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
 * \file lnbeta.c
 ***********************************************/

#include "mathematics/lnbeta.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "fonts.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/gamma.h"
#include "mathematics/ln.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "wp43.h"

TO_QSPI void (* const lnBeta[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])() = {
// regX |    regY ==>    1               2               3               4            5            6            7            8             9             10
//      V                Long integer    Real34          Complex34       Time         Date         String       Real34 mat   Complex34 mat Short integer Config data
/*  1 Long integer  */ { lnbetaLonILonI, lnbetaRealLonI, lnbetaCplxLonI, lnbetaError, lnbetaError, lnbetaError, lnbetaError, lnbetaError,  lnbetaError,  lnbetaError },
/*  2 Real34        */ { lnbetaLonIReal, lnbetaRealReal, lnbetaCplxReal, lnbetaError, lnbetaError, lnbetaError, lnbetaError, lnbetaError,  lnbetaError,  lnbetaError },
/*  3 Complex34     */ { lnbetaLonICplx, lnbetaRealCplx, lnbetaCplxCplx, lnbetaError, lnbetaError, lnbetaError, lnbetaError, lnbetaError,  lnbetaError,  lnbetaError },
/*  4 Time          */ { lnbetaError,    lnbetaError,    lnbetaError,    lnbetaError, lnbetaError, lnbetaError, lnbetaError, lnbetaError,  lnbetaError,  lnbetaError },
/*  5 Date          */ { lnbetaError,    lnbetaError,    lnbetaError,    lnbetaError, lnbetaError, lnbetaError, lnbetaError, lnbetaError,  lnbetaError,  lnbetaError },
/*  6 String        */ { lnbetaError,    lnbetaError,    lnbetaError,    lnbetaError, lnbetaError, lnbetaError, lnbetaError, lnbetaError,  lnbetaError,  lnbetaError },
/*  7 Real34 mat    */ { lnbetaError,    lnbetaError,    lnbetaError,    lnbetaError, lnbetaError, lnbetaError, lnbetaError, lnbetaError,  lnbetaError,  lnbetaError },
/*  8 Complex34 mat */ { lnbetaError,    lnbetaError,    lnbetaError,    lnbetaError, lnbetaError, lnbetaError, lnbetaError, lnbetaError,  lnbetaError,  lnbetaError },
/*  9 Short integer */ { lnbetaError,    lnbetaError,    lnbetaError,    lnbetaError, lnbetaError, lnbetaError, lnbetaError, lnbetaError,  lnbetaError,  lnbetaError },
/* 10 Config data   */ { lnbetaError,    lnbetaError,    lnbetaError,    lnbetaError, lnbetaError, lnbetaError, lnbetaError, lnbetaError,  lnbetaError,  lnbetaError }
};

/********************************************//**
 * \brief Data type error in lnbeta
 *
 * \param void
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void lnbetaError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate lnBeta of %s with base %s", getRegisterDataTypeName(REGISTER_Y, true, false), getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnLnBeta:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and lnBeta(regX, RegY) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnLnBeta(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  lnBeta[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)]();

  adjustResult(REGISTER_X, true, true, REGISTER_X, -1, -1);
}



/*
 * This function checks argument for LnGamma function.
 * Returns true if function can be calculated, false otherwise. In case of error the function sets the appropriate value
 * into REGISTER_X and display the error message.
 */
#define RESULT_TYPE_UNKNOWN 0
#define RESULT_TYPE_REAL    1
#define RESULT_TYPE_COMPLEX 2

