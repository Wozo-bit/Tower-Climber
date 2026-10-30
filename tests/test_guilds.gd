extends Node
## Guilds and the economy: guild data, territories, patrons and rivals,
## joining / leaving, ranks and their perks (tax, prices, stock, patron
## favor, pay), taxes on battle gold, supply and demand, selling, guild jobs,
## guild agents, and saving.
## Run:  godot --headless res://tests/test_guilds.tscn
## Uses separate test save files, so your real save is never touched.

var _passed := 0
var _failed := 0


func _ready() -> void:
	GameState.save_dir = "user://test_saves_guilds"
	GameState.unlocks_path = "user://test_saves_guilds_unlocks.json"
	Tips.path = "user://test_saves_guilds_tips.json"
	GameState.legacy_path = "user://test_hall_guilds.json"
	test_data_is_valid()
	test_territories()
	test_joining_and_leaving()
	test_ranks()
	test_taxes_and_prices()
	test_pay()
	test_market()
	test_selling()
	test_guild_jobs()
	test_agents_and_dialogue()
	test_save_and_ng_plus()
	GameState.delete_slot(1)
	if FileAccess.file_exists(GameState.legacy_path):
		DirAccess.remove_absolute(GameState.legacy_path)
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
	GameState.player.rename("Ophelius")
	GameState.player.legacy_id = "guild-test"
	GameState.companions.append(GameState.make_childhood_friend("Cassia"))
	GameState.floor_number = floor_n


func test_data_is_valid() -> void:
	var problems := GuildLibrary.validate()
	for p in problems:
		printerr("    ", p)
	check(problems.is_empty(), "every guild is valid (patron, tax, prices, stock)")
	check(GuildLibrary.guilds.size() == 10 and GuildLibrary.START_OWNERS.size() == 10, "10 guilds, 10 territories to start")
	check(DialogueLibrary.validate_all().is_empty() and QuestLibrary.validate_all().is_empty(), "guild dialogue and jobs are valid")


func test_territories() -> void:
	_fresh()
	var gs := GameState.guilds
	check(gs.owner_of_floor(1) == &"order_of_the_aegis" and gs.owner_of_floor(3) == &"order_of_the_aegis", "floors 1-3: one territory")
	check(gs.owner_of_floor(4) == &"sunspear_caravan" and gs.owner_of_floor(10) == &"golden_ledger", "every 3 floors, a new guild")
	check(gs.owner_of_floor(31) == gs.owner_of_floor(1), "past the last territory the pattern repeats")
	check(GuildLibrary.territory_floors(1) == "Floors 4-6" and GuildLibrary.is_territory_start(4) and not GuildLibrary.is_territory_start(5), "territory helpers")
	check(GuildLibrary.values_of(&"golden_ledger").likes.has(&"villain"), "a guild's values come from its patron (Mammon: villains)")
	check(GuildLibrary.rivals_of(&"sunspear_caravan").has(&"serpent_coil"), "rival patrons, rival guilds (Ra's Sunspear vs Apep's Serpent Coil)")


func test_joining_and_leaving() -> void:
	_fresh()
	var gs := GameState.guilds
	check(gs.join(&"sunspear_caravan") and gs.member == &"sunspear_caravan" and gs.rank == 0, "join a guild as a Recruit")
	check(gs.rep_of(&"serpent_coil") == -GuildState.RIVAL_JOIN_PENALTY, "its rival guild likes you less")
	check(not gs.can_join(&"golden_ledger") and gs.join_refusal(&"golden_ledger").contains("already"), "one guild at a time")
	check(gs.leave() and gs.member == &"" and gs.rep_of(&"sunspear_caravan") == -GuildState.LEAVE_PENALTY, "leaving costs standing")
	check(not gs.can_join(&"sunspear_caravan"), "...and they won't have you back for a while")
	_fresh()
	GameState.add_route_points(&"villain", 12)
	check(not GameState.guilds.can_join(&"order_of_the_aegis") and GameState.guilds.join_refusal(&"order_of_the_aegis").contains("someone like you"),
		"a guild won't take you if its patron hates your route")
	check(GameState.guilds.can_join(&"golden_ledger"), "...but a villainous one will")


