extends Node
## Balance simulator (dev tool, not part of the game). A bot climbs the tower
## the way a decent player would and reports how it went, so the numbers can
## be tuned against targets instead of guesses.
##
## Run (from the project folder):
##   godot --headless --path . res://tools/balance_sim.tscn -- runs=6 difficulty=1
##   godot --headless --path . res://tools/balance_sim.tscn -- guilds runs=40
##
## Options: runs=N, difficulty=0..3 (Relaxed..Hell) or difficulty=all,
## floors=N (default: the final floor), guilds (guild-world mode only).
##
## The bot: fights everything on every floor, picks a class build, chooses a
## class at level 10 and advances when it can, recruits companions, equips
## better gear, uses known weaknesses and focus-fires, drinks potions when
## hurt (in and out of battle), rests at campfires and restocks at merchants.
## It never grinds: floors are cleared once.

const MAX_ACTIONS := 800
const MAX_WIPES_PER_FLOOR := 6
const MAX_RUN_MSEC := 240000
## Roaming bosses are optional: the bot avoids them until its average level
## is this many times the floor.
const ROAMER_LEVEL_RATIO := 2.5
const BUILDS := [&"tank", &"mage", &"archer", &"rogue", &"support", &"warrior", &"monk", &"spellblade", &"magic_swordsman", &"summoner"]
const POTION_STOCK := { &"potion": 10, &"advanced_potion": 5, &"ether": 4 }

var _args := {}
## The last few fights (printed when a run gives up).
var _recent: Array[String] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := String(a).split("=")
		_args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	GameState.save_dir = "user://sim_saves"
	Settings.cutins = false
	if _args.has("guilds"):
		_guild_world(int(_args.get("runs", "40")))
	else:
		var levels: Array = Difficulty.all() if _args.get("difficulty", "1") == "all" else [int(_args.get("difficulty", "1"))]
		for d in levels:
			_climb_report(d, int(_args.get("runs", "6")), int(_args.get("floors", str(GameState.FINAL_FLOOR))))
	GameState.delete_slot(1)
	get_tree().quit()


# =========================================================
# Full runs
# =========================================================

func _climb_report(diff: int, runs: int, floors: int) -> void:
	var all := []
	for i in runs:
		_rng.seed = 1000 + i * 7919 + diff
		seed(_rng.seed)
		var t0 := Time.get_ticks_msec()
		var res := _run(diff, floors, BUILDS[i % BUILDS.size()], BUILDS[(i + 2) % BUILDS.size()])
		all.append(res)
		print("   run %d (%s + %s): reached floor %d, wipes %s, %s, %.0fs" % [i + 1, BUILDS[i % BUILDS.size()],
			BUILDS[(i + 2) % BUILDS.size()], GameState.floor_number, res.wipes_by_stage,
			"CLEARED" if res.cleared else ("stuck on floor %d" % res.stuck_floor if res.stuck else "unfinished"),
			(Time.get_ticks_msec() - t0) / 1000.0])
	print("\n===== %s: %d runs, floors 1-%d =====" % [Difficulty.name_of(diff), runs, floors])
	var stages := ceili(floors / 10.0)
	for st in stages:
		var w := _avg(all, func(r): return r.wipes_by_stage[st])
		var wb := _avg(all, func(r): return r.boss_wipes[st])
		var wm := _avg(all, func(r): return r.mini_wipes[st])
		var lv := _avg(all, func(r): return r.level_at_boss[st])
		var hp := _avg(all, func(r): return r.hp_lost_normal[st])
		var turns := _avg(all, func(r): return r.rounds_normal[st])
		var gold := _avg(all, func(r): return r.gold_at_stage_end[st])
		var earned := _avg(all, func(r): return r.gold_earned[st])
		var pots := _avg(all, func(r): return r.potions_used[st])
		print("Stage %d: wipes %.1f (boss %.1f, minibosses %.1f) | level at boss %.1f | normal fight: %.0f%% party HP lost, %.1f rounds | potions used %.1f | gold earned %.0f, held %.0f" % [
			st + 1, w, wb, wm, lv, hp * 100, turns, pots, earned, gold])
	var lv_line := "Party level on first reaching floor:"
	for f in [10, 20, 30, 40, 50, 60]:
		var reached := all.filter(func(r): return r.first_level.has(f))
		if not reached.is_empty():
			lv_line += "  %d: %.1f (%d runs)" % [f, _avg(reached, func(r): return r.first_level[f]), reached.size()]
	print(lv_line)
	print("Cleared: %d/%d   stuck (gave up): %d   party size at end %.1f   gold when the charter opens (floor 16): %.0f" % [
		all.filter(func(r): return r.cleared).size(), runs, all.filter(func(r): return r.stuck).size(),
		_avg(all, func(r): return r.party_size), _avg(all, func(r): return r.gold_at_16)])


