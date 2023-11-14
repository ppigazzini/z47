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
 * \file percentPlusMG.c
 ***********************************************/

#include "mathematics/percentPlusMG.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "mathematics/comparisonReals.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "wp43.h"

static void dataTypeError(void);

TO_QSPI void (* const percentPlusMG[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX |    regY ==>    1                      2                      3              4              5              6              7              8              9              10
//      V                Long integer           Real34                 Complex34      Time           Date           String         Real34 mat     Complex34 mat  Short integer  Config data
/*  1 Long integer  */ { percentPlusMGLonILonI, percentPlusMGRealLonI, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError},
/*  2 Real34        */ { percentPlusMGLonIReal, percentPlusMGRealReal, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError},
/*  3 Complex34     */ { dataTypeError,         dataTypeError,         dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError},
/*  4 Time          */ { dataTypeError,         dataTypeError,         dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError},
/*  5 Date          */ { dataTypeError,         dataTypeError,         dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError},
/*  6 String        */ { dataTypeError,         dataTypeError,         dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError},
/*  7 Real34 mat    */ { dataTypeError,         dataTypeError,         dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError},
/*  8 Complex34 mat */ { dataTypeError,         dataTypeError,         dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError},
/*  9 Short integer */ { dataTypeError,         dataTypeError,         dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError},
/* 10 Config data   */ { dataTypeError,         dataTypeError,         dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError, dataTypeError}
};

//=============================================================================
// Error handling
//-----------------------------------------------------------------------------

/********************************************//**
 * \brief Data type error in %+MG
 *
 * \param void
 * \return void
 ***********************************************/
static void dataTypeError(void) {
  displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);

  #if(EXTRA_INFO_ON_CALC_ERROR == 1)
    sprintf(errorMessage, "cannot use %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnPercentPlusMG:", errorMessage, NULL, NULL);
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
}

//=============================================================================
// Main function
//-----------------------------------------------------------------------------

/********************************************//**
 * \brief regX ==> regL and PercentSigma(regX) ==> regX
 * enables stack lift and refreshes the stack.
 * Calculate %Sigma
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnPercentPlusMG(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  percentPlusMG[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)]();

  adjustResult(REGISTER_X, true, true, REGISTER_X, -1, -1);
}

//=============================================================================
// %+MG calculation functions
//-----------------------------------------------------------------------------

static bool_t percentPlusMGReal(real_t *xReal, real_t *yReal, real_t *rReal, realContext_t *realContext) {
  /*
   * Check x and y
   */
  if(realCompareEqual(xReal, const_100) && realIsZero(yReal)) {
    if(getSystemFlag(FLAG_SPCRES)) {
      realCopy(const_NaN, rReal);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function fnPercentPlusMG:", "cannot divide 0 by 0", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return false;
    }
  }
  else if(realCompareEqual(xReal, const_100)) {
    if(getSystemFlag(FLAG_SPCRES)) {
      realCopy((realIsPositive(yReal) ? const_plusInfinity : const_minusInfinity), rReal);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function fnPercenPlusMG:", "cannot divide a real by 0", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return false;
    }
  }
  else {
    realDivide(xReal, const_100, rReal, realContext);    // r = x / 100.0
    realSubtract(const_1, rReal, rReal, realContext);    // r = 1 - x/100
    realDivide(yReal, rReal, rReal, realContext);        // r = y / (1 - x/100)
  }

  return true;
}

/********************************************//**
 * \brief PercentT(Y(long integer), X(long integer)) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void percentPlusMGLonILonI(void) {
  real_t xReal, yReal;
  real_t rReal;

  convertLongIntegerRegisterToReal(REGISTER_X, &xReal, &ctxtReal75);
  convertLongIntegerRegisterToReal(REGISTER_Y, &yReal, &ctxtReal75);

  if(percentPlusMGReal(&xReal, &yReal, &rReal, &ctxtReal75)) {
    reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
    convertRealToReal34ResultRegister(&rReal, REGISTER_X);
    setRegisterAngularMode(REGISTER_X, amNone);
  }
}

/********************************************//**
 * \brief PercentT(Y(long integer), X(real34)) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void percentPlusMGLonIReal(void) {
  real_t xReal, yReal;
  real_t rReal;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  convertLongIntegerRegisterToReal(REGISTER_Y, &yReal, &ctxtReal75);

  if(percentPlusMGReal(&xReal, &yReal, &rReal, &ctxtReal75)) {
    convertRealToReal34ResultRegister(&rReal, REGISTER_X);
  }
}

/********************************************//**
 * \brief PercentT(Y(real34), X(long integer)) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void percentPlusMGRealLonI(void) {
  real_t xReal, yReal;
  real_t rReal;

  convertLongIntegerRegisterToReal(REGISTER_X, &xReal, &ctxtReal75);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);

  if(percentPlusMGReal(&xReal, &yReal, &rReal, &ctxtReal75)) {
    reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
    convertRealToReal34ResultRegister(&rReal, REGISTER_X);
    setRegisterAngularMode(REGISTER_X, amNone);
  }
}

/********************************************//**
 * \brief PercentT(Y(real34), X(real34)) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void percentPlusMGRealReal(void) {
  real_t xReal, yReal;
  real_t rReal;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);

  if(percentPlusMGReal(&xReal, &yReal, &rReal, &ctxtReal39)) {
    convertRealToReal34ResultRegister(&rReal, REGISTER_X);
  }
}
