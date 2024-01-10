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
 * \file dblDivision.c
 ***********************************************/

#include "mathematics/dblDivision.h"

#include "debug.h"
#include "error.h"
#include "flags.h"
#include "fonts.h"
#include "integers.h"
#include "items.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "stack.h"

#include "c47.h"


void dblDivide(bool_t remainder_mode) {
  longInteger_t dividend, x, y, z, wd;
  int32_t base;
  const uint8_t sim = shortIntegerMode;

  if(getRegisterDataType(REGISTER_X) != dtShortInteger) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_T);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "the input type %s is not allowed for DBL" STD_CROSS "!", getDataTypeName(getRegisterDataType(REGISTER_X), false, false));
      moreInfoOnError("In function fnDblDivide:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }
  if(getRegisterDataType(REGISTER_Y) != dtShortInteger) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_T);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "the input type %s is not allowed for DBL" STD_CROSS "!", getDataTypeName(getRegisterDataType(REGISTER_Y), false, false));
      moreInfoOnError("In function fnDblDivide:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }
  if(getRegisterDataType(REGISTER_Z) != dtShortInteger) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_T);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "the input type %s is not allowed for DBL" STD_CROSS "!", getDataTypeName(getRegisterDataType(REGISTER_Z), false, false));
      moreInfoOnError("In function fnDblDivide:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  convertShortIntegerRegisterToLongInteger(REGISTER_X, x);
  if(longIntegerIsZero(x)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_T);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function fnDblDivide:", "cannot divide a short integer by 0", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    longIntegerFree(x);
    return;
  }

  longIntegerInit(wd);
  longInteger2Pow(shortIntegerWordSize, wd);

  shortIntegerMode = SIM_UNSIGN;
  convertShortIntegerRegisterToLongInteger(REGISTER_Z, z);
  convertShortIntegerRegisterToLongInteger(REGISTER_Y, y);
  shortIntegerMode = sim;
  base = getRegisterShortIntegerBase(REGISTER_Y);

  longIntegerInit(dividend);
  longIntegerMultiply(y, wd, dividend);
  longIntegerAdd(dividend, z, dividend);

  if(sim != SIM_UNSIGN) {
    longIntegerSetZero(wd);
    longInteger2Pow(shortIntegerWordSize * 2 - 1, wd);
    if(longIntegerCompare(dividend, wd) >= 0) { // negative
      if(sim == SIM_SIGNMT) {
        longIntegerSubtract(dividend, wd, dividend);
        longIntegerSetNegativeSign(dividend);
      }
      else {
        longIntegerSetZero(wd);
        longInteger2Pow(shortIntegerWordSize * 2, wd);
        if(sim == SIM_1COMPL) {
          longIntegerSubtractUInt(wd, 1, wd);
        }
        longIntegerSubtract(wd, dividend, dividend);
        longIntegerSetNegativeSign(dividend);
      }
    }
    longIntegerSetZero(wd);
    longInteger2Pow(shortIntegerWordSize - 1, wd);
  }

  longIntegerDivideQuotientRemainder(dividend, x, z, y);

  if(remainder_mode) {
    if(!saveLastX()) {
      return;
    }
    convertLongIntegerToShortIntegerRegister(y, base, REGISTER_X);
  }
  else {
    longIntegerSetPositiveSign(wd);
    if((longIntegerCompare(z, wd) >= 0)) { // check for positive quotient overflow
      goto quotient_overflow;
    }
    if(sim != SIM_UNSIGN) {
      longIntegerSetNegativeSign(wd);
      if((longIntegerCompare(z, wd) < 0)) { // check for negative quotient overflow
        goto quotient_overflow;
      }
      else if((sim != SIM_2COMPL) && (longIntegerCompare(z, wd) == 0)) { // check for negative quotient overflow
        goto quotient_overflow;
      }
    }

    if(!saveLastX()) {
      return;
    }
    convertLongIntegerToShortIntegerRegister(z, base, REGISTER_X);

    if(longIntegerIsZero(y)) {
      clearSystemFlag(FLAG_CARRY);
    }
    else {
      setSystemFlag(FLAG_CARRY);
    }

    clearSystemFlag(FLAG_OVERFLOW);
  }

  fnDropY(NOPARAM);
  if(lastErrorCode == ERROR_NONE) {
    fnDropY(NOPARAM);
  }
  goto cleanup;

quotient_overflow:
  displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_T);
  #if(EXTRA_INFO_ON_CALC_ERROR == 1)
    moreInfoOnError("In function fnDblDivide:", "quotient overflow", NULL, NULL);
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

cleanup:
  longIntegerFree(dividend);

  longIntegerFree(x);
  longIntegerFree(y);
  longIntegerFree(z);
  longIntegerFree(wd);
}

void fnDblDivide(uint16_t unusedButMandatoryParameter) {
  dblDivide(false);
}

void fnDblDivideRemainder(uint16_t unusedButMandatoryParameter) {
  dblDivide(true);
}
