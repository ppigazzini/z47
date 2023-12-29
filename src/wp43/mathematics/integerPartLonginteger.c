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
 * \file integerPartLonginteger.c
 ***********************************************/

#include "mathematics/integerPartLonginteger.h"

#include "constantPointers.h"
#include "comparisonReals.h"
#include "debug.h"
#include "display.h"
#include "error.h"
#include "items.h"
#include "mathematics/matrix.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "wp43.h"



TO_QSPI void (* const lint[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2       3         4        5        6        7          8           9             10
//          Long integer Real34  complex34 Time     Date     String   Real34 mat Complex34 m Short integer Config data
            lintLonI,      lintReal, lintError,  lintError, lintError, lintError, lintError, lintError,    lintShoI,       lintError
};



/********************************************//**
 * \brief Data type error in LINT
 *
 * \param void
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void lintError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate LINT for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnLint:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and LINT(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnLint(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }
  lint[getRegisterDataType(REGISTER_X)]();
}



void lintLonI(void) {
}



void lintShoI(void) {
  convertShortIntegerRegisterToLongIntegerRegister(REGISTER_X, REGISTER_X);
  lastIntegerBase = 0;
}



void lintReal(void) {
  int16_t exponent = real34GetExponent(REGISTER_REAL34_DATA(REGISTER_X));
  if(exponent <= (int16_t)(0.301029995663 * MAX_LONG_INTEGER_SIZE_IN_BITS)) {
    convertReal34ToLongIntegerRegister(REGISTER_REAL34_DATA(REGISTER_X), REGISTER_X, DEC_ROUND_DOWN);
  }
  else {

    displayCalcErrorMessage(!real34CompareLessThan(REGISTER_REAL34_DATA(REGISTER_X), const34_0) ? ERROR_OVERFLOW_PLUS_INF : ERROR_OVERFLOW_MINUS_INF, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "Converting a real exponent of %" PRId16 " would result in a value exceeding %" PRId16 " bits!", exponent, (uint16_t)MAX_LONG_INTEGER_SIZE_IN_BITS);
      moreInfoOnError("In function longIntegerAdd:", errorMessage, "", "");
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}
