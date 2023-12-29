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
 * \file floor.c
 ***********************************************/

#include "mathematics/floor.h"

#include "debug.h"
#include "error.h"
#include "fonts.h"
#include "items.h"
#include "mathematics/matrix.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "wp43.h"

static void floorNoOp(void);

TO_QSPI void (* const Floor[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2          3           4           5           6           7          8           9             10
//          Long integer Real34     Complex34   Time        Date        String      Real34 mat Complex34 m Short integer Config data
            floorNoOp,   floorReal, floorError, floorError, floorError, floorError, floorRema, floorError, floorNoOp,    floorError
};



/********************************************//**
 * \brief Data type error in floor
 *
 * \param void
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void floorError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate floor for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnFloor:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and floor(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnFloor(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  Floor[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
}



static void floorNoOp(void) {
}



void floorRema(void) {
  elementwiseRema(floorReal);
}



void floorReal(void) {
  if(real34IsNaN(REGISTER_REAL34_DATA(REGISTER_X))) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function floorReal:", "cannot use NaN as X input of floor", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  if(real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X))) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function floorReal:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of floor", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  real34ToIntegralValue(REGISTER_REAL34_DATA(REGISTER_X), REGISTER_REAL34_DATA(REGISTER_X), DEC_ROUND_FLOOR);
  setRegisterAngularMode(REGISTER_X, amNone);  
}
