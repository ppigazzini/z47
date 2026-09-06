// SPDX-License-Identifier: GPL-3.0-only
//
// The environment both sides of the program save/load parity lane run in.
//
// One copy of program memory, one file emulation, one step grammar, shared by
// c43's saveRestorePrograms.c (compiled as the oracle) and by the Zig owner. A
// snapshot difference can then only come from the serialization logic itself.
//
// Program memory is REAL here, not modelled: `ram` is a backing array and the
// program pointers point into it, because `_addSpaceAfterPrograms` does live
// pointer arithmetic against `ram` through TO_C47MEMPTR and both implementations
// have to land on the same addresses.

#include "program_serialization_test_runtime.h"

#define PROGRAM_AREA_BYTES 2048u

// Not the product's RAM_SIZE_IN_BLOCKS (65534, a quarter-megabyte): the lane only
// needs a program area, and TO_C47MEMPTR is relative to `ram` either way. The
// SIZE that matters for parity is the one both sides compute from, which is why
// getRamSizeInBlocks below is the single source for it.
#define HARNESS_RAM_BLOCKS 1024u

static uint32_t ramStorage[HARNESS_RAM_BLOCKS];
uint32_t *ram = ramStorage;

uint8_t *beginOfProgramMemory = NULL;
uint8_t *firstFreeProgramByte = NULL;
uint8_t *beginOfCurrentProgram = NULL;
uint8_t *endOfCurrentProgram = NULL;
uint8_t *firstDisplayedStep = NULL;
uint8_t *currentStep = NULL;
uint16_t freeProgramBytes = 0;
uint16_t firstDisplayedLocalStepNumber = 0;
uint16_t currentLocalStepNumber = 0;
uint16_t currentProgramNumber = 0;
uint16_t numberOfPrograms = 0;
uint16_t numberOfLabels = 0;
bool_t programListEnd = false;
bool_t lastProgramListEnd = false;
tamState_t tam;
int16_t dynamicMenuItem = 0;
uint8_t temporaryInformation = 0;

// Indexed by `label - FIRST_LABEL` on both sides, so it has to span the whole
// global-label range rather than the handful a case sets.
static labelList_t labelListStorage[LAST_LABEL - FIRST_LABEL + 1];
static programList_t programListStorage[8];
labelList_t *labelList = labelListStorage;
programList_t *programList = programListStorage;

static char tmpStringStorage[TMP_STR_LENGTH];
static char tmpStringLabelStorage[256];
static char aimBufferStorage[AIM_BUFFER_LENGTH];
static char errorMessageStorage[256];
char *tmpString = tmpStringStorage;
char *tmpStringLabelOrVariableName = tmpStringLabelStorage;
char *aimBuffer = aimBufferStorage;
char *errorMessage = errorMessageStorage;

// Zero-initialised, then set per case. Both implementations index this same
// table, so it is shared input rather than a second reference (see c47.h).
item_t indexOfItems[LAST_ITEM + 1];

// --- file emulation --------------------------------------------------------

static char saveBuffer[MAX_PROGRAM_PARITY_FILE_BYTES];
static size_t saveBufferSize = 0;
static char loadBuffer[MAX_PROGRAM_PARITY_FILE_BYTES];
static size_t loadBufferSize = 0;
static size_t loadCursor = 0;
static int saveOpenResult = FILE_OK;
static int loadOpenResult = FILE_OK;
static bool_t fileOpen = false;
static bool_t fileForWriting = false;

static uint8_t lastErrorKind = 0;
static uint8_t warningCount = 0;
static char lastWarning[256];
static uint32_t scanLabelsCalls = 0;
static uint32_t goToLastProgramCalls = 0;
static uint32_t freeRamMemoryBytes = 0;
static uint16_t namedLabelProgramNumber = 0;

int ioFileOpen(ioFilePath_t path, ioFileMode_t mode) {
  int result;
  (void)path;
  if(mode == ioModeWrite) {
    result = saveOpenResult;
    if(result == FILE_OK) {
      saveBufferSize = 0;
      saveBuffer[0] = 0;
      fileOpen = true;
      fileForWriting = true;
    }
    return result;
  }

  result = loadOpenResult;
  if(result == FILE_OK) {
    loadCursor = 0;
    fileOpen = true;
    fileForWriting = false;
  }
  return result;
}

void ioFileWrite(const void *buffer, uint32_t size) {
  if(!fileOpen || !fileForWriting || saveBufferSize + size >= sizeof(saveBuffer)) {
    return;
  }
  memcpy(saveBuffer + saveBufferSize, buffer, size);
  saveBufferSize += size;
  saveBuffer[saveBufferSize] = 0;
}

