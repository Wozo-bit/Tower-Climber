class_name EnemyLibrary
extends RefCounted
## Test enemies roughly tuned against a level-10 party. Placeholders.

const S := Stats.Type
const FRONT := 0  # Combatant.Row.FRONT
const BACK := 1   # Combatant.Row.BACK

static var _enemies: Dictionary = _build()

## Encounter groups: lists of enemy ids. A floor would pick from its own list.
const TEST_ENCOUNTERS := [
	[&"goblin", &"goblin", &"goblin_archer"],
	[&"slime", &"slime", &"imp_shaman"],
	[&"orc_brute", &"goblin_archer", &"imp_shaman"],
	[&"goblin", &"orc_brute", &"goblin_archer", &"goblin_archer"],
]


## Smaller groups for the first few floors.
const EARLY_ENCOUNTERS := [
	[&"slime"],
	[&"slime", &"slime"],
	[&"goblin"],
	[&"slime", &"goblin"],
]
const EARLY_FLOOR_LIMIT := 3
## Floor 1 is tuned for a fresh level-1 pair (you + your childhood friend).
const FLOOR_ONE_ENCOUNTERS := [
	[&"slime"],
	[&"slime"],
	[&"slime", &"slime"],
	[&"goblin"],
]


## Picks an encounter group (enemy ids) suitable for a floor: the floor's
## stage theme decides the enemies (StageLibrary). Floor 1 is tuned for a
## fresh level-1 pair; floors 2-3 use the theme's smaller early groups.
static func encounter_for_floor(floor_number: int, rng: RandomNumberGenerator) -> Array[StringName]:
	var theme := StageLibrary.stage_for_floor(floor_number)
	var pool: Array = theme.encounters
	if floor_number <= EARLY_FLOOR_LIMIT:
		pool = theme.get("early_encounters", EARLY_ENCOUNTERS)
	if floor_number == 1:
		pool = FLOOR_ONE_ENCOUNTERS
	var out: Array[StringName] = []
	for id in pool[rng.randi_range(0, pool.size() - 1)]:
		out.append(id)
	return out


