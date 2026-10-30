extends Node
## Routes and endings: points, leaning, locks, hints, endings (incl. DLC ones),
## companions warning and leaving, merchant reactions, the black market,
## route-flavored bounties, route-only classes and the Hall of Climbers.
## Run:  godot --headless res://tests/test_routes.tscn
## Uses separate test save files, so your real save is never touched.

var _passed := 0
var _failed := 0


func _ready() -> void:
	GameState.save_dir = "user://test_saves_routes"
	GameState.unlocks_path = "user://test_saves_routes_unlocks.json"
	Tips.path = "user://test_saves_routes_tips.json"
	GameState.legacy_path = "user://test_hall_routes.json"
	_cleanup()
	test_data_is_valid()
	test_points_and_locks()
	test_endings_and_dlc()
	test_dialogue_hooks()
	test_companions_react()
	test_merchant_and_black_market()
	test_route_bounties()
	test_route_classes()
	test_hall_and_ng_plus()
	test_save_roundtrip()
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
	GameState.delete_slot(1)
	if FileAccess.file_exists(GameState.legacy_path):
		DirAccess.remove_absolute(GameState.legacy_path)
	RouteLibrary.endings = RouteLibrary.BASE_ENDINGS.duplicate(true)


func _fresh(floor_n: int = 5) -> void:
	GameState.reset_run()
	GameState.highest_floor = 21   # room for 4 (the party grows every 20 floors)
	GameState.player.rename("Ophelius")
	GameState.player.legacy_id = "route-test"
	GameState.companions.append(GameState.make_childhood_friend("Cassia"))
	GameState.floor_number = floor_n


func test_data_is_valid() -> void:
	var problems := RouteLibrary.validate()
	for p in problems:
		printerr("    ", p)
	check(problems.is_empty(), "routes and endings are valid")
	check(DialogueLibrary.validate_all().is_empty() and QuestLibrary.validate_all().is_empty(), "dialogue and quests with route hooks are valid")
	var joined := "\n".join(DialogueLibrary.validate(&"bad", { "start": "a", "nodes": { "a": { "text": "x",
		"effects": [{ "lock_route": &"pirate" }, { "route_points": { &"ninja": 2 } }],
		"choices": [{ "text": "y", "if": { "route": &"wizard" } }] } } }))
	check(joined.contains("unknown route 'pirate'") and joined.contains("'ninja'") and joined.contains("'wizard'"),
		"the dialogue validator catches unknown routes")


func test_points_and_locks() -> void:
	var r := RouteState.new()
	check(r.current() == &"" and r.reputation_text().begins_with("Nobody"), "start neutral")
	r.add(&"hero", 9)
	check(r.current() == &"", "9 points isn't a lean yet")
	r.add(&"hero", 1)
	check(r.current() == &"hero" and r.reputation_text() == RouteLibrary.routes[&"hero"].hints[0], "10 points: leaning hero (first hint)")
	r.add(&"villain", 10)
	check(r.current() == &"", "a tie isn't a lean")
	r.add(&"villain", 15)
	check(r.current() == &"villain" and r.locked == &"", "villain ahead, not locked yet (25 vs 10)")
	r.add(&"villain", 5)
	check(r.locked == &"villain" and r.messages.size() == 1, "30 points with a 15+ lead locks it by itself")
	r.add(&"hero", 50)
	check(r.current() == &"villain", "a locked route stays, whatever the points do")
	check(not r.lock(&"hero"), "can't lock a second route")
	var close := RouteState.new()
	close.add(&"vigilante", 25)
	close.add(&"hero", 35)
	check(close.locked == &"", "no auto-lock without a big enough lead")
	check(close.lock(&"vigilante") and close.current() == &"vigilante", "a key choice locks any route")
	close.add(&"hero", -999)
	check(close.points_of(&"hero") == 0, "points never go below 0")
	close.add(&"pirate", 5)
	check(not close.points.has(&"pirate"), "unknown routes are ignored")


