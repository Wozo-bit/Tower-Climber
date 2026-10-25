extends Node2D
## One tower floor. Grid movement, wandering enemies that chase when you're
## close, and Pokémon-style contact: touch an enemy and a battle starts.
## Stairs take you up. Every 5th floor is a rest floor (campfire + merchant).
##
## Controls: WASD / arrows to move, Tab (or I) for the party menu.
## Walk into the campfire, the merchant or an NPC / lore object to use them.

const TILE := 36
const PLAYER_STEP_TIME := 0.13
const ENEMY_STEP_TIME := 0.2
const ENEMY_THINK_MIN := 0.45
const ENEMY_THINK_MAX := 0.9
const CHASE_RANGE := 5
## Roaming bosses are faster and notice you from further away.
const ROAMER_CHASE_RANGE := 8
const ROAMER_THINK_MIN := 0.3
const ROAMER_THINK_MAX := 0.55
const C_BOSS_RING := Color(1.0, 0.25, 0.2)
const C_MINIBOSS_RING := Color(1.0, 0.8, 0.2)
const C_ROAMER_RING := Color(0.8, 0.4, 1.0)
const C_GUARD_RING := Color(0.4, 0.7, 1.0)
const C_CHAMPION_RING := Color(1.0, 1.0, 1.0)
const C_RESCUE_RING := Color(0.4, 1.0, 0.5)
const FLEE_STUN_TIME := 2.5
const POST_BATTLE_GRACE := 1.2
## After a conversation, holding the move key won't start it again straight away.
const TALK_COOLDOWN := 0.35

const C_FLOOR := Color(0.16, 0.16, 0.2)
const C_FLOOR_ALT := Color(0.18, 0.18, 0.22)
const C_WALL := Color(0.3, 0.29, 0.36)
const C_WALL_EDGE := Color(0.42, 0.4, 0.5)
const C_STAIRS := Color(0.95, 0.8, 0.3)
const C_PLAYER := Color(0.45, 0.75, 1.0)
const C_CAMPFIRE := Color(1.0, 0.55, 0.2)
const C_MERCHANT := Color(0.7, 0.45, 0.9)
const C_NPC_OUTLINE := Color(0.95, 0.95, 0.85)
const C_BOARD := Color(0.5, 0.35, 0.2)

var layout: FloorLayout
var origin := Vector2.ZERO

# Player
var player_tile := Vector2i.ZERO
var _player_from := Vector2.ZERO
var _player_to := Vector2.ZERO
var _player_t := 1.0
var _invulnerable := 0.0

# Enemies: parallel to GameState.floor_enemies
# { "tile": Vector2i, "from": Vector2, "to": Vector2, "t": float, "think": float, "stun": float }
var _enemy_view: Array = []

var _busy := false            # starting a battle / changing floor
var _rng := RandomNumberGenerator.new()

# UI
var _hud: CanvasLayer
var _floor_label: Label
var _party_strip: HBoxContainer
var _toast: Label
## The main toast sits in a system window; system notices stack under it.
var _toast_panel: PanelContainer
var _notices: SystemNotice
## Art hooks for the map (null = draw the placeholder shape).
var _art: Dictionary = {}
var _party_menu: PartyMenu
var _shop: ShopPanel
var _flash: ColorRect
var _pause: PauseMenu
var _dialogue: DialogueBox
var _talk_cooldown := 0.0
var _climb_prompt: ConfirmationDialog
var _board_panel: NoticeBoardPanel
## Pinned quest's current step (top right).
var _tracker: Label
## Does the board have jobs you haven't taken? (Shows "!" on it.)
var _board_has_new := false
var _completion_open := false


func _ready() -> void:
	_rng.randomize()
	_build_hud()
	_load_floor()
	_handle_battle_return()
	if GameState.pending_completion:
		_show_completion()
	else:
		_autosave()


# =========================================================
# Floor setup
# =========================================================

