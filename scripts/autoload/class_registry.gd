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
	3: { "floor": 40, "level": 45 },   # Hayden 2026-10-25 (may change)
	4: { "floor": 70, "level": 60 },   # Hayden 2026-11-04
}

## Every stat +x% per tier. The Ascendant (NG+) always gets ASCENDANT_EDGE
## more than the best normal tier, so it stays the strongest (design rule).
const TIER_STAT_BONUS := { 2: 0.1, 3: 0.2, 4: 0.3 }
const ASCENDANT_EDGE := 0.1
## Demigods' own classes are a little stronger than their tier.
const DEMIGOD_EDGE := 0.05
## NG+: a character in a top-tier class can Ascend their own line (below the Ascendant).
const ASCENSION_BONUS := 0.05
const ASCENSION_GATE := { "floor": 40, "level": 50, "tier": 3 }
## Share of spent points a quest class wants in its two stats.
const QUEST_CLASS_THRESHOLD := 0.55


func _init() -> void:
	_register_tier_one()
	_register_tier_two()
	_register_tier_three()
	_register_demigods()
	_register_secret()
	_register_tier_four()
	_register_quest_classes()
	_load_resource_classes()


## Best stat bonus any normal (non-NG+) class can reach.
func best_tier_bonus() -> float:
	var best := 0.0
	for t in TIER_STAT_BONUS:
		best = maxf(best, TIER_STAT_BONUS[t])
	return best


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
	# New starting classes' advancements (2026-10-25). Necromancer: villain only.
	_advanced(&"berserker", "Berserker", "Rage without end: the more it hurts, the harder they hit.", &"warrior", [S.STRENGTH, S.HEALTH], 0.6)
	_advanced(&"warlord", "Warlord", "A war leader whose cries steel the whole party.", &"warrior", [S.STRENGTH, S.LUCK], 0.6)
	_advanced(&"grandmaster", "Grandmaster", "Perfect form: every strike lands where it should.", &"monk", [S.AGILITY, S.STRENGTH], 0.6)
	_advanced(&"shadowfist", "Shadowfist", "Fists from nowhere, past any guard.", &"monk", [S.AGILITY, S.LUCK], 0.6)
	_advanced(&"stormblade", "Stormblade", "Blade and thunder as one.", &"spellblade", [S.STRENGTH, S.INTELLIGENCE], 0.6)
	_advanced(&"arcane_knight", "Arcane Knight", "Spells woven into steel and armour.", &"spellblade", [S.INTELLIGENCE, S.STAMINA], 0.6)
	_advanced(&"blademaster", "Blademaster", "The duel perfected: parry, then strike.", &"magic_swordsman", [S.STRENGTH, S.AGILITY], 0.6)
	_advanced(&"runeguard", "Runeguard", "Runes carved into the blade hold the line.", &"magic_swordsman", [S.STAMINA, S.INTELLIGENCE], 0.6)
	_advanced(&"beastcaller", "Beastcaller", "Calls the beasts of the wild to fight.", &"summoner", [S.INTELLIGENCE, S.LUCK], 0.6)
	_advanced(&"spiritbinder", "Spiritbinder", "Binds guardian spirits to shield the living.", &"summoner", [S.INTELLIGENCE, S.HEALTH], 0.55)
	_advanced(&"necromancer_class", "Necromancer", "Raises the dead and drains the living. Villain route only.", &"summoner", [S.INTELLIGENCE, S.LUCK], 0.6, &"villain")


