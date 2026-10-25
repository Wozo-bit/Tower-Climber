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
	# Tier 2: these come ON TOP of the class they advanced from (lineage).
	&"bastion": [&"bulwark", &"iron_will"],
	&"juggernaut": [&"crushing_blow", &"rampage"],
	&"paladin": [&"holy_strike", &"lay_on_hands"],
	&"pyromancer": [&"magma_burst", &"inferno"],
	&"stormcaller": [&"chain_lightning", &"tempest"],
	&"warlock": [&"hex_bolt", &"doom_wave"],
	&"sharpshooter": [&"deadeye", &"armor_breaker"],
	&"ranger": [&"gale_arrows", &"wind_step"],
	&"assassin": [&"shadow_strike", &"vanish"],
	&"trickster": [&"lucky_strike", &"smoke_screen"],
	&"executioner": [&"execute", &"grim_resolve"],
	&"cleric": [&"holy_light", &"divine_lance"],
	&"oracle": [&"foresight", &"starfall"],
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

		# =====================================================
		# Tier 2 class skills (placeholder numbers)
		# =====================================================
		SkillDef.make(&"bulwark", "Bulwark", "The whole party takes 30% less damage for 2 turns.",
			{"mp_cost": 12, "effect": E.STATUS, "targeting": T.ALLY_ALL, "status_id": &"ward", "status_turns": 2}),
		SkillDef.make(&"iron_will", "Iron Will", "Recover 30% of your max HP.",
			{"mp_cost": 10, "effect": E.HEAL, "targeting": T.SELF, "power": 0.0, "heal_pct_max_hp": 0.3}),
		SkillDef.make(&"crushing_blow", "Crushing Blow", "A huge blow that ignores 30% of defense.",
			{"elements": [EL.BLUNT] as Array[int], "mp_cost": 9, "damage_type": D.MELEE, "power": 2.0, "def_pierce": 0.3}),
		SkillDef.make(&"rampage", "Rampage", "Smashes every enemy you can reach.",
			{"elements": [EL.BLUNT] as Array[int], "mp_cost": 14, "damage_type": D.MELEE, "targeting": T.ENEMY_ALL, "power": 1.0}),
		SkillDef.make(&"holy_strike", "Holy Strike", "A blessed blade.",
			{"elements": [EL.HOLY, EL.SLASH] as Array[int], "mp_cost": 9, "damage_type": D.MELEE, "power": 1.7}),
		SkillDef.make(&"lay_on_hands", "Lay on Hands", "A strong heal on one ally.",
			{"mp_cost": 12, "effect": E.HEAL, "targeting": T.ALLY_SINGLE, "power": 1.5, "heal_pct_max_hp": 0.25}),
		SkillDef.make(&"magma_burst", "Magma Burst", "Molten rock: Fire and Earth at once.",
			{"elements": [EL.FIRE, EL.EARTH] as Array[int], "mp_cost": 14, "damage_type": D.MAGIC, "power": 2.0}),
		SkillDef.make(&"inferno", "Inferno", "Fire engulfs every enemy.",
			{"elements": [EL.FIRE] as Array[int], "mp_cost": 18, "damage_type": D.MAGIC, "targeting": T.ENEMY_ALL, "power": 1.1}),
		SkillDef.make(&"chain_lightning", "Chain Lightning", "Lightning leaps between every enemy.",
			{"elements": [EL.LIGHTNING] as Array[int], "mp_cost": 15, "damage_type": D.MAGIC, "targeting": T.ENEMY_ALL, "power": 0.95}),
		SkillDef.make(&"tempest", "Tempest", "A storm of wind and lightning over every enemy.",
			{"elements": [EL.WIND, EL.LIGHTNING] as Array[int], "mp_cost": 20, "damage_type": D.MAGIC, "targeting": T.ENEMY_ALL, "power": 1.2}),
		SkillDef.make(&"hex_bolt", "Hex Bolt", "A cursed bolt of darkness.",
			{"elements": [EL.DARK] as Array[int], "mp_cost": 10, "damage_type": D.MAGIC, "power": 1.9}),
		SkillDef.make(&"doom_wave", "Doom Wave", "Darkness washes over every enemy.",
			{"elements": [EL.DARK] as Array[int], "mp_cost": 18, "damage_type": D.MAGIC, "targeting": T.ENEMY_ALL, "power": 1.1}),
		SkillDef.make(&"deadeye", "Deadeye", "A perfect shot. +30% crit chance.",
			{"elements": [EL.PIERCE] as Array[int], "mp_cost": 10, "damage_type": D.RANGED, "power": 2.0, "bonus_crit": 0.3}),
		SkillDef.make(&"armor_breaker", "Armor Breaker", "Ignores 80% of the target's defense.",
			{"elements": [EL.PIERCE] as Array[int], "mp_cost": 9, "damage_type": D.RANGED, "power": 1.5, "def_pierce": 0.8}),
		SkillDef.make(&"gale_arrows", "Gale Arrows", "Wind-driven arrows hit every enemy.",
			{"elements": [EL.WIND, EL.PIERCE] as Array[int], "mp_cost": 12, "damage_type": D.RANGED, "targeting": T.ENEMY_ALL, "power": 0.9}),
		SkillDef.make(&"wind_step", "Wind Step", "Much more likely to act first for 2 rounds.",
			{"mp_cost": 5, "effect": E.STATUS, "targeting": T.SELF, "status_id": &"haste", "status_turns": 3}),
		SkillDef.make(&"shadow_strike", "Shadow Strike", "From the dark, past the front line. +20% crit chance.",
			{"elements": [EL.DARK, EL.PIERCE] as Array[int], "mp_cost": 11, "damage_type": D.MELEE, "power": 2.0,
			"ignores_row": true, "bonus_crit": 0.2}),
		SkillDef.make(&"vanish", "Vanish", "+30% dodge for 3 turns.",
			{"mp_cost": 6, "effect": E.STATUS, "targeting": T.SELF, "status_id": &"evasive", "status_turns": 3}),
		SkillDef.make(&"lucky_strike", "Lucky Strike", "Reaches any row. +50% crit chance.",
			{"mp_cost": 7, "damage_type": D.MELEE, "power": 1.4, "ignores_row": true, "bonus_crit": 0.5}),
		SkillDef.make(&"smoke_screen", "Smoke Screen", "The whole party gets +30% dodge for 2 turns.",
			{"mp_cost": 12, "effect": E.STATUS, "targeting": T.ALLY_ALL, "status_id": &"evasive", "status_turns": 2}),
		SkillDef.make(&"execute", "Execute", "One enormous, final swing.",
			{"elements": [EL.SLASH] as Array[int], "mp_cost": 14, "damage_type": D.MELEE, "power": 2.6}),
		SkillDef.make(&"grim_resolve", "Grim Resolve", "Take 30% less damage for 3 turns.",
			{"mp_cost": 6, "effect": E.STATUS, "targeting": T.SELF, "status_id": &"ward", "status_turns": 3}),
		SkillDef.make(&"holy_light", "Holy Light", "Heals the whole party.",
			{"mp_cost": 16, "effect": E.HEAL, "targeting": T.ALLY_ALL, "power": 1.2, "heal_pct_max_hp": 0.1}),
		SkillDef.make(&"divine_lance", "Divine Lance", "A lance of holy light.",
			{"elements": [EL.HOLY] as Array[int], "mp_cost": 10, "damage_type": D.MAGIC, "power": 1.7}),
		SkillDef.make(&"foresight", "Foresight", "The whole party gets +30% dodge for 2 turns.",
			{"mp_cost": 12, "effect": E.STATUS, "targeting": T.ALLY_ALL, "status_id": &"evasive", "status_turns": 2}),
		SkillDef.make(&"starfall", "Starfall", "Holy starlight falls on every enemy.",
			{"elements": [EL.HOLY] as Array[int], "mp_cost": 16, "damage_type": D.MAGIC, "targeting": T.ENEMY_ALL, "power": 1.0}),

		# =====================================================
		# Blessed skills: usable only while blessed by that being (BeingLibrary)
		# =====================================================
		SkillDef.make(&"righteous_smite", "Righteous Smite", "Astraea's judgment falls on one enemy.",
			{"elements": [EL.HOLY] as Array[int], "mp_cost": 8, "damage_type": D.MAGIC, "power": 1.6}),
		SkillDef.make(&"mercys_embrace", "Mercy's Embrace", "Solenne's warmth heals the whole party.",
			{"mp_cost": 14, "effect": E.HEAL, "targeting": T.ALLY_ALL, "power": 1.0, "heal_pct_max_hp": 0.1}),
		SkillDef.make(&"avarice_strike", "Avarice Strike", "Vorak's greed made sharp. +25% crit chance.",
			{"elements": [EL.DARK] as Array[int], "mp_cost": 8, "damage_type": D.MELEE, "power": 1.6, "bonus_crit": 0.25}),
		SkillDef.make(&"hellfire", "Hellfire", "Ishra's rage burns every enemy.",
			{"elements": [EL.FIRE] as Array[int], "mp_cost": 16, "damage_type": D.MAGIC, "targeting": T.ENEMY_ALL, "power": 1.0}),
		SkillDef.make(&"devils_due", "Devil's Due", "Sable collects from one enemy.",
			{"elements": [EL.DARK] as Array[int], "mp_cost": 10, "damage_type": D.MAGIC, "power": 1.8}),
		SkillDef.make(&"vendetta", "Vendetta", "Corvin guides a strike past any guard.",
			{"elements": [EL.DARK, EL.PIERCE] as Array[int], "mp_cost": 9, "damage_type": D.MELEE, "power": 1.7, "ignores_row": true}),

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
	if class_id == &"":
		return out
	# Advanced classes keep the skills of every class they came from
	# (tier-1 skills first, then each advancement's).
	var line := ClassRegistry.lineage(class_id)
	line.reverse()
	for cid in line:
		for sid in CLASS_SKILLS.get(cid, []):
			out.append(get_skill(sid))
	return out


## Advanced classes use their tier-1 class's basic attack and row.
static func basic_attack_for_class(class_id: StringName) -> SkillDef:
	var root := ClassRegistry.root_of(class_id) if class_id != &"" else class_id
	return get_skill(CLASS_BASIC_ATTACK.get(class_id, CLASS_BASIC_ATTACK.get(root, &"attack_melee")))


static func default_row_for_class(class_id: StringName) -> int:
	var root := ClassRegistry.root_of(class_id) if class_id != &"" else class_id
	return Combatant.Row.BACK if root in CLASS_DEFAULT_BACK_ROW else Combatant.Row.FRONT
