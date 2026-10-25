# Tower Climber — notes for Claude

Manhwa-inspired tower-climber RPG in **Godot 4.7.2** (GDScript; upgraded from 4.6.1). Plays like
Hero's Adventure: Road to Passion / Final Fantasy: FF-style menu combat with
front/back rows. README.md documents every system and its tunables — read it
before changing gameplay.

## Current phase
Building the **Skeleton** (every system working) before the **Meat** (story,
quests, relationships). Don't write story content unless asked.

The Skeleton is essentially DONE (selling gear, all 3 guild phases, art/sound
hooks, guild captains, the balance pass). Deferred until the story exists:
route thresholds (depend on how many choices the story gives) and per-skill
tuning of tier-2 classes. Re-balance with tools/balance_sim after big changes.

### Balance pass (2026-10-25; Hayden approved all changes below)
Hayden's targets: difficulty modes (Relaxed = story/dopamine, Normal = a
couple of wipes, Hard = challenging but fair, Hell = manhwa grind), an
IRONMAN toggle for any difficulty (anyone down after a fight is dead; you
die -> save deleted, Hall records Fallen, no NG+), difficulty picked at New
Game/NG+ and only LOWERED mid-run; clearing floors = enough XP (no grind);
gold "meaningful choices"; guild world "something every few floors" with
your patrons (blessing + own guild's patron) steering it: warlike patron ->
more wars, rival patrons' guilds feud with you (no truce).
Tool: tools/balance_sim.tscn (bot plays runs; "guilds" mode for the AI).
Design-level changes (approved by Hayden 2026-10-25): +10 max HP per
level (CharacterData.HP_PER_LEVEL); pre-class basic attack uses the higher
of STR/INT (attack_novice); enemy groups capped at party size
(MAX_EXTRA_ENEMIES 0) incl. guardian escorts; 5 starting potions + 8% potion
drops; theme "power" (orcs 1.4) divided out of scaling; XP_BASE 100 -> 25;
fewer fights per floor (2/3/4). The melee-only Slime Pits run (rogue+tank)
is the one combo the bot can't clear on Normal (by Hayden's slime design).

### Art/sound hooks (built with Hayden 2026-10-24)
Hayden has no art/music skills: plan is free commercial-safe assets (Kenney
CC0 for SFX/UI) now, commissioned manhwa portraits + boss art later.
- Everything looks up files by name (Assets for art, Audio for music/sfx) and
  keeps its placeholder when missing. Naming guide: assets/README.md.
- UITheme: system-window look, 6 palettes (System Blue default; Hayden
  wanted a variety), picked in Settings. Merged into ThemeDB's default theme
  (a root-window theme does NOT reach controls under a CanvasLayer).
