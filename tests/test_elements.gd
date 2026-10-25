extends Node
## Elements, weaknesses, families, traits, stagger, bestiary, Scouting Lens,
## elemental weapons and per-run stage themes.
## Run:  godot --headless res://tests/test_elements.tscn
## Uses separate test save files, so your real save is never touched.

const E := Element.Type
const A := Element.Affinity

var _passed := 0
var _failed := 0


func _ready() -> void:
	GameState.save_dir = "user://test_saves_elements"
	GameState.unlocks_path = "user://test_saves_elements_unlocks.json"
	test_resolve()
	test_data_is_consistent()
	test_attack_elements()
	test_damage_multipliers()
	test_traits()
	test_stagger()
	test_weak_hits_in_battle()
	test_easily_distracted()
	test_bestiary()
	test_scouting_lens()
	test_elemental_weapons()
	test_stage_themes()
	test_save_roundtrip()
	GameState.delete_slot(1)
	GameState.reset_run()
	print("\n==== %d passed, %d failed ====" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)


func check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  ", label)
	else:
		_failed += 1
		printerr("  FAIL  ", label)


func _enemy(id: StringName) -> Combatant:
	return Combatant.from_enemy(EnemyLibrary.get_enemy(id))


func _mage() -> CharacterData:
	var c := GameState.make_premade("Mira", &"mage", {Stats.Type.INTELLIGENCE: 20, Stats.Type.AGILITY: 15})
	c.learn_skill(&"ember")
	c.learn_skill(&"gust")
	return c


func _roll(attacker: Combatant, target: Combatant, skill_id: StringName, seed_value: int = 7) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return DamageCalc.roll_damage(attacker, target, SkillLibrary.get_skill(skill_id), rng)


func _party(members: Array) -> Array[CharacterData]:
	var out: Array[CharacterData] = []
	out.assign(members)
	return out


## Plays AI turns until it's a party member's turn (or the fight ends).
func _to_player_turn(b: BattleManager) -> void:
	var guard := 0
	while not b.is_over() and not b.is_player_turn() and guard < 200:
		b.advance()
		guard += 1


func test_resolve() -> void:
	var r := Element.resolve([E.FIRE], { E.FIRE: A.WEAK })
	check(r.weak and is_equal_approx(r.mult, 1.5), "weak: x1.5")
	r = Element.resolve([E.SLASH], { E.SLASH: A.RESIST })
	check(r.resisted and not r.weak and is_equal_approx(r.mult, 0.5), "resist: x0.5")
	r = Element.resolve([E.FIRE, E.SLASH], { E.FIRE: A.WEAK, E.SLASH: A.RESIST })
	check(r.weak and is_equal_approx(r.mult, 0.75), "weak + resist multiply (x0.75), still counts as a weakness hit")
	r = Element.resolve([E.DARK, E.HOLY], { E.DARK: A.IMMUNE, E.HOLY: A.WEAK })
	check(r.immune and not r.weak and r.mult == 0.0, "immune beats weak: no damage, no stagger")
	r = Element.resolve([E.FIRE, E.ICE], { E.FIRE: A.ABSORB, E.ICE: A.WEAK })
	check(r.absorbed and not r.immune and not r.weak, "absorb wins over everything")
	r = Element.resolve([], { E.FIRE: A.WEAK })
	check(is_equal_approx(r.mult, 1.0) and r.hit.is_empty(), "no elements = plain hit, nothing learned")
	check(Element.resolve([E.ICE], {}).hit == { E.ICE: A.NORMAL }, "a normal reaction is still learned")


