class_name BeingLibrary
extends RefCounted
## Gods, demons and devils from the world's mythologies, who take an interest
## in climbers (manhwa-style: many beings watch, and the climber chooses).
##
## SENSITIVITY RULE (Hayden, for the commercial release; may change later):
## beings from LIVING religions ("living": true — Shinto kami, Chinese folk /
## Buddhist / Taoist figures) are only ever benevolent "god"s with dignified
## costs. Demon/devil roles go to figures that are monsters, tricksters or
## villains in their own tradition. The tests enforce this.
## (Hindu deities are deliberately not in the first roster: Hayden's call.)
##
## A being (written compactly in SPECS, expanded by _build()):
##   "name", "title", "kind": "god" | "demon" | "devil", "pantheon"
##   "living": true for figures still worshipped today (see rule above)
##   "likes" / "dislikes": route ids. INTEREST = points in liked routes -
##       points in disliked routes (+ direct interest from choices, - rivalry).
##   "rivals": beings it's jealous of (both directions count). If you're
##       blessed by a rival it loses interest; accepting a blessing while a
##       rival wanted you makes that rival curse you out of spite.
##   "skill": usable while blessed
##   "buff" / "curse": level-1 effects; levels 2 and 3 scale every number by
##       LEVEL_SCALE (affinities stay). "curse3": extra curse effects at level 3.
##   "bargain": (optional) { "gold": n } or { "quest": id } — devils deal.
##   "offer" (+ optional "warn", "punish"): what it says (placeholder text).
##
## Effects (both buffs and curses):
##   "stats": { Stats.Type: pct }        e.g. +0.05 = +5%, -0.03 = -3%
##   "element_power": { Element.Type: pct }   more damage with that element
##   "affinities": { Element.Type: Element.Affinity }   how the blessed take hits
##   "gold_mult" / "xp_mult" / "price_mult": pct   (+0.1 = 10% more)
##   "regen_pct": heal this much of max HP after every won battle
##
## DLC can add beings with register_being(id, spec) (same compact format).

const S := Stats.Type
const EL := Element.Type
const AF := Element.Affinity

## Blessing levels 1-3 multiply every buff/curse number by this.
const LEVEL_SCALE := [1.0, 2.0, 3.0]

