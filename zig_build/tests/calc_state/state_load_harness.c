// SPDX-License-Identifier: GPL-3.0-only
//
// Headless state-file loader, for driving MALFORMED .sav / .d47 input through
// the real restore path.
//
// M-SAFE-7 (REPORT-30). The state path is the surface upstream's worst memory
// bug lived on (the 577 statefile overflow), and until this existed nothing in
// the tree fed it anything but files the calculator itself had just written:
// `saveload_parity` and `saveload_golden` round-trip valid state, and
// `pgm_load_fuzz` covers `.p47` programs only. The bounds commit 31fb6f755 added
// to calc_state_restore.zig -- 137 lines of them -- had no adversarial coverage
// at all, and the matrix-dimension guard that M-SAFE-1 ported had none either.
//
// Usage:  state_load <file.sav> [loadMode]
//
// loadMode defaults to LM_ALL. It is a parameter because the restore path
// BRANCHES on it: restoreProgramsSection has a whole LM_PROGRAMS arm, and
// restoreOneSection's local-register guard reads
// `load_mode == LM_ALL or load_mode == LM_REGISTERS`, so its skip-the-matrix-data
// else-arm is unreachable while only LM_ALL is ever driven. Measuring branch
// coverage of the 31fb6f755 guard commit showed 19 of 30 arms reached with
// LM_ALL alone; the modes the runner sweeps cover the mode-dependent rest.
// Exit:   0 = the restore path returned. A malformed file that is REFUSED exits
//             0 as well, and that is the point: refusing is correct behaviour,
//             so the pass condition is "returned without dying", exactly as the
//             sibling pgm_run harness treats a load-only run.
//         1 = harness/setup error (bad args, unreadable corpus file)
//         a natural SIGABRT/SIGSEGV/SIGILL reproduces a real defect with a Zig
//         backtrace -- an out-of-range @intCast on the load path traps in this
//         build, since it is compiled at the default optimize level with Zig's
//         safety checks live. The caller wraps this in `timeout`, so a corrupt
//         file that makes the parser loop forever shows up as exit 124.
//
// The restore path opens ioPathManualSave, which the testSuite HAL maps to
// "c47.sav" relative to the working directory, so this harness COPIES the corpus
// file there before loading. That clobbers c47.sav in the CWD -- the same file
// save_load_parity_harness.c writes, and the gate runs lanes sequentially.

#include <c47.h>
#include <decQuad.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// The 6 screen/keyboard globals testSuite.c normally provides; this harness
// replaces testSuite.c, so it must define them itself. Mirrors
// pgm_run_harness.c and keyboard_entry_harness.c.
GtkWidget      *screen;
calcKeyboard_t  calcKeyboard[43];
int             currentBezel;
int16_t         screenStride;
uint32_t       *screenData;
bool_t          screenChange;

// fnLoad is a Zig export (calc_state.zig); no C header declares it.
extern void fnLoad(uint16_t loadMode);
// Reported after the load so a corpus file that FORGES a version is visible in
// the log rather than only in a crash (M-SAFE-4's wrap-to-10000025 case).
extern uint32_t z47_calc_state_get_loaded_version(void);

#define LM_ALL 0
#define STATE_FILE "c47.sav"

// defines.h is not visible here, so mirror the load modes the runner sweeps.
// A mode outside the known set is passed through unchanged: feeding the restore
// path a mode it does not recognise is itself worth not crashing on.
static uint16_t parseLoadMode(const char *s) {
  char *end = NULL;
  unsigned long v = strtoul(s, &end, 10);
  if(end == s || *end != 0 || v > 0xFFFF) {
    fprintf(stderr, "FAIL: bad load mode '%s'\n", s);
    exit(1);
  }
  return (uint16_t)v;
}

static int copyFile(const char *from, const char *to) {
  FILE *in = fopen(from, "rb");
  if(in == NULL) {
    fprintf(stderr, "FAIL: cannot open corpus file %s\n", from);
    return 1;
  }
  FILE *out = fopen(to, "wb");
  if(out == NULL) {
    fprintf(stderr, "FAIL: cannot write %s\n", to);
    fclose(in);
    return 1;
  }
  char buf[8192];
  size_t n;
  while((n = fread(buf, 1, sizeof(buf), in)) > 0) {
    if(fwrite(buf, 1, n, out) != n) {
      fprintf(stderr, "FAIL: short write to %s\n", to);
      fclose(in);
      fclose(out);
      return 1;
    }
  }
  fclose(in);
  fclose(out);
  return 0;
}

int main(int argc, char **argv) {
  setvbuf(stdout, NULL, _IONBF, 0); // flush progress before any crash

  if(argc < 2) {
    fprintf(stderr, "usage: state_load <file.sav> [loadMode]\n");
    return 1;
  }
  const char *state_path = argv[1];
  const uint16_t loadMode = (argc >= 3) ? parseLoadMode(argv[2]) : LM_ALL;

  // Startup init, matching the sim/testSuite and the sibling pgm_run harness:
  // install the GMP allocators, reset, load the configuration defaults fnReset
  // does not, and allocate the LCD framebuffer any render path touches. The
  // restore path refreshes the screen, so the framebuffer is not optional.
  mp_set_memory_functions(allocGmp, reallocGmp, freeGmp);
  fnReset(CONFIRMED);
  resetOtherConfigurationStuff(true);
  extern uint8_t *lcd_buffer;
  lcd_buffer = (uint8_t *)calloc((size_t)240 * (400 / 8 + 2) + 4, 1) + 2;

  if(copyFile(state_path, STATE_FILE) != 0) {
    return 1;
  }

  printf("LOAD %s (mode %u)\n", state_path, (unsigned)loadMode);
  fnLoad(loadMode);

  // Reaching here means the restore path returned. Whether it accepted or
  // refused the file is not the assertion -- refusing a malformed file is the
  // correct outcome, and a file crafted to be refused would otherwise look like
  // a failure. What is asserted is that it did not trap, crash or hang.
  printf("LOAD-ONLY OK (loadedVersion=%u)\n",
         (unsigned)z47_calc_state_get_loaded_version());
  return 0;
}
