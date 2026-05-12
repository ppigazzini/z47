// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
  void *ptr;
  uint16_t size_in_blocks;
} fake_memory_slot_t;

registerHeader_t globalRegister[NUMBER_OF_GLOBAL_REGISTERS];
static namedVariableHeader_t fake_named_variables[MAX_FAKE_NAMED_VARIABLES];
static registerHeader_t fake_local_registers[MAX_FAKE_LOCAL_REGISTERS];
namedVariableHeader_t *allNamedVariables = fake_named_variables;
registerHeader_t *currentLocalRegisters = fake_local_registers;
char errorMessage[ERROR_MESSAGE_LENGTH];
const char commonBugScreenMessages[2][ERROR_MESSAGE_LENGTH] = {
  "%s: no named variables",
  "%s: register %d must be less than %d",
};
uint16_t numberOfNamedVariables = 0;
uint8_t currentNumberOfLocalRegisters = 0;

uint16_t currentInputVariable = INVALID_VARIABLE;
uint8_t displayStack = 0;
bool_t thereIsSomethingToUndo = false;
uint8_t calcMode = 0;
uint8_t lastErrorCode = ERROR_NONE;
uint8_t entryStatus = 0;
uint64_t systemFlags0 = 0;
uint64_t systemFlags1 = 0;
uint64_t savedSystemFlags0 = 0;
uint64_t savedSystemFlags1 = 0;
int8_t SAVED_SIGMA_lastAddRem = SIGMA_NONE;
uint16_t lrSelection = 0;
uint16_t lrSelectionUndo = 0;
uint16_t lrChosen = 0;
uint16_t lrChosenUndo = 0;
real_t *statisticalSumsPointer = NULL;
real_t *savedStatisticalSumsPointer = NULL;
real_t SAVED_SIGMA_LASTX = {{0}};
real_t SAVED_SIGMA_LASTY = {{0}};

static fake_memory_slot_t fake_memory_slots[MAX_FAKE_MEMORY_SLOTS];

#ifdef Z47_REGISTER_METADATA_RUNTIME
#define getRegisterDataPointer z47_stack_parity_raw_getRegisterDataPointer
#define setRegisterDataPointer z47_stack_parity_raw_setRegisterDataPointer
#define getRegisterDataType z47_stack_parity_raw_getRegisterDataType
#define getRegisterTag z47_stack_parity_raw_getRegisterTag
#define setRegisterDataType z47_stack_parity_raw_setRegisterDataType
#endif

static registerHeader_t *mutableRegisterHeader(calcRegister_t reg) {
  if(reg <= LAST_GLOBAL_REGISTER) {
    return &globalRegister[reg];
  }
  if(reg >= FIRST_NAMED_VARIABLE && reg < FIRST_NAMED_VARIABLE + (calcRegister_t)numberOfNamedVariables) {
    return &allNamedVariables[reg - FIRST_NAMED_VARIABLE].header;
  }
  if(reg >= FIRST_LOCAL_REGISTER && reg < FIRST_LOCAL_REGISTER + (calcRegister_t)currentNumberOfLocalRegisters) {
    return &currentLocalRegisters[reg - FIRST_LOCAL_REGISTER];
  }
  return NULL;
}

static const registerHeader_t *constRegisterHeader(calcRegister_t reg) {
  return mutableRegisterHeader(reg);
}

static uint16_t findSlot(const void *ptr) {
  uint16_t i;

  if(ptr == NULL) {
    return 0;
  }

  for(i = 1; i < MAX_FAKE_MEMORY_SLOTS; i++) {
    if(fake_memory_slots[i].ptr == ptr) {
      return i;
    }
  }

  return 0;
}

uint16_t stackParityToC47MemPtr(const void *ptr) {
  return findSlot(ptr);
}

void *stackParityToPcMemPtr(uint16_t ptr) {
  if(ptr == C47_NULL || ptr >= MAX_FAKE_MEMORY_SLOTS) {
    return NULL;
  }
  return fake_memory_slots[ptr].ptr;
}