func _avg(rows: Array, f: Callable) -> float:
	if rows.is_empty():
		return 0.0
	var t := 0.0
	for r in rows:
		t += float(f.call(r))
	return t / rows.size()


func _run(diff: int, floors: int, build: StringName, friend_build: StringName) -> Dictionary:
	GameState.start_new_game("Bot", "Rowan", 1, diff, false)
	GameState.player.set_meta("build", build)
	GameState.childhood_friend().set_meta("build", friend_build)
	var stages := ceili(floors / 10.0)
	var r := { "wipes_by_stage": _zeros(stages), "boss_wipes": _zeros(stages), "mini_wipes": _zeros(stages),
		"level_at_boss": _zeros(stages), "hp_lost_normal": _zeros(stages), "rounds_normal": _zeros(stages),
		"normal_fights": _zeros(stages), "gold_at_stage_end": _zeros(stages), "gold_earned": _zeros(stages),
		"potions_used": _zeros(stages), "cleared": false, "stuck": false, "stuck_floor": 0, "party_size": 0,
		"gold_at_16": 0, "first_level": {} }
	var wipes_at := {}   # floor -> wipes there (gives up after MAX_WIPES_PER_FLOOR)
	var last_floor := 0
	var started := Time.get_ticks_msec()
	while GameState.floor_number <= floors and not GameState.pending_completion:
		var n := GameState.floor_number
		var st := mini((n - 1) / 10, stages - 1)
		if Time.get_ticks_msec() - started > MAX_RUN_MSEC:
			r.stuck = true
			print("   (run timed out on floor %d)" % n)
			break
		if n != last_floor:
			last_floor = n
			_on_new_floor(r, n)
			if not r.first_level.has(n):
				r.first_level[n] = _avg_level()
		var layout := GameState.current_layout()
		_level_up_everyone()
		_recruit_from(layout)
		if layout.campfire.x >= 0:
			GameState.full_restore_party()
		if layout.merchant.x >= 0:
			_shop()
		_patch_up()
		var lost_floor := false
		for i in GameState.floor_enemies.size():
			var e: Dictionary = GameState.floor_enemies[i]
			if not e.alive:
				continue
			var kind := GameState.enemy_kind(e)
			if kind == "roaming":
				continue   # roaming bosses are optional (you can flee); the bot skips them
			if kind == "boss":
				r.level_at_boss[st] = GameState.player.level
			var gold_before := GameState.player.gold
			var res := _fight(i)
			if res.outcome == BattleManager.Outcome.DEFEAT:
				r.wipes_by_stage[st] += 1
				if kind == "boss":
					r.boss_wipes[st] += 1
				elif kind == "miniboss":
					r.mini_wipes[st] += 1
				wipes_at[n] = wipes_at.get(n, 0) + 1
				lost_floor = true
				break
			r.gold_earned[st] += maxi(0, GameState.player.gold - gold_before)
			r.potions_used[st] += res.potions
			if kind == "normal":
				r.hp_lost_normal[st] += res.hp_lost
				r.rounds_normal[st] += res.rounds
				r.normal_fights[st] += 1
			_level_up_everyone()
			_patch_up()
		if lost_floor:
			if wipes_at[n] >= int(_args.get("max_wipes", str(MAX_WIPES_PER_FLOOR))):
				r.stuck = true
				r.stuck_floor = n
				if _args.has("why"):
					print("\n".join(_recent))
				break
			continue   # handle_defeat already moved us back to the checkpoint
		if GameState.pending_completion:
			r.cleared = true
			break
		r.gold_at_stage_end[st] = GameState.player.gold
		if n == 16:
			r.gold_at_16 = GameState.player.gold
		GameState.enter_floor(n + 1)
	for st in stages:
		if r.normal_fights[st] > 0:
			r.hp_lost_normal[st] /= r.normal_fights[st]
			r.rounds_normal[st] /= r.normal_fights[st]
	r.party_size = GameState.battle_party().size()
	if GameState.floor_number > floors:
		r.cleared = true
	return r


