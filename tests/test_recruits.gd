extends Node
## Recruits (Hayden's roster): the data, every way of meeting them (campfire,
## hire, favor quest, rescue fight, boss captive), wanderers, route refusals,
## loyalty quests unlocking personal skills, and saving.
## Run:  godot --headless res://tests/test_recruits.tscn

var _passed := 0
var _failed := 0


func _ready() -> void:
	GameState.save_dir = "user://test_saves_recruits"
	test_roster()
	test_wanderers()
	test_campfire_and_loyalty()
	test_hire()
	test_favor()
	test_rescue()
	test_captives()
	test_refusals()
	test_saving()
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


func _fresh() -> void:
	GameState.start_new_game("Ophelius", "Cassia", 1)
	GameState.player.gold = 5000


func _recruits() -> Array:
	return NpcLibrary.NPCS.keys().filter(func(id): return NpcLibrary.is_recruitable(id))


## Finish whatever defeat steps the active quests are on.
func _beat(ids: Array, times: int) -> void:
	var rng := RandomNumberGenerator.new()
	for i in times:
		GameState.quests.on_battle_won(EnemyLibrary.build_group(ids), rng)


func test_roster() -> void:
	print("Roster")
	var ids := _recruits()
	check(ids.size() >= 11, "a dozen recruits across the tower (%d)" % ids.size())
	var problems := []
	var names := {}
	for id in ids:
		var n := NpcLibrary.get_npc(id)
		var r := NpcLibrary.recruit_info(id)
		names[n.name] = true
		if ClassRegistry.get_class_def(r.get("class_id", &"")) == null:
			problems.append("%s: class" % id)
		if not r.get("meet", "") in ["campfire", "hire", "favor", "rescue", "captive", "legend"]:
			problems.append("%s: meet" % id)
		var ps := SkillLibrary.get_skill_or_null(r.get("personal_skill", &""))
		if ps == null or ps.learnable:
			problems.append("%s: personal skill must exist and not come from books" % id)
		if QuestLibrary.get_quest(QuestLibrary.loyalty_id(id)).is_empty():
			problems.append("%s: no loyalty quest" % id)
		if n.get("values", {}).get("likes", []).is_empty():
			problems.append("%s: no values" % id)
		match r.get("meet", ""):
			"hire":
				if r.get("fee", 0) <= 0:
					problems.append("%s: hire needs a fee" % id)
			"favor", "legend":
				if QuestLibrary.get_quest(QuestLibrary.favor_id(id)).is_empty():
					problems.append("%s: favor quest" % id)
			"rescue":
				if r.get("rescue_floors", []).size() != 2:
					problems.append("%s: rescue floors" % id)
			"captive":
				var boss := EnemyLibrary.get_enemy_or_null(r.get("captive_of", &""))
				var blessed: StringName = n.get("blessing", [&""])[0]
				if boss == null or not boss.is_boss or not BeingLibrary.rivals_of(boss.patron).has(blessed):
					problems.append("%s: a captive's god must be a rival of the captor's patron" % id)
	check(problems.is_empty(), "every recruit has a class, a way to meet, values, a personal skill and quests %s" % [problems])
	check(names.size() == ids.size(), "no two recruits share a name")
	check(QuestLibrary.validate_all().is_empty(), "their generated quests are valid")
	var meets := {}
	for id in ids:
		meets[NpcLibrary.recruit_info(id).meet] = true
	check(meets.size() == 6, "all six ways of meeting someone are used (incl. demigod legends)")


func test_wanderers() -> void:
	print("Wanderers")
	var present := 0
	for i in 100:
		GameState.player.legacy_id = "wander-%d" % i
		if NpcLibrary.in_this_run(&"kael"):
			present += 1
	check(present > 20 and present < 80, "wanderers are in some runs, not all (%d/100)" % present)
	check(NpcLibrary.in_this_run(&"brakka"), "everyone else is always there")
	GameState.player.legacy_id = "fixed"
	check(NpcLibrary.in_this_run(&"kael") == NpcLibrary.in_this_run(&"kael"), "the roll is fixed for a run")


func test_campfire_and_loyalty() -> void:
	print("Campfire + loyalty")
	_fresh()
	var r := DialogueRunner.new()
	r.start(&"recruit_campfire", null, &"", &"", &"brakka")
	check(r.text() == NpcLibrary.recruit_info(&"brakka").get("pitch", r.text()) or r.text() != "", "shared campfire talk")
	var c := GameState.recruit(&"brakka")
	check(c and GameState.quests.is_active(QuestLibrary.loyalty_id(&"brakka")), "joining starts their loyalty quest")
	check(not c.all_skills().any(func(s): return s.id == &"thunder_charge"), "no personal skill yet")
	_beat([&"goblin_captain"], 2)
	check(GameState.quests.is_done(QuestLibrary.loyalty_id(&"brakka")) and c.personal_unlocked
		and c.all_skills().any(func(s): return s.id == &"thunder_charge"), "loyalty done: their personal skill unlocks")
	c.skill_picks = 1
	check(c.rank_up_skill(&"thunder_charge"), "personal skills can be ranked up")


