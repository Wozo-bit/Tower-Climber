extends Node
## Enemy intent, shared skills, skill picks and skill books.
## Run:  godot --headless res://tests/test_skills.tscn

var _passed := 0
var _failed := 0


func _ready() -> void:
	test_intents()
	test_intent_replans()
	test_guard()
	test_focus_first_aid_haste()
	test_skill_picks()
	test_class_pools()
	test_skill_ranks()
	test_book_odds()
	test_book_drops()
	test_books_teach()
	test_save_roundtrip()
	print("\n==== %d passed, %d failed ====" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)


func check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  ", label)
	else:
		_failed += 1
		printerr("  FAIL  ", label)


func pct(x: float) -> String:
	return "%.2f%%" % x


func party() -> Array[CharacterData]:
	return [
		GameState.make_premade("Tank", &"tank", {Stats.Type.HEALTH: 12, Stats.Type.STAMINA: 12, Stats.Type.STRENGTH: 11}),
		GameState.make_premade("Archer", &"archer", {Stats.Type.AGILITY: 13, Stats.Type.STRENGTH: 10, Stats.Type.LUCK: 6, Stats.Type.STAMINA: 6}),
		GameState.make_premade("Healer", &"support", {Stats.Type.INTELLIGENCE: 12, Stats.Type.STAMINA: 8, Stats.Type.HEALTH: 10, Stats.Type.AGILITY: 5}),
	]


func find(units: Array[Combatant], n: String) -> Combatant:
	for u in units:
		if u.display_name.begins_with(n):
			return u
	return null


# ---------------------------------------------------------

func test_intents() -> void:
	var b := BattleManager.new()
	b.setup(party(), EnemyLibrary.build_group([&"goblin", &"goblin_archer"]), 3)
	b.start()
	var all_planned := true
	for e in b.enemies:
		all_planned = all_planned and b.intent_of(e) != null
	check(all_planned, "every enemy has a planned move at the start of the round")
	check(b.intent_of(b.party[0]) == null, "party members (player-controlled) have no intents")
	# Each enemy carries out exactly what it showed.
	var honest := true
	var turns := 0
	while not b.is_over() and turns < 40:
		turns += 1
		if b.is_player_turn():
			b.submit(BattleAction.simple(BattleAction.Type.DEFEND, b.current))
			continue
		var shown := b.intent_of(b.current)
		var acting := b.current
		var got := {}
		var cb := func(r): got.r = r
		b.action_resolved.connect(cb)
		b.advance()
		b.action_resolved.disconnect(cb)
		if shown and got.has("r") and got.r.type == BattleAction.Type.SKILL:
			var entries: Array = got.r.entries
			honest = honest and got.r.skill == shown.skill
			if shown.skill.is_single_target() and not entries.is_empty():
				honest = honest and entries[0].target == shown.target
		if b.round_number >= 3:
			break
	check(honest, "enemies do what their intent showed (skill and target)")


func test_intent_replans() -> void:
	var b := BattleManager.new()
	b.setup(party(), EnemyLibrary.build_group([&"goblin_archer", &"goblin_archer"]), 5)
	b.start()
	var archer_e := b.enemies[0]
	archer_e.skill_chance = 0.0
	b._plan_intents()
	var target: Combatant = b.intent_of(archer_e).target
	target.hp = 0
	b._refresh_intents()
	check(b.intent_of(archer_e).target != target and b.intent_of(archer_e).target.is_alive(), "intent re-targets when its target falls")
	# Taunt pulls intents onto the taunter.
	var healer := find(b.party, "Healer")
	healer.add_status(&"taunt", 3)
	b._refresh_intents()
	check(b.intent_of(archer_e).target == healer, "taunting re-targets enemy intents onto the taunter")
	var hidden := EnemyLibrary.get_enemy(&"goblin").hide_intent
	check(not hidden, "intents are visible by default (hide_intent is an optional per-enemy flag)")


