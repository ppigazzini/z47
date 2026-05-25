// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

#define fnP_PrinterOnOff z47_frontier_retained_fnP_PrinterOnOff
#define fnP_PrinterMode z47_frontier_retained_fnP_PrinterMode
#define fnSetPrinter z47_frontier_retained_fnSetPrinter
#define fnP_SetDelay z47_frontier_retained_fnP_SetDelay
#define fnP_Advance z47_frontier_retained_fnP_Advance
#define fnP_PrinterList z47_frontier_retained_fnP_PrinterList
#define fnP_Byte z47_frontier_retained_fnP_Byte
#define fnP_Char z47_frontier_retained_fnP_Char
#define fnP_Tab z47_frontier_retained_fnP_Tab
#define fnP_User z47_frontier_retained_fnP_User
#define fnP_LCD z47_frontier_retained_fnP_LCD
#define fnP_Alpha z47_frontier_retained_fnP_Alpha
#define fnP_Sigma z47_frontier_retained_fnP_Sigma
#define fnP_All_Regs z47_frontier_retained_fnP_All_Regs
#define fnP_Regs z47_frontier_retained_fnP_Regs
#define fnP_PrintAllItems z47_frontier_retained_fnP_PrintAllItems

void z47_frontier_retained_fnP_Regs(uint16_t registerNo);
void z47_frontier_retained_fnP_PrintAllItems(uint16_t unusedButMandatoryParameter);

#include "../../src/c47/printing/print.c"

#if !defined(IR_PRINTING)
bool_t z47_frontier_print_reg_range(uint16_t first_register_no, uint16_t last_register_no) {
	(void)first_register_no;
	(void)last_register_no;
	return false;
}

bool_t z47_frontier_print_exit_pressed(void) {
	return false;
}

uint16_t z47_frontier_current_number_of_local_registers(void) {
	return currentNumberOfLocalRegisters;
}

const char *z47_frontier_sigma_name(uint16_t index) {
	return summationRegisterName[index].name;
}

void z47_frontier_print_sigma_line(uint16_t index) {
	(void)index;
}

void z47_frontier_print_alpha_register(uint16_t register_no) {
	(void)register_no;
}

void z47_frontier_print_set_printer_sbi(bool_t status) {
	(void)status;
}

uint16_t z47_frontier_print_get_unicode_value(calcRegister_t regist) {
	(void)regist;
	return 0;
}

uint16_t z47_frontier_x_real_matrix_rows(void) {
	real34Matrix_t x;
	convertReal34MatrixRegisterToReal34Matrix(REGISTER_X, &x);
	return x.header.matrixRows;
}

uint16_t z47_frontier_x_real_matrix_cols(void) {
	real34Matrix_t x;
	convertReal34MatrixRegisterToReal34Matrix(REGISTER_X, &x);
	return x.header.matrixColumns;
}

uint16_t z47_frontier_x_complex_matrix_rows(void) {
	complex34Matrix_t x;
	convertComplex34MatrixRegisterToComplex34Matrix(REGISTER_X, &x);
	return x.header.matrixRows;
}

uint16_t z47_frontier_x_complex_matrix_cols(void) {
	complex34Matrix_t x;
	convertComplex34MatrixRegisterToComplex34Matrix(REGISTER_X, &x);
	return x.header.matrixColumns;
}

void z47_frontier_x_real_matrix_element_to_temp1(uint32_t index) {
	real34Matrix_t x;
	convertReal34MatrixRegisterToReal34Matrix(REGISTER_X, &x);
	reallocateRegister(TEMP_REGISTER_1, dtReal34, REAL34_SIZE_IN_BYTES, amNone);
	real34Copy(&x.matrixElements[index], REGISTER_REAL34_DATA(TEMP_REGISTER_1));
}

void z47_frontier_x_complex_matrix_element_to_temp1(uint32_t index) {
	complex34Matrix_t x;
	convertComplex34MatrixRegisterToComplex34Matrix(REGISTER_X, &x);
	reallocateRegister(TEMP_REGISTER_1, dtComplex34, 0, amNone);
	complex34Copy(&x.matrixElements[index], REGISTER_COMPLEX34_DATA(TEMP_REGISTER_1));
}

bool_t z47_frontier_named_variable_label(uint16_t index, char *buffer, uint16_t buffer_size) {
	if(index >= numberOfNamedVariables || buffer == NULL || buffer_size == 0) {
		return false;
	}

	uint16_t length = allNamedVariables[index].variableName[0];
	if(length >= buffer_size) {
		length = buffer_size - 1;
	}

	xcopy(buffer, allNamedVariables[index].variableName + 1, length);
	buffer[length] = 0;
	return true;
}

bool_t z47_frontier_user_variable_should_skip(const char *label) {
	if(label == NULL) {
		return true;
	}

	return compareString(label, "STATS", CMP_NAME) == 0 ||
	       compareString(label, "HISTO", CMP_NAME) == 0 ||
	       compareString(label, "Mat_A", CMP_NAME) == 0 ||
	       compareString(label, "Mat_B", CMP_NAME) == 0 ||
	       compareString(label, "Mat_X", CMP_NAME) == 0;
}

