# Slow calendar (-Calendar slow|vanilla)

Request (2026-11-13): "staff seems to be getting paid far too often and the
months moving too fast. i want a single month to be the original game's full
operating year. timing of staff payments should be identical from a real time
perspective." Later: "running a tournament i end up super deep in the red ...
i also want that timing adjusted."

So: the calendar runs 8x slower, and everything that ran on play time keeps
its real-time pace. Wages per calendar month go up 8x on purpose (same
paydays per minute of play).

## Clock background

See `year-events.md`. One clock, `DAT_00834170`, saved in the .sve, +1 per
main-loop pass (exe 0x6005e1e9, hook site). 1024 ticks a month, 8 months a
year. Game flag `[0x59e7b8] & 8` rounds it to even. 208 instructions in the
exe touch the clock.

## Design

- **The saved clock stays the calendar.** Saves, dates, seasons, the ledger
  and every date stamp keep their meaning, so saves load in both modes.
- **A fast counter F** at `.cmpn+0x4040` counts one per main-loop pass, as the
  clock used to. It is kept as `F = clock * 8 + (F & 7)`, so it can be
  rebuilt from any loaded clock and never drifts from the save's date.
- **The hook** (exe 0x6005e1e9, 34 bytes: load, +1, store, even-rounding)
  becomes `call .cmpn+0x4000; jmp +0x1A`. The 64-byte routine rebuilds F from
  the clock, adds 1 (keeping the even rounding on F), stores F and writes
  `clock = F >> 3`.
- **129 play-time reads point at F** instead of the clock (the address in
  the instruction, or address + 1 for the byte-wide `test`). They are the
  reads that time things: weeds (`t & 3`), animation frames (`t % n`), events
  scheduled as `t + N` and their comparisons, golfer and staff timers, the
  wage block at 0x6005e4a5 (`t % (0x400 / (difficulty + 2))`), the
  mid-month autosave (0x6005ec15, 0x6005e68d), the tutorial.
- **What stays on the clock** (79 reads): the date text, month and season,
  the July and March tests, the review, the ledger, loading and saving, date
  stamps compared against dates.
- **The 1st-of-month gate** (0x6005ec4b) reads F with its masks raised from
  0x3FF to 0x1FFF (0x5EC54, 0x5EC5E), so it fires on F's sub-step 0 of the
  1st: once, not on 8 passes. The July and March tests inside it read the
  clock and are unchanged.
- **Two calendar spans** read through F are scaled 8x so they keep their
  calendar length: 0x63F8A `0x2200 -> 0x11000` and 0xCF22B `0x1400 -> 0xA000`
  (the tutorial's dates).
- **Strings.** Program: `%d times/month` -> `%dx8 per month` (difficulty
  screen). golf.bin, only with `-YearEvents monthly`: the debt warnings say
  months ("You have two months to get back in the black.", "Just one more
  month to get out of debt."), since the verdict then comes on every 1st.
- **-YearEvents** gate: with the slow calendar the debt gate in `.cmpn+0x1380`
  checks `t & 0x3FF` (every 1st = once per old year of play) instead of
  `t & 0x1FFF` (March 1).

`.cmpn` +0x4000..+0x407F (code +0x4000, F at +0x4040); `$sectionSize` 0x5000.

## Effects to know

- Interest on debt and the 1st-of-month events come 8x less often in play
  time; so does the review with `-YearEvents monthly`.
- A tournament runs on play time, so the calendar barely moves during it and
  it costs the same real-time wages as before. `-TourneyWages unpaid` (another
  item) stops wages while a tournament is on.
- Switching slow -> vanilla: golfer/staff stamps written in F units (e.g.
  golfer +0xB0) read as the future against the vanilla clock, so some timers
  wait longer once. No date readers were found for them.

## Verified (2026-11-13, scratch copy, never the installed game)

Headless harness, `--bridge`, on a copy with junctions to the install's art.

- Dry run and real run recognise every site and verify; a second run says
  nothing to change.
- Clock +15 and F +120 per 120 frames, `F >> 3 == clock`; 1100 frames: clock
  +138, F +1100, no jumps.
- Wages at exactly F % 341 == 0 (difficulty 1): F 265639, 265980, 266321.
- 1 April 2025 with cash -$500: one "MONTHLY REVIEW / END of MONTH: March
  2025" with "You have two months to get back in the black.", strikes 0 -> 1,
  no repeat in the next 80 frames, HUD April 2025.
- AutoSave1 written mid-March on the real-time cadence, AutoSave2 on the 1st.
- New career (Easy, Rocky Mountains): starts March 2021, clock 7 / F 60, then
  clock +25 / F +200 per 200 frames, `F >> 3 == clock` throughout.
- A slow-mode save loads in a `-Calendar vanilla` build and plays on.
- Round trip slow -> vanilla: identical to the shipped exe except the grown
  section (headers, extra 4 KB of zeros).
- Difficulty screen: "2x8 per month" ... "5x8 per month" fits.

Not checked: a full natural old-year of play, a tournament from start to end
under the slow calendar.
