// SPDX-License-Identifier: GPL-3.0-only

#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "program_serialization_test_runtime.h"

typedef struct {
  uint16_t label;
  uint16_t program_number;
} fake_label_t;

typedef struct {
  uint8_t *start;
  uint8_t *end;
} fake_program_t;

uint8_t *beginOfCurrentProgram = NULL;
uint8_t *endOfCurrentProgram = NULL;
uint8_t *firstDisplayedStep = NULL;
uint8_t *currentStep = NULL;
uint8_t *beginOfProgramMemory = NULL;
uint8_t *firstFreeProgramByte = NULL;
uint16_t freeProgramBytes = 0;
uint16_t currentLocalStepNumber = 0;
uint16_t currentProgramNumber = 0;
uint16_t numberOfPrograms = 0;
uint8_t temporaryInformation = 0;

static uint8_t fakeRam[RAM_SIZE_IN_BLOCKS * BYTES_PER_BLOCK];
static char loadFile[MAX_PROGRAM_PARITY_FILE_BYTES];
static size_t loadFileSize = 0;
static size_t loadFileOffset = 0;
static char savedFile[MAX_PROGRAM_PARITY_FILE_BYTES];
static size_t savedFileSize = 0;
static char lastWarning[256];
static uint8_t warningCount = 0;
static uint8_t lastErrorKind = 0;
static uint32_t scanLabelsCalls = 0;
static uint32_t goToLastProgramCalls = 0;
static int saveOpenResult = FILE_OK;
static int loadOpenResult = FILE_OK;
static bool_t powerBlocked = false;
static enum {
  activeFileNone = 0,
  activeFileSave,
  activeFileLoad,
} activeFile = activeFileNone;
static fake_program_t programs[16];
static fake_label_t labels[16];
static uint16_t labelCount = 0;

static bool_t isEndInstruction(const uint8_t *step) {
  return step[0] == (uint8_t)((ITM_END >> 8) | 0x80) && step[1] == (uint8_t)(ITM_END & 0xff);
}

static void updateCurrentProgramPointers(void) {
  if(currentProgramNumber == 0 || currentProgramNumber > numberOfPrograms) {
    beginOfCurrentProgram = beginOfProgramMemory;
    endOfCurrentProgram = firstFreeProgramByte + 2;
  }
  else {
    beginOfCurrentProgram = programs[currentProgramNumber - 1].start;
    endOfCurrentProgram = programs[currentProgramNumber - 1].end;
  }
  currentStep = beginOfCurrentProgram;
  firstDisplayedStep = beginOfCurrentProgram;
}

static void rebuildPrograms(void) {
  uint8_t *cursor;
  uint8_t *limit = fakeRam + sizeof(fakeRam);

  numberOfPrograms = 0;
  memset(programs, 0, sizeof(programs));

  if(beginOfProgramMemory == NULL) {
    return;
  }

  cursor = beginOfProgramMemory;
  while(cursor + 1 < limit) {
    if(cursor[0] == 0xffu && cursor[1] == 0xffu) {
      break;
    }

    programs[numberOfPrograms].start = cursor;
    while(cursor + 1 < limit) {
      if(cursor[0] == 0xffu && cursor[1] == 0xffu) {
        programs[numberOfPrograms].end = cursor + 2;
        numberOfPrograms++;
        updateCurrentProgramPointers();
        return;
      }
      if(isEndInstruction(cursor)) {
        programs[numberOfPrograms].end = cursor + 2;
        numberOfPrograms++;
        cursor += 2;
        break;
      }
      cursor++;
    }
  }

  updateCurrentProgramPointers();
}

static void appendSaved(const char *text) {
  size_t len = strlen(text);

  if(savedFileSize + len >= sizeof(savedFile)) {
    len = sizeof(savedFile) - savedFileSize - 1;
  }
  memcpy(savedFile + savedFileSize, text, len);
  savedFileSize += len;
  savedFile[savedFileSize] = 0;
}

void resizeProgramMemory(uint16_t newSizeInBlocks) {
  uint16_t currentSizeInBlocks = RAM_SIZE_IN_BLOCKS - z47_program_serialization_runtime_to_c47_mem_ptr(beginOfProgramMemory);
  size_t bytesToMove = TO_BYTES(currentSizeInBlocks < newSizeInBlocks ? currentSizeInBlocks : newSizeInBlocks);
  uint8_t *newBeginOfProgramMemory = fakeRam + TO_BYTES(RAM_SIZE_IN_BLOCKS - newSizeInBlocks);
  ptrdiff_t delta = newBeginOfProgramMemory - beginOfProgramMemory;

  if(newBeginOfProgramMemory == beginOfProgramMemory) {
    return;
  }

  memmove(newBeginOfProgramMemory, beginOfProgramMemory, bytesToMove);
  beginOfProgramMemory = newBeginOfProgramMemory;
  firstFreeProgramByte += delta;
}

