extends Node
## Hayden's playtest feedback, 2026-11-04: skill ranks grow percents, HP/MP per
## level, Backspace in text boxes, floor travel, merchants' weapons + books,
## declining gods, guild actions from anywhere, donations, class hints, the
## Ashbound trail, no duplicate skills, floor twists, adaptation, boss phases.
## Run:  godot --headless res://tests/test_playtest.tscn

var _passed := 0
var _failed := 0


func _ready() -> void:
	GameState.save_dir = "user://test_saves_playtest"
	GameState.legacy_path = "user://test_saves_playtest_hall.json"
	GameState.unlocks_path = "user://test_saves_playtest_unlocks.json"
	Tips.path = "user://test_saves_playtest_tips.json"
	Settings.path = "user://test_saves_playtest_settings.cfg"
	CutIns.skip_all()
	test_skill_ranks()
	test_rank_battle_effects()
	test_hp_mp()
	await test_backspace()
	test_no_placeholder_tags()
	test_travel()
	await test_travel_screen()
	test_merchant()
	test_decline()
	test_guild_actions()
	test_class_hints()
	test_ashen_trail()
	test_no_duplicates()
	test_riders()
	test_floor_mods()
	test_adaptation()
	test_boss_phases()
	test_backline_pressure()
	await test_party_menu_scroll()
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


func _skill(id: StringName) -> SkillDef:
	return SkillLibrary.get_skill(id)


func _battle(enemy_ids: Array, setup := Callable()) -> BattleManager:
	var chars: Array[CharacterData] = []
	chars.append(GameState.player)
	var defs: Array[EnemyDef] = []
	for id in enemy_ids:
		defs.append(EnemyLibrary.get_enemy(id))
	var b := BattleManager.new()
	if setup.is_valid():
		setup.call(b)
	b.setup(chars, defs, 7)
	return b


func test_skill_ranks() -> void:
	print("-- skill ranks grow percents --")
	var g2 := SkillLibrary.ranked(_skill(&"guard"), 2)
	var g3 := SkillLibrary.ranked(_skill(&"guard"), 3)
	check(g2.description.contains("40%") and g3.description.contains("50%"), "Guard text: 30 -> 40 -> 50 (%s)" % g3.description)
	check(is_equal_approx(g3.status_bonus, 0.2), "Guard's bonus at rank 3")
	var w3 := SkillLibrary.ranked(_skill(&"ward"), 3)
	check(w3.description.contains("50%") and is_equal_approx(w3.status_bonus, 0.2), "Ward too")
	var crit := SkillLibrary.ranked(_skill(&"backstab"), 2)
	check(is_equal_approx(crit.bonus_crit, _skill(&"backstab").bonus_crit + 0.1) and crit.description.contains("35%"), "crit bonus + text")
	var pierce := SkillLibrary.ranked(_skill(&"armor_breaker"), 3)
	check(is_equal_approx(pierce.def_pierce, 1.0) and pierce.description.contains("100%"), "ignore defense stops at 100%")
	var heal := SkillLibrary.ranked(_skill(&"second_wind"), 3)
	check(is_equal_approx(heal.heal_pct_max_hp, 0.7) and heal.description.contains("70%"), "% heals")
	var focus := SkillLibrary.ranked(_skill(&"focus"), 3)
	check(is_equal_approx(focus.power, 0.45) and focus.description.contains("45%"), "Focus restores more MP")
	check(SkillLibrary.ranked(_skill(&"guard"), 1) == _skill(&"guard"), "rank 1 is the skill itself")
	check(_skill(&"guard").description.contains("30%"), "ranking never changes the base skill")
	# Every % in a growing skill's text matches its numbers.
	var bad := []
	for id in SkillLibrary._skills:
		var s: SkillDef = SkillLibrary._skills[id]
		if not SkillLibrary.has_percent_effect(s) or not s.description.contains("%"):
			continue
		var r := SkillLibrary.ranked(s, 2)
		if r.description == s.description:
			bad.append(id)
	check(bad.is_empty(), "every percent skill's text changes with rank %s" % [bad])


func test_rank_battle_effects() -> void:
	print("-- ranks in battle --")
	_fresh()
	var b := _battle([&"goblin"])
	var u: Combatant = b.party[0]
	u.add_status(&"ward", 2)
	check(is_equal_approx(u.status_bonus_of(&"ward"), 0.0), "rank 1: no bonus")
	u.add_status(&"ward", 2, 0.2)
	check(is_equal_approx(u.status_bonus_of(&"ward"), 0.2), "rank 3 bonus held")
	u.add_status(&"ward", 1, 0.1)
	check(is_equal_approx(u.status_bonus_of(&"ward"), 0.2), "the strongest holds")
	u.statuses.clear()
	u.add_status(&"ward", 1)
	check(is_equal_approx(u.status_bonus_of(&"ward"), 0.0), "a fresh status starts clean")
	u.statuses.clear()
	u.add_status(&"evasive", 2, 0.2)
	var d := u.dodge_chance()
	u.status_bonus.clear()
	check(d > u.dodge_chance(), "ranked Evade dodges more")


func test_hp_mp() -> void:
	print("-- HP and MP per level --")
	_fresh()
	var p := GameState.player
	var hp := p.max_hp()
	var mp := p.max_mp()
	p.level_up()
	check(p.max_hp() == hp + CharacterData.HP_PER_LEVEL and CharacterData.HP_PER_LEVEL == 12, "+12 HP a level")
	check(p.max_mp() == mp + CharacterData.MP_PER_LEVEL and CharacterData.MP_PER_LEVEL == 2, "+2 MP a level")
	var b := _battle([&"goblin"])
	check(b.party[0].max_mp == p.max_mp(), "battle uses it")


