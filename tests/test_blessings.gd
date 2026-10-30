extends Node
## Blessings: the mythological roster (and its sensitivity rule), interest,
## rivalries, offers (shrines, boss visits, bargains), accepting/refusing,
## levels, buffs + curses in stats and combat, warnings, punishment, new
## offers afterwards, blessed NPCs and saving.
## Run:  godot --headless res://tests/test_blessings.tscn
## Uses separate test save files, so your real save is never touched.

const E := Element.Type
const A := Element.Affinity

var _passed := 0
var _failed := 0


func _ready() -> void:
	GameState.save_dir = "user://test_saves_blessings"
	GameState.unlocks_path = "user://test_saves_blessings_unlocks.json"
	Tips.path = "user://test_saves_blessings_tips.json"
	GameState.legacy_path = "user://test_hall_blessings.json"
	test_roster_is_valid()
	test_interest_and_offers()
	test_accepting()
	test_levels_grow()
	test_rivalries()
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
	GameState.solo_run = false   # (these runs never fight; the solo bonus is tested in test_party)


## Offer + accept through the real dialogue.
func _accept(being: StringName) -> void:
	var r := DialogueRunner.new()
	r.start(&"blessing_offer", null, being)
	for c in r.choices():
		if c.text == "I accept." or c.text.begins_with("Deal."):
			r.choose(c.index)
			return


func test_roster_is_valid() -> void:
	var problems := BeingLibrary.validate()
	for p in problems:
		printerr("    ", p)
	check(problems.is_empty(), "every being is valid (levels, buff AND curse, skills, routes, rivals)")
	check(DialogueLibrary.validate_all().is_empty() and QuestLibrary.validate_all().is_empty(), "blessing dialogue and the bargain quest are valid")
	var kinds := {}
	var pantheons := {}
	for id in BeingLibrary.beings:
		kinds[BeingLibrary.beings[id].kind] = true
		pantheons[BeingLibrary.beings[id].pantheon] = true
	check(kinds.size() == 3 and BeingLibrary.beings.size() >= 26, "gods, demons and devils (%d beings)" % BeingLibrary.beings.size())
	check(pantheons.size() >= 8, "from many mythologies: %s" % ", ".join(pantheons.keys()))
	var living_ok := true
	for id in BeingLibrary.beings:
		if BeingLibrary.beings[id].get("living", false) and BeingLibrary.beings[id].kind != "god":
			living_ok = false
	check(living_ok, "sensitivity rule: living-religion figures are only ever gods")
	var bad: Dictionary = BeingLibrary.SPECS[&"amaterasu"].duplicate(true)
	bad["kind"] = "demon"
	BeingLibrary.register_being(&"test_bad", bad)
	check("\n".join(BeingLibrary.validate()).contains("sensitivity rule"), "...and the validator catches a break of it")
	BeingLibrary.beings.erase(&"test_bad")
	check(BeingLibrary.rivals_of(&"loki").has(&"thor") and BeingLibrary.rivals_of(&"thor").has(&"loki"), "rivalries count both ways")
	var lv3 := BeingLibrary.level_effects(&"zeus", 3)
	check(is_equal_approx(lv3.buff.element_power[E.LIGHTNING], 0.45) and is_equal_approx(lv3.curse.gold_mult, -0.15),
		"levels scale buff AND curse (Zeus lv3: +45% Lightning, -15% gold)")
	check(BeingLibrary.level_effects(&"morrigan", 3).curse.has("affinities") and not BeingLibrary.level_effects(&"morrigan", 2).curse.has("affinities"),
		"some curses add something new at level 3")
	BeingLibrary.register_being(&"test_dlc", BeingLibrary.SPECS[&"odin"].duplicate(true))
	check(BeingLibrary.beings.has(&"test_dlc") and BeingLibrary.validate().is_empty(), "DLC can register more beings")
	BeingLibrary.beings.erase(&"test_dlc")


