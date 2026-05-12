// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

uint8_t shortIntegerWordSize;
uint64_t shortIntegerMask;
bool_t thereIsSomethingToUndo;
uint8_t temporaryInformation;
parity_runtime_state_t parityRuntimeState;

static uint64_t *registerWord(calcRegister_t reg) {
  switch(reg) {
    case REGISTER_X: return &parityRuntimeState.x_raw;
    case REGISTER_L: return &parityRuntimeState.l_raw;
    default: return NULL;
  }
}

static uint32_t *registerBase(calcRegister_t reg) {
  switch(reg) {
    case REGISTER_X: return &parityRuntimeState.x_base;
    case REGISTER_L: return &parityRuntimeState.l_base;
    default: return NULL;
  }
}

static uint32_t *registerType(calcRegister_t reg) {
  switch(reg) {
    case REGISTER_X: return &parityRuntimeState.x_data_type;
    case REGISTER_L: return &parityRuntimeState.l_data_type;
    default: return NULL;
  }
}

void parityResetState(uint8_t wordSize, uint64_t xRaw, uint32_t xBase) {
  shortIntegerWordSize = wordSize;
  shortIntegerMask = wordSize == 64 ? UINT64_MAX : ((UINT64_C(1) << wordSize) - 1u);

  parityRuntimeState.x_raw = xRaw & shortIntegerMask;
  parityRuntimeState.x_base = xBase;
  parityRuntimeState.x_data_type = dtShortInteger;
  parityRuntimeState.l_raw = 0;
  parityRuntimeState.l_base = 0;
  parityRuntimeState.l_data_type = 0;
  parityRuntimeState.get_shortint_ok = true;
  parityRuntimeState.save_last_x_ok = true;
  parityRuntimeState.saved_last_x = false;
  parityRuntimeState.lifted_stack = false;
  parityRuntimeState.last_error_code = 0;
  parityRuntimeState.last_error_message_register = 0;
  parityRuntimeState.last_error_register = 0;
  thereIsSomethingToUndo = true;
  temporaryInformation = 0;
}

void paritySetGetShortIntOk(bool_t ok) {
  parityRuntimeState.get_shortint_ok = ok;
}

void paritySetSaveLastXOk(bool_t ok) {
  parityRuntimeState.save_last_x_ok = ok;
}

bool_t getRegisterAsRawShortInt(calcRegister_t reg, uint64_t *val, uint32_t *base) {
  uint64_t *word = registerWord(reg);
  uint32_t *tag = registerBase(reg);

  if(!parityRuntimeState.get_shortint_ok || word == NULL || tag == NULL) {
    return false;
  }

  *val = *word;
  if(base != NULL) {
    *base = *tag;
  }
  return true;
}

bool_t saveLastX(void) {
  if(!parityRuntimeState.save_last_x_ok) {
    return false;
  }

  parityRuntimeState.saved_last_x = true;
  parityRuntimeState.l_raw = parityRuntimeState.x_raw;
  parityRuntimeState.l_base = parityRuntimeState.x_base;
  parityRuntimeState.l_data_type = parityRuntimeState.x_data_type;
  return true;
}

void liftStack(void) {
  parityRuntimeState.lifted_stack = true;
}

void displayCalcErrorMessage(uint8_t errorCode, calcRegister_t errMessageRegisterLine, calcRegister_t errRegisterLine) {
  parityRuntimeState.last_error_code = errorCode;
  parityRuntimeState.last_error_message_register = errMessageRegisterLine;
  parityRuntimeState.last_error_register = errRegisterLine;
}

void reallocateRegister(calcRegister_t regist, uint32_t dataType, uint16_t dataSizeWithoutDataLenBlocks, uint32_t tag) {
  (void)dataSizeWithoutDataLenBlocks;

  if(registerType(regist) != NULL) {
    *registerType(regist) = dataType;
  }
  if(registerBase(regist) != NULL) {
    *registerBase(regist) = tag;
  }
}

void *getRegisterDataPointer(calcRegister_t regist) {
  return registerWord(regist);
}

void convertUInt64ToShortIntegerRegister(int16_t sign, uint64_t value, uint32_t base, calcRegister_t regist) {
  (void)sign;
  reallocateRegister(regist, dtShortInteger, SHORT_INTEGER_SIZE_IN_BLOCKS, base);
  *registerWord(regist) = value & shortIntegerMask;
}