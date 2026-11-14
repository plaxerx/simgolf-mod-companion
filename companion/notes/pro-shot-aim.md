# Pro shot aim: why it snaps, and what free aim would take

Status (2026-11-12): drafted as `-ProAim shift|off` (default shift; `-ProAim off` restores vanilla) in `Apply-CompanionPatches.ps1`.
Tested on scratch copies and under an emulator, not yet in the running game. See "Draft" at the end. The findings come from
static reading of the installed 0.1.36 binary (`Sim Golf Remastered.exe` = `golf.exe`,
ImageBase 0x60000000). The generated golf code is not in this repo, so the addresses below
are binary VAs, plus the original `FUN_xxxxxxxx` name found from its `push addr; call PORT_TRACE`.
Points marked **(verify)** are static readings that should be confirmed in a running game.

## Short answer

- **Can we do it?** Yes. The ball flight is not the limit. The launch uses a full
  32-bit angle and an exact distance, and the ball flies in 1/1024-tile units. The snapping
  happens only in how the **target** is picked and stored: it is a whole tile, and at launch
  that becomes the **centre** of the tile.
- **How?** Store a sub-tile target point and use it at launch. That needs three hooks: the aim
  pick, the stored target and the launch. Hold Shift for free aim, as you suggested. Releasing
  Shift keeps today's snap, which is what makes putts lock onto the cup.
- **At what cost?** As a byte patch: a medium-sized patch with two code-cave hooks, about
  250 bytes of new code, and Shift read through `GetProcAddress`. It can't be checked without
  running the game. As a source change it is small and clean, but it needs a build. Saves are
  not affected. Balance changes only when the player holds Shift.

## Units

1 tile = 1024 world units = **25 yards**. The shot readout and the hole tool both turn
distance into yards as `dist * 25 >> 10`. Snapping to tile centres therefore means a 25-yard grid.

## How the aim works today

Golfer records are 0x100 bytes at `R(slot) = 0x5794b8 + slot*0x100`. The pro's slot is in
`[0x5a59f8]`. "Dock mode" `[0x567afc]` is 3 while the pro waits for a shot and 4 once it is
committed.

| Step | Where | What it does |
|---|---|---|
| 1. Mouse to tile | `FUN_00430020(mx, my, &tx, &ty, 0)`, called at VA 0x60061c05 in `FUN_0040f5c0` (the course frame) | Screen to **integer** tile, written to `[0x543d08]`/`[0x543d0c]` (the hovered tile). |
| 2. Centre or corner | `FUN_0040f5c0`, VA 0x60062201..0x600623d5 (dock mode 3) | Projects the tile centre `(t<<10)\|0x200` and the 4 tile corners `(t+i)<<10, (t+j)<<10` (i, j in {0, 1}) to the screen with `FUN_0042fb90`, and keeps whichever is closest to the mouse (distance helper at VA 0x60044b08). A corner moves the hovered tile to `t+i, t+j` and sets **bit 28 of `R+0x10`** (VA 0x60062347, `or byte [slot*256+0x5794cb], 0x10`; cleared each frame at VA 0x600622a8). |
| 3. Stored target | VA 0x600623b0 / 0x600623bc | `R+0xc4` / `R+0xc8` (`0x57957c` / `0x579580` for slot 0) = **tile ints**. The preview's world point goes to the frame locals `[esp+8]`/`[esp+0xc]`: the centre, or the corner when bit 28 is set (`cmovb` at VA 0x600623c3). |
| 4. Preview facing and club | VA 0x600627d6..0x600628c7 | `FUN_004672d0(dx, dy)` (an atan2 to a 32-bit angle) is rounded to **8 directions** into `R+0x1a`. That only picks which way the golfer **sprite** faces (`(camera - dir + 6) & 7`). The club `R+0x1c` = clamp((max - d) * 60 / (3 * max), 0 or 1, 11): **12 clubs** picked from the distance. Distance is clamped to the pro's maximum, `FUN_00422530(slot)`. |
| 5. Commit | VA 0x60069fb3 (dock mode becomes 4) | `R+0xcc` / `R+0xd0` (`0x579584` / `0x579588`) = `R+0xc4` / `R+0xc8`. Still tile ints. `read_pro` in `hud_game.c` reads `0x579584 == -1` as "no shot committed". |
| 6. Launch | `FUN_004289e0` (golfer tick) calls `FUN_00424120(slot, 1, -1, 0, 0)` at VA 0x60071f2b when `R+0xcc != -1` | With param3 = -1 the target is `(R+0xcc << 10) + 0x200 - ball`, i.e. the **tile centre**, at VA 0x6006cfaf..0x6006cfc8. **Bit 28 is not used on this path**, so a corner pick flies to the centre of the tile below and right of the corner the preview showed **(verify)**. The angle `FUN_004672d0(dx, dy)` is stored at full precision in `R+0xe0` (VA 0x6006d041). With param2 = 1 the AI planner is skipped (`or ebx, [ebp+0xc]; jne` at VA 0x6006d066). |
| 7. Flight | the rest of `FUN_00424120` | Error from skills, wind and lie (`FUN_00422430`, random rolls), then flight in world units. No tile rounding here. |