static void freeSlot(uint16_t slot) {
  if(slot == 0 || slot >= MAX_FAKE_MEMORY_SLOTS) {
    return;
  }
  if(fake_memory_slots[slot].ptr == NULL) {
    return;
  }

  free(fake_memory_slots[slot].ptr);
  fake_memory_slots[slot].ptr = NULL;
  fake_memory_slots[slot].size_in_blocks = 0;
}

static void captureRegister(stack_parity_register_snapshot_t *snapshot, const registerHeader_t *header) {
  uint16_t slot;
  uint32_t size_bytes = 0;

  snapshot->header = *header;
  slot = header->pointerToRegisterData;
  snapshot->size_in_blocks = slot == 0 ? 0 : fake_memory_slots[slot].size_in_blocks;
  memset(snapshot->data, 0, sizeof(snapshot->data));
  if(slot != 0 && fake_memory_slots[slot].ptr != NULL) {
    size_bytes = TO_BYTES(snapshot->size_in_blocks);
    if(size_bytes > sizeof(snapshot->data)) {
      size_bytes = sizeof(snapshot->data);
    }
    memcpy(snapshot->data, fake_memory_slots[slot].ptr, size_bytes);
    snapshot->header.pointerToRegisterData = 1;
  }
}

void stackParityReset(void) {
  uint16_t i;

  for(i = 1; i < MAX_FAKE_MEMORY_SLOTS; i++) {
    freeSlot(i);
  }

  memset(globalRegister, 0, sizeof(globalRegister));
  memset(fake_named_variables, 0, sizeof(fake_named_variables));
  memset(fake_local_registers, 0, sizeof(fake_local_registers));
  numberOfNamedVariables = 0;
  currentNumberOfLocalRegisters = 0;
  currentInputVariable = INVALID_VARIABLE;
  displayStack = 0;
  thereIsSomethingToUndo = false;
  calcMode = 0;
  lastErrorCode = ERROR_NONE;
  entryStatus = 0;
  systemFlags0 = 0;
  systemFlags1 = 0;
  savedSystemFlags0 = 0;
  savedSystemFlags1 = 0;
  SAVED_SIGMA_lastAddRem = SIGMA_NONE;
  lrSelection = 0;
  lrSelectionUndo = 0;
  lrChosen = 0;
  lrChosenUndo = 0;
  statisticalSumsPointer = NULL;
  savedStatisticalSumsPointer = NULL;
  memset(&SAVED_SIGMA_LASTX, 0, sizeof(SAVED_SIGMA_LASTX));
  memset(&SAVED_SIGMA_LASTY, 0, sizeof(SAVED_SIGMA_LASTY));
}

void *allocC47Blocks(size_t size_in_blocks) {
  uint16_t slot;
  void *ptr;

  for(slot = 1; slot < MAX_FAKE_MEMORY_SLOTS; slot++) {
    if(fake_memory_slots[slot].ptr == NULL) {
      break;
    }
  }
  if(slot == MAX_FAKE_MEMORY_SLOTS) {
    return NULL;
  }

  ptr = calloc(1, TO_BYTES(size_in_blocks));
  if(ptr == NULL) {
    return NULL;
  }

  fake_memory_slots[slot].ptr = ptr;
  fake_memory_slots[slot].size_in_blocks = (uint16_t)size_in_blocks;
  return ptr;
}

void freeC47Blocks(void *ptr, size_t size_in_blocks) {
  (void)size_in_blocks;
  freeSlot(findSlot(ptr));
}

void *getRegisterDataPointer(calcRegister_t reg) {
  const registerHeader_t *header = constRegisterHeader(reg);
  if(header == NULL || header->pointerToRegisterData == 0) {
    return NULL;
  }
  return fake_memory_slots[header->pointerToRegisterData].ptr;
}

