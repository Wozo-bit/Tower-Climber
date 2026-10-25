class_name GuildAI
extends RefCounted
## The guilds think for themselves. Every floor the player climbs is one
## "tick": every guild earns income from its territories, then may take ONE
## action chosen from its personality (GuildLibrary "personality": greed,
## aggression, honor) and its situation:
##   trade    - safe extra income (honest guilds like it)
##   fortify  - pay for defense (more likely when threatened)
##   raid     - steal part of another guild's treasury (greedy guilds; rivals first;
##              can hit the player's own guild)
##   ally     - pact with a guild that shares its patron's values (honorable guilds)
##   war      - attack a neighbor or rival for one of its territories (aggressive guilds)
## Wars then progress (GuildState.progress_wars). Everything lands in the
## tower news. Local simulation only: no network, no online AI.
##
## Tuning numbers below are placeholders for the balance pass.

const INCOME_PER_TERRITORY := 60
## Chance a guild does anything at all on a given floor (beyond income).
const ACT_CHANCE := 0.4
const TRADE_GOLD := 120
const FORTIFY_COST := 200
const MAX_DEFENSE := 5
const RAID_SHARE := 0.08
const RAID_MIN_TREASURY := 300
const WAR_COST := 600
const NOISE := 0.3
## Base utilities of each action (tuned with tools/balance_sim "guilds" mode:
## with no patron, something notable every 2-4 floors and 1-2 wars per 10).
const TRADE_WEIGHT := 0.6
const FORTIFY_WEIGHT := 0.0
const RAID_WEIGHT := -0.35
const WAR_WEIGHT := 0.0
const ALLY_WEIGHT := 0.15
## Your patron's temper pulls the guild you're in toward (or away from) war.
const PATRON_PULL := 0.6
## Guilds that feud with your patrons want war with your side this much more.
const FEUD_WAR_BONUS := 0.5
## A guild next to your new guild is tempted to take its floors.
const UPSTART_WAR_BONUS := 0.2


## One tick for every guild. `rng` should be seeded per run + floor so a run
## replays the same way.
static func tick(gs: GuildState, rng: RandomNumberGenerator) -> void:
	var ids := GuildLibrary.guilds.keys()
	ids.sort()
	for g in ids:
		var held := gs.territories_of(g).size()
		gs.treasury[g] = gs.treasury_of(g) + INCOME_PER_TERRITORY * held
	gs.player_guild_income()
	for g in ids:
		if g == GuildLibrary.PLAYER_GUILD or gs.territories_of(g).is_empty():
			continue   # the player runs their own guild; guilds with no floors are broken
		if rng.randf() >= ACT_CHANCE:
			continue
		_act(gs, g, rng)
	gs.progress_wars(rng)