func test_data_is_consistent() -> void:
	var fams_ok := true
	for id in ["slime", "goblin", "goblin_archer", "orc_brute", "imp_shaman", "goblin_king", "king_slime",
			"bubble_slime", "mud_slime", "big_slime", "mire_slime", "orc_warlord", "labyrinth_minotaur",
			"lantern_wraith", "ashen_wyrmling"]:
		var def := EnemyLibrary.get_enemy(StringName(id))
		if not EnemyFamilies.FAMILIES.has(def.family):
			fams_ok = false
			printerr("    no family: ", id)
	check(fams_ok, "every enemy belongs to a real family")
	var traits_ok := true
	for f in EnemyFamilies.FAMILIES.values():
		for t in f.traits:
			if not EnemyFamilies.TRAITS.has(t):
				traits_ok = false
	check(traits_ok, "every family trait is defined")
	# Every magic element has at least one skill a player can learn or use.
	var covered := {}
	for s in SkillLibrary.learnable_skills():
		for e in s.elements:
			covered[e] = true
	var missing := Element.MAGIC_ELEMENTS.filter(func(e): return not covered.has(e))
	check(missing.is_empty(), "every element has a learnable skill (missing: %s)" % Element.list_text(missing))
	check(SkillLibrary.pick_pool().any(func(s): return s.elements.has(E.FIRE)) and
		SkillLibrary.pick_pool().any(func(s): return s.elements.has(E.WIND)),
		"Fire and Wind are available as level-up picks (slimes can be answered early)")
	var slime := EnemyLibrary.get_enemy(&"slime")
	check(EnemyFamilies.affinities_for(slime)[E.FIRE] == A.WEAK, "slimes are weak to Fire")
	var mud := EnemyLibrary.get_enemy(&"mud_slime")
	check(EnemyFamilies.affinities_for(mud).get(E.WATER) == A.NORMAL and EnemyFamilies.affinities_for(mud)[E.FIRE] == A.WEAK,
		"per-enemy overrides on top of the family (Mud Slime doesn't mind water)")
	check(EnemyFamilies.affinities_for(EnemyLibrary.get_enemy(&"ashen_wyrmling"))[E.FIRE] == A.ABSORB, "wyrms absorb Fire")
	check(EnemyFamilies.affinities_for(EnemyLibrary.get_enemy(&"lantern_wraith"))[E.DARK] == A.IMMUNE, "wraiths are immune to Dark")
	check(EnemyFamilies.affinities_for(EnemyLibrary.get_enemy(&"king_slime")) == EnemyFamilies.affinities_for(slime),
		"King Slime shares the slime family's weaknesses (scouting pays off)")


func test_attack_elements() -> void:
	var c := CharacterData.new()
	var u := Combatant.from_character(c)
	var basic := u.basic_attack
	check(DamageCalc.attack_elements(u, basic) == [E.BLUNT], "no weapon: fists are Blunt")
	var sword := LootTable.make_gear(&"sword", Rarity.Tier.COMMON, 1, RandomNumberGenerator.new())
	sword.element = -1
	c.equip(sword)
	u = Combatant.from_character(c)
	check(DamageCalc.attack_elements(u, u.basic_attack) == [E.SLASH], "a sword makes physical attacks Slash")
	check(DamageCalc.attack_elements(u, SkillLibrary.get_skill(&"backstab")) == [E.PIERCE], "a skill's own kind wins (Backstab is Pierce)")
	check(DamageCalc.attack_elements(u, SkillLibrary.get_skill(&"ember")) == [E.FIRE], "magic doesn't pick up the weapon kind")
	sword.element = E.ICE
	u = Combatant.from_character(c)
	check(DamageCalc.attack_elements(u, u.basic_attack) == [E.SLASH, E.ICE], "an elemental weapon adds its element to basic attacks")
	check(DamageCalc.attack_elements(u, SkillLibrary.get_skill(&"power_strike")) == [E.SLASH], "...but not to skills")
	check(SkillLibrary.get_skill(&"meteor").elements == [E.FIRE, E.EARTH], "skills can carry two elements (Meteor = Fire + Earth)")


