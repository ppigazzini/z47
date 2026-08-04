// SPDX-License-Identifier: GPL-3.0-only
//
// Save/load ROUND-TRIP harness for the calc-state serialization
// (saveRestoreCalcState.c). It links the full real calculator core (the same
// object graph as the testSuite) so it exercises the ACTUAL save/restore code
// — not the mocked oracle. Its purpose is to make a Zig port of the heavy
// save/restore bodies VERIFIABLE:
//
//   1. Build a deterministic calculator state (fnReset + a few mutations).
//   2. doSave(manualSave)  -> writes c47.sav (deterministic text sections).
//   3. Read those bytes  -> "save1".
//   4. Golden byte-compare: save1 must equal the committed snapshot (catches any
//      unintended change to SAVE output).
//   5. fnReset (wipe) then doLoad(manualLoad) -> restore from save1.
//   6. fnSave again -> "save2".
//   7. Round-trip: save1 must equal save2 (catches RESTORE bugs — a faithful
//      restore reconstructs state such that re-saving is byte-identical).
//
// Because (4) pins the save bytes and (6) pins restore against a correct save,
// porting save and restore in SEPARATE commits is each independently caught.
//
// WHAT (4) IS NOT. The golden was the C `doSave` output when
// this harness was written and SAVE was still C. SAVE is Zig now, and the golden
// has been regenerated from THIS harness (`zig build saveload_golden`) after every
// deliberate output change since. So it is a snapshot of z47's own bytes, re-pinned
// by z47 — it cannot detect c43 changing the save format, and calling this lane
// "parity" claimed coverage nobody had. Checks B, C and D are honest: they assert
// z47 round-trip idempotence, which needs no external reference to be meaningful.
//
// Usage:
//   save_load_roundtrip_harness <golden_path>                 -> compare + round-trip
//   save_load_roundtrip_harness <golden_path> --write-golden  -> (re)generate golden

// Angle-bracket include resolves to the real src/c47/c47.h via -I; a quoted
// include would pick up the mock c47.h that sits next to this file (used by the
// calc_state parity oracle).
#include <c47.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SAVE_FILE "c47.sav"
// The deterministic fixture state and the small file helpers now live in
// calc_state_fixture.h so `calc_state_parity` -- the c43 differential -- serializes
// the SAME calculator this lane does. Extracted verbatim: the
// committed golden is the byte output of that state.
#include "calc_state_fixture.h"
#include "../common/harness_resource_budget.h"

// Drive the REAL C text-section serialization directly (the namespaced legacy
// entrypoints). The Zig host io_flow path is currently a stub on host, and the
// backup.cfg path (saveCalc) is a raw RAM dump with non-deterministic pointers
// — neither is byte-comparable. doSave(manualSave)/doLoad(...,manualLoad) write
// the deterministic c47.sav text format via save_sections / restoreOneSection,
// which are the porting targets. A Zig port repoints doSaveImpl/doLoadImpl
// below at the production entry and the golden confirms byte-identity.
// SAVE now runs the Zig production path: the canonical fnSave is the Zig export
// (calc_state.zig) -> save() -> io_flow doSave -> z47_calc_state_save_sections
// (the Zig section writer). The golden byte-compare verified the Zig SAVE port
// against the original C output ONCE, at the commit that landed it; every
// regeneration since has re-pinned it to Zig's output (see the note above).
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


