// SPDX-License-Identifier: GPL-3.0-only

#include <stdio.h>
#include <string.h>

#include "c47.h"

void liftStack(void);
bool_t saveLastX(void);
void saveForUndo(void);
void undo(void);
void fnGetLocR(uint16_t unusedButMandatoryParameter);
void fnClearRegisters(uint16_t confirmation);
void clearRegister(calcRegister_t reg);
void fnRegClr(uint16_t unusedButMandatoryParameter);

void fnDrop(uint16_t unusedButMandatoryParameter);
void fnDropY(uint16_t unusedButMandatoryParameter);
void fnRollUp(uint16_t unusedButMandatoryParameter);
void fnRollDown(uint16_t unusedButMandatoryParameter);
void fnDisplayStack(uint16_t numberOfStackLines);
void fnSwapX(uint16_t regist);
void fnSwapXY(uint16_t unusedButMandatoryParameter);
void fnShuffle(uint16_t regist_order);
void fnFillStack(uint16_t unusedButMandatoryParameter);

void oracle_liftStack(void);
bool_t oracle_saveLastX(void);
void oracle_saveForUndo(void);
void oracle_undo(void);
void oracle_fnGetLocR(uint16_t unusedButMandatoryParameter);
void oracle_fnClearRegisters(uint16_t confirmation);
void oracle_clearRegister(calcRegister_t reg);
void oracle_fnRegClr(uint16_t unusedButMandatoryParameter);

void oracle_fnDrop(uint16_t unusedButMandatoryParameter);
void oracle_fnDropY(uint16_t unusedButMandatoryParameter);
void oracle_fnRollUp(uint16_t unusedButMandatoryParameter);
void oracle_fnRollDown(uint16_t unusedButMandatoryParameter);
void oracle_fnDisplayStack(uint16_t numberOfStackLines);
void oracle_fnSwapX(uint16_t regist);
void oracle_fnSwapXY(uint16_t unusedButMandatoryParameter);
void oracle_fnShuffle(uint16_t regist_order);
void oracle_fnFillStack(uint16_t unusedButMandatoryParameter);

typedef void (*stack_void_fn)(void);
typedef void (*stack_u16_fn)(uint16_t);
typedef bool_t (*stack_bool_fn)(void);
typedef void (*stack_reg_fn)(calcRegister_t);

static void fillPayload(uint8_t *buffer, uint16_t size_in_blocks, uint8_t seed) {
  uint32_t i;
  for(i = 0; i < TO_BYTES(size_in_blocks); i++) {
    buffer[i] = (uint8_t)(seed + i);
  }
}

static void seedRegister(calcRegister_t reg, uint8_t seed) {
  uint8_t payload[REAL34_SIZE_IN_BYTES];
  fillPayload(payload, REAL34_SIZE_IN_BLOCKS, seed);
  stackParitySeedRegister(reg, dtReal34, amNone, payload, REAL34_SIZE_IN_BLOCKS);
}

static void seedBasicStack(void) {
  seedRegister(REGISTER_X, 0x10);
  seedRegister(REGISTER_Y, 0x20);
  seedRegister(REGISTER_Z, 0x30);
  seedRegister(REGISTER_T, 0x40);
  seedRegister(REGISTER_L, 0x50);
}

static void setupLiftWithAslift(void) {
  seedBasicStack();
  setSystemFlag(FLAG_ASLIFT);
  currentInputVariable = 123;
}

static void setupLiftWithoutAslift(void) {
  seedBasicStack();
  clearSystemFlag(FLAG_ASLIFT);
  currentInputVariable = 123;
}

static void setupDropCase(void) {
  seedBasicStack();
}

static void setupShuffleCase(void) {
  seedBasicStack();
  seedRegister(SAVED_REGISTER_X + 0, 0x60);
  seedRegister(SAVED_REGISTER_X + 1, 0x70);
  seedRegister(SAVED_REGISTER_X + 2, 0x80);
  seedRegister(SAVED_REGISTER_X + 3, 0x90);
}

