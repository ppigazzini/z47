// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file int.c
 ***********************************************/

#include "c47.h"

void fnCheckInteger(uint16_t mode) {
  longInteger_t x;

  switch(getRegisterDataType(REGISTER_X)) {
    case dtShortInteger:
      convertShortIntegerRegisterToLongInteger(REGISTER_X, x);
      break;

    case dtLongInteger:
      convertLongIntegerRegisterToLongInteger(REGISTER_X, x);
      break;

    case dtComplex34:
      if (!real34IsZero(REGISTER_IMAG34_DATA(REGISTER_X))) {
        temporaryInformation = TI_FALSE;
        return;
      }
      /* FALL THROUGH */
    case dtDate:
    case dtTime:
    case dtReal34:
      if (real34IsSpecial(REGISTER_REAL34_DATA(REGISTER_X))) {
        temporaryInformation = TI_FALSE;
        return;
      }
      if (!real34IsAnInteger(REGISTER_REAL34_DATA(REGISTER_X))) {
        temporaryInformation = mode == CHECK_INTEGER_FP;
        return;
      }
      convertReal34ToLongInteger(REGISTER_REAL34_DATA(REGISTER_X), x, DEC_ROUND_FLOOR);
      break;

    default:
      temporaryInformation = TI_FALSE;
      return;
  }

  #if defined(DMCP_BUILD)
    lcd_refresh();
  #else // !DMCP_BUILD
    refreshLcd(NULL);
  #endif // DMCP_BUILD
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
  longIntegerFree(x);
}
