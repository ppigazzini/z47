// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

void oracle_undo(void);

#define fnClX oracle_fnClX
#define fnClearStack oracle_fnClearStack
#define liftStack oracle_liftStack
#define _Drop oracle__Drop
#define fnDrop oracle_fnDrop
#define fnDropY oracle_fnDropY
#define fnDropZ oracle_fnDropZ
#define fnDropT oracle_fnDropT
#define fnDropN oracle_fnDropN
#define fnRollUp oracle_fnRollUp
#define fnRollDown oracle_fnRollDown
#define fnDisplayStack oracle_fnDisplayStack
#define fnSwapX oracle_fnSwapX
#define fnSwapY oracle_fnSwapY
#define fnSwapZ oracle_fnSwapZ
#define fnSwapT oracle_fnSwapT
#define fnSwapN oracle_fnSwapN
#define fnDupN oracle_fnDupN
#define fnSwapXY oracle_fnSwapXY
#define fnShuffle oracle_fnShuffle
#define fnFillStack oracle_fnFillStack
#define fnGetStackSize oracle_fnGetStackSize
#define saveForUndo oracle_saveForUndo
#define fnUndo oracle_fnUndo
#define undo oracle_undo
#define fillStackWithReal0 oracle_fillStackWithReal0
#define clearRegister oracle_clearRegister

void oracle_clearRegister(calcRegister_t regist);
void z47_stack_parity_raw_clearRegister(calcRegister_t reg);

#include "../../../src/c47/stack.c"

void oracle_clearRegister(calcRegister_t regist) {
	if((lastIntegerBase == 0) && (Input_Default == ID_43S || Input_Default == ID_DP)) {
		if(getRegisterDataType(regist) == dtReal34) {
			real34SetZero(REGISTER_REAL34_DATA(regist));
			setRegisterDataType(regist, (uint16_t)dtReal34, amNone);
		}
		else {
			reallocateRegister(regist, dtReal34, 0, amNone);
			real34SetZero(REGISTER_REAL34_DATA(regist));
		}
		return;
	}

	if((lastIntegerBase == 0) && (Input_Default == ID_CPXDP)) {
		const uint32_t tag = getSystemFlag(FLAG_POLAR) ? currentAngularMode | amPolar : amNone;

		if(getRegisterDataType(regist) == dtComplex34) {
			real34SetZero(REGISTER_REAL34_DATA(regist));
			real34SetZero(REGISTER_IMAG34_DATA(regist));
			setRegisterDataType(regist, (uint16_t)dtComplex34, tag);
		}
		else {
			reallocateRegister(regist, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, tag);
			real34SetZero(REGISTER_REAL34_DATA(regist));
			real34SetZero(REGISTER_IMAG34_DATA(regist));
		}
		return;
	}

	if((lastIntegerBase == 0) && (Input_Default == ID_LI)) {
		longInteger_t lgInt;

		longIntegerInit(lgInt);
		uInt32ToLongInteger(0u, lgInt);
		convertLongIntegerToLongIntegerRegister(lgInt, regist);
		longIntegerFree(lgInt);
		return;
	}

	if(lastIntegerBase != 0) {
		longInteger_t lgInt;

		longIntegerInit(lgInt);
		uInt32ToLongInteger(0u, lgInt);
		convertLongIntegerToShortIntegerRegister(lgInt, lastIntegerBase, regist);
		longIntegerFree(lgInt);
		return;
	}

	z47_registers_retained_clearRegister(regist);
}

bool_t oracle_saveLastX(void) {
	copySourceRegisterToDestRegister(REGISTER_X, REGISTER_L);
	return lastErrorCode == ERROR_NONE;
}

void oracle_fnGetLocR(uint16_t unusedButMandatoryParameter) {
	longInteger_t locR;

	(void)unusedButMandatoryParameter;

	oracle_liftStack();
	longIntegerInit(locR);
	uInt32ToLongInteger(currentNumberOfLocalRegisters, locR);
	convertLongIntegerToLongIntegerRegister(locR, REGISTER_X);
	longIntegerFree(locR);
}

