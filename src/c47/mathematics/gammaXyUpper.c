// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file gammaXyUpper.c
 ***********************************************/

#include "c47.h"

TO_QSPI void (* const GammaXyUpper[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX |    regY ==>   1                     2                     3                  4                  5                  6                  7                  8                  9                  10
//      V               Long integer          Real34                Complex34          Time               Date               String             Real34 matrix      Complex34 matrix   Short integer      Config data
/*  1 Long integer  */ {gammaXyUpperLonILonI, gammaXyUpperLonIReal, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError},
/*  2 Real34        */ {gammaXyUpperRealLonI, gammaXyUpperRealReal, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError},
/*  3 Complex34     */ {gammaXyUpperError,    gammaXyUpperError,    gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError},
/*  4 Time          */ {gammaXyUpperError,    gammaXyUpperError,    gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError},
/*  5 Date          */ {gammaXyUpperError,    gammaXyUpperError,    gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError},
/*  6 String        */ {gammaXyUpperError,    gammaXyUpperError,    gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError},
/*  7 Real34 mat    */ {gammaXyUpperError,    gammaXyUpperError,    gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError},
/*  8 Complex34 mat */ {gammaXyUpperError,    gammaXyUpperError,    gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError},
/*  9 Short integer */ {gammaXyUpperError,    gammaXyUpperError,    gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError},
/* 10 Config data   */ {gammaXyUpperError,    gammaXyUpperError,    gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError, gammaXyUpperError}
};



/********************************************//**
 * \brief Data type error in incomplete gamma function
 *
 * \param void
 * \return void
 ***********************************************/
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  void gammaXyUpperError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate " STD_GAMMA STD_SUB_x STD_SUB_y " for %s and %s", getRegisterDataTypeName(REGISTER_X, true, false), getRegisterDataTypeName(REGISTER_Y, true, false));
    moreInfoOnError("In function fnGammaXyUpper:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and gamma(regX, regY) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnGammaXyUpper(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  GammaXyUpper[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)]();

  adjustResult(REGISTER_X, true, true, REGISTER_X, REGISTER_Y, -1);
}



void gammaXyUpperLonILonI(void) {
  real_t x, y, res;

  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
  convertLongIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);
  if(!getSystemFlag(FLAG_SPCRES) && (realCompareLessEqual(&x, const_0) || realCompareLessThan(&y, const_0))) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function gammaXyUpperLonILonI:", "Y must be non-negative and X must be positive", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  else {
    WP34S_GammaP(&y, &x, &res, &ctxtReal39, true, false);
    reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
    convertRealToReal34ResultRegister(&res, REGISTER_X);
  }
}



void gammaXyUpperLonIReal(void) {
  real_t x, y, res;

  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
  if(!getSystemFlag(FLAG_SPCRES) && (realCompareLessEqual(&x, const_0) || realCompareLessThan(&y, const_0))) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function gammaXyUpperLonIReal:", "Y must be non-negative and X must be positive", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  else {
    WP34S_GammaP(&y, &x, &res, &ctxtReal39, true, false);
    reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
    convertRealToReal34ResultRegister(&res, REGISTER_X);
  }
}



void gammaXyUpperRealLonI(void) {
  real_t x, y, res;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
  convertLongIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);
  if(!getSystemFlag(FLAG_SPCRES) && (realCompareLessEqual(&x, const_0) || realCompareLessThan(&y, const_0))) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function gammaXyUpperRealLonI:", "Y must be non-negative and X must be positive", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  else {
    WP34S_GammaP(&y, &x, &res, &ctxtReal39, true, false);
    convertRealToReal34ResultRegister(&res, REGISTER_X);
  }
}



void gammaXyUpperRealReal(void) {
  real_t x, y, res;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
  if(!getSystemFlag(FLAG_SPCRES) && (realCompareLessEqual(&x, const_0) || realCompareLessThan(&y, const_0))) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function gammaXyUpperRealReal:", "Y must be non-negative and X must be positive", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  else {
    WP34S_GammaP(&y, &x, &res, &ctxtReal39, true, false);
    convertRealToReal34ResultRegister(&res, REGISTER_X);
  }
}
