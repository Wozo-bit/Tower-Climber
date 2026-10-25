extends Node
## Headless test runner for the progression rules.
## Run from the project folder:
##   godot --headless res://tests/test_progression.tscn
## Exits with code 0 on success, 1 on any failure.

var _passed := 0
var _failed := 0


func _ready() -> void:
	test_starting_state()
	test_points_per_level()
	test_level_ten_point_total()
	test_xp_multi_level()
	test_allocation_limits()
	test_base_stats_do_not_count()
	test_tank_threshold_exact()
	test_multiple_classes_qualify()
	test_support_hybrid()
	test_choose_class_rules()
	test_respec_flow()
	test_derived_defense()
	test_near_misses()
	test_rename()
	print("\n==== %d passed, %d failed ====" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)


# --- helpers ---

func check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  ", label)
	else:
		_failed += 1
		printerr("  FAIL  ", label)


func make_level(target: int) -> CharacterData:
	var c := CharacterData.new()
	while c.level < target:
		c.level_up()
	return c


func ids(defs: Array[ClassDef]) -> Array:
	var out := []
	for d in defs:
		out.append(String(d.id))
	out.sort()
	return out


# --- tests ---

func test_starting_state() -> void:
	var c := CharacterData.new()
	check(c.level == 1 and c.unspent_points == 0, "starts level 1 with 0 points")
	var all_five := true
	for s in Stats.all():
		all_five = all_five and c.stats.get_total(s) == 5 and c.stats.get_allocated(s) == 0
	check(all_five, "all stats start at base 5, none allocated")


func test_points_per_level() -> void:
	check(CharacterData.points_for_level(2) == 5, "level 2 grants 5")
	check(CharacterData.points_for_level(5) == 5, "level 5 grants 5")
	check(CharacterData.points_for_level(6) == 3, "level 6 grants 3")
	check(CharacterData.points_for_level(20) == 3, "level 20 grants 3")


func test_level_ten_point_total() -> void:
	var c := make_level(10)
	check(c.unspent_points == 35, "level 10 = 35 points (4x5 + 5x3), got %d" % c.unspent_points)
	check(CharacterData.total_points_at_level(10) == 35, "total_points_at_level(10) == 35")


func test_xp_multi_level() -> void:
	var c := CharacterData.new()
	var needed := CharacterData.xp_to_next(1) + CharacterData.xp_to_next(2) + 7
	c.add_xp(needed)
	check(c.level == 3 and c.xp == 7, "add_xp rolls over multiple levels (lv %d, xp %d)" % [c.level, c.xp])


func test_allocation_limits() -> void:
	var c := make_level(2)  # 5 points
	check(not c.allocate(Stats.Type.HEALTH, 6), "can't allocate more than unspent")
	check(c.allocate(Stats.Type.HEALTH, 3), "allocate 3 ok")
	check(c.unspent_points == 2 and c.stats.get_total(Stats.Type.HEALTH) == 8, "points moved correctly")
	check(not c.apply_allocation({Stats.Type.LUCK: 1, Stats.Type.AGILITY: 2}), "batch over budget rejected")
	check(c.unspent_points == 2 and c.stats.get_allocated(Stats.Type.LUCK) == 0, "rejected batch changes nothing")
	check(c.apply_allocation({Stats.Type.LUCK: 1, Stats.Type.AGILITY: 1}), "batch within budget ok")


func test_base_stats_do_not_count() -> void:
	var c := make_level(10)
	check(c.get_qualifying_classes().is_empty(), "no allocation -> no class qualifies (base 5s ignored)")


func test_tank_threshold_exact() -> void:
	var c := make_level(10)
	c.apply_allocation({Stats.Type.HEALTH: 11, Stats.Type.STAMINA: 10, Stats.Type.STRENGTH: 14})
	check(ClassRegistry.get_class_def(&"tank").qualifies(c.stats), "Tank at exactly 21/35 = 60% qualifies")
	var c2 := make_level(10)
	c2.apply_allocation({Stats.Type.HEALTH: 10, Stats.Type.STAMINA: 10, Stats.Type.STRENGTH: 15})
	check(not ClassRegistry.get_class_def(&"tank").qualifies(c2.stats), "Tank at 20/35 does not qualify")


func test_multiple_classes_qualify() -> void:
	var c := make_level(10)
	c.apply_allocation({Stats.Type.INTELLIGENCE: 20, Stats.Type.STAMINA: 15})
	var q := ids(c.get_qualifying_classes())
	check(q == ["mage", "support"], "INT 20 / STA 15 -> Mage + Support, got %s" % [q])


