// SPDX-License-Identifier: GPL-3.0-only

#ifndef Z47_PROGRAM_SERIALIZATION_C47_H
#define Z47_PROGRAM_SERIALIZATION_C47_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

typedef bool bool_t;

#define BPB 2
#define BYTES_PER_BLOCK (1u << BPB)
#define TO_BLOCKS(n) ((((uint32_t)(n)) + (BYTES_PER_BLOCK - 1)) >> BPB)
#define TO_BYTES(n) (((uint32_t)(n)) << BPB)
#define RAM_SIZE_IN_BLOCKS 128u
#define FILE_OK 1
#define FILE_CANCEL 2
#define ITM_END 1458u
#define TI_SAVED 32u
#define TI_PROGRAM_LOADED 86u

extern uint8_t *beginOfCurrentProgram;
extern uint8_t *endOfCurrentProgram;
extern uint8_t *firstDisplayedStep;
extern uint8_t *currentStep;
extern uint8_t *beginOfProgramMemory;
extern uint8_t *firstFreeProgramByte;
extern uint16_t freeProgramBytes;
extern uint16_t currentLocalStepNumber;
extern uint16_t currentProgramNumber;
extern uint16_t numberOfPrograms;
extern uint8_t temporaryInformation;

void resizeProgramMemory(uint16_t newSizeInBlocks);

bool_t z47_program_serialization_runtime_check_power(void);
bool_t z47_program_serialization_runtime_select_program(uint16_t label);
int z47_program_serialization_runtime_open_save_program(void);
int z47_program_serialization_runtime_open_load_program(void);
void z47_program_serialization_runtime_write_literal(const char *text);
void z47_program_serialization_runtime_write_u32_line(uint32_t value);
void z47_program_serialization_runtime_write_u8_line(uint8_t value);
void z47_program_serialization_runtime_read_line(char *buffer);
void z47_program_serialization_runtime_close_file(void);
void z47_program_serialization_runtime_display_write_error(void);
void z47_program_serialization_runtime_display_read_error(void);
void z47_program_serialization_runtime_show_warning(const char *message);
void z47_program_serialization_runtime_scan_labels_and_programs(void);
void z47_program_serialization_runtime_go_to_last_program(void);
bool_t z47_program_serialization_runtime_is_at_end_of_program(const uint8_t *step);
uint16_t z47_program_serialization_runtime_get_ram_size_in_blocks(void);
uint16_t z47_program_serialization_runtime_to_c47_mem_ptr(const uint8_t *memPtr);
uint32_t z47_program_serialization_runtime_parse_u32_line(const char *line);
uint8_t z47_program_serialization_runtime_parse_u8_line(const char *line);
bool_t z47_program_serialization_runtime_line_equals(const char *line, const char *expected);

void fnSaveProgram(uint16_t label);
void fnLoadProgram(uint16_t unusedButMandatoryParameter);
void oracle_fnSaveProgram(uint16_t label);
void oracle_fnLoadProgram(uint16_t unusedButMandatoryParameter);

#endif