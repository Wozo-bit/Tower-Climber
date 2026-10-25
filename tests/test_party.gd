extends Node
## Party management tests: reserve, swapping, order, rows, dismissing,
## rejoining, the boss/miniboss lock and reserve XP.
## Run:  godot --headless res://tests/test_party.tscn
## Uses separate test save files, so your real save is never touched.

var _passed := 0
var _failed := 0


func _ready() -> void:
	GameState.save_dir = "user://test_saves_party"
	test_bench_and_swap()
	test_order_and_rows()
	test_caps_and_overflow()
	test_lock_on_guardian_floors()
	test_dismiss_and_rejoin()
	test_waiting_on_rest_floors()
	test_reserve_xp()
	test_benched_friend_keeps_name()
	test_save_roundtrip()
	test_party_grows()
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


## Player + friend + 2 others on a normal floor (never locked). Past floor 20
## (4 can fight) so the party is full.
func _fresh() -> void:
	GameState.reset_run()
	GameState.highest_floor = 21
	GameState.player.rename("Ophelius")
	GameState.companions.append(GameState.make_childhood_friend("Cassia"))
	GameState.companions.append(_member("Bo"))
	GameState.companions.append(_member("Di"))
	GameState.enter_floor(2)
	GameState.current_layout()


func _member(n: String) -> CharacterData:
	var c := CharacterData.new()
	c.character_name = n
	c.companion_id = StringName("test_" + n)
	return c


func _names(arr: Array) -> Array:
	return arr.map(func(c): return c.character_name)


func test_bench_and_swap() -> void:
	_fresh()
	var bo: CharacterData = GameState.companions[1]
	check(GameState.bench(bo) and GameState.reserve == [bo] and not GameState.companions.has(bo), "bench: party -> reserve")
	check(not GameState.battle_party().has(bo), "benched members don't fight")
	check(not GameState.bench(bo), "can't bench someone who isn't in the party")
	check(not GameState.bench(GameState.player), "the player can't be benched")
	check(GameState.unbench(bo) and GameState.companions.has(bo) and GameState.reserve.is_empty(), "unbench: reserve -> party")
	var eve := _member("Eve")
	GameState.reserve.append(eve)
	check(not GameState.unbench(eve), "can't unbench into a full party")
	check(GameState.swap_members(bo, eve), "swap a party member with a reserve member")
	# Unbenching put Bo last ([Cassia, Di, Bo]), so Eve takes the last spot.
	check(_names(GameState.companions) == ["Cassia", "Di", "Eve"] and GameState.reserve == [bo], "the newcomer takes their place in the order")


func test_order_and_rows() -> void:
	_fresh()
	var di: CharacterData = GameState.companions[2]
	check(GameState.move_member(di, -1) and _names(GameState.companions) == ["Cassia", "Di", "Bo"], "move up")
	check(not GameState.move_member(GameState.companions[0], -1), "can't move past the top")
	check(not GameState.move_member(GameState.player, 1), "the player always leads")
	check(GameState.battle_party()[0] == GameState.player and GameState.battle_party()[2] == di, "battle order follows the party order")
	GameState.set_member_row(di, Combatant.Row.BACK)
	check(GameState.member_row(di) == Combatant.Row.BACK and Combatant.from_character(di).row == Combatant.Row.BACK, "row set in the menu is used in battle")
	GameState.set_member_row(di, 7)
	check(di.battle_row == Combatant.Row.BACK, "row is clamped to a real row")
	var fresh := _member("Fae")
	check(GameState.member_row(fresh) == SkillLibrary.default_row_for_class(&""), "no row set = class default")


func test_caps_and_overflow() -> void:
	_fresh()
	for i in GameState.RESERVE_CAP:
		GameState.reserve.append(_member("R%d" % i))
	check(not GameState.bench(GameState.companions[1]), "can't bench into a full reserve")
	GameState.player.level_up()
	var b := GameState.recruit(&"brakka")
	check(b != null and GameState.waiting.has(b), "party + reserve full: a recruit waits at rest floors")
	check(GameState.has_recruited(&"brakka"), "a waiting recruit counts as recruited (no duplicate Brakka)")


