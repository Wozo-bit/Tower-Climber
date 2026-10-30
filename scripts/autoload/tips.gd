extends CanvasLayer
## Autoload "Tips": tutorial tips (TipLibrary) shown in a system window the
## first time you meet each system. Seen tips are remembered for the whole
## save file (user://tips.json, like the demigod unlocks), so a tip never
## shows twice, in any slot or New Game+. Settings.tips turns them off.
##
## Screens decide WHEN: they call check(place) to queue the tips due there,
## event(id) when something happens, and show_pending() at a calm moment
## (the window pauses the game until it's closed).

signal finished   # the window closed (queue empty or tips turned off)

const LAYER := 95   # above the HUD and cut-ins' backdrop, below nothing important
const WIDTH := 560

var path := "user://tips.json"
## Off when headless (the test suites), so tips never pause a test; tests
## that check the window turn it on.
var auto_show := DisplayServer.get_name() != "headless"
var queue: Array[StringName] = []

var _seen: Array = []
var _seen_path := ""   # which file _seen was read from (tests change `path`)
var _was_paused := false
var _root: Control
var _title: Label
var _counter: Label
var _body: Label
var _ok: Button
var _shown_count := 0


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


# =========================================================
# Seen list (kept across every run)
# =========================================================

func seen() -> Array:
	if _seen_path != path:
		_seen = []
		for id in SaveSerializer._a(SaveSerializer.read_json(path), "seen"):
			if id is String and TipLibrary.TIPS.has(StringName(id)) and not _seen.has(StringName(id)):
				_seen.append(StringName(id))
		_seen_path = path
	return _seen


func is_seen(id: StringName) -> bool:
	return seen().has(id)


func mark_seen(id: StringName) -> void:
	if is_seen(id) or not TipLibrary.TIPS.has(id):
		return
	_seen.append(id)
	_write()


## Settings -> Reset tips: every tip shows again.
func reset() -> void:
	seen()
	_seen.clear()
	queue.clear()
	_write()


func _write() -> void:
	SaveSerializer.write_json(path, { "version": SaveSerializer.FORMAT_VERSION,
		"seen": _seen.map(func(x): return String(x)) })


# =========================================================
# Queueing
# =========================================================

func enabled() -> bool:
	return Settings.tips


## Queues the tips that are due at this place (see TipLibrary.PLACES).
## Returns the ids it queued.
func check(place: String, layout: FloorLayout = null) -> Array:
	var added := []
	if not enabled():
		return added
	for id in TipLibrary.ids_for(place):
		if not is_seen(id) and not queue.has(id) and TipLibrary.due(id, place, layout):
			queue.append(id)
			added.append(id)
	return added


## Something happened that has a tip (e.g. the first weakness hit).
func event(id: StringName) -> bool:
	if not enabled() or not TipLibrary.TIPS.has(id) or is_seen(id) or queue.has(id):
		return false
	queue.append(id)
	return true


# =========================================================
# The window
# =========================================================

func showing() -> bool:
	return _root != null and _root.visible


## Shows the queued tips one after another. Await it to wait until they're
## closed (returns at once when there's nothing to show).
func show_pending() -> void:
	if queue.is_empty() or not auto_show:
		return
	if not showing():
		_open()
	await finished


func _open() -> void:
	_was_paused = get_tree().paused
	get_tree().paused = true
	_shown_count = 0
	_root.show()
	_next()


## Shows the next queued tip (closes when there's none).
func _next() -> void:
	if queue.is_empty() or not enabled():
		_close()
		return
	var id: StringName = queue.pop_front()
	_shown_count += 1
	var tip: Dictionary = TipLibrary.TIPS[id]
	_title.text = "[ %s ]" % tip.title
	_title.add_theme_color_override("font_color", UITheme.color("accent"))
	_body.text = TipLibrary.text(id)
	_counter.text = "%d / %d" % [_shown_count, _shown_count + queue.size()] if _shown_count + queue.size() > 1 else ""
	_ok.text = "Next" if not queue.is_empty() else "OK"
	mark_seen(id)
	Audio.play_sfx(["system_tip", "system"], 0.0)
	_ok.grab_focus.call_deferred()


func _close() -> void:
	queue.clear()
	_root.hide()
	get_tree().paused = _was_paused
	finished.emit()


func _turn_off() -> void:
	Settings.tips = false
	Settings.save_settings()
	_close()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.visible = false
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = WIDTH
	UIStyle.apply(panel)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var head := HBoxContainer.new()
	box.add_child(head)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 20)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	_counter = Label.new()
	_counter.modulate = Color(1, 1, 1, 0.6)
	head.add_child(_counter)

	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size.x = WIDTH - 36
	_body.add_theme_font_size_override("font_size", 16)
	box.add_child(_body)

	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	var off := Button.new()
	off.text = "Turn off tips"
	off.tooltip_text = "No more tips (turn them back on in Settings). Tab -> Guide keeps the ones you've seen."
	off.pressed.connect(_turn_off)
	buttons.add_child(off)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(spacer)
	_ok = Button.new()
	_ok.custom_minimum_size.x = 110
	_ok.pressed.connect(_next)
	buttons.add_child(_ok)
