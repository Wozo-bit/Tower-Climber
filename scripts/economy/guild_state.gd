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

# --- Phase 3: the guild AI, wars, theft, your own guild ---
## [{ "attacker", "defender", "territory": int, "score": float, "ticks": int }]
var wars: Array = []
## Allied pairs: ["a", "b"] (sorted ids)
var alliances: Array = []
## guild id -> fortification level (0..GuildAI.MAX_DEFENSE)
var defense: Dictionary = {}
## Tower news, newest last: [{ "floor": int, "text": String }]
var news: Array = []
## guild id -> floor: its guards hunt you until you climb past this floor
var hostile_until: Dictionary = {}
## territory -> floor its champion was beaten on (comes back after CHAMPION_RESPAWN)
var champion_beaten: Dictionary = {}
## The guild you're fighting a war for as a hired sword (&"" = none).
var mercenary_for: StringName = &""
## An active heist: { "for": guild id, "target": guild id } ({} = none)
var heist: Dictionary = {}
## Floor you last tried to steal on (one attempt per floor).
var last_steal_floor := -1
## Your own guild once founded: { "name", "patron", "tax", "upgrades": { id: level } }
var player_guild: Dictionary = {}

const NEWS_KEEP := 60
## Your standing at or below this makes a guild's guards hunt you.
const HOSTILE_REP := -50
## Getting caught stealing makes the guild hostile for this many floors.
const CAUGHT_FLOORS := 5
const CAUGHT_PENALTY := 15
## Wars: score needed to win, longest war, prices in the contested territory.
const WAR_WIN := 6.0
const WAR_MAX_TICKS := 8
const WAR_PRICE_SHOCK := 0.2
## How much each fight you win swings a war you're part of.
const GUARD_SWING := 1.5
const CHAMPION_SWING := 4.0
const GUARD_REP_LOSS := 5
const CHAMPION_REP_LOSS := 20
const MERCENARY_PAY := 40
const CHAMPION_RESPAWN := 10
## Theft
const STEAL_BASE := 0.25
const STEAL_PER_POINT := 0.005   # per point of Agility + Luck
const STEAL_MAX := 0.75
const STEAL_VILLAIN_POINTS := 2
const PICKPOCKET_CHANCE := 0.15
const PICKPOCKET_GOLD := 0.1
const HEIST_SHARE := 0.15
const HEIST_REP_GAIN := 10
const HEIST_REP_LOSS := 30
## Your own guild
const CHARTER_FLOOR := 15
const CHARTER_COST := 2000
const PLAYER_INCOME_BASE := 40
const PLAYER_INCOME_PER_TAX := 300
const PLAYER_INCOME_PER_MEMBER := 5
const MAX_PLAYER_TAX := 0.3
const UPGRADES := {
	"vault": { "name": "Vault", "desc": "Raids on your treasury take less (-30% per level).", "max": 3 },
	"barracks": { "name": "Barracks", "desc": "Your guild is stronger in wars (+2 per level).", "max": 3 },
	"armory": { "name": "Armory", "desc": "Better members' stock (one more rank's worth per level).", "max": 3 },
}
const UPGRADE_COST := 500   # x (level + 1)


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


## The floor owner's price level for you (its markup, minus your member
## discount), plus war prices if this territory is being fought over.
func price_mult(floor_n: int) -> float:
	var g := owner_of_floor(floor_n)
	var m: float = GuildLibrary.get_guild(g).get("price_mult", 1.0)
	if g == member:
		m *= 1.0 - GuildLibrary.RANK_DISCOUNT[rank]
	if is_contested(GuildLibrary.territory_of(floor_n) % maxi(1, owners.size())):
		m *= 1.0 + WAR_PRICE_SHOCK
	return m


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


## Every floor climbed: the guilds take their turn (GuildAI), then prices
## drift back toward normal. `rng` = a run+floor seeded generator.
func on_floor(rng: RandomNumberGenerator = null) -> void:
	if rng:
		GuildAI.tick(self, rng)
	_on_floor_market()