func test_ranks() -> void:
	_fresh()
	var gs := GameState.guilds
	gs.join(&"golden_ledger")
	var interest := GameState.blessings.interest(&"mammon")
	gs.add_rep(&"golden_ledger", 25)
	check(gs.rank == 1 and gs.messages.any(func(m): return m.contains("Member")), "25 standing: promoted to Member")
	check(GameState.blessings.interest(&"mammon") == interest + GuildLibrary.RANK_UP_INTEREST, "a promotion pleases the guild's patron")
	gs.add_rep(&"golden_ledger", 60)
	check(gs.rank == 3, "85 standing: Master")
	gs.add_rep(&"golden_ledger", -40)
	check(gs.rank == 1 and gs.messages.any(func(m): return m.contains("Demoted")), "lose standing, lose rank")
	check(ShopPanel.guild_stock(&"golden_ledger") == [&"scouting_lens"], "guild shop at Member: the basics")
	gs.add_rep(&"golden_ledger", 20)
	check(ShopPanel.guild_stock(&"golden_ledger").has(&"goddess_tear"), "Officers see more stock")
	var tear := ItemLibrary.get_item(&"goddess_tear")
	check(ShopPanel.guild_price(&"golden_ledger", tear) == roundi(1500 * 1.15 * 0.85), "guild shop price: the guild's markup minus your rank discount")


func test_taxes_and_prices() -> void:
	_fresh(10)   # Golden Ledger territory: 20% tax, prices x1.15
	var gs := GameState.guilds
	GameState.player.gold = 1000
	check(GameState.collect_battle_tax(100) == 20 and GameState.player.gold == 980, "20% of battle gold goes to the floor's guild")
	check(gs.treasury_of(&"golden_ledger") == GuildState.START_TREASURY + 20, "...into its treasury")
	var potion := ItemLibrary.get_item(&"potion")
	check(GameState.shop_price(potion) == 46, "its merchant charges 15%% more (%d)" % GameState.shop_price(potion))
	gs.join(&"golden_ledger")
	check(is_equal_approx(gs.tax_rate(10), 0.15) and GameState.shop_price(potion) == 44, "members (Recruit) pay less tax and get a discount")
	gs.add_rep(&"golden_ledger", 85)
	check(gs.tax_rate(10) == 0.0, "Masters pay no tax")
	check(is_equal_approx(gs.tax_rate(1), 0.05), "other guilds' floors still tax you")
	_fresh(5)
	check(GameState.shop_price(potion) == 40, "floors 1-6: normal prices")


func test_pay() -> void:
	_fresh(5)
	var gs := GameState.guilds
	gs.join(&"sunspear_caravan")
	gs.add_rep(&"sunspear_caravan", 50)
	check(gs.rank == 2 and not gs.pay_due(), "Officer, but pay isn't due yet")
	GameState.enter_floor(10)
	check(gs.pay_due() and gs.messages.any(func(m): return m.contains("pay ready")), "5 floors later: pay is ready")
	var gold := GameState.player.gold
	var before := gs.treasury_of(&"sunspear_caravan")   # the guild AI earned some income meanwhile
	var paid := gs.collect_pay()
	check(paid == roundi(before * 0.03) and GameState.player.gold == gold + paid, "Officers get 3%% of the treasury (%d of %d)" % [paid, before])
	check(gs.treasury_of(&"sunspear_caravan") == before - paid and not gs.pay_due(), "...which leaves the treasury, and isn't due again yet")


