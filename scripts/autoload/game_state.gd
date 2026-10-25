extends Node
## Autoload "GameState": everything that survives scene changes — the party,
## the item bag, where you are in the tower, and the battle hand-off.

## How many fight (player included): 2 on floors 1-20, then 2 more every 20
## floors (Hayden 2026-10-25: 2 -> 4 -> 6 -> 8 -> 10 over the 100-floor
## climb). It follows the highest floor reached, so a wipe doesn't shrink it.
const PARTY_START_SIZE := 2
const PARTY_GROWTH := 2
const PARTY_GROWTH_FLOORS := 20
const MAX_PARTY_SIZE := 10
const BATTLE_SCENE := "res://scenes/battle.tscn"
const TOWER_SCENE := "res://scenes/tower_floor.tscn"
const TITLE_SCENE := "res://scenes/title.tscn"

## Beating the boss on this floor completes the game (character goes into the
## Hall of Climbers). The design target is 100 floors; 30 for now (tier-2
## advancement opens after floor 20, so it gets played).
const FINAL_FLOOR := 60
## Each New Game+ cycle multiplies enemy strength by this much more (NG+1 = x1.5).
const NG_PLUS_SCALE_PER_CYCLE := 0.5

## A rest floor (campfire + merchant, no enemies) every N floors.
const REST_FLOOR_INTERVAL := 5
## Enemy HP/stat multiplier: floor 1 = 0.7, +0.08 per floor. Placeholder curve.
const ENEMY_SCALE_BASE := 0.42
const ENEMY_SCALE_PER_FLOOR := 0.05
## Fraction of the leader's gold lost on a party wipe.

## Bench size, and the share of battle XP benched members get.
const RESERVE_CAP := 6
const RESERVE_XP_SHARE := 0.5

const STARTING_ITEMS := { &"potion": 5, &"ether": 1 }
## Every run starts with your childhood friend (story canon). The player names
## them on the New Game screen; this is the default if they leave it blank.
const CHILDHOOD_FRIEND_NAME := "Rowan"

# --- Party ---
var player: CharacterData
var companions: Array[CharacterData] = []
## Companions on the bench: they don't fight, and get RESERVE_XP_SHARE of
## each battle's XP. Swap them in from Tab -> Manage party. Max RESERVE_CAP.
var reserve: Array[CharacterData] = []
## Dismissed companions (and recruits who joined with no room anywhere). They
## wait by the campfire on rest floors and cleared boss floors, exactly as they
## left, and can always rejoin.
var waiting: Array[CharacterData] = []
var inventory := Inventory.new()

# --- Tower progress ---
var floor_number := 1
var checkpoint_floor := 1         # where you wake up after a wipe (last rest floor)
var floor_seed := 0
var floor_ready := false          # false = floor_enemies needs generating
## [{ "pos": Vector2i, "group": Array[StringName], "alive": bool }]
var floor_enemies: Array = []
var floor_player_pos := Vector2i(-1, -1)
## Roaming bosses the party has beaten (they never come back).
var defeated_roamers: Array = []
## Highest floor reached this run (class advancement gates check it).
var highest_floor := 1

# --- Story ---
## Story/clue flags: StringName -> true. Dialogue, lore objects and quests set these.
var story_flags: Dictionary = {}
## What the party has learned about enemies (weaknesses, traits). Per run.
var bestiary := Bestiary.new()
## Active / completed / failed quests and notice-board bounties. Per run.
var quests := QuestLog.new()
## Route points (Hero, Villain, Vigilante...) and the locked route. Per run.
var route := RouteState.new()
## Conversations a companion wants to have about your route, shown by the
## tower when nothing else is open: [{ "dialogue": id, "companion": CharacterData }].
var pending_talks: Array = []
## Gods, demons and devils: interest, refusals, scorn. Per run. (The blessing
## itself is on each CharacterData.)
var blessings := BlessingState.new()
## Guilds and the economy: territories, reputation, membership, treasuries,
## supply and demand. Per run.
var guilds := GuildState.new()
## The stage theme picked for each StageLibrary slot this run (e.g. floors
## 1-10 = Slime Pits). Rolled on New Game / New Game+, saved with the run.
var stage_themes: Array = []:
	set(value):
		stage_themes = StageLibrary.validate_themes(value)
		StageLibrary.run_themes = stage_themes

# --- Run / meta ---
## 0 = normal game, 1 = first New Game+, ...
var ng_plus_cycle := 0
## Difficulty (Difficulty.Level): picked at New Game / New Game+, can only be
## lowered during a run. Ironman: anyone still down when a fight ends is dead,
## and the run ends if you die (the save is deleted, the Hall records it).
var difficulty: int = Difficulty.DEFAULT
var ironman := false
## Companions lost in this Ironman run (names, for the Hall and the log).
var fallen_companions: Array[String] = []
## Set when an Ironman run has just ended (the title screen shows it).
var ironman_ended_message := ""
var play_time_sec := 0.0
## True during a real run (New Game / Continue / New Game+). False on the title
## screen and in the dev sandbox, so test sessions never overwrite your save.
var run_active := false
## Pauses the play-time clock (pause menu).
var clock_paused := false
## Set when the final boss falls; the tower shows the ending and returns to title.
var pending_completion := false

## Where saves live. Vars (not consts) so tests can point them elsewhere.
## Saves are plain JSON (never .tres) so a shared/tampered save can't run code.
const SLOT_COUNT := 3
var save_dir := "user://saves"
var legacy_path := "user://hall_of_climbers.json"
## Which of the 3 save slots this run lives in.
var current_slot := 1

# --- Battle hand-off ---
var pending_encounter: Array[EnemyDef] = []
var pending_enemy_scale := 1.0
## What kind of fight it is, for music and cut-ins:
## { "kind": enemy_kind, "guild": .., "roamer_id": .. } ({} = an ordinary fight).
var pending_battle_info: Dictionary = {}
var return_scene: String = ""
var active_enemy_index := -1      # which floor enemy started the fight
var last_battle_outcome := -1     # BattleManager.Outcome, read by the tower on return


func _ready() -> void:
	_register_input_actions()
	DlcLoader.load_all()


func _process(delta: float) -> void:
	if run_active and not clock_paused:
		play_time_sec += delta


## Adds movement/menu keys at runtime so the project works without
## editing Project Settings > Input Map. Rebind there later if you like.
func _register_input_actions() -> void:
	var actions := {
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"party_menu": [KEY_TAB, KEY_I],
		"pause": [KEY_ESCAPE, KEY_P],
	}
	for action in actions:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in actions[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)


func _init() -> void:
	reset_run()


# =========================================================
# Runs: new game, New Game+, save / load
# =========================================================

## Wipes all run state back to a fresh level-1 start.
func reset_run() -> void:
	player = CharacterData.new()
	companions.clear()
	reserve.clear()
	waiting.clear()
	inventory = Inventory.new()
	for id in STARTING_ITEMS:
		inventory.add(id, STARTING_ITEMS[id])
	floor_number = 1
	checkpoint_floor = 1
	floor_seed = randi()
	floor_ready = false
	floor_enemies = []
	floor_player_pos = Vector2i(-1, -1)
	defeated_roamers = []
	highest_floor = 1
	story_flags = {}
	bestiary = Bestiary.new()
	quests = QuestLog.new()
	route = RouteState.new()
	blessings = BlessingState.new()
	guilds = GuildState.new()
	GuildLibrary.guilds.erase(GuildLibrary.PLAYER_GUILD)   # your guild belongs to one run
	pending_talks = []
	stage_themes = []   # each slot's first theme until a run rolls its own
	ng_plus_cycle = 0
	difficulty = Difficulty.DEFAULT
	ironman = false
	fallen_companions = []
	play_time_sec = 0.0
	pending_completion = false
	clock_paused = false
	pending_unlock_message = ""
	active_enemy_index = -1
	last_battle_outcome = -1


## Fresh run with a new level-1 character and their childhood friend, in `slot`.
## A blank `friend_name` uses the default (CHILDHOOD_FRIEND_NAME).
func start_new_game(character_name: String, friend_name: String = "", slot: int = 1,
		p_difficulty: int = Difficulty.DEFAULT, p_ironman := false) -> void:
	reset_run()
	difficulty = p_difficulty if Difficulty.is_valid(p_difficulty) else Difficulty.DEFAULT
	ironman = p_ironman
	current_slot = clampi(slot, 1, SLOT_COUNT)
	player.rename(character_name)
	player.legacy_id = _new_legacy_id()
	companions.append(make_childhood_friend(friend_name))
	roll_stage_themes()
	quests.update()   # the main questline starts
	run_active = true
	save_game()


