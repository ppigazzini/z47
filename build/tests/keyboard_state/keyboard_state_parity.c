// SPDX-License-Identifier: GPL-3.0-only
//
// Scope: the pure key-translation helpers (caseReplacements / keyReplacements /
// numlockReplacements / setLastKeyCode), which have faithful hand-written C
// oracles here. The processKeyAction / fnKey* snapshot cases were removed: those
// handlers are now fully ported in keyboard_state_shared.zig and no longer match
// the simplified delegating oracle this harness carried (e.g. ITM_UP1_ITEM is no
// longer a special-cased item, and the "Retained" cases tested a legacy
// delegation the full port no longer performs). The real handler behaviour is
// covered end-to-end by the main testSuite (9530 cases); re-introducing handler
// parity here needs an oracle rewritten against the ported handlers.

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
  int legacyProcessKeyActionCalls;
  int legacyFnKeyEnterCalls;
  int legacyFnKeyExitCalls;
  int legacyFnKeyCCCalls;
  int legacyFnKeyBackspaceCalls;
  int legacyFnKeyUpCalls;
  int legacyFnKeyDownCalls;
  int legacyFnKeyDotDCalls;
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
  snapshot->legacyProcessKeyActionCalls = legacyProcessKeyActionCalls;
  snapshot->legacyFnKeyEnterCalls = legacyFnKeyEnterCalls;
  snapshot->legacyFnKeyExitCalls = legacyFnKeyExitCalls;
  snapshot->legacyFnKeyCCCalls = legacyFnKeyCCCalls;
  snapshot->legacyFnKeyBackspaceCalls = legacyFnKeyBackspaceCalls;
  snapshot->legacyFnKeyUpCalls = legacyFnKeyUpCalls;
  snapshot->legacyFnKeyDownCalls = legacyFnKeyDownCalls;
  snapshot->legacyFnKeyDotDCalls = legacyFnKeyDotDCalls;
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
  if(expected->legacyProcessKeyActionCalls != actual->legacyProcessKeyActionCalls) {
    fprintf(stderr, "%s legacyProcessKeyActionCalls mismatch: expected %d actual %d\n", label, expected->legacyProcessKeyActionCalls, actual->legacyProcessKeyActionCalls);
    return 1;
  }
  if(expected->legacyFnKeyEnterCalls != actual->legacyFnKeyEnterCalls) {
    fprintf(stderr, "%s legacyFnKeyEnterCalls mismatch: expected %d actual %d\n", label, expected->legacyFnKeyEnterCalls, actual->legacyFnKeyEnterCalls);
    return 1;
  }
  if(expected->legacyFnKeyExitCalls != actual->legacyFnKeyExitCalls) {
    fprintf(stderr, "%s legacyFnKeyExitCalls mismatch: expected %d actual %d\n", label, expected->legacyFnKeyExitCalls, actual->legacyFnKeyExitCalls);
    return 1;
  }
  if(expected->legacyFnKeyCCCalls != actual->legacyFnKeyCCCalls) {
    fprintf(stderr, "%s legacyFnKeyCCCalls mismatch: expected %d actual %d\n", label, expected->legacyFnKeyCCCalls, actual->legacyFnKeyCCCalls);
    return 1;
  }
  if(expected->legacyFnKeyBackspaceCalls != actual->legacyFnKeyBackspaceCalls) {
    fprintf(stderr, "%s legacyFnKeyBackspaceCalls mismatch: expected %d actual %d\n", label, expected->legacyFnKeyBackspaceCalls, actual->legacyFnKeyBackspaceCalls);
    return 1;
  }
  if(expected->legacyFnKeyUpCalls != actual->legacyFnKeyUpCalls) {
    fprintf(stderr, "%s legacyFnKeyUpCalls mismatch: expected %d actual %d\n", label, expected->legacyFnKeyUpCalls, actual->legacyFnKeyUpCalls);
    return 1;
  }
  if(expected->legacyFnKeyDownCalls != actual->legacyFnKeyDownCalls) {
    fprintf(stderr, "%s legacyFnKeyDownCalls mismatch: expected %d actual %d\n", label, expected->legacyFnKeyDownCalls, actual->legacyFnKeyDownCalls);
    return 1;
  }
  if(expected->legacyFnKeyDotDCalls != actual->legacyFnKeyDotDCalls) {
    fprintf(stderr, "%s legacyFnKeyDotDCalls mismatch: expected %d actual %d\n", label, expected->legacyFnKeyDotDCalls, actual->legacyFnKeyDotDCalls);
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












int main(void) {
  int failures = 0;

  failures += runCaseReplacementCase();
  failures += runNumlockReplacementCase();
  failures += runSetLastKeyCodeCase();

  if(failures != 0) {
    fprintf(stderr, "%d keyboard-state parity checks failed\n", failures);
    return 1;
  }

  puts("keyboard-state parity checks passed");
  return 0;
}
