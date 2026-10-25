extends Control
## Title screen: Continue, New Game, New Game+, Settings, Quit
## (+ Dev Sandbox in debug builds). Three save slots: Continue and New Game
## both go through the slot picker; New Game+ reuses the slot the character
## conquered the tower in (after a confirmation).

const SANDBOX_SCENE := "res://scenes/progression_sandbox.tscn"
const GAME_TITLE := "TOWER CLIMBER"   # placeholder title

var _continue_btn: Button
var _ngplus_btn: Button
var _save_info: Label
var _menu: VBoxContainer
var _settings: SettingsPanel
var _credits: CreditsPanel

# Save slot picker
var _slot_panel: Control
var _slot_title: Label
var _slot_rows: VBoxContainer
var _slot_mode := "load"        # "load", "new" or "ngplus"
var _new_game_slot := 1

# New game panel
var _new_panel: Control
var _name_edit: LineEdit
var _friend_edit: LineEdit
var _new_step1: VBoxContainer   # name yourself
var _new_step2: VBoxContainer   # name your childhood friend
var _friend_prompt: Label
var _friend_warning: Label
var _new_warning: Label
var _new_difficulty: OptionButton
var _new_ironman: CheckBox

# New Game+ panel
var _ng_panel: Control
var _ng_list: VBoxContainer
var _ng_detail: Label
var _ng_begin: Button
var _ng_warning: Label
var _ng_selected: LegacyRecord
var _ng_group := ButtonGroup.new()
var _ng_difficulty: OptionButton
var _ng_ironman: CheckBox


func _ready() -> void:
	GameState.run_active = false
	GameState.clock_paused = false
	_build()
	_refresh()
	if GameState.ironman_ended_message != "":   # an Ironman run just ended
		var dlg := AcceptDialog.new()
		dlg.title = "Fallen"
		dlg.dialog_text = GameState.ironman_ended_message
		GameState.ironman_ended_message = ""
		add_child(dlg)
		dlg.popup_centered.call_deferred()


func _refresh() -> void:
	var has_save := GameState.any_save()
	_continue_btn.disabled = not has_save
	var used := 0
	for slot in range(1, GameState.SLOT_COUNT + 1):
		if GameState.slot_info(slot).state != "empty":
			used += 1
	_save_info.text = "%d of %d save slots in use" % [used, GameState.SLOT_COUNT] if used > 0 else "No saved games"
	var book := GameState.load_legacy()
	var can_ng := book.records.any(func(r): return r.can_continue())
	_ngplus_btn.disabled = not can_ng
	_ngplus_btn.tooltip_text = ("Climb again with a character from the Hall of Climbers." if can_ng
		else "Conquer the tower (beat the floor %d boss) to unlock New Game+." % GameState.FINAL_FLOOR)
	var first := _continue_btn if has_save else _menu.get_node("NewGame")
	first.grab_focus.call_deferred()


# =========================================================
# Actions
# =========================================================

func _on_continue() -> void:
	_open_slots("load")


# ---------- Save slot picker ----------

func _open_slots(mode: String) -> void:
	_slot_mode = mode
	match mode:
		"load":
			_slot_title.text = "Continue — choose a save"
		"new":
			_slot_title.text = "New Game — choose a save slot"
		"ngplus":
			_slot_title.text = "New Game+ with %s — choose a save slot" % _ng_selected.display_name()
	_rebuild_slots()
	_slot_panel.show()