func _zeros(n: int) -> Array:
	var a := []
	a.resize(n)
	a.fill(0.0)
	return a


func _on_new_floor(_r: Dictionary, _n: int) -> void:
	GameState.quests.messages.clear()
	GameState.guilds.messages.clear()
	GameState.route.messages.clear()
	GameState.blessings.messages.clear()
	GameState.pending_talks.clear()


# =========================================================
# One fight
# =========================================================

func _fight(index: int) -> Dictionary:
	GameState.prepare_floor_battle(index)
	GameState.return_scene = ""
	var fighters := GameState.fighting_party()
	var hp_before := 0
	var hp_max := 0
	for c in fighters:
		hp_before += c.current_hp()
		hp_max += c.max_hp()
	var battle := BattleManager.new()
	GameState.configure_battle(battle)
	battle.setup(fighters, GameState.pending_encounter)
	var potions := 0
	battle.start()
	var actions := 0
	while not battle.is_over() and actions < MAX_ACTIONS:
		actions += 1
		if battle.current == null:
			break
		if battle.current.ai_controlled:
			battle.advance()
		else:
			var actor := battle.current
			var a := _choose(battle, actor)
			if battle.submit(a):
				if a.type == BattleAction.Type.ITEM:
					potions += 1
			elif not battle.submit(BattleAI.choose(battle, actor)):
				battle.submit(BattleAction.simple(BattleAction.Type.DEFEND, actor))
	if not battle.is_over():
		if _args.has("debug"):
			print("   stalemate on floor %d after %d actions (current: %s)" % [GameState.floor_number, actions,
				battle.current.display_name if battle.current else "none"])
		battle.outcome = BattleManager.Outcome.DEFEAT   # a stalemate counts as a loss
	battle.write_back_party()
	if battle.outcome == BattleManager.Outcome.VICTORY:
		battle.apply_rewards()
		GameState.grant_reserve_xp(battle.rewards.xp, fighters)
		GameState.collect_battle_tax(battle.gold_given)
		for g in battle.rewards.gear:
			GameState.inventory.add_gear(g)
	var hp_after := 0
	for c in fighters:
		hp_after += c.current_hp()
	var rounds := battle.round_number
	var outcome := battle.outcome
	var line := "   floor %d %s vs %s: %s in %d rounds, party HP %d -> %d (levels %s)" % [GameState.floor_number,
		GameState.pending_battle_info.get("kind", "?"), GameState.pending_encounter.map(func(d): return d.id),
		["-", "WIN", "LOSS", "FLED"][outcome], rounds, hp_before, hp_after, fighters.map(func(c): return c.level)]
	_recent.append(line)
	if _recent.size() > 4:
		_recent.pop_front()
	if _args.has("debug"):
		print(line)
	GameState.finish_battle(outcome, fighters)
	return { "outcome": outcome, "potions": potions, "rounds": rounds,
		"hp_lost": float(hp_before - hp_after) / maxi(1, hp_max) }


