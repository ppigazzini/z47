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
 * \file percent.c
 ***********************************************/

#include "mathematics/percent.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"

//=============================================================================
// Percent calculation functions
//-----------------------------------------------------------------------------

static void percentReal(real_t *xReal, real_t *yReal, real_t *rReal, realContext_t *realContext) {
  realMultiply(xReal, yReal, rReal, realContext);     // rReal = xReal * yReal
  realDivide(rReal, const_100, rReal, realContext);   // rReal = rReal / 100.0
}

//=============================================================================
// Main function
//-----------------------------------------------------------------------------

/********************************************//**
 * \brief regX ==> regL and Percent(regX, RegY) ==> regX
 * enables stack lift and refreshes the stack.
 * Calculate x*y/100
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnPercent(uint16_t unusedButMandatoryParameter) {
  real_t xReal, yReal;
  real_t rReal;

  if(!getRegisterAsReal(REGISTER_X, &xReal) || !getRegisterAsReal(REGISTER_Y, &yReal))
    return;

  if(!saveLastX())
    return;

  percentReal(&xReal, &yReal, &rReal, &ctxtReal34);

  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
  convertRealToReal34ResultRegister(&rReal, REGISTER_X);
  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}
