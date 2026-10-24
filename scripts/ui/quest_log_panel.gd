class_name QuestLogPanel
extends Control
## Tab -> Quests: active, completed and failed quests with their steps and
## progress. Pin one to show it on the floor HUD. Quest items you're carrying
## are listed here too (they can't be used like normal items).

signal closed

var _list: VBoxContainer
var _detail: RichTextLabel
var _pin_btn: Button
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
	title.text = "Quests"
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_pin_btn = Button.new()
	_pin_btn.text = "Pin to screen"
	_pin_btn.tooltip_text = "Show this quest's current step on the floor HUD."
	_pin_btn.pressed.connect(func():
		GameState.quests.pin(_selected)
		_rebuild())
	header.add_child(_pin_btn)
	var done := Button.new()
	done.text = "Done"
	done.pressed.connect(close)
	header.add_child(done)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 20)
	root.add_child(body)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = 340
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(_detail)


func open() -> void:
	_selected = GameState.quests.pinned
	_rebuild()
	show()


func close() -> void:
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("party_menu")):
		get_viewport().set_input_as_handled()
		close()


func _rebuild() -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	var ql := GameState.quests
	_section("Active", ql.active.keys(), Color(0.95, 0.85, 0.55))
	_section("Completed", ql.completed, Color(0.6, 0.9, 0.6))
	_section("Failed", ql.failed, Color(0.9, 0.5, 0.5))
	var quest_items := GameState.inventory.owned().filter(func(i): return i.quest_item)
	if not quest_items.is_empty():
		var head := Label.new()
		head.text = "Quest items"
		head.add_theme_font_size_override("font_size", 18)
		_list.add_child(head)
		for item in quest_items:
			var l := Label.new()
			l.text = "  %s x%d" % [item.display_name, GameState.inventory.count(item.id)]
			l.tooltip_text = item.description
			l.mouse_filter = Control.MOUSE_FILTER_PASS
			_list.add_child(l)
	if _selected == &"" or ql.def_of(_selected).is_empty():
		_selected = ql.active.keys()[0] if not ql.active.is_empty() else &""
	_show(_selected)


func _section(title: String, ids: Array, color: Color) -> void:
	var head := Label.new()
	head.text = "%s (%d)" % [title, ids.size()]
	head.add_theme_font_size_override("font_size", 18)
	head.modulate = color
	_list.add_child(head)
	for id in ids:
		var q := GameState.quests.def_of(id)
		var b := Button.new()
		b.text = "  %s%s" % ["📌 " if id == GameState.quests.pinned else "", q.title]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(func():
			_selected = id
			_show(id))
		_list.add_child(b)


func _show(id: StringName) -> void:
	var ql := GameState.quests
	_pin_btn.disabled = not ql.is_active(id) or ql.pinned == id
	if id == &"":
		_detail.text = "No quests yet. Talk to people, check the notice board on rest floors, and look around."
		return
	var q := ql.def_of(id)
	var status := "Active" if ql.is_active(id) else ("Completed" if ql.is_done(id) else "Failed")
	var t := "[font_size=22]%s[/font_size]\n%s   ·   From: %s   ·   %s\n\n%s\n\n[b]Steps[/b]\n" % [
		q.title, String(q.kind).capitalize(), q.get("giver", "?"), status, q.get("desc", "")]
	var current := ql.step_index(id)
	for i in q.steps.size():
		var mark := "   "
		var line: String = q.steps[i].text
		if ql.is_done(id) or (current >= 0 and i < current):
			mark = "[color=#88dd88]✔[/color]"
		elif i == current:
			mark = "[color=#ffd166]▶[/color]"
			line = ql.step_text(id)
		elif current >= 0 and i > current:
			line = "[color=#888888]%s[/color]" % line   # later steps, dimmed
		t += " %s %s\n" % [mark, line]
	if q.has("expires_after_floor") and ql.is_active(id):
		t += "\n[color=#ff9966]Must be finished by floor %d.[/color]\n" % q.expires_after_floor
	t += "\n[b]Reward[/b]: %s" % NoticeBoardPanel.reward_text(q.get("rewards", {}))
	_detail.text = t
