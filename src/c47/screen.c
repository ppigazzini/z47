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

#include "screen.h"

#include "assign.h"
#include "browsers/browsers.h"
#include "bufferize.h"
#include "calcMode.h"
#include "charString.h"
#include "config.h"
#include "constantPointers.h"
#include "curveFitting.h"
#include "dateTime.h"
#include "debug.h"
#include "defines.h"
#include "display.h"
#include "error.h"
#include "flags.h"
#include "fonts.h"
#include "c43Extensions/addons.h"
#include "c43Extensions/graphs.h"
#include "c43Extensions/graphText.h"
#include "c43Extensions/inlineTest.h"
#include "items.h"
#include "c43Extensions/jm.h"
#include "c43Extensions/xeqm.h"
#include "keyboard.h"
#include "longIntegerType.h"
#include "c43Extensions/keyboardTweak.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/incDec.h"
#include "memory.h"
#include "mathematics/matrix.h"
#include "plotstat.h"
#include "programming/manage.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "softmenus.h"
#include "stack.h"
#include "sort.h"
#include "statusBar.h"
#include "timer.h"
#include "ui/matrixEditor.h"
#include "version.h"
#include <string.h>

#include "c47.h"


//#define DEBUGCLEARS

#if !defined(TESTSUITE_BUILD)
  #define spc STD_SPACE
  #define spc1 STD_SPACE STD_SPACE_3_PER_EM
  TO_QSPI static const char *whoStr1 = "C47 Development since 2019" spc "by" spc1
                                       "\n"
                                       "Ben" spc "GB," spc1
                                       "D" spc "A" spc "CA," spc1
                                       "Dani" spc "CH," spc1
                                       "Didier" spc "FR," spc1
                                       "\n"
                                       "H" STD_a_RING "kon" spc "NO," spc1
                                       "Jaco" spc "ZA," spc1
                                       "Martin" spc "FR," spc1
                                       "Mihail" spc "JP," spc1
                                       "\n"
                                       "Pauli" spc "AU," spc1
                                       "RJvM" spc "NL," spc1
                                       "Walter" spc "DE.";

  TO_QSPI static const char *versionStr = VERSION_STRING " [EXIT]";

  #if defined(PC_BUILD)
    TO_QSPI static const char *versionStr2 = "C47 Sim " VERSION1 ", compiled " __DATE__;
  #else // !PC_BUILD
    #if defined(TWO_FILE_PGM)
      TO_QSPI static const char *versionStr2 = "C47 QSPI " VERSION1 ", compiled " __DATE__;
    #else // !TWO_FILE_PGM
      #if !defined(TWO_FILE_PGM)
        TO_QSPI static const char *versionStr2 = "C47 No QSPI " VERSION1 ", compiled " __DATE__;
      #endif // !TWO_FILE_PGM
    #endif // TWO_FILE_PGM
  #endif // PC_BUILD

  /* Names of day of week */
  TO_QSPI static const char *nameOfWday_en[8] = {"invalid day of week",                                   "Monday",            "Tuesday",                     "Wednesday",               "Thursday",           "Friday",             "Saturday",             "Sunday"};
  /*
  TO_QSPI static const char *nameOfWday_de[8] = {"ung" STD_u_DIARESIS "ltiger Wochentag",                 "Montag",            "Dienstag",                    "Mittwoch",                "Donnerstag",         "Freitag",            "Samstag",              "Sonntag"};
  TO_QSPI static const char *nameOfWday_fr[8] = {"jour de la semaine invalide",                           "lundi",             "mardi",                       "mercredi",                "jeudi",              "vendredi",           "samedi",               "dimanche"};
  TO_QSPI static const char *nameOfWday_es[8] = {"d" STD_i_ACUTE "a inv" STD_a_ACUTE "lido de la semana", "lunes",             "martes",                      "mi" STD_e_ACUTE "rcoles", "jueves",             "viernes",            "s" STD_a_ACUTE "bado", "domingo"};
  TO_QSPI static const char *nameOfWday_it[8] = {"giorno della settimana non valido",                     "luned" STD_i_GRAVE, "marted" STD_i_GRAVE,          "mercoled" STD_i_GRAVE,    "gioved" STD_i_GRAVE, "venerd" STD_i_GRAVE, "sabato",               "domenica"};
  TO_QSPI static const char *nameOfWday_pt[8] = {"dia inv" STD_a_ACUTE "lido da semana",                  "segunda-feira",     "ter" STD_c_CEDILLA "a-feira", "quarta-feira",            "quinta-feira",       "sexta-feira",        "s" STD_a_ACUTE "bado", "domingo"};
  */
#endif // !TESTSUITE_BUILD

#if defined(PC_BUILD)
  gboolean drawScreen(GtkWidget *widget, cairo_t *cr, gpointer data) {
    cairo_surface_t *imageSurface;

    imageSurface = cairo_image_surface_create_for_data((unsigned char *)screenData, CAIRO_FORMAT_RGB24, SCREEN_WIDTH, SCREEN_HEIGHT, screenStride * 4);
    #if (BIG_SCREEN_COEF != 1)
      cairo_scale(cr, BIG_SCREEN_COEF, BIG_SCREEN_COEF);
    #endif // BIG_SCREEN_COEF != 1
    cairo_set_source_surface(cr, imageSurface, 0, 0);
    cairo_surface_mark_dirty(imageSurface);
    #if (BIG_SCREEN_COEF != 1)
      cairo_pattern_set_filter(cairo_get_source(cr), CAIRO_FILTER_FAST);
    #endif // BIG_SCREEN_COEF != 1
    cairo_paint(cr);
    cairo_surface_destroy(imageSurface);

    screenChange = false;

    return FALSE;
  }


  void copyScreenToClipboard(void) {
    cairo_surface_t *imageSurface;
    GtkClipboard *clipboard;

    clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
    gtk_clipboard_clear(clipboard);
    gtk_clipboard_set_text(clipboard, "", 0); //JM FOUND TIP TO PROPERLY CLEAR CLIPBOARD: https://stackoverflow.com/questions/2418487/clear-the-system-clipboard-using-the-gtk-lib-in-c/2419673#2419673

    imageSurface = cairo_image_surface_create_for_data((unsigned char *)screenData, CAIRO_FORMAT_RGB24, SCREEN_WIDTH, SCREEN_HEIGHT, screenStride * 4);
    gtk_clipboard_set_image(clipboard, gdk_pixbuf_get_from_surface(imageSurface, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT));
  }


  #define CLIPSTR 30000                                         //JMCSV
#else // !PC_BUILD
  #define CLIPSTR TMP_STR_LENGTH                              //JMCSV
#endif // PC_BUILD                                            //JMCSV

#if defined(PC_BUILD) || defined(DMCP_BUILD)        //JMCSV
  static void angularUnitToString(angularMode_t angularMode, char *string) {
    switch(angularMode) {
      case amRadian: strcpy(string, "r");        break;
      case amMultPi: strcpy(string, STD_pi);     break;
      case amGrad:   strcpy(string, "g");        break;
      case amDegree: strcpy(string, STD_DEGREE); break;
      case amDMS:    strcpy(string, "d.ms");     break;
      case amNone:                               break;
      default:       strcpy(string, "?");
    }
  }

  void copyRegisterToClipboardString(calcRegister_t regist, char *clipboardString) {
    longInteger_t lgInt;
    int16_t base, sign, n;
    uint64_t shortInt;
    char string[CLIPSTR];

    switch(getRegisterDataType(regist)) {
      case dtLongInteger:
        convertLongIntegerRegisterToLongInteger(regist, lgInt);
        longIntegerToAllocatedString(lgInt, string, CLIPSTR);
        longIntegerFree(lgInt);
        break;

      case dtTime:
        timeToDisplayString(regist, string, false);
        break;

      case dtDate:
        dateToDisplayString(regist, string);
        break;

      case dtString:
        xcopy(string, REGISTER_STRING_DATA(regist), stringByteLength(REGISTER_STRING_DATA(regist)) + 1);
        break;

      case dtReal34Matrix: {
        dataBlock_t* dblock = REGISTER_REAL34_MATRIX_DBLOCK(regist);
        real34_t *real34 = REGISTER_REAL34_MATRIX_M_ELEMENTS(regist);
        real34_t reduced;
        int rows, columns, len;

        rows = dblock->matrixRows;
        columns = dblock->matrixColumns;
        sprintf(string, "%dx%d", rows, columns);

        for(int i=0; i<rows*columns; i++) {
          strcat(string, LINEBREAK);
          len = strlen(string);

          real34Reduce(real34++, &reduced);
          real34ToString(&reduced, string + len);

          if(strchr(string + len, '.') == NULL && strchr(string + len, 'E') == NULL) {
            strcat(string + len, ".");
          }
        }
        break;
      }

      case dtComplex34Matrix: {
        dataBlock_t* dblock = REGISTER_COMPLEX34_MATRIX_DBLOCK(regist);
        complex34_t *complex34 = REGISTER_COMPLEX34_MATRIX_M_ELEMENTS(regist);
        real34_t reduced;
        int rows, columns, len;

        rows = dblock->matrixRows;
        columns = dblock->matrixColumns;
        sprintf(string, "%dx%d", rows, columns);

        for(int i=0; i<rows*columns; i++, complex34++) {
          strcat(string, LINEBREAK);
          len = strlen(string);

          // Real part
          real34Reduce((real34_t *)complex34, &reduced);
          real34ToString(&reduced, string + len);
          if(strchr(string + len, '.') == NULL && strchr(string + len, 'E') == NULL) {
            strcat(string + len, ".");
          }
          len = strlen(string);

          // Imaginary part
          real34Reduce(((real34_t *)complex34) + 1, &reduced);
          if(real34IsNegative(&reduced)) {
            sprintf(string + len, " - %sx", COMPLEX_UNIT);
            len += 5;
            real34SetPositiveSign(&reduced);
            real34ToString(&reduced, string + len);
          }
          else {
            sprintf(string + len + strlen(string + len), " + %sx", COMPLEX_UNIT);
            len += 5;
            real34ToString(&reduced, string + len);
          }
          if(strchr(string + len, '.') == NULL && strchr(string + len, 'E') == NULL) {
            strcat(string + len, ".");
          }
        }
        break;
      }

      case dtShortInteger:
        convertShortIntegerRegisterToUInt64(regist, &sign, &shortInt);
        base = getRegisterShortIntegerBase(regist);

        n = ERROR_MESSAGE_LENGTH - 100;
        sprintf(errorMessage + n--, "#%d (word size = %u)", base, shortIntegerWordSize);

        if(shortInt == 0) {
          errorMessage[n--] = '0';
        }
        else {
          while(shortInt != 0) {
            errorMessage[n--] = digits[shortInt % base];
            shortInt /= base;
          }
          if(sign) {
            errorMessage[n--] = '-';
          }
        }
        n++;

        strcpy(string, errorMessage + n);
        break;

      case dtReal34: {
        real34_t reduced;

        real34Reduce(REGISTER_REAL34_DATA(regist), &reduced);
        real34ToString(&reduced, string);
        if(strchr(string, '.') == NULL && strchr(string, 'E') == NULL) {
          strcat(string, ".");
        }
        angularUnitToString(getRegisterAngularMode(regist), string + strlen(string));
        break;
      }

      case dtComplex34: {
        real34_t reduced;
        int len;
        char tmpStr[100];

        // Real part
        real34Reduce(REGISTER_REAL34_DATA(regist), &reduced);
        real34ToString(&reduced, tmpStr);
        if(strchr(tmpStr, '.') == NULL && strchr(tmpStr, 'E') == NULL) {
          strcat(tmpStr, ".");
        }
        len = strlen(tmpStr);

        // Imaginary part
        real34Reduce(REGISTER_IMAG34_DATA(regist), &reduced);
        if(real34IsNegative(&reduced)) {
          sprintf(string, "%s - %sx", tmpStr, COMPLEX_UNIT);
          len += 5;
          real34SetPositiveSign(&reduced);
          real34ToString(&reduced, string + len);
        }
        else {
          sprintf(string, "%s + %sx", tmpStr, COMPLEX_UNIT);
          len += 5;
          real34ToString(&reduced, string + len);
        }
        if(strchr(string + len, '.') == NULL && strchr(string + len, 'E') == NULL) {
          strcat(string + len, ".");
        }
        break;
      }

      case dtConfig:
        xcopy(string, "Configuration data", 19);
        break;

      default:
        sprintf(string, "In function copyRegisterXToClipboard, the data type %" PRIu32 " is unknown! Please try to reproduce and submit a bug.", getRegisterDataType(regist));
    }

    stringToUtf8(string, (uint8_t *)clipboardString);
  }
#endif // PC_BUILD || DMCP_BUILD                              //JMCSV

#define checkHPoffset (checkHP && temporaryInformation == TI_NO_INFO ? 50:0)

#if !defined(TESTSUITE_BUILD)
  char letteredRegisterName(calcRegister_t regist) {
    return "XYZTABCDLIJKMNPQRS"[regist - REGISTER_X];
  }
#endif //TESTSUITE_BUILD


#if defined(PC_BUILD)                                         //JMCSV
  void copyRegisterXToClipboard(void) {
    GtkClipboard *clipboard;
    char clipboardString[CLIPSTR];

    clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
    gtk_clipboard_clear(clipboard);
    gtk_clipboard_set_text(clipboard, "", 0); //JM FOUND TIP TO PROPERLY CLEAR CLIPBOARD: https://stackoverflow.com/questions/2418487/clear-the-system-clipboard-using-the-gtk-lib-in-c/2419673#2419673

    copyRegisterToClipboardString(REGISTER_X, clipboardString);
    gtk_clipboard_set_text(clipboard, clipboardString, -1);
  }


  void copyStackRegistersToClipboardString(char *clipboardString) {
    char *ptr = clipboardString;
    const char *sep = "";

    for (calcRegister_t r = REGISTER_S; r >= REGISTER_X; r--) {
      ptr += sprintf(ptr, "%s%c = ", sep, letteredRegisterName(r));
      copyRegisterToClipboardString(r, ptr);
      ptr = strchr(ptr, '\0');
      sep = LINEBREAK;
    }
  }


  void copyStackRegistersToClipboard(void) {
    GtkClipboard *clipboard;
    char clipboardString[10000];

    clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
    gtk_clipboard_clear(clipboard);
    gtk_clipboard_set_text(clipboard, "", 0); //JM FOUND TIP TO PROPERLY CLEAR CLIPBOARD: https://stackoverflow.com/questions/2418487/clear-the-system-clipboard-using-the-gtk-lib-in-c/2419673#2419673

    copyStackRegistersToClipboardString(clipboardString);

    gtk_clipboard_set_text(clipboard, clipboardString, -1);
  }


  void copyAllRegistersToClipboard(void) {
    GtkClipboard *clipboard;
    char clipboardString[15000], *ptr = clipboardString;

    clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
    gtk_clipboard_clear(clipboard);
    gtk_clipboard_set_text(clipboard, "", 0); //JM FOUND TIP TO PROPERLY CLEAR CLIPBOARD: https://stackoverflow.com/questions/2418487/clear-the-system-clipboard-using-the-gtk-lib-in-c/2419673#2419673

    copyStackRegistersToClipboardString(ptr);

    for(int32_t regist=99; regist>=0; --regist) {
      ptr += strlen(ptr);
      sprintf(ptr, LINEBREAK "R%02d = ", regist);
      ptr += strlen(ptr);
      copyRegisterToClipboardString(regist, ptr);
    }

    for(int32_t regist=currentNumberOfLocalRegisters-1; regist>=0; --regist) {
      ptr += strlen(ptr);
      sprintf(ptr, LINEBREAK "R.%02d = ", regist);
      ptr += strlen(ptr);
      copyRegisterToClipboardString(FIRST_LOCAL_REGISTER + regist, ptr);
    }

    if(statisticalSumsPointer != NULL) {
      char sumName[40];
      for(int32_t sum=0; sum<NUMBER_OF_STATISTICAL_SUMS; sum++) {
        ptr += strlen(ptr);

        switch(sum) {
          case  0: strcpy(sumName,           "n             ");            break;
          case  1: strcpy(sumName, STD_SIGMA "(x)          ");             break;
          case  2: strcpy(sumName, STD_SIGMA "(y)          ");             break;
          case  3: strcpy(sumName, STD_SIGMA "(x" STD_SUP_2 ")         "); break;
          case  4: strcpy(sumName, STD_SIGMA "(x" STD_SUP_2 "y)        "); break;
          case  5: strcpy(sumName, STD_SIGMA "(y" STD_SUP_2 ")         "); break;
          case  6: strcpy(sumName, STD_SIGMA "(xy)         ");             break;
          case  7: strcpy(sumName, STD_SIGMA "(ln(x)" STD_CROSS "ln(y))"); break;
          case  8: strcpy(sumName, STD_SIGMA "(ln(x))      ");             break;
          case  9: strcpy(sumName, STD_SIGMA "(ln" STD_SUP_2 "(x))     "); break;
          case 10: strcpy(sumName, STD_SIGMA "(y ln(x))    ");             break;
          case 11: strcpy(sumName, STD_SIGMA "(ln(y))      ");             break;
          case 12: strcpy(sumName, STD_SIGMA "(ln" STD_SUP_2 "(y))     "); break;
          case 13: strcpy(sumName, STD_SIGMA "(x ln(y))    ");             break;
          case 14: strcpy(sumName, STD_SIGMA "(ln(y)/x)    ");             break;
          case 15: strcpy(sumName, STD_SIGMA "(x" STD_SUP_2 "/y)       "); break;
          case 16: strcpy(sumName, STD_SIGMA "(1/x)        ");             break;
          case 17: strcpy(sumName, STD_SIGMA "(1/x" STD_SUP_2 ")       "); break;
          case 18: strcpy(sumName, STD_SIGMA "(x/y)        ");             break;
          case 19: strcpy(sumName, STD_SIGMA "(1/y)        ");             break;
          case 20: strcpy(sumName, STD_SIGMA "(1/y" STD_SUP_2 ")       "); break;
          case 21: strcpy(sumName, STD_SIGMA "(x" STD_SUP_3 ")         "); break;
          case 22: strcpy(sumName, STD_SIGMA "(x" STD_SUP_4 ")         "); break;
          case 23: strcpy(sumName,           "x min         ");            break;
          case 24: strcpy(sumName,           "x max         ");            break;
          case 25: strcpy(sumName,           "y min         ");            break;
          case 26: strcpy(sumName,           "y max         ");            break;
          default: strcpy(sumName,           "?             ");
        }

        sprintf(ptr, LINEBREAK "SR%02d = ", sum);
        ptr += strlen(ptr);
        stringToUtf8(sumName, (uint8_t *)ptr);
        ptr += strlen(ptr);
        strcpy(ptr, " = ");
        ptr += strlen(ptr);
        realToString(statisticalSumsPointer + REAL_SIZE_IN_BLOCKS * sum, tmpString);
        if(strchr(tmpString, '.') == NULL && strchr(tmpString, 'E') == NULL) {
          strcat(tmpString, ".");
        }
        strcpy(ptr, tmpString);
      }
    }

    gtk_clipboard_set_text(clipboard, clipboardString, -1);
  }


  #define cursorCycle 3                      //JM cursor vv
  int8_t cursorBlinkCounter;                 //JM cursor ^^
  gboolean refreshLcd(gpointer unusedData) { // This function is called every SCREEN_REFRESH_PERIOD ms by a GTK timer
    // Cursor blinking
    static bool_t cursorBlink=true;

    if(cursorEnabled) {
      if(++cursorBlinkCounter > cursorCycle) {         //JM cursor vv
        cursorBlinkCounter = 0;
        if(cursorBlink && !checkHP) {
          showGlyph(STD_CURSOR, cursorFont, xCursor, yCursor - checkHPoffset, vmNormal, true, false);
        }                                              //JM cursor ^^
        else {
          hideCursor();
        }
      cursorBlink = !cursorBlink;
      }
    }

    // Function name display
    if(showFunctionNameCounter > 0) {
      showFunctionNameCounter -= SCREEN_REFRESH_PERIOD;
      if(showFunctionNameCounter <= 0) {
        hideFunctionName();
        tmpString[0] = 0;
        showFunctionName(ITM_NOP, 0, "SF:R");
      }
    }

    // Update date and time
    getTimeString(dateTimeString);
    if(strcmp(dateTimeString, oldTime)) {
      strcpy(oldTime, dateTimeString);
      #if(DEBUG_INSTEAD_STATUS_BAR != 1)
        showDateTime();
        if (Y_SHIFT == 0 && X_SHIFT < 200) {
          showShiftState();
        }
      #endif // (DEBUG_INSTEAD_STATUS_BAR != 1)
    }

    // If LCD has changed: update the GTK screen
    if(screenChange) {
      #if defined(LINUX) && (DEBUG_PANEL == 1)
        if(programRunStop != PGM_RUNNING) {
          refreshDebugPanel();
        }
      #endif // defined(LINUX) && (DEBUG_PANEL == 1)

      gtk_widget_queue_draw(screen);
      while(gtk_events_pending()) {
        gtk_main_iteration();
      }
    }

    return TRUE;
  }
#elif defined(DMCP_BUILD)
  #define cursorCycle 3                      //JM cursor vv
  int8_t cursorBlinkCounter;                 //JM cursor ^^
  void refreshLcd(void) { // This function is called roughly every SCREEN_REFRESH_PERIOD ms from the main loop
    // Cursor blinking
    static bool_t cursorBlink=true;

    if(cursorEnabled) {
      if(++cursorBlinkCounter > cursorCycle) {         //JM cursor vv
        cursorBlinkCounter = 0;
        if(cursorBlink && !checkHP) {
          showGlyph(STD_CURSOR, cursorFont, xCursor, yCursor - checkHPoffset, vmNormal, true, false);
        }                                              //JM cursor ^^
        else {
          hideCursor();
        }
        //cursorBlink = !cursorBlink;
      }
    }

    // Function name display
    if(showFunctionNameCounter>0) {
      showFunctionNameCounter -= FAST_SCREEN_REFRESH_PERIOD;
      if(showFunctionNameCounter <= 0) {
        hideFunctionName();
        tmpString[0] = 0;
        showFunctionName(ITM_NOP, 0, "SF:R");
      }
    }

    // Update date and time
    getTimeString(dateTimeString);
    if(strcmp(dateTimeString, oldTime)) {
      strcpy(oldTime, dateTimeString);
      #if(DEBUG_INSTEAD_STATUS_BAR != 1)
        showDateTime();
        if (Y_SHIFT == 0 && X_SHIFT < 200) {
          showShiftState();
        }
      #endif // (DEBUG_INSTEAD_STATUS_BAR != 1)

      dmcpResetAutoOff();

      fnPollTimerApp();
    }
    checkBattery();
  }
#endif // PC_BUILD DMCP_BUILD


void execTimerApp(uint16_t timerType) {
  fnTimerStart(TO_TIMER_APP, TO_TIMER_APP, TIMER_APP_PERIOD);
  fnUpdateTimerApp();
}