void oracle_fnClearRegisters(uint16_t confirmation) {
	calcRegister_t regist;

	if((confirmation == NOT_CONFIRMED) && (programRunStop != PGM_RUNNING)) {
		z47_stack_runtime_request_clear_registers_confirmation();
		return;
	}

	for(regist = 0; regist < REGISTER_X; regist++) {
		clearRegister(regist);
	}

	for(regist = 0; regist < currentNumberOfLocalRegisters; regist++) {
		clearRegister(FIRST_LOCAL_REGISTER + regist);
	}

	if(!getSystemFlag(FLAG_SSIZE8)) {
		for(regist = REGISTER_A; regist <= REGISTER_D; regist++) {
			clearRegister(regist);
		}
	}

	for(regist = REGISTER_I; regist <= REGISTER_W; regist++) {
		clearRegister(regist);
	}
}

void z47_registers_retained_fnClearRegisters(uint16_t confirmation) {
	oracle_fnClearRegisters(confirmation);
}

void z47_registers_retained_clearRegister(calcRegister_t reg) {
	z47_stack_parity_raw_clearRegister(reg);
}

uint8_t z47_registers_retained_get_reg_clr_range(uint16_t *s, uint16_t *n);
uint8_t z47_registers_retained_get_reg_swap_range(uint16_t *s, uint16_t *n, uint16_t *d);
uint8_t z47_registers_retained_get_reg_copy_params(bool_t *f, uint16_t *s, uint16_t *n, uint16_t *d);
void z47_registers_retained_fnRegCopy(uint16_t unusedButMandatoryParameter);

void oracle_fnRegClr(uint16_t unusedButMandatoryParameter) {
	uint16_t s, n;

	(void)unusedButMandatoryParameter;

	if((lastErrorCode = z47_registers_retained_get_reg_clr_range(&s, &n)) == ERROR_NONE) {
		for(uint16_t i = s; i < (uint16_t)(s + n); ++i) {
			oracle_clearRegister((calcRegister_t)i);
		}
	}
	else {
		z47_stack_runtime_report_register_command_error(lastErrorCode);
	}
}

void oracle_fnRegSwap(uint16_t unusedButMandatoryParameter) {
	uint16_t s, n, d;

	(void)unusedButMandatoryParameter;

	if((lastErrorCode = z47_registers_retained_get_reg_swap_range(&s, &n, &d)) == ERROR_NONE) {
		if((d < s + n) && (s < d + n)) {
			z47_stack_runtime_report_register_command_error(ERROR_OUT_OF_RANGE);
		}
		else {
			for(uint16_t i = 0; i < n; ++i) {
				registerHeader_t savedRegisterHeader = globalRegister[s + i];
				globalRegister[s + i] = globalRegister[d + i];
				globalRegister[d + i] = savedRegisterHeader;
			}
		}
	}
	else {
		z47_stack_runtime_report_register_command_error(lastErrorCode);
	}
}

void oracle_fnRegCopy(uint16_t unusedButMandatoryParameter) {
	bool_t f;
	uint16_t s, n, d;

	if((lastErrorCode = z47_registers_retained_get_reg_copy_params(&f, &s, &n, &d)) == ERROR_NONE) {
		if(f) {
			z47_registers_retained_fnRegCopy(unusedButMandatoryParameter);
		}
		else if(s > d) {
			for(uint16_t i = 0; i < n; ++i) {
				copySourceRegisterToDestRegister((calcRegister_t)(s + i), (calcRegister_t)(d + i));
				if(lastErrorCode == ERROR_RAM_FULL) {
					return;
				}
			}
		}
		else if(s < d) {
			for(uint16_t i = n; i > 0; --i) {
				copySourceRegisterToDestRegister((calcRegister_t)(s + i - 1), (calcRegister_t)(d + i - 1));
				if(lastErrorCode == ERROR_RAM_FULL) {
					return;
				}
			}
		}
	}
	else {
		z47_stack_runtime_report_register_command_error(lastErrorCode);
	}
}
