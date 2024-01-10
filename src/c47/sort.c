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

TO_QSPI uint16_t unSupSubTable[] = {
  GLYPH_TO_CHAR_CODE(STD_SUP_A),        (uint16_t)'A',
  GLYPH_TO_CHAR_CODE(STD_SUP_B),        (uint16_t)'B',
  GLYPH_TO_CHAR_CODE(STD_SUP_C),        (uint16_t)'C',
  GLYPH_TO_CHAR_CODE(STD_SUP_D),        (uint16_t)'D',
  GLYPH_TO_CHAR_CODE(STD_SUP_E),        (uint16_t)'E',
  GLYPH_TO_CHAR_CODE(STD_SUP_F),        (uint16_t)'F',
  GLYPH_TO_CHAR_CODE(STD_SUP_G),        (uint16_t)'G',
  GLYPH_TO_CHAR_CODE(STD_SUP_H),        (uint16_t)'H',
  GLYPH_TO_CHAR_CODE(STD_SUP_I),        (uint16_t)'I',
  GLYPH_TO_CHAR_CODE(STD_SUP_J),        (uint16_t)'J',
  GLYPH_TO_CHAR_CODE(STD_SUP_K),        (uint16_t)'K',
  GLYPH_TO_CHAR_CODE(STD_SUP_L),        (uint16_t)'L',
  GLYPH_TO_CHAR_CODE(STD_SUP_M),        (uint16_t)'M',
  GLYPH_TO_CHAR_CODE(STD_SUP_N),        (uint16_t)'N',
  GLYPH_TO_CHAR_CODE(STD_SUP_O),        (uint16_t)'O',
  GLYPH_TO_CHAR_CODE(STD_SUP_P),        (uint16_t)'P',
  GLYPH_TO_CHAR_CODE(STD_SUP_Q),        (uint16_t)'Q',
  GLYPH_TO_CHAR_CODE(STD_SUP_R),        (uint16_t)'R',
  GLYPH_TO_CHAR_CODE(STD_SUP_S),        (uint16_t)'S',
  GLYPH_TO_CHAR_CODE(STD_SUP_T),        (uint16_t)'T',
  GLYPH_TO_CHAR_CODE(STD_SUP_U),        (uint16_t)'U',
  GLYPH_TO_CHAR_CODE(STD_SUP_V),        (uint16_t)'V',
  GLYPH_TO_CHAR_CODE(STD_SUP_W),        (uint16_t)'W',
  GLYPH_TO_CHAR_CODE(STD_SUP_X),        (uint16_t)'X',
  GLYPH_TO_CHAR_CODE(STD_SUP_Y),        (uint16_t)'Y',
  GLYPH_TO_CHAR_CODE(STD_SUP_Z),        (uint16_t)'Z',

  GLYPH_TO_CHAR_CODE(STD_SUP_a),        (uint16_t)'a',
  GLYPH_TO_CHAR_CODE(STD_SUP_b),        (uint16_t)'b',
  GLYPH_TO_CHAR_CODE(STD_SUP_c),        (uint16_t)'c',
  GLYPH_TO_CHAR_CODE(STD_SUP_d),        (uint16_t)'d',
  GLYPH_TO_CHAR_CODE(STD_SUP_e),        (uint16_t)'e',
  GLYPH_TO_CHAR_CODE(STD_SUP_f),        (uint16_t)'f',
  GLYPH_TO_CHAR_CODE(STD_SUP_g),        (uint16_t)'g',
  GLYPH_TO_CHAR_CODE(STD_SUP_h),        (uint16_t)'h',
  GLYPH_TO_CHAR_CODE(STD_SUP_i),        (uint16_t)'i',
  GLYPH_TO_CHAR_CODE(STD_SUP_j),        (uint16_t)'j',
  GLYPH_TO_CHAR_CODE(STD_SUP_k),        (uint16_t)'k',
  GLYPH_TO_CHAR_CODE(STD_SUP_l),        (uint16_t)'l',
  GLYPH_TO_CHAR_CODE(STD_SUP_m),        (uint16_t)'m',
  GLYPH_TO_CHAR_CODE(STD_SUP_n),        (uint16_t)'n',
  GLYPH_TO_CHAR_CODE(STD_SUP_o),        (uint16_t)'o',
  GLYPH_TO_CHAR_CODE(STD_SUP_p),        (uint16_t)'p',
  GLYPH_TO_CHAR_CODE(STD_SUP_q),        (uint16_t)'q',
  GLYPH_TO_CHAR_CODE(STD_SUP_r),        (uint16_t)'r',
  GLYPH_TO_CHAR_CODE(STD_SUP_s),        (uint16_t)'s',
  GLYPH_TO_CHAR_CODE(STD_SUP_t),        (uint16_t)'t',
  GLYPH_TO_CHAR_CODE(STD_SUP_u),        (uint16_t)'u',
  GLYPH_TO_CHAR_CODE(STD_SUP_v),        (uint16_t)'v',
  GLYPH_TO_CHAR_CODE(STD_SUP_w),        (uint16_t)'w',
  GLYPH_TO_CHAR_CODE(STD_SUP_x),        (uint16_t)'x',
  GLYPH_TO_CHAR_CODE(STD_SUP_y),        (uint16_t)'y',
  GLYPH_TO_CHAR_CODE(STD_SUP_z),        (uint16_t)'z',

  GLYPH_TO_CHAR_CODE(STD_SUP_0),        (uint16_t)'0',
  GLYPH_TO_CHAR_CODE(STD_SUP_1),        (uint16_t)'1',
  GLYPH_TO_CHAR_CODE(STD_SUP_2),        (uint16_t)'2',
  GLYPH_TO_CHAR_CODE(STD_SUP_3),        (uint16_t)'3',
  GLYPH_TO_CHAR_CODE(STD_SUP_4),        (uint16_t)'4',
  GLYPH_TO_CHAR_CODE(STD_SUP_5),        (uint16_t)'5',
  GLYPH_TO_CHAR_CODE(STD_SUP_6),        (uint16_t)'6',
  GLYPH_TO_CHAR_CODE(STD_SUP_7),        (uint16_t)'7',
  GLYPH_TO_CHAR_CODE(STD_SUP_8),        (uint16_t)'8',
  GLYPH_TO_CHAR_CODE(STD_SUP_9),        (uint16_t)'9',

  GLYPH_TO_CHAR_CODE(STD_SUP_PLUS),     (uint16_t)'+',
  GLYPH_TO_CHAR_CODE(STD_SUP_MINUS),    (uint16_t)'-',
  GLYPH_TO_CHAR_CODE(STD_SUP_INFINITY), GLYPH_TO_CHAR_CODE(STD_INFINITY),

  GLYPH_TO_CHAR_CODE(STD_SUP_ASTERISK), (uint16_t)'*',

  GLYPH_TO_CHAR_CODE(STD_SUB_A),        (uint16_t)'A',
  GLYPH_TO_CHAR_CODE(STD_SUB_B),        (uint16_t)'B',
  GLYPH_TO_CHAR_CODE(STD_SUB_C),        (uint16_t)'C',
  GLYPH_TO_CHAR_CODE(STD_SUB_D),        (uint16_t)'D',
  GLYPH_TO_CHAR_CODE(STD_SUB_E),        (uint16_t)'E',
  GLYPH_TO_CHAR_CODE(STD_SUB_F),        (uint16_t)'F',
  GLYPH_TO_CHAR_CODE(STD_SUB_G),        (uint16_t)'G',
  GLYPH_TO_CHAR_CODE(STD_SUB_H),        (uint16_t)'H',
  GLYPH_TO_CHAR_CODE(STD_SUB_I),        (uint16_t)'I',
  GLYPH_TO_CHAR_CODE(STD_SUB_J),        (uint16_t)'J',
  GLYPH_TO_CHAR_CODE(STD_SUB_K),        (uint16_t)'K',
  GLYPH_TO_CHAR_CODE(STD_SUB_L),        (uint16_t)'L',
  GLYPH_TO_CHAR_CODE(STD_SUB_M),        (uint16_t)'M',
  GLYPH_TO_CHAR_CODE(STD_SUB_N),        (uint16_t)'N',
  GLYPH_TO_CHAR_CODE(STD_SUB_O),        (uint16_t)'O',
  GLYPH_TO_CHAR_CODE(STD_SUB_P),        (uint16_t)'P',
  GLYPH_TO_CHAR_CODE(STD_SUB_Q),        (uint16_t)'Q',
  GLYPH_TO_CHAR_CODE(STD_SUB_R),        (uint16_t)'R',
  GLYPH_TO_CHAR_CODE(STD_SUB_S),        (uint16_t)'S',
  GLYPH_TO_CHAR_CODE(STD_SUB_T),        (uint16_t)'T',
  GLYPH_TO_CHAR_CODE(STD_SUB_U),        (uint16_t)'U',
  GLYPH_TO_CHAR_CODE(STD_SUB_V),        (uint16_t)'V',
  GLYPH_TO_CHAR_CODE(STD_SUB_W),        (uint16_t)'W',
  GLYPH_TO_CHAR_CODE(STD_SUB_X),        (uint16_t)'X',
  GLYPH_TO_CHAR_CODE(STD_SUB_Y),        (uint16_t)'Y',
  GLYPH_TO_CHAR_CODE(STD_SUB_Z),        (uint16_t)'Z',

  GLYPH_TO_CHAR_CODE(STD_SUB_a),        (uint16_t)'a',
  GLYPH_TO_CHAR_CODE(STD_SUB_b),        (uint16_t)'b',
  GLYPH_TO_CHAR_CODE(STD_SUB_c),        (uint16_t)'c',
  GLYPH_TO_CHAR_CODE(STD_SUB_d),        (uint16_t)'d',
  GLYPH_TO_CHAR_CODE(STD_SUB_f),        (uint16_t)'e',
  GLYPH_TO_CHAR_CODE(STD_SUB_g),        (uint16_t)'f',
  GLYPH_TO_CHAR_CODE(STD_SUB_e),        (uint16_t)'g',
  GLYPH_TO_CHAR_CODE(STD_SUB_h),        (uint16_t)'h',
  GLYPH_TO_CHAR_CODE(STD_SUB_i),        (uint16_t)'i',
  GLYPH_TO_CHAR_CODE(STD_SUB_j),        (uint16_t)'j',
  GLYPH_TO_CHAR_CODE(STD_SUB_k),        (uint16_t)'k',
  GLYPH_TO_CHAR_CODE(STD_SUB_l),        (uint16_t)'l',
  GLYPH_TO_CHAR_CODE(STD_SUB_m),        (uint16_t)'m',
  GLYPH_TO_CHAR_CODE(STD_SUB_n),        (uint16_t)'n',
  GLYPH_TO_CHAR_CODE(STD_SUB_o),        (uint16_t)'o',
  GLYPH_TO_CHAR_CODE(STD_SUB_p),        (uint16_t)'p',
  GLYPH_TO_CHAR_CODE(STD_SUB_q),        (uint16_t)'q',
  GLYPH_TO_CHAR_CODE(STD_SUB_r),        (uint16_t)'r',
  GLYPH_TO_CHAR_CODE(STD_SUB_s),        (uint16_t)'s',
  GLYPH_TO_CHAR_CODE(STD_SUB_t),        (uint16_t)'t',
  GLYPH_TO_CHAR_CODE(STD_SUB_u),        (uint16_t)'u',
  GLYPH_TO_CHAR_CODE(STD_SUB_v),        (uint16_t)'v',
  GLYPH_TO_CHAR_CODE(STD_SUB_w),        (uint16_t)'w',
  GLYPH_TO_CHAR_CODE(STD_SUB_x),        (uint16_t)'x',
  GLYPH_TO_CHAR_CODE(STD_SUB_y),        (uint16_t)'y',
  GLYPH_TO_CHAR_CODE(STD_SUB_z),        (uint16_t)'z',

  GLYPH_TO_CHAR_CODE(STD_SUB_0),        (uint16_t)'0',
  GLYPH_TO_CHAR_CODE(STD_SUB_1),        (uint16_t)'1',
  GLYPH_TO_CHAR_CODE(STD_SUB_2),        (uint16_t)'2',
  GLYPH_TO_CHAR_CODE(STD_SUB_3),        (uint16_t)'3',
  GLYPH_TO_CHAR_CODE(STD_SUB_4),        (uint16_t)'4',
  GLYPH_TO_CHAR_CODE(STD_SUB_5),        (uint16_t)'5',
  GLYPH_TO_CHAR_CODE(STD_SUB_6),        (uint16_t)'6',
  GLYPH_TO_CHAR_CODE(STD_SUB_7),        (uint16_t)'7',
  GLYPH_TO_CHAR_CODE(STD_SUB_8),        (uint16_t)'8',
  GLYPH_TO_CHAR_CODE(STD_SUB_9),        (uint16_t)'9',

  GLYPH_TO_CHAR_CODE(STD_SUB_PLUS),     (uint16_t)'+',
  GLYPH_TO_CHAR_CODE(STD_SUB_MINUS),    (uint16_t)'-',
  GLYPH_TO_CHAR_CODE(STD_SUB_INFINITY), GLYPH_TO_CHAR_CODE(STD_INFINITY),

  GLYPH_TO_CHAR_CODE(STD_SUB_alpha),    GLYPH_TO_CHAR_CODE(STD_alpha),
  GLYPH_TO_CHAR_CODE(STD_SUB_delta),    GLYPH_TO_CHAR_CODE(STD_delta),
  GLYPH_TO_CHAR_CODE(STD_SUB_mu),       GLYPH_TO_CHAR_CODE(STD_mu),
  GLYPH_TO_CHAR_CODE(STD_SUB_SUN),      GLYPH_TO_CHAR_CODE(STD_SUN),

  0,                                    0
};

static uint16_t _charCodeUnSupSub(uint16_t charCode) {
  for(int i = 0; unSupSubTable[i] != 0; i += 2) {
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
