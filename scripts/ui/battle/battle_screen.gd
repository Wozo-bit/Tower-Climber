extends Control
## FF-style battle screen with front/back rows.
##
##   [enemy back] [enemy front]      [party front] [party back]
##
## Flow: AI turns play automatically with a short delay; on a party turn the
## command menu appears. Pick a command -> (pick a target) -> it resolves.
## Reads its party/encounter from GameState. Run this scene directly (F6) to
## get a test party and a random encounter.

const AI_TURN_DELAY := 0.7
const COLOR_DAMAGE := Color(1, 0.95, 0.9)
const COLOR_CRIT := Color(1, 0.75, 0.2)
const COLOR_HEAL := Color(0.4, 1, 0.5)
const COLOR_MISC := Color(0.7, 0.85, 1)
const COLOR_WEAK := Color(1, 0.45, 0.25)
const COLOR_RESIST := Color(0.65, 0.65, 0.75)

var battle: BattleManager
var _cards: Dictionary = {}   # Combatant -> UnitCard

# Targeting state
var _pending_skill: SkillDef
var _pending_item: ItemDef

# UI refs
var _turn_strip: HBoxContainer
var _round_label: Label
var _cols := {}               # "enemy_back", "enemy_front", "party_front", "party_back" -> VBoxContainer
var _command_box: VBoxContainer
var _skill_box: VBoxContainer
var _prompt: Label
var _log: RichTextLabel
var _result_panel: PanelContainer
var _result_label: Label
var _result_buttons: HBoxContainer
var _result_loot: VBoxContainer


func _ready() -> void:
	_build_ui()
	_start_battle()


# =========================================================
# Setup
# =========================================================

func _start_battle() -> void:
	var encounter := GameState.pending_encounter
	if encounter.is_empty():
		# Scene run on its own (F6): use the test party.
		if GameState.companions.is_empty():
			GameState.ensure_test_companions()
		encounter = EnemyLibrary.random_test_encounter()

	battle = BattleManager.new()
	battle.enemy_scale = GameState.pending_enemy_scale
	battle.inventory = GameState.inventory
	battle.loot_level = GameState.floor_number
	battle.owned_unique_classes = GameState.owned_unique_classes()
	battle.bestiary = GameState.bestiary
	battle.setup(GameState.battle_party(), encounter)
	battle.turn_started.connect(_on_turn_started)
	battle.action_resolved.connect(_on_action_resolved)
	battle.round_started.connect(func(n): _round_label.text = "Round %d" % n)
	battle.battle_ended.connect(_on_battle_ended)
	battle.intents_changed.connect(_update_intents)

	for card in _cards.values():
		card.queue_free()
	_cards.clear()
	for u in battle.party + battle.enemies:
		var card := UnitCard.new(u)
		card.clicked.connect(_on_card_clicked)
		_cards[u] = card
	_layout_cards()
	_log.clear()
	_log_line("[color=salmon]Enemies appear![/color]")
	_result_panel.hide()
	battle.start()


func _layout_cards() -> void:
	for col in _cols.values():
		for child in col.get_children():
			if child is UnitCard:
				col.remove_child(child)
	for u in _cards:
		var key := ("party_" if u.side == Combatant.Side.PARTY else "enemy_") \
			+ ("front" if u.row == Combatant.Row.FRONT else "back")
		_cols[key].add_child(_cards[u])


# =========================================================
# Turn flow
# =========================================================

func _on_turn_started(actor: Combatant) -> void:
	_refresh_all()
	_update_turn_strip()
	if actor.ai_controlled:
		_show_commands(false)
		_prompt.text = "%s's turn..." % actor.display_name
		get_tree().create_timer(AI_TURN_DELAY).timeout.connect(func():
			if battle and battle.current == actor:
				battle.advance())
	else:
		_prompt.text = "%s's turn — choose a command." % actor.display_name
		_show_commands(true)


