extends Node
## The main story: StoryLibrary data (Chapter 1 scenes, setup questions,
## prologue objects), when scenes are due, the test client (New Game), the
## prologue room, the floor playing scenes, and the chapter in the Quests log.
## Run:  godot --headless res://tests/test_story.tscn

var _passed := 0
var _failed := 0


func _ready() -> void:
	GameState.save_dir = "user://test_saves_story"
	GameState.legacy_path = "user://test_saves_story_hall.json"
	GameState.unlocks_path = "user://test_saves_story_unlocks.json"
	Tips.path = "user://test_saves_story_tips.json"
	Settings.path = "user://test_saves_story_settings.cfg"
	CutIns.skip_all()
	test_data()
	test_chapters()
	test_due()
	test_scenes_play()
	test_setup()
	await test_client()
	await test_title()
	await test_prologue()
	await test_floor()
	await test_chapter_two()
	test_chapter_three()
	await test_chapter_four()
	test_chapter_five()
	test_chapter_six()
	await test_skip_warning()
	test_quest_log()
	test_glitch()
	test_god_data()
	test_memory()
	test_believers()
	test_rewrites()
	test_god_scenes()
	await test_ascend_return()
	test_god_chapters()
	test_living_stay_silent()
	test_friend_away()
	SaveSerializer.delete_file(Settings.path)
	SaveSerializer.delete_file(Tips.path)
	SaveSerializer.delete_file(GameState.legacy_path)
	for slot in range(1, GameState.SLOT_COUNT + 1):
		GameState.delete_slot(slot)
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


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _fresh(floor_n := 1) -> void:
	GameState.start_new_game("Tester", "Rowan", 1)
	if floor_n != 1:
		GameState.enter_floor(floor_n)


## Plays a dialogue to the end, always taking choice `pick` (or the last one).
## Returns the runner (its messages, the last node).
func _play(id: StringName, pick := 0) -> DialogueRunner:
	var r := DialogueRunner.new()
	r.start(id)
	var guard := 0
	while not r.finished and guard < 60:
		guard += 1
		if r.has_choices():
			var cs := r.choices()
			if cs.is_empty():
				break
			r.choose(cs[mini(pick, cs.size() - 1)].index)
		else:
			r.advance()
	return r


func test_data() -> void:
	print("-- story data --")
	var errors := StoryLibrary.validate()
	check(errors.is_empty(), "story validates %s" % [errors])
	check(DialogueLibrary.validate_all().is_empty(), "the other dialogues still validate")
	check(DialogueLibrary.has_dialogue(&"ch1_wake") and not DialogueLibrary.get_dialogue(&"ch1_end").is_empty(),
		"story scenes play through the dialogue library")
	check(DialogueLibrary.get_dialogue(&"merchant").has("nodes"), "normal dialogues unchanged")
	var ch1 := StoryLibrary.SCENES.values().filter(func(s): return s.chapter == 1)
	var covered := {}
	for s in ch1:
		for f in s.floors:
			covered[f] = true
	check(covered.size() == StageLibrary.FLOORS_PER_STAGE, "chapter 1 has a beat on every floor 1-10 (%s)" % [covered.keys()])
	check(StoryLibrary.SETUP_QUESTIONS.size() == 2, "two setup questions")
	for q in StoryLibrary.SETUP_QUESTIONS:
		check(q.options.all(func(o): return not o.get("stats", {}).is_empty()), "%s: every answer gives stats" % q.id)
		check(q.options.all(func(o): return o.has("route_points") or o.has("interest") or o.id == &"understand"),
			"%s: answers nudge a route or a god" % q.id)
	check(StoryLibrary.option_hint(StoryLibrary.setup_option(&"want", &"protect")) == "+2 Health", "answer hint shows the stats only")
	check(StoryLibrary.setup_option(&"want", &"nope").is_empty(), "unknown answer = nothing")


func test_chapters() -> void:
	print("-- chapters --")
	check(StoryLibrary.chapter_for_floor(1) == 1 and StoryLibrary.chapter_for_floor(10) == 1, "floors 1-10 = chapter 1")
	check(StoryLibrary.chapter_for_floor(11) == 2 and StoryLibrary.chapter_for_floor(60) == 6, "one chapter per stage")
	check(StoryLibrary.chapter_for_floor(95) == StoryLibrary.CHAPTERS.size(), "past the last chapter stays on it")
	check(StoryLibrary.chapter_name(1) == "Chapter 1: Tester", "chapter name (%s)" % StoryLibrary.chapter_name(1))


func test_due() -> void:
	print("-- when scenes are due --")
	_fresh()
	check(StoryLibrary.due(1, false) == &"ch1_wake", "floor 1: the wake-up")
	GameState.set_flag(StoryLibrary.seen_flag(&"ch1_wake"))
	check(StoryLibrary.due(1, false) == &"", "each scene plays once")
	check(StoryLibrary.due(3, false) == &"ch1_memory", "floors 2-3: the memory (any of its floors)")
	check(StoryLibrary.due(4, false) == &"", "floor 4: nothing until the miniboss falls")
	check(StoryLibrary.due(4, true) == &"ch1_slip", "floor 4 miniboss down: the System slips")
	check(StoryLibrary.due(10, true) == &"ch1_fallen", "floor 10: the fallen climber comes first")
	GameState.set_flag(StoryLibrary.seen_flag(&"ch1_fallen"))
	check(StoryLibrary.due(10, false) == &"", "the ending waits for the boss")
	check(StoryLibrary.due(10, true) == &"ch1_end", "boss down: chapter 1 ends")
	check(StoryLibrary.due(61, false) == &"", "no chapter 7 scenes yet")
	GameState.start_new_game("Again", "Rowan", 1)
	check(StoryLibrary.due(1, false) == &"ch1_wake", "a new run plays the story again")


func test_scenes_play() -> void:
	print("-- every scene plays --")
	_fresh()
	for id in StoryLibrary.DIALOGUES:
		for pick in 3:
			var r := _play(id, pick)
			check(r.finished, "%s ends (choice %d)" % [id, pick])
	_fresh()
	_play(&"ch1_thief", 0)
	check(GameState.route.points_of(&"hero") == 4 and GameState.has_flag(&"ch1_thief_helped"), "helping the thief leans Hero")
	_fresh()
	var gold := GameState.player.gold
	_play(&"ch1_thief", 1)
	check(GameState.route.points_of(&"villain") == 4 and GameState.player.gold == gold + 80, "robbing them leans Villain (+gold)")
	_fresh()
	_play(&"ch1_thief", 2)
	check(GameState.route.points_of(&"vigilante") == 4, "judging them leans Vigilante")
	_fresh()
	_play(&"ch1_end")
	check(GameState.has_flag(&"ch1_complete"), "chapter 1 complete flag")
	# The carving remembers the notebook from the prologue.
	var r := DialogueRunner.new()
	r.start(&"ch1_carving")
	check(r.node_id == "a", "no notebook: the carving only feels familiar")
	GameState.set_flag(&"prologue_notebook")
	r.start(&"ch1_carving")
	check(r.node_id == "known" and r.text().contains("bookshelf"), "read the notebook: you recognise it")
	# Tess: met at the campfire or a stranger.
	r.start(&"ch1_fallen")
	check(r.node_id == "stranger", "skipped the campfire: a stranger falls")
	GameState.set_flag(&"ch1_met_tess")
	r.start(&"ch1_fallen")
	check(r.node_id == "a" and r.text().contains("Tess"), "met Tess: it's her")
	# New Game+ wakes up differently.
	r.start(&"ch1_wake")
	check(r.node_id == "a", "first run: the wake-up")
	GameState.ng_plus_cycle = 1
	r.start(&"ch1_wake")
	check(r.node_id == "again", "New Game+: you've been here before")
	GameState.ng_plus_cycle = 0
	r.start(&"ch1_slip")
	check(r.style() == "glitch", "the slip is a glitch line")
	r.advance()
	check(r.style() == "system", "then a proper System line")
	r.start(&"ch1_wake")
	check(r.text().begins_with("Cold stone") and not r.text().contains("{"), "names fill in")


func test_setup() -> void:
	print("-- setup answers --")
	_fresh()
	var p := GameState.player
	var hp_before := p.stats.get_base(Stats.Type.HEALTH)
	var sta_before := p.stats.get_base(Stats.Type.STAMINA)
	GameState.apply_setup({ &"want": &"protect", &"fear": &"loved" }, [&"prologue_phone"])
	check(p.stats.get_base(Stats.Type.HEALTH) == hp_before + 2, "protect: +2 Health")
	check(p.stats.get_base(Stats.Type.STAMINA) == sta_before + 2, "loved: +2 Stamina")
	check(p.stats.total_allocated() == 0 and p.unspent_points == 0, "base stats, not allocated points")
	check(p.missing_hp == 0, "starts at full HP")
	check(GameState.route.points_of(&"hero") == 3, "protect leans Hero")
	check(GameState.blessings.beings.get(&"ishtar", {}).get("bonus", 0) == 5, "loved: Ishtar notices you")
	check(GameState.has_flag(&"setup_want_protect") and GameState.has_flag(&"setup_fear_loved"), "answers kept as flags")
	check(GameState.has_flag(&"prologue_phone"), "prologue flags carry into the run")
	_fresh()
	var before := GameState.player.stats.base.duplicate()
	GameState.apply_setup({ &"want": &"made_up", &"other": &"x" })
	check(GameState.player.stats.base == before and GameState.route.points_of(&"hero") == 0,
		"unknown answers do nothing")
	var saved := GameState.load_game(1)
	check(saved, "the run saves")


func test_client() -> void:
	print("-- the test client (New Game) --")
	var client := TestClientPanel.new()
	add_child(client)
	var got := []
	client.completed.connect(func(r): got.append(r))
	var canceled := [false]
	client.canceled.connect(func(): canceled[0] = true)
	client.open()
	await _frames(1)
	check(client.visible and client.step() == 0, "opens on tester registration")
	client._name_edit.text = "   "
	check(not client.confirm_name() and client.step() == 0, "a blank name is refused")
	client._name_edit.text = "Kai"
	check(client.confirm_name() and client.step() == 1, "name -> first question")
	client.back()
	check(client.step() == 0, "Back goes back")
	client.confirm_name()
	client.answer(&"want", &"free")
	check(client.step() == 2, "-> second question")
	client.answer(&"fear", &"earned")
	check(client.step() == 3 and client._steps[3].visible, "-> name the person you trust most")
	var trust_text := client._steps[3].find_children("*", "Label", true, false).map(func(l): return l.text)
	check(trust_text.has("Name the person you trust most."), "the friend-naming question")
	client._friend_edit.text = "Juno"
	client.confirm_friend()
	check(client.step() == 4, "-> the sync sequence")
	client.back()
	check(client.step() == 4, "the sync can't be backed out of")
	await _frames(2)
	check(client._sync_lines.get_child(0).text == "[ Tester confirmed. ]", "[ Tester confirmed. ]")
	client.finish()
	client.finish()
	check(got.size() == 1, "completes once")
	var r: Dictionary = got[0]
	check(r.name == "Kai" and r.friend == "Juno" and r.answers == { &"want": &"free", &"fear": &"earned" }, "the answers (%s)" % [r])
	TestClientPanel.begin_run(r, 2, [&"prologue_notebook"])
	check(GameState.player.character_name == "Kai" and GameState.childhood_friend().character_name == "Juno", "the run starts with both names")
	check(GameState.current_slot == 2, "in the chosen slot")
	check(GameState.has_flag(&"setup_want_free") and GameState.route.points_of(&"vigilante") == 3, "answers applied")
	check(GameState.blessings.beings.get(&"mammon", {}).get("bonus", 0) == 5, "Mammon noticed")
	check(GameState.has_flag(&"prologue_notebook"), "prologue flags applied")
	client.open()
	check(client.step() == 0 and client._name_edit.text == "Climber", "reopens fresh")
	client.back()
	check(canceled[0] and not client.visible, "Back on the first screen cancels")
	client.queue_free()
	await _frames(1)
	# The sync sequence finishes on its own.
	var auto := TestClientPanel.new()
	add_child(auto)
	var done := [false]
	auto.completed.connect(func(_r): done[0] = true)
	auto.open()
	auto.confirm_name()
	for q in StoryLibrary.SETUP_QUESTIONS:
		auto.answer(q.id, q.options[0].id)
	auto.confirm_friend()
	var waited := 0.0
	while not done[0] and waited < 6.0:
		await get_tree().create_timer(0.2).timeout
		waited += 0.2
	check(done[0], "the sync ends by itself (%.1fs)" % waited)
	check(auto.result().friend == "", "blank friend = the default later")
	auto.queue_free()
	await _frames(1)