## A decent player's turn: revive / heal when it matters, otherwise hit the
## lowest-HP reachable enemy with the best affordable attack (known
## weaknesses count).
func _choose(battle: BattleManager, actor: Combatant) -> BattleAction:
	var allies := battle.allies_of(actor)
	var inv := GameState.inventory
	for u in allies:
		if not u.is_alive() and inv.count(&"goddess_tear") > 0:
			return BattleAction.use_item(actor, ItemLibrary.get_item(&"goddess_tear"), u)
	var hurt: Combatant = null
	for u in allies:
		if u.is_alive() and float(u.hp) / u.max_hp < 0.35 and (hurt == null or u.hp < hurt.hp):
			hurt = u
	if hurt:
		for s in actor.skills:
			if s.effect == SkillDef.Effect.HEAL and actor.can_afford(s):
				return BattleAction.use_skill(actor, s, hurt if s.is_single_target() else null)
		for id in [&"advanced_potion", &"potion"]:
			if inv.count(id) > 0:
				return BattleAction.use_item(actor, ItemLibrary.get_item(id), hurt)
	# Support play: keep up party buffs and taunts (once, while they last).
	for s in actor.skills:
		if s.effect != SkillDef.Effect.STATUS or not actor.can_afford(s) or s.status_id == &"":
			continue
		if s.targets_enemies():
			continue
		var targets := battle.valid_targets(actor, s)
		if targets.is_empty():
			continue
		var already := targets.any(func(t): return t.has_status(s.status_id))
		if already:
			continue
		if s.status_id == &"taunt" and float(actor.hp) / actor.max_hp < 0.5:
			continue   # don't draw fire when you can't take it
		var t: Combatant = targets[0] if s.is_single_target() else null
		return BattleAction.use_skill(actor, s, t)
	var best_skill: SkillDef = actor.basic_attack
	var best_target: Combatant = null
	var best_score := -1.0
	for s in [actor.basic_attack] + actor.skills:
		if s.effect != SkillDef.Effect.DAMAGE or not actor.can_afford(s):
			continue
		var targets := battle.valid_targets(actor, s)
		if targets.is_empty():
			continue
		var els := DamageCalc.attack_elements(actor, s)
		for t in targets:
			var mult := 1.0
			for el in els:
				var known := GameState.bestiary.summary(t.source_enemy) if t.source_enemy else ""
				var aff: int = t.affinities.get(el, Element.Affinity.NORMAL)
				if aff == Element.Affinity.WEAK and known.contains(Element.name_of(el)):
					mult = 1.5
				elif aff in [Element.Affinity.RESIST, Element.Affinity.IMMUNE, Element.Affinity.ABSORB] and known.contains(Element.name_of(el)):
					mult = minf(mult, 0.3)
			var hits := 1.0 if s.is_single_target() else float(targets.size())
			var cost_penalty := 1.0 - 0.3 * float(s.mp_cost) / maxf(1.0, actor.mp)
			var score: float = s.power * mult * hits * cost_penalty + 0.3 * (1.0 - float(t.hp) / t.max_hp)
			if score > best_score:
				best_score = score
				best_skill = s
				best_target = t
	if best_target == null:
		return BattleAI.choose(battle, actor)
	return BattleAction.use_skill(actor, best_skill, best_target if best_skill.is_single_target() else null)


# =========================================================
# Between fights
# =========================================================

func _avg_level() -> float:
	var party := GameState.battle_party()
	var t := 0.0
	for c in party:
		t += c.level
	return t / party.size()


func _members() -> Array:
	return GameState.battle_party() + GameState.reserve


