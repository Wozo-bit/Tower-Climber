class_name PauseMenu
extends Control
## In-tower pause menu (Esc): Resume, Save, Settings, Quit to Title.

signal closed

var _settings: SettingsPanel
var _message: Label
var _save_btn: Button


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 0)
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
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)
	_add(box, "Resume", close)
	_save_btn = _add(box, "Save Game", func():
		_message.text = "Game saved." if GameState.save_game() else "Save failed!")
	_add(box, "Settings", func(): _settings.open())
	_add(box, "Quit to Title", func():
		if GameState.run_active:
			GameState.save_game()
		GameState.run_active = false
		GameState.clock_paused = false
		get_tree().change_scene_to_file(GameState.TITLE_SCENE))
	_message = Label.new()
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.modulate = Color(0.7, 1, 0.75)
	box.add_child(_message)
	var note := Label.new()
	note.text = "The game also autosaves on every floor."
	note.modulate = Color(1, 1, 1, 0.5)
	note.add_theme_font_size_override("font_size", 12)
	box.add_child(note)

	_settings = SettingsPanel.new()
	add_child(_settings)


func open() -> void:
	_message.text = ""
	_save_btn.disabled = not GameState.run_active
	_save_btn.tooltip_text = "" if GameState.run_active else "Test sessions (dev sandbox) aren't saved."
	GameState.clock_paused = true
	show()


func close() -> void:
	if _settings.visible:
		return
	hide()
	GameState.clock_paused = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and not _settings.visible and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()


func _add(parent: Node, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 36
	b.pressed.connect(cb)
	parent.add_child(b)
	return b
