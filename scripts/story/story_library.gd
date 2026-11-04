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
	{ "title": "The Bidding" },
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
	&"ch2_opening": { "chapter": 2, "floors": [11], "when": "enter", "dialogue": &"ch2_opening" },
	&"ch2_odin": { "chapter": 2, "floors": [12, 13], "when": "enter", "dialogue": &"ch2_odin" },
	&"ch2_loki": { "chapter": 2, "floors": [14], "when": "guardian_down", "dialogue": &"ch2_loki" },
	&"ch2_tess": { "chapter": 2, "floors": [15], "when": "enter", "dialogue": &"ch2_tess" },
	&"ch2_friday": { "chapter": 2, "floors": [16, 17], "when": "enter", "dialogue": &"ch2_friday" },
	&"ch2_envoy": { "chapter": 2, "floors": [18], "when": "enter", "dialogue": &"ch2_envoy" },
	&"ch2_session": { "chapter": 2, "floors": [19], "when": "guardian_down", "dialogue": &"ch2_session" },
	&"ch2_threshold": { "chapter": 2, "floors": [20], "when": "enter", "dialogue": &"ch2_threshold" },
	&"ch2_end": { "chapter": 2, "floors": [20], "when": "guardian_down", "dialogue": &"ch2_end" },
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
	# --- Chapter 2: The Bidding ---
	&"ch2_opening": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Chapter 2: The Bidding ]",
				"next": "b",
			},
			"b": {
				"text": "Word has climbed faster than you did. Two climbers stop talking when you pass. A third makes a sign against bad luck, then one for good luck, just in case.",
				"next": "c",
			},
			"c": {
				"speaker": "{friend}",
				"text": "They keep calling you \"the Tester\". Tester of what? Should I be worried, or should I be charging people to meet you?",
				"choices": [
					{ "text": "I don't know what it means either.", "next": "d", "effects": [{ "set_flag": &"ch2_told_unknown" }] },
					{ "text": "It's a long story. You wouldn't believe it.", "next": "e", "effects": [{ "set_flag": &"ch2_told_story" }] },
				],
			},
			"d": {
				"speaker": "{friend}",
				"text": "Well, whatever it is, the gods have heard. You can feel it, can't you? Like walking into a room where everybody just stopped arguing.",
			},
			"e": {
				"speaker": "{friend}",
				"text": "Twenty years and you've never once told me a story I believed. Doesn't stop you. Later, then. Over something that isn't trying to eat us.",
			},
		},
	},
	&"ch2_odin": {
		"start": [
			{ "if": { "blessed_by": &"odin" }, "node": "his" },
			{ "if": { "blessed": true }, "node": "marked" },
			{ "node": "a" },
		],
		"nodes": {
			"a": {
				"text": "The torches on this floor burn low all at once. A raven lands on nothing, and looks at you with one eye.",
				"next": "offer",
			},
			"marked": {
				"text": "The torches burn low all at once. A raven lands on nothing, and looks at the mark you carry with open distaste.",
				"next": "offer",
			},
			"his": {
				"speaker": "Odin",
				"portrait": "odin",
				"text": "Mine already, and still they whisper your name in other halls. Listen well, Tester. You are not the first I have watched climb.",
				"next": "first",
			},
			"offer": {
				"speaker": "Odin",
				"portrait": "odin",
				"text": "So you are the one they sent. I traded an eye to know what's coming, and I still did not see you. I would like to know why, and I pay for what I learn.",
				"choices": [
					{ "text": "Then tell me what you already know.", "next": "first",
						"effects": [{ "interest": { &"odin": 8, &"loki": -3 } }, { "set_flag": &"ch2_heard_odin" }] },
					{ "text": "I don't work for gods.", "next": "refuse",
						"effects": [{ "interest": { &"odin": -2 } }, { "set_flag": &"ch2_refused_odin" }] },
				],
			},
			"first": {
				"speaker": "Odin",
				"portrait": "odin",
				"text": "A small truth, then, as a down payment. There was a Tester before you. Nobody remembers how they ended. That is what should trouble you.",
				"next": "friend",
			},
			"refuse": {
				"speaker": "Odin",
				"portrait": "odin",
				"text": "Good. The ones who kneel at once are never worth the eye. I will ask again, when you've bled a little more.",
				"next": "friend",
			},
			"friend": {
				"speaker": "{friend}",
				"text": "Why did the torches do that? And why are you nodding at a bird?",
			},
		},
	},
	&"ch2_loki": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Miniboss defeated. ]",
				"next": "b",
			},
			"b": {
				"speaker": "Loki",
				"portrait": "loki",
				"text": "Lovely work. Don't get up. Has the old man been at you yet, with the one eye and the terribly serious voice? He'll want your whole life for one good answer.",
				"next": "c",
			},
			"c": {
				"speaker": "Loki",
				"portrait": "loki",
				"text": "Me, I'll give you the answer free, and you can owe me whatever you think it was worth. Everyone says that's a bad deal. Everyone's so dull.",
				"choices": [
					{ "text": "All right. What's the answer?", "next": "answer",
						"effects": [{ "interest": { &"loki": 8, &"odin": -3 } }, { "set_flag": &"ch2_heard_loki" }] },
					{ "text": "Why does everyone want me?", "next": "why",
						"effects": [{ "interest": { &"loki": 2 } }] },
					{ "text": "Get out of my head.", "next": "out",
						"effects": [{ "interest": { &"loki": -2 } }, { "set_flag": &"ch2_refused_loki" }] },
				],
			},
			"answer": {
				"speaker": "Loki",
				"portrait": "loki",
				"text": "The window you keep reading? Ask who's writing it. And ask why it's so very careful around you.",
				"next": "slip",
			},
			"why": {
				"speaker": "Loki",
				"portrait": "loki",
				"text": "Because you can leave, darling. Nobody else in this tower can. Imagine what we'd give to learn how.",
				"next": "slip",
			},
			"out": {
				"speaker": "Loki",
				"portrait": "loki",
				"text": "Oh, I like that. Say it again when you're less sure I'm in there.",
				"next": "slip",
			},
			"slip": {
				"style": "glitch",
				"text": "[ Do not listen to that one. ]",
				"next": "fix",
			},
			"fix": {
				"style": "system",
				"text": "[ Notice dismissed. ]",
				"effects": [{ "set_flag": &"ch2_system_warned" }],
			},
		},
	},
	&"ch2_tess": {
		"start": [
			{ "if": { "flag": &"ch1_met_tess" }, "node": "a" },
			{ "node": "stranger" },
		],
		"nodes": {
			"a": {
				"text": "The campfire on this floor is crowded. A bright red scarf. A voice you know, in the middle of a joke you've heard.",
				"next": "b",
			},
			"stranger": {
				"text": "The campfire on this floor is crowded. A bright red scarf, the one you saw on the stairs of floor 10. Its owner is telling a joke, and she is breathing.",
				"next": "b",
			},
			"b": {
				"speaker": "Tess",
				"text": "Reach the top and you become a god. Everyone knows that. I'm going to be the god of second breakfasts. Hi! I'm Tess. First time this high?",
				"next": "c",
			},
			"c": {
				"speaker": "{friend}",
				"text": "See? Told you. Back at the fire with a headache and a lighter purse. That's the tower.",
				"next": "d",
			},
			"d": {
				"text": "{friend} is smiling too hard. Tess looks at you the way you look at someone you have never met.",
				"choices": [
					{ "text": "Tess, what happened on floor 10?", "next": "ask", "effects": [{ "set_flag": &"ch2_asked_tess" }] },
					{ "text": "Say nothing. Find Marn.", "next": "marn", "effects": [{ "set_flag": &"ch2_found_marn" }] },
				],
			},
			"ask": {
				"speaker": "Tess",
				"text": "Floor 10? I've never been past 5. You all right? You look like you've seen a ghost. Here, have some of this, it's terrible.",
				"next": "marn",
			},
			"marn": {
				"text": "Marn sits at the far edge of the light with his back to her. He doesn't look up when you sit down.",
				"next": "marn2",
			},
			"marn2": {
				"speaker": "Marn",
				"text": "Fourth time I've met that girl. Same scarf. Same joke. I told you the tower doesn't give anyone back. I didn't say it doesn't send something.",
				"next": "marn3",
			},
			"marn3": {
				"speaker": "Marn",
				"text": "Don't tell your friend. Some things you can only know once.",
				"effects": [{ "set_flag": &"ch2_tess_returned" }],
			},
		},
	},
	&"ch2_friday": {
		"start": [
			{ "if": { "flag": &"prologue_phone" }, "node": "known" },
			{ "node": "unknown" },
		],
		"nodes": {
			"known": {
				"speaker": "{friend}",
				"text": "You coming out Friday? Everyone's asking.",
				"next": "known2",
			},
			"known2": {
				"text": "You stop walking. Those words, in that order. You read them on your phone, in your room, the night you logged in.",
				"next": "c",
			},
			"unknown": {
				"speaker": "{friend}",
				"text": "You coming out Friday? Everyone's asking.",
				"next": "unknown2",
			},
			"unknown2": {
				"text": "You stop walking. There was a message on your phone, the night you logged in. You never read it. You're suddenly certain this is what it said.",
				"next": "c",
			},
			"c": {
				"text": "{friend} has stopped too. For a moment their face is empty, like someone who walked into a room and forgot why.",
				"next": "d",
			},
			"d": {
				"speaker": "{friend}",
				"text": "...Why did I say that? What's Friday? Out where? There isn't an out. There's just up.",
				"choices": [
					{ "text": "Who told you to say that?", "next": "who", "effects": [{ "set_flag": &"ch2_friday_pressed" }] },
					{ "text": "It's nothing. You're tired.", "next": "lie", "effects": [{ "set_flag": &"ch2_friday_hid" }] },
					{ "text": "Tell them the truth about your phone.", "next": "truth", "effects": [{ "set_flag": &"ch2_friday_told" }] },
				],
			},
			"who": {
				"speaker": "{friend}",
				"text": "Nobody! It was just there, in my mouth, like when you know a song. Stop looking at me like that. Please.",
			},
			"lie": {
				"speaker": "{friend}",
				"text": "Yeah. Yeah, you're right. Long climb. ...You'd tell me, though. If it was something.",
			},
			"truth": {
				"text": "You tell them: the room, the phone, the message. They listen to all of it. They do not laugh.",
				"next": "truth2",
			},
			"truth2": {
				"speaker": "{friend}",
				"text": "I think I'd like you to stop talking now. I'm not angry. I just don't like how much of that sounded right.",
			},
		},
	},
	&"ch2_envoy": {
		"start": "a",
		"nodes": {
			"a": {
				"speaker": "Guild envoy",
				"text": "{floor_guild} sends its respects, Tester. Two gods have told our masters to hold you, and each has promised to ruin us if we hand you to the other.",
				"next": "b",
			},
			"b": {
				"speaker": "Guild envoy",
				"text": "We're not fools. We can't fight heaven, so we'd rather have you on our side when it starts. Name your terms.",
				"choices": [
					{ "text": "Keep the climbers on your floors safe, and I'll stand with you.", "next": "ally",
						"effects": [{ "route_points": { &"hero": 3 } }, { "floor_guild_rep": 8 }, { "set_flag": &"ch2_envoy_ally" }] },
					{ "text": "My terms are gold. Lots of it.", "next": "paid",
						"effects": [{ "route_points": { &"villain": 3 } }, { "give_gold": 200 }, { "floor_guild_rep": 2 }, { "set_flag": &"ch2_envoy_paid" }] },
					{ "text": "Tell your masters and their gods to bid somewhere else.", "next": "no",
						"effects": [{ "route_points": { &"vigilante": 3 } }, { "floor_guild_rep": -5 }, { "set_flag": &"ch2_envoy_refused" }] },
				],
			},
			"ally": {
				"speaker": "Guild envoy",
				"text": "Safe. Yes. We can certainly say that. You're an unusual sort of weapon, Tester.",
			},
			"paid": {
				"speaker": "Guild envoy",
				"text": "A language we speak. Consider this the first payment. There's always a second.",
			},
			"no": {
				"speaker": "Guild envoy",
				"text": "I'll carry that word for word. I'd start sleeping lightly, if I were you. I suspect you already do.",
			},
		},
	},
	&"ch2_session": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Miniboss defeated. ]",
				"next": "b",
			},
			"b": {
				"style": "glitch",
				"text": "[ Tester 0041: session active. ]\n[ Session length: 11,302 days. ]",
				"next": "c",
			},
			"c": {
				"style": "system",
				"text": "[ Display error. Disregard. ]",
				"next": "d",
			},
			"d": {
				"text": "It's gone before you can read it twice. You do the sum anyway. Eleven thousand days is thirty-one years.",
				"next": "e",
			},
			"e": {
				"speaker": "{friend}",
				"text": "You've gone white. Sit down a minute. Whatever it is, it'll still be trying to kill us after you've caught your breath.",
				"effects": [{ "set_flag": &"ch2_saw_session" }],
			},
		},
	},
	&"ch2_threshold": {
		"start": [
			{ "if": { "flag": &"ch2_friday_told" }, "node": "told" },
			{ "node": "a" },
		],
		"nodes": {
			"a": {
				"speaker": "{friend}",
				"text": "Whatever's up there, we go in together. We always have. That's the one part of my life I've never had to think about.",
				"next": "b",
			},
			"told": {
				"speaker": "{friend}",
				"text": "I've been thinking about what you said. About the room. If you've got somewhere else to be... no. Later. We go in together. That part I'm sure of.",
				"next": "b",
			},
			"b": {
				"text": "Above you, something enormous is waiting. Further above that, two old powers are holding very still, each hoping you'll look their way when it's over.",
			},
		},
	},
	&"ch2_end": {
		"start": [
			{ "if": { "flag": &"ch2_heard_odin", "not_flag": &"ch2_heard_loki" }, "node": "odin" },
			{ "if": { "flag": &"ch2_heard_loki", "not_flag": &"ch2_heard_odin" }, "node": "loki" },
			{ "node": "both" },
		],
		"nodes": {
			"odin": {
				"speaker": "Odin",
				"portrait": "odin",
				"text": "Well struck. Loki has been telling everyone you are his. I would prove him wrong, if I were you, and I would do it soon.",
				"next": "d",
			},
			"loki": {
				"speaker": "Loki",
				"portrait": "loki",
				"text": "That's my Tester! Oh, the old man's going to be sour about this. He'll send someone. I can hardly wait.",
				"next": "d",
			},
			"both": {
				"text": "The boss falls. A raven on the wreckage turns its one eye on you. Somewhere behind you, someone is slowly applauding. Neither of them says a word. They're both still bidding.",
				"next": "d",
			},
			"d": {
				"style": "system",
				"text": "[ Chapter 2 complete. ]\n[ Class advancement is open. Advance when you are ready. ]",
				"next": "e",
			},
			"e": {
				"style": "glitch",
				"text": "[ You will want to see home first. If you can. ]",
				"effects": [{ "set_flag": &"ch2_complete" }],
			},
		},
	},

	# --- The first return to the real world (first tier-2 advancement). ---
	&"return_tier2_pc": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The test client is still open. [ Session active. ] Under it, a clock you don't remember being there has been counting for nine days.",
				"choices": [
					{ "text": "Log back in.", "next": "in", "effects": [{ "set_flag": &"return_tier2_login" }] },
					{ "text": "Try to log off.", "next": "off", "effects": [{ "set_flag": &"return_tier2_tried_logoff" }],
						"if": { "not_flag": &"return_tier2_tried_logoff" } },
					{ "text": "Not yet." },
				],
			},
			"off": {
				"style": "system",
				"text": "[ Log off is not available during an active session. ]",
				"next": "a",
			},
			"in": {
				"style": "system",
				"text": "[ Resynchronising. ]",
			},
		},
	},
	&"return_tier2_notebook": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The notebook is open on the shelf. You left it closed. There's a new page after the last tower, in the same careful child's letters: a figure on floor 20, labelled {class}.",
				"next": "b",
			},
			"b": {
				"text": "The pencil is fresh enough to smudge on your thumb.",
			},
		},
	},
	&"return_tier2_phone": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "Eleven messages. \"Friday was good, shame you missed it.\" \"You okay?\" \"Seriously, call me.\" A final notice for the electric bill. The date says nine days have passed.",
				"next": "b",
			},
			"b": {
				"speaker": "You",
				"text": "(I sat down for one night. There's no way it's been nine days. ...Why am I not hungry?)",
			},
		},
	},
	&"return_tier2_window": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The city at night, exactly as you left it. The same siren, somewhere. Your reflection looks tired, and lifts its hand a moment after you do.",
			},
		},
	},
	# Back in the tower.
	&"return_tier2_back": {
		"start": "a",
		"nodes": {
			"a": {
				"speaker": "{friend}",
				"text": "Hey. HEY. You were gone for a second there. You just stopped, mid-step, like someone blew you out.",
				"next": "b",
			},
			"b": {
				"speaker": "{friend}",
				"text": "New look suits you, though. {class}, is it? Come on. It's a long way up, and I'm told you've got gods to disappoint.",
			},
		},
	},
}


## The real world comes back at milestones (Hayden 2026-11-04): the prologue
## room again, with its objects' dialogues named "<id>_<object>" and a talk
## "<id>_back" once you're back in the tower. Each plays once per run.
## Only the first is built: the first tier-2 advancement. New Game+ characters
## start past it, so it's first runs only.
const RETURN_TIER2 := &"return_tier2"


## The real-world return that's due now, or &"".
static func return_due() -> StringName:
	var gs := GameState
	if not gs.run_active or gs.ng_plus_cycle > 0 or gs.has_flag(RETURN_TIER2) or not gs.player.has_class():
		return &""
	return RETURN_TIER2 if gs.player.get_class_def().tier >= 2 else &""


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
		for prefix in ["prologue", RETURN_TIER2]:
			if not DIALOGUES.has(StringName("%s_%s" % [prefix, obj])):
				problems.append("%s object %s has no dialogue" % [prefix, obj])
	if not DIALOGUES.has(StringName("%s_back" % RETURN_TIER2)):
		problems.append("%s has no talk back in the tower" % RETURN_TIER2)
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
