// SPDX-License-Identifier: GPL-3.0-only

#include <math.h>
#include <string.h>

#include "c47.h"

double z47_math_wrappers_log(double value) {
  return value > 0.0 ? value : 0.0;
}

static void z47_math_wrappers_long_integer_gcd(longInteger_t liY, longInteger_t liX, longInteger_t liA) {
  if(longIntegerIsZero(liY) && longIntegerIsZero(liX)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
    moreInfoOnError("In function _longIntegerGcd:", "(0, 0) is not in the function domain.", NULL, NULL);
#endif
  }
  else {
    longIntegerGcd(liY, liX, liA);
  }
}

void z47_math_wrappers_gcd_int(void) {
  longInteger_t liX, liY;
  bool_t fracX, fracY;

  if(!getRegisterAsLongInt(REGISTER_Y, liY, &fracY)) {
    goto end1;
  }
  if(!getRegisterAsLongInt(REGISTER_X, liX, &fracX)) {
    goto end2;
  }

  if(fracX) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    goto end2;
  }
  if(fracY) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_Y);
    goto end2;
  }

  longIntegerSetPositiveSign(liY);
  longIntegerSetPositiveSign(liX);
  z47_math_wrappers_long_integer_gcd(liY, liX, liX);
  convertLongIntegerToLongIntegerRegister(liX, REGISTER_X);
end2:
  longIntegerFree(liX);
end1:
  longIntegerFree(liY);
}

void z47_math_wrappers_gcd_short_integer(void) {
  *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = WP34S_intGCD(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_Y)), *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)));
}

void z47_math_wrappers_lcm_int(void) {
  longInteger_t liX, liY;
  bool_t fracX, fracY;

  if(!getRegisterAsLongInt(REGISTER_Y, liY, &fracY)) {
    goto end1;
  }
  if(!getRegisterAsLongInt(REGISTER_X, liX, &fracX)) {
    goto end2;
  }

  if(fracX) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    goto end2;
  }

  if(fracY) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_Y);
    goto end2;
  }

  longIntegerSetPositiveSign(liY);
  longIntegerSetPositiveSign(liX);
  longIntegerLcm(liY, liX, liX);
  convertLongIntegerToLongIntegerRegister(liX, REGISTER_X);

end2:
  longIntegerFree(liX);
end1:
  longIntegerFree(liY);
}

void z47_math_wrappers_lcm_short_integer(void) {
  *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = WP34S_intLCM(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_Y)), *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)));
}

void z47_math_wrappers_long_integer_fibonacci(uint32_t n, longInteger_t result) {
  longIntegerFibonacci(n, result);
}

void z47_math_wrappers_fact_real(void) {
  real_t x;

  if(getRegisterAsReal(REGISTER_X, &x)) {
    WP34S_Factorial(&x, &x, &ctxtReal39);
    convertRealToResultRegister(&x, REGISTER_X, amNone);
  }
}

void z47_math_wrappers_fact_cplx(void) {
  real_t zReal, zImag;

  if(getRegisterAsComplex(REGISTER_X, &zReal, &zImag)) {
    realAdd(&zReal, const_1, &zReal, &ctxtReal39);
    WP34S_ComplexGamma(&zReal, &zImag, &zReal, &zImag, &ctxtReal39);
    convertComplexToResultRegister(&zReal, &zImag, REGISTER_X);
  }
}

void z47_math_wrappers_fact_long_integer(void) {
  longInteger_t x, f;

  convertLongIntegerRegisterToLongInteger(REGISTER_X, x);

  if(longIntegerIsNegative(x)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
    longIntegerRegisterToDisplayString(REGISTER_X, errorMessage, ERROR_MESSAGE_LENGTH, SCREEN_WIDTH, 50, false);
    sprintf(tmpString, "cannot calculate factorial(%s)", errorMessage);
    moreInfoOnError("In function factLonI:", tmpString, NULL, NULL);
#endif
    longIntegerFree(x);
    return;
  }

  if(longIntegerCompareUInt(x, MAX_FACTORIAL) > 0) {
    convertLongIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
    longIntegerFree(x);
    z47_math_wrappers_fact_real();
    return;
  }

  uint32_t n;
  longIntegerToUInt32(x, n);
#if defined(LINUX)
  longIntegerInitSizeInBits(f, 1 + (uint32_t)((n * log(n) - n) / log(2)));
  uInt32ToLongInteger(1u, f);
  for(uint32_t i = 2; i <= n; i++) {
    longIntegerMultiplyUInt(f, i, f);
  }
#else
  longIntegerInit(f);
  longIntegerFactorial(n, f);
#endif

  convertLongIntegerToLongIntegerRegister(f, REGISTER_X);

  longIntegerFree(f);
  longIntegerFree(x);
}

