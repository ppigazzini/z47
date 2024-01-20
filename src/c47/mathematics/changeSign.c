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
 * \file changeSign.c
 ***********************************************/

#include "mathematics/changeSign.h"

#include "debug.h"
#include "error.h"
#include "flags.h"
#include "integers.h"
#include "items.h"
#include "mathematics/matrix.h"
#include "registers.h"

#include "c47.h"

#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  static void chsError    (void);
#else // (EXTRA_INFO_ON_CALC_ERROR == 1)
  #define chsError typeError
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

//      RegX
static void chsLonI     (void);
static void chsRema     (void);
static void chsCxma     (void);
static void chsShoI     (void);


TO_QSPI void (* const chs[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2        3         4         5         6         7          8           9             10
//          Long integer Real34   Complex34 Time      Date      String    Real34 mat Complex34 m Short integer Config data
            chsLonI,     chsReal, chsCplx,  chsReal,  chsError, chsError, chsRema,   chsCxma,    chsShoI,      chsError      //JM added REAL handling for TIME
};



/********************************************//**
 * \brief Data type error in +/-
 *
 * \param void
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  static void chsError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot change the sign of %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnChangeSign:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief rexX ==> regL and -regX ==> regX
 * Drops Y, enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnChangeSign(uint16_t unusedButMandatoryParameter) {
  //if(!saveLastX()) {
  //  return;
  //}

  chs[getRegisterDataType(REGISTER_X)]();
}



static void chsLonI(void) {
  switch(getRegisterLongIntegerSign(REGISTER_X)) {
    case LI_POSITIVE: {
      setRegisterLongIntegerSign(REGISTER_X, LI_NEGATIVE);
      break;
    }
    case LI_NEGATIVE: {
      setRegisterLongIntegerSign(REGISTER_X, LI_POSITIVE);
      break;
    }
    default: {
    }
  }
}



static void chsRema(void) {
  elementwiseRema(chsReal);
}



static void chsCxma(void) {
  elementwiseCxma(chsCplx);
}



static void chsShoI(void) {
  *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = WP34S_intChs(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)));
}



void chsReal(void) {
  if(!getSystemFlag(FLAG_SPCRES) && real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X))) {
    displayCalcErrorMessage(real34IsPositive(REGISTER_REAL34_DATA(REGISTER_X)) ? ERROR_OVERFLOW_MINUS_INF : ERROR_OVERFLOW_PLUS_INF , ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function chsReal:", "cannot change infinity sign while D flag is clear", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  real34ChangeSign(REGISTER_REAL34_DATA(REGISTER_X));

  if(real34IsZero(REGISTER_REAL34_DATA(REGISTER_X)) && !getSystemFlag(FLAG_SPCRES)) {
    real34SetPositiveSign(REGISTER_REAL34_DATA(REGISTER_X));
  }
}



void chsCplx(void) {
  if(!getSystemFlag(FLAG_SPCRES)) {
    if(real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X))) {
      displayCalcErrorMessage(real34IsPositive(REGISTER_REAL34_DATA(REGISTER_X)) ? ERROR_OVERFLOW_MINUS_INF : ERROR_OVERFLOW_PLUS_INF , ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function chsCplx:", "cannot change infinity sign of real part while D flag is clear", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }

    if(real34IsInfinite(REGISTER_IMAG34_DATA(REGISTER_X))) {
      displayCalcErrorMessage(real34IsPositive(REGISTER_IMAG34_DATA(REGISTER_X)) ? ERROR_OVERFLOW_MINUS_INF : ERROR_OVERFLOW_PLUS_INF , ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function chsCplx:", "cannot change infinity sign of imaginary part while D flag is clear", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }
  }

  complex34ChangeSign(REGISTER_COMPLEX34_DATA(REGISTER_X));

  if(real34IsZero(REGISTER_REAL34_DATA(REGISTER_X)) && !getSystemFlag(FLAG_SPCRES)) {
    real34SetPositiveSign(REGISTER_REAL34_DATA(REGISTER_X));
  }

  if(real34IsZero(REGISTER_IMAG34_DATA(REGISTER_X)) && !getSystemFlag(FLAG_SPCRES)) {
    real34SetPositiveSign(REGISTER_IMAG34_DATA(REGISTER_X));
  }
}
