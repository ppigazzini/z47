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
 * \file tan.c
 ***********************************************/

#include "mathematics/tan.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "fonts.h"
#include "items.h"
#include "mathematics/division.h"
#include "mathematics/matrix.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "wp43.h"



TO_QSPI void (* const Tan[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2        3        4         5         6         7        8           9             10
//          Long integer Real     complex  Time      Date      String    Real mat Complex mat short integer Config data
            tanLonI,     tanReal, tanCplx, tanError, tanError, tanError, tanRema, tanCxma,    tanError,     tanError
};


angularMode_t determineAngleMode(angularMode_t mode) {
    return mode == amNone ? currentAngularMode : mode;
}

void longIntegerAngleReduction(calcRegister_t regist, angularMode_t angularMode, real_t *reducedAngle) {
  uint32_t oneTurn;
  longInteger_t angle;

  switch(angularMode) {
    case amMultPi: {
      oneTurn = 2;
      break;
    }
    case amGrad: {
      oneTurn = 400;
      break;
    }
    case amDegree:
    case amDMS: {
      oneTurn = 360;
      break;
    }
    default: {
      convertLongIntegerRegisterToReal(regist, reducedAngle, &ctxtReal75);
      return;
    }
  }

  convertLongIntegerRegisterToLongInteger(regist, angle);
  uInt32ToReal(longIntegerModuloUInt(angle, oneTurn), reducedAngle);
  longIntegerFree(angle);
}



/********************************************//**
 * \brief Data type error in tan
 *
 * \param void
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void tanError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate Tan for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnTan:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and tan(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnTan(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  Tan[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}



void tanLonI(void) {
  real_t sin, cos, tan;

  longIntegerAngleReduction(REGISTER_X, currentAngularMode, &tan);
  WP34S_Cvt2RadSinCosTan(&tan, currentAngularMode, &sin, &cos, &tan, &ctxtReal75);
  if(realIsZero(&sin)) {
     realSetPositiveSign(&tan);
  }

  if(realIsZero(&cos) && !getSystemFlag(FLAG_SPCRES)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function tanLonI:", "X = " STD_PLUS_MINUS "90" STD_DEGREE, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE, amNone);
  if(realIsZero(&cos)) {
    convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
  }
  else {
    convertRealToReal34ResultRegister(&tan, REGISTER_X);
  }
}



void tanRema(void) {
  elementwiseRema(tanReal);
}



void tanCxma(void) {
  elementwiseCxma(tanCplx);
}



void tanReal(void) {
  if(real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X))) {
    convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
  }
  else {
    real_t sin, cos, tan;
    angularMode_t xAngularMode = determineAngleMode(getRegisterAngularMode(REGISTER_X));

    real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &tan);

    WP34S_Cvt2RadSinCosTan(&tan, xAngularMode, &sin, &cos, &tan, &ctxtReal75);
    if(realIsZero(&sin)) {
       realSetPositiveSign(&tan);
    }

    if(realIsZero(&cos) && !getSystemFlag(FLAG_SPCRES)) {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function tanReal:", "X = " STD_PLUS_MINUS "90" STD_DEGREE, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }
    else {
      if(realIsZero(&cos)) {
        convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
      }
      else {
        convertRealToReal34ResultRegister(&tan, REGISTER_X);
      }
    }
  }
  setRegisterAngularMode(REGISTER_X, amNone);
}



void tanCplx(void) {
  //                sin(a)*cosh(b) + i*cos(a)*sinh(b)
  // tan(a + ib) = -----------------------------------
  //                cos(a)*cosh(b) - i*sin(a)*sinh(b)

  real_t xReal, xImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  TanComplex(&xReal, &xImag, &xReal, &xImag, &ctxtReal51);

  convertRealToReal34ResultRegister(&xReal, REGISTER_X);
  convertRealToImag34ResultRegister(&xImag, REGISTER_X);
}

uint8_t TanComplex(const real_t *xReal, const real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext) {
  real_t sina, cosa, sinhb, coshb;
  real_t numerReal, denomReal;
  real_t numerImag, denomImag;

  WP34S_Cvt2RadSinCosTan(xReal, amRadian, &sina, &cosa, NULL, realContext);
  WP34S_SinhCosh(xImag, &sinhb, &coshb, realContext);

  realMultiply(&sina, &coshb, &numerReal, realContext);
  realMultiply(&cosa, &sinhb, &numerImag, realContext);

  realMultiply(&cosa, &coshb, &denomReal, realContext);
  realMultiply(&sina, &sinhb, &denomImag, realContext);
  realChangeSign(&denomImag);

  divComplexComplex(&numerReal, &numerImag, &denomReal, &denomImag, rReal, rImag, realContext);

  return ERROR_NONE;
}
