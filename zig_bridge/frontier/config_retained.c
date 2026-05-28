// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

void z47_frontier_push_u32_to_x(uint32_t value) {
	longInteger_t tmp;
	liftStack();
	longIntegerInit(tmp);
	uInt32ToLongInteger(value, tmp);
	convertLongIntegerToLongIntegerRegister(tmp, REGISTER_X);
	longIntegerFree(tmp);
}

void z47_frontier_release_saved_statistical_sums(void) {
	if(savedStatisticalSumsPointer != NULL) {
		freeC47Blocks(savedStatisticalSumsPointer, NUMBER_OF_STATISTICAL_SUMS * REAL_SIZE_IN_BLOCKS(75));
	}
}

bool_t z47_frontier_is_r47_fam(void) {
	return isR47FAM;
}

void z47_frontier_retained_fnSetGapChar(uint16_t charParam);
void z47_frontier_retained_fnSettingsDispFormatGrpL(uint16_t param);
void z47_frontier_retained_fnSettingsDispFormatGrp1Lo(uint16_t param);
void z47_frontier_retained_fnSettingsDispFormatGrp1L(uint16_t param);
void z47_frontier_retained_fnSettingsDispFormatGrpR(uint16_t param);
void z47_frontier_retained_fnMenuGapL(uint16_t unusedButMandatoryParameter);
void z47_frontier_retained_fnMenuGapRX(uint16_t unusedButMandatoryParameter);
void z47_frontier_retained_fnMenuGapR(uint16_t unusedButMandatoryParameter);
void z47_frontier_retained_fnIntegerMode(uint16_t mode);
void z47_frontier_retained_fnWho(uint16_t unusedButMandatoryParameter);
void z47_frontier_retained_fnVersion(uint16_t unusedButMandatoryParameter);
void z47_frontier_retained_fnSetRoundingMode(uint16_t RM);
void z47_frontier_retained_fnSetSignificantDigits(uint16_t S);
void z47_frontier_retained_fnSetBaseNr(uint16_t S);
void z47_frontier_retained_fnSetFractionDigits(uint16_t S);
void z47_frontier_retained_fnAngularMode(uint16_t am);
void z47_frontier_retained_fnFractionType(uint16_t unusedButMandatoryParameter);
void z47_frontier_retained_fnRange(uint16_t R);
void z47_frontier_retained_fnHide(uint16_t H);
void z47_frontier_retained_fnConfirmationYes(uint16_t unusedButMandatoryParameter);
void z47_frontier_retained_fnConfirmationNo(uint16_t unusedButMandatoryParameter);
void z47_frontier_retained_fnGetRange(uint16_t unusedButMandatoryParameter);
void z47_frontier_retained_fnGetHide(uint16_t unusedButMandatoryParameter);
void z47_frontier_retained_fnGetLastErr(uint16_t unusedButMandatoryParameter);
void z47_frontier_retained_fnClAll(uint16_t confirmation);
void z47_frontier_retained_fnKeysManagement(uint16_t choice);

#define fnSetGapChar z47_frontier_retained_fnSetGapChar
#define fnSettingsDispFormatGrpL z47_frontier_retained_fnSettingsDispFormatGrpL
#define fnSettingsDispFormatGrp1Lo z47_frontier_retained_fnSettingsDispFormatGrp1Lo
#define fnSettingsDispFormatGrp1L z47_frontier_retained_fnSettingsDispFormatGrp1L
#define fnSettingsDispFormatGrpR z47_frontier_retained_fnSettingsDispFormatGrpR
#define fnMenuGapL z47_frontier_retained_fnMenuGapL
#define fnMenuGapRX z47_frontier_retained_fnMenuGapRX
#define fnMenuGapR z47_frontier_retained_fnMenuGapR
#define fnIntegerMode z47_frontier_retained_fnIntegerMode
#define fnWho z47_frontier_retained_fnWho
#define fnVersion z47_frontier_retained_fnVersion
#define fnSetRoundingMode z47_frontier_retained_fnSetRoundingMode
#define fnSetSignificantDigits z47_frontier_retained_fnSetSignificantDigits
#define fnSetBaseNr z47_frontier_retained_fnSetBaseNr
#define fnSetFractionDigits z47_frontier_retained_fnSetFractionDigits
#define fnAngularMode z47_frontier_retained_fnAngularMode
#define fnFractionType z47_frontier_retained_fnFractionType
#define fnRange z47_frontier_retained_fnRange
#define fnHide z47_frontier_retained_fnHide
#define fnConfirmationYes z47_frontier_retained_fnConfirmationYes
#define fnConfirmationNo z47_frontier_retained_fnConfirmationNo
#define fnGetRange z47_frontier_retained_fnGetRange
#define fnGetHide z47_frontier_retained_fnGetHide
#define fnGetLastErr z47_frontier_retained_fnGetLastErr
#define fnClAll z47_frontier_retained_fnClAll
#define fnKeysManagement z47_frontier_retained_fnKeysManagement
#include "../../src/c47/config.c"

void z47_frontier_keys_to_user_case(void) {
	if(Norm_Key_00_key != -1) {
		kbd_usr[Norm_Key_00_key].primary = Norm_Key_00.func;
		setUserKeyArgument(Norm_Key_00_key * 6, Norm_Key_00.funcParam);
		fnRefreshState();
		fnSetFlag(FLAG_USER);
	}
	else {
		Norm_Key_00.used = false;
		displayCalcErrorMessage(ERROR_CANNOT_ASSIGN_HERE, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
	}
}

void z47_frontier_keys_from_user_case(void) {
	if(Norm_Key_00_key != -1) {
		Norm_Key_00.func = kbd_usr[Norm_Key_00_key].primary;
		Norm_Key_00.funcParam[0] = 0;
		Norm_Key_00.used = Norm_Key_00.func != kbd_std[Norm_Key_00_key].primary;
		char *funcParam = (char *)getNthString((uint8_t *)userKeyLabel, Norm_Key_00_key * 6);
		if((funcParam[0] != 0) && ((Norm_Key_00.func == -MNU_DYNAMIC) || (Norm_Key_00.func == ITM_XEQ) || (Norm_Key_00.func == ITM_RCL))) {
			strcpy(Norm_Key_00.funcParam, (char *)getNthString((uint8_t *)userKeyLabel, Norm_Key_00_key * 6));
		}
		fnRefreshState();
		fnClearFlag(FLAG_USER);
	}
	else {
		Norm_Key_00.used = false;
		displayCalcErrorMessage(ERROR_CANNOT_ASSIGN_HERE, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
	}
}

void z47_frontier_keys_user_layout_reset_case(void) {
	xcopy(kbd_usr, kbd_std, sizeof(kbd_std_C47));
	Norm_Key_00.func = Norm_Key_00_item_in_layout;
	Norm_Key_00.funcParam[0] = 0;
	Norm_Key_00.used = false;
	fnRefreshState();
	fnClearFlag(FLAG_USER);
}