void setRegisterDataPointer(calcRegister_t reg, const void *mem_ptr) {
  registerHeader_t *header = mutableRegisterHeader(reg);
  if(header == NULL) {
    return;
  }
  header->pointerToRegisterData = findSlot(mem_ptr);
}

uint32_t getRegisterDataType(calcRegister_t reg) {
  const registerHeader_t *header = constRegisterHeader(reg);
  return header == NULL ? 0u : header->dataType;
}

uint32_t getRegisterTag(calcRegister_t reg) {
  const registerHeader_t *header = constRegisterHeader(reg);
  return header == NULL ? 0u : header->tag;
}

void setRegisterDataType(calcRegister_t reg, uint16_t data_type, uint32_t tag) {
  registerHeader_t *header = mutableRegisterHeader(reg);
  if(header == NULL) {
    return;
  }
  header->dataType = data_type;
  header->tag = tag;
}

uint16_t getRegisterFullSizeInBlocks(calcRegister_t reg) {
  const registerHeader_t *header = constRegisterHeader(reg);
  uint16_t slot;

  if(header == NULL) {
    return 0;
  }
  slot = header->pointerToRegisterData;
  if(slot == 0) {
    return 0;
  }
  return fake_memory_slots[slot].size_in_blocks;
}

void *xcopy(void *dest, const void *source, uint32_t n) {
  if(dest != NULL && source != NULL && n != 0) {
    memmove(dest, source, n);
  }
  return dest;
}

bool_t getSystemFlag(int32_t sf) {
  int32_t flag = sf & 0x3fff;
  if(flag < 64) {
    return (systemFlags0 & ((uint64_t)1u << flag)) != 0;
  }
  return (systemFlags1 & ((uint64_t)1u << (flag - 64))) != 0;
}

void setSystemFlag(unsigned int sf) {
  int32_t flag = (int32_t)(sf & 0x3fff);
  if(flag < 64) {
    systemFlags0 |= ((uint64_t)1u << flag);
  }
  else {
    systemFlags1 |= ((uint64_t)1u << (flag - 64));
  }
}

void clearSystemFlag(unsigned int sf) {
  int32_t flag = (int32_t)(sf & 0x3fff);
  if(flag < 64) {
    systemFlags0 &= ~((uint64_t)1u << flag);
  }
  else {
    systemFlags1 &= ~((uint64_t)1u << (flag - 64));
  }
}

void flipSystemFlag(unsigned int sf) {
  int32_t flag = (int32_t)(sf & 0x3fff);
  if(flag < 64) {
    systemFlags0 ^= ((uint64_t)1u << flag);
  }
  else {
    systemFlags1 ^= ((uint64_t)1u << (flag - 64));
  }
}

void clearRegister(calcRegister_t reg) {
  registerHeader_t *header = mutableRegisterHeader(reg);
  void *ptr;

  if(header == NULL) {
    return;
  }

  freeRegisterData(reg);
  header->descriptor = 0;
  header->dataType = dtReal34;
  header->tag = amNone;
  ptr = allocC47Blocks(REAL34_SIZE_IN_BLOCKS);
  if(ptr == NULL) {
    lastErrorCode = ERROR_RAM_FULL;
    return;
  }
  setRegisterDataPointer(reg, ptr);
  memset(ptr, 0, REAL34_SIZE_IN_BYTES);
}

void copySourceRegisterToDestRegister(calcRegister_t source_register, calcRegister_t dest_register) {
  const registerHeader_t *source = constRegisterHeader(source_register);
  registerHeader_t *dest = mutableRegisterHeader(dest_register);
  uint16_t size_in_blocks;
  void *dest_ptr;

  if(source == NULL || dest == NULL) {
    return;
  }

  size_in_blocks = getRegisterFullSizeInBlocks(source_register);
  freeRegisterData(dest_register);
  *dest = *source;

  if(source->pointerToRegisterData == 0 || size_in_blocks == 0) {
    dest->pointerToRegisterData = 0;
    return;
  }

  dest_ptr = allocC47Blocks(size_in_blocks);
  if(dest_ptr == NULL) {
    lastErrorCode = ERROR_RAM_FULL;
    return;
  }
  setRegisterDataPointer(dest_register, dest_ptr);
  xcopy(dest_ptr, getRegisterDataPointer(source_register), TO_BYTES(size_in_blocks));
}

