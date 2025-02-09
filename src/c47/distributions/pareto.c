// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The C47 Authors

/********************************************//**
 * \file pareto.c
 ***********************************************/

#include "c47.h"

static bool_t checkParamGPD(real_t *x, real_t *i, real_t *j) {
  if(!getRegisterAsReal(REGISTER_X, x)
      || !getRegisterAsReal(REGISTER_M, i)
      || !getRegisterAsReal(REGISTER_N, j))
    goto err;

  if(!(checkRegisterNoFP(i) || checkRegisterNoFP(j))) {
    displayDomainErrorMessage(ERROR_INVALID_DISTRIBUTION_PARAM, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function checkParamGPD:", "d1 or d2 is not an integer", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    goto err;
  }
  if(realIsNegative(x)) {
    displayDomainErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function checkParamPareto:", "cannot calculate for x < 0", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    goto err;
  }
  if(realIsZero(i) || realIsNegative(i) || realIsZero(j) || realIsNegative(j)) {
    displayDomainErrorMessage(ERROR_INVALID_DISTRIBUTION_PARAM, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function checkParamGPD:", "cannot calculate for d1 " STD_LESS_EQUAL " 0 or d2 " STD_LESS_EQUAL " 0", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    goto err;
  }
  return true;

err:
  if(getSystemFlag(FLAG_SPCRES)) {
    convertRealToResultRegister(const_NaN, REGISTER_X, amNone);
  }
  return false;
}

void fnParetoP(uint16_t unusedButMandatoryParameter) {
  real_t val, ans, d1, d2;

  if(!saveLastX()) {
    return;
  }

  if(checkParamGPD(&val, &d1, &d2)) {
    WP34S_Pdf_F(&val, &d1, &d2, &ans, &ctxtReal39);
    convertRealToResultRegister(&ans, REGISTER_X, amNone);
  }

  adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
}

void fnParetoL(uint16_t unusedButMandatoryParameter) {
  real_t val, ans, d1, d2;

  if(!saveLastX()) {
    return;
  }

  if(checkParamGPD(&val, &d1, &d2)) {
    WP34S_Cdf_F(&val, &d1, &d2, &ans, &ctxtReal39);
    convertRealToResultRegister(&ans, REGISTER_X, amNone);
  }

  adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
}

void fnParetoU(uint16_t unusedButMandatoryParameter) {
  real_t val, ans, d1, d2;

  if(!saveLastX()) {
    return;
  }

  if(checkParamGPD(&val, &d1, &d2)) {
    WP34S_Cdfu_F(&val, &d1, &d2, &ans, &ctxtReal39);
    convertRealToResultRegister(&ans, REGISTER_X, amNone);
  }

  adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
}

void fnParetoI(uint16_t unusedButMandatoryParameter) {
    real_t val, ans, d1, d2;

    if(!saveLastX()) {
      return;
    }

    if(checkParamGPD(&val, &d1, &d2)) {
      if(realCompareLessEqual(&val, const_0) || realCompareGreaterEqual(&val, const_1)) {
        displayDomainErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        #if (EXTRA_INFO_ON_CALC_ERROR == 1)
          moreInfoOnError("In function fnGPDI:", "the argument must be 0 < x < 1", NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        if(getSystemFlag(FLAG_SPCRES)) {
          convertRealToResultRegister(const_NaN, REGISTER_X, amNone);
        }
        return;
      }
      WP34S_Qf_F(&val, &d1, &d2, &ans, &ctxtReal39);
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
    }

    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
}

