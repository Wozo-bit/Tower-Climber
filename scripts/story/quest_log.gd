class_name QuestLog
extends RefCounted
## The player's quests for this run: active (with step progress), completed,
## failed, the one pinned to the HUD, and generated notice-board bounties.
## Lives in GameState.quests and is saved with the run.
##
## GameState calls in when things happen (a battle is won, a floor is entered,
## a flag is set) and update() moves quests along. Messages for the floor HUD
## ("Quest updated: Slimes 3/8") pile up in `messages` until the tower shows them.

## Generated bounties per rest-floor notice board.
const BOUNTIES_PER_BOARD := 3
## Bounty rewards per enemy asked for, at floor 1. They grow with the floor
## like battle rewards (about a fight and a half's worth for a typical job).
const BOUNTY_GOLD_PER_KILL := 12
const BOUNTY_XP_PER_KILL := 30

## id -> { "step": int, "progress": int }   (progress = defeat count on that step)
var active: Dictionary = {}
var completed: Array[StringName] = []
var failed: Array[StringName] = []
## Generated quests (notice-board bounties): id -> full quest definition.
var bounties: Dictionary = {}
## Shown on the floor HUD. &"" = none.
var pinned: StringName = &""
## Toasts waiting to be shown.
var messages: Array[String] = []

var _updating := false


# =========================================================
# Queries
# =========================================================

func def_of(id: StringName) -> Dictionary:
	if bounties.has(id):
		return bounties[id]
	if String(id).begins_with("rescue_"):   # a captured guild captain (GuildState)
		return GameState.guilds.rescue_quest_def(id)
	return QuestLibrary.get_quest(id)


func is_active(id: StringName) -> bool:
	return active.has(id)


func is_done(id: StringName) -> bool:
	return completed.has(id)


func is_failed(id: StringName) -> bool:
	return failed.has(id)


## Never started (so it can be offered).
func is_new(id: StringName) -> bool:
	return not (is_active(id) or is_done(id) or is_failed(id))


## Index of the step it's on (-1 if not active).
func step_index(id: StringName) -> int:
	return active[id].step if active.has(id) else -1


func current_step(id: StringName) -> Dictionary:
	var steps: Array = def_of(id).get("steps", [])
	var i := step_index(id)
	return steps[i] if i >= 0 and i < steps.size() else {}


## [have, need] for the step it's on.
func step_progress(id: StringName) -> Array:
	var goal: Dictionary = current_step(id).get("goal", {})
	var gs := GameState
	match goal.get("type", ""):
		"defeat":
			return [mini(active[id].progress, goal.count), goal.count]
		"collect":
			return [mini(gs.inventory.count(goal.item), goal.count), goal.count]
		"reach":
			return [1 if gs.floor_number >= goal.floor else 0, 1]
		"flag":
			return [1 if gs.has_flag(goal.flag) else 0, 1]
	return [0, 1]


func step_done(id: StringName) -> bool:
	var p := step_progress(id)
	return p[0] >= p[1]


## "Defeat slimes (3/8)" — the line shown in the log and on the HUD.
func step_text(id: StringName) -> String:
	var step := current_step(id)
	if step.is_empty():
		return ""
	var p := step_progress(id)
	return step.text + (" (%d/%d)" % p if p[1] > 1 else "")


# =========================================================
# Changing quests
# =========================================================

## Starts a quest. False if it doesn't exist or was already started.
func start(id: StringName) -> bool:
	if def_of(id).is_empty() or not is_new(id):
		return false
	active[id] = { "step": 0, "progress": 0 }
	messages.append("New quest: %s" % def_of(id).title)
	if pinned == &"":
		pinned = id
	update()
	return true


## Fails an active quest (a choice closed it off, or its deadline passed).
func fail(id: StringName, reason: String = "") -> bool:
	if not is_active(id):
		return false
	var q := def_of(id)
	active.erase(id)
	failed.append(id)
	if pinned == id:
		_repin()
	messages.append("Quest failed: %s%s" % [q.title, (" (%s)" % reason) if reason != "" else ""])
	if q.has("on_fail_flag"):
		GameState.set_flag(q.on_fail_flag)
	return true


