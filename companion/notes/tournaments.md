# Tournaments and the SGA standards

Goal (user, 2026-11-13): "visit golf tournament standards. document how the
code works and we are going to tweak it to add some golf realism to the game,
seems like the game wants quirky golf holes but i don't want that."

Addresses: `0x4xxxxx` is golf (`image\golf.bin`, data and strings only, read
with `gdis.py`), `0x60xxxxxx` the remaster program whose translated code runs.
The whole evaluation is one 14 KB function, **FUN_0044fb30(mode)** (exe
`0x600b24b4`), which is both the F7 "SGA Evaluation" report and the silent
tournament check (mode 2). The remaster's reports layer (`reports_game.c`,
`RP_SGA`) only redraws its output.

## The flow

1. **Offer.** In the main loop's July block (now every month, see
   `year-events.md`): if the pro is not out (`[0x5a59f8] == -1`),
   FUN_0044fb30(2) scores the course. A score above 0 stores the prize in
   `DAT_00567b04` ($1000s) and the SGA asks: "The SGA is interested in holding
   a tournament at your course. 'We'd like to schedule the <name> Open..."
   A score of 0 or less clears game flag `0x400000` (the offer) and nothing
   happens.
2. **Accept.** The tournament button / "Great, let the games begin." (main
   loop, golf `0x41cead`) calls **FUN_0046c970**: snapshot of the 84 profiles
   to `DAT_0058f338` (saved with the game while it runs), field set up, game
   flag **`0x200000` = tournament in progress**. Championship mode
   (FUN_0046ddd0) starts the same way with flags `0x4000000`.
