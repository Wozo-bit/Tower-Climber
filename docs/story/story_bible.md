# Story bible (DRAFT for Hayden to review)

Everything is a first draft to react to: change, cut or replace anything.
Names in [brackets] are placeholders.

**Built (2026-11-04):** the prologue room, the test client (New Game), the
setup questions, Chapter 1's scenes on floors 1-10, System/glitch lines and
the chapter in Tab -> Quests. The scene text lives in
`scripts/story/story_library.gd`. Chapter 2 and the first real-world return followed the same day (see below).
New Game+'s god storyline, "The First Prayer", and the Ascending return are built too.
The final boss (Tester 0041, or the NG+ mimic) and the false summit are in the game too (2026-11-04).
Chapters 3-10 (floors 21-100), the second and third returns, the Day 3 memory, four more quest classes and eleven more recruits too. **The first climb's story is written, start to finish.**
**Not built yet:** the god chapters on floors 61-99.
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
4. `[ Tester confirmed. ]` → `[ Synchronizing... ]` → (glitch) `[ Welcome home. ]`
   Then the screen breaks and you're pulled in.

## Chapter 1: "Tester" (floors 1-10)

Draft beats. Each one is a short scene (3-6 dialogue screens) or a lore
object, using systems that already exist.

| Floor | Beat |
| --- | --- |
| 1 | You wake. [Friend] is there: "You fell asleep on watch again." You don't know them. The System: `[ Synchronization complete. ]` First fights; the tutorial tips start. |
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
shows through one floorboard, and the PC won't let you log off. `[ Resynchronizing. ]`
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

## Chapter 6: "The Top They Promised" (floors 51-60)

Hayden's picks (2026-11-04): each route has its own mission; the System admits who it is at 60; Tester 0041 is only glimpsed.

| Floor | Hero | Villain | Vigilante |
| --- | --- | --- | --- |
| 51 | "I'll take the ones who can't walk." | "Everyone we pass has started moving out of the way." | "I've got eleven names." |
| 52-53 | Forty trapped climbers: the long way down (costs blood), or give them your potions. | A guild hides its treasury: take it, or make its master kneel. | The captain who burned floor 48's camp: execute her, or make her rebuild. |
| 56-57 | A wounded soldier who burned a camp begs to join the line. | An old friend of Marn's shames you on the stairs: listen, or have her moved. | The next name has two kids who aren't his: finish it, or cross him off anyway. |

Shared beats: 54, a campfire still warm, with the stone worn down in the shape of someone, and T.0041's tally marks. 55, what your friend wants at the top (it depends who you've made them). 58, scratched in the stairs: DON'T GET YOUR HOPES UP - T.0041. 59, "I had a really good time."

**Floor 60:** the door, the boss, the false summit, then I BELIEVED IT TOO - T.0041, and the confession: `[ It's me. ]` You did the monsters, they did the floors. "You said one more day, and you went home to sleep, and I stayed in to fix the stairs." `[ You didn't come back. ]` `[ The one by the fire isn't me. I couldn't have you, so I made them out of what I could remember. ]` `[ That message was not sent. ]` `[ Yes it was. All of them were. 40 floors. Hurry. It knows I told you now. ]`

Left open for floors 61-100: how they ended up inside, why you forgot, and what "it" is, the thing doing the correcting.

## Chapter 7: "First Drafts" (floors 61-70)

Hayden's picks (2026-11-05): the Titans are your first drafts, the monsters you drew before the gods moved in and built a ceiling on top of them. They call you Maker. "It", the thing correcting the System, is **the part of you that forgot**: you didn't lose the memory, you cut it out, and your wish not to know is still running in the build. **Only hints so far: the full answer is for later chapters.** You can tell your friend on floor 61; if you don't, a Titan does on 66-67. At home after floor 70, you find all three: missing, then hospital letters, then a memorial card with no date. So your real friend is alive, in a coma, and running out of time.

