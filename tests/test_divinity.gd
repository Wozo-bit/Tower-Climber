extends Node
## Becoming a god (Hayden 2026-10-25): domains, apotheosis at the end of a
## run, and past gods joining other characters' runs as beings.
## Run:  godot --headless res://tests/test_divinity.tscn

var _passed := 0
var _failed := 0


func _ready() -> void:
	GameState.save_dir = "user://test_saves_divinity"
	GameState.legacy_path = "user://test_hall_divinity.json"
	_clear_hall()
	test_domains()
	test_apotheosis()
	test_legacy_gods()
	test_saves_and_tampering()
	test_god_in_ng_plus()
	test_contracts()
	test_boons_and_tithes()
	test_own_guild()
	test_divinity_saves()
	GameState.delete_slot(1)
	GameState.delete_slot(2)
	_clear_hall()
	GameState.reset_run()
	GameState.refresh_legacy_gods()
	print("\n==== %d passed, %d failed ====" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)


func check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  ", label)
	else:
		_failed += 1
		printerr("  FAIL  ", label)


func _clear_hall() -> void:
	if FileAccess.file_exists(GameState.legacy_path):
		DirAccess.remove_absolute(GameState.legacy_path)


## Plays a run to the end on the given route and records it in the Hall.
func _conquer(char_name: String, route: StringName, slot: int = 1) -> LegacyRecord:
	GameState.start_new_game(char_name, "Cassia", slot)
	if route != &"":
		GameState.add_route_points(route, 30)
		GameState.lock_route(route)
	return GameState.complete_run()


func test_domains() -> void:
	print("Domains")
	check(DomainLibrary.validate().is_empty(), "domains are valid %s" % [DomainLibrary.validate()])
	for route in [&"hero", &"villain", &"vigilante"]:
		var picks := DomainLibrary.for_ending(route)
		check(picks.size() >= 2 and picks.all(func(id): return DomainLibrary.get_domain(id).route == route),
			"the %s ending suggests its own domains (%s)" % [route, picks])
	check(DomainLibrary.for_ending(&"neutral").size() == DomainLibrary.domains.size(), "the Wanderer may pick any domain")
	check(DomainLibrary.clean_title("  Lord [b]of[/b] {Ash}  ", &"valor") == "Lord bof/b Ash", "typed titles are cleaned (no BBCode)")
	check(DomainLibrary.clean_title("", &"valor") == "God of Valor", "a blank title uses the domain's")
	check(DomainLibrary.clean_title("x".repeat(80), &"valor").length() == DomainLibrary.TITLE_MAX_LENGTH, "titles are capped")


func test_apotheosis() -> void:
	print("Apotheosis")
	_clear_hall()
	var rec := _conquer("Ophelius", &"hero")
	check(not rec.is_god(), "conquering the tower records the climber, not a god yet")
	check(not GameState.become_god(rec.legacy_id, &"nonsense"), "only real domains")
	check(GameState.become_god(rec.legacy_id, &"valor", "Shield of the Weak"), "they ascend")
	var saved := GameState.load_legacy().find(rec.legacy_id)
	check(saved.is_god() and saved.god_domain == &"valor" and saved.god_title == "Shield of the Weak", "...and the Hall remembers")
	check(saved.god_name() == "Ophelius, Shield of the Weak", "god name")
	check(not GameState.become_god(rec.legacy_id, &"tyranny"), "once per character")
	GameState.start_new_game("Nobody", "Cassia", 1)
	check(not GameState.become_god(GameState.player.legacy_id, &"valor"), "nobody ascends without conquering the tower")


func test_legacy_gods() -> void:
	print("Past gods in other runs")
	_clear_hall()
	var rec := _conquer("Ophelius", &"villain")
	GameState.become_god(rec.legacy_id, &"tyranny", "")
	var god_id := DomainLibrary.being_id_for(rec.legacy_id)
	GameState.start_new_game("Brenna", "Cassia", 2)
	var b := BeingLibrary.get_being(god_id)
	check(not b.is_empty() and b.name == "Ophelius" and b.title == "God of Tyranny" and b.pantheon == "Ascended",
		"a new character's run has the past god as a being")
	check(BeingLibrary.validate().is_empty(), "the roster (with the past god) is still valid %s" % [BeingLibrary.validate()])
	check(not BeingLibrary.rivals_of(god_id).is_empty(), "their values make them rivals (%s)" % [BeingLibrary.rivals_of(god_id)])
	GameState.add_route_points(&"villain", 20)
	check(GameState.blessings.offering_beings().has(god_id), "a villain-leaning climber catches the God of Tyranny's eye")
	check(GameState.blessings.accept(god_id) and GameState.player.blessing_id == god_id
		and GameState.player.all_skills().any(func(s): return s.id == &"iron_decree"), "and can take their blessing and skill")
	# The god themself, climbing again in New Game+, is a patron but never courts themself.
	GameState.start_new_game_plus(GameState.load_legacy().find(rec.legacy_id), 1)
	GameState.add_route_points(&"villain", 40)
	check(BeingLibrary.get_being(god_id).get("self", false) and not GameState.blessings.offering_beings().has(god_id),
		"in their own New Game+ their god is never offered to them")


