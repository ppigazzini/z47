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
 * \file gamma.c
 ***********************************************/

#include "mathematics/gamma.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "fonts.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/division.h"
#include "mathematics/ln.h"
#include "mathematics/matrix.h"
#include "mathematics/multiplication.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "wp43.h"



TO_QSPI void (* const Gamma[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2          3          4           5           6           7           8           9             10
//          Long integer Real34     Complex34  Time        Date        String      Real34 mat  Complex34 m Short integer Config data
            gammaLonI,   gammaReal, gammaCplx, gammaError, gammaError, gammaError, gammaError, gammaError, gammaError,   gammaError
};

TO_QSPI void (* const lnGamma[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2            3            4             5             6             7             8             9             10
//          Long integer Real34       Complex34    Time          Date          String        Real34 mat    Complex34 m   Short integer Config data
            lnGammaLonI, lnGammaReal, lnGammaCplx, lnGammaError, lnGammaError, lnGammaError, lnGammaError, lnGammaError, lnGammaError, lnGammaError
};



/********************************************//**
 * \brief Data type error in gamma
 *
 * \param void
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void gammaError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate gamma(%s)", getRegisterDataTypeName(REGISTER_X, false, false));
    moreInfoOnError("In function fnGamma:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief Data type error in lnGamma
 *
 * \param void
 * \return void
 ***********************************************/
void lnGammaError(void) {
  displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
  #if(EXTRA_INFO_ON_CALC_ERROR == 1)
    sprintf(errorMessage, "cannot calculate lnGamma(%s)", getRegisterDataTypeName(REGISTER_X, false, false));
    moreInfoOnError("In function fnLnGamma:", errorMessage, NULL, NULL);
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
}



/********************************************//**
 * \brief regX ==> regL and gamma(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnGamma(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  Gamma[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}



/********************************************//**
 * \brief regX ==> regL and lnGamma(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnLnGamma(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  lnGamma[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}



void gammaLonI(void) {
  real_t x;

  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);

  if(realIsInfinite(&x)) {
    if(!getSystemFlag(FLAG_SPCRES)) {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function gammaLonI:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of gamma when flag D is not set", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
    else {
      realToReal34((realIsPositive(&x) ? const_plusInfinity : const_NaN), REGISTER_REAL34_DATA(REGISTER_X));
    }
    return;
  }

  if(realCompareLessEqual(&x, const_0)) { // x <= 0 and is an integer
    if(!getSystemFlag(FLAG_SPCRES)) {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function gammaLonI:", "cannot use a negative integer as X input of gamma when flag D is not set", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
    else {
      convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
    }
    return;
  }

  WP34S_Gamma(&x, &x, &ctxtReal39);
  convertRealToReal34ResultRegister(&x, REGISTER_X);
}



void lnGammaLonI(void) {
  real_t x;

  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);

  if(realIsInfinite(&x)) {
    if(!getSystemFlag(FLAG_SPCRES)) {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function lnGammaLonI:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of gamma when flag D is not set", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
    else {
      realToReal34((realIsPositive(&x) ? const_plusInfinity : const_NaN), REGISTER_REAL34_DATA(REGISTER_X));
    }
    return;
  }

  if(realCompareLessEqual(&x, const_0)) { // x <= 0 and is an integer
    if(!getSystemFlag(FLAG_SPCRES)) {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function lnGammaLonI:", "cannot use a negative integer as X input of gamma when flag D is not set", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
    else {
      convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
    }
    return;
  }

  WP34S_LnGamma(&x, &x, &ctxtReal39);
  convertRealToReal34ResultRegister(&x, REGISTER_X);
}



void gammaReal(void) {
  setRegisterAngularMode(REGISTER_X, amNone);

  if(real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X))) {
    if(!getSystemFlag(FLAG_SPCRES)) {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function gammaReal:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of gamma when flag D is not set", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
    else {
      realToReal34((real34IsPositive(REGISTER_REAL34_DATA(REGISTER_X)) ? const_plusInfinity : const_NaN), REGISTER_REAL34_DATA(REGISTER_X));
    }
    return;
  }

  if(real34CompareLessEqual(REGISTER_REAL34_DATA(REGISTER_X), const34_0) && real34IsAnInteger(REGISTER_REAL34_DATA(REGISTER_X))) {
    if(!getSystemFlag(FLAG_SPCRES)) {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function gammaReal:", "cannot use a negative integer as X input of gamma when flag D is not set", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
    else {
      convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
    }
    return;
  }

  real_t x;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
  WP34S_Gamma(&x, &x, &ctxtReal39);
  convertRealToReal34ResultRegister(&x, REGISTER_X);
}



void lnGammaReal(void) {
  real_t xReal, xImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  setRegisterAngularMode(REGISTER_X, amNone);

  if(realIsInfinite(&xReal)) {
    if(!getSystemFlag(FLAG_SPCRES)) {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function lngammaReal:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of lngamma when flag D is not set", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
    else {
      realToReal34((realIsPositive(&xReal) ? const_plusInfinity : const_NaN), REGISTER_REAL34_DATA(REGISTER_X));
    }
    return;
  }

  if(realCompareLessEqual(&xReal, const_0)) { // x <= 0
    if(realIsAnInteger(&xReal)) {
      if(!getSystemFlag(FLAG_SPCRES)) {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        #if(EXTRA_INFO_ON_CALC_ERROR == 1)
          moreInfoOnError("In function lngammaReal:", "cannot use a negative integer as X input of lngamma when flag D is not set", NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      }
      else {
        convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
      }
      return;
    }
    else { // x is negative and not an integer
      realMinus(&xReal, &xImag, &ctxtReal39); // x.imag is used as a temp variable here
      WP34S_Mod(&xImag, const_2, &xImag, &ctxtReal39);
      if(realCompareGreaterThan(&xImag, const_1)) { // the result is a real
        WP34S_LnGamma(&xReal, &xReal, &ctxtReal39);
        convertRealToReal34ResultRegister(&xReal, REGISTER_X);
      }
      else { // the result is a complex
        if(getFlag(FLAG_CPXRES)) { // We can calculate a complex
          real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xImag);
          reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
          WP34S_Gamma(&xReal, &xReal, &ctxtReal39);
          realSetPositiveSign(&xReal);
          WP34S_Ln(&xReal, &xReal, &ctxtReal39);
          convertRealToReal34ResultRegister(&xReal, REGISTER_X);
          realToIntegralValue(&xImag, &xImag, DEC_ROUND_FLOOR, &ctxtReal39);
          realMultiply(&xImag, const_pi, &xImag, &ctxtReal39);
          convertRealToImag34ResultRegister(&xImag, REGISTER_X);
        }
        else { // Domain error
          displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
          #if(EXTRA_INFO_ON_CALC_ERROR == 1)
            moreInfoOnError("In function lngammaReal:", "cannot use a as X input of lngamma if gamma(X)<0 when flag I is not set", NULL, NULL);
          #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        }
      }
    }
    return;
  }

  WP34S_LnGamma(&xReal, &xReal, &ctxtReal39);
  convertRealToReal34ResultRegister(&xReal, REGISTER_X);
}



void gammaCplx(void) {
  real_t zReal, zImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &zReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &zImag);

  WP34S_ComplexGamma(&zReal, &zImag, &zReal, &zImag, &ctxtReal39);

  convertRealToReal34ResultRegister(&zReal, REGISTER_X);
  convertRealToImag34ResultRegister(&zImag, REGISTER_X);
}



// Abramowitz & Stegun §6.1.41
// (only approximation needed here)
static void complexLnGamma_Stirling(const real_t *xReal, const real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext) {
  // (z-1/2)ln(z) - z + (1/2)ln(2pi) + 1/(12z) - 1/(360z^3) + 1/(1260z^5) - 1/(1680z^7) ...
  real_t zReal, zImag, z2Real, z2Imag, zxReal, zxImag, tReal, tImag;
  realCopy(xReal, &zReal); realCopy(xImag, &zImag);
  lnComplex(&zReal, &zImag, rReal, rImag, realContext);
  realSubtract(&zReal, const_1on2, &tReal, realContext);
  mulComplexComplex(&tReal, &zImag, rReal, rImag, rReal, rImag, realContext);

  realSubtract(rReal, &zReal, rReal, realContext); realSubtract(rImag, &zImag, rImag, realContext);

  realAdd(rReal, const_ln2piOn2, rReal, realContext);

  realMultiply(const_12, &zReal, &tReal, realContext); realMultiply(const_12, &zImag, &tImag, realContext);
  divRealComplex(const_1, &tReal, &tImag, &tReal, &tImag, realContext);
  realAdd(rReal, &zReal, rReal, realContext); realAdd(rImag, &zImag, rImag, realContext);

  mulComplexComplex(&zReal, &zImag, &zReal, &zImag, &z2Real, &z2Imag, realContext);
  mulComplexComplex(&zReal, &zImag, &z2Real, &z2Imag, &zxReal, &zxImag, realContext);
  realMultiply(const_360, &zxReal, &tReal, realContext); realMultiply(const_360, &zxImag, &tImag, realContext);
  divRealComplex(const_1, &tReal, &tImag, &tReal, &tImag, realContext);
  realSubtract(rReal, &zReal, rReal, realContext); realSubtract(rImag, &zImag, rImag, realContext);

  mulComplexComplex(&zxReal, &zxImag, &z2Real, &z2Imag, &zxReal, &zxImag, realContext);
  realMultiply(const_1260, &zxReal, &tReal, realContext); realMultiply(const_1260, &zxImag, &tImag, realContext);
  divRealComplex(const_1, &tReal, &tImag, &tReal, &tImag, realContext);
  realAdd(rReal, &zReal, rReal, realContext); realAdd(rImag, &zImag, rImag, realContext);

  mulComplexComplex(&zxReal, &zxImag, &z2Real, &z2Imag, &zxReal, &zxImag, realContext);
  realMultiply(const_1680, &zxReal, &tReal, realContext); realMultiply(const_1680, &zxImag, &tImag, realContext);
  divRealComplex(const_1, &tReal, &tImag, &tReal, &tImag, realContext);
  realSubtract(rReal, &zReal, rReal, realContext); realSubtract(rImag, &zImag, rImag, realContext);
}



void complexLnGamma(const real_t *xReal, const real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext) {
  if(realIsZero(xImag)) {
    WP34S_LnGamma(xReal, rReal, realContext);
    realCopy(realIsNaN(rReal) ? const_NaN : const_0, rImag);
  }
  else {
    real_t zReal, zImag, tImag;
    realCopy(xReal, &zReal); realCopy(xImag, &zImag);
    complexLnGamma_Stirling(&zReal, &zImag, rReal, &tImag, &ctxtReal39);
    WP34S_ComplexLnGamma(&zReal, &zImag, rReal, rImag, &ctxtReal39);
    realSubtract(&tImag, rImag, &tImag, &ctxtReal39);
    realDivide(&tImag, const_2pi, &tImag, &ctxtReal39);
    realToIntegralValue(&tImag, &tImag, DEC_ROUND_HALF_EVEN, &ctxtReal39);
    realFMA(const_2pi, &tImag, rImag, rImag, &ctxtReal39);
  }
}



void lnGammaCplx(void) {
  real_t zReal, zImag, rReal, rImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &zReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &zImag);

  complexLnGamma(&zReal, &zImag, &rReal, &rImag, &ctxtReal39);

  convertRealToReal34ResultRegister(&rReal, REGISTER_X);
  convertRealToImag34ResultRegister(&rImag, REGISTER_X);
}
