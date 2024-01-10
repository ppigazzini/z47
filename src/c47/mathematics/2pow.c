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
 * \file 2pow.c
 ***********************************************/

#include "mathematics/2pow.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "fonts.h"
#include "integers.h"
#include "items.h"
#include "mathematics/matrix.h"
#include "mathematics/toRect.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"



TO_QSPI void (* const twoPow[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2           3           4            5            6            7           8           9             10
//          Long integer Real34      Complex34   Time         Date         String       Real34 mat  Complex34 m Short integer Config data
            twoPowLonI,  twoPowReal, twoPowCplx, twoPowError, twoPowError, twoPowError, twoPowRema, twoPowCxma, twoPowShoI,   twoPowError
};



/********************************************//**
 * \brief Data type error in exp
 *
 * \param void
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void twoPowError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate 2" STD_SUP_x " for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fn2Pow:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and 2^regX ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fn2Pow(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  twoPow[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}



void realPower2(const real_t *x, real_t *res, realContext_t *realContext) {
  realMultiply(x, const_ln2, res, realContext);
  realExp(res, res, realContext);
}



void twoPowLonI(void) {
  int32_t exponentSign;
  longInteger_t base, exponent;

  longIntegerInit(base);
  intToLongInteger(2, base);
  convertLongIntegerRegisterToLongInteger(REGISTER_X, exponent);

  longIntegerSetPositiveSign(base);

  exponentSign = longIntegerSign(exponent);
  longIntegerSetPositiveSign(exponent);

  if(longIntegerIsZero(exponent)) {
    uIntToLongInteger(1, base);
    convertLongIntegerToLongIntegerRegister(base, REGISTER_X);
    longIntegerFree(base);
    longIntegerFree(exponent);
    return;
  }
  else if(exponentSign == -1) {
    longIntegerFree(base);
    longIntegerFree(exponent);
    convertLongIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
    twoPowReal();
    return;
  }

  longInteger_t power;

  longIntegerInit(power);
  uIntToLongInteger(1, power);

  for(uint32_t i=0; !longIntegerIsZero(exponent) && lastErrorCode == 0; i++) {
    if(longIntegerIsOdd(exponent)) {
     longIntegerMultiply(power, base, power);
    }

    longIntegerDivideUInt(exponent, 2, exponent);

    if(!longIntegerIsZero(exponent)) {
      longIntegerSquare(base, base);
    }
  }

  convertLongIntegerToLongIntegerRegister(power, REGISTER_X);

  longIntegerFree(power);
  longIntegerFree(base);
  longIntegerFree(exponent);
}



void twoPowRema(void) {
  elementwiseRema(twoPowReal);
}



void twoPowCxma(void) {
  elementwiseCxma(twoPowCplx);
}



void twoPowShoI(void) {
  *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = WP34S_int2pow(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)));
}



void twoPowReal(void) {
  if(real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X)) && !getSystemFlag(FLAG_SPCRES)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function twoPowReal:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of 2" STD_SUP_x " when flag D is not set", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  real_t x;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
  realPower2(&x, &x, &ctxtReal39);
  convertRealToReal34ResultRegister(&x, REGISTER_X);
  setRegisterAngularMode(REGISTER_X, amNone);
}



void twoPowCplx(void) {
  real_t a, b, factor;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &a);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &b);

  // ln(2) * (a + bi) --> (a + bi)
  realMultiply(const_ln2, &a, &a, &ctxtReal39);
  realMultiply(const_ln2, &b, &b, &ctxtReal39);

  // exp(ln(2) * (a + bi)) --> (a + bi)
  realExp(&a, &factor, &ctxtReal39);
  realPolarToRectangular(const_1, &b, &a, &b, &ctxtReal39);
  realMultiply(&factor, &a, &a, &ctxtReal39);
  realMultiply(&factor, &b, &b, &ctxtReal39);

  convertComplexToResultRegister(&a, &b, REGISTER_X);
}
