// SPDX-License-Identifier: GPL-3.0-only
//
// register-metadata parity: the Zig owner against c43's own registers.c, in one
// binary (REPORT-31 M31-12).
//
// register_metadata_oracle.c compiles c43's registers.c a second time under
// `oracle_` names beside the Zig owner that replaced it. Both implementations
// then share ONE calculator -- the same `globalRegister` array, the same named
// variables, the same RAM slab and free list -- so nothing about the environment
// is modelled and a difference can only come from the code under test. The
// reference is c43 source compiled at build time, so it moves when c43 moves.
//
// WHAT THIS REPLACED: 1060 lines of hand-transliterated C plus a 939-line driver
// over a mock world whose `registerHeader_t` was a packed word rather than c43's
// bitfield struct. The old lane could not see c43 move, and its fixture had
// already drifted onto the pre-SPARE reserved-variable model.
//
// SEED / RUN / SNAPSHOT / RE-SEED / RUN / SNAPSHOT. Every mutating case rebuilds
// the fixture from `fnReset(CONFIRMED)` before each side runs. A full core
// carries far more state than a unit harness, so running the two sides back to
// back would compare c43 against a calculator the Zig owner had already changed.

#include <c47.h>

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Screen/GUI globals the core references; normally testSuite.c's. Headless here.
GtkWidget      *screen;
calcKeyboard_t  calcKeyboard[43];
int             currentBezel;
int16_t         screenStride;
uint32_t       *screenData;
bool_t          screenChange;

// ---------------------------------------------------------------------------
// The two implementations. Unprefixed names are the Zig owner's exports (declared
// by upstream's registers.h via <c47.h>); `oracle_` ones are c43's own bodies.
// ---------------------------------------------------------------------------
extern const reservedVariableHeader_t oracle_allReservedVariables[];

extern uint32_t oracle_getRegisterDataType(calcRegister_t regist);
extern void    *oracle_getRegisterDataPointer(calcRegister_t regist);
extern uint32_t oracle_getRegisterTag(calcRegister_t regist);
extern uint16_t oracle_getRegisterMaxDataLengthInBlocks(calcRegister_t regist);
extern uint16_t oracle_getRegisterFullSizeInBlocks(calcRegister_t regist);
extern void     oracle_setRegisterDataType(calcRegister_t regist, uint16_t dataType, uint32_t tag);
extern void     oracle_setRegisterDataPointer(calcRegister_t regist, const void *memPtr);
extern void     oracle_setRegisterTag(calcRegister_t regist, uint32_t tag);
extern void     oracle_setRegisterMaxDataLengthInBlocks(calcRegister_t regist, uint16_t maxDataLen);
extern void     oracle_reallocateRegister(calcRegister_t regist, uint32_t dataType, uint16_t dataSizeWithoutDataLenBlocks, uint32_t tag);
extern void     oracle_clearRegister(calcRegister_t regist);
extern void     oracle_copySourceRegisterToDestRegister(calcRegister_t sourceRegister, calcRegister_t destRegister);
extern void     oracle_allocateLocalRegisters(uint16_t numberOfRegistersToAllocate);
extern void     oracle_allocateNamedVariable(const char *variableName, uint32_t dataType, uint16_t fullDataSizeInBlocks);
extern calcRegister_t oracle_findNamedVariable(const char *variableName);
extern calcRegister_t oracle_findOrAllocateNamedVariable(const char *variableName);
extern calcRegister_t oracle_allocateNamedVariableOnMiss(const char *variableName);
extern bool_t   oracle_validateName(const char *name);
extern bool_t   oracle_isUniqueMenuName(const char *name);
extern bool_t   oracle_isFunctionAllowingNewVariable(int16_t func);
extern bool_t   oracle_namedVariableIsStats(calcRegister_t regist);
extern void     oracle_clampShortIntegerRegistersToWordSize(void);
extern void     oracle_fnDeleteVariable(uint16_t regist);
extern void     oracle_fnClearAllVariables(uint16_t confirmation);
extern void     oracle_fnDeleteAllVariables(uint16_t confirmation);

static int failures = 0;

static void fail(const char *fmt, ...) {
  va_list args;
  va_start(args, fmt);
  printf("FAIL: ");
  vprintf(fmt, args);
  printf("\n");
  va_end(args);
  failures++;
}

