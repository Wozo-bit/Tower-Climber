extends Node
## Demigods (legendary recruits with their own classes), summons, Fury,
## NG+ Ascension and the Ascendant growing with each advancement gate.
## Run:  godot --headless res://tests/test_demigods.tscn

var _passed := 0
var _failed := 0

const DEMIGODS := [&"heracles", &"perseus", &"achilles", &"gilgamesh", &"cu_chulainn", &"sigurd",
	&"theseus", &"hippolyta", &"orpheus", &"atalanta", &"enkidu", &"fionn", &"momotaro", &"bellerophon"]


func _ready() -> void:
	GameState.save_dir = "user://test_saves_demigods"
	GameState.unlocks_path = "user://test_saves_demigods_unlocks.json"
	Tips.path = "user://test_saves_demigods_tips.json"
	if FileAccess.file_exists(GameState.unlocks_path):
		DirAccess.remove_absolute(GameState.unlocks_path)
	test_demigod_classes()
	test_omen()
	test_legend_chain()
	test_summons()
	test_fury()
	test_ascension()
	test_ascendant_gates()
	test_saving()
	test_unlocks()
	test_bonds()
	GameState.delete_slot(1)
	GameState.reset_run()
	print("\n==== %d passed, %d failed ====" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)


func check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  ", label)
	else:
		_failed += 1
		printerr("  FAIL  ", label)


func _fresh() -> void:
	GameState.start_new_game("Ophelius", "Cassia", 1)
	GameState.player.gold = 5000


func _beat(ids: Array, times: int) -> void:
	var rng := RandomNumberGenerator.new()
	for i in times:
		GameState.quests.on_battle_won(EnemyLibrary.build_group(ids), rng)


## A level-`lvl` character whose class is set straight to `class_id`.
func _hero(class_id: StringName, lvl: int) -> CharacterData:
	var c := GameState.make_premade("Hero", &"mage", { Stats.Type.INTELLIGENCE: 20, Stats.Type.AGILITY: 15 })
	while c.level < lvl:
		c.level_up()
	c.class_id = class_id
	c._apply_class_bonus()
	return c


func test_demigod_classes() -> void:
	print("Demigod classes")
	_fresh()
	var problems := []
	var asc := ClassRegistry.get_class_def(&"ascendant")
	for id in DEMIGODS:
		var r := NpcLibrary.recruit_info(id)
		var def := ClassRegistry.get_class_def(r.get("class_id", &""))
		if def == null or def.unique_to != id or not def.is_secret:
			problems.append("%s: class must be theirs alone" % id)
			continue
		if r.get("meet", "") != "legend" or NpcLibrary.get_npc(id).get("min_floor", 0) < 30:
			problems.append("%s: a floor-30+ legend" % id)
		if def.stat_bonus_pct >= asc.stat_bonus_pct:
			problems.append("%s: stronger than the Ascendant" % id)
		if ClassRegistry.advancements_for(def.id).size() != 1:
			problems.append("%s: needs a tier-3 form" % id)
		if not NpcLibrary.get_npc(id).get("if", {}).has("patron_pantheon"):
			problems.append("%s: tied to a pantheon" % id)
	check(problems.is_empty(), "%d demigods, each with a class only they can have %s" % [DEMIGODS.size(), problems])
	var lion := ClassRegistry.get_class_def(&"lionheart")
	var p := _hero(&"", 30)
	check(not ClassRegistry.get_qualifying(p.stats, 1, GameState.unlocked_secret_classes()).has(lion),
		"nobody else can pick a demigod's class")
	var h := NpcLibrary.make_recruit(&"heracles", 30)
	check(h.class_id == &"lionheart" and h.stats.class_bonus_pct == lion.stat_bonus_pct, "Heracles is a Lionheart from the start")
	check(h.personal_skill == &"nemean_roar", "with his own skill (after his loyalty quest)")


func test_omen() -> void:
	print("Pantheon omens")
	_fresh()
	check(not DialogueRunner.check({ "patron_pantheon": "Greek" }), "no patron: no Greek omen")
	GameState.player.blessing_id = &"zeus"
	check(DialogueRunner.check({ "patron_pantheon": "Greek" }), "blessed by Zeus: Greek demigods may appear")
	check(not DialogueRunner.check({ "patron_pantheon": "Norse" }), "...but not Norse ones")
	GameState.player.blessing_id = &""


func test_legend_chain() -> void:
	print("Legend chain")
	_fresh()
	var r := DialogueRunner.new()
	r.start(&"recruit_legend", null, &"", &"", &"perseus")
	check(r.node_id == "omen", "an omen by the campfire")
	r.advance()
	check(r.node_id == "ask" and r.text().contains("Athena"), "then the demigod speaks")
	r.choose(0)
	check(GameState.quests.is_active(QuestLibrary.favor_id(&"perseus")) and not GameState.has_recruited(&"perseus"),
		"accepting starts the legendary trial")
	r.start(&"recruit_legend", null, &"", &"", &"perseus")
	check(r.node_id == "waiting", "they wait while it's not done")
	_beat([&"goblin_captain"], 2)
	_beat([&"moonfang"], 1)
	r.start(&"recruit_legend", null, &"", &"", &"perseus")
	check(r.node_id == "ready", "2 minibosses + a boss: the legend is proven")
	r.choose(r.choices()[0].index)
	var c: Array = (GameState.companions + GameState.reserve).filter(func(m): return m.companion_id == &"perseus")
	check(not c.is_empty() and c[0].class_id == &"gorgonbane", "Perseus joins as a Gorgonbane")