static uint64_t z47_math_wrappers_fact_uint64(uint64_t value) {
  uint64_t result;

  if(value <= 1) {
    result = 1;
  }
  else {
    uint64_t m = value;

    if((value & 1) != 0) {
      m += value;
      value -= 1;
    }
    result = m;
    value -= 2;
    while(value > 0) {
      m += value;
      result *= m;
      value -= 2;
    }
  }

  return result;
}

void z47_math_wrappers_fact_short_integer(void) {
  int16_t sign;
  uint64_t value;

  convertShortIntegerRegisterToUInt64(REGISTER_X, &sign, &value);

  if(sign == 1) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
    longIntegerRegisterToDisplayString(REGISTER_X, errorMessage, ERROR_MESSAGE_LENGTH, SCREEN_WIDTH, 50, false);
    sprintf(tmpString, "cannot calculate factorial(%s)", errorMessage);
    moreInfoOnError("In function factShoI:", tmpString, NULL, NULL);
#endif
    return;
  }

  if(value > 20) {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
    longIntegerRegisterToDisplayString(REGISTER_X, errorMessage, ERROR_MESSAGE_LENGTH, SCREEN_WIDTH, 50, false);
    sprintf(tmpString, "cannot calculate factorial(%s)", errorMessage);
    moreInfoOnError("In function factShoI:", tmpString, NULL, NULL);
#endif
    return;
  }

  uint64_t f = z47_math_wrappers_fact_uint64(value);
  if(f > shortIntegerMask) {
    setSystemFlag(FLAG_OVERFLOW);
  }

  convertUInt64ToShortIntegerRegister(0, f, getRegisterTag(REGISTER_X), REGISTER_X);
}

void z47_math_wrappers_mod_long_integer(void) {
  longInteger_t x, y, remainder;

  if(!getRegisterAsLongInt(REGISTER_X, x, NULL)) {
    goto err1;
  }

  if(longIntegerIsZero(x)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
    moreInfoOnError("In function modLonI:", "cannot IDIVR a long integer by 0", NULL, NULL);
#endif
    goto err1;
  }

  if(!getRegisterAsLongInt(REGISTER_Y, y, NULL)) {
    goto err2;
  }

  longIntegerInit(remainder);
  longIntegerDivideRemainder(y, x, remainder);
  longIntegerAdd(remainder, x, remainder);
  longIntegerDivideRemainder(remainder, x, remainder);

  convertLongIntegerToLongIntegerRegister(remainder, REGISTER_X);

  longIntegerFree(remainder);
err2:
  longIntegerFree(y);
err1:
  longIntegerFree(x);
}

void z47_math_wrappers_mod_short_integer(void) {
  longInteger_t x, y, remainder;
  uint32_t baseY;

  if(!getRegisterAsLongInt(REGISTER_X, x, NULL)) {
    goto err1;
  }

  if(longIntegerIsZero(x)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
    moreInfoOnError("In function modShoI:", "cannot IDIVR a short integer by 0", NULL, NULL);
#endif
    goto err1;
  }

  if(!getRegisterAsLongInt(REGISTER_Y, y, NULL)) {
    goto err2;
  }
  baseY = getRegisterShortIntegerBase(REGISTER_Y);

  longIntegerInit(remainder);
  longIntegerDivideRemainder(y, x, remainder);
  longIntegerAdd(remainder, x, remainder);
  longIntegerDivideRemainder(remainder, x, remainder);

  convertLongIntegerToShortIntegerRegister(remainder, baseY, REGISTER_X);

  longIntegerFree(remainder);
err2:
  longIntegerFree(y);
err1:
  longIntegerFree(x);
}

void z47_math_wrappers_mod_real(void) {
  real_t x, y, r;

  if(!getRegisterAsReal(REGISTER_X, &x) || !getRegisterAsReal(REGISTER_Y, &y)) {
    return;
  }

  if(realIsZero(&x)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
    moreInfoOnError("In function modReal:", "cannot IDIVR a real34 by 0", NULL, NULL);
#endif
    return;
  }

  WP34S_BigMod(&y, &x, &r, &ctxtReal39);
  if(!realIsZero(&r) && realGetSign(&y) != realGetSign(&x)) {
    realAdd(&r, &x, &r, &ctxtReal39);
  }

  convertRealToResultRegister(&r, REGISTER_X, amNone);
}

