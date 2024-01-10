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
 * \file flagBrowser.c
 ***********************************************/

#include "browsers/flagBrowser.h"

#include "charString.h"
#include "config.h"
#include "display.h"
#include "flags.h"
#include "fonts.h"
#include "items.h"
#include "memory.h"
#include "registers.h"
#include "screen.h"
#include <string.h>

#include "c47.h"



#if !defined(TESTSUITE_BUILD)
#if !defined(SAVE_SPACE_DM42_8)
  TO_QSPI const char flagLetter[] = "XYZTABCDLIJK";

  static void oneSystemFlag(uint16_t systemFlag, const char *systemFlagNamename, int16_t *line, bool_t *firstSystemFlag) {
    if(getSystemFlag(systemFlag)) {
      if(stringWidth(tmpString + CHARS_PER_LINE * *line, &standardFont, true, true) + stringWidth(systemFlagNamename, &standardFont, true, false) <= SCREEN_WIDTH - 1 - 8) { // SPACE is 8 pixel wide
        if(!*firstSystemFlag) {
          strcat(tmpString + CHARS_PER_LINE * *line, " ");
        }
        else {
          *firstSystemFlag = false;
        }
        strcat(tmpString + CHARS_PER_LINE * *line, systemFlagNamename);
      }
      else {
        xcopy(tmpString + CHARS_PER_LINE * ++(*line), systemFlagNamename, strlen(systemFlagNamename) + 1);
      }
    }
  }
