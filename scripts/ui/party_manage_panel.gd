class_name PartyManagePanel
extends Control
## Tab -> Manage party: order, rows, bench / swap with the reserve, dismiss.
## Swapping, benching and dismissing are locked on a floor whose miniboss or
## boss is still standing (GameState.party_locked); order and rows never are.

signal closed

var _lock_label: Label
var _party_box: VBoxContainer
var _party_title: Label
var _reserve_box: VBoxContainer
var _reserve_title: Label
var _waiting_label: Label
var _message: Label
## Reserve member picked with "Swap in…": party rows then show "⇄ Swap out".
var _swap_in: CharacterData


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
	panel.custom_minimum_size = Vector2(1060, 500)
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
	title.text = "Manage party"
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "Done"
	close_btn.pressed.connect(close)
	header.add_child(close_btn)

	_lock_label = Label.new()
	_lock_label.add_theme_color_override("font_color", Color(1, 0.6, 0.3))
	root.add_child(_lock_label)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 24)
	root.add_child(body)
	var party_col := VBoxContainer.new()
	party_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	party_col.size_flags_stretch_ratio = 1.3
	body.add_child(party_col)
	_party_title = _heading()
	party_col.add_child(_party_title)
	_party_box = VBoxContainer.new()
	_party_box.add_theme_constant_override("separation", 6)
	party_col.add_child(_party_box)

	var reserve_col := VBoxContainer.new()
	reserve_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(reserve_col)
	_reserve_title = _heading()
	reserve_col.add_child(_reserve_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	reserve_col.add_child(scroll)
	_reserve_box = VBoxContainer.new()
	_reserve_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reserve_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_reserve_box)

	_waiting_label = Label.new()
	_waiting_label.modulate = Color(1, 1, 1, 0.6)
	_waiting_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_waiting_label)
	_message = Label.new()
	_message.modulate = Color(0.7, 1, 0.75)
	root.add_child(_message)


func open() -> void:
	_swap_in = null
	_message.text = ""
	_rebuild()
	show()


func close() -> void:
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("party_menu") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _swap_in:
			_swap_in = null
			_message.text = ""
			_rebuild()
		else:
			close()


func _rebuild() -> void:
	for box in [_party_box, _reserve_box]:
		for c in box.get_children():
			box.remove_child(c)
			c.queue_free()
	var gs := GameState
	var locked := gs.party_locked()
	_lock_label.text = "Locked: " + gs.party_lock_reason() + " You can still change the order and rows." if locked else ""
	_lock_label.visible = locked
	_party_title.text = "Party  (%d / %d)" % [gs.battle_party().size(), gs.MAX_PARTY_SIZE]
	_reserve_title.text = "Reserve  (%d / %d)   ·   gets %d%% XP" % [gs.reserve.size(), gs.RESERVE_CAP,
		roundi(gs.RESERVE_XP_SHARE * 100)]

	# --- Party ---
	_party_box.add_child(_member_row(gs.player, [_row_button(gs.player)], "(you lead)"))
	for i in gs.companions.size():
		var c: CharacterData = gs.companions[i]
		var btns: Array = []
		if _swap_in:
			var swap_out := func():
				var who := _swap_in
				if gs.swap_members(c, who):
					_say("%s swapped in for %s." % [who.character_name, c.character_name])
				_swap_in = null
				_rebuild()
			btns.append(_button("⇄ Swap out", swap_out, locked))
		else:
			var up := func():
				gs.move_member(c, -1)
				_rebuild()
			var down := func():
				gs.move_member(c, 1)
				_rebuild()
			var bench := func():
				if gs.bench(c):
					_say("%s moved to the reserve." % c.character_name)
				_rebuild()
			var bench_full := gs.reserve.size() >= gs.RESERVE_CAP
			btns.append(_button("▲", up, i == 0, "Move up"))
			btns.append(_button("▼", down, i == gs.companions.size() - 1, "Move down"))
			btns.append(_row_button(c))
			btns.append(_button("Bench", bench, locked or bench_full,
				"The reserve is full." if bench_full else "Move to the reserve."))
			btns.append(_dismiss_button(c, locked))
		_party_box.add_child(_member_row(c, btns))
	for i in gs.MAX_PARTY_SIZE - gs.battle_party().size():
		_party_box.add_child(_note("— empty slot —"))

	# --- Reserve ---
	if gs.reserve.is_empty():
		_reserve_box.add_child(_note("Nobody on the reserve. Recruits go here\nwhen the party is full."))
	for c in gs.reserve:
		var btns: Array = []
		if gs.companions.size() < gs.MAX_PARTY_SIZE - 1:
			var join := func():
				if gs.unbench(c):
					_say("%s joined the party." % c.character_name)
				_rebuild()
			btns.append(_button("Join party", join, locked))
		elif _swap_in == c:
			var cancel := func():
				_swap_in = null
				_say("")
				_rebuild()
			btns.append(_button("Cancel", cancel))
		else:
			var pick := func():
				_swap_in = c
				_say("Swap %s in for who?" % c.character_name)
				_rebuild()
			btns.append(_button("Swap in…", pick, locked or _swap_in != null))
		btns.append(_dismiss_button(c, locked or _swap_in != null))
		_reserve_box.add_child(_member_row(c, btns))

	# --- Waiting at campfires ---
	if gs.waiting.is_empty():
		_waiting_label.text = "Dismissed companions wait by the campfire on rest floors. Talk to them there to bring them back."
	else:
		_waiting_label.text = "Waiting by rest-floor campfires: %s. Talk to them there to bring them back." % \
			", ".join(gs.waiting.map(func(c): return "%s (Lv %d)" % [c.character_name, c.level]))


