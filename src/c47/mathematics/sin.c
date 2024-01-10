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
 * \file sin.c
 ***********************************************/

#include "mathematics/sin.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "items.h"
#include "mathematics/matrix.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"



void sinComplex(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext) {
  // sin(a + ib) = sin(a)*cosh(b) + i*cos(a)*sinh(b)
  real_t sina, cosa, sinhb, coshb;

  WP34S_Cvt2RadSinCosTan(real, amRadian, &sina, &cosa, NULL, realContext);
  WP34S_SinhCosh(imag, &sinhb, &coshb, realContext);

  realMultiply(&sina, &coshb, resReal, realContext);
  realMultiply(&cosa, &sinhb, resImag, realContext);
}


static void sinReal(void) {
  real_t x;
  const real_t *r = &x;
  angularMode_t xAngularMode;

  if (!getRegisterAsRealAngle(REGISTER_X, &x, &xAngularMode))
    return;
  if (realIsSpecial(&x))
    r = const_NaN;
  else
    WP34S_Cvt2RadSinCosTan(r = &x, xAngularMode, &x, NULL, NULL, &ctxtReal75);
  convertRealToResultRegister(r, REGISTER_X, amNone);
}



static void sinCplx(void) {
  real_t zReal, zImag;

  if (!getRegisterAsComplex(REGISTER_X, &zReal, &zImag))
    return;

  sinComplex(&zReal, &zImag, &zReal, &zImag, &ctxtReal75);

  convertComplexToResultRegister(&zReal, &zImag, REGISTER_X);
}


/********************************************//**
 * \brief regX ==> regL and sin(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnSin(uint16_t unusedButMandatoryParameter) {
  processRealComplexMonadicFunction(&sinReal, &sinCplx);
}
