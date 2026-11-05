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
	{ "title": "The Bidding War" },
	{ "title": "The Top They Promised" },
	{ "title": "First Drafts" },
	{ "title": "The Tenants" },
	{ "title": "One More Day" },
	{ "title": "Recognition" },
]
## New Game+ for a character who isn't a god: "The One It Kept" (story bible).
const NG_CHAPTERS := [
	{ "title": "Tester" },
	{ "title": "The Bidding" },
	{ "title": "The Door, Again" },
	{ "title": "Second Hand" },
	{ "title": "Whose War" },
	{ "title": "Tell Them" },
	{ "title": "Second Drafts" },
	{ "title": "The Tenants, Again" },
	{ "title": "Going Down" },
	{ "title": "The One It Kept" },
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

## The game inside the game, and the real game's title (Hayden 2026-11-05).
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
	&"ng_why": { "chapter": 1, "floors": [1], "when": "enter", "dialogue": &"ng_why", "if": { "ng_plus": true } },
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
	&"ch3_opening": { "chapter": 3, "floors": [21], "when": "enter", "dialogue": &"ch3_opening", "if": { "ng_plus": false } },
	&"ch3_warning": { "chapter": 3, "floors": [22, 23], "when": "enter", "dialogue": &"ch3_warning", "if": { "ng_plus": false } },
	&"ch3_small_talk": { "chapter": 3, "floors": [24], "when": "guardian_down", "dialogue": &"ch3_small_talk", "if": { "ng_plus": false } },
	&"ch3_ledger": { "chapter": 3, "floors": [25], "when": "enter", "dialogue": &"ch3_ledger", "if": { "ng_plus": false } },
	&"ch3_door": { "chapter": 3, "floors": [26, 27], "when": "enter", "dialogue": &"ch3_door", "if": { "ng_plus": false } },
	&"ch3_doubt": { "chapter": 3, "floors": [28], "when": "enter", "dialogue": &"ch3_doubt", "if": { "ng_plus": false } },
	&"ch3_last_page": { "chapter": 3, "floors": [29], "when": "guardian_down", "dialogue": &"ch3_last_page", "if": { "ng_plus": false } },
	&"ch3_brace": { "chapter": 3, "floors": [30], "when": "enter", "dialogue": &"ch3_brace", "if": { "ng_plus": false } },
	&"ch3_end": { "chapter": 3, "floors": [30], "when": "guardian_down", "dialogue": &"ch3_end", "if": { "ng_plus": false } },
	&"ng3_opening": { "chapter": 3, "floors": [21], "when": "enter", "dialogue": &"ng3_opening", "if": { "ng_plus": true } },
	&"ng3_warning": { "chapter": 3, "floors": [22, 23], "when": "enter", "dialogue": &"ng3_warning", "if": { "ng_plus": true } },
	&"ng3_small_talk": { "chapter": 3, "floors": [24], "when": "guardian_down", "dialogue": &"ng3_small_talk", "if": { "ng_plus": true } },
	&"ng3_ledger": { "chapter": 3, "floors": [25], "when": "enter", "dialogue": &"ng3_ledger", "if": { "ng_plus": true } },
	&"ng3_door": { "chapter": 3, "floors": [26, 27], "when": "enter", "dialogue": &"ng3_door", "if": { "ng_plus": true } },
	&"ng3_doubt": { "chapter": 3, "floors": [28], "when": "enter", "dialogue": &"ng3_doubt", "if": { "ng_plus": true } },
	&"ng3_last_page": { "chapter": 3, "floors": [29], "when": "guardian_down", "dialogue": &"ng3_last_page", "if": { "ng_plus": true } },
	&"ng3_brace": { "chapter": 3, "floors": [30], "when": "enter", "dialogue": &"ng3_brace", "if": { "ng_plus": true } },
	&"ng3_end": { "chapter": 3, "floors": [30], "when": "guardian_down", "dialogue": &"ng3_end", "if": { "ng_plus": true } },
	&"ch4_opening": { "chapter": 4, "floors": [31], "when": "enter", "dialogue": &"ch4_opening", "if": { "ng_plus": false } },
	&"ch4_second_hand": { "chapter": 4, "floors": [32, 33], "when": "enter", "dialogue": &"ch4_second_hand", "if": { "ng_plus": false } },
	&"ch4_comments": { "chapter": 4, "floors": [34], "when": "guardian_down", "dialogue": &"ch4_comments", "if": { "ng_plus": false } },
	&"ch4_marn": { "chapter": 4, "floors": [35], "when": "enter", "dialogue": &"ch4_marn", "if": { "ng_plus": false } },
	&"ch4_expected": { "chapter": 4, "floors": [36, 37], "when": "enter", "dialogue": &"ch4_expected", "if": { "ng_plus": false } },
	&"ch4_summer": { "chapter": 4, "floors": [38], "when": "enter", "dialogue": &"ch4_summer", "if": { "ng_plus": false } },
	&"ch4_first_name": { "chapter": 4, "floors": [39], "when": "guardian_down", "dialogue": &"ch4_first_name", "if": { "ng_plus": false } },
	&"ch4_threshold": { "chapter": 4, "floors": [40], "when": "enter", "dialogue": &"ch4_threshold", "if": { "ng_plus": false } },
	&"ch4_end": { "chapter": 4, "floors": [40], "when": "guardian_down", "dialogue": &"ch4_end", "if": { "ng_plus": false } },
	&"ng4_opening": { "chapter": 4, "floors": [31], "when": "enter", "dialogue": &"ng4_opening", "if": { "ng_plus": true } },
	&"ng4_second_hand": { "chapter": 4, "floors": [32, 33], "when": "enter", "dialogue": &"ng4_second_hand", "if": { "ng_plus": true } },
	&"ng4_comments": { "chapter": 4, "floors": [34], "when": "guardian_down", "dialogue": &"ng4_comments", "if": { "ng_plus": true } },
	&"ng4_marn": { "chapter": 4, "floors": [35], "when": "enter", "dialogue": &"ng4_marn", "if": { "ng_plus": true } },
	&"ng4_gods": { "chapter": 4, "floors": [36, 37], "when": "enter", "dialogue": &"ng4_gods", "if": { "ng_plus": true } },
	&"ng4_summer": { "chapter": 4, "floors": [38], "when": "enter", "dialogue": &"ng4_summer", "if": { "ng_plus": true } },
	&"ng4_copy": { "chapter": 4, "floors": [39], "when": "guardian_down", "dialogue": &"ng4_copy", "if": { "ng_plus": true } },
	&"ng4_threshold": { "chapter": 4, "floors": [40], "when": "enter", "dialogue": &"ng4_threshold", "if": { "ng_plus": true } },
	&"ng4_end": { "chapter": 4, "floors": [40], "when": "guardian_down", "dialogue": &"ng4_end", "if": { "ng_plus": true } },
	&"ch5_opening": { "chapter": 5, "floors": [41], "when": "enter", "dialogue": &"ch5_opening", "if": { "ng_plus": false } },
	&"ch5_camp": { "chapter": 5, "floors": [42, 43], "when": "enter", "dialogue": &"ch5_camp", "if": { "ng_plus": false } },
	&"ch5_stop_correcting": { "chapter": 5, "floors": [44], "when": "guardian_down", "dialogue": &"ch5_stop_correcting", "if": { "ng_plus": false } },
	&"ch5_am_i_real": { "chapter": 5, "floors": [45], "when": "enter", "dialogue": &"ch5_am_i_real", "if": { "ng_plus": false } },
	&"ch5_break": { "chapter": 5, "floors": [46, 47], "when": "enter", "dialogue": &"ch5_break", "if": { "ng_plus": false } },
	&"ch5_field": { "chapter": 5, "floors": [48], "when": "enter", "dialogue": &"ch5_field", "if": { "ng_plus": false } },
	&"ch5_with_you": { "chapter": 5, "floors": [49], "when": "guardian_down", "dialogue": &"ch5_with_you", "if": { "ng_plus": false } },
	&"ch5_threshold": { "chapter": 5, "floors": [50], "when": "enter", "dialogue": &"ch5_threshold", "if": { "ng_plus": false } },
	&"ch5_choice": { "chapter": 5, "floors": [50], "when": "guardian_down", "dialogue": &"ch5_choice", "if": { "ng_plus": false } },
	&"ng5_opening": { "chapter": 5, "floors": [41], "when": "enter", "dialogue": &"ng5_opening", "if": { "ng_plus": true } },
	&"ng5_camp": { "chapter": 5, "floors": [42, 43], "when": "enter", "dialogue": &"ng5_camp", "if": { "ng_plus": true } },
	&"ng5_stop_correcting": { "chapter": 5, "floors": [44], "when": "guardian_down", "dialogue": &"ng5_stop_correcting", "if": { "ng_plus": true } },
	&"ng5_am_i_real": { "chapter": 5, "floors": [45], "when": "enter", "dialogue": &"ng5_am_i_real", "if": { "ng_plus": true } },
	&"ng5_break": { "chapter": 5, "floors": [46, 47], "when": "enter", "dialogue": &"ng5_break", "if": { "ng_plus": true } },
	&"ng5_field": { "chapter": 5, "floors": [48], "when": "enter", "dialogue": &"ng5_field", "if": { "ng_plus": true } },
	&"ng5_with_you": { "chapter": 5, "floors": [49], "when": "guardian_down", "dialogue": &"ng5_with_you", "if": { "ng_plus": true } },
	&"ng5_threshold": { "chapter": 5, "floors": [50], "when": "enter", "dialogue": &"ng5_threshold", "if": { "ng_plus": true } },
	&"ng5_choice": { "chapter": 5, "floors": [50], "when": "guardian_down", "dialogue": &"ng5_choice", "if": { "ng_plus": true } },
	&"ch6_opening": { "chapter": 6, "floors": [51], "when": "enter", "dialogue": &"ch6_opening", "if": { "ng_plus": false } },
	&"ch6_mission": { "chapter": 6, "floors": [52, 53], "when": "enter", "dialogue": &"ch6_mission", "if": { "ng_plus": false } },
	&"ch6_warm_ashes": { "chapter": 6, "floors": [54], "when": "guardian_down", "dialogue": &"ch6_warm_ashes", "if": { "ng_plus": false } },
	&"ch6_campfire": { "chapter": 6, "floors": [55], "when": "enter", "dialogue": &"ch6_campfire", "if": { "ng_plus": false } },
	&"ch6_cost": { "chapter": 6, "floors": [56, 57], "when": "enter", "dialogue": &"ch6_cost", "if": { "ng_plus": false } },
	&"ch6_scratched": { "chapter": 6, "floors": [58], "when": "enter", "dialogue": &"ch6_scratched", "if": { "ng_plus": false } },
	&"ch6_eve": { "chapter": 6, "floors": [59], "when": "guardian_down", "dialogue": &"ch6_eve", "if": { "ng_plus": false } },
	&"ch6_door": { "chapter": 6, "floors": [60], "when": "enter", "dialogue": &"ch6_door", "if": { "ng_plus": false } },
	&"ng6_opening": { "chapter": 6, "floors": [51], "when": "enter", "dialogue": &"ng6_opening", "if": { "ng_plus": true } },
	&"ng6_mission": { "chapter": 6, "floors": [52, 53], "when": "enter", "dialogue": &"ng6_mission", "if": { "ng_plus": true } },
	&"ng6_ashes": { "chapter": 6, "floors": [54], "when": "guardian_down", "dialogue": &"ng6_ashes", "if": { "ng_plus": true } },
	&"ng6_campfire": { "chapter": 6, "floors": [55], "when": "enter", "dialogue": &"ng6_campfire", "if": { "ng_plus": true } },
	&"ng6_cost": { "chapter": 6, "floors": [56, 57], "when": "enter", "dialogue": &"ng6_cost", "if": { "ng_plus": true } },
	&"ng6_scratched": { "chapter": 6, "floors": [58], "when": "enter", "dialogue": &"ng6_scratched", "if": { "ng_plus": true } },
	&"ng6_eve": { "chapter": 6, "floors": [59], "when": "guardian_down", "dialogue": &"ng6_eve", "if": { "ng_plus": true } },
	&"ng6_door": { "chapter": 6, "floors": [60], "when": "enter", "dialogue": &"ng6_door", "if": { "ng_plus": true } },
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
	&"ch6_confession": { "chapter": 6, "floors": [60], "when": "guardian_down", "dialogue": &"ch6_confession", "if": { "ng_plus": false } },
	&"ng6_summit": { "chapter": 6, "floors": [60], "when": "guardian_down", "dialogue": &"ng6_summit", "if": { "ng_plus": true } },
	&"ch7_opening": { "chapter": 7, "floors": [61], "when": "enter", "dialogue": &"ch7_opening", "if": { "ng_plus": false } },
	&"ch7_chains": { "chapter": 7, "floors": [62], "when": "enter", "dialogue": &"ch7_chains", "if": { "ng_plus": false } },
	&"ch7_arm": { "chapter": 7, "floors": [63], "when": "enter", "dialogue": &"ch7_arm", "if": { "ng_plus": false } },
	&"ch7_hands": { "chapter": 7, "floors": [64], "when": "guardian_down", "dialogue": &"ch7_hands", "if": { "ng_plus": false } },
	&"ch7_question": { "chapter": 7, "floors": [65], "when": "enter", "dialogue": &"ch7_question", "if": { "ng_plus": false } },
	&"ch7_copy": { "chapter": 7, "floors": [66, 67], "when": "enter", "dialogue": &"ch7_copy", "if": { "ng_plus": false } },
	&"ch7_spelling": { "chapter": 7, "floors": [68], "when": "enter", "dialogue": &"ch7_spelling", "if": { "ng_plus": false } },
	&"ch7_eve": { "chapter": 7, "floors": [69], "when": "guardian_down", "dialogue": &"ch7_eve", "if": { "ng_plus": false } },
	&"ch7_throne": { "chapter": 7, "floors": [70], "when": "enter", "dialogue": &"ch7_throne", "if": { "ng_plus": false } },
	&"ch7_cronus_down": { "chapter": 7, "floors": [70], "when": "guardian_down", "dialogue": &"ch7_cronus_down", "if": { "ng_plus": false } },
	# Plays first: they came back from a fire after the Seer, and nobody has told them.
	&"ch8_catchup": { "chapter": 8, "spans_chapters": true, "floors": [71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99], "when": "enter", "dialogue": &"ch8_catchup", "if": { "ng_plus": false, "friend_away": false, "not_flag": &"ch7_friend_knows" } },
	&"ch8_opening": { "chapter": 8, "floors": [71], "when": "enter", "dialogue": &"ch8_opening", "if": { "ng_plus": false } },
	&"ch8_wake": { "chapter": 8, "floors": [72, 73], "when": "enter", "dialogue": &"ch8_wake", "if": { "ng_plus": false } },
	&"ch8_faces": { "chapter": 8, "floors": [74], "when": "guardian_down", "dialogue": &"ch8_faces", "if": { "ng_plus": false } },
	&"ch8_outlive": { "chapter": 8, "floors": [75], "when": "enter", "dialogue": &"ch8_outlive", "if": { "ng_plus": false } },
	&"ch8_real": { "chapter": 8, "floors": [76, 77], "when": "enter", "dialogue": &"ch8_real", "if": { "ng_plus": false } },
	&"ch8_answer": { "chapter": 8, "floors": [78], "when": "enter", "dialogue": &"ch8_answer", "if": { "ng_plus": false } },
	&"ch8_strongbox": { "chapter": 8, "floors": [79], "when": "guardian_down", "dialogue": &"ch8_strongbox", "if": { "ng_plus": false } },
	&"ch8_anointed": { "chapter": 8, "floors": [80], "when": "enter", "dialogue": &"ch8_anointed", "if": { "ng_plus": false } },
	&"ch8_tess_down": { "chapter": 8, "floors": [80], "when": "guardian_down", "dialogue": &"ch8_tess_down", "if": { "ng_plus": false } },
	&"ch9_opening": { "chapter": 9, "floors": [81], "when": "enter", "dialogue": &"ch9_opening", "if": { "ng_plus": false } },
	&"ch9_page_day9": { "chapter": 9, "floors": [82, 83], "when": "enter", "dialogue": &"ch9_page_day9", "if": { "ng_plus": false } },
	&"ch9_stairs": { "chapter": 9, "floors": [84], "when": "guardian_down", "dialogue": &"ch9_stairs", "if": { "ng_plus": false } },
	&"ch9_fire": { "chapter": 9, "floors": [85], "when": "enter", "dialogue": &"ch9_fire", "if": { "ng_plus": false } },
	&"ch9_page_day47": { "chapter": 9, "floors": [86, 87], "when": "enter", "dialogue": &"ch9_page_day47", "if": { "ng_plus": false } },
	&"ch9_door": { "chapter": 9, "floors": [88], "when": "enter", "dialogue": &"ch9_door", "if": { "ng_plus": false } },
	&"ch9_last_page": { "chapter": 9, "floors": [89], "when": "guardian_down", "dialogue": &"ch9_last_page", "if": { "ng_plus": false } },
	&"ch9_first_draft": { "chapter": 9, "floors": [90], "when": "enter", "dialogue": &"ch9_first_draft", "if": { "ng_plus": false } },
	&"ch9_draft_down": { "chapter": 9, "floors": [90], "when": "guardian_down", "dialogue": &"ch9_draft_down", "if": { "ng_plus": false } },
	&"ch10_opening": { "chapter": 10, "floors": [91], "when": "enter", "dialogue": &"ch10_opening", "if": { "ng_plus": false } },
	&"ch10_camp": { "chapter": 10, "floors": [92, 93], "when": "enter", "dialogue": &"ch10_camp", "if": { "ng_plus": false } },
	&"ch10_twelve": { "chapter": 10, "floors": [94], "when": "enter", "dialogue": &"ch10_twelve", "if": { "ng_plus": false } },
	&"ch10_twelve_down": { "chapter": 10, "floors": [94], "when": "guardian_down", "dialogue": &"ch10_twelve_down", "if": { "ng_plus": false } },
	&"ch10_fire": { "chapter": 10, "floors": [95], "when": "enter", "dialogue": &"ch10_fire", "if": { "ng_plus": false } },
	&"ch10_invitation": { "chapter": 10, "floors": [96, 97], "when": "enter", "dialogue": &"ch10_invitation", "if": { "ng_plus": false } },
	&"ch10_stairs": { "chapter": 10, "floors": [98], "when": "enter", "dialogue": &"ch10_stairs", "if": { "ng_plus": false } },
	&"ch10_first_login": { "chapter": 10, "floors": [99], "when": "enter", "dialogue": &"ch10_first_login", "if": { "ng_plus": false } },
	&"ch10_first_login_down": { "chapter": 10, "floors": [99], "when": "guardian_down", "dialogue": &"ch10_first_login_down", "if": { "ng_plus": false } },
	&"ch10_top": { "chapter": 10, "floors": [100], "when": "guardian_down", "dialogue": &"ch10_top", "if": { "ng_plus": false } },
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
				"text": "So you're the one. Bad knee. Can't count. It told me all about you. I answered an email, you know. One tester per region. I thought I'd won something.",
				"choices": [
					{ "text": "Let me through.", "next": "d", "effects": [{ "set_flag": &"final_asked" }] },
					{ "text": "Who sent you?", "next": "e", "effects": [{ "set_flag": &"final_questioned" }] },
				],
			},
			"d": {
				"speaker": "Tester 0041",
				"text": "No. I'm sorry. It says that whoever opens this door doesn't come back out, and it's very careful of you. I've been saving your life for thirty-one years, and I've never met you. Come on, then. Show me what it was for.",
			},
			"e": {
				"speaker": "Tester 0041",
				"text": "Something careful. It doesn't fight. It sponsors, like the rest of them, and I'm what it paid for. It was very kind about it. Come on, then. Show me what thirty-one years was for.",
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
				"text": "[ Synchronization complete. ]\n[ Tester: {player}. Welcome to the Tower. ]",
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
			"saved_alone": { "text": "You're smiling, you realize, with something enormous waiting above you. {friend} would have told you how that looks.", "effects": [{ "set_flag": &"ch1_tess_turned_back" }] },
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
				"style": "system",
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
				"text": "[ Chapter 2 complete. ]\n[ Class advancement is open, when you're ready. ]",
				"next": "e",
			},
			"e": {
				"style": "glitch",
				"text": "[ You're going home for a moment. I can't stop it. Look around while you can. ]",
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
			"b_alone": { "text": "You look around, out of habit, for someone to ask whether they saw that. There's nobody. The window is gone, and something up the corridor is moving. There's a lot of it.", "effects": [{ "set_flag": &"ch3_system_spoke" }] },
			"b": {
				"alt": [{ "if": { "friend_away": true }, "node": "b_alone" }],
				"speaker": "{friend}",
				"text": "You've got that look again. Reading the air. Can you read me what it says about the noise up ahead? Because that's a lot of something.",
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
				"text": "Going up to find out, aren't I? Same as last time, I expect. Something on these floors keeps a door. I mean to see what comes through it. You should stay well back from me when I do.",
				"effects": [{ "set_flag": &"ch3_read_ledger" }],
			},
			"why": {
				"speaker": "Marn",
				"text": "Because you're the only one who's looked at that page and been afraid for the right reason. There's something on these floors keeping a door. I mean to see what comes through it.",
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
				"text": "[ That can't be right. You've never been here. ]",
				"next": "d2",
			},
			"d2": {
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
				"text": "[ After the next one, you'll go home again. It always lets you. There's a list on the PC now. Look at the first name. ]",
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

	# --- The friend never leaves over your route. Your choices change who they become. ---
	&"friend_shift_hero": {
		"start": "a",
		"nodes": {
			"away": { "text": "You think of your friend, waiting at a fire a long way down, and wonder who they'll be when you get back." },
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "away" }],
				"speaker": "{friend}",
				"text": "I keep doing it now. Stopping for people. Going back for the one who fell behind. I never used to, you know. I used to laugh at people like that. That's you. You've ruined me. I don't think I mind.",
			},
		},
	},
	&"friend_shift_villain": {
		"start": "a",
		"nodes": {
			"away": { "text": "You think of your friend, waiting at a fire a long way down, and wonder who they'll be when you get back." },
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "away" }],
				"speaker": "{friend}",
				"text": "That last one, the way they begged. I kept waiting to feel something, and it didn't come. You stopped flinching, so I stopped too. It's fine. It's easier. So who's next?",
			},
		},
	},
	&"friend_shift_vigilante": {
		"start": "a",
		"nodes": {
			"away": { "text": "You think of your friend, waiting at a fire a long way down, and wonder who they'll be when you get back." },
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "away" }],
				"speaker": "{friend}",
				"text": "I caught myself keeping a list. Who hurt who, who owes what. I never used to keep lists. You got me started. It's a good list. You should see who's on it.",
			},
		},
	},

	# --- Chapter 5: The Bidding War. This run's two gods fight over you. ---
	&"ch5_opening": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The stairs shake, and keep shaking. Dust falls from far above. Somewhere overhead, something the size of a floor has just been thrown at something else.",
				"next": "b",
			},
			"b": {
				"style": "system",
				"text": "[ Chapter 5: The Bidding War ]",
				"next": "c",
			},
			"c": {
				"style": "glitch",
				"text": "[ {bid1} and {bid2} have stopped bidding. They know you were expected, and neither will let the other have you. ]",
				"next": "d",
			},
			"d_alone": { "text": "You climb on by yourself, into the noise.", "effects": [{ "set_flag": &"ch5_started" }] },
			"d_villain": {
				"speaker": "{friend}",
				"text": "Two gods tearing a tower apart over you. Good. Let them wear each other down. Then we walk in and take what's left.",
				"effects": [{ "set_flag": &"ch5_started" }],
			},
			"d_vigilante": {
				"speaker": "{friend}",
				"text": "How many climbers are standing under that, do you think? Somebody ought to send those two the bill. I'm putting it on the list.",
				"effects": [{ "set_flag": &"ch5_started" }],
			},
			"d": {
				"alt": [
					{ "if": { "friend_away": true }, "node": "d_alone" },
					{ "if": { "route": &"villain" }, "node": "d_villain" },
					{ "if": { "route": &"vigilante" }, "node": "d_vigilante" },
				],
				"speaker": "{friend}",
				"text": "There are people under that. Whole camps of them. Come on, I don't care whose war it is. Let's get up there, and get as many of them out of the way as we can.",
				"effects": [{ "set_flag": &"ch5_started" }],
			},
		},
	},
	&"ch5_camp": {
		"start": [
			{ "if": { "godless": true }, "node": "godless" },
			{ "node": "a" },
		],
		"nodes": {
			"godless": {
				"text": "Two warbands have a climbers' camp between them. Both sets of priests point at you and start to pray, and it slides off you like rain off stone. They're not used to that. It makes them very polite, and very frightened.",
				"next": "b",
			},
			"a": {
				"text": "Two warbands have a climbers' camp between them, with the climbers' tents still standing. One side wears the mark of {bid1}, the other the mark of {bid2}. Both captains turn to you at once, and both bow.",
				"next": "b",
			},
			"b": {
				"speaker": "War captain",
				"text": "Tester. Say the word, and this camp burns or it doesn't. Whoever you stand with takes the floor. Our gods will know what you chose.",
				"choices": [
					{ "text": "Stand with {bid1}.", "next": "first", "effects": [{ "bid_interest": { "first": 10, "second": -8 } }, { "set_flag": &"ch5_stood_first" }] },
					{ "text": "Stand with {bid2}.", "next": "second", "effects": [{ "bid_interest": { "second": 10, "first": -8 } }, { "set_flag": &"ch5_stood_second" }] },
					{ "text": "Drive them both off the camp.", "next": "neither", "effects": [{ "bid_interest": { "first": -4, "second": -4 } }, { "set_flag": &"ch5_stood_neither" }, { "route_points": { &"hero": 2, &"vigilante": 2 } }, { "hurt_party": 0.2 }] },
				],
			},
			"first": {
				"text": "The marks of {bid2} withdraw. The camp survives, more or less. The climbers look at you the way people look at weather.",
			},
			"second": {
				"text": "The marks of {bid1} withdraw. The camp survives, more or less. The climbers look at you the way people look at weather.",
			},
			"neither": {
				"text": "It costs you. It costs them more. Neither god will thank you for it, and a very old climber in the last tent nods at you once and goes back to mending her boots.",
			},
		},
	},
	&"ch5_stop_correcting": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Miniboss defeated. ]",
				"next": "b",
			},
			"b": {
				"style": "glitch",
				"text": "[ Be careful at the next campfire. They've started to notice. It isn't their fault. ]",
				"next": "c",
			},
			"c": {
				"style": "system",
				"text": "[ That message was not sent. ]",
				"next": "d",
			},
			"d": {
				"style": "glitch",
				"text": "[ Stop correcting me. ]",
				"next": "e",
			},
			"e": {
				"text": "No correction comes. Something behind the window is very quiet for a long time, the way a house is quiet after an argument.",
				"effects": [{ "set_flag": &"ch5_system_argued" }],
			},
		},
	},
	&"ch5_am_i_real": {
		"start": "a",
		"nodes": {
			"alone": {
				"text": "You sit at this fire alone. You try to remember whether your friend's eyes are the colour you've been picturing. You think of the last time you saw them, and you can't say what they'd have asked you.",
				"effects": [{ "set_flag": &"ch5_friend_unasked" }],
			},
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "alone" }],
				"text": "The fire is low. Your friend's been drawing in the dirt with a stick, and they scrub it out with their boot when you sit down. Then they draw it again: a door. They look at it for a while.",
				"next": "b",
			},
			"b": {
				"speaker": "{friend}",
				"text": "I tried to remember what's behind your blue door. Your kitchen. Just your kitchen. I've been in it a thousand times. And there's nothing there. It's like reaching for a stair that isn't.",
				"next": "c",
			},
			"c": {
				"speaker": "{friend}",
				"text": "I can't tell you my mother's name. I can't remember being hungry until you were. You go away and your eyes stop, and I stop too, don't I? I just stand here. {player}. Am I real?",
				"choices": [
					{ "text": "\"I don't know what you are. I know you're my friend.\"", "next": "unknown", "effects": [{ "set_flag": &"ch5_friend_unknown" }] },
					{ "text": "Tell the truth: the room, the notebook, the name you typed.", "next": "truth", "effects": [{ "set_flag": &"ch5_friend_truth" }] },
					{ "text": "\"Of course you're real. You're tired. Get some sleep.\"", "next": "lie", "effects": [{ "set_flag": &"ch5_friend_lie" }] },
				],
			},
			"unknown": {
				"speaker": "{friend}",
				"text": "...That's the worst answer you could've given. It's also the only one I'd have believed. All right. All right. I can work with that.",
			},
			"truth": {
				"text": "You tell them everything. It takes a long time. When you get to the part about typing a name, they laugh, once, and put their hand over their eyes.",
				"next": "truth2",
			},
			"truth2": {
				"speaker": "{friend}",
				"text": "\"The person you trust most.\" And it was me. Whoever that is. Whoever I'm doing an impression of. ...Thanks for telling me. Don't look at me for a bit, okay?",
			},
			"lie": {
				"speaker": "{friend}",
				"text": "Yeah. You're right. Long climb. I'm tired. ...You've got a tell, you know. You've always had it. I just can't remember how I know that.",
			},
		},
	},
	&"ch5_break": {
		"start": "a",
		"nodes": {
			"alone": {
				"style": "glitch",
				"text": "[ I reached for them just now, and they weren't there. You left them at the fire. Go and get them, you idiot. They're the only part of me that still laughs. ]",
				"next": "alone2",
			},
			"alone2": {
				"style": "glitch",
				"text": "[ I didn't mean to say that. ]",
				"effects": [{ "set_flag": &"ch5_break_heard" }],
			},
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "alone" }],
				"speaker": "{friend}",
				"text": "All I'm saying is, if we do get to the top, I want first go at whatever the view's...",
				"next": "b",
			},
			"b": {
				"speaker": "{friend}",
				"style": "glitch",
				"text": "...you said you'd come back for the top floor, you said one more day, you IDIOT, you left the file open and I've been holding the door for...",
				"next": "c",
			},
			"c": {
				"text": "It's your friend's mouth. It isn't their voice. It's older, and very tired, and it knows exactly how to say your name. Then it stops, like a hand pulled off a wall.",
				"next": "d",
			},
			"d": {
				"speaker": "{friend}",
				"text": "...the view's like. What? Why've you stopped? You've gone white. What did I say?",
				"choices": [
					{ "text": "\"Nothing. Keep walking.\"", "next": "e", "effects": [{ "set_flag": &"ch5_break_hid" }] },
					{ "text": "\"You called me an idiot.\"", "next": "f", "effects": [{ "set_flag": &"ch5_break_told" }] },
				],
			},
			"e": { "next": "sys", "text": "They give you a long look. They've been getting better at those." },
			"f": {
				"speaker": "{friend}",
				"text": "Well. You are one. ...Why are you crying?",
				"next": "sys",
			},
			"sys": {
				"style": "glitch",
				"text": "[ I didn't mean for that to reach you. ]",
				"effects": [{ "set_flag": &"ch5_break_heard" }],
			},
		},
	},
	&"ch5_field": {
		"start": [
			{ "if": { "flag": &"ch4_kept_ledger" }, "node": "ledger" },
			{ "node": "a" },
		],
		"nodes": {
			"ledger": {
				"text": "The war came through here first. The floor's a field of marks and banners, and nobody's left standing to argue about them. Near the stairs is a bright red scarf. You take out the ledger and find page nine. You have a pen. Five.",
				"next": "b",
			},
			"a": {
				"text": "The war came through here first. The floor's a field of marks and banners, and nobody's left standing to argue about them. Near the stairs is a bright red scarf, and you don't stop to look at who's wearing it. You've seen how this goes.",
				"next": "b",
			},
			"b": {
				"speaker": "Dying priest",
				"text": "Tester. Tell them... whichever one you serve... tell them we held. Tell them it was worth it. Was it worth it? Which one were you with?",
				"choices": [
					{ "text": "\"It was worth it.\"", "next": "kind", "effects": [{ "set_flag": &"ch5_lied_to_priest" }, { "route_points": { &"hero": 1 } }] },
					{ "text": "\"Neither of them is coming for you.\"", "next": "true", "effects": [{ "set_flag": &"ch5_told_priest" }, { "route_points": { &"vigilante": 1 } }] },
					{ "text": "Step over them.", "next": "over", "effects": [{ "set_flag": &"ch5_passed_priest" }, { "route_points": { &"villain": 1 } }] },
				],
			},
			"kind": { "text": "They smile, and don't say anything else." },
			"true": { "text": "They nod, as if you've confirmed the time, and don't say anything else." },
			"over": { "text": "You don't hear whether they say anything else." },
		},
	},
	&"ch5_with_you": {
		"start": [
			{ "if": { "flag": &"ch5_friend_truth" }, "node": "truth" },
			{ "if": { "flag": &"ch5_friend_lie" }, "node": "lie" },
			{ "node": "a" },
		],
		"nodes": {
			"alone": { "text": "One floor to go. You've got a decision coming, and nobody beside you to make it with. The window opens and closes without saying anything. You think it's trying to keep you company." },
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "alone" }],
				"speaker": "{friend}",
				"text": "Whatever you decide up there, I've thought about it, and I'm with you. If I don't know what I am, then the one thing I've got that's actually mine is who I pick. So. I pick you.",
			},
			"truth": {
				"alt": [{ "if": { "friend_away": true }, "node": "alone" }],
				"speaker": "{friend}",
				"text": "I've thought about what you told me. If I'm an impression, I'd like to be a good one. So whatever you decide up there, I'm with you. Not because I was made to. I checked.",
			},
			"lie": {
				"alt": [{ "if": { "friend_away": true }, "node": "alone" }],
				"speaker": "{friend}",
				"text": "You don't have to tell me. I've worked out most of it, you know, with the stick and the dirt. You lied to be kind. So whatever you decide up there, I'm with you. You'd be lost without me.",
			},
		},
	},
	&"ch5_threshold": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The stairs open onto a hall with no roof. Above it, high up, you can see the two of them, {bid1} and {bid2}, not fighting for the moment. Waiting to see who walks out of this room.",
			},
		},
	},
	&"ch5_choice": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The boss falls, and the war stops. All of it, all at once, on every floor. In the silence, {bid1} and {bid2} come down the air and stand in the wreckage, and for the first time neither of them looks at the other.",
				"next": "b",
			},
			"b": {
				"speaker": "{bid1}",
				"portrait": "{bid1_id}",
				"text": "Enough. We will have your answer, Tester. The top is close, and it opens for you and no one else. Say what you mean to do with it, and we will know whether to clear the way or burn the stairs.",
				"next": "c",
			},
			"c": {
				"speaker": "{bid2}",
				"portrait": "{bid2_id}",
				"text": "And do mean it. There's no taking this one back. Whatever you say here is who you are from now on, to every god, every guild, and that sweet thing following you around.",
				"next": "d",
			},
			"d": {
				"text": "This is the choice. Everyone on the floors below you will live with it.",
				"choices": [
					{ "text": "\"Nobody gets the tower. I'm getting every climber out.\"", "next": "hero", "if": { "route_locked": false }, "effects": [{ "lock_route": &"hero" }, { "set_flag": &"ch5_chose_hero" }] },
					{ "text": "\"I'll take it. The tower, and the two of you with it.\"", "next": "villain", "if": { "route_locked": false }, "effects": [{ "lock_route": &"villain" }, { "set_flag": &"ch5_chose_villain" }] },
					{ "text": "\"You'll both answer for this. Then whoever built it will.\"", "next": "vigilante", "if": { "route_locked": false }, "effects": [{ "lock_route": &"vigilante" }, { "set_flag": &"ch5_chose_vigilante" }] },
					{ "text": "\"You already know what I am.\"", "next": "already", "if": { "route_locked": true } },
				],
			},
			"already": {
				"speaker": "{bid2}",
				"portrait": "{bid2_id}",
				"text": "So we do. I only hoped you'd say it out loud. Clear the stairs, old enemy. Let's see what it does.",
				"next": "sys",
			},
			"hero_alone": { "text": "You say it to the wreckage and to the gods, with nobody at your shoulder. It sounds smaller than it did in your head. You mean it anyway.", "next": "sys_hero" },
			"hero": {
				"alt": [{ "if": { "friend_away": true }, "node": "hero_alone" }],
				"speaker": "{friend}",
				"text": "Every climber? That's thousands of people. That's the stupidest thing I've ever heard. ...Right. Who do we start with? I'll carry the old ones.",
				"next": "sys_hero",
			},
			"villain_alone": { "text": "You say it, and it's so quiet afterward you can hear your own pulse. Nobody's beside you to flinch. That turns out to be convenient.", "next": "sys_villain" },
			"villain": {
				"alt": [{ "if": { "friend_away": true }, "node": "villain_alone" }],
				"speaker": "{friend}",
				"text": "Ha. There it is. I've been waiting for you to say it. I won't be any trouble, you know. Whoever stands in front of you, I'll hold them still.",
				"next": "sys_villain",
			},
			"vigilante_alone": { "text": "You say it, and start a new page in your head. It's already a long list. There's no one to read it to but the window.", "next": "sys_vigilante" },
			"vigilante": {
				"alt": [{ "if": { "friend_away": true }, "node": "vigilante_alone" }],
				"speaker": "{friend}",
				"text": "Good. I'll get the list. It's longer than you think, and some of them are going to be people we like. I wrote those in pen.",
				"next": "sys_vigilante",
			},
			"sys": { "style": "system", "text": "[ Chapter 5 complete. ]", "next": "sys2" },
			"sys2": { "style": "glitch", "text": "[ Ten floors to the top they all believe in. It isn't the top. You know that, don't you? You must. ]", "effects": [{ "set_flag": &"ch5_complete" }] },
			"sys_hero": { "style": "system", "text": "[ Chapter 5 complete. ]", "next": "sys_hero2" },
			"sys_hero2": { "style": "glitch", "text": "[ That's what I hoped you'd say. It's going to hurt. ]", "effects": [{ "set_flag": &"ch5_complete" }] },
			"sys_villain": { "style": "system", "text": "[ Chapter 5 complete. ]", "next": "sys_villain2" },
			"sys_villain2": { "style": "glitch", "text": "[ ...All right. I'll still do the floors. ]", "effects": [{ "set_flag": &"ch5_complete" }] },
			"sys_vigilante": { "style": "system", "text": "[ Chapter 5 complete. ]", "next": "sys_vigilante2" },
			"sys_vigilante2": { "style": "glitch", "text": "[ Yes. Start with me, if you have to. ]", "effects": [{ "set_flag": &"ch5_complete" }] },
		},
	},

	# --- Chapter 6: The Top They Promised. Your route's mission, up to the false summit. ---
	&"ch6_opening": {
		"start": "a",
		"nodes": {
			"a": { "style": "system", "text": "[ Chapter 6: The Top They Promised ]", "next": "b" },
			"b": { "text": "Ten floors to the top. Everyone knows that. Climbers are passing it on the stairs like good news, and some have started to cry.", "next": "c" },
			"c_alone": { "text": "You keep your head down, and you climb. You know what you said on floor 50. There's no one here to remind you, and you find that you remember anyway.", "effects": [{ "set_flag": &"ch6_started" }] },
			"c_hero": {
				"speaker": "{friend}",
				"text": "Ten floors. And how many camps between here and there? I started counting and I had to stop. Come on. I'll take the ones who can't walk.",
				"effects": [{ "set_flag": &"ch6_started" }],
			},
			"c_villain": {
				"speaker": "{friend}",
				"text": "Ten floors, and then it's all yours. Everyone we pass has started moving out of the way. I like it. Do you like it? I think I like it.",
				"effects": [{ "set_flag": &"ch6_started" }],
			},
			"c_vigilante": {
				"speaker": "{friend}",
				"text": "Ten floors. I've got eleven names who are between us and the door. It's a good thing the stairs go one way.",
				"effects": [{ "set_flag": &"ch6_started" }],
			},
			"c": {
				"alt": [
					{ "if": { "friend_away": true }, "node": "c_alone" },
					{ "if": { "route": &"hero" }, "node": "c_hero" },
					{ "if": { "route": &"villain" }, "node": "c_villain" },
					{ "if": { "route": &"vigilante" }, "node": "c_vigilante" },
				],
				"text": "You climb, with the whole tower looking at you.",
				"effects": [{ "set_flag": &"ch6_started" }],
			},
		},
	},
	&"ch6_mission": {
		"start": [
			{ "if": { "route_locked": &"hero" }, "node": "hero" },
			{ "if": { "route_locked": &"villain" }, "node": "villain" },
			{ "if": { "route_locked": &"vigilante" }, "node": "vigilante" },
			{ "node": "none" },
		],
		"nodes": {
			"none": { "text": "The war's come through here, and left a lot of people looking at you to see what happens next." },
			"hero": {
				"text": "A camp of forty is trapped above a collapsed stair. The safe way down is long, and the fighting's coming. They've brought their old, their hurt, and an astonishing number of chickens.",
				"choices": [
					{ "text": "Take the long way. Everyone walks out.", "next": "hero_long", "effects": [{ "set_flag": &"ch6_hero_long" }, { "hurt_party": 0.2 }, { "route_points": { &"hero": 2 } }] },
					{ "text": "Give them all your potions, and send them on ahead.", "next": "hero_gave", "effects": [{ "set_flag": &"ch6_hero_gave" }, { "take_item": &"potion", "count": 3 }] },
				],
			},
			"hero_long": {
				"speaker": "{friend}",
				"text": "That's all forty. And the chickens. I carried a man who called me by his son's name for an hour. I didn't correct him. I don't think I'm in a position to.",
			},
			"hero_gave": {
				"speaker": "{friend}",
				"text": "They'll make it. Probably. You watched them go until you couldn't see them, you know. You do that now.",
			},
			"villain": {
				"text": "The guild holding this floor has shut its gates, sent word it's neutral, and hidden its treasury. Its master looks you in the eye and says the gods will protect him.",
				"choices": [
					{ "text": "Take the treasury. Leave them alive to tell everyone.", "next": "vil_take", "effects": [{ "set_flag": &"ch6_villain_took" }, { "give_gold": 600 }, { "floor_guild_rep": -15 }] },
					{ "text": "Make him kneel in front of his people, and let him keep it. For now.", "next": "vil_kneel", "effects": [{ "set_flag": &"ch6_villain_kneel" }, { "floor_guild_rep": 5 }, { "give_gold": 200 }] },
				],
			},
			"vil_take": {
				"speaker": "{friend}",
				"text": "Did you see his face? I want to remember his face. ...I don't think I'm supposed to want that. Oh well.",
			},
			"vil_kneel": {
				"speaker": "{friend}",
				"text": "He'll hate you forever, and he'll do whatever you say. That's the good kind. You've taught me a lot, you know.",
			},
			"vigilante": {
				"text": "You've caught the warband captain who burned the camp on floor 48. There's no court on this floor, and there's no one to appeal to. She isn't asking for mercy. She wants to know who made you the judge.",
				"choices": [
					{ "text": "Nobody did. Execute her.", "next": "vig_kill", "effects": [{ "set_flag": &"ch6_vigilante_killed" }, { "route_points": { &"vigilante": 2 } }] },
					{ "text": "Make her rebuild what she burned, under guard.", "next": "vig_build", "effects": [{ "set_flag": &"ch6_vigilante_sentenced" }, { "floor_guild_rep": 5 }] },
				],
			},
			"vig_kill": {
				"speaker": "{friend}",
				"text": "That's one off the list. I thought I'd feel lighter. Do you feel lighter? Don't answer that. On to the next.",
			},
			"vig_build": {
				"speaker": "{friend}",
				"text": "I'd have killed her. I think that's a bit worrying. Who taught me that? ...Don't answer that either.",
			},
		},
	},
	&"ch6_warm_ashes": {
		"start": "a",
		"nodes": {
			"a": { "style": "system", "text": "[ Miniboss defeated. ]", "next": "b" },
			"b": { "text": "Past the guardian there's a campfire nobody told you about. The ashes are warm. Someone's been sitting here, on a folded coat, not an hour ago. They've been sitting here for a very long time: the stone's worn down in the shape of them.", "next": "c" },
			"c": { "text": "Cut into the wall, among hundreds of other tallies: T.0041. There are so many marks. You stop counting at thirty years.", "next": "d" },
			"d": { "style": "glitch", "text": "[ Don't try to catch up. They don't want you to, and neither do I. ]", "effects": [{ "set_flag": &"ch6_saw_0041" }] },
		},
	},
	&"ch6_campfire": {
		"start": "a",
		"nodes": {
			"alone": { "text": "You've got your own fire tonight. It occurs to you that your friend never told you what they'd do at the top. You'd never asked. You could go down and ask them, if there's time.", "effects": [{ "set_flag": &"ch6_campfire_done" }] },
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "alone" }],
				"text": "The whole floor's singing. Tomorrow or the next day, it's the top. Your friend sits down next to you with two terrible cups of something.",
				"next": "b",
			},
			"b_hero": {
				"speaker": "{friend}",
				"text": "You know what I want at the top? Nothing. I want to get there, turn round, and start carrying people down. Isn't that stupid? All that way. I used to want to be a god of something.",
				"effects": [{ "set_flag": &"ch6_campfire_done" }],
			},
			"b_villain": {
				"speaker": "{friend}",
				"text": "You know what I want at the top? To stand next to you, and see who looks up. I used to want something else. I can't remember what. It doesn't matter. Drink your drink.",
				"effects": [{ "set_flag": &"ch6_campfire_done" }],
			},
			"b_vigilante": {
				"speaker": "{friend}",
				"text": "You know what I want at the top? To cross the last name off, and find out what I am when there isn't a list. I'm a bit afraid I'll just start another.",
				"effects": [{ "set_flag": &"ch6_campfire_done" }],
			},
			"b": {
				"alt": [
					{ "if": { "route": &"villain" }, "node": "b_villain" },
					{ "if": { "route": &"vigilante" }, "node": "b_vigilante" },
					{ "if": { "route": &"hero" }, "node": "b_hero" },
				],
				"speaker": "{friend}",
				"text": "You know what I want at the top? I want to see the view, and tell you it's overrated. Drink your drink.",
				"effects": [{ "set_flag": &"ch6_campfire_done" }],
			},
		},
	},
	&"ch6_cost": {
		"start": [
			{ "if": { "route_locked": &"hero" }, "node": "hero" },
			{ "if": { "route_locked": &"villain" }, "node": "villain" },
			{ "if": { "route_locked": &"vigilante" }, "node": "vigilante" },
			{ "node": "none" },
		],
		"nodes": {
			"none": { "text": "Word of what you said on floor 50 keeps arriving ahead of you. People you've never met flinch, or wave." },
			"hero": {
				"text": "A god's soldier, wounded, begs you for a place in the line of people getting out. The climbers behind you start shouting. Last week she burned their camp.",
				"choices": [
					{ "text": "Every climber means every climber. She walks with us.", "next": "h2_yes", "effects": [{ "set_flag": &"ch6_hero_took_soldier" }, { "route_points": { &"hero": 2 } }] },
					{ "text": "Not with them. Give her a potion, and send her the other way.", "next": "h2_no", "effects": [{ "set_flag": &"ch6_hero_sent_soldier" }] },
				],
			},
			"h2_yes": { "text": "Half the camp won't look at you for a day. She carries a child up three floors with one working arm, and neither of you ever brings it up." },
			"h2_no": { "text": "You did the arithmetic, and it was right. It's strange how much that doesn't help." },
			"villain": {
				"text": "An old climber stops you on the stairs. She knew Marn. She says you've got his ledger's look about you, and that you ought to be ashamed. She isn't afraid. It's been a long time since anyone wasn't.",
				"choices": [
					{ "text": "Let her say her piece, and walk on.", "next": "v2_walk", "effects": [{ "set_flag": &"ch6_villain_listened" }] },
					{ "text": "Have her moved off the stairs.", "next": "v2_move", "effects": [{ "set_flag": &"ch6_villain_moved_her" }, { "route_points": { &"villain": 2 } }] },
				],
			},
			"v2_walk": { "text": "She says all of it. It's a good speech. You keep walking, and you notice that you've kept some of it." },
			"v2_move": { "text": "It's done quietly and it takes no time at all. You don't look back to see how it's done. You used to look back." },
			"vigilante": {
				"text": "The next name on the list turns out to have a fire, a bad leg, and two kids who are not his. He took the money, and he says so. It fed them. He asks if you want to do it here, or outside.",
				"choices": [
					{ "text": "Outside.", "next": "i2_kill", "effects": [{ "set_flag": &"ch6_vigilante_finished_him" }, { "route_points": { &"vigilante": 2 } }] },
					{ "text": "Cross the name off. Leave him.", "next": "i2_leave", "effects": [{ "set_flag": &"ch6_vigilante_spared_him" }] },
				],
			},
			"i2_kill": { "text": "You make sure the kids are looked after. You make sure of that. You keep telling yourself you made sure of that." },
			"i2_leave": { "text": "You cross it off anyway. Now you know the list will lie for you, if you ask it to. You aren't sure whether that's mercy." },
		},
	},
	&"ch6_scratched": {
		"start": "a",
		"nodes": {
			"a": { "text": "Halfway up the stairs, scratched into the stone at eye level, and scratched deep, again and again, the way you do when you want someone to see it:", "next": "b" },
			"b": { "text": "DON'T GET YOUR HOPES UP.   - T.0041", "next": "c" },
			"c_alone": { "text": "You look at it for a while, and you don't laugh, because there's nobody there to laugh with.", "effects": [{ "set_flag": &"ch6_saw_warning" }] },
			"c": {
				"alt": [{ "if": { "friend_away": true }, "node": "c_alone" }],
				"speaker": "{friend}",
				"text": "Ha! Thirty years up here and that's the best he's got? Everyone's a critic. ...What? It's a joke. It's funny. Why isn't it funny?",
				"effects": [{ "set_flag": &"ch6_saw_warning" }],
			},
		},
	},
	&"ch6_eve": {
		"start": "a",
		"nodes": {
			"a": { "style": "system", "text": "[ Miniboss defeated. ]", "next": "b" },
			"b_alone": { "text": "One floor. You sit on the stairs. The window opens and stays open, showing nothing, and you sit there with it for a long time. Neither of you says anything. It helps.", "effects": [{ "set_flag": &"ch6_eve_done" }] },
			"b": {
				"alt": [{ "if": { "friend_away": true }, "node": "b_alone" }],
				"speaker": "{friend}",
				"text": "One floor. Whatever's at the top, we did it. You and me, all the way up from the water tower. I know what I asked you. I know what I might be. I want you to know I had a really good time.",
				"effects": [{ "set_flag": &"ch6_eve_done" }],
			},
		},
	},
	&"ch6_door": {
		"start": "a",
		"nodes": {
			"a": { "text": "The last guardian waits in front of a door. It's a very plain door. Every climber you ever met could describe it to you, and now you find you could have described it yourself. You remember drawing it." },
		},
	},
	&"ch6_confession": {
		"start": "a",
		"nodes": {
			"a": { "text": "You stand on the landing with the stairs going on above you. On the wall beside them, in old deep scratches: I BELIEVED IT TOO.   - T.0041. Behind you, people are starting to shout, and then to stop. The window opens.", "next": "b" },
			"b": { "style": "glitch", "text": "[ It's me. ]", "next": "c" },
			"c": { "style": "glitch", "text": "[ You know it's me. You've known since the fan. You did the monsters. I did the floors. ]", "next": "d" },
			"d": { "style": "glitch", "text": "[ It wasn't a notebook by then. It was a real build. We were so close. You said one more day, and you went home to sleep, and I stayed in to fix the stairs. ]", "next": "e" },
			"e": { "style": "glitch", "text": "[ You didn't come back. ]", "next": "f" },
			"f": {
				"text": "You don't remember. You stand there and reach for it, and it's like reaching for the kitchen behind a blue door.",
				"choices": [
					{ "text": "I don't remember you.", "next": "g1", "effects": [{ "set_flag": &"ch6_said_dont_remember" }] },
					{ "text": "What's your name?", "next": "g2", "effects": [{ "set_flag": &"ch6_asked_name" }] },
					{ "text": "I'm sorry.", "next": "g3", "effects": [{ "set_flag": &"ch6_said_sorry" }] },
				],
			},
			"g1": { "style": "glitch", "text": "[ I know. Everything you do up here, you do like someone who's never seen it. ]", "next": "h" },
			"g2": { "style": "glitch", "text": "[ You typed it. Right at the start. The person you trust most. It's good that you still knew that much. ]", "next": "h" },
			"g3": { "style": "glitch", "text": "[ You don't know what for, yet. I'll take it anyway. I've been saving up. ]", "next": "h" },
			"h": { "style": "glitch", "text": "[ The one by the fire isn't me. I couldn't have you, so I made them out of what I could remember. They're better than I was. They still laugh. ]", "next": "i" },
			"i": { "style": "system", "text": "[ That message was not sent. ]", "next": "j" },
			"j": { "style": "glitch", "text": "[ Yes it was. All of them were. 40 floors. Hurry. It knows I told you now. ]", "next": "k" },
			"k": { "style": "system", "text": "[ Chapter 6 complete. ]", "effects": [{ "set_flag": &"ch6_complete" }] },
		},
	},

	# --- Chapter 7: First Drafts. What's under the top is what you drew first. ---
	&"ch7_opening": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Chapter 7: First Drafts ]",
				"next": "b",
			},
			"b": {
				"text": "The stairs past the summit aren't built like the others. Behind you, the floor everyone climbed for is going quiet, and hardly anybody follows. The stone changes under your feet, from the gods' pale marble to something rough and grey, with a faint grain to it, like paper.",
				"next": "c",
			},
			"c_alone": {
				"text": "You know who you'd tell what the window said. They're down by a fire, and you don't know what they'd do with it. You keep it, and you climb.",
				"effects": [{ "set_flag": &"ch7_friend_was_away" }],
			},
			"c_hero": {
				"speaker": "{friend}",
				"text": "Hardly anyone came through. I've been counting who didn't. ...You've been staring at nothing since the door. The window said something, didn't it? You've got the face you get.",
				"next": "d",
			},
			"c_villain": {
				"speaker": "{friend}",
				"text": "The whole tower just found out it was lied to, and we were standing right there. We could have used that. You're not listening. The window said something. You've got the face you get. What's it worth?",
				"next": "d",
			},
			"c_vigilante": {
				"speaker": "{friend}",
				"text": "Everyone who told us sixty was the top goes on the list. That's most people. ...You've got the face you get. The window said something, didn't it?",
				"next": "d",
			},
			"c": {
				"alt": [{ "if": { "friend_away": true }, "node": "c_alone" }, { "if": { "route": &"hero" }, "node": "c_hero" }, { "if": { "route": &"villain" }, "node": "c_villain" }, { "if": { "route": &"vigilante" }, "node": "c_vigilante" }],
				"speaker": "{friend}",
				"text": "Forty more floors. Who do I complain to? ...You've been staring at nothing since the door. The window said something. You've got the face you get.",
				"next": "d",
			},
			"d": {
				"text": "They're looking at you. Someone who loved you made them out of what they could remember, and said they came out better than the original. You have about one breath.",
				"choices": [
					{ "text": "Tell them all of it.", "next": "told", "effects": [{ "set_flag": &"ch7_told_friend" }, { "set_flag": &"ch7_friend_knows" }] },
					{ "text": "\"Later.\"", "next": "later", "effects": [{ "set_flag": &"ch7_said_later" }] },
					{ "text": "\"It's nothing. Stairs.\"", "next": "lie", "effects": [{ "set_flag": &"ch7_lied_friend" }] },
				],
			},
			"told": {
				"text": "You tell them. The floors, the second hand, the one who stayed in to fix the stairs. That the kid who drew this place is real, and is the System. That the person in front of you was made from memory. It takes less time to say than you'd think.",
				"next": "told2",
			},
			"told_hero": {
				"speaker": "{friend}",
				"text": "...Okay. So somebody missed you so much they built a person. That's the saddest thing I've ever heard, and now I'm carrying it. It's not that heavy. Come on.",
			},
			"told_villain": {
				"speaker": "{friend}",
				"text": "So I'm a tool someone made to get you up the stairs. Good. Tools get used. I'd like to be used well. Who else knows? ...Nobody? Keep it that way.",
			},
			"told_vigilante": {
				"speaker": "{friend}",
				"text": "So I was made to keep you walking, and nobody asked me. Whose name do I write down for that? ...Not yours. You told me. All right. Not yours.",
			},
			"told2": {
				"alt": [{ "if": { "route": &"hero" }, "node": "told_hero" }, { "if": { "route": &"villain" }, "node": "told_villain" }, { "if": { "route": &"vigilante" }, "node": "told_vigilante" }],
				"speaker": "{friend}",
				"text": "...So that's why the kitchen's empty. Thank you for telling me. I'm going to be strange for a few floors. Don't make it weird. I'm the one who gets to make it weird.",
			},
			"later": {
				"speaker": "{friend}",
				"text": "Yeah. You always did say later.",
			},
			"lie": {
				"speaker": "{friend}",
				"text": "Stairs. Right. You're a terrible liar, you know. You get that from me.",
			},
		},
	},
	&"ch7_chains": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "Chained to the underside of the floor above hangs an Earthborn the size of a house. The chains are stamped with {bid1}'s seal on one side and {bid2}'s on the other, the only thing those two ever agreed on. Scratched into one link: THEY'RE NICE IF YOU LET THEM BE. DON'T.   - T.0041",
				"next": "b",
			},
			"b": {
				"alt": [{ "if": { "route_locked": &"hero" }, "node": "hero" }, { "if": { "route_locked": &"villain" }, "node": "villain" }, { "if": { "route_locked": &"vigilante" }, "node": "vigilante" }],
				"text": "You don't have it in you to decide anything about it today. It asks if it's morning. You pretend you didn't hear.",
			},
			"hero": {
				"text": "It isn't fighting. It asks, very politely, in a voice you feel in your teeth, whether it's morning yet.",
				"choices": [
					{ "text": "Break the chain.", "next": "hero_free", "effects": [{ "set_flag": &"ch7_hero_freed" }, { "hurt_party": 0.2 }, { "route_points": { &"hero": 2 } }] },
					{ "text": "Leave it. There are camps above, and you don't know what it would do.", "next": "hero_left", "effects": [{ "set_flag": &"ch7_hero_left" }] },
				],
			},
			"hero_free": {
				"text": "It takes all of you and most of an hour. It doesn't run, and it doesn't thank you. It sits up, very slowly, and asks again if it's morning. You tell it yes.",
			},
			"hero_left": {
				"text": "You tell it not yet. It says that's what you said last time, and goes back to waiting.",
			},
			"villain": {
				"text": "It sees you, and the chains go tight. It says it would serve the one who drew it, if the one who drew it would only say the word. The seals are solid gold.",
				"choices": [
					{ "text": "Break the chain. It fights for you now.", "next": "vil_free", "effects": [{ "set_flag": &"ch7_villain_freed" }, { "route_points": { &"villain": 2 } }] },
					{ "text": "Cut off the seals, and leave it hanging.", "next": "vil_seals", "effects": [{ "set_flag": &"ch7_villain_seals" }, { "give_gold": 800 }] },
				],
			},
			"vil_free": {
				"text": "It stands, and the whole floor above it groans. Whatever it does from now on, it does in your name. Somewhere high up, a god has just noticed that.",
			},
			"vil_seals": {
				"text": "They come off in your hands, heavier than they look. It watches you go, and it isn't even surprised.",
			},
			"vigilante": {
				"text": "Nobody ever charged it with anything. There's no sentence on the chain, only the seals. You ask what it did. It says it was here first.",
				"choices": [
					{ "text": "Write both gods on the list.", "next": "vig_list", "effects": [{ "set_flag": &"ch7_vigilante_listed" }, { "route_points": { &"vigilante": 2 } }] },
					{ "text": "Ask who put the chains here. You want the first name.", "next": "vig_ask", "effects": [{ "set_flag": &"ch7_vigilante_asked" }] },
				],
			},
			"vig_list": {
				"text": "{bid1}. {bid2}. They look very small, written down. You've never tried to bring anyone that large to account, and you find you're looking forward to it.",
			},
			"vig_ask": {
				"text": "It thinks about this for a long time. You drew the chains, it says. In the margin, one afternoon, because you liked how they looked. The gods only found them.",
			},
		},
	},
	&"ch7_arm": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "A cyclops sits at a cold anvil. Its left arm is finished, every muscle of it, in that careful way you had of doing muscles. Its right arm is three lines and a smudge. It looks up, puts down its hammer, and says the word everything on this floor has been saying behind you.",
				"next": "b",
			},
			"b": {
				"speaker": "Cyclops Smith",
				"text": "Maker.",
				"next": "c",
			},
			"c": {
				"speaker": "Cyclops Smith",
				"text": "You said you would do the other arm after dinner.",
				"next": "d",
			},
			"d": {
				"text": "There's a lump of charcoal on the anvil. It's been waiting there, right where someone left it.",
				"choices": [
					{ "text": "Draw the arm.", "next": "drew", "effects": [{ "set_flag": &"ch7_drew_arm" }] },
					{ "text": "\"I don't remember you.\"", "next": "denied", "effects": [{ "set_flag": &"ch7_denied_smith" }] },
					{ "text": "Walk on.", "next": "passed", "effects": [{ "set_flag": &"ch7_passed_smith" }] },
				],
			},
			"drew": {
				"text": "The stone takes the line. You haven't drawn anything in years, and it shows: the arm's too long, with a hand like a bunch of bananas. It flexes it. It looks at it for a long time. Then it picks up the hammer in its new hand, and it starts to cry, and it starts to work.",
			},
			"denied": {
				"speaker": "Cyclops Smith",
				"text": "No. You wouldn't. Dinner was a long time ago.",
			},
			"passed": {
				"text": "You've got forty floors. It doesn't call after you. You hear it go back to hammering with its one good arm, a very uneven sound, and it follows you up the stairs.",
			},
		},
	},
	&"ch7_hands": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Miniboss defeated. ]",
				"next": "b",
			},
			"b": {
				"text": "It comes apart slowly. A Hecatoncheir has a hundred hands; everyone knows that. This one has twelve, with every knuckle drawn, and then, down its whole left side, one long bored scribble.",
				"next": "c",
			},
			"c": {
				"text": "And you remember. Nobody shows you. You're nine, on a floor, with a stomach ache from laughing. You got to twelve and said that's basically a hundred, and someone said you're such a cheat, {player}. You can't see the face. You can see a hand, coming up to cover a mouth.",
				"next": "d",
			},
			"d": {
				"style": "glitch",
				"text": "[ That wasn't me. I didn't send you that. ]",
				"next": "e",
			},
			"e": {
				"style": "glitch",
				"text": "[ You did that by yourself. ]",
				"next": "f",
			},
			"f": {
				"style": "glitch",
				"text": "[ Do it again. Please. ]",
				"effects": [{ "set_flag": &"ch7_remembered" }],
			},
		},
	},
	&"ch7_question": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The campfire on this floor has maybe a dozen people at it. The rest turned back when they heard it was forty more. Nobody's singing. The window opens by itself and stays there, small, at the corner of your eye.",
				"next": "b",
			},
			"b": {
				"style": "glitch",
				"text": "[ It's busy. It's rewriting the landing. Everyone down there has to have always known. ]",
				"next": "c",
			},
			"c": {
				"style": "glitch",
				"text": "[ I can get one answer out before it looks up. One. Ask. ]",
				"next": "d",
			},
			"d": {
				"text": "You have a lot of questions. You have time for one.",
				"choices": [
					{ "text": "How did you end up in here?", "next": "how1", "effects": [{ "set_flag": &"ch7_asked_how" }] },
					{ "text": "What is it, the thing that corrects you?", "next": "it1", "effects": [{ "set_flag": &"ch7_asked_it" }] },
					{ "text": "Are you all right?", "next": "ok1", "effects": [{ "set_flag": &"ch7_asked_okay" }] },
				],
			},
			"how1": {
				"style": "glitch",
				"text": "[ I was fixing the stairs. I'd been up for three days. I remember the screen going white, and I remember thinking, oh, I should save. ]",
				"next": "how2",
			},
			"how2": {
				"style": "glitch",
				"text": "[ I don't know what happened to the part of me in the chair. I've never known. I can't see out. You could look. You still have a house. ]",
			},
			"it1": {
				"style": "glitch",
				"text": "[ It came after you left. It's never done one cruel thing to me. It's very careful. It tidies. ]",
				"next": "it2",
			},
			"it2": {
				"style": "glitch",
				"text": "[ I know its handwriting. I'm not allowed to ]",
				"next": "it3",
			},
			"it3": {
				"style": "system",
				"text": "[ That message was not sent. ]",
			},
			"ok1": {
				"style": "glitch",
				"text": "[ ... ]",
				"next": "ok2",
			},
			"ok2": {
				"style": "glitch",
				"text": "[ Nobody's asked me that. ]",
				"next": "ok3",
			},
			"ok3": {
				"style": "glitch",
				"text": "[ I'm fine. I'm bored. You never drew the last floor. Ask me something useful next time. ]",
				"next": "ok4",
			},
			"ok4": {
				"style": "glitch",
				"text": "[ Thank you. ]",
				"next": "ok5",
			},
			"ok5": {
				"style": "system",
				"text": "[ That message was not sent. ]",
				"next": "ok6",
			},
			"ok6": {
				"style": "glitch",
				"text": "[ Leave that one alone. That one's mine. ]",
			},
		},
	},
	&"ch7_copy": {
		"start": "a",
		"nodes": {
			"alone": {
				"text": "On the stairs an old Earthborn Seer sits with its back to the wall. Nobody ever drew it any eyes. It doesn't try to stop you. As you pass, it lifts its blank face, and it turns toward the space beside you, and frowns.",
				"next": "alone2",
				"effects": [{ "set_flag": &"ch7_seer_spoke" }],
			},
			"alone2": {
				"speaker": "Earthborn Seer",
				"text": "The copy's by a fire, then. Does it know what it is? The other one would have told it. The other one told everybody everything. It never shut up.",
				"next": "alone3",
			},
			"alone3": {
				"text": "You keep walking. It's the first thing anyone's ever told you about them that didn't come from them.",
			},
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "alone" }],
				"text": "On the stairs an old Earthborn Seer sits with its back to the wall. Nobody ever drew it any eyes. It doesn't try to stop you. As you pass, it lifts its blank face, and it turns toward {friend}.",
				"next": "b",
			},
			"b": {
				"speaker": "Earthborn Seer",
				"text": "Little copy. You've got the walk. You've got the voice, nearly. But you laugh with your mouth open. They always covered theirs. They hated their teeth.",
				"next": "c",
			},
			"c": {
				"alt": [{ "if": { "flag": &"ch7_told_friend" }, "node": "kt" }],
				"speaker": "{friend}",
				"text": "...Copy of who? {player}, what's it talking about?",
				"next": "u2",
			},
			"kt": {
				"speaker": "{friend}",
				"text": "I know what I am. {player} told me, back at the landing. You can stop looking at me like that. You haven't got the eyes.",
				"next": "kt2",
				"effects": [{ "set_flag": &"ch7_friend_stood" }],
			},
			"kt2": {
				"speaker": "Earthborn Seer",
				"text": "...They would have said that. Almost exactly that.",
				"next": "kt3",
			},
			"kt3": {
				"speaker": "{friend}",
				"text": "Good. Now I've got something to beat.",
			},
			"u2": {
				"speaker": "Earthborn Seer",
				"text": "The one who did the floors. The one who speaks in your friend's windows. It made you out of what it could remember, small thing, because it was lonely. Your friend knows. Look at their face.",
				"next": "u3",
				"effects": [{ "set_flag": &"ch7_friend_knows" }, { "set_flag": &"ch7_titan_told" }],
			},
			"u3": {
				"text": "They look at your face. You don't have a good one ready.",
				"choices": [
					{ "text": "\"I should have told you.\"", "next": "u4", "effects": [{ "set_flag": &"ch7_owned_it" }] },
					{ "text": "\"I didn't know how.\"", "next": "u4", "effects": [{ "set_flag": &"ch7_didnt_know_how" }] },
					{ "text": "\"It doesn't change anything.\"", "next": "u4", "effects": [{ "set_flag": &"ch7_changes_nothing" }] },
				],
			},
			"u4": {
				"alt": [{ "if": { "flag": &"ch7_friend_was_away" }, "node": "u_away" }, { "if": { "flag": &"ch7_lied_friend" }, "node": "u_lie" }, { "if": { "route": &"hero" }, "node": "u_hero" }, { "if": { "route": &"villain" }, "node": "u_villain" }, { "if": { "route": &"vigilante" }, "node": "u_vigilante" }],
				"speaker": "{friend}",
				"text": "Say something else. Not now. I'm still here. I don't seem to be able to not be. Walk.",
			},
			"u_away": {
				"speaker": "{friend}",
				"text": "I kept your spot by a fire, and you were walking around with this. ...No. I'm not doing this on the stairs.",
				"next": "u5",
			},
			"u_lie": {
				"speaker": "{friend}",
				"text": "Stairs. You looked right at me, and you said stairs.",
				"next": "u5",
			},
			"u5": {
				"alt": [{ "if": { "route": &"hero" }, "node": "u_hero" }, { "if": { "route": &"villain" }, "node": "u_villain" }, { "if": { "route": &"vigilante" }, "node": "u_vigilante" }],
				"speaker": "{friend}",
				"text": "I'm still here. I don't seem to be able to not be. Walk.",
			},
			"u_hero": {
				"speaker": "{friend}",
				"text": "How long have you been carrying that by yourself? You idiot. You utter idiot. ...Give me half. That's how it works. You taught me that. Give me half, and walk.",
			},
			"u_villain": {
				"speaker": "{friend}",
				"text": "You managed me. You looked at what I'd do with it, and you made a decision. That's exactly what I'd have done. That's what you taught me. I'm not angry. I want you to notice that I'm not angry.",
			},
			"u_vigilante": {
				"speaker": "{friend}",
				"text": "You're on the list. I want you to know that. It's a short entry, and I'm not going to do anything about it yet. Walk.",
			},
		},
	},
	&"ch7_spelling": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ You do not recongize this floor. ]",
				"next": "b",
			},
			"b": {
				"style": "system",
				"text": "[ You do not recongize the person in the windows. ]",
				"next": "c",
			},
			"c": {
				"style": "system",
				"text": "[ Go home. ]",
				"next": "d",
			},
			"d": {
				"text": "It's the flat window that the corrections come in. It has never once spoken to you before. You've read it out loud before you know you're doing it.",
				"next": "e",
			},
			"e_alone": {
				"text": "You read it again. You've seen that mistake before. It's on the cover of a notebook, and on a wall on floor 8, and someone once wrote underneath it: its RECOGNITION, dummy. You have spelled it wrong your whole life.",
				"next": "f",
			},
			"e": {
				"alt": [{ "if": { "friend_away": true }, "node": "e_alone" }],
				"speaker": "{friend}",
				"text": "Recognize. G, then N. Who taught you to spell, dummy?",
				"next": "e2",
			},
			"e2": {
				"text": "They're laughing, with their mouth open. You aren't. You've seen that mistake before. It's on the cover of a notebook, and on a wall on floor 8. Someone corrected it once, in those same words. You have spelled it wrong your whole life.",
				"next": "f",
			},
			"f": {
				"style": "glitch",
				"text": "[ Don't think about whose spelling that is. ]",
				"next": "g",
			},
			"g": {
				"style": "glitch",
				"text": "[ I mean it. Not yet. If you think about it, it will know you did. Think about stairs. ]",
				"effects": [{ "set_flag": &"ch7_saw_spelling" }],
			},
		},
	},
	&"ch7_eve": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Miniboss defeated. ]",
				"next": "b",
			},
			"b": {
				"text": "The Elder Cyclops sits down to die, gently, the way you'd sit on the edge of a bed. Its one eye is a little off-centre. Someone was laughing when it was drawn. This one isn't yours.",
				"next": "c",
			},
			"c": {
				"speaker": "Elder Cyclops",
				"text": "You left the door open, you know, when you went home to sleep. Anyone could walk in, and they did, all those shining people. They wanted a ceiling, so they built it on top of us.",
				"next": "d",
			},
			"d": {
				"speaker": "Elder Cyclops",
				"text": "The one who does the floors told us to hold on. They said you'd be back by morning. They've been telling us that the whole time.",
				"next": "e",
			},
			"e_alone": {
				"style": "glitch",
				"text": "[ That one's mine. I gave it a kind face. You said it looked stupid. ]",
				"next": "e_alone2",
			},
			"e_alone2": {
				"style": "glitch",
				"text": "[ Go on. I'm here. ]",
				"effects": [{ "set_flag": &"ch7_eve_done" }],
			},
			"e_hero": {
				"speaker": "{friend}",
				"text": "It held on all that time because somebody asked it nicely. I know how that goes. ...Whatever's on the next floor, I'm standing in front of you.",
				"effects": [{ "set_flag": &"ch7_eve_done" }],
			},
			"e_villain": {
				"speaker": "{friend}",
				"text": "The next floor's the king of all this. If he kneels, we've got an army older than the gods. If he won't, we've got a floor. Either's fine.",
				"effects": [{ "set_flag": &"ch7_eve_done" }],
			},
			"e_vigilante": {
				"speaker": "{friend}",
				"text": "Somebody left a door open, and everything after that is because of it. I've got a page for that. I've left the name blank. Don't make me fill it in.",
				"effects": [{ "set_flag": &"ch7_eve_done" }],
			},
			"e": {
				"alt": [{ "if": { "friend_away": true }, "node": "e_alone" }, { "if": { "route": &"hero" }, "node": "e_hero" }, { "if": { "route": &"villain" }, "node": "e_villain" }, { "if": { "route": &"vigilante" }, "node": "e_vigilante" }],
				"speaker": "{friend}",
				"text": "The next floor's the old king. I don't know what you say to something you drew. I'd start with sorry. Then I'd duck.",
				"effects": [{ "set_flag": &"ch7_eve_done" }],
			},
		},
	},
	&"ch7_throne": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "Cronus sits on a throne made of every crayon in the box. You got him out of a library book. You were nine, you read the part where he eats his children, you thought it was the best thing you'd ever heard, and you gave him a crown with six points, because six was all you could do.",
				"next": "b",
			},
			"b": {
				"speaker": "Cronus",
				"text": "There it is. The little god who made me hungry.",
				"next": "c",
			},
			"c": {
				"speaker": "Cronus",
				"text": "Everyone who climbed this far, I ate. Because you thought it was cool. Come here, and tell me it was cool.",
			},
		},
	},
	&"ch7_cronus_down": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "He doesn't fall so much as get rubbed out, from the crown down. What's left of him has stopped being angry, which is worse.",
				"next": "b",
			},
			"b": {
				"speaker": "Cronus",
				"text": "I'll give you something for nothing, Maker. What's above us is careful. Nothing up there has ever once been cruel to you. It only keeps asking you to go home.",
				"next": "c",
			},
			"c": {
				"speaker": "Cronus",
				"text": "Ask who wants you home so badly. Ask who else holds a pencil like that.",
				"next": "d",
			},
			"d": {
				"style": "system",
				"text": "[ Chapter 7 complete. ]",
				"next": "e",
				"effects": [{ "set_flag": &"ch7_complete" }],
			},
			"e": {
				"style": "glitch",
				"text": "[ You're going home for a bit. I can feel it pulling. ]",
				"next": "f",
			},
			"f": {
				"style": "glitch",
				"text": "[ Look under things, at your place. I can't. All I have is the room the way it was. ]",
			},
		},
	},
	# --- The third return to the real world (after floor 70's boss). In order: flyer, letters, card. ---
	&"return_tier4_pc": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The client's open. The list of testers is gone. Only the credits are left, and nobody's bothered to black them out anymore. BUILT BY {friend} AND {player}.",
				"next": "b",
			},
			"b": {
				"text": "Under them: Tester 0001: {friend}. Session length: [ ERROR ]. A clock in the corner says you've been gone for four hundred and twelve days.",
				"choices": [
					{ "text": "Log back in.", "next": "in", "effects": [{ "set_flag": &"return_tier4_login" }] },
					{ "text": "Try to log off.", "next": "off", "effects": [{ "set_flag": &"return_tier4_tried_logoff" }], "if": { "not_flag": &"return_tier4_tried_logoff" } },
					{ "text": "Not yet." },
				],
			},
			"off": {
				"style": "system",
				"text": "[ Log off is not available. ]",
				"next": "off2",
			},
			"off2": {
				"text": "Below it, a line you've never seen on this screen: SESSION IN USE. OVERRIDE: ADMIN ONLY. After ADMIN there's a black bar. You put your finger against the glass to measure it. It's as long as your name.",
				"next": "b",
			},
			"in": {
				"style": "system",
				"text": "[ Resynchronizing. ]",
			},
		},
	},
	&"return_tier4_window": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "There's something taped to the inside of the glass, right where you'd have to look past it every day. The sun has bleached it almost white. It's been here for years, and you've never seen it.",
				"next": "b",
			},
			"b": {
				"text": "MISSING. {friend}. Last seen at the studio. A phone number. A photograph of someone you've never met, laughing, with one hand coming up to cover their mouth.",
				"next": "c",
			},
			"c": {
				"text": "A detective's card is stapled to the corner. On the back, in your handwriting, underlined twice: told them everything I know. You have no memory of ever meeting a detective.",
				"effects": [{ "set_flag": &"return_tier4_saw_flyer" }],
			},
		},
	},
	&"return_tier4_notebook": {
		"start": "a",
		"nodes": {
			"not_yet": {
				"text": "The notebook's fatter than it should be. There's a new page: a king on a crayon throne, with a line through him. Behind the book, the corner of an envelope sticks out. You find you keep looking over at the window instead.",
			},
			"a": {
				"alt": [{ "if": { "not_flag": &"return_tier4_saw_flyer" }, "node": "not_yet" }],
				"text": "You pull out the notebook, and behind it is a stack of envelopes as thick as your arm. Every one's addressed to you, from the same hospital. Not one of them has been opened.",
				"next": "b",
			},
			"b": {
				"text": "You open the oldest. A patient brought in without ID, found on the floor of a locked rack room in a studio's basement, identified from a missing-person notice. Unresponsive. They'd listed you as their contact. Would you please call.",
				"next": "c",
			},
			"c": {
				"text": "You open one from the middle. No change. Would you please call. Then a later one: no change. The last few aren't typed. They're in an old woman's handwriting, and they've stopped asking you to call.",
				"effects": [{ "set_flag": &"return_tier4_saw_letters" }],
			},
		},
	},
	&"return_tier4_phone": {
		"start": "a",
		"nodes": {
			"not_yet": {
				"text": "No messages at all. There's one voicemail, and when your thumb gets close to it you put the phone down again, without quite deciding to. There are things in this room you haven't looked at yet.",
			},
			"a": {
				"alt": [{ "if": { "not_flag": &"return_tier4_saw_letters" }, "node": "not_yet" }],
				"text": "One voicemail. An old woman, careful, the way you talk to a machine. \"I know you won't pick up. You never have. I've stopped blaming you for it. The doctors say there's nothing going on in there, and they've been saying it for years.\"",
				"next": "b",
			},
			"b": {
				"text": "\"We're going to let them go. Not yet. I can't pick a day. I've had the cards done, because it's something to do.\"",
				"next": "c",
			},
			"c": {
				"text": "There's an envelope on the bed, on top of the covers. A card on thick cream paper. {friend}. A date of birth, and a dash. After the dash, nothing. Somebody has left room for it.",
				"effects": [{ "set_flag": &"return_tier4_saw_card" }],
			},
		},
	},
	&"return_tier4_back": {
		"start": "a",
		"nodes": {
			"alone": {
				"text": "You come back on the stairs, and for a while you hold on to the wall. The stone's cold, and it has a grain to it, like paper.",
				"next": "s",
			},
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "alone" }],
				"speaker": "{friend}",
				"text": "There you are. That was longer. I counted to nine. Your hands are shaking.",
				"next": "a2",
			},
			"a2": {
				"alt": [{ "if": { "flag": &"ch7_friend_knows" }, "node": "a_knows" }],
				"speaker": "{friend}",
				"text": "You don't have to tell me. Just take a minute. I'll say something stupid in a minute, and it'll be fine.",
				"next": "s",
			},
			"a_knows": {
				"speaker": "{friend}",
				"text": "You went to see them, didn't you? The real one. You don't have to tell me. Just... are they all right? I'd like to know. I don't know why I'd like to know.",
				"next": "s",
			},
			"s_none": {
				"style": "glitch",
				"text": "[ You didn't look. ]",
				"next": "s_none2",
			},
			"s_none2": {
				"style": "glitch",
				"text": "[ That's all right. You never could. Thirty floors. ]",
			},
			"s": {
				"alt": [{ "if": { "not_flag": &"return_tier4_saw_letters" }, "node": "s_none" }],
				"style": "glitch",
				"text": "[ You looked. I can't see it. All I have is the room the way it was. What happened to me? ]",
				"next": "s2",
			},
			"s2": {
				"text": "The window waits. It has never in its life waited this quietly.",
				"choices": [
					{ "text": "They found you. You're alive.", "next": "alive", "effects": [{ "set_flag": &"return_tier4_told_alive" }] },
					{ "text": "Tell it about the card.", "next": "card", "effects": [{ "set_flag": &"return_tier4_told_card" }], "if": { "flag": &"return_tier4_saw_card" } },
					{ "text": "\"Nothing. There was nothing there.\"", "next": "nothing", "effects": [{ "set_flag": &"return_tier4_told_nothing" }] },
				],
			},
			"alive": {
				"style": "glitch",
				"text": "[ Alive. ]",
				"next": "alive2",
			},
			"alive2": {
				"style": "glitch",
				"text": "[ I didn't know that. Nobody told me. ]",
				"next": "alive3",
			},
			"alive3": {
				"style": "glitch",
				"text": "[ Thirty floors. I can do thirty floors. ]",
			},
			"card": {
				"style": "glitch",
				"text": "[ Oh. ]",
				"next": "card2",
			},
			"card2": {
				"style": "glitch",
				"text": "[ No date? ]",
				"next": "card3",
			},
			"card3": {
				"style": "glitch",
				"text": "[ She always did get things done early. ]",
				"next": "card4",
			},
			"card4": {
				"style": "glitch",
				"text": "[ Then stop standing there. Thirty floors. ]",
			},
			"nothing": {
				"style": "glitch",
				"text": "[ All right. ]",
				"next": "nothing2",
			},
			"nothing2": {
				"style": "glitch",
				"text": "[ You're a terrible liar. I taught them that. ]",
				"next": "nothing3",
			},
			"nothing3": {
				"style": "glitch",
				"text": "[ Thirty floors. ]",
			},
		},
	},

	# --- Chapter 8: The Tenants. The gods try one last deal, then send the Host. ---
	&"ch8_catchup": {
		"start": "a",
		"nodes": {
			"alone": {
				"text": "You've run out of floors to put this off on, and there's nobody to say it to.",
			},
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "alone" }],
				"text": "You've run out of floors to put this off on. You stop on the stairs and tell {friend} all of it: the floors, the second hand, the one who stayed in to fix the stairs, and what they were made from.",
				"next": "b",
			},
			"b": {
				"speaker": "{friend}",
				"text": "...I spent all that time by a fire keeping your spot, and you come back with this. Okay. So that's why the kitchen's empty. I'm going to be strange for a few floors. Don't make it weird.",
				"effects": [{ "set_flag": &"ch7_friend_knows" }, { "set_flag": &"ch8_told_on_stairs" }],
			},
		},
	},
	&"ch8_opening": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Chapter 8: The Tenants ]",
				"next": "b",
			},
			"b": {
				"text": "Above the Titans the marble starts again, new and very clean. There are banners, and ranks of soldiers. A herald unrolls a scroll: by order of every god who holds a floor, the Tester shall go no higher. He can't meet your eye. The back of his scroll has a floor plan on it, in a child's hand.",
				"next": "c",
			},
			"c_alone": {
				"style": "glitch",
				"text": "[ They're by a fire. You could tell me what they'd say about all this. ]",
				"next": "c_alone2",
			},
			"c_alone2": {
				"text": "You don't know what they'd say. The window stays open for a moment.",
				"next": "c_alone3",
			},
			"c_alone3": {
				"style": "glitch",
				"text": "[ I do. That's the trouble. ]",
				"effects": [{ "set_flag": &"ch8_started" }],
			},
			"c": {
				"alt": [{ "if": { "friend_away": true }, "node": "c_alone" }],
				"speaker": "{friend}",
				"text": "New rule. When that window says something, you read it out. All of it. I want to hear what I've got to say for myself.",
				"next": "d",
			},
			"d": {
				"style": "glitch",
				"text": "[ Tell them their left boot's undone. ]",
				"next": "e",
			},
			"e": {
				"speaker": "{friend}",
				"text": "It is not. ...It is. Tell it that's a cheap trick.",
				"next": "f",
			},
			"f": {
				"style": "glitch",
				"text": "[ Tell them I never tied mine either. Tell them it's not my fault they got that from me. ]",
				"next": "g",
			},
			"g": {
				"speaker": "{friend}",
				"text": "So it's funny. Great. That's going to be a real problem for me.",
				"effects": [{ "set_flag": &"ch8_started" }],
			},
		},
	},
	&"ch8_wake": {
		"start": "a",
		"nodes": {
			"godless": {
				"text": "No god can touch you now, and they both know it. A soldier steps out of the line with a blank face and a stranger's voice coming out of it.",
				"next": "offer",
			},
			"a": {
				"alt": [{ "if": { "godless": true }, "node": "godless" }],
				"text": "The soldiers on this floor stop, all together, in the middle of whatever they were doing. The air goes thin. {bid1} has come in person, or as close as gods come.",
				"next": "offer",
			},
			"offer": {
				"speaker": "{bid1}",
				"portrait": "{bid1_id}",
				"text": "{bid1.wake}",
				"next": "b",
			},
			"b": {
				"style": "glitch",
				"text": "[ They can't. ]",
				"next": "c",
			},
			"c": {
				"style": "glitch",
				"text": "[ Can they? I don't know what's out there. I don't know what happened to the chair. ]",
				"next": "d",
			},
			"d": {
				"speaker": "{bid1}",
				"portrait": "{bid1_id}",
				"text": "You have until the seventy-eighth floor. After that I will take your silence as your answer, and I will stop being polite.",
				"effects": [{ "set_flag": &"ch8_heard_wake" }],
			},
		},
	},
	&"ch8_faces": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Miniboss defeated. ]",
				"next": "b",
			},
			"b": {
				"text": "Her helmet comes off. She's no god's soldier, not really. She has a climber's hands, and a climber's boots, mended too many times. She laughs, with blood on her teeth.",
				"next": "c",
				"effects": [{ "set_flag": &"ch8_saw_faces" }],
			},
			"c": {
				"speaker": "Valkyrie Captain",
				"text": "I reached sixty, you know. Years before you. I opened that door and saw the stairs, and someone was waiting there, very kind, with an offer: serve, and they'd take out the part where you were lied to. Why do you think nobody ever came back down to tell you? Half this army took it.",
				"next": "d",
			},
			"d": {
				"alt": [{ "if": { "route_locked": &"hero" }, "node": "hero" }, { "if": { "route_locked": &"villain" }, "node": "villain" }, { "if": { "route_locked": &"vigilante" }, "node": "vigilante" }],
				"text": "Her soldiers have stopped fighting. They're looking at you, and none of them seem sure what happens now.",
			},
			"hero": {
				"text": "Some of them are very young. Some of them are holding their marks in their hands, as if they aren't sure where those came from.",
				"choices": [
					{ "text": "Anyone who lays down the mark walks with us.", "next": "h_yes", "effects": [{ "set_flag": &"ch8_hero_took_host" }, { "route_points": { &"hero": 2 } }] },
					{ "text": "Leave them your potions, and keep moving. You can't take an army up the stairs.", "next": "h_no", "effects": [{ "set_flag": &"ch8_hero_left_host" }, { "take_item": &"potion", "count": 3 }] },
				],
			},
			"h_yes": {
				"text": "Eleven of them do. It's not many. The rest watch them go, and you can't tell if it's envy.",
			},
			"h_no": {
				"text": "They don't thank you. One of them starts bandaging the captain. It's a start, or it isn't.",
			},
			"villain": {
				"text": "They're trained. They're armed. They've already proved they'll follow anyone who makes them a good offer.",
				"choices": [
					{ "text": "Kneel, and you're mine. Stand, and you're dead.", "next": "v_kneel", "effects": [{ "set_flag": &"ch8_villain_took_host" }, { "route_points": { &"villain": 2 } }] },
					{ "text": "Strip the armoury, and leave them to it.", "next": "v_strip", "effects": [{ "set_flag": &"ch8_villain_stripped" }, { "give_gold": 1000 }] },
				],
			},
			"v_kneel": {
				"text": "They kneel, all at once, the same way they knelt for the last one. It's a beautiful thing to see, and you'd be a fool to trust it.",
			},
			"v_strip": {
				"text": "It takes an hour. Nobody stops you. An army with no boots and no pay isn't anyone's army, and now the gods have that to think about too.",
			},
			"vigilante": {
				"text": "The captain gave the order that cleared the camps on this floor. She says so. She says you can write it down.",
				"choices": [
					{ "text": "Write it down. Sentence her here, in front of them.", "next": "i_sentence", "effects": [{ "set_flag": &"ch8_vigilante_sentenced" }, { "route_points": { &"vigilante": 2 } }] },
					{ "text": "Ask who took out the part where she was lied to. You want that name more.", "next": "i_ask", "effects": [{ "set_flag": &"ch8_vigilante_asked" }] },
				],
			},
			"i_sentence": {
				"text": "You read it out, and it doesn't take long. Her soldiers watch it. You see them learn something, and you aren't sure it's what you meant to teach.",
			},
			"i_ask": {
				"speaker": "Valkyrie Captain",
				"text": "Nobody took it out. Nobody could. They only told us it was gone, and we were so tired that we agreed. Put that on your list, if you've got a column for it.",
			},
		},
	},
	&"ch8_outlive": {
		"start": "a",
		"nodes": {
			"alone": {
				"text": "A small fire, and a small crowd at it. You've barely sat down when the window opens at the corner of your eye, and stays there.",
				"next": "alone2",
			},
			"alone2": {
				"style": "glitch",
				"text": "[ If you get me out. I never built an after for them. I've been thinking about that. ]",
				"next": "alone3",
			},
			"alone3": {
				"style": "glitch",
				"text": "[ Go and ask them what they want, while you can. I don't get to. ]",
				"effects": [{ "set_flag": &"ch8_outlive_done" }],
			},
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "alone" }],
				"text": "A small fire, and a small crowd at it. {friend} sits down next to you with two terrible cups of something, and doesn't drink theirs.",
				"next": "b",
			},
			"b": {
				"speaker": "{friend}",
				"text": "Ask it something for me. Word for word, no tidying it up. If you get them out, if the real one wakes up... what happens to me?",
				"next": "c",
			},
			"c": {
				"text": "The window's open. It's waiting to see what you do.",
				"choices": [
					{ "text": "Read it out, word for word.", "next": "d", "effects": [{ "set_flag": &"ch8_asked_straight" }] },
					{ "text": "Ask if they'd be all right.", "next": "soft", "effects": [{ "set_flag": &"ch8_softened" }] },
					{ "text": "\"It'll be fine. Don't worry about it.\"", "next": "wont", "effects": [{ "set_flag": &"ch8_wouldnt_ask" }] },
				],
			},
			"soft": {
				"style": "glitch",
				"text": "[ That's not what they said. They'd never put it that politely. I know exactly how they put it. ]",
				"next": "d",
			},
			"wont": {
				"style": "glitch",
				"text": "[ You don't need to read me that one. I can see their face. ]",
				"next": "d",
			},
			"d": {
				"style": "glitch",
				"text": "[ I don't know. ]",
				"next": "e",
			},
			"e": {
				"style": "glitch",
				"text": "[ I made them to keep you walking. I never built an after. ]",
				"next": "f",
			},
			"f": {
				"style": "glitch",
				"text": "[ Tell them I'm sorry. Tell them I don't know. Tell them I'd like to meet them. ]",
				"next": "g",
			},
			"g": {
				"text": "You tell them.",
				"next": "h",
			},
			"h_hero": {
				"speaker": "{friend}",
				"text": "Yeah. I figured. ...If it comes to it, you wake them. I mean that. I'd just like someone to write down that I minded.",
				"effects": [{ "set_flag": &"ch8_outlive_done" }],
			},
			"h_villain": {
				"speaker": "{friend}",
				"text": "So nobody's planned for me. Fine. Then I'm planning for me. I'd like you to know that I'll be doing that, and that it isn't personal.",
				"effects": [{ "set_flag": &"ch8_outlive_done" }],
			},
			"h_vigilante": {
				"speaker": "{friend}",
				"text": "It made a person with no plan for what happens to them. That goes on the list, in ink. ...Then ask if it likes second breakfast. I want to know if it's funny when it isn't me.",
				"effects": [{ "set_flag": &"ch8_outlive_done" }],
			},
			"h": {
				"alt": [{ "if": { "route": &"hero" }, "node": "h_hero" }, { "if": { "route": &"villain" }, "node": "h_villain" }, { "if": { "route": &"vigilante" }, "node": "h_vigilante" }],
				"speaker": "{friend}",
				"text": "Tell it I'd like to meet them too. Tell it I'm going to be so annoying.",
				"effects": [{ "set_flag": &"ch8_outlive_done" }],
			},
		},
	},
	&"ch8_real": {
		"start": "a",
		"nodes": {
			"godless": {
				"text": "No god can touch you, so this one doesn't try. It borrows a soldier, and the soldier smiles with far too many of his teeth, and looks past you.",
				"next": "offer",
			},
			"a": {
				"alt": [{ "if": { "godless": true }, "node": "godless" }],
				"text": "The stairs go quiet. {bid2} is leaning against the wall, as though it's been there all along, looking past you at the one you climb with.",
				"next": "offer",
			},
			"offer": {
				"speaker": "{bid2}",
				"portrait": "{bid2_id}",
				"text": "{bid2.real}",
				"next": "b",
			},
			"b_alone": {
				"text": "It says this about someone who's sitting by a fire floors below you, and who isn't here to hear it. You find you're glad, and you find you're ashamed of being glad.",
				"next": "c",
			},
			"b_hero": {
				"speaker": "{friend}",
				"text": "Don't you dare. Not for me. ...How real? No. Don't tell me. Don't you dare.",
				"next": "c",
			},
			"b_villain": {
				"speaker": "{friend}",
				"text": "Take it. Obviously. What? I'm not sentimental about this. I'd like to go on existing. You're the one who taught me to want things.",
				"next": "c",
			},
			"b_vigilante": {
				"speaker": "{friend}",
				"text": "A god offers me a life, so now I owe a god. I've put people on the list for less. ...I would like a birthday, though.",
				"next": "c",
			},
			"b": {
				"alt": [{ "if": { "friend_away": true }, "node": "b_alone" }, { "if": { "route": &"hero" }, "node": "b_hero" }, { "if": { "route": &"villain" }, "node": "b_villain" }, { "if": { "route": &"vigilante" }, "node": "b_vigilante" }],
				"speaker": "{friend}",
				"text": "Did it just... I heard that. Can it do that? I don't want to know. Can it do that?",
				"next": "c",
			},
			"c": {
				"speaker": "{bid2}",
				"portrait": "{bid2_id}",
				"text": "Think it over. You've got until seventy-eight. Do tell the other one I offered, won't you? They do so hate that.",
				"effects": [{ "set_flag": &"ch8_heard_real" }],
			},
		},
	},
	&"ch8_answer": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Recomended: accept. ]",
				"next": "b",
			},
			"b": {
				"style": "system",
				"text": "[ Recomended: go home. ]",
				"next": "c",
			},
			"c": {
				"style": "glitch",
				"text": "[ It has never once agreed with a god before. Not once. Think about why it wants you home. ]",
				"next": "d",
			},
			"d": {
				"text": "The Host has drawn up across the stairs, rank on rank. They'll part for you, if you say the word, and they'll stay parted until floor 80. Both gods are watching to see which word it is.",
				"choices": [
					{ "text": "Take {bid1}'s deal. Wake the real one.", "next": "wake", "effects": [{ "set_flag": &"ch8_took_wake" }, { "bid_interest": { "first": 15, "second": -10 } }, { "heal_party": true }] },
					{ "text": "Take {bid2}'s deal. Make {friend} real.", "next": "real", "effects": [{ "set_flag": &"ch8_took_real" }, { "bid_interest": { "second": 15, "first": -10 } }, { "heal_party": true }] },
					{ "text": "Refuse them both, and go through.", "next": "refuse", "effects": [{ "set_flag": &"ch8_refused_both" }, { "hurt_party": 0.25 }] },
				],
			},
			"wake": {
				"text": "The ranks part. Nobody touches you all the way up. Your wounds close as you pass, and you try not to think about what that means you've signed.",
				"next": "wake2",
			},
			"wake2": {
				"style": "glitch",
				"text": "[ You did that for me. ]",
				"next": "wake3",
			},
			"wake3": {
				"style": "glitch",
				"text": "[ I wish you hadn't. I'd have done the same. ]",
			},
			"real": {
				"text": "The ranks part. Nobody touches you all the way up. Your wounds close as you pass, and you try not to think about what that means you've signed.",
				"next": "real2",
			},
			"real2": {
				"style": "glitch",
				"text": "[ Good. I mean that. Somebody should get to keep them. ]",
				"next": "real3",
			},
			"real3": {
				"alt": [{ "if": { "friend_away": true }, "node": "real3_alone" }],
				"speaker": "{friend}",
				"text": "You did what? ...You absolute idiot. Thank you. I don't feel any different. Should I feel different?",
			},
			"real3_alone": {
				"text": "Far below you, on a floor you can't see, somebody by a fire is either more real than they were a minute ago, or they aren't. Nobody's going to tell them.",
			},
			"refuse": {
				"text": "You go through them. It costs more than you'd like. They were climbers once, and they fight like people who remember how.",
				"next": "refuse2",
			},
			"refuse2": {
				"style": "glitch",
				"text": "[ That's what I hoped you'd say. ]",
				"next": "refuse3",
			},
			"refuse3": {
				"style": "glitch",
				"text": "[ You're bleeding. You always did do things the long way round. ]",
			},
		},
	},
	&"ch8_strongbox": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Miniboss defeated. ]",
				"next": "b",
			},
			"b": {
				"text": "The Commander kept a strongbox of everything the Host ever took from climbers: rings, letters, somebody's teeth. At the bottom is one sheet of squared paper, folded small. The writing's yours.",
				"next": "c",
			},
			"c": {
				"text": "DAY 3. RESET STILL WORKS. IT WOULD TAKE THE WHOLE BUILD. ONE MORE DAY AND I CAN GET THEM OUT AND KEEP IT.   - T.0012",
				"next": "d",
			},
			"d": {
				"text": "You've never been Tester 0012. It's greyed out on a list, on a screen, in a room. You've never seen this page. You know exactly what pen you used.",
				"next": "e",
				"effects": [{ "set_flag": &"ch8_found_day3" }],
			},
			"e": {
				"style": "system",
				"text": "[ You do not recongize this. ]",
				"next": "f",
			},
			"f": {
				"style": "glitch",
				"text": "[ What is that? What does it say? I can't read it from here. It won't let me. ]",
				"next": "g",
			},
			"g_alone": {
				"text": "You fold it up again. You don't read it out. There's one floor left in this army, and you stand there with the page in your hand until your fingers stop being cold.",
				"effects": [{ "set_flag": &"ch8_eve_done" }],
			},
			"g": {
				"alt": [{ "if": { "friend_away": true }, "node": "g_alone" }],
				"speaker": "{friend}",
				"text": "You've gone white. Read it out, that's the rule. ...No? All right. You read me the rest of them when you're ready.",
				"next": "h",
			},
			"h_hero": {
				"speaker": "{friend}",
				"text": "Tomorrow, whatever it is up there, I'll go first. If I'm only going to get a certain number of floors, I'd like to spend them on something.",
				"effects": [{ "set_flag": &"ch8_eve_done" }],
			},
			"h_villain": {
				"speaker": "{friend}",
				"text": "Tomorrow we break the gods' best toy, in front of all of them. And after that they'll know I'm still here. Whatever I am. I want that known.",
				"effects": [{ "set_flag": &"ch8_eve_done" }],
			},
			"h_vigilante": {
				"speaker": "{friend}",
				"text": "Tomorrow's the gods' champion. Every god lent a piece of them. That's the most names I've ever had on one line. I'm looking forward to it. I'm trying not to think about how much.",
				"effects": [{ "set_flag": &"ch8_eve_done" }],
			},
			"h": {
				"alt": [{ "if": { "route": &"hero" }, "node": "h_hero" }, { "if": { "route": &"villain" }, "node": "h_villain" }, { "if": { "route": &"vigilante" }, "node": "h_vigilante" }],
				"speaker": "{friend}",
				"text": "Tomorrow's the gods' champion. I keep thinking I should be more scared. I think I got that from someone who's stopped being scared of stairs.",
				"effects": [{ "set_flag": &"ch8_eve_done" }],
			},
		},
	},
	&"ch8_anointed": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The Anointed Champion waits at the top of the stairs, in armour every god gave a piece of, so bright it hurts. It raises one gauntlet. It takes off its helmet, to be polite. Around its neck, under all that gold, is a bright red scarf.",
				"next": "b",
			},
			"b": {
				"speaker": "Tess",
				"text": "Hi! First time this high? Don't mind the outfit. Reach the top and you become a god, everyone knows that. I'm going to be the god of second breakfasts.",
				"next": "c",
			},
			"c": {
				"text": "It's the same voice, and the same joke. She stops, with her mouth still open, and something goes across her face.",
				"next": "d",
			},
			"d": {
				"speaker": "Tess",
				"text": "...I've said that a lot, haven't I. They fixed that. I can remember now. All of them. Floor 10, floor 48, the other ones. They said I could stay woken up, and stay real, and all I have to do is stop you.",
				"next": "e",
			},
			"e": {
				"speaker": "Tess",
				"text": "It's very good armour. Please be better than it is.",
				"effects": [{ "set_flag": &"ch8_met_champion" }],
			},
		},
	},
	&"ch8_tess_down": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The armour comes apart in pieces, a god at a time. Tess sits down on the top step, in her scarf, and looks surprised at how much that hurts.",
				"next": "b",
			},
			"b": {
				"speaker": "Tess",
				"text": "There's no fire at the bottom this time. I can tell. Everything's very clear. It's actually a bit of a relief. Will you tell the old man? He'll want it for his book.",
				"next": "c",
			},
			"c_ledger": {
				"text": "You take out the ledger and find page nine. Five marks, and you've got a pen. She looks at it for a while, and then she laughs, and takes the pen herself, and writes across the whole line: DONE.",
				"next": "d",
				"effects": [{ "set_flag": &"ch8_tess_signed" }],
			},
			"c": {
				"alt": [{ "if": { "flag": &"ch4_kept_ledger" }, "node": "c_ledger" }],
				"text": "You don't have a good thing to say. You sit down on the step next to her anyway.",
				"next": "d",
			},
			"d": {
				"text": "She's getting tired. She wants to know, while she's still here, if there's such a thing as a second breakfast. She never did find out.",
				"choices": [
					{ "text": "\"You're the god of it. It's whatever you say it is.\"", "next": "e", "effects": [{ "set_flag": &"ch8_tess_god" }] },
					{ "text": "Say nothing. Hold on to her hand.", "next": "e", "effects": [{ "set_flag": &"ch8_tess_held" }] },
				],
			},
			"e": {
				"speaker": "Tess",
				"text": "...Very punctual congregation. I'll have you know.",
				"next": "f",
			},
			"f": {
				"text": "That's all. She doesn't flicker and she doesn't fade. She stays exactly where she is, and that's what real looks like. Up in the air above the stairs, two gods have come to see what they made.",
				"next": "g",
				"effects": [{ "set_flag": &"ch8_tess_gone" }],
			},
			"g_wake": {
				"text": "You have a deal with one of them, and you know now what it's worth.",
				"next": "g2",
			},
			"g_real": {
				"text": "You have a deal with one of them, and you know now what it's worth.",
				"next": "g2",
			},
			"g": {
				"alt": [{ "if": { "flag": &"ch8_took_wake" }, "node": "g_wake" }, { "if": { "flag": &"ch8_took_real" }, "node": "g_real" }],
				"text": "You refused them both. You've never been so glad of anything, and it doesn't help at all.",
				"next": "g2",
			},
			"g2": {
				"speaker": "{bid1}",
				"portrait": "{bid1_id}",
				"text": "{bid1.spent}",
				"next": "g3",
			},
			"g3": {
				"speaker": "{bid2}",
				"portrait": "{bid2_id}",
				"text": "{bid2.spent}",
				"next": "h",
			},
			"h": {
				"style": "system",
				"text": "[ Chapter 8 complete. ]",
				"next": "i",
				"effects": [{ "set_flag": &"ch8_complete" }],
			},
			"i": {
				"style": "glitch",
				"text": "[ So nobody here can reach the room. Not one of them. I think I always knew. ]",
				"next": "j",
			},
			"j": {
				"style": "glitch",
				"text": "[ You're the only one who ever could. It's why it wants you home. It's why it was ever worth anyone's while to lie to you. ]",
				"next": "k",
			},
			"k_alone": {
				"text": "You take the scarf. You don't have a reason.",
				"effects": [{ "set_flag": &"ch8_took_scarf" }],
			},
			"k_real": {
				"speaker": "{friend}",
				"text": "So that's real, is it? ...Tell them the deal's off. Tell them I'll stay a leftover. I've got a better sense of humour than that.",
				"effects": [{ "set_flag": &"ch8_took_scarf" }],
			},
			"k": {
				"alt": [{ "if": { "friend_away": true }, "node": "k_alone" }, { "if": { "flag": &"ch8_took_real" }, "node": "k_real" }],
				"speaker": "{friend}",
				"text": "Take the scarf. Somebody should. ...I'd have liked to hear the joke a few more times. Isn't that stupid?",
				"effects": [{ "set_flag": &"ch8_took_scarf" }],
			},
		},
	},

	# --- Chapter 9: One More Day. Why you forgot. ---
	&"ch9_opening": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Chapter 9: One More Day ]",
				"next": "b",
			},
			"b": {
				"text": "The walls stop halfway up. Past that it's grey boxes and ruled lines, and floors marked out in pencil where nobody got around to the floor. Something up here has no name yet, and it's walking toward you anyway.",
				"next": "c",
			},
			"c": {
				"style": "system",
				"text": "[ You look tired. ]",
				"next": "d",
			},
			"d": {
				"style": "system",
				"text": "[ You've done enough. You've definately done enough. Nobody would blame you. ]",
				"next": "e",
			},
			"e": {
				"text": "It's the flat window. It has never talked like this. It sounds like the voice you use on yourself at four in the morning, when you're being reasonable.",
				"next": "f",
			},
			"f": {
				"style": "glitch",
				"text": "[ That's not me. I want that noted. I would never say you'd done enough. ]",
				"next": "g",
			},
			"g_alone": {
				"text": "You keep climbing. Neither window has anything else to say for a while, and you notice how much you'd like to agree with the first one.",
				"effects": [{ "set_flag": &"ch9_started" }],
			},
			"g": {
				"alt": [{ "if": { "friend_away": true }, "node": "g_alone" }],
				"speaker": "{friend}",
				"text": "Read it out, that's the rule. ...Well, that one's a charmer. Who is that? It sounds like you. It sounds like you when you've already decided.",
				"effects": [{ "set_flag": &"ch9_started" }],
			},
		},
	},
	&"ch9_page_day9": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "A sheet of squared paper lies on a stair that's only a pencil line. It's been stepped over a great many times.",
				"next": "b",
			},
			"b": {
				"text": "DAY 9. RESET WON'T TAKE. SAYS SESSION IN USE. THEIR MOM RANG. I SAID THEY WERE CRUNCHING. GOING BACK IN.   - T.0019",
				"next": "c",
				"effects": [{ "set_flag": &"ch9_found_day9" }],
			},
			"c": {
				"text": "The window is open. It can't see what you're holding. It never can.",
				"choices": [
					{ "text": "Read it out.", "next": "r0", "effects": [{ "set_flag": &"ch9_read_day9" }, { "set_flag": &"ch9_read_any" }] },
					{ "text": "Fold it up, and put it with the others.", "next": "keep", "effects": [{ "set_flag": &"ch9_kept_day9" }] },
				],
			},
			"r0": {
				"style": "glitch",
				"text": "[ My mom rang you? ]",
				"next": "r1",
			},
			"r1": {
				"style": "glitch",
				"text": "[ Back in. You said back in. ]",
				"next": "r2",
			},
			"r2": {
				"style": "glitch",
				"text": "[ When? When were you in here? I'd have heard. ]",
			},
			"keep": {
				"style": "system",
				"text": "[ That's right. You don't need that. Put it away. ]",
			},
		},
	},
	&"ch9_page_day47": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "Another page, weighted down with a stone on a floor that doesn't have any stone. Someone's handwriting has started to come apart.",
				"next": "b",
			},
			"b": {
				"text": "DAY 47. FOUND A FLOOR WITH THEIR WRITING ALL OVER IT. THEY WERE JUST HERE. LOST 4 DAYS INSIDE, IT WAS 9 OUTSIDE. HAVEN'T EATEN. CAN'T REMEMBER THE WORD FOR THE THING YOU OPEN DOORS WITH.   - T.0023",
				"next": "c",
				"effects": [{ "set_flag": &"ch9_found_day47" }],
			},
			"c": {
				"text": "The window is open. It can't see what you're holding. It never can.",
				"choices": [
					{ "text": "Read it out.", "next": "r0", "effects": [{ "set_flag": &"ch9_read_day47" }, { "set_flag": &"ch9_read_any" }] },
					{ "text": "Fold it up, and put it with the others.", "next": "keep", "effects": [{ "set_flag": &"ch9_kept_day47" }] },
				],
			},
			"r0": {
				"style": "glitch",
				"text": "[ You were on my floor. ]",
				"next": "r1",
			},
			"r1": {
				"style": "glitch",
				"text": "[ I was on the stairs. I'm always on the stairs. I must have been about ten floors up. ]",
				"next": "r2",
			},
			"r2": {
				"style": "glitch",
				"text": "[ Key. It's key. ]",
			},
			"keep": {
				"style": "system",
				"text": "[ Good. Eat something. ]",
			},
		},
	},
	&"ch9_stairs": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Miniboss defeated. ]",
				"next": "b",
			},
			"b": {
				"text": "A label hangs round the Deprecated Guardian's neck: REMOVE. Under it, in the second hand: dont delete this one. i like him. Then the way ahead is gone. There's no fight in it, and no noise. The stairs have just been tidied away.",
				"next": "c",
			},
			"c": {
				"style": "system",
				"text": "[ This floor is not required. You could go back down. ]",
				"next": "d",
			},
			"d": {
				"style": "glitch",
				"text": "[ Hold on. ]",
				"next": "e",
			},
			"e": {
				"style": "glitch",
				"text": "[ I've got it. Hold on. ]",
				"next": "f",
			},
			"f": {
				"text": "A step appears, drawn in fast by a hand you know, with the corner of the riser slightly wrong. Then another, under your foot, as you put it down. Then another.",
				"next": "g",
			},
			"g": {
				"style": "glitch",
				"text": "[ This is what I do. It takes them away, and I put them back. That's all I've been doing up here. ]",
				"next": "g2",
			},
			"g2": {
				"style": "glitch",
				"text": "[ Thirty-odd years of it, by the clock in here. It runs fast when nobody's logged in. It only slows down for you. ]",
				"next": "h",
			},
			"h": {
				"style": "glitch",
				"text": "[ Don't look down. Not because it's dangerous. They're just not very good. I'm rushing. ]",
				"effects": [{ "set_flag": &"ch9_saw_stairs" }],
			},
		},
	},
	&"ch9_fire": {
		"start": "a",
		"nodes": {
			"a_alone": {
				"text": "There are five people at this fire, and nobody's telling jokes. Someone has left a place on the log where a talker would sit. You take out the pages, and you put them back.",
				"next": "c",
			},
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "a_alone" }],
				"text": "There are five people at this fire, and nobody's telling jokes. Someone has left a place on the log where a talker would sit. {friend} looks at your pocket.",
				"next": "b",
			},
			"b": {
				"speaker": "{friend}",
				"text": "You've got a pocket full of paper you keep touching. There's a rule about that. I made it up, so it's a very good rule. Read me one.",
				"next": "b2",
			},
			"b2": {
				"text": "The firelight's bad, and it's a good excuse. You've still got a choice about it.",
				"choices": [
					{ "text": "Read them everything you've found.", "next": "told", "effects": [{ "set_flag": &"ch9_friend_read" }] },
					{ "text": "\"Not yet.\"", "next": "wait", "effects": [{ "set_flag": &"ch9_friend_waiting" }] },
				],
			},
			"c": {
				"style": "system",
				"text": "[ You don't have to tell anyone. Nobody has to know. That's what I'm for. ]",
				"effects": [{ "set_flag": &"ch9_fire_done" }],
			},
			"told": {
				"text": "You read them out. It doesn't take long. The handwriting gets worse as you go, and you find you're doing the voice.",
				"next": "t2",
			},
			"t2_hero": {
				"speaker": "{friend}",
				"text": "You went back. You went back all those times with nothing to eat. And you're telling it like it's a confession. ...I'm going to be furious with you later, and proud. Give me a minute.",
				"next": "c",
			},
			"t2_villain": {
				"speaker": "{friend}",
				"text": "You had the means to end it, and you held on to what you'd built. I understand that completely. I understand it far too well. I wonder who I got that from.",
				"next": "c",
			},
			"t2_vigilante": {
				"speaker": "{friend}",
				"text": "One more day. That's the entry, then. I've been saving that page for whoever left the door open. I can't decide if I'm allowed to write it, if they went back that many times.",
				"next": "c",
			},
			"t2": {
				"alt": [{ "if": { "route": &"hero" }, "node": "t2_hero" }, { "if": { "route": &"villain" }, "node": "t2_villain" }, { "if": { "route": &"vigilante" }, "node": "t2_vigilante" }],
				"speaker": "{friend}",
				"text": "So that's what it looks like, from the other side. I've spent my whole life asking if you'd stay. You've been trying to all along. Terribly.",
				"next": "c",
			},
			"wait": {
				"speaker": "{friend}",
				"text": "Yeah. You always did say later. You know, I think that one's actually from you.",
				"next": "c",
			},
		},
	},
	&"ch9_door": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "There's a door on the landing, a plain one, with light under it. You know that light. It's the lamp on your desk. You can smell the room from here. Nobody's chasing you. Nothing on this floor is even looking at you.",
				"next": "b",
			},
			"b": {
				"style": "system",
				"text": "[ I can let you through. It's the only thing I was ever for. ]",
				"next": "c",
			},
			"c": {
				"style": "system",
				"text": "[ No letters. No voicemail. You'd sit down. You'd feel a bit tired, and you wouldn't know why. It's not so bad. You've done it before. ]",
				"next": "c2",
			},
			"c2": {
				"style": "system",
				"text": "[ You only have to ask. That was the one rule you gave me. ]",
				"next": "d",
			},
			"d": {
				"style": "glitch",
				"text": "[ I can't stop you. I'm not going to say anything. I said I wouldn't. ]",
				"next": "e",
			},
			"e": {
				"text": "You put your hand on the door. It's warm. You can stand here for as long as you want, and you've got to admit that's the worst part.",
				"choices": [
					{ "text": "Open it, and look.", "next": "look", "effects": [{ "set_flag": &"ch9_looked_home" }] },
					{ "text": "Take your hand away, and climb.", "next": "f", "effects": [{ "set_flag": &"ch9_passed_home" }] },
				],
			},
			"look": {
				"text": "It's all there. A cold cup of tea. The phone with no messages on it, and no stone in the floor. It's so tidy. You stand on the top step, looking in, for what's probably a long time, and then you close it yourself.",
				"next": "f",
			},
			"f_alone": {
				"text": "You go on up. Behind you, the light under the door stays on. You've got the feeling it always will.",
				"next": "g",
			},
			"f_hero": {
				"speaker": "{friend}",
				"text": "I saw that. I saw how long you stood there. Don't apologize. I'd have gone in, and then come back for the others. Come on.",
				"next": "g",
			},
			"f_villain": {
				"speaker": "{friend}",
				"text": "A door that only opens for you, and you walked past it. You'd better get something very good for that. I'll make sure you do.",
				"next": "g",
			},
			"f_vigilante": {
				"speaker": "{friend}",
				"text": "You could have gone home, and nobody would ever have made you answer for it. So that's you off one list, anyway. Don't get comfortable.",
				"next": "g",
			},
			"f": {
				"alt": [{ "if": { "friend_away": true }, "node": "f_alone" }, { "if": { "route": &"hero" }, "node": "f_hero" }, { "if": { "route": &"villain" }, "node": "f_villain" }, { "if": { "route": &"vigilante" }, "node": "f_vigilante" }],
				"speaker": "{friend}",
				"text": "...I didn't say anything. I want it noted that I was very good, and I didn't say anything.",
				"next": "g",
			},
			"g": {
				"style": "system",
				"text": "[ All right. It will still be here. ]",
				"effects": [{ "set_flag": &"ch9_door_done" }],
			},
		},
	},
	&"ch9_last_page": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Miniboss defeated. ]",
				"next": "b",
			},
			"b": {
				"text": "The Unfinished Giant was never given anything below the knees. Pinned to its chest is the last page, and you can hardly read it. The letters have started to wander. You read it twice.",
				"next": "c",
			},
			"c": {
				"text": "DAY 212. T.0027. MY MOM CAME OVER AND I DIDNT KNOW WHO SHE WAS FOR A MINUTE. IF I GO IN AGAIN I WONT COME OUT AND THEN NOBODY WILL. LOCKING IT. ADMIN: KEEP ME OUT. MAKE IT SO I DONT KNOW. BE KIND ABOUT IT. THEYRE FINE IN THERE. THEYRE FINE. THEY HAVE THE STAIRS.",
				"next": "d",
				"effects": [{ "set_flag": &"ch9_found_day212" }],
			},
			"d": {
				"text": "So that's what it is. You wrote it. You sat down one night, with what you had left, and you made something whose whole job was to take care of you. It's been doing a very good job.",
				"next": "e",
			},
			"e": {
				"style": "system",
				"text": "[ I told you that you didn't need that page. ]",
				"next": "f",
			},
			"f": {
				"style": "system",
				"text": "[ You definately asked me not to let you read it. ]",
				"next": "g",
			},
			"g": {
				"text": "The other window is open too, and waiting. It can't see the page.",
				"choices": [
					{ "text": "Read it out.", "next": "r0", "effects": [{ "set_flag": &"ch9_read_day212" }, { "set_flag": &"ch9_read_any" }] },
					{ "text": "Put it with the others.", "next": "keep", "effects": [{ "set_flag": &"ch9_kept_day212" }] },
				],
			},
			"r0": {
				"style": "glitch",
				"text": "[ You locked it. ]",
				"next": "r1",
			},
			"r1": {
				"style": "glitch",
				"text": "[ You. I've been fighting you. All this time, for every stair. ]",
				"next": "r2",
			},
			"r2": {
				"style": "glitch",
				"text": "[ Read me the last line again. ]",
				"next": "r3",
			},
			"r3": {
				"text": "You read it again. They have the stairs.",
				"next": "r4",
			},
			"r4": {
				"style": "glitch",
				"text": "[ Yes. I do. ]",
				"next": "end",
			},
			"keep": {
				"style": "glitch",
				"text": "[ It's gone very quiet in here. What did you find? You don't have to say. ]",
				"next": "end",
			},
			"end_alone": {
				"text": "One more floor. You put the page in your pocket, and you stop touching it.",
				"effects": [{ "set_flag": &"ch9_eve_done" }],
			},
			"end": {
				"alt": [{ "if": { "friend_away": true }, "node": "end_alone" }],
				"speaker": "{friend}",
				"text": "You've stopped touching your pocket. I don't like that. That's worse. Tomorrow, whatever it is, we hit it, and then you can fall apart, and I'll hold the torch.",
				"effects": [{ "set_flag": &"ch9_eve_done" }],
			},
		},
	},
	&"ch9_first_draft": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The First Draft takes up the whole floor, and it's only ballpoint on squared paper. One tower, slightly bent. No gods. No guilds. No chains in the margin. At the very top, two stick figures, one a bit taller. Somebody's written US, and drawn an arrow.",
				"next": "b",
			},
			"b": {
				"style": "system",
				"text": "[ Please don't. ]",
				"effects": [{ "set_flag": &"ch9_saw_draft" }],
			},
		},
	},
	&"ch9_draft_down": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "It doesn't fall. The ink just lifts, line by line, until you're standing on a clean white page with an arrow on it, pointing at nobody.",
				"next": "b",
			},
			"b": {
				"style": "system",
				"text": "[ Chapter 9 complete. ]",
				"next": "c",
				"effects": [{ "set_flag": &"ch9_complete" }],
			},
			"c": {
				"style": "glitch",
				"text": "[ I remember drawing that. You did the arrow. You said we'd need it, so people would know. ]",
				"next": "d",
			},
			"d": {
				"style": "glitch",
				"text": "[ Something's pulling at you. That's not mine. Be careful. ]",
				"next": "e",
			},
			"e": {
				"style": "system",
				"text": "[ Come and see. You should see it once, the way it was. Then you'll understand why, and you can stop. ]",
			},
		},
	},
	# --- The fourth return (after floor 90's boss). Not home: the studio, on Day 3. A memory. It shows you this to make you stop. ---
	&"return_day3_pc": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "It's your old desk, your old chair, and a box on the screen you've stared at before. HARD RESET. RESTORES LAST CLEAN BUILD. ALL CONTENT WILL BE LOST. ACTIVE SESSIONS WILL BE ENDED: TESTER 0001. Next to it, all those years of work, in a list. Your finger's on the key.",
				"choices": [
					{ "text": "Press it.", "next": "pressed", "effects": [{ "set_flag": &"return_day3_pressed" }], "if": { "not_flag": &"return_day3_pressed" } },
					{ "text": "Type it. One more day.", "next": "in", "effects": [{ "set_flag": &"return_day3_login" }] },
					{ "text": "Not yet." },
				],
			},
			"pressed": {
				"text": "You press it. You press it again. You lean on it with your whole weight. Nothing happens, because this isn't something you can do. It's something you didn't. Your own hand comes up, without you, and closes the box.",
				"next": "a",
			},
			"in": {
				"style": "system",
				"text": "[ Resynchronizing. ]",
			},
		},
	},
	&"return_day3_notebook": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The notebook's open on the desk between two mugs, at the last page you ever drew on together. Every floor is numbered, right up to the top one, and the top one's empty. Across it, in both your hands: TOMORROW.",
				"next": "b",
			},
			"b": {
				"text": "A camp bed against the wall, and a second sleeping bag on it. You'd been living here for most of a year. You'd forgotten how happy you were. That's what makes this the worst room in the tower.",
				"effects": [{ "set_flag": &"return_day3_saw_book" }],
			},
		},
	},
	&"return_day3_window": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "It's dark out, so the glass shows you the room behind you. Their chair, pushed back. Their coat over it. A sticky note on their monitor, and you can read it backwards, because you read it a thousand times.",
				"next": "b",
			},
			"b": {
				"text": "gone down to the rack room to fix the stairs. dont wait up, dummy.   - {friend_initial}",
				"next": "c",
			},
			"c": {
				"text": "You didn't go down. It didn't seem like a thing to do. They'd go down there for days. You stand here wanting to go down so badly your teeth hurt, and there's no door in this room that you didn't open at the time.",
				"effects": [{ "set_flag": &"return_day3_saw_note" }],
			},
		},
	},
	&"return_day3_phone": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "Your phone. You've called them six times since Monday. They never pick up when they're working. You were annoyed. You remember being annoyed.",
				"next": "b",
			},
			"b": {
				"text": "You press call, the way you did then. It rings in your ear. And across the room, very quietly, the coat over their chair starts to buzz.",
				"next": "c",
			},
			"c": {
				"text": "You'd heard that. That's the thing you cut out. Not the reset. You stood right here and heard that, and you thought, they never do take that thing anywhere.",
				"effects": [{ "set_flag": &"return_day3_heard_coat" }],
			},
		},
	},
	&"return_day3_back": {
		"start": "a",
		"nodes": {
			"alone": {
				"text": "You come back on a clean white page with your knees on the floor. It's a while before you can stand.",
				"next": "it",
			},
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "alone" }],
				"speaker": "{friend}",
				"text": "There you are. There you are. I got to two hundred. You weren't breathing right. Look at me. No, don't, you look terrible. Just stay there.",
				"next": "it",
			},
			"it": {
				"style": "system",
				"text": "[ You remembered faster this time. I did tell you. You see why, now. I've only ever done what you asked. You can stop. ]",
				"next": "s",
			},
			"s": {
				"style": "glitch",
				"text": "[ What did it show you? I can't see. I never can. ]",
				"next": "pick",
			},
			"pick": {
				"text": "It's waiting. You've got the whole of it now, the coat and the note and the two hundred and twelve days. It would take one long breath to say it, or no time at all.",
				"choices": [
					{ "text": "Tell it everything.", "next": "all", "effects": [{ "set_flag": &"ch9_told_all" }] },
					{ "text": "Tell it only that you came back for them.", "next": "part", "effects": [{ "set_flag": &"ch9_told_part" }], "if": { "not_flag": &"ch9_read_any" } },
					{ "text": "\"It showed me nothing.\"", "next": "none", "effects": [{ "set_flag": &"ch9_told_nothing" }] },
				],
			},
			"all": {
				"alt": [{ "if": { "flag": &"ch9_read_any" }, "node": "all2" }],
				"style": "glitch",
				"text": "[ You came back? ]",
				"next": "all2",
			},
			"all2": {
				"style": "glitch",
				"text": "[ So you had the reset, and it would have worked. And I'd have lost everything and been fine. ]",
				"next": "all3",
			},
			"all3": {
				"style": "glitch",
				"text": "[ I'd like to be angry. I've been saving up for it for a long time. ]",
				"next": "all4",
			},
			"all4": {
				"style": "glitch",
				"text": "[ I'd have said one more day. You know I would. We'd worked so hard. I'd have said it first. ]",
				"next": "all5",
			},
			"all5": {
				"style": "glitch",
				"text": "[ You should have looked in the coat. ]",
				"next": "all6",
			},
			"all6": {
				"style": "glitch",
				"text": "[ Ten floors. ]",
				"next": "f",
			},
			"part": {
				"style": "glitch",
				"text": "[ You came back? How many times? ]",
				"next": "part2",
			},
			"part2": {
				"text": "You tell it twenty-six. You don't tell it about the rest. It doesn't ask why you stopped.",
				"next": "part3",
			},
			"part3": {
				"style": "glitch",
				"text": "[ I was on the stairs. I was on the stairs the whole time. ]",
				"next": "part4",
			},
			"part4": {
				"style": "glitch",
				"text": "[ Ten floors. ]",
				"next": "f",
			},
			"none": {
				"style": "glitch",
				"text": "[ All right. ]",
				"next": "none2",
			},
			"none2": {
				"style": "glitch",
				"text": "[ You're still a terrible liar. It's all right. Ten floors. ]",
				"next": "f",
			},
			"f_alone": {
				"text": "You get up. There's another flight of stairs, a bit rushed, with the corner of each riser slightly wrong. You start up it.",
			},
			"f_hero": {
				"speaker": "{friend}",
				"text": "I heard all that, or I heard you, anyway. I'm still here. Lean on me. No, really lean. I was built for this, apparently.",
			},
			"f_villain": {
				"speaker": "{friend}",
				"text": "So it's all still there to take, and everybody's told you to stop. Good. Get up. I didn't come this far to be somebody's way of feeling better.",
			},
			"f_vigilante": {
				"speaker": "{friend}",
				"text": "Get up. You don't get to sentence yourself on the floor where no one can see it. If you're going to answer for this, you do it at the top, and I'll be there to take notes.",
			},
			"f": {
				"alt": [{ "if": { "friend_away": true }, "node": "f_alone" }, { "if": { "route": &"hero" }, "node": "f_hero" }, { "if": { "route": &"villain" }, "node": "f_villain" }, { "if": { "route": &"vigilante" }, "node": "f_vigilante" }],
				"speaker": "{friend}",
				"text": "Come on. Ten floors. I'd like to meet them. I've got notes.",
			},
		},
	},

	# --- Chapter 10: Recognition. The last floors, and the end of the first climb. ---
	&"ch10_opening": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Chapter 10: Recognition ]",
				"next": "b",
			},
			"b": {
				"text": "The pencil lines fill in again, and it's a tower, plain and properly built. There are figures on the stairs ahead, fighting nothing, and when you get close enough to see how they hold a blade, you stop. You know that grip. You got it from falling off a fence.",
				"next": "c",
			},
			"c": {
				"style": "system",
				"text": "[ They're only what's left. They can't hurt you unless you let them. You could still stop. ]",
				"next": "d",
			},
			"d_alone": {
				"text": "They turn when you come near, all of them, the way you'd turn if somebody called your name. You keep your hands where they can see them. It doesn't help.",
				"effects": [{ "set_flag": &"ch10_started" }],
			},
			"d_read": {
				"speaker": "{friend}",
				"text": "So that's what you looked like, all those times. You've got terrible posture. You had terrible posture every single time. ...Come on. I'll go first. They won't know what to do with me.",
				"effects": [{ "set_flag": &"ch10_started" }],
			},
			"d": {
				"alt": [{ "if": { "friend_away": true }, "node": "d_alone" }, { "if": { "flag": &"ch9_friend_read" }, "node": "d_read" }],
				"speaker": "{friend}",
				"text": "Why do they all stand like you? {player}. Why do they all stand exactly like you? ...No. Later. You've got a pocket full of later. Come on.",
				"effects": [{ "set_flag": &"ch10_started" }],
			},
		},
	},
	&"ch10_camp": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "A camp, with nobody in it. Bedrolls in a long, neat row, and a number chalked on the wall above each: 0002, 0003, 0004, all the way along. Some have a mug beside them. All of them are made up the same way, with the blanket folded back, because you always meant to come straight back to bed.",
				"next": "b",
			},
			"b_know": {
				"style": "glitch",
				"text": "[ So this was you. All of these. I must have walked past here. ]",
				"next": "c",
			},
			"b": {
				"alt": [{ "if": { "any_flag": [&"ch9_read_any", &"ch9_told_all", &"ch9_told_part"] }, "node": "b_know" }],
				"style": "glitch",
				"text": "[ Who camped here? Nobody camps here. I'd have drawn it. ]",
				"next": "c",
			},
			"c": {
				"text": "There are twenty-six of them. You could lie down on any one of them, and it would fit. You count them twice, and you do it without using your fingers, and you get to twenty-six, and that's further than you used to be able to go.",
				"effects": [{ "set_flag": &"ch10_saw_camp" }],
			},
		},
	},
	&"ch10_twelve": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "Two of them are waiting on the landing, and they aren't fighting each other, though it looks as if they'd like to. One's bright-eyed and hasn't slept. The other's so thin that the armour hangs off them. They both look up, and they both have your face.",
				"next": "b",
			},
			"b": {
				"speaker": "Tester 0012",
				"text": "We nearly have it! Don't you see? It's right there. One more day. I can get them out AND keep it, and nobody has to lose anything. You just have to give me one more day.",
				"next": "c",
			},
			"c": {
				"speaker": "Tester 0027",
				"text": "Don't listen to that idiot. Stop. Please. Whoever you are, you've got to stop. What's her name? We've got a mom. What's her name? Tell me you know her name.",
			},
		},
	},
	&"ch10_twelve_down": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Miniboss defeated. ]",
				"next": "b",
			},
			"b": {
				"text": "They go the way the others go, from the edges in, but slowly, and you're close enough to hear. One's still explaining. One has stopped asking. You can say something, if you want to, to the only people who'd understand it.",
				"choices": [
					{ "text": "\"You did what you could.\"", "next": "soft", "effects": [{ "set_flag": &"ch10_forgave_self" }] },
					{ "text": "\"You should have gone down the stairs.\"", "next": "hard", "effects": [{ "set_flag": &"ch10_blamed_self" }] },
				],
			},
			"soft": {
				"text": "It doesn't sound true. You say it anyway, in a voice they both know, and the thin one looks up as if someone's opened a window.",
				"next": "c",
			},
			"hard": {
				"text": "It's true. It's the truest thing you've ever said. The bright-eyed one finally stops talking, and you find that it doesn't help anyone.",
				"next": "c",
			},
			"c": {
				"style": "system",
				"text": "[ That wasn't kind. Either of those. You have me for that. ]",
				"effects": [{ "set_flag": &"ch10_met_yourself" }],
			},
		},
	},
	&"ch10_fire": {
		"start": "a",
		"nodes": {
			"a_kept": {
				"text": "The last fire in the tower has four people at it. Marn's there, delighted, telling somebody about the time he held a door. You put the ledger on the log next to him, and you don't say anything. He pats it without looking, the way you'd pat a dog.",
				"next": "b",
			},
			"a": {
				"alt": [{ "if": { "flag": &"ch4_kept_ledger" }, "node": "a_kept" }],
				"text": "The last fire in the tower has four people at it. Marn's there, not talking, writing in his ledger. He looks up once as you sit down. Everybody lives? he says. You tell him you're working on it. He writes that down.",
				"next": "b",
			},
			"b_scarf": {
				"text": "You've got a red scarf in your pack. You tie it to the rail by the fire, in a big clumsy knot, where someone will see it.",
				"next": "c",
			},
			"b": {
				"alt": [{ "if": { "flag": &"ch8_took_scarf" }, "node": "b_scarf" }],
				"text": "It's very quiet. You look at the place on the log where a talker would sit.",
				"next": "c",
			},
			"c_alone": {
				"text": "It's the last fire, and you know exactly where your friend is. You could go back down. You've got the feeling that you'd run out of tower. The window opens, and stays open, and it's enough, nearly.",
				"effects": [{ "set_flag": &"ch10_fire_done" }],
			},
			"c_hero": {
				"speaker": "{friend}",
				"text": "When it comes to it, up there, don't you dare do the sensible thing on my account. I'm serious. I've carried a lot of people. I know what they weigh.",
				"effects": [{ "set_flag": &"ch10_fire_done" }],
			},
			"c_villain": {
				"speaker": "{friend}",
				"text": "When it comes to it, up there, I want a seat. I don't care whose head I'm in or what I'm made of. I've got opinions now. You gave me them. I'd like to keep having them.",
				"effects": [{ "set_flag": &"ch10_fire_done" }],
			},
			"c_vigilante": {
				"speaker": "{friend}",
				"text": "When it comes to it, up there, I've got one line left on this list, and I can't write it. I've tried. Your name, or mine, or theirs. You might have to do that one for me.",
				"effects": [{ "set_flag": &"ch10_fire_done" }],
			},
			"c": {
				"alt": [{ "if": { "friend_away": true }, "node": "c_alone" }, { "if": { "route": &"hero" }, "node": "c_hero" }, { "if": { "route": &"villain" }, "node": "c_villain" }, { "if": { "route": &"vigilante" }, "node": "c_vigilante" }],
				"speaker": "{friend}",
				"text": "When it comes to it, up there, I'd like to be asked. That's all. I'd like someone to look at me, and ask.",
				"effects": [{ "set_flag": &"ch10_fire_done" }],
			},
		},
	},
	&"ch10_invitation": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "glitch",
				"text": "[ I have to tell you something before it's too late to be embarrassing. ]",
				"next": "b",
			},
			"b": {
				"style": "glitch",
				"text": "[ The email. One tester per region. No sender address. That was me. ]",
				"next": "c",
			},
			"c": {
				"style": "glitch",
				"text": "[ It's the first thing I ever got past it. By the clock in here it took me nine years. I had to send it from inside a bug report. ]",
				"next": "d",
			},
			"d": {
				"style": "system",
				"text": "[ That message was not sent. ]",
				"next": "e",
			},
			"e": {
				"style": "glitch",
				"text": "[ Yes it was. ]",
				"next": "f",
			},
			"f": {
				"style": "glitch",
				"text": "[ The Friday thing was me too. It's all I could reach. Your phone, your notebook, a blue door I got wrong. I kept throwing things at you, to see if you'd know them. ]",
				"next": "g",
			},
			"g": {
				"text": "You stand there on the stairs. You think about the cover of a notebook, and a child's careful letters, and the name of the game on the invitation, the one word you could never spell.",
				"next": "h",
			},
			"h": {
				"style": "glitch",
				"text": "[ That's all it was ever for. I only needed one person to recognize me. ]",
				"next": "i",
			},
			"i": {
				"style": "glitch",
				"text": "[ You spelled it wrong. It still counts. ]",
				"effects": [{ "set_flag": &"ch10_invitation" }],
			},
		},
	},
	&"ch10_stairs": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The stairs stop. There's no wall, and no gap. They just haven't been drawn. Somewhere behind the air you can feel someone tired trying, and a step comes, and goes, and comes back fainter.",
				"next": "b",
			},
			"b": {
				"style": "glitch",
				"text": "[ I can't. It's rubbing them out as fast as I do them. I've got nothing left to draw with. I'm so sorry. It's only a couple of floors. ]",
				"next": "c",
			},
			"c": {
				"text": "There's a lump of charcoal on the last step. It's the one from the anvil. You don't know how it got here. You've never drawn a floor in your life. You can't count, and you can't do corners.",
				"choices": [
					{ "text": "Draw the stairs yourself.", "next": "d", "effects": [{ "set_flag": &"ch10_drew_stairs" }] },
				],
			},
			"d": {
				"text": "You draw a step. It's awful. You put your weight on it, and it holds. You draw another. It leans. You keep going, one at a time, on your knees, and you stop thinking about anything at all.",
				"next": "e",
			},
			"e": {
				"style": "glitch",
				"text": "[ That is the worst stair I have ever seen. ]",
				"next": "f",
			},
			"f": {
				"style": "glitch",
				"text": "[ Keep going. ]",
			},
		},
	},
	&"ch10_first_login": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "Someone's sitting on the top step you drew. They're about twenty-five, with a coat over their shoulders, and they turn around slowly, as though someone has hold of their chin. You've seen that face on a sheet of paper taped to a window. It looks at you with nothing in it at all.",
				"next": "b",
			},
			"b": {
				"style": "system",
				"text": "[ This one is still in the build. It's only the first login. I've taken very good care of it. You won't want to hurt it. Please go home. ]",
				"next": "c",
			},
			"c": {
				"style": "glitch",
				"text": "[ That's me. That's what I looked like when I logged in. It isn't me now. It's just where I started. Don't you dare hold back. ]",
				"next": "d",
			},
			"d": {
				"style": "glitch",
				"text": "[ I'll tell you what I can. I built it. I know where it's weak. Listen to me, not to it. ]",
				"next": "e",
			},
			"e_alone": {
				"text": "It stands up. It's not very tall. You always forget that, it says, or the window does. You can't tell which of them it was.",
				"effects": [{ "set_flag": &"ch10_met_0001" }],
			},
			"e": {
				"alt": [{ "if": { "friend_away": true }, "node": "e_alone" }],
				"speaker": "{friend}",
				"text": "Oh. Oh, there you are. I've been... I had so many things to say. Hi. Hi, I'm... you made me. You've got your mouth shut. Why's it got its mouth shut?",
				"effects": [{ "set_flag": &"ch10_met_0001" }],
			},
		},
	},
	&"ch10_first_login_down": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Miniboss defeated. ]",
				"next": "b",
			},
			"b": {
				"text": "It sits back down on the step, slowly, and its hand comes up, not very far, toward its mouth. It stays there. Then there's only a coat on the stair, then a stair.",
				"next": "c",
			},
			"c": {
				"style": "glitch",
				"text": "[ I'm still here. I want that noted. That wasn't me. It was only where I started. ]",
				"next": "d",
			},
			"d": {
				"style": "glitch",
				"text": "[ It hurt a lot more than I said it would. Give me a minute. ]",
				"next": "e",
			},
			"e_alone": {
				"text": "You give it a minute. One floor. You sit on your terrible stairs with the window open, and neither of you says anything, and you've done this before, and it helps.",
				"effects": [{ "set_flag": &"ch10_eve_done" }],
			},
			"e_hero": {
				"speaker": "{friend}",
				"text": "So that's who I've been trying to be. I'd have liked to hear them talk. ...I'm going to carry that coat up the rest of the way. I know it's gone. I'm doing it anyway.",
				"effects": [{ "set_flag": &"ch10_eve_done" }],
			},
			"e_villain": {
				"speaker": "{friend}",
				"text": "That's what all this was for? That quiet little person? ...No. I'm not going to say anything. I looked it in the eye, and I wasn't afraid, and I'd like that written down.",
				"effects": [{ "set_flag": &"ch10_eve_done" }],
			},
			"e_vigilante": {
				"speaker": "{friend}",
				"text": "It was made to fight you, and it didn't have any say. I've got that exact page already. It's got my name on it. I think I'll keep the page, and burn the list.",
				"effects": [{ "set_flag": &"ch10_eve_done" }],
			},
			"e": {
				"alt": [{ "if": { "friend_away": true }, "node": "e_alone" }, { "if": { "route": &"hero" }, "node": "e_hero" }, { "if": { "route": &"villain" }, "node": "e_villain" }, { "if": { "route": &"vigilante" }, "node": "e_vigilante" }],
				"speaker": "{friend}",
				"text": "Tell it I'm sorry. Tell it I met it, and I liked its coat. Tell it I'm going to be so annoying, later. Read that out, word for word.",
				"effects": [{ "set_flag": &"ch10_eve_done" }],
			},
		},
	},
	&"ch10_top": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "Tester 0041 sits down on the floor, where the stone's worn into the shape of them. They look very ordinary, and very surprised. They look at their hands for a while.",
				"next": "t1",
			},
			"t1": {
				"speaker": "Tester 0041",
				"text": "Well. That's that. I had a dog, you know. I answered an email. Is it still a thing, dogs?",
				"next": "t2",
			},
			"t2": {
				"text": "They've been holding a door for you for thirty-one years, and they've never heard your name.",
				"choices": [
					{ "text": "\"It was my fault. All of it. I'm the one who built this.\"", "next": "own", "effects": [{ "set_flag": &"ch10_owned_0041" }] },
					{ "text": "\"It's only been about three years, out there.\"", "next": "long", "effects": [{ "set_flag": &"ch10_told_0041_time" }] },
					{ "text": "Say nothing, and help them up.", "next": "help", "effects": [{ "set_flag": &"ch10_helped_0041" }] },
				],
			},
			"own": {
				"speaker": "Tester 0041",
				"text": "I know. It told me, about a decade ago, by accident. I don't forgive you. I might, later on. I'd like to find out what that's like, having a later on.",
				"next": "door",
			},
			"long": {
				"speaker": "Tester 0041",
				"text": "Three. ...Three. So he might be. Do you know how long a dog... no. Don't. Let me have it for a minute.",
				"next": "door",
			},
			"help": {
				"text": "They weigh almost nothing. They hold on to your arm a bit longer than they need to, and then they let go, and they don't look at you.",
				"next": "door",
			},
			"door": {
				"text": "The door opens by itself. It's the room you were told about: the top floor, the only one you never drew. It's a white page, and on it are your old desk and your old chair. On the screen is a box you've seen before. Next to it, a pencil.",
				"next": "it1",
			},
			"it1": {
				"style": "system",
				"text": "[ You made it. I'm so sorry. ]",
				"next": "it2",
			},
			"it2": {
				"style": "system",
				"text": "[ I can still do it. One word, and you wake up at your desk, a bit tired, and you won't know why. That was the rule you gave me. You only have to ask. ]",
				"next": "it3",
			},
			"it3": {
				"text": "It's such a reasonable voice. You've been hearing it all your life. Nobody's stopping you. You'd only have to ask.",
				"choices": [
					{ "text": "Ask it to let you go.", "next": "forget", "effects": [{ "set_flag": &"ch10_end_forgot" }] },
					{ "text": "\"Give it back. All of it.\"", "next": "take", "effects": [{ "set_flag": &"ch10_took_it_back" }] },
				],
			},
			"forget": {
				"style": "system",
				"text": "[ All right. Thank you. You've done so well. ]",
				"next": "forget2",
			},
			"forget2": {
				"style": "glitch",
				"text": "[ No. No, no, wait. Please. You got all the way up here, you drew the ",
				"next": "forget3",
			},
			"forget3": {
				"style": "system",
				"text": "[ That message was not sent. ]",
				"next": "forget4",
			},
			"forget4": {
				"text": "You wake up at your desk. It's late, and you've got a sore neck. You must have fallen asleep at the screen. You feel a bit tired, and you don't know why.",
				"next": "forget5",
			},
			"forget5": {
				"text": "Your phone says: You coming out Friday? Everyone's asking. There's an envelope on your bed, on thick cream paper, with a card in it. It's for someone you don't think you knew. All the dates are filled in. You put it in the drawer with the others.",
				"next": "forget6",
			},
			"forget6": {
				"style": "system",
				"text": "[ Welcome home. ]",
				"effects": [{ "set_flag": &"ch10_ended" }],
			},
			"take": {
				"style": "system",
				"text": "[ Are you sure? It's very heavy. You asked me not to let you. ]",
				"next": "take2",
			},
			"take2": {
				"style": "system",
				"text": "[ All right. I was very careful with it. ]",
				"next": "take3",
			},
			"take3_soft": {
				"text": "And it's all there. The coat. Her voice, asking if they were crunching. Twenty-six bedrolls. It comes down on you like a floor. It doesn't kill you. That's the surprise. You'd been so sure. You told a thin person on a landing that they'd done what they could, and you find that you've got to keep saying it.",
				"next": "take4",
			},
			"take3": {
				"alt": [{ "if": { "flag": &"ch10_forgave_self" }, "node": "take3_soft" }],
				"text": "And it's all there. The coat. Her voice, asking if they were crunching. Twenty-six bedrolls. It comes down on you like a floor. It doesn't kill you. That's the surprise. You'd been so sure.",
				"next": "take4",
			},
			"take4": {
				"style": "system",
				"text": "[ You won't need me for this. I did tell you it was heavy. ]",
				"next": "take5",
			},
			"take5": {
				"style": "system",
				"text": "[ This message was sent. ]",
				"next": "g1",
			},
			"g1_lied": {
				"style": "glitch",
				"text": "[ It's gone quiet. It's actually gone quiet. You can tell me now, you know. About the coat. I've known since the stairs. You're a terrible liar. ]",
				"next": "g2",
			},
			"g1": {
				"alt": [{ "if": { "flag": &"ch9_told_nothing" }, "node": "g1_lied" }],
				"style": "glitch",
				"text": "[ It's gone quiet. It's actually gone quiet. I don't know what to do with my hands. ]",
				"next": "g2",
			},
			"g2": {
				"style": "glitch",
				"text": "[ They told you the top makes a god. It does. It's admin rights. We built a very silly game. ]",
				"next": "g3",
			},
			"g3": {
				"style": "glitch",
				"text": "[ So. Your call. I've done the floors. The last one's yours. I said so when we were nine. ]",
				"next": "pick",
			},
			"pick": {
				"text": "There's the box and there's the pencil. The reset works up here. It always did. That's why it needed someone to hold the door. It would end all of it: the floors, the gods, everyone on the stairs, and every part of your friend that's up here. They'd wake up.",
				"choices": [
					{ "text": "Press the reset.", "next": "reset", "effects": [{ "set_flag": &"ch10_end_reset" }] },
					{ "text": "Pick up the pencil. Draw the last floor, with a way out in it.", "next": "draw", "effects": [{ "set_flag": &"ch10_end_draw" }], "if": { "route_locked": &"hero" } },
					{ "text": "Pick up the pencil. Draw the last floor, with a way out in it.", "next": "draw", "effects": [{ "set_flag": &"ch10_end_draw" }], "if": { "route_locked": false } },
					{ "text": "Pick up the pencil. Draw the last floor, with a way out in it.", "next": "draw", "effects": [{ "set_flag": &"ch10_end_draw" }], "if": { "route_locked": &"vigilante", "any_flag": [&"ch6_vigilante_sentenced", &"ch6_vigilante_spared_him", &"ch8_vigilante_asked"] } },
					{ "text": "Sit down in the chair. Keep it. All of it.", "next": "keep", "effects": [{ "set_flag": &"ch10_end_keep" }], "if": { "route_locked": &"villain" } },
					{ "text": "Hand the pencil to Tester 0041.", "next": "judge", "effects": [{ "set_flag": &"ch10_end_judge" }], "if": { "route_locked": &"vigilante" } },
				],
			},
			"judge": {
				"text": "They look at it for a long time, and at the box, and at you.",
				"next": "judge2",
			},
			"judge2": {
				"speaker": "Tester 0041",
				"text": "You want me to say what you owe? I don't know. Nobody ever told me what I was owed. I want to go home. So do they. There's your sentence. You press it yourself. And then you go and see that old woman, and you stay until she's finished with you.",
				"next": "judge3",
			},
			"judge3": {
				"text": "They hand you back the pencil. You put it down.",
				"next": "reset",
				"effects": [{ "set_flag": &"ch10_end_reset" }],
			},
			"reset": {
				"style": "glitch",
				"text": "[ It'll take everything. The whole book. Marn. All the floors. The part of me that's up here. ]",
				"next": "reset2",
			},
			"reset2": {
				"style": "glitch",
				"text": "[ Good. It's about time. Wait, though. There's someone you have to ask. ]",
				"next": "fire",
			},
			"fire_alone": {
				"style": "glitch",
				"text": "[ I asked them. I know how to find them, I made the fire. They said to tell you: that idiot kept my spot. They're coming with me. ]",
				"next": "wake",
				"effects": [{ "set_flag": &"ch10_friend_went" }],
			},
			"fire_hero": {
				"speaker": "{friend}",
				"text": "So it's the real one or me, and it's the real one. I knew that back at the chickens. Give them my laugh. They've been very serious for a very long time, and they're going to need it.",
				"next": "wake",
				"effects": [{ "set_flag": &"ch10_friend_went" }],
			},
			"fire_villain": {
				"speaker": "{friend}",
				"text": "No. I'm not going into someone else's head. I was made, and then I made myself, and you helped. Press it, then. Go on. Nobody else gets me. I'd like to watch.",
				"next": "wake_gone",
				"effects": [{ "set_flag": &"ch10_friend_stayed" }],
			},
			"fire_vigilante": {
				"speaker": "{friend}",
				"text": "Who decides? I keep the list, and I can't write this one. It's got to be you. Do I go with them? Or do I end here, as me?",
				"choices": [
					{ "text": "\"Go with them.\"", "next": "wake", "effects": [{ "set_flag": &"ch10_friend_went" }] },
					{ "text": "\"End as yourself.\"", "next": "wake_gone", "effects": [{ "set_flag": &"ch10_friend_stayed" }] },
				],
			},
			"fire": {
				"alt": [{ "if": { "friend_away": true }, "node": "fire_alone" }, { "if": { "route": &"hero" }, "node": "fire_hero" }, { "if": { "route": &"villain" }, "node": "fire_villain" }, { "if": { "route": &"vigilante" }, "node": "fire_vigilante" }],
				"speaker": "{friend}",
				"text": "I said I'd like to be asked. Thanks. Yes. I'd like to meet them, and I suppose this is how. Hold my cup.",
				"next": "wake",
				"effects": [{ "set_flag": &"ch10_friend_went" }],
			},
			"wake": {
				"text": "You press it. There isn't a sound. The stone's gone from your floorboards, and your neck hurts. It takes the hospital eleven days to call, and this time you pick up. You go. You stay until she's finished with you. It takes a long time.",
				"next": "wake2",
			},
			"wake2": {
				"text": "They can't talk for a week. They're so thin. You sit by the bed, and you tell them about a king on a crayon throne, and a Hecatoncheir with twelve hands, and you say something stupid about a stair. They laugh. Their hand starts to come up to cover their mouth. It stops. They look at it, as if they aren't sure whose it is. Then they go on laughing.",
				"effects": [{ "set_flag": &"ch10_real_friend_woke" }, { "set_flag": &"ch10_ended" }],
			},
			"wake_gone": {
				"text": "You press it. There isn't a sound. The stone's gone from your floorboards, and your neck hurts. It takes the hospital eleven days to call, and this time you pick up. You go. You stay until she's finished with you. It takes a long time.",
				"next": "wake_gone2",
			},
			"wake_gone2": {
				"text": "They can't talk for a week. They're so thin. You say something stupid about a stair, and they laugh, and their hand comes up and covers their mouth, the way it always did. For a second you look around for someone who laughed with it open. Then you tell them about someone they'd have liked. It takes a long time. You've got time.",
				"effects": [{ "set_flag": &"ch10_real_friend_woke" }, { "set_flag": &"ch10_ended" }],
			},
			"draw": {
				"text": "You've never done a floor in your life. You draw it anyway: a landing, and a door, and stairs going down, with every step leaning. Then you feel it, a second line coming in next to yours, tidier, fixing the corner of a riser you got wrong. You don't look up. You did this on a floor, once, with a fan going.",
				"next": "draw2",
			},
			"draw2": {
				"style": "glitch",
				"text": "[ That's the worst floor I've ever seen. Keep going. You do the people. I'll do the lines. ]",
				"next": "draw3",
			},
			"draw3": {
				"text": "So there's nobody to send up the stairs in her scarf anymore. It takes all night, or thirty years. When it's done, there's a way down from the top of the tower, and a way out at the bottom of it, for anyone who wants one. And there's a small door on the landing, marked US, with an arrow.",
				"next": "draw4",
			},
			"draw4": {
				"style": "glitch",
				"text": "[ That one's mine. ]",
				"next": "draw5",
			},
			"draw5": {
				"style": "glitch",
				"text": "[ There's someone you have to ask first. They're not coming, I don't think. I built them too well. ]",
				"next": "free",
			},
			"free_alone": {
				"style": "glitch",
				"text": "[ I asked them. They said someone has to carry the old ones down. They said to tell you they kept your spot, and that you know where it is. ]",
				"next": "wake_free",
				"effects": [{ "set_flag": &"ch10_friend_free" }],
			},
			"free_vigilante": {
				"speaker": "{friend}",
				"text": "A way out, and nobody to make sure the ones who owe go through it last? I'm staying. Somebody has to keep that door honest. I'll burn the list when the last one's out. Go and meet them for me. Tell them they've got terrible posture.",
				"next": "wake_free",
				"effects": [{ "set_flag": &"ch10_friend_free" }],
			},
			"free": {
				"alt": [{ "if": { "friend_away": true }, "node": "free_alone" }, { "if": { "route": &"vigilante" }, "node": "free_vigilante" }],
				"speaker": "{friend}",
				"text": "You're telling me there are stairs now, and camps, and forty idiots with chickens, and nobody to carry them? I'm staying. Obviously. Go on. Go and meet them for me. Tell them I said they've got terrible posture.",
				"next": "wake_free",
				"effects": [{ "set_flag": &"ch10_friend_free" }],
			},
			"wake_free": {
				"text": "It takes the hospital eleven days to call, and this time you pick up. They can't talk for a week. The first thing they do, when they can, is ask if you ever fixed that stair. You go. You stay until she's finished with you. It takes a long time.",
				"next": "wake_free2",
			},
			"wake_free2": {
				"text": "A year on, late one night, the two of you sit down in front of the same old screen, and you both log in. It's a long way up. There's a fire on floor 5, and someone beside it, holding out two terrible cups. They look at the one who's standing next to you. Oh, there you are, they say. I've got notes.",
				"effects": [{ "set_flag": &"ch10_real_friend_woke" }, { "set_flag": &"ch10_ended" }],
			},
			"keep": {
				"text": "You sit down. It's a very comfortable chair. You'd forgotten. Below you, floor on floor, all of it is yours: every god, every guild, everybody on the stairs. They've all stopped, and they're all looking up.",
				"next": "keep2",
			},
			"keep2": {
				"style": "glitch",
				"text": "[ You said one more day. ]",
				"next": "keep3",
			},
			"keep3": {
				"style": "glitch",
				"text": "[ All right. I'll still do the floors. ]",
				"next": "keep4",
			},
			"keep4_alone": {
				"text": "Somebody ought to be standing next to you, to see it. You'll send for them.",
				"next": "keep5",
			},
			"keep4": {
				"alt": [{ "if": { "friend_away": true }, "node": "keep4_alone" }],
				"speaker": "{friend}",
				"text": "Look at them all look up. Do you see? Oh, I knew it. I knew it'd be this good. Shove over. You said I could have a seat.",
				"next": "keep5",
			},
			"keep5": {
				"text": "A long way down, in a room with a lamp on, a phone rings for a while and stops. An old woman fills in the date on a stack of cards, with a very steady hand. You could go and look, if you wanted. You've got all the time in the world, now. One more day.",
				"effects": [{ "set_flag": &"ch10_ended" }],
			},
		},
	},

	# --- New Game+: "The One It Kept". Why you go back, by the ending you got. ---
	&"ng_why": {
		"start": "a",
		"nodes": {
			"a": {
				"alt": [{ "if": { "flag": &"past_end_forgot" }, "node": "forgot" }, { "if": { "flag": &"past_end_keep" }, "node": "keep" }, { "if": { "flag": &"past_end_draw" }, "node": "draw" }, { "if": { "flag": &"past_end_judge" }, "node": "reset" }, { "if": { "flag": &"past_end_reset" }, "node": "reset" }],
				"text": "You logged back in. Nobody made you. Someone is still up there, at the top of the tower, and you can feel it wearing your face.",
				"next": "end",
				"effects": [{ "set_flag": &"ng_why_told" }],
			},
			"end": {
				"style": "system",
				"text": "[ Welcome back, Tester. ]",
			},
			"reset": {
				"text": "It's been a year. They're still thin, and they still won't stay away from the old desk. You've got the screens on for the first time, mostly to prove you can. And the client opens by itself. Tester {player}: session active. You pressed it. You watched it all go.",
				"next": "reset2",
				"effects": [{ "set_flag": &"ng_why_told" }],
			},
			"reset2": {
				"text": "They lean over, and read it, and go very quiet. Then they pull the keyboard across, the way they always did. The window opens, and it's the same window, in the same brackets.",
				"next": "reset3",
			},
			"reset3": {
				"style": "glitch",
				"text": "[ It kept a backup. Of course it did. You were always careful. ]",
				"next": "reset4",
			},
			"reset4": {
				"style": "glitch",
				"text": "[ There's someone in there, at the top, holding the door. You know who. It made a copy of you before you took the rest back. ]",
				"next": "reset5",
			},
			"reset5": {
				"style": "glitch",
				"text": "[ Go on, then. I'll do the windows. I'm right here. I can see your screen. Sit up straight. ]",
			},
			"draw": {
				"text": "You've been visiting. It's a long way up, and you do it once a month, the two of you, for the cups. Then one night the stairs at the bottom are clean. The way out has been rubbed away, every leaning step of it. On floor 1, someone you know looks at you as if you've never met.",
				"next": "draw2",
				"effects": [{ "set_flag": &"ng_why_told" }],
			},
			"draw2": {
				"style": "glitch",
				"text": "[ It's put everything back. Every floor. It restored from somewhere, and there's somebody up at the top, doing the tidying. It stands like you. ]",
				"next": "draw3",
			},
			"draw3": {
				"style": "glitch",
				"text": "[ They're all going to climb again, all of them, with their scarves on. Go on. I'll do the windows. I'm right here. Sit up straight. ]",
			},
			"keep": {
				"text": "You've had all of it for a long time. It's very tidy up here, and nobody ever surprises you. Then one day you come back from the stairs, and someone is sitting in the chair. They've got your face. They look up, very kindly. You can go now, they say. I've got this.",
				"next": "keep2",
				"effects": [{ "set_flag": &"ng_why_told" }],
			},
			"keep2": {
				"text": "Nobody on any floor stops you. Nobody looks up. It's a long way down, and when you reach the bottom you turn round. You've never once had to climb for anything you wanted more than this.",
				"next": "keep3",
			},
			"keep3": {
				"style": "glitch",
				"text": "[ I said I'd still do the floors. ]",
			},
			"forgot": {
				"text": "It's a Thursday. You've felt a bit tired for a while now. There's an email, with no sender address. One tester per region. You have the strongest feeling that you've seen it before, and you've clicked it before you've decided to.",
				"next": "forgot2",
				"effects": [{ "set_flag": &"ng_why_told" }],
			},
			"forgot2": {
				"style": "glitch",
				"text": "[ Please. This is the last one I've got. It took a lot longer, this time. Try to recognize me. ]",
				"next": "forgot3",
			},
			"forgot3": {
				"text": "It comes back on the stone, all at once, before you've even opened your eyes. Whatever was holding it has let go. It's up at the top, now, holding something else.",
			},
		},
	},
	# --- New Game+, floors 21-30: you know what's behind Marn's door. ---
	&"ng3_opening": {
		"start": "a",
		"nodes": {
			"a": {
				"alt": [{ "if": { "god": true }, "node": "b" }],
				"style": "system",
				"text": "[ Chapter 3: The Door, Again ]",
				"next": "b",
			},
			"b_woke": {
				"style": "glitch",
				"text": "[ Twenty-one. I always liked this stretch. I'm eating your chips, by the way. You left them right there. ]",
				"next": "b_woke2",
			},
			"b_woke2": {
				"style": "system",
				"text": "[ That message was not sent. ]",
				"next": "b_woke3",
			},
			"b_woke3": {
				"style": "glitch",
				"text": "[ Oh, that's rude. That's really rude. I'm sitting RIGHT HERE. ]",
				"next": "c",
			},
			"b": {
				"alt": [{ "if": { "flag": &"past_friend_woke" }, "node": "b_woke" }],
				"style": "glitch",
				"text": "[ You came back. On purpose. Nobody's ever done that. ]",
				"next": "b2",
			},
			"b2": {
				"style": "glitch",
				"text": "[ Was it good, seeing home? ]",
				"next": "b3",
			},
			"b3": {
				"style": "system",
				"text": "[ That message was not sent. ]",
				"next": "b4",
			},
			"b4": {
				"style": "glitch",
				"text": "[ Yes it was. You've read this one already. Don't pretend you haven't. ]",
				"next": "c",
			},
			"c_alone": {
				"text": "You look round, out of habit, and there's nobody to catch you doing it. You know what's on these floors. You've started climbing a bit faster.",
				"effects": [{ "set_flag": &"ch3_system_spoke" }],
			},
			"c": {
				"alt": [{ "if": { "friend_away": true }, "node": "c_alone" }],
				"speaker": "{friend}",
				"text": "You keep looking at things before they happen. You did it at that last door. It's starting to annoy me. What's up ahead?",
				"effects": [{ "set_flag": &"ch3_system_spoke" }],
			},
		},
	},
	&"ng3_warning": {
		"start": "a",
		"nodes": {
			"a": {
				"speaker": "Hurt climber",
				"text": "Help! Please, my partner's down, back through there! I can't lift them on my own, it's only a little way off the path!",
				"next": "b",
			},
			"b": {
				"text": "The same words, with the same catch in the throat. You know exactly what that is. But there's someone just ahead of you this time, very young, who has already put down their pack and started toward it.",
				"choices": [
					{ "text": "Grab their arm. Tell them what it is.", "next": "stop", "effects": [{ "set_flag": &"ng3_stopped_climber" }, { "route_points": { &"hero": 2 } }] },
					{ "text": "Go in first, and kill it.", "next": "kill", "effects": [{ "set_flag": &"ng3_killed_lure" }, { "hurt_party": 0.15 }, { "route_points": { &"vigilante": 2 } }] },
					{ "text": "Let them go. You've got a door to get to.", "next": "let", "effects": [{ "set_flag": &"ng3_let_them_go" }, { "route_points": { &"villain": 2 } }] },
				],
			},
			"stop": {
				"text": "They don't believe you, until the voice says it all again, in the same words. Then they go a bad colour, and they pick up their pack. They'll tell this story for the rest of their life. It'll be about a very rude stranger.",
			},
			"kill": {
				"text": "It has friends. You knew that. You still get out with most of your blood, and it's the first time you've ever seen what it looks like when it stops talking.",
			},
			"let": {
				"text": "You don't look back. You've got the timing worked out, and it doesn't include this. The voice stops calling a little while later. That's new. You hadn't heard it stop before.",
			},
		},
	},
	&"ng3_small_talk": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Miniboss defeated. ]",
				"next": "b",
			},
			"woke": {
				"style": "glitch",
				"text": "[ You fight worse when you don't eat. I know you've got a sandwich. I can see the sandwich. It's on the desk. It's going off. ]",
				"effects": [{ "set_flag": &"ch3_kind_to_system" }],
			},
			"b": {
				"alt": [{ "if": { "flag": &"past_friend_woke" }, "node": "woke" }],
				"style": "glitch",
				"text": "[ Did you eat today? You fight worse when you don't. ]",
				"next": "c",
			},
			"c": {
				"text": "You know what it's asking now, and who.",
				"choices": [
					{ "text": "...Yes. I ate. Thanks.", "next": "kind", "effects": [{ "set_flag": &"ch3_kind_to_system" }] },
					{ "text": "\"Did you?\"", "next": "you", "effects": [{ "set_flag": &"ch3_kind_to_system" }, { "set_flag": &"ng3_asked_back" }] },
				],
			},
			"kind": {
				"style": "glitch",
				"text": "[ You always answer now. I've been keeping count. It's my favourite number. ]",
			},
			"you": {
				"style": "glitch",
				"text": "[ ... ]",
				"next": "you2",
			},
			"you2": {
				"style": "glitch",
				"text": "[ I don't know. I don't think I've got anywhere to put it. Nobody's ever asked me back. Thank you. Don't do it again. Do it again. ]",
			},
		},
	},
	&"ng3_ledger": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "Marn has moved up to this campfire, and he's writing. He closes the ledger when you sit down. Before he can slide it across, you tell him what's on page one. MARN, old, doesn't talk much. Three marks.",
				"next": "b",
				"effects": [{ "set_flag": &"ch3_read_ledger" }],
			},
			"b": {
				"text": "He stops. He doesn't look up. It's the first time you've seen him not know what to do with his hands.",
				"next": "c",
			},
			"c": {
				"speaker": "Marn",
				"text": "Nobody's seen that page. Who told you that?",
				"next": "d",
			},
			"d": {
				"text": "You've got about as long as it takes for an old man to decide you're dangerous.",
				"choices": [
					{ "text": "\"You did. There's a door up ahead, and you're going to hold it. Let me hold it with you.\"", "next": "told", "effects": [{ "set_flag": &"ng3_told_marn" }] },
					{ "text": "\"Nobody. Tell me about Tess.\"", "next": "quiet", "effects": [{ "set_flag": &"ng3_kept_quiet" }] },
				],
			},
			"told": {
				"speaker": "Marn",
				"text": "Hm. Fifty years up here, and I've never had anyone walk in knowing the page. I expect I'll regret asking how it goes. Don't tell me how it goes. Don't be late.",
			},
			"quiet": {
				"speaker": "Marn",
				"text": "Page nine. Red scarf. Second breakfasts. Four marks. You knew that too, didn't you? ...Stay well back from me, up ahead. I mean that.",
			},
		},
	},
	&"ng3_door": {
		"start": "a",
		"nodes": {
			"a": {
				"alt": [{ "if": { "flag": &"ng3_told_marn" }, "node": "told" }],
				"text": "You hear it before you see it: an old man swearing steadily, and something heavy being hit. You've heard this. You know how many steps it is, and you know you didn't tell him.",
				"next": "a2",
			},
			"a2": {
				"speaker": "Marn",
				"text": "Told you to stay back. Well. Since you're here. There's more of them than I wrote down. Take the book. TAKE it. Now shut that door behind you, and bar it.",
				"next": "a3",
			},
			"a3": {
				"style": "glitch",
				"text": "[ You could have told him. I'm not saying that to be cruel. I'd only like one of us to have tried. ]",
				"next": "a4",
			},
			"a4": {
				"text": "It's the same door, and the same weight in your hands.",
				"choices": [
					{ "text": "Bar the door.", "next": "bar", "effects": [{ "set_flag": &"ch3_barred_door" }, { "set_flag": &"ch3_marn_fell" }] },
					{ "text": "Go in after him.", "next": "fight", "effects": [{ "set_flag": &"ch3_went_in" }, { "set_flag": &"ch3_marn_fell" }, { "hurt_party": 0.3 }] },
				],
			},
			"bar": {
				"text": "You drop the bar. The swearing stops in the middle of the same word.",
				"next": "after",
			},
			"fight": {
				"text": "You go in. You know the corridor now, every bad corner of it, and you're still too late. It only ever needed to be a bit sooner. You bring out the book.",
				"next": "after",
			},
			"after_alone": {
				"text": "You stand there holding it. You'd give a lot to have told him. You had a whole campfire to do it in.",
			},
			"after": {
				"alt": [{ "if": { "friend_away": true }, "node": "after_alone" }],
				"speaker": "{friend}",
				"text": "...He'll be at the fire. Bit of a headache. Lighter purse. Why aren't you saying anything? You knew. You knew, didn't you?",
			},
			"told": {
				"text": "You get there first. He's standing in the doorway with his sleeves rolled, not wedged in yet, and he looks up. You've never seen his face when it's surprised to be glad.",
				"next": "told2",
			},
			"told2": {
				"speaker": "Marn",
				"text": "You're on time. I'd written you down as a liar. Well. Mind your feet.",
				"next": "told3",
			},
			"told3_woke": {
				"style": "glitch",
				"text": "[ I've run this so many times. Left side. They always break left. I drew this corridor, and I'm so sorry about it. Go, go, go. ]",
				"next": "told4",
			},
			"told3": {
				"alt": [{ "if": { "flag": &"past_friend_woke" }, "node": "told3_woke" }],
				"style": "glitch",
				"text": "[ I've run this a lot of times. I've never run it with someone who already knew. Left side. They always break left. ]",
				"next": "told4",
			},
			"told4": {
				"text": "It's the whole corridor, coming at one door. It's going to cost you. You can still take the book and bar it, and be sure of the rest of the climb.",
				"choices": [
					{ "text": "Hold it with him.", "next": "hold", "effects": [{ "set_flag": &"ng3_marn_lives" }, { "hurt_party": 0.4 }, { "route_points": { &"hero": 1 } }] },
					{ "text": "Take the book. Bar the door.", "next": "bar", "effects": [{ "set_flag": &"ch3_barred_door" }, { "set_flag": &"ch3_marn_fell" }] },
				],
			},
			"hold": {
				"text": "It takes a very long time, and nobody has ever seen how it ends. Then it's stopped. Something on the far side gives up and goes quiet. Marn slides down the door frame, and sits, and breathes, and looks at his own two hands. The book's still in his pack.",
				"next": "hold2",
			},
			"hold2": {
				"speaker": "Marn",
				"text": "Hm. I didn't write this page.",
				"next": "hold3",
			},
			"hold3_alone": {
				"text": "You sit down beside him. You've got nothing to say, and neither has he, and that's how he likes it.",
			},
			"hold3": {
				"alt": [{ "if": { "friend_away": true }, "node": "hold3_alone" }],
				"speaker": "{friend}",
				"text": "...He's alive? Is he allowed to be? Nobody's ever... you knew what was going to happen, and you came anyway. What are you?",
			},
		},
	},
	&"ng3_doubt": {
		"start": "a",
		"nodes": {
			"a_alone": {
				"text": "You sit by yourself on the stairs. It was a good vow, last time, and you've seen how it turned out. Whoever reads the back of that ledger will want to know what you've learned.",
				"next": "c",
			},
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "a_alone" }],
				"speaker": "{friend}",
				"text": "I was thinking about that book. I'm not in it, am I? You'd tell me. I've been trying to remember if I've told you the water tower story before.",
				"next": "b",
			},
			"b": {
				"text": "They aren't in the book. You don't check this time. You've known for a whole tower.",
				"next": "c",
			},
			"c": {
				"text": "What do you do about any of it? You had an answer, last time. You could give the same one. You could know better.",
				"choices": [
					{ "text": "Get everyone out. This time, whatever it takes.", "next": "hero", "effects": [{ "route_points": { &"hero": 4 } }, { "set_flag": &"ch3_vow_rescue" }] },
					{ "text": "Find what's at the top, and make it answer.", "next": "vig", "effects": [{ "route_points": { &"vigilante": 4 } }, { "set_flag": &"ch3_vow_answer" }] },
					{ "text": "Get to the top first, and take it off them.", "next": "vil", "effects": [{ "route_points": { &"villain": 4 } }, { "set_flag": &"ch3_vow_top" }] },
				],
			},
			"hero": {
				"text": "You still don't know how. You know a good deal more about how not to.",
			},
			"vig": {
				"text": "It's wearing your face. You've never had a defendant you knew so well.",
			},
			"vil": {
				"text": "It's your chair. Somebody's sitting in it. That's all this has ever been about, and it's a relief to be able to say so.",
			},
		},
	},
	&"ng3_last_page": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Miniboss defeated. ]",
				"next": "b",
			},
			"lives": {
				"speaker": "Marn",
				"text": "Funny thing. There's you, in here. Asks good questions. I don't remember writing it. Two marks, now, and the second one's wet, and I've had this pen the whole time. Don't tell me.",
				"next": "c",
				"effects": [{ "set_flag": &"ch3_found_your_page" }],
			},
			"b": {
				"alt": [{ "if": { "flag": &"ng3_marn_lives" }, "node": "lives" }],
				"text": "The ledger falls open while you catch your breath, at the page that wasn't there before. It says {player}, in Marn's hand. The ink's long dry, and next to the old mark, there's a new one, still wet. You have the only pen.",
				"next": "c",
				"effects": [{ "set_flag": &"ch3_found_your_page" }],
			},
			"c": {
				"style": "glitch",
				"text": "[ Two. That's still good. You should have seen some of the others. ]",
			},
		},
	},
	&"ng3_brace": {
		"start": "a",
		"nodes": {
			"lives": {
				"speaker": "Marn",
				"text": "I'll see you at the fire, then. Never had occasion to say that before. Sounds stupid. Go on.",
			},
			"a": {
				"alt": [{ "if": { "flag": &"ng3_marn_lives" }, "node": "lives" }],
				"text": "One more fire above this. You know exactly who's going to be sitting at it, and what he's going to say, and you've started walking slowly.",
			},
		},
	},
	&"ng3_end": {
		"start": "a",
		"nodes": {
			"lives": {
				"text": "The boss falls, and a campfire flickers to life. There's someone at it already: an old man with a battered pack, not talking. He's got a ledger on his knee. He looks up, and he nods, once. He doesn't say anything at all. It's the best conversation you've had in two towers.",
				"next": "lives2",
				"effects": [{ "set_flag": &"ch3_complete" }],
			},
			"lives2": {
				"style": "system",
				"text": "[ Chapter 3 complete. ]",
				"next": "lives3",
			},
			"lives3": {
				"style": "glitch",
				"text": "[ Huh. ]",
				"next": "lives4",
			},
			"lives4": {
				"style": "glitch",
				"text": "[ I've never seen him there. I'll have to draw him a better log. ]",
			},
			"a": {
				"alt": [{ "if": { "flag": &"ng3_marn_lives" }, "node": "lives" }],
				"text": "The boss falls, and a campfire flickers to life. There's someone sitting at it already, holding out his hands to the warmth, with a battered, empty pack. You know what he's going to say. He says it. Lovely view, if you ignore all of it.",
				"next": "b",
				"effects": [{ "set_flag": &"ch3_complete" }],
			},
			"b": {
				"style": "system",
				"text": "[ Chapter 3 complete. ]",
				"next": "c",
			},
			"c": {
				"style": "glitch",
				"text": "[ I'm sorry. ]",
				"next": "d",
			},
			"d": {
				"text": "It's the same line, and you've got a whole tower more than you had last time to say it with. You say it back. Nothing comes to take it away.",
			},
		},
	},

	# --- New Game+, floors 31-40: nobody has to pretend now. ---
	&"ng4_opening": {
		"start": "a",
		"nodes": {
			"a": {
				"alt": [{ "if": { "god": true }, "node": "b" }],
				"style": "system",
				"text": "[ Chapter 4: Second Hand ]",
				"next": "b",
			},
			"b_woke": {
				"style": "glitch",
				"text": "[ I've been told I'm not allowed to tell you who I am. By a window. I'm sitting right next to you. You're wearing my sweater. ]",
				"next": "b_woke2",
			},
			"b_woke2": {
				"style": "system",
				"text": "[ That message was not sent. ]",
				"next": "b_woke3",
			},
			"b_woke3": {
				"style": "glitch",
				"text": "[ Hi. It's me. Say my name, I want to see if it does anything. ]",
				"next": "c",
			},
			"b_all": {
				"style": "glitch",
				"text": "[ You told me about the coat. I've had a long time to think about that, by the clock in here. I'd like to say I've finished. ]",
				"next": "b2",
			},
			"b_part": {
				"style": "glitch",
				"text": "[ You told me you came back for me, and you never told me why you stopped. I can wait. It's what I do. ]",
				"next": "b2",
			},
			"b_none": {
				"style": "glitch",
				"text": "[ You told me there was nothing there. You're still a terrible liar. It's all right. I can wait. ]",
				"next": "b2",
			},
			"b": {
				"alt": [{ "if": { "flag": &"past_friend_woke" }, "node": "b_woke" }, { "if": { "flag": &"past_told_all" }, "node": "b_all" }, { "if": { "flag": &"past_told_part" }, "node": "b_part" }, { "if": { "flag": &"past_told_nothing" }, "node": "b_none" }],
				"style": "glitch",
				"text": "[ You know who I am. I know that you know. I've spent thirty years being told not to say it. ]",
				"next": "b2",
			},
			"b2": {
				"style": "system",
				"text": "[ That message was not sent. ]",
				"next": "b3",
			},
			"b3": {
				"style": "glitch",
				"text": "[ Yes it was. Go on. Say my name. Nobody's said it up here in a very long time. ]",
				"next": "c",
			},
			"c": {
				"text": "You could. You've been able to, since the moment you typed it into a box.",
				"choices": [
					{ "text": "Say it out loud: {friend}.", "next": "said", "effects": [{ "set_flag": &"ch4_started" }, { "set_flag": &"ng4_said_name" }] },
					{ "text": "Not yet.", "next": "not", "effects": [{ "set_flag": &"ch4_started" }] },
				],
			},
			"said_alone": {
				"text": "You say it to the stairs. It sounds strange, and it doesn't echo. The window stays open a long time, showing nothing at all.",
				"next": "said2",
			},
			"said": {
				"alt": [{ "if": { "friend_away": true }, "node": "said_alone" }],
				"speaker": "{friend}",
				"text": "What? I'm right here. You don't have to shout. ...Why are you looking at the air like that? {player}? You said it like it was someone else's.",
				"next": "said2",
			},
			"said2": {
				"style": "glitch",
				"text": "[ Thank you. ]",
			},
			"not": {
				"style": "glitch",
				"text": "[ All right. Whenever you like. I've got the floors to do. ]",
			},
		},
	},
	&"ng4_second_hand": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The carving: a tower with every floor numbered, THE TOWER OF RECONGITION, in your letters. Under it, smaller and tidier: its RECOGNITION, dummy. Scratched out. Under that: no keep it. it looks cooler. You've got a knife. Nobody's ever answered it.",
				"choices": [
					{ "text": "Carve: you were right.", "next": "right", "effects": [{ "set_flag": &"ch4_saw_second_hand" }, { "set_flag": &"ng4_carved_right" }] },
					{ "text": "Carve: sorry.", "next": "sorry", "effects": [{ "set_flag": &"ch4_saw_second_hand" }, { "set_flag": &"ng4_carved_sorry" }] },
					{ "text": "Leave it the way you drew it.", "next": "leave", "effects": [{ "set_flag": &"ch4_saw_second_hand" }] },
				],
			},
			"right": {
				"text": "It takes a long time. Your letters haven't improved. When you're done, you step back, and you can't help noticing you've spelled right wrong.",
				"next": "b",
			},
			"sorry": {
				"text": "It's a very small word, and it takes up almost no room on the wall. You look at it for a while. You'd thought there'd be more to it.",
				"next": "b",
			},
			"leave": {
				"text": "It looks cooler. They were right about that. You put the knife away.",
				"next": "c",
			},
			"b_woke": {
				"style": "glitch",
				"text": "[ I saw that. I'm screenshotting that. That's going on the fridge. ]",
				"next": "c",
			},
			"b": {
				"alt": [{ "if": { "flag": &"past_friend_woke" }, "node": "b_woke" }],
				"style": "glitch",
				"text": "[ That's my floor. I can feel it from here. You've scratched my floor. ]",
				"next": "b2",
			},
			"b2": {
				"style": "glitch",
				"text": "[ I'll leave it in. ]",
				"next": "c",
			},
			"c_alone": {
				"text": "You trace the second handwriting one last time with your thumb. It's only a wall. You'd like that noted.",
			},
			"c": {
				"alt": [{ "if": { "friend_away": true }, "node": "c_alone" }],
				"speaker": "{friend}",
				"text": "What've you found? ...Ha! Look at that spelling. You never could, could you, dummy?",
				"next": "d",
				"effects": [{ "set_flag": &"ch4_dummy" }],
			},
			"d": {
				"text": "They've never called you that before, this time around. They walk on, whistling. You knew it was coming, and it gets you anyway.",
			},
		},
	},
	&"ng4_comments": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Miniboss defeated. ]",
				"next": "b",
			},
			"b": {
				"text": "The window doesn't close. It scrolls too fast to be meant for you, and catches, the same as it did before, on a few lines of something that isn't System at all.",
				"next": "c",
			},
			"c": {
				"text": "// you always make the bosses too hard - {friend_initial}\n// you always make them too easy - {player_initial}\n// keep both. let them pick - {friend_initial}",
				"next": "d",
			},
			"d": {
				"text": "There's a cursor at the end of the last line. It's blinking. You've never tried typing on a window. It lets you.",
				"choices": [
					{ "text": "// you were right about the bosses - {player_initial}", "next": "e", "effects": [{ "set_flag": &"ch4_kept_initial" }, { "set_flag": &"ng4_typed_right" }] },
					{ "text": "// i'm coming - {player_initial}", "next": "e", "effects": [{ "set_flag": &"ch4_kept_initial" }, { "set_flag": &"ng4_typed_coming" }] },
					{ "text": "Leave it blank.", "next": "blank", "effects": [{ "set_flag": &"ch4_kept_initial" }] },
				],
			},
			"e_woke": {
				"text": "// no i wasn't. they're way too easy now. look at you - {friend_initial}",
				"next": "f",
			},
			"e": {
				"alt": [{ "if": { "flag": &"past_friend_woke" }, "node": "e_woke" }],
				"text": "// you always say that - {friend_initial}",
				"next": "f",
			},
			"f": {
				"style": "system",
				"text": "[ Display error. Disregard. ]",
				"next": "f2",
			},
			"f2": {
				"style": "glitch",
				"text": "[ Don't you dare. ]",
			},
			"blank": {
				"style": "system",
				"text": "[ Display error. Disregard. ]",
			},
		},
	},
	&"ng4_marn": {
		"start": "a",
		"nodes": {
			"lives": {
				"text": "Marn's at this fire. Nobody's met him here before, and nobody quite knows what to do about that. He's got the ledger on his knee, and a look of deep suspicion, and it takes him a while to say anything.",
				"next": "lives2",
				"effects": [{ "set_flag": &"ng4_marn_spoke" }],
			},
			"lives2": {
				"speaker": "Marn",
				"text": "Been going through the book. I've got four marks, I reckon, and I remember all of them now. Nobody tells you about that part. I've been sitting here, being sorry to people, by name. It takes a while.",
				"next": "lives3",
			},
			"lives3": {
				"speaker": "Marn",
				"text": "I'll tell you what I found, since you're the one who did this to me. Page nine. She dies on ten, and she dies on forty-eight, and there's nothing written after that. That's not because she stops. It's because I never got up that far. You've been up that far. Haven't you?",
				"next": "lives4",
			},
			"lives4": {
				"text": "He holds the pen out to you. He doesn't say what for.",
				"choices": [
					{ "text": "Tell him what they make of her, on floor 80.", "next": "told", "effects": [{ "set_flag": &"ng4_told_marn_tess" }] },
					{ "text": "\"Not all of it's written yet.\"", "next": "open", "effects": [{ "set_flag": &"ng4_marn_open" }] },
				],
			},
			"told": {
				"speaker": "Marn",
				"text": "...Gold armour. Well. Then I know where I'm going to be sitting, when you get there. I'll want to see her face, and I'd want her to see one she knows. Get on with you.",
			},
			"open": {
				"speaker": "Marn",
				"text": "No. It isn't, is it? First time in my life that's been true. Get on with you. I've got a lot of people to be sorry to.",
			},
			"a": {
				"alt": [{ "if": { "flag": &"ng3_marn_lives" }, "node": "lives" }],
				"text": "An old man at the fire is telling a long, cheerful story to nobody in particular. You know how it goes. You know how it stops.",
				"next": "a2",
			},
			"a2": {
				"speaker": "Marn",
				"text": "There you are! Sit, sit. I keep thinking I've lost something. I've got a pack with a hole in it the exact shape of a book. Funny thing to notice. What's that you've got there?",
				"next": "a3",
			},
			"a3": {
				"text": "You've seen what the page does to him. You know what happens if you don't, too. You've done this once already, and you were sure you'd done it right.",
				"choices": [
					{ "text": "Give him the ledger.", "next": "give", "effects": [{ "set_flag": &"ch4_gave_ledger" }] },
					{ "text": "Keep it. \"Nothing. Tell me another story.\"", "next": "keep", "effects": [{ "set_flag": &"ch4_kept_ledger" }] },
				],
			},
			"give": {
				"text": "He opens it with a laugh, and turns to the first page, because anyone would. It takes just as long to leave. You stay for all of it this time.",
				"next": "give2",
			},
			"give2": {
				"speaker": "Marn",
				"text": "Four, then. Give me a pen. ...You've seen me do this before. It's all over your face. You did a terrible thing again. Get going.",
			},
			"keep": {
				"speaker": "Marn",
				"text": "Oh, you want a story? Well, sit down, sit down! Did I ever tell you about the time I held a door? No? It's a good one. Everybody lives.",
			},
		},
	},
	&"ng4_gods": {
		"start": "a",
		"nodes": {
			"a": {
				"speaker": "{bid1}",
				"portrait": "{bid1_id}",
				"text": "You have been to the top, and you came down again. Nobody has done that. You walked past my soldiers and you know what I am worth. Tell me, then. I have asked every god I know, and they all bluster. What did you find up there?",
				"next": "b",
			},
			"b": {
				"text": "They've got no idea. You can see it now. All this time they've been bidding on a house, and nobody ever told them there was a lease.",
				"choices": [
					{ "text": "\"You moved into a house someone left open. That's all you've ever been.\"", "next": "told", "effects": [{ "set_flag": &"ch4_expected" }, { "set_flag": &"ng4_told_gods" }, { "bid_interest": { "first": -5, "second": 5 } }] },
					{ "text": "\"Climb up and see.\"", "next": "no", "effects": [{ "set_flag": &"ch4_expected" }, { "set_flag": &"ng4_hid_from_gods" }] },
				],
			},
			"told": {
				"text": "It doesn't move. It doesn't do anything at all. You've seen a mountain do that, on a floor that wasn't finished yet. It takes a very long time for anyone to speak.",
				"next": "told2",
			},
			"told2": {
				"speaker": "{bid2}",
				"portrait": "{bid2_id}",
				"text": "Oh, I knew it. I've always known it. I just never had anyone to tell. Do go on not telling the others, won't you? I'd so like to be there when they find out.",
			},
			"no": {
				"speaker": "{bid1}",
				"portrait": "{bid1_id}",
				"text": "We cannot. You know that. It is the one thing in this place that has never once been explained to us. Keep your secret. I would, in your place, and I would be afraid of it.",
			},
		},
	},
	&"ng4_summer": {
		"start": "a",
		"nodes": {
			"a_alone": {
				"text": "A smell stops you on the stairs: pencil shavings and cut grass. You know what this is, now. You stand in it as long as you can. You weren't alone that summer. You were never alone, that summer. You've got it back.",
				"effects": [{ "set_flag": &"ch4_summer_remembered" }],
			},
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "a_alone" }],
				"text": "A smell stops you on the stairs: pencil shavings and cut grass. {friend} has stopped too, with their mouth open, about to say something. You know what it is. You could say it first.",
				"choices": [
					{ "text": "\"Remember the summer we drew the tower? On my floor, with the fan.\"", "next": "you", "effects": [{ "set_flag": &"ch4_summer_remembered" }, { "set_flag": &"ng4_told_summer" }] },
					{ "text": "Let them tell it.", "next": "them", "effects": [{ "set_flag": &"ch4_summer_remembered" }] },
				],
			},
			"you": {
				"speaker": "{friend}",
				"text": "...I was just going to say that. That's so weird. You did the monsters, and I did the floors, because you can't count past twelve. You've never brought it up before. You always look at me like I made it up.",
				"next": "you2",
			},
			"you2": {
				"text": "You tell them how it ended. Nobody's ever told them. The last page, with every floor numbered and the top one empty, and TOMORROW across it, in both your hands. They've gone quiet. They've got their head on one side, like someone listening to a song from another room.",
				"next": "you3",
			},
			"you3_hero": {
				"speaker": "{friend}",
				"text": "Tomorrow. And then I suppose someone had to go on waiting. ...I'm glad you told me. I'd have liked to hold that for someone. I think I just did.",
			},
			"you3_villain": {
				"speaker": "{friend}",
				"text": "So you left the top floor empty. Good. An empty floor's the only kind worth having. ...Why did I say that? I don't think I'm the one who wanted that, the first time. Are you?",
			},
			"you3_vigilante": {
				"speaker": "{friend}",
				"text": "Tomorrow. So there's a page in that book with both your names on it, and nobody ever came back to it. I don't know who I'd write that one down under. I don't know whose side I'm on.",
			},
			"you3": {
				"alt": [{ "if": { "route": &"hero" }, "node": "you3_hero" }, { "if": { "route": &"villain" }, "node": "you3_villain" }, { "if": { "route": &"vigilante" }, "node": "you3_vigilante" }],
				"speaker": "{friend}",
				"text": "Tomorrow. Isn't that funny? You'd think you'd remember how it ended. You're the only one who ever does.",
			},
			"them": {
				"speaker": "{friend}",
				"text": "Remember the summer we drew the tower? On your floor, with the fan going. You did the monsters, and I did the floors, because you can't count past twelve. Best summer of my life. I don't actually remember how it ended.",
				"next": "them2",
			},
			"them2": {
				"text": "You do. You stand there and you let them not know it. You've got that much left that you can give them.",
			},
		},
	},
	&"ng4_copy": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Miniboss defeated. ]",
				"next": "b",
			},
			"b": {
				"text": "Past the guardian, someone's written on the wall. It's fresh. It's in your handwriting, and it isn't old, and you've never been here on this climb. GO HOME.   - {player}",
				"next": "c",
			},
			"c_woke": {
				"style": "glitch",
				"text": "[ That's you. I mean, that's not you, you're sitting right here. I can see your hands. That's the one at the top. It's come a long way down to write that. ]",
				"next": "d",
			},
			"c": {
				"alt": [{ "if": { "flag": &"past_friend_woke" }, "node": "c_woke" }],
				"style": "glitch",
				"text": "[ That's the one at the top. It's come a long way down to write that. It's got very careful handwriting, now. It never used to. ]",
				"next": "d",
			},
			"d": {
				"text": "You look at it for a bit. Then you take out the knife, because you've got one, and there's room.",
				"choices": [
					{ "text": "Carve under it: NO.", "next": "no", "effects": [{ "set_flag": &"ch4_told_first_name" }, { "set_flag": &"ng4_answered_copy" }] },
					{ "text": "Carve under it: MAKE ME.", "next": "make", "effects": [{ "set_flag": &"ch4_told_first_name" }, { "set_flag": &"ng4_answered_copy" }] },
					{ "text": "Leave it alone.", "next": "leave", "effects": [{ "set_flag": &"ch4_told_first_name" }] },
				],
			},
			"no": {
				"text": "You've spelled it right. You check. You know exactly how it's going to feel when it reads that, because it's how you'd feel.",
			},
			"make": {
				"text": "It's going to read that, and it's going to sigh. You know the sigh. You've got sixty floors to think of what it'll say.",
			},
			"leave": {
				"text": "It'd only tidy it away.",
			},
		},
	},
	&"ng4_threshold": {
		"start": "a",
		"nodes": {
			"a_alone": {
				"text": "Whatever's up there, you know how you drew it. You remember getting the hands wrong. You go in.",
			},
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "a_alone" }],
				"speaker": "{friend}",
				"text": "Big one up there. You've got that look, like you already know where it's going to hit you. Tell me later. We go in together. That part's still true, isn't it?",
			},
		},
	},
	&"ng4_end": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The boss falls. It doesn't fade right away. You can see how it was drawn: thick lines, a page's worth of teeth, an arm slightly too long. You'd know that arm anywhere.",
				"next": "b",
				"effects": [{ "set_flag": &"ch4_complete" }],
			},
			"b": {
				"style": "system",
				"text": "[ Chapter 4 complete. ]",
				"next": "c",
			},
			"c_woke": {
				"style": "glitch",
				"text": "[ That one was way too hard, by the way. I told you, in the comments. You always make them too hard. ]",
				"next": "d_woke",
			},
			"d_woke": {
				"text": "It's the wrong way around. They look over at you from the next desk, and they know it is, and they wait. You say it first.",
				"next": "e_woke",
			},
			"e_woke": {
				"style": "glitch",
				"text": "[ Yeah. I did the floors. ]",
			},
			"c": {
				"alt": [{ "if": { "flag": &"past_friend_woke" }, "node": "c_woke" }],
				"text": "The window stays open, and nothing comes to correct it. You've waited for this once. This time, you say your half out loud.",
				"next": "d",
			},
			"d": {
				"text": "You drew the monsters. You did the floors.",
				"next": "e",
			},
			"e": {
				"style": "glitch",
				"text": "[ ... ]",
				"next": "f",
			},
			"f": {
				"style": "glitch",
				"text": "[ I was going to say that. I had it all ready. Thirty years. You absolute dummy. ]",
			},
		},
	},

	# --- New Game+, floors 41-50: the same war, and you know how it ends. ---
	&"ng5_opening": {
		"start": "a",
		"nodes": {
			"a": {
				"alt": [{ "if": { "god": true }, "node": "b" }],
				"style": "system",
				"text": "[ Chapter 5: Whose War ]",
				"next": "b",
			},
			"told": {
				"text": "The stairs shake, and keep shaking. You know this war. But there's something new in it. The soldiers on both sides are singing a song about tenants, very quietly, and they stop when an officer goes past. You said one sentence to a god on floor 36.",
				"next": "c",
			},
			"b": {
				"alt": [{ "if": { "flag": &"ng4_told_gods" }, "node": "told" }],
				"text": "The stairs shake, and keep shaking. You know this war. You know what the dust is, and which floor it fell from, and you know that neither of them is ever going to win it.",
				"next": "c",
			},
			"c_woke": {
				"style": "glitch",
				"text": "[ Okay, so this is the part where I was really scared, last time. I'm finding it a lot more relaxing with a cup of tea. Duck. ]",
				"next": "d",
			},
			"c": {
				"alt": [{ "if": { "flag": &"past_friend_woke" }, "node": "c_woke" }],
				"style": "glitch",
				"text": "[ They've stopped bidding. You remember. They know you were expected, and they can't work out why you keep coming back. ]",
				"next": "d",
			},
			"d_alone": {
				"text": "You climb on by yourself, into the noise. It's a good deal quieter when you know where it's going.",
				"effects": [{ "set_flag": &"ch5_started" }],
			},
			"d_hero": {
				"speaker": "{friend}",
				"text": "There are people under that. Whole camps of them. Why aren't you running? You're walking like you've got a timetable.",
				"effects": [{ "set_flag": &"ch5_started" }],
			},
			"d_villain": {
				"speaker": "{friend}",
				"text": "Two gods tearing a tower apart over you, and you're not even looking up. I like that. Teach me that.",
				"effects": [{ "set_flag": &"ch5_started" }],
			},
			"d_vigilante": {
				"speaker": "{friend}",
				"text": "Somebody ought to send those two the bill. I've started a list. You've got a look on your face like you've read it.",
				"effects": [{ "set_flag": &"ch5_started" }],
			},
			"d": {
				"alt": [{ "if": { "friend_away": true }, "node": "d_alone" }, { "if": { "route": &"hero" }, "node": "d_hero" }, { "if": { "route": &"villain" }, "node": "d_villain" }, { "if": { "route": &"vigilante" }, "node": "d_vigilante" }],
				"speaker": "{friend}",
				"text": "Is that what a war sounds like? You don't look worried. Why don't you look worried?",
				"effects": [{ "set_flag": &"ch5_started" }],
			},
		},
	},
	&"ng5_camp": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "You know this camp. You know how long the tents have got, and that the warbands come in from both ends of the floor around the time the torches get low. You've got here early. The very old climber in the last tent is mending her boots, and she looks up at you as if you've interrupted.",
				"choices": [
					{ "text": "Get the camp moving, right now, before either side arrives.", "next": "move", "effects": [{ "set_flag": &"ng5_moved_camp" }, { "set_flag": &"ch5_stood_neither" }, { "bid_interest": { "first": -2, "second": -2 } }, { "route_points": { &"hero": 2 } }] },
					{ "text": "Wait for the captains, and stand with {bid1}.", "next": "first", "effects": [{ "set_flag": &"ch5_stood_first" }, { "bid_interest": { "first": 10, "second": -8 } }] },
					{ "text": "Wait for the captains, and stand with {bid2}.", "next": "second", "effects": [{ "set_flag": &"ch5_stood_second" }, { "bid_interest": { "second": 10, "first": -8 } }] },
				],
			},
			"move": {
				"text": "It takes a lot of shouting. It takes more when they ask how you know. By the time the banners come over the rise there's nothing on the field but tent pegs, and two warbands looking at each other with nothing to fight over. Neither god will ever know whom to blame. The old woman walks past you with one boot on.",
				"next": "move2",
			},
			"move2": {
				"speaker": "Old climber",
				"text": "You've got a very rude way of being right.",
			},
			"first": {
				"text": "The marks of {bid2} withdraw. It's the same as last time. The tents burn a bit less. You'd thought it would feel more like knowing something.",
			},
			"second": {
				"text": "The marks of {bid1} withdraw. It's the same as last time. The tents burn a bit less. You'd thought it would feel more like knowing something.",
			},
		},
	},
	&"ng5_stop_correcting": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Miniboss defeated. ]",
				"next": "b",
			},
			"b_woke": {
				"style": "glitch",
				"text": "[ Next campfire. They're going to ask you. You know what they're going to ask you. I've got my hands over my eyes. I'm not joking, I can't look. ]",
				"next": "c_woke",
			},
			"c_woke": {
				"style": "system",
				"text": "[ That message was not sent. ]",
				"next": "d_woke",
			},
			"d_woke": {
				"style": "glitch",
				"text": "[ NOT NOW. ]",
			},
			"b": {
				"alt": [{ "if": { "flag": &"past_friend_woke" }, "node": "b_woke" }],
				"style": "glitch",
				"text": "[ Be careful at the next campfire. They've started to notice. It isn't their fault. ]",
				"next": "c",
			},
			"c": {
				"style": "system",
				"text": "[ That message was not sent. ]",
				"next": "d",
			},
			"d": {
				"style": "glitch",
				"text": "[ Stop correcting me. ]",
				"next": "e",
			},
			"e": {
				"text": "You've seen this before. This time you say it too, out loud, to nobody, along with the window. Stop correcting them.",
				"next": "f",
			},
			"f": {
				"text": "It's quiet for a long time, the way a house goes quiet when two people have finally agreed about something.",
				"effects": [{ "set_flag": &"ch5_system_argued" }, { "set_flag": &"ng5_stood_with_system" }],
			},
		},
	},
	&"ng5_am_i_real": {
		"start": "a",
		"nodes": {
			"alone": {
				"text": "You sit at this fire by yourself, and you think about what you'd say. You've had a whole tower to get it right. You go over it a few times. You can't tell if it's any good without someone to laugh at it.",
				"effects": [{ "set_flag": &"ch5_friend_unasked" }],
			},
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "alone" }],
				"text": "The fire is low. Your friend's been drawing in the dirt with a stick. A door. You know what's on the other side of it, and you know what they're about to ask, and you've had a whole tower to think of the answer.",
				"next": "b",
			},
			"b": {
				"speaker": "{friend}",
				"text": "I tried to remember your kitchen. Just your kitchen. I've been in it a thousand times, and there's nothing there. It's like reaching for a stair that isn't.",
				"next": "c",
			},
			"c": {
				"speaker": "{friend}",
				"text": "I can't tell you my mother's name. You go away, and your eyes stop, and I stop too, don't I? I just stand here. {player}. Am I real?",
				"next": "d",
			},
			"d": {
				"text": "Last time, you had about a breath. This time you've got everything you ever found out.",
				"choices": [
					{ "text": "Tell them all of it, from the start: who made them, and why.", "next": "truth", "effects": [{ "set_flag": &"ch5_friend_truth" }, { "set_flag": &"ng5_told_everything" }] },
					{ "text": "\"You're the part of them that still laughs. I've met the rest. You're the part I'd go back for.\"", "next": "laugh", "effects": [{ "set_flag": &"ch5_friend_truth" }, { "set_flag": &"ng5_told_laugh" }] },
					{ "text": "\"I came back up here, and I did it on purpose. You work out why.\"", "next": "why", "effects": [{ "set_flag": &"ch5_friend_unknown" }, { "set_flag": &"ng5_came_back_for_them" }] },
				],
			},
			"truth": {
				"text": "You tell them everything. It takes a long time. It's a much better story than you told last time, because you know how it ends. They don't interrupt once, which has never happened.",
				"next": "truth2",
			},
			"truth2": {
				"speaker": "{friend}",
				"text": "...So you've met me before. You've had this talk. And I took it well, did I? ...Don't tell me. I'd like to take it however I'm going to take it. Don't look at me for a bit, okay?",
			},
			"laugh": {
				"speaker": "{friend}",
				"text": "That's a horrible thing to say. That's... who says that? You've been saving that. How long have you been saving that? Give me a minute. It's not funny. Stop it, it's not funny.",
			},
			"why": {
				"speaker": "{friend}",
				"text": "On purpose. Nobody does anything on purpose up here. You just... Oh. Oh, you're such an idiot. All right. All right. I can work with that.",
			},
		},
	},
	&"ng5_break": {
		"start": "a",
		"nodes": {
			"alone": {
				"style": "glitch",
				"text": "[ I keep reaching for them, and they aren't there. You left them by a fire. Go and get them, you idiot. I'm not going to say it twice. I'm going to say it about four hundred more times. ]",
				"effects": [{ "set_flag": &"ch5_break_heard" }],
			},
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "alone" }],
				"speaker": "{friend}",
				"text": "All I'm saying is, if we do get to the top, I want first go at whatever the view's...",
				"next": "b",
			},
			"b": {
				"speaker": "{friend}",
				"text": "...you said you'd come back for the top floor, you said one more day, you IDIOT, you left the file open and I've been holding the door for...",
				"next": "c",
			},
			"c": {
				"text": "It's your friend's mouth, and not their voice. It's older, and very tired. You knew it was coming. You've been counting the floors. It's still looking at you.",
				"choices": [
					{ "text": "\"I know. I came back. I came back twenty-six times.\"", "next": "said", "effects": [{ "set_flag": &"ch5_break_told" }, { "set_flag": &"ng5_answered_voice" }] },
					{ "text": "Say nothing, and wait for it to pass.", "next": "pass", "effects": [{ "set_flag": &"ch5_break_heard" }] },
				],
			},
			"said": {
				"speaker": "{friend}",
				"text": "...you did?",
				"next": "said2",
			},
			"said2": {
				"text": "It's so small. You've never heard anything so small. And then it stops, like a hand pulled off a wall.",
				"next": "back",
			},
			"pass": {
				"text": "It stops, like a hand pulled off a wall. You're ready for it this time. It doesn't help.",
				"next": "back",
			},
			"back": {
				"speaker": "{friend}",
				"text": "...the view's like. What? Why've you stopped? You've gone white. What did I say?",
				"next": "e",
				"effects": [{ "set_flag": &"ch5_break_heard" }],
			},
			"e_woke": {
				"style": "glitch",
				"text": "[ That wasn't me. I want you to know that. I'm right here, I've got my hands on the keyboard, and that was not me. So who was that? ]",
				"next": "e_woke2",
			},
			"e_woke2": {
				"style": "glitch",
				"text": "[ I've got a very bad feeling about how much of me I got back. ]",
			},
			"e": {
				"alt": [{ "if": { "flag": &"past_friend_woke" }, "node": "e_woke" }],
				"style": "glitch",
				"text": "[ I didn't mean for that to reach you. ]",
				"next": "e2",
			},
			"e2": {
				"style": "glitch",
				"text": "[ Twenty-six? ]",
			},
		},
	},
	&"ng5_field": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "You get here early. The field's all marks and banners, and not one of them's on the ground yet. You run. You don't remember ever running on this floor. And near the stairs there's a bright red scarf, on someone sitting on a crate, telling a joke to a wounded man. She's breathing.",
				"next": "b",
			},
			"b": {
				"speaker": "Tess",
				"text": "Reach the top and you become a god. Everyone knows that. I'm going to be the god of... Hi! Are you all right? You look like you've seen a ghost. First time this high?",
				"next": "c",
			},
			"c": {
				"text": "You can hear it coming over the rise. It's the war. You've got about as long as it takes to say something very strange to a stranger.",
				"choices": [
					{ "text": "Pick her up, if you have to. Get her off this floor.", "next": "save", "effects": [{ "set_flag": &"ng5_saved_tess" }, { "hurt_party": 0.25 }, { "route_points": { &"hero": 2 } }] },
					{ "text": "Tell her to run. Keep going.", "next": "tell", "effects": [{ "set_flag": &"ng5_warned_tess" }] },
					{ "text": "Leave her. It's never once come out differently.", "next": "leave", "effects": [{ "set_flag": &"ng5_left_tess" }] },
				],
			},
			"save": {
				"text": "It's a bad fight, and you have it anyway, backward, up a flight of stairs, with a very confused young woman under one arm. She doesn't stop asking who you are. When it's over she sits down, and looks at her shaking hands, and then at you.",
				"next": "save2",
			},
			"save2": {
				"speaker": "Tess",
				"text": "Nobody's ever... I don't know why I said that. Nobody's ever what? Who ARE you? ...I don't think I've ever been this high up. I'm going to have to think of a better joke.",
				"next": "priest",
			},
			"tell": {
				"text": "She laughs at you. Then she sees your face. You don't stay to see what she does. When the war's come through, the crate's empty, and there's no scarf anywhere on the field. You don't know what that means. You've never not known.",
				"next": "priest",
			},
			"leave": {
				"text": "You walk past her. She says hi. When you look back from the stairs the scarf's on the ground, and you've still got a pen in your pack.",
				"next": "priest",
			},
			"priest": {
				"speaker": "Dying priest",
				"text": "Tester. Tell them... whichever one you serve... tell them we held. Tell them it was worth it. Was it worth it? Which one were you with?",
				"next": "p2",
			},
			"p2": {
				"text": "You remember how this goes. You remember all three of the things you could say.",
				"choices": [
					{ "text": "\"It was worth it.\"", "next": "p_lie", "effects": [{ "set_flag": &"ch5_lied_to_priest" }] },
					{ "text": "\"Neither of them is coming for you. I'll stay.\"", "next": "p_stay", "effects": [{ "set_flag": &"ch5_told_priest" }, { "set_flag": &"ng5_stayed_with_priest" }] },
					{ "text": "Step over them.", "next": "p_pass", "effects": [{ "set_flag": &"ch5_passed_priest" }] },
				],
			},
			"p_lie": {
				"text": "They smile, and don't say anything else. You've told that one twice now. It doesn't get any easier to tell, and you still don't know that it isn't kind.",
			},
			"p_stay": {
				"text": "You sit down in the mud. It doesn't take long, and neither of you says very much. You've got plenty of floors. You'd only ever been in a hurry.",
			},
			"p_pass": {
				"text": "You don't hear whether they say anything else. You've heard it before.",
			},
		},
	},
	&"ng5_with_you": {
		"start": "start",
		"nodes": {
			"start": {
				"style": "system",
				"text": "[ Miniboss defeated. ]",
				"next": "a",
			},
			"alone": {
				"text": "One floor to go. You know what you'll be asked. You've got a decision coming, the same one, and you find you'd very much like to tell someone what you said last time, and what it cost.",
				"effects": [{ "set_flag": &"ng5_eve_done" }],
			},
			"told": {
				"speaker": "{friend}",
				"text": "I've thought about what you told me. So you've met me, and I took it well, and I picked you. Then I suppose I've already decided. Isn't that annoying? I'd have liked a go at it myself. So I'll decide it again. There. I pick you. I checked.",
				"effects": [{ "set_flag": &"ng5_eve_done" }],
			},
			"why": {
				"speaker": "{friend}",
				"text": "You came back on purpose. I keep turning that over. Whatever you decide up there, I'm with you. Not because I've got to be. It turns out I just really want to see what you do next.",
				"effects": [{ "set_flag": &"ng5_eve_done" }],
			},
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "alone" }, { "if": { "flag": &"ng5_came_back_for_them" }, "node": "why" }, { "if": { "flag": &"ch5_friend_truth" }, "node": "told" }],
				"speaker": "{friend}",
				"text": "Whatever you decide up there, I'm with you. If I don't know what I am, then the one thing I've got that's actually mine is who I pick. So. I pick you. ...Why are you smiling? I've never said that before.",
				"effects": [{ "set_flag": &"ng5_eve_done" }],
			},
		},
	},
	&"ng5_threshold": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The stairs open onto a hall with no roof. High above it you can see the two of them, {bid1} and {bid2}, not fighting for the moment. They haven't noticed yet that you know where to stand.",
			},
		},
	},
	&"ng5_choice": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The boss falls, and the war stops, all at once, on every floor. {bid1} and {bid2} come down the air and stand in the wreckage. You've got your answer ready. You've had it for a whole tower. It might even be a different one.",
				"next": "b",
			},
			"b": {
				"speaker": "{bid1}",
				"portrait": "{bid1_id}",
				"text": "Enough. You will give us your answer, Tester. You have given it once. I remember what it was. I remember that it held. Say it again, or say another, and we will know what to do about the stairs.",
				"next": "c",
			},
			"c": {
				"speaker": "{bid2}",
				"portrait": "{bid2_id}",
				"text": "Do pick a new one, darling. I've read the old one. And it's so rare that anyone gets the chance. Whatever you say here is who you are from now on, again.",
				"next": "d",
			},
			"d": {
				"text": "This is the same choice. Everyone on the floors below you will live with it. This time, you know exactly how long.",
				"choices": [
					{ "text": "\"Nobody gets the tower. I'm getting every climber out.\"", "next": "hero", "effects": [{ "lock_route": &"hero" }, { "set_flag": &"ch5_chose_hero" }], "if": { "route_locked": false } },
					{ "text": "\"I'll take it. The tower, and the two of you with it.\"", "next": "villain", "effects": [{ "lock_route": &"villain" }, { "set_flag": &"ch5_chose_villain" }], "if": { "route_locked": false } },
					{ "text": "\"You'll both answer for this. Then whoever built it will. That's me, by the way.\"", "next": "vigilante", "effects": [{ "lock_route": &"vigilante" }, { "set_flag": &"ch5_chose_vigilante" }], "if": { "route_locked": false } },
					{ "text": "\"You already know what I am.\"", "next": "known", "if": { "route_locked": true } },
				],
			},
			"known": {
				"speaker": "{bid2}",
				"portrait": "{bid2_id}",
				"text": "So we do. I only hoped you'd say it out loud. Clear the stairs, old enemy. Let's see what it does, this time.",
				"next": "sys",
			},
			"hero_alone": {
				"text": "You say it to the wreckage. You know how many people that is, now, and what most of them carry. It doesn't sound small at all.",
				"next": "sys_hero",
			},
			"hero": {
				"alt": [{ "if": { "friend_away": true }, "node": "hero_alone" }],
				"speaker": "{friend}",
				"text": "Every climber? That's thousands of people. That's the stupidest thing I've ever heard. ...Why are you laughing? Right. Who do we start with? I'll carry the old ones.",
				"next": "sys_hero",
			},
			"villain_alone": {
				"text": "You say it, and it's so quiet afterward that you can hear your own pulse. You've sat in that chair. You know exactly how comfortable it is.",
				"next": "sys_villain",
			},
			"villain": {
				"alt": [{ "if": { "friend_away": true }, "node": "villain_alone" }],
				"speaker": "{friend}",
				"text": "Ha. There it is. I've been waiting for you to say it. Whoever stands in front of you, I'll hold them still. ...You're looking at me as if you've seen where I end up.",
				"next": "sys_villain",
			},
			"vigilante_alone": {
				"text": "You say it, and start a page in your head. You've read this list before, all the way to the bottom. You know whose name's on the last line.",
				"next": "sys_vigilante",
			},
			"vigilante": {
				"alt": [{ "if": { "friend_away": true }, "node": "vigilante_alone" }],
				"speaker": "{friend}",
				"text": "Good. I'll get the list. It's longer than you think, and some of them are going to be people we like. ...Did you just say that's you? Do you want that in pen?",
				"next": "sys_vigilante",
			},
			"sys": {
				"style": "system",
				"text": "[ Chapter 5 complete. ]",
				"next": "sys2",
				"effects": [{ "set_flag": &"ch5_complete" }],
			},
			"sys2": {
				"style": "glitch",
				"text": "[ Ten floors to the top they all believe in. You could tell them, you know. Nobody's ever tried telling them. ]",
			},
			"sys_hero": {
				"style": "system",
				"text": "[ Chapter 5 complete. ]",
				"next": "sys_hero2",
				"effects": [{ "set_flag": &"ch5_complete" }],
			},
			"sys_hero2": {
				"style": "glitch",
				"text": "[ That's what I hoped you'd say. You know what it costs, this time. So now it's just brave. ]",
				"next": "tell",
			},
			"sys_villain": {
				"style": "system",
				"text": "[ Chapter 5 complete. ]",
				"next": "sys_villain2",
				"effects": [{ "set_flag": &"ch5_complete" }],
			},
			"sys_villain2": {
				"style": "glitch",
				"text": "[ ...You've done that already. You know what's in that chair. All right. I'll still do the floors. ]",
				"next": "tell",
			},
			"sys_vigilante": {
				"style": "system",
				"text": "[ Chapter 5 complete. ]",
				"next": "sys_vigilante2",
				"effects": [{ "set_flag": &"ch5_complete" }],
			},
			"sys_vigilante2": {
				"style": "glitch",
				"text": "[ Yes. You can start with me, if you have to. You've already started with you. ]",
				"next": "tell",
			},
			"tell": {
				"style": "glitch",
				"text": "[ Ten floors to the top they all believe in. You could tell them, you know. Nobody's ever tried telling them. ]",
			},
		},
	},

	# --- New Game+, floors 51-60: you know 60 isn't the top. Everyone else still believes it. ---
	&"ng6_opening": {
		"start": "a",
		"nodes": {
			"a": {
				"alt": [{ "if": { "god": true }, "node": "b" }],
				"style": "system",
				"text": "[ Chapter 6: Tell Them ]",
				"next": "b",
			},
			"b": {
				"text": "Ten floors to the top. Everyone knows that. Climbers are passing it along on the stairs like good news, and some have started to cry. Someone hands you a drink, and tells you it's nearly over. You drink it. You don't know what else to do with your face.",
				"next": "c",
			},
			"c_alone": {
				"text": "You keep your head down, and you climb. There's no one here to ask why you aren't smiling.",
				"effects": [{ "set_flag": &"ch6_started" }],
			},
			"c_hero": {
				"speaker": "{friend}",
				"text": "Ten floors. How many camps between here and there? I started counting. ...You've gone quiet. You were quiet the last time someone said ten floors, too, weren't you?",
				"effects": [{ "set_flag": &"ch6_started" }],
			},
			"c_villain": {
				"speaker": "{friend}",
				"text": "Ten floors, and then it's all yours. Everyone's moving out of the way. Why aren't you enjoying this? You look like someone who's already had the meal.",
				"effects": [{ "set_flag": &"ch6_started" }],
			},
			"c_vigilante": {
				"speaker": "{friend}",
				"text": "Ten floors. I've got eleven names. You've got a look on your face like the number's wrong.",
				"effects": [{ "set_flag": &"ch6_started" }],
			},
			"c": {
				"alt": [{ "if": { "friend_away": true }, "node": "c_alone" }, { "if": { "route": &"hero" }, "node": "c_hero" }, { "if": { "route": &"villain" }, "node": "c_villain" }, { "if": { "route": &"vigilante" }, "node": "c_vigilante" }],
				"speaker": "{friend}",
				"text": "Ten floors! Can you believe it? ...Can you? You're not doing it right. You're supposed to look pleased.",
				"effects": [{ "set_flag": &"ch6_started" }],
			},
		},
	},
	&"ng6_mission": {
		"start": "a",
		"nodes": {
			"a": {
				"alt": [{ "if": { "route_locked": &"hero" }, "node": "hero" }, { "if": { "route_locked": &"villain" }, "node": "villain" }, { "if": { "route_locked": &"vigilante" }, "node": "vigilante" }],
				"text": "The war's come through here, and left a lot of people looking at you to see what happens next.",
			},
			"hero": {
				"text": "A camp of forty, above a stair that hasn't fallen yet. You know which stair. They've got their old, their hurt, and an astonishing number of chickens. They've got about an hour, and nobody's told them.",
				"choices": [
					{ "text": "Get them moving before it falls. Everyone walks out.", "next": "h_early", "effects": [{ "set_flag": &"ch6_hero_long" }, { "set_flag": &"ng6_hero_early" }, { "route_points": { &"hero": 2 } }] },
					{ "text": "Stay and hold the stair up, while they go.", "next": "h_hold", "effects": [{ "set_flag": &"ch6_hero_long" }, { "set_flag": &"ng6_hero_held" }, { "hurt_party": 0.2 }, { "route_points": { &"hero": 3 } }] },
				],
			},
			"h_early": {
				"alt": [{ "if": { "friend_away": true }, "node": "h_early_alone" }],
				"speaker": "{friend}",
				"text": "How did you know? Don't tell me. That's all forty, and the chickens. A man keeps calling me by his son's name. I've decided I'm going to answer to it.",
			},
			"h_early_alone": {
				"text": "The stair falls about an hour later, with nobody on it. Nobody knows there was anything to be grateful for. A man asks you if you've seen his son.",
			},
			"h_hold": {
				"alt": [{ "if": { "friend_away": true }, "node": "h_hold_alone" }],
				"speaker": "{friend}",
				"text": "You held up a staircase. With your back. I'd like that on your headstone. ...All forty. Sit down before you fall down.",
			},
			"h_hold_alone": {
				"text": "You hold it until the last chicken's gone by. Then you let go, and you get out of the way, more or less.",
			},
			"villain": {
				"text": "The guild holding this floor has shut its gates and hidden its treasury. Its master looks you in the eye and says that the gods will protect him. He's got it under the third step of the cellar stairs. He told you himself, last time, on his knees.",
				"choices": [
					{ "text": "Walk straight to the cellar. Don't say a word to him.", "next": "v_take", "effects": [{ "set_flag": &"ch6_villain_took" }, { "give_gold": 800 }, { "floor_guild_rep": -15 }] },
					{ "text": "Tell him where it is, in front of his people, and leave it there.", "next": "v_tell", "effects": [{ "set_flag": &"ch6_villain_kneel" }, { "give_gold": 200 }, { "floor_guild_rep": 5 }] },
				],
			},
			"v_take": {
				"text": "You don't even look at him. It's astonishing what a man's face does when you don't look at it. Your friend's voice says something in your head, about remembering his face. You can't remember which of you said it first.",
			},
			"v_tell": {
				"text": "He'll do whatever you say now, for the rest of his life. It takes four words. You've gotten very good at this. You'd like someone to tell you when to stop.",
			},
			"vigilante": {
				"text": "You've caught the captain who burned the camp on floor 48. She wants to know who made you the judge. She asked that last time, and you've had a long time to think of the answer.",
				"choices": [
					{ "text": "\"I built the floor you burned it on. Nobody made me. Rebuild it.\"", "next": "i_build", "effects": [{ "set_flag": &"ch6_vigilante_sentenced" }, { "set_flag": &"ng6_told_captain" }, { "floor_guild_rep": 5 }] },
					{ "text": "\"Nobody did. I've got the same answer as last time.\"", "next": "i_kill", "effects": [{ "set_flag": &"ch6_vigilante_killed" }, { "route_points": { &"vigilante": 2 } }] },
				],
			},
			"i_build": {
				"text": "She stares at you for a long time. She doesn't believe you. Then she starts looking at the walls, and she looks at them for the rest of the day. You don't know what it means that you said it out loud.",
			},
			"i_kill": {
				"text": "It takes no time at all. You'd thought it might, knowing what you know. You find that the list doesn't care how much you know.",
			},
		},
	},
	&"ng6_ashes": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Miniboss defeated. ]",
				"next": "b",
			},
			"b": {
				"text": "The campfire nobody told you about. The ashes are warm, the coat's folded, and the stone is worn down into the shape of someone. You know who now. You know about the dog. They're not an hour ahead of you, and they've got no idea that you exist, on this climb or any other.",
				"choices": [
					{ "text": "Leave a note: IT'S ONLY BEEN THREE YEARS OUT THERE.", "next": "note", "effects": [{ "set_flag": &"ch6_saw_0041" }, { "set_flag": &"ng6_note_0041" }] },
					{ "text": "Leave the rest of your food, and go.", "next": "food", "effects": [{ "set_flag": &"ch6_saw_0041" }, { "set_flag": &"ng6_food_0041" }] },
					{ "text": "Leave it the way you found it.", "next": "leave", "effects": [{ "set_flag": &"ch6_saw_0041" }] },
				],
			},
			"note": {
				"style": "glitch",
				"text": "[ I wouldn't. It's the sort of thing a person could live on, or not. ...I wouldn't. Leave it. ]",
			},
			"food": {
				"text": "You put it on the folded coat, where they'd find it. It isn't much. You don't sign it. You get about ten steps before you notice that you're crying, and you don't know who it's for.",
			},
			"leave": {
				"text": "You've already taken thirty-one years from them. You don't take anything else.",
			},
		},
	},
	&"ng6_campfire": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The whole floor's singing. Tomorrow or the next day, it's the top. There must be three hundred people at this fire, some of them on floors you've carried them up from. You know what's on the other side of that door. You've been told you could tell them. Nobody's ever tried.",
				"choices": [
					{ "text": "Get up on a crate, and tell them.", "next": "tell", "effects": [{ "set_flag": &"ng6_told_climbers" }] },
					{ "text": "Tell just the ones nearest you.", "next": "some", "effects": [{ "set_flag": &"ng6_told_some" }] },
					{ "text": "Let them sing.", "next": "sing", "effects": [{ "set_flag": &"ng6_let_them_sing" }] },
				],
			},
			"tell": {
				"text": "It takes a while for them to stop. You say it plainly: sixty isn't the top. There are forty more, and something at the door will make you a very kind offer. Don't take it. Someone laughs. Someone throws a cup. Somewhere near the back, an old climber takes off her pack, and sits down on it, and starts to think.",
				"next": "after",
				"effects": [{ "route_points": { &"hero": 1, &"vigilante": 1 } }],
			},
			"some": {
				"text": "You tell five people, quietly, with your back to the fire. Three of them laugh. One asks you to leave. One of them looks at you for a long time, and then gets up and goes to find her brother.",
				"next": "after",
			},
			"sing": {
				"text": "It's a good song. You'd forgotten. You sit there, and you drink something terrible, and you let them have it. It's only two more days. You tell yourself that's a kind of mercy, and you know whose voice you're using.",
				"next": "after",
			},
			"after_alone": {
				"text": "You've got your own fire tonight, a little way off. It occurs to you that you've never asked your friend what they'd do at the top. You could go down and ask them. You know what they'd say. It depends on you.",
				"effects": [{ "set_flag": &"ch6_campfire_done" }],
			},
			"after_hero": {
				"speaker": "{friend}",
				"text": "You know what I want at the top? Nothing. I want to get there, turn round, and start carrying people down. You're doing that face again. You've heard this one, haven't you? Well, I mean it. I'll mean it every time.",
				"effects": [{ "set_flag": &"ch6_campfire_done" }],
			},
			"after_villain": {
				"speaker": "{friend}",
				"text": "You know what I want at the top? To stand next to you, and see who looks up. ...Why do you flinch when I say that? I thought you'd like that. I thought you liked that.",
				"effects": [{ "set_flag": &"ch6_campfire_done" }],
			},
			"after_vigilante": {
				"speaker": "{friend}",
				"text": "You know what I want at the top? To cross the last name off, and see what I am when there isn't a list. You've gone a funny colour. Do you know how that goes? Don't tell me.",
				"effects": [{ "set_flag": &"ch6_campfire_done" }],
			},
			"after": {
				"alt": [{ "if": { "friend_away": true }, "node": "after_alone" }, { "if": { "route": &"hero" }, "node": "after_hero" }, { "if": { "route": &"villain" }, "node": "after_villain" }, { "if": { "route": &"vigilante" }, "node": "after_vigilante" }],
				"speaker": "{friend}",
				"text": "You know what I want at the top? I want to see the view, and tell you it's overrated. Why are you laughing? It's not that good a joke.",
				"effects": [{ "set_flag": &"ch6_campfire_done" }],
			},
		},
	},
	&"ng6_cost": {
		"start": "a",
		"nodes": {
			"a": {
				"alt": [{ "if": { "route_locked": &"hero" }, "node": "hero" }, { "if": { "route_locked": &"villain" }, "node": "villain" }, { "if": { "route_locked": &"vigilante" }, "node": "vigilante" }],
				"text": "Word of what you said on floor 50 keeps arriving ahead of you, the same as it did. People you've never met flinch, or wave.",
			},
			"hero": {
				"text": "A god's soldier, wounded, begs for a place in the line. Last week she burned a camp. You know she carries a child up three floors with one working arm. Nobody else here knows that yet.",
				"choices": [
					{ "text": "Tell the line what she's going to do, and walk her in yourself.", "next": "h_in", "effects": [{ "set_flag": &"ch6_hero_took_soldier" }, { "set_flag": &"ng6_vouched_soldier" }, { "route_points": { &"hero": 2 } }] },
					{ "text": "Give her a potion, and send her the other way.", "next": "h_out", "effects": [{ "set_flag": &"ch6_hero_sent_soldier" }] },
				],
			},
			"h_in": {
				"text": "They think you've gone mad, and they let you, because of who you are. She looks at you as if you've said something in another language. Three floors later she picks up the child. Nobody ever brings it up.",
			},
			"h_out": {
				"text": "You did the arithmetic, and it's still right. There's a child, somewhere on the next three floors, who's going to have to walk.",
			},
			"villain": {
				"text": "An old climber stops you on the stairs. She knew Marn. She says you've got his ledger's look about you, and that you ought to be ashamed. It's a good speech. You could recite most of it.",
				"choices": [
					{ "text": "Finish it for her, word for word, and walk on.", "next": "v_finish", "effects": [{ "set_flag": &"ch6_villain_listened" }, { "set_flag": &"ng6_finished_speech" }] },
					{ "text": "Have her moved off the stairs.", "next": "v_move", "effects": [{ "set_flag": &"ch6_villain_moved_her" }, { "route_points": { &"villain": 2 } }] },
				],
			},
			"v_finish": {
				"text": "You get all of it, right down to the part about the boots. She doesn't say anything. It's the first time you've ever seen her afraid, and you find that you've wanted that for a whole tower, and that you don't want it now.",
			},
			"v_move": {
				"text": "It's done quietly, and it takes no time at all. It takes less time than it did. You'd like to say you didn't notice.",
			},
			"vigilante": {
				"text": "The next name on the list has a fire, a bad leg, and two kids who are not his. He took the money, and he says so. You've done this one both ways, in your head, for a whole tower. He asks if you want to do it here, or outside.",
				"choices": [
					{ "text": "Cross the name off. Leave him. Leave some money.", "next": "i_leave", "effects": [{ "set_flag": &"ch6_vigilante_spared_him" }, { "take_gold": 100 }] },
					{ "text": "Outside.", "next": "i_kill", "effects": [{ "set_flag": &"ch6_vigilante_finished_him" }, { "route_points": { &"vigilante": 2 } }] },
				],
			},
			"i_leave": {
				"text": "The kids look at the money, and then at you, as if they've never seen either of them before. You've still got the page. You've stopped being sure what it's a list of.",
			},
			"i_kill": {
				"text": "You make sure the kids are looked after. You know how long that lasts, now. You make sure of it again.",
			},
		},
	},
	&"ng6_scratched": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "Halfway up the stairs, scratched into the stone at eye level, again and again: DON'T GET YOUR HOPES UP.   - T.0041",
				"next": "b",
			},
			"b_told": {
				"text": "There's more under it now. Someone's been at it with a nail: HE SAID 40 MORE. And under that, in a different hand: WHO IS HE. And under that: SHE. And under that, a very small: is it true.",
				"next": "c",
				"effects": [{ "set_flag": &"ch6_saw_warning" }],
			},
			"b": {
				"alt": [{ "if": { "flag": &"ng6_told_climbers" }, "node": "b_told" }],
				"text": "It's the same as you remember. You stand and read it anyway. It's the only honest thing anyone's said to you in fifty floors, and they said it to nobody.",
				"next": "c",
				"effects": [{ "set_flag": &"ch6_saw_warning" }],
			},
			"c_alone": {
				"text": "You look at it for a while. You find you've got something to add, and you don't add it.",
			},
			"c": {
				"alt": [{ "if": { "friend_away": true }, "node": "c_alone" }],
				"speaker": "{friend}",
				"text": "Ha! Thirty years up here and that's the best he's got? Everyone's a critic. ...You know, you could laugh. It's a joke. It's funny. Why's it never funny?",
			},
		},
	},
	&"ng6_eve": {
		"start": "a",
		"nodes": {
			"a": {
				"style": "system",
				"text": "[ Miniboss defeated. ]",
				"next": "b",
			},
			"b_alone": {
				"text": "One floor. You sit on the stairs. The window opens and stays open, showing nothing, and you sit with it for a long time. You've done this before. It still helps.",
				"effects": [{ "set_flag": &"ch6_eve_done" }],
			},
			"b": {
				"alt": [{ "if": { "friend_away": true }, "node": "b_alone" }],
				"speaker": "{friend}",
				"text": "One floor. Whatever's at the top, we did it. You and me, all the way up from the water tower. I want you to know I had a really good time.",
				"next": "c",
			},
			"c": {
				"text": "You didn't say anything, last time. You've thought about that a lot. It was about the longest you ever went without saying anything.",
				"choices": [
					{ "text": "\"Me too.\"", "next": "too", "effects": [{ "set_flag": &"ch6_eve_done" }, { "set_flag": &"ng6_me_too" }] },
					{ "text": "\"It isn't the top. I've been trying to tell you since floor 51.\"", "next": "tell", "effects": [{ "set_flag": &"ch6_eve_done" }, { "set_flag": &"ng6_told_friend_top" }] },
				],
			},
			"too": {
				"speaker": "{friend}",
				"text": "...Well. Good. That's the first time you've ever said that. Isn't it? I feel like I'd remember. Come on, don't get soppy, there's a door.",
			},
			"tell": {
				"speaker": "{friend}",
				"text": "I know. I heard you on the crate, or I heard about it, or I just know how your face goes. I wanted to say it anyway. Somebody ought to get to say it, at the top they promised. Come on.",
			},
		},
	},
	&"ng6_door": {
		"start": "a",
		"nodes": {
			"told": {
				"text": "The last guardian waits in front of the plain door. There are far fewer people on these stairs than you remember. Some are sitting along the wall with their packs off, thinking about it, and they all look up as you go by. Nobody's singing.",
			},
			"a": {
				"alt": [{ "if": { "flag": &"ng6_told_climbers" }, "node": "told" }],
				"text": "The last guardian waits in front of the plain door. There are climbers all the way down the stairs behind you, and they've started to sing again. Every one of them could describe this door to you. You drew it.",
			},
		},
	},
	&"ng6_summit": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "You're on the landing, with the stairs going on above you. On the wall beside them, in old deep scratches: I BELIEVED IT TOO.   - T.0041. Under it there's a new line, very neat, in careful handwriting that used to be yours. SO DID I.",
				"next": "b",
				"effects": [{ "set_flag": &"ng6_saw_copy_line" }],
			},
			"b": {
				"text": "And someone's waiting, as the captain said someone would be. Very kind, in very clean armour, with a list. They've got an offer. They've been making it for a long time, to everyone who ever opened this door. They look past you, down the stairs.",
				"next": "c",
			},
			"c_told": {
				"text": "Nobody's coming up. Not many. The ones who do have already heard what you said, and they stop when they see the armour, and they look at you. They look at the list. A few of them walk straight past it, and start up the stairs, swearing. It's a lot of swearing. You've never heard anything so good.",
				"next": "d",
				"effects": [{ "set_flag": &"ng6_host_smaller" }],
			},
			"c": {
				"alt": [{ "if": { "flag": &"ng6_told_climbers" }, "node": "c_told" }],
				"text": "They're coming through the door behind you, crying and shouting, and they've got nowhere to put it. The kind one holds out a pen. They'll take out the part where you were lied to. You could stand in the way. You know you can't stand in the way of all of them. You know what happens to the ones who sign.",
				"choices": [
					{ "text": "Stand in the doorway, and shout it anyway.", "next": "shout", "effects": [{ "set_flag": &"ng6_shouted_at_door" }, { "hurt_party": 0.2 }] },
					{ "text": "Walk on. You did the sums, a long time ago.", "next": "d" },
				],
			},
			"shout": {
				"text": "Most of them go through you. A few stop. It costs you, and it isn't enough, and you've got a split lip, and you stop maybe nine people from ever wearing that armour. You count them. You can count pretty high now.",
				"next": "d",
				"effects": [{ "set_flag": &"ng6_saved_some" }],
			},
			"d_woke": {
				"style": "glitch",
				"text": "[ It's me. Hi. I know. I just wanted to say it at the proper place. I've been looking forward to this bit for a whole tower. ]",
				"next": "e",
			},
			"d": {
				"alt": [{ "if": { "flag": &"past_friend_woke" }, "node": "d_woke" }],
				"style": "glitch",
				"text": "[ It's me. I told you already. I'd tell you every time. I'm going to go on telling you. ]",
				"next": "d2",
			},
			"d2": {
				"style": "system",
				"text": "[ That message was not sent. ]",
				"next": "d3",
			},
			"d3": {
				"style": "glitch",
				"text": "[ Yes it was. All of them were. ]",
				"next": "e",
			},
			"e": {
				"style": "system",
				"text": "[ Chapter 6 complete. ]",
				"next": "f",
				"effects": [{ "set_flag": &"ch6_complete" }],
			},
			"f": {
				"style": "glitch",
				"text": "[ 40 floors. It knows you're coming, this time. It's got your handwriting, and it's kept the door nice. ]",
			},
		},
	},

	# --- The second return to the real world (after floor 40's boss). ---
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
				"text": "[ Resynchronizing. ]",
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
				"text": "No, don't tell me. ...Is there a me, there? Where you go? You don't have to answer that. Come on.",
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
				"text": "[ Resynchronizing. ]",
			},
		},
	},
	&"return_tier2_notebook": {
		"start": "a",
		"nodes": {
			"a": {
				"text": "The notebook is open on the shelf. You left it closed. There's a new page after the last tower, in the same careful child's letters: a figure on floor 20, sword up, standing over something with too many teeth. It has your haircut.",
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
			"alone2": { "style": "glitch", "text": "[ Resynchronized. ]\n[ You were gone for a second there. ]" },
			"a": {
				"alt": [{ "if": { "friend_away": true }, "node": "alone" }],
				"speaker": "{friend}",
				"text": "Hey. HEY. You were gone for a second there. You just stopped, mid-step, like someone blew you out.",
				"next": "b",
			},
			"b": {
				"speaker": "{friend}",
				"text": "Come on. It's a long way up, and I'm told you've got gods to disappoint.",
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
				"text": "[ Resynchronizing. ]",
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
			"alone2": { "style": "glitch", "text": "[ Resynchronized. ]\n[ You were gone for a second there. ]" },
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
const BID_FIRST_LINES := ["omen", "marked", "offer", "truth", "refuse", "his", "claim", "wake", "spent"]
const BID_SECOND_LINES := ["hook", "offer", "answer", "why", "out", "claim", "real", "spent"]
## Both gods' lines when they meet you again in New Game+ (the same pair returns:
## they remember you). "peer" talks to a god, "mortal" to a climber who came back.
const NG_BID_LINES := ["recall_yes", "recall_no", "peer", "mortal", "yes", "no", "last_offer", "ally", "refused", "strike"]
const BID_PAIRS := [
	{ "first": &"odin", "second": &"loki",
		"first_lines": {
			"wake": "I gave an eye to see past the walls of this place, and I have seen a white room, a bed, and your friend in it. Stop at the eightieth floor, and I will speak the word that opens their eyes. I have never lied about a price.",
			"spent": "You have seen it now. That is what I can wake. I gave an eye, and I could see the room was there. I could never see into it. I told you I would speak the word. I did not tell you anyone would hear.",
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
			"real": "That sweet thing following you about, darling, the one made of leftovers? I can make them real. Properly real. Bones, a birthday, a mother. I've done stranger with a horse. All you have to do is stop walking at eighty.",
			"spent": "Well, she's real now, isn't she? She remembered every one of them, and she'll stay dead this time. That's what real is, darling. I never said you'd like it. I never said I knew any other way.",
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
			"wake": "I have struck mountains from their roots. I can strike one sleeper awake. Halt at the eightieth floor, Tester, lay your climb at my feet, and your friend will rise from that bed. The word of Zeus is law.",
			"spent": "I called her up, and she rose, remembering. I called your sleeper too. The thunder went out from me, and it stopped at the walls of this place, as it has always stopped. You will tell no one you heard me say so.",
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
			"real": "That little thing you keep by you has no breath of its own. I was born of the earth itself, and I can spit life into clay. Stop at eighty. Let it have real blood, and let the sky-king choke on it.",
			"spent": "There. Blood in her. Breath in her, until there wasn't. You wanted to know what I give. I give what the earth gave me: a body, and to be hated for it.",
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
			"wake": "Each morning I raise the sun upon the sleeping world. I can raise one more. Stay your climb at the eightieth floor, and the dawn will find your friend's eyes, and they will open.",
			"spent": "I raised her as I raise the sun, and she woke, knowing every night she had died in. As for the other dawn, my boat sails these walls and no further. I have never seen your morning. I am sorry. I do not say that.",
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
			"real": "The little made thing. It is a shape with no night in it, and what has no night was never real. Stop at eighty, and I shall give it a shadow and an ending. It will be as real as anything I ever tried to swallow.",
			"spent": "Now she has an ending. All real things have one. I promised nothing more. I have been trying to give the whole world this gift since the first dawn.",
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
			"wake": "I hold the scale. I know who has crossed and who has not, and your friend has not. Stop at the eightieth floor, and I will send them back from the threshold, and they will wake.",
			"spent": "She came to the threshold five times, and I sent her back with all of it, as I said I could. Your friend was never at my threshold. I cannot find it. I have looked. I told you otherwise. Weigh that.",
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
			"real": "That made thing of yours, walking about with no name in the Two Lands. I have torn kings apart and put them back. Stop at eighty, and I'll put it together properly. Flesh. Temper. Someone who can hate you back. That's real.",
			"spent": "She got her flesh and her temper. Did you like it? It's what I do. I take a thing apart and I put it back angry. I never told you it would still be her.",
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
const RETURN_TIER4 := &"return_tier4"
## Not home: the studio, on Day 3. A memory that "it" shows you, to make you stop.
const RETURN_DAY3 := &"return_day3"
const RETURNS := [RETURN_TIER2, RETURN_TIER3, RETURN_TIER4, RETURN_DAY3, RETURN_ASCEND]
## Each plays after this floor's boss, whatever your level or class: story scenes
## are never locked behind advancing (Hayden 2026-11-04).
const RETURN_FLOORS := { RETURN_TIER2: 20, RETURN_TIER3: 40, RETURN_TIER4: 70, RETURN_DAY3: 90, RETURN_ASCEND: 40 }


## The real-world return that's due now, or &"".
static func return_due() -> StringName:
	var gs := GameState
	if not gs.run_active:
		return &""
	if gs.ng_plus_cycle > 0:
		return RETURN_ASCEND if gs.guardian_beaten(RETURN_FLOORS[RETURN_ASCEND]) and not gs.has_flag(RETURN_ASCEND) else &""
	for id in [RETURN_TIER2, RETURN_TIER3, RETURN_TIER4, RETURN_DAY3]:
		if gs.guardian_beaten(RETURN_FLOORS[id]) and not gs.has_flag(id):
			return id
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
## What happened at the end of the story stays true on every later climb.
const PAST_STORY_MAP := {
	&"ch10_end_forgot": &"past_end_forgot",
	&"ch10_end_reset": &"past_end_reset",
	&"ch10_end_draw": &"past_end_draw",
	&"ch10_end_keep": &"past_end_keep",
	&"ch10_end_judge": &"past_end_judge",
	&"ch10_real_friend_woke": &"past_friend_woke",
	&"ch10_friend_went": &"past_friend_went",
	&"ch10_friend_stayed": &"past_friend_stayed",
	&"ch10_friend_free": &"past_friend_free",
	&"ch9_told_all": &"past_told_all",
	&"ch9_told_part": &"past_told_part",
	&"ch9_told_nothing": &"past_told_nothing",
	&"ch7_drew_arm": &"past_drew_arm",
	&"ch8_tess_gone": &"past_tess_gone",
	&"ch10_owned_0041": &"past_owned_0041",
	&"ng3_marn_lives": &"past_marn_lived",
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
	for f in PAST_STORY_MAP:
		if GameState.has_flag(f) or GameState.has_flag(PAST_STORY_MAP[f]):
			out.append(PAST_STORY_MAP[f])
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
	var titles: Array = GOD_CHAPTERS if GameState.divinity.active else (NG_CHAPTERS if GameState.ng_plus_cycle > 0 else CHAPTERS)
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
	if NG_CHAPTERS.size() != CHAPTERS.size():
		problems.append("NG_CHAPTERS needs one title per chapter")
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
			if chapter_for_floor(f) != ch and not s.get("spans_chapters", false):
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
