class_name GearPanel
extends Control
## Equip / unequip gear for one party member. Opened from the party menu.

signal closed

var member: CharacterData
var _title: Label
var _slots_box: VBoxContainer
var _bag_box: VBoxContainer
var _stats_label: Label


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
	var close_btn := Button.new()
	close_btn.text = "Done"
	close_btn.pressed.connect(close)
	header.add_child(close_btn)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 24)
	root.add_child(body)
	_slots_box = VBoxContainer.new()
	_slots_box.custom_minimum_size.x = 400
	_slots_box.add_theme_constant_override("separation", 10)
	body.add_child(_slots_box)

	var bag_col := VBoxContainer.new()
	bag_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(bag_col)
	var bag_title := Label.new()
	bag_title.text = "Bag"
	bag_title.add_theme_font_size_override("font_size", 20)
	bag_col.add_child(bag_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bag_col.add_child(scroll)
	_bag_box = VBoxContainer.new()
	_bag_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_bag_box)

	_stats_label = Label.new()
	_stats_label.modulate = Color(1, 1, 1, 0.8)
	root.add_child(_stats_label)


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
	for c in _slots_box.get_children():
		c.queue_free()
	for c in _bag_box.get_children():
		c.queue_free()
	var cls := member.get_class_def()
	_title.text = "%s's Gear   (%s)" % [member.character_name, cls.display_name if cls else "No class"]

	for slot in [GearItem.Slot.WEAPON, GearItem.Slot.ARMOR, GearItem.Slot.ACCESSORY]:
		var item := member.get_equipped(slot)
		var box := VBoxContainer.new()
		var head := Label.new()
		head.text = GearItem.slot_name(slot)
		head.modulate = Color(1, 1, 1, 0.55)
		box.add_child(head)
		var row := HBoxContainer.new()
		var name_l := Label.new()
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if item:
			name_l.text = item.summary()
			name_l.add_theme_color_override("font_color", Rarity.color_of(item.rarity))
			name_l.tooltip_text = item.description
			var un := Button.new()
			un.text = "Unequip"
			un.pressed.connect(func(): GameState.unequip_to_bag(member, slot); _rebuild())
			row.add_child(name_l)
			row.add_child(un)
		else:
			name_l.text = "(empty)"
			name_l.modulate = Color(1, 1, 1, 0.4)
			row.add_child(name_l)
		box.add_child(row)
		_slots_box.add_child(box)

	if GameState.inventory.gear.is_empty():
		var none := Label.new()
		none.text = "No gear yet. Minibosses drop loot."
		none.modulate = Color(1, 1, 1, 0.5)
		_bag_box.add_child(none)
	# Best rarity first
	var bag: Array = GameState.inventory.gear.duplicate()
	bag.sort_custom(func(a, b): return a.rarity > b.rarity)
	for g: GearItem in bag:
		var row := HBoxContainer.new()
		var l := Label.new()
		l.text = "%s: %s" % [GearItem.slot_name(g.slot), g.summary()]
		l.add_theme_color_override("font_color", Rarity.color_of(g.rarity))
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.tooltip_text = g.description
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(l)
		var eq := Button.new()
		eq.text = "Equip"
		eq.disabled = not g.can_equip(member)
		if eq.disabled:
			eq.tooltip_text = g.lock_text()
		eq.pressed.connect(func(): GameState.equip_from_bag(member, g); _rebuild())
		row.add_child(eq)
		_bag_box.add_child(row)

	var parts: PackedStringArray = []
	for s in Stats.all():
		var bonus := member.stats.get_gear_bonus(s)
		parts.append("%s %d%s" % [Stats.short_name_of(s), member.stats.get_total(s), " (+%d)" % bonus if bonus else ""])
	_stats_label.text = "   ".join(parts) + "      HP %d/%d   MP %d/%d" % [
		member.current_hp(), member.max_hp(), member.current_mp(), member.max_mp()]
