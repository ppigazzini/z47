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
 * \file percentMRR.c
 ***********************************************/

#include "mathematics/percentMRR.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "items.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "stack.h"

#include "c47.h"

static void percentMRR() {
  real_t xReal, yReal, zReal;

  /*
   * Convert register X.
   */
  if(!getRegisterAsReal(REGISTER_X, &xReal))
    return;

  /*
   * Convert register Y.
   */
  if(!getRegisterAsReal(REGISTER_Y, &yReal))
    return;

  /*
   * Convert register Z
   */
  if(!getRegisterAsReal(REGISTER_Z, &zReal))
    return;

  /*
   * Calculate %MRR
   */
  real_t q;

  if(realIsZero(&xReal) && realIsZero(&yReal)) {
    if(getSystemFlag(FLAG_SPCRES)) {
      realCopy(const_NaN, &q);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function fnPercentMRTR:", "cannot divide x=0 by y=0", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }
  }
  else if(realIsZero(&yReal)) {
    if(getSystemFlag(FLAG_SPCRES)) {
      realCopy((realIsPositive(&xReal) ? const_plusInfinity : const_minusInfinity), &q);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function fnPercentMRTR:", "cannot divide a real by 0", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }
  }

  realDivide(&xReal, &yReal, &q, &ctxtReal75);        // q = x/y
  realDivide(const_1, &zReal, &zReal, &ctxtReal75);   // z = 1/z
  realPower(&q, &zReal, &q, &ctxtReal75);             // q = pow(x/y, 1/z)
  realSubtract(&q, const_1, &q, &ctxtReal75);         // q = pow(x/y, 1/z) - 1
  realMultiply(&q, const_100, &q, &ctxtReal75);       // q = 100 * ( pow(x/y, 1/z) - 1 )

  convertRealToResultRegister(&q, REGISTER_X, amNone);

  temporaryInformation = TI_PERC;
}

/********************************************//**
 * \brief regX ==> regL and %MRR(regX, RegY, RegZ) ==> regX
 * enables stack lift and refreshes the stack.
 * Calculate the %MRR.
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnPercentMRR(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  percentMRR();

  adjustResult(REGISTER_X, true, true, REGISTER_X, -1, -1);
  if(lastErrorCode == 0) {
    fnDropY(NOPARAM);
  }
}
