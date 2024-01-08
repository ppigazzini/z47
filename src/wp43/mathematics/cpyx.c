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
 * \file cpyx.c
 ***********************************************/

#include "mathematics/cpyx.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "integers.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/exp.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "wp43.h"

static void cpyxDataTypeError(uint16_t);

TO_QSPI void (* const cpyx[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(uint16_t) = {
// regX |    regY ==>    1                  2                  3                  4                  5                  6                  7                  8                  9                  10
//      V                Long integer       Real34             Complex34          Time               Date               String             Real34 mat         Complex34 mat      Short integer      Config data
/*  1 Long integer  */ { cpyxLonILonI,      cpyxRealLonI,      cpyxCplxLonI,      cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxShoILonI,      cpyxDataTypeError},
/*  2 Real34        */ { cpyxLonIReal,      cpyxRealReal,      cpyxCplxReal,      cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxShoIReal,      cpyxDataTypeError},
/*  3 Complex34     */ { cpyxLonICplx,      cpyxRealCplx,      cpyxCplxCplx,      cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxShoICplx,      cpyxDataTypeError},
/*  4 Time          */ { cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError},
/*  5 Date          */ { cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError},
/*  6 String        */ { cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError},
/*  7 Real34 mat    */ { cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError},
/*  8 Complex34 mat */ { cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError},
/*  9 Short integer */ { cpyxLonIShoI,      cpyxRealShoI,      cpyxCplxShoI,      cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxShoIShoI,      cpyxDataTypeError},
/* 10 Config data   */ { cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError, cpyxDataTypeError}
};

//=============================================================================
// Error handling
//-----------------------------------------------------------------------------


/********************************************//**
 * \brief Data type error in Cyx
 *
 * \param[in] unusedButMandatoryParameter
 * \return void
 ***********************************************/
static void cpyxDataTypeError(uint16_t unused) {
  displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);

  #if(EXTRA_INFO_ON_CALC_ERROR == 1)
    sprintf(errorMessage, "cannot raise %s", getRegisterDataTypeName(REGISTER_Y, true, false));
    sprintf(errorMessage + ERROR_MESSAGE_LENGTH/2, "to %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnCyx/fnPyx:", errorMessage, errorMessage + ERROR_MESSAGE_LENGTH/2, NULL);
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
}

//=============================================================================
// Cyx/Pyx calculation function
//-----------------------------------------------------------------------------

void logCyxReal(real_t *y, real_t *x, real_t *result, realContext_t *realContext) {
  realSubtract(y, x, result, realContext);
  realAdd(result, const_1, result, realContext);
  WP34S_LnGamma(result, result, realContext);       // r = ln((y-x)!)

  realAdd(x, const_1, x, realContext);
  WP34S_LnGamma(x, x, realContext);                 // x = ln(x!)

  realAdd(y, const_1, y, realContext);
  WP34S_LnGamma(y, y, realContext);                 // y = ln(y!)

  realSubtract(y, result, result, realContext);
  realSubtract(result, x, result, realContext);     // r = ln(y!) - ln((y-x)!) - ln(x!)
}

static void cyxReal(real_t *y, real_t *x, real_t *result, realContext_t *realContext) {
  bool_t inputAreIntegers = (realIsAnInteger(x) && realIsAnInteger(y));

  logCyxReal(y, x, result, realContext);

  realExp(result, result, realContext);             // r = y! / ((y-x)! × x!)

  if(inputAreIntegers && !realIsAnInteger(result)) {
    realToIntegralValue(result, result, DEC_ROUND_HALF_UP, realContext);
  }
}

static void cyxLong(longInteger_t y, longInteger_t x, longInteger_t result) {
  if(longIntegerCompareInt(x, 0) == 0) {
    intToLongInteger(1, result);
  }
  else if(longIntegerCompareInt(x, 400) <= 0) {
    uint32_t loops, counter;

    longIntegerToUInt(x, loops);
    longIntegerSubtractUInt(y, --loops, result);
    longIntegerCopy(result, y);
    counter = 1;
    while(counter <= loops) {
      counter++;
      longIntegerAddUInt(y, 1, y);
      longIntegerMultiply(result, y, result);
      longIntegerDivideUInt(result, counter, result);
    }
  }
  else {
    real_t xReal, yReal, resultReal;

    convertLongIntegerToReal(x, &xReal, &ctxtReal75);
    convertLongIntegerToReal(y, &yReal, &ctxtReal75);

    realSubtract(&yReal, &xReal, &resultReal, &ctxtReal75);
    realAdd(&resultReal, const_1, &resultReal, &ctxtReal75);
    WP34S_LnGamma(&resultReal, &resultReal, &ctxtReal75);       // r = ln((y-x)!)

    realAdd(&xReal, const_1, &xReal, &ctxtReal75);
    WP34S_LnGamma(&xReal, &xReal, &ctxtReal75);                 // x = ln(x!)

    realAdd(&yReal, const_1, &yReal, &ctxtReal75);
    WP34S_LnGamma(&yReal, &yReal, &ctxtReal75);                 // y = ln(y!)

    realSubtract(&yReal, &resultReal, &resultReal, &ctxtReal75);
    realSubtract(&resultReal, &xReal, &resultReal, &ctxtReal75); // r = ln(y!) - ln((y-x)!) - ln(x!)

    realExp(&resultReal, &resultReal, &ctxtReal75);             // r = y! / ((y-x)! × x!)

    convertRealToLongInteger(&resultReal, result, DEC_ROUND_HALF_UP);
  }
}

static void cyxCplx(real_t *yReal, real_t *yImag, real_t *xReal, real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext) {
  realSubtract(yReal, xReal, rReal, realContext);                // r = y - x
  realSubtract(yImag, xImag, rImag, realContext);

  realAdd(rReal, const_1, rReal, realContext);                   // r = t + 1
  WP34S_ComplexLnGamma(rReal, rImag, rReal, rImag, realContext); // r = lnGamma(t + 1) = ln((y - x)!)

  realAdd(xReal, const_1, xReal, realContext);                   // x = x + 1
  WP34S_ComplexLnGamma(xReal, xImag, xReal, xImag, realContext); // x = lnGamma(x + 1) = ln(x!)

  realAdd(yReal, const_1, yReal, realContext);                   // y = y + 1
  WP34S_ComplexLnGamma(yReal, yImag, yReal, yImag, realContext); // y = lnGamma(y + 1) = ln(y!)

  realSubtract(yReal, rReal, rReal, realContext);                // r = ln(y!) - ln((y - x)!)
  realSubtract(yImag, rImag, rImag, realContext);

  realSubtract(rReal, xReal, rReal, realContext);                // r = ln(y!) - ln((y - x)!) - ln(x!)
  realSubtract(rImag, xImag, rImag, realContext);

  expComplex(rReal, rImag, rReal, rImag, realContext);           // r = y! / ((y-x)! × x!)
}

static void pyxReal(real_t *y, real_t *x, real_t *result, realContext_t *realContext) {
  bool_t inputAreIntegers = (realIsAnInteger(x) && realIsAnInteger(y));

  realSubtract(y, x, result, realContext);
  realAdd(result, const_1, result, realContext);
  WP34S_LnGamma(result, result, realContext);     // r = ln((y-x)!)

  realAdd(y, const_1, y, realContext);
  WP34S_LnGamma(y, y, realContext);               // y = ln(y!)

  realSubtract(y, result, result, realContext);   // r = ln(y!) - ln((y-x)!)

  realExp(result, result, realContext);           // r = y! / (y-x)!

  if(inputAreIntegers && !realIsAnInteger(result)) {
    realToIntegralValue(result, result, DEC_ROUND_HALF_UP, realContext);
  }
}

static void pyxLong(longInteger_t y, longInteger_t x, longInteger_t result) {
  if(longIntegerCompareInt(x, 0) == 0) {
    intToLongInteger(1, result);
  }
  else if(longIntegerCompareInt(x, 400) <= 0) {
    uint32_t loops;

    longIntegerToUInt(x, loops);
    longIntegerSubtractUInt(y, --loops, result);
    longIntegerCopy(result, y);
    while(loops-- > 0) {
      longIntegerAddUInt(y, 1, y);
      longIntegerMultiply(result, y, result);
    }
  }
  else {
    real_t xReal, yReal, resultReal;

    convertLongIntegerToReal(x, &xReal, &ctxtReal75);
    convertLongIntegerToReal(y, &yReal, &ctxtReal75);

    realSubtract(&yReal, &xReal, &resultReal, &ctxtReal75);
    realAdd(&resultReal, const_1, &resultReal, &ctxtReal75);
    WP34S_LnGamma(&resultReal, &resultReal, &ctxtReal75);        // r = ln((y-x)!)

    realAdd(&yReal, const_1, &yReal, &ctxtReal75);
    WP34S_LnGamma(&yReal, &yReal, &ctxtReal75);                  // y = ln(y!)

    realSubtract(&yReal, &resultReal, &resultReal, &ctxtReal75); // r = ln(y!) - ln((y-x)!)

    realExp(&resultReal, &resultReal, &ctxtReal75);              // r = y! / (y-x)!

    convertRealToLongInteger(&resultReal, result, DEC_ROUND_HALF_UP);
  }
}

static void pyxCplx(real_t *yReal, real_t *yImag, real_t *xReal, real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext) {
  realSubtract(yReal, xReal, rReal, realContext);                // r = y - x
  realSubtract(yImag, xImag, rImag, realContext);

  realAdd(rReal, const_1, rReal, realContext);                   // r = t + 1
  WP34S_ComplexLnGamma(rReal, rImag, rReal, rImag, realContext); // r = lnGamma(t + 1) = ln((y - x)!)

  realAdd(yReal, const_1, yReal, realContext);                   // y = y + 1
  WP34S_ComplexLnGamma(yReal, yImag, yReal, yImag, realContext); // y = lnGamma(y + 1) = ln(y!)

  realSubtract(yReal, rReal, rReal, realContext);                // r = ln(y!) - ln((y - x)!)
  realSubtract(yImag, rImag, rImag, realContext);

  expComplex(rReal, rImag, rReal, rImag, realContext);           // r = y! / (y-x)!
}

//=============================================================================
// Main function
//-----------------------------------------------------------------------------

/********************************************//**
 * \brief regX ==> regL and Cyx(regX, RegY) ==> regX
 * enables stack lift and refreshes the stack.
 * C(n,k) = n! / [k! * (n-k)!]
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnCyx(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  cpyx[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)](CP_COMBINATION);

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
  adjustResult(REGISTER_Y, true, true, REGISTER_Y, -1, -1);
}

/********************************************//**
 * \brief regX ==> regL and Pyx(regX, RegY) ==> regX
 * enables stack lift and refreshes the stack.
 * P(n,k) = n! / (n-k)!
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnPyx(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  cpyx[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)](CP_PERMUTATION);

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
  adjustResult(REGISTER_Y, true, true, REGISTER_Y, -1, -1);
}

//=============================================================================
// Cyx/Pyx(Y(long integer), *)
//-----------------------------------------------------------------------------

/********************************************//**
 * \brief Cyx/Pyx(Y(long integer), X(long integer)) ==> X(long integer)
 *
 * \param void
 * \return void
 ***********************************************/
void cpyxLonILonI(uint16_t combOrPerm) {
  longInteger_t x, y;

  convertLongIntegerRegisterToLongInteger(REGISTER_X, x);
  convertLongIntegerRegisterToLongInteger(REGISTER_Y, y);

  if(longIntegerIsNegative(x) || longIntegerIsNegative(y) || longIntegerCompare(y, x) < 0) {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    EXTRA_INFO_MESSAGE("cpyxLonILonI:", "cannot calculate Cyx/Pyx, conditions: x>=0, y>=0, and x<=y.");
  }
  else {
    longInteger_t t;
    longIntegerInit(t);

    (combOrPerm == CP_COMBINATION) ? cyxLong(y, x, t)
                                   : pyxLong(y, x, t);

    convertLongIntegerToLongIntegerRegister(t, REGISTER_X);
    longIntegerFree(t);
  }

  longIntegerFree(x);
  longIntegerFree(y);
}

/********************************************//**
 * \brief Cyx/Pyx(Y(long integer), X(real34)) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void cpyxLonIReal(uint16_t combOrPerm) {
  real_t x, y;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
  convertLongIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal75);

  if(realIsNegative(&x) || realIsNegative(&y) || realCompareGreaterThan(&x, &y)) {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    EXTRA_INFO_MESSAGE("cpyxLonIReal:", "cannot calculate Cyx/Pyx, conditions: x>=0, y>=0, and x<=y.");
  }
  else {
    real_t t;

    (combOrPerm == CP_COMBINATION) ? cyxReal(&y, &x, &t, &ctxtReal39) : pyxReal(&y, &x, &t, &ctxtReal39);

    convertRealToReal34ResultRegister(&t, REGISTER_X);
    setRegisterAngularMode(REGISTER_X, amNone);
  }
}

/********************************************//**
 * \brief Cyx/Pyx(Y(long integer), X(complex34)) ==> X(complex34)
 *
 * \param void
 * \return void
 ***********************************************/
void cpyxLonICplx(uint16_t combOrPerm) {
  real_t xReal, xImag, yReal, yImag;
  real_t tReal, tImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  convertLongIntegerRegisterToReal(REGISTER_Y, &yReal, &ctxtReal39);
  realZero(&yImag);

  (combOrPerm == CP_COMBINATION) ? cyxCplx(&yReal, &yImag, &xReal, &xImag, &tReal, &tImag, &ctxtReal39)
                                 : pyxCplx(&yReal, &yImag, &xReal, &xImag, &tReal, &tImag, &ctxtReal39);

  convertComplexToResultRegister(&tReal, &tImag, REGISTER_X);
}

/********************************************//**
 * \brief Cyx/Pyx(Y(long integer), X(short integer)) ==> X(long integer)
 *
 * \param void
 * \return void
 ***********************************************/
void cpyxLonIShoI(uint16_t combOrPerm) {
  longInteger_t x, y;

  convertShortIntegerRegisterToLongInteger(REGISTER_X, x);
  convertLongIntegerRegisterToLongInteger(REGISTER_Y, y);

  if(longIntegerIsNegative(x) || longIntegerIsNegative(y) || longIntegerCompare(y, x) < 0) {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    EXTRA_INFO_MESSAGE("cpyxLonIShoI:", "cannot calculate Cyx/Pyx, conditions: x>=0, y>=0, and x<=y.");
  }
  else {
    longInteger_t t;
    longIntegerInit(t);

    (combOrPerm == CP_COMBINATION) ? cyxLong(y, x, t)
                                   : pyxLong(y, x, t);

    convertLongIntegerToLongIntegerRegister(t, REGISTER_X);
    longIntegerFree(t);
  }

  longIntegerFree(x);
  longIntegerFree(y);
}

//=============================================================================
// Cyx/Pyx(Y(real34), *)
//-----------------------------------------------------------------------------

/********************************************//**
 * \brief Cyx/Pyx(Y(real34), X(long integer)) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void cpyxRealLonI(uint16_t combOrPerm) {
  real_t x, y;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);

  if(realIsNegative(&x) || realIsNegative(&y) || realCompareGreaterThan(&x, &y)) {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    EXTRA_INFO_MESSAGE("cpyxRealLonI:", "cannot calculate Cyx/Pyx, conditions: x>=0, y>=0, and x<=y.");
  }
  else {
    real_t t;

    (combOrPerm == CP_COMBINATION) ? cyxReal(&y, &x, &t, &ctxtReal39)
                                   : pyxReal(&y, &x, &t, &ctxtReal39);

    reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
    convertRealToReal34ResultRegister(&t, REGISTER_X);
    setRegisterAngularMode(REGISTER_X, amNone);
  }
}

/********************************************//**
 * \brief Cyx/Pyx(Y(real34), X(real34)) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void cpyxRealReal(uint16_t combOrPerm) {
  real_t x, y;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);

  if(realIsNegative(&x) || realIsNegative(&y) || realCompareGreaterThan(&x, &y)) {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    EXTRA_INFO_MESSAGE("cpyxRealReal:", "cannot calculate Cyx/Pyx, conditions: x>=0, y>=0, and x<=y.");
  }
  else {
    real_t t;

    (combOrPerm == CP_COMBINATION) ? cyxReal(&y, &x, &t, &ctxtReal39)
                                   : pyxReal(&y, &x, &t, &ctxtReal39);

    convertRealToReal34ResultRegister(&t, REGISTER_X);
    setRegisterAngularMode(REGISTER_X, amNone);
  }
}

/********************************************//**
 * \brief Cyx/Pyx(Y(real34), X(complex34)) ==> X(complex34)
 *
 * \param void
 * \return void
 ***********************************************/
void cpyxRealCplx(uint16_t combOrPerm) {
  real_t xReal, xImag, yReal, yImag;
  real_t tReal, tImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);
  realZero(&yImag);

  (combOrPerm == CP_COMBINATION) ? cyxCplx(&yReal, &yImag, &xReal, &xImag, &tReal, &tImag, &ctxtReal39)
                                 : pyxCplx(&yReal, &yImag, &xReal, &xImag, &tReal, &tImag, &ctxtReal39);

  convertComplexToResultRegister(&tReal, &tImag, REGISTER_X);
}

