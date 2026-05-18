// SPDX-License-Identifier: GPL-3.0-only

#include <stdio.h>
#include <string.h>

#include "c47.h"

uint32_t getRegisterDataType(calcRegister_t reg);
void *getRegisterDataPointer(calcRegister_t reg);
uint32_t getRegisterTag(calcRegister_t reg);
void setRegisterMaxDataLengthInBlocks(calcRegister_t reg, uint16_t max_data_len);
uint16_t getRegisterMaxDataLengthInBlocks(calcRegister_t reg);
uint16_t getRegisterFullSizeInBlocks(calcRegister_t reg);
void reallocateRegister(calcRegister_t reg, uint32_t data_type, uint16_t data_size_without_data_len_blocks, uint32_t tag);
void copySourceRegisterToDestRegister(calcRegister_t sourceRegister, calcRegister_t destRegister);
bool_t isFunctionAllowingNewVariable(uint16_t op);
bool_t validateName(const char *name);
bool_t isUniqueMenuName(const char *name);
void allocateNamedVariable(const char *variableName, uint32_t dataType, uint16_t fullDataSizeInBlocks);
void setRegisterDataType(calcRegister_t reg, uint16_t data_type, uint32_t tag);
void setRegisterDataPointer(calcRegister_t reg, const void *mem_ptr);
void setRegisterTag(calcRegister_t reg, uint32_t tag);

uint32_t oracle_getRegisterDataType(calcRegister_t reg);
void *oracle_getRegisterDataPointer(calcRegister_t reg);
uint32_t oracle_getRegisterTag(calcRegister_t reg);
void oracle_setRegisterMaxDataLengthInBlocks(calcRegister_t reg, uint16_t max_data_len);
uint16_t oracle_getRegisterMaxDataLengthInBlocks(calcRegister_t reg);
uint16_t oracle_getRegisterFullSizeInBlocks(calcRegister_t reg);
void oracle_reallocateRegister(calcRegister_t reg, uint32_t data_type, uint16_t data_size_without_data_len_blocks, uint32_t tag);
void oracle_copySourceRegisterToDestRegister(calcRegister_t sourceRegister, calcRegister_t destRegister);
bool_t oracle_isFunctionAllowingNewVariable(uint16_t op);
bool_t oracle_validateName(const char *name);
bool_t oracle_isUniqueMenuName(const char *name);
void oracle_allocateNamedVariable(const char *variableName, uint32_t dataType, uint16_t fullDataSizeInBlocks);
void oracle_setRegisterDataType(calcRegister_t reg, uint16_t data_type, uint32_t tag);
void oracle_setRegisterDataPointer(calcRegister_t reg, const void *mem_ptr);
void oracle_setRegisterTag(calcRegister_t reg, uint32_t tag);

typedef uint32_t (*get_u32_fn)(calcRegister_t);
typedef uint16_t (*get_u16_fn)(calcRegister_t);
typedef void *(*get_ptr_fn)(calcRegister_t);
typedef void (*copy_fn)(calcRegister_t, calcRegister_t);
typedef void (*reallocate_fn)(calcRegister_t, uint32_t, uint16_t, uint32_t);
typedef void (*set_max_len_fn)(calcRegister_t, uint16_t);
typedef void (*set_type_fn)(calcRegister_t, uint16_t, uint32_t);
typedef void (*set_ptr_fn)(calcRegister_t, const void *);
typedef void (*set_tag_fn)(calcRegister_t, uint32_t);
typedef bool_t (*bool_u16_fn)(uint16_t);
typedef bool_t (*bool_str_fn)(const char *);
typedef void (*allocate_named_variable_fn)(const char *, uint32_t, uint16_t);

enum {
  LOCAL_PAYLOAD_BYTES = 128,
};

static const char validate_name_ascii_valid[] = "Abc1";
static const char validate_name_empty[] = "";
static const char validate_name_digit_first[] = "1abc";
static const char validate_name_accented_first[] = "\x80\xc0" "bc";
static const char validate_name_superscript_first[] = "\xa4\x82" "1";
static const char validate_name_plus_after_first[] = "A+";
static const char validate_name_cross_after_first[] = "A" "\x80\xd7";
static const char validate_name_too_long[] = "ABCDEFGH";
static const char allocate_named_variable_empty[] = "";
static const char allocate_named_variable_too_long[] = "ABCDEFGH";
static const char allocate_named_variable_reserved_acc[] = "ACC";
static const char allocate_named_variable_reserved_adm[] = "ADM";

static void seedRegisterBuffer(calcRegister_t reg, uint32_t data_type, uint32_t tag, const uint8_t *payload, uint16_t size_in_blocks) {
  stackParitySeedRegister(reg, data_type, tag, payload, size_in_blocks);
}

static void seedNamedBuffer(int index, uint32_t data_type, uint32_t tag, const uint8_t *payload, uint16_t size_in_blocks) {
  stackParitySeedNamedVariable(index, data_type, tag, payload, size_in_blocks);
}

static void seedLocalBuffer(int index, uint32_t data_type, uint32_t tag, const uint8_t *payload, uint16_t size_in_blocks) {
  stackParitySeedLocalRegister(index, data_type, tag, payload, size_in_blocks);
}

static void fillPayload(uint8_t *buffer, uint16_t size_in_blocks, uint8_t seed) {
  uint32_t i;

  for(i = 0; i < TO_BYTES(size_in_blocks); i++) {
    buffer[i] = (uint8_t)(seed + i);
  }
}

