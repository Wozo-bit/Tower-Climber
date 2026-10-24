class_name DialogueLibrary
extends RefCounted
## Every conversation in the game, as plain data. DialogueRunner plays them.
##
## A dialogue:
##   "start": node id, OR a list of { "if": <condition>, "node": id } checked in
##            order (an entry without "if" always matches, so put it last).
##   "nodes": { node_id: <node> }
##
## A node:
##   "speaker": shown above the text. "" = narration. "{player}" / "{friend}"
##              work here and in all text (they become the current names), and
##              "{npc}" is the companion you're talking to (waiting_companion).
##   "text":    the line.
##   "effects": (optional) run when the node is shown. See below.
##   Then ONE of:
##   "next":    node id to go to on "Next ▸". "" or missing = conversation ends.
##   "choices": [ { "text", "next", "if": <condition>, "effects": [...] }, ... ]
##              Choices whose "if" fails are hidden. A choice with "next" = ""
##              (or missing) ends the conversation.
##
## Conditions (every key given must pass; {} always passes):
##   "flag": &"x"            story flag x is set
##   "not_flag": &"x"        story flag x is NOT set
##   "min_floor" / "max_floor": int
##   "min_level": int        player level
##   "gold": int             the player has at least this much gold
##   "item": &"id"           the bag has at least one
##   "ng_plus": bool         true = only in New Game+, false = only first run
##   "on_secret_path": &"id" the player has found enough clues for that path
##   "recruited": &"npc_id"  that NPC is in the party / reserve
##
## Effects (a list of one-key dictionaries, run in order):
##   { "set_flag": &"x" }  { "clear_flag": &"x" }
##   { "give_item": &"id", "count": 1 }  { "give_gold": n }  { "take_gold": n }
##   { "recruit": &"npc_id" }   joins the party (or the reserve if it's full)
##   { "heal_party": true }     full HP/MP + revive, like a campfire
##   { "open_shop": true }      ends the talk and opens the merchant's shop
##   { "toast": "text" }        a message on the floor HUD afterwards
##   { "rejoin": true }         the dismissed companion you're talking to comes back
##
## Story content goes here later. What's below are placeholder lines so every
## system (shop, clues, recruiting) can be tested.

const DIALOGUES := {
	# --- The rest-floor merchant. Bumping the merchant starts this. ---
	&"merchant": {
		"start": "hello",
		"nodes": {
			"hello": {
				"speaker": "Merchant",
				"text": "Climbing, are we? You'll want supplies.",
				"choices": [
					{ "text": "Let's trade.", "effects": [{ "open_shop": true }] },
					# Ashbound clue 2 of 3. Only once you're deep enough to care.
					{ "text": "Heard any odd stories?", "next": "story",
						"if": { "min_floor": 10, "not_flag": &"clue_ash_merchant_story" } },
					{ "text": "Never mind." },
				],
			},
			"story": {
				"speaker": "Merchant",
				"text": "(Placeholder) A knight who walked out of a fire, they say. Burned black, but still walking.",
				"effects": [{ "set_flag": &"clue_ash_merchant_story" }],
				"next": "hello",
			},
		},
	},

	# --- Placeholder recruitable companion. ---
	&"brakka": {
		"start": [
			{ "if": { "flag": &"met_brakka" }, "node": "again" },
			{ "node": "first" },
		],
		"nodes": {
			"first": {
				"speaker": "Brakka",
				"text": "(Placeholder) Another climber? I've been stuck on this floor for days.",
				"effects": [{ "set_flag": &"met_brakka" }],
				"next": "friend",
			},
			"friend": {
				"speaker": "{friend}",
				"text": "(Placeholder) {player}, we could use someone who can take a hit.",
				"next": "again",
			},
			"again": {
				"speaker": "Brakka",
				"text": "(Placeholder) So, want a shield at your back?",
				"choices": [
					{ "text": "Join us.", "next": "joined", "effects": [{ "recruit": &"brakka" }] },
					{ "text": "Not right now." },
				],
			},
			"joined": {
				"speaker": "Brakka",
				"text": "(Placeholder) Ha! Lead the way.",
			},
		},
	},

	# --- Any dismissed companion waiting by the campfire. ---
	&"waiting_companion": {
		"start": "hello",
		"nodes": {
			"hello": {
				"speaker": "{npc}",
				"text": "(Placeholder) {player}! Ready to climb together again?",
				"choices": [
					{ "text": "Rejoin us.", "effects": [{ "rejoin": true }] },
					{ "text": "Not yet." },
				],
			},
		},
	},

	# --- Lore objects (Ashbound clues 1 and 3) ---
	&"scorched_mural": {
		"start": "look",
		"nodes": {
			"look": {
				"speaker": "",
				"text": "(Placeholder) A mural, half burned away. A knight kneels in the flames, a wyrm coiled above.",
				"effects": [{ "set_flag": &"clue_ash_scorched_mural" }],
			},
		},
	},
	&"feather_in_embers": {
		"start": "look",
		"nodes": {
			"look": {
				"speaker": "",
				"text": "(Placeholder) Something glints in the embers: a black feather that doesn't burn.",
				"effects": [{ "set_flag": &"clue_ash_feather_in_embers" }],
			},
		},
	},
}

