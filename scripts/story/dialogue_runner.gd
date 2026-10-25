class_name DialogueRunner
extends RefCounted
## Plays one conversation from DialogueLibrary. Pure logic, no UI: the
## DialogueBox shows `speaker()`, `text()` and `choices()`, then calls
## `advance()` or `choose(i)`. Tests drive it the same way.
##
## Effects change GameState directly (flags, items, gold, recruits). Things
## the screen has to do afterwards (open the shop, show a toast) are collected
## in `requests` and `messages`.

var dialogue_id: StringName
var node_id := ""
var finished := true
## UI follow-ups, e.g. "shop". Read them when the conversation ends.
var requests: Array[String] = []
## Toasts for the floor HUD ("Brakka joined the party!").
var messages: Array[String] = []
## Who you're talking to, when it's one of your own companions (a dismissed
## companion waiting by the campfire). Used by {npc} and the "rejoin" effect.
var companion: CharacterData
## The god / demon / devil this conversation is with (blessing offers,
## warnings, punishment). Static so conditions and {being} text can see it;
## only one conversation runs at a time.
static var context_being: StringName = &""
## The guild this conversation is with (a guild agent), for {guild...} text,
## guild conditions and effects.
static var context_guild: StringName = &""

var _nodes: Dictionary = {}


## Starts a conversation. Returns false if the id doesn't exist.
func start(id: StringName, with: CharacterData = null, being: StringName = &"", guild: StringName = &"") -> bool:
	context_being = being
	context_guild = guild
	var d := DialogueLibrary.get_dialogue(id)
	companion = with
	requests.clear()
	messages.clear()
	if d.is_empty():
		finished = true
		return false
	dialogue_id = id
	_nodes = d.nodes
	finished = false
	_enter(start_node(d))
	return true


## Which node a dialogue opens on right now (its "start" list is checked in order).
static func start_node(d: Dictionary) -> String:
	var start = d.get("start", "")
	if start is String:
		return start
	for entry in start:
		if check(entry.get("if", {})):
			return entry.node
	return ""


func speaker() -> String:
	return fill(_node().get("speaker", ""), _npc_name())


## The speaker as written in the data ("{friend}", "Merchant"), for portraits.
func raw_speaker() -> String:
	return _node().get("speaker", "")


## The node's explicit "portrait" art id ("" = work it out from the speaker).
func portrait_id() -> String:
	return str(_node().get("portrait", ""))


func text() -> String:
	return fill(_node().get("text", ""), _npc_name())


## Visible choices as [{ "index", "text" }]. Empty = show a "Next" button.
## `index` is what to pass to choose().
func choices() -> Array:
	var out := []
	var all: Array = _node().get("choices", [])
	for i in all.size():
		if check(all[i].get("if", {})):
			out.append({ "index": i, "text": fill(all[i].text, _npc_name()) })
	return out


func has_choices() -> bool:
	return _node().has("choices")


## "Next" on a line without choices.
func advance() -> void:
	if finished or has_choices():
		return
	_enter(_node().get("next", ""))


## Picks choice `index` (the "index" from choices()). Returns false if it's
## hidden or doesn't exist.
func choose(index: int) -> bool:
	if finished:
		return false
	var all: Array = _node().get("choices", [])
	if index < 0 or index >= all.size() or not check(all[index].get("if", {})):
		return false
	var c: Dictionary = all[index]
	_apply_effects(c.get("effects", []))
	if requests.any(func(r): return r.begins_with("shop")):
		_enter("")
	else:
		_enter(c.get("next", ""))
	return true


func _node() -> Dictionary:
	return _nodes.get(node_id, {})


func _enter(id: String) -> void:
	node_id = id
	if id == "" or not _nodes.has(id):
		node_id = ""
		finished = true
		return
	_apply_effects(_nodes[id].get("effects", []))


# =========================================================
# Conditions & effects
# =========================================================