## Tier 3 (floor 40 + level 45): one mastery class for every tier-2 class,
## same build and route. Placeholder names (confirm with Hayden).
func _register_tier_three() -> void:
	var tier3 := {
		&"bastion": ["Aegis Lord", "The wall that never falls."],
		&"juggernaut": ["Colossus", "Unstoppable, unbreakable."],
		&"paladin": ["Templar", "Holy steel for the righteous. Hero route only."],
		&"pyromancer": ["Inferno Sage", "Fire that remembers the first flame."],
		&"stormcaller": ["Tempest Sovereign", "The sky answers to them."],
		&"warlock": ["Archwarlock", "Every pact, called in at once. Villain route only."],
		&"sharpshooter": ["Deadeye", "Never misses. Never needs a second arrow."],
		&"ranger": ["Windwalker", "Arrows ride the storm."],
		&"assassin": ["Nightblade", "Death between heartbeats."],
		&"trickster": ["Fortune's Fool", "Luck so absurd it looks like skill."],
		&"executioner": ["Headsman", "The final verdict. Vigilante route only."],
		&"cleric": ["Saint", "A miracle walking among climbers."],
		&"oracle": ["Seer of Fates", "Sees every thread, and pulls the right one."],
		&"berserker": ["Warbringer", "War made flesh."],
		&"warlord": ["Conqueror", "Every floor is a kingdom to take."],
		&"grandmaster": ["Ascetic Master", "Body and spirit, one weapon."],
		&"shadowfist": ["Phantom Fist", "A blow you never see."],
		&"stormblade": ["Tempest Blade", "Lightning with an edge."],
		&"arcane_knight": ["Mystic Knight", "A fortress of spells and steel."],
		&"blademaster": ["Sword Saint", "One cut. That's all it ever takes."],
		&"runeguard": ["Rune Warden", "The runes remember every blow they stopped."],
		&"beastcaller": ["Beast Lord", "The wild kneels."],
		&"spiritbinder": ["Soul Shepherd", "Guides spirits to guard the living."],
		&"necromancer_class": ["Lich", "Death was only a doorway. Villain route only."],
	}
	for from in tier3:
		var parent := get_class_def(from)
		var id := StringName(String(from) + "_t3")
		_advanced(id, tier3[from][0], "" + tier3[from][1], from, parent.required_stats,
			parent.threshold, parent.required_route)


## Tier 4 (floor 70, Hayden 2026-11-04): one last mastery for every tier-3 class,
## demigods' and the secret line's included. Same build and route as the class
## before it. Placeholder names. Runs after everything tier 3 is registered.
func _register_tier_four() -> void:
	var tier4 := {
		&"bastion_t3": ["Eternal Bulwark", "The last wall left standing."],
		&"juggernaut_t3": ["Titanbreaker", "It hits. Things stop being there."],
		&"paladin_t3": ["Exarch", "Judgment wearing armour."],
		&"pyromancer_t3": ["Ember Sovereign", "Everything burns eventually. They just hurry it along."],
		&"stormcaller_t3": ["Storm Eternal", "The storm stopped asking."],
		&"warlock_t3": ["Pact Sovereign", "Every debt in the tower is owed to them now. Villain route only."],
		&"sharpshooter_t3": ["Godshot", "They've aimed higher."],
		&"ranger_t3": ["Gale Sovereign", "The wind carries their arrows out of habit."],
		&"assassin_t3": ["Silent End", "You'll never know. Nobody has."],
		&"trickster_t3": ["Luck Incarnate", "The dice stopped pretending."],
		&"executioner_t3": ["Last Judge", "The sentence was always this. Vigilante route only."],
		&"cleric_t3": ["Living Miracle", "Where they walk, the wounded stand."],
		&"oracle_t3": ["Fate Weaver", "They don't see the thread. They hold it."],
		&"berserker_t3": ["War Incarnate", "War found out what it was for."],
		&"warlord_t3": ["Emperor of the Climb", "Every floor knows their name, and pays."],
		&"grandmaster_t3": ["Enlightened Fist", "There was never a difference between the body and the blow."],
		&"shadowfist_t3": ["Void Fist", "A blow from where nothing is."],
		&"stormblade_t3": ["Thunder Saint", "Lightning stops to bow."],
		&"arcane_knight_t3": ["Spell Fortress", "A castle that walks and reads."],
		&"blademaster_t3": ["Sword God", "They have stopped drawing it. It's enough that it's there."],
		&"runeguard_t3": ["Rune Sovereign", "The last rune is the one that holds the tower up."],
		&"beastcaller_t3": ["Wild King", "The tower has animals in it. All of them are theirs."],
		&"spiritbinder_t3": ["Spirit Sovereign", "The dead take their orders gently."],
		&"necromancer_class_t3": ["Death Incarnate", "Death stopped being a door, and became a job. Villain route only."],
		&"cinderbrand_t3": ["Ashen Sovereign", "Everything that ever burned answers to them."],
		&"lionheart_t3": ["Thirteenth Labor", "The one the songs don't have yet."],
		&"gorgonbane_t3": ["Written in Stars", "They hung him in the sky. He climbed down."],
		&"myrmidon_lord_t3": ["Glory Undying", "He chose the short life. The tower disagreed."],
		&"king_of_uruk_t3": ["He Who Saw the Deep", "He looked for the end of death, and found the stairs."],
		&"hound_of_ulster_t3": ["The Warp Spasm", "Even his allies stand back."],
		&"dragonslayer_t3": ["Dragon's Heir", "He tasted the blood, and understood everything."],
		&"labyrinth_hero_t3": ["Master of the Maze", "Nobody finds him, and nobody gets out."],
		&"amazon_queen_t3": ["Queen Unconquered", "No one has ever taken the belt."],
		&"songweaver_t3": ["Song at the Gate", "This time he doesn't look back."],
		&"swift_huntress_t3": ["She Was Never Caught", "They've stopped running after her."],
		&"wild_man_t3": ["Brother Unbroken", "They said death would part them. It's trying."],
		&"fianna_captain_t3": ["Thumb of All Knowing", "He knows how this ends. He's still going."],
		&"oni_slayer_t3": ["Peach Immortal", "The oni have started telling stories about him."],
		&"sky_lancer_t3": ["He Reached Olympus", "The fall was only ever a rumour."],
	}
	for from in tier4:
		var parent := get_class_def(from)
		var id := StringName(String(from).trim_suffix("_t3") + "_t4")
		_advanced(id, tier4[from][0], tier4[from][1], from, parent.required_stats, parent.threshold, parent.required_route)
		var def := get_class_def(id)
		def.unique_to = parent.unique_to
		if parent.unique_to != &"":
			def.stat_bonus_pct = TIER_STAT_BONUS[4] + DEMIGOD_EDGE


