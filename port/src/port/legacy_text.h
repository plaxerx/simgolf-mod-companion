// Immutable, frame-bound legacy text sent from the game to the native renderer.
#pragma once
#include <stdint.h>
#define LEGACY_RUNS 256
#define LEGACY_GLYPHS 8192
typedef struct {
  const unsigned char *font; // font files remain allocated for the process lifetime
  float em;
  uint32_t rgb;
  int alpha;                 // 0-255 (gdi_text_alpha when the text was drawn)
  int bold, underline, clip[4], bounds[4], uw0, uw1, ubase, first, count;
} LegacyRun;
typedef struct { int index; float x, y; } LegacyGlyph;
typedef struct {
  int count, glyphs;
  LegacyRun run[LEGACY_RUNS];
  LegacyGlyph glyph[LEGACY_GLYPHS];
} LegacyText;
// Game thread only. Pixels are removed only for intact, fully captured records.
void gdi_legacy_capture(const uint16_t *pixels, uint16_t *clean, int w, int h, LegacyText *text);
// Opacity (0-255, default 255) of text drawn from now on. It only reaches the
// screen through the native legacy-text renderer: the 16-bit pixels, and text
// that is not captured as a run, stay opaque. Callers set it back to 255.
void gdi_text_alpha(int alpha);
