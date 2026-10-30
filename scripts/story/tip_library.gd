class_name TipLibrary
extends RefCounted
## Tutorial tips (Hayden 2026-10-30): a system window the first time you meet
## each system, remembered for the whole save file (Tips autoload), and
## rereadable in Tab -> Guide. Text is short and placeholder-friendly.
##
## Each tip: topic, title, lines, and the "places" where it's checked
## (floor = walking a floor, menu = the Tab menu, battle = start of a battle;
## shop/board = when those open). A tip with no places is an EVENT: the code
## queues it with Tips.event(id) when the thing happens. Lines can use
## {key:<action>} for the current key and {token} for numbers (see tokens()).

const TOPICS := [&"basics", &"growth", &"world", &"late"]
const TOPIC_NAMES := { &"basics": "Basics", &"growth": "Growth", &"world": "The tower", &"late": "Gods and guilds" }
const PLACES := ["floor", "menu", "battle", "shop", "board"]

## In the order they're listed in the Guide.
const TIPS := {
	# --- Basics ---
	&"climbing": { "topic": &"basics", "title": "The Tower", "places": ["floor"], "lines": [
		"Move with {key:move_up}{key:move_left}{key:move_down}{key:move_right} or the arrow keys. Walk into people and things to use them.",
		"Touching an enemy starts a battle. Clear the way and take the stairs to climb.",
		"{key:party_menu} opens your party menu; {key:pause} pauses and saves." ] },
	&"battle": { "topic": &"basics", "title": "Battle", "places": ["battle"], "lines": [
		"Turns go by speed (the strip at the top). On your turn pick a command: Attack, Skills, Items, Defend, Row or Flee.",
		"Skills cost MP. Click a target to act; right-click or Esc to cancel.",
		"HP and MP carry over between battles. Heal with skills or potions." ] },
	&"rows": { "topic": &"basics", "title": "Rows", "places": ["battle"], "lines": [
		"Each side has 4 rows: Front, Middle, Rear and Back. Melee can only reach someone if nobody stands in a row in front of them.",
		"Melee attacks from further back hit softer (100% / 90% / 70% / 50%). Spells and bows don't care.",
		"Each class has a recommended row (a star in Manage party), but you can put anyone anywhere." ] },
	&"weakness": { "topic": &"basics", "title": "Weaknesses", "places": [], "lines": [
		"A hit on a weakness does 1.5x damage, and enough of them STAGGER an enemy: it loses its next turn.",
		"Enemies of one family share weaknesses, so what you learn early helps against the boss.",
		"The Bestiary ({key:party_menu}) remembers what you've found. A Scouting Lens reveals an enemy at once." ] },
	&"campfire": { "topic": &"basics", "title": "Rest Floors", "places": ["floor"], "lines": [
		"Every {rest_every} floors is a rest floor: no enemies, a merchant, a notice board and a campfire.",
		"The campfire restores everyone and revives the fallen. Rest floors are also your checkpoint." ] },
	&"defeat": { "topic": &"basics", "title": "Defeat", "places": [], "lines": [
		"When the whole party falls you wake up at your last checkpoint (the last rest floor you reached).",
		"Depending on the difficulty you may drop some gold. Your levels and gear are kept." ] },
	&"guardians": { "topic": &"basics", "title": "Guardians", "places": ["floor"], "lines": [
		"A miniboss guards every 5th floor from floor 4, and a boss every 10th. The stairs stay shut until it falls.",
		"While a guardian lives you can't swap, bench or dismiss party members, so plan your team first. Order and rows can still change.",
		"Its floors' enemies hint at its weaknesses." ] },

	# --- Growth ---
	&"stats": { "topic": &"growth", "title": "Stat Points", "places": ["floor", "menu"], "lines": [
		"Level-ups give stat points. Spend them in {key:party_menu} -> Stats.",
		"Your stats decide which classes you qualify for at level {class_level}, so build toward the class you want." ] },
	&"skills": { "topic": &"growth", "title": "Skills", "places": ["floor", "menu"], "lines": [
		"You get a skill pick every {pick_every} levels. Spend it in {key:party_menu} -> Skills: learn a new skill, or rank one up (I -> III).",
		"A class can only pick skills that fit it. Skill books can teach anyone anything." ] },
	&"gear": { "topic": &"growth", "title": "Gear", "places": ["floor", "menu"], "lines": [
		"Gear comes in Common, Uncommon, Rare, Epic, Legendary and Unique. Equip it in {key:party_menu} -> Gear.",
		"Unique weapons drop only from bosses and roaming bosses, each locked to one class. They are the only gear New Game+ keeps." ] },
	&"books": { "topic": &"growth", "title": "Skill Books", "places": ["floor", "menu"], "lines": [
		"A skill book teaches its skill to whoever reads it, whatever their class.",
		"Luck makes the rarer books more likely." ] },
	&"class": { "topic": &"growth", "title": "Choosing a Class", "places": ["floor", "menu"], "lines": [
		"You've reached level {class_level}: you can choose a class in {key:party_menu}.",
		"Which classes you can take depends on your stats. Hidden classes exist too, for those who find the clues." ] },
	&"class_change": { "topic": &"growth", "title": "One Free Change", "places": ["floor", "menu"], "lines": [
		"Past floor {class_gate}, each character may give up their first class once, with a free respec, and choose again.",
		"Look for the Change class button in {key:party_menu}." ] },
	&"advancement": { "topic": &"growth", "title": "Advancement", "places": ["floor", "menu"], "lines": [
		"Your class can advance. The Advance button in {key:party_menu} shows each path's requirements: stats, sometimes a route, and a trial quest.",
		"Advanced classes keep every skill they had and get stronger." ] },

	# --- The tower ---
	&"quests": { "topic": &"world", "title": "Quests", "places": ["floor", "menu"], "lines": [
		"Quests are in {key:party_menu} -> Quests. Pin one to keep track of it on screen.",
		"Some quests expire after a few floors, and some choices close others off." ] },
	&"board": { "topic": &"world", "title": "Notice Board", "places": ["board"], "lines": [
		"Bounties fitting the floors ahead, and jobs from the guilds. New ones appear on each rest floor." ] },
	&"shop": { "topic": &"world", "title": "Merchants", "places": ["shop"], "lines": [
		"Prices change with the guild that runs these floors, your standing, and supply and demand: selling lots of one thing lowers its price.",
		"Goddess Tears revive the fallen in battle. They're expensive here; bosses drop them." ] },
	&"recruits": { "topic": &"world", "title": "Recruits", "places": ["floor"], "lines": [
		"Some people in the tower will fight for you: met at a campfire, hired, won by a favor or rescued.",
		"Each has values of their own. Act against them for too long and they'll warn you, then leave." ] },
	&"wages": { "topic": &"world", "title": "Wages", "places": ["floor", "menu"], "lines": [
		"Someone hired by the floor is paid at every new floor. Miss a wage and they warn you; miss two in a row and they walk off.",
		"They wait by a campfire and won't come back until you pay what you owe." ] },
	&"party_growth": { "topic": &"world", "title": "A Bigger Party", "places": ["floor", "menu"], "lines": [
		"One more fighter can join you every {growth_floors} floors (up to {max_party}).",
		"Enemies get tougher to match, so fill the new place." ] },
	&"reserve": { "topic": &"world", "title": "Reserve", "places": ["floor", "menu"], "lines": [
		"Companions who aren't fighting sit in the reserve (up to {reserve_cap}) and get half the XP.",
		"Swap them in and out in Manage party. Dismissed companions wait by the campfires on rest floors." ] },
	&"paths": { "topic": &"world", "title": "Your Path", "places": ["floor", "menu"], "lines": [
		"Your choices shape what people think of you. The line by your name in {key:party_menu} is how they see you.",
		"It changes who will join you, what shops will sell, the classes open to you, and how your climb ends." ] },

	# --- Gods and guilds ---
	&"blessings": { "topic": &"late", "title": "Blessings", "places": ["floor", "menu"], "lines": [
		"Gods, demons and devils are watching. One that likes how you act may offer a blessing: a power, a matching curse, and a blessed skill.",
		"Keep serving their values and both grow. Turn against them and they'll warn you, then punish you." ] },
	&"curses": { "topic": &"late", "title": "Curses", "places": ["floor", "menu"], "lines": [
		"You've been cursed. It weakens you until it wears off; check {key:party_menu} to see how long that is." ] },
	&"guilds": { "topic": &"late", "title": "Guilds", "places": ["floor"], "lines": [
		"Guilds rule the tower's floors three at a time. The ruling guild sets prices and taxes there, and they trade, steal and go to war as you climb.",
		"Join one through its agent and rise in its ranks. {key:party_menu} -> Guilds shows who rules where." ] },
	&"wars": { "topic": &"late", "title": "Guild Wars", "places": ["floor", "menu"], "lines": [
		"Guilds are at war. Fights on their floors can swing it, as a member or as a mercenary.",
		"Tower News and merchants' rumours say what's happening." ] },
	&"own_guild": { "topic": &"late", "title": "Your Own Guild", "places": ["floor", "menu"], "lines": [
		"Past floor {charter_floor} you can found your own guild ({charter_cost} gold) in {key:party_menu} -> Guilds.",
		"Claim floors by beating their champions. Benched companions can captain your territories." ] },
	&"demigods": { "topic": &"late", "title": "Demigods", "places": ["floor"], "lines": [
		"A legend climbs this tower. Demigods come when a patron from their pantheon watches you, and they have classes nobody else can take.",
		"Once one joins you, they wait on floor {demigod_floor} in every later run." ] },
	&"new_game_plus": { "topic": &"late", "title": "New Game+", "places": ["floor"], "lines": [
		"The tower is stronger this time. You keep your level, class and Unique weapons.",
		"A tier-3 class at a high enough level can Ascend ({key:party_menu}), beyond any normal class." ] },
	&"divinity": { "topic": &"late", "title": "Divinity", "places": ["floor", "menu"], "lines": [
		"You are a god now. Sponsor guilds in {key:party_menu} -> Divinity: they pay tithes and follow your values.",
		"Faith fuels your miracles in battle. Guilds that act against your values can be smitten, or cut loose." ] },
}