const CONDITION_KEYS := ["flag", "not_flag", "min_floor", "max_floor", "min_level", "gold", "item",
	"ng_plus", "on_secret_path", "recruited"]
const EFFECT_KEYS := ["set_flag", "clear_flag", "give_item", "give_gold", "take_gold", "recruit",
	"heal_party", "open_shop", "toast", "rejoin"]


static func get_dialogue(id: StringName) -> Dictionary:
	return DIALOGUES.get(id, {})


static func has_dialogue(id: StringName) -> bool:
	return DIALOGUES.has(id)


## Checks every dialogue for typos: missing nodes, unknown condition/effect
## keys, unknown items or NPCs. Returns a list of problems ([] = all good).
## The test suite runs this, so a broken conversation fails the tests.
static func validate_all() -> PackedStringArray:
	var problems: PackedStringArray = []
	for id in DIALOGUES:
		problems.append_array(validate(id, DIALOGUES[id]))
	return problems


static func validate(id: StringName, d: Dictionary) -> PackedStringArray:
	var problems: PackedStringArray = []
	var nodes: Dictionary = d.get("nodes", {})
	if nodes.is_empty():
		problems.append("%s: has no nodes" % id)
		return problems
	var start = d.get("start")
	if start is String:
		if not nodes.has(start):
			problems.append("%s: start node '%s' doesn't exist" % [id, start])
	elif start is Array:
		for entry in start:
			if not entry is Dictionary or not nodes.has(entry.get("node", "")):
				problems.append("%s: start entry %s points to a missing node" % [id, entry])
			else:
				problems.append_array(_validate_condition("%s start" % id, entry.get("if", {})))
	else:
		problems.append("%s: 'start' must be a node id or a list" % id)
	for node_id in nodes:
		var where := "%s/%s" % [id, node_id]
		var node: Dictionary = nodes[node_id]
		if not node.get("text", "") is String or node.get("text", "") == "":
			problems.append("%s: no text" % where)
		problems.append_array(_validate_effects(where, node.get("effects", [])))
		var nxt: String = node.get("next", "")
		if nxt != "" and not nodes.has(nxt):
			problems.append("%s: next '%s' doesn't exist" % [where, nxt])
		if node.has("choices") and node.has("next"):
			problems.append("%s: has both 'next' and 'choices'" % where)
		for c in node.get("choices", []):
			var cnext: String = c.get("next", "")
			if c.get("text", "") == "":
				problems.append("%s: a choice has no text" % where)
			if cnext != "" and not nodes.has(cnext):
				problems.append("%s: choice '%s' goes to missing node '%s'" % [where, c.get("text"), cnext])
			problems.append_array(_validate_condition(where, c.get("if", {})))
			problems.append_array(_validate_effects(where, c.get("effects", [])))
	return problems


static func _validate_condition(where: String, cond: Dictionary) -> PackedStringArray:
	var problems: PackedStringArray = []
	for k in cond:
		if not k in CONDITION_KEYS:
			problems.append("%s: unknown condition '%s'" % [where, k])
	if cond.has("item") and ItemLibrary.get_item(cond.item) == null:
		problems.append("%s: unknown item '%s'" % [where, cond.item])
	if cond.has("recruited") and not NpcLibrary.NPCS.has(cond.recruited):
		problems.append("%s: unknown NPC '%s'" % [where, cond.recruited])
	if cond.has("on_secret_path") and not SecretPaths.PATHS.has(cond.on_secret_path):
		problems.append("%s: unknown secret path '%s'" % [where, cond.on_secret_path])
	return problems


static func _validate_effects(where: String, effects: Array) -> PackedStringArray:
	var problems: PackedStringArray = []
	for e in effects:
		var known := false
		for k in e:
			if k in EFFECT_KEYS:
				known = true
		if not known:
			problems.append("%s: unknown effect %s" % [where, e])
		if e.has("give_item") and ItemLibrary.get_item(e.give_item) == null:
			problems.append("%s: unknown item '%s'" % [where, e.give_item])
		if e.has("recruit"):
			var npc: Dictionary = NpcLibrary.NPCS.get(e.recruit, {})
			if not npc.has("recruit"):
				problems.append("%s: '%s' isn't a recruitable NPC" % [where, e.recruit])
	return problems
