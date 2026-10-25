extends Node
## Loot, gear and miniboss tests.  Run:  godot --headless res://tests/test_loot.tscn

var _passed := 0
var _failed := 0


func _ready() -> void:
	test_rarity_odds()
	test_gear_generation()
	test_uniques()
	test_equipment()
	test_miniboss_floors()
	test_miniboss_battle_drops()
	test_boss_loot_profiles()
	test_boss_floor()
	test_roaming()
	test_secret_class()
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
	return "%.1f%%" % (x * 100.0)


func test_gear_generation() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var lines_ok := true
	for tier in [0, 1, 2, 3, 4]:
		for base in LootTable.BASES:
			var g := LootTable.make_gear(base, tier, 4, rng)
			if g.bonuses.size() != LootTable.STAT_LINES[tier] or g.slot != LootTable.BASES[base].slot:
				lines_ok = false
	check(lines_ok, "every base/rarity rolls the right number of stat lines and slot")
	var c := LootTable.make_gear(&"sword", Rarity.Tier.COMMON, 4, rng)
	var l := LootTable.make_gear(&"sword", Rarity.Tier.LEGENDARY, 4, rng)
	check(l.total_bonus() > c.total_bonus() * 2, "Legendary much stronger than Common (%d vs %d)" % [l.total_bonus(), c.total_bonus()])
	var early := LootTable.make_gear(&"sword", Rarity.Tier.RARE, 4, rng)
	var late := LootTable.make_gear(&"sword", Rarity.Tier.RARE, 24, rng)
	check(late.total_bonus() > early.total_bonus(), "deeper floors drop stronger gear (%d vs %d)" % [late.total_bonus(), early.total_bonus()])
	check(c.display_name == "Iron Sword" and l.display_name == "Ascendant Sword", "names follow rarity (%s / %s)" % [c.display_name, l.display_name])


func test_equipment() -> void:
	var c := GameState.make_premade("E", &"archer", {Stats.Type.AGILITY: 13, Stats.Type.STRENGTH: 10, Stats.Type.LUCK: 6, Stats.Type.STAMINA: 6})
	var agi_before := c.stats.get_total(Stats.Type.AGILITY)
	var bow := GearItem.new()
	bow.slot = GearItem.Slot.WEAPON
	bow.bonuses = {Stats.Type.AGILITY: 4, Stats.Type.HEALTH: 5}
	var hp_before := c.max_hp()
	check(c.equip(bow) == null, "equip into empty slot")
	check(c.stats.get_total(Stats.Type.AGILITY) == agi_before + 4, "gear adds to stat totals")
	check(c.max_hp() == hp_before + 50 and c.current_hp() == c.max_hp(), "+Health gear raises max and current HP")
	check(ClassRegistry.get_class_def(&"archer").qualification_share(c.stats) == ClassRegistry.get_class_def(&"archer").qualification_share(GameState.make_premade("E2", &"archer", {Stats.Type.AGILITY: 13, Stats.Type.STRENGTH: 10, Stats.Type.LUCK: 6, Stats.Type.STAMINA: 6}).stats),
		"gear doesn't affect class thresholds")
	c.set_current_hp(20)
	c.unequip(GearItem.Slot.WEAPON)
	check(not c.is_downed(), "removing +Health gear never knocks someone out (hp %d)" % c.current_hp())

	# Bag round-trip through GameState
	var inv_before := GameState.inventory.gear.size()
	GameState.inventory.add_gear(bow)
	var p := GameState.player
	check(GameState.equip_from_bag(p, bow) and GameState.inventory.gear.size() == inv_before, "equip from bag removes it from the bag")
	var bow2 := GearItem.new()
	bow2.slot = GearItem.Slot.WEAPON
	GameState.inventory.add_gear(bow2)
	GameState.equip_from_bag(p, bow2)
	check(GameState.inventory.gear.has(bow) and p.get_equipped(GearItem.Slot.WEAPON) == bow2, "swapping puts the old piece back in the bag")
	check(GameState.unequip_to_bag(p, GearItem.Slot.WEAPON) and GameState.inventory.gear.has(bow2), "unequip returns to bag")