func _rebuild_slots() -> void:
	for c in _slot_rows.get_children():
		c.queue_free()
	var first_focus: Button = null
	for slot in range(1, GameState.SLOT_COUNT + 1):
		var info := GameState.slot_info(slot)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var l := Label.new()
		l.text = "Slot %d   %s" % [slot, info.summary]
		var suggested := _slot_mode == "ngplus" and slot == GameState.ng_plus_slot_for(_ng_selected)
		if suggested:
			l.text += "   ★ Suggested"
			l.tooltip_text = "Where %s conquered the tower." % _ng_selected.display_name()
			l.mouse_filter = Control.MOUSE_FILTER_PASS
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.clip_text = true
		if info.state == "empty":
			l.modulate = Color(1, 1, 1, 0.5)
		elif info.state == "completed":
			l.modulate = Color(0.95, 0.85, 0.55)
		row.add_child(l)
		var main := Button.new()
		if _slot_mode == "load":
			main.text = "Load"
			main.disabled = info.state != "run"
			if info.state == "completed":
				main.tooltip_text = "This run is finished. Use New Game+ to climb again."
			main.pressed.connect(_load_slot.bind(slot))
		elif _slot_mode == "new":
			main.text = "Start here"
			main.pressed.connect(_choose_new_game_slot.bind(slot))
		else:
			main.text = "Start here"
			main.pressed.connect(_confirm_ng_plus_slot.bind(slot))
		row.add_child(main)
		var del := Button.new()
		del.text = "Delete"
		del.disabled = info.state == "empty"
		del.pressed.connect(_confirm_delete_slot.bind(slot))
		row.add_child(del)
		_slot_rows.add_child(row)
		if first_focus == null and not main.disabled:
			first_focus = main
		if suggested:
			first_focus = main
	if first_focus:
		first_focus.grab_focus.call_deferred()


func _load_slot(slot: int) -> void:
	if GameState.load_game(slot):
		get_tree().change_scene_to_file(GameState.TOWER_SCENE)
	else:
		_confirm("Couldn't load", "Slot %d couldn't be loaded. The file may be damaged." % slot, Callable())


func _choose_new_game_slot(slot: int) -> void:
	var info := GameState.slot_info(slot)
	if info.state == "empty":
		_start_naming(slot)
		return
	var what := "a conquered run (that character stays in the Hall of Climbers)" if info.state == "completed" \
		else "a saved game"
	_confirm("Overwrite Slot %d?" % slot,
		"Slot %d has %s:\n%s\n\nStart a new game here and erase it?" % [slot, what, info.summary],
		_start_naming.bind(slot))


func _confirm_delete_slot(slot: int) -> void:
	_confirm("Delete Slot %d?" % slot,
		"%s\n\nThis can't be undone. (Characters in the Hall of Climbers are kept.)" % GameState.slot_info(slot).summary,
		func():
			GameState.delete_slot(slot)
			_rebuild_slots()
			_refresh())


## Small yes/no popup. An invalid `on_yes` makes it a plain OK message.
func _confirm(title: String, text: String, on_yes: Callable) -> void:
	var dlg: AcceptDialog = ConfirmationDialog.new() if on_yes.is_valid() else AcceptDialog.new()
	dlg.title = title
	dlg.dialog_text = text
	dlg.dialog_autowrap = true
	dlg.min_size = Vector2i(500, 0)
	if on_yes.is_valid():
		dlg.ok_button_text = "Yes"
		dlg.cancel_button_text = "No"
		dlg.confirmed.connect(func(): dlg.queue_free(); on_yes.call())
		dlg.canceled.connect(dlg.queue_free)
	else:
		dlg.confirmed.connect(dlg.queue_free)
	add_child(dlg)
	dlg.popup_centered()


func _start_naming(slot: int) -> void:
	_new_game_slot = slot
	_slot_panel.hide()
	_open_new_game()


## New Game is two steps, Pokémon-style: name yourself, then your childhood friend.
func _open_new_game() -> void:
	_name_edit.text = "Climber"
	_friend_edit.text = ""
	_new_warning.text = "Save slot %d" % _new_game_slot
	_new_step1.show()
	_new_step2.hide()
	_new_panel.show()
	_name_edit.grab_focus()
	_name_edit.select_all()


## Step 1 -> step 2.
func _confirm_player_name(_t: String = "") -> void:
	var cleaned := CharacterData.clean_name(_name_edit.text)
	if cleaned.is_empty():
		_new_warning.text = "Please enter a name."
		return
	_name_edit.text = cleaned
	_friend_prompt.text = "Nice to meet you, %s!\n\nYour childhood friend has insisted on climbing the tower with you.\nWhat's your friend's name?" % cleaned
	_friend_warning.text = ""
	_new_step1.hide()
	_new_step2.show()
	_friend_edit.grab_focus()


## Step 2: start the run. A blank friend name uses the default.
func _begin_new_game(_t: String = "") -> void:
	GameState.start_new_game(_name_edit.text, _friend_edit.text, _new_game_slot,
		_new_difficulty.get_selected_id(), _new_ironman.button_pressed)
	get_tree().change_scene_to_file(GameState.TOWER_SCENE)


