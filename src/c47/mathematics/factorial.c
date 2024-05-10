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
 * \file factorial.c
 ***********************************************/

#include "mathematics/factorial.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "display.h"
#include "flags.h"
#include "fonts.h"
#include "mathematics/matrix.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"



TO_QSPI void (* const fact[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2         3         4          5          6          7          8           9             10
//          Long integer Real34    Complex34 Time       Date       String     Real34 mat Complex34 m Short integer Config data
            factLonI,    factReal, factCplx, factError, factError, factError, factError, factError,  factShoI,     factError
};



/********************************************//**
 * \brief Data type error in fact
 *
 * \param void
 * \return void
 ***********************************************/
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  void factError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate x! for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnFactorial:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and fact(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnFactorial(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  fact[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}



void factLonI(void) {
  longInteger_t x, f;

  convertLongIntegerRegisterToLongInteger(REGISTER_X, x);

  if(longIntegerIsNegative(x)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      longIntegerRegisterToDisplayString(REGISTER_X, errorMessage, ERROR_MESSAGE_LENGTH, SCREEN_WIDTH, 50, false);   //JM added last parameter: Allow LARGELI
      sprintf(tmpString, "cannot calculate factorial(%s)", errorMessage);
      moreInfoOnError("In function factLonI:", tmpString, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    longIntegerFree(x);
    return;
  }

  if(longIntegerCompareUInt(x, MAX_FACTORIAL) > 0) {                            //JM
    // convert long integers above 450 to reals and return a real factorial result
    convertLongIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
    factReal();
    longIntegerFree(x);
    return;
  }


  uint32_t n;
  longIntegerToUInt(x, n);
  #if defined(LINUX)
    //The more precise formula below is: (n*ln(n) - n + (ln(8n� + 4n� + n + 1/30))/6 + ln(pi)/2) / ln(2)
    longIntegerInitSizeInBits(f, 1 + (uint32_t)((n * log(n) - n) / log(2)));
    uIntToLongInteger(1, f);
    for(uint32_t i=2; i<=n; i++) {
      longIntegerMultiplyUInt(f, i, f);
    }
  #else // !LINUX
    longIntegerInit(f);
    longIntegerFactorial(n, f); //TODO why this line fails?
  #endif // LINUX


  convertLongIntegerToLongIntegerRegister(f, REGISTER_X);

  longIntegerFree(f);
  longIntegerFree(x);
}

uint64_t fact_uint64(uint64_t value)
{
  uint64_t result;

  if(value <= 1) {
    result = 1;
  }
  else {
    uint64_t m = value;

    if((value & 1) != 0) {
      m += value;
      value -= 1;
    }
    result = m;
    value -= 2;
    while(value > 0) {
      m += value;
      result *= m;
      value -= 2;
    }
  }

  return result;
}


void factShoI(void) {
  int16_t sign;
  uint64_t value;

  convertShortIntegerRegisterToUInt64(REGISTER_X, &sign, &value);

  if(sign == 1) { // Negative value
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      longIntegerRegisterToDisplayString(REGISTER_X, errorMessage, ERROR_MESSAGE_LENGTH, SCREEN_WIDTH, 50, false);   //JM added last parameter: Allow LARGELI
      sprintf(tmpString, "cannot calculate factorial(%s)", errorMessage);
      moreInfoOnError("In function factShoI:", tmpString, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  if(value > 20) {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      longIntegerRegisterToDisplayString(REGISTER_X, errorMessage, ERROR_MESSAGE_LENGTH, SCREEN_WIDTH, 50, false);   //JM added last parameter: Allow LARGELI
      sprintf(tmpString, "cannot calculate factorial(%s)", errorMessage);
      moreInfoOnError("In function factShoI:", tmpString, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  uint64_t f = fact_uint64(value);
  if(f > shortIntegerMask) {
    setSystemFlag(FLAG_OVERFLOW);
  }

  convertUInt64ToShortIntegerRegister(0, f, getRegisterTag(REGISTER_X), REGISTER_X);
}



void factReal(void) {
  real_t x;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
  WP34S_Factorial(&x, &x, &ctxtReal39);
  convertRealToReal34ResultRegister(&x, REGISTER_X);
  setRegisterAngularMode(REGISTER_X, amNone);
}



void factCplx(void) {
  real_t zReal, zImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &zReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &zImag);

  realAdd(&zReal, const_1, &zReal, &ctxtReal39);
  WP34S_ComplexGamma(&zReal, &zImag, &zReal, &zImag, &ctxtReal39);

  convertComplexToResultRegister(&zReal, &zImag, REGISTER_X);
}
