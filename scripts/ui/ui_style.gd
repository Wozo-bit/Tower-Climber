class_name UIStyle
extends RefCounted
## Shared placeholder styling so popup panels are solid and readable.


static func solid_panel(bg := Color(0.11, 0.11, 0.15), border := Color(0.35, 0.35, 0.45)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(8)
	s.set_content_margin_all(4)
	return s


static func apply(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", solid_panel())
