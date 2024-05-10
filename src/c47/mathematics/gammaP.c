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
 * \file gammaP.c
 ***********************************************/

#include "mathematics/gammaP.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "fonts.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"



TO_QSPI void (* const GammaP[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX |    regY ==>   1               2               3            4            5            6            7            8            9             10
//      V               Long integer    Real34          Complex34    Time         Date         String       Real34 mat   Complex34 m  Short integer Config data
/*  1 Long integer  */ {gammaPLonILonI, gammaPLonIReal, gammaPError, gammaPError, gammaPError, gammaPError, gammaPError, gammaPError, gammaPError,  gammaPError},
/*  2 Real34        */ {gammaPRealLonI, gammaPRealReal, gammaPError, gammaPError, gammaPError, gammaPError, gammaPError, gammaPError, gammaPError,  gammaPError},
/*  3 Complex34     */ {gammaPError,    gammaPError,    gammaPError, gammaPError, gammaPError, gammaPError, gammaPError, gammaPError, gammaPError,  gammaPError},
/*  4 Time          */ {gammaPError,    gammaPError,    gammaPError, gammaPError, gammaPError, gammaPError, gammaPError, gammaPError, gammaPError,  gammaPError},
/*  5 Date          */ {gammaPError,    gammaPError,    gammaPError, gammaPError, gammaPError, gammaPError, gammaPError, gammaPError, gammaPError,  gammaPError},
/*  6 String        */ {gammaPError,    gammaPError,    gammaPError, gammaPError, gammaPError, gammaPError, gammaPError, gammaPError, gammaPError,  gammaPError},
/*  7 Real34 mat    */ {gammaPError,    gammaPError,    gammaPError, gammaPError, gammaPError, gammaPError, gammaPError, gammaPError, gammaPError,  gammaPError},
/*  8 Complex34 mat */ {gammaPError,    gammaPError,    gammaPError, gammaPError, gammaPError, gammaPError, gammaPError, gammaPError, gammaPError,  gammaPError},
/*  9 Short integer */ {gammaPError,    gammaPError,    gammaPError, gammaPError, gammaPError, gammaPError, gammaPError, gammaPError, gammaPError,  gammaPError},
/* 10 Config data   */ {gammaPError,    gammaPError,    gammaPError, gammaPError, gammaPError, gammaPError, gammaPError, gammaPError, gammaPError,  gammaPError}
};



/********************************************//**
 * \brief Data type error in regularised gamma function
 *
 * \param void
 * \return void
 ***********************************************/
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  void gammaPError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate I" STD_GAMMA STD_SUB_p " for %s and %s", getRegisterDataTypeName(REGISTER_X, true, false), getRegisterDataTypeName(REGISTER_Y, true, false));
    moreInfoOnError("In function fnGammaP:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and gamma(regX, regY) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnGammaP(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  GammaP[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)]();

  adjustResult(REGISTER_X, true, true, REGISTER_X, REGISTER_Y, -1);
}



void gammaPLonILonI(void) {
  real_t x, y, res;

  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
  convertLongIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);
  if(!getSystemFlag(FLAG_SPCRES) && (realCompareLessEqual(&x, const_0) || realCompareLessThan(&y, const_0))) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function gammaPLonILonI:", "Y must be non-negative and X must be positive", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  else {
    WP34S_GammaP(&y, &x, &res, &ctxtReal39, false, true);
    reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
    convertRealToReal34ResultRegister(&res, REGISTER_X);
  }
}



void gammaPLonIReal(void) {
  real_t x, y, res;

  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
  if(!getSystemFlag(FLAG_SPCRES) && (realCompareLessEqual(&x, const_0) || realCompareLessThan(&y, const_0))) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function gammaPLonIReal:", "Y must be non-negative and X must be positive", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  else {
    WP34S_GammaP(&y, &x, &res, &ctxtReal39, false, true);
    reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
    convertRealToReal34ResultRegister(&res, REGISTER_X);
  }
}



void gammaPRealLonI(void) {
  real_t x, y, res;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
  convertLongIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);
  if(!getSystemFlag(FLAG_SPCRES) && (realCompareLessEqual(&x, const_0) || realCompareLessThan(&y, const_0))) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function gammaPRealLonI:", "Y must be non-negative and X must be positive", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  else {
    WP34S_GammaP(&y, &x, &res, &ctxtReal39, false, true);
    convertRealToReal34ResultRegister(&res, REGISTER_X);
  }
}



void gammaPRealReal(void) {
  real_t x, y, res;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
  if(!getSystemFlag(FLAG_SPCRES) && (realCompareLessEqual(&x, const_0) || realCompareLessThan(&y, const_0))) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function gammaPRealReal:", "Y must be non-negative and X must be positive", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  else {
    WP34S_GammaP(&y, &x, &res, &ctxtReal39, false, true);
    convertRealToReal34ResultRegister(&res, REGISTER_X);
  }
}
