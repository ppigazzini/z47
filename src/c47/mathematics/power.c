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
 * \file power.c
 ***********************************************/

#include "mathematics/power.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "integers.h"
#include "items.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/exp.h"
#include "mathematics/matrix.h"
#include "mathematics/toPolar.h"
#include "mathematics/toRect.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"



TO_QSPI void (* const power[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX |    regY ==>   1            2            3            4         5         6         7            8            9             10
//      V               Long integer Real34       Complex34    Time      Date      String    Real34 mat   Complex34 m  Short integer Config data
/*  1 Long integer  */ {powLonILonI, powRealLonI, powCplxLonI, powError, powError, powError, powRemaLonI, powCxmaLonI, powShoILonI,  powError},
/*  2 Real34        */ {powLonIReal, powRealReal, powCplxReal, powError, powError, powError, powRemaReal, powCxmaReal, powShoIReal,  powError},
/*  3 Complex34     */ {powLonICplx, powRealCplx, powCplxCplx, powError, powError, powError, powRemaCplx, powCxmaCplx, powShoICplx,  powError},
/*  4 Time          */ {powError,    powError,    powError,    powError, powError, powError, powError,    powError,    powError,     powError},
/*  5 Date          */ {powError,    powError,    powError,    powError, powError, powError, powError,    powError,    powError,     powError},
/*  6 String        */ {powError,    powError,    powError,    powError, powError, powError, powError,    powError,    powError,     powError},
/*  7 Real34 mat    */ {powError,    powError,    powError,    powError, powError, powError, powError,    powError,    powError,     powError},
/*  8 Complex34 mat */ {powError,    powError,    powError,    powError, powError, powError, powError,    powError,    powError,     powError},
/*  9 Short integer */ {powLonIShoI, powRealShoI, powCplxShoI, powError, powError, powError, powRemaShoI, powCxmaShoI, powShoIShoI,  powError},
/* 10 Config data   */ {powError,    powError,    powError,    powError, powError, powError, powError,    powError,    powError,     powError}
};



/********************************************//**
 * \brief Data type error in power
 *
 * \param[in] unusedButMandatoryParameter
 * \return void
 ***********************************************/
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  void powError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot raise %s", getRegisterDataTypeName(REGISTER_Y, true, false));
    sprintf(errorMessage + ERROR_MESSAGE_LENGTH/2, "to %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnPower:", errorMessage, errorMessage + ERROR_MESSAGE_LENGTH/2, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



void PowerReal(const real_t *y, const real_t *x, real_t *res, realContext_t *realContext) {
  real_t lny;
  if(realIsNegative(y) && realIsAnInteger(x) && realIsPositive(x)) {
    realDivideRemainder(x, const_2, &lny, realContext);
    bool_t isOdd = !realIsZero(&lny);
    realCopyAbs(y, &lny);
    WP34S_Ln(&lny, &lny, realContext);
    realMultiply(x, &lny, res, realContext);
    realExp(res, res, realContext);
    fflush(stdout);
    if(isOdd) {
      realChangeSign(res);
    }
  }
  else {
    WP34S_Ln(y, &lny, realContext);
    realMultiply(x, &lny, res, realContext);
    realExp(res, res, realContext);
  }
}




/********************************************//**
 * \brief regX ==> regL and regY ^ regX ==> regX
 * Drops Y, enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter
 * \return void
 ***********************************************/
void fnPower(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  power[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)]();

  adjustResult(REGISTER_X, true, true, REGISTER_X, REGISTER_Y, -1);
}



/******************************************************************************************************************************************************************************************/
/* long integer ^ ...                                                                                                                                                                     */
/******************************************************************************************************************************************************************************************/

void longIntegerPower(longInteger_t base, longInteger_t exponent, longInteger_t result) {
  if(longIntegerIsZero(exponent)) {
    uIntToLongInteger(1, result);
  }
  else if(longIntegerIsZero(base)) {
    uIntToLongInteger(0, result);
  }
  else if((longIntegerCompareInt(base, 1) == 0 || longIntegerCompareInt(base, -1) == 0) && longIntegerCompareInt(exponent, -1) == 0) {
    longIntegerCopy(base, result);
  }
  else if(longIntegerIsNegative(exponent)) {
    uIntToLongInteger(0, result);
  }
  else {
    uIntToLongInteger(1, result);

    while(!longIntegerIsZero(exponent)) {
      if(longIntegerIsOdd(exponent)) {
       longIntegerMultiply(result, base, result);
      }

      longIntegerDivide2(exponent, exponent);

      if(!longIntegerIsZero(exponent)) {
        longIntegerSquare(base, base);
      }
    }
  }
}



/********************************************//**
 * \brief Y(long integer) ^ X(long integer) ==> X(long integer)
 *
 * \param void
 * \return void
 ***********************************************/
void powLonILonI(void) {
  longInteger_t base, exponent;

  convertLongIntegerRegisterToLongInteger(REGISTER_Y, base);
  convertLongIntegerRegisterToLongInteger(REGISTER_X, exponent);

  if(longIntegerIsZero(exponent) && longIntegerIsZero(base)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function powLonILonI: Cannot calculate 0^0!", NULL, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

    longIntegerFree(base);
    longIntegerFree(exponent);
    return;
  }

  if((longIntegerCompareInt(base, 1) == 0 || longIntegerCompareInt(base, -1) == 0) && longIntegerCompareInt(exponent, -1) == 0) {
    convertLongIntegerToLongIntegerRegister(base, REGISTER_X);
    longIntegerFree(base);
    longIntegerFree(exponent);
    return;
  }
  else if(longIntegerIsNegative(exponent)) {
    convertLongIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
    powLonIReal();
    return;
  }

  longInteger_t result;

  longIntegerInit(result);
  longIntegerPower(base, exponent, result);

  convertLongIntegerToLongIntegerRegister(result, REGISTER_X);

  longIntegerFree(result);
  longIntegerFree(base);
  longIntegerFree(exponent);
}



/********************************************//**
 * \brief Y(long integer) ^ X(short integer) ==> X(long integer)
 *
 * \param void
 * \return void
 ***********************************************/
void powLonIShoI(void) {
  convertShortIntegerRegisterToLongIntegerRegister(REGISTER_X, REGISTER_X);
  powLonILonI();
}



/********************************************//**
 * \brief Y(short integer) ^ X(long integer) ==> X(short integer)
 *
 * \param void
 * \return void
 ***********************************************/
void powShoILonI(void) {
  int32_t base = getRegisterShortIntegerBase(REGISTER_Y);
  real_t x, a;
  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);

  convertShortIntegerRegisterToLongIntegerRegister(REGISTER_Y, REGISTER_Y);
  powLonILonI();
  if(realIsPositive(&x)) {
    convertLongIntegerRegisterToReal(REGISTER_X, &a, &ctxtReal39);
    convertLongIntegerRegisterToShortIntegerRegister(REGISTER_X, REGISTER_X);
    setRegisterShortIntegerBase(REGISTER_X, base);
    convertShortIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
    if(realCompareEqual(&x, &a)) {
      clearSystemFlag(FLAG_OVERFLOW);
    }
    else {
      setSystemFlag(FLAG_OVERFLOW);
    }
  }
}