## Picks this run's stage themes (Goblin Warrens or Slime Pits, ...).
func roll_stage_themes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	stage_themes = StageLibrary.roll_themes(rng)


## New Game+: continue a character from the Hall of Climbers. By default it uses
## the save slot that character conquered the tower in (record.slot), but the
## player may pick any slot (`slot`).
## Keeps level, stats and class, plus Unique gear (not questline rewards).
## Other gear, gold, consumables, tower progress and story flags reset, the
## childhood friend rejoins at level 1, and enemies get tougher each cycle.
func start_new_game_plus(record: LegacyRecord, slot: int = -1, p_difficulty: int = Difficulty.DEFAULT,
		p_ironman := false) -> void:
	reset_run()
	difficulty = p_difficulty if Difficulty.is_valid(p_difficulty) else Difficulty.DEFAULT
	ironman = p_ironman
	current_slot = clampi(slot, 1, SLOT_COUNT) if slot > 0 else ng_plus_slot_for(record)
	player = record.character.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	player.gold = 0
	for eq_slot in player.equipment.keys():
		if not player.get_equipped(eq_slot).carries_into_ng_plus():
			player.unequip(eq_slot)
	player.unbless()      # blessings and curses are story: earned again each run
	player.lift_curse()
	player.full_restore()
	if player.legacy_id == "":
		player.legacy_id = record.legacy_id
	for g in record.vault:
		if g.carries_into_ng_plus():
			inventory.add_gear(g.duplicate_deep(Resource.DEEP_DUPLICATE_ALL))
	companions.append(make_childhood_friend(record.friend_name))
	ng_plus_cycle = record.highest_cycle_cleared + 1
	roll_stage_themes()
	quests.update()
	run_active = true
	save_game()


static func ng_plus_slot_for(record: LegacyRecord) -> int:
	return clampi(record.slot, 1, SLOT_COUNT) if record.slot > 0 else 1


## Wherever they are: party, reserve or waiting at a campfire.
func childhood_friend() -> CharacterData:
	for c in companions + reserve + waiting:
		if c.companion_id == &"childhood_friend":
			return c
	return null


static func _new_legacy_id() -> String:
	return "%d-%d" % [Time.get_unix_time_from_system(), randi()]


# =========================================================
# Save slots (JSON — see SaveSerializer for why)
# =========================================================

func slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [save_dir, slot]


## What's in a slot: { "state": "empty" | "run" | "completed" | "corrupt", ... }.
## "completed" slots hold a marker left by conquering the tower (New Game+ uses them).
func slot_info(slot: int) -> Dictionary:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return { "state": "empty", "summary": "Empty" }
	var d := SaveSerializer.read_json(path)
	if d.is_empty():
		return { "state": "corrupt", "summary": "Unreadable save" }
	if d.get("completed", false):
		var name_s := SaveSerializer._s(d, "character_name", "?", 32)
		return { "state": "completed", "character_name": name_s, "legacy_id": SaveSerializer._s(d, "legacy_id"),
			"summary": "%s — conquered the tower%s  ·  %s" % [name_s,
				" (NG+%d)" % d.ng_plus_cycle if d.get("ng_plus_cycle", 0) > 0 else "",
				SaveSerializer._s(d, "saved_at").left(16)] }
	var p := SaveSerializer._d(d, "player")
	var ng := SaveSerializer._i(d, "ng_plus_cycle", 0)
	return { "state": "run", "summary": "%s  ·  Lv %d  ·  Floor %d%s  ·  %s  ·  %s" % [
		SaveSerializer._s(p, "name", "?", 32), SaveSerializer._i(p, "level", 1),
		SaveSerializer._i(d, "floor_number", 1), "  ·  NG+%d" % ng if ng > 0 else "",
		LegacyRecord.format_time(SaveSerializer._f(d, "play_time_sec", 0.0)), SaveSerializer._s(d, "saved_at").left(16)] }


## True if `slot` (default: the current one) holds a run you can continue.
func has_save(slot: int = -1) -> bool:
	return slot_info(current_slot if slot < 0 else slot).state == "run"


func any_save() -> bool:
	for s in range(1, SLOT_COUNT + 1):
		if has_save(s):
			return true
	return false


func save_game() -> bool:
	var d := {
		"version": SaveSerializer.FORMAT_VERSION,
		"saved_at": Time.get_datetime_string_from_system(false, true),
		"play_time_sec": play_time_sec,
		"player": SaveSerializer.character_to_dict(player),
		"companions": companions.map(SaveSerializer.character_to_dict),
		"reserve": reserve.map(SaveSerializer.character_to_dict),
		"waiting": waiting.map(SaveSerializer.character_to_dict),
		"inventory": SaveSerializer.inventory_to_dict(inventory),
		"floor_number": floor_number,
		"checkpoint_floor": checkpoint_floor,
		"floor_seed": floor_seed,
		"floor_ready": floor_ready,
		"floor_enemies": SaveSerializer.floor_enemies_to_array(floor_enemies),
		"floor_player_pos": [floor_player_pos.x, floor_player_pos.y],
		"defeated_roamers": defeated_roamers.map(func(id): return String(id)),
		"highest_floor": highest_floor,
		"story_flags": story_flags.keys().map(func(f): return String(f)),
		"ng_plus_cycle": ng_plus_cycle,
		"difficulty": difficulty,
		"ironman": ironman,
		"fallen_companions": fallen_companions.duplicate(),
		"bestiary": bestiary.to_dict(),
		"quests": quests.to_dict(),
		"route": route.to_dict(),
		"blessings": blessings.to_dict(),
		"guilds": guilds.to_dict(),
		"stage_themes": stage_themes.map(func(t): return String(t)),
	}
	var ok := SaveSerializer.write_json(slot_path(current_slot), d)
	if not ok:
		push_error("Save failed: %s" % slot_path(current_slot))
	return ok


## Loads a slot. Returns false (and leaves the current game alone) if the slot
## has no valid run.
func load_game(slot: int = -1) -> bool:
	var s := current_slot if slot < 0 else slot
	var d := SaveSerializer.read_json(slot_path(s))
	if d.is_empty() or d.get("completed", false) or not d.get("player") is Dictionary:
		return false
	var S := SaveSerializer
	reset_run()
	current_slot = s
	player = S.character_from_dict(d.player)
	for cd in S._a(d, "companions"):
		if cd is Dictionary:
			companions.append(S.character_from_dict(cd))
	for cd in S._a(d, "reserve"):
		if cd is Dictionary:
			reserve.append(S.character_from_dict(cd))
	for cd in S._a(d, "waiting"):
		if cd is Dictionary:
			waiting.append(S.character_from_dict(cd))
	inventory = S.inventory_from_dict(S._d(d, "inventory"))
	floor_number = S._i(d, "floor_number", 1, 1, 100000)
	checkpoint_floor = S._i(d, "checkpoint_floor", 1, 1, floor_number)
	floor_seed = S._i(d, "floor_seed", randi())
	floor_ready = S._b(d, "floor_ready", false)
	floor_enemies = S.floor_enemies_from_array(S._a(d, "floor_enemies"))
	if floor_ready and floor_enemies.is_empty() and not is_rest_floor(floor_number):
		floor_ready = false   # enemy list was lost/invalid: regenerate the floor
	var pos := S._a(d, "floor_player_pos")
	floor_player_pos = Vector2i(int(pos[0]), int(pos[1])) if pos.size() == 2 else Vector2i(-1, -1)
	# Older saves: assume the current floor is the highest reached.
	highest_floor = S._i(d, "highest_floor", floor_number, floor_number, 100000)
	# A tampered save can't field more than a full party or overfill the bench.
	while companions.size() > party_size() - 1:
		reserve.push_front(companions.pop_back())
	while reserve.size() > RESERVE_CAP:
		waiting.append(reserve.pop_back())
	for id in S._a(d, "defeated_roamers"):
		if id is String:
			defeated_roamers.append(StringName(id))
	for f in S._a(d, "story_flags"):
		if f is String:
			story_flags[StringName(f)] = true
	ng_plus_cycle = S._i(d, "ng_plus_cycle", 0, 0, 999)
	difficulty = S._i(d, "difficulty", Difficulty.DEFAULT, 0, Difficulty.Level.HELL)
	ironman = S._b(d, "ironman", false)
	for n in S._a(d, "fallen_companions"):
		if n is String:
			fallen_companions.append(CharacterData.clean_name(n))
	bestiary = Bestiary.from_dict(S._d(d, "bestiary"))
	guilds = GuildState.from_dict(S._d(d, "guilds"))   # before quests: rescue quests live here
	quests = QuestLog.from_dict(S._d(d, "quests"))
	route = RouteState.from_dict(S._d(d, "route"))
	blessings = BlessingState.from_dict(S._d(d, "blessings"))
	stage_themes = S._a(d, "stage_themes")   # older saves: each slot's first theme
	play_time_sec = S._f(d, "play_time_sec", 0.0, 0.0)
	run_active = true
	return true


