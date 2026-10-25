class_name EnemyLibrary
extends RefCounted
## Test enemies roughly tuned against a level-10 party. Placeholders.

const S := Stats.Type
const EL := Element.Type
const AF := Element.Affinity
const FRONT := 0   # Combatant.Row.FRONT
const MIDDLE := 1  # Combatant.Row.MIDDLE: skirmishers
const REAR := 2    # Combatant.Row.REAR: archers and other ranged
const BACK := 3    # Combatant.Row.BACK: casters

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
			"row": REAR, "basic_attack": &"attack_ranged", "xp_reward": 55, "gold_reward": 14,
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

		# =====================================================
		# Stage themes added 2026-10-25. All built at the goblins' baseline
		# strength (theme power 1.0): the floor curve sets the difficulty.
		# Bosses have a `patron` (BeingLibrary): they fight with its blessing.
		# =====================================================
		# --- Bandit Fortress (floors 11-20) ---
		EnemyDef.make(&"bandit_cutthroat", "Bandit Cutthroat", {
			"family": &"bandit",
			"max_hp": 140, "stats": {S.HEALTH: 7, S.STRENGTH: 14, S.STAMINA: 8, S.AGILITY: 15, S.LUCK: 10},
			"row": MIDDLE, "skills": [&"power_strike"] as Array[StringName], "skill_chance": 0.3,
			"xp_reward": 60, "gold_reward": 20, "color": Color(0.55, 0.4, 0.3)}),
		EnemyDef.make(&"bandit_brute", "Bandit Brute", {
			"family": &"bandit",
			"max_hp": 190, "stats": {S.HEALTH: 10, S.STRENGTH: 16, S.STAMINA: 12, S.AGILITY: 7},
			"row": FRONT, "skills": [&"smash"] as Array[StringName], "skill_chance": 0.3,
			"xp_reward": 70, "gold_reward": 18, "color": Color(0.45, 0.32, 0.25)}),
		EnemyDef.make(&"bandit_crossbow", "Bandit Crossbow", {
			"family": &"bandit",
			"max_hp": 110, "stats": {S.STRENGTH: 11, S.STAMINA: 7, S.AGILITY: 16, S.LUCK: 9},
			"row": REAR, "basic_attack": &"attack_ranged", "xp_reward": 55, "gold_reward": 18,
			"color": Color(0.6, 0.5, 0.35)}),
		EnemyDef.make(&"bandit_hexer", "Bandit Hexer", {
			"family": &"bandit",
			"max_hp": 105, "stats": {S.INTELLIGENCE: 16, S.STAMINA: 7, S.AGILITY: 11},
			"row": BACK, "basic_attack": &"attack_magic", "skills": [&"shadow_bolt", &"first_aid"] as Array[StringName],
			"skill_chance": 0.45, "xp_reward": 65, "gold_reward": 20, "color": Color(0.4, 0.3, 0.45)}),
		EnemyDef.make(&"bandit_captain", "Bandit Captain", {
			"family": &"bandit",
			"max_hp": 360, "stats": {S.HEALTH: 11, S.STRENGTH: 15, S.STAMINA: 11, S.AGILITY: 14, S.LUCK: 10},
			"row": FRONT, "skills": [&"power_strike", &"war_cry"] as Array[StringName], "skill_chance": 0.4,
			"xp_reward": 200, "gold_reward": 90, "color": Color(0.65, 0.45, 0.3),
			"is_boss": true, "is_miniboss": true, "loot_rolls": 1}),
		EnemyDef.make(&"bandit_quartermaster", "Bandit Quartermaster", {
			"family": &"bandit",
			"max_hp": 480, "stats": {S.HEALTH: 12, S.INTELLIGENCE: 18, S.STAMINA: 12, S.AGILITY: 10, S.LUCK: 12},
			"row": BACK, "basic_attack": &"attack_magic", "skills": [&"shadow_bolt", &"mend", &"ward"] as Array[StringName],
			"skill_chance": 0.5, "xp_reward": 320, "gold_reward": 140, "color": Color(0.5, 0.4, 0.55),
			"is_boss": true, "is_miniboss": true, "loot_rolls": 1}),
		EnemyDef.make(&"bandit_lord", "Bandit Lord", {
			"family": &"bandit", "patron": &"mammon",
			"max_hp": 1150, "stats": {S.HEALTH: 18, S.STRENGTH: 22, S.STAMINA: 17, S.AGILITY: 15, S.LUCK: 14},
			"row": FRONT, "skills": [&"power_strike", &"war_cry", &"highwaymans_ruin"] as Array[StringName], "skill_chance": 0.45,
			"xp_reward": 750, "gold_reward": 400, "color": Color(0.8, 0.6, 0.2), "is_boss": true,
			"lore": "(Placeholder) Everything that goes missing on these floors ends up in his vault. Mammon takes a cut.",
			"drops": [{"item": &"goddess_tear", "chance": 1.0, "count": 1}, {"item": &"scouting_lens", "chance": 0.35, "count": 1}],
			"loot_rolls": 2, "loot_luck_bonus": 10, "min_loot_rarity": 1, "unique_chance": 0.08}),

		# --- Insect Hive (floors 21-30) ---
		EnemyDef.make(&"hive_drone", "Hive Drone", {
			"family": &"insect",
			"max_hp": 100, "stats": {S.STRENGTH: 12, S.STAMINA: 9, S.AGILITY: 16},
			"row": MIDDLE, "xp_reward": 45, "gold_reward": 10, "color": Color(0.75, 0.7, 0.2)}),
		EnemyDef.make(&"hive_soldier", "Hive Soldier", {
			"family": &"insect",
			"max_hp": 170, "stats": {S.HEALTH: 9, S.STRENGTH: 15, S.STAMINA: 14, S.AGILITY: 9},
			"row": FRONT, "skills": [&"power_strike"] as Array[StringName], "skill_chance": 0.3,
			"xp_reward": 65, "gold_reward": 14, "color": Color(0.55, 0.45, 0.15)}),
		EnemyDef.make(&"acid_spitter", "Acid Spitter", {
			"family": &"insect",
			"max_hp": 105, "stats": {S.INTELLIGENCE: 15, S.STAMINA: 8, S.AGILITY: 12},
			"row": BACK, "basic_attack": &"attack_magic", "skills": [&"stone_shot", &"splash"] as Array[StringName],
			"skill_chance": 0.45, "xp_reward": 55, "gold_reward": 12, "color": Color(0.5, 0.75, 0.25)}),
		EnemyDef.make(&"hive_nurse", "Hive Nurse", {
			"family": &"insect",
			"max_hp": 120, "stats": {S.INTELLIGENCE: 14, S.STAMINA: 9, S.AGILITY: 10},
			"row": BACK, "basic_attack": &"attack_magic", "skills": [&"heal", &"mend"] as Array[StringName],
			"skill_chance": 0.45, "xp_reward": 55, "gold_reward": 12, "color": Color(0.85, 0.8, 0.55)}),
		EnemyDef.make(&"hive_warden", "Hive Warden", {
			"family": &"insect",
			"max_hp": 380, "stats": {S.HEALTH: 12, S.STRENGTH: 15, S.STAMINA: 15, S.AGILITY: 10},
			"row": FRONT, "skills": [&"smash", &"war_cry"] as Array[StringName], "skill_chance": 0.4,
			"xp_reward": 200, "gold_reward": 70, "color": Color(0.6, 0.5, 0.1),
			"is_boss": true, "is_miniboss": true, "loot_rolls": 1}),
		EnemyDef.make(&"brood_mother", "Brood Mother", {
			"family": &"insect",
			"max_hp": 520, "stats": {S.HEALTH: 12, S.INTELLIGENCE: 18, S.STAMINA: 13, S.AGILITY: 11},
			"row": BACK, "basic_attack": &"attack_magic", "skills": [&"stone_shot", &"mend", &"gust"] as Array[StringName],
			"skill_chance": 0.5, "xp_reward": 320, "gold_reward": 110, "color": Color(0.7, 0.65, 0.35),
			"is_boss": true, "is_miniboss": true, "loot_rolls": 1}),
		EnemyDef.make(&"hive_queen", "Hive Queen", {
			"family": &"insect", "patron": &"apep",
			"max_hp": 1100, "stats": {S.HEALTH: 17, S.INTELLIGENCE: 22, S.STRENGTH: 16, S.STAMINA: 16, S.AGILITY: 13, S.LUCK: 10},
			"row": BACK, "basic_attack": &"attack_magic", "skills": [&"stone_shot", &"mend", &"chitin_storm"] as Array[StringName],
			"skill_chance": 0.5, "xp_reward": 750, "gold_reward": 320, "color": Color(0.9, 0.75, 0.15), "is_boss": true,
			"lore": "(Placeholder) A thousand eggs, a thousand mouths. The Serpent of Chaos loves a hungry thing.",
			"drops": [{"item": &"goddess_tear", "chance": 1.0, "count": 1}, {"item": &"scouting_lens", "chance": 0.35, "count": 1}],
			"loot_rolls": 2, "loot_luck_bonus": 10, "min_loot_rarity": 1, "unique_chance": 0.08}),

		# --- Beast Den (floors 21-30) ---
		EnemyDef.make(&"dire_wolf", "Dire Wolf", {
			"family": &"beast",
			"max_hp": 140, "stats": {S.HEALTH: 7, S.STRENGTH: 14, S.STAMINA: 9, S.AGILITY: 16},
			"row": MIDDLE, "xp_reward": 60, "gold_reward": 10, "color": Color(0.55, 0.55, 0.6)}),
		EnemyDef.make(&"cave_bear", "Cave Bear", {
			"family": &"beast",
			"max_hp": 220, "stats": {S.HEALTH: 12, S.STRENGTH: 17, S.STAMINA: 13, S.AGILITY: 6},
			"row": FRONT, "skills": [&"smash"] as Array[StringName], "skill_chance": 0.35,
			"xp_reward": 75, "gold_reward": 12, "color": Color(0.45, 0.3, 0.2)}),
		EnemyDef.make(&"razor_hawk", "Razor Hawk", {
			"family": &"beast",
			"max_hp": 95, "stats": {S.STRENGTH: 12, S.STAMINA: 6, S.AGILITY: 19, S.LUCK: 10},
			"row": REAR, "basic_attack": &"attack_ranged", "skills": [&"gust"] as Array[StringName], "skill_chance": 0.3,
			"xp_reward": 55, "gold_reward": 10, "color": Color(0.7, 0.6, 0.45)}),
		EnemyDef.make(&"boar", "Tusked Boar", {
			"family": &"beast",
			"max_hp": 170, "stats": {S.HEALTH: 9, S.STRENGTH: 15, S.STAMINA: 12, S.AGILITY: 10},
			"row": FRONT, "skills": [&"power_strike"] as Array[StringName], "skill_chance": 0.3,
			"xp_reward": 65, "gold_reward": 10, "color": Color(0.5, 0.35, 0.3)}),
		EnemyDef.make(&"pack_leader", "Pack Leader", {
			"family": &"beast",
			"max_hp": 360, "stats": {S.HEALTH: 11, S.STRENGTH: 16, S.STAMINA: 11, S.AGILITY: 16},
			"row": FRONT, "skills": [&"power_strike", &"war_cry"] as Array[StringName], "skill_chance": 0.4,
			"xp_reward": 200, "gold_reward": 60, "color": Color(0.65, 0.65, 0.7),
			"is_boss": true, "is_miniboss": true, "loot_rolls": 1}),
		EnemyDef.make(&"elder_bear", "Elder Bear", {
			"family": &"beast",
			"max_hp": 560, "stats": {S.HEALTH: 14, S.STRENGTH: 19, S.STAMINA: 16, S.AGILITY: 7},
			"row": FRONT, "skills": [&"smash", &"war_cry"] as Array[StringName], "skill_chance": 0.45,
			"xp_reward": 320, "gold_reward": 90, "color": Color(0.35, 0.22, 0.15),
			"is_boss": true, "is_miniboss": true, "loot_rolls": 1}),
		EnemyDef.make(&"moonfang", "Moonfang, the Great Wolf", {
			"family": &"beast", "patron": &"loki",
			"max_hp": 1150, "stats": {S.HEALTH: 17, S.STRENGTH: 23, S.STAMINA: 16, S.AGILITY: 18, S.LUCK: 12},
			"row": FRONT, "skills": [&"power_strike", &"war_cry", &"moonfang_bite"] as Array[StringName], "skill_chance": 0.45,
			"xp_reward": 750, "gold_reward": 300, "color": Color(0.8, 0.82, 0.9), "is_boss": true,
			"lore": "(Placeholder) The trickster raised it on stolen moonlight. It has never once been full.",
			"drops": [{"item": &"goddess_tear", "chance": 1.0, "count": 1}, {"item": &"scouting_lens", "chance": 0.35, "count": 1}],
			"loot_rolls": 2, "loot_luck_bonus": 10, "min_loot_rarity": 1, "unique_chance": 0.08}),

		# --- Elemental Rift (floors 31-40) ---
		EnemyDef.make(&"ember_sprite", "Ember Sprite", {
			"family": &"elemental", "affinities": {EL.FIRE: AF.ABSORB, EL.WATER: AF.WEAK, EL.ICE: AF.WEAK},
			"max_hp": 110, "stats": {S.INTELLIGENCE: 16, S.STAMINA: 8, S.AGILITY: 13},
			"row": BACK, "basic_attack": &"attack_magic", "skills": [&"firebolt"] as Array[StringName], "skill_chance": 0.45,
			"xp_reward": 60, "gold_reward": 12, "color": Color(1.0, 0.45, 0.15)}),
		EnemyDef.make(&"frost_wisp", "Frost Wisp", {
			"family": &"elemental", "affinities": {EL.ICE: AF.ABSORB, EL.FIRE: AF.WEAK},
			"max_hp": 110, "stats": {S.INTELLIGENCE: 16, S.STAMINA: 8, S.AGILITY: 13},
			"row": BACK, "basic_attack": &"attack_magic", "skills": [&"frost_bolt"] as Array[StringName], "skill_chance": 0.45,
			"xp_reward": 60, "gold_reward": 12, "color": Color(0.6, 0.85, 1.0)}),
		EnemyDef.make(&"storm_spirit", "Storm Spirit", {
			"family": &"elemental", "affinities": {EL.LIGHTNING: AF.ABSORB, EL.EARTH: AF.WEAK},
			"max_hp": 120, "stats": {S.INTELLIGENCE: 17, S.STAMINA: 8, S.AGILITY: 16},
			"row": BACK, "basic_attack": &"attack_magic", "skills": [&"spark", &"gust"] as Array[StringName], "skill_chance": 0.45,
			"xp_reward": 65, "gold_reward": 12, "color": Color(0.75, 0.75, 1.0)}),
		EnemyDef.make(&"stone_golem", "Stone Golem", {
			"family": &"elemental", "affinities": {EL.EARTH: AF.ABSORB, EL.WIND: AF.WEAK, EL.WATER: AF.WEAK},
			"max_hp": 230, "stats": {S.HEALTH: 12, S.STRENGTH: 16, S.STAMINA: 16, S.AGILITY: 4},
			"row": FRONT, "skills": [&"smash"] as Array[StringName], "skill_chance": 0.35,
			"xp_reward": 75, "gold_reward": 12, "color": Color(0.55, 0.5, 0.45)}),
		EnemyDef.make(&"magma_colossus", "Magma Colossus", {
			"family": &"elemental", "affinities": {EL.FIRE: AF.ABSORB, EL.EARTH: AF.RESIST, EL.WATER: AF.WEAK, EL.ICE: AF.WEAK},
			"max_hp": 420, "stats": {S.HEALTH: 13, S.STRENGTH: 17, S.INTELLIGENCE: 14, S.STAMINA: 15, S.AGILITY: 6},
			"row": FRONT, "skills": [&"smash", &"ash_breath"] as Array[StringName], "skill_chance": 0.45,
			"xp_reward": 220, "gold_reward": 70, "color": Color(0.85, 0.3, 0.1),
			"is_boss": true, "is_miniboss": true, "loot_rolls": 1}),
		EnemyDef.make(&"tempest_lord", "Tempest Lord", {
			"family": &"elemental", "affinities": {EL.LIGHTNING: AF.ABSORB, EL.WIND: AF.RESIST, EL.EARTH: AF.WEAK},
			"max_hp": 500, "stats": {S.HEALTH: 12, S.INTELLIGENCE: 20, S.STAMINA: 12, S.AGILITY: 16},
			"row": BACK, "basic_attack": &"attack_magic", "skills": [&"spark", &"gust", &"ward"] as Array[StringName],
			"skill_chance": 0.5, "xp_reward": 330, "gold_reward": 100, "color": Color(0.55, 0.6, 1.0),
			"is_boss": true, "is_miniboss": true, "loot_rolls": 1}),
		EnemyDef.make(&"rift_sovereign", "Rift Sovereign", {
			"family": &"elemental", "patron": &"typhon",
			"affinities": {EL.FIRE: AF.RESIST, EL.ICE: AF.RESIST, EL.LIGHTNING: AF.RESIST, EL.HOLY: AF.WEAK, EL.DARK: AF.WEAK},
			"max_hp": 1100, "stats": {S.HEALTH: 17, S.INTELLIGENCE: 24, S.STAMINA: 16, S.AGILITY: 12, S.LUCK: 10},
			"row": BACK, "basic_attack": &"attack_magic", "skills": [&"firebolt", &"frost_bolt", &"spark", &"cataclysm"] as Array[StringName],
			"skill_chance": 0.55, "xp_reward": 800, "gold_reward": 320, "color": Color(0.8, 0.5, 1.0), "is_boss": true,
			"lore": "(Placeholder) Fire, frost and storm, bound into one will by the Father of Monsters.",
			"drops": [{"item": &"goddess_tear", "chance": 1.0, "count": 1}, {"item": &"scouting_lens", "chance": 0.35, "count": 1}],
			"loot_rolls": 2, "loot_luck_bonus": 10, "min_loot_rarity": 1, "unique_chance": 0.08}),

		# --- Undead Crypt (floors 31-40) ---
		EnemyDef.make(&"skeleton_warrior", "Skeleton Warrior", {
			"family": &"undead", "affinities": {EL.BLUNT: AF.WEAK, EL.PIERCE: AF.RESIST},
			"max_hp": 140, "stats": {S.STRENGTH: 15, S.STAMINA: 11, S.AGILITY: 9},
			"row": FRONT, "skills": [&"power_strike"] as Array[StringName], "skill_chance": 0.3,
			"xp_reward": 60, "gold_reward": 14, "color": Color(0.85, 0.82, 0.72)}),
		EnemyDef.make(&"ghoul", "Ghoul", {
			"family": &"undead",
			"max_hp": 180, "stats": {S.HEALTH: 10, S.STRENGTH: 16, S.STAMINA: 10, S.AGILITY: 11},
			"row": MIDDLE, "xp_reward": 65, "gold_reward": 12, "color": Color(0.45, 0.55, 0.4)}),
		EnemyDef.make(&"skeleton_archer", "Skeleton Archer", {
			"family": &"undead", "affinities": {EL.BLUNT: AF.WEAK, EL.PIERCE: AF.RESIST},
			"max_hp": 100, "stats": {S.STRENGTH: 11, S.STAMINA: 7, S.AGILITY: 16},
			"row": REAR, "basic_attack": &"attack_ranged", "xp_reward": 55, "gold_reward": 14, "color": Color(0.8, 0.78, 0.65)}),
		EnemyDef.make(&"crypt_wraith", "Crypt Wraith", {
			"family": &"undead", "affinities": {EL.SLASH: AF.RESIST, EL.PIERCE: AF.RESIST},
			"max_hp": 110, "stats": {S.INTELLIGENCE: 17, S.STAMINA: 8, S.AGILITY: 14},
			"row": BACK, "basic_attack": &"attack_magic", "skills": [&"shadow_bolt", &"frost_bolt"] as Array[StringName],
			"skill_chance": 0.45, "xp_reward": 65, "gold_reward": 14, "color": Color(0.5, 0.55, 0.75)}),
		EnemyDef.make(&"bone_knight", "Bone Knight", {
			"family": &"undead", "affinities": {EL.BLUNT: AF.WEAK, EL.PIERCE: AF.RESIST},
			"max_hp": 380, "stats": {S.HEALTH: 12, S.STRENGTH: 17, S.STAMINA: 15, S.AGILITY: 9},
			"row": FRONT, "skills": [&"smash", &"war_cry"] as Array[StringName], "skill_chance": 0.4,
			"xp_reward": 220, "gold_reward": 80, "color": Color(0.75, 0.72, 0.6),
			"is_boss": true, "is_miniboss": true, "loot_rolls": 1}),
		EnemyDef.make(&"grave_priest", "Grave Priest", {
			"family": &"undead",
			"max_hp": 480, "stats": {S.HEALTH: 12, S.INTELLIGENCE: 19, S.STAMINA: 12, S.AGILITY: 10},
			"row": BACK, "basic_attack": &"attack_magic", "skills": [&"shadow_bolt", &"mend", &"ward"] as Array[StringName],
			"skill_chance": 0.5, "xp_reward": 330, "gold_reward": 110, "color": Color(0.4, 0.35, 0.5),
			"is_boss": true, "is_miniboss": true, "loot_rolls": 1}),
		EnemyDef.make(&"necromancer", "The Necromancer", {
			"family": &"undead", "patron": &"hades",
			"max_hp": 1050, "stats": {S.HEALTH: 16, S.INTELLIGENCE: 24, S.STAMINA: 15, S.AGILITY: 11, S.LUCK: 10},
			"row": BACK, "basic_attack": &"attack_magic", "skills": [&"shadow_bolt", &"mend", &"grave_tide"] as Array[StringName],
			"skill_chance": 0.55, "xp_reward": 800, "gold_reward": 320, "color": Color(0.35, 0.25, 0.45), "is_boss": true,
			"lore": "(Placeholder) The dead on these floors answer to him, and he answers to the Lord of the Underworld.",
			"drops": [{"item": &"goddess_tear", "chance": 1.0, "count": 1}, {"item": &"scouting_lens", "chance": 0.35, "count": 1}],
			"loot_rolls": 2, "loot_luck_bonus": 10, "min_loot_rarity": 1, "unique_chance": 0.08}),

		# --- Demon Gate (floors 41-60) ---
		EnemyDef.make(&"lesser_fiend", "Lesser Fiend", {
			"family": &"demon",
			"max_hp": 150, "stats": {S.HEALTH: 8, S.STRENGTH: 15, S.STAMINA: 10, S.AGILITY: 12},
			"row": MIDDLE, "skills": [&"power_strike"] as Array[StringName], "skill_chance": 0.3,
			"xp_reward": 60, "gold_reward": 16, "color": Color(0.7, 0.2, 0.2)}),
		EnemyDef.make(&"hellhound", "Hellhound", {
			"family": &"demon", "affinities": {EL.FIRE: AF.ABSORB},
			"max_hp": 140, "stats": {S.STRENGTH: 15, S.INTELLIGENCE: 12, S.STAMINA: 9, S.AGILITY: 16},
			"row": MIDDLE, "skills": [&"ash_breath"] as Array[StringName], "skill_chance": 0.3,
			"xp_reward": 60, "gold_reward": 14, "color": Color(0.5, 0.15, 0.1)}),
		EnemyDef.make(&"succubus", "Temptress", {
			"family": &"demon",
			"max_hp": 115, "stats": {S.INTELLIGENCE: 17, S.STAMINA: 8, S.AGILITY: 14, S.LUCK: 12},
			"row": BACK, "basic_attack": &"attack_magic", "skills": [&"shadow_bolt", &"firebolt"] as Array[StringName],
			"skill_chance": 0.45, "xp_reward": 65, "gold_reward": 18, "color": Color(0.75, 0.3, 0.55)}),
		EnemyDef.make(&"imp_swarm", "Imp Swarm", {
			"family": &"demon",
			"max_hp": 120, "stats": {S.INTELLIGENCE: 14, S.STAMINA: 8, S.AGILITY: 15},
			"row": BACK, "basic_attack": &"attack_magic", "skills": [&"firebolt"] as Array[StringName], "skill_chance": 0.4,
			"xp_reward": 55, "gold_reward": 14, "color": Color(0.8, 0.35, 0.3)}),
		EnemyDef.make(&"pit_fiend", "Pit Fiend", {
			"family": &"demon",
			"max_hp": 400, "stats": {S.HEALTH: 13, S.STRENGTH: 18, S.STAMINA: 14, S.AGILITY: 10},
			"row": FRONT, "skills": [&"smash", &"war_cry"] as Array[StringName], "skill_chance": 0.45,
			"xp_reward": 230, "gold_reward": 90, "color": Color(0.55, 0.1, 0.1),
			"is_boss": true, "is_miniboss": true, "loot_rolls": 1}),
		EnemyDef.make(&"hell_warlock", "Hell Warlock", {
			"family": &"demon",
			"max_hp": 500, "stats": {S.HEALTH: 12, S.INTELLIGENCE: 20, S.STAMINA: 12, S.AGILITY: 12},
			"row": BACK, "basic_attack": &"attack_magic", "skills": [&"shadow_bolt", &"ash_breath", &"ward"] as Array[StringName],
			"skill_chance": 0.5, "xp_reward": 340, "gold_reward": 120, "color": Color(0.45, 0.15, 0.35),
			"is_boss": true, "is_miniboss": true, "loot_rolls": 1}),
		EnemyDef.make(&"archfiend", "The Archfiend", {
			"family": &"demon", "patron": &"mephistopheles",
			"max_hp": 1200, "stats": {S.HEALTH: 18, S.STRENGTH: 23, S.INTELLIGENCE: 20, S.STAMINA: 17, S.AGILITY: 13, S.LUCK: 12},
			"row": FRONT, "skills": [&"smash", &"ash_breath", &"abyssal_brand"] as Array[StringName], "skill_chance": 0.5,
			"xp_reward": 850, "gold_reward": 350, "color": Color(0.6, 0.05, 0.1), "is_boss": true,
			"lore": "(Placeholder) It signed its soul away a thousand years ago and has been collecting interest ever since.",
			"drops": [{"item": &"goddess_tear", "chance": 1.0, "count": 1}, {"item": &"scouting_lens", "chance": 0.35, "count": 1}],
			"loot_rolls": 2, "loot_luck_bonus": 10, "min_loot_rarity": 1, "unique_chance": 0.08}),

		# --- Celestial Spire: angels (floors 41-60) ---
		EnemyDef.make(&"winged_sentinel", "Winged Sentinel", {
			"family": &"celestial",
			"max_hp": 160, "stats": {S.HEALTH: 9, S.STRENGTH: 15, S.STAMINA: 12, S.AGILITY: 11},
			"row": MIDDLE, "skills": [&"power_strike"] as Array[StringName], "skill_chance": 0.3,
			"xp_reward": 65, "gold_reward": 14, "color": Color(0.95, 0.92, 0.75)}),
		EnemyDef.make(&"choir_acolyte", "Choir Acolyte", {
			"family": &"celestial",
			"max_hp": 115, "stats": {S.INTELLIGENCE: 15, S.STAMINA: 9, S.AGILITY: 11},
			"row": BACK, "basic_attack": &"attack_magic", "skills": [&"smite", &"heal"] as Array[StringName],
			"skill_chance": 0.45, "xp_reward": 60, "gold_reward": 14, "color": Color(1.0, 0.95, 0.85)}),
		EnemyDef.make(&"radiant_archer", "Radiant Archer", {
			"family": &"celestial",
			"max_hp": 105, "stats": {S.STRENGTH: 12, S.STAMINA: 7, S.AGILITY: 17, S.LUCK: 9},
			"row": REAR, "basic_attack": &"attack_ranged", "skills": [&"smite"] as Array[StringName], "skill_chance": 0.25,
			"xp_reward": 60, "gold_reward": 14, "color": Color(1.0, 0.9, 0.6)}),
		EnemyDef.make(&"virtue", "Virtue", {
			"family": &"celestial",
			"max_hp": 150, "stats": {S.HEALTH: 9, S.INTELLIGENCE: 14, S.STRENGTH: 13, S.STAMINA: 12, S.AGILITY: 10},
			"row": FRONT, "skills": [&"ward", &"smite"] as Array[StringName], "skill_chance": 0.35,
			"xp_reward": 65, "gold_reward": 14, "color": Color(0.85, 0.85, 1.0)}),
		EnemyDef.make(&"throne_guardian", "Throne Guardian", {
			"family": &"celestial",
			"max_hp": 420, "stats": {S.HEALTH: 13, S.STRENGTH: 17, S.STAMINA: 16, S.AGILITY: 9},
			"row": FRONT, "skills": [&"smash", &"war_cry"] as Array[StringName], "skill_chance": 0.4,
			"xp_reward": 230, "gold_reward": 80, "color": Color(0.9, 0.85, 0.5),
			"is_boss": true, "is_miniboss": true, "loot_rolls": 1}),
		EnemyDef.make(&"choir_master", "Choir Master", {
			"family": &"celestial",
			"max_hp": 480, "stats": {S.HEALTH: 12, S.INTELLIGENCE: 20, S.STAMINA: 12, S.AGILITY: 11},
			"row": BACK, "basic_attack": &"attack_magic", "skills": [&"smite", &"mend", &"ward"] as Array[StringName],
			"skill_chance": 0.5, "xp_reward": 340, "gold_reward": 110, "color": Color(1.0, 1.0, 0.9),
			"is_boss": true, "is_miniboss": true, "loot_rolls": 1}),
		EnemyDef.make(&"seraph_judicator", "Seraph Judicator", {
			"family": &"celestial", "patron": &"zeus",
			"max_hp": 1150, "stats": {S.HEALTH: 17, S.INTELLIGENCE: 23, S.STRENGTH: 20, S.STAMINA: 17, S.AGILITY: 14, S.LUCK: 12},
			"row": FRONT, "skills": [&"smite", &"mend", &"judgment_ray"] as Array[StringName], "skill_chance": 0.5,
			"xp_reward": 850, "gold_reward": 350, "color": Color(1.0, 0.95, 0.55), "is_boss": true,
			"lore": "(Placeholder) It decides who is worthy of climbing higher. The King of the Gods signed its warrant.",
			"drops": [{"item": &"goddess_tear", "chance": 1.0, "count": 1}, {"item": &"scouting_lens", "chance": 0.35, "count": 1}],
			"loot_rolls": 2, "loot_luck_bonus": 10, "min_loot_rarity": 1, "unique_chance": 0.08}),

		# --- Dragon Roost (floors 41-60) ---
		EnemyDef.make(&"drakeling", "Drakeling", {
			"family": &"dragon",
			"max_hp": 150, "stats": {S.HEALTH: 8, S.STRENGTH: 15, S.STAMINA: 11, S.AGILITY: 12},
			"row": MIDDLE, "xp_reward": 65, "gold_reward": 18, "color": Color(0.6, 0.3, 0.2)}),
		EnemyDef.make(&"fire_drake", "Fire Drake", {
			"family": &"dragon", "affinities": {EL.FIRE: AF.ABSORB},
			"max_hp": 170, "stats": {S.HEALTH: 9, S.STRENGTH: 13, S.INTELLIGENCE: 14, S.STAMINA: 12, S.AGILITY: 10},
			"row": FRONT, "skills": [&"ash_breath"] as Array[StringName], "skill_chance": 0.35,
			"xp_reward": 70, "gold_reward": 20, "color": Color(0.85, 0.3, 0.15)}),
		EnemyDef.make(&"wyvern", "Wyvern", {
			"family": &"dragon", "affinities": {EL.WIND: AF.RESIST, EL.LIGHTNING: AF.WEAK},
			"max_hp": 130, "stats": {S.STRENGTH: 14, S.STAMINA: 9, S.AGILITY: 17},
			"row": REAR, "basic_attack": &"attack_ranged", "skills": [&"gust"] as Array[StringName], "skill_chance": 0.3,
			"xp_reward": 65, "gold_reward": 18, "color": Color(0.4, 0.55, 0.35)}),
		EnemyDef.make(&"dragon_cultist", "Dragon Cultist", {
			"family": &"human",
			"max_hp": 110, "stats": {S.INTELLIGENCE: 16, S.STAMINA: 8, S.AGILITY: 11},
			"row": BACK, "basic_attack": &"attack_magic", "skills": [&"firebolt", &"heal"] as Array[StringName],
			"skill_chance": 0.45, "xp_reward": 55, "gold_reward": 20, "color": Color(0.6, 0.25, 0.3)}),
		EnemyDef.make(&"drake_rider", "Drake Rider", {
			"family": &"dragon",
			"max_hp": 420, "stats": {S.HEALTH: 13, S.STRENGTH: 18, S.STAMINA: 15, S.AGILITY: 13},
			"row": FRONT, "skills": [&"power_strike", &"war_cry"] as Array[StringName], "skill_chance": 0.4,
			"xp_reward": 240, "gold_reward": 90, "color": Color(0.7, 0.35, 0.25),
			"is_boss": true, "is_miniboss": true, "loot_rolls": 1}),
		EnemyDef.make(&"elder_wyvern", "Elder Wyvern", {
			"family": &"dragon", "affinities": {EL.WIND: AF.RESIST, EL.LIGHTNING: AF.WEAK},
			"max_hp": 520, "stats": {S.HEALTH: 13, S.STRENGTH: 17, S.INTELLIGENCE: 16, S.STAMINA: 14, S.AGILITY: 15},
			"row": REAR, "basic_attack": &"attack_ranged", "skills": [&"gust", &"ash_breath"] as Array[StringName],
			"skill_chance": 0.5, "xp_reward": 350, "gold_reward": 120, "color": Color(0.35, 0.5, 0.3),
			"is_boss": true, "is_miniboss": true, "loot_rolls": 1}),
		EnemyDef.make(&"dragon_sovereign", "Dragon Sovereign", {
			"family": &"dragon", "patron": &"tiamat",
			"max_hp": 1250, "stats": {S.HEALTH: 19, S.STRENGTH: 24, S.INTELLIGENCE: 22, S.STAMINA: 18, S.AGILITY: 12, S.LUCK: 12},
			"row": FRONT, "skills": [&"smash", &"ash_breath", &"dragonfire"] as Array[StringName], "skill_chance": 0.5,
			"xp_reward": 900, "gold_reward": 400, "color": Color(0.75, 0.1, 0.1), "is_boss": true,
			"lore": "(Placeholder) The eldest child of the Mother of Chaos. Its hoard is the tower's crown.",
			"drops": [{"item": &"goddess_tear", "chance": 1.0, "count": 1}, {"item": &"scouting_lens", "chance": 0.35, "count": 1}],
			"loot_rolls": 2, "loot_luck_bonus": 10, "min_loot_rarity": 1, "unique_chance": 0.08}),

		# --- Summons (called by the Summoner line; scaled by the caster's INT) ---
		EnemyDef.make(&"wisp", "Wisp", {
			"family": &"spirit", "max_hp": 70, "stats": {S.INTELLIGENCE: 14, S.STAMINA: 6, S.AGILITY: 14},
			"row": BACK, "basic_attack": &"attack_magic", "xp_reward": 0, "gold_reward": 0, "color": Color(0.7, 1.0, 0.95)}),
		EnemyDef.make(&"spirit_wolf", "Spirit Wolf", {
			"family": &"spirit", "max_hp": 110, "stats": {S.STRENGTH: 15, S.STAMINA: 8, S.AGILITY: 16},
			"row": MIDDLE, "xp_reward": 0, "gold_reward": 0, "color": Color(0.7, 0.8, 1.0)}),
		EnemyDef.make(&"guardian_spirit", "Guardian Spirit", {
			"family": &"spirit", "max_hp": 180, "stats": {S.STRENGTH: 10, S.STAMINA: 16, S.AGILITY: 8},
			"row": FRONT, "skills": [&"taunt"] as Array[StringName], "skill_chance": 0.4,
			"xp_reward": 0, "gold_reward": 0, "color": Color(0.85, 0.9, 1.0)}),
		EnemyDef.make(&"skeleton_thrall", "Skeleton Thrall", {
			"family": &"spirit", "max_hp": 120, "stats": {S.STRENGTH: 14, S.STAMINA: 10, S.AGILITY: 10},
			"row": FRONT, "xp_reward": 0, "gold_reward": 0, "color": Color(0.8, 0.78, 0.7)}),
		EnemyDef.make(&"great_beast", "Great Spirit Beast", {
			"family": &"spirit", "max_hp": 260, "stats": {S.STRENGTH: 20, S.STAMINA: 14, S.AGILITY: 14},
			"row": FRONT, "skills": [&"smash"] as Array[StringName], "skill_chance": 0.4,
			"xp_reward": 0, "gold_reward": 0, "color": Color(0.6, 0.75, 1.0)}),
		EnemyDef.make(&"bone_colossus", "Bone Colossus", {
			"family": &"spirit", "max_hp": 320, "stats": {S.STRENGTH: 21, S.STAMINA: 16, S.AGILITY: 6},
			"row": FRONT, "skills": [&"smash"] as Array[StringName], "skill_chance": 0.45,
			"xp_reward": 0, "gold_reward": 0, "color": Color(0.85, 0.8, 0.7)}),

		# --- Guild fighters (guards that hunt you, territory champions) ---
		EnemyDef.make(&"guild_guard", "Guild Guard", {
			"family": &"human",
			"max_hp": 170, "stats": {S.HEALTH: 9, S.STRENGTH: 15, S.STAMINA: 12, S.AGILITY: 10, S.LUCK: 6},
			"row": FRONT, "skills": [&"power_strike"] as Array[StringName], "skill_chance": 0.3,
			"xp_reward": 70, "gold_reward": 18, "color": Color(0.6, 0.6, 0.7)}),
		EnemyDef.make(&"guild_archer", "Guild Archer", {
			"family": &"human",
			"max_hp": 120, "stats": {S.STRENGTH: 10, S.STAMINA: 8, S.AGILITY: 15, S.LUCK: 8},
			"row": REAR, "basic_attack": &"attack_ranged", "xp_reward": 60, "gold_reward": 16,
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
