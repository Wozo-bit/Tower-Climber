class_name StoryLibrary
extends RefCounted
## The main story, as data (see docs/story/story_bible.md). One chapter per
## 10-floor stage. Story scenes are ordinary dialogues (same format as
## DialogueLibrary, played by DialogueRunner) that start on their own:
##
## SCENES: { id: {
##   "chapter": int,
##   "floors":  [n, ...]   which floors it can play on (the first one you're on)
##   "when":    "enter"            as soon as you're on the floor
##              "guardian_down"    after that floor's miniboss / boss is beaten
##   "dialogue": id in DIALOGUES below
##   "if":      (optional) a DialogueRunner condition
## } }
## Each scene plays once per run (flag "scene_<id>"), in the order listed.
## A scene you skipped past (e.g. a wipe sent you back) waits until you're
## on one of its floors again.
##
## Dialogue nodes here may also have "style": "system" (a System window line)
## or "glitch" (a System line that flickers: the System slipping).
##
## The text is a FIRST DRAFT for Hayden to rewrite freely.

const STYLES := ["", "system", "glitch"]

## Scenes start on their own in the game; headless test runs leave them off
## (like Tips.auto_show) so other suites' floors stay quiet.
static var auto_play := DisplayServer.get_name() != "headless"

## Chapter titles, one per stage. Later chapters are placeholders until written.
const CHAPTERS := [
	{ "title": "Tester" },
	{ "title": "(Chapter 2)" },
	{ "title": "(Chapter 3)" },
	{ "title": "(Chapter 4)" },
	{ "title": "(Chapter 5)" },
	{ "title": "(Chapter 6)" },
]

## The game inside the game (placeholder name, Hayden 2026-11-04).
const GAME_NAME := "Tower of Recognition"

## The test client's odd questions (New Game). Each answer gives starting
## stat points AND a small nudge: a route lean, or a god noticing you first
## (Hayden: both). Answers are kept as flags "setup_<question>_<answer>".
const SETUP_QUESTIONS := [
	{ "id": &"want", "text": "What do you want most?", "options": [
		{ "id": &"protect", "text": "To protect someone.", "stats": { Stats.Type.HEALTH: 2 },
			"route_points": { &"hero": 3 } },
		{ "id": &"free", "text": "To be free.", "stats": { Stats.Type.AGILITY: 2 },
			"route_points": { &"vigilante": 3 } },
		{ "id": &"win", "text": "To win. Whatever it takes.", "stats": { Stats.Type.STRENGTH: 2 },
			"route_points": { &"villain": 3 } },
		{ "id": &"understand", "text": "To understand.", "stats": { Stats.Type.INTELLIGENCE: 2 } },
	] },
	{ "id": &"fear", "text": "What are you afraid of losing?", "options": [
		{ "id": &"loved", "text": "The people I love.", "stats": { Stats.Type.STAMINA: 2 },
			"interest": { &"ishtar": 5 } },
		{ "id": &"self", "text": "Who I am.", "stats": { Stats.Type.INTELLIGENCE: 2 },
			"interest": { &"odin": 5 } },
		{ "id": &"earned", "text": "Everything I've earned.", "stats": { Stats.Type.LUCK: 2 },
			"interest": { &"mammon": 5 } },
		{ "id": &"nothing", "text": "Nothing. Not anymore.", "stats": { Stats.Type.STRENGTH: 2 },
			"interest": { &"hel": 5 } },
	] },
]

## Things in the prologue room. Looking at one sets "prologue_<id>" (kept into
## the run, so the tower can call back to it).
const PROLOGUE_OBJECTS := [&"pc", &"notebook", &"phone", &"window"]

