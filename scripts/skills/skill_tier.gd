class_name SkillTier
extends RefCounted
## Rarity tiers for learnable (shared) skills and their skill books.
## Separate from gear rarity: skills have no "Uncommon" tier.

enum Tier { COMMON, RARE, EPIC, LEGENDARY, UNIQUE }

const NAMES := {
	Tier.COMMON: "Common",
	Tier.RARE: "Rare",
	Tier.EPIC: "Epic",
	Tier.LEGENDARY: "Legendary",
	Tier.UNIQUE: "Unique",
}

## Same colours as gear rarities so players read them the same way.
const COLORS := {
	Tier.COMMON: Color(0.85, 0.85, 0.85),
	Tier.RARE: Color(0.35, 0.6, 1.0),
	Tier.EPIC: Color(0.75, 0.4, 1.0),
	Tier.LEGENDARY: Color(1.0, 0.6, 0.15),
	Tier.UNIQUE: Color(1.0, 0.3, 0.3),
}

## Skill book tier odds (%) below Luck 10.
const BASE_ODDS := {
	Tier.COMMON: 60.0,
	Tier.RARE: 30.0,
	Tier.EPIC: 8.0,
	Tier.LEGENDARY: 1.5,
	Tier.UNIQUE: 0.5,
}
## Every LUCK_STEP points of Luck (10, 20, 30, ...) is one step. Each step moves
## odds from Common/Rare into Epic/Legendary/Unique by these amounts (each step
## sums to zero). Tuned so Luck 40 gives 50 / 25 / 20 / 3 / 2.
const LUCK_STEP := 10
const PER_STEP := {
	Tier.COMMON: -2.5,
	Tier.RARE: -1.25,
	Tier.EPIC: 3.0,
	Tier.LEGENDARY: 0.375,
	Tier.UNIQUE: 0.375,
}
## Steps stop counting after this (Luck 100 -> 35 / 17.5 / 38 / 5.25 / 4.25).
const MAX_LUCK_STEPS := 10


static func name_of(tier: int) -> String:
	return NAMES.get(tier, "?")


static func color_of(tier: int) -> Color:
	return COLORS.get(tier, Color.WHITE)


static func luck_steps(luck: int) -> int:
	return clampi(luck / LUCK_STEP, 0, MAX_LUCK_STEPS)


static func odds_for_luck(luck: int) -> Dictionary:
	var steps := luck_steps(luck)
	var out := {}
	for t in BASE_ODDS:
		out[t] = BASE_ODDS[t] + PER_STEP[t] * steps
	return out


static func roll(luck: int, rng: RandomNumberGenerator) -> int:
	var odds := odds_for_luck(luck)
	var r := rng.randf() * 100.0
	for t in [Tier.COMMON, Tier.RARE, Tier.EPIC, Tier.LEGENDARY, Tier.UNIQUE]:
		r -= odds[t]
		if r < 0.0:
			return t
	return Tier.COMMON
