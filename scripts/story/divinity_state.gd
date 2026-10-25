class_name DivinityState
extends RefCounted
## You, as a god (Hayden 2026-10-25). A character who conquered the tower and
## ascended (LegacyRecord.god_domain) climbs again in New Game+ as a god:
## they earn FAITH, sponsor guilds with CONTRACTS (your own guild is always
## yours), choose each one's BOON and the CURSE that pays for it, and set
## its STANCE. Sponsored guilds pay tithes (faith + gold) every floor.
## Lives in GameState.divinity, saved with the run. Inactive (active = false)
## for anyone who isn't a god.
##
## Placeholder numbers; tune with tools/balance_sim.

## Faith per floor for each territory a sponsored guild holds.
const FAITH_PER_TERRITORY := 3
## Share of a sponsored guild's territory income it tithes to you in gold.
const TITHE_GOLD_SHARE := 0.25
## Faith a contract costs; twice that for a guild whose values clash with yours.
const CONTRACT_FAITH := 60
## Divinity level from all the faith you've ever earned (level 1 at 0).
const LEVEL_FAITH := [0, 150, 400, 900, 1800]
## A contract's level (1-3) from its favor; favor grows each floor it serves you.
const CONTRACT_LEVEL_FAVOR := [0, 10, 25]
const FAVOR_PER_FLOOR := 1
## What a spurned patron thinks of you when you take its guild.
const SPURN_INTEREST := -20

## Boons (what you grant) and curses (what pays for them). A boon needs a
## curse of at least its cost. Every number scales with the contract level.
const BOONS := {
	&"wealth": { "name": "Wealth", "cost": 1, "desc": "+25% income from its floors per level." },
	&"bulwark": { "name": "Bulwark", "cost": 1, "desc": "+1 war strength per level when defending or attacking." },
	&"warhost": { "name": "Warhost", "cost": 2, "desc": "+2 war strength per level." },
	&"bargains": { "name": "Bargains", "cost": 1, "desc": "-5% prices on its floors per level." },
	&"devotion": { "name": "Devotion", "cost": 1, "desc": "+50% faith from it per level." },
}
const CURSES := {
	&"burden": { "name": "Burden", "weight": 1, "desc": "-15% income per level." },
	&"brittle": { "name": "Brittle", "weight": 1, "desc": "-0.75 war strength per level." },
	&"gouging": { "name": "Gouging", "weight": 1, "desc": "+5% prices on its floors per level." },
	&"zealotry": { "name": "Zealotry", "weight": 2, "desc": "Far more eager for war (aggression +0.25 per level)." },
	&"isolation": { "name": "Isolation", "weight": 2, "desc": "No other guild will ally with it." },
}
## Stances: how a sponsored guild's AI leans (added to its personality).
const STANCES := {
	&"": { "name": "Its own way" },
	&"aggressive": { "name": "Aggressive", "aggression": 0.4, "honor": -0.1 },
	&"defensive": { "name": "Defensive", "aggression": -0.3, "fortify": 0.5 },
	&"greedy": { "name": "Greedy", "greed": 0.4, "honor": -0.2 },
	&"devout": { "name": "Devout", "honor": 0.4, "greed": -0.2 },
}

var active := false
var domain: StringName = &""
var title := ""
## Your god as a being (DomainLibrary.being_id_for): guilds you sponsor take it as patron.
var god_id: StringName = &""
var faith := 0
var faith_earned := 0
## guild id -> { "boon", "curse", "stance", "favor", "since" }
var contracts: Dictionary = {}
## Patrons whose guilds you took: they hold it against you (rivals of your god).
var spurned: Array = []
var messages: Array[String] = []


## A god's New Game+: active from their Hall record.
static func for_record(rec: LegacyRecord) -> DivinityState:
	var d := DivinityState.new()
	if rec and rec.is_god():
		d.active = true
		d.domain = rec.god_domain
		d.title = rec.god_title
		d.god_id = DomainLibrary.being_id_for(rec.legacy_id)
	return d


func level() -> int:
	var lv := 0
	for t in LEVEL_FAITH:
		if faith_earned >= t:
			lv += 1
	return lv


## Contract slots for guilds other than your own: your own guild + 1 to
## start, one more per divinity level and per New Game+ cycle past the first.
func slots() -> int:
	return level() + maxi(0, GameState.ng_plus_cycle - 1)


func others() -> Array:
	return contracts.keys().filter(func(g): return g != GuildLibrary.PLAYER_GUILD)