func _load_floor() -> void:
	layout = GameState.current_layout()
	var vp := get_viewport_rect().size
	var map_px := Vector2(FloorLayout.WIDTH, FloorLayout.HEIGHT) * TILE
	origin = ((vp - map_px) / 2.0).floor() + Vector2(0, 14)

	player_tile = GameState.floor_player_pos
	if player_tile.x < 0 or layout.is_blocked(player_tile):
		player_tile = layout.start
	_player_from = _tile_px(player_tile)
	_player_to = _player_from
	_player_t = 1.0

	_enemy_view.clear()
	for e in GameState.floor_enemies:
		var px := _tile_px(e.pos)
		_enemy_view.append({ "tile": e.pos, "from": px, "to": px, "t": 1.0,
			"think": _rng.randf_range(ENEMY_THINK_MIN, ENEMY_THINK_MAX) + 0.6, "stun": 0.0 })

	_load_art()
	Audio.play_music(MusicLibrary.for_floor(GameState.floor_number, layout.is_rest))
	_update_hud()
	queue_redraw()


## Map art for this floor (tiles follow the stage theme). Missing files stay null.
func _load_art() -> void:
	var theme := StageLibrary.theme_id_for_floor(GameState.floor_number)
	_art = {
		"floor": Assets.first([["tiles", "%s_floor" % theme], ["tiles", "floor"]]),
		"wall": Assets.first([["tiles", "%s_wall" % theme], ["tiles", "wall"]]),
		"stairs": Assets.texture("props", "stairs"),
		"campfire": Assets.texture("props", "campfire"),
		"merchant": Assets.texture("props", "merchant"),
		"board": Assets.texture("props", "board"),
		"player": Assets.texture("tokens", "player"),
	}


func _handle_battle_return() -> void:
	var outcome := GameState.last_battle_outcome
	GameState.last_battle_outcome = -1
	match outcome:
		BattleManager.Outcome.VICTORY:
			_invulnerable = POST_BATTLE_GRACE
			_show_toast("Victory!")
			if _alive_enemy_count() == 0 and not layout.is_boss_floor:
				_show_toast("Floor cleared! The stairs are waiting.")
			if StageLibrary.is_miniboss_floor(GameState.floor_number) and not GameState.stairs_locked():
				_show_toast("Miniboss defeated! The stairs are open. (Tab to check your loot)")
			if layout.is_boss_floor and not GameState.stairs_locked():
				_show_toast("The boss falls! A campfire flickers to life. (Checkpoint saved)")
			if GameState.pending_unlock_message != "":
				_show_toast(GameState.pending_unlock_message)
				GameState.pending_unlock_message = ""
		BattleManager.Outcome.FLED:
			_invulnerable = POST_BATTLE_GRACE + 0.5
			var idx := GameState.active_enemy_index
			if idx >= 0 and idx < _enemy_view.size():
				_enemy_view[idx].stun = FLEE_STUN_TIME
			GameState.active_enemy_index = -1
			_show_toast("You got away!")
		BattleManager.Outcome.DEFEAT:
			_show_toast("You wake up on floor %d..." % GameState.floor_number)
		_:
			_show_toast(_floor_intro_text())


# =========================================================
# Per-frame
# =========================================================

func _process(delta: float) -> void:
	if _busy:
		return
	_invulnerable = maxf(0.0, _invulnerable - delta)
	if not _dialogue.visible:
		_talk_cooldown = maxf(0.0, _talk_cooldown - delta)

	if not GameState.quests.messages.is_empty() or not GameState.route.messages.is_empty() \
			or not GameState.blessings.messages.is_empty() or not GameState.guilds.messages.is_empty():
		_show_quest_messages()
	# A companion wants a word about your route (warning, or leaving).
	if not GameState.pending_talks.is_empty() and not _menus_open() and _player_t >= 1.0:
		var talk_req: Dictionary = GameState.pending_talks.pop_front()
		_talk_cooldown = 0.0
		talk(talk_req.dialogue, talk_req.get("companion"), talk_req.get("being", &""))

	if not _menus_open():
		_update_player(delta)
		_update_enemies(delta)
	queue_redraw()


func _menus_open() -> bool:
	return _party_menu.visible or _shop.visible or _pause.visible or _dialogue.visible \
		or _climb_prompt.visible or _board_panel.visible or _completion_open


## Saves only during a real run (never in the dev sandbox).
func _autosave() -> void:
	if GameState.run_active:
		GameState.save_game()


func _unhandled_input(event: InputEvent) -> void:
	if _busy or _menus_open():
		return
	if event.is_action_pressed("party_menu"):
		get_viewport().set_input_as_handled()
		_party_menu.open()
	elif event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_pause.open()


