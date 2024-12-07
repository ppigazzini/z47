// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

#include "c47.h"

TO_QSPI void (* const logBase2[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2         3         4          5          6          7          8           9             10
//          Long integer Real34    complex34 Time       Date       String     Real34 mat Complex34 m Short integer Config data
            log2LonI,    log2Real, log2Cplx, log2Error, log2Error, log2Error, log2Rema,  log2Cxma,   log2ShoI,     log2Error
};



/********************************************//**
 * \brief Data type error in log2
 *
 * \param void
 * \return void
 ***********************************************/
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  void log2Error(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate log2 for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnLog2:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and log2(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnLog2(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  logBase2[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}



/**********************************************************************
 * In all the functions below:
 * if X is a number then X = a + ib
 * The variables a and b are used for intermediate calculations
 ***********************************************************************/

void log2LonI(void) {
  longInteger_t lgInt;

  convertLongIntegerRegisterToLongInteger(REGISTER_X, lgInt);

  if(longIntegerIsZero(lgInt)) {
    if(getSystemFlag(FLAG_SPCRES)) {
      reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
      convertRealToReal34ResultRegister(const_minusInfinity, REGISTER_X);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function log2LonI:", "cannot calculate log2(0)", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }
  else {
    real_t x, y;

    convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);

    if(longIntegerIsPositive(lgInt)) {
      WP34S_Ln(&x, &x, &ctxtReal39);
      realDivide(&x, const_ln2, &x, &ctxtReal39);
      reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
      convertRealToReal34ResultRegister(&x, REGISTER_X);

      {
        longInteger_t xx, rr, yy;
        longIntegerInit(xx);
        longIntegerInit(rr);
        longIntegerInit(yy);
        uInt32ToLongInteger(2u, xx);
        convertReal34ToLongInteger(REGISTER_REAL34_DATA(REGISTER_X), rr, DEC_ROUND_HALF_EVEN);
        longIntegerPower(xx, rr, yy);
        if(longIntegerCompare(lgInt, yy) == 0) {
          lintReal();
        }
        longIntegerFree(yy);
        longIntegerFree(rr);
        longIntegerFree(xx);
      }
    }
    else if(getFlag(FLAG_CPXRES)) {
      realSetPositiveSign(&x);
      WP34S_Ln(&x, &x, &ctxtReal39);
      realDivide(&x, const_ln2, &x, &ctxtReal39);
      reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
      realDivide(const_pi, const_ln2, &y, &ctxtReal39);
      convertComplexToResultRegister(&x, &y, REGISTER_X);
    }
    else if(getSystemFlag(FLAG_SPCRES)) {
      reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
      convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function log2LonI:", "cannot calculate log2 of a negative number when CPXRES is not set!", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }

  longIntegerFree(lgInt);
}



void log2Rema(void) {
  elementwiseRema(log2Real);
}



void log2Cxma(void) {
  elementwiseCxma(log2Cplx);
}



void log2ShoI(void) {
  *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = WP34S_intLog2(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)));
}



void log2Real(void) {
  real_t a, b;

  if(real34IsZero(REGISTER_REAL34_DATA(REGISTER_X))) {
    if(getSystemFlag(FLAG_SPCRES)) {
      convertRealToReal34ResultRegister(const_minusInfinity, REGISTER_X);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function log2Real:", "cannot calculate log2(0)", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }

  else if(real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X))) {
    if(!getSystemFlag(FLAG_SPCRES)) {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function log2Real:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of log2 when flag D is not set", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }
    else if(getFlag(FLAG_CPXRES)) {
      if(real34IsPositive(REGISTER_REAL34_DATA(REGISTER_X))) {
        convertRealToReal34ResultRegister(const_plusInfinity, REGISTER_X);
      }
      else {
        reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
        realDivide(const_pi, const_ln2, &a, &ctxtReal39);
        convertComplexToResultRegister(const_plusInfinity, &a, REGISTER_X);
      }
    }
    else {
      convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
    }
  }

  else {
    real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &a);
    if(real34IsPositive(REGISTER_REAL34_DATA(REGISTER_X))) {
      WP34S_Ln(&a, &a, &ctxtReal39);
      realDivide(&a, const_ln2, &a, &ctxtReal39);
      convertRealToReal34ResultRegister(&a, REGISTER_X);
     }
    else if(getFlag(FLAG_CPXRES)) {
      realSetPositiveSign(&a);
      WP34S_Ln(&a, &a, &ctxtReal39);
      realDivide(&a, const_ln2, &a, &ctxtReal39);
      reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
      realDivide(const_pi, const_ln2, &b, &ctxtReal39);
      convertComplexToResultRegister(&a, &b, REGISTER_X);
    }
    else if(getSystemFlag(FLAG_SPCRES)) {
      convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function log2Real:", "cannot calculate log2 of a negative number when CPXRES is not set!", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }
  setRegisterAngularMode(REGISTER_X, amNone);
}



void log2Cplx(void) {
  if(real34IsZero(REGISTER_REAL34_DATA(REGISTER_X)) && real34IsZero(REGISTER_IMAG34_DATA(REGISTER_X))) {
    if(getSystemFlag(FLAG_SPCRES)) {
      convertRealToReal34ResultRegister(const_minusInfinity, REGISTER_X);
      real34Zero(REGISTER_IMAG34_DATA(REGISTER_X));
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function log2Cplx:", "cannot calculate log2(0)", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }
  else {
    real_t a, b;

    real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &a);
    real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &b);

    realRectangularToPolar(&a, &b, &a, &b, &ctxtReal39);
    WP34S_Ln(&a, &a, &ctxtReal39);
    realDivide(&a, const_ln2, &a, &ctxtReal39);
    reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
    realDivide(&b, const_ln2, &b, &ctxtReal39);
    convertComplexToResultRegister(&a, &b, REGISTER_X);
  }
}
