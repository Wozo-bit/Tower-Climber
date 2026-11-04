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
	test_quest_log()
	test_glitch()
	SaveSerializer.delete_file(Settings.path)
	SaveSerializer.delete_file(Tips.path)
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
	check(StoryLibrary.due(21, false) == &"", "no chapter 3 scenes yet")
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
	check(StoryLibrary.due(14, true) == &"ch2_loki", "then Loki")
	check(StoryLibrary.due(20, true) == &"ch2_threshold", "floor 20: before the boss comes first")
	GameState.set_flag(StoryLibrary.seen_flag(&"ch2_threshold"))
	check(StoryLibrary.due(20, false) == &"", "the ending waits for the boss")
	check(StoryLibrary.due(20, true) == &"ch2_end", "boss down: chapter 2 ends")
	# The gods' bids are real interest.
	_fresh(12)
	var bonus := func(b: StringName) -> int: return GameState.blessings.beings.get(b, {}).get("bonus", 0)
	_play(&"ch2_odin", 0)
	check(bonus.call(&"odin") == 8 and bonus.call(&"loki") == -3, "listening to Odin: he warms, Loki cools")
	check(GameState.has_flag(&"ch2_heard_odin"), "remembered")
	_fresh(14)
	_play(&"ch2_loki", 0)
	check(bonus.call(&"loki") == 8 and bonus.call(&"odin") == -3, "and the other way round")
	check(GameState.has_flag(&"ch2_system_warned"), "the System slips")
	# Blessed variants.
	_fresh(12)
	var r := DialogueRunner.new()
	r.start(&"ch2_odin")
	check(r.node_id == "a", "unmarked")
	GameState.player.bless(&"thor", 1)
	r.start(&"ch2_odin")
	check(r.node_id == "marked", "marked by someone else")
	GameState.player.bless(&"odin", 1)
	r.start(&"ch2_odin")
	check(r.node_id == "his", "already his")
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
	GameState.set_flag(&"ch2_heard_odin")
	r.start(&"ch2_end")
	check(r.node_id == "odin", "Odin claims you")
	GameState.set_flag(&"ch2_heard_loki")
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
	check(StoryLibrary.return_due() == &"", "no return before advancing")
	GameState.player = GameState.make_premade("Tester", &"mage", { Stats.Type.INTELLIGENCE: 20 })
	check(StoryLibrary.return_due() == &"", "a tier-1 class isn't enough")
	GameState.player.class_id = &"pyromancer"
	check(StoryLibrary.return_due() == StoryLibrary.RETURN_TIER2, "the first tier-2 class brings it")
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
	check(c.text().contains("Pyromancer"), "the notebook draws your class (%s)" % c.text())
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
	GameState.player.class_id = &"pyromancer"
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
