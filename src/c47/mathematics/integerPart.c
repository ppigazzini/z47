// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file integerPart.c
 ***********************************************/

#include "mathematics/integerPart.h"

#include "debug.h"
#include "error.h"
#include "items.h"
#include "mathematics/matrix.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"

static void ipNoOp(void);

TO_QSPI void (* const ip[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2       3         4        5        6        7          8           9             10
//          Long integer Real34  complex34 Time     Date     String   Real34 mat Complex34 m Short integer Config data
            ipNoOp,      ipReal, ipError,  ipError, ipError, ipError, ipRema,    ipError,    ipNoOp,       ipError
};



/********************************************//**
 * \brief Data type error in IP
 *
 * \param void
 * \return void
 ***********************************************/
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  void ipError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate IP for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnIp:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and IP(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnIp(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }
  ip[getRegisterDataType(REGISTER_X)]();
}



static void ipNoOp(void) {
}



void ipRema(void) {
  elementwiseRema(ipReal);
}



void ipReal(void) {
  real34ToIntegralValue(REGISTER_REAL34_DATA(REGISTER_X), REGISTER_REAL34_DATA(REGISTER_X), DEC_ROUND_DOWN);
  setRegisterAngularMode(REGISTER_X, amNone);
}