- Music: stage + battle tracks with fallback chains matched to the stage,
  enemy family and boss (Hayden wanted variety per enemy type), crossfades,
  _2/_3 variants. Cut-ins (Hayden's picks): bosses/minibosses/roamers/
  champions, ultimate skills (Legendary+ or blessed), beings appearing,
  level-up + class change, wars involving your guild either way (player's own
  guild can now declare war too). System notices with chimes.
- Credits: assets/credits.json, validated; tests fail on uncredited files or
  non-commercial licenses. Credits screen includes Godot's MIT + engine
  third-party licenses.

### Guild captains (Hayden's idea, built 2026-10-24)
So benched companions aren't idle: own-guild players post RESERVE/WAITING
companions (not the active party) as captains of their territories
(GuildState.captains). Captains defend in wars + raids, fight beside you on
their floors (GameState.fighting_party adds them as a guest; not vs stage
bosses/minibosses), earn XP, add income + a merchant discount. Attacks on
your territory: you're warned, the attacker's war leader + guards appear
there so you can defend it. Territory falls -> captain CAPTURED (Hayden's
pick) -> rescue quest (rescue_* ids, defs rebuilt from
GuildState.rescue_quests): beat any captor champion or pay a ransom at its
agent; captors with no territory let them escape. Numbers = tunables at the
top of guild_state.gd (part of the balance pass).

Class advancement is BUILT as a multi-tier system: ClassRegistry.
ADVANCEMENT_GATES (tier 2 = beat floor 20 + level 25), per-class stat build,
route-only classes, auto-generated trial quests (QuestLibrary.trials()),
lineage (advanced classes keep all skills, basic attack, row, Uniques).
Tier 2 = 13 placeholder classes (names to confirm with Hayden). Hayden wants
3-5 advancements over 100 floors: add tiers as gates + classes when the
tower grows. Open question for later: tier 3+ may outclass Ascendant (+20%),
which must stay the strongest (design rule) — decide with Hayden then.
Hayden will send tweaks to the enemy family table after playing it.

### Blessings + guilds/economy (designed with Hayden 2026-10-24)
Build in phases: (1) blessings — BUILT (BeingLibrary roster + register_being,
BlessingState interest/offers/levels/warn/punish, blessing on CharacterData,
shrines, boss visits, bargains, blessed NPCs, blessed skills); (2) guilds
core + economy — BUILT (GuildLibrary: 10 guilds w/ patrons, 3-floor
territories, ranks; GuildState: owners per territory (saved, ready for the
AI to change), standing, membership, taxes -> treasuries, pay, per-territory
supply & demand, selling; guild agents, guild jobs on the board, members'
shops, Tab -> Guilds); (3) — BUILT: GuildAI.tick every floor (income +
trade/fortify/raid/ally/war from personality, seeded per run+floor), wars
(simulated, player swings them as member or mercenary), Tower News +
merchant rumors, guards/champions (human enemies, "guard"/"champion" floor
kinds with a "guild"), stealing at traders, pickpockets, heists, founding
your own guild (registered as GuildLibrary.PLAYER_GUILD at runtime; Hayden:
no need to leave your guild first), claiming floors via champions, income,
tax, hall upgrades.
- Roster = 26 figures from world mythologies (Norse, Greek, Egyptian,
  Chinese, Japanese, Mesopotamian, Celtic, Infernal). Hayden wanted
  mythology instead of invented beings. Rivalries (jealousy, spite curses).
- SENSITIVITY RULE (Hayden: "respectful for now", may change; he wants to
  maximize sales): "living": true figures (Shinto kami, Chinese folk/
  Buddhist/Taoist) are only ever gods; demon/devil roles only for figures
  who are monsters/tricksters in their own myths. Enforced by the tests.
  Hindu deities deliberately left out — ask Hayden before adding (biggest
  backlash risk, big market).
- GUILD CONTRACTS (for phases 2-3): guilds are contracted/signed with a
  god/demon/devil, and the patron shapes how the guild acts (its AI
  personality, prices, taxes, jobs, aggression, who it allies with or
  wars against, e.g. Mammon's guild = greedy taxes + theft, Athena's =
  orderly and defensive). Rival patrons -> rival guilds. Use the being's
  values/rivals as the guild's starting personality.

BLESSINGS (manhwa-style: many beings take an interest; the player chooses):
- Many gods / demons / devils, each with VALUES (like companions; e.g. a God
  of Justice, a Demon of Greed) and an interest level in the player that
  rises/falls with route points and choices. Data-driven + DLC-registrable.
- Offers come all 3 ways: shrines on rest floors once you lean their way,
  a visit after stage bosses, and bargains (gold / item / HP / a promise =
  quest). Accepting is always the player's choice.
- A blessing = a buff with a matching curse, levels that grow as you keep
  serving the being (both buff and curse grow), and a blessed skill.
- Punishment equal to the benefit: acting against the being's values can
  make it PUNISH you (debuffs, smiting), not just withdraw. Stray far enough
  and you lose the blessing (warning first) — but other beings can still
  make you a new offer afterwards.
- NPCs/companions can be blessed too (gives them personality); not a
  party-wide buff.

GUILDS + ECONOMY:
- Guilds own floors/territories and run them however they like: prices,
  taxes on gold earned there, jobs on the notice board, guards/patrols,
  a champion defending each territory. Territory changes over time.
- Guilds "think for themselves": LOCAL game AI (utility/goal-based
  simulation, personalities, resources), NOT an online LLM (no network/API
  keys; game is sold). Each floor climbed = a simulation tick: guilds expand,
  trade, steal, raid, go to WAR with each other.
- Theft both ways: the player can steal from guilds and be stolen from;
  wars between guilds (and the player's guild) while climbing.
- Joining: one guild at a time, reputation + ranks (Recruit -> Member ->
  Officer -> Master) with perks; leaving/betraying angers them.
- Own guild: found it later (floor/level gate + charter cost, you name it),
  members = companions/recruited NPCs, claim floors by beating champions or
  buying them out (income + you set prices), guild hall upgrades.
- Economy: SUPPLY AND DEMAND — prices depend on the ruling guild, standing,
  route and blessings, AND move with supply/demand (selling lots lowers a
  price, scarcity raises it) and events (wars, shortages). Selling gear goes
  to guild traders.

### Layout rule
Every screen must fit the 1280x720 design size (the window scales via
stretch mode canvas_items/expand). The battle field scrolls instead of
growing so the command buttons are always on screen. If Hayden still sees
cut-off screens, ask for his resolution + Windows display scaling.

### Quests + routes (designed with Hayden 2026-10-24)
Part 1 (quests) is BUILT: QuestLibrary (data + validator), QuestLog
(GameState.quests: progress, rewards, expiry, bounties, save), dialogue
hooks, notice board, Tab -> Quests, HUD tracker, quest toasts.
Part 2 (routes) is BUILT: RouteLibrary (routes, endings by priority,
register_* for DLC), RouteState (GameState.route), companion values/warning/
leaving, merchant prices + refusal, black market, route-flavored bounties,
ClassDef.required_route, Hall endings_seen, DlcLoader (res://dlc/<name>/
content.gd + .pck files next to the exe). Hayden wants DLC to be able to add
more routes/endings: keep new route content data-driven and registrable.
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
  placeholder text only, no real story.

Tutorial is deliberately deferred until the game is closer to complete.

Placeholders to confirm with Hayden later: title "Tower Climber",
default friend name "Rowan", Ashbound Knight secret-class details,
FINAL_FLOOR = 30 (long-term target is 100 floors, roguelite-style replayability), tier-2 class names.

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
Every change gets tests in tests/ (18 suites, 1067 checks at last run).
Run headless from the project folder:

    godot --headless --path . --import
    godot --headless --path . res://tests/test_skills.tscn

(Replace `godot` with the Godot 4.7.2 console exe on this PC:
C:\Godot\Godot_v4.7.2-stable_win64_console.exe)
Suites: test_progression, test_combat, test_tower, test_loot, test_save,
test_skills, test_dialogue, test_party, test_elements, test_quests,
test_routes, test_classes, test_blessings, test_guilds, test_guild_ai,
test_presentation, test_screens (opens the real screens), test_difficulty. All must pass before
handing work back.
The Dev Sandbox has a floor picker for testing any floor's enemies/bosses.

## Working with Hayden
- Explain changes briefly; he tests in the editor and gives feedback.
- He often adds requests mid-task — fold them in rather than restarting.
- Ask before big design decisions; small tuning numbers can be proposed.
- He commits with GitHub Desktop (repo: Wozo-bit/Tower-Climber, private).
- No rush: quality over speed, work can span days. Don't cut corners to
  save usage; still commit at safe points (tests passing) on feature branches.
- He plans to SELL the game. So: no assets, fonts, music or code that
  aren't cleared for commercial use (record the license of anything added);
  no other games' names, characters or trademarks in the game itself; keep
  Godot's MIT license notice for release; keep saves tamper-safe (JSON).