void z47_math_wrappers_rmd_long_integer(void) {
  longInteger_t x, y, remainder;

  if(!getRegisterAsLongInt(REGISTER_X, x, NULL)) {
    goto err1;
  }

  if(longIntegerIsZero(x)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
    moreInfoOnError("In function rmdLonI:", "cannot IDIVR a long integer by 0", NULL, NULL);
#endif
    goto err1;
  }

  if(!getRegisterAsLongInt(REGISTER_Y, y, NULL)) {
    goto err2;
  }
  longIntegerInit(remainder);
  longIntegerDivideRemainder(y, x, remainder);

  convertLongIntegerToLongIntegerRegister(remainder, REGISTER_X);

  longIntegerFree(remainder);
err2:
  longIntegerFree(y);
err1:
  longIntegerFree(x);
}

void z47_math_wrappers_rmd_short_integer(void) {
  longInteger_t x, y, remainder;
  uint32_t baseY;

  if(!getRegisterAsLongInt(REGISTER_X, x, NULL)) {
    goto err1;
  }

  if(longIntegerIsZero(x)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
    moreInfoOnError("In function rmdShoI:", "cannot IDIVR a short integer by 0", NULL, NULL);
#endif
    goto err1;
  }

  if(!getRegisterAsLongInt(REGISTER_Y, y, NULL)) {
    goto err2;
  }
  baseY = getRegisterShortIntegerBase(REGISTER_Y);

  longIntegerInit(remainder);
  longIntegerDivideRemainder(y, x, remainder);

  convertLongIntegerToShortIntegerRegister(remainder, baseY, REGISTER_X);

  longIntegerFree(remainder);
err2:
  longIntegerFree(y);
err1:
  longIntegerFree(x);
}

void z47_math_wrappers_rmd_real(void) {
  real_t x, y, r;

  if(!getRegisterAsReal(REGISTER_X, &x) || !getRegisterAsReal(REGISTER_Y, &y)) {
    return;
  }

  if(realIsZero(&x)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
    moreInfoOnError("In function rmdReal:", "cannot IDIVR a real34 by 0", NULL, NULL);
#endif
    return;
  }

  WP34S_BigMod(&y, &x, &r, &ctxtReal39);
  convertRealToResultRegister(&r, REGISTER_X, amNone);
}

void z47_math_wrappers_neighb_short_integer(void) {
  bool_t subtract, negx, negy;
  uint64_t x, y;

  if(getRegisterAsShortInt(REGISTER_X, &negx, &x, NULL, NULL) && getRegisterAsShortInt(REGISTER_Y, &negy, &y, NULL, NULL)) {
    if(negx != negy) {
      subtract = negy;
    }
    else if(x == y) {
      return;
    }
    else if(negx) {
      subtract = y > x;
    }
    else {
      subtract = y < x;
    }

    if(subtract) {
      *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = WP34S_intSubtract(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)), 1);
    }
    else {
      *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = WP34S_intAdd(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)), 1);
    }
  }
}

void z47_math_wrappers_neighb_long_integer(void) {
  longInteger_t x, y;

  if(!getRegisterAsLongInt(REGISTER_X, x, NULL)) {
    goto end1;
  }
  if(!getRegisterAsLongInt(REGISTER_Y, y, NULL)) {
    goto end2;
  }

  const int32_t cmp = longIntegerCompare(y, x);

  if(cmp != 0) {
    int32ToLongInteger(cmp > 0 ? 1 : -1, y);
    longIntegerAdd(x, y, x);
  }
  convertLongIntegerToLongIntegerRegister(x, REGISTER_X);

end2:
  longIntegerFree(y);
end1:
  longIntegerFree(x);
}

void z47_math_wrappers_neighb_real(void) {
  real_t x, y;
  angularMode_t xAngularMode = amNone;

  if(!getRegisterAsReal(REGISTER_X, &x) || !getRegisterAsReal(REGISTER_Y, &y)) {
    return;
  }

  if(getRegisterDataType(REGISTER_X) == dtReal34) {
    xAngularMode = getRegisterAngularMode(REGISTER_X);
  }

  realNextToward(&x, &y, &x, &ctxtReal34);
  convertRealToResultRegister(&x, REGISTER_X, xAngularMode);
}

void z47_math_wrappers_build_sign_result(int32_t r) {
  longInteger_t lgInt;

  longIntegerInit(lgInt);
  int32ToLongInteger(r, lgInt);
  convertLongIntegerToLongIntegerRegister(lgInt, REGISTER_X);
  longIntegerFree(lgInt);
}

