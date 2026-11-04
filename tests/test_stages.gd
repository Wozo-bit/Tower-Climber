extends Node
## Stage themes and the 100-floor climb: every theme's data, the slot ladder
## (the pseudo-god slots never repeat a theme), boss patrons (blessed bosses,
## the sensitivity rule, interest shifts), the new traits (swarming, undying,
## dragonscale) and the bosses' signature skill books.
## Run:  godot --headless res://tests/test_stages.tscn

var _passed := 0
var _failed := 0


func _ready() -> void:
	GameState.save_dir = "user://test_saves_stages"
	GameState.legacy_path = "user://test_saves_stages_hall.json"
	GameState.unlocks_path = "user://test_saves_stages_unlocks.json"
	Tips.path = "user://test_saves_stages_tips.json"
	Settings.path = "user://test_saves_stages_settings.cfg"
	test_theme_data()
	test_slots()
	test_last_floors()
	test_boss_patrons()
	test_traits()
	test_signature_books()
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


func test_theme_data() -> void:
	print("Theme data")
	var problems: PackedStringArray = []
	for id in StageLibrary.THEMES:
		var t: Dictionary = StageLibrary.THEMES[id]
		if not EnemyFamilies.FAMILIES.has(t.get("family", &"")):
			problems.append("%s: unknown family" % id)
		if str(t.get("hint", "")) == "" or str(t.get("name", "")) == "":
			problems.append("%s: needs a name and a hint" % id)
		var groups: Array = t.get("encounters", []) + t.get("early_encounters", [])
		for floor_in in t.get("miniboss_floors", {}):
			var g: Array = t.miniboss_floors[floor_in]
			groups.append(g)
			if not EnemyLibrary.get_enemy(g[0]).is_miniboss:
				problems.append("%s: %s isn't flagged as a miniboss" % [id, g[0]])
		groups.append(t.get("boss", []))
		if not EnemyLibrary.get_enemy(t.boss[0]).is_boss:
			problems.append("%s: %s isn't flagged as a boss" % [id, t.boss[0]])
		for g in groups:
			if g.is_empty():
				problems.append("%s: an empty group" % id)
			for e in g:
				if EnemyLibrary.get_enemy_or_null(e) == null:
					problems.append("%s: unknown enemy %s" % [id, e])
	check(problems.is_empty(), "every theme's enemies, minibosses and boss exist %s" % [problems])
	var bad_traits := []
	for d in EnemyLibrary.all():
		if not EnemyFamilies.FAMILIES.has(d.family):
			bad_traits.append(d.id)
		for tr in EnemyFamilies.traits_for(d):
			if not EnemyFamilies.TRAITS.has(tr):
				bad_traits.append(tr)
	check(bad_traits.is_empty(), "every enemy has a known family and traits %s" % [bad_traits])
	var all_themes := []
	for slot in StageLibrary.STAGE_SLOTS:
		all_themes.append_array(slot.themes)
	check([&"bandit_fortress", &"insect_hive", &"beast_den", &"elemental_rift", &"undead_crypt", &"demon_gate",
		&"celestial_spire", &"dragon_roost"].all(func(t): return all_themes.has(t)), "all 8 new themes are in the climb")


func test_slots() -> void:
	print("The climb")
	check(StageLibrary.STAGE_SLOTS.size() * StageLibrary.FLOORS_PER_STAGE == GameState.FINAL_FLOOR and GameState.FINAL_FLOOR == 100,
		"ten stages, final boss on floor 100")
	var ladder := [[&"goblin_warrens", &"slime_pits"], [&"orc_stronghold", &"bandit_fortress"], [&"insect_hive", &"beast_den"],
		[&"elemental_rift", &"undead_crypt"]]
	var in_order := true
	for i in ladder.size():
		in_order = in_order and StageLibrary.STAGE_SLOTS[i].themes == ladder[i]
	check(in_order, "Slimes/Goblins -> Bandits/Orcs -> Insects/Beasts -> Elemental Rift/Undead")
	var repeats := 0
	var seen5 := {}
	var seen6 := {}
	for s in 300:
		var rng := RandomNumberGenerator.new()
		rng.seed = s
		var picks := StageLibrary.roll_themes(rng)
		if picks[4] == picks[5]:
			repeats += 1
		seen5[picks[4]] = true
		seen6[picks[5]] = true
	check(repeats == 0, "floors 41-50 and 51-60 never get the same pseudo-god theme")
	check(seen5.size() == 3 and seen6.size() == 3, "Demons, Angels and Dragons can each land on either")
	check(StageLibrary.validate_themes([&"goblin_warrens", &"orc_stronghold", &"insect_hive", &"elemental_rift",
		&"dragon_roost", &"dragon_roost"])[5] != &"dragon_roost", "a tampered save can't repeat a pseudo-god theme")
	GameState.reset_run()
	GameState.stage_themes = [&"slime_pits", &"bandit_fortress", &"beast_den", &"undead_crypt", &"dragon_roost", &"demon_gate"]
	check(StageLibrary.stage_name(15) == "Stage 2: Bandit Fortress" and StageLibrary.boss_for_floor(40)[0] == &"necromancer"
		and StageLibrary.boss_for_floor(50)[0] == &"dragon_sovereign" and StageLibrary.boss_for_floor(60)[0] == &"archfiend",
		"the run's picks decide each stage")