## Quest classes like the Ashbound Knight (Hayden 2026-11-04), one per story
## thread: found through SecretPaths, each with its own 4-tier line. Placeholder names.
func _register_quest_classes() -> void:
	_quest_line(&"inkblade", "Inkblade", "You drew this hero when you were nine. They're faster than you remember.", [Stats.Type.AGILITY, Stats.Type.LUCK],
		&"margin_walker", "Margin Walker", "Lives in the space around the words.", "Author of Monsters", "Everything you ever drew answers when you call.", "Author of Towers", "You wrote this floor. You wrote all of them. Didn't you?")
	_quest_line(&"stairwarden", "Stairwarden", "Marn's trade: hold the door so someone else gets out.", [Stats.Type.HEALTH, Stats.Type.STAMINA],
		&"longwatch", "Longwatch", "Awake when everyone else needs to sleep.", "Keeper of the Ledger", "Writes down everyone. Forgets no one.", "The One Who Stays", "Somebody has to. They decided a long time ago.")
	_quest_line(&"unsworn", "Unsworn", "Refused every god who bid. Now they're all curious, and none of them can touch you.", [Stats.Type.STRENGTH, Stats.Type.LUCK],
		&"heretic_blade", "Heretic Blade", "Cuts what was never meant to bleed.", "Godspurner", "Heaven keeps a list. You're at the top of it.", "Nobody's Champion", "No one lent you this strength. Nobody can take it back.")
	_quest_line(&"glitchwalker", "Glitchwalker", "You found where the tower doesn't quite meet. You can walk through that.", [Stats.Type.INTELLIGENCE, Stats.Type.AGILITY],
		&"seam_runner", "Seam Runner", "Takes corners the walls didn't plan on.", "Exploit", "Finds the thing the tower forgot to check.", "Out of Bounds", "Standing somewhere that was never built.")


