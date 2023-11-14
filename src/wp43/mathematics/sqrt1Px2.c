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
 * \file sqrt1Px2.c
 ***********************************************/

#include "mathematics/sqrt1Px2.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "fonts.h"
#include "items.h"
#include "mathematics/matrix.h"
#include "mathematics/squareRoot.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "wp43.h"



TO_QSPI void (* const Sqrt1Px2[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1             2             3             4              5              6              7             8             9             10
//          Long integer  Real34        Complex34     Time           Date           String         Real34 mat    Complex34 m   Short integer Config data
            sqrt1Px2LonI, sqrt1Px2Real, sqrt1Px2Cplx, sqrt1Px2Error, sqrt1Px2Error, sqrt1Px2Error, sqrt1Px2Rema, sqrt1Px2Cxma, sqrt1Px2ShoI, sqrt1Px2Error
};



/********************************************//**
 * \brief Data type error in sqrt1Px2
 *
 * \param void
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void sqrt1Px2Error(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate sqrt(1+x^2) for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function sqrt1Px2:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and sqrt1Px2(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnSqrt1Px2(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  Sqrt1Px2[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}






void sqrt1Px2Complex(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext) {
  real_t x, y;

  if(realIsZero(imag)) {
    if(realIsInfinite(real)) {
      realCopy(const_plusInfinity, resReal);
      realZero(resImag);
      return;
    }
    realFMA(real, real, const_1, resReal, realContext);
    realSquareRoot(resReal, resReal, realContext);
    realZero(resImag);
    return;
  }

  if(realIsSpecial(real) || realIsSpecial(imag)) {
    realCopy(const_NaN, resReal);
    realCopy(const_NaN, resImag);
    return;
  }

  // sqrt(1 + a^2 - b^2 + 2 a b i)
  realFMA(imag, imag, const__1, &x, realContext);
  realChangeSign(&x);
  realFMA(real, real, &x, &x, realContext);
  realMultiply(real, imag, &y, realContext);
  realAdd(&y, &y, &y, realContext);
  sqrtComplex(&x, &y, resReal, resImag, realContext);
}



void sqrt1Px2LonI(void) {
  longInteger_t value;
  real_t a;

  convertLongIntegerRegisterToLongInteger(REGISTER_X, value);

  if(longIntegerIsZero(value)) {
    uIntToLongInteger(1, value);
    convertLongIntegerToLongIntegerRegister(value, REGISTER_X);
  }
  else {
    convertLongIntegerRegisterToReal(REGISTER_X, &a, &ctxtReal39);
    realFMA(&a, &a, const_1, &a, &ctxtReal39);
    realSquareRoot(&a, &a, &ctxtReal39);
    reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
    convertRealToReal34ResultRegister(&a, REGISTER_X);
  }

  longIntegerFree(value);
}



void sqrt1Px2Rema(void) {
  elementwiseRema(sqrt1Px2Real);
}



void sqrt1Px2Cxma(void) {
  elementwiseCxma(sqrt1Px2Cplx);
}



void sqrt1Px2ShoI(void) {
  real_t x;

  convertShortIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
  realFMA(&x, &x, const_1, &x, &ctxtReal39);
  realSquareRoot(&x, &x, &ctxtReal39);
  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
  convertRealToReal34ResultRegister(&x, REGISTER_X);
}



void sqrt1Px2Real(void) {
  if(real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X)) && !getSystemFlag(FLAG_SPCRES)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function sqrt1Px2Real:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of exp when flag D is not set", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  real_t x;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);

  if(realIsInfinite(&x)) {
    realCopy(const_plusInfinity, &x);
  }
  else if(realIsSpecial(&x)) {
    realCopy(const_NaN, &x);
  }
  else {
    realFMA(&x, &x, const_1, &x, &ctxtReal51);
    realSquareRoot(&x, &x, &ctxtReal51);
  }
  convertRealToReal34ResultRegister(&x, REGISTER_X);
  setRegisterAngularMode(REGISTER_X, amNone);
}



void sqrt1Px2Cplx(void) {
  real_t zReal, zImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &zReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &zImag);

  sqrt1Px2Complex(&zReal, &zImag, &zReal, &zImag, &ctxtReal75);

  convertRealToReal34ResultRegister(&zReal, REGISTER_X);
  convertRealToImag34ResultRegister(&zImag, REGISTER_X);
}
