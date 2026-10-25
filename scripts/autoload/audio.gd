extends Node
## Autoload "Audio": music and sound-effect hooks. Like the art hooks,
## everything is looked up by name and silently skipped if the file isn't
## there, so sounds can be added one at a time.
##
##   res://assets/audio/music/<track>.ogg   (also .mp3 / .wav)
##   res://assets/audio/sfx/<sound>.ogg
##
## VARIETY: "battle_goblin.ogg", "battle_goblin_2.ogg", "battle_goblin_3.ogg"
## are all versions of the same track/sound; one is picked at random each time.
##
## Music is asked for as a fallback list (MusicLibrary builds them): the first
## name that has a file plays, so a specific boss can have its own theme while
## everything else falls back to its family's, its stage's, or the generic one.
## Asking for the track that's already playing keeps it going (no restart).

const MUSIC_ROOT := "res://assets/audio/music"
const SFX_ROOT := "res://assets/audio/sfx"
const AUDIO_EXTS := ["ogg", "mp3", "wav"]
## "_2" ... "_9" variants are looked for.
const MAX_VARIANTS := 9
const CROSSFADE_SEC := 1.2
const SFX_VOICES := 10
## Same sound twice within this many seconds is skipped (stops stacking).
const SFX_REPEAT_GAP := 0.04

var music_roots: Array[String] = [MUSIC_ROOT]
var sfx_roots: Array[String] = [SFX_ROOT]

## Base name of the music playing now ("" = none), and of the last request.
var current_track := ""
var _music: Array[AudioStreamPlayer] = []
var _active := 0
var _fade: Tween
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _last_played: Dictionary = {}   # sfx id -> time
## "music/battle_goblin" -> [paths of it and its variants] (empty = no file)
var _variant_cache: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # menus can pause the tree; music keeps going
	_rng.randomize()
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = "Music"
		p.finished.connect(_on_music_finished.bind(p))
		add_child(p)
		_music.append(p)
	for i in SFX_VOICES:
		var v := AudioStreamPlayer.new()
		v.bus = "SFX"
		add_child(v)
		_voices.append(v)
	# Every button in the game clicks.
	get_tree().node_added.connect(_on_node_added)


# =========================================================
# Music
# =========================================================

## Plays the first track in `names` that has a file. Returns its name ("" if
## none exist; the music then fades out).
func play_music(names: Array) -> String:
	var pick := ""
	for n in names:
		if not variants("music", String(n)).is_empty():
			pick = String(n)
			break
	if pick == current_track:
		return pick
	current_track = pick
	if pick == "":
		stop_music()
		return ""
	var paths := variants("music", pick)
	var stream := load_stream(paths[_rng.randi() % paths.size()])
	if stream == null:
		return ""
	var old := _music[_active]
	_active = 1 - _active
	var new := _music[_active]
	new.stream = stream
	new.volume_db = -40.0
	new.play()
	if _fade:
		_fade.kill()
	_fade = create_tween().set_parallel(true)
	_fade.tween_property(new, "volume_db", 0.0, CROSSFADE_SEC)
	if old.playing:
		_fade.tween_property(old, "volume_db", -40.0, CROSSFADE_SEC)
		_fade.chain().tween_callback(old.stop)
	return pick


func stop_music(fade := CROSSFADE_SEC) -> void:
	current_track = ""
	if _fade:
		_fade.kill()
	_fade = create_tween().set_parallel(true)
	for p in _music:
		if p.playing:
			_fade.tween_property(p, "volume_db", -40.0, fade)
	_fade.chain().tween_callback(func():
		for p in _music:
			p.stop())


## Tracks loop (whatever their import settings say).
func _on_music_finished(p: AudioStreamPlayer) -> void:
	if p == _music[_active] and current_track != "":
		p.play()


# =========================================================
# Sound effects
# =========================================================

## Plays the first sound in `names` (a String or a fallback list) that has a
## file. Returns the name played, or "".
func play_sfx(names, pitch_jitter := 0.05) -> String:
	var list: Array = names if names is Array else [names]
	for n in list:
		var id := String(n)
		var paths := variants("sfx", id)
		if paths.is_empty():
			continue
		var now := Time.get_ticks_msec() / 1000.0
		if now - _last_played.get(id, -1.0) < SFX_REPEAT_GAP:
			return id
		_last_played[id] = now
		var stream := load_stream(paths[_rng.randi() % paths.size()])
		if stream == null:
			return ""
		var v := _voices[_next_voice]
		_next_voice = (_next_voice + 1) % _voices.size()
		v.stream = stream
		v.pitch_scale = 1.0 + _rng.randf_range(-pitch_jitter, pitch_jitter)
		v.play()
		return id
	return ""


func _on_node_added(node: Node) -> void:
	if node is BaseButton and not node.has_meta("silent"):
		node.pressed.connect(func(): play_sfx("ui_click", 0.0))


# =========================================================
# Files
# =========================================================

## Paths of `id` and its _2.._9 variants under music/ or sfx/ ([] if none).
func variants(kind: String, id: String) -> Array:
	var key := kind + "/" + id
	if _variant_cache.has(key):
		return _variant_cache[key]
	var out := []
	if id != "":
		var roots := music_roots if kind == "music" else sfx_roots
		for i in range(1, MAX_VARIANTS + 1):
			var file_name := id if i == 1 else "%s_%d" % [id, i]
			for root in roots:
				var found := _find_file("%s/%s" % [root, file_name])
				if found != "":
					out.append(found)
					break
	_variant_cache[key] = out
	return out


func _find_file(base: String) -> String:
	for ext in AUDIO_EXTS:
		var p := "%s.%s" % [base, ext]
		if ResourceLoader.exists(p) or FileAccess.file_exists(p):
			return p
	return ""


## Forget which files exist (after DLC loads, or in tests).
func clear_cache() -> void:
	_variant_cache.clear()


## Imported files load normally; raw .ogg/.mp3/.wav (mods, tests) are read from disk.
static func load_stream(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is AudioStream:
			return res
	if not FileAccess.file_exists(path):
		return null
	match path.get_extension().to_lower():
		"ogg":
			return AudioStreamOggVorbis.load_from_file(path)
		"mp3":
			return AudioStreamMP3.load_from_file(path)
		"wav":
			return AudioStreamWAV.load_from_file(path)
	return null
