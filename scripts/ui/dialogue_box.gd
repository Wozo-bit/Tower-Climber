class_name DialogueBox
extends Control
## Bottom-of-screen conversation box. Shows the speaker, the line and either a
## "Next ▸" button or the choices. Keyboard: arrows + Enter/Space. Esc also
## works as "Next" (it never skips lines, so no effect is ever missed).

## Emitted when the conversation ends. `runner` has the requests (e.g. "shop")
## and messages (toasts) for the caller.
signal finished(runner: DialogueRunner)

var runner := DialogueRunner.new()

var _speaker: Label
var _text: Label
var _buttons: VBoxContainer


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 80
	panel.offset_right = -80
	panel.offset_top = -230
	panel.offset_bottom = -50
	UIStyle.apply(panel)
	add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	_speaker = Label.new()
	_speaker.add_theme_font_size_override("font_size", 20)
	_speaker.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	box.add_child(_speaker)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("font_size", 17)
	box.add_child(_text)
	_buttons = VBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(_buttons)


## Starts conversation `id`. Returns false (and stays hidden) if it doesn't exist.
func open(id: StringName) -> bool:
	if not runner.start(id):
		push_warning("DialogueBox: no dialogue '%s'" % id)
		return false
	show()
	_refresh()
	return true


func _refresh() -> void:
	if runner.finished:
		hide()
		finished.emit(runner)
		return
	_speaker.text = runner.speaker()
	_speaker.visible = _speaker.text != ""
	_text.text = runner.text()
	# Narration (lore objects) reads a little dimmer.
	_text.modulate = Color(1, 1, 1, 1) if _speaker.visible else Color(0.85, 0.85, 0.95)
	for c in _buttons.get_children():
		_buttons.remove_child(c)
		c.queue_free()
	var first: Button
	if runner.has_choices():
		for c in runner.choices():
			var b := Button.new()
			b.text = "▸ " + c.text
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.pressed.connect(func(): runner.choose(c.index); _refresh())
			_buttons.add_child(b)
			if first == null:
				first = b
	if first == null:
		# No choices (or every choice hidden): just continue.
		var b := Button.new()
		b.text = "Next ▸"
		b.size_flags_horizontal = Control.SIZE_SHRINK_END
		b.pressed.connect(func():
			if runner.has_choices():
				runner.finished = true   # all choices hidden: nothing to pick, end
			else:
				runner.advance()
			_refresh())
		_buttons.add_child(b)
		first = b
	first.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if not runner.has_choices():
			runner.advance()
			_refresh()
