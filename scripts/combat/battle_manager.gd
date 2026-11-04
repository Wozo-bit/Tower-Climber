class_name BattleManager
extends RefCounted
## Turn-based battle logic, FF-style with front/back rows. No UI, no awaits:
## the UI (or a test) drives it by calling advance() for AI turns and
## submit() for player turns, and listens to the signals.
##
## ROW RULES (4 rows: Front, Middle, Rear, Back)
## - Single-target melee only reaches the nearest row that still has someone
##   standing: a Middle unit is safe while its Front row lives, and so on
##   (unless the skill ignores rows, e.g. Backstab).
## - Melee made FROM further back deals less (DamageCalc.MELEE_ROW_MULT:
##   100% / 90% / 70% / 50%).
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
## A summoned unit joined the field (the UI adds its card).
signal unit_joined(unit: Combatant)

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
## Extra HP for bosses, minibosses and roamers (set from the party size:
## GameState.guardian_hp_mult). They fight a whole party on their own.
var boss_hp_mult := 1.0
## A god's faith for miracles ({ "faith": n }; empty = no god in this fight).
## The player's unit gets the miracle skills. Written back after the fight.
var faith_box: Dictionary = {}
## The Lone Climber (solo clear) fighting alone: hits harder, takes less.
var lone_climber := false
## "X and Y fight as one!" lines for the log (bonds formed at setup).
var start_lines: Array[String] = []
## HP for everyone else (GameState.normal_hp_mult, from the party size).
var normal_hp_mult := 1.0
## Where element discoveries are written (GameState.bestiary). Optional.
var bestiary: Bestiary
## Gold actually paid to the leader by apply_rewards (after blessings), for taxes.
var gold_given := 0
## Difficulty / floor knobs (GameState.configure_battle sets them). Set BEFORE setup().
## enemy_skill_mult: how often enemies use skills; xp_mult / gold_mult: rewards.
var enemy_skill_mult := 1.0
var xp_mult := 1.0
var gold_mult := 1.0

## Pressure on your back rows (Hayden 2026-11-04: a mage in the back was never
## touched). The chance a melee enemy leaps past the front line on its turn;
## above 0 also makes enemies aim (BattleAI._pick_target) and gives non-casters
## some magic defense. GameState sets it by floor. Set BEFORE setup().
var flank_chance := 0.0
const ENEMY_MAGIC_GUARD := 0.5   # Intelligence of at least this share of Stamina

## This floor's twist (FloorMods id). Set BEFORE setup().
var floor_mod: StringName = &""
## Items work in this fight? (Silent Floor)
var items_allowed := true
## Late bosses (Hayden 2026-11-04): 0 = none, 1 = one mechanic, 2 = two.
## Minibosses at tier 1+ only enrage. Set BEFORE setup().
var boss_tier := 0
var boss_is_miniboss := false
## Who a summoning boss calls (normal enemies of its stage).
var reinforcements: Array[EnemyDef] = []
const BOSS_MECHANICS: Array[String] = ["summon", "shield", "charge"]
const BOSS_PHASE_AT := { 1: [0.5], 2: [0.6, 0.3], 3: [0.75, 0.5, 0.25] }
const BOSS_ENRAGE_DEALT := 1.1
const BOSS_SHIELD_ROUNDS := 3
const BOSS_CHARGE_EVERY := 3
## Late floors: enemies learn the party's favourite skills. Shared with
## GameState.floor_skill_uses so it lasts the whole floor. null = off.
var adapt_uses = null
const ADAPT_FREE_USES := 5
const ADAPT_STEP := 0.1
const ADAPT_FLOOR := 0.5

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
		var pu := Combatant.from_character(c)
		if not faith_box.is_empty() and c == GameState.player:
			pu.faith_box = faith_box
			for id in DivinityState.MIRACLES:
				pu.skills.append(SkillLibrary.get_skill(id))
		party.append(pu)
	# Demigods who know each other fight better side by side.
	var ids := party.map(func(u): return u.source_character.companion_id if u.source_character else &"")
	for bond in NpcLibrary.bonds_among(ids):
		for u in party:
			if u.source_character and bond.pair.has(u.source_character.companion_id):
				u.damage_dealt_mult *= NpcLibrary.BOND_DEALT
		start_lines.append(bond.line)
	if lone_climber and party.size() == 1:
		party[0].damage_dealt_mult *= GameState.LONE_DEALT
		party[0].damage_taken_mult *= GameState.LONE_TAKEN
		start_lines.append("%s fights alone, as always." % party[0].display_name)
	for e in enemy_defs:
		var u := Combatant.from_enemy(e, enemy_scale)
		var hp_mult := boss_hp_mult if e.is_boss or e.is_roaming else normal_hp_mult
		if hp_mult != 1.0:
			u.max_hp = maxi(1, roundi(u.max_hp * hp_mult))
			u.hp = u.max_hp
		u.skill_chance = clampf(u.skill_chance * enemy_skill_mult, 0.0, 1.0)
		enemies.append(u)
		if bestiary:
			bestiary.record_seen(e)
	_dedupe_enemy_names()
	for e in enemies:
		if e.source_enemy.is_boss:
			can_flee = false
	if flank_chance > 0.0:
		for e in enemies:
			var guard := roundi(e.stats.get_base(Stats.Type.STAMINA) * ENEMY_MAGIC_GUARD)
			e.stats.base[Stats.Type.INTELLIGENCE] = maxi(e.stats.get_base(Stats.Type.INTELLIGENCE), guard)
	_apply_floor_mod()
	_setup_boss_mechanics()
	_setup_late_traits()


