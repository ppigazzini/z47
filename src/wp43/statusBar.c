// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors


#include "statusBar.h"

#include "bufferize.h"
#include "charString.h"
#include "dateTime.h"
#include "flags.h"
#include "fonts.h"
#include "items.h"
#include "hal/gui.h"
#include "c43Extensions/jm.h"
#include "c43Extensions/keyboardTweak.h"
#include "plotstat.h"
#include "screen.h"
#include "softmenus.h"
#include "timer.h"
#include <string.h>

#include "wp43.h"


#if !defined(TESTSUITE_BUILD)
  void refreshStatusBar(void);



  void showDateTime(void) {
    if(!((SBARUPD_Date) | (SBARUPD_Time))) return;
    lcd_fill_rect(0, 0, X_REAL_COMPLEX, 20, LCD_SET_VALUE);

    uint32_t x = X_DATE;
    if(SBARUPD_Date) {
      getDateString(dateTimeString);
      x = showString(dateTimeString, &standardFont, x, 0, vmNormal, true, true);
      x = showGlyph(getSystemFlag(FLAG_TDM24) ? " " : STD_SPACE_3_PER_EM, &standardFont, x, 0, vmNormal, true, true); // is 0+0+8 pixel wide
    } else {
      x = X_TIME;
    }

    if(SBARUPD_Time) {
      getTimeString(dateTimeString);
      showString(dateTimeString, &standardFont, x, 0, vmNormal, true, false);
    }
  }



  void showRealComplexResult(void) {
    if(!(SBARUPD_ComplexResult)) return;
    if(getSystemFlag(FLAG_CPXRES)) {
      showGlyph(STD_COMPLEX_C, &standardFont, X_REAL_COMPLEX, 0, vmNormal, true, false); // Complex C is 0+8+3 pixel wide
    }
    else {
      showGlyph(STD_REAL_R,    &standardFont, X_REAL_COMPLEX, 0, vmNormal, true, false); // Real R    is 0+8+3 pixel wide
    }
  }



  void showComplexMode(void) {
    if(!(SBARUPD_ComplexMode)) return;
    uint32_t X_COMPLEX_MODE1 =  SBARUPD_ComplexResult ? X_COMPLEX_MODE : X_COMPLEX_MODE + X_COMPLEX_MODE_ADJ;

    if(getSystemFlag(FLAG_POLAR)) { // polar mode
     showGlyph(STD_SUN,           &standardFont, X_COMPLEX_MODE1, 0, vmNormal, true, true); // Sun         is 0+12+2 pixel wide
    }
    else { // rectangular mode
     showGlyph(STD_RIGHT_ANGLE,   &standardFont, X_COMPLEX_MODE1, 0, vmNormal, true, true); // Right angle is 0+12+2 pixel wide
    }
  }



  void showAngularMode(void) {
    if(!((SBARUPD_AngularModeBasic) | (SBARUPD_AngularMode))) return;

    uint32_t x = X_ANGULAR_MODE;

    if(SBARUPD_AngularModeBasic) {
      x = showGlyph(STD_MEASURED_ANGLE, &standardFont, x, 0, vmNormal, true, true); // Angle is 0+9 pixel wide
    }

    switch(currentAngularMode) {
      case amRadian: {
        showGlyph(STD_SUP_r,              &standardFont, x, 0, vmNormal, true, false); // r  is 0+6 pixel wide
        break;
      }

      case amMultPi: {
        showGlyph(STD_SUP_pir,            &standardFont, x, 0, vmNormal, true, false); // pi is 0+9 pixel wide
        break;
      }

      case amGrad: {
        showGlyph(STD_SUP_g,              &standardFont, x, 0, vmNormal, true, false); // g  is 0+6 pixel wide
        break;
      }

      case amDegree: {
        showGlyph(STD_DEGREE,             &standardFont, x, 0, vmNormal, true, false); // °  is 0+6 pixel wide
        break;
      }

      case amDMS: {
        showGlyph(STD_RIGHT_DOUBLE_QUOTE, &standardFont, x, 0, vmNormal, true, false); // "  is 0+6 pixel wide
        break;
      }

      default: {
        showGlyph(STD_QUESTION_MARK,      &standardFont, x, 0, vmNormal, true, false); // ?
      }
    }
  }



     void conv(char * str20, char * str40) {
      str40[0]=0;
      int16_t x = 0;
      int16_t y = 0;
      while(str20[x]!=0) {
        if(str20[x]>='A' && str20[x]<='Z') {
          str40[y++] = 0xa4;
          str40[y++] = str20[x++] + 0x8F;
          str40[y] = 0;
        }
        else if(str20[x]>='0' && str20[x]<='9') {
          str40[y++] = 0xa0;
          str40[y++] = str20[x++] + 0x50;
          str40[y] = 0;
        }
        else {
          str40[y++] = str20[x++];
          str40[y] = 0;
        }
      }
    }                                                  //JM ^^ KEYS