const SCENES := {
	&"ch1_wake": { "chapter": 1, "floors": [1], "when": "enter", "dialogue": &"ch1_wake" },
	&"ch1_memory": { "chapter": 1, "floors": [2, 3], "when": "enter", "dialogue": &"ch1_memory" },
	&"ch1_slip": { "chapter": 1, "floors": [4], "when": "guardian_down", "dialogue": &"ch1_slip" },
	&"ch1_legend": { "chapter": 1, "floors": [5], "when": "enter", "dialogue": &"ch1_legend" },
	&"ch1_thief": { "chapter": 1, "floors": [6, 7], "when": "enter", "dialogue": &"ch1_thief" },
	&"ch1_carving": { "chapter": 1, "floors": [8, 9], "when": "enter", "dialogue": &"ch1_carving" },
	&"ch1_fallen": { "chapter": 1, "floors": [10], "when": "enter", "dialogue": &"ch1_fallen" },
	&"ch1_end": { "chapter": 1, "floors": [10], "when": "guardian_down", "dialogue": &"ch1_end" },
}

const DIALOGUES := {
	# --- The prologue room (the real world). Lore objects you bump. ---
	&"prologue_pc": {
		"start": "mail",
		"nodes": {
			"mail": {
				"text": "One new message. No sender address.\n\n\"You have been selected for the closed test of Tower of Recognition. One tester per region. Do not share this invitation.\"",
				"next": "mail2",
			},
			"mail2": {
				"text": "Under it, a single line: \"A tower that makes gods.\" And a button: START TEST.",
				"choices": [
					{ "text": "Start the test.", "effects": [{ "set_flag": &"prologue_start_test" }] },
					{ "text": "Not yet." },
				],
			},
		},
	},
	&"prologue_notebook": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "An old notebook, wedged between textbooks. You drew in this when you were a kid: a tower, floor after floor, every one numbered.",
				"next": "b",
			},
			"b": {
				"text": "Monsters on every page, named in big careful letters. The cover says THE TOWER OF RECONGITION. You never could spell it.",
			},
		},
	},
	&"prologue_phone": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "Two messages. \"You coming out Friday? Everyone's asking.\" And a reminder that the electric bill is due.",
				"next": "b",
			},
			"b": {
				"speaker": "You",
				"text": "(Tomorrow. I'll answer tomorrow.)",
			},
		},
	},
	&"prologue_window": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The city at night. Somewhere a siren, then nothing. Your reflection looks tired.",
			},
		},
	},

	# --- Chapter 1: Tester ---
	&"ch1_wake": {
		"start": [
			{ "if": { "ng_plus": true }, "node": "again" },
			{ "node": "a" },
		],
		"nodes": {
			"a": {
				"text": "Cold stone under your cheek. Torchlight. Somewhere above you, something enormous creaks like a ship.",
				"next": "b",
			},
			"b": {
				"speaker": "{friend}",
				"text": "Hey. HEY. You fell asleep on watch again. If a slime had come by, I'd be telling your mother you got eaten.",
				"next": "c",
			},
			"c": {
				"text": "You've never seen this person before. They have the name you typed into the test client. They look at you like they've known you all your life.",
				"choices": [
					{ "text": "...Sorry. Long night.", "next": "d", "effects": [{ "set_flag": &"ch1_wake_along" }] },
					{ "text": "Who are you?", "next": "who", "effects": [{ "set_flag": &"ch1_wake_who" }] },
				],
			},
			"who": {
				"speaker": "{friend}",
				"text": "Ha. Very funny. It's me, {player}. Twenty years of me. Did you hit your head on the stairs?",
				"next": "d",
			},
			"d": {
				"style": "system",
				"text": "[ Synchronisation complete. ]\n[ Tester: {player}. Welcome to the Tower. ]",
				"next": "e",
			},
			"e": {
				"speaker": "{friend}",
				"text": "Come on. The others say whoever reaches the top becomes a god. I'm not letting you sleep through it.",
				"next": "f",
			},
			"f": {
				"style": "system",
				"text": "[ Chapter 1: Tester ]",
			},
			"again": {
				"text": "Cold stone. Torchlight. The creak of the tower above you. You know this floor. You know this voice before it speaks.",
				"next": "again2",
			},
			"again2": {
				"speaker": "{friend}",
				"text": "You fell asleep on watch again. ...Why are you looking at me like that?",
				"next": "again3",
			},
			"again3": {
				"style": "glitch",
				"text": "[ Welcome back, Tester. ]",
				"next": "f",
			},
		},
	},
	&"ch1_memory": {
		"start": "a",
		"nodes": {
			"a": {
				"speaker": "{friend}",
				"text": "This climb reminds me of the old water tower behind the mill. Remember? You froze at the top and I had to talk you down.",
				"next": "b",
			},
			"b": {
				"speaker": "{friend}",
				"text": "You split your knee open on the ladder. Still got the scar?",
				"next": "c",
			},
			"c": {
				"text": "You do have a scar on your knee. You got it falling off a fence when you were nine. There was no water tower. There was no {friend}.",
				"choices": [
					{ "text": "Yeah. I remember.", "next": "along", "effects": [{ "set_flag": &"ch1_memory_along" }] },
					{ "text": "Tell me more about back then.", "next": "ask", "effects": [{ "set_flag": &"ch1_memory_asked" }] },
					{ "text": "I don't know you.", "next": "deny", "effects": [{ "set_flag": &"ch1_memory_denied" }] },
				],
			},
			"along": {
				"speaker": "{friend}",
				"text": "Course you do. You cried the whole way home and made me swear not to tell anyone. I never did.",
			},
			"ask": {
				"speaker": "{friend}",
				"text": "Our street. The house with the blue door, yours. The tree we built the fort in. You really don't remember? ...You're scaring me a bit.",
				"next": "ask2",
			},
			"ask2": {
				"text": "Your street. The right street. But your door was never blue.",
			},
			"deny": {
				"text": "{friend} laughs. Then sees your face, and stops laughing.",
				"next": "deny2",
			},
			"deny2": {
				"speaker": "{friend}",
				"text": "...Okay. Okay. You hit your head harder than I thought. Stay close to me, alright?",
			},
		},
	},
	&"ch1_slip": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "glitch",
				"text": "[ Adequate. ]",
				"next": "b",
			},
			"b": {
				"style": "system",
				"text": "[ Miniboss defeated. ]",
				"next": "c",
			},
			"c": {
				"speaker": "{friend}",
				"text": "Did you say something?",
				"choices": [
					{ "text": "No. Nothing.", "effects": [{ "set_flag": &"ch1_slip_hidden" }] },
					{ "text": "Something just... graded me.", "next": "d", "effects": [{ "set_flag": &"ch1_slip_told" }] },
				],
			},
			"d": {
				"speaker": "{friend}",
				"text": "The tower talks to you? Lucky. It only ever talks to me in creaks.",
			},
		},
	},
	&"ch1_legend": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "Other climbers share the campfire. A young one with a bright red scarf, Tess, won't stop talking. An old one, Marn, won't start.",
				"next": "b",
			},
			"b": {
				"speaker": "Tess",
				"text": "Reach the top and you become a god. Everyone knows that. I'm going to be the god of second breakfasts.",
				"next": "c",
			},
			"c": {
				"speaker": "Marn",
				"text": "Everyone knows that, and everyone who knew it is dead. Watch the floors past ten, girl. The tower doesn't give anyone back.",
				"next": "d",
			},
			"d": {
				"speaker": "{friend}",
				"text": "Don't listen to him. You go down, you wake up at the last fire. Bit of a headache, lighter purse. That's the tower.",
				"next": "e",
			},
			"e": {
				"speaker": "{player}",
				"text": "(It's just a game. ...Right?)",
				"effects": [{ "set_flag": &"ch1_met_tess" }],
			},
		},
	},
	&"ch1_thief": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "A climber sits slumped against the wall, bleeding through their sleeve, a heavy coin pouch at their belt. More than one name is stitched into it.",
				"next": "b",
			},
			"b": {
				"speaker": "Wounded climber",
				"text": "Don't. Look, I took it, alright? From people who'd have taken it from me. Just let me go.",
				"choices": [
					{ "text": "Patch them up and let them go.", "next": "help",
						"effects": [{ "route_points": { &"hero": 4 } }, { "set_flag": &"ch1_thief_helped" }] },
					{ "text": "Take the pouch and leave them.", "next": "rob",
						"effects": [{ "route_points": { &"villain": 4 } }, { "give_gold": 80 }, { "set_flag": &"ch1_thief_robbed" }] },
					{ "text": "Make them give it back to the people they robbed.", "next": "judge",
						"effects": [{ "route_points": { &"vigilante": 4 } }, { "set_flag": &"ch1_thief_judged" }] },
				],
			},
			"help": {
				"speaker": "{friend}",
				"text": "Soft. That's why I like you. Hope it doesn't get you killed.",
			},
			"rob": {
				"speaker": "{friend}",
				"text": "...Huh. Didn't think you had that in you. Guess the tower changes people fast.",
			},
			"judge": {
				"speaker": "{friend}",
				"text": "Marched them back down a floor yourself. Remind me never to owe you money.",
			},
		},
	},
	&"ch1_carving": {
		"start": [
			{ "if": { "flag": &"prologue_notebook" }, "node": "known" },
			{ "node": "a" },
		],
		"nodes": {
			"known": {
				"text": "A carving in the wall, old and worn: a tower, floor after floor, every one numbered. You've seen it before. Last night. On your own bookshelf.",
				"next": "b",
			},
			"a": {
				"text": "A carving in the wall, old and worn: a tower, floor after floor, every one numbered. Something about it pulls at you, like a song you can't name.",
				"next": "b",
			},
			"b": {
				"text": "Under it, cut deep into the stone in a child's careful letters: THE TOWER OF RECONGITION.",
				"next": "c",
			},
			"c": {
				"speaker": "{friend}",
				"text": "What are you staring at? It's just a wall. I've walked past it a hundred times.",
				"effects": [{ "set_flag": &"ch1_saw_carving" }],
			},
		},
	},
	&"ch1_fallen": {
		"start": [
			{ "if": { "flag": &"ch1_met_tess" }, "node": "a" },
			{ "node": "stranger" },
		],
		"nodes": {
			"a": {
				"text": "A red scarf on the stairs. Tess's party went up ahead of you. Tess is still here.",
				"next": "b",
			},
			"stranger": {
				"text": "A climber lies on the stairs, a red scarf around her neck. Her party went up without her.",
				"next": "b",
			},
			"b": {
				"text": "Monsters fade when they fall. She doesn't. You wait for her to vanish and wake at the last campfire, the way {friend} said. She doesn't.",
				"next": "c",
			},
			"c": {
				"speaker": "{friend}",
				"text": "...She'll be at the fire. That's how it works. That's how it always works.",
				"next": "d",
			},
			"d": {
				"text": "{friend} doesn't look at her again. Neither do you. The boss is waiting above.",
				"effects": [{ "set_flag": &"ch1_tess_fell" }],
			},
		},
	},
	&"ch1_end": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The boss falls. In the silence after, something vast turns its attention toward you, like a sun deciding where to shine.",
				"next": "b",
			},
			"b": {
				"speaker": "???",
				"text": "So you're the Tester.",
				"next": "c",
			},
			"c": {
				"speaker": "{friend}",
				"text": "Did you hear that? ...Tell me you heard that.",
				"next": "d",
			},
			"d": {
				"style": "system",
				"text": "[ Chapter 1 complete. ]",
				"next": "e",
			},
			"e": {
				"style": "glitch",
				"text": "[ You remembered faster this time. ]",
				"effects": [{ "set_flag": &"ch1_complete" }],
			},
		},
	},
}


