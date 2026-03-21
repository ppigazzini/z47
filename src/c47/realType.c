// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file realType.c
 ***********************************************/

#include "c47.h"

static void roundToIntAndQuantize(const real_t *r, real_t *i) {
  realToIntegralValue(r, i, DEC_ROUND_DOWN, &ctxtReal39); // After this call, it's guaranteed that i is an integer and i->exponent >= 0
  decNumberQuantize(i, i, const_0, &ctxtReal39); // After this call, it's guaranteed that the value of i is not changed and i->exponent == 0 (const_0 is used only because it's exponent is 0)
}

int32_t realToInt32C47(const real_t *r) {
  real_t i;

  roundToIntAndQuantize(r, &i);
  return decNumberToInt32(&i, &ctxtReal39);
}

uint32_t realToUint32C47(const real_t *r) {
  real_t i;

  roundToIntAndQuantize(r, &i);
  return decNumberToUInt32(&i, &ctxtReal39);
}

//int64_t realToInt64C47(const real_t *r) {
//  real_t i;
//
//  roundToIntAndQuantize(r, &i);
//  return decNumberToInt64(&i, &ctxtReal39);
//}

uint64_t realToUint64C47(const real_t *r) {
  real_t i;

  roundToIntAndQuantize(r, &i);
  return decNumberToUInt64(&i, &ctxtReal39);
}
