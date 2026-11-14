# Stuck pro shot (`-ShotFix`), shot types in bad lies (`-AllShots`) and long curves (`-CurveFix`)

Status (2026-11-13): implemented in `Apply-CompanionPatches.ps1` and installed in both programs.
Checked by disassembly and round trips on scratch copies. Not yet seen in the running game.

Addresses are v0.1.36 VAs (image base 0x60000000). Golf globals keep their original addresses.
Golfer record `R(slot) = 0x5794b8 + slot*0x100`; the pro's slot is `[0x5a59f8]` (-1 when in).

## How a pro shot is committed

| Step | Where | What |
|---|---|---|
| Waiting | golfer tick `FUN_004289e0`, VA 0x60071d21 | `R+0xcc == 0`: set it to -1, shot type `[0x58f330] = 0`, delay `[0x5a34e4] = 10`, "your shot" message. Then every tick with `R+0xcc == -1`: dock mode `[0x567afc] = 3`, `[0x561254] = 0`, state byte `R+0x1d = 0xb` (VA 0x60075b87). |
| Delay | `FUN_0040f5c0`, VA 0x6006270d | `[0x5a34e4]` counts down in the aiming code. |
| Click | `FUN_0040f5c0`, VA 0x60066c62 | Commit only if `[0x822d68] == 1` (left click), `[0x567afc] == 3`, `[0x5a34e4] <= 0` and `[0x822d64] < screen_h - 0x78`. Screen height is the port's `win_screen_h` at 0x60393010. |
| Commit | VA 0x60069fb3 | Dock mode 4, `R+0xcc/d0 = R+0xc4/c8` (the aimed tile). |
| Launch | VA 0x60071f17 | `R+0xcc != -1`: `FUN_00424120(slot, 1, -1, 0, 0)` (entry 0x6006cda2). `R+0xcc` keeps the target until the next turn, so the shot buttons (`read_pro` needs `R+0xcc == -1`) stay hidden in flight. |

## The two stuck cases

1. **Bottom strip (Frosted Mint HUD).** The aiming gate (VA 0x600621e3) passes `screen_h - 0x78`
   through `hud_ylim` (0x602d0140, which returns 100000 while the new HUD is up). The click gate
   used the raw limit, so a target in the bottom 120 canvas pixels could be aimed at but not shot.
   `golf.json` patches line 176 (`DAT_00822d64 < 0x1e0 + HD_UI_DY`) without `hud_ylim`.
