# Tower Climber (Godot 4.7)

Open `project.godot` in Godot 4.7.2 and press **F5**. The game scales to fit any window size or fullscreen. It opens on the **title screen**:

- **Continue:** pick one of the **3 save slots**. Each shows character, level, floor, play time and last save time.
- **New Game:** pick a slot (overwriting asks first), then a two-step, Pokémon-style setup. You name your climber, then your childhood friend (leave it blank or press **Use "Rowan"** for the default). You both start at level 1 on floor 1.
- **New Game+:** opens once someone has conquered the tower. Pick a character from the **Hall of Climbers**, then a save slot. The slot they conquered the tower in is suggested (★), but any slot works, and a popup always confirms which slot will be used and what gets replaced.
- **Delete:** every slot has a Delete button (with a confirmation) for a fresh start. Characters in the Hall of Climbers are never deleted this way.
- **Settings:** master, music and sound-effect volume, fullscreen and V-Sync. Saved to `user://settings.cfg`.
- **Quit**
- **Dev Sandbox** (bottom-right, debug builds only): the old test screen with level-10 companions and test fights. Its **floor picker** puts you on any floor (1–100) to test that floor's enemies, miniboss or boss, and shows what's there before you go. That floor becomes your checkpoint, so a wipe brings you straight back. The theme pickers next to it choose each stage's theme (e.g. Slime Pits, to test King Slime). Sandbox sessions never autosave over your real save.

In the tower: **WASD / arrows** move, **Tab** opens the party menu, **Esc** pauses (Resume / Save / Settings / Quit to Title). You can rename yourself or your friend anytime from **Tab → Rename**.

## Becoming a god (Hayden 2026-10-25)
- **Apotheosis:** conquering the tower makes your character divine. The completion screen offers the domains your ending suggests, you choose what you become (**god, demon or devil**; each domain suggests one) and name your title (gender-neutral defaults like "Deity of Valor", "Sovereign of Tyranny"). Once per character, saved in the Hall (`LegacyRecord.god_domain` / `god_title` / `god_kind`).

| Ending | Domains (reviewed with Hayden 2026-10-25) |
|---|---|
| Hero | Valor, Justice, Mercy |
| Villain | Tyranny, Greed, Ruin |
| Vigilante | Vengeance, Shadow, Freedom |
| The Wanderer | Twilight, Fate, Wanderlust, or any other domain |

