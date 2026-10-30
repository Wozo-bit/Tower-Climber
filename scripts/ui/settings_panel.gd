class_name SettingsPanel
extends Control
## Settings overlay, used by the title screen and the pause menu.
## Changes apply immediately and save when you press Back.

signal closed


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
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)

	_add_slider(box, "Master volume", "master_volume")
	_add_slider(box, "Music volume", "music_volume")
	_add_slider(box, "Sound effects", "sfx_volume")
	_add_check(box, "Fullscreen", "fullscreen")
	_add_check(box, "V-Sync", "vsync")
	_add_theme_picker(box)
	_add_check(box, "Cut-in splashes", "cutins")
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

	var note := Label.new()
	note.text = "Controls: WASD / arrows move · Tab party · Esc pause"
	note.modulate = Color(1, 1, 1, 0.5)
	box.add_child(note)

	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(close)
	box.add_child(back)


func open() -> void:
	show()


func close() -> void:
	Settings.save_settings()
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
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