func test_guard() -> void:
	var b := BattleManager.new()
	var p := party()
	p[0].learn_skill(&"guard")
	b.setup(p, EnemyLibrary.build_group([&"goblin"]), 2)
	b.start()
	var tank := find(b.party, "Tank")
	var archer := find(b.party, "Archer")
	var guard := SkillLibrary.get_skill(&"guard")
	check(not b.valid_targets(tank, guard).has(tank), "you can't Guard yourself")
	b.current = tank
	check(b.submit(BattleAction.use_skill(tank, guard, archer)), "Tank guards the Archer")
	check(archer.active_guardian() == tank, "Archer is guarded")
	var goblin := b.enemies[0]
	archer.row = Combatant.Row.FRONT   # make the Archer reachable in melee
	goblin.stats.base[Stats.Type.LUCK] = 0
	tank.stats = tank.stats.duplicate()
	tank.stats.base[Stats.Type.AGILITY] = 0   # no dodge noise
	archer.stats.base[Stats.Type.AGILITY] = 0
	var hp_a := archer.hp
	var hp_t := tank.hp
	b.current = goblin
	b.submit(BattleAction.use_skill(goblin, goblin.basic_attack, archer))
	check(archer.hp == hp_a and tank.hp < hp_t, "the hit aimed at the Archer lands on the Tank")
	# Guard ends at the guardian's next turn.
	tank.tick_statuses()
	check(archer.active_guardian() == null, "guard ends when the guardian's next turn starts")


func test_focus_first_aid_haste() -> void:
	var b := BattleManager.new()
	var p := party()
	for id in [&"focus", &"first_aid", &"quick_step"]:
		p[1].learn_skill(id)
	b.setup(p, EnemyLibrary.build_group([&"slime"]), 4)
	b.start()
	var archer := find(b.party, "Archer")
	check(archer.skills.any(func(s): return s.id == &"focus"), "learned skills appear in battle alongside class skills")
	archer.mp = 0
	b.current = archer
	b.submit(BattleAction.use_skill(archer, SkillLibrary.get_skill(&"focus"), archer))
	check(archer.mp == roundi(archer.max_mp * 0.25), "Focus restores 25%% MP (%d)" % archer.mp)
	var tank := find(b.party, "Tank")
	tank.hp = 50
	archer.mp = archer.max_mp
	b.current = archer
	b.submit(BattleAction.use_skill(archer, SkillLibrary.get_skill(&"first_aid"), tank))
	check(tank.hp - 50 >= roundi(tank.max_hp * 0.15 * 0.9), "First Aid heals ~15%% of max HP even at low INT (+%d)" % (tank.hp - 50))
	# Haste: a hasted unit acts before a faster enemy much more often than without it.
	var counts := [0, 0]
	for hasted in [0, 1]:
		for s in 300:
			var b2 := BattleManager.new()
			b2.setup(party(), EnemyLibrary.build_group([&"slime"]), s)
			var t2 := find(b2.party, "Tank")   # AGI 5 vs slime 4 -> close race
			b2.enemies[0].stats.base[Stats.Type.AGILITY] = 8
			if hasted:
				t2.add_status(&"haste", 5)
			b2.start()
			var order := b2.turn_order_preview()
			if order.find(t2) < order.find(b2.enemies[0]):
				counts[hasted] += 1
	check(counts[1] > counts[0] * 2, "Quick Step makes acting first far more likely (%d/300 vs %d/300 without)" % [counts[1], counts[0]])


func test_skill_picks() -> void:
	var c := CharacterData.new()
	check(c.skill_picks == 1, "everyone starts with 1 skill pick (starting skill)")
	# 5 utility skills + 6 elemental bolts (Ember, Frost Bolt, Splash, Spark, Stone Shot, Gust).
	check(SkillLibrary.pick_pool().size() == 11 and SkillLibrary.pick_pool().all(func(s): return s.tier == SkillTier.Tier.COMMON),
		"picks choose from the 11 Common shared skills")
	check(c.pick_skill(&"first_aid") and c.skill_picks == 0, "spend the starting pick on First Aid")
	check(not c.pick_skill(&"guard"), "no picks left")
	while c.level < 9:
		c.level_up()
	check(c.skill_picks == 3, "a new pick at levels 3, 6, 9 (%d)" % c.skill_picks)
	check(not c.pick_skill(&"first_aid"), "can't pick a skill you already know")
	check(not c.pick_skill(&"meteor"), "picks can't take rarer skills (books only)")
	check(not c.pick_skill(&"fireball"), "or class skills")
	c.level_up()   # level 10
	c.apply_allocation({Stats.Type.HEALTH: 18, Stats.Type.STAMINA: 17})
	c.choose_class(ClassRegistry.get_class_def(&"tank"))
	var ids := c.all_skills().map(func(s): return s.id)
	check(ids.has(&"shield_bash") and ids.has(&"first_aid"), "class skills and shared skills together (%s)" % [ids])


