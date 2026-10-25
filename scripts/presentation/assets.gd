class_name Assets
extends RefCounted
## Art hooks. Every picture in the game is looked up here by KIND and ID;
## if no file exists the caller keeps its placeholder (coloured shapes), so
## art can be dropped in one file at a time with no code changes.
##
##   res://assets/art/<kind>/<id>.png   (also .webp / .jpg)
##
## Kinds and ids (see assets/README.md for sizes):
##   enemies/<enemy id>        battle card + floor token      e.g. goblin_king
##   portraits/<id>            party + dialogue faces: "player", a companion's
##                             companion_id, an NPC id, or the speaker's name
##                             in snake_case ("merchant")
##   classes/<class id>        fallback portrait for anyone of that class
##   beings/<being id>         gods/demons/devils (shrines, dialogue, cut-ins)
##   guilds/<guild id>         guild emblems
##   backgrounds/<id>          battle backdrop per stage theme ("goblin_warrens"),
##                             "battle" (any battle), "title"
##   tiles/<theme>_floor|_wall, tiles/floor|wall   floor map tiles
##   props/stairs|campfire|merchant|board          floor map props
##   items/<item id>, skills/<skill id>            menu icons
##   cutins/<id>               splash art for cut-ins (falls back to the above)
##
## DLC .pck files mount into res://, so a pack can add art at the same paths.

const ART_ROOT := "res://assets/art"
const IMAGE_EXTS := ["png", "webp", "jpg"]

## Folders searched in order (tests add a temporary one).
static var roots: Array[String] = [ART_ROOT]
## "kind/id" -> Texture2D, or null when there's no file (so misses are cheap too).
static var _cache: Dictionary = {}


## The picture for `kind`/`id`, or null if there isn't one.
static func texture(kind: String, id) -> Texture2D:
	var key := "%s/%s" % [kind, id]
	if _cache.has(key):
		return _cache[key]
	var tex: Texture2D = null
	if str(id) != "":
		for root in roots:
			for ext in IMAGE_EXTS:
				tex = load_texture("%s/%s.%s" % [root, key, ext])
				if tex:
					break
			if tex:
				break
	_cache[key] = tex
	return tex


## The first of several [kind, id] pairs that has a picture (fallback chains).
static func first(pairs: Array) -> Texture2D:
	for pair in pairs:
		var tex := texture(pair[0], pair[1])
		if tex:
			return tex
	return null


static func has(kind: String, id) -> bool:
	return texture(kind, id) != null


## Forget everything looked up (after DLC loads, or in tests).
static func clear_cache() -> void:
	_cache.clear()


## Imported resources load normally; plain image files (mods, tests, user://)
## are read straight from disk.
static func load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			return res
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(path)
		if img and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null


## A face for a party member: their own portrait, else their class's.
static func portrait_for(c: CharacterData) -> Texture2D:
	if c == null:
		return null
	var own := "player" if c == GameState.player else String(c.companion_id)
	return first([["portraits", own], ["classes", c.class_id]])


## A face for whoever is in a battle slot.
static func combatant_art(u: Combatant) -> Texture2D:
	if u.source_enemy:
		return texture("enemies", u.source_enemy.id)
	return portrait_for(u.source_character)


## "Old Merchant" -> "old_merchant"
static func slug(text: String) -> String:
	var out := ""
	for ch in text.strip_edges().to_lower():
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"):
			out += ch
		elif not out.ends_with("_") and out != "":
			out += "_"
	return out.trim_suffix("_")
