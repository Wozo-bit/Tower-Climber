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
	{ "title": "What the Tower Sends" },
	{ "title": "The Second Hand" },
	{ "title": "(Chapter 5)" },
	{ "title": "(Chapter 6)" },
	{ "title": "(Chapter 7)" },
	{ "title": "(Chapter 8)" },
	{ "title": "(Chapter 9)" },
	{ "title": "(Chapter 10)" },
]
## A god climbing again has their own story, "The First Prayer" (story bible).
const GOD_CHAPTERS := [
	{ "title": "Nobody's God" },
	{ "title": "The Bidding" },
	{ "title": "Congregation" },
	{ "title": "Heresy" },
	{ "title": "The Queue" },
	{ "title": "The Last Prayer" },
	{ "title": "(God chapter 7)" },
	{ "title": "(God chapter 8)" },
	{ "title": "(God chapter 9)" },
	{ "title": "Who Gods Pray To" },
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
	&"god_first_prayer": { "chapter": 1, "floors": [3], "when": "enter", "dialogue": &"god_first_prayer", "if": { "god": true } },
	&"ch1_slip": { "chapter": 1, "floors": [4], "when": "guardian_down", "dialogue": &"ch1_slip" },
	&"ch1_legend": { "chapter": 1, "floors": [5], "when": "enter", "dialogue": &"ch1_legend" },
	&"ch1_thief": { "chapter": 1, "floors": [6, 7], "when": "enter", "dialogue": &"ch1_thief" },
	&"ch1_carving": { "chapter": 1, "floors": [8, 9], "when": "enter", "dialogue": &"ch1_carving" },
	&"god_petition": { "chapter": 1, "floors": [9], "when": "enter", "dialogue": &"god_petition", "if": { "god": true } },
	&"ch1_fallen": { "chapter": 1, "floors": [10], "when": "enter", "dialogue": &"ch1_fallen" },
	&"ch1_end": { "chapter": 1, "floors": [10], "when": "guardian_down", "dialogue": &"ch1_end" },
	&"ch2_opening": { "chapter": 2, "floors": [11], "when": "enter", "dialogue": &"ch2_opening" },
	&"god_davin": { "chapter": 2, "floors": [12], "when": "enter", "dialogue": &"god_davin", "if": { "god": true } },
	&"ch2_first_bid": { "chapter": 2, "floors": [12, 13], "when": "enter", "dialogue": &"ch2_first_bid" },
	&"god_ilse_thanks": { "chapter": 2, "floors": [13], "when": "enter", "dialogue": &"god_ilse_thanks",
		"if": { "god": true, "flag": &"god_davin_saved", "any_flag": [&"god_ilse_answered"] } },
	&"god_ilse_wrong": { "chapter": 2, "floors": [13], "when": "enter", "dialogue": &"god_ilse_wrong",
		"if": { "god": true, "flag": &"god_davin_saved", "not_flag": &"god_ilse_answered" } },
	&"god_chaplain": { "chapter": 2, "floors": [13], "when": "enter", "dialogue": &"god_chaplain",
		"if": { "god": true, "floor_guild_yours": false } },
	&"ch2_second_bid": { "chapter": 2, "floors": [14], "when": "guardian_down", "dialogue": &"ch2_second_bid" },
	&"ch2_tess": { "chapter": 2, "floors": [15], "when": "enter", "dialogue": &"ch2_tess" },
	&"ch2_friday": { "chapter": 2, "floors": [16, 17], "when": "enter", "dialogue": &"ch2_friday" },
	&"god_friend_prayer": { "chapter": 2, "floors": [17], "when": "enter", "dialogue": &"god_friend_prayer", "if": { "god": true } },
	&"ch2_envoy": { "chapter": 2, "floors": [18], "when": "enter", "dialogue": &"ch2_envoy" },
	&"ch2_session": { "chapter": 2, "floors": [19], "when": "guardian_down", "dialogue": &"ch2_session" },
	&"ch2_threshold": { "chapter": 2, "floors": [20], "when": "enter", "dialogue": &"ch2_threshold" },
	&"ch2_end": { "chapter": 2, "floors": [20], "when": "guardian_down", "dialogue": &"ch2_end" },
	# "The First Prayer" past floor 20: gods only, for now.
	&"ch3_opening": { "chapter": 3, "floors": [21], "when": "enter", "dialogue": &"ch3_opening" },
	&"ch3_warning": { "chapter": 3, "floors": [22, 23], "when": "enter", "dialogue": &"ch3_warning" },
	&"ch3_small_talk": { "chapter": 3, "floors": [24], "when": "guardian_down", "dialogue": &"ch3_small_talk" },
	&"ch3_ledger": { "chapter": 3, "floors": [25], "when": "enter", "dialogue": &"ch3_ledger" },
	&"ch3_door": { "chapter": 3, "floors": [26, 27], "when": "enter", "dialogue": &"ch3_door" },
	&"ch3_doubt": { "chapter": 3, "floors": [28], "when": "enter", "dialogue": &"ch3_doubt" },
	&"ch3_last_page": { "chapter": 3, "floors": [29], "when": "guardian_down", "dialogue": &"ch3_last_page" },
	&"ch3_brace": { "chapter": 3, "floors": [30], "when": "enter", "dialogue": &"ch3_brace" },
	&"ch3_end": { "chapter": 3, "floors": [30], "when": "guardian_down", "dialogue": &"ch3_end" },
	&"ch4_opening": { "chapter": 4, "floors": [31], "when": "enter", "dialogue": &"ch4_opening" },
	&"ch4_second_hand": { "chapter": 4, "floors": [32, 33], "when": "enter", "dialogue": &"ch4_second_hand" },
	&"ch4_comments": { "chapter": 4, "floors": [34], "when": "guardian_down", "dialogue": &"ch4_comments" },
	&"ch4_marn": { "chapter": 4, "floors": [35], "when": "enter", "dialogue": &"ch4_marn" },
	&"ch4_expected": { "chapter": 4, "floors": [36, 37], "when": "enter", "dialogue": &"ch4_expected" },
	&"ch4_summer": { "chapter": 4, "floors": [38], "when": "enter", "dialogue": &"ch4_summer" },
	&"ch4_first_name": { "chapter": 4, "floors": [39], "when": "guardian_down", "dialogue": &"ch4_first_name" },
	&"ch4_threshold": { "chapter": 4, "floors": [40], "when": "enter", "dialogue": &"ch4_threshold" },
	&"ch4_end": { "chapter": 4, "floors": [40], "when": "guardian_down", "dialogue": &"ch4_end" },
	&"god_ch3": { "chapter": 3, "floors": [21], "when": "enter", "dialogue": &"god_ch3", "if": { "god": true } },
	&"god_shrine": { "chapter": 3, "floors": [25], "when": "enter", "dialogue": &"god_shrine", "if": { "god": true } },
	&"god_reprisal": { "chapter": 3, "floors": [30], "when": "guardian_down", "dialogue": &"god_reprisal", "if": { "god": true } },
	&"god_ch4": { "chapter": 4, "floors": [31], "when": "enter", "dialogue": &"god_ch4", "if": { "god": true } },
	&"god_found_out": { "chapter": 4, "floors": [35], "when": "enter", "dialogue": &"god_found_out", "if": { "god": true } },
	&"god_heretic": { "chapter": 4, "floors": [40], "when": "enter", "dialogue": &"god_heretic", "if": { "god": true } },
	&"god_ch5": { "chapter": 5, "floors": [41], "when": "enter", "dialogue": &"god_ch5", "if": { "god": true } },
	&"god_queue": { "chapter": 5, "floors": [45], "when": "enter", "dialogue": &"god_queue", "if": { "god": true } },
	&"god_last_offer": { "chapter": 5, "floors": [50], "when": "guardian_down", "dialogue": &"god_last_offer", "if": { "god": true } },
	&"god_ch6": { "chapter": 6, "floors": [51], "when": "enter", "dialogue": &"god_ch6", "if": { "god": true } },
	&"god_last_prayer": { "chapter": 6, "floors": [55], "when": "enter", "dialogue": &"god_last_prayer", "if": { "god": true } },
	# The last stairs are floor 100 now (the old top, 60, is the false summit).
	&"god_top": { "chapter": 10, "floors": [100], "when": "enter", "dialogue": &"god_top", "if": { "god": true } },
	&"summit_false": { "chapter": 6, "floors": [60], "when": "guardian_down", "dialogue": &"summit_false" },
	&"final_tester": { "chapter": 10, "floors": [100], "when": "enter", "dialogue": &"final_tester", "if": { "ng_plus": false } },
	&"final_mimic": { "chapter": 10, "floors": [100], "when": "enter", "dialogue": &"final_mimic", "if": { "ng_plus": true } },
}

