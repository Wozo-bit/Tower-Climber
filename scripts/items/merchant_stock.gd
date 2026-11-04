class_name MerchantStock
extends RefCounted
## What a rest-floor merchant has beyond potions: a few weapons and skill books
## (Hayden 2026-11-04). Rolled from the run + floor, so a merchant keeps the
## same stock when you come back; what you bought is in GameState.merchant_bought.
##
## Weapons: Common / Uncommon, sometimes Rare (loot stays the better source).
## Books: Common; a Rare on the odd merchant; an Epic too if someone in the
## party has really high Luck (EPIC_LUCK).

const WEAPONS := 3
const WEAPON_BASES := [&"sword", &"mace", &"staff", &"bow", &"dagger", &"scepter"]
const RARE_WEAPON_CHANCE := 0.1
const UNCOMMON_WEAPON_CHANCE := 0.4
## Gear costs this many times its sell value.
const GEAR_PRICE_MULT := 4.0
const COMMON_BOOKS := 2
const RARE_BOOK_CHANCE := 0.25
const EPIC_BOOK_CHANCE := 0.35
const EPIC_LUCK := 40
const BOOK_PRICE := { SkillTier.Tier.COMMON: 120, SkillTier.Tier.RARE: 450, SkillTier.Tier.EPIC: 1500 }


## The highest Luck in the fighting party (buffs and gear count).
static func party_luck() -> int:
	var best := 0
	for m in GameState.battle_party():
		best = maxi(best, m.stats.get_total(Stats.Type.LUCK))
	return best


static func _rng(floor_n: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = ("%s:%d:merchant" % [GameState.player.legacy_id, floor_n]).hash()
	return rng


## This merchant's weapons, with a "key" meta for the sold list.
static func weapons(floor_n: int) -> Array[GearItem]:
	var rng := _rng(floor_n)
	var out: Array[GearItem] = []
	for i in WEAPONS:
		var roll := rng.randf()
		var rarity: int = Rarity.Tier.RARE if roll < RARE_WEAPON_CHANCE \
			else (Rarity.Tier.UNCOMMON if roll < RARE_WEAPON_CHANCE + UNCOMMON_WEAPON_CHANCE else Rarity.Tier.COMMON)
		var base: StringName = WEAPON_BASES[rng.randi_range(0, WEAPON_BASES.size() - 1)]
		var g := LootTable.make_gear(base, rarity, floor_n, rng)
		g.set_meta("merchant_key", "%d:w%d" % [floor_n, i])
		out.append(g)
	return out


static func _books_of_tier(tier: int) -> Array:
	var out := SkillLibrary.learnable_skills().filter(func(s): return s.tier == tier).map(func(s): return s.id)
	out.sort_custom(func(a, b): return String(a) < String(b))
	return out


static func _pick(pool: Array, rng: RandomNumberGenerator, taken: Array) -> StringName:
	var left := pool.filter(func(id): return not taken.has(id))
	return left[rng.randi_range(0, left.size() - 1)] if not left.is_empty() else &""


## This merchant's books (skill ids). `luck` = the party's best Luck.
static func books(floor_n: int, luck: int) -> Array:
	var rng := _rng(floor_n + 100000)
	var out := []
	for i in COMMON_BOOKS:
		var id := _pick(_books_of_tier(SkillTier.Tier.COMMON), rng, out)
		if id != &"":
			out.append(id)
	# Both rolls always happen, so Luck doesn't reshuffle the rest of the stock.
	var rare_roll := rng.randf()
	var epic_roll := rng.randf()
	if rare_roll < RARE_BOOK_CHANCE:
		var id := _pick(_books_of_tier(SkillTier.Tier.RARE), rng, out)
		if id != &"":
			out.append(id)
	if luck >= EPIC_LUCK and epic_roll < EPIC_BOOK_CHANCE:
		var id := _pick(_books_of_tier(SkillTier.Tier.EPIC), rng, out)
		if id != &"":
			out.append(id)
	return out


static func gear_price(g: GearItem) -> int:
	var base: int = GameState.SELL_GEAR_BASE[clampi(g.rarity, 0, GameState.SELL_GEAR_BASE.size() - 1)] \
		+ GameState.SELL_PER_ITEM_LEVEL * g.item_level
	return roundi(base * GEAR_PRICE_MULT * GameState.trade_mult(GuildState.good_key(&"", g)))


static func book_price(skill_id: StringName) -> int:
	var s := SkillLibrary.get_skill_or_null(skill_id)
	var base: int = BOOK_PRICE.get(s.tier if s else SkillTier.Tier.COMMON, 120)
	return roundi(base * GameState.trade_mult(String(SkillBooks.book_item_id(skill_id))))