void ioFileClose(void) {
  fileOpen = false;
}

void ioFileSeek(uint32_t position) {
  loadCursor = position;
}

void readLine(char *line, size_t maxLen) {
  size_t length = 0;

  while(loadCursor < loadBufferSize && loadBuffer[loadCursor] != '\n') {
    if(length + 1 < maxLen) {
      line[length++] = loadBuffer[loadCursor];
    }
    loadCursor++;
  }
  if(loadCursor < loadBufferSize) {
    loadCursor++; // consume the newline
  }
  line[length] = 0;
}

// --- parsing ---------------------------------------------------------------

uint32_t stringToUint32(const char *str) {
  uint32_t value = 0;
  while(*str >= '0' && *str <= '9') {
    value = value * 10u + (uint32_t)(*str++ - '0');
  }
  return value;
}

uint8_t stringToUint8(const char *str) {
  return (uint8_t)stringToUint32(str);
}

int32_t stringByteLength(const char *str) {
  return (int32_t)strlen(str);
}

void stringCopy(char *dest, const char *source) {
  strcpy(dest, source);
}

void *xcopy(void *dest, const void *source, uint32_t n) {
  return memcpy(dest, source, n);
}

// --- the step grammar ------------------------------------------------------
//
// A faithful reimplementation would be a second copy of nextStep.c, which is the
// defect this report is about. These are deliberately SIMPLE and SHARED: the
// lane asks whether the two screening passes agree given the same grammar, not
// what c43's grammar is -- the item-table seam gates own that question.

int16_t literalTailBytes(uint8_t literalType) {
  switch(literalType) {
    case 0: return 0;
    case 1: return 1;
    case 2: return PARAM_TAIL_LENGTH_PREFIXED;
    case 3: return PARAM_TAIL_BASE_LENGTH_PREFIXED;
    default: return PARAM_TAIL_INVALID;
  }
}

int16_t paramTailBytes(uint16_t paramMode, uint16_t op, uint8_t opParam) {
  (void)op;
  (void)opParam;
  if(paramMode == PARAM_DECLARE_LABEL) {
    return PARAM_TAIL_LENGTH_PREFIXED;
  }
  return 0;
}

// --- program area ----------------------------------------------------------

bool_t isAtEndOfProgram(const uint8_t *step) {
  return step[0] == ((ITM_END >> 8) | 0x80) && step[1] == (ITM_END & 0xff);
}

uint8_t boundProgramNameLength(const uint8_t *nameStart, uint8_t claimed) {
  if(nameStart >= firstFreeProgramByte) {
    return 0;
  }
  if(claimed > (uint8_t)(firstFreeProgramByte - nameStart)) {
    return (uint8_t)(firstFreeProgramByte - nameStart);
  }
  return claimed;
}

// The program area is a fixed slab inside `ram`, so growing it cannot move it.
// Both implementations therefore see the same pointers before and after -- a
// real relocation would have to be modelled identically on both sides to mean
// anything, and modelling it here would put the allocator's behaviour back into
// hand-written harness code.
void resizeProgramMemory(uint16_t newSizeInBlocks) {
  (void)newSizeInBlocks;
}

uint32_t getFreeRamMemory(void) {
  return freeRamMemoryBytes;
}

// --- calculator surface ----------------------------------------------------

void displayCalcErrorMessage(uint8_t errorCode, calcRegister_t errMessageRegisterLine, calcRegister_t disUsedCanBeRemoved) {
  (void)errMessageRegisterLine;
  (void)disUsedCanBeRemoved;
  lastErrorKind = errorCode;
}

void moreInfoOnError(const char *m1, const char *m2, const char *m3, const char *m4) {
  (void)m1;
  (void)m2;
  (void)m3;
  (void)m4;
}

void show_warning(char *string) {
  warningCount++;
  strncpy(lastWarning, string, sizeof(lastWarning) - 1);
  lastWarning[sizeof(lastWarning) - 1] = 0;
}

void scanLabelsAndPrograms(void) {
  scanLabelsCalls++;
}

void goToGlobalStep(int32_t step) {
  (void)step;
  goToLastProgramCalls++;
}

void fnGoto(uint16_t label) {
  (void)label;
  currentProgramNumber = namedLabelProgramNumber;
}

uint16_t findNamedLabel(const char *labelName, uint8_t labelType) {
  (void)labelName;
  (void)labelType;
  return 0;
}