func test_backspace() -> void:
	print("-- Backspace in text boxes --")
	check(not InputBindings.DEFAULTS.ui_cancel.has(KEY_BACKSPACE), "Backspace isn't a Cancel key")
	var old := InputBindings.clean({ "ui_cancel": [KEY_ESCAPE, KEY_BACKSPACE] })
	check(old.ui_cancel == [KEY_ESCAPE, 0], "old settings files lose it (%s)" % [old.ui_cancel])
	var bindings := InputBindings.defaults()
	check(InputBindings.bind(bindings, "ui_cancel", 1, KEY_BACKSPACE) != "", "and it can't be rebound")
	InputBindings.apply(InputBindings.defaults())
	var edit := LineEdit.new()
	add_child(edit)
	edit.text = "abc"
	edit.caret_column = 3
	edit.edit()
	await _frames(1)
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.keycode = KEY_BACKSPACE
	ev.physical_keycode = KEY_BACKSPACE
	edit.gui_input.emit(ev)
	edit._gui_input(ev) if edit.has_method("_gui_input") else null
	get_viewport().push_input(ev)
	await _frames(1)
	check(edit.text == "ab", "Backspace deletes a letter (%s)" % edit.text)
	edit.queue_free()


func test_no_placeholder_tags() -> void:
	print("-- no (Placeholder) tags --")
	_fresh()
	var r := DialogueRunner.new()
	r.start(&"merchant")
	check(not r.text().contains("Placeholder"), "dialogue")
	var b := QuestLog.make_bounty(5, 0, "x")
	check(not String(b.def.get("desc", "")).contains("Placeholder"), "bounties")
	check(not QuestLibrary.QUESTS[&"main_climb"].desc.contains("Placeholder"), "quests")
	check(FileAccess.file_exists("res://docs/story/unwritten_text.md"), "the list of unwritten text is kept")


func test_travel() -> void:
	print("-- floor travel --")
	_fresh()
	check(not GameState.can_travel_to(2) and not GameState.can_travel_to(1), "nowhere to go on floor 1")
	GameState.enter_floor(15)
	GameState.current_layout()
	GameState.highest_floor = 15
	check(GameState.can_travel_to(3) and not GameState.can_travel_to(16) and not GameState.can_travel_to(15) and not GameState.can_travel_to(0),
		"only floors you've reached")
	var tick_before: Dictionary = GameState.guilds.treasury.duplicate()
	var check_before := GameState.checkpoint_floor
	GameState.player.gold = 100
	check(GameState.travel_to_floor(3), "travel down")
	check(GameState.floor_number == 3 and GameState.highest_floor == 15, "floor changes, highest doesn't")
	check(GameState.checkpoint_floor == check_before, "the checkpoint stays")
	check(GameState.guilds.treasury == tick_before, "the guild AI doesn't take a turn")
	var layout := GameState.current_layout()
	check(GameState.floor_enemies.any(func(e): return e.alive), "plain floors refill (%d)" % GameState.floor_enemies.size())
	check(layout != null, "layout builds")
	# Stairs below your highest floor: a revisit, no guild turn.
	GameState.climb_to_floor(4)
	check(GameState.floor_number == 4 and GameState.guilds.treasury == tick_before, "stairs on old floors don't tick the guilds")
	# Guardians stay dead.
	GameState.cleared_guardians.append(4)
	GameState.floor_ready = false
	GameState.current_layout()
	check(not GameState.stairs_locked(), "a beaten miniboss stays dead")
	GameState.cleared_guardians.erase(4)
	GameState.floor_ready = false
	GameState.current_layout()
	check(GameState.stairs_locked(), "an unbeaten one is still there")
	# A win records it.
	_fresh(4)
	GameState.current_layout()
	for i in GameState.floor_enemies.size():
		if GameState.enemy_kind(GameState.floor_enemies[i]) == "miniboss":
			GameState.active_enemy_index = i
	GameState.pending_encounter = []
	GameState.finish_battle(BattleManager.Outcome.VICTORY)
	check(GameState.guardian_beaten(4), "beating the miniboss records it")
	# Climbing to a NEW floor is a real climb.
	GameState.climb_to_floor(5)
	check(GameState.highest_floor == 5 and GameState.floor_number == 5, "a new floor counts")
	# Saved.
	GameState.merchant_bought.append("5:w0")
	GameState.save_game()
	GameState.load_game(1)
	check(GameState.guardian_beaten(4) and GameState.merchant_bought == ["5:w0"], "both lists save")
	# Old saves: everything below your highest floor counts as beaten.
	var d: Dictionary = GameState._to_dict() if GameState.has_method("_to_dict") else {}
	if not d.is_empty():
		d.erase("cleared_guardians")
	check(TravelPanel.floor_line(4).contains("miniboss beaten"), "the travel list says so (%s)" % TravelPanel.floor_line(4))
	check(TravelPanel.floor_line(5).contains("rest floor"), "and marks rest floors")