const SPECS := {
	# --- Norse ---
	&"odin": { "name": "Odin", "title": "the Allfather", "kind": "god", "pantheon": "Norse",
		"likes": [&"vigilante", &"hero"], "dislikes": [&"villain"], "rivals": [&"loki"], "skill": &"gungnir",
		"buff": { "stats": { S.INTELLIGENCE: 0.05, S.LUCK: 0.05 } }, "curse": { "stats": { S.HEALTH: -0.03 } },
		"offer": "(Placeholder) I gave an eye for wisdom. What will you give for mine?" },
	&"thor": { "name": "Thor", "title": "God of Thunder", "kind": "god", "pantheon": "Norse",
		"likes": [&"hero"], "dislikes": [&"villain"], "rivals": [&"loki"], "skill": &"mjolnir",
		"buff": { "stats": { S.STRENGTH: 0.05 }, "element_power": { EL.LIGHTNING: 0.15 } },
		"curse": { "stats": { S.AGILITY: -0.04 } },
		"offer": "(Placeholder) You fight like a storm, little climber. Let's make it a real one." },
	&"loki": { "name": "Loki", "title": "the Trickster", "kind": "devil", "pantheon": "Norse",
		"likes": [&"vigilante", &"villain"], "dislikes": [&"hero"], "rivals": [&"odin", &"thor"],
		"skill": &"tricksters_gambit", "bargain": { "gold": 350 },
		"buff": { "stats": { S.AGILITY: 0.05, S.LUCK: 0.05 }, "xp_mult": 0.1 },
		"curse": { "stats": { S.STAMINA: -0.03 }, "price_mult": 0.05 },
		"offer": "(Placeholder) Rules are for people without imagination. I can tell you have plenty. For a small fee." },
	&"hel": { "name": "Hel", "title": "Queen of the Dead", "kind": "demon", "pantheon": "Norse",
		"likes": [&"villain"], "dislikes": [&"hero"], "skill": &"helheim_frost",
		"buff": { "element_power": { EL.DARK: 0.15 }, "regen_pct": 0.05 },
		"curse": { "stats": { S.HEALTH: -0.03 }, "affinities": { EL.HOLY: AF.WEAK } },
		"offer": "(Placeholder) Everyone comes to my hall eventually. You, I'd like to keep busy until then." },

	# --- Greek ---
	&"zeus": { "name": "Zeus", "title": "King of the Gods", "kind": "god", "pantheon": "Greek",
		"likes": [&"hero"], "dislikes": [&"villain", &"vigilante"], "rivals": [&"typhon", &"hades"], "skill": &"thunderbolt",
		"buff": { "element_power": { EL.LIGHTNING: 0.15 }, "stats": { S.STRENGTH: 0.03, S.INTELLIGENCE: 0.03 } },
		"curse": { "gold_mult": -0.05 },
		"offer": "(Placeholder) Order needs champions. Kneel, and I'll lend you the sky." },
	&"athena": { "name": "Athena", "title": "Goddess of Wisdom", "kind": "god", "pantheon": "Greek",
		"likes": [&"hero", &"vigilante"], "dislikes": [&"villain"], "skill": &"aegis",
		"buff": { "stats": { S.INTELLIGENCE: 0.05, S.STAMINA: 0.05 } }, "curse": { "stats": { S.STRENGTH: -0.03 } },
		"offer": "(Placeholder) You think before you strike. That is rarer than courage." },
	&"hades": { "name": "Hades", "title": "Lord of the Underworld", "kind": "god", "pantheon": "Greek",
		"likes": [&"vigilante"], "dislikes": [&"hero"], "rivals": [&"zeus"], "skill": &"bident",
		"buff": { "gold_mult": 0.1, "element_power": { EL.DARK: 0.1 } },
		"curse": { "affinities": { EL.HOLY: AF.WEAK } },
		"offer": "(Placeholder) The riches under the earth are mine. So are the dead who chase them. Climb for me." },
	&"typhon": { "name": "Typhon", "title": "Father of Monsters", "kind": "demon", "pantheon": "Greek",
		"likes": [&"villain"], "dislikes": [&"hero"], "rivals": [&"zeus"], "skill": &"typhon_storm",
		"buff": { "stats": { S.STRENGTH: 0.05 }, "element_power": { EL.WIND: 0.15 } },
		"curse": { "affinities": { EL.LIGHTNING: AF.WEAK } },
		"offer": "(Placeholder) The gods buried me under a mountain. Help me dig." },

	# --- Egyptian ---
	&"ra": { "name": "Ra", "title": "God of the Sun", "kind": "god", "pantheon": "Egyptian",
		"likes": [&"hero"], "dislikes": [&"villain"], "rivals": [&"apep"], "skill": &"sun_disk",
		"buff": { "element_power": { EL.FIRE: 0.1, EL.HOLY: 0.1 }, "regen_pct": 0.05 },
		"curse": { "affinities": { EL.DARK: AF.WEAK } },
		"offer": "(Placeholder) Every night I fight the dark so the sun can rise. Walk in my light." },
	&"anubis": { "name": "Anubis", "title": "Guardian of the Dead", "kind": "god", "pantheon": "Egyptian",
		"likes": [&"vigilante"], "dislikes": [&"villain"], "rivals": [&"set"], "skill": &"weighing_of_the_heart",
		"buff": { "stats": { S.STAMINA: 0.05 }, "affinities": { EL.DARK: AF.RESIST } },
		"curse": { "stats": { S.LUCK: -0.05 } },
		"offer": "(Placeholder) I have weighed many hearts. Yours is... interesting." },
	&"set": { "name": "Set", "title": "Lord of the Desert", "kind": "demon", "pantheon": "Egyptian",
		"likes": [&"villain"], "dislikes": [&"hero"], "rivals": [&"anubis"], "skill": &"sandstorm",
		"buff": { "stats": { S.STRENGTH: 0.05 }, "element_power": { EL.WIND: 0.1, EL.EARTH: 0.1 } },
		"curse": { "affinities": { EL.WATER: AF.WEAK } },
		"offer": "(Placeholder) Brothers, thrones, betrayals... I know the climb. Let me show you how it's done." },
	&"apep": { "name": "Apep", "title": "Serpent of Chaos", "kind": "demon", "pantheon": "Egyptian",
		"likes": [&"villain"], "dislikes": [&"hero", &"vigilante"], "rivals": [&"ra"], "skill": &"devouring_dark",
		"buff": { "element_power": { EL.DARK: 0.15 }, "stats": { S.LUCK: 0.05 } },
		"curse": { "affinities": { EL.FIRE: AF.WEAK, EL.HOLY: AF.WEAK } },
		"offer": "(Placeholder) I will swallow the sun one day. Until then, I'll settle for your enemies." },

	# --- Chinese (living tradition: gods only) ---
	&"guan_yu": { "name": "Guan Yu", "title": "God of Loyalty", "kind": "god", "pantheon": "Chinese", "living": true,
		"likes": [&"hero"], "dislikes": [&"villain"], "skill": &"crescent_blade",
		"buff": { "stats": { S.STRENGTH: 0.05, S.STAMINA: 0.05 } }, "curse": { "stats": { S.AGILITY: -0.03 } },
		"offer": "(Placeholder) You keep your word, even here. Then I will keep mine to you." },
	&"sun_wukong": { "name": "Sun Wukong", "title": "the Monkey King", "kind": "god", "pantheon": "Chinese", "living": true,
		"likes": [&"vigilante"], "dislikes": [&"villain"], "rivals": [&"baigujing"], "skill": &"ruyi_staff",
		"buff": { "stats": { S.AGILITY: 0.05, S.LUCK: 0.05 } }, "curse": { "stats": { S.INTELLIGENCE: -0.03 } },
		"offer": "(Placeholder) Ha! You climb like you've got somewhere better to be. I like that." },
	&"yama": { "name": "Yama", "title": "King of the Underworld Courts", "kind": "god", "pantheon": "Chinese", "living": true,
		"likes": [&"vigilante"], "dislikes": [&"villain"], "skill": &"hellfire",
		"buff": { "element_power": { EL.FIRE: 0.1, EL.DARK: 0.1 } }, "curse": { "stats": { S.LUCK: -0.04 } },
		"offer": "(Placeholder) Every deed is written down. Yours, I would like to judge myself." },
	&"baigujing": { "name": "Baigujing", "title": "the White Bone Demon", "kind": "devil", "pantheon": "Chinese",
		"likes": [&"villain"], "dislikes": [&"hero"], "rivals": [&"sun_wukong"], "skill": &"bone_mirage",
		"bargain": { "gold": 300 },
		"buff": { "stats": { S.INTELLIGENCE: 0.05 }, "xp_mult": 0.1 }, "curse": { "affinities": { EL.HOLY: AF.WEAK } },
		"offer": "(Placeholder) I can be anyone. For you, I'll be a friend. Friends pay, of course." },

	# --- Japanese (kami are a living tradition: gods only; yokai can be demons) ---
	&"amaterasu": { "name": "Amaterasu", "title": "Goddess of the Sun", "kind": "god", "pantheon": "Japanese", "living": true,
		"likes": [&"hero"], "dislikes": [&"villain"], "rivals": [&"susanoo"], "skill": &"divine_mirror",
		"buff": { "element_power": { EL.HOLY: 0.1, EL.FIRE: 0.1 }, "regen_pct": 0.05 },
		"curse": { "affinities": { EL.DARK: AF.WEAK } },
		"offer": "(Placeholder) Even in the darkest floors, the sun can find you. Let it." },
	&"susanoo": { "name": "Susanoo", "title": "God of Storms", "kind": "god", "pantheon": "Japanese", "living": true,
		"likes": [&"vigilante"], "dislikes": [&"villain"], "rivals": [&"amaterasu"], "skill": &"kusanagi",
		"buff": { "stats": { S.STRENGTH: 0.05 }, "element_power": { EL.WIND: 0.1, EL.WATER: 0.1 } },
		"curse": { "stats": { S.STAMINA: -0.03 } },
		"offer": "(Placeholder) My sister has her sun. I have the storm. Which do you think wins fights?" },
	&"inari": { "name": "Inari", "title": "Kami of Prosperity", "kind": "god", "pantheon": "Japanese", "living": true,
		"likes": [&"hero"], "dislikes": [&"villain"], "skill": &"mercys_embrace",
		"buff": { "gold_mult": 0.1, "stats": { S.LUCK: 0.05 } }, "curse": { "stats": { S.STRENGTH: -0.03 } },
		"offer": "(Placeholder) Plenty for those who share. You share. Take my foxes' blessing." },
	&"shuten_doji": { "name": "Shuten-doji", "title": "King of the Oni", "kind": "demon", "pantheon": "Japanese",
		"likes": [&"villain"], "dislikes": [&"hero"], "skill": &"oni_club",
		"buff": { "stats": { S.STRENGTH: 0.07 } },
		"curse": { "stats": { S.INTELLIGENCE: -0.05 }, "affinities": { EL.HOLY: AF.WEAK } },
		"offer": "(Placeholder) Drink with me, smash with me. That's the whole deal." },
	&"tamamo": { "name": "Tamamo-no-Mae", "title": "the Nine-Tailed Fox", "kind": "devil", "pantheon": "Japanese",
		"likes": [&"villain", &"vigilante"], "dislikes": [&"hero"], "skill": &"foxfire", "bargain": { "gold": 500 },
		"buff": { "stats": { S.INTELLIGENCE: 0.05 }, "element_power": { EL.FIRE: 0.15 } },
		"curse": { "affinities": { EL.HOLY: AF.WEAK } },
		"offer": "(Placeholder) Emperors have begged for my favor. You only need to pay." },

	# --- Mesopotamian ---
	&"ishtar": { "name": "Ishtar", "title": "Goddess of Love and War", "kind": "god", "pantheon": "Mesopotamian",
		"likes": [&"vigilante", &"hero"], "dislikes": [&"villain"], "rivals": [&"tiamat"], "skill": &"righteous_smite",
		"buff": { "stats": { S.STRENGTH: 0.03, S.LUCK: 0.05 } }, "curse": { "price_mult": 0.05 },
		"offer": "(Placeholder) I love a fighter with a heart. Fight for me." },
	&"tiamat": { "name": "Tiamat", "title": "Mother of Chaos", "kind": "demon", "pantheon": "Mesopotamian",
		"likes": [&"villain"], "dislikes": [&"hero"], "rivals": [&"ishtar"], "skill": &"primordial_tide",
		"buff": { "element_power": { EL.WATER: 0.15 }, "stats": { S.HEALTH: 0.05 } },
		"curse": { "affinities": { EL.LIGHTNING: AF.WEAK } },
		"offer": "(Placeholder) Before the gods there was the sea. And the sea was me." },

	# --- Celtic ---
	&"morrigan": { "name": "The Morrigan", "title": "Phantom Queen", "kind": "devil", "pantheon": "Celtic",
		"likes": [&"vigilante"], "dislikes": [&"hero"], "skill": &"vendetta", "bargain": { "quest": &"oath_of_vengeance" },
		"buff": { "stats": { S.LUCK: 0.05 }, "element_power": { EL.DARK: 0.1 } },
		"curse": { "stats": { S.INTELLIGENCE: -0.03 } }, "curse3": { "affinities": { EL.HOLY: AF.WEAK } },
		"offer": "(Placeholder) The ravens have already seen how your fight ends. Swear the oath, and I'll change it." },

	# --- Demons of the Abrahamic tradition / European legend ---
	&"mammon": { "name": "Mammon", "title": "Demon of Greed", "kind": "demon", "pantheon": "Infernal",
		"likes": [&"villain"], "dislikes": [&"hero"], "skill": &"avarice_strike",
		"buff": { "gold_mult": 0.15, "stats": { S.LUCK: 0.05 } },
		"curse": { "price_mult": 0.1, "affinities": { EL.HOLY: AF.WEAK } },
		"offer": "(Placeholder) You take what you want. So do I. Let's take more, together." },
	&"mephistopheles": { "name": "Mephistopheles", "title": "Devil of Bargains", "kind": "devil", "pantheon": "Infernal",
		"likes": [&"vigilante", &"villain"], "dislikes": [&"hero"], "skill": &"devils_due", "bargain": { "gold": 400 },
		"buff": { "xp_mult": 0.1, "stats": { S.AGILITY: 0.05 } }, "curse": { "stats": { S.HEALTH: -0.03 } },
		"offer": "(Placeholder) Everyone has a price, friend. Mine is very reasonable. For now." },
}

