// Live-camera scrolling for SimGolf Remastered 0.1.37 (companion patch).
//
// Built once with MSVC (x86) by build_live.py into live_scroll.json; the
// patcher copies the bytes into the .cmpn section and points four call sites
// at them. No C runtime: only the program's own functions (by address) and a
// few user32 calls found through its GetProcAddress.
//
// What it changes (notes/scrolling.md). The remaster's presenter eased every
// new course picture into place over one game frame (~90-105 ms), so the view
// trailed the input by 140-190 ms. Here the render thread, on every presented
// frame, puts golf's last picture where the camera is *now*:
//
//   offset = (live camera - camera the picture was drawn with), in canvas px
//
// and it works the live camera out itself, because the game thread only looks
// at input between golf's frames (it is blind for the ~40 ms golf spends on a
// frame):
//   - pan keys: the camera at the last key tick + speed x time since, the same
//     sum the next tick will make (keys_pan, camera_input.c);
//   - drag: the cursor's position right now through the same mapping and
//     anchor the next mouse event will use (drag_to).
// When the game thread gets to a key or button release it takes over the
// camera that was on screen (ls_adopt), so nothing snaps back.
//
// Holding the picture. A new course picture costs the render thread 100-150 ms
// (terrain, relief, reflections, the guard band: measured on a 158x158 map),
// more than golf's frame period, so with a moving camera every presented frame
// was a new picture and the view ran at about 10 frames a second. While the
// view moves, upload() is skipped and the picture on screen slides at the full
// frame rate, but only a little way: past the picture's edge there is the
// guard band's ground and nothing else (golf's sprites are only recorded where
// they touch the canvas), so the slide may uncover at most lead_pct percent of
// the view. Up to there the view is where the camera is; beyond, it waits at
// that edge for the next picture. A new picture is also taken when the view
// stops, after hold_ms, and while the left mouse button is down (a tool at
// work shows at once).
//
// Only while the camera is the player's (the sub-tile camera owns it). Camera
// moves golf makes itself (shot follow, jumps) keep the remaster's slide.
//
// Ground and course in step (an upstream flicker, in every mode). The hi-res
// ground is a separate hand-over: hdt_capture() leaves one pending scene
// stamped with the frame it belongs to, and the renderer takes it when that
// frame is on screen (take() in hd_terrain_native.c). The game thread captures
// the scene for frame S+1 a few ms before it publishes frame S+1. A render
// thread that took picture S in that gap, or just before it, found the pending
// scene already S+1 and kept the older ground: one picture with the ground a
// camera step away from everything standing on it. take_picture() closes the
// gap: no picture is taken while a scene newer than the published frame is
// pending, and the scene is taken first, then the picture.

typedef unsigned int u32;
typedef unsigned char u8;

#define I32(a) (*(volatile int *)(a))
#define U8(a) (*(volatile u8 *)(a))
#define F64(a) (*(volatile double *)(a))
#define F32(a) (*(volatile float *)(a))

// ---- the program (0.1.37; the patcher checks its signature before installing)
// Rt (hd_native.c render thread state)
#define RT_LAYERED 0xa0
#define RT_SHOWN 0xac         // shown_serial
#define RT_COURSE 0xa8
#define RT_CAM 0x21bd8        // HdUiCamera: x, y, zoom, rot, ax, ay, bx, by, serial, ox, oy, drag_serial
#define RT_OFF_X 0x439f8
#define RT_OFF_Y 0x43a00
#define RT_OFF_T0 0x43a08
#define RT_OFF_DUR 0x43a10
#define RT_ZON 0x43af8
// hd_native.c
#define FN_UPLOAD 0x601ee680   // upload(t, now): ecx, xmm0
#define FRAME_SERIAL 0x60ddf8c4   // g_frame_serial: the newest published frame
// hd_terrain_native.c
#define FN_HDT_TAKE 0x601f6150    // take(renderer, shown): ecx, edx
#define HDT_PENDING_FRAME 0x60e266d8   // g_pending.frame
#define CFG_SMOOTH 0x603933a4
#define CFG_DRAG_FIX 0x603933c4   // fixes.drag_scroll: the guard band is drawn
#define FRAME_W 0x60393230
#define FRAME_H 0x60393234
#define MAP_OK 0x60e263e0     // byte
#define MAP_SX 0x60e263e4     // floats
#define MAP_SY 0x60e263e8
#define MAP_OX 0x60e263ec
#define MAP_OY 0x60e263f0
#define MAP_W 0x60e264ec
#define MAP_H 0x60e264f0
// hd_ui.c
#define SUB_TX 0x60c3e720
#define SUB_TY 0x60c3e728
#define FN_SUB_OWNS 0x601e24d0
#define FN_KEEP_ON_MAP 0x601e2bdc
#define FN_CAMERA_SET 0x601e2afb
#define FN_CONTENT_TO_TILES 0x601e29f2
// camera_input.c
#define HELD 0x60b444b0       // int[4]: W A S D
#define LAST_TICK 0x60b444f0
#define PAN_SPEED 0x60393198
#define EDGE_SCROLL 0x60b444ac
#define DRAG_SERIAL 0x60b44460
#define DRAG_BUTTON 0x60b44468
#define DRAG_PANNING 0x60b4446c
#define DRAG_X0 0x60b44478
#define DRAG_Y0 0x60b4447c
#define DRAG_SUB_X0 0x60b44488
#define DRAG_SUB_Y0 0x60b44490
#define FN_COURSE_ACTIVE 0x601de978
#define WIN_SCREEN_W 0x6039300c
#define WIN_SCREEN_H 0x60393010
// clock, imports
#define FN_PORT_NOW 0x60001cc0
#define IAT_GETMODULEHANDLEA 0x603906b0
#define IAT_GETPROCADDRESS 0x603906c0
// golf
#define ZOOM 0x4c2844
#define ROT 0x5685f4