func delete_slot(slot: int) -> void:
	var path := slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


## Kept for older callers: clears the current slot.
func delete_save() -> void:
	delete_slot(current_slot)


func save_summary(slot: int = -1) -> String:
	return slot_info(current_slot if slot < 0 else slot).summary


# =========================================================
# Hall of Climbers (legacy) & completion
# =========================================================

func load_legacy() -> LegacyBook:
	var book := LegacyBook.new()
	var d := SaveSerializer.read_json(legacy_path)
	for rd in SaveSerializer._a(d, "records"):
		if not rd is Dictionary or not rd.get("character") is Dictionary:
			continue
		var S := SaveSerializer
		var r := LegacyRecord.new()
		r.legacy_id = S._s(rd, "legacy_id", "", 64)
		r.character = S.character_from_dict(rd.character)
		r.times_cleared = S._i(rd, "times_cleared", 1, 0)
		r.highest_cycle_cleared = S._i(rd, "highest_cycle_cleared", 0, 0, 999)
		r.first_cleared_at = S._s(rd, "first_cleared_at")
		r.last_cleared_at = S._s(rd, "last_cleared_at")
		r.best_play_time_sec = S._f(rd, "best_play_time_sec", 0.0, 0.0)
		r.friend_name = CharacterData.clean_name(S._s(rd, "friend_name"))
		r.slot = S._i(rd, "slot", 1, 1, SLOT_COUNT)
		r.best_difficulty = S._i(rd, "best_difficulty", -1, -1, Difficulty.Level.HELL)
		r.ironman_cleared = S._b(rd, "ironman_cleared", false)
		r.fallen = S._b(rd, "fallen", false)
		r.fallen_floor = S._i(rd, "fallen_floor", 0, 0, 100000)
		r.fallen_difficulty = S._i(rd, "fallen_difficulty", Difficulty.DEFAULT, 0, Difficulty.Level.HELL)
		for e in S._a(rd, "endings_seen"):
			# Unknown ids are kept only if they look sane: a DLC ending may not be loaded right now.
			if e is String and e.length() <= 64 and not r.endings_seen.has(StringName(e)):
				r.endings_seen.append(StringName(e))
		for gd in S._a(rd, "vault"):
			if gd is Dictionary:
				var g := S.gear_from_dict(gd)
				if g:
					r.vault.append(g)
		book.records.append(r)
	return book


func save_legacy(book: LegacyBook) -> bool:
	var records := []
	for r in book.records:
		records.append({
			"legacy_id": r.legacy_id, "character": SaveSerializer.character_to_dict(r.character),
			"times_cleared": r.times_cleared, "highest_cycle_cleared": r.highest_cycle_cleared,
			"first_cleared_at": r.first_cleared_at, "last_cleared_at": r.last_cleared_at,
			"best_play_time_sec": r.best_play_time_sec, "friend_name": r.friend_name, "slot": r.slot,
			"endings_seen": r.endings_seen.map(func(e): return String(e)),
			"vault": r.vault.map(SaveSerializer.gear_to_dict),
			"best_difficulty": r.best_difficulty, "ironman_cleared": r.ironman_cleared,
			"fallen": r.fallen, "fallen_floor": r.fallen_floor, "fallen_difficulty": r.fallen_difficulty,
		})
	return SaveSerializer.write_json(legacy_path, { "version": SaveSerializer.FORMAT_VERSION, "records": records })


## Records (or updates) the player in the Hall of Climbers. Returns the record.
func record_completion() -> LegacyRecord:
	var book := load_legacy()
	if player.legacy_id == "":
		player.legacy_id = _new_legacy_id()
	var rec := book.find(player.legacy_id)
	var now := Time.get_datetime_string_from_system(false, true)
	if rec == null:
		rec = LegacyRecord.new()
		rec.legacy_id = player.legacy_id
		rec.first_cleared_at = now
		book.records.append(rec)
	rec.character = player.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	rec.character.full_restore()
	rec.slot = current_slot
	var ending: Dictionary = RouteLibrary.pick_ending()
	if not ending.is_empty() and not rec.endings_seen.has(ending.id):
		rec.endings_seen.append(ending.id)
	var friend := childhood_friend()
	if friend:
		rec.friend_name = friend.character_name
	# Unequipped Uniques (bag + companions' gear) go in the vault for New Game+.
	rec.vault.clear()
	var loose: Array = inventory.gear.duplicate()
	for c in companions + reserve + waiting:
		loose.append_array(c.equipment.values())
	for g: GearItem in loose:
		if g.carries_into_ng_plus():
			rec.vault.append(g.duplicate_deep(Resource.DEEP_DUPLICATE_ALL))
	rec.times_cleared += 1
	rec.highest_cycle_cleared = maxi(rec.highest_cycle_cleared, ng_plus_cycle)
	rec.best_difficulty = maxi(rec.best_difficulty, difficulty)
	rec.ironman_cleared = rec.ironman_cleared or ironman
	rec.last_cleared_at = now
	if rec.best_play_time_sec <= 0.0 or play_time_sec < rec.best_play_time_sec:
		rec.best_play_time_sec = play_time_sec
	if not save_legacy(book):
		push_error("Couldn't save the Hall of Climbers")
	return rec


## Ironman death: the character goes into the Hall as Fallen (no New Game+ from it).
func record_fallen() -> LegacyRecord:
	var book := load_legacy()
	if player.legacy_id == "":
		player.legacy_id = _new_legacy_id()
	var rec := book.find(player.legacy_id)
	if rec == null:
		rec = LegacyRecord.new()
		rec.legacy_id = player.legacy_id
		book.records.append(rec)
	rec.character = player.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	rec.slot = current_slot
	rec.fallen = true
	rec.fallen_floor = floor_number
	rec.fallen_difficulty = difficulty
	rec.last_cleared_at = Time.get_datetime_string_from_system(false, true)
	var friend := childhood_friend()
	if friend:
		rec.friend_name = friend.character_name
	if not save_legacy(book):
		push_error("Couldn't save the Hall of Climbers")
	return rec


## The run is over: the character goes into the Hall, and the save slot is
## replaced by a "conquered" marker (New Game+ will reuse this slot).
func complete_run() -> LegacyRecord:
	var rec := record_completion()
	SaveSerializer.write_json(slot_path(current_slot), {
		"version": SaveSerializer.FORMAT_VERSION, "completed": true,
		"legacy_id": rec.legacy_id, "character_name": player.character_name,
		"ng_plus_cycle": ng_plus_cycle, "saved_at": rec.last_cleared_at,
	})
	run_active = false
	pending_completion = false
	return rec


static func ng_plus_scale(cycle: int) -> float:
	return 1.0 + NG_PLUS_SCALE_PER_CYCLE * cycle


## Who fights the coming battle: the party, plus your guild's captain when
## you're on their territory (GuildState.guest_captain).
func fighting_party() -> Array[CharacterData]:
	var out := battle_party()
	var guest := guilds.guest_captain(floor_number, pending_battle_info.get("kind", "normal"))
	if guest and not out.has(guest):
		out.append(guest)
	# A rescue: whoever you're saving fights beside you.
	var rid: StringName = pending_battle_info.get("recruit", &"")
	if rid != &"" and not has_recruited(rid):
		if rescue_guest == null or rescue_guest.companion_id != rid:
			rescue_guest = NpcLibrary.make_recruit(rid, player.level - 1)
		if not out.has(rescue_guest):
			out.append(rescue_guest)
	return out


