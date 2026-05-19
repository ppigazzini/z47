// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
  void *ptr;
  uint16_t size_in_blocks;
} fake_memory_slot_t;

enum {
  FAKE_CAT_STATUS = 0x00f0,
  FAKE_CAT_MENU = (2 << 4),
  FAKE_CMP_NAME = 3,
  MAX_FAKE_MENU_ITEMS = 8,
  MAX_FAKE_USER_MENUS = 8,
};

#ifdef Z47_REGISTER_METADATA_RUNTIME
typedef struct {
  uint32_t status;
  char itemCatalogName[16];
} item_t;

typedef struct {
  char menuName[16];
} userMenu_t;
#endif

registerHeader_t globalRegister[NUMBER_OF_GLOBAL_REGISTERS];
static namedVariableHeader_t fake_named_variables[MAX_FAKE_NAMED_VARIABLES];
static registerHeader_t fake_local_registers[MAX_FAKE_LOCAL_REGISTERS];
namedVariableHeader_t *allNamedVariables = fake_named_variables;
registerHeader_t *currentLocalRegisters = fake_local_registers;
#ifdef Z47_REGISTER_METADATA_RUNTIME
item_t indexOfItems[MAX_FAKE_MENU_ITEMS];
static userMenu_t fake_user_menus[MAX_FAKE_USER_MENUS];
userMenu_t *userMenus = fake_user_menus;
uint16_t numberOfUserMenus = 0;
#endif
uint32_t currentAngularMode = amNone;
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
uint8_t programRunStop = 0;
uint8_t Input_Default = ID_43S;
uint8_t lastErrorCode = ERROR_NONE;
uint8_t entryStatus = 0;
uint32_t lastIntegerBase = 0;
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
static bool_t fake_memory_block_available = true;
static uint8_t confirmation_request = 0;
static uint8_t fake_regclr_error_code = ERROR_NONE;
static uint16_t fake_regclr_start = 0;
static uint16_t fake_regclr_count = 0;
static uint8_t fake_regswap_error_code = ERROR_NONE;
static uint16_t fake_regswap_start = 0;
static uint16_t fake_regswap_count = 0;
static uint16_t fake_regswap_dest = 0;
static uint8_t fake_regcopy_error_code = ERROR_NONE;
static bool_t fake_regcopy_f = false;
static uint16_t fake_regcopy_start = 0;
static uint16_t fake_regcopy_count = 0;
static uint16_t fake_regcopy_dest = 0;
static bool_t fake_adjust_result_no_drop_success = true;

#ifdef Z47_STACK_STATE_RUNTIME
#define clearRegister z47_stack_parity_raw_clearRegister
#endif

#ifdef Z47_REGISTER_METADATA_RUNTIME
#define getRegisterDataPointer z47_stack_parity_raw_getRegisterDataPointer
#define setRegisterDataPointer z47_stack_parity_raw_setRegisterDataPointer
#define getRegisterDataType z47_stack_parity_raw_getRegisterDataType
#define getRegisterFullSizeInBlocks z47_stack_parity_raw_getRegisterFullSizeInBlocks
#define getRegisterTag z47_stack_parity_raw_getRegisterTag
#define setRegisterDataType z47_stack_parity_raw_setRegisterDataType
#define copySourceRegisterToDestRegister z47_stack_parity_raw_copySourceRegisterToDestRegister
#define reallocateRegister z47_stack_parity_raw_reallocateRegister
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
#ifdef Z47_REGISTER_METADATA_RUNTIME
  memset(indexOfItems, 0, sizeof(indexOfItems));
  memset(fake_user_menus, 0, sizeof(fake_user_menus));
  numberOfUserMenus = 0;