#define sub_owns() (((int (__cdecl *)(void))FN_SUB_OWNS)())
#define keep_on_map(x, y) (((void (__fastcall *)(double *, double *))FN_KEEP_ON_MAP)((x), (y)))
#define camera_set(x, y) (((void (__cdecl *)(double, double))FN_CAMERA_SET)((x), (y)))
#define content_to_tiles(dx, dy, tx, ty) (((void (__cdecl *)(double, double, double *, double *))FN_CONTENT_TO_TILES)((dx), (dy), (tx), (ty)))
#define course_active(now) (((int (__vectorcall *)(double))FN_COURSE_ACTIVE)(now))
#define port_now() (((double (__cdecl *)(void))FN_PORT_NOW)())
#define upload(t, now) (((void (__vectorcall *)(char *, double))FN_UPLOAD)((t), (now)))
#define hdt_take(r, shown) (((void (__fastcall *)(void *, long))FN_HDT_TAKE)((r), (shown)))

typedef struct { long x, y; } Pt;
typedef void *(__stdcall *GetModuleHandleA_t)(const char *);
typedef void *(__stdcall *GetProcAddress_t)(void *, const char *);

// ---- state. The first fields are read and poked by the tests (bridge peek/poke at the blob's data address).
struct LsState {
  volatile u32 magic;          // +0x00 'LSC1'
  volatile int enabled;        // +0x04 0 = the remaster's own slide (A/B)
  volatile int dbg_cursor;     // +0x08 test: 1 = the cursor is dbg_x, dbg_y (frame px), button dbg_down; 2 = probe the real one
  volatile int dbg_x, dbg_y;   // +0x0c, +0x10
  volatile int dbg_down;       // +0x14
  volatile u32 frames;         // +0x18 presented frames the offset was ours
  volatile u32 key_frames;     // +0x1c ... of them with key prediction
  volatile u32 drag_frames;    // +0x20 ... with cursor prediction
  volatile u32 adopts;         // +0x24 releases that took the displayed camera
  volatile int mode;           // +0x28 this frame: 0 the camera as it is, 1 keys, 2 drag
  int latched;                 // +0x2c the presenter's slide duration is ours
  volatile double px, py;      // +0x30 the camera on screen (tiles)
  volatile double pt;          // +0x40 when (game clock, ms)
  volatile double off_x, off_y;// +0x48 the offset written (canvas px)
  volatile int hold_ms;        // +0x58 the longest a picture is kept while the view moves; 0 = every picture as it comes
  volatile u32 holds;          // +0x5c presented frames that kept the picture
  volatile u32 digests;        // +0x60 pictures taken
  volatile int probe_ok, probe_x, probe_y;   // +0x64 dbg_cursor 2: the real cursor in frame px, as the next mouse event would say
  volatile int why;            // +0x70 why the last frame was not ours: 0 it was, 1 off, 2 smooth scrolling off, 3 not layered,
                               //       4 not the course, 5 zoom glide, 6 the camera is golf's, 7 zoom, 8 rotation, 9 a jump
  volatile int lead_pct;       // +0x74 how much of the view the slide may uncover, percent of its width and height (the patcher's -ScrollLead)
  volatile u32 capped;         // +0x78 presented frames where the view waited at that edge
  volatile int sync_on;        // +0x7c 1 = ground and course taken in step (0: as shipped, for A/B)
  volatile u32 sync_waits;     // +0x80 pictures put off a frame because the next ground was already pending
  double sync_since;           // when the wait began (never longer than 50 ms)
  double digest_t, move_t;     // when the picture on screen was taken; when the view last moved
  double last_tx, last_ty;
  u32 drag_seen;               // the drag serial last seen
  double drag_fresh;           // the last time the game thread kept up with the cursor
  int api_tried;
  int (__stdcall *GetCursorPos)(Pt *);
  int (__stdcall *ScreenToClient)(void *, Pt *);
  void *(__stdcall *GetForegroundWindow)(void);
  u32 (__stdcall *GetWindowThreadProcessId)(void *, u32 *);
  short (__stdcall *GetAsyncKeyState)(int);
  u32 (__stdcall *GetCurrentThreadId)(void);
};
struct LsState ls_state = {.magic = 0x3143534c, .enabled = 1, .hold_ms = 800, .lead_pct = 12, .sync_on = 1};