void displayCalcErrorMessage(uint8_t error_code, calcRegister_t err_message_register_line, calcRegister_t err_register_line) {
  (void)err_message_register_line;
  (void)err_register_line;
  lastErrorCode = error_code;
}

void moreInfoOnError(const char *m1, const char *m2, const char *m3, const char *m4) {
  (void)m1;
  (void)m2;
  (void)m3;
  (void)m4;
}

void displayBugScreen(const char *message) {
  (void)message;
  lastErrorCode = ERROR_OUT_OF_RANGE;
}

void reallocateRegister(calcRegister_t reg, uint32_t data_type, uint16_t data_size_without_data_len_blocks, uint32_t tag) {
  registerHeader_t *header = mutableRegisterHeader(reg);
  uint16_t size_in_blocks = data_size_without_data_len_blocks;
  void *ptr = NULL;

  if(header == NULL) {
    return;
  }

  freeRegisterData(reg);
  header->descriptor = 0;
  header->dataType = data_type;
  header->tag = tag;

  if(data_type == dtReal34 && size_in_blocks == 0) {
    size_in_blocks = REAL34_SIZE_IN_BLOCKS;
  }

  if(size_in_blocks != 0) {
    ptr = allocC47Blocks(size_in_blocks);
    if(ptr == NULL) {
      lastErrorCode = ERROR_RAM_FULL;
      return;
    }
    setRegisterDataPointer(reg, ptr);
    memset(ptr, 0, TO_BYTES(size_in_blocks));
  }
}

void real34SetZero(real34_t *dest) {
  if(dest != NULL) {
    memset(dest, 0, sizeof(*dest));
  }
}

void z47_stack_runtime_real34_set_zero(void *dest) {
  real34SetZero((real34_t *)dest);
}

void longIntegerInit(longInteger_t value) {
  value[0] = 0;
}

void uInt32ToLongInteger(uint32_t source, longInteger_t dest) {
  dest[0] = source;
}

void convertLongIntegerToLongIntegerRegister(const longInteger_t value, calcRegister_t dest) {
  reallocateRegister(dest, dtLongInteger, 1, 0);
  if(getRegisterDataPointer(dest) != NULL) {
    memcpy(getRegisterDataPointer(dest), value, sizeof(uint32_t));
  }
}

void longIntegerFree(longInteger_t value) {
  (void)value;
}

void convertRealToResultRegister(const real_t *value, calcRegister_t dest, uint32_t angle) {
  (void)angle;
  reallocateRegister(dest, dtReal34, 0, amNone);
  if(getRegisterDataPointer(dest) != NULL && value != NULL) {
    memcpy(getRegisterDataPointer(dest), value, sizeof(real_t) < REAL34_SIZE_IN_BYTES ? sizeof(real_t) : REAL34_SIZE_IN_BYTES);
  }
}

void fnRecall(uint16_t reg) {
  copySourceRegisterToDestRegister((calcRegister_t)reg, REGISTER_X);
}

void recallStatsMatrix(void) {
}

void fnSigmaAddRem(uint16_t selection) {
  SAVED_SIGMA_lastAddRem = (int8_t)selection;
}

uint16_t z47_stack_runtime_get_stack_top(void) {
  return getSystemFlag(FLAG_SSIZE8) ? REGISTER_D : REGISTER_T;
}

uint16_t z47_stack_runtime_real34_size_in_blocks(void) {
  return REAL34_SIZE_IN_BLOCKS;
}

