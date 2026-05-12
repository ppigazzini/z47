// SPDX-License-Identifier: GPL-3.0-only

#ifndef C47_H
#define C47_H

#ifndef Z47_STACK_STATE_FAKE_C47_H
#define Z47_STACK_STATE_FAKE_C47_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

typedef bool bool_t;
typedef int16_t calcRegister_t;

typedef union {
  uint32_t descriptor;
  struct {
    unsigned pointerToRegisterData : 16;
    unsigned dataType : 4;
    unsigned tag : 5;
    unsigned readOnly : 1;
    unsigned notUsed : 6;
  };
} registerHeader_t;

typedef struct {
  registerHeader_t header;
  uint8_t variableName[16];
} namedVariableHeader_t;

typedef struct {
  char Desc[28];
} reservedVariableDescStr_t;

typedef struct {
  registerHeader_t header;
  uint8_t reservedVariableName[8];
} reservedVariableHeader_t;

typedef struct {
  uint8_t bytes[16];
} real34_t;

typedef struct {
  uint8_t bytes[8];
} real_t;

typedef uint32_t longInteger_t[1];

enum {
  dtLongInteger = 0,
  dtReal34 = 1,
};

enum {
  LI_POSITIVE = 2,
  amNone = 5,
};

enum {
  ERROR_NONE = 0,
  ERROR_OUT_OF_RANGE = 8,
  ERROR_RAM_FULL = 11,
};

enum {
  CM_AIM = 1,
  CM_NIM = 2,
  CM_MIM = 12,
  CM_NO_UNDO = 16,
};

enum {
  SIGMA_NONE = 0,
  SIGMA_PLUS = 1,
  SIGMA_MINUS = 2,
};

enum REG_NUMBERS {
  REGISTER_X = 100,
  REGISTER_Y = 101,
  REGISTER_Z = 102,
  REGISTER_T = 103,
  REGISTER_D = 107,
  REGISTER_L = 108,
  SAVED_REGISTER_X = 126,
  SAVED_REGISTER_L = 134,
  TEMP_REGISTER_2_SAVED_STATS = 136,
  LAST_GLOBAL_REGISTER = TEMP_REGISTER_2_SAVED_STATS,
  FIRST_NAMED_VARIABLE = 256,
  LAST_NAMED_VARIABLE = 1999,
  FIRST_RESERVED_VARIABLE = 2000,
  FIRST_NAMED_RESERVED_VARIABLE = 2026,
  LAST_RESERVED_VARIABLE = 2047,
  INVALID_VARIABLE = 2199,
  FIRST_LOCAL_REGISTER = 7000,
  LAST_LOCAL_REGISTER = 7098,
};

enum {
  NUMBER_OF_GLOBAL_REGISTERS = 137,
  NUMBER_OF_RESERVED_VARIABLES = LAST_RESERVED_VARIABLE - FIRST_RESERVED_VARIABLE + 1,
  NUMBER_OF_LETTERED_VARIABLES = FIRST_NAMED_RESERVED_VARIABLE - FIRST_RESERVED_VARIABLE,
  NUMBER_OF_STATISTICAL_SUMS = 28,
  MAX_FAKE_NAMED_VARIABLES = 64,
  MAX_FAKE_LOCAL_REGISTERS = 4,
  MAX_FAKE_MEMORY_SLOTS = 256,
};

#define FLAG_SSIZE8 0x8018
#define FLAG_ASLIFT 0xc023
#define FLAG_INTING 0xc025
#define FLAG_SOLVING 0xc026

#define BPB 2
#define BYTES_PER_BLOCK (1u << BPB)
#define TO_BLOCKS(n) ((((uint32_t)(n)) + (BYTES_PER_BLOCK - 1)) >> BPB)
#define TO_BYTES(n) (((uint32_t)(n)) << BPB)

