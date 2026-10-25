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

	# --- Added 2026-10-25 (Hayden's climb: Slimes/Goblins -> Bandits/Orcs ->
	# Insects/Beasts -> Elemental Rift/Undead -> Demons/Angels/Dragons). ---
	&"bandit_fortress": {
		"name": "Bandit Fortress", "family": &"bandit",
		"hint": "(Placeholder) Bandits wear cheap mail: a bolt of lightning or a good spear finds the gaps. They lose their heads when someone shouts at them.",
		"encounters": [
			[&"bandit_cutthroat", &"bandit_crossbow", &"bandit_hexer"],
			[&"bandit_brute", &"bandit_cutthroat", &"bandit_crossbow"],
			[&"bandit_brute", &"bandit_hexer"],
			[&"bandit_cutthroat", &"bandit_cutthroat", &"bandit_crossbow", &"bandit_hexer"],
		],
		"miniboss_floors": {
			4: [&"bandit_captain", &"bandit_cutthroat", &"bandit_crossbow"],
			9: [&"bandit_quartermaster", &"bandit_brute", &"bandit_brute"],
		},
		"boss": [&"bandit_lord", &"bandit_hexer", &"bandit_crossbow"],
	},
	&"insect_hive": {
		"name": "Insect Hive", "family": &"insect", "power": 1.1,
		"hint": "(Placeholder) The hive hates fire and a strong wind. Kill them fast: every one left alive makes the rest bolder.",
		"encounters": [
			[&"hive_soldier", &"hive_drone", &"acid_spitter"],
			[&"hive_drone", &"hive_drone", &"hive_nurse"],
			[&"hive_soldier", &"acid_spitter", &"hive_nurse"],
			[&"hive_drone", &"hive_drone", &"hive_drone", &"acid_spitter"],
		],
		"miniboss_floors": {
			4: [&"hive_warden", &"hive_drone", &"hive_drone"],
			9: [&"brood_mother", &"hive_soldier", &"hive_nurse"],
		},
		"boss": [&"hive_queen", &"hive_soldier", &"hive_nurse"],
	},
	&"beast_den": {
		"name": "Beast Den", "family": &"beast",
		"hint": "(Placeholder) A spear stops a charge; a club just makes them angry. Wounded beasts fight hardest, so finish them.",
		"encounters": [
			[&"dire_wolf", &"dire_wolf", &"razor_hawk"],
			[&"cave_bear", &"razor_hawk"],
			[&"boar", &"dire_wolf", &"razor_hawk"],
			[&"dire_wolf", &"boar", &"dire_wolf", &"razor_hawk"],
		],
		"miniboss_floors": {
			4: [&"pack_leader", &"dire_wolf", &"dire_wolf"],
			9: [&"elder_bear", &"boar", &"razor_hawk"],
		},
		"boss": [&"moonfang", &"dire_wolf", &"razor_hawk"],
	},
	&"elemental_rift": {
		"name": "Elemental Rift", "family": &"elemental", "power": 1.3,
		"hint": "(Placeholder) Blades and arrows barely scratch the spirits here, but a hammer cracks them. Fight fire with water, frost with fire, lightning with stone, and never feed one its own element.",
		"encounters": [
			[&"stone_golem", &"ember_sprite", &"frost_wisp"],
			[&"stone_golem", &"storm_spirit"],
			[&"ember_sprite", &"frost_wisp", &"storm_spirit"],
			[&"stone_golem", &"stone_golem", &"storm_spirit", &"ember_sprite"],
		],
		"miniboss_floors": {
			4: [&"magma_colossus", &"ember_sprite", &"ember_sprite"],
			9: [&"tempest_lord", &"stone_golem", &"storm_spirit"],
		},
		"boss": [&"rift_sovereign", &"stone_golem", &"frost_wisp"],
	},
	&"undead_crypt": {
		"name": "Undead Crypt", "family": &"undead", "power": 1.25,
		"hint": "(Placeholder) The dead get back up once, unless you burn them or bless them. Bones break under a hammer.",
		"encounters": [
			[&"skeleton_warrior", &"skeleton_archer", &"crypt_wraith"],
			[&"ghoul", &"ghoul", &"crypt_wraith"],
			[&"skeleton_warrior", &"ghoul", &"skeleton_archer"],
			[&"skeleton_warrior", &"skeleton_warrior", &"skeleton_archer", &"crypt_wraith"],
		],
		"miniboss_floors": {
			4: [&"bone_knight", &"skeleton_warrior", &"skeleton_archer"],
			9: [&"grave_priest", &"ghoul", &"crypt_wraith"],
		},
		"boss": [&"necromancer", &"bone_knight", &"crypt_wraith"],
	},
	&"demon_gate": {
		"name": "Demon Gate", "family": &"demon", "power": 1.1,
		"hint": "(Placeholder) Holy light and cold iron frighten them; fire only feeds them. They fight dirtiest when they're bleeding.",
		"encounters": [
			[&"lesser_fiend", &"hellhound", &"succubus"],
			[&"hellhound", &"hellhound", &"imp_swarm"],
			[&"lesser_fiend", &"imp_swarm", &"succubus"],
			[&"lesser_fiend", &"lesser_fiend", &"imp_swarm", &"imp_swarm"],
		],
		"miniboss_floors": {
			4: [&"pit_fiend", &"lesser_fiend", &"imp_swarm"],
			9: [&"hell_warlock", &"hellhound", &"succubus"],
		},
		"boss": [&"archfiend", &"pit_fiend", &"succubus"],
	},
	&"celestial_spire": {
		"name": "Celestial Spire", "family": &"celestial", "power": 1.1,
		"hint": "(Placeholder) The host of heaven turns aside holy light and lightning. Only darkness stains them.",
		"encounters": [
			[&"winged_sentinel", &"radiant_archer", &"choir_acolyte"],
			[&"virtue", &"winged_sentinel", &"choir_acolyte"],
			[&"winged_sentinel", &"radiant_archer"],
			[&"virtue", &"winged_sentinel", &"radiant_archer", &"choir_acolyte"],
		],
		"miniboss_floors": {
			4: [&"throne_guardian", &"winged_sentinel", &"choir_acolyte"],
			9: [&"choir_master", &"virtue", &"radiant_archer"],
		},
		"boss": [&"seraph_judicator", &"throne_guardian", &"choir_acolyte"],
	},
	&"dragon_roost": {
		"name": "Dragon Roost", "family": &"dragon", "power": 1.2,
		"hint": "(Placeholder) Dragonscale turns most blows. Ice and a well-aimed spear are what it fears.",
		"encounters": [
			[&"drakeling", &"wyvern", &"dragon_cultist"],
			[&"fire_drake", &"drakeling"],
			[&"drakeling", &"drakeling", &"wyvern"],
			[&"fire_drake", &"drakeling", &"wyvern", &"dragon_cultist"],
		],
		"miniboss_floors": {
			4: [&"drake_rider", &"drakeling", &"dragon_cultist"],
			9: [&"elder_wyvern", &"fire_drake", &"wyvern"],
		},
		"boss": [&"dragon_sovereign", &"fire_drake", &"wyvern"],
	},
}

