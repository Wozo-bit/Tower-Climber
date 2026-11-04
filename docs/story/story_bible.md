# Story bible (DRAFT for Hayden to review)

Everything is a first draft to react to: change, cut or replace anything.
Names in [brackets] are placeholders.

**Built (2026-11-04):** the prologue room, the test client (New Game), the
setup questions, Chapter 1's scenes on floors 1-10, System/glitch lines and
the chapter in Tab -> Quests. The scene text lives in
`scripts/story/story_library.gd`. Chapter 2 and the first real-world return followed the same day (see below).
**Not built yet:** chapters 3-6, the final boss (previous Tester / NG+ mimic)
and the later real-world returns.
Chapter 1's campfire climbers are named Tess (red scarf, falls on floor 10)
and Marn (the old one); the notebook's cover misspells the name as
"THE TOWER OF RECONGITION", and the floor 8-9 carving has the same mistake.

## Hayden's decisions (2026-11-03)

| Question | Answer |
| --- | --- |
| Why climb | The tower's legend (reach the top, become a god) **plus** a System that chooses you |
| Tone | Grim but hopeful: friendship and growth at heart, real losses, nothing sugar-coated |
| The tower's secret | Decide later |
| Story amount | One chapter per 10-floor stage (6 chapters for 60 floors) |
| The System | A hidden personality: it slowly turns out to be *someone* |
| Why you | A hidden reason, revealed in a later chapter |
| Premise | A game inside a game: you're invited to test a game and get pulled into it |
| Prologue | Playable, in the real world, then you're pulled in |
| The friend | Lives in the game, and knows you as a lifelong friend you've never met |
| Your knowledge | The game knows you too well: details match things only you could know |
| Dying | "It's just a game... right?" Everyone assumes death resets; later chapters cast doubt |
| Final boss | Not the tower's creator, but the champion the creator **sponsors**. In New Game+, a **mimic of your previous run's character** |

## The premise in one paragraph

You get an invitation to the closed test of a game nobody has heard of:
**Tower of Recognition**, "a tower that makes gods". Late at night you log in, and the
character setup asks strange questions, ending with *"Name the person you
trust most."* Then the screen breaks. You wake on cold stone at the foot of a
tower, and someone with the name you just typed is shaking you awake, telling
you that you fell asleep on watch *again*. They've known you all your life;
you've never seen them before. The other climbers say whoever reaches the top
becomes a god. A System window only you can see says you were selected. And
the tower keeps showing you things from your own childhood.

## The three threads

1. **The friend.** Warm, loyal, funny, and impossible. They remember a shared
   childhood that is *almost* yours: the right street, the wrong house; your
   real treehouse, but a game-world tree. The player decides how much to
   trust them. (Existing hook: they can still leave on some routes.)
2. **The System.** It starts as cold, formatted windows. Now and then it
   slips: a word of praise, a pause, a correction ("[ Adequate. ]" becomes
   "[ Floor cleared. ]"). Over the chapters it becomes clear the System is
   *someone*, with opinions and maybe a stake in your climb.
3. **The game that knows you.** Carvings, floor layouts and enemy names echo
   your real life (an old notebook of tower drawings from when you were a
   kid). Why you were chosen is tied to this, and is revealed later.

## Characters

- **You (the player).** A tester from the real world. The player picks name
  and build as now. Grounded, a bit tired, curious.
- **[The friend]** (default name: Rowan, set by the setup question). Grew up
  "with you" in the game world. Brave, warm, teases you. Never doubts you,
  which is its own kind of unsettling.
- **The System.** Speaks only in [ ] windows. Personality leaks in slowly.
  What it is: decide later (options: the game's creator, a past tester, a
  god, the tower itself, a version of you).
- **The gods** (existing beings). They call you "the Tester" behind your
  back, and argue over whether you're a threat or a chance.
- **Other climbers** (existing recruits and guilds). They live and die by the
  tower. Some don't come back after dying, which is the first crack in "it's
  just a game".

## Prologue (playable, about 5 minutes)

A small walkable room in the real world, at night. Things to interact with:

- **The PC:** the invitation email: *"You have been selected for the closed
  test of Tower of Recognition. One tester per region. Do not share this invitation."*
  Using the PC starts the test (below).
