// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

#include "c47.h"

void drawBattery(uint16_t voltage);

#ifdef PC_BUILD
  void mockupSB(void);
#endif

#if !defined(TESTSUITE_BUILD)


  bool_t timeChanged(void) {
    char timeString[8];
    getTimeString(timeString);
    if(strcmp(timeString, oldTime)) {
      strcpy(oldTime, timeString);
      return true;
    } else {
      return false;                            //returns the strcmp(dateTimeString, oldTime) comparison
    }
  }


  bool_t showDateTime(void) {
    if(timeChanged()) {                        //creates oldTime here
      return false;
    }
    #if (DEBUG_INSTEAD_STATUS_BAR == 1)
      return false;
    #endif // (DEBUG_INSTEAD_STATUS_BAR == 1)

    if(!((SBARUPD_Date) || (SBARUPD_Time) || (SBARUPD_WoY))) {
      return false;
    }
    uint32_t x = X_DATE;
    if(SBARUPD_Date || SBARUPD_WoY) {
      getDateString(dateTimeString);
    }
    if(SBARUPD_Date) {
      x = showString(dateTimeString, &standardFont, x, 0, vmNormal, true, true);
    }
    else {
      lcd_fill_rect(x, 0, X_TIME - x, 20, LCD_SET_VALUE);
      x = X_TIME;
    }

    if(SBARUPD_Time) {
      x = showGlyph(getSystemFlag(FLAG_TDM24) ? " " : STD_SPACE_3_PER_EM, &standardFont, x, 0, vmNormal, true, true, false); // is 0+0+8 pixel wide
      x = showString(oldTime, &standardFont, x, 0, vmNormal, true, false);
      lcd_fill_rect(x, 0, X_REAL_COMPLEX - x, 20, LCD_SET_VALUE);
    }

    if(SBARUPD_WoY) {
      x = showGlyph(STD_SPACE_3_PER_EM, &standardFont, x, 0, vmNormal, true, true, false);
      getWeekOfYearString(dateTimeString);
      x = showString(dateTimeString, &standardFont, x, 0, vmNormal, true, false);
      lcd_fill_rect(x, 0, X_REAL_COMPLEX - x, 20, LCD_SET_VALUE);
    }
    if(Y_SHIFT == 0 && X_SHIFT < 200) {
      showShiftState();
    }
    return true;
  }





//   #define flagSBClear false
//   #define SB_IGNORE  0
//   #define SB_CLEAR   1
//   #define SB_CHANGED 2
//   uint8_t didFlagChange1(bool_t tmp, bool_t *old) {
//     if(flagSBClear) {
//       *old = tmp;
//       return SB_CLEAR;
//     }
//     if(tmp != *old) {
//       *old = !(*old);
//       return SB_CHANGED;
//     }
//     *old = tmp;
//     return SB_IGNORE;
//   }
// 
// bool_t bFLAG_CPXRES        = false;
// bool_t bFLAG_POLAR         = false;
// bool_t bFLAG_GROW          = false;
// bool_t bFLAG_ENDPMT        = false;
// bool_t bFLAG_ERPN          = false;
// bool_t bwatchIconEnabled   = false;
// bool_t bserialIOIconEnabled= false;
// bool_t bprinterIconEnabled = false;
// bool_t bFLAG_USER          = false;

  #define flagSBClear false    //future flag to to a once off clear
  #define SB_IGNORE  0
  #define SB_CLEAR   1
  #define SB_CHANGED 2

  uint16_t statusFlags = 0;
  #define bFLAG_CPXRES         ((bool_t*)1)
  #define bFLAG_POLAR          ((bool_t*)2)
  #define bFLAG_GROW           ((bool_t*)3)
  #define bFLAG_ENDPMT         ((bool_t*)4)
  #define bFLAG_ERPN           ((bool_t*)5)
  #define bwatchIconEnabled    ((bool_t*)6)
  #define bserialIOIconEnabled ((bool_t*)7)
  #define bprinterIconEnabled  ((bool_t*)8)
  #define bFLAG_USER           ((bool_t*)9)

  uint8_t didFlagChange1(bool_t tmp, bool_t *old) {
    // Convert pointer to bit position (offset by 1)
    uint8_t bitPos = (uint8_t)((uintptr_t)old - 1);
    bool_t oldValue = (statusFlags >> bitPos) & 1;
    if(flagSBClear) {
      statusFlags = (statusFlags & ~(1 << bitPos)) | (tmp << bitPos);
      return SB_CLEAR;
    }
    if(tmp != oldValue) {
      statusFlags ^= (1 << bitPos);
      return SB_CHANGED;
    }
    statusFlags = (statusFlags & ~(1 << bitPos)) | (tmp << bitPos);
    return SB_IGNORE;
  }


  void showRealComplexResult(void) {
    if(!(SBARUPD_ComplexResult)) return;
    int32_t x = X_REAL_COMPLEX;
    switch(didFlagChange1(getSystemFlag(FLAG_CPXRES), bFLAG_CPXRES)) {
      case SB_CHANGED: {
        x = showGlyph(getSystemFlag(FLAG_CPXRES) ? STD_COMPLEX_C : STD_REAL_R, &standardFont, x, 0, vmNormal, true, false, false); // Complex C is 0+8+3 pixel wide
        __attribute__((fallthrough));
      }
      case SB_CLEAR: {
        lcd_fill_rect(x, 0, (SBARUPD_ComplexResult ? X_COMPLEX_MODE : X_COMPLEX_MODE + X_COMPLEX_MODE_ADJ) - x, 20, LCD_SET_VALUE);
        break;
      }
      default:break;
    }
  }



  void showComplexMode(void) {
    if(!(SBARUPD_ComplexMode)) return;
    int32_t x =  SBARUPD_ComplexResult ? X_COMPLEX_MODE : X_COMPLEX_MODE + X_COMPLEX_MODE_ADJ;
    switch(didFlagChange1(getSystemFlag(FLAG_POLAR), bFLAG_POLAR)) {
      case SB_CHANGED: {
        x = showGlyph(getSystemFlag(FLAG_POLAR) ? STD_SUN : STD_RIGHT_ANGLE, &standardFont, x, 0, vmNormal, true, true, false); // Sun         is 0+12+2 pixel wide
        __attribute__((fallthrough));
      }
      case SB_CLEAR: {
        lcd_fill_rect(x, 0, X_ANGULAR_MODE - x, 20, LCD_SET_VALUE);
        break;
      }
      default:break;
    }
  }