/********************************************//**
 * \brief Cyx/Pyx(Y(real34), X(short integer)) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void cpyxRealShoI(uint16_t combOrPerm) {
  real_t x, y;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
  convertShortIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);

  if(realIsNegative(&x) || realIsNegative(&y) || realCompareGreaterThan(&x, &y)) {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    EXTRA_INFO_MESSAGE("cpyxRealShoI:", "cannot calculate Cyx/Pyx, conditions: x>=0, y>=0, and x<=y.");
  }
  else {
    real_t t;

    (combOrPerm == CP_COMBINATION) ? cyxReal(&y, &x, &t, &ctxtReal39)
                                   : pyxReal(&y, &x, &t, &ctxtReal39);

    reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
    convertRealToReal34ResultRegister(&t, REGISTER_X);
    setRegisterAngularMode(REGISTER_X, amNone);
  }
}

//=============================================================================
// Cyx/Pyx(Y(complex34), *)
//-----------------------------------------------------------------------------

/********************************************//**
 * \brief Cyx/Pyx(Y(complex34), X(long integer)) ==> X(complex34)
 *
 * \param void
 * \return void
 ***********************************************/
void cpyxCplxLonI(uint16_t combOrPerm) {
  real_t xReal, xImag, yReal, yImag;
  real_t tReal, tImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Y), &yImag);

  convertLongIntegerRegisterToReal(REGISTER_X, &xReal, &ctxtReal39);
  realZero(&xImag);

  (combOrPerm == CP_COMBINATION) ? cyxCplx(&yReal, &yImag, &xReal, &xImag, &tReal, &tImag, &ctxtReal39)
                                 : pyxCplx(&yReal, &yImag, &xReal, &xImag, &tReal, &tImag, &ctxtReal39);

  reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
  convertComplexToResultRegister(&tReal, &tImag, REGISTER_X);
}