func _update_player(delta: float) -> void:
	if _player_t < 1.0:
		_player_t = minf(1.0, _player_t + delta / PLAYER_STEP_TIME)
		if _player_t >= 1.0:
			_on_player_arrived()
		return

	var dir := Vector2i.ZERO
	if Input.is_action_pressed("move_up"):
		dir = Vector2i.UP
	elif Input.is_action_pressed("move_down"):
		dir = Vector2i.DOWN
	elif Input.is_action_pressed("move_left"):
		dir = Vector2i.LEFT
	elif Input.is_action_pressed("move_right"):
		dir = Vector2i.RIGHT
	if dir != Vector2i.ZERO:
		try_move(dir)


## Attempts one step. Bumping the campfire, merchant or an NPC uses them.
## Public so tests/automation can drive the player.
func try_move(dir: Vector2i) -> bool:
	if _player_t < 1.0 or _busy:
		return false
	var target := player_tile + dir
	if target == layout.campfire:
		_use_campfire()
		return false
	if target == layout.merchant:
		talk(&"merchant")
		return false
	if target == layout.board:
		_board_panel.open()
		return false
	if layout.npcs.has(target):
		var waiting := GameState.waiting_companion(layout.npcs[target])
		var being := GameState.shrine_being(layout.npcs[target])
		var guild := GameState.agent_guild(layout.npcs[target])
		if waiting:
			talk(&"waiting_companion", waiting)
		elif being != &"":
			talk(&"blessing_offer", null, being)
		elif guild != &"":
			talk(&"guild_agent", null, &"", guild)
		else:
			var npc_id: StringName = layout.npcs[target]
			talk(NpcLibrary.get_npc(npc_id).dialogue, null, &"", &"", npc_id if NpcLibrary.is_recruitable(npc_id) else &"")
		return false
	if target == layout.stairs and GameState.stairs_locked():
		_show_toast("The stairs are guarded. Defeat the %s to go up!" %
			("boss" if layout.is_boss_floor else "miniboss"))
		return false
	if layout.is_blocked(target):
		return false
	_player_from = _tile_px(player_tile)
	player_tile = target
	_player_to = _tile_px(target)
	_player_t = 0.0
	GameState.floor_player_pos = player_tile
	return true


func _on_player_arrived() -> void:
	if player_tile == layout.stairs:
		if _guardian_ahead() != "":
			_ask_before_climbing()
		else:
			_go_upstairs()
		return
	_check_contact()


func _update_enemies(delta: float) -> void:
	for i in _enemy_view.size():
		var data: Dictionary = GameState.floor_enemies[i]
		if not data.alive:
			continue
		var v: Dictionary = _enemy_view[i]
		if v.stun > 0.0:
			v.stun -= delta
			continue
		var kind := GameState.enemy_kind(data)
		if kind == "miniboss" or kind == "boss" or kind == "champion" or kind == "rescue":
			continue   # guardians and champions hold their post; a rescue is a fight in place
		if v.t < 1.0:
			v.t = minf(1.0, v.t + delta / ENEMY_STEP_TIME)
			if v.t >= 1.0:
				_check_contact()
			continue
		v.think -= delta
		if v.think > 0.0:
			continue
		if kind == "roaming":
			v.think = _rng.randf_range(ROAMER_THINK_MIN, ROAMER_THINK_MAX)
		else:
			v.think = _rng.randf_range(ENEMY_THINK_MIN, ENEMY_THINK_MAX)
		var step := _enemy_choose_step(i)
		if step != Vector2i.ZERO:
			var target: Vector2i = v.tile + step
			v.from = _tile_px(v.tile)
			v.tile = target
			v.to = _tile_px(target)
			v.t = 0.0
			data.pos = target


func _enemy_choose_step(i: int) -> Vector2i:
	var v: Dictionary = _enemy_view[i]
	var tile: Vector2i = v.tile
	var to_player := player_tile - tile
	var dirs: Array[Vector2i] = []
	var chase := ROAMER_CHASE_RANGE if GameState.enemy_kind(GameState.floor_enemies[i]) == "roaming" else CHASE_RANGE
	if absi(to_player.x) + absi(to_player.y) <= chase and _invulnerable <= 0.0:
		# Chase: prefer the axis with the bigger gap.
		var sx := Vector2i(signi(to_player.x), 0)
		var sy := Vector2i(0, signi(to_player.y))
		if absi(to_player.x) >= absi(to_player.y):
			dirs = [sx, sy]
		else:
			dirs = [sy, sx]
	else:
		if _rng.randf() < 0.35:
			return Vector2i.ZERO  # idle
		dirs = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		dirs.shuffle()
	for d in dirs:
		if d != Vector2i.ZERO and _enemy_can_enter(tile + d, i):
			return d
	return Vector2i.ZERO


