// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file xor.c
 ***********************************************/

#include "c47.h"

TO_QSPI void (* const logicalXor[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX |    regY ==>   1            2            3           4           5           6           7           8            9             10
//      V               Long integer Real34       Complex34   Time        Date        String      Real34 mat  Complex34 m  Short integer Config data
/*  1 Long integer  */ {xorLonILonI, xorRealLonI, xorError24, xorError24, xorError24, xorError24, xorError24, xorError24,  xorError31,   xorError24},
/*  2 Real34        */ {xorLonIReal, xorRealReal, xorError24, xorError24, xorError24, xorError24, xorError24, xorError24,  xorError31,   xorError24},
/*  3 Complex34     */ {xorError24,  xorError24,  xorError24, xorError24, xorError24, xorError24, xorError24, xorError24,  xorError24,   xorError24},
/*  4 Time          */ {xorError24,  xorError24,  xorError24, xorError24, xorError24, xorError24, xorError24, xorError24,  xorError24,   xorError24},
/*  5 Date          */ {xorError24,  xorError24,  xorError24, xorError24, xorError24, xorError24, xorError24, xorError24,  xorError24,   xorError24},
/*  6 String        */ {xorError24,  xorError24,  xorError24, xorError24, xorError24, xorError24, xorError24, xorError24,  xorError24,   xorError24},
/*  7 Real34 mat    */ {xorError24,  xorError24,  xorError24, xorError24, xorError24, xorError24, xorError24, xorError24,  xorError24,   xorError24},
/*  8 Complex34 mat */ {xorError24,  xorError24,  xorError24, xorError24, xorError24, xorError24, xorError24, xorError24,  xorError24,   xorError24},
/*  9 Short integer */ {xorError31,  xorError31,  xorError24, xorError24, xorError24, xorError24, xorError24, xorError24,  xorShoIShoI,  xorError24},
/* 10 Config data   */ {xorError24,  xorError24,  xorError24, xorError24, xorError24, xorError24, xorError24, xorError24,  xorError24,   xorError24}
};



/********************************************//**
 * \brief Data type error in XOR
 *
 * \param void
 * \return void
 ***********************************************/
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  void xorError24(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "%s XOR %s", getRegisterDataTypeName(REGISTER_Y, false, false), getRegisterDataTypeName(REGISTER_X, false, false));
    sprintf(errorMessage + ERROR_MESSAGE_LENGTH/2, "data type of one of the XOR parameters is not allowed");
    moreInfoOnError("In function xorError24:", errorMessage, errorMessage + ERROR_MESSAGE_LENGTH/2, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

void xorError31(void) {
  displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    sprintf(errorMessage, "%s XOR %s", getRegisterDataTypeName(REGISTER_Y, false, false), getRegisterDataTypeName(REGISTER_X, false, false));
    sprintf(errorMessage + ERROR_MESSAGE_LENGTH/2, "XOR doesn't allow mixing data types real/long integer and short integer");
    moreInfoOnError("In function xorError31:", errorMessage, errorMessage + ERROR_MESSAGE_LENGTH/2, NULL);
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
}



/********************************************//**
 * \brief regX ==> regL XOR regY ÷ regX ==> regX
 * Drops Y, enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter
 * \return void
 ***********************************************/
void fnLogicalXor(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }
  logicalXor[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)]();
  fnDropY(NOPARAM);
}



void xorLonILonI(void) {
  longInteger_t x, res;

  convertLongIntegerRegisterToLongInteger(REGISTER_X, x);
  convertLongIntegerRegisterToLongInteger(REGISTER_Y, res);

  if((longIntegerIsZero(x) && longIntegerIsZero(res)) || (!longIntegerIsZero(x) && !longIntegerIsZero(res))) {
    uIntToLongInteger(0, res);
  }
  else {
    uIntToLongInteger(1, res);
  }

  convertLongIntegerToLongIntegerRegister(res, REGISTER_X);

  longIntegerFree(x);
  longIntegerFree(res);
}



void xorLonIReal(void) {
  longInteger_t res;

  convertLongIntegerRegisterToLongInteger(REGISTER_Y, res);

  if((real34IsZero(REGISTER_REAL34_DATA(REGISTER_X)) && longIntegerIsZero(res)) || (!real34IsZero(REGISTER_REAL34_DATA(REGISTER_X)) && !longIntegerIsZero(res))) {
    uIntToLongInteger(0, res);
  }
  else {
    uIntToLongInteger(1, res);
  }

  convertLongIntegerToLongIntegerRegister(res, REGISTER_X);

  longIntegerFree(res);
}



void xorRealLonI(void) {
  longInteger_t res;

  convertLongIntegerRegisterToLongInteger(REGISTER_X, res);

  if((real34IsZero(REGISTER_REAL34_DATA(REGISTER_Y)) && longIntegerIsZero(res)) || (!real34IsZero(REGISTER_REAL34_DATA(REGISTER_Y)) && !longIntegerIsZero(res))) {
    uIntToLongInteger(0, res);
  }
  else {
    uIntToLongInteger(1, res);
  }

  convertLongIntegerToLongIntegerRegister(res, REGISTER_X);

  longIntegerFree(res);
}



void xorRealReal(void) {
  longInteger_t res;

  longIntegerInit(res);
  if((real34IsZero(REGISTER_REAL34_DATA(REGISTER_X)) && real34IsZero(REGISTER_REAL34_DATA(REGISTER_Y))) || (!real34IsZero(REGISTER_REAL34_DATA(REGISTER_X)) && !real34IsZero(REGISTER_REAL34_DATA(REGISTER_Y)))) {
    uIntToLongInteger(0, res);
  }
  else {
    uIntToLongInteger(1, res);
  }

  convertLongIntegerToLongIntegerRegister(res, REGISTER_X);

  longIntegerFree(res);
}



void xorShoIShoI(void) {
  *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) ^ *(REGISTER_SHORT_INTEGER_DATA(REGISTER_Y));
  setRegisterShortIntegerBase(REGISTER_X, getRegisterShortIntegerBase(REGISTER_Y));
}