static void seedRegisterPayload(calcRegister_t reg, uint32_t data_type, uint32_t tag, uint16_t size_in_blocks, uint8_t seed) {
  uint8_t payload[STACK_PARITY_REGISTER_CAPTURE_BYTES];

  memset(payload, 0, sizeof(payload));
  fillPayload(payload, size_in_blocks, seed);
  stackParitySeedRegister(reg, data_type, tag, payload, size_in_blocks);
}

static void seedNamedPayload(int index, uint32_t data_type, uint32_t tag, uint16_t size_in_blocks, uint8_t seed) {
  uint8_t payload[STACK_PARITY_REGISTER_CAPTURE_BYTES];

  memset(payload, 0, sizeof(payload));
  fillPayload(payload, size_in_blocks, seed);
  stackParitySeedNamedVariable(index, data_type, tag, payload, size_in_blocks);
}

static void seedLocalPayload(int index, uint32_t data_type, uint32_t tag, uint16_t size_in_blocks, uint8_t seed) {
  uint8_t payload[STACK_PARITY_REGISTER_CAPTURE_BYTES];

  memset(payload, 0, sizeof(payload));
  fillPayload(payload, size_in_blocks, seed);
  stackParitySeedLocalRegister(index, data_type, tag, payload, size_in_blocks);
}

static void buildStringLikePayload(uint8_t *payload, uint16_t size_in_blocks, uint16_t data_max_length_in_blocks, uint8_t seed) {
  strLgIntHeader_t *header = (strLgIntHeader_t *)payload;

  memset(payload, 0, LOCAL_PAYLOAD_BYTES);
  fillPayload(payload, size_in_blocks, seed);
  header->dataMaxLengthInBlocks = data_max_length_in_blocks;
  header->unused = 0;
}

static void seedRegisterStringLike(calcRegister_t reg, uint32_t data_type, uint32_t tag, uint16_t data_max_length_in_blocks, uint8_t seed) {
  uint16_t size_in_blocks = (uint16_t)(TO_BLOCKS(sizeof(strLgIntHeader_t)) + data_max_length_in_blocks);
  uint8_t payload[LOCAL_PAYLOAD_BYTES];

  buildStringLikePayload(payload, size_in_blocks, data_max_length_in_blocks, seed);
  seedRegisterBuffer(reg, data_type, tag, payload, size_in_blocks);
}

static void seedNamedStringLike(int index, uint32_t data_type, uint32_t tag, uint16_t data_max_length_in_blocks, uint8_t seed) {
  uint16_t size_in_blocks = (uint16_t)(TO_BLOCKS(sizeof(strLgIntHeader_t)) + data_max_length_in_blocks);
  uint8_t payload[LOCAL_PAYLOAD_BYTES];

  buildStringLikePayload(payload, size_in_blocks, data_max_length_in_blocks, seed);
  seedNamedBuffer(index, data_type, tag, payload, size_in_blocks);
}

static void seedLocalStringLike(int index, uint32_t data_type, uint32_t tag, uint16_t data_max_length_in_blocks, uint8_t seed) {
  uint16_t size_in_blocks = (uint16_t)(TO_BLOCKS(sizeof(strLgIntHeader_t)) + data_max_length_in_blocks);
  uint8_t payload[LOCAL_PAYLOAD_BYTES];

  buildStringLikePayload(payload, size_in_blocks, data_max_length_in_blocks, seed);
  seedLocalBuffer(index, data_type, tag, payload, size_in_blocks);
}

static void buildMatrixPayload(uint8_t *payload, uint16_t size_in_blocks, uint16_t rows, uint16_t columns, uint32_t tag, uint8_t seed) {
  matrixHeader_t *header = (matrixHeader_t *)payload;

  memset(payload, 0, LOCAL_PAYLOAD_BYTES);
  fillPayload(payload, size_in_blocks, seed);
  header->matrixRows = rows;
  header->matrixColumns = columns;
  header->mtag = tag;
  header->notUsed = 0;
}

static void seedRegisterMatrix(calcRegister_t reg, uint32_t data_type, uint32_t tag, uint16_t rows, uint16_t columns, uint16_t element_size_in_blocks, uint8_t seed) {
  uint16_t size_in_blocks = (uint16_t)(TO_BLOCKS(sizeof(matrixHeader_t)) + rows * columns * element_size_in_blocks);
  uint8_t payload[LOCAL_PAYLOAD_BYTES];

  buildMatrixPayload(payload, size_in_blocks, rows, columns, tag, seed);
  seedRegisterBuffer(reg, data_type, tag, payload, size_in_blocks);
}

static void seedReservedStringLike(uint16_t size_in_blocks, uint16_t data_max_length_in_blocks, uint8_t seed) {
  uint8_t payload[LOCAL_PAYLOAD_BYTES];
  void *ptr;

  buildStringLikePayload(payload, size_in_blocks, data_max_length_in_blocks, seed);
  ptr = allocC47Blocks(size_in_blocks);
  if(ptr != NULL) {
    memcpy(ptr, payload, TO_BYTES(size_in_blocks));
  }
}

static void seedReservedBacking(void) {
  uint8_t acc_payload[REAL34_SIZE_IN_BYTES];
  void *acc_ptr;

  fillPayload(acc_payload, REAL34_SIZE_IN_BLOCKS, 0xa0);
  acc_ptr = allocC47Blocks(REAL34_SIZE_IN_BLOCKS);
  if(acc_ptr != NULL) {
    memcpy(acc_ptr, acc_payload, sizeof(acc_payload));
  }

  seedReservedStringLike(4, 3, 0xb0);
}

