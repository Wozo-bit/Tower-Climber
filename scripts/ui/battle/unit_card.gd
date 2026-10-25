class_name UnitCard
extends PanelContainer
## Visual for one combatant: placeholder sprite, name, HP/MP bars, statuses.
## Clickable when highlighted as a valid target.

signal clicked(unit: Combatant)

enum Highlight { NONE, ACTIVE, TARGETABLE, DIMMED }

const COLOR_ACTIVE := Color(1.0, 0.85, 0.3)
const COLOR_TARGET := Color(0.4, 0.9, 1.0)
## Height of the picture when the unit has art (assets/art/enemies, portraits).
const ART_HEIGHT := 64

var unit: Combatant
var _style := StyleBoxFlat.new()
var _sprite: ColorRect
## Art hook: the enemy's / member's picture, shown instead of the colour bar.
var _art: TextureRect
var _name: Label
var _hp_bar: ProgressBar
var _hp_label: Label
var _mp_bar: ProgressBar
var _status: Label
var _intent: Label
## Enemies: what the bestiary knows ("Weak: Fire").
var _known: Label
var _highlight: int = Highlight.NONE


func _init(p_unit: Combatant) -> void:
	unit = p_unit
	custom_minimum_size = Vector2(150, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_style.bg_color = UITheme.color("panel")
	_style.set_border_width_all(2)
	_style.border_color = _idle_border()
	_style.set_corner_radius_all(6)
	_style.set_content_margin_all(6)
	add_theme_stylebox_override("panel", _style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)

	_sprite = ColorRect.new()
	_sprite.custom_minimum_size = Vector2(0, 26)
	_sprite.color = unit.color
	_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_sprite)
	var tex := Assets.combatant_art(unit)
	if tex:
		_sprite.hide()
		_art = TextureRect.new()
		_art.texture = tex
		_art.custom_minimum_size = Vector2(0, ART_HEIGHT)
		_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(_art)

	_name = Label.new()
	_name.text = unit.display_name
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_name)

	_hp_bar = _make_bar(Color(0.8, 0.25, 0.25))
	box.add_child(_hp_bar)
	_hp_label = Label.new()
	_hp_label.add_theme_font_size_override("font_size", 12)
	_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_hp_label)

	if unit.side == Combatant.Side.PARTY:
		_mp_bar = _make_bar(Color(0.3, 0.5, 0.95))
		box.add_child(_mp_bar)

	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 12)
	_status.modulate = Color(0.8, 0.8, 1.0)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_status)

	# Enemy intent ("Smash → Cassia") or, on party cards, "⚠ Targeted".
	_intent = Label.new()
	_intent.add_theme_font_size_override("font_size", 12)
	_intent.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_intent.custom_minimum_size.x = 134
	_intent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_intent)

	if unit.side == Combatant.Side.ENEMY:
		_known = Label.new()
		_known.add_theme_font_size_override("font_size", 11)
		_known.add_theme_color_override("font_color", Color(1.0, 0.6, 0.4))
		_known.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_known.custom_minimum_size.x = 134
		_known.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(_known)

	gui_input.connect(_on_gui_input)
	refresh()


func _make_bar(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 8)
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
	_hp_label.text = "HP %d/%d" % [unit.hp, unit.max_hp]
	if _mp_bar:
		_mp_bar.max_value = maxi(unit.max_mp, 1)
		_mp_bar.value = unit.mp
		_hp_label.text += "   MP %d/%d" % [unit.mp, unit.max_mp]
	var tags: PackedStringArray = []
	for id in unit.statuses:
		tags.append("%s(%d)" % [String(id).capitalize(), unit.statuses[id]])
	if unit.side == Combatant.Side.ENEMY and unit.is_alive() and unit.stagger > 0:
		tags.append("Stagger %d/%d" % [unit.stagger, unit.stagger_max])
	_status.text = " ".join(tags)
	_status.visible = _status.text != ""   # empty lines would still take up height
	if unit.is_alive():
		_sprite.color = unit.color   # also restores colour after a revive
		if _art:
			_art.modulate = Color.WHITE
	else:
		modulate = Color(1, 1, 1, 0.3)
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
			_style.border_color = _idle_border()
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
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 5)
	l.top_level = true
	l.global_position = global_position + Vector2(size.x * 0.35, 4)
	add_child(l)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "global_position:y", l.global_position.y - 36, 0.8)
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


## The theme's border, faded, for cards that aren't highlighted.
static func _idle_border() -> Color:
	var c := UITheme.color("border")
	c.a = 0.35
	return c