func _on_action_resolved(result: Dictionary) -> void:
	_log_line(result.text)
	for e in result.entries:
		var card: UnitCard = _cards.get(e.target)
		if card == null:
			continue
		match e.kind:
			"damage":
				var txt: String = ("%d!" if e.crit else "%d") % e.amount
				var col := COLOR_CRIT if e.crit else COLOR_DAMAGE
				if e.get("staggered", false):
					txt = "STAGGER! " + txt
					col = COLOR_WEAK
				elif e.get("weak", false):
					txt = "WEAK " + txt
					col = COLOR_WEAK
				elif e.get("resisted", false):
					txt = "resist " + txt
					col = COLOR_RESIST
				card.popup(txt, col)
			"absorb":
				card.popup("Absorbed +%d" % e.amount, COLOR_HEAL)
			"immune":
				card.popup("Immune", COLOR_RESIST)
			"staggered":
				card.popup("Staggered", COLOR_WEAK)
			"scan":
				card.popup("Scanned", COLOR_MISC)
			"heal":
				card.popup("+%d" % e.amount, COLOR_HEAL)
			"miss":
				card.popup("Miss", COLOR_MISC)
			"status":
				card.popup(result.skill.display_name, COLOR_MISC)
	if result.type == BattleAction.Type.SWAP_ROW:
		_layout_cards()
	_refresh_all()


func _on_battle_ended(outcome: int) -> void:
	_show_commands(false)
	_refresh_all()
	for b in _result_buttons.get_children():
		b.queue_free()
	for l in _result_loot.get_children():
		l.queue_free()
	battle.write_back_party()   # HP/MP carry over to the next fight
	match outcome:
		BattleManager.Outcome.VICTORY:
			battle.apply_rewards()
			_result_label.text = "Victory!\n+%d XP each   +%d gold" % [battle.rewards.xp, battle.rewards.gold]
			var reserve_xp := GameState.grant_reserve_xp(battle.rewards.xp)
			if reserve_xp > 0:
				_result_label.text += "\nReserve: +%d XP each" % reserve_xp
			# The guild that runs this floor takes its cut.
			var tax := GameState.collect_battle_tax(battle.gold_given)
			if tax > 0:
				_result_label.text += "\nTax (%s): -%d gold" % [
					GuildLibrary.guild_name(GameState.guilds.owner_of_floor(GameState.floor_number)), tax]
			for id in battle.rewards.items:
				_result_label.text += "\nObtained: %s x%d" % [ItemLibrary.get_item(id).display_name, battle.rewards.items[id]]
			for sid in battle.rewards.books:
				var s := SkillLibrary.get_skill(sid)
				var bl := Label.new()
				bl.text = "Skill Book: %s  [%s]" % [s.display_name, SkillTier.name_of(s.tier)]
				bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				bl.add_theme_color_override("font_color", SkillTier.color_of(s.tier))
				_result_loot.add_child(bl)
			for g: GearItem in battle.rewards.gear:
				var loot := Label.new()
				loot.text = "Loot: " + g.summary()
				loot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				loot.add_theme_color_override("font_color", Rarity.color_of(g.rarity))
				_result_loot.add_child(loot)
		BattleManager.Outcome.DEFEAT:
			_result_label.text = "Defeat..."
			if GameState.return_scene == GameState.TOWER_SCENE:
				_result_label.text += "\nYou wake at floor %d, fully healed.\nLost %d%% of your gold." % [
					GameState.checkpoint_floor, roundi(GameState.DEFEAT_GOLD_PENALTY * 100)]
		BattleManager.Outcome.FLED:
			_result_label.text = "Escaped!"
	if GameState.return_scene != "":
		_add_result_button("Continue", _return)
	else:
		_add_result_button("Fight again (full heal)", _restart)
	_result_panel.show()
	_prompt.text = ""


## Standalone test mode only (scene run directly with F6).
func _restart() -> void:
	GameState.pending_encounter = []
	GameState.full_restore_party()
	_start_battle()