static func _act(gs: GuildState, g: StringName, rng: RandomNumberGenerator) -> void:
	var p: Dictionary = GuildLibrary.get_guild(g).get("personality", {})
	var greed: float = p.get("greed", 0.5)
	var aggression: float = p.get("aggression", 0.5)
	var honor: float = p.get("honor", 0.5)
	var temper := gs.patron_temper()
	var feud := gs.feud_guilds().has(g)
	if gs.your_side().has(g):   # your patron's mood rubs off on your guild
		aggression = lerpf(aggression, temper, PATRON_PULL)
	var options := {}
	# Quiet business (trade) is the usual choice; the rest makes the news.
	options["trade"] = TRADE_WEIGHT + (1.0 - greed) * 0.3
	options["fortify"] = FORTIFY_WEIGHT + (0.5 if gs.is_at_war(g) else 0.0) \
		if gs.treasury_of(g) >= FORTIFY_COST and gs.defense_of(g) < MAX_DEFENSE else -1.0
	var raid_target := _raid_target(gs, g)
	options["raid"] = RAID_WEIGHT + greed * 0.8 + aggression * 0.2 - honor * 0.6 if raid_target != &"" else -1.0
	var war_target := _war_target(gs, g)
	options["war"] = WAR_WEIGHT + aggression * 0.9 - honor * 0.2 \
		if war_target.size() == 2 and gs.treasury_of(g) >= WAR_COST else -1.0
	if options["war"] >= 0.0 and gs.your_side().has(war_target[0]):
		# Attacking you: a calm patron keeps them off, a warlike one invites it; feuds come anyway.
		options["war"] = options["war"] * (0.5 + temper) + (FEUD_WAR_BONUS if feud else 0.0) \
			+ (UPSTART_WAR_BONUS if war_target[0] == GuildLibrary.PLAYER_GUILD else 0.0)
	var ally := _ally_target(gs, g)
	options["ally"] = ALLY_WEIGHT + honor * 0.5 if ally != &"" else -1.0
	var best := ""
	var best_u := -INF
	for a in options:
		if options[a] < 0.0:
			continue
		var u: float = options[a] + rng.randf() * NOISE
		if u > best_u:
			best_u = u
			best = a
	match best:
		"trade":
			gs.treasury[g] = gs.treasury_of(g) + TRADE_GOLD
		"fortify":
			gs.treasury[g] = gs.treasury_of(g) - FORTIFY_COST
			gs.defense[g] = gs.defense_of(g) + 1
			gs.add_news("%s fortifies its floors." % GuildLibrary.guild_name(g))
		"raid":
			gs.raid(g, raid_target, rng)
		"war":
			gs.treasury[g] = gs.treasury_of(g) - WAR_COST
			gs.declare_war(g, war_target[0], war_target[1])
		"ally":
			gs.make_alliance(g, ally)


## Who a guild would rob: a rival first, else the richest guild it isn't allied with.
static func _raid_target(gs: GuildState, g: StringName) -> StringName:
	var best := &""
	var best_score := -1.0
	for other in GuildLibrary.guilds:
		if other == g or gs.allied(g, other) or gs.treasury_of(other) < RAID_MIN_TREASURY:
			continue
		var score := float(gs.treasury_of(other)) + (5000.0 if GuildLibrary.rivals_of(g).has(other) else 0.0)
		if score > best_score:
			best_score = score
			best = other
	return best


## [defender, territory] a guild would attack: a rival's territory first,
## else a neighbouring territory (next to one it holds). [] if none.
static func _war_target(gs: GuildState, g: StringName) -> Array:
	if gs.is_at_war(g):
		return []
	var mine := gs.territories_of(g)
	var feud := gs.feud_guilds().has(g)
	var candidates := []
	for t in gs.owners.size():
		var owner: StringName = gs.owners[t]
		if owner == g or owner == &"" or gs.allied(g, owner) or gs.is_at_war(owner):
			continue
		var rival := GuildLibrary.rivals_of(g).has(owner)
		var near := mine.any(func(m): return absi(m - t) == 1)
		if feud and gs.your_side().has(owner):
			candidates.append([owner, t, 3])   # a feud: your floors first
		elif near and owner == GuildLibrary.PLAYER_GUILD:
			candidates.append([owner, t, 2])   # an upstart guild next door is tempting
		elif rival or near:
			candidates.append([owner, t, 2 if rival else 1])
	if candidates.is_empty():
		return []
	candidates.sort_custom(func(a, b): return a[2] > b[2] or (a[2] == b[2] and a[1] < b[1]))
	return [candidates[0][0], candidates[0][1]]


## A guild whose patron likes the same routes, that isn't a rival, enemy or ally yet.
static func _ally_target(gs: GuildState, g: StringName) -> StringName:
	var likes: Array = GuildLibrary.values_of(g).get("likes", [])
	for other in GuildLibrary.guilds:
		if other == g or other == GuildLibrary.PLAYER_GUILD or gs.allied(g, other) or gs.war_between(g, other) \
				or GuildLibrary.rivals_of(g).has(other):
			continue
		if GuildLibrary.values_of(other).get("likes", []).any(func(r): return likes.has(r)):
			return other
	return &""