func test_support_hybrid() -> void:
	var c := make_level(10)
	# Tank/Support hybrid: heavy Stamina, some Health and Int.
	c.apply_allocation({Stats.Type.HEALTH: 10, Stats.Type.STAMINA: 15, Stats.Type.INTELLIGENCE: 5, Stats.Type.STRENGTH: 5})
	var q := ids(c.get_qualifying_classes())
	check(q == ["support", "tank"], "Tank/Support hybrid qualifies for both, got %s" % [q])


func test_choose_class_rules() -> void:
	var early := make_level(9)
	early.allocate(Stats.Type.INTELLIGENCE, early.unspent_points)
	check(not early.choose_class(ClassRegistry.get_class_def(&"mage")), "can't choose class before level 10")

	var c := make_level(10)
	c.allocate(Stats.Type.INTELLIGENCE, 35)
	check(not c.choose_class(ClassRegistry.get_class_def(&"tank")), "can't choose unqualified class")
	check(c.choose_class(ClassRegistry.get_class_def(&"mage")), "can choose qualified class")
	check(c.get_class_def().display_name == "Mage", "class is Mage")
	check(not c.can_choose_class(), "can't pick a second tier-1 class")


func test_respec_flow() -> void:
	var c := make_level(10)
	c.allocate(Stats.Type.INTELLIGENCE, 35)
	check(c.next_respec_cost() == 0, "pre-class respec is free")
	check(c.respec() and c.unspent_points == 35 and c.stats.total_allocated() == 0, "free pre-class respec refunds all points")
	check(c.stats.get_total(Stats.Type.INTELLIGENCE) == 5, "respec keeps base stats")

	c.allocate(Stats.Type.INTELLIGENCE, 35)
	check(c.next_respec_cost() > 0, "second pre-class respec costs gold")
	c.choose_class(ClassRegistry.get_class_def(&"mage"))
	check(c.next_respec_cost() == 0, "first post-class respec is free")
	check(c.respec(), "free post-class respec works")
	check(c.has_class(), "respec keeps chosen class")

	c.allocate(Stats.Type.INTELLIGENCE, 10)
	check(c.next_respec_cost() == 500, "first paid respec = 500")
	check(not c.respec(), "can't respec without gold")
	c.gold = 600
	check(c.respec() and c.gold == 100, "paid respec deducts gold")
	c.allocate(Stats.Type.INTELLIGENCE, 5)
	check(c.next_respec_cost() == 1000, "second paid respec = 1000")


func test_derived_defense() -> void:
	var c := make_level(3)  # 10 points
	c.apply_allocation({Stats.Type.INTELLIGENCE: 5, Stats.Type.STAMINA: 3})
	# INT 10, STA 8 -> magic def = 10 + 8*0.25 = 12, physical = 8
	check(is_equal_approx(c.stats.magic_defense(), 12.0), "magic def = INT + STA/4 (%.2f)" % c.stats.magic_defense())
	check(is_equal_approx(c.stats.physical_defense(), 8.0), "physical def = STA")


func test_near_misses() -> void:
	var c := make_level(10)
	c.apply_allocation({Stats.Type.HEALTH: 6, Stats.Type.STRENGTH: 6, Stats.Type.INTELLIGENCE: 6,
		Stats.Type.STAMINA: 6, Stats.Type.AGILITY: 6, Stats.Type.LUCK: 5})
	var q := c.get_qualifying_classes()
	var misses := ClassRegistry.get_near_misses(c.stats)
	check(q.is_empty(), "even spread qualifies for nothing")
	check(misses.size() == ClassRegistry.get_tier(1).filter(func(d): return not d.is_secret).size()
		and misses[0].points_short <= misses[-1].points_short, "near misses sorted closest first")


func test_rename() -> void:
	var c := CharacterData.new()
	check(c.character_name == "Climber", "default name is Climber")
	check(c.rename("Hayden") and c.character_name == "Hayden", "rename works")
	check(c.rename("  Sir   Hayden  ") and c.character_name == "Sir Hayden", "extra spaces are trimmed")
	check(not c.rename("   ") and c.character_name == "Sir Hayden", "blank names are refused")
	c.rename("A really very long name indeed")
	check(c.character_name.length() == CharacterData.NAME_MAX_LENGTH, "names are capped at %d characters" % CharacterData.NAME_MAX_LENGTH)
	c.rename("Hayden")
	check(Combatant.from_character(c).display_name == "Hayden", "the new name shows up in battle")