void z47_math_wrappers_change_sign_long_integer(void) {
  longInteger_t x;

  if(!getRegisterAsLongInt(REGISTER_X, x, NULL)) {
    goto end;
  }

  longIntegerChangeSign(x);
  convertLongIntegerToLongIntegerRegister(x, REGISTER_X);
end:
  longIntegerFree(x);
}

void z47_math_wrappers_integer_part_long_integer(void) {
  longInteger_t val;
  uint32_t type = getRegisterDataType(REGISTER_X);

  if(getRegisterAsLongInt(REGISTER_X, val, NULL)) {
    convertLongIntegerToLongIntegerRegister(val, REGISTER_X);
    if(type == dtShortInteger) {
      setLastintegerBasetoZero();
    }
  }
  longIntegerFree(val);
}

void z47_math_wrappers_integer_part_short_integer(void) {
  bool_t sign, overflow, frac;
  uint64_t val;

  if(!getRegisterAsShortInt(REGISTER_X, &sign, &val, &overflow, &frac)) {
    return;
  }
  if(getRegisterDataType(REGISTER_X) != dtShortInteger) {
    convertUInt64ToShortIntegerRegister(sign, val, 10, REGISTER_X);
  }
  forceSystemFlag(FLAG_CARRY, frac);
  forceSystemFlag(FLAG_OVERFLOW, overflow);
}

void z47_math_wrappers_fractional_part_long_integer(void) {
  longInteger_t x;

  longIntegerInit(x);
  convertLongIntegerToLongIntegerRegister(x, REGISTER_X);
  longIntegerFree(x);
}

void z47_math_wrappers_fractional_part_short_integer(void) {
  uint64_t x, y = 0;

  if(shortIntegerMode == SIM_1COMPL || shortIntegerMode == SIM_SIGNMT) {
    x = *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X));
    if((x & shortIntegerSignBit) != 0) {
      y = shortIntegerMode == SIM_1COMPL ? shortIntegerMask : shortIntegerSignBit;
    }
  }

  *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = y;
}

void z47_math_wrappers_fractional_part_real(void) {
  real34_t x;

  real34ToIntegralValue(REGISTER_REAL34_DATA(REGISTER_X), &x, DEC_ROUND_DOWN);
  real34Subtract(REGISTER_REAL34_DATA(REGISTER_X), &x, REGISTER_REAL34_DATA(REGISTER_X));
}

void z47_math_wrappers_square_long_integer(void) {
  longInteger_t lgInt;

  if(!getRegisterAsLongInt(REGISTER_X, lgInt, NULL)) {
    goto end;
  }

  longIntegerMultiply(lgInt, lgInt, lgInt);
  convertLongIntegerToLongIntegerRegister(lgInt, REGISTER_X);
end:
  longIntegerFree(lgInt);
}

void z47_math_wrappers_cube_long_integer(void) {
  longInteger_t x, c;

  if(!getRegisterAsLongInt(REGISTER_X, x, NULL)) {
    goto end;
  }

  longIntegerInit(c);
  longIntegerMultiply(x, x, c);
  longIntegerMultiply(c, x, c);
  convertLongIntegerToLongIntegerRegister(c, REGISTER_X);
  longIntegerFree(c);
end:
  longIntegerFree(x);
}

void z47_math_wrappers_minus_one_power_long_integer(void) {
  longInteger_t lgInt, exponent;

  longIntegerInit(lgInt);
  uInt32ToLongInteger(1u, lgInt);

  convertLongIntegerRegisterToLongInteger(REGISTER_X, exponent);
  if(longIntegerIsOdd(exponent)) {
    longIntegerChangeSign(lgInt);
  }

  convertLongIntegerToLongIntegerRegister(lgInt, REGISTER_X);

  longIntegerFree(lgInt);
  longIntegerFree(exponent);
}

int32_t z47_math_wrappers_small_base_power_long_integer(uint32_t baseValue) {
  int32_t exponentSign;
  longInteger_t base, exponent;

  longIntegerInit(base);
  uInt32ToLongInteger(baseValue, base);
  convertLongIntegerRegisterToLongInteger(REGISTER_X, exponent);

  longIntegerSetPositiveSign(base);

  exponentSign = longIntegerSign(exponent);
  longIntegerSetPositiveSign(exponent);

  if(longIntegerIsZero(exponent)) {
    uInt32ToLongInteger(1u, base);
    convertLongIntegerToLongIntegerRegister(base, REGISTER_X);
    longIntegerFree(base);
    longIntegerFree(exponent);
    return 1;
  }
  else if(exponentSign == -1) {
    longIntegerFree(base);
    longIntegerFree(exponent);
    return -1;
  }

  longInteger_t power;

  longIntegerInit(power);
  uInt32ToLongInteger(1u, power);

  while(!longIntegerIsZero(exponent) && lastErrorCode == 0) {
    if(longIntegerIsOdd(exponent)) {
      longIntegerMultiply(power, base, power);
    }

    longIntegerDivideUInt(exponent, 2u, exponent);

    if(!longIntegerIsZero(exponent)) {
      longIntegerSquare(base, base);
    }
  }

  convertLongIntegerToLongIntegerRegister(power, REGISTER_X);

  longIntegerFree(power);
  longIntegerFree(base);
  longIntegerFree(exponent);
  return 1;
}