func test_lock_on_guardian_floors() -> void:
	_fresh()
	check(not GameState.party_locked(), "normal floors: unlocked")
	GameState.enter_floor(4)   # Goblin Captain
	GameState.current_layout()
	check(GameState.party_locked() and GameState.party_lock_reason().contains("miniboss"), "miniboss floor: locked")
	var bo: CharacterData = GameState.companions[1]
	check(not GameState.bench(bo) and not GameState.dismiss(bo), "locked: no benching or dismissing")
	GameState.reserve.append(_member("Eve"))
	check(not GameState.swap_members(bo, GameState.reserve[0]), "locked: no swapping")
	check(GameState.move_member(bo, 1), "locked: order can still change")
	GameState.set_member_row(bo, Combatant.Row.BACK)
	check(bo.battle_row == Combatant.Row.BACK, "locked: rows can still change")
	GameState.floor_has_alive("miniboss").alive = false
	check(not GameState.party_locked() and GameState.bench(bo), "miniboss beaten: unlocked")
	GameState.enter_floor(10)
	GameState.current_layout()
	check(GameState.party_locked() and GameState.party_lock_reason().contains("boss"), "boss arena: locked")
	GameState.floor_has_alive("boss").alive = false
	check(not GameState.party_locked(), "boss beaten: unlocked")
	GameState.enter_floor(5)
	check(not GameState.party_locked(), "rest floors: unlocked")


func test_dismiss_and_rejoin() -> void:
	_fresh()
	var bo: CharacterData = GameState.companions[1]
	for i in 4:
		bo.level_up()
	var gear := GearItem.new()
	gear.base_id = LootTable.BASES.keys()[0]
	gear.slot = LootTable.BASES[gear.base_id].slot
	bo.equip(gear)
	var bag_before := GameState.inventory.gear.size()
	check(not GameState.dismiss(GameState.player), "the player can't be dismissed")
	check(GameState.dismiss(bo) and GameState.waiting.has(bo) and not GameState.companions.has(bo), "dismiss: off to wait at rest floors")
	check(bo.equipment.is_empty() and GameState.inventory.gear.size() == bag_before + 1, "their gear goes to the bag")
	var sandbox := CharacterData.new()
	GameState.companions.append(sandbox)
	GameState.dismiss(sandbox)
	check(sandbox.companion_id != &"", "a companion without an id gets one so they can wait on a floor")
	check(GameState.rejoin(bo) and GameState.companions.has(bo), "rejoin: back in the party")
	check(bo.level == 5, "exactly as they left (level kept)")
	GameState.reserve.append(_member("X"))
	GameState.companions.append(_member("Y"))
	for i in GameState.RESERVE_CAP - 1:
		GameState.reserve.append(_member("R%d" % i))
	check(not GameState.rejoin(sandbox) and GameState.waiting.has(sandbox), "no room anywhere: they keep waiting")
	var r := DialogueRunner.new()
	r.start(&"waiting_companion", sandbox)
	r.choose(0)
	check(r.messages.has("No room: the party and reserve are full."), "the rejoin talk explains when there's no room")


func test_waiting_on_rest_floors() -> void:
	_fresh()
	GameState.player.level_up()
	var b := GameState.recruit(&"brakka")
	GameState.dismiss(b)
	GameState.enter_floor(5)
	var layout := GameState.current_layout()
	var id := GameState.waiting_npc_id(b)
	var pos := Vector2i(-1, -1)
	for p in layout.npcs:
		if layout.npcs[p] == id:
			pos = p
	check(pos.x >= 0, "a dismissed companion waits on rest floors")
	check(absi(pos.x - layout.campfire.x) + absi(pos.y - layout.campfire.y) <= 2, "by the campfire")
	check(not layout.npcs.values().has(&"brakka"), "no second Brakka NPC while he waits")
	check(GameState.waiting_companion(id) == b, "the floor NPC maps back to the companion")
	GameState.enter_floor(6)
	check(not GameState.current_layout().npcs.values().has(id), "not on combat floors")
	GameState.enter_floor(5)
	var r := DialogueRunner.new()
	r.start(&"waiting_companion", b)
	check(r.speaker() == "Brakka" and r.text().contains("Ophelius"), "{npc} and {player} in the waiting talk")
	r.choose(0)
	# The test party is full, so he comes back to the reserve.
	check(r.finished and GameState.reserve.has(b) and r.messages.has("Brakka is back (on the reserve)!"), "talking to them brings them back")
	GameState.place_npcs(layout)
	check(not layout.npcs.values().has(id), "they leave the floor with you")
	# A crowd at the campfire still all fits on the floor.
	for i in 12:
		var c := _member("W%d" % i)
		GameState.waiting.append(c)
	GameState.place_npcs(layout)
	check(layout.npcs.size() >= 12 and layout.distance_map(layout.start).has(layout.stairs), "lots of waiting companions still fit, stairs reachable")


func test_reserve_xp() -> void:
	_fresh()
	var bo: CharacterData = GameState.companions[1]
	GameState.bench(bo)
	var w := _member("W")
	GameState.waiting.append(w)
	bo.level = 10   # so 40 XP doesn't level them up (and reset the XP counter)
	bo.xp = 0
	check(GameState.grant_reserve_xp(80) == 40 and bo.xp == 40, "reserve gets half the battle XP")
	check(w.xp == 0, "waiting companions get none")
	check(GameState.grant_reserve_xp(1) == 0, "rounds down")


