// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

// There is no console on DMCP hardware, so all console output is discarded.
// Defining the console entry points here keeps newlib's buffered stdio (FILE machinery, ~2Kb flash)
// out of the link, and intercepts printing from inside the libraries (gmp, assert).
// sprintf/snprintf still use newlib's string formatter.

#include <stdio.h>

int printf(const char *format, ...) {
  (void)format;
  return 0;
}

int iprintf(const char *format, ...) {
  (void)format;
  return 0;
}

int puts(const char *s) {
  (void)s;
  return 0;
}

int putchar(int c) {
  return c;
}

int fputs(const char *s, FILE *stream) {
  (void)s;
  (void)stream;
  return 0;
}

int fputc(int c, FILE *stream) {
  (void)stream;
  return c;
}

int fprintf(FILE *stream, const char *format, ...) {
  (void)stream;
  (void)format;
  return 0;
}

int fiprintf(FILE *stream, const char *format, ...) {
  (void)stream;
  (void)format;
  return 0;
}

int fflush(FILE *stream) {
  (void)stream;
  return 0;
}

int _fflush_r(struct _reent *reent, FILE *stream) {
  (void)reent;
  (void)stream;
  return 0;
}

// newlib's exit references __stdio_exit_handler, which links findfp.o and its 312 byte __sf FILE array into SRAM2
void exit(int status) {
  (void)status;
  for(;;) {
  }
}
