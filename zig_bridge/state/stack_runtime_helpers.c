// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

void z47_registers_sort_reg(uint16_t range_start, uint16_t range_end);

uint16_t z47_stack_runtime_get_stack_top(void) {
  return getStackTop();
}

uint16_t z47_stack_runtime_real34_size_in_blocks(void) {
  return REAL34_SIZE_IN_BLOCKS;
}

void z47_stack_runtime_real34_set_zero(void *dest) {
  real34SetZero((real34_t *)dest);
}

bool_t z47_stack_runtime_try_fn_to_real_complex_zero(void) {
  real_t real_part;

  if(getRegisterDataType(REGISTER_X) != dtComplex34) {
    return false;
  }

  if(!real34IsZero(REGISTER_IMAG34_DATA(REGISTER_X))) {
    return false;
  }

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &real_part);
  convertRealToResultRegister(&real_part, REGISTER_X, amNone);
  return true;
}

bool_t z47_stack_runtime_try_fn_to_real_real34(void) {
  if(getRegisterDataType(REGISTER_X) != dtReal34) {
    return false;
  }

  copySourceRegisterToDestRegister(REGISTER_X, REGISTER_L);
  if(getRegisterAngularMode(REGISTER_X) != amNone) {
    if(getRegisterAngularMode(REGISTER_X) == amDMS) {
      temporaryInformation = TI_FROM_DMS;
    }
    setRegisterAngularMode(REGISTER_X, amNone);
  }

  return true;
}

bool_t z47_stack_runtime_try_fn_to_real_long_integer(void) {
  if(getRegisterDataType(REGISTER_X) != dtLongInteger) {
    return false;
  }

  copySourceRegisterToDestRegister(REGISTER_X, REGISTER_L);
  convertLongIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
  return true;
}

bool_t z47_stack_runtime_try_fn_to_real_short_integer(void) {
  if(getRegisterDataType(REGISTER_X) != dtShortInteger) {
    return false;
  }

  copySourceRegisterToDestRegister(REGISTER_X, REGISTER_L);
  convertShortIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
  setLastintegerBasetoZero();
  return true;
}

bool_t z47_stack_runtime_try_fn_to_real_time(void) {
  if(getRegisterDataType(REGISTER_X) != dtTime) {
    return false;
  }

  temporaryInformation = TI_FROM_HMS;
  copySourceRegisterToDestRegister(REGISTER_X, REGISTER_L);
  convertTimeRegisterToReal34Register(REGISTER_X, REGISTER_X);
  return true;
}

bool_t z47_stack_runtime_try_fn_to_real_date(void) {
  if(getRegisterDataType(REGISTER_X) != dtDate) {
    return false;
  }

  temporaryInformation = TI_FROM_DATEX;
  copySourceRegisterToDestRegister(REGISTER_X, REGISTER_L);
  convertDateRegisterToReal34Register(REGISTER_X, REGISTER_X);
  return true;
}

static void z47_adjust_result_adjust_real_register(calcRegister_t reg, real34_t *val) {
  if(real34IsInfinite(val)) {
    displayCalcErrorMessage(real34IsPositive(val) ? ERROR_OVERFLOW_PLUS_INF : ERROR_OVERFLOW_MINUS_INF, ERR_REGISTER_LINE, reg);
  }
  else if(real34IsZero(val)) {
    real34SetPositiveSign(val);
  }
}

bool_t z47_stack_runtime_adjust_result_scalar_core(calcRegister_t res) {
  uint32_t resultDataType = getRegisterDataType(res);
  real_t tmp;

  if(resultDataType != dtReal34 && resultDataType != dtTime && resultDataType != dtDate && resultDataType != dtComplex34) {
    return false;
  }

  if(getSystemFlag(FLAG_SPCRES) == false && lastErrorCode == 0) {
    switch(resultDataType) {
      case dtReal34:
      case dtTime:
      case dtDate:
        z47_adjust_result_adjust_real_register(res, REGISTER_REAL34_DATA(res));
        break;

      case dtComplex34:
        z47_adjust_result_adjust_real_register(res, REGISTER_REAL34_DATA(res));
        z47_adjust_result_adjust_real_register(res, REGISTER_IMAG34_DATA(res));
        break;
    }
  }

  if(lastErrorCode == 0) {
    if(resultDataType == dtTime) {
      checkTimeRange(REGISTER_REAL34_DATA(res));
    }
    if(resultDataType == dtDate) {
      checkDateRange(REGISTER_REAL34_DATA(res));
    }
  }

  if(lastErrorCode != 0) {
    undo();
    return true;
  }

  switch(resultDataType) {
    case dtReal34:
      if(significantDigits != 0 && significantDigits < 34) {
        real34ToReal(REGISTER_REAL34_DATA(res), &tmp);
        convertRealToReal34ResultRegister(&tmp, res);
      }
      break;

    case dtComplex34:
      if(significantDigits != 0 && significantDigits < 34) {
        real34ToReal(REGISTER_REAL34_DATA(res), &tmp);
        convertRealToReal34ResultRegister(&tmp, res);
        real34ToReal(REGISTER_IMAG34_DATA(res), &tmp);
        convertRealToImag34ResultRegister(&tmp, res);
      }
      break;

    default:
      break;
  }

  return true;
}

