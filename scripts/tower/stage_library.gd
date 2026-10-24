class_name StageLibrary
extends RefCounted
## The tower is split into STAGES of FLOORS_PER_STAGE floors. Each stage has a
## theme, minibosses on chosen floors, and a boss on its last floor. The
## minibosses lead up to that boss (e.g. Hobgoblin on 9 -> Goblin King on 10).
##
## Nothing here is a hard rule: change FLOORS_PER_STAGE, give a stage more or
## fewer minibosses, or put them on other floors by editing the data below.
## Floors past the last defined stage reuse the stages in order (and enemy
## scaling makes them harder each time around).

const FLOORS_PER_STAGE := 10

## `miniboss_floors` uses floor numbers WITHIN the stage (1 = first floor of it).
## `boss` is the encounter on the stage's last floor (boss first, escorts after).
const STAGES := [
	{
		"name": "Goblin Warrens",
		"miniboss_floors": {
			4: [&"goblin_captain", &"goblin", &"goblin"],
			9: [&"hobgoblin", &"goblin", &"goblin_archer"],
		},
		"boss": [&"goblin_king", &"goblin_sorcerer", &"goblin_archer"],
	},
	{
		"name": "Orc Stronghold",
		"miniboss_floors": {
			4: [&"orc_warchief", &"orc_brute", &"imp_shaman"],
			9: [&"orc_blood_shaman", &"orc_brute", &"orc_brute"],
		},
		"boss": [&"orc_warlord", &"orc_blood_shaman", &"goblin_archer"],
	},
]

## Roaming bosses: lore bosses loose from their home floor. Once beaten
## they're gone for good. Only normal combat floors can have one, at most one
## per floor. Each has a `spawn` type:
##   "random" - ROAMING_SPAWN_CHANCE on any floor in its range.
##   "story"  - guaranteed: shows up on the first normal floor from
##              `story_floor` on (within its range) until beaten. Optional
##              `requires_flag` delays it until that story flag is set.
##              Keep this to ONE roamer (the tests check it).
##   "secret" - tied to a secret-class path (SecretPaths). Never appears
##              otherwise; once the player is on that path it's guaranteed on
##              the first normal floor in its range until beaten.
## Priority when several could appear: secret, then story, then random.
const ROAMING_SPAWN_CHANCE := 0.12
const ROAMING_BOSSES := [
	{ "id": &"labyrinth_minotaur", "spawn": "story", "story_floor": 7, "requires_flag": &"",
		"origin_floor": 30, "min_floor": 6, "max_floor": 19,
		"group": [&"labyrinth_minotaur"] },
	{ "id": &"lantern_wraith", "spawn": "random",
		"origin_floor": 25, "min_floor": 8, "max_floor": 22,
		"group": [&"lantern_wraith", &"imp_shaman"] },
	{ "id": &"ashen_wyrmling", "spawn": "secret", "secret_path": &"ashbound",
		"origin_floor": 40, "min_floor": 12, "max_floor": 29,
		"group": [&"ashen_wyrmling", &"imp_shaman"],
		"intro": "The air smells of ash... something from far above has come looking for you." },
]


## Minibosses/bosses are balanced by hand for their stage (scale 1.0). When the
## stage list repeats (floor 30+ with 2 stages), they come back this much stronger.
const GUARDIAN_SCALE_PER_REPEAT := 0.6


static func guardian_scale(floor_n: int) -> float:
	var repeat := (stage_number(floor_n) - 1) / STAGES.size()
	return 1.0 + GUARDIAN_SCALE_PER_REPEAT * repeat


# =========================================================
# Floor queries
# =========================================================

static func stage_number(floor_n: int) -> int:
	return (floor_n - 1) / FLOORS_PER_STAGE + 1


static func floor_in_stage(floor_n: int) -> int:
	return (floor_n - 1) % FLOORS_PER_STAGE + 1


static func stage_for_floor(floor_n: int) -> Dictionary:
	return STAGES[(stage_number(floor_n) - 1) % STAGES.size()]


static func stage_name(floor_n: int) -> String:
	return "Stage %d: %s" % [stage_number(floor_n), stage_for_floor(floor_n).name]


static func is_boss_floor(floor_n: int) -> bool:
	return floor_in_stage(floor_n) == FLOORS_PER_STAGE


static func is_miniboss_floor(floor_n: int) -> bool:
	return stage_for_floor(floor_n).miniboss_floors.has(floor_in_stage(floor_n))


static func miniboss_for_floor(floor_n: int) -> Array[StringName]:
	return _typed(stage_for_floor(floor_n).miniboss_floors.get(floor_in_stage(floor_n), []))


static func boss_for_floor(floor_n: int) -> Array[StringName]:
	if not is_boss_floor(floor_n):
		return [] as Array[StringName]
	return _typed(stage_for_floor(floor_n).boss)


static func _in_range(r: Dictionary, floor_n: int, defeated: Array) -> bool:
	return floor_n >= r.min_floor and floor_n <= r.max_floor and not defeated.has(r.id)


## RANDOM roamers that could appear on this floor (not beaten yet).
static func eligible_roamers(floor_n: int, defeated: Array) -> Array:
	var out := []
	for r in ROAMING_BOSSES:
		if r.get("spawn", "random") == "random" and _in_range(r, floor_n, defeated):
			out.append(r)
	return out


## The roamer that MUST appear on this floor, if any (secret first, then story).
static func guaranteed_roamer(floor_n: int, defeated: Array, flags: Dictionary) -> Dictionary:
	for r in ROAMING_BOSSES:
		if r.get("spawn") == "secret" and _in_range(r, floor_n, defeated) \
				and SecretPaths.is_on_path(r.secret_path, flags):
			return r
	for r in ROAMING_BOSSES:
		if r.get("spawn") == "story" and _in_range(r, floor_n, defeated) and floor_n >= r.story_floor:
			var req: StringName = r.get("requires_flag", &"")
			if req == &"" or flags.get(req, false):
				return r
	return {}


static func roamer_info(id: StringName) -> Dictionary:
	for r in ROAMING_BOSSES:
		if r.id == id:
			return r
	return {}


static func _typed(ids: Array) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in ids:
		out.append(id)
	return out
