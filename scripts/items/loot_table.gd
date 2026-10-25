class_name LootTable
extends RefCounted
## Generates gear drops: pick a base item, roll rarity (Luck-scaled), then
## roll stat bonuses sized by rarity and floor. All numbers are placeholders.

const S := Stats.Type
const W := GearItem.Slot.WEAPON
const A := GearItem.Slot.ARMOR
const X := GearItem.Slot.ACCESSORY

const K := Element.Type

## Chance an ordinary (non-boss) enemy drops a Potion when beaten.
const NORMAL_POTION_DROP := 0.08

## Base item types. `stats` = the stats this item favours (primary lines).
## Weapons have a `kind` (Slash / Pierce / Blunt) that physical attacks use.
const BASES := {
	&"sword":  { "name": "Sword",  "slot": W, "stats": [S.STRENGTH, S.HEALTH], "kind": K.SLASH },
	&"mace":   { "name": "Mace",   "slot": W, "stats": [S.STRENGTH, S.STAMINA], "kind": K.BLUNT },
	&"staff":  { "name": "Staff",  "slot": W, "stats": [S.INTELLIGENCE], "kind": K.BLUNT },
	&"bow":    { "name": "Bow",    "slot": W, "stats": [S.AGILITY, S.STRENGTH], "kind": K.PIERCE },
	&"dagger": { "name": "Dagger", "slot": W, "stats": [S.AGILITY, S.LUCK], "kind": K.PIERCE },
	&"scepter": { "name": "Scepter", "slot": W, "stats": [S.INTELLIGENCE, S.STAMINA], "kind": K.BLUNT },
	&"plate":  { "name": "Plate Armor",  "slot": A, "stats": [S.HEALTH, S.STAMINA] },
	&"leather": { "name": "Leather Vest", "slot": A, "stats": [S.AGILITY, S.STAMINA] },
	&"robe":   { "name": "Robe",   "slot": A, "stats": [S.INTELLIGENCE, S.STAMINA] },
	&"ring":   { "name": "Ring",   "slot": X, "stats": [] },   # random stats
	&"amulet": { "name": "Amulet", "slot": X, "stats": [] },
}

## Name prefix per rarity: "Iron Sword", "Mithril Bow", ...
const MATERIALS := {
	Rarity.Tier.COMMON: "Iron",
	Rarity.Tier.UNCOMMON: "Steel",
	Rarity.Tier.RARE: "Mithril",
	Rarity.Tier.EPIC: "Runed",
	Rarity.Tier.LEGENDARY: "Ascendant",
}

## How many stat lines each rarity rolls.
const STAT_LINES := {
	Rarity.Tier.COMMON: 1,
	Rarity.Tier.UNCOMMON: 2,
	Rarity.Tier.RARE: 2,
	Rarity.Tier.EPIC: 3,
	Rarity.Tier.LEGENDARY: 3,
	Rarity.Tier.UNIQUE: 3,
}

## Total stat points = (BUDGET_BASE + BUDGET_PER_FLOOR * floor) * multiplier.
const BUDGET_BASE := 2.0
const BUDGET_PER_FLOOR := 0.5
const BUDGET_MULT := {
	Rarity.Tier.COMMON: 1.0,
	Rarity.Tier.UNCOMMON: 1.4,
	Rarity.Tier.RARE: 1.9,
	Rarity.Tier.EPIC: 2.6,
	Rarity.Tier.LEGENDARY: 3.4,
	Rarity.Tier.UNIQUE: 4.5,
}

## Chance a weapon of this rarity rolls an element (added to basic attacks).
const ELEMENT_CHANCE := {
	Rarity.Tier.RARE: 0.25,
	Rarity.Tier.EPIC: 0.35,
	Rarity.Tier.LEGENDARY: 0.5,
}

## One Unique weapon per class. Only that class can equip it.
## `weights` = how its stat budget is split.
const UNIQUES := {
	&"tank": { "name": "Bulwark of the First Climber", "base": &"mace",
		"weights": { S.HEALTH: 3, S.STAMINA: 3, S.STRENGTH: 2 },
		"desc": "A hammer said to have held the tower's first gate." },
	&"mage": { "name": "Starfall Staff", "base": &"staff",
		"weights": { S.INTELLIGENCE: 6, S.LUCK: 1, S.STAMINA: 1 },
		"desc": "Faint constellations drift inside its crystal." },
	&"archer": { "name": "Windpiercer", "base": &"bow",
		"weights": { S.AGILITY: 4, S.STRENGTH: 3, S.LUCK: 1 },
		"desc": "Its string hums before the wind changes." },
	&"rogue": { "name": "Fang of Fortune", "base": &"dagger",
		"weights": { S.AGILITY: 3, S.LUCK: 4, S.STRENGTH: 1 },
		"desc": "It always seems to find the gap in the armor." },
	&"support": { "name": "Lifebloom Scepter", "base": &"scepter",
		"weights": { S.INTELLIGENCE: 4, S.STAMINA: 3, S.HEALTH: 1 },
		"desc": "Flowers bloom where it touches stone." },
}


