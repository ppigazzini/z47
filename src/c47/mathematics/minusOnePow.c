// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file minusOnePow.c
 ***********************************************/

#include "c47.h"

TO_QSPI void (* const m1Pow[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2          3          4           5           6           7          8           9             10
//          Long integer Real34     complex34  Time        Date        String      Real34 mat Complex34 m Short integer Config data
            m1PowLonI,   m1PowReal, m1PowCplx, m1PowError, m1PowError, m1PowError, m1PowRema, m1PowCxma,  m1PowShoI,    m1PowError
};



/********************************************//**
 * \brief Data type error in exp
 *
 * \param void
 * \return void
 ***********************************************/
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  void m1PowError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate (-1)" STD_SUP_BOLD_x " for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnM1Pow:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and 10^regX ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnM1Pow(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  m1Pow[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}



/**********************************************************************
 * In all the functions below:
 * if X is a number then X = a + ib
 * The variables a and b are used for intermediate calculations
 ***********************************************************************/

void m1PowLonI(void) {
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



void m1PowRema(void) {
  elementwiseRema(m1PowReal);
}



void m1PowCxma(void) {
  elementwiseCxma(m1PowCplx);
}



void m1PowShoI(void) {
  int32_t signExponent;
  uint64_t valueExponent = WP34S_extract_value(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)), &signExponent);
  int32_t odd = valueExponent & 1;

  if(shortIntegerMode == SIM_UNSIGN && odd) {
    setSystemFlag(FLAG_OVERFLOW);
  }
  else {
    clearSystemFlag(FLAG_OVERFLOW);
  }

  *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = WP34S_build_value((uint64_t)1, odd);
}

void m1PowReal(void) {
  const real34_t *stk = REGISTER_REAL34_DATA(REGISTER_X);
  real_t x, y;

  setRegisterAngularMode(REGISTER_X, amNone);
  if(real34IsInfinite(stk) || real34IsNaN(stk)) {
    convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
    return;
  }

  real34ToReal(stk, &x);
  WP34S_Mod(&x, const_2, &x, &ctxtReal39);
  if(realIsZero(&x)) {
    convertRealToReal34ResultRegister(const_1, REGISTER_X);
  }
  else if(realCompareEqual(&x, const_1)) {
    convertRealToReal34ResultRegister(const__1, REGISTER_X);
  }
  else { /* Complex result */
    fnSetFlag(FLAG_CPXRES);
    fnRefreshState();

    angularMode_t savedAngularMode = currentAngularMode;
    currentAngularMode = amRadian;

    reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);

    realMultiply(&x, const_pi, &x, &ctxtReal75);
    eulersFormula(&x, const_0, &x, &y, &ctxtReal39);

    convertComplexToResultRegister(&x, &y, REGISTER_X);
    currentAngularMode = savedAngularMode;
  }
}



void m1PowCplx(void) {
  real_t zReal, zImag;

  fnSetFlag(FLAG_CPXRES);
  fnRefreshState();
  setRegisterAngularMode(REGISTER_X, amNone);

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &zReal);
  WP34S_Mod(&zReal, const_2, &zReal, &ctxtReal39);

  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &zImag);
  if(realIsZero(&zImag)) {
    if(realIsZero(&zReal)) {
      convertComplexToResultRegister(const_1, const_0, REGISTER_X);
      return;
    }
    else if(realCompareEqual(&zReal, const_1)) {
      convertComplexToResultRegister(const__1, const_0, REGISTER_X);
      return;
    }
  }
  angularMode_t savedAngularMode = currentAngularMode;
  currentAngularMode = amRadian;

  realMultiply(&zReal, const_pi, &zReal, &ctxtReal75);
  realMultiply(&zImag, const_pi, &zImag, &ctxtReal75);
  eulersFormula(&zReal, &zImag, &zReal, &zImag, &ctxtReal75);

  convertComplexToResultRegister(&zReal, &zImag, REGISTER_X);
  currentAngularMode = savedAngularMode;
}