//todo
  void showAngularMode(void) {
    if(!((SBARUPD_AngularModeBasic) | (SBARUPD_AngularMode))) return;

    uint32_t x = X_ANGULAR_MODE;

    if(SBARUPD_AngularModeBasic) {
      x = showGlyph(STD_MEASURED_ANGLE, &standardFont, x, 0, vmNormal, true, true, false); // Angle is 0+9 pixel wide
    }

    switch(currentAngularMode) {
      case amRadian: {
        x = showGlyph(STD_SUP_BOLD_r,         &standardFont, x, 0, vmNormal, true, false, false); // r  is 0+6 pixel wide
        break;
      }

      case amMultPi: {
        x = showGlyph(STD_SUP_pir,            &standardFont, x, 0, vmNormal, true, false, false); // pi is 0+9 pixel wide
        break;
      }

      case amGrad: {
        x = showGlyph(STD_SUP_BOLD_g,         &standardFont, x, 0, vmNormal, true, false, false); // g  is 0+6 pixel wide
        break;
      }

      case amDegree: {
        x = showGlyph(STD_DEGREE,             &standardFont, x, 0, vmNormal, true, false, false); // °  is 0+6 pixel wide
        break;
      }

      case amDMS: {
        x = showGlyph(STD_RIGHT_DOUBLE_QUOTE, &standardFont, x, 0, vmNormal, true, false, false); // "  is 0+6 pixel wide
        break;
      }

      default: {
        x = showGlyph(STD_QUESTION_MARK,      &standardFont, x, 0, vmNormal, true, false, false); // ?
      }
    }
    lcd_fill_rect(x, 0, X_FRAC_MODE - x, 20, LCD_SET_VALUE);
  }


//todo
  void showFracMode(void) {
    if(!(SBARUPD_FractionModeAndBaseMode)) return;
    char statusMessage[20];

    uint32_t x = X_FRAC_MODE;

    if(lastIntegerBase != 0) {
      if(topHex) {
        x = showString("#KEY", &standardFont, x, 0 , vmNormal, true, true);
        lcd_fill_rect(x, 0, 26, 20, LCD_SET_VALUE);
        x = showString(STD_SUB_A STD_SUB_MINUS STD_SUB_F,  &standardFont, x, -4 , vmNormal, true, true);
      }
      else {
        x = showString("#BASE", &standardFont, x, 0, vmNormal, true, true);
      }
      lcd_fill_rect(x, 0, X_INTEGER_MODE - x, 20, LCD_SET_VALUE);
      return;
    }

    //a b/c
    char divStr[10];
    if(getSystemFlag(FLAG_FRACT) || getSystemFlag(FLAG_IRFRAC)) {
      if(getSystemFlag(FLAG_PROPFR)) {
        lcd_fill_rect(x, 0, 11, 20, LCD_SET_VALUE);
        raiseString = 3;
        strcpy(divStr,"a" STD_SPACE_4_PER_EM);
        x = showString(divStr, &standardFont, x, 0, vmNormal, true, true) - 3;
      }
      lcd_fill_rect(x, 0, 7, 20, LCD_SET_VALUE);
      raiseString = 9;
      strcpy(divStr, STD_SUB_b);
      x = showString(divStr, &standardFont, x, 0, vmNormal, true, true) - 2;
    }

    #define lowerUnderLine 2 //lower the /1200x a few pixels to create to idea of under the line
    strcpy(divStr,"/");
    compressString = 1;
    int xx = x;
    x = showString(divStr, &standardFont, x, lowerUnderLine-1, vmNormal, false, true);
    lcd_fill_rect(xx, 0, x-xx, lowerUnderLine-1, LCD_SET_VALUE);

    compressString = 1;
    if(denMax == 0 || denMax > MAX_DENMAX) {
      sprintf(statusMessage,"max");
    } else {
      sprintf(statusMessage, "%" PRIu32,denMax);
    }
    xx = x;
    x = showString(statusMessage, &standardFont, x, lowerUnderLine, vmNormal, false, true);
    lcd_fill_rect(xx, 0, x-xx, lowerUnderLine, LCD_SET_VALUE);

    if(!getSystemFlag(FLAG_IRFRAC) && getSystemFlag(FLAG_DENFIX)) {
      raiseString = 3;
      lcd_fill_rect(++x, 0, 11, 20, LCD_SET_VALUE);
      x = showString(STD_SUB_f, &standardFont, x, lowerUnderLine, vmNormal, true, true);
    }

    if((getSystemFlag(FLAG_IRFRAC)) || (!getSystemFlag(FLAG_IRFRAC) && !getSystemFlag(FLAG_DENFIX) && !getSystemFlag(FLAG_DENANY))) {
      strcpy(divStr,PRODUCT_SIGN);
      lcd_fill_rect(++x, 0, 11, 20, LCD_SET_VALUE);
      raiseString = 2;
      x = showString(divStr, &standardFont, x, lowerUnderLine, vmNormal, true, true) + (getSystemFlag(FLAG_MULTx) ? 0 : 2);
    }

    if(getSystemFlag(FLAG_IRFRAC)) {
      strcpy(divStr,STD_IRRATIONAL_I);
      lcd_fill_rect(--x, 0, 9, 20, LCD_SET_VALUE);
      raiseString = 1;
      x = showString(divStr, &standardFont, x, 0, vmNormal, false, false) + 2;

      //TO USE REAL II FONT ABOVE. Previous spacing issue in font, fixed, keeping the old manual way for reference if needed
      //   strcpy(divStr,"I");
      //   raiseString = 1;
      //   showString(divStr, &standardFont, x, 0, vmNormal, true, true);
      //   raiseString = 1;
      //   x = showString(divStr, &standardFont, x+1, 0, vmNormal, true, true);
      //   for(uint16_t yy = 4; yy<=11; yy++) {
      //     setWhitePixel(x - 5, yy);
      //   }
    }

    if((getSystemFlag(FLAG_IRFRAC) || getSystemFlag(FLAG_FRACT)) && (fractionDigits > 0 && fractionDigits < 34)) {
      compressString = 1;
      x = showString(STD_ALMOST_EQUAL, &standardFont, x - 1, 0, vmNormal, true, false);
      if(x >= X_INTEGER_MODE - 1) {
        lcd_fill_rect(X_INTEGER_MODE - 1, 0, 1, 20, LCD_SET_VALUE);        
      }
    }

    if(x <= X_INTEGER_MODE) {
      lcd_fill_rect(x, 0, X_INTEGER_MODE - x, 20, LCD_SET_VALUE);
    }
  }


