// companion: the floating "+$" / "-$" amounts over the course fade in and out.
//
// FUN_0040c890 queues an amount in one of 8 slots (round robin at 0x59abb0)
// with a 24-frame timer; drawMoneyLabels (FUN_0040c910, once per course
// frame) counts each timer down and draws the amount at its world position.
// The original shows it at full strength for all 24 frames and then drops it.
// This is the original line for line (taken from the port's compiled
// function), plus gdi_text_alpha around the one text draw: up to full over
// the first FADE_IN frames, down over the last FADE_OUT.
//
// The alpha only shows where the label goes through the native legacy-text
// renderer (gdi.c capture, legacy_text_native.c). Anywhere else (the browser
// build, text that is not captured) it is drawn opaque as before.
//
// data/mods.ini [ui] money_fade=1 (0 = the original, no fade).
//
// The game functions are called through icall (their uniform by-address
// wrappers), so this file needs no guess at their Ghidra prototypes.

#include <stdint.h>

#include "port/ghidra_prelude.h"
#include "port/legacy_text.h"
#include "port/runtime.h"
#ifndef __EMSCRIPTEN__
#include "mods/mods.h"
#endif

#define G32(a) (*(volatile int32_t *)(uintptr_t)(a))

#define FLAGS 0x59e7b8          // bit 0x1000000: labels frozen (not counted, not drawn)
#define LABEL_AMOUNT 0x542dd8   // int[8], dollars
#define LABEL_TIMER 0x542f00    // int[8], frames left (0 = free slot)
#define LABEL_X 0x542fd8        // int[8], world position
#define LABEL_Y 0x542ff8        // int[8]
#define TEXT_BUF 0x51a068
#define STR_PLUS 0x4c5340       // "+"
#define STR_EMPTY 0x4e9a84      // ""
#define BACK_BUFFER 0x4c1570    // PTR_DAT_004c1570
#define LABEL_FONT 0x51b360
#define COL_GAIN 0x800023e8u
#define COL_LOSS 0x80007d08u

#define FN_WORLD_TO_SCREEN 0x42fb90   // (x, y, &sx, &sy, margin): 0 when off screen
#define FN_MONEY_TEXT 0x42dc00        // (cents): appends the amount to TEXT_BUF
#define FN_SELECT_FONT 0x4762d0       // (surface, font, 0, 0, 0)
#define FN_DRAW_TEXT 0x404bc0         // (text, x, y, colour)

#define LABEL_FRAMES 24   // FUN_0040c890: mov [timer + i*4], 0x18
#define FADE_IN 4
#define FADE_OUT 8

static uint32_t call5(uint32_t fn, uint32_t a, uint32_t b, uint32_t c, uint32_t d, uint32_t e) {
  return icall_lookup(fn)(a, b, c, d, e, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
}

// left: the timer after this frame's decrement, 23 on the first frame, 0 on the last
static int label_alpha(int left) {
  int shown = LABEL_FRAMES - left;   // 1 on the first frame
  int rest = left + 1;               // 1 on the last frame
  if (shown < 1) shown = 1;          // a longer timer than the original's: no fade in
  int a = 255;
  if (shown < FADE_IN) a = 255 * shown / FADE_IN;
  if (rest < FADE_OUT && 255 * rest / FADE_OUT < a) a = 255 * rest / FADE_OUT;
  return a;
}

// @override FUN_0040c910
int FUN_0040c910(void) {
  PORT_TRACE(0x0040c910);   // camera_input.c counts this as "the course view drew a frame"
#ifndef __EMSCRIPTEN__
  int fade = mods_get_int("ui.money_fade", 1);
#else
  int fade = 0;
#endif
  volatile int32_t *amount = (volatile int32_t *)(uintptr_t)LABEL_AMOUNT;
  volatile int32_t *timer = (volatile int32_t *)(uintptr_t)LABEL_TIMER;
  volatile int32_t *lx = (volatile int32_t *)(uintptr_t)LABEL_X;
  volatile int32_t *ly = (volatile int32_t *)(uintptr_t)LABEL_Y;
  for (int i = 0; i < 8; i++) {
    int left = timer[i];
    if (left == 0) continue;
    if (G32(FLAGS) & 0x1000000) continue;
    timer[i] = --left;
    int sx = 0, sy = 0;
    if (!call5(FN_WORLD_TO_SCREEN, (uint32_t)lx[i], (uint32_t)ly[i], (uint32_t)(uintptr_t)&sx,
               (uint32_t)(uintptr_t)&sy, 0))
      continue;
    int value = amount[i];
    {
      char *d = (char *)(uintptr_t)TEXT_BUF;
      const char *s = (const char *)(uintptr_t)(value > 0 ? STR_PLUS : STR_EMPTY);
      while ((*d++ = *s++) != 0) {}
    }
    call5(FN_MONEY_TEXT, (uint32_t)(value * 100), 0, 0, 0, 0);
    call5(FN_SELECT_FONT, (uint32_t)G32(BACK_BUFFER), LABEL_FONT, 0, 0, 0);
    if (fade) gdi_text_alpha(label_alpha(left));
    call5(FN_DRAW_TEXT, TEXT_BUF, (uint32_t)sx, (uint32_t)(sy - 4), value > 0 ? COL_GAIN : COL_LOSS, 0);
    if (fade) gdi_text_alpha(255);
  }
  return 0;
}
