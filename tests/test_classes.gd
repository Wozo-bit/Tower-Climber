extends Node
## Class advancement (tier 2+): the class tree, lineage, the floor/level gate,
## stat builds, route-only classes, trial quests, keeping skills, Uniques and saving.
## Run:  godot --headless res://tests/test_classes.tscn
## Uses separate test save files, so your real save is never touched.

var _passed := 0
var _failed := 0


func _ready() -> void:
	GameState.save_dir = "user://test_saves_classes"
	test_tree_is_complete()
	test_lineage()
	test_gate_and_trial()
	test_advancing_keeps_everything()
	test_stat_builds()
	test_route_only()
	test_uniques_and_loot()
	test_save_roundtrip()
	GameState.delete_slot(1)
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


func _fresh() -> void:
	GameState.reset_run()
	GameState.player.rename("Ophelius")


## A level-25 character of `class_id` with a tier-1 premade build.
func _veteran(class_id: StringName, alloc: Dictionary) -> CharacterData:
	var c := GameState.make_premade("Vet", class_id, alloc)
	while c.level < 25:
		c.level_up()
	# Spend the new points the same way (keeps the build's shape).
	var total := 0
	for s in alloc:
		total += alloc[s]
	var spend := {}
	var left := c.unspent_points
	for s in alloc:
		spend[s] = left * alloc[s] / total
	var given := 0
	for s in spend:
		given += spend[s]
	spend[alloc.keys()[0]] += left - given
	c.apply_allocation(spend)
	return c


const MAGE := { Stats.Type.INTELLIGENCE: 20, Stats.Type.AGILITY: 15 }
const TANK := { Stats.Type.HEALTH: 12, Stats.Type.STAMINA: 12, Stats.Type.STRENGTH: 11 }
const ARCHER := { Stats.Type.AGILITY: 13, Stats.Type.STRENGTH: 10, Stats.Type.LUCK: 6, Stats.Type.STAMINA: 6 }


## Finishes a class's trial quest by "winning" enough fights.
func _finish_trial(def: ClassDef) -> void:
	var trial := CharacterData.trial_id(def)
	GameState.quests.start(trial)
	var crowd := []
	for i in 40:
		crowd.append(EnemyLibrary.get_enemy(&"goblin"))
	GameState.quests.on_battle_won(crowd, RandomNumberGenerator.new())
	GameState.quests.on_battle_won([EnemyLibrary.get_enemy(&"hobgoblin")], RandomNumberGenerator.new())


