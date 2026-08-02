// SPDX-License-Identifier: GPL-3.0-only

#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include "calc_state_test_runtime.h"

static int reportMismatch(const char *caseName, const calc_state_snapshot_t *expected, const calc_state_snapshot_t *actual) {
  if(memcmp(expected, actual, sizeof(*expected)) == 0) {
    return 0;
  }

  fprintf(stderr,
      "%s mismatch\n"
      "  expected: load=%u save=%u restore=%u save_sections=%u backup=%u/%u status=%u/%u allow=%d ti=%u finish=%u/%u cached=%d file=%s\n"
      "  actual:   load=%u save=%u restore=%u save_sections=%u backup=%u/%u status=%u/%u allow=%d ti=%u finish=%u/%u cached=%d file=%s\n",
          caseName,
          expected->opened_load_path,
          expected->opened_save_path,
          expected->restore_calls,
          expected->write_save_sections_calls,
      expected->save_calc_calls,
      expected->restore_calc_calls,
          expected->show_saving_status_calls,
          expected->show_loading_status_calls,
          expected->last_allow_user_keys,
          expected->temporary_information,
          expected->finish_load_ui_calls,
          expected->finish_load_ui_refresh_code,
          expected->cached_dynamic_menu,
          expected->last_state_file_opened,
          actual->opened_load_path,
          actual->opened_save_path,
          actual->restore_calls,
          actual->write_save_sections_calls,
          actual->save_calc_calls,
          actual->restore_calc_calls,
          actual->show_saving_status_calls,
          actual->show_loading_status_calls,
          actual->last_allow_user_keys,
          actual->temporary_information,
          actual->finish_load_ui_calls,
          actual->finish_load_ui_refresh_code,
          actual->cached_dynamic_menu,
          actual->last_state_file_opened);
  return 1;
}

static int runSaveCalcEntryPointCase(void) {
  calc_state_snapshot_t expected;
  calc_state_snapshot_t actual;

  calcStateParityReset();
  oracle_saveCalc();
  calcStateParityCapture(&expected);

  calcStateParityReset();
  saveCalc();
  calcStateParityCapture(&actual);

  return reportMismatch("saveCalc entrypoint", &expected, &actual);
}

static int runRestoreCalcEntryPointCase(void) {
  calc_state_snapshot_t expected;
  calc_state_snapshot_t actual;

  calcStateParityReset();
  oracle_restoreCalc();
  calcStateParityCapture(&expected);

  calcStateParityReset();
  restoreCalc();
  calcStateParityCapture(&actual);

  return reportMismatch("restoreCalc entrypoint", &expected, &actual);
}

static int runFnSaveStateWrapperCase(void) {
  calc_state_snapshot_t expected;
  calc_state_snapshot_t actual;

  calcStateParityReset();
  oracle_fnSave(SM_STATE_SAVE);
  calcStateParityCapture(&expected);

  calcStateParityReset();
  fnSave(SM_STATE_SAVE);
  calcStateParityCapture(&actual);

  return reportMismatch("fnSave state wrapper", &expected, &actual);
}

static int runDoLoadStateFileCase(void) {
  static const char loadFile[] =
      "SAVE_FILE_REVISION\n"
      "0\n"
      "C47_save_file_00\n"
      "10000023\n"
      "END_CONFIG\n";
  calc_state_snapshot_t expected;
  calc_state_snapshot_t actual;

  calcStateParityReset();
  calcStateParitySetSelectedFile("STATE01.sav");
  calcStateParitySetAcceptedSavedCalcModel(USER_C47);
  calcStateParitySetLoadFile(loadFile);
  calcStateParitySetRestoreContinueCount(0);
  oracle_doLoad(LM_ALL, 0, 0, 0, stateLoad);
  calcStateParityCapture(&expected);

  calcStateParityReset();
  calcStateParitySetSelectedFile("STATE01.sav");
  calcStateParitySetAcceptedSavedCalcModel(USER_C47);
  calcStateParitySetLoadFile(loadFile);
  calcStateParitySetRestoreContinueCount(0);
  doLoad(LM_ALL, 0, 0, 0, stateLoad);
  calcStateParityCapture(&actual);

  return reportMismatch("doLoad state-file load", &expected, &actual);
}

