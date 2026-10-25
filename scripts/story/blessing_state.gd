class_name BlessingState
extends RefCounted
## This run's relationship with the gods, demons and devils (BeingLibrary):
## how interested each one is in the player, who has been refused or scorned,
## and the rules for offers, levels, warnings and punishment.
## The blessing itself lives on the CharacterData (so NPCs can have one too).
## Lives in GameState.blessings, saved with the run.

## Interest needed for a being to make you an offer.
const OFFER_INTEREST := 10
## Interest for blessing levels 1, 2, 3 (level 1 = the offer threshold).
const LEVEL_INTEREST := [10, 25, 45]
## At or below this the being warns you; at or below PUNISH it punishes you.
const WARN_INTEREST := 0
const PUNISH_INTEREST := -10
## Punishment: the curse (no buff) lingers this many floors, and everyone in
## the party loses this share of their current HP (never below 1).
const PUNISH_FLOORS := 5
const PUNISH_HP_PCT := 0.3
## A refused being waits this many floors before asking again.
const REOFFER_FLOORS := 5
## Rivals are jealous: a being loses this much interest while you're blessed
## by one of its rivals.
const RIVAL_PENALTY := 15
## Most shrines on one rest floor (the most interested beings).
const MAX_SHRINES := 3

## being id -> { "bonus": int, "scorned": bool, "refused_floor": int, "warned": bool }
var beings: Dictionary = {}
## Toasts for the floor HUD.
var messages: Array[String] = []


func _state(id: StringName) -> Dictionary:
	if not beings.has(id):
		beings[id] = { "bonus": 0, "scorned": false, "refused_floor": -999, "warned": false }
	return beings[id]


## How interested a being is in the player right now.
func interest(id: StringName) -> int:
	var b := BeingLibrary.get_being(id)
	if b.is_empty():
		return 0
	var r: RouteState = GameState.route
	var total: int = beings.get(id, {}).get("bonus", 0)
	for route_id in b.values.get("likes", []):
		total += r.points_of(route_id)
	for route_id in b.values.get("dislikes", []):
		total -= r.points_of(route_id)
	var blessed_by: StringName = GameState.player.blessing_id
	if blessed_by != &"" and blessed_by != id and BeingLibrary.rivals_of(id).has(blessed_by):
		total -= RIVAL_PENALTY   # jealous of the rival you chose
	return total


## Choices can please or anger a being directly (dialogue "interest" effect).
func add_interest(id: StringName, amount: int) -> void:
	if BeingLibrary.beings.has(id):
		_state(id)["bonus"] = _state(id).bonus + amount
		update()


static func level_for_interest(i: int) -> int:
	var level := 0
	for t in LEVEL_INTEREST:
		if i >= t:
			level += 1
	return level


## Would this being offer its blessing to `c` (the player) now?
func wants_to_offer(id: StringName) -> bool:
	var s: Dictionary = beings.get(id, {})
	var player: CharacterData = GameState.player
	if BeingLibrary.get_being(id).get("self", false):
		return false   # your own god (you, in New Game+)
	return not s.get("scorned", false) and player.blessing_id != id and interest(id) >= OFFER_INTEREST \
		and GameState.floor_number >= s.get("refused_floor", -999) + REOFFER_FLOORS


## Beings ready to make an offer, most interested first.
func offering_beings() -> Array:
	var out := BeingLibrary.beings.keys().filter(func(id): return wants_to_offer(id))
	out.sort_custom(func(a, b): return interest(a) > interest(b) or (interest(a) == interest(b) and String(a) < String(b)))
	return out


## "400 gold" / "a promise: Oath of Vengeance" / "" (no price).
static func bargain_text(id: StringName) -> String:
	var bargain: Dictionary = BeingLibrary.get_being(id).get("bargain", {})
	if bargain.has("gold"):
		return "%d gold" % bargain.gold
	if bargain.has("quest"):
		return "a promise: %s" % QuestLibrary.get_quest(bargain.quest).get("title", "?")
	return ""


