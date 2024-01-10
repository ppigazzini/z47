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
 * \file incDec.c
 ***********************************************/

#include "mathematics/incDec.h"

#include "constantPointers.h"
#include "error.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "c43Extensions/xeqm.h"

#include "c47.h"



TO_QSPI void (* const incDec[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(uint16_t, uint8_t) = {
// reg ==>   1            2           3           4            5            6            7            8            9              10
//           Long integer Real34      Complex34   Time         Date         String       Real34 mat   Complex34 m  Short integer  Config data
             incDecLonI,  incDecReal, incDecCplx, incDecError, incDecError, incDecError, incDecError, incDecError, incDecShoI,    incDecError
};



void incDecError(uint16_t regist, uint8_t flag) {
  displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, regist);

  #if(EXTRA_INFO_ON_CALC_ERROR == 1)
    sprintf(errorMessage, "Cannot increment/decrement, incompatible type.");
    moreInfoOnError("In function inc/dec:", errorMessage, NULL, NULL);
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
}



/********************************************//**
 * \brief Decrement a register
 *
 * \param[in] registerNumber uint16_t
 * \return void
 ***********************************************/
void fnDec(uint16_t regist) {
  if(regist < FIRST_LOCAL_REGISTER + currentNumberOfLocalRegisters) {
    incDec[getRegisterDataType(regist)](regist, DEC_FLAG);
  }

  #if defined(PC_BUILD)
    else {
      sprintf(errorMessage, "local register .%02d", regist - FIRST_LOCAL_REGISTER);
      moreInfoOnError("In function fnDec:", errorMessage, "is not defined!", NULL);
    }
  #endif // PC_BUILD
}



/********************************************//**
 * \brief Increment a register
 *
 * \param[in] registerNumber uint16_t
 * \return void
 ***********************************************/
void fnInc(uint16_t regist) {
  if(regist < FIRST_LOCAL_REGISTER + currentNumberOfLocalRegisters) {
    incDec[getRegisterDataType(regist)](regist, INC_FLAG);
  }

  #if defined(PC_BUILD)
    else {
      sprintf(errorMessage, "local register .%02d", regist - FIRST_LOCAL_REGISTER);
      moreInfoOnError("In function fnInc:", errorMessage, "is not defined!", NULL);
    }
  #endif // PC_BUILD
}



void incDecLonI(uint16_t regist, uint8_t flag) {
  longInteger_t r;

  convertLongIntegerRegisterToLongInteger(regist, r);

  (flag == INC_FLAG) ? longIntegerAddUInt(r, 1, r) : longIntegerSubtractUInt(r, 1, r);

  if(running_program_jm) temporaryInformation = longIntegerIsZero(r) ? TI_TRUE : TI_FALSE;    //JM Temporary hack to do DSZ

  convertLongIntegerToLongIntegerRegister(r, regist);

  longIntegerFree(r);
}



void incDecReal(uint16_t regist, uint8_t flag) {
  real_t r;

  real34ToReal(REGISTER_REAL34_DATA(regist), &r);
  (flag == INC_FLAG) ? realAdd(&r, const_1, &r, &ctxtReal39) : realSubtract(&r, const_1, &r, &ctxtReal39);

  if(running_program_jm) temporaryInformation = real34IsZero(&r) ? TI_TRUE : TI_FALSE;    //JM Temporary hack to do DSZ

  realToReal34(&r, REGISTER_REAL34_DATA(regist));
}



void incDecCplx(uint16_t regist, uint8_t flag) {
  real_t r_real;

  real34ToReal(REGISTER_REAL34_DATA(regist), &r_real);

  (flag == INC_FLAG) ? realAdd(&r_real, const_1, &r_real, &ctxtReal39) : realSubtract(&r_real, const_1, &r_real, &ctxtReal39);

  if(running_program_jm)  temporaryInformation = real34IsZero(&r_real) && real34IsZero(REGISTER_REAL34_DATA(regist)) ? TI_TRUE : TI_FALSE;    //JM Temporary hack to do DSZ

  realToReal34(&r_real, REGISTER_REAL34_DATA(regist));
}



void incDecShoI(uint16_t regist, uint8_t flag) {
  int16_t r_sign;
  uint64_t r_value;

  convertShortIntegerRegisterToUInt64(regist, &r_sign, &r_value);

  if(r_sign) { // regiter regist negative
    (flag != INC_FLAG) ? r_value++ : r_value--;
  }
  else { // register regist positive
    (flag == INC_FLAG) ? r_value++ : r_value--;
  }

  if(running_program_jm) temporaryInformation = (r_value == 0) ? TI_TRUE : TI_FALSE;  //JM Temporary hack to do dsz

  convertUInt64ToShortIntegerRegister(r_sign, r_value, getRegisterTag(regist), regist);
}