## Default lines when a being doesn't have its own "warn" / "punish".
const DEFAULT_WARN := {
	"god": "(Placeholder) %s's gaze grows cold. Remember what you swore to.",
	"demon": "(Placeholder) %s laughs, and it isn't friendly. Don't go soft now.",
	"devil": "(Placeholder) %s taps the contract. You're drifting from our terms.",
}
const DEFAULT_PUNISH := {
	"god": "(Placeholder) %s's favor turns to wrath.",
	"demon": "(Placeholder) %s takes back everything it gave. With interest.",
	"devil": "(Placeholder) Contract void. %s collects the penalty.",
}

## TEMPER: how warlike a being is (0 = peaceful, 1 = lives for war). Your
## patrons' temper (your blessing + your guild's patron) sets how often the
## guilds around you go to war (GuildAI). A spec can override it with "temper".
const TEMPER := {
	&"odin": 0.6, &"thor": 0.7, &"loki": 0.85, &"hel": 0.4,
	&"zeus": 0.6, &"athena": 0.35, &"hades": 0.3, &"typhon": 0.95,
	&"ra": 0.4, &"anubis": 0.15, &"set": 0.8, &"apep": 0.9,
	&"guan_yu": 0.5, &"sun_wukong": 0.7, &"yama": 0.2, &"baigujing": 0.6,
	&"amaterasu": 0.45, &"susanoo": 0.8, &"inari": 0.1, &"shuten_doji": 0.85, &"tamamo": 0.5,
	&"ishtar": 0.8, &"tiamat": 0.95, &"morrigan": 0.85,
	&"mammon": 0.5, &"mephistopheles": 0.4,
}
const DEFAULT_TEMPER := { "god": 0.4, "demon": 0.7, "devil": 0.55 }