// --- RTF/text export surface (compiled, never driven by this lane) ----------

uint16_t getNumberOfSteps(void) {
  return 0;
}

void defineFirstDisplayedStep(void) {
}

// _restoreEditorPosition follows the step with this; the lane drives no program bounds, so it has nothing to recompute.
void defineCurrentProgramFromCurrentStep(void) {
}

uint8_t *findNextStep(uint8_t *step) {
  return step;
}

void decodeOneStep_XPORT(const uint8_t *step) {
  (void)step;
  tmpString[0] = 0;
}

void stringToASCII(const char *str, char *ascii) {
  strcpy(ascii, str);
}

void stringToRTF(const char *str, char *rtf) {
  strcpy(rtf, str);
}

// The IR-printer arm of fnPExport. Compiled, never driven here.
int16_t lastFunc = 0;

uint32_t _getProgramSize(void) {
  return 0;
}

bool_t getSystemFlag(int32_t sf) {
  (void)sf;
  return false;
}

void printProgram(uint16_t mode, uint16_t unused) {
  (void)mode;
  (void)unused;
}

// --- the calculator around the STRUCT set -----------------------------------
// The lane drives the file writers, not the structures. calcMode is CM_NORMAL so
// the three writers are never on the editor's refusal path, and no program the
// lane builds holds a structure: every predicate below answers for a program that
// has none, which is what makes the two implementations comparable. Both sides
// read the SAME stubs, so a case that did carry a structure would still be
// comparing c43's walk against the Zig owner's.
uint8_t calcMode = CM_NORMAL;
uint8_t lastErrorCode = ERROR_NONE;

bool_t checkOpCodeOfStep(const uint8_t *step, uint16_t op) {
  if(step == NULL) {
    return false;
  }
  if(op < 128) {
    return step[0] == op;
  }
  return step[0] == ((op >> 8) | 0x80) && step[1] == (op & 0xff);
}

void fnValid(uint16_t unusedButMandatoryParameter) {
  (void)unusedButMandatoryParameter;
}

bool_t structProgramHasUnnumbered(void) {
  return false;
}

bool_t structDisplayOutdent(uint8_t *step) {
  (void)step;
  return false;
}

bool_t structStepOpensIndent(uint8_t *step) {
  (void)step;
  return false;
}

bool_t structStepClosesIndent(uint8_t *step) {
  (void)step;
  return false;
}

// --- seeding and capture ---------------------------------------------------

void programSerializationParityReset(void) {
  memset(ramStorage, 0, sizeof(ramStorage));
  memset(indexOfItems, 0, sizeof(indexOfItems));
  memset(&tam, 0, sizeof(tam));
  memset(labelListStorage, 0, sizeof(labelListStorage));
  memset(programListStorage, 0, sizeof(programListStorage));
  saveBufferSize = 0;
  saveBuffer[0] = 0;
  loadBufferSize = 0;
  loadBuffer[0] = 0;
  loadCursor = 0;
  saveOpenResult = FILE_OK;
  loadOpenResult = FILE_OK;
  fileOpen = false;
  fileForWriting = false;
  lastErrorKind = 0;
  warningCount = 0;
  lastWarning[0] = 0;
  scanLabelsCalls = 0;
  goToLastProgramCalls = 0;
  freeRamMemoryBytes = PROGRAM_AREA_BYTES;
  namedLabelProgramNumber = 0;
  temporaryInformation = 0;
  dynamicMenuItem = 0;
  numberOfLabels = 0;
  numberOfPrograms = 0;
  currentProgramNumber = 0;
  currentLocalStepNumber = 0;
  firstDisplayedLocalStepNumber = 0;
  programListEnd = false;
  lastProgramListEnd = false;
  tmpString[0] = 0;
  tmpStringLabelOrVariableName[0] = 0;
  aimBuffer[0] = 0;
  errorMessage[0] = 0;
  beginOfProgramMemory = (uint8_t *)ramStorage;
  firstFreeProgramByte = beginOfProgramMemory;
  beginOfCurrentProgram = beginOfProgramMemory;
  endOfCurrentProgram = beginOfProgramMemory;
  currentStep = beginOfProgramMemory;
  firstDisplayedStep = beginOfProgramMemory;
  freeProgramBytes = 0;
}

