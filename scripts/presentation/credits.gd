class_name Credits
extends RefCounted
## Credits + license tracking. Every art/sound file in assets/ must be listed
## in assets/credits.json with its author and license; the tests fail if a
## file isn't covered or a license isn't one that allows selling the game.
##
## credits.json:
##   "team":   [ { "role", "name" } ]
##   "assets": [ { "name": pack/track name, "author", "license" (see LICENSES),
##                 "url" (where it came from), "kind": "art" | "music" | "sfx" | "font",
##                 "files": [ paths under assets/, "*" wildcards ok,
##                            e.g. "art/enemies/goblin*.png", "audio/sfx/*" ] } ]
##
## The credits screen also shows Godot's MIT license and the licenses of the
## libraries built into the engine (required when the game ships).

const PATH := "res://assets/credits.json"
const ASSET_ROOT := "res://assets"
## Folders whose files need a credits entry.
const TRACKED_DIRS := ["art", "audio", "fonts"]
## Files that are never game assets.
const IGNORED_EXTS := ["import", "md", "txt", "json", "uid", "gdignore"]

## Licenses that allow commercial use. "attribution": the credits screen must
## name the author (it always does). NOT allowed: anything NonCommercial (NC)
## or NoDerivatives (ND), "personal use only", or unknown.
const LICENSES := {
	"CC0": { "attribution": false },
	"CC-BY-3.0": { "attribution": true },
	"CC-BY-4.0": { "attribution": true },
	"CC-BY-SA-3.0": { "attribution": true },
	"CC-BY-SA-4.0": { "attribution": true },
	"OFL-1.1": { "attribution": true },
	"MIT": { "attribution": true },
	"Commercial license": { "attribution": false },   # bought / commissioned with commercial rights
	"Own work": { "attribution": false },
}
const KINDS := ["art", "music", "sfx", "font"]


static func load_data(path := PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return { "team": [], "assets": [] }
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## Problems with credits.json ([] = all good).
static func validate(data: Dictionary) -> PackedStringArray:
	var problems: PackedStringArray = []
	if not data.get("team") is Array or not data.get("assets") is Array:
		problems.append("credits.json needs a \"team\" list and an \"assets\" list")
		return problems
	for e in data.assets:
		if not e is Dictionary:
			problems.append("credits.json: an asset entry isn't an object")
			continue
		var label: String = str(e.get("name", "?"))
		for key in ["name", "author", "license", "url", "kind", "files"]:
			if not e.has(key) or (e[key] is String and e[key].strip_edges() == ""):
				problems.append("%s: missing \"%s\"" % [label, key])
		if e.has("license") and not LICENSES.has(e.license):
			problems.append("%s: license \"%s\" isn't on the allowed list (Credits.LICENSES)" % [label, e.license])
		if e.has("kind") and not KINDS.has(e.kind):
			problems.append("%s: kind must be one of %s" % [label, KINDS])
		if e.has("files") and (not e.files is Array or e.files.is_empty()):
			problems.append("%s: \"files\" must list at least one path" % label)
	return problems


## Asset files (paths relative to assets/) with no credits entry covering them.
static func uncredited_files(data: Dictionary, root := ASSET_ROOT) -> Array:
	var patterns := []
	for e in data.get("assets", []):
		if e is Dictionary and e.get("files") is Array:
			patterns.append_array(e.files)
	var out := []
	for dir in TRACKED_DIRS:
		for f in list_files("%s/%s" % [root, dir]):
			var rel: String = f.trim_prefix(root + "/")
			if not patterns.any(func(p): return rel.match(p)):
				out.append(rel)
	return out


## Every file under `dir` (recursively), skipping editor/import files.
static func list_files(dir: String) -> Array:
	var out := []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for sub in d.get_directories():
		out.append_array(list_files("%s/%s" % [dir, sub]))
	for f in d.get_files():
		if not IGNORED_EXTS.has(f.get_extension().to_lower()) and not f.begins_with("."):
			out.append("%s/%s" % [dir, f])
	return out


## The whole credits text (BBCode) for the credits screen.
static func text(data: Dictionary, game_title: String) -> String:
	var accent := UITheme.hex("accent")
	var dim := UITheme.hex("dim")
	var t := "[center][font_size=40][color=#%s]%s[/color][/font_size]\n\n" % [accent, esc(game_title)]
	for m in data.get("team", []):
		t += "[color=#%s]%s[/color]\n%s\n\n" % [dim, esc(m.get("role", "")), esc(m.get("name", ""))]
	var groups := { "art": "Art", "music": "Music", "sfx": "Sound effects", "font": "Fonts" }
	for kind in groups:
		var entries: Array = data.get("assets", []).filter(func(e): return e is Dictionary and e.get("kind") == kind)
		if entries.is_empty():
			continue
		t += "\n[font_size=24][color=#%s]%s[/color][/font_size]\n" % [accent, groups[kind]]
		for e in entries:
			t += "%s by %s\n[color=#%s]%s  ·  %s[/color]\n\n" % [esc(e.get("name", "")), esc(e.get("author", "")),
				dim, esc(e.get("license", "")), esc(e.get("url", ""))]
	t += "\n[font_size=24][color=#%s]Made with the Godot Engine[/color][/font_size]\n" % accent
	t += "godotengine.org/license[/center]\n\n"
	t += "[font_size=13]%s\n\n%s[/font_size]" % [esc(Engine.get_license_text().strip_edges()), _engine_third_party()]
	return t


## The libraries inside the engine (FreeType, ENet, mbedTLS, ...) and their
## licenses, which Godot asks shipped games to include.
static func _engine_third_party() -> String:
	var t := "[b]Third-party components in the Godot Engine[/b]\n\n"
	for info in Engine.get_copyright_info():
		t += "[b]%s[/b]\n" % esc(info.name)
		for part in info.parts:
			for c in part.copyright:
				t += "   © %s\n" % esc(c)
			t += "   License: %s\n" % esc(part.license)
		t += "\n"
	var licenses := Engine.get_license_info()
	for id in licenses:
		t += "[b]License: %s[/b]\n%s\n\n" % [esc(id), esc(String(licenses[id]).strip_edges())]
	return t


## Makes text safe inside BBCode (a "[" would otherwise start a tag).
static func esc(s) -> String:
	return str(s).replace("[", "[lb]")
