class_name ShopPanel
extends Control
## Rest-floor merchant. Sells ItemLibrary.SHOP_STOCK for the leader's gold.

signal closed

var _list: VBoxContainer
var _gold: Label
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
	panel.custom_minimum_size = Vector2(520, 0)
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
	title.text = "Merchant"
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	var greet := Label.new()
	greet.text = "\"Climbing, are we? You'll want these.\""
	greet.modulate = Color(1, 1, 1, 0.7)
	box.add_child(greet)
	_gold = Label.new()
	box.add_child(_gold)
	_list = VBoxContainer.new()
	box.add_child(_list)
	_message = Label.new()
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
		c.queue_free()
	_gold.text = "Gold: %d" % GameState.player.gold
	for id in ItemLibrary.SHOP_STOCK:
		var item := ItemLibrary.get_item(id)
		var row := HBoxContainer.new()
		var l := Label.new()
		l.text = "%s — %s  (have %d)" % [item.display_name, item.description, GameState.inventory.count(id)]
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 380
		row.add_child(l)
		var b := Button.new()
		var full := not GameState.inventory.has_room(id)
		b.text = ("Max %d" % item.max_carry) if full else ("Buy %dg" % item.price)
		b.disabled = full or GameState.player.gold < item.price
		b.pressed.connect(func():
			if GameState.buy_item(id):
				_message.text = "Bought a %s." % item.display_name
			_rebuild())
		row.add_child(b)
		_list.add_child(row)