/********************************************//**
 * \brief Cyx/Pyx(Y(complex34), X(real34)) ==> X(complex34)
 *
 * \param void
 * \return void
 ***********************************************/
void cpyxCplxReal(uint16_t combOrPerm) {
  real_t xReal, xImag, yReal, yImag;
  real_t tReal, tImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Y), &yImag);

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  realZero(&xImag);

  (combOrPerm == CP_COMBINATION) ? cyxCplx(&yReal, &yImag, &xReal, &xImag, &tReal, &tImag, &ctxtReal39)
                                 : pyxCplx(&yReal, &yImag, &xReal, &xImag, &tReal, &tImag, &ctxtReal39);

  reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
  convertComplexToResultRegister(&tReal, &tImag, REGISTER_X);
}

/********************************************//**
 * \brief Cyx/Pyx(Y(complex34), X(complex34)) ==> X(complex34)
 *
 * \param void
 * \return void
 ***********************************************/
void cpyxCplxCplx(uint16_t combOrPerm) {
  real_t xReal, xImag, yReal, yImag;
  real_t tReal, tImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Y), &yImag);

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  (combOrPerm == CP_COMBINATION) ? cyxCplx(&yReal, &yImag, &xReal, &xImag, &tReal, &tImag, &ctxtReal39)
                                 : pyxCplx(&yReal, &yImag, &xReal, &xImag, &tReal, &tImag, &ctxtReal39);

  convertComplexToResultRegister(&tReal, &tImag, REGISTER_X);
}