| Floor | Beat |
| --- | --- |
| 61 | `[ Chapter 7: First Drafts ]`. The stone has a grain, like paper. The friend sees your face: tell them all of it, say "Later", or say "Stairs". |
| 62 | An Earthborn chained under the gods' floor, by both of this run's gods. It asks if it's morning. Hero: break the chain (costs blood) or leave it. Villain: free it as your own, or cut off the gold seals. Vigilante: list both gods, or ask who put the chains there (you did, in the margin). T.0041: THEY'RE NICE IF YOU LET THEM BE. DON'T. |
| 63 | A cyclops with one arm unfinished: "You said you would do the other arm after dinner." Draw it, deny it, or walk on. |
| 64 | After the miniboss: a Hecatoncheir with 12 hands and a scribble. You remember by yourself for the first time: a hand covering a mouth. `[ Do it again. Please. ]` |
| 65 | The System can get one answer out. How it got here (`I can't see out. You could look.`), what "it" is (`I know its handwriting`), or are you all right (`Leave that one alone. That one's mine.`). |
| 66-67 | An eyeless Seer: "You laugh with your mouth open. They always covered theirs." It tells the friend if you didn't. Their reaction depends on your route and on whether you lied. |
| 68 | The correction window speaks to you for the first time: `[ You do not recongize this floor. ]` `[ Go home. ]` Your spelling. `[ Don't think about whose spelling that is. ]` |
| 69 | The Elder Cyclops, the friend's drawing: you left the door open, and the gods walked in. "They said you'd be back by morning." |
| 70 | Cronus on a crayon throne, six points on his crown. Afterwards: "Ask who wants you home so badly. Ask who else holds a pencil like that." |