func _enemy_can_enter(p: Vector2i, self_index: int) -> bool:
	if layout.is_blocked(p) or p == layout.stairs:
		return false
	for j in _enemy_view.size():
		if j != self_index and GameState.floor_enemies[j].alive and _enemy_view[j].tile == p:
			return false
	return true


func _check_contact() -> void:
	if _busy or _invulnerable > 0.0:
		return
	for i in _enemy_view.size():
		if GameState.floor_enemies[i].alive and _enemy_view[i].tile == player_tile \
				and _enemy_view[i].stun <= 0.0:
			_start_battle(i)
			return


# =========================================================
# Events
# =========================================================

func _start_battle(index: int) -> void:
	_busy = true
	Audio.play_sfx("encounter_flash")
	GameState.floor_player_pos = player_tile
	_flash.show()
	var tw := create_tween()
	tw.tween_property(_flash, "modulate:a", 1.0, 0.25).from(0.0)
	tw.tween_callback(func(): GameState.start_floor_battle(index))


func _go_upstairs() -> void:
	_busy = true
	Audio.play_sfx("stairs", 0.0)
	var tw := create_tween()
	_flash.show()
	tw.tween_property(_flash, "modulate:a", 1.0, 0.3).from(0.0)
	tw.tween_callback(func():
		GameState.enter_floor(GameState.floor_number + 1)
		_busy = false
		_load_floor()
		_autosave()
		_show_toast(_floor_intro_text()))
	tw.tween_property(_flash, "modulate:a", 0.0, 0.3)
	tw.tween_callback(_flash.hide)


## Opens a conversation (public so tests/automation can use it).
func talk(dialogue_id: StringName, with: CharacterData = null, being: StringName = &"", guild: StringName = &"",
		recruit: StringName = &"") -> void:
	if _talk_cooldown > 0.0 or _dialogue.visible:
		return
	if being != &"":   # a god / demon / devil appears
		CutIns.play(CutInData.being(being))
	if _dialogue.open(dialogue_id, with, being, guild, recruit):
		Audio.play_sfx(["talk_%s" % dialogue_id, "talk"])


func _on_dialogue_finished(runner: DialogueRunner) -> void:
	_talk_cooldown = TALK_COOLDOWN
	GameState.place_npcs(layout)   # read clues vanish, recruits leave with you
	_update_hud()
	_autosave()
	if not runner.messages.is_empty():
		_show_toast("\n".join(runner.messages))
	for r in runner.requests:
		if r == "shop":
			_shop.open()
		elif r == "shop:guild":
			_shop.open_guild(DialogueRunner.context_guild)
		elif r.begins_with("shop:"):
			_shop.open(StringName(r.trim_prefix("shop:")))


## "the Goblin Captain (miniboss)" if the next floor has a miniboss or boss, else "".
func _guardian_ahead() -> String:
	var next := GameState.floor_number + 1
	var group: Array[StringName] = StageLibrary.boss_for_floor(next) if StageLibrary.is_boss_floor(next) \
		else StageLibrary.miniboss_for_floor(next)
	if group.is_empty():
		return ""
	return "the %s (%s)" % [EnemyLibrary.get_enemy(group[0]).display_name,
		"boss" if StageLibrary.is_boss_floor(next) else "miniboss"]


## Before a miniboss/boss floor: the party locks up there, so offer a check.
func _ask_before_climbing() -> void:
	_climb_prompt.dialog_text = "Floor %d: %s awaits.\n\nOnce you're up there, you can't swap, bench or dismiss\nparty members until it's beaten." % [
		GameState.floor_number + 1, _guardian_ahead()]
	_climb_prompt.popup_centered()


func _use_campfire() -> void:
	GameState.full_restore_party()
	Audio.play_sfx("campfire", 0.0)
	_update_hud()
	_autosave()
	_show_toast("The warmth restores everyone. (HP/MP full, downed allies revived)")


