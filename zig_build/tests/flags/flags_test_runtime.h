// SPDX-License-Identifier: GPL-3.0-only

#ifndef Z47_FLAGS_TEST_RUNTIME_H
#define Z47_FLAGS_TEST_RUNTIME_H

#include "c47.h"

typedef struct {
  uint64_t system_flags0;
  uint64_t system_flags1;
  uint64_t system_flags0_changed;
  uint64_t system_flags1_changed;
  uint64_t system_flags2_changed;
  uint32_t last_integer_base;
  uint8_t screen_updating_mode;
  uint32_t refresh_state_calls;
  uint32_t clear_status_bar_calls;
  uint32_t change_base_calls;
  uint8_t last_clear_status_bar_info;
  uint16_t last_change_base_arg;
} flags_parity_snapshot_t;

extern uint64_t systemFlags0Changed;
extern uint64_t systemFlags1Changed;
extern uint64_t systemFlags2Changed;

extern uint64_t oracle_systemFlags0Changed;
extern uint64_t oracle_systemFlags1Changed;
extern uint64_t oracle_systemFlags2Changed;

bool_t oracle_getSystemFlag(int32_t sf);
void oracle_setSystemFlag(unsigned int sf);
void oracle_clearSystemFlag(unsigned int sf);
void oracle_flipSystemFlag(unsigned int sf);
bool_t oracle_didSystemFlagChange(int32_t sf);
void oracle_setSystemFlagChanged(int32_t sf);
void oracle_setAllSystemFlagChanged(void);
void oracle_forceSystemFlag(unsigned int sf, int set);

void flagsParitySeed(uint64_t system_flags0,
                     uint64_t system_flags1,
                     uint64_t system_flags0_changed,
                     uint64_t system_flags1_changed,
                     uint64_t system_flags2_changed,
                     uint32_t last_integer_base,
                     uint8_t screen_updating_mode);
void flagsParityCaptureLive(flags_parity_snapshot_t *snapshot);
void flagsParityCaptureOracle(flags_parity_snapshot_t *snapshot);

#endif