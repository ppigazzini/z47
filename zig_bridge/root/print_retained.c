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
#include "../../src/c47/printing/print.c"

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

void z47_frontier_print_set_printer_sbi(bool_t status) {
	setPrinterSBI(status);
}

uint16_t z47_frontier_print_get_unicode_value(calcRegister_t regist) {
	return _getUnicodeValue(regist);
}