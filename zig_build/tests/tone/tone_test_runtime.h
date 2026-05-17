// SPDX-License-Identifier: GPL-3.0-only

#ifndef Z47_TONE_TEST_RUNTIME_H
#define Z47_TONE_TEST_RUNTIME_H

#include "c47.h"

typedef struct {
  bool_t quiet_enabled;
  uint32_t audio_tone_calls;
  uint32_t tone_frequencies[8];
  uint32_t lcd_refresh_calls;
  uint32_t refresh_lcd_calls;
} tone_snapshot_t;

void toneParityReset(void);
void toneParitySetQuiet(bool_t quiet_enabled);
void toneParityCapture(tone_snapshot_t *snapshot);

#endif