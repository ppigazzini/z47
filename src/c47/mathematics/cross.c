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
 * \file cross.c
 ***********************************************/

#include "mathematics/cross.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "fonts.h"
#include "items.h"
#include "mathematics/matrix.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"

static void crossDataTypeError(void);

TO_QSPI void (* const cross[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX |    regY ==>    1                    2                    3                    4                    5                    6                    7                    8                    9                   10
//      V                Long integer         Real34               Complex34            Time                 Date                 String               Real34 mat           Complex34 mat        Short integer       Config data
/*  1 Long integer  */ { crossDataTypeError,  crossDataTypeError,  crossCplxLonI,       crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError, crossDataTypeError},
/*  2 Real34        */ { crossDataTypeError,  crossDataTypeError,  crossCplxReal,       crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError, crossDataTypeError},
/*  3 Complex34     */ { crossLonICplx,       crossRealCplx,       crossCplxCplx,       crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossShoICplx,      crossDataTypeError},
/*  4 Time          */ { crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError, crossDataTypeError},
/*  5 Date          */ { crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError, crossDataTypeError},
/*  6 String        */ { crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError, crossDataTypeError},
/*  7 Real34 mat    */ { crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossRemaRema,       crossCpmaRema,       crossDataTypeError, crossDataTypeError},
/*  8 Complex34 mat */ { crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossRemaCpma,       crossCpmaCpma,       crossDataTypeError, crossDataTypeError},
/*  9 Short integer */ { crossDataTypeError,  crossDataTypeError,  crossCplxShoI,       crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError, crossDataTypeError},
/* 10 Config data   */ { crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError,  crossDataTypeError, crossDataTypeError}
};

//=============================================================================
// Error handling
//-----------------------------------------------------------------------------

/********************************************//**
 * \brief Data type error in CROSS
 *
 * \param void
 * \return void
 ***********************************************/
static void crossDataTypeError(void) {
  displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);

  #if(EXTRA_INFO_ON_CALC_ERROR == 1)
    sprintf(errorMessage, "cannot raise %s", getRegisterDataTypeName(REGISTER_Y, true, false));
    sprintf(errorMessage + ERROR_MESSAGE_LENGTH/2, "to %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnCross:", errorMessage, errorMessage + ERROR_MESSAGE_LENGTH/2, NULL);
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
}

//static void crossSizeError() {
//  displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);

//  #if(EXTRA_INFO_ON_CALC_ERROR == 1)
//    sprintf(errorMessage, "cannot calculate CROSS product, matrix size mismatch.");
//    moreInfoOnError("In function fnCross:", errorMessage, NULL, NULL);
//  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
//}

//=============================================================================
// Main function
//-----------------------------------------------------------------------------