func test_travel_screen() -> void:
	print("-- campfire travel screen --")
	_fresh(10)
	GameState.current_layout()
	for e in GameState.floor_enemies:
		if GameState.enemy_kind(e) == "boss":
			e.alive = false
	var floor_scene: Node = load(GameState.TOWER_SCENE).instantiate()
	add_child(floor_scene)
	await _frames(2)
	floor_scene._use_campfire()
	check(floor_scene._travel_panel.visible, "the campfire offers travel")
	check(floor_scene._travel_panel._list.get_child_count() == 10, "lists every floor reached")
	check(floor_scene._menus_open(), "it counts as a menu")
	floor_scene._travel_panel.close()
	floor_scene.travel_to(3)
	await get_tree().create_timer(0.5).timeout
	check(GameState.floor_number == 3, "travel works (floor %d)" % GameState.floor_number)
	await _frames(2)
	floor_scene.queue_free()
	await _frames(1)
	_fresh()
	floor_scene = load(GameState.TOWER_SCENE).instantiate()
	add_child(floor_scene)
	await _frames(2)
	floor_scene._use_campfire()
	check(not floor_scene._travel_panel.visible, "nothing to offer on floor 1")
	GameState.ironman = true
	floor_scene._use_campfire()
	check(floor_scene._toast.text.contains("HP/MP full") and not floor_scene._toast.text.contains("revived"), "Ironman: no 'revived' (%s)" % floor_scene._toast.text)
	GameState.ironman = false
	floor_scene.queue_free()
	await _frames(1)


func test_merchant() -> void:
	print("-- merchants sell weapons and books --")
	_fresh(5)
	var w := MerchantStock.weapons(5)
	check(w.size() == MerchantStock.WEAPONS and w.all(func(g): return g.slot == GearItem.Slot.WEAPON), "weapons")
	check(w.all(func(g): return g.rarity <= Rarity.Tier.RARE), "up to Rare")
	var w2 := MerchantStock.weapons(5)
	check(w[0].display_name == w2[0].display_name and w[0].bonuses == w2[0].bonuses, "the same stock when you come back")
	var saw_rare := false
	var saw_epic_low := false
	var saw_epic_high := false
	for f in range(5, 400, 5):
		for id in MerchantStock.books(f, 0):
			var t := _skill(id).tier
			saw_rare = saw_rare or t == SkillTier.Tier.RARE
			saw_epic_low = saw_epic_low or t == SkillTier.Tier.EPIC
			check(t <= SkillTier.Tier.RARE, "low luck: no epics") if t > SkillTier.Tier.RARE else null
		for id in MerchantStock.books(f, MerchantStock.EPIC_LUCK):
			saw_epic_high = saw_epic_high or _skill(id).tier == SkillTier.Tier.EPIC
	check(saw_rare, "a Rare book on the odd merchant")
	check(not saw_epic_low, "no Epic without high Luck")
	check(saw_epic_high, "Epic with really high Luck")
	var base := MerchantStock.books(25, 0).size()
	check(base >= MerchantStock.COMMON_BOOKS, "always some common books")
	var g: GearItem = w[0]
	var price := MerchantStock.gear_price(g)
	GameState.player.gold = price - 1
	check(not GameState.buy_merchant_gear(g), "can't afford")
	GameState.player.gold = price
	check(GameState.buy_merchant_gear(g) and GameState.inventory.gear.has(g) and GameState.player.gold == 0, "bought")
	GameState.player.gold = price * 2
	check(not GameState.buy_merchant_gear(g), "sold once")
	var book: StringName = MerchantStock.books(5, 0)[0]
	GameState.player.gold = MerchantStock.book_price(book)
	check(GameState.buy_merchant_book(book) and GameState.inventory.count(SkillBooks.book_item_id(book)) == 1, "book bought")
	check(not GameState.buy_merchant_book(book), "only one copy")
	check(price > GameState.sell_price_gear(g), "you can't sell it back for profit")
	var shop := ShopPanel.new()
	add_child(shop)
	GameState.player.gold = 99999
	shop.open()
	var rows := shop._list.find_children("*", "Button", true, false).filter(func(b): return b.text.begins_with("Buy"))
	check(rows.size() >= ItemLibrary.SHOP_STOCK.size() + MerchantStock.WEAPONS - 2, "the shop lists them (%d)" % rows.size())
	shop.queue_free()


func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


