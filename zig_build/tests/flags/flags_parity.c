// SPDX-License-Identifier: GPL-3.0-only

#include <stdio.h>
#include <string.h>

#include "flags_test_runtime.h"

static int reportMismatch(const char *name,
                          uint32_t argument,
                          int expected_result,
                          int actual_result,
                          const flags_parity_snapshot_t *expected_snapshot,
                          const flags_parity_snapshot_t *actual_snapshot) {
  int failures = 0;

  if(expected_result != actual_result) {
    fprintf(stderr, "%s(%#x) result mismatch: expected %d actual %d\n", name, argument, expected_result, actual_result);
    failures++;
  }

  if(memcmp(expected_snapshot, actual_snapshot, sizeof(*expected_snapshot)) != 0) {
    fprintf(stderr, "%s(%#x) state mismatch\n", name, argument);
    failures++;
  }

  return failures;
}

static int runGetCase(const char *name,
                      int32_t argument,
                      uint64_t system_flags0,
                      uint64_t system_flags1,
                      uint64_t changed0,
                      uint64_t changed1,
                      uint64_t changed2,
                      uint32_t last_integer_base,
                      uint8_t screen_updating_mode) {
  flags_parity_snapshot_t expected_snapshot;
  flags_parity_snapshot_t actual_snapshot;
  int expected_result;
  int actual_result;

  flagsParitySeed(system_flags0, system_flags1, changed0, changed1, changed2, last_integer_base, screen_updating_mode);
  expected_result = oracle_getSystemFlag(argument);
  flagsParityCaptureOracle(&expected_snapshot);

  flagsParitySeed(system_flags0, system_flags1, changed0, changed1, changed2, last_integer_base, screen_updating_mode);
  actual_result = getSystemFlag(argument);
  flagsParityCaptureLive(&actual_snapshot);

  return reportMismatch(name, (uint32_t)argument, expected_result, actual_result, &expected_snapshot, &actual_snapshot);
}

static int runGetFlagCase(const char *name,
                         uint16_t argument,
                         const uint16_t global_flags[8],
                         bool_t has_local_flags,
                         uint32_t local_flags,
                         uint8_t temporary_information,
                         uint8_t program_run_stop,
                         uint64_t system_flags0,
                         uint64_t system_flags1,
                         uint64_t changed0,
                         uint64_t changed1,
                         uint64_t changed2,
                         uint32_t last_integer_base,
                         uint8_t screen_updating_mode) {
  flags_parity_snapshot_t expected_snapshot;
  flags_parity_snapshot_t actual_snapshot;
  int expected_result;
  int actual_result;

  flagsParitySeed(system_flags0, system_flags1, changed0, changed1, changed2, last_integer_base, screen_updating_mode);
  flagsParitySeedCommandState(global_flags, has_local_flags, local_flags, temporary_information, program_run_stop);
  expected_result = oracle_getFlag(argument);
  flagsParityCaptureOracle(&expected_snapshot);

  flagsParitySeed(system_flags0, system_flags1, changed0, changed1, changed2, last_integer_base, screen_updating_mode);
  flagsParitySeedCommandState(global_flags, has_local_flags, local_flags, temporary_information, program_run_stop);
  actual_result = getFlag(argument);
  flagsParityCaptureLive(&actual_snapshot);

  return reportMismatch(name, argument, expected_result, actual_result, &expected_snapshot, &actual_snapshot);
}

static int runFnGetSystemFlagCase(uint16_t argument,
                                  const uint16_t global_flags[8],
                                  bool_t has_local_flags,
                                  uint32_t local_flags,
                                  uint8_t temporary_information,
                                  uint8_t program_run_stop,
                                  uint64_t system_flags0,
                                  uint64_t system_flags1,
                                  uint64_t changed0,
                                  uint64_t changed1,
                                  uint64_t changed2,
                                  uint32_t last_integer_base,
                                  uint8_t screen_updating_mode) {
  flags_parity_snapshot_t expected_snapshot;
  flags_parity_snapshot_t actual_snapshot;

  flagsParitySeed(system_flags0, system_flags1, changed0, changed1, changed2, last_integer_base, screen_updating_mode);
  flagsParitySeedCommandState(global_flags, has_local_flags, local_flags, temporary_information, program_run_stop);
  oracle_fnGetSystemFlag(argument);
  flagsParityCaptureOracle(&expected_snapshot);

  flagsParitySeed(system_flags0, system_flags1, changed0, changed1, changed2, last_integer_base, screen_updating_mode);
  flagsParitySeedCommandState(global_flags, has_local_flags, local_flags, temporary_information, program_run_stop);
  fnGetSystemFlag(argument);
  flagsParityCaptureLive(&actual_snapshot);

  return reportMismatch("fnGetSystemFlag", argument, 0, 0, &expected_snapshot, &actual_snapshot);
}

