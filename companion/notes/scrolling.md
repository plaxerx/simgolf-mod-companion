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
  `slide_offset()` returns it as is. Below half a pixel it is 0. It is capped
  at `lead_pct` percent of the canvas width and height (the patcher's
  `-ScrollLead`, 12): the view then waits at that edge.
- **Holding the picture.** While the camera moves and the offset is inside the
  cap, `upload()` is skipped and the picture slides at the full frame rate. A
  new picture is taken when the camera has been still for 60 ms, the offset
  reaches the cap, the picture is 0.8 s old (`hold_ms`), or the left mouse
  button is down.
- **Release.** `ls_adopt()` runs on the game thread before a pan key's or the
  drag button's release is stored (three sites): the camera becomes the one
  on screen and the key clock restarts.
- Only while the sub-tile camera owns the camera (`sub_owns()`), the frame is
  layered, same zoom and rotation, no zoom glide. Otherwise the remaster's
  slide runs as before.

State for tests at the blob's `ls_state` (magic `LSC1`): counters, the
displayed camera, a debug cursor, `why` (the reason a frame was not ours),
`enabled`, `lead_pct`, `sync_on`.

### Why the lead is small (a mistake, 2026-11-15 to 16)

The first version held the picture until the slide had used 70% of the canvas
width (60% of the height), on the belief that `fixes.drag_scroll`'s guard
band and overscan cover a screen in every direction. Timing looked excellent
(100-140 presented frames a second while moving). It was only measured, not
looked at. Frame recordings the next day showed the uncovered part as bare
ground with thin black seams, no trees, buildings or golfers, until the next
picture popped them in: golf's tests are widened by a screen, but `hooked()`
in hd_art.c follows a sprite only when `snap_begin` finds it on the canvas, so
nothing beyond the picture is ever recorded, and the guard band is replayed
ground strips, not a fresh render. With the cap at 12% the uncovered strip is
small and short-lived, and full-speed key pans are back to one picture per
presented frame.

## Ground and picture in step (the flicker fix)

Found with the frame recorder (below). `hdt_capture()` (game thread, in
`hd_present`) writes the one pending scene `g_pending` with `frame` = the
serial the frame will get, a few ms before `g_frame_serial` is raised.
`take()` (render thread, from `hdt_render`) takes the pending scene only if
`g_pending.frame <= shown`. So a render thread that uploads frame S after the
game thread has captured the scene for S+1 (in that gap, or because it was
busy when S came out) finds only scene S+1, cannot take it, and draws picture
S on the ground of an older camera. With the camera at rest nothing shows;
while it moves the ground is a camera step off for that picture.

`take_picture()` in live_scroll.c, used in every mode: when the newest frame
is not the one on screen, (1) if `g_pending.frame > g_frame_serial` put the
picture off to the next presented frame (at most 50 ms), else (2) call
`take(renderer, g_frame_serial)` and then `upload()`. A picture published in
between is at least as new as the ground, and `compose()`'s own `take()` then
brings the ground level.

Recorded (bridge `hddump`: the course part of every presented frame, 640 px
wide; frames compared after shifting by the known camera motion; two pans
each way at key speed):

| | pictures | A-B-A frames | large pops | largest change |
|---|---|---|---|---|
| as shipped | 139 | 4 | 8 | 37% of the picture |
| as shipped + in step | 131 | 0 | 0 | 4% |
| live, not in step | 136 | 15 | 25 | 55% |
| live + in step | 103 | 1 (2%) | 3 (7%) | 7% |

At rest and through zoom steps the recorder found nothing in any mode.

## What is left

- **Full-speed pans are one picture per presented frame**, 100-150 ms each on
  a big course (more on a busy PC), as shipped. To change that the new
  picture's work has to get cheaper or leave the render thread (the ground
  re-rendered from scratch for every camera, the relief map and reflections
  rebuilt per picture), or sprites have to be recorded beyond the canvas so
  the picture can be held longer. Both are renderer work in the source
  (hd_terrain_native, course_relief, hd_art), not a patch.
- **Start of a key pan** waits for the game thread to see the key (up to one
  golf frame). The render thread could read the keyboard itself, but pan keys
  can be rebound (keymap.c).
- golf's own camera moves (shot follow) still slide at 10 pictures a second.
- Not looked at yet: flicker that is not about scrolling (the user has not
  said which they see), unlayered frames from golf's modal loops, textures
  loading on first sight.
