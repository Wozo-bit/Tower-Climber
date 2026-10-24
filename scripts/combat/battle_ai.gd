class_name BattleAI
extends RefCounted
## Simple AI for enemies (and for party members when auto-battling in tests).
## - Healers heal an ally under 50% HP if they can.
## - Otherwise, sometimes use an affordable skill, else basic attack.
## - Single-target attacks go for a taunting unit if one is reachable.

const HEAL_THRESHOLD := 0.5


static func choose(battle: BattleManager, actor: Combatant) -> BattleAction:
	var rng := battle.rng

	# 1. Heal if someone is hurting.
	for s in actor.skills:
		if s.effect == SkillDef.Effect.HEAL and actor.can_afford(s):
			var hurt := _most_hurt(battle.allies_of(actor))
			if hurt and float(hurt.hp) / hurt.max_hp < HEAL_THRESHOLD:
				return BattleAction.use_skill(actor, s, hurt)

	# 2. Maybe use a skill.
	var usable: Array[SkillDef] = []
	for s in actor.skills:
		if actor.can_afford(s) and s.effect != SkillDef.Effect.HEAL:
			usable.append(s)
	var skill := actor.basic_attack
	if not usable.is_empty() and rng.randf() < actor.skill_chance:
		skill = usable[rng.randi_range(0, usable.size() - 1)]

	# 3. Pick a target.
	var targets := battle.valid_targets(actor, skill)
	if targets.is_empty():
		# e.g. a back-row melee enemy with nothing reachable: fall back to basic attack / defend
		skill = actor.basic_attack
		targets = battle.valid_targets(actor, skill)
		if targets.is_empty():
			return BattleAction.simple(BattleAction.Type.DEFEND, actor)

	if not skill.is_single_target():
		return BattleAction.use_skill(actor, skill)

	if skill.targets_enemies():
		for t in targets:
			if t.has_status(&"taunt"):
				return BattleAction.use_skill(actor, skill, t)
		# Easily distracted: goes after whoever hit it last.
		if actor.has_trait(&"easily_distracted") and actor.last_attacker and targets.has(actor.last_attacker):
			return BattleAction.use_skill(actor, skill, actor.last_attacker)
	return BattleAction.use_skill(actor, skill, targets[rng.randi_range(0, targets.size() - 1)])


static func _most_hurt(units: Array[Combatant]) -> Combatant:
	var best: Combatant = null
	for u in units:
		if u.is_alive() and (best == null or float(u.hp) / u.max_hp < float(best.hp) / best.max_hp):
			best = u
	return best