func _on_floor_market() -> void:
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
# News
# =========================================================

## Adds to the tower news. `big` events also pop up as a toast.
func add_news(text: String, big: bool = false) -> void:
	news.append({ "floor": GameState.floor_number, "text": text })
	while news.size() > NEWS_KEEP:
		news.pop_front()
	if big:
		messages.append("Tower news: " + text)


## The latest few headlines, newest first ("" if nothing has happened).
func latest_news(count: int = 3) -> String:
	var lines: PackedStringArray = []
	for i in range(news.size() - 1, maxi(-1, news.size() - 1 - count), -1):
		lines.append("Floor %d: %s" % [news[i].floor, news[i].text])
	return "\n".join(lines)


# =========================================================
# Alliances, raids, wars (the AI calls these; see GuildAI)
# =========================================================

func defense_of(g: StringName) -> int:
	return defense.get(g, 0)


static func _pair(a: StringName, b: StringName) -> Array:
	var p := [String(a), String(b)]
	p.sort()
	return p


func allied(a: StringName, b: StringName) -> bool:
	return alliances.has(_pair(a, b))


func make_alliance(a: StringName, b: StringName) -> void:
	if a == b or allied(a, b):
		return
	alliances.append(_pair(a, b))
	add_news("%s and %s sign an alliance." % [GuildLibrary.guild_name(a), GuildLibrary.guild_name(b)])


## `thief` robs part of `target`'s treasury (your guild's Vault helps).
func raid(thief: StringName, target: StringName, rng: RandomNumberGenerator) -> void:
	var aggression: float = GuildLibrary.get_guild(thief).get("personality", {}).get("aggression", 0.5)
	var chance := 0.4 + aggression * 0.4 - defense_of(target) * 0.05
	if target == GuildLibrary.PLAYER_GUILD:
		chance -= 0.1 * upgrade_level("vault")
	if rng.randf() >= chance:
		add_news("%s tried to rob %s, and failed." % [GuildLibrary.guild_name(thief), GuildLibrary.guild_name(target)])
		return
	var share := GuildAI.RAID_SHARE * (1.0 - 0.3 * upgrade_level("vault") if target == GuildLibrary.PLAYER_GUILD else 1.0)
	var stolen := roundi(treasury_of(target) * share)
	treasury[target] = treasury_of(target) - stolen
	treasury[thief] = treasury_of(thief) + stolen
	var mine := target == member or target == GuildLibrary.PLAYER_GUILD
	add_news("%s robbed %s of %d gold." % [GuildLibrary.guild_name(thief), GuildLibrary.guild_name(target), stolen], mine)


func is_at_war(g: StringName) -> bool:
	return wars.any(func(w): return w.attacker == g or w.defender == g)


func war_between(a: StringName, b: StringName) -> bool:
	return wars.any(func(w): return (w.attacker == a and w.defender == b) or (w.attacker == b and w.defender == a))


func war_of(g: StringName) -> Dictionary:
	for w in wars:
		if w.attacker == g or w.defender == g:
			return w
	return {}


func is_contested(t: int) -> bool:
	return wars.any(func(w): return w.territory == t)


func declare_war(attacker: StringName, defender: StringName, t: int) -> void:
	if attacker == defender or war_between(attacker, defender):
		return
	wars.append({ "attacker": attacker, "defender": defender, "territory": t, "score": 0.0, "ticks": 0 })
	# A war is always big news (it moves prices and guards everywhere near it).
	add_news("%s declares war on %s over %s!" % [GuildLibrary.guild_name(attacker), GuildLibrary.guild_name(defender),
		GuildLibrary.territory_floors(t)], true)


