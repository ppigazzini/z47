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

/********************************************//**
 * \file fontBrowser.c
 ***********************************************/

#include "browsers/fontBrowser.h"

#include <stdlib.h>

#include "charString.h"
#include "error.h"
#include "flags.h"
#include "fonts.h"
#include "screen.h"

#include "wp43.h"
#include <stdlib.h>


#if !defined(TESTSUITE_BUILD)
  //TO_QSPI static const char bugScreenShowFonts[] = "In function showFonts: This should never happen!";

  /********************************************//**
   * \brief The font browser application initialisation
   *
   * \param[in] unusedButMandatoryParameter uint16_t
   * \return void
   ***********************************************/
  void initFontBrowser(void) {
    uint16_t g;

    numLinesNumericFont  = 0;
    for(g=0; g<numericFont.numberOfGlyphs;) {
      glyphRow[numLinesNumericFont] = numericFont.glyphs[g].charCode & 0xfff0;
      while(g<numericFont.numberOfGlyphs && ((numericFont.glyphs[g].charCode&0xfff0) == glyphRow[numLinesNumericFont])) {
        g++;
      }
      numLinesNumericFont++;
    }

    numScreensNumericFont = numLinesNumericFont / NUMBER_OF_NUMERIC_FONT_LINES_PER_SCREEN;
    if(numLinesNumericFont % NUMBER_OF_NUMERIC_FONT_LINES_PER_SCREEN != 0) {
      numScreensNumericFont++;
    }
    //printf(">>>> @@ numeric font screens %i\n", numScreensNumericFont);

    numLinesStandardFont  = 0;
    for(g=0; g<standardFont.numberOfGlyphs;) {
      glyphRow[numLinesNumericFont + numLinesStandardFont] = standardFont.glyphs[g].charCode & 0xfff0;
      while(g<standardFont.numberOfGlyphs && ((standardFont.glyphs[g].charCode&0xfff0) == glyphRow[numLinesNumericFont + numLinesStandardFont])) {
        g++;
      }
      numLinesStandardFont++;
    }

    numScreensStandardFont = numLinesStandardFont / NUMBER_OF_STANDARD_FONT_LINES_PER_SCREEN;
    if(numLinesStandardFont % NUMBER_OF_STANDARD_FONT_LINES_PER_SCREEN != 0) {
      numScreensStandardFont++;
    }
    //printf(">>>> @@ standard font screens %i\n", numScreensStandardFont);

    numLinesTinyFont  = 0;
    for(g=0; g<tinyFont.numberOfGlyphs;) {
      glyphRow[numLinesNumericFont + numLinesStandardFont + numLinesTinyFont] = tinyFont.glyphs[g].charCode & 0xfff0;
      while(g<tinyFont.numberOfGlyphs && ((tinyFont.glyphs[g].charCode&0xfff0) == glyphRow[numLinesNumericFont + numLinesStandardFont + numLinesTinyFont])) {
        g++;
      }
      numLinesTinyFont++;
    }

    numScreensTinyFont = numLinesTinyFont / NUMBER_OF_STANDARD_FONT_LINES_PER_SCREEN;
    if(numLinesTinyFont % NUMBER_OF_STANDARD_FONT_LINES_PER_SCREEN != 0) {
      numScreensTinyFont++;
    }
    //printf(">>>> @@ tiny font screens %i\n", numScreensTinyFont);

    currentFntScr = 1;

    #if defined(PC_BUILD)
      if(numLinesNumericFont + numLinesStandardFont + numLinesTinyFont > NUMBER_OF_GLYPH_ROWS) {
        printf("In file defines.h NUMBER_OF_GLYPH_ROWS must be increased from %d to %d\n", NUMBER_OF_GLYPH_ROWS, numLinesNumericFont + numLinesStandardFont + numLinesTinyFont);
        exit(-1);
      }
    #endif // PC_BUILD
  }


  /********************************************//**
   * \brief The font browser application
   *
   * \param[in] unusedButMandatoryParameter uint16_t
   * \return void
   ***********************************************/
  void fontBrowser(uint16_t unusedButMandatoryParameter) {
  #if !defined(SAVE_SPACE_DM42_8)

    uint16_t x, y, first;

    hourGlassIconEnabled = false;

    if(calcMode != CM_FONT_BROWSER) {
      previousCalcMode = calcMode;
      calcMode = CM_FONT_BROWSER;
      clearSystemFlag(FLAG_ALPHA);
      return;
    }

    if(currentFntScr>=1 && currentFntScr<=numScreensNumericFont) { // Numeric font
      //printf("Numeric  font currentFntScr=%2u\n", currentFntScr);
      for(x=0; x<=9; x++) {
        showGlyphCode('0'+x, &standardFont, 50+20*x,     20, vmNormal, false, false);
      }
      for(x=0; x<=5; x++) {
        showGlyphCode('A'+x, &standardFont, 50+200+20*x, 20, vmNormal, false, false);
      }

      first = (currentFntScr-1) * NUMBER_OF_NUMERIC_FONT_LINES_PER_SCREEN;
      for(y=first; y<min(currentFntScr * NUMBER_OF_NUMERIC_FONT_LINES_PER_SCREEN, numLinesNumericFont); y++) {
        sprintf(tmpString, "%04X", glyphRow[y]<0x8000 ? glyphRow[y] : glyphRow[y]-0x8000);
        showString(tmpString, &standardFont, 5, NUMERIC_FONT_HEIGHT*(y-first)+43, vmNormal, false, false);
        for(x=0; x<=15; x++) {
          showGlyphCode(glyphRow[y]+x, &numericFont, 46+20*x, NUMERIC_FONT_HEIGHT*(y-first)+40, vmNormal, false, false);
        }
      }

      if(currentFntScr == 1) {
        showString("Numeric font. Press " STD_DOWN_ARROW " or EXIT", &standardFont, 5, 220, vmNormal, false, false);
      }
      else {
        showString("Numeric font. Press " STD_UP_ARROW ", " STD_DOWN_ARROW " or EXIT", &standardFont, 5, 220, vmNormal, false, false);
      }

      sprintf(tmpString, "%d/%d", currentFntScr, numScreensNumericFont+numScreensStandardFont+numScreensTinyFont);
      showString(tmpString, &standardFont, SCREEN_WIDTH - stringWidth(tmpString, &standardFont, false, true), 220, vmNormal, false, true);
    }

    else if(currentFntScr>numScreensNumericFont && currentFntScr<=numScreensNumericFont+numScreensStandardFont) { // Standard font
      //printf("Standard font currentFntScr=%2u\n", currentFntScr);
      for(x=0; x<=9; x++) {
        showGlyphCode('0'+x, &standardFont, 50+20*x,     20, vmNormal, false, false);
      }
      for(x=0; x<=5; x++) {
        showGlyphCode('A'+x, &standardFont, 50+200+20*x, 20, vmNormal, false, false);
      }

      first = numLinesNumericFont + (currentFntScr-numScreensNumericFont-1) * NUMBER_OF_STANDARD_FONT_LINES_PER_SCREEN;
      for(y=first; y<min(numLinesNumericFont + (currentFntScr-numScreensNumericFont) * NUMBER_OF_STANDARD_FONT_LINES_PER_SCREEN, numLinesNumericFont+numLinesStandardFont); y++) {
        sprintf(tmpString, "%04X", glyphRow[y]<0x8000 ? glyphRow[y] : glyphRow[y]-0x8000);
        showString(tmpString, &standardFont, 5, STANDARD_FONT_HEIGHT*(y-first)+40, vmNormal, false, false);
        for(x=0; x<=15; x++) {
          showGlyphCode(glyphRow[y]+x, &standardFont, 50+20*x, STANDARD_FONT_HEIGHT*(y-first)+40, vmNormal, false, false);
        }
      }

      if(currentFntScr == numScreensNumericFont+numScreensStandardFont+numScreensTinyFont) {
        showString("Standard font. Press " STD_UP_ARROW " or EXIT", &standardFont, 5, 220, vmNormal, false, false);
      }
      else {
        showString("Standard font. Press " STD_UP_ARROW ", " STD_DOWN_ARROW " or EXIT", &standardFont, 5, 220, vmNormal, false, false);
      }

      sprintf(tmpString, "%d/%d", currentFntScr, numScreensNumericFont+numScreensStandardFont+numScreensTinyFont);
      showString(tmpString, &standardFont, SCREEN_WIDTH-stringWidth(tmpString, &standardFont, false, true), 220, vmNormal, false, true);
    }

    else if(currentFntScr>numScreensNumericFont+numScreensStandardFont && currentFntScr<=numScreensNumericFont+numScreensStandardFont+numScreensTinyFont) { // Tiny font
      //printf("Tiny     font currentFntScr=%2u\n", currentFntScr);
      for(x=0; x<=9; x++) {
        showGlyphCode('0'+x, &standardFont, 50+20*x,     20, vmNormal, false, false);
      }
      for(x=0; x<=5; x++) {
        showGlyphCode('A'+x, &standardFont, 50+200+20*x, 20, vmNormal, false, false);
      }

      first = numLinesNumericFont + numLinesStandardFont + (currentFntScr-numScreensNumericFont-numScreensStandardFont-1) * NUMBER_OF_STANDARD_FONT_LINES_PER_SCREEN;
      for(y=first; y<min(numLinesNumericFont + numLinesStandardFont + (currentFntScr-numScreensNumericFont-numScreensStandardFont) * NUMBER_OF_STANDARD_FONT_LINES_PER_SCREEN, numLinesNumericFont+numLinesStandardFont+numLinesTinyFont); y++) {
        sprintf(tmpString, "%04X", glyphRow[y]<0x8000 ? glyphRow[y] : glyphRow[y]-0x8000);
        showString(tmpString, &standardFont, 5, STANDARD_FONT_HEIGHT*(y-first)+40, vmNormal, false, false);
        for(x=0; x<=15; x++) {
          showGlyphCode(glyphRow[y]+x, &tinyFont, 52+20*x, STANDARD_FONT_HEIGHT*(y-first)+46, vmNormal, false, false);
        }
      }

      if(currentFntScr == numScreensNumericFont+numScreensStandardFont+numScreensTinyFont) {
        showString("Tiny font. Press " STD_UP_ARROW " or EXIT", &standardFont, 5, 220, vmNormal, false, false);
      }
      else {
        showString("Tiny font. Press " STD_UP_ARROW ", " STD_DOWN_ARROW " or EXIT", &standardFont, 5, 220, vmNormal, false, false);
      }

      sprintf(tmpString, "%d/%d", currentFntScr, numScreensNumericFont+numScreensStandardFont+numScreensTinyFont);
      showString(tmpString, &standardFont, SCREEN_WIDTH-stringWidth(tmpString, &standardFont, false, true), 220, vmNormal, false, true);
    }

    else {
      //displayBugScreen(bugScreenShowFonts);
    }
  #endif // !SAVE_SPACE_DM42_8
  }
#endif // !TESTSUITE_BUILD