static void z47_math_wrappers_init_constant(real_t *value, int32_t exponent, uint8_t bits, uint16_t lsu0) {
  memset(value, 0, sizeof(*value));
  value->digits = 1;
  value->exponent = exponent;
  value->bits = bits;
  value->lsu[0] = lsu0;
}

const real_t *z47_math_wrappers_const_0(void) {
  static bool initialized = false;
  static real_t value;

  if(!initialized) {
    z47_math_wrappers_init_constant(&value, 0, 0, 0);
    initialized = true;
  }

  return &value;
}

const real_t *z47_math_wrappers_const_1(void) {
  static bool initialized = false;
  static real_t value;

  if(!initialized) {
    z47_math_wrappers_init_constant(&value, 0, 0, 1);
    initialized = true;
  }

  return &value;
}

const real_t *z47_math_wrappers_const_minus_1(void) {
  static bool initialized = false;
  static real_t value;

  if(!initialized) {
    z47_math_wrappers_init_constant(&value, 0, 0x80, 1);
    initialized = true;
  }

  return &value;
}

const real_t *z47_math_wrappers_const_2(void) {
#ifdef Z47_MATH_WRAPPERS_C47_H
  static bool initialized = false;
  static real_t value;

  if(!initialized) {
    z47_math_wrappers_init_constant(&value, 0, 0, 2);
    initialized = true;
  }

  return &value;
#else
  return const_2;
#endif
}

const real_t *z47_math_wrappers_const_5(void) {
#ifdef Z47_MATH_WRAPPERS_C47_H
  static bool initialized = false;
  static real_t value;

  if(!initialized) {
    z47_math_wrappers_init_constant(&value, 0, 0, 5);
    initialized = true;
  }

  return &value;
#else
  return const_5;
#endif
}

const real_t *z47_math_wrappers_const_1on2(void) {
#ifdef Z47_MATH_WRAPPERS_C47_H
  static bool initialized = false;
  static real_t value;

  if(!initialized) {
    z47_math_wrappers_init_constant(&value, -1, 0, 5);
    initialized = true;
  }

  return &value;
#else
  return const_1on2;
#endif
}

const real_t *z47_math_wrappers_const_1on3(void) {
#ifdef Z47_MATH_WRAPPERS_C47_H
  static bool initialized = false;
  static real_t value;

  if(!initialized) {
    z47_math_wrappers_init_constant(&value, 0, 0, 1);
    initialized = true;
  }

  return &value;
#else
  return const39_1on3;
#endif
}

const real_t *z47_math_wrappers_const_2e6(void) {
  static bool initialized = false;
  static real_t value;

  if(!initialized) {
    z47_math_wrappers_init_constant(&value, 6, 0, 2);
    initialized = true;
  }

  return &value;
}

const real_t *z47_math_wrappers_const_1oneE(void) {
#ifdef Z47_MATH_WRAPPERS_C47_H
  static bool initialized = false;
  static real_t value;

  if(!initialized) {
    z47_math_wrappers_init_constant(&value, 0, 0, 1);
    initialized = true;
  }

  return &value;
#else
  return const39_1oneE;
#endif
}

const real_t *z47_math_wrappers_const_90(void) {
#ifdef Z47_MATH_WRAPPERS_C47_H
  static bool initialized = false;
  static real_t value;

  if(!initialized) {
    z47_math_wrappers_init_constant(&value, 0, 0, 90);
    initialized = true;
  }

  return &value;
#else
  return const_90;
#endif
}

#ifndef Z47_MATH_WRAPPERS_C47_H
const real_t *z47_math_wrappers_const_100(void) {
  return const_100;
}

#endif

#ifndef Z47_MATH_WRAPPERS_C47_H
const real_t *z47_math_wrappers_const_180(void) {
  return const_180;
}

#endif

