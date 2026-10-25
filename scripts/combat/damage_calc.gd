class_name DamageCalc
extends RefCounted
## All combat math in one place. Every constant here is a first-pass
## placeholder meant to be tuned once real floors exist.

const MELEE_PER_STR := 3.0
const RANGED_PER_STR := 1.5
const RANGED_PER_AGI := 1.5
const MAGIC_PER_INT := 3.0
const HEAL_PER_INT := 2.0

## Defense uses a ratio curve: damage * 100 / (100 + DEF * DEF_WEIGHT).
## Defense always helps but never makes you immune.
const DEF_WEIGHT := 4.0
const VARIANCE := 0.1          # ±10%
const CRIT_MULT := 1.5

# Row / status modifiers
const BACK_ROW_MELEE_MULT := 0.5   # melee attacks FROM the back row
const DEFEND_MULT := 0.5
const WARD_MULT := 0.7
const GUARD_MULT := 0.7            # a guardian takes 30% less while guarding
const HASTE_INITIATIVE_MULT := 2.0


static func attack_power(attacker: Combatant, type: int) -> float:
	var s := attacker.stats
	match type:
		SkillDef.DamageType.MELEE:
			return s.get_total(Stats.Type.STRENGTH) * MELEE_PER_STR
		SkillDef.DamageType.RANGED:
			return s.get_total(Stats.Type.STRENGTH) * RANGED_PER_STR \
				+ s.get_total(Stats.Type.AGILITY) * RANGED_PER_AGI
		_:
			return s.get_total(Stats.Type.INTELLIGENCE) * MAGIC_PER_INT


## Adaptive skills use whichever of Strength / Intelligence is higher.
static func effective_type(attacker: Combatant, skill: SkillDef) -> int:
	if not skill.adaptive:
		return skill.damage_type
	var s := attacker.stats
	return SkillDef.DamageType.MELEE if s.get_total(Stats.Type.STRENGTH) >= s.get_total(Stats.Type.INTELLIGENCE) \
		else SkillDef.DamageType.MAGIC


static func defense_of(target: Combatant, type: int) -> float:
	if type == SkillDef.DamageType.MAGIC:
		return target.stats.magic_defense()
	return target.stats.physical_defense()


## Elements this hit carries: the skill's own, plus the weapon's kind for
## physical skills that don't name one, plus an elemental weapon's element on
## basic attacks.
static func attack_elements(attacker: Combatant, skill: SkillDef) -> Array[int]:
	var out: Array[int] = skill.elements.duplicate()
	var physical := effective_type(attacker, skill) != SkillDef.DamageType.MAGIC
	if physical and attacker.weapon_kind >= 0 and not out.any(func(e): return Element.WEAPON_KINDS.has(e)):
		out.append(attacker.weapon_kind)
	if skill == attacker.basic_attack and attacker.weapon_element >= 0 and not out.has(attacker.weapon_element):
		out.append(attacker.weapon_element)
	return out


## Returns { "miss", "crit", "amount", "elements", "weak", "resisted",
## "immune", "absorbed", "hit" } (see Element.resolve for the last five).
## "absorbed": `amount` is HP the target regains instead of losing.
## Note: marks a Gelatinous target as having softened its hit this round.
static func roll_damage(attacker: Combatant, target: Combatant, skill: SkillDef,
		rng: RandomNumberGenerator) -> Dictionary:
	var type := effective_type(attacker, skill)
	var elements := attack_elements(attacker, skill)
	# Dodge: physical only. Magic always lands.
	if type != SkillDef.DamageType.MAGIC and rng.randf() < target.dodge_chance():
		return { "miss": true, "crit": false, "amount": 0, "elements": elements, "weak": false,
			"resisted": false, "immune": false, "absorbed": false, "hit": {} }

	var raw := attack_power(attacker, type) * skill.power * rng.randf_range(1.0 - VARIANCE, 1.0 + VARIANCE)
	var def := defense_of(target, type) * (1.0 - skill.def_pierce)
	var dmg := raw * 100.0 / (100.0 + def * DEF_WEIGHT)

	if type == SkillDef.DamageType.MELEE and attacker.row == Combatant.Row.BACK and not skill.adaptive:
		dmg *= BACK_ROW_MELEE_MULT

	var crit := rng.randf() < attacker.crit_chance() + skill.bonus_crit
	if crit:
		dmg *= CRIT_MULT

	if target.has_status(&"defend"):
		dmg *= DEFEND_MULT
	if target.has_status(&"ward"):
		dmg *= WARD_MULT
	if target.has_status(&"guarding"):
		dmg *= GUARD_MULT

	# Traits
	if attacker.has_trait(&"reckless") and attacker.hp * 2 < attacker.max_hp:
		dmg *= EnemyFamilies.RECKLESS_MULT
	if type != SkillDef.DamageType.MAGIC and target.has_trait(&"gelatinous") and not target.gel_used:
		dmg *= EnemyFamilies.GELATINOUS_MULT
		target.gel_used = true
	if attacker.has_trait(&"swarming"):
		dmg *= 1.0 + minf(EnemyFamilies.SWARM_PER_ALLY * attacker.swarm_allies, EnemyFamilies.SWARM_MAX)

	# Elements: weak / resist / immune / absorb
	# Blessings: more damage with favoured elements (adds up across elements).
	var boost := 0.0
	for e in elements:
		boost += attacker.element_power.get(e, 0.0)
	dmg *= 1.0 + boost

	var aff := Element.resolve(elements, target.affinities)
	if target.has_trait(&"dragonscale") and not aff.weak:
		dmg *= EnemyFamilies.DRAGONSCALE_MULT   # only weaknesses get through the scales cleanly
	var amount: int
	if aff.absorbed:
		amount = maxi(1, roundi(dmg))   # healed by this much
	elif aff.immune:
		amount = 0
	else:
		amount = maxi(1, roundi(dmg * aff.mult))
	return { "miss": false, "crit": crit, "amount": amount, "elements": elements, "weak": aff.weak,
		"resisted": aff.resisted, "immune": aff.immune, "absorbed": aff.absorbed, "hit": aff.hit }


## Average heal with no randomness (used out of battle). Some heals also
## restore a % of the target's max HP (heal_pct_max_hp).
static func base_heal(stats: StatBlock, skill: SkillDef, target_max_hp: int = 0) -> int:
	return maxi(1, roundi(stats.get_total(Stats.Type.INTELLIGENCE) * HEAL_PER_INT * skill.power
		+ target_max_hp * skill.heal_pct_max_hp))


static func roll_heal(healer: Combatant, skill: SkillDef, rng: RandomNumberGenerator, target: Combatant = null) -> int:
	var max_hp := target.max_hp if target else 0
	return maxi(1, roundi(base_heal(healer.stats, skill, max_hp) * rng.randf_range(1.0 - VARIANCE, 1.0 + VARIANCE)))
