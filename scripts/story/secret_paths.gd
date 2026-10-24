class_name SecretPaths
extends RefCounted
## Secret-class questlines. Each path:
##   1. Clue flags, picked up from dialogue, lore objects, found items, etc.
##      (whatever calls GameState.set_flag()).
##   2. Once `clues_to_start` clues are found, the player is "on the path" and
##      the path's roaming boss (`final_roamer`) is guaranteed to show up.
##   3. FINAL STEP: beating that roaming boss sets `unlock_flag`, which unlocks
##      the secret class. The class still has its own stat gate (ClassDef).

const PATHS := {
	&"ashbound": {
		"class_id": &"ashbound_knight",
		"clue_flags": [
			&"clue_ash_scorched_mural",       # environmental/lore trigger
			&"clue_ash_merchant_story",       # dialogue choice
			&"clue_ash_feather_in_embers",    # found item
		],
		## How many clues it takes before the final step (the roaming boss) appears.
		## All of them by default, so the boss really is the last step.
		"clues_to_start": 3,
		"final_roamer": &"ashen_wyrmling",
		"unlock_flag": &"ashbound_unlocked",
	},
}


static func clues_found(path_id: StringName, flags: Dictionary) -> int:
	var path: Dictionary = PATHS.get(path_id, {})
	var n := 0
	for f in path.get("clue_flags", []):
		if flags.get(f, false):
			n += 1
	return n


static func is_on_path(path_id: StringName, flags: Dictionary) -> bool:
	var path: Dictionary = PATHS.get(path_id, {})
	return not path.is_empty() and clues_found(path_id, flags) >= path.clues_to_start


static func is_unlocked(path_id: StringName, flags: Dictionary) -> bool:
	var path: Dictionary = PATHS.get(path_id, {})
	return not path.is_empty() and flags.get(path.unlock_flag, false)


## Secret class ids the player has unlocked.
static func unlocked_classes(flags: Dictionary) -> Array:
	var out := []
	for id in PATHS:
		if is_unlocked(id, flags):
			out.append(PATHS[id].class_id)
	return out


## Called when a roaming boss is beaten. If it was the final step of a path the
## player is on, returns that path's id (and the caller sets the unlock flag).
static func path_completed_by(roamer_id: StringName, flags: Dictionary) -> StringName:
	for id in PATHS:
		if PATHS[id].final_roamer == roamer_id and is_on_path(id, flags) and not is_unlocked(id, flags):
			return id
	return &""
