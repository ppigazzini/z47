// SPDX-License-Identifier: GPL-3.0-only
//
// Headless .p47 program runner.
//
// Loads a user program file (res/PROGRAMS/*.p47) into program memory through
// the REAL load path (fnLoadProgram -> program_serialization loadProgram ->
// ioFileOpen(ioPathLoadProgram)) and then XEQs the first global label, exactly
// as pressing R/S from the top of the loaded program would. This exercises the
// program deserialize path AND the program-execution engine (runProgram /
// executeOneStep) on the full calculator core, with no GTK/UI.
//
// Usage:  pgm_run <file.p47>
// Exit:   0 = program ran to completion (END / normal stop)
//         1 = harness/setup error (bad args, load failed, no label)
//         a natural SIGABRT/SIGSEGV (nonzero) reproduces a real crash with a
//         Zig backtrace; an infinite-loop program never returns, so the caller
//         is expected to wrap this in `timeout` (exit 124 => "runs forever").
//
// The load-file path is handed to the testSuite HAL through the settable global
// `z47_pgm_run_file`, which ioFileNameFromFilePath returns for ioPathLoadProgram
// (path 11). Model is C47 (the full-core harness builds -DCALCMODEL=USER_C47).

#include <c47.h>
#include <decQuad.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// The 6 screen/keyboard globals testSuite.c normally provides; this harness
// replaces testSuite.c, so it must define them itself (the GTK/HAL surface is
// inert in this build). Mirrors keyboard_entry_harness.c.
GtkWidget      *screen;
calcKeyboard_t  calcKeyboard[43];
int             currentBezel;
int16_t         screenStride;
uint32_t       *screenData;
bool_t          screenChange;

// Settable load-file path consumed by the testSuite HAL for ioPathLoadProgram.
extern const char *z47_pgm_run_file;

// fnLoadProgram is a Zig export (program_serialization.zig); no C header.
extern void fnLoadProgram(uint16_t unusedButMandatoryParameter);
// Clear all programs so the loaded file's label is the one we XEQ (fnReset
// leaves the shipped demo programs -- e.g. "Prime" -- in program memory).
extern void fnClPAll(uint16_t confirmation);
// R/S resume entry: continues a program that hit a STOP step (programRunStop ==
// PGM_WAITING), e.g. a plot program pausing on "PRESS R/S TO PLOT".
extern void fnRunProgram(uint16_t unusedButMandatoryParameter);

#define PGM_STOPPED 0
#define PGM_WAITING 2
#define MAX_RS_PRESSES 200  // bound programs that STOP every loop iteration

int main(int argc, char **argv) {
  setvbuf(stdout, NULL, _IONBF, 0); // flush progress before any crash

  if(argc < 2) {
    fprintf(stderr, "usage: pgm_run <file.p47>\n");
    return 1;
  }
  const char *pgm_path = argv[1];

  // Startup init, matching the sim/testSuite (see keyboard_entry_harness.c):
  // install the GMP allocators, reset, load the configuration defaults that
  // fnReset does not, and allocate the LCD framebuffer any render path touches.
  mp_set_memory_functions(allocGmp, reallocGmp, freeGmp);
  fnReset(CONFIRMED);
  resetOtherConfigurationStuff(true);
  extern uint8_t *lcd_buffer;
  lcd_buffer = (uint8_t *)calloc((size_t)240 * (400 / 8 + 2) + 4, 1) + 2;

  fnClPAll(CONFIRMED); // drop the shipped demo programs left by fnReset

  // Load the .p47 through the real path.
  z47_pgm_run_file = pgm_path;
  printf("LOAD %s\n", pgm_path);
  fnLoadProgram(NOPARAM);

  // M1 (REPORT-27 ANNEX B) load-only fuzz mode: exercise only the untrusted-file
  // PARSE surface. If the load returned without an OOB/crash, the malformed input
  // was handled -- pass, regardless of whether it produced a (garbage) program.
  // Executing a loaded program is a separate surface, out of M1's scope.
  if(getenv("PGM_LOAD_ONLY") != NULL) {
    printf("LOAD-ONLY OK\n");
    return 0;
  }

  if(numberOfLabels == 0) {
    fprintf(stderr, "FAIL: load produced no labels (load failed or empty)\n");
    return 1;
  }

  // Find the first GLOBAL label (step > 0) and XEQ it from the top.
  char labelName[64];
  calcRegister_t runLabel = INVALID_VARIABLE;
  for(uint16_t i = 0; i < numberOfLabels; ++i) {
    if(labelList[i].step > 0 && labelList[i].labelPointer != NULL) {
      uint8_t len = labelList[i].labelPointer[0];
      if(len >= sizeof(labelName)) len = sizeof(labelName) - 1;
      memcpy(labelName, labelList[i].labelPointer + 1, len);
      labelName[len] = 0;
      runLabel = findNamedLabel(labelName, GLOBAL_LABELS);
      if(runLabel != INVALID_VARIABLE) break;
    }
  }

  if(runLabel == INVALID_VARIABLE) {
    fprintf(stderr, "FAIL: no runnable global label in %s\n", pgm_path);
    return 1;
  }

  // XEQ a global label directly (not via a dynamic softmenu). fnGoto treats the
  // label as a global STEP number when dynamicMenuItem >= 0, so a leftover >= 0
  // makes it resolve a nonexistent step and NULL currentStep. The sim keeps this
  // -1 outside a dynamic-menu selection; set it as that context would.
  extern int16_t dynamicMenuItem;
  dynamicMenuItem = -1;

  printf("XEQ %s (label reg %d) ...\n", labelName, (int)runLabel);
  reallyRunFunction(ITM_XEQ, runLabel);

  // Drive R/S while the program is paused at a STOP step so plot/interactive
  // programs run to completion (this is where plot-path crashes surface). The
  // outer `timeout` still catches programs that never stop looping.
  int rsPresses = 0;
  while(programRunStop == PGM_WAITING && rsPresses < MAX_RS_PRESSES) {
    rsPresses++;
    dynamicMenuItem = -1;
    fnRunProgram(NOPARAM);
  }
  printf("OK %s (R/S x%d)\n", pgm_path, rsPresses);
  return 0;
}