## True if every key in `cond` passes. See DialogueLibrary for the keys.
static func check(cond: Dictionary) -> bool:
	var gs := GameState
	for k in cond:
		var v = cond[k]
		var ok := true
		match k:
			"flag": ok = gs.has_flag(v)
			"not_flag": ok = not gs.has_flag(v)
			"min_floor": ok = gs.floor_number >= v
			"max_floor": ok = gs.floor_number <= v
			"min_level": ok = gs.player.level >= v
			"gold": ok = gs.player.gold >= v
			"item": ok = gs.inventory.count(v) > 0
			"ng_plus": ok = (gs.ng_plus_cycle > 0) == v
			"on_secret_path": ok = SecretPaths.is_on_path(v, gs.story_flags)
			"recruited": ok = gs.has_recruited(v)
			"quest_new": ok = gs.quests.is_new(v)
			"quest_active": ok = gs.quests.is_active(v)
			"quest_done": ok = gs.quests.is_done(v)
			"quest_failed": ok = gs.quests.is_failed(v)
			"quest_on_step": ok = gs.quests.step_index(v[0]) == v[1]
			"route": ok = gs.route.current() == v
			"not_route": ok = gs.route.current() != v
			"route_locked": ok = ((gs.route.locked != &"") == v) if v is bool else gs.route.locked == v
			"no_route": ok = (gs.route.current() == &"") == v
			# Blessing offers (about the being this conversation is with).
			"has_bargain": ok = (not BeingLibrary.get_being(context_being).get("bargain", {}).is_empty()) == v
			"can_pay_bargain": ok = gs.blessings.can_pay(context_being) == v
			"blessed": ok = gs.player.is_blessed() == v
			# Guild agents (about the guild this conversation is with).
			"guild_member": ok = (gs.guilds.member == context_guild and context_guild != &"") == v
			"in_guild": ok = (gs.guilds.member != &"") == v
			"can_join_guild": ok = gs.guilds.can_join(context_guild) == v
			"guild_pay_due": ok = (gs.guilds.member == context_guild and gs.guilds.pay_due()) == v
			"can_hire_on": ok = gs.guilds.can_hire_on(context_guild) == v
			"can_take_heist": ok = gs.guilds.can_take_heist(context_guild) == v
			"heist_here": ok = (not gs.guilds.heist.is_empty() and gs.guilds.heist.target == context_guild) == v
			"holds_captive": ok = gs.guilds.holds_captive(context_guild) == v
			"can_pay_ransom": ok = gs.guilds.can_pay_ransom(context_guild) == v
			_:
				push_warning("Dialogue: unknown condition '%s'" % k)
				ok = false
		if not ok:
			return false
	return true


func _apply_effects(effects: Array) -> void:
	var gs := GameState
	for e: Dictionary in effects:
		if e.has("set_flag"):
			gs.set_flag(e.set_flag)
		if e.has("clear_flag"):
			gs.set_flag(e.clear_flag, false)
		if e.has("give_item"):
			var n: int = e.get("count", 1)
			gs.inventory.add(e.give_item, n)
			messages.append("Got %s%s." % [ItemLibrary.get_item(e.give_item).display_name,
				" x%d" % n if n > 1 else ""])
		if e.has("give_gold"):
			gs.player.gold += e.give_gold
			messages.append("Got %d gold." % e.give_gold)
		if e.has("take_gold"):
			gs.player.gold = maxi(0, gs.player.gold - e.take_gold)
		if e.has("recruit"):
			if gs.npc_refuses(e.recruit):
				messages.append("%s won't travel with someone like you." % NpcLibrary.get_npc(e.recruit).name)
			var c := gs.recruit(e.recruit)
			if c:
				messages.append("%s joined the party!" % c.character_name if gs.companions.has(c)
					else "%s joined (on reserve: the party is full)." % c.character_name)
		if e.has("heal_party"):
			gs.full_restore_party()
			messages.append("Everyone feels rested.")
		if e.has("open_shop"):
			# true = the merchant; a shop id string = that trader's stock.
			requests.append("shop" if e.open_shop is bool else "shop:%s" % e.open_shop)
		if e.has("rejoin") and companion:
			if gs.refuses_to_rejoin(companion):
				messages.append("%s won't come back while you walk this path." % companion.character_name)
			elif gs.rejoin(companion):
				messages.append("%s is back%s!" % [companion.character_name,
					"" if gs.companions.has(companion) else " (on the reserve)"])
			else:
				messages.append("No room: the party and reserve are full.")
		if e.has("route_points"):
			for r in e.route_points:
				gs.add_route_points(r, e.route_points[r])
		if e.has("accept_blessing") and context_being != &"":
			if not gs.blessings.accept(context_being):
				messages.append("You can't pay what %s asks." % BeingLibrary.get_being(context_being).name)
		if e.has("refuse_blessing") and context_being != &"":
			gs.blessings.refuse(context_being)
		if e.has("join_guild") and context_guild != &"":
			gs.guilds.join(context_guild)
		if e.has("leave_guild"):
			gs.guilds.leave()
		if e.has("collect_pay"):
			gs.guilds.collect_pay()
		if e.has("hire_on") and context_guild != &"":
			gs.guilds.hire_on(context_guild)
		if e.has("take_heist") and context_guild != &"":
			gs.guilds.take_heist(context_guild)
		if e.has("attempt_heist") and context_guild != &"":
			var heist_rng := RandomNumberGenerator.new()
			heist_rng.randomize()
			gs.guilds.attempt_heist(context_guild, heist_rng)
		if e.has("pay_ransom") and context_guild != &"":
			gs.guilds.pay_ransom(context_guild)
		if e.has("guild_rep"):
			for g in e.guild_rep:
				gs.guilds.add_rep(g, e.guild_rep[g])
		if e.has("interest"):
			for b in e.interest:
				gs.blessings.add_interest(b, e.interest[b])
		if e.has("lock_route"):
			gs.lock_route(e.lock_route)
		if e.has("take_item"):
			gs.inventory.remove(e.take_item, e.get("count", 1))
		if e.has("start_quest"):
			gs.quests.start(e.start_quest)   # its "New quest" toast comes from the quest log
		if e.has("fail_quest"):
			gs.quests.fail(e.fail_quest)
		if e.has("toast"):
			messages.append(fill(e.toast, _npc_name()))


