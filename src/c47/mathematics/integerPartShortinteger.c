// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file integerPartShortinteger.c
 ***********************************************/

#include "c47.h"

TO_QSPI void (* const sint[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2       3         4        5        6        7          8           9             10
//          Long integer Real34  complex34 Time     Date     String   Real34 mat Complex34 m Short integer Config data
            sintLonI,      sintReal, sintError,  sintError, sintError, sintError, sintError, sintError,    sintShoI,       sintError
};



/********************************************//**
 * \brief Data type error in LINT
 *
 * \param void
 * \return void
 ***********************************************/
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  void sintError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate SINT for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnSint:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and SINT(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnSint(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }
  sint[getRegisterDataType(REGISTER_X)]();
}



void sintLonI(void) {
  convertLongIntegerRegisterToShortIntegerRegister(REGISTER_X, REGISTER_X);
  lastIntegerBase = 10;
}



void sintShoI(void) {
}



void sintReal(void) {
  real_t tmpR, tmpX;
  uInt32ToReal(shortIntegerWordSize,&tmpR);
  realPower(const_2,&tmpR,&tmpR,&ctxtReal39);
  realSubtract(&tmpR,const_1,&tmpR,&ctxtReal39);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X),&tmpX);
  realSubtract(&tmpR,&tmpX,&tmpR,&ctxtReal39);
  if(real34IsPositive(&tmpR)) {
    convertReal34ToLongIntegerRegister(REGISTER_REAL34_DATA(REGISTER_X), REGISTER_X, DEC_ROUND_DOWN);
    convertLongIntegerRegisterToShortIntegerRegister(REGISTER_X, REGISTER_X);
    lastIntegerBase = 10;
  }
  else {

    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "Converting a real would result in a value exceeding %" PRId16 " bits!", (uint16_t)shortIntegerWordSize);
      moreInfoOnError("In function sintReal:", errorMessage, "", "");
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}
