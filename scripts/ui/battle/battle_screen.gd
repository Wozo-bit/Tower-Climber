extends Control
## FF-style battle screen (Hayden 2026-10-25): a flat battlefield on top,
## four rows a side, and a menu window along the bottom.
##
##   [round · turn order ......................................]
##   [Back][Rear][Middle][Front]        [Front][Middle][Rear][Back]
##   [ commands | skills / items / rows, or the log | party status ]
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
## The characters in this fight (party + a guest captain), for Ironman deaths.
var _fighters: Array = []
var _cards: Dictionary = {}   # Combatant -> UnitCard

# Targeting state
var _pending_skill: SkillDef
var _pending_item: ItemDef

# UI refs
var _turn_strip: HBoxContainer
var _round_label: Label
var _cols := {}               # "enemy_0".."enemy_3", "party_0".."party_3" (Combatant.Row) -> GridContainer
## The battlefield and the space it has (it's scaled down to fit, never scrolled).
var _field: HBoxContainer
var _field_area: Control
## Units stacked in one lane before it wraps into another column.
const CARDS_PER_COLUMN := 4
## Party status list: one column up to this many members, then two.
const STATUS_ONE_COLUMN_MAX := 5
var _command_box: VBoxContainer
var _skill_box: VBoxContainer
## The menu window's middle pane shows the skill/item/row list, or the log.
var _sub_pane: Control
var _status_grid: GridContainer
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
	GameState.configure_battle(battle)
	var fighters := GameState.fighting_party()
	_fighters = fighters.duplicate()
	battle.setup(fighters, encounter)
	battle.turn_started.connect(_on_turn_started)
	battle.action_resolved.connect(_on_action_resolved)
	battle.round_started.connect(func(n): _round_label.text = "Round %d" % n)
	battle.battle_ended.connect(_on_battle_ended)
	battle.intents_changed.connect(_update_intents)
	battle.unit_joined.connect(_on_unit_joined)

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
	for c in fighters:
		if GameState.guilds.is_captain(c):
			_log_line("[color=#%s]Captain %s joins the fight on their floors![/color]" % [UITheme.hex("accent"), c.character_name])
	_result_panel.hide()
	var info := GameState.pending_battle_info
	var kind: String = info.get("kind", "normal")
	var ids := encounter.map(func(d): return d.id)
	Audio.play_music(MusicLibrary.for_battle(kind, ids, GameState.floor_number, info))
	Audio.play_sfx(["encounter_%s" % kind, "encounter"])
	# Bosses, minibosses, roamers and champions get a name card first.
	if CutInData.is_big_fight(kind):
		CutIns.play(CutInData.boss(kind, encounter, GameState.floor_number, info))
	await _cutins_done()
	battle.start()


## Waits for any cut-in on screen to finish (returns at once if none).
func _cutins_done() -> void:
	if CutIns.is_playing():
		await CutIns.finished


## A summon arrived: give it a card on its side.
func _on_unit_joined(u: Combatant) -> void:
	var card := UnitCard.new(u)
	card.clicked.connect(_on_card_clicked)
	_cards[u] = card
	_layout_cards()


func _layout_cards() -> void:
	for col in _cols.values():
		for child in col.get_children():
			if child is UnitCard:
				col.remove_child(child)
	for u in _cards:
		var key := ("party_" if u.side == Combatant.Side.PARTY else "enemy_") + str(u.row)
		_cols[key].add_child(_cards[u])
	# A crowded row wraps into more columns (CARDS_PER_COLUMN tall at most)...
	for grid: GridContainer in _cols.values():
		grid.columns = maxi(1, ceili(grid.get_child_count() / float(CARDS_PER_COLUMN)))
	# ...and if the whole field still doesn't fit, it shrinks to fit. No scrolling.
	_fit_field.call_deferred()


## Scales the battlefield down (never up) so every unit is on screen.
func _fit_field() -> void:
	if _field == null or _field_area == null:
		return
	_field.scale = Vector2.ONE
	_field.reset_size()
	var need := _field.get_combined_minimum_size()
	var room := _field_area.size
	if need.x <= 0 or need.y <= 0 or room.x <= 0 or room.y <= 0:
		return
	var s := minf(1.0, minf(room.x / need.x, room.y / need.y))
	_field.size = Vector2(maxf(need.x, room.x / s), need.y)
	_field.scale = Vector2(s, s)
	_field.position = Vector2(0, (room.y - need.y * s) / 2.0)


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
			await _cutins_done()   # an ultimate skill's splash finishes first
			if battle and battle.current == actor:
				battle.advance())
	else:
		_prompt.text = "%s's turn — choose a command." % actor.display_name
		_show_commands(true)