func test_miniboss_battle_drops() -> void:
	var party: Array[CharacterData] = [
		GameState.make_premade("Tank", &"tank", {Stats.Type.HEALTH: 12, Stats.Type.STAMINA: 12, Stats.Type.STRENGTH: 11}),
		GameState.make_premade("Rogue", &"rogue", {Stats.Type.AGILITY: 12, Stats.Type.LUCK: 12, Stats.Type.STRENGTH: 11}),
		GameState.make_premade("Mage", &"mage", {Stats.Type.INTELLIGENCE: 25, Stats.Type.STAMINA: 10}),
		GameState.make_premade("Healer", &"support", {Stats.Type.INTELLIGENCE: 12, Stats.Type.STAMINA: 8, Stats.Type.HEALTH: 10, Stats.Type.AGILITY: 5}),
	]
	var wins := 0
	var drops_ok := true
	var rounds := 0
	for s in 50:
		for c in party:
			c.full_restore()
		var b := BattleManager.new()
		b.enemy_scale = StageLibrary.guardian_scale(4)
		b.loot_level = 4
		b.inventory = Inventory.new()
		b.setup(party, EnemyLibrary.build_group(EnemyLibrary.miniboss_encounter_for_floor(4)), s)
		if s == 0:
			check(not b.can_flee, "can't flee a miniboss")
		for u in b.party:
			u.ai_controlled = true
		b.start()
		var n := 0
		while not b.is_over() and n < 3000:
			b.advance()
			n += 1
		rounds += b.round_number
		if b.outcome == BattleManager.Outcome.VICTORY:
			wins += 1
			b.apply_rewards()
			drops_ok = drops_ok and b.inventory.gear.size() == 1
	check(drops_ok, "each miniboss victory drops exactly 1 piece of gear")
	print("    Floor 4 miniboss (Goblin Captain) vs lv10 party: %d/50 wins, avg %.1f rounds" % [wins, rounds / 50.0])
	check(wins > 0, "the floor-4 miniboss is beatable")


func test_rarity_odds() -> void:
	var T := Rarity.Tier
	var low := Rarity.odds_for_luck(5)
	var high := Rarity.odds_for_luck(30)
	print("    Luck 5 : C %s  U %s  R %s  E %s  L %s" % [pct(low[0]), pct(low[1]), pct(low[2]), pct(low[3]), pct(low[4])])
	print("    Luck 30: C %s  U %s  R %s  E %s  L %s" % [pct(high[0]), pct(high[1]), pct(high[2]), pct(high[3]), pct(high[4])])
	check(low[T.COMMON] > low[T.UNCOMMON] and low[T.UNCOMMON] > low[T.RARE] and low[T.RARE] > low[T.EPIC]
		and low[T.EPIC] > low[T.LEGENDARY], "tiers get rarer in order")
	check(not low.has(T.UNIQUE), "Unique is not in the normal drop table")
	var better := true
	for t in [T.RARE, T.EPIC, T.LEGENDARY]:
		better = better and high[t] > low[t]
	check(better and high[T.COMMON] < low[T.COMMON], "higher Luck = better odds for every tier above Common")
	check(high[T.LEGENDARY] / high[T.RARE] > low[T.LEGENDARY] / low[T.RARE], "Luck helps higher tiers more")

	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var counts := {}
	for i in 20000:
		var r := Rarity.roll(5, rng)
		counts[r] = counts.get(r, 0) + 1
	check(absf(counts.get(T.COMMON, 0) / 20000.0 - low[T.COMMON]) < 0.02, "roll() matches the odds table")