//todo shortIntegerWordSize << 2 + shortIntegerMode
  void showIntegerMode(void) {
    if(!(SBARUPD_IntegerMode)) return;
    char statusMessage[10];
    sprintf(statusMessage, "%s%" PRIu8 ":%c", shortIntegerWordSize <= 9 ? " " : "", shortIntegerWordSize, shortIntegerMode==SIM_1COMPL?'1':(shortIntegerMode==SIM_2COMPL?'2':(shortIntegerMode==SIM_UNSIGN?'u':(shortIntegerMode==SIM_SIGNMT?'s':'?'))));
    int32_t x = showString(statusMessage, &standardFont, X_INTEGER_MODE, 0, vmNormal, true, true);
    lcd_fill_rect(x, 0, X_OVERFLOW_CARRY - x, 20, LCD_SET_VALUE);
  }



  void showMatrixMode(void) {
    if(!(SBARUPD_MatrixMode)) return;
    char statusMessage[5];
    int32_t x = X_MATRIX_MODE;
    switch(didFlagChange1(getSystemFlag(FLAG_GROW), bFLAG_GROW)) {
      case SB_CHANGED: {
        sprintf(statusMessage, getSystemFlag(FLAG_GROW) ? "grow" : "wrap");
        compressString = 1;
        x = showString(statusMessage, &standardFont, x, 0, vmNormal, true, true);
        __attribute__((fallthrough));
      }
      case SB_CLEAR: {
        lcd_fill_rect(x, 0, X_OVERFLOW_CARRY - x, 20, LCD_SET_VALUE);
        break;
      }
      default:break;
    }
  }



  void showTvmMode(void) {
    if(!(SBARUPD_TVMMode)) return;
    int32_t x = X_INTEGER_MODE;
    switch(didFlagChange1(getSystemFlag(FLAG_ENDPMT), bFLAG_ENDPMT)) {
      case SB_CHANGED: {
        x = showString(getSystemFlag(FLAG_ENDPMT) ? "END" : "BEG", &standardFont, x, 0, vmNormal, true, true);
        __attribute__((fallthrough));
      }
      case SB_CLEAR: {
        lcd_fill_rect(x, 0, X_OVERFLOW_CARRY - x, 20, LCD_SET_VALUE);
        break;
      }
      default:break;
    }
  }


//todo
  void showOverflowCarry(void) {
    if(!(SBARUPD_OCCarryMode)) return;
    int32_t x = showGlyph(STD_OVERFLOW_CARRY, &standardFont, X_OVERFLOW_CARRY, 0, vmNormal, true, false, false); // STD_OVERFLOW_CARRY is 0+6+3 pixel wide
    lcd_fill_rect(x, 0, X_ALPHA_MODE - x, 20, LCD_SET_VALUE);
    if(!getSystemFlag(FLAG_OVERFLOW)) { // Overflow flag is cleared
      lcd_fill_rect(X_OVERFLOW_CARRY, 2, 6, 7, LCD_SET_VALUE);
    }

    if(!getSystemFlag(FLAG_CARRY)) { // Carry flag is cleared
      lcd_fill_rect(X_OVERFLOW_CARRY, 12, 6, 7, LCD_SET_VALUE);
    }
  }