func _on_action_resolved(result: Dictionary) -> void:
	_log_line(result.text)
	var actor: Combatant = result.get("actor")
	if result.type == BattleAction.Type.SKILL and actor and actor.side == Combatant.Side.PARTY \
			and CutInData.is_ultimate(result.skill):
		CutIns.play(CutInData.skill(actor, result.skill))
	_play_action_sfx(result)
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
	Audio.play_sfx({ BattleManager.Outcome.VICTORY: "victory", BattleManager.Outcome.DEFEAT: "defeat",
		BattleManager.Outcome.FLED: "flee" }.get(outcome, ""), 0.0)
	match outcome:
		BattleManager.Outcome.VICTORY:
			var fought: Array = battle.party.map(func(u): return u.source_character)
			var members: Array = GameState.battle_party() + GameState.reserve
			for c in GameState.guilds.captains.values():
				if not members.has(c):
					members.append(c)
			var levels_before := members.map(func(m): return m.level)
			battle.apply_rewards()
			_result_label.text = "Victory!\n+%d XP each   +%d gold" % [battle.rewards.xp, battle.rewards.gold]
			var reserve_xp := GameState.grant_reserve_xp(battle.rewards.xp, fought)
			_announce_level_ups(members, levels_before)
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
					GameState.checkpoint_floor, roundi(Difficulty.value(GameState.difficulty, "wipe_gold") * 100)]
		BattleManager.Outcome.FLED:
			_result_label.text = "Escaped!"
	_announce_ironman_deaths(outcome)
	if GameState.return_scene != "":
		_add_result_button("Continue", _return)
	else:
		_add_result_button("Fight again (full heal)", _restart)
	_result_panel.show()
	_prompt.text = ""


## LEVEL UP splash (and sound) for everyone who levelled in this fight.
func _announce_level_ups(members: Array, levels_before: Array) -> void:
	var ups := []
	var class_ready := false
	for i in members.size():
		var m: CharacterData = members[i]
		if m.level > levels_before[i]:
			ups.append([m.character_name, m.level])
			class_ready = class_ready or m.can_choose_class()
	if ups.is_empty():
		return
	Audio.play_sfx("level_up", 0.0)
	CutIns.play(CutInData.level_up(ups, class_ready))


## One sound per action (BattleSfx picks it).
func _play_action_sfx(result: Dictionary) -> void:
	Audio.play_sfx(BattleSfx.names(result))


## Standalone test mode only (scene run directly with F6).
func _restart() -> void:
	GameState.pending_encounter = []
	GameState.full_restore_party()
	_start_battle()


func _return() -> void:
	GameState.finish_battle(battle.outcome, _fighters)


## Ironman: whoever is still down when the fight ends is gone for good.
func _announce_ironman_deaths(outcome: int) -> void:
	var dead := GameState.ironman_deaths(_fighters, outcome)
	if dead.is_empty():
		return
	if dead.has(GameState.player):
		_result_label.text = "You have fallen.\nThe climb ends here. (Ironman)"
		return
	for c in dead:
		var l := Label.new()
		l.text = "☠ %s has fallen. (Ironman)" % c.character_name
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
		_result_loot.add_child(l)


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
		b.text = "%s  (%s)" % [s.display_name, "%d faith of %d" % [s.faith_cost, actor.faith_box.get("faith", 0)]
			if s.faith_cost > 0 else "%d MP" % s.mp_cost]
		b.tooltip_text = s.description
		var els: Array[int] = DamageCalc.attack_elements(actor, s) if s.effect == SkillDef.Effect.DAMAGE else ([] as Array[int])
		if not els.is_empty():
			b.text += "  [%s]" % Element.list_text(els)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_set_icon(b, Assets.texture("skills", s.id))
		b.disabled = not actor.can_afford(s) or battle.valid_targets(actor, s).is_empty()
		b.pressed.connect(_begin_skill.bind(s))
		_skill_box.add_child(b)
	_open_submenu()


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
		_set_icon(b, Assets.texture("items", item.id))
		b.pressed.connect(_begin_item.bind(item))
		_skill_box.add_child(b)
	_open_submenu()


func _begin_item(item: ItemDef) -> void:
	_close_submenu()
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
	_refresh_status()   # party rows in the menu window are clickable targets too


func _cmd_simple(type: int) -> void:
	_cancel_targeting()
	battle.submit(BattleAction.simple(type, battle.current))


func _begin_skill(skill: SkillDef) -> void:
	_close_submenu()
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
	_close_submenu()
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
	_refresh_status()
	_fit_field.call_deferred()   # cards grow and shrink with intents / statuses


## The turn order shows this many upcoming units, then "+N".
const TURN_STRIP_MAX := 8


