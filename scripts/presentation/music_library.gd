class_name MusicLibrary
extends RefCounted
## Which music fits where. Each function returns a FALLBACK LIST of track
## names, most specific first; Audio.play_music plays the first one that has
## a file. So you can start with just "explore.ogg" + "battle.ogg" + "boss.ogg"
## and add variety later (a stage's own theme, a family's battle track, one
## boss's personal theme) without touching code.
##
## A stage theme can also name its tracks directly in StageLibrary.THEMES:
##   "music": { "explore": "my_track", "battle": "...", "boss": "...", "rest": "..." }
## (used before the naming-convention names, handy for DLC stages).

const TITLE := "title"
const CREDITS := "credits"


static func title() -> Array:
	return [TITLE]


static func credits() -> Array:
	return [CREDITS, TITLE]


## Walking around floor `floor_n`.
##   rest floors: rest_<theme> -> rest -> (explore chain)
##   others:      floor_<n> -> explore_<theme> -> explore_<family> -> explore
static func for_floor(floor_n: int, is_rest: bool) -> Array:
	var theme := StageLibrary.theme_id_for_floor(floor_n)
	var family := _theme_family(theme)
	var out := []
	if is_rest:
		out += _override(theme, "rest")
		out += ["rest_%s" % theme, "rest"]
	out += _override(theme, "explore")
	out += ["floor_%d" % floor_n, "explore_%s" % theme]
	if family != "":
		out.append("explore_%s" % family)
	out.append("explore")
	return _clean(out)


## A fight. `kind` = GameState.enemy_kind ("normal", "miniboss", "boss",
## "roaming", "guard", "champion"); `group` = enemy ids (the leader first).
##   normal:   battle_<leader> -> battle_<family> -> battle_<theme> -> battle
##   miniboss: miniboss_<leader> -> miniboss_<family> -> miniboss_<theme> -> miniboss -> (normal chain)
##   boss:     [final_boss] -> boss_<leader> -> boss_<family> -> boss_<theme> -> boss -> battle
##   roaming:  roamer_<roamer id> -> roamer_<leader> -> roamer -> boss -> battle
##   guard:    guild_<guild> -> guild_battle -> battle
##   champion: champion_<guild> -> champion -> guild_<guild> -> guild_battle -> boss -> battle
static func for_battle(kind: String, group: Array, floor_n: int, info: Dictionary = {}) -> Array:
	var leader := String(group[0]) if not group.is_empty() else ""
	var def := EnemyLibrary.get_enemy_or_null(StringName(leader)) if leader != "" else null
	var family := String(def.family) if def else ""
	var theme := String(StageLibrary.theme_id_for_floor(floor_n))
	var guild := String(info.get("guild", ""))
	var normal := []
	normal += _override(StringName(theme), "battle")
	if leader != "":
		normal.append("battle_%s" % leader)
	if family != "":
		normal.append("battle_%s" % family)
	normal += ["battle_%s" % theme, "battle"]
	match kind:
		"miniboss":
			var out := _override(StringName(theme), "miniboss")
			out += ["miniboss_%s" % leader, "miniboss_%s" % family, "miniboss_%s" % theme, "miniboss"]
			return _clean(out + normal)
		"boss":
			var out := []
			if floor_n >= GameState.FINAL_FLOOR:
				out.append("final_boss")
			out += _override(StringName(theme), "boss")
			out += ["boss_%s" % leader, "boss_%s" % family, "boss_%s" % theme, "boss", "battle"]
			return _clean(out)
		"roaming":
			return _clean(["roamer_%s" % info.get("roamer_id", ""), "roamer_%s" % leader, "roamer", "boss", "battle"])
		"guard":
			return _clean(["guild_%s" % guild, "guild_battle", "battle"])
		"champion":
			return _clean(["champion_%s" % guild, "champion", "guild_%s" % guild, "guild_battle", "boss", "battle"])
	return _clean(normal)


static func _theme_family(theme: StringName) -> String:
	return String(StageLibrary.THEMES.get(theme, {}).get("family", ""))


static func _override(theme: StringName, key: String) -> Array:
	var name: String = StageLibrary.THEMES.get(theme, {}).get("music", {}).get(key, "")
	return [name] if name != "" else []


## Drops names left half-empty by missing data ("battle_", "guild_") and repeats.
static func _clean(names: Array) -> Array:
	var out := []
	for n in names:
		var s := String(n)
		if s != "" and not s.ends_with("_") and not out.has(s):
			out.append(s)
	return out