## Moves every active quest along as far as it can go, starts main quests whose
## time has come, and fails expired ones. Safe to call any time.
func update() -> void:
	if _updating:
		return
	_updating = true
	for id in QuestLibrary.QUESTS:
		var q: Dictionary = QuestLibrary.QUESTS[id]
		if q.has("auto_start") and is_new(id) and DialogueRunner.check(q.auto_start):
			active[id] = { "step": 0, "progress": 0 }
			messages.append("New quest: %s" % q.title)
			if pinned == &"":
				pinned = id
	for id in active.keys():
		var q := def_of(id)
		if q.has("expires_after_floor") and GameState.floor_number > q.expires_after_floor:
			_updating = false
			fail(id, "too late")
			_updating = true
			continue
		while active.has(id) and step_done(id):
			_advance(id)
	_updating = false


func _advance(id: StringName) -> void:
	var q := def_of(id)
	active[id]["step"] = active[id]["step"] + 1
	active[id]["progress"] = 0
	if active[id].step >= q.steps.size():
		_complete(id)
	else:
		messages.append("Quest updated: %s — %s" % [q.title, step_text(id)])


func _complete(id: StringName) -> void:
	var q := def_of(id)
	active.erase(id)
	completed.append(id)
	if pinned == id:
		_repin()
	var got := give_rewards(q.get("rewards", {}))
	messages.append("Quest complete: %s%s" % [q.title, (" — " + got) if got != "" else ""])
	if q.has("on_complete_flag"):
		GameState.set_flag(q.on_complete_flag)


func _repin() -> void:
	pinned = &""
	for id in active:
		pinned = id
		break


func pin(id: StringName) -> void:
	if is_active(id):
		pinned = id


## Hands out a quest's rewards. Returns a short "200 gold, 2 Advanced Potion" text.
func give_rewards(r: Dictionary) -> String:
	var gs := GameState
	var parts: PackedStringArray = []
	if r.get("gold", 0) > 0:
		gs.player.gold += r.gold
		parts.append("%d gold" % r.gold)
	if r.get("xp", 0) > 0:
		for m in gs.battle_party():
			m.add_xp(r.xp)
		parts.append("%d XP" % r.xp)
	for item in r.get("items", {}):
		gs.inventory.add(item, r.items[item])
		parts.append("%s x%d" % [ItemLibrary.get_item(item).display_name, r.items[item]])
	if r.has("gear"):
		var g := make_quest_gear(r.gear)
		gs.inventory.add_gear(g)
		parts.append(g.display_name)
	for f in r.get("flags", []):
		gs.set_flag(f)
	for route_id in r.get("route_points", {}):   # never shown as numbers
		gs.add_route_points(route_id, r.route_points[route_id])
	for guild in r.get("guild_rep", {}):
		gs.guilds.add_rep(guild, r.guild_rep[guild])
		parts.append("%+d with %s" % [r.guild_rep[guild], GuildLibrary.guild_name(guild)])
	if r.has("unlock_personal"):   # a recruit's loyalty quest: their own skill
		for c in gs.companions + gs.reserve + gs.waiting + gs.guilds.captains.values():
			if c.companion_id == r.unlock_personal and c.personal_skill != &"":
				c.personal_unlocked = true
				parts.append("%s learned %s" % [c.character_name, SkillLibrary.get_skill(c.personal_skill).display_name])
	if r.has("reveal_family"):
		for def in EnemyLibrary.all():
			if def.family == r.reveal_family:
				gs.bestiary.scan(def)
		parts.append("notes on %s" % EnemyFamilies.family_name(r.reveal_family))
	return ", ".join(parts)


## Quest gear: fixed stats, marked quest_reward (earned again each run, never NG+).
static func make_quest_gear(spec: Dictionary) -> GearItem:
	var base: Dictionary = LootTable.BASES[spec.base]
	var g := GearItem.new()
	g.base_id = spec.base
	g.slot = base.slot
	g.rarity = spec.get("rarity", Rarity.Tier.UNCOMMON)
	g.display_name = spec.get("name", base.name)
	g.description = spec.get("desc", "")
	g.bonuses = spec.get("bonuses", {}).duplicate()
	g.item_level = GameState.floor_number
	g.quest_reward = true
	return g


# =========================================================
# Events from GameState
# =========================================================

