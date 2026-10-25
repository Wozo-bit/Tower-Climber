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