## How strong a guild is in a war right now.
func war_strength(g: StringName) -> float:
	var aggression: float = GuildLibrary.get_guild(g).get("personality", {}).get("aggression", 0.5)
	var s := treasury_of(g) / 400.0 + territories_of(g).size() + aggression * 2.0 + defense_of(g)
	for other in GuildLibrary.guilds:
		if other != g and allied(g, other):
			s += 1.0
	if g == GuildLibrary.PLAYER_GUILD:
		s += 2.0 * upgrade_level("barracks") + 0.3 * GameState.member_count()
	return s


## Each floor: wars move toward one side. Win at +WAR_WIN (attacker takes the
## territory) or -WAR_WIN (defender holds); after WAR_MAX_TICKS it's a truce.
func progress_wars(rng: RandomNumberGenerator) -> void:
	for w in wars.duplicate():
		w["ticks"] = w.ticks + 1
		w["score"] = w.score + (war_strength(w.attacker) - war_strength(w.defender)) * 0.15 + rng.randf_range(-1.5, 1.5)
		_settle(w)


## You (or your side) won a fight: push every war you're part of.
func swing(against: StringName, amount: float) -> void:
	for w in wars.duplicate():
		if w.attacker == against and w.defender == player_side():
			w["score"] = w.score - amount
		elif w.defender == against and w.attacker == player_side():
			w["score"] = w.score + amount
		else:
			continue
		_settle(w)


func _settle(w: Dictionary) -> void:
	var a := GuildLibrary.guild_name(w.attacker)
	var d := GuildLibrary.guild_name(w.defender)
	var yours := player_side() in [w.attacker, w.defender]
	if w.score >= WAR_WIN:
		owners[w.territory] = w.attacker
		champion_beaten.erase(w.territory)
		add_news("%s wins the war and takes %s from %s!" % [a, GuildLibrary.territory_floors(w.territory), d], true)
	elif w.score <= -WAR_WIN:
		add_news("%s holds %s against %s." % [d, GuildLibrary.territory_floors(w.territory), a], yours)
	elif w.ticks >= WAR_MAX_TICKS:
		add_news("%s and %s call a truce." % [a, d], yours)
	else:
		return
	wars.erase(w)
	if mercenary_for != &"" and not is_at_war(mercenary_for):
		mercenary_for = &""   # the contract ends with the war


# =========================================================
# You and the wars: sides, hostility, guards and champions
# =========================================================

## The guild you fight for: your own/your guild if it's at war, else your
## mercenary employer.
func player_side() -> StringName:
	if member != &"" and is_at_war(member):
		return member
	return mercenary_for


## Guilds whose fighters attack you: hated, recently robbed by you, or at war with your side.
func is_hostile(g: StringName) -> bool:
	if g == &"" or g == member:
		return false
	if rep_of(g) <= HOSTILE_REP or hostile_until.get(g, -1) >= GameState.floor_number:
		return true
	return player_side() != &"" and war_between(g, player_side())


## Hire on as a mercenary for a guild at war (not one you're its enemy in).
func can_hire_on(g: StringName) -> bool:
	return is_at_war(g) and mercenary_for == &"" and g != member and not is_hostile(g)


func hire_on(g: StringName) -> bool:
	if not can_hire_on(g):
		return false
	mercenary_for = g
	var w := war_of(g)
	var enemy: StringName = w.defender if w.attacker == g else w.attacker
	messages.append("You fight for %s now. %s's guards will come for you." % [GuildLibrary.guild_name(g), GuildLibrary.guild_name(enemy)])
	return true


## Should this territory's champion stand guard for you to challenge?
func champion_waiting(t: int) -> bool:
	var owner := owner_of_territory(t)
	if owner == &"" or owner == member:
		return false
	if champion_beaten.has(t) and GameState.floor_number < champion_beaten[t] + CHAMPION_RESPAWN:
		return false
	return member == GuildLibrary.PLAYER_GUILD or is_hostile(owner)


