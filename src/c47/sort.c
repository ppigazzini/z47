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

#include "sort.h"

#include "charString.h"
#include "fonts.h"

#include "c47.h"



int32_t compareChar(const char *char1, const char *char2) {
  int16_t code1 = (char1[0] & 0x80) ? ((((uint16_t)(char1[0] & 0x7f)) << 8) | (uint16_t)((uint8_t)(char1)[1])) : char1[0];
  int16_t code2 = (char2[0] & 0x80) ? ((((uint16_t)(char2[0] & 0x7f)) << 8) | (uint16_t)((uint8_t)(char2)[1])) : char2[0];
  return (int32_t)code1 - (int32_t)code2;
}



#define GLYPH_TO_CHAR_CODE(x) (((uint16_t)((uint8_t)(x[0])) << 8) + (uint8_t)(x[1]))

static TO_QSPI struct {
  uint16_t low;
  uint8_t num;
  char base;
} unSupSubRanges[] = {
#define UNSUBRANGE(a, b, c) { GLYPH_TO_CHAR_CODE(a), GLYPH_TO_CHAR_CODE(b) - GLYPH_TO_CHAR_CODE(a) + 1, c }
  UNSUBRANGE(STD_SUP_A, STD_SUP_Z, 'A'),
  UNSUBRANGE(STD_SUP_a, STD_SUP_z, 'a'),
  UNSUBRANGE(STD_SUP_0, STD_SUP_9, '0'),
  UNSUBRANGE(STD_SUB_A, STD_SUB_Z, 'A'),
  UNSUBRANGE(STD_SUB_a, STD_SUB_z, 'a'),
  UNSUBRANGE(STD_SUB_0, STD_SUB_9, '0')
#undef UNSUBRANGE
};

static TO_QSPI uint16_t unSupSubTable[] = {
  GLYPH_TO_CHAR_CODE(STD_SUP_PLUS),     (uint16_t)'+',
  GLYPH_TO_CHAR_CODE(STD_SUP_MINUS),    (uint16_t)'-',
  GLYPH_TO_CHAR_CODE(STD_SUP_INFINITY), GLYPH_TO_CHAR_CODE(STD_INFINITY),

  GLYPH_TO_CHAR_CODE(STD_SUP_ASTERISK), (uint16_t)'*',

  GLYPH_TO_CHAR_CODE(STD_SUB_PLUS),     (uint16_t)'+',
  GLYPH_TO_CHAR_CODE(STD_SUB_MINUS),    (uint16_t)'-',
  GLYPH_TO_CHAR_CODE(STD_SUB_INFINITY), GLYPH_TO_CHAR_CODE(STD_INFINITY),

  GLYPH_TO_CHAR_CODE(STD_SUB_alpha),    GLYPH_TO_CHAR_CODE(STD_alpha),
  GLYPH_TO_CHAR_CODE(STD_SUB_delta),    GLYPH_TO_CHAR_CODE(STD_delta),
  GLYPH_TO_CHAR_CODE(STD_SUB_mu),       GLYPH_TO_CHAR_CODE(STD_mu),
  GLYPH_TO_CHAR_CODE(STD_SUB_SUN),      GLYPH_TO_CHAR_CODE(STD_SUN),
};

static uint16_t _charCodeUnSupSub(uint16_t charCode) {
  for(unsigned int i = 0; i < NELEM(unSupSubRanges); i++)
    if(charCode >= unSupSubRanges[i].low && charCode < unSupSubRanges[i].low + unSupSubRanges[i].num)
      return charCode - unSupSubRanges[i].low + unSupSubRanges[i].base;

  for(unsigned int i = 0; i < NELEM(unSupSubTable); i += 2) {
    if(charCode == unSupSubTable[i]) {
      return unSupSubTable[i + 1];
    }
  }
  return charCode;
}
#undef GLYPH_TO_CHAR_CODE

int32_t compareString(const char *stra, const char *strb, int32_t comparisonType) {
  int32_t lga, lgb, i;
  int16_t posa, posb, ranka, rankb;
  uint16_t charCode;

  lga = stringGlyphLength(stra);
  lgb = stringGlyphLength(strb);

  // Compare the string using charCode only
  if(comparisonType == CMP_BINARY || comparisonType == CMP_NAME) {
    posa = 0;
    posb = 0;
    for(i=0; i<min(lga, lgb); i++) {
      charCode = (uint8_t)stra[posa];
      if(charCode >= 0x80) {
        charCode = (charCode << 8) + (uint8_t)stra[posa + 1];
      }
      if(comparisonType == CMP_NAME) {
        charCode = _charCodeUnSupSub(charCode);
      }
      ranka = charCode;

      charCode = (uint8_t)strb[posb];
      if(charCode >= 0x80) {
        charCode = (charCode << 8) + (uint8_t)strb[posb + 1];
      }
      if(comparisonType == CMP_NAME) {
        charCode = _charCodeUnSupSub(charCode);
      }
      rankb = charCode;

      if(ranka < rankb) {
        return -1;
      }
      if(ranka > rankb) {
        return 1;
      }

      posa = stringNextGlyph(stra, posa);
      posb = stringNextGlyph(strb, posb);
    }

    if(lga < lgb) {
      return -1;
    }
    if(lga > lgb) {
      return 1;
    }
    return 0;
  }

  // Compare the string using replacement glyphs
  posa = 0;
  posb = 0;
  for(i=0; i<min(lga, lgb); i++) {
    charCode = (uint8_t)stra[posa];
    if(charCode >= 0x80) {
      charCode = (charCode << 8) + (uint8_t)stra[posa + 1];
    }
    ranka = standardFont.glyphs[findGlyph(&standardFont, charCode)].rank1;

    charCode = (uint8_t)strb[posb];
    if(charCode >= 0x80) {
      charCode = (charCode << 8) + (uint8_t)strb[posb + 1];
    }
    rankb = standardFont.glyphs[findGlyph(&standardFont, charCode)].rank1;

    if(ranka < rankb) {
      return -1;
    }
    if(ranka > rankb) {
      return 1;
    }

    posa = stringNextGlyph(stra, posa);
    posb = stringNextGlyph(strb, posb);
  }

  if(lga < lgb) {
    return -1;
  }
  if(lga > lgb) {
    return 1;
  }

  // The strings using replacement glyphs are equal: comparing the original strings
  if(comparisonType == CMP_EXTENSIVE) {
    posa = 0;
    posb = 0;
    for(i=0; i<min(lga, lgb); i++) {
      charCode = (uint8_t)stra[posa];
      if(charCode >= 0x80) {
        charCode = (charCode << 8) + (uint8_t)stra[posa + 1];
      }
      ranka = standardFont.glyphs[findGlyph(&standardFont, charCode)].rank2;

      charCode = (uint8_t)strb[posb];
      if(charCode >= 0x80) {
        charCode = (charCode << 8) + (uint8_t)strb[posb + 1];
      }
      rankb = standardFont.glyphs[findGlyph(&standardFont, charCode)].rank2;

      if(ranka < rankb) {
        return -1;
      }
      if(ranka > rankb) {
        return 1;
      }

      posa = stringNextGlyph(stra, posa);
      posb = stringNextGlyph(strb, posb);
    }

    if(lga < lgb) {
      return -1;
    }
    if(lga > lgb) {
      return 1;
    }
  }

  return 0;
}
