extends Node
## Difficulty modes (Relaxed / Normal / Hard / Hell), Ironman, the Hall's
## fallen and difficulty records, patron temper and feuds in the guild AI,
## and the balance-pass scaling rules (enemy curve, rewards, group sizes).
## Run:  godot --headless res://tests/test_difficulty.tscn
## Uses separate test save files, so your real save is never touched.

var _passed := 0
var _failed := 0


func _ready() -> void:
	GameState.save_dir = "user://test_saves_difficulty"
	GameState.unlocks_path = "user://test_saves_difficulty_unlocks.json"
	GameState.legacy_path = "user://test_hall_difficulty.json"
	_cleanup()
	test_difficulty_data()
	test_choosing_and_lowering()
	test_battle_effects()
	test_hell_extras()
	test_wipes()
	test_ironman()
	test_hall_records()
	test_patron_temper()
	test_scaling_rules()
	_cleanup()
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


func _cleanup() -> void:
	for slot in range(1, GameState.SLOT_COUNT + 1):
		GameState.delete_slot(slot)
	if FileAccess.file_exists(GameState.legacy_path):
		DirAccess.remove_absolute(GameState.legacy_path)


const D := Difficulty.Level


func test_difficulty_data() -> void:
	print("Difficulty data")
	check(Difficulty.all().size() == 4 and Difficulty.DEFAULT == D.NORMAL, "Relaxed, Normal, Hard, Hell (Normal by default)")
	var ok := true
	for i in range(1, 4):
		ok = ok and Difficulty.value(i, "enemy") > Difficulty.value(i - 1, "enemy") \
			and Difficulty.value(i, "xp") <= Difficulty.value(i - 1, "xp") \
			and Difficulty.value(i, "gold") <= Difficulty.value(i - 1, "gold") \
			and Difficulty.value(i, "wipe_gold") >= Difficulty.value(i - 1, "wipe_gold")
	check(ok, "each step up: stronger enemies, smaller rewards, harsher wipes")
	check(Difficulty.value(D.RELAXED, "wipe_gold") == 0.0, "Relaxed: no gold lost when you fall")
	check(Difficulty.label(D.HELL, true) == "Hell + Ironman", "labels")


func test_choosing_and_lowering() -> void:
	print("Choosing and lowering")
	GameState.start_new_game("Ophelius", "Cassia", 1, D.HARD, true)
	check(GameState.difficulty == D.HARD and GameState.ironman, "picked at New Game (with Ironman)")
	check(not GameState.set_difficulty(D.HELL) and GameState.difficulty == D.HARD, "can't be raised mid-run")
	check(GameState.set_difficulty(D.NORMAL) and GameState.difficulty == D.NORMAL, "can be lowered")
	GameState.save_game()
	GameState.reset_run()
	check(GameState.difficulty == D.NORMAL and not GameState.ironman, "(reset)")
	GameState.load_game(1)
	check(GameState.difficulty == D.NORMAL and GameState.ironman, "difficulty and Ironman are saved")
	var d := SaveSerializer.read_json(GameState.slot_path(1))
	d.difficulty = 99
	SaveSerializer.write_json(GameState.slot_path(1), d)
	GameState.load_game(1)
	check(Difficulty.is_valid(GameState.difficulty), "tampered difficulty is clamped")


func test_battle_effects() -> void:
	print("In battle")
	var scales := {}
	for level in [D.RELAXED, D.NORMAL, D.HELL]:
		GameState.start_new_game("Ophelius", "Cassia", 1, level)
		GameState.enter_floor(3)
		GameState.current_layout()
		GameState.prepare_floor_battle(0)
		GameState.return_scene = ""
		scales[level] = GameState.pending_enemy_scale
		var b := BattleManager.new()
		GameState.configure_battle(b)
		check(is_equal_approx(b.enemy_skill_mult, Difficulty.value(level, "ai"))
			and is_equal_approx(b.xp_mult, Difficulty.value(level, "xp") * GameState.reward_scale_for_floor(3)),
			"%s: enemy skills and rewards follow the difficulty" % Difficulty.name_of(level))
	check(scales[D.RELAXED] < scales[D.NORMAL] and scales[D.NORMAL] < scales[D.HELL], "enemies are weaker on Relaxed, stronger on Hell")
	var b := BattleManager.new()
	b.xp_mult = 2.0
	b.gold_mult = 0.5
	b.setup([GameState.player] as Array[CharacterData], EnemyLibrary.build_group([&"goblin"]))
	for e in b.enemies:
		e.hp = 0
	b._check_end()
	var g := EnemyLibrary.get_enemy(&"goblin")
	check(b.rewards.xp == g.xp_reward * 2 and b.rewards.gold == roundi(g.gold_reward * 0.5), "reward multipliers apply")


