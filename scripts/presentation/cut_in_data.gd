class_name CutInData
extends RefCounted
## Builds the cut-in splashes (CutIns autoload plays them). Each returns
##   { "kind", "title", "subtitle", "art": Texture2D or null, "color", "glyph", "duration" }
## Art comes from Assets ("cutins/<id>" first, then the usual portrait/enemy
## art); with no art the splash shows a big glyph instead.
##
## When they play (chosen by Hayden): boss / miniboss / roamer / champion
## fights, ultimate skills (Legendary+ tier or a blessed skill), gods and
## devils appearing, level-ups and class changes, and wars involving your
## guild (either side declaring).

const DURATION := 1.6
const SKILL_DURATION := 1.0

const C_BOSS := Color(1.0, 0.3, 0.25)
const C_MINIBOSS := Color(1.0, 0.8, 0.25)
const C_ROAMER := Color(0.8, 0.45, 1.0)
const C_WAR := Color(1.0, 0.35, 0.3)
const C_ADVANCE := Color(1.0, 0.85, 0.45)
const BEING_COLORS := { "god": Color(1.0, 0.9, 0.55), "demon": Color(0.95, 0.3, 0.3), "devil": Color(0.7, 0.4, 1.0) }


static func make(kind: String, title: String, subtitle: String, art: Texture2D, color: Color, glyph: String,
		duration := DURATION) -> Dictionary:
	return { "kind": kind, "title": title, "subtitle": subtitle, "art": art, "color": color, "glyph": glyph,
		"duration": duration }


## Fights worth a splash.
static func is_big_fight(kind: String) -> bool:
	return kind in ["miniboss", "boss", "roaming", "champion"]


## A guardian/boss fight. `group` = enemy ids or EnemyDefs, leader first.
static func boss(kind: String, group: Array, floor_n: int, info: Dictionary = {}) -> Dictionary:
	var leader = group[0] if not group.is_empty() else null
	var def: EnemyDef = leader if leader is EnemyDef else EnemyLibrary.get_enemy_or_null(StringName(str(leader)))
	var id: StringName = def.id if def else &""
	var title := def.display_name if def else "???"
	var art := Assets.first([["cutins", id], ["enemies", id]])
	var sponsor := ""
	if def and def.patron != &"":
		sponsor = "\nSponsored by %s" % BeingLibrary.full_name(def.patron)
	for rid in NpcLibrary.recruits_met_by("captive"):   # someone you can free by winning
		if def and NpcLibrary.recruit_info(rid).get("captive_of", &"") == def.id and not GameState.has_recruited(rid):
			sponsor += "  ·  Holding %s captive" % NpcLibrary.get_npc(rid).name
	match kind:
		"boss":
			var sub := "FINAL BOSS" if floor_n >= GameState.FINAL_FLOOR else "BOSS  ·  Floor %d" % floor_n
			return make("boss", title, sub + sponsor, art, C_BOSS, "☠")
		"miniboss":
			return make("miniboss", title, "MINIBOSS  ·  Floor %d" % floor_n, art, C_MINIBOSS, "!")
		"roaming":
			var rinfo := StageLibrary.roamer_info(info.get("roamer_id", &""))
			if rinfo.get("spawn") == "secret":
				return make("roaming", "???", "Something has found you", art, C_ROAMER, "?")
			return make("roaming", title, "ROAMING BOSS", art, C_ROAMER, "?")
		"champion":
			var guild: StringName = info.get("guild", &"")
			return make("champion", title, "CHAMPION of %s" % GuildLibrary.guild_name(guild),
				Assets.first([["cutins", id], ["guilds", guild], ["enemies", id]]), Color.WHITE, "⚔")
	return make(kind, title, "", art, C_BOSS, "!")


## Ultimate skills get a splash: Legendary / Unique tier, or a blessed skill.
static func is_ultimate(skill: SkillDef) -> bool:
	if skill == null:
		return false
	return skill.tier >= SkillTier.Tier.LEGENDARY or is_blessed_skill(skill.id)


static func is_blessed_skill(id: StringName) -> bool:
	for b in BeingLibrary.beings.values():
		if StringName(str(b.get("skill", ""))) == id:
			return true
	return false


static func skill(caster: Combatant, s: SkillDef) -> Dictionary:
	var label := "Blessed skill" if is_blessed_skill(s.id) else "%s skill" % SkillTier.name_of(s.tier)
	var art := Assets.texture("cutins", "skill_%s" % s.id)
	if art == null and caster:
		art = Assets.combatant_art(caster)
	var col: Color = SkillTier.color_of(s.tier) if not is_blessed_skill(s.id) else C_ADVANCE
	return make("skill", s.display_name, "%s  ·  %s" % [caster.display_name if caster else "?", label], art, col, "✦",
		SKILL_DURATION)


## A god, demon or devil shows up (shrines, boss visits, warnings, punishment).
static func being(id: StringName) -> Dictionary:
	var b := BeingLibrary.get_being(id)
	var kind: String = b.get("kind", "god")
	var sub: String = { "god": "(Placeholder) A god turns its gaze upon you",
		"demon": "(Placeholder) A demon takes an interest",
		"devil": "(Placeholder) A devil has an offer" }.get(kind, "")
	return make("being", BeingLibrary.full_name(id), sub, Assets.first([["cutins", id], ["beings", id]]),
		BEING_COLORS.get(kind, Color.WHITE), "✧")


## `ups` = [[name, new level], ...]. `class_ready` = someone can pick a class now.
static func level_up(ups: Array, class_ready := false) -> Dictionary:
	var parts: PackedStringArray = []
	for u in ups:
		parts.append("%s  Lv %d" % [u[0], u[1]])
	var sub := "   ·   ".join(parts)
	if class_ready:
		sub += "\nA class can be chosen! (Tab)"
	return make("level_up", "LEVEL UP", sub, Assets.texture("cutins", "level_up"), UITheme.color("accent"), "▲")


## A class chosen (first class) or advanced.
static func class_change(c: CharacterData, def: ClassDef, first_class: bool) -> Dictionary:
	var art := Assets.first([["cutins", "class_%s" % def.id], ["classes", def.id]])
	if art == null:
		art = Assets.portrait_for(c)
	return make("advance", "CLASS ACQUIRED" if first_class else "CLASS ADVANCED",
		"%s is now a %s" % [c.character_name, def.display_name], art, C_ADVANCE, "✦")


## NG+ Ascension: a tier-3 line goes beyond mortal limits.
static func ascension(c: CharacterData) -> Dictionary:
	var art := Assets.portrait_for(c)
	return make("advance", "ASCENDED", "%s is now %s" % [c.character_name, c.class_title()], art, C_ADVANCE, "✧")


## A war that involves your guild (or the guild you're in), either way round.
static func war(attacker: StringName, defender: StringName, territory: int) -> Dictionary:
	var gs: GuildState = GameState.guilds
	var mine := [gs.member, GuildLibrary.PLAYER_GUILD if gs.has_own_guild() else &""]
	var enemy := defender if mine.has(attacker) else attacker
	var sub := "%s declares war on %s\nover %s" % [GuildLibrary.guild_name(attacker), GuildLibrary.guild_name(defender),
		GuildLibrary.territory_floors(territory)]
	return make("war", "WAR DECLARED", sub, Assets.first([["cutins", "war_%s" % enemy], ["guilds", enemy]]), C_WAR, "⚔")