static void setupGlobalCase(void) {
  seedRegisterPayload(REGISTER_X, dtLongInteger, LI_POSITIVE, 1, 0x10);
}

static void setupNamedCase(void) {
  seedNamedPayload(2, dtReal34, amNone, REAL34_SIZE_IN_BLOCKS, 0x20);
}

static void setupReservedLetteredCase(void) {
  seedRegisterPayload(REGISTER_X, dtLongInteger, LI_POSITIVE, 1, 0x30);
}

static void setupReservedDataCase(void) {
  seedReservedBacking();
}

static void setupLocalCase(void) {
  seedLocalPayload(1, dtLongInteger, LI_POSITIVE, 1, 0x40);
}

static void setupReservedWriteCase(void) {
  seedReservedBacking();
  seedNamedPayload(40, dtLongInteger, LI_POSITIVE, 1, 0x50);
}

static void setupGlobalLongIntegerCase(void) {
  seedRegisterStringLike(REGISTER_X, dtLongInteger, LI_POSITIVE, 3, 0x60);
}

static void setupGlobalRealMatrixCase(void) {
  seedRegisterMatrix(REGISTER_X, dtReal34Matrix, amNone, 2, 3, REAL34_SIZE_IN_BLOCKS, 0x70);
}

static void setupGlobalComplexMatrixCase(void) {
  seedRegisterMatrix(REGISTER_X, dtComplex34Matrix, amNone, 2, 2, COMPLEX34_SIZE_IN_BLOCKS, 0x80);
}

static void setupNamedStringCase(void) {
  seedNamedStringLike(2, dtString, amNone, 4, 0x90);
}

static void setupLocalLongIntegerCase(void) {
  seedLocalStringLike(1, dtLongInteger, LI_POSITIVE, 5, 0xa0);
}

static void setupReservedLongIntegerCase(void) {
  seedReservedBacking();
}

static void setupGlobalReal34Case(void) {
  seedRegisterPayload(REGISTER_X, dtReal34, amNone, REAL34_SIZE_IN_BLOCKS, 0xb0);
}

static void setupGlobalComplex34Case(void) {
  seedRegisterPayload(REGISTER_X, dtComplex34, amNone, COMPLEX34_SIZE_IN_BLOCKS, 0xc0);
}

static void setupGlobalShortIntegerCase(void) {
  seedRegisterPayload(REGISTER_X, dtShortInteger, 0, SHORT_INTEGER_SIZE_IN_BLOCKS, 0xd0);
}

static void setupCopyGlobalLongIntegerCase(void) {
  seedRegisterStringLike(REGISTER_X, dtLongInteger, LI_POSITIVE, 3, 0xe0);
  seedRegisterPayload(REGISTER_Y, dtReal34, amNone, REAL34_SIZE_IN_BLOCKS, 0xe8);
}

static void setupCopyNamedStringCase(void) {
  seedNamedStringLike(2, dtString, amNone, 4, 0xf0);
  seedRegisterPayload(REGISTER_Y, dtReal34, amNone, REAL34_SIZE_IN_BLOCKS, 0xf8);
}

static void setupCopyLocalLongIntegerCase(void) {
  seedLocalStringLike(1, dtLongInteger, LI_POSITIVE, 5, 0x18);
  seedRegisterPayload(REGISTER_Y, dtReal34, amNone, REAL34_SIZE_IN_BLOCKS, 0x20);
}

static void setupCopyReservedLetteredSourceCase(void) {
  seedRegisterStringLike(REGISTER_X, dtLongInteger, LI_POSITIVE, 3, 0x28);
  seedRegisterPayload(REGISTER_Y, dtReal34, amNone, REAL34_SIZE_IN_BLOCKS, 0x30);
}

static void setupCopyReservedLetteredDestCase(void) {
  seedRegisterStringLike(REGISTER_Y, dtLongInteger, LI_POSITIVE, 4, 0x38);
  seedRegisterPayload(REGISTER_X, dtReal34, amNone, REAL34_SIZE_IN_BLOCKS, 0x40);
}

static void setupCopyReservedDataCase(void) {
  seedReservedBacking();
  seedRegisterPayload(REGISTER_Y, dtReal34, amNone, REAL34_SIZE_IN_BLOCKS, 0x48);
}

static void setupCopyMatrixCase(void) {
  seedRegisterMatrix(REGISTER_X, dtReal34Matrix, amNone, 2, 3, REAL34_SIZE_IN_BLOCKS, 0x50);
  seedRegisterPayload(REGISTER_Y, dtReal34, amNone, REAL34_SIZE_IN_BLOCKS, 0x58);
}

static void setupReallocateGlobalLongIntegerCase(void) {
  seedRegisterPayload(REGISTER_X, dtReal34, amNone, REAL34_SIZE_IN_BLOCKS, 0x68);
}

static void setupReallocateNamedStringCase(void) {
  seedNamedPayload(2, dtReal34, amNone, REAL34_SIZE_IN_BLOCKS, 0x70);
}

static void setupReallocateLocalMatrixCase(void) {
  seedLocalPayload(1, dtReal34, amNone, REAL34_SIZE_IN_BLOCKS, 0x78);
}

static void setupReallocateComplexPolarCase(void) {
  seedRegisterPayload(REGISTER_X, dtReal34, amNone, REAL34_SIZE_IN_BLOCKS, 0x80);
  currentAngularMode = 2;
  setSystemFlag(FLAG_POLAR);
}

