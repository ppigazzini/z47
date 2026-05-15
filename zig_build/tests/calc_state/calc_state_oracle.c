// SPDX-License-Identifier: GPL-3.0-only

#include "calc_state_test_runtime.h"

static bool_t isAutoLoadCompatibleVersion(uint32_t loadedVersion) {
  return loadedVersion >= z47_calc_state_get_version_allowed() && loadedVersion <= z47_calc_state_get_config_file_version();
}

static void parseSaveFileRevision(void) {
  char headerKey[256];
  char ignoredRevision[256];
  char calculatorId[256];
  char versionLine[256];
  uint16_t savedCalcModel = 0;
  uint32_t loadedVersion = 0;

  z47_calc_state_runtime_read_line(headerKey);
  if(z47_calc_state_runtime_line_equals(headerKey, "SAVE_FILE_REVISION")) {
    z47_calc_state_runtime_read_line(ignoredRevision);
    z47_calc_state_runtime_read_line(calculatorId);
    z47_calc_state_runtime_read_line(versionLine);

    if(z47_calc_state_runtime_line_equals(calculatorId, "C47_save_file_00")) {
      savedCalcModel = USER_C47;
    }
    else if(z47_calc_state_runtime_line_equals(calculatorId, "R47_save_file_00")) {
      savedCalcModel = USER_R47;
    }

    if(savedCalcModel == USER_C47 || savedCalcModel == USER_R47) {
      loadedVersion = z47_calc_state_runtime_parse_u32_line(versionLine);
      if(loadedVersion < 10000000u || loadedVersion > 20000000u) {
        loadedVersion = 0;
      }
    }
  }

  z47_calc_state_set_saved_calc_model(savedCalcModel);
  z47_calc_state_set_loaded_version(loadedVersion);
}

static void oracle_doSave(uint16_t saveType) {
  int ret;

  z47_calc_state_runtime_show_saving_status();
  if(z47_calc_state_runtime_check_power()) {
    return;
  }

  ret = z47_calc_state_runtime_open_save(saveType);
  if(ret != FILE_OK) {
    if(ret != FILE_CANCEL) {
      z47_calc_state_runtime_display_write_error();
    }
    return;
  }

  z47_calc_state_runtime_write_save_sections();
  z47_calc_state_runtime_close_file();
  temporaryInformation = TI_SAVED;
}

void oracle_fnSave(uint16_t saveMode) {
  if(saveMode == SM_MANUAL_SAVE) {
    oracle_doSave(manualSave);
  }
  else if(saveMode == SM_STATE_SAVE) {
    oracle_doSave(stateSave);
  }
}

void oracle_doLoad(uint16_t loadMode, uint16_t s, uint16_t n, uint16_t d, uint16_t loadType) {
  int ret;
  uint32_t loadedVersion;
  uint16_t savedCalcModel;
  bool_t enableLoad = false;

  z47_calc_state_reset_load_context();
  ret = z47_calc_state_runtime_open_load(loadType);
  if(ret != FILE_OK) {
    if(ret != FILE_CANCEL) {
      z47_calc_state_runtime_display_read_error();
    }
    return;
  }

  if(loadMode == LM_ALL) {
    z47_calc_state_runtime_unwind_all_subroutines();
  }

  parseSaveFileRevision();
  savedCalcModel = z47_calc_state_get_saved_calc_model();
  loadedVersion = z47_calc_state_get_loaded_version();

  switch(loadType) {
    case manualLoad:
      switch(loadMode) {
        case LM_ALL:
        case LM_PROGRAMS:
        case LM_REGISTERS:
        case LM_SYSTEM_STATE:
        case LM_SUMS:
        case LM_NAMED_VARIABLES:
          enableLoad = true;
          break;
        default:
          break;
      }
      break;
    case stateLoad:
      if(loadMode == LM_ALL) {
        enableLoad = true;
      }
      break;
    case autoLoad:
      if(loadMode == LM_ALL && isAutoLoadCompatibleVersion(loadedVersion)) {
        enableLoad = true;
      }
      break;
    default:
      break;
  }

  if(enableLoad) {
    bool_t allowUserKeys = z47_calc_state_runtime_allow_user_keys(savedCalcModel);
    while(z47_calc_state_restore_one_section(loadMode, s, n, d, allowUserKeys)) {
    }
    z47_calc_state_runtime_fixup_r47_shift_keys();
  }

  lastErrorCode = ERROR_NONE;
  previousErrorCode = lastErrorCode;

  z47_calc_state_runtime_close_file();
  z47_calc_state_runtime_restart_post_load_timers();

  if(loadType == manualLoad && loadMode == LM_ALL) {
    temporaryInformation = TI_BACKUP_RESTORED;
    z47_calc_state_runtime_stamp_last_state_file_opened();
  }
  else if(loadType == autoLoad && loadMode == LM_ALL && isAutoLoadCompatibleVersion(loadedVersion)) {
    temporaryInformation = TI_BACKUP_RESTORED;
    z47_calc_state_runtime_stamp_last_state_file_opened();
  }
  else if(loadType == stateLoad) {
    temporaryInformation = TI_STATEFILE_RESTORED;
    z47_calc_state_runtime_stamp_last_state_file_opened();
  }
  else if(loadMode == LM_PROGRAMS) {
    temporaryInformation = TI_PROGRAMS_RESTORED;
  }
  else if(loadMode == LM_REGISTERS) {
    temporaryInformation = TI_REGISTERS_RESTORED;
  }
  else if(loadMode == LM_SYSTEM_STATE) {
    temporaryInformation = TI_SETTINGS_RESTORED;
  }
  else if(loadMode == LM_SUMS) {
    temporaryInformation = TI_SUMS_RESTORED;
  }
  else if(loadMode == LM_NAMED_VARIABLES) {
    temporaryInformation = TI_VARIABLES_RESTORED;
  }

  cachedDynamicMenu = 0;
}

void oracle_fnLoad(uint16_t loadMode) {
  z47_calc_state_runtime_show_loading_status();
  if(loadMode == LM_STATE_LOAD) {
    oracle_doLoad(LM_ALL, 0, 0, 0, stateLoad);
  }
  else {
    oracle_doLoad(loadMode, 0, 0, 0, manualLoad);
  }
  z47_calc_state_runtime_finish_load_ui(94);
}

void oracle_fnSaveAuto(uint16_t unusedButMandatoryParameter) {
  (void)unusedButMandatoryParameter;
}

void oracle_fnLoadAuto(void) {
  oracle_doLoad(LM_ALL, 0, 0, 0, autoLoad);
  z47_calc_state_runtime_finish_load_ui(95);
}

void oracle_saveCalc(void) {
  z47_calc_state_runtime_save_calc();
}

void oracle_restoreCalc(void) {
  z47_calc_state_runtime_restore_calc();
}