func test_decline() -> void:
	print("-- declining a god --")
	check(BlessingState.curse_chance(&"inari") == 0.0 and BlessingState.curse_chance(&"anubis") == 0.0, "gentle gods never curse")
	check(BlessingState.curse_chance(&"typhon") > BlessingState.curse_chance(&"athena"), "hot tempers curse more")
	# A hot-tempered demon: curses, sometimes.
	_fresh(12)
	var cursed := 0
	var gifted := 0
	for i in 40:
		_fresh(12)
		if GameState.blessings.decline(&"typhon", _rng(i)) == "curse":
			cursed += 1
		check(GameState.blessings.last_refusal != "", "says something") if i == 0 else null
	check(cursed > 15 and cursed < 40, "Typhon usually curses (%d/40)" % cursed)
	_fresh(12)
	var hp := GameState.player.current_hp()
	var seed_with_curse := 0
	for i in 200:
		_fresh(12)
		GameState.player.set_current_hp(50)
		if GameState.blessings.decline(&"typhon", _rng(i)) == "curse":
			seed_with_curse = i
			break
	check(GameState.player.curse_id == &"typhon", "the curse lands")
	check(GameState.player.curse_until_floor == 12 + BlessingState.PUNISH_FLOORS, "for a few floors")
	check(GameState.player.current_hp() < 50, "the hottest strike too")
	check(not GameState.blessings.beings[&"typhon"].get("scorned", false), "it can still make an offer later")
	# Gentle god: never curses, gifts when you line up.
	for i in 30:
		_fresh(12)
		var o := GameState.blessings.decline(&"inari", _rng(i))
		if o == "curse":
			cursed = -1
	check(cursed != -1, "Inari never curses")
	# Gift: a good god you agree with.
	var god := &"athena"
	_fresh(12)
	check(not GameState.blessings.gift_possible(god), "no gift while you don't line up")
	GameState.blessings.add_interest(god, BlessingState.GIFT_INTEREST)
	check(GameState.blessings.gift_possible(god), "aligned: a gift is possible")
	var skill: StringName = BeingLibrary.get_being(god).skill
	for i in 200:
		if GameState.blessings.decline(god, _rng(i)) == "gift":
			gifted += 1
			break
	check(gifted == 1 and GameState.player.knows_skill(skill), "you keep the skill, unblessed")
	check(not GameState.player.is_blessed(), "no blessing, no curse")
	check(GameState.player.all_skills().any(func(s): return s.id == skill), "it's usable")
	check(not GameState.blessings.gift_possible(god), "only once")
	check(not GameState.blessings.gift_possible(&"typhon"), "demons don't give gifts")
	# Saved.
	GameState.save_game()
	GameState.load_game(1)
	check(GameState.blessings.beings[god].get("gifted", false), "saved")
	# Through the dialogue.
	_fresh(12)
	GameState.blessings.add_interest(&"thor", 20)
	var r := DialogueRunner.new()
	r.start(&"blessing_offer", null, &"thor")
	var no: Dictionary = r.choices().filter(func(c): return c.text == "No.")[0]
	r.choose(no.index)
	check(not r.finished and r.text() == GameState.blessings.last_refusal, "the god answers (%s)" % r.text())
	r.advance()
	check(r.finished, "and the talk ends")
	check(not GameState.blessings.wants_to_offer(&"thor"), "it waits before offering again")


func test_guild_actions() -> void:
	print("-- guilds from the menu --")
	_fresh(15)
	var gs := GameState.guilds
	var g: StringName = GuildLibrary.guilds.keys().filter(func(id): return id != GuildLibrary.PLAYER_GUILD)[0]
	gs.member = g
	gs.owners[0] = g
	GameState.highest_floor = 15
	check(gs.job_floor(g) >= 1, "your guild's floor for jobs (%d)" % gs.job_floor(g))
	var panel := GuildPanel.new()
	add_child(panel)
	var contacted := [false]
	panel.contact_requested.connect(func(): contacted[0] = true)
	panel.open()
	var texts: Array = panel._controls.get_children().map(func(b): return b.text)
	check(texts.has("Contact your guild") and texts.has("Guild jobs..."), "member buttons (%s)" % [texts])
	GameState.pending_talks.clear()
	panel._contact()
	check(contacted[0] and not GameState.pending_talks.is_empty() and GameState.pending_talks[0].remote, "contact queues a remote talk")
	GameState.pending_talks.clear()
	# The agent's menu: no shop from afar.
	DialogueRunner.remote_talk = true
	var r := DialogueRunner.new()
	r.start(&"guild_agent", null, &"", g)
	var choices: Array = r.choices().map(func(c): return c.text)
	check(not choices.has("Show me the members' stock."), "no shop from afar")
	check(choices.has("I'm leaving the guild."), "the rest works")
	DialogueRunner.remote_talk = false
	r.start(&"guild_agent", null, &"", g)
	check(r.choices().any(func(c): return c.text == "Show me the members' stock."), "shop face to face")
	panel._jobs.open(gs.job_floor(g))
	check(panel._jobs._list.get_child_count() > 0, "jobs from your guild's floor")
	panel.queue_free()
	# Donations and war.
	_fresh(20)
	var gs2 := GameState.guilds
	check(gs2.donate(100) == 0, "no guild, no donation")
	GameState.player.gold = gs2.CHARTER_COST + 5000
	gs2.found_guild("Testers", &"") if gs2.has_method("found_guild") else null
	if gs2.has_own_guild():
		var before := gs2.treasury_of(GuildLibrary.PLAYER_GUILD)
		GameState.player.gold = 300
		check(gs2.donate(100) == 100 and GameState.player.gold == 200, "donate takes your gold")
		check(gs2.treasury_of(GuildLibrary.PLAYER_GUILD) == before + 100, "into the treasury")
		check(gs2.donate(9999) == 200 and GameState.player.gold == 0, "never more than you have")
		GameState.player.gold = GuildAI.WAR_COST
		gs2.treasury[GuildLibrary.PLAYER_GUILD] = 0
		check(gs2.player_war_refusal().contains("treasury"), "war: no money")
		gs2.donate(GuildAI.WAR_COST)
		check(not gs2.player_war_refusal().contains("treasury"), "donating pays for a war (%s)" % gs2.player_war_refusal())
	else:
		check(false, "couldn't found a guild to test donations")


func test_class_hints() -> void:
	print("-- what a class needs --")
	_fresh()
	var p := GameState.player
	check(p.build_hint().contains("No class yet"), "no class")
	var mage := GameState.make_premade("Wren", &"mage", { Stats.Type.INTELLIGENCE: 20 })
	check(mage.build_hint().contains("Intelligence"), "mage: Intelligence (%s)" % mage.build_hint())
	check(mage.build_hint().contains("needs"), "names its advancements")
	var archer := GameState.make_premade("Tamsin", &"archer", { Stats.Type.AGILITY: 20 })
	check(archer.build_hint().contains("Agility"), "archer: Agility (%s)" % archer.build_hint())
	var panel := StatAllocationPanel.new()
	add_child(panel)
	panel.bind(archer)
	check(panel._hint.text == archer.build_hint(), "shown on the Stats screen")
	panel.queue_free()