## You beat a guild's guards or champion.
func fight_won(g: StringName, champion: bool) -> void:
	add_rep(g, -(CHAMPION_REP_LOSS if champion else GUARD_REP_LOSS))
	if mercenary_for != &"" and war_between(g, mercenary_for):
		GameState.player.gold += MERCENARY_PAY * (3 if champion else 1)
	swing(g, CHAMPION_SWING if champion else GUARD_SWING)
	if champion:
		var t := GuildLibrary.territory_of(GameState.floor_number) % maxi(1, owners.size())
		champion_beaten[t] = GameState.floor_number
		if member == GuildLibrary.PLAYER_GUILD and owners[t] == g:
			owners[t] = GuildLibrary.PLAYER_GUILD
			add_news("%s takes %s from %s!" % [GuildLibrary.guild_name(GuildLibrary.PLAYER_GUILD),
				GuildLibrary.territory_floors(t), GuildLibrary.guild_name(g)], true)
		else:
			add_news("%s's champion has fallen." % GuildLibrary.guild_name(g), true)


# =========================================================
# Theft
# =========================================================

static func steal_chance(c: CharacterData) -> float:
	return clampf(STEAL_BASE + (c.stats.get_total(Stats.Type.AGILITY) + c.stats.get_total(Stats.Type.LUCK)) * STEAL_PER_POINT,
		0.05, STEAL_MAX)


func can_steal() -> bool:
	return last_steal_floor != GameState.floor_number


## Try to pocket an item from the floor's trader. One try per floor.
## Returns "stolen", "caught" or "" (can't try).
func try_steal(id: StringName, rng: RandomNumberGenerator) -> String:
	if not can_steal() or ItemLibrary.get_item(id) == null:
		return ""
	last_steal_floor = GameState.floor_number
	var owner := owner_of_floor(GameState.floor_number)
	if rng.randf() < steal_chance(GameState.player) and GameState.inventory.add(id) > 0:
		GameState.add_route_points(&"villain", STEAL_VILLAIN_POINTS)
		return "stolen"
	add_rep(owner, -CAUGHT_PENALTY)
	hostile_until[owner] = GameState.floor_number + CAUGHT_FLOORS
	add_news("A thief was caught on %s's floors." % GuildLibrary.guild_name(owner))
	messages.append("Caught stealing! %s's guards will be after you for %d floors." % [GuildLibrary.guild_name(owner), CAUGHT_FLOORS])
	return "caught"


## After a won battle: on a hostile or greedy guild's floors, a pickpocket may
## lift some gold or an item. Members (Member rank+) of the floor's guild are safe.
## Returns what was taken ("" = nothing).
func roll_pickpocket(rng: RandomNumberGenerator) -> String:
	var owner := owner_of_floor(GameState.floor_number)
	if owner == member and rank >= 1:
		return ""
	var greed: float = GuildLibrary.get_guild(owner).get("personality", {}).get("greed", 0.0)
	if not (is_hostile(owner) or rep_of(owner) < -10 or greed >= 0.8):
		return ""
	var p := GameState.player
	var chance := PICKPOCKET_CHANCE - (p.stats.get_total(Stats.Type.AGILITY) + p.stats.get_total(Stats.Type.LUCK)) * 0.001
	if rng.randf() >= chance:
		return ""
	var gold := roundi(p.gold * PICKPOCKET_GOLD)
	if gold > 0:
		p.gold -= gold
		treasury[owner] = treasury_of(owner) + gold
		messages.append("A pickpocket lifted %d gold!" % gold)
		return "%d gold" % gold
	var items := GameState.inventory.owned().filter(func(i): return not i.quest_item)
	if items.is_empty():
		return ""
	var item: ItemDef = items[rng.randi_range(0, items.size() - 1)]
	GameState.inventory.remove(item.id)
	messages.append("A pickpocket stole your %s!" % item.display_name)
	return item.display_name


## Your guild (Member rank+) can send you to rob a rival or war enemy.
func heist_target(for_guild: StringName) -> StringName:
	var w := war_of(for_guild)
	if not w.is_empty():
		return w.defender if w.attacker == for_guild else w.attacker
	var rivals := GuildLibrary.rivals_of(for_guild).filter(func(r): return not territories_of(r).is_empty())
	return rivals[0] if not rivals.is_empty() else &""