## Lowers the difficulty mid-run (it can never be raised until New Game+).
func set_difficulty(level: int) -> bool:
	if not Difficulty.is_valid(level) or level > difficulty:
		return false
	difficulty = level
	return true


## Sets up a battle for this run: floor/difficulty enemy scale, rewards,
## bag, loot level and bestiary (the battle screen and the simulator use it).
func configure_battle(battle: BattleManager) -> void:
	battle.enemy_scale = pending_enemy_scale
	battle.boss_hp_mult = guardian_hp_mult(party_size())
	battle.normal_hp_mult = normal_hp_mult(party_size())
	battle.enemy_skill_mult = Difficulty.value(difficulty, "ai")
	var rewards := reward_scale_for_floor(floor_number)
	if pending_battle_info.get("kind", "normal") in THEMED_KINDS:
		rewards /= StageLibrary.theme_power(floor_number)   # their bigger rewards are scaled back too
	battle.xp_mult = Difficulty.value(difficulty, "xp") * rewards
	# Gold grows a little slower than XP, so shop prices still matter higher up.
	battle.gold_mult = Difficulty.value(difficulty, "gold") * pow(rewards, GOLD_REWARD_EXP)
	battle.inventory = inventory
	battle.loot_level = floor_number
	battle.owned_unique_classes = owned_unique_classes()
	battle.bestiary = bestiary


## Bosses, minibosses and roamers were tuned against GUARDIAN_TUNED_PARTY
## fighters; their HP follows how many can fight now (the party slots, so
## a solo run still faces the full boss): 2 -> x0.59, 6 -> x1.36, 10 -> x2.0.
const GUARDIAN_TUNED_PARTY := 4.0
const GUARDIAN_PARTY_EXP := 0.75


static func guardian_hp_mult(slots: int) -> float:
	return pow(slots / GUARDIAN_TUNED_PARTY, GUARDIAN_PARTY_EXP)


## Normal enemies follow the party slots too, more gently: a duo's fights
## are swingier (one crit downs half the party), a big party's are easier.
## 2 -> x0.71, 6 -> x1.22, 10 -> x1.58 (balance pass 2, 2026-10-25).
const NORMAL_PARTY_EXP := 0.5


static func normal_hp_mult(slots: int) -> float:
	return pow(slots / GUARDIAN_TUNED_PARTY, NORMAL_PARTY_EXP)


## How many can fight right now (player included); see PARTY_START_SIZE.
func party_size() -> int:
	return party_size_at(highest_floor)


static func party_size_at(floor_n: int) -> int:
	return mini(MAX_PARTY_SIZE, PARTY_START_SIZE + PARTY_GROWTH * ((maxi(floor_n, 1) - 1) / PARTY_GROWTH_FLOORS))


## Player first, then companions, capped at party_size().
func battle_party() -> Array[CharacterData]:
	var out: Array[CharacterData] = [player]
	for c in companions:
		if out.size() >= party_size():
			break
		out.append(c)
	return out


func party_all_downed() -> bool:
	for c in battle_party():
		if not c.is_downed():
			return false
	return true


func full_restore_party() -> void:
	for c in battle_party():
		c.full_restore()


# =========================================================
# Tower
# =========================================================

## Every 5th floor, except stage-boss floors (those get a campfire AFTER the boss).
static func is_rest_floor(n: int) -> bool:
	return n % REST_FLOOR_INTERVAL == 0 and not StageLibrary.is_boss_floor(n)


## Normal enemy groups never outnumber your party by more than this
## (groups are written for a full party; a pair meets smaller ones).
const MAX_EXTRA_ENEMIES := 0
## Beating a sponsored boss: interest its patron loses, and its rivals gain.
const BOSS_PATRON_INTEREST := 10
## Fights against the stage theme's own enemies (StageLibrary "power" applies).
const THEMED_KINDS := ["normal", "miniboss", "boss"]

## Battle XP and gold grow with the enemies' strength (relative to floor 1),
## to this power, so levelling and income keep pace higher up.
const REWARD_EXP := 1.0
## Gold's share of that growth (1.0 = same as XP).
const GOLD_REWARD_EXP := 0.7


static func reward_scale_for_floor(n: int) -> float:
	return pow(enemy_scale_for_floor(n) / enemy_scale_for_floor(1), REWARD_EXP)


## Past LATE_SCALE_FROM the curve gets steeper: tier-3 classes (+20%) and
## 6+ fighters made floors 41-60 too easy (balance pass 2, 2026-10-25).
const LATE_SCALE_FROM := 40
const ENEMY_SCALE_LATE_PER_FLOOR := 0.02


static func enemy_scale_for_floor(n: int) -> float:
	return ENEMY_SCALE_BASE + ENEMY_SCALE_PER_FLOOR * (n - 1) \
		+ ENEMY_SCALE_LATE_PER_FLOOR * maxi(0, n - LATE_SCALE_FROM)


func enter_floor(n: int) -> void:
	floor_number = n
	var room_before := party_size()
	highest_floor = maxi(highest_floor, n)
	if party_size() > room_before:
		_party_grows()
	var gate: int = ClassRegistry.ADVANCEMENT_GATES[2].floor
	if n == gate + 1 and battle_party().any(func(m): return m.class_change_open()):
		quests.messages.append("Advancement is open. Each climber may also change class once, with a free respec (Tab).")
	floor_seed = randi()
	floor_ready = false
	floor_enemies.clear()
	floor_player_pos = Vector2i(-1, -1)
	if is_rest_floor(n):
		checkpoint_floor = n
	quests.update()   # "reach floor" steps, and quests that expire past a floor
	blessings.update()   # lingering curses run out by floor
	# The guilds take their turn (AI: trade, raid, wars...), prices drift back,
	# guild pay comes due. Seeded per run + floor so a run replays the same.
	var guild_rng := RandomNumberGenerator.new()
	guild_rng.seed = ("%s:%d:guilds" % [player.legacy_id, n]).hash()
	guilds.on_floor(guild_rng)


## Builds the layout for the current floor. First visit also rolls the enemies
## and their encounter groups; later visits reuse the saved enemy list.
##
## Each floor enemy: { "pos", "group", "alive", "kind" } where kind is
## "normal", "miniboss", "boss" or "roaming".
func current_layout() -> FloorLayout:
	var n := floor_number
	var layout := FloorLayout.generate(floor_seed, n, is_rest_floor(n),
		StageLibrary.is_miniboss_floor(n), StageLibrary.is_boss_floor(n))
	if not floor_ready:
		var rng := RandomNumberGenerator.new()
		rng.seed = floor_seed + 7919
		floor_enemies.clear()
		var max_group := battle_party().size() + MAX_EXTRA_ENEMIES
		for spawn in layout.enemy_spawns:
			var group := EnemyLibrary.encounter_for_floor(n, rng)
			group.resize(mini(group.size(), max_group))   # a small party meets smaller groups
			floor_enemies.append({ "pos": spawn, "alive": true, "kind": "normal", "group": group })
		if layout.guardian_spot.x >= 0:
			var boss_floor := StageLibrary.is_boss_floor(n)
			var group: Array[StringName] = StageLibrary.boss_for_floor(n) if boss_floor else StageLibrary.miniboss_for_floor(n)
			var full_size := group.size()
			group.resize(mini(full_size, maxi(1, max_group)))   # escorts match your party's size too
			if boss_floor and Difficulty.is_hell(difficulty) and full_size > 1:
				group.append(StageLibrary.boss_for_floor(n)[-1])   # Hell: stage bosses bring an extra escort
			floor_enemies.append({ "pos": layout.guardian_spot, "alive": true,
				"kind": "boss" if boss_floor else "miniboss", "group": group })
		_maybe_spawn_roamer(layout, rng)
		_maybe_spawn_guild_fighters(layout, rng)
		_maybe_spawn_rescue(layout)
		floor_player_pos = layout.start
		floor_ready = true
	# Boss arenas only get their campfire + merchant once the boss is down.
	if layout.is_boss_floor and stairs_locked():
		layout.campfire = Vector2i(-1, -1)
		layout.merchant = Vector2i(-1, -1)
	place_npcs(layout)
	return layout


## "rest", "boss", "miniboss" or "combat" (NpcLibrary uses these).
func floor_kind(n: int) -> String:
	if is_rest_floor(n):
		return "rest"
	if StageLibrary.is_boss_floor(n):
		return "boss"
	if StageLibrary.is_miniboss_floor(n):
		return "miniboss"
	return "combat"


