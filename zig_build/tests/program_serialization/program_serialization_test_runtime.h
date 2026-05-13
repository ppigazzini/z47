// SPDX-License-Identifier: GPL-3.0-only

#ifndef Z47_PROGRAM_SERIALIZATION_TEST_RUNTIME_H
#define Z47_PROGRAM_SERIALIZATION_TEST_RUNTIME_H

#include "c47.h"

#define MAX_PROGRAM_PARITY_FILE_BYTES 32768
#define MAX_PROGRAM_PARITY_PROGRAM_IMAGE_BYTES 4096

typedef struct {
  uint16_t current_local_step_number;
  uint16_t current_program_number;
  uint16_t number_of_programs;
  uint16_t free_program_bytes;
  uint16_t begin_of_program_block;
  uint32_t first_free_program_offset;
  uint32_t begin_of_current_program_offset;
  uint32_t end_of_current_program_offset;
  uint32_t current_step_offset;
  uint32_t first_displayed_step_offset;
  uint8_t temporary_information;
  uint8_t warning_count;
  uint8_t last_error_kind;
  uint32_t scan_labels_calls;
  uint32_t go_to_last_program_calls;
  size_t saved_file_size;
  char saved_file[MAX_PROGRAM_PARITY_FILE_BYTES];
  char last_warning[256];
  uint32_t program_image_size;
  uint8_t program_image[MAX_PROGRAM_PARITY_PROGRAM_IMAGE_BYTES];
} program_serialization_snapshot_t;

void programSerializationParityReset(void);
void programSerializationParitySeedPrograms(const uint8_t *image, uint32_t imageSize, uint16_t beginBlock, uint16_t currentProgram, uint16_t currentLocalStep);
void programSerializationParitySetLabel(uint16_t label, uint16_t programNumber);
void programSerializationParitySetLoadFile(const char *contents);
void programSerializationParitySetFileOpenResults(int saveResult, int loadResult);
void programSerializationParitySetPowerBlocked(bool_t blocked);
void programSerializationParityCapture(program_serialization_snapshot_t *snapshot);

#endif