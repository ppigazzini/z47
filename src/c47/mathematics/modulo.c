// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file modulo.c
 ***********************************************/

#include "c47.h"

TO_QSPI void (* const mod[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX |    regY ==>   1            2            3          4         5         6         7          8           9             10
//      V               Long integer Real34       Complex34  Time      Date      String    Real34 mat Complex34 m Short integer Config data
/*  1 Long integer  */ {modLonILonI, modRealLonI, modError,  modError, modError, modError, modError,  modError,   modShoILonI,  modError},
/*  2 Real34        */ {modLonIReal, modRealReal, modError,  modError, modError, modError, modError,  modError,   modShoIReal,  modError},
/*  3 Complex34     */ {modError,    modError,    modError,  modError, modError, modError, modError,  modError,   modError,     modError},
/*  4 Time          */ {modError,    modError,    modError,  modError, modError, modError, modError,  modError,   modError,     modError},
/*  5 Date          */ {modError,    modError,    modError,  modError, modError, modError, modError,  modError,   modError,     modError},
/*  6 String        */ {modError,    modError,    modError,  modError, modError, modError, modError,  modError,   modError,     modError},
/*  7 Real34 mat    */ {modError,    modError,    modError,  modError, modError, modError, modError,  modError,   modError,     modError},
/*  8 Complex34 mat */ {modError,    modError,    modError,  modError, modError, modError, modError,  modError,   modError,     modError},
/*  9 Short integer */ {modLonIShoI, modRealShoI, modError,  modError, modError, modError, modError,  modError,   modShoIShoI,  modError},
/* 10 Config data   */ {modError,    modError,    modError,  modError, modError, modError, modError,  modError,   modError,     modError}
};



/********************************************//**
 * \brief Data type error in IDiv
 *
 * \param[in] unusedButMandatoryParameter
 * \return void
 ***********************************************/
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  void modError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot MOD %s", getRegisterDataTypeName(REGISTER_Y, true, false));
    sprintf(errorMessage + ERROR_MESSAGE_LENGTH/2, "by %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnMod:", errorMessage, errorMessage + ERROR_MESSAGE_LENGTH/2, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and regY mod regX ==> regX
 * Drops Y, enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter
 * \return void
 ***********************************************/
void fnMod(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  mod[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)]();

  adjustResult(REGISTER_X, true, false, REGISTER_X, REGISTER_Y, -1);
}



/******************************************************************************************************************************************************************************************/
/* long integer mod ...                                                                                                                                                                     */
/******************************************************************************************************************************************************************************************/

/********************************************//**
 * \brief Y(long integer) mod X(long integer) ==> X(long integer)
 *
 * \param void
 * \return void
 ***********************************************/
void modLonILonI(void) {
  longInteger_t x;

  convertLongIntegerRegisterToLongInteger(REGISTER_X, x);

  if(longIntegerIsZero(x)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function modLonILonI:", "cannot IDIVR a long integer by 0", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  else {
    longInteger_t y, remainder;

    convertLongIntegerRegisterToLongInteger(REGISTER_Y, y);

    longIntegerInit(remainder);
    longIntegerDivideRemainder(y, x, remainder);
    longIntegerAdd(remainder, x, remainder);
    longIntegerDivideRemainder(remainder, x, remainder);

    convertLongIntegerToLongIntegerRegister(remainder, REGISTER_X);

    longIntegerFree(y);
    longIntegerFree(remainder);
  }

  longIntegerFree(x);
}



/********************************************//**
 * \brief Y(long integer) mod X(short integer) ==> X(long integer)
 *
 * \param void
 * \return void
 ***********************************************/
void modLonIShoI(void) {
  longInteger_t x;

  convertShortIntegerRegisterToLongInteger(REGISTER_X, x);

  if(longIntegerIsZero(x)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function modLonIShoI:", "cannot IDIVR a long integer by 0", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  else {
    longInteger_t y, remainder;

    convertLongIntegerRegisterToLongInteger(REGISTER_Y, y);

    longIntegerInit(remainder);
    longIntegerDivideRemainder(y, x, remainder);
    longIntegerAdd(remainder, x, remainder);
    longIntegerDivideRemainder(remainder, x, remainder);

    convertLongIntegerToLongIntegerRegister(remainder, REGISTER_X);

    longIntegerFree(y);
    longIntegerFree(remainder);
  }

  longIntegerFree(x);
}



/********************************************//**
 * \brief Y(short integer) mod X(long integer) ==> X(short integer)
 *
 * \param void
 * \return void
 ***********************************************/
void modShoILonI(void) {
  longInteger_t x;

  convertLongIntegerRegisterToLongInteger(REGISTER_X, x);

  if(longIntegerIsZero(x)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function modShoILonI:", "cannot IDIVR a short integer by 0", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  else {
    longInteger_t y, remainder;
    uint32_t baseY;

    baseY = getRegisterShortIntegerBase(REGISTER_Y);
    convertShortIntegerRegisterToLongInteger(REGISTER_Y, y);

    longIntegerInit(remainder);
    longIntegerDivideRemainder(y, x, remainder);
    longIntegerAdd(remainder, x, remainder);
    longIntegerDivideRemainder(remainder, x, remainder);

    convertLongIntegerToShortIntegerRegister(remainder, baseY, REGISTER_X);

    longIntegerFree(y);
    longIntegerFree(remainder);
  }

  longIntegerFree(x);
}



/********************************************//**
 * \brief Y(long integer) mod X(real34) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void modLonIReal(void) {
  if(real34IsZero(REGISTER_REAL34_DATA(REGISTER_X))) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function modLonIReal:", "cannot IDIVR a long integer by 0", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  real_t x, r;
  real1071_t y;
  realContext_t c = ctxtReal39;

  c.digits = 1071;
  convertLongIntegerRegisterToReal(REGISTER_Y, (real_t *)&y, &c);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);

  WP34S_BigMod((real_t *)&y, &x, &r, &ctxtReal39);
  if(!realIsZero(&r) && realGetSign(&y) != realGetSign(&x)) {
    realAdd(&r, &x, &r, &ctxtReal39);
  }

  convertRealToReal34ResultRegister(&r, REGISTER_X);
  setRegisterAngularMode(REGISTER_X, amNone);
}



/********************************************//**
 * \brief Y(real34) mod X(long integer) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void modRealLonI(void) {
  real1071_t x;
  realContext_t c = ctxtReal39;

  c.digits = 1071;
  convertLongIntegerRegisterToReal(REGISTER_X, (real_t *)&x, &c);
  if(realIsZero(&x)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function modRealLonI:", "cannot IDIVR a real34 by 0", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  real_t y, r;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
  WP34S_BigMod(&y, (real_t *)&x, &r, &ctxtReal39);
  if(!realIsZero(&r) && realGetSign(&y) != realGetSign(&x)) {
    realAdd(&r, (real_t *)&x, &r, &ctxtReal39);
  }

  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  convertRealToReal34ResultRegister(&r, REGISTER_X);
}



/******************************************************************************************************************************************************************************************/
/* short integer mod ...                                                                                                                                                                    */
/******************************************************************************************************************************************************************************************/

/********************************************//**
 * \brief Y(short integer) mod X(short integer) ==> X(short integer)
 *
 * \param void
 * \return void
 ***********************************************/
void modShoIShoI(void) {
  longInteger_t x;

  convertShortIntegerRegisterToLongInteger(REGISTER_X, x);

  if(longIntegerIsZero(x)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function modLonILonI:", "cannot IDIVR a short integer by 0", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  else {
    longInteger_t y, remainder;
    uint32_t baseY;

    baseY = getRegisterShortIntegerBase(REGISTER_Y);
    convertShortIntegerRegisterToLongInteger(REGISTER_Y, y);

    longIntegerInit(remainder);
    longIntegerDivideRemainder(y, x, remainder);
    longIntegerAdd(remainder, x, remainder);
    longIntegerDivideRemainder(remainder, x, remainder);

    convertLongIntegerToShortIntegerRegister(remainder, baseY, REGISTER_X);

    longIntegerFree(y);
    longIntegerFree(remainder);
  }

  longIntegerFree(x);

}



/********************************************//**
 * \brief Y(short integer) mod X(real34) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void modShoIReal(void) {
  if(real34IsZero(REGISTER_REAL34_DATA(REGISTER_X))) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function modShoIReal:", "cannot IDIVR a short integer by 0", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  real_t y, x, r;

  convertShortIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);

  WP34S_Mod(&y, &x, &r, &ctxtReal39);
  if(!realIsZero(&r) && realGetSign(&y) != realGetSign(&x)) {
    realAdd(&r, &x, &r, &ctxtReal39);
  }

  convertRealToReal34ResultRegister(&r, REGISTER_X);
  setRegisterAngularMode(REGISTER_X, amNone);
}



/********************************************//**
 * \brief Y(real34) mod X(short integer) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void modRealShoI(void) {
  real_t x;

  convertShortIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
  if(realIsZero(&x)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function modRealShoI:", "cannot IDIVR a real34 by 0", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  real_t y, r;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);

  WP34S_Mod(&y, &x, &r, &ctxtReal39);
  if(!realIsZero(&r) && realGetSign(&y) != realGetSign(&x)) {
    realAdd(&r, &x, &r, &ctxtReal39);
  }

  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  convertRealToReal34ResultRegister(&r, REGISTER_X);
}



/******************************************************************************************************************************************************************************************/
/* real34 mod ...                                                                                                                                                                           */
/******************************************************************************************************************************************************************************************/

/********************************************//**
 * \brief Y(real34) mod X(real34) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
void modRealReal(void) {
  if(real34IsZero(REGISTER_REAL34_DATA(REGISTER_X))) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function modRealReal:", "cannot IDIVR a real34 by 0", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  real_t x, y, r;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);

  WP34S_BigMod(&y, &x, &r, &ctxtReal39);
  if(!realIsZero(&r) && realGetSign(&y) != realGetSign(&x)) {
    realAdd(&r, &x, &r, &ctxtReal39);
  }

  convertRealToReal34ResultRegister(&r, REGISTER_X);
  setRegisterAngularMode(REGISTER_X, amNone);
}