## (Re)places this floor's NPCs and lore objects. Called when the floor is
## built and again after a conversation (a clue that's been read disappears,
## a recruit leaves with you). Each NPC rolls from its own seed, so they stand
## in the same spot every time you come back.
func place_npcs(layout: FloorLayout) -> void:
	layout.npcs.clear()
	var kind := floor_kind(floor_number)
	if kind == "boss" and stairs_locked():
		return   # nobody hangs around a boss fight
	var rng_for := func(id: StringName) -> RandomNumberGenerator:
		var rng := RandomNumberGenerator.new()
		rng.seed = ("%d:%s" % [floor_seed, id]).hash()
		return rng
	for id in NpcLibrary.npcs_for_floor(floor_number, kind, rng_for):
		var near := Vector2i(-1, -1)
		match NpcLibrary.get_npc(id).get("near", ""):
			"campfire": near = layout.campfire
			"merchant": near = layout.merchant
		var rng: RandomNumberGenerator = rng_for.call(id)
		rng.randf()   # skip the roll used for "chance"
		layout.place_npc(id, rng, near)
	# Dismissed companions wait by the campfire (anywhere, if it's crowded).
	if layout.campfire.x >= 0:
		for c in waiting:
			var id := waiting_npc_id(c)
			if layout.place_npc(id, rng_for.call(id), layout.campfire).x < 0:
				layout.place_npc(id, rng_for.call(id))
	# Shrines of beings ready to offer you a blessing (rest floors only).
	if kind == "rest":
		for being in blessings.offering_beings().slice(0, BlessingState.MAX_SHRINES):
			var sid := StringName("shrine:" + String(being))
			layout.place_npc(sid, rng_for.call(sid))
	# The guild that runs this territory has an agent on its first floor and
	# its rest floors (join, ranks, guild shop, pay).
	if kind == "rest" or GuildLibrary.is_territory_start(floor_number):
		var owner := guilds.owner_of_floor(floor_number)
		if owner != &"":
			var gid := StringName("guild:" + String(owner))
			layout.place_npc(gid, rng_for.call(gid))


## The guild behind a floor agent id ("guild:golden_ledger"), or &"".
static func agent_guild(npc_id: StringName) -> StringName:
	var s := String(npc_id)
	return StringName(s.trim_prefix("guild:")) if s.begins_with("guild:") else &""


## The being behind a floor shrine id ("shrine:odin"), or &"".
static func shrine_being(npc_id: StringName) -> StringName:
	var s := String(npc_id)
	return StringName(s.trim_prefix("shrine:")) if s.begins_with("shrine:") else &""


## Floor NPC id for a waiting companion: "waiting:<companion_id>".
static func waiting_npc_id(c: CharacterData) -> StringName:
	return StringName("waiting:" + String(c.companion_id))


## The waiting companion behind a floor NPC id (null if it isn't one).
func waiting_companion(npc_id: StringName) -> CharacterData:
	for c in waiting:
		if waiting_npc_id(c) == npc_id:
			return c
	return null


# =========================================================
# Recruiting
# =========================================================

## True if this NPC has joined you (party, reserve, or waiting at rest floors).
## Party + reserve + waiting companions and your captains (your guild's members).
func member_count() -> int:
	return companions.size() + reserve.size() + waiting.size() + guilds.captains.size()


## Guild fighters on a normal floor: guards of guilds that hunt you (hated,
## robbed, or at war with your side) replace up to two normal enemies, and a
## territory's champion waits on its first floor if you can challenge it.
func _maybe_spawn_guild_fighters(layout: FloorLayout, rng: RandomNumberGenerator) -> void:
	if floor_kind(floor_number) != "combat":
		return
	var hunters: Array = []
	var owner := guilds.owner_of_floor(floor_number)
	if guilds.is_hostile(owner):
		hunters.append(owner)
	var t := GuildLibrary.territory_of(floor_number) % maxi(1, guilds.owners.size())
	for w in guilds.wars:   # your war's enemy patrols the contested floors
		if w.territory == t and guilds.player_side() in [w.attacker, w.defender]:
			var enemy: StringName = w.defender if w.attacker == guilds.player_side() else w.attacker
			if not hunters.has(enemy):
				hunters.append(enemy)
	var normals := floor_enemies.filter(func(e): return e.kind == "normal")
	var i := 0
	for g in hunters:
		for k in 2:
			if i >= normals.size():
				break
			var e: Dictionary = normals[i]
			e.kind = "guard"
			e["guild"] = g
			e.group = StageLibrary._typed(GuildLibrary.GUARD_GROUPS[rng.randi_range(0, GuildLibrary.GUARD_GROUPS.size() - 1)])
			i += 1
	if GuildLibrary.is_territory_start(floor_number) and i < normals.size():
		# A territory's champion, or the war leader of a guild attacking yours.
		var leader := owner if guilds.champion_waiting(t) else guilds.siege_leader(t)
		if leader != &"":
			var c: Dictionary = normals[i]
			c.kind = "champion"
			c["guild"] = leader
			c.group = StageLibrary._typed(GuildLibrary.CHAMPION_GROUP)


## Try to steal `id` from this floor's trader. "stolen", "caught" or "".
func steal_item(id: StringName) -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return guilds.try_steal(id, rng)


func has_recruited(npc_id: StringName) -> bool:
	for c in companions + reserve + waiting + guilds.captains.values() + guilds.captives.map(func(cap): return cap.c):
		if c.companion_id == npc_id:
			return true
	return false


## Recruits an NPC at the player's level - 1. Joins the party if there's room,
## then the reserve, then waits at rest floors. Returns the new member (null if
## not recruitable or already recruited).
func recruit(npc_id: StringName) -> CharacterData:
	if not NpcLibrary.is_recruitable(npc_id) or has_recruited(npc_id) or npc_refuses(npc_id):
		return null
	var c := NpcLibrary.make_recruit(npc_id, player.level - 1)
	_welcome(c)
	return c


## Someone joins: into the party (or reserve / waiting), and their loyalty
## quest starts (finishing it unlocks their personal skill).
func _welcome(c: CharacterData) -> void:
	_add_member(c)
	quests.start(QuestLibrary.loyalty_id(c.companion_id))


## A rescue fight's recruit, built when the fight starts (null = none).
var rescue_guest: CharacterData


## Recruits met in a fight: on their range of combat floors (in this run),
## the first normal group there becomes "rescue": someone is fighting it.
func _maybe_spawn_rescue(layout: FloorLayout) -> void:
	if floor_kind(floor_number) != "combat":
		return
	for id in NpcLibrary.recruits_met_by("rescue"):
		var r := NpcLibrary.recruit_info(id)
		var span: Array = r.get("rescue_floors", [0, -1])
		if has_recruited(id) or not NpcLibrary.in_this_run(id) or floor_number < span[0] or floor_number > span[1]:
			continue
		for e in floor_enemies:
			if e.kind == "normal":
				e.kind = "rescue"
				e["recruit"] = id
				return


## A boss is down: anyone it held captive is free (and joins).
func _free_captives(boss_id: StringName) -> void:
	for id in NpcLibrary.recruits_met_by("captive"):
		if NpcLibrary.recruit_info(id).get("captive_of", &"") == boss_id and not has_recruited(id):
			var c := NpcLibrary.make_recruit(id, player.level - 1)
			_welcome(c)
			quests.messages.append("%s is free and joins you!" % c.character_name)


## The party just got bigger: the reserve fills the new places (in bench
## order), and a notice says so.
func _party_grows() -> void:
	var filled := []
	while companions.size() < party_size() - 1 and not reserve.is_empty():
		var c: CharacterData = reserve.pop_front()
		companions.append(c)
		filled.append(c.character_name)
	var msg := "Your party can now field %d fighters!" % party_size()
	if not filled.is_empty():
		msg += " %s step%s up from the reserve." % [", ".join(filled), "s" if filled.size() == 1 else ""]
	quests.messages.append(msg)


## Party if there's room, then the reserve, then waiting at rest floors.
func _add_member(c: CharacterData) -> void:
	if companions.size() < party_size() - 1:
		companions.append(c)
	elif reserve.size() < RESERVE_CAP:
		reserve.append(c)
	else:
		waiting.append(c)


