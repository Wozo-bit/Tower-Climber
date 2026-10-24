extends Node
## Dialogue, NPC and recruiting tests.  Run:  godot --headless res://tests/test_dialogue.tscn
## Uses separate test save files, so your real save is never touched.

var _passed := 0
var _failed := 0


func _ready() -> void:
	GameState.save_dir = "user://test_saves_dialogue"
	test_library_is_valid()
	test_validator_catches_typos()
	test_runner_basics()
	test_conditions()
	test_effects()
	test_merchant_shop_and_clue()
	test_recruiting()
	test_reserve_when_full()
	test_npc_placement()
	test_clues_unlock_secret_path()
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


func _fresh(floor_n: int = 1) -> void:
	GameState.reset_run()
	GameState.player.rename("Ophelius")
	GameState.companions.append(GameState.make_childhood_friend("Cassia"))
	GameState.floor_number = floor_n


func test_library_is_valid() -> void:
	var problems := DialogueLibrary.validate_all()
	for p in problems:
		printerr("    ", p)
	check(problems.is_empty(), "every dialogue is valid (nodes, conditions, effects)")
	var all_known := true
	for id in NpcLibrary.NPCS:
		if not DialogueLibrary.has_dialogue(NpcLibrary.NPCS[id].dialogue):
			all_known = false
	check(all_known, "every NPC points to a real dialogue")


func test_validator_catches_typos() -> void:
	var bad := {
		"start": "a",
		"nodes": {
			"a": { "text": "hi", "next": "nope", "effects": [{ "set_flagg": &"x" }] },
			"b": { "text": "", "choices": [{ "text": "go", "next": "missing", "if": { "flagg": &"x" } }] },
		},
	}
	var p := DialogueLibrary.validate(&"bad", bad)
	var joined := "\n".join(p)
	check(joined.contains("next 'nope'"), "validator: missing next node")
	check(joined.contains("unknown effect"), "validator: misspelled effect")
	check(joined.contains("unknown condition 'flagg'"), "validator: misspelled condition")
	check(joined.contains("missing node 'missing'") and joined.contains("no text"), "validator: bad choice + empty text")
	check(not DialogueLibrary.validate(&"r", { "start": "a", "nodes": { "a": { "text": "x",
		"effects": [{ "recruit": &"scorched_mural" }] } } }).is_empty(), "validator: can't recruit a lore object")


func test_runner_basics() -> void:
	_fresh(6)
	var r := DialogueRunner.new()
	check(not r.start(&"no_such_dialogue") and r.finished, "unknown dialogue doesn't start")
	check(r.start(&"brakka"), "dialogue starts")
	check(r.node_id == "first" and r.speaker() == "Brakka" and not r.has_choices(), "opens on the first-meeting line")
	check(GameState.has_flag(&"met_brakka"), "node effects run when the line is shown")
	r.advance()
	check(r.speaker() == "Cassia" and r.text().contains("Ophelius"), "{friend} and {player} are filled in")
	r.advance()
	check(r.has_choices() and r.choices().size() == 2, "choice node shows its choices")
	r.advance()
	check(r.node_id == "again", "'Next' does nothing on a choice node")
	check(r.choose(1) and r.finished, "a choice without 'next' ends the talk")
	r.start(&"brakka")
	check(r.node_id == "again", "start list picks a different opening once met")
	check(not r.choose(7), "out-of-range choice is refused")


func test_conditions() -> void:
	_fresh(3)
	check(DialogueRunner.check({}), "empty condition passes")
	GameState.set_flag(&"x")
	check(DialogueRunner.check({ "flag": &"x" }) and not DialogueRunner.check({ "not_flag": &"x" }), "flag / not_flag")
	check(DialogueRunner.check({ "min_floor": 3, "max_floor": 3 }) and not DialogueRunner.check({ "min_floor": 4 }), "floor range")
	GameState.player.gold = 50
	check(DialogueRunner.check({ "gold": 50 }) and not DialogueRunner.check({ "gold": 51 }), "gold")
	check(DialogueRunner.check({ "item": &"potion" }) and not DialogueRunner.check({ "item": &"goddess_tear" }), "item")
	check(DialogueRunner.check({ "ng_plus": false }) and not DialogueRunner.check({ "ng_plus": true }), "ng_plus")
	check(DialogueRunner.check({ "min_level": 1 }) and not DialogueRunner.check({ "min_level": 2 }), "min_level")
	check(not DialogueRunner.check({ "flag": &"x", "gold": 999 }), "all keys must pass")
	check(not DialogueRunner.check({ "recruited": &"brakka" }), "recruited (not yet)")


