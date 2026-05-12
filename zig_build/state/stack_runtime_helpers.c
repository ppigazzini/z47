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
