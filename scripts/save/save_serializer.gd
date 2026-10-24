class_name SaveSerializer
extends RefCounted
## Converts game data to and from plain JSON-safe dictionaries.
##
## Why JSON: Godot's .tres/.res formats can carry embedded scripts that run when
## loaded, so a tampered or shared save could execute code. JSON can only hold
## data. Everything read back is also validated: unknown ids are dropped,
## numbers are clamped, names are cleaned. A broken file just fails to load.

const FORMAT_VERSION := 2


# =========================================================
# Low-level helpers
# =========================================================

static func write_json(path: String, data: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	# Write to a temp file first, then swap it in, so a crash mid-write can't
	# leave a half-written save.
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	return DirAccess.rename_absolute(tmp, path) == OK


## Returns {} if the file is missing, unreadable or not a JSON object.
static func read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}


static func _i(d: Dictionary, key: String, default: int, lo: int = -9007199254740991, hi: int = 9007199254740991) -> int:
	var v = d.get(key, default)
	if not (v is int or v is float):
		return default
	return clampi(int(v), lo, hi)


static func _f(d: Dictionary, key: String, default: float, lo: float = -1e12, hi: float = 1e12) -> float:
	var v = d.get(key, default)
	if not (v is int or v is float):
		return default
	return clampf(float(v), lo, hi)


static func _b(d: Dictionary, key: String, default: bool) -> bool:
	var v = d.get(key, default)
	return v if v is bool else default


static func _s(d: Dictionary, key: String, default: String = "", max_len: int = 256) -> String:
	var v = d.get(key, default)
	return (v as String).left(max_len) if v is String else default


static func _d(d: Dictionary, key: String) -> Dictionary:
	var v = d.get(key, {})
	return v if v is Dictionary else {}


static func _a(d: Dictionary, key: String) -> Array:
	var v = d.get(key, [])
	return v if v is Array else []


## Stats.Type -> int dictionary. JSON turns int keys into strings, so convert back.
static func _stat_dict_out(src: Dictionary) -> Dictionary:
	var out := {}
	for k in src:
		out[str(k)] = int(src[k])
	return out


static func _stat_dict_in(src: Dictionary, lo: int, hi: int) -> Dictionary:
	var out := {}
	for k in src:
		if not (k is String and k.is_valid_int()):
			continue
		var stat := int(k)
		var v = src[k]
		if stat in Stats.all() and (v is int or v is float):
			out[stat] = clampi(int(v), lo, hi)
	return out


static func _valid_class(id: String) -> StringName:
	return StringName(id) if id != "" and ClassRegistry.get_class_def(StringName(id)) != null else &""


# =========================================================
# Gear / inventory
# =========================================================

static func gear_to_dict(g: GearItem) -> Dictionary:
	return {
		"name": g.display_name, "base": String(g.base_id), "slot": g.slot, "rarity": g.rarity,
		"bonuses": _stat_dict_out(g.bonuses), "class_lock": String(g.class_lock),
		"item_level": g.item_level, "quest_reward": g.quest_reward, "description": g.description,
		"element": g.element,
	}


static func gear_from_dict(d: Dictionary) -> GearItem:
	var base := _s(d, "base")
	if not LootTable.BASES.has(StringName(base)):
		return null
	var g := GearItem.new()
	g.base_id = StringName(base)
	g.display_name = _s(d, "name", "Gear", 64)
	g.slot = _i(d, "slot", 0, 0, GearItem.Slot.size() - 1)
	g.rarity = _i(d, "rarity", 0, 0, Rarity.Tier.size() - 1)
	g.bonuses = _stat_dict_in(_d(d, "bonuses"), -999, 999)
	g.class_lock = _valid_class(_s(d, "class_lock"))
	g.item_level = _i(d, "item_level", 1, 1, 9999)
	g.quest_reward = _b(d, "quest_reward", false)
	g.description = _s(d, "description", "", 512)
	# Only weapons carry an element, and only a real magic one.
	var el := _i(d, "element", -1, -1, Element.Type.size() - 1)
	g.element = el if g.slot == GearItem.Slot.WEAPON and Element.MAGIC_ELEMENTS.has(el) else -1
	return g


static func inventory_to_dict(inv: Inventory) -> Dictionary:
	var counts := {}
	for id in inv.counts:
		counts[String(id)] = inv.counts[id]
	return { "counts": counts, "gear": inv.gear.map(gear_to_dict) }


static func inventory_from_dict(d: Dictionary) -> Inventory:
	var inv := Inventory.new()
	var counts := _d(d, "counts")
	for id in counts:
		var n = counts[id]
		if id is String and ItemLibrary.get_item(StringName(id)) and (n is int or n is float) and n > 0:
			inv.add(StringName(id), clampi(int(n), 0, 9999))   # respects carry limits
	for gd in _a(d, "gear"):
		if gd is Dictionary:
			var g := gear_from_dict(gd)
			if g:
				inv.gear.append(g)
	return inv


# =========================================================
# Characters
# =========================================================

static func character_to_dict(c: CharacterData) -> Dictionary:
	var equip := {}
	for slot in c.equipment:
		equip[str(slot)] = gear_to_dict(c.equipment[slot])
	return {
		"name": c.character_name, "level": c.level, "xp": c.xp, "unspent": c.unspent_points,
		"class": String(c.class_id), "gold": c.gold,
		"free_respec_pre_used": c.free_respec_pre_class_used,
		"free_respec_post_used": c.free_respec_post_class_used,
		"paid_respecs": c.paid_respec_count, "battle_row": c.battle_row,
		"missing_hp": c.missing_hp, "missing_mp": c.missing_mp,
		"legacy_id": c.legacy_id, "companion_id": String(c.companion_id),
		"allocated": _stat_dict_out(c.stats.allocated),
		"learned_skills": c.learned_skills.map(func(id): return String(id)),
		"skill_picks": c.skill_picks,
		"equipment": equip,
	}