func _apply_floor_mod() -> void:
	var m := FloorMods.get_mod(floor_mod)
	if m.is_empty():
		return
	start_lines.append("%s: %s" % [m.name, m.desc])
	items_allowed = not m.get("no_items", false)
	for u in party + enemies:
		u.magic_dealt_mult *= m.get("magic", 1.0)
		u.damage_dealt_mult *= m.get("dealt", 1.0)
	for e in enemies:
		e.damage_dealt_mult *= m.get("enemy_dealt", 1.0)
		var hp_mult: float = m.get("enemy_hp", 1.0)
		e.max_hp = maxi(1, roundi(e.max_hp * hp_mult))
		e.hp = e.max_hp
	xp_mult *= m.get("xp", 1.0)
	gold_mult *= m.get("gold", 1.0)


## The Unfinished: a new weakness and resistance every fight. Echoes: they take
## up to ECHO_SKILLS damage skills from someone in your party.
const ECHO_SKILLS := 3


func _setup_late_traits() -> void:
	for e in enemies:
		if e.has_trait(&"glitched"):
			var types: Array = Element.Type.values()
			var weak: int = types[rng.randi_range(0, types.size() - 1)]
			var resist: int = types[rng.randi_range(0, types.size() - 1)]
			while resist == weak:
				resist = types[rng.randi_range(0, types.size() - 1)]
			e.affinities = { weak: Element.Affinity.WEAK, resist: Element.Affinity.RESIST }
		if e.has_trait(&"echoing") and not party.is_empty():
			var source: Combatant = party[rng.randi_range(0, party.size() - 1)]
			var options := source.skills.filter(func(s): return s.effect == SkillDef.Effect.DAMAGE)
			for i in mini(ECHO_SKILLS, options.size()):
				var pick: SkillDef = options.pop_at(rng.randi_range(0, options.size() - 1))
				if not e.skills.any(func(s): return s.id == pick.id):
					e.skills.append(pick)
			e.max_mp = maxi(e.max_mp, 999)
			e.mp = e.max_mp


## Who a lunging enemy leaps at: a taunter first (Taunt and Guard still protect
## your back rows), else someone behind the front line. null = nobody's there.
func flank_target() -> Combatant:
	var back: Array[Combatant] = []
	for t in living(party):
		if t.has_status(&"taunt"):
			return t
		if is_protected(t):
			back.append(t)
	return back[rng.randi_range(0, back.size() - 1)] if not back.is_empty() else null