func test_uniques() -> void:
	check(LootTable.UNIQUES.size() == 5, "5 Uniques, one per class")
	var all_weapons := true
	for cls in LootTable.UNIQUES:
		var u := LootTable.make_unique(cls, 4)
		all_weapons = all_weapons and u.slot == GearItem.Slot.WEAPON and u.class_lock == cls and u.rarity == Rarity.Tier.UNIQUE
	check(all_weapons, "Uniques are weapons, class-locked")

	var mage := GameState.make_premade("M", &"mage", {Stats.Type.INTELLIGENCE: 35})
	var tank := GameState.make_premade("T", &"tank", {Stats.Type.HEALTH: 20, Stats.Type.STAMINA: 15})
	var staff := LootTable.make_unique(&"mage", 4)
	check(staff.can_equip(mage) and not staff.can_equip(tank), "only the Mage can equip Starfall Staff")
	check(tank.equip(staff) == staff and tank.get_equipped(GearItem.Slot.WEAPON) == null, "equip() refuses a locked Unique")

	var rng := RandomNumberGenerator.new()
	var classes := [&"tank", &"mage", &"archer", &"rogue", &"support"]
	# Minibosses and normal enemies: never a Unique, no matter how lucky.
	var miniboss_unique := false
	for id in [&"goblin_captain", &"hobgoblin", &"orc_warchief", &"orc_blood_shaman"]:
		for s in 400:
			rng.seed = s
			for g in LootTable.roll_enemy_loot(EnemyLibrary.get_enemy(id), 500, 4, rng, classes, []):
				miniboss_unique = miniboss_unique or g.rarity == Rarity.Tier.UNIQUE
	check(not miniboss_unique, "minibosses never drop Uniques (1600 lucky rolls)")

	# Bosses can; they only give Uniques for party classes that don't own theirs.
	var king := EnemyLibrary.get_enemy(&"goblin_king")
	var got := 0
	var right_class := true
	for s in 2000:
		rng.seed = s
		for g in LootTable.roll_enemy_loot(king, 5, 10, rng, [&"tank", &"mage"], [&"mage"]):
			if g.rarity == Rarity.Tier.UNIQUE:
				got += 1
				right_class = right_class and g.class_lock == &"tank"
	print("    Goblin King Unique rate at Luck 5: %s (base %s)" % [pct(got / 2000.0), pct(king.unique_chance)])
	check(got > 100 and got < 260 and right_class, "stage boss drops a Unique ~8% of the time, for a class that needs it")
	var none_left := true
	for s in 300:
		rng.seed = s
		for g in LootTable.roll_enemy_loot(king, 50, 10, rng, [&"mage"], [&"mage"]):
			none_left = none_left and g.rarity != Rarity.Tier.UNIQUE
	check(none_left, "no Unique left to give -> normal loot instead")


func test_boss_loot_profiles() -> void:
	var cap := EnemyLibrary.get_enemy(&"goblin_captain")
	var king := EnemyLibrary.get_enemy(&"goblin_king")
	var mino := EnemyLibrary.get_enemy(&"labyrinth_minotaur")
	check(cap.loot_rolls == 1 and king.loot_rolls == 2 and mino.loot_rolls == 2, "miniboss 1 drop, boss & roaming boss 2 drops")
	check(LootTable.unique_chance_for(mino, 5) > LootTable.unique_chance_for(king, 5), "roaming bosses have the best Unique chance")
	check(LootTable.unique_chance_for(king, 25) > LootTable.unique_chance_for(king, 5), "Luck raises the Unique chance a little")
	var rng := RandomNumberGenerator.new()
	var min_ok := true
	var avg := { "cap": 0.0, "king": 0.0, "mino": 0.0 }
	for s in 1000:
		rng.seed = s
		for g in LootTable.roll_enemy_loot(king, 5, 10, rng):
			min_ok = min_ok and g.rarity >= Rarity.Tier.UNCOMMON
			avg.king += g.rarity
		for g in LootTable.roll_enemy_loot(mino, 5, 10, rng):
			min_ok = min_ok and g.rarity >= Rarity.Tier.RARE
			avg.mino += g.rarity
		for g in LootTable.roll_enemy_loot(cap, 5, 10, rng):
			avg.cap += g.rarity
	check(min_ok, "boss drops are at least Uncommon, roaming at least Rare")
	var names := ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
	print("    avg drop tier: miniboss %.2f   boss %.2f   roaming %.2f" % [avg.cap / 1000.0, avg.king / 2000.0, avg.mino / 2000.0])
	check(avg.mino / 2000.0 > avg.king / 2000.0 and avg.king / 2000.0 > avg.cap / 1000.0, "loot quality: roaming > boss > miniboss")


