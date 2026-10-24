class_name DialogueRunner
extends RefCounted
## Plays one conversation from DialogueLibrary. Pure logic, no UI: the
## DialogueBox shows `speaker()`, `text()` and `choices()`, then calls
## `advance()` or `choose(i)`. Tests drive it the same way.
##
## Effects change GameState directly (flags, items, gold, recruits). Things
## the screen has to do afterwards (open the shop, show a toast) are collected
## in `requests` and `messages`.

var dialogue_id: StringName
var node_id := ""
var finished := true
## UI follow-ups, e.g. "shop". Read them when the conversation ends.
var requests: Array[String] = []
## Toasts for the floor HUD ("Brakka joined the party!").
var messages: Array[String] = []
## Who you're talking to, when it's one of your own companions (a dismissed
## companion waiting by the campfire). Used by {npc} and the "rejoin" effect.
var companion: CharacterData

var _nodes: Dictionary = {}


## Starts a conversation. Returns false if the id doesn't exist.
func start(id: StringName, with: CharacterData = null) -> bool:
	var d := DialogueLibrary.get_dialogue(id)
	companion = with
	requests.clear()
	messages.clear()
	if d.is_empty():
		finished = true
		return false
	dialogue_id = id
	_nodes = d.nodes
	finished = false
	_enter(start_node(d))
	return true


## Which node a dialogue opens on right now (its "start" list is checked in order).
static func start_node(d: Dictionary) -> String:
	var start = d.get("start", "")
	if start is String:
		return start
	for entry in start:
		if check(entry.get("if", {})):
			return entry.node
	return ""


func speaker() -> String:
	return fill(_node().get("speaker", ""), _npc_name())


func text() -> String:
	return fill(_node().get("text", ""), _npc_name())


## Visible choices as [{ "index", "text" }]. Empty = show a "Next" button.
## `index` is what to pass to choose().
func choices() -> Array:
	var out := []
	var all: Array = _node().get("choices", [])
	for i in all.size():
		if check(all[i].get("if", {})):
			out.append({ "index": i, "text": fill(all[i].text, _npc_name()) })
	return out


func has_choices() -> bool:
	return _node().has("choices")


## "Next" on a line without choices.
func advance() -> void:
	if finished or has_choices():
		return
	_enter(_node().get("next", ""))


## Picks choice `index` (the "index" from choices()). Returns false if it's
## hidden or doesn't exist.
func choose(index: int) -> bool:
	if finished:
		return false
	var all: Array = _node().get("choices", [])
	if index < 0 or index >= all.size() or not check(all[index].get("if", {})):
		return false
	var c: Dictionary = all[index]
	_apply_effects(c.get("effects", []))
	if requests.any(func(r): return r.begins_with("shop")):
		_enter("")
	else:
		_enter(c.get("next", ""))
	return true


func _node() -> Dictionary:
	return _nodes.get(node_id, {})


func _enter(id: String) -> void:
	node_id = id
	if id == "" or not _nodes.has(id):
		node_id = ""
		finished = true
		return
	_apply_effects(_nodes[id].get("effects", []))


# =========================================================
# Conditions & effects
# =========================================================

## True if every key in `cond` passes. See DialogueLibrary for the keys.
static func check(cond: Dictionary) -> bool:
	var gs := GameState
	for k in cond:
		var v = cond[k]
		var ok := true
		match k:
			"flag": ok = gs.has_flag(v)
			"not_flag": ok = not gs.has_flag(v)
			"min_floor": ok = gs.floor_number >= v
			"max_floor": ok = gs.floor_number <= v
			"min_level": ok = gs.player.level >= v
			"gold": ok = gs.player.gold >= v
			"item": ok = gs.inventory.count(v) > 0
			"ng_plus": ok = (gs.ng_plus_cycle > 0) == v
			"on_secret_path": ok = SecretPaths.is_on_path(v, gs.story_flags)
			"recruited": ok = gs.has_recruited(v)
			"quest_new": ok = gs.quests.is_new(v)
			"quest_active": ok = gs.quests.is_active(v)
			"quest_done": ok = gs.quests.is_done(v)
			"quest_failed": ok = gs.quests.is_failed(v)
			"quest_on_step": ok = gs.quests.step_index(v[0]) == v[1]
			"route": ok = gs.route.current() == v
			"not_route": ok = gs.route.current() != v
			"route_locked": ok = ((gs.route.locked != &"") == v) if v is bool else gs.route.locked == v
			"no_route": ok = (gs.route.current() == &"") == v
			_:
				push_warning("Dialogue: unknown condition '%s'" % k)
				ok = false
		if not ok:
			return false
	return true


func _apply_effects(effects: Array) -> void:
	var gs := GameState
	for e: Dictionary in effects:
		if e.has("set_flag"):
			gs.set_flag(e.set_flag)
		if e.has("clear_flag"):
			gs.set_flag(e.clear_flag, false)
		if e.has("give_item"):
			var n: int = e.get("count", 1)
			gs.inventory.add(e.give_item, n)
			messages.append("Got %s%s." % [ItemLibrary.get_item(e.give_item).display_name,
				" x%d" % n if n > 1 else ""])
		if e.has("give_gold"):
			gs.player.gold += e.give_gold
			messages.append("Got %d gold." % e.give_gold)
		if e.has("take_gold"):
			gs.player.gold = maxi(0, gs.player.gold - e.take_gold)
		if e.has("recruit"):
			if gs.npc_refuses(e.recruit):
				messages.append("%s won't travel with someone like you." % NpcLibrary.get_npc(e.recruit).name)
			var c := gs.recruit(e.recruit)
			if c:
				messages.append("%s joined the party!" % c.character_name if gs.companions.has(c)
					else "%s joined (on reserve: the party is full)." % c.character_name)
		if e.has("heal_party"):
			gs.full_restore_party()
			messages.append("Everyone feels rested.")
		if e.has("open_shop"):
			# true = the merchant; a shop id string = that trader's stock.
			requests.append("shop" if e.open_shop is bool else "shop:%s" % e.open_shop)
		if e.has("rejoin") and companion:
			if gs.refuses_to_rejoin(companion):
				messages.append("%s won't come back while you walk this path." % companion.character_name)
			elif gs.rejoin(companion):
				messages.append("%s is back%s!" % [companion.character_name,
					"" if gs.companions.has(companion) else " (on the reserve)"])
			else:
				messages.append("No room: the party and reserve are full.")
		if e.has("route_points"):
			for r in e.route_points:
				gs.add_route_points(r, e.route_points[r])
		if e.has("lock_route"):
			gs.lock_route(e.lock_route)
		if e.has("take_item"):
			gs.inventory.remove(e.take_item, e.get("count", 1))
		if e.has("start_quest"):
			gs.quests.start(e.start_quest)   # its "New quest" toast comes from the quest log
		if e.has("fail_quest"):
			gs.quests.fail(e.fail_quest)
		if e.has("toast"):
			messages.append(fill(e.toast, _npc_name()))


func _npc_name() -> String:
	return companion.character_name if companion else ""


## Swaps {player}, {friend} and {npc} for the current names, and {stage_hint}
## for a hint about the stage ahead (StageLibrary theme "hint").
static func fill(s: String, npc_name: String = "") -> String:
	var friend := GameState.childhood_friend()
	return s.replace("{player}", GameState.player.character_name) \
		.replace("{friend}", friend.character_name if friend else GameState.CHILDHOOD_FRIEND_NAME) \
		.replace("{npc}", npc_name) \
		.replace("{stage_hint}", StageLibrary.stage_for_floor(GameState.floor_number + 1).get("hint", ""))
