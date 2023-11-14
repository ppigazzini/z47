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
 * \file swapRealImaginary.c
 ***********************************************/

#include "mathematics/swapRealImaginary.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "fonts.h"
#include "items.h"
#include "mathematics/matrix.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "wp43.h"



TO_QSPI void (* const swapReIm[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1                2             3             4              5              6              7              8             9              10
//          Long integer     Real34        complex34     Time           Date           String         Real34 mat     Complex34 m   Short integer  Config data
            swapLongintReal, swapRealReal, swapReImCplx, swapReImError, swapReImError, swapReImError, swapReImError, swapReImCxma, swapReImError, swapReImError          //JM
};



/********************************************//**
 * \brief Data type error in exp
 *
 * \param void
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void swapReImError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate Re<>Im for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnSwapRealImaginary:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and Re<>IM(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnSwapRealImaginary(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }
  swapReIm[getRegisterDataType(REGISTER_X)]();
}



void swapReImCxma(void) {
  complex34Matrix_t cMat;
  real34_t tmp;

  linkToComplexMatrixRegister(REGISTER_X, &cMat);

  for(uint16_t i = 0; i < cMat.header.matrixRows * cMat.header.matrixColumns; ++i) {
    real34Copy(VARIABLE_REAL34_DATA(&cMat.matrixElements[i]), &tmp);
    real34Copy(VARIABLE_IMAG34_DATA(&cMat.matrixElements[i]), VARIABLE_REAL34_DATA(&cMat.matrixElements[i]));
    real34Copy(&tmp                                         , VARIABLE_IMAG34_DATA(&cMat.matrixElements[i]));
  }
}


void swapReImCplx(void) {
  real34_t temp;

  real34Copy(REGISTER_IMAG34_DATA(REGISTER_X), &temp);
  real34Copy(REGISTER_REAL34_DATA(REGISTER_X), REGISTER_IMAG34_DATA(REGISTER_X));
  real34Copy(&temp,                            REGISTER_REAL34_DATA(REGISTER_X));
}


void swapRealReal(void) {                                                     //JM vv
  real_t c;
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &c);
  reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
  convertRealToImag34ResultRegister(&c, REGISTER_X);
  convertRealToReal34ResultRegister(const_0, REGISTER_X);
}


void swapLongintReal(void) {
  real_t c;
  convertLongIntegerRegisterToReal(REGISTER_X, &c, &ctxtReal39);
  reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
  convertRealToImag34ResultRegister(&c, REGISTER_X);
  convertRealToReal34ResultRegister(const_0, REGISTER_X);
}                                                                             //JM ^^
