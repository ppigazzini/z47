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
 * \file square.c
 ***********************************************/

#include "mathematics/square.h"

#include "debug.h"
#include "error.h"
#include "flags.h"
#include "fonts.h"
#include "integers.h"
#include "items.h"
#include "mathematics/matrix.h"
#include "mathematics/multiplication.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"



TO_QSPI void (* const square[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2           3           4            5            6            7           8           9             10
//          Long integer Real34      complex34   Time         Date         String       Real34 mat  Complex34 m Short integer Config data
            squareLonI,  squareReal, squareCplx, squareError, squareError, squareError, squareRema, squareCxma, squareShoI,   squareError
};



/********************************************//**
 * \brief Data type error in squaring
 *
 * \param[in] unusedButMandatoryParameter
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void squareError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot square %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnSquare:", errorMessage, errorMessage + ERROR_MESSAGE_LENGTH/2, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and regX × regX ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter
 * \return void
 ***********************************************/
void fnSquare(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  square[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}



void squareLonI(void) {
  longInteger_t lgInt;

  convertLongIntegerRegisterToLongInteger(REGISTER_X, lgInt);
  longIntegerMultiply(lgInt, lgInt, lgInt);
  convertLongIntegerToLongIntegerRegister(lgInt, REGISTER_X);
  longIntegerFree(lgInt);
}



void squareRema(void) {
  elementwiseRema(squareReal);
}



void squareCxma(void) {
  elementwiseCxma(squareCplx);
}



void squareShoI(void) {
  *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = WP34S_intMultiply(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)), *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)));
}



void squareReal(void) {
  if(real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X)) && !getSystemFlag(FLAG_SPCRES)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function squareReal:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of ^2 when flag D is not set", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  real34Multiply(REGISTER_REAL34_DATA(REGISTER_X), REGISTER_REAL34_DATA(REGISTER_X), REGISTER_REAL34_DATA(REGISTER_X));
  setRegisterAngularMode(REGISTER_X, amNone);
}



void squareCplx(void) {
  real_t a, b;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &a);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &b);

  mulComplexComplex(&a, &b, &a, &b, &a, &b, &ctxtReal39);

  convertComplexToResultRegister(&a, &b, REGISTER_X);
}