//todo
  void showHideAlphaMode(void) {
    if(!(SBARUPD_AlphaMode) || calcMode == CM_GRAPH) return;
    int status=0;
    uint8_t nChar;
    if(scrLock == NC_NORMAL) {
      nChar = nextChar;
    }
    else {
      nChar = scrLock;
    }
    if(((plainTextMode || calcMode == CM_EIM || (catalog && catalog != CATALOG_MVAR) || (tam.mode != 0 && tam.alpha)))) {

      #if defined (PC_BUILD)
        if(deadKey != 0) {
          status = 20;
        } else
      #endif

      if(plainTextMode) {                  //TODO this flag's purpose must be checked
        if(alphaCase == AC_UPPER) {
          setSystemFlag(FLAG_alphaCAP);
        } else {
          clearSystemFlag(FLAG_alphaCAP);
        }
      }

      if(getSystemFlag(FLAG_NUMLOCK) && !shiftF && !shiftG) {
          if(alphaCase == AC_UPPER)                  { status = 3 - (nChar == NC_SUBSCRIPT ? 2 : nChar == NC_SUPERSCRIPT ? 1:0); } else
          if(alphaCase == AC_LOWER)                  { status = 6 - (nChar == NC_SUBSCRIPT ? 2 : nChar == NC_SUPERSCRIPT ? 1:0); }
        } else
          if(alphaCase == AC_LOWER && shiftF){
                                                       status = 12 - (nChar == NC_SUBSCRIPT ? 2 : nChar == NC_SUPERSCRIPT ? 1:0); //A
          } else
            if(alphaCase == AC_UPPER && shiftF){
                                                       status = 18 - (nChar == NC_SUBSCRIPT ? 2 : nChar == NC_SUPERSCRIPT ? 1:0);   //a
            } else //at this point shiftF is false
              if(alphaCase == AC_UPPER)  { //UPPER
                if(shiftG)                                               { status =  3 - (nChar == NC_SUBSCRIPT ? 2 : nChar == NC_SUPERSCRIPT ? 1:0); } else
                if(!shiftG && !shiftF && !getSystemFlag(FLAG_NUMLOCK))   { status = 12 - (nChar == NC_SUBSCRIPT ? 2 : nChar == NC_SUPERSCRIPT ? 1:0); }
              } else
                if(alphaCase == AC_LOWER)  { //LOWER
                  if(shiftG)                                             { status =  3 - (nChar == NC_SUBSCRIPT ? 2 : nChar == NC_SUPERSCRIPT ? 1:0); } else
                  if(!shiftG && !shiftF && !getSystemFlag(FLAG_NUMLOCK)) { status = 18 - (nChar == NC_SUBSCRIPT ? 2 : nChar == NC_SUPERSCRIPT ? 1:0); }
                }
    }

    int32_t x = X_ALPHA_MODE;
    if((SBARUPD_AlphaMode)) {
      switch(status) {
        case  1: x = showString(STD_SUB_N, &standardFont, x, -2, vmNormal, true, false); break; //sub    // STD_ALPHA is 0+9+2 pixel wide
        case  2: x = showString(STD_SUB_N, &standardFont, x,-11, vmNormal, true, false); break; //sup
        case  3: x = showString(STD_num,   &standardFont, x,  0, vmNormal, true, false); break; //normal

        case  4: x = showString(STD_SUB_n, &standardFont, x, -2, vmNormal, true, false); break; //sub
        case  5: x = showString(STD_SUB_n, &standardFont, x,-11, vmNormal, true, false); break; //sup
        case  6: x = showString(STD_n,     &standardFont, x,  0, vmNormal, true, false); break; //normal

//        case  7: showString(STD_SIGMA, &standardFont, X_ALPHA_MODE,  0, vmNormal, true, false); break; //sub
//        case  8: showString(STD_SIGMA, &standardFont, X_ALPHA_MODE,  0, vmNormal, true, false); break; //sup
//        case  9: showString(STD_SIGMA, &standardFont, X_ALPHA_MODE,  0, vmNormal, true, false); break; //normal

        case 10: x = showString(STD_SUB_A, &standardFont, x, -2, vmNormal, true, false); break; //sub
        case 11: x = showString(STD_SUB_A, &standardFont, x, -11, vmNormal, true, false); break; //sup   //not possible
        case 12: x = showString(STD_A    , &standardFont, x,  0, vmNormal, true, false); break; //normal

//        case 13: showString(STD_sigma, &standardFont, X_ALPHA_MODE,  0, vmNormal, true, false); break; //sub
//        case 14: showString(STD_sigma, &standardFont, X_ALPHA_MODE,  0, vmNormal, true, false); break; //sup
//        case 15: showString(STD_sigma, &standardFont, X_ALPHA_MODE,  0, vmNormal, true, false); break; //normal

        case 16: x = showString(STD_SUB_a, &standardFont, x, -2, vmNormal, true, false); break; //sub
        case 17: x = showString(STD_SUB_a, &standardFont, x, -11, vmNormal, true, false); break; //sup    //not possible
        case 18: x = showString(STD_a    , &standardFont, x,  0, vmNormal, true, false); break; //normal

        #if defined (PC_BUILD)
          case 20: x = showString(STD_BOX  , &standardFont, x,  0, vmNormal, true, false); break; //deadkey
        #endif
        default:;
      }
    }
   lcd_fill_rect(x, 0, X_HOURGLASS - x, 20, LCD_SET_VALUE);
  }