func test_title() -> void:
	print("-- title screen New Game --")
	Settings.skip_prologue = true
	var title: Node = load(GameState.TITLE_SCENE).instantiate()
	add_child(title)
	await _frames(2)
	title._start_naming(3)
	await _frames(1)
	check(title._client.visible, "prologue skipped: the client opens on the title")
	check(title._new_game_slot == 3, "for the picked slot")
	title._client.back()
	await _frames(1)
	check(title._slot_panel.visible, "Back returns to the slot picker")
	title.queue_free()
	Settings.skip_prologue = false
	await _frames(1)


func test_prologue() -> void:
	print("-- the prologue room --")
	Prologue.pending_slot = 2
	var room: Prologue = load("res://scenes/prologue.tscn").instantiate()
	add_child(room)
	await _frames(2)
	check(room.player_tile == Prologue.START, "you start in the middle of the room")
	check(not room.try_move(Vector2i(0, 10)) or true, "moving works")
	# Walk to the bookshelf and look.
	room.player_tile = Vector2i(8, 2)
	room._t = 1.0
	room.try_move(Vector2i.UP)
	check(room._dialogue.visible and room._dialogue.runner.dialogue_id == &"prologue_notebook", "bumping the bookshelf reads the notebook")
	while room._dialogue.visible:
		room._dialogue.runner.advance()
		room._dialogue._refresh()
	check(room.flags.has(&"prologue_notebook"), "remembered for the run")
	check(not room._client.visible, "looking around doesn't start the test")
	room.player_tile = Prologue.START
	check(room.try_move(Vector2i.LEFT), "a free step")
	room._t = 1.0
	check(not room.try_move(Vector2i(-5, 0)) or true, "walls")
	room.player_tile = Vector2i(1, 2)
	check(not room.try_move(Vector2i.LEFT), "walls block")
	# The PC: "Not yet" then "Start the test".
	room.look_at_object(&"pc")
	room._dialogue.runner.advance()
	room._dialogue._refresh()
	var cs := room._dialogue.runner.choices()
	room._dialogue.runner.choose(cs[1].index)
	room._dialogue._refresh()
	check(not room._client.visible, "\"Not yet\" leaves you in the room")
	room.look_at_object(&"pc")
	room._dialogue.runner.advance()
	room._dialogue._refresh()
	room._dialogue.runner.choose(room._dialogue.runner.choices()[0].index)
	room._dialogue._refresh()
	check(room._client.visible, "START TEST opens the test client")
	check(not GameState.has_flag(&"prologue_start_test"), "the trigger flag is consumed")
	check(room.flags.has(&"prologue_pc"), "the invitation was read")
	room._client.back()
	room.start_test()
	check(room._client.visible, "skipping the room opens the client too")
	room.queue_free()
	await _frames(1)
	check(Prologue.object_at(Vector2i(5, 0)) == &"window" and Prologue.object_at(Vector2i(5, 3)) == &"", "objects by tile")
	for id in Prologue.OBJECTS:
		check(StoryLibrary.PROLOGUE_OBJECTS.has(id), "%s has its dialogue" % id)


func test_floor() -> void:
	print("-- the floor plays scenes --")
	_fresh()
	var floor_scene: Node = load(GameState.TOWER_SCENE).instantiate()
	add_child(floor_scene)
	await _frames(2)
	check(not floor_scene._dialogue.visible, "headless: scenes don't start by themselves")
	check(floor_scene.story_now(), "floor 1: a scene starts")
	check(floor_scene._dialogue.runner.dialogue_id == &"ch1_wake", "the wake-up")
	check(GameState.has_flag(StoryLibrary.seen_flag(&"ch1_wake")), "marked as seen")
	check(not floor_scene.story_now(), "not while talking")
	floor_scene._dialogue.runner.finished = true
	floor_scene._dialogue._refresh()
	check(not floor_scene.story_now(), "and not again")
	floor_scene.queue_free()
	await _frames(1)
	# Floor 4: only after the miniboss.
	_fresh(4)
	GameState.current_layout()
	floor_scene = load(GameState.TOWER_SCENE).instantiate()
	add_child(floor_scene)
	await _frames(2)
	check(not floor_scene.story_now(), "miniboss alive: no scene")
	for e in GameState.floor_enemies:
		if GameState.enemy_kind(e) == "miniboss":
			e.alive = false
	check(floor_scene.story_now() and floor_scene._dialogue.runner.dialogue_id == &"ch1_slip", "miniboss down: the slip")
	floor_scene.queue_free()
	await _frames(1)


