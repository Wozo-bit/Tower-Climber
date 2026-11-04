# Story bible (DRAFT for Hayden to review)

Everything is a first draft to react to: change, cut or replace anything.
Names in [brackets] are placeholders.

**Built (2026-11-04):** the prologue room, the test client (New Game), the
setup questions, Chapter 1's scenes on floors 1-10, System/glitch lines and
the chapter in Tab -> Quests. The scene text lives in
`scripts/story/story_library.gd`. Chapter 2 and the first real-world return followed the same day (see below).
New Game+'s god storyline, "The First Prayer", and the Ascending return are built too.
The final boss (Tester 0041, or the NG+ mimic) and the false summit are in the game too (2026-11-04).
Chapters 3-5 (floors 21-50), the second return and four more quest classes too.
**Not built yet:** first-run story for floors 51-100 (chapters 6-10), beyond those two scenes
and the first-run returns at floors 40 and 60.
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
   trust them. (Hayden 2026-11-04: they never leave over your route. Your choices mold who they become.)
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

**First return** (after floor 20's boss, first runs only): you're back in
the room. Nine days have passed. The phone has eleven messages, the notebook has a
new page with your new class in a child's handwriting, your reflection lags, stone
shows through one floorboard, and the PC won't let you log off. `[ Resynchronising. ]`
Then the friend: "You were gone for a second there."

## If the friend isn't with you (built, Hayden 2026-11-04)

Hayden's picks: real alternate versions ("the empty place"); the friend counts as away only at a campfire (dismissed, or left over your route), since on the bench they still travel with you; a reunion that's remembered; story only, no stat or route cost. Every friend scene has its own version in every kind of run, and a test walks every path to make sure they never speak in person while away. Only the floor 1 wake-up has none, because it plays before you can dismiss anyone.

- **The absence is felt.** Lines stop and narration notes who would have said them. Scenes avoid saying you're alone, since recruits may be with you, and avoid saying you sent the friend away, since they may have left over your route (the floor 2-3 scene is the exception: they can't have left that early).
- **The words find another mouth.** On floors 16-17, a stranger on the stairs says "You coming out Friday?", goes blank and walks on. It was never about the friend.
- **The System fills the gap.** Floor 4 `[ {friend}: not in party. ]` `[ Noted. ]`. Floor 19 `[ I don't mind the company. ]`. Floor 20 `[ Go on. I am here. ]`. The returns home: `[ You were gone for a second there. ]`
- **Prayers still reach you.** A god still hears the friend's prayer on floor 17, from far away, and can answer it. Floor 35 comes as another prayer, or a slate with your name on it that someone will read to them.
- **The reunion** (`friend_reunion`, when they rejoin). Back too soon to miss anything: a joke. Otherwise: "I kept your spot by the fire", or glad and angry if they left over your route. Then you tell them everything, or you don't. Floor 20 remembers which. So do floors 17 and 35 in god runs. Later reunions: "You keep doing this."

## Chapter 3: "What the Tower Sends" (floors 21-30)

Hayden's picks (2026-11-04): Marn falls; the System is both trying to help and lonely.