static int runFlagCommandCase(const char *name,
                              uint16_t argument,
                              void (*oracle_fn)(uint16_t),
                              void (*zig_fn)(uint16_t),
                              const uint16_t global_flags[8],
                              bool_t has_local_flags,
                              uint32_t local_flags,
                              uint8_t temporary_information,
                              uint8_t program_run_stop,
                              uint64_t system_flags0,
                              uint64_t system_flags1,
                              uint64_t changed0,
                              uint64_t changed1,
                              uint64_t changed2,
                              uint32_t last_integer_base,
                              uint8_t screen_updating_mode) {
  flags_parity_snapshot_t expected_snapshot;
  flags_parity_snapshot_t actual_snapshot;

  flagsParitySeed(system_flags0, system_flags1, changed0, changed1, changed2, last_integer_base, screen_updating_mode);
  flagsParitySeedCommandState(global_flags, has_local_flags, local_flags, temporary_information, program_run_stop);
  oracle_fn(argument);
  flagsParityCaptureOracle(&expected_snapshot);

  flagsParitySeed(system_flags0, system_flags1, changed0, changed1, changed2, last_integer_base, screen_updating_mode);
  flagsParitySeedCommandState(global_flags, has_local_flags, local_flags, temporary_information, program_run_stop);
  zig_fn(argument);
  flagsParityCaptureLive(&actual_snapshot);

  return reportMismatch(name, argument, 0, 0, &expected_snapshot, &actual_snapshot);
}

static int runSetSettingCase(uint16_t argument,
                             const uint16_t global_flags[8],
                             bool_t has_local_flags,
                             uint32_t local_flags,
                             uint8_t temporary_information,
                             uint8_t program_run_stop,
                             uint8_t alpha_case,
                             uint8_t scr_lock,
                             uint8_t next_char,
                             uint64_t system_flags0,
                             uint64_t system_flags1,
                             uint64_t changed0,
                             uint64_t changed1,
                             uint64_t changed2,
                             uint32_t last_integer_base,
                             uint8_t screen_updating_mode) {
  flags_parity_snapshot_t expected_snapshot;
  flags_parity_snapshot_t actual_snapshot;

  flagsParitySeed(system_flags0, system_flags1, changed0, changed1, changed2, last_integer_base, screen_updating_mode);
  flagsParitySeedCommandState(global_flags, has_local_flags, local_flags, temporary_information, program_run_stop);
  flagsParitySeedTextState(alpha_case, scr_lock, next_char);
  oracle_SetSetting(argument);
  flagsParityCaptureOracle(&expected_snapshot);

  flagsParitySeed(system_flags0, system_flags1, changed0, changed1, changed2, last_integer_base, screen_updating_mode);
  flagsParitySeedCommandState(global_flags, has_local_flags, local_flags, temporary_information, program_run_stop);
  flagsParitySeedTextState(alpha_case, scr_lock, next_char);
  SetSetting(argument);
  flagsParityCaptureLive(&actual_snapshot);

  return reportMismatch("SetSetting", argument, 0, 0, &expected_snapshot, &actual_snapshot);
}

static int runChangedCase(const char *name,
                          int32_t argument,
                          uint64_t system_flags0,
                          uint64_t system_flags1,
                          uint64_t changed0,
                          uint64_t changed1,
                          uint64_t changed2,
                          uint32_t last_integer_base,
                          uint8_t screen_updating_mode) {
  flags_parity_snapshot_t expected_snapshot;
  flags_parity_snapshot_t actual_snapshot;
  int expected_result;
  int actual_result;

  flagsParitySeed(system_flags0, system_flags1, changed0, changed1, changed2, last_integer_base, screen_updating_mode);
  expected_result = oracle_didSystemFlagChange(argument);
  flagsParityCaptureOracle(&expected_snapshot);

  flagsParitySeed(system_flags0, system_flags1, changed0, changed1, changed2, last_integer_base, screen_updating_mode);
  actual_result = didSystemFlagChange(argument);
  flagsParityCaptureLive(&actual_snapshot);

  return reportMismatch(name, (uint32_t)argument, expected_result, actual_result, &expected_snapshot, &actual_snapshot);
}

