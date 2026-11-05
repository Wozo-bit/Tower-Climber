extends Node
## Every screen fits on screen at each window shape and interface size
## (Settings.UI_SCALES): opens the title screen's panels, the floor with its
## menus and every Tab sub-screen, a full battle, and the tip window, then
## looks for anything poking outside the visible area. Also the settings
## for window size, interface size and key rebinding.
## Run:  godot --headless res://tests/test_display.tscn

var _passed := 0
var _failed := 0

## [window size, interface scale, label]. Wider/taller windows show more of
## the field (stretch aspect "expand"); a bigger interface shows less.
const SHAPES := [
	[Vector2i(1280, 720), 1.0, "16:9"],
	[Vector2i(1280, 800), 1.0, "16:10"],
	[Vector2i(1280, 960), 1.0, "4:3"],
	[Vector2i(1720, 720), 1.0, "21:9"],
	[Vector2i(1280, 720), 0.9, "16:9 at 90%"],
	[Vector2i(1280, 720), 1.1, "16:9 at 110%"],
	[Vector2i(1280, 720), 1.2, "16:9 at 120%"],
	[Vector2i(1280, 960), 1.2, "4:3 at 120%"],
]


func _ready() -> void:
	GameState.save_dir = "user://test_saves_display"
	GameState.legacy_path = "user://test_saves_display_hall.json"
	GameState.unlocks_path = "user://test_saves_display_unlocks.json"
	Tips.path = "user://test_saves_display_tips.json"
	Settings.path = "user://test_saves_display_settings.cfg"
	CutIns.skip_all()
	test_settings_values()
	test_key_rebinding()
	for shape in SHAPES:
		await test_shape(shape[0], shape[1], shape[2])
	get_tree().root.size = Vector2i(1280, 720)
	get_tree().root.content_scale_factor = 1.0
	Settings.keys = InputBindings.defaults()
	Settings.ui_scale = 1.0
	Settings.apply()
	SaveSerializer.delete_file(Settings.path)
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


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func test_settings_values() -> void:
	print("-- window size + interface size --")
	check(Settings.clean_scale(1.13) == 1.1 and Settings.clean_scale("big") == 1.0 and Settings.clean_scale(9) == 1.2,
		"odd interface sizes snap to an offered one")
	Settings.window_size = 2
	Settings.ui_scale = 1.1
	Settings.save_settings()
	Settings.window_size = 0
	Settings.ui_scale = 1.0
	Settings.load_settings()
	check(Settings.window_size == 2 and Settings.ui_scale == 1.1, "window and interface size are saved")
	var cfg := ConfigFile.new()
	cfg.load(Settings.path)
	cfg.set_value("video", "window_size", 99)
	cfg.set_value("video", "ui_scale", -4)
	cfg.save(Settings.path)
	Settings.load_settings()
	check(Settings.window_size == Settings.WINDOW_SIZES.size() - 1 and Settings.ui_scale == 0.9, "tampered values are clamped")
	Settings.window_size = 0
	Settings.ui_scale = 1.0
	Settings.apply()
	check(get_tree().root.content_scale_factor == 1.0, "the interface size is applied to the window")


