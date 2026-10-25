extends Node
## Guild phase 3: the guild AI, raids, alliances, wars (and fighting in them),
## guards and champions, stealing and pickpockets, heists, founding your own
## guild (income, tax, upgrades, claiming floors) and saving it all.
## Run:  godot --headless res://tests/test_guild_ai.tscn
## Uses separate test save files, so your real save is never touched.

var _passed := 0
var _failed := 0


func _ready() -> void:
	GameState.save_dir = "user://test_saves_guild_ai"
	test_ai_ticks()
	test_raids_and_alliances()
	test_wars()
	test_fighting_in_wars()
	test_guards_and_hostility()
	test_stealing()
	test_pickpockets()
	test_heists()
	test_founding()
	test_claiming_floors()
	test_dialogue_hooks()
	test_save_roundtrip()
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


func _fresh(floor_n: int = 5) -> void:
	GameState.reset_run()
	GameState.player = GameState.make_premade("Ophelius", &"rogue", { Stats.Type.AGILITY: 20, Stats.Type.LUCK: 15 })
	GameState.player.legacy_id = "ai-test"
	GameState.companions.append(GameState.make_childhood_friend("Cassia"))
	GameState.floor_number = floor_n
	GameState.highest_floor = floor_n


func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


func test_ai_ticks() -> void:
	_fresh()
	var gs := GameState.guilds
	var before := gs.treasury_of(&"golden_ledger")
	GuildAI.tick(gs, _rng(1))
	check(gs.treasury_of(&"golden_ledger") >= before + GuildAI.INCOME_PER_TERRITORY - GuildAI.WAR_COST - GuildAI.FORTIFY_COST,
		"every tick, guilds earn from their floors")
	for i in 40:
		GuildAI.tick(gs, _rng(100 + i))
	check(not gs.news.is_empty(), "the guilds act on their own (%d news items)" % gs.news.size())
	check(gs.news.any(func(n): return n.text.contains("war") or n.text.contains("robbed") or n.text.contains("alliance") or n.text.contains("fortif")),
		"...raids, alliances, fortifying or war: %s" % gs.news[-1].text)
	# Same run, same floors = same story.
	var a := GuildState.new()
	var b := GuildState.new()
	for i in 15:
		GuildAI.tick(a, _rng(7 + i))
		GuildAI.tick(b, _rng(7 + i))
	check(str(a.to_dict()) == str(b.to_dict()), "the AI is deterministic for a seed (a run replays the same)")
	_fresh()
	GameState.enter_floor(6)
	check(GameState.guilds.treasury_of(&"order_of_the_aegis") > GuildState.START_TREASURY - GuildAI.WAR_COST, "climbing a floor runs a tick")


func test_raids_and_alliances() -> void:
	_fresh()
	var gs := GameState.guilds
	var robbed := false
	for s in 30:
		var t0 := gs.treasury_of(&"order_of_the_aegis")
		gs.raid(&"serpent_coil", &"order_of_the_aegis", _rng(s))
		if gs.treasury_of(&"order_of_the_aegis") < t0:
			robbed = true
			break
	check(robbed and gs.treasury_of(&"serpent_coil") > GuildState.START_TREASURY, "raids move gold from one treasury to another")
	check(gs.news.any(func(n): return n.text.contains("Serpent Coil")), "...and make the news")
	gs.make_alliance(&"order_of_the_aegis", &"jade_oath")
	check(gs.allied(&"jade_oath", &"order_of_the_aegis"), "alliances (both ways)")
	check(GuildAI._ally_target(gs, &"order_of_the_aegis") != &"jade_oath", "...a guild doesn't ally the same guild twice")
	check(GuildAI._raid_target(gs, &"sunspear_caravan") == &"serpent_coil" or gs.treasury_of(&"serpent_coil") < GuildAI.RAID_MIN_TREASURY,
		"greedy raids go for rivals first (Ra's Sunspear -> Apep's Serpent Coil)")