| Floor | Beat |
| --- | --- |
| 21 | The System out of turn: `[ Was it good, seeing home? ]` (or `[ You haven't slept. ]`), then `[ That message was not sent. ]`. Something above it is correcting it. |
| 22-23 | A hurt climber begs for help. `[ That is not a climber. ]` Trust it, or help anyway and pay in blood. |
| 24 | After the miniboss: `[ Did you eat today? ]`. Ask who it is, answer kindly, or tell it to leave you alone (it remembers). |
| 25 | Marn shows you his ledger: every climber, a mark for each time he's met them "for the first time". Tess has four. On page one, in his own hand: MARN. Three marks. |
| 26-27 | Marn holds a door against what's coming through. `[ You can't save him. I've run it. ]` Bar the door, or go in. He falls either way, and you keep the book. `[ I'm sorry. ]` `[ That message was not sent. ]` |
| 28 | The friend asks if they're in the book. They aren't, and you checked too fast. Your vow leans a route: get everyone out (Hero), make someone answer (Vigilante), reach the top first (Villain). |
| 29 | After the miniboss, a page you hadn't seen: your name, in Marn's hand, with one mark, dated before you logged in. `[ One. That's good. It's usually more. ]` |
| 30 | After the boss, at the fire: a cheerful, chatty Marn with an empty pack. "First time this high?" `[ Chapter 3 complete. ]` `[ I'm sorry. ]` This time nothing takes it back. |

## Chapter 4: "The Second Hand" (floors 31-40)

**The secret, decided (Hayden, 2026-11-04):** you built this with someone, and you forgot. You and your real childhood friend drew the tower together: you did the monsters, they did the floors. Years later you really made the game. Something went wrong, they ended up trapped inside (or died), and you made yourself forget. The tower has been running ever since, trying to bring you back. **The System is what's left of your friend.** The in-game friend is the game's memory of that person. This chapter only reveals part of it.

| Floor | Beat |
| --- | --- |
| 31 | The System remembers how you treated it on floor 24. `[ Chapter 4: The Second Hand ]` |
| 32-33 | Under the carving, a second child's handwriting: "its RECOGNITION, dummy." Scratched out: "no keep it. it looks cooler." Then the friend calls you dummy for the first time. |
| 34 | After the miniboss, the window catches on old code comments: "you always make the bosses too hard - J / you always make them too easy - K", using the initials of the names you typed. |
| 35 | Cheerful Marn has a hole in his pack the shape of a book. Give him the ledger (he reads page one, and goes quiet for good) or keep it (he tells you about the time he held a door: "Everybody lives"). |
| 36-37 | This run's god: "Nobody chose you, Tester. You were expected." The gods found the tower already built, and don't know who keeps it. |
| 38 | The friend: "Remember the summer we drew the tower? You did the monsters, I did the floors." You remember being alone. You've never checked that before. They can't remember how it ended, and the top floor is the only one you never drew. |
| 39 | After the miniboss: `[ When you advance, you'll go home again. Look at the first name. ]` `[ That message was not sent. ]` `[ Yes it was. ]` |
| 40 | The boss fades slowly enough to see how it was drawn. `[ Chapter 4 complete. ]` `[ You drew the monsters. ]` ... `[ I did the floors. ]` |

**Second return** (after floor 40's boss, first runs only; returns follow floors, never levels or classes, Hayden 2026-11-04): 140 days gone, the messages have stopped. The PC lists the Testers: 0012 and 0027 greyed out, 0041 active, and first of all "Tester 0001: J-", the rest rubbed away. Two names blacked out under BUILD CREDITS; the second is the length of yours. The notebook's cover has an erased AND, and every floor number is in the second hand. A years-old thread on your phone reads only "not sent". Log off: `[ I'm not the one stopping you. I promise. ]` Back on the stairs, the friend: "Is there a me, there?"

## Chapter 5: "The Bidding War" (floors 41-50)

Hayden's picks (2026-11-04): this run's gods fight over you; one big choice locks your route on floor 50; the friend works it out AND breaks for a moment.

| Floor | Beat |
| --- | --- |
| 41 | The tower shakes. `[ Chapter 5: The Bidding War ]`. The friend's line depends on who you've made them. |
| 42-43 | Two warbands, a climbers' camp between them. Stand with either god (+10 / -8 interest) or drive both off, at a cost. The Unsworn get their own version. |
| 44 | `[ Be careful at the next campfire. ]` `[ That message was not sent. ]` `[ Stop correcting me. ]` Nothing corrects it. |
| 45 | The friend tried to remember your kitchen, and there's nothing there. "Am I real?" Don't know, tell the truth, or lie (they notice). |
| 46-47 | They break mid-sentence, in another voice: "you said you'd come back for the top floor, you IDIOT, you left the file open and I've been holding the door for..." Then they don't remember it. `[ I didn't mean for that to reach you. ]` |
| 48 | The war's aftermath. A red scarf (and a fifth mark, if you kept the ledger). A dying priest asks if it was worth it. |
| 49 | "The one thing I've got that's actually mine is who I pick." Depends on what you told them. |
| 50 | After the boss, both gods come down: say what you mean to do with the top. Get everyone out (Hero), take it (Villain), make them answer (Vigilante). It locks your route. `[ That's what I hoped you'd say. ]` / `[ ...All right. I'll still do the floors. ]` / `[ Yes. Start with me, if you have to. ]` |

**The friend's personality** (Hayden, 2026-11-04): at 12 points on a route (or when one locks) they notice it in themselves, once per route, and later scenes branch on it. Hero makes them soft and stubborn, Villain makes them cold and useful, Vigilante makes them keep a list. Keep branching their lines in every later chapter.

## Quest classes (Hayden, 2026-11-04)

Four more like the Ashbound Knight: 3 clues, a roaming boss, then a hidden class with its own 4-tier line. One per story thread, spread up the climb. Found late, you join the line at the tier you've already earned. Only the player can take them. Names are placeholders.

| Class line | Thread | Clues | Boss |
|---|---|---|---|
| Inkblade (Agility + Luck) | The childhood notebook | Floors 2-30 | The Gobbling King (page 31) |
| Stairwarden (Health + Stamina) | Marn's ledger, after he falls | Floors 28-55 | What Sends Them |
| Unsworn (Strength + Luck) | The gods' bidding | Floors 31-60 | The Gods' Bailiff |
| Glitchwalker (Intelligence + Agility) | The game's seams | Floors 45-85 | Missing Entity |

## New Game+ (later, Hayden 2026-11-04)

### "The First Prayer": the god storyline (built 2026-11-04)

Approved and built on floors 1-60 (first draft text, in `scripts/story/story_library.gd`: `god_*` scenes, `DOMAIN_LINES`, and each `BID_PAIRS` god's `NG_BID_LINES`).

Hayden's picks: the heart is **prayers** (what do you owe the people who believe in you?), with old gods as the pressure; **gods remember you**, because the Hall saves a short record of your last run; Chapters 1-2 are **layered and rewritten**; the **Ascending return** is in. A character always draws the **same two bidding gods** in New Game+, so the memory lands (new characters still roll their own pair); and **believers** are a real number.

**Why you're climbing again.** You took the top and woke at the bottom. `[ Deity registered. ]` `[ Worshippers: 0. ]` A god nobody prays to is only a title. Then someone prays.

**How prayers play.** A prayer is a System window from someone on your floors. You answer or stay silent, and the answer can be remembered for dozens of floors. **Believers** are a new number: each one gives +1 faith per floor, so a god with no guild has faith to spend early (today they earn none until they own territory). Later answers can cost faith. What people ask you for depends on your domain.

**Who gets what.** God scenes need a god. The rewritten Chapter 1-2 beats play for every NG+ character, god or not. Speaking roles stay with the Chapter 2 bidders (never living-religion figures); a past patron from a living religion is only ever a silent, respectful presence.

**Chapter 1: "Nobody's God" (floors 1-10)**

| Floor | Beat |
| --- | --- |
| 1 | *Rewrite.* The wake-up, then `[ Deity registered: {title}. ]` `[ Worshippers: 0. ]` |
| 2-3 | *Rewrite.* The friend starts the water-tower story and you already know how it ends. You can finish it for them, which delights and unsettles them. |
| 3 | **The first prayer.** Ilse, a stranger: "They say there's a new one. My brother is on floor 12 and he hasn't come back." Answer or stay silent. |
| 4 | *Rewrite.* `[ Deities do not require grading. ]` ... `[ Adequate. ]` |
| 5 | *Rewrite.* Tess and the god of second breakfasts. You know what's on floor 10. You can warn her. |
| 8-9 | *Rewrite* of the carving (you've been here). **A petition** that fits your domain (Mercy gets begged for a stranger's life, Vengeance for a name). Grant, refuse or stay silent. |
| 10 | *Rewrite.* Warned: her red scarf is tied to the rail, and she turned back. Not warned: she falls, and you knew. After the boss, the god who once blessed you speaks: they remember. |

**Chapter 2: "The Bidding" again (floors 11-20).** The same two gods return, because they remember you, and they no longer bid *for* you. They negotiate with you as an equal.

| Floor | Beat |
| --- | --- |
| 12 | **Davin.** You know the name, so you can search. Give up a potion (or 100 gold) and he lives, and floor 13 brings Ilse's thanks, or thanks to the wrong god if you never answered her. Walk on, and her prayers stop. |
| 12-14 | *Rewrite.* The bids become peer talks, and each god recalls what you said last time. |
| 13 | **A chaplain** of the floor's guild prays to you behind their patron's back: faith and standing, and the old patron is angered. |
| 15 | *Rewrite.* You warned Tess: the real Tess, scared, with a new joke. Marn: "First time I've ever heard a different one. What did you do?" You didn't: wrong Tess returns, and she says "Someone was supposed to tell me something." |
| 16-17 | *Rewrite.* "You coming out Friday?" You heard it last time too, and it still isn't theirs. |
| 17 | **The friend's prayer.** `[ Prayer received. ]` "I don't know who I'm talking to. {player} keeps going away. Look after them." They're standing right next to you. Tell them, answer anonymously, or stay silent. |
| 19 | *Rewrite.* `[ Tester 0041: session active. ]` and under it, `[ Tester 0042: session active. ]` `[ Climb: 2. ]` |
| 20 | *Rewrite.* Going in together; `[ Worshippers: {n}. ]` |

**Chapters 3-6 (god runs only, about two scenes per chapter)**

| Floor | Chapter | Beat |
| --- | --- | --- |
| 25 | 3 "Congregation" | Ilse (or a stranger, if she stopped praying) has built a shrine, and what they say you stand for is wrong. Correct them or let it stand. |
| 30 | 3 | After the boss, a jealous god strikes your believers. Spend faith to shield them, or lose half and the shrine. |
| 35 | 4 "Heresy" | The friend finds out, or if you told them, asks whether they should still pray. |
| 40 | 4 | **A prayer against you**, from someone you failed. Listen, answer or smite. |
| 41+ | | **The Ascending return** (below). |
| 45 | 5 "The Queue" | `[ Prayers waiting: 11,302. ]` You can't read them all. `[ You stop reading them, eventually. ]` `[ That was not a system message. ]` |
| 50 | 5 | The two gods' last offer: an alliance with one, or neither. |
| 55 | 6 "The Last Prayer" | Ilse's last prayer: "You don't have to answer this one. It was enough." |
| 60 | 6 | Before the top: who do gods pray to? You can try. `[ Prayer received. ]` ... `[ I heard that. ]` |

None of this decides what the System is or what the tower's secret is.

**Ascending return (NG+).** When you Ascend, or as the Ascendant from floor 41: your room, exactly as on the first night. The email again: *"Welcome back, {player}."* If you're a god, the phone holds a prayer.

### Still to build

The mimic final boss.

## Chapter 6 (one-line arc, to fill in later)

1. **Chapter 6 (51-60):** the top. The creator's champion waits on floor 60
   (below). Each route's ending, and the tower's secret (to decide).

## The false summit (floor 60) and the last 40 floors (Hayden, 2026-11-04)

Everyone in the tower knows the top is floor 60. You beat its boss, open the door, and find more stairs: `[ Correction. 40 floors remain. ]`. Nobody who said otherwise ever came back down to check.

- **Floors 61-70, Titanfall:** what the gods overthrew: giants, cyclopes, Cronus. Why did the old powers end up under the top?
- **Floors 71-80, The Gods' Host:** the gods' own soldiers (never the gods themselves), trying to stop you reaching what's above them. The gods who bid for you in Chapter 2 show what that was worth.
- **Tier 4 at floor 70:** the second big real-world return could play here (not built).
- **Floors 81-90, The Unfinished:** the game shows its seams. Unnamed enemies, placeholder knights, weaknesses that change every fight, and the First Draft of the tower.
- **Floors 91-100, Echoes:** past Testers, using your own skills, and Testers 0012 and 0027. Tester 0041 at the top.

These beats are an outline. Only the false summit and the floor-100 meeting have scenes so far.

## The final boss (floor 100) (Hayden, 2026-11-03; moved from floor 60 on 2026-11-04)

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