## After a won battle: counts defeats and rolls quest-item drops.
func on_battle_won(defs: Array, rng: RandomNumberGenerator) -> void:
	for id in active.keys():
		var goal: Dictionary = current_step(id).get("goal", {})
		if goal.get("type") == "defeat":
			var before: int = active[id].progress
			for def: EnemyDef in defs:
				if matches(goal, def):
					active[id]["progress"] = active[id]["progress"] + 1
			if active[id].progress > before and active[id].progress < goal.count:
				messages.append("Quest updated: %s — %s" % [def_of(id).title, step_text(id)])
		elif goal.get("type") == "collect":
			for d in def_of(id).get("drops", []):
				if d.item != goal.item or GameState.inventory.count(goal.item) >= goal.count:
					continue
				for def: EnemyDef in defs:
					var fits: bool = (d.has("family") and def.family == d.family) or (d.has("enemy") and def.id == d.enemy)
					if fits and rng.randf() < d.get("chance", 1.0) and GameState.inventory.add(d.item) > 0:
						messages.append("Found a %s! (%s)" % [ItemLibrary.get_item(d.item).display_name, step_text(id)])
	update()


## Does a defeat goal count this enemy?
static func matches(goal: Dictionary, def: EnemyDef) -> bool:
	if goal.get("any", false):
		return true
	if goal.has("enemy"):
		return def.id == goal.enemy
	if goal.has("family"):
		return def.family == goal.family
	if goal.has("kind"):
		return SkillBooks.enemy_kind(def) == goal.kind
	return false


# =========================================================
# Notice board
# =========================================================

## What the board on rest floor `floor_n` offers: hand-written board quests that
## fit, plus BOUNTIES_PER_BOARD generated ones. Taken ones are left off.
## Returns [{ "id", "def" }].
func board_offers(floor_n: int) -> Array:
	var out := []
	for id in QuestLibrary.QUESTS:
		var q: Dictionary = QuestLibrary.QUESTS[id]
		if q.get("board", false) and is_new(id) and DialogueRunner.check(q.get("board_if", {})):
			out.append({ "id": id, "def": q })
	for i in BOUNTIES_PER_BOARD:
		var b := make_bounty(floor_n, i, GameState.player.legacy_id)
		if is_new(b.id) and not bounties.has(b.id):
			out.append(b)
	return out


## Takes a board offer: bounties are remembered (they're generated) and started.
func accept(offer: Dictionary) -> bool:
	if offer.def.get("kind") == "bounty":
		if bounties.has(offer.id):
			return false
		bounties[offer.id] = offer.def
	return start(offer.id)