## Stage slots in climbing order. `themes` = the pool one is picked from each
## run. Add `"pinned": &"theme_id"` to force a slot to one theme (story).
## Slots with the same `"group"` share their pool and never pick the same
## theme twice in a run: Demons, Angels and Dragons are all "pseudo-god"
## stages (Hayden), so any two of them can take floors 41-60 in any order.
const STAGE_SLOTS := [
	{ "themes": [&"goblin_warrens", &"slime_pits"] },
	{ "themes": [&"orc_stronghold", &"bandit_fortress"] },
	{ "themes": [&"insect_hive", &"beast_den"] },
	{ "themes": [&"elemental_rift", &"undead_crypt"] },
	{ "themes": [&"demon_gate", &"celestial_spire", &"dragon_roost"], "group": &"pseudo_god" },
	{ "themes": [&"demon_gate", &"celestial_spire", &"dragon_roost"], "group": &"pseudo_god" },
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
			continue
		var options: Array = slot.themes.filter(func(t): return not _taken_in_group(out, slot, t))
		if options.is_empty():
			options = slot.themes
		out.append(options[rng.randi_range(0, options.size() - 1)])
	return out


## True if an earlier slot of the same group already took `theme`.
static func _taken_in_group(picks: Array, slot: Dictionary, theme: StringName) -> bool:
	if not slot.has("group"):
		return false
	for i in picks.size():
		if STAGE_SLOTS[i].get("group", &"") == slot.group and picks[i] == theme:
			return true
	return false


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
		elif not slot.themes.has(pick) or _taken_in_group(out, slot, pick):
			var free: Array = slot.themes.filter(func(t): return not _taken_in_group(out, slot, t))
			pick = free[0] if not free.is_empty() else slot.themes[0]
		out.append(pick)
	return out


static func theme_id_for_slot(slot_i: int) -> StringName:
	var slot: Dictionary = STAGE_SLOTS[slot_i]
	if slot.has("pinned"):
		return slot.pinned
	if slot_i < run_themes.size() and slot.themes.has(run_themes[slot_i]):
		return run_themes[slot_i]
	return validate_themes(run_themes)[slot_i]   # defaults that respect groups

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
const GUARDIAN_MULT := 0.85


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
