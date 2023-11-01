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
 * \file cos.c
 ***********************************************/

#include "mathematics/cos.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "items.h"
#include "mathematics/matrix.h"
#include "mathematics/tan.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "wp43.h"



TO_QSPI void (* const Cos[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2        3         4         5         6         7          8           9             10
//          Long integer Real34   Complex34 Time      Date      String    Real34 mat Complex34 m Short integer Config data
            cosLonI,     cosReal, cosCplx,  cosError, cosError, cosError, cosRema,   cosCxma,    cosError,     cosError
};



/********************************************//**
 * \brief Data type error in cos
 *
 * \param void
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void cosError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate Cos for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnCos:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and cos(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnCos(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  Cos[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}



void cosComplex(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext) {
  // cos(a + i b) = cos(a)*cosh(b) - i*sin(a)*sinh(b)
  real_t sina, cosa, sinhb, coshb;

  WP34S_Cvt2RadSinCosTan(real, amRadian, &sina, &cosa, NULL, realContext);
  WP34S_SinhCosh(imag, &sinhb, &coshb, realContext);

  realMultiply(&cosa, &coshb, resReal, realContext);
  realMultiply(&sina, &sinhb, resImag, realContext);
  realChangeSign(resImag);
}



void cosLonI(void) {
  real_t x;

  longIntegerAngleReduction(REGISTER_X, currentAngularMode, &x);
  WP34S_Cvt2RadSinCosTan(&x, currentAngularMode, NULL, &x, NULL, &ctxtReal75);

  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE, amNone);
  convertRealToReal34ResultRegister(&x, REGISTER_X);
}



void cosRema(void) {
  elementwiseRema(cosReal);
}



void cosCxma(void) {
  elementwiseCxma(cosCplx);
}



void cosReal(void) {
  if(real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X))) {
    convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
  }
  else {
    real_t x;
    angularMode_t xAngularMode = determineAngleMode(getRegisterAngularMode(REGISTER_X));

    real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);

    WP34S_Cvt2RadSinCosTan(&x, xAngularMode, NULL, &x, NULL, &ctxtReal75);
    convertRealToReal34ResultRegister(&x, REGISTER_X);
  }
  setRegisterAngularMode(REGISTER_X, amNone);
}



void cosCplx(void) {
  real_t zReal, zImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &zReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &zImag);

  cosComplex(&zReal, &zImag, &zReal, &zImag, &ctxtReal75);

  convertRealToReal34ResultRegister(&zReal, REGISTER_X);
  convertRealToImag34ResultRegister(&zImag, REGISTER_X);
}