static void setupReallocateMemoryFullCase(void) {
  seedRegisterPayload(REGISTER_X, dtReal34, amNone, REAL34_SIZE_IN_BLOCKS, 0x88);
  stackParitySetMemoryBlockAvailable(false);
}

static void setupUniqueMenuBuiltInCollisionCase(void) {
  stackParitySeedBuiltInMenuItem(0, CAT_MENU, "HOME");
}

static void setupUniqueMenuBuiltInNonMenuCase(void) {
  stackParitySeedBuiltInMenuItem(0, 0, "HOME");
}

static void setupUniqueMenuUserCollisionCase(void) {
  stackParitySeedUserMenu(0, "TOOLS");
}

static void setupUniqueMenuMissCase(void) {
  stackParitySeedBuiltInMenuItem(0, CAT_MENU, "HOME");
  stackParitySeedUserMenu(0, "TOOLS");
}

static void setupNoOpCase(void) {
}

static void reportSnapshotMismatch(const char *name, calcRegister_t reg, int *failures) {
  fprintf(stderr, "%s(%d) state mismatch\n", name, reg);
  (*failures)++;
}

static int runGetU32Case(const char *name, get_u32_fn oracle_fn, get_u32_fn zig_fn, void (*setup)(void), calcRegister_t reg) {
  stack_parity_snapshot_t expected_snapshot;
  stack_parity_snapshot_t actual_snapshot;
  uint32_t expected;
  uint32_t actual;
  int failures = 0;

  stackParityReset();
  setup();
  expected = oracle_fn(reg);
  stackParityCapture(&expected_snapshot);

  stackParityReset();
  setup();
  actual = zig_fn(reg);
  stackParityCapture(&actual_snapshot);

  if(expected != actual) {
    fprintf(stderr, "%s(%d) result mismatch: expected %#x actual %#x\n", name, reg, expected, actual);
    failures++;
  }
  if(memcmp(&expected_snapshot, &actual_snapshot, sizeof(expected_snapshot)) != 0) {
    reportSnapshotMismatch(name, reg, &failures);
  }

  return failures;
}

static int runGetU16Case(const char *name, get_u16_fn oracle_fn, get_u16_fn zig_fn, void (*setup)(void), calcRegister_t reg) {
  stack_parity_snapshot_t expected_snapshot;
  stack_parity_snapshot_t actual_snapshot;
  uint16_t expected;
  uint16_t actual;
  int failures = 0;

  stackParityReset();
  setup();
  expected = oracle_fn(reg);
  stackParityCapture(&expected_snapshot);

  stackParityReset();
  setup();
  actual = zig_fn(reg);
  stackParityCapture(&actual_snapshot);

  if(expected != actual) {
    fprintf(stderr, "%s(%d) result mismatch: expected %u actual %u\n", name, reg, expected, actual);
    failures++;
  }
  if(memcmp(&expected_snapshot, &actual_snapshot, sizeof(expected_snapshot)) != 0) {
    reportSnapshotMismatch(name, reg, &failures);
  }

  return failures;
}

static int runGetPointerCase(const char *name, get_ptr_fn oracle_fn, get_ptr_fn zig_fn, void (*setup)(void), calcRegister_t reg) {
  stack_parity_snapshot_t expected_snapshot;
  stack_parity_snapshot_t actual_snapshot;
  uint16_t expected;
  uint16_t actual;
  int failures = 0;

  stackParityReset();
  setup();
  expected = TO_C47MEMPTR(oracle_fn(reg));
  stackParityCapture(&expected_snapshot);

  stackParityReset();
  setup();
  actual = TO_C47MEMPTR(zig_fn(reg));
  stackParityCapture(&actual_snapshot);

  if(expected != actual) {
    fprintf(stderr, "%s(%d) pointer mismatch: expected %u actual %u\n", name, reg, expected, actual);
    failures++;
  }
  if(memcmp(&expected_snapshot, &actual_snapshot, sizeof(expected_snapshot)) != 0) {
    reportSnapshotMismatch(name, reg, &failures);
  }

  return failures;
}

static int runSetTypeCase(const char *name, set_type_fn oracle_fn, set_type_fn zig_fn, void (*setup)(void), calcRegister_t reg, uint16_t data_type, uint32_t tag) {
  stack_parity_snapshot_t expected_snapshot;
  stack_parity_snapshot_t actual_snapshot;
  int failures = 0;

  stackParityReset();
  setup();
  oracle_fn(reg, data_type, tag);
  stackParityCapture(&expected_snapshot);

  stackParityReset();
  setup();
  zig_fn(reg, data_type, tag);
  stackParityCapture(&actual_snapshot);

  if(memcmp(&expected_snapshot, &actual_snapshot, sizeof(expected_snapshot)) != 0) {
    reportSnapshotMismatch(name, reg, &failures);
  }

  return failures;
}

static int runSetPointerCase(const char *name, set_ptr_fn oracle_fn, set_ptr_fn zig_fn, void (*setup)(void), calcRegister_t reg, uint16_t size_in_blocks, uint8_t seed) {
  stack_parity_snapshot_t expected_snapshot;
  stack_parity_snapshot_t actual_snapshot;
  uint8_t payload[STACK_PARITY_REGISTER_CAPTURE_BYTES];
  void *expected_ptr;
  void *actual_ptr;
  int failures = 0;

  memset(payload, 0, sizeof(payload));
  fillPayload(payload, size_in_blocks, seed);

  stackParityReset();
  setup();
  expected_ptr = allocC47Blocks(size_in_blocks);
  if(expected_ptr != NULL) {
    memcpy(expected_ptr, payload, TO_BYTES(size_in_blocks));
  }
  oracle_fn(reg, expected_ptr);
  stackParityCapture(&expected_snapshot);

  stackParityReset();
  setup();
  actual_ptr = allocC47Blocks(size_in_blocks);
  if(actual_ptr != NULL) {
    memcpy(actual_ptr, payload, TO_BYTES(size_in_blocks));
  }
  zig_fn(reg, actual_ptr);
  stackParityCapture(&actual_snapshot);

  if(memcmp(&expected_snapshot, &actual_snapshot, sizeof(expected_snapshot)) != 0) {
    reportSnapshotMismatch(name, reg, &failures);
  }

  return failures;
}

