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

uint16_t z47_register_metadata_get_data_max_length_in_blocks(const void *data_ptr) {
  return ((const strLgIntHeader_t *)data_ptr)->dataMaxLengthInBlocks;
}

void z47_register_metadata_set_data_max_length_in_blocks(void *data_ptr, uint16_t max_data_len) {
  ((strLgIntHeader_t *)data_ptr)->dataMaxLengthInBlocks = max_data_len;
}

uint16_t z47_register_metadata_get_matrix_payload_size_in_blocks(const void *data_ptr, uint16_t element_size_in_blocks) {
  const matrixHeader_t *header = (const matrixHeader_t *)data_ptr;

  return (uint16_t)(header->matrixRows * header->matrixColumns * element_size_in_blocks);
}

uint16_t z47_register_metadata_str_lg_int_header_size_in_blocks(void) {
  return TO_BLOCKS(sizeof(strLgIntHeader_t));
}

uint16_t z47_register_metadata_matrix_header_size_in_blocks(void) {
  return TO_BLOCKS(sizeof(matrixHeader_t));
}

uint16_t z47_register_metadata_complex34_size_in_blocks(void) {
  return COMPLEX34_SIZE_IN_BLOCKS;
}

uint16_t z47_register_metadata_short_integer_size_in_blocks(void) {
  return SHORT_INTEGER_SIZE_IN_BLOCKS;
}

uint16_t z47_register_metadata_config_size_in_blocks(void) {
  return CONFIG_SIZE_IN_BLOCKS;
}

bool_t z47_register_metadata_memory_block_available(uint16_t size_in_blocks) {
  return isMemoryBlockAvailable(size_in_blocks, 2, 0.1f);
}

uint16_t z47_register_metadata_align_long_integer_blocks(uint16_t size_in_blocks) {
  const uint16_t limb_size_in_blocks = TO_BLOCKS(LIMB_SIZE);

  if(TO_BYTES(size_in_blocks) % LIMB_SIZE != 0) {
    return (uint16_t)(((size_in_blocks / limb_size_in_blocks) + 1) * limb_size_in_blocks);
  }

  return size_in_blocks;
}

void z47_register_metadata_initialize_matrix_header_1x1(void *data_ptr) {
  matrixHeader_t *header = (matrixHeader_t *)data_ptr;

  if(header == NULL) {
    return;
  }

  header->matrixRows = 1;
  header->matrixColumns = 1;
}

void z47_register_metadata_report_ram_full(void) {
  displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}

uint32_t z47_register_metadata_builtin_menu_item_count(void) {
  return LAST_ITEM;
}

bool_t z47_register_metadata_builtin_menu_item_is_menu(uint32_t index) {
  return index < LAST_ITEM && (indexOfItems[index].status & CAT_STATUS) == CAT_MENU;
}

const char *z47_register_metadata_builtin_menu_item_name(uint32_t index) {
  if(index >= LAST_ITEM) {
    return "";
  }

  return indexOfItems[index].itemCatalogName;
}

uint32_t z47_register_metadata_user_menu_count(void) {
  return numberOfUserMenus;
}

const char *z47_register_metadata_user_menu_name(uint32_t index) {
  if(index >= numberOfUserMenus) {
    return "";
  }

  return userMenus[index].menuName;
}

int32_t z47_register_metadata_compare_menu_names(const char *left, const char *right) {
  return compareString(left, right, CMP_NAME);
}

calcRegister_t z47_register_metadata_find_reserved_variable_name(const char *variable_name, uint8_t glyph_length) {
  for(calcRegister_t reg = 0; reg < NUMBER_OF_RESERVED_VARIABLES; ++reg) {
    if(allReservedVariables[reg].reservedVariableName[0] != glyph_length) {
      continue;
    }

    if(compareString(variable_name, (const char *)(allReservedVariables[reg].reservedVariableName + 1), CMP_NAME) == 0) {
      return (calcRegister_t)(FIRST_RESERVED_VARIABLE + reg);
    }
  }

  return INVALID_VARIABLE;
}

void z47_register_metadata_report_invalid_name(void) {
  displayCalcErrorMessage(ERROR_INVALID_NAME, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}

void z47_register_metadata_report_undef_source_var(void) {
  displayCalcErrorMessage(ERROR_UNDEF_SOURCE_VAR, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}

void z47_register_metadata_report_cannot_delete_predef_item(void) {
  displayCalcErrorMessage(ERROR_CANNOT_DELETE_PREDEF_ITEM, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}