bool_t z47_program_serialization_runtime_check_power(void) {
  return powerBlocked;
}

bool_t z47_program_serialization_runtime_select_program(uint16_t label) {
  uint16_t index;

  if(label == 0) {
    updateCurrentProgramPointers();
    return true;
  }

  for(index = 0; index < labelCount; index++) {
    if(labels[index].label == label) {
      currentProgramNumber = labels[index].program_number;
      updateCurrentProgramPointers();
      return true;
    }
  }

  return false;
}

int z47_program_serialization_runtime_open_save_program(void) {
  activeFile = activeFileNone;
  if(saveOpenResult != FILE_OK) {
    return saveOpenResult;
  }
  savedFileSize = 0;
  savedFile[0] = 0;
  activeFile = activeFileSave;
  return FILE_OK;
}

int z47_program_serialization_runtime_open_load_program(void) {
  activeFile = activeFileNone;
  if(loadOpenResult != FILE_OK) {
    return loadOpenResult;
  }
  loadFileOffset = 0;
  activeFile = activeFileLoad;
  return FILE_OK;
}

void z47_program_serialization_runtime_write_literal(const char *text) {
  if(activeFile == activeFileSave) {
    appendSaved(text);
  }
}

void z47_program_serialization_runtime_write_u32_line(uint32_t value) {
  char line[64];

  sprintf(line, "%u\n", (unsigned)value);
  z47_program_serialization_runtime_write_literal(line);
}

void z47_program_serialization_runtime_write_u8_line(uint8_t value) {
  char line[32];

  sprintf(line, "%u\n", (unsigned)value);
  z47_program_serialization_runtime_write_literal(line);
}

void z47_program_serialization_runtime_read_line(char *buffer) {
  size_t index = 0;

  if(activeFile != activeFileLoad) {
    buffer[0] = 0;
    return;
  }

  while(loadFileOffset < loadFileSize && loadFile[loadFileOffset] != '\n') {
    buffer[index++] = loadFile[loadFileOffset++];
  }
  if(loadFileOffset < loadFileSize && loadFile[loadFileOffset] == '\n') {
    loadFileOffset++;
  }
  buffer[index] = 0;
}

void z47_program_serialization_runtime_close_file(void) {
  activeFile = activeFileNone;
}

void z47_program_serialization_runtime_display_write_error(void) {
  lastErrorKind = 1;
}

void z47_program_serialization_runtime_display_read_error(void) {
  lastErrorKind = 2;
}

void z47_program_serialization_runtime_show_warning(const char *message) {
  warningCount++;
  strncpy(lastWarning, message, sizeof(lastWarning) - 1);
  lastWarning[sizeof(lastWarning) - 1] = 0;
}

void z47_program_serialization_runtime_scan_labels_and_programs(void) {
  scanLabelsCalls++;
  rebuildPrograms();
}

void z47_program_serialization_runtime_go_to_last_program(void) {
  goToLastProgramCalls++;
  if(numberOfPrograms > 0) {
    currentProgramNumber = numberOfPrograms;
    currentLocalStepNumber = 1;
    updateCurrentProgramPointers();
  }
}

bool_t z47_program_serialization_runtime_is_at_end_of_program(const uint8_t *step) {
  return isEndInstruction(step);
}

uint16_t z47_program_serialization_runtime_get_ram_size_in_blocks(void) {
  return RAM_SIZE_IN_BLOCKS;
}

uint16_t z47_program_serialization_runtime_to_c47_mem_ptr(const uint8_t *memPtr) {
  return (uint16_t)((memPtr - fakeRam) >> BPB);
}

uint32_t z47_program_serialization_runtime_parse_u32_line(const char *line) {
  return (uint32_t)strtoul(line, NULL, 10);
}

uint8_t z47_program_serialization_runtime_parse_u8_line(const char *line) {
  return (uint8_t)strtoul(line, NULL, 10);
}

bool_t z47_program_serialization_runtime_line_equals(const char *line, const char *expected) {
  return strcmp(line, expected) == 0;
}