static double dabs(double v) { return v < 0 ? -v : v; }

static int ifloor(double v) {
  int i = (int)v;
  return v < i ? i - 1 : i;
}

static void api_init(struct LsState *s) {
  s->api_tried = 1;
  GetModuleHandleA_t gmh = *(GetModuleHandleA_t *)IAT_GETMODULEHANDLEA;
  GetProcAddress_t gpa = *(GetProcAddress_t *)IAT_GETPROCADDRESS;
  void *u = gmh("user32.dll"), *k = gmh("kernel32.dll");
  if (!u || !k) return;
  void *f1 = gpa(u, "GetCursorPos"), *f2 = gpa(u, "ScreenToClient"), *f3 = gpa(u, "GetForegroundWindow"),
       *f4 = gpa(u, "GetWindowThreadProcessId"), *f5 = gpa(u, "GetAsyncKeyState"), *f6 = gpa(k, "GetCurrentThreadId");
  if (!f1 || !f2 || !f3 || !f4 || !f5 || !f6) return;
  s->ScreenToClient = (int (__stdcall *)(void *, Pt *))f2;
  s->GetForegroundWindow = (void *(__stdcall *)(void))f3;
  s->GetWindowThreadProcessId = (u32 (__stdcall *)(void *, u32 *))f4;
  s->GetAsyncKeyState = (short (__stdcall *)(int))f5;
  s->GetCurrentThreadId = (u32 (__stdcall *)(void))f6;
  s->GetCursorPos = (int (__stdcall *)(Pt *))f1;   // last: its presence means all are there
}

// The cursor in frame pixels as the next mouse event would give it (map_mouse in hd_native.c, then
// camera_input_event's edge clamp), and whether the drag button is physically down. 0: not known.
static int cursor_frame(struct LsState *s, int button, int *fx, int *fy, int *down) {
  if (s->dbg_cursor == 1) {
    *fx = s->dbg_x;
    *fy = s->dbg_y;
    *down = s->dbg_down;
    return 1;
  }
  if (!s->api_tried) api_init(s);
  if (!s->GetCursorPos || !U8(MAP_OK)) return 0;
  void *w = s->GetForegroundWindow();   // the render thread owns the game window
  if (!w || s->GetWindowThreadProcessId(w, 0) != s->GetCurrentThreadId()) return 0;
  Pt p;
  if (!s->GetCursorPos(&p) || !s->ScreenToClient(w, &p)) return 0;
  int mw = I32(MAP_W), mh = I32(MAP_H);
  int gx = ifloor((double)((float)p.x * F32(MAP_SX) - F32(MAP_OX))), gy = ifloor((double)((float)p.y * F32(MAP_SY) - F32(MAP_OY)));
  gx = gx < 0 ? 0 : gx > mw - 1 ? mw - 1 : gx;
  gy = gy < 0 ? 0 : gy > mh - 1 ? mh - 1 : gy;
  if (!I32(EDGE_SCROLL)) {
    int sw = I32(WIN_SCREEN_W), sh = I32(WIN_SCREEN_H);
    if (gx < 1) gx = 1;
    if (gx > sw - 2) gx = sw - 2;
    if (gy < 1) gy = 1;
    if (gy > sh - 2) gy = sh - 2;
  }
  *fx = gx;
  *fy = gy;
  *down = (s->GetAsyncKeyState(button == 2 ? 4 : button == 3 ? 2 : 1) & 0x8000) != 0;   // SDL middle, right
  return 1;
}