func test_interest_and_offers() -> void:
	_fresh()
	var bs := GameState.blessings
	check(bs.offering_beings().is_empty(), "nobody is interested in a nobody")
	GameState.add_route_points(&"hero", 12)
	check(bs.interest(&"thor") == 12 and bs.interest(&"mammon") == -12, "interest follows the route: liked routes up, disliked down")
	var offers := bs.offering_beings()
	check(offers.has(&"ra") and offers.has(&"guan_yu") and not offers.has(&"mammon") and not offers.has(&"hades"),
		"leaning hero: heroic beings take an interest")
	bs.add_interest(&"inari", 5)
	check(bs.offering_beings()[0] == &"inari", "a choice can please a being directly (and the keenest offers first)")


func test_accepting() -> void:
	_fresh()
	GameState.add_route_points(&"hero", 12)
	_accept(&"ra")
	var p := GameState.player
	check(p.blessing_id == &"ra" and p.blessing_level == 1, "accepting Ra's offer blesses you (level 1)")
	check(p.all_skills().any(func(s): return s.id == &"sun_disk"), "a blessed skill while blessed")
	var u := Combatant.from_character(p)
	check(u.affinities.get(E.DARK) == A.WEAK and u.element_power.get(E.FIRE, 0.0) > 0.0, "curse: weak to Dark; buff: more Fire/Holy damage")
	var goblin := Combatant.from_enemy(EnemyLibrary.get_enemy(&"goblin"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var blessed_hit: int = DamageCalc.roll_damage(u, goblin, SkillLibrary.get_skill(&"sun_disk"), rng).amount
	u.element_power = {}
	rng.seed = 3
	var plain_hit: int = DamageCalc.roll_damage(u, goblin, SkillLibrary.get_skill(&"sun_disk"), rng).amount
	check(absi(blessed_hit - roundi(plain_hit * 1.2)) <= 1, "Fire + Holy boosts add up on a Fire+Holy skill: +20%% (%d vs %d)" % [blessed_hit, plain_hit])
	var imp := Combatant.from_enemy(EnemyLibrary.get_enemy(&"imp_shaman"))
	u = Combatant.from_character(p)
	check(DamageCalc.roll_damage(imp, u, SkillLibrary.get_skill(&"shadow_bolt"), rng).weak, "Dark hits on you count as weak hits...")
	check(u.stagger == 0, "...but the party never gets staggered")
	check(DialogueRunner.blessing_summary(&"ra", 1).contains("+10% Fire damage") and DialogueRunner.blessing_summary(&"ra", 1).contains("Weak to Dark"),
		"the offer shows the gift and the price: %s" % DialogueRunner.blessing_summary(&"ra", 1))
	_fresh()
	GameState.add_route_points(&"hero", 12)
	var mp_before := GameState.player.max_mp()
	_accept(&"athena")
	check(GameState.player.max_mp() > mp_before, "stat buffs apply (Athena +5%% INT: max MP %d -> %d)" % [mp_before, GameState.player.max_mp()])


func test_levels_grow() -> void:
	_fresh()
	GameState.add_route_points(&"hero", 12)
	_accept(&"zeus")
	var p := GameState.player
	var gold_curse := p.effect_sum("gold_mult")
	GameState.add_route_points(&"hero", 15)
	check(p.blessing_level == 2, "interest 27: level 2")
	check(p.effect_sum("gold_mult") < gold_curse, "...and the curse grows too (even less gold)")
	GameState.add_route_points(&"hero", 20)
	check(p.blessing_level == 3 and GameState.blessings.messages.any(func(m): return m.contains("level 3")), "interest 47: level 3")


func test_rivalries() -> void:
	_fresh()
	GameState.add_route_points(&"hero", 12)
	GameState.add_route_points(&"vigilante", 12)
	var bs := GameState.blessings
	check(bs.wants_to_offer(&"amaterasu") and bs.wants_to_offer(&"susanoo"), "Amaterasu and her rival Susanoo both want you")
	_accept(&"amaterasu")
	var p := GameState.player
	check(p.blessing_id == &"amaterasu" and p.curse_id == &"susanoo", "choose Amaterasu: jealous Susanoo curses you out of spite")
	check(bs.messages.any(func(m): return m.contains("furious")), "...and you're told why")
	check(bs.interest(&"susanoo") == 12 - BlessingState.RIVAL_PENALTY and not bs.wants_to_offer(&"susanoo"),
		"a rival loses interest while you serve its enemy")


func test_warning_and_punishment() -> void:
	_fresh()
	GameState.add_route_points(&"hero", 12)
	_accept(&"ra")
	GameState.pending_talks.clear()
	GameState.add_route_points(&"villain", 12)
	check(GameState.pending_talks.any(func(t): return t.dialogue == &"blessing_warning" and t.being == &"ra"),
		"acting against its values: a warning first")
	check(GameState.player.is_blessed(), "a warning isn't losing it")
	var hp_before := GameState.player.current_hp()
	GameState.add_route_points(&"villain", 10)
	var p := GameState.player
	check(not p.is_blessed() and p.curse_id == &"ra", "keep going: the blessing is taken and its curse remains")
	check(p.current_hp() < hp_before and GameState.pending_talks.any(func(t): return t.dialogue == &"blessing_punish"),
		"...and you're struck (HP %d -> %d)" % [hp_before, p.current_hp()])
	check(Combatant.from_character(p).affinities.get(E.DARK) == A.WEAK and Combatant.from_character(p).element_power.is_empty(),
		"cursed: the weakness without the buff")
	check(not GameState.blessings.wants_to_offer(&"ra"), "a being that punished you never offers again")
	check(GameState.blessings.offering_beings().has(&"mammon"), "...but another being can (Mammon likes villains)")
	GameState.enter_floor(p.curse_until_floor + 1)
	check(p.curse_id == &"" and GameState.blessings.messages.any(func(m): return m.contains("curse on you lifts")), "the curse lifts after 5 floors")


func test_bargains() -> void:
	_fresh()
	GameState.add_route_points(&"vigilante", 12)
	GameState.player.gold = 100
	var r := DialogueRunner.new()
	r.start(&"blessing_offer", null, &"mephistopheles")
	var texts := r.choices().map(func(c): return c.text)
	check(texts.has("(You can't pay: 400 gold)") and not texts.any(func(t): return t.begins_with("Deal")), "Mephistopheles' bargain: can't pay 400 gold")
	GameState.player.gold = 500
	_accept(&"mephistopheles")
	check(GameState.player.blessing_id == &"mephistopheles" and GameState.player.gold == 100, "pay the price, get the blessing")
	_fresh()
	GameState.add_route_points(&"vigilante", 12)
	_accept(&"morrigan")
	check(GameState.player.blessing_id == &"morrigan" and GameState.quests.is_active(&"oath_of_vengeance"), "the Morrigan's price is a promise: the oath quest starts")
	GameState.player.gold = 400
	_accept(&"mephistopheles")
	check(GameState.player.blessing_id == &"mephistopheles", "accepting another being's offer replaces the old blessing")


func test_refusing() -> void:
	_fresh()
	GameState.add_route_points(&"hero", 12)
	var r := DialogueRunner.new()
	r.start(&"blessing_offer", null, &"ra")
	r.choose(r.choices().filter(func(c): return c.text == "No.")[0].index)
	check(not GameState.player.is_blessed() and not GameState.blessings.wants_to_offer(&"ra"), "refuse: no blessing, and it doesn't ask again right away")
	GameState.floor_number += BlessingState.REOFFER_FLOORS
	check(GameState.blessings.wants_to_offer(&"ra"), "...but asks again 5 floors later")


func _won_battle(gold: int, xp: int) -> void:
	var b := BattleManager.new()
	var party: Array[CharacterData] = [GameState.player]
	b.setup(party, EnemyLibrary.build_group([&"slime"]), 1)
	b.outcome = BattleManager.Outcome.VICTORY
	b.rewards = { "xp": xp, "gold": gold, "items": {}, "gear": [], "books": [] }
	b.apply_rewards()


func test_rewards_and_prices() -> void:
	_fresh()
	GameState.add_route_points(&"villain", 12)
	_accept(&"mammon")
	var potion := ItemLibrary.get_item(&"potion")
	check(GameState.shop_price(potion) == 54, "Mammon's curse: prices +10%% on top of the villain markup (%d)" % GameState.shop_price(potion))
	var gold := GameState.player.gold
	_won_battle(100, 0)
	check(GameState.player.gold == gold + 115, "Mammon's buff: +15% gold from battles")
	_fresh()
	GameState.add_route_points(&"vigilante", 12)
	GameState.player.gold = 400
	_accept(&"mephistopheles")
	var xp := GameState.player.xp
	var lv := GameState.player.level
	_won_battle(0, 100)
	check(GameState.player.level > lv or GameState.player.xp == xp + 110, "Mephistopheles' buff: +10% XP")
	_fresh()
	GameState.add_route_points(&"hero", 12)
	_accept(&"ra")
	GameState.player.set_current_hp(10)
	GameState.return_scene = ""
	GameState.finish_battle(BattleManager.Outcome.VICTORY)
	check(GameState.player.current_hp() > 10, "Ra's buff: heal after every win")


func test_shrines_and_boss_visits() -> void:
	_fresh(5)
	GameState.add_route_points(&"hero", 12)
	var layout := FloorLayout.generate(1, 5, true)
	GameState.place_npcs(layout)
	var shrines := layout.npcs.values().filter(func(v): return String(v).begins_with("shrine:"))
	check(shrines.size() == BlessingState.MAX_SHRINES, "shrines appear on rest floors, at most %d (%s)" % [BlessingState.MAX_SHRINES, shrines])
	check(GameState.blessings.offering_beings().has(GameState.shrine_being(shrines[0])), "each shrine belongs to an interested being")
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
	check(brakka.blessing_id == &"thor" and brakka.all_skills().any(func(s): return s.id == &"mjolnir"),
		"NPCs can be blessed too (Brakka follows Thor)")


func test_save_and_ng_plus() -> void:
	GameState.start_new_game("Ophelius", "Cassia", 1)
	GameState.add_route_points(&"hero", 30)
	_accept(&"athena")
	GameState.blessings.refuse(&"ra")
	GameState.save_game()
	GameState.reset_run()
	GameState.load_game(1)
	var p := GameState.player
	check(p.blessing_id == &"athena" and p.blessing_level == 2 and p.stats.blessing_pct.has(Stats.Type.INTELLIGENCE), "blessing saved (with its stat change)")
	check(GameState.blessings.beings[&"ra"].refused_floor == GameState.floor_number, "refusals saved")
	var d := SaveSerializer.read_json(GameState.slot_path(1))
	d.player.blessing = "fake_god"
	d.player.curse = "ra"
	d.player.curse_level = 99
	d.blessings.beings["fake_god"] = { "bonus": 5 }
	SaveSerializer.write_json(GameState.slot_path(1), d)
	GameState.load_game(1)
	p = GameState.player
	check(not p.is_blessed() and p.curse_id == &"ra" and p.curse_level == 3 and not GameState.blessings.beings.has(&"fake_god"),
		"tampered save: fake beings dropped, levels clamped")
	GameState.player.bless(&"athena", 2)
	var rec := GameState.complete_run()
	GameState.start_new_game_plus(rec)
	check(not GameState.player.is_blessed() and GameState.player.curse_id == &"", "New Game+ starts without blessings or curses")
