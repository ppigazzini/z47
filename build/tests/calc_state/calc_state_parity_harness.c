// SPDX-License-Identifier: GPL-3.0-only
//
// calc-state parity: z47's `.sav` bytes against c43's, in one binary.
//
// WHAT THIS LANE IS FOR. A state file is the artifact a user
// carries between a physical DM42 and the simulator, and until this lane existed
// NOTHING in the tree held its format to c43:
//
//   saveload_roundtrip check A   -> z47's own previous output (a golden snapshot,
//                                   regenerated from z47's writer a dozen times)
//   saveload_roundtrip checks B/D-> z47's own load path (round-trip idempotence)
//   state_load_fuzz              -> crash/hang absence on malformed input
//   calc_state_parity (as was)   -> a 194-line hand-written model of save-file
//                                   REVISION PARSING, about 6% of the file
//   anything at all vs c43       -> nothing
//
// So a c43 format change -- a widened field, a reordered section, a renamed
// header key -- would have been invisible, and every state file z47 writes
// silently incompatible. That is the parity rule aimed at the most externally
// visible thing z47 produces.
//
// HOW IT WORKS. calc_state_oracle.c compiles c43's OWN saveRestoreCalcState.c a
// second time into this binary under `oracle_` names, beside the Zig owner that
// replaced it. Both implementations then share ONE calculator: the same globals,
// the same register pool, the same value codecs (decQuadToString,
// registerFMAOutputPlainString, longIntegerToAllocatedString, ...) and the same
// file I/O. Nothing about the environment is modelled, so a difference in the
// output can only come from the code under test. The reference is c43 source
// compiled at build time, so it moves when c43 moves -- which is the entire point.
//
// SEED / RUN / SNAPSHOT / RE-SEED / RUN / SNAPSHOT. Every check rebuilds the
// fixture state from scratch before running each side. A full core carries orders
// of magnitude more state than a unit harness, and running the two sides back to
// back without re-seeding would compare c43 against a calculator z47 had already
// modified.

#include <c47.h>

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SAVE_FILE "c47.sav"

// The deterministic fixture, shared with save_load_roundtrip_harness.c so the two
// calc-state lanes serialize the same calculator.
#include "calc_state_fixture.h"

// ---------------------------------------------------------------------------
// The two implementations. The unprefixed names are the Zig owner's exports,
// declared by upstream's saveRestoreCalcState.h via <c47.h>; the `oracle_` ones
// are c43's own bodies from calc_state_oracle.c.
// ---------------------------------------------------------------------------
extern void oracle_fnSave(uint16_t saveMode);
extern void oracle_fnLoad(uint16_t loadMode);
extern void oracle_doLoad(uint16_t loadMode, uint16_t s, uint16_t n, uint16_t d, uint16_t loadType);

extern uint8_t oracle_stringToUint8(const char *str);
extern uint16_t oracle_stringToUint16(const char *str);
extern uint32_t oracle_stringToUint32(const char *str);
extern uint64_t oracle_stringToUint64(const char *str);
extern int8_t oracle_stringToInt8(const char *str);
extern int16_t oracle_stringToInt16(const char *str);
extern int32_t oracle_stringToInt32(const char *str);
extern int64_t oracle_stringToInt64(const char *str);
extern float oracle_stringToFloat(const char *str);
extern int32_t oracle_toInt32(const char *str);

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
// Byte comparison
// ---------------------------------------------------------------------------

static long writeWholeFile(const char *path, const unsigned char *buf, long n) {
  FILE *f = fopen(path, "wb");
  if(!f) {
    return -1;
  }
  long written = (long)fwrite(buf, 1, (size_t)n, f);
  fclose(f);
  return written;
}

// Report the first differing byte AND the line it falls on. The `.sav` format is
// line-oriented text, so a byte offset alone sends the reader counting; the line
// number names the section.
static int compareBytes(const char *what, const unsigned char *a, long na, const unsigned char *b, long nb) {
  long limit = na < nb ? na : nb;
  for(long i = 0; i < limit; i++) {
    if(a[i] != b[i]) {
      long line = 1;
      long lineStart = 0;
      for(long j = 0; j < i; j++) {
        if(a[j] == '\n') {
          line++;
          lineStart = j + 1;
        }
      }
      fail("%s: first difference at byte %ld (line %ld, column %ld): z47=0x%02x '%c'  c43=0x%02x '%c'",
           what, i, line, i - lineStart + 1,
           a[i], (a[i] >= 32 && a[i] < 127) ? a[i] : '.',
           b[i], (b[i] >= 32 && b[i] < 127) ? b[i] : '.');
      printf("       z47: %.*s\n", (int)((na - lineStart) < 78 ? (na - lineStart) : 78), (const char *)a + lineStart);
      printf("       c43: %.*s\n", (int)((nb - lineStart) < 78 ? (nb - lineStart) : 78), (const char *)b + lineStart);
      return 1;
    }
  }
  if(na != nb) {
    fail("%s: identical for %ld bytes then lengths differ: z47=%ld c43=%ld", what, limit, na, nb);
    return 1;
  }
  printf("PASS: %s (%ld bytes, byte-identical)\n", what, na);
  return 0;
}