func test_endings_and_dlc() -> void:
	_fresh()
	check(RouteLibrary.pick_ending().id == &"neutral", "no route: the neutral ending")
	GameState.add_route_points(&"hero", 12)
	check(RouteLibrary.pick_ending().id == &"hero", "leaning hero: the hero ending")
	var loaded := DlcLoader.load_all("res://tests/fixtures/dlc")
	check(loaded == PackedStringArray(["example_pack"]), "the DLC loader finds and registers a pack")
	check(RouteLibrary.pick_ending().id == &"hero", "a DLC ending only wins when its condition fits")
	GameState.set_flag(&"example_friend_left")
	check(RouteLibrary.pick_ending().id == &"example_lone_hero", "...then its higher priority beats the base ending")
	RouteLibrary.register_ending({ "id": &"example_lone_hero", "title": "Replaced", "text": "x", "priority": 20,
		"if": { "route": &"hero", "flag": &"example_friend_left" } })
	check(RouteLibrary.get_ending(&"example_lone_hero").title == "Replaced"
		and RouteLibrary.endings.filter(func(e): return e.id == &"example_lone_hero").size() == 1, "registering the same id replaces it")
	check(RouteLibrary.validate().is_empty(), "still valid with DLC content")
	check(DlcLoader.load_all("res://no_such_dir").is_empty(), "no DLC folder: nothing loaded, no errors")
	RouteLibrary.endings = RouteLibrary.BASE_ENDINGS.duplicate(true)


func test_dialogue_hooks() -> void:
	_fresh(10)
	var r := DialogueRunner.new()
	r.start(&"captured_bandit")
	var gold := GameState.player.gold
	r.choose(2)   # rob them
	check(GameState.route.points_of(&"villain") == 5 and GameState.player.gold == gold + 250, "a choice gives route points (and gold)")
	check(DialogueRunner.check({ "no_route": true }), "5 points: still neutral")
	check(GameState.has_flag(&"bandit_judged"), "the bandit is judged (won't appear again)")
	r._apply_effects([{ "route_points": { &"villain": 6 } }])
	check(DialogueRunner.check({ "route": &"villain", "not_route": &"hero", "route_locked": false }), "route / not_route / route_locked conditions")
	_fresh(15)
	r.start(&"crossroads_shrine")
	r.choose(0)
	check(GameState.route.locked == &"hero" and DialogueRunner.check({ "route_locked": &"hero" }), "the crossroads shrine is a key choice: locks hero")
	var layout := FloorLayout.generate(1, 15, true)
	GameState.place_npcs(layout)
	check(not layout.npcs.values().has(&"crossroads_shrine"), "the shrine is gone once a route is locked")


