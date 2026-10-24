class_name PartyMenu
extends Control
## Out-of-battle party menu (Tab): HP/MP overview, use items, cast Heal,
## spend stat points and pick a class at level 10.

signal closed

var _members_box: VBoxContainer
var _actions_box: VBoxContainer
var _gold_label: Label
var _message: Label
var _stats_overlay: PanelContainer
var _stats_panel: StatAllocationPanel
var _class_screen: ClassSelectionScreen
var _gear_panel: GearPanel
var _skills_panel: SkillsPanel
var _manage_panel: PartyManagePanel

## When set, the member list shows "Use here" buttons.
## { "kind": "item", "id": StringName } or { "kind": "heal", "caster": CharacterData, "skill": SkillDef }
var _pending: Dictionary = {}


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(980, 520)
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
	title.text = "Party"
	title.add_theme_font_size_override("font_size", 26)
	header.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	_gold_label = Label.new()
	header.add_child(_gold_label)
	var manage_btn := Button.new()
	manage_btn.text = "Manage party"
	manage_btn.tooltip_text = "Order, rows, the reserve and dismissing companions."
	manage_btn.pressed.connect(open_manage)
	header.add_child(manage_btn)
	var close_btn := Button.new()
	close_btn.text = "Close (Tab)"
	close_btn.pressed.connect(close)
	header.add_child(close_btn)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 20)
	root.add_child(body)
	_members_box = VBoxContainer.new()
	_members_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_members_box.add_theme_constant_override("separation", 8)
	body.add_child(_members_box)
	_actions_box = VBoxContainer.new()
	_actions_box.custom_minimum_size.x = 320
	body.add_child(_actions_box)

	_message = Label.new()
	_message.modulate = Color(0.7, 1, 0.75)
	root.add_child(_message)

	# Stats sub-screen
	_stats_overlay = PanelContainer.new()
	_stats_overlay.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_stats_overlay.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_stats_overlay.grow_vertical = Control.GROW_DIRECTION_BOTH
	_stats_overlay.hide()
	UIStyle.apply(_stats_overlay)
	add_child(_stats_overlay)
	var sbox := VBoxContainer.new()
	_stats_overlay.add_child(sbox)
	_stats_panel = StatAllocationPanel.new()
	sbox.add_child(_stats_panel)
	var sclose := Button.new()
	sclose.text = "Done"
	sclose.pressed.connect(func(): _stats_overlay.hide(); _rebuild())
	sbox.add_child(sclose)

	_gear_panel = GearPanel.new()
	_gear_panel.closed.connect(_rebuild)
	add_child(_gear_panel)
	_skills_panel = SkillsPanel.new()
	_skills_panel.closed.connect(_rebuild)
	add_child(_skills_panel)
	_manage_panel = PartyManagePanel.new()
	_manage_panel.closed.connect(_rebuild)
	add_child(_manage_panel)

	_class_screen = ClassSelectionScreen.new()
	add_child(_class_screen)
	_class_screen.closed.connect(_rebuild)
	_class_screen.class_confirmed.connect(func(def): _say("Became a %s!" % def.display_name); _rebuild())
	_class_screen.respec_requested.connect(func():
		if _class_screen.character and _class_screen.character.respec():
			_class_screen.refresh())


func open() -> void:
	_pending = {}
	_message.text = ""
	_rebuild()
	show()


## Opens the Manage party screen on top of this menu.
func open_manage() -> void:
	_manage_panel.open()


func close() -> void:
	if _class_screen.visible or _stats_overlay.visible or _gear_panel.visible or _skills_panel.visible \
			or _manage_panel.visible:
		return
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _gear_panel.visible or _skills_panel.visible or _manage_panel.visible:
		return
	if event.is_action_pressed("party_menu") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _stats_overlay.visible:
			_stats_overlay.hide()
			_rebuild()
		elif not _pending.is_empty():
			_pending = {}
			_rebuild()
		else:
			close()


func _say(text: String) -> void:
	_message.text = text


# =========================================================
# Build
# =========================================================

