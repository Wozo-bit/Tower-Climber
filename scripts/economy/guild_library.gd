class_name GuildLibrary
extends RefCounted
## The guilds that run the tower's floors, and how floors are divided.
##
## The tower is cut into TERRITORIES of TERRITORY_FLOORS floors. Each run
## starts with START_OWNERS (territory i -> guild); GuildState keeps who owns
## what now, so the guild AI (phase 3: wars, takeovers) can change it.
## Past the last territory the pattern repeats.
##
## A guild:
##   "name", "motto"
##   "patron": a BeingLibrary id. The patron shapes the guild: its values
##       (liked / disliked routes) are the guild's, its rivals' guilds are
##       its rivals, and its personality numbers below fit the patron.
##   "tax": share of battle gold earned on its floors (0.2 = 20%)
##   "price_mult": its merchants' prices (1.1 = 10% more)
##   "stock": guild shop for MEMBERS, by rank: { rank: [item ids] } (a rank
##       sees its own and every lower rank's items)
##   "personality": (for the phase-3 AI) { "greed", "aggression", "honor" } 0-1
## Placeholder names and numbers. DLC can add guilds with register_guild().

const TERRITORY_FLOORS := 3

const RANKS := ["Recruit", "Member", "Officer", "Master"]
## Reputation needed (while a member) for each rank.
const RANK_REP := [0, 25, 50, 80]
## Members pay this share of the guild's normal tax, by rank.
const RANK_TAX_SHARE := [0.75, 0.5, 0.25, 0.0]
## Members get this much off the guild's prices, by rank.
const RANK_DISCOUNT := [0.05, 0.1, 0.15, 0.2]
## Share of the guild's treasury paid to Officers / Masters every PAY_FLOORS.
const RANK_PAY_SHARE := [0.0, 0.0, 0.03, 0.06]
const PAY_FLOORS := 5
## Patron interest gained each time you rank up in its guild.
const RANK_UP_INTEREST := 3

const BASE_GUILDS := {
	&"golden_ledger": { "name": "The Golden Ledger", "patron": &"mammon",
		"motto": "(Placeholder) Everything has a price. Everything.", "tax": 0.2, "price_mult": 1.15,
		"stock": { 0: [&"scouting_lens"], 2: [&"goddess_tear"] },
		"personality": { "greed": 0.9, "aggression": 0.5, "honor": 0.1 } },
	&"order_of_the_aegis": { "name": "Order of the Aegis", "patron": &"athena",
		"motto": "(Placeholder) Shield the weak, guard the stairs.", "tax": 0.05, "price_mult": 1.0,
		"stock": { 0: [&"potion"], 1: [&"advanced_potion"], 3: [&"goddess_tear"] },
		"personality": { "greed": 0.2, "aggression": 0.2, "honor": 0.9 } },
	&"stormhammer_company": { "name": "Stormhammer Company", "patron": &"thor",
		"motto": "(Placeholder) Hit it until it stops moving.", "tax": 0.1, "price_mult": 0.95,
		"stock": { 0: [&"potion"], 2: [&"advanced_potion"] },
		"personality": { "greed": 0.3, "aggression": 0.8, "honor": 0.7 } },
	&"sunspear_caravan": { "name": "Sunspear Caravan", "patron": &"ra",
		"motto": "(Placeholder) Light the way, and charge a fair toll.", "tax": 0.08, "price_mult": 1.0,
		"stock": { 0: [&"ether"], 1: [&"advanced_potion"] },
		"personality": { "greed": 0.4, "aggression": 0.3, "honor": 0.8 } },
	&"jade_oath": { "name": "Brotherhood of the Jade Oath", "patron": &"guan_yu",
		"motto": "(Placeholder) A brother's word is iron.", "tax": 0.1, "price_mult": 0.9,
		"stock": { 0: [&"potion"], 2: [&"scouting_lens"] },
		"personality": { "greed": 0.2, "aggression": 0.4, "honor": 1.0 } },
	&"ninefold_lantern": { "name": "Ninefold Lantern", "patron": &"tamamo",
		"motto": "(Placeholder) Whatever you need. Whatever it costs.", "tax": 0.15, "price_mult": 1.1,
		"stock": { 0: [&"scouting_lens"], 1: [&"ether"], 3: [&"goddess_tear"] },
		"personality": { "greed": 0.8, "aggression": 0.4, "honor": 0.2 } },
	&"ravenwatch": { "name": "Ravenwatch", "patron": &"morrigan",
		"motto": "(Placeholder) We see who escapes justice. They don't escape us.", "tax": 0.1, "price_mult": 1.0,
		"stock": { 0: [&"scouting_lens"], 2: [&"advanced_potion"] },
		"personality": { "greed": 0.3, "aggression": 0.7, "honor": 0.6 } },
	&"serpent_coil": { "name": "The Serpent Coil", "patron": &"apep",
		"motto": "(Placeholder) Pay, or be swallowed.", "tax": 0.25, "price_mult": 1.2,
		"stock": { 0: [&"ether"], 1: [&"scouting_lens"], 3: [&"goddess_tear"] },
		"personality": { "greed": 0.9, "aggression": 0.9, "honor": 0.0 } },
	&"mountain_crew": { "name": "Flower-Fruit Mountain Crew", "patron": &"sun_wukong",
		"motto": "(Placeholder) Rules? Never heard of 'em.", "tax": 0.05, "price_mult": 0.95,
		"stock": { 0: [&"potion"], 1: [&"ether"] },
		"personality": { "greed": 0.3, "aggression": 0.6, "honor": 0.5 } },
	&"underworld_exchange": { "name": "Underworld Exchange", "patron": &"hades",
		"motto": "(Placeholder) Riches from below. Fair rates, final terms.", "tax": 0.12, "price_mult": 1.05,
		"stock": { 0: [&"ether"], 2: [&"goddess_tear"] },
		"personality": { "greed": 0.7, "aggression": 0.3, "honor": 0.6 } },
}

