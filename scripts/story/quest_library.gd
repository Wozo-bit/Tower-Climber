class_name QuestLibrary
extends RefCounted
## Every hand-written quest, as plain data. QuestLog tracks them.
## (Notice-board bounties are generated instead; see QuestLog.make_bounty.)
##
## A quest:
##   "title", "desc"
##   "kind":    "main" (the story questline), "side", or "bounty"
##   "giver":   who you get it from, for the log ("Merchant", "Notice board"...)
##   "steps":   done in order. Each: { "text": "Defeat 5 slimes", "goal": <goal> }
##   "rewards": (optional) { "gold", "xp", "items": { id: count },
##              "gear": <quest gear>, "flags": [..], "reveal_family": &"slime",
##              "route_points": { &"hero": 3 } }
##              Quest gear is marked quest_reward, so it never carries into NG+.
##   "drops":   (optional) quest items enemies drop WHILE a collect step needs
##              them: [{ "item", "family" or "enemy", "chance" }]
##   "expires_after_floor": (optional) climbing past this floor fails it
##   "on_fail_flag" / "on_complete_flag": (optional) set when it ends, so a
##              failed (or finished) quest can open another quest or consequence
##   "auto_start": (optional) DialogueRunner condition: starts by itself once
##              true (main quests). Otherwise quests start from dialogue
##              ({ "start_quest": id }) or the notice board ("board": true).
##   "board":   (optional) true = offered on the rest-floor notice board
##   "board_if": (optional) condition for showing it on the board
##
## Goals:
##   { "type": "defeat", "count": n, and ONE of "enemy": id / "family": id /
##     "kind": "boss" | "miniboss" | "roaming" }
##   { "type": "collect", "item": id, "count": n }    (items in the bag)
##   { "type": "reach", "floor": n }
##   { "type": "flag", "flag": &"x" }  talk to someone / find something: the
##     dialogue or lore object sets the flag
##
## Placeholder content below: one quest per source so every system is testable.

const QUESTS := {
	# --- Main questline (starts on its own) ---
	&"main_climb": {
		"title": "The Climb", "kind": "main", "giver": "The tower",
		"desc": "(Placeholder) Reach the top of the tower.",
		"auto_start": {},
		"steps": [
			{ "text": "Defeat the guardian of floor 10", "goal": { "type": "defeat", "kind": "boss", "count": 1 } },
			{ "text": "Reach floor 11", "goal": { "type": "reach", "floor": 11 } },
			{ "text": "Defeat the guardian of floor 20", "goal": { "type": "defeat", "kind": "boss", "count": 1 } },
		],
		"rewards": { "gold": 500 },
	},

	# --- From an NPC (the merchant), with a deadline and a fail consequence ---
	&"glowcap_delivery": {
		"title": "Glowcaps for the Merchant", "kind": "side", "giver": "Merchant",
		"desc": "(Placeholder) The merchant wants 3 glowcaps. Slimes sometimes carry them.",
		"steps": [
			{ "text": "Collect glowcaps", "goal": { "type": "collect", "item": &"glowcap", "count": 3 } },
			{ "text": "Bring them to the merchant", "goal": { "type": "flag", "flag": &"glowcaps_delivered" } },
		],
		"drops": [{ "item": &"glowcap", "family": &"slime", "chance": 0.35 }],
		"expires_after_floor": 15,
		"on_fail_flag": &"glowcaps_failed",
		"rewards": { "gold": 150, "items": { &"advanced_potion": 2 } },
	},

	# --- From a found item (the torn map lore object) ---
	&"torn_map": {
		"title": "The Torn Map", "kind": "side", "giver": "A torn map",
		"desc": "(Placeholder) A scrap of map marks a hidden cache somewhere higher up.",
		"steps": [
			{ "text": "Climb to floor 6", "goal": { "type": "reach", "floor": 6 } },
			{ "text": "Find the hidden cache", "goal": { "type": "flag", "flag": &"found_hidden_cache" } },
		],
		"rewards": { "gold": 120,
			"gear": { "base": &"amulet", "name": "Cartographer's Charm", "rarity": 2,
				"bonuses": { Stats.Type.LUCK: 4, Stats.Type.AGILITY: 2 },
				"desc": "(Placeholder) It always points somewhere interesting." } },
	},

	# --- Hand-written notice board job ---
	&"slime_survey": {
		"title": "Slime Survey", "kind": "side", "giver": "Notice board",
		"desc": "(Placeholder) A hunter wants slimes thinned out, and pays in notes on how to fight them.",
		"board": true, "board_if": { "min_floor": 5 },
		"steps": [
			{ "text": "Defeat slimes", "goal": { "type": "defeat", "family": &"slime", "count": 8 } },
		],
		"rewards": { "gold": 200, "xp": 150, "reveal_family": &"slime" },
	},
}

