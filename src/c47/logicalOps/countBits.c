// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file countBits.c
 ***********************************************/

#include "logicalOps/countBits.h"

#include "debug.h"
#include "error.h"
#include "registers.h"

#include "c47.h"



/********************************************//**
 * \brief regX ==> regL and countBits(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnCountBits(uint16_t unusedButMandatoryParameter) {
  if(getRegisterDataType(REGISTER_X) != dtShortInteger) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "cannot calculate countBits(%s)", getRegisterDataTypeName(REGISTER_X, false, false));
      moreInfoOnError("In function fnCountBits:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  else {
    uint64_t w;

    if(!saveLastX()) {
      return;
    }

    // https://en.wikipedia.org/wiki/Hamming_weight
    w = *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X));
    w -= (w >> 1) & 0x5555555555555555;
    w = (w & 0x3333333333333333) + ((w >> 2) & 0x3333333333333333);
    w = (w + (w >> 4)) & 0x0f0f0f0f0f0f0f0f;
    *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = (w * 0x0101010101010101) >> 56;
  }
}