func is_sponsor_of(g: StringName) -> bool:
	return active and contracts.has(g)


func contract_level(g: StringName) -> int:
	var favor: int = contracts.get(g, {}).get("favor", 0)
	var lv := 0
	for t in CONTRACT_LEVEL_FAVOR:
		if favor >= t:
			lv += 1
	return lv


## Faith to sponsor `g` (doubled when its values clash with your domain's).
func contract_cost(g: StringName) -> int:
	var theirs: Array = GuildLibrary.values_of(g).get("likes", [])
	var hate: Array = DomainLibrary.get_domain(domain).get("dislikes", [])
	return CONTRACT_FAITH * (2 if theirs.any(func(r): return hate.has(r)) else 1)


## Why you can't sponsor `g` now ("" = you can).
func contract_refusal(g: StringName) -> String:
	if not active:
		return "Only a god can sponsor guilds."
	if contracts.has(g):
		return "Already yours."
	if g == GuildLibrary.PLAYER_GUILD:
		return "Your own guild is always yours."
	if GuildLibrary.get_guild(g).is_empty() or GameState.guilds.territories_of(g).is_empty():
		return "That guild holds no floors."
	if others().size() >= slots():
		return "No free contract (divinity level %d: %d)." % [level(), slots()]
	if faith < contract_cost(g):
		return "Needs %d faith." % contract_cost(g)
	return ""


## Sign `g`: it takes your god as patron; its old patron is spurned.
func sponsor(g: StringName) -> bool:
	if contract_refusal(g) != "":
		return false
	faith -= contract_cost(g)
	var old: StringName = GuildLibrary.get_guild(g).get("patron", &"")
	contracts[g] = { "boon": &"wealth", "curse": &"burden", "stance": &"", "favor": 0, "since": GameState.floor_number }
	if old != &"" and old != god_id and not spurned.has(old):
		spurned.append(old)
		GameState.blessings.add_interest(old, SPURN_INTEREST)
	apply()
	GameState.guilds.add_news("%s now answers to %s, %s." % [GuildLibrary.guild_name(g), GameState.player.character_name, title], true)
	if old != &"" and old != god_id:
		messages.append("%s is furious that you took %s." % [BeingLibrary.get_being(old).get("name", "?"), GuildLibrary.guild_name(g)])
	return true


## Your own guild is always under your contract (no slot, no cost).
func claim_own_guild() -> void:
	if active and GameState.guilds.has_own_guild() and not contracts.has(GuildLibrary.PLAYER_GUILD):
		contracts[GuildLibrary.PLAYER_GUILD] = { "boon": &"wealth", "curse": &"burden", "stance": &"", "favor": 0,
			"since": GameState.floor_number }
		apply()


## Pick a boon and the curse that pays for it ("" = fine).
func set_terms(g: StringName, boon: StringName, curse: StringName) -> String:
	if not contracts.has(g):
		return "Not your guild."
	if not BOONS.has(boon) or not CURSES.has(curse):
		return "Unknown boon or curse."
	if CURSES[curse].weight < BOONS[boon].cost:
		return "%s needs a heavier curse." % BOONS[boon].name
	contracts[g]["boon"] = boon
	contracts[g]["curse"] = curse
	return ""


func set_stance(g: StringName, stance: StringName) -> bool:
	if not contracts.has(g) or g == GuildLibrary.PLAYER_GUILD or not STANCES.has(stance):
		return false
	contracts[g]["stance"] = stance
	return true


## Your god's being (always registered in your own runs, never offered to
## you) and its patronage of your guilds. Call after any change, and after
## loading (GuildLibrary is reset each run).
func apply() -> void:
	if not active:
		return
	GameState.register_self_god(self)
	for g in contracts:
		if GuildLibrary.guilds.has(g):
			GuildLibrary.guilds[g]["patron"] = god_id
	if contracts.has(GuildLibrary.PLAYER_GUILD) and GameState.guilds.has_own_guild():
		GameState.guilds.player_guild["patron"] = god_id


# --- Effects (read by GuildAI / GuildState) --------------------------------

func _boon(g: StringName, id: StringName) -> int:
	return contract_level(g) if is_sponsor_of(g) and contracts[g].boon == id else 0


func _curse(g: StringName, id: StringName) -> int:
	return contract_level(g) if is_sponsor_of(g) and contracts[g].curse == id else 0


func income_mult(g: StringName) -> float:
	return 1.0 + 0.25 * _boon(g, &"wealth") - 0.15 * _curse(g, &"burden")