static func get_dialogue(id: StringName) -> Dictionary:
	return DIALOGUES.get(id, {})


## Chapter number (1-based) for a floor: one per stage.
static func chapter_for_floor(n: int) -> int:
	return clampi((maxi(1, n) - 1) / StageLibrary.FLOORS_PER_STAGE + 1, 1, CHAPTERS.size())


## "Chapter 1: Tester".
static func chapter_name(chapter: int) -> String:
	var i := clampi(chapter, 1, CHAPTERS.size()) - 1
	return "Chapter %d: %s" % [i + 1, CHAPTERS[i].title]


static func seen_flag(id: StringName) -> StringName:
	return StringName("scene_%s" % id)


## The first story scene that should play now, or &"" for none.
## `guardian_down` = this floor had a miniboss/boss and it's beaten.
static func due(floor_n: int, guardian_down: bool) -> StringName:
	for id in SCENES:
		var s: Dictionary = SCENES[id]
		if GameState.has_flag(seen_flag(id)) or not floor_n in s.floors:
			continue
		if s.when == "guardian_down" and not guardian_down:
			continue
		if not DialogueRunner.check(s.get("if", {})):
			continue
		return id
	return &""


static func setup_question(id: StringName) -> Dictionary:
	for q in SETUP_QUESTIONS:
		if q.id == id:
			return q
	return {}


