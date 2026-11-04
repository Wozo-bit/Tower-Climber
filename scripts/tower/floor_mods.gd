class_name FloorMods
extends RefCounted
## Late-floor twists (Hayden 2026-11-04: the late game was going stale). From
## FROM_FLOOR up, some plain floors change the rules for every fight on them.
## Picked from the floor's seed, so a floor keeps its twist after a reload.
##
## Battle knobs (BattleManager.apply_floor_mod reads them):
##   "magic":       everyone's magic damage x this
##   "dealt":       everyone's damage x this
##   "enemy_hp":    enemy HP x this
##   "enemy_dealt": enemy damage x this
##   "mp_regen":    the party regains this share of max MP each round
##   "no_items":    items don't work in battle
##   "xp" / "gold": rewards x this

const FROM_FLOOR := 30
const CHANCE := 0.35

const MODS := {
	&"anti_magic": { "name": "Null Field", "desc": "Magic is weak here: all magic deals 30% less, but fights pay 25% more XP.",
		"magic": 0.7, "xp": 1.25 },
	&"mana_well": { "name": "Mana Well", "desc": "The air hums: your party regains 10% MP each round, but enemies hit 15% harder.",
		"mp_regen": 0.1, "enemy_dealt": 1.15 },
	&"no_items": { "name": "Silent Floor", "desc": "Nothing from your bag works in battle here, but enemies carry 50% more gold.",
		"no_items": true, "gold": 1.5 },
	&"gold_rush": { "name": "Gold Vein", "desc": "Double gold from fights, and enemies have 20% more HP.",
		"gold": 2.0, "enemy_hp": 1.2 },
	&"blood_moon": { "name": "Blood Moon", "desc": "Everyone hits 30% harder, on both sides. 50% more XP.",
		"dealt": 1.3, "xp": 1.5 },
}


## This floor's twist, or &"" for none. Rest and guardian floors never have one.
static func for_floor(n: int, floor_seed: int, is_rest: bool) -> StringName:
	if n < FROM_FLOOR or is_rest or StageLibrary.is_boss_floor(n) or StageLibrary.is_miniboss_floor(n):
		return &""
	var rng := RandomNumberGenerator.new()
	rng.seed = floor_seed + 104729
	if rng.randf() >= CHANCE:
		return &""
	var ids := MODS.keys()
	ids.sort_custom(func(a, b): return String(a) < String(b))
	return ids[rng.randi_range(0, ids.size() - 1)]


static func get_mod(id: StringName) -> Dictionary:
	return MODS.get(id, {})
