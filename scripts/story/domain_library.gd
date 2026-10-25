class_name DomainLibrary
extends RefCounted
## Divine domains (Hayden 2026-10-25): conquering the tower makes your
## character a god. The ending you reached suggests a few domains, you pick
## one, choose what you are (god, demon or devil) and name your title. The
## domain sets the god's values, temper and blessing, in the same compact
## format as BeingLibrary.SPECS, so a past god can join other characters'
## runs as a being (GameState.refresh_legacy_gods).
##
## A domain:
##   "name": "Valor" · "title": the default title (gender-neutral; Hayden)
##   "kind": the suggested kind (the player picks: god / demon / devil)
##   "ending": the ending id that suggests it (RouteLibrary.endings)
##   "likes" / "dislikes": route ids (its values) · "temper": 0..1 (warlike)
##   "approves" / "forbids": EVERY guild action (GuildAI: trade, fortify,
##       raid, war, ally) is one or the other (Hayden: strict values), so a
##       sponsored guild earns or loses favor for whatever it does
##   "skill": the blessed skill · "buff" / "curse": BeingLibrary effects
##   "offer": what it says when it offers a blessing (placeholder text)
##
## Names are Hayden's picks; titles, numbers and text are placeholders. DLC
## can add domains with register_domain().

const S := Stats.Type
const EL := Element.Type
const AF := Element.Affinity