func test_damage_multipliers() -> void:
	var mage := Combatant.from_character(_mage())
	var target := _enemy(&"goblin")   # goblins: only weak to Pierce
	var base: int = _roll(mage, target, &"ember").amount
	target.affinities = { E.FIRE: A.WEAK }
	var weak: int = _roll(mage, target, &"ember").amount
	check(absi(weak - roundi(base * 1.5)) <= 1, "weakness: x1.5 (%d -> %d)" % [base, weak])
	target.affinities = { E.FIRE: A.RESIST }
	var res: int = _roll(mage, target, &"ember").amount
	check(absi(res - roundi(base * 0.5)) <= 1, "resistance: x0.5 (%d)" % res)
	target.affinities = { E.FIRE: A.IMMUNE }
	var imm := _roll(mage, target, &"ember")
	check(imm.immune and imm.amount == 0, "immune: no damage")
	target.affinities = { E.FIRE: A.ABSORB }
	var ab := _roll(mage, target, &"ember")
	check(ab.absorbed and absi(ab.amount - base) <= 1, "absorb: heals by what it would have taken")


func test_traits() -> void:
	var fists := Combatant.from_character(GameState.make_premade("Bo", &"tank",
		{Stats.Type.HEALTH: 12, Stats.Type.STAMINA: 12, Stats.Type.STRENGTH: 11}))
	var slime := _enemy(&"slime")
	slime.gel_used = true
	var plain: int = _roll(fists, slime, &"attack_melee").amount
	slime.gel_used = false
	var soft: int = _roll(fists, slime, &"attack_melee").amount
	check(absi(soft - roundi(plain * 0.5)) <= 1 and slime.gel_used, "Gelatinous: first physical hit each round is halved (%d vs %d)" % [soft, plain])
	slime.gel_used = false
	_roll(Combatant.from_character(_mage()), slime, &"ember")
	check(not slime.gel_used, "Gelatinous doesn't soften magic")

	var bull := _enemy(&"labyrinth_minotaur")
	var victim := Combatant.from_character(CharacterData.new())
	victim.affinities = {}
	var healthy: int = _roll(bull, victim, &"attack_melee").amount
	bull.hp = bull.max_hp / 3
	var angry: int = _roll(bull, victim, &"attack_melee").amount
	check(absi(angry - roundi(healthy * EnemyFamilies.RECKLESS_MULT)) <= 1, "Reckless: hits harder below half HP (%d -> %d)" % [healthy, angry])


func test_stagger() -> void:
	var g := _enemy(&"goblin")
	check(g.stagger_max == 2, "normal enemies stagger after 2 weakness hits")
	check(not g.add_stagger() and g.add_stagger() and g.staggered, "2nd weakness hit staggers")
	check(g.stagger == 0 and g.stagger_max == 3, "meter resets and the next stagger takes one more hit")
	check(not g.add_stagger(), "can't add to the meter while already staggered")
	check(_enemy(&"goblin_king").stagger_max == 4, "bosses take 4")
	check(_enemy(&"orc_brute").stagger_max == 3, "Thick-skulled orcs take 1 more")
	check(_enemy(&"orc_warlord").stagger_max == 5, "...bosses too (orc boss: 5)")

	# A staggered enemy loses its next turn.
	var b := BattleManager.new()
	b.setup(_party([_mage()]), EnemyLibrary.build_group([&"king_slime"]), 3)
	var king: Combatant = b.enemies[0]
	king.staggered = true
	var acted_round1 := false
	var log := []
	b.turn_started.connect(func(u): if u == king and b.round_number == 1: acted_round1 = true)
	b.action_resolved.connect(func(r): log.append(r.text))
	b.start()
	var guard := 0
	while not b.is_over() and b.round_number < 2 and guard < 50:
		if b.is_player_turn():
			b.submit(BattleAction.simple(BattleAction.Type.DEFEND, b.current))
		else:
			b.advance()
		guard += 1
	check(not acted_round1 and not king.staggered, "staggered: skips its turn, then recovers")
	check(log.any(func(t): return t.contains("loses its turn")), "the log says so")


