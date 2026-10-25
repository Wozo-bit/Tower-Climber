class_name StatBlock
extends Resource
## Holds a character's stats, split into BASE (the starting 5s) and ALLOCATED
## (points the player spent). Keeping them separate is what lets class
## thresholds ignore base stats, and lets a respec refund exactly what was spent.

# --- Balance knobs for derived stats (placeholders until combat math is designed) ---
const HP_BASE := 50
const HP_PER_HEALTH := 10
const MP_BASE := 10
const MP_PER_INTELLIGENCE := 3
const PHYS_DEF_PER_STAMINA := 1.0
const MAG_DEF_PER_INTELLIGENCE := 1.0
const MAG_DEF_PER_STAMINA := MAG_DEF_PER_INTELLIGENCE * 0.25  # 1/4 of Intelligence's rate
const DODGE_PER_AGILITY := 0.005   # 0.5% per point
const DODGE_CAP := 0.5
const CRIT_BASE := 0.05
const CRIT_PER_LUCK := 0.005       # 0.5% per point
const CRIT_CAP := 0.75

@export var base: Dictionary = {}       # Stats.Type -> int
@export var allocated: Dictionary = {}  # Stats.Type -> int
## Bonuses from equipped gear. Count toward totals (and derived stats) but
## NOT toward class thresholds, which only look at allocated points.
@export var gear_bonus: Dictionary = {}  # Stats.Type -> int
## Multiplier from the character's class (e.g. 0.2 = +20% to every stat total).
## Only special classes use it. Doesn't touch class thresholds either.
@export var class_bonus_pct: float = 0.0
## Per-stat change from blessings and curses: Stats.Type -> pct (+0.1 / -0.05).
## Set by CharacterData.refresh_blessing(). Doesn't touch class thresholds.
@export var blessing_pct: Dictionary = {}


func _init() -> void:
	for stat in Stats.all():
		if not base.has(stat):
			base[stat] = Stats.BASE_VALUE
		if not allocated.has(stat):
			allocated[stat] = 0


# --- Raw values ---

func get_base(stat: int) -> int:
	return base.get(stat, 0)


func get_allocated(stat: int) -> int:
	return allocated.get(stat, 0)


func get_total(stat: int) -> int:
	var raw := get_base(stat) + get_allocated(stat) + get_gear_bonus(stat)
	var pct: float = class_bonus_pct + blessing_pct.get(stat, 0.0)
	if pct == 0.0:
		return raw
	return maxi(1, roundi(raw * (1.0 + pct)))


func get_gear_bonus(stat: int) -> int:
	return gear_bonus.get(stat, 0)


func total_allocated() -> int:
	var sum := 0
	for stat in Stats.all():
		sum += get_allocated(stat)
	return sum


func add_allocated(stat: int, amount: int) -> void:
	allocated[stat] = maxi(0, get_allocated(stat) + amount)
	emit_changed()


## Clears all allocated points and returns how many were refunded.
func reset_allocated() -> int:
	var refunded := total_allocated()
	for stat in Stats.all():
		allocated[stat] = 0
	emit_changed()
	return refunded


## Fraction (0.0-1.0) of ALLOCATED points that sit in the given stats.
## Used for class unlock checks. Returns 0 when nothing is allocated.
func allocated_share(stats: Array) -> float:
	var total := total_allocated()
	if total <= 0:
		return 0.0
	var in_group := 0
	for stat in stats:
		in_group += get_allocated(stat)
	return float(in_group) / float(total)


# --- Derived stats ---

func max_hp() -> int:
	return HP_BASE + get_total(Stats.Type.HEALTH) * HP_PER_HEALTH


func max_mp() -> int:
	return MP_BASE + get_total(Stats.Type.INTELLIGENCE) * MP_PER_INTELLIGENCE


func physical_defense() -> float:
	return get_total(Stats.Type.STAMINA) * PHYS_DEF_PER_STAMINA


func magic_defense() -> float:
	return get_total(Stats.Type.INTELLIGENCE) * MAG_DEF_PER_INTELLIGENCE \
		+ get_total(Stats.Type.STAMINA) * MAG_DEF_PER_STAMINA


func dodge_chance() -> float:
	return minf(get_total(Stats.Type.AGILITY) * DODGE_PER_AGILITY, DODGE_CAP)


func crit_chance() -> float:
	return minf(CRIT_BASE + get_total(Stats.Type.LUCK) * CRIT_PER_LUCK, CRIT_CAP)


## Higher = more likely to act first. Combat system decides how to roll it.
func turn_priority() -> int:
	return get_total(Stats.Type.AGILITY)


func loot_luck() -> int:
	return get_total(Stats.Type.LUCK)
