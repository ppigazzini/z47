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

  failures += runGetCase("getSystemFlag", FLAG_CPXRES, ((uint64_t)1 << 4), 0, 0, 0, 0, 0, SCRUPD_AUTO);
  failures += runGetCase("getSystemFlag", FLAG_TOPHEX, 0, ((uint64_t)1 << 24), 0, 0, 0, 0, SCRUPD_AUTO);

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