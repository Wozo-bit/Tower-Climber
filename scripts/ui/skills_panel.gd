class_name SkillsPanel
extends Control
## A character's skills: class skills, learned shared skills, and spending
## skill picks on Common shared skills. (Skill books are used from Items.)

signal closed

var member: CharacterData
var _title: Label
var _known_box: VBoxContainer
var _pick_box: VBoxContainer
var _picks_label: Label


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
	panel.custom_minimum_size = Vector2(1000, 500)
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

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 24)
	root.add_child(body)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(left)
	left.add_child(_heading("Known skills"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	_known_box = VBoxContainer.new()
	_known_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_known_box)

	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 420
	body.add_child(right)
	right.add_child(_heading("Learn a skill"))
	_picks_label = Label.new()
	_picks_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_picks_label)
	_pick_box = VBoxContainer.new()
	right.add_child(_pick_box)
	var hint := Label.new()
	hint.text = "Rarer skills come from skill books that monsters drop (bosses most often).\nUse them from the party menu's Items list."
	hint.modulate = Color(1, 1, 1, 0.55)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(hint)


func open(c: CharacterData) -> void:
	member = c
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
	for c in _known_box.get_children():
		c.queue_free()
	for c in _pick_box.get_children():
		c.queue_free()
	_title.text = "%s's Skills" % member.character_name

	var class_skills := SkillLibrary.skills_for_class(member.class_id)
	if class_skills.is_empty():
		_known_box.add_child(_note("Class skills: none yet (choose a class at level %d)." % CharacterData.CLASS_UNLOCK_LEVEL))
	for s in class_skills:
		_known_box.add_child(_skill_line(s, "Class"))
	if member.learned_skills.is_empty():
		_known_box.add_child(_note("No shared skills learned yet."))
	for id in member.learned_skills:
		var s := SkillLibrary.get_skill_or_null(id)
		if s:
			_known_box.add_child(_skill_line(s, SkillTier.name_of(s.tier)))

	_picks_label.text = ("Skill picks available: %d  (you get one every %d levels)" % [
		member.skill_picks, CharacterData.SKILL_PICK_EVERY])
	for s in SkillLibrary.pick_pool():
		if member.learned_skills.has(s.id):
			continue
		var row := HBoxContainer.new()
		var l := Label.new()
		l.text = "%s (%d MP) — %s" % [s.display_name, s.mp_cost, s.description]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		var b := Button.new()
		b.text = "Learn"
		b.disabled = member.skill_picks <= 0
		b.pressed.connect(func():
			member.pick_skill(s.id)
			_rebuild())
		row.add_child(b)
		_pick_box.add_child(row)


func _skill_line(s: SkillDef, tag: String) -> Label:
	var l := Label.new()
	l.text = "[%s] %s (%d MP) — %s" % [tag, s.display_name, s.mp_cost, s.description]
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if s.learnable:
		l.add_theme_color_override("font_color", SkillTier.color_of(s.tier))
	return l


func _heading(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 20)
	return l


func _note(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.modulate = Color(1, 1, 1, 0.55)
	return l
