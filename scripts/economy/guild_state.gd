class_name GuildState
extends RefCounted
## This run's guilds and economy: who owns each territory, your reputation
## with every guild, your membership and rank, guild treasuries, and the
## market (supply and demand per territory). Lives in GameState.guilds,
## saved with the run, reset in New Game+.

## Any guild takes you at this reputation (unless its patron hates your route).
const JOIN_REP := 0
## Leaving a guild costs this much reputation with it.
const LEAVE_PENALTY := 25
## Joining a guild costs this much with guilds whose patrons are its rivals.
const RIVAL_JOIN_PENALTY := 10
const REP_MIN := -100
const REP_MAX := 100
const START_TREASURY := 1000

# --- Market: supply and demand per territory ---
## Each buy/sell pushes that good's price in that territory; prices drift back
## by MARKET_DECAY every floor you climb.
const BUY_PRESSURE := 0.05
const SELL_PRESSURE := 0.08
const MARKET_DECAY := 0.8
const BUY_MULT_RANGE := Vector2(0.7, 1.6)
const SELL_MULT_RANGE := Vector2(0.3, 1.3)

## territory index -> guild id (index wraps past the end)
var owners: Array = GuildLibrary.START_OWNERS.duplicate()
## guild id -> reputation (-100..100)
var rep: Dictionary = {}
## The guild you're in (&"" = none) and your rank in it.
var member: StringName = &""
var rank := 0
## guild id -> gold
var treasury: Dictionary = {}
## territory index -> { good key: pressure }
var market: Dictionary = {}
## Floor you were last paid on (Officers / Masters).
var last_pay_floor := 0
var messages: Array[String] = []


# =========================================================
# Territories
# =========================================================

func owner_of_territory(t: int) -> StringName:
	return owners[t % owners.size()] if not owners.is_empty() else &""


func owner_of_floor(floor_n: int) -> StringName:
	return owner_of_territory(GuildLibrary.territory_of(floor_n))


## Territory indexes (0..owners.size()-1) a guild holds right now.
func territories_of(g: StringName) -> Array:
	var out := []
	for t in owners.size():
		if owners[t] == g:
			out.append(t)
	return out


# =========================================================
# Reputation, joining, ranks
# =========================================================

func rep_of(g: StringName) -> int:
	return rep.get(g, 0)


## "Hated", "Disliked", "Neutral", "Liked", "Trusted", "Honored"
static func standing_name(r: int) -> String:
	if r <= -50: return "Hated"
	if r < -10: return "Disliked"
	if r < 10: return "Neutral"
	if r < 40: return "Liked"
	if r < 75: return "Trusted"
	return "Honored"


func add_rep(g: StringName, amount: int) -> void:
	if not GuildLibrary.guilds.has(g) or amount == 0:
		return
	rep[g] = clampi(rep_of(g) + amount, REP_MIN, REP_MAX)
	if g == member:
		_update_rank()


## Why a guild won't take you ("" = it will).
func join_refusal(g: StringName) -> String:
	if member == g:
		return "You're already a member."
	if member != &"":
		return "You're already in %s." % GuildLibrary.guild_name(member)
	if rep_of(g) < JOIN_REP:
		return "They don't trust you."
	var r: StringName = GameState.route.current()
	if r != &"" and GuildLibrary.values_of(g).get("dislikes", []).has(r):
		return "They want nothing to do with someone like you."
	return ""


func can_join(g: StringName) -> bool:
	return GuildLibrary.guilds.has(g) and join_refusal(g) == ""


func join(g: StringName) -> bool:
	if not can_join(g):
		return false
	member = g
	rank = 0
	last_pay_floor = GameState.floor_number
	for rival in GuildLibrary.rivals_of(g):
		add_rep(rival, -RIVAL_JOIN_PENALTY)
	_update_rank()
	messages.append("You joined %s as a %s." % [GuildLibrary.guild_name(g), GuildLibrary.rank_name(rank)])
	return true


func leave() -> bool:
	if member == &"":
		return false
	var g := member
	member = &""
	rank = 0
	add_rep(g, -LEAVE_PENALTY)
	messages.append("You left %s. They won't forget it." % GuildLibrary.guild_name(g))
	return true


static func rank_for(r: int) -> int:
	var out := 0
	for i in GuildLibrary.RANK_REP.size():
		if r >= GuildLibrary.RANK_REP[i]:
			out = i
	return out


func _update_rank() -> void:
	var new_rank := rank_for(rep_of(member))
	if new_rank == rank:
		return
	var patron: StringName = GuildLibrary.get_guild(member).get("patron", &"")
	if new_rank > rank:
		for i in new_rank - rank:   # each promotion pleases the patron
			GameState.blessings.add_interest(patron, GuildLibrary.RANK_UP_INTEREST)
		messages.append("Promoted: you're now a %s of %s." % [GuildLibrary.rank_name(new_rank), GuildLibrary.guild_name(member)])
	else:
		messages.append("Demoted to %s in %s." % [GuildLibrary.rank_name(new_rank), GuildLibrary.guild_name(member)])
	rank = new_rank


# =========================================================
# Taxes, prices, pay
# =========================================================

## Share of battle gold the floor's owner takes from you.
func tax_rate(floor_n: int) -> float:
	var g := owner_of_floor(floor_n)
	var base: float = GuildLibrary.get_guild(g).get("tax", 0.0)
	return base * GuildLibrary.RANK_TAX_SHARE[rank] if g == member else base