func test_summons() -> void:
	print("Summons")
	var s := GameState.make_premade("Sum", &"summoner", { Stats.Type.INTELLIGENCE: 20, Stats.Type.LUCK: 15 })
	var b := BattleManager.new()
	b.setup([s] as Array[CharacterData], EnemyLibrary.build_group([&"slime"]), 1)
	b.start()
	var joined := []
	b.unit_joined.connect(func(u): joined.append(u))
	var me: Combatant = b.party[0]
	var skill := SkillLibrary.get_skill(&"summon_wisp")
	b.current = me
	check(b.submit(BattleAction.use_skill(me, skill, me)), "cast Summon Wisp")
	check(b.party.size() == 2 and joined.size() == 1 and b.party[1].summoned_by == me, "a wisp joins your side")
	check(b.party[1].side == Combatant.Side.PARTY, "...and fights for you")
	if b.outcome == BattleManager.Outcome.NONE:
		b.party[1].hp = 1
		me.mp = me.max_mp
		b.current = me
		b.submit(BattleAction.use_skill(me, skill, me))
		check(b.party.size() == 2 and b.party[1].hp == b.party[1].max_hp, "casting again refreshes it (one per summoner)")
	var e := EnemyLibrary.get_enemy(&"wisp")
	check(e.xp_reward == 0 and e.gold_reward == 0, "summons give no rewards")


func test_fury() -> void:
	print("Fury")
	var c := GameState.make_premade("War", &"warrior", { Stats.Type.STRENGTH: 20, Stats.Type.HEALTH: 15 })
	var a := Combatant.from_character(c)
	var t := Combatant.from_enemy(EnemyLibrary.get_enemy(&"slime"))
	var skill := SkillLibrary.get_skill(&"attack_melee") if SkillLibrary.get_skill_or_null(&"attack_melee") else c.all_skills()[0]
	var plain := 0
	var angry := 0
	for i in 200:
		var rng := RandomNumberGenerator.new()
		rng.seed = i
		plain += DamageCalc.roll_damage(a, t, skill, rng).amount
	a.add_status(&"fury", 3)
	for i in 200:
		var rng := RandomNumberGenerator.new()
		rng.seed = i
		angry += DamageCalc.roll_damage(a, t, skill, rng).amount
	check(angry > plain * 1.2, "Fury hits harder (%d -> %d)" % [plain, angry])


func test_ascension() -> void:
	print("Ascension")
	_fresh()
	var c := _hero(&"inferno_sage", 50) if ClassRegistry.get_class_def(&"inferno_sage") else null
	if c == null:
		var t3: Array = ClassRegistry.get_tier(3).filter(func(d): return d.unique_to == &"")
		c = _hero(t3[0].id, 50)
	GameState.highest_floor = 41
	GameState.ng_plus_cycle = 0
	check(c.ascension_refusal() != "" and not c.ascend(), "no Ascension in the first run")
	GameState.ng_plus_cycle = 1
	var low := _hero(c.class_id, 40)
	check(low.ascension_refusal().contains("level"), "needs level 50")
	var t2 := _hero(ClassRegistry.get_tier(2)[0].id, 50)
	check(t2.ascension_refusal().contains("tier"), "needs a tier-3 class")
	GameState.highest_floor = 40
	check(c.ascension_refusal().contains("floor"), "needs to climb past floor 40")
	GameState.highest_floor = 41
	var before := c.stats.class_bonus_pct
	check(c.ascension_refusal() == "" and c.ascend(), "NG+, tier 3, level 50, floor 41: Ascend")
	check(c.class_title().begins_with("Ascended "), "the title says so (%s)" % c.class_title())
	check(is_equal_approx(c.stats.class_bonus_pct, before + ClassRegistry.ASCENSION_BONUS), "+5% on top of the class")
	check(c.all_skills().any(func(s): return s.id == SkillLibrary.ASCENSION_SKILL), "and Apotheosis")
	check(not c.ascend(), "only once")
	var asc := _hero(&"ascendant", 50)
	check(asc.ascension_refusal() != "", "the Ascendant itself doesn't Ascend")
	check(asc.stats.class_bonus_pct > c.stats.class_bonus_pct, "and stays stronger than any Ascended line")


func test_ascendant_gates() -> void:
	print("Ascendant grows")
	_fresh()
	var a := _hero(&"ascendant", 25)
	GameState.highest_floor = 5
	var has := func(id): return a.all_skills().any(func(s): return s.id == id)
	check(not has.call(&"ascendant_will"), "no gate skill before tier 2's gate")
	GameState.highest_floor = 21
	check(has.call(&"ascendant_will") and not has.call(&"ascendant_dominion"), "tier-2 gate open: Ascendant's Will")
	GameState.highest_floor = 41
	while a.level < 45:
		a.level_up()
	check(has.call(&"ascendant_dominion"), "tier-3 gate open: Ascendant's Dominion")


