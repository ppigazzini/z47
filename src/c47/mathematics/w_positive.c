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
 * \file w_positive.c
 ***********************************************/

#include "mathematics/w_positive.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/matrix.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"

static void wPosReal(void) {
  real_t x, res, resi;

  if(!getRegisterAsReal(REGISTER_X, &x))
    return;

  if(realCompareGreaterEqual(&x, const__1oneE)) {
    WP34S_LambertW(&x, &res, false, &ctxtReal39);
    convertRealToResultRegister(&res, REGISTER_X, amNone);
  }
  else if(getSystemFlag(FLAG_CPXRES)) {
    WP34S_ComplexLambertW(&x, const_0, &res, &resi, &ctxtReal39);
    convertComplexToResultRegister(&res, &resi, REGISTER_X);
  }
  else {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function wPosReal:", "X < -e^(-1)", "and CPXRES is not set!", NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}

static void wPosCplx(void) {
  real_t xr, xi, resr, resi;

  if(!getRegisterAsComplex(REGISTER_X, &xr, &xi))
    return;
  WP34S_ComplexLambertW(&xr, &xi, &resr, &resi, &ctxtReal39);
  convertComplexToResultRegister(&resr, &resi, REGISTER_X);
}

/********************************************//**
 * \brief regX ==> regL and W(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnWpositive(uint16_t unusedButMandatoryParameter) {
  processRealComplexMonadicFunction(&wPosReal, &wPosCplx);
}
