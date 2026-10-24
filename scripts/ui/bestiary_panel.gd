class_name BestiaryPanel
extends Control
## Tab -> Bestiary: every enemy you've fought, grouped by family, with what
## you've learned about its elements. Traits and lore show once it's beaten
## (or Scanned with a Scouting Lens).

signal closed

var _list: VBoxContainer
var _detail: RichTextLabel


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
	title.text = "Bestiary"
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
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
	hint.text = "Hit enemies with different elements to learn how they react. Enemies of the same family share what you learn. A Scouting Lens reveals everything about one enemy."
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
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("party_menu")):
		get_viewport().set_input_as_handled()
		close()


func _rebuild() -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	var b := GameState.bestiary
	# Group seen enemies by family, families in a stable order.
	var by_family := {}
	for id in b.entries:
		var def := EnemyLibrary.get_enemy_or_null(id)
		if def:
			if not by_family.has(def.family):
				by_family[def.family] = []
			by_family[def.family].append(def)
	if by_family.is_empty():
		_detail.text = "Nothing yet. Every enemy you fight is added here."
		return
	var fams := by_family.keys()
	fams.sort()
	var first: EnemyDef
	for fam in fams:
		var head := Label.new()
		head.text = EnemyFamilies.family_name(fam)
		head.add_theme_font_size_override("font_size", 18)
		head.modulate = Color(0.95, 0.85, 0.55)
		_list.add_child(head)
		var defs: Array = by_family[fam]
		defs.sort_custom(func(x, y): return x.display_name < y.display_name)
		for def: EnemyDef in defs:
			var btn := Button.new()
			btn.text = "  " + def.display_name
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.pressed.connect(_show.bind(def))
			_list.add_child(btn)
			if first == null:
				first = def
	_show(first)


func _show(def: EnemyDef) -> void:
	var b := GameState.bestiary
	var e: Dictionary = b.entries.get(def.id, {})
	var t := "[font_size=22]%s[/font_size]\n%s   ·   Beaten: %d%s\n\n" % [def.display_name,
		EnemyFamilies.family_name(def.family), e.get("defeated", 0), "   ·   Scanned" if e.get("scanned", false) else ""]
	var known := b.known_affinities(def)
	t += "[b]Elements[/b]\n"
	for el in Element.Type.values():
		var col := Element.color_of(el).to_html(false)
		var what := "?"
		if known.has(el):
			what = Element.affinity_name(known[el])
			if known[el] == Element.Affinity.WEAK:
				what = "[color=#ff7744]WEAK[/color]"
		t += "  [color=#%s]%s[/color]: %s\n" % [col, Element.name_of(el), what]
	t += "\n[b]Traits[/b]\n"
	if b.knows_details(def.id):
		var traits := EnemyFamilies.traits_for(def)
		if traits.is_empty():
			t += "  None\n"
		for tr in traits:
			t += "  %s: %s\n" % [EnemyFamilies.trait_name(tr), EnemyFamilies.trait_desc(tr)]
		if def.lore != "":
			t += "\n[i]%s[/i]" % def.lore
	else:
		t += "  ? (beat it, or use a Scouting Lens)\n"
	_detail.text = t
