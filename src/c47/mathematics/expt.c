// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file expt.c
 ***********************************************/

#include "c47.h"

TO_QSPI void (* const expt[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2         3          4          5          6          7          8           9             10
//          Long integer Real34    Complex34  Time       Date       String     Real34 mat Complex34 m Short integer Config data
            exptLonI,    exptReal, exptError, exptError, exptError, exptError, exptError, exptError,  exptError,    exptError
};



/********************************************//**
 * \brief Data type error in expt
 *
 * \param void
 * \return void
 ***********************************************/
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  void exptError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate EXPT for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function exptError:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and expt(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnExpt(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  expt[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
}



void exptLonI(void) {
  real_t x;
  longInteger_t lgInt;

  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
  longIntegerInit(lgInt);
  int32ToLongInteger((realIsZero(&x) ? 0 : x.exponent + x.digits - 1), lgInt);
  convertLongIntegerToLongIntegerRegister(lgInt, REGISTER_X);
  longIntegerFree(lgInt);
}



void exptReal(void) {
  if(real34IsNaN(REGISTER_REAL34_DATA(REGISTER_X))) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function exptReal:", "cannot use NaN as X input of EXPT", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  real_t x;
  longInteger_t lgInt;

  if(real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X))) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function exptReal:", "cannot use ±∞ as an input of EXPT", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
  longIntegerInit(lgInt);
  int32ToLongInteger((realIsZero(&x) ? 0 : x.exponent + x.digits - 1), lgInt);
  convertLongIntegerToLongIntegerRegister(lgInt, REGISTER_X);
  longIntegerFree(lgInt);
}
