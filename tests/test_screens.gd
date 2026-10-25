extends Node
## Smoke tests for the real screens: opens the floor and battle scenes and
## drives the presentation hooks on them (system notices, a god's cut-in,
## a boss name card that holds the battle until it's done, the class-change
## cut-in). Catches runtime errors the data tests can't see.
## Run:  godot --headless res://tests/test_screens.tscn

var _passed := 0
var _failed := 0


func _ready() -> void:
	GameState.save_dir = "user://test_saves_screens"
	await test_floor_screen()
	await test_battle_screen()
	await test_captain_in_battle()
	await test_title_screen()
	await test_ascend_button()
	await test_big_party()
	await test_divinity_panel()
	CutIns.skip_all()
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


func _fresh(floor_n: int) -> void:
	GameState.reset_run()
	GameState.player = GameState.make_premade("Ophelius", &"rogue", { Stats.Type.AGILITY: 20, Stats.Type.LUCK: 15 })
	GameState.player.legacy_id = "screens-test"
	GameState.companions.append(GameState.make_childhood_friend("Cassia"))
	GameState.enter_floor(floor_n)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


## Tab: a top-tier line in NG+ gets an "Ascend" button; pressing it (and
## confirming) Ascends them and plays the cut-in.
func test_ascend_button() -> void:
	print("Ascend button")
	_fresh(5)
	CutIns.skip_all()
	GameState.ng_plus_cycle = 1
	GameState.highest_floor = 41
	var p := GameState.player
	while p.level < 50:
		p.level_up()
	p.class_id = ClassRegistry.get_tier(3).filter(func(d): return d.unique_to == &"")[0].id
	p._apply_class_bonus()
	var menu := PartyMenu.new()
	add_child(menu)
	menu.open()
	await _frames(2)
	var btns := menu.find_children("*", "Button", true, false).filter(func(b): return b.text == "✧ Ascend")
	check(btns.size() == 1 and not btns[0].disabled, "a tier-3 line in NG+ can Ascend from Tab")
	menu._confirm_ascend(p)
	var dlg: ConfirmationDialog = menu.find_children("*", "ConfirmationDialog", true, false)[-1]
	dlg.confirmed.emit()
	await _frames(1)
	check(p.ascended and CutIns.is_playing(), "confirming Ascends them, with a cut-in")
	CutIns.skip_all()
	menu.queue_free()
	GameState.ng_plus_cycle = 0
	await _frames(1)


## Floor 81+: 10 fight. Every card of a 10-vs-10 battle and the floor's party
## strip stay on the 1280x720 screen.
func test_big_party() -> void:
	print("A party of 10")
	get_tree().root.size = Vector2i(1280, 720)   # the design size (headless starts square)
	_fresh(81)
	CutIns.skip_all()
	while GameState.companions.size() < GameState.party_size() - 1:
		GameState.companions.append(GameState.make_premade("M%d" % GameState.companions.size(), &"tank",
			{ Stats.Type.HEALTH: 20, Stats.Type.STAMINA: 15 }))
	check(GameState.battle_party().size() == 10, "10 fight on floor 81")
	var ids: Array[StringName] = []
	for i in 10:
		ids.append(&"goblin")
	GameState.pending_encounter = EnemyLibrary.build_group(ids)
	GameState.pending_battle_info = { "kind": "normal" }
	GameState.return_scene = ""
	var battle_scene: Node = load(GameState.BATTLE_SCENE).instantiate()
	add_child(battle_scene)
	await _frames(3)
	var screen := get_viewport().get_visible_rect()
	var cards: Array = battle_scene.find_children("*", "UnitCard", true, false)
	var off := cards.filter(func(c): return not screen.encloses(c.get_global_rect().grow(-1)))
	check(screen.size == Vector2(1280, 720), "checked at 1280x720")
	check(cards.size() == 20 and off.is_empty(), "all 20 cards fit on screen (%d cards, %d off)" % [cards.size(), off.size()])
	battle_scene.queue_free()
	GameState.pending_battle_info = {}
	await _frames(1)
	var floor_scene: Node = load(GameState.TOWER_SCENE).instantiate()
	add_child(floor_scene)
	await _frames(3)
	var strip: Control = floor_scene._party_strip
	check(strip.get_child_count() == 10 and screen.encloses(strip.get_global_rect()), "the floor's party strip wraps and fits")
	floor_scene.queue_free()
	await _frames(1)


