# Shot distances: clubs and lies (inventory for review)

Status (2026-11-12): implemented as `-Distances modern|vanilla` (default modern) in
`Apply-CompanionPatches.ps1`, with no cap. See "Implemented" at the end. Sources: the 0.1.36 program
(`Sim Golf Remastered.exe`, the remaster's translation of golf's code) and the original data
image `image/golf.bin` (golf.exe's memory at 0x400000). Distances are in **yards**: the game
shows `world * 25 >> 10`, so 1 tile = 25 yards. Numbers can be off by ±1 yard because the
game rounds with integer maths. Points marked **(verify)** come from static reading.

## The big picture: there is no per-club distance table

SimGolf works out **one maximum distance per golfer per shot** (`FUN_00422530(slot)`, binary
VA 0x60048881). The lie scales it down. Then:

1. **The shot's distance** is the distance to the target, clamped to `[0, max]`
   (`FUN_00424120`, VA 0x6006d9e6 for AI shots and the same clamp in the pro preview).
2. **The club** is only a label picked from what share of the max that distance is:
   `club = clamp(floor(20 * (max - d) / max), min, 11)`, with `min = 1` (no Driver) from any
   lie except the tees. Clubs are therefore **5 % bands of the max**.
3. Special cases:
   - **Punch shot** (`[0x58f330] == 3`) with club 4 or lower becomes the 4 Iron at 13/18
     (72 %) of the max.
   - **Putter** (club 13) on the green for 49 yards or less (AI path; the pro has its own
     check) **(verify)**.
   - The **Sand Wedge** (12) is never chosen by this formula. It may only appear elsewhere
     **(verify)**.
4. **Flight:** the distance is turned into a launch speed with a fitted curve. With
   `a = yards / 5`, speed = `33a - a²/48 + 64` and height term = `(speed + 64)/8 + 0x200`
   (`FUN_00424120`, VA 0x6006daa9..0x6006db0a), so the ball carries the distance asked for.
   Above the 330 cap the curve was never used, so longer shots need a flight check
   **(verify)**.

Club indexes, from the name formatter `FUN_0040a9a0`:
0 Driver, 1 3 Wood, 2 4 Wood, 3 2 Iron, 4 3 Iron, 5 4 Iron, 6 5 Iron, 7 6 Iron, 8 7 Iron,
9 8 Iron, 10 9 Iron, 11 Lob Wedge, 12 Sand Wedge, 13 Putter. There is no pitching wedge, no
5 Wood and no hybrid.

## The maximum distance, step by step (`FUN_00422530`)

The golfer record is `R = 0x5794b8 + slot * 0x100`. The steps run in this order:

| Step | Rule | Constant in code |
|---|---|---|
| Base, Easy (difficulty 0) | odd golfer type: **240**; even type: **175** | `mov ecx,0x19` / `mov esi,0x28`, then `+0xc8` / `+0x96` |
| Base, difficulty 1-3 | `level * 16.67 + (odd ? 200 : 150)`, level = signed byte `R+0xba` (the golfer's class row) | `imul 0x10aacc >> 16` |
| Power Hitter (golfers with skills) | `+ 4 * skill - 20`. Skill 5 is neutral; 10 gives +20; the companion's cap of 15 gives +40 | `lea esi,[esi+ecx*4]; add esi,-0x14` |
| Long Driver, **tee shots only** | `+ 6 * skill - 30`. Skill 10 gives +30; 15 gives +60 | `lea esi,[esi+eax*6]; add esi,-0x1e` |
| Byte `R+0x36` (0-3, identity unknown, maybe mood or form) | `* (1 + v/24)`, up to +12.5 % | `imul 0x2aaaaaab` |
| Course-wide value `[0x543cc8]` (identity unknown), odd types only | `+ 15 * value` | `lea eax,[eax+eax*4]; lea eax,[eax+eax*2]` |
| Lie hazard (terrain byte +34) | `* (1 - min(h, 3) / 8)`: -12.5 %, -25 % or -37.5 % | `imul; sar 3` |
| Any lie except the tees | `* 0.8` | `imul 0x99999999` |
| Cap | `min(…, 330)` | `mov eax, 0x14a` |

The golfer type is `R+0x19`, 0 to 7, picked when a golfer arrives (`FUN_00421bc0`). Its low
bit picks the long or the short base. That is most likely men versus women, but this is not
confirmed **(verify)**. The pro's own type and level bytes are also unconfirmed. The pro
example below assumes the long base.

## Maximum distance by lie

Terrain rows come from the table at 0x4c1a40 (`data/tables/terrain.json`). Hazard is byte +34.

| Lie | hazard | Easy, odd type (240) | Easy, even type (175) | Pro: 240 + Power Hitter 10 + Long Driver 10 | Same with both skills at 15 |
|---|---|---|---|---|---|
| tees | 0 | 240 | 175 | 290 | 330 (cap) |
| green | -1 (none) | 192 | 140 | 208 | 224 |
| fairway | 0 | 192 | 140 | 208 | 224 |
| firm fairway | 0 | 192 | 140 | 208 | 224 |
| rough | 1 | 168 | 124 | 183 | 196 |
| deep rough | 2 | 144 | 106 | 156 | 168 |
| mound | 2 | 144 | 106 | 156 | 168 |
| waste bunker | 2 | 144 | 106 | 156 | 168 |
| sand trap | 3 | 120 | 88 | 131 | 140 |
| pot bunker, ravine | 5 (counts as 3) | 120 | 88 | 131 | 140 |
| brush, rocks, wetlands, marsh | 3 | 120 | 88 | 131 | 140 |
| tree (all four kinds) | 4 (counts as 3) | 120 | 88 | 131 | 140 |
| water, out of bounds | 8 (counts as 3) | 120 | 88 | 131 | 140 |

Notes:

- **The fairway costs 20 %** compared with the tee, even with no hazard. The Driver is
  effectively tee-only.
- Because the hazard is clamped at 3, every lie from sand onwards is the same (-37.5 %, then
  ×0.8 = 50 % of the base).
- Power Hitter applies everywhere. Long Driver applies only on the tees.
- Lies also change **accuracy** (error and the "bad lie" check at terrain byte +34 ≥ 1, which
  forces straight or punch shots in the HUD). That is a separate system from distance and is
  not covered here.

## Club bands (what each club carries)

| # | Club | share of max | max 240 | max 290 (pro off the tee) | max 208 (pro from fairway) |
|---|---|---|---|---|---|
| 0 | Driver | 95-100 % | 229-240 | 276-290 | 198-208 (tee only) |
| 1 | 3 Wood | 90-95 % | 217-228 | 262-275 | 188-197 |
| 2 | 4 Wood | 85-90 % | 205-216 | 247-261 | 177-187 |
| 3 | 2 Iron | 80-85 % | 193-204 | 233-246 | 167-176 |
| 4 | 3 Iron | 75-80 % | 181-192 | 218-232 | 157-166 |
| 5 | 4 Iron | 70-75 % | 169-180 | 204-217 | 146-156 |
| 6 | 5 Iron | 65-70 % | 157-168 | 189-203 | 136-145 |
| 7 | 6 Iron | 60-65 % | 145-156 | 175-188 | 125-135 |
| 8 | 7 Iron | 55-60 % | 133-144 | 160-174 | 115-124 |
| 9 | 8 Iron | 50-55 % | 121-132 | 146-159 | 105-114 |
| 10 | 9 Iron | 45-50 % | 109-120 | 131-145 | 94-104 |
| 11 | Lob Wedge | 45 % or less | 0-108 | 0-130 | 0-93 |

## Modern reference, for the review (approximate, from memory; check before tuning)

These are typical published launch-monitor averages, roughly TrackMan tour figures. They are
rounded and only a guide.

| Club | PGA Tour, carry | Typical male amateur, total |
|---|---|---|
| Driver | ~280 (about 300 total) | ~215-230 |
| 3 Wood | ~245 | ~200 |
| 5 Wood or hybrid | ~225-230 | ~180-190 |
| 4 Iron | ~205 | ~170 |
| 5 Iron | ~195 | ~160 |
| 6 Iron | ~185 | ~150 |
| 7 Iron | ~172 | ~140 |
| 8 Iron | ~160 | ~130 |
| 9 Iron | ~148 | ~120 |
| Pitching wedge | ~136 | ~110 |
| Sand or lob wedge | ~80-110 | ~60-90 |

Roughly, the LPGA Tour driver is ~250 total and a female amateur's is ~150-170.

Compared with SimGolf:

- **The pro off the tee** (290 with 10/10 skills) is already close to tour level. The
  **fairway penalty** (×0.8) is what feels old-fashioned: a tour pro's 3 Wood from the fairway
  goes ~245, but SimGolf's best fairway shot is 208.
- **The band shape is not bad.** A 9 Iron at 45-50 % of the driver matches tour ratios
  (148/300). The woods sit too close to the driver: the 3 Wood is 90-95 % here and about 82 %
  on tour.
- **Ordinary golfers** (240 or 175 on Easy) are close to modern amateurs off the tee. From the
  fairway they are short (192 or 140).

## Levers for "more distance" (for the review; nothing done)

Each lever is one or a few immediates in `FUN_00422530`, so the patch would be small and each
can be checked with a byte signature:

1. **The bases** (25/40 and 150/200, or the difficulty multiplier 16.67). This raises everyone:
   the pro, AI golfers and celebrities.
2. **The non-tee factor** ×0.8. Raising it to about ×0.9 gives fairway woods modern reach.
3. **The skill slopes**: Power Hitter +4 per point, Long Driver +6 per point. This raises only
   golfers with skills, mainly the pro.
4. **The cap** of 330. It needs raising if the bases go up much; above 330 the flight curve
   needs a test.
5. **The hazard step** (/8 per level, clamped at 3), if rough and sand should cost less or more.

What a review should weigh:

- **Course scale.** 1 tile = 25 yards, so a 50×50 map is 1250 yards across. Longer drives make
  the same holes play shorter. More eagles mean more golfer happiness and fame, so the economy
  is affected too. A par 4 of 16 tiles (400 yards) becomes driver plus wedge.
- **Everyone uses this function**, AI golfers and the pro alike. For a pro-only boost, change the
  skill slopes, not the bases.
- **The AI shot planner** (`FUN_00422fb0`) searches ±10 tiles (±250 yards) around its landing
  guess, so maxima well past ~330 need checking there too **(verify)**.
- **Saves are not affected.** Distances are computed every shot and nothing is stored.

## Golfer level (found 2026-11-12)

`R+0xba` is set on arrival (`FUN_00421bc0`, VA 0x60049f54..0x60049f71) to the golfer's profile
index (`R+0xb8`) mod 3, so the level is 0, 1 or 2. On difficulty 1-3 the tee base is therefore:

| | level 0 | level 1 | level 2 |
|---|---|---|---|
| long type (odd) | 200 | 217 | 233 |
| short type (even) | 150 | 167 | 183 |

The gap between types is 50 yards on the harder levels and 65 on Easy.

## Proposal: narrow the gap for one set of tees (7200 yards, par 72)

The game has a single tee per hole, so short hitters must be able to play the same yardage.
Two-shot reach is `tee * (1 + F)` and three-shot reach is `tee * (1 + 2F)`, with F the non-tee
factor. A 7200 par 72 (4 par 3s ~195, 10 par 4s ~430, 4 par 5s ~530) needs a tee max of ~225
for a par-4 green in two at F = 0.9, and ~190 for a par-5 green in three.

Proposed constants in `FUN_00422530` (all in-place immediates):

| Constant | Now | Proposed |
|---|---|---|
| long offset `lea ecx,[esi+0xc8]` | 200 | 230 |
| short offset `add esi,0x96` | 150 | 210 |
| Easy extra, long (`mov esi,0x28`) | 40 | 30 (Easy total 260) |
| Easy extra, short (`mov ecx,0x19`) | 25 | 25 (Easy total 235) |
| non-tee factor | ×0.8 | ×0.9 |
| cap | 330 | 330 |

Resulting tee / fairway maximums: Easy 260/234 and 235/212; harder levels long 230-263 / 207-237
and short 210-243 / 189-219; the pro with both skills at 10 hits 310 off the tee and 252 from the
fairway. Not verified yet: how the game assigns par from hole length.

## Implemented: `-Distances modern` (no cap)

Two byte sites in `FUN_00422530`, 11 bytes in all, found by signature and changed in place:

- Base site (VA 0x60048951, 27 bytes): `B9 SE 00 00 00 BE LE 00 00 00 0F 44 F1 8D 8E LO32 81 C6 SO32 84 C0 0F 45 F1`.
  Vanilla 25/40/200/150, modern 25/30/230/210.
- End site (VA 0x60048a4a, 32 bytes): `B9 C32 89 F0 F7 E9 89 D0 D1 F8 C1 EA 1F 01 F0 01 D0 89 C6 B8 CAP32 39 C6 0F 4C C6`.
  Vanilla C = 0x99999999 (x0.8) and cap 330. Modern C = 0xCCCCCCCC (x0.9) and cap
  0x7FFFFFFF (none).

Checked on scratch copies only:

- Vanilla to modern and back gives the original file byte for byte, and a second run changes nothing.
- The all-vanilla backup rule and the after-write check include the new option.
- It works on top of the other companion patches and the `.cmpn` section.

Exact integer re-run of the patched code (yards; long-hitter pro on Easy assumed):

| Golfer | Tee | Fairway | Rough | Deep rough | Sand+ |
|---|---|---|---|---|---|
| Easy long / short | 260 / 235 | 234 / 212 | 206 / 186 | 176 / 160 | 147 / 133 |
| Long, level 0 / 1 / 2 | 230 / 246 / 263 | 207 / 222 / 237 | 182 / 195 / 208 | 156 / 167 / 179 | 130 / 139 / 149 |
| Short, level 0 / 1 / 2 | 210 / 226 / 243 | 189 / 204 / 219 | 166 / 179 / 192 | 143 / 153 / 165 | 119 / 128 / 137 |
| Pro 10/10 | 310 | 252 | 221 | 189 | 158 |
| Pro 15/10 | 360 | 270 | 237 | 203 | 170 |
| Pro 20/10 | 410 | 288 | 252 | 216 | 180 |

Why removing the cap is safe for flight:

- The launch speed comes from `FUN_00422430`, called at VA 0x6006db2c. It bisects the speed
  from a fitted guess up to twice that guess, using the flight simulation `FUN_004223c0`. That
  simulation has no step limit: speed decays by 1/16 per step until the ball comes down.
- The carry target is 0.8 x yards, and the rest is roll.
- An emulation of the solver lands within 0.5 yards of the target from 50 to 600 yards.
- Every caller keeps the maximum in 32 bits: `FUN_00407e00`, `FUN_0040f5c0` (pro preview),
  `FUN_00424120`, `FUN_004289e0` and the AI planner `FUN_00422fb0`, which does arithmetic only.

Not tested in the running game:

- how AI golfers plan long holes;
- par and score balance;
- whether the pro is a long or a short hitter.