// The camera to show right now (tiles). Returns the mode.
static int live_camera(struct LsState *s, double *ptx, double *pty) {
  double tx = F64(SUB_TX), ty = F64(SUB_TY), pn = port_now();
  int vx = 0, vy = 0;
  if (I32(HELD + 0)) vy += 1;    // k_dx / k_dy of camera_input.c: W, A, S, D
  if (I32(HELD + 4)) vx += 1;
  if (I32(HELD + 8)) vy -= 1;
  if (I32(HELD + 12)) vx -= 1;
  s->pt = pn;
  if ((vx || vy) && course_active(pn)) {
    double t0 = 0;
    for (int i = 0; i < 3; i++) {   // the tick writes the camera, then its time
      t0 = F64(LAST_TICK);
      tx = F64(SUB_TX);
      ty = F64(SUB_TY);
      if (t0 == F64(LAST_TICK)) break;
    }
    double dt = t0 > 0 ? pn - t0 : 0, dx, dy;
    if (dt > 100) dt = 100;
    if (dt < 0) dt = 0;
    double k = F64(PAN_SPEED) * dt / 1000;
    content_to_tiles(vx * k, vy * k, &dx, &dy);
    tx += dx;
    ty += dy;
    keep_on_map(&tx, &ty);
    *ptx = tx;
    *pty = ty;
    return 1;
  }
  int b = I32(DRAG_BUTTON);
  if (b && I32(DRAG_PANNING) && course_active(pn)) {
    int cx, cy, down;
    if (cursor_frame(s, b, &cx, &cy, &down)) {
      u32 serial = (u32)I32(DRAG_SERIAL);
      int x0 = I32(DRAG_X0), y0 = I32(DRAG_Y0);
      double ax0 = F64(DRAG_SUB_X0), ay0 = F64(DRAG_SUB_Y0);
      int torn = serial != (u32)I32(DRAG_SERIAL);
      // the game thread is following the cursor: it handled a move since, or there is nothing to handle
      if (serial != s->drag_seen || (cx == x0 && cy == y0)) {
        s->drag_seen = serial;
        s->drag_fresh = pn;
      }
      if (pn - s->drag_fresh < 250) {
        if ((!down || torn) && s->mode == 2) {   // released (its event is on its way): stay put
          *ptx = s->px;
          *pty = s->py;
          return 2;
        }
        if (down && !torn) {
          double dx, dy;
          content_to_tiles((double)(cx - x0), (double)(cy - y0), &dx, &dy);
          tx = ax0 + dx;
          ty = ay0 + dy;
          keep_on_map(&tx, &ty);
          *ptx = tx;
          *pty = ty;
          return 2;
        }
      }
    }
  }
  *ptx = tx;
  *pty = ty;
  return 0;
}

static void unlatch(struct LsState *s, char *t, double now) {
  s->mode = 0;
  if (!s->latched) return;
  s->latched = 0;
  F64(t + RT_OFF_T0) = now;   // what is left of our offset eases out as one of the presenter's slides
  F64(t + RT_OFF_DUR) = 90;
}

static int live_ok(struct LsState *s, char *t) {
  int why = !s->enabled ? 1 : !I32(CFG_SMOOTH) ? 2 : !I32(t + RT_LAYERED) ? 3 : !I32(t + RT_COURSE) ? 4 : I32(t + RT_ZON) ? 5 :
            !sub_owns() ? 6 : I32(ZOOM) != I32(t + RT_CAM + 8) ? 7 : I32(ROT) != I32(t + RT_CAM + 12) ? 8 : 0;
  s->why = why;
  return !why;
}

// Where the picture drawn with the camera in t goes to show camera (tx, ty): canvas px.
static void offset_for(char *t, double tx, double ty, double *ox, double *oy) {
  double fx = tx - I32(t + RT_CAM), fy = ty - I32(t + RT_CAM + 4);
  *ox = fx * F64(t + RT_CAM + 0x10) + fy * F64(t + RT_CAM + 0x20) - I32(t + RT_CAM + 0x34);
  *oy = fx * F64(t + RT_CAM + 0x18) + fy * F64(t + RT_CAM + 0x28) - I32(t + RT_CAM + 0x38);
}