const BASE_DOMAINS := {
	# --- Hero ending ---
	&"valor": { "name": "Valor", "title": "Deity of Valor", "kind": "god", "ending": &"hero",
		"likes": [&"hero"], "dislikes": [&"villain"], "temper": 0.6,
		"approves": [&"war", &"fortify", &"ally", &"trade"], "forbids": [&"raid"],
		"skill": &"valor_strike",
		"buff": { "stats": { S.STRENGTH: 0.05, S.STAMINA: 0.03 } }, "curse": { "stats": { S.LUCK: -0.04 } },
		"offer": "(Placeholder) I climbed this tower with nothing but nerve. Take some of mine." },
	&"justice": { "name": "Justice", "title": "Deity of Justice", "kind": "god", "ending": &"hero",
		"likes": [&"hero"], "dislikes": [&"villain", &"vigilante"], "temper": 0.5,
		"approves": [&"fortify", &"ally", &"trade"], "forbids": [&"raid", &"war"],
		"skill": &"verdict_of_light",
		"buff": { "element_power": { EL.HOLY: 0.15 }, "stats": { S.INTELLIGENCE: 0.03 } },
		"curse": { "gold_mult": -0.05 },
		"offer": "(Placeholder) The tower has laws now. Mine. Uphold them and I'll stand behind you." },
	&"mercy": { "name": "Mercy", "title": "Deity of Mercy", "kind": "god", "ending": &"hero",
		"likes": [&"hero", &"vigilante"], "dislikes": [&"villain"], "temper": 0.1,
		"approves": [&"ally", &"trade", &"fortify"], "forbids": [&"war", &"raid"],
		"skill": &"grace",
		"buff": { "regen_pct": 0.05, "stats": { S.HEALTH: 0.03 } }, "curse": { "stats": { S.STRENGTH: -0.03 } },
		"offer": "(Placeholder) I lost too many friends on the way up. I won't lose you." },

	# --- Villain ending ---
	&"tyranny": { "name": "Tyranny", "title": "Sovereign of Tyranny", "kind": "demon", "ending": &"villain",
		"likes": [&"villain"], "dislikes": [&"hero"], "temper": 0.9,
		"approves": [&"war", &"fortify", &"raid", &"trade"], "forbids": [&"ally"],
		"skill": &"iron_decree",
		"buff": { "stats": { S.STRENGTH: 0.05, S.HEALTH: 0.03 } },
		"curse": { "affinities": { EL.HOLY: AF.WEAK } },
		"offer": "(Placeholder) Every floor bows to me now. Kneel, and some of them will bow to you." },
	&"greed": { "name": "Greed", "title": "Patron of Greed", "kind": "devil", "ending": &"villain",
		"likes": [&"villain", &"vigilante"], "dislikes": [&"hero"], "temper": 0.5,
		"approves": [&"raid", &"trade", &"fortify", &"war"], "forbids": [&"ally"],   # Hayden: won't share the spoils
		"skill": &"golden_hand",
		"buff": { "gold_mult": 0.15, "stats": { S.LUCK: 0.03 } }, "curse": { "price_mult": 0.1 },
		"offer": "(Placeholder) I took the tower and everything in it. There's plenty left over. For a price." },
	&"ruin": { "name": "Ruin", "title": "Bringer of Ruin", "kind": "demon", "ending": &"villain",
		"likes": [&"villain"], "dislikes": [&"hero", &"vigilante"], "temper": 0.95,
		"approves": [&"war", &"raid"], "forbids": [&"ally", &"trade", &"fortify"],
		"skill": &"ruin_wave",
		"buff": { "element_power": { EL.DARK: 0.15 } }, "curse": { "stats": { S.INTELLIGENCE: -0.04 } },
		"offer": "(Placeholder) I left the floors below in ashes. Help me finish the rest." },

	# --- Vigilante ending ---
	&"vengeance": { "name": "Vengeance", "title": "Deity of Vengeance", "kind": "devil", "ending": &"vigilante",
		"likes": [&"vigilante"], "dislikes": [&"hero"], "temper": 0.85,
		"approves": [&"war", &"raid", &"fortify"], "forbids": [&"ally", &"trade"],
		"skill": &"retribution",
		"buff": { "stats": { S.LUCK: 0.04 }, "element_power": { EL.DARK: 0.1 } }, "curse": { "stats": { S.STAMINA: -0.03 } },
		"offer": "(Placeholder) I remember every wrong done to me on the way up. Let me remember yours." },
	&"shadow": { "name": "Shadow", "title": "Keeper of Shadows", "kind": "devil", "ending": &"vigilante",
		"likes": [&"vigilante", &"villain"], "dislikes": [&"hero"], "temper": 0.5,
		"approves": [&"raid", &"trade", &"ally"], "forbids": [&"war", &"fortify"],
		"skill": &"night_veil",
		"buff": { "stats": { S.AGILITY: 0.05, S.LUCK: 0.03 } }, "curse": { "stats": { S.HEALTH: -0.03 } },
		"offer": "(Placeholder) No one saw me climb. No one will see you either." },
	&"freedom": { "name": "Freedom", "title": "Deity of Freedom", "kind": "god", "ending": &"vigilante",
		"likes": [&"vigilante", &"hero"], "dislikes": [&"villain"], "temper": 0.6,
		"approves": [&"ally", &"trade", &"war"], "forbids": [&"fortify", &"raid"],
		"skill": &"unbound_gale",
		"buff": { "stats": { S.AGILITY: 0.04 }, "element_power": { EL.WIND: 0.15 } }, "curse": { "stats": { S.STAMINA: -0.03 } },
		"offer": "(Placeholder) No guild, no god, no master. That's how I climbed. Climb free with me." },

	# --- The Wanderer (neutral) ending: Hayden's picks. It may also take any other. ---
	&"twilight": { "name": "Twilight", "title": "Keeper of Twilight", "kind": "god", "ending": &"neutral",
		"likes": [&"hero", &"villain"], "dislikes": [], "temper": 0.5,
		"approves": [&"trade", &"raid", &"ally"], "forbids": [&"war", &"fortify"],
		"skill": &"dusk_and_dawn",
		"buff": { "element_power": { EL.HOLY: 0.1, EL.DARK: 0.1 } }, "curse": { "stats": { S.HEALTH: -0.03 } },
		"offer": "(Placeholder) Light and dark both lost the war for the tower. I won it. Stand between them with me." },
	&"fate": { "name": "Fate", "title": "Weaver of Fate", "kind": "god", "ending": &"neutral",
		"likes": [&"vigilante", &"hero", &"villain"], "dislikes": [], "temper": 0.3,
		"approves": [&"war", &"ally", &"trade"], "forbids": [&"fortify", &"raid"],
		"skill": &"twist_of_fate",
		"buff": { "stats": { S.LUCK: 0.06, S.INTELLIGENCE: 0.02 } }, "curse": { "stats": { S.STRENGTH: -0.03 } },
		"offer": "(Placeholder) I saw how your climb ends. I'd like to see if you can change it." },
	&"wanderlust": { "name": "Wanderlust", "title": "Deity of Wanderlust", "kind": "god", "ending": &"neutral",
		"likes": [&"vigilante", &"hero"], "dislikes": [], "temper": 0.4,
		"approves": [&"trade", &"ally"], "forbids": [&"fortify", &"war", &"raid"],
		"skill": &"trailblazer",
		"buff": { "stats": { S.AGILITY: 0.04 }, "xp_mult": 0.1 }, "curse": { "gold_mult": -0.05 },
		"offer": "(Placeholder) The top was never the point. The climb was. Keep climbing." },
}

## Live table: the base domains plus anything DLC registered.
static var domains: Dictionary = BASE_DOMAINS.duplicate(true)

## Past gods join other runs as beings of this pantheon.
const PANTHEON := "Ascended"
## Being ids for past gods: "ascended_" + the character's legacy id.
const BEING_PREFIX := "ascended_"
const TITLE_MAX_LENGTH := 40
## What a guild can do on its turn (GuildAI), for "approves" / "forbids".
const GUILD_ACTIONS := [&"trade", &"fortify", &"raid", &"war", &"ally"]
## What an ascending player may become (Hayden: the player chooses).
const KINDS := ["god", "demon", "devil"]
## A player-god's blessing is a bit stronger than a mythology god's (Hayden:
## they conquered the tower): every buff number x this. Curses stay.
const PLAYER_GOD_BUFF := 1.25


static func register_domain(id: StringName, def: Dictionary) -> void:
	domains[id] = def


static func get_domain(id: StringName) -> Dictionary:
	return domains.get(id, {})


