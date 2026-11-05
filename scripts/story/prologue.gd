class_name Prologue
extends Control
## The playable prologue (docs/story/story_bible.md): your room in the real
## world, late at night. Walk around and look at things (the notebook, the
## phone, the window); the PC has the invitation, and starting the test opens
## the test client (TestClientPanel), which pulls you into the tower.
## Esc offers to skip straight to the client. The title screen sends you here
## with `pending_slot` set; Settings.skip_prologue skips the room entirely.
##
## The same room comes back for the real-world returns at later milestones
## (StoryLibrary.RETURN_*): `mode` picks its dialogues, and the PC logs you back
## in to the tower instead of opening the client. The first-run returns make the
## room a little more wrong (WRONG_TILES); the Ascending return is the room
## exactly as it was on the first night, which is its own kind of wrong.

## The save slot New Game picked (set by the title screen before coming here).
static var pending_slot := 1
const SCENE := "res://scenes/prologue.tscn"
const MODE_PROLOGUE := &"prologue"
## MODE_PROLOGUE, or the real-world return being played.
static var mode: StringName = MODE_PROLOGUE
## Stone showing through the floorboards, per return.
const WRONG_TILES := { &"return_tier2": [Vector2i(4, 5)],
	&"return_tier3": [Vector2i(4, 5), Vector2i(5, 5), Vector2i(7, 2), Vector2i(2, 4)],
	&"return_tier4": [Vector2i(4, 5), Vector2i(5, 5), Vector2i(6, 5), Vector2i(7, 2), Vector2i(7, 3), Vector2i(2, 4),
		Vector2i(2, 3), Vector2i(3, 4), Vector2i(6, 2)] }
## Tests turn this off so a return doesn't change scene.
var auto_leave := true
signal return_finished

const TILE := 64
const ROOM := Vector2i(11, 7)   # including the walls
const STEP_TIME := 0.14
const START := Vector2i(5, 4)
## Object -> the tiles it covers (bumping any of them looks at it).
const OBJECTS := {
	&"pc": [Vector2i(2, 1), Vector2i(3, 1)],
	&"notebook": [Vector2i(8, 1)],
	&"window": [Vector2i(5, 0), Vector2i(6, 0)],
	&"phone": [Vector2i(9, 5)],
}
const LABELS := { &"pc": "PC", &"notebook": "Bookshelf", &"window": "Window", &"phone": "Phone" }

var player_tile := START
## Things you've looked at, as flags for the run ("prologue_notebook", ...).
var flags: Array[StringName] = []
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _t := 1.0
var _origin := Vector2.ZERO
var _dialogue: DialogueBox
var _client: TestClientPanel
var _skip: ConfirmationDialog
var _hint: Label
var _art: Dictionary = {}
var _layer: CanvasLayer


func _ready() -> void:
	if mode == MODE_PROLOGUE:
		GameState.reset_run()   # a clean slate: no flags from an earlier run
		GameState.run_active = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Audio.play_music(["prologue"] + MusicLibrary.title())
	for id in OBJECTS:
		_art[id] = Assets.texture("props", "prologue_%s" % id)
	_art["floor"] = Assets.texture("tiles", "prologue_floor")
	_art["player"] = Assets.texture("tokens", "player")
	_build_ui()
	_place()
	get_viewport().size_changed.connect(_place)


func _place() -> void:
	var vp := get_viewport_rect().size
	_origin = ((vp - Vector2(ROOM) * TILE) / 2.0).floor()
	_from = _tile_px(player_tile)
	_to = _from
	queue_redraw()


func _tile_px(t: Vector2i) -> Vector2:
	return _origin + Vector2(t) * TILE


func _busy() -> bool:
	return _dialogue.visible or _client.visible or _skip.visible


func _process(delta: float) -> void:
	if _t < 1.0:
		_t = minf(1.0, _t + delta / STEP_TIME)
		queue_redraw()
		return
	if _busy():
		return
	var dir := Vector2i.ZERO
	if Input.is_action_pressed("move_up"):
		dir = Vector2i.UP
	elif Input.is_action_pressed("move_down"):
		dir = Vector2i.DOWN
	elif Input.is_action_pressed("move_left"):
		dir = Vector2i.LEFT
	elif Input.is_action_pressed("move_right"):
		dir = Vector2i.RIGHT
	if dir != Vector2i.ZERO:
		try_move(dir)


func _unhandled_input(event: InputEvent) -> void:
	if _busy():
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_skip.popup_centered()


## The object on tile `t`, or &"".
static func object_at(t: Vector2i) -> StringName:
	for id in OBJECTS:
		if t in OBJECTS[id]:
			return id
	return &""


static func is_wall(t: Vector2i) -> bool:
	return t.x <= 0 or t.y <= 0 or t.x >= ROOM.x - 1 or t.y >= ROOM.y - 1


## One step; bumping an object looks at it. Public for tests.
func try_move(dir: Vector2i) -> bool:
	if _t < 1.0 or _busy():
		return false
	var target := player_tile + dir
	var obj := object_at(target)
	if obj != &"":
		look_at_object(obj)
		return false
	if is_wall(target):
		return false
	_from = _tile_px(player_tile)
	player_tile = target
	_to = _tile_px(target)
	_t = 0.0
	return true


