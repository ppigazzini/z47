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
 * \file percentSigma.c
 ***********************************************/

#include "mathematics/percentSigma.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "mathematics/matrix.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "stats.h"

#include "c47.h"

//=============================================================================
// PercentSigma calculation function
//-----------------------------------------------------------------------------

bool_t percentSigma(real_t *xReal, real_t *rReal, realContext_t *realContext) {
  realCopy(SIGMA_X, rReal);    // r = Sum(x)
  if(realIsZero(rReal)) {
    if(getSystemFlag(FLAG_SPCRES)) {
      realCopy((realIsPositive(rReal) ? const_plusInfinity : const_minusInfinity), rReal);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function fnPercentSigma:", "cannot divide a real by 0", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return false;
    }
  }

  realDivide(xReal, rReal, rReal, realContext);       // r = x/Sum(x)
  realMultiply(rReal, const_100, rReal, realContext); // r = 100*x/Sum(x)

  return true;
}

/***********************************************
 * \brief Percent(X(real34)) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
static void percentSigmaReal(void) {
  real_t xReal, rReal;

  if(!getRegisterAsReal(REGISTER_X, &xReal) || !percentSigma(&xReal, &rReal, &ctxtReal39))
    return;

  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  convertRealToReal34ResultRegister(&rReal, REGISTER_X);
}

//=============================================================================
// Main function
//-----------------------------------------------------------------------------

/********************************************//**
 * \brief regX ==> regL and PercentSigma(regX) ==> regX
 * enables stack lift and refreshes the stack.
 * Calculate %Sigma
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnPercentSigma(uint16_t unusedButMandatoryParameter) {
  if(!checkMinimumDataPoints(const_1)) {
    displayCalcErrorMessage(ERROR_NO_SUMMATION_DATA, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "There is no statistical data available!");
      moreInfoOnError("In function fnPercentSigma:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  if(!saveLastX())
    return;

  if(getRegisterDataType(REGISTER_X) == dtReal34Matrix)
    elementwiseRema(percentSigmaReal);
  else
    percentSigmaReal();

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
  temporaryInformation = TI_PERC;
}