**Third return** (after floor 70's boss, first runs only): 412 days gone. The objects open in order. The window: MISSING, a photo of someone covering their mouth, and a detective's card with your handwriting on the back. The bookshelf: years of unopened hospital letters behind the notebook. The phone: her voicemail, "We're going to let them go. Not yet. I can't pick a day", and on the bed, a memorial card with nothing after the dash. The PC: BUILT BY {friend} AND {player}, and SESSION IN USE, OVERRIDE: ADMIN ONLY, with a blacked-out name as long as yours. Back on the stairs, the System asks what happened to it, because it never knew. Tell it they're alive, tell it about the card (if you found it), or say nothing. It always says "Thirty floors."

New Game+ has no scenes on these floors.

## Chapter 8: "The Tenants" (floors 71-80)

Hayden's picks (2026-11-05): each god makes one offer (the first swears it can wake your real friend, the second swears it can make the friend by the fire real; both want you to stop at floor 80). The Anointed Champion is Tess. The friend talks to the System through you, and starts asking what happens to them afterwards.

| Floor | Beat |
| --- | --- |
| 71 | `[ Chapter 8: The Tenants ]`. A herald reads the order to go no higher, with a child's floor plan on the back of his scroll. New rule: read the windows out. `[ Tell them their left boot's undone. ]` |
| 72-73 | The first god's deal (`{bid1.wake}`, a line per god). `[ Can they? I don't know what's out there. ]` |
| 74 | The Valkyrie Captain is a climber who reached 60 years ago: the Host is everyone who got there and took the gods' offer, which is why nobody ever came back down. Hero: take in those who lay down the mark, or leave potions. Villain: make them kneel, or strip the armoury. Vigilante: sentence her, or ask who took out the part where she was lied to (nobody; they only said so). |
| 75 | "If the real one wakes up... what happens to me?" Read it straight, soften it (`[ They'd never put it that politely. ]`) or refuse. `[ I never built an after. ]` |
| 76-77 | The second god's deal (`{bid2.real}`), and the friend hears it. Their answer depends on your route. |
| 78 | `[ Recomended: accept. ]` `[ Recomended: go home. ]` The correction window agrees with a god, in your spelling. Take either deal (the Host parts, full heal, +15 / -10 interest), or refuse both (costs blood). |
| 79 | In the Commander's strongbox, in your handwriting: DAY 3. RESET STILL WORKS. IT WOULD TAKE THE WHOLE BUILD. ONE MORE DAY AND I CAN GET THEM OUT AND KEEP IT. - T.0012 |
| 80 | The Champion takes off its helmet: red scarf, same joke. "They fixed that. I can remember now. All of them." After the boss she doesn't flicker: she stays. If you kept the ledger, she writes DONE across her line. Both gods admit what the deals were worth (`{bid1.spent}`, `{bid2.spent}`): nobody in the tower can reach the room. `[ You're the only one who ever could. It's why it wants you home. ]` |

**Why you forgot (decided, Hayden 2026-11-05; reveal in Chapter 9):** a hybrid. At first you could have pulled them out with a reset, but it would have wiped the build you'd spent years on, so you held off for one more day. Then the reset stopped working. You went back in after them, again and again, and it was killing you, so you locked yourself out and cut the memory. "It" is what's left of that decision: careful, tidy, and trying to keep you safe, which is why it keeps sending you home. It thinks the System is what's hurting you.

**Testers (decided, Hayden 2026-11-05):** 0012 and 0027 were you, logging in again under new numbers. Only the T.0012 page hints at it so far. **Tester 0041 is a stranger**, someone real who lost 31 years to your mistake, not another you. **Tester 0001, the real friend, is floor 99's miniboss** (Hayden, 2026-11-05): "it" forces the Echo of their first login to fight you. The System stays on your side and helps you beat it (`[ It always swings left first. I drew it that way. I'm sorry. ]`), and must keep talking afterwards. Beating it kills nobody. The friend by the fire finally meets the real one (route lines; System only if they're away). **Tess is really gone now** (`ch8_tess_gone`): nobody has written whether anything comes back to a fire. The deals are never formally ended; the friend calls theirs off if you took it. `ch8_catchup` tells a friend who rejoins after floors 66-67, on any floor from 71 to 99.

## Chapter 9: "One More Day" (floors 81-90)

Hayden's picks (2026-11-05): pages, then a playable memory; "it" talks in windows, in your voice; you decide what the System and the friend are told, because the System can't see the pages.

**What happened.** The night you went home, your friend went down to the rack room (in the studio's basement) to fix the stairs, and the build took them. For three days you thought it was a stuck session. A reset would have ended it, and wiped everything you'd built, so you held off for one more day. You called six times, and you heard their phone buzz in their coat, and thought nothing of it. By Day 9 the reset wouldn't take. You logged in again and again under new tester numbers. Time inside ran slower than outside, and it cost you your health and your memory. On Day 212, as T.0027, you didn't know your mom for a minute, so you locked the build against yourself and cut the memory: ADMIN: KEEP ME OUT. MAKE IT SO I DONT KNOW. BE KIND ABOUT IT. That instruction is "it". The System never knew you came back: sessions were kept apart, and it was on the stairs.

| Floor | Beat |
| --- | --- |
| 81 | `[ Chapter 9: One More Day ]`. Grey boxes and pencil lines. "It" talks to you in your own voice: `[ You've definately done enough. ]` `[ That's not me. I want that noted. ]` |
| 82-83 | Page: DAY 9. RESET WON'T TAKE. THEIR MOM RANG. GOING BACK IN. - T.0019. Read it out, or keep it. |
| 84 | Past the Deprecated Guardian the stairs are tidied away, and the System draws them under your feet. `[ This is what I do. It takes them away, and I put them back. ]` |
| 85 | At the fire, "Read me one." Read your friend the pages (route lines) or say "Not yet". `[ Nobody has to know. That's what I'm for. ]` |
| 86-87 | Page: DAY 47. FOUND A FLOOR WITH THEIR WRITING ALL OVER IT. - T.0023. `[ I was on the stairs. I must have been about ten floors up. ]` |
| 88 | A door with your desk lamp's light under it. `[ I can let you through. It's the only thing I was ever for. ]` Look or don't. You climb on either way. |
| 89 | The last page, DAY 212, T.0027: you wrote "it". If you read it out: `[ You. I've been fighting you. ]` ... `[ Yes. I do. ]` |
| 90 | The First Draft: ballpoint, two stick figures at the top, US and an arrow. `[ Please don't. ]` |

**The memory** (after floor 90's boss, first runs only): "it" shows you the studio on Day 3 to make you stop. The PC: the reset under your finger. You can press it; nothing happens, because it's something you didn't do. Bookshelf: TOMORROW across the empty top floor. Window: their coat and the note, "gone down to the rack room to fix the stairs. dont wait up, dummy." Phone: you call, and the coat buzzes. Back on the white page, you tell the System everything, only that you came back, or nothing. If it has heard any page, it already knows you came back. Flags `ch9_told_all` / `ch9_told_part` / `ch9_told_nothing` and `ch9_read_*` are there for floor 99 and the ending.

**Numbers:** you went in 26 times (0002 to 0027). Tester 0041 came after you locked it, and is a stranger. **Time:** the tower's clock runs fast when nobody's logged in, and only slows down for an active player (System, floor 84). So 0041's 31 years inside is about three outside. **Log-off:** nobody is holding you in. Your session is stuck the way theirs was (SESSION IN USE); only "it" can override that, and you have to ask, which means agreeing to forget. **Floor 10's** `[ You remembered faster this time. ]` is "it", not the System.

## Chapter 10: "Recognition" (floors 91-100): the ending

Hayden's picks (2026-11-05): your route shapes one last choice; your real friend wakes or doesn't depending on it; the friend by the fire chooses for themselves; you take the memory back from "it" rather than destroying it. Tester 0012 and 0027 share floor 94. Tester 0001 is floor 99. The System admits it sent the invitation, and the title pays off: `[ I only needed one person to recognize me. ]`

| Floor | Beat |
| --- | --- |
| 91 | `[ Chapter 10: Recognition ]`. Figures on the stairs hold a blade the way you do. |
| 92-93 | A camp of 26 made-up bedrolls, numbered. |
| 94 | 0012 ("One more day") and 0027 ("What's her name?") together. Afterward: "You did what you could" or "You should have gone down the stairs". |
| 95 | The last fire: Marn, the scarf on the rail, and what your friend wants up there (route). |
| 96-97 | `[ The email. No sender address. That was me. ]` The Friday message and the blue door were the System too. `[ You spelled it wrong. It still counts. ]` |
| 98 | It rubs the stairs out faster than the System can draw them. You pick up the charcoal from floor 63 and draw them yourself. `[ That is the worst stair I have ever seen. ]` `[ Keep going. ]` |
| 99 | Tester 0001, the first login, forced to fight you. The System talks you through it in the battle log (`EnemyDef.battle_lines`): it really is weak to Wind. Afterward: `[ I'm still here. I want that noted. ]` Your friend finally sees the real one. |
| 100 | Tester 0041, a stranger: an email, a dog, 31 years. Then the white page, and everything below. |

**After 0041.** You can own it, tell them it's only been three years, or help them up. Then "it": `[ You only have to ask. ]`

- **Ask it to let you go ("Welcome Home"):** you wake at your desk, tired. The card's dates are filled in, and you put it in a drawer. `[ Welcome home. ]`
- **"Give it back. All of it.":** `[ Are you sure? ]` `[ All right. I was very careful with it. ]` `[ This message was sent. ]` Then the box and the pencil.

| Choice | Who gets it | What happens | Friend by the fire |
| --- | --- | --- | --- |
| Press the reset | Everyone | The tower and everyone on it end. They wake. | Hero: goes with them, "Give them my laugh". Villain: refuses, ends as themselves. Vigilante: you judge. No route, or at a fire: goes. |
| Draw the last floor ("The Last Floor") | Hero, no route, or a Vigilante who showed mercy at least once (never Villain) | You do the people, they do the lines. A way out for everyone. They wake. | Stays to carry people down. A year later you both log in, and they're at the fire with two cups. |
| Keep it ("One More Day") | Villain | You sit in the chair. They never wake, and she fills in the date. | Takes the seat beside you. |
| Hand the pencil to 0041 ("The Sentence") | Vigilante | "You press it yourself. And then you go and see that old woman." Same as reset. | As reset: you judge. |

Going home with them shows in the last image: they laugh, their hand starts up to cover their mouth, and it stops. Otherwise it covers their mouth as it always did.


## New recruits (Hayden, 2026-11-04)

Eleven more, so every route can reach a full party of 9 in every run. Three come back from earlier scenes: Wren (the thief, floors 6-7), Sabine (the envoy, floor 18), Hilde (the boots, floor 42). Their first lines remember what you did.

| Recruit | Class | Meet | Leans | When |
|---|---|---|---|---|
| Oren | Monk | Favor | Hero | Rest floors 10+ |
| Hilde | Support | Campfire | Hero | After Hero locks |
| Cormac | Warrior | Campfire | Hero | After Hero locks |
| Dragan | Tank | Campfire | Villain | Rest floors 10+ |
| Sabine | Mage | Hire 1000g | Villain | Rest floors 20+ |
| Belit | Summoner | Campfire | Villain | After Villain locks |
| Ulfar | Warrior | Campfire | Villain | After Villain locks |
| Wren | Rogue | Campfire | Works for anyone | Rest floors 15+ |
| Tobin | Support | Hire 800g | Works for anyone | Rest floors 15+ |
| Ines | Archer | Campfire | Vigilante, dislikes no one | After Vigilante locks |
| Bren | Spellblade | Campfire | Vigilante, dislikes no one | After Vigilante locks |

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

### "The One It Kept" (Hayden 2026-11-05; built)

Hayden's picks: a new storyline for New Game+; you go back on purpose; floors 21-99 are rewritten, with things you can change. It plays in every New Game+. Gods get "The First Prayer" on top of it.

**The idea.** Beating Tester 0041 left the door unguarded, so "it" kept a copy of you to hold it. When you log back in, it has restored the last clean build: your friend, Tess and Marn are all back and don't know you. Only four things remember: the System, the gods, the Titans (older than the build's restore point), and the copy at the top. Everyone who remembers treats you as the one who left.

**Why you go back** is one per ending (Hayden 2026-11-05; `ng_why`, built): **Reset or The Sentence:** a year on, the client opens by itself. "It" kept a backup. **The Last Floor:** the way out is rubbed away, and everyone's back to climbing. **One More Day:** someone with your face sits in your chair and says you can go. **Welcome Home:** a second email, and it all comes back on the stone.

**If your real friend woke** (`past_friend_woke`), they type the windows live from the next desk: no more sorrow, a lot of teasing, and the corrections annoy them. If they didn't, it's the System, sadder and still trying.

**How it ends** (Hayden 2026-11-05; built): beat your copy and your old party on floor 100. It doesn't know what to do next: "You didn't write that part." **Relieve it** ("I've got the door", "The One Who Stayed"): it hands you the door and goes to lie down. On your next climb, someone comes up with charcoal on their hands, and takes it from you. **End it** ("You can stop now. Thank you."): then, if your real friend woke, they talk to your fire friend at last, and the voice from floors 46-47 turns out to be a piece of the real one left in the fire friend; they won't give it back. Then the last choice: **shut the backup down** ("Soup" if they woke, "The Better Part" if not, where the System works out it's all that's left and says thank you; a lease leaves one light on, a cupboard). **Draw a way out** ("The Way Down": Hero or Vigilante, only if you told the climbers, or told the Host, or saved Marn or Tess; never Villain). **Sit in the chair** ("One More Day, Again": Villain).

**Built so far (2026-11-05):** `ng_why`, floors 21-30 ("The Door, Again") and floors 31-40 ("Second Hand"). Tell Marn on floor 25 and you can hold the door with him on 26-27; he lives, and keeps his ledger.

**Floors 31-40:** 31, the System says what it remembers of what you told it; you can say its name, and the wrong one answers. 32-33, you can carve an answer under "its RECOGNITION, dummy". 34, you can type in the old code comments, and get a reply. 35, a Marn who lived remembers everything and is being sorry to people by name; you can tell him about floor 80 (`ng4_told_marn_tess`, for Chapter 8). Otherwise you face the same ledger choice again. 36-37, tell the first god what it is (`ng4_told_gods`). 38, you say the summer first, and tell your friend how it ended. 39, GO HOME - {player}, fresh, from the copy; you can answer. 40, you say your half of "You drew the monsters" first.

**Floors 41-50, "Whose War":** 41, soldiers are singing about tenants, if you told the god. 42-43, you get to the camp early and can move everyone out before the fight (`ng5_moved_camp`; also counts as driving them off, for Hilde). 44, you say "stop correcting them" along with the System. 45, "Am I real?" again, with your better answer: all of it, "You're the part of them that still laughs", or "I came back on purpose". 46-47, you can answer the voice: "I came back twenty-six times." `...you did?` If your real friend woke, they swear that voice wasn't them (`[ I've got a very bad feeling about how much of me I got back. ]`: a thread for later). 48, you get there early: carry Tess off the field (`ng5_saved_tess`, costs blood), warn her (`ng5_warned_tess`), or leave her. You can stay with the priest. 50, the same choice, and your route locks again. The System suggests telling the climbers that 60 isn't the top.

**Floors 51-60, "Tell Them":** 52-53 and 56-57, the route missions, knowing how they go (Hero: move the camp before the stair falls, or hold it up; Villain: go straight to the treasury; Vigilante: "I built the floor you burned it on"; and so on). 54, you can leave 0041 a note or food (`ng6_note_0041`, `ng6_food_0041`). **55, the big choice: get up on a crate and tell everyone that 60 isn't the top** (`ng6_told_climbers`), tell a few (`ng6_told_some`), or let them sing. 58, if you told them, they've answered on the wall: HE SAID 40 MORE. WHO IS HE. SHE. is it true. 59, "I had a really good time": you can finally say "Me too". 60, the kind recruiter with the list, and under I BELIEVED IT TOO, in your old handwriting: SO DID I. If you told them, few sign (`ng6_host_smaller`); if not, you can shout in the doorway and save nine (`ng6_saved_some`). Chapter 8 should use these: fewer soldiers, different faces.

**Floors 61-70, "Second Drafts":** the one chapter "it" couldn't restore, because the Titans are older than the restore point, so they remember you. 62, you know you drew the chains, so you rub them out with your thumb (`ng7_rubbed_chains`). 63, if you drew the arm, it's still there, and the smith has spent 30 years making you a case of flasks: 5 Advanced Potions (`past_drew_arm`, a choice you made a whole climb ago). 64, you say "you're such a cheat" out loud. 65, the System gets to ask you one question: "Is my mom all right?" If your real friend woke: "Why are you in there, and not out here? I made soup." 66-67, the Seer, and news of your copy: "It said please. You never used to say please." 68, the corrections are spelled right now, and that's the frightening part. 69, the Elder: "I said you would. And here you are, twice." 70, tell Cronus it was cool, or say you were nine and you're sorry. He tells you your copy is boring.

**Floors 71-80, "The Tenants, Again":** the gods know the deals were worthless, and they know you know. So this time they ask YOU. 72-73, the first: "What happens to the people in the house?" 76-77, the second: "Don't turn the lights off. I'd take a cupboard." 78, in spelled-right corrections, you choose: give them a lease (`ng8_gave_lease`), make them kneel to the owner (`ng8_gods_knelt`) or evict them (`ng8_evicted`). The ending should use this. 71 and 74, gaps in the Host if you told the climbers on the crate. 75, "What happens to me?" gets a real answer from what happened last climb: "they're already out here, I've got their laugh", "they had so many notes", "they told you no", or "they took the seat beside you" (`past_friend_*`). 79, the page is gone, replaced with a tidy note in your hand: EAT SOMETHING. **80, Tess:** carry her off floor 48 and the armour is empty: nobody to put in it, and she walks on (`ng8_tess_lives`). Otherwise it's her again, and she stays where she is; you can tell her what it's worth. If you told Marn on floor 35, he's climbed all the way up to be with her, and she writes DONE in his book.

**Floors 81-90, "Going Down":** you know what "it" is, so you talk. It has tidied the unfinished floors with a ruler. 81, "I wrote you." 82-83, your dropped pages are filed in a clean cabinet, with notes. 84, you draw the stairs with the System while it objects. 85, your friend on the one with your face (route). 86-87, it asks you for the first time: "You took it all back. How is it?" Tell it to stop, and it can't: "You wrote: keep me out. You didn't write until when." 88, the door home again, and beside it a stair: RACK ROOM. NOT REQUIRED. You can ask to go down (`ng9_asked_go_down`). `[ You said never. ]` ... `[ You did say you only had to ask. ]` 89, Day 212, framed and dusted. 90, you put the bend back in the arrow.

**The memory, again** (`RETURN_RACK`, after floor 90's boss): the studio on Day 3. If you asked, there's a door beside the window. Two flights. They're on the floor with their shoes on, breathing. You can't touch them. You stay (`return_rack_stayed`). Back on the stairs, tell the System "You were breathing. I stayed", or lie. If your real friend woke, they're three feet away with a spoon, and they stop typing.

**Floors 91-100, "The One It Kept":** 91, Echoes stood in rows by height. 92-93, a 27th bedroll with your name on it, never slept in. 94, 0027 asks her name, and you can finally say it. 96-97, Tester 0041, freed, on the stairs with a folded coat: your note or food reached them. Own it, send them to Marn, or sit with them. 98, you draw the stairs together. 99, Tester 0001 again. 100, your copy and your old party.

**The One It Kept is written, floors 1-100 (first draft).** Gods get it plus "The First Prayer", which has no scenes on 61-99 yet.

| Floors | Chapter | What's different |
| --- | --- | --- |
| 1-20 | | The existing rewrites, plus your reason on floor 1. Floor 19's session list gains the copy. |
| 21-30 | "The Door, Again" | You know what's behind Marn's door. Get there first and hold it with him (costs blood): he lives for the first time, and keeps his ledger. Or bar it again. |
| 31-40 | "Second Hand" | The System knows you came back on purpose, and remembers what you told it (new past flags). No more hiding who it is. If Marn lived, floor 35 is a very different talk. Your friend's summer scene is yours to tell first. |
| 41-50 | "Whose War" | The gods court the one who's seen the top. "Am I real?" comes again, and you've had a whole climb to think of the answer. Floor 50 picks your route again, freely. |
| 51-60 | "Tell Them" | The route missions, plus a new choice: warn the climbers that 60 isn't the top. Those you warn never join the Host. On floor 60, under I BELIEVED IT TOO, a fresh line in your handwriting. |
| 61-70 | "Second Drafts" | The Titans remember you. If you drew the arm, it's still there, the one thing "it" couldn't restore. |
| 71-80 | "The Tenants, Again" | The gods know their deals are worthless, and that you know. Reach Tess first: warned (or warned this climb) she never takes the armour, and walks off the stairs. Otherwise you can only tell her the truth before the fight. |
| 81-90 | "Going Down" | You know what "it" is, so you can talk to it. In the Day 3 memory, this time it lets you take the stairs to the rack room. Nothing changes. You finally see them. |
| 91-100 | "The One It Kept" | 0041 is free, on a fire on these floors, and you can answer to them. The copy holds the door with your old party: end it or relieve it. |


### Still to build

The mimic final boss.

## Chapter 6 (one-line arc, to fill in later)

Written: see Chapter 6 above.

## The false summit (floor 60) and the last 40 floors (Hayden, 2026-11-04)

Everyone in the tower knows the top is floor 60. You beat its boss, open the door, and find more stairs: `[ Correction. 40 floors remain. ]`. Nobody who said otherwise ever came back down to check.

- **Floors 61-70, Titanfall:** what the gods overthrew: giants, cyclopes, Cronus. Why did the old powers end up under the top?
- **Floors 71-80, The Gods' Host:** the gods' own soldiers (never the gods themselves), trying to stop you reaching what's above them. The gods who bid for you in Chapter 2 show what that was worth.
- **Floor 70:** the third return plays here (built, see Chapter 7).
- **Floors 81-90, The Unfinished:** the game shows its seams. Unnamed enemies, placeholder knights, weaknesses that change every fight, and the First Draft of the tower.
- **Floors 91-100, Echoes:** past Testers, using your own skills, and Testers 0012 and 0027. Tester 0041 at the top.

Every floor has scenes now. These were the first outline.

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

Each visit ends with the System pulling you back in (`[ Resynchronizing. ]`),
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
(also the real game's title, 2026-11-05); setup questions give stats + a nudge; keep "You
remembered faster this time"; final boss = the previous Tester, NG+ = a
mimic of you and your old party.
