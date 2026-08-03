// SPDX-License-Identifier: GPL-3.0-only
//
// Full-core differential for the math command wrappers: c43's own
// mathematics/*.c, compiled under `oracle_` names, run side by side with the Zig
// owners that replaced them and compared on the STATE each leaves behind.
//
// WHAT IS COMPARED, AND WHY IT IS STATE. The register file, the RAM slab, the
// error code and `temporaryInformation` after the call -- not which runtime
// functions the wrapper called on the way. A call-count comparison passes when a
// wrapper dispatches the same way and computes the wrong answer, and it fails
// when a refactor changes the call pattern without changing behaviour. Both are
// the wrong verdict. The snapshot is taken WHOLESALE (memcmp over the slab)
// because an enumerated one can forget a field.
//
// The environment is a full core, so both sides run on real decNumber, the real
// register file and the real constant blob. That is what makes results
// comparable at all: these wrappers dispatch into the arithmetic, so a harness
// that models the arithmetic measures the model.
//
// Each side runs from a REBUILT fixture. A full core carries far more state than
// a unit harness, so running the two back to back would compare c43 against a
// calculator the Zig owner had already changed.
//
// Nothing here may be edited to make the lane pass.

#include "c47.h"

#include <stdarg.h>
#include <stdio.h>
#include <string.h>

// Screen/GUI globals the core references; normally testSuite.c's. Headless here.
GtkWidget      *screen;
calcKeyboard_t  calcKeyboard[43];
int             currentBezel;
int16_t         screenStride;
uint32_t       *screenData;
bool_t          screenChange;

// ---------------------------------------------------------------------------
// The two implementations. Unprefixed names are the Zig owner's exports
// (declared by upstream's own headers via <c47.h>); `oracle_` ones are c43's own
// bodies, compiled a second time in math_wrappers_full_core_oracle.c.
// ---------------------------------------------------------------------------
// The two owner exports <c47.h> does not declare. c43 gives fnCheckReal external
// linkage in checkValue.c and names it in no header; fnToRect it keeps static in
// toRect.c, so the name is c43's but the linkage is the owner's alone.
void fnCheckReal(uint16_t unusedButMandatoryParameter);
void fnToRect(uint16_t angleInY);