func _npc_name() -> String:
	return companion.character_name if companion else ""


## Swaps {player}, {friend} and {npc} for the current names, {stage_hint} for
## a hint about the stage ahead (StageLibrary theme "hint"), and the {being...}
## tokens for the god/demon/devil this conversation is with.
static func fill(s: String, npc_name: String = "") -> String:
	var friend := GameState.childhood_friend()
	var out := s.replace("{player}", GameState.player.character_name) \
		.replace("{friend}", friend.character_name if friend else GameState.CHILDHOOD_FRIEND_NAME) \
		.replace("{npc}", npc_name) \
		.replace("{stage_hint}", StageLibrary.stage_for_floor(GameState.floor_number + 1).get("hint", ""))
	if out.contains("{tower_news}"):
		var headlines := GameState.guilds.latest_news(3)
		out = out.replace("{tower_news}", headlines if headlines != "" else "(Placeholder) Quiet lately. Too quiet.")
	if context_guild != &"" and out.contains("{guild"):
		var g := GuildLibrary.get_guild(context_guild)
		var floors := GameState.guilds.territories_of(context_guild).map(func(t): return GuildLibrary.territory_floors(t))
		out = out.replace("{guild}", g.get("name", "?")).replace("{guild_motto}", g.get("motto", "")) \
			.replace("{guild_patron}", BeingLibrary.full_name(g.get("patron", &""))) \
			.replace("{guild_floors}", ", ".join(floors) if not floors.is_empty() else "no floors right now") \
			.replace("{guild_tax}", "%d%%" % roundi(g.get("tax", 0.0) * 100)) \
			.replace("{guild_rank}", GuildLibrary.rank_name(GameState.guilds.rank)) \
			.replace("{guild_standing}", GuildState.standing_name(GameState.guilds.rep_of(context_guild))) \
			.replace("{guild_refusal}", GameState.guilds.join_refusal(context_guild)) \
			.replace("{guild_war}", _war_text(context_guild)) \
			.replace("{guild_ransom}", str(GameState.guilds.ransom_cost(context_guild)))
	if context_being != &"" and out.contains("{being"):
		var b := BeingLibrary.get_being(context_being)
		out = out.replace("{being}", BeingLibrary.full_name(context_being)) \
			.replace("{being_offer}", b.get("offer", "")).replace("{being_warn}", b.get("warn", "")) \
			.replace("{being_punish}", b.get("punish", "")) \
			.replace("{being_bargain}", BlessingState.bargain_text(context_being)) \
			.replace("{being_gifts}", blessing_summary(context_being, 1))
	return out


## "+5% HEA, +5% STA, +20% Holy damage / Weak to Dark" for a being's level.
## "We're at war with The Serpent Coil over Floors 13-15" (or peace).
static func _war_text(g: StringName) -> String:
	var w := GameState.guilds.war_of(g)
	if w.is_empty():
		return "We're at peace"
	var enemy: StringName = w.defender if w.attacker == g else w.attacker
	return "We're at war with %s over %s" % [GuildLibrary.guild_name(enemy), GuildLibrary.territory_floors(w.territory)]


static func blessing_summary(id: StringName, level: int) -> String:
	var lv := BeingLibrary.level_effects(id, level)
	return "%s  /  Price: %s" % [effects_text(lv.get("buff", {})), effects_text(lv.get("curse", {}))]


static func effects_text(e: Dictionary) -> String:
	var parts: PackedStringArray = []
	for st in e.get("stats", {}):
		parts.append("%+d%% %s" % [roundi(e.stats[st] * 100), Stats.short_name_of(st)])
	for el in e.get("element_power", {}):
		parts.append("%+d%% %s damage" % [roundi(e.element_power[el] * 100), Element.name_of(el)])
	for el in e.get("affinities", {}):
		parts.append("%s %s" % [Element.affinity_name(e.affinities[el]).replace("Weak", "Weak to"), Element.name_of(el)])
	for k in [["gold_mult", "gold"], ["xp_mult", "XP"], ["price_mult", "shop prices"]]:
		if e.has(k[0]):
			parts.append("%+d%% %s" % [roundi(e[k[0]] * 100), k[1]])
	if e.has("regen_pct"):
		parts.append("heal %d%% HP after each win" % roundi(e.regen_pct * 100))
	return ", ".join(parts)
