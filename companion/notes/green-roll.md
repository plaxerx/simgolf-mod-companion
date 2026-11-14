# Green roll (`-GreenRoll on|off`, default on)

Status (2026-11-13): implemented in `Apply-CompanionPatches.ps1`. Checked under unicorn and on
scratch copies. Not yet tried in the running game.

## The roll code (port v0.1.36, `FUN_004289e0`, the golfer update)

Field offsets are from the golfer record `R(slot) = 0x5794b8 + slot*0x100`. The compiled code
uses `0x5794c8 = R+0x10` as its base.

| Field | Offset |
|---|---|
| ball x, y, height | R+0xd4, +0xd8, +0xdc (grounded when height <= 1) |
| roll angle (32-bit turn) | R+0xe0 |
| speed | R+0xe4 (the ball moves speed/16 world units a tick; 1 tile = 1024) |
| spin | R+0xec |
| shot origin (ball position at launch) | R+0xc4, +0xc8 |

For a grounded ball, each tick (VA 0x60070666..0x600709c2):

1. `dir8 = ((angle >> 28) + 1) >> 1 & 7`.
2. `slope = FUN_0040c450(x, y, dir8)` (VA 0x6004e499): the corner-height gradient along dir8,
   clamped to ±1 per axis on diagonals. It is 0 in sand and pot bunkers.
3. `friction = clamp(terrain[type].byte_0x21 - slope, 0, 99)`. The terrain table is at 0x578350,
   rows of 0x30, copied from image `0x4c1a40` in `image\golf.bin`. Byte +0x21 values: tees 3,
   green 3, fairway 3, firm fairway 4, rough 2, deep rough 2, sand 1, water 0.
4. `side = FUN_0040c450(x, y, (dir8 + 2) & 7)`: the break.
5. Near a tile edge where the neighbour terrain differs: friction = max(friction, 2).
6. **If the shot's origin tile is a green**, the game uses friction = the raw terrain byte of
   the current tile and side = 0. So putts struck from the green have no slope effect and no
   break.
7. Friction >= 5: the speed moves toward 2048 (`speed += (64 - speed/32) / 2`). This is
   capped to 4 once 128 ticks have passed since `[0x56962c + slot*4]`. Friction <= 4:
   `speed -= (speed >> f) / 2`.
8. `angle -= side << 25`: 1/128 of a turn (2.8 degrees) per slope step, every tick.
9. Weather hook `weather_game_roll_friction` (VA 0x601e87e9, call at 0x6007097d). With
   `[environment] gameplay=0` it returns friction unchanged.

`[esp+0x68]` is the terrain under the ball (set at VA 0x6006ffe3; 0x14 when off the map).

## The patch (section +0x1240..+0x127F)

Both hooks check `[esp+0x6c] == 1` (the frame's `[esp+0x68]` plus the return address).

- **Friction site**, VA 0x60070747, 15 bytes. Vanilla: `cmp ecx,5; jl +0x20f; mov esi,[0x834170]`.
  Patched: `call +0x1240; jl (same target); nop4`. The hook sets friction to at most 4 on a
  green, then runs the `mov esi` (esi is dead on the jl path) and the `cmp`. The kept `jl` uses
  the flags of that `cmp`.
- **Break site**, VA 0x60070964, 5 bytes. Vanilla: `shl eax,0x1a; sar eax,1`. Patched:
  `call +0x1260`. On a green it does one more `sar eax,1` (exact, since the value is a multiple
  of 2^25).
- The jl target is the `mov ebx,0x5794c8` just before the break site. `Find-GreenRoll` checks
  that, and reads the tick address back from the hook to rebuild the vanilla bytes.

## Checks

- **unicorn**, running the real code from the friction site to the speed store, vanilla
  against patched:
  - covers greens, tees, fairway, firm fairway, rough, sand and off-map tiles;
  - friction 0..9, side slope -3..3, timer before and after 128 ticks;
  - registers and stack are kept;
  - off a green, angle and speed are identical to vanilla;
  - on a green, speed equals vanilla at min(friction, 4) and the turn is exactly half.
- **Scratch copies:**
  - the installed program and the vanilla backup patch to the same bytes;
  - a rerun has nothing to change;
  - off and back on gives identical bytes;
  - all off returns the vanilla MD5, and green-only then off does too;
  - the section bytes match the emulated build.

## In game, to check

- An approach onto a downhill green slows and stops instead of speeding off the green.
- Breaking chips still curve, but less.
- Putts from the green behave as before.
