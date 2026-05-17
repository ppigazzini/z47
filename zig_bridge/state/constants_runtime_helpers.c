// SPDX-License-Identifier: GPL-3.0-only

#include <inttypes.h>
#include <stdio.h>

#include "c47.h"

extern const real_t *realtConstants[NOUC];

bool_t z47_constants_runtime_validate_constant(uint16_t constant) {
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  if(constant >= NOUC) {
    sprintf(errorMessage, "parameter constant (%" PRIu16 ") is out of bounds, constant must be less or equal to %" PRId32, constant, NOUC - 1);
    moreInfoOnError("In function fnConstant:", errorMessage, NULL, NULL);
    return false;
  }
#endif

  return constant < NOUC;
}

void z47_constants_runtime_store_constant_in_x(uint16_t constant) {
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  realToReal34(realtConstants[constant], REGISTER_REAL34_DATA(REGISTER_X));
}

void z47_constants_runtime_store_pi_in_x(void) {
  convertRealToResultRegister(const39_pi, REGISTER_X, amNone);
}