const real_t *z47_math_wrappers_const_ln2(void) {
#ifdef Z47_MATH_WRAPPERS_C47_H
  static bool initialized = false;
  static real_t value;

  if(!initialized) {
    z47_math_wrappers_init_constant(&value, 0, 0, 2);
    initialized = true;
  }

  return &value;
#else
  return const39_ln2;
#endif
}

const real_t *z47_math_wrappers_const75_piOn4(void) {
#ifdef Z47_MATH_WRAPPERS_C47_H
  static bool initialized = false;
  static real_t value;

  if(!initialized) {
    z47_math_wrappers_init_constant(&value, 0, 0, 3);
    initialized = true;
  }

  return &value;
#else
  return const75_piOn4;
#endif
}

const real_t *z47_math_wrappers_const75_piOn2(void) {
#ifdef Z47_MATH_WRAPPERS_C47_H
  static bool initialized = false;
  static real_t value;

  if(!initialized) {
    z47_math_wrappers_init_constant(&value, 0, 0, 3);
    initialized = true;
  }

  return &value;
#else
  return const75_piOn2;
#endif
}

const real_t *z47_math_wrappers_const75_pi(void) {
#ifdef Z47_MATH_WRAPPERS_C47_H
  static bool initialized = false;
  static real_t value;

  if(!initialized) {
    z47_math_wrappers_init_constant(&value, 0, 0, 3);
    initialized = true;
  }

  return &value;
#else
  return const75_pi;
#endif
}
const real_t *z47_math_wrappers_const_ln10(void) {
#ifdef Z47_MATH_WRAPPERS_C47_H
  static bool initialized = false;
  static real_t value;

  if(!initialized) {
    z47_math_wrappers_init_constant(&value, 0, 0, 10);
    initialized = true;
  }

  return &value;
#else
  return const39_ln10;
#endif
}

const real_t *z47_math_wrappers_const_phi(void) {
#ifdef Z47_MATH_WRAPPERS_C47_H
  static bool initialized = false;
  static real_t value;

  if(!initialized) {
    z47_math_wrappers_init_constant(&value, 0, 0, 2);
    initialized = true;
  }

  return &value;
#else
  return const39_PHI;
#endif
}

const real_t *z47_math_wrappers_const_pi(void) {
#ifdef Z47_MATH_WRAPPERS_C47_H
  static bool initialized = false;
  static real_t value;

  if(!initialized) {
    z47_math_wrappers_init_constant(&value, 0, 0, 3);
    initialized = true;
  }

  return &value;
#else
  return const39_pi;
#endif
}

const real_t *z47_math_wrappers_const_plus_infinity(void) {
  static bool initialized = false;
  static real_t value;

  if(!initialized) {
    z47_math_wrappers_init_constant(&value, 0, 0x40, 0);
    initialized = true;
  }

  return &value;
}

const real_t *z47_math_wrappers_const_minus_infinity(void) {
  static bool initialized = false;
  static real_t value;

  if(!initialized) {
    z47_math_wrappers_init_constant(&value, 0, 0xc0, 0);
    initialized = true;
  }

  return &value;
}

void z47_math_wrappers_report_sinc_real_domain_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function sincReal:", "cannot divide a real34 by " STD_PLUS_MINUS STD_INFINITY " when flag D is not set", NULL, NULL);
#endif
}

void z47_math_wrappers_report_sincpi_real_domain_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function sincpiReal:", "cannot divide a real34 by " STD_PLUS_MINUS STD_INFINITY " when flag D is not set", NULL, NULL);
#endif
}

void z47_math_wrappers_report_exp_m1_real_domain_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function expM1Real:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of exp when flag D is not set", NULL, NULL);
#endif
}

void z47_math_wrappers_report_ln_p1_real_zero_domain_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function lnP1Real:", "cannot calculate Ln(0) in Ln(1 + x)", NULL, NULL);
#endif
}

void z47_math_wrappers_report_ln_p1_real_infinite_domain_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function lnP1Real:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of ln(x+1) when flag SPCRES is not set", NULL, NULL);
#endif
}

void z47_math_wrappers_report_ln_p1_real_negative_domain_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function lnP1Real:", "cannot calculate Ln of a negative number when CPXRES is not set!", NULL, NULL);
#endif
}

void z47_math_wrappers_report_ln_p1_cplx_zero_domain_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function lnP1Cplx:", "cannot calculate Ln(0) in Ln(1 + x)", NULL, NULL);
#endif
}

void z47_math_wrappers_report_exp_real_domain_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function expReal:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of exp when flag D is not set", NULL, NULL);
#endif
}

void z47_math_wrappers_report_arcsin_real_domain_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function arcsinReal:", "|X| > 1", "and CPXRES is not set!", NULL);
#endif
}