static func character_from_dict(d: Dictionary) -> CharacterData:
	var c := CharacterData.new()
	c.character_name = CharacterData.clean_name(_s(d, "name", "Climber", 64))
	if c.character_name.is_empty():
		c.character_name = "Climber"
	c.level = _i(d, "level", 1, 1, 999)
	c.xp = _i(d, "xp", 0, 0)
	c.unspent_points = _i(d, "unspent", 0, 0, 99999)
	c.gold = _i(d, "gold", 0, 0)
	c.free_respec_pre_class_used = _b(d, "free_respec_pre_used", false)
	c.free_respec_post_class_used = _b(d, "free_respec_post_used", false)
	c.paid_respec_count = _i(d, "paid_respecs", 0, 0, 999)
	c.battle_row = _i(d, "battle_row", -1, -1, 1)
	c.legacy_id = _s(d, "legacy_id", "", 64)
	c.companion_id = StringName(_s(d, "companion_id", "", 64))
	c.stats.allocated = _stat_dict_in(_d(d, "allocated"), 0, 99999)
	for id in _a(d, "learned_skills"):
		if id is String:
			var s := SkillLibrary.get_skill_or_null(StringName(id))
			if s and s.learnable and not c.learned_skills.has(s.id):
				c.learned_skills.append(s.id)
	c.skill_picks = _i(d, "skill_picks", CharacterData.STARTING_SKILL_PICKS, 0, 999)
	for stat in Stats.all():
		if not c.stats.allocated.has(stat):
			c.stats.allocated[stat] = 0
	var equip := _d(d, "equipment")
	for k in equip:
		if equip[k] is Dictionary:
			var g := gear_from_dict(equip[k])
			if g and k is String and k.is_valid_int() and int(k) == g.slot:
				c.equipment[g.slot] = g
	c.class_id = _valid_class(_s(d, "class"))
	# Rebuild derived bonuses (gear + class) from the data above.
	c._refresh_gear_bonus()
	c._apply_class_bonus()
	c.missing_hp = _i(d, "missing_hp", 0, 0, c.max_hp())
	c.missing_mp = _i(d, "missing_mp", 0, 0, c.max_mp())
	return c


# =========================================================
# Run (one save slot)
# =========================================================

static func floor_enemies_to_array(enemies: Array) -> Array:
	var out := []
	for e in enemies:
		var row := { "pos": [e.pos.x, e.pos.y], "alive": e.alive, "kind": e.get("kind", "normal"),
			"group": (e.group as Array).map(func(id): return String(id)) }
		if e.has("roamer_id"):
			row["roamer_id"] = String(e.roamer_id)
		out.append(row)
	return out


static func floor_enemies_from_array(arr: Array) -> Array:
	var out := []
	for row in arr:
		if not row is Dictionary:
			continue
		var pos := _a(row, "pos")
		var group: Array[StringName] = []
		for id in _a(row, "group"):
			if id is String and EnemyLibrary.get_enemy_or_null(StringName(id)):
				group.append(StringName(id))
		var kind := _s(row, "kind", "normal")
		if pos.size() != 2 or group.is_empty() or not kind in ["normal", "miniboss", "boss", "roaming"]:
			continue
		var e := { "pos": Vector2i(int(pos[0]), int(pos[1])), "alive": _b(row, "alive", true),
			"kind": kind, "group": group }
		if row.has("roamer_id"):
			e["roamer_id"] = StringName(_s(row, "roamer_id"))
		out.append(e)
	return out


# =========================================================
# Quests (generated bounties are saved whole, so they're validated here)
# =========================================================

static func quest_def_to_dict(q: Dictionary) -> Dictionary:
	var steps := []
	for st in q.get("steps", []):
		var g: Dictionary = st.goal
		var gd := { "type": g.type, "count": g.get("count", 1) }
		for k in ["enemy", "family", "kind"]:
			if g.has(k):
				gd[k] = String(g[k])
		steps.append({ "text": st.text, "goal": gd })
	var r: Dictionary = q.get("rewards", {})
	return { "title": q.title, "kind": q.kind, "giver": q.get("giver", ""), "desc": q.get("desc", ""),
		"steps": steps, "rewards": { "gold": r.get("gold", 0), "xp": r.get("xp", 0) } }


## Only defeat bounties are generated, so only those are accepted back.
## Returns {} if anything is off.
static func quest_def_from_dict(d: Dictionary) -> Dictionary:
	var steps := []
	for st in _a(d, "steps"):
		if not st is Dictionary:
			return {}
		var g := _d(st, "goal")
		if _s(g, "type") != "defeat":
			return {}
		var goal := { "type": "defeat", "count": _i(g, "count", 1, 1, 99) }
		if g.has("enemy"):
			goal["enemy"] = StringName(_s(g, "enemy"))
		elif g.has("family"):
			goal["family"] = StringName(_s(g, "family"))
		elif g.has("kind"):
			goal["kind"] = _s(g, "kind")
		steps.append({ "text": _s(st, "text", "Defeat enemies", 128), "goal": goal })
	var r := _d(d, "rewards")
	var q := { "title": _s(d, "title", "Bounty", 64), "kind": "bounty", "giver": _s(d, "giver", "Notice board", 64),
		"desc": _s(d, "desc", "", 512), "steps": steps,
		"rewards": { "gold": _i(r, "gold", 0, 0, 100000), "xp": _i(r, "xp", 0, 0, 100000) } }
	return q if QuestLibrary.validate(&"saved_bounty", q).is_empty() else {}
