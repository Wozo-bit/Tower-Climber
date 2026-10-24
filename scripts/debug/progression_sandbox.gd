extends Control
## Playable sandbox for the progression system: gain XP, allocate stats,
## hit level 10, pick a class, and test respecs. Not part of the real game —
## it's a harness so the systems can be felt out before combat exists.

## Lives in GameState so it survives trips to the battle scene.
var character: CharacterData

var _alloc_panel: StatAllocationPanel
var _class_screen: ClassSelectionScreen
var _info: Label
var _name_edit: LineEdit
var _log: RichTextLabel
var _respec_btn: Button
var _class_btn: Button
var _floor_pick: SpinBox
var _floor_info: Label

## Highest floor the sandbox floor picker offers (stages repeat past the last one).
const SANDBOX_MAX_FLOOR := 100


func _ready() -> void:
	GameState.run_active = false   # test sessions never autosave over your real save
	character = GameState.player
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.09, 0.12)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 24)
	margin.add_child(hbox)

	_alloc_panel = StatAllocationPanel.new()
	hbox.add_child(_alloc_panel)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	hbox.add_child(right)

	var name_row := HBoxContainer.new()
	right.add_child(name_row)
	var name_label := Label.new()
	name_label.text = "Name:"
	name_row.add_child(name_label)
	var name_edit := LineEdit.new()
	_name_edit = name_edit
	name_edit.text = character.character_name
	name_edit.max_length = CharacterData.NAME_MAX_LENGTH
	name_edit.custom_minimum_size.x = 220
	name_row.add_child(name_edit)
	var apply_name := func(_t = ""):
		if character.rename(name_edit.text):
			name_edit.text = character.character_name
			_log_line("Your character is now called %s." % character.character_name)
		else:
			name_edit.text = character.character_name
			_log_line("[color=salmon]A name can't be blank.[/color]")
	name_edit.text_submitted.connect(apply_name)
	_add_button(name_row, "Set name", apply_name)

	_info = Label.new()
	_info.add_theme_font_size_override("font_size", 18)
	right.add_child(_info)

	var row1 := HBoxContainer.new()
	right.add_child(row1)
	_add_button(row1, "Gain 100 XP", func(): character.add_xp(100))
	_add_button(row1, "Level up", func(): character.level_up())
	_add_button(row1, "Jump to level 10", _jump_to_ten)

	var row2 := HBoxContainer.new()
	right.add_child(row2)
	_respec_btn = _add_button(row2, "Respec", _do_respec)
	_add_button(row2, "+500 gold", func(): character.gold += 500; _refresh())
	_class_btn = _add_button(row2, "Choose class…", func(): _class_screen.open(character))
	_add_button(row2, "Reset character", _reset_character)

	var row3 := HFlowContainer.new()
	right.add_child(row3)
	_add_button(row3, "⚔ Test battle (you + 3 lv10 companions)", _start_test_battle)
	_add_button(row3, "♛ Test miniboss (Hobgoblin)", func():
		GameState.ensure_test_companions()
		GameState.start_battle(EnemyLibrary.build_group(EnemyLibrary.TEST_MINIBOSS_ENCOUNTER), scene_file_path))
	_add_button(row3, "☠ Test boss (Goblin King)", func():
		GameState.ensure_test_companions()
		GameState.start_battle(EnemyLibrary.build_group(EnemyLibrary.TEST_BOSS_ENCOUNTER), scene_file_path))
	_add_button(row3, "? Test roaming boss", func():
		GameState.ensure_test_companions()
		GameState.start_battle(EnemyLibrary.build_group(EnemyLibrary.TEST_ROAMING_ENCOUNTER), scene_file_path))
	_add_button(row3, "🔍 Find next Ashbound clue (debug)", func():
		var path: Dictionary = SecretPaths.PATHS[&"ashbound"]
		for f in path.clue_flags:
			if not GameState.has_flag(f):
				GameState.set_flag(f)
				var found := SecretPaths.clues_found(&"ashbound", GameState.story_flags)
				_log_line("[color=orange]Clue found: %s (%d/%d).[/color]" % [f, found, path.clue_flags.size()])
				if SecretPaths.is_on_path(&"ashbound", GameState.story_flags):
					_log_line("[color=orange]The final step awaits: the Ashen Wyrmling will hunt you on floors 12–29.[/color]")
				return
		_log_line("All Ashbound clues already found."))
	_add_button(row3, "▲ Enter the Tower", func():
		GameState.ensure_test_companions()
		get_tree().change_scene_to_file(GameState.TOWER_SCENE))

	# Jump straight to any floor to test its enemies, miniboss or boss.
	var floor_row := HBoxContainer.new()
	floor_row.add_theme_constant_override("separation", 8)
	right.add_child(floor_row)
	var floor_label := Label.new()
	floor_label.text = "Floor:"
	floor_row.add_child(floor_label)
	_floor_pick = SpinBox.new()
	_floor_pick.min_value = 1
	_floor_pick.max_value = SANDBOX_MAX_FLOOR
	_floor_pick.value = GameState.floor_number
	_floor_pick.value_changed.connect(func(_v): _floor_info.text = describe_floor(int(_floor_pick.value)))
	floor_row.add_child(_floor_pick)
	_add_button(floor_row, "▲ Go to floor", func(): go_to_floor(int(_floor_pick.value)))
	_floor_info = Label.new()
	_floor_info.modulate = Color(1, 1, 1, 0.7)
	_floor_info.text = describe_floor(int(_floor_pick.value))
	floor_row.add_child(_floor_info)

	# Pick which theme each stage uses (e.g. floors 1-10: Goblin Warrens or Slime Pits).
	var theme_row := HBoxContainer.new()
	theme_row.add_theme_constant_override("separation", 8)
	right.add_child(theme_row)
	if GameState.stage_themes.is_empty():
		GameState.stage_themes = []   # fills in each slot's default
	for i in StageLibrary.STAGE_SLOTS.size():
		var slot: Dictionary = StageLibrary.STAGE_SLOTS[i]
		var lbl := Label.new()
		lbl.text = "Floors %d-%d:" % [i * StageLibrary.FLOORS_PER_STAGE + 1, (i + 1) * StageLibrary.FLOORS_PER_STAGE]
		theme_row.add_child(lbl)
		var opt := OptionButton.new()
		for t in slot.themes:
			opt.add_item(StageLibrary.THEMES[t].name)
		opt.selected = slot.themes.find(StageLibrary.theme_id_for_slot(i))
		opt.disabled = slot.themes.size() < 2 or slot.has("pinned")
		opt.item_selected.connect(func(idx: int):
			var picks := GameState.stage_themes.duplicate()
			picks[i] = slot.themes[idx]
			GameState.stage_themes = picks
			GameState.floor_ready = false
			_floor_info.text = describe_floor(int(_floor_pick.value)))
		theme_row.add_child(opt)

	var log_title := Label.new()
	log_title.text = "Log"
	right.add_child(log_title)
	_log = RichTextLabel.new()
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.scroll_following = true
	right.add_child(_log)

	_class_screen = ClassSelectionScreen.new()
	add_child(_class_screen)
	_class_screen.respec_requested.connect(func(): _do_respec(); _class_screen.refresh())
	_class_screen.class_confirmed.connect(func(def): _log_line("[color=gold]Became a %s![/color]" % def.display_name))

	_bind_character()
	_log_line("Sandbox ready. Level up, spend points, and reach level 10 to pick a class.")
	if character.level > 1 or character.xp > 0:
		_log_line("Welcome back — level %d, %d XP." % [character.level, character.xp])
		_maybe_open_class_screen()