//todo
  void showHideHourGlass(void) {
    const int indicatorWidth = 13; //indicatorWidth
    if(!(SBARUPD_HourGlass)) {
      return;
    }

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
    int32_t x = (GRAPHMODE ? X_HOURGLASS_GRAPHS : X_HOURGLASS);
    switch(programRunStop) {
      case PGM_WAITING: {
        x = showGlyph(STD_NEG_EXCLAMATION_MARK, &standardFont, x - 1, 0, vmNormal, true, false, false);
        lcd_fill_rect(x, 0, indicatorWidth - x - 1, 20, LCD_SET_VALUE);
        break;
      }
      case PGM_RUNNING: {
        //if((lastProgramRunStop & PGM_DEFINED_MASK) != PGM_RUNNING) {
        //  lcd_fill_rect(x - 1, 0, indicatorWidth, 20, LCD_SET_VALUE);
        //}
        x = showGlyph(STD_P, &standardFont, x + 1, 0, vmNormal, true, false, false);
        lcd_fill_rect(x, 0, indicatorWidth - x - 1, 20, LCD_SET_VALUE);
        break;
      }
      default: {
        if(hourGlassIconEnabled) {
          //if((lastProgramRunStop  & PGM_DEFINED_MASK) == PGM_RUNNING || (lastProgramRunStop & PGM_DEFINED_MASK) == PGM_WAITING) {
          //  lcd_fill_rect(x - 1, 0, indicatorWidth, 20, LCD_SET_VALUE);
          //}
          x = showGlyph(STD_HOURGLASS, &standardFont, x, 0, vmNormal, true, false, false); // is 0+11+3 pixel wide //Shift the hourglass to a visible part of the status bar
          lcd_fill_rect(x, 0, indicatorWidth - x - 1, 20, LCD_SET_VALUE);
        }
        else {
          lcd_fill_rect(x - 1, 0, indicatorWidth, 20, LCD_SET_VALUE);
        }
      }
    }
    uint8_t tmpb = (programRunStop & PGM_DEFINED_MASK) | (hourGlassIconEnabled ? !PGM_DEFINED_MASK : 0); //force undefined bit, which forces the hourglass/P indicator update
    force_refresh((lastProgramRunStop != tmpb || lastProgramRunStop == PGM_UNDEFINED) ? force : timed);
    //#if defined (PC_BUILD)
    //  if(lastProgramRunStop != programRunStop) printf("###### force_refresh(force) active: lastProgramRunStop != programRunStop:%i ########\n",lastProgramRunStop != programRunStop);
    //#endif //PC_BUILD
    lastProgramRunStop = tmpb;
  }

//todo
  void light_ASB_icon(void) {
    if(!(SBARUPD_AlphaMode) || calcMode == CM_GRAPH) return;
    lcd_fill_rect(X_ALPHA_MODE,18,9,2,LCD_EMPTY_VALUE);        //underline the alha mode character, AND show the asmBuffer as well
    compressString = 1;
    int32_t x = showString(asmBuffer, &standardFont, X_ASM, 0, vmNormal, true, false) + 1;
    lcd_fill_rect(x, 0, X_SERIAL_IO - x, 18, LCD_SET_VALUE);
    force_refresh(force);
  }


//todo
  void kill_ASB_icon(void) {
    if(!(SBARUPD_AlphaMode) || calcMode == CM_GRAPH) return;
    lcd_fill_rect(X_ALPHA_MODE,18,9,2,LCD_SET_VALUE);        //underline the alha mode character, AND show the asmBuffer as well
    lcd_fill_rect(X_ASM, 0, X_SERIAL_IO - X_ASM, 20, LCD_SET_VALUE);
    force_refresh(force);
  }