## Takes the floor owner's tax out of gold you just earned. Returns the tax.
func collect_tax(gold: int, floor_n: int) -> int:
	var tax := roundi(gold * tax_rate(floor_n))
	if tax > 0:
		var g := owner_of_floor(floor_n)
		treasury[g] = treasury_of(g) + tax
	return tax


func treasury_of(g: StringName) -> int:
	return treasury.get(g, START_TREASURY)


## The floor owner's price level for you (its markup, minus your member discount).
func price_mult(floor_n: int) -> float:
	var g := owner_of_floor(floor_n)
	var m: float = GuildLibrary.get_guild(g).get("price_mult", 1.0)
	return m * (1.0 - GuildLibrary.RANK_DISCOUNT[rank]) if g == member else m


func pay_due() -> bool:
	return member != &"" and GuildLibrary.RANK_PAY_SHARE[rank] > 0.0 \
		and GameState.floor_number >= last_pay_floor + GuildLibrary.PAY_FLOORS


## Officers and Masters take their cut of the treasury. Returns the gold paid.
func collect_pay() -> int:
	if not pay_due():
		return 0
	var pay := roundi(treasury_of(member) * GuildLibrary.RANK_PAY_SHARE[rank])
	treasury[member] = treasury_of(member) - pay
	GameState.player.gold += pay
	last_pay_floor = GameState.floor_number
	messages.append("Your cut from %s: %d gold." % [GuildLibrary.guild_name(member), pay])
	return pay


# =========================================================
# Market (supply and demand per territory)
# =========================================================

## Market key for an item ("potion") or a piece of gear ("gear_2" = Rare gear).
static func good_key(item_id: StringName = &"", gear: GearItem = null) -> String:
	return "gear_%d" % gear.rarity if gear else String(item_id)


func pressure(t: int, key: String) -> float:
	return market.get(t, {}).get(key, 0.0)


func buy_mult(t: int, key: String) -> float:
	return clampf(1.0 + pressure(t, key), BUY_MULT_RANGE.x, BUY_MULT_RANGE.y)


func sell_mult(t: int, key: String) -> float:
	return clampf(1.0 + pressure(t, key), SELL_MULT_RANGE.x, SELL_MULT_RANGE.y)


func _push(t: int, key: String, amount: float) -> void:
	if not market.has(t):
		market[t] = {}
	market[t][key] = pressure(t, key) + amount


func record_buy(t: int, key: String) -> void:
	_push(t, key, BUY_PRESSURE)


func record_sell(t: int, key: String) -> void:
	_push(t, key, -SELL_PRESSURE)


## Every floor climbed: prices drift back toward normal.
func on_floor() -> void:
	for t in market.keys():
		var goods: Dictionary = market[t]
		for k in goods.keys():
			goods[k] *= MARKET_DECAY
			if absf(goods[k]) < 0.01:
				goods.erase(k)
		if goods.is_empty():
			market.erase(t)
	if pay_due():
		messages.append("%s has your pay ready. Find one of their agents." % GuildLibrary.guild_name(member))


# =========================================================
# Save / load (validated)
# =========================================================

func to_dict() -> Dictionary:
	var m := {}
	for t in market:
		m[str(t)] = market[t].duplicate()
	return { "owners": owners.map(func(g): return String(g)), "rep": _strkeys(rep), "member": String(member),
		"rank": rank, "treasury": _strkeys(treasury), "market": m, "last_pay_floor": last_pay_floor }


static func _strkeys(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d:
		out[String(k)] = d[k]
	return out


static func from_dict(d: Dictionary) -> GuildState:
	var gs := GuildState.new()
	var S := SaveSerializer
	var o := S._a(d, "owners")
	if not o.is_empty():
		gs.owners = []
		for i in maxi(o.size(), 1):
			var g := StringName(o[i]) if o[i] is String else &""
			gs.owners.append(g if GuildLibrary.guilds.has(g) else GuildLibrary.START_OWNERS[i % GuildLibrary.START_OWNERS.size()])
	var r := S._d(d, "rep")
	for g in r:
		if g is String and GuildLibrary.guilds.has(StringName(g)):
			gs.rep[StringName(g)] = S._i(r, g, 0, REP_MIN, REP_MAX)
	var mem := StringName(S._s(d, "member"))
	if GuildLibrary.guilds.has(mem):
		gs.member = mem
		gs.rank = mini(S._i(d, "rank", 0, 0, GuildLibrary.RANKS.size() - 1), rank_for(gs.rep_of(mem)))
	var tr := S._d(d, "treasury")
	for g in tr:
		if g is String and GuildLibrary.guilds.has(StringName(g)):
			gs.treasury[StringName(g)] = S._i(tr, g, START_TREASURY, 0, 10000000)
	var m := S._d(d, "market")
	for t in m:
		if t is String and t.is_valid_int() and m[t] is Dictionary:
			var goods := {}
			for k in m[t]:
				var v = m[t][k]
				if k is String and k.length() <= 64 and (v is float or v is int):
					goods[k] = clampf(float(v), -2.0, 2.0)
			gs.market[int(t)] = goods
	gs.last_pay_floor = S._i(d, "last_pay_floor", 0, 0, 100000)
	return gs
