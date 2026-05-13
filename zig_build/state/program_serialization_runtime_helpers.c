// SPDX-License-Identifier: GPL-3.0-only

#include <inttypes.h>
#include <stdio.h>
#include <string.h>

#include "c47.h"

void readLine(char *line);

bool_t z47_program_serialization_runtime_check_power(void) {
#if defined(DMCP_BUILD)
  return power_check_screen();
#else
  return false;
#endif
}

bool_t z47_program_serialization_runtime_select_program(uint16_t label) {
  dynamicMenuItem = -1;

  if(label == 0 && !tam.alpha && tam.digitsSoFar == 0) {
    uint16_t currentLabel = 0;

    strcpy(tmpStringLabelOrVariableName, "untitled");
    while(currentLabel < numberOfLabels) {
      if(labelList[currentLabel].program == currentProgramNumber) {
        break;
      }
      currentLabel++;
    }
    while(currentLabel < numberOfLabels) {
      if(labelList[currentLabel].step > 0) {
        xcopy(tmpStringLabelOrVariableName, labelList[currentLabel].labelPointer + 1, *(labelList[currentLabel].labelPointer));
        tmpStringLabelOrVariableName[*(labelList[currentLabel].labelPointer)] = 0;
        break;
      }
      currentLabel++;
    }
    return true;
  }

  if(label >= FIRST_LABEL && label <= LAST_LABEL) {
    fnGoto(label);
    xcopy(tmpStringLabelOrVariableName, labelList[label - FIRST_LABEL].labelPointer + 1, *(labelList[label - FIRST_LABEL].labelPointer));
    tmpStringLabelOrVariableName[*(labelList[label - FIRST_LABEL].labelPointer)] = 0;
    return true;
  }

  displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  sprintf(errorMessage, "label %" PRIu16 " is not a global label", label);
  moreInfoOnError("In function fnSaveProgram/fnExportProgram (_selectProgram):", errorMessage, NULL, NULL);
#endif
  return false;
}

int z47_program_serialization_runtime_open_save_program(void) {
  return ioFileOpen(ioPathSaveProgram, ioModeWrite);
}

int z47_program_serialization_runtime_open_load_program(void) {
  return ioFileOpen(ioPathLoadProgram, ioModeRead);
}

void z47_program_serialization_runtime_write_literal(const char *text) {
  ioFileWrite(text, strlen(text));
}

void z47_program_serialization_runtime_write_u32_line(uint32_t value) {
  char line[64];

  sprintf(line, "%" PRIu32 "\n", value);
  ioFileWrite(line, strlen(line));
}

void z47_program_serialization_runtime_write_u8_line(uint8_t value) {
  char line[32];

  sprintf(line, "%u\n", (unsigned)value);
  ioFileWrite(line, strlen(line));
}

void z47_program_serialization_runtime_read_line(char *buffer) {
  readLine(buffer);
}

void z47_program_serialization_runtime_close_file(void) {
  ioFileClose();
}

void z47_program_serialization_runtime_display_write_error(void) {
  displayCalcErrorMessage(ERROR_CANNOT_WRITE_FILE, ERR_REGISTER_LINE, REGISTER_X);
}

void z47_program_serialization_runtime_display_read_error(void) {
  displayCalcErrorMessage(ERROR_CANNOT_READ_FILE, ERR_REGISTER_LINE, REGISTER_X);
}

void z47_program_serialization_runtime_show_warning(const char *message) {
  char warning[256];

  strncpy(warning, message, sizeof(warning) - 1);
  warning[sizeof(warning) - 1] = 0;
  show_warning(warning);
}

void z47_program_serialization_runtime_scan_labels_and_programs(void) {
  scanLabelsAndPrograms();
}

void z47_program_serialization_runtime_go_to_last_program(void) {
  if(numberOfPrograms > 0) {
    goToGlobalStep(programList[numberOfPrograms - 1].step);
  }
}

bool_t z47_program_serialization_runtime_is_at_end_of_program(const uint8_t *step) {
  return isAtEndOfProgram((uint8_t *)step);
}

uint16_t z47_program_serialization_runtime_get_ram_size_in_blocks(void) {
  return RAM_SIZE_IN_BLOCKS;
}

uint16_t z47_program_serialization_runtime_to_c47_mem_ptr(const uint8_t *memPtr) {
  return TO_C47MEMPTR(memPtr);
}

uint32_t z47_program_serialization_runtime_parse_u32_line(const char *line) {
  return stringToUint32(line);
}

uint8_t z47_program_serialization_runtime_parse_u8_line(const char *line) {
  return stringToUint8(line);
}

bool_t z47_program_serialization_runtime_line_equals(const char *line, const char *expected) {
  return strcmp(line, expected) == 0;
}