// ---------------------------------------------------------------------------
// The state both implementations share, snapshotted WHOLESALE.
//
// An enumerated snapshot can forget a field; a memcmp over the slab cannot. The
// RAM image is the bulk of it -- reallocateRegister and allocateNamedVariable
// move blocks around inside it, and a divergence in how many blocks a register
// claims shows up there and nowhere else.
// ---------------------------------------------------------------------------
typedef struct {
  registerHeader_t globalRegister[NUMBER_OF_GLOBAL_REGISTERS];
  uint16_t         numberOfNamedVariables;
  uint8_t          localRegisterCount; // currentNumberOfLocalRegisters is a defines.h macro
  uint8_t          lastErrorCode;
  uint8_t          temporaryInformation;
  uint32_t         freeMemoryBlocks;
  uint8_t          ram[RAM_SIZE_IN_BLOCKS * 4];
} snapshot_t;

static snapshot_t snapshotA;
static snapshot_t snapshotB;

static void takeSnapshot(snapshot_t *out) {
  memset(out, 0, sizeof(*out));
  memcpy(out->globalRegister, globalRegister, sizeof(out->globalRegister));
  out->numberOfNamedVariables = numberOfNamedVariables;
  out->localRegisterCount = currentSubroutineLevelData == NULL ? 0 : currentNumberOfLocalRegisters;
  out->lastErrorCode = lastErrorCode;
  out->temporaryInformation = temporaryInformation;
  out->freeMemoryBlocks = getFreeRamMemory();
  memcpy(out->ram, ram, sizeof(out->ram));
}

static int reportSnapshotMismatch(const char *caseName) {
  if(memcmp(&snapshotA, &snapshotB, sizeof(snapshotA)) == 0) {
    return 0;
  }

  // Name the first field that differs, so the failure says WHICH part of the
  // register subsystem diverged rather than only that something did.
  if(memcmp(snapshotA.globalRegister, snapshotB.globalRegister, sizeof(snapshotA.globalRegister)) != 0) {
    for(size_t i = 0; i < NUMBER_OF_GLOBAL_REGISTERS; i++) {
      if(memcmp(&snapshotA.globalRegister[i], &snapshotB.globalRegister[i], sizeof(registerHeader_t)) != 0) {
        fail("%s: globalRegister[%zu] differs -- z47{ptr=%u type=%u tag=%u ro=%u} c43{ptr=%u type=%u tag=%u ro=%u}",
             caseName, i,
             snapshotA.globalRegister[i].pointerToRegisterData, snapshotA.globalRegister[i].dataType,
             snapshotA.globalRegister[i].tag, snapshotA.globalRegister[i].readOnly,
             snapshotB.globalRegister[i].pointerToRegisterData, snapshotB.globalRegister[i].dataType,
             snapshotB.globalRegister[i].tag, snapshotB.globalRegister[i].readOnly);
        return 1;
      }
    }
  }
  if(snapshotA.numberOfNamedVariables != snapshotB.numberOfNamedVariables) {
    fail("%s: numberOfNamedVariables z47=%u c43=%u", caseName,
         snapshotA.numberOfNamedVariables, snapshotB.numberOfNamedVariables);
    return 1;
  }
  if(snapshotA.localRegisterCount != snapshotB.localRegisterCount) {
    fail("%s: currentNumberOfLocalRegisters z47=%u c43=%u", caseName,
         snapshotA.localRegisterCount, snapshotB.localRegisterCount);
    return 1;
  }
  if(snapshotA.lastErrorCode != snapshotB.lastErrorCode) {
    fail("%s: lastErrorCode z47=%u c43=%u", caseName, snapshotA.lastErrorCode, snapshotB.lastErrorCode);
    return 1;
  }
  if(snapshotA.temporaryInformation != snapshotB.temporaryInformation) {
    fail("%s: temporaryInformation z47=%u c43=%u", caseName,
         snapshotA.temporaryInformation, snapshotB.temporaryInformation);
    return 1;
  }
  if(snapshotA.freeMemoryBlocks != snapshotB.freeMemoryBlocks) {
    fail("%s: free memory z47=%u c43=%u blocks", caseName,
         snapshotA.freeMemoryBlocks, snapshotB.freeMemoryBlocks);
    return 1;
  }
  for(size_t i = 0; i < sizeof(snapshotA.ram); i++) {
    if(snapshotA.ram[i] != snapshotB.ram[i]) {
      fail("%s: RAM differs at byte %zu (block %zu): z47=0x%02x c43=0x%02x",
           caseName, i, i / 4, snapshotA.ram[i], snapshotB.ram[i]);
      return 1;
    }
  }
  fail("%s: snapshots differ but no field was identified -- widen the report", caseName);
  return 1;
}

