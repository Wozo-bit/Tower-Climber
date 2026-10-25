extends Node
## Blessings: the being roster, interest, offers (shrines, boss visits,
## bargains), accepting/refusing, levels, buffs + curses in stats and combat,
## warnings, punishment, new offers afterwards, blessed NPCs and saving.
## Run:  godot --headless res://tests/test_blessings.tscn
## Uses separate test save files, so your real save is never touched.

const E := Element.Type
const A := Element.Affinity

var _passed := 0
var _failed := 0


func _ready() -> void:
	GameState.save_dir = "user://test_saves_blessings"
	GameState.legacy_path = "user://test_hall_blessings.json"
	test_roster_is_valid()
	test_interest_and_offers()
	test_accepting()
	test_levels_grow()
	test_warning_and_punishment()
	test_bargains()
	test_refusing()
	test_rewards_and_prices()
	test_shrines_and_boss_visits()
	test_blessed_npcs()
	test_save_and_ng_plus()
	GameState.delete_slot(1)
	if FileAccess.file_exists(GameState.legacy_path):
		DirAccess.remove_absolute(GameState.legacy_path)
	GameState.reset_run()
	print("\n==== %d passed, %d failed ====" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)


func check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  ", label)
	else:
		_failed += 1
		printerr("  FAIL  ", label)


func _fresh(floor_n: int = 5) -> void:
	GameState.reset_run()
	GameState.player = GameState.make_premade("Ophelius", &"mage", { Stats.Type.INTELLIGENCE: 20, Stats.Type.HEALTH: 15 })
	GameState.companions.append(GameState.make_childhood_friend("Cassia"))
	GameState.floor_number = floor_n


## Offer + accept through the real dialogue.
func _accept(being: StringName) -> DialogueRunner:
	var r := DialogueRunner.new()
	r.start(&"blessing_offer", null, being)
	for c in r.choices():
		if c.text == "I accept." or c.text.begins_with("Deal."):
			r.choose(c.index)
			break
	return r


func test_roster_is_valid() -> void:
	var problems := BeingLibrary.validate()
	for p in problems:
		printerr("    ", p)
	check(problems.is_empty(), "every being is valid (levels, buff AND curse, skills, routes)")
	check(DialogueLibrary.validate_all().is_empty() and QuestLibrary.validate_all().is_empty(), "blessing dialogue and the bargain quest are valid")
	var kinds := {}
	for id in BeingLibrary.beings:
		kinds[BeingLibrary.beings[id].kind] = true
	check(kinds.size() == 3 and BeingLibrary.beings.size() >= 6, "gods, demons and devils (%d beings)" % BeingLibrary.beings.size())
	BeingLibrary.register_being(&"test_being", BeingLibrary.beings[&"astraea"].duplicate(true))
	check(BeingLibrary.validate().is_empty() and BeingLibrary.beings.has(&"test_being"), "DLC can register more beings")
	BeingLibrary.beings.erase(&"test_being")


func test_interest_and_offers() -> void:
	_fresh()
	var bs := GameState.blessings
	check(bs.offering_beings().is_empty(), "nobody is interested in a nobody")
	GameState.add_route_points(&"hero", 12)
	check(bs.interest(&"astraea") == 12 and bs.interest(&"vorak") == -12, "interest follows the route: liked routes up, disliked down")
	var offers := bs.offering_beings()
	check(offers.has(&"astraea") and offers.has(&"solenne") and not offers.has(&"vorak"), "leaning hero: the gods take an interest")
	bs.add_interest(&"solenne", 5)
	check(bs.offering_beings()[0] == &"solenne", "a choice can please a being directly (and the keenest offers first)")