static func temper_of(id: StringName) -> float:
	var b := get_being(id)
	if b.is_empty():
		return 0.5
	return clampf(float(b.get("temper", TEMPER.get(id, DEFAULT_TEMPER.get(b.get("kind", "god"), 0.5)))), 0.0, 1.0)


const EFFECT_KEYS := ["stats", "element_power", "affinities", "gold_mult", "xp_mult", "price_mult", "regen_pct"]

## Live table: the base roster (expanded) plus anything DLC registered.
static var beings: Dictionary = _build_all()


static func _build_all() -> Dictionary:
	var out := {}
	for id in SPECS:
		out[id] = expand(SPECS[id])
	return out


## Turns a compact spec into a full being: levels from LEVEL_SCALE, default
## lines, values.
static func expand(spec: Dictionary) -> Dictionary:
	var b := spec.duplicate(true)
	b["values"] = { "likes": spec.get("likes", []), "dislikes": spec.get("dislikes", []) }
	b["rivals"] = spec.get("rivals", [])
	var kind: String = spec.get("kind", "god")
	if not b.has("warn"):
		b["warn"] = DEFAULT_WARN.get(kind, "%s is displeased.") % spec.get("name", "?")
	if not b.has("punish"):
		b["punish"] = DEFAULT_PUNISH.get(kind, "%s punishes you.") % spec.get("name", "?")
	var levels := []
	for i in LEVEL_SCALE.size():
		var curse := _scaled(spec.get("curse", {}), LEVEL_SCALE[i])
		if i == LEVEL_SCALE.size() - 1:
			for k in spec.get("curse3", {}):
				curse[k] = spec.curse3[k]
		levels.append({ "buff": _scaled(spec.get("buff", {}), LEVEL_SCALE[i]), "curse": curse })
	b["levels"] = levels
	return b


