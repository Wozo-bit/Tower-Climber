class_name NpcLibrary
extends RefCounted
## People and lore objects you can bump into on a floor. Each one runs a
## conversation from DialogueLibrary when you walk into it.
##
## Fields:
##   "name":      shown in the HUD and as the default speaker
##   "kind":      "npc" (a person) or "object" (mural, item, sign...)
##   "dialogue":  DialogueLibrary id
##   "color":     placeholder art colour
##   "floors":    which kinds of floor it can be on: "rest", "boss" (only once
##                the boss is beaten), "combat", "miniboss"
##   "min_floor" / "max_floor"
##   "chance":    (default 1.0) chance to be on a floor that fits. Rolled from
##                the floor's seed, so leaving and coming back doesn't re-roll.
##   "if":        (optional) DialogueRunner condition, e.g. { "flag": &"x" }
##   "gone_flag": (optional) once this flag is set it never appears again
##                (a clue that's been read, a quest that's done)
##   "near":      (optional) "campfire" or "merchant": stands right next to it
##   "recruit":   (optional) makes it recruitable. It disappears once recruited.
##       "class_id":  class it takes at level 10+ (if its build qualifies)
##       "build":     Stats.Type -> weight; level-up points are split this way
##       "row":       (optional) Combatant.Row to start in
##
## Recruits join at the player's level - 1 (min 1). Placeholders below.

const NPCS := {
	&"brakka": {
		"name": "Brakka", "kind": "npc", "dialogue": &"brakka", "color": Color(0.85, 0.55, 0.3),
		"floors": ["rest"], "min_floor": 5, "max_floor": 9999, "near": "campfire",
		"recruit": {
			"class_id": &"tank",
			"build": { Stats.Type.HEALTH: 4, Stats.Type.STAMINA: 4, Stats.Type.STRENGTH: 3 },
		},
		# Routes he likes / won't stand for (placeholder). See GameState routes.
		"values": { "likes": [&"hero"], "dislikes": [&"villain"] },
	},
	# --- Route content (placeholders) ---
	&"black_market": {
		"name": "Hooded trader", "kind": "npc", "dialogue": &"black_market", "color": Color(0.25, 0.2, 0.3),
		"floors": ["rest", "boss"], "min_floor": 5, "max_floor": 9999, "near": "merchant",
		"if": { "route": &"villain" },
	},
	&"captured_bandit": {
		"name": "Captured bandit", "kind": "npc", "dialogue": &"captured_bandit", "color": Color(0.6, 0.5, 0.35),
		"floors": ["boss"], "min_floor": 10, "max_floor": 9999, "gone_flag": &"bandit_judged",
	},
	&"crossroads_shrine": {
		"name": "Crossroads shrine", "kind": "object", "dialogue": &"crossroads_shrine", "color": Color(0.85, 0.85, 0.95),
		"floors": ["rest"], "min_floor": 15, "max_floor": 9999,
		"if": { "route_locked": false },
	},
	# A hint about the current stage's enemies, on some normal floors.
	&"warning_scrawl": {
		"name": "Scratched warning", "kind": "object", "dialogue": &"warning_scrawl",
		"color": Color(0.45, 0.45, 0.4),
		"floors": ["combat"], "min_floor": 2, "max_floor": 9999, "chance": 0.2,
	},
	# Quest from a found item: a torn map on early floors (until you've picked
	# it up), and the cache it points to once you're on that step.
	&"torn_map": {
		"name": "Torn map", "kind": "object", "dialogue": &"torn_map",
		"color": Color(0.8, 0.75, 0.55),
		"floors": ["combat"], "min_floor": 2, "max_floor": 9, "chance": 0.3,
		"if": { "quest_new": &"torn_map" },
	},
	&"hidden_cache": {
		"name": "Loose stone", "kind": "object", "dialogue": &"hidden_cache",
		"color": Color(0.5, 0.5, 0.45),
		"floors": ["combat", "rest"], "min_floor": 6, "max_floor": 9999,
		"if": { "quest_on_step": [&"torn_map", 1] },
	},
	# Ashbound clue 1 of 3: on normal floors of stage 2 until you've read it.
	&"scorched_mural": {
		"name": "Scorched mural", "kind": "object", "dialogue": &"scorched_mural",
		"color": Color(0.55, 0.3, 0.25),
		"floors": ["combat"], "min_floor": 11, "max_floor": 29, "chance": 0.4,
		"gone_flag": &"clue_ash_scorched_mural",
	},
	# Ashbound clue 3 of 3: in the campfire's embers once the first boss is down.
	&"feather_in_embers": {
		"name": "Glint in the embers", "kind": "object", "dialogue": &"feather_in_embers",
		"color": Color(0.2, 0.2, 0.25),
		"floors": ["rest", "boss"], "min_floor": 10, "max_floor": 29, "near": "campfire",
		"gone_flag": &"clue_ash_feather_in_embers",
	},
}


static func get_npc(id: StringName) -> Dictionary:
	return NPCS.get(id, {})


static func is_recruitable(id: StringName) -> bool:
	return get_npc(id).has("recruit")


## NPCs that belong on this floor right now, in a stable order.
## `floor_kind` is "rest", "boss", "combat" or "miniboss". `rng_for(id)` must
## return a RandomNumberGenerator seeded for that NPC on this floor.
static func npcs_for_floor(floor_n: int, floor_kind: String, rng_for: Callable) -> Array[StringName]:
	var out: Array[StringName] = []
	var ids := NPCS.keys()
	ids.sort()
	for id in ids:
		var n: Dictionary = NPCS[id]
		if not floor_kind in n.get("floors", []):
			continue
		if floor_n < n.get("min_floor", 1) or floor_n > n.get("max_floor", 9999):
			continue
		if n.has("gone_flag") and GameState.has_flag(n.gone_flag):
			continue
		if n.has("recruit") and GameState.has_recruited(id):
			continue
		if not DialogueRunner.check(n.get("if", {})):
			continue
		var rng: RandomNumberGenerator = rng_for.call(id)
		if rng.randf() >= n.get("chance", 1.0):
			continue
		out.append(id)
	return out


## Builds a recruit at `level` with points split by its build and its class
## taken if it qualifies.
static func make_recruit(id: StringName, level: int) -> CharacterData:
	var n := get_npc(id)
	if not n.has("recruit"):
		return null
	var r: Dictionary = n.recruit
	var c := CharacterData.new()
	c.character_name = n.name
	c.companion_id = id
	while c.level < maxi(1, level):
		c.level_up()
	if c.unspent_points > 0:
		c.apply_allocation(split_points(c.unspent_points, r.build))
	if c.can_choose_class():
		var def := ClassRegistry.get_class_def(r.get("class_id", &""))
		if def and not def.is_secret:
			c.choose_class(def)
	if r.has("row"):
		c.battle_row = r.row
	return c


## Splits `points` by the weights (largest remainder, so it always adds up).
static func split_points(points: int, weights: Dictionary) -> Dictionary:
	var total := 0
	for s in weights:
		total += weights[s]
	var out := {}
	if total <= 0:
		return out
	var given := 0
	var rema := []
	for s in weights:
		var exact: float = float(points) * weights[s] / total
		out[s] = int(exact)
		given += out[s]
		rema.append([exact - int(exact), s])
	rema.sort_custom(func(a, b): return a[0] > b[0])
	for i in points - given:
		out[rema[i % rema.size()][1]] += 1
	return out