/********************************************//**
 * \brief regX ==> regL and CROSS(regX, RegY) ==> regX
 * enables stack lift and refreshes the stack.
 * Calculate the cross (or vector) product between complex and matrix
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnCross(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  cross[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)]();

  adjustResult(REGISTER_X, true, true, REGISTER_X, -1, -1);
}

//=============================================================================
// Complex cross product calculation functionS
//-----------------------------------------------------------------------------

static void crossCplx(real_t *xReal, real_t *xImag, real_t *yReal, real_t *yImag, real_t *rReal, realContext_t *realContext) {
  real_t t;

  realMultiply(xReal, yImag, &t, realContext);        // t = xReal * yImag
  realMultiply(yReal, xImag, rReal, realContext);         // r = yReal * xImag
  realSubtract(rReal, &t, rReal, realContext);   // r = r - t
}


/********************************************//**
 * \brief cross(Y(real34), X(complex34)) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void crossRealCplx(void) {
  real_t xReal, xImag, yReal, yImag;
  real_t rReal;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);
  realZero(&yImag);

  crossCplx(&xReal, &xImag, &yReal, &yImag, &rReal, &ctxtReal39);

  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
  convertRealToReal34ResultRegister(&rReal, REGISTER_X);
  setRegisterAngularMode(REGISTER_X, amNone);
}

/********************************************//**
 * \brief cross(Y(long integer), X(complex34)) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void crossLonICplx(void) {
  real_t xReal, xImag, yReal, yImag;
  real_t rReal;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  convertLongIntegerRegisterToReal(REGISTER_Y, &yReal, &ctxtReal39);
  realZero(&yImag);

  crossCplx(&xReal, &xImag, &yReal, &yImag, &rReal, &ctxtReal39);

  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
  convertRealToReal34ResultRegister(&rReal, REGISTER_X);
  setRegisterAngularMode(REGISTER_X, amNone);
}

/********************************************//**
 * \brief cross(Y(short integer), X(complex34)) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void crossShoICplx(void) {
  real_t xReal, xImag, yReal, yImag;
  real_t rReal;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  convertShortIntegerRegisterToReal(REGISTER_Y, &yReal, &ctxtReal39);
  realZero(&yImag);

  crossCplx(&xReal, &xImag, &yReal, &yImag, &rReal, &ctxtReal39);

  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
  convertRealToReal34ResultRegister(&rReal, REGISTER_X);
  setRegisterAngularMode(REGISTER_X, amNone);
}

/********************************************//**
 * \brief cross(Y(complex34), X(complex34)) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void crossCplxCplx(void) {
  real_t xReal, xImag, yReal, yImag;
  real_t rReal;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Y), &yImag);

  crossCplx(&xReal, &xImag, &yReal, &yImag, &rReal, &ctxtReal39);

  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
  convertRealToReal34ResultRegister(&rReal, REGISTER_X);
  setRegisterAngularMode(REGISTER_X, amNone);
}

/********************************************//**
 * \brief cross(Y(complex34), X(real34)) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void crossCplxReal(void) {
  real_t xReal, xImag, yReal, yImag;
  real_t rReal;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  realZero(&xImag);

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Y), &yImag);

  crossCplx(&xReal, &xImag, &yReal, &yImag, &rReal, &ctxtReal39);

  convertRealToReal34ResultRegister(&rReal, REGISTER_X);
  setRegisterAngularMode(REGISTER_X, amNone);
}

/********************************************//**
 * \brief cross(Y(complex34), X(long integer)) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void crossCplxLonI(void) {
  real_t xReal, xImag, yReal, yImag;
  real_t rReal;

  convertLongIntegerRegisterToReal(REGISTER_X, &xReal, &ctxtReal39);
  realZero(&xImag);

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Y), &yImag);

  crossCplx(&xReal, &xImag, &yReal, &yImag, &rReal, &ctxtReal39);

  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
  convertRealToReal34ResultRegister(&rReal, REGISTER_X);
  setRegisterAngularMode(REGISTER_X, amNone);
}

/********************************************//**
 * \brief cross(Y(complex34), X(short integer)) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void crossCplxShoI(void) {
  real_t xReal, xImag, yReal, yImag;
  real_t rReal;

  convertShortIntegerRegisterToReal(REGISTER_X, &xReal, &ctxtReal39);
  realZero(&xImag);

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Y), &yImag);

  crossCplx(&xReal, &xImag, &yReal, &yImag, &rReal, &ctxtReal39);

  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
  convertRealToReal34ResultRegister(&rReal, REGISTER_X);
  setRegisterAngularMode(REGISTER_X, amNone);
}

//=============================================================================
// Matrix cross calculation function
//-----------------------------------------------------------------------------

/********************************************//**
 * \brief cross(Y(real34 matrix), X(real34 matrix)) ==> X(real34 matrix)
 *
 * \param void
 * \return void
 ***********************************************/
void crossRemaRema(void) {
  real34Matrix_t y, x, res;

  linkToRealMatrixRegister(REGISTER_Y, &y);
  linkToRealMatrixRegister(REGISTER_X, &x);

  if((realVectorSize(&y) == 0) || (realVectorSize(&x) == 0) || (realVectorSize(&y) > 3) || (realVectorSize(&x) > 3)) {
    displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "invalid numbers of elements of %d" STD_CROSS "%d-matrix to %d" STD_CROSS "%d-matrix",
              x.header.matrixRows, x.header.matrixColumns,
              y.header.matrixRows, y.header.matrixColumns);
      moreInfoOnError("In function crossRemaRema:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  else {
    crossRealVectors(&y, &x, &res);
    convertReal34MatrixToReal34MatrixRegister(&res, REGISTER_X);
  }
}

/********************************************//**
 * \brief cross(Y(complex34 matrix), X(real34 matrix)) ==> X(complex34 matrix)
 *
 * \param void
 * \return void
 ***********************************************/
void crossCpmaRema(void) {
  convertReal34MatrixRegisterToComplex34MatrixRegister(REGISTER_X, REGISTER_X);
  crossCpmaCpma();
}

/********************************************//**
 * \brief cross(Y(real34 matrix), X(complex34 matrix)) ==> X(complex34 matrix)
 *
 * \param void
 * \return void
 ***********************************************/
void crossRemaCpma(void) {
  convertReal34MatrixRegisterToComplex34MatrixRegister(REGISTER_Y, REGISTER_Y);
  crossCpmaCpma();
}

/********************************************//**
 * \brief cross(Y(complex34 matrix), X(complex34 matrix)) ==> X(complex34 matrix)
 *
 * \param void
 * \return void
 ***********************************************/
void crossCpmaCpma(void) {
  complex34Matrix_t y, x, res;

  linkToComplexMatrixRegister(REGISTER_Y, &y);
  linkToComplexMatrixRegister(REGISTER_X, &x);

  if((complexVectorSize(&y) == 0) || (complexVectorSize(&x) == 0) || (complexVectorSize(&y) > 3) || (complexVectorSize(&x) > 3)) {
    displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "invalid numbers of elements of %d" STD_CROSS "%d-matrix to %d" STD_CROSS "%d-matrix",
              x.header.matrixRows, x.header.matrixColumns,
              y.header.matrixRows, y.header.matrixColumns);
      moreInfoOnError("In function crossCpmaCpma:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  else {
    crossComplexVectors(&y, &x, &res);
    convertComplex34MatrixToComplex34MatrixRegister(&res, REGISTER_X);
  }
}