calcRegister_t z47_frontier_find_named_variable_register(const char *label) {
	return findNamedVariable(label);
}

uint8_t *z47_frontier_program_begin(void) {
	return beginOfProgramMemory;
}

bool_t z47_frontier_programs_end(uint8_t *step) {
	return isAtEndOfPrograms(step);
}

uint8_t *z47_frontier_program_next_step(uint8_t *step) {
	return findNextStep(step);
}

bool_t z47_frontier_program_global_label(uint8_t *step, char *label, uint16_t label_size) {
	if(step == NULL || label == NULL || label_size == 0) {
		return false;
	}

	if(!checkOpCodeOfStep(step, ITM_LBL)) {
		return false;
	}

	if(*(step + 1) <= LAST_LOCAL_LABEL) {
		return false;
	}

	uint16_t length = *(step + 2);
	if(length >= label_size) {
		length = label_size - 1;
	}
	xcopy(label, step + 3, length);
	label[length] = 0;
	return true;
}

bool_t z47_frontier_program_step_is_end(uint8_t *step) {
	return isAtEndOfProgram(step);
}

const char *z47_frontier_program_label_prefix(void) {
	return "LBL " STD_LEFT_SINGLE_QUOTE;
}

const char *z47_frontier_program_label_suffix(void) {
	return STD_RIGHT_SINGLE_QUOTE;
}

void z47_frontier_print_program_counter(uint16_t program_number, uint16_t total_programs) {
	(void)program_number;
	(void)total_programs;
}

void printTab(uint16_t col) {
	(void)col;
}

void printLine(const char *buff, int with_lf) {
	(void)buff;
	(void)with_lf;
}

void printJustified(const char *buff) {
	(void)buff;
}

void printReg(uint16_t regist, const char *label, bool_t eq, print_area_t where, bool prSigma) {
	(void)regist;
	(void)label;
	(void)eq;
	(void)where;
	(void)prSigma;
}

void printAlpha(const char *Alpha, printArgument_t arg) {
	(void)Alpha;
	(void)arg;
}

void print_lf(void) {}

void cmdPrint(uint16_t arg, printArgument_t op) {
	(void)arg;
	(void)op;
}

void printTraceMatElement(uint16_t where) {
	(void)where;
}

void printProgram(bool_t list, uint16_t lines) {
	(void)list;
	(void)lines;
}
#else
bool_t z47_frontier_print_reg_range(uint16_t first_register_no, uint16_t last_register_no) {
	return _printRegRange(first_register_no, last_register_no);
}

uint16_t z47_frontier_current_number_of_local_registers(void) {
	return currentNumberOfLocalRegisters;
}

const char *z47_frontier_sigma_name(uint16_t index) {
	return summationRegisterName[index].name;
}

bool_t z47_frontier_print_exit_pressed(void) {
	return _exitKeyPressed();
}

void z47_frontier_print_sigma_line(uint16_t index) {
	convertRealToResultRegister(statisticalSumsPointer + index, TEMP_REGISTER_1, amNone);
	printReg(TEMP_REGISTER_1, summationRegisterName[index].name, true, LINE_FULL, true);
}

void z47_frontier_print_alpha_register(uint16_t register_no) {
	if(getRegisterDataType(register_no) == dtString) {
		printAlpha(REGISTER_STRING_DATA(register_no), PRINT_ALPHA);
	}
}

uint16_t z47_frontier_x_real_matrix_rows(void) {
	real34Matrix_t x;
	convertReal34MatrixRegisterToReal34Matrix(REGISTER_X, &x);
	return x.header.matrixRows;
}

uint16_t z47_frontier_x_real_matrix_cols(void) {
	real34Matrix_t x;
	convertReal34MatrixRegisterToReal34Matrix(REGISTER_X, &x);
	return x.header.matrixColumns;
}

uint16_t z47_frontier_x_complex_matrix_rows(void) {
	complex34Matrix_t x;
	convertComplex34MatrixRegisterToComplex34Matrix(REGISTER_X, &x);
	return x.header.matrixRows;
}

uint16_t z47_frontier_x_complex_matrix_cols(void) {
	complex34Matrix_t x;
	convertComplex34MatrixRegisterToComplex34Matrix(REGISTER_X, &x);
	return x.header.matrixColumns;
}

void z47_frontier_x_real_matrix_element_to_temp1(uint32_t index) {
	real34Matrix_t x;
	convertReal34MatrixRegisterToReal34Matrix(REGISTER_X, &x);
	reallocateRegister(TEMP_REGISTER_1, dtReal34, REAL34_SIZE_IN_BYTES, amNone);
	real34Copy(&x.matrixElements[index], REGISTER_REAL34_DATA(TEMP_REGISTER_1));
}

