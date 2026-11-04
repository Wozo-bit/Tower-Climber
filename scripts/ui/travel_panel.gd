class_name TravelPanel
extends Control
## Campfire -> Travel: go back to any floor you've climbed (Hayden 2026-11-04),
## for unfinished quests or your guild's floors. Plain floors fill with enemies
## again; beaten guardians stay dead. See GameState.travel_to_floor.

signal travel_chosen(floor_n: int)
signal closed

var _list: VBoxContainer
var _title: Label


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	UIStyle.apply(panel)
	UIStyle.fit_to_screen(panel, Vector2(620, 520))
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)
	_title = Label.new()
	_title.text = "Travel to which floor?"
	_title.add_theme_font_size_override("font_size", 22)
	root.add_child(_title)
	var note := Label.new()
	note.text = "Plain floors fill with enemies again. Beaten guardians stay dead."
	note.modulate = Color(1, 1, 1, 0.6)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(note)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	var stay := Button.new()
	stay.text = "Stay here"
	stay.pressed.connect(close)
	root.add_child(stay)


func open() -> void:
	_rebuild()
	show()


func close() -> void:
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


## "Floor 12  ·  rest  ·  Stormhammer Company (your guild)".
static func floor_line(n: int) -> String:
	var parts: PackedStringArray = ["Floor %d" % n]
	if GameState.is_rest_floor(n):
		parts.append("rest floor")
	elif StageLibrary.is_boss_floor(n):
		parts.append("boss" if not GameState.guardian_beaten(n) else "boss beaten")
	elif StageLibrary.is_miniboss_floor(n):
		parts.append("miniboss" if not GameState.guardian_beaten(n) else "miniboss beaten")
	var owner := GameState.guilds.owner_of_floor(n)
	if owner != &"":
		var mine := owner == GameState.guilds.member or owner == GuildLibrary.PLAYER_GUILD
		parts.append(GuildLibrary.guild_name(owner) + (" (your guild)" if mine else ""))
	return "  ·  ".join(parts)


func _rebuild() -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	var first: Button = null
	for n in range(GameState.highest_floor, 0, -1):
		var b := Button.new()
		b.text = floor_line(n)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = n == GameState.floor_number
		b.pressed.connect(func():
			hide()
			travel_chosen.emit(n))
		_list.add_child(b)
		if first == null and not b.disabled:
			first = b
	if first:
		first.grab_focus.call_deferred()
