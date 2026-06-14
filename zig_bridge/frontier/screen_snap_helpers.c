// SPDX-License-Identifier: GPL-3.0-only
//
// Residual C helpers for the Zig screen owner (frontier_screen_owned.zig).
//
// 1. The fnSNAP screenshot/printer backup helpers. fnSNAP itself is owned by
//    frontier.zig; these three helpers must stay in C because they call the
//    DMCP-ROM standardScreenDump() (firmware) / the message-buffer xcopy dance
//    around fnScreenDump() (host), and back up/restore the TAM buffer.
//
// 2. The three version strings (versionStr, versionStr2) that embed VERSION_STRING
//    (the generated VCS commit id) and __DATE__ — values produced by the C
//    preprocessor / build system that cannot be reproduced byte-faithfully in
//    pure Zig. They are file-local in upstream screen.c and only feed the
//    TI_VERSION / TI_BACKUP_RESTORED render branches, so they are exported here
//    with C linkage for the Zig owner to reference.

#include "c47.h"
#include "version.h"

// --- version strings (generation-dependent: VCS id + compile __DATE__) -------
#if (CALCMODEL == USER_R47)
  #define MODELTEXT "R47"
#else
  #define MODELTEXT "C47"
#endif

const char versionStr[]  = "  " MODELTEXT " " VERSION_STRING ".";

#if defined(PC_BUILD)
  const char versionStr2[] = "  " MODELTEXT " Sim " VERSION1 ", dated " __DATE__ ".";
#else // !PC_BUILD
  #if defined(TWO_FILE_PGM)
    const char versionStr2[] = "  " MODELTEXT " QSPI " VERSION1 ", dated " __DATE__ ".";
  #else // !TWO_FILE_PGM
    const char versionStr2[] = "  " MODELTEXT " No QSPI " VERSION1 ", dated " __DATE__ ".";
  #endif // TWO_FILE_PGM
#endif // PC_BUILD

// --- fnSNAP backup helpers (call into DMCP ROM / message-buffer area) ---------
void z47_frontier_snap_screenshot_with_message_backup(void) {
#if defined(PC_BUILD)
	xcopy(tmpString, errorMessage, ERROR_MESSAGE_LENGTH + AIM_BUFFER_LENGTH + NIM_BUFFER_LENGTH + TAM_BUFFER_LENGTH);
	fnScreenDump(0);
	xcopy(errorMessage, tmpString, ERROR_MESSAGE_LENGTH + AIM_BUFFER_LENGTH + NIM_BUFFER_LENGTH + TAM_BUFFER_LENGTH);
#elif defined(DMCP_BUILD)
	standardScreenDump();
#endif
}

void z47_frontier_snap_backup_tam(uint8_t *dst) {
	xcopy(dst, tamBuffer, TAM_BUFFER_LENGTH);
}

void z47_frontier_snap_restore_tam(const uint8_t *src) {
	xcopy(tamBuffer, src, TAM_BUFFER_LENGTH);
}