2. **Dock mode 4 while waiting.** `FUN_00436c00` (the pro's sub-page, `[0x561254] != 0`) sets mode 4
   on close (VA 0x60089b93). Only mode 3 commits.

## Patch

- Click gate: `mov eax,[screen_h]; add eax,-0x78` (8 bytes at VA 0x60066c79) -> `call .cmpn+0x1300`
  plus a 3-byte nop. At +0x1300 it does the same two instructions, then `push ecx; push eax;
  call hud_ylim; add esp,4; pop ecx; ret`. The flags come from the `cmp` after the call.
- Shot-type buttons in `FUN_00436060`: the five `mov dword [0x58f330], imm32` (values 0, 3, -1, 1, 4,
  each followed by `jmp` to the shared `xor eax,eax; dec eax; pop esi; ret`) -> `push imm8;
  call .cmpn+0x1320` plus a 3-byte nop. At +0x1320 it stores the shot type. If the pro is out and
  waiting (`R+0xcc == -1`), it sets the delay to 0 and turns mode 4 into 3. It ends with `ret 4`.
- The patcher reads the screen-height address and `hud_ylim` from the aiming gate, checks
  `hud_ylim`'s 30 bytes, and refuses half-patched states.

## All shots

The aiming code at VA 0x600623e0 reads the shot type:
- 0 (straight): skips the check.
- 4 (low punch): its own path.
- 3 (backspin): distance x 13/18.
- -1, 1 and 3: if the ball's terrain has hazard byte +0x22 > 0, the type is reset to 0 and a
  message plays (`jle` at VA 0x60062462).

`FUN_00424120` turns types < 2 into the curve `[esp+0x1c]` (VA 0x6006cf16). At VA 0x6006e488,
a curved shot takes the same branch as a straight shot from a hazard lie (`[0x578372 + t*0x30] != 0`),
so the lie's penalties still apply. `hud_game.c` `read_pro` sets `pro_shots = hazard > 0 ? 1 : 2`
(VA 0x602d6134).

The patch has two edits:
- the `jle` becomes `jmp`;
- `xor ecx,ecx; test al,al; setle cl; inc ecx` becomes `mov ecx,2` plus a 3-byte nop.

The pro page's hit test (`FUN_00435f00`, VA 0x6008b635) never checked the lie.

## In game, to check

- Aim near the bottom edge of the view, click: the shot goes.
- Open and close the pro's Match or Practice page while the pro waits, click a shot type, then
  the target: the shot goes.
- In the rough: Fade and Draw buttons show, and the shot curves, with the rough's loss of distance.
- A long draw or fade from the tee (pro with a high Power Hitter skill): it carries about as far as
  a straight shot to the same target, a little more at most, and curves back towards the line.

## Curve fix (`-CurveFix`), 2026-11-13

The report: "draws and fades don't really follow the flight path as designed. we're hitting like
500 yards instead".

### How a curved shot is launched (`FUN_00424120`)

1. The launch speed is solved for the distance `[esp+0x64]` (yards, clamped to the golfer's max;
   see `shot-distances.md`). Then the curve `[esp+0x1c]` (type < 2 ? type : 0) is applied.
2. Draw (VA 0x6006ed9a) or fade (VA 0x6006ee22):
   - the angle `R+0xe0` turns 30° (0x15555554) off the line;
   - for the pro, an existing spin of the wrong sign is halved;
   - `[esp+0x70]` gets the curve spin, 0xfdc656ab (draw) or 0x0239a955 (fade). It is added to
     `R+0xec` at VA 0x6006f131 and turns the ball spin/2 per tick in the air, about 1.5° per tick.
3. The speed boost (VA 0x6006edf0 draw, 0x6006ee7c fade):

| Yards | Boost |
|---|---|
| ≤ 249 | `speed += speed*16 / (330 - yards)` |
| 250–299 | `speed += speed*16 / (400 - yards)` |
| ≥ 300 | the same, from a saved copy of the speed |

Vanilla yards never pass 330, so the boost is ×1.06..×1.23. `-Distances modern` removed the cap.
The pro reaches 310 yards (skills 10/10) to 410 (Power Hitter 20), which gives:
- ×1.8 at 380 yards;
- ×4.2 at 395 yards;
- a divide by zero at 400;
- a negative divisor past 400: the emulated launch gave speed 0.

Neither free aim nor All Shots is involved: the boost depends only on the clamped yards.

### Patch

Both sites, `mov edx,[esp+0x64]; cmp edx,0x12b` (10 bytes, followed by `jg` rel32 for the draw
and `jg` rel8 for the fade), become `call .cmpn+0x1280` plus a 5-byte nop. The code at +0x1280:
`mov edx,[esp+0x68]; cmp edx,330; jle; mov edx,330; cmp edx,0x12b; ret`. `ret` keeps the flags.
`edx` is only used by the boost before it is reloaded, so nothing else sees the clamp. The patcher
finds each site by the `mov [esp+0x70], spin` in front of it, needs exactly two, and refuses a
half-patched state or code at +0x1280 that differs.

### Checks

- **unicorn**, the real launch code, shot max forced at the clamp (VA 0x6006d9e6):

| Max (yards) | Curved speed, as shipped | Curved speed, fixed | Straight speed |
|---|---|---|---|
| 250 / 300 / 330 | 5448 / 5153 / 5357 | the same | 4632 / 4442 / 4361 |
| 360 | 6005 | 5269 | 4289 |
| 380 | 7720 | 5269 | 4289 |
| 395 | 17723 | 5184 | 4220 |
| 410 | 0 | 5184 | 4220 |

- **Scratch copies:**
  - the installed program + `-CurveFix` and back gives the installed MD5;
  - a rerun has nothing to change;
  - from vanilla, defaults then all off, and curve-only then off, both give the vanilla MD5;
  - the disassembly of the sites and of +0x1280 is right.
- **Not checked:** the flight itself in the running game. The emulator has no sine table, so the
  flight was modelled in Python from the golfer tick (`FUN_004289e0`). That model's distances are
  only good for comparing shots with each other.
