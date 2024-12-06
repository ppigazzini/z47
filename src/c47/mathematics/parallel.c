// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file parallel.c
 ***********************************************/

#include "c47.h"

TO_QSPI void (* const parallel[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX |    regY ==>   1                 2                 3                 4              5              6              7              8              9              10
//      V               Long integer      Real34            Complex34         Time           Date           String         Real34 mat     Complex34 m    Short integer  Config data
/*  1 Long integer  */ {parallelLonILonI, parallelRealLonI, parallelCplxLonI, parallelError, parallelError, parallelError, parallelError, parallelError, parallelError, parallelError},
/*  2 Real34        */ {parallelLonIReal, parallelRealReal, parallelCplxReal, parallelError, parallelError, parallelError, parallelError, parallelError, parallelError, parallelError},
/*  3 Complex34     */ {parallelLonICplx, parallelRealCplx, parallelCplxCplx, parallelError, parallelError, parallelError, parallelError, parallelError, parallelError, parallelError},
/*  4 Time          */ {parallelError,    parallelError,    parallelError,    parallelError, parallelError, parallelError, parallelError, parallelError, parallelError, parallelError},
/*  5 Date          */ {parallelError,    parallelError,    parallelError,    parallelError, parallelError, parallelError, parallelError, parallelError, parallelError, parallelError},
/*  6 String        */ {parallelError,    parallelError,    parallelError,    parallelError, parallelError, parallelError, parallelError, parallelError, parallelError, parallelError},
/*  7 Real34 mat    */ {parallelError,    parallelError,    parallelError,    parallelError, parallelError, parallelError, parallelError, parallelError, parallelError, parallelError},
/*  8 Complex34 mat */ {parallelError,    parallelError,    parallelError,    parallelError, parallelError, parallelError, parallelError, parallelError, parallelError, parallelError},
/*  9 Short integer */ {parallelError,    parallelError,    parallelError,    parallelError, parallelError, parallelError, parallelError, parallelError, parallelError, parallelError},
/* 10 Config data   */ {parallelError,    parallelError,    parallelError,    parallelError, parallelError, parallelError, parallelError, parallelError, parallelError, parallelError}
};



/********************************************//**
 * \brief Data type error in parallel function
 *
 * \param[in] unusedButMandatoryParameter
 * \return void
 ***********************************************/
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  void parallelError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot multiply %s", getRegisterDataTypeName(REGISTER_Y, true, false));
    sprintf(errorMessage + ERROR_MESSAGE_LENGTH/2, "by %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnMultiply:", errorMessage, errorMessage + ERROR_MESSAGE_LENGTH/2, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and regY || regX ==> regX
 * Drops Y, enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter
 * \return void
 ***********************************************/
void fnParallel(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  parallel[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)]();

  adjustResult(REGISTER_X, true, true, REGISTER_X, REGISTER_Y, -1);
}



/******************************************************************************************************************************************************************************************/
/* long integer || ...                                                                                                                                                                    */
/******************************************************************************************************************************************************************************************/

/********************************************//**
 * \brief Y(long integer) || X(long integer) ==> X(Real)
 *
 * \param void
 * \return void
 ***********************************************/
void parallelLonILonI(void) {
  real_t y, x, product;

  // y || x = xy / (x+y)
  convertLongIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);
  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);

  if(!realIsZero(&x)) {
    realMultiply(&y, &x, &product, &ctxtReal39);
    realAdd(&y, &x, &y, &ctxtReal39);
    realDivide(&product, &y, &x, &ctxtReal39);
  }

  convertRealToReal34ResultRegister(&x, REGISTER_X);
}



/********************************************//**
 * \brief Y(long integer) || X(real34) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void parallelLonIReal(void) {
  real_t y, x, product;

  // y || x = xy / (x+y)
  convertLongIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);

  if(!realIsZero(&x)) {
    realMultiply(&y, &x, &product, &ctxtReal39);
    realAdd(&y, &x, &y, &ctxtReal39);
    realDivide(&product, &y, &x, &ctxtReal39);
  }

  convertRealToReal34ResultRegister(&x, REGISTER_X);
  setRegisterAngularMode(REGISTER_X, amNone);
}



/********************************************//**
 * \brief Y(real34) || X(long integer) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void parallelRealLonI(void) {
  real_t y, x, product;

  // y || x = xy / (x+y)
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);

  if(!realIsZero(&x)) {
    realMultiply(&y, &x, &product, &ctxtReal39);
    realAdd(&y, &x, &y, &ctxtReal39);
    realDivide(&product, &y, &x, &ctxtReal39);
  }

  convertRealToReal34ResultRegister(&x, REGISTER_X);
  setRegisterAngularMode(REGISTER_X, amNone);
}



/********************************************//**
 * \brief Y(long integer) || X(complex34) ==> X(complex34)
 *
 * \param void
 * \return void
 ***********************************************/
