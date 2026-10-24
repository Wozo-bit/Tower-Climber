class_name SkillLibrary
extends RefCounted
## Every skill in the game, plus which class gets which skills.
## Numbers are first-pass placeholders; tune freely.

const E := SkillDef.Effect
const D := SkillDef.DamageType
const T := SkillDef.Targeting
const EL := Element.Type

static var _skills: Dictionary = _build()

const CLASS_SKILLS := {
	&"tank": [&"shield_bash", &"taunt"],
	&"mage": [&"fireball", &"arc_storm"],
	&"archer": [&"piercing_shot", &"volley"],
	&"rogue": [&"backstab", &"evade"],
	&"support": [&"heal", &"ward"],
	&"ashbound_knight": [&"ember_strike", &"ashen_nova"],
	&"ascendant": [&"judgment", &"sanctuary", &"heavens_fall"],
}

## Default basic attack per class. Classless characters punch things.
const CLASS_BASIC_ATTACK := {
	&"tank": &"attack_melee",
	&"rogue": &"attack_melee",
	&"archer": &"attack_ranged",
	&"mage": &"attack_magic",
	&"support": &"attack_magic",
	&"ashbound_knight": &"attack_melee",
	&"ascendant": &"attack_melee",
}

## Default row per class (the player can change it in battle).
const CLASS_DEFAULT_BACK_ROW := [&"archer", &"mage", &"support"]