## Final boss beaten: record the character in the Hall of Climbers and end the run.
func _show_completion() -> void:
	_completion_open = true
	var was_real_run := GameState.run_active
	var ng := GameState.ng_plus_cycle
	var time := LegacyRecord.format_time(GameState.play_time_sec)
	var ending: Dictionary = RouteLibrary.pick_ending()   # before the run is wrapped up
	var rec := GameState.complete_run() if was_real_run else null

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud.add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	UIStyle.apply(panel)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)
	var title := Label.new()
	title.text = "The tower is conquered!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	box.add_child(title)
	var body := Label.new()
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.text = "%s\n%s\n\n" % [ending.get("title", ""), ending.get("text", "")]
	if rec:
		body.text += "%s has been recorded in the Hall of Climbers.\nCleared %s in %s (times cleared: %d, endings seen: %d).\n\nNew Game+ is open: climb again with %s from the title screen." % [
			rec.display_name(), "the normal game" if ng == 0 else "NG+%d" % ng, time, rec.times_cleared,
			rec.endings_seen.size(), rec.display_name()]
	else:
		body.text += "(Dev sandbox run: not recorded in the Hall of Climbers.)"
	box.add_child(body)
	var btn := Button.new()
	btn.text = "Return to Title"
	btn.pressed.connect(func(): get_tree().change_scene_to_file(GameState.TITLE_SCENE))
	box.add_child(btn)
	btn.grab_focus.call_deferred()


func _floor_intro_text() -> String:
	var n := GameState.floor_number
	var t := "Floor %d" % n
	if layout.is_rest:
		t += " — Rest Floor"
	var boss := GameState.floor_has_alive("boss")
	if not boss.is_empty():
		t += " — BOSS: the %s awaits" % EnemyLibrary.get_enemy(boss.group[0]).display_name
	var roamer := GameState.floor_has_alive("roaming")
	if not roamer.is_empty():
		var info := StageLibrary.roamer_info(roamer.roamer_id)
		if info.has("intro"):
			t += "\n⚠ " + info.intro
		else:
			t += "\n⚠ The %s has broken loose from floor %d!" % [
				EnemyLibrary.get_enemy(roamer.group[0]).display_name, info.get("origin_floor", 0)]
	return t


func _alive_enemy_count() -> int:
	var n := 0
	for e in GameState.floor_enemies:
		if e.alive:
			n += 1
	return n


# =========================================================
# Drawing (placeholder art: shapes only)
# =========================================================

func _tile_px(t: Vector2i) -> Vector2:
	return origin + Vector2(t) * TILE


