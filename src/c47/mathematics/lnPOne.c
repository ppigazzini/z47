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
 * \file lnPOne.c
 ***********************************************/
// Coded by JM, based on ln.c

#include "mathematics/lnPOne.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "fonts.h"
#include "items.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/magnitude.h"
#include "mathematics/matrix.h"
#include "mathematics/multiplication.h"
#include "mathematics/toPolar.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"



TO_QSPI void (* const lnP1[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2         3         4          5          6          7          8          9         10
//          Long integer Real34    complex34 Time       Date       String     Real34 mat Complex34 m Short integer Config data
            lnP1LonI,    lnP1Real, lnP1Cplx, lnP1Error, lnP1Error, lnP1Error, lnP1Rema,  lnP1Cxma,  lnP1ShoI, lnP1Error
};



/********************************************//**
 * \brief Data type error in lnP1
 *
 * \param void
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void lnP1Error(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate Ln(1 + x) for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnLnP1:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and lnP1(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnLnP1(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  lnP1[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}


/**********************************************************************
 * For |z| small, we use the series expansion:
 *
 *  log(1+z) = z - z^2/2 + z^3/3 - z^4/4 + ...
 *
 * Thresholding |z| against 1e-6, means each term after the first will produce
 * approximately six more digits.
 *
 * For |z| larger, we can use the complex Ln function directly without loss.
 */
void lnP1Complex(const real_t *real, const real_t *imag, real_t *lnReal, real_t *lnImag, realContext_t *realContext) {
  real_t sum_real, sum_imag, term_real, term_imag, r, t;
  int n, i;

  complexMagnitude(real, imag, &t, realContext);
  if(realCompareAbsLessThan(&t, const_1e_6)) {
    realCopy(real, &term_real); /* Sequential terms */
    realCopy(imag, &term_imag);
    realCopy(real, &sum_real);  /* Running summation */
    realCopy(imag, &sum_imag);

    /* Calculate the number of iterations for the number of requied digits.
      * The assumption is a worst case of five digits per iteration and
      * always using an odd number of iterations.
      */
    n = (realContext->digits / 5) | 1;
    for(i = 1; i <= n; i++) {
      mulComplexComplex(&term_real, &term_imag, real, imag, &term_real, &term_imag, realContext);
      realChangeSign(&term_real);
      realChangeSign(&term_imag);
      int32ToReal(i + 1, &r);
      realDivide(&term_real, &r, &t, realContext);
      realAdd(&sum_real, &t, &sum_real, realContext);
      realDivide(&term_imag, &r, &t, realContext);
      realAdd(&sum_imag, &t, &sum_imag, realContext);
    }
    realCopy(&sum_real, lnReal);
    realCopy(&sum_imag, lnImag);
  }
  else {
    /* No numeric problems, so just do this directly */
    realAdd(real, const_1, &r, realContext);
    if(realIsZero(&r) && realIsZero(imag)) {
      realCopy(const_minusInfinity, lnReal);
      realZero(lnImag);
    }
    else {
      realRectangularToPolar(&r, imag, lnReal, lnImag, realContext);
      WP34S_Ln(lnReal, lnReal, realContext);
    }
  }
  realAdd(real, const_1, &r, realContext);
}



/**********************************************************************
 * In all the functions below:
 * if X is a number then X = a + ib
 * 1 added to X
 * The variables a and b are used for intermediate calculations
 ***********************************************************************/

void lnP1LonI(void) {
  longInteger_t lgInt;

  convertLongIntegerRegisterToLongInteger(REGISTER_X, lgInt);
  longIntegerAddUInt(lgInt, 1, lgInt);

  if(longIntegerIsZero(lgInt)) {
    if(getSystemFlag(FLAG_SPCRES)) {
      reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(const_minusInfinity, REGISTER_X);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function lnP1LonI:", "cannot calculate Ln(0) in Ln(1 + x)", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }
  else {
    real_t x;

    convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
    realAdd(&x, const_1, &x, &ctxtReal39);

    if(longIntegerIsPositive(lgInt)) {
      WP34S_Ln(&x, &x, &ctxtReal39);
      reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(&x, REGISTER_X);
     }
    else if(getFlag(FLAG_CPXRES)) {
      realSetPositiveSign(&x);
      WP34S_Ln(&x, &x, &ctxtReal39);
      reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
      convertComplexToResultRegister(&x, const_pi, REGISTER_X);
    }
    else if(getSystemFlag(FLAG_SPCRES)) {
      reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function lnP1LonI:", "cannot calculate Ln of a negative number when CPXRES is not set!", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }

  longIntegerFree(lgInt);
}



void lnP1Rema(void) {
  elementwiseRema(lnP1Real);
}



void lnP1Cxma(void) {
  elementwiseCxma(lnP1Cplx);
}



void lnP1ShoI(void) {
  real_t x;

  convertShortIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
  realAdd(&x, const_1, &x, &ctxtReal39);

  if(realIsZero(&x)) {
    if(getSystemFlag(FLAG_SPCRES)) {
      convertRealToReal34ResultRegister(const_minusInfinity, REGISTER_X);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function lnP1ShoI:", "cannot calculate Ln(0) in Ln(1 + x)", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }
  else {
    if(realIsPositive(&x)) {
      WP34S_Ln(&x, &x, &ctxtReal39);
      convertRealToReal34ResultRegister(&x, REGISTER_X);
     }
    else if(getFlag(FLAG_CPXRES)) {
      realSetPositiveSign(&x);
      WP34S_Ln(&x, &x, &ctxtReal39);
      reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
      convertComplexToResultRegister(&x, const_pi, REGISTER_X);
    }
    else if(getSystemFlag(FLAG_SPCRES)) {
      convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function lnP1ShoI:", "cannot calculate Ln of a negative number when CPXRES is not set!", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }
}



void lnP1Real(void) {
  real_t arg, r, x;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &arg);

  realAdd(&arg, const_1, &r, &ctxtReal39);
  if(realIsZero(&r)) {
    if(getSystemFlag(FLAG_SPCRES)) {
      convertRealToReal34ResultRegister(const_minusInfinity, REGISTER_X);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function lnP1Real:", "cannot calculate Ln(0) in Ln(1 + x)", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }

  else if(realIsInfinite(&r)) {
    if(!getSystemFlag(FLAG_SPCRES)) {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function lnP1Real:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of ln(x+1) when flag D is not set", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }
    else if(getFlag(FLAG_CPXRES)) {
      if(realIsPositive(&r)) {
        convertRealToReal34ResultRegister(const_plusInfinity, REGISTER_X);
      }
      else {
        reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
        convertComplexToResultRegister(const_plusInfinity, const_pi, REGISTER_X);
      }
    }
    else {
      convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
    }
  }

  else {
    real34ToReal(&r, &x);
    if(realIsPositive(&r)) {
      WP34S_Ln1P(&arg, &x, &ctxtReal39);
      convertRealToReal34ResultRegister(&x, REGISTER_X);
     }
    else if(getFlag(FLAG_CPXRES)) {
      lnP1Complex(&arg, const_0, &x, &r, &ctxtReal75);
      reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
      convertComplexToResultRegister(&x, const_pi, REGISTER_X);
    }
    else if(getSystemFlag(FLAG_SPCRES)) {
      convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function lnP1Real:", "cannot calculate Ln of a negative number when CPXRES is not set!", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }
  setRegisterAngularMode(REGISTER_X, amNone);
}



void lnP1Cplx(void) {
  real34_t r;
  int32ToReal34(1, &r);
  real34Add(REGISTER_REAL34_DATA(REGISTER_X),&r,&r);
  if(real34IsZero(&r) && real34IsZero(REGISTER_IMAG34_DATA(REGISTER_X))) {
    if(getSystemFlag(FLAG_SPCRES)) {
      convertRealToReal34ResultRegister(const_minusInfinity, REGISTER_X);
      real34Zero(REGISTER_IMAG34_DATA(REGISTER_X));
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function lnP1Cplx:", "cannot calculate Ln(0) in Ln(1 + x)", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }
  else {
    real_t xReal, xImag;

    real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
    real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

    lnP1Complex(&xReal, &xImag, &xReal, &xImag, &ctxtReal75);

    convertComplexToResultRegister(&xReal, &xImag, REGISTER_X);
  }
}