## A god's Tab menu: the Divinity button, the panel, sponsoring from it.
func test_divinity_panel() -> void:
	print("Divinity panel")
	_fresh(12)
	var dv := DivinityState.new()
	dv.active = true
	dv.domain = &"valor"
	dv.title = "God of Valor"
	dv.god_id = &"ascended_screens"
	dv.add_faith(200)
	GameState.divinity = dv
	dv.apply()
	var menu := PartyMenu.new()
	add_child(menu)
	menu.open()
	await _frames(2)
	check(menu._divinity_btn.visible, "a god has a Divinity button in Tab")
	menu._divinity_panel.open()
	await _frames(2)
	var sponsor: Array = menu._divinity_panel.find_children("*", "Button", true, false).filter(
		func(b): return b.text.begins_with("Sponsor") and not b.disabled)
	check(not sponsor.is_empty(), "guilds can be sponsored from it")
	sponsor[0].pressed.emit()
	await _frames(2)
	check(dv.others().size() == 1 and menu._divinity_panel.find_children("*", "OptionButton", true, false).size() >= 3,
		"the new contract shows its boon, curse and stance")
	menu.queue_free()
	GameState.reset_run()
	await _frames(1)


func test_floor_screen() -> void:
	print("Floor screen")
	_fresh(5)
	CutIns.skip_all()
	var floor_scene: Node = load(GameState.TOWER_SCENE).instantiate()
	add_child(floor_scene)
	await _frames(2)
	check(floor_scene.layout != null, "the floor loads")
	var shown_before: int = floor_scene._notices.get_child_count()
	GameState.quests.messages.append("Quest updated: Test — 1/3")
	GameState.guilds.messages.append("Tower news: Something happened.")
	await _frames(2)
	check(floor_scene._notices.get_child_count() == mini(shown_before + 2, SystemNotice.MAX_SHOWN)
		and GameState.quests.messages.is_empty(),
		"news shows up as system notices")
	floor_scene.talk(&"blessing_offer", null, &"odin")
	check(CutIns.is_playing() and floor_scene._dialogue.visible, "a god appearing plays its cut-in, then talks")
	CutIns.skip_all()
	floor_scene._show_toast("Floor 5 — Rest Floor")
	check(floor_scene._toast_panel.visible and floor_scene._toast.text.begins_with("Floor 5"), "toasts sit in a system window")
	floor_scene.queue_free()
	await _frames(1)


func test_battle_screen() -> void:
	print("Battle screen")
	_fresh(10)
	CutIns.skip_all()
	GameState.pending_encounter = EnemyLibrary.build_group(StageLibrary.boss_for_floor(10))
	GameState.pending_battle_info = { "kind": "boss" }
	GameState.return_scene = ""
	var battle_scene: Node = load(GameState.BATTLE_SCENE).instantiate()
	add_child(battle_scene)
	await _frames(1)
	check(CutIns.is_playing(), "a boss fight opens with its name card")
	check(battle_scene.battle.current == null, "...and the fight waits for it")
	CutIns.skip_all()
	await _frames(2)
	check(battle_scene.battle.current != null, "the fight starts after the card")
	var def := ClassRegistry.get_class_def(&"rogue")
	CutIns.play(CutInData.class_change(GameState.player, def, false))
	check(CutIns.is_playing(), "class-change cut-in plays over any screen")
	CutIns.skip_all()
	battle_scene.queue_free()
	GameState.pending_battle_info = {}
	await _frames(1)


func test_captain_in_battle() -> void:
	print("A guild captain in battle")
	_fresh(16)
	GameState.player.gold = 2000
	var gs := GameState.guilds
	gs.found_guild("Iron Climbers")
	gs.owners[4] = GuildLibrary.PLAYER_GUILD
	var friend := GameState.childhood_friend()
	GameState.bench(friend)
	gs.post_captain(friend, 4)
	GameState.floor_number = 13
	GameState.pending_encounter = EnemyLibrary.build_group([&"goblin", &"goblin"])
	GameState.pending_battle_info = { "kind": "normal" }
	GameState.return_scene = ""
	var battle_scene: Node = load(GameState.BATTLE_SCENE).instantiate()
	add_child(battle_scene)
	await _frames(2)
	var party: Array = battle_scene.battle.party
	check(party.size() == GameState.battle_party().size() + 1 and party.any(func(u): return u.source_character == friend),
		"on their floors, the captain fights with you")
	check(battle_scene._log.get_parsed_text().contains("Captain %s joins" % friend.character_name), "...and the log says so")
	battle_scene.queue_free()
	GameState.pending_battle_info = {}
	await _frames(1)


func test_title_screen() -> void:
	print("Title screen")
	var title: Node = load(GameState.TITLE_SCENE).instantiate()
	add_child(title)
	await _frames(1)
	var credits_btn = title.find_children("*", "Button", true, false).filter(func(b): return b.text == "Credits")
	check(credits_btn.size() == 1, "the title screen has a Credits button")
	title._credits.open("Tower Climber")
	check(title._credits.visible and title._credits._text.get_parsed_text().contains("Godot"), "credits open with Godot's notice")
	title._credits.close()
	title.queue_free()
	await _frames(1)
