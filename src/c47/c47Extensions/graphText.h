// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors



#if !defined(GRAPHTEXT_H)
#define GRAPHTEXT_H

#include "defines.h"
#include "typeDefinitions.h"
#include <stdint.h>

#define      CSV_NEWLINE "\n"
#define      CSV_TAB     "\t"
#define      CSV_CR      "\r"
#define      CSV_SLASH   "\\"
#define      CSV_STR     "\""
#define      T_CR        "\x0D"
#define      APPEND      0
#define      OVERWRITE   1
#define      OPEN        2
#define      CLOSE       3
#define      WRITE       4
#define      NOACTION    5

void         create_filename(char *fn);

int16_t      export_append_line(const char *inputstring);
int16_t      export_string_to_filename(const char line1[TMP_STR_LENGTH], uint8_t mode, const char *dirname, const char *filename);
#if defined(DMCP_BUILD)
  int16_t open_text(const char *dirname, const char *dirfile);
  int16_t close_text(const char *dirfile);
  int16_t save_text(const char *line1, uint8_t mode1, uint8_t mode2, uint8_t mode3, int16_t  nn, const char *dirfile);
#endif // DMCP_BUILD

#define      filenamelen 40
extern char         filename_csv[filenamelen]; //JMMAX                //JM_CSV
extern uint32_t     mem__32;                                          //JM_CSV
extern bool_t       cancelFilename;
void         printStatus    (uint8_t row, const char *line1, uint8_t forced);
void         print_numberstr(const char *line1, bool_t line_init);
void         print_linestr  (const char *line1, bool_t line_init);
int16_t      export_xy_to_file(float x, float y);
int16_t      import_string_from_filename(char *line1,  char *dirname,   char *filename_short,  char *filename,  char *fallback, bool_t scanning);

#endif // !GRAPHTEXT_H