func _use_default_friend_name() -> void:
	_friend_edit.text = GameState.CHILDHOOD_FRIEND_NAME
	_begin_new_game()


func _open_ng_plus() -> void:
	for c in _ng_list.get_children():
		c.queue_free()
	_ng_group = ButtonGroup.new()
	_ng_selected = null
	_ng_begin.disabled = true
	_ng_detail.text = "Choose a character."
	_ng_warning.text = ""
	var book := GameState.load_legacy()
	for rec in book.records:
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = _ng_group
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = rec.summary()
		b.disabled = not rec.can_continue()   # the fallen are remembered, not continued
		b.pressed.connect(_select_record.bind(rec))
		_ng_list.add_child(b)
	_ng_panel.show()


func _select_record(rec: LegacyRecord) -> void:
	_ng_selected = rec
	_ng_begin.disabled = false
	var slot := GameState.ng_plus_slot_for(rec)
	_ng_warning.text = "Suggested save slot: Slot %d, where %s conquered the tower (★). You can pick a different slot on the next screen." % [
		slot, rec.display_name()]
	var c := rec.character
	var stat_parts: PackedStringArray = []
	for s in Stats.all():
		stat_parts.append("%s %d" % [Stats.short_name_of(s), c.stats.get_total(s)])
	var gear_parts: PackedStringArray = []
	for g: GearItem in c.equipment.values():
		if g.carries_into_ng_plus():
			gear_parts.append(g.summary())
	for g: GearItem in rec.vault:
		gear_parts.append(g.summary() + " (bag)")
	var next_cycle := rec.highest_cycle_cleared + 1
	_ng_detail.text = "%s — Level %d %s\n%s\nUnique gear carried over: %s\n\nCleared %d time(s). First clear: %s. Best time: %s.\n\nStarts NG+%d: enemies x%.1f. Keeps level, stats, class and Unique gear; other gear, gold, items\nand tower progress reset, and %s rejoins at level 1. The Ascendant class unlocks in New Game+." % [
		c.character_name, c.level, rec.class_display(), "   ".join(stat_parts),
		", ".join(gear_parts) if not gear_parts.is_empty() else "none",
		rec.times_cleared, rec.first_cleared_at, LegacyRecord.format_time(rec.best_play_time_sec),
		next_cycle, GameState.ng_plus_scale(next_cycle),
		rec.friend_name if rec.friend_name != "" else GameState.CHILDHOOD_FRIEND_NAME]


## "Climb again" -> pick a slot (the one they conquered the tower in is suggested).
func _begin_ng_plus() -> void:
	if _ng_selected == null:
		return
	_ng_panel.hide()
	_open_slots("ngplus")


func _confirm_ng_plus_slot(slot: int) -> void:
	var rec := _ng_selected
	var info := GameState.slot_info(slot)
	var where := "the slot where %s conquered the tower" % rec.display_name() if slot == GameState.ng_plus_slot_for(rec) \
		else "a different slot from where %s conquered the tower (Slot %d)" % [rec.display_name(), GameState.ng_plus_slot_for(rec)]
	var now_text := "It's empty." if info.state == "empty" else "Right now it holds:\n%s\n\nThat will be replaced." % info.summary
	_confirm("Start New Game+ in Slot %d?" % slot,
		"New Game+ with %s will use Save Slot %d, %s.\n\n%s\n\nContinue?" % [
			rec.display_name(), slot, where, now_text],
		func():
			GameState.start_new_game_plus(rec, slot, _ng_difficulty.get_selected_id(), _ng_ironman.button_pressed)
			get_tree().change_scene_to_file(GameState.TOWER_SCENE))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _slot_panel.visible:
			_slot_panel.hide()
			if _slot_mode == "ngplus":
				_ng_panel.show()
		elif _new_panel.visible and _new_step2.visible:
			_new_step2.hide()
			_new_step1.show()
			_name_edit.grab_focus()
			get_viewport().set_input_as_handled()
			return
		elif _new_panel.visible:
			_new_panel.hide()
		elif _ng_panel.visible:
			_ng_panel.hide()
		else:
			return
		get_viewport().set_input_as_handled()
		_refresh()


# =========================================================
# UI construction
# =========================================================

