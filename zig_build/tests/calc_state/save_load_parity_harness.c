// SPDX-License-Identifier: GPL-3.0-only
//
// Save/load round-trip parity harness for the calc-state serialization
// (saveRestoreCalcState.c). It links the full real calculator core (the same
// object graph as the testSuite) so it exercises the ACTUAL save/restore code
// — not the mocked oracle. Its purpose is to make a Zig port of the heavy
// save/restore bodies VERIFIABLE:
//
//   1. Build a deterministic calculator state (fnReset + a few mutations).
//   2. doSave(manualSave)  -> writes c47.sav (deterministic text sections).
//   3. Read those bytes  -> "save1".
//   4. Golden byte-compare: save1 must equal the committed reference produced
//      by the current C implementation (catches any change to SAVE output).
//   5. fnReset (wipe) then doLoad(manualLoad) -> restore from save1.
//   6. fnSave again -> "save2".
//   7. Round-trip: save1 must equal save2 (catches RESTORE bugs — a faithful
//      restore reconstructs state such that re-saving is byte-identical).
//
// Because (4) pins the save bytes and (6) pins restore against a correct save,
// porting save and restore in SEPARATE commits is each independently caught.
//
// Usage:
//   save_load_parity_harness <golden_path>                 -> compare + round-trip
//   save_load_parity_harness <golden_path> --write-golden  -> (re)generate golden

// Angle-bracket include resolves to the real src/c47/c47.h via -I; a quoted
// include would pick up the mock c47.h that sits next to this file (used by the
// calc_state parity oracle).
#include <c47.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SAVE_FILE "c47.sav"
#define MAX_SAVE (1u << 20)

// Screen/GUI globals the core references; normally defined by testSuite.c,
// which this harness replaces. The harness is headless so they stay unused.
GtkWidget      *screen;
calcKeyboard_t  calcKeyboard[43];
int             currentBezel;
int16_t         screenStride;
uint32_t       *screenData;
bool_t          screenChange;

// Drive the REAL C text-section serialization directly (the namespaced legacy
// entrypoints). The Zig host io_flow path is currently a stub on host, and the
// backup.cfg path (saveCalc) is a raw RAM dump with non-deterministic pointers
// — neither is byte-comparable. doSave(manualSave)/doLoad(...,manualLoad) write
// the deterministic c47.sav text format via save_sections / restoreOneSection,
// which are the porting targets. A Zig port repoints doSaveImpl/doLoadImpl
// below at the production entry and the golden confirms byte-identity.
// SAVE now runs the Zig production path: the canonical fnSave is the Zig export
// (calc_state.zig) -> save() -> io_flow doSave -> z47_calc_state_save_sections
// (the Zig section writer). The golden byte-compare therefore verifies the Zig
// SAVE port against the original C output.
//
// LOAD/RESTORE now also runs the Zig production path: the canonical fnLoad is
// the Zig export -> load() -> io_flow doLoad -> header parse -> policy ->
// restoreOneSection loop (the Zig parser). The round-trip therefore verifies the
// Zig RESTORE port reconstructs state such that re-saving (also Zig) is
// byte-identical to the original save.
extern void fnSave(uint16_t saveMode);
extern void fnLoad(uint16_t loadMode);

static void doSaveImpl(void)  { fnSave(SM_MANUAL_SAVE); }
static void doLoadImpl(void)  { fnLoad(LM_ALL); }

// backup.cfg raw-dump path. The canonical saveCalc/restoreCalc are the Zig
// exports (calc_state.zig), which currently route to the C legacy bodies; this
// check gates a future Zig port of them.
extern void saveCalc(void);
extern void restoreCalc(void);
static void saveCalcImpl(void)    { saveCalc(); }
static void restoreCalcImpl(void) { restoreCalc(); }

static long readWholeFile(const char *path, unsigned char *buf, long cap) {
  FILE *f = fopen(path, "rb");
  if(!f) {
    return -1;
  }
  long n = (long)fread(buf, 1, (size_t)cap, f);
  fclose(f);
  return n;
}