#if !defined(TESTSUITE_BUILD)
  void refreshFn(uint16_t timerType) {                        //vv dr - general timeout handler
    if(timerType == TO_FG_LONG) Shft_handler();
    if(timerType == TO_CL_LONG) LongpressKey_handler();
    if(timerType == TO_FG_TIMR) Shft_stop();
    if(timerType == TO_FN_LONG) FN_handler();
    if(timerType == TO_ASM_ACTIVE) {
      if(catalog) {
        resetAlphaSelectionBuffer();
      }
    }
  }                                                           //^^


  void underline(int16_t y) {                     //JM
    int16_t i;
    for(i=0; i<6; i++ ) {
      if((maxfgLines(y) || (fgLN == RB_FGLNFUL)) && ((calcMode != CM_GRAPH && calcMode != CM_PLOT_STAT) || ((calcMode == CM_GRAPH || calcMode == CM_PLOT_STAT) && (i <= 1)))) {
        underline_softkey(i, y, true);
      }
    }
  }                                               //JM


  uint32_t ul;
  void clear_ul(void) {
    ULGL = false;
    ULFL = false;
    ul = 0;                                       //JM Set all bits 00-23 to zero
  }

                                                //JM vv LONGPRESS.   false auto clears
  void underline_softkey(int16_t xSoftkey, int16_t ySoftKey, bool_t dontclear) {
    int16_t x, y, x1, y1, x2, y2;
    uint32_t tmp;

    if(calcMode == CM_REGISTER_BROWSER || calcMode == CM_FLAG_BROWSER || calcMode == CM_FONT_BROWSER) {
      return;
    }

    if((calcMode == CM_GRAPH || calcMode == CM_PLOT_STAT) && xSoftkey >= 2) {
      return;
    }

    if(xSoftkey < 0 || xSoftkey > 5) {
      return;
    }

    if(fgLN != RB_FGLNOFF) {
      //JMUL all changed  vv
      if(!dontclear) {                            //JM Recursively call the same routine to clear the previous line
        for(y=0; y<ySoftKey; y++) {
          tmp = ul;
          if( ((tmp >> (y*6+xSoftkey)) & 1U)) {   //JM To check a bit, shift the number n to the right, then bitwise AND it:
            underline_softkey(xSoftkey,y,true);
          }
        }
      }
      ul ^= 1UL << (ySoftKey*6+xSoftkey);         //JM The XOR operator (^) can be used to toggle a bit.
      //JMUL all changed  ^^

      if(0 <= xSoftkey && xSoftkey <= 5) {
        x1 = 67 * xSoftkey - 1;
        x2 = x1 + 67;
      }
      else {
        x1 = 0;
        x2 = 0;
      }

      if(0 <= ySoftKey && ySoftKey <= 2) {
        y1 = 217 - SOFTMENU_HEIGHT * ySoftKey;
        y2 = y1 + SOFTMENU_HEIGHT;
      }
      else {
        y1 = 0;
        y2 = 0;
      }

      y = y2-3-1;
      if(y>=0) {                                  //JM Make provision for out of range parameter, used to not plot the line and only for the recursive line removal
        for(x=x2-66+1; x<min(x2-1,SCREEN_WIDTH); x++) {
          if(mod(x, 2) == 0) {
            flipPixel  ((uint32_t) x, (uint32_t) y);
            flipPixel  ((uint32_t) x, (uint32_t) (y+2));
          }
          else {
            flipPixel  (x, y+1);
          }
        }
      }
    }
  }                                            //JM ^^


  void FN_handler_StepToF(uint32_t time) {
    shiftF = true;        //S_shF();                  //   New shift state
    shiftG = false;
    showShiftState();
    refreshRegisterLine(REGISTER_T); //clearRegisterLine(Y_POSITION_OF_REGISTER_T_LINE - 4, REGISTER_LINE_HEIGHT); //JM FN clear the previous shift function name
    char *varCatalogItem = "SF:F";
    int16_t Dyn = nameFunction(FN_key_pressed-37, shiftF, shiftG);
    if(dynamicMenuItem > -1 && !DEBUGSFN) {
      varCatalogItem = dynmenuGetLabel(dynamicMenuItem);
    }
    showFunctionName(Dyn,0, varCatalogItem);
    FN_timed_out_to_RELEASE_EXEC = true;
    underline_softkey(FN_key_pressed-38, 1, false);
    fnTimerStart(TO_FN_LONG, TO_FN_LONG, time);          //dr
  }


  void FN_handler_StepToG(uint32_t time) {
    shiftF = false;
    shiftG = true;
    showShiftState();
    refreshRegisterLine(REGISTER_T); //clearRegisterLine(Y_POSITION_OF_REGISTER_T_LINE - 4, REGISTER_LINE_HEIGHT); //JM FN clear the previous shift function name
    char *varCatalogItem = "SF:G";
    int16_t Dyn = nameFunction(FN_key_pressed-37, shiftF, shiftG);
    if(dynamicMenuItem > -1 && !DEBUGSFN) {
      varCatalogItem = dynmenuGetLabel(dynamicMenuItem);
    }
    showFunctionName(Dyn,0, varCatalogItem);
    FN_timed_out_to_RELEASE_EXEC = true;
    underline_softkey(FN_key_pressed-38, 2, false);
    fnTimerStart(TO_FN_LONG, TO_FN_LONG, time);          //dr
  }


  void FN_handler_StepToNOP(void) {
    refreshRegisterLine(REGISTER_T); //clearRegisterLine(Y_POSITION_OF_REGISTER_T_LINE - 4, REGISTER_LINE_HEIGHT); //JM FN clear the previous shift function name
    showFunctionName(ITM_NOP, 0, "SF:N");
    FN_timed_out_to_NOP = true;
    underline_softkey(FN_key_pressed-38, 3, false);   //  Purposely select row 3 which does not exist, just to activate the 'clear previous line'
    FN_timeouts_in_progress = false;
    fnTimerStop(TO_FN_LONG);                                      //dr
  }


  void FN_handler(void) {                     //JM FN LONGPRESS vv Handler FN Key shift longpress handler
                                              //   Processing cycles here while the key is pressed, that is, after PRESS #1, waiting for RELEASE #2
    if((FN_state == ST_1_PRESS1 || FN_state == ST_3_PRESS2) && FN_timeouts_in_progress && (FN_key_pressed != 0) && !IS_BASEBLANK_(softmenuStack[0].softmenuId) ) {
      if(fnTimerGetStatus(TO_FN_LONG) == TMR_COMPLETED) {
        FN_handle_timed_out_to_EXEC = false;
        if(!shiftF && !shiftG) {                              //From No_Shift State 1
          if(LongPressF == RB_F1234) {
            FN_handler_StepToF(TIME_FN_1234_F_TO_G);           //To F State 2
          }
          else if(LongPressF == RB_F124) {
            FN_handler_StepToF(TIME_FN_124_F_TO_NOP);            //To F State 2
          }
          else if(LongPressF == RB_F14) {
            FN_handler_StepToNOP();                           //To NOP State 4
          }

          #if defined(FN_TIME_DEBUG1)
            printf("Handler 1, KEY=%d =%i\n",FN_key_pressed,nameFunction(FN_key_pressed-37, shiftF, shiftG));
          #endif // FN_TIME_DEBUG1
        }
        else if(shiftF && !shiftG) {                          //From F State 2
          if(LongPressF == RB_F1234) {
            FN_handler_StepToG(TIME_FN_1234_G_TO_NOP);            //To G State 3
          }
          else if(LongPressF == RB_F124) {
            FN_handler_StepToNOP();                           //To NOP State 4
          }
          #if defined(FN_TIME_DEBUG1)
            printf("Handler 2, KEY=%d =%i\n",FN_key_pressed,nameFunction(FN_key_pressed-37, shiftF, shiftG));
          #endif // FN_TIME_DEBUG1
        }
        else if((!shiftF && shiftG) || (shiftF && shiftG)) {  //From G: 3 (or illegal state FG)
          FN_handler_StepToNOP();                             //To NOP State 4
          #if defined(FN_TIME_DEBUG1)
            printf("Handler 3, KEY=%d =%i\n",FN_key_pressed,nameFunction(FN_key_pressed-37, shiftF, shiftG));
          #endif // FN_TIME_DEBUG1
        }
      }
    }
  }                                        //JM ^^


  void Shft_handler() {                        //JM SHIFT NEW vv
    if(Shft_LongPress_f_g) {
      if(fnTimerGetStatus(TO_FG_LONG) == TMR_COMPLETED) {
        Shft_LongPress_f_g = false;
        fnTimerStop(TO_3S_CTFF);
        fnTimerStop(TO_FG_LONG);
        if(shiftF) {
          showSoftmenu(-MNU_HOME);
          showSoftmenuCurrentPart();
        }
        else if(shiftG) {
          showSoftmenu(-MNU_MyMenu);
          showSoftmenuCurrentPart();
        }
        shiftF = 0;
        shiftG = 0;
        showShiftState();
        }


    } else
    if(Shft_timeouts) {
      if(fnTimerGetStatus(TO_FG_LONG) == TMR_COMPLETED) {
        fnTimerStop(TO_3S_CTFF);
        if(!shiftF && !shiftG) {
          shiftF = true;
          fnTimerStart(TO_FG_LONG, TO_FG_LONG, JM_TO_FG_LONG);
          showShiftState();
        }
        else if(shiftF && !shiftG) {
          shiftG = true;
          shiftF = false;
          fnTimerStart(TO_FG_LONG, TO_FG_LONG, JM_TO_FG_LONG);
          showShiftState();
        }
        else if((!shiftF && shiftG) || (shiftF && shiftG)) {
          Shft_timeouts = false;
          //fnTimerStop(TO_FG_LONG);                  // vv moved to resetShiftState()
          //fnTimerStop(TO_FG_TIMR);                  // ^^
          resetShiftState();                        //force into no shift state, i.e. to wait
          if(HOME3 || MYM3) {
            #if defined(PC_BUILD)
              jm_show_calc_state("screen.c: Shft_handler: HOME3");
            #endif //PC_BUILD
            if(HOME3 && currentMenu() == -MNU_HOME) {              //JM shifts    //softmenuStackPointerJM
              popSoftmenu();                                                                                                  //JM shifts
            }
            else {
              if(calcMode == CM_AIM) {                                                                                        //JM shifts
              }
              else {                                                                                                          //JM SHIFTS
                if(HOME3) {
                  showSoftmenu(-MNU_HOME);
                }
                else if(MYM3) {
                  showSoftmenu(-MNU_MyMenu);
                }
              }                                                                                                               //JM shifts
            }
            showSoftmenuCurrentPart();
          }
        }
      }
    }
  }                                        //JM ^^


  void LongpressKey_handler() {
    if(fnTimerGetStatus(TO_CL_LONG) == TMR_COMPLETED) {
      if(JM_auto_longpress_enabled != 0) {
        char *funcParam;
        int keyStateCode = (getSystemFlag(FLAG_ALPHA) ? 3 : 0) + ((LongPressM == RB_M124) ? 1 : longpressDelayedkey3 ? 1 : 2);
        funcParam = (char *)getNthString((uint8_t *)userKeyLabel, currentKeyCode * 6 + keyStateCode);
        if((funcParam[0] != 0) && ((JM_auto_longpress_enabled == -MNU_DYNAMIC) || (JM_auto_longpress_enabled == ITM_XEQ) || (JM_auto_longpress_enabled == ITM_RCL))) { // For user menu, prog or variable a-feirassignment
          showFunctionName(JM_auto_longpress_enabled, JM_TO_CL_LONG + 50, funcParam);     //Add a marginal amout of time to prevent racing of end conditions.
        } else {
          showFunctionName(JM_auto_longpress_enabled, JM_TO_CL_LONG + 50, "SF:LL");     //Add a marginal amout of time to prevent racing of end conditions.
        }
        JM_auto_longpress_enabled = 0;                                       //showFunctionName must not time out longer than the timer that is started below

        //Setup up next long press activation possibility
        if(longpressDelayedkey2) {
          JM_auto_longpress_enabled = longpressDelayedkey2;
          longpressDelayedkey2 = 0;
        }
        else if(longpressDelayedkey3) {
          JM_auto_longpress_enabled = longpressDelayedkey3;
          longpressDelayedkey3 = 0;
        }
        if(JM_auto_longpress_enabled) {
          fnTimerStart(TO_CL_LONG, TO_CL_LONG, JM_TO_CL_LONG);
        }
      }
    }
  }


  void Shft_stop() {
    Shft_timeouts = false;
    resetShiftState();                        //force into no shift state, i.e. to wait
  }


  #if !defined(DMCP_BUILD)
    void setBlackPixel(uint32_t x, uint32_t y) {
      //if(y >= (uint32_t)(-6)) return;  //JM allowing allowing -1..-5 for top row text

      if(x >= SCREEN_WIDTH || y >= SCREEN_HEIGHT) {
        printf("In function setBlackPixel: x=%u or %d, y=%u or %d outside the screen!\n", x, (int32_t)(x), y, (int32_t)(y) );
        return;
      }

      *(screenData + y*screenStride + x) = ON_PIXEL;
      screenChange = true;
    }


    void setWhitePixel(uint32_t x, uint32_t y) {
      //if(y >= (uint32_t)(-6)) return;  //JM allowing allowing -1..-5 for top row text

      if(x>=SCREEN_WIDTH || y>=SCREEN_HEIGHT) {
        printf("In function setWhitePixel: x=%u or %d, y=%u or %d outside the screen!\n", x, (int32_t)x, y, (int32_t)y);
        return;
      }

      *(screenData + y*screenStride + x) = OFF_PIXEL;
      screenChange = true;
    }


    void flipPixel(uint32_t x, uint32_t y) {
      if(x >= SCREEN_WIDTH || y >= SCREEN_HEIGHT) {
        printf("In function flipPixel: x=%u, y=%u outside the screen!\n", x, y);
        return;
      }

      if(*(screenData + y*screenStride + x) == OFF_PIXEL) {
        *(screenData + y*screenStride + x) = ON_PIXEL;
      }
      else {
        *(screenData + y*screenStride + x) = OFF_PIXEL;
      }
      screenChange = true;
    }


    int16_t clearScreenCounter = 0;                       //JM ClearScreen Test
    void lcd_fill_rect(uint32_t x, uint32_t y, uint32_t dx, uint32_t dy, int val) {
      uint32_t line, col, pixelColor, *pixel, endX = x + dx, endY = y + dy;

      //if(y >= (uint32_t)(-100)) { //JM allowing -100 to measure the size in pixels; allowing -1..-5 for top row text
      //  return;
      //}

      if(x == 0 && y == 0 && dx == SCREEN_WIDTH && dy == SCREEN_HEIGHT) {  //JMTOCHECK is this needed?
        printf(">>> screen.c: clearScreen: clearScreenCounter=%d\n",clearScreenCounter++);    //JMYY ClearScreen Test  #endif
        clear_ul(); //JMUL
      }

      if(endX > SCREEN_WIDTH || endY > SCREEN_HEIGHT) {
        printf("In function lcd_fill_rect: x=%u, y=%u, dx=%u, dy=%u, val=%d outside the screen!\n", x, y, dx, dy, val);
        return;
      }

      pixelColor = (val == LCD_SET_VALUE ? OFF_PIXEL : ON_PIXEL);
      for(line=y; line<endY; line++) {
        for(col=x, pixel=screenData + line*screenStride + x; col<endX; col++, pixel++) {
          *pixel = pixelColor;
        }
      }

      #if defined(DEBUGCLEARS)
        plotrect(x, y, x+dx, y+dy);
      #endif // DEBUGCLEARS

      screenChange = true;
    }
  #endif // !DMCP_BUILD


  //JM: If maxiC is set, then, if a glyph is not found in numericfont, it will be fetched and enlarged from standardfont
  uint8_t  combinationFonts = combinationFontsDefault;
  uint8_t  miniC = 0;                                                              //JM miniature letters
  uint8_t  maxiC = 0;                                                              //JM ENLARGE letters. Use Numericfont & combinationFontsDefault=2;
  bool_t   noShow = false;                                                         //JM
  uint8_t  displaymode = stdNoEnlarge;


uint16_t str2dec(char* ch) {
  //uint16_t ll = ch[1], hh = ch[0],
  uint16_t res = (uint8_t)ch[1] + (((uint8_t)ch[0]) << 8);
  //printf("= %u *256+ %u = %u\n", (uint8_t)hh, (uint8_t)ll, (uint16_t)res);
return res;
}

