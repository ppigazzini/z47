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
 * \file dblMultiplication.c
 ***********************************************/

#include "mathematics/dblMultiplication.h"

#include "debug.h"
#include "error.h"
#include "flags.h"
#include "fonts.h"
#include "integers.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"


void fnDblMultiply(uint16_t unusedButMandatoryParameter) {
  longInteger_t y, x, ans, wd;
  int32_t base;
  const uint8_t sim = shortIntegerMode;

  if(getRegisterDataType(REGISTER_X) != dtShortInteger) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_T);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "the input type %s is not allowed for DBL" STD_CROSS "!", getDataTypeName(getRegisterDataType(REGISTER_X), false, false));
      moreInfoOnError("In function fnDblMultiply:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }
  if(getRegisterDataType(REGISTER_Y) != dtShortInteger) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_T);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "the input type %s is not allowed for DBL" STD_CROSS "!", getDataTypeName(getRegisterDataType(REGISTER_Y), false, false));
      moreInfoOnError("In function fnDblMultiply:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  if(!saveLastX()) {
    return;
  }

  longIntegerInit(wd);
  longInteger2Pow(shortIntegerWordSize, wd);

  convertShortIntegerRegisterToLongInteger(REGISTER_Y, y);
  convertShortIntegerRegisterToLongInteger(REGISTER_X, x);
  base = getRegisterShortIntegerBase(REGISTER_Y);

  longIntegerInit(ans);
  longIntegerMultiply(y, x, ans);
  if(sim == SIM_1COMPL) {
    if((*(REGISTER_SHORT_INTEGER_DATA(REGISTER_Y)) & shortIntegerSignBit) != (*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) & shortIntegerSignBit)) {
      longIntegerSubtractUInt(ans, 1u, ans);
    }
    shortIntegerMode = SIM_2COMPL;
  }
  else if(sim == SIM_SIGNMT) {
    longIntegerSetPositiveSign(ans);
    shortIntegerMode = SIM_UNSIGN;
  }

  longIntegerModulo(ans, wd, y);
  longIntegerSubtract(ans, y, x);
  longIntegerDivide(x, wd, x);

  if(sim == SIM_SIGNMT) {
    shortIntegerMode = SIM_SIGNMT;
    if((*(REGISTER_SHORT_INTEGER_DATA(REGISTER_Y)) & shortIntegerSignBit) != (*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) & shortIntegerSignBit)) {
      longIntegerSetNegativeSign(x);
    }
  }

  convertLongIntegerToShortIntegerRegister(y, base, REGISTER_Y);
  convertLongIntegerToShortIntegerRegister(x, base, REGISTER_X);

  shortIntegerMode = sim;

  longIntegerFree(x);
  longIntegerFree(y);
  longIntegerFree(ans);
  longIntegerFree(wd);

  clearSystemFlag(FLAG_OVERFLOW);
}