## The boss's mechanics follow from its id, so a boss always plays the same.
func _setup_boss_mechanics() -> void:
	if boss_tier <= 0:
		return
	for e in enemies:
		if not e.source_enemy.is_boss:
			continue
		if boss_is_miniboss:
			e.mechanics = ["enrage"]
			continue
		var start := absi(String(e.source_enemy.id).hash()) % BOSS_MECHANICS.size()
		for i in mini(boss_tier, BOSS_MECHANICS.size()):
			e.mechanics.append(BOSS_MECHANICS[(start + i) % BOSS_MECHANICS.size()])
		break   # only the leader


## Bosses crossing an HP mark enrage and start their next mechanic.
## Returns the line for the log ("" = nothing happened).
func _check_boss_phases() -> String:
	var lines: PackedStringArray = []
	for u in enemies:
		if u.mechanics.is_empty() or not u.is_alive() or u.phase >= u.mechanics.size():
			continue
		var marks: Array = BOSS_PHASE_AT.get(u.mechanics.size(), [0.5])
		if float(u.hp) / u.max_hp > marks[u.phase]:
			continue
		var mech: String = u.mechanics[u.phase]
		u.phase += 1
		u.damage_dealt_mult *= BOSS_ENRAGE_DEALT
		match mech:
			"enrage":
				lines.append("%s flies into a rage!" % u.display_name)
			"summon":
				lines.append("%s calls for help!" % u.display_name)
				for def in reinforcements.slice(0, 2):
					var r := Combatant.from_enemy(def, enemy_scale)
					r.side = Combatant.Side.ENEMY
					r.max_hp = maxi(1, roundi(r.max_hp * normal_hp_mult))
					r.hp = r.max_hp
					enemies.append(r)
					unit_joined.emit(r)
				_dedupe_enemy_names()
			"shield":
				u.shielded = true
				u.shield_rounds = BOSS_SHIELD_ROUNDS
				lines.append("%s raises a barrier! Only a weakness will break it." % u.display_name)
			"charge":
				lines.append("%s begins to draw in power. Watch for the blast!" % u.display_name)
	return " ".join(lines)


## Bosses that charge: gather for a round (the intent shows it), then blast.
func _tick_boss_mechanics() -> void:
	for u in enemies:
		if not u.is_alive():
			continue
		if u.shielded:
			u.shield_rounds -= 1
			if u.shield_rounds <= 0:
				u.shielded = false
		if not (u.phase > 0 and u.mechanics.slice(0, u.phase).has("charge")):
			continue
		if u.charge_state == 1:
			u.charge_state = 2
		elif round_number % BOSS_CHARGE_EVERY == 0:
			u.charge_state = 1
			action_resolved.emit({ "actor": u, "type": BattleAction.Type.DEFEND, "skill": null, "entries": [],
				"text": "%s is gathering power! Defend or shield the party." % u.display_name })
		else:
			u.charge_state = 0


## How much of its damage this party member's skill still does on a late floor.
func adapt_mult(actor: Combatant, skill: SkillDef) -> float:
	if adapt_uses == null or actor.side != Combatant.Side.PARTY or skill == actor.basic_attack:
		return 1.0
	var over: int = adapt_uses.get(_adapt_key(actor, skill), 0) - ADAPT_FREE_USES
	return maxf(ADAPT_FLOOR, 1.0 - ADAPT_STEP * maxi(0, over))


func _adapt_key(actor: Combatant, skill: SkillDef) -> String:
	return "%s:%s" % [actor.display_name, skill.id]


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


