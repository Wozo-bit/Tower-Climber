extends CanvasLayer
## Autoload "CutIns": full-screen manhwa-style splashes (boss name cards,
## ultimate skills, gods appearing, LEVEL UP, class changes, wars). Lives
## above every scene, so anything can call CutIns.play(CutInData.xxx(...)).
## Splashes queue up and play one after another; click or press a key to
## skip. Turned off with Settings.cutins.

## The queue ran dry (await this after play() if you need to wait).
signal finished

const LAYER := 90
const SLIDE_SEC := 0.22
const BAND_HEIGHT := 250.0

var _queue: Array = []
var _playing := false
var _tween: Tween

var _root: Control
var _dim: ColorRect
var _band: Control
var _band_bg: ColorRect
var _line_top: ColorRect
var _line_bottom: ColorRect
var _art: TextureRect
var _glyph: Label
var _title: Label
var _subtitle: Label


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


## Queues a splash. Does nothing if cut-ins are turned off.
func play(data: Dictionary) -> void:
	if not Settings.cutins or data.is_empty():
		return
	_queue.append(data)
	if not _playing:
		_next()


func is_playing() -> bool:
	return _playing


## Ends the current splash and drops the rest of the queue.
func skip_all() -> void:
	_queue.clear()
	if _tween:
		_tween.kill()
	_end()


func _next() -> void:
	if _queue.is_empty():
		_end()
		return
	_playing = true
	var d: Dictionary = _queue.pop_front()
	var col: Color = d.get("color", UITheme.color("accent"))
	_title.text = d.get("title", "")
	_title.add_theme_color_override("font_color", col)
	_subtitle.text = d.get("subtitle", "")
	_line_top.color = col
	_line_bottom.color = col
	var bg := UITheme.color("panel")
	bg.a = 0.94
	_band_bg.color = bg
	var tex: Texture2D = d.get("art")
	_art.texture = tex
	_art.visible = tex != null
	_glyph.visible = tex == null
	_glyph.text = d.get("glyph", "✦")
	_glyph.add_theme_color_override("font_color", col)
	Audio.play_sfx(["cutin_%s" % d.get("kind", ""), "cutin"], 0.0)

	_root.show()
	var w := _root.get_viewport_rect().size.x
	_band.position.x = w
	_dim.modulate.a = 0.0
	_title.position.x = -120.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_dim, "modulate:a", 1.0, SLIDE_SEC)
	_tween.tween_property(_band, "position:x", 0.0, SLIDE_SEC).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_title, "position:x", 0.0, SLIDE_SEC * 1.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.chain().tween_interval(d.get("duration", CutInData.DURATION))
	_tween.chain().tween_property(_band, "position:x", -w, SLIDE_SEC).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.parallel().tween_property(_dim, "modulate:a", 0.0, SLIDE_SEC)
	_tween.chain().tween_callback(_next)


func _end() -> void:
	var was := _playing
	_playing = false
	_root.hide()
	if was:
		finished.emit()


func _input(event: InputEvent) -> void:
	if not _playing:
		return
	var skip: bool = (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventKey and event.pressed and not event.echo)
	if skip:
		get_viewport().set_input_as_handled()
		if _tween:
			_tween.kill()
		_next()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.hide()
	add_child(_root)
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.6)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_dim)

	# The band: a full-width strip across the middle that slides through.
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_HCENTER_WIDE)
	holder.offset_top = -BAND_HEIGHT / 2
	holder.offset_bottom = BAND_HEIGHT / 2
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(holder)
	_band = Control.new()
	_band.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_band.clip_contents = true
	_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(_band)
	_band_bg = ColorRect.new()
	_band_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_band_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_band.add_child(_band_bg)
	_line_top = _edge_line(Control.PRESET_TOP_WIDE)
	_line_bottom = _edge_line(Control.PRESET_BOTTOM_WIDE)

	# Art on the left (fills the band's height), or a big glyph without art.
	_art = TextureRect.new()
	_art.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	_art.offset_right = 420
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_band.add_child(_art)
	_glyph = Label.new()
	_glyph.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	_glyph.offset_left = 60
	_glyph.offset_right = 360
	_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_glyph.add_theme_font_size_override("font_size", 150)
	_glyph.modulate.a = 0.85
	_band.add_child(_glyph)

	var text_box := VBoxContainer.new()
	text_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	text_box.offset_left = 440
	text_box.offset_right = -60
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_band.add_child(text_box)
	var title_holder := Control.new()   # lets the title slide inside the box
	title_holder.custom_minimum_size.y = 72
	text_box.add_child(title_holder)
	_title = Label.new()
	_title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title.add_theme_font_size_override("font_size", 54)
	_title.add_theme_color_override("font_outline_color", Color.BLACK)
	_title.add_theme_constant_override("outline_size", 10)
	title_holder.add_child(_title)
	_subtitle = Label.new()
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.add_theme_font_size_override("font_size", 22)
	_subtitle.add_theme_color_override("font_outline_color", Color.BLACK)
	_subtitle.add_theme_constant_override("outline_size", 6)
	text_box.add_child(_subtitle)


func _edge_line(preset: int) -> ColorRect:
	var line := ColorRect.new()
	line.set_anchors_and_offsets_preset(preset)
	if preset == Control.PRESET_TOP_WIDE:
		line.offset_bottom = 3
	else:
		line.offset_top = -3
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_band.add_child(line)
	return line