static int runSetChangedCase(const char *name,
                             int32_t argument,
                             uint64_t system_flags0,
                             uint64_t system_flags1,
                             uint64_t changed0,
                             uint64_t changed1,
                             uint64_t changed2,
                             uint32_t last_integer_base,
                             uint8_t screen_updating_mode) {
  flags_parity_snapshot_t expected_snapshot;
  flags_parity_snapshot_t actual_snapshot;

  flagsParitySeed(system_flags0, system_flags1, changed0, changed1, changed2, last_integer_base, screen_updating_mode);
  oracle_setSystemFlagChanged(argument);
  flagsParityCaptureOracle(&expected_snapshot);

  flagsParitySeed(system_flags0, system_flags1, changed0, changed1, changed2, last_integer_base, screen_updating_mode);
  setSystemFlagChanged(argument);
  flagsParityCaptureLive(&actual_snapshot);

  return reportMismatch(name, (uint32_t)argument, 0, 0, &expected_snapshot, &actual_snapshot);
}

static int runSetAllChangedCase(uint64_t system_flags0,
                                uint64_t system_flags1,
                                uint64_t changed0,
                                uint64_t changed1,
                                uint64_t changed2,
                                uint32_t last_integer_base,
                                uint8_t screen_updating_mode) {
  flags_parity_snapshot_t expected_snapshot;
  flags_parity_snapshot_t actual_snapshot;

  flagsParitySeed(system_flags0, system_flags1, changed0, changed1, changed2, last_integer_base, screen_updating_mode);
  oracle_setAllSystemFlagChanged();
  flagsParityCaptureOracle(&expected_snapshot);

  flagsParitySeed(system_flags0, system_flags1, changed0, changed1, changed2, last_integer_base, screen_updating_mode);
  setAllSystemFlagChanged();
  flagsParityCaptureLive(&actual_snapshot);

  return reportMismatch("setAllSystemFlagChanged", 0, 0, 0, &expected_snapshot, &actual_snapshot);
}

static int runVoidCase(const char *name,
                       unsigned int argument,
                       void (*oracle_fn)(unsigned int),
                       void (*zig_fn)(unsigned int),
                       uint64_t system_flags0,
                       uint64_t system_flags1,
                       uint64_t changed0,
                       uint64_t changed1,
                       uint64_t changed2,
                       uint32_t last_integer_base,
                       uint8_t screen_updating_mode) {
  flags_parity_snapshot_t expected_snapshot;
  flags_parity_snapshot_t actual_snapshot;

  flagsParitySeed(system_flags0, system_flags1, changed0, changed1, changed2, last_integer_base, screen_updating_mode);
  oracle_fn(argument);
  flagsParityCaptureOracle(&expected_snapshot);

  flagsParitySeed(system_flags0, system_flags1, changed0, changed1, changed2, last_integer_base, screen_updating_mode);
  zig_fn(argument);
  flagsParityCaptureLive(&actual_snapshot);

  return reportMismatch(name, argument, 0, 0, &expected_snapshot, &actual_snapshot);
}

static int runForceCase(unsigned int argument,
                        int set,
                        uint64_t system_flags0,
                        uint64_t system_flags1,
                        uint64_t changed0,
                        uint64_t changed1,
                        uint64_t changed2,
                        uint32_t last_integer_base,
                        uint8_t screen_updating_mode) {
  flags_parity_snapshot_t expected_snapshot;
  flags_parity_snapshot_t actual_snapshot;

  flagsParitySeed(system_flags0, system_flags1, changed0, changed1, changed2, last_integer_base, screen_updating_mode);
  oracle_forceSystemFlag(argument, set);
  flagsParityCaptureOracle(&expected_snapshot);

  flagsParitySeed(system_flags0, system_flags1, changed0, changed1, changed2, last_integer_base, screen_updating_mode);
  forceSystemFlag(argument, set);
  flagsParityCaptureLive(&actual_snapshot);

  return reportMismatch("forceSystemFlag", argument, 0, 0, &expected_snapshot, &actual_snapshot);
}