func test_companions_react() -> void:
	_fresh(5)
	GameState.player.level_up()
	var brakka := GameState.recruit(&"brakka")
	var friend := GameState.childhood_friend()
	var sword := LootTable.make_gear(&"sword", Rarity.Tier.COMMON, 1, RandomNumberGenerator.new())
	brakka.equip(sword)
	GameState.add_route_points(&"hero", 12)
	check(GameState.pending_talks.is_empty(), "companions who like your route stay quiet")
	GameState.route = RouteState.new()
	GameState.add_route_points(&"villain", 10)
	var talks := GameState.pending_talks.map(func(t): return [t.dialogue, t.companion.character_name])
	check(talks.has([&"companion_warning", "Brakka"]) and talks.has([&"companion_warning", "Cassia"]),
		"leaning villain: Brakka and your friend warn you first")
	check(GameState.companions.has(brakka), "a warning isn't leaving")
	GameState.pending_talks.clear()
	GameState.add_route_points(&"villain", 4)
	check(GameState.pending_talks.is_empty() and GameState.companions.has(brakka), "no second warning; still with you below the line")
	GameState.add_route_points(&"villain", 6)
	check(GameState.waiting.has(brakka) and GameState.waiting.has(friend), "at 20 villain points they walk away (the friend too)")
	check(brakka.equipment.is_empty() and GameState.inventory.gear.has(sword), "their gear stays with you")
	check(GameState.pending_talks.any(func(t): return t.dialogue == &"companion_leaving"), "a leaving conversation")
	check(GameState.refuses_to_rejoin(brakka) and not GameState.rejoin(brakka), "they won't come back while you're a villain")
	var r := DialogueRunner.new()
	r.start(&"waiting_companion", brakka)
	r.choose(0)
	check(r.messages.has("Brakka won't come back while you walk this path.") and GameState.waiting.has(brakka), "asking them says so")
	GameState.route = RouteState.new()
	GameState.add_route_points(&"hero", 12)
	check(not GameState.refuses_to_rejoin(brakka) and GameState.rejoin(brakka), "turn back, and they'll rejoin")
	_fresh(5)
	GameState.add_route_points(&"villain", 12)
	check(GameState.npc_refuses(&"brakka") and GameState.recruit(&"brakka") == null, "Brakka won't join a villain")
	r.start(&"brakka")
	r.advance()
	r.advance()
	r.choose(0)
	check(r.messages.has("Brakka won't travel with someone like you."), "...and says so")
	_fresh(5)
	GameState.lock_route(&"villain")
	check(GameState.pending_talks.any(func(t): return t.dialogue == &"companion_warning"), "locking a disliked route also warns")


func test_merchant_and_black_market() -> void:
	_fresh(5)
	var potion := ItemLibrary.get_item(&"potion")
	check(GameState.shop_price(potion) == 40, "neutral: normal prices")
	GameState.add_route_points(&"hero", 12)
	check(GameState.shop_price(potion) == 36, "heroes get a discount")
	GameState.route = RouteState.new()
	GameState.add_route_points(&"villain", 12)
	check(GameState.shop_price(potion) == 50, "villains pay more")
	GameState.player.gold = 50
	check(GameState.buy_item(&"potion") and GameState.player.gold == 0, "buying uses the route price")
	var layout := FloorLayout.generate(1, 5, true)
	GameState.place_npcs(layout)
	check(layout.npcs.values().has(&"black_market"), "the black market shows up for villains")
	var lens := ItemLibrary.get_item(&"scouting_lens")
	check(ShopPanel.price_of(&"black_market", lens) == 160 and ShopPanel.price_of(&"merchant", lens) == 250,
		"the black market has its own prices (merchant charges villains 250 for a lens)")
	var r := DialogueRunner.new()
	r.start(&"black_market")
	r.choose(0)
	check(r.finished and r.requests.has("shop:black_market"), "the hooded trader opens the black market shop")
	GameState.lock_route(&"villain")
	r.start(&"merchant")
	check(r.node_id == "refuse" and not r.has_choices(), "a locked-in villain is refused by the merchant")
	_fresh(5)
	layout = FloorLayout.generate(1, 5, true)
	GameState.place_npcs(layout)
	check(not layout.npcs.values().has(&"black_market"), "no black market for anyone else")