int main(int argc, char *argv[]) {
  if(argc < 2) {
    printf("Usage: %s <golden_path> [--write-golden]\n", argv[0]);
    return 2;
  }
  const char *goldenPath = argv[1];
  bool writeGolden = (argc >= 3 && strcmp(argv[2], "--write-golden") == 0);

  harnessInstallResourceBudget("calc-state save/load roundtrip");

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

  // --- Check D: register data-file (DATA_FILE format) save/load round-trip ---
  // Exercises the NEW M10.4 XFN save/load family: fnSaveLetteredRegisters ->
  // doSaveDataFile -> fnSaveDataRegisters (the dataFileMode codec forms: lettered
  // "RX" names, compact complex "(re+im i)", short-int '#base'), and the load
  // path fnLoadRegisters -> doLoadDataFile -> restoreOneSection -> restoreRegister
  // (stringToRegisterNumber + the inverse parsers). The host HAL maps
  // ioPathRegExport/ioPathRegImport to "c47.regs".
  //
  // The data file is a *human-readable export*: Time/Date are stored as display
  // forms (THMS/DYMD) and complex registers are coerced to the live polar mode
  // when FLAG_POLAR is set -- both faithful to the C, both lossy vs the exact
  // c47.sav form. So we verify the round-trip on a clean slate (fnReset clears
  // FLAG_POLAR) over the LOSSLESSLY-representable scalar types: a real, a short
  // integer, a long integer, a string, and an (unset-polar) complex. Save ->
  // perturb every lettered register -> load -> re-save the data file, and require
  // the two data files to be byte-identical (a no-op load cannot pass because the
  // perturbation rewrites every register first).
  fnReset(CONFIRMED);
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  int32ToReal34(12345, REGISTER_REAL34_DATA(REGISTER_X));
  reallocateRegister(REGISTER_Y, dtReal34, 0, amDegree);          // tagged real -> "Real:DEG"
  int32ToReal34(90, REGISTER_REAL34_DATA(REGISTER_Y));
  convertUInt64ToShortIntegerRegister(0, 0xCAFEBABEULL, 16, REGISTER_Z); // ShoI '#16'
  {
    longInteger_t li;
    longIntegerInit(li);
    stringToLongInteger("98765432109876543210", 10, li);
    convertLongIntegerToLongIntegerRegister(li, REGISTER_T);
    longIntegerFree(li);
  }
  reallocateRegister(REGISTER_A, dtComplex34, 0, amNone);         // FLAG_POLAR clear -> stays amNone
  int32ToReal34(7,  REGISTER_REAL34_DATA(REGISTER_A));
  int32ToReal34(-8, REGISTER_IMAG34_DATA(REGISTER_A));
  {
    const char *s = "data-file str!";
    reallocateRegister(REGISTER_B, dtString, TO_BLOCKS((int)strlen(s) + 1), amNone);
    strcpy(REGISTER_STRING_DATA(REGISTER_B), s);
  }

  static unsigned char regs1[MAX_SAVE], regs2[MAX_SAVE];
  fnSaveLetteredRegisters(NOPARAM);                 // -> c47.regs (dataFileMode forms)
  long nr1 = readWholeFile("c47.regs", regs1, MAX_SAVE);
  for(int r = REGISTER_X; r <= REGISTER_W; ++r) {   // perturb every lettered register
    reallocateRegister(r, dtReal34, 0, amNone);
    int32ToReal34(-99999, REGISTER_REAL34_DATA(r));
  }
  fnLoadRegisters(NOPARAM);                          // <- c47.regs
  fnSaveLetteredRegisters(NOPARAM);                 // re-export
  long nr2 = readWholeFile("c47.regs", regs2, MAX_SAVE);
  if(nr1 < 0 || nr2 < 0) {
    printf("FAIL: could not read c47.regs data file\n");
    return 1;
  }
  if(nr1 != nr2 || memcmp(regs1, regs2, (size_t)nr1) != 0) {
    printf("FAIL: data-file round-trip differs (regs1=%ld regs2=%ld)\n", nr1, nr2);
    long lim = nr2 < nr1 ? nr2 : nr1;
    for(long i = 0; i < lim; i++) {
      if(regs1[i] != regs2[i]) {
        printf("  first diff at byte %ld: regs1=0x%02x regs2=0x%02x\n", i, regs1[i], regs2[i]);
        break;
      }
    }
    failed = 1;
  }
  else {
    printf("PASS: data-file (DATA_FILE) save/load round-trip is byte-identical (%ld bytes)\n", nr1);
  }

  if(failed) {
    printf("SAVE/LOAD ROUND-TRIP: FAILED\n");
    return 1;
  }
  printf("SAVE/LOAD ROUND-TRIP: OK\n");
  return 0;
}
