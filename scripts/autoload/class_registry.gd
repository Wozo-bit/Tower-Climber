extends Node
## Autoload "ClassRegistry": the single source of truth for every class.
## Tier 1 classes are registered in code below. Later you can also drop
## ClassDef .tres files into res://data/classes/ and they'll be picked up.

const CLASS_RESOURCE_DIR := "res://data/classes/"

var _classes: Dictionary = {}  # StringName -> ClassDef


func _init() -> void:
	_register_tier_one()
	_register_secret()
	_load_resource_classes()


func _register_tier_one() -> void:
	register(ClassDef.create(&"tank", "Tank",
		"Frontline defender who soaks hits and protects the party.",
		[Stats.Type.HEALTH, Stats.Type.STAMINA] as Array[int], 0.60))
	register(ClassDef.create(&"mage", "Mage",
		"Wields raw arcane power to devastate enemies.",
		[Stats.Type.INTELLIGENCE] as Array[int], 0.55))
	register(ClassDef.create(&"archer", "Archer",
		"Precise ranged striker who hits hard from the back line.",
		[Stats.Type.AGILITY, Stats.Type.STRENGTH] as Array[int], 0.60))
	register(ClassDef.create(&"rogue", "Rogue",
		"Evasive opportunist who lives on speed, crits, and lucky breaks.",
		[Stats.Type.AGILITY, Stats.Type.LUCK] as Array[int], 0.60))
	# Support is intentionally looser so hybrids (e.g. Tank/Support) stay viable.
	register(ClassDef.create(&"support", "Support",
		"Keeps the party standing with heals, buffs, and wards.",
		[Stats.Type.INTELLIGENCE, Stats.Type.STAMINA] as Array[int], 0.40))


## Secret classes: hidden until their questline is complete (SecretPaths).
func _register_secret() -> void:
	var ash := ClassDef.create(&"ashbound_knight", "Ashbound Knight",
		"A blade that remembers fire. Strikes with steel and cinders alike.",
		[Stats.Type.STRENGTH, Stats.Type.INTELLIGENCE] as Array[int], 0.55)
	ash.is_secret = true
	register(ash)

	# New Game+ only: deliberately stronger than anything in a first run.
	# +20% to every stat, three skills, and no stat requirement (any build works).
	var asc := ClassDef.create(&"ascendant", "Ascendant",
		"One who has already conquered the tower and climbs it again. Every stat +20%.",
		[] as Array[int], 0.0)
	asc.is_secret = true
	asc.ng_plus_only = true
	asc.stat_bonus_pct = 0.2
	register(asc)


func _load_resource_classes() -> void:
	if not DirAccess.dir_exists_absolute(CLASS_RESOURCE_DIR):
		return
	for file in DirAccess.get_files_at(CLASS_RESOURCE_DIR):
		if file.ends_with(".tres") or file.ends_with(".res"):
			var def := load(CLASS_RESOURCE_DIR + file) as ClassDef
			if def:
				register(def)


func register(def: ClassDef) -> void:
	if _classes.has(def.id):
		push_warning("ClassRegistry: overwriting class '%s'" % def.id)
	_classes[def.id] = def


func get_class_def(id: StringName) -> ClassDef:
	return _classes.get(id)


func get_all() -> Array[ClassDef]:
	var result: Array[ClassDef] = []
	for def in _classes.values():
		result.append(def)
	return result


func get_tier(tier: int) -> Array[ClassDef]:
	var result: Array[ClassDef] = []
	for def: ClassDef in _classes.values():
		if def.tier == tier:
			result.append(def)
	return result


## Every class in `tier` the stat block currently qualifies for.
## `unlocked_secrets` = secret class ids the player has unlocked; other secret
## classes are never offered.
func get_qualifying(stats: StatBlock, tier: int = 1, unlocked_secrets: Array = []) -> Array[ClassDef]:
	var result: Array[ClassDef] = []
	for def in get_tier(tier):
		if def.is_secret and not unlocked_secrets.has(def.id):
			continue
		if def.qualifies(stats):
			result.append(def)
	return result


## Non-secret classes the player does NOT qualify for, closest first.
## Returns Array of { "def": ClassDef, "share": float, "points_short": int }.
func get_near_misses(stats: StatBlock, tier: int = 1) -> Array:
	var result: Array = []
	for def in get_tier(tier):
		if def.is_secret or def.qualifies(stats):
			continue
		result.append({
			"def": def,
			"share": def.qualification_share(stats),
			"points_short": def.points_short(stats),
		})
	result.sort_custom(func(a, b): return a.points_short < b.points_short)
	return result