func test_route_bounties() -> void:
	var flavored := 0
	var plain_family := true
	var routes_seen := {}
	for f in range(5, 300, 5):
		for i in QuestLog.BOUNTIES_PER_BOARD:
			var b := QuestLog.make_bounty(f, i, "route-test")
			var rp: Dictionary = b.def.rewards.get("route_points", {})
			if i == 0 and not rp.is_empty():
				plain_family = false
			if not rp.is_empty():
				flavored += 1
				for k in rp:
					routes_seen[k] = true
	check(plain_family, "the family bounty never leans a route")
	check(flavored > 15 and routes_seen.size() == 3, "some bounties are shady / pleas / wanted (%d of %d)" % [flavored, 59 * 2])
	_fresh(5)
	var pick := {}
	for f in range(5, 300, 5):
		for i in range(1, 3):
			var b := QuestLog.make_bounty(f, i, "route-test")
			if b.def.rewards.has("route_points") and b.def.rewards.route_points.has(&"villain"):
				pick = b
	check(not pick.is_empty() and pick.def.title.begins_with("Shady job"), "a shady job: %s" % pick.def.get("title", "?"))
	var back := SaveSerializer.quest_def_from_dict(JSON.parse_string(JSON.stringify(SaveSerializer.quest_def_to_dict(pick.def))))
	check(back.rewards.get("route_points", {}).get(&"villain") == QuestLog.BOUNTY_ROUTE_POINTS, "route rewards survive saving")
	GameState.quests.bounties[pick.id] = pick.def
	GameState.quests.start(pick.id)
	var goal: Dictionary = pick.def.steps[0].goal
	var victims := []
	for i in goal.count:
		victims.append(EnemyLibrary.get_enemy(goal.get("enemy", &"slime")) if goal.has("enemy") else
			EnemyLibrary.all().filter(func(d): return d.family == goal.family)[0])
	GameState.quests.on_battle_won(victims, RandomNumberGenerator.new())
	check(GameState.quests.is_done(pick.id) and GameState.route.points_of(&"villain") == QuestLog.BOUNTY_ROUTE_POINTS,
		"finishing it nudges your route")
	check(not NoticeBoardPanel.reward_text(pick.def.rewards).contains("villain"), "the board never shows route points (hints only)")


func test_route_classes() -> void:
	_fresh(5)
	var def := ClassDef.create(&"test_reaver", "Reaver", "Villain-only test class.", [Stats.Type.STRENGTH] as Array[int], 0.3)
	def.required_route = &"villain"
	check(not def.route_allows(), "a route-only class is closed off to neutrals")
	var c := CharacterData.new()
	while c.level < CharacterData.CLASS_UNLOCK_LEVEL:
		c.level_up()
	c.apply_allocation({ Stats.Type.STRENGTH: c.unspent_points })
	check(not c.choose_class(def), "...so you can't take it")
	GameState.add_route_points(&"villain", 12)
	check(def.route_allows() and c.choose_class(def), "on that route, you can")


func test_hall_and_ng_plus() -> void:
	_cleanup()
	GameState.start_new_game("Ophelius", "Cassia", 1)
	GameState.add_route_points(&"hero", 15)
	var rec := GameState.complete_run()
	check(rec.endings_seen == [&"hero"], "the Hall records the ending reached")
	GameState.start_new_game_plus(rec)
	check(GameState.route.points.is_empty() and GameState.route.current() == &"", "New Game+ starts neutral")
	GameState.add_route_points(&"villain", 15)
	rec = GameState.complete_run()
	check(rec.endings_seen == [&"hero", &"villain"], "each new ending is added")
	var book := GameState.load_legacy()
	check(book.find(rec.legacy_id).endings_seen == [&"hero", &"villain"], "saved in the Hall of Climbers")


func test_save_roundtrip() -> void:
	GameState.start_new_game("Ophelius", "Cassia", 1)
	GameState.add_route_points(&"vigilante", 12)
	GameState.add_route_points(&"hero", 3)
	GameState.save_game()
	GameState.reset_run()
	GameState.load_game(1)
	check(GameState.route.points_of(&"vigilante") == 12 and GameState.route.current() == &"vigilante", "route points are saved")
	GameState.lock_route(&"vigilante")
	GameState.save_game()
	var d := SaveSerializer.read_json(GameState.slot_path(1))
	d.route.points["pirate"] = 999
	d.route.points["hero"] = -50
	SaveSerializer.write_json(GameState.slot_path(1), d)
	GameState.load_game(1)
	check(GameState.route.locked == &"vigilante" and not GameState.route.points.has(&"pirate")
		and GameState.route.points_of(&"hero") == 0, "lock saved; tampered routes dropped, points clamped")
	d.route.locked = "pirate"
	SaveSerializer.write_json(GameState.slot_path(1), d)
	GameState.load_game(1)
	check(GameState.route.locked == &"", "tampered lock dropped")