# =========================================================
# Party management
# =========================================================
# Swapping, benching, dismissing and rejoining are locked on a floor whose
# miniboss or boss is still standing: plan your party on the floors before.
# Reordering and rows can be changed any time out of battle.

func party_locked() -> bool:
	return stairs_locked()


func party_lock_reason() -> String:
	if not party_locked():
		return ""
	return "The party is locked until this floor's %s is beaten." % (
		"boss" if StageLibrary.is_boss_floor(floor_number) else "miniboss")


## Party -> reserve. False if locked, not in the party, or the bench is full.
func bench(c: CharacterData) -> bool:
	if party_locked() or not companions.has(c) or reserve.size() >= RESERVE_CAP:
		return false
	companions.erase(c)
	reserve.append(c)
	return true


## Reserve -> party. False if locked, not on the reserve, or the party is full.
func unbench(c: CharacterData) -> bool:
	if party_locked() or not reserve.has(c) or companions.size() >= party_size() - 1:
		return false
	reserve.erase(c)
	companions.append(c)
	return true


## Swaps a party member with a reserve member; the newcomer takes their place
## in the party order.
func swap_members(in_party: CharacterData, on_bench: CharacterData) -> bool:
	if party_locked() or not companions.has(in_party) or not reserve.has(on_bench):
		return false
	companions[companions.find(in_party)] = on_bench
	reserve[reserve.find(on_bench)] = in_party
	return true


## Moves a companion up (-1) or down (+1) in the party order. The player is
## always first, so this only reorders companions.
func move_member(c: CharacterData, delta: int) -> bool:
	var i := companions.find(c)
	var j := i + delta
	if i < 0 or j < 0 or j >= companions.size():
		return false
	companions[i] = companions[j]
	companions[j] = c
	return true


## Sets the row they start battles in (Combatant.Row).
func set_member_row(c: CharacterData, row: int) -> void:
	c.battle_row = clampi(row, Combatant.Row.FRONT, Combatant.Row.BACK)


## The row they'll start the next battle in.
static func member_row(c: CharacterData) -> int:
	return c.battle_row if c.battle_row >= 0 else SkillLibrary.default_row_for_class(c.class_id)


## Lets a companion go. Their gear goes to the bag, and they wait by the
## campfire on rest floors until you take them back. Not permanent.
func dismiss(c: CharacterData) -> bool:
	if party_locked() or c == player or not (companions.has(c) or reserve.has(c)):
		return false
	for slot in c.equipment.keys():
		unequip_to_bag(c, slot)
	companions.erase(c)
	reserve.erase(c)
	if c.companion_id == &"":
		c.companion_id = StringName("companion_%d" % randi())   # needs an id to wait on a floor
	waiting.append(c)
	return true


## A waiting companion comes back: party if there's room, else the reserve.
## False if locked or there's no room anywhere.
func rejoin(c: CharacterData) -> bool:
	if party_locked() or not waiting.has(c) or refuses_to_rejoin(c):
		return false
	if companions.size() >= party_size() - 1 and reserve.size() >= RESERVE_CAP:
		return false
	waiting.erase(c)
	_add_member(c)
	return true


# =========================================================
# Routes (Hero / Villain / Vigilante ...) — see RouteLibrary
# =========================================================

## Placeholder values for the childhood friend (recruits keep theirs in NpcLibrary).
const CHILDHOOD_FRIEND_VALUES := { "likes": [&"hero"], "dislikes": [&"villain"] }
## A companion who's been warned leaves once a route they dislike has this many
## points (or gets locked).
const COMPANION_LEAVE_POINTS := 20
## Merchant prices while leaning hero / villain. Locked villains are refused.
const HERO_PRICE_MULT := 0.9
const VILLAIN_PRICE_MULT := 1.25


func add_route_points(id: StringName, amount: int) -> void:
	route.add(id, amount)
	_check_companions()
	blessings.update()   # beings react to what you do


## A key story choice. False if a route is already locked.
func lock_route(id: StringName) -> bool:
	var ok := route.lock(id)
	if ok:
		_check_companions()
		blessings.update()
	return ok


## { "likes": [route ids], "dislikes": [...] } for a companion.
func companion_values(c: CharacterData) -> Dictionary:
	if c.companion_id == &"childhood_friend":
		return CHILDHOOD_FRIEND_VALUES
	return NpcLibrary.get_npc(c.companion_id).get("values", {})


func disagrees(c: CharacterData) -> bool:
	var r := route.current()
	return r != &"" and companion_values(c).get("dislikes", []).has(r)


## A recruitable NPC won't join someone on a route they dislike.
func npc_refuses(npc_id: StringName) -> bool:
	var r := route.current()
	return r != &"" and NpcLibrary.get_npc(npc_id).get("values", {}).get("dislikes", []).has(r)


## Someone who left over your route won't come back while you're still on it.
func refuses_to_rejoin(c: CharacterData) -> bool:
	return has_flag(StringName("route_left_%s" % c.companion_id)) and disagrees(c)


## After the route changes: companions who dislike it warn you first, then leave.
func _check_companions() -> void:
	for c in companions + reserve:
		if not disagrees(c):
			continue
		var warned := StringName("route_warned_%s" % c.companion_id)
		if not has_flag(warned):
			story_flags[warned] = true
			pending_talks.append({ "dialogue": &"companion_warning", "companion": c })
			continue
		var r := route.current()
		if route.locked == r or route.points_of(r) >= COMPANION_LEAVE_POINTS:
			leave_over_route(c)


## The companion walks away: gear to the bag, waits at rest floors, and won't
## rejoin until your route changes. Works even on a locked floor (it's their choice).
func leave_over_route(c: CharacterData) -> void:
	if not (companions.has(c) or reserve.has(c)):
		return
	for slot in c.equipment.keys():
		unequip_to_bag(c, slot)
	companions.erase(c)
	reserve.erase(c)
	if c.companion_id == &"":
		c.companion_id = StringName("companion_%d" % randi())
	waiting.append(c)
	story_flags[StringName("route_left_%s" % c.companion_id)] = true
	pending_talks.append({ "dialogue": &"companion_leaving", "companion": c })


## What the merchant charges you: your route (hero discount / villain
## markup), blessings and curses, the guild that runs this floor (its markup,
## your member discount) and supply and demand in this territory.
func shop_price(item: ItemDef) -> int:
	var mult := 1.0
	match route.current():
		&"hero": mult = HERO_PRICE_MULT
		&"villain": mult = VILLAIN_PRICE_MULT
	mult += player.effect_sum("price_mult")   # e.g. the Demon of Greed's curse
	mult *= guilds.price_mult(floor_number)
	mult *= guilds.buy_mult(GuildLibrary.territory_of(floor_number), GuildState.good_key(item.id))
	return roundi(item.price * maxf(0.1, mult) * difficulty_price_mult())


## Hell: consumables cost more.
func difficulty_price_mult() -> float:
	return Difficulty.HELL_CONSUMABLE_PRICE if Difficulty.is_hell(difficulty) else 1.0


## False for items traders won't sell on this difficulty (Hell: Scouting Lens).
func for_sale(id: StringName) -> bool:
	return not (Difficulty.is_hell(difficulty) and Difficulty.HELL_BANNED_ITEMS.has(id))


# =========================================================
# Economy: taxes and selling
# =========================================================

## Base sell value of gear by rarity (+ SELL_PER_ITEM_LEVEL each item level).
## Uniques can't be sold.
const SELL_GEAR_BASE := [10, 25, 60, 140, 320]
const SELL_PER_ITEM_LEVEL := 3
## Consumables sell for this share of their price; skill books for a flat
## amount per tier.
const SELL_ITEM_SHARE := 0.5
const SELL_BOOK_PER_TIER := 30


## The floor owner's cut of battle gold you just earned. Returns the tax taken.
func collect_battle_tax(gold_earned: int) -> int:
	var tax := mini(guilds.collect_tax(gold_earned, floor_number), player.gold)
	player.gold -= tax
	return tax


## What a trader pays for one of an item / a piece of gear right now
## (0 = can't be sold: quest items, Uniques).
func sell_price_item(id: StringName) -> int:
	var item := ItemLibrary.get_item(id)
	if item == null or item.quest_item:
		return 0
	var base := roundi(item.price * SELL_ITEM_SHARE) if item.price > 0 else SELL_BOOK_PER_TIER * (item.tier + 1)
	return maxi(1, roundi(base * guilds.sell_mult(GuildLibrary.territory_of(floor_number), GuildState.good_key(id))))