## Numbers used in the text, so the tips follow the tunables.
static func tokens() -> Dictionary:
	return {
		"rest_every": GameState.REST_FLOOR_INTERVAL,
		"class_level": CharacterData.CLASS_UNLOCK_LEVEL,
		"pick_every": CharacterData.SKILL_PICK_EVERY,
		"class_gate": ClassRegistry.ADVANCEMENT_GATES.get(2, {}).get("floor", 20),
		"growth_floors": GameState.PARTY_GROWTH_FLOORS,
		"max_party": GameState.MAX_PARTY_SIZE,
		"reserve_cap": GameState.RESERVE_CAP,
		"charter_floor": GuildState.CHARTER_FLOOR,
		"charter_cost": GuildState.CHARTER_COST,
		"demigod_floor": GameState.UNLOCKED_DEMIGOD_FLOOR,
	}


## A tip's lines with keys and numbers filled in.
static func text(id: StringName) -> String:
	var out: Array = []
	var toks := tokens()
	for line in TIPS.get(id, {}).get("lines", []):
		var s: String = line
		for k in toks:
			s = s.replace("{%s}" % k, str(toks[k]))
		var i := s.find("{key:")
		while i >= 0:
			var j := s.find("}", i)
			if j < 0:
				break
			s = s.substr(0, i) + key_name(s.substr(i + 5, j - i - 5)) + s.substr(j + 1)
			i = s.find("{key:")
		out.append(s)
	return "\n".join(out)


