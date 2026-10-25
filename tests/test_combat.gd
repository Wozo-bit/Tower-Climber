extends Node
## Headless combat tests.  Run:  godot --headless res://tests/test_combat.tscn

var _passed := 0
var _failed := 0


func _ready() -> void:
	test_default_rows()
	test_four_rows()
	test_row_protection()
	test_backstab_ignores_row()
	test_back_row_melee_penalty()
	test_defend_halves()
	test_mp_costs()
	test_magic_never_misses()
	test_agility_turn_priority()
	test_taunt_draws_attacks()
	test_heal_caps_at_max()
	test_swap_row_persists()
	test_full_auto_battle()
	test_invalid_actions_rejected()
	run_carry_over_tests()
	run_item_tests()
	run_goddess_tear_and_boss_tests()
	print("\n==== %d passed, %d failed ====" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)


func check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  ", label)
	else:
		_failed += 1
		printerr("  FAIL  ", label)


func test_party() -> Array[CharacterData]:
	return [
		GameState.make_premade("Tank", &"tank", {Stats.Type.HEALTH: 12, Stats.Type.STAMINA: 12, Stats.Type.STRENGTH: 11}),
		GameState.make_premade("Archer", &"archer", {Stats.Type.AGILITY: 13, Stats.Type.STRENGTH: 10, Stats.Type.LUCK: 6, Stats.Type.STAMINA: 6}),
		GameState.make_premade("Mage", &"mage", {Stats.Type.INTELLIGENCE: 25, Stats.Type.STAMINA: 10}),
		GameState.make_premade("Healer", &"support", {Stats.Type.INTELLIGENCE: 12, Stats.Type.STAMINA: 8, Stats.Type.HEALTH: 10, Stats.Type.AGILITY: 5}),
	]


func new_battle(enemy_ids: Array, seed_value := 1) -> BattleManager:
	var b := BattleManager.new()
	b.setup(test_party(), EnemyLibrary.build_group(enemy_ids), seed_value)
	return b


func find(units: Array[Combatant], n: String) -> Combatant:
	for u in units:
		if u.display_name.begins_with(n):
			return u
	return null


# ---------------------------------------------------------

func test_default_rows() -> void:
	var b := new_battle([&"goblin"])
	check(find(b.party, "Tank").row == Combatant.Row.FRONT, "Tank defaults to front row")
	check(find(b.party, "Mage").row == Combatant.Row.BACK, "Mage defaults to back row")
	check(find(b.party, "Archer").row == Combatant.Row.REAR, "Archer defaults to the rear row")


## Hayden 2026-10-25: four rows, melee reaches the nearest standing row.
func test_four_rows() -> void:
	var b := new_battle([&"goblin"])
	b.start()
	var tank := find(b.party, "Tank")
	var archer := find(b.party, "Archer")
	var mage := find(b.party, "Mage")
	var healer := find(b.party, "Healer")
	tank.row = Combatant.Row.FRONT
	healer.row = Combatant.Row.MIDDLE
	archer.row = Combatant.Row.REAR
	mage.row = Combatant.Row.BACK
	var gob: Combatant = b.enemies[0]
	var melee := SkillLibrary.get_skill(&"attack_melee")
	var reach := func(): return b.valid_targets(gob, melee).map(func(u): return u.display_name.left(2))
	check(reach.call() == ["Ta"], "melee only reaches the front row while it stands (%s)" % [reach.call()])
	tank.hp = 0
	check(reach.call() == ["He"], "then the middle")
	healer.hp = 0
	check(reach.call() == ["Ar"], "then the rear")
	archer.hp = 0
	check(reach.call() == ["Ma"], "then the back")
	check(b.valid_targets(gob, SkillLibrary.get_skill(&"firebolt")).size() == 1, "magic ignores rows")
	check(DamageCalc.MELEE_ROW_MULT == [1.0, 0.9, 0.7, 0.5], "melee from further back hits softer")
	b.current = mage
	check(b.submit(BattleAction.move_row(mage, Combatant.Row.MIDDLE)) and mage.row == Combatant.Row.MIDDLE,
		"move to a chosen row")
	var mids := { &"bandit_cutthroat": 1, &"goblin_archer": 2, &"imp_shaman": 3 }
	var rows_ok := true
	for id in mids:
		var d := EnemyLibrary.get_enemy_or_null(id)
		if d and d.row != mids[id]:
			rows_ok = false
	check(rows_ok, "enemies use the rows too: skirmishers middle, archers rear, casters back")


