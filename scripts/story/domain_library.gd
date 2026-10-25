class_name DomainLibrary
extends RefCounted
## Divine domains (Hayden 2026-10-25): conquering the tower makes your
## character a god. The ending you reached suggests a few domains, you pick
## one and name your title ("God of Valor", or your own). The domain sets the
## god's values, temper, kind and blessing, in the same compact format as
## BeingLibrary.SPECS, so a past god can join other characters' runs as a
## being (GameState.refresh_legacy_gods).
##
## A domain:
##   "name": "Valor" · "title": the default title · "kind": god/demon/devil
##   "route": the ending route that suggests it (&"" = any ending)
##   "likes" / "dislikes": route ids (its values) · "temper": 0..1 (warlike)
##   "approves" / "forbids": guild actions (GuildAI: trade, fortify, raid,
##       war, ally) a sponsored guild earns or loses favor for
##   "skill": the blessed skill · "buff" / "curse": BeingLibrary effects
##   "offer": what it says when it offers a blessing (placeholder text)
##
## All names and text are placeholders to confirm with Hayden. DLC can add
## domains with register_domain().

const S := Stats.Type
const EL := Element.Type
const AF := Element.Affinity

const BASE_DOMAINS := {
	# --- Hero endings ---
	&"valor": { "name": "Valor", "title": "God of Valor", "kind": "god", "route": &"hero",
		"likes": [&"hero"], "dislikes": [&"villain"], "temper": 0.6, "approves": [&"war"], "forbids": [&"raid"],
		"skill": &"valor_strike",
		"buff": { "stats": { S.STRENGTH: 0.05, S.STAMINA: 0.03 } }, "curse": { "stats": { S.LUCK: -0.04 } },
		"offer": "(Placeholder) I climbed this tower with nothing but nerve. Take some of mine." },
	&"justice": { "name": "Justice", "title": "God of Justice", "kind": "god", "route": &"hero",
		"likes": [&"hero"], "dislikes": [&"villain", &"vigilante"], "temper": 0.5, "approves": [&"fortify"], "forbids": [&"raid"],
		"skill": &"verdict_of_light",
		"buff": { "element_power": { EL.HOLY: 0.15 }, "stats": { S.INTELLIGENCE: 0.03 } },
		"curse": { "gold_mult": -0.05 },
		"offer": "(Placeholder) The tower has laws now. Mine. Uphold them and I'll stand behind you." },
	&"mercy": { "name": "Mercy", "title": "Goddess of Mercy", "kind": "god", "route": &"hero",
		"likes": [&"hero", &"vigilante"], "dislikes": [&"villain"], "temper": 0.1, "approves": [&"ally"], "forbids": [&"war", &"raid"],
		"skill": &"grace",
		"buff": { "regen_pct": 0.05, "stats": { S.HEALTH: 0.03 } }, "curse": { "stats": { S.STRENGTH: -0.03 } },
		"offer": "(Placeholder) I lost too many friends on the way up. I won't lose you." },

	# --- Villain endings ---
	&"tyranny": { "name": "Tyranny", "title": "God of Tyranny", "kind": "demon", "route": &"villain",
		"likes": [&"villain"], "dislikes": [&"hero"], "temper": 0.9, "approves": [&"war"], "forbids": [&"ally"],
		"skill": &"iron_decree",
		"buff": { "stats": { S.STRENGTH: 0.05, S.HEALTH: 0.03 } },
		"curse": { "affinities": { EL.HOLY: AF.WEAK } },
		"offer": "(Placeholder) Every floor bows to me now. Kneel, and some of them will bow to you." },
	&"greed": { "name": "Greed", "title": "God of Greed", "kind": "devil", "route": &"villain",
		"likes": [&"villain", &"vigilante"], "dislikes": [&"hero"], "temper": 0.5, "approves": [&"raid", &"trade"], "forbids": [&"fortify"],
		"skill": &"golden_hand",
		"buff": { "gold_mult": 0.15, "stats": { S.LUCK: 0.03 } }, "curse": { "price_mult": 0.1 },
		"offer": "(Placeholder) I took the tower and everything in it. There's plenty left over. For a price." },
	&"ruin": { "name": "Ruin", "title": "God of Ruin", "kind": "demon", "route": &"villain",
		"likes": [&"villain"], "dislikes": [&"hero", &"vigilante"], "temper": 0.95, "approves": [&"war", &"raid"], "forbids": [&"ally", &"trade"],
		"skill": &"ruin_wave",
		"buff": { "element_power": { EL.DARK: 0.15 } }, "curse": { "stats": { S.INTELLIGENCE: -0.04 } },
		"offer": "(Placeholder) I left the floors below in ashes. Help me finish the rest." },

	# --- Vigilante endings ---
	&"vengeance": { "name": "Vengeance", "title": "God of Vengeance", "kind": "devil", "route": &"vigilante",
		"likes": [&"vigilante"], "dislikes": [&"hero"], "temper": 0.85, "approves": [&"war", &"raid"], "forbids": [&"ally"],
		"skill": &"retribution",
		"buff": { "stats": { S.LUCK: 0.04 }, "element_power": { EL.DARK: 0.1 } }, "curse": { "stats": { S.STAMINA: -0.03 } },
		"offer": "(Placeholder) I remember every wrong done to me on the way up. Let me remember yours." },
	&"shadow": { "name": "Shadow", "title": "God of Shadows", "kind": "devil", "route": &"vigilante",
		"likes": [&"vigilante", &"villain"], "dislikes": [&"hero"], "temper": 0.5, "approves": [&"raid"], "forbids": [&"war"],
		"skill": &"night_veil",
		"buff": { "stats": { S.AGILITY: 0.05, S.LUCK: 0.03 } }, "curse": { "stats": { S.HEALTH: -0.03 } },
		"offer": "(Placeholder) No one saw me climb. No one will see you either." },
	&"freedom": { "name": "Freedom", "title": "God of Freedom", "kind": "god", "route": &"vigilante",
		"likes": [&"vigilante", &"hero"], "dislikes": [&"villain"], "temper": 0.6, "approves": [&"ally"], "forbids": [&"fortify"],
		"skill": &"unbound_gale",
		"buff": { "stats": { S.AGILITY: 0.04 }, "element_power": { EL.WIND: 0.15 } }, "curse": { "stats": { S.STAMINA: -0.03 } },
		"offer": "(Placeholder) No guild, no god, no master. That's how I climbed. Climb free with me." },
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


static func register_domain(id: StringName, def: Dictionary) -> void:
	domains[id] = def


static func get_domain(id: StringName) -> Dictionary:
	return domains.get(id, {})


## The domains an ending suggests (its route's domains). An ending with no
## route of its own (the Wanderer) lets you pick any domain.
static func for_ending(ending_id: StringName) -> Array:
	var out := domains.keys().filter(func(id): return domains[id].get("route", &"") == ending_id)
	if out.is_empty():
		out = domains.keys()
	out.sort()
	return out


## Cleans a typed title: trimmed, no control characters or brackets (BBCode),
## at most TITLE_MAX_LENGTH. Empty = use the domain's default.
static func clean_title(t: String, domain_id: StringName) -> String:
	var out := ""
	for ch in t.strip_edges():
		if ch.unicode_at(0) >= 32 and not ch in ["[", "]", "{", "}"]:
			out += ch
	out = out.left(TITLE_MAX_LENGTH).strip_edges()
	return out if out != "" else str(get_domain(domain_id).get("title", "God"))


static func being_id_for(legacy_id: String) -> StringName:
	var safe := ""
	for ch in legacy_id:
		safe += ch if (ch >= "0" and ch <= "9") or (ch >= "a" and ch <= "z") or ch == "-" else "_"
	return StringName(BEING_PREFIX + safe)


static func is_legacy_being(id: StringName) -> bool:
	return String(id).begins_with(BEING_PREFIX)


## A BeingLibrary spec for a past god: `god_name` (the character), their
## title and domain. Rivals: the roster's beings with the opposite values
## (they like what this god dislikes), at most 2, so its values make enemies.
static func being_spec(god_name: String, title: String, domain_id: StringName) -> Dictionary:
	var d := get_domain(domain_id)
	var spec := {
		"name": god_name, "title": title, "kind": d.get("kind", "god"), "pantheon": PANTHEON,
		"likes": d.get("likes", []), "dislikes": d.get("dislikes", []), "temper": d.get("temper", 0.5),
		"skill": d.get("skill", &""), "buff": d.get("buff", {}), "curse": d.get("curse", {}),
		"offer": d.get("offer", ""), "domain": domain_id,
	}
	var rivals := []
	var ids := BeingLibrary.SPECS.keys()
	ids.sort()
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
	for id in domains:
		var d: Dictionary = domains[id]
		for k in ["name", "title", "offer"]:
			if str(d.get(k, "")) == "":
				problems.append("%s: missing %s" % [id, k])
		if not d.get("kind", "") in ["god", "demon", "devil"]:
			problems.append("%s: kind must be god/demon/devil" % id)
		var route: StringName = d.get("route", &"")
		if route != &"" and not RouteLibrary.routes.has(route):
			problems.append("%s: unknown route %s" % [id, route])
		for r in d.get("likes", []) + d.get("dislikes", []):
			if not RouteLibrary.routes.has(r):
				problems.append("%s: unknown route %s in its values" % [id, r])
		if d.get("likes", []).is_empty():
			problems.append("%s: likes no route" % id)
		if SkillLibrary.get_skill_or_null(d.get("skill", &"")) == null:
			problems.append("%s: unknown skill %s" % [id, d.get("skill")])
		for a in d.get("approves", []) + d.get("forbids", []):
			if not a in GUILD_ACTIONS:
				problems.append("%s: unknown guild action %s" % [id, a])
		for side in ["buff", "curse"]:
			if (d.get(side, {}) as Dictionary).is_empty():
				problems.append("%s: needs a %s" % [id, side])
			for k in d.get(side, {}):
				if not k in BeingLibrary.EFFECT_KEYS:
					problems.append("%s: unknown effect %s" % [id, k])
	for route in RouteLibrary.routes:
		if not domains.values().any(func(d): return d.get("route", &"") == route):
			problems.append("route %s has no domain for its ending" % route)
	return problems
