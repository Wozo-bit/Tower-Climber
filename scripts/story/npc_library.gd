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
##       "personal_skill": their own skill, unlocked by finishing their
##                    "loyalty" quest (QuestLibrary.recruit_quests builds both)
##       "favor" / "loyalty": { "title", "desc", "steps": [{ "text", "goal" }] }
##   "run_chance":    (optional) wanderers: chance (per run) they're in this run
##
## Recruits join at the player's level - 1 (min 1). Placeholders below.

const NPCS := {
	&"brakka": {
		"name": "Brakka", "kind": "npc", "dialogue": &"brakka", "color": Color(0.85, 0.55, 0.3),
		"floors": ["rest"], "min_floor": 5, "max_floor": 9999, "near": "campfire",
		"recruit": {
			"class_id": &"tank", "meet": "campfire", "personal_skill": &"thunder_charge",
			"build": { Stats.Type.HEALTH: 4, Stats.Type.STAMINA: 4, Stats.Type.STRENGTH: 3 },
			"loyalty": { "title": "Brakka: Worthy of Thunder", "desc": "(Placeholder) Brakka wants to prove Thor chose well.",
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
			"pitch": "(Placeholder) You came out of nowhere. I owe you one.",
			"loyalty": { "title": "Tamsin: A Debt Repaid", "desc": "(Placeholder) Tamsin won't rest until she's paid you back in kind.",
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
			"pitch": "(Placeholder) The goddess of wisdom sent me to tend the climbers. Help the wounded first, then we'll talk.",
			"favor": { "title": "Daphne: Clear the Way", "desc": "(Placeholder) Monsters keep the wounded from reaching her fire.",
				"steps": [{ "text": "Defeat 8 enemies", "goal": { "type": "defeat", "any": true, "count": 8 } }] },
			"loyalty": { "title": "Daphne: The Pilgrimage", "desc": "(Placeholder) Daphne made a vow to see the upper floors.",
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
			"pitch": "(Placeholder) My blade's for hire. Six hundred gold and I'm yours, no questions.",
			"loyalty": { "title": "Garrick: The Big Score", "desc": "(Placeholder) Garrick has heard a roaming beast guards a fortune.",
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
			"pitch": "(Placeholder) I don't climb with people I haven't seen fight. Take down one of the big ones.",
			"favor": { "title": "Rook: Prove It", "desc": "(Placeholder) Rook wants to see you beat a guardian.",
				"steps": [{ "text": "Defeat a miniboss", "goal": { "type": "defeat", "kind": "miniboss", "count": 1 } }] },
			"loyalty": { "title": "Rook: The Long Hunt", "desc": "(Placeholder) Rook keeps a tally. Help him fill it.",
				"steps": [{ "text": "Defeat 30 enemies", "goal": { "type": "defeat", "any": true, "count": 30 } }] },
		},
		"values": { "likes": [&"vigilante"], "dislikes": [&"hero"] },
	},
	&"sigrun": {
		"name": "Sigrun", "kind": "npc", "color": Color(0.75, 0.8, 0.95), "floors": [],
		"recruit": {
			"class_id": &"tank", "meet": "captive", "captive_of": &"moonfang", "personal_skill": &"valkyries_shield",
			"build": { Stats.Type.HEALTH: 4, Stats.Type.STAMINA: 4, Stats.Type.STRENGTH: 3 },
			"pitch": "(Placeholder) The Trickster's wolf kept me as a trophy. Odin will hear of this.",
			"loyalty": { "title": "Sigrun: The Allfather's Due", "desc": "(Placeholder) Sigrun owes Odin a great deed.",
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
			"pitch": "(Placeholder) The Serpent's queen walled me in her hive to keep Ra's light out. Thank you.",
			"loyalty": { "title": "Neferet: Light in the Dark", "desc": "(Placeholder) Neferet must carry Ra's light higher.",
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
			"pitch": "(Placeholder) Hades' servant meant to keep Zeus' priest in the dark forever. Not today.",
			"loyalty": { "title": "Lysander: The King's Oath", "desc": "(Placeholder) Lysander's oath demands a victory worthy of Zeus.",
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
			"pitch": "(Placeholder) The Mother of Chaos' dragon caged Ishtar's champion like a jewel. Let's make it pay.",
			"loyalty": { "title": "Shamira: Ishtar's Fury", "desc": "(Placeholder) Shamira wants to see the tower's crown fall.",
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
			"pitch": "(Placeholder) Climbed this tower forty years ago. Never made the top. Got room for an old man?",
			"loyalty": { "title": "Old Fenn: One Last Climb", "desc": "(Placeholder) Fenn wants to stand higher than he ever did.",
				"steps": [{ "text": "Reach floor 45", "goal": { "type": "reach", "floor": 45 } }] },
		},
		"values": { "likes": [&"vigilante"], "dislikes": [&"villain"] },
	},
	&"kael": {
		"name": "Kael", "kind": "npc", "color": Color(0.3, 0.3, 0.4), "floors": [], "run_chance": 0.5,
		"recruit": {
			"class_id": &"rogue", "meet": "rescue", "rescue_floors": [30, 38], "personal_skill": &"shadowstep",
			"build": { Stats.Type.AGILITY: 5, Stats.Type.STRENGTH: 3, Stats.Type.LUCK: 2 },
			"pitch": "(Placeholder) I had it handled. ...Fine. Thanks.",
			"loyalty": { "title": "Kael: Unfinished Business", "desc": "(Placeholder) Kael has a score to settle with the guardians.",
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
			"pitch": "(Placeholder) Fifteen hundred gold. Winter doesn't come cheap.",
			"loyalty": { "title": "Vesna: Deep Winter", "desc": "(Placeholder) Vesna wants to test her frost on the worst the tower has.",
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
			"pitch": "(Placeholder) Twelve labours, and the gods still want a thirteenth. Prove you can keep up.",
			"favor": { "title": "Legend: Heracles", "desc": "(Placeholder) The gods want proof before Heracles will follow you.",
				"steps": [
					{ "text": "Defeat 2 minibosses", "goal": { "type": "defeat", "kind": "miniboss", "count": 2 } },
					{ "text": "Defeat a stage boss", "goal": { "type": "defeat", "kind": "boss", "count": 1 } },
				] },
			"loyalty": { "title": "Heracles: The Last Labour", "desc": "(Placeholder) A demigod's legend needs one more great deed.",
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
			"pitch": "(Placeholder) Athena told me a climber would come. Show me you are the one.",
			"favor": { "title": "Legend: Perseus", "desc": "(Placeholder) The gods want proof before Perseus will follow you.",
				"steps": [
					{ "text": "Defeat 2 minibosses", "goal": { "type": "defeat", "kind": "miniboss", "count": 2 } },
					{ "text": "Defeat a stage boss", "goal": { "type": "defeat", "kind": "boss", "count": 1 } },
				] },
			"loyalty": { "title": "Perseus: The Last Labour", "desc": "(Placeholder) A demigod's legend needs one more great deed.",
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
			"pitch": "(Placeholder) Glory or nothing. If you want me at your side, earn it.",
			"favor": { "title": "Legend: Achilles", "desc": "(Placeholder) The gods want proof before Achilles will follow you.",
				"steps": [
					{ "text": "Defeat 2 minibosses", "goal": { "type": "defeat", "kind": "miniboss", "count": 2 } },
					{ "text": "Defeat a stage boss", "goal": { "type": "defeat", "kind": "boss", "count": 1 } },
				] },
			"loyalty": { "title": "Achilles: The Last Labour", "desc": "(Placeholder) A demigod's legend needs one more great deed.",
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
			"pitch": "(Placeholder) A king does not follow. But he may walk beside someone worth watching.",
			"favor": { "title": "Legend: Gilgamesh", "desc": "(Placeholder) The gods want proof before Gilgamesh will follow you.",
				"steps": [
					{ "text": "Defeat 2 minibosses", "goal": { "type": "defeat", "kind": "miniboss", "count": 2 } },
					{ "text": "Defeat a stage boss", "goal": { "type": "defeat", "kind": "boss", "count": 1 } },
				] },
			"loyalty": { "title": "Gilgamesh: The Last Labour", "desc": "(Placeholder) A demigod's legend needs one more great deed.",
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
			"pitch": "(Placeholder) The Phantom Queen sent her crows to find you. Let us see why.",
			"favor": { "title": "Legend: Cu Chulainn", "desc": "(Placeholder) The gods want proof before Cu Chulainn will follow you.",
				"steps": [
					{ "text": "Defeat 2 minibosses", "goal": { "type": "defeat", "kind": "miniboss", "count": 2 } },
					{ "text": "Defeat a stage boss", "goal": { "type": "defeat", "kind": "boss", "count": 1 } },
				] },
			"loyalty": { "title": "Cu Chulainn: The Last Labour", "desc": "(Placeholder) A demigod's legend needs one more great deed.",
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
			"pitch": "(Placeholder) The birds say a climber means to reach the top. I have killed a dragon. Can you?",
			"favor": { "title": "Legend: Sigurd", "desc": "(Placeholder) The gods want proof before Sigurd will follow you.",
				"steps": [
					{ "text": "Defeat 2 minibosses", "goal": { "type": "defeat", "kind": "miniboss", "count": 2 } },
					{ "text": "Defeat a stage boss", "goal": { "type": "defeat", "kind": "boss", "count": 1 } },
				] },
			"loyalty": { "title": "Sigurd: The Last Labour", "desc": "(Placeholder) A demigod's legend needs one more great deed.",
				"steps": [{ "text": "Defeat 2 stage bosses", "goal": { "type": "defeat", "kind": "boss", "count": 2 } }] },
		},
		"values": { "likes": [&"hero"], "dislikes": [&"villain"] },
		"blessing": [&"odin", 2],
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
	ids.sort()
	for id in ids:
		if NPCS[id].get("recruit", {}).get("meet", "") == meet:
			out.append(id)
	return out


static func recruit_info(id: StringName) -> Dictionary:
	return get_npc(id).get("recruit", {})


## NPCs that belong on this floor right now, in a stable order.
## `floor_kind` is "rest", "boss", "combat" or "miniboss". `rng_for(id)` must
## return a RandomNumberGenerator seeded for that NPC on this floor.
static func npcs_for_floor(floor_n: int, floor_kind: String, rng_for: Callable) -> Array[StringName]:
	var out: Array[StringName] = []
	var ids := NPCS.keys()
	ids.sort()
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
