extends Node
## Presentation: UI theme palettes, art hooks (Assets), audio hooks (Audio +
## MusicLibrary), cut-ins, system notices, credits / license tracking, and
## your guild declaring war (which plays the war cut-in).
## Run:  godot --headless res://tests/test_presentation.tscn
## Test art/audio files go to user://test_presentation_* and are deleted after.

const ART := "user://test_presentation_art"
const AUDIO := "user://test_presentation_audio"
const CREDITS_ROOT := "user://test_presentation_credits"

var _passed := 0
var _failed := 0


func _ready() -> void:
	GameState.save_dir = "user://test_saves_presentation"
	GameState.unlocks_path = "user://test_saves_presentation_unlocks.json"
	Tips.path = "user://test_saves_presentation_tips.json"
	test_themes()
	test_assets()
	test_audio()
	test_music_library()
	test_cut_in_data()
	test_cut_in_player()
	test_war_cut_ins()
	test_player_war()
	test_system_notices()
	test_action_sounds()
	test_dialogue_portraits()
	test_credits()
	_cleanup()
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


func _fresh(floor_n: int = 5) -> void:
	GameState.reset_run()
	GameState.player = GameState.make_premade("Ophelius", &"rogue", { Stats.Type.AGILITY: 20, Stats.Type.LUCK: 15 })
	GameState.player.legacy_id = "presentation-test"
	GameState.companions.append(GameState.make_childhood_friend("Cassia"))
	GameState.floor_number = floor_n
	GameState.highest_floor = floor_n


# =========================================================
# Helpers: tiny files on disk
# =========================================================

func _png(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color.RED)
	img.save_png(path)


