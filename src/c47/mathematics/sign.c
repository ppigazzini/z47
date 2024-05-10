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
 * \file sign.c
 ***********************************************/

#include "mathematics/sign.h"

#include "debug.h"
#include "error.h"
#include "integers.h"
#include "items.h"
#include "mathematics/matrix.h"
#include "mathematics/unitVector.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"



TO_QSPI void (* const sign[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2         3               4          5          6          7          8           9             10
//          Long integer Real34    Complex34       Time       Date       String     Real34 mat Complex34 m Short integer Config data
            signLonI,    signReal, unitVectorCplx, signError, signError, signError, signRema,  signError,  signShoI,     signError
};



/********************************************//**
 * \brief Data type error in sign
 *
 * \param void
 * \return void
 ***********************************************/
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  void signError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate the sign of %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnSign:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and sign(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnSign(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  sign[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}



void signLonI(void) {
  longInteger_t lgInt;

  longIntegerInit(lgInt);

  switch(getRegisterLongIntegerSign(REGISTER_X)) {
    case LI_POSITIVE: {
      intToLongInteger(1, lgInt);
      break;
    }

    case LI_NEGATIVE: {
      intToLongInteger(-1, lgInt);
      break;
    }

    default: {
    }
  }

  convertLongIntegerToLongIntegerRegister(lgInt, REGISTER_X);
  longIntegerFree(lgInt);
}



void signRema(void) {
  elementwiseRema(signReal);
}



void signShoI(void) {
  longInteger_t lgInt;

  longIntegerInit(lgInt);

  switch(WP34S_intSign(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)))) {
    case -1: {
      uIntToLongInteger(1, lgInt);
      longIntegerSetNegativeSign(lgInt);
      break;
    }

    case 0: {
      uIntToLongInteger(0, lgInt);
      break;
    }

    case 1: {
      uIntToLongInteger(1, lgInt);
      break;
    }

    default: {
      uIntToLongInteger(0, lgInt);
      sprintf(errorMessage, "In function signShoI: %" PRIu64 " is an unexpected value returned by WP34S_intSign!", WP34S_intSign(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X))));
      displayBugScreen(errorMessage);
    }
  }

  convertLongIntegerToLongIntegerRegister(lgInt, REGISTER_X);

  longIntegerFree(lgInt);
}



void signReal(void) {
  longInteger_t lgInt;

  if(real34IsNaN(REGISTER_REAL34_DATA(REGISTER_X))) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function signReal:", "cannot use NaN as X input of SIGN", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  longIntegerInit(lgInt);
  if(!real34IsZero(REGISTER_REAL34_DATA(REGISTER_X))) {
    if(real34IsNegative(REGISTER_REAL34_DATA(REGISTER_X))) {
      intToLongInteger(-1, lgInt);
    }
    else {
      intToLongInteger(1, lgInt);
    }
  }
  else {
    intToLongInteger(0, lgInt);
  }

  convertLongIntegerToLongIntegerRegister(lgInt, REGISTER_X);
  longIntegerFree(lgInt);
}