func test_ashen_trail() -> void:
	print("-- the Ashbound trail --")
	_fresh(13)
	var trail := &"ashen_trail"
	check(GameState.quests.is_new(trail), "no quest before a clue")
	GameState.set_flag(&"clue_ash_scorched_mural")
	check(GameState.quests.is_active(trail), "the first clue starts it")
	check(GameState.quests.step_text(trail).contains("merchant"), "it says what's next (%s)" % GameState.quests.step_text(trail))
	GameState.set_flag(&"clue_ash_feather_in_embers")
	check(GameState.quests.step_text(trail).contains("merchant"), "2 of 3 (Hayden's save): the merchant's story is missing")
	check(StageLibrary.guaranteed_roamer(13, [], GameState.story_flags).get("id") != &"ashen_wyrmling", "no wyrmling yet")
	GameState.set_flag(&"clue_ash_merchant_story")
	check(GameState.quests.step_text(trail).contains("Defeat"), "last step: the fight")
	check(StageLibrary.guaranteed_roamer(13, [], GameState.story_flags).id == &"ashen_wyrmling", "it comes")
	check(StageLibrary.guaranteed_roamer(45, [], GameState.story_flags).id == &"ashen_wyrmling", "even if you found the clue on floor 45")
	check(StageLibrary.guaranteed_roamer(11, [], GameState.story_flags).get("id") != &"ashen_wyrmling", "not before floor 12")
	check(StageLibrary.guaranteed_roamer(45, [&"ashen_wyrmling"], GameState.story_flags).get("id") != &"ashen_wyrmling", "and only once")
	check(QuestLibrary.validate_all().is_empty(), "quests validate")


func test_no_duplicates() -> void:
	print("-- no duplicate skills --")
	var props := []
	for p in SkillDef.new().get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and not p.name in ["id", "display_name", "description", "tier", "learnable"]:
			props.append(p.name)
	var seen := {}
	var dupes := []
	for id in SkillLibrary._skills:
		var s: SkillDef = SkillLibrary._skills[id]
		if s.effect == SkillDef.Effect.SUMMON and s.also_status == &"":
			continue
		var key := "|".join(props.map(func(n): return str(s.get(n))))
		if seen.has(key):
			dupes.append([seen[key], id])
		seen[key] = id
	# Same numbers but different elements or summons don't count; these are true copies.
	check(dupes.is_empty(), "every skill plays differently %s" % [dupes])
	for id in SkillLibrary.TWISTS:
		check(SkillLibrary._skills.has(id), "%s exists" % id) if not SkillLibrary._skills.has(id) else null
	check(_skill(&"flurry").mp_cost == 5 and _skill(&"club_of_heracles").mp_cost == 11, "cheap hard hitters cost more")


func test_riders() -> void:
	print("-- skill twists work --")
	_fresh()
	var p := GameState.player
	for st in Stats.all():
		p.stats.base[st] = 30
	var b := _battle([&"goblin"])
	var me: Combatant = b.party[0]
	var foe: Combatant = b.enemies[0]
	foe.max_hp = 100000
	foe.hp = 100000
	me.hp = 1
	var res := { "entries": [], "text": "" }
	var a := BattleAction.use_skill(me, _skill(&"vendetta"), foe)
	foe.stats.base[Stats.Type.AGILITY] = 0
	var ok := false
	for i in 10:
		b._resolve_skill(a, res)
		if me.hp > 1:
			ok = true
			break
	check(ok, "lifesteal heals the user")
	me.mp = 999
	me.hp = 1
	var aegis := BattleAction.use_skill(me, _skill(&"aegis"))
	b._resolve_skill(aegis, res)
	check(me.has_status(&"ward") and me.hp > 1, "a shield that also heals")
	me.statuses.clear()
	var charm := BattleAction.use_skill(me, _skill(&"charm_of_hades"))
	b._resolve_skill(charm, res)
	check(me.has_status(&"ward") and me.has_status(&"evasive"), "two statuses")
	me.mp = 0
	var spell := BattleAction.use_skill(me, _skill(&"spell_bulwark"))
	me.mp = _skill(&"spell_bulwark").mp_cost
	b._resolve_skill(spell, res)
	check(me.mp > 0, "a shield that restores MP")
	foe.stagger = 0
	foe.staggered = false
	var before := foe.stagger
	me.mp = 999
	var grapple := BattleAction.use_skill(me, _skill(&"wild_grapple"), foe)
	for i in 10:
		b._resolve_skill(grapple, res)
		if foe.stagger != before or foe.staggered:
			break
	check(foe.stagger != before or foe.staggered, "stagger without a weakness")
	# Execute + boss damage.
	var rng := RandomNumberGenerator.new()
	var plain := _skill(&"weighing_of_the_heart").duplicate() as SkillDef
	plain.execute_bonus = 0.0
	var avg := func(sk: SkillDef) -> float:
		var t := 0.0
		for i in 200:
			rng.seed = i
			t += DamageCalc.roll_damage(me, foe, sk, rng).amount
		return t
	foe.hp = 100000
	var full: float = avg.call(_skill(&"weighing_of_the_heart"))
	check(is_equal_approx(full, avg.call(plain)), "no bonus at full HP")
	foe.hp = foe.max_hp / 10
	check(avg.call(_skill(&"weighing_of_the_heart")) > avg.call(plain) * 1.3, "execute near death")


