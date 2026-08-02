// SPDX-License-Identifier: GPL-3.0-only
//
// Link-only no-op doubles shared by every math_command_wrappers differential
// oracle (eigen, atan, atan2, ln-complex, real-trig, circular-trig, real-rect-to-
// polar). The full math_command_wrappers Zig module references these display /
// HAL / dispatch symbols across its command surface, but the numeric workers under
// test never call them; they only need to resolve at link time. Providing them
// here (a z47-owned test surface) keeps the upstream tree untouched.

#include "../../../upstream/src/c47/c47.h"

void processResultantLongReal(uint16_t registerNo, int function, int functionType, real_t *paramX, real_t *paramY, real_t *paramTemp, angularMode_t *angleMode, angularMode_t *tmpAngle) {
  (void)registerNo; (void)function; (void)functionType; (void)paramX; (void)paramY; (void)paramTemp; (void)angleMode; (void)tmpAngle;
}

void realToSci(real_t *num, char *dispString) {
  (void)num;
  if(dispString != NULL) {
    dispString[0] = 0;
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
