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
	# The god themself, climbing again in New Game+, never meets themself.
	GameState.start_new_game_plus(GameState.load_legacy().find(rec.legacy_id), 1)
	check(not BeingLibrary.beings.has(god_id), "in their own New Game+ they're not in the roster")


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