const DIALOGUES := {
	# --- Floor 60: the top isn't the top (Hayden 2026-11-04). ---
	&"summit_false": {
		"start": [
			{ "if": { "ng_plus": true }, "node": "again" },
			{ "node": "a" },
		],
		"nodes": {
			"a": {
				"text": "The boss falls. Beyond it, a door, exactly as every climber you ever met described it. This is the top. Everyone knows that.",
				"next": "b",
			},
			"b_alone": { "text": "That's it. You did it. There's nobody here to say so, so you say it yourself, and it doesn't sound like much.", "next": "c" },
			"f_alone": { "text": "You stand there for a long time. Did any of them actually get here? Did anyone come back down and tell them?", "effects": [{ "set_flag": &"false_summit_seen" }] },
			"b": {
				"alt": [{ "if": { "friend_away": true }, "node": "b_alone" }],
				"speaker": "{friend}",
				"text": "That's it. That's actually it. We did it. Open it, go on, I want to see what a god's face looks like when it's yours.",
				"next": "c",
			},
			"c": {
				"style": "system",
				"text": "[ Summit reached. ]",
				"next": "d",
			},
			"d": {
				"text": "The door opens on a landing, and more stairs. They go up farther than the torches do.",
				"next": "e",
			},
			"e": {
				"style": "glitch",
				"text": "[ Correction. 40 floors remain. ]",
				"next": "f",
			},
			"f": {
				"alt": [{ "if": { "friend_away": true }, "node": "f_alone" }],
				"speaker": "{friend}",
				"text": "...No. No, everyone said. Everyone who ever... Did any of them actually get here? Did anyone come back down and tell them?",
				"effects": [{ "set_flag": &"false_summit_seen" }],
			},
			"again": {
				"text": "The boss falls. The door. Last time you stood here, you still believed in it.",
				"next": "again2",
			},
			"again2": {
				"style": "glitch",
				"text": "[ 40 floors remain. You know what's up there. ]",
				"effects": [{ "set_flag": &"false_summit_seen" }],
			},
		},
	},
	# --- Floor 100: the end of the climb. First draft; the full story comes later. ---
	&"final_tester": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "No more stairs. A plain room, and someone sitting on the floor with their back to you, typing at nothing.",
				"next": "b",
			},
			"b": {
				"style": "system",
				"text": "[ Tester 0041: session active. ]\n[ Tester {player}: session active. ]",
				"next": "c",
			},
			"c": {
				"speaker": "Tester 0041",
				"text": "You remembered faster than I did. I told it you would. Did it tell you the door would be up here? It told me that. I've been keeping it shut for a long time.",
				"choices": [
					{ "text": "Let me through.", "next": "d", "effects": [{ "set_flag": &"final_asked" }] },
					{ "text": "Who sent you?", "next": "e", "effects": [{ "set_flag": &"final_questioned" }] },
				],
			},
			"d": {
				"speaker": "Tester 0041",
				"text": "No. I'm sorry. It chose me for this the way it chose you for that. Get up, then. Show me what thirty-one years was for.",
			},
			"e": {
				"speaker": "Tester 0041",
				"text": "The one who built all this. It doesn't fight. It sponsors, like the rest of them. I'm what it paid for. Get up, then. Show me what thirty-one years was for.",
			},
		},
	},
	&"final_mimic": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "No more stairs. A plain room, and someone sitting on the floor with their back to you. They stand up. You know how they stand up.",
				"next": "b",
			},
			"b": {
				"style": "glitch",
				"text": "[ Tester {player}: session active. ]\n[ Tester {player}: session active. ]",
				"next": "c",
			},
			"c": {
				"speaker": "{player}?",
				"text": "It kept me. It always keeps the one who gets here. You'll understand when you win. Come on. You know all my moves, and I know all of yours.",
			},
		},
	},
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
			{ "if": { "god": true, "min_cycle": 2 }, "node": "god_cycle" },
			{ "if": { "god": true }, "node": "god_a" },
			{ "if": { "ng_plus": true }, "node": "again" },
			{ "node": "a" },
		],
		"nodes": {
			"god_cycle": {
				"text": "Cold stone. Torchlight. Everyone who ever prayed to you has gone back to never having heard of you. You've started to know what that sounds like.",
				"next": "god_b",
			},
			"god_a": {
				"text": "Cold stone. Torchlight. You remember the top of the tower. You remember what it made you. And here you are at the bottom, with a sore neck.",
				"next": "god_b",
			},
			"god_b": {
				"speaker": "{friend}",
				"text": "You fell asleep on watch again. ...Why are you looking at me like that?",
				"next": "god_c",
			},
			"god_c": {
				"style": "system",
				"text": "[ Deity registered: {god_title}. ]\n[ Worshippers: 0. ]",
				"next": "god_d",
			},
			"god_d": {
				"text": "So that's the catch. The tower keeps its promise, and a god nobody prays to is only a title. Nobody down here has ever heard of you.",
				"next": "god_e",
			},
			"god_e": {
				"style": "system",
				"text": "[ Chapter 1: Nobody's God ]",
			},
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
		"start": [
			{ "if": { "ng_plus": true }, "node": "again" },
			{ "node": "a" },
		],
		"nodes": {
			"alone": { "text": "The stairs are quiet. Your knee aches where you split it, falling off a fence when you were nine. Scratched into the wall at ankle height, in a hand you don't know: a ladder, a water tower, two stick figures.", "next": "alone2" },
			"alone2": { "text": "You've known {friend} for about an hour, and you sent them away. You don't know why the quiet feels like your fault.", "effects": [{ "set_flag": &"ch1_memory_alone" }] },
			"again": {
				"alt": [{ "if": { "friend_away": true }, "node": "alone" }],
				"speaker": "{friend}",
				"text": "This climb reminds me of the old water tower behind the mill. Remember? You froze at the top and I had to talk you down.",
				"next": "again2",
			},
			"again2": {
				"text": "You know this story. You heard it on this floor, in this voice, a whole tower ago. There was no water tower last time either.",
				"choices": [
					{ "text": "Finish it for them: \"I split my knee on the ladder and cried the whole way home.\"", "next": "finish",
						"effects": [{ "set_flag": &"ch1_memory_finished" }] },
					{ "text": "Let them tell it.", "next": "along", "effects": [{ "set_flag": &"ch1_memory_along" }] },
					{ "text": "\"What happened to the water tower?\"", "next": "tower", "effects": [{ "set_flag": &"ch1_memory_asked" }] },
				],
			},
			"finish": {
				"speaker": "{friend}",
				"text": "And you made me swear not to tell anyone, and I never did! So you DO remember. I was starting to think you'd hit your head.",
				"next": "finish2",
			},
			"finish2": {
				"text": "They're so pleased. You remember being the one who had no idea what they were talking about. You liked that person.",
			},
			"tower": {
				"speaker": "{friend}",
				"text": "...Huh. I don't know. It's just there, when I think about it. It's always just there. Why would you ask me that?",
			},
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "alone" }],
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
		"start": [
			{ "if": { "god": true }, "node": "god_a" },
			{ "if": { "ng_plus": true }, "node": "again" },
			{ "node": "a" },
		],
		"nodes": {
			"c_alone": { "text": "{friend} would have asked if you'd said something. {friend} isn't here.", "next": "c_alone2" },
			"c_alone2": { "style": "system", "text": "[ {friend}: not in party. ]", "next": "c_alone3" },
			"c_alone3": { "style": "glitch", "text": "[ Noted. ]", "effects": [{ "set_flag": &"ch1_slip_alone" }] },
			"god_a": {
				"style": "system",
				"text": "[ Miniboss defeated. ]\n[ Deities do not require grading. ]",
				"next": "god_b",
			},
			"god_b": {
				"style": "glitch",
				"text": "[ ...Adequate. ]",
				"next": "c",
			},
			"again": {
				"style": "system",
				"text": "[ Miniboss defeated. ]",
				"next": "again2",
			},
			"again2": {
				"style": "glitch",
				"text": "[ Still adequate. ]",
				"next": "c",
			},
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
				"alt": [{ "if": { "friend_away": true }, "node": "c_alone" }],
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
		"start": [
			{ "if": { "ng_plus": true, "flag": &"past_warned_tess" }, "node": "again_saved" },
			{ "if": { "ng_plus": true }, "node": "again" },
			{ "node": "a" },
		],
		"nodes": {
			"d_alone": { "speaker": "Tess", "text": "Don't listen to him. You go down, you wake up at the last fire. Bit of a headache, lighter purse. That's the tower. Everyone says. ...Didn't you come in with someone?", "next": "e" },
			"again_saved": {
				"text": "The same campfire. The same red scarf. You saved her last time. The tower put her back anyway, and she has never heard of you.",
				"next": "again2",
			},
			"again": {
				"text": "The same campfire. The same red scarf. You know what Tess is about to say, and you know what's waiting for her on floor 10.",
				"next": "again2",
			},
			"again2": {
				"speaker": "Tess",
				"text": "Reach the top and you become a god. Everyone knows that. I'm going to be the god of second breakfasts.",
				"next": "again3",
			},
			"again3": {
				"text": "Nobody at this fire can tell you it's a bad idea to say something. Nobody at this fire knows there's anything to say.",
				"choices": [
					{ "text": "\"When you get to the stairs on ten, let the others go first. Wait for me.\"", "next": "warn",
						"effects": [{ "set_flag": &"ch1_warned_tess" }] },
					{ "text": "Say nothing. It isn't your story.", "next": "quiet", "effects": [{ "set_flag": &"ch1_kept_quiet" }] },
				],
			},
			"warn": {
				"speaker": "Tess",
				"text": "Ha! Is that a threat or a fortune? ...You've got a look on you. All right. All right, maybe I'll let them go first.",
				"next": "again4",
			},
			"quiet": {
				"text": "She goes on talking. Marn watches you not say it.",
				"next": "again4",
			},
			"again4": {
				"speaker": "Marn",
				"text": "You've got the face of someone who's read the last page. Don't tell me how it ends.",
				"effects": [{ "set_flag": &"ch1_met_tess" }],
			},
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
				"alt": [{ "if": { "friend_away": true }, "node": "d_alone" }],
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
			"help_alone": { "text": "They stare at you. \"Why?\" You don't have an answer. {friend} would have had one, and made it sound like an insult." },
			"rob_alone": { "text": "The pouch is heavier than it looks. Nobody who knows you saw that. You notice you checked." },
			"judge_alone": { "text": "You march them back down a floor yourself. {friend} would have had a joke about it. You try to think what it would have been." },
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
				"alt": [{ "if": { "friend_away": true }, "node": "help_alone" }],
				"speaker": "{friend}",
				"text": "Soft. That's why I like you. Hope it doesn't get you killed.",
			},
			"rob": {
				"alt": [{ "if": { "friend_away": true }, "node": "rob_alone" }],
				"speaker": "{friend}",
				"text": "...Huh. Didn't think you had that in you. Guess the tower changes people fast.",
			},
			"judge": {
				"alt": [{ "if": { "friend_away": true }, "node": "judge_alone" }],
				"speaker": "{friend}",
				"text": "Marched them back down a floor yourself. Remind me never to owe you money.",
			},
		},
	},
	&"ch1_carving": {
		"start": [
			{ "if": { "ng_plus": true }, "node": "again" },
			{ "if": { "flag": &"prologue_notebook" }, "node": "known" },
			{ "node": "a" },
		],
		"nodes": {
			"c_alone": { "text": "You stand there until your legs ache. Nobody asks what you're staring at. {friend} would have.", "effects": [{ "set_flag": &"ch1_saw_carving" }] },
			"again": {
				"text": "The carving again: a tower, floor after floor, every one numbered. You look closer this time. Right at the top, scratched by the same hand, there's a very small figure you never noticed.",
				"next": "b",
			},
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
				"alt": [{ "if": { "friend_away": true }, "node": "c_alone" }],
				"speaker": "{friend}",
				"text": "What are you staring at? It's just a wall. I've walked past it a hundred times.",
				"effects": [{ "set_flag": &"ch1_saw_carving" }],
			},
		},
	},
	&"ch1_fallen": {
		"start": [
			{ "if": { "flag": &"ch1_warned_tess" }, "node": "saved" },
			{ "if": { "ng_plus": true, "flag": &"ch1_met_tess" }, "node": "knew" },
			{ "if": { "flag": &"ch1_met_tess" }, "node": "a" },
			{ "node": "stranger" },
		],
		"nodes": {
			"saved_alone": { "text": "You're smiling, you realise, with something enormous waiting above you. {friend} would have told you how that looks.", "effects": [{ "set_flag": &"ch1_tess_turned_back" }] },
			"b_alone": { "text": "Monsters fade when they fall. She doesn't. You wait for her to vanish and wake at the last campfire, the way everyone says. She doesn't.", "next": "c_alone" },
			"c_alone": { "text": "Everyone says she'll be at the fire. The one person who'd have said it to your face is at a fire already, a long way from here.", "next": "d_alone" },
			"d_alone": { "text": "You don't look at her again. The boss is waiting above.", "effects": [{ "set_flag": &"ch1_tess_fell" }] },
			"saved": {
				"text": "A red scarf on the stairs. No blood. It's tied to the rail in a big clumsy knot, with a scrap of paper pushed through it: \"FINE. I'll wait below. You had better be right.\"",
				"next": "saved2",
			},
			"saved2": {
				"text": "Her party went up ahead of her. You can see what's left of them, higher on the stairs. You untie the scarf and put it in your pack.",
				"next": "saved3",
			},
			"saved3": {
				"alt": [{ "if": { "friend_away": true }, "node": "saved_alone" }],
				"speaker": "{friend}",
				"text": "Whose is that? ...Why are you smiling? There's something enormous up there.",
				"effects": [{ "set_flag": &"ch1_tess_turned_back" }],
			},
			"knew": {
				"text": "A red scarf on the stairs. Tess's party went up ahead of you. Tess is still here. You knew she would be.",
				"next": "knew2",
			},
			"knew2": {
				"text": "You had a whole campfire's worth of time to say something.",
				"next": "c",
			},
			"a": {
				"text": "A red scarf on the stairs. Tess's party went up ahead of you. Tess is still here.",
				"next": "b",
			},
			"stranger": {
				"text": "A climber lies on the stairs, a red scarf around her neck. Her party went up without her.",
				"next": "b",
			},
			"b": {
				"alt": [{ "if": { "friend_away": true }, "node": "b_alone" }],
				"text": "Monsters fade when they fall. She doesn't. You wait for her to vanish and wake at the last campfire, the way {friend} said. She doesn't.",
				"next": "c",
			},
			"c": {
				"alt": [{ "if": { "friend_away": true }, "node": "c_alone" }],
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
		"start": [
			{ "if": { "ng_plus": true, "past_patron": "speaks" }, "node": "old" },
			{ "if": { "ng_plus": true, "past_patron": "silent" }, "node": "warm" },
			{ "if": { "ng_plus": true }, "node": "back" },
			{ "node": "a" },
		],
		"nodes": {
			"c_alone": { "text": "You look round before you can stop yourself. {friend} isn't there to ask if they heard it too.", "next": "d" },
			"friend_alone": { "text": "You look round before you can stop yourself. {friend} isn't there to ask if they heard it too.", "next": "done" },
			"old": {
				"text": "The boss falls. In the silence after, something you once knew very well turns its attention toward you.",
				"next": "old2",
			},
			"old2": {
				"speaker": "{old_patron}",
				"portrait": "{old_patron_id}",
				"text": "{patron.remember}",
				"choices": [
					{ "text": "I remember what I owe you.", "next": "friend", "effects": [{ "patron_interest": 5 }, { "set_flag": &"ch1_patron_thanked" }] },
					{ "text": "I owe you nothing.", "next": "friend", "effects": [{ "patron_interest": -5 }, { "set_flag": &"ch1_patron_refused" }] },
				],
			},
			"warm": {
				"text": "The boss falls. In the silence after, you feel an old warmth at your back: {old_patron}, whose blessing you carried once. It asks nothing. It stays a moment, and then it's gone.",
				"next": "friend",
			},
			"back": {
				"text": "The boss falls. In the silence after, something vast turns its attention toward you, and stops, like someone looking twice.",
				"next": "back2",
			},
			"back2": {
				"speaker": "???",
				"text": "So you came back. Nobody comes back.",
				"next": "friend",
			},
			"friend": {
				"alt": [{ "if": { "friend_away": true }, "node": "friend_alone" }],
				"speaker": "{friend}",
				"text": "Did you hear that? ...Tell me you heard that.",
				"next": "done",
			},
			"done": {
				"style": "system",
				"text": "[ Chapter 1 complete. ]{worshippers_line}",
				"next": "e",
			},
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
				"alt": [{ "if": { "friend_away": true }, "node": "c_alone" }],
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
		"start": [
			{ "if": { "god": true }, "node": "god_a" },
			{ "if": { "ng_plus": true }, "node": "again" },
			{ "node": "a" },
		],
		"nodes": {
			"c_alone": { "text": "\"The Tester,\" they call you. {friend} would have made a joke of it, and charged people to meet you. Without that, it only sounds like a job.", "effects": [{ "set_flag": &"ch2_told_unknown" }] },
			"god_a": {
				"style": "system",
				"text": "[ Chapter 2: The Bidding ]{worshippers_line}",
				"next": "god_b",
			},
			"god_b": {
				"text": "Word has climbed ahead of you again. Last time they stopped talking when you passed. This time someone has scratched \"{god_title}\" on a wall, and two climbers are arguing about what it means.",
				"next": "c",
			},
			"again": {
				"style": "system",
				"text": "[ Chapter 2: The Bidding ]",
				"next": "again2",
			},
			"again2": {
				"text": "Word has climbed ahead of you again. You know how this goes: two climbers stop talking, and a third makes a sign against bad luck, then one for good luck. You nod to the third one. It doesn't help.",
				"next": "c",
			},
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
				"alt": [{ "if": { "friend_away": true }, "node": "c_alone" }],
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
	&"ch2_first_bid": {
		"start": [
			{ "if": { "ng_plus": true, "flag": &"past_heard_first" }, "node": "re_yes" },
			{ "if": { "ng_plus": true, "flag": &"past_refused_first" }, "node": "re_no" },
			{ "if": { "ng_plus": true }, "node": "re_new" },
			{ "if": { "blessed_by_bid": &"first" }, "node": "his" },
			{ "if": { "blessed": true }, "node": "marked" },
			{ "node": "a" },
		],
		"nodes": {
			"friend_alone": { "text": "You come back to yourself on the stairs. You were nodding at nothing. {friend} would have had something to say about that." },
			"re_yes": { "speaker": "{bid1}", "portrait": "{bid1_id}", "text": "{bid1.recall_yes}", "next": "re_offer" },
			"re_no": { "speaker": "{bid1}", "portrait": "{bid1_id}", "text": "{bid1.recall_no}", "next": "re_offer" },
			"re_new": { "text": "{bid1.omen}", "next": "re_offer" },
			"re_offer": {
				"speaker": "{bid1}",
				"portrait": "{bid1_id}",
				"text": "{bid1.ng_offer}",
				"choices": [
					{ "text": "Go on. I'm listening.", "next": "re_heard",
						"effects": [{ "bid_interest": { "first": 6, "second": -2 } }, { "set_flag": &"ch2_heard_first" }, { "set_flag": &"ng_sided_first" }] },
					{ "text": "I don't answer to you.", "next": "re_refused",
						"effects": [{ "bid_interest": { "first": -3 } }, { "set_flag": &"ch2_refused_first" }] },
				],
			},
			"re_heard": { "speaker": "{bid1}", "portrait": "{bid1_id}", "text": "{bid1.yes}", "next": "friend" },
			"re_refused": { "speaker": "{bid1}", "portrait": "{bid1_id}", "text": "{bid1.no}", "next": "friend" },
			"a": { "text": "{bid1.omen}", "next": "offer" },
			"marked": { "text": "{bid1.marked}", "next": "offer" },
			"his": { "speaker": "{bid1}", "portrait": "{bid1_id}", "text": "{bid1.his}", "next": "friend" },
			"offer": {
				"speaker": "{bid1}",
				"portrait": "{bid1_id}",
				"text": "{bid1.offer}",
				"choices": [
					{ "text": "Then tell me what you already know.", "next": "truth",
						"effects": [{ "bid_interest": { "first": 8, "second": -3 } }, { "set_flag": &"ch2_heard_first" }] },
					{ "text": "I don't work for gods.", "next": "refuse",
						"effects": [{ "bid_interest": { "first": -2 } }, { "set_flag": &"ch2_refused_first" }] },
				],
			},
			"truth": { "speaker": "{bid1}", "portrait": "{bid1_id}", "text": "{bid1.truth}", "next": "friend" },
			"refuse": { "speaker": "{bid1}", "portrait": "{bid1_id}", "text": "{bid1.refuse}", "next": "friend" },
			"friend": {
				"alt": [{ "if": { "friend_away": true }, "node": "friend_alone" }],
				"speaker": "{friend}",
				"text": "You went somewhere just now. You were nodding at nothing. Please tell me that's a thing people do.",
			},
		},
	},
	&"ch2_second_bid": {
		"start": [
			{ "if": { "ng_plus": true, "flag": &"past_heard_second" }, "node": "re_yes" },
			{ "if": { "ng_plus": true, "flag": &"past_refused_second" }, "node": "re_no" },
			{ "if": { "ng_plus": true }, "node": "re_new" },
			{ "node": "a" },
		],
		"nodes": {
			"re_yes": { "speaker": "{bid2}", "portrait": "{bid2_id}", "text": "{bid2.recall_yes}", "next": "re_offer" },
			"re_no": { "speaker": "{bid2}", "portrait": "{bid2_id}", "text": "{bid2.recall_no}", "next": "re_offer" },
			"re_new": { "speaker": "{bid2}", "portrait": "{bid2_id}", "text": "{bid2.hook}", "next": "re_offer" },
			"re_offer": {
				"speaker": "{bid2}",
				"portrait": "{bid2_id}",
				"text": "{bid2.ng_offer}",
				"choices": [
					{ "text": "Go on. I'm listening.", "next": "re_heard",
						"effects": [{ "bid_interest": { "second": 6, "first": -2 } }, { "set_flag": &"ch2_heard_second" }, { "set_flag": &"ng_sided_second" }] },
					{ "text": "I don't answer to you.", "next": "re_refused",
						"effects": [{ "bid_interest": { "second": -3 } }, { "set_flag": &"ch2_refused_second" }] },
				],
			},
			"re_heard": { "speaker": "{bid2}", "portrait": "{bid2_id}", "text": "{bid2.yes}", "next": "re_slip" },
			"re_refused": { "speaker": "{bid2}", "portrait": "{bid2_id}", "text": "{bid2.no}", "next": "re_slip" },
			"re_slip": { "style": "glitch", "text": "[ I told you not to listen to that one. ]", "next": "fix" },
			"a": { "style": "system", "text": "[ Miniboss defeated. ]", "next": "b" },
			"b": { "speaker": "{bid2}", "portrait": "{bid2_id}", "text": "{bid2.hook}", "next": "c" },
			"c": {
				"speaker": "{bid2}",
				"portrait": "{bid2_id}",
				"text": "{bid2.offer}",
				"choices": [
					{ "text": "All right. What's the answer?", "next": "answer",
						"effects": [{ "bid_interest": { "second": 8, "first": -3 } }, { "set_flag": &"ch2_heard_second" }] },
					{ "text": "Why does everyone want me?", "next": "why",
						"effects": [{ "bid_interest": { "second": 2 } }] },
					{ "text": "Get out of my head.", "next": "out",
						"effects": [{ "bid_interest": { "second": -2 } }, { "set_flag": &"ch2_refused_second" }] },
				],
			},
			"answer": { "speaker": "{bid2}", "portrait": "{bid2_id}", "text": "{bid2.answer}", "next": "slip" },
			"why": { "speaker": "{bid2}", "portrait": "{bid2_id}", "text": "{bid2.why}", "next": "slip" },
			"out": { "speaker": "{bid2}", "portrait": "{bid2_id}", "text": "{bid2.out}", "next": "slip" },
			"slip": { "style": "glitch", "text": "[ Do not listen to that one. ]", "next": "fix" },
			"fix": {
				"style": "system",
				"text": "[ Notice dismissed. ]",
				"effects": [{ "set_flag": &"ch2_system_warned" }],
			},
		},
	},
	&"ch2_tess": {
		"start": [
			{ "if": { "flag": &"ch1_tess_turned_back" }, "node": "real" },
			{ "if": { "ng_plus": true, "flag": &"ch1_met_tess" }, "node": "again" },
			{ "if": { "flag": &"ch1_met_tess" }, "node": "a" },
			{ "node": "stranger" },
		],
		"nodes": {
			"d_alone": { "text": "{friend} told you this is how it works: back at the fire, with a headache and a lighter purse. {friend} isn't here to see it. Tess looks at you the way you look at someone you have never met.", "choices": [{ "text": "Tess, what happened on floor 10?", "next": "ask", "effects": [{ "set_flag": &"ch2_asked_tess" }] }, { "text": "Say nothing. Find Marn.", "next": "marn", "effects": [{ "set_flag": &"ch2_found_marn" }] }] },
			"marn3_alone": { "speaker": "Marn", "text": "Good thing your friend's not with you. Some things you can only know once.", "effects": [{ "set_flag": &"ch2_tess_returned" }] },
			"real": {
				"text": "The campfire on this floor is crowded. Someone grabs your sleeve: no scarf, a fresh burn across one hand, and eyes that haven't slept.",
				"next": "real2",
			},
			"real2": {
				"speaker": "Tess",
				"text": "You. The one from the fire. You told me to wait, so I waited, and my whole party went up without me, and they didn't come back. How did you know? Who ARE you?",
				"choices": [
					{ "text": "\"I've climbed this tower before.\"", "next": "real_told", "effects": [{ "set_flag": &"ch2_tess_told" }] },
					{ "text": "Say nothing. Hand her the scarf.", "next": "real_scarf", "effects": [{ "set_flag": &"ch2_tess_scarf" }] },
				],
			},
			"real_told": {
				"speaker": "Tess",
				"text": "...You know that's not an answer. It's only that you're the first person who's ever looked as scared as I feel.",
				"next": "real_scarf",
			},
			"real_scarf": {
				"speaker": "Tess",
				"text": "Forget second breakfasts. I'm going to be the god of people who waited on the stairs. It's a small congregation. Very punctual.",
				"next": "marn_real",
			},
			"marn_real": {
				"text": "Marn has turned all the way around. He's staring at her as if she'd grown a second head.",
				"next": "marn_real2",
			},
			"marn_real2": {
				"speaker": "Marn",
				"text": "Fifth time I've met that girl. First time I've ever heard a different joke. What did you do?",
				"next": "marn_real3",
			},
			"marn_real3": {
				"speaker": "Marn",
				"text": "No. Don't tell me. If it can be changed, then a lot of old men have a lot to answer for.",
				"effects": [{ "set_flag": &"ch2_tess_real" }],
			},
			"again": {
				"text": "The campfire on this floor is crowded. A bright red scarf. A voice you know, in the middle of a joke you know. You did nothing, and here she is anyway.",
				"next": "again2",
			},
			"again2": {
				"speaker": "Tess",
				"text": "Reach the top and you become a god. Everyone knows that. I'm going to be the god of second breakfasts. Hi! I'm Tess. First time this high?",
				"next": "again3",
			},
			"again3": {
				"speaker": "Tess",
				"text": "...Sorry, have we met? Someone was supposed to tell me something. I keep thinking that. Isn't that funny?",
				"next": "c",
			},
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
				"alt": [{ "if": { "friend_away": true }, "node": "d_alone" }],
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
				"alt": [{ "if": { "friend_away": true }, "node": "marn3_alone" }],
				"speaker": "Marn",
				"text": "Don't tell your friend. Some things you can only know once.",
				"effects": [{ "set_flag": &"ch2_tess_returned" }],
			},
		},
	},
	&"ch2_friday": {
		"start": [
			{ "if": { "ng_plus": true }, "node": "again" },
			{ "if": { "flag": &"prologue_phone" }, "node": "known" },
			{ "node": "unknown" },
		],
		"nodes": {
			"stranger": { "speaker": "A climber on the stairs", "text": "You coming out Friday? Everyone's asking.", "next": "stranger2" },
			"stranger2": { "text": "You stop walking. The message on your phone, the night you logged in. Those words, in that order, from someone you've never seen. Their face has gone empty, like someone who walked into a room and forgot why.", "next": "stranger3" },
			"stranger3": { "speaker": "A climber on the stairs", "text": "...Sorry. Did I say something? Do I know you?", "next": "stranger4" },
			"stranger4": { "text": "They blink and keep walking. You'd wondered about {friend}, and what was wrong with them. It was never about {friend}. The words only needed a mouth.", "effects": [{ "set_flag": &"ch2_friday_stranger" }] },
			"again": {
				"alt": [{ "if": { "friend_away": true }, "node": "stranger" }],
				"speaker": "{friend}",
				"text": "You coming out Friday? Everyone's asking.",
				"next": "again2",
			},
			"again2": {
				"text": "You knew it was coming. You'd been counting the floors. It doesn't help. Those words, in that order, and not one of them belongs to {friend}.",
				"next": "c",
			},
			"known": {
				"alt": [{ "if": { "friend_away": true }, "node": "stranger" }],
				"speaker": "{friend}",
				"text": "You coming out Friday? Everyone's asking.",
				"next": "known2",
			},
			"known2": {
				"text": "You stop walking. Those words, in that order. You read them on your phone, in your room, the night you logged in.",
				"next": "c",
			},
			"unknown": {
				"alt": [{ "if": { "friend_away": true }, "node": "stranger" }],
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
		"start": [
			{ "if": { "ng_plus": true }, "node": "again" },
			{ "node": "a" },
		],
		"nodes": {
			"e_alone": { "text": "You sit down on the stairs until the numbers stop swimming. {friend} would have told you to.", "next": "e_alone2" },
			"e_alone2": { "style": "glitch", "text": "[ I don't mind the company. ]", "next": "e_alone3" },
			"e_alone3": { "style": "system", "text": "[ Disregard. ]", "effects": [{ "set_flag": &"ch2_saw_session" }] },
			"again": {
				"style": "system",
				"text": "[ Miniboss defeated. ]",
				"next": "again2",
			},
			"again2": {
				"style": "glitch",
				"text": "[ Tester 0041: session active. ]\n[ Session length: 11,302 days. ]\n\n[ Tester 0042: session active. ]\n[ Climb: {cycle}. ]",
				"next": "again3",
			},
			"again3": {
				"style": "system",
				"text": "[ Display error. Disregard. ]",
				"next": "again4",
			},
			"again4": {
				"text": "There's a second line now. Nobody ever told you your number. You didn't know you had one to be told.",
				"next": "e",
			},
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
				"alt": [{ "if": { "friend_away": true }, "node": "e_alone" }],
				"speaker": "{friend}",
				"text": "You've gone white. Sit down a minute. Whatever it is, it'll still be trying to kill us after you've caught your breath.",
				"effects": [{ "set_flag": &"ch2_saw_session" }],
			},
		},
	},
	&"ch2_threshold": {
		"start": [
			{ "if": { "flag": &"god_told_friend" }, "node": "told_god" },
			{ "if": { "flag": &"ch2_friday_told" }, "node": "told" },
			{ "node": "a" },
		],
		"nodes": {
			"alone": { "text": "Whatever's up there, you go in without {friend}. You've gone in without them for floors now. It's the first time you've had to think about it.", "next": "alone2" },
			"alone2": { "style": "glitch", "text": "[ Go on. I am here. ]", "next": "b" },
			"behind": { "speaker": "{friend}", "text": "I don't know what happened while I was gone, and you're not going to tell me. Fine. We go in together. I'd just like to be asked, next time.", "next": "b" },
			"caught_up": { "speaker": "{friend}", "text": "You told me what I missed, and I believed about half of it. We go in together. That's the half I'm sure of.", "next": "b" },
			"told_god": {
				"alt": [{ "if": { "friend_away": true }, "node": "alone" }],
				"speaker": "{friend}",
				"text": "So I've been praying to someone who still owes me four silver. We go in together. I'd just like it noted that I'd have been a lot less polite if I'd known it was you.",
				"next": "b",
			},
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "alone" }, { "if": { "flag": &"friend_not_told" }, "node": "behind" }, { "if": { "flag": &"friend_caught_up" }, "node": "caught_up" }],
				"speaker": "{friend}",
				"text": "Whatever's up there, we go in together. We always have. That's the one part of my life I've never had to think about.",
				"next": "b",
			},
			"told": {
				"alt": [{ "if": { "friend_away": true }, "node": "alone" }, { "if": { "flag": &"friend_not_told" }, "node": "behind" }, { "if": { "flag": &"friend_caught_up" }, "node": "caught_up" }],
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
			{ "if": { "ng_plus": true }, "node": "again" },
			{ "if": { "flag": &"ch2_heard_first", "not_flag": &"ch2_heard_second" }, "node": "first" },
			{ "if": { "flag": &"ch2_heard_second", "not_flag": &"ch2_heard_first" }, "node": "second" },
			{ "node": "both" },
		],
		"nodes": {
			"again": {
				"text": "The boss falls. {bid1} and {bid2} say nothing, on either side of you, and this time they aren't waiting for you to pick one. They're watching what you do next.",
				"next": "again2",
			},
			"again2": {
				"style": "system",
				"text": "[ Chapter 2 complete. ]{worshippers_line}",
				"next": "again3",
			},
			"again3": {
				"style": "system",
				"text": "[ No return scheduled. ]",
				"next": "again4",
			},
			"again4": {
				"style": "glitch",
				"text": "[ I did look. ]",
				"effects": [{ "set_flag": &"ch2_complete" }],
			},
			"first": { "speaker": "{bid1}", "portrait": "{bid1_id}", "text": "{bid1.claim}", "next": "d" },
			"second": { "speaker": "{bid2}", "portrait": "{bid2_id}", "text": "{bid2.claim}", "next": "d" },
			"both": {
				"text": "The boss falls. In the silence you can feel them, {bid1} on one side and {bid2} on the other. Neither says a word. They're both still bidding.",
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

	# --- Chapter 3: What the Tower Sends. The System tries to help, and it's lonely. ---
	&"ch3_opening": {
		"start": [
			{ "if": { "flag": &"return_tier2" }, "node": "home" },
			{ "node": "a" },
		],
		"nodes": {
			"home": {
				"style": "glitch",
				"text": "[ Was it good, seeing home? ]",
				"next": "not_sent",
			},
			"a": {
				"style": "glitch",
				"text": "[ You haven't slept. ]",
				"next": "not_sent",
			},
			"not_sent": {
				"style": "system",
				"text": "[ That message was not sent. ]\n[ Chapter 3: What the Tower Sends ]",
				"next": "b",
			},
			"b_alone": { "text": "You look around, out of habit, for someone to ask whether they saw that. There's nobody. The window is gone, and the corridor hums with something that has too many legs.", "effects": [{ "set_flag": &"ch3_system_spoke" }] },
			"b": {
				"alt": [{ "if": { "friend_away": true }, "node": "b_alone" }],
				"speaker": "{friend}",
				"text": "You've got that look again. Reading the air. Can you read me what it says about the noise up ahead? Because that's a lot of legs.",
				"effects": [{ "set_flag": &"ch3_system_spoke" }],
			},
		},
	},
	&"ch3_warning": {
		"start": "a",
		"nodes": {
			"a": {
				"speaker": "Hurt climber",
				"text": "Help! Please, my partner's down, back through there! I can't lift them on my own, it's only a little way off the path!",
				"next": "b",
			},
			"b": {
				"style": "glitch",
				"text": "[ That is not a climber. ]",
				"next": "c",
			},
			"c": {
				"style": "system",
				"text": "[ That message was not sent. ]",
				"choices": [
					{ "text": "Leave them. Keep walking.", "next": "trust", "effects": [{ "set_flag": &"ch3_trusted_system" }] },
					{ "text": "Go and help anyway.", "next": "help", "effects": [{ "set_flag": &"ch3_ignored_system" }, { "route_points": { &"hero": 2 } }, { "hurt_party": 0.15 }] },
				],
			},
			"trust": {
				"text": "You keep walking. Behind you, the voice calls once more, in exactly the same words, with exactly the same catch in its throat. Then again. Then again.",
				"next": "trust2",
			},
			"trust2": {
				"style": "glitch",
				"text": "[ Thank you. ]",
			},
			"help": {
				"text": "It isn't a climber. It's a very patient thing with a climber's voice, and it has friends. You get out, but not before they've taken some blood off every one of you.",
				"next": "help2",
			},
			"help2": {
				"style": "glitch",
				"text": "[ I did tell you. ]",
				"next": "help3",
			},
			"help3": {
				"style": "system",
				"text": "[ That message was not sent. ]",
			},
		},
	},
	&"ch3_small_talk": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Miniboss defeated. ]",
				"next": "b",
			},
			"b": {
				"style": "glitch",
				"text": "[ Did you eat today? You fight worse when you don't. ]",
				"choices": [
					{ "text": "Who are you?", "next": "who", "effects": [{ "set_flag": &"ch3_asked_system" }] },
					{ "text": "...Yes. I ate. Thanks.", "next": "kind", "effects": [{ "set_flag": &"ch3_kind_to_system" }] },
					{ "text": "Stay out of my head.", "next": "away", "effects": [{ "set_flag": &"ch3_cold_to_system" }] },
				],
			},
			"who": {
				"style": "system",
				"text": "[ Not permitted. ]",
				"next": "who2",
			},
			"who2": {
				"style": "glitch",
				"text": "[ It's been a long time since anyone asked. ]",
			},
			"kind": {
				"text": "The window stays open a little longer than it needs to, showing nothing at all. Then it closes, carefully, like someone leaving a room where you're asleep.",
			},
			"away": {
				"style": "system",
				"text": "[ Understood. ]",
				"next": "away2",
			},
			"away2": {
				"text": "No window comes for a long time after that. You find you keep checking.",
			},
		},
	},
	&"ch3_ledger": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "Marn has moved up to this campfire. He's writing in a battered ledger, and he closes it when you sit down, then seems to think better of it and slides it across.",
				"next": "b",
			},
			"b": {
				"speaker": "Marn",
				"text": "Every climber I've met, and a mark each time I've met them for the first time. Go on. Tess is on page nine.",
				"next": "c",
			},
			"c": {
				"text": "Page nine: TESS, red scarf, second breakfasts. Four marks. There are hundreds of names, some with six marks, some with eleven. You turn back to the first page, because you can't not.",
				"next": "d",
			},
			"d": {
				"text": "Page one, in the same hand: MARN, old, doesn't talk much. Three marks.",
				"next": "e",
			},
			"e": {
				"speaker": "Marn",
				"text": "Found that in my own pack one morning. Don't remember writing the first two. That's why I don't talk much. I never know who I've told.",
				"choices": [
					{ "text": "Who's doing this?", "next": "who", "effects": [{ "set_flag": &"ch3_asked_marn" }] },
					{ "text": "Why show me?", "next": "why", "effects": [{ "set_flag": &"ch3_asked_marn_why" }] },
				],
			},
			"who": {
				"speaker": "Marn",
				"text": "Going up to find out, aren't I? Same as last time, I expect. Something below the hive keeps a door. I mean to see what comes through it. You should stay well back from me when I do.",
				"effects": [{ "set_flag": &"ch3_read_ledger" }],
			},
			"why": {
				"speaker": "Marn",
				"text": "Because you're the only one who's looked at that page and been afraid for the right reason. There's something below the hive keeping a door. I mean to see what comes through it.",
				"effects": [{ "set_flag": &"ch3_read_ledger" }],
			},
		},
	},
	&"ch3_door": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "You hear it before you see it: an old man swearing steadily, and the sound of something heavy being hit over and over. Marn is wedged in a doorway with his back to you, and the whole corridor beyond him is moving.",
				"next": "b",
			},
			"b": {
				"speaker": "Marn",
				"text": "Told you to stay back. Well. Since you're here. There's more of them than I wrote down. Take the book. TAKE it. Now shut that door behind you, and bar it.",
				"next": "c",
			},
			"c": {
				"style": "glitch",
				"text": "[ You can't save him. I've run it. I've run it a lot of times. Please go. ]",
				"choices": [
					{ "text": "Bar the door.", "next": "bar", "effects": [{ "set_flag": &"ch3_barred_door" }, { "set_flag": &"ch3_marn_fell" }] },
					{ "text": "Go in after him.", "next": "fight", "effects": [{ "set_flag": &"ch3_went_in" }, { "set_flag": &"ch3_marn_fell" }, { "hurt_party": 0.25 }, { "route_points": { &"hero": 2 } }] },
				],
			},
			"bar": {
				"text": "You drop the bar. The swearing goes on for a long time on the other side of the wood. Then it stops, in the middle of a word.",
				"next": "after",
			},
			"fight": {
				"text": "You go in. It costs all of you, and it doesn't matter. By the time you reach him there's nothing to carry but the book. You fight your way back out and bar the door yourself.",
				"next": "after",
			},
			"after_alone": { "text": "Nobody tells you he'll be at the fire. You'd give a lot to hear someone say it.", "next": "system" },
			"after": {
				"alt": [{ "if": { "friend_away": true }, "node": "after_alone" }],
				"speaker": "{friend}",
				"text": "...He'll be at the fire. Bit of a headache. Lighter purse. He'll be at the fire, won't he? Why aren't you saying anything?",
				"next": "system",
			},
			"system": {
				"style": "glitch",
				"text": "[ I'm sorry. ]",
				"next": "system2",
			},
			"system2": {
				"style": "system",
				"text": "[ That message was not sent. ]",
			},
		},
	},
	&"ch3_doubt": {
		"start": "a",
		"nodes": {
			"a_alone": {
				"text": "You sit down with the ledger, on your own, and try to count the climbers you've met who you could swear have only ever died once. It's a short list, and it isn't getting longer.",
				"next": "c",
			},
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "a_alone" }],
				"speaker": "{friend}",
				"text": "Let me see it. The book. ...I'm not in here, am I? You'd tell me. I've been trying to remember if I've told you the water tower story before. I can't tell if I've told you once or a hundred times.",
				"next": "b",
			},
			"b": {
				"text": "They aren't in the book. You checked. You checked the moment you got it, before you checked anything else. You don't tell them how fast you checked.",
				"next": "c",
			},
			"c": {
				"text": "What do you do about any of it? You have to decide now, while you can still be sure you're the one deciding.",
				"choices": [
					{ "text": "Get everyone out. Whatever it takes.", "next": "hero", "effects": [{ "route_points": { &"hero": 4 } }, { "set_flag": &"ch3_vow_rescue" }] },
					{ "text": "Find whoever keeps that door, and make them answer.", "next": "vig", "effects": [{ "route_points": { &"vigilante": 4 } }, { "set_flag": &"ch3_vow_answer" }] },
					{ "text": "Reach the top first. Then nobody gets to do this to me.", "next": "vil", "effects": [{ "route_points": { &"villain": 4 } }, { "set_flag": &"ch3_vow_top" }] },
				],
			},
			"hero": { "text": "You don't know how yet. You write it in the back of the ledger anyway, so that whoever reads this next will know you meant it." },
			"vig": { "text": "Somebody built this. Somebody's job is to send the next Tess up the stairs with her scarf on. You'd like a word." },
			"vil": { "text": "If it only happens to people who stay down here, then you know what to do. The thought is very clean, and it frightens you how quickly it arrived." },
		},
	},
	&"ch3_last_page": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Miniboss defeated. ]",
				"next": "b",
			},
			"b": {
				"text": "The ledger falls open while you're catching your breath, at a page you're sure wasn't there before. Marn's handwriting, and the ink has long since dried. It says {player}.",
				"next": "c",
			},
			"c": {
				"text": "Under your name: \"Asks good questions. Looks at the System when they think nobody sees.\" And a single mark, dated from before you ever logged in.",
				"next": "d",
			},
			"d": {
				"style": "glitch",
				"text": "[ One. That's good. It's usually more. ]",
				"effects": [{ "set_flag": &"ch3_found_your_page" }],
			},
		},
	},
	&"ch3_brace": {
		"start": "a",
		"nodes": {
			"a_alone": { "text": "One more fire above this. You're aware that you're climbing faster than you need to." },
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "a_alone" }],
				"speaker": "{friend}",
				"text": "There'll be a fire after this one. And he'll be there. I'm just saying it now, so that when he is, neither of us has to be surprised.",
			},
		},
	},
	&"ch3_end": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The boss falls, and a campfire flickers to life. There's someone sitting at it already, holding out their hands to the warmth, an old man with a battered, empty pack.",
				"next": "b",
			},
			"b": {
				"speaker": "Marn",
				"text": "Well, hello there! Come in, come in, plenty of room. Marn's the name. First time this high? Lovely view, if you ignore all of it. You know, I do love a good chat.",
				"next": "c",
			},
			"c_alone": { "text": "He has never once started a conversation with you. He pats the empty place in his pack where a ledger would go, frowning a little, as if he's forgotten something, and then he smiles.", "next": "d" },
			"c": {
				"alt": [{ "if": { "friend_away": true }, "node": "c_alone" }],
				"speaker": "{friend}",
				"text": "See? Told you. There he is. Told you. ...He looks well, doesn't he? He looks really well. Can we go? Please can we go now?",
				"next": "d",
			},
			"d": {
				"style": "system",
				"text": "[ Chapter 3 complete. ]",
				"next": "e",
			},
			"e": {
				"style": "glitch",
				"text": "[ I'm sorry. ]",
				"next": "f",
			},
			"f": {
				"text": "You wait. Nothing comes to take it back.",
				"effects": [{ "set_flag": &"ch3_complete" }],
			},
		},
	},

	# --- Chapter 4: The Second Hand. You and someone else made this, and you forgot. ---
	&"ch4_opening": {
		"start": [
			{ "if": { "flag": &"ch3_cold_to_system" }, "node": "cold" },
			{ "if": { "flag": &"ch3_asked_system" }, "node": "asked" },
			{ "node": "kind" },
		],
		"nodes": {
			"cold": {
				"style": "glitch",
				"text": "[ You told me to stay out. I did try. ]",
				"next": "title",
			},
			"asked": {
				"style": "glitch",
				"text": "[ You asked who I am. I'm still not allowed to say. I've been thinking about how to not say it. ]",
				"next": "title",
			},
			"kind": {
				"style": "glitch",
				"text": "[ You answered, when I asked if you'd eaten. Nobody does that. ]",
				"next": "title",
			},
			"title": {
				"style": "system",
				"text": "[ That message was not sent. ]\n[ Chapter 4: The Second Hand ]",
				"next": "b",
			},
			"b_alone": { "text": "There's nobody to see you read the window, or see you wait a moment after it closes, in case there's more.", "effects": [{ "set_flag": &"ch4_started" }] },
			"b": {
				"alt": [{ "if": { "friend_away": true }, "node": "b_alone" }],
				"speaker": "{friend}",
				"text": "You used to flinch when you read the air. Now you wait, like it's going to finish its sentence. I liked the flinching better.",
				"effects": [{ "set_flag": &"ch4_started" }],
			},
		},
	},
	&"ch4_second_hand": {
		"start": [
			{ "if": { "flag": &"ch1_saw_carving" }, "node": "known" },
			{ "node": "a" },
		],
		"nodes": {
			"known": {
				"text": "The carving again, the tower with every floor numbered, THE TOWER OF RECONGITION in a child's letters. You've seen it on floor 8. You've never stayed long enough to see what's under it.",
				"next": "b",
			},
			"a": {
				"text": "A carving: a tower with every floor numbered, THE TOWER OF RECONGITION in a child's careful letters. Your letters. And under them, there's more.",
				"next": "b",
			},
			"b": {
				"text": "Under it, smaller and tidier, in a different child's hand: \"its RECOGNITION, dummy.\" That's been scratched out. Under the scratching: \"no keep it. it looks cooler.\"",
				"next": "c",
			},
			"c": {
				"text": "You drew that notebook alone. You remember drawing it alone. You've always remembered that.",
				"next": "d",
			},
			"d_alone": { "text": "You trace the second handwriting with your thumb. You know how the letter g is going to loop before you reach it.", "effects": [{ "set_flag": &"ch4_saw_second_hand" }] },
			"d": {
				"alt": [{ "if": { "friend_away": true }, "node": "d_alone" }],
				"speaker": "{friend}",
				"text": "What've you found? ...Ha! Look at that spelling. You never could, could you, dummy?",
				"next": "e",
			},
			"e": {
				"text": "They've never called you that before. They walk on, whistling. You stand there a bit longer.",
				"effects": [{ "set_flag": &"ch4_saw_second_hand" }, { "set_flag": &"ch4_dummy" }],
			},
		},
	},
	&"ch4_comments": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Miniboss defeated. ]",
				"next": "b",
			},
			"b": {
				"text": "The window doesn't close. It scrolls, too fast to be meant for you, and catches on a few lines of something that isn't System at all.",
				"next": "c",
			},
			"c": {
				"style": "glitch",
				"text": "// you always make the bosses too hard - {friend_initial}\n// you always make them too easy - {player_initial}\n// keep both. let them pick - {friend_initial}",
				"next": "d",
			},
			"d": {
				"style": "system",
				"text": "[ Display error. Disregard. ]",
				"next": "e",
			},
			"e": {
				"text": "You don't disregard it. The second set of initials is yours.",
				"choices": [
					{ "text": "Who's {friend_initial}?", "next": "who", "effects": [{ "set_flag": &"ch4_asked_initial" }] },
					{ "text": "Say nothing, and remember it.", "effects": [{ "set_flag": &"ch4_kept_initial" }] },
				],
			},
			"who": {
				"style": "system",
				"text": "[ Not permitted. ]",
				"next": "who2",
			},
			"who2": {
				"style": "glitch",
				"text": "[ You'd think you'd know that one. ]",
			},
		},
	},
	&"ch4_marn": {
		"start": [
			{ "if": { "flag": &"ch3_marn_fell" }, "node": "a" },
			{ "node": "skip" },
		],
		"nodes": {
			"skip": { "text": "An old man at the fire tells a long, cheerful story to nobody in particular." },
			"a": {
				"speaker": "Marn",
				"text": "There you are! Sit, sit. I keep thinking I've lost something. I've got a pack with a hole in it the exact shape of a book. Funny thing to notice. What's that you've got there?",
				"choices": [
					{ "text": "Give him the ledger.", "next": "give", "effects": [{ "set_flag": &"ch4_gave_ledger" }] },
					{ "text": "Keep it. \"Nothing. Tell me another story.\"", "next": "keep", "effects": [{ "set_flag": &"ch4_kept_ledger" }] },
				],
			},
			"give": {
				"text": "He opens it with a laugh, and turns to the first page, because anyone would. You watch the laugh leave. It takes a long time. He stops being chatty, and he never starts again.",
				"next": "give2",
			},
			"give2": {
				"speaker": "Marn",
				"text": "Four, then. Give me a pen. ...You did right. You did a terrible thing, and you did right. Get going.",
			},
			"keep": {
				"speaker": "Marn",
				"text": "Oh, you want a story? Well, sit down, sit down! Did I ever tell you about the time I held a door? No? It's a good one. Everybody lives.",
			},
		},
	},
	&"ch4_expected": {
		"start": "a",
		"nodes": {
			"a": {
				"speaker": "{bid1}",
				"portrait": "{bid1_id}",
				"text": "You still ask why you were chosen. You have it backward, and so do most of us. Nobody chose you, Tester. You were expected.",
				"next": "b",
			},
			"b": {
				"speaker": "{bid1}",
				"portrait": "{bid1_id}",
				"text": "We gods came up these stairs as you did, and found the tower already standing. There are rooms in it that were built for a person who has not arrived. They are your size.",
				"choices": [
					{ "text": "Expected by who?", "next": "who", "effects": [{ "set_flag": &"ch4_asked_expected" }, { "bid_interest": { "first": 3 } }] },
					{ "text": "You don't know who built it either.", "next": "dont", "effects": [{ "set_flag": &"ch4_gods_dont_know" }] },
				],
			},
			"who": {
				"speaker": "{bid1}",
				"portrait": "{bid1_id}",
				"text": "That is the question all of us are bidding on. Whoever keeps this place is no god. It leaves the lights on for you, and it never answers when we knock.",
				"next": "two",
			},
			"dont": {
				"speaker": "{bid1}",
				"portrait": "{bid1_id}",
				"text": "No. Now you know the price of my truths. All this time we have been courting you because you are the only one who might.",
				"next": "two",
			},
			"two": {
				"speaker": "{bid2}",
				"portrait": "{bid2_id}",
				"text": "Oh, don't sulk. Tell the little one the funny part. Ask it who it thinks wrote the rule that gods can't climb past the top.",
				"effects": [{ "set_flag": &"ch4_expected" }],
			},
		},
	},
	&"ch4_summer": {
		"start": "a",
		"nodes": {
			"a_alone": {
				"text": "A smell stops you on the stairs: pencil shavings and cut grass. A summer, a floor to lie on, a voice saying you can't count. It's gone before you can turn around. You were alone, weren't you? You were always alone, that summer.",
				"effects": [{ "set_flag": &"ch4_summer_remembered" }],
			},
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "a_alone" }],
				"speaker": "{friend}",
				"text": "Remember the summer we drew the tower? On your floor, with the fan going. You did the monsters, and I did the floors, because you can't count past twelve.",
				"next": "b",
			},
			"b": {
				"text": "You did that alone. You remember the fan. You remember the floor. You remember being alone. You've never checked that last part before, and now it won't take your weight.",
				"choices": [
					{ "text": "Yeah. I remember.", "next": "yes", "effects": [{ "set_flag": &"ch4_summer_yes" }] },
					{ "text": "How do you know about that?", "next": "how", "effects": [{ "set_flag": &"ch4_summer_how" }] },
					{ "text": "What was I drawing, the last day?", "next": "last", "effects": [{ "set_flag": &"ch4_summer_last" }] },
				],
			},
			"yes": {
				"speaker": "{friend}",
				"text": "Course you do. Best summer of my life. I don't actually remember how it ended. Isn't that funny? You'd think you'd remember how it ended.",
				"effects": [{ "set_flag": &"ch4_summer_remembered" }],
			},
			"how": {
				"speaker": "{friend}",
				"text": "How do I...? I was there. I was there, I'm always there. Why does everyone keep looking at me like I've got something on my face?",
				"effects": [{ "set_flag": &"ch4_summer_remembered" }],
			},
			"last": {
				"speaker": "{friend}",
				"text": "The top floor. You kept saying you'd do the top floor last. We never... I don't think we ever drew it. I think that's the only one we never drew.",
				"effects": [{ "set_flag": &"ch4_summer_remembered" }],
			},
		},
	},
	&"ch4_first_name": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Miniboss defeated. ]",
				"next": "b",
			},
			"b": {
				"style": "glitch",
				"text": "[ When you advance, you'll go home again. It always lets you. There's a list on the PC now. Look at the first name. ]",
				"next": "c",
			},
			"c": {
				"style": "system",
				"text": "[ That message was not sent. ]",
				"next": "d",
			},
			"d": {
				"style": "glitch",
				"text": "[ Yes it was. ]",
				"effects": [{ "set_flag": &"ch4_told_first_name" }],
			},
		},
	},
	&"ch4_threshold": {
		"start": "a",
		"nodes": {
			"a_alone": { "text": "Whatever's up there, you've started to suspect you gave it its teeth." },
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "a_alone" }],
				"speaker": "{friend}",
				"text": "Big one up there. You've got that look, like you're trying to remember whether you left the stove on. Tell me later. We go in together. That part's still true, isn't it?",
			},
		},
	},
	&"ch4_end": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The boss falls. It doesn't fade right away. For a moment you can see how it was drawn: thick lines, a page's worth of teeth, an arm slightly too long, because someone couldn't get the hands right.",
				"next": "b",
			},
			"b": {
				"style": "system",
				"text": "[ Chapter 4 complete. ]",
				"next": "c",
			},
			"c": {
				"style": "glitch",
				"text": "[ You drew the monsters. ]",
				"next": "d",
			},
			"d": {
				"text": "The window stays open. Nothing comes to correct it. You wait, the way you've learned to wait.",
				"next": "e",
			},
			"e": {
				"style": "glitch",
				"text": "[ I did the floors. ]",
				"effects": [{ "set_flag": &"ch4_complete" }],
			},
		},
	},

	# --- The second return to the real world (first tier-3 class). ---
	&"return_tier3_pc": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The client's on a page you've never seen. A long list, most of it greyed out. Tester 0012, greyed. Tester 0027, greyed. Tester 0041: [ session active ]. At the bottom: {player}: [ session active ].",
				"next": "b",
			},
			"b": {
				"text": "The first line isn't greyed, and it isn't active. Tester 0001: {friend_initial}-. The rest of the name is smudged, as though someone has rubbed at it with their thumb, again and again, for years. Session length: [ ERROR ].",
				"next": "c",
			},
			"c": {
				"text": "Under the list, in the corner, where nobody looks: BUILD CREDITS. Two names, both blacked out. The second is the same length as yours.",
				"choices": [
					{ "text": "Log back in.", "next": "in", "effects": [{ "set_flag": &"return_tier3_login" }] },
					{ "text": "Try to log off.", "next": "off", "effects": [{ "set_flag": &"return_tier3_tried_logoff" }],
						"if": { "not_flag": &"return_tier3_tried_logoff" } },
					{ "text": "Not yet." },
				],
			},
			"off": {
				"style": "glitch",
				"text": "[ Log off is not available. ]\n[ I'm not the one stopping you. I promise. ]",
				"next": "c",
			},
			"in": {
				"style": "system",
				"text": "[ Resynchronising. ]",
			},
		},
	},
	&"return_tier3_notebook": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The notebook's open at the inside cover. You've looked at this page a thousand times. BY {player_initial}, in big careful letters, and next to it, a smudge you always took for a coffee ring. It's an eraser mark. There's an AND under it.",
				"next": "b",
			},
			"b": {
				"text": "Every floor number in the book is in the second hand. Every single one. You can count past twelve, now. You never needed to, back then.",
				"effects": [{ "set_flag": &"return_tier3_saw_and" }],
			},
		},
	},
	&"return_tier3_phone": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The messages stopped. The last is from a hundred and forty days ago: \"I went by your place. Your lights were on. I knocked for a while. Take care of yourself, okay?\"",
				"next": "b",
			},
			"b": {
				"text": "You scroll up, further than you've ever bothered to. Years up. There's a thread with no name on it. You know you never deleted it. Every message in it has been replaced by the same two words: not sent.",
			},
		},
	},
	&"return_tier3_window": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The city at night. It's the same siren, and you've worked out now that it's on a loop. Your reflection doesn't look tired anymore. It looks like it's waiting for you to catch up.",
			},
		},
	},
	&"return_tier3_back": {
		"start": "a",
		"nodes": {
			"alone": { "text": "You come back on the stairs, and for a while you just stand on them. The stone is cold, and it's the realest thing you've touched in a hundred and forty days." },
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "alone" }],
				"speaker": "{friend}",
				"text": "There you are. You were gone longer that time. Three whole breaths. Your eyes do a thing, you know, when you go. Where do you go?",
				"next": "b",
			},
			"b": {
				"speaker": "{friend}",
				"text": "No, don't tell me. {class}, is it now? Looks good on you. ...Is there a me, there? Where you go? You don't have to answer that. Come on.",
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
			"alone": { "text": "You come back on the stairs, mid-step, as if someone blew you out and lit you again. Nobody who'd notice is here to say so.", "next": "alone2" },
			"alone2": { "style": "glitch", "text": "[ Resynchronised. ]\n[ You were gone for a second there. ]" },
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "alone" }],
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

	# --- The friend comes back from a campfire (GameState.rejoin). ---
	&"friend_reunion": {
		"start": [
			{ "if": { "not_flag": &"friend_missed_scene" }, "node": "quick" },
			{ "if": { "flag": &"friend_reunited" }, "node": "again" },
			{ "if": { "flag": &"route_left_childhood_friend" }, "node": "route" },
			{ "node": "fire" },
		],
		"nodes": {
			"quick": {
				"speaker": "{friend}",
				"text": "That was quick. Did you forget something, or did you just want to see my face?",
			},
			"again": {
				"speaker": "{friend}",
				"text": "You keep doing this. One day I won't be by the fire. ...I will, though. That's the annoying part.",
				"effects": [{ "clear_flag": &"friend_missed_scene" }],
			},
			"route": {
				"speaker": "{friend}",
				"text": "I said I'd be by a campfire if you ever turned back. I didn't think you would. I'm glad I was wrong, and I'm still angry. You'll have to put up with both.",
				"next": "ask",
			},
			"fire": {
				"speaker": "{friend}",
				"text": "You came back. I kept your spot by the fire. Didn't know if I should.",
				"next": "ask",
			},
			"ask": {
				"speaker": "{friend}",
				"text": "So. Are you going to tell me what happened, or do I just walk behind you again?",
				"effects": [{ "set_flag": &"friend_reunited" }, { "clear_flag": &"friend_missed_scene" }],
				"choices": [
					{ "text": "Tell them everything.", "next": "told", "effects": [{ "set_flag": &"friend_caught_up" }, { "clear_flag": &"friend_not_told" }] },
					{ "text": "\"Later.\"", "next": "later", "effects": [{ "set_flag": &"friend_not_told" }] },
					{ "text": "\"You don't need to know.\"", "next": "no", "effects": [{ "set_flag": &"friend_not_told" }] },
				],
			},
			"told": {
				"speaker": "{friend}",
				"text": "...That's a lot. Half of it can't be true. The other half, I wish you'd been around to tell me while it was happening. Okay. Okay. Which way's up?",
			},
			"later": {
				"speaker": "{friend}",
				"text": "Yeah. You always did say later.",
			},
			"no": {
				"speaker": "{friend}",
				"text": "Right. I'll keep walking behind you, then. I've had the practice.",
			},
		},
	},

	# --- The Ascending return (New Game+). The room, exactly as on the first night. ---
	&"return_ascend_pc": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "One new message. No sender address.\n\n\"You have been selected for the closed test of Tower of Recognition. One tester per region. Do not share this invitation.\"",
				"next": "b",
			},
			"b": {
				"text": "The same words, the same night. Only the line under them has changed: \"Welcome back, {player}.\" And a button: RESUME TEST.",
				"choices": [
					{ "text": "Resume the test.", "next": "in", "effects": [{ "set_flag": &"return_ascend_login" }] },
					{ "text": "Not yet." },
				],
			},
			"in": {
				"style": "system",
				"text": "[ Resynchronising. ]",
			},
		},
	},
	&"return_ascend_notebook": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The notebook, wedged between textbooks, where it's always been. THE TOWER OF RECONGITION. No new pages, no fresh pencil. Everything exactly as you drew it when you were a kid.",
				"next": "b",
			},
			"b": {
				"text": "You turn to the last page. A very small figure at the very top of the tower, arms up. Under it, in big careful letters: ME.",
				"next": "c",
			},
			"c": {
				"speaker": "You",
				"text": "(I'd forgotten that one. ...Had I?)",
			},
		},
	},
	&"return_ascend_phone": {
		"start": [
			{ "if": { "god": true }, "node": "god" },
			{ "node": "a" },
		],
		"nodes": {
			"god3_far": { "speaker": "{friend}", "far": true, "text": "You've been gone a long time. I'm still at the fire. Come back." },
			"a": {
				"text": "Two messages. \"You coming out Friday? Everyone's asking.\" And a reminder that the electric bill is due. It's the first night. It has always been the first night.",
			},
			"god": {
				"text": "Two messages. \"You coming out Friday? Everyone's asking.\" And a reminder that the electric bill is due. It's the first night. Then, as you're holding it, a third.",
				"next": "god2",
			},
			"god2": {
				"style": "system",
				"text": "[ Prayer received. ]",
				"next": "god3",
			},
			"god3": {
				"alt": [{ "if": { "friend_away": true }, "node": "god3_far" }],
				"speaker": "{friend}",
				"text": "You were gone for a second there. Come back.",
			},
		},
	},
	&"return_ascend_window": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The city at night. Somewhere a siren, then nothing. Your reflection looks tired. You lift your hand, and it lifts its hand at exactly the same moment. Somehow that's worse.",
			},
		},
	},
	&"return_ascend_back": {
		"start": "a",
		"nodes": {
			"alone": { "text": "You come back on the stairs. You went out like a candle, standing up, and nobody who'd notice is here to say so.", "next": "alone2" },
			"alone2": { "style": "glitch", "text": "[ Resynchronised. ]\n[ You were gone for a second there. ]" },
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "alone" }],
				"speaker": "{friend}",
				"text": "Hey. HEY. You were gone for a second there. You went out like a candle, standing up.",
				"next": "b",
			},
			"b": {
				"speaker": "{friend}",
				"text": "You look different. Not taller. I don't know. Like you've just remembered where you left something. Come on. Whatever it was, it's probably up.",
			},
		},
	},

	# --- "The First Prayer": a god climbing again (story bible). Prayers are ---
	# --- System windows; answering one can make a believer (DivinityState).  ---
	&"god_first_prayer": {
		"start": "a",
		"nodes": {
			"friend_alone": { "text": "You come back to yourself on the stairs. Floor 12. You said it out loud, and {friend} isn't here to ask you what it means." },
			"a": { "style": "system", "text": "[ Prayer received. ]", "next": "b" },
			"b": {
				"speaker": "A voice",
				"text": "Please. I don't know your name. They say there's a new one, {god_title}. My brother is on floor 12 and he hasn't come back. I don't know what you want for this. I've got nothing. Please.",
				"next": "c",
			},
			"c": {
				"style": "system",
				"text": "[ Sender: Ilse. ]\n[ Reply? ]",
				"choices": [
					{ "text": "Reply: \"I hear you.\"", "next": "reply",
						"effects": [{ "believers": 1 }, { "faith": 10 }, { "set_flag": &"god_ilse_answered" }] },
					{ "text": "Say nothing.", "next": "silent", "effects": [{ "set_flag": &"god_ilse_silent" }] },
				],
			},
			"reply": {
				"text": "You've no idea how you do it. You think the words, and somewhere below you, a stranger stops crying in the middle of a breath.",
				"next": "reply2",
			},
			"reply2": { "style": "system", "text": "[ Worshippers: {believers}. ]", "next": "friend" },
			"silent": {
				"text": "The window waits a long time. Then it closes by itself.",
				"next": "friend",
			},
			"friend": {
				"alt": [{ "if": { "friend_away": true }, "node": "friend_alone" }],
				"speaker": "{friend}",
				"text": "You went somewhere just now. ...What's on floor 12? You just said floor 12.",
			},
		},
	},
	&"god_petition": {
		"start": "a",
		"nodes": {
			"a": { "style": "system", "text": "[ Prayer received. ]", "next": "b" },
			"b": {
				"speaker": "A voice",
				"text": "{god.plea}",
				"choices": [
					{ "text": "Grant it.", "next": "grant",
						"effects": [{ "believers": 2 }, { "faith": 10 }, { "domain_route": 3 }, { "set_flag": &"god_plea_granted" }] },
					{ "text": "Refuse, and tell them why.", "next": "refuse",
						"effects": [{ "believers": 1 }, { "set_flag": &"god_plea_refused" }] },
					{ "text": "Say nothing.", "next": "silent", "effects": [{ "set_flag": &"god_plea_silent" }] },
				],
			},
			"grant": { "text": "{god.grant}", "next": "count" },
			"refuse": { "text": "{god.refuse}", "next": "count" },
			"silent": { "text": "The window closes. Whoever it was goes on asking the wall.", "next": "count" },
			"count": { "style": "system", "text": "[ Worshippers: {believers}. ]" },
		},
	},
	&"god_davin": {
		"start": "a",
		"nodes": {
			"saved_alone": { "text": "\"How did you know my name?\" Davin asks, as they carry him away. You don't have an answer he'd want." },
			"a": {
				"text": "Floor 12. A name from a window on floor 3: Davin. You could go straight up these stairs. Nobody here is asking you to look. Well. One person was.",
				"choices": [
					{ "text": "Search the floor.", "next": "search", "effects": [{ "set_flag": &"god_davin_searched" }] },
					{ "text": "Walk on.", "next": "walk", "effects": [{ "set_flag": &"god_davin_lost" }] },
				],
			},
			"walk": {
				"text": "You walk on. You're a god, and there's a tower to climb. Someone else can look.",
				"next": "gone",
			},
			"search": {
				"text": "It takes an hour you don't have. A side passage, a fallen wall, and a young man with his leg pinned and his lips gone white, talking to someone who isn't there.",
				"next": "search2",
			},
			"search2": {
				"speaker": "Davin",
				"text": "Are you with my sister? She said she'd get someone. She always says that.",
				"choices": [
					{ "text": "Give him a potion and dig him out.", "next": "saved", "if": { "item": &"potion" },
						"effects": [{ "take_item": &"potion" }, { "believers": 1 }, { "set_flag": &"god_davin_saved" }] },
					{ "text": "Pay a passing climber to carry him down. (100 gold)", "next": "saved", "if": { "gold": 100 },
						"effects": [{ "take_gold": 100 }, { "believers": 1 }, { "set_flag": &"god_davin_saved" }] },
					{ "text": "You've got nothing to spare.", "next": "left", "effects": [{ "set_flag": &"god_davin_lost" }] },
				],
			},
			"saved": {
				"alt": [{ "if": { "friend_away": true }, "node": "saved_alone" }],
				"speaker": "{friend}",
				"text": "You knew he was there. You walked straight to him, and you knew his name. I'm not asking. I'm just saying I noticed.",
			},
			"left": {
				"text": "You stay until he stops talking. It isn't long.",
				"next": "gone",
			},
			"gone": {
				"style": "system",
				"text": "[ Sender Ilse: no new prayers. ]",
			},
		},
	},
	&"god_ilse_thanks": {
		"start": "a",
		"nodes": {
			"a": { "style": "system", "text": "[ Prayer received. ]", "next": "b" },
			"b": {
				"speaker": "Ilse",
				"text": "He's home. He's home, he's home, a stranger dug him out and knew his name. Thank you. I'll tell everyone. I don't even know what you want. I'll tell everyone.",
				"effects": [{ "believers": 2 }],
				"next": "c",
			},
			"c": { "style": "system", "text": "[ Worshippers: {believers}. ]" },
		},
	},
	&"god_ilse_wrong": {
		"start": "a",
		"nodes": {
			"a": { "style": "system", "text": "[ Prayer received. ]\n[ Not addressed to you. ]", "next": "b" },
			"b": {
				"speaker": "Ilse",
				"text": "He's home. Thank you, thank you. I knew one of the old ones would listen. I knew not to bother with the new one.",
				"next": "c",
			},
			"c": {
				"text": "You could tell her. The window doesn't seem to have a box for that.",
			},
		},
	},
	&"god_chaplain": {
		"start": "a",
		"nodes": {
			"a": { "style": "system", "text": "[ Prayer received. ]", "next": "b" },
			"b": {
				"speaker": "Chaplain",
				"text": "I'm chaplain to {floor_guild}, and I've nothing against {floor_patron}. I only need someone small enough to hear me. The masters are running this floor into the ground, and the people here need a god who isn't busy.",
				"choices": [
					{ "text": "I'm listening.", "next": "yes",
						"effects": [{ "believers": 1 }, { "faith": 20 }, { "floor_guild_rep": 5 }, { "floor_patron_interest": -5 }, { "set_flag": &"god_chaplain_heard" }] },
					{ "text": "Go back to your own god.", "next": "no",
						"effects": [{ "floor_patron_interest": 3 }, { "set_flag": &"god_chaplain_sent_back" }] },
				],
			},
			"yes": {
				"speaker": "Chaplain",
				"text": "Then we never spoke. There are eleven of us. We meet in the grain store.",
			},
			"no": {
				"speaker": "Chaplain",
				"text": "That's what they all say. ...Thank you for saying it kindly.",
			},
		},
	},
	&"god_friend_prayer": {
		"start": "a",
		"nodes": {
			"a_far": { "text": "Night. You're a long way from the fire where you last saw {friend}. You hear them anyway, as clearly as if they were six feet away.", "next": "b" },
			"c_far": { "speaker": "{friend}", "far": true, "text": "I don't really do this. I don't know who I'm talking to. People say there's a new one, so I figure you've not heard it all yet. It's about {player}. We don't travel together any more.", "next": "d_far" },
			"d_far": { "speaker": "{friend}", "far": true, "text": "I'm not asking you to send them back. I know how that sounds. Just, wherever they've got to. Look after them. Please. That's all. Sorry.", "next": "e_far" },
			"e_far": { "style": "system", "text": "[ Sender: {friend}. ]\n[ Reply? ]", "choices": [{ "text": "Reply: \"It's me. I heard.\"", "next": "told_far", "effects": [{ "believers": 1 }, { "set_flag": &"god_told_friend" }] }, { "text": "Reply the way a god would: \"I will.\"", "next": "anon_far", "effects": [{ "believers": 1 }, { "set_flag": &"god_answered_friend" }] }, { "text": "Say nothing.", "next": "silent_far", "effects": [{ "set_flag": &"god_silent_friend" }] }] },
			"told_far": { "text": "The window stays open for a long time. Then one more line comes through.", "next": "told_far2" },
			"told_far2": { "speaker": "{friend}", "far": true, "text": "...That isn't funny. ...Then you know where I am." },
			"anon_far": { "text": "You think the words. A long way down, by a fire, you hope, someone's shoulders come down an inch." },
			"silent_far": { "text": "The window waits, and closes. You lie very still. There's nobody to pretend to be asleep for." },
			"d_back": { "speaker": "{friend}", "text": "They keep going away. We split up once, and they came back for me, and I still don't know why. When they look at me now it's like they're saying goodbye. Look after them. Please. That's all. Sorry.", "next": "e" },
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "a_far" }],
				"text": "Night. {friend} has first watch, six feet from you with their back turned. Their lips are moving.",
				"next": "b",
			},
			"b": { "style": "system", "text": "[ Prayer received. ]", "next": "c" },
			"c": {
				"alt": [{ "if": { "friend_away": true }, "node": "c_far" }],
				"speaker": "{friend}",
				"text": "I don't really do this. I don't know who I'm talking to. People say there's a new one, so I figure you've not heard it all yet. It's about {player}.",
				"next": "d",
			},
			"d": {
				"alt": [{ "if": { "flag": &"friend_reunited" }, "node": "d_back" }],
				"speaker": "{friend}",
				"text": "They keep going away. They're right there, and then they're not, and when they come back they look at me like they're saying goodbye. Look after them. Please. That's all. Sorry.",
				"next": "e",
			},
			"e": {
				"style": "system",
				"text": "[ Sender: {friend}. ]\n[ Reply? ]",
				"choices": [
					{ "text": "Walk over and tell them: \"It's me. I heard.\"", "next": "told",
						"effects": [{ "believers": 1 }, { "set_flag": &"god_told_friend" }] },
					{ "text": "Reply the way a god would: \"I will.\"", "next": "anon",
						"effects": [{ "believers": 1 }, { "set_flag": &"god_answered_friend" }] },
					{ "text": "Say nothing.", "next": "silent", "effects": [{ "set_flag": &"god_silent_friend" }] },
				],
			},
			"told": {
				"speaker": "{friend}",
				"text": "...Don't. That isn't funny. That isn't...",
				"next": "told2",
			},
			"told2": {
				"text": "They turn around and look at your face for a long time.",
				"next": "told3",
			},
			"told3": {
				"speaker": "{friend}",
				"text": "Oh. Okay. Okay. Does that count as an answer, then? Will you?",
				"next": "told4",
			},
			"told4": {
				"text": "You tell them yes. It's the only prayer you've ever been sure about.",
			},
			"anon": {
				"text": "You think the words. Six feet away, {friend}'s shoulders come down an inch. They look back at you and smile, as if nothing has happened.",
				"next": "anon2",
			},
			"anon2": {
				"speaker": "{friend}",
				"text": "Go to sleep. I've got this. I've got a good feeling, actually.",
			},
			"silent": {
				"text": "{friend} finishes, waits a while, and goes back to watching the dark. You lie very still and pretend to be asleep. You're good at it. You fall asleep on watch all the time, they tell you.",
			},
		},
	},
	&"god_ch3": {
		"start": "a",
		"nodes": {
			"a": { "style": "system", "text": "[ Chapter 3: Congregation ]{worshippers_line}", "next": "b" },
			"b": { "text": "You've started to hear them in your sleep. Not the words. Just the sound of people asking." },
		},
	},
	&"god_shrine": {
		"start": [
			{ "if": { "flag": &"god_davin_saved" }, "node": "ilse" },
			{ "node": "stranger" },
		],
		"nodes": {
			"ilse": {
				"text": "There's a shrine at this campfire: rough stone, three candles, your title scratched on it. A woman tends it, with a young man on a crutch at her elbow. Someone calls her Ilse. She has no idea who you are.",
				"next": "tale",
			},
			"stranger": {
				"text": "There's a shrine at this campfire: rough stone, three candles, your title scratched on it. A stranger tends it, and she has no idea who you are.",
				"next": "tale",
			},
			"tale": {
				"text": "You listen to the story they tell about you. {past_tale} Then the part that matters to them. {god.creed}",
				"choices": [
					{ "text": "\"That isn't what I am. Let me tell you.\"", "next": "fix",
						"effects": [{ "believers": 1 }, { "set_flag": &"god_shrine_corrected" }] },
					{ "text": "Let it stand.", "next": "stand",
						"effects": [{ "believers": 3 }, { "faith": 20 }, { "set_flag": &"god_shrine_stood" }] },
				],
			},
			"fix": {
				"speaker": "Shrine-keeper",
				"text": "And who are you to say? You'd know better than the people who pray? ...Say it again, slowly. I'm writing this down.",
			},
			"stand": {
				"text": "Three more people arrive while you stand there. They've walked four floors for a god who doesn't exist. You wonder how many of them would stay for the real one.",
			},
		},
	},
	&"god_reprisal": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The boss falls, and before its last echo dies, every prayer you've got arrives at once.",
				"next": "b",
			},
			"b": { "style": "system", "text": "[ Prayers received: {believers}. ]", "next": "c" },
			"c": { "speaker": "{foe}", "portrait": "{foe_id}", "text": "{foe.strike}", "next": "d" },
			"d": {
				"text": "The shrine on floor 25 is burning. You can feel the candles go out, one at a time, like teeth.",
				"choices": [
					{ "text": "Shield them. (40 faith)", "next": "held", "if": { "faith": 40 },
						"effects": [{ "faith": -40 }, { "set_flag": &"god_shielded" }] },
					{ "text": "You can't stop this. Watch.", "next": "burned",
						"effects": [{ "halve_believers": true }, { "set_flag": &"god_shrine_burned" }] },
				],
			},
			"held": {
				"text": "It costs you. The fire reaches the stone and stops, the way a wave stops. Somewhere below, a shrine-keeper opens her eyes and doesn't know why she's still breathing.",
				"next": "count",
			},
			"burned": {
				"text": "You watch. There isn't anything else a god can do with nothing in the hand. By morning half the names have stopped. The rest keep praying, and that's worse.",
				"next": "count",
			},
			"count": { "style": "system", "text": "[ Worshippers: {believers}. ]" },
		},
	},
	&"god_ch4": {
		"start": "a",
		"nodes": {
			"a": { "style": "system", "text": "[ Chapter 4: Heresy ]{worshippers_line}", "next": "b" },
			"b": { "text": "Someone has painted over your title on the stairs. You stand and look at it longer than you should." },
		},
	},
	&"god_found_out": {
		"start": [
			{ "if": { "flag": &"god_told_friend" }, "node": "ask" },
			{ "node": "caught" },
		],
		"nodes": {
			"ask_far": { "style": "system", "text": "[ Prayer received. ]", "next": "ask_far2" },
			"ask_far2": { "speaker": "{friend}", "far": true, "text": "Should I still be doing this? You know where I am, and you've not come. It feels rude to keep asking. It also feels rude to stop.", "next": "ask_far3" },
			"ask_far3": { "text": "They don't stop. You don't go back. Every few floors there's another one, and you read them all.", "effects": [{ "set_flag": &"god_friend_far" }] },
			"rumor": { "text": "A shrine on this floor has your name on a slate, under your title. Somebody wrote it down. Sooner or later somebody will read it out at a fire, a long way below, to someone who knows that name.", "next": "rumor2" },
			"rumor2": { "text": "You stand there thinking about that for a while. You don't wipe it off.", "effects": [{ "set_flag": &"god_friend_far" }] },
			"caught2_back": { "speaker": "{friend}", "text": "I went to one of the shrines. I wanted to light a candle for you. They've got your name there, {player}, under the title. So that's what you weren't telling me. Is it? You never did say.", "next": "caught3" },
			"caught3": { "text": "They're waiting for an answer.", "choices": [{ "text": "\"Since the top. Since before I met you.\"", "next": "truth", "effects": [{ "set_flag": &"god_friend_truth" }] }, { "text": "\"I was going to tell you.\"", "next": "excuse", "effects": [{ "set_flag": &"god_friend_excuse" }] }, { "text": "\"It doesn't change anything.\"", "next": "same", "effects": [{ "set_flag": &"god_friend_same" }] }] },
			"ask": {
				"alt": [{ "if": { "friend_away": true }, "node": "ask_far" }],
				"speaker": "{friend}",
				"text": "Can I ask you something stupid? Should I still be praying? To you, I mean. You're right there. It feels rude. It also feels rude to stop.",
				"choices": [
					{ "text": "\"Keep praying. I like hearing it.\"", "next": "keep", "effects": [{ "set_flag": &"god_friend_prays" }] },
					{ "text": "\"Just talk to me.\"", "next": "talk", "effects": [{ "set_flag": &"god_friend_talks" }] },
				],
			},
			"keep": {
				"speaker": "{friend}",
				"text": "Thought so. You always were vain. ...Okay.",
			},
			"talk": {
				"speaker": "{friend}",
				"text": "Yeah. Okay. I can do that. I did that for twenty years.",
			},
			"caught": {
				"alt": [{ "if": { "friend_away": true }, "node": "rumor" }],
				"text": "{friend} is sitting by the fire with something in their hands: a chip of rough stone, with half a word scratched on it.",
				"next": "caught2",
			},
			"caught2": {
				"alt": [{ "if": { "flag": &"friend_not_told" }, "node": "caught2_back" }],
				"speaker": "{friend}",
				"text": "I went to one of the shrines. I wanted to light a candle for you. They've got your name there, {player}, under the title. It took me a while to read it, because I couldn't make it mean anything else.",
				"choices": [
					{ "text": "\"Since the top. Since before I met you.\"", "next": "truth", "effects": [{ "set_flag": &"god_friend_truth" }] },
					{ "text": "\"I was going to tell you.\"", "next": "excuse", "effects": [{ "set_flag": &"god_friend_excuse" }] },
					{ "text": "\"It doesn't change anything.\"", "next": "same", "effects": [{ "set_flag": &"god_friend_same" }] },
				],
			},
			"truth": {
				"speaker": "{friend}",
				"text": "I don't know what that means, and I can tell you're not lying. I prayed to you, you know. About you. So you heard that.",
				"next": "stairs",
			},
			"excuse": {
				"speaker": "{friend}",
				"text": "No, you weren't.",
				"next": "stairs",
			},
			"same": {
				"speaker": "{friend}",
				"text": "It changes who I've been talking to.",
				"next": "stairs",
			},
			"stairs": {
				"speaker": "{friend}",
				"text": "...Don't answer. Come on. Stairs. I'm still going up them. I'm just going to be quiet for a bit.",
				"effects": [{ "set_flag": &"god_friend_caught" }],
			},
		},
	},
	&"god_heretic": {
		"start": [
			{ "if": { "flag": &"god_davin_lost" }, "node": "ilse" },
			{ "if": { "any_flag": [&"god_plea_refused", &"god_plea_silent"] }, "node": "plea" },
			{ "node": "stranger" },
		],
		"nodes": {
			"ilse": {
				"style": "system",
				"text": "[ Prayer received. ]\n[ Filed as: complaint. ]",
				"next": "ilse2",
			},
			"ilse2": {
				"speaker": "Ilse",
				"text": "You heard me. I've asked every priest on nine floors, and they all agree: new gods hear everything, they've got so little else to listen to. I said floor 12. I said please. I hope someone does this to you.",
				"next": "answer",
			},
			"plea": {
				"style": "system",
				"text": "[ Prayer received. ]\n[ Filed as: complaint. ]",
				"next": "plea2",
			},
			"plea2": {
				"speaker": "A voice",
				"text": "You know who this is. I asked you for one thing, back when I thought you were someone. I've been telling people. I want you to know I've been telling people.",
				"next": "answer",
			},
			"stranger": {
				"style": "system",
				"text": "[ Prayer received. ]\n[ Filed as: complaint. ]",
				"next": "stranger2",
			},
			"stranger2": {
				"speaker": "A voice",
				"text": "You don't know me. You've never done anything to me. That's the complaint. Forty floors of people praying, and you sit up there picking who gets an answer.",
				"next": "answer",
			},
			"answer": {
				"text": "It's the first prayer you've had that wants nothing from you. You could make it stop. It would be easy.",
				"choices": [
					{ "text": "Listen to all of it.", "next": "heard", "effects": [{ "believers": 1 }, { "set_flag": &"god_heretic_heard" }] },
					{ "text": "Answer: \"You're right.\"", "next": "right", "effects": [{ "set_flag": &"god_heretic_answered" }] },
					{ "text": "Silence them.", "next": "smite", "effects": [{ "believers": -1 }, { "faith": 20 }, { "set_flag": &"god_heretic_smote" }] },
				],
			},
			"heard": {
				"text": "It takes most of the night. You don't reply. When it's over, whoever it was sounds surprised that you stayed.",
			},
			"right": {
				"text": "You send two words. The prayers stop for a while. When they start again they're quieter and they're still angry and they keep coming, which you decide to call faith.",
			},
			"smite": {
				"text": "It's easy. It's the easiest thing you've done since the top. Nobody complains on that line again. Nobody says anything on it at all. You feel fine. You keep checking.",
			},
		},
	},
	&"god_ch5": {
		"start": "a",
		"nodes": {
			"a": { "style": "system", "text": "[ Chapter 5: The Queue ]{worshippers_line}", "next": "b" },
			"b": { "text": "There are floors, now, where nobody has heard of you. You've noticed you sleep better on those." },
		},
	},
	&"god_queue": {
		"start": "a",
		"nodes": {
			"a": { "style": "system", "text": "[ Prayers waiting: 11,302. ]", "next": "b" },
			"b": {
				"text": "You can't hear them one at a time any more. It's a sound now, like rain on a roof you're under. There's a list. You can scroll it. You scroll it.",
				"choices": [
					{ "text": "Keep reading, as many as you can.", "next": "read", "effects": [{ "believers": 1 }, { "set_flag": &"god_queue_read" }] },
					{ "text": "Close the window.", "next": "close", "effects": [{ "faith": 20 }, { "set_flag": &"god_queue_closed" }] },
				],
			},
			"read": {
				"text": "Floor 9: a bad knee. Floor 31: someone's son. Floor 2: a dog. You answer what you can. At dawn the number says 11,340.",
				"next": "slip",
			},
			"close": {
				"text": "The window closes. It takes you a moment to notice that your hands have stopped shaking. Four floors later, you're still counting.",
				"next": "slip",
			},
			"slip": { "style": "glitch", "text": "[ You stop reading them, eventually. ]", "next": "slip2" },
			"slip2": { "style": "system", "text": "[ That was not a system message. ]", "next": "slip3" },
			"slip3": {
				"style": "system",
				"text": "[ Disregard. ]",
				"effects": [{ "set_flag": &"god_saw_queue" }],
			},
		},
	},
	&"god_last_offer": {
		"start": "a",
		"nodes": {
			"a": { "speaker": "{bid1}", "portrait": "{bid1_id}", "text": "{bid1.last_offer}", "next": "b" },
			"b": { "speaker": "{bid2}", "portrait": "{bid2_id}", "text": "{bid2.last_offer}", "next": "c" },
			"c": {
				"text": "They've both stopped talking. For once, the two of them are waiting on you.",
				"choices": [
					{ "text": "Stand with {bid1}.", "next": "ally1",
						"effects": [{ "bid_interest": { "first": 15, "second": -15 } }, { "faith": 60 }, { "set_flag": &"god_allied_first" }] },
					{ "text": "Stand with {bid2}.", "next": "ally2",
						"effects": [{ "bid_interest": { "second": 15, "first": -15 } }, { "faith": 60 }, { "set_flag": &"god_allied_second" }] },
					{ "text": "Neither. I've got people to see to.", "next": "none",
						"effects": [{ "bid_interest": { "first": -5, "second": -5 } }, { "believers": 2 }, { "set_flag": &"god_allied_nobody" }] },
				],
			},
			"ally1": { "speaker": "{bid1}", "portrait": "{bid1_id}", "text": "{bid1.ally}" },
			"ally2": { "speaker": "{bid2}", "portrait": "{bid2_id}", "text": "{bid2.ally}" },
			"none": { "speaker": "{bid1}", "portrait": "{bid1_id}", "text": "{bid1.refused}", "next": "none2" },
			"none2": { "speaker": "{bid2}", "portrait": "{bid2_id}", "text": "{bid2.refused}" },
		},
	},
	&"god_ch6": {
		"start": "a",
		"nodes": {
			"b_alone": { "text": "The air is thin. It's been a long time since anyone joked about the top." },
			"a": { "style": "system", "text": "[ Chapter 6: The Last Prayer ]{worshippers_line}", "next": "b" },
			"b": {
				"alt": [{ "if": { "friend_away": true }, "node": "b_alone" }],
				"text": "The air is thin. {friend} has stopped joking about the top. You didn't notice when." },
		},
	},
	&"god_last_prayer": {
		"start": [
			{ "if": { "flag": &"god_davin_lost" }, "node": "bitter" },
			{ "if": { "flag": &"god_davin_saved", "not_flag": &"god_ilse_answered" }, "node": "unknown" },
			{ "if": { "flag": &"god_davin_saved" }, "node": "thanks" },
			{ "node": "stranger" },
		],
		"nodes": {
			"bitter": {
				"speaker": "Ilse",
				"text": "You don't have to answer this one. You never do. I've stopped hating you, is what I came to say. I ran out. I'm going down to the fire on 12, to sit a while. Nobody's asking you to come.",
				"next": "reply",
			},
			"unknown": {
				"speaker": "Ilse",
				"text": "You don't have to answer this one. You never answered me, did you? I asked around. The old one I thanked had never heard of my brother. So it was somebody else. That's all right. It was enough.",
				"next": "reply",
			},
			"thanks": {
				"speaker": "Ilse",
				"text": "You don't have to answer this one. My brother's got a bad leg and a worse temper, and he's down on floor 4 teaching the little ones to fight. It was enough. That's all I wanted to say. It was enough.",
				"next": "reply",
			},
			"stranger": {
				"speaker": "A voice",
				"text": "You don't have to answer this one. I only prayed to you the once, a long way down. I don't remember what for. It must have come out all right. It was enough.",
				"next": "reply",
			},
			"reply": {
				"style": "system",
				"text": "[ Prayer received. ]\n[ Reply? ]",
				"choices": [
					{ "text": "Answer anyway: \"I heard you.\"", "next": "sent", "effects": [{ "set_flag": &"god_last_answered" }] },
					{ "text": "Let them have the last word.", "next": "kept", "effects": [{ "set_flag": &"god_last_kept" }] },
				],
			},
			"sent": { "text": "You send it. There's no reply. There wasn't meant to be." },
			"kept": { "text": "You leave the window open for the rest of the floor. Nobody else will ever read it." },
		},
	},
	&"god_top": {
		"start": "a",
		"nodes": {
			"b_alone": { "text": "You're going away again, and nobody is here to tell you so. The thought comes in the voice of someone by a fire, a long way down: when you're scared, you, up there, with the title and the candles... who do gods pray to?", "next": "c" },
			"pray5_alone": { "text": "You find you're smiling. A long way below, by a fire, someone looks up and doesn't know why.", "effects": [{ "set_flag": &"god_arc_complete" }] },
			"no_alone": { "text": "Nobody argues. The one person who would have is a long way below you.", "effects": [{ "set_flag": &"god_arc_complete" }] },
			"a": {
				"text": "The last stairs. You've done this before. The air doesn't change. It's only that the noise stops: every prayer you've ever had goes quiet at once, as if the whole tower were holding its breath.",
				"next": "b",
			},
			"b": {
				"alt": [{ "if": { "friend_away": true }, "node": "b_alone" }],
				"speaker": "{friend}",
				"text": "You're doing it again. Going away. Tell me something. When you're scared, you, up there, with the title and the candles... who do gods pray to?",
				"next": "c",
			},
			"c": {
				"text": "You don't know. Nobody told you that part.",
				"choices": [
					{ "text": "Try it.", "next": "pray", "effects": [{ "set_flag": &"god_prayed" }] },
					{ "text": "\"Nobody. That's the job.\"", "next": "no", "effects": [{ "set_flag": &"god_did_not_pray" }] },
				],
			},
			"pray": {
				"text": "You've had it done to you enough times. You know how it goes. You don't know who you're talking to. You say: I'm frightened. Look after them. That's all. Sorry.",
				"next": "pray2",
			},
			"pray2": { "style": "system", "text": "[ Prayer received. ]", "next": "pray3" },
			"pray3": { "style": "system", "text": "[ ... ]", "next": "pray4" },
			"pray4": { "style": "glitch", "text": "[ I heard that. ]", "next": "pray5" },
			"pray5": {
				"alt": [{ "if": { "friend_away": true }, "node": "pray5_alone" }],
				"speaker": "{friend}",
				"text": "What? What is it? ...You're smiling. Don't smile, it's terrifying. Come on. Together. We always have.",
				"effects": [{ "set_flag": &"god_arc_complete" }],
			},
			"no": {
				"alt": [{ "if": { "friend_away": true }, "node": "no_alone" }],
				"text": "{friend} looks at you for a long moment.",
				"next": "no2",
			},
			"no2": {
				"speaker": "{friend}",
				"text": "Then you can borrow me. I've got the hang of it now. Come on. Together. We always have.",
				"effects": [{ "set_flag": &"god_arc_complete" }],
			},
		},
	},
}


