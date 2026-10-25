extends Node
## Save/load, Hall of Climbers, New Game+ and Ascendant tests.
## Run:  godot --headless res://tests/test_save.tscn
## Uses separate test files in user:// so your real save is never touched.

var _passed := 0
var _failed := 0


func _ready() -> void:
	GameState.save_dir = "user://test_saves"
	GameState.legacy_path = "user://test_hall.json"
	_cleanup()
	test_new_game()
	test_save_load_roundtrip()
	test_completion_and_hall()
	test_new_game_plus()
	test_ascendant()
	test_json_safety()
	test_three_slots()
	test_ng_plus_slot_choice()
	test_settings()
	_cleanup()
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


func _cleanup() -> void:
	for slot in range(1, GameState.SLOT_COUNT + 1):
		GameState.delete_slot(slot)
	for p in [GameState.legacy_path]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


func test_new_game() -> void:
	GameState.start_new_game("  Ophelius ")
	check(GameState.player.character_name == "Ophelius" and GameState.player.level == 1, "new game: named level-1 player")
	check(GameState.companions.size() == 1 and GameState.companions[0].companion_id == &"childhood_friend"
		and GameState.companions[0].level == 1, "starts with the childhood friend (lv 1)")
	check(GameState.floor_number == 1 and GameState.inventory.count(&"potion") == GameState.STARTING_ITEMS[&"potion"], "floor 1 with starting items")
	check(GameState.run_active and GameState.has_save(), "a real run, saved immediately")
	check(GameState.player.legacy_id != "", "character gets a legacy id")
	check(GameState.companions[0].character_name == GameState.CHILDHOOD_FRIEND_NAME, "friend gets the default name when left blank")
	GameState.start_new_game("Ophelius", "  Cassia ")
	check(GameState.childhood_friend().character_name == "Cassia", "player can name the childhood friend")
	check(GameState.childhood_friend().rename("Bram") and GameState.childhood_friend().character_name == "Bram", "friend can be renamed later")


func test_save_load_roundtrip() -> void:
	GameState.start_new_game("Ophelius")
	var p := GameState.player
	while p.level < 12:
		p.level_up()
	p.apply_allocation({Stats.Type.STAMINA: 20, Stats.Type.HEALTH: 21})
	p.choose_class(ClassRegistry.get_class_def(&"tank"))
	p.gold = 321
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var sword := LootTable.make_gear(&"sword", Rarity.Tier.EPIC, 6, rng)
	GameState.inventory.add_gear(sword)
	GameState.equip_from_bag(p, sword)
	GameState.inventory.add_gear(LootTable.make_gear(&"ring", Rarity.Tier.RARE, 6, rng))
	GameState.inventory.add(&"goddess_tear", 2)
	p.set_current_hp(77)
	GameState.enter_floor(7)
	GameState.current_layout()
	GameState.floor_enemies[0].alive = false
	GameState.set_flag(&"clue_ash_scorched_mural")
	GameState.defeated_roamers.append(&"lantern_wraith")
	GameState.play_time_sec = 1234.0
	var str_before := p.stats.get_total(Stats.Type.STRENGTH)
	var enemies_before := _enemy_summary()
	var seed_before := GameState.floor_seed
	check(GameState.save_game(), "save_game() writes the slot")

	GameState.reset_run()
	check(GameState.player.character_name == "Climber", "reset clears the run in memory")
	check(GameState.load_game(), "load_game() reads it back")
	var q := GameState.player
	check(q.character_name == "Ophelius" and q.level == 12 and q.class_id == &"tank", "name, level, class restored")
	check(q.stats.get_total(Stats.Type.STRENGTH) == str_before, "stats incl. gear bonus restored (STR %d)" % q.stats.get_total(Stats.Type.STRENGTH))
	check(q.get_equipped(GearItem.Slot.WEAPON) != null and q.get_equipped(GearItem.Slot.WEAPON).rarity == Rarity.Tier.EPIC, "equipped gear restored")
	check(q.current_hp() == 77 and q.gold == 321, "HP and gold restored")
	check(GameState.inventory.gear.size() == 1 and GameState.inventory.count(&"goddess_tear") == 2, "bag restored")
	check(GameState.companions.size() == 1 and GameState.companions[0].character_name == GameState.CHILDHOOD_FRIEND_NAME, "companion restored")
	check(GameState.floor_number == 7 and GameState.floor_seed == seed_before and _enemy_summary() == enemies_before, "floor, layout seed and enemies restored")
	check(GameState.has_flag(&"clue_ash_scorched_mural") and GameState.defeated_roamers.has(&"lantern_wraith"), "story flags and beaten roamers restored")
	check(is_equal_approx(GameState.play_time_sec, 1234.0), "play time restored")
	check(GameState.save_summary().contains("Ophelius") and GameState.save_summary().contains("Floor 7"), "title-screen summary: %s" % GameState.save_summary())


