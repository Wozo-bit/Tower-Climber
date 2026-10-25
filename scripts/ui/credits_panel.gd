class_name CreditsPanel
extends Control
## Title screen -> Credits: the team, every credited asset (from
## assets/credits.json) and Godot's license notices. Scrolls on its own;
## the mouse wheel or dragging the bar takes over.

signal closed

const SCROLL_SPEED := 30.0   # pixels per second

var _text: RichTextLabel
var _auto := true


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(820, 620)
	UIStyle.apply(panel)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.selection_enabled = true
	_text.gui_input.connect(func(e):
		if e is InputEventMouseButton:
			_auto = false)
	box.add_child(_text)
	var back := Button.new()
	back.text = "Back"
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.custom_minimum_size.x = 160
	back.pressed.connect(close)
	box.add_child(back)


func open(game_title: String) -> void:
	_text.text = Credits.text(Credits.load_data(), game_title)
	_auto = true
	show()
	_text.get_v_scroll_bar().value = 0
	Audio.play_music(MusicLibrary.credits())


func close() -> void:
	hide()
	Audio.play_music(MusicLibrary.title())
	closed.emit()


func _process(delta: float) -> void:
	if visible and _auto:
		_text.get_v_scroll_bar().value += SCROLL_SPEED * delta


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close()
