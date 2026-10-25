class_name DivinityPanel
extends Control
## Tab -> Divinity (only for a god in New Game+): your faith and divinity
## level, the guilds you sponsor (boon, curse, stance, level), and offering
## contracts to other guilds. See DivinityState.

signal closed

var _list: VBoxContainer
var _header: Label
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
	panel.custom_minimum_size = Vector2(1060, 600)
	UIStyle.apply(panel)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)
	var top := HBoxContainer.new()
	root.add_child(top)
	_header = Label.new()
	_header.add_theme_font_size_override("font_size", 22)
	_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_header)
	var done := Button.new()
	done.text = "Done"
	done.pressed.connect(close)
	top.add_child(done)
	_message = Label.new()
	_message.modulate = Color(0.7, 1, 0.75)
	root.add_child(_message)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)


func open() -> void:
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
	var dv: DivinityState = GameState.divinity
	_header.text = "%s, %s   ·   Faith %d   ·   Divinity level %d   ·   Contracts %d / %d" % [
		GameState.player.character_name, dv.title, dv.faith, dv.level(), dv.others().size(), dv.slots()]
	_list.add_child(_note("Guilds you sponsor take you as their patron: they follow your values, pay tithes every floor (faith + gold) and get the boon you grant, paid for by the curse you choose. Their level grows as they serve you."))
	_list.add_child(_heading("Your guilds"))
	if dv.contracts.is_empty():
		_list.add_child(_note("None yet. Found your own guild (Tab -> Guilds, past floor %d) or offer a contract below." % GuildState.CHARTER_FLOOR))
	for g in dv.contracts:
		_list.add_child(_contract_row(g))
	_list.add_child(_heading("Bless your people (%d faith each)" % DivinityState.BLESS_FAITH))
	for c in GameState.companions + GameState.reserve:
		_list.add_child(_person_row(c))
	_list.add_child(_heading("Offer a contract"))
	var ids := GuildLibrary.guilds.keys().filter(func(g): return not dv.contracts.has(g) and g != GuildLibrary.PLAYER_GUILD)
	ids.sort()
	for g in ids:
		_list.add_child(_offer_row(g))


func _contract_row(g: StringName) -> Control:
	var dv: DivinityState = GameState.divinity
	var c: Dictionary = dv.contracts[g]
	var panel := PanelContainer.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var info := Label.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.text = "%s%s   Level %d   ·   %d floors held" % [GuildLibrary.guild_name(g),
		"  (your guild)" if g == GuildLibrary.PLAYER_GUILD else "", dv.contract_level(g),
		GameState.guilds.territories_of(g).size() * GuildLibrary.TERRITORY_FLOORS]
	row.add_child(info)
	var boon := _picker(DivinityState.BOONS, c.boon, func(b): return "%s (cost %d)" % [DivinityState.BOONS[b].name, DivinityState.BOONS[b].cost])
	var curse := _picker(DivinityState.CURSES, c.curse, func(k): return "%s (weight %d)" % [DivinityState.CURSES[k].name, DivinityState.CURSES[k].weight])
	boon.tooltip_text = DivinityState.BOONS[c.boon].desc
	curse.tooltip_text = DivinityState.CURSES[c.curse].desc
	var apply_terms := func(_i):
		var why := dv.set_terms(g, boon.get_item_metadata(boon.selected), curse.get_item_metadata(curse.selected))
		_message.text = why if why != "" else "%s: terms set." % GuildLibrary.guild_name(g)
		_rebuild()
	boon.item_selected.connect(apply_terms)
	curse.item_selected.connect(apply_terms)
	row.add_child(_label("Boon"))
	row.add_child(boon)
	row.add_child(_label("Curse"))
	row.add_child(curse)
	if g != GuildLibrary.PLAYER_GUILD:
		var stance := _picker(DivinityState.STANCES, c.stance, func(s): return DivinityState.STANCES[s].name)
		stance.tooltip_text = "How this guild acts each floor: raids, wars, alliances, fortifying."
		stance.item_selected.connect(func(i):
			dv.set_stance(g, stance.get_item_metadata(i))
			_message.text = "%s will act %s." % [GuildLibrary.guild_name(g), DivinityState.STANCES[stance.get_item_metadata(i)].name.to_lower()])
		row.add_child(_label("Stance"))
		row.add_child(stance)
		row.add_child(_smite_button(g))
		var revoke := Button.new()
		revoke.text = "Revoke"
		revoke.tooltip_text = "End the contract. They go back to their old patron, and feud with you for the rest of the run."
		revoke.pressed.connect(func():
			if dv.revoke(g):
				_message.text = "%s is no longer yours. They won't forget it." % GuildLibrary.guild_name(g)
			_rebuild())
		row.add_child(revoke)
	if c.get("warned", false):
		info.text += "   ⚠ warned"
		info.add_theme_color_override("font_color", Color(1, 0.7, 0.4))
	return panel