3. **Play.** Golfers with type `&0xe0 == 0x20` are the pros. While `0x200000`
   is set nobody walks off (FUN_004289e0 clamps the patience word, golf
   `0x4293b2`), a course can not be saved ("Cannot save course during a
   tournament."), and the leaderboard report is available.
4. **End.** FUN_0045a090 (results, "TOURNAMENT RESULTS"/"SCORES") pays the
   purse and FUN_0046d0c0 restores the profiles and clears `0x200000`; a cancel
   ("CANCEL this tournament...", golf `0x41c8cd`) does the same without pay.

Companion patches: building during step 3 is locked (`-TourneyBuild`, item 31)
and staff draw no wages (`-TourneyWages`, item 32; golf already skipped them
in Championship mode, flag `0x4000000`).

## The SGA evaluation (FUN_0044fb30)

### Course class

`FUN_0044faf0(holes)`, where `DAT_005685f0` is holes + 1 (hole slots count
from 1):

| holes | class | ideal holes | hole-type ideal |
|---|---|---|---|
| 1-5 | 0 | 5 | 5 |
| 6-9 | 1 | 9 | 9 |
| 10-17 | 2 | 17 | holes |
| 18 | 3 | 18 | 18 |

### Ten criteria, 0..10 points each, 100 total

Every criterion is clamped to 0..10 (FUN_00467130). **A 0 in any of them
prints "- not acceptable -" and the whole report fails** (score -999, no
tournament).

| # | Criterion | Value | Points |
|---|---|---|---|
| 1 | Length of Course | total yards | 18 holes: `10 - (ideal - yards)/100`; else `10 + (yards - ideal)(class + 4)*5/ideal`. Ideal = `idealHoles*100/18 * (57 + 5*class)`: **7,200 yd** for 18 (minimum 6,200), 3,100 for 9, 1,539 for 5. Longer is never penalised. |
| 2 | Number of Holes | holes | `10 - abs(ideal - holes) * k` |
| 3 | Time to Play | average round, minutes | full at **4 hours or less**, falling to 0 at 5 hours (`cmp 300`), over 5 h fails |
| 4 | Fun Factor | course fun % | full at **100%+**, about a point per 4% below (`(fun - 109)/4 + 10`) |
| 5 | Holes with Variety | holes not "very similar to the last hole" (hole +0x1FC < 2) | `10 + count - ideal` |
| 6 | Scenic Holes | holes with `scen(+0x104)/2 + (+0x110) + (+0xEE) >= 8` | `10 + count - ideal` |
| 7 | Length Holes | holes that test length (below) | `10 + count - ideal` |
| 8 | Accuracy Holes | holes that test accuracy | `10 + count - ideal` |
| 9 | Imagination Holes | holes that test imagination | `10 + count - ideal` |
| 10 | Facilities on Site | distinct building kinds (of 20) | `2*(count - ideal) + 8` |

**The hole-type ideal is every hole.** On an 18-hole course a full score
needs all 18 holes to be scenic, varied *and* each to test length, accuracy
and imagination at the same time. Each hole missing from a category costs a
point; ten missing fails the report.

### What makes a hole "test" a skill

Each hole record (`DAT_00575ab0 + hole*0x208`, see `port/docs/formats/sve.md`)
keeps stroke totals and round counts for golfers grouped by skills ("Shot
Analysis": golfers with ALL skills / no Imagination / no Accuracy / no
Length). For skill X:

    extra = 100 * strokes(no X) / rounds(no X) - 100 * strokes(all) / rounds(all)

in hundredths of a stroke (game flag `0x40` adds a second group's
difference). The hole tests X when `extra >= T`, with **T = 25 on Easy, 50
otherwise** (`[0x822c88]`, difficulty). So a "Length hole" is one where
golfers without Length average half a stroke more than complete golfers.

The hole's type name (table `0x4c2a28`) comes from the mask of skills it tests
(1 length, 2 accuracy, 4 imagination): **Classic** = all three, **Strategic**
= accuracy + imagination, **Heroic** = length + imagination, plus
**Challenge**. "Top 100 Hole" / "Top 18 Hole" are further ranks (thresholds
50 and 100 on the per-skill differences, golf `0x450538..0x450663`).

### Why the game wants quirky holes

Half the score (criteria 5-9) counts holes, and the target is every hole. A
hole only counts for Accuracy, Length *and* Imagination when golfers missing
each skill lose half a stroke there, so every hole needs a forced carry, a
narrow landing area and something to shape a shot around. A realistic course
mixes holes: a short par 3, a straight par 4 that is about the drive, a
risk-reward par 5. Under these rules such a course scores 50-70 at best. The
Fun Factor (criterion 4) is the other quirk driver: golfers' fun comes from
the shots they enjoy on each hole (hole +0x158 fun points, not yet traced).

### Score, event and prize

The total S (0..100) picks the event, in steps of 5 (jump table `0x453228`):

| S | Event |
|---|---|
| < 45 | Jr. Qualifying School |
| 45 | SGA Qualifying School |
| 50 | Jr. Tour Event |
| 55 | Jr. Tour Championship! |
| 60 | SGA Amateur Championship |
| 65 | Senior SGA Tour Event |
| 70 | Senior SGA Championship |
| 75 | SGA Tour Event |
| 80 | SGA Players Championship |
| 85 | SGA Championship! |
| 90+ | Grand Slam Championship! (18 holes), else Mini Slam |

Purse (`DAT_00567b04`, $1000s): `(S/5 - 5) * (class + 1) * (holes + 1) * 2`.
Example: the 9-hole "Carolina Open, $280,000" of the year-events test is
S = 60: 7 * 2 * 10 * 2 = 280. An 18-hole course at 100: $2,280,000. The
"Championship" course upgrade doubles the money ("DOUBLE your tournament
prize monies if your course passes the more stringent SGA evaluation").

Awards from here: S >= 90 with 9+ holes "1st Grand Slam course (9+ holes)",
with 18 "(18 hole)", and S == 100 with 18 holes "1st 100 star rating".

## Realism tweaks to choose from (not done)

1. **Hole mix instead of every hole.** Make the hole-type ideal a share of
   the holes (for example half for Length, Accuracy and Imagination, two
   thirds for Scenic), so a course of distinct holes can score 100. One
   immediate per class at golf `0x45107e..0x4510d7` (exe equivalent).
2. **A hole tests one or two skills, not all three.** Score criteria 7-9
   together: count holes that test at least one skill, ideal = every hole.
3. **Par and length standards.** Replace "Holes with Variety" with a par mix
   (18 holes: four par 3s, four par 5s, par 70-72) and ideal length by par
   (par 72 ~ 7,200 yd).
4. **Skill threshold.** Raise T (0.5 stroke) so only real tests count, or
   lower it so subtle holes count.
5. **Pace.** Keep 4 hours; tighten to 4.5 h for the fail point.

Not traced yet: the Fun Factor and per-hole fun points, the scenic fields
(+0xEE, +0x104, +0x110), the facilities ideal, the course-tier upgrade test
(Municipal / Golf Club / Country Club / Championship) and its doubling.