func test_key_rebinding() -> void:
	print("-- key rebinding --")
	var k := InputBindings.defaults()
	check(InputBindings.ACTIONS.all(func(a): return k[a].any(func(x): return x != 0)), "every action has a default key")
	check(InputBindings.bind(k, "move_up", 0, KEY_T) == "" and k.move_up == [KEY_T, KEY_UP], "bind a new key")
	check(InputBindings.bind(k, "pause", 1, KEY_T) == "" and k.move_up == [0, KEY_UP] and k.pause[1] == KEY_T,
		"a key used by another action moves over")
	check(InputBindings.bind(k, "party_menu", 0, KEY_UP) != "" and k.move_up == [0, KEY_UP],
		"can't take an action's only key")
	check(InputBindings.bind(k, "ui_cancel", 1, KEY_T) == "" and k.pause.has(KEY_T),
		"menu keys and floor keys can share (Esc pauses AND goes back)")
	check(not InputBindings.clear(k, "move_up", 1), "can't clear the last key")
	check(InputBindings.clear(k, "pause", 1) and k.pause == [KEY_ESCAPE, 0], "clear a spare key")
	check(InputBindings.bind(k, "pause", 1, KEY_ESCAPE) == "" and k.pause == [0, KEY_ESCAPE], "same key to the other slot just moves")
	check(InputBindings.bind(k, "pause", 0, -5) != "", "bad keys are refused")
	# Saved, loaded and cleaned.
	Settings.keys = k
	Settings.save_settings()
	Settings.keys = InputBindings.defaults()
	Settings.load_settings()
	check(Settings.keys.move_up == [0, KEY_UP] and Settings.keys.ui_cancel[1] == KEY_T, "keys are saved")
	var raw := { "move_up": [KEY_W, KEY_W], "move_down": [KEY_W, "x"], "pause": "nope", "made_up": [KEY_Q, 0],
		"party_menu": [999999999, -1] }
	var clean := InputBindings.clean(raw)
	check(clean.move_up == [KEY_W, 0], "a key twice in one action is dropped")
	check(clean.move_down == InputBindings.DEFAULTS.move_down, "an action left with no key gets its defaults")
	check(clean.pause == InputBindings.DEFAULTS.pause and clean.party_menu == InputBindings.DEFAULTS.party_menu,
		"junk falls back to the defaults")
	check(not clean.has("made_up"), "unknown actions are ignored")
	# Applied to the input map, and the text follows.
	Settings.apply()
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_UP
	check(InputMap.event_is_action(ev, "move_up"), "the input map uses the new keys")
	ev.physical_keycode = KEY_W
	check(not InputMap.event_is_action(ev, "move_up"), "the old key is gone")
	check(InputBindings.key_name("move_up") == "Up" and TipLibrary.text(&"climbing").contains("Up"), "tips name the new key")
	# The Controls screen: click a key, press another.
	var panel := ControlsPanel.new()
	add_child(panel)
	panel.open()
	panel._start_capture("party_menu", 1)
	check(panel.is_capturing(), "clicking a key listens for the next press")
	check(panel.press_key(KEY_M) == "" and Settings.keys.party_menu[1] == KEY_M and not panel.is_capturing(),
		"pressing a key binds it")
	var reset: Button = panel.find_children("*", "Button", true, false).filter(func(b): return b.text == "Reset to defaults")[0]
	reset.pressed.emit()
	check(Settings.keys == InputBindings.defaults() and InputBindings.key_name("party_menu") == "Tab", "reset to defaults")
	panel.queue_free()
	var settings := SettingsPanel.new()
	add_child(settings)
	settings.open()
	check(settings._keys_note.text.contains("Tab"), "the settings screen lists the keys")
	settings.queue_free()


## Anything visible that pokes outside the screen (scrolling/clipping
## containers are allowed to hold more than fits). Returns short names.
func _offscreen(root: Node) -> Array:
	var screen := get_viewport().get_visible_rect().grow(1)
	var out := []
	for c in root.find_children("*", "Control", true, false):
		if not c.is_visible_in_tree() or c.size == Vector2.ZERO or _clipped(c):
			continue
		if not screen.encloses(c.get_global_rect()):
			# Report the outermost one only.
			var p := c.get_parent()
			if p is Control and p.is_visible_in_tree() and not screen.encloses(p.get_global_rect()) and not _clipped(p):
				continue
			out.append("%s %s %s" % [c.get_class(), c.name, c.get_global_rect()])
	return out


func _clipped(c: Node) -> bool:
	var p := c.get_parent()
	while p:
		if p is ScrollContainer or (p is Control and p.clip_contents):
			return true
		p = p.get_parent()
	return false


func _expect_fit(root: Node, what: String, label: String) -> void:
	var off := _offscreen(root)
	check(off.is_empty(), "%s fits (%s)%s" % [what, label, "" if off.is_empty() else ": " + ", ".join(off.slice(0, 3))])


func _fresh() -> void:
	GameState.start_new_game("Measure", "Cassia", 1)
	GameState.highest_floor = 41
	var p := GameState.player
	while p.level < 30:
		p.level_up()
	p.choose_class(ClassRegistry.get_class_def(&"rogue"))
	while GameState.companions.size() < GameState.party_size() - 1:
		GameState.companions.append(GameState.make_premade("M%d" % GameState.companions.size(), &"tank",
			{ Stats.Type.HEALTH: 20, Stats.Type.STAMINA: 15 }))
	GameState.enter_floor(40)


