class_name NpcLibrary
extends RefCounted
## People and lore objects you can bump into on a floor. Each one runs a
## conversation from DialogueLibrary when you walk into it.
##
## Fields:
##   "name":      shown in the HUD and as the default speaker
##   "kind":      "npc" (a person) or "object" (mural, item, sign...)
##   "dialogue":  DialogueLibrary id
##   "color":     placeholder art colour
##   "floors":    which kinds of floor it can be on: "rest", "boss" (only once
##                the boss is beaten), "combat", "miniboss"
##   "min_floor" / "max_floor"
##   "chance":    (default 1.0) chance to be on a floor that fits. Rolled from
##                the floor's seed, so leaving and coming back doesn't re-roll.
##   "if":        (optional) DialogueRunner condition, e.g. { "flag": &"x" }
##   "gone_flag": (optional) once this flag is set it never appears again
##                (a clue that's been read, a quest that's done)
##   "near":      (optional) "campfire" or "merchant": stands right next to it
##   "recruit":   (optional) makes it recruitable. It disappears once recruited.
##       "class_id":  class it takes at level 10+ (if its build qualifies)
##       "build":     Stats.Type -> weight; level-up points are split this way
##       "row":       (optional) Combatant.Row to start in
##       "meet":      how you meet them (Hayden 2026-10-25). "legend" = a
##                    demigod: their "favor" is a legendary quest chain
##                    (recruit_legend), and their class is their own. Or:
##                    "campfire" (sitting by a rest-floor campfire; dialogue
##                    recruit_campfire), "hire" (one-time "fee" in gold, near the
##                    merchant; recruit_hire), "favor" (do their "favor" quest
##                    first; recruit_favor), "rescue" (fighting for their life on
##                    a combat floor in "rescue_floors": they fight beside you
##                    and join if you win), "captive" (locked up by the boss
##                    "captive_of"; beat it to free them). Captives are blessed
##                    by a being whose RIVAL sponsors that boss.
##       "pitch":     what they say when you meet them (placeholder)
##       "pitch_if":  (optional) [{ "if": condition, "pitch": text }]: the first
##                    that passes replaces "pitch" (people who remember you)
##       "personal_skill": their own skill, unlocked by finishing their
##                    "loyalty" quest (QuestLibrary.recruit_quests builds both)
##       "favor" / "loyalty": { "title", "desc", "steps": [{ "text", "goal" }] }
##   "run_chance":    (optional) wanderers: chance (per run) they're in this run
##
## Recruits join at the player's level - 1 (min 1). Placeholders below.