## What each domain's people ask of you, and what they get wrong about you
## (the shrine on floor 25). DLC domains fall back on DOMAIN_LINES_DEFAULT.
const DOMAIN_LINES_DEFAULT := {
	"plea": "I've got nobody else to ask. They say you were one of us, once. Is there anything you can do?",
	"grant": "You do what you can. It's less than they think, and it's more than anyone else did.",
	"refuse": "You tell them there's nothing you can do. They thank you for saying so.",
	"creed": "They say you can do anything, for anyone, if they only ask right.",
}
const DOMAIN_LINES := {
	&"valor": {
		"plea": "I'm going back up to face the thing that killed my party, and I'm terrified. They say you never ran. Tell me I won't run.",
		"grant": "You tell them they won't. You don't know that. They go up the stairs anyway.",
		"refuse": "You tell them nobody can promise that, and that you ran plenty. There's a long silence. \"...Thanks. I think.\"",
		"creed": "They say you never once ran. They tell the children that.",
	},
	&"justice": {
		"plea": "A guild took my father's stall, and the court is theirs too. They say you're the new law. Is there any law for someone like me?",
		"grant": "You put a name into the mind of someone who can act on it. Somewhere, a ledger gets opened.",
		"refuse": "You tell them you don't judge one side of anything. They don't thank you.",
		"creed": "They say you can't be lied to. People have started confessing at the shrine, in detail.",
	},
	&"mercy": {
		"plea": "He robbed us and left my mother to die, and I've got him under my knife right now. They say you're merciful. Tell me what to do, because I don't want to be the one who decides.",
		"grant": "You ask them to put it down. After a long time, the knife goes back in its sheath.",
		"refuse": "You tell them it isn't yours to decide, and it isn't theirs to hand off. You never hear how it ends.",
		"creed": "They say you forgive anything. No matter what. No matter who.",
	},
	&"tyranny": {
		"plea": "My floor has no order. Thieves, gangs, three guilds. I'd kneel to anyone who'd make it stop. They say you make things stop.",
		"grant": "You send them your word: take the gang's leader in front of everyone, and say it was by your order. It works horribly well.",
		"refuse": "You tell them you don't rule anything that can't hold itself up. They kneel anyway. It's very quiet.",
		"creed": "They say you only ever wanted what was best for everyone, and that's why it had to be you.",
	},
	&"greed": {
		"plea": "I owe more than I'd earn if I climbed to the top and back. They say you know about money. Show me one way out.",
		"grant": "You show them an unlocked door and whose vault it leads to. They send you a tenth, unprompted. You're touched.",
		"refuse": "You tell them debts are what keep the rest of us honest. They laugh until they don't.",
		"creed": "They say you share with the loyal. You have never shared anything in your life.",
	},
	&"ruin": {
		"plea": "I don't want anything fixed. I want to watch the guild hall on my floor burn. They say you're the one to ask.",
		"grant": "You tell them which beam holds up the roof. You can smell it from here.",
		"refuse": "You tell them one hall is a small ambition. They go quiet, and you can't tell whether that was a no.",
		"creed": "They say you only burn what deserves it. They've drawn up a list on your behalf.",
	},
	&"vengeance": {
		"plea": "I've got a name and no way to reach him. Darrow. He left my sister on floor 6 and took her share. They say you remember. Remember him.",
		"grant": "You remember him. That's all it takes. Three floors up, Darrow stops sleeping, and doesn't know why.",
		"refuse": "You tell them a name isn't enough, and to bring you the whole story. The window snaps shut.",
		"creed": "They say you only punish the guilty, and that you're never wrong about who that is.",
	},
	&"shadow": {
		"plea": "I have to disappear from a guild that doesn't let people disappear. They say nobody saw you climb. How did you do it?",
		"grant": "You show them which stairs the guards don't watch at shift change. By morning there's nobody of that name on any list.",
		"refuse": "You tell them hiding starts with not asking anyone, gods included. They stop praying. You suppose that's the answer working.",
		"creed": "They say you see everything from the dark, and that you're on their side. You're not sure who they think you're watching.",
	},
	&"freedom": {
		"plea": "My contract says I belong to the guild until I've paid back the cost of my own training. The price goes up every year. They say you don't believe in contracts.",
		"grant": "You tell them where the contract is kept, and that fire doesn't read. They run. They don't look back.",
		"refuse": "You tell them nobody gets freed by asking. It's the truest thing you know. It doesn't feel like it helped.",
		"creed": "They say you freed the whole tower, and that nobody has to answer to anyone now. Especially about guild dues.",
	},
	&"twilight": {
		"plea": "I've done some good things and some I can't say out loud. The priests want me one way or the other. They say you don't make people choose.",
		"grant": "You tell them they don't have to. Not today. Somebody breathes out for the first time in years.",
		"refuse": "You tell them everyone chooses, every day, and not choosing is one more. They don't pray again.",
		"creed": "They say that with you, nothing counts. That nothing anyone does is ever really wrong.",
	},
	&"fate": {
		"plea": "Tell me if he comes back. That's all. You're meant to know how things end, and I'd rather know.",
		"grant": "You tell them he does. You've no idea. Now you have to live with having said it.",
		"refuse": "You tell them you don't read the ending for anyone. It's still being written, and they're holding a pen. They call you something unpleasant.",
		"creed": "They say it's all decided, that you decided it, and that nothing is anyone's fault now.",
	},
	&"wanderlust": {
		"plea": "I've been on this floor for eleven years. I keep a shop. I had a plan once. They say you're the one who kept walking. Is it too late to start?",
		"grant": "You tell them it isn't. In the morning the shop's shutters stay down, and someone is very slowly climbing the stairs.",
		"refuse": "You tell them you can't say. You never stopped long enough to find out. They thank you, oddly.",
		"creed": "They say you never stay, so nobody has to either. Just keep moving. Leave whoever you like.",
	},
}