#endif
  numberOfNamedVariables = 0;
  currentNumberOfLocalRegisters = 0;
  confirmation_request = 0;
  fake_regclr_error_code = ERROR_NONE;
  fake_regclr_start = 0;
  fake_regclr_count = 0;
  fake_regswap_error_code = ERROR_NONE;
  fake_regswap_start = 0;
  fake_regswap_count = 0;
  fake_regswap_dest = 0;
  fake_regcopy_error_code = ERROR_NONE;
  fake_regcopy_f = false;
  fake_regcopy_start = 0;
  fake_regcopy_count = 0;
  fake_regcopy_dest = 0;
  fake_adjust_result_no_drop_success = true;
  currentInputVariable = INVALID_VARIABLE;
  displayStack = 0;
  thereIsSomethingToUndo = false;
  calcMode = 0;
  programRunStop = 0;
  Input_Default = ID_43S;
  lastErrorCode = ERROR_NONE;
  entryStatus = 0;
  lastIntegerBase = 0;
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
  currentAngularMode = amNone;
  memset(&SAVED_SIGMA_LASTX, 0, sizeof(SAVED_SIGMA_LASTX));
  memset(&SAVED_SIGMA_LASTY, 0, sizeof(SAVED_SIGMA_LASTY));
  fake_memory_block_available = true;
}

bool_t isMemoryBlockAvailable(size_t size_in_blocks, uint16_t numBlocks, float extraFraction) {
  (void)size_in_blocks;
  (void)numBlocks;
  (void)extraFraction;
  return fake_memory_block_available;
}

void stackParitySetMemoryBlockAvailable(bool_t available) {
  fake_memory_block_available = available;
}

void stackParitySeedBuiltInMenuItem(uint32_t index, uint32_t status, const char *name) {
  if(index >= MAX_FAKE_MENU_ITEMS) {
    return;
  }

  indexOfItems[index].status = status;
  memset(indexOfItems[index].itemCatalogName, 0, sizeof(indexOfItems[index].itemCatalogName));
  if(name != NULL) {
    strncpy(indexOfItems[index].itemCatalogName, name, sizeof(indexOfItems[index].itemCatalogName) - 1);
  }
}

