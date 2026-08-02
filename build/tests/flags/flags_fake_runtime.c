// SPDX-License-Identifier: GPL-3.0-only
//
// The environment both sides of the system-flags parity lane run in.
//
// There is exactly one copy of every global and every out-call here, shared by
// c43's flags.c (compiled as the oracle) and by the Zig owner. That is what makes
// the comparison mean something: the two implementations are indistinguishable to
// everything around them, so a snapshot difference can only come from the flag
// logic itself.
//
// The out-calls COUNT rather than act. `calcModeAim` really does enter alpha mode
// in the calculator; here it increments, because the lane is asking whether both
// implementations decide to call it under the same conditions, not what it does.

#include <string.h>

#include "flags_test_runtime.h"

uint64_t systemFlags0 = 0;
uint64_t systemFlags1 = 0;
uint32_t lastIntegerBase = 0;
uint8_t screenUpdatingMode = SCRUPD_AUTO;
uint16_t globalFlags[8] = {0};
localFlags_t *currentLocalFlags = NULL;
uint8_t temporaryInformation = 0;
uint8_t programRunStop = PGM_STOPPED;
uint8_t alphaCase = AC_UPPER;
uint8_t scrLock = NC_NORMAL;
uint8_t nextChar = NC_NORMAL;
uint8_t calcMode = CM_NORMAL;

// Two softmenus so a case can put either one on top of the stack: only id 1 is
// the equation editor, so `_clearAlpha`'s inner `== -MNU_EQ_EDIT` test is a real
// test and not a foregone conclusion.
static const int16_t harnessSoftkeyItems[1] = {0};

const softmenu_t softmenu[] = {
  {.menuItem = 0, .numItems = 0, .softkeyItem = harnessSoftkeyItems},
  {.menuItem = -MNU_EQ_EDIT, .numItems = 0, .softkeyItem = harnessSoftkeyItems},
};

softmenuStack_t softmenuStack[SOFTMENU_STACK_SIZE] = {{0}};

static formulaHeader_t formulaStorage[1] = {{0}};
formulaHeader_t *allFormulae = formulaStorage;
uint16_t currentFormula = 0;

static char tmpStringStorage[256];
static char errorMessageStorage[256];
char *tmpString = tmpStringStorage;
char *errorMessage = errorMessageStorage;

// Deliberately empty format strings: the bug-screen messages are only ever fed
// to sprintf, and an empty format consumes no arguments and cannot mismatch the
// varargs upstream passes. Their TEXT is not what this lane is checking.
const char commonBugScreenMessages[NUMBER_OF_BUG_SCREEN_MESSAGES][SIZE_OF_EACH_BUG_SCREEN_MESSAGE] = {{0}};

static localFlags_t localFlagsStorage = 0;

static uint32_t refreshStateCalls = 0;
static uint32_t clearStatusBarCalls = 0;
static uint32_t changeBaseCalls = 0;
static uint32_t showAlphaModeCalls = 0;
static uint32_t writeProtectedErrorCalls = 0;
static uint32_t enterAlphaCalls = 0;
static uint32_t leaveAlphaCalls = 0;
static uint32_t leaveTamCalls = 0;
static uint32_t clFAllConfirmationCalls = 0;
static uint32_t popSoftmenuCalls = 0;
static uint32_t deleteEquationCalls = 0;
static uint8_t lastClearStatusBarInfo = 0;
static uint16_t lastChangeBaseArg = 0;

void fnRefreshState(void) {
  refreshStateCalls++;
}

void reallyClearStatusBar(uint8_t info) {
  clearStatusBarCalls++;
  lastClearStatusBarInfo = info;
}

void fnChangeBaseJM(uint16_t base) {
  changeBaseCalls++;
  lastChangeBaseArg = base;
  lastIntegerBase = base;
}

void showAlphaModeonGui(void) {
  showAlphaModeCalls++;
}

void leaveTamModeIfEnabled(void) {
  leaveTamCalls++;
}

void calcModeAim(uint16_t unusedButMandatoryParameter) {
  (void)unusedButMandatoryParameter;
  enterAlphaCalls++;
}

void calcModeNormal(void) {
  leaveAlphaCalls++;
}

void popSoftmenu(void) {
  popSoftmenuCalls++;
}

void deleteEquation(uint16_t equation) {
  (void)equation;
  deleteEquationCalls++;
}

void setConfirmationMode(void (*func)(uint16_t)) {
  (void)func;
  clFAllConfirmationCalls++;
}

void displayCalcErrorMessage(uint8_t errorCode, calcRegister_t errMessageRegisterLine, calcRegister_t disUsedCanBeRemoved) {
  (void)errorCode;
  (void)errMessageRegisterLine;
  (void)disUsedCanBeRemoved;
  writeProtectedErrorCalls++;
}

void displayBugScreen(const char *msg) {
  (void)msg;
}

void moreInfoOnError(const char *m1, const char *m2, const char *m3, const char *m4) {
  (void)m1;
  (void)m2;
  (void)m3;
  (void)m4;
}

