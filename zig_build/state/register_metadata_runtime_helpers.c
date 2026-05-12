// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

uint32_t z47_register_metadata_get_global_descriptor(calcRegister_t reg) {
  return globalRegister[reg].descriptor;
}

void z47_register_metadata_set_global_descriptor(calcRegister_t reg, uint32_t descriptor) {
  globalRegister[reg].descriptor = descriptor;
}

bool_t z47_register_metadata_try_get_named_descriptor(calcRegister_t reg, uint32_t *descriptor) {
  if(numberOfNamedVariables == 0 || reg < FIRST_NAMED_VARIABLE) {
    return false;
  }

  reg -= FIRST_NAMED_VARIABLE;
  if(reg >= numberOfNamedVariables) {
    return false;
  }

  *descriptor = allNamedVariables[reg].header.descriptor;
  return true;
}

bool_t z47_register_metadata_try_set_named_descriptor(calcRegister_t reg, uint32_t descriptor) {
  if(numberOfNamedVariables == 0 || reg < FIRST_NAMED_VARIABLE) {
    return false;
  }

  reg -= FIRST_NAMED_VARIABLE;
  if(reg >= numberOfNamedVariables) {
    return false;
  }

  allNamedVariables[reg].header.descriptor = descriptor;
  return true;
}

uint32_t z47_register_metadata_get_named_descriptor_unchecked(uint16_t index) {
  return allNamedVariables[index].header.descriptor;
}

void z47_register_metadata_set_named_descriptor_unchecked(uint16_t index, uint32_t descriptor) {
  allNamedVariables[index].header.descriptor = descriptor;
}

bool_t z47_register_metadata_try_get_local_descriptor(calcRegister_t reg, uint32_t *descriptor) {
  if(currentLocalRegisters == NULL || reg < FIRST_LOCAL_REGISTER) {
    return false;
  }

  reg -= FIRST_LOCAL_REGISTER;
  if(reg >= currentNumberOfLocalRegisters) {
    return false;
  }

  *descriptor = currentLocalRegisters[reg].descriptor;
  return true;
}

bool_t z47_register_metadata_try_set_local_descriptor(calcRegister_t reg, uint32_t descriptor) {
  if(currentLocalRegisters == NULL || reg < FIRST_LOCAL_REGISTER) {
    return false;
  }

  reg -= FIRST_LOCAL_REGISTER;
  if(reg >= currentNumberOfLocalRegisters) {
    return false;
  }

  currentLocalRegisters[reg].descriptor = descriptor;
  return true;
}

uint32_t z47_register_metadata_get_reserved_descriptor(calcRegister_t reg) {
  return allReservedVariables[reg - FIRST_RESERVED_VARIABLE].header.descriptor;
}

uint32_t z47_register_metadata_get_reserved_data_type_descriptor(calcRegister_t reg) {
  reg -= FIRST_RESERVED_VARIABLE;
  if(reg < NUMBER_OF_LETTERED_VARIABLES) {
    return globalRegister[reg + REGISTER_X].descriptor;
  }
  return allReservedVariables[reg].header.descriptor;
}

bool_t z47_register_metadata_reserved_allows_data_type_write(calcRegister_t reg) {
  reg -= FIRST_RESERVED_VARIABLE;
  return allReservedVariables[reg].header.pointerToRegisterData != C47_NULL && allReservedVariables[reg].header.readOnly == 0;
}

void *z47_register_metadata_to_pc_mem_ptr(uint16_t mem_ptr) {
  return TO_PCMEMPTR(mem_ptr);
}

uint16_t z47_register_metadata_to_c47_mem_ptr(const void *mem_ptr) {
  return TO_C47MEMPTR(mem_ptr);
}