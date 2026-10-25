class_name Difficulty
extends RefCounted
## Difficulty modes (designed with Hayden 2026-10-24). Picked at New Game and
## when starting New Game+; during a run it can only be LOWERED (never raised,
## so the early floors can't be cheesed). Ironman is a separate toggle that
## works with any of them (GameState.ironman).
##
##   Relaxed - for the story / a dopamine hit: weaker enemies, more rewards,
##             no gold lost on a wipe.
##   Normal  - expect to wipe a couple of times, not a lot.
##   Hard    - challenging but fair.
##   Hell    - the manhwa grind: much stronger enemies, smaller rewards, harsh
##             wipes, plus Hell-only extras (no Scouting Lens for sale, pricier
##             consumables, stage bosses bring an extra escort).
##
## All numbers here are tuned with tools/balance_sim (see README).

enum Level { RELAXED, NORMAL, HARD, HELL }

const DEFAULT := Level.NORMAL

## enemy:    multiplier on enemy stats/HP (on top of floor scaling)
## ai:       multiplier on how often enemies use their skills
## xp/gold:  multipliers on battle rewards
## wipe_gold: share of your gold lost when the party is wiped out
const DATA := {
	Level.RELAXED: { "name": "Relaxed", "enemy": 0.75, "ai": 0.75, "xp": 1.25, "gold": 1.25, "wipe_gold": 0.0,
		"desc": "For the story, or just a good time. Weaker enemies, bigger rewards, no gold lost when you fall." },
	Level.NORMAL: { "name": "Normal", "enemy": 1.0, "ai": 1.0, "xp": 1.0, "gold": 1.0, "wipe_gold": 0.2,
		"desc": "The intended climb. Expect to fall a few times, especially to stage bosses." },
	Level.HARD: { "name": "Hard", "enemy": 1.1, "ai": 1.15, "xp": 0.95, "gold": 0.9, "wipe_gold": 0.25,
		"desc": "Challenging but fair. Weaknesses, rows and potions all matter." },
	Level.HELL: { "name": "Hell", "enemy": 1.35, "ai": 1.4, "xp": 0.85, "gold": 0.75, "wipe_gold": 0.4,
		"desc": "The grind. Much stronger enemies, smaller rewards, no Scouting Lens for sale, pricier potions, and stage bosses bring extra escorts." },
}

## Hell-only extras.
const HELL_CONSUMABLE_PRICE := 1.5
const HELL_BANNED_ITEMS := [&"scouting_lens"]


static func all() -> Array:
	return DATA.keys()


static func is_valid(level) -> bool:
	return level is int and DATA.has(level)


static func name_of(level: int) -> String:
	return DATA.get(level, DATA[DEFAULT]).name


static func desc_of(level: int) -> String:
	return DATA.get(level, DATA[DEFAULT]).desc


static func value(level: int, key: String) -> float:
	return DATA.get(level, DATA[DEFAULT])[key]


static func is_hell(level: int) -> bool:
	return level == Level.HELL


## "Hard" / "Hell + Ironman"
static func label(level: int, ironman: bool) -> String:
	return name_of(level) + (" + Ironman" if ironman else "")
