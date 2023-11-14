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
 * \file arg.c
 ***********************************************/
// Coded by JM, based on arctan.c

#include "mathematics/arg.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "conversionAngles.h"
#include "mathematics/matrix.h"
#include "mathematics/toPolar.h"
#include "registerValueConversions.h"
#include "registers.h"

#include "wp43.h"



TO_QSPI void (* const arg[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2           3           4            5            6            7            8            9             10
//          Long integer Real34      Complex34   Time         Date         String       Real34 mat   Complex34 m  Short integer Config data
            argError,    argReal,    argCplx,    argError,    argError,    argError,    argError,    argCxma,     argError,     argError
};



/********************************************//**
 * \brief Data type error in arctan
 *
 * \param void
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void argError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate arg for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnArg:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)




/********************************************//**
 * \brief regX ==> regL and arctan(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnArg(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  arg[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
}



/********************************************//**
 * \brief regX ==> regL and arg(regX) = arctan(Im(regX) / Re(regX)) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void argReal(void) {
  if(real34IsNaN(REGISTER_REAL34_DATA(REGISTER_X))) {
    //let it stay NAN
  }
  else {
    if(real34IsPositive(REGISTER_REAL34_DATA(REGISTER_X)) || real34IsZero(REGISTER_REAL34_DATA(REGISTER_X))){
      reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(const_0, REGISTER_X);
      convertAngle34FromTo(REGISTER_REAL34_DATA(REGISTER_X), amDegree, currentAngularMode);
      setRegisterAngularMode(REGISTER_X, currentAngularMode);
    }
    else
      if(real34IsNegative(REGISTER_REAL34_DATA(REGISTER_X))) {
        reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
        convertRealToReal34ResultRegister(const_180, REGISTER_X);
        convertAngle34FromTo(REGISTER_REAL34_DATA(REGISTER_X), amDegree, currentAngularMode);
        setRegisterAngularMode(REGISTER_X, currentAngularMode);
      }
  }
}


void argCplx(void) {
  real_t real, imag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &real);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &imag);
  realRectangularToPolar(&real, &imag, &real, &imag, &ctxtReal39);
  convertAngleFromTo(&imag, amRadian, currentAngularMode, &ctxtReal39);

  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, currentAngularMode);
  convertRealToReal34ResultRegister(&imag, REGISTER_X);
}



void argCxma(void) {
  complex34Matrix_t cMat;
  real34Matrix_t rMat;
  real34_t dummy;

  linkToComplexMatrixRegister(REGISTER_X, &cMat);
  if(realMatrixInit(&rMat, cMat.header.matrixRows, cMat.header.matrixColumns)) {
    for(uint16_t i = 0; i < cMat.header.matrixRows * cMat.header.matrixColumns; ++i) {
      real34RectangularToPolar(VARIABLE_REAL34_DATA(&cMat.matrixElements[i]), VARIABLE_IMAG34_DATA(&cMat.matrixElements[i]), &dummy, &rMat.matrixElements[i]);
      convertAngle34FromTo(&rMat.matrixElements[i], amRadian, currentAngularMode);
    }

    convertReal34MatrixToReal34MatrixRegister(&rMat, REGISTER_X);
    realMatrixFree(&rMat);
  }
  else {
    displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
  }
}