// ---------------------------------------------------------------------------
// The fixture. Diverse enough that a divergence in ANY register class shows up:
// every payload shape (fixed, variable-length, matrix), a named variable, a local
// frame, and a couple of read-only reserved variables.
// ---------------------------------------------------------------------------
static void buildFixture(void) {
  fnReset(CONFIRMED);

  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  int32ToReal34(1234, REGISTER_REAL34_DATA(REGISTER_X));
  reallocateRegister(REGISTER_Y, dtReal34, 0, amDegree);
  int32ToReal34(90, REGISTER_REAL34_DATA(REGISTER_Y));
  reallocateRegister(REGISTER_Z, dtComplex34, 0, amNone);
  int32ToReal34(3, REGISTER_REAL34_DATA(REGISTER_Z));
  int32ToReal34(4, REGISTER_IMAG34_DATA(REGISTER_Z));
  convertUInt64ToShortIntegerRegister(0, 0xDEADBEEFULL, 16, REGISTER_A);

  {
    longInteger_t li;
    longIntegerInit(li);
    stringToLongInteger("123456789012345678901234567890", 10, li);
    convertLongIntegerToLongIntegerRegister(li, REGISTER_B);
    longIntegerFree(li);
  }
  {
    const char *s = "register string";
    reallocateRegister(REGISTER_C, dtString, TO_BLOCKS((int)strlen(s) + 1), amNone);
    strcpy(REGISTER_STRING_DATA(REGISTER_C), s);
  }

  initMatrixRegister(10, 2, 3, false);
  for(int e = 0; e < 6; ++e) {
    int32ToReal34(e * 10 + 1, REGISTER_REAL34_MATRIX_ELEMENTS(10) + e);
  }

  allocateNamedVariable("TESTVAR", dtReal34, REAL34_SIZE_IN_BLOCKS);
  int32ToReal34(777, REGISTER_REAL34_DATA(findNamedVariable("TESTVAR")));
  allocateNamedVariable("STRV", dtString, TO_BLOCKS(8));

  allocateLocalRegisters(3);
  reallocateRegister(FIRST_LOCAL_REGISTER + 0, dtReal34, 0, amNone);
  int32ToReal34(111, REGISTER_REAL34_DATA(FIRST_LOCAL_REGISTER + 0));
}

// Run one side of a mutating case: rebuild the fixture, run `body`, snapshot.
static void runSide(void (*body)(void), snapshot_t *out) {
  buildFixture();
  body();
  takeSnapshot(out);
}

static int diffCase(const char *caseName, void (*zigSide)(void), void (*c43Side)(void)) {
  runSide(zigSide, &snapshotA);
  runSide(c43Side, &snapshotB);
  return reportSnapshotMismatch(caseName);
}

// ---------------------------------------------------------------------------
// Check 1 -- the reserved-variable table.
//
// registers.c DEFINES allReservedVariables, so compiling it brings c43's real
// 48-entry table into the binary while the Zig owner exports its own. Nothing in
// the tree ever compared them, which is why the pre-SPARE model survived: z47
// named ADM/DENMAX/ISM/REALDF/NDEC at 2026-2030 where c43 has placeholders, and
// every lane agreed with itself. This is the check that would have caught it.
// ---------------------------------------------------------------------------
static int runReservedVariableTableDifferential(void) {
  const int count = LAST_RESERVED_VARIABLE - FIRST_RESERVED_VARIABLE + 1;
  int bad = 0;

  for(int i = 0; i < count; i++) {
    const reservedVariableHeader_t *mine = &allReservedVariables[i];
    const reservedVariableHeader_t *theirs = &oracle_allReservedVariables[i];

    if(memcmp(mine, theirs, sizeof(*mine)) != 0) {
      fail("allReservedVariables[%d] (register %d) differs:\n"
           "       z47: ptr=%u type=%u tag=%u ro=%u notUsed=%u name-len=%u name=\"%.7s\"\n"
           "       c43: ptr=%u type=%u tag=%u ro=%u notUsed=%u name-len=%u name=\"%.7s\"",
           i, FIRST_RESERVED_VARIABLE + i,
           mine->header.pointerToRegisterData, mine->header.dataType, mine->header.tag,
           mine->header.readOnly, mine->header.notUsed,
           mine->reservedVariableName[0], (const char *)mine->reservedVariableName + 1,
           theirs->header.pointerToRegisterData, theirs->header.dataType, theirs->header.tag,
           theirs->header.readOnly, theirs->header.notUsed,
           theirs->reservedVariableName[0], (const char *)theirs->reservedVariableName + 1);
      bad = 1;
    }
  }

  if(!bad) {
    printf("PASS: allReservedVariables matches c43's table entry for entry (%d entries)\n", count);
  }
  return bad;
}