For comparison:

- **The AI** goes through `FUN_00424120(slot, 0, -1, ...)`. It aims at the pin tile and then
  `FUN_00422fb0` (the shot planner) searches whole-tile candidates within ±10 tiles. If no
  candidate passes, it falls back to the **pin**. The planner has a branch that only accepts
  the pro's own tile, but the pro's normal shots never reach the planner.
- **The hole-design test golfer** (slot 0x99, `FUN_004226a0`) passes a world target and
  honours the corner flag.

## What limits the aim (answer to "which part")

1. **Not a table of allowed targets.** No such table exists.
2. **The mouse-to-tile conversion** (`FUN_00430020`) returns whole tiles. The corner pick
   (step 2) is the only refinement, so the preview offers centres and corners: a half-tile
   (12.5-yard) lattice.
3. **The stored target is a tile** (`R+0xc4/c8` to `R+0xcc/d0`), and **the launch turns it
   into the tile centre** (step 6). The ball's aim point is therefore on the 25-yard grid of
   tile centres, and corner picks are dropped **(verify)**.
4. **The 8 directions and 12 clubs are not limits on the flight.** The 8-way direction only
   sets the golfer's facing. The flight uses the full-precision angle in `R+0xe0`. The club is
   picked from the distance. As far as I traced, the carry comes from the exact distance (in
   whole yards) rather than from a club step **(verify)**.
5. **The ball-flight code is continuous** (1/1024 tile). No physics rewrite is needed.

### Why it "still snaps to the hole"

The cup sits at the centre of the pin tile (the AI aims at `(pin<<10)|0x200`). Both the
preview's centre pick and the launch snap to tile centres. So whenever the mouse is in the pin
tile and closer to its centre than to a corner, the target **is** the cup exactly. That is the
lock you see. I found no separate "aim at the hole" code on the pro's path. The planner's
fall-back to the pin is AI-only. The putting branch of `FUN_00424120` (distance under 25,
VA 0x6006d80d) reads the 8 neighbour tiles around the target for slope and break, but it did
not look like it replaces the target **(verify)**.

So a Shift "anti-lock" fits the code: holding Shift bypasses the tile snap (step 2) and the
centre rounding (step 6) together. That also removes the cup lock, but only while Shift is held.

## Options

### (a) Byte patch to the installed program: feasible, medium size

Three sites, each found by a unique byte signature in 0.1.36:

1. **Aim pick**, VA 0x600623c3: the 18 bytes
   `0f 42 54 24 0c 89 54 24 0c 0f 42 74 24 08 89 74 24 08` (the two `cmovb` and their stores).
   Replace them with `call cave` plus nops. Flags survive the call, so the cave first does the
   `cmovb` itself. Then, if Shift is down, it refines the point with a coarse-to-fine search:
   steps 512, 256 ... 16 units around the tile centre, 9 points per level, each one projected
   with `FUN_0042fb90(wx, wy, &sx, &sy, 0)` and measured against the mouse at
   `[esp+0x22c]`/`[esp+0x218]` (+4 inside the cave), about 54 projections in all. It writes the
   point to the frame's `[esp+8]`/`[esp+0xc]` (the preview, facing and yardage follow it), sets
   `R+0xc4/c8` to the point's tile, and saves `(fx, fy)` in the cave's data.
