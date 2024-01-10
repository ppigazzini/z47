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
 * \file gd.c
 ***********************************************/

#include "mathematics/gd.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "mathematics/arctan.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/exp.h"
#include "mathematics/ln.h"
#include "mathematics/tan.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"

TO_QSPI void (* const gd[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(uint16_t) = {
// regX ==> 1            2       3         4            5            6            7            8            9             10
//          Long integer Real34  Complex34 Time         Date         String       Real34 mat   Complex34 m  Short integer Config data
            gdLonI,      gdReal, gdCplx,   gdTypeError, gdTypeError, gdTypeError, gdTypeError, gdTypeError, gdTypeError,  gdTypeError
};

/********************************************//**
 * \brief Data type error in gd
 *
 * \param void
 * \return void
 ***********************************************/
void gdTypeError(uint16_t gdOrInvGd) {
  displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
  #if(EXTRA_INFO_ON_CALC_ERROR == 1)
    if(gdOrInvGd==GD_DIRECT_FUNCTION) {
      sprintf(errorMessage, "cannot calculate gd(%s)", getRegisterDataTypeName(REGISTER_X, false, false));
      moreInfoOnError("In function fnGd:", errorMessage, NULL, NULL);
    }
    else {
      sprintf(errorMessage, "cannot calculate invGd(%s)", getRegisterDataTypeName(REGISTER_X, false, false));
      moreInfoOnError("In function fnInvGd:", errorMessage, NULL, NULL);
    }
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
}

static void gdError(uint16_t gdOrInvGd, uint8_t errorCode) {
  displayCalcErrorMessage(errorCode, ERR_REGISTER_LINE, REGISTER_X);
  #if(EXTRA_INFO_ON_CALC_ERROR == 1)
    if(gdOrInvGd==GD_DIRECT_FUNCTION) {
      sprintf(errorMessage, "cannot calculate gd(%s)", getRegisterDataTypeName(REGISTER_X, false, false));
      moreInfoOnError("In function fnGd:", errorMessage, NULL, NULL);
    }
    else {
      sprintf(errorMessage, "cannot calculate invGd(%s)", getRegisterDataTypeName(REGISTER_X, false, false));
      moreInfoOnError("In function fnInvGd:", errorMessage, NULL, NULL);
    }
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
}


/********************************************//**
 * \brief regX ==> regL and gd(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnGd(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }
  gd[getRegisterDataType(REGISTER_X)](GD_DIRECT_FUNCTION);
  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}

/********************************************//**
 * \brief regX ==> regL and invGd(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnInvGd(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }
  gd[getRegisterDataType(REGISTER_X)](GD_INVERSE_FUNCTION);
  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}

void gdLonI(uint16_t gdOrInvGd) {
  real_t x;

  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);

  uint8_t errorCode = (gdOrInvGd == GD_DIRECT_FUNCTION) ? GudermannianReal(&x, &x, &ctxtReal39)
                                                        : InverseGudermannianReal(&x, &x, &ctxtReal39);

  if(errorCode != ERROR_NONE) {
    gdError(gdOrInvGd, errorCode);
  }
  else {
    reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
    convertRealToReal34ResultRegister(&x, REGISTER_X);
  }
}

void gdReal(uint16_t gdOrInvGd) {
  real_t x;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);

  uint8_t errorCode = (gdOrInvGd == GD_DIRECT_FUNCTION) ? GudermannianReal(&x, &x, &ctxtReal39)
                                                        : InverseGudermannianReal(&x, &x, &ctxtReal39);

  if(errorCode != ERROR_NONE) {
    gdError(gdOrInvGd, errorCode);
  }
  else {
    convertRealToReal34ResultRegister(&x, REGISTER_X);
  }
}

void gdCplx(uint16_t gdOrInvGd) {
  real_t xReal, xImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  uint8_t errorCode;

  if(realIsZero(&xImag)) {
    errorCode = (gdOrInvGd == GD_DIRECT_FUNCTION) ? GudermannianReal(&xReal, &xReal, &ctxtReal39)
                                                  : InverseGudermannianReal(&xReal, &xReal, &ctxtReal39);
  }
  else {
    errorCode = (gdOrInvGd == GD_DIRECT_FUNCTION) ? GudermannianComplex(&xReal, &xImag, &xReal, &xImag, &ctxtReal39)
                                                  : InverseGudermannianComplex(&xReal, &xImag, &xReal, &xImag, &ctxtReal39);
  }

  if(errorCode != ERROR_NONE) {
    gdError(gdOrInvGd, errorCode);
  }
  else {
    convertComplexToResultRegister(&xReal, &xImag, REGISTER_X);
  }
}

uint8_t GudermannianReal(const real_t *x, real_t *res, realContext_t *realContext) {
  if(realIsInfinite(x)) {
    if(realIsPositive(x)) {
      realCopy(const_piOn2, res);
    }
    else {
      realCopy(const_piOn2, res);
      realChangeSign(res);
    }
  }
  else {
    /*
     * Gd(x) = 2 * Arctan(Exp(x)) - PI/2
     */
    realExp(x, res, realContext);
    WP34S_Atan(res, res, realContext);
    realMultiply(res, const_2, res, realContext);
    realSubtract(res, const_piOn2, res, realContext);

    /*
     * Gd(x) = ArchSin(Tanh(x))
     */
    //WP34S_Tanh(x, res, realContext);
    //WP34S_Asin(res, res, realContext);
  }

  return ERROR_NONE;
}