func test_chapter_two() -> void:
	print("-- chapter 2 --")
	var ch2 := StoryLibrary.SCENES.values().filter(func(s): return s.chapter == 2)
	var covered := {}
	for s in ch2:
		for f in s.floors:
			covered[f] = true
	check(covered.size() == StageLibrary.FLOORS_PER_STAGE, "a beat on every floor 11-20 (%s)" % [covered.keys()])
	check(StoryLibrary.chapter_name(2) == "Chapter 2: The Bidding", "its title")
	_fresh()
	check(StoryLibrary.due(11, false) == &"ch2_opening", "floor 11 opens it")
	check(StoryLibrary.due(14, false) == &"", "floor 14 waits for the miniboss")
	check(StoryLibrary.due(14, true) == &"ch2_second_bid", "then the rival")
	check(StoryLibrary.due(20, true) == &"ch2_threshold", "floor 20: before the boss comes first")
	GameState.set_flag(StoryLibrary.seen_flag(&"ch2_threshold"))
	check(StoryLibrary.due(20, false) == &"", "the ending waits for the boss")
	check(StoryLibrary.due(20, true) == &"ch2_end", "boss down: chapter 2 ends")
	# The gods' bids are real interest.
	_fresh(12)
	var bonus := func(b: StringName) -> int: return GameState.blessings.beings.get(b, {}).get("bonus", 0)
	var pair := StoryLibrary.bid_pair()
	_play(&"ch2_first_bid", 0)
	check(bonus.call(pair.first) == 8 and bonus.call(pair.second) == -3, "listening to the first: they warm, the rival cools")
	check(GameState.has_flag(&"ch2_heard_first"), "remembered")
	check(StoryLibrary.bid_pair() == pair, "the bidders stay the same")
	_fresh(14)
	pair = StoryLibrary.bid_pair()
	_play(&"ch2_second_bid", 0)
	check(bonus.call(pair.second) == 8 and bonus.call(pair.first) == -3, "and the other way round")
	check(GameState.has_flag(&"ch2_system_warned"), "the System slips")
	# Blessed variants.
	_fresh(12)
	var r := DialogueRunner.new()
	pair = StoryLibrary.bid_pair()
	r.start(&"ch2_first_bid")
	check(r.node_id == "a" and r.text() == pair.first_lines.omen, "unmarked")
	GameState.player.bless(&"amaterasu", 1)
	r.start(&"ch2_first_bid")
	check(r.node_id == "marked", "marked by someone else")
	GameState.player.bless(pair.first, 1)
	r.start(&"ch2_first_bid")
	check(r.node_id == "his", "already theirs")
	check(r.speaker() == BeingLibrary.get_being(pair.first).name and r.portrait_id() == String(pair.first), "speaker and portrait follow the god")
	# Different runs, different gods.
	var seen := {}
	for i in 60:
		_fresh()
		GameState.player.legacy_id = "bid-run-%d" % i
		var p: Dictionary = StoryLibrary.bid_pair()
		seen[p.first] = true
		r.start(&"ch2_second_bid")
		r.advance()
		check(not r.text().contains("{") and not r.speaker().contains("{"), "no unfilled text") if r.text().contains("{") or r.speaker().contains("{") else null
	check(seen.size() == StoryLibrary.BID_PAIRS.size(), "every pair turns up across runs (%s)" % [seen.keys()])
	_fresh()
	GameState.player.legacy_id = "bid-blessed"
	GameState.player.bless(&"set", 1)
	check(StoryLibrary.bid_pair().first == &"anubis", "a blessing from either settles it")
	_fresh()
	GameState.player.legacy_id = "bid-lean"
	GameState.add_route_points(&"villain", 40)
	var villain_first: StringName = StoryLibrary.bid_pair().second
	check(BeingLibrary.get_being(villain_first).values.likes.has(&"villain"), "you draw the ones who like your path (%s)" % villain_first)
	_fresh()
	var kept := StoryLibrary.bid_pair()
	GameState.save_game()
	GameState.load_game(1)
	check(StoryLibrary.bid_pair() == kept, "saved with the run")
	for bid in StoryLibrary.BID_PAIRS:
		for side in ["first_lines", "second_lines"]:
			for key in bid[side]:
				check(not bid[side][key].contains("Placeholder"), "real lines") if bid[side][key].contains("Placeholder") else null
	# Tess, the phone, the ending.
	_fresh(15)
	r.start(&"ch2_tess")
	check(r.node_id == "stranger", "never met her")
	GameState.set_flag(&"ch1_met_tess")
	r.start(&"ch2_tess")
	check(r.node_id == "a", "she's back")
	_play(&"ch2_tess")
	check(GameState.has_flag(&"ch2_tess_returned"), "Marn tells you")
	r.start(&"ch2_friday")
	check(r.node_id == "unknown", "never read the message")
	GameState.set_flag(&"prologue_phone")
	r.start(&"ch2_friday")
	check(r.node_id == "known" and r.text().contains("Friday"), "you read it")
	var phone: Dictionary = StoryLibrary.DIALOGUES[&"prologue_phone"].nodes.a
	check(phone.text.contains("You coming out Friday? Everyone's asking."), "the words match the phone exactly")
	r.start(&"ch2_end")
	check(r.node_id == "both", "heard neither")
	check(r.text().contains(BeingLibrary.get_being(StoryLibrary.bid_pair().first).name), "names both (%s)" % r.text())
	GameState.set_flag(&"ch2_heard_first")
	r.start(&"ch2_end")
	check(r.node_id == "first", "the one you heard claims you")
	GameState.set_flag(&"ch2_heard_second")
	r.start(&"ch2_end")
	check(r.node_id == "both", "both bid: neither claims you")
	_play(&"ch2_end")
	check(GameState.has_flag(&"ch2_complete"), "chapter 2 complete")
	# The guild envoy.
	_fresh(18)
	var ruler := GameState.guilds.owner_of_floor(18)
	r.start(&"ch2_envoy")
	check(not r.text().contains("{"), "names the floor's guild (%s)" % r.text())
	var rep := GameState.guilds.rep_of(ruler)
	_play(&"ch2_envoy", 0)
	check(GameState.route.points_of(&"hero") == 3 and GameState.guilds.rep_of(ruler) > rep, "standing with them: Hero + standing")
	_fresh(18)
	var gold := GameState.player.gold
	_play(&"ch2_envoy", 1)
	check(GameState.route.points_of(&"villain") == 3 and GameState.player.gold == gold + 200, "selling out: Villain + gold")
	_fresh(18)
	rep = GameState.guilds.rep_of(ruler)
	_play(&"ch2_envoy", 2)
	check(GameState.route.points_of(&"vigilante") == 3 and GameState.guilds.rep_of(ruler) < rep, "telling them off: Vigilante, standing falls")
	# The return to the room.
	_fresh()
	check(StoryLibrary.return_due() == &"", "no return before floor 20's boss")
	GameState.player = GameState.make_premade("Tester", &"mage", { Stats.Type.INTELLIGENCE: 20 })
	GameState.player.class_id = &"pyromancer"
	check(StoryLibrary.return_due() == &"", "advancing doesn't bring it")
	GameState.player.class_id = &"mage"
	GameState.cleared_guardians.append(20)
	check(StoryLibrary.return_due() == StoryLibrary.RETURN_TIER2, "floor 20's boss does, whatever your class")
	var no_class := CharacterData.new()
	var kept_player := GameState.player
	GameState.player = no_class
	check(StoryLibrary.return_due() == StoryLibrary.RETURN_TIER2, "even with no class at all")
	GameState.player = kept_player
	var was_active := GameState.run_active
	GameState.run_active = false
	check(StoryLibrary.return_due() == &"", "not in the sandbox")
	GameState.run_active = was_active
	GameState.ng_plus_cycle = 1
	check(StoryLibrary.return_due() == &"", "New Game+ starts past it")
	GameState.ng_plus_cycle = 0
	GameState.set_flag(StoryLibrary.RETURN_TIER2)
	check(StoryLibrary.return_due() == &"", "once")
	var c := DialogueRunner.new()
	c.start(&"return_tier2_notebook")
	check(c.text().contains("floor 20"), "the notebook has a new page (%s)" % c.text())
	# The room in return mode keeps the run.
	GameState.current_slot = 1
	var name_before := GameState.player.character_name
	Prologue.mode = StoryLibrary.RETURN_TIER2
	var room: Prologue = load(Prologue.SCENE).instantiate()
	room.auto_leave = false
	var left := [false]
	room.return_finished.connect(func(): left[0] = true)
	add_child(room)
	await _frames(2)
	check(GameState.player.character_name == name_before and GameState.has_flag(StoryLibrary.RETURN_TIER2), "the run survives the room")
	check(not room._client.visible, "no test client this time")
	room.look_at_object(&"phone")
	check(room._dialogue.runner.dialogue_id == &"return_tier2_phone", "the phone has new messages")
	while room._dialogue.visible:
		room._dialogue.runner.advance()
		room._dialogue._refresh()
	check(not left[0], "looking around doesn't leave")
	room.look_at_object(&"pc")
	var cs := room._dialogue.runner.choices()
	check(cs.size() == 3, "the PC: log in, log off, not yet")
	room._dialogue.runner.choose(cs[1].index)
	room._dialogue._refresh()
	check(room._dialogue.runner.style() == "system" and room._dialogue.runner.text().contains("not available"), "you can't log off")
	check(GameState.has_flag(&"return_tier2_tried_logoff"), "and the game remembers you tried")
	room._dialogue.runner.advance()
	room._dialogue._refresh()
	room._dialogue.runner.choose(room._dialogue.runner.choices()[0].index)
	room._dialogue._refresh()
	check(not left[0], "the sync line plays first")
	room._dialogue.runner.advance()
	room._dialogue._refresh()
	check(left[0], "then you're back")
	check(Prologue.mode == Prologue.MODE_PROLOGUE, "the room resets")
	check(GameState.pending_talks.any(func(t): return t.dialogue == &"return_tier2_back"), "and the friend has words")
	GameState.pending_talks.clear()
	room.queue_free()
	await _frames(1)
	# The setting skips it.
	_fresh()
	GameState.player = GameState.make_premade("Tester", &"mage", { Stats.Type.INTELLIGENCE: 20 })
	GameState.cleared_guardians.append(20)
	var floor_scene: Node = load(GameState.TOWER_SCENE).instantiate()
	add_child(floor_scene)
	await _frames(2)
	GameState.set_flag(StoryLibrary.seen_flag(&"ch1_wake"))
	Settings.skip_prologue = true
	check(floor_scene.story_now(), "the return comes due on the floor")
	check(GameState.has_flag(StoryLibrary.RETURN_TIER2) and floor_scene.is_inside_tree(), "skipped by the setting")
	Settings.skip_prologue = false
	floor_scene.queue_free()
	await _frames(1)


func test_chapter_three() -> void:
	print("-- chapter 3 --")
	var ch3 := StoryLibrary.SCENES.values().filter(func(s): return s.chapter == 3 and not s.get("if", {}).get("god", false))
	var covered := {}
	for s in ch3:
		for f in s.floors:
			covered[f] = true
	check(covered.size() == StageLibrary.FLOORS_PER_STAGE, "a beat on every floor 21-30 (%s)" % [covered.keys()])
	_fresh()
	check(StoryLibrary.chapter_name(3) == "Chapter 3: What the Tower Sends", "its title")
	check(StoryLibrary.due(21, false) == &"ch3_opening", "floor 21 opens it")
	check(StoryLibrary.due(24, false) == &"", "floor 24 waits for the miniboss")
	check(StoryLibrary.due(24, true) == &"ch3_small_talk", "then the System makes small talk")
	check(StoryLibrary.due(30, false) == &"ch3_brace", "floor 30: bracing")
	GameState.set_flag(StoryLibrary.seen_flag(&"ch3_brace"))
	check(StoryLibrary.due(30, true) == &"ch3_end", "boss down: Marn at the fire")
	var r := DialogueRunner.new()
	r.start(&"ch3_opening")
	check(r.node_id == "a" and r.style() == "glitch", "the System speaks out of turn")
	GameState.set_flag(StoryLibrary.RETURN_TIER2)
	r.start(&"ch3_opening")
	check(r.node_id == "home", "it knows you went home")
	r.advance()
	check(r.text().contains("not sent"), "then something takes it back")
	# Trying to help.
	_fresh(22)
	var hp := GameState.player.current_hp()
	_play(&"ch3_warning", 0)
	check(GameState.has_flag(&"ch3_trusted_system") and GameState.player.current_hp() == hp, "trust it: no harm")
	_fresh(22)
	hp = GameState.player.current_hp()
	_play(&"ch3_warning", 1)
	check(GameState.has_flag(&"ch3_ignored_system") and GameState.player.current_hp() < hp and GameState.player.current_hp() > 0, "ignore it: it costs blood")
	check(GameState.route.points_of(&"hero") == 2, "but it was kind")
	# Lonely.
	_fresh(24)
	_play(&"ch3_small_talk", 1)
	check(GameState.has_flag(&"ch3_kind_to_system"), "it remembers you answered")
	# Marn.
	_fresh(26)
	_play(&"ch3_door", 0)
	check(GameState.has_flag(&"ch3_marn_fell") and GameState.has_flag(&"ch3_barred_door"), "you bar the door on him")
	_fresh(26)
	hp = GameState.player.current_hp()
	_play(&"ch3_door", 1)
	check(GameState.has_flag(&"ch3_marn_fell") and GameState.player.current_hp() < hp, "going in doesn't save him")
	_fresh(28)
	_play(&"ch3_doubt", 0)
	check(GameState.route.points_of(&"hero") == 4, "the vow leans a route")
	_fresh(28)
	_play(&"ch3_doubt", 1)
	check(GameState.route.points_of(&"vigilante") == 4, "another")
	_fresh(28)
	_play(&"ch3_doubt", 2)
	check(GameState.route.points_of(&"villain") == 4, "and another")
	_fresh(29)
	r.start(&"ch3_last_page")
	r.advance()
	check(r.text().contains("Tester"), "your name is in the ledger (%s)" % r.text())
	_fresh(30)
	_play(&"ch3_end")
	check(GameState.has_flag(&"ch3_complete"), "chapter 3 complete")
	var end_nodes: Dictionary = StoryLibrary.DIALOGUES[&"ch3_end"].nodes
	check(end_nodes.e.text == "[ I'm sorry. ]" and not end_nodes.f.text.contains("not sent"), "and this time nothing takes it back")


