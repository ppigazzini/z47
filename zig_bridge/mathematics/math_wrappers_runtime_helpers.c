// SPDX-License-Identifier: GPL-3.0-only

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

void z47_math_wrappers_report_sign_real_nan_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function signReal:", "cannot use NaN as X input of SIGN", NULL, NULL);
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