bool_t z47_stack_runtime_adjust_result_real_matrix_core(calcRegister_t res) {
  real34Matrix_t matrix;

  if(getRegisterDataType(res) != dtReal34Matrix) {
    return false;
  }

  if(getSystemFlag(FLAG_SPCRES) == false && lastErrorCode == 0) {
    linkToRealMatrixRegister(res, &matrix);
    for(uint32_t i = 0; i < matrix.header.matrixRows * matrix.header.matrixColumns; ++i) {
      z47_adjust_result_adjust_real_register(res, VARIABLE_REAL34_DATA(&matrix.matrixElements[i]));
    }
  }

  if(lastErrorCode != 0) {
    undo();
    return true;
  }

  if(significantDigits != 0 && significantDigits < 34) {
    rsdRema(significantDigits);
  }

  return true;
}

bool_t z47_stack_runtime_adjust_result_complex_matrix_core(calcRegister_t res) {
  complex34Matrix_t matrix;

  if(getRegisterDataType(res) != dtComplex34Matrix) {
    return false;
  }

  if(getSystemFlag(FLAG_SPCRES) == false && lastErrorCode == 0) {
    linkToComplexMatrixRegister(res, &matrix);
    for(uint32_t i = 0; i < matrix.header.matrixRows * matrix.header.matrixColumns; ++i) {
      z47_adjust_result_adjust_real_register(res, VARIABLE_REAL34_DATA(&matrix.matrixElements[i]));
      z47_adjust_result_adjust_real_register(res, VARIABLE_IMAG34_DATA(&matrix.matrixElements[i]));
    }
  }

  if(lastErrorCode != 0) {
    undo();
    return true;
  }

  if(significantDigits != 0 && significantDigits < 34) {
    rsdCxma(significantDigits);
  }

  return true;
}

void z47_stack_runtime_adjust_result_set_cpxres(void) {
  fnSetFlag(FLAG_CPXRES);
  fnRefreshState();
}

uint32_t z47_stack_runtime_get_global_register_descriptor(calcRegister_t reg) {
  return globalRegister[reg].descriptor;
}

void z47_stack_runtime_set_global_register_descriptor(calcRegister_t reg, uint32_t descriptor) {
  globalRegister[reg].descriptor = descriptor;
}

bool_t z47_stack_runtime_get_swap_target_descriptor(uint16_t reg, uint32_t *descriptor) {
  if(reg <= LAST_GLOBAL_REGISTER) {
    *descriptor = globalRegister[reg].descriptor;
    return true;
  }

  if(reg < FIRST_NAMED_VARIABLE + numberOfNamedVariables) {
    *descriptor = allNamedVariables[reg - FIRST_NAMED_VARIABLE].header.descriptor;
    return true;
  }

  if(reg < FIRST_LOCAL_REGISTER + currentNumberOfLocalRegisters) {
    *descriptor = currentLocalRegisters[reg - FIRST_LOCAL_REGISTER].descriptor;
    return true;
  }

  return false;
}

bool_t z47_stack_runtime_set_swap_target_descriptor(uint16_t reg, uint32_t descriptor) {
  if(reg <= LAST_GLOBAL_REGISTER) {
    globalRegister[reg].descriptor = descriptor;
    return true;
  }

  if(reg < FIRST_NAMED_VARIABLE + numberOfNamedVariables) {
    allNamedVariables[reg - FIRST_NAMED_VARIABLE].header.descriptor = descriptor;
    return true;
  }

  if(reg < FIRST_LOCAL_REGISTER + currentNumberOfLocalRegisters) {
    currentLocalRegisters[reg - FIRST_LOCAL_REGISTER].descriptor = descriptor;
    return true;
  }

  return false;
}