func test_last_floors() -> void:
	print("Floors 61-100")
	GameState.reset_run()
	check(StageLibrary.stage_name(65) == "Stage 7: Titanfall" and StageLibrary.boss_for_floor(70)[0] == &"cronus", "61-70: titans")
	check(StageLibrary.stage_name(75) == "Stage 8: The Gods' Host" and StageLibrary.boss_for_floor(80)[0] == &"anointed_champion", "71-80: the gods' soldiers")
	check(StageLibrary.stage_name(85) == "Stage 9: The Unfinished" and StageLibrary.boss_for_floor(90)[0] == &"first_draft", "81-90: the game breaks")
	check(StageLibrary.stage_name(95) == "Stage 10: Echoes" and StageLibrary.boss_for_floor(100)[0] == &"tester_0041", "91-100: past Testers")
	# Soldiers, never gods; bosses' patrons are never living-religion figures.
	for id in [&"cronus", &"anointed_champion"]:
		var pat: StringName = EnemyLibrary.get_enemy(id).patron
		check(not BeingLibrary.get_being(pat).get("living", false), "%s's patron is allowed" % id)
	var named := EnemyLibrary.all().filter(func(d): return BeingLibrary.beings.has(d.id))
	check(named.is_empty(), "no enemy is a being from the roster (%s)" % [named.map(func(d): return d.id)])
	# False summit: floor 60 no longer ends the run.
	GameState.start_new_game("Summit", "Rowan", 1)
	GameState.enter_floor(60)
	GameState.current_layout()
	check(not GameState.pending_completion, "not finished yet")
	for i in GameState.floor_enemies.size():
		if GameState.enemy_kind(GameState.floor_enemies[i]) == "boss":
			GameState.active_enemy_index = i
	GameState.pending_encounter = []
	GameState.finish_battle(BattleManager.Outcome.VICTORY)
	check(not GameState.pending_completion, "floor 60's boss doesn't end the climb")
	check(StoryLibrary.due(60, true) == &"summit_false", "it reveals the false summit")
	GameState.enter_floor(100)
	GameState.current_layout()
	for i in GameState.floor_enemies.size():
		if GameState.enemy_kind(GameState.floor_enemies[i]) == "boss":
			GameState.active_enemy_index = i
			check(GameState.floor_enemies[i].group[0] == &"tester_0041", "floor 100: Tester 0041")
	GameState.pending_encounter = []
	GameState.finish_battle(BattleManager.Outcome.VICTORY)
	check(GameState.pending_completion, "floor 100's boss ends it")
	GameState.pending_completion = false
	check(GameState.party_size_at(100) == GameState.MAX_PARTY_SIZE, "a full party of ten")
	# Bosses at the top run all three mechanics.
	GameState.floor_number = 95
	GameState.pending_battle_info = { "kind": "boss" }
	var cfg := BattleManager.new()
	GameState.configure_battle(cfg)
	check(cfg.boss_tier == 3, "floor 90+ bosses: every mechanic")
	GameState.pending_battle_info = {}
	# Glitched: new weaknesses every fight.
	var chars: Array[CharacterData] = [GameState.player]
	var seen := {}
	for s in 40:
		var b := BattleManager.new()
		var defs: Array[EnemyDef] = [EnemyLibrary.get_enemy(&"placeholder_knight")]
		b.setup(chars, defs, s)
		var a: Dictionary = b.enemies[0].affinities
		check(a.size() == 2 and a.values().has(Element.Affinity.WEAK) and a.values().has(Element.Affinity.RESIST), "one weak, one resist") if a.size() != 2 else null
		seen[str(a)] = true
	check(seen.size() > 5, "weaknesses differ between fights (%d)" % seen.size())
	# Echoing: copies a party member's damage skills.
	var p := GameState.make_premade("Copied", &"mage", { Stats.Type.INTELLIGENCE: 20 })
	var echo_party: Array[CharacterData] = [p]
	var eb := BattleManager.new()
	var echo_defs: Array[EnemyDef] = [EnemyLibrary.get_enemy(&"tester_echo_bow")]
	eb.setup(echo_party, echo_defs, 3)
	var copied := eb.enemies[0].skills.filter(func(s): return p.all_skills().any(func(o): return o.id == s.id))
	check(not copied.is_empty(), "an echo fights with your skills (%s)" % [copied.map(func(s): return s.id)])
	check(eb.enemies[0].skills.all(func(s): return s.effect == SkillDef.Effect.DAMAGE), "only damage skills")
	check(eb.enemies[0].can_afford(copied[0]), "and it can pay for them")
	var turns := 0
	eb.start()
	while not eb.is_over() and turns < 30:
		turns += 1
		if eb.current == null:
			break
		if eb.current.ai_controlled:
			eb.advance()
		else:
			eb.submit(BattleAI.choose(eb, eb.current))
	check(turns > 0, "an echo fight plays")
	test_mimics()