func sell_price_gear(g: GearItem) -> int:
	if g == null or g.rarity == Rarity.Tier.UNIQUE:
		return 0
	var base: int = SELL_GEAR_BASE[clampi(g.rarity, 0, SELL_GEAR_BASE.size() - 1)] + SELL_PER_ITEM_LEVEL * g.item_level
	return maxi(1, roundi(base * guilds.sell_mult(GuildLibrary.territory_of(floor_number), GuildState.good_key(&"", g))))


## Sells one item from the bag. Returns the gold received (0 = couldn't).
func sell_item(id: StringName) -> int:
	var price := sell_price_item(id)
	if price <= 0 or not inventory.remove(id):
		return 0
	player.gold += price
	guilds.record_sell(GuildLibrary.territory_of(floor_number), GuildState.good_key(id))
	return price


## Sells a piece of gear from the bag (never equipped gear or Uniques).
func sell_gear(g: GearItem) -> int:
	var price := sell_price_gear(g)
	if price <= 0 or not inventory.remove_gear(g):
		return 0
	player.gold += price
	guilds.record_sell(GuildLibrary.territory_of(floor_number), GuildState.good_key(&"", g))
	return price


## After a won battle: everyone on the reserve gets their share of the XP.
## Returns the amount each got.
func grant_reserve_xp(battle_xp: int, fought: Array = []) -> int:
	var share := floori(battle_xp * RESERVE_XP_SHARE)
	if share <= 0:
		return 0
	for c in reserve:
		c.add_xp(share)
	# Guild captains on duty learn too (unless they were in this fight already).
	var captain_share := floori(battle_xp * GuildState.CAPTAIN_XP_SHARE)
	for c in guilds.captains.values():
		if not fought.has(c):
			c.add_xp(captain_share)
	return share


## Plain combat floors past the first few may have a roaming boss wandering them.
## It replaces one of the normal enemies.
func _maybe_spawn_roamer(layout: FloorLayout, rng: RandomNumberGenerator) -> void:
	var n := floor_number
	if is_rest_floor(n) or StageLibrary.is_boss_floor(n) or StageLibrary.is_miniboss_floor(n):
		return
	var pick := StageLibrary.guaranteed_roamer(n, defeated_roamers, story_flags)
	if pick.is_empty():
		var options := StageLibrary.eligible_roamers(n, defeated_roamers)
		if options.is_empty() or rng.randf() >= StageLibrary.ROAMING_SPAWN_CHANCE:
			return
		pick = options[rng.randi_range(0, options.size() - 1)]
	for e in floor_enemies:
		if e.kind == "normal":
			e.kind = "roaming"
			e.group = StageLibrary._typed(pick.group)
			e.roamer_id = pick.id
			return


## Set by a secret-class unlock so the tower can announce it. Cleared once shown.
var pending_unlock_message: String = ""


func _check_secret_unlock(roamer_id: StringName) -> void:
	var path := SecretPaths.path_completed_by(roamer_id, story_flags)
	if path == &"":
		return
	set_flag(SecretPaths.PATHS[path].unlock_flag)
	var def := ClassRegistry.get_class_def(SecretPaths.PATHS[path].class_id)
	pending_unlock_message = "✦ Secret class unlocked: %s! (Tab → party menu)" % def.display_name


## Secret classes from questlines, plus New Game+ classes during an NG+ run.
func unlocked_secret_classes() -> Array:
	var out := SecretPaths.unlocked_classes(story_flags)
	if ng_plus_cycle > 0:
		for def in ClassRegistry.get_all():
			if def.ng_plus_only and not out.has(def.id):
				out.append(def.id)
	return out


## The player character switches to an unlocked secret class (stat gate applies).
## The one free class change: they give up their class (gear locked to it
## goes back in the bag) and pick again.
func release_class(member: CharacterData) -> bool:
	if not member.release_class():
		return false
	for slot in member.equipment.keys():
		if not member.get_equipped(slot).can_equip(member):
			unequip_to_bag(member, slot)
	return true


func take_secret_class(member: CharacterData, class_id: StringName) -> bool:
	if member != player or not unlocked_secret_classes().has(class_id):
		return false
	if not member.take_secret_class(ClassRegistry.get_class_def(class_id)):
		return false
	# Class-locked gear (e.g. another class's Unique) goes back in the bag.
	for slot in member.equipment.keys():
		if not member.get_equipped(slot).can_equip(member):
			unequip_to_bag(member, slot)
	return true


func set_flag(flag: StringName, value: bool = true) -> void:
	if value:
		story_flags[flag] = true
	else:
		story_flags.erase(flag)
	quests.update()   # talk / find steps complete when their flag is set


func has_flag(flag: StringName) -> bool:
	return story_flags.get(flag, false)


func enemy_kind(e: Dictionary) -> String:
	return e.get("kind", "normal")


func floor_has_alive(kind: String) -> Dictionary:
	for e in floor_enemies:
		if e.alive and enemy_kind(e) == kind:
			return e
	return {}


## The stairs stay sealed until this floor's miniboss or boss is beaten.
func stairs_locked() -> bool:
	return not floor_has_alive("miniboss").is_empty() or not floor_has_alive("boss").is_empty()


func start_floor_battle(enemy_index: int) -> void:
	prepare_floor_battle(enemy_index)
	get_tree().change_scene_to_file(BATTLE_SCENE)


## Sets up the fight with floor enemy `enemy_index` (encounter, scale, kind)
## without changing scene. The balance simulator calls this directly.
func prepare_floor_battle(enemy_index: int) -> void:
	var e: Dictionary = floor_enemies[enemy_index]
	var kind := enemy_kind(e)
	# Minibosses and bosses are hand-tuned for their stage, so they use the
	# stage scale instead of the per-floor curve. Normal and roaming enemies
	# scale with the floor.
	var scale := StageLibrary.guardian_scale(floor_number) if kind == "miniboss" or kind == "boss" \
		else enemy_scale_for_floor(floor_number)
	scale *= ng_plus_scale(ng_plus_cycle) * Difficulty.value(difficulty, "enemy")
	if kind in THEMED_KINDS:
		scale /= StageLibrary.theme_power(floor_number)   # stronger themes get scaled back to the floor
	set_pending_battle(EnemyLibrary.build_group(e.group), TOWER_SCENE, scale, enemy_index,
		{ "kind": kind, "guild": e.get("guild", &""), "roamer_id": e.get("roamer_id", &""), "recruit": e.get("recruit", &"") })


# =========================================================
# Battles
# =========================================================

## `enemy_index` = which floor enemy started it (-1 for test battles).
func start_battle(encounter: Array[EnemyDef], return_to: String = "", scale: float = 1.0,
		enemy_index: int = -1, info: Dictionary = {}) -> void:
	set_pending_battle(encounter, return_to, scale, enemy_index, info)
	get_tree().change_scene_to_file(BATTLE_SCENE)


## The next battle's setup (read by the battle screen / configure_battle).
func set_pending_battle(encounter: Array[EnemyDef], return_to: String, scale: float, enemy_index: int,
		info: Dictionary) -> void:
	active_enemy_index = enemy_index
	pending_battle_info = info
	pending_encounter = encounter
	pending_enemy_scale = scale
	return_scene = return_to
	last_battle_outcome = -1


## Ironman: who dies if this fight ends now (anyone in it still down).
## `fighters` = the characters that fought (GameState.fighting_party()).
func ironman_deaths(fighters: Array, outcome: int) -> Array:
	if not ironman:
		return []
	if outcome == BattleManager.Outcome.DEFEAT:
		return fighters.duplicate()
	return fighters.filter(func(c): return c.is_downed())


## Ironman: buries the fallen. Returns true if the run is over (you died).
func apply_ironman_deaths(dead: Array) -> bool:
	if dead.has(player):
		return true
	for c in dead:
		for slot in c.equipment.keys():
			unequip_to_bag(c, slot)
		companions.erase(c)
		reserve.erase(c)
		for t in guilds.captains.keys():
			if guilds.captains[t] == c:
				guilds.captains.erase(t)
		fallen_companions.append(c.character_name)
		guilds.add_news("%s has fallen." % c.character_name)
	return false


