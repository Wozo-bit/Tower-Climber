extends Node
## Autoload "Settings": player options, saved to user://settings.cfg and
## applied on startup. Add new options here + in SettingsPanel.

const PATH := "user://settings.cfg"
## Where settings are saved (the tests point this elsewhere).
var path := PATH

## Windowed sizes to pick from (Hayden 2026-11-01); clamped to the screen.
const WINDOW_SIZES := [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]
## Interface scale: bigger or smaller menus and text. Every screen must fit
## the 1280x720 design size divided by the largest of these.
const UI_SCALES := [0.9, 1.0, 1.1, 1.2]

var master_volume := 0.8      # 0-1
var music_volume := 0.8
var sfx_volume := 0.8
var fullscreen := false
var vsync := true
## Look of every menu (a UITheme.PALETTES id).
var ui_theme: StringName = UITheme.DEFAULT
## Full-screen splashes for bosses, ultimate skills, gods, level-ups and wars.
var cutins := true
## Tutorial tips the first time you meet each system (the Tips autoload).
var tips := true
## Index into WINDOW_SIZES (used when not fullscreen).
var window_size := 0
var ui_scale := 1.0
## Rebound keys (InputBindings): action -> [key, key].
var keys: Dictionary = InputBindings.defaults()

## The palette changed (screens with their own backgrounds repaint).
signal ui_theme_changed
var _theme_applied := false
var _applied_window := Vector2i.ZERO


func _ready() -> void:
	_ensure_buses()
	load_settings()
	apply()


## Music and SFX buses so sound can be plugged in later without touching this.
func _ensure_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")


func apply() -> void:
	_set_bus("Master", master_volume)
	_set_bus("Music", music_volume)
	_set_bus("SFX", sfx_volume)
	InputBindings.apply(keys)
	get_tree().root.content_scale_factor = ui_scale
	if DisplayServer.get_name() != "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		var was_full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)
		if not fullscreen and (was_full or _applied_window != window_pixels()):
			_applied_window = window_pixels()
			var screen := DisplayServer.window_get_current_screen()
			DisplayServer.window_set_size(_applied_window)
			var usable := DisplayServer.screen_get_usable_rect(screen)
			DisplayServer.window_set_position(usable.position + (usable.size - _applied_window) / 2)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync
			else DisplayServer.VSYNC_DISABLED)
	if UITheme.current != ui_theme or not _theme_applied:
		_theme_applied = true
		UITheme.apply_to(get_tree().root, ui_theme)
		ui_theme = UITheme.current
		ui_theme_changed.emit()


func _set_bus(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
		AudioServer.set_bus_mute(idx, linear <= 0.001)


## The chosen window size, shrunk (keeping 16:9) if the screen is smaller.
func window_pixels() -> Vector2i:
	var want: Vector2i = WINDOW_SIZES[clampi(window_size, 0, WINDOW_SIZES.size() - 1)]
	if DisplayServer.get_name() == "headless":
		return want
	var usable := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen()).size
	var fit := minf(1.0, minf(usable.x / float(want.x), (usable.y - 40) / float(want.y)))   # room for the title bar
	return Vector2i(roundi(want.x * fit), roundi(want.y * fit))


## Snaps any number to the nearest offered interface scale.
static func clean_scale(v) -> float:
	if not (v is float or v is int):
		return 1.0
	var best: float = UI_SCALES[0]
	for s in UI_SCALES:
		if absf(s - float(v)) < absf(best - float(v)):
			best = s
	return best


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("video", "vsync", vsync)
	cfg.set_value("video", "ui_theme", String(ui_theme))
	cfg.set_value("video", "cutins", cutins)
	cfg.set_value("game", "tips", tips)
	cfg.set_value("video", "window_size", window_size)
	cfg.set_value("video", "ui_scale", ui_scale)
	for a in InputBindings.ACTIONS:
		cfg.set_value("keys", a, keys[a])
	cfg.save(path)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	master_volume = cfg.get_value("audio", "master", master_volume)
	music_volume = cfg.get_value("audio", "music", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)
	fullscreen = cfg.get_value("video", "fullscreen", fullscreen)
	vsync = cfg.get_value("video", "vsync", vsync)
	var theme_id = cfg.get_value("video", "ui_theme", String(ui_theme))
	ui_theme = StringName(theme_id) if UITheme.is_valid(theme_id) else UITheme.DEFAULT
	cutins = cfg.get_value("video", "cutins", cutins) == true
	tips = cfg.get_value("game", "tips", tips) == true
	var ws = cfg.get_value("video", "window_size", window_size)
	window_size = clampi(int(ws), 0, WINDOW_SIZES.size() - 1) if (ws is int or ws is float) else 0
	ui_scale = clean_scale(cfg.get_value("video", "ui_scale", ui_scale))
	var raw := {}
	if cfg.has_section("keys"):
		for a in cfg.get_section_keys("keys"):
			raw[a] = cfg.get_value("keys", a)
	keys = InputBindings.clean(raw if not raw.is_empty() else null)