// ---------------------------------------------------------------------------
// Check 1 -- the stringTo* / toInt32 parser family.
//
// These parse every scalar field of every section, so a base or overflow
// disagreement corrupts the restore of a field nobody wrote a case for. The
// previous lane pinned them against HAND-WRITTEN expected values, which is the
// defect this report is about one function at a time: `stringToUint8("300") ==
// 44` is somebody's reading of c43, not c43. Now both sides run and the answers
// are compared, so the expectation cannot drift away from the implementation.
//
// The sweep is deliberately width- and platform-agnostic in what it ASSERTS: it
// never claims a value, only that the two implementations agree. That makes the
// 32-vs-64-bit `unsigned long` divergence visible as a
// disagreement if one side stops matching, instead of being encoded here as if
// one platform's answer were the contract.
// ---------------------------------------------------------------------------

static const char *const parserInputs[] = {
  "0",      "1",       "-1",      "+42",     "42",
  "0x1F",   "0X7f",    "0xFF",    "0xFFFF",  "0xFFFFFFFF",
  "010",    "0777",    "07",      "08",
  "127",    "128",     "255",     "256",     "300",
  "-128",   "-129",    "-300",    "-32768",  "-32769",
  "32767",  "32768",   "65535",   "65536",   "70000",
  "2147483647", "2147483648", "-2147483648", "-2147483649",
  "4294967295", "4294967296",
  "9223372036854775807", "18446744073709551615",
  "",       " ",       "zz",      " 12",     "12abc",   "abc12",
  "1e3",    "3.14",    "-2.5",    "0.0",     "1.5e-3",
};

static int runParserFamilyDifferential(void) {
  int before = failures;

  for(size_t i = 0; i < sizeof(parserInputs) / sizeof(parserInputs[0]); i++) {
    const char *s = parserInputs[i];

    if(stringToUint8(s) != oracle_stringToUint8(s)) {
      fail("stringToUint8(\"%s\"): z47=%u c43=%u", s, stringToUint8(s), oracle_stringToUint8(s));
    }
    if(stringToUint16(s) != oracle_stringToUint16(s)) {
      fail("stringToUint16(\"%s\"): z47=%u c43=%u", s, stringToUint16(s), oracle_stringToUint16(s));
    }
    if(stringToUint32(s) != oracle_stringToUint32(s)) {
      fail("stringToUint32(\"%s\"): z47=%u c43=%u", s, stringToUint32(s), oracle_stringToUint32(s));
    }
    if(stringToUint64(s) != oracle_stringToUint64(s)) {
      fail("stringToUint64(\"%s\"): z47=%llu c43=%llu", s,
           (unsigned long long)stringToUint64(s), (unsigned long long)oracle_stringToUint64(s));
    }
    if(stringToInt8(s) != oracle_stringToInt8(s)) {
      fail("stringToInt8(\"%s\"): z47=%d c43=%d", s, stringToInt8(s), oracle_stringToInt8(s));
    }
    if(stringToInt16(s) != oracle_stringToInt16(s)) {
      fail("stringToInt16(\"%s\"): z47=%d c43=%d", s, stringToInt16(s), oracle_stringToInt16(s));
    }
    if(stringToInt32(s) != oracle_stringToInt32(s)) {
      fail("stringToInt32(\"%s\"): z47=%d c43=%d", s, stringToInt32(s), oracle_stringToInt32(s));
    }
    if(stringToInt64(s) != oracle_stringToInt64(s)) {
      fail("stringToInt64(\"%s\"): z47=%lld c43=%lld", s,
           (long long)stringToInt64(s), (long long)oracle_stringToInt64(s));
    }
    if(toInt32(s) != oracle_toInt32(s)) {
      fail("toInt32(\"%s\"): z47=%d c43=%d", s, toInt32(s), oracle_toInt32(s));
    }
    // Bit-compare the float: a NaN or a one-ULP difference must not pass as equal,
    // and `==` would call two NaNs unequal and two -0.0/0.0 equal.
    {
      float mine = stringToFloat(s);
      float theirs = oracle_stringToFloat(s);
      if(memcmp(&mine, &theirs, sizeof(float)) != 0) {
        fail("stringToFloat(\"%s\"): z47=%.9g c43=%.9g", s, (double)mine, (double)theirs);
      }
    }
  }

  if(failures == before) {
    printf("PASS: stringTo*/toInt32 family agrees with c43 over %zu inputs\n",
           sizeof(parserInputs) / sizeof(parserInputs[0]));
  }
  return failures - before;
}