static bool_t _checkLnGammaArgs(int8_t *resultType, real_t *xReal, realContext_t *realContext) {
  bool_t result = true;
  *resultType = RESULT_TYPE_UNKNOWN;

  if(realIsInfinite(xReal)) {
    if(!getSystemFlag(FLAG_SPCRES)) {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      EXTRA_INFO_MESSAGE("_checkLnGammaArgs", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of lnbeta when flag D is not set");
    }
    else {
      realToReal34((real34IsPositive(xReal) ? const_plusInfinity : const_NaN), REGISTER_REAL34_DATA(REGISTER_X));
    }

    result = false;
  }
  else if(realCompareLessEqual(xReal, const_0)) { // x <= 0
    if(realIsAnInteger(xReal)) {
      if(!getSystemFlag(FLAG_SPCRES)) {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        EXTRA_INFO_MESSAGE("_checkLnGammaArgs", "cannot use a negative integer as X input of lnbeta when flag D is not set");
      }
      else {
        reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
        convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
      }

      result = false;
    }
    else { // x is negative and not an integer
      real_t tmp;

      realMinus(xReal, &tmp, realContext); // tmp = -x
      WP34S_Mod(&tmp, const_2, &tmp, realContext); // tmp = ?

      if(realCompareGreaterThan(&tmp, const_1)) { // the result is a real
          *resultType = RESULT_TYPE_REAL;
      }
      else { // the result is a complex
        if(getFlag(FLAG_CPXRES)) {
          *resultType = RESULT_TYPE_COMPLEX;
        }
        else { // Domain error
          displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
          EXTRA_INFO_MESSAGE("_checkLnGammaArgs", "cannot use a as X input of lnbeta if gamma(X)<0 when flag I is not set");
          result = false;
        }
      }
    }
  }
  else {
      *resultType = RESULT_TYPE_REAL;
  }

  return result;
}



static void _lnGammaReal(real_t *xReal, real_t *rReal, realContext_t *realContext) {
  WP34S_LnGamma(xReal, rReal, realContext);
}



static void _lnGammaComplex(real_t *xReal, real_t *rReal, real_t *rImag, realContext_t *realContext) {
  realCopy(xReal, rImag);
  WP34S_Gamma(xReal, xReal, realContext);
  realSetPositiveSign(xReal);
  WP34S_Ln(xReal, xReal, realContext);
  realCopy(xReal, rReal);
  realToIntegralValue(rImag, rImag, DEC_ROUND_FLOOR, realContext);
  realMultiply(rImag, const_pi, rImag, realContext);
}



static void _lnBetaComplex(real_t *xReal, real_t *xImag, real_t *yReal, real_t *yImag, real_t *rReal, real_t *rImag, realContext_t *realContext) {
  // LnBeta(x, y) := LnGamma(x) + LnGamma(y) - LnGamma(x+y)
  real_t tReal, tImag;

  complexLnGamma(xReal, xImag, &tReal, &tImag, realContext); // t = LnGamma(x)
  complexLnGamma(yReal, yImag, rReal, rImag, realContext);   // r = LnGamma(y)

  realAdd(rReal, &tReal, rReal, realContext); // r = LnGamma(x) + LnGamma(y)
  realAdd(rImag, &tImag, rImag, realContext);

  realAdd(xReal, yReal, &tReal, realContext); // t = x + y
  realAdd(xImag, yImag, &tImag, realContext);

  complexLnGamma(&tReal, &tImag, &tReal, &tImag, realContext); // t = LnGamma(x + y);

  realSubtract(rReal, &tReal, rReal, realContext); // r = LnGamma(x) + LnGamma(y) - LnGamma(x + y);
  realSubtract(rImag, &tImag, rImag, realContext);
}



static bool_t _lnBetaReal(real_t *xReal, real_t *yReal, real_t *rReal, real_t *rImag, realContext_t *realContext) {
  int8_t xflag, yflag, sflag;

  realAdd(xReal, yReal, rReal, realContext);  // r = x+y

  if(_checkLnGammaArgs(&xflag, xReal, realContext)
      && _checkLnGammaArgs(&yflag, yReal, realContext)
      && _checkLnGammaArgs(&sflag, rReal, realContext)) {
    real_t gxReal, gxImag;  // LnGamma(x)
    real_t gyReal, gyImag;  // LnGamma(y)
    real_t gsReal, gsImag;  // LnGamma(x+y)

    if(xflag==RESULT_TYPE_REAL) {
      _lnGammaReal(xReal, &gxReal, realContext);
      realCopy(const_0, &gxImag);
    }
    else {
      _lnGammaComplex(xReal, &gxReal, &gxImag, realContext);
    }

    if(yflag==RESULT_TYPE_REAL) {
      _lnGammaReal(yReal, &gyReal, realContext);
      realCopy(const_0, &gyImag);
    }
    else {
      _lnGammaComplex(yReal, &gyReal, &gyImag, realContext);
    }

    if(sflag==RESULT_TYPE_REAL) {
      _lnGammaReal(rReal, &gsReal, realContext);
      realCopy(const_0, &gsImag);
    }
    else {
      _lnGammaComplex(rReal, &gsReal, &gsImag, realContext);
    }

    realAdd(&gxReal, &gyReal, rReal, realContext); // r = LnGamma(x) + LnGamma(y)
    realAdd(&gxImag, &gyImag, rImag, realContext);

    realSubtract(rReal, &gsReal, rReal, realContext); // r = LnGamma(x) + LnGamma(y) - LnGamma(x+y)
    realSubtract(rImag, &gsImag, rImag, realContext);

    return true;
  }

  return false;
}



static void _lnBeta(real_t *x, real_t *y, realContext_t *realContext) {
  real_t rReal, rImag;

  if(_lnBetaReal(x, y, &rReal, &rImag, &ctxtReal39)) {
    if(realIsZero(&rImag)) {
      reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(&rReal, REGISTER_X);
    }
    else {
      reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
      convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
    }
  }
}



void lnbetaLonILonI(void) {
  real_t x, y;

  convertLongIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);
  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);

  _lnBeta(&x, &y, &ctxtReal39);
}



