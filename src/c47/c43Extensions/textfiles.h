// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/* ADDITIONAL C43 functions and routines */


/********************************************//** //JM
 * \file jmgraph.c TEXTFILES module
 ***********************************************/

#if !defined(TEXTFILES_H)
#define TEXTFILES_H

#include "defines.h"
#include "typeDefinitions.h"
#include <stdint.h>

#define ONELINE true

void         print_inlinestr(const char *line1, bool_t endline);
void         print_Register_line(calcRegister_t regist, char *before, char *after, bool_t line_init);
void         displaywords(char *line1);
int16_t      export_string_to_file(const char line1[TMP_STR_LENGTH]);
void         stackregister_csv_out(int16_t reg_b, int16_t reg_e, bool_t oneLine);
void         aimBuffer_csv_out(void);
void         copyRegisterToClipboardString2(calcRegister_t regist, char *clipboardString);

#endif // !TEXTFILES_H
