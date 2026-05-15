// SPDX-License-Identifier: GPL-3.0-only

#include <stdio.h>
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

int main(void) {
  int failures = 0;

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