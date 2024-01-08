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
 * \file arccosh.c
 ***********************************************/

#include "mathematics/arccosh.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "items.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/matrix.h"
#include "mathematics/toRect.h"
#include "mathematics/toPolar.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "wp43.h"



TO_QSPI void (* const arccosh[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2            3            4             5             6             7            8            9             10
//          Long integer Real34       Complex34    Time          Date          String        Real34 mat   Complex34 m  Short integer Config data
            arccoshLonI, arccoshReal, arccoshCplx, arccoshError, arccoshError, arccoshError, arccoshRema, arccoshCxma, arccoshError, arccoshError
};



/********************************************//**
 * \brief Data type error in arccosh
 *
 * \param void
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void arccoshError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate arccosh for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnArccos:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and arccosh(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnArccosh(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  arccosh[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}



void arccoshLonI(void) {
  real_t x;

  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
  if(realCompareLessThan(&x, const_1)) {
    if(getFlag(FLAG_CPXRES)) {
      reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(&x, REGISTER_X);
      real34Zero(REGISTER_IMAG34_DATA(REGISTER_X));
      arccoshCplx();
    }
    else if(getSystemFlag(FLAG_SPCRES)) {
      reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function arccoshLonI:", "X < 1", "and CPXRES is not set!", NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
    return;
  }

  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);

  realArcosh(&x, &x, &ctxtReal39);

  convertRealToReal34ResultRegister(&x, REGISTER_X);
}



void arccoshRema(void) {
  elementwiseRema(arccoshReal);
}



void arccoshCxma(void) {
  elementwiseCxma(arccoshCplx);
}



void arccoshReal(void) {
  real_t x;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);

  if(realCompareLessThan(&x, const_1)) {
    if(getFlag(FLAG_CPXRES)) {
      reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(&x, REGISTER_X);
      real34Zero(REGISTER_IMAG34_DATA(REGISTER_X));
      arccoshCplx();
      setRegisterAngularMode(REGISTER_X, amNone);
    }
    else if(getSystemFlag(FLAG_SPCRES)) {
      convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function arccoshReal:", "X < 1", "and CPXRES is not set!", NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
    return;
  }

  realArcosh(&x, &x, &ctxtReal75);

  convertRealToReal34ResultRegister(&x, REGISTER_X);
  setRegisterAngularMode(REGISTER_X, amNone);
}



void arccoshCplx(void) {
  real_t a, b, real, imag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &a);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &b);

  // arccosh(z) = ln(z + sqrt(z² - 1))
  // calculate z²   real part
  realMultiply(&b, &b, &real, &ctxtReal39);
  realChangeSign(&real);
  realFMA(&a, &a, &real, &real, &ctxtReal39);

  // calculate z²   imaginary part
  realMultiply(&a, &b, &imag, &ctxtReal39);
  realMultiply(&imag, const_2, &imag, &ctxtReal39);

  // calculate z² - 1
  realSubtract(&real, const_1, &real, &ctxtReal39);

  // calculate sqrt(z² - 1)
  realRectangularToPolar(&real, &imag, &real, &imag, &ctxtReal39);
  realSquareRoot(&real, &real, &ctxtReal39);
  realMultiply(&imag, const_1on2, &imag, &ctxtReal39);
  realPolarToRectangular(&real, &imag, &real, &imag, &ctxtReal39);

  // calculate z + sqrt(z² - 1)
  realAdd(&a, &real, &real, &ctxtReal39);
  realAdd(&b, &imag, &imag, &ctxtReal39);

  // calculate ln(z + sqtr(z² - 1))
  realRectangularToPolar(&real, &imag, &a, &b, &ctxtReal39);
  WP34S_Ln(&a, &a, &ctxtReal39);

  convertComplexToResultRegister(&a, &b, REGISTER_X);
}



void realArcosh(const real_t *x, real_t *res, realContext_t *realContext) {
  real_t xSquared;

  // arccosh(x) = ln(x + sqrt(x² - 1))
  realMultiply(x, x, &xSquared, realContext);
  realSubtract(&xSquared, const_1, &xSquared, realContext);
  realSquareRoot(&xSquared, &xSquared, realContext);
  realAdd(&xSquared, x, res, realContext);
  WP34S_Ln(res, res, realContext);
}
