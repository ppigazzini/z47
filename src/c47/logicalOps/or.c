// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file or.c
 ***********************************************/

#include "c47.h"

TO_QSPI void (* const logicalOr[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX |    regY ==>   1            2            3          4          5          6          7           8            9             10
//      V               Long integer Real34       Complex34  Time       Date       String     Real34 mat  Complex34 m  Short integer Config data
/*  1 Long integer  */ {orLonILonI,  orRealLonI,  orError24, orError24, orError24, orError24, orError24,  orError24,   orError31,    orError24},
/*  2 Real34        */ {orLonIReal,  orRealReal,  orError24, orError24, orError24, orError24, orError24,  orError24,   orError31,    orError24},
/*  3 Complex34     */ {orError24,   orError24,   orError24, orError24, orError24, orError24, orError24,  orError24,   orError24,    orError24},
/*  4 Time          */ {orError24,   orError24,   orError24, orError24, orError24, orError24, orError24,  orError24,   orError24,    orError24},
/*  5 Date          */ {orError24,   orError24,   orError24, orError24, orError24, orError24, orError24,  orError24,   orError24,    orError24},
/*  6 String        */ {orError24,   orError24,   orError24, orError24, orError24, orError24, orError24,  orError24,   orError24,    orError24},
/*  7 Real34 mat    */ {orError24,   orError24,   orError24, orError24, orError24, orError24, orError24,  orError24,   orError24,    orError24},
/*  8 Complex34 mat */ {orError24,   orError24,   orError24, orError24, orError24, orError24, orError24,  orError24,   orError24,    orError24},
/*  9 Short integer */ {orError31,   orError31,   orError24, orError24, orError24, orError24, orError24,  orError24,   orShoIShoI,   orError24},
/* 10 Config data   */ {orError24,   orError24,   orError24, orError24, orError24, orError24, orError24,  orError24,   orError24,    orError24}
};



/********************************************//**
 * \brief Data type error in OR
 *
 * \param void
 * \return void
 ***********************************************/
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  void orError24(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "%s OR %s", getRegisterDataTypeName(REGISTER_Y, false, false), getRegisterDataTypeName(REGISTER_X, false, false));
    sprintf(errorMessage + ERROR_MESSAGE_LENGTH/2, "data type of one of the OR parameters is not allowed");
    moreInfoOnError("In function orError24:", errorMessage, errorMessage + ERROR_MESSAGE_LENGTH/2, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

void orError31(void) {
  displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    sprintf(errorMessage, "%s OR %s", getRegisterDataTypeName(REGISTER_Y, false, false), getRegisterDataTypeName(REGISTER_X, false, false));
    sprintf(errorMessage + ERROR_MESSAGE_LENGTH/2, "OR doesn't allow mixing data types real/long integer and short integer");
    moreInfoOnError("In function orError31:", errorMessage, errorMessage + ERROR_MESSAGE_LENGTH/2, NULL);
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
}



/********************************************//**
 * \brief regX ==> regL OR regY ÷ regX ==> regX
 * Drops Y, enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter
 * \return void
 ***********************************************/
void fnLogicalOr(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }
  logicalOr[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)]();
  fnDropY(NOPARAM);
}



void orLonILonI(void) {
  longInteger_t x, res;

  convertLongIntegerRegisterToLongInteger(REGISTER_X, x);
  convertLongIntegerRegisterToLongInteger(REGISTER_Y, res);

  if(longIntegerIsZero(x) && longIntegerIsZero(res)) {
    uInt32ToLongInteger(0u, res);
  }
  else {
    uInt32ToLongInteger(1u, res);
  }

  convertLongIntegerToLongIntegerRegister(res, REGISTER_X);

  longIntegerFree(x);
  longIntegerFree(res);
}



void orLonIReal(void) {
  longInteger_t res;

  convertLongIntegerRegisterToLongInteger(REGISTER_Y, res);

  if(real34IsZero(REGISTER_REAL34_DATA(REGISTER_X)) && longIntegerIsZero(res)) {
    uInt32ToLongInteger(0u, res);
  }
  else {
    uInt32ToLongInteger(1u, res);
  }

  convertLongIntegerToLongIntegerRegister(res, REGISTER_X);

  longIntegerFree(res);
}



void orRealLonI(void) {
  longInteger_t res;

  convertLongIntegerRegisterToLongInteger(REGISTER_X, res);

  if(real34IsZero(REGISTER_REAL34_DATA(REGISTER_Y)) && longIntegerIsZero(res)) {
    uInt32ToLongInteger(0u, res);
  }
  else {
    uInt32ToLongInteger(1u, res);
  }

  convertLongIntegerToLongIntegerRegister(res, REGISTER_X);

  longIntegerFree(res);
}



void orRealReal(void) {
  longInteger_t res;

  longIntegerInit(res);
  if(real34IsZero(REGISTER_REAL34_DATA(REGISTER_X)) && real34IsZero(REGISTER_REAL34_DATA(REGISTER_Y))) {
    uInt32ToLongInteger(0u, res);
  }
  else {
    uInt32ToLongInteger(1u, res);
  }

  convertLongIntegerToLongIntegerRegister(res, REGISTER_X);

  longIntegerFree(res);
}



void orShoIShoI(void) {
  *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) | *(REGISTER_SHORT_INTEGER_DATA(REGISTER_Y));
  setRegisterShortIntegerBase(REGISTER_X, getRegisterShortIntegerBase(REGISTER_Y));
}