/********************************************//**
 * \brief Y(long integer) ^ X(real34) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void powLonIReal(void) {
  convertLongIntegerRegisterToReal34Register(REGISTER_Y, REGISTER_Y);
  powRealReal();
}



/********************************************//**
 * \brief Y(real34) ^ X(long integer) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void powRealLonI(void) {
  convertLongIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
  powRealReal();
}



/********************************************//**
 * \brief Y(long integer) ^ X(complex34) ==> X(complex34)
 *
 * \param void
 * \return void
 ***********************************************/
void powLonICplx(void) {
  real_t y;

  convertLongIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);
  reallocateRegister(REGISTER_Y, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
  convertRealToReal34ResultRegister(&y, REGISTER_Y);
  real34Zero(REGISTER_IMAG34_DATA(REGISTER_Y));
  powCplxCplx();
}



/********************************************//**
 * \brief Y(complex34) ^ X(long integer) ==> X(complex34)
 *
 * \param void
 * \return void
 ***********************************************/
void powCplxLonI(void) {
  real_t x;

  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
  reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
  convertRealToReal34ResultRegister(&x, REGISTER_X);
  real34Zero(REGISTER_IMAG34_DATA(REGISTER_X));
  powCplxCplx();
}



/******************************************************************************************************************************************************************************************/
/* time ^ ...                                                                                                                                                                             */
/******************************************************************************************************************************************************************************************/

