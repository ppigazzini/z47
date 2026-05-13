// SPDX-License-Identifier: GPL-3.0-only

#include <stdio.h>
#include <string.h>

#include "program_serialization_test_runtime.h"

static int reportMismatch(const char *caseName,
                          const program_serialization_snapshot_t *expected,
                          const program_serialization_snapshot_t *actual) {
  if(memcmp(expected, actual, sizeof(*expected)) == 0) {
    return 0;
  }

  fprintf(stderr, "%s mismatch\n", caseName);
  if(expected->saved_file_size != actual->saved_file_size || memcmp(expected->saved_file, actual->saved_file, expected->saved_file_size > actual->saved_file_size ? expected->saved_file_size : actual->saved_file_size) != 0) {
    fprintf(stderr, "  saved file mismatch\nexpected:\n%s\nactual:\n%s\n", expected->saved_file, actual->saved_file);
  }
  if(expected->program_image_size != actual->program_image_size || memcmp(expected->program_image, actual->program_image, expected->program_image_size > actual->program_image_size ? expected->program_image_size : actual->program_image_size) != 0) {
    fprintf(stderr, "  program image mismatch\n");
  }
  if(strcmp(expected->last_warning, actual->last_warning) != 0) {
    fprintf(stderr, "  warning mismatch\nexpected: %s\nactual:   %s\n", expected->last_warning, actual->last_warning);
  }
  return 1;
}

static int runSaveCurrentLastProgramCase(void) {
  static const uint8_t image[] = { 0x10u, 0x20u, 0xffu, 0xffu };
  program_serialization_snapshot_t expected;
  program_serialization_snapshot_t actual;

  programSerializationParityReset();
  programSerializationParitySeedPrograms(image, sizeof(image), 120, 1, 5);
  oracle_fnSaveProgram(0);
  programSerializationParityCapture(&expected);

  programSerializationParityReset();
  programSerializationParitySeedPrograms(image, sizeof(image), 120, 1, 5);
  fnSaveProgram(0);
  programSerializationParityCapture(&actual);

  return reportMismatch("save current last program", &expected, &actual);
}

static int runSaveSelectedProgramCase(void) {
  static const uint8_t image[] = { 0x11u, (uint8_t)((ITM_END >> 8) | 0x80), (uint8_t)(ITM_END & 0xff), 0x22u, 0xffu, 0xffu };
  program_serialization_snapshot_t expected;
  program_serialization_snapshot_t actual;

  programSerializationParityReset();
  programSerializationParitySeedPrograms(image, sizeof(image), 118, 2, 9);
  programSerializationParitySetLabel(42, 1);
  oracle_fnSaveProgram(42);
  programSerializationParityCapture(&expected);

  programSerializationParityReset();
  programSerializationParitySeedPrograms(image, sizeof(image), 118, 2, 9);
  programSerializationParitySetLabel(42, 1);
  fnSaveProgram(42);
  programSerializationParityCapture(&actual);

  return reportMismatch("save selected labeled program", &expected, &actual);
}

static int runLoadIntoEmptyProgramAreaCase(void) {
  static const uint8_t image[] = { 0xffu, 0xffu };
  static const char loadFile[] =
      "PROGRAM_FILE_FORMAT\n"
      "0\n"
      "C47_program_file_version\n"
      "1\n"
      "PROGRAM\n"
      "2\n"
      "7\n"
      "8\n";
  program_serialization_snapshot_t expected;
  program_serialization_snapshot_t actual;

  programSerializationParityReset();
  programSerializationParitySeedPrograms(image, sizeof(image), 120, 1, 1);
  programSerializationParitySetLoadFile(loadFile);
  oracle_fnLoadProgram(0);
  programSerializationParityCapture(&expected);

  programSerializationParityReset();
  programSerializationParitySeedPrograms(image, sizeof(image), 120, 1, 1);
  programSerializationParitySetLoadFile(loadFile);
  fnLoadProgram(0);
  programSerializationParityCapture(&actual);

  return reportMismatch("load into empty program area", &expected, &actual);
}

static int runLoadWithEndInsertionCase(void) {
  static const uint8_t image[] = { 0x33u, 0x44u, 0xffu, 0xffu };
  static const char loadFile[] =
      "PROGRAM_FILE_FORMAT\n"
      "0\n"
      "C47_program_file_version\n"
      "1\n"
      "PROGRAM\n"
      "2\n"
      "85\n"
      "102\n";
  program_serialization_snapshot_t expected;
  program_serialization_snapshot_t actual;

  programSerializationParityReset();
  programSerializationParitySeedPrograms(image, sizeof(image), 120, 1, 1);
  programSerializationParitySetLoadFile(loadFile);
  oracle_fnLoadProgram(0);
  programSerializationParityCapture(&expected);

  programSerializationParityReset();
  programSerializationParitySeedPrograms(image, sizeof(image), 120, 1, 1);
  programSerializationParitySetLoadFile(loadFile);
  fnLoadProgram(0);
  programSerializationParityCapture(&actual);

  return reportMismatch("load with inserted end separator", &expected, &actual);
}

static int runInvalidHeaderCase(void) {
  static const uint8_t image[] = { 0x33u, 0x44u, 0xffu, 0xffu };
  static const char loadFile[] = "NOT_A_C47_PROGRAM\n";
  program_serialization_snapshot_t expected;
  program_serialization_snapshot_t actual;

  programSerializationParityReset();
  programSerializationParitySeedPrograms(image, sizeof(image), 120, 1, 1);
  programSerializationParitySetLoadFile(loadFile);
  oracle_fnLoadProgram(0);
  programSerializationParityCapture(&expected);

  programSerializationParityReset();
  programSerializationParitySeedPrograms(image, sizeof(image), 120, 1, 1);
  programSerializationParitySetLoadFile(loadFile);
  fnLoadProgram(0);
  programSerializationParityCapture(&actual);

  return reportMismatch("load invalid header", &expected, &actual);
}

int main(void) {
  int failures = 0;

  failures += runSaveCurrentLastProgramCase();
  failures += runSaveSelectedProgramCase();
  failures += runLoadIntoEmptyProgramAreaCase();
  failures += runLoadWithEndInsertionCase();
  failures += runInvalidHeaderCase();

  if(failures != 0) {
    return 1;
  }

  puts("program serialization parity checks passed");
  return 0;
}