void programSerializationParitySeedPrograms(const uint8_t *image,
                                            uint32_t imageSize,
                                            uint16_t beginBlock,
                                            uint16_t currentProgram,
                                            uint16_t currentLocalStep) {
  beginOfProgramMemory = (uint8_t *)(ramStorage + beginBlock);
  memcpy(beginOfProgramMemory, image, imageSize);
  firstFreeProgramByte = beginOfProgramMemory + imageSize - 2;
  freeProgramBytes = (uint16_t)(PROGRAM_AREA_BYTES - imageSize);
  beginOfCurrentProgram = beginOfProgramMemory;
  endOfCurrentProgram = beginOfProgramMemory + imageSize;
  currentStep = beginOfProgramMemory;
  firstDisplayedStep = beginOfProgramMemory;
  currentProgramNumber = currentProgram;
  currentLocalStepNumber = currentLocalStep;
  numberOfPrograms = 1;
  programList[0].step = 1;
}

void programSerializationParitySetLabel(uint16_t label, uint16_t programNumber) {
  // The name is a 1-byte-length string, and it lives BELOW the program area so
  // boundProgramNameLength's `nameStart < firstFreeProgramByte` test resolves the
  // same way for both implementations.
  uint8_t *name = (uint8_t *)ramStorage;
  name[0] = 3;
  name[1] = 'A';
  name[2] = 'B';
  name[3] = 'C';

  namedLabelProgramNumber = programNumber;
  numberOfLabels = 1;
  if(label >= FIRST_LABEL && label <= LAST_LABEL) {
    labelList[label - FIRST_LABEL].program = programNumber;
    labelList[label - FIRST_LABEL].step = 1;
    labelList[label - FIRST_LABEL].labelPointer = name;
  }
  labelList[0].program = programNumber;
  labelList[0].step = 1;
  labelList[0].labelPointer = name;
}

void programSerializationParitySetLoadFile(const char *contents) {
  loadBufferSize = strlen(contents);
  if(loadBufferSize >= sizeof(loadBuffer)) {
    loadBufferSize = sizeof(loadBuffer) - 1;
  }
  memcpy(loadBuffer, contents, loadBufferSize);
  loadBuffer[loadBufferSize] = 0;
  loadCursor = 0;
}

void programSerializationParitySetFileOpenResults(int saveResult, int loadResult) {
  saveOpenResult = saveResult;
  loadOpenResult = loadResult;
}

void programSerializationParitySetFreeRamMemory(uint32_t bytes) {
  freeRamMemoryBytes = bytes;
}

void programSerializationParitySetItemStatus(uint16_t op, uint16_t status) {
  if(op <= LAST_ITEM) {
    indexOfItems[op].status = status;
  }
}

void programSerializationParityCapture(program_serialization_snapshot_t *snapshot) {
  memset(snapshot, 0, sizeof(*snapshot));
  snapshot->current_local_step_number = currentLocalStepNumber;
  snapshot->current_program_number = currentProgramNumber;
  snapshot->number_of_programs = numberOfPrograms;
  snapshot->free_program_bytes = freeProgramBytes;
  snapshot->begin_of_program_block = (uint16_t)((uint32_t *)beginOfProgramMemory - ramStorage);
  snapshot->first_free_program_offset = (uint32_t)(firstFreeProgramByte - beginOfProgramMemory);
  snapshot->begin_of_current_program_offset = (uint32_t)(beginOfCurrentProgram - beginOfProgramMemory);
  snapshot->end_of_current_program_offset = (uint32_t)(endOfCurrentProgram - beginOfProgramMemory);
  snapshot->current_step_offset = (uint32_t)(currentStep - beginOfProgramMemory);
  snapshot->first_displayed_step_offset = (uint32_t)(firstDisplayedStep - beginOfProgramMemory);
  snapshot->temporary_information = temporaryInformation;
  snapshot->dynamic_menu_item = dynamicMenuItem;
  snapshot->warning_count = warningCount;
  snapshot->last_error_kind = lastErrorKind;
  snapshot->scan_labels_calls = scanLabelsCalls;
  snapshot->go_to_last_program_calls = goToLastProgramCalls;
  snapshot->saved_file_size = saveBufferSize;
  memcpy(snapshot->saved_file, saveBuffer, saveBufferSize);
  strncpy(snapshot->last_warning, lastWarning, sizeof(snapshot->last_warning) - 1);
  snapshot->program_image_size = MAX_PROGRAM_PARITY_PROGRAM_IMAGE_BYTES;
  memcpy(snapshot->program_image, beginOfProgramMemory, MAX_PROGRAM_PARITY_PROGRAM_IMAGE_BYTES);
}
