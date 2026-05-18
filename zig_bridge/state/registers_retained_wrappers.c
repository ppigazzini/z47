// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

void z47_registers_retained_allocateLocalRegisters(uint16_t numberOfRegistersToAllocate);
void z47_registers_retained_allocateNamedVariable(const char *variableName, dataType_t dataType, uint16_t fullDataSizeInBlocks);
void z47_registers_retained_fnDeleteVariable(uint16_t regist);
void z47_registers_retained_fnDeleteAllVariables(uint16_t confirmation);
void z47_registers_retained_fnClearAllVariables(uint16_t confirmation);
bool_t z47_registers_retained_isFunctionAllowingNewVariable(uint16_t op);

void allocateLocalRegisters(uint16_t numberOfRegistersToAllocate) {
  z47_registers_retained_allocateLocalRegisters(numberOfRegistersToAllocate);
}

void allocateNamedVariable(const char *variableName, dataType_t dataType, uint16_t fullDataSizeInBlocks) {
  z47_registers_retained_allocateNamedVariable(variableName, dataType, fullDataSizeInBlocks);
}

void fnDeleteVariable(uint16_t regist) {
  z47_registers_retained_fnDeleteVariable(regist);
}

void fnDeleteAllVariables(uint16_t confirmation) {
  z47_registers_retained_fnDeleteAllVariables(confirmation);
}

void fnClearAllVariables(uint16_t confirmation) {
  z47_registers_retained_fnClearAllVariables(confirmation);
}