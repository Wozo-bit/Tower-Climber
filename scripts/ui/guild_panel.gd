class_name GuildPanel
extends Control
## Tab -> Guilds: your guild (or founding one), its hall (treasury, tax,
## upgrades), every guild's patron, floors, tax and your standing, the wars
## going on, your mercenary contract / heist, and the Tower News.

signal closed

var _controls: HBoxContainer
var _text: RichTextLabel
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
	_controls = HBoxContainer.new()
	_controls.add_theme_constant_override("separation", 6)
	root.add_child(_controls)
	_message = Label.new()
	_message.modulate = Color(0.7, 1, 0.75)
	root.add_child(_message)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_text)


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


func _button(text: String, on_press: Callable, disabled := false, tip := "") -> void:
	var b := Button.new()
	b.text = text
	b.disabled = disabled
	b.tooltip_text = tip
	b.pressed.connect(on_press)
	_controls.add_child(b)


func _rebuild() -> void:
	for c in _controls.get_children():
		_controls.remove_child(c)
		c.queue_free()
	var gs := GameState.guilds
	var pg := GuildLibrary.PLAYER_GUILD
	if gs.has_own_guild():
		_button("Withdraw 100", func(): _say("Withdrew %d gold." % gs.withdraw(100)), gs.treasury_of(pg) <= 0)
		_button("Withdraw all", func(): _say("Withdrew %d gold." % gs.withdraw(gs.treasury_of(pg))), gs.treasury_of(pg) <= 0)
		_button("Tax -", func(): gs.set_player_tax(gs.player_guild.tax - 0.05); _rebuild(), gs.player_guild.tax <= 0.0)
		_button("Tax +", func(): gs.set_player_tax(gs.player_guild.tax + 0.05); _rebuild(),
			gs.player_guild.tax >= GuildState.MAX_PLAYER_TAX - 0.001, "Higher tax: more income from your floors.")
		for id in GuildState.UPGRADES:
			var up: Dictionary = GuildState.UPGRADES[id]
			var lv := gs.upgrade_level(id)
			var maxed: bool = lv >= up.max
			_button("%s %d/%d%s" % [up.name, lv, up.max, "" if maxed else " (%dg)" % gs.upgrade_cost(id)],
				func(): _say("%s upgraded." % up.name if gs.buy_upgrade(id) else "Not enough in the treasury."),
				maxed, up.desc)
		var war_no := gs.player_war_refusal()
		_button("Declare war (%dg)" % GuildAI.WAR_COST, _open_war, war_no != "",
			war_no if war_no != "" else "Attack another guild's territory. Beat its guards and champion to take it.")
	else:
		var refusal := gs.charter_refusal()
		_button("Found a guild (%dg)" % GuildState.CHARTER_COST, _open_charter, refusal != "",
			refusal if refusal != "" else "Name your guild and pick a patron. You'll leave your current guild.")

	var t := ""
	if gs.has_own_guild():
		t += "[b]You lead %s[/b]  ·  Patron: %s  ·  Treasury %d gold  ·  Tax %d%%  ·  Floors: %s\n" % [
			gs.player_guild.name, BeingLibrary.full_name(gs.player_guild.patron) if gs.player_guild.patron != &"" else "none",
			gs.treasury_of(pg), roundi(gs.player_guild.tax * 100),
			", ".join(gs.territories_of(pg).map(func(i): return GuildLibrary.territory_floors(i))) if not gs.territories_of(pg).is_empty()
				else "none yet (beat a territory's champion to claim it)"]
	elif gs.member != &"":
		t += "[b]You're a %s of %s[/b]%s\n" % [GuildLibrary.rank_name(gs.rank), GuildLibrary.guild_name(gs.member),
			"  ·  your pay is ready" if gs.pay_due() else ""]
	else:
		t += "[b]You're not in a guild.[/b] Talk to a guild agent to join one (one at a time).\n"
	if gs.mercenary_for != &"":
		t += "[color=#ffd166]Mercenary for %s.[/color] Beat their enemy's guards on the contested floors.\n" % GuildLibrary.guild_name(gs.mercenary_for)
	if not gs.heist.is_empty():
		t += "[color=#ffd166]Heist:[/color] rob %s's vault (talk to one of their agents).\n" % GuildLibrary.guild_name(gs.heist.target)
	if not gs.wars.is_empty():
		t += "\n[b]Wars[/b]\n"
		for w in gs.wars:
			t += "   %s vs %s over %s (%s)\n" % [GuildLibrary.guild_name(w.attacker), GuildLibrary.guild_name(w.defender),
				GuildLibrary.territory_floors(w.territory),
				"attacker winning" if w.score > 1.5 else ("defender winning" if w.score < -1.5 else "even")]

	t += "\n[b]Guilds[/b]\n"
	var here := gs.owner_of_floor(GameState.floor_number)
	var order: Array = GuildLibrary.START_OWNERS.duplicate()
	for g in GuildLibrary.guilds:
		if not order.has(g):
			order.append(g)
	for id in order:
		var g := GuildLibrary.get_guild(id)
		if g.is_empty():
			continue
		var floors: Array = gs.territories_of(id).map(func(i): return GuildLibrary.territory_floors(i))
		var r := gs.rep_of(id)
		var col := "#88dd88" if r >= 10 else ("#dd8888" if r <= -10 else "#cccccc")
		var tags := ""
		if id == here:
			tags += "  [color=#ffd166](you are here)[/color]"
		if id == gs.member:
			tags += "  [color=#88dd88](yours)[/color]"
		if gs.is_hostile(id):
			tags += "  [color=#ff6666](hunting you)[/color]"
		t += "[b]%s[/b]%s\n" % [g.name, tags]
		t += "   Patron: %s  ·  %s  ·  Tax %d%%  ·  Prices x%.2f  ·  Standing: [color=%s]%s (%d)[/color]\n" % [
			BeingLibrary.full_name(g.patron) if g.patron != &"" else "none",
			", ".join(floors) if not floors.is_empty() else "no floors", roundi(g.tax * 100), g.price_mult,
			col, GuildState.standing_name(r), r]

	t += "\n[b]Tower News[/b]\n"
	if gs.news.is_empty():
		t += "   Nothing yet.\n"
	for i in range(gs.news.size() - 1, maxi(-1, gs.news.size() - 13), -1):
		t += "   Floor %d: %s\n" % [gs.news[i].floor, gs.news[i].text]
	_text.text = t