void flagsParitySeed(uint64_t system_flags0,
                     uint64_t system_flags1,
                     uint64_t system_flags0_changed,
                     uint64_t system_flags1_changed,
                     uint64_t system_flags2_changed,
                     uint32_t last_integer_base,
                     uint8_t screen_updating_mode) {
  systemFlags0 = system_flags0;
  systemFlags1 = system_flags1;
  systemFlags0Changed = system_flags0_changed;
  systemFlags1Changed = system_flags1_changed;
  systemFlags2Changed = system_flags2_changed;
  oracle_systemFlags0Changed = system_flags0_changed;
  oracle_systemFlags1Changed = system_flags1_changed;
  oracle_systemFlags2Changed = system_flags2_changed;
  lastIntegerBase = last_integer_base;
  screenUpdatingMode = screen_updating_mode;
  memset(globalFlags, 0, sizeof(globalFlags));
  currentLocalFlags = NULL;
  localFlagsStorage = 0;
  temporaryInformation = 0;
  programRunStop = PGM_STOPPED;
  alphaCase = AC_UPPER;
  scrLock = NC_NORMAL;
  nextChar = NC_NORMAL;
  calcMode = CM_NORMAL;
  softmenuStack[0].softmenuId = 0;
  currentFormula = 0;
  formulaStorage[0].pointerToFormulaData = 0;
  refreshStateCalls = 0;
  clearStatusBarCalls = 0;
  changeBaseCalls = 0;
  showAlphaModeCalls = 0;
  writeProtectedErrorCalls = 0;
  enterAlphaCalls = 0;
  leaveAlphaCalls = 0;
  leaveTamCalls = 0;
  clFAllConfirmationCalls = 0;
  popSoftmenuCalls = 0;
  deleteEquationCalls = 0;
  lastClearStatusBarInfo = 0;
  lastChangeBaseArg = 0;
}

void flagsParitySeedCommandState(const uint16_t global_flags[8],
                                 bool_t has_local_flags,
                                 uint32_t local_flags,
                                 uint8_t temporary_information,
                                 uint8_t program_run_stop) {
  memcpy(globalFlags, global_flags, sizeof(globalFlags));
  localFlagsStorage = local_flags;
  currentLocalFlags = has_local_flags ? &localFlagsStorage : NULL;
  temporaryInformation = temporary_information;
  programRunStop = program_run_stop;
}

void flagsParitySeedTextState(uint8_t alpha_case,
                              uint8_t scr_lock,
                              uint8_t next_char) {
  alphaCase = alpha_case;
  scrLock = scr_lock;
  nextChar = next_char;
}

void flagsParitySeedEquationState(uint8_t calc_mode,
                                  int16_t top_softmenu_id,
                                  uint16_t formula_data_pointer) {
  calcMode = calc_mode;
  softmenuStack[0].softmenuId = top_softmenu_id;
  currentFormula = 0;
  formulaStorage[0].pointerToFormulaData = formula_data_pointer;
}

static void capture(flags_parity_snapshot_t *snapshot,
                    uint64_t changed0,
                    uint64_t changed1,
                    uint64_t changed2) {
  memset(snapshot, 0, sizeof(*snapshot));
  snapshot->system_flags0 = systemFlags0;
  snapshot->system_flags1 = systemFlags1;
  snapshot->system_flags0_changed = changed0;
  snapshot->system_flags1_changed = changed1;
  snapshot->system_flags2_changed = changed2;
  snapshot->last_integer_base = lastIntegerBase;
  snapshot->screen_updating_mode = screenUpdatingMode;
  memcpy(snapshot->global_flags, globalFlags, sizeof(snapshot->global_flags));
  snapshot->has_local_flags = currentLocalFlags != NULL;
  snapshot->local_flags = currentLocalFlags == NULL ? 0 : *currentLocalFlags;
  snapshot->temporary_information = temporaryInformation;
  snapshot->program_run_stop = programRunStop;
  snapshot->alpha_case = alphaCase;
  snapshot->scr_lock = scrLock;
  snapshot->next_char = nextChar;
  snapshot->calc_mode = calcMode;
  snapshot->current_formula = currentFormula;
  snapshot->formula_data_pointer = formulaStorage[0].pointerToFormulaData;
  snapshot->refresh_state_calls = refreshStateCalls;
  snapshot->clear_status_bar_calls = clearStatusBarCalls;
  snapshot->change_base_calls = changeBaseCalls;
  snapshot->write_protected_error_calls = writeProtectedErrorCalls;
  snapshot->enter_alpha_calls = enterAlphaCalls;
  snapshot->leave_alpha_calls = leaveAlphaCalls;
  snapshot->leave_tam_calls = leaveTamCalls;
  snapshot->clf_all_confirmation_calls = clFAllConfirmationCalls;
  snapshot->show_alpha_mode_calls = showAlphaModeCalls;
  snapshot->pop_softmenu_calls = popSoftmenuCalls;
  snapshot->delete_equation_calls = deleteEquationCalls;
  snapshot->last_clear_status_bar_info = lastClearStatusBarInfo;
  snapshot->last_change_base_arg = lastChangeBaseArg;
}

void flagsParityCaptureLive(flags_parity_snapshot_t *snapshot) {
  capture(snapshot, systemFlags0Changed, systemFlags1Changed, systemFlags2Changed);
}

void flagsParityCaptureOracle(flags_parity_snapshot_t *snapshot) {
  capture(snapshot, oracle_systemFlags0Changed, oracle_systemFlags1Changed, oracle_systemFlags2Changed);
}
