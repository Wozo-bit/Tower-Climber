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
var _bestiary_panel: BestiaryPanel
var _quest_panel: QuestLogPanel
var _reputation: Label
var _advance_panel: AdvancementPanel
var _guild_panel: GuildPanel
var _divinity_panel: DivinityPanel
var _guide_panel: GuidePanel
## Tab -> Divinity: only shown for a god (New Game+ of an ascended character).
var _divinity_btn: Button

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
	panel.custom_minimum_size = Vector2(980, 600)
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
	# Route hint: how people see you (never numbers).
	_reputation = Label.new()
	_reputation.modulate = Color(0.85, 0.8, 1.0, 0.8)
	_reputation.add_theme_font_size_override("font_size", 14)
	_reputation.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_reputation)
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
	var bestiary_btn := Button.new()
	bestiary_btn.text = "Bestiary"
	bestiary_btn.tooltip_text = "Enemies you've fought and what you've learned about them."
	bestiary_btn.pressed.connect(func(): _bestiary_panel.open())
	header.add_child(bestiary_btn)
	var quests_btn := Button.new()
	quests_btn.text = "Quests"
	quests_btn.tooltip_text = "Active, completed and failed quests."
	quests_btn.pressed.connect(func(): _quest_panel.open())
	header.add_child(quests_btn)
	var guilds_btn := Button.new()
	guilds_btn.text = "Guilds"
	guilds_btn.tooltip_text = "Who runs which floors, and where you stand with them."
	guilds_btn.pressed.connect(func(): _guild_panel.open())
	header.add_child(guilds_btn)
	_divinity_btn = Button.new()
	_divinity_btn.text = "Divinity"
	_divinity_btn.tooltip_text = "Your faith, and the guilds you sponsor as a god."
	_divinity_btn.pressed.connect(func(): _divinity_panel.open())
	header.add_child(_divinity_btn)
	var guide_btn := Button.new()
	guide_btn.text = "Guide"
	guide_btn.tooltip_text = "Reread the tips you've seen."
	guide_btn.pressed.connect(func(): _guide_panel.open())
	header.add_child(guide_btn)
	var close_btn := Button.new()
	close_btn.text = "Close (Tab)"
	close_btn.pressed.connect(close)
	header.add_child(close_btn)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 20)
	root.add_child(body)
	# Scrolls: later in the climb up to 10 fight (plus the reserve list).
	var members_scroll := ScrollContainer.new()
	members_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	members_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(members_scroll)
	_members_box = VBoxContainer.new()
	_members_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_members_box.add_theme_constant_override("separation", 8)
	members_scroll.add_child(_members_box)
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
	_bestiary_panel = BestiaryPanel.new()
	add_child(_bestiary_panel)
	_quest_panel = QuestLogPanel.new()
	add_child(_quest_panel)
	_guild_panel = GuildPanel.new()
	add_child(_guild_panel)
	_divinity_panel = DivinityPanel.new()
	_divinity_panel.closed.connect(_rebuild)
	add_child(_divinity_panel)
	_guide_panel = GuidePanel.new()
	add_child(_guide_panel)
	_advance_panel = AdvancementPanel.new()
	_advance_panel.closed.connect(_rebuild)
	add_child(_advance_panel)

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
	_divinity_btn.visible = GameState.divinity.active
	_rebuild()
	show()
	Tips.check("menu")
	Tips.show_pending()


## Opens the Manage party screen on top of this menu.
func open_manage() -> void:
	_manage_panel.open()


