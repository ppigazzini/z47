// SPDX-License-Identifier: GPL-3.0-only

#include <string.h>

#include "c47.h"

void z47_calc_state_retained_saveCalc(void);
void z47_calc_state_retained_restoreCalc(void);
void z47_calc_state_save_sections(void);

void z47_calc_state_runtime_save_calc(void) {
  z47_calc_state_retained_saveCalc();
}

void z47_calc_state_runtime_restore_calc(void) {
  z47_calc_state_retained_restoreCalc();
}

bool_t z47_calc_state_runtime_check_power(void) {
#if defined(DMCP_BUILD)
  return power_check_screen();
#else
  return false;
#endif
}

int z47_calc_state_runtime_open_save(uint16_t saveType) {
  ioFilePath_t path;

  if(saveType == autoSave) {
    path = ioPathAutoSave;
  }
  else if(saveType == manualSave) {
    path = ioPathManualSave;
  }
  else {
    path = ioPathSaveStateFile;
  }

  return ioFileOpen(path, ioModeWrite);
}

int z47_calc_state_runtime_open_load(uint16_t loadType) {
  ioFilePath_t path;

  if(loadType == autoLoad) {
    path = ioPathAutoSave;
  }
  else if(loadType == manualLoad) {
    path = ioPathManualSave;
  }
  else {
    path = ioPathLoadStateFile;
  }

  return ioFileOpen(path, ioModeRead);
}

void z47_calc_state_runtime_close_file(void) {
  ioFileClose();
}

void z47_calc_state_runtime_display_write_error(void) {
  #if !defined(DMCP_BUILD)
    printf("Cannot SAVE in file C47.sav!\n");
  #endif
  displayCalcErrorMessage(ERROR_CANNOT_WRITE_FILE, ERR_REGISTER_LINE, REGISTER_X);
}

void z47_calc_state_runtime_display_read_error(void) {
  displayCalcErrorMessage(ERROR_CANNOT_READ_FILE, ERR_REGISTER_LINE, REGISTER_X);
}

void z47_calc_state_runtime_unwind_all_subroutines(void) {
  while(currentSubroutineLevel > 0) {
    fnReturn(0);
  }
}

void z47_calc_state_runtime_read_line(char *buffer) {
  readLine(buffer);
}

bool_t z47_calc_state_runtime_line_equals(const char *line, const char *expected) {
  return strcmp(line, expected) == 0;
}

uint32_t z47_calc_state_runtime_parse_u32_line(const char *line) {
  return stringToUint32(line);
}

bool_t z47_calc_state_runtime_allow_user_keys(uint16_t savedCalcModel) {
  #if CALCMODEL == USER_C47
    return savedCalcModel == USER_C47;
  #elif CALCMODEL == USER_R47
    return savedCalcModel == USER_R47;
  #else
    (void)savedCalcModel;
    return false;
  #endif
}

void z47_calc_state_runtime_fixup_r47_shift_keys(void) {
  if(calcModel == USER_R47f_g || calcModel == USER_R47fg_g || calcModel == USER_R47fg_bk || calcModel == USER_R47bk_fg) {
    for(int i = 10; i <= 11; ++i) {
      kbd_usr[i].primary = kbd_std[i].primary;
      kbd_usr[i].keyLblAim = kbd_std[i].keyLblAim;
      kbd_usr[i].primaryAim = kbd_std[i].primaryAim;
      kbd_usr[i].primaryTam = kbd_std[i].primaryTam;
    }
  }
}

void z47_calc_state_runtime_restart_post_load_timers(void) {
  #if defined(DMCP_BUILD)
    sys_timer_disable(TIMER_IDX_REFRESH_SLEEP);
    sys_timer_start(TIMER_IDX_REFRESH_SLEEP, 1000);
    fnTimerStart(TO_KB_ACTV, TO_KB_ACTV, TO_KB_ACTV_MEDIUM);
  #endif
}

void z47_calc_state_runtime_stamp_last_state_file_opened(void) {
  getDateString(lastStateFileOpened);
  strcat(lastStateFileOpened, ": ");
  stringCopy(lastStateFileOpened + stringByteLength(lastStateFileOpened), fileNameSelected);
}

void z47_calc_state_runtime_show_saving_status(void) {
  printStatus(0, errorMessages[SAVING_STATE_FILE], force);
}

void z47_calc_state_runtime_show_loading_status(void) {
  printStatus(0, errorMessages[LOADING_STATE_FILE], force);
}

void z47_calc_state_runtime_write_save_sections(void) {
  z47_calc_state_save_sections();
}

void z47_calc_state_runtime_finish_load_ui(uint16_t refreshCode) {
  fnClearFlag(FLAG_USER);
  screenUpdatingMode &= ~SCRUPD_MANUAL_MENU;
  refreshScreen(refreshCode);
}