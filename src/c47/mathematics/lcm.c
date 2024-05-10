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
 * \file lcm.c
 ***********************************************/

#include "mathematics/lcm.h"

#include "debug.h"
#include "error.h"
#include "integers.h"
#include "items.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "stack.h"

#include "c47.h"



TO_QSPI void (* const lcm[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX |    regY ==>   1            2         3         4         5         6         7          8           9             10
//      V               Long integer Real34    Complex34 Time      Date      String    Real34 mat Complex34 m Short integer Config data
/*  1 Long integer  */ {lcmLonILonI, lcmError, lcmError, lcmError, lcmError, lcmError, lcmError,  lcmError,   lcmShoILonI,  lcmError},
/*  2 Real34        */ {lcmError,    lcmError, lcmError, lcmError, lcmError, lcmError, lcmError,  lcmError,   lcmError,     lcmError},
/*  3 Complex34     */ {lcmError,    lcmError, lcmError, lcmError, lcmError, lcmError, lcmError,  lcmError,   lcmError,     lcmError},
/*  4 Time          */ {lcmError,    lcmError, lcmError, lcmError, lcmError, lcmError, lcmError,  lcmError,   lcmError,     lcmError},
/*  5 Date          */ {lcmError,    lcmError, lcmError, lcmError, lcmError, lcmError, lcmError,  lcmError,   lcmError,     lcmError},
/*  6 String        */ {lcmError,    lcmError, lcmError, lcmError, lcmError, lcmError, lcmError,  lcmError,   lcmError,     lcmError},
/*  7 Real34 mat    */ {lcmError,    lcmError, lcmError, lcmError, lcmError, lcmError, lcmError,  lcmError,   lcmError,     lcmError},
/*  8 Complex34 mat */ {lcmError,    lcmError, lcmError, lcmError, lcmError, lcmError, lcmError,  lcmError,   lcmError,     lcmError},
/*  9 Short integer */ {lcmLonIShoI, lcmError, lcmError, lcmError, lcmError, lcmError, lcmError,  lcmError,   lcmShoIShoI,  lcmError},
/* 10 Config data   */ {lcmError,    lcmError, lcmError, lcmError, lcmError, lcmError, lcmError,  lcmError,   lcmError,     lcmError}
};



/********************************************//**
 * \brief Data type error in lcm
 *
 * \param void
 * \return void
 ***********************************************/
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  void lcmError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate lcm (%s, %s)", getRegisterDataTypeName(REGISTER_Y, true, false), getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnLcm:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and LCM(regY, regX) ==> regX
 * Drops Y, enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnLcm(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }
  lcm[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)]();
  fnDropY(NOPARAM);
}



void lcmLonILonI(void) {
  longInteger_t liX, liY;

  convertLongIntegerRegisterToLongInteger(REGISTER_Y, liY);
  longIntegerSetPositiveSign(liY);
  convertLongIntegerRegisterToLongInteger(REGISTER_X, liX);
  longIntegerSetPositiveSign(liX);

  longIntegerLcm(liY, liX, liX);

  convertLongIntegerToLongIntegerRegister(liX, REGISTER_X);

  longIntegerFree(liX);
  longIntegerFree(liY);
}



void lcmLonIShoI(void) {
  longInteger_t liX, liY;

  convertLongIntegerRegisterToLongInteger(REGISTER_Y, liY);
  longIntegerSetPositiveSign(liY);
  convertShortIntegerRegisterToLongInteger(REGISTER_X, liX);
  longIntegerSetPositiveSign(liX);

  longIntegerLcm(liY, liX, liX);

  convertLongIntegerToLongIntegerRegister(liX, REGISTER_X);

  longIntegerFree(liX);
  longIntegerFree(liY);
}



void lcmShoILonI(void) {
  longInteger_t liX, liY;

  convertLongIntegerRegisterToLongInteger(REGISTER_X, liX);
  longIntegerSetPositiveSign(liX);
  convertShortIntegerRegisterToLongInteger(REGISTER_Y, liY);
  longIntegerSetPositiveSign(liY);

  longIntegerLcm(liY, liX, liX);

  convertLongIntegerToLongIntegerRegister(liX, REGISTER_X);

  longIntegerFree(liX);
  longIntegerFree(liY);
}



void lcmShoIShoI(void) {
  *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = WP34S_intLCM(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_Y)), *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)));
}