// ---------------------------------------------------------------------------
// Check 2 -- the metadata accessors, over a register sweep that crosses every
// class boundary. These are pure queries, so they need no re-seed: both sides
// read the same state and must return the same answer.
// ---------------------------------------------------------------------------
static const calcRegister_t sweepRegisters[] = {
  0, 1, 50, 99,                                       // numbered
  REGISTER_X, REGISTER_Y, REGISTER_Z, REGISTER_T,     // stack
  REGISTER_A, REGISTER_B, REGISTER_C, REGISTER_D,
  REGISTER_L, REGISTER_I, REGISTER_J, REGISTER_K,
  10,                                                 // the matrix register
  LAST_GLOBAL_REGISTER,
  FIRST_NAMED_VARIABLE, FIRST_NAMED_VARIABLE + 1,
  FIRST_RESERVED_VARIABLE,                            // lettered reserved (aliases X)
  FIRST_RESERVED_VARIABLE + 25,                       // last lettered reserved
  FIRST_RESERVED_VARIABLE + 26,                       // SPARE1 -- the M31-11 boundary
  FIRST_RESERVED_VARIABLE + 30,                       // SPARE5
  FIRST_NAMED_RESERVED_VARIABLE,                      // ACC
  LAST_RESERVED_VARIABLE,
  FIRST_LOCAL_REGISTER, FIRST_LOCAL_REGISTER + 2,
};
#define SWEEP_COUNT ((int)(sizeof(sweepRegisters) / sizeof(sweepRegisters[0])))

// The subset the PAYLOAD-mutating cases use.
//
// The reserved-variable range is excluded on purpose, and the reason is worth
// stating plainly: c43's `clearRegister(2000)` reads the LETTERED reserved
// variable's type from the aliased stack register (dtReal34) and then writes
// through `getRegisterDataPointer(2000)`, which is NULL -- so it dereferences
// null. A differential must not ask its reference to do something undefined; the
// "expected" answer would be whatever that build's memory happened to hold, and
// the lane would be pinning an accident. Those registers are still swept by the
// read-only accessors above and by the reallocate cases, which allocate before
// they touch a payload.
static const calcRegister_t mutableRegisters[] = {
  0, 99,
  REGISTER_X, REGISTER_Y, REGISTER_Z, REGISTER_T, REGISTER_A, REGISTER_B, REGISTER_C,
  10,                                                 // the matrix register
  LAST_GLOBAL_REGISTER,
  FIRST_NAMED_VARIABLE, FIRST_NAMED_VARIABLE + 1,
  FIRST_LOCAL_REGISTER, FIRST_LOCAL_REGISTER + 2,
};
#define MUTABLE_COUNT ((int)(sizeof(mutableRegisters) / sizeof(mutableRegisters[0])))

static int runAccessorDifferential(void) {
  int before = failures;

  buildFixture();
  for(int i = 0; i < SWEEP_COUNT; i++) {
    const calcRegister_t r = sweepRegisters[i];

    if(getRegisterDataType(r) != oracle_getRegisterDataType(r)) {
      fail("getRegisterDataType(%d): z47=%u c43=%u", r, getRegisterDataType(r), oracle_getRegisterDataType(r));
    }
    if(getRegisterDataPointer(r) != oracle_getRegisterDataPointer(r)) {
      fail("getRegisterDataPointer(%d): z47=%p c43=%p", r, getRegisterDataPointer(r), oracle_getRegisterDataPointer(r));
    }
    if(getRegisterTag(r) != oracle_getRegisterTag(r)) {
      fail("getRegisterTag(%d): z47=%u c43=%u", r, getRegisterTag(r), oracle_getRegisterTag(r));
    }
    if(getRegisterMaxDataLengthInBlocks(r) != oracle_getRegisterMaxDataLengthInBlocks(r)) {
      fail("getRegisterMaxDataLengthInBlocks(%d): z47=%u c43=%u", r,
           getRegisterMaxDataLengthInBlocks(r), oracle_getRegisterMaxDataLengthInBlocks(r));
    }
    if(getRegisterFullSizeInBlocks(r) != oracle_getRegisterFullSizeInBlocks(r)) {
      fail("getRegisterFullSizeInBlocks(%d): z47=%u c43=%u", r,
           getRegisterFullSizeInBlocks(r), oracle_getRegisterFullSizeInBlocks(r));
    }
    if(namedVariableIsStats(r) != oracle_namedVariableIsStats(r)) {
      fail("namedVariableIsStats(%d): z47=%d c43=%d", r, namedVariableIsStats(r), oracle_namedVariableIsStats(r));
    }
  }

  if(failures == before) {
    printf("PASS: the metadata accessors agree with c43 over %d registers\n", SWEEP_COUNT);
  }
  return failures - before;
}

