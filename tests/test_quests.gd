extends Node
## Quest tests: the quest library, progress for every goal type, rewards,
## expiry and failing, dialogue hooks, the notice board and saving.
## Run:  godot --headless res://tests/test_quests.tscn
## Uses separate test save files, so your real save is never touched.

var _passed := 0
var _failed := 0


func _ready() -> void:
	GameState.save_dir = "user://test_saves_quests"
	test_library_is_valid()
	test_start_and_pin()
	test_defeat_goals()
	test_collect_and_deliver()
	test_expiry_and_failing()
	test_reach_and_find()
	test_main_quest()
	test_notice_board()
	test_dialogue_conditions()
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
	GameState.player.legacy_id = "test-run"
	GameState.companions.append(GameState.make_childhood_friend("Cassia"))
	GameState.floor_number = floor_n


func _defs(ids: Array) -> Array:
	return ids.map(func(id): return EnemyLibrary.get_enemy(id))


## Picks a dialogue choice by its text (so new options don't shift the tests).
func _choose_text(r: DialogueRunner, text: String) -> void:
	for c in r.choices():
		if c.text == text:
			r.choose(c.index)
			return
	printerr("    no choice '%s'" % text)


func _rng(s: int = 1) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


func test_library_is_valid() -> void:
	var problems := QuestLibrary.validate_all()
	for p in problems:
		printerr("    ", p)
	check(problems.is_empty(), "every quest is valid")
	check(DialogueLibrary.validate_all().is_empty(), "dialogue with quest hooks is still valid")
	var bad := { "title": "", "kind": "nope", "steps": [
		{ "text": "x", "goal": { "type": "defeat", "family": &"dragons", "count": 0 } },
		{ "text": "y", "goal": { "type": "collect", "item": &"no_such_item", "count": 2 } },
		{ "text": "z", "goal": { "type": "dance" } }] }
	var joined := "\n".join(QuestLibrary.validate(&"bad", bad))
	check(joined.contains("no title") and joined.contains("kind must be"), "validator: title and kind")
	check(joined.contains("unknown family") and joined.contains("count must be"), "validator: bad defeat goal")
	check(joined.contains("unknown item") and joined.contains("unknown goal type"), "validator: bad collect / goal type")


func test_start_and_pin() -> void:
	_fresh(3)
	var ql := GameState.quests
	check(ql.is_new(&"slime_survey") and ql.start(&"slime_survey"), "start a quest")
	check(ql.is_active(&"slime_survey") and not ql.start(&"slime_survey"), "can't start it twice")
	check(ql.pinned == &"slime_survey", "the first quest gets pinned")
	check(ql.messages.has("New quest: Slime Survey"), "a 'New quest' toast")
	check(not ql.start(&"no_such_quest"), "unknown quests can't start")
	ql.start(&"torn_map")
	ql.pin(&"torn_map")
	check(ql.pinned == &"torn_map", "pin another")
	ql.fail(&"torn_map")
	check(ql.pinned == &"slime_survey", "a finished/failed pinned quest hands the pin to another")


func test_defeat_goals() -> void:
	_fresh(5)
	var ql := GameState.quests
	ql.start(&"slime_survey")
	ql.on_battle_won(_defs([&"slime", &"bubble_slime", &"goblin"]), _rng())
	check(ql.step_progress(&"slime_survey") == [2, 8], "family goal counts every slime, not goblins")
	check(ql.step_text(&"slime_survey") == "Defeat slimes (2/8)", "step text with progress")
	var gold := GameState.player.gold
	ql.on_battle_won(_defs([&"slime", &"slime", &"slime", &"mud_slime", &"king_slime", &"slime"]), _rng())
	check(ql.is_done(&"slime_survey"), "completes at 8")
	check(GameState.player.gold == gold + 200 and GameState.player.xp > 0, "gold and XP rewards")
	check(GameState.bestiary.known_affinities(EnemyLibrary.get_enemy(&"mud_slime")).size() == Element.Type.size(),
		"'reveal_family' reward fills in the bestiary for every slime")
	check(ql.messages.any(func(m): return m.begins_with("Quest complete: Slime Survey")), "completion toast")
	check(QuestLog.matches({ "kind": "boss" }, EnemyLibrary.get_enemy(&"goblin_king"))
		and not QuestLog.matches({ "kind": "boss" }, EnemyLibrary.get_enemy(&"hobgoblin"))
		and QuestLog.matches({ "kind": "miniboss" }, EnemyLibrary.get_enemy(&"hobgoblin"))
		and QuestLog.matches({ "enemy": &"goblin" }, EnemyLibrary.get_enemy(&"goblin")), "enemy / kind goals")