void stackParitySeedUserMenu(uint32_t index, const char *name) {
  if(index >= MAX_FAKE_USER_MENUS) {
    return;
  }

  memset(fake_user_menus[index].menuName, 0, sizeof(fake_user_menus[index].menuName));
  if(name != NULL) {
    strncpy(fake_user_menus[index].menuName, name, sizeof(fake_user_menus[index].menuName) - 1);
  }
  if(index + 1 > numberOfUserMenus) {
    numberOfUserMenus = (uint16_t)(index + 1);
  }
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
  else if(data_type == dtComplex34 && size_in_blocks == 0) {
    size_in_blocks = COMPLEX34_SIZE_IN_BLOCKS;
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

bool_t z47_stack_runtime_try_fn_to_real_complex_zero(void) {
  uint8_t real_bytes[REAL34_SIZE_IN_BYTES];
  uint8_t *data;

  if(getRegisterDataType(REGISTER_X) != dtComplex34) {
    return false;
  }

  data = (uint8_t *)getRegisterDataPointer(REGISTER_X);
  if(data == NULL) {
    return false;
  }

  for(uint32_t i = 0; i < REAL34_SIZE_IN_BYTES; ++i) {
    if(data[REAL34_SIZE_IN_BYTES + i] != 0) {
      return false;
    }
  }

  memcpy(real_bytes, data, sizeof(real_bytes));
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  if(lastErrorCode != ERROR_NONE) {
    return true;
  }

  memcpy(getRegisterDataPointer(REGISTER_X), real_bytes, sizeof(real_bytes));
  confirmation_request = 4;
  return true;
}

bool_t z47_stack_runtime_try_fn_to_real_real34(void) {
  if(getRegisterDataType(REGISTER_X) != dtReal34) {
    return false;
  }

  confirmation_request = 6;
  copySourceRegisterToDestRegister(REGISTER_X, REGISTER_L);
  setRegisterDataType(REGISTER_X, dtReal34, amNone);
  return true;
}

bool_t z47_stack_runtime_try_fn_to_real_long_integer(void) {
  if(getRegisterDataType(REGISTER_X) != dtLongInteger) {
    return false;
  }

  confirmation_request = 7;
  copySourceRegisterToDestRegister(REGISTER_X, REGISTER_L);
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  return true;
}

bool_t z47_stack_runtime_try_fn_to_real_short_integer(void) {
  if(getRegisterDataType(REGISTER_X) != dtShortInteger) {
    return false;
  }

  confirmation_request = 8;
  copySourceRegisterToDestRegister(REGISTER_X, REGISTER_L);
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  lastIntegerBase = 0;
  return true;
}

bool_t z47_stack_runtime_try_fn_to_real_time(void) {
  if(getRegisterDataType(REGISTER_X) != dtTime) {
    return false;
  }

  confirmation_request = 9;
  copySourceRegisterToDestRegister(REGISTER_X, REGISTER_L);
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  return true;
}

bool_t z47_stack_runtime_try_fn_to_real_date(void) {
  if(getRegisterDataType(REGISTER_X) != dtDate) {
    return false;
  }

  confirmation_request = 10;
  copySourceRegisterToDestRegister(REGISTER_X, REGISTER_L);
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  return true;
}

void z47_stack_runtime_adjust_result_set_cpxres(void) {
  setSystemFlag(FLAG_CPXRES);
}

int32_t compareString(const char *left, const char *right, int32_t comparisonType) {
  (void)comparisonType;
  return strcmp(left, right);
}

void z47_registers_retained_allocateNamedVariable(const char *variableName, uint32_t dataType, uint16_t fullDataSizeInBlocks) {
  size_t len;

  if(numberOfNamedVariables != 0) {
    displayBugScreen("unexpected retained allocateNamedVariable grow-allocation parity fallback");
    return;
  }

  len = strlen(variableName);
  if(len > 14) {
    len = 14;
  }

  memset(allNamedVariables[0].variableName, 0, sizeof(allNamedVariables[0].variableName));
  allNamedVariables[0].variableName[0] = (uint8_t)len;
  memcpy(allNamedVariables[0].variableName + 1, variableName, len);
  numberOfNamedVariables = 1;
  setRegisterDataType(FIRST_NAMED_VARIABLE, (uint16_t)dataType, amNone);
  setRegisterDataPointer(FIRST_NAMED_VARIABLE, allocC47Blocks(fullDataSizeInBlocks));
}

void z47_registers_retained_fnDeleteVariable(uint16_t regist) {
  (void)regist;
  displayBugScreen("unexpected retained fnDeleteVariable parity fallback");
}

void z47_register_metadata_request_delete_all_variables_confirmation(void) {
  confirmation_request = 11;
}

void z47_register_metadata_request_clear_all_variables_confirmation(void) {
  confirmation_request = 12;
}

void z47_registers_retained_fnDeleteAllVariables(uint16_t confirmation) {
  (void)confirmation;
  displayBugScreen("unexpected retained fnDeleteAllVariables parity fallback");
}

void z47_registers_retained_fnClearAllVariables(uint16_t confirmation) {
  (void)confirmation;
  displayBugScreen("unexpected retained fnClearAllVariables parity fallback");
}

bool_t z47_stack_runtime_adjust_result_scalar_core(calcRegister_t res) {
  uint32_t result_data_type = getRegisterDataType(res);

  if(result_data_type != dtReal34 && result_data_type != dtTime && result_data_type != dtDate && result_data_type != dtComplex34) {
    return false;
  }

  confirmation_request = fake_adjust_result_no_drop_success ? 15 : 16;
  if(!fake_adjust_result_no_drop_success) {
    lastErrorCode = ERROR_OUT_OF_RANGE;
  }
  return true;
}

bool_t z47_stack_runtime_adjust_result_real_matrix_core(calcRegister_t res) {
  if(getRegisterDataType(res) != dtReal34Matrix) {
    return false;
  }

  confirmation_request = fake_adjust_result_no_drop_success ? 17 : 18;
  if(!fake_adjust_result_no_drop_success) {
    lastErrorCode = ERROR_OUT_OF_RANGE;
  }
  return true;
}

bool_t z47_stack_runtime_adjust_result_complex_matrix_core(calcRegister_t res) {
  if(getRegisterDataType(res) != dtComplex34Matrix) {
    return false;
  }

  confirmation_request = fake_adjust_result_no_drop_success ? 19 : 20;
  if(!fake_adjust_result_no_drop_success) {
    lastErrorCode = ERROR_OUT_OF_RANGE;
  }
  return true;
}

void longIntegerInit(longInteger_t value) {
  value[0] = 0;
}

void uInt32ToLongInteger(uint32_t source, longInteger_t dest) {
  dest[0] = source;
}

void convertLongIntegerToLongIntegerRegister(const longInteger_t value, calcRegister_t dest) {
  reallocateRegister(dest, dtLongInteger, 1, LI_POSITIVE);
  if(getRegisterDataPointer(dest) != NULL) {
    memcpy(getRegisterDataPointer(dest), value, sizeof(uint32_t));
  }
}

void convertLongIntegerToShortIntegerRegister(const longInteger_t value, uint32_t base, calcRegister_t dest) {
  reallocateRegister(dest, dtShortInteger, SHORT_INTEGER_SIZE_IN_BLOCKS, base);
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

void z47_stack_runtime_store_local_register_count_in_x(void) {
  longInteger_t li;

  longIntegerInit(li);
  uInt32ToLongInteger(currentNumberOfLocalRegisters, li);
  convertLongIntegerToLongIntegerRegister(li, REGISTER_X);
}

uint8_t z47_stack_runtime_current_local_register_count(void) {
  return currentNumberOfLocalRegisters;
}

uint8_t z47_stack_runtime_get_input_default(void) {
  return Input_Default;
}

void z47_stack_runtime_store_zero_long_integer(calcRegister_t reg) {
  longInteger_t li;

  longIntegerInit(li);
  uInt32ToLongInteger(0u, li);
  convertLongIntegerToLongIntegerRegister(li, reg);
}

void z47_stack_runtime_store_zero_short_integer(calcRegister_t reg, uint32_t base) {
  longInteger_t li;

  longIntegerInit(li);
  uInt32ToLongInteger(0u, li);
  convertLongIntegerToShortIntegerRegister(li, base, reg);
}

void z47_stack_runtime_request_clear_registers_confirmation(void) {
  confirmation_request = 1;
}

void z47_stack_runtime_report_register_command_error(uint8_t error_code) {
  displayCalcErrorMessage(error_code, REGISTER_X, REGISTER_X);
}

uint8_t z47_registers_retained_get_reg_clr_range(uint16_t *s, uint16_t *n) {
  *s = fake_regclr_start;
  *n = fake_regclr_count;
  return fake_regclr_error_code;
}

uint8_t z47_registers_retained_get_reg_swap_range(uint16_t *s, uint16_t *n, uint16_t *d) {
  *s = fake_regswap_start;
  *n = fake_regswap_count;
  *d = fake_regswap_dest;
  return fake_regswap_error_code;
}

uint8_t z47_registers_retained_get_reg_copy_params(bool_t *f, uint16_t *s, uint16_t *n, uint16_t *d) {
  *f = fake_regcopy_f;
  *s = fake_regcopy_start;
  *n = fake_regcopy_count;
  *d = fake_regcopy_dest;
  return fake_regcopy_error_code;
}

void z47_registers_retained_fnRegCopy(uint16_t unusedButMandatoryParameter) {
  (void)unusedButMandatoryParameter;

  confirmation_request = 2;

  if(fake_regcopy_start > fake_regcopy_dest) {
    for(uint16_t i = 0; i < fake_regcopy_count; ++i) {
      copySourceRegisterToDestRegister((calcRegister_t)(fake_regcopy_start + i), (calcRegister_t)(fake_regcopy_dest + i));
    }
    return;
  }

  if(fake_regcopy_start < fake_regcopy_dest) {
    for(uint16_t i = fake_regcopy_count; i > 0; --i) {
      copySourceRegisterToDestRegister((calcRegister_t)(fake_regcopy_start + i - 1), (calcRegister_t)(fake_regcopy_dest + i - 1));
    }
  }
}

void z47_registers_retained_fnToReal(uint16_t unusedButMandatoryParameter) {
  (void)unusedButMandatoryParameter;

  confirmation_request = 5;
  copySourceRegisterToDestRegister(REGISTER_X, REGISTER_L);
}

void z47_registers_retained_sort_reg(uint16_t range_start, uint16_t range_end) {
  confirmation_request = 3;

  for(uint16_t i = range_start; i < range_end; ++i) {
    for(uint16_t j = (uint16_t)(i + 1); j <= range_end; ++j) {
      registerHeader_t saved_register_header;
      registerHeader_t *left = mutableRegisterHeader((calcRegister_t)i);
      registerHeader_t *right = mutableRegisterHeader((calcRegister_t)j);

      if(left == NULL || right == NULL) {
        continue;
      }

      if((left->dataType > right->dataType) || ((left->dataType == right->dataType) && (left->descriptor > right->descriptor))) {
        saved_register_header = *left;
        *left = *right;
        *right = saved_register_header;
      }
    }
  }
}

void stackParitySetRegClrRange(uint8_t error_code, uint16_t s, uint16_t n) {
  fake_regclr_error_code = error_code;
  fake_regclr_start = s;
  fake_regclr_count = n;
}

void stackParitySetRegSwapRange(uint8_t error_code, uint16_t s, uint16_t n, uint16_t d) {
  fake_regswap_error_code = error_code;
  fake_regswap_start = s;
  fake_regswap_count = n;
  fake_regswap_dest = d;
}

void stackParitySetRegCopyParams(uint8_t error_code, bool_t f, uint16_t s, uint16_t n, uint16_t d) {
  fake_regcopy_error_code = error_code;
  fake_regcopy_f = f;
  fake_regcopy_start = s;
  fake_regcopy_count = n;
  fake_regcopy_dest = d;
}

void stackParitySetAdjustResultNoDropOutcome(bool_t success) {
  fake_adjust_result_no_drop_success = success;
}

void z47_stack_runtime_restore_saved_sigma_last_xy_and_add(void) {
  convertRealToResultRegister(&SAVED_SIGMA_LASTX, REGISTER_X, amNone);
  convertRealToResultRegister(&SAVED_SIGMA_LASTY, REGISTER_Y, amNone);
  fnSigmaAddRem(SIGMA_PLUS);
}

void z47_stack_runtime_save_for_undo(void) {
  calcRegister_t regist;

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

  for(regist = getStackTop(); regist >= REGISTER_X; regist--) {
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
  for(regist = getStackTop(); regist >= REGISTER_X; regist--) {
    clearRegister(SAVED_REGISTER_X - REGISTER_X + regist);
  }
  clearRegister(SAVED_REGISTER_L);
  thereIsSomethingToUndo = false;
  lastErrorCode = ERROR_RAM_FULL;
}

void z47_stack_runtime_undo(void) {
  bool_t wasSolving = getSystemFlag(FLAG_SOLVING);
  bool_t wasInting = getSystemFlag(FLAG_INTING);
  uint8_t lastErrorCodeMeM = lastErrorCode;
  calcRegister_t regist;

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

  for(regist = getStackTop(); regist >= REGISTER_X; regist--) {
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

void stackParitySeedNamedVariableName(int index, const char *name) {
  size_t len;

  if(index < 0 || index >= MAX_FAKE_NAMED_VARIABLES || name == NULL) {
    return;
  }

  len = strlen(name);
  if(len > 14) {
    len = 14;
  }

  memset(allNamedVariables[index].variableName, 0, sizeof(allNamedVariables[index].variableName));
  allNamedVariables[index].variableName[0] = (uint8_t)len;
  memcpy(allNamedVariables[index].variableName + 1, name, len);

  if(numberOfNamedVariables < (uint16_t)(index + 1)) {
    numberOfNamedVariables = (uint16_t)(index + 1);
  }
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
  snapshot->confirmationRequest = confirmation_request;
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