static func _build() -> Dictionary:
	var list: Array[SkillDef] = [
		# --- Basic attacks (free) ---
		SkillDef.make(&"attack_melee", "Attack", "A basic melee strike.",
			{"damage_type": D.MELEE}),
		SkillDef.make(&"attack_ranged", "Shoot", "A basic ranged shot. Ignores rows.",
			{"damage_type": D.RANGED}),
		SkillDef.make(&"attack_magic", "Magic Bolt", "A weak bolt of magic. Ignores rows, can't be dodged.",
			{"damage_type": D.MAGIC, "power": 0.8}),

		# --- Tank ---
		SkillDef.make(&"shield_bash", "Shield Bash", "Heavy melee blow.",
			{"elements": [EL.BLUNT] as Array[int], "mp_cost": 5, "damage_type": D.MELEE, "power": 1.4}),
		SkillDef.make(&"taunt", "Taunt", "Enemies focus you for 2 turns.",
			{"mp_cost": 4, "effect": E.STATUS, "targeting": T.SELF, "status_id": &"taunt", "status_turns": 2}),

		# --- Mage ---
		SkillDef.make(&"fireball", "Fireball", "Strong single-target magic.",
			{"elements": [EL.FIRE] as Array[int], "mp_cost": 6, "damage_type": D.MAGIC, "power": 1.6}),
		SkillDef.make(&"arc_storm", "Arc Storm", "Lightning hits every enemy.",
			{"elements": [EL.LIGHTNING] as Array[int], "mp_cost": 10, "damage_type": D.MAGIC, "targeting": T.ENEMY_ALL, "power": 0.75}),

		# --- Archer ---
		SkillDef.make(&"piercing_shot", "Piercing Shot", "Ignores half the target's defense.",
			{"elements": [EL.PIERCE] as Array[int], "mp_cost": 5, "damage_type": D.RANGED, "power": 1.2, "def_pierce": 0.5}),
		SkillDef.make(&"volley", "Volley", "Arrows rain on every enemy.",
			{"elements": [EL.PIERCE] as Array[int], "mp_cost": 8, "damage_type": D.RANGED, "targeting": T.ENEMY_ALL, "power": 0.6}),

		# --- Rogue ---
		SkillDef.make(&"backstab", "Backstab", "Slips past the front line. +25% crit chance.",
			{"elements": [EL.PIERCE] as Array[int], "mp_cost": 6, "damage_type": D.MELEE, "power": 1.3, "ignores_row": true, "bonus_crit": 0.25}),
		SkillDef.make(&"evade", "Evade", "+30% dodge for 2 turns.",
			{"mp_cost": 4, "effect": E.STATUS, "targeting": T.SELF, "status_id": &"evasive", "status_turns": 2}),

		# --- Support ---
		SkillDef.make(&"heal", "Heal", "Restore an ally's HP.",
			{"mp_cost": 6, "effect": E.HEAL, "targeting": T.ALLY_SINGLE, "power": 1.5}),
		SkillDef.make(&"ward", "Ward", "Ally takes 30% less damage for 3 turns.",
			{"mp_cost": 5, "effect": E.STATUS, "targeting": T.ALLY_SINGLE, "status_id": &"ward", "status_turns": 3}),

		# --- Ashbound Knight (secret) ---
		SkillDef.make(&"ember_strike", "Ember Strike", "A burning blade that ignores 30% of defense.",
			{"elements": [EL.FIRE, EL.SLASH] as Array[int], "mp_cost": 6, "damage_type": D.MELEE, "power": 1.5, "def_pierce": 0.3}),
		SkillDef.make(&"ashen_nova", "Ashen Nova", "Cinders burst over every enemy.",
			{"elements": [EL.FIRE] as Array[int], "mp_cost": 12, "damage_type": D.MAGIC, "targeting": T.ENEMY_ALL, "power": 0.85}),

		# --- Ascendant (New Game+ only) ---
		SkillDef.make(&"judgment", "Judgment", "A devastating blow using your stronger of STR or INT. Ignores rows.",
			{"elements": [EL.HOLY] as Array[int], "mp_cost": 10, "damage_type": D.MAGIC, "adaptive": true, "ignores_row": true, "power": 2.2, "bonus_crit": 0.15}),
		SkillDef.make(&"sanctuary", "Sanctuary", "Heals the whole party.",
			{"mp_cost": 14, "effect": E.HEAL, "targeting": T.ALLY_ALL, "power": 1.1}),
		SkillDef.make(&"heavens_fall", "Heaven's Fall", "Strikes every enemy with your stronger of STR or INT.",
			{"elements": [EL.HOLY] as Array[int], "mp_cost": 18, "damage_type": D.MAGIC, "adaptive": true, "ignores_row": true, "targeting": T.ENEMY_ALL, "power": 1.2}),

		# =====================================================
		# Shared skills: anyone can learn these (picks or skill books).
		# Common ones can be chosen with level-up skill picks; every tier
		# can be learned from skill books that monsters drop.
		# =====================================================
		# --- Common ---
		SkillDef.make(&"power_strike", "Power Strike", "A heavier swing.",
			{"mp_cost": 3, "damage_type": D.MELEE, "power": 1.4, "learnable": true, "tier": 0}),
		SkillDef.make(&"first_aid", "First Aid", "Patch up an ally: 15% of their max HP plus a little more.",
			{"mp_cost": 4, "effect": E.HEAL, "targeting": T.ALLY_SINGLE, "power": 0.5, "heal_pct_max_hp": 0.15,
			"learnable": true, "tier": 0}),
		SkillDef.make(&"guard", "Guard", "Step in front of an ally: you take their single-target hits (30% less) until your next turn.",
			{"mp_cost": 2, "effect": E.GUARD, "targeting": T.ALLY_SINGLE, "learnable": true, "tier": 0}),
		SkillDef.make(&"focus", "Focus", "Catch your breath: restore 25% of your max MP.",
			{"mp_cost": 0, "effect": E.RESTORE_MP, "targeting": T.SELF, "power": 0.25, "learnable": true, "tier": 0}),
		SkillDef.make(&"quick_step", "Quick Step", "Much more likely to act first next round.",
			{"mp_cost": 3, "effect": E.STATUS, "targeting": T.SELF, "status_id": &"haste", "status_turns": 2,
			"learnable": true, "tier": 0}),
		# Elemental bolts: cheap single-target magic, one per element, so any
		# character can answer a weakness. Common = available as skill picks.
		SkillDef.make(&"ember", "Ember", "A small burst of flame. [Fire]",
			{"elements": [EL.FIRE] as Array[int], "mp_cost": 3, "damage_type": D.MAGIC, "power": 1.0, "learnable": true, "tier": 0}),
		SkillDef.make(&"frost_bolt", "Frost Bolt", "A shard of ice. [Ice]",
			{"elements": [EL.ICE] as Array[int], "mp_cost": 3, "damage_type": D.MAGIC, "power": 1.0, "learnable": true, "tier": 0}),
		SkillDef.make(&"splash", "Splash", "A lash of water. [Water]",
			{"elements": [EL.WATER] as Array[int], "mp_cost": 3, "damage_type": D.MAGIC, "power": 1.0, "learnable": true, "tier": 0}),
		SkillDef.make(&"spark", "Spark", "A crackle of lightning. [Lightning]",
			{"elements": [EL.LIGHTNING] as Array[int], "mp_cost": 3, "damage_type": D.MAGIC, "power": 1.0, "learnable": true, "tier": 0}),
		SkillDef.make(&"stone_shot", "Stone Shot", "Hurls a chunk of rock. [Earth]",
			{"elements": [EL.EARTH] as Array[int], "mp_cost": 3, "damage_type": D.MAGIC, "power": 1.0, "learnable": true, "tier": 0}),
		SkillDef.make(&"gust", "Gust", "A cutting gust of wind. [Wind]",
			{"elements": [EL.WIND] as Array[int], "mp_cost": 3, "damage_type": D.MAGIC, "power": 1.0, "learnable": true, "tier": 0}),
		SkillDef.make(&"smite", "Smite", "Holy light strikes one enemy. [Holy]",
			{"elements": [EL.HOLY] as Array[int], "mp_cost": 6, "damage_type": D.MAGIC, "power": 1.4, "learnable": true, "tier": 1}),
		SkillDef.make(&"shadow_bolt", "Shadow Bolt", "A bolt of darkness. [Dark]",
			{"elements": [EL.DARK] as Array[int], "mp_cost": 6, "damage_type": D.MAGIC, "power": 1.4, "learnable": true, "tier": 1}),
		# --- Rare ---
		SkillDef.make(&"cleave", "Cleave", "Hits every enemy you can reach in melee.",
			{"elements": [EL.SLASH] as Array[int], "mp_cost": 7, "damage_type": D.MELEE, "targeting": T.ENEMY_ALL, "power": 0.75, "learnable": true, "tier": 1}),
		SkillDef.make(&"mend", "Mend", "Heals the whole party a little.",
			{"mp_cost": 9, "effect": E.HEAL, "targeting": T.ALLY_ALL, "power": 0.5, "heal_pct_max_hp": 0.1,
			"learnable": true, "tier": 1}),
		SkillDef.make(&"rally", "Rally", "The whole party takes 30% less damage for 2 turns.",
			{"mp_cost": 10, "effect": E.STATUS, "targeting": T.ALLY_ALL, "status_id": &"ward", "status_turns": 2,
			"learnable": true, "tier": 1}),
		# --- Epic ---
		SkillDef.make(&"earthshatter", "Earthshatter", "A blow that shakes every enemy, front row or back.",
			{"elements": [EL.EARTH, EL.BLUNT] as Array[int], "mp_cost": 14, "damage_type": D.MELEE, "targeting": T.ENEMY_ALL, "power": 1.0, "ignores_row": true,
			"learnable": true, "tier": 2}),
		SkillDef.make(&"arcane_barrage", "Arcane Barrage", "Magic bolts hit every enemy.",
			{"mp_cost": 14, "damage_type": D.MAGIC, "targeting": T.ENEMY_ALL, "power": 1.0, "learnable": true, "tier": 2}),
		# --- Legendary ---
		SkillDef.make(&"second_wind", "Second Wind", "Recover 50% of your max HP.",
			{"mp_cost": 16, "effect": E.HEAL, "targeting": T.SELF, "power": 0.0, "heal_pct_max_hp": 0.5,
			"learnable": true, "tier": 3}),
		SkillDef.make(&"meteor", "Meteor", "A falling star crushes every enemy.",
			{"elements": [EL.FIRE, EL.EARTH] as Array[int], "mp_cost": 28, "damage_type": D.MAGIC, "targeting": T.ENEMY_ALL, "power": 1.6, "learnable": true, "tier": 3}),
		# --- Unique (boss and roaming-boss books only) ---
		SkillDef.make(&"kings_decree", "King's Decree", "The Goblin King's command: a crushing blow with your stronger of STR or INT.",
			{"elements": [EL.BLUNT] as Array[int], "mp_cost": 20, "damage_type": D.MAGIC, "adaptive": true, "ignores_row": true, "power": 2.6,
			"learnable": true, "tier": 4}),
		SkillDef.make(&"labyrinth_rage", "Labyrinth Rage", "The Minotaur's fury: an enormous blow that reaches any row.",
			{"elements": [EL.BLUNT] as Array[int], "mp_cost": 22, "damage_type": D.MELEE, "ignores_row": true, "power": 3.0, "learnable": true, "tier": 4}),
		SkillDef.make(&"cinder_storm", "Cinder Storm", "The Wyrmling's breath: hits every enemy with your stronger of STR or INT.",
			{"elements": [EL.FIRE] as Array[int], "mp_cost": 26, "damage_type": D.MAGIC, "adaptive": true, "ignores_row": true, "targeting": T.ENEMY_ALL,
			"power": 1.8, "learnable": true, "tier": 4}),
		SkillDef.make(&"warlords_roar", "Warlord's Roar", "The whole party takes 30% less damage for 3 turns and acts sooner.",
			{"mp_cost": 18, "effect": E.STATUS, "targeting": T.ALLY_ALL, "status_id": &"ward", "status_turns": 3,
			"learnable": true, "tier": 4}),

		# --- Enemy-only ---
		# Smash and Firebolt are enemy moves, but their books can drop, so they're learnable too.
		SkillDef.make(&"smash", "Smash", "A crushing overhead blow.",
			{"elements": [EL.BLUNT] as Array[int], "mp_cost": 4, "damage_type": D.MELEE, "power": 1.5, "learnable": true, "tier": 1}),
		SkillDef.make(&"firebolt", "Firebolt", "A spiteful little fireball.",
			{"elements": [EL.FIRE] as Array[int], "mp_cost": 5, "damage_type": D.MAGIC, "power": 1.3, "learnable": true, "tier": 1}),
		SkillDef.make(&"ash_breath", "Ash Breath", "Scorching ash washes over the whole party.",
			{"elements": [EL.FIRE] as Array[int], "mp_cost": 8, "damage_type": D.MAGIC, "targeting": T.ENEMY_ALL, "power": 0.7}),
		SkillDef.make(&"war_cry", "War Cry", "Steel yourself: take 30% less damage for 3 turns.",
			{"mp_cost": 6, "effect": E.STATUS, "targeting": T.SELF, "status_id": &"ward", "status_turns": 3,
			"learnable": true, "tier": 2}),
	]
	var dict := {}
	for s in list:
		dict[s.id] = s
	return dict