static int runFnLoadStateWrapperCase(void) {
  static const char loadFile[] =
      "SAVE_FILE_REVISION\n"
      "0\n"
      "C47_save_file_00\n"
      "10000023\n"
      "END_CONFIG\n";
  calc_state_snapshot_t expected;
  calc_state_snapshot_t actual;

  calcStateParityReset();
  calcStateParitySetSelectedFile("STATE02.sav");
  calcStateParitySetAcceptedSavedCalcModel(USER_C47);
  calcStateParitySetLoadFile(loadFile);
  calcStateParitySetRestoreContinueCount(0);
  oracle_fnLoad(LM_STATE_LOAD);
  calcStateParityCapture(&expected);

  calcStateParityReset();
  calcStateParitySetSelectedFile("STATE02.sav");
  calcStateParitySetAcceptedSavedCalcModel(USER_C47);
  calcStateParitySetLoadFile(loadFile);
  calcStateParitySetRestoreContinueCount(0);
  fnLoad(LM_STATE_LOAD);
  calcStateParityCapture(&actual);

  return reportMismatch("fnLoad state wrapper", &expected, &actual);
}

static int runFnLoadAutoVersionGateCase(void) {
  static const char loadFile[] =
      "SAVE_FILE_REVISION\n"
      "0\n"
      "C47_save_file_00\n"
      "10000004\n"
      "END_CONFIG\n";
  calc_state_snapshot_t expected;
  calc_state_snapshot_t actual;

  calcStateParityReset();
  calcStateParitySetSelectedFile("AUTO01.sav");
  calcStateParitySetAcceptedSavedCalcModel(USER_C47);
  calcStateParitySetLoadFile(loadFile);
  calcStateParitySetRestoreContinueCount(0);
  oracle_fnLoadAuto();
  calcStateParityCapture(&expected);

  calcStateParityReset();
  calcStateParitySetSelectedFile("AUTO01.sav");
  calcStateParitySetAcceptedSavedCalcModel(USER_C47);
  calcStateParitySetLoadFile(loadFile);
  calcStateParitySetRestoreContinueCount(0);
  fnLoadAuto();
  calcStateParityCapture(&actual);

  return reportMismatch("fnLoadAuto version gate", &expected, &actual);
}

static int runFnSaveAutoHostNoopCase(void) {
  calc_state_snapshot_t expected;
  calc_state_snapshot_t actual;

  calcStateParityReset();
  oracle_fnSaveAuto(0);
  calcStateParityCapture(&expected);

  calcStateParityReset();
  fnSaveAuto(0);
  calcStateParityCapture(&actual);

  return reportMismatch("fnSaveAuto host noop", &expected, &actual);
}

// M-SAFE-11: pin the stringTo* macro family's BEHAVIOUR, not just its shape.
//
// Upstream generates six of these from two macros (saveRestoreCalcState.c:1056),
// both passing base 0 to strtol/strtoul, both narrowing an out-of-range result.
// Four of the six had drifted to `parseInt(.., 10) catch 0`: a different base and
// a different answer on overflow (finding 10). The macro-family scan keeps the six
// bodies identical to each other; this keeps them identical to UPSTREAM, which the
// scan cannot know -- changing all six to base 10 at once would leave it green.
//
// Every probe here is width-independent on purpose. `(uint32_t)strtoul("4294967296")`
// is 0 where `unsigned long` is 64-bit and 4294967295 where it is 32-bit, so it
// differs between Linux/macOS and Windows and between host and firmware. That
// divergence is real and is M-SAFE-10's subject; pinning it here would just encode
// one platform's answer as if it were the contract.
extern uint8_t  stringToUint8(const char *str);
extern uint16_t stringToUint16(const char *str);
extern uint32_t stringToUint32(const char *str);
extern int8_t   stringToInt8(const char *str);
extern int16_t  stringToInt16(const char *str);
extern int32_t  stringToInt32(const char *str);

