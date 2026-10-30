extends Node
## Autoload "Settings": player options, saved to user://settings.cfg and
## applied on startup. Add new options here + in SettingsPanel.

const PATH := "user://settings.cfg"

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

## The palette changed (screens with their own backgrounds repaint).
signal ui_theme_changed
var _theme_applied := false


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
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen
			else DisplayServer.WINDOW_MODE_WINDOWED)
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
	cfg.save(PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
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
