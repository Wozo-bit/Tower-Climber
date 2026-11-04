class_name TestClientPanel
extends Control
## New Game, told as the setup screens of the game you were invited to test
## (StoryLibrary.GAME_NAME): your tester name + difficulty, the odd questions
## (StoryLibrary.SETUP_QUESTIONS), "Name the person you trust most" (the
## childhood friend), then the sync sequence that pulls you in.
## Used by the prologue room (on the PC) and by the title screen when the
## prologue is skipped. Emits `completed` with the answers; begin_run() starts it.

signal completed(result: Dictionary)
signal canceled

const SYNC_TIME := 2.4

var _steps: Array[Control] = []
var _step := 0
var _name_edit: LineEdit
var _difficulty: OptionButton
var _ironman: CheckBox
var _warning: Label
var _friend_edit: LineEdit
var _answers: Dictionary = {}
var _sync_lines: VBoxContainer
var _sync_bar: ProgressBar
var _sync: Tween
var _flash: ColorRect
var _done := false


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.92)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	UIStyle.apply(panel)
	UIStyle.fit_to_screen(panel, Vector2(640, 0))
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	panel.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)
	var head := Label.new()
	head.text = "%s  ·  Closed Test Client" % StoryLibrary.GAME_NAME.to_upper()
	head.add_theme_font_size_override("font_size", 14)
	head.modulate = Color(1, 1, 1, 0.55)
	root.add_child(head)

	_steps.append(_build_tester())
	for q in StoryLibrary.SETUP_QUESTIONS:
		_steps.append(_build_question(q))
	_steps.append(_build_trust())
	_steps.append(_build_sync())
	for s in _steps:
		root.add_child(s)

	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_flash)


## Starts the client from the first screen.
func open() -> void:
	_answers.clear()
	_done = false
	_name_edit.text = "Climber"
	_friend_edit.text = ""
	_warning.text = ""
	_flash.color.a = 0.0
	show()
	_go(0)
	_name_edit.select_all.call_deferred()


func step() -> int:
	return _step


func _go(i: int) -> void:
	_step = clampi(i, 0, _steps.size() - 1)
	for j in _steps.size():
		_steps[j].visible = j == _step
	var focus := _steps[_step].find_children("*", "BaseButton", true, false)
	if _step == 0:
		_focus(_name_edit)
	elif _step == _steps.size() - 2:
		_focus(_friend_edit)
	elif not focus.is_empty():
		_focus(focus[0])
	if _step == _steps.size() - 1:
		_start_sync()


## Focus after this frame, if the control is still on screen by then.
func _focus(c: Control) -> void:
	var ref: WeakRef = weakref(c)
	(func():
		var ctl: Control = ref.get_ref()
		if ctl and ctl.is_inside_tree() and ctl.is_visible_in_tree():
			ctl.grab_focus()).call_deferred()


func back() -> void:
	if _step == _steps.size() - 1:
		return   # can't stop the sync
	if _step == 0:
		hide()
		canceled.emit()
	else:
		_go(_step - 1)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		back()


# ---------- Screens ----------