func test_saves_and_tampering() -> void:
	print("Saving")
	_clear_hall()
	var rec := _conquer("Ophelius", &"hero")
	GameState.become_god(rec.legacy_id, &"mercy", "")
	var god_id := DomainLibrary.being_id_for(rec.legacy_id)
	GameState.start_new_game("Brenna", "Cassia", 2)
	GameState.player.bless(god_id, 2)
	GameState.save_game()
	GameState.reset_run()
	GameState.refresh_legacy_gods()
	check(GameState.load_game(2) and GameState.player.blessing_id == god_id and GameState.player.blessing_level == 2,
		"a blessing from a past god is saved")
	var hall := SaveSerializer.read_json(GameState.legacy_path)
	hall.records[0]["god_domain"] = "omnipotence"
	SaveSerializer.write_json(GameState.legacy_path, hall)
	check(not GameState.load_legacy().find(rec.legacy_id).is_god(), "tampered Hall: an unknown domain is no god")
	hall.records[0]["god_domain"] = "mercy"
	hall.records[0]["god_title"] = "[color=red]Queen[/color]"
	hall.records[0]["times_cleared"] = 0
	SaveSerializer.write_json(GameState.legacy_path, hall)
	check(not GameState.load_legacy().find(rec.legacy_id).is_god(), "...nor someone who never conquered the tower")
	hall.records[0]["times_cleared"] = 1
	SaveSerializer.write_json(GameState.legacy_path, hall)
	check(GameState.load_legacy().find(rec.legacy_id).god_title == "color=redQueen/color", "...and titles are cleaned")
	_clear_hall()
	GameState.reset_run()
	check(GameState.load_game(2) and GameState.player.blessing_id == &"", "a god gone from the Hall: their blessing fades on load")


# =========================================================
# Phase 2: climbing as a god (New Game+)
# =========================================================

## A god of `domain` starting their New Game+ (slot 1).
func _god(domain: StringName, route: StringName) -> LegacyRecord:
	_clear_hall()
	var rec := _conquer("Ophelius", route)
	GameState.become_god(rec.legacy_id, domain, "")
	rec = GameState.load_legacy().find(rec.legacy_id)
	GameState.start_new_game_plus(rec, 1)
	return rec


func test_god_in_ng_plus() -> void:
	print("A god in New Game+")
	_clear_hall()
	GameState.start_new_game("Mortal", "Cassia", 1)
	check(not GameState.divinity.active and GameState.divinity.income_mult(&"golden_ledger") == 1.0,
		"a mortal run has no divinity (and no effects)")
	_god(&"valor", &"hero")
	var dv := GameState.divinity
	check(dv.active and dv.domain == &"valor" and dv.title == "God of Valor", "an ascended character climbs again as a god")
	check(dv.faith == 0 and dv.level() == 1 and dv.slots() == 1, "starting out: no faith, one contract")
	dv.add_faith(150)
	check(dv.level() == 2 and dv.slots() == 2, "faith raises divinity: more contracts")


func test_contracts() -> void:
	print("Contracts")
	_god(&"valor", &"hero")
	var dv := GameState.divinity
	check(dv.contract_refusal(&"golden_ledger").contains("faith"), "contracts cost faith")
	dv.add_faith(500)
	check(dv.contract_cost(&"golden_ledger") == 2 * dv.contract_cost(&"order_of_the_aegis"),
		"a guild whose values clash with yours costs double (Mammon's greedy Ledger vs Valor)")
	var mammon_before := GameState.blessings.interest(&"mammon")
	check(dv.sponsor(&"golden_ledger"), "sponsor a guild")
	check(GuildLibrary.get_guild(&"golden_ledger").patron == dv.god_id
		and GuildLibrary.values_of(&"golden_ledger").likes.has(&"hero"), "it takes you as patron, and your values")
	check(GameState.blessings.interest(&"mammon") < mammon_before and BeingLibrary.rivals_of(dv.god_id).has(&"mammon"),
		"its old patron is spurned: a rival now")
	check(dv.faith == 500 - 120, "paid in faith")
	dv.faith_earned = 400   # level 3: 3 contracts
	check(dv.sponsor(&"order_of_the_aegis") and dv.sponsor(&"jade_oath"), "more divinity, more contracts")
	check(dv.contract_refusal(&"ravenwatch").contains("No free contract"), "...but not unlimited")
	GameState.reset_run()
	check(GuildLibrary.get_guild(&"golden_ledger").patron == &"mammon", "a new run: every guild has its own patron again")


