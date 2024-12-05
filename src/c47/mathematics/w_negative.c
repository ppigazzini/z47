// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file w_negative.c
 ***********************************************/

#include "mathematics/w_negative.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/matrix.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"

static void wNegReal(void) {
  real_t x, res;

  if(!getRegisterAsReal(REGISTER_X, &x))
    return;

  if(realCompareGreaterEqual(&x, const__1oneE) && realCompareLessEqual(&x, const_0)) {
    WP34S_LambertW(&x, &res, true, &ctxtReal39);
    convertRealToResultRegister(&res, REGISTER_X, amNone);
  }
  else {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function wNegReal:", "X < -e^(-1) || 0 < X", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}

static void wNegCplx(void) {
  real_t xr, xi, res;

  if(!getRegisterAsComplex(REGISTER_X, &xr, &xi))
    return;

  if(realIsZero(&xi)) {
    if(realCompareGreaterEqual(&xr, const__1oneE) && realCompareLessEqual(&xr, const_0)) {
      WP34S_LambertW(&xr, &res, true, &ctxtReal39);
      convertComplexToResultRegister(&res, const_0, REGISTER_X);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function wNegCplx:", "X < -e^(-1) || 0 < X", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }
  else {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function wNegCplx:", "Cannot calculate Wm for complex number with non-zero imaginary part", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}

/********************************************//**
 * \brief regX ==> regL and W(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnWnegative(uint16_t unusedButMandatoryParameter) {
  processRealComplexMonadicFunction(&wNegReal, &wNegCplx);
}
