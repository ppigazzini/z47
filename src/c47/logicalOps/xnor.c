// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file xnor.c
 ***********************************************/

#include "c47.h"

TO_QSPI void (* const logicalXnor[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX |    regY ==>   1             2             3            4            5            6            7            8             9             10
//      V               Long integer  Real34        Complex34    Time         Date         String       Real34 mat   Complex34 m   Short integer Config data
/*  1 Long integer  */ {xnorLonILonI, xnorRealLonI, xnorError24, xnorError24, xnorError24, xnorError24, xnorError24, xnorError24,  xnorError31,  xnorError24},
/*  2 Real34        */ {xnorLonIReal, xnorRealReal, xnorError24, xnorError24, xnorError24, xnorError24, xnorError24, xnorError24,  xnorError31,  xnorError24},
/*  3 Complex34     */ {xnorError24,  xnorError24,  xnorError24, xnorError24, xnorError24, xnorError24, xnorError24, xnorError24,  xnorError24,  xnorError24},
/*  4 Time          */ {xnorError24,  xnorError24,  xnorError24, xnorError24, xnorError24, xnorError24, xnorError24, xnorError24,  xnorError24,  xnorError24},
/*  5 Date          */ {xnorError24,  xnorError24,  xnorError24, xnorError24, xnorError24, xnorError24, xnorError24, xnorError24,  xnorError24,  xnorError24},
/*  6 String        */ {xnorError24,  xnorError24,  xnorError24, xnorError24, xnorError24, xnorError24, xnorError24, xnorError24,  xnorError24,  xnorError24},
/*  7 Real34 mat    */ {xnorError24,  xnorError24,  xnorError24, xnorError24, xnorError24, xnorError24, xnorError24, xnorError24,  xnorError24,  xnorError24},
/*  8 Complex34 mat */ {xnorError24,  xnorError24,  xnorError24, xnorError24, xnorError24, xnorError24, xnorError24, xnorError24,  xnorError24,  xnorError24},
/*  9 Short integer */ {xnorError31,  xnorError31,  xnorError24, xnorError24, xnorError24, xnorError24, xnorError24, xnorError24,  xnorShoIShoI, xnorError24},
/* 10 Config data   */ {xnorError24,  xnorError24,  xnorError24, xnorError24, xnorError24, xnorError24, xnorError24, xnorError24,  xnorError24,  xnorError24}
};



/********************************************//**
 * \brief Data type error in XNOR
 *
 * \param void
 * \return void
 ***********************************************/
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  void xnorError24(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "%s XNOR %s", getRegisterDataTypeName(REGISTER_Y, false, false), getRegisterDataTypeName(REGISTER_X, false, false));
    sprintf(errorMessage + ERROR_MESSAGE_LENGTH/2, "data type of one of the XNOR parameters is not allowed");
    moreInfoOnError("In function xnorError24:", errorMessage, errorMessage + ERROR_MESSAGE_LENGTH/2, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

void xnorError31(void) {
  displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    sprintf(errorMessage, "%s XNOR %s", getRegisterDataTypeName(REGISTER_Y, false, false), getRegisterDataTypeName(REGISTER_X, false, false));
    sprintf(errorMessage + ERROR_MESSAGE_LENGTH/2, "XNOR doesn't allow mixing data types real/long integer and short integer");
    moreInfoOnError("In function xnorError31:", errorMessage, errorMessage + ERROR_MESSAGE_LENGTH/2, NULL);
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
}



/********************************************//**
 * \brief regX ==> regL XNOR regY ÷ regX ==> regX
 * Drops Y, enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter
 * \return void
 ***********************************************/
void fnLogicalXnor(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }
  logicalXnor[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)]();
  fnDropY(NOPARAM);
}



void xnorLonILonI(void) {
  longInteger_t x, res;

  convertLongIntegerRegisterToLongInteger(REGISTER_X, x);
  convertLongIntegerRegisterToLongInteger(REGISTER_Y, res);

  if((longIntegerIsZero(x) && longIntegerIsZero(res)) || (!longIntegerIsZero(x) && !longIntegerIsZero(res))) {
    uIntToLongInteger(1, res);
  }
  else {
    uIntToLongInteger(0, res);
  }

  convertLongIntegerToLongIntegerRegister(res, REGISTER_X);

  longIntegerFree(x);
  longIntegerFree(res);
}



void xnorLonIReal(void) {
  longInteger_t res;

  convertLongIntegerRegisterToLongInteger(REGISTER_Y, res);

  if((real34IsZero(REGISTER_REAL34_DATA(REGISTER_X)) && longIntegerIsZero(res)) || (!real34IsZero(REGISTER_REAL34_DATA(REGISTER_X)) && !longIntegerIsZero(res))) {
    uIntToLongInteger(1, res);
  }
  else {
    uIntToLongInteger(0, res);
  }

  convertLongIntegerToLongIntegerRegister(res, REGISTER_X);

  longIntegerFree(res);
}



void xnorRealLonI(void) {
  longInteger_t res;

  convertLongIntegerRegisterToLongInteger(REGISTER_X, res);

  if((real34IsZero(REGISTER_REAL34_DATA(REGISTER_Y)) && longIntegerIsZero(res)) || (!real34IsZero(REGISTER_REAL34_DATA(REGISTER_Y)) && !longIntegerIsZero(res))) {
    uIntToLongInteger(1, res);
  }
  else {
    uIntToLongInteger(0, res);
  }

  convertLongIntegerToLongIntegerRegister(res, REGISTER_X);

  longIntegerFree(res);
}



void xnorRealReal(void) {
  longInteger_t res;

  longIntegerInit(res);
  if((real34IsZero(REGISTER_REAL34_DATA(REGISTER_X)) && real34IsZero(REGISTER_REAL34_DATA(REGISTER_Y))) || (!real34IsZero(REGISTER_REAL34_DATA(REGISTER_X)) && !real34IsZero(REGISTER_REAL34_DATA(REGISTER_Y)))) {
    uIntToLongInteger(1, res);
  }
  else {
    uIntToLongInteger(0, res);
  }

  convertLongIntegerToLongIntegerRegister(res, REGISTER_X);

  longIntegerFree(res);
}



void xnorShoIShoI(void) {
  *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = ~(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) ^ *(REGISTER_SHORT_INTEGER_DATA(REGISTER_Y))) & shortIntegerMask;
  setRegisterShortIntegerBase(REGISTER_X, getRegisterShortIntegerBase(REGISTER_Y));
}
