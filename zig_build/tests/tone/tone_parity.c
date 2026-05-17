// SPDX-License-Identifier: GPL-3.0-only

#include <stdio.h>
#include <string.h>

#include "tone_test_runtime.h"

void fnTone(uint16_t toneNum);
void fnBeep(uint16_t unusedButMandatoryParameter);

void oracle_fnTone(uint16_t toneNum);
void oracle_fnBeep(uint16_t unusedButMandatoryParameter);

typedef void (*tone_fn)(uint16_t);

static int reportMismatch(const char *name,
                          uint16_t arg,
                          const tone_snapshot_t *expected,
                          const tone_snapshot_t *actual) {
  if(memcmp(expected, actual, sizeof(*expected)) == 0) {
    return 0;
  }

  fprintf(stderr,
          "%s(%u) parity mismatch\n"
          "  expected: quiet=%d audio=%u host_refresh=%u fw_refresh=%u\n"
          "  actual:   quiet=%d audio=%u host_refresh=%u fw_refresh=%u\n",
          name,
          arg,
          expected->quiet_enabled,
          expected->audio_tone_calls,
          expected->refresh_lcd_calls,
          expected->lcd_refresh_calls,
          actual->quiet_enabled,
          actual->audio_tone_calls,
          actual->refresh_lcd_calls,
          actual->lcd_refresh_calls);
  return 1;
}

static int runCase(const char *name,
                   tone_fn oracle_fn,
                   tone_fn zig_fn,
                   uint16_t arg,
                   bool_t quiet_enabled) {
  tone_snapshot_t expected;
  tone_snapshot_t actual;

  toneParityReset();
  toneParitySetQuiet(quiet_enabled);
  oracle_fn(arg);
  toneParityCapture(&expected);

  toneParityReset();
  toneParitySetQuiet(quiet_enabled);
  zig_fn(arg);
  toneParityCapture(&actual);

  return reportMismatch(name, arg, &expected, &actual);
}

int main(void) {
  int failures = 0;

  failures += runCase("fnTone", oracle_fnTone, fnTone, 3, false);
  failures += runCase("fnTone", oracle_fnTone, fnTone, 3, true);
  failures += runCase("fnTone", oracle_fnTone, fnTone, 99, false);
  failures += runCase("fnBeep", oracle_fnBeep, fnBeep, 0, false);
  failures += runCase("fnBeep", oracle_fnBeep, fnBeep, 0, true);

  if(failures != 0) {
    fprintf(stderr, "%d tone parity checks failed\n", failures);
    return 1;
  }

  return 0;
}