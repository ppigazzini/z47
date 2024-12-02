// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file gcd.c
 ***********************************************/

#include "mathematics/gcd.h"

#include "debug.h"
#include "error.h"
#include "integers.h"
#include "items.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "stack.h"

#include "c47.h"



TO_QSPI void (* const gcd[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX |    regY ==>   1            2         3         4         5         6         7          8           9             10
//      V               Long integer Real34    Complex34 Time      Date      String    Real34 mat Complex34 m Short integer Config data
/*  1 Long integer  */ {gcdLonILonI, gcdError, gcdError, gcdError, gcdError, gcdError, gcdError,  gcdError,   gcdShoILonI,  gcdError},
/*  2 Real34        */ {gcdError,    gcdError, gcdError, gcdError, gcdError, gcdError, gcdError,  gcdError,   gcdError,     gcdError},
/*  3 Complex34     */ {gcdError,    gcdError, gcdError, gcdError, gcdError, gcdError, gcdError,  gcdError,   gcdError,     gcdError},
/*  4 Time          */ {gcdError,    gcdError, gcdError, gcdError, gcdError, gcdError, gcdError,  gcdError,   gcdError,     gcdError},
/*  5 Date          */ {gcdError,    gcdError, gcdError, gcdError, gcdError, gcdError, gcdError,  gcdError,   gcdError,     gcdError},
/*  6 String        */ {gcdError,    gcdError, gcdError, gcdError, gcdError, gcdError, gcdError,  gcdError,   gcdError,     gcdError},
/*  7 Real34 mat    */ {gcdError,    gcdError, gcdError, gcdError, gcdError, gcdError, gcdError,  gcdError,   gcdError,     gcdError},
/*  8 Complex34 mat */ {gcdError,    gcdError, gcdError, gcdError, gcdError, gcdError, gcdError,  gcdError,   gcdError,     gcdError},
/*  9 Short integer */ {gcdLonIShoI, gcdError, gcdError, gcdError, gcdError, gcdError, gcdError,  gcdError,   gcdShoIShoI,  gcdError},
/* 10 Config data   */ {gcdError,    gcdError, gcdError, gcdError, gcdError, gcdError, gcdError,  gcdError,   gcdError,     gcdError}
};



/********************************************//**
 * \brief Data type error in gcd
 *
 * \param void
 * \return void
 ***********************************************/
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  void gcdError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate gcd (%s, %s)", getRegisterDataTypeName(REGISTER_Y, true, false), getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnGcd:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)


void _longIntegerGcd(longInteger_t liY, longInteger_t liX, longInteger_t liA) {
  if(longIntegerIsZero(liY) && longIntegerIsZero(liX)) {
    #if !defined(TESTSUITE_BUILD)
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function fnGcd:", "(0, 0) is not in the function domain.", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    #endif //TESTSUITE_BUILD
  } else {
    longIntegerGcd(liY, liX, liA);
  }
}


/********************************************//**
 * \brief regX ==> regL and GDC(regY, regX) ==> regX
 * Drops Y, enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnGcd(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }
  gcd[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)]();
  fnDropY(NOPARAM);
}



void gcdLonILonI(void) {
  longInteger_t liX, liY;

  convertLongIntegerRegisterToLongInteger(REGISTER_Y, liY);
  longIntegerSetPositiveSign(liY);
  convertLongIntegerRegisterToLongInteger(REGISTER_X, liX);
  longIntegerSetPositiveSign(liX);

  _longIntegerGcd(liY, liX, liX);

  convertLongIntegerToLongIntegerRegister(liX, REGISTER_X);

  longIntegerFree(liX);
  longIntegerFree(liY);
}



void gcdLonIShoI(void) {
  longInteger_t liX, liY;

  convertLongIntegerRegisterToLongInteger(REGISTER_Y, liY);
  longIntegerSetPositiveSign(liY);
  convertShortIntegerRegisterToLongInteger(REGISTER_X, liX);
  longIntegerSetPositiveSign(liX);

  _longIntegerGcd(liY, liX, liX);

  convertLongIntegerToLongIntegerRegister(liX, REGISTER_X);

  longIntegerFree(liX);
  longIntegerFree(liY);
}



void gcdShoILonI(void) {
  longInteger_t liX, liY;

  convertLongIntegerRegisterToLongInteger(REGISTER_X, liX);
  longIntegerSetPositiveSign(liX);
  convertShortIntegerRegisterToLongInteger(REGISTER_Y, liY);
  longIntegerSetPositiveSign(liY);

  _longIntegerGcd(liY, liX, liX);

  convertLongIntegerToLongIntegerRegister(liX, REGISTER_X);

  longIntegerFree(liX);
  longIntegerFree(liY);
}



void gcdShoIShoI(void) {
  *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = WP34S_intGCD(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_Y)), *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)));
}