static func budget_for(rarity: int, item_level: int) -> float:
	return (BUDGET_BASE + BUDGET_PER_FLOOR * item_level) * BUDGET_MULT[rarity]


## Each Luck point above 5 raises a boss's Unique chance by this fraction.
## e.g. 8% base at Luck 25 -> 8% x (1 + 20 x 0.02) = 11.2%.
const UNIQUE_LUCK_SCALING := 0.02


## One normal drop (never Unique). `min_rarity` floors the result.
static func roll_drop(luck: int, item_level: int, rng: RandomNumberGenerator,
		min_rarity: int = Rarity.Tier.COMMON) -> GearItem:
	var rarity := maxi(Rarity.roll(luck, rng), min_rarity)
	var base_ids := BASES.keys()
	base_ids.sort_custom(func(a, b): return String(a) < String(b))   # by name (StringNames sort by address)
	return make_gear(base_ids[rng.randi_range(0, base_ids.size() - 1)], rarity, item_level, rng)


## All gear an enemy drops on defeat, using its loot profile (EnemyDef).
## Uniques can only come from enemies with unique_chance > 0 (stage bosses and
## roaming bosses), and only for a class in the party that doesn't own theirs yet.
static func roll_enemy_loot(def: EnemyDef, luck: int, item_level: int, rng: RandomNumberGenerator,
		party_classes: Array = [], owned_uniques: Array = []) -> Array[GearItem]:
	var out: Array[GearItem] = []
	var rolls := def.loot_rolls
	if rolls <= 0:
		return out
	if def.unique_chance > 0.0:
		var candidates: Array = []
		for c in party_classes:
			if UNIQUES.has(c) and not owned_uniques.has(c) and not candidates.has(c):
				candidates.append(c)
		if not candidates.is_empty() and rng.randf() < unique_chance_for(def, luck):
			candidates.sort_custom(func(a, b): return String(a) < String(b))   # by name (StringNames sort by address)
			out.append(make_unique(candidates[rng.randi_range(0, candidates.size() - 1)], item_level))
			rolls -= 1
	for i in rolls:
		out.append(roll_drop(luck + def.loot_luck_bonus, item_level, rng, def.min_loot_rarity))
	return out


static func unique_chance_for(def: EnemyDef, luck: int) -> float:
	return def.unique_chance * (1.0 + maxi(0, luck - Rarity.LUCK_BASELINE) * UNIQUE_LUCK_SCALING)


static func make_gear(base_id: StringName, rarity: int, item_level: int, rng: RandomNumberGenerator) -> GearItem:
	var base: Dictionary = BASES[base_id]
	var g := GearItem.new()
	g.base_id = base_id
	g.slot = base.slot
	g.rarity = rarity
	g.item_level = item_level
	g.display_name = "%s %s" % [MATERIALS.get(rarity, ""), base.name]

	# Pick stat lines: the base's primary stats first, then random extras.
	var lines: Array = []
	for s in base.stats:
		if lines.size() < STAT_LINES[rarity]:
			lines.append(s)
	var pool := Stats.all().filter(func(s): return not lines.has(s))
	while lines.size() < STAT_LINES[rarity] and not pool.is_empty():
		lines.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))

	# Primary lines get double weight.
	var weights := {}
	for s in lines:
		weights[s] = 2.0 if base.stats.has(s) else 1.0
	g.bonuses = _split_budget(budget_for(rarity, item_level), weights)

	# Rare+ weapons may carry an element ("Flame Mithril Sword").
	if g.slot == W and rng.randf() < ELEMENT_CHANCE.get(rarity, 0.0):
		g.element = Element.MAGIC_ELEMENTS[rng.randi_range(0, Element.MAGIC_ELEMENTS.size() - 1)]
		g.display_name = "%s %s" % [Element.adjective_of(g.element), g.display_name]
	return g


static func make_unique(class_id: StringName, item_level: int) -> GearItem:
	var u: Dictionary = UNIQUES[class_id]
	var g := GearItem.new()
	g.base_id = u.base
	g.slot = GearItem.Slot.WEAPON
	g.rarity = Rarity.Tier.UNIQUE
	g.item_level = item_level
	g.display_name = u.name
	g.description = u.desc
	g.class_lock = class_id
	g.bonuses = _split_budget(budget_for(Rarity.Tier.UNIQUE, item_level), u.weights)
	return g


static func _split_budget(budget: float, weights: Dictionary) -> Dictionary:
	var total := 0.0
	for s in weights:
		total += weights[s]
	var out := {}
	for s in weights:
		out[s] = maxi(1, roundi(budget * weights[s] / total))
	return out
