class_name ThemedBackground
extends ColorRect
## A full-screen background in the current palette's "bg" colour that
## repaints itself when the player picks another palette in Settings.


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = UITheme.color("bg")


func _ready() -> void:
	Settings.ui_theme_changed.connect(_repaint)


func _repaint() -> void:
	color = UITheme.color("bg")
