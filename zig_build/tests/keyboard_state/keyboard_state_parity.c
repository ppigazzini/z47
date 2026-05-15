// SPDX-License-Identifier: GPL-3.0-only

#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "c47.h"

typedef struct {
  uint8_t currentFlgScr;
  uint8_t lastErrorCode;
  uint8_t temporaryInformation;
  uint8_t programRunStop;
  uint8_t screenUpdatingMode;
  bool_t keyActionProcessed;
  int16_t ListXYposition;
  int16_t lastKeyCode;
  uint32_t flags;
  int runFunctionCalls;
  int16_t lastRunFunctionItem;
  int nimBufferCalls;
  int16_t lastNimBufferItem;
  int refreshScreenCalls;
  int16_t lastRefreshScreenId;
  int retainedProcessKeyActionCalls;
  int retainedFnKeyEnterCalls;
  int retainedFnKeyExitCalls;
  int retainedFnKeyCCCalls;
  int retainedFnKeyBackspaceCalls;
  int retainedFnKeyUpCalls;
  int retainedFnKeyDownCalls;
  int retainedFnKeyDotDCalls;
} keyboard_state_snapshot_t;

static void captureSnapshot(keyboard_state_snapshot_t *snapshot) {
  memset(snapshot, 0, sizeof(*snapshot));
  snapshot->currentFlgScr = currentFlgScr;
  snapshot->lastErrorCode = lastErrorCode;
  snapshot->temporaryInformation = temporaryInformation;
  snapshot->programRunStop = programRunStop;
  snapshot->screenUpdatingMode = screenUpdatingMode;
  snapshot->keyActionProcessed = keyActionProcessed;
  snapshot->ListXYposition = ListXYposition;
  snapshot->lastKeyCode = lastKeyCode;
  snapshot->flags = keyboardStateFlags();
  snapshot->runFunctionCalls = runFunctionCalls;
  snapshot->lastRunFunctionItem = lastRunFunctionItem;
  snapshot->nimBufferCalls = nimBufferCalls;
  snapshot->lastNimBufferItem = lastNimBufferItem;
  snapshot->refreshScreenCalls = refreshScreenCalls;
  snapshot->lastRefreshScreenId = lastRefreshScreenId;
  snapshot->retainedProcessKeyActionCalls = retainedProcessKeyActionCalls;
  snapshot->retainedFnKeyEnterCalls = retainedFnKeyEnterCalls;
  snapshot->retainedFnKeyExitCalls = retainedFnKeyExitCalls;
  snapshot->retainedFnKeyCCCalls = retainedFnKeyCCCalls;
  snapshot->retainedFnKeyBackspaceCalls = retainedFnKeyBackspaceCalls;
  snapshot->retainedFnKeyUpCalls = retainedFnKeyUpCalls;
  snapshot->retainedFnKeyDownCalls = retainedFnKeyDownCalls;
  snapshot->retainedFnKeyDotDCalls = retainedFnKeyDotDCalls;
}