## A generated bounty for the stage ahead. The first one on a board is for the
## stage's family ("Defeat 8 slimes"), the others for different enemies
## ("Defeat 5 Mud Slimes"). Same floor + same run = same bounties, so the
## board doesn't re-roll when you come back.
static func make_bounty(floor_n: int, index: int, run_key: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = ("%s:%d" % [run_key, floor_n]).hash()
	var theme := StageLibrary.stage_for_floor(floor_n + 1)
	var pool := []
	for group in theme.encounters:
		for e in group:
			if not pool.has(e):
				pool.append(e)
	pool.sort()
	for i in range(pool.size() - 1, 0, -1):   # this board's shuffle (seeded)
		var j := rng.randi_range(0, i)
		var tmp = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	var counts := [rng.randi_range(6, 10), rng.randi_range(3, 6), rng.randi_range(3, 6), rng.randi_range(3, 6)]
	var flavor_rolls := [rng.randf(), rng.randf(), rng.randf(), rng.randf()]   # one per board slot
	var goal := {}
	var label := ""
	if index == 0 and theme.has("family"):
		goal = { "type": "defeat", "family": theme.family, "count": counts[0] }
		label = EnemyFamilies.family_name(theme.family).to_lower()
	else:
		var target: StringName = pool[(index - 1 + pool.size()) % pool.size()]
		goal = { "type": "defeat", "enemy": target, "count": counts[mini(index, counts.size() - 1)] }
		label = EnemyLibrary.get_enemy(target).display_name + "s"
	var n: int = goal.count
	var id := StringName("bounty_%d_%d" % [floor_n, index])
	# Paid like battle rewards: they grow with the floor (GameState.reward_scale_for_floor).
	var scale := GameState.reward_scale_for_floor(floor_n + 1)
	var rewards := { "gold": roundi(n * BOUNTY_GOLD_PER_KILL * pow(scale, GameState.GOLD_REWARD_EXP)),
		"xp": roundi(n * BOUNTY_XP_PER_KILL * scale) }
	var title := "Bounty: %s" % label.capitalize()
	var desc := "(Placeholder) Someone wants %d %s gone." % [n, label]
	# Some jobs lean a route (the family bounty never does).
	var flavor := _bounty_flavor(flavor_rolls[mini(index, flavor_rolls.size() - 1)]) if index > 0 else {}
	if not flavor.is_empty():
		title = "%s: %s" % [flavor.label, label.capitalize()]
		desc = flavor.desc % [n, label]
		rewards.gold = roundi(rewards.gold * flavor.gold_mult)
		rewards["route_points"] = { flavor.route: BOUNTY_ROUTE_POINTS }
	# Guild jobs: the guild that runs this floor posts it and pays in reputation too.
	var guild: StringName = GameState.guilds.owner_of_floor(floor_n)
	var giver := "Notice board"
	if guild != &"":
		rewards["guild_rep"] = { guild: BOUNTY_GUILD_REP }
		giver = GuildLibrary.guild_name(guild)
	return { "id": id, "def": {
		"title": title, "kind": "bounty", "giver": giver, "desc": desc,
		"steps": [{ "text": "Defeat %s" % label, "goal": goal }], "rewards": rewards,
	} }


## Reputation a guild job pays with the guild that posted it.
const BOUNTY_GUILD_REP := 5


## Route flavors for bounties: { route, label, desc (with %d/%s), gold_mult }.
const BOUNTY_ROUTE_POINTS := 3
const BOUNTY_FLAVORS := [
	{ "chance": 0.2, "route": &"villain", "label": "Shady job", "gold_mult": 1.5,
		"desc": "(Placeholder) No names, no questions: %d %s, and the pay is good." },
	{ "chance": 0.2, "route": &"hero", "label": "Plea for help", "gold_mult": 0.8,
		"desc": "(Placeholder) Climbers below are scared. Clear out %d %s for them." },
	{ "chance": 0.15, "route": &"vigilante", "label": "Wanted", "gold_mult": 1.2,
		"desc": "(Placeholder) The guards won't touch them. Deal with %d %s yourself." },
]


static func _bounty_flavor(roll: float) -> Dictionary:
	var acc := 0.0
	for f in BOUNTY_FLAVORS:
		acc += f.chance
		if roll < acc:
			return f
	return {}


# =========================================================
# Save / load (validated: unknown quests dropped, numbers clamped)
# =========================================================

func to_dict() -> Dictionary:
	var act := {}
	for id in active:
		act[String(id)] = { "step": active[id].step, "progress": active[id].progress }
	var b := {}
	for id in bounties:
		b[String(id)] = SaveSerializer.quest_def_to_dict(bounties[id])
	return { "active": act, "completed": completed.map(func(x): return String(x)),
		"failed": failed.map(func(x): return String(x)), "bounties": b, "pinned": String(pinned) }


static func from_dict(d: Dictionary) -> QuestLog:
	var ql := QuestLog.new()
	var S := SaveSerializer
	var bd := S._d(d, "bounties")
	for id in bd:
		if id is String and id.begins_with("bounty_") and bd[id] is Dictionary:
			var q := S.quest_def_from_dict(bd[id])
			if not q.is_empty():
				ql.bounties[StringName(id)] = q
	var act := S._d(d, "active")
	for id in act:
		var sid := StringName(id) if id is String else &""
		if not act[id] is Dictionary or ql.def_of(sid).is_empty():
			continue
		var steps: int = ql.def_of(sid).steps.size()
		ql.active[sid] = { "step": S._i(act[id], "step", 0, 0, steps - 1),
			"progress": S._i(act[id], "progress", 0, 0, 99999) }
	for key in ["completed", "failed"]:
		for id in S._a(d, key):
			if id is String and not ql.def_of(StringName(id)).is_empty() and not ql.active.has(StringName(id)):
				(ql.completed if key == "completed" else ql.failed).append(StringName(id))
	var p := StringName(S._s(d, "pinned"))
	ql.pinned = p if ql.active.has(p) else &""
	return ql