//todo
  static void showHideASB(void) {
    if(!(SBARUPD_AlphaMode) || calcMode == CM_GRAPH) return;
    if(fnTimerGetStatus(TO_ASM_ACTIVE) == TMR_RUNNING) {
      light_ASB_icon();
    }
    else {
      kill_ASB_icon();
    }
  }


  void showStackSize(void) {
    if(!(SBARUPD_StackSize)) return;
    uint32_t x = X_SSIZE_BEGIN;
    switch(didFlagChange1(getSystemFlag(FLAG_ERPN), bFLAG_ERPN)) {
      case SB_CHANGED: {
        // Standard stack size, inversed if RPN. Note it moved 5 pixels left in X_SSIZE_BEGIN
        if(getSystemFlag(FLAG_ERPN)) {
          x = showGlyph(STD_SPACE_6_PER_EM, &standardFont, x, 0, vmNormal, true, true, false); // is 0+6+2 pixel wide
          x = showGlyph(getSystemFlag(FLAG_SSIZE8) ? STD_8 : STD_4, &standardFont, x, 0, vmNormal, true, true, false); // is 0+6+2 pixel wide
        }
        else {
          x = showGlyph(STD_SPACE_6_PER_EM, &standardFont, x, 0, vmReverse, false, true, false); // is 0+6+2 pixel wide
          x = showGlyph(getSystemFlag(FLAG_SSIZE8) ? STD_8 : STD_4, &standardFont, x, 0, vmReverse, false, true, false); // is 0+6+2 pixel wide
        }
        __attribute__((fallthrough));
      }
      case SB_CLEAR: {
        lcd_fill_rect(x, 0, X_ASM - x, 20, LCD_SET_VALUE);
        break;
      }
      default:break;
    }
  }



  void showHideWatch(void) {
    if(!(SBARUPD_StopWatch)) return;
    int32_t x = X_STOPWATCH;
    switch(didFlagChange1(watchIconEnabled, bwatchIconEnabled)) {
      case SB_CHANGED: {
        if(watchIconEnabled) {
          x = showGlyph(STD_TIMER, &standardFont, x, 0, vmNormal, true, false, false); // is 0+13+1 pixel wide
        }
       __attribute__((fallthrough));
      }
      case SB_CLEAR: {
        lcd_fill_rect(x, 0, X_SSIZE_BEGIN - x, 20, LCD_SET_VALUE);
        break;
      }
      default:break;
    }
  }



  void showHideSerialIO(void) {
    if(!(SBARUPD_SerialIO)) return;
    int32_t x = X_SERIAL_IO;
    switch(didFlagChange1(serialIOIconEnabled, bserialIOIconEnabled)) {
      case SB_CHANGED: {
        if(serialIOIconEnabled) {
          x = showGlyph(STD_SERIAL_IO, &standardFont, x, 0, vmNormal, true, false, false); // is 0+8+3 pixel wide
        }
        __attribute__((fallthrough));
      }
      case SB_CLEAR: {
        lcd_fill_rect(x, 0, X_PRINTER - x, 20, LCD_SET_VALUE);
        break;
      }
      default:break;
    }
  }



  void showHidePrinter(void) {
    if(!(SBARUPD_Printer)) return;
    int32_t x = X_PRINTER;
    switch(didFlagChange1(printerIconEnabled, bprinterIconEnabled)) {
      case SB_CHANGED: {
        if(printerIconEnabled) {
          x = showGlyph(STD_PRINTER,   &standardFont, x, 0, vmNormal, true, false, false); // is 0+12+3 pixel wide
        }
        __attribute__((fallthrough));
      }
      case SB_CLEAR: {
        lcd_fill_rect(x, 0, X_USER_MODE - x, 20, LCD_SET_VALUE);
        break;
      }
      default:break;
    }
  }



  void showHideUserMode(void) {
    if(!(SBARUPD_UserMode)) return;
    int32_t x = X_USER_MODE;
    switch(didFlagChange1(getSystemFlag(FLAG_USER), bFLAG_USER)) {
      case SB_CHANGED: {
        if(getSystemFlag(FLAG_USER)) {
          x = showGlyph(STD_USER_MODE, &standardFont, x, 0, vmNormal, false, false, false); // STD_USER_MODE is 0+12+2 pixel wide
        }
        __attribute__((fallthrough));
      }
      case SB_CLEAR: {
        lcd_fill_rect(x, 0, X_BATTERY - x, 20, LCD_SET_VALUE);
        refreshModeGui();
        break;
      }
      default:break;
    }
  }


void drawBattery(uint16_t voltage) {
  lcd_fill_rect(X_BATTERY, 0, 11, 20, LCD_SET_VALUE);
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


//todo
  #if defined(DMCP_BUILD)
    void showHideUsbLowBattery(void) {
      if(!(SBARUPD_Battery)) {
        // Clear the space used by the USB / LOWBAT glyph
        lcd_fill_rect(X_BATTERY, 0, 11, 20, LCD_SET_VALUE);
        return;
      }
      if(getSystemFlag(FLAG_USB)) {
        showGlyph(STD_USB_SYMBOL, &standardFont, X_BATTERY, 0, vmNormal, true, false, false); // is 0+9+2 pixel wide
      }
      else {
        if(SBARUPD_BatVoltage) {
          drawBattery(min(get_vbat(), vbatVIntegrated));
        }
        else if(getSystemFlag(FLAG_LOWBAT)) {
          showGlyph(STD_BATTERY, &standardFont, X_BATTERY, 0, vmNormal, true, false, false); // is 0+10+1 pixel wide
        }
        else {
          // Clear the space used by the USB / LOWBAT glyph
          lcd_fill_rect(X_BATTERY, 0, 11, 20, LCD_SET_VALUE);
        }
      }
    }
  #endif // DMCP_BUILD


#define FLAGSETS  (uint32_t)( (topHex    << (32- 1)) \
                  + (scrLock             << (32- 2)) \
                  + (calcMode            << (32- 7)) \
                  + (fractionDigits      << (32-12)) \
                  + (shortIntegerWordSize<< (32-14)) \
                  + (alphaCase           << (32-16)) \
                  + (programRunStop      << (32-18)) \
                  + (watchIconEnabled    << (32-19)) \
                  + (serialIOIconEnabled << (32-20)) \
                  + (printerIconEnabled  << (32-21)) )

uint32_t flagsSettingsOld  = 0;
uint32_t flagsSettingsTest = 0;
uint32_t systemFlags0Mem   = 0;
uint32_t systemFlags1Mem   = 0;
uint32_t denMaxMem         = 0;

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