func test_row_protection() -> void:
	var b := new_battle([&"goblin", &"goblin_archer"])
	var goblin := find(b.enemies, "Goblin")      # front
	var archer := find(b.enemies, "Goblin Archer") # back
	var tank := find(b.party, "Tank")
	var melee := SkillLibrary.get_skill(&"attack_melee")
	var ranged := SkillLibrary.get_skill(&"attack_ranged")
	check(not b.valid_targets(tank, melee).has(archer), "melee can't reach back row behind a living front row")
	check(b.valid_targets(tank, ranged).has(archer), "ranged can reach the back row")
	goblin.hp = 0
	check(b.valid_targets(tank, melee).has(archer), "back row exposed once front row falls")

	# Same rule protects the party's back row from enemy melee.
	var enemy_goblin := Combatant.from_enemy(EnemyLibrary.get_enemy(&"goblin"))
	var party_targets := b.valid_targets(enemy_goblin, melee)
	check(party_targets.size() == 1 and party_targets[0].display_name == "Tank", "enemy melee can only hit our front-row Tank")


func test_backstab_ignores_row() -> void:
	var b := new_battle([&"goblin", &"goblin_archer"])
	var tank := find(b.party, "Tank")
	check(b.valid_targets(tank, SkillLibrary.get_skill(&"backstab")).has(find(b.enemies, "Goblin Archer")),
		"Backstab reaches a protected back row")


func test_back_row_melee_penalty() -> void:
	var b := new_battle([&"orc_brute"])
	var tank := find(b.party, "Tank")
	var orc := b.enemies[0]
	var melee := SkillLibrary.get_skill(&"attack_melee")
	var rng1 := RandomNumberGenerator.new(); rng1.seed = 42
	var rng2 := RandomNumberGenerator.new(); rng2.seed = 42
	orc.stats.base[Stats.Type.AGILITY] = 0  # no dodge noise
	var front := DamageCalc.roll_damage(tank, orc, melee, rng1)
	tank.row = Combatant.Row.BACK
	var back := DamageCalc.roll_damage(tank, orc, melee, rng2)
	check(absi(back.amount - roundi(front.amount * 0.5)) <= 1,
		"melee from back row deals ~half (%d vs %d)" % [back.amount, front.amount])


func test_defend_halves() -> void:
	var b := new_battle([&"orc_brute"])
	var tank := find(b.party, "Tank")
	var orc := b.enemies[0]
	var melee := SkillLibrary.get_skill(&"attack_melee")
	tank.stats.base[Stats.Type.AGILITY] = 0
	var r1 := RandomNumberGenerator.new(); r1.seed = 7
	var r2 := RandomNumberGenerator.new(); r2.seed = 7
	var normal := DamageCalc.roll_damage(orc, tank, melee, r1)
	tank.add_status(&"defend", 1)
	var defended := DamageCalc.roll_damage(orc, tank, melee, r2)
	tank.stats.base[Stats.Type.AGILITY] = 5
	check(absi(defended.amount - roundi(normal.amount * 0.5)) <= 1,
		"Defend halves damage (%d vs %d)" % [defended.amount, normal.amount])