func _classed(class_id: StringName, alloc: Dictionary) -> CharacterData:
	var c := CharacterData.new()
	while c.level < CharacterData.CLASS_UNLOCK_LEVEL:
		c.level_up()
	c.apply_allocation(alloc)
	c.choose_class(ClassRegistry.get_class_def(class_id))
	return c


func test_class_pools() -> void:
	var bolts := [&"ember", &"frost_bolt", &"splash", &"spark", &"stone_shot", &"gust"]
	var ok := true
	for cid in SkillLibrary.CLASS_PICK_POOLS:
		for id in SkillLibrary.CLASS_PICK_POOLS[cid]:
			var s := SkillLibrary.get_skill_or_null(id)
			ok = ok and s != null and SkillLibrary.pick_pool().has(s)
	for id in SkillLibrary.NOVICE_POOL:
		ok = ok and SkillLibrary.pick_pool().has(SkillLibrary.get_skill_or_null(id))
	check(ok, "every pool lists real Common skills")
	var novice := CharacterData.new()
	check(SkillLibrary.pick_pool_for(&"").size() == SkillLibrary.NOVICE_POOL.size() and not novice.pick_skill(&"frost_bolt")
		and novice.pick_skill(&"ember"), "before a class: a small novice pool")
	var tank := _classed(&"tank", {Stats.Type.HEALTH: 18, Stats.Type.STAMINA: 17})
	var tank_pool := SkillLibrary.pick_pool_for(&"tank").map(func(s): return s.id)
	check(not bolts.any(func(b): return tank_pool.has(b)) and tank_pool.has(&"guard") and tank_pool.has(&"first_aid")
		and tank_pool.has(&"quick_step"), "tanks pick bruiser skills, no elemental bolts")
	check(not tank.pick_skill(&"frost_bolt"), "a tank can't pick a bolt")
	var mage_pool := SkillLibrary.pick_pool_for(&"mage").map(func(s): return s.id)
	check(bolts.all(func(b): return mage_pool.has(b)), "mages can pick every elemental bolt")
	check(SkillLibrary.pick_pool_for(&"bastion") == SkillLibrary.pick_pool_for(&"tank"), "advanced classes use their line's pool")
	check(SkillLibrary.pick_pool_for(&"ascendant").size() == SkillLibrary.pick_pool().size(), "the Ascendant may pick anything")
	check(tank.learn_skill(&"frost_bolt"), "skill books still teach anyone anything")
	novice.skill_picks = 0
	var kept := CharacterData.new()
	kept.pick_skill(&"ember")
	while kept.level < CharacterData.CLASS_UNLOCK_LEVEL:
		kept.level_up()
	kept.apply_allocation({Stats.Type.HEALTH: 18, Stats.Type.STAMINA: 17})
	kept.choose_class(ClassRegistry.get_class_def(&"tank"))
	check(kept.all_skills().any(func(s): return s.id == &"ember"), "skills picked before the class are kept")
	var before := tank.pickable_skills().size()
	tank.skill_picks = 1
	tank.pick_skill(tank.pickable_skills()[0].id)
	check(tank.pickable_skills().size() == before - 1, "the pool shrinks as you learn it")