/********************************************//**
 * \brief Cyx/Pyx(Y(complex34), X(short integer)) ==> X(complex34)
 *
 * \param void
 * \return void
 ***********************************************/
void cpyxCplxShoI(uint16_t combOrPerm) {
  real_t xReal, xImag, yReal, yImag;
  real_t tReal, tImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Y), &yImag);

  convertShortIntegerRegisterToReal(REGISTER_X, &xReal, &ctxtReal39);
  realZero(&xImag);

  (combOrPerm == CP_COMBINATION) ? cyxCplx(&yReal, &yImag, &xReal, &xImag, &tReal, &tImag, &ctxtReal39)
                                 : pyxCplx(&yReal, &yImag, &xReal, &xImag, &tReal, &tImag, &ctxtReal39);

  reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
  convertComplexToResultRegister(&tReal, &tImag, REGISTER_X);
}

//=============================================================================
// Cyx/Pyx(Y(short integer), *)
//-----------------------------------------------------------------------------

/********************************************//**
 * \brief Cyx/Pyx(Y(short integer), X(long integer)) ==> X(long integer)
 *
 * \param void
 * \return void
 ***********************************************/
void cpyxShoILonI(uint16_t combOrPerm) {
  longInteger_t x, y;

  convertLongIntegerRegisterToLongInteger(REGISTER_X, x);
  convertShortIntegerRegisterToLongInteger(REGISTER_Y, y);

  if(longIntegerIsNegative(x) || longIntegerIsNegative(y) || longIntegerCompare(y, x) < 0) {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    EXTRA_INFO_MESSAGE("cpyxShoILonI:", "cannot calculate Cyx/Pyx, y and x must be greater or equal than zero.");
  }
  else {
    longInteger_t t;
    longIntegerInit(t);

    (combOrPerm == CP_COMBINATION) ? cyxLong(y, x, t)
                                   : pyxLong(y, x, t);

    convertLongIntegerToLongIntegerRegister(t, REGISTER_X);
    longIntegerFree(t);
  }

  longIntegerFree(x);
  longIntegerFree(y);
}