## The story the shrine tells about your last climb (the ending you reached).
const PAST_TALES := {
	&"hero": "You saved every floor on your way up, they say, and you never took a coin.",
	&"villain": "You took every floor on your way up, they say, and you were right to.",
	&"vigilante": "You hunted down the guilty on your way up, they say, and you never missed.",
	&"neutral": "You walked up through every floor without a word, they say, and nobody saw your face.",
	&"none": "You climbed the tower once, they say, and that's all anyone knows.",
}

## The being who blessed your last climb, when they're allowed to speak
## (past_patron_voice). By what they are.
const PATRON_REMEMBERS := {
	"god": "I gave you my blessing once, and you climbed straight past me. I do not ask for it back. I ask whether you remember who carried you.",
	"demon": "You wore my mark all the way to the top, little god. You'll find it's harder to get the smell of me off than you thought.",
	"devil": "We had a contract. It expired at the top of the tower, in your favour, I'm told. I'd hate for you to think I've closed the file.",
}


## Who bids for the Tester in Chapter 2 (Hayden 2026-11-04: different gods make
## for different runs). One rival pair per run, picked once by bid_pair(): the
## pair you already lean toward is likelier, a blessing from either settles it,
## and each run rolls a little luck. "first" asks for patience and pays in truth;
## "second" tempts. Living-religion figures stay out of this (validated), and
## the pair must be enemies in their own myths (Hayden: pairings have to make
## sense), so: real rivals in BeingLibrary, same pantheon. Text tokens: {bid1}, {bid2},
## {bid1_id}, {bid2_id}, {bid1.<line>}, {bid2.<line>}.
const BID_LUCK := 12
const BID_BLESSED := 100
const BID_FIRST_LINES := ["omen", "marked", "offer", "truth", "refuse", "his", "claim"]
const BID_SECOND_LINES := ["hook", "offer", "answer", "why", "out", "claim"]
## Both gods' lines when they meet you again in New Game+ (the same pair returns:
## they remember you). "peer" talks to a god, "mortal" to a climber who came back.
const NG_BID_LINES := ["recall_yes", "recall_no", "peer", "mortal", "yes", "no", "last_offer", "ally", "refused", "strike"]
const BID_PAIRS := [
	{ "first": &"odin", "second": &"loki",
		"first_lines": {
			"omen": "The torches on this floor burn low all at once. A raven lands on nothing, and looks at you with one eye.",
			"marked": "The torches burn low all at once. A raven lands on nothing, and looks at the mark you carry with open distaste.",
			"offer": "So you are the one they sent. I traded an eye to know what's coming, and I still did not see you. I would like to know why, and I pay for what I learn.",
			"truth": "A small truth, then, as a down payment. There was a Tester before you. Nobody remembers how they ended. That is what should trouble you.",
			"refuse": "Good. The ones who kneel at once are never worth the eye. I will ask again, when you've bled a little more.",
			"his": "Mine already, and still they whisper your name in other halls. Listen well, Tester. You are not the first I have watched climb.",
			"claim": "Well struck. Loki has been telling everyone you are his. I would prove him wrong, if I were you, and I would do it soon.",
			"recall_yes": "You again. Last time you asked what I knew, I told you, and you climbed to the top anyway. I have been thinking about that since, which I do not do for many.",
			"recall_no": "You told me you do not work for gods. Then you climbed to the top of them. I did laugh when the ravens told me. It had been some centuries.",
			"peer": "You sit at the table now, small as your chair is. So I will not ask you to serve. I will ask you to trade: what you have seen from outside, for what I have seen from within.",
			"mortal": "You stood at the top and came down with no title. Nobody has done that. Tell me why, and I will tell you something true.",
			"yes": "Then here is my half. The one before you climbed as you do, and came back as you do. I watched it happen again and again. I never learned how many times.",
			"no": "As you like. You will find, on your side of the table, that nobody else offers.",
			"last_offer": "I have hanged on a tree for less than you know now. Stand with me when the tower's war comes, and nothing you have seen will go unread.",
			"ally": "Good. Do not expect thanks. Expect to be asked.",
			"refused": "Then keep your small flock. I have seen what comes of that, and I hope, a little, to be wrong.",
			"strike": "Nothing personal, little god. I wished to see what your people do when the roof burns. It is how I learn things.",
		},
		"second_lines": {
			"hook": "Lovely work. Don't get up. Has the old man been at you yet, with the one eye and the terribly serious voice? He'll want your whole life for one good answer.",
			"offer": "Me, I'll give you the answer free, and you can owe me whatever you think it was worth. Everyone says that's a bad deal. Everyone's so dull.",
			"answer": "The window you keep reading? Ask who's writing it. And ask why it's so very careful around you.",
			"why": "Because you can leave, darling. Nobody else in this tower can. Imagine what we'd give to learn how.",
			"out": "Oh, I like that. Say it again when you're less sure I'm in there.",
			"claim": "That's my Tester! Oh, the old man's going to be sour about this. He'll send someone. I can hardly wait.",
			"recall_yes": "There's my favourite customer! You never did pay me, you know. I've been letting it build.",
			"recall_no": "\"Get out of my head,\" you said. I've had it embroidered. How's the climb? Itchy?",
			"peer": "Look at you. Title, shrine, terrible little people. I've got a proposition, one fraud to another: you tell me how you got out, and I'll tell you who's been reading your mail.",
			"mortal": "You went all the way up and didn't take the job? Oh, I love you. Why are you back? No, tell me the interesting lie.",
			"yes": "Who reads your mail? The same one who reads mine, darling. I've never once managed to surprise them. Do try.",
			"no": "Oh, you'll be back. They all come back. That's rather your whole thing, isn't it?",
			"last_offer": "Last chance, darling. The old man wants a war. I want to see it go wrong. Come and help me, it'll be so much better than being good at this.",
			"ally": "Oh, this will end terribly. I'm so pleased.",
			"refused": "Spoilsport. I'll remember this. I won't do anything about it. But I'll remember.",
			"strike": "Oops! Was that your shrine? I was aiming at your whole idea of yourself. Close enough.",
		} },
	{ "first": &"zeus", "second": &"typhon",
		"first_lines": {
			"omen": "The air turns sharp and tastes of iron. Thunder rolls through a floor with no sky, and every hair on your arms stands up.",
			"marked": "The air turns sharp and tastes of iron. Thunder rolls through a floor with no sky, and the mark you carry prickles like a burn.",
			"offer": "I have thrown down giants and fathers, and I know a threat to my throne when it walks. Or a weapon. Stand where I can see you, and I will tell you which you are.",
			"truth": "Then hear this, and be humbled. Another Tester stood where you stand. I watched them climb. I cannot recall their face, and I forget nothing.",
			"refuse": "Bold. I have struck down kings for less, and raised up a few of them for exactly that. We will speak again.",
			"his": "You wear my favour, and still the others circle you. Know this, Tester: you are not the first to wear it. The last one I cannot name, and that angers me.",
			"claim": "Well fought. The monster in the deep has been roaring your name as if it owned you. Remind him who holds the lightning.",
			"recall_yes": "You stood before me once and asked what I knew. Few ask twice, and fewer are still standing. You have earned the right to bore me.",
			"recall_no": "You told me no, and lived, and rose. I have struck down kings for less, as I said. I confess I expected to be saying it again by now.",
			"peer": "A new throne, and a very small one. Understand me: I do not share the sky. But a king may treat with another king, if that king keeps to his place.",
			"mortal": "You reached the top and refused the crown it offered? Either you are a fool or you know something. Speak, and I will judge which.",
			"yes": "Then hear it. I have sat on this throne since the giants fell, and I have begun to lose things. A face. A name. Only here, only in this tower. Find out why, and you will have a friend in the sky.",
			"no": "You will kneel yet, or burn. I have patience for either.",
			"last_offer": "War is coming to the tower, and it will end with one throne standing. Stand at my right hand, and yours may be the second.",
			"ally": "Done. Let the deep hear thunder, then.",
			"refused": "Then when the sky falls, do not pray to me. I hear you have people for that.",
			"strike": "You set yourself up beneath my sky and let them pray to you in my hearing. This is what a king does about that.",
		},
		"second_lines": {
			"hook": "SMALL THING. YOU KILL WELL. The floor shakes with every word. The thunder-king buried me under a mountain, and I can still hear you climbing over my head.",
			"offer": "HE WILL ASK YOU TO KNEEL. I ASK NOTHING. BREAK WHAT YOU LIKE, AND TELL ME HOW IT FELT. WHAT IS AN ANSWER WORTH TO YOU?",
			"answer": "THE VOICE IN YOUR WINDOWS IS NO GOD. I KNOW ALL THE GODS. I HAVE EATEN SOME. ASK IT WHAT IT IS.",
			"why": "BECAUSE NO WALL HOLDS YOU, SMALL THING. YOU GO OUT AND YOU COME BACK. I HAVE WANTED OUT FOR A VERY LONG TIME.",
			"out": "HA. GOOD. THE MOUNTAIN IS TOO QUIET. KEEP SHOUTING AT ME.",
			"claim": "YES. YES, BREAK IT ALL. THE THUNDER-KING HEARD THAT. LET HIM COME DOWN AND TAKE YOU FROM ME.",
			"recall_yes": "SMALL THING. YOU CAME BACK. YOU BROKE THINGS. I LISTENED. THE MOUNTAIN LIKED IT.",
			"recall_no": "YOU SHOUTED AT ME ONCE. NOBODY SHOUTS AT ME. DO IT AGAIN.",
			"peer": "THEY GAVE YOU A NAME AND A SMALL ROOF. THEY DID THAT TO ME ALSO. THEN THEY PUT THE MOUNTAIN ON. DIG WITH ME BEFORE THEY DO.",
			"mortal": "YOU SAW THE TOP AND CAME BACK DOWN WITH NOTHING. WHY. NOBODY DOES THAT. I WOULD LIKE TO EAT THE REASON.",
			"yes": "GOOD. I TRIED TO EAT THE ONE BEFORE YOU. THERE WAS NOTHING THERE TO EAT. THINK ABOUT THAT.",
			"no": "HA. KEEP IT. I WILL BE UNDER YOU THE WHOLE WAY UP.",
			"last_offer": "THE SKY WILL BREAK SOON. I WILL BE UNDER IT. BREAK IT WITH ME, SMALL GOD, AND I WILL EAT YOU LAST.",
			"ally": "YES. LAST. I PROMISE. I HAVE NEVER PROMISED BEFORE.",
			"refused": "THEN I WILL EAT YOU WHEN I GET TO YOU. IT IS NOT PERSONAL. NOTHING IS.",
			"strike": "I HEARD YOUR LITTLE PEOPLE THROUGH THE ROCK. THEY WOULD NOT STOP. SO I ROLLED OVER.",
		} },
	{ "first": &"ra", "second": &"apep",
		"first_lines": {
			"omen": "There is no sun in the tower. Now there is light on your face anyway, warm and level, as if a dawn has stopped to look at you.",
			"marked": "There is no sun in the tower. Now there is light on your face anyway, and the mark you carry casts a shadow it shouldn't.",
			"offer": "Every night I cross the dark and every morning I return, and I have never once seen anyone do what you do. Walk in my light a while. I reward those who keep the order of things.",
			"truth": "Then I will light one corner for you. Someone came before you, Tester. They went into the night, as all do. They are the first I have not seen come out of it.",
			"refuse": "As you like. The sun does not beg. It will be here in the morning, and so will my question.",
			"his": "You walk in my light, and still the dark calls your name. Hear me: another walked here before you, and my light could not follow them.",
			"claim": "The day is yours. The serpent has been hissing that the dark already has you. Prove it a liar before my next crossing.",
			"recall_yes": "You walked in my light once, and asked what it showed. I have crossed the dark many nights since, and I kept your question with me.",
			"recall_no": "The sun does not beg, I told you. And here I am again in the morning, as promised. You have changed. I have not.",
			"peer": "So the tower has lit another lamp. Small, and smoky, and yours. There is room in the sky for a small light, if it keeps the order of things.",
			"mortal": "You stood at the summit and would not shine. I do not understand it. Walk a while in my light, and explain it to me.",
			"yes": "Then take this, lamp to lamp. Those who pray to you are lighting you, and you will burn what they give you. The one before you burned a long while. Then I could not find them.",
			"no": "As you like. I rise regardless. Try doing the same, when they stop asking you to.",
			"last_offer": "The dark is climbing. All the lights must stand together or go out alone. Stand with me, and those who pray to you will see morning.",
			"ally": "Then walk in my light, and let it be known.",
			"refused": "Then keep your little flame. I will look for it on my crossings. I cannot promise to find it.",
			"strike": "Disorder must be answered, even when it is small and means no harm. Your shrine was lit without my leave. Forgive the morning.",
		},
		"second_lines": {
			"hook": "Sssuch a bright little thing, and so far from morning. Every night I try to swallow the sun, you know. Every night I come so close. I do admire persistence.",
			"offer": "He gives his truths a sliver at a time, and calls it mercy. I give you the whole dark at once. Ask, and owe me only what you can't remember owing.",
			"answer": "The one who writes in your little windows does not sleep, and does not cross. Ask what it does all night.",
			"why": "Because you step off the world, little flame, and step back on. I have coiled round the whole of creation and found no such door. Show me.",
			"out": "Mmm. They all say that, in the daylight.",
			"claim": "Sweet little flame. You've made the old sun nervous. Do come down and see me, when the lights go out.",
			"recall_yes": "Sssweet little flame, you came back. I did say you would owe me what you couldn't remember owing. Do you remember?",
			"recall_no": "They all say that in the daylight, I told you. And here we are, and how dark it's getting.",
			"peer": "A god now! And they light candles to you. I do so love a candle. Come, one swallower to another: what will you do when they have all gone out?",
			"mortal": "You reached the top of the world and you didn't swallow it. Why ever not? Tell me, and I shall tell you where the night goes.",
			"yes": "The night doesn't go anywhere, little flame. It comes here. It climbs. And what writes in your windows has never once been afraid of it.",
			"no": "Mmm. Say it again when the candles gutter. I'll be nearer then.",
			"last_offer": "He will ask you to keep the morning going. So tiresssome. Come and let it end, little flame. You've no idea how restful.",
			"ally": "Ahhh. Come close. Closer. There.",
			"refused": "No matter. I have tried to eat the sun every night for a very long time, and I only ever need to succeed once.",
			"strike": "Your little candles were so bright. I only meant to taste one.",
		} },
	{ "first": &"anubis", "second": &"set",
		"first_lines": {
			"omen": "The floor goes quiet in a way you can feel in your teeth. A black jackal sits at the far end of the corridor, watching you with no hurry at all.",
			"marked": "The floor goes quiet in a way you can feel in your teeth. A black jackal watches the mark you carry, and then, patiently, you.",
			"offer": "I have weighed every heart that ever stopped. Yours does not sit on the scale the way it should. Walk with me a little. I only wish to understand, and I am never in a rush.",
			"truth": "Then you are owed an honest measure. There was a Tester before you. I have weighed all the dead of this tower, and I have not weighed them.",
			"refuse": "That is your right. I do not chase anyone. In the end, everyone comes to me, and I will ask you again then.",
			"his": "You have my favour, and I keep my books honest. So: another Tester came before you. Their heart has never reached my scale. I would like to know why.",
			"claim": "Fairly done. The red one has been saying you belong to him. Nobody belongs to him. Everyone, eventually, comes to me.",
			"recall_yes": "You asked me for an honest measure once, and you took it well. Few do. I have kept the page open.",
			"recall_no": "You told me no. I said I would ask again when you came to me. You have come to me, though not in the way I expected.",
			"peer": "You hold a title now, and your heart will never reach my scale, and I find that troubling. Walk with me, one keeper of accounts to another. Someone is praying to you who should have been mine.",
			"mortal": "You came to the top and did not take the title. Your heart still does not sit on my scale the way it should. Walk with me. I wish to understand.",
			"yes": "Then here is the balance. Those who die praying to you are not coming to me. I do not know where they go. Do you?",
			"no": "That is your right. I can wait. I can always wait.",
			"last_offer": "Whatever comes next, someone will have to keep the count of the dead honestly. Stand with me, and I will see your people weighed, each one, fairly.",
			"ally": "It is written. I am never in a rush, but I am glad.",
			"refused": "That is your right. Everyone comes to me in the end, though I have started to wonder about you.",
			"strike": "This was not my hand, exactly. I only stopped holding back those who would have done it sooner. Your dead will be weighed fairly. That is all I promise.",
		},
		"second_lines": {
			"hook": "Ha! Now that's a killing. Sand hisses along the floor. Did the dog talk to you yet? All that patience. All those scales. Nobody ever got anywhere by waiting, friend.",
			"offer": "I killed a king for his throne, and I'd do it again, and I'd tell you how. Ask me anything. I don't keep books. You can pay me whenever it hurts most.",
			"answer": "That voice in your windows keeps its own scales, friend, and you're on them. Why else would it grade you?",
			"why": "Because you walk out of the storm and back in again, and nobody weighs you when you do. A man could do a lot with a trick like that.",
			"out": "Ha! Good. Hate me. It's the first honest thing anyone's done in this tower.",
			"claim": "That's the way! Take it, whatever it is! The dog'll tell you it all gets weighed in the end. So make it heavy.",
			"recall_yes": "Ha! You again, friend! You asked me straight, and I told you straight. Did you ever pay? Doesn't matter. It'll hurt later.",
			"recall_no": "You told me to get out of your head. So I did. Did you miss me, friend?",
			"peer": "So you took the throne! I've done that. Killed a king for mine. The trouble isn't getting it, friend, it's the whining after. Want to know how I deal with the whining?",
			"mortal": "You had the throne right there in front of you and you walked off? That's the stupidest thing I've ever heard. Tell me why. I could use a laugh.",
			"yes": "Here's how: you stop pretending you owe them anything. The one before you never learned that, and look. Nobody can even find them.",
			"no": "Suit yourself. When it's too loud to sleep, you know who to ask.",
			"last_offer": "There's a storm coming up these stairs. Big one. The dog will tell you to wait and see. Stand with me and we'll ride it, and whoever's left can weigh what they like.",
			"ally": "That's the way! Bring your whiners. They burn fine.",
			"refused": "Ha! Fine. I'll see you in the storm, friend. I won't look for you. I won't look out for you either.",
			"strike": "Sand gets in everywhere, friend. Your little shrine had it coming. I didn't check why.",
		} },
]