const NPCS := {
	# --- Added 2026-11-04 (Hayden): every route can reach a full party in every run.
	# Hilde, Cormac, Belit, Ulfar, Ines and Bren only come after your route locks.
	&"oren": {
		"name": "Oren", "kind": "npc", "dialogue": &"recruit_favor", "color": Color(0.8, 0.65, 0.4),
		"floors": ["rest"], "min_floor": 10, "max_floor": 9999, "near": "campfire",
		"recruit": {
			"class_id": &"monk", "meet": "favor", "personal_skill": &"mending_palm",
			"build": { Stats.Type.STRENGTH: 4, Stats.Type.HEALTH: 3, Stats.Type.AGILITY: 3 },
			"pitch": "I walk the lower floors, bringing bread to whoever's still breathing. The way's been blocked. Help me clear it, and I'll walk with you instead.",
			"favor": { "title": "Oren: Bread for the Lower Floors", "desc": "Monsters keep Oren from reaching the camps.",
				"steps": [{ "text": "Defeat 10 enemies", "goal": { "type": "defeat", "any": true, "count": 10 } }] },
			"loyalty": { "title": "Oren: The Long Road Down", "desc": "Oren wants to know the camps below are safe.",
				"steps": [{ "text": "Defeat 40 enemies", "goal": { "type": "defeat", "any": true, "count": 40 } }] },
		},
		"values": { "likes": [&"hero"], "dislikes": [&"villain"] },
	},
	&"hilde": {
		"name": "Hilde", "kind": "npc", "dialogue": &"recruit_campfire", "color": Color(0.7, 0.6, 0.5),
		"floors": ["rest", "boss"], "min_floor": 50, "max_floor": 9999, "near": "campfire",
		"if": { "route_locked": &"hero" },
		"recruit": {
			"class_id": &"support", "meet": "campfire", "personal_skill": &"patch_and_mend",
			"build": { Stats.Type.INTELLIGENCE: 5, Stats.Type.HEALTH: 3, Stats.Type.STAMINA: 2 },
			"pitch": "I heard what you told those two gods. Every climber, you said. Well, I've mended every boot on this floor. Somebody ought to walk with you who knows how long a road that is.",
			"pitch_if": [
				{ "if": { "flag": &"ch5_stood_neither" }, "pitch": "You drove them off my camp, floor 42. Cost you blood, and I watched you pay it. You said every climber, up there. Fine. My boots are mended. Let's go." },
			],
			"loyalty": { "title": "Hilde: One More Pair", "desc": "Hilde means to see the camps get out alive.",
				"steps": [{ "text": "Defeat 30 enemies", "goal": { "type": "defeat", "any": true, "count": 30 } }] },
		},
		"values": { "likes": [&"hero"], "dislikes": [&"villain"] },
	},
	&"cormac": {
		"name": "Cormac", "kind": "npc", "dialogue": &"recruit_campfire", "color": Color(0.55, 0.7, 0.45),
		"floors": ["rest", "boss"], "min_floor": 50, "max_floor": 9999, "near": "campfire",
		"if": { "route_locked": &"hero" },
		"recruit": {
			"class_id": &"warrior", "meet": "campfire", "personal_skill": &"shield_of_the_stair",
			"build": { Stats.Type.STRENGTH: 4, Stats.Type.HEALTH: 4, Stats.Type.STAMINA: 2 },
			"pitch": "I was a god's soldier until a week ago. I laid my mark down at that hall when you said what you said. I'm good at standing between things. Point me at whoever's next.",
			"loyalty": { "title": "Cormac: Mark Laid Down", "desc": "Cormac's old warband wants him back. He'd like to discuss it.",
				"steps": [{ "text": "Defeat 2 minibosses", "goal": { "type": "defeat", "kind": "miniboss", "count": 2 } }] },
		},
		"values": { "likes": [&"hero"], "dislikes": [&"villain"] },
	},
	&"sabine": {
		"name": "Sabine", "kind": "npc", "dialogue": &"recruit_hire", "color": Color(0.45, 0.3, 0.6),
		"floors": ["rest"], "min_floor": 20, "max_floor": 9999, "near": "merchant",
		"recruit": {
			"class_id": &"mage", "meet": "hire", "personal_skill": &"fine_print", "fee": 1000,
			"build": { Stats.Type.INTELLIGENCE: 6, Stats.Type.LUCK: 2, Stats.Type.AGILITY: 2 },
			"pitch": "A guild envoy gets to read everyone's mail. I know where every god's money is kept. A thousand gold, and I'll stop working for people who are about to lose.",
			"pitch_if": [
				{ "if": { "flag": &"ch2_envoy_paid" }, "pitch": "We've done business, Tester. Floor 18. You named a price, and I respected it. A thousand gold, and I'll stop working for people who are about to lose." },
				{ "if": { "flag": &"ch2_envoy_refused" }, "pitch": "You told my masters to go and bid elsewhere, floor 18. I carried that word for word, and enjoyed it. They've since gone bankrupt. A thousand gold, and I'm yours." },
			],
			"loyalty": { "title": "Sabine: Hostile Takeover", "desc": "Sabine has a list of guildmasters she'd like to see removed.",
				"steps": [{ "text": "Defeat 2 bosses", "goal": { "type": "defeat", "kind": "boss", "count": 2 } }] },
		},
		"values": { "likes": [&"villain"], "dislikes": [&"hero"] },
	},
	&"dragan": {
		"name": "Dragan", "kind": "npc", "dialogue": &"recruit_campfire", "color": Color(0.45, 0.25, 0.25),
		"floors": ["rest"], "min_floor": 10, "max_floor": 9999, "near": "campfire",
		"recruit": {
			"class_id": &"tank", "meet": "campfire", "personal_skill": &"hold_them_down",
			"build": { Stats.Type.HEALTH: 4, Stats.Type.STAMINA: 4, Stats.Type.STRENGTH: 2 },
			"pitch": "You've got a fair idea of what the strong can do to the weak up here. I've got a very good one. I don't ask why, I just stand where you tell me, and nothing gets past.",
			"loyalty": { "title": "Dragan: The Toll", "desc": "Dragan used to take a toll on the stairs. He'd like it back.",
				"steps": [{ "text": "Defeat 40 enemies", "goal": { "type": "defeat", "any": true, "count": 40 } }] },
		},
		"values": { "likes": [&"villain"], "dislikes": [&"hero"] },
	},
	&"belit": {
		"name": "Belit", "kind": "npc", "dialogue": &"recruit_campfire", "color": Color(0.35, 0.2, 0.4),
		"floors": ["rest", "boss"], "min_floor": 50, "max_floor": 9999, "near": "campfire",
		"if": { "route_locked": &"villain" },
		"recruit": {
			"class_id": &"summoner", "meet": "campfire", "personal_skill": &"court_of_the_dead",
			"build": { Stats.Type.INTELLIGENCE: 6, Stats.Type.STAMINA: 2, Stats.Type.HEALTH: 2 },
			"pitch": "I heard you, up there. The tower, and the two of them with it. How delightful. My family served the old queens of the underworld, and I've been looking for a new one. Don't flatter yourself, I said looking.",
			"loyalty": { "title": "Belit: The Old Court", "desc": "Belit wants a throne for you. Hers is the seat beside it.",
				"steps": [{ "text": "Defeat 1 bosses", "goal": { "type": "defeat", "kind": "boss", "count": 1 } }] },
		},
		"values": { "likes": [&"villain"], "dislikes": [&"hero"] },
	},
	&"ulfar": {
		"name": "Ulfar", "kind": "npc", "dialogue": &"recruit_campfire", "color": Color(0.6, 0.3, 0.25),
		"floors": ["rest", "boss"], "min_floor": 50, "max_floor": 9999, "near": "campfire",
		"if": { "route_locked": &"villain" },
		"recruit": {
			"class_id": &"warrior", "meet": "campfire", "personal_skill": &"red_ruin",
			"build": { Stats.Type.STRENGTH: 6, Stats.Type.HEALTH: 3, Stats.Type.AGILITY: 1 },
			"pitch": "You told gods to their faces you'd take it all. I've killed for worse reasons. You feed me fights, I won't ask what they're for.",
			"loyalty": { "title": "Ulfar: A Good Death", "desc": "Ulfar's still looking for something that can kill him.",
				"steps": [{ "text": "Defeat 50 enemies", "goal": { "type": "defeat", "any": true, "count": 50 } }] },
		},
		"values": { "likes": [&"villain"], "dislikes": [&"hero"] },
	},
	&"wren": {
		"name": "Wren", "kind": "npc", "dialogue": &"recruit_campfire", "color": Color(0.5, 0.55, 0.45),
		"floors": ["rest"], "min_floor": 15, "max_floor": 9999, "near": "campfire",
		"recruit": {
			"class_id": &"rogue", "meet": "campfire", "personal_skill": &"light_fingers",
			"build": { Stats.Type.AGILITY: 5, Stats.Type.LUCK: 3, Stats.Type.STRENGTH: 2 },
			"pitch": "You probably don't remember me. Floor 6 or 7, bleeding on a wall. I've gotten better at not getting caught.",
			"pitch_if": [
				{ "if": { "flag": &"ch1_thief_helped" }, "pitch": "You patched me up, floor 6 or 7, when I'd robbed half the camp. Nobody does that. I don't know what to do about it, so I thought I'd follow you around." },
				{ "if": { "flag": &"ch1_thief_robbed" }, "pitch": "You took my pouch and left me bleeding on floor 6. Best lesson I ever had. I'm better now. I'd rather be standing behind you than in front of you." },
				{ "if": { "flag": &"ch1_thief_judged" }, "pitch": "You marched me back down a floor to give it all back. I hated you for a month. Then one of them thanked me. I don't know what you did to me, but I've got nowhere else to be." },
			],
			"loyalty": { "title": "Wren: Giving It Back", "desc": "Wren's trying to work out who that pouch belonged to.",
				"steps": [{ "text": "Defeat 30 enemies", "goal": { "type": "defeat", "any": true, "count": 30 } }] },
		},
		"values": { "likes": [&"vigilante"], "dislikes": [] },
	},
	&"tobin": {
		"name": "Tobin", "kind": "npc", "dialogue": &"recruit_hire", "color": Color(0.75, 0.85, 0.8),
		"floors": ["rest"], "min_floor": 15, "max_floor": 9999, "near": "merchant",
		"recruit": {
			"class_id": &"support", "meet": "hire", "personal_skill": &"field_medicine", "fee": 800,
			"build": { Stats.Type.INTELLIGENCE: 5, Stats.Type.HEALTH: 3, Stats.Type.STAMINA: 2 },
			"pitch": "Eight hundred gold, and I keep your people alive. I don't care what you do with them after. I've patched up saints and butchers, and they bleed the same.",
			"loyalty": { "title": "Tobin: The Bill", "desc": "Tobin has unpaid invoices on every floor. Help him collect.",
				"steps": [{ "text": "Defeat 2 minibosses", "goal": { "type": "defeat", "kind": "miniboss", "count": 2 } }] },
		},
		"values": { "likes": [&"vigilante"], "dislikes": [] },
	},
	&"ines": {
		"name": "Ines", "kind": "npc", "dialogue": &"recruit_campfire", "color": Color(0.5, 0.65, 0.6),
		"floors": ["rest", "boss"], "min_floor": 50, "max_floor": 9999, "near": "campfire",
		"if": { "route_locked": &"vigilante" },
		"recruit": {
			"class_id": &"archer", "meet": "campfire", "personal_skill": &"named_arrow",
			"build": { Stats.Type.AGILITY: 5, Stats.Type.STRENGTH: 3, Stats.Type.LUCK: 2 },
			"pitch": "You told them they'd answer for it. I've got a list too, and it's mostly the same names. Every arrow I've got has someone's name on it. I've got a few to spare.",
			"loyalty": { "title": "Ines: Every Name", "desc": "Ines has one name left she can't find.",
				"steps": [{ "text": "Defeat 1 bosses", "goal": { "type": "defeat", "kind": "boss", "count": 1 } }] },
		},
		"values": { "likes": [&"vigilante"], "dislikes": [] },
	},
	&"bren": {
		"name": "Bren", "kind": "npc", "dialogue": &"recruit_campfire", "color": Color(0.6, 0.45, 0.55),
		"floors": ["rest", "boss"], "min_floor": 50, "max_floor": 9999, "near": "campfire",
		"if": { "route_locked": &"vigilante" },
		"recruit": {
			"class_id": &"spellblade", "meet": "campfire", "personal_skill": &"sentence_passed",
			"build": { Stats.Type.STRENGTH: 4, Stats.Type.INTELLIGENCE: 4, Stats.Type.HEALTH: 2 },
			"pitch": "I was a judge, on floor 12, back when anyone cared. Then the guild bought the court. If you're serious about making them answer, you'll want somebody who knows how the sentences go.",
			"loyalty": { "title": "Bren: The Court Reopens", "desc": "Bren wants the floor 12 court to sit once more.",
				"steps": [{ "text": "Defeat 40 enemies", "goal": { "type": "defeat", "any": true, "count": 40 } }] },
		},
		"values": { "likes": [&"vigilante"], "dislikes": [] },
	},
	&"brakka": {
		"name": "Brakka", "kind": "npc", "dialogue": &"brakka", "color": Color(0.85, 0.55, 0.3),
		"floors": ["rest"], "min_floor": 5, "max_floor": 9999, "near": "campfire",
		"recruit": {
			"class_id": &"tank", "meet": "campfire", "personal_skill": &"thunder_charge",
			"build": { Stats.Type.HEALTH: 4, Stats.Type.STAMINA: 4, Stats.Type.STRENGTH: 3 },
			"loyalty": { "title": "Brakka: Worthy of Thunder", "desc": "Brakka wants to prove Thor chose well.",
				"steps": [{ "text": "Defeat 2 minibosses with Brakka", "goal": { "type": "defeat", "kind": "miniboss", "count": 2 } }] },
		},
		# Routes he likes / won't stand for (placeholder). See GameState routes.
		"values": { "likes": [&"hero"], "dislikes": [&"villain"] },
		# NPCs can be blessed too (personality): [being id, level].
		"blessing": [&"thor", 1],
	},
	# =====================================================
	# Recruits (Hayden's roster 2026-10-25). Names follow each one's origin.
	# All text is placeholder for the story phase.
	# =====================================================
	&"tamsin": {
		"name": "Tamsin", "kind": "npc", "color": Color(0.45, 0.7, 0.4), "floors": [],
		"recruit": {
			"class_id": &"archer", "meet": "rescue", "rescue_floors": [2, 6], "personal_skill": &"hunters_mark",
			"build": { Stats.Type.AGILITY: 5, Stats.Type.STRENGTH: 3, Stats.Type.LUCK: 2 },
			"pitch": "You came out of nowhere. I owe you one.",
			"loyalty": { "title": "Tamsin: A Debt Repaid", "desc": "Tamsin won't rest until she's paid you back in kind.",
				"steps": [{ "text": "Defeat 25 enemies", "goal": { "type": "defeat", "any": true, "count": 25 } }] },
		},
		"values": { "likes": [&"vigilante"], "dislikes": [&"villain"] },
	},
	&"daphne": {
		"name": "Daphne", "kind": "npc", "dialogue": &"recruit_favor", "color": Color(0.9, 0.9, 0.75),
		"floors": ["rest"], "min_floor": 5, "max_floor": 9999, "near": "campfire",
		"recruit": {
			"class_id": &"support", "meet": "favor", "personal_skill": &"saints_hymn",
			"build": { Stats.Type.INTELLIGENCE: 5, Stats.Type.HEALTH: 3, Stats.Type.STAMINA: 2 },
			"pitch": "The goddess of wisdom sent me to tend the climbers. Help the wounded first, then we'll talk.",
			"favor": { "title": "Daphne: Clear the Way", "desc": "Monsters keep the wounded from reaching her fire.",
				"steps": [{ "text": "Defeat 8 enemies", "goal": { "type": "defeat", "any": true, "count": 8 } }] },
			"loyalty": { "title": "Daphne: The Pilgrimage", "desc": "Daphne made a vow to see the upper floors.",
				"steps": [{ "text": "Reach floor 20", "goal": { "type": "reach", "floor": 20 } }] },
		},
		"values": { "likes": [&"hero"], "dislikes": [&"villain"] },
		"blessing": [&"athena", 1],
	},
	&"garrick": {
		"name": "Garrick", "kind": "npc", "dialogue": &"recruit_hire", "color": Color(0.5, 0.45, 0.4),
		"floors": ["rest"], "min_floor": 15, "max_floor": 9999, "near": "merchant",
		"recruit": {
			"class_id": &"rogue", "meet": "hire", "fee": 600, "personal_skill": &"dirty_work",
			"build": { Stats.Type.AGILITY: 4, Stats.Type.STRENGTH: 4, Stats.Type.LUCK: 2 },
			"pitch": "My blade's for hire. Six hundred gold and I'm yours, no questions.",
			"loyalty": { "title": "Garrick: The Big Score", "desc": "Garrick has heard a roaming beast guards a fortune.",
				"steps": [{ "text": "Defeat a roaming boss", "goal": { "type": "defeat", "kind": "roaming", "count": 1 } }] },
		},
		"values": { "likes": [&"villain"], "dislikes": [&"hero"] },
	},
	&"rook": {
		"name": "Rook", "kind": "npc", "dialogue": &"recruit_favor", "color": Color(0.35, 0.5, 0.3),
		"floors": ["rest"], "min_floor": 20, "max_floor": 9999, "near": "campfire",
		"recruit": {
			"class_id": &"archer", "meet": "favor", "personal_skill": &"rain_of_thorns",
			"build": { Stats.Type.AGILITY: 5, Stats.Type.STRENGTH: 3, Stats.Type.LUCK: 2 },
			"pitch": "I don't climb with people I haven't seen fight. Take down one of the big ones.",
			"favor": { "title": "Rook: Prove It", "desc": "Rook wants to see you beat a guardian.",
				"steps": [{ "text": "Defeat a miniboss", "goal": { "type": "defeat", "kind": "miniboss", "count": 1 } }] },
			"loyalty": { "title": "Rook: The Long Hunt", "desc": "Rook keeps a tally. Help him fill it.",
				"steps": [{ "text": "Defeat 30 enemies", "goal": { "type": "defeat", "any": true, "count": 30 } }] },
		},
		"values": { "likes": [&"vigilante"], "dislikes": [&"hero"] },
	},
	&"sigrun": {
		"name": "Sigrun", "kind": "npc", "color": Color(0.75, 0.8, 0.95), "floors": [],
		"recruit": {
			"class_id": &"tank", "meet": "captive", "captive_of": &"moonfang", "personal_skill": &"valkyries_shield",
			"build": { Stats.Type.HEALTH: 4, Stats.Type.STAMINA: 4, Stats.Type.STRENGTH: 3 },
			"pitch": "The Trickster's wolf kept me as a trophy. Odin will hear of this.",
			"loyalty": { "title": "Sigrun: The Allfather's Due", "desc": "Sigrun owes Odin a great deed.",
				"steps": [{ "text": "Defeat a stage boss", "goal": { "type": "defeat", "kind": "boss", "count": 1 } }] },
		},
		"values": { "likes": [&"hero"], "dislikes": [&"villain"] },
		"blessing": [&"odin", 1],
	},
	&"neferet": {
		"name": "Neferet", "kind": "npc", "color": Color(1.0, 0.85, 0.4), "floors": [],
		"recruit": {
			"class_id": &"mage", "meet": "captive", "captive_of": &"hive_queen", "personal_skill": &"solar_flare",
			"build": { Stats.Type.INTELLIGENCE: 6, Stats.Type.HEALTH: 2, Stats.Type.STAMINA: 2 },
			"pitch": "The Serpent's queen walled me in her hive to keep Ra's light out. Thank you.",
			"loyalty": { "title": "Neferet: Light in the Dark", "desc": "Neferet must carry Ra's light higher.",
				"steps": [{ "text": "Defeat a stage boss", "goal": { "type": "defeat", "kind": "boss", "count": 1 } }] },
		},
		"values": { "likes": [&"hero"], "dislikes": [&"villain"] },
		"blessing": [&"ra", 1],
	},
	&"lysander": {
		"name": "Lysander", "kind": "npc", "color": Color(0.8, 0.85, 1.0), "floors": [],
		"recruit": {
			"class_id": &"support", "meet": "captive", "captive_of": &"necromancer", "personal_skill": &"thunder_oath",
			"build": { Stats.Type.INTELLIGENCE: 5, Stats.Type.HEALTH: 3, Stats.Type.STRENGTH: 2 },
			"pitch": "Hades' servant meant to keep Zeus' priest in the dark forever. Not today.",
			"loyalty": { "title": "Lysander: The King's Oath", "desc": "Lysander's oath demands a victory worthy of Zeus.",
				"steps": [{ "text": "Defeat a stage boss", "goal": { "type": "defeat", "kind": "boss", "count": 1 } }] },
		},
		"values": { "likes": [&"hero"], "dislikes": [&"vigilante"] },
		"blessing": [&"zeus", 1],
	},
	&"shamira": {
		"name": "Shamira", "kind": "npc", "color": Color(0.85, 0.5, 0.6), "floors": [],
		"recruit": {
			"class_id": &"rogue", "meet": "captive", "captive_of": &"dragon_sovereign", "personal_skill": &"lions_grace",
			"build": { Stats.Type.AGILITY: 4, Stats.Type.STRENGTH: 4, Stats.Type.LUCK: 2 },
			"pitch": "The Mother of Chaos' dragon caged Ishtar's champion like a jewel. Let's make it pay.",
			"loyalty": { "title": "Shamira: Ishtar's Fury", "desc": "Shamira wants to see the tower's crown fall.",
				"steps": [{ "text": "Reach the top of the tower", "goal": { "type": "reach", "floor": 60 } }] },
		},
		"values": { "likes": [&"vigilante"], "dislikes": [&"hero"] },
		"blessing": [&"ishtar", 1],
	},
	&"old_fenn": {
		"name": "Old Fenn", "kind": "npc", "dialogue": &"recruit_campfire", "color": Color(0.6, 0.55, 0.5),
		"floors": ["rest"], "min_floor": 25, "max_floor": 9999, "near": "campfire", "run_chance": 0.5,
		"recruit": {
			"class_id": &"tank", "meet": "campfire", "personal_skill": &"stand_firm",
			"build": { Stats.Type.HEALTH: 5, Stats.Type.STAMINA: 4, Stats.Type.STRENGTH: 2 },
			"pitch": "Climbed this tower forty years ago. Never made the top. Got room for an old man?",
			"loyalty": { "title": "Old Fenn: One Last Climb", "desc": "Fenn wants to stand higher than he ever did.",
				"steps": [{ "text": "Reach floor 45", "goal": { "type": "reach", "floor": 45 } }] },
		},
		"values": { "likes": [&"vigilante"], "dislikes": [&"villain"] },
	},
	&"kael": {
		"name": "Kael", "kind": "npc", "color": Color(0.3, 0.3, 0.4), "floors": [], "run_chance": 0.5,
		"recruit": {
			"class_id": &"rogue", "meet": "rescue", "rescue_floors": [30, 38], "personal_skill": &"shadowstep",
			"build": { Stats.Type.AGILITY: 5, Stats.Type.STRENGTH: 3, Stats.Type.LUCK: 2 },
			"pitch": "I had it handled. ...Fine. Thanks.",
			"loyalty": { "title": "Kael: Unfinished Business", "desc": "Kael has a score to settle with the guardians.",
				"steps": [{ "text": "Defeat 2 minibosses", "goal": { "type": "defeat", "kind": "miniboss", "count": 2 } }] },
		},
		"values": { "likes": [&"villain"], "dislikes": [&"hero"] },
	},
	&"vesna": {
		"name": "Vesna", "kind": "npc", "dialogue": &"recruit_hire", "color": Color(0.6, 0.8, 0.95),
		"floors": ["rest"], "min_floor": 35, "max_floor": 9999, "near": "merchant", "run_chance": 0.5,
		"recruit": {
			"class_id": &"mage", "meet": "hire", "fee": 1500, "personal_skill": &"frost_nova",
			"build": { Stats.Type.INTELLIGENCE: 6, Stats.Type.HEALTH: 2, Stats.Type.STAMINA: 2 },
			"pitch": "Fifteen hundred gold. Winter doesn't come cheap.",
			"loyalty": { "title": "Vesna: Deep Winter", "desc": "Vesna wants to test her frost on the worst the tower has.",
				"steps": [{ "text": "Defeat 30 enemies", "goal": { "type": "defeat", "any": true, "count": 30 } }] },
		},
		"values": { "likes": [&"villain"], "dislikes": [&"hero"] },
	},

	# =====================================================
	# Demigods (Hayden 2026-10-25): rare, floor 30+, only when one of your
	# patrons (blessing / guild patron) is from their pantheon. A legendary
	# quest chain earns them; each has a class only they can have.
	# =====================================================
	&"heracles": {
		"name": "Heracles", "kind": "npc", "dialogue": &"recruit_legend", "color": Color(1.0, 0.85, 0.35),
		"floors": ["rest"], "min_floor": 30, "max_floor": 9999, "near": "campfire", "run_chance": 0.35,
		"if": { "patron_pantheon": "Greek" },
		"recruit": {
			"class_id": &"lionheart", "meet": "legend", "demigod": true, "personal_skill": &"nemean_roar",
			"build": { Stats.Type.STRENGTH: 5, Stats.Type.HEALTH: 4, Stats.Type.STAMINA: 2 },
			"pitch": "Twelve labours, and the gods still want a thirteenth. Prove you can keep up.",
			"favor": { "title": "Legend: Heracles", "desc": "The gods want proof before Heracles will follow you.",
				"steps": [
					{ "text": "Defeat 2 minibosses", "goal": { "type": "defeat", "kind": "miniboss", "count": 2 } },
					{ "text": "Defeat a stage boss", "goal": { "type": "defeat", "kind": "boss", "count": 1 } },
				] },
			"loyalty": { "title": "Heracles: The Last Labour", "desc": "A demigod's legend needs one more great deed.",
				"steps": [{ "text": "Defeat 2 stage bosses", "goal": { "type": "defeat", "kind": "boss", "count": 2 } }] },
		},
		"values": { "likes": [&"hero"], "dislikes": [&"villain"] },
		"blessing": [&"zeus", 2],
	},
	&"perseus": {
		"name": "Perseus", "kind": "npc", "dialogue": &"recruit_legend", "color": Color(1.0, 0.85, 0.35),
		"floors": ["rest"], "min_floor": 30, "max_floor": 9999, "near": "campfire", "run_chance": 0.35,
		"if": { "patron_pantheon": "Greek" },
		"recruit": {
			"class_id": &"gorgonbane", "meet": "legend", "demigod": true, "personal_skill": &"winged_sandals",
			"build": { Stats.Type.AGILITY: 5, Stats.Type.STRENGTH: 4, Stats.Type.LUCK: 2 },
			"pitch": "Athena told me a climber would come. Show me you are the one.",
			"favor": { "title": "Legend: Perseus", "desc": "The gods want proof before Perseus will follow you.",
				"steps": [
					{ "text": "Defeat 2 minibosses", "goal": { "type": "defeat", "kind": "miniboss", "count": 2 } },
					{ "text": "Defeat a stage boss", "goal": { "type": "defeat", "kind": "boss", "count": 1 } },
				] },
			"loyalty": { "title": "Perseus: The Last Labour", "desc": "A demigod's legend needs one more great deed.",
				"steps": [{ "text": "Defeat 2 stage bosses", "goal": { "type": "defeat", "kind": "boss", "count": 2 } }] },
		},
		"values": { "likes": [&"hero"], "dislikes": [&"villain"] },
		"blessing": [&"athena", 2],
	},
	&"achilles": {
		"name": "Achilles", "kind": "npc", "dialogue": &"recruit_legend", "color": Color(1.0, 0.85, 0.35),
		"floors": ["rest"], "min_floor": 30, "max_floor": 9999, "near": "campfire", "run_chance": 0.35,
		"if": { "patron_pantheon": "Greek" },
		"recruit": {
			"class_id": &"myrmidon_lord", "meet": "legend", "demigod": true, "personal_skill": &"heel_guard",
			"build": { Stats.Type.AGILITY: 5, Stats.Type.HEALTH: 4, Stats.Type.STRENGTH: 2 },
			"pitch": "Glory or nothing. If you want me at your side, earn it.",
			"favor": { "title": "Legend: Achilles", "desc": "The gods want proof before Achilles will follow you.",
				"steps": [
					{ "text": "Defeat 2 minibosses", "goal": { "type": "defeat", "kind": "miniboss", "count": 2 } },
					{ "text": "Defeat a stage boss", "goal": { "type": "defeat", "kind": "boss", "count": 1 } },
				] },
			"loyalty": { "title": "Achilles: The Last Labour", "desc": "A demigod's legend needs one more great deed.",
				"steps": [{ "text": "Defeat 2 stage bosses", "goal": { "type": "defeat", "kind": "boss", "count": 2 } }] },
		},
		"values": { "likes": [&"vigilante"], "dislikes": [&"hero"] },
	},
	&"gilgamesh": {
		"name": "Gilgamesh", "kind": "npc", "dialogue": &"recruit_legend", "color": Color(1.0, 0.85, 0.35),
		"floors": ["rest"], "min_floor": 30, "max_floor": 9999, "near": "campfire", "run_chance": 0.35,
		"if": { "patron_pantheon": "Mesopotamian" },
		"recruit": {
			"class_id": &"king_of_uruk", "meet": "legend", "demigod": true, "personal_skill": &"gate_of_uruk",
			"build": { Stats.Type.STRENGTH: 5, Stats.Type.LUCK: 4, Stats.Type.HEALTH: 2 },
			"pitch": "A king does not follow. But he may walk beside someone worth watching.",
			"favor": { "title": "Legend: Gilgamesh", "desc": "The gods want proof before Gilgamesh will follow you.",
				"steps": [
					{ "text": "Defeat 2 minibosses", "goal": { "type": "defeat", "kind": "miniboss", "count": 2 } },
					{ "text": "Defeat a stage boss", "goal": { "type": "defeat", "kind": "boss", "count": 1 } },
				] },
			"loyalty": { "title": "Gilgamesh: The Last Labour", "desc": "A demigod's legend needs one more great deed.",
				"steps": [{ "text": "Defeat 2 stage bosses", "goal": { "type": "defeat", "kind": "boss", "count": 2 } }] },
		},
		"values": { "likes": [&"villain"], "dislikes": [&"hero"] },
	},
	&"cu_chulainn": {
		"name": "Cu Chulainn", "kind": "npc", "dialogue": &"recruit_legend", "color": Color(1.0, 0.85, 0.35),
		"floors": ["rest"], "min_floor": 30, "max_floor": 9999, "near": "campfire", "run_chance": 0.35,
		"if": { "patron_pantheon": "Celtic" },
		"recruit": {
			"class_id": &"hound_of_ulster", "meet": "legend", "demigod": true, "personal_skill": &"spear_storm",
			"build": { Stats.Type.STRENGTH: 5, Stats.Type.AGILITY: 4, Stats.Type.HEALTH: 2 },
			"pitch": "The Phantom Queen sent her crows to find you. Let us see why.",
			"favor": { "title": "Legend: Cu Chulainn", "desc": "The gods want proof before Cu Chulainn will follow you.",
				"steps": [
					{ "text": "Defeat 2 minibosses", "goal": { "type": "defeat", "kind": "miniboss", "count": 2 } },
					{ "text": "Defeat a stage boss", "goal": { "type": "defeat", "kind": "boss", "count": 1 } },
				] },
			"loyalty": { "title": "Cu Chulainn: The Last Labour", "desc": "A demigod's legend needs one more great deed.",
				"steps": [{ "text": "Defeat 2 stage bosses", "goal": { "type": "defeat", "kind": "boss", "count": 2 } }] },
		},
		"values": { "likes": [&"vigilante"], "dislikes": [&"villain"] },
		"blessing": [&"morrigan", 2],
	},
	&"sigurd": {
		"name": "Sigurd", "kind": "npc", "dialogue": &"recruit_legend", "color": Color(1.0, 0.85, 0.35),
		"floors": ["rest"], "min_floor": 30, "max_floor": 9999, "near": "campfire", "run_chance": 0.35,
		"if": { "patron_pantheon": "Norse" },
		"recruit": {
			"class_id": &"dragonslayer", "meet": "legend", "demigod": true, "personal_skill": &"birdspeech",
			"build": { Stats.Type.STRENGTH: 5, Stats.Type.STAMINA: 4, Stats.Type.HEALTH: 2 },
			"pitch": "The birds say a climber means to reach the top. I have killed a dragon. Can you?",
			"favor": { "title": "Legend: Sigurd", "desc": "The gods want proof before Sigurd will follow you.",
				"steps": [
					{ "text": "Defeat 2 minibosses", "goal": { "type": "defeat", "kind": "miniboss", "count": 2 } },
					{ "text": "Defeat a stage boss", "goal": { "type": "defeat", "kind": "boss", "count": 1 } },
				] },
			"loyalty": { "title": "Sigurd: The Last Labour", "desc": "A demigod's legend needs one more great deed.",
				"steps": [{ "text": "Defeat 2 stage bosses", "goal": { "type": "defeat", "kind": "boss", "count": 2 } }] },
		},
		"values": { "likes": [&"hero"], "dislikes": [&"villain"] },
		"blessing": [&"odin", 2],
	},
	# Added 2026-10-25 (Hayden's picks)
	&"theseus": {
		"name": "Theseus", "kind": "npc", "dialogue": &"recruit_legend", "color": Color(1.0, 0.85, 0.35),
		"floors": ["rest"], "min_floor": 30, "max_floor": 9999, "near": "campfire", "run_chance": 0.35,
		"if": { "patron_pantheon": "Greek" },
		"recruit": {
			"class_id": &"labyrinth_hero", "meet": "legend", "demigod": true, "personal_skill": &"ariadnes_thread",
			"build": { Stats.Type.AGILITY: 5, Stats.Type.STRENGTH: 4, Stats.Type.LUCK: 2 },
			"pitch": "I walked into the labyrinth and came back out. This tower is just a taller maze.",
			"favor": { "title": "Legend: Theseus", "desc": "The gods want proof before Theseus will follow you.",
				"steps": [
					{ "text": "Defeat 2 minibosses", "goal": { "type": "defeat", "kind": "miniboss", "count": 2 } },
					{ "text": "Defeat a stage boss", "goal": { "type": "defeat", "kind": "boss", "count": 1 } },
				] },
			"loyalty": { "title": "Theseus: The Last Deed", "desc": "A demigod's legend needs one more great deed.",
				"steps": [{ "text": "Defeat 2 stage bosses", "goal": { "type": "defeat", "kind": "boss", "count": 2 } }] },
		},
		"values": { "likes": [&"hero"], "dislikes": [&"villain"] },
		"blessing": [&"athena", 1],
	},
	&"hippolyta": {
		"name": "Hippolyta", "kind": "npc", "dialogue": &"recruit_legend", "color": Color(1.0, 0.85, 0.35),
		"floors": ["rest"], "min_floor": 30, "max_floor": 9999, "near": "campfire", "run_chance": 0.35,
		"if": { "patron_pantheon": "Greek" },
		"recruit": {
			"class_id": &"amazon_queen", "meet": "legend", "demigod": true, "personal_skill": &"girdle_of_ares",
			"build": { Stats.Type.STRENGTH: 5, Stats.Type.HEALTH: 4, Stats.Type.AGILITY: 2 },
			"pitch": "My warriors follow strength, not titles. Show me yours.",
			"favor": { "title": "Legend: Hippolyta", "desc": "The gods want proof before Hippolyta will follow you.",
				"steps": [
					{ "text": "Defeat 2 minibosses", "goal": { "type": "defeat", "kind": "miniboss", "count": 2 } },
					{ "text": "Defeat a stage boss", "goal": { "type": "defeat", "kind": "boss", "count": 1 } },
				] },
			"loyalty": { "title": "Hippolyta: The Last Deed", "desc": "A demigod's legend needs one more great deed.",
				"steps": [{ "text": "Defeat 2 stage bosses", "goal": { "type": "defeat", "kind": "boss", "count": 2 } }] },
		},
		"values": { "likes": [&"vigilante"], "dislikes": [&"villain"] },
	},
	&"orpheus": {
		"name": "Orpheus", "kind": "npc", "dialogue": &"recruit_legend", "color": Color(1.0, 0.85, 0.35),
		"floors": ["rest"], "min_floor": 30, "max_floor": 9999, "near": "campfire", "run_chance": 0.35,
		"if": { "patron_pantheon": "Greek" },
		"recruit": {
			"class_id": &"songweaver", "meet": "legend", "demigod": true, "personal_skill": &"charm_of_hades",
			"build": { Stats.Type.INTELLIGENCE: 5, Stats.Type.LUCK: 4, Stats.Type.HEALTH: 2 },
			"pitch": "I sang my way out of the underworld once. A tower should be easier.",
			"favor": { "title": "Legend: Orpheus", "desc": "The gods want proof before Orpheus will follow you.",
				"steps": [
					{ "text": "Defeat 2 minibosses", "goal": { "type": "defeat", "kind": "miniboss", "count": 2 } },
					{ "text": "Defeat a stage boss", "goal": { "type": "defeat", "kind": "boss", "count": 1 } },
				] },
			"loyalty": { "title": "Orpheus: The Last Deed", "desc": "A demigod's legend needs one more great deed.",
				"steps": [{ "text": "Defeat 2 stage bosses", "goal": { "type": "defeat", "kind": "boss", "count": 2 } }] },
		},
		"values": { "likes": [&"hero"], "dislikes": [&"villain"] },
	},
	&"atalanta": {
		"name": "Atalanta", "kind": "npc", "dialogue": &"recruit_legend", "color": Color(1.0, 0.85, 0.35),
		"floors": ["rest"], "min_floor": 30, "max_floor": 9999, "near": "campfire", "run_chance": 0.35,
		"if": { "patron_pantheon": "Greek" },
		"recruit": {
			"class_id": &"swift_huntress", "meet": "legend", "demigod": true, "personal_skill": &"golden_apple",
			"build": { Stats.Type.AGILITY: 5, Stats.Type.LUCK: 4, Stats.Type.STRENGTH: 2 },
			"pitch": "Race me to the next stairs. If you keep up, I'll climb with you.",
			"favor": { "title": "Legend: Atalanta", "desc": "The gods want proof before Atalanta will follow you.",
				"steps": [
					{ "text": "Defeat 2 minibosses", "goal": { "type": "defeat", "kind": "miniboss", "count": 2 } },
					{ "text": "Defeat a stage boss", "goal": { "type": "defeat", "kind": "boss", "count": 1 } },
				] },
			"loyalty": { "title": "Atalanta: The Last Deed", "desc": "A demigod's legend needs one more great deed.",
				"steps": [{ "text": "Defeat 2 stage bosses", "goal": { "type": "defeat", "kind": "boss", "count": 2 } }] },
		},
		"values": { "likes": [&"vigilante"], "dislikes": [&"villain"] },
	},
	&"enkidu": {
		"name": "Enkidu", "kind": "npc", "dialogue": &"recruit_legend", "color": Color(1.0, 0.85, 0.35),
		"floors": ["rest"], "min_floor": 30, "max_floor": 9999, "near": "campfire", "run_chance": 0.35,
		"if": { "patron_pantheon": "Mesopotamian" },
		"recruit": {
			"class_id": &"wild_man", "meet": "legend", "demigod": true, "personal_skill": &"brothers_oath",
			"build": { Stats.Type.STRENGTH: 5, Stats.Type.HEALTH: 4, Stats.Type.STAMINA: 2 },
			"pitch": "The gods made me from clay to be someone's equal. Let's see if you are.",
			"favor": { "title": "Legend: Enkidu", "desc": "The gods want proof before Enkidu will follow you.",
				"steps": [
					{ "text": "Defeat 2 minibosses", "goal": { "type": "defeat", "kind": "miniboss", "count": 2 } },
					{ "text": "Defeat a stage boss", "goal": { "type": "defeat", "kind": "boss", "count": 1 } },
				] },
			"loyalty": { "title": "Enkidu: The Last Deed", "desc": "A demigod's legend needs one more great deed.",
				"steps": [{ "text": "Defeat 2 stage bosses", "goal": { "type": "defeat", "kind": "boss", "count": 2 } }] },
		},
		"values": { "likes": [&"vigilante"], "dislikes": [&"villain"] },
	},
	&"fionn": {
		"name": "Fionn mac Cumhaill", "kind": "npc", "dialogue": &"recruit_legend", "color": Color(1.0, 0.85, 0.35),
		"floors": ["rest"], "min_floor": 30, "max_floor": 9999, "near": "campfire", "run_chance": 0.35,
		"if": { "patron_pantheon": "Celtic" },
		"recruit": {
			"class_id": &"fianna_captain", "meet": "legend", "demigod": true, "personal_skill": &"thumb_of_knowledge",
			"build": { Stats.Type.STRENGTH: 4, Stats.Type.INTELLIGENCE: 4, Stats.Type.AGILITY: 3 },
			"pitch": "One taste of the salmon and I knew everything. Including that you'd come.",
			"favor": { "title": "Legend: Fionn mac Cumhaill", "desc": "The gods want proof before Fionn mac Cumhaill will follow you.",
				"steps": [
					{ "text": "Defeat 2 minibosses", "goal": { "type": "defeat", "kind": "miniboss", "count": 2 } },
					{ "text": "Defeat a stage boss", "goal": { "type": "defeat", "kind": "boss", "count": 1 } },
				] },
			"loyalty": { "title": "Fionn mac Cumhaill: The Last Deed", "desc": "A demigod's legend needs one more great deed.",
				"steps": [{ "text": "Defeat 2 stage bosses", "goal": { "type": "defeat", "kind": "boss", "count": 2 } }] },
		},
		"values": { "likes": [&"hero"], "dislikes": [&"villain"] },
	},
	&"momotaro": {
		"name": "Momotaro", "kind": "npc", "dialogue": &"recruit_legend", "color": Color(1.0, 0.85, 0.35),
		"floors": ["rest"], "min_floor": 30, "max_floor": 9999, "near": "campfire", "run_chance": 0.35,
		"if": { "patron_pantheon": "Japanese" },
		"recruit": {
			"class_id": &"oni_slayer", "meet": "legend", "demigod": true, "personal_skill": &"kibi_dango",
			"build": { Stats.Type.STRENGTH: 5, Stats.Type.AGILITY: 4, Stats.Type.HEALTH: 2 },
			"pitch": "My dog, my monkey and my pheasant say you're trustworthy. They're usually right.",
			"favor": { "title": "Legend: Momotaro", "desc": "The gods want proof before Momotaro will follow you.",
				"steps": [
					{ "text": "Defeat 2 minibosses", "goal": { "type": "defeat", "kind": "miniboss", "count": 2 } },
					{ "text": "Defeat a stage boss", "goal": { "type": "defeat", "kind": "boss", "count": 1 } },
				] },
			"loyalty": { "title": "Momotaro: The Last Deed", "desc": "A demigod's legend needs one more great deed.",
				"steps": [{ "text": "Defeat 2 stage bosses", "goal": { "type": "defeat", "kind": "boss", "count": 2 } }] },
		},
		"values": { "likes": [&"hero"], "dislikes": [&"villain"] },
	},
	&"bellerophon": {
		"name": "Bellerophon", "kind": "npc", "dialogue": &"recruit_legend", "color": Color(1.0, 0.85, 0.35),
		"floors": ["rest"], "min_floor": 30, "max_floor": 9999, "near": "campfire", "run_chance": 0.35,
		"if": { "patron_pantheon": "Greek" },
		"recruit": {
			"class_id": &"sky_lancer", "meet": "legend", "demigod": true, "personal_skill": &"wings_of_pegasus",
			"build": { Stats.Type.AGILITY: 5, Stats.Type.STRENGTH: 4, Stats.Type.STAMINA: 2 },
			"pitch": "Pegasus doesn't like stairs. Lucky for you, I do.",
			"favor": { "title": "Legend: Bellerophon", "desc": "The gods want proof before Bellerophon will follow you.",
				"steps": [
					{ "text": "Defeat 2 minibosses", "goal": { "type": "defeat", "kind": "miniboss", "count": 2 } },
					{ "text": "Defeat a stage boss", "goal": { "type": "defeat", "kind": "boss", "count": 1 } },
				] },
			"loyalty": { "title": "Bellerophon: The Last Deed", "desc": "A demigod's legend needs one more great deed.",
				"steps": [{ "text": "Defeat 2 stage bosses", "goal": { "type": "defeat", "kind": "boss", "count": 2 } }] },
		},
		"values": { "likes": [&"hero"], "dislikes": [&"villain"] },
		"blessing": [&"athena", 1],
	},

	# --- Route content (placeholders) ---
	&"black_market": {
		"name": "Hooded trader", "kind": "npc", "dialogue": &"black_market", "color": Color(0.25, 0.2, 0.3),
		"floors": ["rest", "boss"], "min_floor": 5, "max_floor": 9999, "near": "merchant",
		"if": { "route": &"villain" },
	},
	&"captured_bandit": {
		"name": "Captured bandit", "kind": "npc", "dialogue": &"captured_bandit", "color": Color(0.6, 0.5, 0.35),
		"floors": ["boss"], "min_floor": 10, "max_floor": 9999, "gone_flag": &"bandit_judged",
	},
	&"crossroads_shrine": {
		"name": "Crossroads shrine", "kind": "object", "dialogue": &"crossroads_shrine", "color": Color(0.85, 0.85, 0.95),
		"floors": ["rest"], "min_floor": 15, "max_floor": 9999,
		"if": { "route_locked": false },
	},
	# A hint about the current stage's enemies, on some normal floors.
	&"warning_scrawl": {
		"name": "Scratched warning", "kind": "object", "dialogue": &"warning_scrawl",
		"color": Color(0.45, 0.45, 0.4),
		"floors": ["combat"], "min_floor": 2, "max_floor": 9999, "chance": 0.2,
	},
	# Quest from a found item: a torn map on early floors (until you've picked
	# it up), and the cache it points to once you're on that step.
	&"torn_map": {
		"name": "Torn map", "kind": "object", "dialogue": &"torn_map",
		"color": Color(0.8, 0.75, 0.55),
		"floors": ["combat"], "min_floor": 2, "max_floor": 9, "chance": 0.3,
		"if": { "quest_new": &"torn_map" },
	},
	&"hidden_cache": {
		"name": "Loose stone", "kind": "object", "dialogue": &"hidden_cache",
		"color": Color(0.5, 0.5, 0.45),
		"floors": ["combat", "rest"], "min_floor": 6, "max_floor": 9999,
		"if": { "quest_on_step": [&"torn_map", 1] },
	},
	# Ashbound teaser (Hayden 2026-10-25): before the level-10 class choice, so
	# players can plan the build. Not one of the 3 clues.
	&"ash_carving": {
		"name": "Burnt sword", "kind": "object", "dialogue": &"ash_carving",
		"color": Color(0.45, 0.3, 0.25),
		"floors": ["combat"], "min_floor": 2, "max_floor": 9, "chance": 0.5,
		"gone_flag": &"hint_ash_carving",
	},
	# Quest class clues (SecretPaths): the notebook, Marn's ledger, the godless, the seams.
	&"note_page": {
		"name": "Torn page", "kind": "object", "dialogue": &"note_page",
		"color": Color(0.85, 0.85, 0.75),
		"floors": ["combat"], "min_floor": 2, "max_floor": 14, "chance": 0.35,
		"gone_flag": &"clue_note_page",
	},
	&"note_door": {
		"name": "Chalk door", "kind": "object", "dialogue": &"note_door",
		"color": Color(0.8, 0.8, 0.85),
		"floors": ["rest"], "min_floor": 5, "max_floor": 30,
		"gone_flag": &"clue_note_door",
	},
	&"note_name": {
		"name": "Scrawled warning", "kind": "object", "dialogue": &"note_name",
		"color": Color(0.5, 0.5, 0.6),
		"floors": ["combat"], "min_floor": 6, "max_floor": 30, "chance": 0.3,
		"gone_flag": &"clue_note_name",
	},
	&"marn_pack": {
		"name": "Marn's old pack", "kind": "object", "dialogue": &"marn_pack",
		"color": Color(0.5, 0.4, 0.3),
		"floors": ["combat"], "min_floor": 28, "max_floor": 50, "chance": 0.4, "if": { "flag": &"ch3_marn_fell" },
		"gone_flag": &"clue_marn_pack",
	},
	&"marn_fire": {
		"name": "Cold campfire", "kind": "object", "dialogue": &"marn_fire",
		"color": Color(0.3, 0.3, 0.35),
		"floors": ["rest"], "min_floor": 30, "max_floor": 55, "near": "campfire", "if": { "flag": &"ch3_marn_fell" },
		"gone_flag": &"clue_marn_fire",
	},
	&"marn_marks": {
		"name": "Tally marks", "kind": "object", "dialogue": &"marn_marks",
		"color": Color(0.55, 0.5, 0.45),
		"floors": ["combat"], "min_floor": 28, "max_floor": 50, "chance": 0.35, "if": { "flag": &"ch3_marn_fell" },
		"gone_flag": &"clue_marn_marks",
	},
	&"defaced_shrine": {
		"name": "Defaced shrine", "kind": "object", "dialogue": &"defaced_shrine",
		"color": Color(0.6, 0.55, 0.5),
		"floors": ["combat"], "min_floor": 31, "max_floor": 60, "chance": 0.35,
		"gone_flag": &"clue_god_shrine",
	},
	&"tithe_box": {
		"name": "Unpaid tithe box", "kind": "object", "dialogue": &"tithe_box",
		"color": Color(0.7, 0.6, 0.3),
		"floors": ["rest"], "min_floor": 35, "max_floor": 60, "near": "merchant",
		"gone_flag": &"clue_god_tithe",
	},
	&"broken_idol_object": {
		"name": "Broken idol", "kind": "object", "dialogue": &"broken_idol_object",
		"color": Color(0.5, 0.45, 0.55),
		"floors": ["combat"], "min_floor": 36, "max_floor": 60, "chance": 0.3,
		"gone_flag": &"clue_god_idol",
	},
	&"seam_wall": {
		"name": "Flickering wall", "kind": "object", "dialogue": &"seam_wall",
		"color": Color(0.9, 0.3, 0.9),
		"floors": ["combat"], "min_floor": 45, "max_floor": 80, "chance": 0.35,
		"gone_flag": &"clue_seam_wall",
	},
	&"seam_stair": {
		"name": "Stair to nowhere", "kind": "object", "dialogue": &"seam_stair",
		"color": Color(0.6, 0.6, 0.75),
		"floors": ["rest"], "min_floor": 50, "max_floor": 85,
		"gone_flag": &"clue_seam_stair",
	},
	&"seam_note": {
		"name": "Debug note", "kind": "object", "dialogue": &"seam_note",
		"color": Color(0.25, 0.9, 0.35),
		"floors": ["combat"], "min_floor": 45, "max_floor": 85, "chance": 0.3,
		"gone_flag": &"clue_seam_note",
	},
	# Ashbound clue 1 of 3: on normal floors of stage 2 until you've read it.
	&"scorched_mural": {
		"name": "Scorched mural", "kind": "object", "dialogue": &"scorched_mural",
		"color": Color(0.55, 0.3, 0.25),
		"floors": ["combat"], "min_floor": 11, "max_floor": 29, "chance": 0.4,
		"gone_flag": &"clue_ash_scorched_mural",
	},
	# Ashbound clue 3 of 3: in the campfire's embers once the first boss is down.
	&"feather_in_embers": {
		"name": "Glint in the embers", "kind": "object", "dialogue": &"feather_in_embers",
		"color": Color(0.2, 0.2, 0.25),
		"floors": ["rest", "boss"], "min_floor": 10, "max_floor": 29, "near": "campfire",
		"gone_flag": &"clue_ash_feather_in_embers",
	},
}


