class_name StatAllocationPanel
extends PanelContainer
## Stat allocation UI. Points go into a PENDING pool first and only commit on
## Confirm — since respecs are limited, a misclick shouldn't cost the player.
## Built entirely in code so it can be dropped into any scene.

signal allocation_confirmed

var character: CharacterData
var _pending: Dictionary = {}   # Stats.Type -> int
var _rows: Dictionary = {}      # Stats.Type -> { value: Label, minus: Button, plus: Button }
var _points_label: Label
var _derived_label: Label
var _confirm_btn: Button
var _clear_btn: Button


func _init() -> void:
	custom_minimum_size = Vector2(420, 0)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Stats"
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)

	_points_label = Label.new()
	box.add_child(_points_label)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	box.add_child(grid)

	for stat in Stats.all():
		var name_label := Label.new()
		name_label.text = Stats.name_of(stat)
		name_label.tooltip_text = Stats.description_of(stat)
		name_label.mouse_filter = Control.MOUSE_FILTER_PASS
		name_label.custom_minimum_size.x = 120
		grid.add_child(name_label)

		var value_label := Label.new()
		value_label.custom_minimum_size.x = 110
		grid.add_child(value_label)

		var minus := Button.new()
		minus.text = " - "
		minus.pressed.connect(_change_pending.bind(stat, -1))
		grid.add_child(minus)

		var plus := Button.new()
		plus.text = " + "
		plus.pressed.connect(_change_pending.bind(stat, 1))
		grid.add_child(plus)

		_rows[stat] = { "value": value_label, "minus": minus, "plus": plus }

	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	_confirm_btn = Button.new()
	_confirm_btn.text = "Confirm"
	_confirm_btn.pressed.connect(_on_confirm)
	buttons.add_child(_confirm_btn)
	_clear_btn = Button.new()
	_clear_btn.text = "Clear pending"
	_clear_btn.pressed.connect(_clear_pending)
	buttons.add_child(_clear_btn)

	box.add_child(HSeparator.new())
	_derived_label = Label.new()
	box.add_child(_derived_label)

	_clear_pending_silent()


func bind(c: CharacterData) -> void:
	if character and character.stats_changed.is_connected(_refresh):
		character.stats_changed.disconnect(_refresh)
	character = c
	character.stats_changed.connect(_refresh)
	_clear_pending()


func pending_total() -> int:
	var sum := 0
	for stat in _pending:
		sum += _pending[stat]
	return sum


func _remaining() -> int:
	return character.unspent_points - pending_total() if character else 0


func _change_pending(stat: int, delta: int) -> void:
	if character == null:
		return
	if delta > 0 and _remaining() <= 0:
		return
	_pending[stat] = maxi(0, _pending[stat] + delta)
	_refresh()


func _clear_pending_silent() -> void:
	for stat in Stats.all():
		_pending[stat] = 0


func _clear_pending() -> void:
	_clear_pending_silent()
	_refresh()


func _on_confirm() -> void:
	if character and character.apply_allocation(_pending.duplicate()):
		_clear_pending()
		allocation_confirmed.emit()


func _refresh() -> void:
	if character == null:
		return
	# Clamp pending if points vanished (e.g. external change).
	if _remaining() < 0:
		_clear_pending_silent()

	var remaining := _remaining()
	_points_label.text = "Unspent points: %d" % remaining
	if pending_total() > 0:
		_points_label.text += "   (%d pending)" % pending_total()

	for stat in Stats.all():
		var row: Dictionary = _rows[stat]
		var total := character.stats.get_total(stat)
		var pend: int = _pending[stat]
		row.value.text = "%d" % total if pend == 0 else "%d  → %d" % [total, total + pend]
		row.value.modulate = Color(0.55, 1.0, 0.55) if pend > 0 else Color.WHITE
		row.minus.disabled = pend <= 0
		row.plus.disabled = remaining <= 0

	_confirm_btn.disabled = pending_total() == 0
	_clear_btn.disabled = pending_total() == 0

	var s := character.stats
	_derived_label.text = "Max HP: %d\nPhys DEF: %.1f   Mag DEF: %.1f\nDodge: %.1f%%   Crit: %.1f%%\nTurn priority: %d" % [
		s.max_hp(), s.physical_defense(), s.magic_defense(),
		s.dodge_chance() * 100.0, s.crit_chance() * 100.0, s.turn_priority()]