func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ThemedBackground.new())
	var backdrop := Assets.texture("backgrounds", "title")   # art hook
	if backdrop:
		var art := TextureRect.new()
		art.texture = backdrop
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		add_child(art)
	Audio.play_music(MusicLibrary.title())

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	center.add_child(col)

	var title := Label.new()
	title.text = GAME_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", UITheme.color("accent"))
	title.add_theme_color_override("font_outline_color", UITheme.color("glow"))
	title.add_theme_constant_override("outline_size", 8)
	col.add_child(title)
	var sub := Label.new()
	sub.text = "How high will you climb?"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.modulate = Color(1, 1, 1, 0.55)
	col.add_child(sub)
	col.add_child(_spacer(24))

	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 8)
	_menu.custom_minimum_size.x = 300
	col.add_child(_menu)
	_continue_btn = _menu_button("Continue", _on_continue)
	_save_info = Label.new()
	_save_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_save_info.add_theme_font_size_override("font_size", 13)
	_save_info.modulate = Color(1, 1, 1, 0.55)
	_menu.add_child(_save_info)
	_menu_button("New Game", _open_slots.bind("new")).name = "NewGame"
	_ngplus_btn = _menu_button("New Game+", _open_ng_plus)
	_menu_button("Settings", func(): _settings.open())
	_menu_button("Credits", func(): _credits.open(GAME_TITLE))
	_menu_button("Quit", func(): get_tree().quit())

	if OS.is_debug_build():
		var dev := Button.new()
		dev.text = "Dev Sandbox"
		dev.flat = true
		dev.modulate = Color(1, 1, 1, 0.45)
		dev.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		dev.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		dev.grow_vertical = Control.GROW_DIRECTION_BEGIN
		dev.offset_right = -16
		dev.offset_bottom = -12
		dev.pressed.connect(func(): get_tree().change_scene_to_file(SANDBOX_SCENE))
		add_child(dev)

	var version := Label.new()
	version.text = "Prototype build"
	version.modulate = Color(1, 1, 1, 0.3)
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	version.offset_left = 16
	version.offset_top = -32
	add_child(version)

	_build_slot_panel()
	_build_new_game_panel()
	_build_ng_plus_panel()
	_settings = SettingsPanel.new()
	_settings.closed.connect(_refresh)
	add_child(_settings)
	_credits = CreditsPanel.new()
	add_child(_credits)


func _build_slot_panel() -> void:
	var box := _overlay_panel(880)
	_slot_panel = box.get_meta("overlay")
	_slot_title = _heading("")
	box.add_child(_slot_title)
	_slot_rows = VBoxContainer.new()
	_slot_rows.add_theme_constant_override("separation", 10)
	box.add_child(_slot_rows)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(row)
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(func():
		_slot_panel.hide()
		if _slot_mode == "ngplus":
			_ng_panel.show()
		else:
			_refresh())
	row.add_child(back)


func _build_new_game_panel() -> void:
	var box := _overlay_panel(520)
	_new_panel = box.get_meta("overlay")
	box.add_child(_heading("New Game"))

	# Step 1: your name
	_new_step1 = VBoxContainer.new()
	_new_step1.add_theme_constant_override("separation", 10)
	box.add_child(_new_step1)
	var l := Label.new()
	l.text = "What's your name, climber? (up to %d characters)" % CharacterData.NAME_MAX_LENGTH
	_new_step1.add_child(l)
	_name_edit = LineEdit.new()
	_name_edit.max_length = CharacterData.NAME_MAX_LENGTH
	_name_edit.text_submitted.connect(_confirm_player_name)
	_new_step1.add_child(_name_edit)
	var picks := difficulty_picker(_new_step1)
	_new_difficulty = picks[0]
	_new_ironman = picks[1]
	_new_warning = Label.new()
	_new_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_new_warning.modulate = Color(1, 0.75, 0.4)
	_new_step1.add_child(_new_warning)
	var row1 := HBoxContainer.new()
	row1.alignment = BoxContainer.ALIGNMENT_END
	_new_step1.add_child(row1)
	var back1 := Button.new()
	back1.text = "Back"
	back1.pressed.connect(func(): _new_panel.hide(); _open_slots("new"))
	row1.add_child(back1)
	var next := Button.new()
	next.text = "Next"
	next.pressed.connect(_confirm_player_name)
	row1.add_child(next)

	# Step 2: your childhood friend's name
	_new_step2 = VBoxContainer.new()
	_new_step2.add_theme_constant_override("separation", 10)
	_new_step2.hide()
	box.add_child(_new_step2)
	_friend_prompt = Label.new()
	_friend_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_new_step2.add_child(_friend_prompt)
	_friend_edit = LineEdit.new()
	_friend_edit.max_length = CharacterData.NAME_MAX_LENGTH
	_friend_edit.placeholder_text = "Leave blank for %s" % GameState.CHILDHOOD_FRIEND_NAME
	_friend_edit.text_submitted.connect(_begin_new_game)
	_new_step2.add_child(_friend_edit)
	_friend_warning = Label.new()
	_friend_warning.modulate = Color(1, 1, 1, 0.55)
	_friend_warning.text = ""
	_new_step2.add_child(_friend_warning)
	var row2 := HBoxContainer.new()
	row2.alignment = BoxContainer.ALIGNMENT_END
	_new_step2.add_child(row2)
	var back2 := Button.new()
	back2.text = "Back"
	back2.pressed.connect(func():
		_new_step2.hide()
		_new_step1.show()
		_name_edit.grab_focus())
	row2.add_child(back2)
	var dflt := Button.new()
	dflt.text = "Use \"%s\"" % GameState.CHILDHOOD_FRIEND_NAME
	dflt.tooltip_text = "Can't think of one? Use the default name. You can rename them later from the party menu."
	dflt.pressed.connect(_use_default_friend_name)
	row2.add_child(dflt)
	var go := Button.new()
	go.text = "Begin the climb"
	go.pressed.connect(_begin_new_game)
	row2.add_child(go)