func test_hell_extras() -> void:
	print("Hell extras")
	GameState.start_new_game("Ophelius", "Cassia", 1, D.NORMAL)
	var lens := ItemLibrary.get_item(&"potion")
	var normal_price := GameState.shop_price(lens)
	GameState.enter_floor(10)
	GameState.current_layout()
	var normal_boss: Array = GameState.floor_has_alive("boss").group
	GameState.start_new_game("Ophelius", "Cassia", 1, D.HELL)
	check(not GameState.for_sale(&"scouting_lens") and GameState.for_sale(&"potion"), "Hell: no Scouting Lens for sale")
	check(GameState.shop_price(lens) == roundi(normal_price * Difficulty.HELL_CONSUMABLE_PRICE), "Hell: potions cost more")
	GameState.enter_floor(10)
	GameState.current_layout()
	check(GameState.floor_has_alive("boss").group.size() == normal_boss.size() + 1, "Hell: stage bosses bring an extra escort")


func test_wipes() -> void:
	print("Wipes")
	for level in [D.RELAXED, D.NORMAL, D.HELL]:
		GameState.start_new_game("Ophelius", "Cassia", 1, level)
		GameState.player.gold = 1000
		GameState.handle_defeat()
		check(GameState.player.gold == 1000 - roundi(1000 * Difficulty.value(level, "wipe_gold")),
			"%s: a wipe costs %d%% of your gold" % [Difficulty.name_of(level), roundi(Difficulty.value(level, "wipe_gold") * 100)])


func test_ironman() -> void:
	print("Ironman")
	GameState.start_new_game("Ophelius", "Cassia", 1, D.NORMAL, false)
	var friend := GameState.childhood_friend()
	friend.set_current_hp(0)
	check(GameState.ironman_deaths(GameState.fighting_party(), BattleManager.Outcome.VICTORY).is_empty(), "off: nobody dies")
	GameState.start_new_game("Ophelius", "Cassia", 1, D.NORMAL, true)
	friend = GameState.childhood_friend()
	var fighters := GameState.fighting_party()
	check(GameState.ironman_deaths(fighters, BattleManager.Outcome.VICTORY).is_empty(), "a clean win: nobody dies")
	friend.set_current_hp(0)
	check(GameState.ironman_deaths(fighters, BattleManager.Outcome.VICTORY) == [friend], "still down when the fight ends: dead")
	check(GameState.ironman_deaths(fighters, BattleManager.Outcome.DEFEAT).size() == fighters.size(), "losing the fight: everyone")
	var weapon := LootTable.make_gear(LootTable.BASES.keys()[0], Rarity.Tier.COMMON, 1, RandomNumberGenerator.new())
	friend.equip(weapon)
	check(not GameState.apply_ironman_deaths([friend]) and not GameState.companions.has(friend)
		and GameState.fallen_companions == ["Cassia"], "a fallen companion is gone for good")
	check(GameState.inventory.gear.has(weapon), "...their gear goes to the bag")
	check(GameState.apply_ironman_deaths([GameState.player]), "if you fall, the run is over")
	GameState.floor_number = 7
	GameState.end_ironman_run(false)
	check(not GameState.has_save(1) and not GameState.run_active and GameState.ironman_ended_message.contains("floor 7"),
		"the save is deleted")
	var rec := GameState.load_legacy().find(GameState.player.legacy_id)
	check(rec != null and rec.fallen and rec.fallen_floor == 7 and not rec.can_continue(), "the Hall remembers them as Fallen (no New Game+)")
	check(rec.summary().contains("FALLEN"), "...and says so")
	GameState.ironman_ended_message = ""


