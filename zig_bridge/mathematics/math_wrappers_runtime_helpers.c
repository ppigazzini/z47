// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

void z47_math_wrappers_report_sinh_cosh_real_domain_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function sinhCoshReal:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of sinh when flag D is not set", NULL, NULL);
#endif
}

void z47_math_wrappers_report_tan_real_pole_error(void) {
  displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  moreInfoOnError("In function tanReal:", "X = " STD_PLUS_MINUS "90" STD_DEGREE, NULL, NULL);
#endif
}