func test_collect_and_deliver() -> void:
	_fresh(5)
	var ql := GameState.quests
	ql.on_battle_won(_defs([&"slime", &"slime", &"slime", &"slime"]), _rng())
	check(GameState.inventory.count(&"glowcap") == 0, "no quest drops before you have the quest")
	var r := DialogueRunner.new()
	r.start(&"merchant")
	_choose_text(r, "Need help with anything?")
	check(ql.is_active(&"glowcap_delivery"), "the merchant gives the quest")
	var fights := 0
	while GameState.inventory.count(&"glowcap") < 3 and fights < 100:
		ql.on_battle_won(_defs([&"slime", &"goblin"]), _rng(fights))
		fights += 1
	check(GameState.inventory.count(&"glowcap") == 3, "slimes drop glowcaps while you need them (%d fights)" % fights)
	for i in 30:
		ql.on_battle_won(_defs([&"slime"]), _rng(500 + i))
	check(GameState.inventory.count(&"glowcap") == 3, "...and stop once you have enough")
	check(ql.step_index(&"glowcap_delivery") == 1, "collected: on to the delivery step")
	check(not ItemLibrary.get_item(&"glowcap").description.is_empty() and ItemLibrary.get_item(&"glowcap").quest_item
		and not GameState.inventory.use_on_character(&"glowcap", GameState.player), "quest items can't be used")
	r.start(&"merchant")
	check(r.choices().any(func(c): return c.text == "Here are your glowcaps."), "hand-in option appears")
	_choose_text(r, "Here are your glowcaps.")
	check(ql.is_done(&"glowcap_delivery") and GameState.inventory.count(&"glowcap") == 0
		and GameState.inventory.count(&"advanced_potion") == 2, "handed over: quest done, items rewarded")


func test_expiry_and_failing() -> void:
	_fresh(12)
	var ql := GameState.quests
	ql.start(&"glowcap_delivery")
	GameState.enter_floor(15)
	check(ql.is_active(&"glowcap_delivery"), "still fine on floor 15")
	GameState.enter_floor(16)
	check(ql.is_failed(&"glowcap_delivery") and GameState.has_flag(&"glowcaps_failed"),
		"climbing past the deadline fails it and sets its fail flag (which can open something else)")
	check(ql.messages.any(func(m): return m.contains("Quest failed")), "failure toast")
	ql.start(&"torn_map")
	var r := DialogueRunner.new()
	r._apply_effects([{ "fail_quest": &"torn_map" }])
	check(ql.is_failed(&"torn_map"), "a dialogue choice can fail a quest")
	check(not ql.fail(&"torn_map"), "can't fail it twice")


func test_reach_and_find() -> void:
	_fresh(3)
	var ql := GameState.quests
	var r := DialogueRunner.new()
	r.start(&"torn_map")
	check(ql.is_active(&"torn_map") and ql.step_index(&"torn_map") == 0, "reading the torn map starts its quest")
	GameState.enter_floor(6)
	check(ql.step_index(&"torn_map") == 1, "reaching floor 6 completes the 'climb' step")
	var layout := GameState.current_layout()
	check(layout.npcs.values().has(&"hidden_cache"), "the hidden cache appears once you're on that step")
	check(not layout.npcs.values().has(&"torn_map"), "the map doesn't appear again once taken")
	r.start(&"hidden_cache")
	check(ql.is_done(&"torn_map"), "finding the cache completes it")
	var charm: GearItem = GameState.inventory.gear.filter(func(g): return g.display_name == "Cartographer's Charm")[0]
	check(charm.quest_reward and not charm.carries_into_ng_plus(), "quest gear is marked quest_reward (never NG+)")
	GameState.place_npcs(layout)
	check(not layout.npcs.values().has(&"hidden_cache"), "the cache is gone afterwards")


func test_main_quest() -> void:
	GameState.start_new_game("Ophelius", "Cassia", 1)
	var ql := GameState.quests
	check(ql.is_active(&"main_climb"), "the main questline starts with a new game")
	ql.on_battle_won(_defs([&"hobgoblin"]), _rng())
	check(ql.step_index(&"main_climb") == 0, "a miniboss doesn't count as the floor-10 guardian")
	GameState.floor_number = 10
	ql.on_battle_won(_defs([&"goblin_king", &"goblin_sorcerer"]), _rng())
	check(ql.step_index(&"main_climb") == 1, "beating the floor-10 boss advances it")
	GameState.enter_floor(11)
	check(ql.step_index(&"main_climb") == 2, "reaching floor 11 too")