func test_skill_ranks() -> void:
	var tank := _classed(&"tank", {Stats.Type.HEALTH: 18, Stats.Type.STAMINA: 17})
	tank.skill_picks = 0
	check(not tank.can_rank_up(&"shield_bash"), "ranking up costs a skill pick")
	tank.skill_picks = 5
	var base := SkillLibrary.get_skill(&"shield_bash")
	check(tank.rank_up_skill(&"shield_bash") and tank.skill_rank(&"shield_bash") == 2 and tank.skill_picks == 4, "rank up a class skill")
	var r2: SkillDef = tank.all_skills().filter(func(s): return s.id == &"shield_bash")[0]
	check(r2.power > base.power and r2.mp_cost <= base.mp_cost and r2.display_name == "Shield Bash II", "rank II: stronger, cheaper (%s)" % r2.display_name)
	check(base.power == 1.4 and base.display_name == "Shield Bash", "the shared skill itself is unchanged")
	tank.rank_up_skill(&"shield_bash")
	check(not tank.rank_up_skill(&"shield_bash") and tank.skill_rank(&"shield_bash") == SkillLibrary.MAX_SKILL_RANK, "ranks stop at %d" % SkillLibrary.MAX_SKILL_RANK)
	check(not tank.rank_up_skill(&"meteor"), "only skills you know")
	tank.bless(&"thor", 1)
	check(not tank.can_rank_up(&"mjolnir"), "blessed skills can't be ranked (they're the being's)")
	var u := Combatant.from_character(tank)
	check(u.skills.any(func(s): return s.id == &"shield_bash" and s.display_name.ends_with("III")), "battles use the ranked skill")
	var heal := _classed(&"support", {Stats.Type.INTELLIGENCE: 20, Stats.Type.HEALTH: 15})
	heal.skill_picks = 1
	heal.pick_skill(&"first_aid")
	heal.skill_picks = 1
	heal.rank_up_skill(&"first_aid")
	var fa: SkillDef = heal.all_skills().filter(func(s): return s.id == &"first_aid")[0]
	check(fa.heal_pct_max_hp > SkillLibrary.get_skill(&"first_aid").heal_pct_max_hp, "ranked heals heal more")
	var d := SaveSerializer.character_to_dict(tank)
	var back := SaveSerializer.character_from_dict(JSON.parse_string(JSON.stringify(d)))
	check(back.skill_rank(&"shield_bash") == SkillLibrary.MAX_SKILL_RANK, "ranks are saved")
	d["skill_ranks"] = { "shield_bash": 99, "hack_everything": 3 }
	back = SaveSerializer.character_from_dict(d)
	check(back.skill_rank(&"shield_bash") == SkillLibrary.MAX_SKILL_RANK and not back.skill_ranks.has(&"hack_everything"),
		"tampered ranks are capped and unknown skills dropped")


func test_book_odds() -> void:
	var T := SkillTier.Tier
	var low := SkillTier.odds_for_luck(5)
	var at40 := SkillTier.odds_for_luck(40)
	print("    Luck 5 : C %s  R %s  E %s  L %s  U %s" % [pct(low[0]), pct(low[1]), pct(low[2]), pct(low[3]), pct(low[4])])
	for l in [10, 20, 30, 40, 60, 100]:
		var o := SkillTier.odds_for_luck(l)
		print("    Luck %d: C %s  R %s  E %s  L %s  U %s" % [l, pct(o[0]), pct(o[1]), pct(o[2]), pct(o[3]), pct(o[4])])
	check(is_equal_approx(low[T.COMMON], 60) and is_equal_approx(low[T.RARE], 30) and is_equal_approx(low[T.EPIC], 8)
		and is_equal_approx(low[T.LEGENDARY], 1.5) and is_equal_approx(low[T.UNIQUE], 0.5), "base odds 60 / 30 / 8 / 1.5 / 0.5")
	check(is_equal_approx(at40[T.COMMON], 50) and is_equal_approx(at40[T.RARE], 25) and is_equal_approx(at40[T.EPIC], 20)
		and is_equal_approx(at40[T.LEGENDARY], 3) and is_equal_approx(at40[T.UNIQUE], 2), "Luck 40 gives 50 / 25 / 20 / 3 / 2")
	var stepped := true
	for l in [9, 19, 29]:
		stepped = stepped and SkillTier.odds_for_luck(l) == SkillTier.odds_for_luck(l - 9)
	var rises := true
	for l in [10, 20, 30, 40, 50]:
		var a := SkillTier.odds_for_luck(l - 10)
		var b := SkillTier.odds_for_luck(l)
		rises = rises and b[T.EPIC] > a[T.EPIC] and b[T.LEGENDARY] > a[T.LEGENDARY] and b[T.UNIQUE] > a[T.UNIQUE]
	check(stepped and rises, "odds step up at every multiple of 10 Luck (Epic, Legendary, Unique all rise)")
	var sums_ok := true
	for l in range(0, 200, 7):
		var o := SkillTier.odds_for_luck(l)
		var total := 0.0
		for t in o:
			total += o[t]
			sums_ok = sums_ok and o[t] >= 0.0
		sums_ok = sums_ok and is_equal_approx(total, 100.0)
	check(sums_ok, "odds always add to 100% and never go negative (capped at Luck 100)")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var counts := {}
	for i in 40000:
		var t := SkillTier.roll(40, rng)
		counts[t] = counts.get(t, 0) + 1
	check(absf(counts.get(T.EPIC, 0) / 400.0 - 20.0) < 1.0, "roll() matches the table (Epic at Luck 40: %.1f%%)" % (counts.get(T.EPIC, 0) / 400.0))


