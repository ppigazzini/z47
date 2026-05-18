// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

void z47_registers_retained_allocateLocalRegisters(uint16_t numberOfRegistersToAllocate);
bool_t z47_registers_retained_isFunctionAllowingNewVariable(uint16_t op);

void allocateLocalRegisters(uint16_t numberOfRegistersToAllocate) {
  z47_registers_retained_allocateLocalRegisters(numberOfRegistersToAllocate);
}