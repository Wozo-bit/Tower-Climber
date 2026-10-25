extends Node
## Stage themes and the 60-floor climb: every theme's data, the slot ladder
## (the pseudo-god slots never repeat a theme), boss patrons (blessed bosses,
## the sensitivity rule, interest shifts), the new traits (swarming, undying,
## dragonscale) and the bosses' signature skill books.
## Run:  godot --headless res://tests/test_stages.tscn

var _passed := 0
var _failed := 0


func _ready() -> void:
	GameState.save_dir = "user://test_saves_stages"
	GameState.unlocks_path = "user://test_saves_stages_unlocks.json"
	test_theme_data()
	test_slots()
	test_boss_patrons()
	test_traits()
	test_signature_books()
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


func test_theme_data() -> void:
	print("Theme data")
	var problems: PackedStringArray = []
	for id in StageLibrary.THEMES:
		var t: Dictionary = StageLibrary.THEMES[id]
		if not EnemyFamilies.FAMILIES.has(t.get("family", &"")):
			problems.append("%s: unknown family" % id)
		if str(t.get("hint", "")) == "" or str(t.get("name", "")) == "":
			problems.append("%s: needs a name and a hint" % id)
		var groups: Array = t.get("encounters", []) + t.get("early_encounters", [])
		for floor_in in t.get("miniboss_floors", {}):
			var g: Array = t.miniboss_floors[floor_in]
			groups.append(g)
			if not EnemyLibrary.get_enemy(g[0]).is_miniboss:
				problems.append("%s: %s isn't flagged as a miniboss" % [id, g[0]])
		groups.append(t.get("boss", []))
		if not EnemyLibrary.get_enemy(t.boss[0]).is_boss:
			problems.append("%s: %s isn't flagged as a boss" % [id, t.boss[0]])
		for g in groups:
			if g.is_empty():
				problems.append("%s: an empty group" % id)
			for e in g:
				if EnemyLibrary.get_enemy_or_null(e) == null:
					problems.append("%s: unknown enemy %s" % [id, e])
	check(problems.is_empty(), "every theme's enemies, minibosses and boss exist %s" % [problems])
	var bad_traits := []
	for d in EnemyLibrary.all():
		if not EnemyFamilies.FAMILIES.has(d.family):
			bad_traits.append(d.id)
		for tr in EnemyFamilies.traits_for(d):
			if not EnemyFamilies.TRAITS.has(tr):
				bad_traits.append(tr)
	check(bad_traits.is_empty(), "every enemy has a known family and traits %s" % [bad_traits])
	var all_themes := []
	for slot in StageLibrary.STAGE_SLOTS:
		all_themes.append_array(slot.themes)
	check([&"bandit_fortress", &"insect_hive", &"beast_den", &"elemental_rift", &"undead_crypt", &"demon_gate",
		&"celestial_spire", &"dragon_roost"].all(func(t): return all_themes.has(t)), "all 8 new themes are in the climb")


func test_slots() -> void:
	print("The climb")
	check(StageLibrary.STAGE_SLOTS.size() * StageLibrary.FLOORS_PER_STAGE == GameState.FINAL_FLOOR and GameState.FINAL_FLOOR == 60,
		"six stages, final boss on floor 60")
	var ladder := [[&"goblin_warrens", &"slime_pits"], [&"orc_stronghold", &"bandit_fortress"], [&"insect_hive", &"beast_den"],
		[&"elemental_rift", &"undead_crypt"]]
	var in_order := true
	for i in ladder.size():
		in_order = in_order and StageLibrary.STAGE_SLOTS[i].themes == ladder[i]
	check(in_order, "Slimes/Goblins -> Bandits/Orcs -> Insects/Beasts -> Elemental Rift/Undead")
	var repeats := 0
	var seen5 := {}
	var seen6 := {}
	for s in 300:
		var rng := RandomNumberGenerator.new()
		rng.seed = s
		var picks := StageLibrary.roll_themes(rng)
		if picks[4] == picks[5]:
			repeats += 1
		seen5[picks[4]] = true
		seen6[picks[5]] = true
	check(repeats == 0, "floors 41-50 and 51-60 never get the same pseudo-god theme")
	check(seen5.size() == 3 and seen6.size() == 3, "Demons, Angels and Dragons can each land on either")
	check(StageLibrary.validate_themes([&"goblin_warrens", &"orc_stronghold", &"insect_hive", &"elemental_rift",
		&"dragon_roost", &"dragon_roost"])[5] != &"dragon_roost", "a tampered save can't repeat a pseudo-god theme")
	GameState.reset_run()
	GameState.stage_themes = [&"slime_pits", &"bandit_fortress", &"beast_den", &"undead_crypt", &"dragon_roost", &"demon_gate"]
	check(StageLibrary.stage_name(15) == "Stage 2: Bandit Fortress" and StageLibrary.boss_for_floor(40)[0] == &"necromancer"
		and StageLibrary.boss_for_floor(50)[0] == &"dragon_sovereign" and StageLibrary.boss_for_floor(60)[0] == &"archfiend",
		"the run's picks decide each stage")


