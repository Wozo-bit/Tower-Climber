# Assets: art and sound drop-in guide

The game draws coloured shapes and plays nothing until real files exist.
Drop a correctly named file into the right folder and the game uses it.
You don't need any code changes. Anything missing keeps its placeholder.

**Every file you add must be listed in `credits.json`** with its author and
license. `test_presentation` fails if a file isn't credited or its license
doesn't allow selling the game (see "Licenses" below).

## Art (`assets/art/<kind>/<id>.png`, also .webp / .jpg)

| Folder | File name | Used for | Suggested size |
|---|---|---|---|
| `enemies/` | enemy id, e.g. `goblin_king.png` | battle card, floor token, boss cut-in | 256×256, transparent |
| `portraits/` | `player`, a companion's id, an NPC id, or the speaker's name in snake_case (`merchant`) | party cards, dialogue faces, skill cut-ins | 512×512 |
| `classes/` | class id, e.g. `rogue.png` | fallback face for anyone of that class | 512×512 |
| `beings/` | being id, e.g. `odin.png` | shrines, dialogue, god cut-ins | 512×512 |
| `guilds/` | guild id | emblems (champion and war cut-ins) | 256×256 |
| `backgrounds/` | stage theme id (`goblin_warrens`), `battle` (any fight), `title` | battle and title backdrops | 1920×1080 |
| `tiles/` | `<theme>_floor`, `<theme>_wall`, or plain `floor` / `wall` | floor map tiles | 72×72 |
| `props/` | `stairs`, `campfire`, `merchant`, `board` | floor map props | 72×72 |
| `tokens/` | `player`, enemy id, NPC id, being id | small map pieces (falls back to enemy/portrait art) | 72×72 |
| `items/` | item id | icons in battle menus | 64×64 |
| `skills/` | skill id | icons in battle menus | 64×64 |
| `cutins/` | enemy id, being id, `skill_<skill id>`, `class_<class id>`, `war_<guild id>`, `level_up` | splash art (falls back to the art above) | 840×500 |

Ids are in the data files: enemies in `scripts/combat/enemy_library.gd`,
classes in `class_registry.gd`, beings in `being_library.gd`, guilds in
`guild_library.gd`, stage themes in `stage_library.gd`.

## Music (`assets/audio/music/<name>.ogg`, also .mp3 / .wav)

Each situation tries a list of names and plays the first one that exists.
That means you can start with only `explore`, `battle` and `boss`, then add
variety later.

* **Floors:** `floor_<n>`, then `explore_<theme>`, then `explore_<family>`, then `explore`
  (rest floors try `rest_<theme>` and `rest` first)
* **Battles:** `battle_<enemy id>`, then `battle_<family>`, then `battle_<theme>`, then `battle`
* **Minibosses:** `miniboss_<enemy id>`, then `miniboss_<family>`, then `miniboss_<theme>`, then `miniboss`, then the battle list
* **Bosses:** `final_boss` (last floor only), then `boss_<enemy id>`, then `boss_<family>`, then `boss_<theme>`, then `boss`, then `battle`
* **Roaming bosses:** `roamer_<roamer id>`, then `roamer_<enemy id>`, then `roamer`, then `boss`
* **Guild fights:** `champion_<guild>` / `guild_<guild>`, then `champion` / `guild_battle`, then `battle`
* **Menus:** `title`, `credits`

Families are `goblin`, `slime`, `orc` and so on; themes are stage ids like `goblin_warrens`.
A stage can also name its tracks in `StageLibrary.THEMES` with
`"music": { "explore": ..., "battle": ..., "boss": ..., "rest": ... }`.

**Variety:** `battle_goblin.ogg`, `battle_goblin_2.ogg` and `battle_goblin_3.ogg` are
treated as versions of one track, and one is picked at random. The same works for sounds.
Tracks loop automatically, and the game crossfades between them.

## Sound effects (`assets/audio/sfx/<name>.ogg`)

* **Interface:** `ui_click` (every button), `system` (system notices), plus
  `system_quest` / `system_route` / `system_blessing` / `system_guild` to give
  each kind its own chime
* **Battle:** `encounter`, `encounter_<kind>` (e.g. `encounter_boss`), `hit`,
  `hit_<element>` (`hit_fire`, `hit_ice`, ...), `crit`, `weak`, `stagger`, `resist`,
  `absorb`, `immune`, `miss`, `heal`, `status`, `scan`, `defend`, `item`,
  `down_enemy`, `down_ally`, `victory`, `defeat`, `flee`, `level_up`
* **Cut-ins:** `cutin`, or `cutin_<kind>` (`boss`, `miniboss`, `roaming`, `champion`,
  `skill`, `being`, `level_up`, `advance`, `war`)
* **Floor:** `encounter_flash`, `stairs`, `campfire`, `talk`, `talk_<dialogue id>`
* **Shop:** `buy`, `sell`, `coin` (fallback for both), `steal`, `caught` (or `alarm`)

## Licenses (`credits.json`)

```json
{
  "name": "Pack or track name",
  "author": "Who made it",
  "license": "CC0",
  "url": "where you got it",
  "kind": "art",
  "files": ["art/enemies/goblin*.png"]
}
```

`kind` is `art`, `music`, `sfx` or `font`. `files` takes paths under `assets/`,
and `*` wildcards work. The allowed licenses are in `Credits.LICENSES`:
`CC0`, `CC-BY-3.0`, `CC-BY-4.0`, `CC-BY-SA-3.0`, `CC-BY-SA-4.0`, `OFL-1.1`, `MIT`,
`Commercial license` (bought or commissioned with commercial rights) and `Own work`.
**Never** use NonCommercial (NC), NoDerivatives (ND), "personal use only",
RPG Maker-only resources, or anything ripped from another game or comic.

The credits screen (title screen, then Credits) lists everything in `credits.json`,
then Godot's MIT license and the engine's third-party licenses, which a
shipped game must include.