func test_weak_hits_in_battle() -> void:
	GameState.reset_run()
	var b := BattleManager.new()
	b.bestiary = GameState.bestiary
	b.setup(_party([_mage()]), EnemyLibrary.build_group([&"king_slime"]), 11)
	check(GameState.bestiary.has_seen(&"king_slime"), "fighting an enemy adds it to the bestiary")
	b.party[0].max_hp = 99999   # a lone mage wouldn't survive King Slime long enough
	b.party[0].hp = 99999
	b.start()
	var king: Combatant = b.enemies[0]
	var results := []
	b.action_resolved.connect(func(r): results.append(r))
	_to_player_turn(b)
	b.submit(BattleAction.use_skill(b.current, SkillLibrary.get_skill(&"ember"), king))
	var hit: Dictionary = results.filter(func(r): return r.actor.side == Combatant.Side.PARTY)[0].entries[0]
	check(hit.weak and king.stagger == 1, "Ember on a slime: WEAK, stagger 1/4")
	check(GameState.bestiary.known_affinities(king.source_enemy).get(E.FIRE) == A.WEAK, "the bestiary learns it")
	check(GameState.bestiary.known_affinities(EnemyLibrary.get_enemy(&"slime")).get(E.FIRE) == A.WEAK,
		"...and so does every slime (family knowledge)")
	check(not GameState.bestiary.known_affinities(EnemyLibrary.get_enemy(&"mud_slime")).has(E.WATER),
		"family knowledge skips elements an enemy overrides")
	for i in 3:
		_to_player_turn(b)
		if b.is_over():
			break
		b.submit(BattleAction.use_skill(b.current, SkillLibrary.get_skill(&"gust"), king))
	check(results.any(func(r): return r.entries.any(func(e): return e.get("staggered", false))),
		"4 weakness hits stagger the boss")


func test_easily_distracted() -> void:
	var tank := GameState.make_premade("Bo", &"tank", {Stats.Type.HEALTH: 12, Stats.Type.STAMINA: 12, Stats.Type.STRENGTH: 11})
	var mage := _mage()
	mage.battle_row = Combatant.Row.FRONT   # reachable by the goblin's melee
	var b := BattleManager.new()
	b.setup(_party([tank, mage]), EnemyLibrary.build_group([&"goblin"]), 5)
	b.party[0].max_hp = 99999
	b.party[0].hp = 99999
	b.party[1].max_hp = 99999
	b.party[1].hp = 99999
	b.start()
	var guard := 0
	while not (b.is_player_turn() and b.current.source_character == tank) and guard < 50:
		if b.is_player_turn():
			b.submit(BattleAction.simple(BattleAction.Type.DEFEND, b.current))
		else:
			b.advance()
		guard += 1
	b.submit(BattleAction.use_skill(b.current, SkillLibrary.get_skill(&"taunt")))
	check(b.party[0].statuses.get(&"taunt", 0) == 3, "Taunt lasts 1 turn longer against goblins (3)")
	var gob: Combatant = b.enemies[0]
	gob.last_attacker = b.party[1]
	b.party[0].statuses.erase(&"taunt")
	var all_on_target := true
	for s in 30:
		b.rng.seed = s
		var a := BattleAI.choose(b, gob)
		if a.target != b.party[1]:
			all_on_target = false
	check(all_on_target, "an easily distracted goblin goes after whoever hit it last")


