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
## A lone climber (nobody has fought beside you this run) draws the gods' eye.
const SOLO_INTEREST := 5
## Declining an offer (see decline).
const CALM_TEMPER := 0.3
const STRIKE_TEMPER := 0.8
const GIFT_INTEREST := 25
## Even when a god approves, a gift is rare: this, reduced by its temper...
const GIFT_CHANCE := 0.15
## ...and only this many per run (Hayden 2026-11-05: it felt like every god).
const MAX_GIFTS := 2
## What each being says when you turn it down. "no" = no hard feelings.
const DECLINE_LINES := {
	&"odin": { "no": "Refuse, then. I gave an eye for less than you've just thrown away.", "curse": "You refuse the one who hung nine nights on a tree? Carry this up with you, and learn what a price is.", "gift": "You owe me nothing for this. That's what should worry you." },
	&"thor": { "no": "Ha! Suit yourself. Come and find me when something needs hitting.", "curse": "No? NO? I've flattened mountains for less. Here. Feel that.", "gift": "You've got a good arm and a bad attitude. Take this anyway." },
	&"loki": { "no": "Oh, you're no fun. I'll ask again when you're desperate. It's so much better then.", "curse": "Ooh, that's a shame. I've already told everyone you said yes. Enjoy the itching.", "gift": "" },
	&"hel": { "no": "Everyone comes down to me eventually. I can afford to be polite.", "curse": "Half of me is sorry. See if you can guess which half did this.", "gift": "" },
	&"zeus": { "no": "You have the nerve to say no to me. Very well. Remember the sky has a long memory.", "curse": "I have struck down kings for less. Consider this a warning, and a mild one.", "gift": "I don't often say this. You'll do. Keep it, and stay out of my way." },
	&"athena": { "no": "A considered answer. I'd have respected nothing less. Think on it.", "curse": "You chose badly, and you chose without thinking. That I will correct.", "gift": "You reason well, for someone who won't listen. Take this. Use it wisely." },
	&"hades": { "no": "No matter. My door's the one door that's always open.", "curse": "You think that's your choice to make, down here? Think again, for a few floors.", "gift": "You've earned this. Not many do. Don't tell my brothers." },
	&"typhon": { "no": "Crawl on, then, little thing. The mountain's still on my back either way.", "curse": "SMALL. You are so SMALL, to say no to me.", "gift": "" },
	&"ra": { "no": "As you wish. The sun will rise on you regardless. It isn't personal.", "curse": "You turn your face from the light? Then see how you like the glare.", "gift": "Walk in the light, then, in your own way. Take this with you." },
	&"anubis": { "no": "I'll weigh that too, in its time. No hurry. There's never any hurry.", "curse": "I am not angry. The scale simply tips. You'll feel it for a while.", "gift": "Your heart's lighter than you think. Take this, and go carefully." },
	&"set": { "no": "Fine. There's a storm coming either way. Stand where you like.", "curse": "Nobody tells me no twice. You don't even get to tell me no once.", "gift": "" },
	&"apep": { "no": "The dark doesn't ask twice. It only waits.", "curse": "You'll have nothing left, soon enough. Let me help you start.", "gift": "" },
	&"guan_yu": { "no": "A person's word is theirs to give or keep. I respect that. Go well.", "curse": "You have given a poor answer, and you'll answer for it, honestly. Go on.", "gift": "You keep your word. That's rare. Take this, and go on keeping it." },
	&"sun_wukong": { "no": "Ha! Nobody tells me what to do either. Go on, then! Race you up.", "curse": "Oh, you want to play? I've been waiting five hundred years for someone to play with!", "gift": "I like you. Here, I stole this. I mean, I earned it. Take it, quick." },
	&"yama": { "no": "It's all written down. Your answer too. Go on with your climb.", "curse": "That goes in the account, and the account always comes due.", "gift": "Your account's better than you know. Take this, and keep it that way." },
	&"baigujing": { "no": "You'll change your mind. Or something wearing you will.", "curse": "That was unkind. I've got such a lot of faces, and I'll remember you with all of them.", "gift": "" },
	&"amaterasu": { "no": "Then I'll go on shining on you all the same. Go gently.", "curse": "You've hidden from the light. It'll be a little colder for you, until you come back out.", "gift": "You didn't need me for this, and I'd like you to have it anyway." },
	&"susanoo": { "no": "Hmph. Good. I never listened to anyone either, and look how that went.", "curse": "You've got a nerve! So have I. Let's see who's still standing after the storm.", "gift": "You've got a temper worth having. Take this. Try not to break anything I like." },
	&"inari": { "no": "Of course. There's always enough, and the door's always open. Eat something.", "curse": "", "gift": "There's always enough. Here, take some with you. No, really. Take it." },
	&"shuten_doji": { "no": "More for me, then! Come back when you're thirsty.", "curse": "You won't drink with me? Oh, that's a very rude thing to do to an oni.", "gift": "" },
	&"tamamo": { "no": "So sensible. I do so like it when they think they've been sensible.", "curse": "Oh, sweet thing. I've ruined emperors for less. You'll hardly feel it at first.", "gift": "" },
	&"ishtar": { "no": "Fine. Go on, then. Love and war both come round again. I'll be there.", "curse": "You don't refuse me. Ask the bull of heaven. Ask anyone at all.", "gift": "You've got a fire in you. I like that. Take this, and burn something." },
	&"tiamat": { "no": "I was the sea before there was anything to say no. Say what you like.", "curse": "I gave birth to the first monsters. Here's a small one, to keep you company.", "gift": "" },
	&"morrigan": { "no": "I've already seen how this goes. You still have to walk it.", "curse": "I washed your armour in the river last night, climber. You'll want to watch your step.", "gift": "" },
	&"mammon": { "no": "Your loss, literally. I'll put it in the ledger, with the interest.", "curse": "Nobody walks away from a deal for free. That'll be a few floors of your luck.", "gift": "" },
	&"mephistopheles": { "no": "Of course. Take all the time you need. Everyone does. I keep the file open.", "curse": "You've misread the small print. You can't refuse without signing here. And here.", "gift": "" },
}
## For gods without their own lines (past players, DLC).
const DECLINE_FALLBACK := {
	"god": ["As you wish. The offer stands for those who earn it.", "So be it. I've been refused by better, and I've blessed worse.", "Go on, then. I hope you find what you're looking for."],
	"demon": ["Your loss, little climber. Crawl on.", "You'll want me, further up. They all do.", "Fine. Stay small."],
	"devil": ["Everyone changes their mind eventually. I can wait.", "No hard feelings. No feelings at all, in fact.", "I'll hold on to the paperwork."],
}
## What the being said when you last declined it (for the dialogue).
var last_refusal := ""

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
	if GameState.solo_run and GameState.floor_number > 1:
		total += SOLO_INTEREST
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
	if not Settings.god_offers or player.godless():
		return false   # the player turned offers off, or walks the Unsworn line
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
	GameState.sync_relic()
	var p: CharacterData = GameState.player
	if not jealous.is_empty() and p.curse_id == &"":
		var rival: StringName = jealous[0]
		p.curse(rival, 1, GameState.floor_number + PUNISH_FLOORS)
		messages.append("%s is furious you chose %s, and curses you out of spite!" % [
			BeingLibrary.get_being(rival).name, BeingLibrary.get_being(id).name])
	return true