// ===========================================================================
// Host-only (and host/DMCP) clipboard + cairo helpers, lifted verbatim from
// upstream screen.c. These bind the GTK clipboard / cairo surface / gdk-pixbuf
// APIs (drawScreen, copy*ToClipboard) and copyRegisterToClipboardString (called
// by 3 other C units). Kept in C to avoid binding the entire GTK/cairo surface
// API in Zig; they are PC_BUILD-only (or PC_BUILD||DMCP_BUILD) UI helpers.
// ===========================================================================
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
  void copyMenuToClipboard(void) {
    cairo_surface_t *imageSurface;
    GtkClipboard *clipboard;

    clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
    gtk_clipboard_clear(clipboard);
    gtk_clipboard_set_text(clipboard, "", 0); //JM FOUND TIP TO PROPERLY CLEAR CLIPBOARD: https://stackoverflow.com/questions/2418487/clear-the-system-clipboard-using-the-gtk-lib-in-c/2419673#2419673

    imageSurface = cairo_image_surface_create_for_data((unsigned char *)screenData, CAIRO_FORMAT_RGB24, SCREEN_WIDTH, SCREEN_HEIGHT-170, screenStride * 4);
    gtk_clipboard_set_image(clipboard, gdk_pixbuf_get_from_surface(imageSurface, 0, 170, SCREEN_WIDTH, SCREEN_HEIGHT-170));
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

  void copyRegisterToClipboardString(calcRegister_t regist, char *clipboardString, bool_t forPrinter) {
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
        COPY_REGISTER_STRING_TO(string,    regist);
        break;

      case dtReal34Matrix: {
        matrixHeader_t *matrixHeader = REGISTER_MATRIX_HEADER(regist);
        real34_t *real34 = REGISTER_REAL34_MATRIX_ELEMENTS(regist);
        real34_t reduced;
        uint32_t rows, columns, len;

        rows = matrixHeader->matrixRows;
        columns = matrixHeader->matrixColumns;
        sprintf(string, "%" PRIu32 "x%" PRIu32, rows, columns);

        for(uint32_t i=0; i<rows*columns; i++) {
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
        matrixHeader_t *matrixHeader = REGISTER_MATRIX_HEADER(regist);
        complex34_t *complex34 = REGISTER_COMPLEX34_MATRIX_ELEMENTS(regist);
        real34_t reduced;
        uint32_t rows, columns, len;

        rows = matrixHeader->matrixRows;
        columns = matrixHeader->matrixColumns;
        sprintf(string, "%" PRIu32 "x%" PRIu32, rows, columns);

        for(uint32_t i=0; i<rows*columns; i++, complex34++) {
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
        if(forPrinter) {
          sprintf(errorMessage + n--, "#%d", base);
        }
        else {
          sprintf(errorMessage + n--, "#%d (word size = %u)", base, shortIntegerWordSize);
        }

        if(shortInt == 0) {
          errorMessage[n--] = '0';
        }
        else {
          while(shortInt != 0) {
            errorMessage[n--] = baseDigits[shortInt % base];
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
        if(forPrinter) {
          xcopy(string, "Config. data", 13);
        }
        else {
          xcopy(string, "Configuration data", 19);
        }


        break;

      default:
        sprintf(string, "In function copyRegisterXToClipboard, the data type %" PRIu32 " is unknown! Please try to reproduce and submit a bug.", getRegisterDataType(regist));
    }

    if(forPrinter) {
      strcpy(clipboardString, string);
    }
    else {
      stringToUtf8(string, (uint8_t *)clipboardString);
    }
  }
#endif // PC_BUILD || DMCP_BUILD                              //JMCSV

#define checkHPoffset (checkHP && temporaryInformation == TI_NO_INFO ? 50 : 0)

char letteredRegisterName(calcRegister_t regist) {
  return registerFlagLetters[regist - FIRST_LETTERED_REGISTER];
}


#if defined(PC_BUILD)                                         //JMCSV
  void copyRegisterXToClipboard(void) {
    GtkClipboard *clipboard;
    char clipboardString[CLIPSTR];

    clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
    gtk_clipboard_clear(clipboard);
    gtk_clipboard_set_text(clipboard, "", 0); //JM FOUND TIP TO PROPERLY CLEAR CLIPBOARD: https://stackoverflow.com/questions/2418487/clear-the-system-clipboard-using-the-gtk-lib-in-c/2419673#2419673

    copyRegisterToClipboardString(REGISTER_X, clipboardString, false);
    gtk_clipboard_set_text(clipboard, clipboardString, -1);
  }


  void copyStackRegistersToClipboardString(char *clipboardString, calcRegister_t lastRegist) {
    char *ptr = clipboardString;
    const char *sep = "";

    for(calcRegister_t r = lastRegist; r >= REGISTER_X; r--) {
      ptr += sprintf(ptr, "%s%c = ", sep, letteredRegisterName(r));
      copyRegisterToClipboardString(r, ptr, false);
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

    copyStackRegistersToClipboardString(clipboardString, REGISTER_K);

    gtk_clipboard_set_text(clipboard, clipboardString, -1);
  }


  void copyAllRegistersToClipboard(void) {
    GtkClipboard *clipboard;
    char clipboardString[15000], *ptr = clipboardString;

    clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
    gtk_clipboard_clear(clipboard);
    gtk_clipboard_set_text(clipboard, "", 0); //JM FOUND TIP TO PROPERLY CLEAR CLIPBOARD: https://stackoverflow.com/questions/2418487/clear-the-system-clipboard-using-the-gtk-lib-in-c/2419673#2419673

    copyStackRegistersToClipboardString(ptr, LAST_SPARE_REGISTER);

    for(int32_t regist=99; regist>=0; --regist) {
      ptr += strlen(ptr);
      sprintf(ptr, LINEBREAK "R%02d = ", regist);
      ptr += strlen(ptr);
      copyRegisterToClipboardString(regist, ptr, false);
    }

    for(int32_t regist=currentNumberOfLocalRegisters-1; regist>=0; --regist) {
      ptr += strlen(ptr);
      sprintf(ptr, LINEBREAK "R.%02d = ", regist);
      ptr += strlen(ptr);
      copyRegisterToClipboardString(FIRST_LOCAL_REGISTER + regist, ptr, false);
    }

    if(statisticalSumsPointer != NULL) {
      TO_QSPI const char * const StatSumNames[NUMBER_OF_STATISTICAL_SUMS] = {
        /* 0*/ "n             ",
        /* 1*/ STD_SIGMA "(x)          ",
        /* 2*/ STD_SIGMA "(y)          ",
        /* 3*/ STD_SIGMA "(x" STD_SUP_2 ")         ",
        /* 4*/ STD_SIGMA "(x" STD_SUP_2 "y)        ",
        /* 5*/ STD_SIGMA "(y" STD_SUP_2 ")         ",
        /* 6*/ STD_SIGMA "(xy)         ",
        /* 7*/ STD_SIGMA "(ln(x)" STD_CROSS "ln(y))",
        /* 8*/ STD_SIGMA "(ln(x))      ",
        /* 9*/ STD_SIGMA "(ln" STD_SUP_2 "(x))     ",
        /*10*/ STD_SIGMA "(y ln(x))    ",
        /*11*/ STD_SIGMA "(ln(y))      ",
        /*12*/ STD_SIGMA "(ln" STD_SUP_2 "(y))     ",
        /*13*/ STD_SIGMA "(x ln(y))    ",
        /*14*/ STD_SIGMA "(ln(y)/x)    ",
        /*15*/ STD_SIGMA "(x" STD_SUP_2 "/y)       ",
        /*16*/ STD_SIGMA "(1/x)        ",
        /*17*/ STD_SIGMA "(1/x" STD_SUP_2 ")       ",
        /*18*/ STD_SIGMA "(x/y)        ",
        /*19*/ STD_SIGMA "(1/y)        ",
        /*20*/ STD_SIGMA "(1/y" STD_SUP_2 ")       ",
        /*21*/ STD_SIGMA "(x" STD_SUP_3 ")         ",
        /*22*/ STD_SIGMA "(x" STD_SUP_4 ")         ",
        /*23*/ "x min         ",
        /*24*/ "x max         ",
        /*25*/ "y min         ",
        /*26*/ "y max         "
      };

      char sumName[40];
      for(int32_t sum=0; sum<NUMBER_OF_STATISTICAL_SUMS; sum++) {
        ptr += strlen(ptr);
        strcpy(sumName, StatSumNames[sum]);

        sprintf(ptr, LINEBREAK "SR%02d = ", sum);
        ptr += strlen(ptr);
        stringToUtf8(sumName, (uint8_t *)ptr);
        ptr += strlen(ptr);
        strcpy(ptr, " = ");
        ptr += strlen(ptr);
        realToString(statisticalSumsPointer + sum, tmpString);
        if(strchr(tmpString, '.') == NULL && strchr(tmpString, 'E') == NULL) {
          strcat(tmpString, ".");
        }
        strcpy(ptr, tmpString);
      }
    }

    gtk_clipboard_set_text(clipboard, clipboardString, -1);
  }
#endif // PC_BUILD