## Ironman: you died. The Hall records it, the save is deleted, back to title.
func end_ironman_run(to_title := true) -> void:
	record_fallen()
	ironman_ended_message = "%s has fallen on floor %d.\n\n(%s) The run is over: the save is gone, but the Hall of Climbers remembers." % [
		player.character_name, floor_number, Difficulty.label(difficulty, ironman)]
	delete_slot(current_slot)
	run_active = false
	pending_encounter = []
	return_scene = ""
	if to_title and is_inside_tree():
		get_tree().change_scene_to_file(TITLE_SCENE)


## Called by the battle screen when the player leaves the result screen.
## `fighters` = who fought (for Ironman deaths).
func finish_battle(outcome: int, fighters: Array = []) -> void:
	if ironman and apply_ironman_deaths(ironman_deaths(fighters, outcome)):
		end_ironman_run()
		return
	last_battle_outcome = outcome
	if outcome == BattleManager.Outcome.VICTORY and active_enemy_index >= 0 \
			and active_enemy_index < floor_enemies.size():
		var e: Dictionary = floor_enemies[active_enemy_index]
		e.alive = false
		active_enemy_index = -1
		if enemy_kind(e) == "roaming":
			defeated_roamers.append(e.roamer_id)
			_check_secret_unlock(e.roamer_id)
		if enemy_kind(e) == "guard" or enemy_kind(e) == "champion":
			guilds.fight_won(e.get("guild", &""), enemy_kind(e) == "champion")
		if enemy_kind(e) == "rescue" and rescue_guest and rescue_guest.companion_id == e.get("recruit", &""):
			if not rescue_guest.is_downed() or not ironman:
				_welcome(rescue_guest)
				quests.messages.append("%s joins you!" % rescue_guest.character_name)
			rescue_guest = null
		if enemy_kind(e) in ["boss", "miniboss"]:
			_free_captives(e.group[0])
		if enemy_kind(e) == "boss":
			checkpoint_floor = floor_number   # the arena's campfire is your new checkpoint
			if floor_number >= FINAL_FLOOR:
				pending_completion = true
	if outcome == BattleManager.Outcome.VICTORY:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		quests.on_battle_won(pending_encounter, rng)   # defeat counts + quest-item drops
		guilds.roll_pickpocket(rng)   # lawless floors have light fingers
		# Blessings that heal after a win ("regen_pct").
		for m in battle_party():
			var regen := m.effect_sum("regen_pct")
			if regen > 0.0 and not m.is_downed():
				m.heal(roundi(m.max_hp() * regen))
		# A sponsored boss falls: its patron is annoyed, the patron's rivals approve.
		for d in pending_encounter:
			if d.patron != &"":
				blessings.add_interest(d.patron, -BOSS_PATRON_INTEREST)
				for rival in BeingLibrary.rivals_of(d.patron):
					blessings.add_interest(rival, BOSS_PATRON_INTEREST)
				blessings.messages.append("%s's champion has fallen. %s won't forget it." % [
					BeingLibrary.get_being(d.patron).get("name", "?"), BeingLibrary.get_being(d.patron).get("name", "?")])
		# A stage boss falls: an interested being may come calling.
		if pending_encounter.any(func(d): return SkillBooks.enemy_kind(d) == "boss"):
			var offers := blessings.offering_beings()
			if not offers.is_empty():
				pending_talks.append({ "dialogue": &"blessing_offer", "being": offers[0] })
	if outcome == BattleManager.Outcome.DEFEAT:
		handle_defeat()
	pending_encounter = []
	var dest := return_scene
	return_scene = ""
	if dest != "":
		get_tree().change_scene_to_file(dest)


## Party wipe: lose some gold, wake up fully healed at the last rest floor.
func handle_defeat() -> void:
	var lost := roundi(player.gold * Difficulty.value(difficulty, "wipe_gold"))
	player.gold -= lost
	full_restore_party()
	enter_floor(checkpoint_floor)
	active_enemy_index = -1


# =========================================================
# Out-of-battle actions
# =========================================================

## Cast a HEAL skill from the party menu. Returns HP restored (0 = failed).
func cast_field_heal(caster: CharacterData, skill: SkillDef, target: CharacterData) -> int:
	if skill == null or skill.effect != SkillDef.Effect.HEAL:
		return 0
	if caster.is_downed() or target.is_downed() or caster.current_mp() < skill.mp_cost:
		return 0
	if target.current_hp() >= target.max_hp():
		return 0
	caster.set_current_mp(caster.current_mp() - skill.mp_cost)
	return target.heal(DamageCalc.base_heal(caster.stats, skill, target.max_hp()))


## Cast a party-wide HEAL skill (e.g. Mend) out of battle. Returns total HP restored.
func cast_field_heal_all(caster: CharacterData, skill: SkillDef) -> int:
	if skill == null or skill.effect != SkillDef.Effect.HEAL or caster.is_downed() \
			or caster.current_mp() < skill.mp_cost:
		return 0
	var hurt := battle_party().filter(func(c): return not c.is_downed() and c.current_hp() < c.max_hp())
	if hurt.is_empty():
		return 0
	caster.set_current_mp(caster.current_mp() - skill.mp_cost)
	var total := 0
	for c in hurt:
		total += c.heal(DamageCalc.base_heal(caster.stats, skill, c.max_hp()))
	return total


## Moves a piece of gear from the bag onto a character (old piece goes back in the bag).
func equip_from_bag(member: CharacterData, item: GearItem) -> bool:
	if not inventory.gear.has(item) or not item.can_equip(member):
		return false
	inventory.remove_gear(item)
	var prev := member.equip(item)
	if prev:
		inventory.add_gear(prev)
	return true


func unequip_to_bag(member: CharacterData, slot: int) -> bool:
	var prev := member.unequip(slot)
	if prev == null:
		return false
	inventory.add_gear(prev)
	return true


## Classes whose Unique weapon is already in the bag or equipped by someone.
func owned_unique_classes() -> Array:
	var out := []
	var all_gear: Array = inventory.gear.duplicate()
	for m in battle_party() + reserve + waiting:
		all_gear.append_array(m.equipment.values())
	for g: GearItem in all_gear:
		if g.rarity == Rarity.Tier.UNIQUE and not out.has(g.class_lock):
			out.append(g.class_lock)
	return out


## Buys from the merchant (route prices) or, with `price_override`, from
## another trader like the black market.
func buy_item(id: StringName, price_override: int = -1) -> bool:
	var item := ItemLibrary.get_item(id)
	if item == null:
		return false
	var price := price_override if price_override >= 0 else shop_price(item)
	if player.gold < price or not inventory.has_room(id):
		return false
	player.gold -= price
	guilds.record_buy(GuildLibrary.territory_of(floor_number), GuildState.good_key(id))   # demand goes up
	inventory.add(id)
	return true


# =========================================================
# Test helpers
# =========================================================

## The companion every run starts with. Level 1, no class yet — you spend
## their points and pick their class at level 10, same as your own.
static func make_childhood_friend(friend_name: String = "") -> CharacterData:
	var f := CharacterData.new()
	f.character_name = CHILDHOOD_FRIEND_NAME
	f.rename(friend_name)   # blank/invalid -> keeps the default
	f.companion_id = &"childhood_friend"
	return f


## Placeholder companions so combat can be tested before recruiting exists.
func ensure_test_companions() -> void:
	if not companions.is_empty():
		return
	companions.append(make_premade("Brakka", &"tank",
		{Stats.Type.HEALTH: 12, Stats.Type.STAMINA: 12, Stats.Type.STRENGTH: 11}))
	companions.append(make_premade("Lyra", &"archer",
		{Stats.Type.AGILITY: 13, Stats.Type.STRENGTH: 10, Stats.Type.LUCK: 6, Stats.Type.STAMINA: 6}))
	companions.append(make_premade("Sera", &"support",
		{Stats.Type.INTELLIGENCE: 12, Stats.Type.STAMINA: 8, Stats.Type.HEALTH: 10, Stats.Type.AGILITY: 5}))


## Builds a level-10 character with the given allocation and class.
static func make_premade(p_name: String, class_id: StringName, allocation: Dictionary) -> CharacterData:
	var c := CharacterData.new()
	c.character_name = p_name
	while c.level < CharacterData.CLASS_UNLOCK_LEVEL:
		c.level_up()
	c.apply_allocation(allocation)
	if not c.choose_class(ClassRegistry.get_class_def(class_id)):
		push_warning("make_premade: %s doesn't qualify for %s" % [p_name, class_id])
	return c