uint32_t z47_stack_runtime_get_global_register_descriptor(calcRegister_t reg) {
  return globalRegister[reg].descriptor;
}

void z47_stack_runtime_set_global_register_descriptor(calcRegister_t reg, uint32_t descriptor) {
  globalRegister[reg].descriptor = descriptor;
}

bool_t z47_stack_runtime_get_swap_target_descriptor(uint16_t reg, uint32_t *descriptor) {
  const registerHeader_t *header = constRegisterHeader((calcRegister_t)reg);
  if(header == NULL) {
    return false;
  }
  *descriptor = header->descriptor;
  return true;
}

bool_t z47_stack_runtime_set_swap_target_descriptor(uint16_t reg, uint32_t descriptor) {
  registerHeader_t *header = mutableRegisterHeader((calcRegister_t)reg);
  if(header == NULL) {
    return false;
  }
  header->descriptor = descriptor;
  return true;
}

void z47_stack_runtime_report_invalid_swap_target(uint16_t reg) {
  (void)reg;
  displayCalcErrorMessage(ERROR_OUT_OF_RANGE, REGISTER_Z, REGISTER_X);
}

uint16_t z47_stack_runtime_statistical_sums_blocks(void) {
  return NUMBER_OF_STATISTICAL_SUMS * REAL_SIZE_IN_BLOCKS(75);
}

uint32_t z47_stack_runtime_statistical_sums_bytes(void) {
  return NUMBER_OF_STATISTICAL_SUMS * REAL_SIZE_IN_BYTES(75);
}

void z47_stack_runtime_store_stack_size_in_x(uint32_t size) {
  longInteger_t li;
  longIntegerInit(li);
  uInt32ToLongInteger(size, li);
  convertLongIntegerToLongIntegerRegister(li, REGISTER_X);
}

void z47_stack_runtime_restore_saved_sigma_last_xy_and_add(void) {
  convertRealToResultRegister(&SAVED_SIGMA_LASTX, REGISTER_X, amNone);
  convertRealToResultRegister(&SAVED_SIGMA_LASTY, REGISTER_Y, amNone);
  fnSigmaAddRem(SIGMA_PLUS);
}

void stackParitySeedRegister(calcRegister_t reg, uint32_t data_type, uint32_t tag, const uint8_t *data, uint16_t size_in_blocks) {
  registerHeader_t *header = mutableRegisterHeader(reg);
  void *ptr = NULL;

  if(header == NULL) {
    return;
  }

  freeRegisterData(reg);
  header->descriptor = 0;
  header->dataType = data_type;
  header->tag = tag;
  if(size_in_blocks != 0) {
    ptr = allocC47Blocks(size_in_blocks);
    if(ptr == NULL) {
      lastErrorCode = ERROR_RAM_FULL;
      return;
    }
    setRegisterDataPointer(reg, ptr);
    if(data != NULL) {
      memcpy(ptr, data, TO_BYTES(size_in_blocks));
    }
  }
}

void stackParitySeedNamedVariable(int index, uint32_t data_type, uint32_t tag, const uint8_t *data, uint16_t size_in_blocks) {
  calcRegister_t reg;

  if(index < 0 || index >= MAX_FAKE_NAMED_VARIABLES) {
    return;
  }
  if(numberOfNamedVariables < (uint16_t)(index + 1)) {
    numberOfNamedVariables = (uint16_t)(index + 1);
  }
  reg = (calcRegister_t)(FIRST_NAMED_VARIABLE + index);
  stackParitySeedRegister(reg, data_type, tag, data, size_in_blocks);
}

void stackParitySeedLocalRegister(int index, uint32_t data_type, uint32_t tag, const uint8_t *data, uint16_t size_in_blocks) {
  calcRegister_t reg;

  if(index < 0 || index >= MAX_FAKE_LOCAL_REGISTERS) {
    return;
  }
  if(currentNumberOfLocalRegisters < (uint8_t)(index + 1)) {
    currentNumberOfLocalRegisters = (uint8_t)(index + 1);
  }
  reg = (calcRegister_t)(FIRST_LOCAL_REGISTER + index);
  stackParitySeedRegister(reg, data_type, tag, data, size_in_blocks);
}

