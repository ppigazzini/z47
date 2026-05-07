// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

#include "c47.h"

void showOneChar(const font_t *font, uint16_t charCode) {
  uint16_t cc;
  int8_t  col, row, bit, byte, *data;

  const glyph_t *glyph;

  for(cc=0; cc<font->numberOfGlyphs; cc++) {
    if(font->glyphs[cc].charCode == charCode) {
      glyph = font->glyphs + cc;

      for(col=0; col<glyph->colsBeforeGlyph + glyph->colsGlyph  + glyph->colsAfterGlyph + 2; col++) {
        putchar('+');
      }
      putchar('\n');

      data = (int8_t *)(glyph->data);

      for(row=0; row<glyph->rowsAboveGlyph; row++) {
        putchar('+');
        for(col=0; col<glyph->colsBeforeGlyph+glyph->colsGlyph+glyph->colsAfterGlyph; col++) {
         putchar(' ');
        }
        putchar('+');
        putchar('\n');
      }

      for(row=0; row<glyph->rowsGlyph; row++) {
        putchar('+');

        for(col=0; col<glyph->colsBeforeGlyph; col++) {
          putchar(' ');
        }

        bit = 7;
        for(col=0; col<glyph->colsGlyph; col++) {
          if(bit == 7) {
            byte = *(data++);
          }

          if(byte & 0x80) { // MSB set
            putchar('#');
          }
          else {
            putchar(' ');
          }

          byte <<= 1;

          if(--bit == -1) {
            bit = 7;
          }
        }

        for(col=0; col<glyph->colsAfterGlyph; col++) {
          putchar(' ');
        }

        putchar('+');
        putchar('\n');
      }

      for(row=0; row<glyph->rowsBelowGlyph; row++) {
        putchar('+');
        for(col=0; col<glyph->colsBeforeGlyph+glyph->colsGlyph+glyph->colsAfterGlyph; col++) {
          putchar(' ');
        }
        putchar('+');
        putchar('\n');
      }

      for(col=0; col<glyph->colsBeforeGlyph + glyph->colsGlyph  + glyph->colsAfterGlyph + 2; col++) {
        putchar('+');
      }
      putchar('\n');

      break;
    }
  }
}

int main(void) {
  printf("sizeof(int8_t  ) =%3ld bits\n", 8L * (long)sizeof(int8_t));
  printf("sizeof(uint16_t) =%3ld bits\n", 8L * (long)sizeof(uint16_t));

  if(sizeof(int8_t) != 1 || sizeof(uint16_t) != 2) {
    fprintf(stderr, "Type int8_t must be 8 bit, type uint_16 must be 16 bit and pointer must be 32 bit!\n");
    exit(1);
  }

  printf("Size of types are OK\n");

  showOneChar(&numericFont,  0x0038);
  showOneChar(&numericFont,  0x0040);
  showOneChar(&numericFont,  0x0020);
  showOneChar(&numericFont,  0x80c0);
  showOneChar(&standardFont, 0x0038);
  showOneChar(&standardFont, 0x0040);
  showOneChar(&standardFont, 0x0020);
  showOneChar(&standardFont, 0x0032);
  showOneChar(&standardFont, 0xa3e9);
  showOneChar(&tinyFont,     0x0038);
  showOneChar(&tinyFont,     0x0040);
  showOneChar(&tinyFont,     0x0020);
  showOneChar(&tinyFont,     0x0032);
  showOneChar(&tinyFont,     0xa3e9);

  return 0;
}