static void setupSaveForUndoCase(void) {
  seedBasicStack();
  currentInputVariable = 77;
  entryStatus = 0x01;
  systemFlags0 = 0x0123456789abcdefULL;
  systemFlags1 = 0x00fedcba98765432ULL;
  lrSelection = 11;
  lrChosen = 7;
  stackParitySeedCurrentStats(0xa0);
}

static void mutateAfterSave(void) {
  seedRegister(REGISTER_X, 0xb0);
  seedRegister(REGISTER_Y, 0xc0);
  currentInputVariable = 15;
  entryStatus = 0;
  systemFlags0 ^= 0x00ff00ff00ff00ffULL;
  systemFlags1 ^= 0x0f0f0f0f0f0f0f0fULL;
  lrSelection = 33;
  lrChosen = 44;
  displayStack = 3;
  stackParitySeedCurrentStats(0xd0);
}

static void setupGetLocRCase(void) {
  seedBasicStack();
  clearSystemFlag(FLAG_ASLIFT);
  currentNumberOfLocalRegisters = 3;
}

static void setupGetLocRAsliftCase(void) {
  seedBasicStack();
  setSystemFlag(FLAG_ASLIFT);
  currentNumberOfLocalRegisters = 3;
}

static void setupClearRegistersCase(void) {
  seedBasicStack();
  seedRegister(0, 0x60);
  seedRegister(REGISTER_A, 0x70);
  seedRegister(REGISTER_I, 0x80);
  stackParitySeedLocalRegister(0, dtReal34, amNone, (const uint8_t[REAL34_SIZE_IN_BYTES]){0x90}, REAL34_SIZE_IN_BLOCKS);
  currentNumberOfLocalRegisters = 1;
  clearSystemFlag(FLAG_SSIZE8);
  programRunStop = 0;
}

static void setupClearRegistersRunningCase(void) {
  setupClearRegistersCase();
  programRunStop = PGM_RUNNING;
}

static void setupClearRegistersStack8Case(void) {
  setupClearRegistersCase();
  setSystemFlag(FLAG_SSIZE8);
}

static void setupClearRegistersConfirmCase(void) {
  setupClearRegistersCase();
  programRunStop = 0;
}

static void setupRegClrCase(void) {
  seedBasicStack();
  seedRegister(2, 0xe0);
  seedRegister(3, 0xe4);
  seedRegister(4, 0xe8);
  seedRegister(5, 0xec);
  stackParitySetRegClrRange(ERROR_NONE, 2, 3);
}

static void setupRegClrErrorCase(void) {
  seedBasicStack();
  stackParitySetRegClrRange(ERROR_OUT_OF_RANGE, 0, 0);
}

static void setupClearRegisterRealCase(void) {
  seedRegister(REGISTER_X, 0xa0);
  Input_Default = ID_DP;
  lastIntegerBase = 0;
}

static void setupClearRegisterComplexCase(void) {
  uint8_t payload[TO_BYTES(COMPLEX34_SIZE_IN_BLOCKS)] = {0};

  seedBasicStack();
  stackParitySeedRegister(REGISTER_X, dtComplex34, amPolar | 2, payload, COMPLEX34_SIZE_IN_BLOCKS);
  Input_Default = ID_CPXDP;
  lastIntegerBase = 0;
  currentAngularMode = 2;
  setSystemFlag(FLAG_POLAR);
}

static void setupClearRegisterComplexReallocateCase(void) {
  seedRegister(REGISTER_X, 0xb0);
  Input_Default = ID_CPXDP;
  lastIntegerBase = 0;
  currentAngularMode = 2;
  clearSystemFlag(FLAG_POLAR);
}

static void setupClearRegisterLongIntegerCase(void) {
  seedRegister(REGISTER_X, 0xc0);
  Input_Default = ID_LI;
  lastIntegerBase = 0;
}

static void setupClearRegisterShortIntegerCase(void) {
  seedRegister(REGISTER_X, 0xd0);
  Input_Default = ID_DP;
  lastIntegerBase = 16;
}

