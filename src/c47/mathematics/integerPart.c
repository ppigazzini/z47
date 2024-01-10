/* This file is part of 43S.
 *
 * 43S is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * 43S is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with 43S.  If not, see <http://www.gnu.org/licenses/>.
 */

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
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
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