func _draw() -> void:
	if layout == null:
		return
	var font := ThemeDB.fallback_font
	for y in FloorLayout.HEIGHT:
		for x in FloorLayout.WIDTH:
			var p := Vector2i(x, y)
			var r := Rect2(_tile_px(p), Vector2(TILE, TILE))
			if layout.is_wall(p):
				if _art.get("wall"):
					draw_texture_rect(_art.wall, r, false)
				else:
					draw_rect(r, C_WALL)
					draw_rect(r, C_WALL_EDGE, false, 1.0)
			elif _art.get("floor"):
				draw_texture_rect(_art.floor, r, false)
			else:
				draw_rect(r, C_FLOOR if (x + y) % 2 == 0 else C_FLOOR_ALT)

	# Stairs
	var sr := Rect2(_tile_px(layout.stairs), Vector2(TILE, TILE)).grow(-4)
	var locked := GameState.stairs_locked()
	if _art.get("stairs"):
		draw_texture_rect(_art.stairs, sr.grow(4), false, Color(0.45, 0.45, 0.45) if locked else Color.WHITE)
	else:
		draw_rect(sr, C_STAIRS.darkened(0.55) if locked else C_STAIRS)
		draw_string(font, sr.position + Vector2(7, 24), "UP", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.BLACK)

	# Rest floor props
	if layout.campfire.x >= 0 and _art.get("campfire"):
		draw_texture_rect(_art.campfire, Rect2(_tile_px(layout.campfire), Vector2(TILE, TILE)), false)
	elif layout.campfire.x >= 0:
		var c := _tile_px(layout.campfire) + Vector2(TILE, TILE) / 2
		draw_circle(c, TILE * 0.42, C_CAMPFIRE)
		draw_circle(c + Vector2(0, 3), TILE * 0.2, Color(1, 0.9, 0.4))
	if layout.merchant.x >= 0 and _art.get("merchant"):
		draw_texture_rect(_art.merchant, Rect2(_tile_px(layout.merchant), Vector2(TILE, TILE)), false)
	elif layout.merchant.x >= 0:
		var mr := Rect2(_tile_px(layout.merchant), Vector2(TILE, TILE)).grow(-3)
		draw_rect(mr, C_MERCHANT)
		draw_string(font, mr.position + Vector2(10, 23), "$", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	if layout.board.x >= 0:   # notice board: a wooden panel with "!"
		var br := Rect2(_tile_px(layout.board), Vector2(TILE, TILE)).grow(-4)
		if _art.get("board"):
			draw_texture_rect(_art.board, br.grow(4), false)
		else:
			draw_rect(br, C_BOARD)
			draw_rect(br, C_BOARD.lightened(0.4), false, 2.0)
		draw_string(font, br.position + Vector2(11, 21), "!" if _board_has_new else "·", HORIZONTAL_ALIGNMENT_LEFT, -1, 18,
			Color(1, 0.9, 0.4) if _board_has_new else Color(1, 1, 1, 0.5))

	# NPCs (rounded square with an initial) and lore objects (diamond with "?")
	for p: Vector2i in layout.npcs:
		var npc := NpcLibrary.get_npc(layout.npcs[p])
		var waiting := GameState.waiting_companion(layout.npcs[p])
		var being := GameState.shrine_being(layout.npcs[p])
		if waiting:   # one of your dismissed companions: drawn in the player's colour
			npc = { "name": waiting.character_name, "kind": "npc", "color": C_PLAYER.darkened(0.2) }
		elif being != &"":   # a shrine: gold for gods, red for demons, violet for devils
			var col: Color = { "god": Color(1.0, 0.9, 0.5), "demon": Color(0.8, 0.2, 0.2), "devil": Color(0.6, 0.3, 0.8) }.get(
				BeingLibrary.get_being(being).kind, Color.WHITE)
			npc = { "name": BeingLibrary.get_being(being).name, "kind": "object", "color": col }
		var agent := GameState.agent_guild(layout.npcs[p])
		if agent != &"":   # a guild agent: green if you're a member, grey otherwise
			npc = { "name": GuildLibrary.guild_name(agent).trim_prefix("The "), "kind": "npc",
				"color": Color(0.4, 0.8, 0.5) if GameState.guilds.member == agent else Color(0.65, 0.65, 0.7) }
		var center := _tile_px(p) + Vector2(TILE, TILE) / 2
		var col: Color = npc.get("color", Color.GRAY)
		var token := Assets.first([["tokens", being], ["beings", being]]) if being != &"" \
			else Assets.first([["tokens", layout.npcs[p]], ["portraits", layout.npcs[p]]])
		if token:
			draw_texture_rect(token, Rect2(_tile_px(p), Vector2(TILE, TILE)).grow(-2), false)
		elif npc.get("kind") == "object":
			var h := TILE * 0.38
			var pts := PackedVector2Array([center + Vector2(0, -h), center + Vector2(h, 0),
				center + Vector2(0, h), center + Vector2(-h, 0)])
			draw_colored_polygon(pts, col)
			pts.append(pts[0])
			draw_polyline(pts, Color(1, 0.85, 0.5), 2.0)
			draw_string(font, center + Vector2(-4, 6), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.9, 0.6))
		else:
			var nr := Rect2(_tile_px(p), Vector2(TILE, TILE)).grow(-5)
			draw_rect(nr, col)
			draw_rect(nr, C_NPC_OUTLINE, false, 2.0)
			draw_string(font, nr.position + Vector2(8, 20), String(npc.name).left(1),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.BLACK)

	# Enemies
	for i in _enemy_view.size():
		var data: Dictionary = GameState.floor_enemies[i]
		if not data.alive:
			continue
		var v: Dictionary = _enemy_view[i]
		var pos: Vector2 = (v.from as Vector2).lerp(v.to, v.t) + Vector2(TILE, TILE) / 2
		var first := EnemyLibrary.get_enemy(data.group[0])
		var col: Color = first.color
		if v.stun > 0.0:
			col.a = 0.35
		var kind := GameState.enemy_kind(data)
		var is_boss := kind != "normal"
		var radius: float = TILE * (0.3 + 0.04 * data.group.size())
		if is_boss:
			radius = TILE * (0.62 if kind == "boss" else (0.4 if kind in ["guard", "rescue"] else 0.48))
			var ring: Color = {"boss": C_BOSS_RING, "miniboss": C_MINIBOSS_RING, "roaming": C_ROAMER_RING,
				"guard": C_GUARD_RING, "champion": C_CHAMPION_RING, "rescue": C_RESCUE_RING}[kind]
			if kind == "rescue":   # pulses: someone's in trouble
				ring.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() / 200.0)
			if kind == "roaming":   # pulsing ring so it stands out while it moves
				ring.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() / 150.0)
			draw_arc(pos, radius + 4, 0, TAU, 28, ring, 3.0)
		var token := Assets.first([["tokens", first.id], ["enemies", first.id]])
		if token:
			draw_texture_rect(token, Rect2(pos - Vector2(radius, radius), Vector2(radius, radius) * 2), false,
				Color(1, 1, 1, col.a))
		else:
			draw_circle(pos, radius, col)
			draw_arc(pos, radius, 0, TAU, 20, Color(0, 0, 0, 0.6), 2.0)
		if is_boss:
			var mark: String = {"boss": "!!", "miniboss": "!", "roaming": "?", "guard": "G", "champion": "C", "rescue": "+"}[kind]
			draw_string(font, pos + Vector2(-4.5 * mark.length(), 6), mark, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.BLACK)
		elif data.group.size() > 1:
			draw_string(font, pos + Vector2(-4, 5), str(data.group.size()), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.BLACK)

	# Player
	var pp := _player_from.lerp(_player_to, _player_t)
	var pr := Rect2(pp, Vector2(TILE, TILE)).grow(-6)
	var pc := C_PLAYER
	if _invulnerable > 0.0 and int(_invulnerable * 10) % 2 == 0:
		pc.a = 0.4
	if _art.get("player"):
		draw_texture_rect(_art.player, pr.grow(6), false, Color(1, 1, 1, pc.a))
	else:
		draw_rect(pr, pc)
		draw_rect(pr, Color.WHITE, false, 2.0)


