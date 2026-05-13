// SPDX-License-Identifier: GPL-3.0-only

#include <stddef.h>
#include <stdint.h>

#include "program_serialization_test_runtime.h"

#define PROGRAM_VERSION 1u
#define OLDEST_COMPATIBLE_PROGRAM_VERSION 1u
#define BACKUP_FORMAT 0u

static void addSpaceAfterPrograms(uint16_t size) {
  if(freeProgramBytes < size) {
    uint8_t *oldBeginOfProgramMemory = beginOfProgramMemory;
    uint32_t programSizeInBlocks = z47_program_serialization_runtime_get_ram_size_in_blocks() - z47_program_serialization_runtime_to_c47_mem_ptr(beginOfProgramMemory);
    uint32_t newProgramSizeInBlocks = TO_BLOCKS(TO_BYTES(programSizeInBlocks) - freeProgramBytes + size);

    freeProgramBytes += TO_BYTES(newProgramSizeInBlocks - programSizeInBlocks);
    resizeProgramMemory((uint16_t)newProgramSizeInBlocks);
    currentStep += beginOfProgramMemory - oldBeginOfProgramMemory;
    firstDisplayedStep += beginOfProgramMemory - oldBeginOfProgramMemory;
    beginOfCurrentProgram += beginOfProgramMemory - oldBeginOfProgramMemory;
    endOfCurrentProgram += beginOfProgramMemory - oldBeginOfProgramMemory;
  }

  firstFreeProgramByte += size;
  freeProgramBytes -= size;
}

static bool_t addEndNeeded(void) {
  if(firstFreeProgramByte <= beginOfProgramMemory) {
    return false;
  }
  if(firstFreeProgramByte == beginOfProgramMemory + 1) {
    return true;
  }
  if(z47_program_serialization_runtime_is_at_end_of_program(firstFreeProgramByte - 2)) {
    return false;
  }
  return true;
}

void oracle_fnSaveProgram(uint16_t label) {
  uint16_t savedCurrentLocalStepNumber;
  uint16_t savedCurrentProgramNumber;
  size_t currentSizeInBytes;
  uint32_t index;
  int ret;

  if(z47_program_serialization_runtime_check_power()) {
    return;
  }

  savedCurrentLocalStepNumber = currentLocalStepNumber;
  savedCurrentProgramNumber = currentProgramNumber;

  if(!z47_program_serialization_runtime_select_program(label)) {
    return;
  }

  ret = z47_program_serialization_runtime_open_save_program();
  if(ret != FILE_OK) {
    if(ret != FILE_CANCEL) {
      z47_program_serialization_runtime_display_write_error();
    }
    currentLocalStepNumber = savedCurrentLocalStepNumber;
    currentProgramNumber = savedCurrentProgramNumber;
    return;
  }

  z47_program_serialization_runtime_write_literal("PROGRAM_FILE_FORMAT\n");
  z47_program_serialization_runtime_write_u8_line(BACKUP_FORMAT);
  z47_program_serialization_runtime_write_literal("C47_program_file_version\n");
  z47_program_serialization_runtime_write_u32_line(PROGRAM_VERSION);

  currentSizeInBytes = (size_t)(endOfCurrentProgram - beginOfCurrentProgram);
  if(currentProgramNumber == numberOfPrograms) {
    currentSizeInBytes -= 2;
  }

  z47_program_serialization_runtime_write_literal("PROGRAM\n");
  z47_program_serialization_runtime_write_u32_line((uint32_t)currentSizeInBytes);
  for(index = 0; index < currentSizeInBytes; index++) {
    z47_program_serialization_runtime_write_u8_line(beginOfCurrentProgram[index]);
  }
  if(currentProgramNumber == numberOfPrograms) {
    z47_program_serialization_runtime_write_u8_line(255);
    z47_program_serialization_runtime_write_u8_line(255);
  }

  z47_program_serialization_runtime_close_file();
  currentLocalStepNumber = savedCurrentLocalStepNumber;
  currentProgramNumber = savedCurrentProgramNumber;
  temporaryInformation = TI_SAVED;
}

