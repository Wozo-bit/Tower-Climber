class_name BattleManager
extends RefCounted
## Turn-based battle logic, FF-style with front/back rows. No UI, no awaits:
## the UI (or a test) drives it by calling advance() for AI turns and
## submit() for player turns, and listens to the signals.
##
## ROW RULES
## - Melee attacks can't target a back-row unit while its side has a living
##   front-row unit (unless the skill ignores rows, e.g. Backstab).
## - Melee attacks made FROM the back row deal 50% damage.
## - Ranged and magic ignore rows entirely.
##
## TURN ORDER
## - Each round, every living unit rolls initiative = Agility * random(0.75-1.25).
##   Higher Agility = better chance to act first, never a guarantee.

signal round_started(round_number: int)
signal turn_started(actor: Combatant)
signal action_resolved(result: Dictionary)
signal battle_ended(outcome: int)
## Enemy intents changed (new round, a target died, someone taunted, ...).
signal intents_changed

enum Outcome { NONE, VICTORY, DEFEAT, FLED }

const INITIATIVE_SPREAD := 0.25
const FLEE_BASE := 0.5
const FLEE_PER_AGI_DIFF := 0.03

var party: Array[Combatant] = []
var enemies: Array[Combatant] = []
var rng := RandomNumberGenerator.new()
var current: Combatant
var outcome: int = Outcome.NONE
var round_number := 0
var can_flee := true
var rewards := { "xp": 0, "gold": 0, "items": {}, "gear": [], "books": [] }   # books: skill ids
## ENEMY INTENT: every AI unit decides its move at the start of each round, and
## the UI shows it (who they'll hit, with what) so the player can react with
## Defend, Guard, Ward, heals or row changes. Re-planned if it stops being valid.
var intents: Dictionary = {}   # Combatant -> BattleAction
## Party bag used by the Items command. Optional (null = no items in this fight).
var inventory: Inventory
## Floor number used for the stat size of gear drops.
var loot_level := 1
## Classes whose Unique weapon the party already owns (so it isn't dropped twice).
var owned_unique_classes: Array = []
## Multiplies enemy HP/stats (floor difficulty). Set BEFORE setup().
var enemy_scale := 1.0
## Where element discoveries are written (GameState.bestiary). Optional.
var bestiary: Bestiary

var _queue: Array[Combatant] = []


