// SPDX-License-Identifier: GPL-3.0-only

#ifndef Z47_CALC_STATE_TEST_RUNTIME_H
#define Z47_CALC_STATE_TEST_RUNTIME_H

#include "c47.h"

#define MAX_CALC_STATE_PARITY_FILE_BYTES 4096
#define MAX_CALC_STATE_LAST_STATE_FILE_BYTES 64

typedef struct {
  int open_result;
  uint16_t opened_load_path;
  uint16_t opened_save_path;
  uint32_t close_file_calls;
  uint32_t check_power_calls;
  uint32_t display_write_error_calls;
  uint32_t display_read_error_calls;
  uint32_t unwind_calls;
  uint32_t read_line_calls;
  uint32_t restore_calls;
  uint32_t write_save_sections_calls;
  uint16_t last_restore_load_mode;
  uint16_t last_restore_s;
  uint16_t last_restore_n;
  uint16_t last_restore_d;
  bool_t last_allow_user_keys;
  uint32_t restart_timers_calls;
  uint32_t r47_shift_fixup_calls;
  uint32_t show_saving_status_calls;
  uint32_t show_loading_status_calls;
  uint32_t finish_load_ui_calls;
  uint32_t clear_user_calls;
  uint16_t finish_load_ui_refresh_code;
  uint16_t saved_calc_model;
  uint32_t loaded_version;
  uint8_t last_error_code;
  uint8_t previous_error_code;
  uint8_t temporary_information;
  uint8_t screen_updating_mode;
  int16_t cached_dynamic_menu;
  char last_state_file_opened[MAX_CALC_STATE_LAST_STATE_FILE_BYTES];
} calc_state_snapshot_t;

void calcStateParityReset(void);
void calcStateParitySetLoadFile(const char *contents);
void calcStateParitySetOpenResult(int result);
void calcStateParitySetAcceptedSavedCalcModel(uint16_t savedCalcModel);
void calcStateParitySetSelectedFile(const char *fileName);
void calcStateParitySetPowerBlocked(bool_t blocked);
void calcStateParitySetRestoreContinueCount(uint32_t continueCount);
void calcStateParityCapture(calc_state_snapshot_t *snapshot);

void oracle_fnSave(uint16_t saveMode);
void oracle_doLoad(uint16_t loadMode, uint16_t s, uint16_t n, uint16_t d, uint16_t loadType);
void oracle_fnLoad(uint16_t loadMode);
void oracle_fnSaveAuto(uint16_t unusedButMandatoryParameter);
void oracle_fnLoadAuto(void);

void z47_calc_state_reset_load_context(void);
void z47_calc_state_set_saved_calc_model(uint16_t saved_calc_model);
uint16_t z47_calc_state_get_saved_calc_model(void);
void z47_calc_state_set_loaded_version(uint32_t version);
uint32_t z47_calc_state_get_loaded_version(void);
uint32_t z47_calc_state_get_version_allowed(void);
uint32_t z47_calc_state_get_config_file_version(void);
bool_t z47_calc_state_restore_one_section(uint16_t loadMode, uint16_t s, uint16_t n, uint16_t d, bool_t allowUserKeys);

bool_t z47_calc_state_runtime_check_power(void);
int z47_calc_state_runtime_open_save(uint16_t saveType);
int z47_calc_state_runtime_open_load(uint16_t loadType);
void z47_calc_state_runtime_close_file(void);
void z47_calc_state_runtime_display_write_error(void);
void z47_calc_state_runtime_display_read_error(void);
void z47_calc_state_runtime_unwind_all_subroutines(void);
void z47_calc_state_runtime_read_line(char *buffer);
bool_t z47_calc_state_runtime_line_equals(const char *line, const char *expected);
uint32_t z47_calc_state_runtime_parse_u32_line(const char *line);
bool_t z47_calc_state_runtime_allow_user_keys(uint16_t savedCalcModel);
void z47_calc_state_runtime_fixup_r47_shift_keys(void);
void z47_calc_state_runtime_restart_post_load_timers(void);
void z47_calc_state_runtime_stamp_last_state_file_opened(void);
void z47_calc_state_runtime_show_saving_status(void);
void z47_calc_state_runtime_show_loading_status(void);
void z47_calc_state_runtime_write_save_sections(void);
void z47_calc_state_runtime_finish_load_ui(uint16_t refreshCode);

extern uint8_t lastErrorCode;
extern uint8_t previousErrorCode;
extern uint8_t temporaryInformation;
extern uint8_t screenUpdatingMode;
extern int16_t cachedDynamicMenu;

#endif