func test_boss_patrons() -> void:
	print("Boss patrons")
	var bad := []
	for d in EnemyLibrary.all():
		if d.patron == &"":
			continue
		var b := BeingLibrary.get_being(d.patron)
		if b.is_empty() or b.get("living", false):
			bad.append(d.id)   # sensitivity rule: living-religion figures never sponsor enemies
	check(bad.is_empty(), "boss patrons exist and are never figures from living religions %s" % [bad])
	check(EnemyLibrary.get_enemy(&"necromancer").patron == &"hades", "the Necromancer answers to Hades")
	var plain := Combatant.from_enemy(EnemyLibrary.get_enemy(&"bandit_cutthroat"))
	var boss := Combatant.from_enemy(EnemyLibrary.get_enemy(&"necromancer"))
	var blessed_skill: StringName = BeingLibrary.get_being(&"hades").skill
	# Hades' blessing: +Dark power (level 2), and his Bident.
	check(boss.skills.any(func(s): return s.id == blessed_skill) and boss.element_power.get(Element.Type.DARK, 0.0) > 0.0
		and plain.element_power.is_empty(), "a sponsored boss fights with its patron's blessing and blessed skill")
	check(CutInData.boss("boss", [&"necromancer"], 40).subtitle.contains("Hades"), "its cut-in names the sponsor")
	GameState.start_new_game("Ophelius", "Cassia", 1)
	var rival: StringName = BeingLibrary.rivals_of(&"hades")[0]
	var before_p := GameState.blessings.interest(&"hades")
	var before_r := GameState.blessings.interest(rival)
	GameState.pending_encounter = EnemyLibrary.build_group([&"necromancer"])
	GameState.return_scene = ""
	GameState.active_enemy_index = -1
	GameState.finish_battle(BattleManager.Outcome.VICTORY)
	check(GameState.blessings.interest(&"hades") < before_p and GameState.blessings.interest(rival) > before_r,
		"beating it annoys its patron and pleases the patron's rivals")
	GameState.delete_slot(1)


func _unit(id: StringName) -> Combatant:
	return Combatant.from_enemy(EnemyLibrary.get_enemy(id))


func test_traits() -> void:
	print("Traits")
	var party: Array[CharacterData] = [GameState.make_premade("Vex", &"mage", { Stats.Type.INTELLIGENCE: 20, Stats.Type.HEALTH: 15 })]
	var b := BattleManager.new()
	b.rng.seed = 7
	b.setup(party, EnemyLibrary.build_group([&"hive_drone", &"hive_drone", &"hive_drone"]))
	var drone: Combatant = b.enemies[0]
	var target: Combatant = b.party[0]
	drone.swarm_allies = 0
	var r1 := RandomNumberGenerator.new()
	r1.seed = 3
	var alone: int = DamageCalc.roll_damage(drone, target, drone.basic_attack, r1).amount
	drone.swarm_allies = 2
	var r2 := RandomNumberGenerator.new()
	r2.seed = 3
	var swarm: int = DamageCalc.roll_damage(drone, target, drone.basic_attack, r2).amount
	check(swarm > alone, "swarmers hit harder with friends alive (%d -> %d)" % [alone, swarm])

	var mage := b.party[0]
	var skeleton := _unit(&"skeleton_warrior")
	b.enemies = [skeleton] as Array[Combatant]
	skeleton.hp = 5
	mage.mp = 99
	b.current = mage
	b.submit(BattleAction.use_skill(mage, SkillLibrary.get_skill(&"frost_bolt"), skeleton))
	check(skeleton.hp == 1 and skeleton.undying_used, "undying: survives its first killing blow")
	skeleton.hp = 5
	skeleton.undying_used = false
	b.current = mage
	b.submit(BattleAction.use_skill(mage, SkillLibrary.get_skill(&"ember"), skeleton))
	check(not skeleton.is_alive(), "...but fire puts it down for good")

	var plain := _unit(&"bandit_brute")
	var dragon := _unit(&"drakeling")
	plain.stats = dragon.stats   # same defenses, only the trait differs
	plain.affinities = {}
	dragon.affinities = {}
	var r3 := RandomNumberGenerator.new()
	r3.seed = 11
	var normal_hit: int = DamageCalc.roll_damage(target, plain, SkillLibrary.get_skill(&"attack_magic"), r3).amount
	var r4 := RandomNumberGenerator.new()
	r4.seed = 11
	var scaled_hit: int = DamageCalc.roll_damage(target, dragon, SkillLibrary.get_skill(&"attack_magic"), r4).amount
	check(scaled_hit < normal_hit, "dragonscale turns hits that aren't weaknesses (%d -> %d)" % [normal_hit, scaled_hit])


func test_signature_books() -> void:
	print("Signature skills")
	var bosses := [&"bandit_lord", &"hive_queen", &"moonfang", &"rift_sovereign", &"necromancer", &"archfiend",
		&"seraph_judicator", &"dragon_sovereign"]
	var ok := true
	for id in bosses:
		var sig := EnemyLibrary.get_enemy(id).skills.filter(func(s): return SkillLibrary.get_skill(s).tier == SkillTier.Tier.UNIQUE)
		ok = ok and sig.size() == 1 and ItemLibrary.get_item(SkillBooks.book_item_id(sig[0])) != null
	check(ok, "every new boss has one Unique signature skill, with a book that can drop")