func _return() -> void:
	GameState.finish_battle(battle.outcome)


# =========================================================
# Player commands
# =========================================================

func _cmd_attack() -> void:
	_begin_skill(battle.current.basic_attack)


func _cmd_skills() -> void:
	for c in _skill_box.get_children():
		c.queue_free()
	var actor := battle.current
	if actor.skills.is_empty():
		var none := Label.new()
		none.text = "No skills yet —\nchoose a class at Lv 10."
		_skill_box.add_child(none)
	for s in actor.skills:
		var b := Button.new()
		b.text = "%s  (%d MP)" % [s.display_name, s.mp_cost]
		b.tooltip_text = s.description
		var els: Array[int] = DamageCalc.attack_elements(actor, s) if s.effect == SkillDef.Effect.DAMAGE else ([] as Array[int])
		if not els.is_empty():
			b.text += "  [%s]" % Element.list_text(els)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = not actor.can_afford(s) or battle.valid_targets(actor, s).is_empty()
		b.pressed.connect(_begin_skill.bind(s))
		_skill_box.add_child(b)
	_skill_box.show()


func _cmd_items() -> void:
	for c in _skill_box.get_children():
		c.queue_free()
	var owned := GameState.inventory.owned().filter(func(i): return not i.is_skill_book() and not i.quest_item)
	if owned.is_empty():
		var none := Label.new()
		none.text = "No items."
		_skill_box.add_child(none)
	for item in owned:
		var b := Button.new()
		b.text = "%s  x%d" % [item.display_name, GameState.inventory.count(item.id)]
		b.tooltip_text = item.description
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_begin_item.bind(item))
		_skill_box.add_child(b)
	_skill_box.show()


func _begin_item(item: ItemDef) -> void:
	_skill_box.hide()
	_pending_skill = null
	_pending_item = item
	var valid: Array[Combatant] = []
	if item.scan:   # Scouting Lens: look at an enemy
		valid = BattleManager.living(battle.opponents_of(battle.current))
	else:
		for u in battle.allies_of(battle.current):
			if u.is_alive() != item.is_revive():   # revive items target the downed
				valid.append(u)
	_highlight_targets(valid)
	_prompt.text = "%s: choose %s.  (Right-click or Esc to cancel)" % [item.display_name,
		"an enemy" if item.scan else "an ally"]


func _highlight_targets(valid: Array[Combatant]) -> void:
	var actor := battle.current
	for u in _cards:
		var card: UnitCard = _cards[u]
		if valid.has(u):
			card.set_highlight(UnitCard.Highlight.TARGETABLE)
		elif u == actor:
			card.set_highlight(UnitCard.Highlight.ACTIVE)
		else:
			card.set_highlight(UnitCard.Highlight.DIMMED)


func _cmd_simple(type: int) -> void:
	_cancel_targeting()
	battle.submit(BattleAction.simple(type, battle.current))


func _begin_skill(skill: SkillDef) -> void:
	_skill_box.hide()
	var actor := battle.current
	if not skill.is_single_target():
		battle.submit(BattleAction.use_skill(actor, skill))
		return
	_pending_item = null
	_pending_skill = skill
	_highlight_targets(battle.valid_targets(actor, skill))
	_prompt.text = "%s: choose a target.  (Right-click or Esc to cancel)" % skill.display_name


func _on_card_clicked(u: Combatant) -> void:
	if not battle.is_player_turn():
		return
	if _pending_item:
		var item := _pending_item
		_pending_item = null
		battle.submit(BattleAction.use_item(battle.current, item, u))
	elif _pending_skill:
		var skill := _pending_skill
		_pending_skill = null
		battle.submit(BattleAction.use_skill(battle.current, skill, u))


func _cancel_targeting() -> void:
	_pending_skill = null
	_pending_item = null
	_skill_box.hide()
	_refresh_all()
	if battle and battle.is_player_turn():
		_prompt.text = "%s's turn — choose a command." % battle.current.display_name