static func get_npc(id: StringName) -> Dictionary:
	return NPCS.get(id, {})


static func is_recruitable(id: StringName) -> bool:
	return get_npc(id).has("recruit")


## Wanderers ("run_chance") are only in some runs; the roll is fixed per run.
static func in_this_run(id: StringName) -> bool:
	var chance: float = get_npc(id).get("run_chance", 1.0)
	if chance >= 1.0:
		return true
	var rng := RandomNumberGenerator.new()
	rng.seed = ("%s:%d:%s" % [GameState.player.legacy_id, GameState.ng_plus_cycle, id]).hash()
	return rng.randf() < chance


## Recruit ids met a certain way ("campfire", "hire", "favor", "rescue", "captive").
static func recruits_met_by(meet: String) -> Array:
	var out := []
	var ids := NPCS.keys()
	ids.sort_custom(func(a, b): return String(a) < String(b))   # by name (StringNames sort by address)
	for id in ids:
		if NPCS[id].get("recruit", {}).get("meet", "") == meet:
			out.append(id)
	return out


## What this recruit says right now (some remember what you did).
static func pitch_of(id: StringName) -> String:
	var r := recruit_info(id)
	for entry in r.get("pitch_if", []):
		if DialogueRunner.check(entry.if):
			return entry.pitch
	return r.get("pitch", "")


