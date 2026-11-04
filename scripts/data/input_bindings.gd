class_name InputBindings
extends RefCounted
## Rebindable keys (Hayden 2026-11-01): moving, the party menu, pause, and
## confirm/cancel in menus. Two keys per action, kept in Settings.keys
## (action -> [key, key], 0 = empty) and applied to the InputMap. Only key
## events are replaced; mouse and gamepad events of built-in actions stay.

const ACTIONS := ["move_up", "move_down", "move_left", "move_right", "party_menu", "pause", "ui_accept", "ui_cancel"]
const NAMES := {
	"move_up": "Move up", "move_down": "Move down", "move_left": "Move left", "move_right": "Move right",
	"party_menu": "Party menu", "pause": "Pause", "ui_accept": "Confirm", "ui_cancel": "Cancel / back",
}
const SLOTS := 2
const DEFAULTS := {
	"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
	"party_menu": [KEY_TAB, KEY_I], "pause": [KEY_ESCAPE, KEY_P],
	"ui_accept": [KEY_ENTER, KEY_SPACE], "ui_cancel": [KEY_ESCAPE, 0],
}
## Keys only clash inside a group: Esc can pause on a floor AND go back in a menu.
const GROUPS := [["move_up", "move_down", "move_left", "move_right", "party_menu", "pause"], ["ui_accept", "ui_cancel"]]


static func defaults() -> Dictionary:
	var out := {}
	for a in ACTIONS:
		out[a] = DEFAULTS[a].duplicate()
	return out


static func _group_of(action: String) -> Array:
	for g in GROUPS:
		if g.has(action):
			return g
	return [action]


static func valid_key(key) -> bool:
	return (key is int or key is float) and int(key) > 0 and int(key) < (1 << 23) \
		and OS.get_keycode_string(int(key)) != ""


## Bindings read from the settings file: anything odd falls back to the
## defaults, clashes inside a group are dropped, every action keeps a key.
static func clean(raw) -> Dictionary:
	var out := defaults()
	if not raw is Dictionary:
		return out
	var used := {}   # group index -> keys taken
	for a in ACTIONS:
		var keys = raw.get(a)
		if not keys is Array:
			continue
		var gi := GROUPS.find(_group_of(a))
		var taken: Array = used.get(gi, [])
		var picked := []
		for k in keys.slice(0, SLOTS):
			var free: bool = valid_key(k) and not taken.has(int(k)) and not picked.has(int(k))
			picked.append(int(k) if free and not _typing_clash(a, int(k)) else 0)
		while picked.size() < SLOTS:
			picked.append(0)
		if picked.any(func(k): return k != 0):
			out[a] = picked
			taken.append_array(picked.filter(func(k): return k != 0))
			used[gi] = taken
	return out


## Text boxes stop editing on Cancel, so Backspace can never be a Cancel key
## (it was a default until 2026-11-04: Hayden couldn't delete typed text).
static func _typing_clash(action: String, key: int) -> bool:
	return action == "ui_cancel" and key == KEY_BACKSPACE


## Puts the bindings into the InputMap.
static func apply(bindings: Dictionary) -> void:
	for a in ACTIONS:
		if not InputMap.has_action(a):
			InputMap.add_action(a)
		for ev in InputMap.action_get_events(a):
			if ev is InputEventKey:
				InputMap.action_erase_event(a, ev)
		for k in bindings.get(a, DEFAULTS[a]):
			if k != 0:
				var ev := InputEventKey.new()
				ev.physical_keycode = k
				InputMap.action_add_event(a, ev)


## Binds `key` to slot `slot` of `action`. A key already used in the same
## group moves here. Returns "" when done, or why it couldn't.
static func bind(bindings: Dictionary, action: String, slot: int, key: int) -> String:
	if not ACTIONS.has(action) or slot < 0 or slot >= SLOTS or not valid_key(key):
		return "That key can't be used."
	if _typing_clash(action, key):
		return "%s has to keep working in text boxes." % OS.get_keycode_string(key)
	for other in _group_of(action):
		if other == action:
			continue
		var keys: Array = bindings[other]
		if keys.has(key):
			if keys.count(0) == SLOTS - 1:
				return "%s is the only key for %s." % [OS.get_keycode_string(key), NAMES[other]]
			keys[keys.find(key)] = 0
	var mine: Array = bindings[action]
	if mine.has(key) and mine.find(key) != slot:
		mine[mine.find(key)] = 0   # same key in the other slot: just move it
	mine[slot] = key
	return ""


## Empties a slot (never the last key of an action).
static func clear(bindings: Dictionary, action: String, slot: int) -> bool:
	var keys: Array = bindings.get(action, [])
	if slot < 0 or slot >= keys.size() or keys[slot] == 0 or keys.count(0) == SLOTS - 1:
		return false
	keys[slot] = 0
	return true


## "W" (the first key bound to an action), so on-screen text follows rebinding.
static func key_name(action: String) -> String:
	if InputMap.has_action(action):
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey:
				var code: int = ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
				return OS.get_keycode_string(code)
	return NAMES.get(action, action)


## "W / Up" for the Controls screen and hints.
static func keys_text(bindings: Dictionary, action: String) -> String:
	var parts := []
	for k in bindings.get(action, []):
		if k != 0:
			parts.append(OS.get_keycode_string(k))
	return " / ".join(parts)
