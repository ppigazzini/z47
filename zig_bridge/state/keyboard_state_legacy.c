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
#define fg_processing_jm z47_keyboard_state_fg_processing_jm
#define Check_Norm_Key_00_Assigned z47_keyboard_state_Check_Norm_Key_00_Assigned
#define Setup_MultiPresses z47_keyboard_state_Setup_MultiPresses
#define Check_MultiPresses z47_keyboard_state_Check_MultiPresses
#define nameFunction z47_keyboard_state_nameFunction
#define FN_cancel z47_keyboard_state_FN_cancel
#define btnFnPressed_StateMachine z47_keyboard_state_btnFnPressed_StateMachine
#define btnFnReleased_StateMachine z47_keyboard_state_btnFnReleased_StateMachine
#define shiftCutoff z47_keyboard_state_shiftCutoff
#define execFnTimeout z47_keyboard_state_execFnTimeout
#define openHOMEorMyM z47_keyboard_state_openHOMEorMyM
#define _keyClick z47_keyboard_state_keyClickImpl
#define keyClick z47_keyboard_state_keyClick
#define powerMarkerMsF z47_keyboard_state_powerMarkerMsF
// fnKeyDotD: switched to the Zig owner on ALL lanes (M1 leaf — the handler has
// no DMCP #ifdef divergence, so its rename is unconditional here too).
#define fnKeyDotD z47_keyboard_state_fnKeyDotD
// leavePem / checkKeyShifts: switched to the Zig owner on ALL lanes (M1 — both
// divergence-free, reaching only lane-independent helpers).
#define leavePem z47_keyboard_state_leavePem
#define checkKeyShifts z47_keyboard_state_checkKeyShifts
// M1 batch: divergence-free handlers switched to the Zig owner on ALL lanes.
#define processAimInput z47_keyboard_state_processAimInput
#define determineFunctionKeyItem_C47 z47_keyboard_state_determineFunctionKeyItem_C47
#define fnKeyEnter z47_keyboard_state_fnKeyEnter
#define fnKeyExit z47_keyboard_state_fnKeyExit
#define fnKeyBackspace z47_keyboard_state_fnKeyBackspace
#define fnKeyUp z47_keyboard_state_fnKeyUp
#define fnKeyDown z47_keyboard_state_fnKeyDown
#define fnKeyCC z47_keyboard_state_fnKeyCC
#define processKeyAction z47_keyboard_state_processKeyAction

#if defined(PC_BUILD)
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

#undef powerMarkerMsF
#undef keyClick
#undef _keyClick
#undef openHOMEorMyM
#undef btnFnReleased_StateMachine
#undef btnFnPressed_StateMachine
#undef FN_cancel
#undef nameFunction
#undef Check_MultiPresses
#undef Setup_MultiPresses
#undef Check_Norm_Key_00_Assigned
#undef fg_processing_jm
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
#undef fnKeyDotD
#undef leavePem
#undef checkKeyShifts
#undef processAimInput
#undef determineFunctionKeyItem_C47
#undef fnKeyEnter
#undef fnKeyExit
#undef fnKeyBackspace
#undef fnKeyUp
#undef fnKeyDown
#undef fnKeyCC
#undef processKeyAction
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
#endif
