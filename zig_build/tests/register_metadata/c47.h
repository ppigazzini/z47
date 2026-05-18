// SPDX-License-Identifier: GPL-3.0-only

#ifndef Z47_REGISTER_METADATA_FAKE_C47_H
#define Z47_REGISTER_METADATA_FAKE_C47_H

#include "../stack_state/c47.h"

typedef struct {
	unsigned matrixRows : 12;
	unsigned matrixColumns : 12;
	unsigned mtag : 6;
	unsigned notUsed : 2;
} matrixHeader_t;

typedef struct {
	uint16_t dataMaxLengthInBlocks;
	uint16_t unused;
} strLgIntHeader_t;

typedef struct {
	uint8_t bytes[32];
} complex34_t;

typedef struct {
	uint8_t bytes[840];
} dtConfigDescriptor_t;

#define COMPLEX34_SIZE_IN_BYTES TO_BYTES(COMPLEX34_SIZE_IN_BLOCKS)
#define CONFIG_SIZE_IN_BLOCKS TO_BLOCKS(sizeof(dtConfigDescriptor_t))
#define LIMB_SIZE ((uint32_t)sizeof(uintptr_t))
#define ERR_REGISTER_LINE REGISTER_X
#define NIM_REGISTER_LINE REGISTER_Y

enum {
	dtConfig = 9,
};

#define ITM_INPUT 43
#define ITM_STO 44
#define ITM_STOADD 45
#define ITM_STOSUB 46
#define ITM_STOMULT 47
#define ITM_STODIV 48
#define ITM_RCL 51
#define ITM_KEYQ 77
#define ITM_Xex 127
#define ITM_STOMAX 1430
#define ITM_MVAR 1524
#define ITM_M_DIM 1526
#define ITM_STOMIN 1545
#define ITM_SOLVE 1608
#define ITM_STOCFG 1611
#define ITM_Tex 1625
#define ITM_XtoALPHA 1645
#define ITM_Yex 1650
#define ITM_Zex 1651
#define ITM_INTEGRAL 1700

enum {
	RESERVED_VARIABLE_ADM = FIRST_NAMED_RESERVED_VARIABLE,
	RESERVED_VARIABLE_DENMAX,
	RESERVED_VARIABLE_ISM,
	RESERVED_VARIABLE_REALDF,
	RESERVED_VARIABLE_NDEC,
};

extern uint32_t currentAngularMode;

bool_t isMemoryBlockAvailable(size_t size_in_blocks, uint16_t numBlocks, float extraFraction);
void stackParitySetMemoryBlockAvailable(bool_t available);

#endif