static int reportSnapshotMismatch(const char *label, const keyboard_state_snapshot_t *expected, const keyboard_state_snapshot_t *actual) {
  if(expected->currentFlgScr != actual->currentFlgScr) {
    fprintf(stderr, "%s currentFlgScr mismatch: expected %u actual %u\n", label, expected->currentFlgScr, actual->currentFlgScr);
    return 1;
  }
  if(expected->lastErrorCode != actual->lastErrorCode) {
    fprintf(stderr, "%s lastErrorCode mismatch: expected %u actual %u\n", label, expected->lastErrorCode, actual->lastErrorCode);
    return 1;
  }
  if(expected->temporaryInformation != actual->temporaryInformation) {
    fprintf(stderr, "%s temporaryInformation mismatch: expected %u actual %u\n", label, expected->temporaryInformation, actual->temporaryInformation);
    return 1;
  }
  if(expected->programRunStop != actual->programRunStop) {
    fprintf(stderr, "%s programRunStop mismatch: expected %u actual %u\n", label, expected->programRunStop, actual->programRunStop);
    return 1;
  }
  if(expected->screenUpdatingMode != actual->screenUpdatingMode) {
    fprintf(stderr, "%s screenUpdatingMode mismatch: expected %u actual %u\n", label, expected->screenUpdatingMode, actual->screenUpdatingMode);
    return 1;
  }
  if(expected->keyActionProcessed != actual->keyActionProcessed) {
    fprintf(stderr, "%s keyActionProcessed mismatch: expected %u actual %u\n", label, expected->keyActionProcessed, actual->keyActionProcessed);
    return 1;
  }
  if(expected->ListXYposition != actual->ListXYposition) {
    fprintf(stderr, "%s ListXYposition mismatch: expected %d actual %d\n", label, expected->ListXYposition, actual->ListXYposition);
    return 1;
  }
  if(expected->lastKeyCode != actual->lastKeyCode) {
    fprintf(stderr, "%s lastKeyCode mismatch: expected %d actual %d\n", label, expected->lastKeyCode, actual->lastKeyCode);
    return 1;
  }
  if(expected->flags != actual->flags) {
    fprintf(stderr, "%s flag-mask mismatch: expected %u actual %u\n", label, expected->flags, actual->flags);
    return 1;
  }
  if(expected->runFunctionCalls != actual->runFunctionCalls) {
    fprintf(stderr, "%s runFunctionCalls mismatch: expected %d actual %d\n", label, expected->runFunctionCalls, actual->runFunctionCalls);
    return 1;
  }
  if(expected->lastRunFunctionItem != actual->lastRunFunctionItem) {
    fprintf(stderr, "%s lastRunFunctionItem mismatch: expected %d actual %d\n", label, expected->lastRunFunctionItem, actual->lastRunFunctionItem);
    return 1;
  }
  if(expected->nimBufferCalls != actual->nimBufferCalls) {
    fprintf(stderr, "%s nimBufferCalls mismatch: expected %d actual %d\n", label, expected->nimBufferCalls, actual->nimBufferCalls);
    return 1;
  }
  if(expected->lastNimBufferItem != actual->lastNimBufferItem) {
    fprintf(stderr, "%s lastNimBufferItem mismatch: expected %d actual %d\n", label, expected->lastNimBufferItem, actual->lastNimBufferItem);
    return 1;
  }
  if(expected->refreshScreenCalls != actual->refreshScreenCalls) {
    fprintf(stderr, "%s refreshScreenCalls mismatch: expected %d actual %d\n", label, expected->refreshScreenCalls, actual->refreshScreenCalls);
    return 1;
  }
  if(expected->lastRefreshScreenId != actual->lastRefreshScreenId) {
    fprintf(stderr, "%s lastRefreshScreenId mismatch: expected %d actual %d\n", label, expected->lastRefreshScreenId, actual->lastRefreshScreenId);
    return 1;
  }
  if(expected->retainedProcessKeyActionCalls != actual->retainedProcessKeyActionCalls) {
    fprintf(stderr, "%s retainedProcessKeyActionCalls mismatch: expected %d actual %d\n", label, expected->retainedProcessKeyActionCalls, actual->retainedProcessKeyActionCalls);
    return 1;
  }
  if(expected->retainedFnKeyEnterCalls != actual->retainedFnKeyEnterCalls) {
    fprintf(stderr, "%s retainedFnKeyEnterCalls mismatch: expected %d actual %d\n", label, expected->retainedFnKeyEnterCalls, actual->retainedFnKeyEnterCalls);
    return 1;
  }
  if(expected->retainedFnKeyExitCalls != actual->retainedFnKeyExitCalls) {
    fprintf(stderr, "%s retainedFnKeyExitCalls mismatch: expected %d actual %d\n", label, expected->retainedFnKeyExitCalls, actual->retainedFnKeyExitCalls);
    return 1;
  }
  if(expected->retainedFnKeyCCCalls != actual->retainedFnKeyCCCalls) {
    fprintf(stderr, "%s retainedFnKeyCCCalls mismatch: expected %d actual %d\n", label, expected->retainedFnKeyCCCalls, actual->retainedFnKeyCCCalls);
    return 1;
  }
  if(expected->retainedFnKeyBackspaceCalls != actual->retainedFnKeyBackspaceCalls) {
    fprintf(stderr, "%s retainedFnKeyBackspaceCalls mismatch: expected %d actual %d\n", label, expected->retainedFnKeyBackspaceCalls, actual->retainedFnKeyBackspaceCalls);
    return 1;
  }
  if(expected->retainedFnKeyUpCalls != actual->retainedFnKeyUpCalls) {
    fprintf(stderr, "%s retainedFnKeyUpCalls mismatch: expected %d actual %d\n", label, expected->retainedFnKeyUpCalls, actual->retainedFnKeyUpCalls);
    return 1;
  }
  if(expected->retainedFnKeyDownCalls != actual->retainedFnKeyDownCalls) {
    fprintf(stderr, "%s retainedFnKeyDownCalls mismatch: expected %d actual %d\n", label, expected->retainedFnKeyDownCalls, actual->retainedFnKeyDownCalls);
    return 1;
  }
  if(expected->retainedFnKeyDotDCalls != actual->retainedFnKeyDotDCalls) {
    fprintf(stderr, "%s retainedFnKeyDotDCalls mismatch: expected %d actual %d\n", label, expected->retainedFnKeyDotDCalls, actual->retainedFnKeyDotDCalls);
    return 1;
  }

  return 0;
}

