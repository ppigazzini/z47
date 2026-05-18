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

enum {
	dtComplex34 = 2,
	dtTime = 3,
	dtDate = 4,
	dtString = 5,
	dtReal34Matrix = 6,
	dtComplex34Matrix = 7,
	dtShortInteger = 8,
	dtConfig = 9,
};

#define COMPLEX34_SIZE_IN_BLOCKS TO_BLOCKS(sizeof(complex34_t))
#define COMPLEX34_SIZE_IN_BYTES TO_BYTES(COMPLEX34_SIZE_IN_BLOCKS)
#define SHORT_INTEGER_SIZE_IN_BLOCKS 2
#define CONFIG_SIZE_IN_BLOCKS TO_BLOCKS(sizeof(dtConfigDescriptor_t))

enum {
	RESERVED_VARIABLE_ADM = FIRST_NAMED_RESERVED_VARIABLE,
	RESERVED_VARIABLE_DENMAX,
	RESERVED_VARIABLE_ISM,
	RESERVED_VARIABLE_REALDF,
	RESERVED_VARIABLE_NDEC,
};

#endif