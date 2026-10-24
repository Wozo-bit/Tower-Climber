class_name Rarity
extends RefCounted
## Loot rarity tiers and the luck-scaled drop roll.
##
## Unique is special: weapons only, one per class, and only that class can equip it.
## It is NOT in the normal drop table — only stage bosses and roaming bosses can
## give one (see EnemyDef.unique_chance and LootTable.roll_enemy_loot).

enum Tier { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, UNIQUE }

const NAMES := {
	Tier.COMMON: "Common",
	Tier.UNCOMMON: "Uncommon",
	Tier.RARE: "Rare",
	Tier.EPIC: "Epic",
	Tier.LEGENDARY: "Legendary",
	Tier.UNIQUE: "Unique",
}

const COLORS := {
	Tier.COMMON: Color(0.85, 0.85, 0.85),
	Tier.UNCOMMON: Color(0.4, 0.9, 0.4),
	Tier.RARE: Color(0.35, 0.6, 1.0),
	Tier.EPIC: Color(0.75, 0.4, 1.0),
	Tier.LEGENDARY: Color(1.0, 0.6, 0.15),
	Tier.UNIQUE: Color(1.0, 0.3, 0.3),
}

## Drop weights at baseline Luck (5). They add up to 100, so they read as %.
const BASE_WEIGHTS := {
	Tier.COMMON: 55.0,
	Tier.UNCOMMON: 28.0,
	Tier.RARE: 12.0,
	Tier.EPIC: 4.0,
	Tier.LEGENDARY: 1.0,
}

## Each Luck point above the baseline boosts every tier above Common by
## LUCK_SCALING x (tier steps above Common). Higher tiers benefit more.
## e.g. Luck 25 -> Rare weight x2.2, Legendary x3.4.
const LUCK_BASELINE := 5
const LUCK_SCALING := 0.03


static func name_of(tier: int) -> String:
	return NAMES.get(tier, "?")


static func color_of(tier: int) -> Color:
	return COLORS.get(tier, Color.WHITE)


static func weights_for_luck(luck: int) -> Dictionary:
	var bonus := maxi(0, luck - LUCK_BASELINE) * LUCK_SCALING
	var out := {}
	for tier in BASE_WEIGHTS:
		out[tier] = BASE_WEIGHTS[tier] * (1.0 + bonus * tier)
	return out


## Chance (0-1) of each tier at a given Luck. Handy for tooltips/tests.
static func odds_for_luck(luck: int) -> Dictionary:
	var w := weights_for_luck(luck)
	var total := 0.0
	for t in w:
		total += w[t]
	var out := {}
	for t in w:
		out[t] = w[t] / total
	return out


static func roll(luck: int, rng: RandomNumberGenerator) -> int:
	var w := weights_for_luck(luck)
	var total := 0.0
	for t in w:
		total += w[t]
	var r := rng.randf() * total
	for t in [Tier.COMMON, Tier.UNCOMMON, Tier.RARE, Tier.EPIC, Tier.LEGENDARY]:
		r -= w[t]
		if r <= 0.0:
			return t
	return Tier.COMMON
