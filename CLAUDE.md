# Tower Climber — notes for Claude

Manhwa-inspired tower-climber RPG in **Godot 4.7.2** (GDScript; upgraded from 4.6.1). Plays like
Hero's Adventure: Road to Passion / Final Fantasy: FF-style menu combat with
front/back rows. README.md documents every system and its tunables — read it
before changing gameplay.

## Current phase
Building the **Skeleton** (every system working) before the **Meat** (story,
quests, relationships). Don't write story content unless asked.

Skeleton items still open (Hayden picks the order):
quests, tier-2 class advancement after floor 20 (also where deeper elemental
skill lines go, e.g. Fire mage -> Lava = Fire + Earth), selling gear, balance
pass, art/sound hooks.
Hayden will send tweaks to the enemy family table after playing it.

### To do first when Hayden is back (in this order)
1. BUG (Hayden, playing in-game): the screen gets cut off and doesn't
   fit/adjust to the window, so in fights the command buttons can end up off
   screen. Every screen must always fit, battle commands always visible.
   Likely fix: project.godot has no stretch settings (only 1280x720
   viewport) -> set display/window/stretch/mode="canvas_items" and
   aspect="expand", then check battle/party/manage/bestiary layouts at
   smaller and larger window sizes (and fullscreen). Ask him for his screen
   resolution / Windows display scaling if it still happens.

### NEXT: Quests + routes (designed with Hayden 2026-10-24, not built yet)
- Quest sources: NPC dialogue, rest-floor notice board, found items/lore
  objects, and a main story questline.
- Goal types: defeat enemies (count/family/specific boss or roamer),
  collect/deliver items, reach floor / find something, talk to someone.
- Rewards: gold/XP/items/books, quest_reward gear (never carries to NG+),
  unlocks (recruits, secret-path clues, shop items, tier-2 class reqs),
  bestiary knowledge.
- Failing: optional quests can expire (floor limit) and choices can close
  quests off. A failed quest goes to "Failed" and can set a flag that opens
  another quest or consequence.
- ROUTES (multiple endings): Hero, Villain, Vigilante (more later). Tracked
  by points per route from choices/quests PLUS a few big key choices that
  lock a route. Route changes: the ending, which quests are offered, who
  joins (and stays), route-only classes and shops (merchants refusing etc.).
  Player sees HINTS only (reputation line in Tab, NPC reactions), no meter.
- Companions who strongly disagree warn first, then leave (wait at rest
  floors, refuse to rejoin unless the route changes back). The childhood
  friend CAN leave too on certain routes (big story moment).
- NG+: route resets to neutral; the Hall of Climbers records which endings
  that character has seen.
- Notice board: both generated bounties fitting the current stage (3 per
  rest floor, some route-flavored) and hand-written jobs at set floors/routes.
- Tracking: Tab -> Quests log (active/completed/failed with step progress),
  one pinned quest on the floor HUD, toasts on progress.
- Build quests/routes as data (like DialogueLibrary), validated by tests;
  placeholder text only, no real story. Tutorial is deliberately deferred until the game is closer
to complete.

Placeholders to confirm with Hayden later: title "Tower Climber",
default friend name "Rowan", Ashbound Knight secret-class details,
FINAL_FLOOR = 20 (long-term target is 100 floors, roguelite-style replayability).

## Architecture
- Autoloads: ClassRegistry, GameState, Settings. UI is built in code
  (scenes are minimal roots). Data libraries are static (SkillLibrary,
  EnemyLibrary, ItemLibrary, LootTable, StageLibrary, SkillBooks, SkillTier).
- Saves are **JSON** (never .tres — those can run embedded code), validated
  on load in scripts/save/save_serializer.gd, written atomically. 3 slots +
  user://hall_of_climbers.json for completed characters (New Game+).
- Dialogue/NPCs: conversations are data in scripts/story/dialogue_library.gd
  (validated by the tests), NPCs/lore objects in npc_library.gd, played by
  DialogueRunner. Recruits join at player level - 1.
- Party: GameState.companions (fighting, max 3 + player), reserve (bench,
  max RESERVE_CAP), waiting (dismissed / overflow; they stand by rest-floor
  campfires and rejoin via the waiting_companion dialogue). UI in
  scripts/ui/party_manage_panel.gd (Tab -> Manage party).
- **No API keys or network code.** Keep it that way unless Hayden asks;
  never hardcode secrets (he plans to publish).

## Design rules Hayden has set
- HP/MP carry over between battles; healing via healers or potions.
- Goddess Tear (revive) only from bosses or very expensive in shop.
- Miniboss every 5 floors starting floor 4, themed to that stage's boss
  (data-driven in StageLibrary, not hardcoded). Boss every 10 floors.
- Rarity: Common/Uncommon/Rare/Epic/Legendary/Unique. Unique = weapon only,
  one per class, class-locked, only from 10-floor bosses and roaming bosses.
- Exactly 1 story-guaranteed roamer; secret-path roamers appear when on that
  path; beating the secret roamer is the final step to unlock the secret class.
- NG+ carries only hard-to-get gear (Uniques), not quest rewards. NG+-only
  class (Ascendant) is stronger than any normal class. NG+ suggests the slot
  the run was beaten in but lets the player pick any slot (with a confirm).
- New Game starts with one companion: the childhood friend, named by the
  player Pokémon-style after character creation (default name provided).
- Skill book tiers: 60/30/8/1.5/0.5 (Common/Rare/Epic/Legendary/Unique);
  every 10 Luck shifts odds toward Epic+; Luck 40 = 50/25/20/3/2.
- Party management: swap/bench/dismiss freely out of battle, but LOCKED on a
  floor whose miniboss or boss is alive (plan the party beforehand; the
  stairs warn first). Order and rows can always change. Reserve cap 6, gets
  50% XP. The childhood friend can be benched/dismissed like anyone.
- Weaknesses: 8 elements (Fire, Ice, Water, Lightning, Earth, Holy, Dark,
  Wind) + weapon kinds (Slash, Pierce, Blunt); skills can carry several.
  Weak x1.5 / resist x0.5 / immune and absorb only on rare enemies.
  Weakness hits stagger (2 normal, 4 bosses) = lose next turn. Enemy
  families share weaknesses + traits so floors 1-9 teach the floor-10 boss.
  Players learn by fighting (bestiary), family knowledge, lore hints, and a
  LIMITED Scouting Lens (200g, carry max 3) so it can't be abused.
- Stage themes are random per run (e.g. floors 1-10 Goblin Warrens or Slime
  Pits). If the story needs a fixed stage, pin that slot in StageLibrary.
- Dismissing is never permanent: they wait by the campfire on rest floors
  exactly as they left (gear goes to the bag). Recruits with no room at all
  wait there too.

## Testing
Every change gets tests in tests/ (9 suites, 525 checks at last run).
Run headless from the project folder:

    godot --headless --path . --import
    godot --headless --path . res://tests/test_skills.tscn

(Replace `godot` with the Godot 4.7.2 console exe on this PC:
C:\Godot\Godot_v4.7.2-stable_win64_console.exe)
Suites: test_progression, test_combat, test_tower, test_loot, test_save,
test_skills, test_dialogue, test_party, test_elements. All must pass before
handing work back.
The Dev Sandbox has a floor picker for testing any floor's enemies/bosses.

## Working with Hayden
- Explain changes briefly; he tests in the editor and gives feedback.
- He often adds requests mid-task — fold them in rather than restarting.
- Ask before big design decisions; small tuning numbers can be proposed.
- He commits with GitHub Desktop (repo: Wozo-bit/Tower-Climber, private).