static func _build() -> Dictionary:
	var list: Array[EnemyDef] = [
		EnemyDef.make(&"slime", "Slime", {
			"family": &"slime",
			"max_hp": 90, "stats": {S.STRENGTH: 9, S.STAMINA: 8, S.AGILITY: 4},
			"row": FRONT, "xp_reward": 35, "gold_reward": 6, "color": Color(0.4, 0.8, 0.9)}),
		EnemyDef.make(&"goblin", "Goblin", {
			"family": &"goblin",
			"max_hp": 150, "stats": {S.HEALTH: 8, S.STRENGTH: 14, S.STAMINA: 10, S.AGILITY: 12, S.LUCK: 6},
			"row": FRONT, "xp_reward": 60, "gold_reward": 15, "color": Color(0.35, 0.7, 0.3)}),
		EnemyDef.make(&"goblin_archer", "Goblin Archer", {
			"family": &"goblin",
			"max_hp": 110, "stats": {S.STRENGTH: 10, S.STAMINA: 7, S.AGILITY: 16, S.LUCK: 8},
			"row": BACK, "basic_attack": &"attack_ranged", "xp_reward": 55, "gold_reward": 14,
			"color": Color(0.55, 0.65, 0.25)}),
		EnemyDef.make(&"orc_brute", "Orc Brute", {
			"family": &"orc",
			"max_hp": 260, "stats": {S.HEALTH: 14, S.STRENGTH: 20, S.STAMINA: 16, S.AGILITY: 6},
			"row": FRONT, "skills": [&"smash"] as Array[StringName], "xp_reward": 110, "gold_reward": 30,
			"color": Color(0.5, 0.35, 0.25)}),
		EnemyDef.make(&"imp_shaman", "Imp Shaman", {
			"family": &"imp",
			"max_hp": 105, "stats": {S.INTELLIGENCE: 18, S.STAMINA: 6, S.AGILITY: 12},
			"row": BACK, "basic_attack": &"attack_magic", "skills": [&"firebolt"] as Array[StringName],
			"skill_chance": 0.5, "xp_reward": 70, "gold_reward": 20, "color": Color(0.75, 0.3, 0.55)}),

		# --- Escorts ---
		EnemyDef.make(&"goblin_sorcerer", "Goblin Sorcerer", {
			"family": &"goblin",
			"max_hp": 220, "stats": {S.INTELLIGENCE: 20, S.STAMINA: 8, S.AGILITY: 11},
			"row": BACK, "basic_attack": &"attack_magic", "skills": [&"firebolt", &"heal"] as Array[StringName],
			"skill_chance": 0.5, "xp_reward": 120, "gold_reward": 30, "color": Color(0.45, 0.35, 0.8)}),

		# --- Minibosses (StageLibrary decides which floor uses which) ---
		EnemyDef.make(&"goblin_captain", "Goblin Captain", {
			"family": &"goblin",
			"max_hp": 320, "stats": {S.HEALTH: 10, S.STRENGTH: 13, S.STAMINA: 11, S.AGILITY: 10, S.LUCK: 6},
			"row": FRONT, "skills": [&"smash"] as Array[StringName], "skill_chance": 0.3,
			"xp_reward": 180, "gold_reward": 60, "color": Color(0.5, 0.75, 0.3),
			"is_boss": true, "is_miniboss": true, "loot_rolls": 1}),
		EnemyDef.make(&"hobgoblin", "Hobgoblin", {
			"family": &"goblin",
			"max_hp": 520, "stats": {S.HEALTH: 12, S.STRENGTH: 19, S.STAMINA: 14, S.AGILITY: 12, S.LUCK: 8},
			"row": FRONT, "skills": [&"smash"] as Array[StringName], "skill_chance": 0.4,
			"xp_reward": 300, "gold_reward": 90, "color": Color(0.25, 0.55, 0.2),
			"is_boss": true, "is_miniboss": true, "loot_rolls": 1}),
		EnemyDef.make(&"orc_warchief", "Orc Warchief", {
			"family": &"orc",
			"max_hp": 700, "stats": {S.HEALTH: 16, S.STRENGTH: 23, S.STAMINA: 18, S.AGILITY: 8},
			"row": FRONT, "skills": [&"smash", &"war_cry"] as Array[StringName], "skill_chance": 0.45,
			"xp_reward": 420, "gold_reward": 130, "color": Color(0.6, 0.3, 0.15),
			"is_boss": true, "is_miniboss": true, "loot_rolls": 1}),
		EnemyDef.make(&"orc_blood_shaman", "Orc Blood Shaman", {
			"family": &"orc",
			"max_hp": 480, "stats": {S.INTELLIGENCE: 22, S.STAMINA: 14, S.HEALTH: 10, S.AGILITY: 9},
			"row": BACK, "basic_attack": &"attack_magic", "skills": [&"firebolt", &"heal", &"ward"] as Array[StringName],
			"skill_chance": 0.5, "xp_reward": 380, "gold_reward": 110, "color": Color(0.65, 0.15, 0.2),
			"is_boss": true, "is_miniboss": true, "loot_rolls": 1}),
		# --- Slime Pits (stage theme that can replace the Goblin Warrens) ---
		EnemyDef.make(&"bubble_slime", "Bubble Slime", {
			"family": &"slime",
			"max_hp": 100, "stats": {S.INTELLIGENCE: 14, S.STAMINA: 7, S.AGILITY: 8},
			"row": BACK, "basic_attack": &"attack_magic", "skills": [&"splash"] as Array[StringName],
			"skill_chance": 0.4, "xp_reward": 55, "gold_reward": 14, "color": Color(0.55, 0.8, 1.0)}),
		EnemyDef.make(&"mud_slime", "Mud Slime", {
			"family": &"slime",
			"max_hp": 220, "stats": {S.HEALTH: 10, S.STRENGTH: 14, S.STAMINA: 15, S.AGILITY: 3},
			"row": FRONT, "skills": [&"smash"] as Array[StringName], "skill_chance": 0.3,
			# Mud doesn't mind water, and it's less bothered by wind.
			"affinities": {Element.Type.WATER: Element.Affinity.NORMAL, Element.Type.WIND: Element.Affinity.NORMAL},
			"xp_reward": 80, "gold_reward": 20, "color": Color(0.5, 0.4, 0.3)}),
		EnemyDef.make(&"big_slime", "Big Slime", {
			"family": &"slime",
			"max_hp": 340, "stats": {S.HEALTH: 10, S.STRENGTH: 12, S.STAMINA: 12, S.AGILITY: 4},
			"row": FRONT, "skills": [&"smash"] as Array[StringName], "skill_chance": 0.3,
			"xp_reward": 180, "gold_reward": 60, "color": Color(0.35, 0.75, 0.85),
			"is_boss": true, "is_miniboss": true, "loot_rolls": 1}),
		EnemyDef.make(&"mire_slime", "Mire Slime", {
			"family": &"slime",
			"max_hp": 540, "stats": {S.HEALTH: 12, S.STRENGTH: 17, S.STAMINA: 15, S.INTELLIGENCE: 12, S.AGILITY: 6},
			"row": FRONT, "skills": [&"smash", &"splash"] as Array[StringName], "skill_chance": 0.4,
			"xp_reward": 300, "gold_reward": 90, "color": Color(0.3, 0.45, 0.35),
			"is_boss": true, "is_miniboss": true, "loot_rolls": 1}),
		EnemyDef.make(&"king_slime", "King Slime", {
			"family": &"slime",
			"max_hp": 1150, "stats": {S.HEALTH: 18, S.STRENGTH: 21, S.STAMINA: 18, S.INTELLIGENCE: 14, S.AGILITY: 5, S.LUCK: 10},
			"row": FRONT, "skills": [&"smash", &"splash"] as Array[StringName], "skill_chance": 0.45,
			"xp_reward": 700, "gold_reward": 300, "color": Color(0.3, 0.55, 1.0), "is_boss": true,
			"lore": "(Placeholder) Every slime on these floors drains toward it eventually.",
			"drops": [{"item": &"goddess_tear", "chance": 1.0, "count": 1}, {"item": &"scouting_lens", "chance": 0.35, "count": 1}],
			"loot_rolls": 2, "loot_luck_bonus": 10, "min_loot_rarity": 1, "unique_chance": 0.08}),

		# --- Guild fighters (guards that hunt you, territory champions) ---
		EnemyDef.make(&"guild_guard", "Guild Guard", {
			"family": &"human",
			"max_hp": 170, "stats": {S.HEALTH: 9, S.STRENGTH: 15, S.STAMINA: 12, S.AGILITY: 10, S.LUCK: 6},
			"row": FRONT, "skills": [&"power_strike"] as Array[StringName], "skill_chance": 0.3,
			"xp_reward": 70, "gold_reward": 18, "color": Color(0.6, 0.6, 0.7)}),
		EnemyDef.make(&"guild_archer", "Guild Archer", {
			"family": &"human",
			"max_hp": 120, "stats": {S.STRENGTH: 10, S.STAMINA: 8, S.AGILITY: 15, S.LUCK: 8},
			"row": BACK, "basic_attack": &"attack_ranged", "xp_reward": 60, "gold_reward": 16,
			"color": Color(0.55, 0.6, 0.55)}),
		EnemyDef.make(&"guild_mage", "Guild Mage", {
			"family": &"human",
			"max_hp": 110, "stats": {S.INTELLIGENCE: 16, S.STAMINA: 7, S.AGILITY: 10},
			"row": BACK, "basic_attack": &"attack_magic", "skills": [&"firebolt", &"frost_bolt"] as Array[StringName],
			"skill_chance": 0.45, "xp_reward": 65, "gold_reward": 18, "color": Color(0.5, 0.5, 0.75)}),
		# Champions defend a guild's territory. You can flee from them.
		EnemyDef.make(&"guild_champion", "Guild Champion", {
			"family": &"human",
			"max_hp": 900, "stats": {S.HEALTH: 16, S.STRENGTH: 22, S.STAMINA: 18, S.AGILITY: 12, S.LUCK: 10},
			"row": FRONT, "skills": [&"smash", &"war_cry", &"power_strike"] as Array[StringName], "skill_chance": 0.45,
			"xp_reward": 500, "gold_reward": 200, "color": Color(0.85, 0.85, 0.95),
			"lore": "(Placeholder) Every guild's best fighter, sworn to hold its floors.",
			"loot_rolls": 1, "min_loot_rarity": 1}),

		# --- Stage bosses (floor 10, 20, ...) ---
		# Better loot: 2 rolls, +10 Luck, at least Uncommon, 8% Unique chance, Goddess Tear.
		EnemyDef.make(&"goblin_king", "Goblin King", {
			"family": &"goblin",
			"max_hp": 1100, "stats": {S.HEALTH: 18, S.STRENGTH: 22, S.STAMINA: 18, S.AGILITY: 10, S.LUCK: 10},
			"row": FRONT, "skills": [&"smash", &"war_cry"] as Array[StringName], "skill_chance": 0.45,
			"xp_reward": 700, "gold_reward": 300, "color": Color(0.85, 0.75, 0.2), "is_boss": true,
			"lore": "He crowned himself the day the Hobgoblin knelt.",
			"drops": [{"item": &"goddess_tear", "chance": 1.0, "count": 1}, {"item": &"scouting_lens", "chance": 0.35, "count": 1}],
			"loot_rolls": 2, "loot_luck_bonus": 10, "min_loot_rarity": 1, "unique_chance": 0.08}),
		EnemyDef.make(&"orc_warlord", "Orc Warlord", {
			"family": &"orc",
			"max_hp": 1600, "stats": {S.HEALTH: 22, S.STRENGTH: 27, S.STAMINA: 22, S.AGILITY: 9, S.LUCK: 10},
			"row": FRONT, "skills": [&"smash", &"war_cry"] as Array[StringName], "skill_chance": 0.5,
			"xp_reward": 1100, "gold_reward": 450, "color": Color(0.7, 0.15, 0.1), "is_boss": true,
			"lore": "The Warchief and the Blood Shaman both answer to him.",
			"drops": [{"item": &"goddess_tear", "chance": 1.0, "count": 1}, {"item": &"scouting_lens", "chance": 0.35, "count": 1}],
			"loot_rolls": 2, "loot_luck_bonus": 10, "min_loot_rarity": 1, "unique_chance": 0.08}),

		# --- Roaming bosses: lore bosses that broke loose from their floors ---
		# Best loot in the game: 2 rolls, +20 Luck, at least Rare, 15% Unique chance.
		EnemyDef.make(&"labyrinth_minotaur", "Labyrinth Minotaur", {
			"family": &"beast",
			"max_hp": 1300, "stats": {S.HEALTH: 20, S.STRENGTH: 26, S.STAMINA: 20, S.AGILITY: 9, S.LUCK: 8},
			"row": FRONT, "skills": [&"smash", &"war_cry"] as Array[StringName], "skill_chance": 0.5,
			"xp_reward": 1000, "gold_reward": 400, "color": Color(0.55, 0.25, 0.2), "is_roaming": true,
			"lore": "Broke its chains on floor 30 and has been wandering downward ever since.",
			"drops": [{"item": &"goddess_tear", "chance": 0.5, "count": 1}],
			"loot_rolls": 2, "loot_luck_bonus": 20, "min_loot_rarity": 2, "unique_chance": 0.15}),
		EnemyDef.make(&"lantern_wraith", "Lantern Wraith", {
			"family": &"wraith",
			"max_hp": 1000, "stats": {S.HEALTH: 14, S.INTELLIGENCE: 22, S.STAMINA: 14, S.AGILITY: 18, S.LUCK: 12},
			"row": BACK, "basic_attack": &"attack_magic", "skills": [&"firebolt", &"ward"] as Array[StringName],
			"skill_chance": 0.5, "xp_reward": 900, "gold_reward": 380, "color": Color(0.9, 0.85, 0.5), "is_roaming": true,
			"lore": "Its lantern went out on floor 25. It has been looking for a new flame on the floors below.",
			"drops": [{"item": &"goddess_tear", "chance": 0.5, "count": 1}],
			"loot_rolls": 2, "loot_luck_bonus": 20, "min_loot_rarity": 2, "unique_chance": 0.15}),
		EnemyDef.make(&"ashen_wyrmling", "Ashen Wyrmling", {
			"family": &"wyrm",
			"max_hp": 1200, "stats": {S.HEALTH: 16, S.INTELLIGENCE: 25, S.STAMINA: 16, S.AGILITY: 14, S.LUCK: 10},
			"row": BACK, "basic_attack": &"attack_magic", "skills": [&"ash_breath", &"firebolt"] as Array[StringName],
			"skill_chance": 0.55, "xp_reward": 1200, "gold_reward": 450, "color": Color(0.45, 0.45, 0.5), "is_roaming": true,
			"lore": "Hatched too early on floor 40 and flew down the stairwell looking for its mother.",
			"drops": [{"item": &"goddess_tear", "chance": 0.5, "count": 1}],
			"loot_rolls": 2, "loot_luck_bonus": 20, "min_loot_rarity": 2, "unique_chance": 0.15}),
	]
	var dict := {}
	for e in list:
		dict[e.id] = e
	return dict


