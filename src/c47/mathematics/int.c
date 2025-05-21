// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file int.c
 ***********************************************/

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

    case dtComplex34:
      if (!real34IsZero(REGISTER_IMAG34_DATA(REGISTER_X)) || real34IsSpecial(REGISTER_IMAG34_DATA(REGISTER_X))) {
        temporaryInformation = TI_FALSE;
        return;
      }
      /* FALL THROUGH */
    case dtReal34: {
      // if ceil(x) != floor(x), then x is not an integer
      if (real34IsSpecial(REGISTER_REAL34_DATA(REGISTER_X))) {
        temporaryInformation = TI_FALSE;
        return;
      }
      convertReal34ToLongInteger(REGISTER_REAL34_DATA(REGISTER_X), x, DEC_ROUND_CEILING);
      convertReal34ToLongInteger(REGISTER_REAL34_DATA(REGISTER_X), x2, DEC_ROUND_FLOOR);
      break;
    }

    default: {
      //displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
      //#if (EXTRA_INFO_ON_CALC_ERROR == 1)
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
