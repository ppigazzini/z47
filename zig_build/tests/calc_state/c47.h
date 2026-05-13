// SPDX-License-Identifier: GPL-3.0-only

#ifndef C47_H
#define C47_H

#include <stdbool.h>
#include <stdint.h>

typedef bool bool_t;

enum {
  FILE_OK = 1,
  FILE_CANCEL = 2,
};

enum {
  autoLoad = 0,
  manualLoad = 1,
  stateLoad = 2,
  autoSave = 3,
  manualSave = 4,
  stateSave = 5,
};

enum {
  SM_MANUAL_SAVE = 0,
  SM_STATE_SAVE = 1,
};

enum {
  LM_ALL = 0,
  LM_PROGRAMS = 1,
  LM_REGISTERS = 2,
  LM_NAMED_VARIABLES = 3,
  LM_SUMS = 4,
  LM_SYSTEM_STATE = 5,
  LM_REGISTERS_PARTIAL = 6,
  LM_STATE_LOAD = 7,
};

enum {
  USER_C47 = 46,
  USER_R47 = 66,
};

enum {
  ERROR_NONE = 0,
};

enum {
  TI_SAVED = 32,
  TI_BACKUP_RESTORED = 33,
  TI_STATEFILE_RESTORED = 71,
  TI_PROGRAMS_RESTORED = 87,
  TI_REGISTERS_RESTORED = 88,
  TI_SETTINGS_RESTORED = 89,
  TI_SUMS_RESTORED = 90,
  TI_VARIABLES_RESTORED = 91,
};

enum {
  SCRUPD_MANUAL_MENU = 0x04,
};

void doLoad(uint16_t loadMode, uint16_t s, uint16_t n, uint16_t d, uint16_t loadType);
void fnSave(uint16_t saveMode);
void fnLoad(uint16_t loadMode);
void fnSaveAuto(uint16_t unusedButMandatoryParameter);
void fnLoadAuto(void);

#endif