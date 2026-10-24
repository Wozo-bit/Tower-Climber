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


## Returns { "miss": bool, "crit": bool, "amount": int }
static func roll_damage(attacker: Combatant, target: Combatant, skill: SkillDef,
		rng: RandomNumberGenerator) -> Dictionary:
	var type := effective_type(attacker, skill)
	# Dodge: physical only. Magic always lands.
	if type != SkillDef.DamageType.MAGIC and rng.randf() < target.dodge_chance():
		return { "miss": true, "crit": false, "amount": 0 }

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

	return { "miss": false, "crit": crit, "amount": maxi(1, roundi(dmg)) }


## Average heal with no randomness (used out of battle). Some heals also
## restore a % of the target's max HP (heal_pct_max_hp).
static func base_heal(stats: StatBlock, skill: SkillDef, target_max_hp: int = 0) -> int:
	return maxi(1, roundi(stats.get_total(Stats.Type.INTELLIGENCE) * HEAL_PER_INT * skill.power
		+ target_max_hp * skill.heal_pct_max_hp))


static func roll_heal(healer: Combatant, skill: SkillDef, rng: RandomNumberGenerator, target: Combatant = null) -> int:
	var max_hp := target.max_hp if target else 0
	return maxi(1, roundi(base_heal(healer.stats, skill, max_hp) * rng.randf_range(1.0 - VARIANCE, 1.0 + VARIANCE)))
