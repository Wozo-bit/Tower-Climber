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
	if requests.has("shop"):
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
			var c := gs.recruit(e.recruit)
			if c:
				messages.append("%s joined the party!" % c.character_name if gs.companions.has(c)
					else "%s joined (on reserve: the party is full)." % c.character_name)
		if e.has("heal_party"):
			gs.full_restore_party()
			messages.append("Everyone feels rested.")
		if e.has("open_shop"):
			requests.append("shop")
		if e.has("rejoin") and companion:
			if gs.rejoin(companion):
				messages.append("%s is back%s!" % [companion.character_name,
					"" if gs.companions.has(companion) else " (on the reserve)"])
			else:
				messages.append("No room: the party and reserve are full.")
		if e.has("toast"):
			messages.append(fill(e.toast, _npc_name()))


func _npc_name() -> String:
	return companion.character_name if companion else ""


## Swaps {player}, {friend} and {npc} for the current names.
static func fill(s: String, npc_name: String = "") -> String:
	var friend := GameState.childhood_friend()
	return s.replace("{player}", GameState.player.character_name) \
		.replace("{friend}", friend.character_name if friend else GameState.CHILDHOOD_FRIEND_NAME) \
		.replace("{npc}", npc_name)