static void captureAndCompare(const char *name, const stack_parity_snapshot_t *expected, const stack_parity_snapshot_t *actual, uint16_t arg, int *failures) {
  if(memcmp(expected, actual, sizeof(*expected)) != 0) {
    fprintf(stderr,
            "%s(%u) parity mismatch\n"
            "  expected: x_desc=%#x y_desc=%#x z_desc=%#x t_desc=%#x undo=%d err=%u flags0=%#llx flags1=%#llx display=%u\n"
            "  actual:   x_desc=%#x y_desc=%#x z_desc=%#x t_desc=%#x undo=%d err=%u flags0=%#llx flags1=%#llx display=%u\n",
            name,
            arg,
            expected->global_registers[REGISTER_X].header.descriptor,
            expected->global_registers[REGISTER_Y].header.descriptor,
            expected->global_registers[REGISTER_Z].header.descriptor,
            expected->global_registers[REGISTER_T].header.descriptor,
            expected->thereIsSomethingToUndo,
            expected->lastErrorCode,
            (unsigned long long)expected->systemFlags0,
            (unsigned long long)expected->systemFlags1,
            expected->displayStack,
            actual->global_registers[REGISTER_X].header.descriptor,
            actual->global_registers[REGISTER_Y].header.descriptor,
            actual->global_registers[REGISTER_Z].header.descriptor,
            actual->global_registers[REGISTER_T].header.descriptor,
            actual->thereIsSomethingToUndo,
            actual->lastErrorCode,
            (unsigned long long)actual->systemFlags0,
            (unsigned long long)actual->systemFlags1,
            actual->displayStack);
    (*failures)++;
  }
}

static int runVoidCase(const char *name, stack_void_fn oracle_fn, stack_void_fn zig_fn, void (*setup)(void)) {
  stack_parity_snapshot_t expected;
  stack_parity_snapshot_t actual;
  int failures = 0;

  stackParityReset();
  setup();
  oracle_fn();
  stackParityCapture(&expected);

  stackParityReset();
  setup();
  zig_fn();
  stackParityCapture(&actual);

  captureAndCompare(name, &expected, &actual, 0, &failures);
  return failures;
}

static int runU16Case(const char *name, stack_u16_fn oracle_fn, stack_u16_fn zig_fn, void (*setup)(void), uint16_t arg) {
  stack_parity_snapshot_t expected;
  stack_parity_snapshot_t actual;
  int failures = 0;

  stackParityReset();
  setup();
  oracle_fn(arg);
  stackParityCapture(&expected);

  stackParityReset();
  setup();
  zig_fn(arg);
  stackParityCapture(&actual);

  captureAndCompare(name, &expected, &actual, arg, &failures);
  return failures;
}

static int runSaveUndoRoundTripCase(void) {
  stack_parity_snapshot_t expected;
  stack_parity_snapshot_t actual;
  int failures = 0;

  stackParityReset();
  setupSaveForUndoCase();
  oracle_saveForUndo();
  mutateAfterSave();
  oracle_undo();
  stackParityCapture(&expected);

  stackParityReset();
  setupSaveForUndoCase();
  saveForUndo();
  mutateAfterSave();
  undo();
  stackParityCapture(&actual);

  captureAndCompare("saveForUndo+undo", &expected, &actual, 0, &failures);
  return failures;
}

static int runBoolCase(const char *name, stack_bool_fn oracle_fn, stack_bool_fn zig_fn, void (*setup)(void)) {
  stack_parity_snapshot_t expected;
  stack_parity_snapshot_t actual;
  bool_t expected_result;
  bool_t actual_result;
  int failures = 0;

  stackParityReset();
  setup();
  expected_result = oracle_fn();
  stackParityCapture(&expected);

  stackParityReset();
  setup();
  actual_result = zig_fn();
  stackParityCapture(&actual);

  if(expected_result != actual_result) {
    fprintf(stderr, "%s result mismatch: expected %u actual %u\n", name, expected_result, actual_result);
    failures++;
  }

  captureAndCompare(name, &expected, &actual, 0, &failures);
  return failures;
}