func look_at_object(id: StringName) -> void:
	if _dialogue.open(StringName("%s_%s" % [mode, id])):
		Audio.play_sfx(["talk_%s_%s" % [mode, id], "talk"])


func _on_dialogue_finished(runner: DialogueRunner) -> void:
	if mode != MODE_PROLOGUE:
		if GameState.has_flag(StringName("%s_login" % mode)):
			leave_return()
		return
	var id := StringName(String(runner.dialogue_id).trim_prefix("prologue_"))
	var flag := StringName("prologue_%s" % id)
	if not flags.has(flag):
		flags.append(flag)
	if GameState.has_flag(&"prologue_start_test"):
		GameState.set_flag(&"prologue_start_test", false)
		start_test()
	_hint.text = "Use the PC when you're ready." if not flags.is_empty() else _hint.text


## Back to the tower from a real-world return. The friend has something to say.
func leave_return() -> void:
	GameState.pending_talks.append({ "dialogue": StringName("%s_back" % mode) })
	mode = MODE_PROLOGUE
	return_finished.emit()
	if auto_leave:
		get_tree().change_scene_to_file(GameState.TOWER_SCENE)


## Opens the test client (the PC's START TEST, or skipping the room).
func start_test() -> void:
	_client.open()


func _on_client_done(r: Dictionary) -> void:
	TestClientPanel.begin_run(r, pending_slot, flags)
	get_tree().change_scene_to_file(GameState.TOWER_SCENE)


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	add_child(_layer)
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(ui)
	_hint = Label.new()
	var move_keys := "/".join(["move_up", "move_left", "move_down", "move_right"].map(
		func(a): return InputBindings.key_name(a)))
	_hint.text = ("Your room. Late. Look around, or use the PC.   (%s: move · %s: skip)" if mode == MODE_PROLOGUE
		else ("The studio. You know what day it is.   (%s: move · %s: skip)" if mode in [StoryLibrary.RETURN_DAY3, StoryLibrary.RETURN_RACK]
		else "Your room? The PC is still on.   (%s: move · %s: skip)")) % [move_keys, InputBindings.key_name("pause")]
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_hint.offset_top = 16
	_hint.offset_left = 16
	_hint.offset_right = -16
	_hint.modulate = Color(1, 1, 1, 0.6)
	ui.add_child(_hint)
	_dialogue = DialogueBox.new()
	_dialogue.finished.connect(_on_dialogue_finished)
	ui.add_child(_dialogue)
	_client = TestClientPanel.new()
	_client.completed.connect(_on_client_done)
	ui.add_child(_client)
	_skip = ConfirmationDialog.new()
	_skip.title = "Skip the prologue?"
	_skip.dialog_text = "Go straight to the test client?\n(Settings can skip this every time, along with the later scenes in this room.)"
	_skip.ok_button_text = "Skip"
	_skip.cancel_button_text = "Stay"
	_skip.confirmed.connect(leave_return if mode != MODE_PROLOGUE else start_test)
	if mode != MODE_PROLOGUE:
		_skip.title = "Skip this?"
		_skip.dialog_text = "Go straight back to the tower?"
	ui.add_child(_skip)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.03, 0.03, 0.06))
	var font := ThemeDB.fallback_font
	for y in ROOM.y:
		for x in ROOM.x:
			var t := Vector2i(x, y)
			var r := Rect2(_tile_px(t), Vector2(TILE, TILE))
			if is_wall(t):
				draw_rect(r, Color(0.13, 0.13, 0.19))
			elif t in WRONG_TILES.get(mode, []):
				draw_rect(r, Color(0.3, 0.3, 0.34))   # stone through the floorboards
			elif _art["floor"]:
				draw_texture_rect(_art["floor"], r, false)
			else:
				draw_rect(r, Color(0.2, 0.17, 0.15) if (x + y) % 2 == 0 else Color(0.18, 0.15, 0.13))
	# The bed (decoration) beside the phone.
	draw_rect(Rect2(_tile_px(Vector2i(8, 4)) + Vector2(6, 6), Vector2(TILE - 12, TILE * 2 - 12)), Color(0.25, 0.28, 0.42))
	for id in OBJECTS:
		var tiles: Array = OBJECTS[id]
		var r := Rect2(_tile_px(tiles[0]), Vector2(TILE * tiles.size(), TILE))
		if _art[id]:
			draw_texture_rect(_art[id], r, false)
		else:
			var c: Color = { &"pc": Color(0.3, 0.75, 1.0), &"notebook": Color(0.55, 0.38, 0.24),
				&"window": Color(0.2, 0.3, 0.55), &"phone": Color(0.85, 0.85, 0.9) }[id]
			draw_rect(r.grow(-8), c)
			if id == &"pc":   # the monitor's glow
				draw_rect(r.grow(10), Color(0.3, 0.75, 1.0, 0.08))
		var label: String = LABELS[id]
		var size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
		draw_string(font, r.get_center() + Vector2(-size.x / 2, 5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0, 0, 0, 0.85))
	var p := _from.lerp(_to, _t) + Vector2(TILE, TILE) / 2
	if _art["player"]:
		draw_texture_rect(_art["player"], Rect2(p - Vector2(TILE, TILE) / 2, Vector2(TILE, TILE)), false)
	else:
		draw_circle(p, TILE * 0.32, Color(0.95, 0.9, 0.75))