2. **Launch**, VA 0x6006cfc0: the 9 bytes `b8 00 02 00 00 01 c7 01 c6` (`mov eax, 0x200;
   add edi, eax; add esi, eax`). Replace them with `call cave2` plus 4 nops. cave2 recomputes
   the tile from `(edi + ecx) >> 10` and `(esi + ebx) >> 10`. If `[ebp+8] == [0x5a59f8]` (the
   pro), `[ebp+0xc] != 0` (a player-chosen shot) and the tile matches the saved point, it uses
   `fx - ecx` and `fy - ebx`. Otherwise it adds 0x200 as vanilla does. AI golfers take the same
   path with param2 = 0, so the guard is required.
3. **Shift:** nothing in the program imports a key-state call (no `SDL_GetModState`, and
   USER32 has only `MessageBoxA`). It does import `GetModuleHandleA` and `GetProcAddress`, so
   the cave can resolve `GetAsyncKeyState` from USER32 once and cache it.

Where the code goes: the `.cmpn` section has 0xA0..0x1FF free (352 bytes, between the
staff-names code and its name tables). The patcher would have to keep `.cmpn` when only
`-ProAim` wants it, the same way `-PixelHdFix` does now. Round trip: `-ProAim off` restores the
two sites and clears the cave. The 0.1.36 signatures above are each unique.

Cost and risk: it is the biggest patch in the script. Most of the asm is the projection
search. A mistake crashes or mis-aims only during pro shots. It needs at least one live test
(launch a scratch copy of the game while you aren't playing, aim with and without Shift, and
check that putts still lock onto the cup without Shift). That is why it is **not drafted
here**: the task allowed a draft only if it was clearly safe and small.

A tiny side fix is possible: at site 2, honour bit 28 for the pro and add 0 instead of 0x200,
so corner picks land where the preview shows. It is one 9-byte hook and a cave of about
30 bytes. It doubles the resolution (to a 17.7-yard lattice) but is not free aim.

### (b) Source change that needs a build: the clean route

- A translator patch (`tools/translate/golf.aim.json` style) on `FUN_0040f5c0` replaces the
  centre/corner loop with `pro_aim_pick(mx, my, &tile_x, &tile_y, &wx, &wy)` in
  `port/src/port/golf/aim_hooks.c`. Shift comes from `SDL_GetModState() & KMOD_SHIFT`, and an
  exact screen-to-ground inverse is available on the port side.
- A second patch on `FUN_00424120` replaces the `(R+0xcc << 10) + 0x200` target on the
  `param2 != 0` path with `pro_aim_target(slot, axis)`.
- Setting: `[ui] pro_aim = snap | shift | free` in `data/mods.ini`. The default `snap` is vanilla.
- No compiler on this machine, so this has to wait for a build environment, or go upstream.

### (c) Rewriting shot physics: not needed

## Balance and saves

- **Saves:** no format change. The committed target `R+0xcc/d0` is transient (set at commit,
  used at the swing) and stays a tile int. The fine point lives only in the cave or port data.
  Saving between commit and swing loses it, and the shot falls back to the tile centre. The
  patch touches only the program, with an exact vanilla round trip.
- **Balance:** skill error, wind and lie still apply, so an exact target is not an exact
  landing. Free aim still makes the pro clearly stronger. You can lay up exactly short of
  hazards, pick the safe side of a green and place approach shots within yards instead of on
  a 25-yard grid. Expect better scores and possibly faster skill growth, since skills grow from
  shot results in `FUN_00407e00`. That matters most in matches and tournaments against AI
  golfers, who stay on whole tiles. Putting is the exception: vanilla's tile snap gives an
  exact cup lock, and free aim would make putts **worse** without it. That is the reason for
  Shift-to-free-aim, with snapping as the default.

## Recommendation

1. Use **Shift = anti-lock** with snapping as the default. Default play is unchanged and putts
   keep the cup lock. Hold Shift for exact placement.
2. On this machine, implement it as the **`-ProAim on|off` byte patch** in
   `Apply-CompanionPatches.ps1` using the design in (a), but only as a session that can launch
   a **scratch copy** of the game to test the asm. If a build becomes available, prefer (b):
   it is simpler, it uses the port's exact screen-to-ground inverse, and it can live in mods.ini.
3. Optional and cheap: the corner fix (honour bit 28 at launch). It removes the
   preview-versus-landing mismatch even without free aim.

Things to confirm in game before or while implementing:

- Corner-aimed shots land on the centre of the tile below and right of the shown corner.
- The carry follows the exact distance, not the club step.
- Putts aimed at the pin tile go to the cup centre.

