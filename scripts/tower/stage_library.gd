class_name StageLibrary
extends RefCounted
## The tower is split into stages of FLOORS_PER_STAGE floors. Each stage has a
## THEME (an enemy family), minibosses on chosen floors, and a boss on its last
## floor. The normal enemies and minibosses lead up to that boss, so the floors
## before it teach you its weaknesses (e.g. slimes on 1-9 -> King Slime on 10).
##
## Each stage SLOT has a pool of themes; every run (and every New Game+) picks
## one per slot, so the climb changes between runs. A slot can be "pinned" to
## one theme when the story needs it to always be the same.
##
## Nothing here is a hard rule: change FLOORS_PER_STAGE, give a theme more or
## fewer minibosses, or put them on other floors by editing the data below.
## Floors past the last slot reuse the slots in order (and enemy scaling makes
## them harder each time around).

const FLOORS_PER_STAGE := 10

## `encounters`: normal enemy groups on this stage's floors (floors 1-3 of the
##   tower use EnemyLibrary's smaller early groups, from `early_encounters`).
## `miniboss_floors`: floor numbers WITHIN the stage (1 = first floor of it).
## `boss`: the encounter on the stage's last floor (boss first, escorts after).
## `hint`: what the merchant and wall scrawls say about this stage (placeholder).
## `power`: (optional, default 1.0) how strong this theme's enemies are by
##   their own stats, compared to the goblins. Floor scaling divides it out
##   (and rewards with it), so any theme fits any slot: the floor sets the
##   difficulty, the theme just changes who you fight.
const THEMES := {
	&"goblin_warrens": {
		"name": "Goblin Warrens", "family": &"goblin",
		"hint": "(Placeholder) Goblins can't keep their eyes off whoever's shouting at them, and their leather won't stop an arrow.",
		"early_encounters": [[&"slime"], [&"slime", &"slime"], [&"goblin"], [&"slime", &"goblin"]],
		"encounters": [
			[&"goblin", &"goblin", &"goblin_archer"],
			[&"goblin", &"goblin_archer", &"goblin_archer"],
			[&"goblin", &"goblin", &"goblin"],
			[&"slime", &"goblin", &"goblin_archer"],
		],
		"miniboss_floors": {
			4: [&"goblin_captain", &"goblin", &"goblin"],
			9: [&"hobgoblin", &"goblin", &"goblin_archer"],
		},
		"boss": [&"goblin_king", &"goblin_sorcerer", &"goblin_archer"],
	},
	&"slime_pits": {
		"name": "Slime Pits", "family": &"slime",
		"hint": "(Placeholder) Slimes hate an open flame and a dry wind. Blades just slide through them; a hammer does better.",
		"early_encounters": [[&"slime"], [&"slime", &"slime"], [&"bubble_slime"], [&"slime", &"bubble_slime"]],
		"encounters": [
			[&"slime", &"slime", &"bubble_slime"],
			[&"mud_slime", &"slime", &"slime"],
			[&"mud_slime", &"bubble_slime"],
			[&"slime", &"slime", &"slime", &"bubble_slime"],
		],
		"miniboss_floors": {
			4: [&"big_slime", &"slime", &"slime"],
			9: [&"mire_slime", &"bubble_slime", &"mud_slime"],
		},
		"boss": [&"king_slime", &"bubble_slime", &"bubble_slime"],
	},
	&"orc_stronghold": {
		"name": "Orc Stronghold", "family": &"orc", "power": 1.4,
		"hint": "(Placeholder) Orc hide shrugs off a hammer, but a spear point or a hard frost gets through. Their shamans hate holy light.",
		"early_encounters": [[&"orc_brute"]],
		"encounters": [
			[&"orc_brute", &"goblin_archer", &"imp_shaman"],
			[&"goblin", &"orc_brute", &"goblin_archer", &"goblin_archer"],
			[&"orc_brute", &"orc_brute"],
			[&"orc_brute", &"imp_shaman", &"imp_shaman"],
		],
		"miniboss_floors": {
			4: [&"orc_warchief", &"orc_brute", &"imp_shaman"],
			9: [&"orc_blood_shaman", &"orc_brute", &"orc_brute"],
		},
		"boss": [&"orc_warlord", &"orc_blood_shaman", &"goblin_archer"],
	},
}

## Stage slots in climbing order. `themes` = the pool one is picked from each
## run. Add `"pinned": &"theme_id"` to force a slot to one theme (story).
const STAGE_SLOTS := [
	{ "themes": [&"goblin_warrens", &"slime_pits"] },
	{ "themes": [&"orc_stronghold"] },
]

## The theme picked for each slot this run (GameState sets and saves it).
## Empty or invalid entries fall back to the slot's first theme.
static var run_themes: Array = []


## Picks a theme for every slot (pinned slots always get their pin).
static func roll_themes(rng: RandomNumberGenerator) -> Array:
	var out := []
	for slot in STAGE_SLOTS:
		if slot.has("pinned"):
			out.append(slot.pinned)
		else:
			out.append(slot.themes[rng.randi_range(0, slot.themes.size() - 1)])
	return out


## Keeps only valid picks (per slot), e.g. for themes read from a save.
static func validate_themes(picks: Array) -> Array:
	var out := []
	for i in STAGE_SLOTS.size():
		var slot: Dictionary = STAGE_SLOTS[i]
		var pick := &""
		if i < picks.size() and (picks[i] is String or picks[i] is StringName):
			pick = StringName(picks[i])
		if slot.has("pinned"):
			pick = slot.pinned
		elif not slot.themes.has(pick):
			pick = slot.themes[0]
		out.append(pick)
	return out


static func theme_id_for_slot(slot_i: int) -> StringName:
	var slot: Dictionary = STAGE_SLOTS[slot_i]
	if slot.has("pinned"):
		return slot.pinned
	if slot_i < run_themes.size() and slot.themes.has(run_themes[slot_i]):
		return run_themes[slot_i]
	return slot.themes[0]

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


## Minibosses and bosses (and their escorts) follow the same floor curve as
## everyone else (GameState.enemy_scale_for_floor, about 1.0 at floor 10);
## their own stats already make them the big fight. This multiplies it.
## (Tuned with tools/balance_sim.)
const GUARDIAN_MULT := 0.9


static func guardian_scale(floor_n: int) -> float:
	return GameState.enemy_scale_for_floor(floor_n) * GUARDIAN_MULT


## How strong this floor's stage theme is by its own stats (THEMES "power").
static func theme_power(floor_n: int) -> float:
	return float(stage_for_floor(floor_n).get("power", 1.0))


# =========================================================
# Floor queries
# =========================================================

static func stage_number(floor_n: int) -> int:
	return (floor_n - 1) / FLOORS_PER_STAGE + 1


static func floor_in_stage(floor_n: int) -> int:
	return (floor_n - 1) % FLOORS_PER_STAGE + 1


## The theme this run uses for the stage `floor_n` is in.
static func stage_for_floor(floor_n: int) -> Dictionary:
	return THEMES[theme_id_for_floor(floor_n)]


static func theme_id_for_floor(floor_n: int) -> StringName:
	return theme_id_for_slot((stage_number(floor_n) - 1) % STAGE_SLOTS.size())


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