func _member_row(c: CharacterData, buttons: Array, extra: String = "") -> Control:
	var panel := PanelContainer.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)
	var info := Label.new()
	var def := c.get_class_def()
	info.text = "%s   Lv %d   %s%s\n%s" % [c.character_name, c.level, def.display_name if def else "No class",
		"   " + extra if extra != "" else "",
		"DOWNED" if c.is_downed() else "HP %d/%d   MP %d/%d" % [c.current_hp(), c.max_hp(), c.current_mp(), c.max_mp()]]
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	for b in buttons:
		row.add_child(b)
	return panel


func _row_button(c: CharacterData) -> Button:
	var front := GameState.member_row(c) == Combatant.Row.FRONT
	var flip := func():
		GameState.set_member_row(c, Combatant.Row.BACK if front else Combatant.Row.FRONT)
		_rebuild()
	return _button("Front" if front else "Back", flip, false, "Starting row in battle. Click to switch.")


func _dismiss_button(c: CharacterData, disabled: bool) -> Button:
	return _button("Dismiss", _confirm_dismiss.bind(c), disabled,
		"Let them go. Not permanent: they'll wait by the campfire on rest floors.")


func _confirm_dismiss(c: CharacterData) -> void:
	var dlg := ConfirmationDialog.new()
	dlg.title = "Dismiss"
	dlg.dialog_text = "Dismiss %s?\n\nTheir gear goes to your bag. They'll wait by the campfire on rest\nfloors, exactly as they are, and you can take them back any time." % c.character_name
	dlg.confirmed.connect(func():
		if GameState.dismiss(c):
			_say("%s will wait for you at the next campfire." % c.character_name)
		_rebuild()
		dlg.queue_free())
	dlg.canceled.connect(dlg.queue_free)
	add_child(dlg)
	dlg.popup_centered()


func _button(text: String, on_press: Callable, disabled: bool = false, tooltip: String = "") -> Button:
	var b := Button.new()
	b.text = text
	b.disabled = disabled
	b.tooltip_text = tooltip
	b.pressed.connect(on_press)
	return b


func _say(text: String) -> void:
	_message.text = text


func _heading() -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", 20)
	return l


func _note(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.modulate = Color(1, 1, 1, 0.5)
	return l