func test_market() -> void:
	_fresh(5)
	var gs := GameState.guilds
	var t := GuildLibrary.territory_of(5)
	var potion := ItemLibrary.get_item(&"potion")
	GameState.player.gold = 10000
	var first := GameState.shop_price(potion)
	for i in 6:
		GameState.buy_item(&"potion")
	check(GameState.shop_price(potion) > first, "buying lots raises the price (%d -> %d)" % [first, GameState.shop_price(potion)])
	check(gs.buy_mult(GuildLibrary.territory_of(1), "potion") == 1.0, "...only in this territory")
	var sell_before := GameState.sell_price_item(&"ether")
	GameState.inventory.add(&"ether", 10)
	for i in 8:
		GameState.sell_item(&"ether")
	check(GameState.sell_price_item(&"ether") < sell_before, "selling lots drops what traders pay (%d -> %d)" % [sell_before, GameState.sell_price_item(&"ether")])
	check(gs.sell_mult(t, "ether") >= GuildState.SELL_MULT_RANGE.x, "...but never below the floor price")
	var low := gs.sell_mult(t, "ether")
	GameState.enter_floor(6)
	check(gs.sell_mult(t, "ether") > low, "prices recover as you climb")
	for i in 30:
		gs.on_floor()
	check(gs.market.is_empty(), "...all the way back to normal")


func test_selling() -> void:
	_fresh(5)
	GameState.inventory.add(&"potion")
	var gold := GameState.player.gold
	check(GameState.sell_item(&"potion") == 20 and GameState.player.gold == gold + 20, "consumables sell for half their price")
	var rng := RandomNumberGenerator.new()
	var g := LootTable.make_gear(&"bow", Rarity.Tier.RARE, 3, rng)
	GameState.inventory.add_gear(g)
	check(GameState.sell_price_gear(g) == 60 + 9, "gear sells by rarity and item level")
	check(GameState.sell_gear(g) == 69 and not GameState.inventory.gear.has(g), "sold gear leaves the bag")
	var unique := LootTable.make_unique(&"mage", 10)
	GameState.inventory.add_gear(unique)
	check(GameState.sell_gear(unique) == 0 and GameState.inventory.gear.has(unique), "Uniques can't be sold")
	GameState.inventory.add(&"glowcap")
	check(GameState.sell_item(&"glowcap") == 0, "quest items can't be sold")
	check(GameState.sell_price_item(SkillBooks.book_item_id(&"power_strike")) == GameState.SELL_BOOK_PER_TIER, "skill books sell too")


func test_guild_jobs() -> void:
	_fresh(5)
	var offers := GameState.quests.board_offers(5)
	var bounty: Dictionary = offers.filter(func(o): return o.def.kind == "bounty")[0]
	check(bounty.def.rewards.guild_rep.has(&"sunspear_caravan") and bounty.def.giver == "Sunspear Caravan", "board jobs are posted by the guild that runs the floor")
	check(NoticeBoardPanel.reward_text(bounty.def.rewards).contains("standing with Sunspear Caravan"), "...and pay standing with it")
	var back := SaveSerializer.quest_def_from_dict(JSON.parse_string(JSON.stringify(SaveSerializer.quest_def_to_dict(bounty.def))))
	check(back.rewards.guild_rep.get(&"sunspear_caravan") == QuestLog.BOUNTY_GUILD_REP, "guild rewards survive saving")
	GameState.quests.accept(bounty)
	var goal: Dictionary = bounty.def.steps[0].goal
	var victims := []
	for i in goal.count:
		victims.append(EnemyLibrary.get_enemy(goal.enemy) if goal.has("enemy") else
			EnemyLibrary.all().filter(func(d): return d.family == goal.family)[0])
	GameState.quests.on_battle_won(victims, RandomNumberGenerator.new())
	check(GameState.quests.is_done(bounty.id) and GameState.guilds.rep_of(&"sunspear_caravan") == QuestLog.BOUNTY_GUILD_REP, "finishing a guild job raises your standing")