# =========================================================
# HUD
# =========================================================

func _build_hud() -> void:
	_hud = CanvasLayer.new()
	add_child(_hud)

	var bg := ThemedBackground.new()
	# Background must sit *behind* the map, so it goes on its own layer.
	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -1
	bg_layer.add_child(bg)
	add_child(bg_layer)

	var top := HBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 16
	top.offset_right = -16
	top.offset_top = 8
	_hud.add_child(top)
	_floor_label = Label.new()
	_floor_label.add_theme_font_size_override("font_size", 16)
	top.add_child(_floor_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var hint := Label.new()
	hint.text = "WASD move · Tab party"
	hint.modulate = Color(1, 1, 1, 0.5)
	top.add_child(hint)

	# Pinned quest, top right under the controls hint.
	_tracker = Label.new()
	_tracker.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_tracker.offset_top = 34
	_tracker.offset_right = -16
	_tracker.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_tracker.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_tracker.add_theme_font_size_override("font_size", 14)
	_tracker.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	_tracker.add_theme_color_override("font_outline_color", Color.BLACK)
	_tracker.add_theme_constant_override("outline_size", 4)
	_hud.add_child(_tracker)

	_party_strip = HBoxContainer.new()
	_party_strip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_party_strip.offset_left = 16
	_party_strip.offset_top = -40
	_party_strip.offset_bottom = -8
	_party_strip.add_theme_constant_override("separation", 28)
	_hud.add_child(_party_strip)

	# Toast (floor intro, "Victory!", ...) in a system window, notices stacked below.
	var toasts := VBoxContainer.new()
	toasts.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toasts.offset_top = 34
	toasts.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toasts.add_theme_constant_override("separation", 8)
	toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(toasts)
	_toast_panel = PanelContainer.new()
	UIStyle.apply(_toast_panel)
	_toast_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.hide()
	toasts.add_child(_toast_panel)
	_toast = Label.new()
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 18)
	_toast_panel.add_child(_toast)
	_notices = SystemNotice.new()
	_notices.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	toasts.add_child(_notices)

	_flash = ColorRect.new()
	_flash.color = Color.WHITE
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.hide()
	_hud.add_child(_flash)

	_party_menu = PartyMenu.new()
	_party_menu.closed.connect(_update_hud)
	_hud.add_child(_party_menu)
	_shop = ShopPanel.new()
	_shop.closed.connect(_update_hud)
	_hud.add_child(_shop)
	_pause = PauseMenu.new()
	_hud.add_child(_pause)
	_board_panel = NoticeBoardPanel.new()
	_board_panel.closed.connect(_update_hud)
	_hud.add_child(_board_panel)
	_climb_prompt = ConfirmationDialog.new()
	_climb_prompt.title = "Danger ahead"
	_climb_prompt.ok_button_text = "Climb"
	_climb_prompt.cancel_button_text = "Check party first"
	_climb_prompt.confirmed.connect(_go_upstairs)
	_climb_prompt.canceled.connect(func():
		_party_menu.open()
		_party_menu.open_manage())
	_hud.add_child(_climb_prompt)
	_dialogue = DialogueBox.new()
	_dialogue.finished.connect(_on_dialogue_finished)
	_hud.add_child(_dialogue)


