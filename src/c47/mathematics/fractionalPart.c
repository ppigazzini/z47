// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file fractionalPart.c
 ***********************************************/

#include "c47.h"

TO_QSPI void (* const fp[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2       3         4        5        6        7          8           9             10
//          Long integer Real34  Complex34 Time     Date     String   Real34 mat Complex34 m Short integer Config data
            fpLonI,      fpReal, fpError,  fpError, fpError, fpError, fpRema,    fpError,    fpShoI,       fpError
};



/********************************************//**
 * \brief Data type error in FP
 *
 * \param void
 * \return void
 ***********************************************/
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  void fpError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate FP for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnFp:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and FP(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnFp(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }
  fp[getRegisterDataType(REGISTER_X)]();
}



void fpLonI(void) {
  longInteger_t x;

  longIntegerInit(x); // Set to 0
  convertLongIntegerToLongIntegerRegister(x, REGISTER_X);
  longIntegerFree(x);
}



void fpRema(void) {
  elementwiseRema(fpReal);
}



void fpShoI(void) {
  uint64_t x, y = 0;

  if(shortIntegerMode == SIM_1COMPL || shortIntegerMode == SIM_SIGNMT) {
    /* These two modes support negative 0, so the fractional part of a negative
     * number becomes -0 rather than +0.
     */
    x = *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X));
    if((x & shortIntegerSignBit) != 0)
      y = shortIntegerMode == SIM_1COMPL ? shortIntegerMask : shortIntegerSignBit;
  }
  *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = y;
}



void fpReal(void) {
  real34_t x;

  real34ToIntegralValue(REGISTER_REAL34_DATA(REGISTER_X), &x, DEC_ROUND_DOWN);
  real34Subtract(REGISTER_REAL34_DATA(REGISTER_X), &x ,REGISTER_REAL34_DATA(REGISTER_X));
}