void oracle_fnLoadProgram(uint16_t unusedButMandatoryParameter) {
  char keyBuffer[256];
  char valueBuffer[256];
  uint32_t loadedVersion = 0;
  uint32_t pgmSizeInByte;
  uint32_t index;
  uint8_t *startOfProgram;
  int ret;

  (void)unusedButMandatoryParameter;

  ret = z47_program_serialization_runtime_open_load_program();
  if(ret != FILE_OK) {
    if(ret != FILE_CANCEL) {
      z47_program_serialization_runtime_display_read_error();
    }
    return;
  }

  z47_program_serialization_runtime_read_line(keyBuffer);
  if(z47_program_serialization_runtime_line_equals(keyBuffer, "PROGRAM_FILE_FORMAT")) {
    z47_program_serialization_runtime_read_line(valueBuffer);
  }
  else {
    z47_program_serialization_runtime_show_warning(" \nThis is not a C47 program\n\nIt will not be loaded.");
    z47_program_serialization_runtime_close_file();
    return;
  }

  z47_program_serialization_runtime_read_line(keyBuffer);
  z47_program_serialization_runtime_read_line(valueBuffer);
  if(z47_program_serialization_runtime_line_equals(keyBuffer, "C47_program_file_version")) {
    loadedVersion = z47_program_serialization_runtime_parse_u32_line(valueBuffer);
    if(loadedVersion < OLDEST_COMPATIBLE_PROGRAM_VERSION) {
      z47_program_serialization_runtime_show_warning(" \n   !!! Program version is too old !!!\nNot compatible with current version\n \nIt will not be loaded.");
      z47_program_serialization_runtime_close_file();
      return;
    }
  }
  else if(z47_program_serialization_runtime_line_equals(keyBuffer, "WP43_program_file_version")) {
    loadedVersion = z47_program_serialization_runtime_parse_u32_line(valueBuffer);
    z47_program_serialization_runtime_show_warning(" \nThis is a WP43 program\nWP43 program support is experimental\nSome instructions may not be \ncompatible with the C47 and may\ncrash the calculator.");
  }
  else {
    z47_program_serialization_runtime_show_warning(" \nThis is not a C47 program\n \nIt will not be loaded.");
    z47_program_serialization_runtime_close_file();
    return;
  }

  z47_program_serialization_runtime_read_line(keyBuffer);
  z47_program_serialization_runtime_read_line(valueBuffer);
  if(!z47_program_serialization_runtime_line_equals(keyBuffer, "PROGRAM")) {
    z47_program_serialization_runtime_close_file();
    return;
  }

  pgmSizeInByte = z47_program_serialization_runtime_parse_u32_line(valueBuffer);

  if(addEndNeeded()) {
    addSpaceAfterPrograms(2);
    *(firstFreeProgramByte - 2) = (uint8_t)((ITM_END >> 8) | 0x80);
    *(firstFreeProgramByte - 1) = (uint8_t)(ITM_END & 0xff);
    *(firstFreeProgramByte    ) = 0xffu;
    *(firstFreeProgramByte + 1) = 0xffu;
    z47_program_serialization_runtime_scan_labels_and_programs();
  }

  addSpaceAfterPrograms((uint16_t)pgmSizeInByte);
  startOfProgram = firstFreeProgramByte - pgmSizeInByte;
  for(index = 0; index < pgmSizeInByte; index++) {
    z47_program_serialization_runtime_read_line(valueBuffer);
    startOfProgram[index] = z47_program_serialization_runtime_parse_u8_line(valueBuffer);
  }

  *(firstFreeProgramByte    ) = 0xffu;
  *(firstFreeProgramByte + 1) = 0xffu;
  z47_program_serialization_runtime_scan_labels_and_programs();
  z47_program_serialization_runtime_go_to_last_program();
  z47_program_serialization_runtime_close_file();

  if(loadedVersion < OLDEST_COMPATIBLE_PROGRAM_VERSION) {
    z47_program_serialization_runtime_show_warning(" \n   !!! Program version is too old !!!\nNot compatible with current version\n \nIt will not be loaded.");
    return;
  }

  temporaryInformation = TI_PROGRAM_LOADED;
}