func _update_turn_strip() -> void:
	for c in _turn_strip.get_children():
		c.queue_free()
	var first := true
	var order := battle.turn_order_preview()
	for u in order.slice(0, TURN_STRIP_MAX):
		var l := Label.new()
		l.text = ("▶ " if first else "") + u.display_name
		l.add_theme_color_override("font_color",
			Color(0.6, 0.85, 1) if u.side == Combatant.Side.PARTY else Color(1, 0.6, 0.55))
		if first:
			l.add_theme_font_size_override("font_size", 18)
		_turn_strip.add_child(l)
		first = false
	if order.size() > TURN_STRIP_MAX:
		var more := Label.new()
		more.text = "+%d" % (order.size() - TURN_STRIP_MAX)
		more.modulate = Color(1, 1, 1, 0.5)
		_turn_strip.add_child(more)


## Commands stay on screen (so the layout doesn't jump) but are disabled
## during enemy turns.
func _show_commands(on: bool) -> void:
	_command_box.modulate.a = 1.0 if on else 0.35
	for b in _command_box.get_children():
		b.disabled = not on
	if not on:
		_close_submenu()
	if on:
		var flee_btn: Button = _command_box.get_node("Flee")
		flee_btn.disabled = not battle.can_flee
		flee_btn.tooltip_text = "%d%% chance" % roundi(battle.flee_chance() * 100) if battle.can_flee else "Can't flee from a boss!"
		var row_btn: Button = _command_box.get_node("Row")
		row_btn.text = "Row (%s)" % battle.current.row_name()


## The submenu (skills, items, rows) takes the log's place in the menu window.
func _open_submenu() -> void:
	_skill_box.show()
	_log.hide()


func _close_submenu() -> void:
	_skill_box.hide()
	_log.show()


## Row command: pick any of the four rows (the class's recommended one starred).
func _cmd_row() -> void:
	for c in _skill_box.get_children():
		c.queue_free()
	var actor := battle.current
	var rec := SkillLibrary.default_row_for_class(actor.source_character.class_id) if actor.source_character else -1
	for r in Combatant.ROW_NAMES.size():
		var b := Button.new()
		b.text = "%s row%s%s" % [Combatant.ROW_NAMES[r], "  ★" if r == rec else "", "  (here)" if r == actor.row else ""]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = r == actor.row
		b.tooltip_text = "Melee only reaches the nearest row with someone standing. Melee from this row hits for %d%%." % \
			roundi(DamageCalc.MELEE_ROW_MULT[r] * 100)
		b.pressed.connect(func():
			_cancel_targeting()
			battle.submit(BattleAction.move_row(actor, r)))
		_skill_box.add_child(b)
	_open_submenu()


## The party's HP / MP / row in the menu window. A row is clickable when that
## member is a valid target (heals, items, guard...).
func _refresh_status() -> void:
	if _status_grid == null or battle == null:
		return
	for c in _status_grid.get_children():
		_status_grid.remove_child(c)
		c.queue_free()
	_status_grid.columns = 1 if battle.party.size() <= STATUS_ONE_COLUMN_MAX else 2
	for u in battle.party:
		_status_grid.add_child(_status_row(u))


func _status_row(u: Combatant) -> Control:
	# A plain panel (not a Button) so the cells give the row its real width.
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var card: UnitCard = _cards.get(u)
	var targetable := card != null and card._highlight == UnitCard.Highlight.TARGETABLE
	if targetable:
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		panel.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				_on_card_clicked(u))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	var col := Color(1, 1, 1)
	if u == battle.current:
		col = UnitCard.COLOR_ACTIVE
	elif targetable:
		col = UnitCard.COLOR_TARGET
	elif not u.is_alive():
		col = Color(1, 0.45, 0.45)
	# Two columns (6+ members) use the compact layout.
	var compact := _status_grid.columns > 1
	var cells := [
		[("▶ " if u == battle.current else "") + u.display_name, 100 if compact else 140],
		["DOWN" if not u.is_alive() else ("%d/%d" if compact else "HP %d/%d") % [u.hp, u.max_hp], 70 if compact else 110],
		[("%d/%d" if compact else "MP %d/%d") % [u.mp, u.max_mp], 54 if compact else 84],
		[u.row_name(), 52],
	]
	for cell in cells:
		var l := Label.new()
		l.text = cell[0]
		l.custom_minimum_size.x = cell[1]
		l.clip_text = true
		l.add_theme_font_size_override("font_size", 13 if compact else 15)
		l.add_theme_color_override("font_color", col)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(l)
	var hp := ProgressBar.new()
	hp.show_percentage = false
	hp.custom_minimum_size = Vector2(30, 6)
	hp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hp.max_value = maxi(u.max_hp, 1)
	hp.value = u.hp
	hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.3, 0.8, 0.45) if u.hp > u.max_hp * 0.35 else Color(0.9, 0.5, 0.2)
	hp.add_theme_stylebox_override("fill", fill)
	row.add_child(hp)
	return panel


