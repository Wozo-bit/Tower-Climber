extends Node
## Autoload "GameState": everything that survives scene changes — the party,
## the item bag, where you are in the tower, and the battle hand-off.

const MAX_PARTY_SIZE := 4
const BATTLE_SCENE := "res://scenes/battle.tscn"
const TOWER_SCENE := "res://scenes/tower_floor.tscn"
const TITLE_SCENE := "res://scenes/title.tscn"

## Beating the boss on this floor completes the game (character goes into the
## Hall of Climbers). The design target is 100 floors; 20 = end of stage 2 for now.
const FINAL_FLOOR := 20
## Each New Game+ cycle multiplies enemy strength by this much more (NG+1 = x1.5).
const NG_PLUS_SCALE_PER_CYCLE := 0.5

## A rest floor (campfire + merchant, no enemies) every N floors.
const REST_FLOOR_INTERVAL := 5
## Enemy HP/stat multiplier: floor 1 = 0.7, +0.08 per floor. Placeholder curve.
const ENEMY_SCALE_BASE := 0.7
const ENEMY_SCALE_PER_FLOOR := 0.08
## Fraction of the leader's gold lost on a party wipe.
const DEFEAT_GOLD_PENALTY := 0.2

const STARTING_ITEMS := { &"potion": 3, &"ether": 1 }
## Every run starts with your childhood friend (story canon). The player names
## them on the New Game screen; this is the default if they leave it blank.
const CHILDHOOD_FRIEND_NAME := "Rowan"

# --- Party ---
var player: CharacterData
var companions: Array[CharacterData] = []
## Recruits who joined while the party was full. They wait here (and get no
## XP) until party management lets you swap them in.
var reserve: Array[CharacterData] = []
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

# --- Story ---
## Story/clue flags: StringName -> true. Dialogue, lore objects and quests set these.
var story_flags: Dictionary = {}

# --- Run / meta ---
## 0 = normal game, 1 = first New Game+, ...
var ng_plus_cycle := 0
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
var return_scene: String = ""
var active_enemy_index := -1      # which floor enemy started the fight
var last_battle_outcome := -1     # BattleManager.Outcome, read by the tower on return


func _ready() -> void:
	_register_input_actions()


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
	story_flags = {}
	ng_plus_cycle = 0
	play_time_sec = 0.0
	pending_completion = false
	clock_paused = false
	pending_unlock_message = ""
	active_enemy_index = -1
	last_battle_outcome = -1


## Fresh run with a new level-1 character and their childhood friend, in `slot`.
## A blank `friend_name` uses the default (CHILDHOOD_FRIEND_NAME).
func start_new_game(character_name: String, friend_name: String = "", slot: int = 1) -> void:
	reset_run()
	current_slot = clampi(slot, 1, SLOT_COUNT)
	player.rename(character_name)
	player.legacy_id = _new_legacy_id()
	companions.append(make_childhood_friend(friend_name))
	run_active = true
	save_game()


## New Game+: continue a character from the Hall of Climbers. By default it uses
## the save slot that character conquered the tower in (record.slot), but the
## player may pick any slot (`slot`).
## Keeps level, stats and class, plus Unique gear (not questline rewards).
## Other gear, gold, consumables, tower progress and story flags reset, the
## childhood friend rejoins at level 1, and enemies get tougher each cycle.
func start_new_game_plus(record: LegacyRecord, slot: int = -1) -> void:
	reset_run()
	current_slot = clampi(slot, 1, SLOT_COUNT) if slot > 0 else ng_plus_slot_for(record)
	player = record.character.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	player.gold = 0
	for eq_slot in player.equipment.keys():
		if not player.get_equipped(eq_slot).carries_into_ng_plus():
			player.unequip(eq_slot)
	player.full_restore()
	if player.legacy_id == "":
		player.legacy_id = record.legacy_id
	for g in record.vault:
		if g.carries_into_ng_plus():
			inventory.add_gear(g.duplicate_deep(Resource.DEEP_DUPLICATE_ALL))
	companions.append(make_childhood_friend(record.friend_name))
	ng_plus_cycle = record.highest_cycle_cleared + 1
	run_active = true
	save_game()


static func ng_plus_slot_for(record: LegacyRecord) -> int:
	return clampi(record.slot, 1, SLOT_COUNT) if record.slot > 0 else 1


func childhood_friend() -> CharacterData:
	for c in companions:
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
		"inventory": SaveSerializer.inventory_to_dict(inventory),
		"floor_number": floor_number,
		"checkpoint_floor": checkpoint_floor,
		"floor_seed": floor_seed,
		"floor_ready": floor_ready,
		"floor_enemies": SaveSerializer.floor_enemies_to_array(floor_enemies),
		"floor_player_pos": [floor_player_pos.x, floor_player_pos.y],
		"defeated_roamers": defeated_roamers.map(func(id): return String(id)),
		"story_flags": story_flags.keys().map(func(f): return String(f)),
		"ng_plus_cycle": ng_plus_cycle,
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
	for id in S._a(d, "defeated_roamers"):
		if id is String:
			defeated_roamers.append(StringName(id))
	for f in S._a(d, "story_flags"):
		if f is String:
			story_flags[StringName(f)] = true
	ng_plus_cycle = S._i(d, "ng_plus_cycle", 0, 0, 999)
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
			"vault": r.vault.map(SaveSerializer.gear_to_dict),
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
	var friend := childhood_friend()
	if friend:
		rec.friend_name = friend.character_name
	# Unequipped Uniques (bag + companions' gear) go in the vault for New Game+.
	rec.vault.clear()
	var loose: Array = inventory.gear.duplicate()
	for c in companions + reserve:
		loose.append_array(c.equipment.values())
	for g: GearItem in loose:
		if g.carries_into_ng_plus():
			rec.vault.append(g.duplicate_deep(Resource.DEEP_DUPLICATE_ALL))
	rec.times_cleared += 1
	rec.highest_cycle_cleared = maxi(rec.highest_cycle_cleared, ng_plus_cycle)
	rec.last_cleared_at = now
	if rec.best_play_time_sec <= 0.0 or play_time_sec < rec.best_play_time_sec:
		rec.best_play_time_sec = play_time_sec
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


