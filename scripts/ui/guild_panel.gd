class_name GuildPanel
extends Control
## Tab -> Guilds: every guild, its patron, the floors it runs, its tax and
## your standing with it, plus your membership and rank.

signal closed

var _text: RichTextLabel


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
	panel.custom_minimum_size = Vector2(1000, 560)
	UIStyle.apply(panel)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = "Guilds"
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var done := Button.new()
	done.text = "Done"
	done.pressed.connect(close)
	header.add_child(done)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_text)
	var hint := Label.new()
	hint.text = "Guild agents stand on the first floor of each territory and on rest floors. Guild jobs on the notice board raise your standing with the guild that posted them."
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
	var gs := GameState.guilds
	var t := ""
	if gs.member != &"":
		t += "[b]You're a %s of %s[/b]%s\n\n" % [GuildLibrary.rank_name(gs.rank), GuildLibrary.guild_name(gs.member),
			"  ·  your pay is ready" if gs.pay_due() else ""]
	else:
		t += "[b]You're not in a guild.[/b] Talk to a guild agent to join one (one at a time).\n\n"
	var here := gs.owner_of_floor(GameState.floor_number)
	for id in GuildLibrary.START_OWNERS + GuildLibrary.guilds.keys().filter(func(g): return not GuildLibrary.START_OWNERS.has(g)):
		var g := GuildLibrary.get_guild(id)
		if g.is_empty():
			continue
		var floors: Array = gs.territories_of(id).map(func(i): return GuildLibrary.territory_floors(i))
		var r := gs.rep_of(id)
		var col := "#88dd88" if r >= 10 else ("#dd8888" if r <= -10 else "#cccccc")
		t += "[b]%s[/b]%s%s\n" % [g.name, "  [color=#ffd166](you are here)[/color]" if id == here else "",
			"  [color=#88dd88](member)[/color]" if id == gs.member else ""]
		t += "   Patron: %s   ·   %s   ·   Tax %d%%   ·   Prices x%.2f\n" % [BeingLibrary.full_name(g.patron),
			", ".join(floors) if not floors.is_empty() else "no floors", roundi(g.tax * 100), g.price_mult]
		t += "   Standing: [color=%s]%s (%d)[/color]\n" % [col, GuildState.standing_name(r), r]
	_text.text = t
