// SPDX-License-Identifier: GPL-3.0-only

// This bridge provides only the save/restore/load entrypoints; the rest of
// saveRestoreCalcState.c (helpers, accessors, save-sections) is Zig-owned, so
// those names are namespaced here to avoid duplicate-symbol collisions.
#define doSave z47_calc_state_legacy_doSave
#define doLoad z47_calc_state_legacy_doLoad
#define fnSave z47_calc_state_legacy_fnSave
#define fnLoad z47_calc_state_legacy_fnLoad
#define fnSaveAuto z47_calc_state_legacy_fnSaveAuto
#define fnLoadAuto z47_calc_state_legacy_fnLoadAuto
#define saveCalc z47_calc_state_legacy_saveCalc
#define restoreCalc z47_calc_state_legacy_restoreCalc

#define readLine z47_calc_state_legacy_readLine
#define toInt32 z47_calc_state_legacy_toInt32
#define stringToInt16 z47_calc_state_legacy_stringToInt16
#define stringToInt32 z47_calc_state_legacy_stringToInt32
#define stringToUint8 z47_calc_state_legacy_stringToUint8
#define stringToUint32 z47_calc_state_legacy_stringToUint32
#define fnLoadedFile z47_calc_state_legacy_fnLoadedFile
#define fnDeleteBackup z47_calc_state_legacy_fnDeleteBackup

#include "../../src/c47/saveRestoreCalcState.c"

#undef doSave
#undef doLoad
#undef fnSave
#undef fnLoad
#undef fnSaveAuto
#undef fnLoadAuto
#undef saveCalc
#undef restoreCalc
#undef readLine
#undef toInt32
#undef stringToInt16
#undef stringToInt32
#undef stringToUint8
#undef stringToUint32
#undef fnLoadedFile
#undef fnDeleteBackup


// power_check_screen is a DMCP library function-table macro (lft_ifc.h), not a
// linkable symbol, so a Zig extern cannot resolve it on firmware. Wrap it in C
// where the macro is in scope; the host build has no power button and returns 0.
bool_t z47_state_power_check_screen(void) {
#if defined(DMCP_BUILD)
	return power_check_screen();
#else
	return false;
#endif
}

// sys_timer_disable / sys_timer_start are DMCP ROM function-table macros
// (lft_ifc.h), not linkable symbols, so the Zig io_owned timer restart wraps
// them here where the macro is in scope. No-ops on host (no DMCP timers).
void z47_state_sys_timer_disable(int timer_ix) {
#if defined(DMCP_BUILD)
	sys_timer_disable(timer_ix);
#else
	(void)timer_ix;
#endif
}
void z47_state_sys_timer_start(int timer_ix, uint32_t ms_value) {
#if defined(DMCP_BUILD)
	sys_timer_start(timer_ix, ms_value);
#else
	(void)timer_ix; (void)ms_value;
#endif
}

// --- c47.sav text-path residual trampolines (ALL lanes) ---
// These back the Zig section writer / parser / register codec, which run on
// every lane (host / DMCP5 / DMCP). They wrap the remaining file-static / macro
// / enum surface the Zig owners can't reach directly, so they must be available
// on the firmware lanes too.

// Matrix vector-tag predicates (macros over the matrix subsystem) used by the
// Zig register codec's matrix arms.
bool_t  z47_css_isRegisterMatrixVector(int16_t regist)      { return isRegisterMatrixVector(regist); }
uint8_t z47_css_getVectorRegisterAngularMode(int16_t regist){ return getVectorRegisterAngularMode(regist); }
uint8_t z47_css_getVectorRegisterPolarMode(int16_t regist)  { return getVectorRegisterPolarMode(regist); }

void z47_css_printerState(uint8_t *print_on, uint8_t *printer_model, uint16_t *delay) {
	*print_on      = printerState.print_on;
	*printer_model = printerState.printer_model;
	*delay         = printerState.delay;
}