func setup(party_chars: Array[CharacterData], enemy_defs: Array[EnemyDef], seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	party.clear()
	enemies.clear()
	rewards = { "xp": 0, "gold": 0, "items": {}, "gear": [], "books": [] }
	intents.clear()
	for c in party_chars:
		party.append(Combatant.from_character(c))
	for e in enemy_defs:
		enemies.append(Combatant.from_enemy(e, enemy_scale))
		if bestiary:
			bestiary.record_seen(e)
	_dedupe_enemy_names()
	for e in enemies:
		if e.source_enemy.is_boss:
			can_flee = false


## Starts round 1 and stops at the first unit's turn.
func start() -> void:
	outcome = Outcome.NONE
	round_number = 0
	_queue.clear()
	if _check_end():  # e.g. everyone already downed
		return
	_next_turn()


func is_over() -> bool:
	return outcome != Outcome.NONE


func is_player_turn() -> bool:
	return not is_over() and current != null and not current.ai_controlled


## Runs the current unit's turn if it's AI-controlled.
func advance() -> void:
	if is_over() or current == null or not current.ai_controlled:
		return
	var planned: BattleAction = intents.get(current)
	if not intent_still_valid(planned):
		planned = BattleAI.choose(self, current)
	submit(planned)


func intent_of(u: Combatant) -> BattleAction:
	return intents.get(u)


## True if a planned action can still be carried out as shown. Single-target
## attacks also re-plan when someone starts taunting.
func intent_still_valid(a: BattleAction) -> bool:
	if a == null or not a.actor.is_alive():
		return false
	if a.type != BattleAction.Type.SKILL:
		return true
	if not a.actor.can_afford(a.skill):
		return false
	if a.skill.is_single_target():
		var legal := valid_targets(a.actor, a.skill)
		if a.target == null or not legal.has(a.target):
			return false
		if a.skill.targets_enemies() and not a.target.has_status(&"taunt"):
			for t in legal:
				if t.has_status(&"taunt"):
					return false
			# Easily distracted: turns on whoever just hit it.
			var la := a.actor.last_attacker
			if a.actor.has_trait(&"easily_distracted") and la and la != a.target and legal.has(la):
				return false
	elif valid_targets(a.actor, a.skill).is_empty():
		return false
	return true


func _plan_intents() -> void:
	intents.clear()
	for u in living(party) + living(enemies):
		if u.ai_controlled:
			intents[u] = BattleAI.choose(self, u)
	intents_changed.emit()


func _refresh_intents() -> void:
	for u in intents.keys():
		if not u.is_alive():
			intents.erase(u)
		elif not intent_still_valid(intents[u]):
			intents[u] = BattleAI.choose(self, u)
	intents_changed.emit()


## Queue of units still to act this round (current first).
func turn_order_preview() -> Array[Combatant]:
	var out: Array[Combatant] = []
	if current and current.is_alive():
		out.append(current)
	for u in _queue:
		if u.is_alive():
			out.append(u)
	return out


# =========================================================
# Targeting
# =========================================================

func allies_of(u: Combatant) -> Array[Combatant]:
	return party if u.side == Combatant.Side.PARTY else enemies


func opponents_of(u: Combatant) -> Array[Combatant]:
	return enemies if u.side == Combatant.Side.PARTY else party


static func living(units: Array[Combatant]) -> Array[Combatant]:
	var out: Array[Combatant] = []
	for u in units:
		if u.is_alive():
			out.append(u)
	return out


## True if `target` is in the back row and shielded by a living front row.
func is_protected(target: Combatant) -> bool:
	if target.row != Combatant.Row.BACK:
		return false
	for ally in allies_of(target):
		if ally.is_alive() and ally.row == Combatant.Row.FRONT:
			return true
	return false


func valid_targets(actor: Combatant, skill: SkillDef) -> Array[Combatant]:
	match skill.targeting:
		SkillDef.Targeting.SELF:
			return [actor] as Array[Combatant]
		SkillDef.Targeting.ALLY_SINGLE, SkillDef.Targeting.ALLY_ALL:
			var allies := living(allies_of(actor))
			if skill.effect == SkillDef.Effect.GUARD:
				allies.erase(actor)   # you can't guard yourself
			return allies
		_:
			var out: Array[Combatant] = []
			for t in living(opponents_of(actor)):
				var blocked := skill.damage_type == SkillDef.DamageType.MELEE \
					and not skill.ignores_row and is_protected(t)
				if not blocked:
					out.append(t)
			return out


# =========================================================
# Resolving actions
# =========================================================

## Execute an action for the current unit. Returns false if it was invalid
## (wrong actor, not enough MP, bad target) — nothing happens in that case.
func submit(action: BattleAction) -> bool:
	if is_over() or action == null or action.actor != current:
		return false

	var result := {
		"actor": current, "type": action.type, "skill": action.skill,
		"entries": [], "text": "",
	}

	match action.type:
		BattleAction.Type.SKILL:
			if not _resolve_skill(action, result):
				return false
		BattleAction.Type.DEFEND:
			current.add_status(&"defend", 1)
			result.text = "%s defends." % current.display_name
		BattleAction.Type.SWAP_ROW:
			current.row = Combatant.Row.BACK if current.row == Combatant.Row.FRONT else Combatant.Row.FRONT
			if current.source_character:
				current.source_character.battle_row = current.row
			result.text = "%s moves to the %s row." % [current.display_name, current.row_name().to_lower()]
		BattleAction.Type.ITEM:
			if not _resolve_item(action, result):
				return false
		BattleAction.Type.FLEE:
			if not can_flee:
				return false
			if rng.randf() < flee_chance():
				result.text = "The party escapes!"
				action_resolved.emit(result)
				_end(Outcome.FLED)
				return true
			result.text = "Couldn't escape!"

	intents.erase(action.actor)
	action_resolved.emit(result)
	if not _check_end():
		_refresh_intents()
		_next_turn()
	return true


func _resolve_item(action: BattleAction, result: Dictionary) -> bool:
	var item := action.item
	var t := action.target
	if inventory == null or item == null or inventory.count(item.id) <= 0:
		return false
	if item.scan:
		return _resolve_scan(action, result)
	if t == null or t.side != action.actor.side:
		return false
	if item.is_revive():
		if not t.revive(roundi(t.max_hp * item.revive_hp_pct)):
			return false
		inventory.remove(item.id)
		result.entries.append({ "target": t, "kind": "heal", "amount": t.hp, "crit": false, "killed": false })
		result.text = "%s uses a %s: %s is revived with %d HP!" % [action.actor.display_name,
			item.display_name, t.display_name, t.hp]
		return true
	if not t.is_alive():
		return false
	inventory.remove(item.id)
	var healed := t.restore_hp(item.heal_hp)
	var mp_gain := mini(item.restore_mp, t.max_mp - t.mp)
	t.mp += mp_gain
	var entry := { "target": t, "kind": "heal", "amount": healed, "crit": false, "killed": false }
	result.entries.append(entry)
	var parts: PackedStringArray = []
	if item.heal_hp > 0:
		parts.append("%d HP" % healed)
	if item.restore_mp > 0:
		parts.append("%d MP" % mp_gain)
	result.text = "%s uses a %s on %s: +%s." % [action.actor.display_name, item.display_name,
		t.display_name, ", +".join(parts)]
	return true


## Scouting Lens: reveals one living enemy's affinities and traits for good.
func _resolve_scan(action: BattleAction, result: Dictionary) -> bool:
	var t := action.target
	if t == null or t.side == action.actor.side or not t.is_alive() or t.source_enemy == null:
		return false
	inventory.remove(action.item.id)
	if bestiary == null:
		bestiary = Bestiary.new()
	bestiary.scan(t.source_enemy)
	result.entries.append({ "target": t, "kind": "scan", "amount": 0, "crit": false, "killed": false })
	var found := bestiary.summary(t.source_enemy)
	var trait_names: PackedStringArray = []
	for tr in t.traits:
		trait_names.append(EnemyFamilies.trait_name(tr))
	result.text = "%s studies %s through a %s: %s%s." % [action.actor.display_name, t.display_name,
		action.item.display_name, found if found != "" else "no weaknesses or resistances",
		(" · Traits: " + ", ".join(trait_names)) if not trait_names.is_empty() else ""]
	return true


## Copies HP/MP back onto the party's CharacterData so it carries over.
func write_back_party() -> void:
	for u in party:
		if u.source_character:
			u.source_character.set_current_hp(u.hp)
			u.source_character.set_current_mp(u.mp)


func flee_chance() -> float:
	var diff := _avg_agility(party) - _avg_agility(enemies)
	return clampf(FLEE_BASE + diff * FLEE_PER_AGI_DIFF, 0.1, 0.9)


func _resolve_skill(action: BattleAction, result: Dictionary) -> bool:
	var skill := action.skill
	var actor := action.actor
	if skill == null or not actor.can_afford(skill):
		return false

	var legal := valid_targets(actor, skill)
	var targets: Array[Combatant] = []
	if skill.is_single_target():
		if action.target == null or not legal.has(action.target):
			return false
		targets.append(action.target)
	else:
		targets = legal
	if targets.is_empty():
		return false

	actor.mp -= skill.mp_cost
	var parts: PackedStringArray = []

	for target in targets:
		var t: Combatant = target
		var entry := { "target": t, "kind": "", "amount": 0, "crit": false, "killed": false,
			"weak": false, "resisted": false, "staggered": false }
		match skill.effect:
			SkillDef.Effect.DAMAGE:
				# Guard: single-target hits on a guarded unit land on the guardian instead.
				var guardian := t.active_guardian()
				if skill.is_single_target() and guardian and guardian != t:
					parts.append("%s guards %s" % [guardian.display_name, t.display_name])
					t = guardian
					entry.target = t
				var roll := DamageCalc.roll_damage(actor, t, skill, rng)
				if roll.miss:
					entry.kind = "miss"
					parts.append("%s dodges" % t.display_name)
				else:
					_learn(t, roll.hit)
					if roll.absorbed:
						entry.kind = "absorb"
						entry.amount = t.restore_hp(roll.amount)
						parts.append("%s absorbs it and recovers %d HP" % [t.display_name, entry.amount])
					elif roll.immune:
						entry.kind = "immune"
						parts.append("%s is immune" % t.display_name)
					else:
						entry.kind = "damage"
						entry.amount = t.take_damage(roll.amount)
						entry.crit = roll.crit
						entry.weak = roll.weak
						entry.resisted = roll.resisted
						entry.killed = not t.is_alive()
						t.last_attacker = actor
						entry.staggered = roll.weak and t.add_stagger()
						if entry.staggered:
							intents.erase(t)
						parts.append("%s takes %d%s%s%s%s" % [t.display_name, entry.amount,
							" (WEAK)" if roll.weak else (" (resisted)" if roll.resisted else ""),
							" (CRIT)" if roll.crit else "", " and falls" if entry.killed else "",
							" and is STAGGERED" if entry.staggered else ""])
			SkillDef.Effect.HEAL:
				entry.kind = "heal"
				entry.amount = t.restore_hp(DamageCalc.roll_heal(actor, skill, rng, t))
				parts.append("%s recovers %d HP" % [t.display_name, entry.amount])
			SkillDef.Effect.RESTORE_MP:
				entry.kind = "mp"
				var gain := mini(roundi(t.max_mp * skill.power), t.max_mp - t.mp)
				t.mp += gain
				entry.amount = gain
				parts.append("%s recovers %d MP" % [t.display_name, gain])
			SkillDef.Effect.GUARD:
				entry.kind = "status"
				t.guarded_by = actor
				actor.add_status(&"guarding", 1)
				parts.append("%s will take hits for %s" % [actor.display_name, t.display_name])
			SkillDef.Effect.STATUS:
				entry.kind = "status"
				var turns := skill.status_turns
				# Easily distracted enemies fall for a Taunt for a turn longer.
				if skill.status_id == &"taunt" and living(opponents_of(actor)).any(
						func(o): return o.has_trait(&"easily_distracted")):
					turns += 1
				t.add_status(skill.status_id, turns)
				parts.append("%s gains %s" % [t.display_name, String(skill.status_id)])
		result.entries.append(entry)

	result.text = "%s uses %s: %s." % [actor.display_name, skill.display_name, ", ".join(parts)]
	return true


## Writes what a hit revealed (element -> affinity) into the bestiary.
func _learn(t: Combatant, hit: Dictionary) -> void:
	if bestiary == null or t.source_enemy == null:
		return
	for e in hit:
		bestiary.record_affinity(t.source_enemy, e, hit[e])


# =========================================================
# Turn flow
# =========================================================

func _next_turn() -> void:
	current = null
	while current == null:
		if _queue.is_empty():
			_start_round()
		var next: Combatant = _queue.pop_front()
		if next.is_alive() and next.staggered:
			# Staggered: loses this turn (and whatever it was planning).
			next.staggered = false
			next.tick_statuses()
			intents.erase(next)
			action_resolved.emit({ "actor": next, "type": BattleAction.Type.DEFEND, "skill": null,
				"entries": [{ "target": next, "kind": "staggered", "amount": 0, "crit": false, "killed": false }],
				"text": "%s is staggered and loses its turn!" % next.display_name })
			continue
		if next.is_alive():
			current = next
	current.tick_statuses()
	turn_started.emit(current)


func _start_round() -> void:
	round_number += 1
	var rolls := {}
	var units: Array[Combatant] = living(party)
	units.append_array(living(enemies))
	for u in units:
		u.gel_used = false
		var agi := float(u.stats.turn_priority())
		rolls[u] = agi * rng.randf_range(1.0 - INITIATIVE_SPREAD, 1.0 + INITIATIVE_SPREAD) + rng.randf() * 0.01
		if u.has_status(&"haste"):
			rolls[u] *= DamageCalc.HASTE_INITIATIVE_MULT
	units.sort_custom(func(a, b): return rolls[a] > rolls[b])
	_queue = units
	round_started.emit(round_number)
	_plan_intents()


func _check_end() -> bool:
	if living(enemies).is_empty():
		for e in enemies:
			if bestiary:
				bestiary.record_defeat(e.source_enemy)
			rewards.xp += e.source_enemy.xp_reward
			rewards.gold += e.source_enemy.gold_reward
			var loot := LootTable.roll_enemy_loot(e.source_enemy, party_luck(), loot_level, rng,
				party_classes(), owned_unique_classes)
			rewards.gear.append_array(loot)
			for g in loot:   # don't hand out the same Unique twice in one fight
				if g.rarity == Rarity.Tier.UNIQUE:
					owned_unique_classes.append(g.class_lock)
			var book := SkillBooks.roll_book_drop(e.source_enemy, party_luck(), rng)
			if book != &"":
				rewards.books.append(book)
			for drop in e.source_enemy.drops:
				if rng.randf() < drop.get("chance", 1.0):
					var id: StringName = drop.item
					rewards.items[id] = rewards.items.get(id, 0) + drop.get("count", 1)
		_end(Outcome.VICTORY)
		return true
	if living(party).is_empty():
		_end(Outcome.DEFEAT)
		return true
	return false


func _end(result: int) -> void:
	outcome = result
	current = null
	battle_ended.emit(result)


## Gives XP to every surviving party member and gold to the leader.
func apply_rewards() -> void:
	if outcome != Outcome.VICTORY:
		return
	for u in party:
		if u.is_alive() and u.source_character:
			u.source_character.add_xp(rewards.xp)
	if not party.is_empty() and party[0].source_character:
		party[0].source_character.gold += rewards.gold
	if inventory:
		for id in rewards.items:
			inventory.add(id, rewards.items[id])
		for sid in rewards.books:
			inventory.add(SkillBooks.book_item_id(sid))
		for g in rewards.gear:
			inventory.add_gear(g)


## Loot luck = the highest Luck among conscious party members.
func party_luck() -> int:
	var best := 0
	for u in living(party):
		best = maxi(best, u.stats.get_total(Stats.Type.LUCK))
	return best


func party_classes() -> Array:
	var out := []
	for u in party:
		if u.source_character and u.source_character.class_id != &"":
			out.append(u.source_character.class_id)
	return out


func _avg_agility(units: Array[Combatant]) -> float:
	var alive := living(units)
	if alive.is_empty():
		return 0.0
	var sum := 0.0
	for u in alive:
		sum += u.stats.get_total(Stats.Type.AGILITY)
	return sum / alive.size()


func _dedupe_enemy_names() -> void:
	var counts := {}
	for e in enemies:
		counts[e.display_name] = counts.get(e.display_name, 0) + 1
	var seen := {}
	for e in enemies:
		if counts[e.display_name] > 1:
			var base_name := e.display_name
			seen[base_name] = seen.get(base_name, 0) + 1
			e.display_name = "%s %s" % [base_name, char(64 + seen[base_name])]
