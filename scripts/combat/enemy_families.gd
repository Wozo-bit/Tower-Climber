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
	# Guild guards, enforcers and champions: people, so no elemental quirks.
	&"human": { "name": "Guild fighters",
		"affinities": {},
		"traits": [] },
	&"beast": { "name": "Beasts",
		"affinities": { E.PIERCE: A.WEAK, E.BLUNT: A.RESIST },
		"traits": [&"reckless"] },
	# --- Stage families added 2026-10-25 (floors 11-60) ---
	&"bandit": { "name": "Bandits",
		"affinities": { E.LIGHTNING: A.WEAK, E.PIERCE: A.WEAK },
		"traits": [&"easily_distracted"] },
	&"insect": { "name": "Insects",
		"affinities": { E.FIRE: A.WEAK, E.WIND: A.WEAK, E.EARTH: A.RESIST, E.PIERCE: A.RESIST },
		"traits": [&"swarming"] },
	# Elementals shrug off blades and points (a hammer still cracks them); each
	# one also absorbs its own element and fears its opposite (set per enemy).
	&"elemental": { "name": "Elementals",
		"affinities": { E.SLASH: A.RESIST, E.PIERCE: A.RESIST },
		"traits": [] },
	&"undead": { "name": "Undead",
		"affinities": { E.HOLY: A.WEAK, E.FIRE: A.WEAK, E.DARK: A.RESIST, E.ICE: A.RESIST },
		"traits": [&"undying"] },
	&"demon": { "name": "Demons",
		"affinities": { E.HOLY: A.WEAK, E.ICE: A.WEAK, E.FIRE: A.RESIST, E.DARK: A.RESIST },
		"traits": [&"reckless"] },
	&"celestial": { "name": "Celestials",
		"affinities": { E.DARK: A.WEAK, E.HOLY: A.RESIST, E.LIGHTNING: A.RESIST },
		"traits": [] },
	&"dragon": { "name": "Dragons",
		"affinities": { E.ICE: A.WEAK, E.PIERCE: A.WEAK, E.FIRE: A.RESIST, E.SLASH: A.RESIST },
		"traits": [&"dragonscale"] },
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
	&"swarming": { "name": "Swarming",
		"desc": "Hits harder for every other swarmer still alive on its side. Thin them out." },
	&"undying": { "name": "Undying",
		"desc": "Survives its first killing blow with 1 HP, unless that blow is Holy or Fire." },
	&"dragonscale": { "name": "Dragonscale",
		"desc": "Takes less damage from anything that isn't one of its weaknesses." },
}

## Gelatinous: physical damage multiplier on the first physical hit each round.
const GELATINOUS_MULT := 0.5
## Reckless: damage multiplier while below half HP.
const RECKLESS_MULT := 1.3
## Swarming: +10% damage per other living swarmer (up to +30%).
const SWARM_PER_ALLY := 0.1
const SWARM_MAX := 0.3
## Dragonscale: damage multiplier on hits that aren't weaknesses.
const DRAGONSCALE_MULT := 0.75


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