func test_shape(win: Vector2i, scale: float, label: String) -> void:
	print("-- %s --" % label)
	get_tree().root.size = win
	Settings.ui_scale = scale
	Settings.apply()
	await _frames(2)
	print("   visible area %s" % get_viewport().get_visible_rect().size)

	# Title screen and its panels.
	var title: Node = load(GameState.TITLE_SCENE).instantiate()
	add_child(title)
	await _frames(2)
	_expect_fit(title, "title screen", label)
	for opener in [func(): title._open_slots("load"), func(): title._open_new_game(), func(): title._settings.open(),
			func(): title._settings._controls.open(), func(): title._credits.open("Tower of Recognition")]:
		opener.call()
		await _frames(2)
		_expect_fit(title, "a title panel", label)
		for panel in [title._slot_panel, title._client, title._settings._controls, title._settings, title._credits]:
			panel.hide()
	title.queue_free()
	await _frames(1)

	# The prologue room and every screen of the test client.
	var room: Node = load("res://scenes/prologue.tscn").instantiate()
	add_child(room)
	await _frames(2)
	_expect_fit(room, "prologue room", label)
	var room_px := Vector2(Prologue.ROOM) * Prologue.TILE
	check(Rect2(room._origin, room_px).size.x <= get_viewport().get_visible_rect().size.x
		and room._origin.y >= 0, "[%s] the room is on screen" % label)
	room.look_at_object(&"notebook")
	await _frames(2)
	_expect_fit(room, "prologue dialogue", label)
	room._dialogue.hide()
	var client: TestClientPanel = room._client
	client.open()
	for step in StoryLibrary.SETUP_QUESTIONS.size() + 3:
		await _frames(2)
		_expect_fit(room, "test client screen %d" % client.step(), label)
		if client.step() == 0:
			client.confirm_name()
		elif client.step() <= StoryLibrary.SETUP_QUESTIONS.size():
			var q: Dictionary = StoryLibrary.SETUP_QUESTIONS[client.step() - 1]
			client.answer(q.id, q.options[0].id)
		else:
			client.confirm_friend()
	client._done = true   # don't start a run
	room.queue_free()
	await _frames(1)

	# The Dev Sandbox (not in the released game, but Hayden tests with it).
	if scale <= 1.0:
		var sandbox: Node = load("res://scenes/progression_sandbox.tscn").instantiate()
		add_child(sandbox)
		await _frames(2)
		_expect_fit(sandbox, "dev sandbox", label)
		sandbox.queue_free()
		await _frames(1)

	# The floor, the Tab menu and every sub-screen.
	_fresh()
	var floor_scene: Node = load(GameState.TOWER_SCENE).instantiate()
	add_child(floor_scene)
	await _frames(2)
	_expect_fit(floor_scene, "floor HUD", label)
	var menu: PartyMenu = floor_scene._party_menu
	menu.open()
	await _frames(2)
	_expect_fit(floor_scene, "Tab menu", label)
	var p := GameState.player
	var subs := {
		"stats": func(): menu._stats_overlay.show(), "gear": func(): menu._gear_panel.open(p),
		"skills": func(): menu._skills_panel.open(p), "manage party": func(): menu._manage_panel.open(),
		"bestiary": func(): menu._bestiary_panel.open(), "quests": func(): menu._quest_panel.open(),
		"guilds": func(): menu._guild_panel.open(), "divinity": func(): menu._divinity_panel.open(),
		"advancement": func(): menu._advance_panel.open(p), "class choice": func(): menu._class_screen.open(p),
		"guide": func(): menu._guide_panel.open(),
		"guild jobs": func(): menu._guild_panel.open(); menu._guild_panel._jobs.open(1),
		"travel": func(): floor_scene._travel_panel.open(),
	}
	for what in subs:
		subs[what].call()
		await _frames(2)
		_expect_fit(floor_scene, what, label)
		for panel in [menu._stats_overlay, menu._gear_panel, menu._skills_panel, menu._manage_panel, menu._bestiary_panel,
				menu._quest_panel, menu._guild_panel, menu._divinity_panel, menu._advance_panel, menu._class_screen, menu._guide_panel,
				floor_scene._travel_panel]:
			panel.hide()
		if menu._guild_panel._jobs:
			menu._guild_panel._jobs.hide()
	menu.hide()
	for what in ["shop", "notice board", "pause menu"]:
		match what:
			"shop": floor_scene._shop.open()
			"notice board": floor_scene._board_panel.open()
			"pause menu": floor_scene._pause.open()
		await _frames(2)
		_expect_fit(floor_scene, what, label)
		floor_scene._shop.hide()
		floor_scene._board_panel.hide()
		floor_scene._pause.hide()
	get_tree().paused = false
	floor_scene.talk(&"merchant")
	await _frames(2)
	_expect_fit(floor_scene, "dialogue box", label)
	floor_scene.queue_free()
	await _frames(1)

	# A full battle (10 a side).
	var ids: Array[StringName] = []
	for i in 10:
		ids.append(&"goblin")
	GameState.pending_encounter = EnemyLibrary.build_group(ids)
	GameState.pending_battle_info = { "kind": "normal" }
	GameState.return_scene = ""
	var battle_scene: Node = load(GameState.BATTLE_SCENE).instantiate()
	add_child(battle_scene)
	await _frames(3)
	_expect_fit(battle_scene, "battle (10 vs 10)", label)
	battle_scene.queue_free()
	GameState.pending_battle_info = {}
	await _frames(1)

	# The tip window.
	Tips.auto_show = true
	Tips.queue.append(&"own_guild")
	Tips.show_pending()
	await _frames(2)
	_expect_fit(Tips, "tip window", label)
	Tips._close()
	Tips.auto_show = false
	await _frames(1)
