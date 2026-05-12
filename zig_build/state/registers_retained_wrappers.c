// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

void z47_registers_retained_allocateLocalRegisters(uint16_t numberOfRegistersToAllocate);
bool_t z47_registers_retained_validateName(const char *name);
bool_t z47_registers_retained_isUniqueMenuName(const char *name);
void z47_registers_retained_allocateNamedVariable(const char *variableName, dataType_t dataType, uint16_t fullDataSizeInBlocks);
void z47_registers_retained_fnDeleteVariable(uint16_t regist);
void z47_registers_retained_fnDeleteAllVariables(uint16_t confirmation);
void z47_registers_retained_fnClearAllVariables(uint16_t confirmation);
void z47_registers_retained_setRegisterMaxDataLengthInBlocks(calcRegister_t regist, uint16_t maxDataLen);
uint16_t z47_registers_retained_getRegisterMaxDataLengthInBlocks(calcRegister_t regist);
uint16_t z47_registers_retained_getRegisterFullSizeInBlocks(calcRegister_t regist);
void z47_registers_retained_clearRegister(calcRegister_t regist);
void z47_registers_retained_fnClearRegisters(uint16_t confirmation);
void z47_registers_retained_fnGetLocR(uint16_t unusedButMandatoryParameter);
void z47_registers_retained_adjustResult(calcRegister_t res, bool_t dropY, bool_t setCpxRes, calcRegister_t op1, calcRegister_t op2, calcRegister_t op3);
void z47_registers_retained_copySourceRegisterToDestRegister(calcRegister_t sourceRegister, calcRegister_t destRegister);
void z47_registers_retained_reallocateRegister(calcRegister_t regist, uint32_t dataType, uint16_t dataSizeWithoutDataLenBlocks, uint32_t tag);
void z47_registers_retained_fnToReal(uint16_t unusedButMandatoryParameter);
bool_t z47_registers_retained_saveLastX(void);
void z47_registers_retained_fnRegClr(uint16_t unusedButMandatoryParameter);
void z47_registers_retained_fnRegSort(uint16_t unusedButMandatoryParameter);
void z47_registers_retained_fnRegCopy(uint16_t unusedButMandatoryParameter);
void z47_registers_retained_fnRegSwap(uint16_t unusedButMandatoryParameter);
bool_t z47_registers_retained_isFunctionAllowingNewVariable(uint16_t op);

void allocateLocalRegisters(uint16_t numberOfRegistersToAllocate) {
  z47_registers_retained_allocateLocalRegisters(numberOfRegistersToAllocate);
}

bool_t validateName(const char *name) {
  return z47_registers_retained_validateName(name);
}

bool_t isUniqueMenuName(const char *name) {
  return z47_registers_retained_isUniqueMenuName(name);
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

void setRegisterMaxDataLengthInBlocks(calcRegister_t regist, uint16_t maxDataLen) {
  z47_registers_retained_setRegisterMaxDataLengthInBlocks(regist, maxDataLen);
}

uint16_t getRegisterMaxDataLengthInBlocks(calcRegister_t regist) {
  return z47_registers_retained_getRegisterMaxDataLengthInBlocks(regist);
}

uint16_t getRegisterFullSizeInBlocks(calcRegister_t regist) {
  return z47_registers_retained_getRegisterFullSizeInBlocks(regist);
}

void clearRegister(calcRegister_t regist) {
  z47_registers_retained_clearRegister(regist);
}

void fnClearRegisters(uint16_t confirmation) {
  z47_registers_retained_fnClearRegisters(confirmation);
}

void fnGetLocR(uint16_t unusedButMandatoryParameter) {
  z47_registers_retained_fnGetLocR(unusedButMandatoryParameter);
}

void adjustResult(calcRegister_t res, bool_t dropY, bool_t setCpxRes, calcRegister_t op1, calcRegister_t op2, calcRegister_t op3) {
  z47_registers_retained_adjustResult(res, dropY, setCpxRes, op1, op2, op3);
}

void copySourceRegisterToDestRegister(calcRegister_t sourceRegister, calcRegister_t destRegister) {
  z47_registers_retained_copySourceRegisterToDestRegister(sourceRegister, destRegister);
}

void reallocateRegister(calcRegister_t regist, uint32_t dataType, uint16_t dataSizeWithoutDataLenBlocks, uint32_t tag) {
  z47_registers_retained_reallocateRegister(regist, dataType, dataSizeWithoutDataLenBlocks, tag);
}

void fnToReal(uint16_t unusedButMandatoryParameter) {
  z47_registers_retained_fnToReal(unusedButMandatoryParameter);
}

bool_t saveLastX(void) {
  return z47_registers_retained_saveLastX();
}

void fnRegClr(uint16_t unusedButMandatoryParameter) {
  z47_registers_retained_fnRegClr(unusedButMandatoryParameter);
}

void fnRegSort(uint16_t unusedButMandatoryParameter) {
  z47_registers_retained_fnRegSort(unusedButMandatoryParameter);
}

void fnRegCopy(uint16_t unusedButMandatoryParameter) {
  z47_registers_retained_fnRegCopy(unusedButMandatoryParameter);
}

void fnRegSwap(uint16_t unusedButMandatoryParameter) {
  z47_registers_retained_fnRegSwap(unusedButMandatoryParameter);
}

bool_t isFunctionAllowingNewVariable(uint16_t op) {
  return z47_registers_retained_isFunctionAllowingNewVariable(op);
}