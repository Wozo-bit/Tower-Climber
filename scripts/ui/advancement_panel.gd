class_name AdvancementPanel
extends Control
## Tab -> a member's "✦ Advance" button: the classes their class can advance
## into, with a checklist of what each needs (floor, level, stat build, route,
## trial quest), a button to begin the trial, and one to advance.

signal closed

var member: CharacterData
var _title: Label
var _list: VBoxContainer
var _message: Label


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
	panel.custom_minimum_size = Vector2(900, 0)
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
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 24)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	var done := Button.new()
	done.text = "Done"
	done.pressed.connect(close)
	header.add_child(done)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 10)
	root.add_child(_list)
	var hint := Label.new()
	hint.text = "You keep every skill you have and gain the new class's skills, plus +10% to every stat. Your class's Unique weapon still fits."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(1, 1, 1, 0.55)
	root.add_child(hint)
	_message = Label.new()
	_message.modulate = Color(0.7, 1, 0.75)
	root.add_child(_message)


func open(c: CharacterData) -> void:
	member = c
	_message.text = ""
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
	var current := member.get_class_def()
	_title.text = "%s: advance from %s" % [member.character_name, current.display_name if current else "?"]
	var options := member.available_advancements()
	if options.is_empty():
		_list.add_child(_note("No advancements for this class yet."))
	for def in options:
		_list.add_child(_option(def))


func _option(def: ClassDef) -> Control:
	var s := member.advancement_status(def)
	var panel := PanelContainer.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var info := Label.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var skills: PackedStringArray = []
	for sid in SkillLibrary.CLASS_SKILLS.get(def.id, []):
		skills.append(SkillLibrary.get_skill(sid).display_name)
	var gate: Dictionary = s.gate
	var lines: PackedStringArray = [
		"%s — %s" % [def.display_name, def.description],
		"New skills: %s" % ", ".join(skills),
		"%s Beat floor %d" % [_mark(s.floor), gate.get("floor", 0)],
		"%s Level %d (now %d)" % [_mark(s.level), gate.get("level", 0), member.level],
		"%s %s (now %d%%)" % [_mark(s.stats), def.requirement_text(), roundi(def.qualification_share(member.stats) * 100)],
	]
	if def.required_route != &"":
		lines.append("%s %s route" % [_mark(s.route), RouteLibrary.route_name(def.required_route)])
	var trial := CharacterData.trial_id(def)
	var ql := GameState.quests
	var trial_state := "done" if ql.is_done(trial) else ("in progress: " + ql.step_text(trial) if ql.is_active(trial) else "not started")
	lines.append("%s %s (%s)" % [_mark(s.trial), QuestLibrary.get_quest(trial).title, trial_state])
	info.text = "\n".join(lines)
	row.add_child(info)

	var buttons := VBoxContainer.new()
	row.add_child(buttons)
	if ql.is_new(trial):
		var start := Button.new()
		start.text = "Begin trial"
		start.disabled = not (s.floor and s.level)
		start.tooltip_text = "Adds the trial to Tab -> Quests."
		start.pressed.connect(func():
			ql.start(trial)
			_message.text = "Trial started: see Tab -> Quests."
			_rebuild())
		buttons.add_child(start)
	var adv := Button.new()
	adv.text = "Advance!"
	adv.disabled = not member.can_advance(def)
	adv.pressed.connect(_confirm.bind(def))
	buttons.add_child(adv)
	return panel


func _confirm(def: ClassDef) -> void:
	var dlg := ConfirmationDialog.new()
	dlg.title = "Advance"
	dlg.dialog_text = "%s becomes a %s?\n\nThis can't be undone (you keep all your current skills)." % [
		member.character_name, def.display_name]
	dlg.confirmed.connect(func():
		if member.advance_class(def):
			_message.text = "%s is now a %s!" % [member.character_name, def.display_name]
		_rebuild()
		dlg.queue_free())
	dlg.canceled.connect(dlg.queue_free)
	add_child(dlg)
	dlg.popup_centered()


static func _mark(ok: bool) -> String:
	return "✔" if ok else "✘"


func _note(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.modulate = Color(1, 1, 1, 0.55)
	return l
