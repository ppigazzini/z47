// SPDX-License-Identifier: GPL-3.0-only

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "calc_state_test_runtime.h"

uint8_t lastErrorCode = 77;
uint8_t previousErrorCode = 88;
uint8_t temporaryInformation = 19;
uint8_t screenUpdatingMode = (uint8_t)(SCRUPD_MANUAL_MENU | 0x20u);
int16_t cachedDynamicMenu = 17;

static uint16_t savedCalcModelState = 0;
static uint32_t loadedVersionState = 0;
static char loadFile[MAX_CALC_STATE_PARITY_FILE_BYTES];
static size_t loadFileSize = 0;
static size_t loadFileOffset = 0;
static int openResult = FILE_OK;
static bool_t powerBlocked = false;
static bool_t fileOpen = false;
static uint16_t openedLoadPath = 0xffffu;
static uint16_t openedSavePath = 0xffffu;
static uint32_t closeFileCalls = 0;
static uint32_t checkPowerCalls = 0;
static uint32_t displayWriteErrorCalls = 0;
static uint32_t displayReadErrorCalls = 0;
static uint32_t unwindCalls = 0;
static uint32_t readLineCalls = 0;
static uint32_t restoreCalls = 0;
static uint32_t writeSaveSectionsCalls = 0;
static uint32_t saveCalcCalls = 0;
static uint32_t restoreCalcCalls = 0;
static uint16_t lastRestoreLoadMode = 0;
static uint16_t lastRestoreS = 0;
static uint16_t lastRestoreN = 0;
static uint16_t lastRestoreD = 0;
static bool_t lastAllowUserKeys = false;
static uint32_t restoreContinueCount = 0;
static uint16_t acceptedSavedCalcModel = USER_C47;
static uint32_t restartTimersCalls = 0;
static uint32_t r47ShiftFixupCalls = 0;
static uint32_t showSavingStatusCalls = 0;
static uint32_t showLoadingStatusCalls = 0;
static uint32_t finishLoadUiCalls = 0;
static uint32_t clearUserCalls = 0;
static uint16_t finishLoadUiRefreshCode = 0;
static char fileNameSelected[32] = "STATE.SAV";
static char lastStateFileOpened[MAX_CALC_STATE_LAST_STATE_FILE_BYTES];

void calcStateParityReset(void) {
  savedCalcModelState = 0;
  loadedVersionState = 0;
  loadFile[0] = 0;
  loadFileSize = 0;
  loadFileOffset = 0;
  openResult = FILE_OK;
  powerBlocked = false;
  fileOpen = false;
  openedLoadPath = 0xffffu;
  openedSavePath = 0xffffu;
  closeFileCalls = 0;
  checkPowerCalls = 0;
  displayWriteErrorCalls = 0;
  displayReadErrorCalls = 0;
  unwindCalls = 0;
  readLineCalls = 0;
  restoreCalls = 0;
  writeSaveSectionsCalls = 0;
  saveCalcCalls = 0;
  restoreCalcCalls = 0;
  lastRestoreLoadMode = 0;
  lastRestoreS = 0;
  lastRestoreN = 0;
  lastRestoreD = 0;
  lastAllowUserKeys = false;
  restoreContinueCount = 0;
  acceptedSavedCalcModel = USER_C47;
  restartTimersCalls = 0;
  r47ShiftFixupCalls = 0;
  showSavingStatusCalls = 0;
  showLoadingStatusCalls = 0;
  finishLoadUiCalls = 0;
  clearUserCalls = 0;
  finishLoadUiRefreshCode = 0;
  strcpy(fileNameSelected, "STATE.SAV");
  lastStateFileOpened[0] = 0;
  lastErrorCode = 77;
  previousErrorCode = 88;
  temporaryInformation = 19;
  screenUpdatingMode = (uint8_t)(SCRUPD_MANUAL_MENU | 0x20u);
  cachedDynamicMenu = 17;
}