func can_pay(id: StringName) -> bool:
	var bargain: Dictionary = BeingLibrary.get_being(id).get("bargain", {})
	if bargain.has("gold"):
		return GameState.player.gold >= bargain.gold
	if bargain.has("quest"):
		return GameState.quests.is_new(bargain.quest)
	return true


## The player accepts. Pays the bargain (if any) and takes the blessing at the
## level their interest supports. Replaces any blessing they had (no penalty).
func accept(id: StringName) -> bool:
	if not wants_to_offer(id) or not can_pay(id):
		return false
	var bargain: Dictionary = BeingLibrary.get_being(id).get("bargain", {})
	if bargain.has("gold"):
		GameState.player.gold -= bargain.gold
	if bargain.has("quest"):
		GameState.quests.start(bargain.quest)
	# Rivals who wanted you too are jealous (checked before you're blessed).
	var jealous := BeingLibrary.rivals_of(id).filter(func(r): return wants_to_offer(r))
	GameState.player.bless(id, maxi(1, level_for_interest(interest(id))))
	_state(id)["warned"] = false
	messages.append("You are blessed by %s." % BeingLibrary.full_name(id))
	var p: CharacterData = GameState.player
	if not jealous.is_empty() and p.curse_id == &"":
		var rival: StringName = jealous[0]
		p.curse(rival, 1, GameState.floor_number + PUNISH_FLOORS)
		messages.append("%s is furious you chose %s, and curses you out of spite!" % [
			BeingLibrary.get_being(rival).name, BeingLibrary.get_being(id).name])
	return true


func refuse(id: StringName) -> void:
	_state(id)["refused_floor"] = GameState.floor_number


## Re-checks the player's blessing after anything that changes interest:
## level ups (and downs), warnings, punishment, and lingering curses ending.
func update() -> void:
	var p: CharacterData = GameState.player
	if p.curse_until_floor > 0 and GameState.floor_number > p.curse_until_floor:
		p.lift_curse()
		messages.append("The curse on you lifts.")
	if p.blessing_id == &"":
		return
	var id := p.blessing_id
	var i := interest(id)
	if i <= PUNISH_INTEREST:
		punish(id)
		return
	if i <= WARN_INTEREST:
		if not _state(id).warned:
			_state(id)["warned"] = true
			GameState.pending_talks.append({ "dialogue": &"blessing_warning", "being": id })
		return
	if i > WARN_INTEREST + 5:
		_state(id)["warned"] = false   # back in its good graces: the next drift warns again
	var level := maxi(1, level_for_interest(i))
	if level != p.blessing_level:
		var up := level > p.blessing_level
		p.bless(id, level)
		messages.append("%s's blessing %s (level %d)." % [BeingLibrary.get_being(id).name,
			"grows stronger" if up else "weakens", level])


## The being punishes the player: the blessing is taken, its curse lingers
## for PUNISH_FLOORS floors, the whole party is struck, and it never offers again.
func punish(id: StringName) -> void:
	var p: CharacterData = GameState.player
	var level := p.blessing_level
	p.unbless()
	p.curse(id, level, GameState.floor_number + PUNISH_FLOORS)
	_state(id)["scorned"] = true
	for m in GameState.battle_party():
		if not m.is_downed():
			m.set_current_hp(maxi(1, roundi(m.current_hp() * (1.0 - PUNISH_HP_PCT))))
	GameState.pending_talks.append({ "dialogue": &"blessing_punish", "being": id })
	messages.append("%s punishes you!" % BeingLibrary.full_name(id))


func to_dict() -> Dictionary:
	var out := {}
	for id in beings:
		out[String(id)] = beings[id].duplicate()
	return { "beings": out }


static func from_dict(d: Dictionary) -> BlessingState:
	var st := BlessingState.new()
	var S := SaveSerializer
	var bd := S._d(d, "beings")
	for id in bd:
		if id is String and BeingLibrary.beings.has(StringName(id)) and bd[id] is Dictionary:
			var e: Dictionary = bd[id]
			st.beings[StringName(id)] = { "bonus": S._i(e, "bonus", 0, -9999, 9999), "scorned": S._b(e, "scorned", false),
				"refused_floor": S._i(e, "refused_floor", -999, -999, 100000), "warned": S._b(e, "warned", false) }
	return st