static func setup_option(question: StringName, option: StringName) -> Dictionary:
	for o in setup_question(question).get("options", []):
		if o.id == option:
			return o
	return {}


## "+2 Health" for an answer (the visible part; the nudge stays hidden).
static func option_hint(o: Dictionary) -> String:
	var parts: PackedStringArray = []
	for st in o.get("stats", {}):
		parts.append("+%d %s" % [o.stats[st], Stats.name_of(st)])
	return ", ".join(parts)


## Every problem in the story data ([] = all good). Run by the tests.
static func validate() -> PackedStringArray:
	var problems: PackedStringArray = []
	for id in DIALOGUES:
		if DialogueLibrary.DIALOGUES.has(id):
			problems.append("story dialogue %s clashes with a DialogueLibrary id" % id)
		problems.append_array(DialogueLibrary.validate(id, DIALOGUES[id]))
		for node_id in DIALOGUES[id].nodes:
			var style: String = DIALOGUES[id].nodes[node_id].get("style", "")
			if not style in STYLES:
				problems.append("%s/%s: unknown style '%s'" % [id, node_id, style])
	for obj in PROLOGUE_OBJECTS:
		if not DIALOGUES.has(StringName("prologue_%s" % obj)):
			problems.append("prologue object %s has no dialogue" % obj)
	for id in SCENES:
		var s: Dictionary = SCENES[id]
		if not DIALOGUES.has(s.get("dialogue", &"")):
			problems.append("scene %s: no dialogue '%s'" % [id, s.get("dialogue")])
		if not s.get("when", "") in ["enter", "guardian_down"]:
			problems.append("scene %s: unknown 'when' %s" % [id, s.get("when")])
		var ch: int = s.get("chapter", 0)
		if ch < 1 or ch > CHAPTERS.size():
			problems.append("scene %s: bad chapter %d" % [id, ch])
		for f in s.get("floors", []):
			if chapter_for_floor(f) != ch:
				problems.append("scene %s: floor %d isn't in chapter %d" % [id, f, ch])
			if s.when == "guardian_down" and not (StageLibrary.is_boss_floor(f) or StageLibrary.is_miniboss_floor(f)):
				problems.append("scene %s: floor %d has no guardian" % [id, f])
		if s.get("floors", []).is_empty():
			problems.append("scene %s: no floors" % id)
		problems.append_array(DialogueLibrary._validate_condition("scene %s" % id, s.get("if", {})))
	for q in SETUP_QUESTIONS:
		if q.get("options", []).size() < 2:
			problems.append("setup question %s needs options" % q.id)
		for o in q.get("options", []):
			for st in o.get("stats", {}):
				if not st in Stats.all():
					problems.append("setup %s/%s: unknown stat %s" % [q.id, o.id, st])
			for r in o.get("route_points", {}):
				if not RouteLibrary.routes.has(r):
					problems.append("setup %s/%s: unknown route %s" % [q.id, o.id, r])
			for b in o.get("interest", {}):
				if not BeingLibrary.beings.has(b):
					problems.append("setup %s/%s: unknown being %s" % [q.id, o.id, b])
				elif BeingLibrary.get_being(b).get("living", false):
					problems.append("setup %s/%s: keep living-religion figures out of the nudges" % [q.id, o.id])
	return problems
