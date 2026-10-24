# Tower Climber (Godot 4.6)

Open `project.godot` in Godot 4.6 and press **F5**. The game opens on the **title screen**:

- **Continue:** pick one of the **3 save slots**. Each shows character, level, floor, play time and last save time.
- **New Game:** pick a slot (overwriting asks first), then a two-step, Pokémon-style setup. You name your climber, then your childhood friend (leave it blank or press **Use "Rowan"** for the default). You both start at level 1 on floor 1.
- **New Game+:** opens once someone has conquered the tower. Pick a character from the **Hall of Climbers**, then a save slot. The slot they conquered the tower in is suggested (★), but any slot works, and a popup always confirms which slot will be used and what gets replaced.
- **Delete:** every slot has a Delete button (with a confirmation) for a fresh start. Characters in the Hall of Climbers are never deleted this way.
- **Settings:** master, music and sound-effect volume, fullscreen and V-Sync. Saved to `user://settings.cfg`.
- **Quit**
- **Dev Sandbox** (bottom-right, debug builds only): the old test screen with level-10 companions and test fights. Sandbox sessions never autosave over your real save.

In the tower: **WASD / arrows** move, **Tab** opens the party menu, **Esc** pauses (Resume / Save / Settings / Quit to Title). You can rename yourself or your friend anytime from **Tab → Rename**.

## Saving, the Hall of Climbers and New Game+
- **Autosave** happens when a run starts, on every floor, after every battle and at campfires. You can also save from the pause menu. Slots are `user://saves/slot_1.json` to `slot_3.json`.
- **Saves are plain JSON, on purpose.** Godot's `.tres` format can contain scripts that run when loaded, so a shared or tampered save could run code on someone's computer. JSON can only hold data, and everything read back is validated: unknown ids are dropped, numbers clamped, names cleaned. A broken file just shows as "Unreadable save". Saves are written to a temp file and then swapped in, so a crash mid-save can't corrupt the slot.
- **Completing the game** means beating the boss on `GameState.FINAL_FLOOR`, currently **20** (the design target is 100). The character is recorded in the **Hall of Climbers** (`user://hall_of_climbers.json`, kept across new games), and their save slot shows "conquered the tower" (it can't be continued, but New Game+ suggests it). Clearing again with the same character updates their record (times cleared, highest NG+ cycle, best time) instead of adding a duplicate.
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
- **Recruiting:** recruitable NPCs join at **your level − 1** (min 1), with their points spent by their build and their class taken if they're level 10+. If the party (you + 3) is full, they wait on the **reserve** (listed in the Tab menu, no XP) until party management lets you swap them in. Recruits leave the floor, are saved, and reset in New Game+ like other story progress. Uniques on reserve members still carry into New Game+.
- **The Ashbound clues** all come from this system now: the **scorched mural** (40% of normal floors 11–29), the **merchant's story** (floor 10+) and the **glint in the embers** (by the campfire on rest floors and cleared boss floors from floor 10).
- **Placeholder content only:** Brakka (a Tank you can recruit on rest floors from floor 5), the merchant and the two lore objects. Real story content comes later.

## Enemy intent, shared skills and skill books
- **Enemy intent:** at the start of each round, every enemy decides its move. Its card shows it (e.g. "Smash → Cassia" or "Volley → everyone"), and targeted allies get a red **⚠ Targeted** marker (x2 if two enemies are aiming at them). React with Defend, Guard, Ward, heals or a row change. If the target falls, or someone starts **taunting**, the intent re-plans and the markers update. An enemy can hide its intent (`hide_intent`, shown as "Intent: ???"); none do yet.
- **Shared skills:** anyone can learn these, whatever their class (or with no class). They're kept when you change class and carried into New Game+.
  - **Skill picks:** everyone starts with **1** (a starting skill) and gets another at levels **3, 6, 9, 12…**. Picks choose from the **Common** skills: Power Strike, First Aid, Guard, Focus, Quick Step. Spend them in **Tab → Skills**.
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

## Tower rules
- **HP and MP carry over** between battles. Heal with Support's Heal (in or out of battle) or potions.
- **Downed allies stay down** (no turns) until you use a **Goddess Tear** (revives with 30% HP, in or out of battle) or rest at a **campfire** (full heal and revive for the whole party).
- **Goddess Tears** are rare. Bosses drop them, and the merchant sells them for 1500g (a Potion is 40g).
- **Bosses and minibosses** can't be fled from; roaming bosses can. The sandbox has test buttons for all three kinds.
- **Every 5th floor is a rest floor** (except boss floors), with a campfire, a merchant and no enemies. Reaching one makes it your checkpoint. Beating a stage boss also makes its floor your checkpoint.
- **A party wipe** sends you back to your last checkpoint (floor 1 before your first rest floor), fully healed, and costs 20% of your gold.
- **Enemies** wander around and chase you when you're within 5 tiles. Touching one starts the fight with its group; the number on an enemy is how many are in its group.
- **Beating an enemy** removes it from the floor. **Fleeing** leaves it there, but it's stunned for a moment so you can get away.
- **Enemy strength** scales with the floor: ×0.7 on floor 1, +0.08 per floor. Floors 1–3 have smaller groups.

## Stages, bosses & loot
The tower is split into **stages of 10 floors**, set up in `scripts/tower/stage_library.gd`. Each stage has a theme, minibosses that lead up to its boss, and a **boss on its last floor**. The structure is data, not a hard rule: you can change the number of floors per stage, how many minibosses a stage has, or which floors they're on. Floors past the last stage you've defined reuse the stages in order.

| Stage | Floor 4 miniboss | Floor 9 miniboss | Floor 10 boss |
|---|---|---|---|
| 1: Goblin Warrens | Goblin Captain | Hobgoblin | Goblin King (+ Goblin Sorcerer, Goblin Archer) |
| 2: Orc Stronghold (floors 11–20) | Orc Warchief | Orc Blood Shaman | Orc Warlord |

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