func _rebuild() -> void:
	for c in _members_box.get_children():
		c.queue_free()
	for c in _actions_box.get_children():
		c.queue_free()
	_gold_label.text = "Gold: %d   " % GameState.player.gold

	for member in GameState.battle_party():
		_members_box.add_child(_member_row(member))
	if not GameState.reserve.is_empty():
		_members_box.add_child(_heading("Reserve"))
		for member in GameState.reserve:
			var def := member.get_class_def()
			_members_box.add_child(_note("%s   Lv %d   %s   (swap in from Manage party)" % [
				member.character_name, member.level, def.display_name if def else "No class"]))

	# --- Items ---
	_actions_box.add_child(_heading("Items"))
	var owned := GameState.inventory.owned()
	if owned.is_empty():
		_actions_box.add_child(_note("No items."))
	for item in owned:
		var b := Button.new()
		b.text = "%s  x%d" % [item.display_name, GameState.inventory.count(item.id)]
		b.tooltip_text = item.description
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(func():
			_pending = { "kind": "item", "id": item.id }
			_say("Use %s on who?" % item.display_name)
			_rebuild())
		_actions_box.add_child(b)

	# --- Healing spells ---
	_actions_box.add_child(_heading("Spells"))
	var any_spell := false
	for member in GameState.battle_party():
		for skill in member.all_skills():
			if skill.effect != SkillDef.Effect.HEAL:
				continue
			any_spell = true
			var b := Button.new()
			b.text = "%s: %s (%d MP)" % [member.character_name, skill.display_name, skill.mp_cost]
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.disabled = member.is_downed() or member.current_mp() < skill.mp_cost
			b.pressed.connect(func():
				match skill.targeting:
					SkillDef.Targeting.ALLY_ALL:
						var total := GameState.cast_field_heal_all(member, skill)
						_say("%s restored %d HP to the party." % [member.character_name, total] if total > 0
							else "Nobody needs healing.")
					SkillDef.Targeting.SELF:
						var healed := GameState.cast_field_heal(member, skill, member)
						_say("%s recovered %d HP." % [member.character_name, healed] if healed > 0
							else "%s doesn't need healing." % member.character_name)
					_:
						_pending = { "kind": "heal", "caster": member, "skill": skill }
						_say("%s casts %s on who?" % [member.character_name, skill.display_name])
				_rebuild())
			_actions_box.add_child(b)
	if not any_spell:
		_actions_box.add_child(_note("Nobody knows a healing spell."))

	if not _pending.is_empty():
		var cancel := Button.new()
		cancel.text = "Cancel"
		cancel.pressed.connect(func(): _pending = {}; _say(""); _rebuild())
		_actions_box.add_child(cancel)

	_actions_box.add_child(_note("\nDowned allies can't be healed. Revive them\nwith a Goddess Tear or at a campfire."))


func _member_row(member: CharacterData) -> Control:
	var panel := PanelContainer.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var def := member.get_class_def()
	var name_l := Label.new()
	name_l.text = "%s   Lv %d   %s" % [member.character_name, member.level, def.display_name if def else "No class"]
	info.add_child(name_l)
	var hp_l := Label.new()
	if member.is_downed():
		hp_l.text = "DOWNED   MP %d/%d" % [member.current_mp(), member.max_mp()]
		hp_l.modulate = Color(1, 0.45, 0.45)
	else:
		hp_l.text = "HP %d/%d   MP %d/%d" % [member.current_hp(), member.max_hp(), member.current_mp(), member.max_mp()]
	info.add_child(hp_l)

	if not _pending.is_empty():
		var use := Button.new()
		use.text = "▶ Here"
		use.pressed.connect(_apply_pending.bind(member))
		row.add_child(use)
	else:
		if member == GameState.player or member.companion_id == &"childhood_friend":
			var rename_btn := Button.new()
			rename_btn.text = "Rename"
			rename_btn.pressed.connect(_open_rename.bind(member))
			row.add_child(rename_btn)
		var stats_btn := Button.new()
		stats_btn.text = "Stats" + (" (%d)" % member.unspent_points if member.unspent_points > 0 else "")
		if member.unspent_points > 0:
			stats_btn.modulate = Color(1, 0.9, 0.4)
		stats_btn.pressed.connect(func():
			_stats_panel.bind(member)
			_stats_overlay.show())
		row.add_child(stats_btn)
		var skills_btn := Button.new()
		skills_btn.text = "Skills" + (" (%d)" % member.skill_picks if member.skill_picks > 0 else "")
		if member.skill_picks > 0:
			skills_btn.modulate = Color(1, 0.9, 0.4)
		skills_btn.pressed.connect(func(): _skills_panel.open(member))
		row.add_child(skills_btn)
		var gear_btn := Button.new()
		gear_btn.text = "Gear"
		gear_btn.pressed.connect(func(): _gear_panel.open(member))
		row.add_child(gear_btn)
		if member == GameState.player:
			for sid in GameState.unlocked_secret_classes():
				if member.class_id == sid:
					continue
				var sdef := ClassRegistry.get_class_def(sid)
				var sbtn := Button.new()
				sbtn.text = "✦ " + sdef.display_name
				sbtn.modulate = Color(1, 0.6, 0.3)
				if member.can_take_secret_class(sdef):
					sbtn.tooltip_text = "%s\nReplaces your current class." % sdef.description
					sbtn.pressed.connect(_confirm_secret_class.bind(member, sdef))
				else:
					sbtn.disabled = true
					sbtn.tooltip_text = "Needs %s (you have %d%%). A respec can help." % [
						sdef.requirement_text(), roundi(sdef.qualification_share(member.stats) * 100)]
				row.add_child(sbtn)
		if member.can_choose_class():
			var class_btn := Button.new()
			class_btn.text = "Choose class!"
			class_btn.modulate = Color(0.5, 1, 1)
			class_btn.pressed.connect(func(): _class_screen.open(member))
			row.add_child(class_btn)
	return panel