void z47_stack_runtime_report_invalid_swap_target(uint16_t reg) {
  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    if(reg <= LAST_LOCAL_REGISTER) {
      displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
      sprintf(errorMessage, "local register .%02d", reg - FIRST_LOCAL_REGISTER);
      moreInfoOnError("In function _swapRegs:", errorMessage, "is not defined!", NULL);
    }
    else {
      displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
      sprintf(errorMessage, "register %d", reg);
      moreInfoOnError("In function _swapRegs:", errorMessage, "is unsupported!", NULL);
    }
  #else
    (void)reg;
  #endif
}

uint16_t z47_stack_runtime_statistical_sums_blocks(void) {
  return NUMBER_OF_STATISTICAL_SUMS * REAL_SIZE_IN_BLOCKS(75);
}

uint32_t z47_stack_runtime_statistical_sums_bytes(void) {
  return NUMBER_OF_STATISTICAL_SUMS * REAL_SIZE_IN_BYTES(75);
}

void z47_stack_runtime_store_stack_size_in_x(uint32_t size) {
  longInteger_t stack;

  longIntegerInit(stack);
  uInt32ToLongInteger(size, stack);
  convertLongIntegerToLongIntegerRegister(stack, REGISTER_X);
  longIntegerFree(stack);
}

void z47_stack_runtime_store_local_register_count_in_x(void) {
  longInteger_t loc_r;

  longIntegerInit(loc_r);
  uInt32ToLongInteger(currentNumberOfLocalRegisters, loc_r);
  convertLongIntegerToLongIntegerRegister(loc_r, REGISTER_X);
  longIntegerFree(loc_r);
}

uint8_t z47_stack_runtime_current_local_register_count(void) {
  return currentNumberOfLocalRegisters;
}

uint8_t z47_stack_runtime_get_input_default(void) {
  return Input_Default;
}

void z47_stack_runtime_store_zero_long_integer(calcRegister_t reg) {
  longInteger_t lg_int;

  longIntegerInit(lg_int);
  uInt32ToLongInteger(0u, lg_int);
  convertLongIntegerToLongIntegerRegister(lg_int, reg);
  longIntegerFree(lg_int);
}

void z47_stack_runtime_store_zero_short_integer(calcRegister_t reg, uint32_t base) {
  longInteger_t lg_int;

  longIntegerInit(lg_int);
  uInt32ToLongInteger(0u, lg_int);
  convertLongIntegerToShortIntegerRegister(lg_int, base, reg);
  longIntegerFree(lg_int);
}

void z47_stack_runtime_request_clear_registers_confirmation(void) {
  setConfirmationMode(fnClearRegisters);
}

void z47_stack_runtime_do_partial_register_load(uint16_t s, uint16_t n, uint16_t d) {
  doLoad(LM_REGISTERS_PARTIAL, s, n, d, manualLoad);
}

void z47_stack_runtime_sort_register_range(uint16_t range_start, uint16_t range_end) {
  z47_registers_sort_reg(range_start, range_end);
}

