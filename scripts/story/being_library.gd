class_name BeingLibrary
extends RefCounted
## Gods, demons and devils that take an interest in climbers (manhwa-style:
## many beings watch, and the climber chooses whose blessing to accept).
##
## A being:
##   "name", "title", "kind": "god" | "demon" | "devil"
##   "values": { "likes": [route ids], "dislikes": [...] }
##       Its INTEREST in you = points in routes it likes - points in routes it
##       dislikes (+ any interest that choices give it directly).
##   "skill": a skill the blessed character can use while blessed
##   "levels": [ level 1, level 2, level 3 ] each { "buff": <effects>, "curse": <effects> }
##       The blessing grows with interest (BlessingState.LEVEL_INTEREST); the
##       buff AND the curse grow together: equal power, equal price.
##   "bargain": (optional) what accepting costs: { "gold": n } or { "quest": id }
##       (a promise; its quest starts when you accept). Devils deal; gods don't.
##   "offer", "warn", "punish": what it says (placeholder text).
##
## Effects (both buffs and curses):
##   "stats": { Stats.Type: pct }        e.g. +0.1 = +10%, -0.1 = -10%
##   "element_power": { Element.Type: pct }   more damage with that element
##   "affinities": { Element.Type: Element.Affinity }   how the blessed take hits
##   "gold_mult" / "xp_mult" / "price_mult": pct   (+0.2 = 20% more)
##   "regen_pct": heal this much of max HP after every won battle
##
## DLC can add beings with register_being(). Placeholder roster below.

const S := Stats.Type
const EL := Element.Type
const AF := Element.Affinity

const BASE_BEINGS := {
	&"astraea": {
		"name": "Astraea", "title": "God of Justice", "kind": "god",
		"values": { "likes": [&"hero"], "dislikes": [&"villain"] },
		"skill": &"righteous_smite",
		"levels": [
			{ "buff": { "stats": { S.HEALTH: 0.05, S.STAMINA: 0.05 }, "element_power": { EL.HOLY: 0.2 } },
				"curse": { "affinities": { EL.DARK: AF.WEAK } } },
			{ "buff": { "stats": { S.HEALTH: 0.1, S.STAMINA: 0.1 }, "element_power": { EL.HOLY: 0.35 } },
				"curse": { "affinities": { EL.DARK: AF.WEAK }, "gold_mult": -0.1 } },
			{ "buff": { "stats": { S.HEALTH: 0.15, S.STAMINA: 0.15 }, "element_power": { EL.HOLY: 0.5 } },
				"curse": { "affinities": { EL.DARK: AF.WEAK }, "gold_mult": -0.2 } },
		],
		"offer": "(Placeholder) I have watched you protect the weak. Carry my scales, and I will carry you.",
		"warn": "(Placeholder) My scales are tipping, climber. Do not make me choose.",
		"punish": "(Placeholder) Justice does not forgive. Neither do I.",
	},
	&"solenne": {
		"name": "Solenne", "title": "Goddess of Mercy", "kind": "god",
		"values": { "likes": [&"hero"], "dislikes": [&"villain", &"vigilante"] },
		"skill": &"mercys_embrace",
		"levels": [
			{ "buff": { "regen_pct": 0.1, "stats": { S.INTELLIGENCE: 0.05 } }, "curse": { "stats": { S.STRENGTH: -0.05 } } },
			{ "buff": { "regen_pct": 0.15, "stats": { S.INTELLIGENCE: 0.1 } }, "curse": { "stats": { S.STRENGTH: -0.1 } } },
			{ "buff": { "regen_pct": 0.2, "stats": { S.INTELLIGENCE: 0.15 } }, "curse": { "stats": { S.STRENGTH: -0.15 } } },
		],
		"offer": "(Placeholder) You spare those who don't deserve it. Let me spare you, too.",
		"warn": "(Placeholder) There is cruelty in you now. I can feel it.",
		"punish": "(Placeholder) Even mercy has an end.",
	},
	&"vorak": {
		"name": "Vorak", "title": "Demon of Greed", "kind": "demon",
		"values": { "likes": [&"villain"], "dislikes": [&"hero"] },
		"skill": &"avarice_strike",
		"levels": [
			{ "buff": { "gold_mult": 0.2, "stats": { S.LUCK: 0.1 } },
				"curse": { "price_mult": 0.1, "affinities": { EL.HOLY: AF.WEAK } } },
			{ "buff": { "gold_mult": 0.35, "stats": { S.LUCK: 0.15 } },
				"curse": { "price_mult": 0.2, "affinities": { EL.HOLY: AF.WEAK } } },
			{ "buff": { "gold_mult": 0.5, "stats": { S.LUCK: 0.2 } },
				"curse": { "price_mult": 0.3, "affinities": { EL.HOLY: AF.WEAK } } },
		],
		"offer": "(Placeholder) You take what you want. So do I. Let's take more, together.",
		"warn": "(Placeholder) Charity? From YOU? Don't disappoint me.",
		"punish": "(Placeholder) Everything I gave, I take back. With interest.",
	},
	&"ishra": {
		"name": "Ishra", "title": "Demon of Wrath", "kind": "demon",
		"values": { "likes": [&"villain"], "dislikes": [&"hero"] },
		"skill": &"hellfire",
		"levels": [
			{ "buff": { "stats": { S.STRENGTH: 0.1 }, "element_power": { EL.FIRE: 0.2 } },
				"curse": { "stats": { S.STAMINA: -0.05 } } },
			{ "buff": { "stats": { S.STRENGTH: 0.15 }, "element_power": { EL.FIRE: 0.35 } },
				"curse": { "stats": { S.STAMINA: -0.1 }, "affinities": { EL.WATER: AF.WEAK } } },
			{ "buff": { "stats": { S.STRENGTH: 0.2 }, "element_power": { EL.FIRE: 0.5 } },
				"curse": { "stats": { S.STAMINA: -0.15 }, "affinities": { EL.WATER: AF.WEAK, EL.HOLY: AF.WEAK } } },
		],
		"offer": "(Placeholder) I like how angry you are. Let it burn.",
		"warn": "(Placeholder) You're going soft. I hate soft.",
		"punish": "(Placeholder) Then burn without me.",
	},
	&"sable": {
		"name": "Sable", "title": "Devil of Bargains", "kind": "devil",
		"values": { "likes": [&"vigilante"], "dislikes": [] },
		"skill": &"devils_due",
		"bargain": { "gold": 400 },
		"levels": [
			{ "buff": { "xp_mult": 0.15, "stats": { S.AGILITY: 0.1 } }, "curse": { "stats": { S.HEALTH: -0.05 } } },
			{ "buff": { "xp_mult": 0.25, "stats": { S.AGILITY: 0.15 } }, "curse": { "stats": { S.HEALTH: -0.1 } } },
			{ "buff": { "xp_mult": 0.35, "stats": { S.AGILITY: 0.2 } }, "curse": { "stats": { S.HEALTH: -0.15 } } },
		],
		"offer": "(Placeholder) Everyone has a price, friend. Mine is very reasonable. For now.",
		"warn": "(Placeholder) You're drifting from our arrangement. I'd read the small print.",
		"punish": "(Placeholder) Contract void. The penalty clause, however, still applies.",
	},
	&"corvin": {
		"name": "Corvin", "title": "Devil of Vengeance", "kind": "devil",
		"values": { "likes": [&"vigilante"], "dislikes": [&"hero"] },
		"skill": &"vendetta",
		"bargain": { "quest": &"oath_of_vengeance" },
		"levels": [
			{ "buff": { "stats": { S.LUCK: 0.1 }, "element_power": { EL.DARK: 0.2 } },
				"curse": { "stats": { S.INTELLIGENCE: -0.05 } } },
			{ "buff": { "stats": { S.LUCK: 0.15 }, "element_power": { EL.DARK: 0.35 } },
				"curse": { "stats": { S.INTELLIGENCE: -0.1 }, "affinities": { EL.HOLY: AF.WEAK } } },
			{ "buff": { "stats": { S.LUCK: 0.2 }, "element_power": { EL.DARK: 0.5 } },
				"curse": { "stats": { S.INTELLIGENCE: -0.15 }, "affinities": { EL.HOLY: AF.WEAK } } },
		],
		"offer": "(Placeholder) Someone should pay. Swear it, and I'll make sure they do.",
		"warn": "(Placeholder) Forgiveness? That wasn't the oath.",
		"punish": "(Placeholder) An oath broken is a debt. I collect.",
	},
}

