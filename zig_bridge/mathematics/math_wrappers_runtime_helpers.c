// SPDX-License-Identifier: GPL-3.0-only

#include <string.h>

#include "c47.h"

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