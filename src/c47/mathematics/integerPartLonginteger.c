// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file integerPartLonginteger.c
 ***********************************************/

#include "c47.h"

TO_QSPI void (* const lint[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2       3         4        5        6        7          8           9             10
//          Long integer Real34  complex34 Time     Date     String   Real34 mat Complex34 m Short integer Config data
            lintLonI,      lintReal, lintError,  lintError, lintError, lintError, lintError, lintError,    lintShoI,       lintError
};



/********************************************//**
 * \brief Data type error in LINT
 *
 * \param void
 * \return void
 ***********************************************/
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  void lintError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate LINT for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnLint:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and LINT(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnLint(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }
  lint[getRegisterDataType(REGISTER_X)]();
}



void lintLonI(void) {
}



void lintShoI(void) {
  convertShortIntegerRegisterToLongIntegerRegister(REGISTER_X, REGISTER_X);
  setLastintegerBasetoZero();
}



void lintReal(void) {
  int32_t exponent = real34GetExponent(REGISTER_REAL34_DATA(REGISTER_X));
  if(exponent <= (int32_t)(0.301029995663 * MAX_LONG_INTEGER_SIZE_IN_BITS)) {
    convertReal34ToLongIntegerRegister(REGISTER_REAL34_DATA(REGISTER_X), REGISTER_X, DEC_ROUND_DOWN);
  }
  else {

    displayCalcErrorMessage(!real34CompareLessThan(REGISTER_REAL34_DATA(REGISTER_X), const34_0) ? ERROR_OVERFLOW_PLUS_INF : ERROR_OVERFLOW_MINUS_INF, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "Converting a real exponent of %" PRId32 " would result in a value exceeding %" PRId16 " bits!", exponent, (uint16_t)MAX_LONG_INTEGER_SIZE_IN_BITS);
      moreInfoOnError("In function longIntegerAdd:", errorMessage, "", "");
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}
