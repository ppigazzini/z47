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

#include "wp43.h"



TO_QSPI void (* const arcsin[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2           3           4            5            6            7           8           9             10
//          Long integer Real34      Complex34   Time         Date         String       Real34 mat  Complex34 m Short integer Config data
            arcsinLonI,  arcsinReal, arcsinCplx, arcsinError, arcsinError, arcsinError, arcsinRema, arcsinCxma, arcsinError,  arcsinError
};



/********************************************//**
 * \brief Data type error in arcsin
 *
 * \param void
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void arcsinError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate arcsin for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnArcsin:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and arcsin(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnArcsin(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  arcsin[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}



void arcsinLonI(void) {
  real_t x;

  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
  if(realCompareAbsGreaterThan(&x, const_1)) {
    if(getFlag(FLAG_CPXRES)) {
      reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(&x, REGISTER_X);
      real34Zero(REGISTER_IMAG34_DATA(REGISTER_X));
      arcsinCplx();
    }
    else if(getSystemFlag(FLAG_SPCRES)) {
      reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, currentAngularMode);
      convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function arcsinLonI:", "|X| > 1", "and CPXRES is not set!", NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
    return;
  }

  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, currentAngularMode);

  if(realIsZero(&x)) {
    real34Zero(REGISTER_REAL34_DATA(REGISTER_X));
  }
  else {
    convertRealToReal34ResultRegister(const_90, REGISTER_X);
    if(realIsNegative(&x)) {
      real34ChangeSign(REGISTER_REAL34_DATA(REGISTER_X));
    }
    convertAngle34FromTo(REGISTER_REAL34_DATA(REGISTER_X), amDegree, currentAngularMode);
  }
}



void arcsinRema(void) {
  elementwiseRema(arcsinReal);
}



void arcsinCxma(void) {
  elementwiseCxma(arcsinCplx);
}



void arcsinReal(void) {
  real_t x;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
  setRegisterAngularMode(REGISTER_X, currentAngularMode);

  if(realCompareAbsGreaterThan(&x, const_1)) {
    if(getFlag(FLAG_CPXRES)) {
      reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(&x, REGISTER_X);
      real34Zero(REGISTER_IMAG34_DATA(REGISTER_X));
      arcsinCplx();
      return;
    }
    else if(getSystemFlag(FLAG_SPCRES)) {
      convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function arcsinReal:", "|X| > 1", "and CPXRES is not set!", NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }
  }

  WP34S_Asin(&x, &x, &ctxtReal39);
  convertAngleFromTo(&x, amRadian, currentAngularMode, &ctxtReal39);
  convertRealToReal34ResultRegister(&x, REGISTER_X);
}

void arcsinCplx(void) {
  real_t xReal, xImag, rReal, rImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  ArcsinComplex(&xReal, &xImag, &rReal, &rImag, &ctxtReal39);

  convertRealToReal34ResultRegister(&rReal, REGISTER_X);
  convertRealToImag34ResultRegister(&rImag, REGISTER_X);
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
