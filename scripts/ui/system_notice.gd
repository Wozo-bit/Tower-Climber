class_name SystemNotice
extends VBoxContainer
## Manhwa-style system messages: small glowing windows that stack at the top
## of the screen, e.g.
##
##   [ Quest Updated ]
##   Goblin Trouble — 3/5 goblins
##
## Each one plays a chime ("system_<category>" or "system") and fades out.
## Messages that start with a short "Label: " get that label as their header;
## everything else uses the category's header.

const SHOW_SEC := 3.2
const FADE_SEC := 0.7
const MAX_SHOWN := 4
const WIDTH := 520
## Header labels longer than this many words aren't treated as a header.
const HEADER_MAX_WORDS := 3

const CATEGORY_HEADERS := {
	"quest": "Quest", "route": "Path", "blessing": "Blessing", "guild": "Guild", "system": "System",
}


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	custom_minimum_size.x = WIDTH
	offset_left = -WIDTH / 2.0
	offset_right = WIDTH / 2.0
	add_theme_constant_override("separation", 6)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Shows one notice. Returns the [header, body] it used (for the tests).
func push(text: String, category := "system") -> Array:
	var parts := split(text, category)
	while get_child_count() >= MAX_SHOWN:
		var oldest := get_child(0)
		remove_child(oldest)
		oldest.queue_free()
	var panel := PanelContainer.new()
	UIStyle.apply(panel)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	panel.add_child(box)
	var head := Label.new()
	head.text = "[ %s ]" % parts[0]
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 14)
	head.add_theme_color_override("font_color", UITheme.color("accent"))
	box.add_child(head)
	if parts[1] != "":
		var body := Label.new()
		body.text = parts[1]
		body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size.x = WIDTH - 24
		body.add_theme_font_size_override("font_size", 15)
		box.add_child(body)
	Audio.play_sfx(["system_%s" % category, "system"], 0.0)
	var tw := panel.create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.15).from(0.0)
	tw.tween_interval(SHOW_SEC)
	tw.tween_property(panel, "modulate:a", 0.0, FADE_SEC)
	tw.tween_callback(panel.queue_free)
	return parts


## "Quest updated: Goblin Trouble" -> ["Quest Updated", "Goblin Trouble"];
## "You joined X." (guild) -> ["Guild", "You joined X."]
static func split(text: String, category := "system") -> Array:
	var i := text.find(": ")
	if i > 0:
		var label := text.substr(0, i)
		if label.split(" ").size() <= HEADER_MAX_WORDS and not label.contains("."):
			return [label.capitalize(), text.substr(i + 2).strip_edges()]
	return [CATEGORY_HEADERS.get(category, "System"), text.strip_edges()]
