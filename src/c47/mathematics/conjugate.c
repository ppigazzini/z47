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
 * \file conjugate.c
 ***********************************************/

#include "mathematics/conjugate.h"

#include "debug.h"
#include "error.h"
#include "flags.h"
#include "items.h"
#include "mathematics/matrix.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"



static void conjRema(void) {
  complex34Matrix_t cMat;

  convertReal34MatrixRegisterToComplex34Matrix(REGISTER_X, &cMat);
  if (getSystemFlag(FLAG_SPCRES))
    for (uint16_t i = 0; i < cMat.header.matrixRows * cMat.header.matrixColumns; ++i)
      real34ChangeSign(VARIABLE_IMAG34_DATA(&cMat.matrixElements[i]));
  convertComplex34MatrixToComplex34MatrixRegister(&cMat, REGISTER_X);
}

static void conjCxma(void) {
  complex34Matrix_t cMat;

  linkToComplexMatrixRegister(REGISTER_X, &cMat);

  for(uint16_t i = 0; i < cMat.header.matrixRows * cMat.header.matrixColumns; ++i) {
    real34ChangeSign(VARIABLE_IMAG34_DATA(&cMat.matrixElements[i]));
    if(real34IsZero(VARIABLE_IMAG34_DATA(&cMat.matrixElements[i])) && !getSystemFlag(FLAG_SPCRES)) {
      real34SetPositiveSign(VARIABLE_IMAG34_DATA(&cMat.matrixElements[i]));
    }
  }
}

static void conjCplx(void) {
  real_t r, i;

  if (!getRegisterAsComplex(REGISTER_X, &r, &i))
      return;

  realChangeSign(&i);
  if(realIsZero(&i) && !getSystemFlag(FLAG_SPCRES)) {
    realSetPositiveSign(&i);
  }
  reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
  convertComplexToResultRegister(&r, &i, REGISTER_X);
}

/********************************************//**
 * \brief regX ==> regL and conj(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnConjugate(uint16_t unusedButMandatoryParameter) {
  uint32_t typex = getRegisterDataType(REGISTER_X);

  if(!saveLastX())
    return;

  if (typex == dtComplex34Matrix)
    conjCxma();
  else if (typex == dtReal34Matrix)
    conjRema();
  else
    conjCplx();
}