void parallelLonICplx(void) {
  real_t y;
  real_t xReal, productReal, sumReal;
  real_t xImag, productImag, sumImag;

  // y || x = xy / (x + y)
  convertLongIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  if(!realIsZero(&xReal) || !realIsZero(&xImag)) {
    realMultiply(&y, &xReal, &productReal, &ctxtReal39);
    realMultiply(&y, &xImag, &productImag, &ctxtReal39);
    realAdd(&y, &xReal, &sumReal, &ctxtReal39);
    realCopy(&xImag, &sumImag);
    divComplexComplex(&productReal, &productImag, &sumReal, &sumImag, &xReal, &xImag, &ctxtReal39);
  }

  convertComplexToResultRegister(&xReal, &xImag, REGISTER_X);
}



/********************************************//**
 * \brief Y(complex34) || X(long integer) ==> X(complex34)
 *
 * \param void
 * \return void
 ***********************************************/
void parallelCplxLonI(void) {
  real_t x;
  real_t yReal, productReal, sumReal;
  real_t yImag, productImag, sumImag;

  // y || x = xy / (x + y)
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Y), &yImag);
  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
  reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);

  if(!realIsZero(&yReal) || !realIsZero(&yImag)) {
    realMultiply(&x, &yReal, &productReal, &ctxtReal39);
    realMultiply(&x, &yImag, &productImag, &ctxtReal39);
    realAdd(&x, &yReal, &sumReal, &ctxtReal39);
    realCopy(&yImag, &sumImag);
    divComplexComplex(&productReal, &productImag, &sumReal, &sumImag, &yReal, &yImag, &ctxtReal39);
  }

  convertComplexToResultRegister(&yReal, &yImag, REGISTER_X);
}



/******************************************************************************************************************************************************************************************/
/* real34 || ...                                                                                                                                                                          */
/******************************************************************************************************************************************************************************************/

/********************************************//**
 * \brief Y(real34) || X(real34) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void parallelRealReal(void) {
  real_t y, x, product;

  // y || x = xy / (x+y)
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);

  if(!realIsZero(&x)) {
    realMultiply(&y, &x, &product, &ctxtReal39);
    realAdd(&y, &x, &y, &ctxtReal39);
    realDivide(&product, &y, &x, &ctxtReal39);
  }

  convertRealToReal34ResultRegister(&x, REGISTER_X);
  setRegisterAngularMode(REGISTER_X, amNone);
}



/********************************************//**
 * \brief Y(real34) || X(complex34) ==> X(complex34)
 *
 * \param void
 * \return void
 ***********************************************/
void parallelRealCplx(void) {
  real_t y;
  real_t xReal, productReal, sumReal;
  real_t xImag, productImag, sumImag;

  // y || x = xy / (x + y)
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  if(!realIsZero(&xReal) || !realIsZero(&xImag)) {
    realMultiply(&y, &xReal, &productReal, &ctxtReal39);
    realMultiply(&y, &xImag, &productImag, &ctxtReal39);
    realAdd(&y, &xReal, &sumReal, &ctxtReal39);
    realCopy(&xImag, &sumImag);
    divComplexComplex(&productReal, &productImag, &sumReal, &sumImag, &xReal, &xImag, &ctxtReal39);
  }

  convertComplexToResultRegister(&xReal, &xImag, REGISTER_X);
}



/********************************************//**
 * \brief Y(complex34) || X(real34) ==> X(complex34)
 *
 * \param void
 * \return void
 ***********************************************/
void parallelCplxReal(void) {
  real_t x;
  real_t yReal, productReal, sumReal;
  real_t yImag, productImag, sumImag;

  // y || x = xy / (x + y)
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Y), &yImag);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
  reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);

  if(!realIsZero(&yReal) || !realIsZero(&yImag)) {
    realMultiply(&x, &yReal, &productReal, &ctxtReal39);
    realMultiply(&x, &yImag, &productImag, &ctxtReal39);
    realAdd(&x, &yReal, &sumReal, &ctxtReal39);
    realCopy(&yImag, &sumImag);
    divComplexComplex(&productReal, &productImag, &sumReal, &sumImag, &yReal, &yImag, &ctxtReal39);
  }

  convertComplexToResultRegister(&yReal, &yImag, REGISTER_X);
}



/******************************************************************************************************************************************************************************************/
/* complex34 || ...                                                                                                                                                                       */
/******************************************************************************************************************************************************************************************/

/********************************************//**
 * \brief Y(complex34) || X(complex34) ==> X(complex34)
 *
 * \param void
 * \return void
 ***********************************************/
void parallelCplxCplx(void) {
  real_t yReal, xReal, productReal, sumReal;
  real_t yImag, xImag, productImag, sumImag;

  // y || x = xy / (x + y)
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Y), &yImag);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  if(!realIsZero(&xReal) || !realIsZero(&xImag)) {
    mulComplexComplex(&yReal, &yImag, &xReal, &xImag, &productReal, &productImag, &ctxtReal39);
    realAdd(&yReal, &xReal, &sumReal, &ctxtReal39);
    realAdd(&yImag, &xImag, &sumImag, &ctxtReal39);
    divComplexComplex(&productReal, &productImag, &sumReal, &sumImag, &xReal, &xImag, &ctxtReal39);
  }

  convertComplexToResultRegister(&xReal, &xImag, REGISTER_X);
}