## Every enemy definition, sorted by id.
static func all() -> Array[EnemyDef]:
	var ids := _enemies.keys()
	ids.sort()
	var out: Array[EnemyDef] = []
	for id in ids:
		out.append(_enemies[id])
	return out


## Like get_enemy() but quiet: for validating ids read from save files.
static func get_enemy_or_null(id: StringName) -> EnemyDef:
	return _enemies.get(id)


static func get_enemy(id: StringName) -> EnemyDef:
	var e: EnemyDef = _enemies.get(id)
	if e == null:
		push_error("EnemyLibrary: unknown enemy '%s'" % id)
	return e


static func build_group(ids: Array) -> Array[EnemyDef]:
	var out: Array[EnemyDef] = []
	for id in ids:
		out.append(get_enemy(id))
	return out


## Kept for convenience; the real data lives in StageLibrary.
static func is_miniboss_floor(n: int) -> bool:
	return StageLibrary.is_miniboss_floor(n)


static func miniboss_encounter_for_floor(n: int) -> Array[StringName]:
	return StageLibrary.miniboss_for_floor(n)


## Sandbox test fights.
const TEST_BOSS_ENCOUNTER := [&"goblin_king", &"goblin_sorcerer", &"goblin_archer"]
const TEST_MINIBOSS_ENCOUNTER := [&"hobgoblin", &"goblin", &"goblin_archer"]
const TEST_ROAMING_ENCOUNTER := [&"labyrinth_minotaur"]


static func random_test_encounter() -> Array[EnemyDef]:
	return build_group(TEST_ENCOUNTERS.pick_random())