void showFracMode(void) {
    if(!(SBARUPD_FractionModeAndBaseMode)) return;
    static char statusMessage[20];
    char str20[20];                                   //JM vv KEYS
    char str40[40];

  showString(STD_SPACE_EM STD_SPACE_EM STD_SPACE_EM STD_SPACE_EM STD_SPACE_EM, &standardFont, X_INTEGER_MODE-12*5, 0, vmNormal, true, true); // STD_SPACE_EM is 0+0+12 pixel wide

  uint32_t x = 0;

  if(lastIntegerBase != 0) {                               //JMvv HEXKEYS
    str20[0]=0;
    if(topHex) {
      x = showString("#KEY", &standardFont, X_FRAC_MODE, 0 , vmNormal, true, true);//-4 looks good
      strcpy(str20,"A"); conv(str20, str40);
      x = showString(str40,  &standardFont, x, -4 , vmNormal, true, true);         //-4 looks good
      x = showString("-",    &standardFont, x,  2 , vmNormal, true, true);         //-4 looks good
      strcpy(str20,"F"); conv(str20, str40);
      x = showString(str40,  &standardFont, x, -4 , vmNormal, true, true);         //-4 looks good
    }
    else {
      x = showString("#BASE", &standardFont, X_FRAC_MODE, 0, vmNormal, true, true); //-4 looks good
    }
    return;
  }                                                                                //JM^^


    x = X_FRAC_MODE;                    //vJM
    char divStr[10];
    if(getSystemFlag(FLAG_FRACT) || (constantFractions && constantFractionsOn)) {
      if(!getSystemFlag(FLAG_PROPFR)) {
        raiseString = 9;
        strcpy(divStr,STD_SUB_b);
        x = showString(divStr, &standardFont, x, 0, vmNormal, true, true)-2;
        strcpy(divStr,"/");
      }
      else {
        raiseString = 3;
        strcpy(divStr,"a" STD_SPACE_4_PER_EM);
        x = showString(divStr, &standardFont, x, 0, vmNormal, true, true);
        raiseString = 9;
        strcpy(divStr, STD_SUB_b);
        x = showString(divStr, &standardFont, x, 0, vmNormal, true, true)-2;
        strcpy(divStr,"/");
      }
    }
    else {
        strcpy(divStr,"/");
    }
    compressString = 1;             //^JM


    if(constantFractions && constantFractionsOn && !getSystemFlag(FLAG_FRACT)) {
      sprintf(statusMessage,"%s",divStr);
      x = showString(statusMessage, &standardFont, x, 0, vmNormal, true, true);
      raiseString = 4;
      sprintf(statusMessage,STD_SUB_c);
      x = showString(statusMessage, &standardFont, x-2, 0, vmNormal, true, true);

      strcpy(divStr,STD_DOT);
      raiseString = 2;
      x = showString(divStr, &standardFont, x+1, 0, vmNormal, true, true);
      strcpy(divStr,"I");
      raiseString = 2;
      showString(divStr, &standardFont, x, 0, vmNormal, true, true);
      raiseString = 2;
      x = showString(divStr, &standardFont, x+1, 0, vmNormal, true, true);
      x -= 5;
      for(uint16_t yy = 4; yy<=11; yy++) {
        setWhitePixel(x, yy); 
      }
    } else {

      if(getSystemFlag(FLAG_DENANY) && denMax == MAX_DENMAX) {
        sprintf(statusMessage,"%smax",divStr);
        x = showString(statusMessage, &standardFont, x, 0, vmNormal, true, true);
      }
      else {
        if((getSystemFlag(FLAG_DENANY) && denMax != MAX_DENMAX) || !getSystemFlag(FLAG_DENANY)) {
          sprintf(statusMessage, "%s%" PRIu32, divStr,denMax);
          x = showString(statusMessage, &standardFont, x, 0, vmNormal, true, true);
        }

        if(!getSystemFlag(FLAG_DENANY)) {
          if(getSystemFlag(FLAG_DENFIX)) {
            x = showGlyphCode('f',  &standardFont, x, 0, vmNormal, true, false); // f is 0+7+3 pixel wide
          }
          else {
            x = showString(PRODUCT_SIGN, &standardFont, x, 0, vmNormal, true, false); // STD_DOT is 0+3+2 pixel wide and STD_CROSS is 0+7+2 pixel wide
          }
        }
      }

    }
  }



  void showIntegerMode(void) {
    if(!(SBARUPD_IntegerMode)) return;
    static char statusMessage[10];
    if(shortIntegerWordSize <= 9) {
      sprintf(statusMessage, " %" PRIu8 ":%c", shortIntegerWordSize, shortIntegerMode==SIM_1COMPL?'1':(shortIntegerMode==SIM_2COMPL?'2':(shortIntegerMode==SIM_UNSIGN?'u':(shortIntegerMode==SIM_SIGNMT?'s':'?'))));
    }
    else {
      sprintf(statusMessage, "%" PRIu8 ":%c", shortIntegerWordSize, shortIntegerMode==SIM_1COMPL?'1':(shortIntegerMode==SIM_2COMPL?'2':(shortIntegerMode==SIM_UNSIGN?'u':(shortIntegerMode==SIM_SIGNMT?'s':'?'))));
    }

    showString(statusMessage, &standardFont, X_INTEGER_MODE, 0, vmNormal, true, true);
  }



  void showMatrixMode(void) {
    if(!(SBARUPD_MatrixMode)) return;
    static char statusMessage[5];
    if(getSystemFlag(FLAG_GROW)) {
      sprintf(statusMessage, "grow");
    }
    else {
      sprintf(statusMessage, "wrap");
    }

    showString(statusMessage, &standardFont, X_INTEGER_MODE - 2, 0, vmNormal, true, true);
  }



  void showTvmMode(void) {
    if(!(SBARUPD_TVMMode)) return;
    static char statusMessage[5];
    if(getSystemFlag(FLAG_ENDPMT)) {
      sprintf(statusMessage, "END");
    }
    else {
      sprintf(statusMessage, "BEG");
    }

    showString(statusMessage, &standardFont, X_INTEGER_MODE, 0, vmNormal, true, true);
  }



  void showOverflowCarry(void) {
    if(!(SBARUPD_OCCarryMode)) return;
    showGlyph(STD_OVERFLOW_CARRY, &standardFont, X_OVERFLOW_CARRY, 0, vmNormal, true, false); // STD_OVERFLOW_CARRY is 0+6+3 pixel wide

    if(!getSystemFlag(FLAG_OVERFLOW)) { // Overflow flag is cleared
      lcd_fill_rect(X_OVERFLOW_CARRY, 2, 6, 7, LCD_SET_VALUE);
    }

    if(!getSystemFlag(FLAG_CARRY)) { // Carry flag is cleared
      lcd_fill_rect(X_OVERFLOW_CARRY, 12, 6, 7, LCD_SET_VALUE);
    }
  }



  void showHideAlphaMode(void) {
    int status=0;
    uint8_t nChar;
    if(scrLock == NC_NORMAL) { nChar = nextChar; } else { nChar = scrLock; }
    if(calcMode == CM_AIM || calcMode == CM_EIM || (catalog && catalog != CATALOG_MVAR) || (tam.mode != 0 && tam.alpha) || ((calcMode == CM_PEM || calcMode == CM_ASSIGN) && getSystemFlag(FLAG_ALPHA))) {
      if(numLock && !shiftF && !shiftG) {
          if(alphaCase == AC_UPPER)                  { status = 3 - (nChar == NC_SUBSCRIPT ? 2 : nChar == NC_SUPERSCRIPT ? 1:0); } else
          if(alphaCase == AC_LOWER)                  { status = 6 - (nChar == NC_SUBSCRIPT ? 2 : nChar == NC_SUPERSCRIPT ? 1:0); }
        } else
          if(alphaCase == AC_LOWER && shiftF){
            setSystemFlag(FLAG_alphaCAP);              status = 12 - (nChar == NC_SUBSCRIPT ? 2 : nChar == NC_SUPERSCRIPT ? 1:0); //A
          } else
            if(alphaCase == AC_UPPER && shiftF){
              clearSystemFlag(FLAG_alphaCAP);          status = 18 - (nChar == NC_SUBSCRIPT ? 2 : nChar == NC_SUPERSCRIPT ? 1:0);   //a
            } else //at this point shiftF is false
              if(alphaCase == AC_UPPER)  { //UPPER
                setSystemFlag(FLAG_alphaCAP);
                if(shiftG)                           { status =  3 - (nChar == NC_SUBSCRIPT ? 2 : nChar == NC_SUPERSCRIPT ? 1:0); } else
                if(!shiftG && !shiftF && !numLock)   { status = 12 - (nChar == NC_SUBSCRIPT ? 2 : nChar == NC_SUPERSCRIPT ? 1:0); }
              } else
                if(alphaCase == AC_LOWER)  { //LOWER
                  clearSystemFlag(FLAG_alphaCAP);
                  if(shiftG)                         { status =  3 - (nChar == NC_SUBSCRIPT ? 2 : nChar == NC_SUPERSCRIPT ? 1:0); } else
                  if(!shiftG && !shiftF && !numLock) { status = 18 - (nChar == NC_SUBSCRIPT ? 2 : nChar == NC_SUPERSCRIPT ? 1:0); }
                }

      if((SBARUPD_AlphaMode) && status >0 && status <=18) {
        lcd_fill_rect(X_ALPHA_MODE,0,11,18,0);
        switch(status) {
          case  1: showString(STD_SUB_N, &standardFont, X_ALPHA_MODE, -2, vmNormal, true, false); break; //sub    // STD_ALPHA is 0+9+2 pixel wide
          case  2: showString(STD_SUB_N, &standardFont, X_ALPHA_MODE,-11, vmNormal, true, false); break; //sup
          case  3: showString(STD_num,   &standardFont, X_ALPHA_MODE,  0, vmNormal, true, false); break; //normal

          case  4: showString(STD_SUB_n, &standardFont, X_ALPHA_MODE, -2, vmNormal, true, false); break; //sub
          case  5: showString(STD_SUB_n, &standardFont, X_ALPHA_MODE,-11, vmNormal, true, false); break; //sup
          case  6: showString(STD_n,     &standardFont, X_ALPHA_MODE,  0, vmNormal, true, false); break; //normal

//          case  7: showString(STD_SIGMA, &standardFont, X_ALPHA_MODE,  0, vmNormal, true, false); break; //sub
//          case  8: showString(STD_SIGMA, &standardFont, X_ALPHA_MODE,  0, vmNormal, true, false); break; //sup
//          case  9: showString(STD_SIGMA, &standardFont, X_ALPHA_MODE,  0, vmNormal, true, false); break; //normal

          case 10: showString(STD_SUB_A, &standardFont, X_ALPHA_MODE, -2, vmNormal, true, false); break; //sub
          case 11: showString(STD_SUB_A, &standardFont, X_ALPHA_MODE, -11, vmNormal, true, false); break; //sup   //not possible
          case 12: showString(STD_A    , &standardFont, X_ALPHA_MODE,  0, vmNormal, true, false); break; //normal

//          case 13: showString(STD_sigma, &standardFont, X_ALPHA_MODE,  0, vmNormal, true, false); break; //sub
//          case 14: showString(STD_sigma, &standardFont, X_ALPHA_MODE,  0, vmNormal, true, false); break; //sup
//          case 15: showString(STD_sigma, &standardFont, X_ALPHA_MODE,  0, vmNormal, true, false); break; //normal

          case 16: showString(STD_SUB_a, &standardFont, X_ALPHA_MODE, -2, vmNormal, true, false); break; //sub
          case 17: showString(STD_SUB_a, &standardFont, X_ALPHA_MODE, -11, vmNormal, true, false); break; //sup    //not possible
          case 18: showString(STD_a    , &standardFont, X_ALPHA_MODE,  0, vmNormal, true, false); break; //normal
          default:;
        }
      }

    }
    else {
      clearSystemFlag(FLAG_alphaCAP);
    }
  }



  void showHideHourGlass(void) {
    if(!(SBARUPD_HourGlass)) return;

    if(screenUpdatingMode & SCRUPD_MANUAL_STATUSBAR) {
      switch(calcMode) {
        case CM_PEM:
        case CM_REGISTER_BROWSER:
        case CM_FLAG_BROWSER:
        case CM_ASN_BROWSER:
        case CM_FONT_BROWSER:
        case CM_PLOT_STAT:
        case CM_CONFIRMATION:
        case CM_MIM:
        case CM_TIMER:
        case CM_GRAPH: {
          screenUpdatingMode &= ~SCRUPD_MANUAL_STATUSBAR;
          break;
        }

        default: {
          return;
        }
      }
    }
    switch(programRunStop) {
      case PGM_WAITING: {
        showGlyph(STD_NEG_EXCLAMATION_MARK, &standardFont, (GRAPHMODE ? X_HOURGLASS_GRAPHS : X_HOURGLASS) - 1, 0, vmNormal, true, false);
        break;
      }
      case PGM_RUNNING: {
        lcd_fill_rect((GRAPHMODE ? X_HOURGLASS_GRAPHS : X_HOURGLASS) - 1, 0, stringWidth(STD_NEG_EXCLAMATION_MARK, &standardFont, true, false), 20, LCD_SET_VALUE);
        showGlyph(STD_P, &standardFont, (GRAPHMODE ? X_HOURGLASS_GRAPHS : X_HOURGLASS) + 1, 0, vmNormal, true, false);
        break;
      }
      default: {
        lcd_fill_rect((GRAPHMODE ? X_HOURGLASS_GRAPHS : X_HOURGLASS) - 1, 0, stringWidth(STD_NEG_EXCLAMATION_MARK, &standardFont, true, false), 20, LCD_SET_VALUE);
        if(hourGlassIconEnabled) {
          showGlyph(STD_HOURGLASS, &standardFont, GRAPHMODE ? X_HOURGLASS_GRAPHS : X_HOURGLASS, 0, vmNormal, true, false); // is 0+11+3 pixel wide //Shift the hourglass to a visible part of the status bar
        }
      }
    }
    force_refresh(timed);
  }



  void light_ASB_icon(void) {
    if(!(SBARUPD_AlphaMode)) return;
    lcd_fill_rect(X_ALPHA_MODE,18,9,2,0xFF);
    showString(asmBuffer, &standardFont, X_ALPHA_MODE+30, 0, vmNormal, true, false);
    force_refresh(force);
  }


  void kill_ASB_icon(void) {
    if(!(SBARUPD_AlphaMode)) return;
    lcd_fill_rect(X_ALPHA_MODE,18,9,2,0);
    showString("    ", &standardFont, X_ALPHA_MODE+30, 0, vmNormal, true, false);
    force_refresh(force);
  }


  void showStackSize(void) {
    if(!(SBARUPD_StackSize)) return;
    showGlyph(getSystemFlag(FLAG_SSIZE8) ? STD_8 : STD_4, &standardFont, X_SSIZE_BEGIN, 0, vmNormal, true, false); // is 0+6+2 pixel wide
  }


  void showHideWatch(void) {
    if(!(SBARUPD_Watch)) return;
    if(watchIconEnabled) {
      showGlyph(STD_TIMER, &standardFont, X_WATCH, 0, vmNormal, true, false); // is 0+13+1 pixel wide
    }
  }



  void showHideSerialIO(void) {
    if(!(SBARUPD_SerialIO)) return;
    if(serialIOIconEnabled) {
      showGlyph(STD_SERIAL_IO, &standardFont, X_SERIAL_IO, 0, vmNormal, true, false); // is 0+8+3 pixel wide
    }
  }



  void showHidePrinter(void) {
    if(!(SBARUPD_Printer)) return;
    if(printerIconEnabled) {
      showGlyph(STD_PRINTER,   &standardFont, X_PRINTER, 0, vmNormal, true, false); // is 0+12+3 pixel wide
    }
  }




