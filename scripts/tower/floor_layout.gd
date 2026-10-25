class_name FloorLayout
extends RefCounted
## Generates a tower floor from a seed: walls, start, stairs, enemy spawns.
## Same seed + floor number = same layout, so a floor can be rebuilt
## exactly after coming back from a battle scene.

const WIDTH := 29
const HEIGHT := 17
const MAX_ATTEMPTS := 30

enum Tile { FLOOR, WALL }

var floor_number := 1
var is_rest := false
var tiles := PackedByteArray()
var start := Vector2i.ZERO
var stairs := Vector2i.ZERO
var campfire := Vector2i(-1, -1)
var merchant := Vector2i(-1, -1)
## Rest floors: the notice board with quests and bounties. (-1,-1) = none.
var board := Vector2i(-1, -1)
## Where a miniboss or stage boss stands guard, in front of the stairs. (-1,-1) = none.
var guardian_spot := Vector2i(-1, -1)
var is_boss_floor := false
var enemy_spawns: Array[Vector2i] = []
## NPCs and lore objects standing on this floor: Vector2i -> NpcLibrary id.
## GameState fills this in (see place_npc); they block movement like the merchant.
var npcs: Dictionary = {}


## `p_guardian` = a miniboss guards the stairs. `p_boss` = stage-boss arena.
static func generate(seed_value: int, p_floor: int, p_rest: bool, p_guardian: bool = false,
		p_boss: bool = false) -> FloorLayout:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var f := FloorLayout.new()
	f.floor_number = p_floor
	f.is_rest = p_rest
	if p_rest:
		f._build_rest_floor()
		return f
	if p_boss:
		f._build_boss_floor(rng)
		return f
	for attempt in MAX_ATTEMPTS:
		f._build_combat_floor(rng, attempt < MAX_ATTEMPTS - 1)
		if f.distance_map(f.start).has(f.stairs):
			break
	if p_guardian:
		# Obstacles never spawn within 2 tiles of the stairs, so this is always open floor.
		f.guardian_spot = f.stairs + Vector2i.LEFT
	f._place_enemies(rng)
	return f


static func enemy_count_for_floor(n: int) -> int:
	return mini(2 + n / 5, 4)


# =========================================================
# Queries
# =========================================================

func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < WIDTH and p.y < HEIGHT


func is_wall(p: Vector2i) -> bool:
	return not in_bounds(p) or tiles[p.y * WIDTH + p.x] == Tile.WALL


## Walls, the campfire, the merchant, the notice board and NPCs all block movement.
func is_blocked(p: Vector2i) -> bool:
	return is_wall(p) or p == campfire or p == merchant or p == board or npcs.has(p)


