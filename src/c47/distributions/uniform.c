// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file uniform.c
 ***********************************************/

#include "c47.h"

static bool_t checkParamUniform(real_t *x, real_t *low, real_t *high, real_t *range, int *cmp, uint16_t discrete) {
  if (!saveLastX())
    return false;

  if (!getRegisterAsReal(REGISTER_X, x) || !getRegisterAsReal(REGISTER_M, low) || !getRegisterAsReal(REGISTER_N, high))
    goto err;
  if (realIsSpecial(x) || realIsSpecial(low) || realIsSpecial(high)) {
    displayDomainErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function checkParamUniform:", "given non-number inputs", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    goto err;
  }
  if (discrete) {
    if (!realIsAnInteger(low)) {
      displayDomainErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_M);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function checkParamUniform:", "given non-integer lower limit", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      goto err;
    }
    if (!realIsAnInteger(high)) {
      displayDomainErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_N);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function checkParamUniform:", "given non-integer upper limit", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      goto err;
    }
  }

  if (realCompareGreaterThan(low, high)) {
    const real_t t = *low;
    *low = *high;
    *high = t;
  }
  if (range != NULL) {
    realSubtract(high, low, range, &ctxtReal39);
    if (discrete)
      realAdd(range, const_1, range, &ctxtReal39);
  }
  if (cmp != NULL)
    *cmp = realCompareLessThan(x, low) ? -1 : realCompareGreaterThan(x, high) ? 1 : 0;
  return true;

err:
  if(getSystemFlag(FLAG_SPCRES)) {
    convertRealToResultRegister(const_NaN, REGISTER_X, amNone);
  }
  return false;
}

void fnUniformP(uint16_t discrete) {
  real_t x, l, h, range, *res = &x;
  int cmp;

  if (checkParamUniform(&x, &l, &h, &range, &cmp, discrete)) {
    if (cmp == 0) {
      if (realIsZero(&range))
        res = const_1;
      else if (discrete && !realIsAnInteger(&x))
        res = const_0;
      else
        realDivide(const_1, &range, &x, &ctxtReal39);
    } else
      res = const_0;
    convertRealToResultRegister(res, REGISTER_X, amNone);
    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
  }
}

void fnUniformL(uint16_t discrete) {
  real_t x, low, h, range, *res = &x;
  int cmp;

  if (checkParamUniform(&x, &low, &h, &range, &cmp, discrete)) {
    if (cmp < 0) {
      res = const_0;
    } else if (cmp > 0 || realIsZero(&range)) {
      res = const_1;
    } else {
      realSubtract(&x, &low, &h, &ctxtReal39);
      if (discrete) {
        realToIntegralValue(&h, &low, DEC_ROUND_FLOOR, &ctxtReal39);
        realAdd(&low, const_1, &h, &ctxtReal39);
      }
      realDivide(&h, &range, &x, &ctxtReal39);
    }
    convertRealToResultRegister(res, REGISTER_X, amNone);
    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
  }
}

void fnUniformU(uint16_t discrete) {
  real_t x, l, high, range, *res = &x;
  int cmp;

  if (checkParamUniform(&x, &l, &high, &range, &cmp, discrete)) {
    if (cmp < 0 || realIsZero(&range)) {
      res = const_1;
    } else if (cmp > 0) {
      res = const_0;
    } else {
      realSubtract(&high, &x, &l, &ctxtReal39);
      if (discrete) {
        realToIntegralValue(&l, &high, DEC_ROUND_CEILING, &ctxtReal39);
        realAdd(&high, const_1, &l, &ctxtReal39);
      }
      realDivide(&l, &range, &x, &ctxtReal39);
    }
    convertRealToResultRegister(res, REGISTER_X, amNone);
    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
  }
}

void fnUniformI(uint16_t discrete) {
  real_t x, low, high, res;

  if (checkParamUniform(&x, &low, &high, NULL, NULL, discrete)) {
    if (realCompareLessEqual(&x, const_0) || realCompareGreaterEqual(&x, const_1)) {
      displayDomainErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function fnUniformI:", "the argument must be 0 < x < 1", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      if(getSystemFlag(FLAG_SPCRES)) {
        convertRealToResultRegister(const_NaN, REGISTER_X, amNone);
      }
      return;
    }
    linpol(&low, &high, &x, &res);
    convertRealToResultRegister(&res, REGISTER_X, amNone);
    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
  }
}