void calcStateParitySetLoadFile(const char *contents) {
  size_t len = strlen(contents);

  if(len >= sizeof(loadFile)) {
    len = sizeof(loadFile) - 1;
  }
  memcpy(loadFile, contents, len);
  loadFile[len] = 0;
  loadFileSize = len;
  loadFileOffset = 0;
}

void calcStateParitySetOpenResult(int result) {
  openResult = result;
}

void calcStateParitySetAcceptedSavedCalcModel(uint16_t savedCalcModel) {
  acceptedSavedCalcModel = savedCalcModel;
}

void calcStateParitySetSelectedFile(const char *fileName) {
  strncpy(fileNameSelected, fileName, sizeof(fileNameSelected) - 1);
  fileNameSelected[sizeof(fileNameSelected) - 1] = 0;
}

void calcStateParitySetPowerBlocked(bool_t blocked) {
  powerBlocked = blocked;
}

void calcStateParitySetRestoreContinueCount(uint32_t continueCount) {
  restoreContinueCount = continueCount;
}

void calcStateParityCapture(calc_state_snapshot_t *snapshot) {
  memset(snapshot, 0, sizeof(*snapshot));
  snapshot->open_result = openResult;
  snapshot->opened_load_path = openedLoadPath;
  snapshot->opened_save_path = openedSavePath;
  snapshot->close_file_calls = closeFileCalls;
  snapshot->check_power_calls = checkPowerCalls;
  snapshot->display_write_error_calls = displayWriteErrorCalls;
  snapshot->display_read_error_calls = displayReadErrorCalls;
  snapshot->unwind_calls = unwindCalls;
  snapshot->read_line_calls = readLineCalls;
  snapshot->restore_calls = restoreCalls;
  snapshot->write_save_sections_calls = writeSaveSectionsCalls;
  snapshot->save_calc_calls = saveCalcCalls;
  snapshot->restore_calc_calls = restoreCalcCalls;
  snapshot->last_restore_load_mode = lastRestoreLoadMode;
  snapshot->last_restore_s = lastRestoreS;
  snapshot->last_restore_n = lastRestoreN;
  snapshot->last_restore_d = lastRestoreD;
  snapshot->last_allow_user_keys = lastAllowUserKeys;
  snapshot->restart_timers_calls = restartTimersCalls;
  snapshot->r47_shift_fixup_calls = r47ShiftFixupCalls;
  snapshot->show_saving_status_calls = showSavingStatusCalls;
  snapshot->show_loading_status_calls = showLoadingStatusCalls;
  snapshot->finish_load_ui_calls = finishLoadUiCalls;
  snapshot->clear_user_calls = clearUserCalls;
  snapshot->finish_load_ui_refresh_code = finishLoadUiRefreshCode;
  snapshot->saved_calc_model = savedCalcModelState;
  snapshot->loaded_version = loadedVersionState;
  snapshot->last_error_code = lastErrorCode;
  snapshot->previous_error_code = previousErrorCode;
  snapshot->temporary_information = temporaryInformation;
  snapshot->screen_updating_mode = screenUpdatingMode;
  snapshot->cached_dynamic_menu = cachedDynamicMenu;
  strncpy(snapshot->last_state_file_opened, lastStateFileOpened, sizeof(snapshot->last_state_file_opened) - 1);
  snapshot->last_state_file_opened[sizeof(snapshot->last_state_file_opened) - 1] = 0;
}

void z47_calc_state_reset_load_context(void) {
  savedCalcModelState = 0;
  loadedVersionState = 0;
}

void z47_calc_state_set_saved_calc_model(uint16_t saved_calc_model) {
  savedCalcModelState = saved_calc_model;
}

uint16_t z47_calc_state_get_saved_calc_model(void) {
  return savedCalcModelState;
}

void z47_calc_state_set_loaded_version(uint32_t version) {
  loadedVersionState = version;
}

uint32_t z47_calc_state_get_loaded_version(void) {
  return loadedVersionState;
}

uint32_t z47_calc_state_get_version_allowed(void) {
  return 10000005u;
}

