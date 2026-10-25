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
	# Added 2026-10-25: new classes, tier 3 and demigods.
	&"warrior": [&"heavy_swing", &"battle_fury"],
	&"monk": [&"flurry", &"inner_peace"],
	&"spellblade": [&"flame_edge", &"storm_edge"],
	&"magic_swordsman": [&"arcane_guard", &"enchanted_edge"],
	&"summoner": [&"summon_wisp", &"spirit_bolt"],
	&"berserker": [&"blood_frenzy", &"reckless_cleave"],
	&"warlord": [&"battle_standard", &"commanding_strike"],
	&"grandmaster": [&"hundred_fists", &"iron_body"],
	&"shadowfist": [&"shadow_palm", &"mist_step"],
	&"stormblade": [&"thunder_edge", &"tempest_slash"],
	&"arcane_knight": [&"spell_bulwark", &"arcane_lance"],
	&"blademaster": [&"iaido", &"blade_dance"],
	&"runeguard": [&"rune_of_warding", &"rune_strike"],
	&"beastcaller": [&"summon_wolf", &"pack_howl"],
	&"spiritbinder": [&"summon_guardian", &"spirit_mend"],
	&"necromancer_class": [&"raise_dead", &"death_bolt"],
	&"bastion_t3": [&"unbreakable"],
	&"juggernaut_t3": [&"earthsplitter"],
	&"paladin_t3": [&"divine_judgment"],
	&"pyromancer_t3": [&"phoenix_flame"],
	&"stormcaller_t3": [&"heavens_wrath"],
	&"warlock_t3": [&"abyssal_pact"],
	&"sharpshooter_t3": [&"killshot"],
	&"ranger_t3": [&"hurricane_volley"],
	&"assassin_t3": [&"death_blossom"],
	&"trickster_t3": [&"jackpot"],
	&"executioner_t3": [&"final_verdict"],
	&"cleric_t3": [&"miracle"],
	&"oracle_t3": [&"fated_strike"],
	&"berserker_t3": [&"world_breaker"],
	&"warlord_t3": [&"conquerors_banner"],
	&"grandmaster_t3": [&"nirvana_strike"],
	&"shadowfist_t3": [&"phantom_barrage"],
	&"stormblade_t3": [&"lightning_cleave"],
	&"arcane_knight_t3": [&"aegis_of_runes"],
	&"blademaster_t3": [&"one_cut"],
	&"runeguard_t3": [&"rune_burst"],
	&"beastcaller_t3": [&"summon_great_beast"],
	&"spiritbinder_t3": [&"soul_chorus"],
	&"necromancer_class_t3": [&"army_of_the_dead"],
	&"lionheart": [&"lion_skin", &"club_of_heracles"],
	&"lionheart_t3": [&"twelve_labors"],
	&"gorgonbane": [&"harpe_strike", &"aegis_reflection"],
	&"gorgonbane_t3": [&"medusas_gaze"],
	&"myrmidon_lord": [&"swift_footed", &"spear_of_achilles"],
	&"myrmidon_lord_t3": [&"wrath_of_achilles"],
	&"king_of_uruk": [&"kings_challenge", &"cedar_axe"],
	&"king_of_uruk_t3": [&"flood_of_ages"],
	&"hound_of_ulster": [&"gae_bolg", &"salmon_leap"],
	&"hound_of_ulster_t3": [&"riastrad_rage"],
	&"dragonslayer": [&"gram_strike", &"dragons_blood"],
	&"dragonslayer_t3": [&"fafnirs_end"],
}

## The Ascendant earns a new skill as each advancement gate opens for it
## (tier -> skill), so it keeps pace with the tiers.
const ASCENDANT_GATE_SKILLS := { 2: &"ascendant_will", 3: &"ascendant_dominion" }
## Ascension (NG+): the capstone every Ascended line gets.
const ASCENSION_SKILL := &"apotheosis"

## LEVEL-UP SKILL PICKS fit the class fantasy (Hayden 2026-10-25): each class
## line picks from its own pool of Common skills. Skill books still teach
## anyone anything (the rare way to break the mold). Advanced classes use the
## pool of the class they came from. Placeholder lists, easy to change.
const NOVICE_POOL := [&"first_aid", &"power_strike", &"guard", &"ember"]   # before a class (levels 1-9)
const CLASS_PICK_POOLS := {
	&"tank": [&"power_strike", &"guard", &"first_aid", &"focus", &"quick_step"],
	&"mage": [&"ember", &"frost_bolt", &"splash", &"spark", &"stone_shot", &"gust", &"focus"],
	&"archer": [&"quick_step", &"focus", &"first_aid", &"gust", &"spark"],
	&"rogue": [&"quick_step", &"power_strike", &"focus", &"first_aid", &"guard"],
	&"support": [&"first_aid", &"focus", &"guard", &"quick_step", &"splash", &"gust"],
	&"ashbound_knight": [&"power_strike", &"guard", &"first_aid", &"quick_step", &"ember"],
	&"warrior": [&"power_strike", &"guard", &"first_aid", &"quick_step", &"focus"],
	&"monk": [&"quick_step", &"focus", &"first_aid", &"power_strike", &"gust"],
	&"spellblade": [&"ember", &"frost_bolt", &"spark", &"power_strike", &"focus"],
	&"magic_swordsman": [&"guard", &"power_strike", &"first_aid", &"focus", &"ember"],
	&"summoner": [&"focus", &"first_aid", &"splash", &"stone_shot", &"gust", &"frost_bolt"],
	# Demigods (their own class lines)
	&"lionheart": [&"power_strike", &"guard", &"first_aid", &"quick_step", &"focus"],
	&"gorgonbane": [&"quick_step", &"power_strike", &"first_aid", &"focus", &"stone_shot"],
	&"myrmidon_lord": [&"quick_step", &"power_strike", &"guard", &"focus", &"first_aid"],
	&"king_of_uruk": [&"power_strike", &"guard", &"focus", &"splash", &"first_aid"],
	&"hound_of_ulster": [&"quick_step", &"power_strike", &"focus", &"first_aid", &"gust"],
	&"dragonslayer": [&"power_strike", &"guard", &"first_aid", &"focus", &"frost_bolt"],
}
## Classes that may pick any Common skill (the NG+ Ascendant has mastered everything).
const OPEN_POOL_CLASSES := [&"ascendant"]