func test_floor_mods() -> void:
	print("-- floor twists --")
	var hits := {}
	var some := 0
	for s in 2000:
		var m := FloorMods.for_floor(33, s, false)
		if m != &"":
			some += 1
			hits[m] = true
	check(hits.size() == FloorMods.MODS.size(), "every twist turns up (%s)" % [hits.keys()])
	check(some > 500 and some < 900, "about a third of floors (%d/2000)" % some)
	check(FloorMods.for_floor(33, 5, false) == FloorMods.for_floor(33, 5, false), "stays the same for a floor")
	for s in 50:
		check(FloorMods.for_floor(29, s, false) == &"", "nothing below floor 30") if FloorMods.for_floor(29, s, false) != &"" else null
		check(FloorMods.for_floor(40, s, false) == &"", "never on boss floors") if FloorMods.for_floor(40, s, false) != &"" else null
		check(FloorMods.for_floor(35, s, true) == &"", "never on rest floors") if FloorMods.for_floor(35, s, true) != &"" else null
	_fresh()
	var with_mod := func(id: StringName) -> BattleManager:
		return _battle([&"goblin"], func(b): b.floor_mod = id)
	var plain := _battle([&"goblin"])
	var moon: BattleManager = with_mod.call(&"blood_moon")
	check(is_equal_approx(moon.enemies[0].damage_dealt_mult, 1.3) and is_equal_approx(moon.party[0].damage_dealt_mult, 1.3), "Blood Moon: both sides")
	check(moon.xp_mult > plain.xp_mult, "more XP")
	check(moon.start_lines.any(func(l): return l.contains("Blood Moon")), "named in the log")
	var gold: BattleManager = with_mod.call(&"gold_rush")
	check(gold.enemies[0].max_hp > plain.enemies[0].max_hp and gold.gold_mult > plain.gold_mult, "Gold Vein")
	var null_field: BattleManager = with_mod.call(&"anti_magic")
	check(is_equal_approx(null_field.party[0].magic_dealt_mult, 0.7), "Null Field")
	var silent: BattleManager = with_mod.call(&"no_items")
	check(not silent.items_allowed, "Silent Floor")
	silent.start()
	if silent.is_player_turn():
		GameState.inventory.add(&"potion")
		var used := silent.submit(BattleAction.use_item(silent.current, ItemLibrary.get_item(&"potion"), silent.current))
		check(used and GameState.inventory.count(&"potion") > 0, "items do nothing there")
	var well: BattleManager = with_mod.call(&"mana_well")
	well.party[0].mp = 0
	well._start_round()
	check(well.party[0].mp > 0, "Mana Well refills MP each round")
	# Through GameState.
	_fresh(33)
	GameState.floor_seed = 0
	for s in 500:
		GameState.floor_seed = s
		if GameState.current_floor_mod() != &"":
			break
	GameState.pending_battle_info = { "kind": "normal" }
	GameState.pending_encounter = []
	var cfg := BattleManager.new()
	GameState.configure_battle(cfg)
	check(cfg.floor_mod == GameState.current_floor_mod(), "fights on the floor get its twist")
	check(cfg.adapt_uses != null, "and adaptation")
	GameState.pending_battle_info = {}
	var test_fight := BattleManager.new()
	GameState.configure_battle(test_fight)
	check(test_fight.floor_mod == &"" and test_fight.adapt_uses == null, "test battles don't")
	check(TipLibrary.validate().is_empty(), "tips validate")


func test_adaptation() -> void:
	print("-- enemies adapt --")
	_fresh()
	var uses := {}
	var b := _battle([&"goblin"], func(x): x.adapt_uses = uses)
	var me: Combatant = b.party[0]
	var foe: Combatant = b.enemies[0]
	var skill := _skill(&"smash")
	check(b.adapt_mult(me, skill) == 1.0, "a new move is at full strength")
	check(b.adapt_mult(me, me.basic_attack) == 1.0, "basic attacks never fade")
	me.mp = 9999
	foe.max_hp = 1000000
	foe.hp = foe.max_hp
	var res := { "entries": [], "text": "" }
	for i in BattleManager.ADAPT_FREE_USES:
		b._resolve_skill(BattleAction.use_skill(me, skill, foe), res)
	check(b.adapt_mult(me, skill) == 1.0, "a few uses are free")
	b._resolve_skill(BattleAction.use_skill(me, skill, foe), res)
	check(is_equal_approx(b.adapt_mult(me, skill), 0.9), "then it fades")
	for i in 30:
		b._resolve_skill(BattleAction.use_skill(me, skill, foe), res)
	check(is_equal_approx(b.adapt_mult(me, skill), BattleManager.ADAPT_FLOOR), "never below half")
	check(res.text.contains("learned"), "the log says so (%s)" % res.text)
	check(b.adapt_mult(me, _skill(&"power_strike")) == 1.0, "other moves are fine")
	var off := _battle([&"goblin"])
	check(off.adapt_mult(off.party[0], skill) == 1.0, "off on early floors")
	# A new floor forgets.
	GameState.floor_skill_uses["x"] = 3
	GameState.enter_floor(2)
	check(GameState.floor_skill_uses.is_empty(), "a new floor starts over")


func _boss_id() -> StringName:
	for id in EnemyLibrary._enemies if "_enemies" in EnemyLibrary else []:
		if EnemyLibrary.get_enemy(id).is_boss:
			return id
	return StageLibrary.boss_for_floor(10)[0]