uint8_t GudermannianComplex(const real_t *xReal, const real_t *xImag, real_t *resReal, real_t *resImag, realContext_t *realContext) {
  /*
   * This implementation provides same results as Mathematica.
   * Gd(x) = 2 * Arctan(Exp(x)) - PI/2
   */
  expComplex(xReal, xImag, resReal, resImag, realContext);
  ArctanComplex(resReal, resImag, resReal,resImag, realContext);

  realMultiply(resReal, const_2, resReal, realContext);
  realMultiply(resImag, const_2, resImag, realContext);
  realSubtract(resReal, const_piOn2, resReal, realContext);

  /*
   * Gd(x) = ArchSin(Tanh(x))
   */
  //TanhComplex(xReal, xImag, resReal, resImag, realContext);
  //ArcsinComplex(resReal, resImag, resReal, resImag, realContext);

  return ERROR_NONE;
}

uint8_t InverseGudermannianReal(const real_t *x, real_t *res, realContext_t *realContext) {
  uint8_t result = ERROR_NONE;

  /*
   * InvGd(x) = Ln(Tan(x/2 + PI/4))
   */
  if(!realIsNaN(x) && realCompareAbsLessThan(x, const_piOn2)) {
    if(realIsZero(x)) {
      realCopy(const_0, res);
    }
    else {
      real_t sin, cos;

      /*
       * InvGd(x) = Ln(Tan(x/2 + PI/4))
       * -PI/2 < x < PI/2
       */
      realMultiply(x, const_1on2, res, realContext);       // r = x/2
      realAdd(res, const_piOn4, res, realContext);    // r = x/2 + pi/4
      WP34S_Cvt2RadSinCosTan(res, amRadian, &sin, &cos, res, &ctxtReal39); // r = Tan(x/2 + pi/4)
      WP34S_Ln(res, res, &ctxtReal39);                // r = Ln(Tan(x/2 + pi/4))

      /*
       * InvGd(x) = ArcSinh(Tan(x))
       * -PI/2 < x < PI/2
       */
      //WP34S_Cvt2RadSinCosTan(x, amRadian, &sin, &cos, res, &ctxtReal39);
      //ArcsinhReal(res, res, &ctxtReal39);
    }
  }
  else {
    result = ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
  }

  return result;
}

uint8_t InverseGudermannianComplex(const real_t *xReal, const real_t *xImag, real_t *resReal, real_t *resImag, realContext_t *realContext) {
  /*
   * This implementation provides same results as Mathematica.
   * InvGd(x) = Ln(Tan(x / 2 + PI / 4))
   */
  realMultiply(xReal, const_1on2, resReal, realContext);               // r = x/2
  realMultiply(xImag, const_1on2, resImag, realContext);

  realAdd(xReal, const_piOn4, resReal, realContext);              // r = x/2 + pi/2

  TanComplex(resReal, resImag, resReal, resImag, realContext);    // r = Tan(x/2 + pi/4)
  lnComplex(resReal, resImag, resReal, resImag, realContext);     // r = Ln(Tan(x/2 + pi/4))

  /*
   * InvGd(x) = ArcSinh(Tan(x))
   */
  //real_t tReal, tImag;
  //
  //TanComplex(xReal, xImag, &tReal, &tImag, realContext);
  //ArcsinhComplex(&tReal, &tImag, resReal, resImag, realContext);

  return ERROR_NONE;
}
