// SPDX-License-Identifier: GPL-3.0-only
//
// Drives c43's saveRestorePrograms.c (compiled as oracle_*) and the Zig owner
// through the same seeded environment and byte-compares the result.

#include <stdio.h>
#include <string.h>

#include "program_serialization_test_runtime.h"

typedef void (*programEntry_t)(uint16_t);

static const uint8_t defaultImage[] = {0x33u, 0x44u, 0xffu, 0xffu};

static int reportMismatch(const char *caseName,
                          const program_serialization_snapshot_t *expected,
                          const program_serialization_snapshot_t *actual) {
  if(memcmp(expected, actual, sizeof(*expected)) == 0) {
    return 0;
  }

  fprintf(stderr, "%s mismatch\n", caseName);
  if(expected->saved_file_size != actual->saved_file_size ||
     memcmp(expected->saved_file, actual->saved_file, expected->saved_file_size) != 0) {
    fprintf(stderr, "  saved file\n  expected(%zu):\n%s\n  actual(%zu):\n%s\n",
            expected->saved_file_size, expected->saved_file, actual->saved_file_size, actual->saved_file);
  }
  if(expected->program_image_size != actual->program_image_size ||
     memcmp(expected->program_image, actual->program_image, expected->program_image_size) != 0) {
    fprintf(stderr, "  program image\n");
  }
  if(strcmp(expected->last_warning, actual->last_warning) != 0) {
    fprintf(stderr, "  warning\n  expected: %s\n  actual:   %s\n", expected->last_warning, actual->last_warning);
  }
  if(expected->temporary_information != actual->temporary_information) {
    fprintf(stderr, "  temporaryInformation expected %u actual %u\n",
            expected->temporary_information, actual->temporary_information);
  }
  if(expected->last_error_kind != actual->last_error_kind) {
    fprintf(stderr, "  error expected %u actual %u\n", expected->last_error_kind, actual->last_error_kind);
  }
  if(expected->dynamic_menu_item != actual->dynamic_menu_item) {
    fprintf(stderr, "  dynamicMenuItem expected %d actual %d\n",
            expected->dynamic_menu_item, actual->dynamic_menu_item);
  }
  if(expected->free_program_bytes != actual->free_program_bytes) {
    fprintf(stderr, "  freeProgramBytes expected %u actual %u\n",
            expected->free_program_bytes, actual->free_program_bytes);
  }
  return 1;
}

// One scenario, described by what the environment should look like before the
// entry point runs. Both sides get an identical setup because the SAME function
// builds it twice.
typedef struct {
  const char *name;
  const uint8_t *image;
  uint32_t imageSize;
  uint16_t beginBlock;
  uint16_t currentProgram;
  uint16_t currentLocalStep;
  uint16_t label;
  uint16_t labelProgramNumber;
  bool_t hasLabel;
  const char *loadFile;
  int saveOpenResult;
  int loadOpenResult;
  uint32_t freeRamMemory;
  uint16_t itemOp;
  uint16_t itemStatus;
  bool_t hasItem;
} programCase_t;

static void applyCase(const programCase_t *c) {
  programSerializationParityReset();
  programSerializationParitySetFileOpenResults(c->saveOpenResult, c->loadOpenResult);
  programSerializationParitySeedPrograms(c->image, c->imageSize, c->beginBlock, c->currentProgram, c->currentLocalStep);
  if(c->hasLabel) {
    programSerializationParitySetLabel(c->label, c->labelProgramNumber);
  }
  if(c->loadFile != NULL) {
    programSerializationParitySetLoadFile(c->loadFile);
  }
  programSerializationParitySetFreeRamMemory(c->freeRamMemory);
  if(c->hasItem) {
    programSerializationParitySetItemStatus(c->itemOp, c->itemStatus);
  }
}

static int runCase(const programCase_t *c, programEntry_t oracleFn, programEntry_t zigFn, uint16_t argument) {
  program_serialization_snapshot_t expected;
  program_serialization_snapshot_t actual;

  applyCase(c);
  oracleFn(argument);
  programSerializationParityCapture(&expected);

  applyCase(c);
  zigFn(argument);
  programSerializationParityCapture(&actual);

  return reportMismatch(c->name, &expected, &actual);
}

#define BASE_CASE(caseName)                  \
  {                                          \
    .name = (caseName),                      \
    .image = defaultImage,                   \
    .imageSize = sizeof(defaultImage),       \
    .beginBlock = 8,                         \
    .currentProgram = 1,                     \
    .currentLocalStep = 1,                   \
    .saveOpenResult = FILE_OK,               \
    .loadOpenResult = FILE_OK,               \
    .freeRamMemory = 1024,                   \
  }

static const char validProgramFile[] =
    "PROGRAM_FILE_FORMAT\n"
    "0\n"
    "C47_program_file_version\n"
    "1\n"
    "PROGRAM\n"
    "2\n"
    "7\n"
    "8\n";