func test_wars() -> void:
	_fresh()
	var gs := GameState.guilds
	gs.declare_war(&"serpent_coil", &"sunspear_caravan", 1)
	check(gs.is_at_war(&"serpent_coil") and gs.war_between(&"sunspear_caravan", &"serpent_coil") and gs.is_contested(1), "a war over a territory")
	check(gs.messages.any(func(m): return m.contains("declares war")), "wars are big news")
	var potion := ItemLibrary.get_item(&"potion")
	check(GameState.shop_price(potion) == 48, "prices jump in a contested territory (%d)" % GameState.shop_price(potion))
	gs.wars[0].score = GuildState.WAR_WIN - 0.1
	gs.swing(&"sunspear_caravan", 0.0)   # nobody's side: nothing
	gs.progress_wars(_rng(1))
	var settled := gs.wars.is_empty()
	check(settled or gs.wars[0].ticks == 1, "wars move every floor")
	gs.wars.clear()
	gs.declare_war(&"serpent_coil", &"sunspear_caravan", 1)
	gs.wars[0].score = GuildState.WAR_WIN
	gs._settle(gs.wars[0])
	check(gs.owners[1] == &"serpent_coil" and not gs.is_at_war(&"serpent_coil"), "the winner takes the territory")
	check(GameState.guilds.owner_of_floor(5) == &"serpent_coil", "...and runs those floors now")
	gs.declare_war(&"order_of_the_aegis", &"serpent_coil", 1)
	gs.wars[0].ticks = GuildState.WAR_MAX_TICKS - 1
	gs.wars[0].score = 0.0
	gs.progress_wars(_rng(2))
	check(gs.wars.is_empty() or absf(gs.wars[0].score) >= GuildState.WAR_WIN, "long wars end (truce or a winner)")


func test_fighting_in_wars() -> void:
	_fresh()
	var gs := GameState.guilds
	gs.join(&"sunspear_caravan")
	gs.declare_war(&"serpent_coil", &"sunspear_caravan", 1)
	check(gs.player_side() == &"sunspear_caravan" and gs.is_hostile(&"serpent_coil"), "your guild's at war: its enemy hunts you")
	var score: float = gs.wars[0].score
	gs.fight_won(&"serpent_coil", false)
	check(gs.wars[0].score == score - GuildState.GUARD_SWING, "each guard group you beat swings the war your way")
	check(gs.rep_of(&"serpent_coil") < 0, "...and they like you less")
	_fresh()
	gs = GameState.guilds
	gs.declare_war(&"serpent_coil", &"sunspear_caravan", 1)
	check(gs.can_hire_on(&"sunspear_caravan") and gs.hire_on(&"sunspear_caravan") and gs.player_side() == &"sunspear_caravan",
		"not a member? hire on as a mercenary")
	var gold := GameState.player.gold
	gs.fight_won(&"serpent_coil", false)
	check(GameState.player.gold == gold + GuildState.MERCENARY_PAY, "mercenaries are paid per fight")
	for i in 10:
		if gs.wars.is_empty():
			break
		gs.fight_won(&"serpent_coil", false)
	check(gs.owners[1] == &"sunspear_caravan" and gs.mercenary_for == &"", "fight enough and your side wins; the contract ends with the war")


func test_guards_and_hostility() -> void:
	_fresh(8)   # Mountain Crew, territory 2
	var gs := GameState.guilds
	gs.add_rep(&"mountain_crew", -60)
	check(gs.is_hostile(&"mountain_crew"), "hated: that guild's guards hunt you")
	GameState.floor_seed = 3
	GameState.floor_ready = false
	GameState.current_layout()
	var guards := GameState.floor_enemies.filter(func(e): return e.kind == "guard")
	check(guards.size() == 2 and guards.all(func(e): return e.guild == &"mountain_crew"), "guards replace two normal enemies on its floors")
	check(guards[0].group.has(&"guild_guard") or guards[0].group.has(&"guild_archer"), "guard groups are guild fighters")
	var idx := GameState.floor_enemies.find(guards[0])
	GameState.active_enemy_index = idx
	GameState.pending_encounter = EnemyLibrary.build_group(guards[0].group)
	GameState.return_scene = ""
	var rep := gs.rep_of(&"mountain_crew")
	GameState.finish_battle(BattleManager.Outcome.VICTORY)
	check(gs.rep_of(&"mountain_crew") == rep - GuildState.GUARD_REP_LOSS and not GameState.floor_enemies[idx].alive, "beating guards: they're gone, and you're liked even less")
	var saved := SaveSerializer.floor_enemies_from_array(SaveSerializer.floor_enemies_to_array(GameState.floor_enemies))
	check(saved.filter(func(e): return e.kind == "guard").all(func(e): return e.guild == &"mountain_crew"), "guards are saved with their guild")
	_fresh(8)
	GameState.floor_seed = 3
	GameState.floor_ready = false
	GameState.current_layout()
	check(GameState.floor_enemies.all(func(e): return e.kind != "guard" and e.kind != "champion"), "nobody hunts a climber in good standing")