func war_bonus(g: StringName) -> float:
	return 1.0 * _boon(g, &"bulwark") + 2.0 * _boon(g, &"warhost") - 0.75 * _curse(g, &"brittle")


func price_mult(g: StringName) -> float:
	return 1.0 - 0.05 * _boon(g, &"bargains") + 0.05 * _curse(g, &"gouging")


func can_ally(g: StringName) -> bool:
	return _curse(g, &"isolation") == 0


## { "greed", "aggression", "honor", "fortify" } added to the guild's AI.
func personality_shift(g: StringName) -> Dictionary:
	if not is_sponsor_of(g):
		return {}
	var out: Dictionary = STANCES.get(contracts[g].get("stance", &""), {}).duplicate()
	out.erase("name")
	out["aggression"] = out.get("aggression", 0.0) + 0.25 * _curse(g, &"zealotry")
	return out


# --- Each floor ----------------------------------------------------------

## Tithes and favor, after the guilds' turn.
func on_floor() -> void:
	if not active:
		return
	claim_own_guild()
	var gs: GuildState = GameState.guilds
	var faith_gain := 0
	var gold_gain := 0
	for g in contracts.keys():
		var held := gs.territories_of(g).size()
		if held == 0 and g != GuildLibrary.PLAYER_GUILD:
			continue
		contracts[g]["favor"] = contracts[g].favor + FAVOR_PER_FLOOR
		faith_gain += roundi(FAITH_PER_TERRITORY * held * (1.0 + 0.5 * _boon(g, &"devotion")))
		if g != GuildLibrary.PLAYER_GUILD:
			var tithe := mini(gs.treasury_of(g), roundi(GuildAI.INCOME_PER_TERRITORY * held * TITHE_GOLD_SHARE))
			gs.treasury[g] = gs.treasury_of(g) - tithe
			gold_gain += tithe
	add_faith(faith_gain)
	GameState.player.gold += gold_gain
	if faith_gain > 0 or gold_gain > 0:
		messages.append("Tithes: +%d faith, +%d gold." % [faith_gain, gold_gain])


func add_faith(n: int) -> void:
	var before := level()
	faith += n
	faith_earned += maxi(0, n)
	if level() > before:
		messages.append("Your divinity grows (level %d): %d contract%s." % [level(), slots(), "" if slots() == 1 else "s"])


# --- Save ----------------------------------------------------------------

func to_dict() -> Dictionary:
	var c := {}
	for g in contracts:
		var e: Dictionary = contracts[g]
		c[String(g)] = { "boon": String(e.boon), "curse": String(e.curse), "stance": String(e.stance),
			"favor": e.favor, "since": e.since }
	return { "active": active, "domain": String(domain), "title": title, "god_id": String(god_id),
		"faith": faith, "faith_earned": faith_earned, "contracts": c, "spurned": spurned.map(func(b): return String(b)) }


## `rec` = the player's Hall record: you're only a god if the Hall says so.
static func from_dict(d: Dictionary, rec: LegacyRecord) -> DivinityState:
	var st := DivinityState.for_record(rec)
	if not st.active or not SaveSerializer._b(d, "active", false):
		return st
	var S := SaveSerializer
	st.faith = S._i(d, "faith", 0, 0, 1000000)
	st.faith_earned = S._i(d, "faith_earned", st.faith, st.faith, 10000000)
	var cd := S._d(d, "contracts")
	for g in cd:
		if not (g is String and cd[g] is Dictionary):
			continue
		var gid := StringName(g)
		if not GuildLibrary.BASE_GUILDS.has(gid) and gid != GuildLibrary.PLAYER_GUILD:
			continue
		var e: Dictionary = cd[g]
		var boon := StringName(S._s(e, "boon", "wealth", 32))
		var curse := StringName(S._s(e, "curse", "burden", 32))
		if not BOONS.has(boon) or not CURSES.has(curse) or CURSES[curse].weight < BOONS[boon].cost:
			boon = &"wealth"
			curse = &"burden"
		var stance := StringName(S._s(e, "stance", "", 32))
		st.contracts[gid] = { "boon": boon, "curse": curse, "stance": stance if STANCES.has(stance) else &"",
			"favor": S._i(e, "favor", 0, 0, 100000), "since": S._i(e, "since", 1, 1, 100000) }
	for b in S._a(d, "spurned"):
		if b is String and BeingLibrary.SPECS.has(StringName(b)):
			st.spurned.append(StringName(b))
	return st
