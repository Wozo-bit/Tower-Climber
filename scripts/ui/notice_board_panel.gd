class_name NoticeBoardPanel
extends Control
## Rest-floor notice board: hand-written jobs plus generated bounties for the
## stage ahead (QuestLog.board_offers). Take as many as you like; they go in
## Tab -> Quests and stay there until they're done.

signal closed

var _list: VBoxContainer
var _message: Label


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
	panel.custom_minimum_size = Vector2(640, 0)
	UIStyle.apply(panel)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	var title := Label.new()
	title.text = "Notice Board"
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	box.add_child(_list)
	_message = Label.new()
	_message.modulate = Color(0.7, 1, 0.75)
	box.add_child(_message)
	var close_btn := Button.new()
	close_btn.text = "Leave"
	close_btn.pressed.connect(close)
	box.add_child(close_btn)


func open() -> void:
	_message.text = ""
	_rebuild()
	show()


func close() -> void:
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _rebuild() -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	var offers := GameState.quests.board_offers(GameState.floor_number)
	if offers.is_empty():
		var none := Label.new()
		none.text = "Nothing new pinned up. Check the next rest floor."
		none.modulate = Color(1, 1, 1, 0.6)
		_list.add_child(none)
	for offer in offers:
		var q: Dictionary = offer.def
		var row := HBoxContainer.new()
		var l := Label.new()
		l.text = "%s\n%s\nReward: %s" % [q.title, q.get("desc", ""), reward_text(q.get("rewards", {}))]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		var b := Button.new()
		b.text = "Take job"
		b.pressed.connect(func():
			if GameState.quests.accept(offer):
				_message.text = "Added to your quest log: %s" % q.title
			_rebuild())
		row.add_child(b)
		_list.add_child(row)


## "200 gold, 150 XP" (what a quest pays, without handing it out).
static func reward_text(r: Dictionary) -> String:
	var parts: PackedStringArray = []
	if r.get("gold", 0) > 0:
		parts.append("%d gold" % r.gold)
	if r.get("xp", 0) > 0:
		parts.append("%d XP" % r.xp)
	for item in r.get("items", {}):
		parts.append("%s x%d" % [ItemLibrary.get_item(item).display_name, r.items[item]])
	if r.has("gear"):
		parts.append(r.gear.get("name", "gear"))
	if r.has("reveal_family"):
		parts.append("notes on %s" % EnemyFamilies.family_name(r.reveal_family))
	return ", ".join(parts) if not parts.is_empty() else "—"