func test_effects() -> void:
	_fresh(3)
	var r := DialogueRunner.new()
	r._nodes = { "a": { "text": "x" } }
	r._apply_effects([{ "set_flag": &"f" }, { "give_item": &"ether", "count": 2 }, { "give_gold": 30 },
		{ "take_gold": 10 }, { "toast": "Hi {player}" }])
	check(GameState.has_flag(&"f"), "set_flag")
	check(GameState.inventory.count(&"ether") == 3, "give_item with count")
	check(GameState.player.gold == 20, "give_gold / take_gold")
	check(r.messages.has("Hi Ophelius"), "toast message (with names filled in)")
	r._apply_effects([{ "clear_flag": &"f" }, { "take_gold": 999 }])
	check(not GameState.has_flag(&"f") and GameState.player.gold == 0, "clear_flag, gold never goes negative")
	GameState.player.set_current_hp(1)
	r._apply_effects([{ "heal_party": true }])
	check(GameState.player.current_hp() == GameState.player.max_hp(), "heal_party")


func test_merchant_shop_and_clue() -> void:
	_fresh(5)
	var r := DialogueRunner.new()
	r.start(&"merchant")
	var texts := r.choices().map(func(c): return c.text)
	check(texts.size() == 2 and not texts.has("Heard any odd stories?"), "merchant's story is hidden early in the climb")
	r.choose(0)
	check(r.finished and r.requests.has("shop"), "'Let's trade' ends the talk and asks for the shop")
	GameState.floor_number = 15
	r.start(&"merchant")
	check(r.choices().size() == 3, "story option appears from floor 10")
	r.choose(1)
	check(GameState.has_flag(&"clue_ash_merchant_story"), "hearing the story sets the Ashbound clue")
	r.advance()
	check(r.node_id == "hello" and r.choices().size() == 2, "back to the menu, story option gone")


func test_recruiting() -> void:
	_fresh(5)
	for i in 11:
		GameState.player.level_up()   # player level 12
	var r := DialogueRunner.new()
	r.start(&"brakka")
	r.advance()
	r.advance()
	r.choose(0)
	check(GameState.has_recruited(&"brakka"), "recruit choice adds Brakka")
	var b: CharacterData = GameState.companions[-1]
	check(b.companion_id == &"brakka" and b.character_name == "Brakka", "recruit has its NPC id and name")
	check(b.level == 11, "joins at player level - 1 (%d)" % b.level)
	check(b.unspent_points == 0 and b.stats.total_allocated() == CharacterData.total_points_at_level(11), "all points spent by its build")
	check(b.class_id == &"tank", "takes its class at level 10+")
	check(r.messages.has("Brakka joined the party!"), "join message")
	check(GameState.recruit(&"brakka") == null, "can't recruit the same NPC twice")
	check(GameState.recruit(&"scorched_mural") == null, "lore objects can't be recruited")
	_fresh(5)
	var low := GameState.recruit(&"brakka")
	check(low.level == 1 and not low.has_class(), "a level-1 player gets a level-1 recruit, no class yet")
	check(NpcLibrary.split_points(10, { 0: 1, 1: 1, 2: 1 }).values().reduce(func(a, x): return a + x) == 10,
		"point split always adds up")


func test_reserve_when_full() -> void:
	_fresh(5)
	GameState.ensure_test_companions()   # leaves friend + 3 = full
	while GameState.companions.size() < GameState.MAX_PARTY_SIZE - 1:
		GameState.companions.append(CharacterData.new())
	var count := GameState.companions.size()
	var c := GameState.recruit(&"brakka")
	check(c != null and GameState.companions.size() == count and GameState.reserve.has(c), "full party: recruit goes to the reserve")
	check(not GameState.battle_party().has(c), "reserve members don't fight")
	check(GameState.has_recruited(&"brakka"), "reserve counts as recruited")


