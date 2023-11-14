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
 * \file arctanh.c
 ***********************************************/

#include "mathematics/arctanh.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "fonts.h"
#include "items.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/division.h"
#include "mathematics/ln.h"
#include "mathematics/matrix.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "wp43.h"



TO_QSPI void (* const arctanh[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1             2            3            4             5             6             7            8            9             10
//          Long integer  Real34       Complex34    Time          Date          String        Real34 mat   Complex34 m  Short integer Config data
            arctanhLonI,  arctanhReal, arctanhCplx, arctanhError, arctanhError, arctanhError, arctanhRema, arctanhCxma, arctanhError, arctanhError
};



/********************************************//**
 * \brief Data type error in arctanh
 *
 * \param void
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void arctanhError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate arctanh for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnArctanh:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and arctanh(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnArctanh(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  arctanh[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}



void arctanhLonI(void) {
  real_t x;

  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);

  if(realIsZero(&x)) {
    reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
    real34Zero(REGISTER_REAL34_DATA(REGISTER_X));
  }
  else {
    if(realCompareEqual(&x, const_1)) {
      if(getSystemFlag(FLAG_SPCRES)) {
        reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
        convertRealToReal34ResultRegister(const_plusInfinity, REGISTER_X);
      }
      else {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        #if(EXTRA_INFO_ON_CALC_ERROR == 1)
          moreInfoOnError("In function arctanhLonI:", "X = 1", "and DANGER flag is not set!", NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
       }
    }
    else if(realCompareEqual(&x, const__1)) {
      if(getSystemFlag(FLAG_SPCRES)) {
        reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
        convertRealToReal34ResultRegister(const_minusInfinity, REGISTER_X);
      }
      else {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        #if(EXTRA_INFO_ON_CALC_ERROR == 1)
          moreInfoOnError("In function arctanhLonI:", "X = -1", "and DANGER flag is not set!", NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
       }
    }
    else {
      if(getFlag(FLAG_CPXRES)) {
        reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
        convertRealToReal34ResultRegister(&x, REGISTER_X);
        real34Zero(REGISTER_IMAG34_DATA(REGISTER_X));
        arctanhCplx();
      }
      else if(getSystemFlag(FLAG_SPCRES)) {
        reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
        convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
      }
      else {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        #if(EXTRA_INFO_ON_CALC_ERROR == 1)
          moreInfoOnError("In function arctanhLonI:", "|X| > 1", "and CPXRES is not set!", NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      }
    }
  }
}



void arctanhRema(void) {
  elementwiseRema(arctanhReal);
}



void arctanhCxma(void) {
  elementwiseCxma(arctanhCplx);
}



void arctanhReal(void) {
  real_t x;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);

  if(realIsZero(&x)) {
    real34Zero(REGISTER_REAL34_DATA(REGISTER_X));
  }
  else {
    if(realCompareEqual(&x, const_1)) {
      if(getSystemFlag(FLAG_SPCRES)) {
        convertRealToReal34ResultRegister(const_plusInfinity, REGISTER_X);
      }
      else {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        #if(EXTRA_INFO_ON_CALC_ERROR == 1)
          moreInfoOnError("In function arctanhReal:", "X = 1", "and DANGER flag is not set!", NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
       }
    }
    else if(realCompareEqual(&x, const__1)) {
      if(getSystemFlag(FLAG_SPCRES)) {
        convertRealToReal34ResultRegister(const_minusInfinity, REGISTER_X);
      }
      else {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        #if(EXTRA_INFO_ON_CALC_ERROR == 1)
          moreInfoOnError("In function arctanhReal:", "X = -1", "and DANGER flag is not set!", NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
       }
    }
    else {
      if(realCompareAbsGreaterThan(&x, const_1)) {
        if(getFlag(FLAG_CPXRES)) {
          reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
          convertRealToReal34ResultRegister(&x, REGISTER_X);
          real34Zero(REGISTER_IMAG34_DATA(REGISTER_X));
          arctanhCplx();
        }
        else if(getSystemFlag(FLAG_SPCRES)) {
          convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
        }
        else {
          displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
          #if(EXTRA_INFO_ON_CALC_ERROR == 1)
            moreInfoOnError("In function arctanhReal:", "|X| > 1", "and CPXRES is not set!", NULL);
          #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        }
      }
      else {
        WP34S_ArcTanh(&x, &x, &ctxtReal39);
        convertRealToReal34ResultRegister(&x, REGISTER_X);
      }
    }
  }
  setRegisterAngularMode(REGISTER_X, amNone);
}



void arctanhCplx(void) {
  //                    1       1 + (a + ib)
  // arctanh(a + i b) = - * ln( ------------ )
  //                    2       1 - (a + ib)

  real_t numerReal, denomReal;
  real_t numerImag, denomImag;

  // numer = 1 + (a + ib)
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &numerReal);
  realAdd(&numerReal, const_1, &numerReal, &ctxtReal39);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &numerImag);

  // denom = 1 - (a + ib)
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &denomReal);
  realSubtract(const_1, &denomReal, &denomReal, &ctxtReal39);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &denomImag);
  realChangeSign(&denomImag);

  // numer = (1 + (a + ib)) / (1 - (a + ib)
  divComplexComplex(&numerReal, &numerImag, &denomReal, &denomImag, &numerReal, &numerImag, &ctxtReal39);

  // numer = ln((1 + (a + ib)) / (1 - (a + ib))
  lnComplex(&numerReal, &numerImag, &numerReal, &numerImag, &ctxtReal39);

  // 1/2 * ln((1 + (a + ib)) / (1 - (a + ib))
  realMultiply(&numerReal, const_1on2, &numerReal, &ctxtReal39);
  realMultiply(&numerImag, const_1on2, &numerImag, &ctxtReal39);

  convertRealToReal34ResultRegister(&numerReal, REGISTER_X);
  convertRealToImag34ResultRegister(&numerImag, REGISTER_X);
}
