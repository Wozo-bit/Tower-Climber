class_name UIStyle
extends RefCounted
## Shared styling helpers. The actual look lives in UITheme (palettes the
## player picks in Settings); these just hook panels up to it.


## A glowing system-window box in the current palette.
static func solid_panel() -> StyleBoxFlat:
	return UITheme.panel_box()


## Popup panels use the theme's system-window variation, so they follow the
## palette even if it changes while the panel exists.
static func apply(panel: PanelContainer) -> void:
	panel.theme_type_variation = UITheme.PANEL_VARIATION


## A big panel's design size, shrunk to the screen when the window is
## narrow or the interface size is large (its contents scroll or wrap).
## Re-checked whenever it's shown or the window changes.
static func fit_to_screen(panel: Control, design: Vector2, gap := 24.0) -> void:
	panel.custom_minimum_size = design
	var refit := func():
		if panel.is_inside_tree():
			var vis := panel.get_viewport_rect().size
			panel.custom_minimum_size = Vector2(minf(design.x, vis.x - gap), minf(design.y, vis.y - gap))
	panel.visibility_changed.connect(refit)
	panel.tree_entered.connect(func():
		refit.call()
		if not panel.get_viewport().size_changed.is_connected(refit):
			panel.get_viewport().size_changed.connect(refit))
	panel.tree_exiting.connect(func():
		if panel.get_viewport().size_changed.is_connected(refit):
			panel.get_viewport().size_changed.disconnect(refit))