func _say(text: String) -> void:
	_message.text = text
	_rebuild()


## Name + patron dialog for a new guild charter.
func _open_charter() -> void:
	var dlg := ConfirmationDialog.new()
	dlg.title = "Found a guild (%d gold)" % GuildState.CHARTER_COST
	var box := VBoxContainer.new()
	var l := Label.new()
	l.text = "Name your guild:"
	box.add_child(l)
	var edit := LineEdit.new()
	edit.max_length = 32
	edit.custom_minimum_size.x = 320
	box.add_child(edit)
	var l2 := Label.new()
	l2.text = "Sign with a patron (shapes how others see your guild):"
	box.add_child(l2)
	var opt := OptionButton.new()
	var patrons := GuildState.willing_patrons()
	opt.add_item("No patron")
	for p in patrons:
		opt.add_item(BeingLibrary.full_name(p))
	if not patrons.is_empty() and patrons[0] == GameState.player.blessing_id:
		opt.selected = 1   # your blessing's being is first in line
	box.add_child(opt)
	dlg.add_child(box)
	dlg.confirmed.connect(func():
		var patron: StringName = patrons[opt.selected - 1] if opt.selected > 0 else &""
		if GameState.guilds.found_guild(edit.text, patron):
			_say("%s is founded!" % GameState.guilds.player_guild.name)
		else:
			_say("Give your guild a name.")
		dlg.queue_free())
	dlg.canceled.connect(dlg.queue_free)
	add_child(dlg)
	dlg.popup_centered()
	edit.grab_focus()


## Pick a territory for your guild to attack.
func _open_war() -> void:
	var gs := GameState.guilds
	var targets := gs.player_war_targets()
	if targets.is_empty():
		return
	var dlg := ConfirmationDialog.new()
	dlg.title = "Declare war (%d gold from the treasury)" % GuildAI.WAR_COST
	dlg.ok_button_text = "Declare war"
	var box := VBoxContainer.new()
	var l := Label.new()
	l.text = "Which territory do you want to take?"
	box.add_child(l)
	var opt := OptionButton.new()
	for t in targets:
		opt.add_item("%s  (%s)" % [GuildLibrary.territory_floors(t), GuildLibrary.guild_name(gs.owners[t])])
	box.add_child(opt)
	dlg.add_child(box)
	dlg.confirmed.connect(func():
		var t: int = targets[opt.selected]
		_say("War! Fight %s's guards on %s." % [GuildLibrary.guild_name(gs.owners[t]), GuildLibrary.territory_floors(t)]
			if gs.player_declare_war(t) else "You can't declare that war right now.")
		dlg.queue_free())
	dlg.canceled.connect(dlg.queue_free)
	add_child(dlg)
	dlg.popup_centered()