#define REAL34_SIZE_IN_BLOCKS TO_BLOCKS(sizeof(real34_t))
#define REAL34_SIZE_IN_BYTES TO_BYTES(REAL34_SIZE_IN_BLOCKS)
#define REAL_SIZE_IN_BYTES(digits) ((uint32_t)sizeof(real_t))
#define REAL_SIZE_IN_BLOCKS(digits) TO_BLOCKS(REAL_SIZE_IN_BYTES(digits))

#define C47_NULL 0
#define EXTRA_INFO_ON_CALC_ERROR 0
#define min(a, b) ((a) < (b) ? (a) : (b))
#define ERROR_MESSAGE_LENGTH 256

enum {
  bugMsgNoNamedVariables = 0,
  bugMsgRegistMustBeLessThan = 1,
};

uint16_t stackParityToC47MemPtr(const void *ptr);
void *stackParityToPcMemPtr(uint16_t ptr);

#define TO_PCMEMPTR(p) stackParityToPcMemPtr((uint16_t)(p))
#define TO_C47MEMPTR(p) stackParityToC47MemPtr(p)

#define getStackTop() z47_stack_runtime_get_stack_top()
#define freeRegisterData(regist) freeC47Blocks(getRegisterDataPointer(regist), getRegisterFullSizeInBlocks(regist))
#define REGISTER_REAL34_DATA(a) ((real34_t *)(getRegisterDataPointer(a)))

extern registerHeader_t globalRegister[NUMBER_OF_GLOBAL_REGISTERS];
extern namedVariableHeader_t *allNamedVariables;
extern registerHeader_t *currentLocalRegisters;
extern const reservedVariableHeader_t allReservedVariables[];
extern char errorMessage[ERROR_MESSAGE_LENGTH];
extern const char commonBugScreenMessages[2][ERROR_MESSAGE_LENGTH];
extern uint16_t numberOfNamedVariables;
extern uint8_t currentNumberOfLocalRegisters;

extern uint16_t currentInputVariable;
extern uint8_t displayStack;
extern bool_t thereIsSomethingToUndo;
extern uint8_t calcMode;
extern uint8_t lastErrorCode;
extern uint8_t entryStatus;
extern uint64_t systemFlags0;
extern uint64_t systemFlags1;
extern uint64_t savedSystemFlags0;
extern uint64_t savedSystemFlags1;
extern int8_t SAVED_SIGMA_lastAddRem;
extern uint16_t lrSelection;
extern uint16_t lrSelectionUndo;
extern uint16_t lrChosen;
extern uint16_t lrChosenUndo;
extern real_t *statisticalSumsPointer;
extern real_t *savedStatisticalSumsPointer;
extern real_t SAVED_SIGMA_LASTX;
extern real_t SAVED_SIGMA_LASTY;

uint16_t z47_stack_runtime_get_stack_top(void);
uint16_t z47_stack_runtime_real34_size_in_blocks(void);
uint32_t z47_stack_runtime_get_global_register_descriptor(calcRegister_t reg);
void z47_stack_runtime_set_global_register_descriptor(calcRegister_t reg, uint32_t descriptor);
bool_t z47_stack_runtime_get_swap_target_descriptor(uint16_t reg, uint32_t *descriptor);
bool_t z47_stack_runtime_set_swap_target_descriptor(uint16_t reg, uint32_t descriptor);
void z47_stack_runtime_report_invalid_swap_target(uint16_t reg);
uint16_t z47_stack_runtime_statistical_sums_blocks(void);
uint32_t z47_stack_runtime_statistical_sums_bytes(void);
void z47_stack_runtime_store_stack_size_in_x(uint32_t size);
void z47_stack_runtime_restore_saved_sigma_last_xy_and_add(void);

bool_t getSystemFlag(int32_t sf);
void setSystemFlag(unsigned int sf);
void clearSystemFlag(unsigned int sf);
void flipSystemFlag(unsigned int sf);