func _smite_button(g: StringName) -> Button:
	var dv: DivinityState = GameState.divinity
	var b := Button.new()
	b.text = "Smite (%d)" % DivinityState.SMITE_FAITH
	var why := dv.smite_refusal(g)
	b.disabled = why != ""
	b.tooltip_text = why if why != "" else "Strike them: -%d%% treasury, -1 defense, their wars turn against them. Their patron won't like it." % \
		roundi(DivinityState.SMITE_TREASURY * 100)
	b.pressed.connect(func():
		if dv.smite(g):
			_message.text = "You smite %s." % GuildLibrary.guild_name(g)
		_rebuild())
	return b


func _person_row(c: CharacterData) -> Control:
	var dv: DivinityState = GameState.divinity
	var row := HBoxContainer.new()
	var info := Label.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var now := "blessed by you (level %d)" % c.blessing_level if c.blessing_id == dv.god_id else (
		"blessed by %s" % BeingLibrary.get_being(c.blessing_id).get("name", "?") if c.blessing_id != &"" else "not blessed")
	info.text = "%s   Lv %d   ·   %s" % [c.character_name, c.level, now]
	row.add_child(info)
	var why := dv.bless_refusal(c)
	var b := Button.new()
	b.text = "Bless"
	b.disabled = why != ""
	b.tooltip_text = why if why != "" else "Your domain's blessing (and its curse) at level %d, plus its skill." % dv.person_level()
	b.pressed.connect(func():
		if dv.bless_person(c):
			_message.text = "%s receives your blessing." % c.character_name
		_rebuild())
	row.add_child(b)
	return row


func _offer_row(g: StringName) -> Control:
	var dv: DivinityState = GameState.divinity
	var row := HBoxContainer.new()
	var info := Label.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var patron := BeingLibrary.get_being(GuildLibrary.get_guild(g).get("patron", &""))
	info.text = "%s   ·   patron: %s   ·   %d floors" % [GuildLibrary.guild_name(g), patron.get("name", "none"),
		GameState.guilds.territories_of(g).size() * GuildLibrary.TERRITORY_FLOORS]
	row.add_child(info)
	var why := dv.contract_refusal(g)
	var b := Button.new()
	b.text = "Sponsor (%d faith)" % dv.contract_cost(g)
	b.disabled = why != ""
	b.tooltip_text = why if why != "" else "%s will be furious: you're taking their guild." % patron.get("name", "Its patron")
	b.pressed.connect(func():
		if dv.sponsor(g):
			_message.text = "%s now answers to you." % GuildLibrary.guild_name(g)
		_rebuild())
	row.add_child(b)
	row.add_child(_smite_button(g))
	if dv.renegades.has(g):
		info.text += "   ·   renegade (feuds with you)"
	return row


## An OptionButton over a table's keys, with `current` selected.
func _picker(table: Dictionary, current: StringName, label: Callable) -> OptionButton:
	var o := OptionButton.new()
	for k in table:
		o.add_item(label.call(k))
		o.set_item_metadata(o.item_count - 1, k)
		if k == current:
			o.select(o.item_count - 1)
	return o


func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.modulate = Color(1, 1, 1, 0.6)
	return l


func _heading(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color(1, 0.9, 0.55))
	return l


func _note(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.modulate = Color(1, 1, 1, 0.6)
	return l
