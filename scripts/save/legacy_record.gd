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
## Ending ids this character has reached (RouteLibrary), across all their runs.
@export var endings_seen: Array[StringName] = []
## Hardest difficulty (Difficulty.Level) they've cleared on (-1 = none yet),
## and whether they've cleared with Ironman on.
@export var best_difficulty: int = -1
@export var ironman_cleared: bool = false
## Died in an Ironman run: remembered, but no New Game+ from them.
@export var fallen: bool = false
@export var fallen_floor: int = 0
@export var fallen_difficulty: int = 1
## Apotheosis (Hayden 2026-10-25): conquering the tower made them a god.
## &"" = not (yet). The domain (DomainLibrary) and the title they chose.
@export var god_domain: StringName = &""
@export var god_title: String = ""


func is_god() -> bool:
	return god_domain != &"" and not DomainLibrary.get_domain(god_domain).is_empty()


## "Ophelius, God of Valor"
func god_name() -> String:
	return "%s, %s" % [display_name(), god_title] if is_god() else display_name()


func can_continue() -> bool:
	return not fallen and times_cleared > 0


func display_name() -> String:
	return character.character_name if character else "?"


func class_display() -> String:
	var def := character.get_class_def() if character else null
	return def.display_name if def else "No class"


## One-line summary for lists: "Ophelius — Lv 24 Ashbound Knight — cleared 2x (NG+1)"
func summary() -> String:
	var s := "%s — Lv %d %s" % [display_name(), character.level, class_display()]
	if times_cleared > 0:
		s += " — cleared %dx" % times_cleared
		if highest_cycle_cleared > 0:
			s += " (up to NG+%d)" % highest_cycle_cleared
		if best_difficulty >= 0:
			s += " on %s" % Difficulty.label(best_difficulty, ironman_cleared)
	if fallen:
		s += " — FALLEN on floor %d (%s + Ironman)" % [fallen_floor, Difficulty.name_of(fallen_difficulty)]
	return s


static func format_time(sec: float) -> String:
	var total := int(sec)
	return "%dh %02dm" % [total / 3600, (total % 3600) / 60]
