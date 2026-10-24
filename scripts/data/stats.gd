class_name Stats
extends RefCounted
## Central definition of the six core stats. Everything else refers to
## Stats.Type values (plain ints) so adding a stat later is a one-file change.

enum Type { HEALTH, STRENGTH, INTELLIGENCE, STAMINA, AGILITY, LUCK }

## Every character starts with this much in every stat.
## Base points never count toward class unlock thresholds.
const BASE_VALUE := 5

const DISPLAY_NAMES := {
	Type.HEALTH: "Health",
	Type.STRENGTH: "Strength",
	Type.INTELLIGENCE: "Intelligence",
	Type.STAMINA: "Stamina",
	Type.AGILITY: "Agility",
	Type.LUCK: "Luck",
}

const SHORT_NAMES := {
	Type.HEALTH: "HLT",
	Type.STRENGTH: "STR",
	Type.INTELLIGENCE: "INT",
	Type.STAMINA: "STA",
	Type.AGILITY: "AGI",
	Type.LUCK: "LCK",
}

const DESCRIPTIONS := {
	Type.HEALTH: "Increases maximum HP.",
	Type.STRENGTH: "Increases physical damage.",
	Type.INTELLIGENCE: "Increases magic damage and magic defense.",
	Type.STAMINA: "Increases physical defense, and magic defense at 1/4 the rate of Intelligence.",
	Type.AGILITY: "Increases turn priority and dodge chance.",
	Type.LUCK: "Increases critical hit chance and item roll quality.",
}


static func all() -> Array:
	return Type.values()


static func name_of(stat: int) -> String:
	return DISPLAY_NAMES.get(stat, "???")


static func short_name_of(stat: int) -> String:
	return SHORT_NAMES.get(stat, "???")


static func description_of(stat: int) -> String:
	return DESCRIPTIONS.get(stat, "")