## Puts NPC `id` on a free tile and returns it ((-1,-1) if there's no room).
## Never on/next to the entrance or stairs, never on an enemy spawn, and never
## somewhere that would cut off part of the floor. `near` = a tile to stand
## within 2 steps of (e.g. the campfire), or (-1,-1) for anywhere.
func place_npc(id: StringName, rng: RandomNumberGenerator, near := Vector2i(-1, -1)) -> Vector2i:
	var dist := distance_map(start)
	var reachable := dist.size()
	var candidates: Array[Vector2i] = []
	for p: Vector2i in dist:
		if _steps(p, start) < 2 or _steps(p, stairs) < 2 or p == guardian_spot or enemy_spawns.has(p):
			continue
		if guardian_spot.x >= 0 and _steps(p, guardian_spot) < 2:
			continue
		if near.x >= 0 and _steps(p, near) > 2:
			continue
		candidates.append(p)
	candidates.sort_custom(func(a, b): return a.y * WIDTH + a.x < b.y * WIDTH + b.x)
	for i in range(candidates.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = tmp
	for p in candidates:
		npcs[p] = id
		if distance_map(start).size() == reachable - 1:
			return p
		npcs.erase(p)
	return Vector2i(-1, -1)


static func _steps(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


## BFS distances from `from` to every reachable tile.
func distance_map(from: Vector2i) -> Dictionary:
	var dist := { from: 0 }
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var p: Vector2i = queue.pop_front()
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = p + d
			if not dist.has(n) and not is_blocked(n):
				dist[n] = dist[p] + 1
				queue.append(n)
	return dist


# =========================================================
# Builders
# =========================================================

func _fill_empty_room() -> void:
	tiles.resize(WIDTH * HEIGHT)
	for y in HEIGHT:
		for x in WIDTH:
			var border := x == 0 or y == 0 or x == WIDTH - 1 or y == HEIGHT - 1
			tiles[y * WIDTH + x] = Tile.WALL if border else Tile.FLOOR


func _set_wall(p: Vector2i) -> void:
	if in_bounds(p):
		tiles[p.y * WIDTH + p.x] = Tile.WALL


func _build_combat_floor(rng: RandomNumberGenerator, with_obstacles: bool) -> void:
	_fill_empty_room()
	start = Vector2i(1, HEIGHT / 2)
	stairs = Vector2i(WIDTH - 2, rng.randi_range(2, HEIGHT - 3))
	if not with_obstacles:
		return
	var blobs := rng.randi_range(12, 18)
	for i in blobs:
		var size := Vector2i(rng.randi_range(1, 4), rng.randi_range(1, 3))
		var pos := Vector2i(rng.randi_range(2, WIDTH - 3 - size.x), rng.randi_range(1, HEIGHT - 1 - size.y))
		var rect := Rect2i(pos, size)
		# Keep breathing room around the entrance and stairs.
		if rect.grow(2).has_point(start) or rect.grow(2).has_point(stairs):
			continue
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				_set_wall(Vector2i(x, y))


func _place_enemies(rng: RandomNumberGenerator) -> void:
	enemy_spawns.clear()
	var dist := distance_map(start)
	var candidates: Array[Vector2i] = []
	for p in dist:
		var near_boss := guardian_spot.x >= 0 and absi(p.x - guardian_spot.x) + absi(p.y - guardian_spot.y) < 4
		if dist[p] >= 7 and p != stairs and not near_boss:
			candidates.append(p)
	# Deterministic order before shuffling with our rng.
	candidates.sort_custom(func(a, b): return a.y * WIDTH + a.x < b.y * WIDTH + b.x)
	for i in range(candidates.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = tmp
	var wanted := enemy_count_for_floor(floor_number)
	for c in candidates:
		if enemy_spawns.size() >= wanted:
			break
		var too_close := false
		for e in enemy_spawns:
			if absi(e.x - c.x) + absi(e.y - c.y) < 4:
				too_close = true
				break
		if not too_close:
			enemy_spawns.append(c)


## Boss arena: open hall, boss in front of the stairs, no regular enemies.
## The campfire and merchant are placed here too, but GameState hides them
## until the boss is beaten (then this floor works as a rest floor).
func _build_boss_floor(_rng: RandomNumberGenerator) -> void:
	is_boss_floor = true
	_fill_empty_room()
	start = Vector2i(1, HEIGHT / 2)
	stairs = Vector2i(WIDTH - 2, HEIGHT / 2)
	guardian_spot = stairs + Vector2i.LEFT * 2
	campfire = Vector2i(7, HEIGHT / 2)
	merchant = Vector2i(7, HEIGHT / 2 - 4)
	# Two rows of pillars down the hall.
	for x in range(10, WIDTH - 5, 4):
		_set_wall(Vector2i(x, 3))
		_set_wall(Vector2i(x, HEIGHT - 4))
	enemy_spawns.clear()


func _build_rest_floor() -> void:
	_fill_empty_room()
	start = Vector2i(1, HEIGHT / 2)
	stairs = Vector2i(WIDTH - 2, HEIGHT / 2)
	campfire = Vector2i(WIDTH / 2, HEIGHT / 2)
	merchant = Vector2i(WIDTH / 2, HEIGHT / 2 - 4)
	board = Vector2i(WIDTH / 2, HEIGHT / 2 + 4)
	# A few pillars for looks.
	for p in [Vector2i(6, 4), Vector2i(6, 12), Vector2i(22, 4), Vector2i(22, 12)]:
		_set_wall(p)