func test_book_drops() -> void:
	check(SkillBooks.drop_chance(EnemyLibrary.get_enemy(&"goblin_king")) > SkillBooks.drop_chance(EnemyLibrary.get_enemy(&"hobgoblin"))
		and SkillBooks.drop_chance(EnemyLibrary.get_enemy(&"hobgoblin")) > SkillBooks.drop_chance(EnemyLibrary.get_enemy(&"goblin")),
		"boss > miniboss > normal book drop chance")
	var pool := SkillBooks.pool_for(EnemyLibrary.get_enemy(&"orc_brute")).map(func(s): return s.id)
	check(pool.has(&"smash"), "an enemy can drop books for skills it actually uses (Orc Brute -> Smash)")
	var rng := RandomNumberGenerator.new()
	var slime_ok := true
	var king_unique := 0
	var king_drops := 0
	for s in 4000:
		rng.seed = s
		var sb := SkillBooks.roll_book_drop(EnemyLibrary.get_enemy(&"slime"), 100, rng)
		if sb != &"":
			slime_ok = slime_ok and SkillLibrary.get_skill(sb).tier == SkillTier.Tier.COMMON
		var kb := SkillBooks.roll_book_drop(EnemyLibrary.get_enemy(&"goblin_king"), 40, rng)
		if kb != &"":
			king_drops += 1
			if kb == &"kings_decree":
				king_unique += 1
	check(slime_ok, "a slime only drops Common books, even at huge Luck (tier steps down)")
	check(king_drops > 2700 and king_unique > 0, "the Goblin King drops books ~75%% of the time, Unique King's Decree included (%d / %d)" % [king_unique, king_drops])


func test_books_teach() -> void:
	var book := ItemLibrary.get_item(SkillBooks.book_item_id(&"meteor"))
	check(book != null and book.is_skill_book() and book.display_name == "Skill Book: Meteor", "a book item exists for each shared skill")
	var inv := Inventory.new()
	inv.add(book.id, 1)
	var c := CharacterData.new()
	check(inv.use_on_character(book.id, c) and c.learned_skills.has(&"meteor") and inv.count(book.id) == 0, "using a book teaches the skill and uses it up")
	inv.add(book.id, 1)
	check(not inv.use_on_character(book.id, c) and inv.count(book.id) == 1, "a book isn't wasted on someone who knows it")
	# Battle rewards put books in the bag.
	var b := BattleManager.new()
	b.inventory = Inventory.new()
	var p := party()
	b.setup(p, EnemyLibrary.build_group([&"goblin_king"]), 1)
	b.rewards.books = [&"rally"]
	b.outcome = BattleManager.Outcome.VICTORY
	b.apply_rewards()
	check(b.inventory.count(SkillBooks.book_item_id(&"rally")) == 1, "book drops land in the bag after a win")


func test_save_roundtrip() -> void:
	var c := CharacterData.new()
	c.pick_skill(&"guard")
	c.learn_skill(&"meteor")
	c.skill_picks = 2
	var d := SaveSerializer.character_to_dict(c)
	var back := SaveSerializer.character_from_dict(JSON.parse_string(JSON.stringify(d)))
	check(back.learned_skills == c.learned_skills and back.skill_picks == 2, "learned skills and picks survive save/load")
	d["learned_skills"] = ["guard", "fireball", "hack_everything"]
	back = SaveSerializer.character_from_dict(d)
	check(back.learned_skills.size() == 1 and back.learned_skills[0] == &"guard", "class-only and unknown skills are dropped from tampered saves")
