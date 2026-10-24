extends Node
## Tower floor tests.  Run:  godot --headless res://tests/test_tower.tscn

var _passed := 0
var _failed := 0


func _ready() -> void:
	test_layout_deterministic()
	test_layouts_always_solvable()
	test_rest_floor()
	test_floor_state_and_rewards()
	test_defeat_sends_to_checkpoint()
	test_enemy_scaling()
	test_shop()
	print("\n==== %d passed, %d failed ====" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)


func check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  ", label)
	else:
		_failed += 1
		printerr("  FAIL  ", label)


func test_layout_deterministic() -> void:
	var a := FloorLayout.generate(1234, 3, false)
	var b := FloorLayout.generate(1234, 3, false)
	var c := FloorLayout.generate(9999, 3, false)
	check(a.tiles == b.tiles and a.enemy_spawns == b.enemy_spawns and a.stairs == b.stairs, "same seed = same floor")
	check(a.tiles != c.tiles, "different seed = different floor")


func test_layouts_always_solvable() -> void:
	var ok := true
	var enemies_ok := true
	var spawn_ok := true
	for s in 300:
		var f := FloorLayout.generate(s, 1 + s % 12, false)
		var dist := f.distance_map(f.start)
		if not dist.has(f.stairs):
			ok = false
		if f.enemy_spawns.size() != FloorLayout.enemy_count_for_floor(f.floor_number):
			enemies_ok = false
		for e in f.enemy_spawns:
			if not dist.has(e) or dist[e] < 7:
				spawn_ok = false
	check(ok, "stairs reachable on 300 random floors")
	check(enemies_ok, "every floor gets its full enemy count")
	check(spawn_ok, "enemies spawn reachable and >= 7 steps from the entrance")


func test_rest_floor() -> void:
	check(GameState.is_rest_floor(5) and GameState.is_rest_floor(15) and not GameState.is_rest_floor(4) and not GameState.is_rest_floor(10), "rest floor every 5th floor, except boss floors")
	var f := FloorLayout.generate(1, 5, true)
	check(f.enemy_spawns.is_empty(), "rest floor has no enemies")
	check(f.is_blocked(f.campfire) and f.is_blocked(f.merchant), "campfire & merchant are solid (bump to use)")
	check(f.distance_map(f.start).has(f.stairs), "rest floor stairs reachable")


func test_floor_state_and_rewards() -> void:
	GameState.enter_floor(2)
	var layout := GameState.current_layout()
	check(GameState.floor_enemies.size() == layout.enemy_spawns.size(), "floor enemies rolled on first visit")
	var groups_before := str(GameState.floor_enemies)
	GameState.current_layout()
	check(str(GameState.floor_enemies) == groups_before, "revisiting (after a battle) keeps the same enemies")
	GameState.active_enemy_index = 0
	GameState.return_scene = ""   # don't change scenes in the test
	GameState.finish_battle(BattleManager.Outcome.VICTORY)
	check(not GameState.floor_enemies[0].alive, "victory removes that enemy from the floor")
	check(GameState.floor_enemies[1].alive, "other enemies stay")


func test_defeat_sends_to_checkpoint() -> void:
	GameState.ensure_test_companions()
	GameState.enter_floor(5)       # rest floor -> checkpoint
	GameState.enter_floor(7)
	GameState.player.gold = 100
	for m in GameState.battle_party():
		m.set_current_hp(0)
	GameState.return_scene = ""
	GameState.finish_battle(BattleManager.Outcome.DEFEAT)
	check(GameState.floor_number == 5, "wipe sends you back to the last rest floor")
	check(GameState.player.gold == 80, "wipe costs 20% gold")
	check(not GameState.party_all_downed() and GameState.player.current_hp() == GameState.player.max_hp(), "party revived at full")


func test_enemy_scaling() -> void:
	var def := EnemyLibrary.get_enemy(&"goblin")
	var weak := Combatant.from_enemy(def, GameState.enemy_scale_for_floor(1))
	var strong := Combatant.from_enemy(def, GameState.enemy_scale_for_floor(10))
	check(weak.max_hp < def.max_hp and strong.max_hp > def.max_hp, "enemies scale with floor (%d / %d / %d HP)" % [weak.max_hp, def.max_hp, strong.max_hp])
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var small := true
	for i in 50:
		if EnemyLibrary.encounter_for_floor(2, rng).size() > 2:
			small = false
	check(small, "early floors roll small groups")


func test_shop() -> void:
	GameState.player.gold = 50
	var before := GameState.inventory.count(&"potion")
	check(GameState.buy_item(&"potion") and GameState.player.gold == 10, "buy Potion for 40g")
	check(GameState.inventory.count(&"potion") == before + 1, "potion added to bag")
	check(not GameState.buy_item(&"potion"), "can't buy without gold")