// ---------------------------------------------------------------------------
// Check 2 -- SAVE format parity. The one thing nothing in the tree measured.
// ---------------------------------------------------------------------------

static unsigned char zigSave[MAX_SAVE];
static unsigned char c43Save[MAX_SAVE];
static long zigSaveLen;
static long c43SaveLen;

static int runSaveFormatDifferential(void) {
  buildState();
  fnSave(SM_MANUAL_SAVE);
  zigSaveLen = readWholeFile(SAVE_FILE, zigSave, MAX_SAVE);
  if(zigSaveLen < 0) {
    fail("could not read %s after the z47 save", SAVE_FILE);
    return 1;
  }

  // Re-seed. The oracle must see the calculator the Zig writer saw, not the one
  // the Zig writer left behind.
  buildState();
  oracle_fnSave(SM_MANUAL_SAVE);
  c43SaveLen = readWholeFile(SAVE_FILE, c43Save, MAX_SAVE);
  if(c43SaveLen < 0) {
    fail("could not read %s after the c43 save", SAVE_FILE);
    return 1;
  }

  return compareBytes("SAVE: z47's .sav bytes == c43's", zigSave, zigSaveLen, c43Save, c43SaveLen);
}

// ---------------------------------------------------------------------------
// Check 3 -- RESTORE parity, measured through a common writer.
//
// Both sides load the SAME file, then the SAME (Zig) writer serializes whatever
// each produced. Any difference is therefore a restore difference: the writer is
// held constant on purpose, exactly as the codecs are, so the comparison cannot
// be confounded by the thing check 2 already measures.
// ---------------------------------------------------------------------------

static unsigned char reference[MAX_SAVE];
static unsigned char afterZigRestore[MAX_SAVE];
static unsigned char afterC43Restore[MAX_SAVE];

static int runRestoreDifferential(void) {
  // The file both sides read: c43's own bytes, so the restore is being asked to
  // read what a real C47 would have written.
  memcpy(reference, c43Save, (size_t)c43SaveLen);
  const long referenceLen = c43SaveLen;

  if(writeWholeFile(SAVE_FILE, reference, referenceLen) != referenceLen) {
    fail("could not stage the reference %s", SAVE_FILE);
    return 1;
  }
  fnReset(CONFIRMED);
  doLoad(LM_ALL, 0, 0, 0, manualLoad);
  const uint8_t zigTemporaryInformation = temporaryInformation;
  const uint8_t zigLastErrorCode = lastErrorCode;
  fnSave(SM_MANUAL_SAVE);
  const long zigLen = readWholeFile(SAVE_FILE, afterZigRestore, MAX_SAVE);

  if(writeWholeFile(SAVE_FILE, reference, referenceLen) != referenceLen) {
    fail("could not re-stage the reference %s", SAVE_FILE);
    return 1;
  }
  fnReset(CONFIRMED);
  oracle_doLoad(LM_ALL, 0, 0, 0, manualLoad);
  const uint8_t c43TemporaryInformation = temporaryInformation;
  const uint8_t c43LastErrorCode = lastErrorCode;
  fnSave(SM_MANUAL_SAVE);
  const long c43Len = readWholeFile(SAVE_FILE, afterC43Restore, MAX_SAVE);

  if(zigLen < 0 || c43Len < 0) {
    fail("could not read %s after a restore", SAVE_FILE);
    return 1;
  }

  int bad = compareBytes("RESTORE: state after z47's doLoad == after c43's",
                         afterZigRestore, zigLen, afterC43Restore, c43Len);

  // The observable side effects of a load, which the deleted oracle modelled by
  // hand and which no byte comparison can see.
  if(zigTemporaryInformation != c43TemporaryInformation) {
    fail("doLoad temporaryInformation: z47=%u c43=%u", zigTemporaryInformation, c43TemporaryInformation);
    bad = 1;
  }
  if(zigLastErrorCode != c43LastErrorCode) {
    fail("doLoad lastErrorCode: z47=%u c43=%u", zigLastErrorCode, c43LastErrorCode);
    bad = 1;
  }
  if(!bad) {
    printf("PASS: doLoad side effects agree (temporaryInformation=%u lastErrorCode=%u)\n",
           zigTemporaryInformation, zigLastErrorCode);
  }
  return bad;
}