func test_miniboss_floors() -> void:
	var floors := []
	var boss_floors := []
	for n in range(1, 31):
		if StageLibrary.is_miniboss_floor(n):
			floors.append(n)
		if StageLibrary.is_boss_floor(n):
			boss_floors.append(n)
	check(floors == [4, 9, 14, 19, 24, 29], "minibosses on 4, 9, 14, 19, 24, 29 (got %s)" % [floors])
	check(boss_floors == [10, 20, 30], "stage bosses on 10, 20, 30 (got %s)" % [boss_floors])
	check(StageLibrary.miniboss_for_floor(4)[0] == &"goblin_captain", "floor 4 = Goblin Captain")
	check(StageLibrary.miniboss_for_floor(9)[0] == &"hobgoblin", "floor 9 = Hobgoblin")
	check(StageLibrary.boss_for_floor(10)[0] == &"goblin_king", "floor 10 = Goblin King (the Hobgoblin's master)")
	check(StageLibrary.miniboss_for_floor(14)[0] == &"orc_warchief" and StageLibrary.boss_for_floor(20)[0] == &"orc_warlord", "stage 2: orcs, Warlord on floor 20")
	check(StageLibrary.boss_for_floor(70)[0] == StageLibrary.boss_for_floor(10)[0], "stages past the last defined one repeat (floor 70 = floor 10)")
	check(StageLibrary.guardian_scale(4) < StageLibrary.guardian_scale(10) and StageLibrary.guardian_scale(30) > StageLibrary.guardian_scale(20)
		and is_equal_approx(StageLibrary.guardian_scale(10), GameState.enemy_scale_for_floor(10) * StageLibrary.GUARDIAN_MULT),
		"bosses follow the floor curve, so repeated stages come back stronger")
	check(StageLibrary.stage_name(10) == "Stage 1: Goblin Warrens" and StageLibrary.stage_name(11) == "Stage 2: Orc Stronghold", "stage names")
	check(not GameState.is_rest_floor(10) and GameState.is_rest_floor(5) and GameState.is_rest_floor(15), "rest floors 5, 15 (floor 10 is the boss)")

	var ok := true
	for s in 200:
		var f := FloorLayout.generate(s, 4, false, true)
		var dist := f.distance_map(f.start)
		if f.is_blocked(f.guardian_spot) or not dist.has(f.guardian_spot) or f.enemy_spawns.has(f.guardian_spot):
			ok = false
	check(ok, "miniboss spot is open, reachable, and not shared with a normal enemy (200 floors)")

	GameState.enter_floor(4)
	GameState.current_layout()
	check(GameState.stairs_locked(), "stairs locked while the miniboss lives")
	_win_against("miniboss")
	check(not GameState.stairs_locked(), "stairs open after beating it")
	GameState.enter_floor(3)
	GameState.current_layout()
	check(not GameState.stairs_locked(), "normal floors aren't locked")


func test_boss_floor() -> void:
	GameState.checkpoint_floor = 5
	GameState.enter_floor(10)
	var layout := GameState.current_layout()
	check(layout.is_boss_floor and layout.enemy_spawns.is_empty(), "floor 10 is a boss arena with no regular enemies")
	check(GameState.floor_enemies.size() == 1 and GameState.enemy_kind(GameState.floor_enemies[0]) == "boss", "just the boss")
	check(layout.distance_map(layout.start).has(layout.guardian_spot), "boss reachable")
	check(layout.campfire.x < 0 and GameState.stairs_locked(), "no campfire and stairs locked while the boss lives")
	_win_against("boss")
	layout = GameState.current_layout()
	check(layout.campfire.x >= 0 and layout.merchant.x >= 0, "beating the boss lights the campfire and brings the merchant")
	check(GameState.checkpoint_floor == 10 and not GameState.stairs_locked(), "boss floor becomes the checkpoint, stairs open")