## All shared (learnable) skills, optionally only one tier.
static func learnable_skills(tier: int = -1) -> Array[SkillDef]:
	var out: Array[SkillDef] = []
	for s: SkillDef in _skills.values():
		if s.learnable and (tier < 0 or s.tier == tier):
			out.append(s)
	out.sort_custom(func(a, b): return a.tier < b.tier or (a.tier == b.tier and a.display_name < b.display_name))
	return out


## What level-up skill picks can choose from: every Common shared skill.
static func pick_pool() -> Array[SkillDef]:
	return learnable_skills(SkillTier.Tier.COMMON)


static func get_skill_or_null(id: StringName) -> SkillDef:
	return _skills.get(id)


static func get_skill(id: StringName) -> SkillDef:
	var s: SkillDef = _skills.get(id)
	if s == null:
		push_error("SkillLibrary: unknown skill '%s'" % id)
	return s


static func skills_for_class(class_id: StringName) -> Array[SkillDef]:
	var out: Array[SkillDef] = []
	for sid in CLASS_SKILLS.get(class_id, []):
		out.append(get_skill(sid))
	return out


static func basic_attack_for_class(class_id: StringName) -> SkillDef:
	return get_skill(CLASS_BASIC_ATTACK.get(class_id, &"attack_melee"))


static func default_row_for_class(class_id: StringName) -> int:
	return Combatant.Row.BACK if class_id in CLASS_DEFAULT_BACK_ROW else Combatant.Row.FRONT