/********************************************//**
 * \brief Cyx/Pyx(Y(short integer), X(real34)) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void cpyxShoIReal(uint16_t combOrPerm) {
  real_t x, y;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
  convertShortIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);

  if(realIsNegative(&x) || realIsNegative(&y) || realCompareGreaterThan(&x, &y)) {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    EXTRA_INFO_MESSAGE("cpyxShoIReal:", "cannot calculate Cyx/Pyx, conditions: x>=0, y>=0, and x<=y.");
  }
  else {
    real_t t;

    (combOrPerm == CP_COMBINATION) ? cyxReal(&y, &x, &t, &ctxtReal39)
                                   : pyxReal(&y, &x, &t, &ctxtReal39);

    reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
    convertRealToReal34ResultRegister(&t, REGISTER_X);
    setRegisterAngularMode(REGISTER_X, amNone);
  }
}

/********************************************//**
 * \brief Cyx/Pyx(Y(short integer), X(complex34)) ==> X(complex34)
 *
 * \param void
 * \return void
 ***********************************************/
void cpyxShoICplx(uint16_t combOrPerm) {
  real_t xReal, xImag, yReal, yImag;
  real_t tReal, tImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  convertShortIntegerRegisterToReal(REGISTER_Y, &yReal, &ctxtReal39);
  realZero(&yImag);

  (combOrPerm == CP_COMBINATION) ? cyxCplx(&yReal, &yImag, &xReal, &xImag, &tReal, &tImag, &ctxtReal39)
                                 : pyxCplx(&yReal, &yImag, &xReal, &xImag, &tReal, &tImag, &ctxtReal39);

  convertComplexToResultRegister(&tReal, &tImag, REGISTER_X);
}