// ---------------------------------------------------------------------------
// Check 3 -- the mutators. Each case is a seed/run/snapshot pair.
// ---------------------------------------------------------------------------
static calcRegister_t caseRegister;
static uint32_t caseDataType;
static uint16_t caseSize;
static uint32_t caseTag;
static const char *caseName;

static void zigReallocate(void)    { reallocateRegister(caseRegister, caseDataType, caseSize, caseTag); }
static void c43Reallocate(void)    { oracle_reallocateRegister(caseRegister, caseDataType, caseSize, caseTag); }
static void zigClear(void)         { clearRegister(caseRegister); }
static void c43Clear(void)         { oracle_clearRegister(caseRegister); }
static void zigSetDataType(void)   { setRegisterDataType(caseRegister, (uint16_t)caseDataType, caseTag); }
static void c43SetDataType(void)   { oracle_setRegisterDataType(caseRegister, (uint16_t)caseDataType, caseTag); }
static void zigSetTag(void)        { setRegisterTag(caseRegister, caseTag); }
static void c43SetTag(void)        { oracle_setRegisterTag(caseRegister, caseTag); }
static void zigSetMaxLen(void)     { setRegisterMaxDataLengthInBlocks(caseRegister, caseSize); }
static void c43SetMaxLen(void)     { oracle_setRegisterMaxDataLengthInBlocks(caseRegister, caseSize); }
static void zigAllocLocal(void)    { allocateLocalRegisters(caseSize); }
static void c43AllocLocal(void)    { oracle_allocateLocalRegisters(caseSize); }
static void zigAllocNamed(void)    { allocateNamedVariable(caseName, caseDataType, caseSize); }
static void c43AllocNamed(void)    { oracle_allocateNamedVariable(caseName, caseDataType, caseSize); }
static void zigFindOrAlloc(void)   { (void)findOrAllocateNamedVariable(caseName); }
static void c43FindOrAlloc(void)   { (void)oracle_findOrAllocateNamedVariable(caseName); }
static void zigDeleteVar(void)     { fnDeleteVariable((uint16_t)caseRegister); }
static void c43DeleteVar(void)     { oracle_fnDeleteVariable((uint16_t)caseRegister); }
static void zigClamp(void)         { clampShortIntegerRegistersToWordSize(); }
static void c43Clamp(void)         { oracle_clampShortIntegerRegistersToWordSize(); }

static calcRegister_t caseSource;
static void zigCopy(void)          { copySourceRegisterToDestRegister(caseSource, caseRegister); }
static void c43Copy(void)          { oracle_copySourceRegisterToDestRegister(caseSource, caseRegister); }

