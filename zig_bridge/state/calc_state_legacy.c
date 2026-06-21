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

// The save/restore trampolines below are consumed only by the host-only Zig
// section writer / parser owners (gated is_dmcp_build); guarding them off the
// DMCP lane keeps firmware byte-identical (those owners are dead-stripped on
// firmware, which loads/saves through the C retained path).
#if !defined(DMCP_BUILD)

// --- Save-serialization leaf formatters (z47_calc_state_save_sections owner) ---
// registerToSaveString / saveMatrixElements / UI64toString and the
// tmpRegisterString / loadedVersion buffers are file-static inside
// saveRestoreCalcState.c, so the Zig save_sections owner reaches them through
// these same-translation-unit trampolines (declared after the #include where
// the statics are in scope). realToString and the printerState/loadedVersion
// reads are wrapped here too to keep the macro/enum surface out of Zig. These
// are the per-element value formatters; the Zig owner frames the sections.
void z47_css_registerToSaveString(int16_t regist) { registerToSaveString(regist); }
void z47_css_saveMatrixElements(int16_t regist)   { saveMatrixElements(regist); }
void z47_css_UI64toString(uint64_t value, char *out) { UI64toString(value, out); }
char *z47_css_tmpRegisterString(void) { return tmpRegisterString; }

void z47_css_statSumString(uint16_t i) {
	tmpRegisterString = tmpString + START_REGISTER_VALUE;
	realToString(statisticalSumsPointer + i, tmpRegisterString);
}

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
int16_t  z47_css_toInt16(const char *s)  { return toInt16(s); }
uint8_t  z47_css_toUint8(const char *s)  { return toUint8(s); }
uint16_t z47_css_toUint16(const char *s) { return toUint16(s); }
uint32_t z47_css_toUint32(const char *s) { return toUint32(s); }
char *z47_css_next_word(char *s)              { return next_word(s); }
char *z47_css_skip_space(char *s)             { return skip_space(s); }
char *z47_css_skip_to_space_newline(char *s)  { return skip_to_space_newline(s); }
char *z47_css_toInt16_next_word(char *s, int16_t *val) { return toInt16_next_word(s, val); }
uint16_t z47_css_strcmp2(char *a, char *b)    { return strcmp2(a, b); }

void z47_css_restoreRegister(int16_t regist, char *type, char *value) { restoreRegister(regist, type, value); }
void z47_css_restoreMatrixData(int16_t regist) { restoreMatrixData(regist); }
void z47_css_skipMatrixData(char *type, char *value) { skipMatrixData(type, value); }
void z47_css_updateConstantsInEquations(void) { _updateConstantsInEquations(); }

void z47_css_loadStatSum(const char *str, uint16_t i) {
	stringToReal(str, statisticalSumsPointer + i, &ctxtReal75);
}

bool_t z47_css_isAtEndOfProgram(const uint8_t *step) { return isAtEndOfProgram(step); }
int16_t z47_css_normKey00Key(void) { return Norm_Key_00_key; }
int16_t z47_css_kbdStdPrimary(int16_t idx) { return kbd_std[idx].primary; }

void z47_css_set_loaded_version(uint32_t v) { loadedVersion = v; }

void z47_css_setPrinterOn(uint8_t v)    { printerState.print_on = v; }
void z47_css_setPrinterModel(uint8_t v) { printerState.printer_model = v; }
void z47_css_setPrinterDelay(uint16_t v){ printerState.delay = v; }

#endif // !DMCP_BUILD