func refuse(id: StringName) -> void:
	_state(id)["refused_floor"] = GameState.floor_number


## The player says no to an offer they could have taken. What the being does
## depends on its temper (BeingLibrary.TEMPER) and your values (Hayden 2026-11-04):
##  - a GOD who approves of your path (you lean its way, or high interest) may
##    give you its skill anyway, once, no strings;
##  - a proud being may curse you for a few floors (the hottest strike too);
##    gentle beings (temper under CALM_TEMPER) never do.
## Returns "gift", "curse" or "". Its reply is in last_refusal.
func decline(id: StringName, rng: RandomNumberGenerator) -> String:
	refuse(id)
	var b := BeingLibrary.get_being(id)
	var temper := BeingLibrary.temper_of(id)
	var outcome := ""
	if gift_possible(id) and gifts_given() < MAX_GIFTS and rng.randf() < GIFT_CHANCE * (1.0 - temper):
		outcome = "gift"
		_state(id)["gifted"] = true
		GameState.player.learned_skills.append(b.get("skill", &""))
		GameState.player.stats_changed.emit()
		messages.append("%s gives you %s anyway." % [b.name, SkillLibrary.get_skill(b.skill).display_name])
		last_refusal = _decline_line(id, "gift", rng, "Your path is a good one, blessed or not. Keep this. No strings.")
	elif rng.randf() < curse_chance(id) and GameState.player.curse_id == &"":
		outcome = "curse"
		GameState.player.curse(id, 1, GameState.floor_number + PUNISH_FLOORS)
		if temper >= STRIKE_TEMPER:
			for m in GameState.battle_party():
				if not m.is_downed():
					m.set_current_hp(maxi(1, roundi(m.current_hp() * (1.0 - PUNISH_HP_PCT))))
		messages.append("%s curses you for refusing." % b.name)
		last_refusal = _decline_line(id, "curse", rng, "You dare refuse me? Then carry this up your tower.")
	else:
		var pool: Array = DECLINE_FALLBACK.get(b.get("kind", "god"), DECLINE_FALLBACK.god)
		last_refusal = _decline_line(id, "no", rng, pool[rng.randi_range(0, pool.size() - 1)])
	return outcome


func _decline_line(id: StringName, key: String, _rng: RandomNumberGenerator, fallback: String) -> String:
	var line: String = DECLINE_LINES.get(id, {}).get(key, "")
	return line if line != "" else fallback


## How many gods have gifted you a skill this run.
func gifts_given() -> int:
	var n := 0
	for id in beings:
		if beings[id].get("gifted", false):
			n += 1
	return n


## Could this being gift its skill to someone who declined it?
func gift_possible(id: StringName) -> bool:
	var b := BeingLibrary.get_being(id)
	var skill: StringName = b.get("skill", &"")
	if b.get("kind", "") != "god" or skill == &"" or _state(id).get("gifted", false):
		return false
	if GameState.player.learned_skills.has(skill):
		return false
	return b.get("values", {}).get("likes", []).has(GameState.route.current()) or interest(id) >= GIFT_INTEREST


## How likely this being is to curse you for refusing it.
static func curse_chance(id: StringName) -> float:
	var temper := BeingLibrary.temper_of(id)
	return 0.0 if temper < CALM_TEMPER else clampf(temper - 0.2, 0.0, 1.0)


## Re-checks the player's blessing after anything that changes interest:
## level ups (and downs), warnings, punishment, and lingering curses ending.
func update() -> void:
	var p: CharacterData = GameState.player
	GameState.sync_relic()   # blessing lost or levelled: the god's weapon follows
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
	GameState.sync_relic()
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
				"refused_floor": S._i(e, "refused_floor", -999, -999, 100000), "warned": S._b(e, "warned", false),
				"gifted": S._b(e, "gifted", false) }
	return st