void oracle_fnCheckAngle(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckForZero(uint16_t mode);
void oracle_fnCheckGreaterEqualPlusZero(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckInfinite(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckInteger(uint16_t mode);
void oracle_fnCheckIsVect2d(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckIsVect3d(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckLessEqualMinusZero(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckMatrix(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckMatrixSquare(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckMinusZero(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckNaN(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckNumber(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckPlusZero(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckReal(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckSpecial(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckType(uint16_t type);
void oracle_fnGetType(uint16_t unusedButMandatoryParameter);
void oracle_fnRound(uint16_t unusedButMandatoryParameter);
void oracle_fnSquareRoot(uint16_t unusedButMandatoryParameter);
void oracle_fnCubeRoot(uint16_t unusedButMandatoryParameter);
void oracle_fnArcsin(uint16_t unusedButMandatoryParameter);
void oracle_fnArccos(uint16_t unusedButMandatoryParameter);
void oracle_fnArctan(uint16_t unusedButMandatoryParameter);
void oracle_fnArcsinh(uint16_t unusedButMandatoryParameter);
void oracle_fnArccosh(uint16_t unusedButMandatoryParameter);
void oracle_fnArctanh(uint16_t unusedButMandatoryParameter);
void oracle_fnSin(uint16_t unusedButMandatoryParameter);
void oracle_fnCos(uint16_t unusedButMandatoryParameter);
void oracle_fnTan(uint16_t unusedButMandatoryParameter);
void oracle_fnSinh(uint16_t unusedButMandatoryParameter);
void oracle_fnCosh(uint16_t unusedButMandatoryParameter);
void oracle_fnTanh(uint16_t unusedButMandatoryParameter);
void oracle_fnLn(uint16_t unusedButMandatoryParameter);
void oracle_fnLnP1(uint16_t unusedButMandatoryParameter);
void oracle_fnLog10(uint16_t unusedButMandatoryParameter);
void oracle_fnLog2(uint16_t unusedButMandatoryParameter);
void oracle_fnExp(uint16_t unusedButMandatoryParameter);
void oracle_fnExpM1(uint16_t unusedButMandatoryParameter);
void oracle_fnIDiv(uint16_t unusedButMandatoryParameter);
void oracle_fnIDivR(uint16_t unusedButMandatoryParameter);
void oracle_fnXAlmostEqual(uint16_t regist);
void oracle_fnXEqualsTo(uint16_t regist);
void oracle_fnXGreaterEqual(uint16_t regist);
void oracle_fnXGreaterThan(uint16_t regist);
void oracle_fnXLessEqual(uint16_t regist);
void oracle_fnXLessThan(uint16_t regist);
void oracle_fnXNotEqual(uint16_t regist);
void oracle_fnIsConverged(uint16_t mode);
void oracle_fnAtan2(uint16_t unusedButMandatoryParameter);
void oracle_fnConjugate(uint16_t unusedButMandatoryParameter);
void oracle_fnSwapRealImaginary(uint16_t unusedButMandatoryParameter);
void oracle_fnToPolar2(uint16_t unusedButMandatoryParameter);
void oracle_fnToRect2(uint16_t unusedButMandatoryParameter);
// Not oracle_-prefixed on purpose: c43's fnToRect is static and takes an int8_t,
// so this is the oracle file's adapter over it rather than c43's own body.
void oracleFnToRectEntry(uint16_t angleInY);
void oracle_fnUnitVector(uint16_t unusedButMandatoryParameter);
// curtReal and compareTypeErrorX are NOT compared here, and will not be. The
// question was asked properly and the answer is that exporting them would be the
// wrong fix.
//
// c43 has both as functions. z47 has neither as a SYMBOL: curtReal is a
// `callconv(.c)` local handed to a dispatcher, and compareTypeErrorX has no z47
// counterpart at all -- its two-line body (temporaryInformation = TI_FALSE, then
// badTypeError) is inlined into a local `typeErrorX` in check_value.zig and again
// in convergence.zig. Both spellings are faithful, including the REGISTER_T the
// error line carries: badTypeError passes REGISTER_T regardless of the register it
// is complaining about (registerValueConversions.c:959).
//
// Exporting them so this lane could diff them would add symbols to the shipped
// program for the test's benefit, which is exactly the seam
// check-owner-build-conditionals.py exists to keep out. A differential is not
// worth changing the product's symbol table for.
//
// They are covered indirectly and that is enough here: fnIDiv and the comparisons
// route their type errors through compareTypeErrorX, and the cube-root wrapper
// through curtReal, so a divergence in either still surfaces as a state mismatch
// in the cases below.

// typeError is the shared handler c43's headers reduce every per-file `*Error`
// to when EXTRA_INFO_ON_CALC_ERROR is not 1. It is not renamed, so both sides
// hold the same pointer in their dispatch tables' error slots.
void typeError(void);

// c43's five type-dispatch TABLES, renamed alongside the functions. A missed
// table would link silently against the Zig owner's, so main() names them.
extern void (*const oracle_idiv[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void);
extern void (*const oracle_idivr[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void);
extern void (*const oracle_arctan2[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void);
extern void (*const oracle_Round[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void);
extern void (*const oracle_unitVector[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void);

// The owner-side tables. c43 does not declare these in c47.h -- they are
// file-scope in mathematics/*.c. The Zig owner exports Round, idiv and idivr
// under c43's own names; arctan2, unitVector and curtReal it keeps internal, so
// only these three can be compared.
extern void (*const idiv[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void);
extern void (*const idivr[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void);
extern void (*const Round[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void);

static int failures = 0;

static void fail(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  printf("  FAIL: ");
  vprintf(fmt, ap);
  printf("\n");
  va_end(ap);
  failures++;
}

// ---------------------------------------------------------------------------
// The state both implementations share, snapshotted WHOLESALE.
// ---------------------------------------------------------------------------
typedef struct {
  registerHeader_t globalRegister[NUMBER_OF_GLOBAL_REGISTERS];
  uint8_t          lastErrorCode;
  uint8_t          temporaryInformation;
  uint64_t         systemFlags0;
  uint64_t         systemFlags1;
  uint32_t         freeMemoryBlocks;
  uint8_t          ram[RAM_SIZE_IN_BLOCKS * 4];
} snapshot_t;

static snapshot_t snapshotA;
static snapshot_t snapshotB;

// matrixHeader_t's top two bits are `notUsed` -- "2 bits free" in
// typeDefinitions.h:435 -- and neither implementation initialises them, so a
// freshly allocated header carries whatever the pool block last held. c43 treats
// them as junk too: saveRestoreBackup.c:51 clears them on the way out with the
// comment "clear spare bits and clear Polar flag, setting only amNone", so they
// never reach backup.cfg and cannot be observed by a user.
//
// Comparing them would be comparing uninitialised memory, which is not a parity
// question. They are zeroed in BOTH snapshots instead of the whole RAM slab being
// waived, so every other byte of every matrix -- header dimensions, mtag,
// elements -- is still held to c43.
// Keep only the RAM bytes that belong to a live register.
//
// A wrapper that converts a real matrix to a complex one allocates a temporary,
// writes it, copies it back and frees it. The freed block keeps whatever the two
// implementations last wrote there, and that residue differs without either
// being wrong -- it is memory nobody owns. Comparing it compares garbage.
//
// The alternative used elsewhere in the tree is to waive the whole RAM slab for
// such cases, which also drops the matrix ELEMENTS -- the bytes these families
// exist to get right. Masking to live extents keeps those and drops only the
// unowned bytes.
//
// The mask covers every register class that can own pool memory: the globals
// (which include the stack and last-X), the reserved variables, the named
// variables and the current local frame. Anything outside all of those is memory
// no register owns.
static void markLive(uint8_t *live, size_t liveLen, calcRegister_t reg) {
  const uint8_t *data = (const uint8_t *)getRegisterDataPointer(reg);
  if(data == NULL) {
    return;
  }
  const ptrdiff_t base = data - (const uint8_t *)ram;
  const ptrdiff_t size = (ptrdiff_t)getRegisterFullSizeInBlocks(reg) * 4;
  if(base < 0 || size <= 0 || base + size > (ptrdiff_t)liveLen) {
    return;
  }
  memset(live + base, 1, (size_t)size);
}

static void keepOnlyLiveRegisterBytes(snapshot_t *out) {
  static uint8_t live[RAM_SIZE_IN_BLOCKS * 4];
  memset(live, 0, sizeof(live));

  for(int reg = 0; reg < NUMBER_OF_GLOBAL_REGISTERS; reg++) {
    markLive(live, sizeof(live), (calcRegister_t)reg);
  }
  for(int v = FIRST_RESERVED_VARIABLE; v <= LAST_RESERVED_VARIABLE; v++) {
    markLive(live, sizeof(live), (calcRegister_t)v);
  }
  for(int v = 0; v < numberOfNamedVariables; v++) {
    markLive(live, sizeof(live), (calcRegister_t)(FIRST_NAMED_VARIABLE + v));
  }
  for(int v = 0; v < currentNumberOfLocalRegisters; v++) {
    markLive(live, sizeof(live), (calcRegister_t)(FIRST_LOCAL_REGISTER + v));
  }

  for(size_t i = 0; i < sizeof(out->ram); i++) {
    if(!live[i]) {
      out->ram[i] = 0;
    }
  }
}

static void normalizeMatrixHeaderSpareBits(snapshot_t *out) {
  for(int reg = 0; reg < NUMBER_OF_GLOBAL_REGISTERS; reg++) {
    const uint32_t dt = out->globalRegister[reg].dataType;
    if(dt != dtReal34Matrix && dt != dtComplex34Matrix) {
      continue;
    }
    const uint8_t *live = (const uint8_t *)getRegisterDataPointer(reg);
    if(live == NULL) {
      continue;
    }
    const ptrdiff_t offset = live - (const uint8_t *)ram;
    if(offset < 0 || (size_t)offset + 4 > sizeof(out->ram)) {
      continue;
    }
    out->ram[offset + 3] &= 0x3f; // keep mtag's 6 bits, drop the 2 spare
  }
}

static void takeSnapshot(snapshot_t *out) {
  memset(out, 0, sizeof(*out));
  memcpy(out->globalRegister, globalRegister, sizeof(out->globalRegister));
  out->lastErrorCode = lastErrorCode;
  out->temporaryInformation = temporaryInformation;
  out->systemFlags0 = systemFlags0;
  out->systemFlags1 = systemFlags1;
  out->freeMemoryBlocks = getFreeRamMemory();
  memcpy(out->ram, ram, sizeof(out->ram));
  keepOnlyLiveRegisterBytes(out);
  normalizeMatrixHeaderSpareBits(out);
}

static int reportSnapshotMismatch(const char *caseName) {
  if(memcmp(&snapshotA, &snapshotB, sizeof(snapshotA)) == 0) {
    return 0;
  }
  const int before = failures;

  if(snapshotA.temporaryInformation != snapshotB.temporaryInformation) {
    fail("%s: temporaryInformation z47=%u c43=%u", caseName,
         snapshotA.temporaryInformation, snapshotB.temporaryInformation);
  }
  if(snapshotA.lastErrorCode != snapshotB.lastErrorCode) {
    fail("%s: lastErrorCode z47=%u c43=%u", caseName,
         snapshotA.lastErrorCode, snapshotB.lastErrorCode);
  }
  if(memcmp(snapshotA.globalRegister, snapshotB.globalRegister, sizeof(snapshotA.globalRegister)) != 0) {
    for(int i = 0; i < NUMBER_OF_GLOBAL_REGISTERS; i++) {
      if(memcmp(&snapshotA.globalRegister[i], &snapshotB.globalRegister[i], sizeof(registerHeader_t)) != 0) {
        fail("%s: globalRegister[%d] z47(ptr=%u dt=%u tag=%u) c43(ptr=%u dt=%u tag=%u)",
             caseName, i,
             snapshotA.globalRegister[i].pointerToRegisterData, snapshotA.globalRegister[i].dataType,
             snapshotA.globalRegister[i].tag,
             snapshotB.globalRegister[i].pointerToRegisterData, snapshotB.globalRegister[i].dataType,
             snapshotB.globalRegister[i].tag);
      }
    }
  }
  if(snapshotA.systemFlags0 != snapshotB.systemFlags0 || snapshotA.systemFlags1 != snapshotB.systemFlags1) {
    fail("%s: systemFlags z47=%016llx/%016llx c43=%016llx/%016llx", caseName,
         (unsigned long long)snapshotA.systemFlags0, (unsigned long long)snapshotA.systemFlags1,
         (unsigned long long)snapshotB.systemFlags0, (unsigned long long)snapshotB.systemFlags1);
  }
  if(snapshotA.freeMemoryBlocks != snapshotB.freeMemoryBlocks) {
    fail("%s: freeMemoryBlocks z47=%u c43=%u", caseName,
         snapshotA.freeMemoryBlocks, snapshotB.freeMemoryBlocks);
  }
  if(memcmp(snapshotA.ram, snapshotB.ram, sizeof(snapshotA.ram)) != 0) {
    for(size_t i = 0; i < sizeof(snapshotA.ram); i++) {
      if(snapshotA.ram[i] != snapshotB.ram[i]) {
        // Name the register that owns the byte. A bare offset says a matrix
        // differs somewhere; the owner and the offset within it say which.
        int owner = -1;
        ptrdiff_t within = 0;
        for(int reg = 0; reg < NUMBER_OF_GLOBAL_REGISTERS; reg++) {
          const uint8_t *live = (const uint8_t *)getRegisterDataPointer(reg);
          if(live == NULL) {
            continue;
          }
          const ptrdiff_t base = live - (const uint8_t *)ram;
          const ptrdiff_t size = (ptrdiff_t)getRegisterFullSizeInBlocks(reg) * 4;
          if((ptrdiff_t)i >= base && (ptrdiff_t)i < base + size) {
            owner = reg;
            within = (ptrdiff_t)i - base;
            break;
          }
        }
        if(owner >= 0) {
          fail("%s: ram[%zu] z47=0x%02x c43=0x%02x (register %d, byte %ld of its data)",
               caseName, i, snapshotA.ram[i], snapshotB.ram[i], owner, (long)within);
        } else {
          fail("%s: ram[%zu] z47=0x%02x c43=0x%02x (not inside any live register)",
               caseName, i, snapshotA.ram[i], snapshotB.ram[i]);
        }
        break;
      }
    }
  }
  // The wholesale memcmp disagreed but no named field did. Report rather than
  // pass: the snapshot is the contract and something inside it moved.
  if(failures == before) {
    fail("%s: snapshots differ in a field this reporter does not name", caseName);
  }
  return 1;
}

// ---------------------------------------------------------------------------
// Fixtures. Each seeds register X into one shape the predicates branch on.
// ---------------------------------------------------------------------------
static void seedRealPositive(void) {
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  int32ToReal34(1234, REGISTER_REAL34_DATA(REGISTER_X));
}

static void seedRealWithAngle(void) {
  reallocateRegister(REGISTER_X, dtReal34, 0, amDegree);
  int32ToReal34(90, REGISTER_REAL34_DATA(REGISTER_X));
}

static void seedRealFraction(void) {
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  stringToReal34("1.5", REGISTER_REAL34_DATA(REGISTER_X));
}

static void seedRealEven(void) {
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  int32ToReal34(42, REGISTER_REAL34_DATA(REGISTER_X));
}

static void seedRealOdd(void) {
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  int32ToReal34(43, REGISTER_REAL34_DATA(REGISTER_X));
}

static void seedRealPlusZero(void) {
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  stringToReal34("0", REGISTER_REAL34_DATA(REGISTER_X));
}

static void seedRealMinusZero(void) {
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  stringToReal34("-0", REGISTER_REAL34_DATA(REGISTER_X));
}

static void seedRealNaN(void) {
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  stringToReal34("NaN", REGISTER_REAL34_DATA(REGISTER_X));
}

static void seedRealInfinity(void) {
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  stringToReal34("Infinity", REGISTER_REAL34_DATA(REGISTER_X));
}

static void seedComplex(void) {
  reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
  int32ToReal34(3, REGISTER_REAL34_DATA(REGISTER_X));
  int32ToReal34(4, REGISTER_IMAG34_DATA(REGISTER_X));
}

static void seedComplexRealZero(void) {
  reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
  stringToReal34("0", REGISTER_REAL34_DATA(REGISTER_X));
  int32ToReal34(4, REGISTER_IMAG34_DATA(REGISTER_X));
}

static void seedComplexImagZero(void) {
  reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
  int32ToReal34(3, REGISTER_REAL34_DATA(REGISTER_X));
  stringToReal34("0", REGISTER_IMAG34_DATA(REGISTER_X));
}

static void seedShortInteger(void) {
  convertUInt64ToShortIntegerRegister(0, 0xDEADBEEFULL, 16, REGISTER_X);
}

static void seedLongInteger(void) {
  longInteger_t li;
  longIntegerInit(li);
  stringToLongInteger("123456789012345678901234567890", 10, li);
  convertLongIntegerToLongIntegerRegister(li, REGISTER_X);
  longIntegerFree(li);
}

static void seedString(void) {
  const char *s = "register string";
  reallocateRegister(REGISTER_X, dtString, TO_BLOCKS((int)strlen(s) + 1), amNone);
  strcpy(REGISTER_STRING_DATA(REGISTER_X), s);
}

// A 2x3 real matrix: neither square nor a vector.
static void seedMatrix2x3(void) {
  initMatrixRegister(REGISTER_X, 2, 3, false);
  for(int e = 0; e < 6; ++e) {
    int32ToReal34(e * 10 + 1, REGISTER_REAL34_MATRIX_ELEMENTS(REGISTER_X) + e);
  }
}

static void seedMatrixSquare(void) {
  initMatrixRegister(REGISTER_X, 2, 2, false);
  for(int e = 0; e < 4; ++e) {
    int32ToReal34(e + 1, REGISTER_REAL34_MATRIX_ELEMENTS(REGISTER_X) + e);
  }
}

// 1x2: a 2d row vector.
static void seedVector2d(void) {
  initMatrixRegister(REGISTER_X, 1, 2, false);
  int32ToReal34(3, REGISTER_REAL34_MATRIX_ELEMENTS(REGISTER_X) + 0);
  int32ToReal34(4, REGISTER_REAL34_MATRIX_ELEMENTS(REGISTER_X) + 1);
}

// 1x3: a 3d row vector.
static void seedVector3d(void) {
  initMatrixRegister(REGISTER_X, 1, 3, false);
  for(int e = 0; e < 3; ++e) {
    int32ToReal34(e + 1, REGISTER_REAL34_MATRIX_ELEMENTS(REGISTER_X) + e);
  }
}

// A COMPLEX matrix in X. Nothing in this tree has ever seeded one: this harness
// named dtComplex34Matrix in exactly one place -- normalizeMatrixHeaderSpareBits,
// which normalises a matrix register's spare header bits before comparison -- so
// the lane was prepared to COMPARE a complex matrix register and never to CREATE
// one. Every wrapper that dispatches on dtComplex34Matrix took its real-matrix or
// scalar branch here and its complex-matrix branch nowhere.
static void seedComplexMatrix(void) {
  initMatrixRegister(REGISTER_X, 2, 2, true);
  for(int e = 0; e < 4; ++e) {
    int32ToReal34(e + 1, VARIABLE_REAL34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(REGISTER_X) + e));
    int32ToReal34(-(e + 1), VARIABLE_IMAG34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(REGISTER_X) + e));
  }
}

// The same, with a zero imaginary part in every element AND special results off.
// conjCxma restores a POSITIVE sign on a zero imaginary part only when SPCRES is
// clear, and both halves of that condition have to be arranged: a fixture whose
// imaginary parts are all non-zero never reaches the line, and this harness leaves
// SPCRES at its reset value, which is SET. Without the clear below, deleting the
// restore from the Zig owner changes nothing that either side computes -- measured,
// not assumed: that mutant survived until this line existed.
static void seedComplexMatrixImagZero(void) {
  initMatrixRegister(REGISTER_X, 1, 2, true);
  for(int e = 0; e < 2; ++e) {
    int32ToReal34(e + 1, VARIABLE_REAL34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(REGISTER_X) + e));
    real34SetZero(VARIABLE_IMAG34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(REGISTER_X) + e));
  }
  clearSystemFlag(FLAG_SPCRES);
}

static void seedTime(void) {
  reallocateRegister(REGISTER_X, dtTime, 0, amNone);
  int32ToReal34(12345, REGISTER_REAL34_DATA(REGISTER_X));
}

typedef struct {
  const char *name;
  void      (*seed)(void);
} fixture_t;

// ---------------------------------------------------------------------------
// The SIGN partition.
//
// The shapes above enumerate DATA TYPES exhaustively and every one of them is
// non-negative: seedRealPositive is 1234, seedRealEven 42, seedRealOdd 43,
// seedRealWithAngle +90 degrees, seedShortInteger 0xDEADBEEF with sign 0,
// seedLongInteger +123456789012345678901234567890. Only realMinusZero carried a
// sign, and it is a boundary rather than a magnitude -- so X was never negative in
// any case this lane ran, while src/core/numeric/ branches on sign at 265 sites.
//
// It was demonstrable rather than theoretical: deleting the negative-infinity sign
// handling from arctanReal, so that arctan(-inf) answers +90 degrees instead of
// -90, left every case in this lane agreeing.
//
// A partition is only as good as the list of properties it was drawn over. This is
// the second property; PARTITION_PROPERTIES below is the list.
// ---------------------------------------------------------------------------

static void seedRealNegative(void) {
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  int32ToReal34(-1234, REGISTER_REAL34_DATA(REGISTER_X));
}

static void seedRealNegativeFraction(void) {
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  stringToReal34("-1.5", REGISTER_REAL34_DATA(REGISTER_X));
}

static void seedRealNegativeInfinity(void) {
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  stringToReal34("-Infinity", REGISTER_REAL34_DATA(REGISTER_X));
}

static void seedRealNegativeWithAngle(void) {
  reallocateRegister(REGISTER_X, dtReal34, 0, amDegree);
  int32ToReal34(-90, REGISTER_REAL34_DATA(REGISTER_X));
}

static void seedShortIntegerNegative(void) {
  convertUInt64ToShortIntegerRegister(1, 0xDEADBEEFULL, 16, REGISTER_X);
}

static void seedLongIntegerNegative(void) {
  longInteger_t li;
  longIntegerInit(li);
  stringToLongInteger("-123456789012345678901234567890", 10, li);
  convertLongIntegerToLongIntegerRegister(li, REGISTER_X);
  longIntegerFree(li);
}

// The +-1 boundary. arcsin, arccos, arctanh and arccosh all branch on |x| > 1, and
// the nearest fixtures were 1.5 and 0 -- so the edge itself, where boundary value
// analysis says the errors cluster, was on neither side of any comparison.
static void seedRealOne(void) {
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  int32ToReal34(1, REGISTER_REAL34_DATA(REGISTER_X));
}

static void seedRealMinusOne(void) {
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  int32ToReal34(-1, REGISTER_REAL34_DATA(REGISTER_X));
}

static const fixture_t FIXTURES[] = {
  { "realPositive",    seedRealPositive    },
  { "realWithAngle",   seedRealWithAngle   },
  { "realFraction",    seedRealFraction    },
  { "realEven",        seedRealEven        },
  { "realOdd",         seedRealOdd         },
  { "realPlusZero",    seedRealPlusZero    },
  { "realMinusZero",   seedRealMinusZero   },
  { "realNaN",         seedRealNaN         },
  { "realInfinity",    seedRealInfinity    },
  { "complex",         seedComplex         },
  { "complexRealZero", seedComplexRealZero },
  { "complexImagZero", seedComplexImagZero },
  { "shortInteger",    seedShortInteger    },
  { "longInteger",     seedLongInteger     },
  { "string",          seedString          },
  { "matrix2x3",       seedMatrix2x3       },
  { "matrixSquare",    seedMatrixSquare    },
  { "vector2d",        seedVector2d        },
  { "vector3d",        seedVector3d        },
  { "complexMatrix",   seedComplexMatrix   },
  { "complexMatrixImagZero", seedComplexMatrixImagZero },
  { "time",            seedTime            },

  // The sign partition, and the +-1 boundary.
  { "realNegative",          seedRealNegative          },
  { "realNegativeFraction",  seedRealNegativeFraction  },
  { "realNegativeInfinity",  seedRealNegativeInfinity  },
  { "realNegativeWithAngle", seedRealNegativeWithAngle },
  { "shortIntegerNegative",  seedShortIntegerNegative  },
  { "longIntegerNegative",   seedLongIntegerNegative   },
  { "realOne",               seedRealOne               },
  { "realMinusOne",          seedRealMinusOne          },
};

typedef struct {
  const char *name;
  void      (*owner)(uint16_t);
  void      (*oracle)(uint16_t);
  uint16_t    param;
} predicate_t;

// Every predicate runs against every register shape: a predicate's whole job is
// to discriminate between shapes, and a fixture that only ever presents one
// cannot tell a working discriminator from a constant.
//
// fnCheckType, fnCheckForZero and fnCheckInteger dispatch on their parameter, so
// each mode is its own entry. A pinned parameter hides every branch but one.
static const predicate_t PREDICATES[] = {
  { "fnCheckAngle",             fnCheckAngle,        oracle_fnCheckAngle,        0                  },
  { "fnCheckInfinite",          fnCheckInfinite,     oracle_fnCheckInfinite,     0                  },
  { "fnCheckIsVect2d",          fnCheckIsVect2d,     oracle_fnCheckIsVect2d,     0                  },
  { "fnCheckIsVect3d",          fnCheckIsVect3d,     oracle_fnCheckIsVect3d,     0                  },
  { "fnCheckMatrix",            fnCheckMatrix,       oracle_fnCheckMatrix,       0                  },
  { "fnCheckMatrixSquare",      fnCheckMatrixSquare, oracle_fnCheckMatrixSquare, 0                  },
  { "fnCheckMinusZero",         fnCheckMinusZero,    oracle_fnCheckMinusZero,    0                  },
  { "fnCheckNaN",               fnCheckNaN,          oracle_fnCheckNaN,          0                  },
  { "fnCheckNumber",            fnCheckNumber,       oracle_fnCheckNumber,       0                  },
  { "fnCheckPlusZero",          fnCheckPlusZero,     oracle_fnCheckPlusZero,     0                  },
  { "fnCheckSpecial",           fnCheckSpecial,      oracle_fnCheckSpecial,      0                  },
  { "fnGetType",                fnGetType,           oracle_fnGetType,           0                  },

  // checkValue.c's own entry points, compiled into the oracle since the predicates
  // above were added and driven by nothing until now. fnCheckReal has the further
  // claim on a place here: the unit lane's reference for it is hand-written, and
  // checkValue.c cannot compile against that lane's c47.h -- real34IsSpecial,
  // compareTypeErrorX, getRegisterAsComplexOrAnyRealQuiet, isMatrix2dVector and
  // the ITM_IS* items are all missing there. This is where c43's own body runs.
  { "fnCheckGreaterEqualPlusZero", fnCheckGreaterEqualPlusZero, oracle_fnCheckGreaterEqualPlusZero, 0 },
  { "fnCheckLessEqualMinusZero",   fnCheckLessEqualMinusZero,   oracle_fnCheckLessEqualMinusZero,   0 },
  { "fnCheckReal",              fnCheckReal,         oracle_fnCheckReal,         0                  },

  { "fnCheckType/longInteger",  fnCheckType,         oracle_fnCheckType,         dtLongInteger      },
  { "fnCheckType/real34",       fnCheckType,         oracle_fnCheckType,         dtReal34           },
  { "fnCheckType/complex34",    fnCheckType,         oracle_fnCheckType,         dtComplex34        },
  { "fnCheckType/string",       fnCheckType,         oracle_fnCheckType,         dtString           },
  { "fnCheckType/real34Matrix", fnCheckType,         oracle_fnCheckType,         dtReal34Matrix     },
  { "fnCheckType/shortInteger", fnCheckType,         oracle_fnCheckType,         dtShortInteger     },
  { "fnCheckType/time",         fnCheckType,         oracle_fnCheckType,         dtTime             },
  { "fnCheckType/date",         fnCheckType,         oracle_fnCheckType,         dtDate             },

  { "fnCheckForZero/ISREZQ",    fnCheckForZero,      oracle_fnCheckForZero,      ITM_ISREZQ         },
  { "fnCheckForZero/ISIMZQ",    fnCheckForZero,      oracle_fnCheckForZero,      ITM_ISIMZQ         },
  { "fnCheckForZero/ISRENZQ",   fnCheckForZero,      oracle_fnCheckForZero,      ITM_ISRENZQ        },
  { "fnCheckForZero/ISIMNZQ",   fnCheckForZero,      oracle_fnCheckForZero,      ITM_ISIMNZQ        },

  { "fnCheckInteger/EVEN",      fnCheckInteger,      oracle_fnCheckInteger,      CHECK_INTEGER_EVEN },
  { "fnCheckInteger/ODD",       fnCheckInteger,      oracle_fnCheckInteger,      CHECK_INTEGER_ODD  },
  { "fnCheckInteger/FP",        fnCheckInteger,      oracle_fnCheckInteger,      CHECK_INTEGER_FP   },

  // Unary on X but MUTATING: each saves last-X, writes a result and adjusts the
  // stack, so the register file and the RAM slab carry the verdict, not just
  // temporaryInformation.
  { "fnRound",                  fnRound,             oracle_fnRound,             0                  },

  // squareRoot.c and cubeRoot.c were compiled into the oracle for the leaves they
  // give the families above, and their own entry points were never driven.
  { "fnSquareRoot",             fnSquareRoot,        oracle_fnSquareRoot,        0                  },
  { "fnCubeRoot",               fnCubeRoot,          oracle_fnCubeRoot,          0                  },

  // The inverse-circular and inverse-hyperbolic family. Until now these had no
  // result-level comparison in any lane: the unit lane drives them over a fake
  // numeric core, so it compares the paths they take and never the numbers.
  { "fnArcsin",                fnArcsin,            oracle_fnArcsin,            0                  },
  { "fnArccos",                fnArccos,            oracle_fnArccos,            0                  },
  { "fnArctan",                fnArctan,            oracle_fnArctan,            0                  },
  { "fnArcsinh",               fnArcsinh,           oracle_fnArcsinh,           0                  },
  { "fnArccosh",               fnArccosh,           oracle_fnArccosh,           0                  },
  { "fnArctanh",               fnArctanh,           oracle_fnArctanh,           0                  },

  // The circular and hyperbolic families, same reason.
  { "fnSin",                   fnSin,               oracle_fnSin,               0                  },
  { "fnCos",                   fnCos,               oracle_fnCos,               0                  },
  { "fnTan",                   fnTan,               oracle_fnTan,               0                  },
  { "fnSinh",                  fnSinh,              oracle_fnSinh,              0                  },
  { "fnCosh",                  fnCosh,              oracle_fnCosh,              0                  },
  { "fnTanh",                  fnTanh,              oracle_fnTanh,              0                  },

  // The logarithmic and exponential families, same reason.
  { "fnLn",                    fnLn,                oracle_fnLn,                0                  },
  { "fnLnP1",                  fnLnP1,              oracle_fnLnP1,              0                  },
  { "fnLog10",                 fnLog10,             oracle_fnLog10,             0                  },
  { "fnLog2",                  fnLog2,              oracle_fnLog2,              0                  },
  { "fnExp",                   fnExp,               oracle_fnExp,               0                  },
  { "fnExpM1",                 fnExpM1,             oracle_fnExpM1,             0                  },

  // Vector and complex families. These are the ones the unit lane could never
  // host: they dispatch into the matrix and complex leaves, which that lane's
  // fake numeric core answers differently from real decNumber. Here both sides
  // run the same arithmetic, so the comparison is about the result.
  { "fnConjugate",              fnConjugate,         oracle_fnConjugate,         0                  },
  { "fnSwapRealImaginary",      fnSwapRealImaginary, oracle_fnSwapRealImaginary, 0                  },
  { "fnUnitVector",             fnUnitVector,        oracle_fnUnitVector,        0                  },
  { "fnToPolar2",               fnToPolar2,          oracle_fnToPolar2,          0                  },
  { "fnToRect2",                fnToRect2,           oracle_fnToRect2,           0                  },

  // fnToRect reads a SECOND register and swaps which of X and Y carries the angle
  // on its parameter, so both values are driven: a pinned one exercises one
  // assignment and calls the other covered.
  { "fnToRect/angleInX",        fnToRect,            oracleFnToRectEntry,        0                  },
  { "fnToRect/angleInY",        fnToRect,            oracleFnToRectEntry,        1                  },
};

// ---------------------------------------------------------------------------
// Binary operands. fnIDiv, fnIDivR, the seven comparisons and fnIsConverged all
// read a SECOND register, so they need a pair fixture; the unary table above
// leaves Y at its reset value and would compare every pair against the same one.
//
// Y and Z are seeded alike so the `regist` parameter can be swept: a comparison
// entry exists for both REGISTER_Y and REGISTER_Z, which is the difference
// between testing the function and testing one hardcoded operand.
// ---------------------------------------------------------------------------
typedef struct {
  const char *name;
  void      (*seedX)(void);
  void      (*seedSecond)(void);
} pair_t;

static void secondReal1234(void)     { reallocateRegister(REGISTER_Y, dtReal34, 0, amNone); int32ToReal34(1234, REGISTER_REAL34_DATA(REGISTER_Y));
                                       reallocateRegister(REGISTER_Z, dtReal34, 0, amNone); int32ToReal34(1234, REGISTER_REAL34_DATA(REGISTER_Z)); }
static void secondReal7(void)        { reallocateRegister(REGISTER_Y, dtReal34, 0, amNone); int32ToReal34(7, REGISTER_REAL34_DATA(REGISTER_Y));
                                       reallocateRegister(REGISTER_Z, dtReal34, 0, amNone); int32ToReal34(7, REGISTER_REAL34_DATA(REGISTER_Z)); }
static void secondRealMinus7(void)   { reallocateRegister(REGISTER_Y, dtReal34, 0, amNone); int32ToReal34(-7, REGISTER_REAL34_DATA(REGISTER_Y));
                                       reallocateRegister(REGISTER_Z, dtReal34, 0, amNone); int32ToReal34(-7, REGISTER_REAL34_DATA(REGISTER_Z)); }
static void secondRealZero(void)     { reallocateRegister(REGISTER_Y, dtReal34, 0, amNone); stringToReal34("0", REGISTER_REAL34_DATA(REGISTER_Y));
                                       reallocateRegister(REGISTER_Z, dtReal34, 0, amNone); stringToReal34("0", REGISTER_REAL34_DATA(REGISTER_Z)); }
static void secondRealNaN(void)      { reallocateRegister(REGISTER_Y, dtReal34, 0, amNone); stringToReal34("NaN", REGISTER_REAL34_DATA(REGISTER_Y));
                                       reallocateRegister(REGISTER_Z, dtReal34, 0, amNone); stringToReal34("NaN", REGISTER_REAL34_DATA(REGISTER_Z)); }
static void secondRealInfinity(void) { reallocateRegister(REGISTER_Y, dtReal34, 0, amNone); stringToReal34("Infinity", REGISTER_REAL34_DATA(REGISTER_Y));
                                       reallocateRegister(REGISTER_Z, dtReal34, 0, amNone); stringToReal34("Infinity", REGISTER_REAL34_DATA(REGISTER_Z)); }
static void secondComplex(void)      { reallocateRegister(REGISTER_Y, dtComplex34, 0, amNone); int32ToReal34(3, REGISTER_REAL34_DATA(REGISTER_Y)); int32ToReal34(4, REGISTER_IMAG34_DATA(REGISTER_Y));
                                       reallocateRegister(REGISTER_Z, dtComplex34, 0, amNone); int32ToReal34(3, REGISTER_REAL34_DATA(REGISTER_Z)); int32ToReal34(4, REGISTER_IMAG34_DATA(REGISTER_Z)); }
static void secondShortInteger(void) { convertUInt64ToShortIntegerRegister(0, 0x1FULL, 16, REGISTER_Y);
                                       convertUInt64ToShortIntegerRegister(0, 0x1FULL, 16, REGISTER_Z); }
static void secondString(void)       { const char *s = "second"; reallocateRegister(REGISTER_Y, dtString, TO_BLOCKS((int)strlen(s) + 1), amNone); strcpy(REGISTER_STRING_DATA(REGISTER_Y), s);
                                       reallocateRegister(REGISTER_Z, dtString, TO_BLOCKS((int)strlen(s) + 1), amNone); strcpy(REGISTER_STRING_DATA(REGISTER_Z), s); }

static const pair_t PAIRS[] = {
  { "real1234:real1234",   seedRealPositive,  secondReal1234     }, // equal
  { "real1234:real7",      seedRealPositive,  secondReal7        }, // greater
  { "real1234:real-7",     seedRealPositive,  secondRealMinus7   }, // greater, negative rhs
  { "realOdd:real7",       seedRealOdd,       secondReal7        }, // divides unevenly
  { "realEven:real7",      seedRealEven,      secondReal7        },
  { "realFraction:real7",  seedRealFraction,  secondReal7        },
  { "real1234:zero",       seedRealPositive,  secondRealZero     }, // divide by zero
  { "zero:zero",           seedRealPlusZero,  secondRealZero     },
  { "realNaN:real7",       seedRealNaN,       secondReal7        },
  { "real1234:NaN",        seedRealPositive,  secondRealNaN      },
  { "realInfinity:real7",  seedRealInfinity,  secondReal7        },
  { "real1234:infinity",   seedRealPositive,  secondRealInfinity },
  { "complex:complex",     seedComplex,       secondComplex      },
  { "complex:real7",       seedComplex,       secondReal7        },
  { "shortInteger:shortInteger", seedShortInteger, secondShortInteger },
  { "shortInteger:real7",  seedShortInteger,  secondReal7        },
  { "longInteger:real7",   seedLongInteger,   secondReal7        },
  { "string:real7",        seedString,        secondReal7        }, // type error
  { "matrix2x3:real7",     seedMatrix2x3,     secondReal7        },
  { "real1234:string",     seedRealPositive,  secondString       },
};

static const predicate_t BINARY[] = {
  { "fnIDiv",                 fnIDiv,          oracle_fnIDiv,          0            },
  { "fnIDivR",                fnIDivR,         oracle_fnIDivR,         0            },

  { "fnXLessThan/Y",          fnXLessThan,     oracle_fnXLessThan,     REGISTER_Y   },
  { "fnXLessEqual/Y",         fnXLessEqual,    oracle_fnXLessEqual,    REGISTER_Y   },
  { "fnXGreaterThan/Y",       fnXGreaterThan,  oracle_fnXGreaterThan,  REGISTER_Y   },
  { "fnXGreaterEqual/Y",      fnXGreaterEqual, oracle_fnXGreaterEqual, REGISTER_Y   },
  { "fnXEqualsTo/Y",          fnXEqualsTo,     oracle_fnXEqualsTo,     REGISTER_Y   },
  { "fnXNotEqual/Y",          fnXNotEqual,     oracle_fnXNotEqual,     REGISTER_Y   },
  { "fnXAlmostEqual/Y",       fnXAlmostEqual,  oracle_fnXAlmostEqual,  REGISTER_Y   },

  { "fnXLessThan/Z",          fnXLessThan,     oracle_fnXLessThan,     REGISTER_Z   },
  { "fnXGreaterThan/Z",       fnXGreaterThan,  oracle_fnXGreaterThan,  REGISTER_Z   },
  { "fnXEqualsTo/Z",          fnXEqualsTo,     oracle_fnXEqualsTo,     REGISTER_Z   },
  { "fnXAlmostEqual/Z",       fnXAlmostEqual,  oracle_fnXAlmostEqual,  REGISTER_Z   },

  // fnIsConverged reads bit 0 (absolute vs relative), bit 1 (infinite) and
  // bit 2 (NaN), so all eight combinations are distinct behaviour.
  { "fnIsConverged/0",        fnIsConverged,   oracle_fnIsConverged,   0            },
  { "fnIsConverged/1",        fnIsConverged,   oracle_fnIsConverged,   1            },
  { "fnIsConverged/2",        fnIsConverged,   oracle_fnIsConverged,   2            },
  { "fnIsConverged/3",        fnIsConverged,   oracle_fnIsConverged,   3            },
  { "fnIsConverged/4",        fnIsConverged,   oracle_fnIsConverged,   4            },
  { "fnIsConverged/5",        fnIsConverged,   oracle_fnIsConverged,   5            },
  { "fnIsConverged/6",        fnIsConverged,   oracle_fnIsConverged,   6            },
  { "fnIsConverged/7",        fnIsConverged,   oracle_fnIsConverged,   7            },

  // fnAtan2 dispatches on the (X, Y) type pair through c43's arctan2 table.
  { "fnAtan2",                fnAtan2,         oracle_fnAtan2,         0            },
  // fnToPolar2 and fnToRect2 read Y as the second component when X is a plain
  // real, so they belong in the pair sweep as well as the unary one.
  { "fnToPolar2/pair",        fnToPolar2,      oracle_fnToPolar2,      0            },
  { "fnToRect2/pair",         fnToRect2,       oracle_fnToRect2,       0            },
};

// Run one side: reset the calculator, seed the operands, call the wrapper,
// snapshot. `seedSecond` is NULL for the unary families.
static void runSide(void (*seed)(void), void (*seedSecond)(void), void (*body)(uint16_t),
                    uint16_t param, snapshot_t *out) {
  fnReset(CONFIRMED);
  seed();
  if(seedSecond != NULL) {
    seedSecond();
  }
  temporaryInformation = TI_NO_INFO;
  lastErrorCode = ERROR_NONE;
  body(param);
  takeSnapshot(out);
}

int main(void) {
  int cases = 0;







  // The reference and the owner must be DIFFERENT code. A rename that did not
  // take still LINKS, and would make every case below compare a thing against
  // itself and pass.
  if((const void *)&oracle_fnCheckNumber == (const void *)&fnCheckNumber) {
    printf("math-wrappers full-core: oracle_fnCheckNumber IS fnCheckNumber -- rename did not take\n");
    return 1;
  }
  if((const void *)oracle_Round == (const void *)Round) {
    printf("math-wrappers full-core: oracle_Round IS Round -- dispatch-table rename did not take\n");
    return 1;
  }
  if((const void *)oracle_idiv == (const void *)idiv) {
    printf("math-wrappers full-core: oracle_idiv IS idiv -- dispatch-table rename did not take\n");
    return 1;
  }
  if((const void *)oracle_idivr == (const void *)idivr) {
    printf("math-wrappers full-core: oracle_idivr IS idivr -- dispatch-table rename did not take\n");
    return 1;
  }

  // c43's error slots hold the shared typeError. If a build turns
  // EXTRA_INFO_ON_CALC_ERROR on, c43 declares real per-file handlers instead and
  // they need renaming like everything else; this catches that day.
  if((const void *)oracle_Round[5] != (const void *)&typeError) {
    printf("math-wrappers full-core: oracle_Round error slot is not typeError\n");
    return 1;
  }
  if((const void *)oracle_unitVector[5] != (const void *)&typeError) {
    printf("math-wrappers full-core: oracle_unitVector error slot is not typeError\n");
    return 1;
  }

  for(size_t p = 0; p < sizeof(PREDICATES) / sizeof(PREDICATES[0]); p++) {
    for(size_t f = 0; f < sizeof(FIXTURES) / sizeof(FIXTURES[0]); f++) {
      char caseName[128];
      snprintf(caseName, sizeof(caseName), "%s/%s", PREDICATES[p].name, FIXTURES[f].name);

      runSide(FIXTURES[f].seed, NULL, PREDICATES[p].owner, PREDICATES[p].param, &snapshotA);
      runSide(FIXTURES[f].seed, NULL, PREDICATES[p].oracle, PREDICATES[p].param, &snapshotB);
      reportSnapshotMismatch(caseName);
      cases++;
    }
  }

  for(size_t p = 0; p < sizeof(BINARY) / sizeof(BINARY[0]); p++) {
    for(size_t f = 0; f < sizeof(PAIRS) / sizeof(PAIRS[0]); f++) {
      char caseName[128];
      snprintf(caseName, sizeof(caseName), "%s/%s", BINARY[p].name, PAIRS[f].name);

      runSide(PAIRS[f].seedX, PAIRS[f].seedSecond, BINARY[p].owner, BINARY[p].param, &snapshotA);
      runSide(PAIRS[f].seedX, PAIRS[f].seedSecond, BINARY[p].oracle, BINARY[p].param, &snapshotB);
      reportSnapshotMismatch(caseName);
      cases++;
    }
  }

  if(failures) {
    printf("MATH-WRAPPER FULL-CORE PARITY: %d failure(s) over %d cases\n", failures, cases);
    return 1;
  }
  printf("math-wrappers full-core: %d cases agree (%zu unary x %zu shapes, %zu binary x %zu pairs)\n",
         cases, sizeof(PREDICATES) / sizeof(PREDICATES[0]), sizeof(FIXTURES) / sizeof(FIXTURES[0]),
         sizeof(BINARY) / sizeof(BINARY[0]), sizeof(PAIRS) / sizeof(PAIRS[0]));
  return 0;
}