/******************************************************************************************************************************************************************************************/
/* date ^ ...                                                                                                                                                                             */
/******************************************************************************************************************************************************************************************/

/******************************************************************************************************************************************************************************************/
/* string ^ ...                                                                                                                                                                           */
/******************************************************************************************************************************************************************************************/

/******************************************************************************************************************************************************************************************/
/* real34 matrix ^ ...                                                                                                                                                                    */
/******************************************************************************************************************************************************************************************/

/********************************************//**
 * \brief Y(real34 matrix) ^ X(long integer) ==> X(real34 matrix)
 *
 * \param void
 * \return void
 ***********************************************/
void powRemaLonI(void) {
  elementwiseRemaLonI(powRealLonI);
}



/********************************************//**
 * \brief Y(real34 matrix) ^ X(short integer) ==> X(real34 matrix)
 *
 * \param void
 * \return void
 ***********************************************/
void powRemaShoI(void) {
  elementwiseRemaShoI(powRealShoI);
}



/********************************************//**
 * \brief Y(real34 matrix) ^ X(real34) ==> X(real34 matrix)
 *
 * \param void
 * \return void
 ***********************************************/
void powRemaReal(void) {
  elementwiseRemaReal(powRealReal);
}



/********************************************//**
 * \brief Y(real34 matrix) ^ X(complex34) ==> X(complex34 matrix)
 *
 * \param void
 * \return void
 ***********************************************/
void powRemaCplx(void) {
  convertReal34MatrixRegisterToComplex34MatrixRegister(REGISTER_Y, REGISTER_Y);
  powCxmaCplx();
}



/******************************************************************************************************************************************************************************************/
/* complex34 matrix ^ ...                                                                                                                                                                 */
/******************************************************************************************************************************************************************************************/

/********************************************//**
 * \brief Y(complex34 matrix) ^ X(long integer) ==> X(complex34 matrix)
 *
 * \param void
 * \return void
 ***********************************************/
void powCxmaLonI(void) {
  elementwiseCxmaLonI(powCplxLonI);
}



/********************************************//**
 * \brief Y(complex34 matrix) ^ X(short integer) ==> X(complex34 matrix)
 *
 * \param void
 * \return void
 ***********************************************/
void powCxmaShoI(void) {
  elementwiseCxmaShoI(powCplxShoI);
}



/********************************************//**
 * \brief Y(complex34 matrix) ^ X(real34) ==> X(complex34 matrix)
 *
 * \param void
 * \return void
 ***********************************************/
void powCxmaReal(void) {
  elementwiseCxmaReal(powCplxReal);
}



/********************************************//**
 * \brief Y(complex34 matrix) ^ X(complex34) ==> X(complex34 matrix)
 *
 * \param void
 * \return void
 ***********************************************/
void powCxmaCplx(void) {
  elementwiseCxmaCplx(powCplxCplx);
}



/******************************************************************************************************************************************************************************************/
/* short integer ^ ...                                                                                                                                                                    */
/******************************************************************************************************************************************************************************************/

/********************************************//**
 * \brief Y(short integer) ^ X(short integer) ==> X(short integer)
 *
 * \param void
 * \return void
 ***********************************************/
