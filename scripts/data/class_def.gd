class_name ClassDef
extends Resource
## Definition of a class the player can unlock.
## Tier 1 classes unlock at level 10 purely from stat distribution.
## Tier 2+ will add quest/story gates on top (see `advances_from`).

## Tiny tolerance so 21/35 == 60% never fails due to float rounding.
const EPSILON := 0.0001

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var tier: int = 1
## Stats (Stats.Type values) whose ALLOCATED points count toward the threshold.
@export var required_stats: Array[int] = []
## Share of allocated points that must be in `required_stats` (0.0-1.0).
@export_range(0.0, 1.0, 0.01) var threshold: float = 0.6
## For tier 2+: the class this one advances from. Unused for tier 1.
@export var advances_from: StringName = &""
## Hidden classes don't show as "almost qualified" hints, and are only offered
## once unlocked (secret questline or New Game+).
@export var is_secret: bool = false
## Only available in New Game+ runs.
@export var ng_plus_only: bool = false
## Boost to every stat total while in this class (0.2 = +20%).
@export var stat_bonus_pct: float = 0.0
## Only on this route (RouteLibrary id, e.g. &"villain"). Empty = any route.
## Meant for tier-2 advancements; checked by CharacterData.
@export var required_route: StringName = &""


## True if the current run's route allows this class.
func route_allows() -> bool:
	return required_route == &"" or GameState.route.current() == required_route


static func create(p_id: StringName, p_name: String, p_desc: String,
		p_stats: Array[int], p_threshold: float, p_tier: int = 1) -> ClassDef:
	var def := ClassDef.new()
	def.id = p_id
	def.display_name = p_name
	def.description = p_desc
	def.required_stats = p_stats
	def.threshold = p_threshold
	def.tier = p_tier
	return def


## Current share of allocated points in this class's stats.
func qualification_share(stats: StatBlock) -> float:
	return stats.allocated_share(required_stats)


func qualifies(stats: StatBlock) -> bool:
	if stats.total_allocated() <= 0:
		return false
	return qualification_share(stats) + EPSILON >= threshold


## How many more points in the required stats would be needed to qualify,
## assuming those points are added on top of the current allocation.
func points_short(stats: StatBlock) -> int:
	var total := stats.total_allocated()
	var in_group := 0
	for s in required_stats:
		in_group += stats.get_allocated(s)
	var needed := 0
	# Solve (in_group + x) / (total + x) >= threshold for the smallest whole x.
	while total + needed > 0 and float(in_group + needed) / float(total + needed) + EPSILON < threshold:
		needed += 1
		if needed > 999:
			break
	if total + needed == 0:
		needed = 1
	return needed


func requirement_text() -> String:
	if threshold <= 0.0 or required_stats.is_empty():
		return "no stat requirement"
	var names: PackedStringArray = []
	for s in required_stats:
		names.append(Stats.name_of(s))
	return "%d%% of allocated points in %s" % [roundi(threshold * 100.0), " + ".join(names)]