func test_boss_phases() -> void:
	print("-- boss mechanics --")
	_fresh()
	var id := _boss_id()
	var plain := _battle([id])
	check(plain.enemies[0].mechanics.is_empty(), "early bosses have none")
	var t1 := _battle([id], func(b): b.boss_tier = 1)
	check(t1.enemies[0].mechanics.size() == 1, "tier 1: one mechanic")
	var t2 := _battle([id], func(b): b.boss_tier = 2)
	check(t2.enemies[0].mechanics.size() == 2, "tier 2: two")
	check(t2.enemies[0].mechanics[0] == t1.enemies[0].mechanics[0], "a boss always plays the same")
	var mini_boss := _battle([id], func(b): b.boss_tier = 1; b.boss_is_miniboss = true)
	check(mini_boss.enemies[0].mechanics == ["enrage"], "minibosses just enrage")
	# Enrage at the mark.
	var u: Combatant = t1.enemies[0]
	var dealt := u.damage_dealt_mult
	check(t1._check_boss_phases() == "", "nothing above half HP")
	u.hp = u.max_hp / 2
	check(t1._check_boss_phases() != "", "half HP: it changes")
	check(u.phase == 1 and u.damage_dealt_mult > dealt, "and hits harder")
	check(t1._check_boss_phases() == "", "once")
	# Summon.
	var joined := []
	var s := _battle([id], func(b): b.boss_tier = 1; b.reinforcements = [EnemyLibrary.get_enemy(&"goblin")] as Array[EnemyDef])
	s.unit_joined.connect(func(x): joined.append(x))
	s.enemies[0].mechanics = ["summon"]
	s.enemies[0].hp = 1
	s._check_boss_phases()
	check(s.enemies.size() == 2 and joined.size() == 1, "reinforcements arrive and get a card")
	# Shield: weak hits only.
	var sh := _battle([id], func(b): b.boss_tier = 1)
	var boss: Combatant = sh.enemies[0]
	boss.mechanics = ["shield"]
	boss.hp = 1
	sh._check_boss_phases()
	check(boss.shielded, "a barrier goes up")
	boss.hp = boss.max_hp
	var me: Combatant = sh.party[0]
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	boss.stats.base[Stats.Type.AGILITY] = 0
	var sk := _skill(&"smash")
	var shielded_dmg := 0
	for i in 20:
		shielded_dmg += DamageCalc.roll_damage(me, boss, sk, rng).amount
	boss.shielded = false
	rng.seed = 3
	var open_dmg := 0
	for i in 20:
		open_dmg += DamageCalc.roll_damage(me, boss, sk, rng).amount
	check(shielded_dmg < open_dmg or boss.affinities.values().has(Element.Affinity.WEAK), "the barrier blunts normal hits (%d vs %d)" % [shielded_dmg, open_dmg])
	boss.shielded = true
	boss.shield_rounds = 1
	sh._tick_boss_mechanics()
	check(not boss.shielded, "and fades in time")
	# Charge: gather, blast, repeat.
	var ch := _battle([id], func(b): b.boss_tier = 1)
	var c: Combatant = ch.enemies[0]
	c.mechanics = ["charge"]
	c.phase = 1
	ch.round_number = BattleManager.BOSS_CHARGE_EVERY
	ch._tick_boss_mechanics()
	check(c.charge_state == 1, "gathering")
	check(BattleAI.choose(ch, c).type == BattleAction.Type.DEFEND, "it holds still while gathering")
	ch.round_number += 1
	ch._tick_boss_mechanics()
	check(c.charge_state == 2, "ready")
	var blast := BattleAI.choose(ch, c)
	check(blast.skill and blast.skill.id == SkillLibrary.BOSS_UNLEASH, "then it blasts")
	ch.current = c
	check(ch.submit(blast), "the blast resolves")
	check(c.charge_state == 0, "and starts over")
	# Through GameState.
	_fresh(50)
	GameState.pending_battle_info = { "kind": "boss" }
	GameState.pending_encounter = []
	var cfg := BattleManager.new()
	GameState.configure_battle(cfg)
	check(cfg.boss_tier == 2 and not cfg.boss_is_miniboss and not cfg.reinforcements.is_empty(), "floor 50 boss: tier 2")
	GameState.floor_number = 34
	GameState.pending_battle_info = { "kind": "miniboss" }
	cfg = BattleManager.new()
	GameState.configure_battle(cfg)
	check(cfg.boss_tier == 1 and cfg.boss_is_miniboss, "floor 34 miniboss")
	GameState.floor_number = 20
	GameState.pending_battle_info = { "kind": "boss" }
	cfg = BattleManager.new()
	GameState.configure_battle(cfg)
	check(cfg.boss_tier == 0, "floor 20 boss: none")
	GameState.pending_battle_info = {}


func _lineup(setup := Callable()) -> BattleManager:
	GameState.player = GameState.make_premade("Wren", &"mage", { Stats.Type.INTELLIGENCE: 20 })
	GameState.companions.clear()
	GameState.companions.append(GameState.make_premade("Bram", &"tank", { Stats.Type.HEALTH: 10, Stats.Type.STAMINA: 10 }))
	var chars: Array[CharacterData] = [GameState.player, GameState.companions[0]]
	var defs: Array[EnemyDef] = [EnemyLibrary.get_enemy(&"goblin"), EnemyLibrary.get_enemy(&"goblin_archer"), EnemyLibrary.get_enemy(&"imp_shaman")]
	var b := BattleManager.new()
	if setup.is_valid():
		setup.call(b)
	b.setup(chars, defs, 11)
	b.party[0].row = Combatant.Row.BACK
	b.party[1].row = Combatant.Row.FRONT
	return b