int main(void) {
  int failures = 0;

  // --- save --------------------------------------------------------------
  {
    programCase_t c = BASE_CASE("save current (last) program");
    failures += runCase(&c, oracle_fnSaveProgram, fnSaveProgram, 0);
  }
  {
    static const uint8_t image[] = {0x11u, (uint8_t)((ITM_END >> 8) | 0x80), (uint8_t)(ITM_END & 0xff), 0x22u, 0xffu, 0xffu};
    programCase_t c = BASE_CASE("save selected labelled program");
    c.image = image;
    c.imageSize = sizeof(image);
    c.currentProgram = 2;
    c.currentLocalStep = 9;
    c.hasLabel = true;
    c.label = 2242;
    c.labelProgramNumber = 1;
    failures += runCase(&c, oracle_fnSaveProgram, fnSaveProgram, 2242);
  }
  {
    // A label outside FIRST_LABEL..LAST_LABEL is out of range: c43 raises the
    // error and never opens the file.
    programCase_t c = BASE_CASE("save with an out-of-range label");
    failures += runCase(&c, oracle_fnSaveProgram, fnSaveProgram, 42);
  }
  {
    programCase_t c = BASE_CASE("save when the file picker is cancelled");
    c.saveOpenResult = FILE_CANCEL;
    failures += runCase(&c, oracle_fnSaveProgram, fnSaveProgram, 0);
  }
  {
    programCase_t c = BASE_CASE("save when the file cannot be opened");
    c.saveOpenResult = 0;
    failures += runCase(&c, oracle_fnSaveProgram, fnSaveProgram, 0);
  }
  {
    // Selecting a label moves currentProgramNumber, and c43 puts it back only
    // after a COMPLETED write. These two cases are what tell a `defer`-style
    // restore-on-every-path apart from c43's restore-at-the-end.
    programCase_t c = BASE_CASE("save cancelled after selecting a label");
    c.saveOpenResult = FILE_CANCEL;
    c.hasLabel = true;
    c.label = 2242;
    c.labelProgramNumber = 7;
    failures += runCase(&c, oracle_fnSaveProgram, fnSaveProgram, 2242);
  }
  {
    programCase_t c = BASE_CASE("save failing to open after selecting a label");
    c.saveOpenResult = 0;
    c.hasLabel = true;
    c.label = 2242;
    c.labelProgramNumber = 7;
    failures += runCase(&c, oracle_fnSaveProgram, fnSaveProgram, 2242);
  }

  // --- load --------------------------------------------------------------
  {
    programCase_t c = BASE_CASE("load into an empty program area");
    c.loadFile = validProgramFile;
    failures += runCase(&c, oracle_fnLoadProgram, fnLoadProgram, 0);
  }
  {
    static const uint8_t image[] = {0x01u, 0x02u, 0xffu, 0xffu};
    programCase_t c = BASE_CASE("load needing an inserted .END. separator");
    c.image = image;
    c.imageSize = sizeof(image);
    c.loadFile = validProgramFile;
    failures += runCase(&c, oracle_fnLoadProgram, fnLoadProgram, 0);
  }
  {
    programCase_t c = BASE_CASE("load when the file picker is cancelled");
    c.loadOpenResult = FILE_CANCEL;
    c.loadFile = validProgramFile;
    failures += runCase(&c, oracle_fnLoadProgram, fnLoadProgram, 0);
  }
  {
    programCase_t c = BASE_CASE("load when the file cannot be opened");
    c.loadOpenResult = 0;
    c.loadFile = validProgramFile;
    failures += runCase(&c, oracle_fnLoadProgram, fnLoadProgram, 0);
  }
  {
    programCase_t c = BASE_CASE("load a file with no PROGRAM_FILE_FORMAT header");
    c.loadFile = "NOT_A_C47_PROGRAM\n";
    failures += runCase(&c, oracle_fnLoadProgram, fnLoadProgram, 0);
  }
  {
    programCase_t c = BASE_CASE("load a file with an unknown version key");
    c.loadFile =
        "PROGRAM_FILE_FORMAT\n"
        "0\n"
        "SOMETHING_ELSE\n"
        "1\n"
        "PROGRAM\n"
        "2\n"
        "7\n"
        "8\n";
    failures += runCase(&c, oracle_fnLoadProgram, fnLoadProgram, 0);
  }
  {
    // The WP43 header is accepted with a warning rather than refused.
    programCase_t c = BASE_CASE("load a WP43 program file");
    c.loadFile =
        "PROGRAM_FILE_FORMAT\n"
        "0\n"
        "WP43_program_file_version\n"
        "1\n"
        "PROGRAM\n"
        "2\n"
        "7\n"
        "8\n";
    failures += runCase(&c, oracle_fnLoadProgram, fnLoadProgram, 0);
  }
  {
    programCase_t c = BASE_CASE("load a version older than the oldest compatible");
    c.loadFile =
        "PROGRAM_FILE_FORMAT\n"
        "0\n"
        "C47_program_file_version\n"
        "0\n"
        "PROGRAM\n"
        "2\n"
        "7\n"
        "8\n";
    failures += runCase(&c, oracle_fnLoadProgram, fnLoadProgram, 0);
  }
  {
    programCase_t c = BASE_CASE("load a file whose third key is not PROGRAM");
    c.loadFile =
        "PROGRAM_FILE_FORMAT\n"
        "0\n"
        "C47_program_file_version\n"
        "1\n"
        "NOT_PROGRAM\n"
        "2\n";
    failures += runCase(&c, oracle_fnLoadProgram, fnLoadProgram, 0);
  }
  {
    // The RAM bound: a declared size the program area cannot hold is refused
    // before anything is reserved. The frozen oracle had no such check at all.
    programCase_t c = BASE_CASE("load a program larger than free RAM");
    c.freeRamMemory = 0;
    c.loadFile =
        "PROGRAM_FILE_FORMAT\n"
        "0\n"
        "C47_program_file_version\n"
        "1\n"
        "PROGRAM\n"
        "60000\n";
    failures += runCase(&c, oracle_fnLoadProgram, fnLoadProgram, 0);
  }
  {
    // The other half of that bound: a declared size past UINT16_MAX would be
    // reserved by its low 16 bits and written in full.
    programCase_t c = BASE_CASE("load a program claiming more than UINT16_MAX bytes");
    c.freeRamMemory = 0xFFFFFFFFu;
    c.loadFile =
        "PROGRAM_FILE_FORMAT\n"
        "0\n"
        "C47_program_file_version\n"
        "1\n"
        "PROGRAM\n"
        "70000\n";
    failures += runCase(&c, oracle_fnLoadProgram, fnLoadProgram, 0);
  }

  // --- the pre-load screening pass ---------------------------------------
  //
  // None of these could be compared while the oracle was frozen: it
  // did not model the screen, and the Zig owner's screen was compiled out of the
  // parity build entirely.
  {
    // An opcode at or above LAST_ITEM is not a step; only a corrupt or crafted
    // file contains one, and it is refused rather than walked.
    programCase_t c = BASE_CASE("screen refuses a non-item opcode");
    c.loadFile =
        "PROGRAM_FILE_FORMAT\n"
        "0\n"
        "C47_program_file_version\n"
        "1\n"
        "PROGRAM\n"
        "2\n"
        "255\n"
        "254\n";
    failures += runCase(&c, oracle_fnLoadProgram, fnLoadProgram, 0);
  }
  {
    // A declared label longer than MAX_LABEL_NAME_LENGTH is the check the screen
    // exists for.
    programCase_t c = BASE_CASE("screen refuses an overlong declared label");
    c.hasItem = true;
    c.itemOp = 1;
    c.itemStatus = PARAM_DECLARE_LABEL << 9;
    c.loadFile =
        "PROGRAM_FILE_FORMAT\n"
        "0\n"
        "C47_program_file_version\n"
        "1\n"
        "PROGRAM\n"
        "4\n"
        "1\n"
        "0\n"
        "99\n"
        "65\n";
    failures += runCase(&c, oracle_fnLoadProgram, fnLoadProgram, 0);
  }
  {
    // The same shape with a legal length must NOT be refused, or the check would
    // be indistinguishable from refusing everything.
    programCase_t c = BASE_CASE("screen accepts a legal declared label");
    c.hasItem = true;
    c.itemOp = 1;
    c.itemStatus = PARAM_DECLARE_LABEL << 9;
    c.loadFile =
        "PROGRAM_FILE_FORMAT\n"
        "0\n"
        "C47_program_file_version\n"
        "1\n"
        "PROGRAM\n"
        "8\n"
        "1\n"
        "0\n"
        "5\n"
        "65\n"
        "66\n"
        "67\n"
        "68\n"
        "69\n";
    failures += runCase(&c, oracle_fnLoadProgram, fnLoadProgram, 0);
  }
  {
    // .END. inside the declared size ends the screen without refusing.
    programCase_t c = BASE_CASE("screen stops at .END. without refusing");
    c.loadFile =
        "PROGRAM_FILE_FORMAT\n"
        "0\n"
        "C47_program_file_version\n"
        "1\n"
        "PROGRAM\n"
        "2\n"
        "255\n"
        "255\n";
    failures += runCase(&c, oracle_fnLoadProgram, fnLoadProgram, 0);
  }

  if(failures != 0) {
    fprintf(stderr, "%d program serialization parity checks failed\n", failures);
    return 1;
  }

  puts("program serialization parity checks passed");
  return 0;
}