func _open_rename(member: CharacterData) -> void:
	var dlg := ConfirmationDialog.new()
	dlg.title = "Rename"
	var box := VBoxContainer.new()
	var prompt := Label.new()
	prompt.text = "Enter a new name (up to %d characters):" % CharacterData.NAME_MAX_LENGTH
	box.add_child(prompt)
	var edit := LineEdit.new()
	edit.text = member.character_name
	edit.max_length = CharacterData.NAME_MAX_LENGTH
	edit.custom_minimum_size.x = 280
	edit.select_all_on_focus = true
	box.add_child(edit)
	dlg.add_child(box)
	dlg.register_text_enter(edit)
	dlg.confirmed.connect(func():
		var old := member.character_name
		if member.rename(edit.text):
			if old != member.character_name:
				_say("%s is now called %s." % [old, member.character_name])
		else:
			_say("A name can't be blank.")
		_rebuild()
		dlg.queue_free())
	dlg.canceled.connect(dlg.queue_free)
	add_child(dlg)
	dlg.popup_centered()
	edit.grab_focus()


func _confirm_secret_class(member: CharacterData, def: ClassDef) -> void:
	var dlg := ConfirmationDialog.new()
	var current := member.get_class_def()
	dlg.title = "Secret class"
	dlg.dialog_text = "Become an %s?\n\n%s\n\nThis replaces %s and its skills.\nGear locked to your old class goes back in the bag." % [
		def.display_name, def.description, current.display_name if current else "your current class"]
	dlg.confirmed.connect(func():
		if GameState.take_secret_class(member, def.id):
			_say("%s is now an %s!" % [member.character_name, def.display_name])
		_rebuild()
		dlg.queue_free())
	dlg.canceled.connect(dlg.queue_free)
	add_child(dlg)
	dlg.popup_centered()


func _apply_pending(target: CharacterData) -> void:
	var p := _pending
	_pending = {}
	match p.get("kind"):
		"item":
			var item := ItemLibrary.get_item(p.id)
			if GameState.inventory.use_on_character(p.id, target):
				if item.is_skill_book():
					_say("%s learned %s!" % [target.character_name, SkillLibrary.get_skill(item.teaches_skill).display_name])
				else:
					_say("Used %s on %s." % [item.display_name, target.character_name])
			elif item.is_skill_book():
				_say("%s already knows that skill." % target.character_name)
			else:
				_say("It wouldn't do anything to %s." % target.character_name)
		"heal":
			var healed := GameState.cast_field_heal(p.caster, p.skill, target)
			if healed > 0:
				_say("%s restored %d HP to %s." % [p.caster.character_name, healed, target.character_name])
			else:
				_say("Can't heal %s right now." % target.character_name)
	_rebuild()


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