// Takes golf's newest picture with its ground. Returns 1 when the picture on screen changed.
static int take_picture(struct LsState *s, char *t, double now) {
  int shown = I32(t + RT_SHOWN), newest = I32(FRAME_SERIAL);
  if (s->sync_on && newest != shown) {
    if (I32(HDT_PENDING_FRAME) > newest) {   // the game thread is between the next frame's ground and the frame itself
      if (s->sync_since == 0) s->sync_since = now;
      if (now - s->sync_since < 50) {
        s->sync_waits++;
        return 0;
      }
    } else hdt_take(*(void **)t, newest);    // the ground first: the picture that follows is at least as new
    s->sync_since = 0;
  }
  upload(t, now);
  return I32(t + RT_SHOWN) != shown;
}

// Render thread, every presented frame, in place of upload(t, now): takes golf's new picture (or keeps
// the one on screen while the view moves) and says where the course picture goes.
void __cdecl ls_frame(double now, char *t) {
  struct LsState *s = &ls_state;
  double tx = 0, ty = 0, ox, oy;
  int mode = 0, live = live_ok(s, t), hold = 0;
  if (!s->api_tried) api_init(s);
  if (s->dbg_cursor == 2) {
    int px = 0, py = 0, down = 0;
    s->probe_ok = cursor_frame(s, 2, &px, &py, &down);
    s->probe_x = px;
    s->probe_y = py;
  }
  if (live) {
    mode = live_camera(s, &tx, &ty);
    if (tx != s->last_tx || ty != s->last_ty) s->move_t = now;
    s->last_tx = tx;
    s->last_ty = ty;
    if (s->hold_ms > 0 && I32(CFG_DRAG_FIX) && now - s->move_t < 60 && now - s->digest_t < s->hold_ms) {
      offset_for(t, tx, ty, &ox, &oy);
      hold = dabs(ox) < I32(FRAME_W) * s->lead_pct / 100.0 && dabs(oy) < I32(FRAME_H) * s->lead_pct / 100.0;
      if (hold && s->GetAsyncKeyState && (s->GetAsyncKeyState(1) & 0x8000)) hold = 0;   // the left button: a tool at work
    }
  }
  if (hold) s->holds++;
  else {
    if (take_picture(s, t, now)) {
      s->digest_t = now;
      s->digests++;
      live = live_ok(s, t);   // the new picture may be another zoom, or not the course
    }
  }
  if (!live) {
    unlatch(s, t, now);
    return;
  }
  offset_for(t, tx, ty, &ox, &oy);
  if (dabs(ox) > I32(FRAME_W) * 0.9 || dabs(oy) > I32(FRAME_H) * 0.9) {   // a jump: the presenter cuts
    s->why = 9;
    unlatch(s, t, now);
    return;
  }
  if (dabs(ox) <= 0.5 && dabs(oy) <= 0.5) ox = oy = 0;   // the picture is the view: at rest, no half pixels
  double lx = I32(FRAME_W) * s->lead_pct / 100.0, ly = I32(FRAME_H) * s->lead_pct / 100.0;
  if (dabs(ox) > lx || dabs(oy) > ly) {   // no further than the guard band is fit to be seen
    ox = ox > lx ? lx : ox < -lx ? -lx : ox;
    oy = oy > ly ? ly : oy < -ly ? -ly : oy;
    s->capped++;
  }
  s->px = tx;
  s->py = ty;
  s->mode = mode;
  s->off_x = ox;
  s->off_y = oy;
  s->frames++;
  if (mode == 1) s->key_frames++;
  if (mode == 2) s->drag_frames++;
  F64(t + RT_OFF_X) = ox;
  F64(t + RT_OFF_Y) = oy;
  F64(t + RT_OFF_T0) = now;
  F64(t + RT_OFF_DUR) = 1e12;   // slide_offset: a = 0, the offset as written
  s->latched = 1;
}

// Game thread, at a pan key's or the drag button's release, before the game forgets it was held:
// the camera becomes the one on screen, and the key clock starts from now.
void __cdecl ls_adopt(void) {
  struct LsState *s = &ls_state;
  double pn = port_now();
  if (!s->enabled || !s->mode || !s->latched || pn - s->pt > 250 || pn < s->pt) return;
  double x = s->px, y = s->py;
  if (x != s->px || y != s->py) return;   // the render thread was writing: leave it
  camera_set(x, y);
  F64(LAST_TICK) = pn;
  s->adopts++;
}
