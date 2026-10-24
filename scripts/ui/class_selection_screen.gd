class_name ClassSelectionScreen
extends Control
## Full-screen overlay shown at level 10. Lists EVERY class the player
## qualifies for; if none qualify, shows the closest ones and offers a respec.

signal class_confirmed(def: ClassDef)
signal respec_requested
signal closed

var character: CharacterData
var _selected: ClassDef
var _group := ButtonGroup.new()

var _title: Label
var _subtitle: Label
var _list: VBoxContainer
var _detail: Label
var _confirm_btn: Button
var _respec_btn: Button


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	UIStyle.apply(panel)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 26)
	box.add_child(_title)

	_subtitle = Label.new()
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_subtitle)

	_list = VBoxContainer.new()
	box.add_child(_list)

	_detail = Label.new()
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size.y = 48
	box.add_child(_detail)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(buttons)

	_respec_btn = Button.new()
	_respec_btn.pressed.connect(func(): respec_requested.emit())
	buttons.add_child(_respec_btn)

	var later := Button.new()
	later.text = "Decide later"
	later.pressed.connect(close)
	buttons.add_child(later)

	_confirm_btn = Button.new()
	_confirm_btn.text = "Confirm class"
	_confirm_btn.pressed.connect(_on_confirm)
	buttons.add_child(_confirm_btn)


func open(c: CharacterData) -> void:
	character = c
	refresh()
	show()


func close() -> void:
	hide()
	closed.emit()


func refresh() -> void:
	if character == null:
		return
	_selected = null
	for child in _list.get_children():
		child.queue_free()
	_group = ButtonGroup.new()

	var qualifying := character.get_qualifying_classes()
	var warn := ""
	if character.unspent_points > 0:
		warn = "You still have %d unspent points — spending them may change your options. " % character.unspent_points

	if character.stats.total_allocated() == 0:
		_title.text = "Spend your points first"
		_subtitle.text = "Only points you allocate count toward a class — your base stats don't. Requirements:"
		for def in ClassRegistry.get_tier(1):
			if def.is_secret:
				continue
			var req := Label.new()
			req.text = "%s — %s" % [def.display_name, def.requirement_text()]
			_list.add_child(req)
		_detail.text = ""
	elif qualifying.is_empty():
		_title.text = "No class qualifies yet"
		_subtitle.text = warn + "Your stats are spread too evenly. Here's how close you are:"
		for miss in ClassRegistry.get_near_misses(character.stats):
			var def: ClassDef = miss.def
			var row := Label.new()
			row.text = "%s — %d%% (needs %s)  ·  ~%d more points in those stats" % [
				def.display_name, roundi(miss.share * 100.0), def.requirement_text(), miss.points_short]
			_list.add_child(row)
		_detail.text = ""
	else:
		_title.text = "Choose your class"
		_subtitle.text = warn + ("You qualify for %d class%s." % [qualifying.size(), "" if qualifying.size() == 1 else "es"])
		for def in qualifying:
			var btn := Button.new()
			btn.toggle_mode = true
			btn.button_group = _group
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.text = "%s   —   %d%%  (needs %s)" % [
				def.display_name, roundi(def.qualification_share(character.stats) * 100.0), def.requirement_text()]
			btn.pressed.connect(_on_select.bind(def))
			_list.add_child(btn)
		_detail.text = "Select a class to see details."

	var cost := character.next_respec_cost()
	_respec_btn.text = "Respec (free)" if cost == 0 else "Respec (%d gold)" % cost
	_respec_btn.disabled = not character.can_respec()
	_confirm_btn.disabled = true
	_confirm_btn.visible = not qualifying.is_empty()


func _on_select(def: ClassDef) -> void:
	_selected = def
	_detail.text = def.description
	_confirm_btn.disabled = false


func _on_confirm() -> void:
	# Keep a local ref: choose_class() emits stats_changed, which can trigger refresh()
	# and clear _selected before we emit.
	var def := _selected
	if def and character.choose_class(def):
		hide()
		class_confirmed.emit(def)