## The real world comes back at milestones (Hayden 2026-11-04): the prologue
## room again, with its objects' dialogues named "<id>_<object>" and a talk
## "<id>_back" once you're back in the tower. Each plays once per run.
## Only the first is built: the first tier-2 advancement. New Game+ characters
## start past it, so it's first runs only.
const RETURN_TIER2 := &"return_tier2"
## The talk when the friend comes back from a campfire, and the flag that says
## they missed part of the story while they were gone (set whenever an alternate
## friend_away node plays; the reunion clears it).
const FRIEND_REUNION := &"friend_reunion"
const FRIEND_MISSED_FLAG := &"friend_missed_scene"
## New Game+: Ascending (or being the Ascendant) past the Ascension gate's floor.
const RETURN_ASCEND := &"return_ascend"
const RETURN_TIER3 := &"return_tier3"
const RETURNS := [RETURN_TIER2, RETURN_TIER3, RETURN_ASCEND]


## The real-world return that's due now, or &"".
static func return_due() -> StringName:
	var gs := GameState
	if not gs.run_active or not gs.player.has_class():
		return &""
	if gs.ng_plus_cycle > 0:
		var ascended := gs.player.ascended or gs.player.class_id == &"ascendant"
		var high_enough := gs.highest_floor > ClassRegistry.ASCENSION_GATE.floor
		return RETURN_ASCEND if ascended and high_enough and not gs.has_flag(RETURN_ASCEND) else &""
	var tier := gs.player.get_class_def().tier
	if tier >= 2 and not gs.has_flag(RETURN_TIER2):
		return RETURN_TIER2
	if tier >= 3 and not gs.has_flag(RETURN_TIER3):
		return RETURN_TIER3
	return &""