## SKILL RANKS: a skill pick can rank up a skill you know instead (up to
## MAX_SKILL_RANK). Each rank above 1: +RANK_POWER power (and heal %), and
## -RANK_MP of its MP cost. Blessed skills can't be ranked (they're the being's).
const MAX_SKILL_RANK := 3
const RANK_POWER := 0.15
const RANK_MP := 0.1
const RANK_NUMERALS := ["", "", " II", " III", " IV", " V"]

## Default basic attack per class. Classless characters use attack_novice.
const CLASS_BASIC_ATTACK := {
	&"tank": &"attack_melee",
	&"rogue": &"attack_melee",
	&"archer": &"attack_ranged",
	&"mage": &"attack_magic",
	&"support": &"attack_magic",
	&"ashbound_knight": &"attack_melee",
	&"ascendant": &"attack_melee",
	&"warrior": &"attack_melee",
	&"monk": &"attack_melee",
	&"spellblade": &"attack_novice",
	&"magic_swordsman": &"attack_melee",
	&"summoner": &"attack_magic",
}

## Default row per class (the player can change it in battle).
const CLASS_DEFAULT_BACK_ROW := [&"archer", &"mage", &"support", &"summoner"]


static func _build() -> Dictionary:
	var list: Array[SkillDef] = [
		# --- Basic attacks (free) ---
		SkillDef.make(&"attack_melee", "Attack", "A basic melee strike.",
			{"damage_type": D.MELEE}),
		SkillDef.make(&"attack_ranged", "Shoot", "A basic ranged shot. Ignores rows.",
			{"damage_type": D.RANGED}),
		SkillDef.make(&"attack_magic", "Magic Bolt", "A weak bolt of magic. Ignores rows, can't be dodged.",
			{"damage_type": D.MAGIC, "power": 0.8}),
		# Before a class (levels 1-9): uses your stronger of Strength or
		# Intelligence, so a future mage isn't stuck punching.
		SkillDef.make(&"attack_novice", "Attack", "A basic strike with your stronger of Strength or Intelligence.",
			{"damage_type": D.MELEE, "adaptive": true}),

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
		# Stage bosses added 2026-10-25: their signature moves (Unique books).
		SkillDef.make(&"highwaymans_ruin", "Highwayman's Ruin", "The Bandit Lord's finisher: a brutal blow that reaches any row.",
			{"elements": [EL.SLASH] as Array[int], "mp_cost": 20, "damage_type": D.MELEE, "ignores_row": true, "power": 2.6,
			"bonus_crit": 0.2, "learnable": true, "tier": 4}),
		SkillDef.make(&"chitin_storm", "Chitin Storm", "The Hive Queen's swarm: shards of shell and wind tear at every enemy.",
			{"elements": [EL.WIND, EL.EARTH] as Array[int], "mp_cost": 24, "damage_type": D.MAGIC, "targeting": T.ENEMY_ALL,
			"power": 1.6, "learnable": true, "tier": 4}),
		SkillDef.make(&"moonfang_bite", "Moonfang", "The Great Wolf's bite: an enormous blow from any row.",
			{"elements": [EL.PIERCE] as Array[int], "mp_cost": 22, "damage_type": D.MELEE, "ignores_row": true, "power": 2.9,
			"learnable": true, "tier": 4}),
		SkillDef.make(&"cataclysm", "Cataclysm", "The Rift Sovereign's storm of fire, frost and lightning hits every enemy.",
			{"elements": [EL.FIRE, EL.ICE, EL.LIGHTNING] as Array[int], "mp_cost": 28, "damage_type": D.MAGIC, "targeting": T.ENEMY_ALL,
			"power": 1.7, "learnable": true, "tier": 4}),
		SkillDef.make(&"grave_tide", "Grave Tide", "The Necromancer's tide of the dead washes over every enemy.",
			{"elements": [EL.DARK, EL.ICE] as Array[int], "mp_cost": 26, "damage_type": D.MAGIC, "targeting": T.ENEMY_ALL,
			"power": 1.7, "learnable": true, "tier": 4}),
		SkillDef.make(&"abyssal_brand", "Abyssal Brand", "The Archfiend's brand of hellfire and shadow, with your stronger of STR or INT.",
			{"elements": [EL.FIRE, EL.DARK] as Array[int], "mp_cost": 22, "damage_type": D.MAGIC, "adaptive": true,
			"ignores_row": true, "power": 2.8, "learnable": true, "tier": 4}),
		SkillDef.make(&"judgment_ray", "Judgment Ray", "The Seraph's verdict: holy light on every enemy.",
			{"elements": [EL.HOLY] as Array[int], "mp_cost": 26, "damage_type": D.MAGIC, "targeting": T.ENEMY_ALL,
			"power": 1.8, "learnable": true, "tier": 4}),
		SkillDef.make(&"dragonfire", "Dragonfire", "The Sovereign's breath engulfs every enemy.",
			{"elements": [EL.FIRE] as Array[int], "mp_cost": 30, "damage_type": D.MAGIC, "adaptive": true, "ignores_row": true,
			"targeting": T.ENEMY_ALL, "power": 2.0, "learnable": true, "tier": 4}),
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
		SkillDef.make(&"righteous_smite", "Righteous Smite", "Holy judgment falls on one enemy.",
			{"elements": [EL.HOLY] as Array[int], "mp_cost": 8, "damage_type": D.MAGIC, "power": 1.6}),
		SkillDef.make(&"mercys_embrace", "Mercy's Embrace", "A warm blessing heals the whole party.",
			{"mp_cost": 14, "effect": E.HEAL, "targeting": T.ALLY_ALL, "power": 1.0, "heal_pct_max_hp": 0.1}),
		SkillDef.make(&"avarice_strike", "Avarice Strike", "Greed made sharp. +25% crit chance.",
			{"elements": [EL.DARK] as Array[int], "mp_cost": 8, "damage_type": D.MELEE, "power": 1.6, "bonus_crit": 0.25}),
		SkillDef.make(&"hellfire", "Hellfire", "Underworld fire burns every enemy.",
			{"elements": [EL.FIRE] as Array[int], "mp_cost": 16, "damage_type": D.MAGIC, "targeting": T.ENEMY_ALL, "power": 1.0}),
		SkillDef.make(&"devils_due", "Devil's Due", "The devil collects from one enemy.",
			{"elements": [EL.DARK] as Array[int], "mp_cost": 10, "damage_type": D.MAGIC, "power": 1.8}),
		SkillDef.make(&"vendetta", "Vendetta", "A raven-guided strike past any guard.",
			{"elements": [EL.DARK, EL.PIERCE] as Array[int], "mp_cost": 9, "damage_type": D.MELEE, "power": 1.7, "ignores_row": true}),
		SkillDef.make(&"gungnir", "Gungnir", "Odin's spear never misses its mark.",
			{"elements": [EL.PIERCE, EL.LIGHTNING] as Array[int], "mp_cost": 10, "damage_type": D.RANGED, "power": 1.7, "bonus_crit": 0.15}),
		SkillDef.make(&"mjolnir", "Mjolnir", "A thunderous hammer blow.",
			{"elements": [EL.LIGHTNING, EL.BLUNT] as Array[int], "mp_cost": 10, "damage_type": D.MELEE, "power": 1.8}),
		SkillDef.make(&"tricksters_gambit", "Trickster's Gambit", "Loki's trick: a sly, lucky strike from any row. +40% crit chance.",
			{"elements": [EL.DARK] as Array[int], "mp_cost": 8, "damage_type": D.MELEE, "power": 1.3, "ignores_row": true, "bonus_crit": 0.4}),
		SkillDef.make(&"helheim_frost", "Helheim's Frost", "The cold of the dead washes over every enemy.",
			{"elements": [EL.ICE, EL.DARK] as Array[int], "mp_cost": 16, "damage_type": D.MAGIC, "targeting": T.ENEMY_ALL, "power": 0.95}),
		SkillDef.make(&"thunderbolt", "Thunderbolt", "Zeus hurls lightning at every enemy.",
			{"elements": [EL.LIGHTNING] as Array[int], "mp_cost": 16, "damage_type": D.MAGIC, "targeting": T.ENEMY_ALL, "power": 1.0}),
		SkillDef.make(&"aegis", "Aegis", "Athena's shield: the whole party takes 30% less damage for 2 turns.",
			{"mp_cost": 12, "effect": E.STATUS, "targeting": T.ALLY_ALL, "status_id": &"ward", "status_turns": 2}),
		SkillDef.make(&"bident", "Bident", "The underworld's two-pronged spear.",
			{"elements": [EL.DARK, EL.PIERCE] as Array[int], "mp_cost": 9, "damage_type": D.MELEE, "power": 1.7}),
		SkillDef.make(&"typhon_storm", "Typhon's Storm", "Monstrous winds tear at every enemy.",
			{"elements": [EL.WIND] as Array[int], "mp_cost": 16, "damage_type": D.MAGIC, "targeting": T.ENEMY_ALL, "power": 1.0}),
		SkillDef.make(&"sun_disk", "Sun Disk", "Ra's burning light on one enemy.",
			{"elements": [EL.FIRE, EL.HOLY] as Array[int], "mp_cost": 10, "damage_type": D.MAGIC, "power": 1.7}),
		SkillDef.make(&"weighing_of_the_heart", "Weighing of the Heart", "Anubis judges one enemy.",
			{"elements": [EL.DARK] as Array[int], "mp_cost": 10, "damage_type": D.MAGIC, "power": 1.8}),
		SkillDef.make(&"sandstorm", "Sandstorm", "Set's desert storm buries every enemy.",
			{"elements": [EL.WIND, EL.EARTH] as Array[int], "mp_cost": 16, "damage_type": D.MAGIC, "targeting": T.ENEMY_ALL, "power": 0.95}),
		SkillDef.make(&"devouring_dark", "Devouring Dark", "Apep's jaws close on one enemy.",
			{"elements": [EL.DARK] as Array[int], "mp_cost": 12, "damage_type": D.MAGIC, "power": 2.0}),
		SkillDef.make(&"crescent_blade", "Crescent Blade", "Guan Yu's great glaive cuts true.",
			{"elements": [EL.SLASH] as Array[int], "mp_cost": 10, "damage_type": D.MELEE, "power": 1.8}),
		SkillDef.make(&"ruyi_staff", "Ruyi Staff", "The Monkey King's staff grows to reach any row.",
			{"elements": [EL.BLUNT] as Array[int], "mp_cost": 8, "damage_type": D.MELEE, "power": 1.6, "ignores_row": true}),
		SkillDef.make(&"bone_mirage", "Bone Mirage", "Phantoms of bone confuse and cut every enemy.",
			{"elements": [EL.DARK] as Array[int], "mp_cost": 14, "damage_type": D.MAGIC, "targeting": T.ENEMY_ALL, "power": 0.9}),
		SkillDef.make(&"divine_mirror", "Divine Mirror", "Amaterasu's mirror shines on every enemy.",
			{"elements": [EL.HOLY] as Array[int], "mp_cost": 16, "damage_type": D.MAGIC, "targeting": T.ENEMY_ALL, "power": 1.0}),
		SkillDef.make(&"kusanagi", "Kusanagi", "The storm god's sword.",
			{"elements": [EL.SLASH, EL.WIND] as Array[int], "mp_cost": 10, "damage_type": D.MELEE, "power": 1.8}),
		SkillDef.make(&"oni_club", "Oni Club", "A huge iron club. Ignores 30% of defense.",
			{"elements": [EL.BLUNT] as Array[int], "mp_cost": 10, "damage_type": D.MELEE, "power": 2.0, "def_pierce": 0.3}),
		SkillDef.make(&"foxfire", "Foxfire", "Ghostly fox flames on every enemy.",
			{"elements": [EL.FIRE] as Array[int], "mp_cost": 15, "damage_type": D.MAGIC, "targeting": T.ENEMY_ALL, "power": 0.95}),
		SkillDef.make(&"primordial_tide", "Primordial Tide", "The first sea drowns every enemy.",
			{"elements": [EL.WATER] as Array[int], "mp_cost": 16, "damage_type": D.MAGIC, "targeting": T.ENEMY_ALL, "power": 1.0}),

		# =====================================================
		# Recruits' personal skills (NpcLibrary "personal_skill"): never
		# learnable from books; unlocked by finishing their loyalty quest.
		# =====================================================
		SkillDef.make(&"thunder_charge", "Thunder Charge", "Brakka's charge: a blunt blow crackling with Thor's lightning.",
			{"elements": [EL.BLUNT, EL.LIGHTNING] as Array[int], "mp_cost": 10, "damage_type": D.MELEE, "power": 1.9}),
		SkillDef.make(&"hunters_mark", "Hunter's Mark", "Tamsin never misses twice: a piercing shot. +30% crit chance.",
			{"elements": [EL.PIERCE] as Array[int], "mp_cost": 9, "damage_type": D.RANGED, "power": 1.8, "bonus_crit": 0.3}),
		SkillDef.make(&"saints_hymn", "Saint's Hymn", "Daphne's hymn heals the whole party.",
			{"mp_cost": 16, "effect": E.HEAL, "targeting": T.ALLY_ALL, "power": 1.0, "heal_pct_max_hp": 0.15}),
		SkillDef.make(&"dirty_work", "Dirty Work", "Garrick finds the gap in any guard, from any row.",
			{"elements": [EL.SLASH] as Array[int], "mp_cost": 10, "damage_type": D.MELEE, "ignores_row": true, "power": 2.0}),
		SkillDef.make(&"rain_of_thorns", "Rain of Thorns", "Rook's arrows fall on every enemy.",
			{"elements": [EL.PIERCE] as Array[int], "mp_cost": 14, "damage_type": D.RANGED, "targeting": T.ENEMY_ALL, "power": 1.1}),
		SkillDef.make(&"valkyries_shield", "Valkyrie's Shield", "Sigrun's oath: the whole party takes 30% less damage for 3 turns.",
			{"mp_cost": 14, "effect": E.STATUS, "targeting": T.ALLY_ALL, "status_id": &"ward", "status_turns": 3}),
		SkillDef.make(&"solar_flare", "Solar Flare", "Neferet calls down Ra's light: holy fire on every enemy.",
			{"elements": [EL.HOLY, EL.FIRE] as Array[int], "mp_cost": 18, "damage_type": D.MAGIC, "targeting": T.ENEMY_ALL, "power": 1.3}),
		SkillDef.make(&"thunder_oath", "Thunder Oath", "Lysander swears by Zeus: lightning with your stronger of STR or INT.",
			{"elements": [EL.LIGHTNING] as Array[int], "mp_cost": 12, "damage_type": D.MAGIC, "adaptive": true, "power": 2.0}),
		SkillDef.make(&"lions_grace", "Lion's Grace", "Shamira's dancing strike. +40% crit chance.",
			{"elements": [EL.SLASH] as Array[int], "mp_cost": 9, "damage_type": D.MELEE, "power": 1.8, "bonus_crit": 0.4}),
		SkillDef.make(&"stand_firm", "Stand Firm", "Old Fenn plants his feet and draws every blow for 3 turns.",
			{"mp_cost": 8, "effect": E.STATUS, "targeting": T.SELF, "status_id": &"taunt", "status_turns": 3}),
		SkillDef.make(&"shadowstep", "Shadowstep", "Kael strikes from the dark, past any front line.",
			{"elements": [EL.DARK] as Array[int], "mp_cost": 10, "damage_type": D.MELEE, "ignores_row": true, "power": 1.9,
			"bonus_crit": 0.15}),
		SkillDef.make(&"frost_nova", "Frost Nova", "Vesna freezes the air around every enemy.",
			{"elements": [EL.ICE] as Array[int], "mp_cost": 16, "damage_type": D.MAGIC, "targeting": T.ENEMY_ALL, "power": 1.4}),

		# =====================================================
		# Classes added 2026-10-25 (Hayden): new tier-1 classes, their tier 2,
		# tier-3 capstones, demigods, the Ascendant's gate skills, Ascension.
		# Placeholder names and numbers.
		# =====================================================
		# warrior
		SkillDef.make(&"heavy_swing", "Heavy Swing", "A huge two-handed blow.",
			{"elements": [EL.SLASH] as Array[int], "mp_cost": 4, "damage_type": D.MELEE, "power": 1.6}),
		SkillDef.make(&"battle_fury", "Battle Fury", "Rage: deal 30% more damage for 3 turns.",
			{"mp_cost": 6, "effect": E.STATUS, "targeting": T.SELF, "status_id": &"fury", "status_turns": 3}),
		# monk
		SkillDef.make(&"flurry", "Flurry", "A storm of fists. +30% crit chance.",
			{"elements": [EL.BLUNT] as Array[int], "mp_cost": 4, "damage_type": D.MELEE, "power": 1.4, "bonus_crit": 0.3}),
		SkillDef.make(&"inner_peace", "Inner Peace", "Breathe: recover 25% of your max HP.",
			{"mp_cost": 6, "effect": E.HEAL, "targeting": T.SELF, "power": 0.0, "heal_pct_max_hp": 0.25}),
		# spellblade
		SkillDef.make(&"flame_edge", "Flame Edge", "A burning strike with your stronger of STR or INT.",
			{"elements": [EL.FIRE, EL.SLASH] as Array[int], "mp_cost": 5, "damage_type": D.MELEE, "power": 1.5, "adaptive": true}),
		SkillDef.make(&"storm_edge", "Storm Edge", "Lightning leaps off your blade to every enemy.",
			{"elements": [EL.LIGHTNING] as Array[int], "mp_cost": 9, "damage_type": D.MELEE, "power": 0.9, "adaptive": true, "targeting": T.ENEMY_ALL}),
		# magic_swordsman
		SkillDef.make(&"arcane_guard", "Arcane Guard", "Enchanted armour: take 30% less damage for 3 turns.",
			{"mp_cost": 5, "effect": E.STATUS, "targeting": T.SELF, "status_id": &"ward", "status_turns": 3}),
		SkillDef.make(&"enchanted_edge", "Enchanted Edge", "A glowing cut that ignores 20% of defense.",
			{"elements": [EL.HOLY, EL.SLASH] as Array[int], "mp_cost": 5, "damage_type": D.MELEE, "power": 1.5, "def_pierce": 0.2}),
		# summoner
		SkillDef.make(&"summon_wisp", "Summon Wisp", "Call a wisp that fights beside you until it falls.",
			{"mp_cost": 10, "effect": E.SUMMON, "targeting": T.SELF, "summon_id": &"wisp"}),
		SkillDef.make(&"spirit_bolt", "Spirit Bolt", "A bolt of spirit light. Ignores rows.",
			{"mp_cost": 4, "damage_type": D.MAGIC, "power": 1.3}),
		# berserker
		SkillDef.make(&"blood_frenzy", "Blood Frenzy", "Deal 30% more damage for 4 turns.",
			{"mp_cost": 8, "effect": E.STATUS, "targeting": T.SELF, "status_id": &"fury", "status_turns": 4}),
		SkillDef.make(&"reckless_cleave", "Reckless Cleave", "Hits every enemy you can reach.",
			{"elements": [EL.SLASH] as Array[int], "mp_cost": 9, "damage_type": D.MELEE, "power": 1.0, "targeting": T.ENEMY_ALL}),
		# warlord
		SkillDef.make(&"battle_standard", "Battle Standard", "The whole party deals 30% more damage for 2 turns.",
			{"mp_cost": 14, "effect": E.STATUS, "targeting": T.ALLY_ALL, "status_id": &"fury", "status_turns": 2}),
		SkillDef.make(&"commanding_strike", "Commanding Strike", "A leader's blow.",
			{"mp_cost": 7, "damage_type": D.MELEE, "power": 1.8}),
		# grandmaster
		SkillDef.make(&"hundred_fists", "Hundred Fists", "A blur of strikes. +20% crit chance.",
			{"elements": [EL.BLUNT] as Array[int], "mp_cost": 9, "damage_type": D.MELEE, "power": 2.2, "bonus_crit": 0.2}),
		SkillDef.make(&"iron_body", "Iron Body", "Take 30% less damage for 3 turns.",
			{"mp_cost": 6, "effect": E.STATUS, "targeting": T.SELF, "status_id": &"ward", "status_turns": 3}),
		# shadowfist
		SkillDef.make(&"shadow_palm", "Shadow Palm", "A dark palm strike past any front line.",
			{"elements": [EL.DARK] as Array[int], "mp_cost": 7, "damage_type": D.MELEE, "power": 1.8, "ignores_row": true}),
		SkillDef.make(&"mist_step", "Mist Step", "+30% dodge for 3 turns.",
			{"mp_cost": 5, "effect": E.STATUS, "targeting": T.SELF, "status_id": &"evasive", "status_turns": 3}),
		# stormblade
		SkillDef.make(&"thunder_edge", "Thunder Edge", "Lightning and steel, with your stronger of STR or INT.",
			{"elements": [EL.LIGHTNING, EL.SLASH] as Array[int], "mp_cost": 9, "damage_type": D.MELEE, "power": 2.0, "adaptive": true}),
		SkillDef.make(&"tempest_slash", "Tempest Slash", "Wind and lightning cut every enemy.",
			{"elements": [EL.WIND, EL.LIGHTNING] as Array[int], "mp_cost": 13, "damage_type": D.MELEE, "power": 1.1, "adaptive": true, "targeting": T.ENEMY_ALL}),
		# arcane_knight
		SkillDef.make(&"spell_bulwark", "Spell Bulwark", "The whole party takes 30% less damage for 2 turns.",
			{"mp_cost": 12, "effect": E.STATUS, "targeting": T.ALLY_ALL, "status_id": &"ward", "status_turns": 2}),
		SkillDef.make(&"arcane_lance", "Arcane Lance", "A lance of force. Ignores rows.",
			{"mp_cost": 8, "damage_type": D.MAGIC, "power": 1.8}),
		# blademaster
		SkillDef.make(&"iaido", "Iaido", "Draw and cut in one motion. +25% crit chance.",
			{"elements": [EL.SLASH] as Array[int], "mp_cost": 10, "damage_type": D.MELEE, "power": 2.4, "bonus_crit": 0.25}),
		SkillDef.make(&"blade_dance", "Blade Dance", "Cuts every enemy you can reach.",
			{"elements": [EL.SLASH] as Array[int], "mp_cost": 10, "damage_type": D.MELEE, "power": 1.0, "targeting": T.ENEMY_ALL}),
		# runeguard
		SkillDef.make(&"rune_of_warding", "Rune of Warding", "The whole party takes 30% less damage for 3 turns.",
			{"mp_cost": 14, "effect": E.STATUS, "targeting": T.ALLY_ALL, "status_id": &"ward", "status_turns": 3}),
		SkillDef.make(&"rune_strike", "Rune Strike", "An earth rune bursts on impact.",
			{"elements": [EL.EARTH] as Array[int], "mp_cost": 7, "damage_type": D.MELEE, "power": 1.7}),
		# beastcaller
		SkillDef.make(&"summon_wolf", "Call the Pack", "A spirit wolf fights beside you.",
			{"mp_cost": 12, "effect": E.SUMMON, "targeting": T.SELF, "summon_id": &"spirit_wolf"}),
		SkillDef.make(&"pack_howl", "Pack Howl", "The whole party acts sooner for 2 rounds.",
			{"mp_cost": 10, "effect": E.STATUS, "targeting": T.ALLY_ALL, "status_id": &"haste", "status_turns": 2}),
		# spiritbinder
		SkillDef.make(&"summon_guardian", "Bind Guardian", "A guardian spirit stands in front of the party.",
			{"mp_cost": 12, "effect": E.SUMMON, "targeting": T.SELF, "summon_id": &"guardian_spirit"}),
		SkillDef.make(&"spirit_mend", "Spirit Mend", "Spirits heal the whole party.",
			{"mp_cost": 12, "effect": E.HEAL, "targeting": T.ALLY_ALL, "power": 0.8, "heal_pct_max_hp": 0.1}),
		# necromancer_class
		SkillDef.make(&"raise_dead", "Raise Dead", "A skeleton thrall rises to fight for you.",
			{"mp_cost": 12, "effect": E.SUMMON, "targeting": T.SELF, "summon_id": &"skeleton_thrall"}),
		SkillDef.make(&"death_bolt", "Death Bolt", "Raw death magic on one enemy.",
			{"elements": [EL.DARK] as Array[int], "mp_cost": 9, "damage_type": D.MAGIC, "power": 1.9}),
		# bastion_t3
		SkillDef.make(&"unbreakable", "Unbreakable", "The whole party takes 30% less damage for 4 turns.",
			{"mp_cost": 18, "effect": E.STATUS, "targeting": T.ALLY_ALL, "status_id": &"ward", "status_turns": 4}),
		# juggernaut_t3
		SkillDef.make(&"earthsplitter", "Earthsplitter", "Splits the ground under every enemy, any row.",
			{"elements": [EL.EARTH, EL.BLUNT] as Array[int], "mp_cost": 18, "damage_type": D.MELEE, "power": 1.5, "ignores_row": true, "targeting": T.ENEMY_ALL}),
		# paladin_t3
		SkillDef.make(&"divine_judgment", "Divine Judgment", "Holy wrath with your stronger of STR or INT.",
			{"elements": [EL.HOLY] as Array[int], "mp_cost": 16, "damage_type": D.MAGIC, "power": 2.6, "adaptive": true, "ignores_row": true}),
		# pyromancer_t3
		SkillDef.make(&"phoenix_flame", "Phoenix Flame", "Undying fire on every enemy.",
			{"elements": [EL.FIRE] as Array[int], "mp_cost": 22, "damage_type": D.MAGIC, "power": 1.8, "targeting": T.ENEMY_ALL}),
		# stormcaller_t3
		SkillDef.make(&"heavens_wrath", "Heaven's Wrath", "The storm breaks over every enemy.",
			{"elements": [EL.LIGHTNING, EL.WIND] as Array[int], "mp_cost": 22, "damage_type": D.MAGIC, "power": 1.8, "targeting": T.ENEMY_ALL}),
		# warlock_t3
		SkillDef.make(&"abyssal_pact", "Abyssal Pact", "Every pact called in on one enemy.",
			{"elements": [EL.DARK] as Array[int], "mp_cost": 20, "damage_type": D.MAGIC, "power": 3.0}),
		# sharpshooter_t3
		SkillDef.make(&"killshot", "Killshot", "The perfect shot. +30% crit chance.",
			{"elements": [EL.PIERCE] as Array[int], "mp_cost": 18, "damage_type": D.RANGED, "power": 3.0, "bonus_crit": 0.3}),
		# ranger_t3
		SkillDef.make(&"hurricane_volley", "Hurricane Volley", "Storm-borne arrows hit every enemy.",
			{"elements": [EL.WIND, EL.PIERCE] as Array[int], "mp_cost": 20, "damage_type": D.RANGED, "power": 1.6, "targeting": T.ENEMY_ALL}),
		# assassin_t3
		SkillDef.make(&"death_blossom", "Death Blossom", "Blades bloom across every enemy, any row.",
			{"elements": [EL.SLASH] as Array[int], "mp_cost": 20, "damage_type": D.MELEE, "power": 1.4, "ignores_row": true, "bonus_crit": 0.2, "targeting": T.ENEMY_ALL}),
		# trickster_t3
		SkillDef.make(&"jackpot", "Jackpot", "The luckiest strike ever thrown. +60% crit chance.",
			{"mp_cost": 14, "damage_type": D.MELEE, "power": 2.0, "bonus_crit": 0.6}),
		# executioner_t3
		SkillDef.make(&"final_verdict", "Final Verdict", "One last, enormous swing.",
			{"elements": [EL.SLASH] as Array[int], "mp_cost": 20, "damage_type": D.MELEE, "power": 3.2}),
		# cleric_t3
		SkillDef.make(&"miracle", "Miracle", "A great heal for the whole party.",
			{"mp_cost": 24, "effect": E.HEAL, "targeting": T.ALLY_ALL, "power": 1.4, "heal_pct_max_hp": 0.25}),
		# oracle_t3
		SkillDef.make(&"fated_strike", "Fated Strike", "The blow fate already chose. Holy.",
			{"elements": [EL.HOLY] as Array[int], "mp_cost": 16, "damage_type": D.MAGIC, "power": 2.4, "bonus_crit": 0.3}),
		# berserker_t3
		SkillDef.make(&"world_breaker", "World Breaker", "A blow that cracks the floor.",
			{"elements": [EL.BLUNT] as Array[int], "mp_cost": 20, "damage_type": D.MELEE, "power": 3.2}),
		# warlord_t3
		SkillDef.make(&"conquerors_banner", "Conqueror's Banner", "The whole party deals 30% more damage for 3 turns.",
			{"mp_cost": 20, "effect": E.STATUS, "targeting": T.ALLY_ALL, "status_id": &"fury", "status_turns": 3}),
		# grandmaster_t3
		SkillDef.make(&"nirvana_strike", "Nirvana Strike", "A perfect strike. +30% crit chance.",
			{"elements": [EL.BLUNT] as Array[int], "mp_cost": 16, "damage_type": D.MELEE, "power": 2.8, "bonus_crit": 0.3}),
		# shadowfist_t3
		SkillDef.make(&"phantom_barrage", "Phantom Barrage", "Unseen blows hit every enemy, any row.",
			{"elements": [EL.DARK] as Array[int], "mp_cost": 20, "damage_type": D.MELEE, "power": 1.4, "ignores_row": true, "targeting": T.ENEMY_ALL}),
		# stormblade_t3
		SkillDef.make(&"lightning_cleave", "Lightning Cleave", "Lightning cleaves every enemy.",
			{"elements": [EL.LIGHTNING, EL.SLASH] as Array[int], "mp_cost": 20, "damage_type": D.MELEE, "power": 1.6, "adaptive": true, "targeting": T.ENEMY_ALL}),
		# arcane_knight_t3
		SkillDef.make(&"aegis_of_runes", "Aegis of Runes", "The whole party takes 30% less damage for 4 turns.",
			{"mp_cost": 18, "effect": E.STATUS, "targeting": T.ALLY_ALL, "status_id": &"ward", "status_turns": 4}),
		# blademaster_t3
		SkillDef.make(&"one_cut", "One Cut", "The only cut that matters.",
			{"elements": [EL.SLASH] as Array[int], "mp_cost": 22, "damage_type": D.MELEE, "power": 3.5}),
		# runeguard_t3
		SkillDef.make(&"rune_burst", "Rune Burst", "Every rune bursts at once over every enemy.",
			{"elements": [EL.EARTH] as Array[int], "mp_cost": 20, "damage_type": D.MAGIC, "power": 1.6, "targeting": T.ENEMY_ALL}),
		# beastcaller_t3
		SkillDef.make(&"summon_great_beast", "Call the Great Beast", "A great spirit beast joins the fight.",
			{"mp_cost": 22, "effect": E.SUMMON, "targeting": T.SELF, "summon_id": &"great_beast"}),
		# spiritbinder_t3
		SkillDef.make(&"soul_chorus", "Soul Chorus", "Spirits sing the whole party back to strength.",
			{"mp_cost": 22, "effect": E.HEAL, "targeting": T.ALLY_ALL, "power": 1.2, "heal_pct_max_hp": 0.2}),
		# necromancer_class_t3
		SkillDef.make(&"army_of_the_dead", "Bone Colossus", "A colossus of bone rises to fight for you.",
			{"mp_cost": 24, "effect": E.SUMMON, "targeting": T.SELF, "summon_id": &"bone_colossus"}),
		# lionheart
		SkillDef.make(&"lion_skin", "Nemean Hide", "The lion's hide: take 30% less damage for 4 turns.",
			{"mp_cost": 8, "effect": E.STATUS, "targeting": T.SELF, "status_id": &"ward", "status_turns": 4}),
		SkillDef.make(&"club_of_heracles", "Olive-Wood Club", "A blow that once killed a lion.",
			{"elements": [EL.BLUNT] as Array[int], "mp_cost": 8, "damage_type": D.MELEE, "power": 2.2}),
		# lionheart_t3
		SkillDef.make(&"twelve_labors", "Twelve Labors", "Every labour in one fight: hits every enemy.",
			{"elements": [EL.BLUNT] as Array[int], "mp_cost": 20, "damage_type": D.MELEE, "power": 1.8, "ignores_row": true, "targeting": T.ENEMY_ALL}),
		# gorgonbane
		SkillDef.make(&"harpe_strike", "Harpe Strike", "The sickle that took the Gorgon's head. +20% crit chance.",
			{"elements": [EL.SLASH] as Array[int], "mp_cost": 8, "damage_type": D.MELEE, "power": 2.0, "bonus_crit": 0.2}),
		SkillDef.make(&"aegis_reflection", "Mirror Shield", "The whole party gets +30% dodge for 2 turns.",
			{"mp_cost": 12, "effect": E.STATUS, "targeting": T.ALLY_ALL, "status_id": &"evasive", "status_turns": 2}),
		# gorgonbane_t3
		SkillDef.make(&"medusas_gaze", "Gorgon's Gaze", "Stone creeps over every enemy.",
			{"elements": [EL.EARTH] as Array[int], "mp_cost": 20, "damage_type": D.MAGIC, "power": 1.6, "targeting": T.ENEMY_ALL}),
		# myrmidon_lord
		SkillDef.make(&"swift_footed", "Swift-Footed", "Much more likely to act first for 3 rounds.",
			{"mp_cost": 5, "effect": E.STATUS, "targeting": T.SELF, "status_id": &"haste", "status_turns": 3}),
		SkillDef.make(&"spear_of_achilles", "Pelian Spear", "A spear throw that reaches any row.",
			{"elements": [EL.PIERCE] as Array[int], "mp_cost": 8, "damage_type": D.MELEE, "power": 2.2, "ignores_row": true}),
		# myrmidon_lord_t3
		SkillDef.make(&"wrath_of_achilles", "Wrath of Achilles", "A grief-fuelled, enormous blow.",
			{"elements": [EL.PIERCE] as Array[int], "mp_cost": 20, "damage_type": D.MELEE, "power": 3.2}),
		# king_of_uruk
		SkillDef.make(&"kings_challenge", "King's Challenge", "Deal 30% more damage for 3 turns.",
			{"mp_cost": 8, "effect": E.STATUS, "targeting": T.SELF, "status_id": &"fury", "status_turns": 3}),
		SkillDef.make(&"cedar_axe", "Cedar-Forest Axe", "The axe that felled Humbaba's forest.",
			{"elements": [EL.SLASH] as Array[int], "mp_cost": 8, "damage_type": D.MELEE, "power": 2.0}),
		# king_of_uruk_t3
		SkillDef.make(&"flood_of_ages", "Flood of Ages", "The great flood, on every enemy.",
			{"elements": [EL.WATER] as Array[int], "mp_cost": 20, "damage_type": D.MAGIC, "power": 1.7, "adaptive": true, "targeting": T.ENEMY_ALL}),
		# hound_of_ulster
		SkillDef.make(&"gae_bolg", "Gae Bolg", "The barbed spear. +20% crit chance.",
			{"elements": [EL.PIERCE] as Array[int], "mp_cost": 9, "damage_type": D.MELEE, "power": 2.4, "bonus_crit": 0.2}),
		SkillDef.make(&"salmon_leap", "Salmon Leap", "+30% dodge for 3 turns.",
			{"mp_cost": 5, "effect": E.STATUS, "targeting": T.SELF, "status_id": &"evasive", "status_turns": 3}),
		# hound_of_ulster_t3
		SkillDef.make(&"riastrad_rage", "Warp Spasm", "A terrible battle-frenzy hits every enemy.",
			{"mp_cost": 20, "damage_type": D.MELEE, "power": 1.8, "ignores_row": true, "targeting": T.ENEMY_ALL}),
		# dragonslayer
		SkillDef.make(&"gram_strike", "Gram", "The reforged sword.",
			{"elements": [EL.SLASH] as Array[int], "mp_cost": 8, "damage_type": D.MELEE, "power": 2.2}),
		SkillDef.make(&"dragons_blood", "Dragon's Blood", "Recover 30% of your max HP.",
			{"mp_cost": 8, "effect": E.HEAL, "targeting": T.SELF, "power": 0.0, "heal_pct_max_hp": 0.3}),
		# dragonslayer_t3
		SkillDef.make(&"fafnirs_end", "Fafnir's End", "The blow that slew the dragon.",
			{"elements": [EL.FIRE, EL.SLASH] as Array[int], "mp_cost": 20, "damage_type": D.MELEE, "power": 3.0}),
		# Demigods' personal skills (their loyalty quests unlock them)
		SkillDef.make(&"nemean_roar", "Nemean Roar", "Heracles roars: the whole party deals 30% more damage for 2 turns.",
			{"mp_cost": 14, "effect": E.STATUS, "targeting": T.ALLY_ALL, "status_id": &"fury", "status_turns": 2}),
		SkillDef.make(&"winged_sandals", "Winged Sandals", "Hermes' gift: the whole party acts sooner for 2 rounds.",
			{"mp_cost": 10, "effect": E.STATUS, "targeting": T.ALLY_ALL, "status_id": &"haste", "status_turns": 2}),
		SkillDef.make(&"heel_guard", "Dipped in the Styx", "Achilles shrugs off harm: 30% less damage for 4 turns.",
			{"mp_cost": 6, "effect": E.STATUS, "targeting": T.SELF, "status_id": &"ward", "status_turns": 4}),
		SkillDef.make(&"gate_of_uruk", "Walls of Uruk", "Gilgamesh's walls: the whole party takes 30% less damage for 2 turns.",
			{"mp_cost": 12, "effect": E.STATUS, "targeting": T.ALLY_ALL, "status_id": &"ward", "status_turns": 2}),
		SkillDef.make(&"spear_storm", "Spear Storm", "Cu Chulainn hurls spears at every enemy.",
			{"elements": [EL.PIERCE] as Array[int], "mp_cost": 14, "damage_type": D.RANGED, "power": 1.3, "targeting": T.ENEMY_ALL}),
		SkillDef.make(&"birdspeech", "Birdspeech", "Sigurd heeds the birds: the whole party gets +30% dodge for 2 turns.",
			{"mp_cost": 12, "effect": E.STATUS, "targeting": T.ALLY_ALL, "status_id": &"evasive", "status_turns": 2}),
		SkillDef.make(&"ascendant_will", "Ascendant's Will", "The whole party takes 30% less damage for 3 turns.",
			{"mp_cost": 14, "effect": E.STATUS, "targeting": T.ALLY_ALL, "status_id": &"ward", "status_turns": 3}),
		SkillDef.make(&"ascendant_dominion", "Dominion", "A conqueror's strike on every enemy, with your stronger of STR or INT.",
			{"mp_cost": 24, "damage_type": D.MAGIC, "power": 2.0, "adaptive": true, "ignores_row": true, "targeting": T.ENEMY_ALL}),
		SkillDef.make(&"apotheosis", "Apotheosis", "A god's blow, with your stronger of STR or INT, from any row.",
			{"elements": [EL.HOLY] as Array[int], "mp_cost": 25, "damage_type": D.MAGIC, "power": 3.0, "adaptive": true, "ignores_row": true}),

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


## What a character of `class_id` can choose with a skill pick (before a class:
## the novice pool; advanced classes: their tier-1 class's pool).
static func pick_pool_for(class_id: StringName) -> Array[SkillDef]:
	if class_id == &"":
		return _skills_of(NOVICE_POOL)
	var root := ClassRegistry.root_of(class_id)
	if OPEN_POOL_CLASSES.has(class_id) or OPEN_POOL_CLASSES.has(root):
		return pick_pool()
	return _skills_of(CLASS_PICK_POOLS.get(class_id, CLASS_PICK_POOLS.get(root, NOVICE_POOL)))


static func _skills_of(ids: Array) -> Array[SkillDef]:
	var out: Array[SkillDef] = []
	for id in ids:
		var s := get_skill_or_null(id)
		if s:
			out.append(s)
	return out


## A copy of `s` at `rank` (1 = as written): stronger and cheaper per rank,
## with "II"/"III" on its name.
static func ranked(s: SkillDef, rank: int) -> SkillDef:
	if rank <= 1:
		return s
	var r := s.duplicate() as SkillDef
	var steps := rank - 1
	r.power = s.power * (1.0 + RANK_POWER * steps)
	r.heal_pct_max_hp = s.heal_pct_max_hp * (1.0 + RANK_POWER * steps)
	r.mp_cost = maxi(0, roundi(s.mp_cost * (1.0 - RANK_MP * steps)))
	r.display_name = s.display_name + RANK_NUMERALS[clampi(rank, 0, RANK_NUMERALS.size() - 1)]
	return r


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
	if class_id == &"":
		return get_skill(&"attack_novice")
	return get_skill(CLASS_BASIC_ATTACK.get(class_id, CLASS_BASIC_ATTACK.get(root, &"attack_melee")))


static func default_row_for_class(class_id: StringName) -> int:
	var root := ClassRegistry.root_of(class_id) if class_id != &"" else class_id
	return Combatant.Row.BACK if root in CLASS_DEFAULT_BACK_ROW else Combatant.Row.FRONT