func test_benched_friend_keeps_name() -> void:
	_fresh()
	var friend := GameState.childhood_friend()
	check(GameState.bench(friend) and GameState.childhood_friend() == friend, "friend can be benched and is still found")
	check(DialogueRunner.fill("{friend}") == "Cassia", "{friend} still uses their name")
	GameState.dismiss(friend)
	check(GameState.childhood_friend() == friend, "friend can be dismissed too (and is still found)")


## Hayden 2026-10-25: 2 fight on floors 1-20, then 2 more every 20 floors.
func test_party_grows() -> void:
	var sizes := [1, 20, 21, 40, 41, 61, 81, 100, 500].map(func(f): return GameState.party_size_at(f))
	check(sizes == [2, 2, 4, 4, 6, 8, 10, 10, 10], "2 -> 4 -> 6 -> 8 -> 10 every 20 floors, 10 at most (%s)" % [sizes])
	GameState.start_new_game("Ophelius", "Cassia", 1)
	check(GameState.battle_party().size() == 2, "a new game: you and your childhood friend")
	var bo := _member("Bo")
	GameState._add_member(bo)
	check(GameState.reserve.has(bo) and not GameState.unbench(bo), "a third member waits on the reserve")
	var di := _member("Di")
	GameState._add_member(di)
	GameState.enter_floor(20)
	check(GameState.battle_party().size() == 2, "still 2 on floor 20")
	GameState.quests.messages.clear()
	GameState.enter_floor(21)
	check(GameState.battle_party().size() == 4 and GameState.companions.has(bo) and GameState.companions.has(di),
		"floor 21: room for 4, and the reserve steps up")
	check(GameState.quests.messages.any(func(m): return m.contains("4 fighters")), "a notice says so")
	GameState.enter_floor(15)   # back at a checkpoint after a wipe
	check(GameState.battle_party().size() == 4, "a wipe back to an earlier floor doesn't shrink it")
	GameState.save_game()
	GameState.load_game(1)
	check(GameState.party_size() == 4 and GameState.companions.size() == 3, "saved")
	# Bosses fight the whole party alone: their HP follows the party slots.
	check(GameState.guardian_hp_mult(4) == 1.0 and GameState.guardian_hp_mult(2) < 0.65
		and GameState.guardian_hp_mult(10) > 1.9, "boss HP: x0.59 for 2, x1 for 4, x2 for 10")
	var hp := []
	for floor_n in [1, 81]:
		GameState.highest_floor = floor_n
		var b := BattleManager.new()
		GameState.configure_battle(b)
		b.enemy_scale = 1.0
		b.setup([GameState.player] as Array[CharacterData], EnemyLibrary.build_group([&"goblin_captain", &"goblin"]), 1)
		hp.append([b.enemies[0].max_hp, b.enemies[1].max_hp])
	check(hp[1][0] > hp[0][0] * 3 and hp[1][1] == hp[0][1], "a big party faces a tougher boss; normal enemies are unchanged")


func test_save_roundtrip() -> void:
	GameState.start_new_game("Ophelius", "Cassia", 1)
	GameState.highest_floor = 21
	GameState.companions.append(_member("Bo"))
	var di := _member("Di")
	GameState.companions.append(di)
	GameState.set_member_row(di, Combatant.Row.BACK)
	GameState.move_member(di, -1)
	GameState.reserve.append(_member("Eve"))
	GameState.waiting.append(_member("Wren"))
	check(GameState.save_game(), "save")
	GameState.reset_run()
	check(GameState.load_game(1), "load")
	check(_names(GameState.companions) == ["Cassia", "Di", "Bo"], "party order is saved")
	check(GameState.companions[1].battle_row == Combatant.Row.BACK, "rows are saved")
	check(_names(GameState.reserve) == ["Eve"] and _names(GameState.waiting) == ["Wren"], "reserve and waiting are saved")
	# A tampered save with an oversized party and reserve gets trimmed.
	var d := SaveSerializer.read_json(GameState.slot_path(1))
	for i in 5:
		d.companions.append(SaveSerializer.character_to_dict(_member("C%d" % i)))
	for i in 10:
		d.reserve.append(SaveSerializer.character_to_dict(_member("R%d" % i)))
	SaveSerializer.write_json(GameState.slot_path(1), d)
	GameState.load_game(1)
	check(GameState.companions.size() == GameState.party_size() - 1 and GameState.reserve.size() == GameState.RESERVE_CAP,
		"tampered save: party and reserve trimmed to their caps")
	check(GameState.companions.size() + GameState.reserve.size() + GameState.waiting.size() == 3 + 5 + 1 + 10 + 1,
		"nobody is lost when trimming (extras wait at rest floors)")