func test_accepting() -> void:
	_fresh()
	GameState.add_route_points(&"hero", 12)
	var hp_before := GameState.player.max_hp()
	_accept(&"astraea")
	var p := GameState.player
	check(p.blessing_id == &"astraea" and p.blessing_level == 1, "accepting Astraea's offer blesses you (level 1)")
	check(p.max_hp() > hp_before, "buff: +5%% Health (max HP %d -> %d)" % [hp_before, p.max_hp()])
	check(p.all_skills().any(func(s): return s.id == &"righteous_smite"), "a blessed skill while blessed")
	var u := Combatant.from_character(p)
	check(u.affinities.get(E.DARK) == A.WEAK and u.element_power.get(E.HOLY, 0.0) > 0.0, "curse: weak to Dark; buff: more Holy damage")
	var goblin := Combatant.from_enemy(EnemyLibrary.get_enemy(&"goblin"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var blessed_hit: int = DamageCalc.roll_damage(u, goblin, SkillLibrary.get_skill(&"righteous_smite"), rng).amount
	u.element_power = {}
	rng.seed = 3
	var plain_hit: int = DamageCalc.roll_damage(u, goblin, SkillLibrary.get_skill(&"righteous_smite"), rng).amount
	check(absi(blessed_hit - roundi(plain_hit * 1.2)) <= 1, "+20%% Holy damage (%d vs %d)" % [blessed_hit, plain_hit])
	var orc := Combatant.from_enemy(EnemyLibrary.get_enemy(&"imp_shaman"))
	u = Combatant.from_character(p)
	var b := BattleManager.new()
	b.party = [u] as Array[Combatant]
	b.enemies = [orc] as Array[Combatant]
	var dark_bolt := SkillLibrary.get_skill(&"shadow_bolt")
	check(DamageCalc.roll_damage(orc, u, dark_bolt, rng).weak, "Dark hits on you count as weak hits...")
	check(u.stagger == 0, "...but the party never gets staggered")
	check(DialogueRunner.blessing_summary(&"astraea", 1).contains("+5% HLT") and DialogueRunner.blessing_summary(&"astraea", 1).contains("Weak to Dark"),
		"the offer shows the gift and the price: %s" % DialogueRunner.blessing_summary(&"astraea", 1))


func test_levels_grow() -> void:
	_fresh()
	GameState.add_route_points(&"hero", 12)
	_accept(&"astraea")
	var p := GameState.player
	GameState.add_route_points(&"hero", 15)
	check(p.blessing_level == 2, "interest 27: level 2")
	check(p.effect_sum("gold_mult") < 0.0, "...and the curse grows too (less gold)")
	GameState.add_route_points(&"hero", 20)
	check(p.blessing_level == 3 and GameState.blessings.messages.any(func(m): return m.contains("level 3")), "interest 47: level 3")


func test_warning_and_punishment() -> void:
	_fresh()
	GameState.add_route_points(&"hero", 12)
	_accept(&"astraea")
	GameState.pending_talks.clear()
	GameState.add_route_points(&"villain", 12)
	check(GameState.pending_talks.any(func(t): return t.dialogue == &"blessing_warning" and t.being == &"astraea"),
		"acting against its values: a warning first")
	check(GameState.player.is_blessed(), "a warning isn't losing it")
	var hp_before := GameState.player.current_hp()
	GameState.add_route_points(&"villain", 10)
	var p := GameState.player
	check(not p.is_blessed() and p.curse_id == &"astraea", "keep going: the blessing is taken and its curse remains")
	check(p.current_hp() < hp_before and GameState.pending_talks.any(func(t): return t.dialogue == &"blessing_punish"),
		"...and you're struck (HP %d -> %d)" % [hp_before, p.current_hp()])
	check(Combatant.from_character(p).affinities.get(E.DARK) == A.WEAK and Combatant.from_character(p).element_power.is_empty(),
		"cursed: the weakness without the buff")
	check(not GameState.blessings.wants_to_offer(&"astraea"), "a being that punished you never offers again")
	check(GameState.blessings.offering_beings().has(&"vorak"), "...but another being can (the Demon of Greed likes villains)")
	GameState.enter_floor(p.curse_until_floor + 1)
	check(p.curse_id == &"" and GameState.blessings.messages.any(func(m): return m.contains("curse on you lifts")), "the curse lifts after 5 floors")


func test_bargains() -> void:
	_fresh()
	GameState.add_route_points(&"vigilante", 12)
	GameState.player.gold = 100
	var r := DialogueRunner.new()
	r.start(&"blessing_offer", null, &"sable")
	var texts := r.choices().map(func(c): return c.text)
	check(texts.has("(You can't pay: 400 gold)") and not texts.any(func(t): return t.begins_with("Deal")), "Sable's bargain: can't pay 400 gold")
	GameState.player.gold = 500
	_accept(&"sable")
	check(GameState.player.blessing_id == &"sable" and GameState.player.gold == 100, "pay the price, get the blessing")
	_fresh()
	GameState.add_route_points(&"vigilante", 12)
	_accept(&"corvin")
	check(GameState.player.blessing_id == &"corvin" and GameState.quests.is_active(&"oath_of_vengeance"), "Corvin's price is a promise: the oath quest starts")
	GameState.player.gold = 400
	_accept(&"sable")
	check(GameState.player.blessing_id == &"sable", "accepting another being's offer replaces the old blessing")


func test_refusing() -> void:
	_fresh()
	GameState.add_route_points(&"hero", 12)
	var r := DialogueRunner.new()
	r.start(&"blessing_offer", null, &"astraea")
	r.choose(r.choices().filter(func(c): return c.text == "No.")[0].index)
	check(not GameState.player.is_blessed() and not GameState.blessings.wants_to_offer(&"astraea"), "refuse: no blessing, and it doesn't ask again right away")
	GameState.floor_number += BlessingState.REOFFER_FLOORS
	check(GameState.blessings.wants_to_offer(&"astraea"), "...but asks again 5 floors later")


func test_rewards_and_prices() -> void:
	_fresh()
	GameState.add_route_points(&"villain", 12)
	_accept(&"vorak")
	var potion := ItemLibrary.get_item(&"potion")
	check(GameState.shop_price(potion) == 54, "Vorak's curse: prices +10%% on top of the villain markup (%d)" % GameState.shop_price(potion))
	var b := BattleManager.new()
	var party: Array[CharacterData] = [GameState.player]
	b.setup(party, EnemyLibrary.build_group([&"slime"]), 1)
	b.outcome = BattleManager.Outcome.VICTORY
	b.rewards = { "xp": 100, "gold": 100, "items": {}, "gear": [], "books": [] }
	var gold := GameState.player.gold
	b.apply_rewards()
	check(GameState.player.gold == gold + 120, "Vorak's buff: +20% gold from battles")
	_fresh()
	GameState.add_route_points(&"vigilante", 12)
	GameState.player.gold = 400
	_accept(&"sable")
	var xp := GameState.player.xp
	var lv := GameState.player.level
	b = BattleManager.new()
	party = [GameState.player]
	b.setup(party, EnemyLibrary.build_group([&"slime"]), 1)
	b.outcome = BattleManager.Outcome.VICTORY
	b.rewards = { "xp": 100, "gold": 0, "items": {}, "gear": [], "books": [] }
	b.apply_rewards()
	check(GameState.player.level > lv or GameState.player.xp == xp + 115, "Sable's buff: +15% XP")
	_fresh()
	GameState.add_route_points(&"hero", 12)
	_accept(&"solenne")
	GameState.player.set_current_hp(10)
	GameState.return_scene = ""
	GameState.finish_battle(BattleManager.Outcome.VICTORY)
	check(GameState.player.current_hp() > 10, "Solenne's buff: heal after every win")


func test_shrines_and_boss_visits() -> void:
	_fresh(5)
	GameState.add_route_points(&"hero", 12)
	var layout := FloorLayout.generate(1, 5, true)
	GameState.place_npcs(layout)
	check(layout.npcs.values().has(&"shrine:astraea") and GameState.shrine_being(&"shrine:astraea") == &"astraea",
		"shrines of interested beings appear on rest floors")
	var combat := FloorLayout.generate(1, 6, false)
	GameState.floor_number = 6
	GameState.place_npcs(combat)
	check(not combat.npcs.values().any(func(v): return String(v).begins_with("shrine:")), "...not on normal floors")
	GameState.floor_number = 10
	GameState.pending_talks.clear()
	GameState.pending_encounter = EnemyLibrary.build_group([&"goblin_king"])
	GameState.return_scene = ""
	GameState.finish_battle(BattleManager.Outcome.VICTORY)
	check(GameState.pending_talks.any(func(t): return t.dialogue == &"blessing_offer"), "after a stage boss, an interested being comes calling")


func test_blessed_npcs() -> void:
	_fresh(5)
	GameState.player.level_up()
	var brakka := GameState.recruit(&"brakka")
	check(brakka.blessing_id == &"astraea" and brakka.all_skills().any(func(s): return s.id == &"righteous_smite"),
		"NPCs can be blessed too (Brakka follows Astraea)")


func test_save_and_ng_plus() -> void:
	GameState.start_new_game("Ophelius", "Cassia", 1)
	GameState.add_route_points(&"hero", 30)
	_accept(&"solenne")
	GameState.blessings.refuse(&"astraea")
	GameState.save_game()
	GameState.reset_run()
	GameState.load_game(1)
	var p := GameState.player
	check(p.blessing_id == &"solenne" and p.blessing_level == 2 and p.stats.blessing_pct.has(Stats.Type.INTELLIGENCE), "blessing saved (with its stat change)")
	check(GameState.blessings.beings[&"astraea"].refused_floor == GameState.floor_number, "refusals saved")
	var d := SaveSerializer.read_json(GameState.slot_path(1))
	d.player.blessing = "fake_god"
	d.player.curse = "solenne"
	d.player.curse_level = 99
	d.blessings.beings["fake_god"] = { "bonus": 5 }
	SaveSerializer.write_json(GameState.slot_path(1), d)
	GameState.load_game(1)
	p = GameState.player
	check(not p.is_blessed() and p.curse_id == &"solenne" and p.curse_level == 3 and not GameState.blessings.beings.has(&"fake_god"),
		"tampered save: fake beings dropped, levels clamped")
	GameState.player.bless(&"solenne", 2)
	var rec := GameState.complete_run()
	GameState.start_new_game_plus(rec)
	check(not GameState.player.is_blessed() and GameState.player.curse_id == &"", "New Game+ starts without blessings or curses")