## Starting owner of each territory, in climbing order (floors 1-3, 4-6, ...).
## The first two (floors 1-6) charge normal prices so the early game reads clearly.
const START_OWNERS := [&"order_of_the_aegis", &"sunspear_caravan", &"mountain_crew", &"golden_ledger",
	&"stormhammer_company", &"ninefold_lantern", &"jade_oath", &"ravenwatch", &"underworld_exchange", &"serpent_coil"]

## Enemy groups for a guild's fighters (any guild; scaled to the floor).
const GUARD_GROUPS := [[&"guild_guard", &"guild_archer"], [&"guild_guard", &"guild_guard", &"guild_mage"],
	[&"guild_guard", &"guild_archer", &"guild_mage"]]
const CHAMPION_GROUP := [&"guild_champion", &"guild_guard", &"guild_archer"]

## The player's own guild is registered under this id once founded.
const PLAYER_GUILD := &"player_guild"

## Live table: base guilds plus anything DLC registered.
static var guilds: Dictionary = BASE_GUILDS.duplicate(true)


static func register_guild(id: StringName, def: Dictionary) -> void:
	guilds[id] = def


static func get_guild(id: StringName) -> Dictionary:
	return guilds.get(id, {})


static func guild_name(id: StringName) -> String:
	return get_guild(id).get("name", "No one")


## Which territory a floor is in (0-based, not wrapped).
static func territory_of(floor_n: int) -> int:
	return (maxi(1, floor_n) - 1) / TERRITORY_FLOORS


## "Floors 4-6"
static func territory_floors(t: int) -> String:
	return "Floors %d-%d" % [t * TERRITORY_FLOORS + 1, (t + 1) * TERRITORY_FLOORS]


## Is this floor the first one of its territory? (Guild agents stand there.)
static func is_territory_start(floor_n: int) -> bool:
	return (floor_n - 1) % TERRITORY_FLOORS == 0


## The guild's values come from its patron: { "likes": [...], "dislikes": [...] }.
static func values_of(id: StringName) -> Dictionary:
	return BeingLibrary.get_being(get_guild(id).get("patron", &"")).get("values", {})


## Guilds whose patrons are rivals of this guild's patron.
static func rivals_of(id: StringName) -> Array:
	var patron: StringName = get_guild(id).get("patron", &"")
	var rival_beings := BeingLibrary.rivals_of(patron)
	return guilds.keys().filter(func(g): return g != id and rival_beings.has(get_guild(g).get("patron", &"")))


static func rank_name(rank: int) -> String:
	return RANKS[clampi(rank, 0, RANKS.size() - 1)]


## Problems with the guild data ([] = all good). Run by the tests.
static func validate() -> PackedStringArray:
	var problems: PackedStringArray = []
	for id in guilds:
		if id == PLAYER_GUILD:
			continue   # built from the player's choices at runtime
		var g: Dictionary = guilds[id]
		if g.get("name", "") == "" or g.get("motto", "") == "":
			problems.append("%s: needs a name and motto" % id)
		if not BeingLibrary.beings.has(g.get("patron", &"")):
			problems.append("%s: unknown patron %s" % [id, g.get("patron")])
		if g.get("tax", -1.0) < 0.0 or g.get("tax", 2.0) > 0.5:
			problems.append("%s: tax must be 0-50%%" % id)
		if g.get("price_mult", 0.0) < 0.5 or g.get("price_mult", 9.0) > 2.0:
			problems.append("%s: price_mult must be 0.5-2" % id)
		for rank in g.get("stock", {}):
			for item in g.stock[rank]:
				if ItemLibrary.get_item(item) == null:
					problems.append("%s: unknown stock item %s" % [id, item])
	for owner in START_OWNERS:
		if not guilds.has(owner):
			problems.append("territory owner %s isn't a guild" % owner)
	return problems