//mockupSB();
//return;

    #if (DEBUG_INSTEAD_STATUS_BAR == 1)
      char statusMessage[100];
      sprintf(statusMessage, "%s%d %s/%s  mnu:%s fi:%d", catalog ? "asm:" : "", catalog, tam.mode ? "/tam" : "", getCalcModeName(calcMode),indexOfItems[-softmenu[softmenuStack[0].softmenuId].menuItem].itemCatalogName, softmenuStack[0].firstItem);
      showString(statusMessage, &standardFont, X_DATE, 0, vmNormal, true, true);
    #else // DEBUG_INSTEAD_STATUS_BAR != 1


      //This sub-section returns, with no statusbar updates if none of the settings changed. 
      //lastProgramRunStop = PGM_UNDEFINED is used as a flag to indicate the status bar was cleared; it was set in clearScreen() in screen.h
      flagsSettingsTest = FLAGSETS;
      if(!(systemFlags0 == systemFlags0Mem && systemFlags1 == systemFlags1Mem && denMax == denMaxMem && flagsSettingsOld == flagsSettingsTest)) {
           flagsSettingsOld = flagsSettingsTest;
           systemFlags0Mem  = systemFlags0;
           systemFlags1Mem  = systemFlags1;
           denMaxMem        = denMax;
           if(lastProgramRunStop != PGM_UNDEFINED) { 
             return;
           }
      }


      if(GRAPHMODE) {
        lcd_fill_rect(0, 0, 158, 20, LCD_SET_VALUE);
      }
      showDateTime();
      if(Y_SHIFT==0 && X_SHIFT<200) {
        showShiftState();
      }
      showHideHourGlass();
      if(GRAPHMODE) {                      // With graph displayed, only update the time, as the other items are clashing with the graph display screen
        return;
      }
      showRealComplexResult();
      showComplexMode();
      showAngularMode();
      showFracMode();
      if(calcMode == CM_MIM) {
        showMatrixMode();
      }
      else if(softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_TVM || softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_FIN) {
        showTvmMode();
      }
      else {
        showIntegerMode();
        showOverflowCarry();
      }
      showHideAlphaMode();
      showStackSize();
      showHideWatch();
      showHideSerialIO();
      showHidePrinter();
      if(Y_SHIFT==0 && X_SHIFT >300) {
        showShiftState();
      }
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

      #if defined(BATTERYTEST)
        drawBattery(exponentLimit); //test battery indicator
        return;                     //test battery indicator
      #endif

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


