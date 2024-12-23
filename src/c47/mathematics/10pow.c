// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file 10pow.c
 ***********************************************/

#include "c47.h"

TO_QSPI void (* const tenPow[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2           3           4            5            6            7           8           9             10
//          Long integer Real34      Complex34   Time         Date         String       Real34 mat  Complex34 m Short integer Config data
            tenPowLonI,  tenPowReal, tenPowCplx, tenPowError, tenPowError, tenPowError, tenPowRema, tenPowCxma, tenPowShoI,   tenPowError
};



/********************************************//**
 * \brief Data type error in exp
 *
 * \param void
 * \return void
 ***********************************************/
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  void tenPowError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate 10" STD_SUP_BOLD_x " for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fn10Pow:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and 10^regX ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fn10Pow(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  tenPow[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}



void realPower10(const real_t *x, real_t *res, realContext_t *realContext) {
  realMultiply(x, const_ln10, res, realContext);
  realExp(res, res, realContext);
}



void tenPowLonI(void) {
  int32_t exponentSign;
  longInteger_t base, exponent;

  longIntegerInit(base);
  uInt32ToLongInteger(10u, base);
  convertLongIntegerRegisterToLongInteger(REGISTER_X, exponent);

  longIntegerSetPositiveSign(base);

  exponentSign = longIntegerSign(exponent);
  longIntegerSetPositiveSign(exponent);

  if(longIntegerIsZero(exponent)) {
    uInt32ToLongInteger(1u, base);
    convertLongIntegerToLongIntegerRegister(base, REGISTER_X);
    longIntegerFree(base);
    longIntegerFree(exponent);
    return;
  }
  else if(exponentSign == -1) {
    longIntegerFree(base);
    longIntegerFree(exponent);
    convertLongIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
    tenPowReal();
    return;
  }

  longInteger_t power;

  longIntegerInit(power);
  uInt32ToLongInteger(1u, power);

  while(!longIntegerIsZero(exponent) && lastErrorCode == 0) {
    if(longIntegerIsOdd(exponent)) {
     longIntegerMultiply(power, base, power);
    }

    longIntegerDivideUInt(exponent, 2, exponent);

    if(!longIntegerIsZero(exponent)) {
      longIntegerSquare(base, base);
    }
  }

  convertLongIntegerToLongIntegerRegister(power, REGISTER_X);

  longIntegerFree(power);
  longIntegerFree(base);
  longIntegerFree(exponent);
}



void tenPowRema(void) {
  elementwiseRema(tenPowReal);
}



void tenPowCxma(void) {
  elementwiseCxma(tenPowCplx);
}



void tenPowShoI(void) {
  *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = WP34S_int10pow(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)));
}



void tenPowReal(void) {
  if(real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X)) && !getSystemFlag(FLAG_SPCRES)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function tenPowReal:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of 10" STD_SUP_BOLD_x " when flag D is not set", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  real_t x;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
  realPower10(&x, &x, &ctxtReal39);
  convertRealToReal34ResultRegister(&x, REGISTER_X);
  setRegisterAngularMode(REGISTER_X, amNone);
}



void tenPowCplx(void) {
  real_t a, b, factor;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &a);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &b);

  // ln(10) * (a + bi) --> (a + bi)
  realMultiply(const_ln10, &a, &a, &ctxtReal39);
  realMultiply(const_ln10, &b, &b, &ctxtReal39);

  // exp(ln(10) * (a + bi)) --> (a + bi)
  realExp(&a, &factor, &ctxtReal39);
  realPolarToRectangular(const_1, &b, &a, &b, &ctxtReal39);
  realMultiply(&factor, &a, &a, &ctxtReal39);
  realMultiply(&factor, &b, &b, &ctxtReal39);

  convertComplexToResultRegister(&a, &b, REGISTER_X);
}
