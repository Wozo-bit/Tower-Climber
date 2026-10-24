extends Node
## Autoload "ClassRegistry": the single source of truth for every class.
## Tier 1 classes are registered in code below. Later you can also drop
## ClassDef .tres files into res://data/classes/ and they'll be picked up.

const CLASS_RESOURCE_DIR := "res://data/classes/"

var _classes: Dictionary = {}  # StringName -> ClassDef


## Advancement tiers: what it takes before a tier opens up at all (each class
## then has its own stat build, trial quest and maybe a route on top).
## "floor" = you must have climbed past it (beaten its boss); "level" = the
## character's level. Add tiers 3, 4, 5... here as the tower grows (and their
## classes below) — no other code changes needed.
const ADVANCEMENT_GATES := {
	2: { "floor": 20, "level": 25 },
}


func _init() -> void:
	_register_tier_one()
	_register_tier_two()
	_register_secret()
	_load_resource_classes()


## Tier 2: two advancements per tier-1 class, plus route-only ones.
## Placeholder names and numbers. Skills are in SkillLibrary.CLASS_SKILLS.
func _register_tier_two() -> void:
	var S := Stats.Type
	_advanced(&"bastion", "Bastion", "An immovable wall that shields the whole party.", &"tank", [S.HEALTH, S.STAMINA], 0.6)
	_advanced(&"juggernaut", "Juggernaut", "Trades a little defense for crushing, armor-breaking blows.", &"tank", [S.STRENGTH, S.HEALTH], 0.6)
	_advanced(&"paladin", "Paladin", "A holy knight who heals as well as protects. Hero route only.", &"tank", [S.HEALTH, S.INTELLIGENCE], 0.5, &"hero")
	_advanced(&"pyromancer", "Pyromancer", "Fire turned deeper: magma and infernos.", &"mage", [S.INTELLIGENCE], 0.55)
	_advanced(&"stormcaller", "Stormcaller", "Lightning and wind that sweep the whole field.", &"mage", [S.INTELLIGENCE, S.AGILITY], 0.6)
	_advanced(&"warlock", "Warlock", "Dark magic bought at a price. Villain route only.", &"mage", [S.INTELLIGENCE, S.HEALTH], 0.55, &"villain")
	_advanced(&"sharpshooter", "Sharpshooter", "One arrow, one weak point.", &"archer", [S.AGILITY, S.LUCK], 0.6)
	_advanced(&"ranger", "Ranger", "Rides the wind; arrows that cover the field.", &"archer", [S.AGILITY, S.STRENGTH], 0.6)
	_advanced(&"assassin", "Assassin", "Strikes from the dark, from any row.", &"rogue", [S.AGILITY, S.STRENGTH], 0.6)
	_advanced(&"trickster", "Trickster", "Luck, misdirection, and an unfair amount of dodging.", &"rogue", [S.LUCK, S.AGILITY], 0.6)
	_advanced(&"executioner", "Executioner", "Delivers the judgment the law won't. Vigilante route only.", &"rogue", [S.STRENGTH, S.AGILITY], 0.6, &"vigilante")
	_advanced(&"cleric", "Cleric", "Holy light that mends the party and burns the wicked.", &"support", [S.INTELLIGENCE, S.HEALTH], 0.5)
	_advanced(&"oracle", "Oracle", "Sees the blow coming and moves the party out of its way.", &"support", [S.INTELLIGENCE, S.LUCK], 0.5)


## Tier-2 bonus: +10% to every stat (Ascendant's +20% stays the strongest).
const ADVANCED_STAT_BONUS := 0.1


func _advanced(id: StringName, display: String, desc: String, from: StringName, stats: Array,
		threshold: float, route: StringName = &"") -> void:
	var typed: Array[int] = []
	typed.assign(stats)
	var def := ClassDef.create(id, display, desc, typed, threshold, ClassDef.tier_of_next(get_class_def(from)))
	def.advances_from = from
	def.required_route = route
	def.stat_bonus_pct = ADVANCED_STAT_BONUS
	register(def)


# =========================================================
# Lineage (advanced classes inherit from the class they came from)
# =========================================================

## The class and every class it advanced from: [pyromancer, mage].
func lineage(id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	var def := get_class_def(id)
	while def and not out.has(def.id):
		out.append(def.id)
		def = get_class_def(def.advances_from) if def.advances_from != &"" else null
	return out


## The tier-1 class at the root of the line (pyromancer -> mage).
func root_of(id: StringName) -> StringName:
	var line := lineage(id)
	return line[-1] if not line.is_empty() else id


## True if `id` is `ancestor` or advanced from it (a Pyromancer counts as a Mage).
func is_in_lineage(id: StringName, ancestor: StringName) -> bool:
	return lineage(id).has(ancestor)


## The classes `id` can advance into (next tier), sorted by name.
func advancements_for(id: StringName) -> Array[ClassDef]:
	var out: Array[ClassDef] = []
	for def: ClassDef in _classes.values():
		if def.advances_from == id and id != &"":
			out.append(def)
	out.sort_custom(func(a, b): return a.display_name < b.display_name)
	return out


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
