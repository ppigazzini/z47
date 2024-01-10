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
 * \file bn.c
 ***********************************************/

#include "mathematics/bn.h"

#include "debug.h"
#include "error.h"
#include "items.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"



static void bn_common(bool_t bnstar) {
  real_t x, res;

  if (!getRegisterAsReal(REGISTER_X, &x))
    return;
  if(!saveLastX()) {
    return;
  }

  WP34S_Bernoulli(&x, &res, bnstar, &ctxtReal39);
  if(realIsNaN(&res)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function fnBn:", bnstar ? "k must be a non-negative integer" : "k must be a positive integer", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  else {
    reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
    convertRealToReal34ResultRegister(&res, REGISTER_X);
  }

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}

void fnBn(uint16_t unusedButMandatoryParameter) {
  bn_common(false);
}

void fnBnStar(uint16_t unusedButMandatoryParameter) {
  bn_common(true);
}