func test_hall_records() -> void:
	print("Hall records")
	GameState.start_new_game("Vex", "Cassia", 2, D.HARD, true)
	var rec := GameState.record_completion()
	check(rec.best_difficulty == D.HARD and rec.ironman_cleared and rec.can_continue(), "clears record the difficulty and Ironman")
	check(rec.summary().contains("Hard + Ironman"), "...shown in the Hall")
	var book := GameState.load_legacy()
	var loaded := book.find(rec.legacy_id)
	check(loaded.best_difficulty == D.HARD and loaded.ironman_cleared, "saved in the Hall")
	GameState.start_new_game_plus(loaded, 2, D.HELL, false)
	check(GameState.difficulty == D.HELL and GameState.ng_plus_cycle == 1, "New Game+ can pick a new difficulty")


func test_patron_temper() -> void:
	print("Patron temper")
	var ok := true
	for b in BeingLibrary.beings:
		var t := BeingLibrary.temper_of(b)
		ok = ok and t >= 0.0 and t <= 1.0
	check(ok and BeingLibrary.validate().is_empty(), "every being has a temper 0-1")
	check(BeingLibrary.temper_of(&"loki") > BeingLibrary.temper_of(&"inari"), "Loki is more warlike than Inari")
	GameState.start_new_game("Ophelius", "Cassia", 1)
	var gs := GameState.guilds
	check(gs.your_patrons().is_empty() and gs.patron_temper() == GuildState.NEUTRAL_TEMPER, "no patron: a neutral world")
	GameState.player.bless(&"ra", 1)
	check(gs.your_patrons() == [&"ra"] and gs.feud_guilds().has(&"serpent_coil"), "Ra's blessing: Apep's Serpent Coil feuds with you")
	gs.join(&"order_of_the_aegis")
	gs.declare_war(&"serpent_coil", &"order_of_the_aegis", 0)
	var w := gs.war_of(&"serpent_coil")
	check(gs.is_feud_war(w), "a war between your guild and a feuding guild is a feud")
	w["ticks"] = GuildState.WAR_MAX_TICKS
	w["score"] = 0.0
	gs._settle(w)
	check(gs.war_between(&"serpent_coil", &"order_of_the_aegis"), "feuds don't end in a truce")
	CutIns.skip_all()
	# Over many runs, a warlike patron drags your guild into more wars than a calm one.
	var wars := {}
	for patron in [&"inari", &"loki"]:
		var n := 0
		for i in 12:
			GameState.start_new_game("Ophelius", "Cassia", 1)
			GameState.player.legacy_id = "temper-%d" % i
			GameState.player.bless(patron, 1)
			GameState.guilds.join(&"order_of_the_aegis")
			for f in range(2, 31):
				GameState.enter_floor(f)
				n += GameState.guilds.wars.filter(func(x): return x.attacker == &"order_of_the_aegis" or x.defender == &"order_of_the_aegis").size()
			CutIns.skip_all()
		wars[patron] = n
	check(wars[&"loki"] > wars[&"inari"], "Loki's blessing means more wars for your guild than Inari's (%d vs %d floor-wars)" % [wars[&"loki"], wars[&"inari"]])


func test_scaling_rules() -> void:
	print("Scaling rules")
	check(GameState.enemy_scale_for_floor(1) < GameState.enemy_scale_for_floor(10)
		and GameState.enemy_scale_for_floor(10) < GameState.enemy_scale_for_floor(30), "enemies grow with the floor")
	var step := func(f): return GameState.enemy_scale_for_floor(f + 1) - GameState.enemy_scale_for_floor(f)
	check(is_equal_approx(step.call(20), step.call(30)) and step.call(45) > step.call(30) * 1.3,
		"past floor 40 the curve gets steeper (tier 3 and big parties)")
	check(GameState.reward_scale_for_floor(1) == 1.0 and GameState.reward_scale_for_floor(20) > GameState.reward_scale_for_floor(10),
		"rewards grow with them")
	GameState.start_new_game("Ophelius", "Cassia", 1)
	GameState.enter_floor(8)
	GameState.current_layout()
	var biggest := 0
	for e in GameState.floor_enemies:
		if e.kind == "normal":
			biggest = maxi(biggest, e.group.size())
	check(biggest <= GameState.battle_party().size() + GameState.MAX_EXTRA_ENEMIES, "a pair never meets more enemies than it has members")
