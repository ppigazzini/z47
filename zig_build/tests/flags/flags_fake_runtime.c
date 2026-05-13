// SPDX-License-Identifier: GPL-3.0-only

#include <string.h>

#include "flags_test_runtime.h"

uint64_t systemFlags0 = 0;
uint64_t systemFlags1 = 0;
uint32_t lastIntegerBase = 0;
uint8_t screenUpdatingMode = SCRUPD_AUTO;

static uint32_t refreshStateCalls = 0;
static uint32_t clearStatusBarCalls = 0;
static uint32_t changeBaseCalls = 0;
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
  refreshStateCalls = 0;
  clearStatusBarCalls = 0;
  changeBaseCalls = 0;
  lastClearStatusBarInfo = 0;
  lastChangeBaseArg = 0;
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
  snapshot->refresh_state_calls = refreshStateCalls;
  snapshot->clear_status_bar_calls = clearStatusBarCalls;
  snapshot->change_base_calls = changeBaseCalls;
  snapshot->last_clear_status_bar_info = lastClearStatusBarInfo;
  snapshot->last_change_base_arg = lastChangeBaseArg;
}

void flagsParityCaptureLive(flags_parity_snapshot_t *snapshot) {
  capture(snapshot, systemFlags0Changed, systemFlags1Changed, systemFlags2Changed);
}

void flagsParityCaptureOracle(flags_parity_snapshot_t *snapshot) {
  capture(snapshot, oracle_systemFlags0Changed, oracle_systemFlags1Changed, oracle_systemFlags2Changed);
}