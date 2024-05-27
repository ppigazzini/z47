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