func test_mimics() -> void:
	print("New Game+'s final boss")
	GameState.start_new_game("Ronald", "Rowan", 1)
	var p := GameState.player
	while p.level < 60:
		p.level_up()
	p.apply_allocation({ Stats.Type.INTELLIGENCE: p.unspent_points })
	p.choose_class(ClassRegistry.get_class_def(&"mage"))
	GameState.companions[0].level_up()
	var rec := GameState.record_completion()
	check(rec.party.size() == GameState.companions.size(), "the Hall records who stood beside you")
	# It survives saving.
	var book := GameState.load_legacy()
	check(book.find(rec.legacy_id).party.size() == 1 and book.find(rec.legacy_id).party[0].character_name == "Rowan", "and saves them")
	var snapshot := p.stats.get_total(Stats.Type.INTELLIGENCE)
	GameState.start_new_game_plus(book.find(rec.legacy_id), 1)
	check(GameState.boss_group(100).size() == 2, "you and your old friend (%s)" % [GameState.boss_group(100)])
	check(GameState.boss_group(60) == StageLibrary.boss_for_floor(60), "only the last floor")
	var leader := EnemyLibrary.get_enemy(GameState.boss_group(100)[0])
	check(leader.display_name == "Ronald's Echo" and leader.is_boss, "it has your name")
	check(not leader.skills.is_empty() and leader.skills.has(&"fireball"), "and your skills (%s)" % [leader.skills])
	check(not EnemyLibrary.get_enemy(GameState.boss_group(100)[1]).is_boss, "the party are its escorts")
	GameState.enter_floor(100)
	GameState.current_layout()
	var boss_i := -1
	for i in GameState.floor_enemies.size():
		if GameState.enemy_kind(GameState.floor_enemies[i]) == "boss":
			boss_i = i
	check(GameState.floor_enemies[boss_i].group[0] == leader.id, "floor 100 uses them")
	GameState.prepare_floor_battle(boss_i)
	var b := BattleManager.new()
	GameState.configure_battle(b)
	var fighters := GameState.fighting_party()
	b.setup(fighters, GameState.pending_encounter, 1)
	var u: Combatant = b.enemies[0]
	var mult := GameState.ng_plus_scale(GameState.ng_plus_cycle) * Difficulty.value(GameState.difficulty, "enemy")
	check(absf(u.stats.get_total(Stats.Type.INTELLIGENCE) - snapshot * mult) <= maxf(3.0, snapshot * 0.05),
		"as strong as you were, plus New Game+ (%d vs %d x %.2f)" % [u.stats.get_total(Stats.Type.INTELLIGENCE), snapshot, mult])
	check(absf(u.max_hp - rec.character.max_hp() * GameState.MIMIC_LEADER_HP * mult) < rec.character.max_hp() * GameState.MIMIC_LEADER_HP * mult * 0.1,
		"with plenty of HP (%d)" % u.max_hp)
	check(StoryLibrary.due(100, false) == &"final_mimic" or GameState.divinity.active, "it greets you")
	# Reloading keeps the fight.
	GameState.pending_battle_info = {}
	GameState.save_game()
	GameState.load_game(1)
	check(GameState.floor_enemies.any(func(e): return e.group.has(leader.id)), "a reload keeps the mimics")
	# First runs never meet them.
	GameState.start_new_game("Fresh", "Rowan", 1)
	check(GameState.boss_group(100)[0] == &"tester_0041", "a first run: Tester 0041")
	GameState.delete_slot(1)
	SaveSerializer.delete_file(GameState.legacy_path)


