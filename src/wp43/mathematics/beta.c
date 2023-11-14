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
 * \file beta.c
 ***********************************************/

#include "mathematics/beta.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/division.h"
#include "mathematics/multiplication.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "wp43.h"

TO_QSPI void (* const beta[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])() = {
// regX |    regY ==>    1             2             3             4          5          6          7          8          9          10
//      V                Long integer  Real34        Complex34     Time       Date       String     Real34 mat Complex34  mat Short  Config data
/*  1 Long integer  */ { betaLonILonI, betaRealLonI, betaCplxLonI, betaError, betaError, betaError, betaError, betaError, betaError, betaError },
/*  2 Real34        */ { betaLonIReal, betaRealReal, betaCplxReal, betaError, betaError, betaError, betaError, betaError, betaError, betaError },
/*  3 Complex34     */ { betaLonICplx, betaRealCplx, betaCplxCplx, betaError, betaError, betaError, betaError, betaError, betaError, betaError },
/*  4 Time          */ { betaError,    betaError,    betaError,    betaError, betaError, betaError, betaError, betaError, betaError, betaError },
/*  5 Date          */ { betaError,    betaError,    betaError,    betaError, betaError, betaError, betaError, betaError, betaError, betaError },
/*  6 String        */ { betaError,    betaError,    betaError,    betaError, betaError, betaError, betaError, betaError, betaError, betaError },
/*  7 Real34 mat    */ { betaError,    betaError,    betaError,    betaError, betaError, betaError, betaError, betaError, betaError, betaError },
/*  8 Complex34 mat */ { betaError,    betaError,    betaError,    betaError, betaError, betaError, betaError, betaError, betaError, betaError },
/*  9 Short integer */ { betaError,    betaError,    betaError,    betaError, betaError, betaError, betaError, betaError, betaError, betaError },
/* 10 Config data   */ { betaError,    betaError,    betaError,    betaError, betaError, betaError, betaError, betaError, betaError, betaError }
};