func test_bestiary() -> void:
	var bst := Bestiary.new()
	var wraith := EnemyLibrary.get_enemy(&"lantern_wraith")
	bst.record_seen(wraith)
	check(bst.summary(wraith) == "" and not bst.knows_details(&"lantern_wraith"), "new entry: nothing known yet")
	bst.record_affinity(wraith, E.HOLY, A.WEAK)
	check(bst.summary(wraith) == "Weak: Holy", "summary lists what's known")
	bst.record_defeat(wraith)
	check(bst.knows_details(&"lantern_wraith"), "traits and lore unlock after a win")
	var wyrm := EnemyLibrary.get_enemy(&"ashen_wyrmling")
	bst.scan(wyrm)
	check(bst.known_affinities(wyrm).size() == Element.Type.size() and bst.knows_details(&"ashen_wyrmling"),
		"a scan reveals every element and the traits")
	check(bst.summary(wyrm).contains("Absorbs: Fire"), "scan summary: %s" % bst.summary(wyrm))
	var copy := Bestiary.from_dict(JSON.parse_string(JSON.stringify(bst.to_dict())))
	check(copy.summary(wyrm) == bst.summary(wyrm) and copy.entries[&"lantern_wraith"].defeated == 1, "bestiary survives JSON")
	var bad := { "entries": { "not_an_enemy": { "defeated": 3 }, "slime": { "defeated": 2, "known": { "99": 1, "3": 77, "4": 1 } } },
		"families": { "fake": {}, "slime": { "3": 1 } } }
	var clean := Bestiary.from_dict(bad)
	check(not clean.entries.has(&"not_an_enemy") and clean.entries[&"slime"].known == { 4: 1 }
		and not clean.family_known.has(&"fake"), "tampered bestiary: unknown enemies/elements/affinities dropped")


func test_scouting_lens() -> void:
	GameState.reset_run()
	GameState.player.gold = 5000
	var spent := 0
	for i in 3:
		spent += GameState.shop_price(ItemLibrary.get_item(&"scouting_lens"))   # rises a little each buy (demand)
		GameState.buy_item(&"scouting_lens")
	check(GameState.inventory.count(&"scouting_lens") == 3 and spent >= 600, "buy Scouting Lenses (200g base, %d spent)" % spent)
	check(not GameState.buy_item(&"scouting_lens") and GameState.player.gold == 5000 - spent, "can't carry more than 3")
	check(GameState.inventory.add(&"scouting_lens", 2) == 0, "drops past the limit are refused too")
	var b := BattleManager.new()
	b.inventory = GameState.inventory
	b.bestiary = GameState.bestiary
	b.setup(_party([_mage()]), EnemyLibrary.build_group([&"orc_brute"]), 2)
	b.start()
	_to_player_turn(b)
	var lens := ItemLibrary.get_item(&"scouting_lens")
	check(not b.submit(BattleAction.use_item(b.current, lens, b.current)), "a lens can't be used on an ally")
	var texts := []
	b.action_resolved.connect(func(r): texts.append(r.text))
	check(b.submit(BattleAction.use_item(b.current, lens, b.enemies[0])), "use a lens on an enemy")
	check(GameState.inventory.count(&"scouting_lens") == 2, "it's used up")
	check(GameState.bestiary.knows_details(&"orc_brute") and texts[0].contains("Weak: Pierce, Ice")
		and texts[0].contains("Thick-skulled"), "reveals weaknesses and traits: %s" % texts[0])


func test_elemental_weapons() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var elemental := 0
	var named_ok := true
	for i in 400:
		var g := LootTable.make_gear(&"sword", Rarity.Tier.EPIC, 5, rng)
		if g.element >= 0:
			elemental += 1
			if not g.display_name.begins_with(Element.adjective_of(g.element)):
				named_ok = false
	check(elemental > 100 and elemental < 180, "about 35%% of Epic weapons are elemental (%d / 400)" % elemental)
	check(named_ok, "elemental weapons are named for it (\"Flame Runed Sword\")")
	var none := true
	for i in 200:
		if LootTable.make_gear(&"sword", Rarity.Tier.COMMON, 5, rng).element >= 0 \
				or LootTable.make_gear(&"plate", Rarity.Tier.LEGENDARY, 5, rng).element >= 0:
			none = false
	check(none, "Common weapons and armour never roll an element")
	var g := LootTable.make_gear(&"bow", Rarity.Tier.RARE, 3, rng)
	g.element = E.WIND
	var back := SaveSerializer.gear_from_dict(JSON.parse_string(JSON.stringify(SaveSerializer.gear_to_dict(g))))
	check(back.element == E.WIND and back.summary().contains("Pierce + Wind"), "element saved; summary: %s" % back.summary())
	var armor := SaveSerializer.gear_to_dict(LootTable.make_gear(&"plate", Rarity.Tier.RARE, 3, rng))
	armor.element = E.FIRE
	check(SaveSerializer.gear_from_dict(armor).element == -1, "tampered save: armour can't carry an element")


