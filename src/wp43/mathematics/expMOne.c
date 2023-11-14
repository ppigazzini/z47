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
 * \file expMOne.c
 ***********************************************/
// Coded by JM, based on exp.c

#include "mathematics/expMOne.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "fonts.h"
#include "items.h"
#include "mathematics/exp.h"
#include "mathematics/matrix.h"
#include "mathematics/multiplication.h"
#include "mathematics/sin.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "wp43.h"



TO_QSPI void (* const ExpM1[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2          3           4           5           6           7            8             9               10
//          Long integer Real34     Complex34   Time        Date        String      Real34 mat   Complex34 m   Short integer   Config data
            expM1LonI,   expM1Real, expM1Cplx,  expM1Error, expM1Error, expM1Error, expM1Rema,   expM1Cxma,    expM1ShoI,      expM1Error
};



/********************************************//**
 * \brief Data type error in expM1
 *
 * \param void
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void expM1Error(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate Exp(x)-1 for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnExpM1:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and expM1(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnExpM1(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  ExpM1[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}






void expM1Complex(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext) {
  real_t z2_real, z2_imag, e_real, e_imag;

  if(realIsZero(imag)) {
    if(realIsInfinite(real) && realIsNegative(real)) {
      realCopy(const__1, resReal);
      realZero(resImag);
      return;
    }
    realExpM1(real, resReal, realContext);
    realZero(resImag);
    return;
  }

  if(realIsSpecial(real) || realIsSpecial(imag)) {
    realCopy(const_NaN, resReal);
    realCopy(const_NaN, resImag);
    return;
  }

  /* Complex (e^z)-1.
   *
   * With a bit of algebra it can be shown that:
   *  e^z - 1 = -exp(z/2) * 2*i*sin(i*z/2)
   * which has no obvious accuracy issues inherent here.
   *
   * The negation and multiplication by i are simplified to negates and swaps.
   */
  realMultiply(real, const_1on2, &z2_real, realContext);
  realMultiply(imag, const_1on2, &z2_imag, realContext);
  expComplex(&z2_real, &z2_imag, &e_real, &e_imag, realContext);
  realChangeSign(&e_real);
  realAdd(&e_real, &e_real, &e_real, realContext);
  realAdd(&e_imag, &e_imag, &e_imag, realContext);
  /* sin(i * z/2) */
  realChangeSign(&z2_imag);
  sinComplex(&z2_imag, &z2_real, &z2_real, &z2_imag, realContext);
  mulComplexComplex(&z2_real, &z2_imag, &e_imag, &e_real, resReal, resImag, realContext);
}



/**********************************************************************
 * In all the functions below:
 * if X is a number then X = a + ib
 * The variables a and b are used for intermediate calculations
 * 1 is subtracted at the end
 ***********************************************************************/

void expM1LonI(void) {
  real_t a;

  convertLongIntegerRegisterToReal(REGISTER_X, &a, &ctxtReal39);
  realExp(&a, &a, &ctxtReal39);
  realSubtract(&a, const_1, &a, &ctxtReal39);
  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
  convertRealToReal34ResultRegister(&a, REGISTER_X);
}



void expM1Rema(void) {
  elementwiseRema(expM1Real);
}



void expM1Cxma(void) {
  elementwiseCxma(expM1Cplx);
}



void expM1ShoI(void) {
  real_t x;

  convertShortIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
  realExp(&x, &x, &ctxtReal39);
  realSubtract(&x, const_1, &x, &ctxtReal39);
  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
  convertRealToReal34ResultRegister(&x, REGISTER_X);
}

void realExpM1(const real_t *x, real_t *res, realContext_t *realContext)
{
  if(realIsInfinite(x) && realIsNegative(x)) {
    realCopy(const__1, res);
  }
  else if(realIsInfinite(x) && realIsPositive(x)) {
    realCopy(const_plusInfinity, res);
  }
  else if(realIsSpecial(x)) {
    realCopy(const_NaN, res);
  }
  else {
    WP34S_ExpM1(x, res, realContext);
  }
}

void expM1Real(void) {
  if(real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X)) && !getSystemFlag(FLAG_SPCRES)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function expM1Real:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of exp when flag D is not set", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  real_t x;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
  realExpM1(&x, &x, &ctxtReal39);
  convertRealToReal34ResultRegister(&x, REGISTER_X);
  setRegisterAngularMode(REGISTER_X, amNone);
}



void expM1Cplx(void) {
  real_t zReal, zImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &zReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &zImag);

  expM1Complex(&zReal, &zImag, &zReal, &zImag, &ctxtReal75);

  convertRealToReal34ResultRegister(&zReal, REGISTER_X);
  convertRealToImag34ResultRegister(&zImag, REGISTER_X);
}