func test_saving() -> void:
	print("Saving")
	_fresh()
	GameState.ng_plus_cycle = 1
	GameState.highest_floor = 41
	var t3: Array = ClassRegistry.get_tier(3).filter(func(d): return d.unique_to == &"")
	var p := GameState.player
	while p.level < 50:
		p.level_up()
	p.class_id = t3[0].id
	p._apply_class_bonus()
	check(p.ascend(), "the player Ascends")
	var h := GameState.recruit(&"heracles")
	check(h != null and h.class_id == &"lionheart", "Heracles joins")
	GameState.save_game()
	GameState.load_game(1)
	check(GameState.player.ascended and GameState.player.class_title().begins_with("Ascended"), "Ascension is saved")
	check((GameState.companions + GameState.reserve).any(func(m): return m.companion_id == &"heracles" and m.class_id == &"lionheart"),
		"a demigod's class is saved")
	var d := SaveSerializer.read_json(GameState.slot_path(1))
	d.player["class"] = "lionheart"
	SaveSerializer.write_json(GameState.slot_path(1), d)
	GameState.load_game(1)
	check(GameState.player.class_id != &"lionheart", "tampered save: the player can't be a demigod's class")
	d = SaveSerializer.read_json(GameState.slot_path(1))
	d.player["class"] = String(ClassRegistry.get_tier(2)[0].id)
	d.player["ascended"] = true
	SaveSerializer.write_json(GameState.slot_path(1), d)
	GameState.load_game(1)
	check(not GameState.player.ascended, "tampered save: Ascension below tier 3 is dropped")


## Hayden 2026-10-25: a demigod who joined you once waits on floor 20 in
## every later run (any character), and joins without the legend chain.
func test_unlocks() -> void:
	print("Unlocked demigods")
	if FileAccess.file_exists(GameState.unlocks_path):
		DirAccess.remove_absolute(GameState.unlocks_path)
	_fresh()
	check(GameState.unlocked_demigods().is_empty(), "nothing unlocked at first")
	GameState.recruit(&"theseus")
	check(GameState.is_demigod_unlocked(&"theseus") and not GameState.is_demigod_unlocked(&"orpheus"), "recruiting one unlocks them")
	GameState.recruit(&"daphne")
	check(not GameState.unlocked_demigods().has(&"daphne"), "only demigods are remembered")
	# A brand-new character, no Greek patron at all.
	GameState.start_new_game("Brenna", "Cassia", 2)
	GameState.enter_floor(GameState.UNLOCKED_DEMIGOD_FLOOR)
	var layout := GameState.current_layout()
	check(not layout.npcs.values().has(&"theseus"), "not while the floor-20 boss lives")
	GameState.floor_enemies[0].alive = false
	layout = GameState.current_layout()
	check(layout.npcs.values().has(&"theseus"), "after it falls, Theseus waits by the campfire")
	var r := DialogueRunner.new()
	r.start(&"recruit_legend", null, &"", &"", &"theseus")
	check(r.node_id == "returning", "he remembers you (no omen, no trial)")
	r.choose(r.choices()[0].index)
	check(GameState.has_recruited(&"theseus"), "and joins")
	GameState.enter_floor(25)
	check(not GameState.current_layout().npcs.values().has(&"theseus"), "...only once a run")
	var d := SaveSerializer.read_json(GameState.unlocks_path)
	d.demigods.append("garrick")
	d.demigods.append("zeus")
	SaveSerializer.write_json(GameState.unlocks_path, d)
	check(GameState.unlocked_demigods() == [&"theseus"], "a tampered unlock file only counts real demigods")


func test_bonds() -> void:
	print("Bonds")
	check(NpcLibrary.BONDS.all(func(b): return DEMIGODS.has(b.pair[0]) and DEMIGODS.has(b.pair[1])), "every bond is between demigods")
	var g := NpcLibrary.make_recruit(&"gilgamesh", 30)
	var e := NpcLibrary.make_recruit(&"enkidu", 30)
	var h := NpcLibrary.make_recruit(&"heracles", 30)
	var b := BattleManager.new()
	b.setup([g, e, h] as Array[CharacterData], EnemyLibrary.build_group([&"slime"]), 1)
	var mult := b.party.map(func(u): return u.damage_dealt_mult)
	check(mult == [NpcLibrary.BOND_DEALT, NpcLibrary.BOND_DEALT, 1.0], "Gilgamesh and Enkidu fight better together (Heracles alone doesn't)")
	check(b.start_lines.size() == 1 and b.start_lines[0].contains("Enkidu"), "and the log says so")
	var b2 := BattleManager.new()
	b2.setup([g, h] as Array[CharacterData], EnemyLibrary.build_group([&"slime"]), 1)
	check(b2.party.all(func(u): return u.damage_dealt_mult == 1.0), "no pair, no bond")