func can_take_heist(for_guild: StringName) -> bool:
	return heist.is_empty() and member == for_guild and rank >= 1 and heist_target(for_guild) != &""


func take_heist(for_guild: StringName) -> bool:
	if not can_take_heist(for_guild):
		return false
	heist = { "for": for_guild, "target": heist_target(for_guild) }
	messages.append("Heist: rob %s's vault (talk to one of their agents)." % GuildLibrary.guild_name(heist.target))
	return true


## At the target's agent: try the heist. Returns "done", "caught" or "".
func attempt_heist(target: StringName, rng: RandomNumberGenerator) -> String:
	if heist.is_empty() or heist.target != target:
		return ""
	var employer: StringName = heist["for"]
	heist = {}
	if rng.randf() < steal_chance(GameState.player):
		var loot := roundi(treasury_of(target) * HEIST_SHARE)
		treasury[target] = treasury_of(target) - loot
		GameState.player.gold += loot / 2
		treasury[employer] = treasury_of(employer) + loot - loot / 2
		add_rep(employer, HEIST_REP_GAIN)
		add_rep(target, -HEIST_REP_LOSS)
		add_news("%s's vault was robbed!" % GuildLibrary.guild_name(target), true)
		messages.append("Heist done: %d gold for you, %d for %s." % [loot / 2, loot - loot / 2, GuildLibrary.guild_name(employer)])
		return "done"
	add_rep(target, -HEIST_REP_LOSS)
	hostile_until[target] = GameState.floor_number + CAUGHT_FLOORS
	messages.append("The heist failed! %s knows it was you." % GuildLibrary.guild_name(target))
	return "caught"


# =========================================================
# Your own guild
# =========================================================

func has_own_guild() -> bool:
	return not player_guild.is_empty()


## Why you can't found a guild ("" = you can).
func charter_refusal() -> String:
	if has_own_guild():
		return "You already lead a guild."
	if GameState.highest_floor <= CHARTER_FLOOR:
		return "Climb past floor %d first." % CHARTER_FLOOR
	if GameState.player.gold < CHARTER_COST:
		return "A charter costs %d gold." % CHARTER_COST
	return ""


const GUILD_NAME_MAX := 32


## Trims and collapses spaces; guild names can be longer than character names.
static func clean_guild_name(raw: String) -> String:
	return " ".join(raw.strip_edges().split(" ", false)).left(GUILD_NAME_MAX)


## Founds your guild. You leave any guild you were in (they take it badly).
## `patron` may be &"" (none) or a being that would sign with you.
func found_guild(guild_name: String, patron: StringName = &"") -> bool:
	var cleaned := clean_guild_name(guild_name)
	if charter_refusal() != "" or cleaned == "":
		return false
	if patron != &"" and not BeingLibrary.beings.has(patron):
		return false
	GameState.player.gold -= CHARTER_COST
	if member != &"":
		leave()
	player_guild = { "name": cleaned, "patron": patron, "tax": 0.1, "upgrades": {} }
	_register_player_guild()
	member = GuildLibrary.PLAYER_GUILD
	rank = GuildLibrary.RANKS.size() - 1
	rep[GuildLibrary.PLAYER_GUILD] = REP_MAX
	treasury[GuildLibrary.PLAYER_GUILD] = 0
	add_news("A new guild is founded: %s." % cleaned, true)
	return true


## Patrons who'd sign with you: your blessing's being first, then any being
## that isn't against you (interest >= 0).
static func willing_patrons() -> Array:
	var out := []
	var blessed: StringName = GameState.player.blessing_id
	if blessed != &"":
		out.append(blessed)
	var willing := func(b) -> bool:
		var scorned: bool = GameState.blessings.beings.get(b, {}).get("scorned", false)
		return b != blessed and GameState.blessings.interest(b) >= 0 and not scorned
	var others := BeingLibrary.beings.keys().filter(willing)
	others.sort_custom(func(a, b): return GameState.blessings.interest(a) > GameState.blessings.interest(b))
	return out + others