## True if someone on `target`'s side stands in a row in front of it.
func is_protected(target: Combatant) -> bool:
	for ally in allies_of(target):
		if ally.is_alive() and ally.row < target.row:
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
			# A chosen row (action.row), else the next one back (wrapping to the front).
			var to := action.row if action.row >= 0 else (current.row + 1) % Combatant.Row.size()
			if to == current.row or to < 0 or to >= Combatant.Row.size():
				return false
			current.row = to
			if current.source_character:
				current.source_character.battle_row = current.row
			result.text = "%s moves to the %s row." % [current.display_name, current.row_name().to_lower()]
		BattleAction.Type.ITEM:
			if not items_allowed:
				result.text = "Nothing from the bag works here."
			elif not _resolve_item(action, result):
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
	if not faith_box.is_empty():
		GameState.divinity.faith = maxi(0, faith_box.get("faith", 0))


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
	if skill.faith_cost > 0:
		actor.faith_box["faith"] = actor.faith_box.get("faith", 0) - skill.faith_cost
	var parts: PackedStringArray = []
	var adapt := adapt_mult(actor, skill) if skill.effect == SkillDef.Effect.DAMAGE else 1.0
	if adapt < 1.0:
		parts.append("the enemy has learned this move")
	if adapt_uses != null and skill.effect == SkillDef.Effect.DAMAGE and actor.side == Combatant.Side.PARTY and skill != actor.basic_attack:
		adapt_uses[_adapt_key(actor, skill)] = adapt_uses.get(_adapt_key(actor, skill), 0) + 1
	if skill.id == SkillLibrary.BOSS_UNLEASH:
		actor.charge_state = 0
	if actor.has_trait(&"swarming"):
		actor.swarm_allies = living(allies_of(actor)).filter(func(u): return u != actor and u.has_trait(&"swarming")).size()

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
						var amount: int = maxi(1, roundi(roll.amount * adapt))
						if t.shielded and roll.weak:
							t.shielded = false
							parts.append("the barrier shatters")
						# Undying: shrugs off one killing blow (Holy and Fire put it down for good).
						if amount >= t.hp and t.has_trait(&"undying") and not t.undying_used \
								and not roll.elements.any(func(e): return e in [Element.Type.HOLY, Element.Type.FIRE]):
							amount = t.hp - 1
							t.undying_used = true
							parts.append("%s refuses to die" % t.display_name)
						entry.amount = t.take_damage(amount)
						entry.crit = roll.crit
						entry.weak = roll.weak
						entry.resisted = roll.resisted
						entry.killed = not t.is_alive()
						t.last_attacker = actor
						# Only enemies stagger (a cursed weakness costs the party damage, not turns).
						entry.staggered = roll.weak and t.side == Combatant.Side.ENEMY and t.add_stagger()
						for i in skill.stagger_bonus:
							if t.side == Combatant.Side.ENEMY and t.add_stagger():
								entry.staggered = true
						if skill.lifesteal > 0.0 and entry.amount > 0 and actor.is_alive():
							var drained := actor.restore_hp(maxi(1, roundi(entry.amount * skill.lifesteal)))
							if drained > 0:
								parts.append("%s drains %d HP" % [actor.display_name, drained])
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
				_apply_riders(t, skill, parts)
			SkillDef.Effect.RESTORE_MP:
				entry.kind = "mp"
				var gain := mini(roundi(t.max_mp * skill.power), t.max_mp - t.mp)
				t.mp += gain
				entry.amount = gain
				parts.append("%s recovers %d MP" % [t.display_name, gain])
			SkillDef.Effect.GUARD:
				entry.kind = "status"
				t.guarded_by = actor
				actor.add_status(&"guarding", 1, skill.status_bonus)
				parts.append("%s will take hits for %s" % [actor.display_name, t.display_name])
			SkillDef.Effect.SUMMON:
				entry.kind = "status"
				var summoned := _summon(actor, skill.summon_id)
				parts.append("%s answers the call" % summoned.display_name if summoned else "nothing answers")
				if skill.also_status != &"":
					actor.add_status(skill.also_status, skill.also_turns)
			SkillDef.Effect.STATUS:
				entry.kind = "status"
				var turns := skill.status_turns
				# Easily distracted enemies fall for a Taunt for a turn longer.
				if skill.status_id == &"taunt" and living(opponents_of(actor)).any(
						func(o): return o.has_trait(&"easily_distracted")):
					turns += 1
				t.add_status(skill.status_id, turns, skill.status_bonus)
				parts.append("%s gains %s" % [t.display_name, String(skill.status_id)])
				if skill.also_status != &"":
					t.add_status(skill.also_status, skill.also_turns, skill.status_bonus)
					parts.append("and %s" % String(skill.also_status))
				_apply_riders(t, skill, parts)
		result.entries.append(entry)

	result.text = "%s uses %s: %s." % [actor.display_name, skill.display_name, ", ".join(parts)]
	var phase_line := _check_boss_phases()
	if phase_line != "":
		result.text += " " + phase_line
	return true