void programSerializationParityReset(void) {
  memset(fakeRam, 0, sizeof(fakeRam));
  memset(loadFile, 0, sizeof(loadFile));
  memset(savedFile, 0, sizeof(savedFile));
  memset(lastWarning, 0, sizeof(lastWarning));
  memset(labels, 0, sizeof(labels));
  loadFileSize = 0;
  loadFileOffset = 0;
  savedFileSize = 0;
  warningCount = 0;
  lastErrorKind = 0;
  scanLabelsCalls = 0;
  goToLastProgramCalls = 0;
  saveOpenResult = FILE_OK;
  loadOpenResult = FILE_OK;
  powerBlocked = false;
  activeFile = activeFileNone;
  labelCount = 0;
  beginOfProgramMemory = fakeRam + TO_BYTES(RAM_SIZE_IN_BLOCKS - 1);
  firstFreeProgramByte = beginOfProgramMemory;
  beginOfProgramMemory[0] = 0xffu;
  beginOfProgramMemory[1] = 0xffu;
  freeProgramBytes = BYTES_PER_BLOCK - 2;
  currentLocalStepNumber = 1;
  currentProgramNumber = 1;
  temporaryInformation = 0;
  rebuildPrograms();
}

void programSerializationParitySeedPrograms(const uint8_t *image, uint32_t imageSize, uint16_t beginBlock, uint16_t currentProgram, uint16_t currentLocalStep) {
  memset(fakeRam, 0, sizeof(fakeRam));
  beginOfProgramMemory = fakeRam + TO_BYTES(beginBlock);
  memcpy(beginOfProgramMemory, image, imageSize);
  firstFreeProgramByte = beginOfProgramMemory + imageSize - 2;
  freeProgramBytes = (uint16_t)(TO_BYTES(RAM_SIZE_IN_BLOCKS - beginBlock) - imageSize);
  currentProgramNumber = currentProgram;
  currentLocalStepNumber = currentLocalStep;
  rebuildPrograms();
}

void programSerializationParitySetLabel(uint16_t label, uint16_t programNumber) {
  if(labelCount < (uint16_t)(sizeof(labels) / sizeof(labels[0]))) {
    labels[labelCount].label = label;
    labels[labelCount].program_number = programNumber;
    labelCount++;
  }
}

void programSerializationParitySetLoadFile(const char *contents) {
  loadFileSize = strlen(contents);
  memcpy(loadFile, contents, loadFileSize + 1);
  loadFileOffset = 0;
}

void programSerializationParitySetFileOpenResults(int saveResult, int loadResult) {
  saveOpenResult = saveResult;
  loadOpenResult = loadResult;
}

void programSerializationParitySetPowerBlocked(bool_t blocked) {
  powerBlocked = blocked;
}

void programSerializationParityCapture(program_serialization_snapshot_t *snapshot) {
  uint32_t imageSize = 0;

  memset(snapshot, 0, sizeof(*snapshot));
  snapshot->current_local_step_number = currentLocalStepNumber;
  snapshot->current_program_number = currentProgramNumber;
  snapshot->number_of_programs = numberOfPrograms;
  snapshot->free_program_bytes = freeProgramBytes;
  snapshot->begin_of_program_block = z47_program_serialization_runtime_to_c47_mem_ptr(beginOfProgramMemory);
  snapshot->first_free_program_offset = (uint32_t)(firstFreeProgramByte - beginOfProgramMemory);
  snapshot->begin_of_current_program_offset = (uint32_t)(beginOfCurrentProgram - beginOfProgramMemory);
  snapshot->end_of_current_program_offset = (uint32_t)(endOfCurrentProgram - beginOfProgramMemory);
  snapshot->current_step_offset = (uint32_t)(currentStep - beginOfProgramMemory);
  snapshot->first_displayed_step_offset = (uint32_t)(firstDisplayedStep - beginOfProgramMemory);
  snapshot->temporary_information = temporaryInformation;
  snapshot->warning_count = warningCount;
  snapshot->last_error_kind = lastErrorKind;
  snapshot->scan_labels_calls = scanLabelsCalls;
  snapshot->go_to_last_program_calls = goToLastProgramCalls;
  snapshot->saved_file_size = savedFileSize;
  memcpy(snapshot->saved_file, savedFile, savedFileSize + 1);
  strncpy(snapshot->last_warning, lastWarning, sizeof(snapshot->last_warning) - 1);
  imageSize = (uint32_t)((firstFreeProgramByte + 2) - beginOfProgramMemory);
  if(imageSize > MAX_PROGRAM_PARITY_PROGRAM_IMAGE_BYTES) {
    imageSize = MAX_PROGRAM_PARITY_PROGRAM_IMAGE_BYTES;
  }
  snapshot->program_image_size = imageSize;
  memcpy(snapshot->program_image, beginOfProgramMemory, imageSize);
}