func _log_line(text: String) -> void:
	_log.append_text(text + "\n")


# =========================================================
# UI construction (all in code so it's easy to restyle later)
# =========================================================

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ThemedBackground.new())
	# Art hook: the stage's battle backdrop, darkened so the cards stay readable.
	var theme_id := StageLibrary.theme_id_for_floor(GameState.floor_number)
	var backdrop := Assets.first([["backgrounds", theme_id], ["backgrounds", "battle"]])
	if backdrop:
		var art := TextureRect.new()
		art.texture = backdrop
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.modulate = Color(0.55, 0.55, 0.6)
		add_child(art)

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
	# Clipped, so a long turn order (up to 10 a side) never widens the screen.
	var strip_clip := Control.new()
	strip_clip.clip_contents = true
	strip_clip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip_clip.custom_minimum_size.y = 26
	top.add_child(strip_clip)
	_turn_strip = HBoxContainer.new()
	_turn_strip.add_theme_constant_override("separation", 14)
	strip_clip.add_child(_turn_strip)

	# --- Battlefield: four lanes a side, enemies on the left facing the party ---
	# Never scrolls: crowded rows wrap, and the field shrinks to fit if it
	# must (_fit_field), so every unit AND the menu below stay on screen.
	_field_area = Control.new()
	_field_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_field_area.clip_contents = true
	_field_area.resized.connect(func(): _fit_field.call_deferred())
	root.add_child(_field_area)
	var field := HBoxContainer.new()
	field.add_theme_constant_override("separation", 18)
	field.alignment = BoxContainer.ALIGNMENT_CENTER
	_field_area.add_child(field)
	_field = field
	for r in [Combatant.Row.BACK, Combatant.Row.REAR, Combatant.Row.MIDDLE, Combatant.Row.FRONT]:
		field.add_child(_make_column("enemy", r))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.custom_minimum_size.x = 24
	field.add_child(spacer)
	for r in [Combatant.Row.FRONT, Combatant.Row.MIDDLE, Combatant.Row.REAR, Combatant.Row.BACK]:
		field.add_child(_make_column("party", r))

	# --- Prompt ---
	_prompt = Label.new()
	_prompt.add_theme_font_size_override("font_size", 18)
	root.add_child(_prompt)

	# --- The menu window: commands | submenu or log | party status ---
	var window := PanelContainer.new()
	window.custom_minimum_size.y = 196
	UIStyle.apply(window)
	root.add_child(window)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 14)
	window.add_child(bottom)

	_command_box = VBoxContainer.new()
	_command_box.custom_minimum_size.x = 150
	_command_box.add_theme_constant_override("separation", 2)
	bottom.add_child(_command_box)
	_add_command("Attack", _cmd_attack)
	_add_command("Skills", _cmd_skills)
	_add_command("Items", _cmd_items)
	_add_command("Defend", _cmd_simple.bind(BattleAction.Type.DEFEND))
	_add_command("Row", _cmd_row)
	_add_command("Flee", _cmd_simple.bind(BattleAction.Type.FLEE))
	bottom.add_child(VSeparator.new())

	_sub_pane = Control.new()
	_sub_pane.custom_minimum_size.x = 330
	_sub_pane.clip_contents = true
	bottom.add_child(_sub_pane)
	var sub_scroll := ScrollContainer.new()
	sub_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sub_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_sub_pane.add_child(sub_scroll)
	_skill_box = VBoxContainer.new()
	_skill_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_skill_box.hide()
	sub_scroll.add_child(_skill_box)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sub_pane.add_child(_log)
	bottom.add_child(VSeparator.new())

	_status_grid = GridContainer.new()
	_status_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_grid.add_theme_constant_override("h_separation", 18)
	_status_grid.add_theme_constant_override("v_separation", 0)
	bottom.add_child(_status_grid)

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


func _make_column(side: String, r: int) -> VBoxContainer:
	var key := "%s_%d" % [side, r]
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 6)
	col.custom_minimum_size.x = 48   # an empty lane still shows where it is
	var header := Label.new()
	header.text = Combatant.ROW_NAMES[r]
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 12)
	header.modulate = Color(1, 1, 1, 0.4)
	col.add_child(header)
	var grid := GridContainer.new()   # cards go here; extra columns when crowded
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	col.add_child(grid)
	_cols[key] = grid
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


## Menu icon (art hook): only when the file exists, kept small.
static func _set_icon(b: Button, tex: Texture2D) -> void:
	if tex:
		b.icon = tex
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 22)


func _add_result_button(label: String, callback: Callable) -> void:
	var b := Button.new()
	b.text = label
	b.pressed.connect(callback)
	_result_buttons.add_child(b)