static func recruit_info(id: StringName) -> Dictionary:
	return get_npc(id).get("recruit", {})


## NPCs that belong on this floor right now, in a stable order.
## `floor_kind` is "rest", "boss", "combat" or "miniboss". `rng_for(id)` must
## return a RandomNumberGenerator seeded for that NPC on this floor.
static func npcs_for_floor(floor_n: int, floor_kind: String, rng_for: Callable) -> Array[StringName]:
	var out: Array[StringName] = []
	var ids := NPCS.keys()
	ids.sort_custom(func(a, b): return String(a) < String(b))   # by name (StringNames sort by address)
	for id in ids:
		var n: Dictionary = NPCS[id]
		if not floor_kind in n.get("floors", []):
			continue
		if floor_n < n.get("min_floor", 1) or floor_n > n.get("max_floor", 9999):
			continue
		if n.has("gone_flag") and GameState.has_flag(n.gone_flag):
			continue
		if n.has("recruit") and (GameState.has_recruited(id) or not in_this_run(id)):
			continue
		if not DialogueRunner.check(n.get("if", {})):
			continue
		var rng: RandomNumberGenerator = rng_for.call(id)
		if rng.randf() >= n.get("chance", 1.0):
			continue
		out.append(id)
	return out


## Demigods who know each other (Hayden 2026-10-25): when both fight, each
## deals BOND_DEALT more damage, and the battle log has a line (placeholder).
const BOND_DEALT := 1.1
const BONDS := [
	{ "pair": [&"gilgamesh", &"enkidu"], "line": "Gilgamesh and Enkidu fight back to back, as they did in the Cedar Forest." },
	{ "pair": [&"perseus", &"bellerophon"], "line": "Perseus and Bellerophon: the slayer of Medusa and the rider of her son Pegasus." },
	{ "pair": [&"heracles", &"theseus"], "line": "Heracles and Theseus trade a grin. Old friends, older monsters." },
	{ "pair": [&"cu_chulainn", &"fionn"], "line": "Cu Chulainn and Fionn: two heroes of Ireland, one battle-cry." },
	{ "pair": [&"orpheus", &"atalanta"], "line": "Orpheus plays and Atalanta runs, the way they did aboard the Argo." },
]


