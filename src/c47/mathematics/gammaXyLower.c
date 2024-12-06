// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file gammaXyLower.c
 ***********************************************/

#include "c47.h"

TO_QSPI void (* const GammaXyLower[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX |    regY ==>   1                     2                     3                  4                  5                  6                  7                  8                  9                  10
//      V               Long integer          Real34                Complex34          Time               Date               String             Real34 matrix      Complex34 matrix   Short integer      Config data
/*  1 Long integer  */ {gammaXyLowerLonILonI, gammaXyLowerLonIReal, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError},
/*  2 Real34        */ {gammaXyLowerRealLonI, gammaXyLowerRealReal, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError},
/*  3 Complex34     */ {gammaXyLowerError,    gammaXyLowerError,    gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError},
/*  4 Time          */ {gammaXyLowerError,    gammaXyLowerError,    gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError},
/*  5 Date          */ {gammaXyLowerError,    gammaXyLowerError,    gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError},
/*  6 String        */ {gammaXyLowerError,    gammaXyLowerError,    gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError},
/*  7 Real34 mat    */ {gammaXyLowerError,    gammaXyLowerError,    gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError},
/*  8 Complex34 mat */ {gammaXyLowerError,    gammaXyLowerError,    gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError},
/*  9 Short integer */ {gammaXyLowerError,    gammaXyLowerError,    gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError},
/* 10 Config data   */ {gammaXyLowerError,    gammaXyLowerError,    gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError, gammaXyLowerError}
};



/********************************************//**
 * \brief Data type error in incomplete gamma function
 *
 * \param void
 * \return void
 ***********************************************/
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  void gammaXyLowerError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate " STD_gamma STD_SUB_x STD_SUB_y " for %s and %s", getRegisterDataTypeName(REGISTER_X, true, false), getRegisterDataTypeName(REGISTER_Y, true, false));
    moreInfoOnError("In function fnGammaXyLower:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and gamma(regX, regY) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnGammaXyLower(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  GammaXyLower[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)]();

  adjustResult(REGISTER_X, true, true, REGISTER_X, REGISTER_Y, -1);
}



void gammaXyLowerLonILonI(void) {
  real_t x, y, res;

  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
  convertLongIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);
  if(!getSystemFlag(FLAG_SPCRES) && (realCompareLessEqual(&x, const_0) || realCompareLessThan(&y, const_0))) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function gammaXyLowerLonILonI:", "Y must be non-negative and X must be positive", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  else {
    WP34S_GammaP(&y, &x, &res, &ctxtReal39, false, false);
    reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
    convertRealToReal34ResultRegister(&res, REGISTER_X);
  }
}



void gammaXyLowerLonIReal(void) {
  real_t x, y, res;

  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
  if(!getSystemFlag(FLAG_SPCRES) && (realCompareLessEqual(&x, const_0) || realCompareLessThan(&y, const_0))) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function gammaXyLowerLonIReal:", "Y must be non-negative and X must be positive", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  else {
    WP34S_GammaP(&y, &x, &res, &ctxtReal39, false, false);
    reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
    convertRealToReal34ResultRegister(&res, REGISTER_X);
  }
}



void gammaXyLowerRealLonI(void) {
  real_t x, y, res;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
  convertLongIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);
  if(!getSystemFlag(FLAG_SPCRES) && (realCompareLessEqual(&x, const_0) || realCompareLessThan(&y, const_0))) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function gammaXyLowerRealLonI:", "Y must be non-negative and X must be positive", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  else {
    WP34S_GammaP(&y, &x, &res, &ctxtReal39, false, false);
    convertRealToReal34ResultRegister(&res, REGISTER_X);
  }
}



void gammaXyLowerRealReal(void) {
  real_t x, y, res;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
  if(!getSystemFlag(FLAG_SPCRES) && (realCompareLessEqual(&x, const_0) || realCompareLessThan(&y, const_0))) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function gammaXyLowerRealReal:", "Y must be non-negative and X must be positive", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  else {
    WP34S_GammaP(&y, &x, &res, &ctxtReal39, false, false);
    convertRealToReal34ResultRegister(&res, REGISTER_X);
  }
}
