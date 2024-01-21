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
 * \file deltaPercentXmean.c
 ***********************************************/

#include "mathematics/deltaPercentXmean.h"
#include "mathematics/deltaPercent.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "mathematics/comparisonReals.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"


//=============================================================================
// Delta% calculation functions
//-----------------------------------------------------------------------------

bool_t deltaPercentXmeanReal(real_t *xReal, real_t *rReal, realContext_t *realContext) {
real_t yReal;

  realDivide(SIGMA_X, SIGMA_N, &yReal, &ctxtReal39);
  /*
   * Check x and y
   */
  if(realIsZero(xReal) && realCompareEqual(xReal, &yReal)) {
      if(getSystemFlag(FLAG_SPCRES)) {
        realCopy(const_NaN, rReal);
      }
      else {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        #if(EXTRA_INFO_ON_CALC_ERROR == 1)
          moreInfoOnError("In function fndeltaPercentXmean:", "cannot divide 0 by 0", NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        return false;
      }
  }
  else if(realIsZero(&yReal)) {
    if(getSystemFlag(FLAG_SPCRES)) {
      realCopy((realCompareAbsGreaterThan(xReal, &yReal) ? const_plusInfinity : const_minusInfinity),rReal);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function fndeltaPercentXmean:", "cannot divide a real by y=0", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return false;
    }
  }
  else {
    realSubtract(xReal, &yReal, rReal, realContext);     // r = x - y
    realDivide(rReal, &yReal, rReal, realContext);       // r = (x - y)/y
    realMultiply(rReal, const_100, rReal, realContext); // r = r * 100.0
  }
  return true;
}

//=============================================================================
// Main function
//-----------------------------------------------------------------------------

/********************************************//**
 * \brief regX ==> regL and deltaPercentXmean(regX) ==> regX
 * enables stack lift and refreshes the stack.
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/


void fnDeltaPercentXmean(uint16_t unusedButMandatoryParameter) {
  real_t xReal, yReal;
  real_t rReal;

  if (!getRegisterAsReal(REGISTER_X, &xReal)
          || !getRegisterAsReal(REGISTER_Y, &yReal))
    return;

  if(!saveLastX()) {
    return;
  }

  if(deltaPercentXmeanReal(&xReal, &rReal, &ctxtReal75)) {
    reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
    convertRealToReal34ResultRegister(&rReal, REGISTER_X);
    setRegisterAngularMode(REGISTER_X, amNone);
  }

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);

  temporaryInformation = TI_PERCD;
}
