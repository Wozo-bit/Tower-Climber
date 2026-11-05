class_name RouteLibrary
extends RefCounted
## Routes (Hero, Villain, Vigilante, ...) and the endings they lead to.
##
## Routes are tracked as points (RouteState). Choices, quests and bounties add
## points; a few big story choices LOCK a route for good, and a big enough
## lead locks it too. The player only ever sees hints (reputation text and
## NPC reactions), never the numbers.
##
## Built to be added to: DLC (see DlcLoader) can call register_route() and
## register_ending() to add new routes and endings without touching these.
##
## An ending: { "id", "title", "text", "priority": int, "if": <condition> }
##   When the run ends, the highest-priority ending whose condition passes is
##   used, so a more specific ending (priority 20, "if" route hero + a flag)
##   beats the plain route ending (priority 10). The neutral ending (priority 0,
##   no condition) always matches as the fallback.
##   Conditions are DialogueRunner conditions, e.g. { "route": &"hero" },
##   { "route_locked": &"villain" }, { "no_route": true }, { "flag": &"x" }.

## Points to count as leaning toward a route (hints, merchant prices, companions).
const LEAN_POINTS := 10
## A route locks by itself at this many points with this much lead on the next.
const LOCK_POINTS := 30
const LOCK_LEAD := 15

const BASE_ROUTES := {
	&"hero": { "name": "Hero",
		"hints": ["People have started to speak well of you.", "They call you a hero, and mean it."] },
	&"villain": { "name": "Villain",
		"hints": ["People lower their voices when you pass.", "Your name is spoken like a threat."] },
	&"vigilante": { "name": "Vigilante",
		"hints": ["Some say you do what the law won't.", "Outlaws fear you, and so do the guards."] },
}

const BASE_ENDINGS := [
	{ "id": &"neutral", "title": "The Wanderer", "priority": 0, "if": {},
		"text": "You reached the top as no one in particular. The tower will remember the climb, if not the climber." },
	{ "id": &"hero", "title": "The Hero's Ending", "priority": 10, "if": { "route": &"hero" },
		"text": "The floors below celebrate. You climbed for them, and they know it." },
	{ "id": &"villain", "title": "The Villain's Ending", "priority": 10, "if": { "route": &"villain" },
		"text": "The tower is yours now, and everyone in it." },
	{ "id": &"vigilante", "title": "The Vigilante's Ending", "priority": 10, "if": { "route": &"vigilante" },
		"text": "No one asked you to climb. No one will stop you either." },
]

## What you did at the top of a first climb: replaces the ending's title and text,
## keeping its id (the ending id suggests your domains).
const FINAL_CHOICES := [
	{ "if": { "flag": &"ch10_end_forgot" }, "title": "Welcome Home",
		"text": "You went home. You feel a bit tired, and you don't know why. It's not so bad. You've done it before." },
	{ "if": { "flag": &"ch10_end_keep" }, "title": "One More Day",
		"text": "The tower is yours, and everyone in it. You kept what you built. You've got all the time in the world." },
	{ "if": { "flag": &"ch10_end_draw" }, "title": "The Last Floor",
		"text": "You did the people. They did the lines. There's a way out of the tower now, and nobody has to climb it twice. They woke up. Somebody's still by the fire, with two terrible cups." },
	{ "if": { "flag": &"ch10_end_judge", "any_flag": [&"ch10_friend_went"] }, "title": "The Sentence",
		"text": "Someone with every right told you what you owed. You pressed it yourself. They woke up, and they laugh with their mouth open now, and you're still paying it." },
	{ "if": { "flag": &"ch10_end_judge" }, "title": "The Sentence",
		"text": "Someone with every right told you what you owed. You pressed it yourself. They woke up. You told them about someone they'd have liked, and you're still paying it." },
	{ "if": { "any_flag": [&"ch10_friend_went"] }, "title": "The Laugh",
		"text": "The tower's gone, and everyone on its stairs. They woke up. Now and then they laugh with their mouth open, and they don't know where they got it. You do." },
	{ "if": { "flag": &"ch10_end_reset" }, "title": "The Reset",
		"text": "The tower's gone, and everyone on its stairs. They woke up. You told them about someone they'd have liked. It took a long time." },
]

## Live tables: the base content plus anything DLC registered.
static var routes: Dictionary = BASE_ROUTES.duplicate(true)
static var endings: Array = BASE_ENDINGS.duplicate(true)


static func register_route(id: StringName, def: Dictionary) -> void:
	routes[id] = def


## Adds (or replaces, by id) an ending.
static func register_ending(def: Dictionary) -> void:
	for i in endings.size():
		if endings[i].id == def.id:
			endings[i] = def
			return
	endings.append(def)


static func route_name(id: StringName) -> String:
	return routes.get(id, {}).get("name", "No one")


static func get_ending(id: StringName) -> Dictionary:
	for e in endings:
		if e.id == id:
			return e
	return {}


## The ending this run gets right now (highest priority that fits).
static func pick_ending() -> Dictionary:
	var best := {}
	for e in endings:
		if DialogueRunner.check(e.get("if", {})) and (best.is_empty() or e.get("priority", 0) > best.get("priority", 0)):
			best = e
	for choice in FINAL_CHOICES:
		if DialogueRunner.check(choice.if):
			best = best.duplicate()
			best.title = choice.title
			best.text = choice.text
			break
	return best


## Problems with the route/ending data ([] = all good). Run by the tests.
static func validate() -> PackedStringArray:
	var problems: PackedStringArray = []
	var has_fallback := false
	for e in endings:
		if e.get("title", "") == "" or e.get("text", "") == "":
			problems.append("ending %s: needs a title and text" % e.get("id"))
		if (e.get("if", {}) as Dictionary).is_empty():
			has_fallback = true
		for k in e.get("if", {}):
			if not k in DialogueLibrary.CONDITION_KEYS:
				problems.append("ending %s: unknown condition '%s'" % [e.id, k])
		for k in ["route", "route_locked"]:
			if e.get("if", {}).has(k) and not routes.has(e["if"][k]):
				problems.append("ending %s: unknown route '%s'" % [e.id, e["if"][k]])
	if not has_fallback:
		problems.append("no fallback ending (one with no condition)")
	for id in routes:
		if routes[id].get("hints", []).size() < 2:
			problems.append("route %s: needs 2 hint lines (leaning, strong)" % id)
	return problems