#ifdef PC_BUILD
  void mockupSB(void) {
    uint32_t x = 0;
    uint32_t xx = 0;
    char statusMessage[100];
    #define L0 0
    #define L1 20
    #define L2 40
    #define L3 60
    #define L4 80
    #define L5 100

    //All status bar printing functions copied frm the individual sections to creat a statusbar mockup

      showDateTime();
      if(Y_SHIFT==0 && X_SHIFT<200) showShiftState();
      showGlyph(STD_MODE_F, &standardFont, X_SHIFT_L, L5, vmNormal, true, true, false);   // f is pixel 4+8+3 wide
      showGlyph(STD_MODE_G, &standardFont, X_SHIFT_R, L5, vmNormal, true, true, false);   // g is pixel 4+10+1 wide

      showRealComplexResult();
      showComplexMode();
      showAngularMode();


      x = showString("#KEY", &standardFont, X_FRAC_MODE, L5 , vmNormal, true, true);//-4 looks good
      x = showString(STD_SUB_A,  &standardFont, x, L5-4 , vmNormal, true, true);         //-4 looks good
      x = showString("-",    &standardFont, x, L5+2 , vmNormal, true, true);         //-4 looks good
      x = showString(STD_SUB_F,  &standardFont, x, L5-4 , vmNormal, true, true);         //-4 looks good
      x = showString("#BASE", &standardFont, X_FRAC_MODE, L4, vmNormal, true, true); //-4 looks good

      x = X_FRAC_MODE;                    //vJM
      char divStr[10];
      raiseString = 9;
      strcpy(divStr,STD_SUB_b);
      x = showString(divStr, &standardFont, x, L3, vmNormal, true, true)-2;
      strcpy(divStr,"/");
      sprintf(statusMessage,"%s",divStr);
      x = showString(statusMessage, &standardFont, x, L3, vmNormal, true, true);
      raiseString = 4;
      sprintf(statusMessage,STD_SUB_c);
      x = showString(statusMessage, &standardFont, x-2, L3, vmNormal, true, true);


      x = X_FRAC_MODE;                    //vJM
      raiseString = 3;
      strcpy(divStr,"a" STD_SPACE_4_PER_EM);
      x = showString(divStr, &standardFont, x, L0, vmNormal, true, true);
      raiseString = 9;
      strcpy(divStr, STD_SUB_b);
      x = showString(divStr, &standardFont, x, L0, vmNormal, true, true)-2;
      strcpy(divStr,"/");

      compressString = 1;             //^JM
      xx=x;
      sprintf(statusMessage,"%s",divStr);
      x = showString(statusMessage, &standardFont, x, L0, vmNormal, true, true);
      raiseString = 4;
      sprintf(statusMessage,STD_SUB_c);
      x = showString(statusMessage, &standardFont, x-2, L0, vmNormal, true, true);


      strcpy(divStr,STD_DOT);
      raiseString = 2;
      x = showString(divStr, &standardFont, x+1, L0, vmNormal, true, true);

      strcpy(divStr,"I");
      raiseString = 2;
      showString(divStr, &standardFont, x, L0, vmNormal, true, true);
      raiseString = 2;
      x = showString(divStr, &standardFont, x+1, L0, vmNormal, true, true);
      x -= 5;
      for(uint16_t yy = 4; yy<=11; yy++) {
        setWhitePixel(x, L0+yy);
      }

      compressString = 1;             //^JM
      x=xx;
      strcpy(divStr,"/");
      sprintf(statusMessage,"%smax",divStr);
      x = showString(statusMessage, &standardFont, x, L1, vmNormal, true, true);

      compressString = 1;             //^JM
      x=xx;
      sprintf(statusMessage, "%s%" PRIu32, divStr,denMax);
      x = showString(statusMessage, &standardFont, x, L2, vmNormal, true, true);

      compressString = 1;             //^JM
      x=xx;
      x = showGlyphCode('f',  &standardFont, x, L2, vmNormal, true, false, false); // f is 0+7+3 pixel wide
      compressString = 1;             //^JM

      x=xx;
      x = showString(PRODUCT_SIGN, &standardFont, x, L2, vmNormal, true, false); // STD_DOT is 0+3+2 pixel wide and STD_CROSS is 0+7+2 pixel wide

      sprintf(statusMessage, "%" PRIu8 ":%c", shortIntegerWordSize, shortIntegerMode==SIM_1COMPL?'1':(shortIntegerMode==SIM_2COMPL?'2':(shortIntegerMode==SIM_UNSIGN?'u':(shortIntegerMode==SIM_SIGNMT?'s':'?'))));
      showString(statusMessage, &standardFont, X_INTEGER_MODE, L0, vmNormal, true, true);

      compressString = 1;             //^JM
      sprintf(statusMessage, "wrap");
      showString(statusMessage, &standardFont, X_INTEGER_MODE - 2, L1, vmNormal, true, true);

      compressString = 1;             //^JM
      sprintf(statusMessage, "END");
      showString(statusMessage, &standardFont, X_INTEGER_MODE, L2, vmNormal, true, true);

      showGlyph(STD_OVERFLOW_CARRY, &standardFont, X_OVERFLOW_CARRY, 0, vmNormal, true, false, false); // STD_OVERFLOW_CARRY is 0+6+3 pixel wide


 //       showString(STD_SUB_N, &standardFont, X_ALPHA_MODE, -2, vmNormal, true, false);   //sub    // STD_ALPHA is 0+9+2 pixel wide
 //       showString(STD_SUB_N, &standardFont, X_ALPHA_MODE,-11, vmNormal, true, false);   //sup
//        showString(STD_num,   &standardFont, X_ALPHA_MODE,  0, vmNormal, true, false);   //normal
//
//        showString(STD_SUB_n, &standardFont, X_ALPHA_MODE, -2, vmNormal, true, false);   //sub
//        showString(STD_SUB_n, &standardFont, X_ALPHA_MODE,-11, vmNormal, true, false);   //sup
//        showString(STD_n,     &standardFont, X_ALPHA_MODE,  0, vmNormal, true, false);   //normal
//
//        showString(STD_SUB_A, &standardFont, X_ALPHA_MODE, -2, vmNormal, true, false);   //sub
//        showString(STD_SUB_A, &standardFont, X_ALPHA_MODE, -11, vmNormal, true, false);   //sup   //not possible
      showString(STD_A    , &standardFont, X_ALPHA_MODE,  0, vmNormal, true, false);   //normal
//
//        showString(STD_SUB_a, &standardFont, X_ALPHA_MODE, -2, vmNormal, true, false);   //sub
//        showString(STD_SUB_a, &standardFont, X_ALPHA_MODE, -11, vmNormal, true, false);   //sup    //not possible
//        showString(STD_a    , &standardFont, X_ALPHA_MODE,  0, vmNormal, true, false);   //normal

      showGlyph(STD_HOURGLASS, &standardFont, calcMode == CM_PLOT_STAT || calcMode == CM_GRAPH ? X_HOURGLASS_GRAPHS : X_HOURGLASS, L1, vmNormal, true, false, false); // is 0+11+3 pixel wide //Shift the hourglass to a visible part of the status bar
      showGlyph(STD_NEG_EXCLAMATION_MARK, &standardFont, (calcMode == CM_PLOT_STAT || calcMode == CM_GRAPH  ? X_HOURGLASS_GRAPHS : X_HOURGLASS) - 1, L3, vmNormal, true, false, false);
      showGlyph(STD_P, &standardFont, (calcMode == CM_PLOT_STAT || calcMode == CM_GRAPH ? X_HOURGLASS_GRAPHS : X_HOURGLASS) + 1, L2, vmNormal, true, false, false);

      strcpy(asmBuffer,"XX");
      compressString = 1;             //^JM
      showString(asmBuffer, &standardFont, X_ASM, L1, vmNormal, true, false);
      asmBuffer[0]=0;

      showGlyph(getSystemFlag(FLAG_SSIZE8) ? STD_8 : STD_4, &standardFont, X_SSIZE_BEGIN, 0, vmNormal, true, false, false); // is 0+6+2 pixel wide

      showGlyph(STD_TIMER, &standardFont, X_STOPWATCH, 0, vmNormal, true, false, false); // is 0+13+1 pixel wide

      showGlyph(STD_SERIAL_IO, &standardFont, X_SERIAL_IO, L1, vmNormal, true, false, false); // is 0+8+3 pixel wide

      showGlyph(STD_PRINTER,   &standardFont, X_PRINTER, 0, vmNormal, true, false, false); // is 0+12+3 pixel wide

      showGlyph(STD_USER_MODE, &standardFont, X_USER_MODE, 0, vmNormal, false, false, false); // STD_USER_MODE is 0+12+2 pixel wide


      light_ASB_icon();
      drawBattery(exponentLimit); //test battery indicator
  }
#endif //PC_BUILD

#endif // !TESTSUITE_BUILD