## Player first, then companions, capped at MAX_PARTY_SIZE.
func battle_party() -> Array[CharacterData]:
	var out: Array[CharacterData] = [player]
	for c in companions:
		if out.size() >= MAX_PARTY_SIZE:
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


static func enemy_scale_for_floor(n: int) -> float:
	return ENEMY_SCALE_BASE + ENEMY_SCALE_PER_FLOOR * (n - 1)


func enter_floor(n: int) -> void:
	floor_number = n
	floor_seed = randi()
	floor_ready = false
	floor_enemies.clear()
	floor_player_pos = Vector2i(-1, -1)
	if is_rest_floor(n):
		checkpoint_floor = n


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
		for spawn in layout.enemy_spawns:
			floor_enemies.append({ "pos": spawn, "alive": true, "kind": "normal",
				"group": EnemyLibrary.encounter_for_floor(n, rng) })
		if layout.guardian_spot.x >= 0:
			var boss_floor := StageLibrary.is_boss_floor(n)
			floor_enemies.append({ "pos": layout.guardian_spot, "alive": true,
				"kind": "boss" if boss_floor else "miniboss",
				"group": StageLibrary.boss_for_floor(n) if boss_floor else StageLibrary.miniboss_for_floor(n) })
		_maybe_spawn_roamer(layout, rng)
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


# =========================================================
# Recruiting
# =========================================================

## True if this NPC is in the party or on the reserve bench.
func has_recruited(npc_id: StringName) -> bool:
	for c in companions + reserve:
		if c.companion_id == npc_id:
			return true
	return false


## Recruits an NPC at the player's level - 1. Joins the party if there's room,
## otherwise the reserve. Returns the new member (null if not recruitable or
## already recruited).
func recruit(npc_id: StringName) -> CharacterData:
	if not NpcLibrary.is_recruitable(npc_id) or has_recruited(npc_id):
		return null
	var c := NpcLibrary.make_recruit(npc_id, player.level - 1)
	if companions.size() < MAX_PARTY_SIZE - 1:
		companions.append(c)
	else:
		reserve.append(c)
	return c


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
	var e: Dictionary = floor_enemies[enemy_index]
	var kind := enemy_kind(e)
	# Minibosses and bosses are hand-tuned for their stage, so they use the
	# stage scale instead of the per-floor curve. Normal and roaming enemies
	# scale with the floor.
	var scale := StageLibrary.guardian_scale(floor_number) if kind == "miniboss" or kind == "boss" \
		else enemy_scale_for_floor(floor_number)
	scale *= ng_plus_scale(ng_plus_cycle)
	start_battle(EnemyLibrary.build_group(e.group), TOWER_SCENE, scale, enemy_index)


# =========================================================
# Battles
# =========================================================

## `enemy_index` = which floor enemy started it (-1 for test battles).
func start_battle(encounter: Array[EnemyDef], return_to: String = "", scale: float = 1.0,
		enemy_index: int = -1) -> void:
	active_enemy_index = enemy_index
	pending_encounter = encounter
	pending_enemy_scale = scale
	return_scene = return_to
	last_battle_outcome = -1
	get_tree().change_scene_to_file(BATTLE_SCENE)


## Called by the battle screen when the player leaves the result screen.
func finish_battle(outcome: int) -> void:
	last_battle_outcome = outcome
	if outcome == BattleManager.Outcome.VICTORY and active_enemy_index >= 0 \
			and active_enemy_index < floor_enemies.size():
		var e: Dictionary = floor_enemies[active_enemy_index]
		e.alive = false
		active_enemy_index = -1
		if enemy_kind(e) == "roaming":
			defeated_roamers.append(e.roamer_id)
			_check_secret_unlock(e.roamer_id)
		if enemy_kind(e) == "boss":
			checkpoint_floor = floor_number   # the arena's campfire is your new checkpoint
			if floor_number >= FINAL_FLOOR:
				pending_completion = true
	if outcome == BattleManager.Outcome.DEFEAT:
		handle_defeat()
	pending_encounter = []
	var dest := return_scene
	return_scene = ""
	if dest != "":
		get_tree().change_scene_to_file(dest)


## Party wipe: lose some gold, wake up fully healed at the last rest floor.
func handle_defeat() -> void:
	var lost := roundi(player.gold * DEFEAT_GOLD_PENALTY)
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
	for m in battle_party() + reserve:
		all_gear.append_array(m.equipment.values())
	for g: GearItem in all_gear:
		if g.rarity == Rarity.Tier.UNIQUE and not out.has(g.class_lock):
			out.append(g.class_lock)
	return out


func buy_item(id: StringName) -> bool:
	var item := ItemLibrary.get_item(id)
	if item == null or player.gold < item.price:
		return false
	player.gold -= item.price
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
