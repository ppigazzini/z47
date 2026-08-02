// SPDX-License-Identifier: GPL-3.0-only

#include <string.h>

#include "../../../upstream/src/c47/c47.h"

static void z47_math_ln_complex_init_constant(real_t *value, int32_t exponent, uint8_t bits, uint16_t lsu0) {
  memset(value, 0, sizeof(*value));
  value->digits = 1;
  value->exponent = exponent;
  value->bits = bits;
  value->lsu[0] = lsu0;
}

const real_t *z47_math_wrappers_const_0(void) {
  static bool_t initialized = false;
  static real_t value;

  if(!initialized) {
    z47_math_ln_complex_init_constant(&value, 0, 0, 0);
    initialized = true;
  }

  return &value;
}

const real_t *z47_math_wrappers_const_1(void) {
  static bool_t initialized = false;
  static real_t value;

  if(!initialized) {
    z47_math_ln_complex_init_constant(&value, 0, 0, 1);
    initialized = true;
  }

  return &value;
}

const real_t *z47_math_wrappers_const_minus_1(void) {
  static bool_t initialized = false;
  static real_t value;

  if(!initialized) {
    z47_math_ln_complex_init_constant(&value, 0, DECNEG, 1);
    initialized = true;
  }

  return &value;
}

const real_t *z47_math_wrappers_const_2(void) {
  static bool_t initialized = false;
  static real_t value;

  if(!initialized) {
    z47_math_ln_complex_init_constant(&value, 0, 0, 2);
    initialized = true;
  }

  return &value;
}

const real_t *z47_math_wrappers_const_1on2(void) {
  static bool_t initialized = false;
  static real_t value;

  if(!initialized) {
    z47_math_ln_complex_init_constant(&value, -1, 0, 5);
    initialized = true;
  }

  return &value;
}

const real_t *z47_math_wrappers_const_2e6(void) {
  static bool_t initialized = false;
  static real_t value;

  if(!initialized) {
    z47_math_ln_complex_init_constant(&value, 6, 0, 2);
    initialized = true;
  }

  return &value;
}

const real_t *z47_math_wrappers_const_90(void) {
  return const_90;
}

const real_t *z47_math_wrappers_const_100(void) {
  return const_100;
}

const real_t *z47_math_wrappers_const_180(void) {
  return const_180;
}

const real_t *z47_math_wrappers_const_ln10(void) {
  return const39_ln10;
}

const real_t *z47_math_wrappers_const_piOn4(void) {
  return const39_piOn4;
}

const real_t *z47_math_wrappers_const_3piOn4(void) {
  return const39_3piOn4;
}

const real_t *z47_math_wrappers_const75_piOn4(void) {
  return const75_piOn4;
}

const real_t *z47_math_wrappers_const75_piOn2(void) {
  return const75_piOn2;
}

const real_t *z47_math_wrappers_const75_pi(void) {
  return const75_pi;
}
const real_t *z47_math_wrappers_const_piOn2(void) {
  return const39_piOn2;
}

const real_t *z47_math_wrappers_const_pi(void) {
  return const39_pi;
}

const real_t *z47_math_wrappers_const_plus_infinity(void) {
  return const_plusInfinity;
}

const real_t *z47_math_wrappers_const_minus_infinity(void) {
  return const_minusInfinity;
}
