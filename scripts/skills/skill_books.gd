class_name SkillBooks
extends RefCounted
## Skill books: monsters drop books for skills that fit them. Using a book (from
## the party menu) teaches that shared skill to one character.
##
## Drop flow per defeated enemy:
##   1. Roll BOOK_DROP_CHANCE for its type (bosses drop books far more often).
##   2. Roll a tier with SkillTier.roll(party Luck) — higher Luck, better odds.
##   3. Pick a book of that tier from the enemy's pool. If it has none of that
##      tier, step DOWN until a tier it does have (so a slime never drops a
##      Unique, but a boss can).

## Chance an enemy drops a book at all.
const BOOK_DROP_CHANCE := {
	"normal": 0.04,
	"miniboss": 0.30,
	"boss": 0.75,
	"roaming": 0.75,
}

## Extra books each enemy can drop on top of the learnable skills it actually
## uses (e.g. an Orc Brute using Smash can drop Smash). Edit freely.
const ENEMY_BOOKS := {
	&"slime": [&"guard", &"focus", &"splash"],
	&"goblin": [&"power_strike", &"quick_step"],
	&"goblin_archer": [&"quick_step", &"focus", &"gust"],
	&"imp_shaman": [&"focus", &"ember", &"shadow_bolt"],
	&"orc_brute": [&"power_strike", &"cleave", &"stone_shot"],
	&"goblin_sorcerer": [&"first_aid", &"mend", &"spark", &"frost_bolt"],
	&"goblin_captain": [&"power_strike", &"cleave", &"rally"],
	&"hobgoblin": [&"cleave", &"rally"],
	&"orc_warchief": [&"earthshatter"],
	&"orc_blood_shaman": [&"mend", &"arcane_barrage"],
	&"bubble_slime": [&"focus", &"splash", &"frost_bolt"],
	&"mud_slime": [&"guard", &"stone_shot"],
	&"big_slime": [&"guard", &"splash", &"mend"],
	&"mire_slime": [&"mend", &"rally", &"stone_shot"],
	&"king_slime": [&"rally", &"mend", &"second_wind", &"meteor"],
	&"goblin_king": [&"rally", &"earthshatter", &"second_wind", &"kings_decree"],
	&"orc_warlord": [&"earthshatter", &"second_wind", &"warlords_roar"],
	&"labyrinth_minotaur": [&"earthshatter", &"second_wind", &"labyrinth_rage"],
	&"lantern_wraith": [&"arcane_barrage", &"meteor", &"smite"],
	&"ashen_wyrmling": [&"arcane_barrage", &"meteor", &"cinder_storm"],
}


static func book_item_id(skill_id: StringName) -> StringName:
	return StringName("book_" + String(skill_id))


static func enemy_kind(def: EnemyDef) -> String:
	if def.is_roaming:
		return "roaming"
	if def.is_miniboss:
		return "miniboss"
	if def.is_boss:
		return "boss"
	return "normal"


static func drop_chance(def: EnemyDef) -> float:
	return BOOK_DROP_CHANCE[enemy_kind(def)]


## Learnable skills this enemy can drop books for.
static func pool_for(def: EnemyDef) -> Array[SkillDef]:
	var out: Array[SkillDef] = []
	var ids: Array = def.skills.duplicate()
	ids.append_array(ENEMY_BOOKS.get(def.id, []))
	for id in ids:
		var s := SkillLibrary.get_skill_or_null(id)
		if s and s.learnable and not out.has(s):
			out.append(s)
	return out


## Returns the skill id of a dropped book, or &"" for no drop.
static func roll_book_drop(def: EnemyDef, luck: int, rng: RandomNumberGenerator) -> StringName:
	var pool := pool_for(def)
	if pool.is_empty() or rng.randf() >= drop_chance(def):
		return &""
	return pick_from_pool(pool, SkillTier.roll(luck, rng), rng)


## Picks a book of `tier` from the pool, stepping down a tier at a time if needed.
static func pick_from_pool(pool: Array[SkillDef], tier: int, rng: RandomNumberGenerator) -> StringName:
	for t in range(tier, -1, -1):
		var options := pool.filter(func(s): return s.tier == t)
		if not options.is_empty():
			return options[rng.randi_range(0, options.size() - 1)].id
	# Pool only has higher tiers than rolled: give the lowest it has.
	var lowest: SkillDef = pool[0]
	for s in pool:
		if s.tier < lowest.tier:
			lowest = s
	return lowest.id
