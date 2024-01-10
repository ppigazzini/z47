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
#include "mathematics/comparisonReals.h"
#include "mathematics/matrix.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"



TO_QSPI void (* const WPositive[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2         3          4          5          6          7          8           9             10
//          Long integer Real34    Complex34  Time       Date       String     Real34 mat Complex34 m Short integer Config data
            wPosLonI,    wPosReal, wPosCplx,  wPosError, wPosError, wPosError, wPosError, wPosError,  wPosError,    wPosError
};



/********************************************//**
 * \brief Data type error in W
 *
 * \param void
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void wPosError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate Wp for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnWpositive:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and W(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnWpositive(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  WPositive[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}



void wPosLonI(void) {
  real_t x;

  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
  convertRealToReal34ResultRegister(&x, REGISTER_X);
  wPosReal();
}



void wPosReal(void) {
  real_t x, res, resi;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);

  if(getRegisterAngularMode(REGISTER_X) == amNone) {
    if(realCompareGreaterEqual(&x, const__1oneE)) {
      WP34S_LambertW(&x, &res, false, &ctxtReal39);
      convertRealToReal34ResultRegister(&res, REGISTER_X);
    }
    else if(getSystemFlag(FLAG_CPXRES)) {
      WP34S_ComplexLambertW(&x, const_0, &res, &resi, &ctxtReal39);
      reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
      convertComplexToResultRegister(&res, &resi, REGISTER_X);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function wPosReal:", "X < -e^(-1)", "and CPXRES is not set!", NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }
  else {
    wPosError();
  }
}



void wPosCplx(void) {
  real_t xr, xi, resr, resi;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xr);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xi);
  WP34S_ComplexLambertW(&xr, &xi, &resr, &resi, &ctxtReal39);
  convertComplexToResultRegister(&resr, &resi, REGISTER_X);
}
