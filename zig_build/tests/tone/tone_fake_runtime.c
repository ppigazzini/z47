// SPDX-License-Identifier: GPL-3.0-only

#include <string.h>

#include "tone_test_runtime.h"

static tone_snapshot_t snapshot;

void toneParityReset(void) {
  memset(&snapshot, 0, sizeof(snapshot));
}

void toneParitySetQuiet(bool_t quiet_enabled) {
  snapshot.quiet_enabled = quiet_enabled;
}

void toneParityCapture(tone_snapshot_t *out) {
  *out = snapshot;
}

bool_t getSystemFlag(int32_t sf) {
  return sf == FLAG_QUIET ? snapshot.quiet_enabled : false;
}

void audioTone(uint32_t frequency) {
  if(snapshot.audio_tone_calls < (sizeof(snapshot.tone_frequencies) / sizeof(snapshot.tone_frequencies[0]))) {
    snapshot.tone_frequencies[snapshot.audio_tone_calls] = frequency;
  }
  snapshot.audio_tone_calls++;
}

void lcd_refresh(void) {
  snapshot.lcd_refresh_calls++;
}

void refreshLcd(void *unusedData) {
  (void)unusedData;
  snapshot.refresh_lcd_calls++;
}