func _build_ng_plus_panel() -> void:
	var box := _overlay_panel(820)
	_ng_panel = box.get_meta("overlay")
	box.add_child(_heading("New Game+ — Hall of Climbers"))
	var hint := Label.new()
	hint.text = "Every character who conquered the tower is recorded here. Pick one to climb again."
	hint.modulate = Color(1, 1, 1, 0.6)
	box.add_child(hint)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 150
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_ng_list = VBoxContainer.new()
	_ng_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_ng_list)
	_ng_detail = Label.new()
	_ng_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ng_detail.custom_minimum_size.y = 150
	box.add_child(_ng_detail)
	var picks := difficulty_picker(box)
	_ng_difficulty = picks[0]
	_ng_ironman = picks[1]
	_ng_warning = Label.new()
	_ng_warning.modulate = Color(1, 0.75, 0.4)
	_ng_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_ng_warning)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(row)
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(func(): _ng_panel.hide(); _refresh())
	row.add_child(back)
	_ng_begin = Button.new()
	_ng_begin.text = "Climb again"
	_ng_begin.pressed.connect(_begin_ng_plus)
	row.add_child(_ng_begin)


## Builds a hidden full-screen overlay with a centred panel; returns the panel's
## content box (the overlay itself is stored in its "overlay" meta).
func _overlay_panel(width: float) -> VBoxContainer:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.hide()
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, 0)
	UIStyle.apply(panel)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	box.set_meta("overlay", overlay)
	return box


## Difficulty dropdown (with a description) + the Ironman checkbox.
## Returns [OptionButton, CheckBox].
static func difficulty_picker(parent: Control) -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var l := Label.new()
	l.text = "Difficulty"
	row.add_child(l)
	var opt := OptionButton.new()
	for level in Difficulty.all():
		opt.add_item(Difficulty.name_of(level), level)
	opt.select(opt.get_item_index(Difficulty.DEFAULT))
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(opt)
	var desc := Label.new()
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 440
	desc.add_theme_font_size_override("font_size", 13)
	desc.modulate = Color(1, 1, 1, 0.65)
	desc.text = Difficulty.desc_of(Difficulty.DEFAULT) + "\nYou can lower it later, but never raise it."
	opt.item_selected.connect(func(i):
		desc.text = Difficulty.desc_of(opt.get_item_id(i)) + "\nYou can lower it later, but never raise it.")
	parent.add_child(desc)
	var iron := CheckBox.new()
	iron.text = "Ironman: anyone still down after a fight is dead; if you die, the save is deleted."
	iron.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	iron.custom_minimum_size.x = 440
	parent.add_child(iron)
	return [opt, iron]


func _menu_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 40
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(cb)
	_menu.add_child(b)
	return b


func _heading(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 24)
	return l


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	return c