func test_npc_placement() -> void:
	_fresh(5)
	GameState.enter_floor(5)
	var layout := GameState.current_layout()
	var brakka_pos := Vector2i(-1, -1)
	for p in layout.npcs:
		if layout.npcs[p] == &"brakka":
			brakka_pos = p
	check(brakka_pos.x >= 0, "Brakka waits on rest floors from floor 5")
	check(absi(brakka_pos.x - layout.campfire.x) + absi(brakka_pos.y - layout.campfire.y) <= 2, "Brakka sits by the campfire")
	check(layout.is_blocked(brakka_pos), "NPCs block movement (bump to talk)")
	check(layout.distance_map(layout.start).has(layout.stairs), "stairs still reachable")
	var again := GameState.current_layout()
	check(again.npcs == layout.npcs, "same spot when the floor is rebuilt")
	GameState.recruit(&"brakka")
	GameState.place_npcs(layout)
	check(not layout.npcs.values().has(&"brakka"), "recruited NPCs leave the floor")

	_fresh(4)
	GameState.enter_floor(4)
	check(GameState.current_layout().npcs.is_empty(), "no NPCs on early combat floors")

	# The mural: 40% of eligible combat floors, never blocking anything.
	var seen := 0
	var safe := true
	for s in 60:
		_fresh(12)
		GameState.floor_seed = s
		GameState.floor_ready = false
		var l := GameState.current_layout()
		if l.npcs.values().has(&"scorched_mural"):
			seen += 1
			var dist := l.distance_map(l.start)
			if not dist.has(l.stairs) or dist.size() + l.npcs.size() != FloorLayout.generate(s, 12, false).distance_map(l.start).size():
				safe = false
	check(seen > 10 and seen < 40, "mural shows up on some floors, not all (%d / 60)" % seen)
	check(safe, "lore objects never cut off part of the floor")
	_fresh(12)
	GameState.set_flag(&"clue_ash_scorched_mural")
	var gone := true
	for s in 30:
		GameState.floor_seed = s
		GameState.floor_ready = false
		if GameState.current_layout().npcs.values().has(&"scorched_mural"):
			gone = false
	check(gone, "a clue that's been read never appears again")

	# Boss floors: nobody until the boss is down.
	_fresh(10)
	GameState.enter_floor(10)
	check(GameState.current_layout().npcs.is_empty(), "boss arena is empty while the boss lives")
	GameState.floor_enemies[0].alive = false
	var cleared := GameState.current_layout()
	check(cleared.npcs.values().has(&"feather_in_embers"), "the feather appears in the embers after the floor-10 boss")


func test_clues_unlock_secret_path() -> void:
	_fresh(15)
	var r := DialogueRunner.new()
	for id in [&"scorched_mural", &"feather_in_embers"]:
		r.start(id)
		r.advance()
	r.start(&"merchant")
	r.choose(1)
	check(SecretPaths.is_on_path(&"ashbound", GameState.story_flags), "all 3 Ashbound clues come from dialogue")
	check(DialogueRunner.check({ "on_secret_path": &"ashbound" }), "on_secret_path condition")


func test_save_roundtrip() -> void:
	GameState.start_new_game("Ophelius", "Cassia", 1)
	GameState.floor_number = 5
	GameState.recruit(&"brakka")
	GameState.reserve.append(NpcLibrary.make_recruit(&"brakka", 3))
	GameState.reserve[0].character_name = "Spare"
	GameState.set_flag(&"met_brakka")
	check(GameState.save_game(), "save with a recruit and a reserve member")
	GameState.reset_run()
	check(GameState.load_game(1), "load it back")
	check(GameState.has_recruited(&"brakka") and GameState.companions.size() == 2, "recruit is still in the party")
	check(GameState.reserve.size() == 1 and GameState.reserve[0].character_name == "Spare", "reserve is saved")
	check(GameState.has_flag(&"met_brakka"), "dialogue flags are saved")
