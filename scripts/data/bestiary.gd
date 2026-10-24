class_name Bestiary
extends RefCounted
## What the party has learned about enemies. Filled in by fighting:
##   - an enemy is added the first time you fight it
##   - hitting it with an element records how it reacted (Weak, Resists, ...)
##   - its traits and lore show once you've beaten it (or Scanned it)
##   - a Scouting Lens reveals everything at once
## Family knowledge is shared: learn that one slime is weak to Fire and every
## slime's entry shows it (unless that slime overrides Fire itself).

## enemy id -> { "defeated": int, "scanned": bool, "known": { Element.Type: Element.Affinity } }
var entries: Dictionary = {}
## family id -> { Element.Type: Element.Affinity }
var family_known: Dictionary = {}


func has_seen(id: StringName) -> bool:
	return entries.has(id)


func _entry(id: StringName) -> Dictionary:
	if not entries.has(id):
		entries[id] = { "defeated": 0, "scanned": false, "known": {} }
	return entries[id]


func record_seen(def: EnemyDef) -> void:
	_entry(def.id)


func record_defeat(def: EnemyDef) -> void:
	var e := _entry(def.id)
	e["defeated"] = e["defeated"] + 1


## Records how `def` reacted to `element`. Returns true if it's new knowledge.
func record_affinity(def: EnemyDef, element: int, affinity: int) -> bool:
	var was_known := known_affinities(def).has(element)
	_entry(def.id).known[element] = affinity
	# Not overridden by this enemy = it's the family's, so the whole family learns it.
	if def.family != &"" and not def.affinities.has(element):
		if not family_known.has(def.family):
			family_known[def.family] = {}
		family_known[def.family][element] = affinity
	return not was_known


## Scouting Lens: everything about this enemy.
func scan(def: EnemyDef) -> void:
	var all := EnemyFamilies.affinities_for(def)
	for e in Element.Type.values():
		record_affinity(def, e, all.get(e, Element.Affinity.NORMAL))
	_entry(def.id)["scanned"] = true


## Element -> Affinity the player knows for this enemy.
func known_affinities(def: EnemyDef) -> Dictionary:
	var out := {}
	var fam: Dictionary = family_known.get(def.family, {})
	for e in fam:
		if not def.affinities.has(e):
			out[e] = fam[e]
	out.merge(entries.get(def.id, {}).get("known", {}), true)
	return out


## Traits and lore are revealed by beating it once or scanning it.
func knows_details(id: StringName) -> bool:
	var e: Dictionary = entries.get(id, {})
	return e.get("defeated", 0) > 0 or e.get("scanned", false)


## "Weak: Fire, Wind · Resists: Water" (only what's known). "" if nothing.
func summary(def: EnemyDef) -> String:
	var groups := {}
	var known := known_affinities(def)
	var els := known.keys()
	els.sort()
	for e in els:
		var a: int = known[e]
		if a != Element.Affinity.NORMAL:
			if not groups.has(a):
				groups[a] = []
			groups[a].append(Element.name_of(e))
	var parts: PackedStringArray = []
	for a in [Element.Affinity.WEAK, Element.Affinity.RESIST, Element.Affinity.IMMUNE, Element.Affinity.ABSORB]:
		if groups.has(a):
			parts.append("%s: %s" % [Element.affinity_name(a), ", ".join(groups[a])])
	return " · ".join(parts)


# =========================================================
# Save / load (validated like everything else in SaveSerializer)
# =========================================================

func to_dict() -> Dictionary:
	var e_out := {}
	for id in entries:
		var e: Dictionary = entries[id]
		e_out[String(id)] = { "defeated": e.defeated, "scanned": e.scanned, "known": _aff_out(e.known) }
	var f_out := {}
	for fam in family_known:
		f_out[String(fam)] = _aff_out(family_known[fam])
	return { "entries": e_out, "families": f_out }


static func from_dict(d: Dictionary) -> Bestiary:
	var b := Bestiary.new()
	var S := SaveSerializer
	var ents := S._d(d, "entries")
	for id in ents:
		if not id is String or not ents[id] is Dictionary or EnemyLibrary.get_enemy_or_null(StringName(id)) == null:
			continue
		var e: Dictionary = ents[id]
		b.entries[StringName(id)] = { "defeated": S._i(e, "defeated", 0, 0, 999999),
			"scanned": S._b(e, "scanned", false), "known": _aff_in(S._d(e, "known")) }
	var fams := S._d(d, "families")
	for fam in fams:
		if fam is String and EnemyFamilies.FAMILIES.has(StringName(fam)) and fams[fam] is Dictionary:
			b.family_known[StringName(fam)] = _aff_in(fams[fam])
	return b


static func _aff_out(src: Dictionary) -> Dictionary:
	var out := {}
	for e in src:
		out[str(e)] = src[e]
	return out


static func _aff_in(src: Dictionary) -> Dictionary:
	var out := {}
	for k in src:
		var v = src[k]
		if k is String and k.is_valid_int() and Element.is_valid(int(k)) \
				and (v is int or v is float) and int(v) >= 0 and int(v) < Element.Affinity.size():
			out[int(k)] = int(v)
	return out
