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
 * \file int.c
 ***********************************************/

#include "mathematics/int.h"

#include "debug.h"
#include "error.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "screen.h"

#include "c47.h"


void fnCheckInteger(uint16_t mode) {
  longInteger_t x, x2;

  switch(getRegisterDataType(REGISTER_X)) {
    case dtShortInteger: {
      convertShortIntegerRegisterToLongInteger(REGISTER_X, x);
      convertShortIntegerRegisterToLongInteger(REGISTER_X, x2);
      break;
    }

    case dtLongInteger: {
      convertLongIntegerRegisterToLongInteger(REGISTER_X, x);
      convertLongIntegerRegisterToLongInteger(REGISTER_X, x2);
      break;
    }

    case dtReal34: {
      // if ceil(x) != floor(x), then x is not an integer
      convertReal34ToLongInteger(REGISTER_REAL34_DATA(REGISTER_X), x, DEC_ROUND_CEILING);
      convertReal34ToLongInteger(REGISTER_REAL34_DATA(REGISTER_X), x2, DEC_ROUND_FLOOR);
      break;
    }

    default: {
      //displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
      //#if(EXTRA_INFO_ON_CALC_ERROR == 1)
      //  sprintf(errorMessage, "the input type %s cannot convert to integer", getDataTypeName(getRegisterDataType(REGISTER_X), false, false));
      //  moreInfoOnError("In function fnCheckInteger:", errorMessage, NULL, NULL);
      //#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      temporaryInformation = TI_FALSE;
      return;
    }
  }

  #if defined(DMCP_BUILD)
    lcd_refresh();
  #else // !DMCP_BUILD
    refreshLcd(NULL);
  #endif // DMCP_BUILD
  if(longIntegerCompare(x, x2) == 0) {
    switch(mode) {
      case CHECK_INTEGER: {
        temporaryInformation = TI_TRUE;
        break;
      }

      case CHECK_INTEGER_EVEN: {
        SET_TI_TRUE_FALSE(longIntegerIsEven(x));
        break;
      }

      case CHECK_INTEGER_ODD: {
        SET_TI_TRUE_FALSE(longIntegerIsOdd(x));
        break;
      }

      case CHECK_INTEGER_FP: {
        temporaryInformation = TI_FALSE;
        break;
      }
    }
  }
  else if(lastErrorCode == 0 && mode == CHECK_INTEGER_FP) {
    temporaryInformation = TI_TRUE;
  }
  else {
    temporaryInformation = TI_FALSE;
  }
  longIntegerFree(x);
  longIntegerFree(x2);
}
