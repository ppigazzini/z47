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
// doSave/doLoad are static in saveRestoreCalcState.c; the public bridged
// entries fnSave/fnLoad (namespaced to z47_calc_state_legacy_* by the shim)
// call them and are linkable. fnSave(SM_MANUAL_SAVE)->doSave(manualSave);
// fnLoad(LM_ALL)->doLoad(...,manualLoad).
extern void z47_calc_state_legacy_fnSave(uint16_t saveMode);
extern void z47_calc_state_legacy_fnLoad(uint16_t loadMode);

static void doSaveImpl(void)  { z47_calc_state_legacy_fnSave(SM_MANUAL_SAVE); }
static void doLoadImpl(void)  { z47_calc_state_legacy_fnLoad(LM_ALL); }

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

  // Put real values into a couple of global (stack) registers so the dynamic
  // GLOBAL_REGISTERS section exercises the real number formatting paths during
  // save, rather than only empty defaults.
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

  if(failed) {
    printf("SAVE/LOAD PARITY: FAILED\n");
    return 1;
  }
  printf("SAVE/LOAD PARITY: OK\n");
  return 0;
}