func _quest_line(root: StringName, display: String, desc: String, stats: Array, t2: StringName, t2_name: String,
		t2_desc: String, t3_name: String, t3_desc: String, t4_name: String, t4_desc: String) -> void:
	var typed: Array[int] = []
	typed.assign(stats)
	var base := ClassDef.create(root, display, desc, typed, QUEST_CLASS_THRESHOLD)
	base.is_secret = true
	register(base)
	var t3 := StringName(String(root) + "_t3")
	_advanced(t2, t2_name, t2_desc, root, stats, QUEST_CLASS_THRESHOLD)
	_advanced(t3, t3_name, t3_desc, t2, stats, QUEST_CLASS_THRESHOLD)
	_advanced(StringName(String(root) + "_t4"), t4_name, t4_desc, t3, stats, QUEST_CLASS_THRESHOLD)


## The class in `root`'s line at `tier` (or the highest it has). Late finds join
## their new line at the tier you've already earned.
func line_at_tier(root: StringName, tier: int) -> StringName:
	var id := root
	var left := tier - get_class_def(root).tier
	while left > 0:
		var next := advancements_for(id)
		if next.is_empty():
			break
		id = next[0].id
		left -= 1
	return id


## Demigods' own classes (Hayden 2026-10-25): only that demigod can have one
## (unique_to), it's tier-2 strength (+DEMIGOD_EDGE), and it advances to its
## own tier-3 form at the usual gate. Placeholder names.
func _register_demigods() -> void:
	var S := Stats.Type
	var demigods := [
		[&"heracles", &"lionheart", "Lionheart", "The strongest of heroes, son of Zeus.", [S.STRENGTH, S.HEALTH], "Olympian Hero"],
		[&"perseus", &"gorgonbane", "Gorgonbane", "Slayer of the Gorgon, favoured by Athena.", [S.AGILITY, S.STRENGTH], "Starborn Hero"],
		[&"achilles", &"myrmidon_lord", "Myrmidon Lord", "Swift-footed and nearly unkillable.", [S.AGILITY, S.HEALTH], "The Invulnerable"],
		[&"gilgamesh", &"king_of_uruk", "King of Uruk", "Two-thirds divine, one-third legend.", [S.STRENGTH, S.LUCK], "Two-Thirds Divine"],
		[&"cu_chulainn", &"hound_of_ulster", "Hound of Ulster", "The Morrigan's chosen, terrible in battle.", [S.STRENGTH, S.AGILITY], "Riastrad"],
		[&"sigurd", &"dragonslayer", "Dragonslayer", "Of Odin's line, slayer of Fafnir.", [S.STRENGTH, S.STAMINA], "Fafnirsbane"],
		# Added 2026-10-25 (Hayden's picks)
		[&"theseus", &"labyrinth_hero", "Labyrinth Hero", "Slayer of the Minotaur, who found the way out by a thread.", [S.AGILITY, S.STRENGTH], "King of Athens"],
		[&"hippolyta", &"amazon_queen", "Amazon Queen", "Queen of the Amazons, daughter of Ares.", [S.STRENGTH, S.HEALTH], "War-Queen of Themiscyra"],
		[&"orpheus", &"songweaver", "Songweaver", "The bard whose song moved the dead.", [S.INTELLIGENCE, S.LUCK], "Voice of the Underworld"],
		[&"atalanta", &"swift_huntress", "Swift Huntress", "The huntress no one could outrun.", [S.AGILITY, S.LUCK], "Calydonian Huntress"],
		[&"enkidu", &"wild_man", "Wild Man", "Made by the gods to match Gilgamesh, and became his brother.", [S.STRENGTH, S.HEALTH], "Bull-Breaker"],
		[&"fionn", &"fianna_captain", "Fianna Captain", "Leader of the Fianna, who tasted the Salmon of Wisdom.", [S.STRENGTH, S.INTELLIGENCE], "Salmon-Sage"],
		[&"momotaro", &"oni_slayer", "Oni Slayer", "Born from a peach, sent to end the oni.", [S.STRENGTH, S.AGILITY], "Hero of Onigashima"],
		[&"bellerophon", &"sky_lancer", "Sky Lancer", "Rider of Pegasus, slayer of the Chimera.", [S.AGILITY, S.STRENGTH], "Chimera's Bane"],
	]
	for d in demigods:
		var stats: Array[int] = []
		stats.assign(d[4])
		var def := ClassDef.create(d[1], d[2], "" + d[3], stats, 0.4, 2)
		def.is_secret = true
		def.unique_to = d[0]
		def.stat_bonus_pct = TIER_STAT_BONUS[2] + DEMIGOD_EDGE
		register(def)
		_advanced(StringName(String(d[1]) + "_t3"), d[5], "The legend complete.", d[1], d[4], 0.4)
		get_class_def(StringName(String(d[1]) + "_t3")).unique_to = d[0]
		get_class_def(StringName(String(d[1]) + "_t3")).stat_bonus_pct = TIER_STAT_BONUS[3] + DEMIGOD_EDGE


