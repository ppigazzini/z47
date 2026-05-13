// SPDX-License-Identifier: GPL-3.0-only

#include <stdio.h>

#include "c47.h"

static int runCaseReplacementCase(void) {
  int16_t expected = 0;
  int16_t actual = 0;

  keyboardStateReset();
  if(!oracle_caseReplacements(0, true, ITM_A, &expected)) {
    fprintf(stderr, "oracle caseReplacements did not translate uppercase input\n");
    return 1;
  }

  keyboardStateReset();
  if(!caseReplacements(0, true, ITM_A, &actual)) {
    fprintf(stderr, "zig caseReplacements did not translate uppercase input\n");
    return 1;
  }

  if(expected != actual) {
    fprintf(stderr, "caseReplacements mismatch: expected %d actual %d\n", expected, actual);
    return 1;
  }

  return 0;
}

static int runNumlockReplacementCase(void) {
  uint16_t expected;
  uint16_t actual;

  keyboardStateReset();
  keyboardStateSetFlag(FLAG_NUMLOCK, true);
  expected = oracle_numlockReplacements(0, ITM_Q, true, false, false);

  keyboardStateReset();
  keyboardStateSetFlag(FLAG_NUMLOCK, true);
  actual = numlockReplacements(0, ITM_Q, true, false, false);

  if(expected != actual) {
    fprintf(stderr, "numlockReplacements mismatch: expected %u actual %u\n", expected, actual);
    return 1;
  }

  return 0;
}

static int runSetLastKeyCodeCase(void) {
  int16_t expected;
  int16_t actual;

  keyboardStateReset();
  oracle_setLastKeyCode(43);
  expected = lastKeyCode;
 
  keyboardStateReset();
  setLastKeyCode(43);
  actual = lastKeyCode;

  if(expected != actual) {
    fprintf(stderr, "setLastKeyCode mismatch: expected %d actual %d\n", expected, actual);
    return 1;
  }

  return 0;
}

int main(void) {
  int failures = 0;

  failures += runCaseReplacementCase();
  failures += runNumlockReplacementCase();
  failures += runSetLastKeyCodeCase();

  if(failures != 0) {
    fprintf(stderr, "%d keyboard-state parity checks failed\n", failures);
    return 1;
  }

  puts("keyboard-state parity checks passed");
  return 0;
}