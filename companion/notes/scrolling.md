# Scrolling: why smooth scroll felt sticky, and live scrolling

User, 2026-11-14: "the remastered's smooth scroll is just a sticky laggy
version rather than crisp scrolling like in modern games ... we want it to be
butter smooth when we move with no lag."

Done: `-LiveScroll` (patcher item 34, `src/live_scroll.c`). This file is the
research behind it and what is left.

## Golf's frame clock

golf's main loop (FUN_0040f5c0) draws the course once per game tick. The tick
starts with `timeGetTime` at golf `0x40fc29` (kept at `[esp+0x1f0]`); at the
end the loop busy-waits, pumping messages (`0x45bf80`), until

    start + (flag 0x20000 ? 250 : 175) / 2   ms      (golf 0x41e639..0x41e6b1)

so a frame is **87 ms (11.5 frames/s)**, 125 ms with game flag `0x20000`; the
logs show 10-11. The simulation and the drawing are one pass, so a shorter
wait speeds up the whole game, and golf has no draw-only path to call between
ticks. The fix has to be in the presenter.

## Threads

- **Game thread** (also SDL's event thread): golf, and between its frames
  `win_yield()`: `pump_sdl()` (events to `camera_input_event`), then
  `camera_input_tick()` (pan keys). About 300 yields a second while golf
  waits, none while it works on a frame (10-50 ms, 40-50% of the time on a big
  course). So the camera only moves at yields.
- **Render thread** (`render_main`, hd_native.c): 100-500 presents a second.
  `upload()` takes golf's newest picture; `compose()` draws it.

## Two separate problems

1. **Lag.** `upload()` started a slide from where the old picture is on screen
   to the new one, one game frame long (x1.2 for keys). The picture was drawn
   with the camera of golf's frame start. Together the view ran 120-240 ms
   behind the input (measured) and kept moving after it stopped.
2. **Frame rate.** A new course picture costs the render thread 100-150 ms on
   a 158 x 158 map at 1600 x 900 (profile, per new picture: terrain render
   30-40 ms, relief build 25-35 ms, reflections 10-16 ms, cast shadows 5-7 ms,
   upload 5 ms, the rest the guard band and layer copies). That is more than
   golf's frame period, so while the camera moved every presented frame was a
   new picture: 9-16 presented frames a second, CPU bound, whatever the GPU.
   Between new pictures a frame costs 2-8 ms. (`fixes.drag_scroll=0` halves
   the cost in a headless 800 x 600 run but not in a window, and it removes
   the guard band live scrolling needs.)

This second one is the "sticky" feel, and it is there with smooth scrolling
off as well (whole-tile jumps at 10 a second).

## Live scrolling (what the patch does)

`ls_frame()` runs on the render thread in place of the `upload(t, now)` call
(exe 0x601e9f50):

- **The camera now.** Pan keys: `g_sub` (the sub-tile camera) at the last key
  tick + speed x time since, through `hd_ui_content_to_tiles` and
  `keep_on_map`, i.e. what the next `keys_pan` will set. Drag: the cursor now
  (`GetCursorPos`, the window mapping `g_map_*`, the edge clamp) through
  `g_drag`'s anchor, i.e. what the next `drag_to` will set; if the button is
  physically up the last position is kept.
- **Placing the picture.** offset = (camera now - camera of the picture) in
  canvas px, written to `Rt.off_x/off_y` with `off_dur = 1e12`, so
  `slide_offset()` returns it as is. Below half a pixel it is 0.
- **Holding the picture.** While the camera moves, `upload()` is skipped (the
  guard band and the overscanned sprite lists of `fixes.drag_scroll` cover a
  screen each way). A new picture is taken when the camera has been still for
  60 ms, the offset passes 70% of the canvas width or 60% of its height, the
  picture is 0.8 s old (`hold_ms`), or the left mouse button is down.
- **Release.** `ls_adopt()` runs on the game thread before a pan key's or the
  drag button's release is stored (three sites): the camera becomes the one
  on screen and the key clock restarts.
- Only while the sub-tile camera owns the camera (`sub_owns()`), the frame is
  layered, same zoom and rotation, no zoom glide. Otherwise the remaster's
  slide runs as before.

State for tests at the blob's `ls_state` (magic `LSC1`): counters, the
displayed camera, a debug cursor, `why` (the reason a frame was not ours).

### Measured (a copy, 158 x 158 map, 1600 x 900 window, 2 s key pans)

| | as shipped | live |
|---|---|---|
| presented frames while moving | 9-16 /s | 100-140 /s |
| behind the input | 120-240 ms | 0-40 ms |
| frames over 50 ms per pan | all | 3 |
| start after key down | 40-135 ms | 4-19 ms |

Drag: cursor mapping equal to the game's at 5 of 5 points; a drag with the
cursor ahead of the events: 316 predicted frames, no step backwards, the
release adopted the camera on screen.

## What is left

- **The skip when a picture is taken while moving** (about every 0.7 s of a
  long pan, 100-150 ms). To remove it the new picture's work has to leave the
  render thread or get cheaper: the terrain re-rendered from scratch for every
  camera (9,000+ batches zoomed out), the relief map and the reflections
  rebuilt per picture. That is renderer work in the source (hd_terrain_native,
  course_relief, hd_art), not a patch.
- **Golfers stand still** for up to 0.8 s at a time while the view moves.
- **Start of a key pan** waits for the game thread to see the key (up to one
  golf frame). The render thread could read the keyboard itself, but pan keys
  can be rebound (keymap.c).
- golf's own camera moves (shot follow) still slide at 10 pictures a second.

## Flicker: what the same data says

Not yet chased (needs the user's description of what flickers and when), but
the candidates from this work:

- A picture taken mid-move replaces terrain, relief shadows and reflections
  in one frame after a long frame: a visible pop if anything in them depends
  on the camera (the relief map does).
- Unlayered frames: golf's modal loops and some redraws publish a frame with
  no course layer (`g_snap_fresh` 0); the presenter then cuts to a single
  picture and back, dropping the slide and the kept picture.
- The art pack loads textures on first sight (`hd_art_prepare`), so sprites
  entering the view can appear a frame or two late in their original pixels.