func test_hire() -> void:
	print("Hiring")
	_fresh()
	GameState.player.gold = 100
	var r := DialogueRunner.new()
	r.start(&"recruit_hire", null, &"", &"", &"garrick")
	check(r.choices().any(func(ch): return ch.text.contains("can't afford")), "too poor to hire")
	GameState.player.gold = 1000
	r.start(&"recruit_hire", null, &"", &"", &"garrick")
	var deal: Array = r.choices().filter(func(ch): return ch.text.begins_with("Deal. (600"))
	check(deal.size() == 1, "the fee is on the offer")
	r.choose(deal[0].index)
	check(GameState.player.gold == 400 and GameState.has_recruited(&"garrick"), "one-time fee: they join")


func test_favor() -> void:
	print("Favor quests")
	_fresh()
	var r := DialogueRunner.new()
	r.start(&"recruit_favor", null, &"", &"", &"daphne")
	r.choose(0)
	check(GameState.quests.is_active(QuestLibrary.favor_id(&"daphne")) and not GameState.has_recruited(&"daphne"),
		"do them a favor first")
	r.start(&"recruit_favor", null, &"", &"", &"daphne")
	check(r.node_id == "waiting", "they wait while it's not done")
	_beat([&"goblin"], 8)
	r.start(&"recruit_favor", null, &"", &"", &"daphne")
	check(r.node_id == "ready", "favor done")
	r.choose(r.choices()[0].index)
	check(GameState.has_recruited(&"daphne"), "then they join")


func test_rescue() -> void:
	print("Rescues")
	_fresh()
	GameState.enter_floor(3)
	GameState.current_layout()
	var idx := -1
	for i in GameState.floor_enemies.size():
		if GameState.floor_enemies[i].kind == "rescue":
			idx = i
	check(idx >= 0 and GameState.floor_enemies[idx].recruit == &"tamsin", "someone's fighting for their life on floor 3")
	GameState.prepare_floor_battle(idx)
	GameState.return_scene = ""
	var fighters := GameState.fighting_party()
	check(fighters.any(func(c): return c.companion_id == &"tamsin"), "they fight beside you")
	GameState.finish_battle(BattleManager.Outcome.VICTORY, fighters)
	check(GameState.has_recruited(&"tamsin") and GameState.quests.is_active(QuestLibrary.loyalty_id(&"tamsin")),
		"win, and they join")
	GameState.enter_floor(4)
	GameState.current_layout()
	check(not GameState.floor_enemies.any(func(e): return e.kind == "rescue"), "only once")


func test_captives() -> void:
	print("Captives")
	_fresh()
	check(CutInData.boss("boss", [&"moonfang"], 30).subtitle.contains("Holding Sigrun captive"), "the boss's card says who it holds")
	GameState.pending_encounter = EnemyLibrary.build_group([&"moonfang"])
	GameState.floor_enemies = [{ "pos": Vector2i(1, 1), "alive": true, "kind": "boss", "group": [&"moonfang"] as Array[StringName] }]
	GameState.active_enemy_index = 0
	GameState.return_scene = ""
	GameState.finish_battle(BattleManager.Outcome.VICTORY)
	check(GameState.has_recruited(&"sigrun"), "beat the captor: they're free and join")
	check(GameState.member_count() >= 2, "...as a member of the party")


func test_refusals() -> void:
	print("Values")
	_fresh()
	GameState.add_route_points(&"hero", 30)
	GameState.lock_route(&"hero")
	var r := DialogueRunner.new()
	r.start(&"recruit_hire", null, &"", &"", &"garrick")
	check(r.choices().any(func(ch): return ch.text == "Deal.") and GameState.recruit(&"garrick") == null,
		"a mercenary who hates heroes won't take a hero's gold")
	check(GameState.recruit(&"daphne") != null, "but a healer who likes heroes will join")


func test_saving() -> void:
	print("Saving")
	_fresh()
	var c := GameState.recruit(&"brakka")
	c.personal_unlocked = true
	GameState.enter_floor(3)
	GameState.current_layout()
	GameState.save_game()
	GameState.load_game(1)
	var back := GameState.companions.filter(func(m): return m.companion_id == &"brakka")
	check(not back.is_empty() and back[0].personal_unlocked and back[0].personal_skill == &"thunder_charge",
		"personal skills are saved")
	check(GameState.floor_enemies.any(func(e): return e.kind == "rescue" and e.get("recruit") == &"tamsin"),
		"a rescue fight on the floor is saved")
	var d := SaveSerializer.read_json(GameState.slot_path(1))
	for m in d.companions:
		if m.get("companion_id") == "brakka":
			m["personal_skill"] = "meteor"
	for e in d.floor_enemies:
		if e.get("kind") == "rescue":
			e["recruit"] = "nobody"
	SaveSerializer.write_json(GameState.slot_path(1), d)
	GameState.load_game(1)
	back = GameState.companions.filter(func(m): return m.companion_id == &"brakka")
	check(back[0].personal_skill == &"", "tampered save: a personal skill that isn't theirs is dropped")
	check(not GameState.floor_enemies.any(func(e): return e.kind == "rescue"), "...and a fake rescue becomes a normal fight")
