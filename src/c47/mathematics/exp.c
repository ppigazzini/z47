// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file exp.c
 ***********************************************/

#include "c47.h"

TO_QSPI void (* const Exp[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2        3         4         5         6         7          8           9             10
//          Long integer Real34   Complex34 Time      Date      String    Real34 mat Complex34 m Short integer Config data
            expLonI,     expReal, expCplx,  expError, expError, expError, expRema,   expCxma,    expShoI,      expError
};



/********************************************//**
 * \brief Data type error in exp
 *
 * \param void
 * \return void
 ***********************************************/
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  void expError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate Exp for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnExp:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and exp(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnExp(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  Exp[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}

bool_t realExpLimitCheck(const real_t *x, real_t *res, const real_t *zero) {
  if(realIsSpecial(x)) {
    if(realIsInfinite(x)) {
inf:  if(realIsPositive(x)) {
        realCopy(const_plusInfinity, res);
      }
      else {
        realCopy(zero, res);
      }
    }
    else {
      realCopy(const_NaN, res);
    }
    return false;
  }
  if(realCompareAbsGreaterThan(x, const_2e6))
    goto inf;
  return true;
}

void realExp(const real_t *x, real_t *res, realContext_t *set) {
  if(realExpLimitCheck(x, res, const_0))
    decNumberExp(res, x, set);
}

void expComplex(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext) {
  real_t expa, sin, cos;

  if(realIsZero(imag)) {
   realExp(real, resReal, realContext);
   realZero(resImag);
   return;
  }

  if(realIsSpecial(real) || realIsSpecial(imag)) {
    realCopy(const_NaN, resReal);
    realCopy(const_NaN, resImag);
    return;
  }

 realExp(real, &expa, realContext);
 WP34S_Cvt2RadSinCosTan(imag, amRadian, &sin, &cos, NULL, realContext);
 realMultiply(&expa, &cos, resReal, realContext);
 realMultiply(&expa, &sin, resImag, realContext);
}



/**********************************************************************
 * In all the functions below:
 * if X is a number then X = a + ib
 * The variables a and b are used for intermediate calculations
 ***********************************************************************/

void expLonI(void) {
  real_t a;

  convertLongIntegerRegisterToReal(REGISTER_X, &a, &ctxtReal39);
  realExp(&a, &a, &ctxtReal39);
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  convertRealToReal34ResultRegister(&a, REGISTER_X);
}



void expRema(void) {
  elementwiseRema(expReal);
}



void expCxma(void) {
  elementwiseCxma(expCplx);
}



void expShoI(void) {
  real_t x;

  convertShortIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
  realExp(&x, &x, &ctxtReal39);
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  convertRealToReal34ResultRegister(&x, REGISTER_X);
}



void expReal(void) {
  if(real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X)) && !getSystemFlag(FLAG_SPCRES)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function expReal:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of exp when flag D is not set", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  real_t x;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
  realExp(&x, &x, &ctxtReal39);
  convertRealToReal34ResultRegister(&x, REGISTER_X);
  setRegisterAngularMode(REGISTER_X, amNone);
}



void expCplx(void) {
  real_t zReal, zImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &zReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &zImag);

  expComplex(&zReal, &zImag, &zReal, &zImag, &ctxtReal39);

  convertComplexToResultRegister(&zReal, &zImag, REGISTER_X);
}