func _level_up_everyone() -> void:
	for c in _members():
		var build: StringName = c.get_meta("build", &"") if c.has_meta("build") else &""
		if build == &"":
			continue   # recruits come with their own build (NpcLibrary)
		if c.unspent_points > 0:
			c.apply_allocation(_split(c.unspent_points, build))
		if c.can_choose_class():
			var def := ClassRegistry.get_class_def(build)
			if def and def.qualifies(c.stats):
				c.choose_class(def)
	for c in _members():
		while c.skill_picks > 0:
			var pool: Array = c.pickable_skills()
			if pool.is_empty():
				# Pool finished: rank up the strongest attack (or anything rankable).
				var best: SkillDef = null
				for s in c.all_skills():
					if c.can_rank_up(s.id) and (best == null or (s.effect == SkillDef.Effect.DAMAGE and s.power > best.power)):
						best = s
				if best == null or not c.rank_up_skill(best.id):
					break
				continue
			# Like a player who reads the stage hints: an attack that hits this
			# stage's weakness, else one that fits the build.
			var magic: bool = c.stats.get_total(Stats.Type.INTELLIGENCE) > c.stats.get_total(Stats.Type.STRENGTH)
			var family: StringName = StageLibrary.stage_for_floor(GameState.floor_number).get("family", &"")
			var weak := []
			for el in EnemyFamilies.FAMILIES.get(family, {}).get("affinities", {}):
				if EnemyFamilies.FAMILIES[family].affinities[el] == Element.Affinity.WEAK:
					weak.append(el)
			var fits := []
			for s in pool:
				if s.effect == SkillDef.Effect.DAMAGE and s.elements.any(func(el): return weak.has(el)):
					fits.append(s)
			if fits.is_empty():
				for s in pool:
					if s.effect == SkillDef.Effect.DAMAGE and (s.damage_type == SkillDef.DamageType.MAGIC) == magic:
						fits.append(s)
			var from: Array = fits if not fits.is_empty() else pool
			var pick: SkillDef = from[_rng.randi_range(0, from.size() - 1)]
			if not c.pick_skill(pick.id):
				break
		for def in c.available_advancements():
			var trial := CharacterData.trial_id(def)
			if GameState.quests.is_new(trial):
				GameState.quests.start(trial)
			if c.can_advance(def):
				c.advance_class(def)
				break
	for item in GameState.inventory.owned():
		if item.is_skill_book():
			for c in _members():
				if GameState.inventory.use_on_character(item.id, c):
					break
	_equip_best()


## 75% of points into the class's stats, the rest into Health / Stamina.
func _split(points: int, build: StringName) -> Dictionary:
	var def := ClassRegistry.get_class_def(build)
	var weights := {}
	for s in def.required_stats:
		weights[s] = 75.0 / def.required_stats.size()
	var offense := def.required_stats.any(func(s): return s in [Stats.Type.STRENGTH, Stats.Type.INTELLIGENCE, Stats.Type.AGILITY])
	if offense:
		weights[Stats.Type.HEALTH] = weights.get(Stats.Type.HEALTH, 0.0) + 15.0
		weights[Stats.Type.STAMINA] = weights.get(Stats.Type.STAMINA, 0.0) + 10.0
	else:   # a defensive build still needs something to hit with
		weights[Stats.Type.STRENGTH] = 25.0
	return NpcLibrary.split_points(points, weights)


func _equip_best() -> void:
	for g: GearItem in GameState.inventory.gear.duplicate():
		for c in _members():
			if not g.can_equip(c):
				continue
			var cur: GearItem = c.get_equipped(g.slot)
			if cur == null or g.total_bonus() > cur.total_bonus():
				GameState.equip_from_bag(c, g)
				break


func _recruit_from(layout: FloorLayout) -> void:
	for p in layout.npcs:
		var id: StringName = layout.npcs[p]
		if not NpcLibrary.is_recruitable(id) or GameState.has_recruited(id):
			continue
		var r := NpcLibrary.recruit_info(id)
		match r.get("meet", "campfire"):
			"hire":   # pay if it leaves something for potions
				if GameState.player.gold >= r.get("fee", 0) + 300 and not GameState.npc_refuses(id):
					GameState.player.gold -= r.fee
					GameState.recruit(id)
			"favor":
				var fid := QuestLibrary.favor_id(id)
				if GameState.quests.is_done(fid):
					GameState.recruit(id)
				elif GameState.quests.is_new(fid):
					GameState.quests.start(fid)
			_:
				GameState.recruit(id)


