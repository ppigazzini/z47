/* This file is part of 43S.
 *
 * 43S is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * 43S is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with 43S.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "wp43.h"

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
