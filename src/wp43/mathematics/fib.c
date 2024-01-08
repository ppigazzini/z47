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
 * \file fib.c
 ***********************************************/

#include "mathematics/fib.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "display.h"
#include "fonts.h"
#include "mathematics/cos.h"
#include "mathematics/division.h"
#include "mathematics/matrix.h"
#include "mathematics/multiplication.h"
#include "mathematics/power.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "wp43.h"



TO_QSPI void (* const fib[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2          3          4           5           6           7           8           9             10
//          Long integer Real34     Complex34  Time        Date        String      Real34 mat  Complex34 m Short integer Config data
            fibLonI,     fibReal,   fibCplx,   fibError,   fibError,   fibError,   fibError,   fibError,   fibError,     fibError
};


/********************************************//**
 * \brief Data type error in fib
 *
 * \param void
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void fibError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate fib(%s)", getRegisterDataTypeName(REGISTER_X, false, false));
    moreInfoOnError("In function fnFib:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)


/********************************************//**
 * \brief regX ==> regL and fib(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnFib(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  fib[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}


void fibLonI(void) {
  longInteger_t x, result;

  convertLongIntegerRegisterToLongInteger(REGISTER_X, x);

  if(longIntegerIsNegative(x)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      longIntegerRegisterToDisplayString(REGISTER_X, errorMessage, ERROR_MESSAGE_LENGTH, SCREEN_WIDTH, 50, false);   //JM added last parameter: Allow LARGELI
      sprintf(tmpString, "cannot calculate fib(%s)", errorMessage);
      moreInfoOnError("In function fibLonI:", tmpString, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    longIntegerFree(x);
    return;
  }

  if(shortIntegerMode == SIM_UNSIGN && longIntegerCompareUInt(x, 93) > 0) {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      longIntegerRegisterToDisplayString(REGISTER_X, errorMessage, ERROR_MESSAGE_LENGTH, SCREEN_WIDTH, 50, false);   //JM added last parameter: Allow LARGELI
      sprintf(tmpString, "cannot calculate fib(%s), the limit for UNSIGN is 93", errorMessage);
      moreInfoOnError("In function fibLonI:", tmpString, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    longIntegerFree(x);
    return;
  }
  else if(longIntegerCompareUInt(x, 4791) > 0) {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      longIntegerRegisterToDisplayString(REGISTER_X, errorMessage, ERROR_MESSAGE_LENGTH, SCREEN_WIDTH, 50, false);   //JM added last parameter: Allow LARGELI
      sprintf(tmpString, "cannot calculate fib(%s), the limit is 4791, it's to ensure that the 3328 bits limit is not exceeded", errorMessage);
      moreInfoOnError("In function fibLonI:", tmpString, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    longIntegerFree(x);
    return;
  }

  uint32_t n;
  longIntegerToUInt(x, n);           // Convert x into unsigned int.

  longIntegerInit(result);           // Initialize fib variable
  longIntegerFibonacci(n, result);   // result = FIB(n)

  convertLongIntegerToLongIntegerRegister(result, REGISTER_X);

  longIntegerFree(result);
  longIntegerFree(x);
}


uint8_t FibonacciReal(const real_t *n, real_t *res, realContext_t *realContext) {
  // FIB(x) = [ PHI^(x) - PHI^(-x)*COS(PI * x) ] / SQRT(5)

  real_t a, b;

  realPower(const_PHI, n, &a, realContext);                             // a   = PHI^(n)
  realDivide(const_1, &a, &b, realContext);                             // b   = PHI^(-n) = = 1/PHI^(n)
  realMultiply(const_pi, n, res, realContext);                          // res = PI * n
  WP34S_Cvt2RadSinCosTan(res, amRadian, NULL, res, NULL, realContext);  // res = COS(PI * n)
  realMultiply(&b, res, &b, realContext);                               // b   = PHI^(-n) * COS(PI * n)
  realSquareRoot(const_5, res, realContext);                            // res = SQRT(5)
  realSubtract(&a, &b, &a, realContext);                                // a   = PHI^(n) - PHI^(-n) * COS(PI * n)
  realDivide(&a, res, res, realContext);                                // res = [ PHI^n - PHI^(-n) * COS(PI * n) ] / SQRT(5)

  return ERROR_NONE;
}


uint8_t FibonacciComplex(const real_t *nReal, const real_t *nImag, real_t *resReal, real_t *resImag, realContext_t *realContext) {
  // FIB(x) = [ PHI^(x) - PHI^(-x)*COS(PI * x) ] / SQRT(5)

  real_t aReal, aImag;
  real_t bReal, bImag;

  PowerComplex(const_PHI, const_0, nReal, nImag, &aReal, &aImag, realContext);       // a   = PHI^(n)
  divRealComplex(const_1, &aReal, &aImag, &bReal, &bImag, realContext);              // b   = PHI^(-n) = 1/PHI^(n)
  mulComplexComplex(const_pi, const_0, nReal, nImag, resReal, resImag, realContext); // res = PI * n
  cosComplex(resReal, resImag, resReal, resImag, realContext);                       // res = COS(PI * n)
  mulComplexComplex(&bReal, &bImag, resReal, resImag, &bReal, &bImag, realContext);  // b   = PHI^(-n) * COS(PI * n)
  realSquareRoot(const_5, resReal, realContext);                                     // res = SQRT(5)
  realZero(resImag);
  realSubtract(&aReal, &bReal, &aReal, realContext);                                 // a   = PHI^(n) - PHI^(-n) * COS(PI * n)
  realSubtract(&aImag, &bImag, &aImag, realContext);
  divComplexComplex(&aReal, &aImag, resReal, resImag, resReal, resImag, realContext);// res = [ PHI^(n) - PHI^(-n) * COS(PI * n) ] / SQRT(5)

  return ERROR_NONE;
}

void fibReal(void) {
  // FIB(x) = [ PHI^(x) - PHI^(-x)*COS(PI * x) ] / SQRT(5)

  real_t x;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
  FibonacciReal(&x, &x, &ctxtReal39);
  convertRealToReal34ResultRegister(&x, REGISTER_X);
}

void fibCplx(void) {
  real_t xReal, xImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  if(realIsZero(&xImag)) {
    FibonacciReal(&xReal, &xReal, &ctxtReal39);
  }
  else {
    FibonacciComplex(&xReal, &xImag, &xReal, &xImag, &ctxtReal39);
  }

  convertComplexToResultRegister(&xReal, &xImag, REGISTER_X);
}