func close() -> void:
	if _class_screen.visible or _stats_overlay.visible or _gear_panel.visible or _skills_panel.visible \
			or _manage_panel.visible or _bestiary_panel.visible or _quest_panel.visible or _advance_panel.visible or _guild_panel.visible \
			or _divinity_panel.visible or _guide_panel.visible:
		return
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _gear_panel.visible or _skills_panel.visible or _manage_panel.visible \
			or _bestiary_panel.visible or _quest_panel.visible or _advance_panel.visible or _guild_panel.visible \
			or _divinity_panel.visible or _guide_panel.visible:
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
	_reputation.text = "   " + GameState.route.reputation_text()

	for member in GameState.battle_party():
		_members_box.add_child(_member_row(member))
	if not GameState.reserve.is_empty():
		_members_box.add_child(_heading("Reserve"))
		for member in GameState.reserve:
			_members_box.add_child(_note("%s   Lv %d   %s   (swap in from Manage party)" % [
				member.character_name, member.level, member.class_title()]))

	# --- Items ---
	_actions_box.add_child(_heading("Items"))
	var owned := GameState.inventory.owned().filter(func(i): return not i.quest_item)   # see Tab -> Quests
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
	name_l.text = "%s   Lv %d   %s" % [member.full_name(), member.level, member.class_title()]
	info.add_child(name_l)
	if member.is_blessed() or member.curse_id != &"":
		var bl := Label.new()
		bl.add_theme_font_size_override("font_size", 13)
		if member.is_blessed():
			bl.text = "✦ Blessed by %s (level %d)" % [BeingLibrary.full_name(member.blessing_id), member.blessing_level]
			bl.modulate = Color(1.0, 0.9, 0.6)
			bl.tooltip_text = DialogueRunner.blessing_summary(member.blessing_id, member.blessing_level)
		else:
			bl.text = "✖ Cursed by %s (until floor %d)" % [BeingLibrary.full_name(member.curse_id), member.curse_until_floor]
			bl.modulate = Color(1.0, 0.5, 0.5)
			bl.tooltip_text = DialogueRunner.effects_text(BeingLibrary.level_effects(member.curse_id, member.curse_level).get("curse", {}))
		bl.mouse_filter = Control.MOUSE_FILTER_PASS
		info.add_child(bl)
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
		if member.advancement_open():
			var adv_btn := Button.new()
			adv_btn.text = "✦ Advance"
			adv_btn.modulate = Color(0.6, 1, 0.8)
			adv_btn.tooltip_text = "Advance to a stronger class (needs its trial)."
			adv_btn.pressed.connect(func(): _advance_panel.open(member))
			row.add_child(adv_btn)
		# The one free class change, once the tier-2 gate's floor is beaten.
		if member.class_change_open():
			var change_btn := Button.new()
			change_btn.text = "⇄ Change class"
			change_btn.modulate = Color(0.75, 0.85, 1)
			change_btn.tooltip_text = "Once per character, before advancing: give up this class, respec for free, and choose again."
			change_btn.pressed.connect(_confirm_class_change.bind(member))
			row.add_child(change_btn)
		# NG+ Ascension: shown on a top-tier line once you're in New Game+.
		if GameState.ng_plus_cycle >= 1 and def and def.tier >= ClassRegistry.ASCENSION_GATE.tier 				and member.class_id != &"ascendant" and not member.ascended:
			var asc_btn := Button.new()
			asc_btn.text = "✧ Ascend"
			asc_btn.modulate = Color(1, 0.9, 0.5)
			var why := member.ascension_refusal()
			asc_btn.disabled = why != ""
			asc_btn.tooltip_text = why if why != "" else 				"Ascend: +%d%% to every stat and the Apotheosis skill. Once per character." % roundi(ClassRegistry.ASCENSION_BONUS * 100)
			asc_btn.pressed.connect(_confirm_ascend.bind(member))
			row.add_child(asc_btn)
	return panel


func _confirm_ascend(member: CharacterData) -> void:
	var dlg := ConfirmationDialog.new()
	dlg.title = "Ascend"
	dlg.dialog_text = "%s Ascends beyond the %s?

+%d%% to every stat and the Apotheosis skill. This can't be undone." % [
		member.character_name, member.get_class_def().display_name, roundi(ClassRegistry.ASCENSION_BONUS * 100)]
	dlg.confirmed.connect(func():
		if member.ascend():
			_say("%s has Ascended!" % member.character_name)
			CutIns.play(CutInData.ascension(member))
		_rebuild()
		dlg.queue_free())
	dlg.canceled.connect(dlg.queue_free)
	add_child(dlg)
	dlg.popup_centered()


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


func _confirm_class_change(member: CharacterData) -> void:
	var dlg := ConfirmationDialog.new()
	dlg.title = "Change class"
	dlg.dialog_text = ("%s gives up the %s?

You get a free respec, then choose a class again (or an unlocked secret class)."
		+ "
Learned skills stay; class skills change. This is your only free change.") % [
		member.character_name, member.get_class_def().display_name]
	dlg.confirmed.connect(func():
		if GameState.release_class(member):
			_say("%s can choose a new class. Respec first if you like (free)." % member.character_name)
		_rebuild()
		dlg.queue_free())
	dlg.canceled.connect(dlg.queue_free)
	add_child(dlg)
	dlg.popup_centered()


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
