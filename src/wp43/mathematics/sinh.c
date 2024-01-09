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
 * \file sinh.c
 ***********************************************/

#include "mathematics/sinh.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "fonts.h"
#include "items.h"
#include "mathematics/matrix.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "wp43.h"



static void sinhReal(void) {
  real_t x;

  if (!getRegisterAsReal(REGISTER_X, &x))
    return;
  if(realIsInfinite(&x) && !getSystemFlag(FLAG_SPCRES)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function sinhReal:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of sinh when flag D is not set", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  WP34S_SinhCosh(&x, &x, NULL, &ctxtReal39);
  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
  convertRealToReal34ResultRegister(&x, REGISTER_X);
}



static void sinhCplx(void) {
  // sinh(a + i b) = sinh(a) cos(b) + i cosh(a) sin(b)
  real_t a, b, sinha, cosha, sinb, cosb;

  if (!getRegisterAsComplex(REGISTER_X, &a, &b))
    return;

  WP34S_SinhCosh(&a, &sinha, &cosha, &ctxtReal39);
  WP34S_Cvt2RadSinCosTan(&b, amRadian, &sinb, &cosb, NULL, &ctxtReal39);

  realMultiply(&sinha, &cosb, &a, &ctxtReal39);
  realMultiply(&cosha, &sinb, &b, &ctxtReal39);

  convertComplexToResultRegister(&a, &b, REGISTER_X);
}



/********************************************//**
 * \brief regX ==> regL and sinh(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnSinh(uint16_t unusedButMandatoryParameter) {
  processRealComplexMonadicFunction(&sinhReal, &sinhCplx);
}