func test_agents_and_dialogue() -> void:
	_fresh(4)
	var layout := FloorLayout.generate(1, 4, false, true)
	GameState.place_npcs(layout)
	check(layout.npcs.values().has(&"guild:sunspear_caravan") and GameState.agent_guild(&"guild:sunspear_caravan") == &"sunspear_caravan",
		"the territory's guild agent stands on its first floor")
	GameState.floor_number = 5
	var rest := FloorLayout.generate(1, 5, true)
	GameState.place_npcs(rest)
	check(rest.npcs.values().has(&"guild:sunspear_caravan"), "...and on its rest floors")
	GameState.floor_number = 6
	var plain := FloorLayout.generate(1, 6, false)
	GameState.place_npcs(plain)
	check(not plain.npcs.values().any(func(v): return String(v).begins_with("guild:")), "...not everywhere")
	var r := DialogueRunner.new()
	r.start(&"guild_agent", null, &"", &"sunspear_caravan")
	check(r.speaker() == "Sunspear Caravan agent" and r.text().contains("Neutral"), "the agent knows your standing")
	r.choose(1)   # join
	check(GameState.guilds.member == &"sunspear_caravan", "join through the agent")
	r.start(&"guild_agent", null, &"", &"sunspear_caravan")
	var texts := r.choices().map(func(c): return c.text)
	check(texts.has("Show me the members' stock.") and texts.has("I'm leaving the guild.") and not texts.has("I want to join."),
		"members see the guild shop and can leave")
	r.choose(3)
	check(r.finished and r.requests.has("shop:guild") and DialogueRunner.context_guild == &"sunspear_caravan", "the members' shop opens for that guild")
	r.start(&"guild_agent", null, &"", &"sunspear_caravan")
	r.choose(0)
	check(r.text().contains("Ra, God of the Sun") and r.text().contains("Floors 4-6") and r.text().contains("8%"), "about: patron, floors and tax")


func test_save_and_ng_plus() -> void:
	GameState.start_new_game("Ophelius", "Cassia", 1)
	var gs := GameState.guilds
	gs.join(&"order_of_the_aegis")
	gs.add_rep(&"order_of_the_aegis", 30)
	gs.add_rep(&"golden_ledger", -20)
	gs.record_sell(0, "potion")
	gs.owners[2] = &"golden_ledger"   # the guild AI (phase 3) will do this
	GameState.collect_battle_tax(200)
	GameState.save_game()
	GameState.reset_run()
	GameState.load_game(1)
	gs = GameState.guilds
	check(gs.member == &"order_of_the_aegis" and gs.rank == 1 and gs.rep_of(&"golden_ledger") == -20, "membership, rank and standing saved")
	check(gs.owners[2] == &"golden_ledger" and gs.pressure(0, "potion") < 0.0, "territory owners and the market saved")
	check(gs.treasury_of(&"order_of_the_aegis") > GuildState.START_TREASURY, "treasuries saved")
	var d := SaveSerializer.read_json(GameState.slot_path(1))
	d.guilds.member = "fake_guild"
	d.guilds.rep["fake_guild"] = 50
	d.guilds.rep["golden_ledger"] = 9999
	d.guilds.owners[0] = "fake_guild"
	SaveSerializer.write_json(GameState.slot_path(1), d)
	GameState.load_game(1)
	gs = GameState.guilds
	check(gs.member == &"" and not gs.rep.has(&"fake_guild") and gs.rep_of(&"golden_ledger") == GuildState.REP_MAX
		and gs.owners[0] == GuildLibrary.START_OWNERS[0], "tampered save: fake guilds dropped, standing clamped")
	gs.join(&"order_of_the_aegis")
	var rec := GameState.complete_run()
	GameState.start_new_game_plus(rec)
	check(GameState.guilds.member == &"" and GameState.guilds.rep.is_empty(), "New Game+ starts with no guild")