static const struct {
  const char *name;
  calcRegister_t regist;
  uint32_t dataType;
  uint16_t size;
  uint32_t tag;
} reallocateCases[] = {
  {"reallocateRegister X -> real34",        REGISTER_X, dtReal34, 0, amNone},
  {"reallocateRegister X -> real34 tagged", REGISTER_X, dtReal34, 0, amDegree},
  {"reallocateRegister X -> complex34",     REGISTER_X, dtComplex34, 0, amNone},
  {"reallocateRegister X -> shortInteger",  REGISTER_X, dtShortInteger, 0, 16},
  {"reallocateRegister X -> longInteger",   REGISTER_X, dtLongInteger, 4, 0},
  {"reallocateRegister X -> string",        REGISTER_X, dtString, 5, amNone},
  {"reallocateRegister X -> time",          REGISTER_X, dtTime, 0, amNone},
  {"reallocateRegister X -> date",          REGISTER_X, dtDate, 0, amNone},
  {"reallocateRegister C shrink string",    REGISTER_C, dtString, 1, amNone},
  {"reallocateRegister C grow string",      REGISTER_C, dtString, 40, amNone},
  {"reallocateRegister matrix -> real34",   10, dtReal34, 0, amNone},
  {"reallocateRegister named -> string",    FIRST_NAMED_VARIABLE, dtString, 6, amNone},
  {"reallocateRegister local -> longInt",   FIRST_LOCAL_REGISTER, dtLongInteger, 2, 0},
  {"reallocateRegister lettered reserved",  FIRST_RESERVED_VARIABLE, dtReal34, 0, amNone},
  {"reallocateRegister SPARE1",             FIRST_RESERVED_VARIABLE + 26, dtReal34, 0, amNone},
  {"reallocateRegister ACC",                FIRST_NAMED_RESERVED_VARIABLE, dtReal34, 0, amNone},
  // NO out-of-range case here. c43 indexes its arrays unguarded, so
  // reallocateRegister(LAST_LOCAL_REGISTER + 1, ...) is undefined behaviour in the
  // reference -- it writes past currentLocalRegisters and then segfaults. z47's
  // isValidRegisterId guard raises ERROR_UNDEF_SOURCE_VAR instead. That is a
  // DELIBERATE divergence from REPORT-30's memory-safety programme, not a parity
  // defect, and a differential must not ask its reference to do something
  // undefined: the answer would be whatever that build's stack happened to hold.
};

static const struct {
  const char *name;
  calcRegister_t source;
  calcRegister_t dest;
} copyCases[] = {
  {"copy real34 -> real34",           REGISTER_X, REGISTER_Y},
  {"copy longInteger -> real34",      REGISTER_B, REGISTER_Y},
  {"copy string -> real34",           REGISTER_C, REGISTER_Y},
  {"copy matrix -> real34",           10, REGISTER_Y},
  {"copy named -> stack",             FIRST_NAMED_VARIABLE, REGISTER_Y},
  {"copy stack -> named",             REGISTER_X, FIRST_NAMED_VARIABLE},
  {"copy local -> stack",             FIRST_LOCAL_REGISTER, REGISTER_Y},
  {"copy lettered reserved -> stack", FIRST_RESERVED_VARIABLE, REGISTER_Y},
  {"copy stack -> lettered reserved", REGISTER_X, FIRST_RESERVED_VARIABLE + 1},
  {"copy SPARE1 -> stack",            FIRST_RESERVED_VARIABLE + 26, REGISTER_Y},
  {"copy SPARE5 -> stack",            FIRST_RESERVED_VARIABLE + 30, REGISTER_Y},
  {"copy ACC -> stack",               FIRST_NAMED_RESERVED_VARIABLE, REGISTER_Y},
};

static const char *const nameCases[] = {
  "ACC", "ADM", "D.MAX", "TESTVAR", "NEWVAR", "X", "Y", "A",
  "", "1BAD", "toolongname", "STRV", "PV", "FV", "GRAMOD", "+",
};
#define NAME_CASE_COUNT ((int)(sizeof(nameCases) / sizeof(nameCases[0])))