func test_stage_themes() -> void:
	var seen := {}
	for s in 40:
		var rng := RandomNumberGenerator.new()
		rng.seed = s
		seen[StageLibrary.roll_themes(rng)[0]] = true
	check(seen.has(&"goblin_warrens") and seen.has(&"slime_pits"), "floors 1-10 roll Goblin Warrens or Slime Pits")
	check(StageLibrary.validate_themes(["nonsense", 5]) == [&"goblin_warrens", &"orc_stronghold", &"insect_hive", &"elemental_rift", &"demon_gate", &"celestial_spire"],
		"bad picks fall back to defaults (and the pseudo-god slots never repeat)")

	GameState.reset_run()
	GameState.stage_themes = [&"slime_pits", &"orc_stronghold"]
	check(StageLibrary.stage_name(4) == "Stage 1: Slime Pits", "the run's pick is used")
	check(StageLibrary.miniboss_for_floor(4)[0] == &"big_slime" and StageLibrary.miniboss_for_floor(9)[0] == &"mire_slime",
		"slime minibosses on 4 and 9")
	check(StageLibrary.boss_for_floor(10)[0] == &"king_slime" and StageLibrary.boss_for_floor(70)[0] == &"king_slime",
		"King Slime on floor 10 (and when the stages repeat)")
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var all_slimes := true
	for i in 60:
		for id in EnemyLibrary.encounter_for_floor(6, rng):
			if EnemyLibrary.get_enemy(id).family != &"slime":
				all_slimes = false
	check(all_slimes, "Slime Pits floors are full of slimes")
	GameState.floor_number = 5
	var r := DialogueRunner.new()
	r.start(&"merchant")
	r.choose(2)
	check(r.text().contains("Slimes hate an open flame"), "the merchant's advice matches the stage ahead")
	GameState.floor_number = 10
	r.start(&"merchant")
	r.choose(2)
	check(r.text().contains("Orc hide"), "after the boss, advice is about the next stage")
	GameState.stage_themes = []
	check(StageLibrary.boss_for_floor(10)[0] == &"goblin_king", "no pick = the slot's first theme")


func test_save_roundtrip() -> void:
	GameState.start_new_game("Ophelius", "Cassia", 1)
	GameState.stage_themes = [&"slime_pits", &"orc_stronghold"]
	GameState.bestiary.scan(EnemyLibrary.get_enemy(&"slime"))
	GameState.save_game()
	GameState.reset_run()
	check(GameState.load_game(1), "load")
	check(GameState.stage_themes.slice(0, 2) == [&"slime_pits", &"orc_stronghold"] and StageLibrary.boss_for_floor(10)[0] == &"king_slime",
		"stage themes are saved with the run")
	check(GameState.bestiary.knows_details(&"slime") and GameState.bestiary.summary(EnemyLibrary.get_enemy(&"slime")).contains("Weak: Fire"),
		"bestiary is saved with the run")
	var d := SaveSerializer.read_json(GameState.slot_path(1))
	d.erase("stage_themes")
	SaveSerializer.write_json(GameState.slot_path(1), d)
	GameState.load_game(1)
	check(StageLibrary.boss_for_floor(10)[0] == &"goblin_king", "older saves (no themes) keep the original stages")
