extends RefCounted
## Example DLC used by the tests: adds a more specific ending on top of the
## base Hero ending. Real DLC lives in res://dlc/<name>/content.gd.


func register() -> void:
	RouteLibrary.register_ending({
		"id": &"example_lone_hero", "title": "The Lonely Hero", "priority": 20,
		"if": { "route": &"hero", "flag": &"example_friend_left" },
		"text": "(Test DLC) You saved everyone, but climbed the last floors alone.",
	})