func test_stealing() -> void:
	_fresh(5)
	var gs := GameState.guilds
	var chance := GuildState.steal_chance(GameState.player)
	check(chance > GuildState.STEAL_BASE and chance <= GuildState.STEAL_MAX, "Agility + Luck improve your odds (%d%%)" % roundi(chance * 100))
	var outcome := ""
	var seed_ok := -1
	for s in 50:
		var r := _rng(s)
		if r.randf() < chance:
			seed_ok = s
			break
	var lenses := GameState.inventory.count(&"ether")
	outcome = gs.try_steal(&"ether", _rng(seed_ok))
	check(outcome == "stolen" and GameState.inventory.count(&"ether") == lenses + 1, "a clean theft: free item")
	check(GameState.route.points_of(&"villain") == GuildState.STEAL_VILLAIN_POINTS, "...and a step toward villainy")
	check(gs.try_steal(&"ether", _rng(1)) == "", "one try per floor")
	GameState.floor_number = 6
	var seed_fail := -1
	for s in 50:
		if _rng(s).randf() >= chance:
			seed_fail = s
			break
	check(gs.try_steal(&"potion", _rng(seed_fail)) == "caught", "caught!")
	check(gs.is_hostile(&"sunspear_caravan") and gs.rep_of(&"sunspear_caravan") == -GuildState.CAUGHT_PENALTY,
		"...the floor's guild hunts you for a while")
	GameState.floor_number = 6 + GuildState.CAUGHT_FLOORS + 1
	check(not gs.is_hostile(&"sunspear_caravan"), "...then it blows over")


func test_pickpockets() -> void:
	_fresh(10)   # the Golden Ledger: greedy, lawless floors
	var gs := GameState.guilds
	GameState.player.gold = 1000
	var hit := false
	for s in 200:
		if gs.roll_pickpocket(_rng(s)) != "":
			hit = true
			break
	check(hit and GameState.player.gold < 1000, "pickpockets work greedy guilds' floors (gold now %d)" % GameState.player.gold)
	_fresh(10)
	gs = GameState.guilds
	gs.join(&"golden_ledger")
	gs.add_rep(&"golden_ledger", 30)
	GameState.player.gold = 1000
	var any := false
	for s in 200:
		if gs.roll_pickpocket(_rng(s)) != "":
			any = true
	check(not any and GameState.player.gold == 1000, "members of the floor's guild are left alone")
	_fresh(1)
	GameState.player.gold = 1000
	any = false
	for s in 200:
		if GameState.guilds.roll_pickpocket(_rng(s)) != "":
			any = true
	check(not any, "honest guilds' floors are safe")


func test_heists() -> void:
	_fresh(5)
	var gs := GameState.guilds
	gs.join(&"sunspear_caravan")
	check(not gs.can_take_heist(&"sunspear_caravan"), "Recruits don't get heists")
	gs.add_rep(&"sunspear_caravan", 30)
	check(gs.heist_target(&"sunspear_caravan") == &"serpent_coil" and gs.take_heist(&"sunspear_caravan"), "Members can be sent to rob a rival")
	var chance := GuildState.steal_chance(GameState.player)
	var good := -1
	for s in 50:
		if _rng(s).randf() < chance:
			good = s
			break
	var gold := GameState.player.gold
	var their := gs.treasury_of(&"serpent_coil")
	var their_rep := gs.rep_of(&"serpent_coil")   # already down a little: you joined their rival
	check(gs.attempt_heist(&"serpent_coil", _rng(good)) == "done", "pull it off at their agent")
	var loot := roundi(their * GuildState.HEIST_SHARE)
	check(GameState.player.gold == gold + loot / 2 and gs.treasury_of(&"serpent_coil") == their - loot, "half the loot for you, half for your guild")
	check(gs.heist.is_empty() and gs.rep_of(&"serpent_coil") == their_rep - GuildState.HEIST_REP_LOSS, "...and they know who to blame")


