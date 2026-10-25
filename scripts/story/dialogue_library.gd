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
##   "portrait": (optional) art id for the face shown next to the line
##              (assets/art/portraits/<id> or beings/<id>). Without it the
##              face is found from the speaker (Assets / DialogueBox).
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
##   "quest_new": &"id"      that quest was never started (so it can be offered)
##   "quest_active": &"id"   /  "quest_done": &"id"  /  "quest_failed": &"id"
##   "quest_on_step": [&"id", i]  the quest is active and on step i (0 = first)
##   "route": &"hero"        you're on that route (locked, or clearly leaning)
##   "not_route": &"villain" you're NOT on that route
##   "route_locked": &"hero" that route is locked in (true/false = any route locked or not)
##   "no_route": true        neutral (not on any route)
##
## Effects (a list of one-key dictionaries, run in order):
##   { "set_flag": &"x" }  { "clear_flag": &"x" }
##   { "give_item": &"id", "count": 1 }  { "give_gold": n }  { "take_gold": n }
##   { "recruit": &"npc_id" }   joins the party (or the reserve if it's full)
##   { "heal_party": true }     full HP/MP + revive, like a campfire
##   { "open_shop": true }      ends the talk and opens the merchant's shop
##   { "toast": "text" }        a message on the floor HUD afterwards
##   { "rejoin": true }         the dismissed companion you're talking to comes back
##   { "start_quest": &"id" }   { "fail_quest": &"id" }   (QuestLibrary ids)
##   { "take_item": &"id", "count": 1 }   e.g. handing over quest items
##   { "route_points": { &"hero": 3 } }   nudges your route (negative = away)
##   { "lock_route": &"villain" }  a KEY choice: that route for good
##   { "open_shop": "black_market" }  a different trader's stock (ShopPanel)
##
## Story content goes here later. What's below are placeholder lines so every
## system (shop, clues, recruiting) can be tested.