func _add_button(parent: Node, text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(callback)
	parent.add_child(b)
	return b


func _bind_character() -> void:
	character.stats_changed.connect(_refresh)
	character.leveled_up.connect(func(lv, pts): _log_line("Reached level %d (+%d points)" % [lv, pts]))
	character.class_selection_available.connect(func():
		_log_line("[color=cyan]Class selection unlocked![/color] Spend your points — the class screen opens once they're all allocated.")
		_maybe_open_class_screen())
	if not _alloc_panel.allocation_confirmed.is_connected(_maybe_open_class_screen):
		_alloc_panel.allocation_confirmed.connect(_maybe_open_class_screen)
	character.respecced.connect(func(free, cost):
		_log_line("Respecced (%s)" % ("free" if free else "%d gold" % cost)))
	_alloc_panel.bind(character)
	_refresh()


## Auto-open the class screen once the player is eligible AND has spent every point,
## so they aren't asked to choose before their build is finished.
## (They can still open it early with the "Choose class…" button.)
func _maybe_open_class_screen() -> void:
	if character.can_choose_class() and character.unspent_points == 0:
		_class_screen.open(character)


func _jump_to_ten() -> void:
	while character.level < CharacterData.CLASS_UNLOCK_LEVEL:
		character.level_up()


func _do_respec() -> void:
	if not character.respec():
		_log_line("[color=salmon]Can't respec (no points allocated, or not enough gold).[/color]")


func _reset_character() -> void:
	character = CharacterData.new()
	GameState.player = character
	_bind_character()
	_log_line("Character reset.")


## Puts the party on floor `n` (fresh layout, and it becomes the checkpoint so
## a wipe brings you straight back) and enters the tower.
func go_to_floor(n: int) -> void:
	GameState.ensure_test_companions()
	GameState.enter_floor(clampi(n, 1, SANDBOX_MAX_FLOOR))
	GameState.checkpoint_floor = GameState.floor_number
	get_tree().change_scene_to_file(GameState.TOWER_SCENE)


## e.g. "Stage 1: Goblin Warrens · miniboss: Goblin Captain".
static func describe_floor(n: int) -> String:
	var t := StageLibrary.stage_name(n)
	if GameState.is_rest_floor(n):
		return t + "  ·  rest floor"
	if StageLibrary.is_boss_floor(n):
		return t + "  ·  BOSS: " + EnemyLibrary.get_enemy(StageLibrary.boss_for_floor(n)[0]).display_name
	if StageLibrary.is_miniboss_floor(n):
		return t + "  ·  miniboss: " + EnemyLibrary.get_enemy(StageLibrary.miniboss_for_floor(n)[0]).display_name
	return t + "  ·  normal floor"


func _start_test_battle() -> void:
	GameState.ensure_test_companions()
	GameState.start_battle(EnemyLibrary.random_test_encounter(), scene_file_path)


func _refresh() -> void:
	var c := character
	var class_name_text := c.get_class_def().display_name if c.has_class() else "None"
	if _name_edit and not _name_edit.has_focus():
		_name_edit.text = c.character_name
	_info.text = "Level %d   XP %d / %d   Gold %d\nClass: %s\nFree respec available: %s   Next respec cost: %d" % [
		c.level, c.xp, CharacterData.xp_to_next(c.level), c.gold,
		class_name_text, "yes" if c.has_free_respec() else "no", c.next_respec_cost()]
	_respec_btn.disabled = not c.can_respec()
	_class_btn.disabled = not c.can_choose_class()
	if _class_screen.visible:
		_class_screen.refresh()


func _log_line(text: String) -> void:
	_log.append_text(text + "\n")