func _page(title: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	var l := Label.new()
	l.text = title
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", UITheme.color("accent"))
	box.add_child(l)
	return box


func _buttons_row(box: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	return row


func _button(row: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	row.add_child(b)
	return b


func _build_tester() -> Control:
	var box := _page("Tester registration")
	var l := Label.new()
	l.text = "Tester name (up to %d characters)" % CharacterData.NAME_MAX_LENGTH
	box.add_child(l)
	_name_edit = LineEdit.new()
	_name_edit.max_length = CharacterData.NAME_MAX_LENGTH
	_name_edit.text_submitted.connect(func(_t): confirm_name())
	box.add_child(_name_edit)
	var picks := difficulty_picker(box)
	_difficulty = picks[0]
	_ironman = picks[1]
	_warning = Label.new()
	_warning.modulate = Color(1, 0.75, 0.4)
	box.add_child(_warning)
	var row := _buttons_row(box)
	_button(row, "Back", back)
	_button(row, "Next", confirm_name)
	return box


func confirm_name() -> bool:
	var cleaned := CharacterData.clean_name(_name_edit.text)
	if cleaned.is_empty():
		_warning.text = "Please enter a name."
		return false
	_name_edit.text = cleaned
	_warning.text = ""
	_go(1)
	return true


func _build_question(q: Dictionary) -> Control:
	var box := _page(q.text)
	for o in q.options:
		var b := Button.new()
		b.text = "▸ %s   (%s)" % [o.text, StoryLibrary.option_hint(o)]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(answer.bind(q.id, o.id))
		box.add_child(b)
	var row := _buttons_row(box)
	_button(row, "Back", back)
	return box


## Picks an answer on the current question screen and moves on.
func answer(question: StringName, option: StringName) -> void:
	_answers[question] = option
	_go(_step + 1)


func _build_trust() -> Control:
	var box := _page("Name the person you trust most.")
	var hint := Label.new()
	hint.text = "(This will be your childhood friend.)"
	hint.modulate = Color(1, 1, 1, 0.55)
	box.add_child(hint)
	_friend_edit = LineEdit.new()
	_friend_edit.max_length = CharacterData.NAME_MAX_LENGTH
	_friend_edit.placeholder_text = "Leave blank for %s" % GameState.CHILDHOOD_FRIEND_NAME
	_friend_edit.text_submitted.connect(func(_t): confirm_friend())
	box.add_child(_friend_edit)
	var row := _buttons_row(box)
	_button(row, "Back", back)
	_button(row, "Use \"%s\"" % GameState.CHILDHOOD_FRIEND_NAME, func():
		_friend_edit.text = GameState.CHILDHOOD_FRIEND_NAME
		confirm_friend()).tooltip_text = "You can rename them later from the party menu."
	_button(row, "Confirm", confirm_friend)
	return box


func confirm_friend() -> void:
	_go(_steps.size() - 1)


func _build_sync() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_sync_lines = VBoxContainer.new()
	_sync_lines.add_theme_constant_override("separation", 6)
	box.add_child(_sync_lines)
	_sync_bar = ProgressBar.new()
	_sync_bar.max_value = 1.0
	_sync_bar.show_percentage = false
	_sync_bar.custom_minimum_size.y = 14
	box.add_child(_sync_bar)
	return box


func _sync_line(text: String, glitch := false) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", Color(1, 0.35, 0.4) if glitch else UITheme.color("accent"))
	_sync_lines.add_child(l)
	return l


## [ Tester confirmed. ] -> [ Synchronising... ] -> (glitch) [ Welcome home. ]
func _start_sync() -> void:
	for c in _sync_lines.get_children():
		c.queue_free()
	_sync_bar.value = 0.0
	_sync_line("[ Tester confirmed. ]")
	Audio.play_sfx(["system_line", "notice"])
	if _sync:
		_sync.kill()
	_sync = create_tween()
	_sync.tween_interval(0.5)
	_sync.tween_callback(func(): _sync_line("[ Synchronising... ]"))
	_sync.tween_property(_sync_bar, "value", 1.0, SYNC_TIME * 0.5)
	_sync.tween_callback(func():
		var l := _sync_line("[ Welcome home. ]", true)
		Audio.play_sfx(["system_glitch", "notice"])
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		l.text = DialogueBox.scramble(l.text, rng))
	_sync.tween_interval(0.35)
	_sync.tween_callback(func():
		var last: Label = _sync_lines.get_child(_sync_lines.get_child_count() - 1)
		last.text = "[ Welcome home. ]")
	_sync.tween_interval(0.6)
	_sync.tween_property(_flash, "color:a", 1.0, 0.4)
	_sync.tween_callback(finish)


## Ends the client (the sync sequence calls this; tests can call it early).
func finish() -> void:
	if _done:
		return
	_done = true
	if _sync:
		_sync.kill()
	completed.emit(result())


func result() -> Dictionary:
	return {
		"name": _name_edit.text,
		"friend": _friend_edit.text,
		"difficulty": _difficulty.get_selected_id(),
		"ironman": _ironman.button_pressed,
		"answers": _answers.duplicate(),
	}


## Starts the run from the client's answers in `slot`. `flags` = things done
## in the prologue room (StoryLibrary.PROLOGUE_OBJECTS).
static func begin_run(r: Dictionary, slot: int, flags: Array = []) -> void:
	GameState.start_new_game(r.get("name", ""), r.get("friend", ""), slot,
		r.get("difficulty", Difficulty.DEFAULT), r.get("ironman", false))
	GameState.apply_setup(r.get("answers", {}), flags)


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