func test_mp_costs() -> void:
	var b := new_battle([&"goblin"])
	b.start()
	var mage := find(b.party, "Mage")
	b.current = mage  # force turn for the test
	var fireball := SkillLibrary.get_skill(&"fireball")
	var before := mage.mp
	check(b.submit(BattleAction.use_skill(mage, fireball, b.enemies[0])), "Mage can cast Fireball")
	check(mage.mp == before - fireball.mp_cost, "Fireball deducted %d MP" % fireball.mp_cost)
	if not b.is_over():
		mage.mp = 0
		b.current = mage
		check(not b.submit(BattleAction.use_skill(mage, fireball, b.enemies[0])), "can't cast without MP")


func test_magic_never_misses() -> void:
	var b := new_battle([&"goblin"])
	var mage := find(b.party, "Mage")
	var goblin := b.enemies[0]
	goblin.add_status(&"evasive", 99)
	goblin.stats.base[Stats.Type.AGILITY] = 200
	var misses := 0
	var phys_misses := 0
	for i in 200:
		if DamageCalc.roll_damage(mage, goblin, SkillLibrary.get_skill(&"fireball"), b.rng).miss:
			misses += 1
		if DamageCalc.roll_damage(mage, goblin, SkillLibrary.get_skill(&"attack_melee"), b.rng).miss:
			phys_misses += 1
	check(misses == 0, "magic is never dodged")
	check(phys_misses > 100, "physical attacks do get dodged by an evasive target (%d/200)" % phys_misses)


func test_agility_turn_priority() -> void:
	var fast_first := 0
	for i in 300:
		var b := new_battle([&"slime"], i)  # slime AGI 4, archer AGI 18
		b.start()
		var order := b.turn_order_preview()
		if order.find(find(b.party, "Archer")) < order.find(b.enemies[0]):
			fast_first += 1
	check(fast_first > 280, "high-Agility archer usually acts before slow slime (%d/300)" % fast_first)


func test_taunt_draws_attacks() -> void:
	var b := new_battle([&"goblin_archer"])
	var healer := find(b.party, "Healer")
	healer.add_status(&"taunt", 5)
	var archer_enemy := b.enemies[0]
	archer_enemy.skill_chance = 0.0
	var all_on_taunter := true
	for i in 50:
		var action := BattleAI.choose(b, archer_enemy)
		all_on_taunter = all_on_taunter and action.target == healer
	check(all_on_taunter, "enemy AI always targets the taunting unit")


func test_heal_caps_at_max() -> void:
	var b := new_battle([&"goblin"])
	b.start()
	var healer := find(b.party, "Healer")
	var tank := find(b.party, "Tank")
	tank.hp = tank.max_hp - 3
	b.current = healer
	b.submit(BattleAction.use_skill(healer, SkillLibrary.get_skill(&"heal"), tank))
	check(tank.hp == tank.max_hp, "heal doesn't overflow max HP")


func test_swap_row_persists() -> void:
	var b := new_battle([&"goblin"])
	b.start()
	var mage := find(b.party, "Mage")
	b.current = mage
	b.submit(BattleAction.simple(BattleAction.Type.SWAP_ROW, mage))
	check(mage.row == Combatant.Row.FRONT, "swap row moves mage to front")
	check(mage.source_character.battle_row == Combatant.Row.FRONT, "row choice saved to the character")


func test_full_auto_battle() -> void:
	var wins := 0
	var finished := 0
	for s in 20:
		var b := new_battle([&"goblin", &"goblin", &"goblin_archer"], s)
		for u in b.party:
			u.ai_controlled = true
		var xp_before := b.party[0].source_character.xp + b.party[0].source_character.level * 100000
		b.start()
		var turns := 0
		while not b.is_over() and turns < 500:
			b.advance()
			turns += 1
		if b.is_over():
			finished += 1
		if b.outcome == BattleManager.Outcome.VICTORY:
			wins += 1
			b.apply_rewards()
			var src := b.party[0].source_character
			if s == 0:
				check(b.rewards.xp == 175 and b.rewards.gold == 44, "rewards summed (%d xp, %d gold)" % [b.rewards.xp, b.rewards.gold])
				check(src.xp + src.level * 100000 > xp_before, "surviving party members gain XP")
	check(finished == 20, "all 20 auto-battles finish")
	check(wins >= 15, "lv10 party usually beats a goblin pack (%d/20)" % wins)