/********************************************//**
 * \brief Data type error in beta
 *
 * \param void
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void betaError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate Beta of (%s, %s)", getRegisterDataTypeName(REGISTER_Y, true, false), getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnBeta:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)


/********************************************//**
 * \brief regX ==> regL and beta(regX, RegY) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnBeta(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  beta[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)]();

  adjustResult(REGISTER_X, true, true, REGISTER_X, -1, -1);
}


#if !defined(SAVE_SPACE_DM42_12)
static bool_t _beta(real_t *xReal, real_t *xImag, real_t *yReal, real_t *yImag, real_t *rReal, real_t *rImag, realContext_t *realContext) {
  // Beta(x, y) := Gamma(x) * Gamma(y) / Gamma(x+y)
  real_t tReal, tImag;

  if(realCompareLessEqual(xReal, const_0)) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "cannot calculate Beta of (%s, %s) with Re(x)<=0", getRegisterDataTypeName(REGISTER_Y, true, false), getRegisterDataTypeName(REGISTER_X, true, false));
      moreInfoOnError("In function fnBeta:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return false;
  }
  else if(realCompareLessEqual(yReal, const_0)) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "cannot calculate Beta of (%s, %s with Re(y)<=0", getRegisterDataTypeName(REGISTER_Y, true, false), getRegisterDataTypeName(REGISTER_X, true, false));
      moreInfoOnError("In function fnBeta:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return false;
  }

  WP34S_ComplexGamma(xReal, xImag, &tReal, &tImag, realContext);              // t = Gamma(x)
  WP34S_ComplexGamma(yReal, yImag, rReal, rImag, realContext);                // r = Gamma(y)

  mulComplexComplex(rReal, rImag, &tReal, &tImag, rReal, rImag, realContext); // r = Gamma(x) * Gamma(y)

  realAdd(xReal, yReal, &tReal, realContext);                             // t = x + y
  realAdd(xImag, yImag, &tImag, realContext);

  WP34S_ComplexGamma(&tReal, &tImag, &tReal, &tImag, realContext);            // t = Gamma(x + y);
  divComplexComplex(rReal, rImag, &tReal, &tImag, rReal, rImag, realContext); // r = Gamma(x) * Gamma(y) / Gamma(x + y);

  if(realIsNaN(rImag) || realIsNaN(rReal)) {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "cannot calculate Beta of (%s, %s) out of range", getRegisterDataTypeName(REGISTER_Y, true, false), getRegisterDataTypeName(REGISTER_X, true, false));
      moreInfoOnError("In function fnBeta:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return false;
  }

  return true;
}


static void _betaComplex(real_t *xReal, real_t *xImag, real_t *yReal, real_t *yImag, realContext_t *realContext) {
  real_t rReal, rImag;

  if(_beta(xReal, xImag, yReal, yImag, &rReal, &rImag, realContext)) {
    reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
    convertRealToReal34ResultRegister(&rReal, REGISTER_X);
    convertRealToImag34ResultRegister(&rImag, REGISTER_X);
  }
}


static void _betaReal(real_t *xReal, real_t *yReal, realContext_t *realContext) {
  real_t rReal, rImag;
  real_t xImag, yImag;

  realZero(&xImag);
  realZero(&yImag);

  if(_beta(xReal, &xImag, yReal, &yImag, &rReal, &rImag, realContext)) {
    if(realIsZero(&rImag)) {
      reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(&rReal, REGISTER_X);
    }
    else {
      reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(&rReal, REGISTER_X);
      convertRealToImag34ResultRegister(&rImag, REGISTER_X);
    }
  }
}
#endif // !SAVE_SPACE_DM42_12


void betaLonILonI(void) {
#if !defined(SAVE_SPACE_DM42_12)
  real_t x, y;

  convertLongIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);
  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);

  _betaReal(&x, &y, &ctxtReal39);
#endif // !SAVE_SPACE_DM42_12
}


void betaRealLonI(void) {
#if !defined(SAVE_SPACE_DM42_12)
  real_t x, y;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);

  _betaReal(&x, &y, &ctxtReal39);
#endif // !SAVE_SPACE_DM42_12
}


void betaCplxLonI(void) {
#if !defined(SAVE_SPACE_DM42_12)
  real_t xReal, xImag, yReal, yImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Y), &yImag);

  convertLongIntegerRegisterToReal(REGISTER_X, &xReal, &ctxtReal39);
  realZero(&xImag);

  _betaComplex(&xReal, &xImag, &yReal, &yImag, &ctxtReal39);
#endif // !SAVE_SPACE_DM42_12
}


void betaLonIReal(void) {
#if !defined(SAVE_SPACE_DM42_12)
  real_t x, y;

  convertLongIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);

  _betaReal(&x, &y, &ctxtReal39);
#endif // !SAVE_SPACE_DM42_12
}


void betaRealReal(void) {
#if !defined(SAVE_SPACE_DM42_12)
  real_t x, y;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);

  _betaReal(&x, &y, &ctxtReal39);
#endif // !SAVE_SPACE_DM42_12
}


void betaCplxReal(void) {
#if !defined(SAVE_SPACE_DM42_12)
  real_t xReal, xImag, yReal, yImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Y), &yImag);

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  realZero(&xImag);

  _betaComplex(&xReal, &xImag, &yReal, &yImag, &ctxtReal39);
#endif // !SAVE_SPACE_DM42_12
}


void betaLonICplx(void) {
#if !defined(SAVE_SPACE_DM42_12)
  real_t xReal, xImag, yReal, yImag;

  convertLongIntegerRegisterToReal(REGISTER_Y, &yReal, &ctxtReal39);
  realZero(&yImag);

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  _betaComplex(&xReal, &xImag, &yReal, &yImag, &ctxtReal39);
#endif // !SAVE_SPACE_DM42_12
}


void betaRealCplx(void)  {
#if !defined(SAVE_SPACE_DM42_12)
  real_t xReal, xImag, yReal, yImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);
  realZero(&yImag);

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  _betaComplex(&xReal, &xImag, &yReal, &yImag, &ctxtReal39);
#endif // !SAVE_SPACE_DM42_12
}


void betaCplxCplx(void)  {
#if !defined(SAVE_SPACE_DM42_12)
  real_t xReal, xImag, yReal, yImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Y), &yImag);

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  _betaComplex(&xReal, &xImag, &yReal, &yImag, &ctxtReal39);
#endif // !SAVE_SPACE_DM42_12
}
