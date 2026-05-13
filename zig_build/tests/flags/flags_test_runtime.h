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
  uint16_t global_flags[8];
  bool_t has_local_flags;
  uint32_t local_flags;
  uint8_t temporary_information;
  uint8_t program_run_stop;
  uint8_t alpha_case;
  uint8_t scr_lock;
  uint8_t next_char;
  uint32_t refresh_state_calls;
  uint32_t clear_status_bar_calls;
  uint32_t change_base_calls;
  uint32_t write_protected_error_calls;
  uint32_t enter_alpha_calls;
  uint32_t leave_alpha_calls;
  uint32_t leave_tam_calls;
  uint32_t clf_all_confirmation_calls;
  uint32_t show_alpha_mode_calls;
  uint8_t last_clear_status_bar_info;
  uint16_t last_change_base_arg;
} flags_parity_snapshot_t;

extern uint64_t systemFlags0Changed;
extern uint64_t systemFlags1Changed;
extern uint64_t systemFlags2Changed;

extern uint64_t oracle_systemFlags0Changed;
extern uint64_t oracle_systemFlags1Changed;
extern uint64_t oracle_systemFlags2Changed;
extern uint32_t writeProtectedErrorCalls;
extern uint32_t enterAlphaCalls;
extern uint32_t leaveAlphaCalls;
extern uint32_t leaveTamCalls;
extern uint32_t clFAllConfirmationCalls;

bool_t oracle_getFlag(uint16_t flag);
bool_t oracle_getSystemFlag(int32_t sf);
void oracle_fnGetSystemFlag(uint16_t systemFlag);
void oracle_fnSetFlag(uint16_t flag);
void oracle_fnClearFlag(uint16_t flag);
void oracle_fnFlipFlag(uint16_t flag);
void oracle_fnClFAll(uint16_t confirmation);
void oracle_SetSetting(uint16_t jmConfig);
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
void flagsParitySeedCommandState(const uint16_t global_flags[8],
                                 bool_t has_local_flags,
                                 uint32_t local_flags,
                                 uint8_t temporary_information,
                                 uint8_t program_run_stop);
void flagsParitySeedTextState(uint8_t alpha_case,
                              uint8_t scr_lock,
                              uint8_t next_char);
void flagsParityCaptureLive(flags_parity_snapshot_t *snapshot);
void flagsParityCaptureOracle(flags_parity_snapshot_t *snapshot);

#endif