## A tenth of a second of silence as a 16-bit mono WAV.
func _wav(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var rate := 22050
	var samples := rate / 10
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_buffer("RIFF".to_ascii_buffer())
	f.store_32(36 + samples * 2)
	f.store_buffer("WAVEfmt ".to_ascii_buffer())
	f.store_32(16)
	f.store_16(1)          # PCM
	f.store_16(1)          # mono
	f.store_32(rate)
	f.store_32(rate * 2)   # byte rate
	f.store_16(2)          # block align
	f.store_16(16)         # bits per sample
	f.store_buffer("data".to_ascii_buffer())
	f.store_32(samples * 2)
	for i in samples:
		f.store_16(0)
	f.close()


func _rm_tree(dir: String) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for sub in d.get_directories():
		_rm_tree("%s/%s" % [dir, sub])
	for f in d.get_files():
		d.remove(f)
	DirAccess.remove_absolute(dir)


func _cleanup() -> void:
	for dir in [ART, AUDIO, CREDITS_ROOT]:
		_rm_tree(dir)
	Assets.roots = [Assets.ART_ROOT]
	Assets.clear_cache()
	Audio.music_roots = [Audio.MUSIC_ROOT]
	Audio.sfx_roots = [Audio.SFX_ROOT]
	Audio.clear_cache()
	Audio.stop_music(0.0)
	CutIns.skip_all()
	Settings.cutins = true


# =========================================================
# Tests
# =========================================================

func test_themes() -> void:
	print("Themes")
	check(UITheme.PALETTES.has(UITheme.DEFAULT) and UITheme.DEFAULT == &"system_blue", "the default look is the blue system glow")
	check(UITheme.ids().size() >= 5, "there's a variety of palettes to pick from")
	var complete := true
	for id in UITheme.PALETTES:
		for key in UITheme.KEYS:
			complete = complete and UITheme.PALETTES[id].has(key)
	check(complete, "every palette defines every colour")
	var theme := UITheme.build(&"crimson_pact")
	check(theme.is_type_variation(UITheme.PANEL_VARIATION, "PanelContainer"), "the theme has the system-window panel style")
	var box := theme.get_stylebox("panel", UITheme.PANEL_VARIATION) as StyleBoxFlat
	check(box != null and box.shadow_size > 0 and box.border_color == UITheme.PALETTES[&"crimson_pact"].border,
		"system windows glow in the palette's colour")
	check(theme.has_stylebox("hover", "Button") and theme.has_color("font_color", "Label"), "buttons and labels are styled")
	check(not UITheme.is_valid("not_a_theme") and UITheme.palette(&"not_a_theme") == UITheme.PALETTES[UITheme.DEFAULT],
		"an unknown palette falls back to the default")

	var before := Settings.ui_theme
	Settings.ui_theme = &"royal_gold"
	Settings.apply()
	var orphan := CanvasLayer.new()   # the floor HUD's menus live under a CanvasLayer
	var btn := Button.new()
	orphan.add_child(btn)
	add_child(orphan)
	check(UITheme.current == &"royal_gold" and btn.get_theme_stylebox("hover").border_color == UITheme.PALETTES[&"royal_gold"].border,
		"Settings applies the palette to the whole game (even under a CanvasLayer)")
	orphan.free()
	check(UITheme.color("accent") == UITheme.PALETTES[&"royal_gold"].accent, "colours follow the chosen palette")
	Settings.ui_theme = before
	Settings.apply()
	var panel := PanelContainer.new()
	UIStyle.apply(panel)
	check(panel.theme_type_variation == UITheme.PANEL_VARIATION, "popup panels use the themed system window")
	panel.free()


func test_assets() -> void:
	print("Art hooks")
	Assets.clear_cache()
	check(Assets.texture("enemies", "goblin") == null, "no art yet: the placeholder stays")
	_png(ART + "/enemies/goblin.png")
	_png(ART + "/portraits/player.png")
	_png(ART + "/classes/rogue.png")
	Assets.roots = [Assets.ART_ROOT, ART]
	check(Assets.texture("enemies", "goblin") == null, "misses are cached until the cache is cleared")
	Assets.clear_cache()
	check(Assets.texture("enemies", "goblin") != null, "a dropped-in file is picked up")
	check(Assets.has("enemies", "goblin") and not Assets.has("enemies", "slime"), "has() checks for a picture")
	check(Assets.first([["cutins", "goblin"], ["enemies", "goblin"]]) == Assets.texture("enemies", "goblin"),
		"fallback chains use the first picture that exists")
	_fresh()
	check(Assets.portrait_for(GameState.player) == Assets.texture("portraits", "player"), "the player's own portrait")
	var friend := GameState.childhood_friend()
	friend.class_id = &"rogue"
	check(Assets.portrait_for(friend) == Assets.texture("classes", "rogue"), "no portrait of their own: their class's art")
	check(Assets.slug("Old Merchant") == "old_merchant" and Assets.slug("  Odin, the Allfather ") == "odin_the_allfather",
		"speaker names become file names")


func test_audio() -> void:
	print("Audio hooks")
	_wav(AUDIO + "/music/explore.wav")
	_wav(AUDIO + "/music/explore_2.wav")
	_wav(AUDIO + "/music/battle_goblin.wav")
	_wav(AUDIO + "/sfx/hit.wav")
	Audio.music_roots = [AUDIO + "/music"]
	Audio.sfx_roots = [AUDIO + "/sfx"]
	Audio.clear_cache()
	check(Audio.variants("music", "explore").size() == 2, "numbered files are variants of one track")
	check(Audio.variants("music", "boss").is_empty(), "missing tracks have no files")
	check(Audio.load_stream(AUDIO + "/sfx/hit.wav") != null, "raw sound files load")
	check(Audio.play_music(["explore_goblin_warrens", "explore"]) == "explore" and Audio.current_track == "explore",
		"music plays the first name in the list that has a file")
	check(Audio.play_music(["explore"]) == "explore", "asking for the same track keeps it playing")
	check(Audio.play_music(["battle_goblin_king", "battle_goblin", "battle"]) == "battle_goblin",
		"a family's battle track is used when the enemy has none of its own")
	check(Audio.play_music(["nothing_here"]) == "" and Audio.current_track == "", "no file at all: the music fades out")
	check(Audio.play_sfx(["hit_fire", "hit"]) == "hit", "sound effects fall back too")
	check(Audio.play_sfx("crit") == "", "a missing sound is just skipped")
	var b := Button.new()
	add_child(b)
	check(b.pressed.get_connections().size() > 0, "every button gets a click sound")
	b.queue_free()


func test_music_library() -> void:
	print("Music choice")
	_fresh(3)
	var theme := String(StageLibrary.theme_id_for_floor(3))
	var family := String(StageLibrary.THEMES[StringName(theme)].family)
	var walk := MusicLibrary.for_floor(3, false)
	check(walk.has("explore_" + theme) and walk.has("explore_" + family) and walk.back() == "explore",
		"floors try the stage's track, then the family's, then the generic one")
	var rest := MusicLibrary.for_floor(5, true)
	check(rest.find("rest") >= 0 and rest.find("rest") < rest.find("explore"), "rest floors have their own track first")
	var boss := MusicLibrary.for_battle("boss", [&"goblin_king"], 10)
	check(boss[0] == "boss_goblin_king" and boss.has("boss_goblin") and boss.back() == "battle",
		"a boss can have its own theme, else its family's boss theme")
	check(MusicLibrary.for_battle("boss", [&"goblin_king"], GameState.FINAL_FLOOR)[0] == "final_boss", "the final boss comes first on the last floor")
	var normal := MusicLibrary.for_battle("normal", [&"goblin", &"goblin_archer"], 3)
	check(normal[0] == "battle_goblin" and normal.back() == "battle", "ordinary fights match the enemies on the floor")
	var mini := MusicLibrary.for_battle("miniboss", [&"goblin_captain"], 4)
	check(mini[0] == "miniboss_goblin_captain" and mini.has("miniboss") and mini.back() == "battle", "minibosses fall back to battle music")
	var champ := MusicLibrary.for_battle("champion", [&"goblin"], 4, { "guild": &"iron_oath" })
	check(champ[0] == "champion_iron_oath" and champ.has("guild_battle"), "guild champions and guards get guild music")
	var roam := MusicLibrary.for_battle("roaming", [&"goblin"], 4, {})
	check(not roam.any(func(n): return n.ends_with("_")), "missing info never makes broken names")


func test_cut_in_data() -> void:
	print("Cut-in content")
	_fresh(10)
	var boss := CutInData.boss("boss", [&"goblin_king"], 10)
	check(boss.title == EnemyLibrary.get_enemy(&"goblin_king").display_name and boss.subtitle.contains("BOSS"),
		"bosses get a name card")
	check(CutInData.boss("boss", EnemyLibrary.build_group([&"goblin_king"]), GameState.FINAL_FLOOR).subtitle == "FINAL BOSS",
		"the final boss is announced as such")
	check(CutInData.is_big_fight("miniboss") and CutInData.is_big_fight("champion") and not CutInData.is_big_fight("normal")
		and not CutInData.is_big_fight("guard"), "only big fights get a name card")
	var legendary := SkillDef.new()
	legendary.id = &"test_legend"
	legendary.display_name = "Test Legend"
	legendary.tier = SkillTier.Tier.LEGENDARY
	var common := SkillDef.new()
	common.tier = SkillTier.Tier.COMMON
	check(CutInData.is_ultimate(legendary) and not CutInData.is_ultimate(common), "Legendary+ skills are ultimates")
	check(CutInData.is_ultimate(SkillLibrary.get_skill(&"righteous_smite")), "blessed skills are ultimates too")
	var being := CutInData.being(&"odin")
	check(being.title == BeingLibrary.full_name(&"odin") and being.kind == "being", "gods appear with their full name")
	var lv := CutInData.level_up([["Ophelius", 12], ["Cassia", 11]], true)
	check(lv.title == "LEVEL UP" and lv.subtitle.contains("Cassia  Lv 11") and lv.subtitle.contains("class"),
		"LEVEL UP lists everyone who levelled")
	var def := ClassRegistry.get_class_def(&"rogue")
	check(CutInData.class_change(GameState.player, def, true).title == "CLASS ACQUIRED"
		and CutInData.class_change(GameState.player, def, false).title == "CLASS ADVANCED", "class choices and advancements")


func test_cut_in_player() -> void:
	print("Cut-in player")
	CutIns.skip_all()
	Settings.cutins = false
	CutIns.play(CutInData.being(&"odin"))
	check(not CutIns.is_playing(), "turned off in Settings: nothing plays")
	Settings.cutins = true
	var done := [false]
	CutIns.finished.connect(func(): done[0] = true, CONNECT_ONE_SHOT)
	CutIns.play(CutInData.being(&"odin"))
	CutIns.play(CutInData.level_up([["Ophelius", 2]]))
	check(CutIns.is_playing() and CutIns._queue.size() == 1, "splashes queue up one after another")
	CutIns.skip_all()
	check(not CutIns.is_playing() and CutIns._queue.is_empty() and done[0], "skipping ends them and says so")


func test_war_cut_ins() -> void:
	print("War cut-ins")
	_fresh(16)
	CutIns.skip_all()
	var gs := GameState.guilds
	gs.declare_war(GuildLibrary.START_OWNERS[0], GuildLibrary.START_OWNERS[1], 0)
	check(not CutIns.is_playing(), "other guilds' wars are just news")
	GameState.player.gold = 2000
	gs.found_guild("Iron Climbers")
	gs.owners[2] = GuildLibrary.PLAYER_GUILD
	gs.declare_war(GuildLibrary.START_OWNERS[3], GuildLibrary.PLAYER_GUILD, 2)
	check(CutIns.is_playing(), "a guild declaring war on your guild gets a cut-in")
	CutIns.skip_all()
	_fresh(16)
	GameState.guilds.join(GuildLibrary.START_OWNERS[4])
	GameState.guilds.declare_war(GuildLibrary.START_OWNERS[4], GuildLibrary.START_OWNERS[5], 5)
	check(CutIns.is_playing(), "...and so does your guild declaring one")
	CutIns.skip_all()


func test_player_war() -> void:
	print("Your guild declares war")
	_fresh(16)
	CutIns.skip_all()
	var gs := GameState.guilds
	var pg := GuildLibrary.PLAYER_GUILD
	check(gs.player_war_refusal().contains("own guild") and not gs.player_declare_war(0), "you need your own guild")
	GameState.player.gold = 2000
	gs.found_guild("Iron Climbers")
	gs.treasury[pg] = 100
	check(gs.player_war_refusal().contains(str(GuildAI.WAR_COST)), "a war costs treasury gold")
	gs.treasury[pg] = GuildAI.WAR_COST + 50
	var targets := gs.player_war_targets()
	check(not targets.is_empty() and not targets.any(func(t): return gs.owners[t] == pg), "you can attack other guilds' floors")
	var t: int = targets[0]
	var defender: StringName = gs.owners[t]
	var rep := gs.rep_of(defender)
	check(gs.player_declare_war(t), "declare war")
	check(gs.war_between(pg, defender) and gs.war_of(pg).territory == t and gs.war_of(pg).attacker == pg,
		"your guild is the attacker over that territory")
	check(gs.treasury_of(pg) == 50 and gs.rep_of(defender) == rep - GuildState.PLAYER_WAR_REP_LOSS,
		"it costs the treasury and angers the defender")
	check(gs.player_side() == pg and gs.is_hostile(defender), "their guards come for you now")
	check(CutIns.is_playing(), "WAR DECLARED cut-in")
	CutIns.skip_all()
	check(gs.player_war_refusal().contains("already") and not gs.player_declare_war(targets[-1]), "one war at a time")


func test_system_notices() -> void:
	print("System notices")
	check(SystemNotice.split("Quest updated: Goblin Trouble — 2/5", "quest") == ["Quest Updated", "Goblin Trouble — 2/5"],
		"\"Label: text\" becomes a [ Label ] header")
	check(SystemNotice.split("Tower news: A war!", "guild")[0] == "Tower News", "tower news gets its own header")
	check(SystemNotice.split("You joined The Iron Oath as a Recruit.", "guild") == ["Guild", "You joined The Iron Oath as a Recruit."],
		"other messages use their category's header")
	check(SystemNotice.split("Odin, the Allfather punishes you: that's what you get", "blessing")[0] == "Blessing",
		"long sentences with a colon aren't mistaken for headers")
	var stack := SystemNotice.new()
	add_child(stack)
	for i in SystemNotice.MAX_SHOWN + 3:
		stack.push("New quest: Test %d" % i, "quest")
	check(stack.get_child_count() == SystemNotice.MAX_SHOWN, "only a few notices stack at once")
	stack.queue_free()


func test_action_sounds() -> void:
	print("Battle sounds")
	var fire := SkillDef.new()
	fire.elements = [Element.Type.FIRE] as Array[int]
	var crit := { "type": BattleAction.Type.SKILL, "skill": fire,
		"entries": [{ "kind": "damage", "crit": true, "amount": 10, "target": null }] }
	check(BattleSfx.names(crit) == ["hit_fire", "crit", "hit"], "a fire crit: fire hit sound, else crit, else hit")
	var heal := { "type": BattleAction.Type.SKILL, "skill": SkillDef.new(), "entries": [{ "kind": "heal", "amount": 5, "target": null }] }
	check(BattleSfx.names(heal) == ["heal"], "heals")
	var defend := { "type": BattleAction.Type.DEFEND, "skill": null, "entries": [] }
	check(BattleSfx.names(defend) == ["defend"], "defending")


func test_dialogue_portraits() -> void:
	print("Dialogue portraits")
	_fresh(5)
	_png(ART + "/portraits/merchant.png")
	Assets.roots = [Assets.ART_ROOT, ART]
	Assets.clear_cache()
	var r := DialogueRunner.new()
	r.start(&"merchant")
	check(r.raw_speaker() == "Merchant" and DialogueBox.portrait_for(r) == Assets.texture("portraits", "merchant"),
		"a speaker's portrait is found from their name")
	var none := DialogueRunner.new()
	none.start(&"waiting_companion", GameState.childhood_friend())
	check(none.portrait_id() == "", "lines can name a portrait but don't have to")


func test_credits() -> void:
	print("Credits and licenses")
	var data := Credits.load_data()
	check(Credits.validate(data).is_empty(), "credits.json is valid")
	var missing := Credits.uncredited_files(data)
	check(missing.is_empty(), "every art/audio file in assets/ is credited %s" % [missing])
	var bad := { "team": [], "assets": [{ "name": "Pack", "author": "A", "license": "CC-BY-NC-4.0", "url": "x",
		"kind": "art", "files": ["art/*"] }] }
	check(Credits.validate(bad).size() == 1 and Credits.validate(bad)[0].contains("allowed"),
		"non-commercial licenses are rejected")
	check(not Credits.validate({ "team": [], "assets": [{ "name": "Pack" }] }).is_empty(), "entries need author, license, url, files")
	_png(CREDITS_ROOT + "/art/enemies/goblin.png")
	_png(CREDITS_ROOT + "/art/enemies/slime.png")
	var partial := { "team": [], "assets": [{ "name": "Goblins", "author": "A", "license": "CC0", "url": "x",
		"kind": "art", "files": ["art/enemies/goblin*"] }] }
	check(Credits.uncredited_files(partial, CREDITS_ROOT) == ["art/enemies/slime.png"], "an uncredited file is caught")
	var text := Credits.text({ "team": [{ "role": "Design", "name": "Hayden" }], "assets": partial.assets }, "Tower Climber")
	check(text.contains("Hayden") and text.contains("Goblins by A"), "the credits list the team and the assets")
	check(text.contains("Permission is hereby granted") and text.contains("Godot"), "Godot's MIT license notice is included")
	check(text.contains("FreeType"), "...and the engine's third-party licenses")
