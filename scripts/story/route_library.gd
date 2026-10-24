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
		"text": "(Placeholder) You reached the top as no one in particular. The tower will remember the climb, if not the climber." },
	{ "id": &"hero", "title": "The Hero's Ending", "priority": 10, "if": { "route": &"hero" },
		"text": "(Placeholder) The floors below celebrate. You climbed for them, and they know it." },
	{ "id": &"villain", "title": "The Villain's Ending", "priority": 10, "if": { "route": &"villain" },
		"text": "(Placeholder) The tower is yours now, and everyone in it." },
	{ "id": &"vigilante", "title": "The Vigilante's Ending", "priority": 10, "if": { "route": &"vigilante" },
		"text": "(Placeholder) No one asked you to climb. No one will stop you either." },
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
