// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file not.c
 ***********************************************/

#include "c47.h"

TO_QSPI void (* const not[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2        3         4         5         6         7          8           9             10
//          Long integer Real34   Complex34 Time      Date      String    Real34 mat Complex34 m Short integer Config data
            notLonI,     notReal, notError, notError, notError, notError, notError,  notError,   notShoI,      notError
};



/********************************************//**
 * \brief Data type error in logical not
 *
 * \param void
 * \return void
 ***********************************************/
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  void notError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate not(%s)", getRegisterDataTypeName(REGISTER_X, false, false));
    moreInfoOnError("In function notError:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and not(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnLogicalNot(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }
  not[getRegisterDataType(REGISTER_X)]();
}



void notLonI(void) {
  longInteger_t res;

  convertLongIntegerRegisterToLongInteger(REGISTER_X, res);

  if(longIntegerIsZero(res)) {
    uInt32ToLongInteger(1u, res);
  }
  else {
    uInt32ToLongInteger(0u, res);
  }

  convertLongIntegerToLongIntegerRegister(res, REGISTER_X);

  longIntegerFree(res);
}



void notShoI(void) {
  *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = ~(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X))) & shortIntegerMask;
}



void notReal(void) {
  longInteger_t res;

  longIntegerInit(res);
  if(real34IsZero(REGISTER_REAL34_DATA(REGISTER_X))) {
    uInt32ToLongInteger(1u, res);
  }

  convertLongIntegerToLongIntegerRegister(res, REGISTER_X);

  longIntegerFree(res);
}