func test_invalid_actions_rejected() -> void:
	var b := new_battle([&"goblin", &"goblin_archer"])
	b.start()
	var tank := find(b.party, "Tank")
	b.current = tank
	var not_current := find(b.party, "Mage")
	check(not b.submit(BattleAction.use_skill(not_current, not_current.basic_attack, b.enemies[0])), "can't act out of turn")
	check(not b.submit(BattleAction.use_skill(tank, tank.basic_attack, find(b.enemies, "Goblin Archer"))),
		"can't melee a protected back-row target")
	b.can_flee = false
	check(not b.submit(BattleAction.simple(BattleAction.Type.FLEE, tank)), "can't flee when fleeing is disabled")


# ---------------------------------------------------------
# HP carry-over & items
# ---------------------------------------------------------

func run_carry_over_tests() -> void:
	# Damage persists after a battle.
	var b := new_battle([&"goblin"])
	var tank := find(b.party, "Tank")
	var tank_data := tank.source_character
	tank.hp -= 50
	tank.mp -= 5
	b.write_back_party()
	check(tank_data.current_hp() == tank_data.max_hp() - 50, "HP damage carries over to CharacterData")
	check(tank_data.current_mp() == tank_data.max_mp() - 5, "MP spent carries over")
	var b2 := BattleManager.new()
	b2.setup([tank_data] as Array[CharacterData], EnemyLibrary.build_group([&"slime"]), 1)
	check(b2.party[0].hp == tank_data.max_hp() - 50, "next battle starts with carried-over HP")

	# Downed stays downed and doesn't get a turn.
	tank_data.set_current_hp(0)
	check(tank_data.is_downed(), "0 HP = downed")
	check(tank_data.heal(100) == 0, "healing can't revive a downed ally")
	var b3 := BattleManager.new()
	var healthy := GameState.make_premade("H", &"mage", {Stats.Type.INTELLIGENCE: 35})
	b3.setup([tank_data, healthy] as Array[CharacterData], EnemyLibrary.build_group([&"slime"]), 3)
	b3.start()
	check(not b3.turn_order_preview().has(b3.party[0]), "downed ally gets no turn")
	tank_data.full_restore()
	check(tank_data.current_hp() == tank_data.max_hp(), "full_restore revives to full")

	# Raising Health raises current HP too.
	var c := CharacterData.new()
	c.level_up()
	c.set_current_hp(c.max_hp() - 20)
	c.allocate(Stats.Type.HEALTH, 2)
	check(c.current_hp() == c.max_hp() - 20, "allocating Health raises current HP with max")

	# Respec never knocks someone out.
	var r := CharacterData.new()
	r.level_up()
	r.allocate(Stats.Type.HEALTH, 5)       # max 150
	r.set_current_hp(30)
	r.respec()                              # max back to 100
	check(r.current_hp() == 30, "respec keeps current HP when it fits under the new max (hp %d)" % r.current_hp())

	# All downed at battle start -> immediate defeat, no hang.
	var d := CharacterData.new()
	d.set_current_hp(0)
	var b4 := BattleManager.new()
	b4.setup([d] as Array[CharacterData], EnemyLibrary.build_group([&"slime"]), 1)
	b4.start()
	check(b4.outcome == BattleManager.Outcome.DEFEAT, "battle with no conscious party ends in defeat")


