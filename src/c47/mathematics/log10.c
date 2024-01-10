/* This file is part of 43S.
 *
 * 43S is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * 43S is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with 43S.  If not, see <http://www.gnu.org/licenses/>.
 */

/********************************************//**
 * \file log10.c
 ***********************************************/

#include "mathematics/log10.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "fonts.h"
#include "integers.h"
#include "items.h"
#include "mathematics/matrix.h"
#include "mathematics/toPolar.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"



TO_QSPI void (* const logBase10[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2          3          4           5           6           7          8           9             10
//          Long integer Real34     complex34  Time        Date        String      Real34 mat Complex34 m Short integer Config data
            log10LonI,   log10Real, log10Cplx, log10Error, log10Error, log10Error, log10Rema, log10Cxma,  log10ShoI,    log10Error
};



/********************************************//**
 * \brief Data type error in log10
 *
 * \param void
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void log10Error(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate log10 for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnLog10:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and log10(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnLog10(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  logBase10[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}



/**********************************************************************
 * In all the functions below:
 * if X is a number then X = a + ib
 * The variables a and b are used for intermediate calculations
 ***********************************************************************/

void log10LonI(void) {
  longInteger_t lgInt;

  convertLongIntegerRegisterToLongInteger(REGISTER_X, lgInt);

  if(longIntegerIsZero(lgInt)) {
    if(getSystemFlag(FLAG_SPCRES)) {
      reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(const_minusInfinity, REGISTER_X);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function log10LonI:", "cannot calculate log10(0)", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }
  else {
    real_t x, y;

    convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);

    if(longIntegerIsPositive(lgInt)) {
      WP34S_Ln(&x, &x, &ctxtReal39);
      realDivide(&x, const_ln10, &x, &ctxtReal39);
      reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(&x, REGISTER_X);
     }
    else if(getFlag(FLAG_CPXRES)) {
      realSetPositiveSign(&x);
      WP34S_Ln(&x, &x, &ctxtReal39);
      realDivide(&x, const_ln10, &x, &ctxtReal39);
      reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
      realDivide(const_pi, const_ln10, &y, &ctxtReal39);
      convertComplexToResultRegister(&x, &y, REGISTER_X);
    }
    else if(getSystemFlag(FLAG_SPCRES)) {
      reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function log10LonI:", "cannot calculate log10 of a negative number when CPXRES is not set!", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }

  longIntegerFree(lgInt);
}



void log10Rema(void) {
  elementwiseRema(log10Real);
}



void log10Cxma(void) {
  elementwiseCxma(log10Cplx);
}



void log10ShoI(void) {
  *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = WP34S_intLog10(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)));
}



void log10Real(void) {
  real_t x, y;

  if(real34IsZero(REGISTER_REAL34_DATA(REGISTER_X))) {
    if(getSystemFlag(FLAG_SPCRES)) {
      convertRealToReal34ResultRegister(const_minusInfinity, REGISTER_X);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function log10Real:", "cannot calculate log10(0)", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }

  else if(real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X))) {
    if(!getSystemFlag(FLAG_SPCRES)) {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function log10Real:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of log when flag D is not set", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }
    else if(getFlag(FLAG_CPXRES)) {
      if(real34IsPositive(REGISTER_REAL34_DATA(REGISTER_X))) {
        convertRealToReal34ResultRegister(const_plusInfinity, REGISTER_X);
      }
      else {
        reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
        realDivide(const_pi, const_ln10, &x, &ctxtReal39);
        convertComplexToResultRegister(const_plusInfinity, &x, REGISTER_X);
      }
    }
    else {
      convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
    }
  }

  else {
    real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
    if(real34IsPositive(REGISTER_REAL34_DATA(REGISTER_X))) {
      WP34S_Ln(&x, &x, &ctxtReal39);
      realDivide(&x, const_ln10, &x, &ctxtReal39);
      convertRealToReal34ResultRegister(&x, REGISTER_X);
     }
    else if(getFlag(FLAG_CPXRES)) {
      realSetPositiveSign(&x);
      WP34S_Ln(&x, &x, &ctxtReal39);
      realDivide(&x, const_ln10, &x, &ctxtReal39);
      reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
      realDivide(const_pi, const_ln10, &y, &ctxtReal39);
      convertComplexToResultRegister(&x, &y, REGISTER_X);
    }
    else if(getSystemFlag(FLAG_SPCRES)) {
      convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function log10Real:", "cannot calculate log10 of a negative number when CPXRES is not set!", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }
  setRegisterAngularMode(REGISTER_X, amNone);
}



void log10Cplx(void) {
  if(real34IsZero(REGISTER_REAL34_DATA(REGISTER_X)) && real34IsZero(REGISTER_IMAG34_DATA(REGISTER_X))) {
    if(getSystemFlag(FLAG_SPCRES)) {
      convertRealToReal34ResultRegister(const_minusInfinity, REGISTER_X);
      real34Zero(REGISTER_IMAG34_DATA(REGISTER_X));
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function log10Cplx:", "cannot calculate log10(0)", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }
  else {
    real_t a, b;

    real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &a);
    real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &b);

    realRectangularToPolar(&a, &b, &a, &b, &ctxtReal39);
    WP34S_Ln(&a, &a, &ctxtReal39);
    realDivide(&a, const_ln10, &a, &ctxtReal39);
    reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
    realDivide(&b, const_ln10, &b, &ctxtReal39);
    convertComplexToResultRegister(&a, &b, REGISTER_X);
  }
}