## Draft: `-ProAim shift` (2026-11-12)

This implements option (a) with Shift as the anti-lock. It is on by default; `-ProAim off` removes it.

**Sites**, each found by a unique signature that includes nearby bytes. The aim site's signature
also checks `[0x5a59f8]` and `R+0xc4`.

- Aim site, VA 0x600623c3: the 18 bytes become `call .cmpn+0xD00` followed by a 7-byte and a
  6-byte nop.
- Launch site, VA 0x6006cfc0: the 9 bytes become `call .cmpn+0xDFA` followed by a 4-byte nop.
- The projection function `FUN_0042fb90` (VA 0x6007f664) is read from the corner-loop call
  `lea edx,[esp+0x224]; push edx; push ecx; push eax; call; add esp,0x14; mov eax,[esp+0x218];
  mov ecx,[esp+0x228]`. That call also confirms the mouse locals.
- `GetModuleHandleA` and `GetProcAddress` come from the KERNEL32 import table.

**Section layout** (`.cmpn`; staff-name strings end at 0xC42):

| Offset | Contents |
|---|---|
| +0xC80 | data: GetAsyncKeyState pointer (1 = lookup failed), valid flag, saved tile x/y, saved point x/y, mouse, projection outputs |
| +0xCA8 | the 8 neighbour directions |
| +0xCB8 / +0xCC8 | `USER32.dll` / `GetAsyncKeyState` |
| +0xD00 | aim hook |
| +0xDFA | launch hook |
| +0xE4E | dist (one projection plus squared screen distance) |
| +0xE84 | Shift check |

The code is 461 bytes. The section is kept whenever any of staff names, the Pixel HD fix or pro
aim is on.

**Aim hook (+0xD00):**

1. It runs the original two `cmovb`s and their stores.
2. It saves all registers (`pushal`) and clears the valid flag.
3. If Shift is down, it copies the mouse from the frame (`[esp+0x24+0x228]` and `+0x218`) and
   starts from the point the game picked.
4. It runs a pattern search with steps of 512, 256, 128, 64, 32 and 16 world units. At each step
   it tries the 8 neighbours and keeps the one nearest the mouse on screen. That is 49
   projections per frame while Shift is held.
5. It writes the result to the preview point `[esp+8]`/`[esp+0xc]`, to the hovered tile
   `[0x543d08]`/`[0x543d0c]` (which draws the tile outline) and to `R+0xc4`/`R+0xc8`.
6. It saves the point and its tile and sets the valid flag.
7. It restores the registers (`popal`). eax (the slot), ebx and edi come back unchanged, and esi,
   ecx and edx hold what vanilla leaves in them.

**Launch hook (+0xDFA):** it uses the saved point only when all of these hold:

- `[ebp+0xc] != 0` (a player shot);
- `[ebp+8] == [0x5a59f8]` (the pro);
- the valid flag is set;
- `(edi + ecx) >> 10` and `(esi + ebx) >> 10` equal the saved tile.

Otherwise it adds 0x200 as vanilla does.

**How it was checked:**

- **Assembly:** written with keystone and listed back with capstone.
- **Emulation:** the code was run under unicorn, with a mock isometric projection that includes
  hills (32 by 16 px tiles) and mocked Windows calls. Results:
  - With Shift held, 400 random targets all landed within 1 screen pixel of the mouse. The
    error in yards depends only on pixel size.
  - With Shift released, the result was the same as the vanilla pick in 200 out of 200 cases.
  - The Windows functions are looked up once.
  - At launch, the saved point is used only for the pro's matching player shot. The AI, other
    slots, a different tile and a cleared flag all get the tile centre.
- **The patched files:** the same emulation was run on the section bytes taken from the patched
  files.
- **Round trips** on scratch copies, compared by hash:
  - vanilla to pro aim on to off gives vanilla;
  - the installed state to on to off gives the installed state;
  - on twice gives the same file;
  - the result is the same with or without staff names and the Pixel HD fix in the section.

**To check in game:**

- Shift free aim follows the mouse smoothly, and the yardage readout changes continuously.
- Without Shift, aiming is unchanged and putts still lock onto the cup.
- A Shift-aimed shot flies to the point shown, not to the tile centre.
- Holding Shift while aiming has no other effect in the game (a key binding, a selection mode).
- The frame rate holds while Shift is held (49 projections per frame).
- AI golfers and tournament play are unchanged.
