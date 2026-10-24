# Tower Climber — notes for Claude

Manhwa-inspired tower-climber RPG in **Godot 4.6.1** (GDScript). Plays like
Hero's Adventure: Road to Passion / Final Fantasy: FF-style menu combat with
front/back rows. README.md documents every system and its tunables — read it
before changing gameplay.

## Current phase
Building the **Skeleton** (every system working) before the **Meat** (story,
quests, relationships). Don't write story content unless asked.

Skeleton items still open (Hayden picks the order):
boss weaknesses (NEXT: elements on skills, weaknesses/resistances and
traits like "easily taunted" on enemies, a bestiary that records what you've
seen, so players scout floors 1-9 and plan the party for the boss; e.g.
slimes weak to fire, goblins easy to distract; design it with Hayden first),
quests, tier-2 class advancement after floor 20, selling gear, balance pass,
art/sound hooks. Tutorial is deliberately deferred until the game is closer
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
- Dismissing is never permanent: they wait by the campfire on rest floors
  exactly as they left (gear goes to the bag). Recruits with no room at all
  wait there too.

## Testing
Every change gets tests in tests/ (8 suites, 446 checks at last run).
Run headless from the project folder:

    godot --headless --path . --import
    godot --headless --path . res://tests/test_skills.tscn

(Replace `godot` with the path to the Godot 4.6.1 executable on this PC.)
Suites: test_progression, test_combat, test_tower, test_loot, test_save,
test_skills, test_dialogue, test_party. All must pass before handing work back.
The Dev Sandbox has a floor picker for testing any floor's enemies/bosses.

## Working with Hayden
- Explain changes briefly; he tests in the editor and gives feedback.
- He often adds requests mid-task — fold them in rather than restarting.
- Ask before big design decisions; small tuning numbers can be proposed.
- He commits with GitHub Desktop (repo: Wozo-bit/Tower-Climber, private).