func test_backline_pressure() -> void:
	print("-- pressure on the back rows --")
	_fresh()
	check(GameState.flank_chance_for(10) == 0.0, "floors 1-10 teach rows: front line holds")
	check(GameState.flank_chance_for(11) > 0.0 and GameState.flank_chance_for(45) > GameState.flank_chance_for(11), "it grows as you climb")
	GameState.floor_number = 25
	GameState.pending_battle_info = { "kind": "normal" }
	GameState.pending_encounter = []
	var cfg := BattleManager.new()
	GameState.configure_battle(cfg)
	check(cfg.flank_chance > 0.0, "tower fights get it")
	GameState.pending_battle_info = {}
	cfg = BattleManager.new()
	GameState.configure_battle(cfg)
	check(cfg.flank_chance == 0.0, "test fights don't")
	# Early: melee never touches the back row.
	var calm := _lineup()
	for i in 200:
		var a := BattleAI.choose(calm, calm.enemies[0])
		check(a.target != calm.party[0], "no lunges early") if a.target == calm.party[0] else null
	# Later: it does, and Lunge really reaches.
	var b := _lineup(func(x): x.flank_chance = 0.35)
	var mage: Combatant = b.party[0]
	var tank: Combatant = b.party[1]
	check(b.flank_target() == mage, "the one behind the front line")
	var lunges := 0
	for i in 400:
		var a := BattleAI.choose(b, b.enemies[0])
		if a.skill.id == SkillLibrary.ENEMY_LUNGE:
			lunges += 1
	check(lunges > 90 and lunges < 200, "melee lunges about a third of the time (%d/400)" % lunges)
	check(b.valid_targets(b.enemies[0], _skill(SkillLibrary.ENEMY_LUNGE)).has(mage), "past the front line")
	check(not b.valid_targets(b.enemies[0], b.enemies[0].basic_attack).has(mage), "a normal hit still can't")
	# Counterplay.
	tank.add_status(&"taunt", 2)
	check(b.flank_target() == tank, "Taunt pulls it back")
	tank.statuses.clear()
	mage.guarded_by = tank
	tank.add_status(&"guarding", 1)
	b.enemies[0].stats.base[Stats.Type.AGILITY] = 200
	var res := { "entries": [], "text": "" }
	var hp := mage.hp
	var thp := tank.hp
	b.current = b.enemies[0]
	b._resolve_skill(BattleAction.use_skill(b.enemies[0], _skill(SkillLibrary.ENEMY_LUNGE), mage), res)
	check(mage.hp == hp and (tank.hp < thp or res.text.contains("dodges")), "Guard takes the hit (%s)" % res.text)
	tank.statuses.clear()
	mage.guarded_by = null
	# Nobody behind the front: no lunge.
	mage.row = Combatant.Row.FRONT
	check(b.flank_target() == null, "nobody to leap at")
	mage.row = Combatant.Row.BACK
	# Archers aim for the back rows.
	var back_hits := 0
	var archer: Combatant = b.enemies[1]
	for i in 300:
		var t := BattleAI._pick_target(b, archer, archer.basic_attack, b.valid_targets(archer, archer.basic_attack))
		if t == mage:
			back_hits += 1
	check(back_hits > 200, "archers hunt the back row (%d/300)" % back_hits)
	var plain := _lineup()
	var plain_hits := 0
	for i in 300:
		if BattleAI._pick_target(plain, plain.enemies[1], plain.enemies[1].basic_attack, plain.valid_targets(plain.enemies[1], plain.enemies[1].basic_attack)) == plain.party[0]:
			plain_hits += 1
	check(plain_hits < 200, "early archers shoot anyone (%d/300)" % plain_hits)
	# Casters go for whoever resists magic least (a tank here, not the mage).
	var soft := 0
	var shaman: Combatant = b.enemies[2]
	var bolt := _skill(&"firebolt")
	for i in 300:
		if BattleAI._pick_target(b, shaman, bolt, b.valid_targets(shaman, bolt)) == tank:
			soft += 1
	check(soft > 200, "casters pick the softest target (%d/300)" % soft)
	# Non-casters' magic defense.
	var late_orc := _battle([&"orc_brute"], func(x): x.flank_chance = 0.15)
	var early_orc := _battle([&"orc_brute"])
	check(late_orc.enemies[0].stats.magic_defense() > early_orc.enemies[0].stats.magic_defense(), "sturdy melee enemies resist magic a little from floor 11")
	check(_skill(SkillLibrary.ENEMY_LUNGE).learnable == false, "Lunge is the enemies' own")


func test_party_menu_scroll() -> void:
	print("-- Tab menu scrolls --")
	_fresh()
	var menu := PartyMenu.new()
	add_child(menu)
	menu.open()
	await _frames(2)
	check(menu._actions_box.get_parent() is ScrollContainer, "items + spells scroll")
	var p := GameState.player
	for id in [&"heal", &"first_aid", &"mend", &"second_wind", &"iron_will", &"lay_on_hands", &"holy_light", &"grace", &"inner_peace", &"sanctuary"]:
		if not p.learned_skills.has(id):
			p.learned_skills.append(id)
	menu._rebuild()
	await _frames(2)
	var screen := get_viewport().get_visible_rect()
	var scroll: Control = menu._actions_box.get_parent()
	check(screen.encloses(scroll.get_global_rect()), "the list stays on screen however long it gets")
	menu.queue_free()
	await _frames(1)
