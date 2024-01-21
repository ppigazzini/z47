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
 * \file sqrt.c
 ***********************************************/

#include "mathematics/squareRoot.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "fonts.h"
#include "integers.h"
#include "items.h"
#include "mathematics/matrix.h"
#include "mathematics/toPolar.h"
#include "mathematics/toRect.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"

static void sqrtShoI(void) {
  int32_t signValue;

  WP34S_extract_value(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)), &signValue);
  if(signValue && getFlag(FLAG_CPXRES)) {
    real_t a;
    convertShortIntegerRegisterToReal(REGISTER_X, &a, &ctxtReal39);
    reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
    realSetPositiveSign(&a);
    realSquareRoot(&a, &a, &ctxtReal39);
    convertComplexToResultRegister(const_0, &a, REGISTER_X);
  }
  else {
    *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = WP34S_intSqrt(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)));
  }
}

static void sqrtReal(void) {
  real_t a;

  if (!getRegisterAsReal(REGISTER_X, &a))
    return;

  if(realIsInfinite(&a) && !getSystemFlag(FLAG_SPCRES)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function sqrtReal:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of sqrt when flag D is not set", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  if(realIsPositive(&a)) {
    realSquareRoot(&a, &a, &ctxtReal39);
    convertRealToResultRegister(&a, REGISTER_X, amNone);
  }
  else if(getFlag(FLAG_CPXRES)) {
    realSetPositiveSign(&a);
    realSquareRoot(&a, &a, &ctxtReal39);
    convertComplexToResultRegister(const_0, &a, REGISTER_X);
  }
  else {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, STD_SQUARE_ROOT STD_x_UNDER_ROOT " doesn't work on a negative real when flag I is not set!");
      moreInfoOnError("In function sqrtReal:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}

static void sqrtCplx(void) {
  real_t a, b;

  if (getRegisterAsComplex(REGISTER_X, &a, &b)) {
    sqrtComplex(&a, &b, &a, &b, &ctxtReal39);
    convertComplexToResultRegister(&a, &b, REGISTER_X);
  }
}

void sqrtComplex(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext) {
  if(realIsZero(imag) && realIsNegative(real)) {
    realMinus(real, resImag, realContext);
    realSquareRoot(resImag, resImag, realContext);
    realZero(resReal);
  }
  else if(realIsZero(imag)) {
    realSquareRoot(real, resReal, realContext);
    realZero(resImag);
  }
  else {
    realRectangularToPolar(real, imag, resReal, resImag, realContext);
    realSquareRoot(resReal, resReal, realContext);
    realMultiply(resImag, const_1on2, resImag, realContext);
    realPolarToRectangular(resReal, resImag, resReal, resImag, realContext);
  }
}

/********************************************//**
 * \brief regX ==> regL and sqrt(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnSquareRoot(uint16_t unusedButMandatoryParameter) {
  processIntRealComplexMonadicFunction(&sqrtReal, &sqrtCplx, &sqrtShoI, NULL);
}