## The domains an ending suggests, its own first. The Wanderer (or any
## ending without domains of its own) may also pick any other domain.
static func for_ending(ending_id: StringName) -> Array:
	var by_name := func(a, b): return String(a) < String(b)   # StringNames don't sort alphabetically
	var own := domains.keys().filter(func(id): return domains[id].get("ending", &"") == ending_id)
	own.sort_custom(by_name)
	if not own.is_empty() and ending_id != &"neutral":
		return own
	var rest := domains.keys().filter(func(id): return not own.has(id))
	rest.sort_custom(by_name)
	return own + rest


## Cleans a typed title: trimmed, no control characters or brackets (BBCode),
## at most TITLE_MAX_LENGTH. Empty = use the domain's default.
static func clean_title(t: String, domain_id: StringName) -> String:
	var out := ""
	for ch in t.strip_edges():
		if ch.unicode_at(0) >= 32 and not ch in ["[", "]", "{", "}"]:
			out += ch
	out = out.left(TITLE_MAX_LENGTH).strip_edges()
	return out if out != "" else str(get_domain(domain_id).get("title", "Deity"))


## A valid kind, else the domain's suggestion.
static func clean_kind(kind: String, domain_id: StringName) -> String:
	return kind if kind in KINDS else str(get_domain(domain_id).get("kind", "god"))


static func being_id_for(legacy_id: String) -> StringName:
	var safe := ""
	for ch in legacy_id:
		safe += ch if (ch >= "0" and ch <= "9") or (ch >= "a" and ch <= "z") or ch == "-" else "_"
	return StringName(BEING_PREFIX + safe)


static func is_legacy_being(id: StringName) -> bool:
	return String(id).begins_with(BEING_PREFIX)


## A BeingLibrary spec for a past god: `god_name` (the character), their
## title, domain and kind. Their buff is PLAYER_GOD_BUFF stronger. Rivals:
## the roster's beings with the opposite values, at most 2.
static func being_spec(god_name: String, title: String, domain_id: StringName, kind: String = "") -> Dictionary:
	var d := get_domain(domain_id)
	var spec := {
		"name": god_name, "title": title, "kind": clean_kind(kind, domain_id), "pantheon": PANTHEON,
		"likes": d.get("likes", []), "dislikes": d.get("dislikes", []), "temper": d.get("temper", 0.5),
		"skill": d.get("skill", &""), "buff": BeingLibrary._scaled(d.get("buff", {}), PLAYER_GOD_BUFF),
		"curse": d.get("curse", {}), "offer": d.get("offer", ""), "domain": domain_id,
	}
	var rivals := []
	var ids := BeingLibrary.SPECS.keys()
	ids.sort_custom(func(a, b): return String(a) < String(b))   # by name (StringNames sort by address)
	for id in ids:
		var b: Dictionary = BeingLibrary.SPECS[id]
		var likes_what_we_hate: bool = b.get("likes", []).any(func(r): return spec.dislikes.has(r))
		var hates_what_we_like: bool = b.get("dislikes", []).any(func(r): return spec.likes.has(r))
		if likes_what_we_hate and hates_what_we_like and rivals.size() < 2:
			rivals.append(id)
	spec["rivals"] = rivals
	return spec


## Problems with the domains ([] = all good). Run by the tests.
static func validate() -> PackedStringArray:
	var problems: PackedStringArray = []
	var ending_ids := RouteLibrary.endings.map(func(e): return e.id)
	for id in domains:
		var d: Dictionary = domains[id]
		for k in ["name", "title", "offer"]:
			if str(d.get(k, "")) == "":
				problems.append("%s: missing %s" % [id, k])
		if not d.get("kind", "") in KINDS:
			problems.append("%s: kind must be god/demon/devil" % id)
		if not ending_ids.has(d.get("ending", &"")):
			problems.append("%s: unknown ending %s" % [id, d.get("ending")])
		for r in d.get("likes", []) + d.get("dislikes", []):
			if not RouteLibrary.routes.has(r):
				problems.append("%s: unknown route %s in its values" % [id, r])
		if d.get("likes", []).is_empty():
			problems.append("%s: likes no route" % id)
		if SkillLibrary.get_skill_or_null(d.get("skill", &"")) == null:
			problems.append("%s: unknown skill %s" % [id, d.get("skill")])
		var judged: Array = d.get("approves", []) + d.get("forbids", [])
		for a in judged:
			if not a in GUILD_ACTIONS:
				problems.append("%s: unknown guild action %s" % [id, a])
		for a in GUILD_ACTIONS:
			if judged.count(a) != 1:
				problems.append("%s: must approve OR forbid %s (exactly once)" % [id, a])
		for side in ["buff", "curse"]:
			if (d.get(side, {}) as Dictionary).is_empty():
				problems.append("%s: needs a %s" % [id, side])
			for k in d.get(side, {}):
				if not k in BeingLibrary.EFFECT_KEYS:
					problems.append("%s: unknown effect %s" % [id, k])
	for e in ending_ids:
		if not domains.values().any(func(d): return d.get("ending", &"") == e):
			problems.append("ending %s has no domain" % e)
	return problems
