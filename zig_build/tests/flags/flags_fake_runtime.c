// SPDX-License-Identifier: GPL-3.0-only

#include <string.h>

#include "flags_test_runtime.h"

uint64_t systemFlags0 = 0;
uint64_t systemFlags1 = 0;
uint32_t lastIntegerBase = 0;
uint8_t screenUpdatingMode = SCRUPD_AUTO;
uint16_t globalFlags[8] = {0};
uint32_t *currentLocalFlags = NULL;
uint8_t temporaryInformation = 0;
uint8_t programRunStop = PGM_STOPPED;
uint8_t alphaCase = AC_UPPER;
uint8_t scrLock = NC_NORMAL;
uint8_t nextChar = NC_NORMAL;

static uint32_t localFlagsStorage = 0;

static uint32_t refreshStateCalls = 0;
static uint32_t clearStatusBarCalls = 0;
static uint32_t changeBaseCalls = 0;
static uint32_t showAlphaModeCalls = 0;
uint32_t writeProtectedErrorCalls = 0;
uint32_t enterAlphaCalls = 0;
uint32_t leaveAlphaCalls = 0;
uint32_t leaveTamCalls = 0;
uint32_t clFAllConfirmationCalls = 0;
static uint8_t lastClearStatusBarInfo = 0;
static uint16_t lastChangeBaseArg = 0;

void fnRefreshState(void) {
  refreshStateCalls++;
}

void reallyClearStatusBar(uint8_t info) {
  clearStatusBarCalls++;
  lastClearStatusBarInfo = info;
}

void fnChangeBaseJM(uint16_t base) {
  changeBaseCalls++;
  lastChangeBaseArg = base;
  lastIntegerBase = base;
}

void showAlphaModeonGui(void) {
  showAlphaModeCalls++;
}

void flagsParitySeed(uint64_t system_flags0,
                     uint64_t system_flags1,
                     uint64_t system_flags0_changed,
                     uint64_t system_flags1_changed,
                     uint64_t system_flags2_changed,
                     uint32_t last_integer_base,
                     uint8_t screen_updating_mode) {
  systemFlags0 = system_flags0;
  systemFlags1 = system_flags1;
  systemFlags0Changed = system_flags0_changed;
  systemFlags1Changed = system_flags1_changed;
  systemFlags2Changed = system_flags2_changed;
  oracle_systemFlags0Changed = system_flags0_changed;
  oracle_systemFlags1Changed = system_flags1_changed;
  oracle_systemFlags2Changed = system_flags2_changed;
  lastIntegerBase = last_integer_base;
  screenUpdatingMode = screen_updating_mode;
  memset(globalFlags, 0, sizeof(globalFlags));
  currentLocalFlags = NULL;
  localFlagsStorage = 0;
  temporaryInformation = 0;
  programRunStop = PGM_STOPPED;
  alphaCase = AC_UPPER;
  scrLock = NC_NORMAL;
  nextChar = NC_NORMAL;
  refreshStateCalls = 0;
  clearStatusBarCalls = 0;
  changeBaseCalls = 0;
  showAlphaModeCalls = 0;
  writeProtectedErrorCalls = 0;
  enterAlphaCalls = 0;
  leaveAlphaCalls = 0;
  leaveTamCalls = 0;
  clFAllConfirmationCalls = 0;
  lastClearStatusBarInfo = 0;
  lastChangeBaseArg = 0;
}

void flagsParitySeedCommandState(const uint16_t global_flags[8],
                                 bool_t has_local_flags,
                                 uint32_t local_flags,
                                 uint8_t temporary_information,
                                 uint8_t program_run_stop) {
  memcpy(globalFlags, global_flags, sizeof(globalFlags));
  localFlagsStorage = local_flags;
  currentLocalFlags = has_local_flags ? &localFlagsStorage : NULL;
  temporaryInformation = temporary_information;
  programRunStop = program_run_stop;
}

void flagsParitySeedTextState(uint8_t alpha_case,
                              uint8_t scr_lock,
                              uint8_t next_char) {
  alphaCase = alpha_case;
  scrLock = scr_lock;
  nextChar = next_char;
}

void leaveTamModeIfEnabled(void) {
  leaveTamCalls++;
}

void z47_flags_runtime_handle_write_protected_flag(void) {
  writeProtectedErrorCalls++;
  temporaryInformation = TI_NO_INFO;
  if(programRunStop == PGM_WAITING) {
    programRunStop = PGM_STOPPED;
  }
}

void z47_flags_runtime_enter_alpha_mode(void) {
  enterAlphaCalls++;
  setSystemFlag(FLAG_ALPHA);
}

void z47_flags_runtime_leave_alpha_mode(void) {
  leaveAlphaCalls++;
  clearSystemFlag(FLAG_ALPHA);
}

void z47_flags_runtime_request_clf_all_confirmation(void) {
  clFAllConfirmationCalls++;
}

static void capture(flags_parity_snapshot_t *snapshot,
                    uint64_t changed0,
                    uint64_t changed1,
                    uint64_t changed2) {
  memset(snapshot, 0, sizeof(*snapshot));
  snapshot->system_flags0 = systemFlags0;
  snapshot->system_flags1 = systemFlags1;
  snapshot->system_flags0_changed = changed0;
  snapshot->system_flags1_changed = changed1;
  snapshot->system_flags2_changed = changed2;
  snapshot->last_integer_base = lastIntegerBase;
  snapshot->screen_updating_mode = screenUpdatingMode;
  memcpy(snapshot->global_flags, globalFlags, sizeof(snapshot->global_flags));
  snapshot->has_local_flags = currentLocalFlags != NULL;
  snapshot->local_flags = currentLocalFlags == NULL ? 0 : *currentLocalFlags;
  snapshot->temporary_information = temporaryInformation;
  snapshot->program_run_stop = programRunStop;
  snapshot->alpha_case = alphaCase;
  snapshot->scr_lock = scrLock;
  snapshot->next_char = nextChar;
  snapshot->refresh_state_calls = refreshStateCalls;
  snapshot->clear_status_bar_calls = clearStatusBarCalls;
  snapshot->change_base_calls = changeBaseCalls;
  snapshot->write_protected_error_calls = writeProtectedErrorCalls;
  snapshot->enter_alpha_calls = enterAlphaCalls;
  snapshot->leave_alpha_calls = leaveAlphaCalls;
  snapshot->leave_tam_calls = leaveTamCalls;
  snapshot->clf_all_confirmation_calls = clFAllConfirmationCalls;
  snapshot->show_alpha_mode_calls = showAlphaModeCalls;
  snapshot->last_clear_status_bar_info = lastClearStatusBarInfo;
  snapshot->last_change_base_arg = lastChangeBaseArg;
}

void flagsParityCaptureLive(flags_parity_snapshot_t *snapshot) {
  capture(snapshot, systemFlags0Changed, systemFlags1Changed, systemFlags2Changed);
}

void flagsParityCaptureOracle(flags_parity_snapshot_t *snapshot) {
  capture(snapshot, oracle_systemFlags0Changed, oracle_systemFlags1Changed, oracle_systemFlags2Changed);
}