class_name SettingsPanel
extends Control
## Settings overlay, used by the title screen and the pause menu.
## Changes apply immediately and save when you press Back.

signal closed
var _skip_check: CheckBox
var _skip_warning: ConfirmationDialog

var _controls: ControlsPanel
var _keys_note: Label


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
	panel.custom_minimum_size = Vector2(460, 0)
	UIStyle.apply(panel)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)

	_add_slider(box, "Master volume", "master_volume")
	_add_slider(box, "Music volume", "music_volume")
	_add_slider(box, "Sound effects", "sfx_volume")
	_add_check(box, "Fullscreen", "fullscreen")
	var sizes := []
	for s in Settings.WINDOW_SIZES:
		sizes.append("%d x %d" % [s.x, s.y])
	_add_picker(box, "Window size", sizes, Settings.window_size, func(i): Settings.window_size = i,
		"Used when not in fullscreen.")
	var scales := Settings.UI_SCALES.map(func(s): return "%d%%" % roundi(s * 100))
	_add_picker(box, "Interface size", scales, Settings.UI_SCALES.find(Settings.ui_scale),
		func(i): Settings.ui_scale = Settings.UI_SCALES[i], "Makes menus and text bigger or smaller.")
	_add_check(box, "V-Sync", "vsync")
	_add_theme_picker(box)
	var story_row := HBoxContainer.new()   # one row, so the panel stays short
	story_row.add_theme_constant_override("separation", 24)
	box.add_child(story_row)
	_add_check(story_row, "Cut-in splashes", "cutins")
	_add_skip_scenes(story_row)
	var tips_row := HBoxContainer.new()
	box.add_child(tips_row)
	_add_check(tips_row, "Tutorial tips", "tips")
	var reset := Button.new()
	reset.text = "Show all tips again"
	reset.tooltip_text = "Forget which tips you've seen, so each shows again when it comes up."
	reset.pressed.connect(func():
		Tips.reset()
		reset.text = "Tips reset")
	tips_row.add_child(reset)
	tips_row.add_theme_constant_override("separation", 16)
	_add_check(tips_row, "God blessing offers", "god_offers")
	tips_row.get_child(-1).tooltip_text = "Off: gods never offer you a blessing, so there's nothing to refuse. Nobody curses you for it, and nobody gifts you a skill. The story still plays."

	var controls_btn := Button.new()
	controls_btn.text = "Controls..."
	controls_btn.tooltip_text = "Change the keys."
	controls_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	controls_btn.pressed.connect(func(): _controls.open())
	box.add_child(controls_btn)
	_keys_note = Label.new()
	_keys_note.modulate = Color(1, 1, 1, 0.5)
	_keys_note.add_theme_font_size_override("font_size", 14)
	_keys_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_keys_note)

	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(close)
	box.add_child(back)

	_controls = ControlsPanel.new()
	_controls.closed.connect(_refresh_keys_note)
	add_child(_controls)
	_refresh_keys_note()


func open() -> void:
	_refresh_keys_note()
	show()


func _refresh_keys_note() -> void:
	var k := Settings.keys
	_keys_note.text = "%s / %s / %s / %s move · %s party · %s pause" % [
		InputBindings.key_name("move_up"), InputBindings.key_name("move_left"), InputBindings.key_name("move_down"),
		InputBindings.key_name("move_right"), InputBindings.keys_text(k, "party_menu"), InputBindings.keys_text(k, "pause")]


func close() -> void:
	Settings.save_settings()
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and not _controls.visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close()


func _add_slider(parent: Node, label: String, prop: String) -> void:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = label
	l.custom_minimum_size.x = 160
	row.add_child(l)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = Settings.get(prop)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pct := Label.new()
	pct.custom_minimum_size.x = 48
	pct.text = "%d%%" % roundi(slider.value * 100)
	slider.value_changed.connect(func(v):
		Settings.set(prop, v)
		pct.text = "%d%%" % roundi(v * 100)
		Settings.apply())
	row.add_child(slider)
	row.add_child(pct)
	parent.add_child(row)


func _add_check(parent: Node, label: String, prop: String) -> void:
	var cb := CheckBox.new()
	cb.text = label
	cb.button_pressed = Settings.get(prop)
	cb.toggled.connect(func(on):
		Settings.set(prop, on)
		Settings.apply())
	parent.add_child(cb)


## "Skip the prologue" also skips the story's later visits home, so turning it
## on asks first (Hayden 2026-11-04).
func _add_skip_scenes(parent: Node) -> void:
	_skip_check = CheckBox.new()
	_skip_check.text = "Skip the prologue and home scenes"
	_skip_check.tooltip_text = "New Game goes straight to character setup, and you won't return to your room at story milestones."
	_skip_check.button_pressed = Settings.skip_prologue
	parent.add_child(_skip_check)
	_skip_warning = ConfirmationDialog.new()
	_skip_warning.title = "Skip these scenes?"
	_skip_warning.dialog_text = "This skips the opening room AND the later story scenes back in your room, including what happens right after them.\nYou'd miss part of the story.\n\nSkip them anyway?"
	_skip_warning.dialog_autowrap = true
	_skip_warning.min_size = Vector2i(460, 0)
	_skip_warning.ok_button_text = "Skip them"
	_skip_warning.cancel_button_text = "Keep them"
	_skip_warning.confirmed.connect(func(): _set_skip_scenes(true))
	_skip_warning.canceled.connect(func(): _skip_check.set_pressed_no_signal(false))
	add_child(_skip_warning)
	_skip_check.toggled.connect(func(on: bool):
		if on:
			_skip_warning.popup_centered()
		else:
			_set_skip_scenes(false))


func _set_skip_scenes(on: bool) -> void:
	Settings.skip_prologue = on
	_skip_check.set_pressed_no_signal(on)
	Settings.apply()


## A labelled dropdown that applies at once.
func _add_picker(parent: Node, label: String, items: Array, selected: int, on_pick: Callable, tip := "") -> void:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = label
	l.custom_minimum_size.x = 160
	row.add_child(l)
	var opt := OptionButton.new()
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt.tooltip_text = tip
	for it in items:
		opt.add_item(it)
	opt.selected = maxi(0, selected)
	opt.item_selected.connect(func(i):
		on_pick.call(i)
		Settings.apply())
	row.add_child(opt)
	parent.add_child(row)


## The menu colour scheme (UITheme palettes); changes the whole game at once.
func _add_theme_picker(parent: Node) -> void:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = "Interface style"
	l.custom_minimum_size.x = 160
	row.add_child(l)
	var opt := OptionButton.new()
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ids := UITheme.ids()
	for id in ids:
		opt.add_item(UITheme.PALETTES[id].name)
	opt.selected = maxi(0, ids.find(Settings.ui_theme))
	opt.item_selected.connect(func(i):
		Settings.ui_theme = ids[i]
		Settings.apply())
	row.add_child(opt)
	parent.add_child(row)