func test_completion_and_hall() -> void:
	GameState.start_new_game("Ophelius", "Cassia")
	var p := GameState.player
	while p.level < 15:
		p.level_up()
	p.apply_allocation({Stats.Type.STAMINA: 25, Stats.Type.HEALTH: 25})
	p.choose_class(ClassRegistry.get_class_def(&"tank"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	# Equipped: one Unique (carries), one Epic (doesn't).
	var bulwark := LootTable.make_unique(&"tank", 20)
	var plate := LootTable.make_gear(&"plate", Rarity.Tier.EPIC, 20, rng)
	for g in [bulwark, plate]:
		GameState.inventory.add_gear(g)
		GameState.equip_from_bag(p, g)
	# In the bag: a Unique (carries), a quest-reward Unique (doesn't), a Legendary (doesn't).
	GameState.inventory.add_gear(LootTable.make_unique(&"mage", 20))
	var quest_u := LootTable.make_unique(&"rogue", 20)
	quest_u.quest_reward = true
	GameState.inventory.add_gear(quest_u)
	GameState.inventory.add_gear(LootTable.make_gear(&"bow", Rarity.Tier.LEGENDARY, 20, rng))

	# Beat the final boss.
	GameState.enter_floor(GameState.FINAL_FLOOR)
	GameState.current_layout()
	for i in GameState.floor_enemies.size():
		if GameState.enemy_kind(GameState.floor_enemies[i]) == "boss":
			GameState.active_enemy_index = i
	GameState.return_scene = ""
	GameState.finish_battle(BattleManager.Outcome.VICTORY)
	check(GameState.pending_completion, "beating the floor-%d boss completes the game" % GameState.FINAL_FLOOR)
	GameState.current_slot = 2
	var rec := GameState.complete_run()
	check(rec != null and rec.times_cleared == 1 and rec.display_name() == "Ophelius", "Ophelius recorded in the Hall of Climbers")
	check(not GameState.has_save(2) and GameState.slot_info(2).state == "completed",
		"the slot now shows a 'conquered' marker instead of a run (%s)" % GameState.slot_info(2).summary)
	check(rec.slot == 2, "the Hall remembers which slot it was beaten in")
	check(not GameState.load_game(2), "a conquered slot can't be 'continued'")
	check(rec.vault.size() == 1 and rec.vault[0].class_lock == &"mage", "vault keeps only bag Uniques that aren't quest rewards")

	var book := GameState.load_legacy()
	check(book.records.size() == 1 and book.records[0].character.level == 15, "Hall survives on disk")

	# Completing again with the same character updates the record instead of duplicating it.
	GameState.load_legacy()
	GameState.player = book.records[0].character.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	GameState.ng_plus_cycle = 1
	GameState.play_time_sec = 50.0
	GameState.record_completion()
	book = GameState.load_legacy()
	check(book.records.size() == 1 and book.records[0].times_cleared == 2 and book.records[0].highest_cycle_cleared == 1,
		"clearing again updates the same record (2 clears, NG+1)")
	# A second, different character gets their own entry.
	GameState.start_new_game("Mira")
	GameState.record_completion()
	check(GameState.load_legacy().records.size() == 2, "different characters get separate records")


func test_new_game_plus() -> void:
	var book := GameState.load_legacy()
	var rec: LegacyRecord = null
	for r in book.records:
		if r.display_name() == "Ophelius":
			rec = r
	GameState.start_new_game_plus(rec)
	check(GameState.current_slot == 2, "New Game+ defaults to the slot the tower was conquered in (Slot 2)")
	var p := GameState.player
	check(p.character_name == "Ophelius" and p.level == 15 and p.class_id == &"tank", "NG+ keeps name, level, class")
	check(p.stats.get_allocated(Stats.Type.STAMINA) == 25, "NG+ keeps allocated stats")
	var weapon := p.get_equipped(GearItem.Slot.WEAPON)
	check(weapon != null and weapon.rarity == Rarity.Tier.UNIQUE, "equipped Unique carries over")
	check(p.get_equipped(GearItem.Slot.ARMOR) == null, "equipped non-Unique gear does not")
	check(GameState.inventory.gear.size() == 1 and GameState.inventory.gear[0].class_lock == &"mage", "vaulted Unique lands in the bag; Legendary + quest Unique don't")
	check(p.gold == 0 and GameState.inventory.count(&"goddess_tear") == 0 and GameState.inventory.count(&"potion") == GameState.STARTING_ITEMS[&"potion"], "gold and consumables reset")
	check(GameState.floor_number == 1 and GameState.story_flags.is_empty(), "tower progress and story flags reset")
	check(GameState.companions.size() == 1 and GameState.companions[0].level == 1, "childhood friend rejoins at level 1")
	check(GameState.childhood_friend().character_name == "Cassia", "and keeps the name you gave them")
	check(GameState.ng_plus_cycle == 2, "cycle = highest cleared + 1 (NG+2)")
	check(is_equal_approx(GameState.ng_plus_scale(1), 1.5) and is_equal_approx(GameState.ng_plus_scale(2), 2.0), "enemies x1.5 in NG+1, x2.0 in NG+2")
	check(GameState.has_save() and GameState.load_game() and GameState.player.character_name == "Ophelius", "NG+ run saves and loads")


func test_ascendant() -> void:
	var asc := ClassRegistry.get_class_def(&"ascendant")
	check(asc != null and asc.ng_plus_only and asc.is_secret, "Ascendant exists, NG+ only")
	GameState.ng_plus_cycle = 0
	check(not GameState.unlocked_secret_classes().has(&"ascendant"), "not available in a normal run")
	GameState.ng_plus_cycle = 1
	check(GameState.unlocked_secret_classes().has(&"ascendant"), "available in New Game+")
	var p := GameState.player
	var tank_unique := p.get_equipped(GearItem.Slot.WEAPON)
	check(GameState.take_secret_class(p, &"ascendant"), "player can become an Ascendant (no stat gate)")
	check(tank_unique != null and p.get_equipped(GearItem.Slot.WEAPON) == null and GameState.inventory.gear.has(tank_unique),
		"the Tank-only Unique goes back to the bag on class change")
	var raw := p.stats.get_base(Stats.Type.HEALTH) + p.stats.get_allocated(Stats.Type.HEALTH) + p.stats.get_gear_bonus(Stats.Type.HEALTH)
	check(p.stats.get_total(Stats.Type.HEALTH) == roundi(raw * 1.2), "+20%% to every stat (Health %d -> %d)" % [raw, p.stats.get_total(Stats.Type.HEALTH)])
	check(p.max_hp() == StatBlock.HP_BASE + p.stats.get_total(Stats.Type.HEALTH) * StatBlock.HP_PER_HEALTH
		+ CharacterData.HP_PER_LEVEL * (p.level - 1) and p.current_hp() == p.max_hp(),
		"max HP uses the boosted Health (and current HP stays full)")
	var u := Combatant.from_character(p)
	check(u.skills.size() == 3, "3 skills (other classes have 2)")
	# Adaptive damage uses the higher of STR / INT and ignores rows.
	var judgment := SkillLibrary.get_skill(&"judgment")
	check(DamageCalc.effective_type(u, judgment) == SkillDef.DamageType.MELEE, "STR build -> Judgment hits physically")
	var b := BattleManager.new()
	b.setup([p] as Array[CharacterData], EnemyLibrary.build_group([&"goblin", &"goblin_archer"]), 1)
	var archer := b.enemies[1]
	check(b.valid_targets(b.party[0], judgment).has(archer), "Judgment reaches the protected back row")
	# Compare with the strongest normal-run class skill at equal stats.
	var tank_u := Combatant.from_character(p)
	tank_u.stats = p.stats
	var r1 := RandomNumberGenerator.new(); r1.seed = 3
	var r2 := RandomNumberGenerator.new(); r2.seed = 3
	var goblin := b.enemies[0]
	goblin.stats.base[Stats.Type.AGILITY] = 0
	var j := DamageCalc.roll_damage(u, goblin, judgment, r1)
	var bash := DamageCalc.roll_damage(u, goblin, SkillLibrary.get_skill(&"shield_bash"), r2)
	check(j.amount > bash.amount, "Judgment out-hits Shield Bash (%d vs %d)" % [j.amount, bash.amount])
	GameState.ng_plus_cycle = 0


func test_settings() -> void:
	Settings.master_volume = 0.25
	Settings.save_settings()
	Settings.master_volume = 1.0
	Settings.load_settings()
	check(is_equal_approx(Settings.master_volume, 0.25), "settings save and load")
	Settings.master_volume = 0.8
	Settings.save_settings()


## Order-independent snapshot of the floor's enemies (dictionary key order can change on load).
func _enemy_summary() -> String:
	var parts: PackedStringArray = []
	for e in GameState.floor_enemies:
		parts.append("%s|%s|%s|%s" % [e.pos, e.alive, e.kind, e.group])
	return ";".join(parts)


func test_json_safety() -> void:
	GameState.start_new_game("Ophelius", "Cassia", 1)
	var path := GameState.slot_path(1)
	var text := FileAccess.get_file_as_string(path)
	check(path.ends_with(".json") and JSON.parse_string(text) is Dictionary, "save slot is plain JSON")
	check(not text.contains("GDScript") and not text.contains("[gd_resource") and not text.contains("script"),
		"no scripts or Godot resource data in the save")
	check(FileAccess.get_file_as_string(GameState.legacy_path).begins_with("{"), "the Hall of Climbers is JSON too")

	# Garbage file: fails to load, game state untouched.
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("[gd_resource type=\"Resource\"]\nnot json at all {{{")
	f.close()
	check(GameState.slot_info(1).state == "corrupt", "a broken file shows as 'Unreadable save'")
	check(not GameState.load_game(1) and GameState.player.character_name == "Ophelius", "loading it fails safely")

	# Tampered values: unknown ids dropped, numbers clamped, names cleaned.
	var bad := {
		"player": { "name": "   ", "level": 999999, "class": "hacker_god", "gold": -50,
			"allocated": {"0": 5, "99": 1000, "x": 3},
			"equipment": {"0": {"base": "laser_cannon", "rarity": 5}} },
		"companions": [ "not a dict", {"name": "Bram"} ],
		"inventory": { "counts": {"potion": 2, "infinite_gold": 99}, "gear": [{"base": "sword", "rarity": 99, "bonuses": {"1": 5}}] },
		"floor_number": -7,
		"floor_enemies": [ {"pos": [1, 2], "group": ["goblin", "dragon_god"], "kind": "normal"}, {"pos": "x"} ],
		"story_flags": ["clue_ash_scorched_mural", 42],
	}
	SaveSerializer.write_json(path, bad)
	check(GameState.load_game(1), "a tampered-but-valid JSON save still loads")
	var p := GameState.player
	check(p.character_name == "Climber" and p.level == 999 and p.class_id == &"" and p.gold == 0, "bad name/level/class/gold sanitised")
	check(p.stats.get_allocated(Stats.Type.HEALTH) == 5 and p.equipment.is_empty(), "unknown stats and unknown gear dropped")
	check(GameState.companions.size() == 1 and GameState.companions[0].character_name == "Bram", "non-dictionary companions skipped")
	check(GameState.inventory.count(&"potion") == 2 and GameState.inventory.count(&"infinite_gold") == 0, "unknown items dropped")
	check(GameState.inventory.gear.size() == 1 and GameState.inventory.gear[0].rarity <= Rarity.Tier.UNIQUE, "out-of-range rarity clamped")
	check(GameState.floor_number == 1, "floor number clamped")
	check(GameState.floor_enemies.size() == 1 and GameState.floor_enemies[0].group.size() == 1 and GameState.floor_enemies[0].group[0] == &"goblin", "unknown enemies and bad rows dropped")
	check(GameState.has_flag(&"clue_ash_scorched_mural") and GameState.story_flags.size() == 1, "only valid flags kept")


func test_three_slots() -> void:
	_cleanup()
	check(GameState.SLOT_COUNT == 3, "3 save slots")
	GameState.start_new_game("Ana", "", 1)
	GameState.start_new_game("Bel", "", 3)
	check(GameState.slot_info(1).state == "run" and GameState.slot_info(2).state == "empty" and GameState.slot_info(3).state == "run",
		"slots are independent (1 and 3 used, 2 empty)")
	check(GameState.load_game(1) and GameState.player.character_name == "Ana" and GameState.current_slot == 1, "load slot 1")
	GameState.enter_floor(4)
	GameState.save_game()
	check(GameState.load_game(3) and GameState.player.character_name == "Bel" and GameState.floor_number == 1, "slot 3 untouched by slot 1's progress")
	check(GameState.load_game(1) and GameState.floor_number == 4, "slot 1 kept its own progress")
	GameState.delete_slot(1)
	check(GameState.slot_info(1).state == "empty" and GameState.any_save(), "deleting a slot only clears that slot")
	check(not GameState.load_game(2), "loading an empty slot does nothing")


func test_ng_plus_slot_choice() -> void:
	_cleanup()
	GameState.start_new_game("Ophelius", "Cassia", 1)
	GameState.complete_run()
	var rec := GameState.load_legacy().records[0]
	for r in GameState.load_legacy().records:
		if r.display_name() == "Ophelius":
			rec = r
	check(GameState.ng_plus_slot_for(rec) == 1, "suggested NG+ slot = where it was beaten (Slot 1)")
	GameState.start_new_game_plus(rec, 3)
	check(GameState.current_slot == 3 and GameState.slot_info(3).state == "run" and GameState.ng_plus_cycle >= 1,
		"player may choose a different slot (Slot 3) instead")
	check(GameState.slot_info(1).state == "completed", "the conquered marker in Slot 1 is left alone")