## The first key bound to an action ("Tab"), so the text follows rebinding.
static func key_name(action: String) -> String:
	if InputMap.has_action(action):
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey:
				var code: int = ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
				return OS.get_keycode_string(code)
	return action


static func ids_for(place: String) -> Array:
	return TIPS.keys().filter(func(id): return TIPS[id].places.has(place))


## Is this tip's moment here? (Seen-ness is the Tips autoload's job.)
## `layout` = the floor you're on (floor tips only).
static func due(id: StringName, place: String, layout: FloorLayout = null) -> bool:
	var gs := GameState
	var p: CharacterData = gs.player
	if p == null:
		return false
	var members := gs.battle_party() + gs.reserve
	match id:
		&"climbing", &"battle":
			return true
		&"rows":
			return gs.highest_floor >= 2
		&"campfire":
			return layout != null and layout.is_rest
		&"guardians":
			return StageLibrary.is_boss_floor(gs.floor_number) or StageLibrary.is_miniboss_floor(gs.floor_number)
		&"stats":
			return p.unspent_points > 0 and p.level >= 2
		&"skills":
			return p.skill_picks > 0 and gs.highest_floor >= 2
		&"gear":
			return not gs.inventory.gear.is_empty()
		&"books":
			return gs.inventory.owned().any(func(it): return it.is_skill_book())
		&"class":
			return p.can_choose_class()
		&"class_change":
			return p.class_change_open()
		&"advancement":
			return members.any(func(c): return c.advancement_open())
		&"quests":
			return not gs.quests.active.is_empty()
		&"board", &"shop":
			return true
		&"recruits":
			return layout != null and layout.npcs.values().any(
				func(n): return not NpcLibrary.recruit_info(n).is_empty())
		&"wages":
			return members.any(func(c): return c.wage > 0) or gs.waiting.any(func(c): return c.wage_owed > 0)
		&"party_growth":
			return gs.party_size() > GameState.PARTY_START_SIZE
		&"reserve":
			return not gs.reserve.is_empty() or not gs.waiting.is_empty()
		&"paths":
			return gs.route.points.values().any(func(v): return v != 0)
		&"blessings":
			return p.is_blessed() or not gs.blessings.offering_beings().is_empty()
		&"curses":
			return p.curse_id != &""
		&"guilds":
			return gs.highest_floor > GameState.REST_FLOOR_INTERVAL
		&"wars":
			return not gs.guilds.wars.is_empty()
		&"own_guild":
			return gs.highest_floor > GuildState.CHARTER_FLOOR and not gs.guilds.has_own_guild()
		&"demigods":
			return layout != null and layout.npcs.values().any(
				func(n): return NpcLibrary.recruit_info(n).get("demigod", false))
		&"new_game_plus":
			return gs.ng_plus_cycle > 0
		&"divinity":
			return gs.divinity.active
	return false


## Problems with the data ([] = fine). Run by the tests.
static func validate() -> Array:
	var errors := []
	for id in TIPS:
		var t: Dictionary = TIPS[id]
		if not TOPICS.has(t.get("topic")):
			errors.append("%s: unknown topic" % id)
		if String(t.get("title", "")) == "" or t.get("lines", []).is_empty():
			errors.append("%s: needs a title and lines" % id)
		for pl in t.get("places", []):
			if not PLACES.has(pl):
				errors.append("%s: unknown place %s" % [id, pl])
		var body := text(id)
		if body.contains("{"):
			errors.append("%s: unfilled token in %s" % [id, body])
	return errors