func test_tree_is_complete() -> void:
	var tier2 := ClassRegistry.get_tier(2).filter(func(d): return d.unique_to == &"")   # demigods' classes aside
	var bases := [&"tank", &"mage", &"archer", &"rogue", &"support", &"warrior", &"monk", &"spellblade", &"magic_swordsman", &"summoner"]
	check(ClassRegistry.get_tier(1).filter(func(d): return not d.is_secret).size() == bases.size(), "10 starting classes")
	check(tier2.size() == 24, "24 tier-2 classes (2 per class + 4 route-only)")
	for base in bases:
		var normal := ClassRegistry.advancements_for(base).filter(func(d): return d.required_route == &"")
		check(normal.size() == 2, "%s has 2 normal advancements" % base)
	var routed := tier2.filter(func(d): return d.required_route != &"")
	check(routed.size() == 4 and routed.all(func(d): return RouteLibrary.routes.has(d.required_route)), "4 route-only advancements on real routes")
	var tier3 := ClassRegistry.get_tier(3).filter(func(d): return d.unique_to == &"")
	check(tier3.size() == tier2.size() and tier2.all(func(d): return ClassRegistry.advancements_for(d.id).size() == 1),
		"every tier-2 class has a tier-3 mastery")
	var t3_ok := true
	for d in tier3:
		t3_ok = t3_ok and d.required_route == ClassRegistry.get_class_def(d.advances_from).required_route \
			and SkillLibrary.CLASS_SKILLS.get(d.id, []).size() == 1
	check(t3_ok, "tier 3 keeps its route and adds a capstone skill")
	var skills_ok := true
	for def in tier2:
		var ids: Array = SkillLibrary.CLASS_SKILLS.get(def.id, [])
		if ids.size() != 2 or ids.any(func(s): return SkillLibrary.get_skill_or_null(s) == null):
			skills_ok = false
	check(skills_ok, "every advanced class has 2 real skills")
	check(ClassRegistry.ADVANCEMENT_GATES.has(2), "tier 2 has a gate")
	var advanced := ClassRegistry.get_all().filter(func(d): return d.advances_from != &"")
	check(QuestLibrary.trials().size() == advanced.size() and QuestLibrary.validate_all().is_empty(), "every advanced class has a valid trial quest")
	check(SkillLibrary.get_skill(&"magma_burst").elements == [Element.Type.FIRE, Element.Type.EARTH], "deeper elements: Magma Burst = Fire + Earth")
	check(GameState.FINAL_FLOOR == 60, "the climb now ends on floor 60")
	check(ClassRegistry.ADVANCEMENT_GATES.get(3, {}) == { "floor": 40, "level": 45 }, "tier 3: floor 40 + level 45")
	check(ClassRegistry.advancements_for(&"pyromancer_t3").is_empty() and ClassRegistry.advancements_for(&"ascendant").is_empty(),
		"tier 3 is the top for now; secret/NG+ classes don't advance")
	var asc := ClassRegistry.get_class_def(&"ascendant")
	var stronger := ClassRegistry.get_all().all(func(d): return d.id == &"ascendant" or d.stat_bonus_pct + ClassRegistry.ASCENSION_BONUS < asc.stat_bonus_pct)
	check(stronger, "the Ascendant stays the strongest, even against Ascended lines")


func test_lineage() -> void:
	check(ClassRegistry.lineage(&"pyromancer") == [&"pyromancer", &"mage"], "lineage: Pyromancer <- Mage")
	check(ClassRegistry.root_of(&"warlock") == &"mage" and ClassRegistry.root_of(&"tank") == &"tank", "root class")
	check(ClassRegistry.is_in_lineage(&"cleric", &"support") and not ClassRegistry.is_in_lineage(&"cleric", &"mage"), "is_in_lineage")
	check(SkillLibrary.basic_attack_for_class(&"pyromancer").id == &"attack_magic"
		and SkillLibrary.basic_attack_for_class(&"juggernaut").id == &"attack_melee", "advanced classes keep their basic attack")
	check(SkillLibrary.default_row_for_class(&"ranger") == Combatant.Row.BACK
		and SkillLibrary.default_row_for_class(&"bastion") == Combatant.Row.FRONT, "...and their default row")


func test_gate_and_trial() -> void:
	_fresh()
	var c := _veteran(&"mage", MAGE)
	var pyro := ClassRegistry.get_class_def(&"pyromancer")
	GameState.highest_floor = 20
	var s := c.advancement_status(pyro)
	check(not s.floor and s.level and s.stats and not s.trial, "level 25 mage on floor 20: floor and trial missing")
	check(not c.advancement_open() and not c.can_advance(pyro), "no Advance button before floor 20 is beaten")
	GameState.enter_floor(21)
	check(c.advancement_open(), "past floor 20 at level 25: the Advance button shows")
	check(not c.can_advance(pyro), "...but the trial comes first")
	GameState.quests.start(CharacterData.trial_id(pyro))
	check(GameState.quests.is_active(&"trial_pyromancer"), "the trial is a quest")
	_finish_trial(pyro)
	check(GameState.quests.is_done(&"trial_pyromancer") and c.can_advance(pyro), "trial done: ready to advance")
	var young := GameState.make_premade("Kid", &"mage", MAGE)
	check(not young.advancement_status(pyro).level and not young.can_advance(pyro), "a level-10 mage still can't (level gate)")


