class_name UnitCard
extends PanelContainer
## One combatant standing on the battlefield (FF-style): a small sprite (art
## or a coloured placeholder), name, HP bar and statuses. Enemies also show
## their intent and what the bestiary knows; party members show "⚠ Targeted".
## Full HP/MP numbers for the party are in the menu window's status list.
## Clickable when highlighted as a valid target.

signal clicked(unit: Combatant)

enum Highlight { NONE, ACTIVE, TARGETABLE, DIMMED }

const COLOR_ACTIVE := Color(1.0, 0.85, 0.3)
const COLOR_TARGET := Color(0.4, 0.9, 1.0)
## Token width, and the sprite's size (art from assets/art/enemies, portraits).
const WIDTH := 116
const SPRITE_SIZE := Vector2(40, 34)
const ART_HEIGHT := 48

var unit: Combatant
var _style := StyleBoxFlat.new()
var _sprite: ColorRect
## Art hook: the enemy's / member's picture, shown instead of the colour block.
var _art: TextureRect
var _name: Label
var _hp_bar: ProgressBar
var _hp_label: Label
var _status: Label
var _intent: Label
## Enemies: what the bestiary knows ("Weak: Fire").
var _known: Label
var _highlight: int = Highlight.NONE


func _init(p_unit: Combatant) -> void:
	unit = p_unit
	custom_minimum_size = Vector2(WIDTH, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Mostly see-through so the backdrop shows: units stand on the field.
	_style.bg_color = Color(0, 0, 0, 0.25)
	_style.set_border_width_all(2)
	_style.border_color = Color(0, 0, 0, 0)
	_style.set_corner_radius_all(6)
	_style.set_content_margin_all(4)
	add_theme_stylebox_override("panel", _style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)

	var tex := Assets.combatant_art(unit)
	if tex:
		_art = TextureRect.new()
		_art.texture = tex
		_art.custom_minimum_size = Vector2(0, ART_HEIGHT)
		_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_art.flip_h = unit.side == Combatant.Side.PARTY   # the party faces left, at the enemies
		_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(_art)
	else:
		var holder := CenterContainer.new()
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(holder)
		_sprite = ColorRect.new()
		_sprite.custom_minimum_size = SPRITE_SIZE
		_sprite.color = unit.color
		_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(_sprite)

	_name = _small(13)
	_name.text = unit.display_name
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name.custom_minimum_size.x = WIDTH - 8
	_name.add_theme_color_override("font_outline_color", Color.BLACK)
	_name.add_theme_constant_override("outline_size", 3)
	box.add_child(_name)

	_hp_bar = _make_bar(Color(0.8, 0.25, 0.25))
	box.add_child(_hp_bar)
	if unit.side == Combatant.Side.ENEMY:   # party numbers live in the status list
		_hp_label = _small(11)
		_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(_hp_label)

	_status = _small(10)
	_status.modulate = Color(0.8, 0.8, 1.0)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size.x = WIDTH - 8
	box.add_child(_status)

	# Enemy intent ("Smash → Cassia") or, on party members, "⚠ Targeted".
	_intent = _small(11)
	_intent.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_intent.custom_minimum_size.x = WIDTH - 8
	box.add_child(_intent)

	if unit.side == Combatant.Side.ENEMY:
		_known = _small(10)
		_known.add_theme_color_override("font_color", Color(1.0, 0.6, 0.4))
		_known.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_known.custom_minimum_size.x = WIDTH - 8
		box.add_child(_known)

	gui_input.connect(_on_gui_input)
	refresh()


func _small(size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _make_bar(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 6)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.08, 0.1)
	bar.add_theme_stylebox_override("background", bg)
	return bar


func refresh() -> void:
	_hp_bar.max_value = unit.max_hp
	_hp_bar.value = unit.hp
	if _hp_label:
		_hp_label.text = "HP %d/%d" % [unit.hp, unit.max_hp]
	var tags: PackedStringArray = []
	for id in unit.statuses:
		tags.append("%s(%d)" % [String(id).capitalize(), unit.statuses[id]])
	if unit.side == Combatant.Side.ENEMY and unit.is_alive() and unit.stagger > 0:
		tags.append("Stagger %d/%d" % [unit.stagger, unit.stagger_max])
	_status.text = " ".join(tags)
	_status.visible = _status.text != ""   # empty lines would still take up height
	if unit.is_alive():
		if _sprite:
			_sprite.color = unit.color   # also restores colour after a revive
		if _art:
			_art.modulate = Color.WHITE
	else:
		if _sprite:
			_sprite.color = Color(0.2, 0.2, 0.2)
		if _art:
			_art.modulate = Color(0.3, 0.3, 0.3)
	set_highlight(_highlight)


func set_highlight(h: int) -> void:
	_highlight = h
	match h:
		Highlight.ACTIVE:
			_style.border_color = COLOR_ACTIVE
		Highlight.TARGETABLE:
			_style.border_color = COLOR_TARGET
		_:
			_style.border_color = Color(0, 0, 0, 0)
	if unit.is_alive():
		modulate = Color(1, 1, 1, 0.45) if h == Highlight.DIMMED else Color.WHITE
	elif h == Highlight.TARGETABLE:
		modulate = Color(1, 1, 1, 0.8)   # downed ally being targeted by a revive
	else:
		modulate = Color(1, 1, 1, 0.3)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if h == Highlight.TARGETABLE else Control.CURSOR_ARROW


func popup(text: String, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 5)
	l.top_level = true
	l.global_position = global_position + Vector2(size.x * 0.25, 4)
	add_child(l)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "global_position:y", l.global_position.y - 32, 0.8)
	tw.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tw.chain().tween_callback(l.queue_free)


func _on_gui_input(event: InputEvent) -> void:
	if _highlight == Highlight.TARGETABLE and event is InputEventMouseButton \
			and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(unit)


## "Weak: Fire · Resists: Water" from the bestiary ("Weaknesses: ?" if nothing's known).
func set_known(text: String) -> void:
	if _known:
		_known.text = text if text != "" else "Weaknesses: ?"


func set_intent(text: String) -> void:
	_intent.text = text
	_intent.visible = text != ""
	_intent.add_theme_color_override("font_color", Color(1.0, 0.75, 0.45))


func set_threat(text: String) -> void:
	_intent.text = text
	_intent.visible = text != ""
	_intent.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))