func test_notice_board() -> void:
	_fresh(5)
	GameState.stage_themes = [&"slime_pits", &"orc_stronghold"]
	var ql := GameState.quests
	var offers := ql.board_offers(5)
	check(offers.any(func(o): return o.id == &"slime_survey"), "hand-written board jobs show up when they fit")
	var bounties := offers.filter(func(o): return o.def.kind == "bounty")
	check(bounties.size() == QuestLog.BOUNTIES_PER_BOARD, "3 generated bounties per board")
	var fits := bounties.all(func(o):
		var g: Dictionary = o.def.steps[0].goal
		return g.get("family") == &"slime" or EnemyLibrary.get_enemy(g.get("enemy", &"slime")).family == &"slime")
	check(fits, "bounties fit the stage (Slime Pits -> slimes)")
	var targets := bounties.map(func(o): return str(o.def.steps[0].goal.get("family", o.def.steps[0].goal.get("enemy"))))
	var unique := {}
	for t in targets:
		unique[t] = true
	check(unique.size() == targets.size(), "no two bounties on a board want the same thing (%s)" % ", ".join(targets))
	check(QuestLibrary.validate(&"b", bounties[0].def).is_empty(), "generated bounties are valid quests")
	check(str(ql.board_offers(5)) == str(offers), "same run + same floor = same board")
	check(ql.board_offers(15) != offers, "a different rest floor has different bounties")
	check(ql.accept(bounties[0]) and ql.is_active(bounties[0].id), "take a bounty")
	check(not ql.board_offers(5).any(func(o): return o.id == bounties[0].id), "taken jobs leave the board")
	check(NoticeBoardPanel.reward_text(bounties[0].def.rewards).contains("gold"), "reward text: %s" % NoticeBoardPanel.reward_text(bounties[0].def.rewards))
	_fresh(2)
	check(not GameState.quests.board_offers(2).any(func(o): return o.id == &"slime_survey"), "board jobs respect their conditions (Slime Survey from floor 5)")
	check(FloorLayout.generate(1, 5, true).board.x >= 0 and FloorLayout.generate(1, 6, false).board.x < 0,
		"rest floors have a notice board, normal floors don't")
	var rest := FloorLayout.generate(1, 5, true)
	check(rest.is_blocked(rest.board) and rest.distance_map(rest.start).has(rest.stairs), "the board is solid (bump to read) and blocks nothing")


func test_dialogue_conditions() -> void:
	_fresh(5)
	check(DialogueRunner.check({ "quest_new": &"torn_map" }), "quest_new")
	GameState.quests.start(&"torn_map")
	check(DialogueRunner.check({ "quest_active": &"torn_map", "quest_on_step": [&"torn_map", 0] })
		and not DialogueRunner.check({ "quest_on_step": [&"torn_map", 1] }), "quest_active / quest_on_step")
	GameState.quests.fail(&"torn_map")
	check(DialogueRunner.check({ "quest_failed": &"torn_map" }) and not DialogueRunner.check({ "quest_done": &"torn_map" }),
		"quest_failed / quest_done")
	var bad := { "start": "a", "nodes": { "a": { "text": "x", "effects": [{ "start_quest": &"nope" }],
		"choices": [{ "text": "y", "if": { "quest_on_step": [&"torn_map", 9] } }] } } }
	var joined := "\n".join(DialogueLibrary.validate(&"bad", bad))
	check(joined.contains("unknown quest 'nope'") and joined.contains("quest_on_step needs"), "dialogue validator checks quest ids and steps")


func test_save_roundtrip() -> void:
	GameState.start_new_game("Ophelius", "Cassia", 1)
	GameState.player.legacy_id = "test-run"
	var ql := GameState.quests
	ql.start(&"slime_survey")
	ql.on_battle_won(_defs([&"slime", &"slime", &"slime"]), _rng())
	var bounty: Dictionary = ql.board_offers(5).filter(func(o): return o.def.kind == "bounty")[0]
	ql.accept(bounty)
	ql.start(&"torn_map")
	ql.fail(&"torn_map")
	ql.pin(&"slime_survey")
	check(GameState.save_game(), "save")
	GameState.reset_run()
	check(GameState.load_game(1), "load")
	ql = GameState.quests
	check(ql.is_active(&"slime_survey") and ql.step_progress(&"slime_survey") == [3, 8], "progress is saved")
	check(ql.is_active(bounty.id) and ql.def_of(bounty.id).title == bounty.def.title, "accepted bounties are saved whole")
	check(ql.is_failed(&"torn_map") and ql.is_active(&"main_climb") and ql.pinned == &"slime_survey", "failed, main and pinned are saved")
	var d := SaveSerializer.read_json(GameState.slot_path(1))
	d.quests.active["no_such_quest"] = { "step": 0 }
	d.quests.active["slime_survey"] = { "step": 99, "progress": -5 }
	d.quests.bounties["bounty_9_9"] = { "title": "Evil", "steps": [{ "text": "x", "goal": { "type": "collect", "item": "gold" } }] }
	d.quests.completed.append("fake_quest")
	SaveSerializer.write_json(GameState.slot_path(1), d)
	GameState.load_game(1)
	ql = GameState.quests
	check(not ql.active.has(&"no_such_quest") and not ql.completed.has(&"fake_quest"), "tampered save: unknown quests dropped")
	check(ql.step_index(&"slime_survey") == 0 and ql.active[&"slime_survey"].progress == 0, "tampered save: step and progress clamped")
	check(not ql.bounties.has(&"bounty_9_9"), "tampered save: invalid bounty dropped")
