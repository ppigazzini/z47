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
 * \file magnitude.c
 ***********************************************/

#include "mathematics/magnitude.h"

#include "debug.h"
#include "error.h"
#include "integers.h"
#include "items.h"
#include "mathematics/matrix.h"
#include "registerValueConversions.h"
#include "registers.h"
#include "toPolar.h"

#include "c47.h"



TO_QSPI void (* const magnitude[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1              2              3              4               5               6               7              8              9              10
//          Long integer   Real34         complex34      Time            Date            String          Real34 mat     Complex34 m    Short integer  Config data
            magnitudeLonI, magnitudeReal, magnitudeCplx, magnitudeError, magnitudeError, magnitudeError, magnitudeRema, magnitudeCxma, magnitudeShoI, magnitudeError
};



/********************************************//**
 * \brief Data type error in |x|
 *
 * \param void
 * \return void
 ***********************************************/
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  void magnitudeError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate |x| for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnMagnitude:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief Returns the absolute value of an integer or a real and the magnitude of a complex
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnMagnitude(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  magnitude[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
}



void magnitudeLonI(void) {
  setRegisterLongIntegerSign(REGISTER_X, LI_POSITIVE);
}



void magnitudeRema(void) {
  elementwiseRema(magnitudeReal);
}



void magnitudeCxma(void) {
  complex34Matrix_t cMat;
  real34Matrix_t rMat;
  real34_t dummy;

  linkToComplexMatrixRegister(REGISTER_X, &cMat);
  if(realMatrixInit(&rMat, cMat.header.matrixRows, cMat.header.matrixColumns)) {
    for(uint16_t i = 0; i < cMat.header.matrixRows * cMat.header.matrixColumns; ++i) {
      real34RectangularToPolar(VARIABLE_REAL34_DATA(&cMat.matrixElements[i]), VARIABLE_IMAG34_DATA(&cMat.matrixElements[i]), &rMat.matrixElements[i], &dummy);
    }

    convertReal34MatrixToReal34MatrixRegister(&rMat, REGISTER_X);
    realMatrixFree(&rMat);
  }
  else {
    displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
  }
}



void magnitudeShoI(void) {
  *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = WP34S_intAbs(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)));
}



void magnitudeReal(void) {
  real34SetPositiveSign(REGISTER_REAL34_DATA(REGISTER_X));
  setRegisterAngularMode(REGISTER_X, amNone);
}



void magnitudeCplx(void) {
  real_t a, b, c;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &a);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &b);

  complexMagnitude(&a, &b, &c, &ctxtReal39);

  convertRealToResultRegister(&c, REGISTER_X, amNone);
}

void complexMagnitude2(const real_t *a, const real_t *b, real_t *c, realContext_t *realContext) {
  real_t t;

  realMultiply(a, a, &t, realContext);
  realFMA(b, b, &t, c, realContext);
}


void complexMagnitude(const real_t *a, const real_t *b, real_t *c, realContext_t *realContext) {
  real_t u;

  complexMagnitude2(a, b, &u, realContext);
  realSquareRoot(&u, c, realContext);
}

