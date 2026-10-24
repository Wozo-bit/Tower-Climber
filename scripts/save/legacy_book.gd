class_name LegacyBook
extends Resource
## The Hall of Climbers: every character who has conquered the tower.
## Lives in its own file, separate from the save slot, so it survives new games.

@export var records: Array[LegacyRecord] = []


func find(legacy_id: String) -> LegacyRecord:
	for r in records:
		if r.legacy_id == legacy_id:
			return r
	return null
