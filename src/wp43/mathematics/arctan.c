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
 * \file arctan.c
 ***********************************************/

#include "mathematics/arctan.h"

#include "constantPointers.h"
#include "conversionAngles.h"
#include "debug.h"
#include "error.h"
#include "fonts.h"
#include "items.h"
#include "mathematics/toPolar.h"
#include "mathematics/matrix.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "wp43.h"



TO_QSPI void (* const arctan[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2           3           4            5            6            7           8           9             10
//          Long integer Real34      Complex34   Time         Date         String       Real34 mat  Complex34 m Short integer Config data
            arctanLonI,  arctanReal, arctanCplx, arctanError, arctanError, arctanError, arctanRema, arctanCxma, arctanError,  arctanError
};



/********************************************//**
 * \brief Data type error in arctan
 *
 * \param void
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void arctanError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate arctan for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnArctan:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and arctan(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnArctan(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  arctan[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}



void arctanLonI(void) {
  real_t x;

  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
  WP34S_Atan(&x, &x, &ctxtReal39);
  convertAngleFromTo(&x, amRadian, currentAngularMode, &ctxtReal39);
  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, currentAngularMode);
  convertRealToReal34ResultRegister(&x, REGISTER_X);
}



void arctanRema(void) {
  elementwiseRema(arctanReal);
}



void arctanCxma(void) {
  elementwiseCxma(arctanCplx);
}



void arctanReal(void) {
  if(real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X))) {
    if(getSystemFlag(FLAG_SPCRES)) {
      if(real34IsPositive(REGISTER_REAL34_DATA(REGISTER_X))) {
        convertRealToReal34ResultRegister(const_90, REGISTER_X);
      }
      else {
        convertRealToReal34ResultRegister(const_90, REGISTER_X);
        real34SetNegativeSign(REGISTER_REAL34_DATA(REGISTER_X));
      }
      convertAngle34FromTo(REGISTER_REAL34_DATA(REGISTER_X), amDegree, currentAngularMode);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function arctanReal:", "X = " STD_PLUS_MINUS STD_INFINITY, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }
  }
  else {
    real_t x;

    real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
    WP34S_Atan(&x, &x, &ctxtReal39);
    convertAngleFromTo(&x, amRadian, currentAngularMode, &ctxtReal39);
    convertRealToReal34ResultRegister(&x, REGISTER_X);
  }

  setRegisterAngularMode(REGISTER_X, currentAngularMode);
}



void arctanCplx(void) {
  real_t xReal, xImag, rReal, rImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  ArctanComplex(&xReal, &xImag, &rReal, &rImag, &ctxtReal39);

  convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);

  //real_t a, b, numer, denom;
  //
  //real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &a);
  //real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &b);
  //
  //// arctan(z) = i/2 . ln((1 - iz) / (1 + iz))
  //
  //// calculate (1 - iz) / (1 + iz)  with z = a + bi
  //
  //// 1 - (a + bi)i      1 - (a² + b²)             - 2a
  //// -------------  =  ----------------  +  ---------------- i
  //// 1 + (a + bi)i     a² + b² - 2b + 1     a² + b² - 2b + 1
  //
  //realMultiply(&a, &a, &denom, &ctxtReal39);          // denom = a²
  //realFMA(&b, &b, &denom, &denom, &ctxtReal39);       // denom = a² + b²
  //realSubtract(const_1, &denom, &numer, &ctxtReal39); // numer = 1 - (a² + b²)
  //realChangeSign(&b);                                 // b = -b
  //realFMA(&b, const_2, &denom, &denom, &ctxtReal39);  // denom = a² + b² - 2b
  //realAdd(&denom, const_1, &denom, &ctxtReal39);      // denom = a² + b² - 2b + 1
  //realMultiply(&a, const_2, &b, &ctxtReal39);         // imag part = 2a
  //realChangeSign(&b);                                 // imag part = -2a
  //realDivide(&numer, &denom, &a, &ctxtReal39);        // real part = numer / denom
  //realDivide(&b, &denom, &b, &ctxtReal39);            // imag part = -2a / denom
  //
  //// calculate ln((1 - iz) / (1 + iz))
  //realRectangularToPolar(&a, &b, &a, &b, &ctxtReal39);
  //WP34S_Ln(&a, &a, &ctxtReal39);
  //
  //// arctan(z) = i/2 . ln((1 - iz) / (1 + iz))
  //realMultiply(&a, const_1on2, &a, &ctxtReal39);
  //realMultiply(&b, const_1on2, &b, &ctxtReal39);
  //realChangeSign(&b);
  //
  //convertComplexToResultRegister(&b, &a, REGISTER_X);
}


uint8_t ArctanComplex(real_t *xReal, real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext) {
  real_t a, b, numer, denom;

  realCopy(xReal, &a);
  realCopy(xImag, &b);

  // arctan(z) = i/2 . ln((1 - iz) / (1 + iz))

  // calculate (1 - iz) / (1 + iz)  with z = a + bi

  // 1 - (a + bi)i      1 - (a² + b²)             - 2a
  // -------------  =  ----------------  +  ---------------- i
  // 1 + (a + bi)i     a² + b² - 2b + 1     a² + b² - 2b + 1

  realMultiply(&a, &a, &denom, realContext);         // denom = a²
  realFMA(&b, &b, &denom, &denom, realContext);   // denom = a² + b²
  realSubtract(const_1, &denom, &numer, realContext);         // numer = 1 - (a² + b²)
  realChangeSign(&b);                                              // b = -b
  realFMA(&b, const_2, &denom, &denom, realContext);     // denom = a² + b² - 2b
  realAdd(&denom, const_1, &denom, realContext);             // denom = a² + b² - 2b + 1
  realMultiply(&a, const_2, &b, realContext);                // imag part = 2a
  realChangeSign(&b);                                             // imag part = -2a
  realDivide(&numer, &denom, &a, realContext);      // real part = numer / denom
  realDivide(&b, &denom, &b, realContext);          // imag part = -2a / denom

  // calculate ln((1 - iz) / (1 + iz))
  realRectangularToPolar(&a, &b, &a, &b, realContext);
  WP34S_Ln(&a, &a, realContext);

  // arctan(z) = i/2 . ln((1 - iz) / (1 + iz))
  realMultiply(&a, const_1on2, &a, realContext);
  realMultiply(&b, const_1on2, &b, realContext);
  realChangeSign(&b);

  realCopy(&b, rReal);
  realCopy(&a, rImag);

  return ERROR_NONE;
}
