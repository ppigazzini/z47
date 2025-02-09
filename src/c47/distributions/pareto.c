// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The C47 Authors

/********************************************//**
 * \file pareto.c
 ***********************************************/

#include "c47.h"

bool_t checkParamGPD(real_t *x, real_t *mu, real_t *sigma, real_t *xi, bool_t qf) {
  real_t t;

  if(!saveLastX())
    return false;

  if(!getRegisterAsReal(REGISTER_X, x)
      || !getRegisterAsReal(REGISTER_M, mu)
      || !getRegisterAsReal(REGISTER_S, sigma)
      || !getRegisterAsReal(REGISTER_Q, xi))
    goto err;

  if(realIsNegative(x)) {
    displayDomainErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function checkParamGPD:", "cannot calculate for x < 0", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    goto err;
  }
  else if(realIsZero(sigma) || realIsNegative(sigma)) {
    displayDomainErrorMessage(ERROR_INVALID_DISTRIBUTION_PARAM, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function checkParamGPD:", "the parameter sigma must be positive", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    goto err;
  }

  // Check support range
  if(qf || realIsZero(xi))
    return true;                                // xi = 0, full line
  realSubtract(mu, sigma, &t, &ctxtReal39);
  realDivide(&t, xi, &t, &ctxtReal39);
  if(realIsNegative(xi))
    return realCompareLessEqual(x, &t);         // xi < 0, (-inf, (mu-sigma)/xi]
  return realCompareGreaterEqual(x, &t);        // xi > 0, [(mu-sigma)/xi, +inf)

  err:
  if(getSystemFlag(FLAG_SPCRES)) {
    convertRealToResultRegister(const_NaN, REGISTER_X, amNone);
  }
  return false;
}

void fnParetoP(uint16_t unusedButMandatoryParameter) {
  real_t x, mu, sigma, xi;

  if(checkParamGPD(&x, &mu, &sigma, &xi, false)) {
    //WP34S_Pdf_F(&val, &d1, &d2, &ans, &ctxtReal39);
    convertRealToResultRegister(&ans, REGISTER_X, amNone);
    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
  }
}

void fnParetoL(uint16_t unusedButMandatoryParameter) {
  real_t x, mu, sigma, xi;

  if(checkParamGPD(&x, &mu, &sigma, &xi, false)) {
    //WP34S_Cdf_F(&val, &d1, &d2, &ans, &ctxtReal39);
    convertRealToResultRegister(&ans, REGISTER_X, amNone);
    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
  }
}

void fnParetoU(uint16_t unusedButMandatoryParameter) {
  real_t x, mu, sigma, xi;

  if(checkParamGPD(&x, &mu, &sigma, &xi, false)) {
    //WP34S_Cdfu_F(&val, &d1, &d2, &ans, &ctxtReal39);
    convertRealToResultRegister(&ans, REGISTER_X, amNone);
    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
  }
}

void fnParetoI(uint16_t unusedButMandatoryParameter) {
  real_t x, mu, sigma, xi;

    if(checkParamGPD(&x, &mu, &sigma, &xi, true)) {
      //WP34S_Qf_F(&val, &d1, &d2, &ans, &ctxtReal39);
      if(realIsNaN(&ans)) {
        displayDomainErrorMessage(ERROR_NO_ROOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
        #if (EXTRA_INFO_ON_CALC_ERROR == 1)
          moreInfoOnError("In function fGPDI:", "WP34S_Qf_F did not converge", NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        if(getSystemFlag(FLAG_SPCRES)) {
          convertRealToResultRegister(const_NaN, REGISTER_X, amNone);
        }
        return;
      }
      convertRealToResultRegister(&ans, REGISTER_X, amNone);
      adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
    }
}