// ---------------------------------------------------------------------------
// Check 4 -- the load-mode policy table.
//
// doLoad's enableLoad decision is a switch over (loadType, loadMode) and the
// temporaryInformation it leaves behind is a chain of eight else-ifs. Both are
// pure branch coverage that neither the byte comparison nor the round-trip lane
// reaches, and the previous hand-written oracle got its version of this chain
// from a reading of c43 rather than from c43.
// ---------------------------------------------------------------------------

static const struct {
  const char *name;
  uint16_t loadMode;
  uint16_t loadType;
} loadPolicyCases[] = {
  {"manualLoad LM_ALL", LM_ALL, manualLoad},
  {"manualLoad LM_PROGRAMS", LM_PROGRAMS, manualLoad},
  {"manualLoad LM_REGISTERS", LM_REGISTERS, manualLoad},
  {"manualLoad LM_SYSTEM_STATE", LM_SYSTEM_STATE, manualLoad},
  {"manualLoad LM_SUMS", LM_SUMS, manualLoad},
  {"manualLoad LM_NAMED_VARIABLES", LM_NAMED_VARIABLES, manualLoad},
  {"manualLoad LM_REGISTERS_PARTIAL", LM_REGISTERS_PARTIAL, manualLoad},
  {"stateLoad LM_ALL", LM_ALL, stateLoad},
  {"stateLoad LM_REGISTERS", LM_REGISTERS, stateLoad},
  {"autoLoad LM_ALL", LM_ALL, autoLoad},
  {"autoLoad LM_PROGRAMS", LM_PROGRAMS, autoLoad},
};

static int runLoadPolicyDifferential(void) {
  int before = failures;

  for(size_t i = 0; i < sizeof(loadPolicyCases) / sizeof(loadPolicyCases[0]); i++) {
    const uint16_t mode = loadPolicyCases[i].loadMode;
    const uint16_t type = loadPolicyCases[i].loadType;

    if(writeWholeFile(SAVE_FILE, reference, c43SaveLen) != c43SaveLen) {
      fail("%s: could not stage the reference", loadPolicyCases[i].name);
      continue;
    }
    fnReset(CONFIRMED);
    doLoad(mode, 0, 0, 0, type);
    const uint8_t zigTi = temporaryInformation;
    const uint8_t zigErr = lastErrorCode;
    const uint16_t zigCached = cachedDynamicMenu;
    fnSave(SM_MANUAL_SAVE);
    const long zigLen = readWholeFile(SAVE_FILE, afterZigRestore, MAX_SAVE);

    if(writeWholeFile(SAVE_FILE, reference, c43SaveLen) != c43SaveLen) {
      fail("%s: could not re-stage the reference", loadPolicyCases[i].name);
      continue;
    }
    fnReset(CONFIRMED);
    oracle_doLoad(mode, 0, 0, 0, type);
    const uint8_t c43Ti = temporaryInformation;
    const uint8_t c43Err = lastErrorCode;
    const uint16_t c43Cached = cachedDynamicMenu;
    fnSave(SM_MANUAL_SAVE);
    const long c43Len = readWholeFile(SAVE_FILE, afterC43Restore, MAX_SAVE);

    if(zigTi != c43Ti) {
      fail("%s: temporaryInformation z47=%u c43=%u", loadPolicyCases[i].name, zigTi, c43Ti);
    }
    if(zigErr != c43Err) {
      fail("%s: lastErrorCode z47=%u c43=%u", loadPolicyCases[i].name, zigErr, c43Err);
    }
    if(zigCached != c43Cached) {
      fail("%s: cachedDynamicMenu z47=%u c43=%u", loadPolicyCases[i].name, zigCached, c43Cached);
    }
    if(zigLen < 0 || c43Len < 0 || zigLen != c43Len || memcmp(afterZigRestore, afterC43Restore, (size_t)zigLen) != 0) {
      char what[128];
      snprintf(what, sizeof(what), "%s: restored state", loadPolicyCases[i].name);
      compareBytes(what, afterZigRestore, zigLen, afterC43Restore, c43Len);
    }
  }

  if(failures == before) {
    printf("PASS: the (loadType, loadMode) policy table agrees with c43 over %zu combinations\n",
           sizeof(loadPolicyCases) / sizeof(loadPolicyCases[0]));
  }
  return failures - before;
}

int main(void) {
  mp_set_memory_functions(allocGmp, reallocGmp, freeGmp);

  runParserFamilyDifferential();
  if(runSaveFormatDifferential() == 0) {
    runRestoreDifferential();
    runLoadPolicyDifferential();
  }
  else {
    printf("SKIPPING the restore differentials: they read the c43 save this check produced.\n");
  }

  if(failures != 0) {
    printf("CALC-STATE PARITY: %d check(s) FAILED\n", failures);
    return 1;
  }
  printf("CALC-STATE PARITY: OK\n");
  return 0;
}