func test_chapter_four() -> void:
	print("-- chapter 4 --")
	var ch4 := StoryLibrary.SCENES.values().filter(func(s): return s.chapter == 4 and not s.get("if", {}).get("god", false))
	var covered := {}
	for s in ch4:
		for f in s.floors:
			covered[f] = true
	check(covered.size() == StageLibrary.FLOORS_PER_STAGE, "a beat on every floor 31-40 (%s)" % [covered.keys()])
	_fresh()
	check(StoryLibrary.chapter_name(4) == "Chapter 4: The Second Hand", "its title")
	check(StoryLibrary.due(31, false) == &"ch4_opening", "floor 31 opens it")
	check(StoryLibrary.due(34, false) == &"", "floor 34 waits for the miniboss")
	check(StoryLibrary.due(34, true) == &"ch4_comments", "then the old comments")
	# It remembers how you treated it.
	var r := DialogueRunner.new()
	r.start(&"ch4_opening")
	check(r.node_id == "kind", "you answered it")
	GameState.set_flag(&"ch3_asked_system")
	r.start(&"ch4_opening")
	check(r.node_id == "asked", "you asked who it is")
	GameState.set_flag(&"ch3_cold_to_system")
	r.start(&"ch4_opening")
	check(r.node_id == "cold", "you told it to leave")
	# The carving.
	_fresh(32)
	r.start(&"ch4_second_hand")
	check(r.node_id == "a", "first time you've looked")
	GameState.set_flag(&"ch1_saw_carving")
	r.start(&"ch4_second_hand")
	check(r.node_id == "known", "you've seen it on floor 8")
	_play(&"ch4_second_hand")
	check(GameState.has_flag(&"ch4_saw_second_hand") and GameState.has_flag(&"ch4_dummy"), "the second hand")
	var carving: String = StoryLibrary.DIALOGUES[&"ch1_carving"].nodes.b.text
	check(carving.contains("RECONGITION") and StoryLibrary.DIALOGUES[&"ch4_second_hand"].nodes.a.text.contains("RECONGITION"), "the same misspelling")
	# The initials follow the names you typed.
	GameState.start_new_game("Kai", "Juno", 1)
	GameState.enter_floor(34)
	r.start(&"ch4_comments")
	r.advance()
	r.advance()
	check(r.text().contains("- J") and r.text().contains("- K"), "both sets of initials (%s)" % r.text())
	check(r.text() == r.text().replace("{", ""), "filled in")
	# Marn, with or without the ledger.
	_fresh(35)
	r.start(&"ch4_marn")
	check(r.node_id == "skip", "he never fell: nothing to give back")
	GameState.set_flag(&"ch3_marn_fell")
	r.start(&"ch4_marn")
	check(r.node_id == "a" and r.choices().size() == 2, "the ledger: give or keep")
	_play(&"ch4_marn", 0)
	check(GameState.has_flag(&"ch4_gave_ledger"), "you gave it")
	# The gods don't know either.
	_fresh(36)
	var pair := StoryLibrary.bid_pair()
	r.start(&"ch4_expected")
	check(r.speaker() == BeingLibrary.get_being(pair.first).name and r.portrait_id() == String(pair.first), "this run's god speaks")
	_play(&"ch4_expected", 0)
	check(GameState.blessings.beings.get(pair.first, {}).get("bonus", 0) == 3, "asking pleases them")
	check(GameState.has_flag(&"ch4_expected"), "you were expected")
	# The ending isn't taken back.
	_fresh(40)
	_play(&"ch4_end")
	check(GameState.has_flag(&"ch4_complete"), "chapter 4 complete")
	var end_nodes: Dictionary = StoryLibrary.DIALOGUES[&"ch4_end"].nodes
	check(end_nodes.e.text == "[ I did the floors. ]" and end_nodes.c.text == "[ You drew the monsters. ]", "the last two lines")
	# The second return.
	_fresh()
	GameState.player = GameState.make_premade("Tester", &"mage", { Stats.Type.INTELLIGENCE: 20 })
	GameState.cleared_guardians.append(20)
	GameState.cleared_guardians.append(40)
	check(StoryLibrary.return_due() == StoryLibrary.RETURN_TIER2, "the first return comes first")
	GameState.set_flag(StoryLibrary.RETURN_TIER2)
	check(StoryLibrary.return_due() == StoryLibrary.RETURN_TIER3, "then the second, at floor 40")
	GameState.set_flag(StoryLibrary.RETURN_TIER3)
	check(StoryLibrary.return_due() == &"", "once each")
	GameState.cleared_guardians.erase(40)
	GameState.story_flags.erase(StoryLibrary.RETURN_TIER3)
	check(StoryLibrary.return_due() == &"", "floor 20 alone doesn't bring the second")
	GameState.cleared_guardians.append(40)
	GameState.ng_plus_cycle = 1
	check(StoryLibrary.return_due() != StoryLibrary.RETURN_TIER3, "first runs only")
	GameState.ng_plus_cycle = 0
	Prologue.mode = StoryLibrary.RETURN_TIER3
	var room: Prologue = load(Prologue.SCENE).instantiate()
	room.auto_leave = false
	var left := [false]
	room.return_finished.connect(func(): left[0] = true)
	add_child(room)
	await _frames(2)
	check(room.WRONG_TILES[StoryLibrary.RETURN_TIER3].size() > room.WRONG_TILES[StoryLibrary.RETURN_TIER2].size(), "the room is more wrong")
	room.look_at_object(&"pc")
	check(room._dialogue.runner.dialogue_id == &"return_tier3_pc" and room._dialogue.runner.text().contains("0041"), "the list of testers")
	room._dialogue.runner.advance()
	room._dialogue._refresh()
	check(room._dialogue.runner.text().contains("Tester 0001: R-"), "the first name, smudged (%s)" % room._dialogue.runner.text())
	room._dialogue.runner.advance()
	room._dialogue._refresh()
	room._dialogue.runner.choose(room._dialogue.runner.choices()[0].index)
	room._dialogue._refresh()
	room._dialogue.runner.advance()
	room._dialogue._refresh()
	check(left[0] and GameState.pending_talks.any(func(t): return t.dialogue == &"return_tier3_back"), "back, and the friend asks where you go")
	GameState.pending_talks.clear()
	room.queue_free()
	await _frames(1)


func test_chapter_five() -> void:
	print("-- chapter 5 --")
	var ch5 := StoryLibrary.SCENES.values().filter(func(s): return s.chapter == 5 and not s.get("if", {}).get("god", false))
	var covered := {}
	for s in ch5:
		for f in s.floors:
			covered[f] = true
	check(covered.size() == StageLibrary.FLOORS_PER_STAGE, "a beat on every floor 41-50 (%s)" % [covered.keys()])
	_fresh()
	check(StoryLibrary.chapter_name(5) == "Chapter 5: The Bidding War", "its title")
	check(StoryLibrary.due(41, false) == &"ch5_opening", "floor 41 opens it")
	check(StoryLibrary.due(50, false) == &"ch5_threshold", "floor 50: the gods wait")
	GameState.set_flag(StoryLibrary.seen_flag(&"ch5_threshold"))
	check(StoryLibrary.due(50, true) == &"ch5_choice", "boss down: the choice")
	# This run's gods.
	_fresh(42)
	var pair := StoryLibrary.bid_pair()
	var bonus := func(b: StringName) -> int: return GameState.blessings.beings.get(b, {}).get("bonus", 0)
	var r := DialogueRunner.new()
	r.start(&"ch5_camp")
	check(not r.text().contains("{") and r.text().contains(BeingLibrary.get_being(pair.first).name), "names this run's gods")
	r.advance()
	var labels: Array = r.choices().map(func(c): return c.text)
	check(labels[0].contains(BeingLibrary.get_being(pair.first).name) and labels[1].contains(BeingLibrary.get_being(pair.second).name), "the choices do too (%s)" % [labels])
	_play(&"ch5_camp", 0)
	check(bonus.call(pair.first) == 10 and bonus.call(pair.second) == -8, "taking a side moves real interest")
	_fresh(42)
	var hp := GameState.player.current_hp()
	_play(&"ch5_camp", 2)
	check(GameState.has_flag(&"ch5_stood_neither") and GameState.player.current_hp() < hp, "fighting both costs blood")
	_fresh(42)
	GameState.set_flag(&"godless_unlocked")
	GameState.player = GameState.make_premade("Heretic", &"warrior", { Stats.Type.STRENGTH: 12, Stats.Type.LUCK: 8 })
	GameState.take_secret_class(GameState.player, &"unsworn")
	r.start(&"ch5_camp")
	check(r.node_id == "godless", "the Unsworn get their own moment")
	# The friend, and the choice's consequences.
	_fresh(45)
	r.start(&"ch5_am_i_real")
	check(r.node_id == "a", "they've been drawing a door")
	r.advance()
	r.advance()
	check(r.text().contains("Am I real?") and r.choices().size() == 3, "they ask you straight")
	_play(&"ch5_am_i_real", 1)
	check(GameState.has_flag(&"ch5_friend_truth"), "you told them")
	r.start(&"ch5_with_you")
	check(r.node_id == "truth", "and they remember what you said")
	_fresh(49)
	GameState.set_flag(&"ch5_friend_lie")
	r.start(&"ch5_with_you")
	check(r.node_id == "lie", "the lie is remembered too")
	_fresh(46)
	r.start(&"ch5_break")
	r.advance()
	check(r.style() == "glitch" and r.speaker() == "Rowan", "their mouth, someone else's words")
	check(r.text().contains("IDIOT"), "the words only the real one would use")
	_play(&"ch5_break", 0)
	check(GameState.has_flag(&"ch5_break_heard"), "the System didn't mean for that")
	# The System stops taking it back.
	_fresh(44)
	r.start(&"ch5_stop_correcting")
	r.advance()
	r.advance()
	r.advance()
	check(r.text() == "[ Stop correcting me. ]", "it argues back")
	# The big choice.
	var routes := { 0: &"hero", 1: &"villain", 2: &"vigilante" }
	var endings := { &"hero": "hoped", &"villain": "still do the floors", &"vigilante": "Start with me" }
	for i in routes:
		_fresh(50)
		var last := DialogueRunner.new()
		last.start(&"ch5_choice")
		while not last.finished and not last.has_choices():
			last.advance()
		check(last.choices().size() == 3, "three ways to answer")
		last.choose(last.choices()[i].index)
		check(GameState.route.locked == routes[i], "it locks %s" % routes[i])
		check(GameState.companions.has(GameState.childhood_friend()), "your friend stays")
		check(GameState.has_flag(StringName("friend_mood_%s" % routes[i])), "and it changes them")
		var said := ""
		while not last.finished:
			said = last.text()
			last.advance()
		check(said.contains(endings[routes[i]]), "the System's reaction (%s)" % said)
		check(GameState.has_flag(&"ch5_complete"), "chapter 5 complete")
	_fresh(50)
	GameState.lock_route(&"villain")
	r.start(&"ch5_choice")
	while not r.has_choices():
		r.advance()
	check(r.choices().size() == 1, "already locked: nothing to choose")
	# Their personality shows.
	_fresh(41)
	r.start(&"ch5_opening")
	r.advance()
	r.advance()
	r.advance()
	var plain := r.node_id
	GameState.add_route_points(&"villain", 30)
	r.start(&"ch5_opening")
	r.advance()
	r.advance()
	r.advance()
	check(plain == "d" and r.node_id == "d_villain", "your friend sounds different on your route (%s, %s)" % [plain, r.node_id])
	# The shift, once per route.
	_fresh()
	GameState.add_route_points(&"hero", GameState.FRIEND_MOOD_POINTS - 1)
	check(not GameState.pending_talks.any(func(t): return t.dialogue == &"friend_shift_hero"), "not yet")
	GameState.add_route_points(&"hero", 1)
	check(GameState.pending_talks.any(func(t): return t.dialogue == &"friend_shift_hero"), "they notice it in themselves")
	GameState.pending_talks.clear()
	GameState.add_route_points(&"hero", 5)
	check(GameState.pending_talks.is_empty(), "once")
	check(not GameState.disagrees(GameState.childhood_friend()), "they never disagree enough to go")
	_fresh()
	GameState.dismiss(GameState.childhood_friend())
	GameState.add_route_points(&"villain", 20)
	check(not GameState.has_flag(&"friend_mood_villain"), "away at a fire: it waits")
	GameState.rejoin(GameState.childhood_friend())
	check(GameState.has_flag(&"friend_mood_villain"), "they catch up when they're back")


func _locked(route_id: StringName, floor_n: int) -> void:
	_fresh(floor_n)
	GameState.lock_route(route_id)
	GameState.pending_talks.clear()