const EFFECT_KEYS := ["stats", "element_power", "affinities", "gold_mult", "xp_mult", "price_mult", "regen_pct"]

## Live table: the base roster plus anything DLC registered.
static var beings: Dictionary = BASE_BEINGS.duplicate(true)


static func register_being(id: StringName, def: Dictionary) -> void:
	beings[id] = def


static func get_being(id: StringName) -> Dictionary:
	return beings.get(id, {})


## "Astraea, God of Justice"
static func full_name(id: StringName) -> String:
	var b := get_being(id)
	return "%s, %s" % [b.get("name", "?"), b.get("title", "")] if not b.is_empty() else "?"


## Effects for a level (1-based): { "buff": {...}, "curse": {...} }.
static func level_effects(id: StringName, level: int) -> Dictionary:
	var levels: Array = get_being(id).get("levels", [])
	if levels.is_empty() or level < 1:
		return {}
	return levels[mini(level, levels.size()) - 1]


## Problems with the roster ([] = all good). Run by the tests.
static func validate() -> PackedStringArray:
	var problems: PackedStringArray = []
	for id in beings:
		var b: Dictionary = beings[id]
		if not b.get("kind", "") in ["god", "demon", "devil"]:
			problems.append("%s: kind must be god/demon/devil" % id)
		for k in ["name", "title", "offer", "warn", "punish"]:
			if b.get(k, "") == "":
				problems.append("%s: missing %s" % [id, k])
		for r in b.get("values", {}).get("likes", []) + b.get("values", {}).get("dislikes", []):
			if not RouteLibrary.routes.has(r):
				problems.append("%s: unknown route %s" % [id, r])
		if b.get("values", {}).get("likes", []).is_empty():
			problems.append("%s: likes no route (it could never take an interest)" % id)
		if SkillLibrary.get_skill_or_null(b.get("skill", &"")) == null:
			problems.append("%s: unknown skill %s" % [id, b.get("skill")])
		if b.get("levels", []).size() != BlessingState.LEVEL_INTEREST.size():
			problems.append("%s: needs %d levels" % [id, BlessingState.LEVEL_INTEREST.size()])
		for lv in b.get("levels", []):
			for side in ["buff", "curse"]:
				if (lv.get(side, {}) as Dictionary).is_empty():
					problems.append("%s: every level needs a buff AND a curse" % id)
				for k in lv.get(side, {}):
					if not k in EFFECT_KEYS:
						problems.append("%s: unknown effect '%s'" % [id, k])
		var bargain: Dictionary = b.get("bargain", {})
		if bargain.has("quest") and QuestLibrary.get_quest(bargain.quest).is_empty():
			problems.append("%s: bargain quest %s doesn't exist" % [id, bargain.quest])
	return problems