func test_roaming() -> void:
	GameState.story_flags.clear()
	var story_count := 0
	for r in StageLibrary.ROAMING_BOSSES:
		if r.spawn == "story":
			story_count += 1
	check(story_count == 1, "exactly one roaming boss is guaranteed by the story")

	# Random roamers: ~12% on eligible floors (story roamer already beaten so it doesn't interfere).
	GameState.defeated_roamers = [&"labyrinth_minotaur"]
	var spawned := 0
	for s in 600:
		var n: int = [8, 8, 11, 13, 16, 17][s % 6]
		GameState.enter_floor(n)
		GameState.floor_seed = s * 31 + 7
		GameState.current_layout()
		var r := GameState.floor_has_alive("roaming")
		if not r.is_empty():
			spawned += 1
			check_once(r.roamer_id == &"lantern_wraith", "random spawns only use \"random\" roamers")
	print("    random roaming boss appeared on %d/600 eligible floors" % spawned)
	check(spawned > 40 and spawned < 110, "random roamers spawn ~12% of the time")
	var bad_floor := false
	GameState.defeated_roamers.clear()
	for n in [4, 5, 9, 10, 14, 15]:
		for s in 60:
			GameState.enter_floor(n)
			GameState.floor_seed = s
			GameState.current_layout()
			bad_floor = bad_floor or not GameState.floor_has_alive("roaming").is_empty()
	check(not bad_floor, "never on rest, miniboss or boss floors")
	check(StageLibrary.eligible_roamers(3, []).is_empty(), "no roaming bosses on the first floors")

	# Story roamer: guaranteed from floor 7 on, every visit, until beaten.
	GameState.defeated_roamers.clear()
	var early := false
	for s in 50:
		GameState.enter_floor(6)
		GameState.floor_seed = s
		GameState.current_layout()
		var r := GameState.floor_has_alive("roaming")
		early = early or (not r.is_empty() and r.roamer_id == &"labyrinth_minotaur")
	check(not early, "story roamer doesn't show up before its story floor")
	var always := true
	for s in 50:
		GameState.enter_floor(7 + s % 2)   # floors 7 and 8
		GameState.floor_seed = s
		GameState.current_layout()
		var r := GameState.floor_has_alive("roaming")
		always = always and not r.is_empty() and r.roamer_id == &"labyrinth_minotaur"
	check(always, "story roamer (Minotaur) is guaranteed on floors 7+ until beaten")
	GameState.enter_floor(7)
	GameState.current_layout()
	_win_against("roaming")
	check(GameState.defeated_roamers.has(&"labyrinth_minotaur"), "victory records the roamer as defeated")
	var gone := true
	for s in 100:
		GameState.enter_floor(8 + s % 10)
		GameState.floor_seed = s
		GameState.current_layout()
		var r := GameState.floor_has_alive("roaming")
		gone = gone and (r.is_empty() or r.roamer_id != &"labyrinth_minotaur")
	check(gone, "a defeated roamer never comes back")

	# Secret-path roamer: hidden unless you're on the path, then guaranteed.
	var seen_without := false
	for s in 300:
		GameState.enter_floor(12 + s % 8)
		GameState.floor_seed = s
		GameState.current_layout()
		var r := GameState.floor_has_alive("roaming")
		seen_without = seen_without or (not r.is_empty() and r.roamer_id == &"ashen_wyrmling")
	check(not seen_without, "secret-class roamer never appears if you're not on its path")
	check(not SecretPaths.is_on_path(&"ashbound", GameState.story_flags), "not on the Ashbound path yet")
	GameState.set_flag(&"clue_ash_merchant_story")
	GameState.set_flag(&"clue_ash_scorched_mural")
	var hidden_at_two := true
	for s in 50:
		GameState.enter_floor([12, 13, 16, 17, 18][s % 5])
		GameState.floor_seed = s
		GameState.current_layout()
		var r := GameState.floor_has_alive("roaming")
		hidden_at_two = hidden_at_two and (r.is_empty() or r.roamer_id != &"ashen_wyrmling")
	check(hidden_at_two, "2 of 3 clues: the final step hasn't opened yet")
	GameState.set_flag(&"clue_ash_feather_in_embers")
	check(SecretPaths.is_on_path(&"ashbound", GameState.story_flags), "all 3 clues: on the path, final step open")
	var guaranteed := true
	for s in 50:
		GameState.enter_floor([12, 13, 16, 17, 18][s % 5])   # normal combat floors only
		GameState.floor_seed = s
		GameState.current_layout()
		var r := GameState.floor_has_alive("roaming")
		guaranteed = guaranteed and not r.is_empty() and r.roamer_id == &"ashen_wyrmling"
	check(guaranteed, "on the path -> the Ashen Wyrmling is guaranteed on normal floors 12+")

	# FINAL STEP: beating the Wyrmling unlocks the secret class.
	check(GameState.unlocked_secret_classes().is_empty(), "secret class still locked before the final fight")
	GameState.enter_floor(13)
	GameState.current_layout()
	_win_against("roaming")
	check(GameState.has_flag(&"ashbound_unlocked") and GameState.unlocked_secret_classes() == [&"ashbound_knight"],
		"beating the Ashen Wyrmling unlocks the Ashbound Knight")
	check(GameState.pending_unlock_message.contains("Ashbound Knight"), "the unlock is announced")
	GameState.defeated_roamers.erase(&"ashen_wyrmling")

	# Secret beats story when both are due on the same floor.
	GameState.defeated_roamers.clear()
	var pick := StageLibrary.guaranteed_roamer(13, [], GameState.story_flags)
	check(pick.id == &"ashen_wyrmling", "secret roamer takes priority over the story roamer")

	var b := BattleManager.new()
	b.setup([GameState.make_premade("R", &"tank", {Stats.Type.HEALTH: 20, Stats.Type.STAMINA: 15})] as Array[CharacterData],
		EnemyLibrary.build_group(EnemyLibrary.TEST_ROAMING_ENCOUNTER), 1)
	check(b.can_flee, "you can flee from a roaming boss")
	GameState.defeated_roamers.clear()
	GameState.story_flags.clear()


