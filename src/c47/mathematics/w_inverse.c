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
 * \file w_inverse.c
 ***********************************************/

#include "mathematics/w_inverse.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "fonts.h"
#include "mathematics/matrix.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"

static void wInvReal(void) {
  real_t x, res;

  if(!getRegisterAsReal(REGISTER_X, &x))
    return;

  WP34S_InverseW(&x, &res, &ctxtReal39);
  convertRealToResultRegister(&res, REGISTER_X, amNone);
}

static void wInvCplx(void) {
  real_t xr, xi, resr, resi;

  if(!getRegisterAsComplex(REGISTER_X, &xr, &xi))
    return;
  WP34S_InverseComplexW(&xr, &xi, &resr, &resi, &ctxtReal39);
  convertComplexToResultRegister(&resr, &resi, REGISTER_X);
}

/********************************************//**
 * \brief regX ==> regL and W^(-1)(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnWinverse(uint16_t unusedButMandatoryParameter) {
  processRealComplexMonadicFunction(&wInvReal, &wInvCplx);

}