const DIALOGUES := {
	# --- The rest-floor merchant. Bumping the merchant starts this. ---
	&"merchant": {
		# Locked-in villains get turned away (prices also shift with your route).
		"start": [
			{ "if": { "route_locked": &"villain" }, "node": "refuse" },
			{ "node": "hello" },
		],
		"nodes": {
			"refuse": {
				"speaker": "Merchant",
				"text": "(Placeholder) I know who you are. I don't sell to your kind. Try the alleys.",
			},
			"hello": {
				"speaker": "Merchant",
				"text": "Climbing, are we? You'll want supplies.",
				"choices": [
					{ "text": "Let's trade.", "effects": [{ "open_shop": true }] },
					# Ashbound clue 2 of 3. Only once you're deep enough to care.
					{ "text": "Heard any odd stories?", "next": "story",
						"if": { "min_floor": 10, "not_flag": &"clue_ash_merchant_story" } },
					# Weakness hint for the stage ahead (StageLibrary theme "hint").
					{ "text": "Any advice for the floors ahead?", "next": "advice" },
					{ "text": "Heard any news?", "next": "rumors" },
					# Quest: glowcap delivery (offered, then handed in).
					{ "text": "Need help with anything?", "next": "glowcap_ask",
						"if": { "quest_new": &"glowcap_delivery", "max_floor": 15 } },
					{ "text": "Here are your glowcaps.", "next": "glowcap_thanks",
						"if": { "quest_on_step": [&"glowcap_delivery", 1] } },
					{ "text": "Never mind." },
				],
			},
			"glowcap_ask": {
				"speaker": "Merchant",
				"text": "(Placeholder) Glowcaps! Three of them. Slimes swallow them whole, so check what they leave behind. Before floor 15, mind; they spoil.",
				"effects": [{ "start_quest": &"glowcap_delivery" }],
				"next": "hello",
			},
			"glowcap_thanks": {
				"speaker": "Merchant",
				"text": "(Placeholder) Perfect, still glowing. Here, for your trouble.",
				"effects": [{ "take_item": &"glowcap", "count": 3 }, { "set_flag": &"glowcaps_delivered" }],
				"next": "hello",
			},
			"story": {
				"speaker": "Merchant",
				"text": "(Placeholder) A knight who walked out of a fire, they say. Burned black, but still walking.",
				"effects": [{ "set_flag": &"clue_ash_merchant_story" }],
				"next": "hello",
			},
			"advice": {
				"speaker": "Merchant",
				"text": "{stage_hint}",
				"next": "hello",
			},
			"rumors": {
				"speaker": "Merchant",
				"text": "(Placeholder) Word travels up and down the stairs...\n\n{tower_news}",
				"next": "hello",
			},
		},
	},

	# --- Guild agents ({guild...} = the guild that runs this floor). ---
	&"guild_agent": {
		"start": "hello",
		"nodes": {
			"hello": {
				"speaker": "{guild} agent",
				"text": "(Placeholder) Welcome to {guild} territory. Your standing with us: {guild_standing}.",
				"choices": [
					{ "text": "Tell me about your guild.", "next": "about" },
					{ "text": "I want to join.", "next": "joined", "effects": [{ "join_guild": true }],
						"if": { "can_join_guild": true } },
					{ "text": "Can I join?", "next": "refused", "if": { "guild_member": false, "can_join_guild": false } },
					{ "text": "Show me the members' stock.", "effects": [{ "open_shop": "guild" }],
						"if": { "guild_member": true } },
					# Phase 3: wars, mercenaries, heists.
					{ "text": "Need a sword in your war?", "next": "hired", "effects": [{ "hire_on": true }],
						"if": { "can_hire_on": true } },
					{ "text": "Any special jobs for me?", "next": "heist_given", "effects": [{ "take_heist": true }],
						"if": { "can_take_heist": true } },
					{ "text": "(Heist) Slip away to their vault...", "next": "heist_tried", "effects": [{ "attempt_heist": true }],
						"if": { "heist_here": true } },
					{ "text": "I'm here for my pay.", "next": "paid", "effects": [{ "collect_pay": true }],
						"if": { "guild_pay_due": true } },
					# Your guild's captains they captured.
					{ "text": "Release my captain. ({guild_ransom} gold)", "next": "ransomed", "effects": [{ "pay_ransom": true }],
						"if": { "can_pay_ransom": true } },
					{ "text": "(You can't pay the {guild_ransom} gold ransom for your captain.)", "next": "no_ransom",
						"if": { "holds_captive": true, "can_pay_ransom": false } },
					{ "text": "I'm leaving the guild.", "next": "leave_confirm", "if": { "guild_member": true } },
					{ "text": "Goodbye." },
				],
			},
			"about": {
				"speaker": "{guild} agent",
				"text": "{guild_motto}\n\nWe serve {guild_patron}. We run {guild_floors}, and take {guild_tax} of what's earned there. Members pay less, and climb the ranks.",
				"next": "hello",
			},
			"joined": { "speaker": "{guild} agent", "text": "(Placeholder) Welcome, {guild_rank}. Don't embarrass us." , "next": "hello" },
			"refused": { "speaker": "{guild} agent", "text": "(Placeholder) Not a chance. {guild_refusal}", "next": "hello" },
			"paid": { "speaker": "{guild} agent", "text": "(Placeholder) Your cut. Spend it wisely.", "next": "hello" },
			"ransomed": { "speaker": "{guild} agent", "text": "(Placeholder) Pleasure doing business. Your captain's free to go.", "next": "hello" },
			"no_ransom": { "speaker": "{guild} agent", "text": "(Placeholder) Then they stay with us. Come back with the gold, or come through our champion.", "next": "hello" },
			"hired": { "speaker": "{guild} agent", "text": "(Placeholder) {guild_war}. Their guards will come for you now. We pay per head.", "next": "hello" },
			"heist_given": { "speaker": "{guild} agent", "text": "(Placeholder) Our rivals keep a vault. Find one of their agents, and help yourself.", "next": "hello" },
			"heist_tried": { "speaker": "", "text": "(Placeholder) You slip away while the agent's back is turned..." },
			"leave_confirm": {
				"speaker": "{guild} agent",
				"text": "(Placeholder) Walk out on us, and we'll remember it. Sure?",
				"choices": [
					{ "text": "I'm sure.", "next": "left", "effects": [{ "leave_guild": true }] },
					{ "text": "No, I'll stay.", "next": "hello" },
				],
			},
			"left": { "speaker": "{guild} agent", "text": "(Placeholder) Then get off our floors." },
		},
	},

	# --- Gods, demons and devils ({being...} = the being you're talking to). ---
	# Started at a shrine, after a stage boss, or by a devil's bargain.
	&"blessing_offer": {
		"start": "offer",
		"nodes": {
			"offer": {
				"speaker": "{being}",
				"text": "{being_offer}\n\nBlessing: {being_gifts}",
				"choices": [
					{ "text": "I accept.", "next": "accepted", "effects": [{ "accept_blessing": true }],
						"if": { "has_bargain": false } },
					{ "text": "Deal. ({being_bargain})", "next": "accepted", "effects": [{ "accept_blessing": true }],
						"if": { "has_bargain": true, "can_pay_bargain": true } },
					{ "text": "(You can't pay: {being_bargain})", "if": { "has_bargain": true, "can_pay_bargain": false },
						"effects": [{ "refuse_blessing": true }] },
					{ "text": "No.", "effects": [{ "refuse_blessing": true }] },
				],
			},
			"accepted": { "speaker": "{being}", "text": "(Placeholder) Then we are bound. Don't make me regret it." },
		},
	},
	&"blessing_warning": {
		"start": "warn",
		"nodes": { "warn": { "speaker": "{being}", "text": "{being_warn}" } },
	},
	&"blessing_punish": {
		"start": "punish",
		"nodes": { "punish": { "speaker": "{being}", "text": "{being_punish}" } },
	},

	# --- Route reactions from companions ({npc} = the companion). ---
	&"companion_warning": {
		"start": "warn",
		"nodes": {
			"warn": {
				"speaker": "{npc}",
				"text": "(Placeholder) {player}... I don't like who you're becoming. Keep going like this and I'm gone.",
			},
		},
	},
	&"companion_leaving": {
		"start": "leave",
		"nodes": {
			"leave": {
				"speaker": "{npc}",
				"text": "(Placeholder) I warned you. I can't follow you down this path. If you ever turn back, I'll be by a campfire.",
			},
		},
	},

	# --- Route placeholders: a choice that nudges your route, and a key choice. ---
	&"captured_bandit": {
		"start": "plead",
		"nodes": {
			"plead": {
				"speaker": "Captured bandit",
				"text": "(Placeholder) The boss had me chained here. Please, let me go. I'll never rob anyone again.",
				"choices": [
					{ "text": "Let them go.", "next": "freed",
						"effects": [{ "route_points": { &"hero": 5 } }, { "set_flag": &"bandit_judged" }] },
					{ "text": "Turn them in for the bounty.", "next": "turned_in",
						"effects": [{ "route_points": { &"vigilante": 5 } }, { "give_gold": 150 }, { "set_flag": &"bandit_judged" }] },
					{ "text": "Take everything they have.", "next": "robbed",
						"effects": [{ "route_points": { &"villain": 5 } }, { "give_gold": 250 }, { "set_flag": &"bandit_judged" }] },
				],
			},
			"freed": { "speaker": "Captured bandit", "text": "(Placeholder) Thank you. I won't forget this." },
			"turned_in": { "speaker": "Captured bandit", "text": "(Placeholder) ...Figures." },
			"robbed": { "speaker": "Captured bandit", "text": "(Placeholder) You're worse than the boss." },
		},
	},
	&"crossroads_shrine": {
		"start": [
			{ "if": { "route_locked": true }, "node": "settled" },
			{ "node": "oath" },
		],
		"nodes": {
			"oath": {
				"speaker": "",
				"text": "(Placeholder) An old shrine where three paths meet. An oath sworn here can't be taken back.",
				"choices": [
					{ "text": "Swear to protect the tower's people.", "next": "sworn", "effects": [{ "lock_route": &"hero" }] },
					{ "text": "Swear to take what you want.", "next": "sworn", "effects": [{ "lock_route": &"villain" }] },
					{ "text": "Swear to judge for yourself.", "next": "sworn", "effects": [{ "lock_route": &"vigilante" }] },
					{ "text": "Not yet." },
				],
			},
			"sworn": { "speaker": "", "text": "(Placeholder) The shrine's light settles on you. There's no going back now." },
			"settled": { "speaker": "", "text": "(Placeholder) The shrine is quiet. Your path is already chosen." },
		},
	},
	&"black_market": {
		"start": "hello",
		"nodes": {
			"hello": {
				"speaker": "Hooded trader",
				"text": "(Placeholder) Heard you're not fussy about how things get done. Neither am I.",
				"choices": [
					{ "text": "Show me what you've got.", "effects": [{ "open_shop": "black_market" }] },
					{ "text": "Not now." },
				],
			},
		},
	},

	# --- Quest from a found item: the torn map, and the cache it leads to. ---
	&"torn_map": {
		"start": "look",
		"nodes": {
			"look": {
				"speaker": "",
				"text": "(Placeholder) A torn scrap of map is pinned under a rock. An X marks somewhere a few floors up.",
				"effects": [{ "start_quest": &"torn_map" }],
			},
		},
	},
	&"hidden_cache": {
		"start": "look",
		"nodes": {
			"look": {
				"speaker": "",
				"text": "(Placeholder) Behind a loose stone: the cache from the map!",
				"effects": [{ "set_flag": &"found_hidden_cache" }],
			},
		},
	},

	# --- Scratched warnings on the walls of normal floors (weakness hints). ---
	&"warning_scrawl": {
		"start": "read",
		"nodes": {
			"read": {
				"speaker": "",
				"text": "Someone scratched a warning into the wall: \"{stage_hint}\"",
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

	# --- Recruits (NpcLibrary "recruit"; {recruit...} = the one you're talking to).
	# One shared conversation per way of meeting them, so a new recruit is
	# just data. Placeholder text.
	&"recruit_campfire": {
		"start": "hello",
		"nodes": {
			"hello": {
				"speaker": "{recruit}",
				"text": "{recruit_pitch}",
				"choices": [
					{ "text": "Join us.", "next": "joined", "effects": [{ "recruit_here": true }], "if": { "refuses_you": false } },
					{ "text": "Join us.", "next": "refused", "if": { "refuses_you": true } },
					{ "text": "Not right now." },
				],
			},
			"joined": { "speaker": "{recruit}", "text": "(Placeholder) Lead the way." },
			"refused": { "speaker": "{recruit}", "text": "(Placeholder) Not with someone who walks your path." },
		},
	},
	&"recruit_hire": {
		"start": "hello",
		"nodes": {
			"hello": {
				"speaker": "{recruit}",
				"text": "{recruit_pitch}",
				"choices": [
					{ "text": "Deal. ({recruit_fee} gold)", "next": "hired", "effects": [{ "pay_fee": true }, { "recruit_here": true }],
						"if": { "can_pay_fee": true, "refuses_you": false } },
					{ "text": "(You can't afford {recruit_fee} gold.)", "if": { "can_pay_fee": false } },
					{ "text": "Deal.", "next": "refused", "if": { "can_pay_fee": true, "refuses_you": true } },
					{ "text": "Not right now." },
				],
			},
			"hired": { "speaker": "{recruit}", "text": "(Placeholder) Pleasure doing business." },
			"refused": { "speaker": "{recruit}", "text": "(Placeholder) Your gold's no good. Not after what I've heard about you." },
		},
	},
	&"recruit_favor": {
		"start": [
			{ "if": { "favor_done": true }, "node": "ready" },
			{ "if": { "favor_active": true }, "node": "waiting" },
			{ "node": "ask" },
		],
		"nodes": {
			"ask": {
				"speaker": "{recruit}",
				"text": "{recruit_pitch}",
				"choices": [
					{ "text": "I'll do it.", "next": "accepted", "effects": [{ "start_favor": true }] },
					{ "text": "Not right now." },
				],
			},
			"accepted": { "speaker": "{recruit}", "text": "(Placeholder) Come back when it's done." },
			"waiting": { "speaker": "{recruit}", "text": "(Placeholder) Still waiting on that favor ({recruit_favor})." },
			"ready": {
				"speaker": "{recruit}",
				"text": "(Placeholder) You kept your word. I'll keep mine.",
				"choices": [
					{ "text": "Join us.", "next": "joined", "effects": [{ "recruit_here": true }], "if": { "refuses_you": false } },
					{ "text": "Join us.", "next": "refused", "if": { "refuses_you": true } },
					{ "text": "Not right now." },
				],
			},
			"joined": { "speaker": "{recruit}", "text": "(Placeholder) Lead the way." },
			"refused": { "speaker": "{recruit}", "text": "(Placeholder) ...I've seen what you've become. No." },
		},
	},

	# Demigods: an omen by the campfire, then a legendary quest chain.
	&"recruit_legend": {
		"start": [
			{ "if": { "favor_done": true }, "node": "ready" },
			{ "if": { "favor_active": true }, "node": "waiting" },
			{ "node": "omen" },
		],
		"nodes": {
			"omen": {
				"speaker": "",
				"text": "(Placeholder) The fire burns gold. A figure of legend steps out of the light.",
				"next": "ask",
			},
			"ask": {
				"speaker": "{recruit}",
				"text": "{recruit_pitch}",
				"choices": [
					{ "text": "I accept the trial.", "next": "accepted", "effects": [{ "start_favor": true }] },
					{ "text": "Not yet." },
				],
			},
			"accepted": { "speaker": "{recruit}", "text": "(Placeholder) Then go. I will be watching from the fires above." },
			"waiting": { "speaker": "{recruit}", "text": "(Placeholder) Your legend is not finished yet ({recruit_favor})." },
			"ready": {
				"speaker": "{recruit}",
				"text": "(Placeholder) The gods have seen enough. I will climb with you.",
				"choices": [
					{ "text": "Climb with us.", "next": "joined", "effects": [{ "recruit_here": true }], "if": { "refuses_you": false } },
					{ "text": "Climb with us.", "next": "refused", "if": { "refuses_you": true } },
					{ "text": "Not yet." },
				],
			},
			"joined": { "speaker": "{recruit}", "text": "(Placeholder) Lead, mortal. Try to keep up." },
			"refused": { "speaker": "{recruit}", "text": "(Placeholder) Your path has strayed from anything I would follow." },
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
	"ng_plus", "on_secret_path", "recruited", "quest_new", "quest_active", "quest_done", "quest_failed",
	"quest_on_step", "route", "not_route", "route_locked", "no_route", "has_bargain", "can_pay_bargain", "blessed",
	"guild_member", "in_guild", "can_join_guild", "guild_pay_due", "can_hire_on", "can_take_heist", "heist_here",
	"holds_captive", "can_pay_ransom", "favor_new", "favor_active", "favor_done", "can_pay_fee", "refuses_you",
	"patron_pantheon"]
const EFFECT_KEYS := ["set_flag", "clear_flag", "give_item", "give_gold", "take_gold", "recruit",
	"heal_party", "open_shop", "toast", "rejoin", "start_quest", "fail_quest", "take_item",
	"route_points", "lock_route", "accept_blessing", "refuse_blessing", "interest",
	"join_guild", "leave_guild", "collect_pay", "guild_rep", "hire_on", "take_heist", "attempt_heist", "pay_ransom",
	"recruit_here", "pay_fee", "start_favor"]


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
	for k in ["route", "not_route", "route_locked"]:
		if cond.has(k) and not (k == "route_locked" and cond[k] is bool) and not RouteLibrary.routes.has(cond[k]):
			problems.append("%s: unknown route '%s'" % [where, cond[k]])
	for k in ["quest_new", "quest_active", "quest_done", "quest_failed"]:
		if cond.has(k) and not QuestLibrary.QUESTS.has(cond[k]):
			problems.append("%s: unknown quest '%s'" % [where, cond[k]])
	if cond.has("quest_on_step"):
		var qs = cond.quest_on_step
		if not (qs is Array and qs.size() == 2 and QuestLibrary.QUESTS.has(qs[0])
				and qs[1] is int and qs[1] < QuestLibrary.QUESTS[qs[0]].steps.size()):
			problems.append("%s: quest_on_step needs [quest id, step index] (got %s)" % [where, qs])
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
		for k in ["start_quest", "fail_quest"]:
			if e.has(k) and not QuestLibrary.QUESTS.has(e[k]):
				problems.append("%s: unknown quest '%s'" % [where, e[k]])
		if e.has("take_item") and ItemLibrary.get_item(e.take_item) == null:
			problems.append("%s: unknown item '%s'" % [where, e.take_item])
		if e.has("lock_route") and not RouteLibrary.routes.has(e.lock_route):
			problems.append("%s: unknown route '%s'" % [where, e.lock_route])
		for r in e.get("route_points", {}):
			if not RouteLibrary.routes.has(r):
				problems.append("%s: unknown route '%s'" % [where, r])
		for b in e.get("interest", {}):
			if not BeingLibrary.beings.has(b):
				problems.append("%s: unknown being '%s'" % [where, b])
		for g in e.get("guild_rep", {}):
			if not GuildLibrary.guilds.has(g):
				problems.append("%s: unknown guild '%s'" % [where, g])
		if e.get("open_shop") is String and e.open_shop != "guild" and not ItemLibrary.SHOPS.has(StringName(e.open_shop)):
			problems.append("%s: unknown shop '%s'" % [where, e.open_shop])
	return problems
