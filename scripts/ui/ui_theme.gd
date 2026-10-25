class_name UITheme
extends RefCounted
## The manhwa "system window" look: dark glassy panels with a glowing border.
## Built entirely in code (no art needed) and applied to the whole game as the
## root window's Theme, so every Button / Panel / Label picks it up.
##
## Players pick a palette in Settings (Settings.ui_theme). Add a palette by
## adding an entry to PALETTES with the same keys as system_blue.

const DEFAULT := &"system_blue"

## bg: screen background · panel: window fill · border/glow: the edge and its
## halo · text/dim: normal and faded text · accent: headings and highlights ·
## button/button_hover/button_pressed: button fills.
const PALETTES := {
	&"system_blue": {
		"name": "System Blue",
		"bg": Color(0.02, 0.04, 0.08), "panel": Color(0.03, 0.07, 0.14, 0.95),
		"border": Color(0.35, 0.78, 1.0), "glow": Color(0.15, 0.55, 1.0, 0.5),
		"text": Color(0.88, 0.95, 1.0), "dim": Color(0.55, 0.65, 0.78), "accent": Color(0.55, 0.9, 1.0),
		"button": Color(0.05, 0.12, 0.23), "button_hover": Color(0.09, 0.22, 0.4), "button_pressed": Color(0.14, 0.33, 0.55),
	},
	&"royal_gold": {
		"name": "Royal Gold",
		"bg": Color(0.05, 0.04, 0.02), "panel": Color(0.08, 0.06, 0.03, 0.95),
		"border": Color(0.95, 0.78, 0.35), "glow": Color(1.0, 0.7, 0.2, 0.42),
		"text": Color(1.0, 0.96, 0.86), "dim": Color(0.75, 0.68, 0.55), "accent": Color(1.0, 0.85, 0.45),
		"button": Color(0.15, 0.11, 0.05), "button_hover": Color(0.28, 0.2, 0.08), "button_pressed": Color(0.4, 0.29, 0.1),
	},
	&"crimson_pact": {
		"name": "Crimson Pact",
		"bg": Color(0.06, 0.02, 0.03), "panel": Color(0.1, 0.03, 0.05, 0.95),
		"border": Color(1.0, 0.32, 0.35), "glow": Color(0.9, 0.1, 0.15, 0.48),
		"text": Color(1.0, 0.9, 0.9), "dim": Color(0.75, 0.55, 0.57), "accent": Color(1.0, 0.5, 0.45),
		"button": Color(0.2, 0.05, 0.07), "button_hover": Color(0.35, 0.08, 0.11), "button_pressed": Color(0.5, 0.11, 0.15),
	},
	&"abyssal_violet": {
		"name": "Abyssal Violet",
		"bg": Color(0.04, 0.02, 0.07), "panel": Color(0.07, 0.04, 0.13, 0.95),
		"border": Color(0.72, 0.48, 1.0), "glow": Color(0.55, 0.25, 1.0, 0.48),
		"text": Color(0.95, 0.9, 1.0), "dim": Color(0.66, 0.58, 0.78), "accent": Color(0.82, 0.65, 1.0),
		"button": Color(0.13, 0.07, 0.24), "button_hover": Color(0.23, 0.12, 0.4), "button_pressed": Color(0.33, 0.17, 0.55),
	},
	&"jade_sect": {
		"name": "Jade Sect",
		"bg": Color(0.02, 0.06, 0.05), "panel": Color(0.03, 0.1, 0.08, 0.95),
		"border": Color(0.35, 0.95, 0.7), "glow": Color(0.1, 0.8, 0.55, 0.42),
		"text": Color(0.88, 1.0, 0.95), "dim": Color(0.55, 0.75, 0.67), "accent": Color(0.5, 1.0, 0.78),
		"button": Color(0.05, 0.18, 0.14), "button_hover": Color(0.08, 0.3, 0.23), "button_pressed": Color(0.11, 0.42, 0.32),
	},
	&"monochrome": {
		"name": "Monochrome",
		"bg": Color(0.04, 0.04, 0.04), "panel": Color(0.08, 0.08, 0.08, 0.96),
		"border": Color(0.85, 0.85, 0.85), "glow": Color(1.0, 1.0, 1.0, 0.22),
		"text": Color(0.95, 0.95, 0.95), "dim": Color(0.62, 0.62, 0.62), "accent": Color(1.0, 1.0, 1.0),
		"button": Color(0.14, 0.14, 0.14), "button_hover": Color(0.25, 0.25, 0.25), "button_pressed": Color(0.36, 0.36, 0.36),
	},
}

const KEYS := ["name", "bg", "panel", "border", "glow", "text", "dim", "accent", "button", "button_hover", "button_pressed"]

## Type variation for system-window panels (UIStyle.apply sets it).
const PANEL_VARIATION := &"SystemPanel"
const GLOW_SIZE := 10
const CORNER := 3

## The palette in use right now (set by Settings.apply).
static var current: StringName = DEFAULT


static func ids() -> Array:
	return PALETTES.keys()


static func is_valid(id) -> bool:
	return PALETTES.has(StringName(str(id)))


static func palette(id: StringName = current) -> Dictionary:
	return PALETTES.get(id, PALETTES[DEFAULT])


static func color(key: String, id: StringName = current) -> Color:
	return palette(id).get(key, Color.MAGENTA)