func _shop() -> void:
	var p := GameState.player
	for id in POTION_STOCK:
		while GameState.inventory.count(id) < POTION_STOCK[id] and GameState.for_sale(id):
			var item := ItemLibrary.get_item(id)
			if p.gold < GameState.shop_price(item) + 100 or not GameState.buy_item(id):
				break


## Out of battle: potions on anyone under half HP.
func _patch_up() -> void:
	for c in GameState.battle_party():
		while not c.is_downed() and c.current_hp() < c.max_hp() * 0.5:
			if not (GameState.inventory.use_on_character(&"potion", c) or GameState.inventory.use_on_character(&"advanced_potion", c)):
				break


# =========================================================
# Guild world (no fighting): how busy is it, and does the patron matter?
# =========================================================

func _guild_world(runs: int) -> void:
	var setups := [
		["no patron, no guild", &"", &""],
		["no patron, member of Order of the Aegis", &"", &"order_of_the_aegis"],
		["calm patron (Inari), member", &"inari", &"order_of_the_aegis"],
		["warlike patron (Loki), member", &"loki", &"order_of_the_aegis"],
		["feud: blessed by Ra (Apep's Serpent Coil hates you), member", &"ra", &"order_of_the_aegis"],
		["own guild from floor 16, no patron", &"", &"own"],
		["own guild from floor 16, Ra (feud with Serpent Coil)", &"ra", &"own"],
	]
	print("\n===== Guild world: %d runs x 30 floors per setup =====" % runs)
	for su in setups:
		var tot := { "news": 0.0, "wars": 0.0, "wars_you": 0.0, "raids": 0.0, "raids_you": 0.0, "allies": 0.0,
			"fortify": 0.0, "truces": 0.0, "your_floors_lost": 0.0 }
		for i in runs:
			GameState.start_new_game("Bot", "Rowan", 1, Difficulty.Level.NORMAL, false)
			GameState.player.legacy_id = "world-%d" % i
			if su[1] != &"":
				GameState.player.bless(su[1], 1)
			if su[2] != &"" and su[2] != &"own":
				GameState.guilds.join(su[2])
			var gs := GameState.guilds
			for n in range(2, 31):
				if su[2] == &"own" and n == 16:
					GameState.player.gold = GuildState.CHARTER_COST
					GameState.highest_floor = 16
					gs.found_guild("Bot Guild", su[1])
					gs.owners[4] = GuildLibrary.PLAYER_GUILD
					gs.owners[5] = GuildLibrary.PLAYER_GUILD
				var before := gs.news.size()
				var wars_before := gs.wars.size()
				GameState.enter_floor(n)
				CutIns.skip_all()
				for k in range(before, gs.news.size()):
					var t: String = gs.news[k].text
					tot.news += 1
					if t.contains("declares war"):
						tot.wars += 1
						if gs.your_side().any(func(g): return t.contains(GuildLibrary.guild_name(g))):
							tot.wars_you += 1
					elif t.contains("robbed") or t.contains("tried to rob"):
						tot.raids += 1
						if gs.your_side().any(func(g): return t.contains("rob " + GuildLibrary.guild_name(g)) or t.contains("robbed " + GuildLibrary.guild_name(g))):
							tot.raids_you += 1
					elif t.contains("alliance"):
						tot.allies += 1
					elif t.contains("fortifies"):
						tot.fortify += 1
					elif t.contains("truce"):
						tot.truces += 1
					if su[2] == &"own" and t.contains("takes") and t.contains("from " + GuildLibrary.guild_name(GuildLibrary.PLAYER_GUILD)):
						tot.your_floors_lost += 1
			for k in tot:
				pass
		for k in tot:
			tot[k] /= runs
		print("%s:\n   news %.1f per 30 floors (one every %.1f floors) | wars %.1f (vs your side %.1f) | raids %.1f (on you %.1f) | alliances %.1f | fortify %.1f | truces %.1f | your floors lost %.1f" % [
			su[0], tot.news, 29.0 / maxf(0.1, tot.news), tot.wars, tot.wars_you, tot.raids, tot.raids_you,
			tot.allies, tot.fortify, tot.truces, tot.your_floors_lost])