## STATUS / HEAL riders: a little HP or MP on top.
func _apply_riders(t: Combatant, skill: SkillDef, parts: PackedStringArray) -> void:
	if skill.rider_heal_pct > 0.0:
		var got := t.restore_hp(maxi(1, roundi(t.max_hp * skill.rider_heal_pct)))
		if got > 0:
			parts.append("%s recovers %d HP" % [t.display_name, got])
	if skill.rider_mp_pct > 0.0:
		var gain := mini(maxi(1, roundi(t.max_mp * skill.rider_mp_pct)), t.max_mp - t.mp)
		t.mp += gain
		if gain > 0:
			parts.append("%s recovers %d MP" % [t.display_name, gain])


## Calls a summon to `actor`'s side for the rest of the fight. One per
## summoner: calling again refreshes the one already there. Its strength
## follows the summoner's Intelligence. Acts from the next round on.
const SUMMON_INT_PER_SCALE := 18.0


func _summon(actor: Combatant, summon_id: StringName) -> Combatant:
	var def := EnemyLibrary.get_enemy_or_null(summon_id)
	if def == null:
		return null
	var side := party if actor.side == Combatant.Side.PARTY else enemies
	for u in side:
		if u.summoned_by == actor and u.is_alive():
			u.hp = u.max_hp
			return u
	var scale := maxf(0.3, actor.stats.get_total(Stats.Type.INTELLIGENCE) / SUMMON_INT_PER_SCALE)
	var u := Combatant.from_enemy(def, scale)
	u.side = actor.side
	u.summoned_by = actor
	side.append(u)
	unit_joined.emit(u)
	return u


## Writes what a hit revealed (element -> affinity) into the bestiary.
func _learn(t: Combatant, hit: Dictionary) -> void:
	if bestiary == null or t.source_enemy == null or t.has_trait(&"glitched"):
		return   # a glitched enemy's weaknesses only last the fight
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
	var regen: float = FloorMods.get_mod(floor_mod).get("mp_regen", 0.0)
	if regen > 0.0:
		for u in living(party):
			u.mp = mini(u.max_mp, u.mp + roundi(u.max_mp * regen))
	_tick_boss_mechanics()
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
			rewards.xp += roundi(e.source_enemy.xp_reward * xp_mult)
			rewards.gold += roundi(e.source_enemy.gold_reward * gold_mult)
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
			# Ordinary enemies sometimes carry a potion (healing between rest floors).
			if not e.source_enemy.is_boss and rng.randf() < LootTable.NORMAL_POTION_DROP:
				rewards.items[&"potion"] = rewards.items.get(&"potion", 0) + 1
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
## Blessings and curses can change both (each member's own "xp_mult", the
## leader's "gold_mult").
func apply_rewards() -> void:
	if outcome != Outcome.VICTORY:
		return
	for u in party:
		if u.is_alive() and u.source_character:
			u.source_character.add_xp(maxi(0, roundi(rewards.xp * (1.0 + u.source_character.effect_sum("xp_mult")))))
	if not party.is_empty() and party[0].source_character:
		var leader := party[0].source_character
		gold_given = maxi(0, roundi(rewards.gold * (1.0 + leader.effect_sum("gold_mult"))))
		leader.gold += gold_given
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


## Tier-1 classes in the party (Uniques are per tier-1 class, so a Pyromancer
## counts as a Mage).
func party_classes() -> Array:
	var out := []
	for u in party:
		if u.source_character and u.source_character.class_id != &"":
			out.append(ClassRegistry.root_of(u.source_character.class_id))
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