int main(void) {
  int failures = 0;
  static const uint16_t no_global_flags[8] = {0};
  uint16_t seeded_global_flags[8] = {0};
  uint16_t seeded_extra_global_flags[8] = {0};

  seeded_global_flags[0] = (uint16_t)(1u << 5);
  seeded_extra_global_flags[7] = (uint16_t)(1u << 13);

  failures += runGetCase("getSystemFlag", FLAG_CPXRES, ((uint64_t)1 << 4), 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runGetCase("getSystemFlag", FLAG_TOPHEX, 0, ((uint64_t)1 << 24), 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runGetFlagCase("getFlag", FLAG_CPXRES, no_global_flags, false, 0, 0, PGM_STOPPED, ((uint64_t)1 << 4), 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runGetFlagCase("getFlag", 5, seeded_global_flags, false, 0, 0, PGM_STOPPED, 0, 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runGetFlagCase("getFlag", NUMBER_OF_GLOBAL_FLAGS + 6, no_global_flags, true, ((uint32_t)1 << 6), 0, PGM_STOPPED, 0, 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runGetFlagCase("getFlag", FLAG_W, seeded_extra_global_flags, false, 0, 0, PGM_STOPPED, 0, 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runFnGetSystemFlagCase(FLAG_CPXRES, no_global_flags, false, 0, 0, PGM_STOPPED, ((uint64_t)1 << 4), 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runFnGetSystemFlagCase(FLAG_TOPHEX, no_global_flags, false, 0, 0, PGM_STOPPED, 0, 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runFlagCommandCase("fnSetFlag", FLAG_CPXRES, oracle_fnSetFlag, fnSetFlag, no_global_flags, false, 0, 0, PGM_STOPPED, 0, 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runFlagCommandCase("fnSetFlag", 5, oracle_fnSetFlag, fnSetFlag, no_global_flags, false, 0, 0, PGM_STOPPED, 0, 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runFlagCommandCase("fnSetFlag", NUMBER_OF_GLOBAL_FLAGS + 6, oracle_fnSetFlag, fnSetFlag, no_global_flags, true, 0, 0, PGM_STOPPED, 0, 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runFlagCommandCase("fnSetFlag", FLAG_W, oracle_fnSetFlag, fnSetFlag, no_global_flags, false, 0, 0, PGM_STOPPED, 0, 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runFlagCommandCase("fnSetFlag", (uint16_t)(FLAG_CPXRES | 0x4000), oracle_fnSetFlag, fnSetFlag, no_global_flags, false, 0, 7, PGM_WAITING, 0, 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runFlagCommandCase("fnSetFlag", FLAG_ALPHA, oracle_fnSetFlag, fnSetFlag, no_global_flags, false, 0, 0, PGM_STOPPED, 0, 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runFlagCommandCase("fnClearFlag", FLAG_CPXRES, oracle_fnClearFlag, fnClearFlag, no_global_flags, false, 0, 0, PGM_STOPPED, ((uint64_t)1 << 4), 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runFlagCommandCase("fnClearFlag", 5, oracle_fnClearFlag, fnClearFlag, seeded_global_flags, false, 0, 0, PGM_STOPPED, 0, 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runFlagCommandCase("fnFlipFlag", FLAG_TOPHEX, oracle_fnFlipFlag, fnFlipFlag, no_global_flags, false, 0, 0, PGM_STOPPED, 0, 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runFlagCommandCase("fnFlipFlag", FLAG_ALPHA, oracle_fnFlipFlag, fnFlipFlag, no_global_flags, false, 0, 0, PGM_STOPPED, 0, 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runFlagCommandCase("fnClFAll", NOT_CONFIRMED, oracle_fnClFAll, fnClFAll, seeded_global_flags, true, ((uint32_t)1 << 3), 0, PGM_STOPPED, 0, 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runFlagCommandCase("fnClFAll", 1234, oracle_fnClFAll, fnClFAll, seeded_global_flags, true, ((uint32_t)1 << 3), 0, PGM_STOPPED, 0, 0, 0, 0, 0, 0, SCRUPD_MANUAL_STATUSBAR);
  failures += runSetSettingCase(TF_H24, no_global_flags, false, 0, 0, PGM_STOPPED, AC_UPPER, NC_NORMAL, NC_NORMAL, 0, 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runSetSettingCase(FLAG_HPRP, no_global_flags, false, 0, 0, PGM_STOPPED, AC_UPPER, NC_NORMAL, NC_NORMAL, 0, 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runSetSettingCase(JC_NL, no_global_flags, false, 0, 0, PGM_STOPPED, AC_UPPER, NC_NORMAL, NC_NORMAL, 0, 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runSetSettingCase(FLAG_DENANY, no_global_flags, false, 0, 0, PGM_STOPPED, AC_UPPER, NC_NORMAL, NC_NORMAL, (uint64_t)1 << 10, 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runSetSettingCase(JC_UC, no_global_flags, false, 0, 0, PGM_STOPPED, AC_LOWER, NC_NORMAL, NC_NORMAL, 0, 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runSetSettingCase(JC_SS, no_global_flags, false, 0, 0, PGM_STOPPED, AC_UPPER, NC_SUBSCRIPT, NC_NORMAL, 0, 0, 0, 0, 0, 0, SCRUPD_AUTO);

  failures += runVoidCase("setSystemFlag", FLAG_CPXRES, oracle_setSystemFlag, setSystemFlag, 0, 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runVoidCase("setSystemFlag", FLAG_TOPHEX, oracle_setSystemFlag, setSystemFlag, 0, 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runVoidCase("setSystemFlag", FLAG_BCD, oracle_setSystemFlag, setSystemFlag, 0, 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runVoidCase("setSystemFlag", FLAG_SBtime, oracle_setSystemFlag, setSystemFlag, 0, ((uint64_t)1 << 23), 0, 0, 0, 5, SCRUPD_MANUAL_STATUSBAR);
  failures += runVoidCase("setSystemFlag", FLAG_FRACT, oracle_setSystemFlag, setSystemFlag, 0, (((uint64_t)1 << 7) | ((uint64_t)1 << 8)), 0, 0, 0, 0, SCRUPD_MANUAL_STATUSBAR);
  failures += runVoidCase("setSystemFlag", FLAG_IRFRAC, oracle_setSystemFlag, setSystemFlag, ((uint64_t)1 << 7), 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runVoidCase("setSystemFlag", FLAG_IRFRQ, oracle_setSystemFlag, setSystemFlag, ((uint64_t)1 << 7), 0, 0, 0, 0, 0, SCRUPD_AUTO);

  failures += runVoidCase("clearSystemFlag", FLAG_CPXRES, oracle_clearSystemFlag, clearSystemFlag, ((uint64_t)1 << 4), 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runVoidCase("flipSystemFlag", FLAG_TOPHEX, oracle_flipSystemFlag, flipSystemFlag, 0, 0, 0, 0, 0, 0, SCRUPD_AUTO);

  failures += runChangedCase("didSystemFlagChange", FLAG_CPXRES, 0, 0, ((uint64_t)1 << 4), 0, 0, 0, SCRUPD_AUTO);
  failures += runChangedCase("didSystemFlagChange", FLAG_TOPHEX, 0, 0, 0, ((uint64_t)1 << 24), 0, 0, SCRUPD_AUTO);
  failures += runChangedCase("didSystemFlagChange", 0x0080, 0, 0, 0, 0, ((uint64_t)1 << 0), 0, SCRUPD_AUTO);

  failures += runSetChangedCase("setSystemFlagChanged", FLAG_CPXRES, 0, 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runSetChangedCase("setSystemFlagChanged", FLAG_TOPHEX, 0, 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runSetChangedCase("setSystemFlagChanged", 0x0080, 0, 0, 0, 0, 0, 0, SCRUPD_AUTO);

  failures += runSetAllChangedCase(0, 0, 0, 0, 0, 0, SCRUPD_AUTO);

  failures += runForceCase(FLAG_BCD, 1, 0, 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runForceCase(FLAG_CPXRES, 0, ((uint64_t)1 << 4), 0, 0, 0, 0, 0, SCRUPD_AUTO);

  if(failures != 0) {
    fprintf(stderr, "%d flags parity checks failed\n", failures);
    return 1;
  }

  puts("flags parity checks passed");
  return 0;
}