static int runMutatorDifferential(void) {
  int before = failures;

  for(size_t i = 0; i < sizeof(reallocateCases) / sizeof(reallocateCases[0]); i++) {
    caseRegister = reallocateCases[i].regist;
    caseDataType = reallocateCases[i].dataType;
    caseSize = reallocateCases[i].size;
    caseTag = reallocateCases[i].tag;
    diffCase(reallocateCases[i].name, zigReallocate, c43Reallocate);
  }

  for(int i = 0; i < MUTABLE_COUNT; i++) {
    char label[96];
    caseRegister = mutableRegisters[i];
    snprintf(label, sizeof(label), "clearRegister(%d)", caseRegister);
    diffCase(label, zigClear, c43Clear);

    caseSize = 7;
    snprintf(label, sizeof(label), "setRegisterMaxDataLengthInBlocks(%d, 7)", caseRegister);
    diffCase(label, zigSetMaxLen, c43SetMaxLen);
  }

  // The descriptor-only mutators touch no payload, so they take the whole sweep
  // including the reserved range -- which is where the interesting behaviour is:
  // a reserved variable's type and tag are fixed, and both sides have to refuse.
  for(int i = 0; i < SWEEP_COUNT; i++) {
    char label[96];
    caseRegister = sweepRegisters[i];

    caseDataType = dtReal34;
    caseTag = amRadian;
    snprintf(label, sizeof(label), "setRegisterDataType(%d, dtReal34, amRadian)", caseRegister);
    diffCase(label, zigSetDataType, c43SetDataType);

    caseTag = amGrad;
    snprintf(label, sizeof(label), "setRegisterTag(%d, amGrad)", caseRegister);
    diffCase(label, zigSetTag, c43SetTag);
  }

  for(size_t i = 0; i < sizeof(copyCases) / sizeof(copyCases[0]); i++) {
    caseSource = copyCases[i].source;
    caseRegister = copyCases[i].dest;
    diffCase(copyCases[i].name, zigCopy, c43Copy);
  }

  for(int i = 0; i < NAME_CASE_COUNT; i++) {
    char label[96];
    caseName = nameCases[i];
    caseDataType = dtReal34;
    caseSize = REAL34_SIZE_IN_BLOCKS;
    snprintf(label, sizeof(label), "allocateNamedVariable(\"%s\")", caseName);
    diffCase(label, zigAllocNamed, c43AllocNamed);

    snprintf(label, sizeof(label), "findOrAllocateNamedVariable(\"%s\")", caseName);
    diffCase(label, zigFindOrAlloc, c43FindOrAlloc);

    buildFixture();
    if(findNamedVariable(caseName) != oracle_findNamedVariable(caseName)) {
      fail("findNamedVariable(\"%s\"): z47=%d c43=%d", caseName,
           findNamedVariable(caseName), oracle_findNamedVariable(caseName));
    }
    if(validateName(caseName) != oracle_validateName(caseName)) {
      fail("validateName(\"%s\"): z47=%d c43=%d", caseName,
           validateName(caseName), oracle_validateName(caseName));
    }
    if(isUniqueMenuName(caseName) != oracle_isUniqueMenuName(caseName)) {
      fail("isUniqueMenuName(\"%s\"): z47=%d c43=%d", caseName,
           isUniqueMenuName(caseName), oracle_isUniqueMenuName(caseName));
    }
  }

  for(uint16_t n = 0; n <= 4; n++) {
    char label[64];
    caseSize = n;
    snprintf(label, sizeof(label), "allocateLocalRegisters(%u)", n);
    diffCase(label, zigAllocLocal, c43AllocLocal);
  }

  caseRegister = FIRST_NAMED_VARIABLE;
  diffCase("fnDeleteVariable(first named)", zigDeleteVar, c43DeleteVar);

  diffCase("clampShortIntegerRegistersToWordSize", zigClamp, c43Clamp);

  if(failures == before) {
    printf("PASS: the register mutators agree with c43 (state compared wholesale after each)\n");
  }
  return failures - before;
}

// ---------------------------------------------------------------------------
// Check 4 -- isFunctionAllowingNewVariable, the item-code predicate. Pure, and a
// table of item codes is exactly the shape a hand-written oracle gets wrong the
// way FLAG_IMPLOT was wrong: by omitting a member nobody named in a case.
// ---------------------------------------------------------------------------
static int runFunctionPredicateDifferential(void) {
  int before = failures;

  for(int16_t item = 0; item < LAST_ITEM; item++) {
    if(isFunctionAllowingNewVariable(item) != oracle_isFunctionAllowingNewVariable(item)) {
      fail("isFunctionAllowingNewVariable(%d): z47=%d c43=%d", item,
           isFunctionAllowingNewVariable(item), oracle_isFunctionAllowingNewVariable(item));
    }
  }

  if(failures == before) {
    printf("PASS: isFunctionAllowingNewVariable agrees with c43 over all %d item codes\n", LAST_ITEM);
  }
  return failures - before;
}

int main(void) {
  mp_set_memory_functions(allocGmp, reallocGmp, freeGmp);

  runReservedVariableTableDifferential();
  runAccessorDifferential();
  runMutatorDifferential();
  runFunctionPredicateDifferential();

  if(failures != 0) {
    printf("REGISTER-METADATA PARITY: %d check(s) FAILED\n", failures);
    return 1;
  }
  printf("REGISTER-METADATA PARITY: OK\n");
  return 0;
}
