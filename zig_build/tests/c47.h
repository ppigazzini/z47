// SPDX-License-Identifier: GPL-3.0-only

#ifndef Z47_LOGICAL_SHORTINT_FAKE_C47_H
#define Z47_LOGICAL_SHORTINT_FAKE_C47_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

typedef bool bool_t;
typedef int16_t calcRegister_t;

enum REG_NUMBERS {
  REGISTER_X = 100,
  REGISTER_Y = 101,
  REGISTER_Z = 102,
  REGISTER_L = 108,
};

enum {
  dtShortInteger = 8,
};

#define SHORT_INTEGER_SIZE_IN_BLOCKS 2
#define ERROR_WORD_SIZE_TOO_SMALL 14
#define ERR_REGISTER_LINE REGISTER_Z
#define TI_FALSE 12
#define EXTRA_INFO_ON_CALC_ERROR 0

extern uint8_t shortIntegerWordSize;
extern uint64_t shortIntegerMask;
extern bool_t thereIsSomethingToUndo;
extern uint8_t temporaryInformation;

typedef struct parity_runtime_state {
  uint64_t x_raw;
  uint32_t x_base;
  uint32_t x_data_type;
  uint64_t l_raw;
  uint32_t l_base;
  uint32_t l_data_type;
  bool_t get_shortint_ok;
  bool_t save_last_x_ok;
  bool_t saved_last_x;
  bool_t lifted_stack;
  uint8_t last_error_code;
  calcRegister_t last_error_message_register;
  calcRegister_t last_error_register;
} parity_runtime_state_t;

extern parity_runtime_state_t parityRuntimeState;

bool_t getRegisterAsRawShortInt(calcRegister_t reg, uint64_t *val, uint32_t *base);
bool_t saveLastX(void);
void liftStack(void);
void displayCalcErrorMessage(uint8_t errorCode, calcRegister_t errMessageRegisterLine, calcRegister_t errRegisterLine);
void reallocateRegister(calcRegister_t regist, uint32_t dataType, uint16_t dataSizeWithoutDataLenBlocks, uint32_t tag);
void *getRegisterDataPointer(calcRegister_t regist);
void convertUInt64ToShortIntegerRegister(int16_t sign, uint64_t value, uint32_t base, calcRegister_t regist);

void parityResetState(uint8_t wordSize, uint64_t xRaw, uint32_t xBase);
void paritySetGetShortIntOk(bool_t ok);
void paritySetSaveLastXOk(bool_t ok);

#define REGISTER_SHORT_INTEGER_DATA(a) ((uint64_t *)(getRegisterDataPointer(a)))
#define SET_TI_TRUE_FALSE(condition) do { temporaryInformation = TI_FALSE + (condition); } while(0)

#endif