## (Re)registers your guild in GuildLibrary so it works like any other guild.
func _register_player_guild() -> void:
	if not has_own_guild():
		GuildLibrary.guilds.erase(GuildLibrary.PLAYER_GUILD)
		return
	var stock := {}
	for r in GuildLibrary.RANKS.size():
		stock[r] = []
	stock[0] = [&"potion", &"ether"]
	stock[1] = [&"advanced_potion"]
	stock[2] = [&"scouting_lens"]
	stock[3] = [&"goddess_tear"]
	# The Armory unlocks higher ranks' stock for everyone... and you're the Master anyway.
	GuildLibrary.guilds[GuildLibrary.PLAYER_GUILD] = { "name": player_guild.name, "patron": player_guild.patron,
		"motto": "(Your guild)", "tax": player_guild.tax, "price_mult": 1.0 - 0.05 * upgrade_level("armory"),
		"stock": stock, "personality": { "greed": 0.5, "aggression": 0.5, "honor": 0.5 } }


func upgrade_level(id: String) -> int:
	return player_guild.get("upgrades", {}).get(id, 0)


func upgrade_cost(id: String) -> int:
	return UPGRADE_COST * (upgrade_level(id) + 1)


## Buys a guild hall upgrade from your guild's treasury.
func buy_upgrade(id: String) -> bool:
	if not has_own_guild() or not UPGRADES.has(id) or upgrade_level(id) >= UPGRADES[id].max:
		return false
	var cost := upgrade_cost(id)
	if treasury_of(GuildLibrary.PLAYER_GUILD) < cost:
		return false
	treasury[GuildLibrary.PLAYER_GUILD] = treasury_of(GuildLibrary.PLAYER_GUILD) - cost
	player_guild.upgrades[id] = upgrade_level(id) + 1
	_register_player_guild()
	return true


## Your guild's tax on its floors (0-30%). Higher tax = more income.
func set_player_tax(t: float) -> void:
	if has_own_guild():
		player_guild["tax"] = clampf(snappedf(t, 0.05), 0.0, MAX_PLAYER_TAX)
		_register_player_guild()


## Moves gold from your guild's treasury to you.
func withdraw(amount: int) -> int:
	if not has_own_guild():
		return 0
	var take := clampi(amount, 0, treasury_of(GuildLibrary.PLAYER_GUILD))
	treasury[GuildLibrary.PLAYER_GUILD] = treasury_of(GuildLibrary.PLAYER_GUILD) - take
	GameState.player.gold += take
	return take


## Each floor: your guild earns from the floors it holds (more with a higher
## tax and more members).
func player_guild_income() -> void:
	if not has_own_guild():
		return
	var held := territories_of(GuildLibrary.PLAYER_GUILD).size()
	if held == 0:
		return
	var income := held * (PLAYER_INCOME_BASE + roundi(player_guild.tax * PLAYER_INCOME_PER_TAX)) \
		+ PLAYER_INCOME_PER_MEMBER * GameState.member_count()
	treasury[GuildLibrary.PLAYER_GUILD] = treasury_of(GuildLibrary.PLAYER_GUILD) + income


# =========================================================
# Save / load (validated)
# =========================================================