void z47_frontier_x_complex_matrix_element_to_temp1(uint32_t index) {
	complex34Matrix_t x;
	convertComplex34MatrixRegisterToComplex34Matrix(REGISTER_X, &x);
	reallocateRegister(TEMP_REGISTER_1, dtComplex34, 0, amNone);
	complex34Copy(&x.matrixElements[index], REGISTER_COMPLEX34_DATA(TEMP_REGISTER_1));
}

void z47_frontier_print_set_printer_sbi(bool_t status) {
	setPrinterSBI(status);
}

uint16_t z47_frontier_print_get_unicode_value(calcRegister_t regist) {
	return _getUnicodeValue(regist);
}

bool_t z47_frontier_named_variable_label(uint16_t index, char *buffer, uint16_t buffer_size) {
	if(index >= numberOfNamedVariables || buffer == NULL || buffer_size == 0) {
		return false;
	}

	uint16_t length = allNamedVariables[index].variableName[0];
	if(length >= buffer_size) {
		length = buffer_size - 1;
	}

	xcopy(buffer, allNamedVariables[index].variableName + 1, length);
	buffer[length] = 0;
	return true;
}

bool_t z47_frontier_user_variable_should_skip(const char *label) {
	if(label == NULL) {
		return true;
	}

	return compareString(label, "STATS", CMP_NAME) == 0 ||
	       compareString(label, "HISTO", CMP_NAME) == 0 ||
	       compareString(label, "Mat_A", CMP_NAME) == 0 ||
	       compareString(label, "Mat_B", CMP_NAME) == 0 ||
	       compareString(label, "Mat_X", CMP_NAME) == 0;
}

calcRegister_t z47_frontier_find_named_variable_register(const char *label) {
	return findNamedVariable(label);
}

uint8_t *z47_frontier_program_begin(void) {
	return beginOfProgramMemory;
}

bool_t z47_frontier_programs_end(uint8_t *step) {
	return isAtEndOfPrograms(step);
}

uint8_t *z47_frontier_program_next_step(uint8_t *step) {
	return findNextStep(step);
}

bool_t z47_frontier_program_global_label(uint8_t *step, char *label, uint16_t label_size) {
	if(step == NULL || label == NULL || label_size == 0) {
		return false;
	}

	if(!checkOpCodeOfStep(step, ITM_LBL)) {
		return false;
	}

	if(*(step + 1) <= LAST_LOCAL_LABEL) {
		return false;
	}

	uint16_t length = *(step + 2);
	if(length >= label_size) {
		length = label_size - 1;
	}
	xcopy(label, step + 3, length);
	label[length] = 0;
	return true;
}

bool_t z47_frontier_program_step_is_end(uint8_t *step) {
	return isAtEndOfProgram(step);
}

const char *z47_frontier_program_label_prefix(void) {
	return "LBL " STD_LEFT_SINGLE_QUOTE;
}

const char *z47_frontier_program_label_suffix(void) {
	return STD_RIGHT_SINGLE_QUOTE;
}

void z47_frontier_print_program_counter(uint16_t program_number, uint16_t total_programs) {
	sprintf(tmpString, "Prgm #" "%" PRIu16 "/" "%" PRIu16 "", program_number, total_programs);
	printJustified(tmpString);
}
#endif

void z47_frontier_format_register_label(uint16_t register_no, char *label, uint16_t label_size) {
	if(label == NULL || label_size == 0) {
		return;
	}

	label[0] = 0;

	if(REGISTER_X <= register_no && register_no <= REGISTER_W) {
		label[0] = letteredRegisterName((calcRegister_t)register_no);
		label[1] = 0;
	}
	else if(register_no < REGISTER_X) {
		snprintf(label, label_size, "R%02u", register_no);
	}
	else if(FIRST_LOCAL_REGISTER <= register_no && register_no <= LAST_LOCAL_REGISTER) {
		snprintf(label, label_size, "R.%03u", register_no - 100);
	}
	else if(FIRST_NAMED_VARIABLE <= register_no && register_no <= LAST_NAMED_VARIABLE) {
		snprintf(label, label_size, "%s", (char *)allNamedVariables[register_no - FIRST_NAMED_VARIABLE].variableName + 1);
	}
	else if(FIRST_NAMED_RESERVED_VARIABLE <= register_no && register_no <= LAST_RESERVED_VARIABLE) {
		snprintf(label, label_size, "%s", (char *)allReservedVariables[register_no - FIRST_RESERVED_VARIABLE].reservedVariableName + 1);
	}
}

const char *z47_frontier_item_catalog_name(uint16_t item) {
	return indexOfItems[item].itemCatalogName;
}

const char *z47_frontier_item_softmenu_name(uint16_t item) {
	return indexOfItems[item].itemSoftmenuName;
}

void z47_frontier_print_backup_aim_message_area(void) {
	xcopy(tmpString, aimBuffer, ERROR_MESSAGE_LENGTH + AIM_BUFFER_LENGTH + NIM_BUFFER_LENGTH);
}

void z47_frontier_print_restore_aim_message_area(void) {
	xcopy(aimBuffer, tmpString, ERROR_MESSAGE_LENGTH + AIM_BUFFER_LENGTH + NIM_BUFFER_LENGTH);
}