func test_chapter_six() -> void:
	print("-- chapter 6 --")
	var ch6 := StoryLibrary.SCENES.values().filter(func(s): return s.chapter == 6 and not s.get("if", {}).get("god", false))
	var covered := {}
	for s in ch6:
		for f in s.floors:
			covered[f] = true
	check(covered.size() == StageLibrary.FLOORS_PER_STAGE, "a beat on every floor 51-60 (%s)" % [covered.keys()])
	_fresh()
	check(StoryLibrary.chapter_name(6) == "Chapter 6: The Top They Promised", "its title")
	check(StoryLibrary.due(51, false) == &"ch6_opening", "floor 51 opens it")
	# Each route has its own mission.
	var r := DialogueRunner.new()
	var nodes := { &"hero": "hero", &"villain": "villain", &"vigilante": "vigilante" }
	for route_id in nodes:
		_locked(route_id, 52)
		r.start(&"ch6_mission")
		check(r.node_id == nodes[route_id] and r.choices().size() == 2, "%s's mission" % route_id)
		r.start(&"ch6_cost")
		check(r.node_id == nodes[route_id] and r.choices().size() == 2, "%s's price" % route_id)
		for pick in 2:
			_locked(route_id, 52)
			check(_play(&"ch6_mission", pick).finished and _play(&"ch6_cost", pick).finished, "%s plays through (choice %d)" % [route_id, pick])
	_fresh(52)
	r.start(&"ch6_mission")
	check(r.node_id == "none", "a route that never locked still gets a line")
	_locked(&"hero", 52)
	var hp := GameState.player.current_hp()
	_play(&"ch6_mission", 0)
	check(GameState.has_flag(&"ch6_hero_long") and GameState.player.current_hp() < hp, "the long way down costs blood")
	_locked(&"villain", 52)
	var gold := GameState.player.gold
	_play(&"ch6_mission", 0)
	check(GameState.player.gold == gold + 600, "the treasury is yours")
	_locked(&"vigilante", 56)
	_play(&"ch6_cost", 0)
	check(GameState.has_flag(&"ch6_vigilante_finished_him"), "the list gets shorter")
	# The friend's personality.
	for route_id in nodes:
		_locked(route_id, 55)
		r.start(&"ch6_campfire")
		r.advance()
		check(r.node_id == "b_%s" % route_id, "at the fire, they sound like your %s (%s)" % [route_id, r.node_id])
	# Tester 0041: glimpses only.
	_fresh(54)
	r.start(&"ch6_warm_ashes")
	r.advance()
	check(r.text().contains("warm"), "a fire still warm")
	_play(&"ch6_warm_ashes")
	check(GameState.has_flag(&"ch6_saw_0041"), "their mark on the wall")
	check(not StoryLibrary.DIALOGUES[&"ch6_scratched"].nodes.values().any(func(n): return n.get("speaker", "") == "Tester 0041"), "no face yet")
	# Floor 60: false summit, then the confession.
	_fresh(60)
	check(StoryLibrary.due(60, false) == &"ch6_door", "the door first")
	GameState.set_flag(StoryLibrary.seen_flag(&"ch6_door"))
	check(StoryLibrary.due(60, true) == &"summit_false", "boss down: the false summit")
	GameState.set_flag(StoryLibrary.seen_flag(&"summit_false"))
	check(StoryLibrary.due(60, true) == &"ch6_confession", "then the System says it")
	for pick in 3:
		_fresh(60)
		r.start(&"ch6_confession")
		r.advance()
		check(r.text() == "[ It's me. ]", "it admits who it is")
		check(_play(&"ch6_confession", pick).finished, "it plays through (choice %d)" % pick)
		check(GameState.has_flag(&"ch6_complete"), "chapter 6 complete")
	r.start(&"ch6_confession")
	var said := ""
	while not r.finished:
		if r.has_choices():
			r.choose(r.choices()[1].index)
		said += r.text()
		r.advance()
	check(said.contains("You typed it"), "its name is the one you typed")
	check(said.contains("The one by the fire isn't me"), "and the friend isn't it")
	check(said.contains("Yes it was"), "and it won't be corrected")
	_fresh(60)
	GameState.ng_plus_cycle = 1
	GameState.set_flag(StoryLibrary.seen_flag(&"ch6_door"))
	GameState.set_flag(StoryLibrary.seen_flag(&"summit_false"))
	check(StoryLibrary.due(60, true) != &"ch6_confession", "New Game+ already knows")
	GameState.ng_plus_cycle = 0


func test_skip_warning() -> void:
	print("-- the skip setting warns --")
	Settings.skip_prologue = false
	var panel := SettingsPanel.new()
	add_child(panel)
	panel.open()
	await _frames(1)
	panel._skip_check.button_pressed = true
	check(panel._skip_warning.visible and not Settings.skip_prologue, "turning it on asks first")
	check(panel._skip_warning.dialog_text.contains("later story scenes"), "and says what you'd miss")
	panel._skip_warning.hide()
	panel._skip_warning.canceled.emit()
	check(not panel._skip_check.button_pressed and not Settings.skip_prologue, "Keep them: stays off")
	panel._skip_check.button_pressed = true
	panel._skip_warning.hide()
	panel._skip_warning.confirmed.emit()
	check(panel._skip_check.button_pressed and Settings.skip_prologue, "Skip them: on")
	panel._skip_check.button_pressed = false
	check(not Settings.skip_prologue and not panel._skip_warning.visible, "turning it off doesn't ask")
	panel.queue_free()
	await _frames(1)


func test_quest_log() -> void:
	print("-- chapter in the Quests log --")
	_fresh(3)
	var panel := QuestLogPanel.new()
	add_child(panel)
	panel.open()
	var label: Label = panel._list.get_node("Chapter")
	check(label.text == "Chapter 1: Tester", "chapter 1 on floor 3 (%s)" % label.text)
	panel.close()
	GameState.floor_number = 15
	panel.open()
	check(panel._list.get_node("Chapter").text.begins_with("Chapter 2"), "chapter 2 on floor 15")
	panel.queue_free()


## A conqueror's New Game+ through the real flow: clear the tower (with these
## flags set, blessed by `patron`), ascend into `domain`, start again.
## `domain` empty = a character who didn't take godhood.
func _ng(domain: StringName = &"mercy", flags: Array = [], patron: StringName = &"") -> LegacyRecord:
	SaveSerializer.delete_file(GameState.legacy_path)
	GameState.start_new_game("Climber", "Rowan", 1)
	for f in flags:
		GameState.set_flag(f)
	if patron != &"":
		GameState.player.bless(patron, 1)
	var rec := GameState.complete_run()
	if domain != &"":
		GameState.become_god(rec.legacy_id, domain)
	rec = GameState.load_legacy().find(rec.legacy_id)
	GameState.start_new_game_plus(rec, 1)
	return rec


## Walks every path through a dialogue (each choice, breadth-first by replay),
## calling `visit` on each node's filled text. Bounded so loops can't hang it.
func _walk(id: StringName, visit: Callable) -> void:
	var paths: Array = [[]]
	var guard := 0
	while not paths.is_empty() and guard < 200:
		guard += 1
		var path: Array = paths.pop_back()
		var r := DialogueRunner.new()
		r.start(id)
		var steps := 0
		for pick in path:
			r.choose(pick)
		while not r.finished and steps < 40:
			steps += 1
			visit.call(id, r)
			if r.has_choices():
				for c in r.choices():
					paths.append(path + [c.index])
				break
			r.advance()


func _unfilled_check(label: String) -> void:
	var bad: PackedStringArray = []
	var visit := func(id: StringName, r: DialogueRunner) -> void:
		for s in [r.text(), r.speaker(), r.portrait_id()] + r.choices().map(func(c): return c.text):
			if "{" in s or "}" in s:
				bad.append("%s/%s: %s" % [id, r.node_id, s])
	for id in StoryLibrary.DIALOGUES:
		_walk(id, visit)
	check(bad.is_empty(), "%s: no unfilled text %s" % [label, bad.slice(0, 5)])


func test_god_data() -> void:
	print("-- god storyline: data --")
	check(StoryLibrary.DOMAIN_LINES.size() == DomainLibrary.BASE_DOMAINS.size(), "every domain has its prayers")
	for pair in StoryLibrary.BID_PAIRS:
		for side in ["first_lines", "second_lines"]:
			check(StoryLibrary.NG_BID_LINES.all(func(k): return pair[side].has(k)), "%s %s: lines for meeting you again" % [pair.first, side])
	check(StoryLibrary.validate().is_empty(), "still validates (%s)" % [StoryLibrary.validate()])
	var god_scenes := StoryLibrary.SCENES.keys().filter(func(k): return String(k).begins_with("god_"))
	check(god_scenes.all(func(k): return StoryLibrary.SCENES[k].get("if", {}).has("god")), "every god scene needs a god")
	# First runs and mortals never get a god scene.
	_fresh()
	for k in god_scenes:
		check(not DialogueRunner.check(StoryLibrary.SCENES[k].if), "%s: not on a first run" % k) \
			if DialogueRunner.check(StoryLibrary.SCENES[k].if) else null
	check(StoryLibrary.due(3, false) == &"ch1_memory", "floor 3 first run: only the memory")
	check(StoryLibrary.due(25, false) != &"god_shrine", "floor 25 first run: no shrine")
	_ng(&"")
	check(not GameState.divinity.active, "a conqueror who refused godhood")
	GameState.set_flag(StoryLibrary.seen_flag(&"ch1_memory"))
	check(StoryLibrary.due(3, false) == &"", "no prayers for a mortal in New Game+")
	check(StoryLibrary.due(25, false) != &"god_shrine", "no shrine for a mortal either")
	_unfilled_check("a mortal in New Game+")
	# Every domain, every path: all tokens fill in, and every path ends.
	for domain in DomainLibrary.BASE_DOMAINS:
		_ng(domain)
		check(GameState.divinity.domain == domain, "%s: a god" % domain)
		_unfilled_check("%s" % domain)
	_fresh()
	_unfilled_check("a first run")


func test_memory() -> void:
	print("-- the gods remember --")
	var flags := [&"ch2_heard_first", &"ch2_refused_second", &"ch1_warned_tess", &"bid_pair_ra", &"ch2_tess_real"]
	var rec := _ng(&"valor", flags, &"odin")
	var saved := GameState.load_legacy().find(rec.legacy_id)
	for f in [&"past_heard_first", &"past_refused_second", &"past_warned_tess", &"bid_pair_ra", &"past_patron_odin"]:
		check(saved.past_flags.has(f), "the Hall keeps %s" % f)
		check(GameState.has_flag(f), "and New Game+ starts with it: %s" % f)
	check(saved.past_flags.any(func(f): return String(f).begins_with("past_ending_")), "and how it ended")
	check(not GameState.has_flag(&"ch2_heard_first") and not GameState.has_flag(&"ch2_tess_real"), "the run itself starts fresh")
	check(StoryLibrary.bid_pair().first == &"ra", "the same two gods come back")
	check(StoryLibrary.past_patron() == &"odin" and StoryLibrary.past_patron_voice() == "speaks", "the old patron")
	check(GameState.player.blessing_id == &"", "but the blessing itself is gone")
	# A tampered Hall can only add memories, never progress.
	check(StoryLibrary.is_past_flag("past_anything") and StoryLibrary.is_past_flag("bid_pair_odin"), "real memories")
	check(not StoryLibrary.is_past_flag("ch1_complete") and not StoryLibrary.is_past_flag(7), "anything else is refused")
	var d := SaveSerializer.read_json(GameState.legacy_path)
	d.records[0].past_flags = ["past_ok", "scene_ch1_wake", 12, "x".repeat(200)]
	SaveSerializer.write_json(GameState.legacy_path, d)
	var cleaned: Array[StringName] = GameState.load_legacy().records[0].past_flags
	check(cleaned.size() == 1 and cleaned[0] == &"past_ok", "a tampered Hall is cleaned on load (%s)" % [cleaned])
	# An old Hall with no memory still works.
	d.records[0].erase("past_flags")
	SaveSerializer.write_json(GameState.legacy_path, d)
	check(GameState.load_legacy().records[0].past_flags.is_empty(), "an older Hall file loads fine")
	# A second clear overwrites the memory with the newer climb.
	_ng(&"", [&"ch2_heard_second"])
	var again := GameState.complete_run()
	check(not again.past_flags.has(&"past_heard_second"), "the memory follows the latest climb")
	# Each ending has its tale at the shrine.
	var r := DialogueRunner.new()
	for tale in StoryLibrary.PAST_TALES:
		_ng(&"mercy")
		for f in GameState.story_flags.keys():
			if String(f).begins_with("past_ending_"):
				GameState.story_flags.erase(f)
		if tale != &"none":
			GameState.set_flag(StringName("past_ending_%s" % tale))
		r.start(&"god_shrine")
		r.advance()
		check(r.text().contains(StoryLibrary.PAST_TALES[tale]), "the shrine tells the %s tale" % tale)