// Build a deterministic, non-trivial state so the save exercises the dynamic
// sections (registers with values, a couple of flags) rather than only the
// empty defaults.
static void buildState(void) {
  fnReset(CONFIRMED);

  // Populate global (stack) registers with a DIVERSE set of data types so the
  // GLOBAL_REGISTERS save/restore exercises every value-codec branch of
  // registerToSaveString / restoreRegister (not just dtReal34): real34 (plain
  // and angular-tagged), complex34, short integer, long integer, time, date.
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  int32ToReal34(1234, REGISTER_REAL34_DATA(REGISTER_X));
  reallocateRegister(REGISTER_Y, dtReal34, 0, amNone);
  int32ToReal34(-42, REGISTER_REAL34_DATA(REGISTER_Y));

  // real34 with an angular tag -> "Real:DEG"
  reallocateRegister(REGISTER_Z, dtReal34, 0, amDegree);
  int32ToReal34(90, REGISTER_REAL34_DATA(REGISTER_Z));

  // complex34 (3 + 4i)
  reallocateRegister(REGISTER_T, dtComplex34, 0, amNone);
  int32ToReal34(3, REGISTER_REAL34_DATA(REGISTER_T));
  int32ToReal34(4, REGISTER_IMAG34_DATA(REGISTER_T));

  // short integer (hex base)
  convertUInt64ToShortIntegerRegister(0, 0xDEADBEEFULL, 16, REGISTER_A);

  // long integer (arbitrary precision)
  {
    longInteger_t li;
    longIntegerInit(li);
    stringToLongInteger("123456789012345678901234567890", 10, li);
    convertLongIntegerToLongIntegerRegister(li, REGISTER_B);
    longIntegerFree(li);
  }

  // time and date
  reallocateRegister(REGISTER_C, dtTime, 0, amNone);
  int32ToReal34(3600, REGISTER_REAL34_DATA(REGISTER_C));
  reallocateRegister(REGISTER_D, dtDate, 0, amNone);
  int32ToReal34(20260622, REGISTER_REAL34_DATA(REGISTER_D));

  // Every angular tag, so the textTag codec (DEG/DMS/RAD/MULTPI/GRAD + polar)
  // is fully exercised on save AND restore.
  reallocateRegister(0, dtReal34, 0, amRadian);
  int32ToReal34(1, REGISTER_REAL34_DATA(0));
  reallocateRegister(1, dtReal34, 0, amGrad);
  int32ToReal34(2, REGISTER_REAL34_DATA(1));
  reallocateRegister(2, dtReal34, 0, amDMS);
  int32ToReal34(3, REGISTER_REAL34_DATA(2));
  reallocateRegister(3, dtReal34, 0, amMultPi);
  int32ToReal34(4, REGISTER_REAL34_DATA(3));

  // complex34 in polar mode (tag carries amPolar + an angular mode) -> "Cplx:DEGp"
  reallocateRegister(4, dtComplex34, 0, amPolar | amDegree);
  int32ToReal34(5, REGISTER_REAL34_DATA(4));
  int32ToReal34(45, REGISTER_IMAG34_DATA(4));

  // string register
  {
    const char *s = "Hello, C47 \"state\"!";
    reallocateRegister(5, dtString, TO_BLOCKS((int)strlen(s) + 1), amNone);
    strcpy(REGISTER_STRING_DATA(5), s);
  }

  // real34 matrix (2x3) with distinct element values
  initMatrixRegister(6, 2, 3, false);
  for(int e = 0; e < 6; ++e) {
    int32ToReal34(e * 10 + 1, REGISTER_REAL34_MATRIX_ELEMENTS(6) + e);
  }

  // complex34 matrix (2x2) with distinct re/im element values
  initMatrixRegister(7, 2, 2, true);
  for(int e = 0; e < 4; ++e) {
    int32ToReal34(e + 1,   VARIABLE_REAL34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(7) + e));
    int32ToReal34(e + 100, VARIABLE_IMAG34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(7) + e));
  }

  // Named variables of two types land in the NAMED_VARIABLES section.
  allocateNamedVariable("TESTVAR", dtReal34, REAL34_SIZE_IN_BLOCKS);
  int32ToReal34(777, REGISTER_REAL34_DATA(findNamedVariable("TESTVAR")));
  allocateNamedVariable("CPXVAR", dtComplex34, COMPLEX34_SIZE_IN_BLOCKS);
  {
    calcRegister_t v = findNamedVariable("CPXVAR");
    int32ToReal34(11, REGISTER_REAL34_DATA(v));
    int32ToReal34(22, REGISTER_IMAG34_DATA(v));
  }

  // Accumulate two-variable statistics so the STATISTICAL_SUMS section (and the
  // stat-sum value codec) is exercised rather than left empty.
  {
    const int32_t xs[] = {2, 5, 11}, ys[] = {3, 7, 13};
    for(int k = 0; k < 3; ++k) {
      reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
      int32ToReal34(xs[k], REGISTER_REAL34_DATA(REGISTER_X));
      reallocateRegister(REGISTER_Y, dtReal34, 0, amNone);
      int32ToReal34(ys[k], REGISTER_REAL34_DATA(REGISTER_Y));
      fnSigmaAddRem(1); // Sigma+
    }
  }

  // MyMenu / MyAlpha items (the MYMENU / MYALPHA sections) with an argument name.
  userMenuItems[0].item = ITM_ADD;
  userMenuItems[1].item = ITM_SUB;
  strcpy(userAlphaItems[0].argumentName, "Av");
  userAlphaItems[0].item = 100;

  // A user menu with items (the USER_MENUS section, otherwise empty).
  createMenu("UMENU");
  if(numberOfUserMenus > 0) {
    userMenus[numberOfUserMenus - 1].menuItem[0].item = ITM_ADD;
    strcpy(userMenus[numberOfUserMenus - 1].menuItem[1].argumentName, "X");
    userMenus[numberOfUserMenus - 1].menuItem[1].item = 42;
  }

  // Local registers: allocate a subroutine frame with a few registers so the
  // LOCAL_REGISTERS section -- and, on restore, the Zig parser for a non-empty
  // local frame -- is exercised by the round-trip instead of staying at count 0.
  // Mix value types so the local-section codec path is covered, not just dtReal34.
  allocateLocalRegisters(3);
  reallocateRegister(FIRST_LOCAL_REGISTER + 0, dtReal34, 0, amNone);
  int32ToReal34(111, REGISTER_REAL34_DATA(FIRST_LOCAL_REGISTER + 0));
  reallocateRegister(FIRST_LOCAL_REGISTER + 1, dtReal34, 0, amDegree);
  int32ToReal34(222, REGISTER_REAL34_DATA(FIRST_LOCAL_REGISTER + 1));
  convertUInt64ToShortIntegerRegister(0, 0xABCDULL, 16, FIRST_LOCAL_REGISTER + 2);

  // Restore the diverse X/Y values consumed by the statistics accumulation.
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  int32ToReal34(1234, REGISTER_REAL34_DATA(REGISTER_X));
  reallocateRegister(REGISTER_Y, dtReal34, 0, amNone);
  int32ToReal34(-42, REGISTER_REAL34_DATA(REGISTER_Y));

  // A couple of user flags land in the GLOBAL_FLAGS section.
  fnSetFlag(5);
  fnSetFlag(42);
}

