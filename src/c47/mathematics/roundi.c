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
 * \file roundi.c
 ***********************************************/

#include "mathematics/roundi.h"

#include "constantPointers.h"
#include "comparisonReals.h"
#include "debug.h"
#include "error.h"
#include "items.h"
#include "mathematics/matrix.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"


static void roundiNoOp (void);
static void roundiRema (void);
static void roundiReal (void);


TO_QSPI void (* const Roundi[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2           3            4            5            6            7           8            9             10
//          Long integer Real34      Complex34    Time         Date         String       Real34 mat  Complex34 m  Short integer Config data
            roundiNoOp,  roundiReal, roundiError, roundiError, roundiError, roundiError, roundiRema, roundiError, roundiNoOp,   roundiError
};



/********************************************//**
 * \brief Data type error in roundi
 *
 * \param void
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void roundiError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate ROUNDI for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function roundiError:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and roundi(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnRoundi(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  Roundi[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
}



static void roundiNoOp(void) {
  // Nothing to do
}



static void roundiRema(void) {
  elementwiseRema(roundiReal);
}



static void roundiReal(void) {
  if(real34IsNaN(REGISTER_REAL34_DATA(REGISTER_X))) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function roundiReal:", "cannot use NaN as X input of ROUNDI", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  if(real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X))) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function roundiReal:", "cannot use ±∞ as an input of ROUNDI", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  int16_t exponent = real34GetExponent(REGISTER_REAL34_DATA(REGISTER_X));
  if(exponent > (int16_t)(0.301029995663 * MAX_LONG_INTEGER_SIZE_IN_BITS)) {
    displayCalcErrorMessage(!real34CompareLessThan(REGISTER_REAL34_DATA(REGISTER_X), const34_0) ? ERROR_OVERFLOW_PLUS_INF : ERROR_OVERFLOW_MINUS_INF, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "Converting a real exponent of %" PRId16 " would result in a value exceeding %" PRId16 " bits!", exponent, (uint16_t)MAX_LONG_INTEGER_SIZE_IN_BITS);
      moreInfoOnError("In function roundiReal:", errorMessage, "", "");
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }

  convertReal34ToLongIntegerRegister(REGISTER_REAL34_DATA(REGISTER_X), REGISTER_X, DEC_ROUND_HALF_UP);
}
