class_name EnemyFamilies
extends RefCounted
## Enemy families share weaknesses, resistances and traits, so what you learn
## fighting slimes on floors 1-9 tells you how to beat the slime boss on 10.
## An EnemyDef joins a family with `family`, and can override single elements
## with its own `affinities` or add `traits`.
##
## Placeholder numbers: tune freely.

const E := Element.Type
const A := Element.Affinity

const FAMILIES := {
	&"slime": { "name": "Slimes",
		"affinities": { E.FIRE: A.WEAK, E.WIND: A.WEAK, E.WATER: A.RESIST, E.SLASH: A.RESIST, E.PIERCE: A.RESIST },
		"traits": [&"gelatinous"] },
	&"goblin": { "name": "Goblins",
		"affinities": { E.PIERCE: A.WEAK },
		"traits": [&"easily_distracted"] },
	&"orc": { "name": "Orcs",
		"affinities": { E.PIERCE: A.WEAK, E.ICE: A.WEAK, E.BLUNT: A.RESIST },
		"traits": [&"thick_skulled"] },
	&"imp": { "name": "Imps",
		"affinities": { E.HOLY: A.WEAK, E.WATER: A.WEAK, E.FIRE: A.RESIST, E.DARK: A.RESIST },
		"traits": [] },
	&"wraith": { "name": "Wraiths",
		"affinities": { E.HOLY: A.WEAK, E.BLUNT: A.WEAK, E.PIERCE: A.RESIST, E.SLASH: A.RESIST, E.DARK: A.IMMUNE },
		"traits": [] },
	&"wyrm": { "name": "Wyrms",
		"affinities": { E.ICE: A.WEAK, E.WATER: A.WEAK, E.FIRE: A.ABSORB },
		"traits": [] },
	&"beast": { "name": "Beasts",
		"affinities": { E.PIERCE: A.WEAK, E.BLUNT: A.RESIST },
		"traits": [&"reckless"] },
}

const TRAITS := {
	&"gelatinous": { "name": "Gelatinous",
		"desc": "The first physical hit it takes each round only does half damage." },
	&"easily_distracted": { "name": "Easily distracted",
		"desc": "Taunt lasts 1 turn longer against it, and it goes after whoever hit it last." },
	&"thick_skulled": { "name": "Thick-skulled",
		"desc": "Takes one more weakness hit to stagger." },
	&"reckless": { "name": "Reckless",
		"desc": "Hits harder once it's below half HP." },
}

## Gelatinous: physical damage multiplier on the first physical hit each round.
const GELATINOUS_MULT := 0.5
## Reckless: damage multiplier while below half HP.
const RECKLESS_MULT := 1.3


static func family_name(id: StringName) -> String:
	return FAMILIES.get(id, {}).get("name", "Unknown")


## Element -> Affinity for this enemy: its family's, with its own overrides on top.
static func affinities_for(def: EnemyDef) -> Dictionary:
	var out: Dictionary = FAMILIES.get(def.family, {}).get("affinities", {}).duplicate()
	out.merge(def.affinities, true)
	return out


static func traits_for(def: EnemyDef) -> Array[StringName]:
	var out: Array[StringName] = []
	for t in FAMILIES.get(def.family, {}).get("traits", []) + def.traits:
		if not out.has(t):
			out.append(t)
	return out


static func trait_name(id: StringName) -> String:
	return TRAITS.get(id, {}).get("name", String(id))


static func trait_desc(id: StringName) -> String:
	return TRAITS.get(id, {}).get("desc", "")