func test_boons_and_tithes() -> void:
	print("Boons, curses, tithes")
	_god(&"tyranny", &"villain")
	var dv := GameState.divinity
	dv.add_faith(200)
	var g := &"stormhammer_company"
	dv.sponsor(g)
	check(dv.set_terms(g, &"warhost", &"burden") != "", "a big boon needs a heavy curse")
	check(dv.set_terms(g, &"warhost", &"zealotry") == "", "Warhost paid for with Zealotry")
	check(dv.war_bonus(g) == 2.0 and dv.personality_shift(g).aggression >= 0.25, "boon and curse both apply")
	dv.set_terms(g, &"bargains", &"isolation")
	check(dv.price_mult(g) < 1.0 and not dv.can_ally(g), "Bargains + Isolation")
	dv.set_terms(g, &"wealth", &"gouging")
	check(is_equal_approx(dv.income_mult(g), 1.25) and dv.price_mult(g) > 1.0, "Wealth + Gouging")
	check(dv.set_stance(g, &"defensive") and dv.personality_shift(g).get("fortify", 0.0) > 0.0, "set its stance")
	var held := GameState.guilds.territories_of(g).size()
	var gold := GameState.player.gold
	var faith := dv.faith
	dv.on_floor()
	check(dv.faith == faith + DivinityState.FAITH_PER_TERRITORY * held and GameState.player.gold > gold,
		"tithes every floor: faith and gold (%d faith, %d gold)" % [dv.faith - faith, GameState.player.gold - gold])
	for i in 10:
		dv.on_floor()
	check(dv.contract_level(g) == 2 and is_equal_approx(dv.income_mult(g), 1.5), "serving you, it grows (level 2: stronger boon)")
	var before := GameState.guilds.treasury_of(g)
	GuildAI.tick(GameState.guilds, RandomNumberGenerator.new())
	check(GameState.guilds.treasury_of(g) - before >= roundi(GuildAI.INCOME_PER_TERRITORY * held * 1.5) - GuildAI.FORTIFY_COST,
		"the guild AI pays out the boosted income")


func test_own_guild() -> void:
	print("Your own church")
	_god(&"mercy", &"hero")
	var dv := GameState.divinity
	check(GameState.guilds.willing_patrons()[0] == dv.god_id, "a god founds their own guild as its patron")
	GameState.highest_floor = 20
	GameState.player.gold = 5000
	check(GameState.guilds.found_guild("Hands of Mercy", dv.god_id), "found it")
	check(dv.contracts.has(GuildLibrary.PLAYER_GUILD) and dv.others().is_empty() and dv.slots() == 1,
		"your guild is yours, and doesn't use a contract")
	check(GameState.guilds.your_patrons().has(dv.god_id), "you're your guild's patron (your temper steers the wars)")


func test_divinity_saves() -> void:
	print("Saving a god")
	_god(&"greed", &"villain")
	var dv := GameState.divinity
	dv.add_faith(300)
	dv.sponsor(&"order_of_the_aegis")
	dv.set_terms(&"order_of_the_aegis", &"devotion", &"brittle")
	dv.set_stance(&"order_of_the_aegis", &"greedy")
	GameState.save_game()
	GameState.reset_run()
	check(GameState.load_game(1), "load")
	dv = GameState.divinity
	var c: Dictionary = dv.contracts.get(&"order_of_the_aegis", {})
	check(dv.active and dv.faith == 300 - 120 and c.get("boon") == &"devotion" and c.get("stance") == &"greedy",
		"faith, contracts, terms and stance are saved")
	check(GuildLibrary.get_guild(&"order_of_the_aegis").patron == dv.god_id and dv.spurned.has(&"athena"),
		"...and the guild is still yours (Athena still angry)")
	var d := SaveSerializer.read_json(GameState.slot_path(1))
	d.divinity.contracts["order_of_the_aegis"]["boon"] = "warhost"   # cost 2 with a weight-1 curse
	d.divinity.contracts["jade_oath"] = { "boon": "wealth", "curse": "burden" }
	d.divinity.contracts["ravenwatch"] = { "boon": "wealth", "curse": "burden" }
	d.divinity.contracts["nonsense_guild"] = { "boon": "wealth", "curse": "burden" }
	SaveSerializer.write_json(GameState.slot_path(1), d)
	GameState.load_game(1)
	dv = GameState.divinity
	check(dv.contracts.order_of_the_aegis.boon == &"wealth", "tampered: an unpaid boon is reset")
	check(dv.others().size() <= dv.slots() and not dv.contracts.has(&"nonsense_guild"), "tampered: contracts trimmed to your slots")
	# A mortal's save can't claim divinity.
	GameState.start_new_game("Mortal", "Cassia", 2)
	GameState.save_game()
	d = SaveSerializer.read_json(GameState.slot_path(2))
	d["divinity"] = { "active": true, "faith": 9999, "contracts": { "golden_ledger": { "boon": "wealth", "curse": "burden" } } }
	SaveSerializer.write_json(GameState.slot_path(2), d)
	GameState.load_game(2)
	check(not GameState.divinity.active and GuildLibrary.get_guild(&"golden_ledger").patron == &"mammon",
		"tampered: a mortal can't make themself a god")