static int runCaseReplacementCase(void) {
  int16_t expected = 0;
  int16_t actual = 0;

  keyboardStateReset();
  if(!oracle_caseReplacements(0, true, ITM_A, &expected)) {
    fprintf(stderr, "oracle caseReplacements did not translate uppercase input\n");
    return 1;
  }

  keyboardStateReset();
  if(!caseReplacements(0, true, ITM_A, &actual)) {
    fprintf(stderr, "zig caseReplacements did not translate uppercase input\n");
    return 1;
  }

  if(expected != actual) {
    fprintf(stderr, "caseReplacements mismatch: expected %d actual %d\n", expected, actual);
    return 1;
  }

  return 0;
}

static int runNumlockReplacementCase(void) {
  uint16_t expected;
  uint16_t actual;

  keyboardStateReset();
  keyboardStateSetFlag(FLAG_NUMLOCK, true);
  expected = oracle_numlockReplacements(0, ITM_Q, true, false, false);

  keyboardStateReset();
  keyboardStateSetFlag(FLAG_NUMLOCK, true);
  actual = numlockReplacements(0, ITM_Q, true, false, false);

  if(expected != actual) {
    fprintf(stderr, "numlockReplacements mismatch: expected %u actual %u\n", expected, actual);
    return 1;
  }

  return 0;
}

static int runSetLastKeyCodeCase(void) {
  int16_t expected;
  int16_t actual;

  keyboardStateReset();
  oracle_setLastKeyCode(43);
  expected = lastKeyCode;
 
  keyboardStateReset();
  setLastKeyCode(43);
  actual = lastKeyCode;

  if(expected != actual) {
    fprintf(stderr, "setLastKeyCode mismatch: expected %d actual %d\n", expected, actual);
    return 1;
  }

  return 0;
}

static int runProcessKeyActionFlagBrowserCase(void) {
  keyboard_state_snapshot_t expected;
  keyboard_state_snapshot_t actual;

  keyboardStateReset();
  calcMode = CM_FLAG_BROWSER;
  currentFlgScr = 7;
  screenUpdatingMode = (uint8_t)(SCRUPD_MANUAL_MENU | SCRUPD_MANUAL_STACK | 0x80);
  oracle_processKeyAction(ITM_UP1_ITEM);
  captureSnapshot(&expected);

  keyboardStateReset();
  calcMode = CM_FLAG_BROWSER;
  currentFlgScr = 7;
  screenUpdatingMode = (uint8_t)(SCRUPD_MANUAL_MENU | SCRUPD_MANUAL_STACK | 0x80);
  processKeyAction(ITM_UP1_ITEM);
  captureSnapshot(&actual);

  return reportSnapshotMismatch("processKeyAction flag-browser up", &expected, &actual);
}

static int runProcessKeyActionRetainedCase(void) {
  keyboard_state_snapshot_t expected;
  keyboard_state_snapshot_t actual;

  keyboardStateReset();
  calcMode = CM_NORMAL;
  oracle_processKeyAction(ITM_ENTER);
  captureSnapshot(&expected);

  keyboardStateReset();
  calcMode = CM_NORMAL;
  processKeyAction(ITM_ENTER);
  captureSnapshot(&actual);

  return reportSnapshotMismatch("processKeyAction retained fallback", &expected, &actual);
}

static int runFnKeyEnterRetainedCase(void) {
  keyboard_state_snapshot_t expected;
  keyboard_state_snapshot_t actual;

  keyboardStateReset();
  oracle_fnKeyEnter(0);
  captureSnapshot(&expected);

  keyboardStateReset();
  fnKeyEnter(0);
  captureSnapshot(&actual);

  return reportSnapshotMismatch("fnKeyEnter retained fallback", &expected, &actual);
}

static int runFnKeyExitRetainedCase(void) {
  keyboard_state_snapshot_t expected;
  keyboard_state_snapshot_t actual;

  keyboardStateReset();
  oracle_fnKeyExit(0);
  captureSnapshot(&expected);

  keyboardStateReset();
  fnKeyExit(0);
  captureSnapshot(&actual);

  return reportSnapshotMismatch("fnKeyExit retained fallback", &expected, &actual);
}

static int runFnKeyCCNimCase(void) {
  keyboard_state_snapshot_t expected;
  keyboard_state_snapshot_t actual;

  keyboardStateReset();
  calcMode = CM_NIM;
  oracle_fnKeyCC(0);
  captureSnapshot(&expected);

  keyboardStateReset();
  calcMode = CM_NIM;
  fnKeyCC(0);
  captureSnapshot(&actual);

  return reportSnapshotMismatch("fnKeyCC NIM", &expected, &actual);
}

