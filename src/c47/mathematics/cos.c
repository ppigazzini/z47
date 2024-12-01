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
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"



void cosComplex(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext) {
  // cos(a + i b) = cos(a)*cosh(b) - i*sin(a)*sinh(b)
  real_t sina, cosa, sinhb, coshb;

  WP34S_Cvt2RadSinCosTan(real, amRadian, &sina, &cosa, NULL, realContext);
  WP34S_SinhCosh(imag, &sinhb, &coshb, realContext);

  realMultiply(&cosa, &coshb, resReal, realContext);
  realMultiply(&sina, &sinhb, resImag, realContext);
  realChangeSign(resImag);
}



static void cosReal(void) {
  real_t x;
  const real_t *r = &x;
  angularMode_t xAngularMode;

  if(!getRegisterAsRealAngle(REGISTER_X, &x, &xAngularMode))
    return;

  if(realIsSpecial(&x))
    r = const_NaN;
  else
    WP34S_Cvt2RadSinCosTan(r = &x, xAngularMode, NULL, &x, NULL, &ctxtReal75);
  convertRealToResultRegister(r, REGISTER_X, amNone);
}



static void cosCplx(void) {
  real_t zReal, zImag;

  if(!getRegisterAsComplex(REGISTER_X, &zReal, &zImag))
    return;

  cosComplex(&zReal, &zImag, &zReal, &zImag, &ctxtReal75);

  convertComplexToResultRegister(&zReal, &zImag, REGISTER_X);
}



/********************************************//**
 * \brief regX ==> regL and cos(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnCos(uint16_t unusedButMandatoryParameter) {
  processRealComplexMonadicFunction(&cosReal, &cosCplx);
}