void lnbetaRealLonI(void) {
  real_t x, y;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);

  _lnBeta(&x, &y, &ctxtReal39);
}



void lnbetaCplxLonI(void) {
  real_t xReal, xImag, yReal, yImag, rReal, rImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Y), &yImag);

  convertLongIntegerRegisterToReal(REGISTER_X, &xReal, &ctxtReal39);
  realZero(&xImag);

  _lnBetaComplex(&xReal, &xImag, &yReal, &yImag, &rReal, &rImag, &ctxtReal39);

  reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
  convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
}



void lnbetaLonIReal(void) {
  real_t x, y;

  convertLongIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);

  _lnBeta(&x, &y, &ctxtReal39);
}



void lnbetaRealReal(void) {
  real_t x, y;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);

  _lnBeta(&x, &y, &ctxtReal39);
}



void lnbetaCplxReal(void) {
  real_t xReal, xImag, yReal, yImag, rReal, rImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Y), &yImag);

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  realZero(&xImag);

  _lnBetaComplex(&xReal, &xImag, &yReal, &yImag, &rReal, &rImag, &ctxtReal39);

  reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
  convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
}



void lnbetaLonICplx(void) {
  real_t xReal, xImag, yReal, yImag, rReal, rImag;

  convertLongIntegerRegisterToReal(REGISTER_Y, &yReal, &ctxtReal39);
  realZero(&yImag);

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  _lnBetaComplex(&xReal, &xImag, &yReal, &yImag, &rReal, &rImag, &ctxtReal39);

  convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
}



void lnbetaRealCplx(void)  {
  real_t xReal, xImag, yReal, yImag, rReal, rImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);
  realZero(&yImag);

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  _lnBetaComplex(&xReal, &xImag, &yReal, &yImag, &rReal, &rImag, &ctxtReal39);

  convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
}



void lnbetaCplxCplx(void)  {
  real_t xReal, xImag, yReal, yImag, rReal, rImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Y), &yImag);

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  _lnBetaComplex(&xReal, &xImag, &yReal, &yImag, &rReal, &rImag, &ctxtReal39);

  convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
}



void LnBeta(const real_t *x, const real_t *y, real_t *res, realContext_t *realContext) {
  real_t rReal, rImag;
  real_t xx, yy;

  realCopy(x, &xx); realCopy(y, &yy);
  if(_lnBetaReal(&xx, &yy, &rReal, &rImag, realContext) && realIsZero(&rImag)) {
    realCopy(&rReal, res);
  }
  else {
    realCopy(const_NaN, res);
  }
}
