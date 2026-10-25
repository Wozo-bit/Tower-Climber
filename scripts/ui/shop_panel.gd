class_name ShopPanel
extends Control
## A trader's shop: the rest-floor merchant (ItemLibrary.SHOPS, run by the
## guild that owns the floor), another trader like the black market, or a
## guild's members-only stock. Buy and Sell tabs; prices follow your route,
## blessings, the guild and supply and demand in this territory.

signal closed

## Which ItemLibrary.SHOPS entry is open (ignored for a guild shop).
var shop_id: StringName = &"merchant"
## Set when this is a guild's members' shop.
var guild_id: StringName = &""
var _selling := false
var _title: Label
var _greet: Label
var _run_by: Label
var _tabs: HBoxContainer
var _buy_tab: Button
var _sell_tab: Button
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
	panel.custom_minimum_size = Vector2(620, 0)
	UIStyle.apply(panel)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 24)
	box.add_child(_title)
	_greet = Label.new()
	_greet.modulate = Color(1, 1, 1, 0.7)
	box.add_child(_greet)
	_run_by = Label.new()
	_run_by.add_theme_font_size_override("font_size", 13)
	_run_by.modulate = Color(0.8, 0.85, 1.0, 0.8)
	box.add_child(_run_by)
	_tabs = HBoxContainer.new()
	box.add_child(_tabs)
	_buy_tab = Button.new()
	_buy_tab.text = "Buy"
	_buy_tab.toggle_mode = true
	_buy_tab.pressed.connect(func(): _selling = false; _message.text = ""; _rebuild())
	_tabs.add_child(_buy_tab)
	_sell_tab = Button.new()
	_sell_tab.text = "Sell"
	_sell_tab.toggle_mode = true
	_sell_tab.pressed.connect(func(): _selling = true; _message.text = ""; _rebuild())
	_tabs.add_child(_sell_tab)
	_gold = Label.new()
	box.add_child(_gold)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 300
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_message = Label.new()
	box.add_child(_message)
	var close_btn := Button.new()
	close_btn.text = "Leave"
	close_btn.pressed.connect(close)
	box.add_child(close_btn)


func open(id: StringName = &"merchant") -> void:
	guild_id = &""
	shop_id = id if ItemLibrary.SHOPS.has(id) else &"merchant"
	var shop: Dictionary = ItemLibrary.SHOPS[shop_id]
	_title.text = shop.name
	_greet.text = shop.greet
	var owner := GameState.guilds.owner_of_floor(GameState.floor_number)
	_run_by.text = "Run by %s · tax %d%% on battle gold here" % [GuildLibrary.guild_name(owner),
		roundi(GameState.guilds.tax_rate(GameState.floor_number) * 100)] if shop_id == &"merchant" else ""
	_tabs.visible = true
	_open()


## A guild's members-only stock (unlocks more as you rank up).
func open_guild(id: StringName) -> void:
	guild_id = id
	var g := GuildLibrary.get_guild(id)
	_title.text = "%s: members' stock" % g.get("name", "?")
	_greet.text = g.get("motto", "")
	_run_by.text = "Your rank: %s (%d%% members' discount)" % [GuildLibrary.rank_name(GameState.guilds.rank),
		roundi(GuildLibrary.RANK_DISCOUNT[GameState.guilds.rank] * 100)]
	_tabs.visible = false
	_open()


func _open() -> void:
	_selling = false
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


## What this trader charges for `item` right now.
static func price_of(shop: StringName, item: ItemDef) -> int:
	var prices: Dictionary = ItemLibrary.SHOPS.get(shop, {}).get("prices", {})
	return prices.get(item.id, GameState.shop_price(item))


## A guild shop's price: the item's price x the guild's markup x your discount.
static func guild_price(id: StringName, item: ItemDef) -> int:
	var g := GuildLibrary.get_guild(id)
	return roundi(item.price * g.get("price_mult", 1.0) * (1.0 - GuildLibrary.RANK_DISCOUNT[GameState.guilds.rank]))