int main(int argc, char *argv[]) {
  if(argc < 2) {
    printf("Usage: %s <golden_path> [--write-golden]\n", argv[0]);
    return 2;
  }
  const char *goldenPath = argv[1];
  bool writeGolden = (argc >= 3 && strcmp(argv[2], "--write-golden") == 0);

  mp_set_memory_functions(allocGmp, reallocGmp, freeGmp);

  static unsigned char save1[MAX_SAVE];
  static unsigned char save2[MAX_SAVE];

  // --- Pass 1: build state, save, capture save1 ---
  buildState();
  doSaveImpl();
  long n1 = readWholeFile(SAVE_FILE, save1, MAX_SAVE);
  if(n1 < 0) {
    printf("FAIL: could not read %s after first save\n", SAVE_FILE);
    return 1;
  }
  printf("save1: %ld bytes\n", n1);

  if(writeGolden) {
    FILE *g = fopen(goldenPath, "wb");
    if(!g) {
      printf("FAIL: cannot open golden %s for writing\n", goldenPath);
      return 1;
    }
    fwrite(save1, 1, (size_t)n1, g);
    fclose(g);
    printf("wrote golden (%ld bytes) to %s\n", n1, goldenPath);
    return 0;
  }

  int failed = 0;

  // --- Check A: golden byte-compare (save serialization parity) ---
  static unsigned char golden[MAX_SAVE];
  long ng = readWholeFile(goldenPath, golden, MAX_SAVE);
  if(ng < 0) {
    printf("FAIL: could not read golden %s\n", goldenPath);
    return 1;
  }
  if(ng != n1 || memcmp(golden, save1, (size_t)n1) != 0) {
    printf("FAIL: save output differs from golden (golden=%ld save1=%ld)\n", ng, n1);
    long lim = ng < n1 ? ng : n1;
    for(long i = 0; i < lim; i++) {
      if(golden[i] != save1[i]) {
        printf("  first diff at byte %ld: golden=0x%02x save1=0x%02x\n", i, golden[i], save1[i]);
        break;
      }
    }
    failed = 1;
  }
  else {
    printf("PASS: save output matches golden (%ld bytes)\n", n1);
  }

  // --- Check B: round-trip (restore correctness) ---
  fnReset(CONFIRMED);     // wipe live state
  doLoadImpl();           // restore from c47.sav (== save1)
  doSaveImpl();           // re-serialize
  long n2 = readWholeFile(SAVE_FILE, save2, MAX_SAVE);
  if(n2 < 0) {
    printf("FAIL: could not read %s after round-trip save\n", SAVE_FILE);
    return 1;
  }
  if(n2 != n1 || memcmp(save1, save2, (size_t)n1) != 0) {
    printf("FAIL: round-trip save differs (save1=%ld save2=%ld)\n", n1, n2);
    long lim = n2 < n1 ? n2 : n1;
    for(long i = 0; i < lim; i++) {
      if(save1[i] != save2[i]) {
        printf("  first diff at byte %ld: save1=0x%02x save2=0x%02x\n", i, save1[i], save2[i]);
        break;
      }
    }
    failed = 1;
  }
  else {
    printf("PASS: round-trip save1 == save2 (%ld bytes)\n", n1);
  }

  // --- Check C: backup.cfg (saveCalc/restoreCalc) state round-trip ---
  // saveCalc/restoreCalc use the raw RAM-dump backup format (backup.cfg), whose
  // bytes are non-deterministic (live pointers), so they cannot be byte-compared
  // directly. Instead, verify they PRESERVE STATE by re-using the deterministic
  // c47.sav text as the oracle: dump -> wipe -> restore -> re-serialize and
  // compare against save1. This gates a future Zig port of saveCalc/restoreCalc
  // (still C today via the bridge) exactly as Checks A/B gate doSave/doLoad.
  // State at this point == save1's (restored by Check B).
  saveCalcImpl();          // raw dump -> backup.cfg
  fnReset(CONFIRMED);      // wipe live state
  restoreCalcImpl();       // raw restore from backup.cfg
  doSaveImpl();            // re-serialize to c47.sav
  long n3 = readWholeFile(SAVE_FILE, save2, MAX_SAVE);
  if(n3 < 0) {
    printf("FAIL: could not read %s after backup restore\n", SAVE_FILE);
    return 1;
  }
  if(n3 != n1 || memcmp(save1, save2, (size_t)n1) != 0) {
    printf("FAIL: backup.cfg round-trip differs (save1=%ld save3=%ld)\n", n1, n3);
    long lim = n3 < n1 ? n3 : n1;
    for(long i = 0; i < lim; i++) {
      if(save1[i] != save2[i]) {
        printf("  first diff at byte %ld: save1=0x%02x save3=0x%02x\n", i, save1[i], save2[i]);
        break;
      }
    }
    failed = 1;
  }
  else {
    printf("PASS: backup.cfg round-trip preserves state (%ld bytes)\n", n1);
  }

  if(failed) {
    printf("SAVE/LOAD PARITY: FAILED\n");
    return 1;
  }
  printf("SAVE/LOAD PARITY: OK\n");
  return 0;
}
