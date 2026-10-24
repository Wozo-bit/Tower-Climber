class_name RouteState
extends RefCounted
## This run's route standing: points per route and the locked route, if any.
## Lives in GameState.route, saved with the run, reset in New Game+.

## route id -> points
var points: Dictionary = {}
## Set by a key story choice or a big enough lead. &"" = not locked.
var locked: StringName = &""
## Hint toasts waiting to be shown ("Your path is set: ...").
var messages: Array[String] = []


func points_of(id: StringName) -> int:
	return points.get(id, 0)


func add(id: StringName, amount: int) -> void:
	if not RouteLibrary.routes.has(id) or amount == 0:
		return
	points[id] = maxi(0, points_of(id) + amount)
	_maybe_auto_lock()


## A key story choice: this route for good. False if already locked.
func lock(id: StringName) -> bool:
	if locked != &"" or not RouteLibrary.routes.has(id):
		return false
	locked = id
	messages.append("Your path is set. %s" % RouteLibrary.routes[id].hints[1])
	return true


## The route you're on: the locked one, else the one you're clearly leaning
## toward (at least LEAN_POINTS and ahead of the rest), else &"" (neutral).
func current() -> StringName:
	if locked != &"":
		return locked
	var ranked := _ranked()
	if ranked.is_empty() or points_of(ranked[0]) < RouteLibrary.LEAN_POINTS:
		return &""
	if ranked.size() > 1 and points_of(ranked[1]) == points_of(ranked[0]):
		return &""   # a tie isn't a lean
	return ranked[0]


## The vague line the player sees (Tab menu). Never shows numbers.
func reputation_text() -> String:
	var r := current()
	if r == &"":
		return "Nobody knows quite what to make of you yet."
	var hints: Array = RouteLibrary.routes[r].hints
	return hints[1] if locked == r or points_of(r) >= RouteLibrary.LOCK_POINTS else hints[0]


func _ranked() -> Array:
	var ids := points.keys().filter(func(id): return RouteLibrary.routes.has(id))
	ids.sort_custom(func(a, b): return points_of(a) > points_of(b) or (points_of(a) == points_of(b) and String(a) < String(b)))
	return ids


func _maybe_auto_lock() -> void:
	if locked != &"":
		return
	var ranked := _ranked()
	if ranked.is_empty():
		return
	var top := points_of(ranked[0])
	var second := points_of(ranked[1]) if ranked.size() > 1 else 0
	if top >= RouteLibrary.LOCK_POINTS and top - second >= RouteLibrary.LOCK_LEAD:
		lock(ranked[0])


func to_dict() -> Dictionary:
	var p := {}
	for id in points:
		p[String(id)] = points[id]
	return { "points": p, "locked": String(locked) }


static func from_dict(d: Dictionary) -> RouteState:
	var r := RouteState.new()
	var p := SaveSerializer._d(d, "points")
	for id in p:
		if id is String and RouteLibrary.routes.has(StringName(id)):
			r.points[StringName(id)] = SaveSerializer._i(p, id, 0, 0, 99999)
	var l := StringName(SaveSerializer._s(d, "locked"))
	r.locked = l if RouteLibrary.routes.has(l) else &""
	return r
