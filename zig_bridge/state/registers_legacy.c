// SPDX-License-Identifier: GPL-3.0-only

#define getRegisterDataType z47_registers_getRegisterDataType
#define getRegisterDataPointer z47_registers_getRegisterDataPointer
#define getRegisterTag z47_registers_getRegisterTag
#define setRegisterDataType z47_registers_setRegisterDataType
#define setRegisterDataPointer z47_registers_setRegisterDataPointer
#define setRegisterTag z47_registers_setRegisterTag
#define allocateLocalRegisters z47_registers_allocateLocalRegisters
#define validateName z47_registers_validateName
#define isUniqueMenuName z47_registers_isUniqueMenuName
#define allocateNamedVariable z47_registers_allocateNamedVariable
#define findNamedVariable z47_registers_findNamedVariable
#define findOrAllocateNamedVariable z47_registers_findOrAllocateNamedVariable
#define fnDeleteVariable z47_registers_fnDeleteVariable
#define fnDeleteAllVariables z47_registers_fnDeleteAllVariables
#define fnClearAllVariables z47_registers_fnClearAllVariables
#define setRegisterMaxDataLengthInBlocks z47_registers_setRegisterMaxDataLengthInBlocks
#define getRegisterMaxDataLengthInBlocks z47_registers_getRegisterMaxDataLengthInBlocks
#define getRegisterFullSizeInBlocks z47_registers_getRegisterFullSizeInBlocks
#define clearRegister z47_registers_clearRegister
#define fnClearRegisters z47_registers_fnClearRegisters
#define fnGetLocR z47_registers_fnGetLocR
#define adjustResult z47_registers_adjustResult
#define copySourceRegisterToDestRegister z47_registers_copySourceRegisterToDestRegister
#define reallocateRegister z47_registers_reallocateRegister
#define fnToReal z47_registers_fnToReal
#define saveLastX z47_registers_saveLastX
#define fnRegClr z47_registers_fnRegClr
#define fnRegSort z47_registers_fnRegSort
#define fnRegCopy z47_registers_fnRegCopy
#define fnRegSwap z47_registers_fnRegSwap
#define isFunctionAllowingNewVariable z47_registers_isFunctionAllowingNewVariable

#include "../../src/c47/registers.c"

uint8_t z47_registers_get_reg_clr_range(uint16_t *s, uint16_t *n) {
	return getRegParam(NULL, s, n, NULL);
}

uint8_t z47_registers_get_reg_swap_range(uint16_t *s, uint16_t *n, uint16_t *d) {
	return getRegParam(NULL, s, n, d);
}

uint8_t z47_registers_get_reg_copy_params(bool_t *f, uint16_t *s, uint16_t *n, uint16_t *d) {
	return getRegParam(f, s, n, d);
}

void z47_registers_sort_reg(uint16_t range_start, uint16_t range_end) {
	sortReg(range_start, range_end);
}