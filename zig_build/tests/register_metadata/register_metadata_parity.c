// SPDX-License-Identifier: GPL-3.0-only

#include <stdio.h>
#include <string.h>

#include "c47.h"

uint32_t getRegisterDataType(calcRegister_t reg);
void *getRegisterDataPointer(calcRegister_t reg);
uint32_t getRegisterTag(calcRegister_t reg);
void setRegisterDataType(calcRegister_t reg, uint16_t data_type, uint32_t tag);
void setRegisterDataPointer(calcRegister_t reg, const void *mem_ptr);
void setRegisterTag(calcRegister_t reg, uint32_t tag);

uint32_t oracle_getRegisterDataType(calcRegister_t reg);
void *oracle_getRegisterDataPointer(calcRegister_t reg);
uint32_t oracle_getRegisterTag(calcRegister_t reg);
void oracle_setRegisterDataType(calcRegister_t reg, uint16_t data_type, uint32_t tag);
void oracle_setRegisterDataPointer(calcRegister_t reg, const void *mem_ptr);
void oracle_setRegisterTag(calcRegister_t reg, uint32_t tag);

typedef uint32_t (*get_u32_fn)(calcRegister_t);
typedef void *(*get_ptr_fn)(calcRegister_t);
typedef void (*set_type_fn)(calcRegister_t, uint16_t, uint32_t);
typedef void (*set_ptr_fn)(calcRegister_t, const void *);
typedef void (*set_tag_fn)(calcRegister_t, uint32_t);

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

static void seedReservedBacking(void) {
  uint8_t acc_payload[REAL34_SIZE_IN_BYTES];
  uint8_t gramod_payload[TO_BYTES(1)];
  void *acc_ptr;
  void *gramod_ptr;

  fillPayload(acc_payload, REAL34_SIZE_IN_BLOCKS, 0xa0);
  acc_ptr = allocC47Blocks(REAL34_SIZE_IN_BLOCKS);
  if(acc_ptr != NULL) {
    memcpy(acc_ptr, acc_payload, sizeof(acc_payload));
  }

  fillPayload(gramod_payload, 1, 0xb0);
  gramod_ptr = allocC47Blocks(1);
  if(gramod_ptr != NULL) {
    memcpy(gramod_ptr, gramod_payload, sizeof(gramod_payload));
  }
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

int main(void) {
  int failures = 0;

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

  failures += runSetTypeCase("setRegisterDataType", oracle_setRegisterDataType, setRegisterDataType, setupGlobalCase, REGISTER_X, dtReal34, amNone);
  failures += runSetTypeCase("setRegisterDataType", oracle_setRegisterDataType, setRegisterDataType, setupNamedCase, FIRST_NAMED_VARIABLE + 2, dtLongInteger, LI_POSITIVE);
  failures += runSetTypeCase("setRegisterDataType", oracle_setRegisterDataType, setRegisterDataType, setupReservedWriteCase, FIRST_RESERVED_VARIABLE + 40, dtReal34, amNone);
  failures += runSetTypeCase("setRegisterDataType", oracle_setRegisterDataType, setRegisterDataType, setupLocalCase, FIRST_LOCAL_REGISTER + 1, dtReal34, amNone);

  failures += runSetPointerCase("setRegisterDataPointer", oracle_setRegisterDataPointer, setRegisterDataPointer, setupGlobalCase, REGISTER_X, 1, 0x60);
  failures += runSetPointerCase("setRegisterDataPointer", oracle_setRegisterDataPointer, setRegisterDataPointer, setupNamedCase, FIRST_NAMED_VARIABLE + 2, 1, 0x70);
  failures += runSetPointerCase("setRegisterDataPointer", oracle_setRegisterDataPointer, setRegisterDataPointer, setupReservedDataCase, FIRST_RESERVED_VARIABLE + 31, 1, 0x80);
  failures += runSetPointerCase("setRegisterDataPointer", oracle_setRegisterDataPointer, setRegisterDataPointer, setupLocalCase, FIRST_LOCAL_REGISTER + 1, 1, 0x90);

  failures += runSetTagCase("setRegisterTag", oracle_setRegisterTag, setRegisterTag, setupGlobalCase, REGISTER_X, amNone);
  failures += runSetTagCase("setRegisterTag", oracle_setRegisterTag, setRegisterTag, setupNamedCase, FIRST_NAMED_VARIABLE + 2, LI_POSITIVE);
  failures += runSetTagCase("setRegisterTag", oracle_setRegisterTag, setRegisterTag, setupReservedDataCase, FIRST_RESERVED_VARIABLE + 40, amNone);
  failures += runSetTagCase("setRegisterTag", oracle_setRegisterTag, setRegisterTag, setupLocalCase, FIRST_LOCAL_REGISTER + 1, amNone);

  if(failures != 0) {
    fprintf(stderr, "%d register-metadata parity checks failed\n", failures);
    return 1;
  }

  puts("register-metadata parity checks passed");
  return 0;
}