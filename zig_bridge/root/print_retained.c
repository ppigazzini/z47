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
#define fnP_LCD z47_frontier_retained_fnP_LCD
#include "../../src/c47/printing/print.c"

void z47_frontier_print_set_printer_sbi(bool_t status) {
	setPrinterSBI(status);
}

uint16_t z47_frontier_print_get_unicode_value(calcRegister_t regist) {
	return _getUnicodeValue(regist);
}