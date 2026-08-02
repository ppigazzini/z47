// SPDX-License-Identifier: GPL-3.0-only

#ifndef Z47_REGISTER_METADATA_FAKE_C47_H
#define Z47_REGISTER_METADATA_FAKE_C47_H

#include <string.h>

#include "../stack_state/c47.h"

typedef struct {
	uint32_t descriptor;
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

#define Z47_MATRIX_ROWS_MASK 0x00000fffu
#define Z47_MATRIX_COLUMNS_MASK 0x00fff000u
#define Z47_MATRIX_TAG_MASK 0x3f000000u

#define Z47_MATRIX_ROWS_SHIFT 0u
#define Z47_MATRIX_COLUMNS_SHIFT 12u
#define Z47_MATRIX_TAG_SHIFT 24u

static inline uint32_t z47MakeMatrixHeaderDescriptor(uint16_t rows, uint16_t columns, uint32_t tag) {
	return ((((uint32_t)rows) & 0x0fffu) << Z47_MATRIX_ROWS_SHIFT) |
	       ((((uint32_t)columns) & 0x0fffu) << Z47_MATRIX_COLUMNS_SHIFT) |
	       ((((uint32_t)tag) & 0x3fu) << Z47_MATRIX_TAG_SHIFT);
}

static inline uint16_t z47MatrixHeaderRows(uint32_t descriptor) {
	return (uint16_t)((descriptor & Z47_MATRIX_ROWS_MASK) >> Z47_MATRIX_ROWS_SHIFT);
}

static inline uint16_t z47MatrixHeaderColumns(uint32_t descriptor) {
	return (uint16_t)((descriptor & Z47_MATRIX_COLUMNS_MASK) >> Z47_MATRIX_COLUMNS_SHIFT);
}

static inline uint32_t z47MatrixHeaderTag(uint32_t descriptor) {
	return (descriptor & Z47_MATRIX_TAG_MASK) >> Z47_MATRIX_TAG_SHIFT;
}

static inline uint32_t z47MatrixHeaderReadDescriptor(const void *data_ptr) {
	uint32_t descriptor = 0;

	if(data_ptr != NULL) {
		memcpy(&descriptor, data_ptr, sizeof(descriptor));
	}

	return descriptor;
}

static inline void z47MatrixHeaderWriteDescriptor(void *data_ptr, uint32_t descriptor) {
	if(data_ptr == NULL) {
		return;
	}

	memcpy(data_ptr, &descriptor, sizeof(descriptor));
}

static inline void z47MatrixHeaderWrite(void *data_ptr, uint16_t rows, uint16_t columns, uint32_t tag) {
	z47MatrixHeaderWriteDescriptor(data_ptr, z47MakeMatrixHeaderDescriptor(rows, columns, tag));
}

static inline uint16_t z47MatrixHeaderRowsFromData(const void *data_ptr) {
	return z47MatrixHeaderRows(z47MatrixHeaderReadDescriptor(data_ptr));
}

static inline uint16_t z47MatrixHeaderColumnsFromData(const void *data_ptr) {
	return z47MatrixHeaderColumns(z47MatrixHeaderReadDescriptor(data_ptr));
}

static inline void z47MatrixHeaderSetRowsColumns(void *data_ptr, uint16_t rows, uint16_t columns) {
	uint32_t descriptor = z47MatrixHeaderReadDescriptor(data_ptr);

	descriptor &= ~(Z47_MATRIX_ROWS_MASK | Z47_MATRIX_COLUMNS_MASK);
	descriptor |= ((((uint32_t)rows) & 0x0fffu) << Z47_MATRIX_ROWS_SHIFT) |
	             ((((uint32_t)columns) & 0x0fffu) << Z47_MATRIX_COLUMNS_SHIFT);
	z47MatrixHeaderWriteDescriptor(data_ptr, descriptor);
}

static inline uint16_t z47StrLgIntHeaderReadMaxLength(const void *data_ptr) {
	strLgIntHeader_t header = {0};

	if(data_ptr != NULL) {
		memcpy(&header, data_ptr, sizeof(header));
	}

	return header.dataMaxLengthInBlocks;
}

static inline void z47StrLgIntHeaderWrite(void *data_ptr, uint16_t data_max_length_in_blocks) {
	strLgIntHeader_t header = {0};

	header.dataMaxLengthInBlocks = data_max_length_in_blocks;
	if(data_ptr != NULL) {
		memcpy(data_ptr, &header, sizeof(header));
	}
}

static inline void z47StrLgIntHeaderWriteMaxLength(void *data_ptr, uint16_t data_max_length_in_blocks) {
	strLgIntHeader_t header = {0};

	if(data_ptr == NULL) {
		return;
	}

	memcpy(&header, data_ptr, sizeof(header));
	header.dataMaxLengthInBlocks = data_max_length_in_blocks;
	memcpy(data_ptr, &header, sizeof(header));
}

#define COMPLEX34_SIZE_IN_BYTES TO_BYTES(COMPLEX34_SIZE_IN_BLOCKS)
#define CONFIG_SIZE_IN_BLOCKS TO_BLOCKS(sizeof(dtConfigDescriptor_t))
#define LIMB_SIZE ((uint32_t)sizeof(uintptr_t))
#define ERR_REGISTER_LINE REGISTER_X
#define NIM_REGISTER_LINE REGISTER_Y

#define CAT_STATUS 0x00f0
#define CAT_MENU (2 << 4)
#define CMP_NAME 3
#define LAST_ITEM 8
#define ERROR_INVALID_NAME 48
#define ERROR_TOO_MANY_VARIABLES 49
#define ERROR_CANNOT_DELETE_PREDEF_ITEM 27
#define ERROR_UNDEF_SOURCE_VAR 36

enum {
	dtConfig = 9,
};

typedef struct {
	uint32_t status;
	char itemCatalogName[16];
} item_t;

typedef struct {
	char menuName[16];
} userMenu_t;

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
extern item_t indexOfItems[LAST_ITEM];
extern userMenu_t *userMenus;
extern uint16_t numberOfUserMenus;
extern uint16_t currentSolverVariable;
extern calcRegister_t graphVariabl1;

bool_t isMemoryBlockAvailable(size_t size_in_blocks, uint16_t numBlocks, float extraFraction);
void stackParitySetMemoryBlockAvailable(bool_t available);
void stackParitySeedBuiltInMenuItem(uint32_t index, uint32_t status, const char *name);
void stackParitySeedUserMenu(uint32_t index, const char *name);
void stackParitySeedNamedVariableName(int index, const char *name);
calcRegister_t findNamedVariable(const char *variableName);
void fnDeleteVariable(uint16_t regist);
int32_t compareString(const char *left, const char *right, int32_t comparisonType);

uint32_t z47_register_metadata_builtin_menu_item_count(void);
bool_t z47_register_metadata_builtin_menu_item_is_menu(uint32_t index);
const char *z47_register_metadata_builtin_menu_item_name(uint32_t index);
uint32_t z47_register_metadata_user_menu_count(void);
const char *z47_register_metadata_user_menu_name(uint32_t index);
const char *z47_register_metadata_named_variable_name(uint16_t index);
bool_t z47_register_metadata_allocate_first_named_variable_header(void);
bool_t z47_register_metadata_append_named_variable_header(uint16_t *index);
void z47_register_metadata_store_named_variable_name(uint16_t index, const char *variable_name);
int32_t z47_register_metadata_compare_menu_names(const char *left, const char *right);
calcRegister_t z47_register_metadata_find_reserved_variable_name(const char *variable_name, uint8_t glyph_length);
void z47_register_metadata_report_invalid_name(void);
void z47_register_metadata_report_undef_source_var(void);
void z47_register_metadata_report_cannot_delete_predef_item(void);
void z47_register_metadata_report_too_many_variables(void);
void z47_register_metadata_request_delete_all_variables_confirmation(void);
void z47_register_metadata_request_clear_all_variables_confirmation(void);

#endif