void powShoIShoI(void) {
  int32_t exponentSign, baseSign;

  uint64_t exponent = WP34S_extract_value(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)), &exponentSign);
  uint64_t base = WP34S_extract_value(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_Y)), &baseSign);

  if(base == 1 && exponent == 1 && exponentSign) {
    setRegisterShortIntegerBase(REGISTER_X, getRegisterShortIntegerBase(REGISTER_Y));
    *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = *(REGISTER_SHORT_INTEGER_DATA(REGISTER_Y));
    return;
  }
  else if(exponentSign) { // exponent is negative
    convertShortIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
    convertShortIntegerRegisterToReal34Register(REGISTER_Y, REGISTER_Y);
    powRealReal();
  }
  else {
    setRegisterShortIntegerBase(REGISTER_X, getRegisterShortIntegerBase(REGISTER_Y));
    *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = WP34S_intPower(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_Y)), *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)));
  }
}



/********************************************//**
 * \brief Y(short integer) ^ X(real34) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void powShoIReal(void) {
  convertShortIntegerRegisterToReal34Register(REGISTER_Y, REGISTER_Y);
  powRealReal();
}



/********************************************//**
 * \brief Y(real34) ^ X(short integer) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void powRealShoI(void) {
  convertShortIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
  powRealReal();
}



/********************************************//**
 * \brief Y(short integer) ^ X(complex34) ==> X(complex34)
 *
 * \param void
 * \return void
 ***********************************************/
void powShoICplx(void) {
  real_t y;

  convertShortIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);
  reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
  convertRealToReal34ResultRegister(&y, REGISTER_Y);
  real34Zero(REGISTER_IMAG34_DATA(REGISTER_Y));
  powCplxCplx();
}



/********************************************//**
 * \brief Y(complex34) ^ X(short integer) ==> X(complex34)
 *
 * \param void
 * \return void
 ***********************************************/
void powCplxShoI(void) {
  real_t x;

  convertShortIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
  reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
  convertRealToReal34ResultRegister(&x, REGISTER_X);
  real34Zero(REGISTER_IMAG34_DATA(REGISTER_X));
  powCplxCplx();
}



/******************************************************************************************************************************************************************************************/
/* real34 ^ ...                                                                                                                                                                           */
/******************************************************************************************************************************************************************************************/

/********************************************//**
 * \brief Y(real34) ^ X(real34) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void powRealReal(void) {
  if(real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_Y))) {
    if(real34IsZero(REGISTER_REAL34_DATA(REGISTER_X))) {
      convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
    }
    else {
      if(real34IsPositive(REGISTER_REAL34_DATA(REGISTER_X)) && real34IsAnInteger(REGISTER_REAL34_DATA(REGISTER_X))) {
        longInteger_t lgInt;
        convertReal34ToLongInteger(REGISTER_REAL34_DATA(REGISTER_X), lgInt, DEC_ROUND_DOWN);
        if(longIntegerIsEven(lgInt)) {
          convertRealToReal34ResultRegister(const_plusInfinity, REGISTER_X);
        }
        else {
          convertRealToReal34ResultRegister(const_minusInfinity, REGISTER_X);
        }
        longIntegerFree(lgInt);
      }
      else {
        convertRealToReal34ResultRegister(const_plusInfinity, REGISTER_X);
      }
    }
    setRegisterAngularMode(REGISTER_X, amNone);
    return;
  }

  real_t y, x;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);

  real_t res;
  PowerReal(&y, &x, &res, &ctxtReal39);

  if(realIsNaN(&res) && realIsNegative(&y) && !realIsAnInteger(&x)) {
    if(getFlag(FLAG_CPXRES)) {
      reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(&x, REGISTER_X);
      real34Zero(REGISTER_IMAG34_DATA(REGISTER_X));

      reallocateRegister(REGISTER_Y, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(&y, REGISTER_Y);
      real34Zero(REGISTER_IMAG34_DATA(REGISTER_Y));

      powCplxCplx();
      return;
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function powRealReal:", "cannot do complex results if CPXRES is not set", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }
  }

  convertRealToReal34ResultRegister(&res, REGISTER_X);
  setRegisterAngularMode(REGISTER_X, amNone);
}



/********************************************//**
 * \brief Y(real34) ^ X(complex34) ==> X(complex34)
 *
 * \param void
 * \return void
 ***********************************************/
