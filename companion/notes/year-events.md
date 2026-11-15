# Year events every month (-YearEvents)

Request: "given there's no date based innovation, time goes too quickly... a
month should equal a year in terms of progression." Two readings were offered:
a calendar 8x slower (one month lasts as long as today's year), or yearly
events every month. The user chose **yearly events every month**.

## How the game keeps time

Addresses: `0x4xxxxx` is the original program (`image\golf.bin`, loaded raw at
0x400000; data and strings only), `0x60xxxxxx` is the 0.1.36 remaster program,
whose translated code is what runs.

- One clock, `DAT_00834170`, saved in the .sve. The main loop adds 1 per pass
  (orig 0x41763a, exe 0x6005e1ee).
- 1024 ticks a month, 8 months a year (March..October), so 8192 ticks a year.
  day = `(t & 0x3FF) * 30 >> 10` + 1, month = `(t >> 10) & 7`, year = `t >> 13`.
- `DAT_005a6d3c` (int16) caches the year. FUN_0040d7b0 (date to text, exe
  0x60040675) writes it; it indexes the finance ledger (`year % 100`).
- The remaster's day/night light runs on real seconds, not the clock. Seasons
  (renderer and `weather_climate.c`) use `(t >> 10) & 7`.

## What runs when (main loop)

| When | What |
|---|---|
| every pass | golfers, staff, weeds (`t & 3 <= difficulty`), animations (`t % frames`), events scheduled as `t + N` |
| every `0x400 / (difficulty + 2)` ticks | wages: $100 per employee |
| `t & 0x3FF == 0x200` (16th) | &AutoSave1 |
| `t & 0x3FF == 0` (1st) | &AutoSave2; history sample (`month % 500`: cash, fun, skill, membership); "will not be operational" path warnings; per-hole stats fade 1/8; 2 % interest on debt; tutorial hint |
| `t & 0x1FFF == 0x1000` (July 1) | if the pro is not out (`[0x5a59f8] == -1`): FUN_0044fb30(2) picks an event, and if the course qualifies (`[0x567b04]`) the SGA invitation ("We'd like to schedule the ... Open") |
| `t & 0x1FFF == 0` (March 1) | map stat layers fade 1/8; the visitor mix table (`DAT_005422f8`, 9 rows) drifts +1; the board's review FUN_0044cff0 |

The two yearly blocks are nested in the 1st-of-month block (exe: the month test
at 0x6005ec69 jumps past both). There is no pro ageing on the calendar; the
yearly +1 at 0x54230c is the visitor mix.

## The board's review (FUN_0044cff0, exe 0x600ae60f)

It compares history sample `m = t >> 10` with `m - 8` (a year back): "Cash
reserves have increased", fun rating, skill rating, membership, then the
highlights between the two. Title "END of  YEAR:  " + `_itoa(year + base - 1)`
(the StartYear "last year" site), columns "This Year" / "Last Year".

The debt verdict sits in the same function: with cash below 0 (and the board
not told to ignore it, `[0x59e7bb] & 1`), strike counter `DAT_005a6374` goes up
with "You have two years to return...", "one more year...", and at 3 the main
loop (0x6006a679) ends the career. Cash at or above 0 resets the strikes.

## The patch

Same-length byte edits:

- July block (exe 0x6005f23c..0x6005f250): mask `0x80001FFF` -> `0x800003FF`,
  the negative-tick `or` `0xFFFFE000` -> `0xFFFFFC00`, `cmp edx, 0x1000` -> `0`.
- Year block (0x6005f74f, 0x6005f758): masks `0x1FFF` -> `0x3FF`. The July
  block's `jne` lands past the year block's own mask, using the July mask's
  result, so both masks must change together.
- The review's history back-index (0x600ae99b `lea eax, [ecx-8]`, 0x600ae9b4
  `add eax, -8`): -8 -> -1.

Two hooks into `.cmpn` (+0x1380..+0x13FF):

- **Debt gate**, the review's `cmp dword [0x571fd4], 0` (7 bytes) -> `call
  +0x1380; nop2`. With `t & 0x1FFF == 0` it does the compare and returns. On
  any other 1st it returns to just past the strike reset (the `jns` target +
  10), so the verdict is skipped and the strikes kept. With `-Calendar slow`
  (see `slow-calendar.md`) the gate's mask is `0x3FF` instead: the verdict
  comes on every 1st, which is once per old year of play, and the two debt
  warnings say "months".
- **Title**, the review's `_itoa(year + base - 1, 0x821c50, 10)` call -> `call
  +0x13A0`: writes "<Month> <year>" for tick - 1 (the month that just ended)
  into the 16-byte buffer (longest "September 2199", 15 bytes). The year is the
  passed value + 1, less one on March 1, so it follows -StartYear without
  touching its site.

Strings: golf.bin `END of  YEAR:  ` -> `END of MONTH:  `, `This Year` -> `This
Month`, `Last Year` -> `Previous` ("Last Month" is cut off in the remaster's
right column); the program's `YEAR IN REVIEW` -> `MONTHLY REVIEW`.

Unchanged: the calendar, seasons, weather, autosaves, wages, income, the
monthly interest and fading, tournament dates, the ledger, and saves.

## Verified (2026-11-13, scratch copy, never the installed game)

Headless harness on a scratch copy with its own `game` folder:

- 15 March 2025 save, clock to 1 April: "MONTHLY REVIEW / END of MONTH: March
  2025", This Month against Previous; all 9 visitor mix rows +1.
- 1 May with cash -$50,000 and the pro in: review for April with no debt
  verdict, strikes stay 0; then the SGA invitation ("Carolina Open", $280,000).
- 1 March 2026 in debt: review titled "October 2025" with "The board is
  concerned ... You have two years to return to positive cash.", strikes 0 -> 1.
- Round trip: `monthly` then `yearly` gives byte-identical exes and golf.bin to
  `yearly` alone; `monthly` differs only at the sites above, the one exe
  string and `.cmpn` +0x1380..+0x13FF.

Not checked: a full natural year of play (the tests moved the clock), and a
review with highlights in it.
