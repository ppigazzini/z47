// SPDX-License-Identifier: GPL-3.0-only

#include <string.h>

#include "c47.h"

uint8_t shortIntegerWordSize;
uint64_t shortIntegerMask;
uint64_t shortIntegerSignBit;
bool_t thereIsSomethingToUndo;
uint8_t temporaryInformation;
parity_runtime_state_t parityRuntimeState;

static uint64_t *registerWord(calcRegister_t reg) {
  switch(reg) {
    case REGISTER_X: return &parityRuntimeState.x_raw;
    case REGISTER_Y: return &parityRuntimeState.y_raw;
    case REGISTER_Z: return &parityRuntimeState.z_raw;
    case REGISTER_L: return &parityRuntimeState.l_raw;
    default: return NULL;
  }
}

static uint32_t *registerBase(calcRegister_t reg) {
  switch(reg) {
    case REGISTER_X: return &parityRuntimeState.x_base;
    case REGISTER_Y: return &parityRuntimeState.y_base;
    case REGISTER_Z: return &parityRuntimeState.z_base;
    case REGISTER_L: return &parityRuntimeState.l_base;
    default: return NULL;
  }
}

static uint32_t *registerType(calcRegister_t reg) {
  switch(reg) {
    case REGISTER_X: return &parityRuntimeState.x_data_type;
    case REGISTER_Y: return &parityRuntimeState.y_data_type;
    case REGISTER_Z: return &parityRuntimeState.z_data_type;
    case REGISTER_L: return &parityRuntimeState.l_data_type;
    default: return NULL;
  }
}

static void copyRegister(calcRegister_t source, calcRegister_t dest) {
  if(registerWord(source) == NULL || registerWord(dest) == NULL) {
    return;
  }

  *registerWord(dest) = *registerWord(source);
  *registerBase(dest) = *registerBase(source);
  *registerType(dest) = *registerType(source);
}

static void maskRegisterIfShortInteger(calcRegister_t reg) {
  if(registerWord(reg) != NULL && registerType(reg) != NULL && *registerType(reg) == dtShortInteger) {
    *registerWord(reg) &= shortIntegerMask;
  }
}

void rotateBitsResetState(uint8_t wordSize,
                          uint64_t xRaw,
                          uint32_t xBase,
                          uint64_t yRaw,
                          uint32_t yBase,
                          uint64_t zRaw,
                          uint32_t zBase,
                          bool_t carryFlag) {
  memset(&parityRuntimeState, 0, sizeof(parityRuntimeState));

  shortIntegerWordSize = wordSize;
  shortIntegerMask = wordSize == 64 ? UINT64_MAX : ((UINT64_C(1) << wordSize) - 1u);
  shortIntegerSignBit = UINT64_C(1) << (wordSize - 1u);

  parityRuntimeState.x_raw = xRaw & shortIntegerMask;
  parityRuntimeState.x_base = xBase;
  parityRuntimeState.x_data_type = dtShortInteger;
  parityRuntimeState.y_raw = yRaw & shortIntegerMask;
  parityRuntimeState.y_base = yBase;
  parityRuntimeState.y_data_type = dtShortInteger;
  parityRuntimeState.z_raw = zRaw & shortIntegerMask;
  parityRuntimeState.z_base = zBase;
  parityRuntimeState.z_data_type = dtShortInteger;
  parityRuntimeState.l_data_type = 0;
  parityRuntimeState.get_shortint_ok = true;
  parityRuntimeState.save_last_x_ok = true;
  parityRuntimeState.carry_flag = carryFlag;

  thereIsSomethingToUndo = true;
  temporaryInformation = 0;
}

void rotateBitsCapture(rotate_bits_snapshot_t *out) {
  memset(out, 0, sizeof(*out));
  out->runtime_state = parityRuntimeState;
  out->word_size = shortIntegerWordSize;
  out->mask = shortIntegerMask;
  out->sign_bit = shortIntegerSignBit;
  out->temporary_information = temporaryInformation;
  out->undo_flag = thereIsSomethingToUndo;
}