/********************************************//**
 * \brief Cyx/Pyx(Y(short integer), X(short integer)) ==> X(short integer)
 *
 * \param void
 * \return void
 ***********************************************/
void cpyxShoIShoI(uint16_t combOrPerm) {
  longInteger_t x, y;

  convertShortIntegerRegisterToLongInteger(REGISTER_X, x);
  convertShortIntegerRegisterToLongInteger(REGISTER_Y, y);

  if(longIntegerIsNegative(x) || longIntegerIsNegative(y) || longIntegerCompare(y, x) < 0) {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    EXTRA_INFO_MESSAGE("cpyxShoIShoI:", "cannot calculate Cyx/Pyx, y and x must be greater or equal than zero.");
  }
  else {
    longInteger_t t;

    longIntegerInit(t);
    (combOrPerm == CP_COMBINATION) ? cyxLong(y, x, t)
                                   : pyxLong(y, x, t);

    convertLongIntegerToShortIntegerRegister(t, getRegisterShortIntegerBase(REGISTER_Y), REGISTER_X);

    longIntegerFree(x); // Because convertShortIntegerRegisterToLongInteger reinits the long integer
    convertShortIntegerRegisterToLongInteger(REGISTER_X, x);
    if(longIntegerCompare(t, x) != 0) {
      setSystemFlag(FLAG_OVERFLOW);
    }

    longIntegerFree(t);
  }

  longIntegerFree(x);
  longIntegerFree(y);
}

