# News popups (`-NewsPopup on|off`, default on)

Status (2026-11-13): implemented in `Apply-CompanionPatches.ps1` and installed. Checked under
unicorn and on scratch copies. Not yet seen in the running game.

## The news function

`FUN_0040cb00(tag, priority, subject)` posts the text the caller wrote into golf's buffer
`0x51a068` to the one-slot strip (`0x5a6d40`, `screen_state 0x569498 = 1` while it shows).

| Strip state | Priority | Result |
|---|---|---|
| Busy | ≤ 0 | Refused |
| Busy | ≥ 1 | Replaces the current message |
| Any | any, while `[0x567afc] == 3` | Refused |

- **Tag** (`0x8000xxxx`) is stored at `0x5a34ec`.
- **Subject** is the golfer slot, or a negative kind, stored at `0x4c2e08`.

There are 50 call sites (v0.1.36). The priority-1 posts, grouped by tag and subject:

| Tag | Subject | What | Popup |
|---|---|---|---|
| `0x80002108` | golfer | VIP arrives (CEO, commissioner, heiress) | yes |
| `0x80000210` | golfer | VIP on the last hole | yes |
| `0x80006000` / `0x80001204` | golfer | VIP verdict: quits, board seat, land approval | yes |
| `0x80004210` | landmark | Landmark unlocked | yes |
| `0x80000018` | -2 | Story event | yes |
| `0x80001204` | -0x14 | Tournament | yes |
| `0x8000211f` / `0x80002190` | -4 / -1 | Scenario goals and philosophy | yes |
| `0x800023e8` | golfer | Skill needs a bigger course | yes |
| `0x00000001` | | Greens-fee advice | yes |
| `0x80006000` | -1 | Build and course feedback, hole hints | no |
| `0x80004210` | -1 | "Trees must be transplanted." | no |
| `0x80001284` | -4 | "Game Saved." | no |
| `0x80002108` | golfer | Match score each hole (`FUN_00427380`), the one call after the `31 FF 8A 1C 3A … 56 6A 01 68 08 21 00 80` copy loop | no (by return address) |

Golfer chatter, bets and departures are priority 0 or `esi`, so they stay in the strip.

## Hooks (section +0x1000..+0x1FFF)

**Post hook** (+0x1000):
- Site: the prologue's `mov eax,[trace flag]` (`A1 imm32`) after `push ebp/ebx/edi/esi`.
- `call +0x1000` runs `pushal`, the filters and the copy, then `popal`.
- It then repeats `mov eax,[flag]`, so the patcher reads the flag address back from the stub.
- Queue: 4 slots of 0x200 at +0x1800. Read index is at +0x11F0, write index at +0x11F4.
- When the queue is full, new posts are dropped.

**Show hook** (+0x10A0):
- Site: in `FUN_0040f5c0`, `test byte [0x567a1c],1; mov esi,0x51a068` (12 bytes) before the
  land-offer `je`. That is where golf opens its own land dialog.
- Per queued text, it:
  1. wraps at 44 columns, with no leading or double spaces, so no line can turn into a menu item;
  2. adds `"\n OK\n"`;
  3. calls `FUN_0046d6e0(400, 100, 0, 1, 0)`, the same call `practice_start.c` uses for an
     info box.
- It ends with the original `test` (flags for the `je`) and `mov esi`.
- The popup is golf's modal loop, so no game tick runs until it closes.

The patcher grows `.cmpn` from 0x1000 to 0x2000 in place (`Resize-Section`).
`Remove-Section` takes the section's own size. The Pixel HD helpers now stop at +0x1000.

## Checks

- **unicorn:**
  - registers and stack are kept;
  - `eax` gets the flag value;
  - ZF and `esi` are right after the show hook;
  - each filter drops its case;
  - texts are truncated at 511 characters;
  - the ring wraps;
  - wrapped lines are at most 44 characters and none starts with a space.
- **Scratch copies:**
  - the 4 KB install upgrades to the same bytes as patching vanilla;
  - a rerun has nothing to change;
  - off and back on gives identical bytes;
  - all off returns the vanilla MD5, and popups-only then off does too.

## In game, to check

- An important message opens a box and the clock stops until OK.
- Several messages arrive one after another.
- Building errors give no box.
- No box during the pro's match commentary.