## Items in a guild's members' stock at your rank.
static func guild_stock(id: StringName) -> Array:
	var out := []
	var stock: Dictionary = GuildLibrary.get_guild(id).get("stock", {})
	for r in stock:
		if r <= GameState.guilds.rank:
			for item in stock[r]:
				if not out.has(item):
					out.append(item)
	return out


func _rebuild() -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	_buy_tab.button_pressed = not _selling
	_sell_tab.button_pressed = _selling
	_gold.text = "Gold: %d" % GameState.player.gold
	if _selling:
		_rebuild_sell()
		return
	var stock: Array = guild_stock(guild_id) if guild_id != &"" else ItemLibrary.SHOPS[shop_id].stock
	for id in stock:
		var item := ItemLibrary.get_item(id)
		var price := guild_price(guild_id, item) if guild_id != &"" else price_of(shop_id, item)
		var b := _row("%s — %s  (have %d)" % [item.display_name, item.description, GameState.inventory.count(id)])
		var full := not GameState.inventory.has_room(id)
		b.text = ("Max %d" % item.max_carry) if full else ("Buy %dg" % price)
		b.disabled = full or GameState.player.gold < price
		b.pressed.connect(func():
			if GameState.buy_item(id, price):
				_message.text = "Bought a %s." % item.display_name
				Audio.play_sfx(["buy", "coin"])
			_rebuild())
		# Theft: one try per floor, at traders (not your own guild's shop).
		if guild_id == &"" and not full:
			var steal := Button.new()
			steal.text = "Steal (%d%%)" % roundi(GuildState.steal_chance(GameState.player) * 100)
			steal.tooltip_text = "Pocket it for free. If you're caught, this floor's guild will hunt you for a while."
			steal.disabled = not GameState.guilds.can_steal()
			steal.pressed.connect(func():
				match GameState.steal_item(id):
					"stolen":
						_message.text = "You slipped a %s into your pack." % item.display_name
						Audio.play_sfx("steal")
					"caught":
						Audio.play_sfx(["caught", "alarm"])
						_message.text = "Caught! The trader shouts for the guards."
						close()
						return
				_rebuild())
			b.get_parent().add_child(steal)


func _rebuild_sell() -> void:
	var any := false
	for g: GearItem in GameState.inventory.gear.duplicate():
		var price := GameState.sell_price_gear(g)
		if price <= 0:
			continue
		any = true
		var b := _row(g.summary())
		b.text = "Sell %dg" % price
		b.pressed.connect(func():
			var got := GameState.sell_gear(g)
			if got > 0:
				_message.text = "Sold %s for %d gold." % [g.display_name, got]
				Audio.play_sfx(["sell", "coin"])
			_rebuild())
	for item in GameState.inventory.owned():
		var price := GameState.sell_price_item(item.id)
		if price <= 0:
			continue
		any = true
		var b := _row("%s  (have %d)" % [item.display_name, GameState.inventory.count(item.id)])
		b.text = "Sell %dg" % price
		b.pressed.connect(func():
			var got := GameState.sell_item(item.id)
			if got > 0:
				_message.text = "Sold a %s for %d gold." % [item.display_name, got]
				Audio.play_sfx(["sell", "coin"])
			_rebuild())
	if not any:
		var l := Label.new()
		l.text = "Nothing to sell. (Equipped gear, Uniques and quest items can't be sold.)"
		l.modulate = Color(1, 1, 1, 0.6)
		_list.add_child(l)
	else:
		var hint := Label.new()
		hint.text = "Selling a lot of one thing here lowers what traders pay for it. Prices recover as you climb."
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.modulate = Color(1, 1, 1, 0.5)
		_list.add_child(hint)


## Adds a row with a label and an action button; returns the button.
func _row(text: String) -> Button:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 420
	row.add_child(l)
	var b := Button.new()
	row.add_child(b)
	_list.add_child(row)
	return b