void powRealCplx(void) {
  real_t y;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
  reallocateRegister(REGISTER_Y, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
  convertRealToReal34ResultRegister(&y, REGISTER_Y);
  real34Zero(REGISTER_IMAG34_DATA(REGISTER_Y));
  powCplxCplx();
}



/********************************************//**
 * \brief Y(complex34) ^ X(real34) ==> X(complex34)
 *
 * \param void
 * \return void
 ***********************************************/
void powCplxReal(void) {
  real_t x;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
  reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
  convertRealToReal34ResultRegister(&x, REGISTER_X);
  real34Zero(REGISTER_IMAG34_DATA(REGISTER_X));
  powCplxCplx();
}



/******************************************************************************************************************************************************************************************/
/* complex34 + ...                                                                                                                                                                        */
/******************************************************************************************************************************************************************************************/

/*
 * Calculate y^x for complex numbers.
 */
uint8_t PowerComplex(const real_t *yReal, const real_t *yImag, const real_t *xReal, const real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext) {
  uint8_t errorCode = ERROR_NONE;

  if(realIsInfinite(yReal) || realIsInfinite(yImag)) {
      if(realIsZero(xReal) && realIsZero(xImag)) {
          realCopy(const_NaN, rReal);
          realCopy(const_NaN, rImag);
      }
      else {
          realCopy(const_plusInfinity, rReal);
          realCopy(const_plusInfinity, rImag);
      }
  }
  else if(realIsZero(yReal) && realIsZero(yImag)) {
      if(realIsZero(xReal)) {
          realCopy(const_NaN, rReal);
          realCopy(const_NaN, rImag);
      }
      else {
          realCopy(const_0, rReal);
          realCopy(const_0, rImag);
      }
  }
  else {
      real_t theta;
      real_t tmp;

      realRectangularToPolar(yReal, yImag, rReal, &theta, realContext);
      WP34S_Ln(rReal, rReal, realContext);

      realMultiply(rReal, xImag, rImag, realContext);
      realFMA(&theta, xReal, rImag, rImag, realContext);
      realChangeSign(&theta);

      realMultiply(rReal, xReal, rReal, realContext);
      realFMA(&theta, xImag, rReal, rReal, realContext);

      realExp(rReal, &tmp, realContext);
      realPolarToRectangular(const_1, rImag, rReal, rImag, realContext);
      realMultiply(&tmp, rImag, rImag, realContext);
      realMultiply(&tmp, rReal, rReal, realContext);
  }

  return errorCode;
}

/********************************************//**
 * \brief Y(complex34) ^ X(complex34) ==> X(complex34)
 *
 * \param void
 * \return void
 ***********************************************/
void powCplxCplx(void) {
  real_t yReal, yImag, xReal, xImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Y), &yImag);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  real_t rReal, rImag;

  uint8_t errorCode = PowerComplex(&yReal, &yImag, &xReal, &xImag, &rReal, &rImag, &ctxtReal39);

  if(errorCode!=ERROR_NONE) {
    displayCalcErrorMessage(errorCode, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "cannot raise %s", getRegisterDataTypeName(REGISTER_Y, true, false));
      sprintf(errorMessage + ERROR_MESSAGE_LENGTH/2, "to %s", getRegisterDataTypeName(REGISTER_X, true, false));
      moreInfoOnError("In function fnPower:", errorMessage, errorMessage + ERROR_MESSAGE_LENGTH/2, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  else {
    convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
  }
}
