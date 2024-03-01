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
 * \file clcvar.c
 ***********************************************/

#include "programming/clcvar.h"

#include "charString.h"
#include "constantPointers.h"
#include "defines.h"
#include "dateTime.h"
#include "error.h"
#include "fonts.h"
#include "items.h"
#include "longIntegerType.h"
#include "mathematics/matrix.h"
#include "programming/nextStep.h"
#include "realType.h"
#include "registers.h"
#include "registerValueConversions.h"
#include <stdio.h>

#include "c47.h"



#if !defined(TESTSUITE_BUILD)
  static void _clearVar(calcRegister_t regist) {
    switch(getRegisterDataType(regist)) {
      case dtLongInteger: {
        longInteger_t l;
        longIntegerInit(l);
        convertLongIntegerToLongIntegerRegister(l, regist);
        longIntegerFree(l);
        break;
      }

      case dtReal34:
      case dtTime: {
        real34Zero(REGISTER_REAL34_DATA(regist));
        break;
      }

      case dtComplex34: {
        real34Zero(REGISTER_REAL34_DATA(regist));
        real34Zero(REGISTER_IMAG34_DATA(regist));
        break;
      }

      case dtDate: {
        composeJulianDay(const34_0, const34_1, const34_1, REGISTER_REAL34_DATA(regist));
        julianDayToInternalDate(REGISTER_REAL34_DATA(regist), REGISTER_REAL34_DATA(regist));
        break;
      }

      case dtString: {
        reallocateRegister(regist, dtString, 1, amNone);
        break;
      }

      case dtReal34Matrix: {
        real34Matrix_t m;
        linkToRealMatrixRegister(regist, &m);
        for(uint32_t i = 0; i < m.header.matrixRows * m.header.matrixColumns; i++) {
          real34Zero(VARIABLE_REAL34_DATA(&m.matrixElements[i]));
        }
        break;
      }

      case dtComplex34Matrix: {
        complex34Matrix_t m;
        linkToComplexMatrixRegister(regist, &m);
        for(uint32_t i = 0; i < m.header.matrixRows * m.header.matrixColumns; i++) {
          real34Zero(VARIABLE_REAL34_DATA(&m.matrixElements[i]));
          real34Zero(VARIABLE_IMAG34_DATA(&m.matrixElements[i]));
        }
        break;
      }

      case dtShortInteger: {
        convertUInt64ToShortIntegerRegister(false, 0, getRegisterTag(regist), regist);
        break;
      }

      case dtConfig: {
        break;
      }

      default: {
        printf("In function _clearVar, the data type %" PRIu32 " is unknown! Please try to reproduce and submit a bug.\n", getRegisterDataType(regist));
      }
    }
  }

  static void _getStringLabelOrVariableName(uint8_t *stringAddress) {
    uint8_t stringLength = *(uint8_t *)(stringAddress++);
    xcopy(tmpStringLabelOrVariableName, stringAddress, stringLength);
    tmpStringLabelOrVariableName[stringLength] = 0;
  }

  static void _indirectRegister(uint8_t *paramAddress) {
    uint8_t opParam = *(uint8_t *)paramAddress;
    if(opParam <= LAST_LOCAL_REGISTER) { // Local register from .00 to .98
      _clearVar(opParam);
    }
    else {
      sprintf(tmpString, "\nIn function _executeWithIndirectRegister: " STD_RIGHT_ARROW " %u is not a valid parameter!", opParam);
    }
  }

  static void _indirectVariable(uint8_t *stringAddress) {
    calcRegister_t regist;
    _getStringLabelOrVariableName(stringAddress);
    regist = findOrAllocateNamedVariable(tmpStringLabelOrVariableName);
    _clearVar(regist);
  }

  static void _processOp(uint8_t *paramAddress, uint16_t op, uint16_t paramMode) {
    uint8_t opParam = *(uint8_t *)(paramAddress++);

    switch(paramMode) {
      case PARAM_DECLARE_LABEL: {
        // nothing to do
        break;
      }

      case PARAM_LABEL: {
        if(opParam <= 104) { // Local label from 00 to 99 or from A to E
          // nothing to do
        }
        else if(opParam == STRING_LABEL_VARIABLE) {
          // nothing to do
        }
        else if(opParam == INDIRECT_REGISTER) {
          _indirectRegister(paramAddress);
        }
        else if(opParam == INDIRECT_VARIABLE) {
          _indirectVariable(paramAddress);
        }
        else {
          sprintf(tmpString, "\nIn function _processOp: case PARAM_LABEL, %s  %u is not a valid parameter!", indexOfItems[op].itemCatalogName, opParam);
        }
        break;
      }

      case PARAM_FLAG: {
        if(opParam <= LAST_LOCAL_FLAG) { // Global flag from 00 to 99, Lettered flag from X to K, or Local flag from .00 to .15 (or .31)
          // nothing to do
        }
        else if(FIRST_LOCAL_FLAG + NUMBER_OF_LOCAL_FLAGS <= opParam && opParam < FIRST_LOCAL_FLAG + NUMBER_OF_LOCAL_FLAGS + NUMBER_OF_SYSTEM_FLAGS) { // Local register from .00 to .15 (or .31)
          // nothing to do
        }
        else if(opParam == SYSTEM_FLAG_NUMBER) {
          // nothing to do
        }
        else if(opParam == INDIRECT_REGISTER) {
          _indirectRegister(paramAddress);
        }
        else if(opParam == INDIRECT_VARIABLE) {
          _indirectVariable(paramAddress);
        }
        else {
          sprintf(tmpString, "\nIn function _processOp: case PARAM_FLAG, %s  %u is not a valid parameter!", indexOfItems[op].itemCatalogName, opParam);
        }
        break;
      }

      case PARAM_NUMBER_8: {
        if(opParam <= (indexOfItems[op].tamMinMax & TAM_MAX_MASK)) { // Value from 0 to 99
          // nothing to do
        }
        else if(opParam == INDIRECT_REGISTER) {
          _indirectRegister(paramAddress);
        }
        else if(opParam == INDIRECT_VARIABLE) {
          _indirectVariable(paramAddress);
        }
        else {
          sprintf(tmpString, "\nIn function _processOp: case PARAM_NUMBER, %s  %u is not a valid parameter!", indexOfItems[op].itemCatalogName, opParam);
        }
        break;
      }

      case PARAM_NUMBER_8_16: {
        if(opParam <= 249) { // Value from 0 to 249
          // nothing to do
        }
        else if(opParam == CNST_BEYOND_250) { // Value from 250 to 499
          // nothing to do
        }
        else if(opParam == INDIRECT_REGISTER) {
          _indirectRegister(paramAddress);
        }
        else if(opParam == INDIRECT_VARIABLE) {
          _indirectVariable(paramAddress);
        }
        else {
          sprintf(tmpString, "\nIn function _processOp: case PARAM_NUMBER, %s  %u is not a valid parameter!", indexOfItems[op].itemCatalogName, opParam);
        }
        break;
      }

      case PARAM_NUMBER_16:
      case PARAM_SKIP_BACK:
      case PARAM_SHUFFLE: {
        // nothing to do
        break;
      }

      case PARAM_REGISTER:
      case PARAM_COMPARE: {
        if(opParam <= LAST_LOCAL_REGISTER) { // Global register from 00 to 99, Lettered register from X to K, or Local register from .00 to .98
          _clearVar(opParam);
        }
        else if(opParam == STRING_LABEL_VARIABLE) {
          _getStringLabelOrVariableName(paramAddress);
          _clearVar(findOrAllocateNamedVariable(tmpStringLabelOrVariableName));
        }
        else if(paramMode == PARAM_COMPARE && (opParam == VALUE_0 || opParam == VALUE_1)) {
        // nothing to do
        }
        else if(opParam == INDIRECT_REGISTER) {
          _indirectRegister(paramAddress);
        }
        else if(opParam == INDIRECT_VARIABLE) {
          _indirectVariable(paramAddress);
        }
        else {
          sprintf(tmpString, "\nIn function _processOp: case PARAM_REGISTER / PARAM_COMPARE, %s  %u is not a valid parameter!", indexOfItems[op].itemCatalogName, opParam);
        }
        break;
      }

      default: {
        sprintf(tmpString, "\nIn function _processOp: paramMode %u is not valid!\n", paramMode);
      }
    }
  }



  static bool_t _processOneStep(uint8_t *step) {
    uint16_t op;

    op = *(step++);
    if(op & 0x80) {
      op &= 0x7f;
      op <<= 8;
      op |= *(step++);
    }

    if(op == ITM_END || op == 0x7fff) {
      return false;
    }
    else {
      switch(indexOfItems[op].status & PTP_STATUS) {
        case PTP_NONE:
        case PTP_DECLARE_LABEL:
        case PTP_LITERAL:
        case PTP_REM: {
          return true;
        }

        case PTP_DISABLED: {
          displayCalcErrorMessage(ERROR_NON_PROGRAMMABLE_COMMAND, ERR_REGISTER_LINE, REGISTER_X);
          #if(EXTRA_INFO_ON_CALC_ERROR == 1)
            moreInfoOnError("In function decodeOneStep:", "non-programmable function", indexOfItems[op].itemCatalogName, "appeared in the program!");
          #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
          return false;
        }

        case PTP_KEYG_KEYX: {
          uint8_t *secondParam = findKey2ndParam(step - 2);
          _processOp(step, op, PARAM_NUMBER_8);
          _processOp(secondParam, *secondParam, PARAM_LABEL);
          return true;
        }

        default: {
          _processOp(step, op, (indexOfItems[op].status & PTP_STATUS) >> 9);
          return true;
        }
      }
    }
  }
#endif // !TESTSUITE_BUILD



void fnClCVar(uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
    uint8_t *ptr = beginOfCurrentProgram;

    while(_processOneStep(ptr)) {
      ptr = findNextStep(ptr);
    }
  #endif // !TESTSUITE_BUILD
}