func test_founding() -> void:
	_fresh(10)
	var gs := GameState.guilds
	check(gs.charter_refusal().contains("floor 15"), "a charter needs you past floor 15")
	GameState.highest_floor = 16
	check(gs.charter_refusal().contains("2000"), "...and 2000 gold")
	GameState.player.gold = 2500
	gs.join(&"golden_ledger")
	GameState.add_route_points(&"hero", 12)
	var r := DialogueRunner.new()
	r.start(&"blessing_offer", null, &"thor")
	r.choose(0)
	check(GuildState.willing_patrons()[0] == &"thor", "your blessing's being is first in line to be your patron")
	check(gs.found_guild("  The   Iron   Climbers ", &"thor"), "found a guild (even while in another)")
	check(gs.member == GuildLibrary.PLAYER_GUILD and gs.rank == 3 and GameState.player.gold == 500, "you're its Master; the charter cost 2000")
	check(gs.rep_of(&"golden_ledger") == -GuildState.LEAVE_PENALTY, "your old guild takes it badly")
	check(GuildLibrary.guild_name(GuildLibrary.PLAYER_GUILD) == "The Iron Climbers" and GuildLibrary.get_guild(GuildLibrary.PLAYER_GUILD).patron == &"thor",
		"your guild works like any other (name cleaned up, patron Thor)")
	check(not gs.found_guild("Again"), "one guild of your own")
	gs.set_player_tax(0.9)
	check(is_equal_approx(gs.player_guild.tax, GuildState.MAX_PLAYER_TAX), "tax is capped at 30%")
	gs.treasury[GuildLibrary.PLAYER_GUILD] = 600
	check(gs.buy_upgrade("vault") and gs.upgrade_level("vault") == 1 and gs.treasury_of(GuildLibrary.PLAYER_GUILD) == 100, "guild hall upgrades come out of the treasury")
	check(not gs.buy_upgrade("barracks"), "...if it can afford them")
	check(gs.withdraw(1000) == 100 and gs.treasury_of(GuildLibrary.PLAYER_GUILD) == 0, "withdraw from your treasury")
	var strength := gs.war_strength(GuildLibrary.PLAYER_GUILD)
	gs.treasury[GuildLibrary.PLAYER_GUILD] = 1000
	gs.buy_upgrade("barracks")
	check(gs.war_strength(GuildLibrary.PLAYER_GUILD) > strength, "Barracks make your guild stronger in wars")
	GameState.reset_run()
	check(not GuildLibrary.guilds.has(GuildLibrary.PLAYER_GUILD), "a new run starts without your old guild")


func test_claiming_floors() -> void:
	_fresh(16)
	var gs := GameState.guilds
	GameState.player.gold = 2000
	gs.found_guild("Iron Climbers")
	GameState.floor_number = 13   # Stormhammer's first floor (territory 4)
	GameState.highest_floor = 16
	check(gs.champion_waiting(4), "with your own guild, champions wait to be challenged")
	GameState.floor_seed = 5
	GameState.floor_ready = false
	GameState.current_layout()
	var champ := GameState.floor_enemies.filter(func(e): return e.kind == "champion")
	check(champ.size() == 1 and champ[0].guild == &"stormhammer_company" and champ[0].group[0] == &"guild_champion", "the territory's champion holds its first floor")
	GameState.active_enemy_index = GameState.floor_enemies.find(champ[0])
	GameState.pending_encounter = EnemyLibrary.build_group(champ[0].group)
	GameState.return_scene = ""
	GameState.finish_battle(BattleManager.Outcome.VICTORY)
	check(gs.owners[4] == GuildLibrary.PLAYER_GUILD and gs.owner_of_floor(14) == GuildLibrary.PLAYER_GUILD, "beat it: Floors 13-15 are yours")
	check(gs.rep_of(&"stormhammer_company") == -GuildState.CHAMPION_REP_LOSS and gs.messages.any(func(m): return m.contains("takes Floors 13-15")),
		"the old owner is furious; the tower hears of it")
	check(not gs.champion_waiting(4), "no champion on your own floors")
	var t0 := gs.treasury_of(GuildLibrary.PLAYER_GUILD)
	gs.player_guild_income()
	check(gs.treasury_of(GuildLibrary.PLAYER_GUILD) > t0, "your floors pay into your treasury every floor")
	var potion := ItemLibrary.get_item(&"potion")
	GameState.floor_number = 14
	check(GameState.shop_price(potion) <= 40, "...and your floors' merchants charge your prices")


