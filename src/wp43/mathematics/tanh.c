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
 * \file tanh.c
 ***********************************************/

#include "mathematics/tanh.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "fonts.h"
#include "items.h"
#include "mathematics/division.h"
#include "mathematics/matrix.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "wp43.h"



TO_QSPI void (* const Tanh[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2         3         4          5          6          7          8           9             10
//          Long integer Real34    complex34 Time       Date       String     Real34 mat Complex34 m Short integer Config data
            tanhLonI,    tanhReal, tanhCplx, tanhError, tanhError, tanhError, tanhRema,  tanhCxma,   tanhError,    tanhError
};



/********************************************//**
 * \brief Data type error in tanh
 *
 * \param void
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void tanhError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate Tan for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnTanh:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and tanh(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnTanh(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  Tanh[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}



void tanhLonI(void) {
  real_t x;

  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
  WP34S_Tanh(&x, &x, &ctxtReal39);

  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
  convertRealToReal34ResultRegister(&x, REGISTER_X);
}



void tanhRema(void) {
  elementwiseRema(tanhReal);
}



void tanhCxma(void) {
  elementwiseCxma(tanhCplx);
}



void tanhReal(void) {
  if(real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X)) && !getSystemFlag(FLAG_SPCRES)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function tanhReal:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of tanh when flag D is not set", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  real_t x;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
  WP34S_Tanh(&x, &x, &ctxtReal39);
  convertRealToReal34ResultRegister(&x, REGISTER_X);
  setRegisterAngularMode(REGISTER_X, amNone);
}



void tanhCplx(void) {
  real_t xReal, xImag;
  real_t rReal, rImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  TanhComplex(&xReal, &xImag, &rReal, &rImag, &ctxtReal39);

  convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
}


uint8_t TanhComplex(const real_t *xReal, const real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext) {
  // tanh(a + i b) = (tanh(a) + i tan(b)) / (1 + i tanh(a) tan(b))

  real_t sina, cosa;
  real_t denomReal, denomImag;

  if(realIsZero(xImag)) {
    WP34S_Tanh(xReal, rReal, &ctxtReal39);
    realZero(rImag);
  }
  else {
    WP34S_Tanh(xReal, rReal, &ctxtReal39);
    WP34S_Cvt2RadSinCosTan(xImag, amRadian, &sina, &cosa, rImag, &ctxtReal39);

    realCopy(const_1, &denomReal);
    realMultiply(rReal, rImag, &denomImag, &ctxtReal39);

    divComplexComplex(rReal, rImag, &denomReal, &denomImag, rReal, rImag, &ctxtReal39);
  }

  return ERROR_NONE;
}