void z47_math_wrappers_report_arccos_real_domain_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function arccosReal:", "|X| > 1", "and CPXRES is not set!", NULL);
#endif
}

void z47_math_wrappers_report_arctan_real_domain_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function arctanReal:", "X = " STD_PLUS_MINUS STD_INFINITY, NULL, NULL);
#endif
}

void z47_math_wrappers_report_arccosh_real_domain_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function arccoshReal:", "X < 1", "and CPXRES is not set!", NULL);
#endif
}

void z47_math_wrappers_report_arctanh_real_positive_one_domain_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function arctanhReal:", "X = 1", "and DANGER flag is not set!", NULL);
#endif
}

void z47_math_wrappers_report_arctanh_real_negative_one_domain_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function arctanhReal:", "X = -1", "and DANGER flag is not set!", NULL);
#endif
}

void z47_math_wrappers_report_arctanh_real_domain_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function arctanhReal:", "|X| > 1", "and CPXRES is not set!", NULL);
#endif
}

void z47_math_wrappers_report_int_pow_real_domain_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function intPowReal:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of 10^x when flag D is not set", NULL, NULL);
#endif
}

void z47_math_wrappers_report_eulers_formula_complex_domain_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function eulersFormulaCplx:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as real or imag X input when flag SPCRES is not set", NULL, NULL);
#endif
}

void z47_math_wrappers_report_eulers_formula_real_domain_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function eulersFormulaReal:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input when flag SPCRES is not set", NULL, NULL);
#endif
}

void z47_math_wrappers_report_sign_real_nan_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function signReal:", "cannot use NaN as X input of SIGN", NULL, NULL);
#endif
}

void z47_math_wrappers_report_invert_real_divide_by_zero_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function invertReal:", "cannot divide a real by 0", NULL, NULL);
#endif
}

void z47_math_wrappers_report_sinh_cosh_real_domain_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function sinhCoshReal:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of sinh when flag D is not set", NULL, NULL);
#endif
}

void z47_math_wrappers_report_tanh_real_domain_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function tanhReal:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of tanh when flag D is not set", NULL, NULL);
#endif
}

void z47_math_wrappers_report_square_real_domain_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function squareReal:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of curt when flag D is not set", NULL, NULL);
#endif
}

void z47_math_wrappers_report_tan_real_pole_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function tanReal:", "X = " STD_PLUS_MINUS "90" STD_DEGREE, NULL, NULL);
#endif
}

void z47_math_wrappers_report_cube_real_domain_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function cubeReal:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of curt when flag D is not set", NULL, NULL);
#endif
}

#define fnBn z47_math_wrappers_retained_fnBn
#define fnBnStar z47_math_wrappers_retained_fnBnStar
#include "../../src/c47/mathematics/bn.c"
#undef fnBnStar
#undef fnBn

#define fnExpt z47_math_wrappers_retained_fnExpt
#include "../../src/c47/mathematics/expt.c"
#undef fnExpt

#define fnWpositive z47_math_wrappers_retained_fnWpositive
#include "../../src/c47/mathematics/w_positive.c"
#undef fnWpositive

#define fnWnegative z47_math_wrappers_retained_fnWnegative
#include "../../src/c47/mathematics/w_negative.c"
#undef fnWnegative

#define fnWinverse z47_math_wrappers_retained_fnWinverse
#include "../../src/c47/mathematics/w_inverse.c"
#undef fnWinverse

#define fnGcd z47_math_wrappers_retained_fnGcd
#include "../../src/c47/mathematics/gcd.c"
#undef fnGcd

#define fnLcm z47_math_wrappers_retained_fnLcm
#include "../../src/c47/mathematics/lcm.c"
#undef fnLcm

#define modReal z47_math_wrappers_retained_modReal
#define fnMod z47_math_wrappers_retained_fnMod
#include "../../src/c47/mathematics/modulo.c"
#undef fnMod
#undef modReal

#define fnRmd z47_math_wrappers_retained_fnRmd
#include "../../src/c47/mathematics/remainder.c"
#undef fnRmd

#define fnUlp z47_math_wrappers_retained_fnUlp
#include "../../src/c47/mathematics/ulp.c"
#undef fnUlp

#define mant z47_math_wrappers_retained_mant
#define mantLonI z47_math_wrappers_retained_mantLonI
#define mantReal z47_math_wrappers_retained_mantReal
#define fnMant z47_math_wrappers_retained_fnMant
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  #define mantError z47_math_wrappers_retained_mantError
  void mantError(void);
#else
  #define mantError typeError
