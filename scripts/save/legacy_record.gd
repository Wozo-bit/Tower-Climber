class_name LegacyRecord
extends Resource
## One character in the Hall of Climbers: someone who conquered the tower.
## The full character is kept so New Game+ can continue with them.

@export var legacy_id: String = ""
@export var character: CharacterData
@export var times_cleared: int = 0
## Highest New Game+ cycle this character has beaten (0 = the normal game).
@export var highest_cycle_cleared: int = 0
@export var first_cleared_at: String = ""
@export var last_cleared_at: String = ""
@export var best_play_time_sec: float = 0.0
## Unequipped gear that carries into New Game+ (Uniques from the bag and from
## companions). The character's own equipped Uniques stay on them.
@export var vault: Array[GearItem] = []
## The childhood friend's name in that run, so they keep it in New Game+.
@export var friend_name: String = ""
## The save slot this character conquered the tower in. New Game+ reuses it.
@export var slot: int = 1


func display_name() -> String:
	return character.character_name if character else "?"


func class_display() -> String:
	var def := character.get_class_def() if character else null
	return def.display_name if def else "No class"


## One-line summary for lists: "Ophelius — Lv 24 Ashbound Knight — cleared 2x (NG+1)"
func summary() -> String:
	var s := "%s — Lv %d %s — cleared %dx" % [display_name(), character.level, class_display(), times_cleared]
	if highest_cycle_cleared > 0:
		s += " (up to NG+%d)" % highest_cycle_cleared
	return s


static func format_time(sec: float) -> String:
	var total := int(sec)
	return "%dh %02dm" % [total / 3600, (total % 3600) / 60]
