extends Node
## Tutorial tips: the TipLibrary data, the Tips autoload (queue, seen list kept
## across runs, the system window) and Tab -> Guide.
## Run:  godot --headless res://tests/test_tips.tscn

var _passed := 0
var _failed := 0


func _ready() -> void:
	GameState.save_dir = "user://test_saves_tips"
	GameState.legacy_path = "user://test_saves_tips_hall.json"
	GameState.unlocks_path = "user://test_saves_tips_unlocks.json"
	Tips.path = "user://test_saves_tips_tips.json"
	_clear_seen()
	var tips_were_on := Settings.tips
	Settings.tips = true
	test_data()
	test_seen_list()
	test_queueing()
	test_conditions()
	test_window()
	test_guide()
	Settings.tips = tips_were_on
	_clear_seen()
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


func _clear_seen() -> void:
	if FileAccess.file_exists(Tips.path):
		DirAccess.remove_absolute(Tips.path)
	Tips._seen_path = ""   # read the file again
	Tips.queue.clear()


func _fresh() -> void:
	_clear_seen()
	GameState.start_new_game("Tipper", "Rowan", 1)


func test_data() -> void:
	print("-- tip data --")
	var errors := TipLibrary.validate()
	check(errors.is_empty(), "tips validate %s" % [errors])
	check(TipLibrary.TIPS.size() >= 25, "a tip for each system (%d)" % TipLibrary.TIPS.size())
	for topic in TipLibrary.TOPICS:
		check(TipLibrary.TIPS.values().any(func(t): return t.topic == topic), "topic %s has tips" % topic)
	check(TipLibrary.key_name("party_menu") == "Tab", "keys come from the input map (%s)" % TipLibrary.key_name("party_menu"))
	check(TipLibrary.text(&"climbing").contains("Tab"), "the floor tip names the party key")
	check(TipLibrary.text(&"own_guild").contains(str(GuildState.CHARTER_COST)), "numbers follow the tunables")
	check(TipLibrary.text(&"nope") == "", "unknown tip = no text")
	check(TipLibrary.ids_for("battle").has(&"battle") and not TipLibrary.ids_for("battle").has(&"climbing"),
		"tips are checked only at their places")
	check(TipLibrary.ids_for("floor").all(func(id): return not TipLibrary.TIPS[id].places.is_empty()),
		"event tips aren't checked by place")


func test_seen_list() -> void:
	print("-- seen list (whole save file) --")
	_clear_seen()
	check(not Tips.is_seen(&"climbing"), "nothing seen at first")
	Tips.mark_seen(&"climbing")
	Tips.mark_seen(&"climbing")
	Tips.mark_seen(&"not_a_tip")
	Tips._seen_path = ""
	check(Tips.is_seen(&"climbing"), "seen tips are saved")
	check(Tips.seen().size() == 1, "no duplicates or unknown ids (%s)" % [Tips.seen()])
	# A new run (any slot) doesn't bring them back.
	GameState.start_new_game("Another", "Rowan", 2)
	check(Tips.is_seen(&"climbing"), "kept across runs")
	GameState.delete_slot(2)
	# Tampered file: junk is dropped.
	SaveSerializer.write_json(Tips.path, { "version": 1, "seen": ["battle", 5, "fake", "battle", null] })
	Tips._seen_path = ""
	check(Tips.seen() == [&"battle"], "tampered list is cleaned (%s)" % [Tips.seen()])
	FileAccess.open(Tips.path, FileAccess.WRITE).store_string("{not json")
	Tips._seen_path = ""
	check(Tips.seen().is_empty(), "broken file = nothing seen")
	Tips.mark_seen(&"rows")
	Tips.reset()
	Tips._seen_path = ""
	check(Tips.seen().is_empty(), "Reset tips forgets them")


func test_queueing() -> void:
	print("-- queueing --")
	_fresh()
	var layout := GameState.current_layout()
	var added := Tips.check("floor", layout)
	check(added.has(&"climbing"), "floor 1 queues the climbing tip")
	check(not added.has(&"campfire") and not added.has(&"guilds"), "nothing that isn't due (%s)" % [added])
	check(Tips.check("floor", layout).is_empty(), "already queued = not queued twice")
	Tips.queue.clear()
	Tips.mark_seen(&"climbing")
	check(not Tips.check("floor", layout).has(&"climbing"), "a seen tip never queues again")
	Tips.queue.clear()
	check(Tips.event(&"weakness") and Tips.queue == [&"weakness"], "events queue their tip")
	check(not Tips.event(&"weakness"), "an event tip queues once")
	check(not Tips.event(&"made_up"), "unknown events are ignored")
	Tips.queue.clear()
	Settings.tips = false
	check(Tips.check("battle").is_empty() and not Tips.event(&"defeat"), "tips off = nothing queues")
	Settings.tips = true
	check(Tips.check("battle").has(&"battle"), "the first battle has a tip")
	check(not Tips.queue.has(&"rows"), "rows wait until floor 2")
	Tips.queue.clear()


func _due(id: StringName, place := "floor", layout: FloorLayout = null) -> bool:
	return TipLibrary.due(id, place, layout)