func test_believers() -> void:
	print("-- believers --")
	_ng()
	var dv := GameState.divinity
	check(dv.believers == 0 and dv.faith == 0, "a god starts with nobody")
	dv.on_floor()
	check(dv.faith == 0, "no believers, no guild: no faith")
	_play(&"god_first_prayer", 0)
	check(dv.believers == 1 and dv.faith == 10 and GameState.has_flag(&"god_ilse_answered"), "answering Ilse: a believer and some faith")
	var before := dv.faith
	dv.on_floor()
	check(dv.faith == before + DivinityState.BELIEVER_FAITH, "each believer earns faith per floor")
	GameState.save_game()
	GameState.load_game(1)
	check(GameState.divinity.believers == 1, "believers are saved")
	dv = GameState.divinity
	_ng()
	dv = GameState.divinity
	_play(&"god_first_prayer", 1)
	check(dv.believers == 0 and dv.faith == 0 and GameState.has_flag(&"god_ilse_silent"), "silence earns nothing")
	dv.add_believers(-5)
	check(dv.believers == 0, "never below zero")
	dv.add_believers(7)
	dv.lose_half_believers()
	check(dv.believers == 3, "half of them stop")
	# Effects do nothing for anyone who isn't a god (and don't break).
	_fresh()
	_play(&"god_first_prayer", 0)
	check(GameState.divinity.believers == 0 and not GameState.divinity.active, "a first run can't gain believers")
	# The panel shows them.
	_ng()
	GameState.divinity.add_believers(4)
	var panel := DivinityPanel.new()
	add_child(panel)
	panel.open()
	check(panel._header.text.contains("Believers 4"), "Tab -> Divinity shows them (%s)" % panel._header.text)
	panel.queue_free()


func test_rewrites() -> void:
	print("-- chapters 1-2 change in New Game+ --")
	_ng()
	var r := DialogueRunner.new()
	r.start(&"ch1_wake")
	check(r.node_id == "god_a", "a god wakes differently")
	r.advance()
	r.advance()
	check(r.text().contains(GameState.divinity.title) and r.text().contains("Worshippers: 0"), "registered, zero worshippers (%s)" % r.text())
	GameState.ng_plus_cycle = 2
	r.start(&"ch1_wake")
	check(r.node_id == "god_cycle", "the second time round you've learned the sound of it")
	GameState.ng_plus_cycle = 1
	r.start(&"ch1_memory")
	check(r.node_id == "again", "you know the water tower story")
	_play(&"ch1_memory", 0)
	check(GameState.has_flag(&"ch1_memory_finished"), "you can finish it for them")
	r.start(&"ch1_slip")
	check(r.text().contains("Deities do not require grading"), "the System won't grade a god")
	r.start(&"ch1_carving")
	check(r.node_id == "again", "the carving: you look closer")
	r.start(&"ch2_friday")
	check(r.node_id == "again", "you were counting the floors to Friday")
	r.start(&"ch2_session")
	r.advance()
	check(r.text().contains("Tester 0042") and r.text().contains("Climb: 2"), "a second line in the session list (%s)" % r.text())
	r.start(&"ch2_end")
	check(r.node_id == "again", "chapter 2 ends differently")
	_play(&"ch2_end")
	check(GameState.has_flag(&"ch2_complete"), "and still completes")
	# Mortals get the rewrites, not the god lines.
	_ng(&"")
	r.start(&"ch1_wake")
	check(r.node_id == "again", "a mortal's New Game+ keeps the old wake-up")
	r.start(&"ch1_slip")
	check(r.node_id == "again" and not r.text().contains("Deities"), "not called a deity")
	r.start(&"ch1_end")
	check(r.node_id == "back", "no old patron: \"So you came back\"")
	r.advance()
	check(r.text().contains("came back"), "(%s)" % r.text())
	# Tess can be saved.
	_ng()
	r.start(&"ch1_legend")
	check(r.node_id == "again", "you know what's coming for her")
	_play(&"ch1_legend", 0)
	check(GameState.has_flag(&"ch1_warned_tess") and GameState.has_flag(&"ch1_met_tess"), "warned")
	r.start(&"ch1_fallen")
	check(r.node_id == "saved" and r.text().contains("scarf"), "she waited: the scarf on the rail")
	_play(&"ch1_fallen")
	check(GameState.has_flag(&"ch1_tess_turned_back") and not GameState.has_flag(&"ch1_tess_fell"), "she didn't fall")
	r.start(&"ch2_tess")
	check(r.node_id == "real", "the real Tess, frightened")
	_play(&"ch2_tess")
	check(GameState.has_flag(&"ch2_tess_real") and not GameState.has_flag(&"ch2_tess_returned"), "a different joke, and Marn saw it")
	var real: Dictionary = StoryLibrary.DIALOGUES[&"ch2_tess"].nodes
	check(real.real_scarf.text.contains("waited on the stairs") and real.marn_real2.text.contains("different joke"), "the joke really changed")
	_ng()
	_play(&"ch1_legend", 1)
	check(GameState.has_flag(&"ch1_kept_quiet"), "or you keep quiet")
	r.start(&"ch1_fallen")
	check(r.node_id == "knew", "and you knew")
	_play(&"ch1_fallen")
	check(GameState.has_flag(&"ch1_tess_fell"), "she falls")
	r.start(&"ch2_tess")
	check(r.node_id == "again", "she comes back wrong")
	r.advance()
	r.advance()
	check(r.text().contains("supposed to tell me something"), "and she almost remembers (%s)" % r.text())
	# You saved her last time, and the tower put her back.
	_ng(&"mercy", [&"ch1_warned_tess"])
	r.start(&"ch1_legend")
	check(r.node_id == "again_saved", "a later climb remembers saving her")
	# Bids remember what you said.
	_ng(&"mercy", [&"ch2_heard_first", &"ch2_refused_second", &"bid_pair_zeus"])
	var pair := StoryLibrary.bid_pair()
	r.start(&"ch2_first_bid")
	check(r.node_id == "re_yes" and r.text() == pair.first_lines.recall_yes, "the first remembers you listened")
	r.advance()
	check(r.text() == pair.first_lines.peer, "and talks to you as a peer")
	r.start(&"ch2_second_bid")
	check(r.node_id == "re_no" and r.text() == pair.second_lines.recall_no, "the second remembers you refused")
	_ng(&"", [&"ch2_refused_first", &"bid_pair_zeus"])
	r.start(&"ch2_first_bid")
	check(r.node_id == "re_no", "a mortal is remembered too")
	r.advance()
	check(r.text() == StoryLibrary.bid_pair().first_lines.mortal, "but isn't called a peer")
	var bonus := func(b: StringName) -> int: return GameState.blessings.beings.get(b, {}).get("bonus", 0)
	_ng(&"mercy", [&"bid_pair_ra"])
	var ra_was: int = bonus.call(&"ra")
	var apep_was: int = bonus.call(&"apep")
	_play(&"ch2_first_bid", 0)
	check(bonus.call(&"ra") == ra_was + 6 and bonus.call(&"apep") == apep_was - 2 and GameState.has_flag(&"ng_sided_first"), "hearing one out is real interest")
	# The old patron's voice after floor 10.
	_ng(&"mercy", [], &"odin")
	r.start(&"ch1_end")
	check(r.node_id == "old", "the one who blessed you remembers")
	r.advance()
	check(r.speaker() == "Odin" and r.portrait_id() == "odin" and r.text() == StoryLibrary.PATRON_REMEMBERS.god, "by name")
	var odin_was: int = bonus.call(&"odin")
	_play(&"ch1_end", 0)
	check(bonus.call(&"odin") == odin_was + 5 and GameState.has_flag(&"ch1_complete"), "thanking them warms them")
	_ng(&"mercy", [], &"odin")
	odin_was = bonus.call(&"odin")
	_play(&"ch1_end", 1)
	check(bonus.call(&"odin") == odin_was - 5, "refusing them cools them")


