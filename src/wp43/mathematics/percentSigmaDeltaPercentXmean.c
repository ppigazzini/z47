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
 * \file percentSigmaDeltaPercentXmean.c
 ***********************************************/

#include "mathematics/percentSigmaDeltaPercentXmean.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/percentSigma.h"
#include "mathematics/deltaPercentXmean.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "stack.h"

#include "wp43.h"

//=============================================================================
// Delta% calculation functions
//-----------------------------------------------------------------------------


/********************************************//**
 * \brief pcSigmaDeltaPcXmeanReal(X(long integer)) ==> X(real34) ; Y(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void pcSigmaDeltaPcXmeanLonI(void) {
  real_t xReal;
  real_t rReal;

  convertLongIntegerRegisterToReal(REGISTER_L, &xReal, &ctxtReal75);

  if(percentSigma(&xReal, &rReal, &ctxtReal39)) {
    if(getRegisterDataType(REGISTER_Y) != dtReal34) {
      reallocateRegister(REGISTER_Y, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
    }
    convertRealToReal34ResultRegister(&rReal, REGISTER_Y);
    setRegisterAngularMode(REGISTER_Y, amNone);
  }

  if(deltaPercentXmeanReal(&xReal, &rReal, &ctxtReal75)) {
    reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
    convertRealToReal34ResultRegister(&rReal, REGISTER_X);
    setRegisterAngularMode(REGISTER_X, amNone);
  }
}

/********************************************//**
 * \brief pcSigmaDeltaPcXmeanReal(X(real34)) ==> X(real34); Y(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void pcSigmaDeltaPcXmeanReal(void) {
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


void fnPcSigmaDeltaPcXmean(uint16_t unusedButMandatoryParameter) {
  real_t xReal;
  real_t rReal;

  if (!getRegisterAsReal(REGISTER_X, &xReal))
    return;

  if(!saveLastX()) {
    return;
  }
  liftStack();

  if(percentSigma(&xReal, &rReal, &ctxtReal75)) {
    if(getRegisterDataType(REGISTER_Y) != dtReal34)
      reallocateRegister(REGISTER_Y, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
    convertRealToReal34ResultRegister(&rReal, REGISTER_Y);
  }

  if(deltaPercentXmeanReal(&xReal, &rReal, &ctxtReal75))
    convertRealToReal34ResultRegister(&rReal, REGISTER_X);

  adjustResult(REGISTER_X, false, true, REGISTER_L, -1, -1);
  adjustResult(REGISTER_Y, false, true, REGISTER_L, -1, -1);

  temporaryInformation = TI_PERCD2;
}