## The tier-2+ bonus for a class's tier.
static func tier_bonus(tier: int) -> float:
	return TIER_STAT_BONUS.get(tier, 0.0)


func _advanced(id: StringName, display: String, desc: String, from: StringName, stats: Array,
		threshold: float, route: StringName = &"") -> void:
	var typed: Array[int] = []
	typed.assign(stats)
	var def := ClassDef.create(id, display, desc, typed, threshold, ClassDef.tier_of_next(get_class_def(from)))
	def.advances_from = from
	def.required_route = route
	def.stat_bonus_pct = tier_bonus(def.tier)
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
	# Added 2026-10-25 (Hayden's picks).
	register(ClassDef.create(&"warrior", "Warrior",
		"A bruiser with a big weapon who hits harder when the fight turns ugly.",
		[Stats.Type.STRENGTH, Stats.Type.HEALTH] as Array[int], 0.60))
	register(ClassDef.create(&"monk", "Monk",
		"An unarmed martial artist: fast, slippery, and full of second winds.",
		[Stats.Type.AGILITY, Stats.Type.STRENGTH] as Array[int], 0.60))
	register(ClassDef.create(&"spellblade", "Spellblade",
		"Sword and sorcery on the attack: elemental strikes that find weaknesses.",
		[Stats.Type.STRENGTH, Stats.Type.INTELLIGENCE] as Array[int], 0.60))
	register(ClassDef.create(&"magic_swordsman", "Magic Swordsman",
		"A defensive duelist who enchants blade and armour, guards and outlasts.",
		[Stats.Type.STRENGTH, Stats.Type.STAMINA] as Array[int], 0.60))
	register(ClassDef.create(&"summoner", "Summoner",
		"Calls spirits and familiars to fight and shield the party.",
		[Stats.Type.INTELLIGENCE, Stats.Type.LUCK] as Array[int], 0.60))


## Secret classes: hidden until their questline is complete (SecretPaths).
func _register_secret() -> void:
	var ash := ClassDef.create(&"ashbound_knight", "Ashbound Knight",
		"A blade that remembers fire. Strikes with steel and cinders alike.",
		[Stats.Type.STRENGTH, Stats.Type.INTELLIGENCE] as Array[int], 0.55)
	ash.is_secret = true
	register(ash)
	# Its own line (Hayden 2026-10-25), so taking it isn't a step down. Placeholder names.
	_advanced(&"cinderbrand", "Cinderbrand Knight", "The ashes answer the blade.", &"ashbound_knight",
		[Stats.Type.STRENGTH, Stats.Type.INTELLIGENCE], 0.55)
	_advanced(&"cinderbrand_t3", "Wyrmflame Knight", "The wyrm's fire, bound to a knight.", &"cinderbrand",
		[Stats.Type.STRENGTH, Stats.Type.INTELLIGENCE], 0.55)

	# New Game+ only: deliberately stronger than anything in a first run.
	# Always ASCENDANT_EDGE above the best tier's bonus, no stat requirement,
	# and new skills as each advancement gate opens (SkillLibrary.ASCENDANT_GATE_SKILLS).
	var asc := ClassDef.create(&"ascendant", "Ascendant",
		"One who has already conquered the tower and climbs it again. Stronger than any other class.",
		[] as Array[int], 0.0)
	asc.is_secret = true
	asc.ng_plus_only = true
	asc.stat_bonus_pct = best_tier_bonus() + ASCENDANT_EDGE
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
