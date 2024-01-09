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



static void tanhReal(void) {
  real_t x;

  if (!getRegisterAsReal(REGISTER_X, &x))
    return;
  if(realIsInfinite(&x) && !getSystemFlag(FLAG_SPCRES)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function tanhReal:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of tanh when flag D is not set", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  WP34S_Tanh(&x, &x, &ctxtReal39);
  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
  convertRealToReal34ResultRegister(&x, REGISTER_X);
}



static void tanhCplx(void) {
  real_t xReal, xImag;
  real_t rReal, rImag;

  if (!getRegisterAsComplex(REGISTER_X, &xReal, &xImag))
    return;

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



/********************************************//**
 * \brief regX ==> regL and tanh(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnTanh(uint16_t unusedButMandatoryParameter) {
  processRealComplexMonadicFunction(&tanhReal, &tanhCplx);
}
