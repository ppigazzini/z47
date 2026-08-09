// SPDX-License-Identifier: GPL-3.0-only
//
// Link-only no-op doubles shared by every math_command_wrappers differential
// oracle (eigen, atan, atan2, ln-complex, real-trig, circular-trig, real-rect-to-
// polar). The full math_command_wrappers Zig module references these display /
// HAL / dispatch symbols across its command surface, but the numeric workers under
// test never call them; they only need to resolve at link time. Providing them
// here (a z47-owned test surface) keeps the upstream tree untouched.

#include "../../../upstream/src/c47/c47.h"

// processResultantLongReal is NOT stubbed here any more. It used to be, because
// nothing exported it -- the xfn port had inlined it into doXfn. The
// factored it back out as a real export (saveRestoreCalcState.c's restoreRegister
// needs it for the RXFN branch), so a stub here is now a duplicate symbol.
// realSCIToDisplayString lives in the display owner, which this lane does not
// link; registerFMAOutputString reaches it and nothing here drives that path.
void realSCIToDisplayString(const real_t *work, char *displayString, int16_t digitsToDisplay, bool_t frontSpace, uint8_t *bcd, int16_t maxDigits) {
  (void)work; (void)digitsToDisplay; (void)frontSpace; (void)bcd; (void)maxDigits;
  if(displayString != NULL) {
    displayString[0] = 0;
  }
}

int create_dir(char *dir) {
  (void)dir;
  return 0;
}

// Weak: oracles that filter mathematics/ln.c out of the link need *a* lnComplex
// to resolve against, but the ln-complex oracle keeps the real ln.c so it has
// something to compare the Zig owner with. Weak lets the real definition win
// wherever it is present and this no-op stand in everywhere else.
__attribute__((weak))
void lnComplex(const real_t *real, const real_t *imag, real_t *lnReal, real_t *lnImag, realContext_t *realContext) {
  (void)real; (void)imag; (void)lnReal; (void)lnImag; (void)realContext;
}

// lcd_buffer_pixel_on and _ioFileNameOverride are NOT stubbed here: every
// consumer of this file also links build/tests/testsuite_hal.zig, which
// defines both, and duplicating them made all six oracles that use this file
// fail to link with "duplicate symbol". addMathEigenOracle links the HAL
// without this file, which is why it was the only one still building.