func _update_hud() -> void:
	var fl := "Floor %d" % GameState.floor_number
	if GameState.is_rest_floor(GameState.floor_number):
		fl += "  (Rest Floor)"
	fl += "     Gold %d     Checkpoint: floor %d" % [GameState.player.gold, GameState.checkpoint_floor]
	fl = StageLibrary.stage_name(GameState.floor_number) + "   ·   " + fl
	fl += "     %s territory" % GuildLibrary.guild_name(GameState.guilds.owner_of_floor(GameState.floor_number))
	var captain := GameState.guilds.guest_captain(GameState.floor_number, "normal")
	if captain:
		fl += " (Captain %s)" % captain.character_name
	for e in GameState.floor_enemies:
		if not e.alive:
			continue
		var name_s := EnemyLibrary.get_enemy(e.group[0]).display_name
		match GameState.enemy_kind(e):
			"miniboss":
				fl += "     ⚠ %s guards the stairs" % name_s
			"boss":
				fl += "     ☠ BOSS: %s" % name_s
			"roaming":
				# Secret-path roamers stay mysterious until you fight them.
				if StageLibrary.roamer_info(e.roamer_id).get("spawn") == "secret":
					fl += "     ? Something stalks this floor"
				else:
					fl += "     ? %s is loose on this floor" % name_s
			"champion":
				fl += "     ⚔ %s's champion holds this territory" % GuildLibrary.guild_name(e.get("guild", &""))
			"rescue":
				fl += "     + Someone is fighting for their life here!"
	var hunting := GameState.floor_enemies.filter(func(e): return e.alive and e.kind == "guard")
	if not hunting.is_empty():
		fl += "     ⚠ %s guards are hunting you" % GuildLibrary.guild_name(hunting[0].get("guild", &""))
	_floor_label.text = fl

	_board_has_new = layout != null and layout.board.x >= 0 \
		and not GameState.quests.board_offers(GameState.floor_number).is_empty()
	var pinned := GameState.quests.pinned
	_tracker.text = "📌 %s\n%s" % [GameState.quests.def_of(pinned).title, GameState.quests.step_text(pinned)] \
		if GameState.quests.is_active(pinned) else ""

	for c in _party_strip.get_children():
		c.queue_free()
	for m in GameState.battle_party():
		var l := Label.new()
		if m.is_downed():
			l.text = "%s  DOWNED" % m.character_name
			l.modulate = Color(1, 0.45, 0.45)
		else:
			l.text = "%s  HP %d/%d  MP %d/%d" % [m.character_name, m.current_hp(), m.max_hp(),
				m.current_mp(), m.max_mp()]
			if m.current_hp() < m.max_hp() * 0.35:
				l.modulate = Color(1, 0.8, 0.4)
		if m.unspent_points > 0 or m.can_choose_class():
			l.text += "  ★"
		_party_strip.add_child(l)


var _toast_tween: Tween


func _show_toast(text: String) -> void:
	_toast.text = text
	_toast_panel.show()
	_toast_panel.modulate.a = 1.0
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = _toast_panel.create_tween()
	_toast_tween.tween_interval(2.0)
	_toast_tween.tween_property(_toast_panel, "modulate:a", 0.0, 0.6)
	_toast_tween.tween_callback(_toast_panel.hide)


## Quest / path / blessing / guild news become system notices (with a chime),
## stacked under the main toast so they never hide it.
func _show_quest_messages() -> void:
	for pair in [[GameState.quests.messages, "quest"], [GameState.route.messages, "route"],
			[GameState.blessings.messages, "blessing"], [GameState.guilds.messages, "guild"]]:
		for m in pair[0]:
			_notices.push(m, pair[1])
		pair[0].clear()
	_update_hud()
