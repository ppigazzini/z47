// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file imaginaryPart.c
 ***********************************************/

#include "mathematics/imaginaryPart.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "items.h"
#include "mathematics/matrix.h"
#include "registerValueConversions.h"
#include "registers.h"

#include "c47.h"



TO_QSPI void (* const imagPart[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1              2              3             4              5              6              7              8             9              10
//          Long integer   Real34         complex34     Time           Date           String         Real34 mat     Complex34 m   Short integer  Config data
            imagPartError, imagPartReal,  imagPartCplx, imagPartError, imagPartError, imagPartError, imagPartError, imagPartCxma, imagPartError, imagPartError
};



/********************************************//**
 * \brief Data type error in Im
 *
 * \param void
 * \return void
 ***********************************************/
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  void imagPartError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate Im for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnImaginaryPart:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and Im(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnImaginaryPart(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }
  imagPart[getRegisterDataType(REGISTER_X)]();
}



void imagPartCxma(void) {
  complex34Matrix_t cMat;
  real34Matrix_t rMat;

  linkToComplexMatrixRegister(REGISTER_X, &cMat);
  if(realMatrixInit(&rMat, cMat.header.matrixRows, cMat.header.matrixColumns)) {
    for(uint16_t i = 0; i < cMat.header.matrixRows * cMat.header.matrixColumns; ++i) {
      real34Copy(VARIABLE_IMAG34_DATA(&cMat.matrixElements[i]), &rMat.matrixElements[i]);
    }

    convertReal34MatrixToReal34MatrixRegister(&rMat, REGISTER_X); // cMat invalidates here
    realMatrixFree(&rMat);
  }
  else {
    displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
  }
}


void imagPartCplx(void) {
  real34_t ip;

  real34Copy(REGISTER_IMAG34_DATA(REGISTER_X), &ip);
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  real34Copy(&ip, REGISTER_REAL34_DATA(REGISTER_X));
}


void imagPartReal(void) {
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  convertRealToReal34ResultRegister(const_0, REGISTER_X);
}