bool_t ratherUseEnlargement(uint16_t charCode) {
  return ((bool_t) (
    ((charCode >= str2dec(STD_SUP_f)) && (charCode <= str2dec(STD_SUP_h))) ||
    ( charCode == str2dec(STD_SUP_r)) ||
    ( charCode == str2dec(STD_SUP_x)) ||

    ((charCode >= str2dec(STD_SUB_f)) && (charCode <= str2dec(STD_SUB_h))) ||
    ( charCode == str2dec(STD_SUB_r)) ||
    ( charCode == str2dec(STD_SUB_t))
    ));
}

  uint32_t showGlyphCode(uint16_t charCode, const font_t *font, uint32_t x, uint32_t y, videoMode_t videoMode, bool_t showLeadingCols, bool_t showEndingCols) {
    uint32_t col, row, xGlyph, endingCols;
    int32_t  glyphId;
    int8_t   byte, *data;
    const glyph_t *glyph;

    if(charCode == 1) {
      return x; //This is special usage of the 01 ASCII code, to ignore the code and return with nothing printed
    }

    bool_t enlarge = false;                                   //JM ENLARGE vv
    if(combinationFonts == stdnumEnlarge || combinationFonts == numHalf) {
      if(maxiC == 1 && font == &numericFont) {                //JM allow enlargements
        glyphId = findGlyph(font, charCode);
        //printf("DDDDDD %d %d --- %u\n",glyphId, charCode, ratherUseEnlargement(charCode));
        if(glyphId < 0 || ratherUseEnlargement(charCode)) {           //JM if there is not a large glyph, enlarge the small letter
          enlarge = true;
          font = &standardFont;
        }
      }
    }
    else if(combinationFonts == 1) {
      if(maxiC == 1 && font == &standardFont) {                //JM allow enlargements
        enlarge = true;
      }                                                       //JM ENLARGE ^^
    }

    #if !defined(GENERATE_CATALOGS)
      if(checkHP && font == &numericFont && HPFONT) {
        charCodeHPReplacement(&charCode);
      }
    #endif //GENERATE_CATALOGS

    glyphId = findGlyph(font, charCode);
    if(glyphId >= 0) {
      glyph = (font->glyphs) + glyphId;
    }
    else if(glyphId == -1) {
      generateNotFoundGlyph(-1, charCode);
      glyph = &glyphNotFound;
    }
    else if(glyphId == -2) {
      generateNotFoundGlyph(-2, charCode);
      glyph = &glyphNotFound;
    }
    else {
      glyph = NULL;
    }

    if(glyph == NULL) {
      sprintf(errorMessage, commonBugScreenMessages[bugMsgValueReturnedByFindGlyph], "showGlyphCode", glyphId);
      displayBugScreen(errorMessage);
      return 0;
    }

    data = (int8_t *)glyph->data;
    uint32_t y0 = y;                                                   //JMmini 0-reference
    xGlyph      = showLeadingCols ? glyph->colsBeforeGlyph : 0;
    endingCols  = showEndingCols ? glyph->colsAfterGlyph : 0;

    bool_t numDouble = font == &numericFont && checkHP && temporaryInformation == TI_NO_INFO; //&& charCodeFromString(STD_MODE_G, 0)!=charCode && charCodeFromString(STD_MODE_G, 0)!=charCode; //this also triggers the vertical doubling
    uint16_t doubling = numDouble ? DOUBLING : DOUBLINGBASEX;      //this is the horizontal factor, 8 is normal, so 16 is double

    // Clearing the space needed by the glyph
    bool_t rep_enlarge = numDouble || (enlarge && combinationFonts != 0);                //JM ENLARGE
    uint32_t yNewMaxDx = (rep_enlarge ? 2 : 1) * (((glyph->rowsAboveGlyph + glyph->rowsGlyph + glyph->rowsBelowGlyph) >> miniC) - (rep_enlarge ? 4 : 0));
    if(!noShow) {
      lcd_fill_rect(x, y, (uint32_t)(doubling * ((xGlyph + glyph->colsGlyph + endingCols) >> miniC)) >> 3, yNewMaxDx, (videoMode == vmNormal ? LCD_SET_VALUE : LCD_EMPTY_VALUE));  //JMmini
    }
    if(displaymode == numHalf) {
      y += (uint32_t)(glyph->rowsAboveGlyph*REDUCT_A/REDUCT_B*(rep_enlarge ? 2 : 1));
    }
    else {
      y += glyph->rowsAboveGlyph*(rep_enlarge ? 2 : 1);
    }        //JM REDUCE and DOUBLE
    //x += xGlyph; //JM

    // Drawing the glyph
    for(row=0; row<glyph->rowsGlyph; row++, y++) {
      if(displaymode == numHalf) {
        if((int)((REDUCT_A*row+REDUCT_OFF)) % REDUCT_B == 0) {
          y--;
        }
      }                           //JM REDUCE
      // Drawing the columns of the glyph
      int32_t bit = 7;
      for(col=0; col<glyph->colsGlyph; col++) {
        if(bit == 7) {
          byte = *(data++);
          if(miniC!=0) {
            byte = (uint8_t)byte | (((uint8_t)byte) << 1);           //JMmini
          }
        }

        if(byte & 0x80 && !noShow) { // MSB set
          uint32_t x1 = x+((((doubling * (xGlyph+col)) >> miniC)) >> 3);
          uint32_t x2 = x1;
          uint32_t y1 = min(SCREEN_HEIGHT-1, y0 + min(yNewMaxDx,((y-y0) >> miniC)));
          uint32_t y2 = min(SCREEN_HEIGHT-1, y0 + min(yNewMaxDx,1+((y-y0) >> miniC)));
          if(x2 > 0) {
            x2--;
          }
          if(videoMode == vmNormal) { // Black pixel for white background
            setBlackPixel(x1,y1);
            if(numDouble) {
              setBlackPixel(x2,y1);
            }
            if(rep_enlarge) {
              setBlackPixel(x1,y2);
              if(numDouble) {
                setBlackPixel(x2,y2);
              }
            }
          }
          else { // White pixel for black background
            setWhitePixel(x1,y1);
            if(numDouble) {
              setWhitePixel(x2,y1);
            }
            if(rep_enlarge) {
              setWhitePixel(x1,y2);
              if(numDouble) {
                setWhitePixel(x2,y2);
              }
            }
          }
        }

        byte <<= 1;

        if(--bit == -1) {
          bit = 7;
        }
      }
      if(rep_enlarge && row!=3 && row!=6 && row!=9 && row!=12) {
        y++; //JM ENLARGE vv do not advance the row counter for four rows, to match the row height of the enlarge font
      }
    }
    return x + (((doubling * (xGlyph + glyph->colsGlyph + endingCols)) >> miniC) >> 3);        //JMmini
  }


  uint32_t showGlyph(const char *ch, const font_t *font, uint32_t x, uint32_t y, videoMode_t videoMode, bool_t showLeadingCols, bool_t showEndingCols) {
    return showGlyphCode(charCodeFromString(ch, 0), font, x, y, videoMode, showLeadingCols, showEndingCols);
  }


  /* Finds the cols and rows for a glyph.
   *
   * \param[in]     ch     const char*   String whose first glyph is to find the bounds for
   * \param[in,out] offset uint16_t*     Offset for string or null if zero should be used
   * \param[in]     font   const font_t* Font to use
   * \param[out]    col    uint32_t*     Number of columns for the glyph
   * \param[out]    row    uint32_t*     Number of rows for the glyph
   */
  static void getGlyphBounds(const char *ch, uint16_t *offset, const font_t *font, uint32_t *col, uint32_t *row) {
    int32_t        glyphId;
    const glyph_t *glyph;

    glyphId = findGlyph(font, charCodeFromString(ch, offset));
    if(glyphId < 0) {
      sprintf(errorMessage, commonBugScreenMessages[bugMsgValueReturnedByFindGlyph], "getGlyphBounds", glyphId);
      displayBugScreen(errorMessage);
      return;
    }
    glyph = (font->glyphs) + glyphId;
    *col = glyph->colsBeforeGlyph + glyph->colsGlyph + glyph->colsAfterGlyph;
    *row = glyph->rowsAboveGlyph + glyph->rowsGlyph + glyph->rowsBelowGlyph;
  }


  uint8_t  compressString = 0;                                                              //JM compressString
  uint8_t  raiseString = 0;                                                                 //JM compressString
  static uint32_t _doShowString(const char *string, const font_t *font, uint32_t x, uint32_t y, char **resStr, uint32_t width, videoMode_t videoMode, bool_t showLeadingCols, bool_t showEndingCols, bool_t LF) {
    uint16_t ch, lg;
    bool_t   slc, sec;
    uint32_t prevX = x;
    uint32_t orgX = x;

    lg = stringByteLength(string);

    ch = 0;
    while(string[ch] != 0) {
      if(lg == 1 || (lg == 2 && (string[0] & 0x80))) {// The string is 1 glyph long
        slc = showLeadingCols;
        sec = showEndingCols;
      }
      else if(ch == 0) {// First glyph
        slc = showLeadingCols;
        sec = true;
      }
      else if(ch == lg-1 || (ch == lg-2 && (string[ch] & 0x80))) {// Last glyph
        slc = true;
        sec = showEndingCols;
      }
      else {// Glyph between first and last glyph
        slc = true;
        sec = true;
      }

      if(LF && x > SCREEN_WIDTH - 20 && !noShow) {                      //auto LF when line is full
        noShow = true;
        uint16_t tmp = ch;
        if(x + showGlyphCode(charCodeFromString(string, &tmp), font, 0, 0, videoMode, slc, sec) - compressString > SCREEN_WIDTH) {
          x = orgX;
          prevX = x;
          y += 20;
        }
        noShow = false;
      }

      x = showGlyphCode(charCodeFromString(string, &ch), font, x, y - raiseString, videoMode, slc, sec) - compressString;
      if(resStr) { // for stringAfterPixelsC43
        if(x > width) {
          if(!showEndingCols) {
            uint32_t tmpX = x;
            ch = *resStr - string;
            x = showGlyphCode(charCodeFromString(string, &ch), font, prevX, y - raiseString, videoMode, true, false) - compressString;
            if(x <= width) {
              *resStr = (char *)(string + ch);
            }
            x = tmpX;
          }
          break;
        }
        else {
          *resStr = (char *)(string + ch);
          prevX = x;
        }
      }
      uint16_t tmp = ch;                                     //LF after 0x0A is recognized (/n)
      while (LF && (charCodeFromString(string, &tmp) == 0x0A)) {   //do not touch character pointer
        charCodeFromString(string, &ch);                       //increment character pointer to skip 0x0A
        x = orgX;
        prevX = x;
        y += 20;
      }
    }
    compressString = 0;        //JM compressString
    raiseString = 0;
    return x;
  }


  uint32_t showStringEnhanced(const char *string, const font_t *font, uint32_t x, uint32_t y, videoMode_t videoMode, bool_t showLeadingCols, bool_t showEndingCols, uint8_t compress1, uint8_t raise1, uint8_t noShow1, bool_t lf) {
    compressString = compress1;
    raiseString = raise1;
    noShow = noShow1;
    uint32_t tmp = _doShowString(string, font, x, y, NULL, 0, videoMode, showLeadingCols, showEndingCols, lf);
    compressString = 0;
    raiseString = 0;
    noShow = 0;
    return tmp;
  }


  uint32_t showString(const char *string, const font_t *font, uint32_t x, uint32_t y, videoMode_t videoMode, bool_t showLeadingCols, bool_t showEndingCols) {
    return _doShowString(string, font, x, y, NULL, 0, videoMode, showLeadingCols, showEndingCols, NO_LF);
  }


  static char *_stringAfterPixels(const char *string, const font_t *font, uint32_t width, bool_t showLeadingCols, bool_t showEndingCols) {
    char *resStr = (char *)string;
    _doShowString(string, font, 0, 0, &resStr, width, vmNormal, showLeadingCols, showEndingCols, NO_LF);
    return resStr;
  }


  static uint32_t _showStringWithLimit(const char *string, const font_t *font, uint32_t limitWidth, bool_t showLeadingCols, bool_t showEndingCols) {
    char *resStr = (char *)string;
    return _doShowString(string, font, 0, 0, &resStr, limitWidth, vmNormal, showLeadingCols, showEndingCols, NO_LF);
  }


  static void _setStringMode(int mode, int comp, const font_t **fontPtr) {
    compressString = comp;
    displaymode = mode;             // miniC and maxiC to be depreciated in favour of displaymode
    switch(mode) {
      case stdNoEnlarge:  miniC = 0 ; maxiC = 0; combinationFonts = combinationFontsDefault; *fontPtr = &standardFont; break;
      case stdEnlarge:    miniC = 0 ; maxiC = 1; combinationFonts = stdEnlarge;              *fontPtr = &standardFont; break;
      case stdnumEnlarge: miniC = 0 ; maxiC = 1; combinationFonts = stdnumEnlarge;           *fontPtr = &numericFont;  break;
      case numSmall:      miniC = 1 ; maxiC = 0; combinationFonts = combinationFontsDefault; *fontPtr = &numericFont;  break;
      case numHalf:       miniC = 0 ; maxiC = 1; combinationFonts = numHalf;                 *fontPtr = &numericFont;  break;
      default:                                                                               *fontPtr = NULL;
    }
  }


  static void _resetStringMode(void) {
    miniC = 0;
    maxiC = 0;
    compressString = 0;
    noShow = false;
    displaymode = stdNoEnlarge;
  }


  uint32_t showStringC43(const char *string, int mode, int comp, uint32_t x, uint32_t y, videoMode_t videoMode, bool_t showLeadingCols, bool_t showEndingCols ) {
    int combinationFontsM = combinationFonts;
    if(combinationFontsDefault == 0) {
      mode = stdNoEnlarge;
    }

    const font_t *font;
    _setStringMode(mode, comp, &font);
    if(font) {
      x = showString(string, font, x, y, videoMode, showLeadingCols, showEndingCols );
    }
    else {
      x = 0;
    }

    combinationFonts = combinationFontsM; _resetStringMode();
    return x;
  }

  char *stringAfterPixelsC43(const char *string, int mode, int comp, uint32_t width, bool_t withLeadingEmptyRows, bool_t withEndingEmptyRows) {
    int combinationFontsM = combinationFonts;
    char *resStr = (char *)string;
    if(combinationFontsDefault == 0) {
      mode = stdNoEnlarge;
    }

    const font_t *font;
    noShow = true;
    _setStringMode(mode, comp, &font);
    if(font) {
      resStr = _stringAfterPixels(string, font, width, withLeadingEmptyRows, withEndingEmptyRows );
    }
    else {
      resStr = (char *)string;
    }

    combinationFonts = combinationFontsM; _resetStringMode();
    return resStr;
  }

  uint32_t stringWidthWithLimitC43(const char *string, int mode, int comp, uint32_t limitWidth, bool_t withLeadingEmptyRows, bool_t withEndingEmptyRows) {
    int combinationFontsM = combinationFonts;
    uint32_t x = 0;
    if(combinationFontsDefault == 0) {
      mode = stdNoEnlarge;
    }

    const font_t *font;
    noShow = true;
    _setStringMode(mode, comp, &font);
    if(font) {
      x = _showStringWithLimit(string, font, limitWidth, withLeadingEmptyRows, withEndingEmptyRows );
    }
    else {
      x = 0;
    }

    combinationFonts = combinationFontsM; _resetStringMode();
    return x;
  }


  uint32_t  stringWidthC43(const char *str, int mode, int comp, bool_t withLeadingEmptyRows, bool_t withEndingEmptyRows){
     noShow = true;
     return showStringC43(str, mode, comp, 0, 0, vmNormal, withLeadingEmptyRows, withEndingEmptyRows );
     //noShow = false; //no need to redo
  }


  void showDispSmall(uint16_t offset, uint8_t _h1) {
    #define line_h0 21
    const uint32_t line_h_offset = Y_POSITION_OF_REGISTER_T_LINE;
    if(tmpString[offset]) {
      uint32_t w = stringWidth(tmpString + offset, &standardFont, true, true);
      showString(tmpString + offset, &standardFont, SCREEN_WIDTH - w, line_h_offset + line_h0 * _h1, vmNormal, true, true);
      #if defined(VERBOSE_SCREEN) && defined(PC_BUILD)
        printf("^^^^NEW SHOW: %s\n", tmpString + offset);
      #endif // VERBOSE_SCREEN && PC_BUILD
      if(_h1 == 0) {
        if(temporaryInformation == TI_SHOW_REGISTER_SMALL && tmpString[1500] != 0) {
        }
        else {
          lcd_fill_rect(0,240-3*SOFTMENU_HEIGHT,SCREEN_WIDTH,1,LCD_EMPTY_VALUE);
        }
      }
    }
  }


  void showDisp(uint16_t offset, uint8_t _h1) {
    #define line_h1 37
    const uint32_t line_h_offset = Y_POSITION_OF_REGISTER_T_LINE - 3;

    uint32_t w = stringWidthWithLimitC43(tmpString + offset, stdnumEnlarge, nocompress, SCREEN_WIDTH, true, true);
    if(w < SCREEN_WIDTH) {
      showStringC43(tmpString + offset, stdnumEnlarge, nocompress,  SCREEN_WIDTH - w, line_h_offset + line_h1 * _h1, vmNormal, true, true);
      goto gotoReturn;
    }

    w = stringWidthWithLimitC43(tmpString + offset, stdEnlarge, nocompress, SCREEN_WIDTH, true, true);
    if(w < SCREEN_WIDTH) {
      showStringC43(tmpString + offset, stdEnlarge, nocompress,  SCREEN_WIDTH - w, line_h_offset + line_h1 * _h1, vmNormal, true, true);
      goto gotoReturn;
    }

    w = stringWidthWithLimitC43(tmpString + offset, stdNoEnlarge, nocompress, SCREEN_WIDTH, true, true);
    if(w < SCREEN_WIDTH) {
      showStringC43(tmpString + offset, stdNoEnlarge, nocompress,  SCREEN_WIDTH - w, line_h_offset + line_h1 * _h1, vmNormal, true, true);
      goto gotoReturn;
    }

    w = stringWidthWithLimitC43(tmpString + offset, numSmall, nocompress, SCREEN_WIDTH, true, true);
    if(w < SCREEN_WIDTH) {
      showStringC43(tmpString + offset, numSmall, nocompress,  SCREEN_WIDTH - w, line_h_offset + line_h1 * _h1, vmNormal, true, true);
      goto gotoReturn;
    }

    w = stringWidthWithLimitC43(tmpString + offset, numSmall, DO_compress, SCREEN_WIDTH, true, true);
    if(w < SCREEN_WIDTH) {
      showStringC43(tmpString + offset, numSmall, DO_compress,  SCREEN_WIDTH - w, line_h_offset + line_h1 * _h1, vmNormal, true, true);
      goto gotoReturn;
    }

    w = stringWidth(tmpString + offset + 2, &standardFont, true, true);
    if(w < SCREEN_WIDTH) {
      showString(tmpString + offset + 2, &standardFont,  SCREEN_WIDTH - w, line_h_offset + line_h1 * _h1, vmNormal, true, true);
      goto gotoReturn;
    }

    return;

    gotoReturn:
    if(_h1 == 0) {
      if(temporaryInformation == TI_SHOW_REGISTER_BIG && tmpString[1200] != 0) {
      }
      else if(tmpString[1500] != 0) {
        lcd_fill_rect(0, line_h_offset + line_h1 * 2 - 3,SCREEN_WIDTH,1,LCD_EMPTY_VALUE);
      }
      else {
        lcd_fill_rect(0,240-3*SOFTMENU_HEIGHT,SCREEN_WIDTH,1,LCD_EMPTY_VALUE);
      }
    }
  }

  uint8_t lines;      //lines   0
  uint8_t y_offset;
  uint8_t x_offset;      //pixels 40
  uint16_t current_cursor_x = 0;
  uint16_t current_cursor_y = 0;

  #if defined(TEXT_MULTILINE_EDIT)
    uint32_t showStringEdC43(uint32_t lastline, int16_t offset, int16_t edcursor, const char *string, uint32_t x, uint32_t y, videoMode_t videoMode, bool_t showLeadingCols, bool_t showEndingCols, bool_t noshow1) {
      uint16_t ch, charCode, lg;
      int16_t  glyphId;
      bool_t   slc, sec;
      uint32_t  numPixels, orglastlines, tmpxy;
      const    glyph_t *glyph;
      uint8_t  editlines;
      uint8_t  yincr;
      const    font_t *font;

      //combinationFonts = 0;

      if(combinationFonts == 2) {
        font = &numericFont;                             //JM ENLARGE
      }
      else {
        font = &standardFont;                            //JM ENLARGE
      }

      lg = stringByteLength(string + offset);

      //Removed the "new" fixed 3-line text input in favour of 1 line, which jumps to 3.
      /*
      if(combinationFonts !=0) {
        editlines     = 3 ;       //JM ENLARGE 5    number of editing lines                                        //JMCURSOR vv
        yincr         = 35;       //JM ENLARGE 21   distasnce between editing wrapped lines
        x_offset      = 0;    //pixels 40
        lines = 1;
        y_offset = 1;
      }
      */

      //see original size jumping code: c7de947 108_02 2022-08-31
      editlines     = 3 ;       //JM ENLARGE 5    number of editing lines                                        //JMCURSOR vv
      yincr         = 35;       //JM ENLARGE 21   distasnce between editing wrapped lines
      x_offset      = 0;    //pixels 40
      if(stringWidth(string + offset, &numericFont, showLeadingCols, showEndingCols) > SCREEN_WIDTH - 50 ) {  //jump from large letters to small letters
        lines = editlines;
        y_offset = 1;
      }
      else {
        lines = 2;              //jump back to small letters
        y_offset = 3;
        last_CM = 253; //Force redraw
      }

      if(checkHP) {
        lines = 1;
        y_offset = 1;
        last_CM = 253; //Force redraw
        editlines = 1;
        yincr = 1;
      }

      if(lines == editlines || lg == 0) {
        last_CM = 253; //Force redraw if
      }

      orglastlines = lastline;

      if(lastline > y_offset) {
        if(!noshow1) {
          clearScreen_old(false, true,false);
        }
        x = x_offset;
        y = (yincr-1) + y_offset * (yincr-1);
      }

      //****************************************
      ch = offset;
      while(string[ch] != 0) {
        //printf("%3d:%3d ",ch,(uint8_t)string[ch]);

        if(lg == 1 || (lg == 2 && (string[offset] & 0x80))) {// The string is 1 glyph long
          slc = showLeadingCols;
          sec = showEndingCols;
        }
        else if(ch == 0) {// First glyph
          slc = showLeadingCols;
          sec = true;
        }
        else if(ch == lg-1 || (ch == lg-2 && (string[ch] & 0x80))) {// Last glyph
          slc = true;
          sec = showEndingCols;
        }
        else {// Glyph between first and last glyph
          slc = true;
          sec = true;
        }

        //printf("^^^^ ch=%d edcursor=%d string[ch]=%d \n",ch, edcursor, string[ch]);

        if(ch == edcursor) {                 //draw cursor
          current_cursor_x = x;
          current_cursor_y = y;
          tmpxy = y-1;
          while(tmpxy < y + (yincr+1)) {
            if(!noshow1) {
              setBlackPixel(x,tmpxy);
            }
            if(!noshow1) {
              setBlackPixel(x+1,tmpxy);
            }
            tmpxy++;
          }
          x += 2;
        }

        charCode = (uint8_t)string[ch++];                         //get glyph code
        if(charCode & 0x80) {// MSB set?
          charCode = (charCode<<8) | (uint8_t)string[ch++];
        }
        glyph = NULL;
        glyphId = findGlyph(font, charCode);
        if(glyphId >= 0) {
          glyph = (font->glyphs) + glyphId;
        }
        else if(glyphId == -1) {                   //JMvv
          generateNotFoundGlyph(-1, charCode);
          glyph = &glyphNotFound;
        }
        else if(glyphId == -2) {
          generateNotFoundGlyph(-2, charCode);
          glyph = &glyphNotFound;
        }
        else {
          glyph = NULL;
        }                                         //JM^^

        numPixels = 0;

        numPixels += glyph->colsGlyph + glyph->colsAfterGlyph + glyph->colsBeforeGlyph;    // get width of glyph
        //printf(">>> lastline=%d string[ch]=%d x=%d numPixels=%d", lastline, string[ch], x, numPixels);
        if(string[ch]== 0) {
          numPixels += 8;
        }
        //printf("±±± lastline=%d string[ch]=%d x=%d numPixels=%d\n", lastline, string[ch], x, numPixels);

        if(x + numPixels > SCREEN_WIDTH-1 && lastline == orglastlines) {
          x = x_offset;
          y += yincr;
          lastline--;
        }
        else if(x + numPixels > SCREEN_WIDTH-1 && lastline > 1) {
          x = 1;
          y += yincr;
          lastline--;
        }
        else if(x + numPixels > SCREEN_WIDTH-1 && lastline <= 1) {
          xCursor = x;
          yCursor = y;
          return x;
        }

        maxiC = 1;                                                                            //JM
          if(y!=(uint32_t)(-100)) x = showGlyphCode(charCode, font, x, y - raiseString, videoMode, slc, sec) - compressString;        //JM compressString
        maxiC = 0;                                                                            //JM
      }
      //printf("\n");

      xCursor = x;
      yCursor = y;
      compressString = 0;                                                                     //JM compressString
      raiseString = 0;
      return xCursor;
    }
  #endif // TEXT_MULTILINE_EDIT
                                                          //JMCURSOR ^^


  void findOffset(void) {             //C43 JM
    int32_t strWidth = (int32_t)stringWidthC43(aimBuffer, combinationFonts, nocompress, true, true);
    strWidth -= SCREEN_WIDTH * lines - 45;
    if(strWidth < 0) {
      strWidth = 0;
    }
    char *offset = stringAfterPixelsC43(aimBuffer, combinationFonts, nocompress, strWidth, true, true);
    displayAIMbufferoffset = offset - aimBuffer;
    incOffset();
  }


  void incOffset(void) {             //C43 JM
    if( (int32_t)stringWidthC43(aimBuffer + displayAIMbufferoffset, combinationFonts ,nocompress, true, true) -
        (int32_t)stringWidthC43(aimBuffer + T_cursorPos, combinationFonts ,nocompress, true, true)
        > SCREEN_WIDTH * lines - 45
        ) {
      displayAIMbufferoffset = stringNextGlyph(aimBuffer, displayAIMbufferoffset);
    }
  }


  void refresh_gui(void) {
    #if defined(PC_BUILD)
      while(gtk_events_pending()) {
        gtk_main_iteration();
      }
    #endif // PC_BUILD
  }


  void force_refresh(uint8_t mode) {
    if(!getSystemFlag(FLAG_MONIT) && mode == timed) {
      return;
    }
    if(mode == force || ((((uint16_t)(getUptimeMs()) >> 4) & 0x0020) == 0x0020) == halfSecTick) {  //Restrict refresh to once per half second. Use this minimally, due to extreme slow response.
      halfSecTick = !halfSecTick;

      #if defined(PC_BUILD)
        gtk_widget_queue_draw(screen);
        #if defined(FULLUPDATE) // (UGLY)
          refresh_gui();
        #endif // FULLUPDATE (UGLY)
      #endif // PC_BUILD

      #if defined(DMCP_BUILD)
        lcd_forced_refresh();
      #endif // DMCP_BUILD
    }
  }

  uint16_t old_time = 0;
  static bool_t _printHalfSecUpdate_Integer(uint8_t mode, char *txt, int loop) {
    char tmps[100];
    bool_t ret_value = false;
    uint16_t new_time = (uint16_t)(getUptimeMs());

    if((mode != timed) || (((new_time - old_time) & 0xFE00) != 0 )) { //0x0200 || 0.512 second refresh interval
      old_time = new_time;
      ret_value = true;

      //refreshScreen();   //to update stack
      clearRegisterLine(REGISTER_T, true, true);
      if(mode > 1) {
        clearRegisterLine(REGISTER_Z, true, true);
      }

      //lcd_refresh();
      fnTimerStart(TO_KB_ACTV, TO_KB_ACTV, JM_TO_KB_ACTV); //PROGRAM_KB_ACTV
      sprintf(tmps, "%s %" PRIu32 "  ", txt, (uint32_t)loop);

      showString(tmps, &standardFont, 20, /*145-7*/ Y_POSITION_OF_REGISTER_T_LINE + mode * 20, vmNormal, false, false);  //note: 1 line down for "force"

      #if defined(PC_BUILD)
        gtk_widget_queue_draw(screen);
        #if defined(FULLUPDATE) // (UGLY)
          refresh_gui();
        #endif // FULLUPDATE (UGLY)
      #endif // PC_BUILD

      #if defined(DMCP_BUILD)
        lcd_forced_refresh();
      #endif // DMCP_BUILD
    }
    return ret_value;
  }

  bool_t printHalfSecUpdate_Integer(uint8_t mode, char *txt, int loop) { //further optimisation, not to even set up the 100 byte array or call getUptimeMs if progress monitor is not selected 
    if(!getSystemFlag(FLAG_MONIT)) {
      return false;
    }
    return _printHalfSecUpdate_Integer(mode, txt, loop);
  }


  void hideCursor(void) {
    if(cursorEnabled) {
      if(cursorFont == &standardFont) {
        lcd_fill_rect(xCursor, yCursor + 10,  6,  6, LCD_SET_VALUE);
      }
      else {
        if(checkHP) {
          lcd_fill_rect(xCursor, yCursor + 15 -50, 13*2, 13*2, LCD_SET_VALUE);
        }
        else {
          lcd_fill_rect(xCursor, yCursor + 15, 13, 13, LCD_SET_VALUE);
        }
      }
    }
  }


  static void stats_param_display(const char *name, calcRegister_t reg, char *prefix, char *tmpString, calcRegister_t rowReg) {
    int16_t prefixWidth;
    char regS[5], *p;
    real_t t;
    real34_t u;
    uint32_t angleMode;

    if(name == NULL || !(rowReg == REGISTER_Y || rowReg == REGISTER_Z || rowReg == REGISTER_T)) {
      return;
    }
    clearRegisterLine(rowReg, true, true);

    strcpy(regS, "Reg_"); 
    regS[3] = letteredRegisterName(reg);
    showString(regS, &standardFont, 19, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(rowReg - REGISTER_X) + 6, vmNormal, true, true);
    sprintf(prefix, "= %s =", name);
    prefixWidth = showString(prefix, &standardFont, 19 + (17+28), Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(rowReg - REGISTER_X) + 6, vmNormal, true, true);

    if (getRegisterAsRealQuiet(reg, &t)) {
      angleMode = getRegisterDataType(reg) == dtReal34 ? getRegisterAngularMode(reg) : amNone;
      realToReal34(&t, &u);
      real34ToDisplayString(&u, angleMode, tmpString, &numericFont, SCREEN_WIDTH - prefixWidth, NUMBER_OF_DISPLAY_DIGITS, true, true);
      p = tmpString;
    } else {
      p = "invalid";
    }

    showString(p, &numericFont, SCREEN_WIDTH - stringWidth(p, &numericFont, false, true), Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(rowReg - REGISTER_X), vmNormal, false, true);
  }


  void showFunctionName(int16_t itm, int16_t delayInMs, const char *arg) {
    int16_t item = (int16_t)itm;
    //printf("---Function par:%4u %4u-- converted %4u--arg:|%s|-=-", itm, (int16_t)itm, item, arg );
    uint32_t fcol, frow, gcol, grow;
    char functionName[64];
    char padding[20];                                          //JM
    functionName[0] = 0;
    showFunctionNameArg = NULL;

    //FIX //REMOVE DISPLAYING TEMP STRING as in C43 the tmpstring does NOT show the last keystroke or whatever this tempstr is needed for. It gets executed from timers
    //if(tmpString[0] != 0) {
    //  strcpy(functionName,tmpString);
    //}
    //else

    #if defined(DEBUG_SHOWNAME)
      if(item < LAST_ITEM && (item == ITM_XEQ || item != ITM_RCL)) {
        stringAppend(functionName + stringByteLength(functionName), indexOfItems[abs(item)].itemCatalogName);
        stringAppend(functionName + stringByteLength(functionName), ":");
      }
      if(item < LAST_ITEM && (item == ITM_RCL || item != ITM_XEQ)) {
        stringAppend(functionName + stringByteLength(functionName), indexOfItems[abs(item)].itemSoftmenuName);
        stringAppend(functionName + stringByteLength(functionName), ":");
      }
      if(arg != NULL) {
        stringAppend(functionName + stringByteLength(functionName), arg);
        stringAppend(functionName + stringByteLength(functionName), ":");
      }
      if(item >= ITM_X_P1 && item <= ITM_X_g6) {
        stringAppend(functionName, indexOfItemsXEQM + 8*(item-fnXEQMENUpos));
        stringAppend(functionName + stringByteLength(functionName), ":");
      }
      if(dynamicMenuItem > -1) {
        stringAppend(functionName + stringByteLength(functionName),dynmenuGetLabel(dynamicMenuItem));
      }

    #else //DEBUG_SHOWNAME
      if((item == ITM_XEQ) || (item == ITM_RCL)) {
        if(arg != NULL) stringAppend(functionName,arg);
        showFunctionNameArg = (char *)arg;                          // Needed when executing a program or a variable from a long pressed key
        if(functionName[0]==0) {
          stringAppend(functionName,indexOfItems[abs(item)].itemCatalogName);
        }
      }
      else if(item == -MNU_DYNAMIC) {
        if(arg != NULL) stringAppend(functionName,arg);
        showFunctionNameArg = (char *)arg;                        // Needed when executing a user menu from a long pressed key
      }
      else if(item >= ITM_X_P1 && item <= ITM_X_g6) {
        stringAppend(functionName, indexOfItemsXEQM + 8*(item-fnXEQMENUpos));
      }
      else if(item >= FIRST_CONSTANT && item <= LAST_CONSTANT) {
        stringAppend(functionName,indexOfItems[abs(item)].itemSoftmenuName);
      }
      else if(item < LAST_ITEM && item != MNU_DYNAMIC) {
        stringAppend(functionName,indexOfItems[abs(item)].itemCatalogName);
      }
      else {
        if(dynamicMenuItem > -1) stringAppend(functionName,dynmenuGetLabel(dynamicMenuItem));
      }
    #endif //DEBUG_SHOWNAME
      //printf("---|%s|---\n", functionName);

    showFunctionNameItem = item;
    if(running_program_jm) {
      return;                             //JM
    }
    showFunctionNameCounter = delayInMs;
    stringAppend(padding,functionName);                              //JM
    stringAppend(padding + stringByteLength(padding),"     ");                                    //JM
    if(stringWidth(padding, &standardFont, true, true) + 1 /*JM 20*/ + lineTWidth > SCREEN_WIDTH) {                //JM T-Register clearing
      clearRegisterLine(REGISTER_T, true, false);
    }

    // Draw over SHIFT f and SHIFT g in case they were present (otherwise they will be obscured by the function name)
    getGlyphBounds(STD_MODE_F, 0, &standardFont, &fcol, &frow);
    getGlyphBounds(STD_MODE_G, 0, &standardFont, &gcol, &grow);
    lcd_fill_rect(X_SHIFT, Y_SHIFT, (fcol > gcol ? fcol : gcol), (frow > grow ? frow : grow), LCD_SET_VALUE);

    showString(padding, &standardFont, 18, Y_POSITION_OF_REGISTER_T_LINE + 6, vmNormal, true, true);      //JM
  }


  void hideFunctionName(void) {
    if(!running_program_jm && (tmpString[0] != 0 || calcMode!=CM_AIM)) {
      refreshRegisterLine(REGISTER_T);                                                //JM DO NOT CHANGE BACK TO CLEARING ONLY A SHORT PIECE. CHANGED IN TWEAKED AS WELL>
      if(getRegisterDataType(REGISTER_X) == dtReal34Matrix || getRegisterDataType(REGISTER_X) == dtReal34Matrix) {
        refreshRegisterLine(REGISTER_X);
      }
    }
    showFunctionNameItem = 0;
    showFunctionNameCounter = 0;
  }


  void clearRegisterLine(calcRegister_t regist, bool_t clearTop, bool_t clearBottom) {
    if(REGISTER_X <= regist && regist <= REGISTER_T) {
      uint32_t yStart = Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X);
      uint32_t height = 32;

      if(clearTop) {
        yStart -= 4;
        height += 4;
      }

      if(clearBottom) {
        height += 4;
        if(regist == REGISTER_X) {
          height += 3;
        }
      }

      lcd_fill_rect(0, yStart, SCREEN_WIDTH, height, LCD_SET_VALUE);
    }
  }


  static void viewRegName(char *prefix, int16_t *prefixWidth) { //using "=" for VIEW
    if(currentViewRegister < REGISTER_X) {
      sprintf(prefix, "R%02" PRIu16 STD_SPACE_4_PER_EM "=" STD_SPACE_4_PER_EM, currentViewRegister);
    }
    else if(currentViewRegister < FIRST_LOCAL_REGISTER) {
      sprintf(prefix, "%c" STD_SPACE_4_PER_EM "=" STD_SPACE_4_PER_EM, letteredRegisterName(currentViewRegister));
    }
    else if(currentViewRegister <= LAST_LOCAL_REGISTER) {
      sprintf(prefix, "R.%02" PRIu16 STD_SPACE_4_PER_EM "=" STD_SPACE_4_PER_EM, (uint16_t)(currentViewRegister - FIRST_LOCAL_REGISTER));
    }
    else if(currentViewRegister >= FIRST_NAMED_VARIABLE && currentViewRegister <= LAST_NAMED_VARIABLE) {
      memcpy(prefix, allNamedVariables[currentViewRegister - FIRST_NAMED_VARIABLE].variableName + 1, allNamedVariables[currentViewRegister - FIRST_NAMED_VARIABLE].variableName[0]);
      strcpy(prefix + allNamedVariables[currentViewRegister - FIRST_NAMED_VARIABLE].variableName[0], STD_SPACE_4_PER_EM "=" STD_SPACE_4_PER_EM);
    }
    else if(currentViewRegister >= FIRST_RESERVED_VARIABLE && currentViewRegister <= LAST_RESERVED_VARIABLE) {
      memcpy(prefix, allReservedVariables[currentViewRegister - FIRST_RESERVED_VARIABLE].reservedVariableName + 1, allReservedVariables[currentViewRegister - FIRST_RESERVED_VARIABLE].reservedVariableName[0]);
      strcpy(prefix + allReservedVariables[currentViewRegister - FIRST_RESERVED_VARIABLE].reservedVariableName[0], STD_SPACE_4_PER_EM "=" STD_SPACE_4_PER_EM);
    }
    else {
      sprintf(prefix, "?" STD_SPACE_4_PER_EM "=" STD_SPACE_4_PER_EM);
    }
    *prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
  }


  void viewRegName2(char *prefix, int16_t *prefixWidth) { //using ":" for SHOW
    uint16_t currentViewRegisterStored = currentViewRegister;
    currentViewRegister = SHOWregis;
    viewRegName(prefix, prefixWidth);
    uint16_t nn = 0;
    while(prefix[nn] != 0) {
      if(prefix[nn] == '=') {
        prefix[nn] = ':';
        *prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
      }
      nn++;
    }
    currentViewRegister = currentViewRegisterStored;
  }


  static void inputRegName(char *prefix, int16_t *prefixWidth) {
    if((currentInputVariable & 0x3fff) < REGISTER_X) {
      sprintf(prefix, "R%02" PRIu16 "?", (uint16_t)(currentInputVariable & 0x3fff));
    }
    else if((currentInputVariable & 0x3fff) < FIRST_LOCAL_REGISTER) {
      sprintf(prefix, "%c?", letteredRegisterName((currentInputVariable & 0x3fff)));
    }
    else if((currentInputVariable & 0x3fff) <= LAST_LOCAL_REGISTER) {
      sprintf(prefix, "R.%02" PRIu16 "?", (uint16_t)((currentInputVariable & 0x3fff) - FIRST_LOCAL_REGISTER));
    }
    else if((currentInputVariable & 0x3fff) >= FIRST_NAMED_VARIABLE && (currentInputVariable & 0x3fff) <= LAST_NAMED_VARIABLE) {
      memcpy(prefix, allNamedVariables[(currentInputVariable & 0x3fff) - FIRST_NAMED_VARIABLE].variableName + 1, allNamedVariables[(currentInputVariable & 0x3fff) - FIRST_NAMED_VARIABLE].variableName[0]);
      strcpy(prefix + allNamedVariables[(currentInputVariable & 0x3fff) - FIRST_NAMED_VARIABLE].variableName[0], "?");
    }
    else if((currentInputVariable & 0x3fff) >= FIRST_RESERVED_VARIABLE && (currentInputVariable & 0x3fff) <= LAST_RESERVED_VARIABLE) {
      memcpy(prefix, allReservedVariables[(currentInputVariable & 0x3fff) - FIRST_RESERVED_VARIABLE].reservedVariableName + 1, allReservedVariables[(currentInputVariable & 0x3fff) - FIRST_RESERVED_VARIABLE].reservedVariableName[0]);
      strcpy(prefix + allReservedVariables[(currentInputVariable & 0x3fff) - FIRST_RESERVED_VARIABLE].reservedVariableName[0], "?");
    }
    else {
      sprintf(prefix, "??");
    }
    *prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
  }


  static void _fnShowRecallTI(char * prefix, int16_t *prefixWidth) {
    viewRegName2(prefix + sprintf(prefix, "SHOW RCL "), prefixWidth);
    *prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
    temporaryInformation = TI_NO_INFO;
    screenUpdatingMode |= SCRUPD_SKIP_STACK_ONE_TIME;
  }


  void updateMatrixHeightCache(void) {
    int16_t prefixWidth = 0;
    char prefix[200];

    cachedDisplayStack = 4;

    if(getRegisterDataType(REGISTER_X) == dtReal34Matrix || (calcMode == CM_MIM && getRegisterDataType(matrixIndex) == dtReal34Matrix)) {
      real34Matrix_t matrix;

      if(temporaryInformation == TI_VIEW) {
        viewRegName(prefix, &prefixWidth);
      }
      if(temporaryInformation == TI_NO_INFO && currentInputVariable != INVALID_VARIABLE) {
        inputRegName(prefix, &prefixWidth);
      }
      if(calcMode == CM_MIM) {
        matrix = openMatrixMIMPointer.realMatrix;
      }
      else {
        linkToRealMatrixRegister(REGISTER_X, &matrix);
      }
      const uint16_t rows = matrix.header.matrixRows;
      const uint16_t cols = matrix.header.matrixColumns;
      bool_t smallFont = (rows >= 5);
      int16_t dummyVal[MATRIX_MAX_COLUMNS * (MATRIX_MAX_ROWS + 1) + 1] = {};
      const int16_t mtxWidth = getRealMatrixColumnWidths(&matrix, prefixWidth, &numericFont, dummyVal, dummyVal + MATRIX_MAX_COLUMNS, dummyVal + (MATRIX_MAX_ROWS + 1) * MATRIX_MAX_COLUMNS, cols > MATRIX_MAX_COLUMNS ? MATRIX_MAX_COLUMNS : cols);
      if(abs(mtxWidth) > MATRIX_LINE_WIDTH) {
        smallFont = true;
      }
      if(rows == 2 && cols > 1 && !smallFont) {
        cachedDisplayStack = 3;
      }
      if(rows == 3 && cols > 1) {
        cachedDisplayStack = smallFont ? 3 : 2;
      }
      if(rows == 4 && cols > 1) {
        cachedDisplayStack = smallFont ? 2 : 1;
      }
      if(rows >= 5 && cols > 1) {
        cachedDisplayStack = 2;
      }
      if(calcMode == CM_MIM) {
        cachedDisplayStack -= 2;
      }
      if(cachedDisplayStack > 4) { // in case of overflow
        cachedDisplayStack = 0;
      }
    }
    else if(getRegisterDataType(REGISTER_X) == dtComplex34Matrix || (calcMode == CM_MIM && getRegisterDataType(matrixIndex) == dtComplex34Matrix)) {
      complex34Matrix_t matrix;
      if(temporaryInformation == TI_VIEW) {
        viewRegName(prefix, &prefixWidth);
      }
      if(temporaryInformation == TI_NO_INFO && currentInputVariable != INVALID_VARIABLE) {
        inputRegName(prefix, &prefixWidth);
      }
      if(calcMode == CM_MIM) {
        matrix = openMatrixMIMPointer.complexMatrix;
      }
      else {
        linkToComplexMatrixRegister(REGISTER_X, &matrix);
      }
      const uint16_t rows = matrix.header.matrixRows;
      const uint16_t cols = matrix.header.matrixColumns;
      bool_t smallFont = (rows >= 5);
      int16_t dummyVal[MATRIX_MAX_COLUMNS * (MATRIX_MAX_ROWS * 2 + 3) + 1] = {};
      const int16_t mtxWidth = getComplexMatrixColumnWidths(&matrix, prefixWidth, &numericFont, dummyVal, dummyVal + MATRIX_MAX_COLUMNS, dummyVal + MATRIX_MAX_COLUMNS * 2, dummyVal + MATRIX_MAX_COLUMNS * 3, dummyVal + MATRIX_MAX_COLUMNS * (MATRIX_MAX_ROWS + 3), dummyVal + MATRIX_MAX_COLUMNS * (MATRIX_MAX_ROWS * 2 + 3), cols > MATRIX_MAX_COLUMNS ? MATRIX_MAX_COLUMNS : cols,  getComplexRegisterAngularMode(REGISTER_X), getComplexRegisterPolarMode(REGISTER_X) == amPolar);
      if(mtxWidth > MATRIX_LINE_WIDTH) {
        smallFont = true;
      }
      if(rows == 2 && cols > 1 && !smallFont) {
        cachedDisplayStack = 3;
      }
      if(rows == 3 && cols > 1) {
        cachedDisplayStack = smallFont ? 3 : 2;
      }
      if(rows == 4 && cols > 1) {
        cachedDisplayStack = smallFont ? 2 : 1;
      }
      if(rows >= 5 && cols > 1) {
        cachedDisplayStack = 2;
      }
      if(calcMode == CM_MIM) {
        cachedDisplayStack -= 2;
      }
      if(cachedDisplayStack > 4) { // in case of overflow
        cachedDisplayStack = 0;
      }
    }

    if(calcMode == CM_MIM && matrixIndex == REGISTER_X) {
      cachedDisplayStack += 1;
    }
  }


  void displayTemporaryInformationOnX(char *prefix) {
    int16_t       w, prefixWidth;
    uint8_t       savedTempInformation;

    prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
    savedTempInformation = temporaryInformation;
    temporaryInformation = TI_NO_INFO;
    refreshRegisterLine(REGISTER_T);
    refreshRegisterLine(REGISTER_Z);
    refreshRegisterLine(REGISTER_Y);
    refreshRegisterLine(REGISTER_X);
    temporaryInformation = savedTempInformation;

    if(getRegisterDataType(REGISTER_X) == dtReal34) {
      clearRegisterLine(REGISTER_X, true, true);
      if(getSystemFlag(FLAG_FRACT)) {
        fractionToDisplayString(REGISTER_X, tmpString);
      }
      else {
        real34ToDisplayString(REGISTER_REAL34_DATA(REGISTER_X), getRegisterAngularMode(REGISTER_X), tmpString, &numericFont, SCREEN_WIDTH - prefixWidth, NUMBER_OF_DISPLAY_DIGITS, true, true);
      }
      w = stringWidth(tmpString, &numericFont, false, true);
      showString(prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, true, true);
      showString(tmpString, &numericFont, SCREEN_WIDTH - w, Y_POSITION_OF_REGISTER_X_LINE, vmNormal, false, true);
    }
    else if(getRegisterDataType(REGISTER_X) == dtComplex34) {
      clearRegisterLine(REGISTER_X, true, true);
      complex34ToDisplayString(REGISTER_COMPLEX34_DATA(REGISTER_X), tmpString, &numericFont, SCREEN_WIDTH - prefixWidth, NUMBER_OF_DISPLAY_DIGITS, true, true, getComplexRegisterAngularMode(REGISTER_X),  getComplexRegisterPolarMode(REGISTER_X) == amPolar);
      w = stringWidth(tmpString, &numericFont, false, true);
      showString(prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, true, true);
      showString(tmpString, &numericFont, SCREEN_WIDTH - w, Y_POSITION_OF_REGISTER_X_LINE, vmNormal, false, true);
    }
    else if(getRegisterDataType(REGISTER_X) == dtLongInteger) {
      clearRegisterLine(REGISTER_X, true, true);
      longIntegerRegisterToDisplayString(REGISTER_X, tmpString, TMP_STR_LENGTH, SCREEN_WIDTH - prefixWidth, 50, true);
      w = stringWidth(tmpString, &numericFont, false, true);
      showString(prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, true, true);
      if(w <= SCREEN_WIDTH-prefixWidth) {
        showString(tmpString, &numericFont, SCREEN_WIDTH - w, Y_POSITION_OF_REGISTER_X_LINE, vmNormal, false, true);
      }
      else {
        w = stringWidth(tmpString, &standardFont, false, true);
        if(w > SCREEN_WIDTH-prefixWidth) {
          //errorMoreInfo("Long integer representation too wide!\n%s", tmpString);
          strcpy(tmpString, "Long integer representation too wide!");
        }
        w = stringWidth(tmpString, &standardFont, false, true);
        showString(tmpString, &standardFont, SCREEN_WIDTH - w, Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, false, true);
      }
    }
    else {
        showString(prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, true, true);
    }
  }


  void _displayIJ(char *prefix, int16_t *prefixWidth) {
    if(currentMenu() != -MNU_MATX || lastErrorCode != 0) {
      return;
    }
    real_t iir,jjr;

    if(getRegisterAsRealQuiet(REGISTER_I, &iir) && getRegisterAsRealQuiet(REGISTER_J, &jjr)) {
      int32_t iii, jji;
      iii=realToUint32C47(&iir);
      jji=realToUint32C47(&jjr);
      if(iii >= 0 && iii < 200 && jji >= 0 && jji < 200) {
        prefix[0] = 0;
        *prefixWidth = 0;
        if(temporaryInformation == TI_MIJ) {
          sprintf(prefix,STD_MU "[I" STD_SUB_r STD_SPACE_4_PER_EM "J" STD_SUB_c "]=" STD_MU "[%u" STD_SPACE_3_PER_EM "%u]=",(uint8_t)iii,(uint8_t)jji);
        } else {
          sprintf(prefix,"[I" STD_SUB_r STD_SPACE_4_PER_EM "J" STD_SUB_c "]=[%u" STD_SPACE_3_PER_EM "%u]",(uint8_t)iii,(uint8_t)jji);
        }
        *prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
      }
    }
  }


  #define PROBMENU (-softmenu[softmenuStack[0].softmenuId].menuItem >= MNU_BINOM && -softmenu[softmenuStack[0].softmenuId].menuItem <= ITM_1296)

  void refreshRegisterLine(calcRegister_t regist) {
    int32_t w;
    int16_t wLastBaseNumeric, wLastBaseStandard, prefixWidth = 0, lineWidth = 0;
    bool_t prefixPre = true;
    bool_t prefixPost = true;
    const uint8_t origDisplayStack = displayStack;
    bool_t distModeActive = false;
    bool_t baseModeActive = false;

    char prefix[200], lastBase[12];

    baseModeActive = !PROBMENU && (SHOWregis == 9999) && displayStackSHOIDISP != 0 && (lastIntegerBase != 0 || softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_BASE);
    if(baseModeActive && getRegisterDataType(REGISTER_X) == dtShortInteger) { //JMSHOI
      if(displayStack != 4-displayStackSHOIDISP) {                            //JMSHOI
        fnDisplayStack(4-displayStackSHOIDISP);                               //JMSHOI
      }                                                                       //JMSHOI
    }

    #if(DEBUG_PANEL == 1)
      if(programRunStop != PGM_RUNNING) {
        refreshDebugPanel();
      }
    #endif // (DEBUG_PANEL == 1)

    if((temporaryInformation == TI_SHOW_REGISTER || temporaryInformation == TI_SHOW_REGISTER_BIG || temporaryInformation == TI_SHOW_REGISTER_SMALL) && regist == REGISTER_X) { //JM frame the SHOW window
      lcd_fill_rect(0, Y_POSITION_OF_REGISTER_T_LINE-4, SCREEN_WIDTH, 1, LCD_EMPTY_VALUE);
      if(temporaryInformation != TI_SHOW_REGISTER_BIG && temporaryInformation != TI_SHOW_REGISTER_SMALL) {   //JM TI_SHOW_REGISTER_BIG is drawn elsewhere (showDisplay)
        lcd_fill_rect(0, 240-3*SOFTMENU_HEIGHT, SCREEN_WIDTH, 1, LCD_EMPTY_VALUE);
      }
    }

    if((calcMode != CM_BUG_ON_SCREEN) && (calcMode != CM_PLOT_STAT) && (calcMode != CM_GRAPH) && (calcMode != CM_LISTXY)) {               //JM
      if(temporaryInformation != TI_SHOW_REGISTER_BIG) {                        //JMSHOW
        clearRegisterLine(regist, true, (regist != REGISTER_Y));
      }                                                                         //JMSHOW

      #if defined(PC_BUILD)
        #if(DEBUG_REGISTER_L == 1 || SHOW_MEMORY_STATUS == 1)
          char tmpStr[1000];
        #endif // (DEBUG_REGISTER_L == 1 || SHOW_MEMORY_STATUS == 1)
        #if(DEBUG_REGISTER_L == 1)
          char string1[1000], string2[1000], *p;
          uint16_t i;

          strcpy(string1, "L = ");

          if(getRegisterDataType(REGISTER_L) == dtReal34) {
            strcat(string1, "real34 = ");
            formatReal34Debug(string2, (real34_t *)getRegisterDataPointer(REGISTER_L));
            strcat(string2, " ");
            strcat(string2, getAngularModeName(getRegisterAngularMode(REGISTER_L)));
          }

          else if(getRegisterDataType(REGISTER_L) == dtComplex34) {
            strcat(string1, "complex34 = ");
            formatComplex34Debug(string2, (void *)getRegisterDataPointer(REGISTER_L));
          }

          else if(getRegisterDataType(REGISTER_L) == dtString) {
            strcat(string1, "string = ");
            for(i=0, p=REGISTER_STRING_DATA(REGISTER_L); i<=stringByteLength(REGISTER_STRING_DATA(REGISTER_L)); i++, p++) {
              string2[i] = *p;
            }
          }

          else if(getRegisterDataType(REGISTER_L) == dtShortInteger) {
            strcat(string1, "short integer = ");
            shortIntegerToDisplayString(REGISTER_L, string2, false);
            strcat(string2, STD_SPACE_3_PER_EM);
            strcat(string2, getShortIntegerModeName(shortIntegerMode));
          }

          else if(getRegisterDataType(REGISTER_L) == dtLongInteger) {
            strcat(string1, "long integer = ");
            longIntegerRegisterToDisplayString(REGISTER_L, string2, sizeof(string2), SCREEN_WIDTH, 50, true);
          }

          else if(getRegisterDataType(REGISTER_L) == dtTime) {
            strcat(string1, "time = ");
            formatReal34Debug(string2, (real34_t *)getRegisterDataPointer(REGISTER_L));
          }

          else if(getRegisterDataType(REGISTER_L) == dtDate) {
            strcat(string1, "date = ");
            formatReal34Debug(string2, (real34_t *)getRegisterDataPointer(REGISTER_L));
          }

          else if(getRegisterDataType(REGISTER_L) == dtReal34Matrix) {
            sprintf(&string1[strlen(string1)], "real34 %" PRIu16 STD_CROSS "%" PRIu16 " matrix = ", REGISTER_REAL34_MATRIX_DBLOCK(REGISTER_L)->matrixRows, REGISTER_REAL34_MATRIX_DBLOCK(REGISTER_L)->matrixColumns);
            formatReal34Debug(string2, REGISTER_REAL34_MATRIX_M_ELEMENTS(REGISTER_L));
          }

          else if(getRegisterDataType(REGISTER_L) == dtComplex34Matrix) {
            sprintf(&string1[strlen(string1)], "complex34 %" PRIu16 STD_CROSS "%" PRIu16 " matrix = ", REGISTER_COMPLEX34_MATRIX_DBLOCK(REGISTER_L)->matrixRows, REGISTER_COMPLEX34_MATRIX_DBLOCK(REGISTER_L)->matrixColumns);
            formatComplex34Debug(string2, REGISTER_COMPLEX34_MATRIX_M_ELEMENTS(REGISTER_L));
          }

          else if(getRegisterDataType(REGISTER_L) == dtConfig) {
            strcat(string1, "Configuration data");
            string2[0] = 0;
          }

          else {
            sprintf(string2, "data type %s not supported for now!", getRegisterDataTypeName(REGISTER_L, false, false));
          }

          stringToUtf8(string1, (uint8_t *)tmpStr);
          stringToUtf8(string2, (uint8_t *)tmpStr + 500);

          gtk_label_set_label(GTK_LABEL(lblRegisterL1), tmpStr);
          gtk_label_set_label(GTK_LABEL(lblRegisterL2), tmpStr + 500);
          gtk_widget_show(lblRegisterL1);
          gtk_widget_show(lblRegisterL2);
        #endif // (DEBUG_REGISTER_L == 1)
        #if(SHOW_MEMORY_STATUS == 1)
          char string[1000];

          sprintf(string, "%" PRId32 " bytes free (%" PRId32 " region%s), C43 %" PRIu32 " bytes, GMP %" PRIu32 " bytes -> should always be 0", getFreeRamMemory(), numberOfFreeMemoryRegions, numberOfFreeMemoryRegions==1 ? "" : "s", (uint32_t)TO_BYTES((uint64_t)c47MemInBlocks), (uint32_t)gmpMemInBytes);
          stringToUtf8(string, (uint8_t *)tmpStr);
          gtk_label_set_label(GTK_LABEL(lblMemoryStatus), tmpStr);
          gtk_widget_show(lblMemoryStatus);
        #endif // (SHOW_MEMORY_STATUS == 1)
      #endif // PC_BUILD

      #if defined(VERBOSE_SCREEN) && defined(PC_BUILD)
        printf("^^^^Display Register: %d temporaryInformation: %d\n", regist, temporaryInformation);
      #endif //VERBOSE_SCREEN

      if(getRegisterDataType(REGISTER_X) == dtReal34Matrix || (calcMode == CM_MIM && getRegisterDataType(matrixIndex) == dtReal34Matrix)) {
        displayStack = cachedDisplayStack;
      }
      else if(getRegisterDataType(REGISTER_X) == dtComplex34Matrix || (calcMode == CM_MIM && getRegisterDataType(matrixIndex) == dtComplex34Matrix)) {
        displayStack = cachedDisplayStack;
      }

      if(temporaryInformation == TI_STATISTIC_LR && (getRegisterDataType(REGISTER_X) != dtReal34)) {
        if(regist == REGISTER_X) {
          if(orOrtho(lrSelection) == CF_ORTHOGONAL_FITTING) {
            sprintf(tmpString, "L.R. selected to OrthoF");
          }
          else {
            sprintf(tmpString, "L.R. selected to %03" PRIu16 ".", (uint16_t)((lrSelection) & 0x01FF));
          }
          #if(EXTRA_INFO_ON_CALC_ERROR == 1)
            sprintf(errorMessage, "BestF is set, but will not work until REAL data points are used.");
            moreInfoOnError("In function refreshRegisterLine:", errorMessage, errorMessages[24], NULL);
          #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
          w = stringWidth(tmpString, &standardFont, true, true);
          showString(tmpString, &standardFont, SCREEN_WIDTH - w, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X) + 6, vmNormal, true, true);
        }
      }

      else if(temporaryInformation == TI_BATTV && regist == REGISTER_X) {
        sprintf(prefix, "V" STD_SPACE_FIGURE "=");
        displayTemporaryInformationOnX(prefix);
      }

      else if(temporaryInformation == TI_BYTES && regist == REGISTER_X) {
        sprintf(prefix, "Bytes" STD_SPACE_FIGURE "=");
        displayTemporaryInformationOnX(prefix);
      }
      else if(temporaryInformation == TI_BITS && regist == REGISTER_X) {
        sprintf(prefix, "Bits" STD_SPACE_FIGURE "=");
        displayTemporaryInformationOnX(prefix);
      }

      else if(temporaryInformation == TI_ARE_YOU_SURE && regist == REGISTER_X) {
        uint16_t id = getConfirmationTiId();
        showString(confirmationTI[id].string, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X) + 6, vmNormal, true, true);
      }

      else if(temporaryInformation == TI_WHO) {
        if(regist == REGISTER_Z || regist == REGISTER_Y || regist == REGISTER_X) { //Force repainting it 3 times to get it painted properly over three lines
          showStringEnhanced(whoStr1, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*2 + 6, vmNormal, true, true, NO_compress, NO_raise, DO_Show, DO_LF);
        }
      }

      else if(temporaryInformation == TI_VERSION && regist == REGISTER_X) {
        clearRegisterLine(REGISTER_X, true, true);
        clearRegisterLine(REGISTER_Y, true, true);
        showStringEnhanced(versionStr,  &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X) + 6, vmNormal, true, true, NO_compress, NO_raise, DO_Show, DO_LF);
        showStringEnhanced(versionStr2, &standardFont, 1, Y_POSITION_OF_REGISTER_Y_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X) + 6, vmNormal, true, true, NO_compress, NO_raise, DO_Show, DO_LF);
      }

      else if(temporaryInformation == TI_DISP_JULIAN) {
        real34_t j;
        char tmpStr2[20];
        uInt32ToReal34(firstGregorianDay, &j);
        julianDayToInternalDate(&j,REGISTER_REAL34_DATA(TEMP_REGISTER_1));
        dateToDisplayString(TEMP_REGISTER_1, tmpStr2);
        sprintf(tmpString, "First Gregorian day set: %s", tmpStr2);
        //sprintf(tmpString, "1st Gregorian day set: %s (JD %" PRId32 ")", tmpStr2, firstGregorianDay);
        showString(tmpString, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE + TEMPORARY_INFO_OFFSET + 6, vmNormal, true, true);
      }

      else if(temporaryInformation == TI_KEYS && regist == REGISTER_X) {
        showString(errorMessage, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X) + 6, vmNormal, true, true);
      }

      else if(temporaryInformation == TI_FALSE && regist == TRUE_FALSE_REGISTER_LINE) {
        sprintf(tmpString, "false");
        showString(tmpString, &standardFont, 1, Y_POSITION_OF_TRUE_FALSE_LINE + 6, vmNormal, true, true);
      }

      else if(temporaryInformation == TI_TRUE && regist == TRUE_FALSE_REGISTER_LINE) {
        sprintf(tmpString, "true");
        showString(tmpString, &standardFont, 1, Y_POSITION_OF_TRUE_FALSE_LINE + 6, vmNormal, true, true);
      }

      else if(temporaryInformation == TI_RESET && regist == REGISTER_X) {
        sprintf(tmpString, "Data, programs, and definitions cleared");
        w = stringWidth(tmpString, &standardFont, true, true);
        showString(tmpString, &standardFont, SCREEN_WIDTH - w, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X) + 6, vmNormal, true, true);
      }

      else if(temporaryInformation == TI_SAVED && regist == REGISTER_X) {
        sprintf(prefix, "Saved");
        displayTemporaryInformationOnX(prefix);
      }

      else if(temporaryInformation == TI_CLEAR_ALL_MENUS && regist == REGISTER_X) {
        sprintf(tmpString, "All user menus cleared");
        w = stringWidth(tmpString, &standardFont, true, true);
        showString(tmpString, &standardFont, SCREEN_WIDTH - w, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X) + 6, vmNormal, true, true);
      }

      else if(temporaryInformation == TI_CLEAR_ALL_VARIABLES && regist == REGISTER_X) {
        sprintf(tmpString, "All user variables cleared");
        w = stringWidth(tmpString, &standardFont, true, true);
        showString(tmpString, &standardFont, SCREEN_WIDTH - w, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X) + 6, vmNormal, true, true);
      }

      else if(temporaryInformation == TI_DEL_ALL_MENUS && regist == REGISTER_X) {
        sprintf(tmpString, "All user menus deleted");
        w = stringWidth(tmpString, &standardFont, true, true);
        showString(tmpString, &standardFont, SCREEN_WIDTH - w, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X) + 6, vmNormal, true, true);
      }

      else if(temporaryInformation == TI_DEL_ALL_VARIABLES && regist == REGISTER_X) {
        sprintf(tmpString, "All user variables deleted");
        w = stringWidth(tmpString, &standardFont, true, true);
        showString(tmpString, &standardFont, SCREEN_WIDTH - w, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X) + 6, vmNormal, true, true);
      }

      #if defined(PC_BUILD)
      else if(temporaryInformation == TI_DMCP_ONLY && regist == REGISTER_X) {
        sprintf(prefix, "Not available on the simulator");
        displayTemporaryInformationOnX(prefix);
      }
      #endif // PC_BUILD

      else if(temporaryInformation == TI_BACKUP_RESTORED && regist == REGISTER_X) {
        clearRegisterLine(REGISTER_X, true, true);
        clearRegisterLine(REGISTER_Y, true, true);
        clearRegisterLine(REGISTER_Z, true, true);
        showString("Backup restored", &standardFont, 1, Y_POSITION_OF_REGISTER_Z_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X) + 6, vmNormal, true, true);
        showStringEnhanced(versionStr,  &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X) + 6, vmNormal, true, true, NO_compress, NO_raise, DO_Show, DO_LF);
        showStringEnhanced(versionStr2, &standardFont, 1, Y_POSITION_OF_REGISTER_Y_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X) + 6, vmNormal, true, true, NO_compress, NO_raise, DO_Show, DO_LF);
      }

      else if(temporaryInformation == TI_STATEFILE_RESTORED && regist == REGISTER_X) {
        sprintf(prefix, "State file restored");
        displayTemporaryInformationOnX(prefix);
      }

      else if(temporaryInformation == TI_PROGRAMS_RESTORED && regist == REGISTER_X) {
        sprintf(prefix, "                                ");
        displayTemporaryInformationOnX(prefix);
        sprintf(prefix, "Saved programs and equations");
        showString(prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X) - 3, vmNormal, true, true);
        sprintf(prefix, "appended");
        showString(prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X) + 17, vmNormal, true, true);
     }

      else if(temporaryInformation == TI_REGISTERS_RESTORED && regist == REGISTER_X) {
        sprintf(prefix, "                                  ");
        displayTemporaryInformationOnX(prefix);
        sprintf(prefix, "Saved global and local registers");
        showString(prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X) - 3, vmNormal, true, true);
        sprintf(prefix, "(w/ local flags) restored");
        showString(prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X) + 17, vmNormal, true, true);
      }

      else if(temporaryInformation == TI_SETTINGS_RESTORED && regist == REGISTER_X) {
        sprintf(prefix, "Saved system settings restored");
        displayTemporaryInformationOnX(prefix);
      }

      else if(temporaryInformation == TI_SUMS_RESTORED && regist == REGISTER_X) {
        sprintf(prefix, "Saved statistic data restored");
        displayTemporaryInformationOnX(prefix);
      }

      else if(temporaryInformation == TI_VARIABLES_RESTORED && regist == REGISTER_X) {
        sprintf(prefix, "Saved user variables restored");
        displayTemporaryInformationOnX(prefix);
      }

      else if(temporaryInformation == TI_PROGRAM_LOADED && regist == REGISTER_X) {
        sprintf(prefix, "Program file loaded");
        displayTemporaryInformationOnX(prefix);
      }

      else if(temporaryInformation == TI_UNDO_DISABLED && regist == REGISTER_X) {
        showString("Not enough memory for undo", &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X) + 6, vmNormal, true, true);
      }

      //Original SHOW
      else if(temporaryInformation == TI_SHOW_REGISTER && regist == REGISTER_T) { // L1
        w = stringWidth(tmpString, &standardFont, true, true);
        showString(tmpString, &standardFont, SCREEN_WIDTH - w, Y_POSITION_OF_REGISTER_T_LINE + 21*0, vmNormal, true, true);
      }

      else if(temporaryInformation == TI_SHOW_REGISTER && regist == REGISTER_Z && tmpString[300] != 0) { // L2 & L3
        w = stringWidth(tmpString + 300, &standardFont, true, true);
        showString(tmpString + 300, &standardFont, SCREEN_WIDTH - w, Y_POSITION_OF_REGISTER_T_LINE + 21*1, vmNormal, true, true);

        if(tmpString[600]) {
          w = stringWidth(tmpString + 600, &standardFont, true, true);
          showString(tmpString + 600, &standardFont, SCREEN_WIDTH - w, Y_POSITION_OF_REGISTER_T_LINE + 21*2, vmNormal, true, true);
        }
      }

      else if(temporaryInformation == TI_SHOW_REGISTER && regist == REGISTER_Y && tmpString[900] != 0) { // L4 & L5
        w = stringWidth(tmpString + 900, &standardFont, true, true);
        showString(tmpString + 900, &standardFont, SCREEN_WIDTH - w, Y_POSITION_OF_REGISTER_T_LINE + 21*3, vmNormal, true, true);

        if(tmpString[1200]) {
          w = stringWidth(tmpString + 1200, &standardFont, true, true);
          showString(tmpString + 1200, &standardFont, SCREEN_WIDTH - w, Y_POSITION_OF_REGISTER_T_LINE + 21*4, vmNormal, true, true);
        }
      }

      else if(temporaryInformation == TI_SHOW_REGISTER && regist == REGISTER_X && tmpString[1500] != 0) { // L6 & L7
        w = stringWidth(tmpString + 1500, &standardFont, true, true);
        showString(tmpString + 1500, &standardFont, SCREEN_WIDTH - w, Y_POSITION_OF_REGISTER_T_LINE + 21*5, vmNormal, true, true);

        if(tmpString[1800]) {
          w = stringWidth(tmpString + 1800, &standardFont, true, true);
          showString(tmpString + 1800, &standardFont, SCREEN_WIDTH - w, Y_POSITION_OF_REGISTER_T_LINE + 21*6, vmNormal, true, true);
        }
      }

      // NEW SHOW                                                                  //JMSHOW vv
      else if(temporaryInformation == TI_SHOW_REGISTER_SMALL) {
        #define line_h0 21
        switch(regist) {
          // L1
          case REGISTER_T:
            showDispSmall(   0, 0);
            break;
          // L2 & L3
          case REGISTER_Z:
            showDispSmall( 300, 1);
            showDispSmall( 600, 2);
            break;
          // L4 & L5
          case REGISTER_Y:
            showDispSmall( 900, 3);
            showDispSmall(1200, 4);
            break;
          // L6 & L7
          case REGISTER_X:
            showDispSmall(1500, 5);
            showDispSmall(1800, 6);
            showDispSmall(2100, 7);
            showDispSmall(2400, 8);
            break;
          default: ;
        }
      }

      else if(temporaryInformation == TI_SHOW_REGISTER_BIG) {            //JMSHOW ^^
        if(regist == REGISTER_T) {
            showDisp(   0, 0);
            showDisp( 300, 1);
            showDisp( 600, 2);
            showDisp( 900, 3);
            showDisp(1200, 4);
            showDisp(1500, 5);
            screenUpdatingMode = SCRUPD_AUTO;
          }

        //switch(regist) {
        //  // L1
        //  case REGISTER_T: showDisp(0  ,0); break;
        //  // L2 & L3
        //  case REGISTER_Z: showDisp(300,1); break;
        //  // L4 & L5
        //  case REGISTER_Y: showDisp(600,2); break;
        //  // L6 & L7
        //  case REGISTER_X: showDisp(900,3); break;
        //  default: ;
        //}

      }                                                                 //JMSHOW ^^

      else if(regist < REGISTER_X + min(displayStack, origDisplayStack) || (lastErrorCode != 0 && regist == errorMessageRegisterLine) || (temporaryInformation == TI_VIEW && regist == REGISTER_T)) {
        prefixWidth = 0;
        const int16_t baseY = Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X + ((temporaryInformation == TI_VIEW && regist == REGISTER_T) ? 0 : (getRegisterDataType(REGISTER_X) == dtReal34Matrix || getRegisterDataType(REGISTER_X) == dtComplex34Matrix) ? 4 - displayStack : 0));
        calcRegister_t origRegist = regist;
        if(temporaryInformation == TI_VIEW && regist == REGISTER_T) {
          if(currentViewRegister >= FIRST_RESERVED_VARIABLE && currentViewRegister < LAST_RESERVED_VARIABLE && allReservedVariables[currentViewRegister - FIRST_RESERVED_VARIABLE].header.pointerToRegisterData == C47_NULL) {
            copySourceRegisterToDestRegister(currentViewRegister, TEMP_REGISTER_1);
            regist = TEMP_REGISTER_1;
          }
          else {
            regist = currentViewRegister;
          }
        }

        if(regist == REGISTER_X && currentInputVariable != INVALID_VARIABLE) {
          inputRegName(prefix, &prefixWidth);
        }

        // STATISTICAL DISTR
        if(regist == REGISTER_X && lastErrorCode == 0 && calcMode != CM_PEM) {
          const char *r_i = NULL, *r_j = NULL, *r_k = NULL;
          calcRegister_t register_i = REGISTER_X, register_j = REGISTER_X, register_k = REGISTER_X;
          

          switch(softmenu[softmenuStack[0].softmenuId].menuItem) {
            case -MNU_GEV:
              r_i = STD_mu;                 register_i = REGISTER_M;
              r_j = STD_sigma;              register_j = REGISTER_S;
              r_k = STD_xi;                 register_k = REGISTER_Q;
              break;
            case -MNU_BINOM:
              r_i = STD_p;                  register_i = REGISTER_P;
              r_j = STD_n;                  register_j = REGISTER_N;
              break;
            case -MNU_CAUCH:
              r_i = STD_x STD_SUB_0;        register_i = REGISTER_M;
              r_j = STD_gamma;              register_j = REGISTER_S;
              break;
            case -MNU_WEIBL:
              r_i = STD_k;                  register_i = REGISTER_Q;
              r_j = STD_lambda;             register_j = REGISTER_S;
              break;
            case -MNU_CHI2:
            case -MNU_T:
              r_i = STD_nu;                 register_i = REGISTER_M;
              break;
            case -MNU_EXPON:
            case -MNU_POISS:
              r_i = STD_lambda;             register_i = REGISTER_R;
              break;
            case -MNU_F:
              r_i = STD_d STD_SUB_1;        register_i = REGISTER_M;
              r_j = STD_d STD_SUB_2;        register_j = REGISTER_N;
              break;
            case -MNU_GEOM:
              r_i = STD_p;                  register_i = REGISTER_P;
              break;
            case -MNU_HYPER:
              r_i = STD_N;                  register_i = REGISTER_M;
              r_j = STD_n;                  register_j = REGISTER_N;
              r_k = STD_K;                  register_k = REGISTER_Q;
              break;
            case -MNU_LOGIS:
              r_j = STD_s;                  register_j = REGISTER_S;
              r_i = STD_mu;                 register_i = REGISTER_M;
              break;
            case -MNU_NORML:
              r_j = STD_sigma;              register_j = REGISTER_S;
              r_i = STD_mu;                 register_i = REGISTER_M;
              break;
            default: ;
          }

          if(r_i != NULL || r_j != NULL || r_k != NULL) {
            stats_param_display(r_i, register_i, prefix, tmpString, REGISTER_T);
            stats_param_display(r_j, register_j, prefix, tmpString, REGISTER_Z);
            stats_param_display(r_k, register_k, prefix, tmpString, REGISTER_Y);

            prefix[0]=0;
            tmpString[0]=0;
            uint8_t ii = 255;
            if(r_i != NULL) {
              ii = Y_POSITION_OF_REGISTER_Z_LINE;
              fnDisplayStack(3);
              distModeActive = true;
            }
            if(r_j != NULL) {
              ii = Y_POSITION_OF_REGISTER_Y_LINE;
              fnDisplayStack(2);
              distModeActive = true;
            }
            if(r_k != NULL) {
              ii = Y_POSITION_OF_REGISTER_X_LINE;
              fnDisplayStack(1);
              distModeActive = true;
            }
            if(distModeActive) {
              lcd_fill_rect(0, ii - 2, SCREEN_WIDTH, 1, 0xFF);
              if(displayStack != origDisplayStack) {
                refreshScreen();                                //recurse into refreshScreen
              }
            }
          }
        }


        if(lastErrorCode != 0 && regist == errorMessageRegisterLine) {
          if(stringWidth(errorMessages[lastErrorCode], &standardFont, true, true) <= SCREEN_WIDTH - 1) {
            showString(errorMessages[lastErrorCode], &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X) + 6, vmNormal, true, true);
          }
          else {
            #if(EXTRA_INFO_ON_CALC_ERROR == 1)
              sprintf(errorMessage, "Error message %" PRIu8 " is too wide!", lastErrorCode);
              moreInfoOnError("In function refreshRegisterLine:", errorMessage, errorMessages[lastErrorCode], NULL);
            #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
            sprintf(tmpString, "Error message %" PRIu8 " is too wide!", lastErrorCode);
            w = stringWidth(tmpString, &standardFont, true, true);
            showString(tmpString, &standardFont, SCREEN_WIDTH - w, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X) + 6, vmNormal, true, true);
          }
        }

        else if(regist == NIM_REGISTER_LINE && calcMode == CM_NIM) {
          if(lastIntegerBase != 0) {
            lastBase[0] = '#';
            if(lastIntegerBase > 9) {
              lastBase[1] = '1';
              lastBase[2] = '0' + (lastIntegerBase - 10);
              lastBase[3] = 0;
            }
            else {
              lastBase[1] = '0' + lastIntegerBase;
              lastBase[2] = 0;
            }
            wLastBaseNumeric  = stringWidth(lastBase, &numericFont,  true, true);
            wLastBaseStandard = stringWidth(lastBase, &standardFont, true, true);
          }
          else if(aimBuffer[0] != 0 && aimBuffer[strlen(aimBuffer)-1]=='/') {
            char *lb = lastBase;
            if(lastDenominator >= 1000) {
              *(lb++) = STD_SUB_0[0];
              *(lb++) = STD_SUB_0[1] + (lastDenominator / 1000);
            }
            if(lastDenominator >= 100) {
              *(lb++) = STD_SUB_0[0];
              *(lb++) = STD_SUB_0[1] + (lastDenominator % 1000 / 100);
            }
            if(lastDenominator >= 10) {
              *(lb++) = STD_SUB_0[0];
              *(lb++) = STD_SUB_0[1] + (lastDenominator % 100 / 10);
            }
            *(lb++) = STD_SUB_0[0];
            *(lb++) = STD_SUB_0[1] + (lastDenominator % 10);
            *(lb++) = 0;
            wLastBaseNumeric  = stringWidth(lastBase, &numericFont,  true, true);
            wLastBaseStandard = stringWidth(lastBase, &standardFont, true, true);
          }
          else {
            wLastBaseNumeric  = 0;
            wLastBaseStandard = 0;
          }

          displayNim(nimBufferDisplay, lastBase, wLastBaseNumeric, wLastBaseStandard);
        }

        else if(regist == AIM_REGISTER_LINE && calcMode == CM_AIM && !tam.mode) {
          //JMCURSOR vv
          #if defined(TEXT_MULTILINE_EDIT)
            int16_t tmplen = stringByteLength(aimBuffer);
            if(T_cursorPos > tmplen) {T_cursorPos = tmplen;}     //Do range checking in case the cursor starts off outside of range
            if(T_cursorPos < 0)      {T_cursorPos = tmplen;}     //Do range checking in case the cursor starts off outside of range
            showStringEdC43(lines ,displayAIMbufferoffset, T_cursorPos, aimBuffer, 1, Y_POSITION_OF_NIM_LINE - 3 - checkHPoffset, vmNormal, true, true, false);  //display up to the cursor

            if(T_cursorPos == tmplen) {
              cursorEnabled = true;
            }
            else {
              cursorEnabled = false;
            }
            if(combinationFonts == 2) {
              cursorFont = &numericFont;                             //JM ENLARGE
            }
            else {
              cursorFont = &standardFont;                            //JM ENLARGE
            }
            //JMCURSOR  ^^
          #else // !TEXT_MULTILINE_EDIT

            // JM Removed and replaced with JMCURSOR vv
            if(stringWidth(aimBuffer, &standardFont, true, true) < SCREEN_WIDTH - 8) { // 8 is the standard font cursor width
              xCursor = showString(aimBuffer, &standardFont, 1, Y_POSITION_OF_NIM_LINE + 6, vmNormal, true, true);
              yCursor = Y_POSITION_OF_NIM_LINE + 6;
              cursorFont = &standardFont;
            }
            else {
              char *aimw;
              w = stringByteLength(aimBuffer) + 1;
              xcopy(tmpString,        aimBuffer, w);
              xcopy(tmpString + 1500, aimBuffer, w);
              aimw = stringAfterPixels(tmpString, &standardFont, SCREEN_WIDTH - 2, true, true);
              w = aimw - tmpString;
              *aimw = 0;

              if(stringWidth(tmpString + 1500 + w, &standardFont, true, true) >= SCREEN_WIDTH - 8) { // 8 is the standard font cursor width
                fnKeyBackspace(0); // back space
              }
              else {
                showString(tmpString, &standardFont, 1, Y_POSITION_OF_NIM_LINE - 3, vmNormal, true, true);

                xCursor = showString(tmpString + 1500 + w, &standardFont, 1, Y_POSITION_OF_NIM_LINE + 18, vmNormal, true, true);
                yCursor = Y_POSITION_OF_NIM_LINE + 18;
                cursorFont = &standardFont;
              }
            }
            // JM Removed and replaced with JMCURSOR ^^
          #endif // TEXT_MULTILINE_EDIT
        }

        else if(getSystemFlag(FLAG_FRACT)
                    && (    getRegisterDataType(regist) == dtReal34
                         && (
                                (   real34CompareAbsGreaterThan(REGISTER_REAL34_DATA(regist), const34_1e_4)
                                 && real34CompareAbsLessThan(REGISTER_REAL34_DATA(regist), const34_1e6)
                                )
                             || real34IsZero(REGISTER_REAL34_DATA(regist))
                            )
                       )
               ) {
          fractionToDisplayString(regist, tmpString);

          w = stringWidth(tmpString, &numericFont, false, true);
          lineWidth = w;
          if(w <= SCREEN_WIDTH) {
            showString(tmpString, &numericFont, SCREEN_WIDTH - w, baseY - checkHPoffset, vmNormal, false, true);
          }
          else {
            w = stringWidth(tmpString, &standardFont, false, true);
            lineWidth = w;
            if(w > SCREEN_WIDTH) {
              #if(EXTRA_INFO_ON_CALC_ERROR == 1)
                moreInfoOnError("In function refreshRegisterLine:", "Fraction representation too wide!", tmpString, NULL);
              #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
              strcpy(tmpString, "Fraction representation too wide!");
              w = stringWidth(tmpString, &standardFont, false, true);
              lineWidth = w;
            }
            showString(tmpString, &standardFont, SCREEN_WIDTH - w, baseY, vmNormal, false, true);
          }
        }

        else if(getRegisterDataType(regist) == dtReal34) {
          if(temporaryInformation == TI_COPY_FROM_SHOW && regist == REGISTER_X) {
            _fnShowRecallTI(prefix, &prefixWidth);
          }

          else if(temporaryInformation == TI_THETA_RADIUS) {
            if(regist == REGISTER_Y) {
              strcpy(prefix, "r =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_X) {
              strcpy(prefix, STD_theta " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_RADIUS_THETA) {
            if(regist == REGISTER_X) {
              strcpy(prefix, "r =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, STD_theta " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_RADIUS_THETA_SWAPPED) {
            if(regist == REGISTER_Y) {
              strcpy(prefix, "r =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_X) {
              strcpy(prefix, STD_theta " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_PERC) {
            if(regist == REGISTER_X) {
              strcpy(prefix, " % :");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_PERCD) {
            if(regist == REGISTER_X) {
              strcpy(prefix, STD_DELTA "% :");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_PERCD2) {
            if(regist == REGISTER_Y) {
              strcpy(prefix, " % :");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            if(regist == REGISTER_X) {
              strcpy(prefix, STD_DELTA "% :");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_X_Y) {
            if(regist == REGISTER_X) {
              strcpy(prefix, "x : Re =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, "y : Im =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_X_Y_SWAPPED) {
            if(regist == REGISTER_Y) {
              strcpy(prefix, "x : Re =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_X) {
              strcpy(prefix, "y : Im =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_RE_IM) {
            if(regist == REGISTER_X) {
              strcpy(prefix, "Im" STD_SPACE_FIGURE "=");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, "Re" STD_SPACE_FIGURE "=");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_SUMX_SUMY) {
            if(regist == REGISTER_X) {
              strcpy(prefix, STD_SIGMA "x =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, STD_SIGMA "y =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_XMIN_YMIN) {
            if(regist == REGISTER_X) {
              strcpy(prefix, "x" STD_SUB_m STD_SUB_i STD_SUB_n " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, "y" STD_SUB_m STD_SUB_i STD_SUB_n " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_XMAX_YMAX) {
            if(regist == REGISTER_X) {
              strcpy(prefix, "x" STD_SUB_m STD_SUB_a STD_SUB_x " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, "y" STD_SUB_m STD_SUB_a STD_SUB_x " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_SA) {
            if(regist == REGISTER_X) {
              strcpy(prefix, "s(a" STD_SUB_0 ") =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, "s(a" STD_SUB_1 ") =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_MEANX_MEANY) {
            if(regist == REGISTER_X) {
              strcpy(prefix, STD_x_BAR " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, STD_y_BAR " =");
               prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
           }

          else if(temporaryInformation == TI_PCTILEX_PCTILEY) {
            if(regist == REGISTER_X) {
              strcpy(prefix, "pctile" STD_SUB_x " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, "pctile" STD_SUB_y " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_MEDIANX_MEDIANY) {
            if(regist == REGISTER_X) {
              strcpy(prefix, "md" STD_SUB_x " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, "md" STD_SUB_y " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_Q1X_Q1Y) {
            if(regist == REGISTER_X) {
              strcpy(prefix, "Q" STD_SUB_1 STD_SPACE_3_PER_EM STD_SUB_x " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, "Q" STD_SUB_1 STD_SPACE_3_PER_EM STD_SUB_y " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_Q3X_Q3Y) {
            if(regist == REGISTER_X) {
              strcpy(prefix, "Q" STD_SUB_3 STD_SPACE_3_PER_EM STD_SUB_x " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, "Q" STD_SUB_3 STD_SPACE_3_PER_EM STD_SUB_y " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_MADX_MADY) {
            if(regist == REGISTER_X) {
              strcpy(prefix, "mad" STD_SUB_x " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, "mad" STD_SUB_y " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_IQRX_IQRY) {
            if(regist == REGISTER_X) {
              strcpy(prefix, "iqr" STD_SUB_x " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, "iqr" STD_SUB_y " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_RANGEX_RANGEY) {
            if(regist == REGISTER_X) {
              strcpy(prefix, "rg" STD_SUB_x " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, "rg" STD_SUB_y " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_SAMPLSTDDEV) {
            if(regist == REGISTER_X) {
              strcpy(prefix, "s" STD_SUB_x " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, "s" STD_SUB_y " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_POPLSTDDEV) {
            if(regist == REGISTER_X) {
              strcpy(prefix, STD_sigma STD_SUB_x " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, STD_sigma STD_SUB_y " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_STDERR) {
            if(regist == REGISTER_X) {
              strcpy(prefix, "s" STD_SUB_m STD_SUB_x " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, "s" STD_SUB_m STD_SUB_y " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_GEOMMEANX_GEOMMEANY) {
            if(regist == REGISTER_X) {
              strcpy(prefix, STD_x_BAR STD_SUB_G " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, STD_y_BAR STD_SUB_G " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_GEOMSAMPLSTDDEV) {
            if(regist == REGISTER_X) {
              strcpy(prefix, STD_epsilon STD_SUB_x " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, STD_epsilon STD_SUB_y " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_GEOMPOPLSTDDEV) {
            if(regist == REGISTER_X) {
              strcpy(prefix, STD_epsilon STD_SUB_p STD_SUB_x " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, STD_epsilon STD_SUB_p STD_SUB_y " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_GEOMSTDERR) {
            if(regist == REGISTER_X) {
              strcpy(prefix, STD_epsilon STD_SUB_m STD_SUB_x " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, STD_epsilon STD_SUB_m STD_SUB_y " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_WEIGHTEDMEANX) {
            if(regist == REGISTER_X) {
              strcpy(prefix, STD_x_BAR STD_SUB_w " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_WEIGHTEDSAMPLSTDDEV) {
            if(regist == REGISTER_X) {
              strcpy(prefix, "s" STD_SUB_w " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_WEIGHTEDPOPLSTDDEV) {
            if(regist == REGISTER_X) {
              strcpy(prefix, STD_sigma STD_SUB_w " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_WEIGHTEDSTDERR) {
            if(regist == REGISTER_X) {
              strcpy(prefix, "s" STD_SUB_m STD_SUB_w " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_STATISTIC_HISTO) {
            if(regist == REGISTER_X) {
              strcpy(prefix,STD_UP_ARROW "BIN" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            } else
            if(regist == REGISTER_Y) {
              strcpy(prefix,STD_DOWN_ARROW "BIN" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Z) {
              strcpy(prefix,"nBINS" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }


          else if(temporaryInformation == TI_ROOTS3) {
            if(regist == REGISTER_X || regist == REGISTER_Y || regist == REGISTER_Z) {
              strcpy(prefix,"Root" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            #ifdef DISCRIMINANT
            if(regist == REGISTER_T) {
              strcpy(prefix,STD_UP_ARROW "Discr." STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            #endif //DISCRIMINANT
          }
          else if(temporaryInformation == TI_ROOTS2) {
            if(regist == REGISTER_X || regist == REGISTER_Y) {
              strcpy(prefix,"Root" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            #ifdef DISCRIMINANT
            if(regist == REGISTER_Z) {
              strcpy(prefix,STD_UP_ARROW "Discr." STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            #endif //DISCRIMINANT
          }


          //L.R. Display
          else if(temporaryInformation == TI_LR && lrChosen != 0) {
            #define LRWidth 140
            bool_t prefixPre = false;
            bool_t prefixPost = false;

            if(lrChosen == CF_CAUCHY_FITTING || lrChosen == CF_GAUSS_FITTING || lrChosen == CF_PARABOLIC_FITTING){
              if(regist == REGISTER_X) {
                strcpy(prefix,getCurveFitModeFormula(lrChosen));
                while(stringWidth(prefix, &standardFont, prefixPre, prefixPost) + 1 < LRWidth) {
                  strcat(prefix,STD_SPACE_6_PER_EM);
                }
                strcat(prefix,"a" STD_SUB_0 " =");
                prefixWidth = stringWidth(prefix, &standardFont, prefixPre, prefixPost) + 1;
              }
              else if(regist == REGISTER_Y) {
                strcpy(prefix,"y = ");
                while(stringWidth(prefix, &standardFont, prefixPre, prefixPost) + 1 < LRWidth) {
                  strcat(prefix,STD_SPACE_6_PER_EM);
                }
                strcat(prefix, "a" STD_SUB_1 " =");
                prefixWidth = stringWidth(prefix, &standardFont, prefixPre, prefixPost) + 1;
              }
              else if(regist == REGISTER_Z) {
                strcpy(prefix, eatSpacesEnd(getCurveFitModeName(lrChosen)));
                if(lrCountOnes(lrSelection)>1) {
                  strcat(prefix,lrChosen == 0 ? "" : STD_SUP_ASTERISK);
                }
                while(stringWidth(prefix, &standardFont, prefixPre, prefixPost) + 1 < LRWidth) {
                  strcat(prefix,STD_SPACE_6_PER_EM);
                }
                strcat(prefix, "a" STD_SUB_2 " =");
                prefixWidth = stringWidth(prefix, &standardFont, prefixPre, prefixPost) + 1;
              }
            }
            else {
              if(regist == REGISTER_X) {
                strcpy(prefix,"y = ");
                strcat(prefix,getCurveFitModeFormula(lrChosen));
                while(stringWidth(prefix, &standardFont, prefixPre, prefixPost) + 1 < LRWidth) {
                  strcat(prefix,STD_SPACE_6_PER_EM);
                }
                strcat(prefix,"a" STD_SUB_0 " =");
                prefixWidth = stringWidth(prefix, &standardFont, prefixPre, prefixPost) + 1;
              }
              else if(regist == REGISTER_Y) {
                strcpy(prefix, eatSpacesEnd(getCurveFitModeName(lrChosen)));
                if(lrCountOnes(lrSelection)>1) {
                  strcat(prefix,lrChosen == 0 ? "" : STD_SUP_ASTERISK);
                }
                while(stringWidth(prefix, &standardFont, prefixPre, prefixPost) + 1 < LRWidth) {
                  strcat(prefix,STD_SPACE_6_PER_EM);
                }
                strcat(prefix, "a" STD_SUB_1 " =");
                prefixWidth = stringWidth(prefix, &standardFont, prefixPre, prefixPost) + 1;
              }
            }
          }

          //else if(temporaryInformation == TI_SXY) {
          //  if(regist == REGISTER_X) {
          //    strcpy(prefix, "s" STD_SUB_x STD_SUB_y " =");
          //    prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
          //  }
          //}

          //else if(temporaryInformation == TI_COV) {
          //  if(regist == REGISTER_X) {
          //    strcpy(prefix, "s" STD_SUB_m STD_SUB_w " =");
          //    prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
          //  }
          //}

          else if(temporaryInformation == TI_CALCY) {
            if(regist == REGISTER_X) {
              prefix[0] = 0;
              if(lrChosen != 0) {
                strcpy(prefix,eatSpacesEnd(getCurveFitModeName(lrChosen)));
                if(lrCountOnes(lrSelection)>1) {
                  strcat(prefix,STD_SUP_ASTERISK);
                }
                strcat(prefix, STD_SPACE_FIGURE);
              }
              strcat(prefix, STD_y_CIRC " =");
              prefixWidth = stringWidth(prefix, &standardFont, false,false) + 1;
            }
          }

          else if(temporaryInformation == TI_CALCX) {
            if(regist == REGISTER_X) {
              prefix[0] = 0;
              if(lrChosen != 0) {
                strcpy(prefix,eatSpacesEnd(getCurveFitModeName(lrChosen)));
                if(lrCountOnes(lrSelection)>1) {
                  strcat(prefix,STD_SUP_ASTERISK);
                }
                strcat(prefix, STD_SPACE_FIGURE);
              }
              strcat(prefix, STD_x_CIRC " =");
              prefixWidth = stringWidth(prefix, &standardFont, false,false) + 1;
            }
          }

          else if(temporaryInformation == TI_CALCX2) {
            if(regist == REGISTER_X) {
              prefix[0] = 0;
              if(lrChosen != 0) {
                strcpy(prefix,eatSpacesEnd(getCurveFitModeName(lrChosen)));
                if(lrCountOnes(lrSelection)>1) {
                  strcat(prefix,STD_SUP_ASTERISK);
                }
                strcat(prefix, STD_SPACE_FIGURE);
              }
              strcat(prefix, STD_x_CIRC STD_SUB_1 " =" );
              prefixWidth = stringWidth(prefix, &standardFont, false,false) + 1;
            }
            else {
              if(regist == REGISTER_Y) {
                prefix[0] = 0;
                if(lrChosen != 0) {
                  strcpy(prefix,eatSpacesEnd(getCurveFitModeName(lrChosen)));
                  if(lrCountOnes(lrSelection)>1) {
                    strcat(prefix,STD_SUP_ASTERISK);
                  }
                  strcat(prefix, STD_SPACE_FIGURE);
                }
                strcat(prefix, STD_x_CIRC STD_SUB_2 " =");
                prefixWidth = stringWidth(prefix, &standardFont, false,false) + 1;
              }
            }
          }

          else if(temporaryInformation == TI_CORR) {
            if(regist == REGISTER_X) {
              prefix[0] = 0;
              if(lrChosen != 0) {
                strcpy(prefix,eatSpacesEnd(getCurveFitModeName(lrChosen)));
                if(lrCountOnes(lrSelection)>1) {
                  strcat(prefix,STD_SUP_ASTERISK);
                }
                strcat(prefix, STD_SPACE_FIGURE);
              }
              strcat(prefix, "r =");
              prefixWidth = stringWidth(prefix, &standardFont, false,false) + 1;
            }
          }

          else if(temporaryInformation == TI_SMI) {
            if(regist == REGISTER_X) {
              strcpy(prefix, "s" STD_SUB_m STD_SUB_i " =");
              prefixWidth = stringWidth(prefix, &standardFont, false,false) + 1;
            }
          }
          //L.R. Display

          else if(temporaryInformation == TI_HARMMEANX_HARMMEANY) {
            if(regist == REGISTER_X) {
              strcpy(prefix, STD_x_BAR STD_SUB_H " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, STD_y_BAR STD_SUB_H " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_RMSMEANX_RMSMEANY) {
            if(regist == REGISTER_X) {
              strcpy(prefix, STD_x_BAR STD_SUB_R STD_SUB_M STD_SUB_S " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, STD_y_BAR STD_SUB_R STD_SUB_M STD_SUB_S " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_STATISTIC_SUMS) {
            w = realToInt32C47(SIGMA_N);
            if(regist == REGISTER_Y) {
              if(w == 1) {
                sprintf(prefix, "%03" PRId32 " data point", w);
              }
              else {
                sprintf(prefix, "%03" PRId32 " data points", w);
              }
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
              lcd_fill_rect(0, Y_POSITION_OF_REGISTER_Y_LINE - 2, SCREEN_WIDTH, 1, LCD_EMPTY_VALUE);
            }
          }

          else if(temporaryInformation == TI_STATISTIC_LR) {
             if(regist == REGISTER_X) {
               if(orOrtho(lrSelection) == CF_ORTHOGONAL_FITTING) {
                 sprintf(prefix, "L.R. selected to OrthoF");
               }
               else {
                 sprintf(prefix, "L.R. selected to %03" PRIu16, (uint16_t)((lrSelection) & 0x01FF));
               }
               prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
               //lcd_fill_rect(0, Y_POSITION_OF_REGISTER_Y_LINE - 2, SCREEN_WIDTH, 1, LCD_EMPTY_VALUE);
             }
           }

          else if(temporaryInformation == TI_SOLVER_VARIABLE_RESULT) {
            if(regist == REGISTER_X || regist == REGISTER_Y) {
              if(currentSolverVariable >= FIRST_RESERVED_VARIABLE) {
                memcpy(prefix, allReservedVariables[currentSolverVariable - FIRST_RESERVED_VARIABLE].reservedVariableName + 1, allReservedVariables[currentSolverVariable - FIRST_RESERVED_VARIABLE].reservedVariableName[0]);
                strcpy(prefix + allReservedVariables[currentSolverVariable - FIRST_RESERVED_VARIABLE].reservedVariableName[0], " =");
              }
              else {
                memcpy(prefix, allNamedVariables[currentSolverVariable - FIRST_NAMED_VARIABLE].variableName + 1, allNamedVariables[currentSolverVariable - FIRST_NAMED_VARIABLE].variableName[0]);
                strcpy(prefix + allNamedVariables[currentSolverVariable - FIRST_NAMED_VARIABLE].variableName[0], " =");
              }
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            } else
            if(regist == REGISTER_Z) {
              strcpy(prefix, "Accuracy =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }
          else if(temporaryInformation == TI_SOLVER_VARIABLE) {
            if(regist == REGISTER_X) {
              if(currentSolverVariable >= FIRST_RESERVED_VARIABLE) {
                memcpy(prefix, allReservedVariables[currentSolverVariable - FIRST_RESERVED_VARIABLE].reservedVariableName + 1, allReservedVariables[currentSolverVariable - FIRST_RESERVED_VARIABLE].reservedVariableName[0]);
                strcpy(prefix + allReservedVariables[currentSolverVariable - FIRST_RESERVED_VARIABLE].reservedVariableName[0], " =");
              }
              else {
                memcpy(prefix, allNamedVariables[currentSolverVariable - FIRST_NAMED_VARIABLE].variableName + 1, allNamedVariables[currentSolverVariable - FIRST_NAMED_VARIABLE].variableName[0]);
                strcpy(prefix + allNamedVariables[currentSolverVariable - FIRST_NAMED_VARIABLE].variableName[0], " =");
              }
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_ACC) {
            if(regist == REGISTER_X) {
              sprintf(prefix, "ACC" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_ULIM) {
            if(regist == REGISTER_X) {
              sprintf(prefix, STD_UP_ARROW "Lim" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_LLIM) {
            if(regist == REGISTER_X) {
              sprintf(prefix, STD_DOWN_ARROW "Lim" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_INTEGRAL) {
            if(regist == REGISTER_X) {
              sprintf(prefix, STD_INTEGRAL STD_ALMOST_EQUAL);
              prefixWidth = stringWidth(prefix, &numericFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_1ST_DERIVATIVE) {
            if(regist == REGISTER_X) {
              sprintf(prefix, "f' =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_2ND_DERIVATIVE) {
            if(regist == REGISTER_X) {
              sprintf(prefix, "f\" =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_VIEW && origRegist == REGISTER_T) {
            viewRegName(prefix, &prefixWidth);
          }

          else if(temporaryInformation == TI_CONV_MENU_STR && regist == REGISTER_X) {    //convert menu
                strcpy(prefix," ");
                strcat(prefix, errorMessage);
                strcat(prefix, ":");
                prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
          }

          else if(temporaryInformation == TI_ABC) {                             //JM EE \/
            if(regist == REGISTER_X) {
              strcpy(prefix, "c" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, "b" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Z) {
              strcpy(prefix, "a" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_ABBCCA) {
            if(regist == REGISTER_X) {
              strcpy(prefix, "ca" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, "bc" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Z) {
              strcpy(prefix, "ab" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_012) {
            if(regist == REGISTER_X) {
              strcpy(prefix, "sym2" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, "sym1" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Z) {
              strcpy(prefix, "sym0" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_FROM_DMS) {
            if(regist == REGISTER_X) {
              strcpy(prefix, "decimal" STD_DEGREE STD_SPACE_FIGURE " :");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_FROM_HMS) {
            if(regist == REGISTER_X) {
              strcpy(prefix, "decimal h" STD_SPACE_FIGURE " :");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_FROM_MS_TIME) {
            if(regist == REGISTER_X) {
              strcpy(prefix, "hh.mmss" STD_SPACE_FIGURE " :");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_FROM_MS_DEG) {
            if(regist == REGISTER_X) {
              strcpy(prefix, "dd.mmss" STD_SPACE_FIGURE " :");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_FROM_DATEX) {
            if(regist == REGISTER_X) {
              if(getSystemFlag(FLAG_DMY)) {
                strcpy(prefix, "dd.mmyyyy" STD_SPACE_FIGURE " :");
              }
              else if(getSystemFlag(FLAG_MDY)) {
                strcpy(prefix, "mm.ddyyyy" STD_SPACE_FIGURE " :");
              }
              else { // YMD
                strcpy(prefix, "yyyy.mmdd" STD_SPACE_FIGURE " :");
              }
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_LAST_CONST_CATNAME || temporaryInformation == TI_SCATTER_SMI) {
            if(regist == REGISTER_X) {
              strcpy(prefix, lastFuncSoftmenuName());
              if(prefix[0] != 0) {
                strcat(prefix,  " ");
                if(compareString(lastFuncSoftmenuName(), lastFuncCatalogName(), CMP_BINARY) != 0) {
                  char prefix_[16];
                  prefix_[0]=0;
                  strcat(prefix_, lastFuncCatalogName());
                  if(prefix_[0] != 0) {
                    strcat(prefix,prefix_);
                  }
                }
                if(prefix[0] != 0) {
                  strcat(prefix,  " = ");
                }
                prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
              }
            }
          }
          else if(regist == REGISTER_X && (temporaryInformation == TI_IJ || temporaryInformation == TI_MIJ)) {
            _displayIJ(prefix, &prefixWidth);
          }


          if(prefixWidth > 0) {
            if(regist == REGISTER_X) {
              showString(prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X) + TEMPORARY_INFO_OFFSET, vmNormal, true, true);
            }
            else if(regist == REGISTER_Y) {
              showString(prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_Y_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_Y) + TEMPORARY_INFO_OFFSET, vmNormal, true, true);
            }
            else if(regist == REGISTER_Z) {
              showString(prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_Z_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_Z) + TEMPORARY_INFO_OFFSET, vmNormal, true, true);
            }
          }
                                                                      //JM EE ^

          real34ToDisplayString(REGISTER_REAL34_DATA(regist), getRegisterAngularMode(regist), tmpString, &numericFont, SCREEN_WIDTH - prefixWidth, NUMBER_OF_DISPLAY_DIGITS, true, true);

          w = stringWidth(tmpString, &numericFont, false, true);
          lineWidth = w;
          if(prefixWidth > 0) {
            if(temporaryInformation == TI_INTEGRAL) {
              showString(prefix, &numericFont, 1, baseY - checkHPoffset, vmNormal, prefixPre, prefixPost);
            }
            else {
              showString(prefix, &standardFont, 1, baseY + TEMPORARY_INFO_OFFSET, vmNormal, prefixPre, prefixPost);
            }
          }
          showString(tmpString, &numericFont, (temporaryInformation == TI_VIEW && origRegist == REGISTER_T) ? prefixWidth : SCREEN_WIDTH - w, baseY - checkHPoffset, vmNormal, false, true);
        }

          //JM else if(getRegisterDataType(regist) == dtComplex34) {                                                                                                      //JM EE Removed and replaced with the below
          //JM complex34ToDisplayString(REGISTER_COMPLEX34_DATA(regist), tmpString, &numericFont, SCREEN_WIDTH, NUMBER_OF_DISPLAY_DIGITS, true, STD_SPACE_PUNCTUATION);   //JM EE Removed and replaced with the below
        else if(getRegisterDataType(regist) == dtComplex34) {
          if(temporaryInformation == TI_COPY_FROM_SHOW && regist == REGISTER_X) {
            _fnShowRecallTI(prefix, &prefixWidth);
          }

          else if(temporaryInformation == TI_SOLVER_VARIABLE_RESULT) {
            if(regist == REGISTER_X || regist == REGISTER_Y) {
              if(currentSolverVariable >= FIRST_RESERVED_VARIABLE) {
                memcpy(prefix, allReservedVariables[currentSolverVariable - FIRST_RESERVED_VARIABLE].reservedVariableName + 1, allReservedVariables[currentSolverVariable - FIRST_RESERVED_VARIABLE].reservedVariableName[0]);
                strcpy(prefix + allReservedVariables[currentSolverVariable - FIRST_RESERVED_VARIABLE].reservedVariableName[0], " =");
              }
              else {
                memcpy(prefix, allNamedVariables[currentSolverVariable - FIRST_NAMED_VARIABLE].variableName + 1, allNamedVariables[currentSolverVariable - FIRST_NAMED_VARIABLE].variableName[0]);
                strcpy(prefix + allNamedVariables[currentSolverVariable - FIRST_NAMED_VARIABLE].variableName[0], " =");
              }
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            } else 
            if(regist == REGISTER_Z) {
              strcpy(prefix, "Accuracy =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }
          else if(temporaryInformation == TI_SOLVER_VARIABLE) {
            if(regist == REGISTER_X) {
              memcpy(prefix, allNamedVariables[currentSolverVariable - FIRST_NAMED_VARIABLE].variableName + 1, allNamedVariables[currentSolverVariable - FIRST_NAMED_VARIABLE].variableName[0]);
              strcpy(prefix + allNamedVariables[currentSolverVariable - FIRST_NAMED_VARIABLE].variableName[0], " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_VIEW && origRegist == REGISTER_T) {
              viewRegName(prefix, &prefixWidth);
          }

          else if(temporaryInformation == TI_ABC) {                             //JM EE \/
            if(regist == REGISTER_X) {
              strcpy(prefix, "c" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, "b" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Z) {
              strcpy(prefix, "a" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_ABBCCA) {
            if(regist == REGISTER_X) {
              strcpy(prefix, "ca" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, "bc" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Z) {
              strcpy(prefix, "ab" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_012) {
            if(regist == REGISTER_X) {
              strcpy(prefix, "sym2" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Y) {
              strcpy(prefix, "sym1" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            else if(regist == REGISTER_Z) {
              strcpy(prefix, "sym0" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }

          else if(temporaryInformation == TI_ROOTS3) {
            if(regist == REGISTER_X || regist == REGISTER_Y || regist == REGISTER_Z) {
              strcpy(prefix,"Root" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            #ifdef DISCRIMINANT
            if(regist == REGISTER_T) {
              strcpy(prefix,STD_UP_ARROW "Discr." STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            #endif //DISCRIMINANT
          }
          else if(temporaryInformation == TI_ROOTS2) {
            if(regist == REGISTER_X || regist == REGISTER_Y) {
              strcpy(prefix,"Root" STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            #ifdef DISCRIMINANT
            if(regist == REGISTER_Z) {
              strcpy(prefix,STD_UP_ARROW "Discr." STD_SPACE_FIGURE ":");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
            #endif //DISCRIMINANT
          }
          else if(regist == REGISTER_X && (temporaryInformation == TI_IJ || temporaryInformation == TI_MIJ)) {
            _displayIJ(prefix, &prefixWidth);
          }


          if(prefixWidth > 0) {
            if(regist == REGISTER_X) {
              showString(prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X) + TEMPORARY_INFO_OFFSET, vmNormal, true, true);
            }
            else if(regist == REGISTER_Y) {
              showString(prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_Y_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_Y) + TEMPORARY_INFO_OFFSET, vmNormal, true, true);
            }
            else if(regist == REGISTER_Z) {
              showString(prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_Z_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_Z) + TEMPORARY_INFO_OFFSET, vmNormal, true, true);
            }
          }
                                                                       //JM EE ^

          complex34ToDisplayString(REGISTER_COMPLEX34_DATA(regist), tmpString, &numericFont, SCREEN_WIDTH - prefixWidth, NUMBER_OF_DISPLAY_DIGITS,true, true, getComplexRegisterAngularMode(regist),  getComplexRegisterPolarMode(regist) == amPolar);

          w = stringWidth(tmpString, &numericFont, false, true);
          lineWidth = w;
          if(prefixWidth > 0) {
            showString(prefix, &standardFont, 1, baseY + TEMPORARY_INFO_OFFSET, vmNormal, prefixPre, prefixPost);
          }
          showString(tmpString, &numericFont, (temporaryInformation == TI_VIEW && origRegist == REGISTER_T) ? prefixWidth : SCREEN_WIDTH - w, baseY - checkHPoffset, vmNormal, false, true);
        }

        else if(getRegisterDataType(regist) == dtString) {
          if(temporaryInformation == TI_COPY_FROM_SHOW && regist == REGISTER_X) {
            _fnShowRecallTI(prefix, &prefixWidth);
          }

          else if(temporaryInformation == TI_VIEW && origRegist == REGISTER_T) {
            viewRegName(prefix, &prefixWidth);
          }

          if(prefixWidth > 0) {
            showString(prefix, &standardFont, 1, baseY + TEMPORARY_INFO_OFFSET, vmNormal, prefixPre, prefixPost);
          }

          //JM REGISTER STRING LARGE FONTS
          #if defined(STACK_X_STR_LRG_FONT)
            //This is for X
            w = stringWidthWithLimitC43(REGISTER_STRING_DATA(regist), stdnumEnlarge, nocompress, SCREEN_WIDTH, false, true);
            if(temporaryInformation != TI_VIEW && regist == REGISTER_X && w<SCREEN_WIDTH) {
              lineWidth = w; //slighly incorrect if special characters are there as well.
              showStringC43(REGISTER_STRING_DATA(regist), stdnumEnlarge, nocompress, SCREEN_WIDTH - w, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X) + 6 - checkHPoffset, vmNormal, false, true);
            }
            else                                                                   //JM
          #endif // STACK_X_STR_LRG_FONT

          #if defined(STACK_X_STR_MED_FONT)
            //This is for X
            if(temporaryInformation != TI_VIEW && regist == REGISTER_X && (w = stringWidthWithLimitC43(REGISTER_STRING_DATA(regist), numHalf, nocompress, SCREEN_WIDTH, false, true)) < SCREEN_WIDTH) {
              lineWidth = w;
              showStringC43(REGISTER_STRING_DATA(regist), numHalf, nocompress, SCREEN_WIDTH - w, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X) + 6 - checkHPoffset, vmNormal, false, true);
            }
            else                                                                   //JM
          #endif //STACK_X_STR_MED_FONT

          #if defined(STACK_STR_MED_FONT)
            //This is for Y, Z & T
            if(regist >= REGISTER_Y && regist <= REGISTER_T && (w = stringWidthWithLimitC43(REGISTER_STRING_DATA(regist), numHalf, nocompress, SCREEN_WIDTH, false, true)) < SCREEN_WIDTH) {
              lineWidth = w;
              showStringC43(REGISTER_STRING_DATA(regist), numHalf, nocompress, SCREEN_WIDTH - w, baseY + 6 - checkHPoffset, vmNormal, false, true);
            }
            else                                                                   //JM
          #endif // STACK_STR_MED_FONT
            //JM ^^ large fonts


          {
            //printf("^^^^#### combinationFonts=%d maxiC=%d miniC=%d displaymode=%d\n", combinationFonts, maxiC, miniC, displaymode);
            w = stringWidth(REGISTER_STRING_DATA(regist), &standardFont, false, true);

            if(w >= SCREEN_WIDTH - prefixWidth) {
              char *tmpStrW;
              if(regist == REGISTER_X || (temporaryInformation == TI_VIEW && origRegist == REGISTER_T)) {
                xcopy(tmpString, REGISTER_STRING_DATA(regist), stringByteLength(REGISTER_STRING_DATA(regist)) + 1);
                tmpStrW = stringAfterPixels(tmpString, &standardFont, SCREEN_WIDTH - prefixWidth - 1, false, true);
                *tmpStrW = 0;
                w = stringWidth(tmpString, &standardFont, false, true);
                if(temporaryInformation == TI_VIEW && origRegist == REGISTER_T) {
                  showString(tmpString, &standardFont, prefixWidth     , Y_POSITION_OF_REGISTER_T_LINE - 3, vmNormal, false, true);
                }
                else {
                  showString(tmpString, &standardFont, SCREEN_WIDTH - w, Y_POSITION_OF_REGISTER_X_LINE - 3 - checkHPoffset, vmNormal, false, true);
                }

                w = stringByteLength(tmpString);
                xcopy(tmpString, REGISTER_STRING_DATA(regist) + w, stringByteLength(REGISTER_STRING_DATA(regist) + w) + 1);
                w = stringWidth(tmpString, &standardFont, false, true);
                if(w >= SCREEN_WIDTH - prefixWidth) {
                  tmpStrW = stringAfterPixels(tmpString, &standardFont, SCREEN_WIDTH - prefixWidth - 14 - 1, false, true); // 14 is the width of STD_ELLIPSIS
                  xcopy(tmpStrW, STD_ELLIPSIS, 3);
                  w = stringWidth(tmpString, &standardFont, false, true);
                }
                if(temporaryInformation == TI_VIEW && origRegist == REGISTER_T) {
                  showString(tmpString, &standardFont, prefixWidth     , Y_POSITION_OF_REGISTER_T_LINE + 18, vmNormal, false, true);
                }
                else {
                  showString(tmpString, &standardFont, SCREEN_WIDTH - w, Y_POSITION_OF_REGISTER_X_LINE + 18 - checkHPoffset, vmNormal, false, true);
                }
              }
              else {
                xcopy(tmpString, REGISTER_STRING_DATA(regist), stringByteLength(REGISTER_STRING_DATA(regist)) + 1);
                tmpStrW = stringAfterPixels(tmpString, &standardFont, SCREEN_WIDTH - prefixWidth - 14 - 1, false, true); // 14 is the width of STD_ELLIPSIS
                xcopy(tmpStrW, STD_ELLIPSIS, 3);
                w = stringWidth(tmpString, &standardFont, false, true);
                lineWidth = w;
                showString(tmpString, &standardFont, SCREEN_WIDTH - w, baseY + 6 - checkHPoffset, vmNormal, false, true);
              }
            }
            else {
              lineWidth = w;
              if(temporaryInformation == TI_VIEW && origRegist == REGISTER_T) {
                showString(REGISTER_STRING_DATA(regist), &standardFont, prefixWidth     , baseY + TEMPORARY_INFO_OFFSET, vmNormal, false, true);
              }
              else {
                showString(REGISTER_STRING_DATA(regist), &standardFont, SCREEN_WIDTH - w, baseY + 6                    - checkHPoffset, vmNormal, false, true);
              }
            }
          }
        }


        //original
        //else if(getRegisterDataType(regist) == dtShortInteger) {
        //  if(temporaryInformation == TI_VIEW && origRegist == REGISTER_T) {
        //    viewRegName(prefix, &prefixWidth);
        //  }
        //  shortIntegerToDisplayString(regist, tmpString, true);
        //  if(prefixWidth > 0) {
        //    showString(prefix, &standardFont, 1, baseY + TEMPORARY_INFO_OFFSET, vmNormal, prefixPre, prefixPost);
        //  }
        //  w = stringWidth(tmpString, fontForShortInteger, false, true);
        //  showString(tmpString, fontForShortInteger, (temporaryInformation == TI_VIEW && origRegist == REGISTER_T) ? min(prefixWidth, SCREEN_WIDTH - w) : SCREEN_WIDTH - w, baseY + (fontForShortInteger == &standardFont ? 6 : 0), vmNormal, false, true);
        //}

        else if(getRegisterDataType(regist) == dtShortInteger) {
          prefixWidth = 0;
          tmpString[0]=0;
          if(temporaryInformation == TI_DATA_LOSS && regist == REGISTER_X) {
             shortIntegerToDisplayString(regist, tmpString, true);
             sprintf(prefix,"Ovrfl>%ubits:",shortIntegerWordSize);
             prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
             if(prefixWidth + stringWidth(tmpString, fontForShortInteger, true, true) + 1 > SCREEN_WIDTH) {
               sprintf(prefix,"OF");
               prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
             }
          }
          if(temporaryInformation == TI_VIEW && origRegist == REGISTER_T) {
            viewRegName(prefix, &prefixWidth);
          }
          else if(temporaryInformation == TI_COPY_FROM_SHOW && regist == REGISTER_X) {
            _fnShowRecallTI(prefix, &prefixWidth);
          }
          if(prefixWidth > 0) {
            if(regist == REGISTER_X) {
              showString(prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE + TEMPORARY_INFO_OFFSET - REGISTER_LINE_HEIGHT*(regist - REGISTER_X), vmNormal, true, true);
            }
            if(tmpString[0]!=0) {
              shortIntegerToDisplayString(regist, tmpString, true);
            }
            showString(tmpString, fontForShortInteger, SCREEN_WIDTH - stringWidth(tmpString, fontForShortInteger, false, true), Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X) + (fontForShortInteger == &standardFont ? 6 : 0) - (fontForShortInteger == &numericFont && temporaryInformation == TI_NO_INFO && checkHP ? 50:0), vmNormal, false, true);
          } else {
            shortIntegerToDisplayString(regist, tmpString, true);
            showString(tmpString, fontForShortInteger, SCREEN_WIDTH - stringWidth(tmpString, fontForShortInteger, false, true), Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(regist - REGISTER_X) + (fontForShortInteger == &standardFont ? 6 : 0) - (fontForShortInteger == &numericFont && temporaryInformation == TI_NO_INFO && checkHP ? 50:0), vmNormal, false, true);

            //JM SHOIDISP // use the top part of the screen for HEX and BIN    //JM vv SHOIDISP
            //DISP_TI=3    T=16    T=16    T=16
            //DISP_TI=2            Z=10    T=2
            //DISP_TI=1                    Z=10
            if(baseModeActive && lastErrorCode == 0) {
              if(displayStack == 1) { //handle Reg Pos Y
                copySourceRegisterToDestRegister(REGISTER_Y, TEMP_REGISTER_1);
                copySourceRegisterToDestRegister(REGISTER_X, REGISTER_Y);
                setRegisterTag(REGISTER_Y,  !bcdDisplay ? 10 : 10);
                shortIntegerToDisplayString(REGISTER_Y, tmpString, true);
                if(lastErrorCode == 0 && stringWidth(tmpString, fontForShortInteger, false, true) + stringWidth("  X: ", &standardFont, false, true) <= SCREEN_WIDTH) {
                  showString("  X: ", &standardFont, 0, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(REGISTER_Y - REGISTER_X) + (fontForShortInteger == &standardFont ? 6 : 0), vmNormal, false, true);
                }
                showString(tmpString, fontForShortInteger, SCREEN_WIDTH - stringWidth(tmpString, fontForShortInteger, false, true), Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(REGISTER_Y - REGISTER_X) + (fontForShortInteger == &standardFont ? 6 : 0), vmNormal, false, true);
                copySourceRegisterToDestRegister(TEMP_REGISTER_1,REGISTER_Y);
              }
              if(displayStack == 1 || displayStack == 2){ //handle reg pos Z
                copySourceRegisterToDestRegister(REGISTER_Z, TEMP_REGISTER_1);
                copySourceRegisterToDestRegister(REGISTER_X, REGISTER_Z);
                if(displayStack == 2) {
                  setRegisterTag(REGISTER_Z,  !bcdDisplay ? 10 : 10);
                }
                else if(displayStack == 1) {
                  setRegisterTag(REGISTER_Z, !bcdDisplay ? 2 : 2);
                }
                shortIntegerToDisplayString(REGISTER_Z, tmpString, true);
                if(lastErrorCode == 0 && stringWidth(tmpString, fontForShortInteger, false, true) + stringWidth("  X: ", &standardFont, false, true) <= SCREEN_WIDTH) {
                  showString("  X: ", &standardFont, 0, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(REGISTER_Z - REGISTER_X) + (fontForShortInteger == &standardFont ? 6 : 0), vmNormal, false, true);
                }
                showString(tmpString, fontForShortInteger, SCREEN_WIDTH - stringWidth(tmpString, fontForShortInteger, false, true), Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(REGISTER_Z - REGISTER_X) + (fontForShortInteger == &standardFont ? 6 : 0), vmNormal, false, true);
                copySourceRegisterToDestRegister(TEMP_REGISTER_1,REGISTER_Z);
              }
              if(displayStack == 1 || displayStack == 2 || displayStack == 3) { //handle reg pos T
                copySourceRegisterToDestRegister(REGISTER_T, TEMP_REGISTER_1);
                copySourceRegisterToDestRegister(REGISTER_X, REGISTER_T);
                setRegisterTag(REGISTER_T, !bcdDisplay ? 16 : 17);
                shortIntegerToDisplayString(REGISTER_T, tmpString, true);
                if(lastErrorCode == 0 && stringWidth(tmpString, fontForShortInteger, false, true) + stringWidth("  X: ", &standardFont, false, true) <= SCREEN_WIDTH) {
                  showString("  X: ", &standardFont, 0, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(REGISTER_T - REGISTER_X) + (fontForShortInteger == &standardFont ? 6 : 0), vmNormal, false, true);
                }
                showString(tmpString, fontForShortInteger, SCREEN_WIDTH - stringWidth(tmpString, fontForShortInteger, false, true), Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(REGISTER_T - REGISTER_X) + (fontForShortInteger == &standardFont ? 6 : 0), vmNormal, false, true);
                copySourceRegisterToDestRegister(TEMP_REGISTER_1,REGISTER_T);
              }
              if(displayStack == 3) {
                lcd_fill_rect(0, Y_POSITION_OF_REGISTER_Z_LINE - 2, SCREEN_WIDTH, 1, 0xFF);
              }
              else if(displayStack == 2) {
                lcd_fill_rect(0, Y_POSITION_OF_REGISTER_Y_LINE - 2, SCREEN_WIDTH, 1, 0xFF);
              }
              else if(displayStack == 1) {
                lcd_fill_rect(0, Y_POSITION_OF_REGISTER_X_LINE - 2, SCREEN_WIDTH, 1, 0xFF);
              }
            }
          }
                                                                           //JM ^^
        }

        else if(getRegisterDataType(regist) == dtLongInteger) {
          if(temporaryInformation == TI_COPY_FROM_SHOW && regist == REGISTER_X) {
            _fnShowRecallTI(prefix, &prefixWidth);
          }

          else if(temporaryInformation == TI_SOLVER_VARIABLE) {
            if(regist == REGISTER_X) {
              memcpy(prefix, allNamedVariables[currentSolverVariable - FIRST_NAMED_VARIABLE].variableName + 1, allNamedVariables[currentSolverVariable - FIRST_NAMED_VARIABLE].variableName[0]);
              strcpy(prefix + allNamedVariables[currentSolverVariable - FIRST_NAMED_VARIABLE].variableName[0], " =");
              prefixWidth = stringWidth(prefix, &standardFont, true, true) + 1;
            }
          }
          else if(regist == REGISTER_X && (temporaryInformation == TI_IJ || temporaryInformation == TI_MIJ)) {
            _displayIJ(prefix, &prefixWidth);
          }

          if(prefixWidth > 0) {
            if(regist == REGISTER_X) {
              showString(prefix, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE + TEMPORARY_INFO_OFFSET - REGISTER_LINE_HEIGHT*(regist - REGISTER_X), vmNormal, true, true);
            }
          }                                                               //JMms ^^

          if(temporaryInformation == TI_VIEW && origRegist == REGISTER_T) {
            viewRegName(prefix, &prefixWidth);
          }
          longIntegerRegisterToDisplayString(regist, tmpString, TMP_STR_LENGTH, SCREEN_WIDTH - prefixWidth, 50, true);          //JMms added prefix   //JM added last parameter: Allow LARGELI

          if(temporaryInformation == TI_DAY_OF_WEEK) {
            if(regist == REGISTER_X) {
              int day = (int)tmpString[0] - '0';
              if(day < 1 || day > 7) {
                day = 0;
              }
              strcpy(prefix, nameOfWday_en[day]);

              // Old code
              //if(strcmp(tmpString, "1") == 0) {
              //  strcpy(prefix, nameOfWday_en[1]);
              //}
              //else if(strcmp(tmpString, "2") == 0) {
              //  strcpy(prefix, nameOfWday_en[2]);
              //}
              //else if(strcmp(tmpString, "3") == 0) {
              //  strcpy(prefix, nameOfWday_en[3]);
              //}
              //else if(strcmp(tmpString, "4") == 0) {
              //  strcpy(prefix, nameOfWday_en[4]);
              //}
              //else if(strcmp(tmpString, "5") == 0) {
              //  strcpy(prefix, nameOfWday_en[5]);
              //}
              //else if(strcmp(tmpString, "6") == 0) {
              //  strcpy(prefix, nameOfWday_en[6]);
              //}
              //else if(strcmp(tmpString, "7") == 0) {
              //  strcpy(prefix, nameOfWday_en[7]);
              //}
              //else {
              //  strcpy(prefix, nameOfWday_en[0]);
              //}
              showString(prefix, &standardFont, 1, baseY + TEMPORARY_INFO_OFFSET, vmNormal, true, true);
            }
          }

          w = stringWidth(tmpString, &numericFont, false, true);
          lineWidth = w;
          if(prefixWidth > 0) {
            showString(prefix, &standardFont, 1, baseY + TEMPORARY_INFO_OFFSET, vmNormal, prefixPre, prefixPost);
          }

          if(w <= SCREEN_WIDTH) {
            showString(tmpString, &numericFont, (temporaryInformation == TI_VIEW && origRegist == REGISTER_T) ? prefixWidth : SCREEN_WIDTH - w, baseY - checkHPoffset, vmNormal, false, true);
          }
          else {
            w = stringWidth(tmpString, &standardFont, false, true);
            if(w > SCREEN_WIDTH) {
              #if(EXTRA_INFO_ON_CALC_ERROR == 1)
                moreInfoOnError("In function refreshRegisterLine:", "Long integer representation too wide!", tmpString, NULL);
              #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
              strcpy(tmpString, "Long integer representation too wide!");
            }
            w = stringWidth(tmpString, &standardFont, false, true);
            lineWidth = w;
            showString(tmpString, &standardFont, (temporaryInformation == TI_VIEW && origRegist == REGISTER_T) ? prefixWidth : SCREEN_WIDTH - w, baseY + 6, vmNormal, false, true);
          }
        }

        else if(getRegisterDataType(regist) == dtTime) {
          if(temporaryInformation == TI_COPY_FROM_SHOW && regist == REGISTER_X) {
            _fnShowRecallTI(prefix, &prefixWidth);
          }

          else if(temporaryInformation == TI_VIEW && origRegist == REGISTER_T) {
            viewRegName(prefix, &prefixWidth);
          }
          timeToDisplayString(regist, tmpString, false);
          w = stringWidth(tmpString, &numericFont, false, true);
          if(prefixWidth > 0) {
            showString(prefix, &standardFont, 1, baseY + TEMPORARY_INFO_OFFSET, vmNormal, prefixPre, prefixPost);
          }
          showString(tmpString, &numericFont, (temporaryInformation == TI_VIEW && origRegist == REGISTER_T) ? prefixWidth : SCREEN_WIDTH - w, baseY - checkHPoffset, vmNormal, false, true);
        }

        else if(getRegisterDataType(regist) == dtDate) {
          if(temporaryInformation == TI_COPY_FROM_SHOW && regist == REGISTER_X) {
            _fnShowRecallTI(prefix, &prefixWidth);
          }
          else if(temporaryInformation == TI_DAY_OF_WEEK) {
            if(regist == REGISTER_X) {
              strcpy(prefix, nameOfWday_en[getDayOfWeek(regist)]);
              showString(prefix, &standardFont, 1, baseY + TEMPORARY_INFO_OFFSET, vmNormal, true, true);
            }
          }
          else if(temporaryInformation == TI_VIEW && origRegist == REGISTER_T) {
            viewRegName(prefix, &prefixWidth);
          }

          dateToDisplayString(regist, tmpString);
          w = stringWidth(tmpString, &numericFont, false, true);
          if(prefixWidth > 0) {
            showString(prefix, &standardFont, 1, baseY + TEMPORARY_INFO_OFFSET, vmNormal, prefixPre, prefixPost);
          }
          showString(tmpString, &numericFont, (temporaryInformation == TI_VIEW && origRegist == REGISTER_T) ? prefixWidth : SCREEN_WIDTH - w, baseY - checkHPoffset, vmNormal, false, true);
        }

        else if(getRegisterDataType(regist) == dtConfig) {
          if(temporaryInformation == TI_COPY_FROM_SHOW && regist == REGISTER_X) {
            _fnShowRecallTI(prefix, &prefixWidth);
          }
          if(temporaryInformation == TI_VIEW && origRegist == REGISTER_T) {
            viewRegName(prefix, &prefixWidth);
          }
          xcopy(tmpString, "Configuration data", 19);
          w = stringWidth(tmpString, &numericFont, false, true);
          lineWidth = w;
          if(prefixWidth > 0) {
            showString(prefix, &standardFont, 1, baseY + TEMPORARY_INFO_OFFSET, vmNormal, prefixPre, prefixPost);
          }
          showString(tmpString, &numericFont, (temporaryInformation == TI_VIEW && origRegist == REGISTER_T) ? prefixWidth : SCREEN_WIDTH - w, baseY - checkHPoffset, vmNormal, false, true);
        }

        else if(getRegisterDataType(regist) == dtReal34Matrix) {
          if((origRegist == REGISTER_X && calcMode != CM_MIM) || (temporaryInformation == TI_VIEW && origRegist == REGISTER_T)) {
            real34Matrix_t matrix;
            prefixWidth = 0; prefix[0] = 0;
            linkToRealMatrixRegister(regist, &matrix);
            if(temporaryInformation == TI_VIEW && origRegist == REGISTER_T) {
              viewRegName(prefix, &prefixWidth);
            }
            showRealMatrix(&matrix, prefixWidth);
            if(lastErrorCode != 0) {
              refreshRegisterLine(errorMessageRegisterLine);
            }
            else if(regist == REGISTER_X && (temporaryInformation == TI_IJ || temporaryInformation == TI_MIJ)) {
              _displayIJ(prefix, &prefixWidth);
            }
            if(temporaryInformation == TI_TRUE || temporaryInformation == TI_FALSE) {
              refreshRegisterLine(TRUE_FALSE_REGISTER_LINE);
            }
            if(prefixWidth > 0) {
              showString(prefix, &standardFont, 1, baseY + TEMPORARY_INFO_OFFSET, vmNormal, prefixPre, prefixPost);
            }
          }
          else {
            real34MatrixToDisplayString(regist, tmpString);
            w = stringWidth(tmpString, &numericFont, false, true);
            lineWidth = w;
            showString(tmpString, &numericFont, SCREEN_WIDTH - w - 2, baseY, vmNormal, false, true);
          }

          if(temporaryInformation == TI_INACCURATE && regist == REGISTER_X) {
            showString("This result may be inaccurate", &standardFont, 1, Y_POSITION_OF_ERR_LINE, vmNormal, true, true);
          }
        }

        else if(getRegisterDataType(regist) == dtComplex34Matrix) {
          if((origRegist == REGISTER_X && calcMode != CM_MIM) || (temporaryInformation == TI_VIEW && origRegist == REGISTER_T)) {
            complex34Matrix_t matrix;
            linkToComplexMatrixRegister(regist, &matrix);
            if(temporaryInformation == TI_VIEW && origRegist == REGISTER_T) {
              viewRegName(prefix, &prefixWidth);
            }
            else if(regist == REGISTER_X && (temporaryInformation == TI_IJ || temporaryInformation == TI_MIJ)) {
              _displayIJ(prefix, &prefixWidth);
            }
            showComplexMatrix(&matrix, prefixWidth, getComplexRegisterAngularMode(regist), getComplexRegisterPolarMode(regist) == amPolar);
            if(lastErrorCode != 0) {
              refreshRegisterLine(errorMessageRegisterLine);
            }
            if(temporaryInformation == TI_TRUE || temporaryInformation == TI_FALSE) {
              refreshRegisterLine(TRUE_FALSE_REGISTER_LINE);
            }
            if(prefixWidth > 0) {
              showString(prefix, &standardFont, 1, baseY + TEMPORARY_INFO_OFFSET, vmNormal, prefixPre, prefixPost);
            }
          }
          else {
            complex34MatrixToDisplayString(regist, tmpString);
            w = stringWidth(tmpString, &numericFont, false, true);
            lineWidth = w;
            showString(tmpString, &numericFont, SCREEN_WIDTH - w - 2, baseY, vmNormal, false, true);
          }

          if(temporaryInformation == TI_INACCURATE && regist == REGISTER_X) {
            showString("This result may be inaccurate", &standardFont, 1, Y_POSITION_OF_ERR_LINE, vmNormal, true, true);
          }
        }

        else {
          sprintf(tmpString, "Displaying %s: to be coded!", getRegisterDataTypeName(regist, true, false));
          showString(tmpString, &standardFont, SCREEN_WIDTH - stringWidth(tmpString, &standardFont, false, true), baseY + 6, vmNormal, false, true);
        }

        if(temporaryInformation == TI_VIEW && origRegist == REGISTER_X) {
          regist = REGISTER_X;
        }
      }

      if(regist == REGISTER_T) {
        lineTWidth = lineWidth;
      }
    }

    if(getRegisterDataType(REGISTER_X) == dtReal34Matrix || getRegisterDataType(REGISTER_X) == dtComplex34Matrix || calcMode == CM_MIM || distModeActive || baseModeActive) {
      displayStack = origDisplayStack;
    }
  }


  void displayNim(const char *nim, const char *lastBase, int16_t wLastBaseNumeric, int16_t wLastBaseStandard) {
    int16_t w;
    if(stringWidth(nim, &numericFont, true, true) + wLastBaseNumeric <= SCREEN_WIDTH - 16) { // 16 is the numeric font cursor width
      xCursor = showString(nim, &numericFont, 0, Y_POSITION_OF_NIM_LINE - checkHPoffset, vmNormal, true, true);
      yCursor = Y_POSITION_OF_NIM_LINE;
      cursorFont = &numericFont;

      if(lastIntegerBase != 0 || (aimBuffer[0] != 0 && aimBuffer[strlen(aimBuffer)-1]=='/')) {
        showString(lastBase, &numericFont, xCursor + 16, Y_POSITION_OF_NIM_LINE - checkHPoffset, vmNormal, true, true);
      }
    }
    else if(stringWidth(nim, &standardFont, true, true) + wLastBaseStandard <= SCREEN_WIDTH - 8) { // 8 is the standard font cursor width
      xCursor = showString(nim, &standardFont, 0, Y_POSITION_OF_NIM_LINE + 6, vmNormal, true, true);
      yCursor = Y_POSITION_OF_NIM_LINE + 6;
      cursorFont = &standardFont;

      if(lastIntegerBase != 0 || (aimBuffer[0] != 0 && aimBuffer[strlen(aimBuffer)-1]=='/')) {
        showString(lastBase, &standardFont, xCursor + 8, Y_POSITION_OF_NIM_LINE + 6, vmNormal, true, true);
      }
    }
    else {
      char *nimw;
      w = stringByteLength(nim) + 1;
      xcopy(tmpString,        nim, w);
      xcopy(tmpString + 1500, nim, w);
      nimw = stringAfterPixels(tmpString, &standardFont, SCREEN_WIDTH - 1, true, true);
      w = nimw - tmpString;
      *nimw = 0;

      if(stringWidth(tmpString + 1500 + w, &standardFont, true, true) + wLastBaseStandard > SCREEN_WIDTH - 8) { // 8 is the standard font cursor width
        addItemToNimBuffer(ITM_BACKSPACE);
      }
      else {
        showString(tmpString, &standardFont, 0, Y_POSITION_OF_NIM_LINE - 3, vmNormal, true, true);

        xCursor = showString(tmpString + 1500 + w, &standardFont, 0, Y_POSITION_OF_NIM_LINE + 18, vmNormal, true, true);
        yCursor = Y_POSITION_OF_NIM_LINE + 18;
        cursorFont = &standardFont;

        if(lastIntegerBase != 0 || (aimBuffer[0] != 0 && aimBuffer[strlen(aimBuffer)-1] == '/')) {
          showString(lastBase, &standardFont, xCursor + 8, Y_POSITION_OF_NIM_LINE + 18, vmNormal, true, true);
        }
      }
    }
  }


  void clearTamBuffer(void) {
    if(shiftF || shiftG) {
      //lcd_fill_rect(18, Y_POSITION_OF_TAM_LINE, 120, 32, LCD_SET_VALUE);
      lcd_fill_rect(18, Y_POSITION_OF_TAM_LINE, SCREEN_WIDTH - 18, 32, LCD_SET_VALUE); //JM Clear the whole t-register instead of only 120+18 oixels
    }
    else {
      //lcd_fill_rect(0, Y_POSITION_OF_TAM_LINE, 138, 32, LCD_SET_VALUE);
      lcd_fill_rect(0, Y_POSITION_OF_TAM_LINE, SCREEN_WIDTH, 32, LCD_SET_VALUE); //JM Clear the whole t-register instead of 138
    }
  }


  void clearShiftState(void) {
    uint32_t fcol, frow, gcol, grow;
    getGlyphBounds(STD_MODE_F, 0, &standardFont, &fcol, &frow);
    getGlyphBounds(STD_MODE_G, 0, &standardFont, &gcol, &grow);
    lcd_fill_rect(X_SHIFT, Y_SHIFT, (fcol > gcol ? fcol : gcol), (frow > grow ? frow : grow), LCD_SET_VALUE);
    if(calcMode == CM_PEM) {
        fnPem(NOPARAM);
    }
  }


  void displayShiftAndTamBuffer(void) {
    if(calcMode == CM_ASSIGN) {
      updateAssignTamBuffer();
    }

    if(calcMode != CM_ASSIGN || itemToBeAssigned == 0 || tam.alpha) {
      if(shiftF) {
        showGlyph(STD_MODE_F, &standardFont, X_SHIFT, Y_SHIFT, vmNormal, true, true); // f is pixel 4+8+3 wide
      }
      else if(shiftG) {
        showGlyph(STD_MODE_G, &standardFont, X_SHIFT, Y_SHIFT, vmNormal, true, true); // g is pixel 4+10+1 wide
      }
    }

    if(tam.mode || calcMode == CM_ASSIGN) {
      if(calcMode == CM_PEM) { // Variable line to display TAM informations
        lcd_fill_rect(45+20, tamOverPemYPos, 168, 20, LCD_SET_VALUE);
        showString(tamBuffer, &standardFont, 75+20, tamOverPemYPos, vmNormal,  false, false);
      }
      else { // Fixed line to display TAM informations
        clearTamBuffer();
        showString(tamBuffer, &standardFont, 18, Y_POSITION_OF_TAM_LINE + 6, vmNormal, true, true);
      }
    }
  }


  int16_t refreshScreenCounter = 0;        //JM
  void refreshScreen(void) {
    if(running_program_jm) { //JM TEST PROGRAM!
      return;
    }

    #if defined(PC_BUILD)
      jm_show_calc_state("refreshScreen");
      printf(">>> refreshScreenCounter=%d calcMode=%d last_CM=%d doRefreshSoftMenu=%d screenUpdatingMode=%d\n", refreshScreenCounter++, calcMode, last_CM, doRefreshSoftMenu, screenUpdatingMode);    //JMYY
    #endif // PC_BUILD
    //screenUpdatingMode = 0; //0 is ALL REFRESHES; ~0 is NO REFRESHES

    if(calcMode!=CM_AIM && calcMode!=CM_NIM && calcMode!=CM_PLOT_STAT && calcMode!=CM_GRAPH && calcMode!=CM_LISTXY && last_CM != 240) {  //240 specifically to prefent this
      last_CM = 254;  //JM Force NON-CM_AIM and NON-CM_NIM to refresh to be compatible to 43S
    } else if (last_CM == 240) last_CM = calcMode;

    switch(calcMode) {
      case CM_FLAG_BROWSER:
        last_CM = calcMode;
        clearScreen();
        flagBrowser(NOPARAM);
        refreshStatusBar();
        break;

      case CM_FONT_BROWSER:
        last_CM = calcMode;
        clearScreen();
        fontBrowser(NOPARAM);
        refreshStatusBar();
        break;

      case CM_REGISTER_BROWSER:
        last_CM = calcMode;
        clearScreen();
        registerBrowser(NOPARAM);
        refreshStatusBar();
        break;

      case CM_PEM:
        clearScreen();
        showSoftmenuCurrentPart();
        fnPem(NOPARAM);
        displayShiftAndTamBuffer();
        refreshStatusBar();
        break;

      case CM_ASN_BROWSER:
      case CM_NORMAL:
      case CM_AIM:
      case CM_NIM:
      case CM_MIM:
      case CM_EIM:
      case CM_ASSIGN:
      case CM_ERROR_MESSAGE:
      case CM_CONFIRMATION:
      case CM_TIMER:
        if(doRefreshSoftMenu) {
          screenUpdatingMode = SCRUPD_MANUAL_MENU ;
        }
        if(last_CM != calcMode || calcMode == CM_CONFIRMATION) {
          screenUpdatingMode = SCRUPD_AUTO;
        }
        else if(calcMode == CM_MIM) {
          screenUpdatingMode = (aimBuffer[0] == 0) ? SCRUPD_AUTO : (SCRUPD_MANUAL_STACK | SCRUPD_MANUAL_SHIFT_STATUS);
        }
        else if(calcMode == CM_TIMER) {
          screenUpdatingMode = SCRUPD_MANUAL_STACK | SCRUPD_MANUAL_SHIFT_STATUS;
        }

        if(screenUpdatingMode == SCRUPD_AUTO) {
          clearScreen();
        }
        else {
          if(!(screenUpdatingMode & SCRUPD_MANUAL_STATUSBAR)) {
            lcd_fill_rect(0, 0, SCREEN_WIDTH, Y_POSITION_OF_REGISTER_T_LINE, LCD_SET_VALUE);
          }
          if(!(screenUpdatingMode & (SCRUPD_MANUAL_STACK | SCRUPD_SKIP_STACK_ONE_TIME))) {
            lcd_fill_rect(0, Y_POSITION_OF_REGISTER_T_LINE, SCREEN_WIDTH, 240 - Y_POSITION_OF_REGISTER_T_LINE - SOFTMENU_HEIGHT * 3, LCD_SET_VALUE);
          }
          if(!(screenUpdatingMode & (SCRUPD_MANUAL_MENU | SCRUPD_SKIP_MENU_ONE_TIME))) {
            lcd_fill_rect(0, 240 - SOFTMENU_HEIGHT * 3, SCREEN_WIDTH, SOFTMENU_HEIGHT * 3, LCD_SET_VALUE);
          }
        }

        // The ordering of the 4 lines below is important for SHOW (temporaryInformation == TI_SHOW_REGISTER)
        if(last_CM != calcMode || !(screenUpdatingMode & (SCRUPD_MANUAL_STACK | SCRUPD_SKIP_STACK_ONE_TIME))) {
          if(calcMode != CM_TIMER && temporaryInformation != TI_VIEW) {
            refreshRegisterLine(REGISTER_T);
          }
          refreshRegisterLine(REGISTER_Z);
          refreshRegisterLine(REGISTER_Y);
          refreshRegisterLine(REGISTER_X);
          if(temporaryInformation == TI_VIEW) {
            clearRegisterLine(REGISTER_T, true, true);
            refreshRegisterLine(REGISTER_T);
          }
        }
        else if(calcMode == CM_NIM) {
          refreshRegisterLine(NIM_REGISTER_LINE);
        }

        //if(last_CM != calcMode) {
        //  clearScreen_old(true, false, false);
        //}

        if(calcMode == CM_ASN_BROWSER) {
          last_CM = calcMode;
          fnAsnViewer(NOPARAM);
          calcModeNormal();
          calcMode = last_CM;
        }

        if(calcMode == CM_MIM) {
          showMatrixEditor();
        }
        if(calcMode == CM_TIMER) {
          fnShowTimerApp();
        }

        if(currentSolverStatus & SOLVER_STATUS_INTERACTIVE) {
          bool_t mvarMenu = false;
          for(int i=0; i<SOFTMENU_STACK_SIZE; i++) {
            if(softmenu[softmenuStack[i].softmenuId].menuItem == -MNU_MVAR) {
              mvarMenu = true;
              break;
            }
          }
          if(!mvarMenu) {
            if(currentSolverStatus & SOLVER_STATUS_USES_FORMULA) {
              if((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_INTEGRATE) {
                showSoftmenu(-MNU_Sf);
              }
              else {
                showSoftmenu(-MNU_Solver);
              }
            }
            else {
              currentMvarLabel = INVALID_VARIABLE;
              showSoftmenu(-MNU_MVAR);
            }
          }
        }
        if(calcMode == CM_EIM) {
          bool_t mvarMenu = false;
          for(int i=0; i<SOFTMENU_STACK_SIZE; i++) {
            if(softmenu[softmenuStack[i].softmenuId].menuItem == -MNU_EQ_EDIT) {
              mvarMenu = true;
              break;
            }
          }
          if(!mvarMenu) {
            showSoftmenu(-MNU_EQ_EDIT);
          }
        }

        if((last_CM != calcMode) || (doRefreshSoftMenu)) {
          last_CM = calcMode;
          doRefreshSoftMenu = false;
          displayShiftAndTamBuffer();

          if(temporaryInformation != TI_SHOW_REGISTER_BIG && temporaryInformation != TI_SHOW_REGISTER_SMALL) {       //JM
            showSoftmenuCurrentPart();
          }
        }
        else {
          if(!(screenUpdatingMode & SCRUPD_MANUAL_SHIFT_STATUS)) {
            if(screenUpdatingMode & (SCRUPD_MANUAL_STACK | SCRUPD_SKIP_STACK_ONE_TIME)) {
              clearShiftState();
            }
            displayShiftAndTamBuffer();
          }

          if(!(screenUpdatingMode & (SCRUPD_MANUAL_MENU | SCRUPD_SKIP_MENU_ONE_TIME))) {
            showSoftmenuCurrentPart();
          }
        }

        if(programRunStop == PGM_STOPPED || programRunStop == PGM_WAITING) {
          hourGlassIconEnabled = false;
        }
        if(last_CM == calcMode || !(screenUpdatingMode & SCRUPD_MANUAL_STATUSBAR)) {
          refreshStatusBar();
        }
        #if(REAL34_WIDTH_TEST == 1)
          for(int y=Y_POSITION_OF_REGISTER_Y_LINE; y<Y_POSITION_OF_REGISTER_Y_LINE + 2*REGISTER_LINE_HEIGHT; y++ ) {
            setBlackPixel(SCREEN_WIDTH - largeur - 1, y);
          }
        #endif // (REAL34_WIDTH_TEST == 1)
        break;

      case CM_LISTXY:                     //JM
        if((last_CM != calcMode) || (doRefreshSoftMenu)) {
          last_CM = calcMode;
          doRefreshSoftMenu = false;
          displayShiftAndTamBuffer();
          refreshStatusBar();
          fnStatList();
          hourGlassIconEnabled = false;
          refreshStatusBar();
        }
        break;

      case CM_GRAPH:
        if((last_CM != calcMode) || (doRefreshSoftMenu)) {
          if(last_CM == 252) {
            last_CM--;
          }
          else {
            last_CM = 252; //calcMode;
          }
          doRefreshSoftMenu = false;
          //clearScreen();
          displayShiftAndTamBuffer();
          showSoftmenuCurrentPart();
          hourGlassIconEnabled = true;
          refreshStatusBar();
          //graphPlotstat(plotSelection);
          graph_plotmem();
          if(lastErrorCode != ERROR_NONE) {
            //printf("lastErrorCode1=%d\n", lastErrorCode);
            //printf(">>>> %d\n", softmenu[softmenuStack[0].softmenuId].menuItem);
            if(softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_GRAPH) {
              popSoftmenu();
              calcMode = CM_NORMAL;
              refreshScreen();
            }
          }

          hourGlassIconEnabled = false;
          showHideHourGlass();
          refreshStatusBar();
        }
        break;

      case CM_PLOT_STAT:
        if((last_CM != calcMode) || (doRefreshSoftMenu)) {
          if(last_CM == 252) {
            last_CM--;
          }
          else {
            last_CM = 252; //calcMode;
          }
          doRefreshSoftMenu = false;
          //clearScreen();
          displayShiftAndTamBuffer();
          showSoftmenuCurrentPart();
          hourGlassIconEnabled = true;
          refreshStatusBar();
          graphPlotstat(plotSelection);
          if(lastErrorCode != ERROR_NONE) {
            if(softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_GRAPH) {
              popSoftmenu();
              calcMode = CM_NORMAL;
              refreshScreen();
            }
          }
          graphDrawLRline(plotSelection);
          if(lastErrorCode != ERROR_NONE) {
            if(softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_HPLOT || softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_PLOT_LR || softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_HPLOT || softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_PLOT_STAT) {
              popSoftmenu();
              calcMode = CM_NORMAL;
              refreshScreen();
            }
          }
          hourGlassIconEnabled = false;
          showHideHourGlass();
          refreshStatusBar();
        }
        break;

      default: ;
    }

    #if !defined(DMCP_BUILD)
      refreshLcd(NULL);
    #endif // !DMCP_BUILD
  }
#endif // !TESTSUITE_BUILD


void fnSNAP(uint16_t unusedButMandatoryParameter) {
  #ifdef PC_BUILD
    printf("fnSNAP!\n");
  #endif
  if(calcMode == CM_AIM) {
    xcopy(tmpString, aimBuffer, ERROR_MESSAGE_LENGTH + AIM_BUFFER_LENGTH + NIM_BUFFER_LENGTH);       //backup portion of the "message buffer" area in DMCP used by ERROR..AIM..NIM buffers, to the tmpstring area in DMCP. DMCP uses this area during create_screenshot.
    fnScreenDump(0);
    xcopy(aimBuffer,tmpString, ERROR_MESSAGE_LENGTH + AIM_BUFFER_LENGTH + NIM_BUFFER_LENGTH);        //   This total area must be less than the tmpString storage area, which it is.
    fnP_Alpha();     //print alpha
  }
  else {
    fnScreenDump(0);
    fnP_All_Regs(1); //print stack
  }
}


void fnScreenDump(uint16_t unusedButMandatoryParameter) {
  #if defined(PC_BUILD)
    FILE *bmp;
    char bmpFileName[22];
    time_t rawTime;
    struct tm *timeInfo;
    int32_t x, y;
    uint32_t uint32;
    uint16_t uint16;
    uint8_t  uint8;

    time(&rawTime);
    timeInfo = localtime(&rawTime);

    strftime(bmpFileName, 22, "%Y%m%d-%H%M%S00.bmp", timeInfo);
    bmp = fopen(bmpFileName, "wb");

    fwrite("BM", 1, 2, bmp);        // Offset 0x00  0  BMP header

    uint32 = (SCREEN_WIDTH/8 * SCREEN_HEIGHT) + 610;
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x02  2  File size

    uint32 = 0;
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x06  6  unused

    uint32 = 0x00000082;
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x0a 10  Offset where the bitmap data can be found

    uint32 = 0x0000006c;
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x0e 14  Number of bytes in DIB header

    uint32 = SCREEN_WIDTH;
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x12 18  Bitmap width

    uint32 = SCREEN_HEIGHT;
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x16 22  Bitmap height

    uint16 = 0x0001;
    fwrite(&uint16, 1, 2, bmp);     // Offset 0x1a 26  Number of planes

    uint16 = 0x0001;
    fwrite(&uint16, 1, 2, bmp);     // Offset 0x1c 28  Number of bits per pixel

    uint32 = 0;
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x1e 30  Compression

    uint32 = 0x000030c0;
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x22 34  Size of bitmap data (including padding)

    uint32 = 0x00001a7c; // 6780 pixels/m
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x26 38  Horizontal print resolution

    uint32 = 0x00001a7c; // 6780 pixels/m
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x2a 42  Vertical print resolution

    uint32 = 0x00000002;
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x2e 46  Number of colors in the palette

    uint32 = 0x00000002;
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x32 50  Number of important colors

    uint32 = 0x73524742;
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x36  ???

    uint32 = 0;
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x3a  ???
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x3e  ???
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x42  ???
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x46  ???
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x4a  ???
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x4e  ???
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x52  ???
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x56  ???
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x5a  ???
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x5e  ???
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x62  ???
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x66  ???

    uint32 = 0x00000002;
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x6a  ???

    uint32 = 0;
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x6e  ???
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x72  ???
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x76  ???

    uint32 = 0x00dff5cc; // light green
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x7a  RGB color for 0

    uint32 = 0;
    fwrite(&uint32, 1, 4, bmp);     // Offset 0x7e  RGB color for 1

    // Offset 0x82  bit map data
    uint16 = 0;
    uint32 = 0;
    for(y=SCREEN_HEIGHT-1; y>=0; y--) {
      for(x=0; x<SCREEN_WIDTH; x++) {
        uint8 <<= 1;
        if(*(screenData + y*screenStride + x) == ON_PIXEL) {
          uint8 |= 1;
        }

        if((x % 8) == 7) {
          fwrite(&uint8, 1, 1, bmp);
          uint8 = 0;
        }
      }
      fwrite(&uint16, 1, 2, bmp); // Padding
    }


    fclose(bmp);
    screenUpdatingMode |= SCRUPD_SKIP_STACK_ONE_TIME | SCRUPD_SKIP_MENU_ONE_TIME;
  #endif // PC_BUILD

  #if defined(DMCP_BUILD)
    resetShiftState();                  //JM To avoid f or g top left of the screen, clear to make sure
    create_screenshot(0);
    screenUpdatingMode |= SCRUPD_SKIP_STACK_ONE_TIME | SCRUPD_SKIP_MENU_ONE_TIME;
  #endif // DMCP_BUILD
}


#if !defined(TESTSUITE_BUILD)
  static int32_t _getPositionFromRegister(calcRegister_t regist, int16_t maxValuePlusOne) {
    int32_t value;

    if(getRegisterDataType(regist) == dtReal34) {
      real34_t maxValue34;

      int32ToReal34(maxValuePlusOne, &maxValue34);
      if(real34CompareLessThan(REGISTER_REAL34_DATA(regist), const34_0) || real34CompareLessEqual(&maxValue34, REGISTER_REAL34_DATA(regist))) {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        #if defined(PC_BUILD)
          real34ToString(REGISTER_REAL34_DATA(regist), errorMessage);
          sprintf(tmpString, "x %" PRId16 " = %s:", regist, errorMessage);
          moreInfoOnError("In function _getPositionFromRegister:", tmpString, "this value is negative or too big!", NULL);
        #endif // PC_BUILD
        return -1;
      }
      value = real34ToInt32(REGISTER_REAL34_DATA(regist));
    }

    else if(getRegisterDataType(regist) == dtLongInteger) {
      longInteger_t lgInt;

      convertLongIntegerRegisterToLongInteger(regist, lgInt);
      if(longIntegerCompareUInt(lgInt, 0) < 0 || longIntegerCompareUInt(lgInt, maxValuePlusOne) >= 0) {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        #if defined(PC_BUILD)
          longIntegerToAllocatedString(lgInt, errorMessage, ERROR_MESSAGE_LENGTH);
          sprintf(tmpString, "register %" PRId16 " = %s:", regist, errorMessage);
          moreInfoOnError("In function _getPositionFromRegister:", tmpString, "this value is negative or too big!", NULL);
        #endif // PC_BUILD
        longIntegerFree(lgInt);
        return -1;
      }
      longIntegerToUInt(lgInt, value);
      longIntegerFree(lgInt);
    }

    else {
      displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
      #if defined(PC_BUILD)
        sprintf(errorMessage, "register %" PRId16 " is %s:", regist, getRegisterDataTypeName(regist, true, false));
        moreInfoOnError("In function _getPositionFromRegister:", errorMessage, "not suited for addressing!", NULL);
      #endif // PC_BUILD
      return -1;
    }

    return value;
  }

  static void getPixelPos(int32_t *x, int32_t *y) {
    *x = _getPositionFromRegister(REGISTER_X, SCREEN_WIDTH);
    *y = _getPositionFromRegister(REGISTER_Y, SCREEN_HEIGHT);
  }
#endif // !TESTSUITE_BUILD

void fnClLcd(uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
    int32_t x, y;
    getPixelPos(&x, &y);
    if(lastErrorCode == ERROR_NONE) {
      screenUpdatingMode |= SCRUPD_MANUAL_STATUSBAR | SCRUPD_MANUAL_STACK | SCRUPD_MANUAL_MENU | SCRUPD_MANUAL_SHIFT_STATUS;
      lcd_fill_rect(x, 0, SCREEN_WIDTH - x, SCREEN_HEIGHT - y, LCD_SET_VALUE);
    }
  #endif // !TESTSUITE_BUILD
}


void fnPixel(uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
    int32_t x, y;
    getPixelPos(&x, &y);
    if(lastErrorCode == ERROR_NONE) {
      screenUpdatingMode |= SCRUPD_MANUAL_STACK | SCRUPD_MANUAL_MENU | SCRUPD_MANUAL_SHIFT_STATUS;
        if((SCREEN_HEIGHT - y - 1) <= Y_POSITION_OF_REGISTER_T_LINE) {
          screenUpdatingMode |= SCRUPD_MANUAL_STATUSBAR;
        }
      setBlackPixel(x, SCREEN_HEIGHT - y - 1);
    }
  #endif // !TESTSUITE_BUILD
}

void fnPoint(uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
    int32_t x, y;
    getPixelPos(&x, &y);
    if(lastErrorCode == ERROR_NONE) {
      screenUpdatingMode |= SCRUPD_MANUAL_STACK | SCRUPD_MANUAL_MENU | SCRUPD_MANUAL_SHIFT_STATUS;
      if((SCREEN_HEIGHT - y - 2) <= Y_POSITION_OF_REGISTER_T_LINE) {
        screenUpdatingMode |= SCRUPD_MANUAL_STATUSBAR;
      }
      lcd_fill_rect(x - 1, SCREEN_HEIGHT - y - 2, 3, 3, LCD_EMPTY_VALUE);
    }
  #endif // !TESTSUITE_BUILD
}

void fnAGraph(uint16_t regist) {
  #if !defined(TESTSUITE_BUILD)
    int32_t x, y;
    uint32_t gramod;
    longInteger_t liGramod;
    getPixelPos(&x, &y);
    convertLongIntegerRegisterToLongInteger(RESERVED_VARIABLE_GRAMOD, liGramod);
    longIntegerToUInt(liGramod, gramod);
    longIntegerFree(liGramod);
    if(lastErrorCode == ERROR_NONE) {
      if(getRegisterDataType(regist) == dtShortInteger) {
        uint64_t val;
        int16_t sign;
        const uint8_t savedShortIntegerMode = shortIntegerMode;

        screenUpdatingMode |= SCRUPD_MANUAL_STACK | SCRUPD_MANUAL_MENU | SCRUPD_MANUAL_SHIFT_STATUS;
        if((SCREEN_HEIGHT - y - 1 - (int)shortIntegerWordSize) <= Y_POSITION_OF_REGISTER_T_LINE) {
          screenUpdatingMode |= SCRUPD_MANUAL_STATUSBAR;
        }
        shortIntegerMode = SIM_UNSIGN;
        convertShortIntegerRegisterToUInt64(regist, &sign, &val);
        shortIntegerMode = savedShortIntegerMode;
        for(uint32_t i = 0; i < shortIntegerWordSize; ++i) {
          switch(gramod) {
            case 1: if(!(val & 1)) setWhitePixel(x, SCREEN_HEIGHT - y - 1 - i); /* fallthrough */
            case 0: if(val & 1)    setBlackPixel(x, SCREEN_HEIGHT - y - 1 - i); break;
            case 2: if(val & 1)    setWhitePixel(x, SCREEN_HEIGHT - y - 1 - i); break;
            case 3: if(val & 1)    flipPixel(x, SCREEN_HEIGHT - y - 1 - i);     break;
          }
          val >>= 1;
        }

        fnInc(REGISTER_X);
      }

      else {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        #if defined(PC_BUILD)
          sprintf(errorMessage, "register %" PRId16 " is %s:", regist, getRegisterDataTypeName(regist, true, false));
          moreInfoOnError("In function fnAGraph:", errorMessage, "not suited for addressing!", NULL);
        #endif // PC_BUILD
      }
    }
  #endif // !TESTSUITE_BUILD
}


#if !defined(TESTSUITE_BUILD)
  void clearScreen_old(bool_t clearStatusBar, bool_t clearRegisterLines, bool_t clearSoftkeys) {      //JMOLD
    if(clearStatusBar) {
      lcd_fill_rect(0, 0, SCREEN_WIDTH, 20, 0);
    }
    if(clearRegisterLines) {
      lcd_fill_rect(0, 20, SCREEN_WIDTH, 151, 0);
    }
    if(clearSoftkeys) {
      clear_ul(); //JMUL
      lcd_fill_rect(0, 171, SCREEN_WIDTH, 69, 0);
      lcd_fill_rect(0, 171-5, 20, 5, 0);
    }
  }                                                       //JM ^^
#endif // !TESTSUITE_BUILD