static func _scaled(effects: Dictionary, f: float) -> Dictionary:
	var out := {}
	for k in effects:
		var v = effects[k]
		if k == "affinities":
			out[k] = (v as Dictionary).duplicate()
		elif v is Dictionary:
			var m := {}
			for sub in v:
				m[sub] = snappedf(v[sub] * f, 0.001)
			out[k] = m
		else:
			out[k] = snappedf(v * f, 0.001)
	return out


## DLC: add (or replace) a being, in the same compact format as SPECS.
static func register_being(id: StringName, spec: Dictionary) -> void:
	beings[id] = expand(spec)


static func get_being(id: StringName) -> Dictionary:
	return beings.get(id, {})


## "Odin, the Allfather"
static func full_name(id: StringName) -> String:
	var b := get_being(id)
	return "%s, %s" % [b.get("name", "?"), b.get("title", "")] if not b.is_empty() else "?"


## Rivals in both directions (Odin lists Loki; Loki lists Odin and Thor).
static func rivals_of(id: StringName) -> Array:
	var out: Array = get_being(id).get("rivals", []).duplicate()
	for other in beings:
		if beings[other].get("rivals", []).has(id) and not out.has(other):
			out.append(other)
	return out


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
		if b.get("living", false) and b.get("kind") != "god":
			problems.append("%s: beings from living religions may only be gods (sensitivity rule)" % id)
		for k in ["name", "title", "pantheon", "offer", "warn", "punish"]:
			if str(b.get(k, "")) == "":
				problems.append("%s: missing %s" % [id, k])
		for r in b.values.get("likes", []) + b.values.get("dislikes", []):
			if not RouteLibrary.routes.has(r):
				problems.append("%s: unknown route %s" % [id, r])
		if b.values.get("likes", []).is_empty():
			problems.append("%s: likes no route (it could never take an interest)" % id)
		for r in b.get("rivals", []):
			if not beings.has(r):
				problems.append("%s: unknown rival %s" % [id, r])
		if SkillLibrary.get_skill_or_null(b.get("skill", &"")) == null:
			problems.append("%s: unknown skill %s" % [id, b.get("skill")])
		for lv in b.get("levels", []):
			for side in ["buff", "curse"]:
				if (lv.get(side, {}) as Dictionary).is_empty():
					problems.append("%s: every level needs a buff AND a curse" % id)
				for k in lv.get(side, {}):
					if not k in EFFECT_KEYS:
						problems.append("%s: unknown effect '%s'" % [id, k])
		if b.has("temper") and not (b.temper is float or b.temper is int):
			problems.append("%s: temper must be a number 0-1" % id)
		var bargain: Dictionary = b.get("bargain", {})
		if bargain.has("quest") and QuestLibrary.get_quest(bargain.quest).is_empty():
			problems.append("%s: bargain quest %s doesn't exist" % [id, bargain.quest])
	return problems