static int runFnKeyCCRetainedCase(void) {
  keyboard_state_snapshot_t expected;
  keyboard_state_snapshot_t actual;

  keyboardStateReset();
  calcMode = CM_NORMAL;
  oracle_fnKeyCC(KEY_COMPLEX);
  captureSnapshot(&expected);

  keyboardStateReset();
  calcMode = CM_NORMAL;
  fnKeyCC(KEY_COMPLEX);
  captureSnapshot(&actual);

  return reportSnapshotMismatch("fnKeyCC retained fallback", &expected, &actual);
}

static int runFnKeyBackspaceNimCase(void) {
  keyboard_state_snapshot_t expected;
  keyboard_state_snapshot_t actual;

  keyboardStateReset();
  calcMode = CM_NIM;
  screenUpdatingMode = (uint8_t)(SCRUPD_MANUAL_STACK | SCRUPD_SKIP_STACK_ONE_TIME | 0x80);
  oracle_fnKeyBackspace(0);
  captureSnapshot(&expected);

  keyboardStateReset();
  calcMode = CM_NIM;
  screenUpdatingMode = (uint8_t)(SCRUPD_MANUAL_STACK | SCRUPD_SKIP_STACK_ONE_TIME | 0x80);
  fnKeyBackspace(0);
  captureSnapshot(&actual);

  return reportSnapshotMismatch("fnKeyBackspace NIM", &expected, &actual);
}

static int runFnKeyUpListXYCase(void) {
  keyboard_state_snapshot_t expected;
  keyboard_state_snapshot_t actual;

  keyboardStateReset();
  calcMode = CM_LISTXY;
  ListXYposition = 20;
  oracle_fnKeyUp(0);
  captureSnapshot(&expected);

  keyboardStateReset();
  calcMode = CM_LISTXY;
  ListXYposition = 20;
  fnKeyUp(0);
  captureSnapshot(&actual);

  return reportSnapshotMismatch("fnKeyUp LISTXY", &expected, &actual);
}

static int runFnKeyDownListXYCase(void) {
  keyboard_state_snapshot_t expected;
  keyboard_state_snapshot_t actual;

  keyboardStateReset();
  calcMode = CM_LISTXY;
  ListXYposition = 20;
  oracle_fnKeyDown(0);
  captureSnapshot(&expected);

  keyboardStateReset();
  calcMode = CM_LISTXY;
  ListXYposition = 20;
  fnKeyDown(0);
  captureSnapshot(&actual);

  return reportSnapshotMismatch("fnKeyDown LISTXY", &expected, &actual);
}

static int runFnKeyDotDClearFractionCase(void) {
  keyboard_state_snapshot_t expected;
  keyboard_state_snapshot_t actual;

  keyboardStateReset();
  calcMode = CM_NORMAL;
  keyboardStateSetFlag(FLAG_FRACT, true);
  oracle_fnKeyDotD(0);
  captureSnapshot(&expected);

  keyboardStateReset();
  calcMode = CM_NORMAL;
  keyboardStateSetFlag(FLAG_FRACT, true);
  fnKeyDotD(0);
  captureSnapshot(&actual);

  return reportSnapshotMismatch("fnKeyDotD clear fraction", &expected, &actual);
}

static int runFnKeyDotDRunFunctionCase(void) {
  keyboard_state_snapshot_t expected;
  keyboard_state_snapshot_t actual;

  keyboardStateReset();
  calcMode = CM_NORMAL;
  oracle_fnKeyDotD(0);
  captureSnapshot(&expected);

  keyboardStateReset();
  calcMode = CM_NORMAL;
  fnKeyDotD(0);
  captureSnapshot(&actual);

  return reportSnapshotMismatch("fnKeyDotD runFunction", &expected, &actual);
}

int main(void) {
  int failures = 0;

  failures += runCaseReplacementCase();
  failures += runNumlockReplacementCase();
  failures += runSetLastKeyCodeCase();
  failures += runProcessKeyActionFlagBrowserCase();
  failures += runProcessKeyActionRetainedCase();
  failures += runFnKeyEnterRetainedCase();
  failures += runFnKeyExitRetainedCase();
  failures += runFnKeyCCNimCase();
  failures += runFnKeyCCRetainedCase();
  failures += runFnKeyBackspaceNimCase();
  failures += runFnKeyUpListXYCase();
  failures += runFnKeyDownListXYCase();
  failures += runFnKeyDotDClearFractionCase();
  failures += runFnKeyDotDRunFunctionCase();

  if(failures != 0) {
    fprintf(stderr, "%d keyboard-state parity checks failed\n", failures);
    return 1;
  }

  puts("keyboard-state parity checks passed");
  return 0;
}