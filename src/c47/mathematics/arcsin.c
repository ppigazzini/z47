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
 * \file arcsin.c
 ***********************************************/

#include "mathematics/arcsin.h"

#include "constantPointers.h"
#include "conversionAngles.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "items.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/ln.h"
#include "mathematics/matrix.h"
#include "mathematics/multiplication.h"
#include "mathematics/sqrt1Px2.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"


static void arcsinCplx(void) {
  real_t xReal, xImag, rReal, rImag;

  if(!getRegisterAsComplex(REGISTER_X, &xReal, &xImag))
    return;

  ArcsinComplex(&xReal, &xImag, &rReal, &rImag, &ctxtReal39);

  convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
}

static void arcsinReal(void) {
  real_t x;
  const real_t *r = &x;

  if(!getRegisterAsReal(REGISTER_X, &x))
    return;

  if(realCompareAbsGreaterThan(&x, const_1)) {
    if(getFlag(FLAG_CPXRES)) {
      arcsinCplx();
      return;
    }
    else if(getSystemFlag(FLAG_SPCRES)) {
      r = const_NaN;
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function arcsinReal:", "|X| > 1", "and CPXRES is not set!", NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }
  }
  else {
    WP34S_Asin(&x, &x, &ctxtReal39);
    convertAngleFromTo(&x, amRadian, currentAngularMode, &ctxtReal39);
  }
  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, currentAngularMode);
  convertRealToResultRegister(r, REGISTER_X, currentAngularMode);
}


uint8_t ArcsinComplex(const real_t *xReal, const real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext) {
  real_t a, b;

  realCopy(xReal, &a);
  realCopy(xImag, &b);

  // arcsin(z) = -i.ln(iz + sqrt(1 - z²))
  // calculate sqrt(1 - z²)
  realChangeSign(&b);
  sqrt1Px2Complex(&b, &a, rReal, rImag, realContext);

  // calculate iz + sqrt(1 - z²)
  realAdd(rReal, &b, rReal, realContext);
  realAdd(rImag, &a, rImag, realContext);

  // calculate ln(iz + sqrt(1 - z²))
  lnComplex(rReal, rImag, &a, &b, realContext);

  // calculate = -i.ln(iz + sqrt(1 - z²))
  realChangeSign(&a);

  realCopy(&b, rReal);
  realCopy(&a, rImag);

  return ERROR_NONE;
}


/********************************************//**
 * \brief regX ==> regL and arcsin(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnArcsin(uint16_t unusedButMandatoryParameter) {
  processRealComplexMonadicFunction(&arcsinReal, &arcsinCplx);

}
