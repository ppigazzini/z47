// SPDX-License-Identifier: GPL-3.0-only
//
// Link-only no-op doubles for the eigen worker golden oracle
// (math_wrappers_eigen_oracle.c). The full math_command_wrappers Zig module
// references these display / HAL / dispatch symbols across its command surface,
// but the eigen numeric workers under test never call them; they only need to
// resolve at link time. Providing them here (a z47-owned test surface) keeps the
// upstream tree untouched.

#include "../../../src/c47/c47.h"

void processResultantLongReal(uint16_t registerNo, int function, int functionType, real_t *paramX, real_t *paramY, real_t *paramTemp, angularMode_t *angleMode, angularMode_t *tmpAngle) {
  (void)registerNo; (void)function; (void)functionType; (void)paramX; (void)paramY; (void)paramTemp; (void)angleMode; (void)tmpAngle;
}

void realToSci(real_t *num, char *dispString) {
  (void)num;
  if(dispString != NULL) {
    dispString[0] = 0;
  }
}

bool_t lcd_buffer_pixel_on(uint32_t x, uint32_t y) {
  (void)x; (void)y;
  return 0;
}

int create_dir(char *dir) {
  (void)dir;
  return 0;
}

void lnComplex(const real_t *real, const real_t *imag, real_t *lnReal, real_t *lnImag, realContext_t *realContext) {
  (void)real; (void)imag; (void)lnReal; (void)lnImag; (void)realContext;
}

char _ioFileNameOverride[1024];