static int runRegCase(const char *name, stack_reg_fn oracle_fn, stack_reg_fn zig_fn, void (*setup)(void), calcRegister_t reg) {
  stack_parity_snapshot_t expected;
  stack_parity_snapshot_t actual;
  int failures = 0;

  stackParityReset();
  setup();
  oracle_fn(reg);
  stackParityCapture(&expected);

  stackParityReset();
  setup();
  zig_fn(reg);
  stackParityCapture(&actual);

  captureAndCompare(name, &expected, &actual, (uint16_t)reg, &failures);
  return failures;
}

int main(void) {
  int failures = 0;

  failures += runVoidCase("liftStack", oracle_liftStack, liftStack, setupLiftWithAslift);
  failures += runVoidCase("liftStack", oracle_liftStack, liftStack, setupLiftWithoutAslift);
  failures += runRegCase("clearRegister", oracle_clearRegister, clearRegister, setupClearRegisterRealCase, REGISTER_X);
  failures += runRegCase("clearRegister", oracle_clearRegister, clearRegister, setupClearRegisterComplexCase, REGISTER_X);
  failures += runRegCase("clearRegister", oracle_clearRegister, clearRegister, setupClearRegisterComplexReallocateCase, REGISTER_X);
  failures += runRegCase("clearRegister", oracle_clearRegister, clearRegister, setupClearRegisterLongIntegerCase, REGISTER_X);
  failures += runRegCase("clearRegister", oracle_clearRegister, clearRegister, setupClearRegisterShortIntegerCase, REGISTER_X);
  failures += runBoolCase("saveLastX", oracle_saveLastX, saveLastX, setupDropCase);
  failures += runU16Case("fnGetLocR", oracle_fnGetLocR, fnGetLocR, setupGetLocRCase, 0);
  failures += runU16Case("fnGetLocR", oracle_fnGetLocR, fnGetLocR, setupGetLocRAsliftCase, 0);
  failures += runU16Case("fnClearRegisters", oracle_fnClearRegisters, fnClearRegisters, setupClearRegistersCase, 1);
  failures += runU16Case("fnClearRegisters", oracle_fnClearRegisters, fnClearRegisters, setupClearRegistersConfirmCase, NOT_CONFIRMED);
  failures += runU16Case("fnClearRegisters", oracle_fnClearRegisters, fnClearRegisters, setupClearRegistersRunningCase, NOT_CONFIRMED);
  failures += runU16Case("fnClearRegisters", oracle_fnClearRegisters, fnClearRegisters, setupClearRegistersStack8Case, 1);
  failures += runU16Case("fnRegClr", oracle_fnRegClr, fnRegClr, setupRegClrCase, 0);
  failures += runU16Case("fnRegClr", oracle_fnRegClr, fnRegClr, setupRegClrErrorCase, 0);

  failures += runU16Case("fnDrop", oracle_fnDrop, fnDrop, setupDropCase, 0);
  failures += runU16Case("fnDropY", oracle_fnDropY, fnDropY, setupDropCase, 0);
  failures += runU16Case("fnRollUp", oracle_fnRollUp, fnRollUp, setupDropCase, 0);
  failures += runU16Case("fnRollDown", oracle_fnRollDown, fnRollDown, setupDropCase, 0);
  failures += runU16Case("fnDisplayStack", oracle_fnDisplayStack, fnDisplayStack, setupDropCase, 3);
  failures += runU16Case("fnSwapX", oracle_fnSwapX, fnSwapX, setupDropCase, REGISTER_L);
  failures += runU16Case("fnSwapXY", oracle_fnSwapXY, fnSwapXY, setupDropCase, 0);
  failures += runU16Case("fnShuffle", oracle_fnShuffle, fnShuffle, setupShuffleCase, 0xb1);
  failures += runU16Case("fnFillStack", oracle_fnFillStack, fnFillStack, setupDropCase, 0);

  failures += runVoidCase("saveForUndo", oracle_saveForUndo, saveForUndo, setupSaveForUndoCase);
  failures += runSaveUndoRoundTripCase();

  if(failures != 0) {
    fprintf(stderr, "%d stack-state parity checks failed\n", failures);
    return 1;
  }

  puts("stack-state parity checks passed");
  return 0;
}