void z47_stack_runtime_report_register_command_error(uint8_t error_code) {
  displayCalcErrorMessage(error_code, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}

void z47_stack_runtime_restore_saved_sigma_last_xy_and_add(void) {
  convertRealToResultRegister(&SAVED_SIGMA_LASTX, REGISTER_X, amNone);
  convertRealToResultRegister(&SAVED_SIGMA_LASTY, REGISTER_Y, amNone);
  fnSigmaAddRem(SIGMA_PLUS);
}

void z47_stack_runtime_save_for_undo(void) {
  if(((calcMode == CM_NIM || calcMode == CM_AIM || calcMode == CM_MIM) && thereIsSomethingToUndo) || calcMode == CM_NO_UNDO) {
    return;
  }

  clearRegister(TEMP_REGISTER_2_SAVED_STATS);
  SAVED_SIGMA_lastAddRem = SIGMA_NONE;

  savedSystemFlags0 = systemFlags0;
  savedSystemFlags1 = systemFlags1;

  if(currentInputVariable != INVALID_VARIABLE) {
    if(currentInputVariable & 0x8000) {
      currentInputVariable |= 0x4000;
    }
    else {
      currentInputVariable &= 0xbfff;
    }
  }

  if(entryStatus & 0x01) {
    entryStatus |= 0x02;
  }
  else {
    entryStatus &= 0xfd;
  }

  for(calcRegister_t regist=getStackTop(); regist>=REGISTER_X; regist--) {
    copySourceRegisterToDestRegister(regist, SAVED_REGISTER_X - REGISTER_X + regist);
    if(lastErrorCode == ERROR_RAM_FULL) {
      goto failed;
    }
  }

  copySourceRegisterToDestRegister(REGISTER_L, SAVED_REGISTER_L);
  if(lastErrorCode == ERROR_RAM_FULL) {
    goto failed;
  }

  lrSelectionUndo = lrSelection;
  if(statisticalSumsPointer == NULL) {
    freeC47Blocks(savedStatisticalSumsPointer, NUMBER_OF_STATISTICAL_SUMS * REAL_SIZE_IN_BLOCKS(75));
    savedStatisticalSumsPointer = NULL;
  }
  else {
    lrChosenUndo = lrChosen;
    if(savedStatisticalSumsPointer == NULL) {
      savedStatisticalSumsPointer = allocC47Blocks(NUMBER_OF_STATISTICAL_SUMS * REAL_SIZE_IN_BLOCKS(75));
    }
    xcopy(savedStatisticalSumsPointer, statisticalSumsPointer, NUMBER_OF_STATISTICAL_SUMS * REAL_SIZE_IN_BYTES(75));
  }

  thereIsSomethingToUndo = true;
  return;

failed:
  for(calcRegister_t regist=getStackTop(); regist>=REGISTER_X; regist--) {
    clearRegister(SAVED_REGISTER_X - REGISTER_X + regist);
  }
  clearRegister(SAVED_REGISTER_L);
  thereIsSomethingToUndo = false;
  lastErrorCode = ERROR_RAM_FULL;
}

void z47_stack_runtime_undo(void) {
  const bool_t wasSolving = getSystemFlag(FLAG_SOLVING);
  const bool_t wasInting = getSystemFlag(FLAG_INTING);

  const uint8_t lastErrorCodeMeM = lastErrorCode;
  lastErrorCode = ERROR_NONE;
  recallStatsMatrix();
  if(lastErrorCode == ERROR_NONE) {
    lastErrorCode = lastErrorCodeMeM;
  }

  if(currentInputVariable != INVALID_VARIABLE) {
    if(currentInputVariable & 0x4000) {
      currentInputVariable |= 0x8000;
    }
    else {
      currentInputVariable &= 0x7fff;
    }
  }

  if(entryStatus & 0x02) {
    entryStatus |= 0x01;
  }
  else {
    entryStatus &= 0xfe;
  }

  if(SAVED_SIGMA_lastAddRem == SIGMA_PLUS && statisticalSumsPointer != NULL) {
    fnSigmaAddRem(SIGMA_MINUS);
  }
  else if(SAVED_SIGMA_lastAddRem == SIGMA_MINUS && statisticalSumsPointer != NULL) {
    convertRealToResultRegister(&SAVED_SIGMA_LASTX, REGISTER_X, amNone);
    convertRealToResultRegister(&SAVED_SIGMA_LASTY, REGISTER_Y, amNone);
    fnSigmaAddRem(SIGMA_PLUS);
  }

  systemFlags0 = savedSystemFlags0;
  systemFlags1 = savedSystemFlags1;

  for(calcRegister_t regist=getStackTop(); regist>=REGISTER_X; regist--) {
    copySourceRegisterToDestRegister(SAVED_REGISTER_X - REGISTER_X + regist, regist);
  }

  copySourceRegisterToDestRegister(SAVED_REGISTER_L, REGISTER_L);

  lrSelection = lrSelectionUndo;
  if(savedStatisticalSumsPointer == NULL) {
    freeC47Blocks(statisticalSumsPointer, NUMBER_OF_STATISTICAL_SUMS * REAL_SIZE_IN_BLOCKS(75));
    statisticalSumsPointer = NULL;
    lrChosen = 0;
  }
  else {
    lrChosen = lrChosenUndo;
    if(statisticalSumsPointer == NULL) {
      statisticalSumsPointer = allocC47Blocks(NUMBER_OF_STATISTICAL_SUMS * REAL_SIZE_IN_BLOCKS(75));
    }
    xcopy(statisticalSumsPointer, savedStatisticalSumsPointer, NUMBER_OF_STATISTICAL_SUMS * REAL_SIZE_IN_BYTES(75));
  }

  SAVED_SIGMA_lastAddRem = SIGMA_NONE;
  thereIsSomethingToUndo = false;
  clearRegister(TEMP_REGISTER_2_SAVED_STATS);

  if(wasSolving != getSystemFlag(FLAG_SOLVING)) {
    flipSystemFlag(FLAG_SOLVING);
  }
  if(wasInting != getSystemFlag(FLAG_INTING)) {
    flipSystemFlag(FLAG_INTING);
  }
}
