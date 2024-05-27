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
 * \file setClearFlipBits.c
 ***********************************************/

#include "logicalOps/setClearFlipBits.h"

#include "debug.h"
#include "error.h"
#include "registers.h"

#include "c47.h"



/********************************************//**
 * \brief regX ==> regL and CB(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnCb(uint16_t bit) { // bit from 0=LSB to shortIntegerWordSize-1=MSB
  if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
    if(!saveLastX()) {
      return;
    }

    *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) &= ~((uint64_t)1 << bit);
  }
  else {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "cannot CB %s", getRegisterDataTypeName(REGISTER_X, true, false));
      moreInfoOnError("In function fnCb:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}



/********************************************//**
 * \brief regX ==> regL and SB(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnSb(uint16_t bit) { // bit from 0=LSB to shortIntegerWordSize-1=MSB
  if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
    if(!saveLastX()) {
      return;
    }

    *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) |= (uint64_t)1 << bit;
  }
  else {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "cannot SB %s", getRegisterDataTypeName(REGISTER_X, true, false));
      moreInfoOnError("In function fnSb:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}



/********************************************//**
 * \brief regX ==> regL and FB(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnFb(uint16_t bit) { // bit from 0=LSB to shortIntegerWordSize-1=MSB
  if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
    if(!saveLastX()) {
      return;
    }

    *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) ^= (uint64_t)1 << bit;
  }
  else {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "cannot FB %s", getRegisterDataTypeName(REGISTER_X, true, false));
      moreInfoOnError("In function fnFb:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}



/********************************************//**
 * \brief bit clear in register X
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnBc(uint16_t bit) { // bit from 0=LSB to shortIntegerWordSize-1=MSB
  if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
    thereIsSomethingToUndo = false;
    SET_TI_TRUE_FALSE((*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) & ((uint64_t)1 << bit)) == 0);
  }
  else {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "cannot BC %s", getRegisterDataTypeName(REGISTER_X, true, false));
      moreInfoOnError("In function fnBc:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}



/********************************************//**
 * \brief bit set in register X
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnBs(uint16_t bit) { // bit from 0=LSB to shortIntegerWordSize-1=MSB
  if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
    thereIsSomethingToUndo = false;
    SET_TI_TRUE_FALSE((*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) & ((uint64_t)1 << bit)) != 0);
  }
  else {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "cannot BS %s", getRegisterDataTypeName(REGISTER_X, true, false));
      moreInfoOnError("In function fnBs:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}