func test_conditions() -> void:
	print("-- when each tip is due --")
	_fresh()
	var p := GameState.player
	check(not _due(&"stats") and not _due(&"class") and not _due(&"party_growth"), "a new character has few tips")
	p.add_xp(p.xp_to_next(1))
	check(_due(&"stats"), "a level-up -> stat points tip")
	while p.level < CharacterData.CLASS_UNLOCK_LEVEL:
		p.level_up()
	check(_due(&"class"), "level %d -> class tip" % CharacterData.CLASS_UNLOCK_LEVEL)
	check(not _due(&"skills"), "skill tip waits for floor 2")
	GameState.highest_floor = 2
	check(_due(&"skills") == (p.skill_picks > 0), "skill picks -> skills tip")
	check(_due(&"rows", "battle"), "rows from floor 2")
	GameState.highest_floor = GameState.PARTY_GROWTH_FLOORS + 1
	check(_due(&"party_growth"), "party grows -> tip")
	check(_due(&"guilds"), "past the first rest floor -> guilds tip")
	check(not _due(&"own_guild"), "own guild waits for the charter floor")
	GameState.highest_floor = GuildState.CHARTER_FLOOR + 1
	check(_due(&"own_guild"), "charter floor -> own guild tip")
	check(not _due(&"reserve"), "no reserve yet")
	var friend := GameState.companions[0]
	GameState.bench(friend)
	check(_due(&"reserve"), "someone on the bench -> reserve tip")
	check(not _due(&"wages"), "no wages yet")
	friend.wage = 30
	check(_due(&"wages"), "a wage -> wages tip")
	check(not _due(&"new_game_plus") and not _due(&"divinity"), "NG+ and god tips wait")
	GameState.ng_plus_cycle = 1
	check(_due(&"new_game_plus"), "NG+ -> tip")
	GameState.ng_plus_cycle = 0
	# Floor-dependent tips read the floor you're on.
	GameState.enter_floor(GameState.REST_FLOOR_INTERVAL)
	var rest := GameState.current_layout()
	check(rest.is_rest and _due(&"campfire", "floor", rest), "rest floor -> campfire tip")
	check(not _due(&"campfire", "menu"), "the campfire tip needs the floor")
	GameState.enter_floor(4)
	check(_due(&"guardians", "floor", GameState.current_layout()), "miniboss floor -> guardians tip")
	GameState.enter_floor(3)
	check(not _due(&"guardians", "floor", GameState.current_layout()), "a plain floor has no guardian tip")


func test_window() -> void:
	print("-- the system window --")
	_fresh()
	Tips.auto_show = true
	Tips.event(&"weakness")
	Tips.event(&"defeat")
	Tips.show_pending()
	check(Tips.showing(), "the window opens")
	check(get_tree().paused, "the game is paused behind it")
	check(Tips._title.text == "[ Weaknesses ]", "first tip first (%s)" % Tips._title.text)
	check(Tips._counter.text == "1 / 2" and Tips._ok.text == "Next", "counter + Next (%s, %s)" % [Tips._counter.text, Tips._ok.text])
	check(Tips.is_seen(&"weakness"), "a shown tip counts as seen")
	Tips._ok.pressed.emit()
	check(Tips._title.text == "[ Defeat ]" and Tips._ok.text == "OK", "OK on the last one")
	Tips._ok.pressed.emit()
	check(not Tips.showing() and not get_tree().paused, "closed and unpaused")
	check(Tips.is_seen(&"defeat"), "both seen")
	# Turning tips off mid-queue closes the window (Settings itself not saved here).
	Tips.event(&"stats")
	Tips.event(&"skills")
	Tips.show_pending()
	Settings.tips = false
	Tips._ok.pressed.emit()
	check(not Tips.showing() and Tips.queue.is_empty(), "tips off closes the window")
	Settings.tips = true
	Tips.auto_show = false
	Tips.event(&"gear")
	Tips.show_pending()
	check(not Tips.showing(), "headless runs never show the window")
	Tips.queue.clear()


func test_guide() -> void:
	print("-- Tab -> Guide --")
	_clear_seen()
	check(GuidePanel.entries().is_empty(), "an empty guide at first")
	Tips.mark_seen(&"divinity")
	Tips.mark_seen(&"climbing")
	Tips.mark_seen(&"stats")
	check(GuidePanel.entries() == [&"climbing", &"stats", &"divinity"], "seen tips in topic order (%s)" % [GuidePanel.entries()])
	var guide := GuidePanel.new()
	add_child(guide)
	guide.open()
	check(guide._count.text.contains("3 of %d" % TipLibrary.TIPS.size()), "count of found tips (%s)" % guide._count.text)
	check(guide._detail.get_parsed_text().contains("The Tower"), "the first entry is shown")
	guide.close()
	guide.queue_free()
	var menu := PartyMenu.new()
	add_child(menu)
	var found := menu.find_children("*", "Button", true, false).any(func(b): return b.text == "Guide")
	check(found, "the Tab menu has a Guide button")
	menu.queue_free()
