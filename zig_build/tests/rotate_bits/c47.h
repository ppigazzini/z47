// SPDX-License-Identifier: GPL-3.0-only

#ifndef Z47_ROTATE_BITS_FAKE_C47_H
#define Z47_ROTATE_BITS_FAKE_C47_H

#include <stdbool.h>
#include <stdint.h>

typedef bool bool_t;
typedef int16_t calcRegister_t;
typedef uint32_t longInteger_t[1];

enum REG_NUMBERS {
  REGISTER_X = 100,
  REGISTER_Y = 101,
  REGISTER_Z = 102,
  REGISTER_L = 108,
};

enum {
  dtLongInteger = 0,
  dtShortInteger = 8,
};

#define SHORT_INTEGER_SIZE_IN_BLOCKS 2
#define ERROR_INVALID_DATA_TYPE_FOR_OP 24
#define ERR_REGISTER_LINE REGISTER_Z
#define EXTRA_INFO_ON_CALC_ERROR 0

#define FLAG_CARRY 0x800b
#define FLAG_ASLIFT 0xc023

extern uint8_t shortIntegerWordSize;
extern uint64_t shortIntegerMask;
extern uint64_t shortIntegerSignBit;
extern bool_t thereIsSomethingToUndo;
extern uint8_t temporaryInformation;

typedef struct parity_runtime_state {
  uint64_t x_raw;
  uint32_t x_base;
  uint32_t x_data_type;
  uint64_t y_raw;
  uint32_t y_base;
  uint32_t y_data_type;
  uint64_t z_raw;
  uint32_t z_base;
  uint32_t z_data_type;
  uint64_t l_raw;
  uint32_t l_base;
  uint32_t l_data_type;
  bool_t get_shortint_ok;
  bool_t save_last_x_ok;
  bool_t saved_last_x;
  bool_t lifted_stack;
  bool_t carry_flag;
  bool_t aslift_flag;
  uint8_t last_error_code;
  calcRegister_t last_error_message_register;
  calcRegister_t last_error_register;
  uint32_t adjust_result_calls;
} parity_runtime_state_t;

typedef struct rotate_bits_snapshot {
  parity_runtime_state_t runtime_state;
  uint8_t word_size;
  uint64_t mask;
  uint64_t sign_bit;
  uint8_t temporary_information;
  bool_t undo_flag;
} rotate_bits_snapshot_t;

extern parity_runtime_state_t parityRuntimeState;

bool_t getRegisterAsRawShortInt(calcRegister_t reg, uint64_t *val, uint32_t *base);
bool_t saveLastX(void);
void liftStack(void);
void displayCalcErrorMessage(uint8_t errorCode, calcRegister_t errMessageRegisterLine, calcRegister_t errRegisterLine);
void reallocateRegister(calcRegister_t regist, uint32_t dataType, uint16_t dataSizeWithoutDataLenBlocks, uint32_t tag);
void *getRegisterDataPointer(calcRegister_t regist);
bool_t getSystemFlag(int32_t sf);
void setSystemFlag(unsigned int sf);
void forceSystemFlag(unsigned int sf, int set);
void fnSetWordSize(uint16_t ws);
void adjustResult(calcRegister_t res, bool_t dropY, bool_t setCpxRes, calcRegister_t op1, calcRegister_t op2, calcRegister_t op3);
void longIntegerInit(longInteger_t value);
void uInt32ToLongInteger(uint32_t source, longInteger_t dest);
void convertLongIntegerToLongIntegerRegister(const longInteger_t value, calcRegister_t dest);
void convertShortIntegerRegisterToLongIntegerRegister(calcRegister_t source, calcRegister_t dest);
void longIntegerFree(longInteger_t value);

void rotateBitsResetState(uint8_t wordSize,
                          uint64_t xRaw,
                          uint32_t xBase,
                          uint64_t yRaw,
                          uint32_t yBase,
                          uint64_t zRaw,
                          uint32_t zBase,
                          bool_t carryFlag);
void rotateBitsCapture(rotate_bits_snapshot_t *out);

#define REGISTER_SHORT_INTEGER_DATA(a) ((uint64_t *)(getRegisterDataPointer(a)))

#endif