static int runSetTagCase(const char *name, set_tag_fn oracle_fn, set_tag_fn zig_fn, void (*setup)(void), calcRegister_t reg, uint32_t tag) {
  stack_parity_snapshot_t expected_snapshot;
  stack_parity_snapshot_t actual_snapshot;
  int failures = 0;

  stackParityReset();
  setup();
  oracle_fn(reg, tag);
  stackParityCapture(&expected_snapshot);

  stackParityReset();
  setup();
  zig_fn(reg, tag);
  stackParityCapture(&actual_snapshot);

  if(memcmp(&expected_snapshot, &actual_snapshot, sizeof(expected_snapshot)) != 0) {
    reportSnapshotMismatch(name, reg, &failures);
  }

  return failures;
}

static int runSetMaxLengthCase(const char *name, set_max_len_fn oracle_fn, set_max_len_fn zig_fn, void (*setup)(void), calcRegister_t reg, uint16_t max_data_len) {
  stack_parity_snapshot_t expected_snapshot;
  stack_parity_snapshot_t actual_snapshot;
  int failures = 0;

  stackParityReset();
  setup();
  oracle_fn(reg, max_data_len);
  stackParityCapture(&expected_snapshot);

  stackParityReset();
  setup();
  zig_fn(reg, max_data_len);
  stackParityCapture(&actual_snapshot);

  if(memcmp(&expected_snapshot, &actual_snapshot, sizeof(expected_snapshot)) != 0) {
    reportSnapshotMismatch(name, reg, &failures);
  }

  return failures;
}

static int runCopyCase(const char *name, copy_fn oracle_fn, copy_fn zig_fn, void (*setup)(void), calcRegister_t source_reg, calcRegister_t dest_reg) {
  stack_parity_snapshot_t expected_snapshot;
  stack_parity_snapshot_t actual_snapshot;
  int failures = 0;

  stackParityReset();
  setup();
  oracle_fn(source_reg, dest_reg);
  stackParityCapture(&expected_snapshot);

  stackParityReset();
  setup();
  zig_fn(source_reg, dest_reg);
  stackParityCapture(&actual_snapshot);

  if(memcmp(&expected_snapshot, &actual_snapshot, sizeof(expected_snapshot)) != 0) {
    reportSnapshotMismatch(name, dest_reg, &failures);
  }

  return failures;
}

static int runReallocateCase(const char *name, reallocate_fn oracle_fn, reallocate_fn zig_fn, void (*setup)(void), calcRegister_t reg, uint32_t data_type, uint16_t data_size_without_data_len_blocks, uint32_t tag) {
  stack_parity_snapshot_t expected_snapshot;
  stack_parity_snapshot_t actual_snapshot;
  int failures = 0;

  stackParityReset();
  setup();
  oracle_fn(reg, data_type, data_size_without_data_len_blocks, tag);
  stackParityCapture(&expected_snapshot);

  stackParityReset();
  setup();
  zig_fn(reg, data_type, data_size_without_data_len_blocks, tag);
  stackParityCapture(&actual_snapshot);

  if(memcmp(&expected_snapshot, &actual_snapshot, sizeof(expected_snapshot)) != 0) {
    reportSnapshotMismatch(name, reg, &failures);
  }

  return failures;
}

static int runBoolU16Case(const char *name, bool_u16_fn oracle_fn, bool_u16_fn zig_fn, void (*setup)(void), uint16_t arg) {
  stack_parity_snapshot_t expected_snapshot;
  stack_parity_snapshot_t actual_snapshot;
  bool_t expected;
  bool_t actual;
  int failures = 0;

  stackParityReset();
  setup();
  expected = oracle_fn(arg);
  stackParityCapture(&expected_snapshot);

  stackParityReset();
  setup();
  actual = zig_fn(arg);
  stackParityCapture(&actual_snapshot);

  if(expected != actual) {
    fprintf(stderr, "%s(%u) result mismatch: expected %u actual %u\n", name, arg, expected, actual);
    failures++;
  }
  if(memcmp(&expected_snapshot, &actual_snapshot, sizeof(expected_snapshot)) != 0) {
    reportSnapshotMismatch(name, (calcRegister_t)arg, &failures);
  }

  return failures;
}

static int runBoolStringCase(const char *name, const char *case_name, bool_str_fn oracle_fn, bool_str_fn zig_fn, void (*setup)(void), const char *arg) {
  stack_parity_snapshot_t expected_snapshot;
  stack_parity_snapshot_t actual_snapshot;
  bool_t expected;
  bool_t actual;
  int failures = 0;

  stackParityReset();
  setup();
  expected = oracle_fn(arg);
  stackParityCapture(&expected_snapshot);

  stackParityReset();
  setup();
  actual = zig_fn(arg);
  stackParityCapture(&actual_snapshot);

  if(expected != actual) {
    fprintf(stderr, "%s(%s) result mismatch: expected %u actual %u\n", name, case_name, expected, actual);
    failures++;
  }
  if(memcmp(&expected_snapshot, &actual_snapshot, sizeof(expected_snapshot)) != 0) {
    fprintf(stderr, "%s(%s) state mismatch\n", name, case_name);
    failures++;
  }

  return failures;
}