func test_boss_patrons() -> void:
	print("Boss patrons")
	var bad := []
	for d in EnemyLibrary.all():
		if d.patron == &"":
			continue
		var b := BeingLibrary.get_being(d.patron)
		if b.is_empty() or b.get("living", false):
			bad.append(d.id)   # sensitivity rule: living-religion figures never sponsor enemies
	check(bad.is_empty(), "boss patrons exist and are never figures from living religions %s" % [bad])
	check(EnemyLibrary.get_enemy(&"necromancer").patron == &"hades", "the Necromancer answers to Hades")
	var plain := Combatant.from_enemy(EnemyLibrary.get_enemy(&"bandit_cutthroat"))
	var boss := Combatant.from_enemy(EnemyLibrary.get_enemy(&"necromancer"))
	var blessed_skill: StringName = BeingLibrary.get_being(&"hades").skill
	# Hades' blessing: +Dark power (level 2), and his Bident.
	check(boss.skills.any(func(s): return s.id == blessed_skill) and boss.element_power.get(Element.Type.DARK, 0.0) > 0.0
		and plain.element_power.is_empty(), "a sponsored boss fights with its patron's blessing and blessed skill")
	check(CutInData.boss("boss", [&"necromancer"], 40).subtitle.contains("Hades"), "its cut-in names the sponsor")
	GameState.start_new_game("Ophelius", "Cassia", 1)
	var rival: StringName = BeingLibrary.rivals_of(&"hades")[0]
	var before_p := GameState.blessings.interest(&"hades")
	var before_r := GameState.blessings.interest(rival)
	GameState.pending_encounter = EnemyLibrary.build_group([&"necromancer"])
	GameState.return_scene = ""
	GameState.active_enemy_index = -1
	GameState.finish_battle(BattleManager.Outcome.VICTORY)
	check(GameState.blessings.interest(&"hades") < before_p and GameState.blessings.interest(rival) > before_r,
		"beating it annoys its patron and pleases the patron's rivals")
	GameState.delete_slot(1)


func _unit(id: StringName) -> Combatant:
	return Combatant.from_enemy(EnemyLibrary.get_enemy(id))


func test_traits() -> void:
	print("Traits")
	var party: Array[CharacterData] = [GameState.make_premade("Vex", &"mage", { Stats.Type.INTELLIGENCE: 20, Stats.Type.HEALTH: 15 })]
	var b := BattleManager.new()
	b.rng.seed = 7
	b.setup(party, EnemyLibrary.build_group([&"hive_drone", &"hive_drone", &"hive_drone"]))
	var drone: Combatant = b.enemies[0]
	var target: Combatant = b.party[0]
	drone.swarm_allies = 0
	var r1 := RandomNumberGenerator.new()
	r1.seed = 3
	var alone: int = DamageCalc.roll_damage(drone, target, drone.basic_attack, r1).amount
	drone.swarm_allies = 2
	var r2 := RandomNumberGenerator.new()
	r2.seed = 3
	var swarm: int = DamageCalc.roll_damage(drone, target, drone.basic_attack, r2).amount
	check(swarm > alone, "swarmers hit harder with friends alive (%d -> %d)" % [alone, swarm])

	var mage := b.party[0]
	var skeleton := _unit(&"skeleton_warrior")
	b.enemies = [skeleton] as Array[Combatant]
	skeleton.hp = 5
	mage.mp = 99
	b.current = mage
	b.submit(BattleAction.use_skill(mage, SkillLibrary.get_skill(&"frost_bolt"), skeleton))
	check(skeleton.hp == 1 and skeleton.undying_used, "undying: survives its first killing blow")
	skeleton.hp = 5
	skeleton.undying_used = false
	b.current = mage
	b.submit(BattleAction.use_skill(mage, SkillLibrary.get_skill(&"ember"), skeleton))
	check(not skeleton.is_alive(), "...but fire puts it down for good")

	var plain := _unit(&"bandit_brute")
	var dragon := _unit(&"drakeling")
	plain.stats = dragon.stats   # same defenses, only the trait differs
	plain.affinities = {}
	dragon.affinities = {}
	var r3 := RandomNumberGenerator.new()
	r3.seed = 11
	var normal_hit: int = DamageCalc.roll_damage(target, plain, SkillLibrary.get_skill(&"attack_magic"), r3).amount
	var r4 := RandomNumberGenerator.new()
	r4.seed = 11
	var scaled_hit: int = DamageCalc.roll_damage(target, dragon, SkillLibrary.get_skill(&"attack_magic"), r4).amount
	check(scaled_hit < normal_hit, "dragonscale turns hits that aren't weaknesses (%d -> %d)" % [normal_hit, scaled_hit])


func test_signature_books() -> void:
	print("Signature skills")
	var bosses := [&"bandit_lord", &"hive_queen", &"moonfang", &"rift_sovereign", &"necromancer", &"archfiend",
		&"seraph_judicator", &"dragon_sovereign"]
	var ok := true
	for id in bosses:
		var sig := EnemyLibrary.get_enemy(id).skills.filter(func(s): return SkillLibrary.get_skill(s).tier == SkillTier.Tier.UNIQUE)
		ok = ok and sig.size() == 1 and ItemLibrary.get_item(SkillBooks.book_item_id(sig[0])) != null
	check(ok, "every new boss has one Unique signature skill, with a book that can drop")