func test_advancing_keeps_everything() -> void:
	_fresh()
	GameState.enter_floor(21)
	var c := _veteran(&"mage", MAGE)
	c.learn_skill(&"ember")
	var pyro := ClassRegistry.get_class_def(&"pyromancer")
	_finish_trial(pyro)
	var hp_before := c.max_hp()
	check(c.advance_class(pyro) and c.class_id == &"pyromancer", "advance: Mage -> Pyromancer")
	var ids := c.all_skills().map(func(s): return s.id)
	check(ids.has(&"fireball") and ids.has(&"arc_storm") and ids.has(&"magma_burst") and ids.has(&"inferno") and ids.has(&"ember"),
		"keeps the Mage skills and learned skills, gains 2 new ones")
	check(c.max_hp() > hp_before, "+10%% to every stat (max HP %d -> %d)" % [hp_before, c.max_hp()])
	check(c.knows_skill(&"fireball") and c.knows_skill(&"magma_burst"), "knows_skill follows the lineage")
	var u := Combatant.from_character(c)
	check(u.skills.size() == ids.size() and u.basic_attack.id == &"attack_magic", "in battle too")
	check(not c.advance_class(ClassRegistry.get_class_def(&"stormcaller")), "can't advance sideways into the other branch")


func test_stat_builds() -> void:
	_fresh()
	GameState.enter_floor(21)
	var archer := _veteran(&"archer", ARCHER)
	var sharp := ClassRegistry.get_class_def(&"sharpshooter")
	var ranger := ClassRegistry.get_class_def(&"ranger")
	check(not archer.advancement_status(sharp).stats and archer.advancement_status(ranger).stats,
		"the build decides: this archer fits Ranger (AGI+STR), not Sharpshooter (AGI+LUCK)")
	var tank := _veteran(&"tank", TANK)
	check(tank.advancement_status(ClassRegistry.get_class_def(&"bastion")).stats
		and tank.advancement_status(ClassRegistry.get_class_def(&"juggernaut")).stats, "a balanced tank fits both")


func test_route_only() -> void:
	_fresh()
	GameState.enter_floor(21)
	var c := _veteran(&"mage", MAGE)
	var warlock := ClassRegistry.get_class_def(&"warlock")
	check(not c.available_advancements().has(warlock), "Warlock is hidden unless you're a villain (no spoilers)")
	_finish_trial(warlock)
	check(not c.can_advance(warlock), "...and can't be taken")
	GameState.add_route_points(&"villain", 12)
	check(c.available_advancements().has(warlock), "on the villain route it shows up")
	var s := c.advancement_status(warlock)
	check(s.route and s.trial and s.floor and s.level, "route, trial, floor and level all met (stats: %s)" % s.stats)


func test_uniques_and_loot() -> void:
	_fresh()
	GameState.enter_floor(21)
	var c := _veteran(&"mage", MAGE)
	var staff := LootTable.make_unique(&"mage", 20)
	var pyro := ClassRegistry.get_class_def(&"pyromancer")
	_finish_trial(pyro)
	c.advance_class(pyro)
	check(staff.can_equip(c), "the Mage's Unique still fits a Pyromancer")
	check(not LootTable.make_unique(&"tank", 20).can_equip(c), "other classes' Uniques still don't")
	var b := BattleManager.new()
	var party: Array[CharacterData] = [c]
	b.setup(party, EnemyLibrary.build_group([&"slime"]), 1)
	check(b.party_classes() == [&"mage"], "Unique drops treat a Pyromancer as a Mage")


func test_save_roundtrip() -> void:
	GameState.start_new_game("Ophelius", "Cassia", 1)
	GameState.enter_floor(21)
	var c := _veteran(&"tank", TANK)
	var bastion := ClassRegistry.get_class_def(&"bastion")
	_finish_trial(bastion)
	c.advance_class(bastion)
	GameState.companions.append(c)
	GameState.save_game()
	GameState.reset_run()
	GameState.load_game(1)
	var back: CharacterData = GameState.companions[-1]
	check(back.class_id == &"bastion" and back.knows_skill(&"taunt") and back.knows_skill(&"bulwark"), "advanced class saved, skills intact")
	check(GameState.highest_floor == 21 and GameState.quests.is_done(&"trial_bastion"), "highest floor and finished trials saved")