const GOAL_TYPES := ["defeat", "collect", "reach", "flag"]
const KINDS := ["main", "side", "bounty"]


static func get_quest(id: StringName) -> Dictionary:
	return QUESTS.get(id, {})


## Checks every quest for typos (unknown enemies, items, families, goal types).
## Returns a list of problems ([] = all good). The test suite runs this.
static func validate_all() -> PackedStringArray:
	var problems: PackedStringArray = []
	for id in QUESTS:
		problems.append_array(validate(id, QUESTS[id]))
	return problems


static func validate(id: StringName, q: Dictionary) -> PackedStringArray:
	var problems: PackedStringArray = []
	if q.get("title", "") == "":
		problems.append("%s: no title" % id)
	if not q.get("kind", "") in KINDS:
		problems.append("%s: kind must be one of %s" % [id, KINDS])
	var steps: Array = q.get("steps", [])
	if steps.is_empty():
		problems.append("%s: no steps" % id)
	for i in steps.size():
		var where := "%s step %d" % [id, i + 1]
		if steps[i].get("text", "") == "":
			problems.append("%s: no text" % where)
		problems.append_array(validate_goal(where, steps[i].get("goal", {})))
	for d in q.get("drops", []):
		if ItemLibrary.get_item(d.get("item", &"")) == null:
			problems.append("%s: drop of unknown item %s" % [id, d.get("item")])
		if d.has("family") and not EnemyFamilies.FAMILIES.has(d.family):
			problems.append("%s: drop from unknown family %s" % [id, d.family])
		if d.has("enemy") and EnemyLibrary.get_enemy_or_null(d.enemy) == null:
			problems.append("%s: drop from unknown enemy %s" % [id, d.enemy])
	var r: Dictionary = q.get("rewards", {})
	for item in r.get("items", {}):
		if ItemLibrary.get_item(item) == null:
			problems.append("%s: reward of unknown item %s" % [id, item])
	if r.has("gear") and not LootTable.BASES.has(r.gear.get("base", &"")):
		problems.append("%s: reward gear has unknown base %s" % [id, r.gear.get("base")])
	if r.has("reveal_family") and not EnemyFamilies.FAMILIES.has(r.reveal_family):
		problems.append("%s: reveals unknown family %s" % [id, r.reveal_family])
	for route_id in r.get("route_points", {}):
		if not RouteLibrary.routes.has(route_id):
			problems.append("%s: reward for unknown route %s" % [id, route_id])
	for key in ["auto_start", "board_if"]:
		for k in q.get(key, {}):
			if not k in DialogueLibrary.CONDITION_KEYS:
				problems.append("%s: unknown condition '%s' in %s" % [id, k, key])
	return problems


static func validate_goal(where: String, g: Dictionary) -> PackedStringArray:
	var problems: PackedStringArray = []
	match g.get("type", ""):
		"defeat":
			var targets := ["enemy", "family", "kind"].filter(func(k): return g.has(k))
			if targets.size() != 1:
				problems.append("%s: defeat needs exactly one of enemy/family/kind" % where)
			if g.has("enemy") and EnemyLibrary.get_enemy_or_null(g.enemy) == null:
				problems.append("%s: unknown enemy %s" % [where, g.enemy])
			if g.has("family") and not EnemyFamilies.FAMILIES.has(g.family):
				problems.append("%s: unknown family %s" % [where, g.family])
			if g.has("kind") and not g.kind in ["boss", "miniboss", "roaming"]:
				problems.append("%s: unknown kind %s" % [where, g.kind])
			if g.get("count", 0) < 1:
				problems.append("%s: count must be at least 1" % where)
		"collect":
			if ItemLibrary.get_item(g.get("item", &"")) == null:
				problems.append("%s: unknown item %s" % [where, g.get("item")])
			if g.get("count", 0) < 1:
				problems.append("%s: count must be at least 1" % where)
		"reach":
			if g.get("floor", 0) < 1:
				problems.append("%s: reach needs a floor" % where)
		"flag":
			if g.get("flag", &"") == &"":
				problems.append("%s: flag goal needs a flag" % where)
		_:
			problems.append("%s: unknown goal type '%s'" % [where, g.get("type", "")])
	return problems
