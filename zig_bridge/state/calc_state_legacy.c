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