func test_dialogue_hooks() -> void:
	_fresh(5)
	var gs := GameState.guilds
	gs.declare_war(&"serpent_coil", &"sunspear_caravan", 1)
	var r := DialogueRunner.new()
	r.start(&"guild_agent", null, &"", &"sunspear_caravan")
	var texts := r.choices().map(func(c): return c.text)
	check(texts.has("Need a sword in your war?"), "a guild at war will hire you")
	r.choose(r.choices().filter(func(c): return c.text == "Need a sword in your war?")[0].index)
	check(gs.mercenary_for == &"sunspear_caravan" and r.text().contains("at war with The Serpent Coil"), "hired: %s" % r.text())
	r.start(&"merchant")
	r.choose(r.choices().filter(func(c): return c.text == "Heard any news?")[0].index)
	check(r.text().contains("declares war"), "the merchant passes on the news")
	check(DialogueLibrary.validate_all().is_empty(), "guild dialogue still validates")


func test_save_roundtrip() -> void:
	GameState.start_new_game("Ophelius", "Cassia", 1)
	GameState.highest_floor = 20
	GameState.player.gold = 3000
	var gs := GameState.guilds
	gs.found_guild("Iron Climbers", &"odin")
	gs.treasury[GuildLibrary.PLAYER_GUILD] = 600   # a new guild's treasury starts empty
	gs.buy_upgrade("vault")
	gs.owners[3] = GuildLibrary.PLAYER_GUILD
	gs.declare_war(&"serpent_coil", GuildLibrary.PLAYER_GUILD, 3)
	gs.make_alliance(&"order_of_the_aegis", &"jade_oath")
	gs.hostile_until[&"golden_ledger"] = 12
	gs.champion_beaten[4] = 13
	gs.defense[&"ravenwatch"] = 2
	GameState.save_game()
	GameState.reset_run()
	check(not GuildLibrary.guilds.has(GuildLibrary.PLAYER_GUILD), "(reset clears it)")
	GameState.load_game(1)
	gs = GameState.guilds
	check(gs.has_own_guild() and GuildLibrary.guild_name(GuildLibrary.PLAYER_GUILD) == "Iron Climbers" and gs.member == GuildLibrary.PLAYER_GUILD,
		"your guild is saved and works again after loading")
	check(gs.owners[3] == GuildLibrary.PLAYER_GUILD and gs.upgrade_level("vault") == 1, "its floors and upgrades too")
	check(gs.war_between(&"serpent_coil", GuildLibrary.PLAYER_GUILD) and gs.allied(&"jade_oath", &"order_of_the_aegis"), "wars and alliances saved")
	check(gs.hostile_until[&"golden_ledger"] == 12 and gs.champion_beaten[4] == 13 and gs.defense_of(&"ravenwatch") == 2 and not gs.news.is_empty(),
		"hostility, champions, defenses and news saved")
	var d := SaveSerializer.read_json(GameState.slot_path(1))
	d.guilds.wars.append({ "attacker": "fake", "defender": "serpent_coil", "territory": 1 })
	d.guilds.player_guild.upgrades.vault = 99
	d.guilds.mercenary_for = "golden_ledger"
	SaveSerializer.write_json(GameState.slot_path(1), d)
	GameState.load_game(1)
	gs = GameState.guilds
	check(gs.wars.size() == 1 and gs.upgrade_level("vault") == GuildState.UPGRADES.vault.max and gs.mercenary_for == &"",
		"tampered save: fake wars dropped, upgrades capped, no contract with a guild at peace")
