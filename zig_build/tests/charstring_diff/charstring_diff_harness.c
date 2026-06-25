// SPDX-License-Identifier: GPL-3.0-only
//
// C-vs-Zig DIFFERENTIAL harness (Annex A5).
//
// The A7 dry-run proved the host suites are structurally blind to upstream
// changes in the replaced (Zig-owned, C-compiled-out) owners: advancing the
// imported C to a new pin leaves every suite green because nothing compares the
// new upstream C against the Zig port. This harness is the missing comparison:
// it compiles the PINNED upstream C of a function (oracle_stringGlyphLength,
// extracted by extract_oracle.sh) beside the live Zig owner export
// (stringGlyphLength, linked by addFullCoreHarness) and asserts they agree
// byte-for-byte over a large enumerated input space. On an M10 pin bump the
// oracle tracks the new upstream C, so any Zig owner that was not re-ported to
// match makes this harness go RED -- the catch the parity suites cannot give.
//
// stringGlyphLength is the first target: pure, self-contained, and it has a
// non-trivial branch (a high-bit lead byte 0x80.. counts as a 2-byte glyph),
// which the enumeration below exercises directly.

#include <c47.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

// addFullCoreHarness replaces testSuite.c, so define the screen/keyboard globals
// it normally provides (inert here).
GtkWidget      *screen;
calcKeyboard_t  calcKeyboard[43];
int             currentBezel;
int16_t         screenStride;
uint32_t       *screenData;
bool_t          screenChange;

// The pinned upstream C oracles (generated from src/c47/charString.c). The Zig
// owner exports (stringGlyphLength, stringNextGlyph, ...) come from c47.h.
int32_t oracle_stringGlyphLength(const char *str);
int16_t oracle_stringNextGlyphNoEndCheck_JM(const char *str, int16_t pos);
int16_t oracle_stringNextGlyph(const char *str, int16_t pos);
int16_t oracle_stringPrevGlyph(const char *str, int16_t pos);
int16_t oracle_stringLastGlyph(const char *str);
void oracle_stringToFileNameChars(const char *str, char *ascii);

static long checked;

static void print_bytes(const char *s) {
  for(const unsigned char *p = (const unsigned char *)s; *p; ++p)
    printf("%02x ", *p);
}

#define DIFF(expr_zig, expr_oracle, name, s, pos)                            \
  do {                                                                       \
    long g = (long)(expr_zig), w = (long)(expr_oracle);                      \
    checked++;                                                               \
    if(g != w) {                                                             \
      printf("FAIL: %s diverges (pos=%d): Zig=%ld oracle=%ld on bytes [",    \
             name, (int)(pos), g, w);                                        \
      print_bytes(s);                                                        \
      printf("]\n");                                                         \
      return 1;                                                              \
    }                                                                        \
  } while(0)

// Diff every cluster function on one input string (and over its glyph positions
// for the position-taking members).
static int diff_one(const char *s) {
  DIFF(stringGlyphLength(s), oracle_stringGlyphLength(s), "stringGlyphLength",
       s, -1);
  DIFF(stringLastGlyph(s), oracle_stringLastGlyph(s), "stringLastGlyph", s, -1);
  int len = (int)strlen(s);
  for(int pos = 0; pos <= len + 1; ++pos) {
    DIFF(stringNextGlyph(s, (int16_t)pos), oracle_stringNextGlyph(s, (int16_t)pos),
         "stringNextGlyph", s, pos);
    DIFF(stringPrevGlyph(s, (int16_t)pos), oracle_stringPrevGlyph(s, (int16_t)pos),
         "stringPrevGlyph", s, pos);
    // NoEndCheck reads without a terminator guard, so only feed in-range pos.
    if(pos < len)
      DIFF(stringNextGlyphNoEndCheck_JM(s, (int16_t)pos),
           oracle_stringNextGlyphNoEndCheck_JM(s, (int16_t)pos),
           "stringNextGlyphNoEndCheck_JM", s, pos);
  }

  // stringToFileNameChars writes a sanitized filename into an output buffer;
  // compare the two outputs byte-for-byte. This is the function the M10 delta
  // changes upstream (a new distinctQuotes parameter), so the oracle will flip
  // RED against the Zig owner the moment the imported C is refreshed (M10.2)
  // until the owner is re-ported to match.
  {
    char a_zig[160], a_oracle[160];
    memset(a_zig, 0x7f, sizeof(a_zig));
    memset(a_oracle, 0x7f, sizeof(a_oracle));
    stringToFileNameChars(s, a_zig);
    oracle_stringToFileNameChars(s, a_oracle);
    checked++;
    if(memcmp(a_zig, a_oracle, sizeof(a_zig)) != 0) {
      printf("FAIL: stringToFileNameChars diverges: Zig=[%s] oracle=[%s] on [",
             a_zig, a_oracle);
      print_bytes(s);
      printf("]\n");
      return 1;
    }
  }
  return 0;
}

int main(void) {
  char buf[64];

  // 1) Empty string.
  buf[0] = 0;
  if(diff_one(buf)) return 1;

  // 2) Every single non-NUL byte (covers ASCII and lone high-bit lead bytes).
  for(int b = 1; b < 256; ++b) {
    buf[0] = (char)b;
    buf[1] = 0;
    if(diff_one(buf)) return 1;
  }

  // 3) Every two-byte string (256*255): exercises the high-bit 2-byte-glyph
  //    branch against every following byte, plus ASCII pairs.
  for(int a = 1; a < 256; ++a) {
    for(int b = 1; b < 256; ++b) {
      buf[0] = (char)a;
      buf[1] = (char)b;
      buf[2] = 0;
      if(diff_one(buf)) return 1;
    }
  }

  // 4) Deterministic pseudo-random strings up to length 32, mixing ASCII and
  //    high-bit bytes so glyph boundaries land at varied offsets.
  uint64_t lcg = 0x9e3779b97f4a7c15ULL;
  for(int iter = 0; iter < 200000; ++iter) {
    lcg = lcg * 6364136223846793005ULL + 1442695040888963407ULL;
    int len = (int)(lcg >> 58) % 32; // 0..31
    for(int i = 0; i < len; ++i) {
      lcg = lcg * 6364136223846793005ULL + 1442695040888963407ULL;
      unsigned char c = (unsigned char)(lcg >> 56);
      if(c == 0) c = 1; // no embedded NUL terminator
      buf[i] = (char)c;
    }
    buf[len] = 0;
    if(diff_one(buf)) return 1;
  }

  printf("CHARSTRING DIFFERENTIAL: OK (glyph cluster + stringToFileNameChars "
         "agree with the pinned C oracle over %ld comparisons)\n", checked);
  return 0;
}