func run_item_tests() -> void:
	var inv := Inventory.new()
	inv.add(&"potion", 2)
	var b := new_battle([&"goblin"])
	b.inventory = inv
	b.start()
	var tank := find(b.party, "Tank")
	var mage := find(b.party, "Mage")
	tank.hp = 50
	b.current = mage
	check(b.submit(BattleAction.use_item(mage, ItemLibrary.get_item(&"potion"), tank)), "use Potion in battle")
	check(tank.hp == 130 and inv.count(&"potion") == 1, "Potion heals 80 and is consumed")
	b.current = mage
	check(not b.submit(BattleAction.use_item(mage, ItemLibrary.get_item(&"potion"), b.enemies[0])), "can't potion an enemy")
	b.current = mage
	check(not b.submit(BattleAction.use_item(mage, ItemLibrary.get_item(&"ether"), tank)), "can't use an item you don't have")

	# Field use
	var c := GameState.make_premade("F", &"tank", {Stats.Type.HEALTH: 20, Stats.Type.STAMINA: 15})
	check(not inv.use_on_character(&"potion", c), "potion on a full-HP ally is refused (not wasted)")
	c.set_current_hp(10)
	check(inv.use_on_character(&"potion", c) and c.current_hp() == 90, "field potion heals 80")

	# Field heal spell
	var healer := GameState.make_premade("S", &"support", {Stats.Type.INTELLIGENCE: 20, Stats.Type.STAMINA: 15})
	var mp_before := healer.current_mp()
	var healed := GameState.cast_field_heal(healer, SkillLibrary.get_skill(&"heal"), c)
	check(healed > 0 and healer.current_mp() == mp_before - 6, "Support can cast Heal out of battle (+%d)" % healed)


func run_goddess_tear_and_boss_tests() -> void:
	var tear := ItemLibrary.get_item(&"goddess_tear")
	check(tear.price >= 1000 and ItemLibrary.SHOP_STOCK.has(&"goddess_tear"), "Goddess Tear sold, and expensive (%dg)" % tear.price)

	# Field use
	var inv := Inventory.new()
	inv.add(&"goddess_tear", 2)
	var c := GameState.make_premade("K", &"tank", {Stats.Type.HEALTH: 20, Stats.Type.STAMINA: 15})
	check(not inv.use_on_character(&"goddess_tear", c), "Goddess Tear does nothing on a conscious ally (not wasted)")
	c.set_current_hp(0)
	check(inv.use_on_character(&"goddess_tear", c), "Goddess Tear revives a downed ally out of battle")
	check(c.current_hp() == roundi(c.max_hp() * 0.3) and inv.count(&"goddess_tear") == 1, "revived at 30%% HP (%d/%d), Goddess Tear consumed" % [c.current_hp(), c.max_hp()])

	# Battle use
	var b := new_battle([&"goblin"])
	b.inventory = inv
	b.start()
	var tank := find(b.party, "Tank")
	var mage := find(b.party, "Mage")
	tank.hp = 0
	b.current = mage
	check(not b.submit(BattleAction.use_item(mage, ItemLibrary.get_item(&"potion"), tank)), "potion can't revive in battle")
	b.current = mage
	check(b.submit(BattleAction.use_item(mage, tear, tank)) and tank.is_alive(), "Goddess Tear revives in battle")
	check(inv.count(&"goddess_tear") == 0, "Goddess Tear consumed in battle")

	# Boss: no fleeing, guaranteed Goddess Tear drop
	var boss := new_battle(EnemyLibrary.TEST_BOSS_ENCOUNTER)
	check(not boss.can_flee, "can't flee from a boss fight")
	var normal := new_battle([&"goblin"])
	check(normal.can_flee, "can still flee normal fights")
	var bag := Inventory.new()
	boss.inventory = bag
	for u in boss.party:
		u.ai_controlled = true
	boss.start()
	var n := 0
	while not boss.is_over() and n < 2000:
		boss.advance()
		n += 1
	if boss.outcome == BattleManager.Outcome.VICTORY:
		boss.apply_rewards()
		check(bag.count(&"goddess_tear") == 1, "boss drops a Goddess Tear on victory")
	else:
		check(boss.outcome == BattleManager.Outcome.DEFEAT, "boss fight ended (party lost this seed — drop not tested)")