void stackParitySeedCurrentStats(uint8_t seed) {
  uint8_t *ptr;
  uint32_t i;

  freeC47Blocks(statisticalSumsPointer, z47_stack_runtime_statistical_sums_blocks());
  statisticalSumsPointer = allocC47Blocks(z47_stack_runtime_statistical_sums_blocks());
  if(statisticalSumsPointer == NULL) {
    return;
  }
  ptr = (uint8_t *)statisticalSumsPointer;
  for(i = 0; i < z47_stack_runtime_statistical_sums_bytes(); i++) {
    ptr[i] = (uint8_t)(seed + i);
  }
}

void stackParitySeedSavedStats(uint8_t seed) {
  uint8_t *ptr;
  uint32_t i;

  freeC47Blocks(savedStatisticalSumsPointer, z47_stack_runtime_statistical_sums_blocks());
  savedStatisticalSumsPointer = allocC47Blocks(z47_stack_runtime_statistical_sums_blocks());
  if(savedStatisticalSumsPointer == NULL) {
    return;
  }
  ptr = (uint8_t *)savedStatisticalSumsPointer;
  for(i = 0; i < z47_stack_runtime_statistical_sums_bytes(); i++) {
    ptr[i] = (uint8_t)(seed + i);
  }
}

void stackParityCapture(stack_parity_snapshot_t *snapshot) {
  int i;

  memset(snapshot, 0, sizeof(*snapshot));
  for(i = 0; i < NUMBER_OF_GLOBAL_REGISTERS; i++) {
    captureRegister(&snapshot->global_registers[i], &globalRegister[i]);
  }
  for(i = 0; i < MAX_FAKE_NAMED_VARIABLES; i++) {
    captureRegister(&snapshot->named_variables[i], &fake_named_variables[i].header);
  }
  for(i = 0; i < MAX_FAKE_LOCAL_REGISTERS; i++) {
    captureRegister(&snapshot->local_registers[i], &fake_local_registers[i]);
  }

  snapshot->numberOfNamedVariables = numberOfNamedVariables;
  snapshot->currentNumberOfLocalRegisters = currentNumberOfLocalRegisters;
  snapshot->currentInputVariable = currentInputVariable;
  snapshot->displayStack = displayStack;
  snapshot->thereIsSomethingToUndo = thereIsSomethingToUndo;
  snapshot->calcMode = calcMode;
  snapshot->lastErrorCode = lastErrorCode;
  snapshot->entryStatus = entryStatus;
  snapshot->systemFlags0 = systemFlags0;
  snapshot->systemFlags1 = systemFlags1;
  snapshot->savedSystemFlags0 = savedSystemFlags0;
  snapshot->savedSystemFlags1 = savedSystemFlags1;
  snapshot->SAVED_SIGMA_lastAddRem = SAVED_SIGMA_lastAddRem;
  snapshot->lrSelection = lrSelection;
  snapshot->lrSelectionUndo = lrSelectionUndo;
  snapshot->lrChosen = lrChosen;
  snapshot->lrChosenUndo = lrChosenUndo;
  snapshot->stats_present = statisticalSumsPointer != NULL;
  snapshot->saved_stats_present = savedStatisticalSumsPointer != NULL;
  if(statisticalSumsPointer != NULL) {
    memcpy(snapshot->statistical_sums, statisticalSumsPointer, z47_stack_runtime_statistical_sums_bytes());
  }
  if(savedStatisticalSumsPointer != NULL) {
    memcpy(snapshot->saved_statistical_sums, savedStatisticalSumsPointer, z47_stack_runtime_statistical_sums_bytes());
  }
}