## The bonds formed by these companion ids (each a BONDS entry).
static func bonds_among(ids: Array) -> Array:
	return BONDS.filter(func(b): return ids.has(b.pair[0]) and ids.has(b.pair[1]))


## Hiring by the floor (Hayden 2026-10-25): this share of the fee up front,
## then the fee / WAGE_FLOORS every floor (a 600g hire: 150 now, 30 a floor).
const HIRE_DOWN_SHARE := 0.25
const WAGE_FLOORS := 20


static func hire_down(id: StringName) -> int:
	return roundi(recruit_info(id).get("fee", 0) * HIRE_DOWN_SHARE)


static func hire_wage(id: StringName) -> int:
	return maxi(1, roundi(recruit_info(id).get("fee", 0) / float(WAGE_FLOORS))) if recruit_info(id).has("fee") else 0


## Builds a recruit at `level` with points split by its build and its class
## taken if it qualifies.
static func make_recruit(id: StringName, level: int) -> CharacterData:
	var n := get_npc(id)
	if not n.has("recruit"):
		return null
	var r: Dictionary = n.recruit
	var c := CharacterData.new()
	c.character_name = n.name
	c.companion_id = id
	c.personal_skill = r.get("personal_skill", &"")
	while c.level < maxi(1, level):
		c.level_up()
	if c.unspent_points > 0:
		c.apply_allocation(split_points(c.unspent_points, r.build))
	var cdef := ClassRegistry.get_class_def(r.get("class_id", &""))
	if cdef and cdef.unique_to == id:
		c.class_id = cdef.id   # a demigod's own class: theirs from the start
		c._apply_class_bonus()
	elif c.can_choose_class():
		if cdef and not cdef.is_secret:
			c.choose_class(cdef)
	if r.has("row"):
		c.battle_row = r.row
	var blessing: Array = n.get("blessing", [])
	if blessing.size() == 2 and BeingLibrary.beings.has(blessing[0]):
		c.bless(blessing[0], blessing[1])
	return c


## Splits `points` by the weights (largest remainder, so it always adds up).
static func split_points(points: int, weights: Dictionary) -> Dictionary:
	var total := 0
	for s in weights:
		total += weights[s]
	var out := {}
	if total <= 0:
		return out
	var given := 0
	var rema := []
	for s in weights:
		var exact: float = float(points) * weights[s] / total
		out[s] = int(exact)
		given += out[s]
		rema.append([exact - int(exact), s])
	rema.sort_custom(func(a, b): return a[0] > b[0])
	for i in points - given:
		out[rema[i % rema.size()][1]] += 1
	return out