#endif // !SAVE_SPACE_DM42_8


  /********************************************//**
   * \brief The flag browser application
   *
   * \param[in] unusedButMandatoryParameter uint16_t
   * \return void
   ***********************************************/
  void flagBrowser(uint16_t init) {
  #if !defined(SAVE_SPACE_DM42_8)
    static int16_t line;
    int16_t f;
    bool_t firstFlag;

    hourGlassIconEnabled = false;

    if(calcMode != CM_FLAG_BROWSER) {
      if(calcMode == CM_AIM) {
        hideCursor();
        cursorEnabled = false;
      }

      previousCalcMode = calcMode;
      calcMode = CM_FLAG_BROWSER;
      clearSystemFlag(FLAG_ALPHA);
      currentFlgScr = init;                      //5 in new style; 0 is old style
      if(currentFlgScr == 0)  currentFlgScr = 3; // Init old style
      refreshScreen();                           //Restart once, clearing screen and all, restarting flag browser, now in the correct mode
    }

    if(currentFlgScr == 0) currentFlgScr = 4;
    if(currentFlgScr == 5) currentFlgScr = 1;

    if(currentFlgScr == 1) { // Init new style
      char flagNumber[4];

      line = 0;

      // Free memory
      //sprintf(tmpString + CHARS_PER_LINE * line++, "%" PRIu32 " bytes free in RAM, %" PRIu32 " in flash.", getFreeRamMemory(), getFreeFlash());
      sprintf(tmpString + CHARS_PER_LINE * line++, "%" PRIu32 " bytes free in RAM.", getFreeRamMemory());

      // Global flags
      sprintf(tmpString + CHARS_PER_LINE * line++, "Global user flags set:");

      tmpString[CHARS_PER_LINE * line] = 0;
      firstFlag = true;
      for(f=0; f<NUMBER_OF_GLOBAL_FLAGS; f++) {
        if(getFlag(f)) {
          if(f < 10) {
            flagNumber[0] = '0' + f;
            flagNumber[1] = 0;
          }
          else if(f < 100) {
            flagNumber[0] = '0' + f/10;
            flagNumber[1] = '0' + f%10;
            flagNumber[2] = 0;
          }
          else {
            flagNumber[0] = flagLetter[f-100];
            flagNumber[1] = 0;
          }

          if(stringWidth(tmpString + CHARS_PER_LINE * line, &standardFont, true, true) + stringWidth(flagNumber, &standardFont, true, false) <= SCREEN_WIDTH - 1 - 8) { // SPACE is 8 pixel wide
            if(!firstFlag) {
              strcat(tmpString + CHARS_PER_LINE * line, " ");
            }
            else {
              firstFlag = false;
            }
            strcat(tmpString + CHARS_PER_LINE * line, flagNumber);
          }
          else {
            xcopy(tmpString + CHARS_PER_LINE * ++line, flagNumber, 4);
          }
        }
      }

      if(currentNumberOfLocalFlags == 0) {
        sprintf(tmpString + CHARS_PER_LINE * ++line, "No local flags and registers are allocated.");
      }
      else {
        if(currentNumberOfLocalRegisters == 0) {
          sprintf(tmpString + CHARS_PER_LINE * ++line, "No local registers are allocated.");
        }
        else {
          // Local registers
          if(currentNumberOfLocalRegisters == 1) {
            strcpy(tmpString + CHARS_PER_LINE * ++line, "1 local register is allocated.");
          }
          else {
            sprintf(tmpString + CHARS_PER_LINE * ++line, "%" PRIu8 " local registers are allocated.", currentNumberOfLocalRegisters);
          }
        }

        // Local flags
        tmpString[CHARS_PER_LINE * ++line] = 0;
        firstFlag = true;
        for(f=0; f<NUMBER_OF_LOCAL_FLAGS; f++) {
          if(getFlag(NUMBER_OF_GLOBAL_FLAGS + f)) {
            if(f < 10) {
              flagNumber[0] = '0' + f;
              flagNumber[1] = 0;
            }
            else {
              flagNumber[0] = '0' + f/10;
              flagNumber[1] = '0' + f%10;
              flagNumber[2] = 0;
            }

            if(stringWidth(tmpString + CHARS_PER_LINE * line, &standardFont, true, true) + stringWidth(flagNumber, &standardFont, true, false) <= SCREEN_WIDTH - 1 - 8) { // SPACE is 8 pixel wide
              if(!firstFlag) {
                strcat(tmpString + CHARS_PER_LINE * line, " ");
              }
              else {
                firstFlag = false;
              }
              strcat(tmpString + CHARS_PER_LINE * line, flagNumber);
            }
            else {
              xcopy(tmpString + CHARS_PER_LINE * ++line, flagNumber, 4);
            }
          }
        }
      }

      // Empty line
      tmpString[CHARS_PER_LINE * ++line] = 0;

      // Rounding mode
      strcpy(tmpString + CHARS_PER_LINE * ++line, "RM=");
      switch(roundingMode) {
        case RM_HALF_EVEN: {
          strcat(tmpString + CHARS_PER_LINE * line, STD_ONE_HALF "E");
          break;
        }

        case RM_HALF_UP: {
          strcat(tmpString + CHARS_PER_LINE * line, STD_ONE_HALF STD_UP_ARROW);
          break;
        }

        case RM_HALF_DOWN: {
          strcat(tmpString + CHARS_PER_LINE * line, STD_ONE_HALF STD_DOWN_ARROW);
          break;
        }

        case RM_UP: {
          strcat(tmpString + CHARS_PER_LINE * line, STD_LEFT_ARROW "0" STD_RIGHT_ARROW);
          break;
        }

        case RM_DOWN: {
          strcat(tmpString + CHARS_PER_LINE * line, STD_RIGHT_ARROW "0" STD_LEFT_ARROW);
          break;
        }

        case RM_CEIL: {
          strcat(tmpString + CHARS_PER_LINE * line, STD_LEFT_CEILING "x" STD_RIGHT_CEILING);
          break;
        }

        case RM_FLOOR: {
          strcat(tmpString + CHARS_PER_LINE * line, STD_LEFT_FLOOR "x" STD_RIGHT_FLOOR);
          break;
        }

        default: {
          strcat(tmpString + CHARS_PER_LINE * line, "???");
        }
      }

      // Significant digits
      strcat(tmpString + CHARS_PER_LINE * line, "  SDIGS=");
      uint8_t sd = (significantDigits == 0 ? 34 : significantDigits);
      if(sd < 10) {
        flagNumber[0] = '0' + sd;
        flagNumber[1] = 0;
      }
      else {
        flagNumber[0] = '0' + sd/10;
        flagNumber[1] = '0' + sd%10;
        flagNumber[2] = 0;
      }
      strcat(tmpString + CHARS_PER_LINE * line, flagNumber);

      // ULP of X
      switch(getRegisterDataType(REGISTER_X)) {
        case dtLongInteger:
        case dtShortInteger: {
          strcat(tmpString + CHARS_PER_LINE * line, "  ULP of reg X = 1");
          break;
        }

        case dtReal34: {
          if(real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X))) {
            strcat(tmpString + CHARS_PER_LINE * line, "  ULP of reg X = " STD_INFINITY);
          }
          else {
            real34_t x34;
            real34NextPlus(REGISTER_REAL34_DATA(REGISTER_X), &x34);
            if(real34IsInfinite(&x34)) {
              real34NextMinus(REGISTER_REAL34_DATA(REGISTER_X), &x34);
              real34Subtract(REGISTER_REAL34_DATA(REGISTER_X), &x34, &x34);
            }
            else {
              real34Subtract(&x34, REGISTER_REAL34_DATA(REGISTER_X), &x34);
            }
            strcat(tmpString + CHARS_PER_LINE * line, "  ULP of reg X = 10");
            supNumberToDisplayString(real34GetExponent(&x34), tmpString + CHARS_PER_LINE * line + strlen(tmpString + CHARS_PER_LINE * line), NULL, false);
          }
          break;
        }

        default: {
        }
      }

      // System flags
      firstFlag = true;
      tmpString[CHARS_PER_LINE * ++line] = 0;
      oneSystemFlag(FLAG_ALLENG,  "ALLENG",  &line, &firstFlag);
      oneSystemFlag(FLAG_ALPIN,   "ALP.IN",  &line, &firstFlag);
      oneSystemFlag(FLAG_AUTOFF,  "AUTOFF",  &line, &firstFlag);
      oneSystemFlag(FLAG_AUTXEQ,  "AUTXEQ",  &line, &firstFlag);
      oneSystemFlag(FLAG_CPXj,    "CPXj",    &line, &firstFlag);
      oneSystemFlag(FLAG_CPXRES,  "CPXRES",  &line, &firstFlag);  //JM
      oneSystemFlag(FLAG_ENDPMT,  "ENDPMT",  &line, &firstFlag);
      oneSystemFlag(FLAG_FRACT,   "FRACT",   &line, &firstFlag);
      oneSystemFlag(FLAG_GROW,    "GROW",    &line, &firstFlag);
      oneSystemFlag(FLAG_IGN1ER,  "IGN1ER",  &line, &firstFlag);
      oneSystemFlag(FLAG_INTING,  "INTING",  &line, &firstFlag);
      oneSystemFlag(FLAG_LEAD0,   "LEAD.0",  &line, &firstFlag);
      oneSystemFlag(FLAG_NUMIN,   "NUM.IN",  &line, &firstFlag);
      oneSystemFlag(FLAG_POLAR,   "POLAR",   &line, &firstFlag);   //JM
      oneSystemFlag(FLAG_PRTACT,  "PRTACT",  &line, &firstFlag);
      oneSystemFlag(FLAG_QUIET,   "QUIET",   &line, &firstFlag);
      oneSystemFlag(FLAG_SLOW,    "SLOW",    &line, &firstFlag);
      oneSystemFlag(FLAG_SOLVING, "SOLVING", &line, &firstFlag);
      oneSystemFlag(FLAG_SPCRES,  "SPCRES",  &line, &firstFlag);
      oneSystemFlag(FLAG_SSIZE8,  "SSIZE8",  &line, &firstFlag);
      oneSystemFlag(FLAG_TRACE,   "TRACE",   &line, &firstFlag);
      oneSystemFlag(FLAG_USB,     "USB",     &line, &firstFlag);
      oneSystemFlag(FLAG_VMDISP,  "VMDISP",  &line, &firstFlag);
      line++;
    }


    if(currentFlgScr == 1) {
      for(f=0; f<min(9, line); f++) {
        showString(tmpString + CHARS_PER_LINE * f, &standardFont, 1, 22*f + 43, vmNormal, true, false);
      }
    }

    if(currentFlgScr == 2) {
      if(line > 9) {
        for(f=9; f<line; f++) {
          showString(tmpString + CHARS_PER_LINE * f, &standardFont, 1, 22*(f-9) + 43, vmNormal, true, false);
        }
      }
      else {
        if(lastFlgScr == 1) {currentFlgScr++;}
        else {
          currentFlgScr--;
        }
      }
    }


    if(currentFlgScr == 3) { // flags from 0 to 99
  //    clearScreen(false, true, true);

      for(f=0; f<=99/*79*/; f++) {                                          //JM 99
        if(getFlag(f)) {
          lcd_fill_rect(40*(f%10)+1,22*(f/10)+66-1-44,  40*(f%10)+39-(40*(f%10)+1),22*(f/10)+66+20-1-44-(22*(f/10)+66-1-44)+1,0xFF);
        }
        sprintf(tmpString, "%d", f);
        showString(tmpString, &standardFont, 40*(f%10) + 19 - stringWidth(tmpString, &standardFont, false, false)/2, 22*(f/10)+66-1-44, getFlag(f) ? vmReverse : vmNormal, true, true); //JM-44
      }
    }

    if(currentFlgScr == 4) { // Flags from 100 to GLOBALFLAGS, local registers and local flags
  //    clearScreen(false, true, true);

      showString("Global flag status (continued):", &standardFont, 1, 22-1, vmNormal, true, true);

      for(f=100/*80*/; f<NUMBER_OF_GLOBAL_FLAGS; f++) {                     //JM100
        if(getFlag(f)) {
          lcd_fill_rect(80*(f%5), 22*(f/5)-132-1-44-220, 80*(f%5)+74-(80*(f%5)), 22*(f/5)-132+20-1-44-220-(22*(f/5)-132-1-44-220)+1, 0xFF);
        }

        switch(f) {
          case FLAG_X: strcpy(tmpString, "X:POLAR "); break;
          case FLAG_Y: strcpy(tmpString, "Y:101   "); break;
          case FLAG_Z: strcpy(tmpString, "Z:102   "); break;
          case FLAG_T: strcpy(tmpString, "T:TRACE "); break;
          case FLAG_A: strcpy(tmpString, "A:ALLENG"); break;
          case FLAG_B: strcpy(tmpString, "B:OVRFL "); break;
          case FLAG_C: strcpy(tmpString, "C:CARRY "); break;
          case FLAG_D: strcpy(tmpString, "D:SPCRES"); break;
          case FLAG_L: strcpy(tmpString, "L:LEAD0 "); break;
          case FLAG_I: strcpy(tmpString, "I:CPXRES"); break;
          case FLAG_J: strcpy(tmpString, "J:110   "); break;
          case FLAG_K: strcpy(tmpString, "K:111   "); break;
          default:  sprintf(tmpString,"   %d ", f);break;
        }

        char ss[2];
        int16_t i;
        i=0;
        ss[1]=0;
        while(tmpString[i]!=0){
          ss[0]=tmpString[i];
          showString(ss, &standardFont, i*9-32+1+max(0,16-1+2*40*(f%5) + 19 - 16/8), 22*(f/5)-132-1-44-220, getFlag(f) ? vmReverse : vmNormal, true, true);  //JM-44
          i++;
        }
  //      showString(tmpString, &standardFont, max(0,16-1+2*40*(f%5) + 19 - stringWidth(tmpString, &standardFont, false, false)/2), 22*(f/5)-132-1-44-220, getFlag(f) ? vmReverse : vmNormal, true, true);  //JM-44
      }

      if(currentNumberOfLocalFlags == 0) {
        sprintf(tmpString, "No local flags and registers are allocated.");
        showString(tmpString, &standardFont, 1, 110-1, vmNormal, true, true);
      }
      else {
        if(currentNumberOfLocalRegisters == 0) {
          sprintf(tmpString, "No local registers are allocated.");
          showString(tmpString, &standardFont, 1, 110-1, vmNormal, true, true);
        }
        else {
           // Local registers
          if(currentNumberOfLocalRegisters == 1) {
            strcpy(tmpString, "1 local register is allocated.");
            showString(tmpString, &standardFont, 1, 110-1, vmNormal, true, true);
          }
          else {
            sprintf(tmpString,"%" PRIu8 " local registers are allocated.", currentNumberOfLocalRegisters);
            showString(tmpString, &standardFont, 1, 110-1, vmNormal, true, true);
          }
        }
        showString("Local flag status:", &standardFont, 1, 132-1, vmNormal, true, true);

        for(f=0; f<NUMBER_OF_LOCAL_FLAGS; f++) {
          if(getFlag(NUMBER_OF_GLOBAL_FLAGS + f)) {
            lcd_fill_rect(40*(f%10)+1, 22*(f/10)+198-1-44, 40*(f%10)+39-(40*(f%10)+1), 22*(f/10)+198+20-1-44-(22*(f/10)+198-1-44)+1,  0xFF);
          }

          sprintf(tmpString, "%d", f);
          showString(tmpString, &standardFont, f<=9 ? 40*(f%10) + 17 : 40*(f%10) + 12, 22*(f/10)+198-1-44, getFlag(NUMBER_OF_GLOBAL_FLAGS + f) ? vmReverse : vmNormal, true, true);     //JM-44
        }


      }

  #if defined(OOO)
      if(currentNumberOfLocalRegisters > 0) {
        // Local registers
        sprintf(tmpString, "%" PRIu16 " local register%s allocated.", currentNumberOfLocalRegisters, currentNumberOfLocalRegisters==1 ? " is" : "s are");
        showString(tmpString, &standardFont, 1, 132-1, vmNormal, true, true);
        showString("Local flag status:", &standardFont, 1, 154-1, vmNormal, true, true);

        for(f=0; f<16; f++) {
          if(getFlag(NUMBER_OF_GLOBAL_FLAGS+f)) {
            lcd_fill_rect(40*(f%10)+1, 22*(f/10)+176-1-44, 40*(f%10)+39-(40*(f%10)+1), 22*(f/10)+176+20-1-44-(22*(f/10)+176-1-44)+1,  0xFF);
          }

          sprintf(tmpString, "%d", f);
          showString(tmpString, &standardFont, f<=9 ? 40*(f%10) + 17 : 40*(f%10) + 12, 22*(f/10)+176-1-44, getFlag(NUMBER_OF_GLOBAL_FLAGS+f) ? vmReverse : vmNormal, true, true);     //JM-44
        }
      }
  #endif // OOO

    }
    lastFlgScr = currentFlgScr;
  #endif // !SAVE_SPACE_DM42_8
  }
#endif // !TESTSUITE_BUILD