void showHideASB(void) {                     //JMvv
  if(!(SBARUPD_AlphaMode)) return;
  if(fnTimerGetStatus(TO_ASM_ACTIVE) == TMR_RUNNING) {
    light_ASB_icon();
  }
  else {
    kill_ASB_icon();
  }
}                                             //JM^^




void showHideUserMode(void) {
  if(!(SBARUPD_UserMode)) return;
  if(getSystemFlag(FLAG_USER)) {
    showGlyph(STD_USER_MODE, &standardFont, X_USER_MODE, 0, vmNormal, false, false); // STD_USER_MODE is 0+12+2 pixel wide
  }
  refreshModeGui(); //JM refreshModeGui
}


void drawBattery(uint16_t voltage) {
  uint16_t vv = (uint16_t)(min(max(voltage - 2000,0),3100) / (float)(((float)3100 - 2000.0f)/(float)(DY_BATTERY))); //draw a battery, full at 3.1V empty at 2V
  for(uint16_t ii = min(vv-1,DY_BATTERY-1); ii <= DY_BATTERY-1; ii++) {
    if(ii%2 == 0) { //draw outline
      setBlackPixel(ii < DY_BATTERY-3 ?  X_BATTERY + 0 : X_BATTERY + 2                           ,(DY_BATTERY-1)-ii);
      setBlackPixel(ii < DY_BATTERY-3 ?  X_BATTERY + DX_BATTERY + 0 : X_BATTERY + DX_BATTERY - 2 ,(DY_BATTERY-1)-ii);
    }
  }
  for(uint16_t ii = 0; ii <= min(vv,DY_BATTERY-1); ii++) { //draw voltage
    for(uint16_t jj = 0; jj <= DX_BATTERY; jj++) {
      if(min(vv,DY_BATTERY)-ii > (voltage > 2750 ? 2 : 1) || (jj>1 && jj<DX_BATTERY-1)) {
        setBlackPixel(X_BATTERY + jj, (DY_BATTERY-1)-ii);
      }
    }
  }
}


  #if defined(DMCP_BUILD)

    int updateVbatIntegrated(void) {
      int tmpVbat = get_vbat();
      if(tmpVbat > 1500 && tmpVbat < 3100 && tmpVbat < vbatIntegrated) {
        vbatIntegrated = tmpVbat;
      } else if(tmpVbat > 1500 && tmpVbat < 3100 && tmpVbat > vbatIntegrated) {
        vbatIntegrated = vbatIntegrated + ((tmpVbat - vbatIntegrated) >> 4);
        if(tmpVbat > 2900) vbatIntegrated = tmpVbat; 
        if(vbatIntegrated > 3100) vbatIntegrated = 3100;
      }
      return tmpVbat;
    }

    void showHideUsbLowBattery(void) {
      if(!(SBARUPD_Battery)) return;
      if(getSystemFlag(FLAG_USB)) {
        showGlyph(STD_USB_SYMBOL, &standardFont, X_BATTERY, 0, vmNormal, true, false); // is 0+9+2 pixel wide
      }
      else {
        if(SBARUPD_BatVoltage) {
          drawBattery(min(get_vbat(), vbatIntegrated));
        } 
        else if(getSystemFlag(FLAG_LOWBAT)) {
          showGlyph(STD_BATTERY, &standardFont, X_BATTERY, 0, vmNormal, true, false); // is 0+10+1 pixel wide
        }
    	  else {
      		// Clear the space used by the USB / LOWBAT glyph
      		lcd_fill_rect(X_BATTERY, 0, 11, 20, LCD_SET_VALUE);
    	  }
      }
    }
  #endif // DMCP_BUILD


  void refreshStatusBar(void) {
    if(screenUpdatingMode & SCRUPD_MANUAL_STATUSBAR) {
      switch(calcMode) {
        case CM_PEM:
        case CM_REGISTER_BROWSER:
        case CM_FLAG_BROWSER:
        case CM_ASN_BROWSER:
        case CM_FONT_BROWSER:
        case CM_PLOT_STAT:
        case CM_CONFIRMATION:
        case CM_MIM:
        case CM_TIMER:
        case CM_GRAPH: {
          screenUpdatingMode &= ~SCRUPD_MANUAL_STATUSBAR;
          break;
        }

        default: {
          return;
        }
      }
    }
    #if(DEBUG_INSTEAD_STATUS_BAR == 1)
      static char statusMessage[100];
      sprintf(statusMessage, "%s%d %s/%s  mnu:%s fi:%d", catalog ? "asm:" : "", catalog, tam.mode ? "/tam" : "", getCalcModeName(calcMode),indexOfItems[-softmenu[softmenuStack[0].softmenuId].menuItem].itemCatalogName, softmenuStack[0].firstItem);
      showString(statusMessage, &standardFont, X_DATE, 0, vmNormal, true, true);
    #else // DEBUG_INSTEAD_STATUS_BAR != 1
      if(GRAPHMODE) lcd_fill_rect(0, 0, 158, 20, 0);
      showDateTime();
      if(Y_SHIFT==0 && X_SHIFT<200) showShiftState();
      showHideHourGlass(); //TODO check if this belongs here and why JM
      if(GRAPHMODE) {
        return;    // With graph displayed, only update the time, as the other items are clashing with the graph display screen
      }
      showRealComplexResult();
      showComplexMode();
      showAngularMode();
      showFracMode();
      if(calcMode == CM_MIM) {
        showMatrixMode();
      }
      else if(softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_TVM || softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_FIN) { //JM added FIN
        showTvmMode();
      }
      else {
        showIntegerMode();
        showOverflowCarry();
      }
      showHideAlphaMode();
      showHideHourGlass();
      showStackSize();
      showHideWatch();
      showHideSerialIO();
      showHidePrinter();
      if(Y_SHIFT==0 && X_SHIFT >300) showShiftState();
      showHideUserMode();
      #if defined(DMCP_BUILD)
        showHideUsbLowBattery();
      #else // !DMCP_BUILD
        showHideStackLift();
      #endif // DMCP_BUILD
      showHideASB();                            //JM
    #endif // DEBUG_INSTEAD_STATUS_BAR == 1
  }




  #if !defined(DMCP_BUILD)
    void showHideStackLift(void) {
      //drawBattery(exponentLimit); //test battery indicator
      //return;                     //test battery indicator

      if(getSystemFlag(FLAG_ASLIFT)) {
        // Draw S
        setBlackPixel(392,  1);
        setBlackPixel(393,  1);
        setBlackPixel(394,  1);
        setBlackPixel(391,  2);
        setBlackPixel(395,  2);
        setBlackPixel(391,  3);
        setBlackPixel(392,  4);
        setBlackPixel(393,  4);
        setBlackPixel(394,  4);
        setBlackPixel(395,  5);
        setBlackPixel(391,  6);
        setBlackPixel(395,  6);
        setBlackPixel(392,  7);
        setBlackPixel(393,  7);
        setBlackPixel(394,  7);

        // Draw L
        setBlackPixel(391, 10);
        setBlackPixel(391, 11);
        setBlackPixel(391, 12);
        setBlackPixel(391, 13);
        setBlackPixel(391, 14);
        setBlackPixel(391, 15);
        setBlackPixel(391, 16);
        setBlackPixel(392, 16);
        setBlackPixel(393, 16);
        setBlackPixel(394, 16);
        setBlackPixel(395, 16);
      }
      else {
        // Erase S
        setWhitePixel(392,  1);
        setWhitePixel(393,  1);
        setWhitePixel(394,  1);
        setWhitePixel(391,  2);
        setWhitePixel(395,  2);
        setWhitePixel(391,  3);
        setWhitePixel(392,  4);
        setWhitePixel(393,  4);
        setWhitePixel(394,  4);
        setWhitePixel(395,  5);
        setWhitePixel(391,  6);
        setWhitePixel(395,  6);
        setWhitePixel(392,  7);
        setWhitePixel(393,  7);
        setWhitePixel(394,  7);

        // Erase L
        setWhitePixel(391, 10);
        setWhitePixel(391, 11);
        setWhitePixel(391, 12);
        setWhitePixel(391, 13);
        setWhitePixel(391, 14);
        setWhitePixel(391, 15);
        setWhitePixel(391, 16);
        setWhitePixel(392, 16);
        setWhitePixel(393, 16);
        setWhitePixel(394, 16);
        setWhitePixel(395, 16);
      }
    }
  #endif // !DMCP_BUILD
#endif // !TESTSUITE_BUILD