func _unhandled_input(event: InputEvent) -> void:
	var cancel: bool = event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton
		and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT)
	if cancel and (_pending_skill != null or _pending_item != null or _skill_box.visible):
		_cancel_targeting()


# =========================================================
# Refresh helpers
# =========================================================

## Shows each enemy's planned move on its card, and marks targeted allies.
func _update_intents() -> void:
	if battle == null:
		return
	var threats := {}   # Combatant -> [enemy names]
	for u in _cards:
		var card: UnitCard = _cards[u]
		var a := battle.intent_of(u)
		if u.side == Combatant.Side.ENEMY and u.is_alive() and u.staggered:
			card.set_intent("Staggered: loses its next turn")
			continue
		if u.side != Combatant.Side.ENEMY or a == null or not u.is_alive():
			card.set_intent("")
			continue
		if u.source_enemy and u.source_enemy.hide_intent:
			card.set_intent("Intent: ???")
			continue
		card.set_intent(_intent_text(a))
		if a.type == BattleAction.Type.SKILL and a.skill.targets_enemies():
			var hit: Array = [a.target] if a.skill.is_single_target() else battle.valid_targets(u, a.skill)
			for t in hit:
				if t:
					threats[t] = threats.get(t, 0) + 1
	for u in _cards:
		if u.side == Combatant.Side.PARTY:
			var n: int = threats.get(u, 0)
			var guard: Combatant = u.active_guardian()
			var txt := ""
			if n > 0:
				txt = "⚠ Targeted" + (" x%d" % n if n > 1 else "")
				if guard:
					txt += " (%s guards)" % guard.display_name
			_cards[u].set_threat(txt)


func _intent_text(a: BattleAction) -> String:
	match a.type:
		BattleAction.Type.DEFEND:
			return "Will defend"
		BattleAction.Type.SKILL:
			var s := a.skill
			if s.targeting == SkillDef.Targeting.ENEMY_ALL:
				return "%s → everyone" % s.display_name
			if s.targeting == SkillDef.Targeting.SELF:
				return "%s (self)" % s.display_name
			if s.targets_allies():
				return "%s → %s" % [s.display_name, a.target.display_name if a.target else "allies"]
			return "%s → %s" % [s.display_name, a.target.display_name if a.target else "?"]
	return ""


func _refresh_all() -> void:
	for u in _cards:
		var card: UnitCard = _cards[u]
		card.set_highlight(UnitCard.Highlight.ACTIVE if u == battle.current else UnitCard.Highlight.NONE)
		if u.source_enemy:
			card.set_known(GameState.bestiary.summary(u.source_enemy))
		card.refresh()
	_update_intents()


func _update_turn_strip() -> void:
	for c in _turn_strip.get_children():
		c.queue_free()
	var first := true
	for u in battle.turn_order_preview():
		var l := Label.new()
		l.text = ("▶ " if first else "") + u.display_name
		l.add_theme_color_override("font_color",
			Color(0.6, 0.85, 1) if u.side == Combatant.Side.PARTY else Color(1, 0.6, 0.55))
		if first:
			l.add_theme_font_size_override("font_size", 18)
		_turn_strip.add_child(l)
		first = false


## Commands stay on screen (so the layout doesn't jump) but are disabled
## during enemy turns.
func _show_commands(on: bool) -> void:
	_command_box.modulate.a = 1.0 if on else 0.35
	for b in _command_box.get_children():
		b.disabled = not on
	if not on:
		_skill_box.hide()
	if on:
		var flee_btn: Button = _command_box.get_node("Flee")
		flee_btn.disabled = not battle.can_flee
		flee_btn.tooltip_text = "%d%% chance" % roundi(battle.flee_chance() * 100) if battle.can_flee else "Can't flee from a boss!"
		var row_btn: Button = _command_box.get_node("Row")
		row_btn.text = "Move to %s row" % ("back" if battle.current.row == Combatant.Row.FRONT else "front")