- **The bookshelf:** an old notebook full of tower drawings you made as a
  kid, with floors numbered and monsters named. (The first seed of "the
  game knows you".)
- **Your phone:** a couple of ordinary messages (a friend asking if you're
  coming out, a bill reminder). This is the life you're about to leave.
- **The window:** the city at night, and your reflection.

**The test client** is the existing New Game flow, reframed as the game's
setup screens:

1. "Tester name" (your name), then difficulty and Ironman as now.
2. A couple of odd questions: *"What do you want most?" / "What are you
   afraid of losing?"* Each answer (Hayden: both) gives a couple of
   starting stat points **and** a small nudge: a little route lean, or one
   god notices you first. Remembered for callbacks later.
3. *"Name the person you trust most."* This is the existing friend-naming
   step; the default is [Rowan].
4. `[ Tester confirmed. ]` → `[ Synchronising... ]` → (glitch) `[ Welcome home. ]`
   Then the screen breaks and you're pulled in.

## Chapter 1: "Tester" (floors 1-10)

Draft beats. Each one is a short scene (3-6 dialogue screens) or a lore
object, using systems that already exist.

| Floor | Beat |
| --- | --- |
| 1 | You wake. [Friend] is there: "You fell asleep on watch again." You don't know them. The System: `[ Synchronisation complete. ]` First fights; the tutorial tips start. |
| 2-3 | Walking talk: [Friend] brings up "remember when we..." memories. One detail matches your real childhood exactly. You can play along, ask questions, or say you don't know them (each answer is remembered). |
| 4 | Miniboss. Afterwards the System slips: `[ Adequate. ]`, corrected a moment later to `[ Miniboss defeated. ]` |
| 5 | Rest floor, first campfire. Other climbers tell the legend (the top makes a god). An old climber says the dead don't come back. [Friend] laughs it off; your character thinks *it's just a game.* |
| 6-7 | A route choice: a wounded climber who robbed others. Help them (Hero), take what they stole and leave them (Villain), or make them answer for it (Vigilante). |
| 8-9 | A carving on the wall matches a drawing from your childhood notebook, down to the misspelled monster name. [Friend] has never noticed it. |
| 10 | Boss. Before it, a climber you met at the campfire falls in a fight and doesn't respawn. After it: the boss's patron god takes notice ("So you're the Tester."), and the System: `[ Chapter 1 complete. ]` ... `[ You remembered faster this time. ]` |

The last line hints you've been here before (kept, Hayden 2026-11-03). It
pays off with the previous Tester and the NG+ mimic, and can still be
reinterpreted later, so it doesn't lock in the secret.

## Chapter 2: "The Bidding" (floors 11-20)

Hayden's picks (2026-11-04): the gods bid for the Tester; the friend knows too
much; Tess comes back wrong; the room returns on your first advancement.

| Floor | Beat |
| --- | --- |
| 11 | `[ Chapter 2: The Bidding ]`. Word has climbed ahead of you. The friend asks what "the Tester" means. |
| 12-13 | The first god's bid: patient, and pays in truth. Listening: that god +8 interest, the rival -3. A small truth: **there was a Tester before you** (the rumour stage of the previous Tester). |
| 14 | After the miniboss, the rival's counter-bid: temptation, and the core of it, that **you can leave** and nobody else can. The System slips: `[ Do not listen to that one. ]`, then `[ Notice dismissed. ]`. |
| 15 | The campfire: Tess is back, same scarf, same joke, no memory of you or of dying. The friend: "See? Told you." Marn: "Fourth time I've met that girl... I didn't say it doesn't send something." |
| 16-17 | The friend says the exact phone message from the prologue, "You coming out Friday? Everyone's asking.", and doesn't know why. Press them, lie, or tell them the truth about your room (they believe too much of it). |
| 18 | The floor's guild, threatened by both gods, wants you on its side: stand with them (Hero), sell out (Villain), or tell them off (Vigilante). |
| 19 | After the miniboss, a window not meant for you: `[ Tester 0041: session active. ]` `[ Session length: 11,302 days. ]`, then `[ Display error. Disregard. ]`. Thirty-one years. |
| 20 | Going in together (changes if you told them about the room). After the boss: whoever you listened to claims you, or both keep bidding. `[ Chapter 2 complete. ]` `[ You will want to see home first. If you can. ]` |

**Who bids changes per run** (Hayden, 2026-11-04): Odin and Loki, Zeus and Typhon, Ra and Apep, or Anubis and Set, each with their own lines (`StoryLibrary.BID_PAIRS`). Pairs must be enemies in their own myths. You draw the pair you already lean toward, a blessing from either settles it, and each run rolls some luck. Figures from living religions stay out of it.

**First return** (the player's first tier-2 class, first runs only): you're back in
the room. Nine days have passed. The phone has eleven messages, the notebook has a
new page with your new class in a child's handwriting, your reflection lags, stone
shows through one floorboard, and the PC won't let you log off. `[ Resynchronising. ]`
Then the friend: "You were gone for a second there."

## New Game+ (later, Hayden 2026-11-04)

More story in New Game+, including a **god storyline**, to be designed later. Today NG+ only has its own wake-up scene and skips the real-world returns; the Ascending return and the mimic final boss are also still to build.

## Chapters 3-6 (one-line arcs, to fill in later)

1. **Chapter 3 (21-30):** doubt. Someone close falls and doesn't come back.
   The System talks more like a person.
2. **Chapter 4 (31-40):** the past. Why you were chosen starts to surface
   (the notebook, who made the game).
3. **Chapter 5 (41-50):** the gods' war over the tower; routes lock in.
4. **Chapter 6 (51-60):** the top. The creator's champion waits on floor 60
   (below). Each route's ending, and the tower's secret (to decide).

## The final boss (floor 60) (Hayden, 2026-11-03)

The creator of the tower never fights you directly. Like every god, it
**sponsors** someone, and its champion is the last thing between you and
the top. This fits the systems that already exist: bosses have god patrons,
and gods sponsor guilds and champions.

- **First run: the previous Tester.** Someone invited before you, who
  reached the top and was kept there as the creator's champion. Their story
  mirrors yours, which sets up the mimic. Foreshadowed in earlier chapters
  as a rumour, then a name, then a face.
- **New Game+: a mimic of you and your party.** The creator's new champion
  is a copy of your character as they were when you last conquered the
  tower (name, class, skills, gear, that run's strength plus NG+ scaling),
  fighting beside mimics of the companions you had at the end of that run.
  Your current party against your old one. If you became a god, the mimic
  carries your god title. It pays off `[ You remembered faster this time. ]`:
  the tower remembers you too.
- **How it would work:** the Hall of Climbers already saves the conqueror's
  whole character (`LegacyRecord.character`: class, stats, skills, gear;
  also the friend's name and god title). It doesn't save the companions yet:
  the completion screen would also snapshot the fighting party. The mimics
  are built from those snapshots and use their real skill lists. A run with
  no past conqueror gets the previous Tester.

## Returns to the real world (Hayden, 2026-11-04)

The real world comes back at the big milestones, as short playable visits
to your room (the prologue room, reused). Each time, a little more is wrong
with it, and something from the tower has followed you.

| When | Draft moment |
| --- | --- |
| Tier-2 class advancement (floor 20) | You blink awake at your desk, the game client open. It feels like a dream, until the phone shows days have passed. The notebook has a new page you don't remember drawing: your new class. |
| Tier-3 class advancement (floor 40) | The room is quieter. Messages from friends have stopped. The PC shows a list of testers; most names are greyed out. One is the previous Tester. |
| Before the final boss (floor 60) | The room is half tower: stone through the floorboards. The window shows the city, and your reflection is the champion. You can still log off... can't you? |
| Ascending (NG+) | Your room, exactly as on the first night. The invitation email again, but addressed to your old name: *"Welcome back."* |

Each visit ends with the System pulling you back in (`[ Resynchronising. ]`),
and the friend is waiting: "You were gone for a second there."
They're optional to explore but short (1-3 minutes), and a setting can skip
them like the prologue.

## How it would work in the game (for later)

- A **prologue scene**: a small walkable room, before the New Game naming
  screens. Skipped in New Game+, with a "Skip prologue" option in settings.
  The same room is reused for the real-world returns (its objects change).
- **Story scenes**: dialogue that starts on its own when you enter a floor,
  meet a guardian, or beat one (`StoryLibrary`, data like the dialogues,
  validated by tests). A **chapter** marker in the Quests log.
- **System lines**: the existing system window, with a "glitch" style for
  the slips.
- **Remembered answers** (flags) that later chapters can call back to, and
  route points from the big choices.

## Open questions for Hayden

None right now.

Answered: the real world comes back at major milestones (class advancements,
before the final boss, Ascending); the game inside the game is called **Tower of Recognition**
(placeholder, 2026-11-04); setup questions give stats + a nudge; keep "You
remembered faster this time"; final boss = the previous Tester, NG+ = a
mimic of you and your old party.