// Post-keyboard-section migration fixup (doSave line ~1867): faithful to the C
// path. loadedVersion is static; the call has no effect on the saved bytes
// (KEYBOARD_ASSIGNMENTS is already written) but is preserved for product
// parity.
void z47_css_postKeyboardFixup(void) {
	if(loadedVersion < 10000023) {
		setLongPressFg(calcModel, -MNU_HOME);
	}
}

// --- Load-parsing leaf helpers (z47_calc_state_restore_one_section owner) ---
// The parse primitives (toInt16/toUint8/toUint16/toUint32/next_word/skip_*/
// toInt16_next_word/strcmp2) and the register/matrix restorers
// (restoreRegister/restoreMatrixData/skipMatrixData) are file-static; the Zig
// restoreOneSection owner reaches them through these same-TU trampolines. The
// remaining wrappers cover macros (stringToReal, Norm_Key_00_key, kbd_std) and a
// static-inline (isAtEndOfProgram) so that surface stays out of Zig. The Zig
// port keeps the C statics loadedVersion/savedCalcModel in sync via the setter.
void z47_css_updateConstantsInEquations(void) { _updateConstantsInEquations(); }

bool_t z47_css_isAtEndOfProgram(const uint8_t *step) { return isAtEndOfProgram(step); }
int16_t z47_css_normKey00Key(void) { return Norm_Key_00_key; }
int16_t z47_css_kbdStdPrimary(int16_t idx) { return kbd_std[idx].primary; }

void z47_css_set_loaded_version(uint32_t v) { loadedVersion = v; }

void z47_css_setPrinterOn(uint8_t v)    { printerState.print_on = v; }
void z47_css_setPrinterModel(uint8_t v) { printerState.printer_model = v; }
void z47_css_setPrinterDelay(uint16_t v){ printerState.delay = v; }

// --- backup.cfg trampolines (HOST only) ---
// The backup owner (saveCalc/restoreCalc) stays on the C retained path on the
// firmware lanes (OLD_HW has a different memory model), so these are host-only
// and dead-stripped elsewhere.
#if !defined(DMCP_BUILD)

// backup.cfg typed value serializer (saveCalc) for the Zig backup owner.
void z47_css_saveStateValue(const void *buffer, uint32_t size, const char *name, const char *type) {
	saveStateValue(buffer, size, name, type);
}
int8_t z47_css_cursorFontId(void) {
	if(cursorFont == &tinyFont)     return 1;
	if(cursorFont == &standardFont) return 2;
	if(cursorFont == &numericFont)  return 3;
	return -1;
}

// backup.cfg restore primitives for the Zig backup owner: the typed value
// parser (reads the file-static paramHead list) + the linked-list build/free.
void z47_css_restoreStateValue(void *buffer, uint32_t size, const char *name, const char *type) {
	restoreStateValue(buffer, size, name, type);
}
int z47_css_backupOpenParse(void) {
	char oneParam[200];
	int ret = ioFileOpen(ioPathBackup, ioModeRead);
	if(ret != FILE_OK) return ret;
	z47_calc_state_legacy_readLine(oneParam);
	paramHead = malloc(sizeof(cfgFileParam_t));
	paramCurrent = paramHead;
	paramCurrent->param = malloc(strlen(oneParam) + 1);
	strcpy(paramCurrent->param, oneParam);
	paramCurrent->next = NULL;
	z47_calc_state_legacy_readLine(oneParam);
	while(!ioEof()) {
		paramCurrent->next = malloc(sizeof(cfgFileParam_t));
		paramCurrent = paramCurrent->next;
		paramCurrent->param = malloc(strlen(oneParam) + 1);
		strcpy(paramCurrent->param, oneParam);
		paramCurrent->next = NULL;
		z47_calc_state_legacy_readLine(oneParam);
	}
	ioFileClose();
	return FILE_OK;
}
void z47_css_backupFreeParams(void) {
	paramCurrent = paramHead;
	while(paramHead) {
		paramHead = paramHead->next;
		free(paramCurrent->param);
		free(paramCurrent);
		paramCurrent = paramHead;
	}
}

#endif // !DMCP_BUILD