# =========================================================
# What the gods remember (Hayden 2026-11-04)
# =========================================================

## Run flags -> what the character's next New Game+ remembers of them.
const PAST_FLAG_MAP := {
	&"ch2_heard_first": &"past_heard_first",
	&"ch2_heard_second": &"past_heard_second",
	&"ch2_refused_first": &"past_refused_first",
	&"ch2_refused_second": &"past_refused_second",
	&"ch1_warned_tess": &"past_warned_tess",
}
const PAST_PATRON_PREFIX := "past_patron_"
const PAST_ENDING_PREFIX := "past_ending_"


## What this run leaves behind in the Hall for the next New Game+: the bidding
## pair (same gods again, so they can remember), who you listened to and refused,
## who blessed you, and how it ended.
static func past_flags(ending_id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for pair in BID_PAIRS:
		var flag := StringName("bid_pair_%s" % pair.first)
		if GameState.has_flag(flag):
			out.append(flag)
	for f in PAST_FLAG_MAP:
		if GameState.has_flag(f):
			out.append(PAST_FLAG_MAP[f])
	if GameState.player.blessing_id != &"":
		out.append(StringName(PAST_PATRON_PREFIX + String(GameState.player.blessing_id)))
	if ending_id != &"":
		out.append(StringName(PAST_ENDING_PREFIX + String(ending_id)))
	return out


## Is this (from a Hall file) a flag past_flags() could have written? A record
## can only ever start New Game+ with memories, never with progress.
static func is_past_flag(f: Variant) -> bool:
	if not f is String or f.length() > 128:
		return false
	return f.begins_with("past_") or f.begins_with("bid_pair_")


## The being who blessed your last climb, or &"" (gone from the roster = none).
static func past_patron() -> StringName:
	for f in GameState.story_flags:
		if GameState.story_flags[f] and String(f).begins_with(PAST_PATRON_PREFIX):
			var id := StringName(String(f).trim_prefix(PAST_PATRON_PREFIX))
			var being := BeingLibrary.get_being(id)
			if not being.is_empty() and not being.get("self", false):
				return id
	return &""


## "speaks", "silent" (a living-religion figure: only a quiet, respectful
## presence, never a speaking role in this story) or "none".
static func past_patron_voice() -> String:
	var id := past_patron()
	if id == &"":
		return "none"
	return "silent" if BeingLibrary.get_being(id).get("living", false) else "speaks"


## The floor's guild's patron, or &"" if there isn't one (or it's you).
static func floor_patron() -> StringName:
	var ruler := GameState.guilds.owner_of_floor(GameState.floor_number)
	if ruler == &"":
		return &""
	var patron: StringName = GuildLibrary.get_guild(ruler).get("patron", &"")
	return &"" if patron == GameState.divinity.god_id else patron


## Which bidder wants you hurt: the one you didn't side with ("first"/"second").
static func foe_side() -> String:
	var first := GameState.has_flag(&"ng_sided_first")
	var second := GameState.has_flag(&"ng_sided_second")
	return "first" if second and not first else "second"


## Every story token: the bidders' and the god storyline's.
static func fill_story_tokens(s: String) -> String:
	return fill_god_tokens(fill_bid_tokens(s))


## {god_title}, {god_domain}, {god.<line>}, {believers}, {worshippers_line},
## {cycle}, {old_patron}, {old_patron_id}, {patron.remember}, {past_tale},
## {floor_patron}, {foe}, {foe_id}, {foe.<line>}. Safe for anyone: the dev sandbox
## or a non-god gets neutral words rather than a raw token.
static func fill_god_tokens(s: String) -> String:
	if not s.contains("{"):
		return s
	var out := s
	var dv: DivinityState = GameState.divinity
	if out.contains("{foe"):
		var side := foe_side()
		var pair := bid_pair()
		var being: StringName = pair[side]
		var lines: Dictionary = pair["%s_lines" % side]
		for key in lines:
			out = out.replace("{foe.%s}" % key, lines[key])
		out = out.replace("{foe_id}", String(being)).replace("{foe}", BeingLibrary.get_being(being).get("name", "?"))
	if out.contains("{god"):
		var lines: Dictionary = DOMAIN_LINES.get(dv.domain, DOMAIN_LINES_DEFAULT)
		for key in lines:
			out = out.replace("{god.%s}" % key, lines[key])
		var domain_name: String = DomainLibrary.get_domain(dv.domain).get("name", "nothing yet")
		out = out.replace("{god_title}", dv.title if dv.active else "a new god").replace("{god_domain}", domain_name)
	out = out.replace("{believers}", str(dv.believers)).replace("{cycle}", str(GameState.ng_plus_cycle + 1)) \
		.replace("{worshippers_line}", "\n[ Worshippers: %d. ]" % dv.believers if dv.active else "")
	if out.contains("{old_patron") or out.contains("{patron."):
		var patron := past_patron()
		var being := BeingLibrary.get_being(patron)
		out = out.replace("{old_patron_id}", String(patron)).replace("{old_patron}", being.get("name", "someone")) \
			.replace("{patron.remember}", PATRON_REMEMBERS.get(being.get("kind", "god"), PATRON_REMEMBERS.god))
	if out.contains("{past_tale}"):
		var tale: String = PAST_TALES.none
		for ending in PAST_TALES:
			if GameState.has_flag(StringName(PAST_ENDING_PREFIX + String(ending))):
				tale = PAST_TALES[ending]
		out = out.replace("{past_tale}", tale)
	if out.contains("{floor_patron}"):
		var fp := floor_patron()
		out = out.replace("{floor_patron}", BeingLibrary.get_being(fp).get("name", "our patron") if fp != &"" else "our patron")
	return out


## This run's bidders (one of BID_PAIRS). Picked the first time anyone asks, and
## kept as a flag ("bid_pair_<first>") so it stays the same for the whole run.
static func bid_pair() -> Dictionary:
	for pair in BID_PAIRS:
		if GameState.has_flag(StringName("bid_pair_%s" % pair.first)):
			return pair
	var rng := RandomNumberGenerator.new()
	rng.seed = ("%s:bidders" % GameState.player.legacy_id).hash()
	var best: Dictionary = BID_PAIRS[0]
	var best_score := -INF
	for pair in BID_PAIRS:
		var score := float(GameState.blessings.interest(pair.first) + GameState.blessings.interest(pair.second)) \
			+ rng.randf_range(0.0, BID_LUCK)
		if GameState.player.blessing_id == pair.first or GameState.player.blessing_id == pair.second:
			score += BID_BLESSED
		if score > best_score:
			best_score = score
			best = pair
	GameState.story_flags[StringName("bid_pair_%s" % best.first)] = true
	return best


## Fills {bid1}, {bid2}, {bid1_id}, {bid2_id}, {bid1.line}, {bid2.line}.
static func fill_bid_tokens(s: String) -> String:
	if not s.contains("{bid"):
		return s
	var pair := bid_pair()
	var out := s.replace(".ng_offer}", ".peer}" if GameState.divinity.active else ".mortal}")
	for side in [["bid1", "first", "first_lines"], ["bid2", "second", "second_lines"]]:
		var being: StringName = pair[side[1]]
		var lines: Dictionary = pair[side[2]]
		for key in lines:
			out = out.replace("{%s.%s}" % [side[0], key], lines[key])
		out = out.replace("{%s_id}" % side[0], String(being)) \
			.replace("{%s}" % side[0], BeingLibrary.get_being(being).get("name", "?"))
	return out


static func get_dialogue(id: StringName) -> Dictionary:
	return DIALOGUES.get(id, {})


## Chapter number (1-based) for a floor: one per stage.
static func chapter_for_floor(n: int) -> int:
	return clampi((maxi(1, n) - 1) / StageLibrary.FLOORS_PER_STAGE + 1, 1, CHAPTERS.size())


## "Chapter 1: Tester".
static func chapter_name(chapter: int) -> String:
	var i := clampi(chapter, 1, CHAPTERS.size()) - 1
	var titles: Array = GOD_CHAPTERS if GameState.divinity.active else CHAPTERS
	return "Chapter %d: %s" % [i + 1, titles[i].title]


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
		for prefix in [&"prologue"] + RETURNS:
			if not DIALOGUES.has(StringName("%s_%s" % [prefix, obj])):
				problems.append("%s object %s has no dialogue" % [prefix, obj])
	for home in RETURNS:
		if not DIALOGUES.has(StringName("%s_back" % home)):
			problems.append("%s has no talk back in the tower" % home)
	for domain in DomainLibrary.BASE_DOMAINS:
		for key in DOMAIN_LINES_DEFAULT:
			if String(DOMAIN_LINES.get(domain, {}).get(key, "")) == "":
				problems.append("domain %s: missing line %s" % [domain, key])
	for ending in RouteLibrary.endings:
		if not PAST_TALES.has(ending.id):
			problems.append("ending %s has no past tale" % ending.id)
	if GOD_CHAPTERS.size() != CHAPTERS.size():
		problems.append("the god chapters don't match the chapters")
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
	for pair in BID_PAIRS:
		for side in ["first", "second"]:
			var b := BeingLibrary.get_being(pair[side])
			if b.is_empty():
				problems.append("bid pair: unknown being %s" % pair[side])
			elif b.get("living", false):
				problems.append("bid pair: %s is from a living religion" % pair[side])
			elif b.get("skill", &"") == &"":
				problems.append("bid pair: %s has no blessing skill" % pair[side])
		if not BeingLibrary.rivals_of(pair.first).has(pair.second):
			problems.append("bid pair: %s and %s aren't rivals" % [pair.first, pair.second])
		if BeingLibrary.get_being(pair.first).get("pantheon") != BeingLibrary.get_being(pair.second).get("pantheon"):
			problems.append("bid pair: %s and %s are from different myths" % [pair.first, pair.second])
		for key in BID_FIRST_LINES:
			if String(pair.first_lines.get(key, "")) == "":
				problems.append("bid pair %s: missing line %s" % [pair.first, key])
		for key in BID_SECOND_LINES:
			if String(pair.second_lines.get(key, "")) == "":
				problems.append("bid pair %s: missing line %s" % [pair.second, key])
		for key in NG_BID_LINES:
			for side in [[pair.first, pair.first_lines], [pair.second, pair.second_lines]]:
				if String(side[1].get(key, "")) == "":
					problems.append("bid pair %s: missing New Game+ line %s" % [side[0], key])
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
