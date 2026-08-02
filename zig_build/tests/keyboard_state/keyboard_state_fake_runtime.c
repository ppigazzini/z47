// SPDX-License-Identifier: GPL-3.0-only

#include <string.h>

#include "c47.h"

uint8_t calcMode = CM_AIM;
int16_t itemToBeAssigned = 0;
uint8_t lastKeyCode = 0;
tam_state_t tam = {0, false};
calcKey_t kbd_std[37];
calcKey_t kbd_usr[37];
uint8_t currentFlgScr = 0;
uint8_t lastErrorCode = 0;
uint8_t temporaryInformation = TI_NO_INFO;
uint8_t programRunStop = 0;
uint8_t screenUpdatingMode = 0;
bool_t keyActionProcessed = false;
int16_t ListXYposition = 0;

int runFunctionCalls = 0;
int16_t lastRunFunctionItem = 0;
int nimBufferCalls = 0;
int16_t lastNimBufferItem = 0;
int refreshScreenCalls = 0;
int16_t lastRefreshScreenId = 0;
int legacyProcessKeyActionCalls = 0;
int legacyFnKeyEnterCalls = 0;
int legacyFnKeyExitCalls = 0;
int legacyFnKeyCCCalls = 0;
int legacyFnKeyBackspaceCalls = 0;
int legacyFnKeyUpCalls = 0;
int legacyFnKeyDotDCalls = 0;
int legacyFnKeyDownCalls = 0;

static uint32_t keyboardFlags = 0;

void keyboardStateReset(void) {
  calcMode = CM_AIM;
  itemToBeAssigned = 0;
  lastKeyCode = 0;
  tam.mode = 0;
  tam.alpha = false;
  currentFlgScr = 0;
  lastErrorCode = 0;
  temporaryInformation = TI_NO_INFO;
  programRunStop = 0;
  screenUpdatingMode = 0;
  keyActionProcessed = false;
  ListXYposition = 0;
  runFunctionCalls = 0;
  lastRunFunctionItem = 0;
  nimBufferCalls = 0;
  lastNimBufferItem = 0;
  refreshScreenCalls = 0;
  lastRefreshScreenId = 0;
  legacyProcessKeyActionCalls = 0;
  legacyFnKeyEnterCalls = 0;
  legacyFnKeyExitCalls = 0;
  legacyFnKeyCCCalls = 0;
  legacyFnKeyBackspaceCalls = 0;
  legacyFnKeyUpCalls = 0;
  legacyFnKeyDotDCalls = 0;
  legacyFnKeyDownCalls = 0;
  keyboardFlags = 0;
  memset(kbd_std, 0, sizeof(kbd_std));
  memset(kbd_usr, 0, sizeof(kbd_usr));

  kbd_std[15].primaryAim = ITM_Q;
  kbd_std[15].gShiftedAim = ITM_DIGIT_1;
  kbd_usr[15] = kbd_std[15];

  kbd_std[31].primaryAim = ITM_Q;
  kbd_std[31].gShiftedAim = ITM_DIGIT_1;
  kbd_usr[31] = kbd_std[31];
}

void keyboardStateSetFlag(int32_t flag, bool_t enabled) {
  uint32_t mask = 1u << (uint32_t)flag;

  if(enabled) {
    keyboardFlags |= mask;
  }
  else {
    keyboardFlags &= ~mask;
  }
}

uint32_t keyboardStateFlags(void) {
  return keyboardFlags;
}

bool_t getSystemFlag(int32_t flag) {
  uint32_t mask = 1u << (uint32_t)flag;
  return (keyboardFlags & mask) != 0;
}

void clearSystemFlag(uint32_t flag) {
  uint32_t mask = 1u << flag;
  keyboardFlags &= ~mask;
}

void runFunction(int16_t item) {
  runFunctionCalls++;
  lastRunFunctionItem = item;
}

void addItemToNimBuffer(int16_t item) {
  nimBufferCalls++;
  lastNimBufferItem = item;
}

void refreshScreen(int16_t reason) {
  refreshScreenCalls++;
  lastRefreshScreenId = reason;
}

void z47_keyboard_state_runtime_standard_key(uint16_t index, calcKey_t *key) {
  *key = kbd_std[index];
}

void z47_keyboard_state_processKeyAction(int16_t item) {
  legacyProcessKeyActionCalls++;
  (void)item;
}

void z47_keyboard_state_fnKeyEnter(uint16_t unusedButMandatoryParameter) {
  legacyFnKeyEnterCalls++;
  (void)unusedButMandatoryParameter;
}

void z47_keyboard_state_fnKeyExit(uint16_t unusedButMandatoryParameter) {
  legacyFnKeyExitCalls++;
  (void)unusedButMandatoryParameter;
}

void z47_keyboard_state_fnKeyCC(uint16_t unusedButMandatoryParameter) {
  legacyFnKeyCCCalls++;
  (void)unusedButMandatoryParameter;
}

void z47_keyboard_state_fnKeyBackspace(uint16_t unusedButMandatoryParameter) {
  legacyFnKeyBackspaceCalls++;
  (void)unusedButMandatoryParameter;
}

void z47_keyboard_state_fnKeyUp(uint16_t unusedButMandatoryParameter) {
  legacyFnKeyUpCalls++;
  (void)unusedButMandatoryParameter;
}

void z47_keyboard_state_fnKeyDown(uint16_t unusedButMandatoryParameter) {
  legacyFnKeyDownCalls++;
  (void)unusedButMandatoryParameter;
}

void z47_keyboard_state_fnKeyDotD(uint16_t unusedButMandatoryParameter) {
  legacyFnKeyDotDCalls++;
  (void)unusedButMandatoryParameter;
}
