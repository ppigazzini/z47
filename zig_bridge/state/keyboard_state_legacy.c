// SPDX-License-Identifier: GPL-3.0-only

#define setLastKeyCode z47_keyboard_state_setLastKeyCode
#define caseReplacements z47_keyboard_state_caseReplacements
#define keyReplacements z47_keyboard_state_keyReplacements
#define numlockReplacements z47_keyboard_state_numlockReplacements
#define fnSHIFTf z47_keyboard_state_fnSHIFTf
#define fnSHIFTg z47_keyboard_state_fnSHIFTg
#define fnSHIFTfg z47_keyboard_state_fnSHIFTfg
#define fnCla z47_keyboard_state_fnCla
#define fnCln z47_keyboard_state_fnCln
#define fnT_ARROW z47_keyboard_state_fnT_ARROW
#define refreshModeGui z47_keyboard_state_refreshModeGui
#define showAlphaModeonGui z47_keyboard_state_showAlphaModeonGui
#define showShiftState z47_keyboard_state_showShiftState
#define resetShiftState z47_keyboard_state_resetShiftState
#define resetKeytimers z47_keyboard_state_resetKeytimers
#define shiftCutoff z47_keyboard_state_shiftCutoff
#define execFnTimeout z47_keyboard_state_execFnTimeout
#define openHOMEorMyM z47_keyboard_state_openHOMEorMyM
#define _keyClick z47_keyboard_state_keyClickImpl
#define keyClick z47_keyboard_state_keyClick
#define powerMarkerMsF z47_keyboard_state_powerMarkerMsF

#if defined(PC_BUILD)
#define processKeyAction z47_keyboard_state_processKeyAction
#define processAimInput z47_keyboard_state_processAimInput
#define leavePem z47_keyboard_state_leavePem
#define checkKeyShifts z47_keyboard_state_checkKeyShifts
#define determineFunctionKeyItem_C47 z47_keyboard_state_determineFunctionKeyItem_C47
#define btnFnClicked z47_keyboard_state_btnFnClicked
#define btnReleased z47_keyboard_state_btnReleased
#define btnFnPressed z47_keyboard_state_btnFnPressed
#define btnFnReleased z47_keyboard_state_btnFnReleased
#define btnClickedP z47_keyboard_state_btnClickedP
#define btnClickedR z47_keyboard_state_btnClickedR
#define btnFnClickedP z47_keyboard_state_btnFnClickedP
#define btnFnClickedR z47_keyboard_state_btnFnClickedR
#define frmCalcMouseButtonPressed z47_keyboard_state_frmCalcMouseButtonPressed
#define frmCalcMouseButtonReleased z47_keyboard_state_frmCalcMouseButtonReleased
#define fnKeyEnter z47_keyboard_state_fnKeyEnter
#define fnKeyExit z47_keyboard_state_fnKeyExit
#define fnKeyCC z47_keyboard_state_fnKeyCC
#define fnKeyBackspace z47_keyboard_state_fnKeyBackspace
#define fnKeyUp z47_keyboard_state_fnKeyUp
#define fnKeyDown z47_keyboard_state_fnKeyDown
#define fnKeyDotD z47_keyboard_state_fnKeyDotD
#endif

#define btnPressed z47_keyboard_state_btnPressed
#define btnClicked z47_keyboard_state_btnClicked

#include "../../src/c47/keyboard.c"

#undef btnClicked
#undef btnPressed

#if defined(PC_BUILD)
extern void btnClicked(GtkWidget *notUsed, gpointer data);
#endif

#if defined(DMCP_BUILD)
extern void btnClicked(void *unused, void *data);
#endif

#include "../../src/c47/c47Extensions/keyboardTweak.c"

// _assignToMenu is static inside keyboard.c, so the Zig fnKeyBackspace/Up/Down
// owners cannot link it directly.  Expose a thin external trampoline from inside
// this translation unit (where the static is in scope).
bool_t z47_keyboard_state_assignToMenu(uint8_t *data) {
  return _assignToMenu(data);
}

#undef powerMarkerMsF
#undef keyClick
#undef _keyClick
#undef openHOMEorMyM
#undef execFnTimeout
#undef shiftCutoff
#undef resetKeytimers
#undef resetShiftState
#undef showShiftState
#undef showAlphaModeonGui
#undef refreshModeGui
#undef fnT_ARROW
#undef fnCln
#undef fnCla
#undef fnSHIFTfg
#undef fnSHIFTg
#undef fnSHIFTf
#undef numlockReplacements
#undef keyReplacements
#undef caseReplacements
#undef setLastKeyCode
#if defined(PC_BUILD)
#undef frmCalcMouseButtonReleased
#undef frmCalcMouseButtonPressed
#undef btnFnClickedR
#undef btnFnClickedP
#undef btnClickedR
#undef btnClickedP
#undef btnFnReleased
#undef btnFnPressed
#undef btnReleased
#undef btnFnClicked
#undef determineFunctionKeyItem_C47
#undef checkKeyShifts
#undef leavePem
#undef processAimInput
#undef fnKeyDotD
#undef fnKeyDown
#undef fnKeyUp
#undef fnKeyBackspace
#undef fnKeyCC
#undef fnKeyExit
#undef fnKeyEnter
#undef processKeyAction
#endif