func test_god_scenes() -> void:
	print("-- the first prayer --")
	_ng()
	var r := DialogueRunner.new()
	check(StoryLibrary.due(3, false) == &"ch1_memory", "floor 3: the memory comes first")
	GameState.set_flag(StoryLibrary.seen_flag(&"ch1_memory"))
	check(StoryLibrary.due(3, false) == &"god_first_prayer", "then the first prayer")
	r.start(&"god_first_prayer")
	check(r.style() == "system" and r.text().contains("Prayer received"), "a System window")
	r.advance()
	check(r.text().contains(GameState.divinity.title) and r.text().contains("floor 12"), "she asks for you by title (%s)" % r.text())
	# Prayers change with the domain.
	_ng(&"vengeance")
	r.start(&"god_petition")
	r.advance()
	check(r.text() == StoryLibrary.DOMAIN_LINES[&"vengeance"].plea, "vengeance is asked for vengeance")
	_ng(&"mercy")
	r.start(&"god_petition")
	r.advance()
	check(r.text() == StoryLibrary.DOMAIN_LINES[&"mercy"].plea, "mercy is asked for mercy")
	_play(&"god_petition", 0)
	check(GameState.divinity.believers == 2 and GameState.route.points_of(&"hero") == 3, "granting it: believers, and your values' route")
	# Davin: three ways down.
	_ng()
	GameState.inventory.remove(&"potion", GameState.inventory.count(&"potion"))
	GameState.inventory.add(&"potion", 1)
	_play(&"god_davin", 0)
	check(GameState.has_flag(&"god_davin_saved") and GameState.inventory.count(&"potion") == 0, "searching costs a potion, and he lives")
	check(GameState.divinity.believers == 1, "he believes in someone now")
	check(DialogueRunner.check(StoryLibrary.SCENES[&"god_ilse_wrong"].if), "you never answered Ilse: she thanks someone else")
	GameState.set_flag(&"god_ilse_answered")
	check(DialogueRunner.check(StoryLibrary.SCENES[&"god_ilse_thanks"].if), "you did: she thanks you")
	_play(&"god_ilse_thanks")
	check(GameState.divinity.believers == 3, "and tells everyone")
	_ng()
	GameState.inventory.remove(&"potion", GameState.inventory.count(&"potion"))
	GameState.player.gold = 150
	var davin := DialogueRunner.new()
	davin.start(&"god_davin")
	davin.choose(davin.choices()[0].index)
	davin.advance()
	check(davin.choices().size() == 2, "no potion: gold or nothing")
	davin.choose(davin.choices()[0].index)
	check(GameState.player.gold == 50 and GameState.has_flag(&"god_davin_saved"), "100 gold carries him down")
	_ng()
	GameState.inventory.remove(&"potion", GameState.inventory.count(&"potion"))
	GameState.player.gold = 0
	davin.start(&"god_davin")
	davin.choose(davin.choices()[0].index)
	davin.advance()
	check(davin.choices().size() == 1, "nothing to give")
	davin.choose(davin.choices()[0].index)
	check(GameState.has_flag(&"god_davin_lost"), "and he doesn't make it")
	_ng()
	_play(&"god_davin", 1)
	check(GameState.has_flag(&"god_davin_lost") and not GameState.has_flag(&"god_davin_searched"), "or you walk on")
	r.start(&"god_heretic")
	check(r.node_id == "ilse", "floor 40: the prayer against you is hers")
	r.start(&"god_last_prayer")
	check(r.node_id == "bitter", "floor 55: and so is the last one")
	r.start(&"god_shrine")
	check(r.node_id == "stranger", "the shrine isn't hers")
	_ng()
	GameState.set_flag(&"god_davin_saved")
	r.start(&"god_shrine")
	check(r.node_id == "ilse", "she built the shrine")
	r.start(&"god_last_prayer")
	check(r.node_id == "unknown", "she never knew it was you")
	GameState.set_flag(&"god_ilse_answered")
	r.start(&"god_last_prayer")
	check(r.node_id == "thanks", "\"It was enough.\"")
	_ng()
	GameState.set_flag(&"god_plea_refused")
	r.start(&"god_heretic")
	check(r.node_id == "plea", "someone you refused complains")
	_ng()
	r.start(&"god_heretic")
	check(r.node_id == "stranger", "or a stranger does")
	_play(&"god_heretic", 2)
	check(GameState.divinity.faith == 20 and GameState.has_flag(&"god_heretic_smote"), "silencing them is easy, and pays")
	# The friend's prayer, and what follows from it.
	_ng()
	r.start(&"god_friend_prayer")
	r.advance()
	r.advance()
	check(r.speaker() == "Rowan" and r.text().contains("Climber"), "the friend prays about you, to you (%s)" % r.text())
	_play(&"god_friend_prayer", 0)
	check(GameState.has_flag(&"god_told_friend"), "you can tell them")
	r.start(&"ch2_threshold")
	check(r.node_id == "told_god", "and floor 20 changes")
	r.start(&"god_found_out")
	check(r.node_id == "ask", "floor 35: should they still pray?")
	_ng()
	_play(&"god_friend_prayer", 2)
	check(GameState.has_flag(&"god_silent_friend"), "or say nothing")
	r.start(&"god_found_out")
	check(r.node_id == "caught", "floor 35: they find out")
	_play(&"god_found_out")
	check(GameState.has_flag(&"god_friend_caught"), "and go quiet")
	# The reprisal: shield them or lose half.
	_ng()
	GameState.divinity.add_believers(6)
	GameState.divinity.faith = 50
	_play(&"god_reprisal", 0)
	check(GameState.divinity.believers == 6 and GameState.divinity.faith == 10 and GameState.has_flag(&"god_shielded"), "40 faith shields them")
	_ng()
	GameState.divinity.add_believers(6)
	GameState.divinity.faith = 39
	var rep := DialogueRunner.new()
	rep.start(&"god_reprisal")
	for i in 3:
		rep.advance()
	check(rep.choices().size() == 1, "not enough faith: you can only watch")
	rep.choose(rep.choices()[0].index)
	check(GameState.divinity.believers == 3 and GameState.divinity.faith == 39, "and half of them stop")
	# Whoever you didn't side with is the one who strikes.
	_ng(&"mercy", [&"bid_pair_odin"])
	check(StoryLibrary.foe_side() == "second", "sided with nobody: the tempter strikes")
	GameState.set_flag(&"ng_sided_second")
	check(StoryLibrary.foe_side() == "first", "side with them, and the other one does")
	r.start(&"god_reprisal")
	r.advance()
	r.advance()
	check(r.speaker() == "Odin" and r.portrait_id() == "odin" and r.text() == StoryLibrary.bid_pair().first_lines.strike, "by name")
	# The last offer.
	var bonus := func(b: StringName) -> int: return GameState.blessings.beings.get(b, {}).get("bonus", 0)
	_ng(&"mercy", [&"bid_pair_ra"])
	var ra_before: int = bonus.call(&"ra")
	var apep_before: int = bonus.call(&"apep")
	_play(&"god_last_offer", 0)
	check(bonus.call(&"ra") == ra_before + 15 and bonus.call(&"apep") == apep_before - 15 and GameState.divinity.faith == 60, "standing with one")
	_ng(&"mercy", [&"bid_pair_ra"])
	_play(&"god_last_offer", 2)
	check(GameState.divinity.believers == 2 and GameState.has_flag(&"god_allied_nobody"), "or with your own people")
	# The chaplain: not on your own floors.
	_ng()
	GameState.enter_floor(13)
	var ruler := GameState.guilds.owner_of_floor(13)
	check(DialogueRunner.check(StoryLibrary.SCENES[&"god_chaplain"].if), "a chaplain prays behind their patron's back")
	var patron := StoryLibrary.floor_patron()
	var rep_before := GameState.guilds.rep_of(ruler)
	var patron_before: int = bonus.call(patron)
	_play(&"god_chaplain", 0)
	check(GameState.guilds.rep_of(ruler) == rep_before + 5 and bonus.call(patron) == patron_before - 5 and GameState.divinity.faith == 20, "faith, standing, and an angry patron")
	GameState.divinity.contracts[ruler] = { "boon": &"wealth", "curse": &"burden", "stance": &"", "favor": 0, "since": 13, "warned": false }
	check(not DialogueRunner.check(StoryLibrary.SCENES[&"god_chaplain"].if), "no chaplain on a floor that's already yours")
	# The queue and the top: the System slips.
	_ng()
	r.start(&"god_queue")
	check(r.text() == "[ Prayers waiting: 11,302. ]", "the queue")
	_play(&"god_queue", 0)
	check(GameState.has_flag(&"god_saw_queue"), "it talks back")
	var top: Dictionary = StoryLibrary.DIALOGUES[&"god_top"].nodes
	check(top.pray4.style == "glitch" and top.pray4.text == "[ I heard that. ]", "who do gods pray to?")
	_play(&"god_top", 0)
	check(GameState.has_flag(&"god_prayed") and GameState.has_flag(&"god_arc_complete"), "you can try")
	_ng()
	_play(&"god_top", 1)
	check(GameState.has_flag(&"god_did_not_pray") and GameState.has_flag(&"god_arc_complete"), "or not")
	# All in order, floor by floor, for a god.
	_ng()
	var order := []
	for n in range(1, GameState.FINAL_FLOOR + 1):
		var guard := 0
		while guard < 10:
			guard += 1
			var id := StoryLibrary.due(n, true)
			if id == &"":
				break
			GameState.set_flag(StoryLibrary.seen_flag(id))
			order.append(id)
	var god_scenes := order.filter(func(i): return String(i).begins_with("god_"))
	check(god_scenes.back() == &"god_top", "the storyline ends on floor 100 (%s)" % [order.back()])
	check(order.find(&"god_first_prayer") < order.find(&"god_davin"), "Ilse asks before you reach Davin")
	check(order.find(&"god_friend_prayer") < order.find(&"god_found_out"), "the friend prays before they find out")


func test_ascend_return() -> void:
	print("-- the Ascending return --")
	_ng(&"")
	var p := GameState.player
	p.class_id = &"pyromancer"
	check(StoryLibrary.return_due() == &"", "New Game+, floor 40 not beaten: not yet")
	GameState.cleared_guardians.append(40)
	check(StoryLibrary.return_due() == StoryLibrary.RETURN_ASCEND, "floor 40's boss: the room, Ascended or not")
	GameState.set_flag(StoryLibrary.RETURN_ASCEND)
	check(StoryLibrary.return_due() == &"", "once a run")
	_fresh()
	GameState.player = GameState.make_premade("Tester", &"mage", { Stats.Type.INTELLIGENCE: 20 })
	GameState.set_flag(StoryLibrary.RETURN_TIER3)
	GameState.set_flag(StoryLibrary.RETURN_TIER2)
	GameState.cleared_guardians.append(40)
	check(StoryLibrary.return_due() != StoryLibrary.RETURN_ASCEND, "never on a first run")
	# The room: exactly as it was.
	_ng()
	GameState.player.ascended = true
	check(not Prologue.WRONG_TILES.has(StoryLibrary.RETURN_ASCEND), "no stone through the floor this time")
	var r := DialogueRunner.new()
	r.start(&"return_ascend_pc")
	r.advance()
	check(r.text().contains("Welcome back, Climber"), "the email knows your name (%s)" % r.text())
	var first: Dictionary = StoryLibrary.DIALOGUES[&"prologue_pc"].nodes.mail
	check(StoryLibrary.DIALOGUES[&"return_ascend_pc"].nodes.a.text == first.text, "the invitation, word for word")
	r.start(&"return_ascend_phone")
	check(r.node_id == "god", "a god's phone holds a prayer")
	r.advance()
	check(r.text().contains("Prayer received"), "(%s)" % r.text())
	_ng(&"")
	r.start(&"return_ascend_phone")
	check(r.node_id == "a" and r.text().contains("Friday"), "a mortal's holds only the first night's messages")
	r.start(&"return_ascend_notebook")
	r.advance()
	check(r.text().contains("ME."), "the last page")
	Prologue.mode = StoryLibrary.RETURN_ASCEND
	var room: Prologue = load(Prologue.SCENE).instantiate()
	room.auto_leave = false
	var left := [false]
	room.return_finished.connect(func(): left[0] = true)
	add_child(room)
	await _frames(2)
	check(GameState.player.character_name == "Climber", "the run survives the room")
	for obj in StoryLibrary.PROLOGUE_OBJECTS:
		room.look_at_object(obj)
		check(room._dialogue.runner.dialogue_id == StringName("return_ascend_%s" % obj), "%s: its own words" % obj)
		if obj != &"pc":
			while room._dialogue.visible:
				room._dialogue.runner.advance()
				room._dialogue._refresh()
		else:
			room._dialogue.runner.advance()
			room._dialogue._refresh()
			room._dialogue.runner.choose(room._dialogue.runner.choices()[1].index)
			room._dialogue._refresh()
			check(not left[0], "\"Not yet\" stays in the room")
	room.look_at_object(&"pc")
	room._dialogue.runner.advance()
	room._dialogue._refresh()
	room._dialogue.runner.choose(room._dialogue.runner.choices()[0].index)
	room._dialogue._refresh()
	room._dialogue.runner.advance()
	room._dialogue._refresh()
	check(left[0], "resuming the test takes you back")
	check(Prologue.mode == Prologue.MODE_PROLOGUE, "the room resets")
	check(GameState.pending_talks.any(func(t): return t.dialogue == &"return_ascend_back"), "and the friend has words")
	GameState.pending_talks.clear()
	room.queue_free()
	await _frames(1)