## A system-window box: dark fill, thin glowing border, a brighter top edge.
static func panel_box(id: StringName = current, glow := true) -> StyleBoxFlat:
	var p := palette(id)
	var s := StyleBoxFlat.new()
	s.bg_color = p.panel
	s.border_color = p.border
	s.set_border_width_all(1)
	s.border_width_top = 2
	s.set_corner_radius_all(CORNER)
	s.set_content_margin_all(6)
	if glow:
		s.shadow_color = p.glow
		s.shadow_size = GLOW_SIZE
	return s


static func _button_box(fill: Color, border: Color, glow: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(CORNER)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	if glow.a > 0.0:
		s.shadow_color = glow
		s.shadow_size = 5
	return s


## The full Theme for a palette.
static func build(id: StringName = current) -> Theme:
	var p := palette(id)
	var t := Theme.new()
	var faded_border: Color = p.border
	faded_border.a = 0.45

	# Panels and windows
	var panel := panel_box(id)
	t.set_stylebox("panel", "PanelContainer", panel_box(id, false))
	t.set_type_variation(PANEL_VARIATION, "PanelContainer")
	t.set_stylebox("panel", PANEL_VARIATION, panel)
	t.set_stylebox("panel", "PopupPanel", panel)
	t.set_stylebox("panel", "AcceptDialog", panel_box(id, false))
	t.set_stylebox("embedded_border", "Window", panel)
	t.set_stylebox("embedded_unfocused_border", "Window", panel)
	t.set_color("title_color", "Window", p.accent)
	t.set_stylebox("panel", "TooltipPanel", panel_box(id, false))
	t.set_color("font_color", "TooltipLabel", p.text)
	t.set_stylebox("panel", "PopupMenu", panel_box(id, false))
	t.set_stylebox("hover", "PopupMenu", _button_box(p.button_hover, p.border))
	t.set_color("font_color", "PopupMenu", p.text)
	t.set_color("font_hover_color", "PopupMenu", p.accent)

	# Text
	t.set_color("font_color", "Label", p.text)
	t.set_color("default_color", "RichTextLabel", p.text)

	# Buttons (OptionButton, CheckBox etc. inherit from Button in the default theme)
	for type in ["Button", "OptionButton", "MenuButton"]:
		t.set_stylebox("normal", type, _button_box(p.button, faded_border))
		t.set_stylebox("hover", type, _button_box(p.button_hover, p.border, p.glow))
		t.set_stylebox("pressed", type, _button_box(p.button_pressed, p.accent, p.glow))
		t.set_stylebox("focus", type, _button_box(Color.TRANSPARENT, p.accent))
		var off: Color = p.button
		off.a = 0.45
		var off_border: Color = faded_border
		off_border.a = 0.2
		t.set_stylebox("disabled", type, _button_box(off, off_border))
		t.set_color("font_color", type, p.text)
		t.set_color("font_hover_color", type, p.accent)
		t.set_color("font_pressed_color", type, Color.WHITE)
		t.set_color("font_focus_color", type, p.text)
		t.set_color("font_disabled_color", type, p.dim * Color(1, 1, 1, 0.6))
	for type in ["CheckBox", "CheckButton"]:
		t.set_color("font_color", type, p.text)
		t.set_color("font_hover_color", type, p.accent)
		t.set_color("font_pressed_color", type, p.text)

	# Inputs
	t.set_stylebox("normal", "LineEdit", _button_box(p.bg, faded_border))
	t.set_stylebox("focus", "LineEdit", _button_box(Color.TRANSPARENT, p.accent))
	t.set_color("font_color", "LineEdit", p.text)
	t.set_color("caret_color", "LineEdit", p.accent)

	# Tabs
	t.set_stylebox("panel", "TabContainer", panel_box(id, false))
	t.set_stylebox("tab_selected", "TabContainer", _button_box(p.button_pressed, p.border))
	t.set_stylebox("tab_unselected", "TabContainer", _button_box(p.button, faded_border))
	t.set_stylebox("tab_hovered", "TabContainer", _button_box(p.button_hover, p.border))
	t.set_color("font_selected_color", "TabContainer", Color.WHITE)
	t.set_color("font_unselected_color", "TabContainer", p.dim)
	t.set_color("font_hovered_color", "TabContainer", p.accent)

	# Bars and sliders
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = p.bg
	bar_bg.border_color = faded_border
	bar_bg.set_border_width_all(1)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = p.border
	t.set_stylebox("background", "ProgressBar", bar_bg)
	t.set_stylebox("fill", "ProgressBar", bar_fill)
	t.set_color("font_color", "ProgressBar", p.text)
	var slider := StyleBoxFlat.new()
	slider.bg_color = p.button
	slider.content_margin_top = 3
	slider.content_margin_bottom = 3
	var slider_fill := slider.duplicate()
	slider_fill.bg_color = p.border
	t.set_stylebox("slider", "HSlider", slider)
	t.set_stylebox("grabber_area", "HSlider", slider_fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", slider_fill)
	return t


## Makes `id` the game-wide look. It's merged into Godot's fallback theme
## (not set on the root window) because a window's theme doesn't reach
## controls under a CanvasLayer, like the floor HUD and its menus.
static func apply_to(root: Window, id: StringName) -> void:
	current = id if is_valid(id) else DEFAULT
	ThemeDB.get_default_theme().merge_with(build(current))
	if root:   # controls that are already on screen restyle now
		root.propagate_notification(Control.NOTIFICATION_THEME_CHANGED)


## "[b]" heading hex for RichTextLabel bbcode, e.g. "[color=#%s]" % UITheme.hex("accent").
static func hex(key: String) -> String:
	return color(key).to_html(false)