func _log_line(text: String) -> void:
	_log.append_text(text + "\n")


# =========================================================
# UI construction (all in code so it's easy to restyle later)
# =========================================================

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.07, 0.1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	# --- Top: round + turn order ---
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	root.add_child(top)
	_round_label = Label.new()
	_round_label.add_theme_font_size_override("font_size", 18)
	top.add_child(_round_label)
	var order_title := Label.new()
	order_title.text = "  Turn order:"
	order_title.modulate = Color(1, 1, 1, 0.6)
	top.add_child(order_title)
	_turn_strip = HBoxContainer.new()
	_turn_strip.add_theme_constant_override("separation", 14)
	top.add_child(_turn_strip)

	# --- Middle: battlefield ---
	# Scrolls (rarely) instead of growing, so the commands below always stay on screen.
	var field_scroll := ScrollContainer.new()
	field_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	field_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(field_scroll)
	var field := HBoxContainer.new()
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.size_flags_vertical = Control.SIZE_EXPAND_FILL
	field.add_theme_constant_override("separation", 18)
	field_scroll.add_child(field)
	for key in ["enemy_back", "enemy_front"]:
		field.add_child(_make_column(key))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.add_child(spacer)
	for key in ["party_front", "party_back"]:
		field.add_child(_make_column(key))

	# --- Prompt ---
	_prompt = Label.new()
	_prompt.add_theme_font_size_override("font_size", 18)
	root.add_child(_prompt)

	# --- Bottom: commands | skills | log ---
	var bottom := HBoxContainer.new()
	bottom.custom_minimum_size.y = 210
	bottom.add_theme_constant_override("separation", 16)
	root.add_child(bottom)

	_command_box = VBoxContainer.new()
	_command_box.custom_minimum_size.x = 170
	bottom.add_child(_command_box)
	_add_command("Attack", _cmd_attack)
	_add_command("Skills", _cmd_skills)
	_add_command("Items", _cmd_items)
	_add_command("Defend", _cmd_simple.bind(BattleAction.Type.DEFEND))
	_add_command("Row", _cmd_simple.bind(BattleAction.Type.SWAP_ROW))
	_add_command("Flee", _cmd_simple.bind(BattleAction.Type.FLEE))

	_skill_box = VBoxContainer.new()
	_skill_box.custom_minimum_size.x = 210
	_skill_box.hide()
	bottom.add_child(_skill_box)

	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(_log)

	# --- Result overlay ---
	_result_panel = PanelContainer.new()
	_result_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_result_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_result_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_result_panel.custom_minimum_size = Vector2(380, 170)
	UIStyle.apply(_result_panel)
	_result_panel.hide()
	add_child(_result_panel)
	var rbox := VBoxContainer.new()
	rbox.alignment = BoxContainer.ALIGNMENT_CENTER
	rbox.add_theme_constant_override("separation", 16)
	_result_panel.add_child(rbox)
	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 26)
	rbox.add_child(_result_label)
	_result_loot = VBoxContainer.new()
	rbox.add_child(_result_loot)
	_result_buttons = HBoxContainer.new()
	_result_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	rbox.add_child(_result_buttons)


func _make_column(key: String) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 6)
	var header := Label.new()
	header.text = key.split("_")[1].capitalize() + " row"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.modulate = Color(1, 1, 1, 0.4)
	col.add_child(header)
	_cols[key] = col
	return col


func _add_command(label: String, callback: Callable) -> void:
	var b := Button.new()
	b.name = label
	b.text = label
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(func():
		if battle.is_player_turn():
			callback.call())
	_command_box.add_child(b)


func _add_result_button(label: String, callback: Callable) -> void:
	var b := Button.new()
	b.text = label
	b.pressed.connect(callback)
	_result_buttons.add_child(b)