func to_dict() -> Dictionary:
	var m := {}
	for t in market:
		m[str(t)] = market[t].duplicate()
	var cb := {}
	for t in champion_beaten:
		cb[str(t)] = champion_beaten[t]
	return { "owners": owners.map(func(g): return String(g)), "rep": _strkeys(rep), "member": String(member),
		"rank": rank, "treasury": _strkeys(treasury), "market": m, "last_pay_floor": last_pay_floor,
		"wars": wars.map(func(w): return { "attacker": String(w.attacker), "defender": String(w.defender),
			"territory": w.territory, "score": w.score, "ticks": w.ticks }),
		"alliances": alliances.duplicate(true), "defense": _strkeys(defense), "news": news.duplicate(true),
		"hostile_until": _strkeys(hostile_until), "champion_beaten": cb, "mercenary_for": String(mercenary_for),
		"heist": { "for": String(heist.get("for", &"")), "target": String(heist.get("target", &"")) } if not heist.is_empty() else {},
		"last_steal_floor": last_steal_floor,
		"player_guild": { "name": player_guild.get("name", ""), "patron": String(player_guild.get("patron", &"")),
			"tax": player_guild.get("tax", 0.1), "upgrades": player_guild.get("upgrades", {}).duplicate() } if has_own_guild() else {} }


static func _strkeys(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d:
		out[String(k)] = d[k]
	return out


static func from_dict(d: Dictionary) -> GuildState:
	var gs := GuildState.new()
	var S := SaveSerializer
	# Your own guild first, so the rest of the data can refer to it.
	var pg := S._d(d, "player_guild")
	if not pg.is_empty() and clean_guild_name(S._s(pg, "name")) != "":
		var patron := StringName(S._s(pg, "patron"))
		var ups := {}
		var u := S._d(pg, "upgrades")
		for k in UPGRADES:
			ups[k] = S._i(u, k, 0, 0, UPGRADES[k].max)
		gs.player_guild = { "name": clean_guild_name(S._s(pg, "name")),
			"patron": patron if BeingLibrary.beings.has(patron) else &"",
			"tax": clampf(S._f(pg, "tax", 0.1), 0.0, MAX_PLAYER_TAX), "upgrades": ups }
	gs._register_player_guild()
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
	var valid := func(x) -> bool: return x is String and GuildLibrary.guilds.has(StringName(x))
	for w in S._a(d, "wars"):
		if w is Dictionary and valid.call(w.get("attacker")) and valid.call(w.get("defender")) and w.attacker != w.defender:
			gs.wars.append({ "attacker": StringName(w.attacker), "defender": StringName(w.defender),
				"territory": S._i(w, "territory", 0, 0, maxi(0, gs.owners.size() - 1)),
				"score": S._f(w, "score", 0.0, -WAR_WIN, WAR_WIN), "ticks": S._i(w, "ticks", 0, 0, WAR_MAX_TICKS) })
	for a in S._a(d, "alliances"):
		if a is Array and a.size() == 2 and valid.call(a[0]) and valid.call(a[1]) and a[0] != a[1]:
			gs.alliances.append(_pair(StringName(a[0]), StringName(a[1])))
	var df := S._d(d, "defense")
	for g in df:
		if valid.call(g):
			gs.defense[StringName(g)] = S._i(df, g, 0, 0, GuildAI.MAX_DEFENSE)
	for n in S._a(d, "news"):
		if n is Dictionary:
			gs.news.append({ "floor": S._i(n, "floor", 1, 1, 100000), "text": S._s(n, "text", "", 200) })
	while gs.news.size() > NEWS_KEEP:
		gs.news.pop_front()
	var hu := S._d(d, "hostile_until")
	for g in hu:
		if valid.call(g):
			gs.hostile_until[StringName(g)] = S._i(hu, g, 0, 0, 100000)
	var cb := S._d(d, "champion_beaten")
	for t in cb:
		if t is String and t.is_valid_int():
			gs.champion_beaten[int(t)] = S._i(cb, t, 0, 0, 100000)
	var merc := S._s(d, "mercenary_for")
	gs.mercenary_for = StringName(merc) if valid.call(merc) and gs.is_at_war(StringName(merc)) else &""
	var h := S._d(d, "heist")
	if valid.call(h.get("for")) and valid.call(h.get("target")):
		gs.heist = { "for": StringName(h["for"]), "target": StringName(h.target) }
	gs.last_steal_floor = S._i(d, "last_steal_floor", -1, -1, 100000)
	return gs
