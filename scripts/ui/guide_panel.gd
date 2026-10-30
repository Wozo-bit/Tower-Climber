class_name GuidePanel
extends Control
## Tab -> Guide: every tutorial tip you've seen (TipLibrary), grouped by
## topic, to reread whenever you like. Unseen tips stay hidden until they
## come up in play.

signal closed

var _list: VBoxContainer
var _detail: RichTextLabel
var _count: Label
var _selected: StringName = &""


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
	panel.custom_minimum_size = Vector2(1000, 520)
	UIStyle.apply(panel)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = "Guide"
	title.add_theme_font_size_override("font_size", 24)
	header.add_child(title)
	_count = Label.new()
	_count.modulate = Color(1, 1, 1, 0.6)
	_count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_count)
	var done := Button.new()
	done.text = "Done"
	done.pressed.connect(close)
	header.add_child(done)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 20)
	root.add_child(body)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = 300
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(_detail)

	var hint := Label.new()
	hint.text = "New entries appear as you meet each part of the tower. Tips can be turned off (or shown again) in Settings."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(1, 1, 1, 0.55)
	root.add_child(hint)


func open() -> void:
	_rebuild()
	show()


func close() -> void:
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


## Seen tips in Guide order (TipLibrary order, grouped by topic).
static func entries() -> Array:
	var out := []
	for topic in TipLibrary.TOPICS:
		for id in TipLibrary.TIPS:
			if TipLibrary.TIPS[id].topic == topic and Tips.is_seen(id):
				out.append(id)
	return out


func _rebuild() -> void:
	for c in _list.get_children():
		c.queue_free()
	var shown := entries()
	_count.text = "  %d of %d found" % [shown.size(), TipLibrary.TIPS.size()]
	if not shown.has(_selected):
		_selected = shown[0] if not shown.is_empty() else &""
	var topic: StringName = &""
	for id in shown:
		var t: Dictionary = TipLibrary.TIPS[id]
		if t.topic != topic:
			topic = t.topic
			var head := Label.new()
			head.text = TipLibrary.TOPIC_NAMES[topic]
			head.add_theme_color_override("font_color", UITheme.color("accent"))
			_list.add_child(head)
		var b := Button.new()
		b.text = t.title
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.toggle_mode = true
		b.button_pressed = id == _selected
		b.pressed.connect(func(): _selected = id; _rebuild())
		_list.add_child(b)
	_show_detail()


func _show_detail() -> void:
	if _selected == &"":
		_detail.text = "Nothing here yet. Tips are added as you meet each part of the tower."
		return
	_detail.text = "[font_size=20][color=#%s]%s[/color][/font_size]\n\n%s" % [
		UITheme.hex("accent"), TipLibrary.TIPS[_selected].title,
		TipLibrary.text(_selected).replace("\n", "\n\n")]
