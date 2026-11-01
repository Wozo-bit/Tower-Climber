class_name ControlsPanel
extends Control
## Settings -> Controls: two keys per action (InputBindings). Click a key and
## press the new one; right-click a key to clear it. Changes apply at once
## and are saved by the Settings panel.

signal closed

var _grid: GridContainer
var _message: Label
## [action, slot] waiting for a key press, or [] when not listening.
var _capturing: Array = []


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 0)
	UIStyle.apply(panel)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Controls"
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	var hint := Label.new()
	hint.text = "Click a key, then press the new one. Right-click a key to clear it."
	hint.modulate = Color(1, 1, 1, 0.6)
	box.add_child(hint)

	_grid = GridContainer.new()
	_grid.columns = 1 + InputBindings.SLOTS
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 6)
	box.add_child(_grid)

	_message = Label.new()
	_message.modulate = Color(1, 0.85, 0.6)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_message)

	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	var reset := Button.new()
	reset.text = "Reset to defaults"
	reset.pressed.connect(func():
		Settings.keys = InputBindings.defaults()
		Settings.apply()
		_capturing = []
		_message.text = "Keys reset to the defaults."
		_rebuild())
	buttons.add_child(reset)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(spacer)
	var done := Button.new()
	done.text = "Done"
	done.pressed.connect(close)
	buttons.add_child(done)


func open() -> void:
	_capturing = []
	_message.text = ""
	_rebuild()
	show()


func close() -> void:
	_capturing = []
	hide()
	closed.emit()


func is_capturing() -> bool:
	return not _capturing.is_empty()


func _rebuild() -> void:
	for c in _grid.get_children():
		c.queue_free()
	for a in InputBindings.ACTIONS:
		var l := Label.new()
		l.text = InputBindings.NAMES[a]
		l.custom_minimum_size.x = 170
		_grid.add_child(l)
		for slot in InputBindings.SLOTS:
			var k: int = Settings.keys[a][slot]
			var b := Button.new()
			b.custom_minimum_size.x = 140
			b.text = "Press a key..." if _capturing == [a, slot] else (OS.get_keycode_string(k) if k != 0 else "—")
			b.pressed.connect(_start_capture.bind(a, slot))
			b.gui_input.connect(func(ev):
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
					_clear(a, slot))
			_grid.add_child(b)


func _start_capture(action: String, slot: int) -> void:
	_capturing = [] if _capturing == [action, slot] else [action, slot]
	_message.text = "Press a key for %s..." % InputBindings.NAMES[action] if is_capturing() else ""
	_rebuild()


func _clear(action: String, slot: int) -> void:
	_capturing = []
	if InputBindings.clear(Settings.keys, action, slot):
		Settings.apply()
		_message.text = ""
	else:
		_message.text = "%s needs at least one key." % InputBindings.NAMES[action]
	_rebuild()


## The key press while listening (before anything else can use it).
func _input(event: InputEvent) -> void:
	if not visible or not is_capturing():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		press_key(key)


## Binds the key being listened for (public for the tests).
func press_key(key: int) -> String:
	var why := InputBindings.bind(Settings.keys, _capturing[0], _capturing[1], key)
	_message.text = why if why != "" else "%s: %s" % [InputBindings.NAMES[_capturing[0]], InputBindings.keys_text(Settings.keys, _capturing[0])]
	_capturing = []
	Settings.apply()
	_rebuild()
	return why


func _unhandled_input(event: InputEvent) -> void:
	if visible and not is_capturing() and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