static int expectU(const char *fn, const char *input, uint32_t got, uint32_t want) {
  if(got == want) {
    return 0;
  }
  fprintf(stderr, "%s(\"%s\") = %u, expected %u\n", fn, input, got, want);
  return 1;
}

static int expectI(const char *fn, const char *input, int32_t got, int32_t want) {
  if(got == want) {
    return 0;
  }
  fprintf(stderr, "%s(\"%s\") = %d, expected %d\n", fn, input, got, want);
  return 1;
}

static int runStringToNumberFamilyCase(void) {
  int failures = 0;

  // Base 0: "0x" is hexadecimal and a leading "0" is octal. `parseInt(.., 10)`
  // read neither, so all six of these were wrong before M-SAFE-11.
  failures += expectU("stringToUint8", "0x1F", stringToUint8("0x1F"), 31);
  failures += expectU("stringToUint16", "0x1F", stringToUint16("0x1F"), 31);
  failures += expectU("stringToUint32", "0x1F", stringToUint32("0x1F"), 31);
  failures += expectI("stringToInt8", "0x1F", stringToInt8("0x1F"), 31);
  failures += expectI("stringToInt16", "0x1F", stringToInt16("0x1F"), 31);
  failures += expectI("stringToInt32", "0x1F", stringToInt32("0x1F"), 31);

  failures += expectU("stringToUint8", "010", stringToUint8("010"), 8);
  failures += expectU("stringToUint16", "010", stringToUint16("010"), 8);
  failures += expectU("stringToUint32", "010", stringToUint32("010"), 8);
  failures += expectI("stringToInt8", "010", stringToInt8("010"), 8);
  failures += expectI("stringToInt16", "010", stringToInt16("010"), 8);
  failures += expectI("stringToInt32", "010", stringToInt32("010"), 8);

  // Out of range NARROWS to the low bits; it does not become 0. The `catch 0` the
  // drifted members carried turned 300 into 0 for u8 rather than 44.
  failures += expectU("stringToUint8", "300", stringToUint8("300"), 44);
  failures += expectI("stringToInt8", "300", stringToInt8("300"), 44);
  failures += expectU("stringToUint16", "70000", stringToUint16("70000"), 4464);

  // In range, and negatives for the signed half.
  failures += expectU("stringToUint32", "300", stringToUint32("300"), 300);
  failures += expectI("stringToInt16", "-300", stringToInt16("-300"), -300);
  failures += expectI("stringToInt32", "-300", stringToInt32("-300"), -300);
  failures += expectI("stringToInt8", "-1", stringToInt8("-1"), -1);

  // Not a number at all: strtoul converts nothing and returns 0.
  failures += expectU("stringToUint32", "", stringToUint32(""), 0);
  failures += expectU("stringToUint8", "zz", stringToUint8("zz"), 0);

  return failures;
}

int main(void) {
  int failures = 0;

  failures += runStringToNumberFamilyCase();
  failures += runSaveCalcEntryPointCase();
  failures += runRestoreCalcEntryPointCase();
  failures += runFnSaveStateWrapperCase();
  failures += runDoLoadStateFileCase();
  failures += runFnLoadStateWrapperCase();
  failures += runFnSaveAutoHostNoopCase();
  failures += runFnLoadAutoVersionGateCase();

  if(failures != 0) {
    fprintf(stderr, "%d calc-state parity checks failed\n", failures);
    return 1;
  }

  puts("calc-state parity checks passed");
  return 0;
}