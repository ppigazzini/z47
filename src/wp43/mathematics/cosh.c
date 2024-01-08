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
 * \file cosh.c
 ***********************************************/

#include "mathematics/cosh.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "fonts.h"
#include "items.h"
#include "mathematics/matrix.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "wp43.h"



TO_QSPI void (* const Cosh[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1             2         3          4          5          6          7           8            9             10
//          Long integer  Real34    Complex34  Time       Date       String     Real34 mat  Complex34 m  Short integer Config data
            coshLonI,     coshReal, coshCplx,  coshError, coshError, coshError, coshRema,   coshCxma,    coshError,    coshError
};



/********************************************//**
 * \brief Data type error in cosh
 *
 * \param void
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void coshError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate Cos for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnCosh:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and cosh(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnCosh(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  Cosh[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}



void coshLonI(void) {
  real_t cosh;

  convertLongIntegerRegisterToReal(REGISTER_X, &cosh, &ctxtReal39);
  WP34S_SinhCosh(&cosh, NULL, &cosh, &ctxtReal39);

  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
  convertRealToReal34ResultRegister(&cosh, REGISTER_X);
}



void coshRema(void) {
  elementwiseRema(coshReal);
}



void coshCxma(void) {
  elementwiseCxma(coshCplx);
}



void coshReal(void) {
  if(real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X)) && !getSystemFlag(FLAG_SPCRES)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function coshReal:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of cosh when flag D is not set", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  real_t x;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
  WP34S_SinhCosh(&x, NULL, &x, &ctxtReal39);
  convertRealToReal34ResultRegister(&x, REGISTER_X);
  setRegisterAngularMode(REGISTER_X, amNone);
}



void coshCplx(void) {
  // cosh(a + i b) = cosh(a) cos(b) + i sinh(a) sin(b)
  real_t a, b, sinha, cosha, sinb, cosb;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &a);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &b);

  WP34S_SinhCosh(&a, &sinha, &cosha, &ctxtReal39);
  WP34S_Cvt2RadSinCosTan(&b, amRadian, &sinb, &cosb, NULL, &ctxtReal39);

  realMultiply(&cosha, &cosb, &a, &ctxtReal39);
  realMultiply(&sinha, &sinb, &b, &ctxtReal39);

  convertComplexToResultRegister(&a, &b, REGISTER_X);
}
