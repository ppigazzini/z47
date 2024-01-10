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


static void swapReImCxma(void) {
  complex34Matrix_t cMat;
  real34_t tmp;

  linkToComplexMatrixRegister(REGISTER_X, &cMat);

  for(uint16_t i = 0; i < cMat.header.matrixRows * cMat.header.matrixColumns; ++i) {
    real34Copy(VARIABLE_REAL34_DATA(&cMat.matrixElements[i]), &tmp);
    real34Copy(VARIABLE_IMAG34_DATA(&cMat.matrixElements[i]), VARIABLE_REAL34_DATA(&cMat.matrixElements[i]));
    real34Copy(&tmp                                         , VARIABLE_IMAG34_DATA(&cMat.matrixElements[i]));
  }
}

static void swapReImRema(void) {
  complex34Matrix_t c;
  real34Matrix_t r;

  linkToRealMatrixRegister(REGISTER_X, &r);
  convertReal34MatrixToComplex34Matrix(&r, &c);

  for(uint16_t i = 0; i < c.header.matrixRows * c.header.matrixColumns; ++i) {
    real34Copy(VARIABLE_REAL34_DATA(&c.matrixElements[i]), VARIABLE_IMAG34_DATA(&c.matrixElements[i]));
    real34Zero(VARIABLE_REAL34_DATA(&c.matrixElements[i]));
  }
  
  convertComplex34MatrixToComplex34MatrixRegister(&c, REGISTER_X);
  complexMatrixFree(&c);
}

/********************************************//**
 * \brief regX ==> regL and Re<>IM(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnSwapRealImaginary(uint16_t unusedButMandatoryParameter) {
  real_t a, b;
  const uint32_t type = getRegisterDataType(REGISTER_X);

  if(!saveLastX())
    return;

  if (type == dtReal34Matrix)
    swapReImRema();
  else if (type == dtComplex34Matrix)
    swapReImCxma();
  else {
    if (!getRegisterAsComplex(REGISTER_X, &a, &b))
      return;
    convertComplexToResultRegister(&b, &a, REGISTER_X);
  }
}