void clearRegister(calcRegister_t reg);
void *allocC47Blocks(size_t size_in_blocks);
void freeC47Blocks(void *ptr, size_t size_in_blocks);
void *getRegisterDataPointer(calcRegister_t reg);
void setRegisterDataPointer(calcRegister_t reg, const void *mem_ptr);
uint32_t getRegisterDataType(calcRegister_t reg);
uint32_t getRegisterTag(calcRegister_t reg);
void setRegisterDataType(calcRegister_t reg, uint16_t data_type, uint32_t tag);
uint16_t getRegisterFullSizeInBlocks(calcRegister_t reg);
void *xcopy(void *dest, const void *source, uint32_t n);
void copySourceRegisterToDestRegister(calcRegister_t source_register, calcRegister_t dest_register);
void fnRecall(uint16_t reg);
void recallStatsMatrix(void);
void fnSigmaAddRem(uint16_t selection);
void displayBugScreen(const char *message);
void displayCalcErrorMessage(uint8_t error_code, calcRegister_t err_message_register_line, calcRegister_t err_register_line);
void moreInfoOnError(const char *m1, const char *m2, const char *m3, const char *m4);
void reallocateRegister(calcRegister_t reg, uint32_t data_type, uint16_t data_size_without_data_len_blocks, uint32_t tag);
void real34SetZero(real34_t *dest);
void longIntegerInit(longInteger_t value);
void uInt32ToLongInteger(uint32_t source, longInteger_t dest);
void convertLongIntegerToLongIntegerRegister(const longInteger_t value, calcRegister_t dest);
void longIntegerFree(longInteger_t value);
void convertRealToResultRegister(const real_t *value, calcRegister_t dest, uint32_t angle);

#define STACK_PARITY_REGISTER_CAPTURE_BYTES 32
#define STACK_PARITY_STATS_BYTES (NUMBER_OF_STATISTICAL_SUMS * sizeof(real_t))

typedef struct {
  registerHeader_t header;
  uint16_t size_in_blocks;
  uint8_t data[STACK_PARITY_REGISTER_CAPTURE_BYTES];
} stack_parity_register_snapshot_t;

typedef struct {
  stack_parity_register_snapshot_t global_registers[NUMBER_OF_GLOBAL_REGISTERS];
  stack_parity_register_snapshot_t named_variables[MAX_FAKE_NAMED_VARIABLES];
  stack_parity_register_snapshot_t local_registers[MAX_FAKE_LOCAL_REGISTERS];
  uint16_t numberOfNamedVariables;
  uint8_t currentNumberOfLocalRegisters;
  uint16_t currentInputVariable;
  uint8_t displayStack;
  bool_t thereIsSomethingToUndo;
  uint8_t calcMode;
  uint8_t lastErrorCode;
  uint8_t entryStatus;
  uint64_t systemFlags0;
  uint64_t systemFlags1;
  uint64_t savedSystemFlags0;
  uint64_t savedSystemFlags1;
  int8_t SAVED_SIGMA_lastAddRem;
  uint16_t lrSelection;
  uint16_t lrSelectionUndo;
  uint16_t lrChosen;
  uint16_t lrChosenUndo;
  bool_t stats_present;
  bool_t saved_stats_present;
  uint8_t statistical_sums[STACK_PARITY_STATS_BYTES];
  uint8_t saved_statistical_sums[STACK_PARITY_STATS_BYTES];
} stack_parity_snapshot_t;

void stackParityReset(void);
void stackParitySeedRegister(calcRegister_t reg, uint32_t data_type, uint32_t tag, const uint8_t *data, uint16_t size_in_blocks);
void stackParitySeedNamedVariable(int index, uint32_t data_type, uint32_t tag, const uint8_t *data, uint16_t size_in_blocks);
void stackParitySeedLocalRegister(int index, uint32_t data_type, uint32_t tag, const uint8_t *data, uint16_t size_in_blocks);
void stackParitySeedCurrentStats(uint8_t seed);
void stackParitySeedSavedStats(uint8_t seed);
void stackParityCapture(stack_parity_snapshot_t *snapshot);

#endif

#endif
