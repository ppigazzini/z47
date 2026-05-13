// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

uint16_t z47_stack_runtime_get_stack_top(void) {
  return getStackTop();
}

uint16_t z47_stack_runtime_real34_size_in_blocks(void) {
  return REAL34_SIZE_IN_BLOCKS;
}

void z47_stack_runtime_real34_set_zero(void *dest) {
  real34SetZero((real34_t *)dest);
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
