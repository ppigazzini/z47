// SPDX-License-Identifier: GPL-3.0-only

#ifndef Z47_KEYBOARD_STATE_FAKE_C47_H
#define Z47_KEYBOARD_STATE_FAKE_C47_H

#include <stdbool.h>
#include <stdint.h>

typedef bool bool_t;

typedef struct {
  int16_t primaryAim;
  int16_t gShiftedAim;
} calcKey_t;

typedef struct {
  uint8_t mode;
  bool_t alpha;
} tam_state_t;

enum {
  ITM_A = 100,
  ITM_Z = 125,
  ITM_a = 126,
  ITM_z = 151,
  ITM_sigma = 170,
  ITM_SIGMA = 171,
  ITM_delta = 172,
  ITM_DELTA = 173,
  ITM_NULL = 174,
  ITM_SPACE = 175,
  ITM_EXIT1 = 176,
  ITM_UP1 = 177,
  ITM_DOWN1 = 178,
  ITM_BACKSPACE = 179,
  ITM_DIGIT_1 = 180,
  ITM_Q = 181,
};

enum {
  CM_NORMAL = 0,
  CM_AIM = 1,
  CM_EIM = 2,
  CM_PEM = 3,
  CM_ASSIGN = 4,
  CM_NIM = 5,
  CM_REGISTER_BROWSER = 6,
  CM_FLAG_BROWSER = 7,
  CM_FONT_BROWSER = 8,
  CM_PLOT_STAT = 9,
  CM_MIM = 10,
  CM_TIMER = 11,
  CM_GRAPH = 12,
  CM_ASN_BROWSER = 13,
  CM_LISTXY = 14,
};

enum {
  FLAG_USER = 1,
  FLAG_NUMLOCK = 2,
  FLAG_FRACT = 3,
  FLAG_IRFRAC = 4,
  FLAG_IRFRQ = 5,
};

enum {
  ITM_ENTER = 180,
  ITM_toREAL = 181,
  ITM_CC = 182,
  ITM_UP1_ITEM = 183,
  ITM_DOWN1_ITEM = 184,
  ITM_EXIT1_ITEM = 185,
  ITM_BACKSPACE_ITEM = 186,
  ITM_dotD = 187,
  KEY_COMPLEX = 188,
};

enum {
  TI_NO_INFO = 0,
};

enum {
  PGM_WAITING = 1,
};

enum {
  SCRUPD_MANUAL_STACK = 0x02,
  SCRUPD_MANUAL_MENU = 0x04,
  SCRUPD_SKIP_STACK_ONE_TIME = 0x20,
};

extern uint8_t calcMode;
extern int16_t itemToBeAssigned;
extern int16_t lastKeyCode;
extern tam_state_t tam;
extern calcKey_t kbd_std[37];
extern calcKey_t kbd_usr[37];
extern uint8_t currentFlgScr;
extern uint8_t lastErrorCode;
extern uint8_t temporaryInformation;
extern uint8_t programRunStop;
extern uint8_t screenUpdatingMode;
extern bool_t keyActionProcessed;
extern int16_t ListXYposition;
extern int runFunctionCalls;
extern int16_t lastRunFunctionItem;
extern int nimBufferCalls;
extern int16_t lastNimBufferItem;
extern int refreshScreenCalls;
extern int16_t lastRefreshScreenId;
extern int retainedProcessKeyActionCalls;
extern int retainedFnKeyEnterCalls;
extern int retainedFnKeyExitCalls;
extern int retainedFnKeyCCCalls;
extern int retainedFnKeyBackspaceCalls;
extern int retainedFnKeyUpCalls;
extern int retainedFnKeyDotDCalls;
extern int retainedFnKeyDownCalls;

bool_t getSystemFlag(int32_t flag);
void clearSystemFlag(uint32_t flag);
void keyboardStateReset(void);
void keyboardStateSetFlag(int32_t flag, bool_t enabled);
uint32_t keyboardStateFlags(void);
void runFunction(int16_t item);
void addItemToNimBuffer(int16_t item);
void refreshScreen(int16_t reason);

bool_t caseReplacements(uint8_t id, bool_t lowerCaseSelected, int16_t item, int16_t *itemOut);
bool_t keyReplacements(int16_t item, int16_t *item1, bool_t NL, bool_t FSHIFT, bool_t GSHIFT);
uint16_t numlockReplacements(uint16_t id, int16_t item, bool_t NL, bool_t FSHIFT, bool_t GSHIFT);
void setLastKeyCode(int key);
void processKeyAction(int16_t item);
void fnKeyEnter(uint16_t unusedButMandatoryParameter);
void fnKeyExit(uint16_t unusedButMandatoryParameter);
void fnKeyCC(uint16_t unusedButMandatoryParameter);
void fnKeyBackspace(uint16_t unusedButMandatoryParameter);
void fnKeyUp(uint16_t unusedButMandatoryParameter);
void fnKeyDown(uint16_t unusedButMandatoryParameter);
void fnKeyDotD(uint16_t unusedButMandatoryParameter);

bool_t oracle_caseReplacements(uint8_t id, bool_t lowerCaseSelected, int16_t item, int16_t *itemOut);
bool_t oracle_keyReplacements(int16_t item, int16_t *item1, bool_t NL, bool_t FSHIFT, bool_t GSHIFT);
uint16_t oracle_numlockReplacements(uint16_t id, int16_t item, bool_t NL, bool_t FSHIFT, bool_t GSHIFT);
void oracle_setLastKeyCode(int key);
void oracle_processKeyAction(int16_t item);
void oracle_fnKeyEnter(uint16_t unusedButMandatoryParameter);
void oracle_fnKeyExit(uint16_t unusedButMandatoryParameter);
void oracle_fnKeyCC(uint16_t unusedButMandatoryParameter);
void oracle_fnKeyBackspace(uint16_t unusedButMandatoryParameter);
void oracle_fnKeyUp(uint16_t unusedButMandatoryParameter);
void oracle_fnKeyDown(uint16_t unusedButMandatoryParameter);
void oracle_fnKeyDotD(uint16_t unusedButMandatoryParameter);

#endif