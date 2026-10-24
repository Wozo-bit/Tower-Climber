class_name Element
extends RefCounted
## Damage elements. Slash / Pierce / Blunt are the physical "weapon kinds";
## the rest are magical elements. A hit can carry several (Ember Strike is
## Fire + Slash; a future Lava skill could be Fire + Earth).
##
## Enemies have an affinity per element (EnemyFamilies). For a hit:
##   - any element it ABSORBS -> the hit heals it instead
##   - else any element it's IMMUNE to -> no damage
##   - else damage x WEAK_MULT for each weakness, x RESIST_MULT for each resistance
## Any weakness also counts toward staggering it (see Combatant).

enum Type { SLASH, PIERCE, BLUNT, FIRE, ICE, WATER, LIGHTNING, EARTH, HOLY, DARK, WIND }
enum Affinity { NORMAL, WEAK, RESIST, IMMUNE, ABSORB }

const WEAK_MULT := 1.5
const RESIST_MULT := 0.5

const WEAPON_KINDS: Array[int] = [Type.SLASH, Type.PIERCE, Type.BLUNT]
const MAGIC_ELEMENTS: Array[int] = [Type.FIRE, Type.ICE, Type.WATER, Type.LIGHTNING, Type.EARTH,
	Type.HOLY, Type.DARK, Type.WIND]

const NAMES := {
	Type.SLASH: "Slash", Type.PIERCE: "Pierce", Type.BLUNT: "Blunt",
	Type.FIRE: "Fire", Type.ICE: "Ice", Type.WATER: "Water", Type.LIGHTNING: "Lightning",
	Type.EARTH: "Earth", Type.HOLY: "Holy", Type.DARK: "Dark", Type.WIND: "Wind",
}
## Used to name elemental weapons: "Flame Mithril Sword".
const ADJECTIVES := {
	Type.FIRE: "Flame", Type.ICE: "Frost", Type.WATER: "Tide", Type.LIGHTNING: "Storm",
	Type.EARTH: "Stone", Type.HOLY: "Blessed", Type.DARK: "Shadow", Type.WIND: "Gale",
}
const COLORS := {
	Type.SLASH: Color(0.85, 0.85, 0.85), Type.PIERCE: Color(0.8, 0.8, 0.65), Type.BLUNT: Color(0.75, 0.65, 0.55),
	Type.FIRE: Color(1.0, 0.5, 0.25), Type.ICE: Color(0.6, 0.9, 1.0), Type.WATER: Color(0.35, 0.6, 1.0),
	Type.LIGHTNING: Color(1.0, 0.95, 0.4), Type.EARTH: Color(0.7, 0.55, 0.3), Type.HOLY: Color(1.0, 0.95, 0.75),
	Type.DARK: Color(0.65, 0.45, 0.85), Type.WIND: Color(0.6, 1.0, 0.7),
}
const AFFINITY_NAMES := {
	Affinity.NORMAL: "Normal", Affinity.WEAK: "Weak", Affinity.RESIST: "Resists",
	Affinity.IMMUNE: "Immune", Affinity.ABSORB: "Absorbs",
}


static func name_of(e: int) -> String:
	return NAMES.get(e, "?")


static func adjective_of(e: int) -> String:
	return ADJECTIVES.get(e, name_of(e))


static func color_of(e: int) -> Color:
	return COLORS.get(e, Color.WHITE)


static func affinity_name(a: int) -> String:
	return AFFINITY_NAMES.get(a, "?")


static func is_valid(e) -> bool:
	return (e is int or e is float) and int(e) >= 0 and int(e) < Type.size()


static func list_text(elements: Array) -> String:
	return " + ".join(elements.map(func(e): return name_of(e)))


## What a hit with `elements` does to a target with `affinities` (Type -> Affinity).
## { "mult": float, "weak": bool, "resisted": bool, "immune": bool, "absorbed": bool,
##   "hit": { element: affinity } }   ("hit" = what this hit taught you)
static func resolve(elements: Array, affinities: Dictionary) -> Dictionary:
	var out := { "mult": 1.0, "weak": false, "resisted": false, "immune": false, "absorbed": false, "hit": {} }
	for e in elements:
		var a: int = affinities.get(e, Affinity.NORMAL)
		out.hit[e] = a
		match a:
			Affinity.WEAK:
				out.weak = true
				out.mult *= WEAK_MULT
			Affinity.RESIST:
				out.resisted = true
				out.mult *= RESIST_MULT
			Affinity.IMMUNE:
				out.immune = true
			Affinity.ABSORB:
				out.absorbed = true
	if out.absorbed:
		out.immune = false
		out.weak = false
	elif out.immune:
		out.mult = 0.0
		out.weak = false
	return out