- **Strict values:** every domain approves or forbids every guild action (trade, fortify, raid, war, ally), so the guilds you sponsor always earn or lose your favor. E.g. Mercy approves alliances, trade and fortifying and forbids war and raids; Greed forbids only alliances (it won't share the spoils).
- **A player-god's blessing** is a bit stronger than a mythology god's: buffs ×1.25 (`PLAYER_GOD_BUFF`), same curse.
- **Past gods join other runs:** every god in the Hall becomes a being (pantheon "Ascended") in every OTHER character's run: they take an interest by their domain's values, offer their blessing (buff + curse + the domain's skill) at shrines and after bosses, and are rivals of beings with opposite values. You never meet yourself in your own New Game+.
- **Climbing as a god (New Game+):** a god who climbs again gets **Tab → Divinity** (`DivinityState`, saved with the run; only if the Hall says you're a god).
  - **Faith** comes from tithes. All the faith you've ever earned sets your **divinity level** (150 / 400 / 900 / 1800), and each level (and each NG+ cycle past the first) gives another **contract** slot. Your own guild never needs one.
  - **Contracts:** pay faith (60, doubled if the guild's values clash with yours) and a guild takes **your god as its patron**: your values, your temper in its wars. Its old patron is **spurned**: less interested in you, and a rival of your god from then on.
  - **Boon + curse:** pick what you grant (Wealth, Bulwark, Warhost, Bargains, Devotion) and the curse that pays for it (Burden, Brittle, Gouging, Zealotry, Isolation). A curse must weigh at least the boon's cost. Both grow with the contract's level (favor grows each floor it serves you).
  - **Stance:** Aggressive, Defensive, Greedy or Devout leans the guild's AI each floor. A guild with any stance also **heeds your values**: it avoids what your domain forbids (resting a turn rather than doing it) and leans toward what it approves. Left to "its own way", it strays: a Ruin or Vengeance guild left alone gets punished about 3 times per 30 floors; with a stance, almost never.
  - **Tithes:** every floor each sponsored guild pays 3 faith per territory and a quarter of its territory income in gold.
  - Your own god is in your run's roster (so guilds can take you as patron) but never courts you. Every guild gets its own patron back in a new run.
  - **Your values judge your guilds:** a sponsored guild gains favor (+3) or loses it (-6) for what it does each floor: at -5 it's **warned**, at -15 you **punish** it automatically (-20% treasury, -1 defense) and it starts over.
  - **Smite** any guild (40 faith): -25% treasury, -1 defense, its wars swing against it; its patron takes offence. **Revoke** a contract: the guild returns to its old patron and feuds with you as a **renegade** for the rest of the run (sign it again to end the feud).
  - **Bless people** (40 faith): party and reserve members can take your domain's blessing (buff, curse and skill) at your divinity level, growing with it. Anyone whose values clash with your domain refuses.
  - **Miracles:** in battle the god has Miracle: Mend (party heal 30%), Wrath (huge holy hit) and Aegis (party ward), paid in **faith**, not MP (`SkillDef.faith_cost`).
  - **Champions:** on floors held by a guild you sponsor, its champion fights miniboss and boss fights beside you (a guest; never an Ironman loss).
  - **Other gods react by values:** like-minded gods warm to you once per run; rivals (opposite values, plus patrons you spurned) feud with your guilds, a jealous rival curses you for 5 floors whenever your divinity grows, and bosses sponsored by a rival have 15% more HP.
- `scripts/story/domain_library.gd` holds the domains, `scripts/story/divinity_state.gd` everything you do as a god (placeholder names, text and numbers; DLC can `register_domain`).

## Saving, the Hall of Climbers and New Game+
- **Autosave** happens when a run starts, on every floor, after every battle and at campfires. You can also save from the pause menu. Slots are `user://saves/slot_1.json` to `slot_3.json`.
- **Saves are plain JSON, on purpose.** Godot's `.tres` format can contain scripts that run when loaded, so a shared or tampered save could run code on someone's computer. JSON can only hold data, and everything read back is validated: unknown ids are dropped, numbers clamped, names cleaned. A broken file just shows as "Unreadable save". Saves are written to a temp file and then swapped in, so a crash mid-save can't corrupt the slot.
- **Completing the game** means beating the boss on `GameState.FINAL_FLOOR`, currently **30** (the design target is 100). The character is recorded in the **Hall of Climbers** (`user://hall_of_climbers.json`, kept across new games), and their save slot shows "conquered the tower" (it can't be continued, but New Game+ suggests it). Clearing again with the same character updates their record (times cleared, highest NG+ cycle, best time) instead of adding a duplicate.
- **What New Game+ keeps:**
  - Level, allocated stats, class and name.
  - **Unique gear only** (equipped, plus Uniques left in the bag or on companions), except gear marked `quest_reward`, which you'd earn again through its questline.
- **What New Game+ resets:**
  - All other gear, gold, consumables, tower progress and story flags.
  - Your childhood friend rejoins at level 1 with the same name.
  - Enemies are ×1.5 in NG+1, ×2.0 in NG+2, and so on (`NG_PLUS_SCALE_PER_CYCLE`).
- **Ascendant** is a New Game+ only class for the player character, deliberately stronger than any other class:
  - No stat requirement, and its bonus **grows with the tiers**: the best tier bonus there is + 10% (`ASCENDANT_EDGE`), so +30% while tier 3 is the top. It also gains **Ascendant's Will** when the tier-2 gate opens and **Ascendant's Dominion** at the tier-3 gate (`SkillLibrary.ASCENDANT_GATE_SKILLS`).
  - Three skills: **Judgment** (a huge single hit using your higher of Strength or Intelligence, ignoring rows), **Sanctuary** (heals the whole party) and **Heaven's Fall** (hits every enemy, also using your higher stat).
  - You take it from **Tab → ✦ Ascendant**. Gear locked to your old class goes back in the bag.

## What's here

| File | Role |
|---|---|
| `scripts/data/stats.gd` | The 6 stats (enum, names, tooltips). Base value 5. |
| `scripts/data/stat_block.gd` | Base vs allocated points, derived stats (HP, defenses, dodge, crit). Balance numbers at the top. |
| `scripts/data/class_def.gd` | A class definition: required stats + threshold. Has `tier`, `advances_from`, `is_secret` ready for later. |
| `scripts/autoload/class_registry.gd` | Autoload `ClassRegistry`. Registers the 5 tier-1 classes; also loads any `ClassDef` `.tres` in `res://data/classes/`. |
| `scripts/data/character_data.gd` | Level/XP, points per level (5 up to lv5, 3 after), allocation, class choice at lv10, respec rules. |
| `scripts/ui/stat_allocation_panel.gd` | Allocation UI with a pending pool + Confirm, so a misclick doesn't cost a respec. |
| `scripts/ui/class_selection_screen.gd` | Level-10 overlay that lists every class you qualify for, or how close you are to each one. |
| `scripts/debug/progression_sandbox.gd` | Dev Sandbox: test harness with buttons to gain XP, level up, respec, add gold and start test fights. |
| `tests/test_progression.gd` | 40 rule checks. Run: `godot --headless res://tests/test_progression.tscn` |
| `scripts/autoload/game_state.gd` | Autoload `GameState`. Holds the player, companions and the next encounter across scene changes. |
| `scripts/combat/skill_def.gd`, `skill_library.gd` | Every skill, and which class gets which skills and basic attack. |
| `scripts/combat/enemy_def.gd`, `enemy_library.gd` | Test enemies and encounter groups. |
| `scripts/combat/combatant.gd` | A unit in one battle (HP, MP, row, statuses). |
| `scripts/combat/damage_calc.gd` | All combat math and tuning constants. |
| `scripts/combat/battle_manager.gd` | Turn order, row rules, action resolution and rewards. Pure logic with no UI. |
| `scripts/combat/battle_ai.gd` | Enemy AI: heals if an ally is hurt, uses skills sometimes, respects Taunt. |
| `scripts/ui/battle/*` | Battle screen and unit cards. `scenes/battle.tscn` runs on its own with F6. |
| `tests/test_combat.gd` | 54 combat + HP carry-over + item checks. Run: `godot --headless res://tests/test_combat.tscn` |
| `scripts/items/*` | Item definitions (Potion, Advanced Potion, Ether, Goddess Tear), the shop list, and the party inventory. |
| `scripts/tower/floor_layout.gd` | Builds each floor from a seed (same seed always gives the same floor). Checks the stairs are always reachable. |
| `scripts/tower/tower_floor.gd` | The floor scene: grid movement, wandering and chasing enemies, touch-to-fight, stairs, campfire, HUD. |
| `scripts/ui/party_menu.gd` | Tab menu: HP/MP, use items, cast Heal, spend stat points, choose a class. |
| `scripts/ui/shop_panel.gd` | Rest-floor merchant. |
| `tests/test_tower.gd` | 21 floor checks. Run: `godot --headless res://tests/test_tower.tscn` |
| `scripts/items/rarity.gd` | Rarity tiers (Common → Unique), colours, and the Luck-scaled drop roll. |
| `scripts/items/gear_item.gd`, `loot_table.gd` | Gear pieces, base item types, stat budgets per rarity and floor, and the 5 class Uniques. |
| `scripts/ui/gear_panel.gd` | Equip and unequip gear (party menu → Gear). |
| `scripts/tower/stage_library.gd` | Stages: themes, miniboss floors, bosses and roaming bosses (random / story / secret). |
| `scripts/story/secret_paths.gd` | Secret-class questlines: clue flags, the final roaming boss, and the unlock. |
| `scripts/save/*` | `SaveSerializer` (validated JSON saves), `LegacyRecord` / `LegacyBook` (Hall of Climbers). |
| `scripts/ui/title_screen.gd`, `pause_menu.gd`, `settings_panel.gd` | Title screen, pause menu and settings. `scripts/autoload/settings.gd` stores and applies the settings. |
| `tests/test_save.gd` | 79 save/load (incl. tampered-file and 3-slot), Hall of Climbers, New Game+ and Ascendant checks. Uses separate test files, so your save is never touched. |
| `scripts/skills/*` | `SkillTier` (book tier odds) and `SkillBooks` (who drops which books, drop chances). Shared skills themselves are in `skill_library.gd`. |
| `scripts/ui/skills_panel.gd` | Tab → Skills: known skills and spending skill picks. |
| `tests/test_skills.gd` | 39 intent, shared skill, skill pick and skill book checks. |
| `scripts/story/dialogue_library.gd` | Every conversation as data: lines, choices, conditions and effects. The format is documented at the top. |
| `scripts/story/dialogue_runner.gd` | Plays a conversation (pure logic): checks conditions, runs effects, fills in `{player}` / `{friend}`. |
| `scripts/story/npc_library.gd` | NPCs and lore objects: which floors they appear on, recruit builds. |
| `scripts/ui/dialogue_box.gd` | The conversation box at the bottom of the screen. |
| `tests/test_dialogue.gd` | 69 dialogue, NPC placement, recruiting, reserve and clue checks. Run: `godot --headless res://tests/test_dialogue.tscn` |
| `scripts/ui/party_manage_panel.gd` | Tab → Manage party: order, rows, reserve, swapping and dismissing. |
| `tests/test_party.gd` | 58 party management checks: bench/swap, order, rows, caps, the miniboss/boss lock, dismiss/rejoin, reserve XP. Run: `godot --headless res://tests/test_party.tscn` |
| `scripts/combat/element.gd`, `enemy_families.gd` | Elements and weapon kinds, how reactions combine, and the enemy families (weaknesses, resistances, traits). |
| `scripts/data/bestiary.gd`, `scripts/ui/bestiary_panel.gd` | What you've learned about enemies, and Tab → Bestiary. |
| `tests/test_elements.gd` | 79 element, weakness, trait, stagger, bestiary, Scouting Lens, elemental weapon and stage theme checks. Run: `godot --headless res://tests/test_elements.tscn` |
| `scripts/story/quest_library.gd` | Every hand-written quest as data (format at the top, checked by the tests). |
| `scripts/story/quest_log.gd` | Your quests this run: progress, rewards, deadlines, notice-board bounties, saving. |
| `scripts/ui/quest_log_panel.gd`, `notice_board_panel.gd` | Tab → Quests and the rest-floor notice board. |
| `tests/test_quests.gd` | 68 quest checks: every goal type, rewards, expiry/failing, dialogue hooks, the board, saving. Run: `godot --headless res://tests/test_quests.tscn` |
| `scripts/story/route_library.gd`, `route_state.gd` | Routes, endings (with priorities) and this run's route points / lock. |
| `scripts/autoload/dlc_loader.gd` | Loads DLC packs and their `content.gd` at startup. |
| `scripts/ui/advancement_panel.gd` | Tab → ✦ Advance: requirements checklist, begin trial, advance. |
| `tests/test_classes.gd` | 52 advancement checks: the 10-class tree, tier 3, lineage, gate, trials, keeping skills, builds, route-only classes, Uniques, saving. Run: `godot --headless res://tests/test_classes.tscn` |
| `scripts/story/being_library.gd`, `blessing_state.gd` | Gods, demons and devils (their values, blessing levels, buffs + curses, bargains) and this run's interest / refusals / punishment. |
| `tests/test_blessings.gd` | 56 blessing checks: the roster and its sensitivity rule, rivalries, interest, offers, accepting, levels, buffs and curses in combat, warnings, punishment, bargains, shrines, boss visits, blessed NPCs, saving. Run: `godot --headless res://tests/test_blessings.tscn` |
| `scripts/economy/guild_library.gd`, `guild_state.gd` | The guilds (patrons, taxes, prices, members' stock, ranks) and this run's territories, standing, membership, treasuries and market. |
| `scripts/ui/guild_panel.gd` | Tab → Guilds. (The merchant's Buy/Sell tabs and guild shops are in `shop_panel.gd`.) |
| `tests/test_guilds.gd` | 63 guild and economy checks: territories, joining/leaving, ranks and perks, taxes, prices, pay, supply and demand, selling, guild jobs, agents, saving. Run: `godot --headless res://tests/test_guilds.tscn` |
| `scripts/economy/guild_ai.gd` | The guild AI: what each guild does every floor (trade, fortify, raid, ally, war). |
| `tests/test_guild_ai.gd` | 112 checks: the AI, raids, alliances, wars and fighting in them, guards and champions, stealing, pickpockets, heists, founding your guild, claiming floors, captains (posting, defense, fighting beside you, XP, capture, ransom and rescue), saving. Run: `godot --headless res://tests/test_guild_ai.tscn` |
| `tests/test_routes.gd` | 67 route checks: points, locks, hints, endings and DLC endings, companions warning/leaving, prices, the black market, route bounties and classes, the Hall, saving. Run: `godot --headless res://tests/test_routes.tscn` |
| `tests/test_loot.gd` | 80 loot, gear, stage, boss and roaming-boss checks. Run: `godot --headless res://tests/test_loot.tscn` |
| `scripts/ui/ui_theme.gd`, `ui_style.gd`, `themed_background.gd` | The system-window look (palettes picked in Settings). |
| `scripts/presentation/assets.gd` | Art hooks: finds `assets/art/<kind>/<id>.png`, else the placeholder stays. |
| `scripts/autoload/audio.gd`, `scripts/presentation/music_library.gd`, `battle_sfx.gd` | Autoload `Audio` (music crossfades, sound effects, variants) and which track or sound fits where. |
| `scripts/autoload/cut_ins.gd`, `scripts/presentation/cut_in_data.gd` | Autoload `CutIns` (full-screen splashes) and what each one shows. |
| `scripts/ui/system_notice.gd` | `[ Quest Updated ]`-style system notices on the floor HUD. |
| `scripts/presentation/credits.gd`, `scripts/ui/credits_panel.gd`, `assets/credits.json` | Credits and license tracking, and the credits screen. |
| `assets/README.md` | **The drop-in guide:** every art and sound file name the game looks for. |
| `tests/test_presentation.gd` | 77 checks: palettes, art and audio hooks, music choice, cut-ins, system notices, battle sounds, dialogue portraits, credits/licenses, your guild declaring war. Run: `godot --headless res://tests/test_presentation.tscn` |
| `tests/test_screens.gd` | 14 smoke checks that open the real floor, battle and title screens and drive the hooks on them (including a captain joining a fight, and the Ascend button). Run: `godot --headless res://tests/test_screens.tscn` |
| `scripts/data/difficulty.gd` | Difficulty modes (Relaxed / Normal / Hard / Hell). Ironman lives in `GameState`. |
| `tools/balance_sim.gd` | The balance simulator (dev tool): a bot plays whole runs, or measures the guild world. See "What the balance simulator says". |
| `tests/test_recruits.gd` | 33 checks: the roster data, campfire/hire/favor/rescue/captive meetings, wanderers, route refusals, loyalty quests and personal skills, saving. Run: `godot --headless res://tests/test_recruits.tscn` |
| `tests/test_stages.gd` | 19 checks: every theme's data, the 60-floor ladder and the non-repeating pseudo-god slots, boss patrons (blessing, sensitivity rule, interest), the new traits, signature books. Run: `godot --headless res://tests/test_stages.tscn` |
| `tests/test_divinity.gd` | 88 checks: domains, apotheosis, past gods as beings in other runs (offers, skill, rivals, never courting themselves), saves and tampered Hall records; climbing as a god: faith, levels, contracts, spurned patrons, boons/curses, stances, tithes, your own guild, saving and tampering; judging guilds, smite/revoke, blessing people, miracles, champions, rival gods. Run: `godot --headless res://tests/test_divinity.tscn` |
| `tests/test_demigods.gd` | 39 checks: demigod classes and recruits, pantheon omens, the legend chain, summons, Fury, NG+ Ascension, the Ascendant's gate skills, saving and tampering. Run: `godot --headless res://tests/test_demigods.tscn` |
| `tests/test_difficulty.gd` | 45 checks: difficulty choice and lowering, battle multipliers, Hell extras, wipes, Ironman deaths and the fallen, Hall records, patron temper and feuds, scaling rules. Run: `godot --headless res://tests/test_difficulty.tscn` |

## Dialogue, NPCs and recruiting
- **Walk into** an NPC (coloured square with an initial), a lore object (diamond with **?**) or the merchant to talk. Choices are buttons; Enter/Space picks, and Esc works as "Next".
- **Conversations are data** in `dialogue_library.gd`. Each line can have choices, and both lines and choices can have:
  - **Conditions** (hide a choice or pick a different opening): story flags, floor range, player level, gold, an item, NG+ or not, being on a secret path, having recruited someone.
  - **Effects:** set/clear flags, give items or gold, take gold, recruit, heal the party, open the shop, show a message.
  - `{player}` and `{friend}` in any text become the current names, so the childhood friend can join in.
- **A typo can't sneak in:** the dialogue tests check every conversation for missing lines, misspelled conditions/effects and unknown items or NPCs.
- **NPCs and lore objects** are set up in `npc_library.gd`: which kinds of floor they can be on (rest, cleared boss, combat, miniboss), the floor range, a chance per floor, extra conditions, a flag that makes them disappear for good, and whether they stand by the campfire. Placement uses the floor's seed, so they're in the same spot when you come back, and never cut off part of the floor.
- **The merchant** now greets you first: **Let's trade** opens the shop. From floor 10 they also have a story to tell (an Ashbound clue).
- **Recruiting:** recruitable NPCs join at **your level − 1** (min 1), with their points spent by their build and their class taken if they're level 10+. They join the party if there's room, then the reserve, and if both are full they wait by the campfire on rest floors (see Party management). Recruits leave the floor, are saved, and reset in New Game+ like other story progress. Uniques on reserve or waiting members still carry into New Game+.
- **A hint before the class choice** (Hayden 2026-10-25): a **burnt sword** on normal floors 2–9 (50%) hints that a hidden class favours Strength and Intelligence, so players can plan their build before level 10. It isn't one of the 3 clues.
- **The Ashbound clues** all come from this system now: the **scorched mural** (40% of normal floors 11–29), the **merchant's story** (floor 10+) and the **glint in the embers** (by the campfire on rest floors and cleared boss floors from floor 10).
- **Placeholder content only:** the merchant, lore objects and the recruit roster below. Real story content comes later.

### The recruit roster (Hayden 2026-10-25)
Twelve recruits across the 60 floors. Their names follow each one's origin (the god who blessed them). All their text is placeholder.

| Recruit | Class | How you meet them | Blessed by | Likes / dislikes |
|---|---|---|---|---|
| Brakka | Tank | campfire, rest floors 5+ | Thor | Hero / Villain |
| Tamsin | Archer | **rescue** fight, floors 2–6 | | Vigilante / Villain |
| Daphne | Support | **favor** quest, rest floors 5+ | Athena | Hero / Villain |
| Garrick | Rogue | **hire** 600g, rest floors 15+ | | Villain / Hero |
| Rook | Archer | **favor** quest, rest floors 20+ | | Vigilante / Hero |
| Sigrun | Tank | **captive** of Moonfang (Loki's) | Odin | Hero / Villain |
| Neferet | Mage | **captive** of the Hive Queen (Apep's) | Ra | Hero / Villain |
| Lysander | Support | **captive** of the Necromancer (Hades') | Zeus | Hero / Vigilante |
| Shamira | Rogue | **captive** of the Dragon Sovereign (Tiamat's) | Ishtar | Vigilante / Hero |
| Old Fenn | Tank | campfire, rest floors 25+ (*wanderer*) | | Vigilante / Villain |
| Kael | Rogue | **rescue** fight, floors 30–38 (*wanderer*) | | Villain / Hero |
| Vesna | Mage | **hire** 1500g, rest floors 35+ (*wanderer*) | | Villain / Hero |

- **Ways to meet them** (`NpcLibrary` "recruit" → `"meet"`):
  - **campfire:** talk and they join.
  - **hire:** a one-time fee. Hayden may switch this to a wage later.
  - **favor:** do their small quest first, then they join.
  - **rescue:** on their floors, a group of enemies has someone cornered (green pulsing ring, **+**). They fight beside you and join if you win.
  - **captive:** a boss sponsored by a **rival** of their god keeps them locked up, and the boss's cut-in says so. Beat it to free them. Captives only exist in runs where their captor's stage rolls.
- **Shared conversations:** `recruit_campfire`, `recruit_hire` and `recruit_favor` cover everyone, filled in with `{recruit}` / `{recruit_pitch}` / `{recruit_fee}`. A new recruit is just data.
- **Wanderers** (`"run_chance"`) are only in about half of runs. The roll is fixed per run.
- **Values:** every recruit likes and dislikes routes. They refuse to join someone on a route they dislike, and they warn and leave like other companions.
- **Loyalty quests:** joining starts their loyalty quest, themed on their backstory. Finishing it unlocks their **personal skill** (Thunder Charge, Hunter's Mark, Saint's Hymn, Dirty Work, Rain of Thorns, Valkyrie's Shield, Solar Flare, Thunder Oath, Lion's Grace, Stand Firm, Shadowstep, Frost Nova). Personal skills never come from books, and they can be ranked up. The favor and loyalty quests are generated from the recruit data (`QuestLibrary.recruit_quests`).
- **Demigods** (Hayden 2026-10-25; "I will probably want to add more later"): rare legends with a class only they can have (`ClassDef.unique_to`).
  - They appear by a rest-floor campfire on floors **30+**, in about a third of runs (`run_chance` 0.35), and **only if one of your patrons** (your blessing or your own guild's patron) **is from their pantheon** (dialogue condition `patron_pantheon`).
  - Meet type **legend**: an omen, then a legendary quest chain (`recruit_legend`: defeat 2 minibosses, then a stage boss) before they join.
  - Their class is tier-2 strength + 5% (`DEMIGOD_EDGE`) from the moment they join, and it advances to its own tier-3 form at the usual gate. Always below the Ascendant. A save that gives anyone else a demigod's class is corrected on load.

| Demigod | Pantheon | Class → tier 3 | Personal skill | Blessed by |
|---|---|---|---|---|
| Heracles | Greek | Lionheart → Olympian Hero | Nemean Roar | Zeus |
| Perseus | Greek | Gorgonbane → Starborn Hero | Winged Sandals | Athena |
| Achilles | Greek | Myrmidon Lord → The Invulnerable | Heel Guard | |
| Gilgamesh | Mesopotamian | King of Uruk → Two-Thirds Divine | Gate of Uruk | |
| Cú Chulainn | Celtic | Hound of Ulster → Riastrad | Spear Storm | The Morrigan |
| Sigurd | Norse | Dragonslayer → Fafnirsbane | Birdspeech | Odin |

- **Solo runs** already work. You can bench or dismiss anyone, including your childhood friend, from floor 1 (just not on a floor whose miniboss or boss is still alive). Enemy groups shrink to your party's size.

## Party management
Open it with **Tab → Manage party**.
- **The party grows as you climb** (Hayden 2026-10-25): **2** fight on floors 1–20 (you and your childhood friend), then 2 more every 20 floors: **4** from floor 21, **6** from 41, **8** from 61 and **10** from 81 (`GameState.party_size()`, `PARTY_START_SIZE` / `PARTY_GROWTH` / `PARTY_GROWTH_FLOORS`, `MAX_PARTY_SIZE` 10). It follows the highest floor reached, so a wipe back to a checkpoint never shrinks it. When it grows, the reserve fills the new places in bench order and a notice says so. Early recruits wait on the reserve until then (still earning 50% XP).
- **Bosses scale with it:** bosses, minibosses and roamers fight the whole party alone, so their HP follows the party slots: ×0.59 for 2, ×1 for 4, ×1.36 for 6, ×2 for 10 (`GameState.guardian_hp_mult`, `GUARDIAN_PARTY_EXP` 0.75). It uses the slots, not who's fighting, so a solo run still faces the full boss.
- **Big parties fit the screen:** the battle field wraps and shrinks (10 vs 10 is tested at 1280×720), the turn order shows the next 8 then "+N", the floor's party strip wraps upward, and the Tab member list scrolls.
- You always lead. Use **▲ / ▼** to change the order, which is the order in battle and on the HUD. **Front / Back** sets the row each member starts battles in.
- **The reserve** (the bench) holds up to **6** (`RESERVE_CAP`). Benched members don't fight but get **50%** of each battle's XP (`RESERVE_XP_SHARE`), shown on the victory screen. **Bench** sends a party member there, **Join party** brings someone back if there's a free slot, and **Swap in…** trades places with a party member you pick.
- **Dismiss** (with a confirm) is never permanent. Their gear goes to your bag, and they wait by the campfire on **rest floors and cleared boss floors**, exactly as they left. Talk to them there to bring them back (party if there's room, else the reserve). Recruits who join when the party and reserve are both full wait there too. The Manage party screen lists who's waiting.
- **The childhood friend** can be benched or dismissed like anyone else.
- **Plan ahead: the party locks on miniboss and boss floors.** While a floor's miniboss or boss is standing, you can't bench, swap, dismiss or bring anyone back. You can still change the order and rows. Walking onto stairs that lead to a miniboss or boss floor asks first: **Climb**, or **Check party first** (opens Manage party).

## Enemy intent, shared skills and skill books
- **Enemy intent:** at the start of each round, every enemy decides its move. Its card shows it (e.g. "Smash → Cassia" or "Volley → everyone"), and targeted allies get a red **⚠ Targeted** marker (x2 if two enemies are aiming at them). React with Defend, Guard, Ward, heals or a row change. If the target falls, or someone starts **taunting**, the intent re-plans and the markers update. An enemy can hide its intent (`hide_intent`, shown as "Intent: ???"); none do yet.
- **Shared skills:** anyone can learn these, whatever their class (or with no class). They're kept when you change class and carried into New Game+.
  - **Skill picks:** everyone starts with **1** (a starting skill) and gets another at levels **3, 6, 9, 12…**. Spend them in **Tab → Skills**.
    - **Picks fit the class fantasy:** each class line has its own pool of Common skills (`SkillLibrary.CLASS_PICK_POOLS`; advanced classes use their line's pool).
      - Before a class (levels 1–9): First Aid, Power Strike, Guard and Ember.
      - Tank: Power Strike, Guard, First Aid, Focus, Quick Step.
      - Mage: all six elemental bolts and Focus.
      - Archer, Rogue and Support each get their own mix.
      - The NG+ Ascendant can pick anything.
      - Skills picked before your class stay with you.
    - **Skill books still teach anyone anything.** They're the rare way to break the mold.
    - **Rank up:** a pick can instead rank up any skill you know, up to rank **III**. Each rank adds **+15% power** (and heal %) and takes **10% off** the MP cost (`MAX_SKILL_RANK`, `RANK_POWER`, `RANK_MP`). Blessed skills can't be ranked.
  - **Guard** takes single-target hits aimed at an ally (30% less) until your next turn. **Focus** restores 25% MP. **First Aid** heals 15% of max HP plus a little. **Quick Step** makes acting first much more likely next round.
- **Skill books** teach any shared skill, including Rare, Epic, Legendary and Unique ones, only through books. Use them from **Tab → Items**. They can't be read mid-battle, and a book isn't used up on someone who already knows the skill.
  - **Who drops what:** monsters drop books that fit them, including skills they actually use (an Orc Brute can drop Smash). Each enemy's list is in `scripts/skills/skill_books.gd`.
  - **Drop chance:** normal 4%, miniboss 30%, boss and roaming boss 75%.
  - **Tier odds** use the party's highest Luck, stepping up at every multiple of 10:

| Luck | Common | Rare | Epic | Legendary | Unique |
|---|---|---|---|---|---|
| 0–9 | 60% | 30% | 8% | 1.5% | 0.5% |
| 10–19 | 57.5 | 28.75 | 11 | 1.88 | 0.88 |
| 20–29 | 55 | 27.5 | 14 | 2.25 | 1.25 |
| 30–39 | 52.5 | 26.25 | 17 | 2.63 | 1.63 |
| 40–49 | 50 | 25 | 20 | 3 | 2 |
| 100+ (cap) | 35 | 17.5 | 38 | 5.25 | 4.25 |

  - **If an enemy has no book of the rolled tier,** it steps down to the next tier it does have. A slime only ever drops Common books, but the Goblin King can drop its Unique **King's Decree**.

## Combat rules (FF-style menus, four rows)
- **Four rows a side** (Hayden 2026-10-25): **Front, Middle, Rear, Back** (`Combatant.Row`). Enemies use them too: skirmishers (cutthroats, wolves, hellhounds...) in the Middle, archers in the Rear, casters in the Back.
- **Melee is layered:** a single-target melee attack only reaches the **nearest row that still has someone standing**. Middle is safe while the Front stands, Rear while Front and Middle stand, and so on. Backstab and other row-ignoring skills are the exception.
- **Melee from further back** hits softer: 100% / 90% / 70% / 50% from Front / Middle / Rear / Back (`DamageCalc.MELEE_ROW_MULT`; Middle was 75% at first, softened so the Middle-row classes aren't punished for standing where they're recommended).
- **Recommended rows** (never a lock): every class has one (`SkillLibrary.CLASS_ROWS`, inherited along the line). Front: tanks, warriors, magic swordsmen. Middle: rogues, monks, spellblades, Ashbound. Rear: archers, summoners. Back: mages, supports. New members and newly chosen classes start there. Manage party has a row picker with the recommended row starred (tinted when someone stands elsewhere), and the class and advancement screens name it.
- **The battle screen** is laid out like a classic FF battle: a flat battlefield with four lanes a side (enemies on the left), and a **menu window** along the bottom with the commands, the skill / item / row list (or the battle log), and the party's HP / MP / row (two columns once 6+ fight; rows are clickable targets for heals and items). **Row** opens a list of the four rows.
- Old saves are converted (a character saved in the old Back row is still in the Back row).
- **Ranged and magic** ignore rows. Magic can't be dodged; physical attacks can.
- **Turn order** is rolled each round: Agility × a random 0.75–1.25.
- **Commands:** Attack, Skills, Defend (halves damage until your next turn), Row (pick any of the four; saved on the character), Flee (chance based on average Agility).
- **Victory:** every surviving party member gets the full XP, and the leader gets the gold.
- **Commands** also include **Items** (Potion, Advanced Potion, Ether).

## Quests
- **Where they come from:** people (dialogue), the **notice board** on rest floors, things you find (lore objects), and the **main questline**, which starts by itself.
- **Goals** (`scripts/story/quest_library.gd`): **defeat** enemies (a specific enemy, a family, or any boss/miniboss/roaming boss), **collect** items, **reach** a floor, and **flag** steps for talking to someone or finding something (the dialogue or lore object sets the flag). Steps happen in order.
- **Rewards:** gold, XP (whole fighting party), items, **quest gear** (marked `quest_reward`, so it never carries into New Game+), story flags (unlocks), and **bestiary notes** that reveal a whole family.
- **Deadlines and failing:** a quest can expire after a floor (`expires_after_floor`), and a dialogue choice can fail it (`fail_quest`). Failed quests stay in the log and can set a flag (`on_fail_flag`) that opens something else.
- **Quest items** (e.g. Glowcaps) drop only while a quest needs them, stop dropping once you have enough, and can't be used like normal items. They're listed in Tab → Quests.
- **Notice board** (rest floors, a wooden panel marked **!** when there's something new): hand-written jobs (`"board": true`) plus **3 generated bounties** for the stage ahead. The first bounty is for the stage's family, the other two for different enemies. A board offers the same jobs if you come back. Take as many as you like.
- **Tracking:** **Tab → Quests** lists active, completed and failed quests with each step and its progress. **Pin** one to show its current step in the top-right corner of the floor HUD. Quest news ("Quest updated: Defeat slimes (3/8)") pops up under the normal messages.
- **Dialogue hooks:** conditions `quest_new`, `quest_active`, `quest_on_step`, `quest_done`, `quest_failed`, and effects `start_quest`, `fail_quest` and `take_item` (for hand-ins).
- **Placeholder quests:**
  - **The Climb** (main): beat the floor-10 boss, reach 11, beat the floor-20 boss.
  - **Glowcaps for the Merchant**: collect 3 from slimes, then hand them in, before floor 15.
  - **The Torn Map**: a map on floors 2–9 leads to a hidden cache from floor 6, which pays out a Cartographer's Charm.
  - **Slime Survey** (board, floor 5+): defeat 8 slimes, and the reward reveals all slime weaknesses.
- Bounty pay (`QuestLog.BOUNTY_*`): 10 gold + 2 per floor and 15 XP + 2 per floor, per enemy asked for. The balance pass can tune it.

## Guilds and the economy
- **10 guilds run the tower** (`scripts/economy/guild_library.gd`). Floors are split into **territories of 3 floors** (`TERRITORY_FLOORS`): floors 1–3 belong to one guild, 4–6 to the next, and so on, repeating past the last. The HUD shows whose territory you're in.
- **Every guild is signed with a patron** from the blessing roster, and the patron shapes it: the guild's values are the patron's (which routes it welcomes), rival patrons make **rival guilds**, and its tax and prices fit the patron (Mammon's Golden Ledger: 20% tax, +15% prices; Athena's Order of the Aegis: 5%, normal prices). Each guild also has personality numbers (greed, aggression, honor) waiting for the phase-3 guild AI.

| Floors | Guild | Patron | Tax | Prices |
|---|---|---|---|---|
| 1–3 | Order of the Aegis | Athena | 5% | ×1.00 |
| 4–6 | Sunspear Caravan | Ra | 8% | ×1.00 |
| 7–9 | Flower-Fruit Mountain Crew | Sun Wukong | 5% | ×0.95 |
| 10–12 | The Golden Ledger | Mammon | 20% | ×1.15 |
| 13–15 | Stormhammer Company | Thor | 10% | ×0.95 |
| 16–18 | Ninefold Lantern | Tamamo-no-Mae | 15% | ×1.10 |
| 19–21 | Brotherhood of the Jade Oath | Guan Yu | 10% | ×0.90 |
| 22–24 | Ravenwatch | The Morrigan | 10% | ×1.00 |
| 25–27 | Underworld Exchange | Hades | 12% | ×1.05 |
| 28–30 | The Serpent Coil | Apep | 25% | ×1.20 |

- **Taxes:** the floor's guild takes its cut of the gold you win in battle there (shown on the victory screen), and it goes into the guild's **treasury**.
- **Guild agents** stand on the first floor of each territory and on rest floors. Talk to one to:
  - learn about the guild (patron, floors, tax)
  - **join** (one guild at a time; it won't take you if its patron hates your route)
  - shop its **members' stock**
  - collect your **pay**
  - **leave**, which costs 25 standing
  Joining also costs 10 standing with its rival guilds.
- **Standing and ranks:** your standing with every guild runs from −100 to 100 (Hated → Honored). Members rank up: **Recruit → Member (25) → Officer (50) → Master (80)**. Ranks give:
  - lower tax on the guild's floors (Masters pay none)
  - a discount at its merchants (up to 20%)
  - more members' stock
  - **patron favor:** each promotion raises the patron's interest in you
  - **pay:** Officers and Masters take 3% / 6% of the treasury every 5 floors
- **Guild jobs:** notice-board bounties are posted by the guild that runs that rest floor, and pay **+5 standing** with it.
- **Selling:** the merchant (and other traders) have a **Sell** tab:
  - gear sells by rarity and item level
  - consumables sell for half their price, skill books for a flat amount
  - Uniques, quest items and equipped gear can't be sold
- **Supply and demand, per territory:** buying an item raises its price there, and selling lowers what traders pay. Prices drift back toward normal every floor you climb (`GuildState.BUY_PRESSURE / SELL_PRESSURE / MARKET_DECAY`).
- **Tab → Guilds** shows every guild, its patron, floors, tax, prices and your standing.
- Saved with the run, reset in New Game+. DLC can add guilds with `GuildLibrary.register_guild()`.

### The guild AI, wars and theft
- **The guilds think for themselves** (`scripts/economy/guild_ai.gd`; a local simulation, no online AI). Every floor you climb, every guild earns **60 gold per territory**, then (40% of the time) takes one action picked from its personality (greed, aggression, honor) and situation. Quiet trade is the usual pick; with no patron something makes the news about every 2 floors, and there are about 1.4 wars per 10 floors. The options:
  - **trade** (safe income)
  - **fortify** (defense, more likely when threatened)
  - **raid** another treasury (greedy guilds, rivals first; yours too)
  - **ally** (honorable guilds whose patrons share values)
  - **declare war** on a neighbor or rival for one of its territories (aggressive guilds)
  It's seeded per run and floor, so a run replays the same way.
- **Your patrons steer the wars around you** (Hayden's design). Your patrons are the being who blessed you and your own guild's patron. Every being has a **temper** from calm to warlike (`BeingLibrary.TEMPER`: Inari 0.1, Anubis 0.15, Athena 0.35, Loki 0.85, Typhon and Tiamat 0.95; 0.5 with no patron).
  - A warlike patron pulls the guild you're in toward war; a calm one keeps attackers away from your floors.
  - **Feuds:** guilds whose patron is a **rival** of yours want war with your side above all else. For example, Ra's blessing puts Apep's Serpent Coil at your throat. Feud wars **never end in a truce**: they're fought until someone wins.
  - A **newly founded guild** next door is a tempting target, so your own guild is attacked about once every 10 floors with no patron.
  - Measured with `tools/balance_sim.tscn -- guilds`.
- **Tower News:** everything goes in the news (Tab → Guilds shows the latest), big events (wars, territory changes, raids on your guild) pop up as toasts, and the merchant passes on rumors ("Heard any news?").
- **Wars** are simulated every floor. Strength comes from treasury, territories, aggression, defenses and allies. At **+6** the attacker takes the territory, at **−6** the defender holds, and after 8 floors it's a truce. Prices in a contested territory are **20% higher** while it lasts.
- **Fighting in a war:** if your guild is at war, or you've **hired on as a mercenary** with a warring guild's agent ("Need a sword in your war?"), the enemy's **guards** hunt you on the contested floors. Every guard group you beat swings the war **1.5** your way, and a champion swings it **4**. Mercenaries earn **40 gold per fight**, and the contract ends with the war.
- **Guards** (Guild Guard, Archer, Mage; blue ring, **G**) replace normal enemies on a guild's floors while it's hostile to you. That happens if you're Hated (−50), were caught stealing (5 floors), or are at war with your side. Beating guards costs standing with that guild.
- **Champions** (white ring, **C**; 900 HP, can be fled) hold a territory's first floor when you can challenge it: when you have your own guild, or that guild is hostile to you. Beat one to swing a war, or **claim the territory** for your guild. It costs 20 standing, and the champion returns after 10 floors.
- **Stealing:** traders have a **Steal (x%)** button, one try per floor. The odds come from Agility + Luck (25% + 0.5% per point, up to 75%). Success means a free item and 2 villain points. Getting caught costs 15 standing, and the floor's guild hunts you for 5 floors.
- **Pickpockets:** after a won battle on a **hostile or greedy** guild's floors, a pickpocket may lift 10% of your gold or an item. Members of that floor's guild (Member rank and up) are left alone.
- **Heists:** at Member rank or higher, your guild's agent may send you to rob a rival or war enemy ("Any special jobs for me?"). Talk to one of the target's agents to try it. Success splits 15% of their treasury between you and your guild. Get caught, and they hunt you.

### Your own guild
- **Founding:** once you've passed **floor 15**, Tab → Guilds → **Found a guild** for **2000 gold**. You don't have to leave your guild first; founding moves you out of it, which takes the usual standing hit. Name your guild and sign with a **patron**: your blessing's being is first in line, or any being that isn't against you, or none.
- **You're its Master.** Your companions (party, reserve, waiting) are its members.
- **Claim floors** by beating territory champions. Your floors pay into your treasury every floor: base + tax + 5 per member. Their merchants charge your prices, and other guilds may go to war to take them back.
- **The guild hall** (Tab → Guilds):
  - **withdraw** gold from the treasury
  - set your **tax** (0–30%; higher means more income)
  - buy **upgrades** (500 / 1000 / 1500 gold from the treasury): **Vault** (raids take less), **Barracks** (stronger in wars), **Armory** (better prices)
  - **declare war** (600 gold from the treasury, one war at a time) on another guild's territory. Beat its guards and champion to take it. The defender's standing drops by 30.
  - **Captains...**: post a **reserve or waiting** companion on one of your territories (one per territory, recall any time). A captain:
    - **defends** it: adds level x 0.1 to your side when that territory is attacked, and every captain cuts raid odds on your treasury by 4%
    - **fights beside you** on its floors, as an extra party member (not in stage boss or miniboss fights; `CAPTAIN_HELPS_GUARDIANS`)
    - **levels up** while posted (50% of battle XP, plus 150 XP for holding a war) and rests to full every floor
    - brings in **+15 income** per floor, and that territory's merchant gives **5% off**
- **When a guild attacks your territory** you're told (and get the war cut-in). Its guards patrol your floors and its **war leader** waits on the territory's first floor. Beat them to swing the war, with your captain fighting beside you.
- **If the territory falls, its captain is captured.** A **rescue quest** starts. Free them by beating any of the captor's champions, or pay the **ransom** (200 + 25 per level) to one of its agents. A captor left with no territory can't hold anyone, so the captain escapes home.
- Tunables: top of `guild_ai.gd` and `guild_state.gd` (wars, theft, champions, charter, income, upgrades).

## Look, art and sound

The game has no art or audio files yet. Everything that would show a picture
or play a sound looks for a file first and keeps its placeholder if there
isn't one. **`assets/README.md`** lists every file name.

- **System-window UI:** dark panels with a glowing border, built in code
  (`UITheme`). Settings → **Interface style** offers System Blue (default),
  Royal Gold, Crimson Pact, Abyssal Violet, Jade Sect and Monochrome. The
  palette is merged into Godot's fallback theme, so every control picks it up,
  including the ones under the floor HUD's CanvasLayer.
- **System notices:** quest, path, blessing and guild news appear as stacked
  `[ Header ]` windows with a chime (`system_<kind>`, else `system`).
- **Cut-ins** (Settings → Cut-in splashes; click or press a key to skip):
  - boss, miniboss, roaming boss and champion fights; the fight waits for the card
  - ultimate skills (Legendary or Unique tier, or a blessed skill) used by the party
  - a god, demon or devil appearing
  - LEVEL UP after a fight, and choosing or advancing a class
  - a war declared by or on your guild (your own or the one you're in)
- **Music** changes with the stage, the enemies and the kind of fight, with
  crossfades. Missing tracks fall back step by step to the generic ones, and
  numbered files (`_2`, `_3`) add variety.
- **Sound effects** for every button, battle results (element-specific hits
  first), shop, stairs and campfire.
- **Credits** (title screen → Credits): the team and every asset from
  `assets/credits.json`, then Godot's MIT license and the engine's
  third-party licenses. The tests fail if an asset file isn't credited or its
  license doesn't allow commercial use.

## Blessings (gods, demons and devils)
- **Many beings watch the climb** (`scripts/story/being_library.gd`). Each has **values** (routes it likes and dislikes), and its **interest** in you is your points in routes it likes minus routes it dislikes. Dialogue choices can also please or anger one directly (an `interest` effect). Accepting a blessing is always your choice.
- **26 beings from world mythologies** (placeholder numbers and lines; all of these are public-domain figures):

| Pantheon | Gods | Demons | Devils (bargains) |
|---|---|---|---|
| Norse | Odin, Thor | Hel | Loki (350 gold) |
| Greek | Zeus, Athena, Hades | Typhon | — |
| Egyptian | Ra, Anubis | Set, Apep | — |
| Chinese | Guan Yu, Sun Wukong, Yama | — | Baigujing, the White Bone Demon (300 gold) |
| Japanese | Amaterasu, Susanoo, Inari | Shuten-doji (oni king) | Tamamo-no-Mae (500 gold) |
| Mesopotamian | Ishtar | Tiamat | — |
| Celtic | — | — | The Morrigan (a promise: the Oath of Vengeance quest) |
| Infernal (Abrahamic tradition / legend) | — | Mammon | Mephistopheles (400 gold) |

- Each being has **likes/dislikes** (routes), a **blessed skill** (Mjolnir, Gungnir, Sun Disk, Kusanagi, Ruyi Staff...), and a level-1 **buff and curse** that scale ×2 and ×3 at levels 2 and 3 (`BeingLibrary.LEVEL_SCALE`). Some curses add something new at level 3. All of it is in `being_library.gd` (`SPECS`), so it's easy to tune.
- **Sensitivity rule** (for the commercial release, may change later): figures from **living religions** (Shinto kami, Chinese folk/Buddhist/Taoist figures) are marked `living` and are **only ever gods**, with dignified costs. Demon and devil roles go to figures who are monsters, tricksters or villains in their own myths. The tests enforce this. **Hindu deities are left out** of the first roster on purpose: that's Hayden's call for later.
- **Rivalries:** beings can be rivals (Odin & Thor vs Loki, Zeus vs Typhon & Hades, Ra vs Apep, Anubis vs Set, Amaterasu vs Susanoo, Sun Wukong vs Baigujing, Ishtar vs Tiamat). Rivalry counts both ways.
  - While you're blessed by a rival, a being loses **15 interest** (`RIVAL_PENALTY`).
  - If a rival **also wanted you** when you accept, it **curses you out of spite** for 5 floors.
- **Shrines:** at most **3** per rest floor, for the most interested beings (`MAX_SHRINES`).

- **Offers** come once a being's interest reaches **10** (`BlessingState.OFFER_INTEREST`), in three ways:
  - **shrines** on rest floors (gold = god, red = demon, violet = devil)
  - a **visit after a stage boss**
  - **bargains:** devils ask for gold or a promise (a quest)
  The offer shows exactly what you get and what it costs. Refuse, and that being waits 5 floors before asking again.
- **Blessings grow:** level 2 at 25 interest and level 3 at 45. The **buff and the curse grow together**. Accepting another being's offer replaces your blessing.
- **Equal punishment:** act against a being's values and it warns you once its interest drops to 0. At −10 it **punishes** you:
  - the blessing is taken
  - the whole party loses 30% of its current HP
  - the being's curse stays on you for **5 floors** without the buff
  - that being never offers again (other beings still can)
- **Effects** a blessing or curse can have: per-stat % (`stats`), more damage with an element (`element_power`), how you take hits (`affinities`, e.g. weak to Dark), `gold_mult`, `xp_mult`, `price_mult`, and `regen_pct` (heal after each won battle). The party is **never staggered**, so a cursed weakness costs damage, not turns.
- **NPCs can be blessed too** (`"blessing": [being, level]` in `npc_library.gd`). Brakka follows Thor. The Tab menu shows each character's blessing or curse (hover for details).
- Blessings and curses reset in New Game+. DLC can add beings with `BeingLibrary.register_being()`.

## Class advancement (tier 2+)
- **When:** each tier has a **gate** in `ClassRegistry.ADVANCEMENT_GATES`. Tier 2: **beat floor 20** + **level 25**. Tier 3: **beat floor 40** + **level 45** (Hayden: may change). Once both are met, an **✦ Advance** button appears on that character in the Tab menu. More tiers (e.g. 4 at 60, 5 at 80) are just a gate plus their classes; the design is 3–5 advancements over the full 100-floor climb.
- **Each advancement also needs:** its **stat build** (a share of allocated points, like tier 1), its **route** if it's route-only, and its **trial quest**. Trials are placeholders: defeat 20 enemies, then a miniboss. Begin one from the Advance panel, and once it's done anyone who qualifies can take that class. The panel shows every requirement as ✔ / ✘.
- **What you get:** you **keep every skill** (tier-1 class skills and learned ones) and gain the new class's skills (2 at tier 2, a capstone at tier 3), plus a bonus to every stat: **+10% at tier 2, +20% at tier 3** (`ClassRegistry.TIER_STAT_BONUS`; the Ascendant always stays above). Your basic attack, default row and your class's **Unique weapon** carry over. Unique drops treat you as your tier-1 class.
- **The tree** (placeholder names, in `class_registry.gd` and skills in `skill_library.gd`):

| Tier 1 | Advancement | Advancement | Route-only |
|---|---|---|---|
| Tank | Bastion (HP+STA): Bulwark, Iron Will | Juggernaut (STR+HP): Crushing Blow, Rampage | Paladin (Hero, HP+INT): Holy Strike, Lay on Hands |
| Mage | Pyromancer (INT): Magma Burst (Fire+Earth), Inferno | Stormcaller (INT+AGI): Chain Lightning, Tempest (Wind+Lightning) | Warlock (Villain, INT+HP): Hex Bolt, Doom Wave |
| Archer | Sharpshooter (AGI+LUCK): Deadeye, Armor Breaker | Ranger (AGI+STR): Gale Arrows, Wind Step | — |
| Rogue | Assassin (AGI+STR): Shadow Strike, Vanish | Trickster (LUCK+AGI): Lucky Strike, Smoke Screen | Executioner (Vigilante, STR+AGI): Execute, Grim Resolve |
| Support | Cleric (INT+HP): Holy Light, Divine Lance | Oracle (INT+LUCK): Foresight, Starfall | — |
| Warrior (STR+HP) | Berserker (STR+HP) | Warlord (STR+LUCK) | — |
| Monk (AGI+STR) | Grandmaster (AGI+STR) | Shadowfist (AGI+LUCK) | — |
| Spellblade (STR+INT, offensive) | Stormblade (STR+INT) | Arcane Knight (INT+STA) | — |
| Magic Swordsman (STR+STA, defensive duelist) | Blademaster (STR+AGI) | Runeguard (STA+INT) | — |
| Summoner (INT+LUCK) | Beastcaller (INT+LUCK) | Spiritbinder (INT+HP) | Necromancer (Villain, INT+LUCK) |

- The five newer lines (Warrior, Monk, Spellblade, Magic Swordsman, Summoner; Hayden 2026-10-25) have their skills in `SkillLibrary.CLASS_SKILLS`. Warrior lines use **Fury** (a status: +30% damage, `DamageCalc.FURY_MULT`).
- **Tier 3** (placeholder names): every tier-2 class has one mastery with the same stats and route, and a capstone skill: Aegis Lord, Colossus, Templar, Inferno Sage, Tempest Sovereign, Archwarlock, Deadeye, Windwalker, Nightblade, Fortune's Fool, Headsman, Saint, Seer of Fates, Warbringer, Conqueror, Ascetic Master, Phantom Fist, Tempest Blade, Mystic Knight, Sword Saint, Rune Warden, Beast Lord, Soul Shepherd, Lich.
- **Summons:** a skill with `effect: SUMMON` and a `summon_id` (an `EnemyDef` in the "spirit" family, 0 XP/gold) calls a unit to the caster's side for the rest of the fight. One per summoner (casting again heals it), strength follows the caster's Intelligence (`BattleManager.SUMMON_INT_PER_SCALE`). The battle screen adds its card when it joins.
- **Ascension (NG+):** any line can Ascend. Needs New Game+, a **tier-3** class (not the Ascendant), **level 50** and floor **41+** (`ClassRegistry.ASCENSION_GATE`). Tab shows a **✧ Ascend** button (hover says what's missing). An Ascended character is titled "Ascended <class>", gets **+5%** to every stat (`ASCENSION_BONUS`) and the **Apotheosis** skill. Still below the Ascendant. Saved; a tampered flag on a lower class is dropped.

- Route-only advancements are **hidden** unless you're on that route.
- **The main questline** now continues to floor 30, where the climb ends for now.

## Routes and endings
- **Routes:** Hero, Villain and Vigilante (`scripts/story/route_library.gd`). Your choices, quests and some bounties add **points** to a route. You **lean** toward one at **10 points** if it's ahead of the rest (a tie doesn't count). A route **locks** for good at **30 points with a 15-point lead**, or through a **key choice**.
- **You only ever see hints**, never numbers: a line in the Tab menu ("People lower their voices when you pass."), how NPCs treat you, prices.
- **What your route changes:**
  - **The ending:** beating the final floor shows your route's ending, or **The Wanderer** if you never leaned.
  - **Quests and dialogue:** `route`, `not_route`, `route_locked` and `no_route` conditions, plus `route_points` and `lock_route` effects.
  - **Who joins and stays:** each companion has values (`"likes"` / `"dislikes"`). Lean into a route they dislike and they warn you in a conversation. Keep going (20 points, or a lock) and they leave: their gear goes to your bag, they wait by a campfire, and they refuse to rejoin until you turn back. Your childhood friend can leave too. A recruitable NPC won't join someone on a route they dislike.
  - **Shops:** heroes pay 10% less and villains 25% more (`GameState.HERO_PRICE_MULT` / `VILLAIN_PRICE_MULT`). A locked-in villain is refused by the merchant, but a **hooded trader (the black market)** appears on rest floors for anyone on the villain route, with its own stock and prices.
  - **Classes:** a class can have a `required_route` (Paladin, Warlock and Executioner do). It's hidden and can't be taken on other routes.
  - **Bounties:** besides the family bounty, board jobs can be a **Shady job** (more gold, nudges villain), a **Plea for help** (less gold, nudges hero) or **Wanted** (nudges vigilante).
- **Endings are picked by priority:** when the run ends, the most specific ending that fits wins. The route endings are priority 10, the Wanderer is 0 and always fits.
- **The Hall of Climbers** records every ending a character has reached. New Game+ starts the route over, so you can try another one.
- **DLC-ready:** at startup the game mounts any `.pck` in a `dlc` folder next to the game exe and calls `register()` on each `res://dlc/<name>/content.gd`. A DLC can add routes and endings (e.g. a priority-20 "The Lonely Hero" ending for heroes whose friend left) without changing the base game. Packs are only read from the game's own folder, never from saves. There's an example pack in `tests/fixtures/dlc/`.
- **Placeholder route content:**
  - **A captured bandit** on cleared boss floors: let them go (hero), turn them in (vigilante) or rob them (villain).
  - **The crossroads shrine** on rest floors from 15, while no route is locked: the key choice, swearing an oath that locks a route.
- Tunables: `RouteLibrary.LEAN_POINTS / LOCK_POINTS / LOCK_LEAD`, `GameState.COMPANION_LEAVE_POINTS`, `QuestLog.BOUNTY_FLAVORS`.

## Elements, weaknesses and the Bestiary
Plan your party on floors 1–9 for the boss on floor 10.
- **Elements:** Fire, Ice, Water, Lightning, Earth, Holy, Dark and Wind, plus the physical **weapon kinds** Slash, Pierce and Blunt (`scripts/combat/element.gd`). A skill can carry more than one: Ember Strike is Fire + Slash, Meteor is Fire + Earth. Battle skill buttons show what each hit carries, e.g. "Ember (3 MP) [Fire]".
- **Weapon kinds:** physical attacks and skills that don't name a kind use your weapon's. Sword = Slash; Bow and Dagger = Pierce; Mace, Staff and Scepter = Blunt; no weapon = Blunt.
- **Elemental weapons:** Rare+ weapons can roll an element (25% Rare, 35% Epic, 50% Legendary), e.g. "Flame Mithril Sword". It's added to that wielder's **basic attack**.
- **Reactions:** **Weak ×1.5**, **Resists ×0.5**, plus rare **Immune** (no damage) and **Absorbs** (heals it). If a hit has several elements, the multipliers stack. Absorb beats everything, then immune.
- **Stagger:** every weakness hit fills the enemy's meter: **2** hits for normal enemies, **4** for bosses, minibosses and roaming bosses (`Combatant.STAGGER_HITS`). A full meter makes it **lose its next turn** and cancels its planned move. Each stagger needs one more hit than the last, so bosses can't be stun-locked. The meter shows on the enemy's card.
- **Families** share weaknesses, resistances and traits (`scripts/combat/enemy_families.gd`). An enemy can override single elements on top of its family, like the Mud Slime that doesn't mind water.

| Family | Weak | Resists | Trait |
|---|---|---|---|
| Slimes | Fire, Wind | Water, Slash, Pierce | Gelatinous: the first physical hit each round does half damage |
| Goblins | Pierce | — | Easily distracted: Taunt lasts +1 turn; goes after whoever hit it last |
| Orcs | Pierce, Ice | Blunt | Thick-skulled: 1 more weakness hit to stagger |
| Imps | Holy, Water | Fire, Dark | — |
| Wraiths | Holy, Blunt | Pierce, Slash; **immune** to Dark | — |
| Wyrms | Ice, Water | **absorbs** Fire | — |
| Beasts | Pierce | Blunt | Reckless: hits 30% harder below half HP |

- **Bestiary (Tab → Bestiary):** every enemy you fight is added. Hitting one with an element records how it reacted, and what you learn about a family shows on all its members. Traits and lore unlock once you've beaten it. In battle, each enemy card shows what you know ("Weak: Fire, Wind"). The bestiary is saved with the run and starts fresh in New Game+.
- **Scouting Lens** (merchant, **200g**, carry at most **3**; stage bosses drop one 35% of the time): use it on an enemy in battle to reveal all its reactions and traits for good. Because families share knowledge, scanning one slime tells you about every slime.
- **Hints:** the merchant's "Any advice for the floors ahead?" and the scratched warnings on some normal floors (20%) describe the next stage's family (placeholder text in each theme's `hint`).
- **Learning elements:** the six elemental bolts are Common picks, so any character can answer a weakness early. Smite (Holy) and Shadow Bolt (Dark) are Rare skill books. Monsters drop books that fit them.

## Tower rules
- **HP and MP carry over** between battles. Heal with Support's Heal (in or out of battle) or potions.
- **Downed allies stay down** (no turns) until you use a **Goddess Tear** (revives with 30% HP, in or out of battle) or rest at a **campfire** (full heal and revive for the whole party).
- **Goddess Tears** are rare. Bosses drop them, and the merchant sells them for 1500g (a Potion is 40g). The merchant also sells the Scouting Lens (200g, carry 3).
- **Bosses and minibosses** can't be fled from; roaming bosses can. The sandbox has test buttons for all three kinds.
- **Every 5th floor is a rest floor** (except boss floors), with a campfire, a merchant and no enemies. Reaching one makes it your checkpoint. Beating a stage boss also makes its floor your checkpoint.
- **A party wipe** sends you back to your last checkpoint (floor 1 before your first rest floor), fully healed, and costs some gold (20% on Normal; see Difficulty).
- **Enemies** wander around and chase you when you're within 5 tiles. Touching one starts the fight with its group; the number on an enemy is how many are in its group.
- **Beating an enemy** removes it from the floor. **Fleeing** leaves it there, but it's stunned for a moment so you can get away.
- **Enemies per floor:** 2 on floors 1–4, 3 on floors 5–9, then 4 (`FloorLayout.enemy_count_for_floor`).
- **Group size follows your party:** a normal group never has more enemies than your party has members (`GameState.MAX_EXTRA_ENEMIES` = 0). Minibosses and bosses always come, but their escorts are trimmed the same way. The groups in `StageLibrary` are written for a party of four; with 6+ fighters they're never bigger than written.
- **Enemy strength** scales with the floor: ×0.42 on floor 1, +0.05 per floor (×0.87 on floor 10, ×1.87 on floor 30). Minibosses and bosses follow the same curve (×0.9; `StageLibrary.GUARDIAN_MULT`). Every enemy's HP is also ×0.8 (`Combatant.ENEMY_HP_MULT`).
- **Stage themes have a `power` rating** (Orc Stronghold 1.4: orcs are stronger than goblins by their own stats). Floor scaling and rewards are divided by it, so any theme fits any slot and the floor alone sets the difficulty.
- **Rewards grow with the floor:** battle XP grows with enemy strength (×1 on floor 1, ×4.4 on floor 30), gold a little slower (to the power 0.7), so shop prices still matter higher up. Bounty rewards follow the same curve.
- **Healing between rest floors:** you start with 5 Potions, ordinary enemies drop one 8% of the time (`LootTable.NORMAL_POTION_DROP`), and every level adds 10 max HP on top of Health (`CharacterData.HP_PER_LEVEL`).
- **Before a class (levels 1–9)** the basic attack uses your stronger of Strength or Intelligence (`attack_novice`), so a future mage isn't stuck punching.

## Difficulty and Ironman
Picked at **New Game** (and again when starting **New Game+**). During a run you can **lower** it (pause menu → Difficulty) but never raise it.

| | Enemies | Enemy skills | XP | Gold | Gold lost on a wipe | Extras |
|---|---|---|---|---|---|---|
| **Relaxed** | ×0.75 | ×0.75 | ×1.25 | ×1.25 | none | |
| **Normal** | ×1 | ×1 | ×1 | ×1 | 20% | |
| **Hard** | ×1.1 | ×1.15 | ×0.95 | ×0.9 | 25% | |
| **Hell** | ×1.35 | ×1.4 | ×0.85 | ×0.75 | 40% | no Scouting Lens for sale, consumables ×1.5, stage bosses bring an extra escort |

- **Ironman** is a checkbox that works with any difficulty and can't be turned off. Anyone still down when a fight ends is **dead**: companions are gone for good (their gear goes to the bag), and if **you** die, or the party is wiped out, the run is over. The save is deleted and the Hall of Climbers records the character as **Fallen on floor X** (no New Game+ from them).
- The Hall shows the hardest difficulty each character has cleared on, and whether they did it on Ironman.
- Numbers: `scripts/data/difficulty.gd`.

### What the balance simulator says
`tools/balance_sim.tscn` plays whole runs with a bot: it fights everything, uses weaknesses, heals, buffs, keeps its summons up, takes a heal skill when the party has none, recruits, equips gear and shops, but never grinds. It also skips roaming bosses and never moves rows, Defends or Guards, so a real player should do somewhat better. The bot is noisy (battles roll their own dice), so compare 20+ runs.

**Balance pass 2** (2026-10-25, after the growing party and the 4 rows), 20 runs per difficulty over all 60 floors, giving up after 6 wipes on one floor (15 on Hell):

| | Runs cleared | Wipes per run (bot) | Hardest stages | Party level reaching floor 10 / 30 / 60 |
|---|---|---|---|---|
| Relaxed | 20/20 | ~1 | — | 11 / 30 / 53 |
| Normal | 17/20 | ~9 | 3–4 | 11 / 31 / 56 |
| Hard | 10/20 | ~15 | 3–4 | 11 / 32 / 57 |
| Hell | 9/20 | ~42 | 1–3 | 16 / 36 / 66 |

- **Every enemy's HP follows the party slots**, not just bosses': normal enemies ×`pow(slots / 4, 0.5)` (`GameState.NORMAL_PARTY_EXP`): ×0.71 for 2 fighters, ×1.22 for 6, ×1.58 for 10. A duo's fights are swingier (one crit downs half the party) and a big party's were too easy.
- **The curve steepens past floor 40** (`ENEMY_SCALE_LATE_PER_FLOOR` 0.02 per floor on top of the usual 0.05), for tier-3 classes (+20%) and bigger parties.
- **Combos the bot can't always clear on Normal:** Rogue + Warrior (no heals, no Pierce) in Goblin Warrens or Slime Pits, and all-physical parties in the Elemental Rift. Both match the stage designs (slimes and elementals resist physical).

Run it yourself (from the project folder):

    godot --headless --path . res://tools/balance_sim.tscn -- runs=20 difficulty=all
    godot --headless --path . res://tools/balance_sim.tscn -- runs=40 guilds

Options: `difficulty=0..3` (Relaxed..Hell) or `all`, `runs=N`, `floors=N`, `max_wipes=N` (give up after this many wipes on one floor), `why` (print the last fights of runs that gave up), `debug` (print every fight). The `guilds` mode measures how busy the guild world is with different patrons.

## Stages, bosses & loot
The tower is split into **stages of 10 floors**, set up in `scripts/tower/stage_library.gd`. Each stage has a **theme** (an enemy family), normal enemies and minibosses from that family, and a **boss on its last floor**. The structure is data, not a hard rule: you can change the number of floors per stage, how many minibosses a theme has, or which floors they're on. Floors past the last stage slot reuse the slots in order.

**Themes are picked per run.** Each stage slot has a pool of themes, and every New Game and New Game+ rolls one per slot (saved with the run). A slot can be **pinned** to one theme (`"pinned"`) if the story ever needs it fixed. Saves from before themes existed keep the original stages.

**The climb is 60 floors (6 stages; `FINAL_FLOOR`).** Hayden's arc: the player climbs toward godhood. Each run picks one theme per slot:

| Floors | Themes (one per run) | Minibosses (4th / 9th floor of the stage) | Boss (patron) |
|---|---|---|---|
| 1–10 | Goblin Warrens / Slime Pits | Goblin Captain, Hobgoblin / Big Slime, Mire Slime | Goblin King / King Slime |
| 11–20 | Orc Stronghold / **Bandit Fortress** | Orc Warchief, Orc Blood Shaman / Bandit Captain, Bandit Quartermaster | Orc Warlord / **Bandit Lord** (Mammon) |
| 21–30 | **Insect Hive** / **Beast Den** | Hive Warden, Brood Mother / Pack Leader, Elder Bear | **Hive Queen** (Apep) / **Moonfang, the Great Wolf** (Loki) |
| 31–40 | **Elemental Rift** / **Undead Crypt** | Magma Colossus, Tempest Lord / Bone Knight, Grave Priest | **Rift Sovereign** (Typhon) / **The Necromancer** (Hades) |
| 41–50 and 51–60 | two of **Demon Gate** / **Celestial Spire** (angels) / **Dragon Roost**, never the same twice | Pit Fiend, Hell Warlock / Throne Guardian, Choir Master / Drake Rider, Elder Wyvern | **The Archfiend** (Mephistopheles) / **Seraph Judicator** (Zeus) / **Dragon Sovereign** (Tiamat) |

- **Pseudo-god stages:** Demons, Angels and Dragons share one pool for floors 41–60 (`"group"` in `STAGE_SLOTS`), so any two of them can come in either order.
- **New families:**
  - **Bandits:** weak to Lightning and Pierce; easily distracted.
  - **Insects:** weak to Fire and Wind; resist Earth and Pierce. **Swarming:** +10% damage per other living swarmer, up to +30%.
  - **Elementals:** resist blades and arrows (a hammer cracks them); each absorbs its own element and fears its opposite.
  - **Undead:** weak to Holy and Fire; resist Dark and Ice. **Undying:** survives its first killing blow with 1 HP, unless that blow is Holy or Fire.
  - **Demons:** weak to Holy and Ice; resist Fire and Dark; reckless.
  - **Celestials:** weak to Dark; resist Holy and Lightning.
  - **Dragons:** weak to Ice and Pierce; resist Fire and Slash. **Dragonscale:** non-weakness hits do 25% less.
  - Families and traits live in `enemy_families.gd`.
- **Boss patrons:** a boss can name a sponsoring being (`EnemyDef.patron`).
  - It fights with that being's level-2 blessing (buffs, no curse) and its blessed skill.
  - The cut-in says "Sponsored by …".
  - Beating it costs that being 10 interest in you, and gives each of its rivals 10.
  - Sensitivity rule: figures from living religions never sponsor enemies (tests enforce it).
- **Signature skills:** each new boss has a Unique skill book (Highwayman's Ruin, Chitin Storm, Moonfang, Cataclysm, Grave Tide, Abyssal Brand, Judgment Ray, Dragonfire).
- **Theme power:** new themes are built at the goblins' baseline. The trait-heavy ones get a power rating so the floor curve stays fair: Insects 1.1, Elemental Rift 1.3, Undead 1.25, Demons 1.1, Angels 1.1, Dragons 1.2 (Orcs 1.4).
- **Simulator, Normal, 60 floors (with the recruit roster):** 28 of 30 runs clear, with about 10 wipes per run spread across the stages. Party level on first reaching floors 10/20/30/40/50/60 is about 12/23/33/41/50/58. Hard clears 11 of 12 and Hell 5 of 12 (a grind).

- Floor 1 always uses the small level-1 groups. Floors 2–3 use the theme's small early groups, and floor 4 onward its full groups.

- **Minibosses and bosses guard the stairs.** They don't move, the stairs stay locked until you win, and you can't flee.
- **A boss floor is an arena** with no regular enemies. Beating the boss lights a **campfire** and brings the **merchant**, and that floor becomes your checkpoint. Normal **rest floors** are every 5th floor except boss floors (5, 15, 25…).
- **Minibosses and bosses** have their own (bigger) stats and follow the same floor curve as everyone else (×0.9), so a repeated stage's bosses come back stronger on higher floors.
- **Roaming bosses** are lore bosses that broke loose from their home floor. They only appear on normal combat floors, at most one per floor. They're faster than other enemies, chase from 8 tiles away, and have a pulsing purple ring. **You can flee from them**, and once beaten they're gone for good. Each one has a spawn type (set in `stage_library.gd`):
  - **Story** (keep to exactly one): guaranteed on every normal floor from its story floor onward, within its range, until you beat it. It can optionally wait for a story flag. *Labyrinth Minotaur:* escaped from floor 30, guaranteed from floor 7, roams floors 6–19.
  - **Secret**: the **final step of a secret-class questline**. It **never appears** until you've found the path's clues; after that it's **guaranteed** on normal floors in its range until you beat it. The HUD only says "Something stalks this floor". *Ashen Wyrmling:* escaped from floor 40, floors 12–29.
  - **Random**: a 12% chance on normal floors in its range. *Lantern Wraith:* escaped from floor 25, floors 8–22.
  - If more than one could appear on a floor, the order is secret, then story, then random.
- **Secret-class questlines** are defined in `scripts/story/secret_paths.gd`:
  1. **Find the clue flags.** They're set by dialogue, lore objects or found items with `GameState.set_flag(&"flag_name")`. The Ashbound path has 3: a scorched mural, a merchant's story, and a feather in the embers.
  2. **Once you've found `clues_to_start` of them** (all 3 by default), the path's roaming boss is guaranteed to hunt you.
  3. **Beating it is the final step.** It unlocks the secret class and announces it on the floor.
- **Ashbound Knight** is the placeholder secret class. It needs 55% of allocated points in Strength + Intelligence, and it's **player character only**. Its skills are Ember Strike (melee, ignores 30% defense) and Ashen Nova (magic, hits all enemies). Once unlocked, it's offered at the level-10 class screen if you qualify. If you already have a class, the party menu has a **✦ Ashbound Knight** button that switches to it (it replaces your class and skills). Locked secret classes never show up anywhere, including the "how close you are" hints.
- **Its own advancements** (Hayden 2026-10-25), so taking it isn't a step down: Ashbound Knight → **Cinderbrand Knight** (tier 2: Cinder Cleave, Ashen Ward) → **Wyrmflame Knight** (tier 3: Wyrmflame). Same gates and trials as other lines; placeholder names.
- **One free class change** (Hayden 2026-10-25): once floor 20 is beaten, each character still in a tier-1 class gets a **⇄ Change class** button in Tab (a notice on floor 21 says so). It gives up the class, grants a free respec, and lets them choose again (any class they qualify for, or an unlocked secret class for the player). Learned skills stay. Once per character (`CharacterData.class_change_used`, saved), and not after advancing.
- In the sandbox, **🔍 Find next Ashbound clue** gives you the clues one at a time for testing.

### Loot
| Source | Gear drops | Luck bonus | Minimum rarity | Unique chance |
|---|---|---|---|---|
| Miniboss | 1 | – | Common | **none** |
| Stage boss | 2 (+ Goddess Tear) | +10 | Uncommon | 8% |
| Roaming boss | 2 (+ 50% Goddess Tear) | +20 | Rare | 15% |

- **Rarity** is rolled from the party's highest Luck plus the enemy's bonus. Tiers are Common, Uncommon, Rare, Epic and Legendary; at Luck 5 the odds are 55 / 28 / 12 / 4 / 1%.
- **Uniques** are not in the normal table. They **only come from stage bosses and roaming bosses**. The Unique chance goes up 2% (relative) for each Luck point above 5. A Unique only drops for a class in the party that doesn't already have theirs.
- **Uniques** are one weapon per class, and only that class can equip them: Bulwark of the First Climber (Tank), Starfall Staff (Mage), Windpiercer (Archer), Fang of Fortune (Rogue) and Lifebloom Scepter (Support).
- **Gear slots** are Weapon, Armor and Accessory. Gear stats don't count toward class requirements.

## Placeholder numbers to tune
Most of these were set by the balance pass with `tools/balance_sim` (see Difficulty and Ironman). Re-run it after changing them.
- XP curve: `25 * level^1.5` (`CharacterData.XP_BASE / XP_EXPONENT`), plus `HP_PER_LEVEL`
- Difficulty modes: `scripts/data/difficulty.gd`
- Enemy curve, rewards and group size: top of `game_state.gd` (`ENEMY_SCALE_*`, `REWARD_EXP`, `GOLD_REWARD_EXP`, `MAX_EXTRA_ENEMIES`); `Combatant.ENEMY_HP_MULT`; `StageLibrary.GUARDIAN_MULT` and each theme's `power`
- Guild AI activity: top of `guild_ai.gd` (`ACT_CHANCE`, `*_WEIGHT`, `PATRON_PULL`, `FEUD_WAR_BONUS`, `UPSTART_WAR_BONUS`); beings' `TEMPER` in `being_library.gd`
- Respec cost: 500 gold, doubling each paid respec (`RESPEC_BASE_COST / RESPEC_COST_MULTIPLIER`)
- Derived stat rates: top of `stat_block.gd`
- Combat math: top of `damage_calc.gd`
- Skill numbers: `skill_library.gd`
- Enemy stats: `enemy_library.gd`
- Floor scaling, rest-floor interval and defeat penalty: top of `game_state.gd`
- Item amounts and prices: `item_library.gd`
- Rarity odds and Luck scaling: `rarity.gd`
- Gear stat budgets, base items and Uniques: `loot_table.gd`
- Boss stats and loot profiles: `enemy_library.gd` (`loot_rolls`, `loot_luck_bonus`, `min_loot_rarity`, `unique_chance`, `drops`)
- Stage layout, roaming spawn chance and repeat scaling: `stage_library.gd`