bool_t getRegisterAsRawShortInt(calcRegister_t reg, uint64_t *val, uint32_t *base) {
  uint64_t *word = registerWord(reg);
  uint32_t *tag = registerBase(reg);
  uint32_t *type = registerType(reg);

  if(!parityRuntimeState.get_shortint_ok || word == NULL || tag == NULL || type == NULL || *type != dtShortInteger) {
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
  copyRegister(REGISTER_X, REGISTER_L);
  return true;
}

void liftStack(void) {
  parityRuntimeState.lifted_stack = true;
  parityRuntimeState.aslift_flag = true;
  copyRegister(REGISTER_Y, REGISTER_Z);
  copyRegister(REGISTER_X, REGISTER_Y);
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

bool_t getSystemFlag(int32_t sf) {
  switch(sf) {
    case FLAG_CARRY: return parityRuntimeState.carry_flag;
    case FLAG_ASLIFT: return parityRuntimeState.aslift_flag;
    default: return false;
  }
}

void setSystemFlag(unsigned int sf) {
  switch(sf) {
    case FLAG_CARRY: parityRuntimeState.carry_flag = true; break;
    case FLAG_ASLIFT: parityRuntimeState.aslift_flag = true; break;
    default: break;
  }
}

void forceSystemFlag(unsigned int sf, int set) {
  switch(sf) {
    case FLAG_CARRY: parityRuntimeState.carry_flag = set != 0; break;
    case FLAG_ASLIFT: parityRuntimeState.aslift_flag = set != 0; break;
    default: break;
  }
}

void fnSetWordSize(uint16_t ws) {
  bool_t reduceWordSize;

  if(ws == 0) {
    ws = 64;
  }

  reduceWordSize = ws < shortIntegerWordSize;

  shortIntegerWordSize = (uint8_t)ws;
  shortIntegerMask = shortIntegerWordSize == 64 ? UINT64_MAX : ((UINT64_C(1) << shortIntegerWordSize) - 1u);
  shortIntegerSignBit = UINT64_C(1) << (shortIntegerWordSize - 1u);

  if(reduceWordSize) {
    maskRegisterIfShortInteger(REGISTER_X);
    maskRegisterIfShortInteger(REGISTER_Y);
    maskRegisterIfShortInteger(REGISTER_Z);
    maskRegisterIfShortInteger(REGISTER_L);
  }
}

void adjustResult(calcRegister_t res, bool_t dropY, bool_t setCpxRes, calcRegister_t op1, calcRegister_t op2, calcRegister_t op3) {
  (void)res;
  (void)setCpxRes;
  (void)op1;
  (void)op2;
  (void)op3;

  parityRuntimeState.adjust_result_calls++;
  parityRuntimeState.lifted_stack = true;
  parityRuntimeState.aslift_flag = true;

  if(dropY) {
    copyRegister(REGISTER_Z, REGISTER_Y);
  }
}

void longIntegerInit(longInteger_t value) {
  value[0] = 0;
}

void uInt32ToLongInteger(uint32_t source, longInteger_t dest) {
  dest[0] = source;
}

void convertLongIntegerToLongIntegerRegister(const longInteger_t value, calcRegister_t dest) {
  reallocateRegister(dest, dtLongInteger, 1, 0);
  if(registerWord(dest) != NULL) {
    *registerWord(dest) = value[0];
  }
}

void convertShortIntegerRegisterToLongIntegerRegister(calcRegister_t source, calcRegister_t dest) {
  reallocateRegister(dest, dtLongInteger, 1, 0);
  if(registerWord(source) != NULL && registerWord(dest) != NULL) {
    *registerWord(dest) = *registerWord(source);
  }
}

void longIntegerFree(longInteger_t value) {
  (void)value;
}