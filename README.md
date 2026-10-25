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
- **Ascendant** is a New Game+ only class for the player character, deliberately stronger than any first-run class:
  - +20% to every stat and no stat requirement.
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
| `tests/test_classes.gd` | 42 advancement checks: the tree, lineage, gate, trials, keeping skills, builds, route-only classes, Uniques, saving. Run: `godot --headless res://tests/test_classes.tscn` |
| `scripts/story/being_library.gd`, `blessing_state.gd` | Gods, demons and devils (their values, blessing levels, buffs + curses, bargains) and this run's interest / refusals / punishment. |
| `tests/test_blessings.gd` | 56 blessing checks: the roster and its sensitivity rule, rivalries, interest, offers, accepting, levels, buffs and curses in combat, warnings, punishment, bargains, shrines, boss visits, blessed NPCs, saving. Run: `godot --headless res://tests/test_blessings.tscn` |
| `scripts/economy/guild_library.gd`, `guild_state.gd` | The guilds (patrons, taxes, prices, members' stock, ranks) and this run's territories, standing, membership, treasuries and market. |
| `scripts/ui/guild_panel.gd` | Tab → Guilds. (The merchant's Buy/Sell tabs and guild shops are in `shop_panel.gd`.) |
| `tests/test_guilds.gd` | 63 guild and economy checks: territories, joining/leaving, ranks and perks, taxes, prices, pay, supply and demand, selling, guild jobs, agents, saving. Run: `godot --headless res://tests/test_guilds.tscn` |
| `scripts/economy/guild_ai.gd` | The guild AI: what each guild does every floor (trade, fortify, raid, ally, war). |
| `tests/test_guild_ai.gd` | 75 checks: the AI, raids, alliances, wars and fighting in them, guards and champions, stealing, pickpockets, heists, founding your guild, claiming floors, saving. Run: `godot --headless res://tests/test_guild_ai.tscn` |
| `tests/test_routes.gd` | 67 route checks: points, locks, hints, endings and DLC endings, companions warning/leaving, prices, the black market, route bounties and classes, the Hall, saving. Run: `godot --headless res://tests/test_routes.tscn` |
| `tests/test_loot.gd` | 80 loot, gear, stage, boss and roaming-boss checks. Run: `godot --headless res://tests/test_loot.tscn` |

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
- **The Ashbound clues** all come from this system now: the **scorched mural** (40% of normal floors 11–29), the **merchant's story** (floor 10+) and the **glint in the embers** (by the campfire on rest floors and cleared boss floors from floor 10).
- **Placeholder content only:** Brakka (a Tank you can recruit on rest floors from floor 5), the merchant and the two lore objects. Real story content comes later.

## Party management
Open it with **Tab → Manage party**.
- **The party** is you plus up to 3 companions. You always lead. Use **▲ / ▼** to change the order, which is the order in battle and on the HUD. **Front / Back** sets the row each member starts battles in.
- **The reserve** (the bench) holds up to **6** (`RESERVE_CAP`). Benched members don't fight but get **50%** of each battle's XP (`RESERVE_XP_SHARE`), shown on the victory screen. **Bench** sends a party member there, **Join party** brings someone back if there's a free slot, and **Swap in…** trades places with a party member you pick.
- **Dismiss** (with a confirm) is never permanent. Their gear goes to your bag, and they wait by the campfire on **rest floors and cleared boss floors**, exactly as they left. Talk to them there to bring them back (party if there's room, else the reserve). Recruits who join when the party and reserve are both full wait there too. The Manage party screen lists who's waiting.
- **The childhood friend** can be benched or dismissed like anyone else.
- **Plan ahead: the party locks on miniboss and boss floors.** While a floor's miniboss or boss is standing, you can't bench, swap, dismiss or bring anyone back. You can still change the order and rows. Walking onto stairs that lead to a miniboss or boss floor asks first: **Climb**, or **Check party first** (opens Manage party).

## Enemy intent, shared skills and skill books
- **Enemy intent:** at the start of each round, every enemy decides its move. Its card shows it (e.g. "Smash → Cassia" or "Volley → everyone"), and targeted allies get a red **⚠ Targeted** marker (x2 if two enemies are aiming at them). React with Defend, Guard, Ward, heals or a row change. If the target falls, or someone starts **taunting**, the intent re-plans and the markers update. An enemy can hide its intent (`hide_intent`, shown as "Intent: ???"); none do yet.
- **Shared skills:** anyone can learn these, whatever their class (or with no class). They're kept when you change class and carried into New Game+.
  - **Skill picks:** everyone starts with **1** (a starting skill) and gets another at levels **3, 6, 9, 12…**. Picks choose from the **Common** skills: Power Strike, First Aid, Guard, Focus, Quick Step, and the six elemental bolts (Ember, Frost Bolt, Splash, Spark, Stone Shot, Gust). Spend them in **Tab → Skills**.
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

## Combat rules (FF-style menus with front and back rows)
- **Melee** can't hit a back-row unit while its side still has a living front-row unit. Backstab is the exception.
- **Melee from the back row** deals 50% damage.
- **Ranged and magic** ignore rows. Magic can't be dodged; physical attacks can.
- **Turn order** is rolled each round: Agility × a random 0.75–1.25.
- **Commands:** Attack, Skills, Defend (halves damage until your next turn), Move row (saved on the character), Flee (chance based on average Agility).
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
- **The guilds think for themselves** (`scripts/economy/guild_ai.gd`; a local simulation, no online AI). Every floor you climb, every guild earns **60 gold per territory**, then (half the time) takes one action picked from its personality (greed, aggression, honor) and situation:
  - **trade** (safe income)
  - **fortify** (defense, more likely when threatened)
  - **raid** another treasury (greedy guilds, rivals first; yours too)
  - **ally** (honorable guilds whose patrons share values)
  - **declare war** on a neighbor or rival for one of its territories (aggressive guilds)
  It's seeded per run and floor, so a run replays the same way.
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
- Tunables: top of `guild_ai.gd` and `guild_state.gd` (wars, theft, champions, charter, income, upgrades).

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
- **When:** each tier has a **gate** in `ClassRegistry.ADVANCEMENT_GATES`. Tier 2 needs you to have **beaten floor 20** and the character to be **level 25**. Once both are met, an **✦ Advance** button appears on that character in the Tab menu. More tiers (e.g. 3 at floor 40, 4 at 60, 5 at 80) are just a gate plus their classes; the design is 3–5 advancements over the full 100-floor climb.
- **Each advancement also needs:** its **stat build** (a share of allocated points, like tier 1), its **route** if it's route-only, and its **trial quest**. Trials are placeholders: defeat 20 enemies, then a miniboss. Begin one from the Advance panel, and once it's done anyone who qualifies can take that class. The panel shows every requirement as ✔ / ✘.
- **What you get:** you **keep every skill** (tier-1 class skills and learned ones) and gain **2 new skills**, plus **+10% to every stat** (`ADVANCED_STAT_BONUS`; Ascendant's +20% stays the strongest). Your basic attack, default row and your class's **Unique weapon** carry over. Unique drops treat you as your tier-1 class.
- **The tree** (placeholder names, in `class_registry.gd` and skills in `skill_library.gd`):

| Tier 1 | Advancement | Advancement | Route-only |
|---|---|---|---|
| Tank | Bastion (HP+STA): Bulwark, Iron Will | Juggernaut (STR+HP): Crushing Blow, Rampage | Paladin (Hero, HP+INT): Holy Strike, Lay on Hands |
| Mage | Pyromancer (INT): Magma Burst (Fire+Earth), Inferno | Stormcaller (INT+AGI): Chain Lightning, Tempest (Wind+Lightning) | Warlock (Villain, INT+HP): Hex Bolt, Doom Wave |
| Archer | Sharpshooter (AGI+LUCK): Deadeye, Armor Breaker | Ranger (AGI+STR): Gale Arrows, Wind Step | — |
| Rogue | Assassin (AGI+STR): Shadow Strike, Vanish | Trickster (LUCK+AGI): Lucky Strike, Smoke Screen | Executioner (Vigilante, STR+AGI): Execute, Grim Resolve |
| Support | Cleric (INT+HP): Holy Light, Divine Lance | Oracle (INT+LUCK): Foresight, Starfall | — |

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
- **A party wipe** sends you back to your last checkpoint (floor 1 before your first rest floor), fully healed, and costs 20% of your gold.
- **Enemies** wander around and chase you when you're within 5 tiles. Touching one starts the fight with its group; the number on an enemy is how many are in its group.
- **Beating an enemy** removes it from the floor. **Fleeing** leaves it there, but it's stunned for a moment so you can get away.
- **Enemy strength** scales with the floor: ×0.7 on floor 1, +0.08 per floor. Floors 1–3 have smaller groups.

## Stages, bosses & loot
The tower is split into **stages of 10 floors**, set up in `scripts/tower/stage_library.gd`. Each stage has a **theme** (an enemy family), normal enemies and minibosses from that family, and a **boss on its last floor**. The structure is data, not a hard rule: you can change the number of floors per stage, how many minibosses a theme has, or which floors they're on. Floors past the last stage slot reuse the slots in order.

**Themes are picked per run.** Each stage slot has a pool of themes, and every New Game and New Game+ rolls one per slot (saved with the run). A slot can be **pinned** to one theme (`"pinned"`) if the story ever needs it fixed. Saves from before themes existed keep the original stages.

| Floors | Theme | Floor 4 miniboss | Floor 9 miniboss | Floor 10 boss |
|---|---|---|---|---|
| 1–10 | Goblin Warrens | Goblin Captain | Hobgoblin | Goblin King (+ Goblin Sorcerer, Goblin Archer) |
| 1–10 | *or* Slime Pits | Big Slime | Mire Slime | King Slime (+ 2 Bubble Slimes) |
| 11–20 | Orc Stronghold | Orc Warchief | Orc Blood Shaman | Orc Warlord |

- Floor 1 always uses the small level-1 groups. Floors 2–3 use the theme's small early groups, and floor 4 onward its full groups.

- **Minibosses and bosses guard the stairs.** They don't move, the stairs stay locked until you win, and you can't flee.
- **A boss floor is an arena** with no regular enemies. Beating the boss lights a **campfire** and brings the **merchant**, and that floor becomes your checkpoint. Normal **rest floors** are every 5th floor except boss floors (5, 15, 25…).
- **Minibosses and bosses are tuned by hand for their stage** rather than scaled per floor. They come back 60% stronger each time the stage list repeats. Against the level-10 test party with no gear: Goblin Captain 100% wins, Hobgoblin 100%, Goblin King 65%, Labyrinth Minotaur 39%.
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
- XP curve: `100 * level^1.5` (`CharacterData.XP_BASE / XP_EXPONENT`)
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