static int runAllocateNamedVariableCase(const char *name, const char *case_name, allocate_named_variable_fn oracle_fn, allocate_named_variable_fn zig_fn, void (*setup)(void), const char *variable_name, uint32_t data_type, uint16_t full_data_size_in_blocks) {
  stack_parity_snapshot_t expected_snapshot;
  stack_parity_snapshot_t actual_snapshot;
  int failures = 0;

  stackParityReset();
  setup();
  oracle_fn(variable_name, data_type, full_data_size_in_blocks);
  stackParityCapture(&expected_snapshot);

  stackParityReset();
  setup();
  zig_fn(variable_name, data_type, full_data_size_in_blocks);
  stackParityCapture(&actual_snapshot);

  if(memcmp(&expected_snapshot, &actual_snapshot, sizeof(expected_snapshot)) != 0) {
    fprintf(stderr, "%s(%s) state mismatch\n", name, case_name);
    failures++;
  }

  return failures;
}

int main(void) {
  int failures = 0;

  failures += runBoolU16Case("isFunctionAllowingNewVariable", oracle_isFunctionAllowingNewVariable, isFunctionAllowingNewVariable, setupNoOpCase, ITM_STOADD);
  failures += runBoolU16Case("isFunctionAllowingNewVariable", oracle_isFunctionAllowingNewVariable, isFunctionAllowingNewVariable, setupNoOpCase, ITM_RCL);
  failures += runAllocateNamedVariableCase("allocateNamedVariable", "empty", oracle_allocateNamedVariable, allocateNamedVariable, setupNoOpCase, allocate_named_variable_empty, dtReal34, REAL34_SIZE_IN_BLOCKS);
  failures += runAllocateNamedVariableCase("allocateNamedVariable", "too-long", oracle_allocateNamedVariable, allocateNamedVariable, setupNoOpCase, allocate_named_variable_too_long, dtReal34, REAL34_SIZE_IN_BLOCKS);
  failures += runAllocateNamedVariableCase("allocateNamedVariable", "reserved-acc", oracle_allocateNamedVariable, allocateNamedVariable, setupNoOpCase, allocate_named_variable_reserved_acc, dtReal34, REAL34_SIZE_IN_BLOCKS);
  failures += runAllocateNamedVariableCase("allocateNamedVariable", "reserved-adm", oracle_allocateNamedVariable, allocateNamedVariable, setupNoOpCase, allocate_named_variable_reserved_adm, dtReal34, REAL34_SIZE_IN_BLOCKS);
  failures += runBoolStringCase("isUniqueMenuName", "builtin-menu-hit", oracle_isUniqueMenuName, isUniqueMenuName, setupUniqueMenuBuiltInCollisionCase, "HOME");
  failures += runBoolStringCase("isUniqueMenuName", "builtin-nonmenu-ignored", oracle_isUniqueMenuName, isUniqueMenuName, setupUniqueMenuBuiltInNonMenuCase, "HOME");
  failures += runBoolStringCase("isUniqueMenuName", "user-menu-hit", oracle_isUniqueMenuName, isUniqueMenuName, setupUniqueMenuUserCollisionCase, "TOOLS");
  failures += runBoolStringCase("isUniqueMenuName", "miss", oracle_isUniqueMenuName, isUniqueMenuName, setupUniqueMenuMissCase, "GRAPHS");
  failures += runBoolStringCase("validateName", "ascii-valid", oracle_validateName, validateName, setupNoOpCase, validate_name_ascii_valid);
  failures += runBoolStringCase("validateName", "empty", oracle_validateName, validateName, setupNoOpCase, validate_name_empty);
  failures += runBoolStringCase("validateName", "digit-first", oracle_validateName, validateName, setupNoOpCase, validate_name_digit_first);
  failures += runBoolStringCase("validateName", "accented-first", oracle_validateName, validateName, setupNoOpCase, validate_name_accented_first);
  failures += runBoolStringCase("validateName", "superscript-first", oracle_validateName, validateName, setupNoOpCase, validate_name_superscript_first);
  failures += runBoolStringCase("validateName", "plus-after-first", oracle_validateName, validateName, setupNoOpCase, validate_name_plus_after_first);
  failures += runBoolStringCase("validateName", "cross-after-first", oracle_validateName, validateName, setupNoOpCase, validate_name_cross_after_first);
  failures += runBoolStringCase("validateName", "too-long", oracle_validateName, validateName, setupNoOpCase, validate_name_too_long);

  failures += runGetU32Case("getRegisterDataType", oracle_getRegisterDataType, getRegisterDataType, setupGlobalCase, REGISTER_X);
  failures += runGetU32Case("getRegisterDataType", oracle_getRegisterDataType, getRegisterDataType, setupNamedCase, FIRST_NAMED_VARIABLE + 2);
  failures += runGetU32Case("getRegisterDataType", oracle_getRegisterDataType, getRegisterDataType, setupReservedLetteredCase, FIRST_RESERVED_VARIABLE);
  failures += runGetU32Case("getRegisterDataType", oracle_getRegisterDataType, getRegisterDataType, setupReservedDataCase, FIRST_RESERVED_VARIABLE + 40);
  failures += runGetU32Case("getRegisterDataType", oracle_getRegisterDataType, getRegisterDataType, setupLocalCase, FIRST_LOCAL_REGISTER + 1);

  failures += runGetPointerCase("getRegisterDataPointer", oracle_getRegisterDataPointer, getRegisterDataPointer, setupNamedCase, FIRST_NAMED_VARIABLE + 2);
  failures += runGetPointerCase("getRegisterDataPointer", oracle_getRegisterDataPointer, getRegisterDataPointer, setupReservedDataCase, FIRST_RESERVED_VARIABLE + 31);
  failures += runGetPointerCase("getRegisterDataPointer", oracle_getRegisterDataPointer, getRegisterDataPointer, setupLocalCase, FIRST_LOCAL_REGISTER + 1);

  failures += runGetU32Case("getRegisterTag", oracle_getRegisterTag, getRegisterTag, setupGlobalCase, REGISTER_X);
  failures += runGetU32Case("getRegisterTag", oracle_getRegisterTag, getRegisterTag, setupReservedDataCase, FIRST_RESERVED_VARIABLE + 40);
  failures += runGetU32Case("getRegisterTag", oracle_getRegisterTag, getRegisterTag, setupLocalCase, FIRST_LOCAL_REGISTER + 1);

  failures += runGetU16Case("getRegisterMaxDataLengthInBlocks", oracle_getRegisterMaxDataLengthInBlocks, getRegisterMaxDataLengthInBlocks, setupGlobalLongIntegerCase, REGISTER_X);
  failures += runGetU16Case("getRegisterMaxDataLengthInBlocks", oracle_getRegisterMaxDataLengthInBlocks, getRegisterMaxDataLengthInBlocks, setupGlobalRealMatrixCase, REGISTER_X);
  failures += runGetU16Case("getRegisterMaxDataLengthInBlocks", oracle_getRegisterMaxDataLengthInBlocks, getRegisterMaxDataLengthInBlocks, setupGlobalComplexMatrixCase, REGISTER_X);
  failures += runGetU16Case("getRegisterMaxDataLengthInBlocks", oracle_getRegisterMaxDataLengthInBlocks, getRegisterMaxDataLengthInBlocks, setupNamedStringCase, FIRST_NAMED_VARIABLE + 2);
  failures += runGetU16Case("getRegisterMaxDataLengthInBlocks", oracle_getRegisterMaxDataLengthInBlocks, getRegisterMaxDataLengthInBlocks, setupReservedLongIntegerCase, FIRST_RESERVED_VARIABLE + 40);
  failures += runGetU16Case("getRegisterMaxDataLengthInBlocks", oracle_getRegisterMaxDataLengthInBlocks, getRegisterMaxDataLengthInBlocks, setupLocalLongIntegerCase, FIRST_LOCAL_REGISTER + 1);

  failures += runGetU16Case("getRegisterFullSizeInBlocks", oracle_getRegisterFullSizeInBlocks, getRegisterFullSizeInBlocks, setupGlobalLongIntegerCase, REGISTER_X);
  failures += runGetU16Case("getRegisterFullSizeInBlocks", oracle_getRegisterFullSizeInBlocks, getRegisterFullSizeInBlocks, setupGlobalReal34Case, REGISTER_X);
  failures += runGetU16Case("getRegisterFullSizeInBlocks", oracle_getRegisterFullSizeInBlocks, getRegisterFullSizeInBlocks, setupGlobalComplex34Case, REGISTER_X);
  failures += runGetU16Case("getRegisterFullSizeInBlocks", oracle_getRegisterFullSizeInBlocks, getRegisterFullSizeInBlocks, setupGlobalShortIntegerCase, REGISTER_X);
  failures += runGetU16Case("getRegisterFullSizeInBlocks", oracle_getRegisterFullSizeInBlocks, getRegisterFullSizeInBlocks, setupGlobalRealMatrixCase, REGISTER_X);
  failures += runGetU16Case("getRegisterFullSizeInBlocks", oracle_getRegisterFullSizeInBlocks, getRegisterFullSizeInBlocks, setupGlobalComplexMatrixCase, REGISTER_X);
  failures += runGetU16Case("getRegisterFullSizeInBlocks", oracle_getRegisterFullSizeInBlocks, getRegisterFullSizeInBlocks, setupNamedStringCase, FIRST_NAMED_VARIABLE + 2);
  failures += runGetU16Case("getRegisterFullSizeInBlocks", oracle_getRegisterFullSizeInBlocks, getRegisterFullSizeInBlocks, setupReservedLongIntegerCase, FIRST_RESERVED_VARIABLE + 40);
  failures += runGetU16Case("getRegisterFullSizeInBlocks", oracle_getRegisterFullSizeInBlocks, getRegisterFullSizeInBlocks, setupLocalLongIntegerCase, FIRST_LOCAL_REGISTER + 1);

  failures += runSetTypeCase("setRegisterDataType", oracle_setRegisterDataType, setRegisterDataType, setupGlobalCase, REGISTER_X, dtReal34, amNone);
  failures += runSetTypeCase("setRegisterDataType", oracle_setRegisterDataType, setRegisterDataType, setupNamedCase, FIRST_NAMED_VARIABLE + 2, dtLongInteger, LI_POSITIVE);
  failures += runSetTypeCase("setRegisterDataType", oracle_setRegisterDataType, setRegisterDataType, setupReservedWriteCase, FIRST_RESERVED_VARIABLE + 40, dtReal34, amNone);
  failures += runSetTypeCase("setRegisterDataType", oracle_setRegisterDataType, setRegisterDataType, setupLocalCase, FIRST_LOCAL_REGISTER + 1, dtReal34, amNone);

  failures += runSetMaxLengthCase("setRegisterMaxDataLengthInBlocks", oracle_setRegisterMaxDataLengthInBlocks, setRegisterMaxDataLengthInBlocks, setupGlobalLongIntegerCase, REGISTER_X, 6);
  failures += runSetMaxLengthCase("setRegisterMaxDataLengthInBlocks", oracle_setRegisterMaxDataLengthInBlocks, setRegisterMaxDataLengthInBlocks, setupNamedStringCase, FIRST_NAMED_VARIABLE + 2, 7);
  failures += runSetMaxLengthCase("setRegisterMaxDataLengthInBlocks", oracle_setRegisterMaxDataLengthInBlocks, setRegisterMaxDataLengthInBlocks, setupLocalLongIntegerCase, FIRST_LOCAL_REGISTER + 1, 9);

  failures += runSetPointerCase("setRegisterDataPointer", oracle_setRegisterDataPointer, setRegisterDataPointer, setupGlobalCase, REGISTER_X, 1, 0x60);
  failures += runSetPointerCase("setRegisterDataPointer", oracle_setRegisterDataPointer, setRegisterDataPointer, setupNamedCase, FIRST_NAMED_VARIABLE + 2, 1, 0x70);
  failures += runSetPointerCase("setRegisterDataPointer", oracle_setRegisterDataPointer, setRegisterDataPointer, setupReservedDataCase, FIRST_RESERVED_VARIABLE + 31, 1, 0x80);
  failures += runSetPointerCase("setRegisterDataPointer", oracle_setRegisterDataPointer, setRegisterDataPointer, setupLocalCase, FIRST_LOCAL_REGISTER + 1, 1, 0x90);

  failures += runSetTagCase("setRegisterTag", oracle_setRegisterTag, setRegisterTag, setupGlobalCase, REGISTER_X, amNone);
  failures += runSetTagCase("setRegisterTag", oracle_setRegisterTag, setRegisterTag, setupNamedCase, FIRST_NAMED_VARIABLE + 2, LI_POSITIVE);
  failures += runSetTagCase("setRegisterTag", oracle_setRegisterTag, setRegisterTag, setupReservedDataCase, FIRST_RESERVED_VARIABLE + 40, amNone);
  failures += runSetTagCase("setRegisterTag", oracle_setRegisterTag, setRegisterTag, setupLocalCase, FIRST_LOCAL_REGISTER + 1, amNone);

  failures += runCopyCase("copySourceRegisterToDestRegister", oracle_copySourceRegisterToDestRegister, copySourceRegisterToDestRegister, setupCopyGlobalLongIntegerCase, REGISTER_X, REGISTER_Y);
  failures += runCopyCase("copySourceRegisterToDestRegister", oracle_copySourceRegisterToDestRegister, copySourceRegisterToDestRegister, setupCopyNamedStringCase, FIRST_NAMED_VARIABLE + 2, REGISTER_Y);
  failures += runCopyCase("copySourceRegisterToDestRegister", oracle_copySourceRegisterToDestRegister, copySourceRegisterToDestRegister, setupCopyLocalLongIntegerCase, FIRST_LOCAL_REGISTER + 1, REGISTER_Y);
  failures += runCopyCase("copySourceRegisterToDestRegister", oracle_copySourceRegisterToDestRegister, copySourceRegisterToDestRegister, setupCopyReservedLetteredSourceCase, FIRST_RESERVED_VARIABLE, REGISTER_Y);
  failures += runCopyCase("copySourceRegisterToDestRegister", oracle_copySourceRegisterToDestRegister, copySourceRegisterToDestRegister, setupCopyReservedLetteredDestCase, REGISTER_Y, FIRST_RESERVED_VARIABLE);
  failures += runCopyCase("copySourceRegisterToDestRegister", oracle_copySourceRegisterToDestRegister, copySourceRegisterToDestRegister, setupCopyReservedDataCase, FIRST_RESERVED_VARIABLE + 40, REGISTER_Y);
  failures += runCopyCase("copySourceRegisterToDestRegister", oracle_copySourceRegisterToDestRegister, copySourceRegisterToDestRegister, setupCopyMatrixCase, REGISTER_X, REGISTER_Y);

  failures += runReallocateCase("reallocateRegister", oracle_reallocateRegister, reallocateRegister, setupReallocateGlobalLongIntegerCase, REGISTER_X, dtLongInteger, 1, LI_POSITIVE);
  failures += runReallocateCase("reallocateRegister", oracle_reallocateRegister, reallocateRegister, setupReallocateNamedStringCase, FIRST_NAMED_VARIABLE + 2, dtString, 5, amNone);
  failures += runReallocateCase("reallocateRegister", oracle_reallocateRegister, reallocateRegister, setupReallocateLocalMatrixCase, FIRST_LOCAL_REGISTER + 1, dtReal34Matrix, REAL34_SIZE_IN_BLOCKS * 2, amNone);
  failures += runReallocateCase("reallocateRegister", oracle_reallocateRegister, reallocateRegister, setupReallocateComplexPolarCase, REGISTER_X, dtComplex34, 0, amNone);
  failures += runReallocateCase("reallocateRegister", oracle_reallocateRegister, reallocateRegister, setupReallocateMemoryFullCase, REGISTER_X, dtString, 6, amNone);

  if(failures != 0) {
    fprintf(stderr, "%d register-metadata parity checks failed\n", failures);
    return 1;
  }

  puts("register-metadata parity checks passed");
  return 0;
}