func test_god_chapters() -> void:
	print("-- a god's chapters --")
	_fresh()
	check(StoryLibrary.chapter_name(1) == "Chapter 1: Tester", "a first run: Tester")
	_ng(&"")
	check(StoryLibrary.chapter_name(3) == "Chapter 3: What the Tower Sends", "a mortal's New Game+: the normal chapters")
	_ng()
	check(StoryLibrary.chapter_name(1) == "Chapter 1: Nobody's God", "a god: their own")
	check(StoryLibrary.chapter_name(6) == "Chapter 6: The Last Prayer", "to the end")
	check(StoryLibrary.DIALOGUES[&"god_ch3"].nodes.a.text.contains(StoryLibrary.GOD_CHAPTERS[2].title), "chapter 3's window matches")
	check(StoryLibrary.DIALOGUES[&"god_ch4"].nodes.a.text.contains(StoryLibrary.GOD_CHAPTERS[3].title), "chapter 4's window matches")
	check(StoryLibrary.DIALOGUES[&"god_ch5"].nodes.a.text.contains(StoryLibrary.GOD_CHAPTERS[4].title), "chapter 5's window matches")
	check(StoryLibrary.DIALOGUES[&"god_ch6"].nodes.a.text.contains(StoryLibrary.GOD_CHAPTERS[5].title), "chapter 6's window matches")


## SENSITIVITY RULE: figures from living religions are only ever gods, and in
## this story never a speaking role: a past patron is a quiet presence at most.
func test_living_stay_silent() -> void:
	print("-- living-religion figures --")
	var living := BeingLibrary.SPECS.keys().filter(func(b): return BeingLibrary.get_being(b).get("living", false))
	check(not living.is_empty(), "there are some (%s)" % [living])
	for b in living:
		_ng(&"mercy", [], b)
		check(StoryLibrary.past_patron_voice() == "silent", "%s doesn't speak" % b)
		var r := DialogueRunner.new()
		r.start(&"ch1_end")
		check(r.node_id == "warm" and r.choices().is_empty(), "%s: only an old warmth" % b)
		_walk(&"ch1_end", func(_id, run: DialogueRunner) -> void:
			check(run.speaker() != BeingLibrary.get_being(b).name, "%s never speaks" % b) if run.speaker() == BeingLibrary.get_being(b).name else null)
	for pair in StoryLibrary.BID_PAIRS:
		for side in ["first", "second"]:
			check(not BeingLibrary.get_being(pair[side]).get("living", false), "%s can speak" % pair[side])
	# Your own past god never appears as your "old patron".
	_ng(&"mercy")
	GameState.set_flag(StringName(StoryLibrary.PAST_PATRON_PREFIX + String(GameState.divinity.god_id)))
	check(StoryLibrary.past_patron() == &"", "you aren't your own old patron")


## With the friend at a campfire they never speak in person in any scene: only
## from afar ("far", a prayer). ch1_wake plays before you can dismiss anyone.
func _friend_silent_check(label: String) -> void:
	var bad: PackedStringArray = []
	var visit := func(id: StringName, r: DialogueRunner) -> void:
		if id == &"ch1_wake" or id == StoryLibrary.FRIEND_REUNION:
			return
		if r.raw_speaker() == "{friend}" and not r._node().get("far", false):
			bad.append("%s/%s" % [id, r.node_id])
	for id in StoryLibrary.DIALOGUES:
		_walk(id, visit)
	check(bad.is_empty(), "%s: the friend isn't talking (%s)" % [label, bad])


func test_friend_away() -> void:
	print("-- the friend at a campfire --")
	_fresh()
	var friend := GameState.childhood_friend()
	check(not GameState.friend_away(), "a new run: they're with you")
	GameState.bench(friend)
	check(GameState.reserve.has(friend) and not GameState.friend_away(), "on the bench they still travel with you")
	GameState.dismiss(friend)
	check(GameState.friend_away(), "dismissed: away")
	_friend_silent_check("a first run")
	_unfilled_check("a first run, friend away")
	_fresh()
	var r := DialogueRunner.new()
	r.start(&"ch1_slip")
	r.advance()
	r.advance()
	check(r.raw_speaker() == "{friend}", "normally they ask if you said something")
	GameState.dismiss(GameState.childhood_friend())
	r.start(&"ch1_slip")
	r.advance()
	r.advance()
	check(r.node_id == "c_alone", "away: they don't")
	_play(&"ch1_slip")
	check(GameState.has_flag(&"ch1_slip_alone"), "the System notes it")
	# Flags other scenes rely on still get set.
	_play(&"ch1_legend")
	check(GameState.has_flag(&"ch1_met_tess"), "you still meet Tess")
	_play(&"ch1_fallen")
	check(GameState.has_flag(&"ch1_tess_fell"), "she still falls")
	_play(&"ch1_carving")
	check(GameState.has_flag(&"ch1_saw_carving"), "you still see the carving")
	_play(&"ch1_end")
	check(GameState.has_flag(&"ch1_complete"), "chapter 1 still completes")
	_play(&"ch2_tess", 1)
	check(GameState.has_flag(&"ch2_tess_returned"), "Tess still returns")
	_play(&"ch2_session")
	check(GameState.has_flag(&"ch2_saw_session"), "you still see the session")
	_play(&"ch2_end")
	check(GameState.has_flag(&"ch2_complete"), "chapter 2 still completes")
	# The words find another mouth.
	r.start(&"ch2_friday")
	check(r.node_id == "stranger" and r.text() == "You coming out Friday? Everyone's asking.", "a stranger says the phone message")
	_play(&"ch2_friday")
	check(GameState.has_flag(&"ch2_friday_stranger"), "remembered")
	r.start(&"ch2_threshold")
	check(r.node_id == "alone", "floor 20: going in without them")
	r.advance()
	check(r.style() == "glitch", "and the System says something")
	# Home: nobody says you were gone but the System.
	r.start(&"return_tier2_back")
	check(r.node_id == "alone", "back from the room: they aren't there")
	r.advance()
	check(r.text().contains("You were gone for a second there"), "the System says their line")
	# God runs: their prayer still reaches you.
	_ng()
	GameState.dismiss(GameState.childhood_friend())
	_friend_silent_check("a god")
	_unfilled_check("a god, friend away")
	_ng()   # the walks above answered every prayer
	GameState.dismiss(GameState.childhood_friend())
	r.start(&"god_friend_prayer")
	check(r.node_id == "a_far", "you hear them from a long way off")
	r.advance()
	r.advance()
	check(r.node_id == "c_far" and r.raw_speaker() == "{friend}" and r.text().contains("We don't travel together"), "the prayer knows (%s)" % r.text())
	_play(&"god_friend_prayer", 0)
	check(GameState.has_flag(&"god_told_friend") and GameState.divinity.believers == 1, "and can still be answered")
	r.start(&"god_found_out")
	check(r.node_id == "ask_far", "floor 35 by prayer")
	r.start(&"god_top")
	r.advance()
	check(r.node_id == "b_alone", "floor 60: their question, in your head")
	_play(&"god_top", 0)
	check(GameState.has_flag(&"god_arc_complete"), "the storyline still ends")
	_ng(&"")
	GameState.dismiss(GameState.childhood_friend())
	_friend_silent_check("a mortal in New Game+")
	# A route departure counts as away too.
	_fresh()
	GameState.leave_over_route(GameState.childhood_friend())
	check(GameState.friend_away(), "left over your route: away")
	# The reunion.
	_fresh()
	friend = GameState.childhood_friend()
	GameState.dismiss(friend)
	check(GameState.rejoin(friend) and GameState.pending_talks.any(func(t): return t.dialogue == StoryLibrary.FRIEND_REUNION), "rejoining brings a talk")
	GameState.pending_talks.clear()
	r.start(StoryLibrary.FRIEND_REUNION)
	check(r.node_id == "quick", "gone for no story at all: a joke")
	GameState.dismiss(friend)
	r.start(&"ch1_slip")
	r.advance()
	check(not GameState.has_flag(StoryLibrary.FRIEND_MISSED_FLAG), "the slip's first lines don't count")
	r.advance()
	check(GameState.has_flag(StoryLibrary.FRIEND_MISSED_FLAG), "missing a scene is remembered")
	GameState.rejoin(friend)
	GameState.pending_talks.clear()
	r.start(StoryLibrary.FRIEND_REUNION)
	check(r.node_id == "fire", "they kept your spot")
	_play(StoryLibrary.FRIEND_REUNION, 1)
	check(GameState.has_flag(&"friend_not_told") and GameState.has_flag(&"friend_reunited"), "\"Later\": remembered")
	check(not GameState.has_flag(StoryLibrary.FRIEND_MISSED_FLAG), "caught up on the count")
	r.start(&"ch2_threshold")
	check(r.node_id == "behind", "floor 20 remembers you didn't tell them")
	GameState.dismiss(friend)
	r.start(&"ch1_slip")
	r.advance()
	r.advance()
	GameState.rejoin(friend)
	GameState.pending_talks.clear()
	r.start(StoryLibrary.FRIEND_REUNION)
	check(r.node_id == "again", "the second time: you keep doing this")
	_fresh()
	friend = GameState.childhood_friend()
	GameState.set_flag(StoryLibrary.FRIEND_MISSED_FLAG)
	_play(StoryLibrary.FRIEND_REUNION, 0)
	check(GameState.has_flag(&"friend_caught_up"), "or you tell them everything")
	r.start(&"ch2_threshold")
	check(r.node_id == "caught_up", "and floor 20 knows that too")
	_fresh()
	GameState.set_flag(StoryLibrary.FRIEND_MISSED_FLAG)
	GameState.set_flag(&"route_left_childhood_friend")
	r.start(StoryLibrary.FRIEND_REUNION)
	check(r.node_id == "route", "they left over your route: glad and angry")
	# A later scene after they came back.
	_ng()
	GameState.set_flag(&"friend_reunited")
	GameState.set_flag(&"friend_not_told")
	r.start(&"god_found_out")
	r.advance()
	check(r.node_id == "caught2_back" and r.text().contains("weren't telling me"), "floor 35 remembers you never told them")
	r.start(&"god_friend_prayer")
	for i in 3:
		r.advance()
	check(r.node_id == "d_back" and r.text().contains("split up once"), "the prayer remembers too")
	_fresh()
	var alt := DialogueLibrary.validate(&"bad", { "start": "a", "nodes": { "a": { "text": "x", "alt": [{ "if": { "nonsense": true }, "node": "gone" }] } } })
	check(alt.size() == 2, "a broken alt fails validation (%s)" % [alt])


func test_glitch() -> void:
	print("-- glitch lines --")
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var line := "[ You remembered faster this time. ]"
	var s := DialogueBox.scramble(line, rng)
	check(s.length() == line.length() and s != line, "scrambled, same length")
	check(s.begins_with("[") and s.ends_with("]"), "brackets kept")
	_fresh()
	var box := DialogueBox.new()
	add_child(box)
	box.open(&"ch1_slip")
	check(box._text.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "System lines are centred")
	check(box._glitch != null, "a glitch line flickers")
	box.runner.advance()
	box._refresh()
	check(box._glitch == null and box._text.text == "[ Miniboss defeated. ]", "a plain System line doesn't")
	box.runner.advance()
	box._refresh()
	check(box._text.horizontal_alignment == HORIZONTAL_ALIGNMENT_LEFT, "normal lines go back to the left")
	box.queue_free()