var _once := {}
func check_once(cond: bool, label: String) -> void:
	if not cond:
		_once[label] = true
		check(false, label)
	elif not _once.has(label):
		_once[label] = true
		check(true, label)


func _win_against(kind: String) -> void:
	for i in GameState.floor_enemies.size():
		if GameState.enemy_kind(GameState.floor_enemies[i]) == kind:
			GameState.active_enemy_index = i
	GameState.return_scene = ""
	GameState.finish_battle(BattleManager.Outcome.VICTORY)



func test_secret_class() -> void:
	GameState.story_flags.clear()
	var ash := ClassRegistry.get_class_def(&"ashbound_knight")
	check(ash != null and ash.is_secret, "Ashbound Knight exists and is secret")
	var p := GameState.player
	var saved_class := p.class_id
	# A STR/INT build that meets the stat gate.
	var c := GameState.make_premade("A", &"archer", {Stats.Type.AGILITY: 13, Stats.Type.STRENGTH: 10, Stats.Type.LUCK: 6, Stats.Type.STAMINA: 6})
	var fresh := CharacterData.new()
	while fresh.level < 10:
		fresh.level_up()
	fresh.apply_allocation({Stats.Type.STRENGTH: 12, Stats.Type.INTELLIGENCE: 10, Stats.Type.HEALTH: 13})
	check(not fresh.get_qualifying_classes().has(ash), "locked secret class never shows up at level 10")
	check(ClassRegistry.get_near_misses(fresh.stats).all(func(m): return not m.def.is_secret), "or in the 'how close you are' hints")
	check(not GameState.take_secret_class(p, &"ashbound_knight"), "can't take it while locked")

	GameState.set_flag(&"ashbound_unlocked")
	check(fresh.get_qualifying_classes().has(ash), "unlocked + stat gate met -> offered at level 10")
	check(not c.can_take_secret_class(ash), "stat gate still applies (%d%% STR+INT, needs 55%%)" % roundi(ash.qualification_share(c.stats) * 100))

	# Player switches from an existing class.
	GameState.player = fresh
	fresh.choose_class(ClassRegistry.get_class_def(&"tank"))
	check(not GameState.take_secret_class(GameState.companions[0] if not GameState.companions.is_empty() else c, &"ashbound_knight"), "only the player character can take it")
	check(GameState.take_secret_class(fresh, &"ashbound_knight") and fresh.class_id == &"ashbound_knight", "player can switch into the secret class")
	var u := Combatant.from_character(fresh)
	check(u.skills.size() == 2 and u.skills[0].id == &"ember_strike", "gets the Ashbound Knight skills in battle")
	GameState.player = p
	p.class_id = saved_class
	GameState.story_flags.clear()