#endif
void mantLonI(void);
void mantReal(void);
#include "../../src/c47/mathematics/mant.c"
#undef fnMant
#undef mantReal
#undef mantLonI
#undef mantError
#undef mant

#define Roundi z47_math_wrappers_retained_Roundi
#define roundiRema z47_math_wrappers_retained_roundiRema
#define roundiReal z47_math_wrappers_retained_roundiReal
#define fnRoundi z47_math_wrappers_retained_fnRoundi
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  #define roundiError z47_math_wrappers_retained_roundiError
  void roundiError(void);
#else
  #define roundiError typeError
#endif
void roundiRema(void);
void roundiReal(void);
#include "../../src/c47/mathematics/roundi.c"
#undef fnRoundi
#undef roundiReal
#undef roundiRema
#undef roundiError
#undef Roundi

#define fnNeighb z47_math_wrappers_retained_fnNeighb
#include "../../src/c47/mathematics/neighb.c"
#undef fnNeighb

#define fnIxyz z47_math_wrappers_retained_fnIxyz
#include "../../src/c47/mathematics/ixyz.c"
#undef fnIxyz

#define log z47_math_wrappers_log
#define fnFactorial z47_math_wrappers_retained_fnFactorial
#include "../../src/c47/mathematics/factorial.c"
#undef fnFactorial
#undef log

#define fnRealPart z47_math_wrappers_retained_fnRealPart
#include "../../src/c47/mathematics/realPart.c"
#undef fnRealPart

#define fnImaginaryPart z47_math_wrappers_retained_fnImaginaryPart
#include "../../src/c47/mathematics/imaginaryPart.c"
#undef fnImaginaryPart

#define arg z47_math_wrappers_retained_arg
#define fnArg z47_math_wrappers_retained_fnArg
#include "../../src/c47/mathematics/arg.c"
#undef fnArg
#undef arg

#define complexMagnitude2 z47_math_wrappers_retained_complexMagnitude2
#define complexMagnitude z47_math_wrappers_retained_complexMagnitude
#define fnMagnitude z47_math_wrappers_retained_fnMagnitude
void complexMagnitude(const real_t *a, const real_t *b, real_t *c, realContext_t *realContext);
#include "../../src/c47/mathematics/magnitude.c"
#undef fnMagnitude
#undef complexMagnitude
#undef complexMagnitude2

#ifndef Z47_MATH_WRAPPERS_C47_H
void complexMagnitude2(const real_t *a, const real_t *b, real_t *c, realContext_t *realContext) {
  z47_math_wrappers_retained_complexMagnitude2(a, b, c, realContext);
}

void complexMagnitude(const real_t *a, const real_t *b, real_t *c, realContext_t *realContext) {
  z47_math_wrappers_retained_complexMagnitude(a, b, c, realContext);
}
#endif

#define conjCplx z47_math_wrappers_retained_conjCplx
#define fnConjugate z47_math_wrappers_retained_fnConjugate
#include "../../src/c47/mathematics/conjugate.c"
#undef fnConjugate
#undef conjCplx

void conjCplx(void) {
  z47_math_wrappers_retained_conjCplx();
}

#define fnSwapRealImaginary z47_math_wrappers_retained_fnSwapRealImaginary
#include "../../src/c47/mathematics/swapRealImaginary.c"
#undef fnSwapRealImaginary

#define arctan2 z47_math_wrappers_retained_arctan2
#define atan2RealReal z47_math_wrappers_retained_atan2RealReal
#define atan2RemaRema z47_math_wrappers_retained_atan2RemaRema
#define atan2RemaReal z47_math_wrappers_retained_atan2RemaReal
#define atan2RealRema z47_math_wrappers_retained_atan2RealRema
#define atan2LonIRema z47_math_wrappers_retained_atan2LonIRema
#define fnAtan2 z47_math_wrappers_retained_fnAtan2
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  #define atan2Error z47_math_wrappers_retained_atan2Error
  void atan2Error(void);
#else
  #define atan2Error typeError
#endif
void atan2RealReal(void);
void atan2RemaRema(void);
void atan2RemaReal(void);
void atan2RealRema(void);
void atan2LonIRema(void);
#include "../../src/c47/mathematics/atan2.c"
#undef fnAtan2
#undef atan2LonIRema
#undef atan2RealRema
#undef atan2RemaReal
#undef atan2RemaRema
#undef atan2RealReal
#undef atan2Error
#undef arctan2

#define percentReal z47_math_wrappers_retained_percentReal
#define fnPercent z47_math_wrappers_retained_fnPercent
#include "../../src/c47/mathematics/percent.c"
#undef fnPercent
#undef percentReal