uint32_t z47_calc_state_get_config_file_version(void) {
  return 10000023u;
}

bool_t z47_calc_state_restore_one_section(uint16_t loadMode, uint16_t s, uint16_t n, uint16_t d, bool_t allowUserKeys) {
  restoreCalls++;
  lastRestoreLoadMode = loadMode;
  lastRestoreS = s;
  lastRestoreN = n;
  lastRestoreD = d;
  lastAllowUserKeys = allowUserKeys;
  return restoreCalls <= restoreContinueCount;
}

bool_t z47_calc_state_runtime_check_power(void) {
  checkPowerCalls++;
  return powerBlocked;
}

int z47_calc_state_runtime_open_save(uint16_t saveType) {
  openedSavePath = saveType;
  fileOpen = false;
  if(openResult != FILE_OK) {
    return openResult;
  }

  fileOpen = true;
  return FILE_OK;
}

int z47_calc_state_runtime_open_load(uint16_t loadType) {
  switch(loadType) {
    case autoLoad:
      openedLoadPath = 1;
      break;
    case manualLoad:
      openedLoadPath = 0;
      break;
    default:
      openedLoadPath = 7;
      break;
  }

  fileOpen = false;
  if(openResult != FILE_OK) {
    return openResult;
  }

  loadFileOffset = 0;
  fileOpen = true;
  return FILE_OK;
}

void z47_calc_state_runtime_close_file(void) {
  closeFileCalls++;
  fileOpen = false;
}

void z47_calc_state_runtime_display_write_error(void) {
  displayWriteErrorCalls++;
}

void z47_calc_state_runtime_display_read_error(void) {
  displayReadErrorCalls++;
}

void z47_calc_state_runtime_unwind_all_subroutines(void) {
  unwindCalls++;
}

void z47_calc_state_runtime_read_line(char *buffer) {
  size_t index = 0;

  readLineCalls++;
  if(!fileOpen) {
    buffer[0] = 0;
    return;
  }

  while(loadFileOffset < loadFileSize && loadFile[loadFileOffset] != '\n') {
    buffer[index++] = loadFile[loadFileOffset++];
  }
  if(loadFileOffset < loadFileSize && loadFile[loadFileOffset] == '\n') {
    loadFileOffset++;
  }
  buffer[index] = 0;
}

bool_t z47_calc_state_runtime_line_equals(const char *line, const char *expected) {
  return strcmp(line, expected) == 0;
}

uint32_t z47_calc_state_runtime_parse_u32_line(const char *line) {
  return (uint32_t)strtoul(line, NULL, 10);
}

bool_t z47_calc_state_runtime_allow_user_keys(uint16_t savedCalcModel) {
  return savedCalcModel == acceptedSavedCalcModel;
}

void z47_calc_state_runtime_fixup_r47_shift_keys(void) {
  r47ShiftFixupCalls++;
}

void z47_calc_state_runtime_restart_post_load_timers(void) {
  restartTimersCalls++;
}

void z47_calc_state_runtime_stamp_last_state_file_opened(void) {
  snprintf(lastStateFileOpened, sizeof(lastStateFileOpened), "2026-05-13: %s", fileNameSelected);
}

void z47_calc_state_runtime_show_saving_status(void) {
  showSavingStatusCalls++;
}

void z47_calc_state_runtime_show_loading_status(void) {
  showLoadingStatusCalls++;
}

void z47_calc_state_runtime_write_save_sections(void) {
  if(fileOpen) {
    writeSaveSectionsCalls++;
  }
}

void z47_calc_state_runtime_finish_load_ui(uint16_t refreshCode) {
  clearUserCalls++;
  finishLoadUiCalls++;
  finishLoadUiRefreshCode = refreshCode;
  screenUpdatingMode &= (uint8_t)~SCRUPD_MANUAL_MENU;
}

void z47_calc_state_runtime_save_calc(void) {
  saveCalcCalls++;
}

void z47_calc_state_runtime_restore_calc(void) {
  restoreCalcCalls++;
}