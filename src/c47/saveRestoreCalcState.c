// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors


#include "saveRestoreCalcState.h"

#include "assign.h"
#include "charString.h"
#include "config.h"
#include "display.h"
#include "error.h"
#include "flags.h"
#include "hal/gui.h"
#include "hal/io.h"
#include "items.h"
#include "c43Extensions/addons.h"
#include "c43Extensions/graphText.h"
#include "c43Extensions/xeqm.h"
#include "c43Extensions/jm.h"
#include "c43Extensions/radioButtonCatalog.h"
#include "curveFitting.h"
#include "dateTime.h"
#include "mathematics/matrix.h"
#include "memory.h"
#include "plotstat.h"
#include "programming/lblGtoXeq.h"
#include "programming/manage.h"
#include "programming/nextStep.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "screen.h"
#include "softmenus.h"
#include "solver/equation.h"
#include "solver/graph.h"
#include "statusBar.h"
#include "stack.h"
#include "sort.h"
#include "stats.h"
#include "timer.h"
#include <string.h>

#if defined(PC_BUILD)
#include <gtk/gtk.h>
#include <stdbool.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <sys/stat.h>
#endif

#if defined(DMCP_BUILD)
#include <dmcp.h>
#endif

#include "c47.h"
#define configFileVersion                  10000012 // 5 flags converted from C43; Arbitrary starting point version 10 000 001 of STATE files. Allowable values are 10000000 to 20000000
#define BACKUP_VERSION                     1003  // 5 flags converted from C43;
#define VersionAllowed                     10000005 // This code will not autoload versions earlier than this

/*
10000001 // arbitrary starting point version 10 000 001
10000002 // 2022-12-05 First release, version 108_08f
10000003 // 2022-12-06 version 108_08h, added LongPressM & LongPressF
10000004 // 2022-12-26 version 108_08n, added lastIntegerBase
10000005 // 2022-01-08 version 108_08q, Pauli changed the real number saver representaiton
...
10000008 // 2023-09-12 version 108.13   Jaco added the missing STOCFG items, remove the unneccary STOCFG items, added the missing STATe file items.

Current version defaults all non-loaded settings from previous version files correctly
*/

uint16_t flushBufferCnt = 0;
#if !defined(TESTSUITE_BUILD)
  #define START_REGISTER_VALUE 1000  // was 1522, why?
  static uint32_t loadedVersion = 0;
  static char *tmpRegisterString = NULL;

  static void save(const void *buffer, uint32_t size) {
    ioFileWrite(buffer, size);
  }

  static uint32_t restore(void *buffer, uint32_t size) {
    return ioFileRead(buffer, size);
  }
#endif // !TESTSUITE_BUILD



#if defined(PC_BUILD)
  cfgFileParam_t *paramHead=NULL, *paramCurrent;

  static void changeCommaToPeriod(char *str) {
    char *s;

    s = strchr(str, ':') + 1;
    s = strchr(s, ':') + 1;
    while(*s) {
      if(*s == ',') {
        *s = '.';
      }
      s++;
    }
  }

  static void saveStateValue(const void *buffer, uint32_t size, const char *valueName, const char *valueType) {
    char value[200];

    if(!strcmp(valueType, "int64")) {
      sprintf(value, "%s:%s:%" PRIi64 LINEBREAK, valueName, valueType, *(int64_t *)buffer);
      save(value, strlen(value));
    }

    else if(!strcmp(valueType, "uint64")) {
      sprintf(value, "%s:%s:%" PRIu64 LINEBREAK, valueName, valueType, *(uint64_t *)buffer);
      save(value, strlen(value));
    }

    else if(!strcmp(valueType, "int32")) {
      sprintf(value, "%s:%s:%" PRIi32 LINEBREAK, valueName, valueType, *(int32_t *)buffer);
      save(value, strlen(value));
    }

    else if(!strcmp(valueType, "uint32")) {
      sprintf(value, "%s:%s:%" PRIu32 LINEBREAK, valueName, valueType, *(uint32_t *)buffer);
      save(value, strlen(value));
    }

    else if(!strcmp(valueType, "int16")) {
      sprintf(value, "%s:%s:%" PRIi16 LINEBREAK, valueName, valueType, *(int16_t *)buffer);
      save(value, strlen(value));
    }

    else if(!strcmp(valueType, "uint16")) {
      sprintf(value, "%s:%s:%" PRIu16 LINEBREAK, valueName, valueType, *(uint16_t *)buffer);
      save(value, strlen(value));
    }

    else if(!strcmp(valueType, "int8")) {
      sprintf(value, "%s:%s:%" PRIi8 LINEBREAK, valueName, valueType, *(int8_t *)buffer);
      save(value, strlen(value));
    }

    else if(!strcmp(valueType, "uint8")) {
      sprintf(value, "%s:%s:%" PRIu8 LINEBREAK, valueName, valueType, *(uint8_t *)buffer);
      save(value, strlen(value));
    }

    else if(!strcmp(valueType, "float")) {
      sprintf(value, "%s:%s:%.20e" LINEBREAK, valueName, valueType, *(float *)buffer);
      changeCommaToPeriod(value);
      save(value, strlen(value));
    }

    else if(!strcmp(valueType, "double")) {
      sprintf(value, "%s:%s:%.20e" LINEBREAK, valueName, valueType, *(double *)buffer);
      changeCommaToPeriod(value);
      save(value, strlen(value));
    }

    else if(!strcmp(valueType, "real")) {
      sprintf(value, "%s:%s:", valueName, valueType);
      if(realIsInfinite((real_t *)buffer)) {
        if(realIsNegative((real_t *)buffer)) {
          strcpy(value + strlen(value), "-9.9e9999999");
        }
        else {
          strcpy(value + strlen(value), "9.9e9999999");
        }
      }
      else {
        realToString(buffer, value + strlen(value));
      }
      strcat(value, LINEBREAK);
      changeCommaToPeriod(value);
      save(value, strlen(value));
    }

    else if(!strcmp(valueType, "real34")) {
      sprintf(value, "%s:%s:", valueName, valueType);
      if(real34IsInfinite((real34_t *)buffer)) {
        if(real34IsNegative((real34_t *)buffer)) {
          strcpy(value + strlen(value), "-9.9e9999");
        }
        else {
          strcpy(value + strlen(value), "9.9e9999");
        }
      }
      else {
        real34ToString(buffer, value + strlen(value));
      }
      strcat(value, LINEBREAK);
      changeCommaToPeriod(value);
      save(value, strlen(value));
    }

    else if(!strcmp(valueType, "bool")) {
      sprintf(value, "%s:%s:%" PRIu32 LINEBREAK, valueName, valueType, *(bool_t *)buffer);
      save(value, strlen(value));
    }

    else if(!strcmp(valueType, "c47Ptr")) {
      sprintf(value, "%s:%s:%" PRIu32 " (0x%05x)" LINEBREAK, valueName, valueType, *(uint32_t *)buffer, 4 * *(uint32_t *)buffer);
      save(value, strlen(value));
    }

    else if(!strcmp(valueType, "hexDump")) {
      uint32_t addr, b;

      sprintf(value, "%s:%s:%" PRIu32 LINEBREAK, valueName, valueType, size);
      save(value, strlen(value));

      for(addr=0; addr<size; addr+=32) {
        // Hexadecimal dump
        sprintf(value, "%05x  ", addr);
        for(b=0; b<32; b++) {
          if(addr + b < size) {
            sprintf(value + 7 + 3*b, "%02x ", *(uint8_t *)(buffer + addr + b));
          }
          else {
            strcpy(value + 7 + 3*b, "   ");
          }
        }

        // ASCII dump
        strcpy(value + 103, " '");
        for(b=0; b<32; b++) {
          if(addr + b < size) {
            sprintf(value + 105 + b, "%c", *(char *)(buffer + addr + b) >= ' ' && *(char *)(buffer + addr + b) != 0x7f ? *(char *)(buffer + addr + b) : ' ');
          }
          else {
            strcpy(value + 105 + b, " ");
          }
        }
        strcpy(value + 137, "'" LINEBREAK);

        save(value, strlen(value));
      }
    }

    //save and restore screenData is not mandatory
    //else if(!strcmp(valueType, "screenData")) {
    //  char screenRow[401];
    //  screenRow[400] = 0;
    //
    //  sprintf(value, "%s:%s:%dx%d" LINEBREAK, valueName, valueType, SCREEN_WIDTH, SCREEN_HEIGHT);
    //  save(value, strlen(value));
    //
    //  uint32_t addr=0;
    //  for(int y = 0; y < SCREEN_HEIGHT; ++y) {
    //    uint8_t bmpdata = 0;
    //    for(int x = 0; x < SCREEN_WIDTH; ++x) {
    //      bmpdata <<= 1;
    //      if(*((uint32_t *)buffer + y*screenStride + x) == ON_PIXEL) {
    //        bmpdata |= 1;
    //        screenRow[x] = '#';
    //      }
    //      else {
    //        screenRow[x] = ' ';
    //      }
    //      if((x % 8) == 7) {
    //        if(++addr % 50 == 0) {
    //          sprintf(value, "%s|" LINEBREAK, screenRow);
    //          save(value, strlen(value));
    //        }
    //        bmpdata = 0;
    //      }
    //    }
    //  }
    //}

    else {
      printf("ERROR: valueType %s unknown in function saveStateValue!" LINEBREAK, valueType);
    }
  }

  void saveCalc(void) {
    uint32_t ramSizeInBlocks = RAM_SIZE_IN_BLOCKS;
    uint32_t ramPtr, backupVersion = BACKUP_VERSION;
    int ret;

    ret = ioFileOpen(ioPathBackup, ioModeWrite);

    if(ret != FILE_OK) {
      if(ret == FILE_CANCEL) {
        return;
      }
      else {
        printf("Cannot save calc's memory in file backup.bin!\n");
        exit(0);
      }
    }

    if(calcMode == CM_CONFIRMATION) {
      calcMode = previousCalcMode;
      refreshScreen(90);
    }

    printf("Begin of calc's backup\n");

    // The order in which parameters are saved doesn't matter
    // When a parameter is removed, simply remove the corresponding saveStateValue(...) and restoreStateValue(...) lines.
    saveStateValue(&backupVersion,                  sizeof(backupVersion),                                       "backupVersion",                  "uint32");
    saveStateValue(&ramSizeInBlocks,                sizeof(ramSizeInBlocks),                                     "ramSizeInBlocks",                "uint32");
    saveStateValue(&numberOfFreeMemoryRegions,      sizeof(numberOfFreeMemoryRegions),                           "numberOfFreeMemoryRegions",      "int32");
    saveStateValue(freeMemoryRegions,               sizeof(freeMemoryRegion_t) * numberOfFreeMemoryRegions,      "freeMemoryRegions",              "hexDump");
    saveStateValue(&numberOfAllocatedMemoryRegions, sizeof(numberOfAllocatedMemoryRegions),                      "numberOfAllocatedMemoryRegions", "int32");
    saveStateValue(allocatedMemoryRegions,          sizeof(freeMemoryRegion_t) * numberOfAllocatedMemoryRegions, "allocatedMemoryRegions",         "hexDump");
    saveStateValue(globalFlags,                     sizeof(globalFlags),                                         "globalFlags",                    "hexDump");
    saveStateValue(errorMessage,                    ERROR_MESSAGE_LENGTH,                                        "errorMessage",                   "hexDump");
    saveStateValue(aimBuffer,                       AIM_BUFFER_LENGTH,                                           "aimBuffer",                      "hexDump");
    saveStateValue(nimBufferDisplay,                NIM_BUFFER_LENGTH,                                           "nimBufferDisplay",               "hexDump");
    saveStateValue(tamBuffer,                       TAM_BUFFER_LENGTH,                                           "tamBuffer",                      "hexDump");
    saveStateValue(asmBuffer,                       sizeof(asmBuffer),                                           "asmBuffer",                      "hexDump");
    saveStateValue(oldTime,                         sizeof(oldTime),                                             "oldTime",                        "hexDump");
    saveStateValue(dateTimeString,                  sizeof(dateTimeString),                                      "dateTimeString",                 "hexDump");
    saveStateValue(softmenuStack,                   sizeof(softmenuStack),                                       "softmenuStack",                  "hexDump");
    saveStateValue(globalRegister,                  sizeof(globalRegister),                                      "globalRegister",                 "hexDump");
    saveStateValue(kbd_usr,                         sizeof(kbd_usr),                                             "kbd_usr",                        "hexDump");
    saveStateValue(userMenuItems,                   sizeof(userMenuItems),                                       "userMenuItems",                  "hexDump");
    saveStateValue(userAlphaItems,                  sizeof(userAlphaItems),                                      "userAlphaItems",                 "hexDump");
    saveStateValue(&tam.mode,                       sizeof(tam.mode),                                            "tam.mode",                       "uint16");
    saveStateValue(&tam.function,                   sizeof(tam.function),                                        "tam.function",                   "int16");
    saveStateValue(&tam.alpha,                      sizeof(tam.alpha),                                           "tam.alpha",                      "bool");
    saveStateValue(&tam.currentOperation,           sizeof(tam.currentOperation),                                "tam.currentOperation",           "int16");
    saveStateValue(&tam.dot,                        sizeof(tam.dot),                                             "tam.dot",                        "bool");
    saveStateValue(&tam.indirect,                   sizeof(tam.indirect),                                        "tam.indirect",                   "bool");
    saveStateValue(&tam.digitsSoFar,                sizeof(tam.digitsSoFar),                                     "tam.digitsSoFar",                "int16");
    saveStateValue(&tam.value,                      sizeof(tam.value),                                           "tam.value",                      "int16");
    saveStateValue(&tam.min,                        sizeof(tam.min),                                             "tam.min",                        "int16");
    saveStateValue(&tam.max,                        sizeof(tam.max),                                             "tam.max",                        "int16");
    saveStateValue(&rbrRegister,                    sizeof(rbrRegister),                                         "rbrRegister",                    "int16");
    saveStateValue(&numberOfNamedVariables,         sizeof(numberOfNamedVariables),                              "numberOfNamedVariables",         "int16");
    saveStateValue(&xCursor,                        sizeof(xCursor),                                             "xCursor",                        "uint32");
    saveStateValue(&yCursor,                        sizeof(yCursor),                                             "yCursor",                        "uint32");
    saveStateValue(&firstGregorianDay,              sizeof(firstGregorianDay),                                   "firstGregorianDay",              "uint32");
    saveStateValue(&denMax,                         sizeof(denMax),                                              "denMax",                         "uint32");
    saveStateValue(&lastDenominator,                sizeof(lastDenominator),                                     "lastDenominator",                "uint32");
    saveStateValue(&currentRegisterBrowserScreen,   sizeof(currentRegisterBrowserScreen),                        "currentRegisterBrowserScreen",   "int16");
    saveStateValue(&currentFntScr,                  sizeof(currentFntScr),                                       "currentFntScr",                  "uint8");
    saveStateValue(&currentFlgScr,                  sizeof(currentFlgScr),                                       "currentFlgScr",                  "uint8");
    saveStateValue(&displayFormat,                  sizeof(displayFormat),                                       "displayFormat",                  "uint8");
    saveStateValue(&displayFormatDigits,            sizeof(displayFormatDigits),                                 "displayFormatDigits",            "uint8");
    saveStateValue(&timeDisplayFormatDigits,        sizeof(timeDisplayFormatDigits),                             "timeDisplayFormatDigits",        "uint8");
    saveStateValue(&shortIntegerWordSize,           sizeof(shortIntegerWordSize),                                "shortIntegerWordSize",           "uint8");
    saveStateValue(&significantDigits,              sizeof(significantDigits),                                   "significantDigits",              "uint8");
    saveStateValue(&fractionDigits,                 sizeof(fractionDigits),                                      "fractionDigits",                 "uint8");
    saveStateValue(&shortIntegerMode,               sizeof(shortIntegerMode),                                    "shortIntegerMode",               "uint8");
    saveStateValue(&currentAngularMode,             sizeof(currentAngularMode),                                  "currentAngularMode",             "uint32");
    saveStateValue(&scrLock,                        sizeof(scrLock),                                             "scrLock",                        "uint8");
    saveStateValue(&roundingMode,                   sizeof(roundingMode),                                        "roundingMode",                   "uint8");
    saveStateValue(&calcMode,                       sizeof(calcMode),                                            "calcMode",                       "uint8");
    saveStateValue(&nextChar,                       sizeof(nextChar),                                            "nextChar",                       "uint8");
    saveStateValue(&alphaCase,                      sizeof(alphaCase),                                           "alphaCase",                      "uint8");
    saveStateValue(&hourGlassIconEnabled,           sizeof(hourGlassIconEnabled),                                "hourGlassIconEnabled",           "bool");
    saveStateValue(&watchIconEnabled,               sizeof(watchIconEnabled),                                    "watchIconEnabled",               "bool");
    saveStateValue(&serialIOIconEnabled,            sizeof(serialIOIconEnabled),                                 "serialIOIconEnabled",            "bool");
    saveStateValue(&printerIconEnabled,             sizeof(printerIconEnabled),                                  "printerIconEnabled",             "bool");
    saveStateValue(&programRunStop,                 sizeof(programRunStop),                                      "programRunStop",                 "uint8");
    saveStateValue(&entryStatus,                    sizeof(entryStatus),                                         "entryStatus",                    "uint8");
    saveStateValue(&cursorEnabled,                  sizeof(cursorEnabled),                                       "cursorEnabled",                  "uint8");

    int8_t cf;
         if(cursorFont == &tinyFont)     cf =  1;
    else if(cursorFont == &standardFont) cf =  2;
    else if(cursorFont == &numericFont)  cf =  3;
    else                                 cf = -1;
    saveStateValue(&cf,                             sizeof(cf),                                                  "cursorFont",                     "int8");

    saveStateValue(&rbr1stDigit,                    sizeof(rbr1stDigit),                                         "rbr1stDigit",                    "bool");
    saveStateValue(&shiftF,                         sizeof(shiftF),                                              "shiftF",                         "bool");
    saveStateValue(&shiftG,                         sizeof(shiftG),                                              "shiftG",                         "bool");
    saveStateValue(&rbrMode,                        sizeof(rbrMode),                                             "rbrMode",                        "uint8");
    saveStateValue(&showContent,                    sizeof(showContent),                                         "showContent",                    "bool");
    saveStateValue(&numScreensNumericFont,          sizeof(numScreensNumericFont),                               "numScreensNumericFont",          "uint8");
    saveStateValue(&numLinesNumericFont,            sizeof(numLinesNumericFont),                                 "numLinesNumericFont",            "uint8");
    saveStateValue(&numScreensStandardFont,         sizeof(numScreensStandardFont),                              "numScreensStandardFont",         "uint8");
    saveStateValue(&numLinesStandardFont,           sizeof(numLinesStandardFont),                                "numLinesStandardFont",           "uint8");
    saveStateValue(&numScreensTinyFont,             sizeof(numScreensTinyFont),                                  "numScreensTinyFont",             "uint8");
    saveStateValue(&numLinesTinyFont,               sizeof(numLinesTinyFont),                                    "numLinesTinyFont",               "uint8");
    saveStateValue(&previousCalcMode,               sizeof(previousCalcMode),                                    "previousCalcMode",               "uint8");
    saveStateValue(&lastErrorCode,                  sizeof(lastErrorCode),                                       "lastErrorCode",                  "uint8");
    saveStateValue(&nimNumberPart,                  sizeof(nimNumberPart),                                       "nimNumberPart",                  "uint8");
    saveStateValue(&displayStack,                   sizeof(displayStack),                                        "displayStack",                   "uint8");
    saveStateValue(&hexDigits,                      sizeof(hexDigits),                                           "hexDigits",                      "uint8");
    saveStateValue(&errorMessageRegisterLine,       sizeof(errorMessageRegisterLine),                            "errorMessageRegisterLine",       "int16");
    saveStateValue(&shortIntegerMask,               sizeof(shortIntegerMask),                                    "shortIntegerMask",               "uint64");
    saveStateValue(&shortIntegerSignBit,            sizeof(shortIntegerSignBit),                                 "shortIntegerSignBit",            "uint64");
    saveStateValue(&temporaryInformation,           sizeof(temporaryInformation),                                "temporaryInformation",           "uint8");
    saveStateValue(&glyphNotFound,                  sizeof(glyphNotFound),                                       "glyphNotFound",                  "hexDump");
    saveStateValue(&funcOK,                         sizeof(funcOK),                                              "funcOK",                         "bool");
    saveStateValue(&screenChange,                   sizeof(screenChange),                                        "screenChange",                   "bool");
    saveStateValue(&exponentSignLocation,           sizeof(exponentSignLocation),                                "exponentSignLocation",           "int16");
    saveStateValue(&denominatorLocation,            sizeof(denominatorLocation),                                 "denominatorLocation",            "int16");
    saveStateValue(&imaginaryExponentSignLocation,  sizeof(imaginaryExponentSignLocation),                       "imaginaryExponentSignLocation",  "int16");
    saveStateValue(&imaginaryMantissaSignLocation,  sizeof(imaginaryMantissaSignLocation),                       "imaginaryMantissaSignLocation",  "int16");
    saveStateValue(&lineTWidth,                     sizeof(lineTWidth),                                          "lineTWidth",                     "int16");
    saveStateValue(&lastIntegerBase,                sizeof(lastIntegerBase),                                     "lastIntegerBase",                "uint32");
    saveStateValue(&c47MemInBlocks,                 sizeof(c47MemInBlocks),                                      "c47MemInBlocks",                 "uint64");
    saveStateValue(&gmpMemInBytes,                  sizeof(gmpMemInBytes),                                       "gmpMemInBytes",                  "uint64");
    saveStateValue(&catalog,                        sizeof(catalog),                                             "catalog",                        "int16");
    saveStateValue(&lastCatalogPosition,            sizeof(lastCatalogPosition),                                 "lastCatalogPosition",            "int16");
    saveStateValue(&lgCatalogSelection,             sizeof(lgCatalogSelection),                                  "lgCatalogSelection",             "int32");
    saveStateValue(displayValueX,                   sizeof(displayValueX),                                       "displayValueX",                  "hexDump");
    saveStateValue(&pcg32_global,                   sizeof(pcg32_global),                                        "pcg32_global",                   "hexDump");
    saveStateValue(&exponentLimit,                  sizeof(exponentLimit),                                       "exponentLimit",                  "int16");
    saveStateValue(&exponentHideLimit,              sizeof(exponentHideLimit),                                   "exponentHideLimit",              "int16");
    saveStateValue(&keyActionProcessed,             sizeof(keyActionProcessed),                                  "keyActionProcessed",             "bool");
    saveStateValue(&systemFlags0,                   sizeof(systemFlags0),                                        "systemFlags",                    "uint64");
    saveStateValue(&systemFlags1,                   sizeof(systemFlags1),                                        "systemFlags1",                   "uint64");
    saveStateValue(&savedSystemFlags0,              sizeof(savedSystemFlags0),                                   "savedSystemFlags",               "uint64");
    saveStateValue(&savedSystemFlags1,              sizeof(savedSystemFlags1),                                   "savedSystemFlags1",              "uint64");
    saveStateValue(&thereIsSomethingToUndo,         sizeof(thereIsSomethingToUndo),                              "thereIsSomethingToUndo",         "bool");
    saveStateValue(&freeProgramBytes,               sizeof(freeProgramBytes),                                    "freeProgramBytes",               "uint16");
    saveStateValue(&firstDisplayedLocalStepNumber,  sizeof(firstDisplayedLocalStepNumber),                       "firstDisplayedLocalStepNumber",  "uint16");
    saveStateValue(&numberOfLabels,                 sizeof(numberOfLabels),                                      "numberOfLabels",                 "uint16");
    saveStateValue(&numberOfPrograms,               sizeof(numberOfPrograms),                                    "numberOfPrograms",               "uint16");
    saveStateValue(&currentLocalStepNumber,         sizeof(currentLocalStepNumber),                              "currentLocalStepNumber",         "uint16");
    saveStateValue(&currentProgramNumber,           sizeof(currentProgramNumber),                                "currentProgramNumber",           "uint16");
    saveStateValue(&lastProgramListEnd,             sizeof(lastProgramListEnd),                                  "lastProgramListEnd",             "bool");
    saveStateValue(&programListEnd,                 sizeof(programListEnd),                                      "programListEnd",                 "bool");
    saveStateValue(&allSubroutineLevels,            sizeof(allSubroutineLevels),                                 "allSubroutineLevels",            "uint32");
    saveStateValue(&pemCursorIsZerothStep,          sizeof(pemCursorIsZerothStep),                               "pemCursorIsZerothStep",          "bool");
    saveStateValue(&halfSecTick,                    sizeof(halfSecTick),                                         "halfSecTick",                    "bool");
    saveStateValue(&skippedStackLines,              sizeof(skippedStackLines),                                   "skippedStackLines",              "bool");
    saveStateValue(&numberOfTamMenusToPop,          sizeof(numberOfTamMenusToPop),                               "numberOfTamMenusToPop",          "int16");
    saveStateValue(&lrSelection,                    sizeof(lrSelection),                                         "lrSelection",                    "uint16");
    saveStateValue(&lrSelectionUndo,                sizeof(lrSelectionUndo),                                     "lrSelectionUndo",                "uint16");
    saveStateValue(&lrChosen,                       sizeof(lrChosen),                                            "lrChosen",                       "uint16");
    saveStateValue(&lrChosenUndo,                   sizeof(lrChosenUndo),                                        "lrChosenUndo",                   "uint16");
    saveStateValue(&lastPlotMode,                   sizeof(lastPlotMode),                                        "lastPlotMode",                   "uint16");
    saveStateValue(&plotSelection,                  sizeof(plotSelection),                                       "plotSelection",                  "uint16");
    saveStateValue(&graph_dx,                       sizeof(graph_dx),                                            "graph_dx",                       "float");
    saveStateValue(&graph_dy,                       sizeof(graph_dy),                                            "graph_dy",                       "float");
    saveStateValue(&roundedTicks,                   sizeof(roundedTicks),                                        "roundedTicks",                   "bool");
    saveStateValue(&extentx,                        sizeof(extentx),                                             "extentx",                        "bool");
    saveStateValue(&extenty,                        sizeof(extenty),                                             "extenty",                        "bool");
    saveStateValue(&PLOT_VECT,                      sizeof(PLOT_VECT),                                           "PLOT_VECT",                      "bool");
    saveStateValue(&PLOT_NVECT,                     sizeof(PLOT_NVECT),                                          "PLOT_NVECT",                     "bool");
    saveStateValue(&PLOT_SCALE,                     sizeof(PLOT_SCALE),                                          "PLOT_SCALE",                     "bool");
    saveStateValue(&Aspect_Square,                  sizeof(Aspect_Square),                                       "Aspect_Square",                  "bool");
    saveStateValue(&PLOT_LINE,                      sizeof(PLOT_LINE),                                           "PLOT_LINE",                      "bool");
    saveStateValue(&PLOT_CROSS,                     sizeof(PLOT_CROSS),                                          "PLOT_CROSS",                     "bool");
    saveStateValue(&PLOT_BOX,                       sizeof(PLOT_BOX),                                            "PLOT_BOX",                       "bool");
    saveStateValue(&PLOT_INTG,                      sizeof(PLOT_INTG),                                           "PLOT_INTG",                      "bool");
    saveStateValue(&PLOT_DIFF,                      sizeof(PLOT_DIFF),                                           "PLOT_DIFF",                      "bool");
    saveStateValue(&PLOT_RMS,                       sizeof(PLOT_RMS),                                            "PLOT_RMS",                       "bool");
    saveStateValue(&PLOT_SHADE,                     sizeof(PLOT_SHADE),                                          "PLOT_SHADE",                     "bool");
    saveStateValue(&PLOT_CPXPLOT,                   sizeof(PLOT_CPXPLOT),                                        "PLOT_CPXPLOT",                   "bool");
    saveStateValue(&PLOT_AXIS,                      sizeof(PLOT_AXIS),                                           "PLOT_AXIS",                      "bool");
    saveStateValue(&PLOT_ZMX,                       sizeof(PLOT_ZMX),                                            "PLOT_ZMX",                       "int8");
    saveStateValue(&PLOT_ZMY,                       sizeof(PLOT_ZMY),                                            "PLOT_ZMY",                       "int8");
    saveStateValue(&PLOT_ZOOM,                      sizeof(PLOT_ZOOM),                                           "PLOT_ZOOM",                      "uint8");
    saveStateValue(&plotmode,                       sizeof(plotmode),                                            "plotmode",                       "int8");
    saveStateValue(&tick_int_x,                     sizeof(tick_int_x),                                          "tick_int_x",                     "float");
    saveStateValue(&tick_int_y,                     sizeof(tick_int_y),                                          "tick_int_y",                     "float");
    saveStateValue(&x_min,                          sizeof(x_min),                                               "x_min",                          "float");
    saveStateValue(&x_max,                          sizeof(x_max),                                               "x_max",                          "float");
    saveStateValue(&y_min,                          sizeof(y_min),                                               "y_min",                          "float");
    saveStateValue(&y_max,                          sizeof(y_max),                                               "y_max",                          "float");
    saveStateValue(&xzero,                          sizeof(xzero),                                               "xzero",                          "uint32");
    saveStateValue(&yzero,                          sizeof(yzero),                                               "yzero",                          "uint32");
    saveStateValue(&regStatsXY,                     sizeof(regStatsXY),                                          "regStatsXY",                     "int16");
    saveStateValue(&matrixIndex,                    sizeof(matrixIndex),                                         "matrixIndex",                    "uint16");
    saveStateValue(&currentViewRegister,            sizeof(currentViewRegister),                                 "currentViewRegister",            "uint16");
    saveStateValue(&currentSolverStatus,            sizeof(currentSolverStatus),                                 "currentSolverStatus",            "uint16");
    saveStateValue(&currentSolverProgram,           sizeof(currentSolverProgram),                                "currentSolverProgram",           "uint16");
    saveStateValue(&currentSolverVariable,          sizeof(currentSolverVariable),                               "currentSolverVariable",          "uint16");
    saveStateValue(&numberOfFormulae,               sizeof(numberOfFormulae),                                    "numberOfFormulae",               "uint16");
    saveStateValue(&currentFormula,                 sizeof(currentFormula),                                      "currentFormula",                 "uint16");
    saveStateValue(&numberOfUserMenus,              sizeof(numberOfUserMenus),                                   "numberOfUserMenus",              "uint16");
    saveStateValue(&currentUserMenu,                sizeof(currentUserMenu),                                     "currentUserMenu",                "uint16");
    saveStateValue(&userKeyLabelSize,               sizeof(userKeyLabelSize),                                    "userKeyLabelSize",               "uint16");
    saveStateValue(&timerCraAndDeciseconds,         sizeof(timerCraAndDeciseconds),                              "timerCraAndDeciseconds",         "uint8");
    saveStateValue(&timerValue,                     sizeof(timerValue),                                          "timerValue",                     "uint32");
    saveStateValue(&timerTotalTime,                 sizeof(timerTotalTime),                                      "timerTotalTime",                 "uint32");
    saveStateValue(&currentInputVariable,           sizeof(currentInputVariable),                                "currentInputVariable",           "uint16");
    saveStateValue(&SAVED_SIGMA_LASTX,              sizeof(SAVED_SIGMA_LASTX),                                   "SAVED_SIGMA_LASTX",              "real");
    saveStateValue(&SAVED_SIGMA_LASTY,              sizeof(SAVED_SIGMA_LASTY),                                   "SAVED_SIGMA_LASTY",              "real");
    saveStateValue(&SAVED_SIGMA_LAc1,               sizeof(SAVED_SIGMA_LAc1),                                    "SAVED_SIGMA_LAc1",               "int8");
    saveStateValue(&currentMvarLabel,               sizeof(currentMvarLabel),                                    "currentMvarLabel",               "uint16");
    graphVariabl1 = INVALID_VARIABLE;
    saveStateValue(&graphVariabl1,                  sizeof(graphVariabl1),                                       "graphVariabl1",                  "int16");
    saveStateValue(&plotStatMx,                     sizeof(plotStatMx),                                          "plotStatMx",                     "hexDump");
    saveStateValue(&drawHistogram,                  sizeof(drawHistogram),                                       "drawHistogram",                  "uint8");
    saveStateValue(&statMx,                         sizeof(statMx),                                              "statMx",                         "hexDump");
    saveStateValue(&lrSelectionHistobackup,         sizeof(lrSelectionHistobackup),                              "lrSelectionHistobackup",         "uint16");
    saveStateValue(&lrChosenHistobackup,            sizeof(lrChosenHistobackup),                                 "lrChosenHistobackup",            "uint16");
    saveStateValue(&loBinR,                         sizeof(loBinR),                                              "loBinR",                         "real34");
    saveStateValue(&nBins,                          sizeof(nBins),                                               "nBins",                          "real34");
    saveStateValue(&hiBinR,                         sizeof(hiBinR),                                              "hiBinR",                         "real34");
    saveStateValue(&histElementXorY,                sizeof(histElementXorY),                                     "histElementXorY",                "int16");
    saveStateValue(&screenUpdatingMode,             sizeof(screenUpdatingMode),                                  "screenUpdatingMode",             "uint8");
    //save and restore screenData is not mandatory
    //saveStateValue(screenData,                      0,                                                           "screenData",                     "screenData");
    saveStateValue(&HOME3,                          sizeof(HOME3),                                               "HOME3",                          "bool");
    saveStateValue(&ShiftTimoutMode,                sizeof(ShiftTimoutMode),                                     "ShiftTimoutMode",                "bool");
    saveStateValue(&fgLN,                           sizeof(fgLN),                                                "fgLN",                           "uint8");
    saveStateValue(&BASE_HOME,                      sizeof(BASE_HOME),                                           "BASE_HOME",                      "bool");
    saveStateValue(&Norm_Key_00_VAR,                sizeof(Norm_Key_00_VAR),                                     "Norm_Key_00_VAR",                "int16");
    saveStateValue(&Input_Default,                  sizeof(Input_Default),                                       "Input_Default",                  "uint8");
    saveStateValue(&BASE_MYM,                       sizeof(BASE_MYM),                                            "BASE_MYM",                       "bool");
    saveStateValue(&jm_G_DOUBLETAP,                 sizeof(jm_G_DOUBLETAP),                                      "jm_G_DOUBLETAP",                 "bool");
    saveStateValue(&graph_xmin,                     sizeof(graph_xmin),                                          "graph_xmin",                     "float");
    saveStateValue(&graph_xmax,                     sizeof(graph_xmax),                                          "graph_xmax",                     "float");
    saveStateValue(&graph_ymin,                     sizeof(graph_ymin),                                          "graph_ymin",                     "float");
    saveStateValue(&graph_ymax,                     sizeof(graph_ymax),                                          "graph_ymax",                     "float");
    saveStateValue(&running_program_jm,             sizeof(running_program_jm),                                  "running_program_jm",             "bool");
    saveStateValue(&fnXEQMENUpos,                   sizeof(fnXEQMENUpos),                                        "fnXEQMENUpos",                   "int16");
    saveStateValue(&indexOfItemsXEQM,               sizeof(indexOfItemsXEQM),                                    "indexOfItemsXEQM",               "hexDump");
    saveStateValue(&T_cursorPos,                    sizeof(T_cursorPos),                                         "T_cursorPos",                    "int16");   //JM ^^
    saveStateValue(&showRegis,                      sizeof(showRegis),                                           "showRegis",                      "int16");   //JM ^^
    saveStateValue(&displayStackSHOIDISP,           sizeof(displayStackSHOIDISP),                                "displayStackSHOIDISP",           "uint8");   //JM ^^
    saveStateValue(&ListXYposition,                 sizeof(ListXYposition),                                      "ListXYposition",                 "int16");   //JM ^^
    saveStateValue(&numLock,                        sizeof(numLock),                                             "numLock",                        "bool");    //JM ^^
    saveStateValue(&DRG_Cycling,                    sizeof(DRG_Cycling),                                         "DRG_Cycling",                    "uint8");   //JM
    saveStateValue(&lastFlgScr,                     sizeof(lastFlgScr),                                          "lastFlgScr",                     "uint8");   //C43 JM
    saveStateValue(&displayAIMbufferoffset,         sizeof(displayAIMbufferoffset),                              "displayAIMbufferoffset",         "int16");   //C43 JM
    saveStateValue(&bcdDisplay,                     sizeof(bcdDisplay),                                          "bcdDisplay",                     "bool");    //C43 JM
    saveStateValue(&topHex,                         sizeof(topHex),                                              "topHex",                         "bool");    //C43 JM
    saveStateValue(&bcdDisplaySign,                 sizeof(bcdDisplaySign),                                      "bcdDisplaySign",                 "uint8");   //C43 JM
    saveStateValue(&DM_Cycling,                     sizeof(DM_Cycling),                                          "DM_Cycling",                     "uint8");   //JM
    saveStateValue(&SI_All,                         sizeof(SI_All),                                              "SI_All",                         "bool");    //JM
    saveStateValue(&LongPressM,                     sizeof(LongPressM),                                          "LongPressM",                     "uint8");   //JM
    saveStateValue(&LongPressF,                     sizeof(LongPressF),                                          "LongPressF",                     "uint8");   //JM
    saveStateValue(&currentAsnScr,                  sizeof(currentAsnScr),                                       "currentAsnScr",                  "uint8");   //JM
    saveStateValue(&gapItemLeft,                    sizeof(gapItemLeft),                                         "gapItemLeft",                    "uint16");  //JM
    saveStateValue(&gapItemRight,                   sizeof(gapItemRight),                                        "gapItemRight",                   "uint16");  //JM
    saveStateValue(&gapItemRadix,                   sizeof(gapItemRadix),                                        "gapItemRadix",                   "uint16");  //JM
    saveStateValue(&grpGroupingLeft,                sizeof(grpGroupingLeft),                                     "grpGroupingLeft",                "uint8");   //JM
    saveStateValue(&grpGroupingGr1LeftOverflow,     sizeof(grpGroupingGr1LeftOverflow),                          "grpGroupingGr1LeftOverflow",     "uint8");   //JM
    saveStateValue(&grpGroupingGr1Left,             sizeof(grpGroupingGr1Left),                                  "grpGroupingGr1Left",             "uint8");   //JM
    saveStateValue(&grpGroupingRight,               sizeof(grpGroupingRight),                                    "grpGroupingRight",               "uint8");   //JM
    saveStateValue(&MYM3,                           sizeof(MYM3),                                                "MYM3",                           "bool");

    ramPtr = TO_C47MEMPTR(allNamedVariables);
    saveStateValue(&ramPtr,                         sizeof(ramPtr),                                              "allNamedVariables",              "c47Ptr");

    ramPtr = TO_C47MEMPTR(allFormulae);
    saveStateValue(&ramPtr,                         sizeof(ramPtr),                                              "allFormulae",                    "c47Ptr");

    ramPtr = TO_C47MEMPTR(userMenus);
    saveStateValue(&ramPtr,                         sizeof(ramPtr),                                              "userMenus",                      "c47Ptr");

    ramPtr = TO_C47MEMPTR(userKeyLabel);
    saveStateValue(&ramPtr,                         sizeof(ramPtr),                                              "userKeyLabel",                   "c47Ptr");

    ramPtr = TO_C47MEMPTR(statisticalSumsPointer);
    saveStateValue(&ramPtr,                         sizeof(ramPtr),                                              "statisticalSumsPointer",         "c47Ptr");

    ramPtr = TO_C47MEMPTR(savedStatisticalSumsPointer);
    saveStateValue(&ramPtr,                         sizeof(ramPtr),                                              "savedStatisticalSumsPointer",    "c47Ptr");

    ramPtr = TO_C47MEMPTR(labelList);
    saveStateValue(&ramPtr,                         sizeof(ramPtr),                                              "labelList",                      "c47Ptr");

    ramPtr = TO_C47MEMPTR(programList);
    saveStateValue(&ramPtr,                         sizeof(ramPtr),                                              "programList",                    "c47Ptr");

    ramPtr = TO_C47MEMPTR(currentSubroutineLevelData);
    saveStateValue(&ramPtr,                         sizeof(ramPtr),                                              "currentSubroutineLevelData",     "c47Ptr");

    ramPtr = TO_C47MEMPTR(currentLocalFlags);
    saveStateValue(&ramPtr,                         sizeof(ramPtr),                                              "currentLocalFlags",              "c47Ptr");

    ramPtr = TO_C47MEMPTR(currentLocalRegisters);
    saveStateValue(&ramPtr,                         sizeof(ramPtr),                                              "currentLocalRegisters",          "c47Ptr");

    ramPtr = TO_C47MEMPTR(beginOfProgramMemory);
    saveStateValue(&ramPtr,                         sizeof(ramPtr),                                              "beginOfProgramMemory",           "c47Ptr"); // beginOfProgramMemory pointer to block

    ramPtr = (uint32_t)((void *)beginOfProgramMemory - TO_PCMEMPTR(TO_C47MEMPTR(beginOfProgramMemory)));
    saveStateValue(&ramPtr,                         sizeof(ramPtr),                                              "beginOfProgramMemoryOffset",     "uint32"); // beginOfProgramMemory offset within block

    ramPtr = TO_C47MEMPTR(firstFreeProgramByte);
    saveStateValue(&ramPtr,                         sizeof(ramPtr),                                              "firstFreeProgramByte",           "c47Ptr"); // firstFreeProgramByte pointer to block

    ramPtr = (uint32_t)((void *)firstFreeProgramByte - TO_PCMEMPTR(TO_C47MEMPTR(firstFreeProgramByte)));
    saveStateValue(&ramPtr,                         sizeof(ramPtr),                                              "firstFreeProgramByteOffset",     "uint32"); // firstFreeProgramByte offset within block

    ramPtr = TO_C47MEMPTR(firstDisplayedStep);
    saveStateValue(&ramPtr,                         sizeof(ramPtr),                                              "firstDisplayedStep",             "c47Ptr"); // firstDisplayedStep pointer to block

    ramPtr = (uint32_t)((void *)firstDisplayedStep - TO_PCMEMPTR(TO_C47MEMPTR(firstDisplayedStep)));
    saveStateValue(&ramPtr,                         sizeof(ramPtr),                                              "firstDisplayedStepOffset",       "uint32"); // firstDisplayedStep offset within block

    ramPtr = TO_C47MEMPTR(currentStep);
    saveStateValue(&ramPtr,                         sizeof(ramPtr),                                              "currentStep",                    "c47Ptr"); // currentStep pointer to block

    ramPtr = (uint32_t)((void *)currentStep - TO_PCMEMPTR(TO_C47MEMPTR(currentStep)));
    saveStateValue(&ramPtr,                         sizeof(ramPtr),                                              "currentStepOffset",              "uint32"); // currentStep offset within block

    saveStateValue(ram,                             TO_BYTES(RAM_SIZE_IN_BLOCKS),                                "ram",                            "hexDump");

    // If you create a new parameter, proceed as following:
    //saveStateValue(&newParam,                       sizeof(newParam),                                            "newParam",                       "parameterType");

    ioFileClose();
    printf("End of calc's backup\n");
  }


  static void restoreStateValue(const void *buffer, uint32_t size, const char *valueName, const char *valueType) {
    char value[200], *typePtr, *valuePtr;

    strcpy(value, valueName);
    strcat(value, ":");
    paramCurrent = paramHead;
    while(paramCurrent) {
      if(!strncmp(paramCurrent->param, value, strlen(value))) {
        break;
      }
      paramCurrent = paramCurrent->next;
    }

    if(paramCurrent == NULL) {
      printf("Parameter %s of type %s not found in file backup.cfg\n", valueName, valueType);
      printf("Using default value for %s\n", valueName);
      return;
    }

    if((typePtr = strchr(paramCurrent->param, ':')) == NULL) {
      printf("Missing colon (:) after parameter name %s\n", paramCurrent->param);
      printf("Using default value for %s\n", valueName);
      return;
    }
    typePtr++;

    if((valuePtr = strchr(typePtr, ':')) == NULL) {
      printf("Missing colon (:) after parameter type %s\n", paramCurrent->param);
      printf("Using default value for %s\n", valueName);
      return;
    }
    valuePtr++;

    char *p = typePtr;
    int i = 0;
    while(*p != ':') {
      value[i++] = *p++;
    }
    value[i] = 0;

    if(strcmp(valueType, value)) {
      printf("Expected type for parameter %s is %s but %s found\n", valueName, valueType, value);
      return;
    }

    if(!strcmp(valueType, "int64")) {
      *(int64_t *)buffer = stringToInt64(valuePtr);
    }

    else if(!strcmp(valueType, "uint64")) {
      *(uint64_t *)buffer = stringToUint64(valuePtr);
    }

    else if(!strcmp(valueType, "int32")) {
      *(int32_t *)buffer = stringToInt32(valuePtr);
    }

    else if(!strcmp(valueType, "uint32")) {
      *(uint32_t *)buffer = stringToUint32(valuePtr);
    }

    else if(!strcmp(valueType, "int16")) {
      *(int16_t *)buffer = stringToInt16(valuePtr);
    }

    else if(!strcmp(valueType, "uint16")) {
      *(uint16_t *)buffer = stringToUint16(valuePtr);
    }

    else if(!strcmp(valueType, "int8")) {
      *(int8_t *)buffer = stringToInt8(valuePtr);
    }

    else if(!strcmp(valueType, "uint8")) {
      *(uint8_t *)buffer = stringToUint8(valuePtr);
    }

    else if(!strcmp(valueType, "float")) {
      *(float *)buffer = atof(valuePtr);
    }

    else if(!strcmp(valueType, "double")) {
      *(double *)buffer = atof(valuePtr);
    }

    else if(!strcmp(valueType, "real")) {
      stringToReal(valuePtr, (real_t *)buffer, &ctxtReal39);
    }

    else if(!strcmp(valueType, "real34")) {
      stringToReal34(valuePtr, (real34_t *)buffer);
    }

    else if(!strcmp(valueType, "bool")) {
      *(bool_t *)buffer = stringToInt8(valuePtr);
      if(*(bool_t *)buffer != 0) {
        *(bool_t *)buffer = true;
      }
    }

    else if(!strcmp(valueType, "c47Ptr")) {
      *(uint32_t *)buffer = stringToUint32(valuePtr);
    }

    else if(!strcmp(valueType, "hexDump")) {
      uint32_t numberOfBytes = stringToUint32(valuePtr);
      uint8_t hi, lo, *buf = (uint8_t *)buffer;
      uint8_t *v;
      for(uint32_t count=0; count < numberOfBytes; count++, buf++) {
        if(count % 32 == 0) {
          paramCurrent = paramCurrent->next;
          v = (uint8_t *)paramCurrent->param + 7;
        }

        hi = *v - (*v <= '9' ? '0' : 'a' - 10);
        v++;
        lo = *v - (*v <= '9' ? '0' : 'a' - 10);
        v += 2;
        *buf = (hi << 4) | lo;
      }
    }

    //save and restore screenData is not mandatory
    //else if(!strcmp(valueType, "screenData")) {
    //  uint8_t *ls = (uint8_t *)buffer;
    //  for(int y = 0; y < SCREEN_HEIGHT; ++y) {
    //    paramCurrent = paramCurrent->next;
    //    for(int x = 0; x < SCREEN_WIDTH; ++x) {
    //      *ls <<= 1;
    //      if(paramCurrent->param[x] != ' ') {
    //        *ls |= 1;
    //      }
    //      if((x % 8) == 7) {
    //        ls++;
    //      }
    //    }
    //  }
    //}

    else {
      printf("ERROR: valueType %s unknown in function restoreStateValue!" LINEBREAK, valueType);
    }
  }

  void restoreCalc(void) {
    printf("RestoreCalc\n");
    uint32_t ramSizeInBlocks = 0, ramPtr = 0, backupVersion = 0;
    int ret;
    //save and restore screenData is not mandatory
    //uint8_t *loadedScreen = malloc(SCREEN_WIDTH * SCREEN_HEIGHT / 8);
    char oneParam[200];

    doFnReset(CONFIRMED, loadAutoSav);
    ret = ioFileOpen(ioPathBackup, ioModeRead);

    if(ret != FILE_OK ) {
      if(ret == FILE_CANCEL ) {
        return;
      }
      else {
        printf("Cannot restore calc's memory from file backup.cfg! Performing RESET\n");
        refreshScreen(91);
        return;
      }
    }

    // Reading all the configuration parameters
    readLine(oneParam);
    paramHead = malloc(sizeof(cfgFileParam_t));
    paramCurrent = paramHead;
    paramCurrent->param = malloc(strlen(oneParam) + 1);
    strcpy(paramCurrent->param, oneParam);
    paramCurrent->next = NULL;
    readLine(oneParam);
    while(!ioEof()) {
      paramCurrent->next = malloc(sizeof(cfgFileParam_t));
      paramCurrent = paramCurrent->next;
      paramCurrent->param = malloc(strlen(oneParam) + 1);
      strcpy(paramCurrent->param, oneParam);
      paramCurrent->next = NULL;
      readLine(oneParam);
    }
    ioFileClose();

    cachedDynamicMenu = 0;
    //configCommon(CFG_DFLT);
    restoreStateValue(&backupVersion,                  sizeof(backupVersion),                                       "backupVersion",                  "uint32");
    restoreStateValue(&ramSizeInBlocks,                sizeof(ramSizeInBlocks),                                     "ramSizeInBlocks",                "uint32");
    if(ramSizeInBlocks != RAM_SIZE_IN_BLOCKS) {
      refreshScreen(92);
      printf("Cannot restore calc's memory from file backup.cfg! File backup.cfg is from incompatible RAM size.\n");
      printf("       Backup file      Program\n");
      printf("ramSize blocks %6u           %6d\n", ramSizeInBlocks, RAM_SIZE_IN_BLOCKS);
      printf("ramSize bytes  %6u           %6d\n", TO_BYTES(ramSizeInBlocks), TO_BYTES(RAM_SIZE_IN_BLOCKS));
      return;
    }
    else if(backupVersion == 0) {
      refreshScreen(92);
      printf("Cannot restore calc's memory from file backup.cfg! File backup.cfg has invalid version number.\n");
      return;
    }

    printf("Begin of calc's restoration, backup version:%i\n", backupVersion);

    // The order in which parameters are restored doesn't matter
    // When a parameter is removed, simply remove the corresponding saveStateValue(...) and restoreStateValue(...) lines.
    restoreStateValue(ram,                             TO_BYTES(RAM_SIZE_IN_BLOCKS),                                "ram",                            "hexDump");
    restoreStateValue(&numberOfFreeMemoryRegions,      sizeof(numberOfFreeMemoryRegions),                           "numberOfFreeMemoryRegions",      "int32");
    restoreStateValue(freeMemoryRegions,               sizeof(freeMemoryRegion_t) * numberOfFreeMemoryRegions,      "freeMemoryRegions",              "hexDump");
    restoreStateValue(&numberOfAllocatedMemoryRegions, sizeof(numberOfAllocatedMemoryRegions),                      "numberOfAllocatedMemoryRegions", "int32");
    restoreStateValue(allocatedMemoryRegions,          sizeof(freeMemoryRegion_t) * numberOfAllocatedMemoryRegions, "allocatedMemoryRegions",         "hexDump");

    restoreStateValue(&ramPtr,                         sizeof(ramPtr),                                              "allNamedVariables",              "c47Ptr");
    allNamedVariables = TO_PCMEMPTR(ramPtr);

    restoreStateValue(&ramPtr,                         sizeof(ramPtr),                                              "allFormulae",                    "c47Ptr");
    allFormulae = TO_PCMEMPTR(ramPtr);

    restoreStateValue(&ramPtr,                         sizeof(ramPtr),                                              "userMenus",                      "c47Ptr");
    userMenus = TO_PCMEMPTR(ramPtr);

    restoreStateValue(&ramPtr,                         sizeof(ramPtr),                                              "userKeyLabel",                   "c47Ptr");
    userKeyLabel = TO_PCMEMPTR(ramPtr);

    restoreStateValue(&ramPtr,                         sizeof(ramPtr),                                              "statisticalSumsPointer",         "c47Ptr");
    statisticalSumsPointer = TO_PCMEMPTR(ramPtr);

    restoreStateValue(&ramPtr,                         sizeof(ramPtr),                                              "savedStatisticalSumsPointer",    "c47Ptr");
    savedStatisticalSumsPointer = TO_PCMEMPTR(ramPtr);

    restoreStateValue(&ramPtr,                         sizeof(ramPtr),                                              "labelList",                      "c47Ptr");
    labelList = TO_PCMEMPTR(ramPtr);

    restoreStateValue(&ramPtr,                         sizeof(ramPtr),                                              "programList",                    "c47Ptr");
    programList = TO_PCMEMPTR(ramPtr);

    restoreStateValue(&ramPtr,                         sizeof(ramPtr),                                              "currentSubroutineLevelData",     "c47Ptr");
    currentSubroutineLevelData = TO_PCMEMPTR(ramPtr);

    restoreStateValue(&ramPtr,                         sizeof(ramPtr),                                              "currentLocalFlags",              "c47Ptr");
    currentLocalFlags = TO_PCMEMPTR(ramPtr);

    restoreStateValue(&ramPtr,                         sizeof(ramPtr),                                              "currentLocalRegisters",          "c47Ptr");
    currentLocalRegisters = TO_PCMEMPTR(ramPtr);

    restoreStateValue(&ramPtr,                         sizeof(ramPtr),                                              "beginOfProgramMemory",           "c47Ptr"); // beginOfProgramMemory pointer to block
    beginOfProgramMemory = TO_PCMEMPTR(ramPtr);

    restoreStateValue(&ramPtr,                         sizeof(ramPtr),                                              "beginOfProgramMemoryOffset",     "uint32"); // beginOfProgramMemory offset within block
    beginOfProgramMemory += ramPtr;

    restoreStateValue(&ramPtr,                         sizeof(ramPtr),                                              "firstFreeProgramByte",           "c47Ptr"); // firstFreeProgramByte pointer to block
    firstFreeProgramByte = TO_PCMEMPTR(ramPtr);

    restoreStateValue(&ramPtr,                         sizeof(ramPtr),                                              "firstFreeProgramByteOffset",     "uint32"); // firstFreeProgramByte offset within block
    firstFreeProgramByte += ramPtr;

    restoreStateValue(&ramPtr,                         sizeof(ramPtr),                                              "firstDisplayedStep",             "c47Ptr"); // firstDisplayedStep pointer to block
    firstDisplayedStep = TO_PCMEMPTR(ramPtr);

    restoreStateValue(&ramPtr,                         sizeof(ramPtr),                                              "firstDisplayedStepOffset",       "uint32"); // firstDisplayedStep offset within block
    firstDisplayedStep += ramPtr;

    restoreStateValue(&ramPtr,                         sizeof(ramPtr),                                              "currentStep",                    "c47Ptr"); // currentStep pointer to block
    currentStep = TO_PCMEMPTR(ramPtr);

    restoreStateValue(&ramPtr,                         sizeof(ramPtr),                                              "currentStepOffset",              "uint32"); // currentStep offset within block
    currentStep += ramPtr;

    restoreStateValue(globalFlags,                     sizeof(globalFlags),                                         "globalFlags",                    "hexDump");
    restoreStateValue(errorMessage,                    ERROR_MESSAGE_LENGTH,                                        "errorMessage",                   "hexDump");
    restoreStateValue(aimBuffer,                       AIM_BUFFER_LENGTH,                                           "aimBuffer",                      "hexDump");
    restoreStateValue(nimBufferDisplay,                NIM_BUFFER_LENGTH,                                           "nimBufferDisplay",               "hexDump");
    restoreStateValue(tamBuffer,                       TAM_BUFFER_LENGTH,                                           "tamBuffer",                      "hexDump");
    restoreStateValue(asmBuffer,                       sizeof(asmBuffer),                                           "asmBuffer",                      "hexDump");
    restoreStateValue(oldTime,                         sizeof(oldTime),                                             "oldTime",                        "hexDump");
    restoreStateValue(dateTimeString,                  sizeof(dateTimeString),                                      "dateTimeString",                 "hexDump");
    restoreStateValue(softmenuStack,                   sizeof(softmenuStack),                                       "softmenuStack",                  "hexDump");
    restoreStateValue(globalRegister,                  sizeof(globalRegister),                                      "globalRegister",                 "hexDump");
    restoreStateValue(kbd_usr,                         sizeof(kbd_usr),                                             "kbd_usr",                        "hexDump");
    restoreStateValue(userMenuItems,                   sizeof(userMenuItems),                                       "userMenuItems",                  "hexDump");
    restoreStateValue(userAlphaItems,                  sizeof(userAlphaItems),                                      "userAlphaItems",                 "hexDump");
    restoreStateValue(&tam.mode,                       sizeof(tam.mode),                                            "tam.mode",                       "uint16");
    restoreStateValue(&tam.function,                   sizeof(tam.function),                                        "tam.function",                   "int16");
    restoreStateValue(&tam.alpha,                      sizeof(tam.alpha),                                           "tam.alpha",                      "bool");
    restoreStateValue(&tam.currentOperation,           sizeof(tam.currentOperation),                                "tam.currentOperation",           "int16");
    restoreStateValue(&tam.dot,                        sizeof(tam.dot),                                             "tam.dot",                        "bool");
    restoreStateValue(&tam.indirect,                   sizeof(tam.indirect),                                        "tam.indirect",                   "bool");
    restoreStateValue(&tam.digitsSoFar,                sizeof(tam.digitsSoFar),                                     "tam.digitsSoFar",                "int16");
    restoreStateValue(&tam.value,                      sizeof(tam.value),                                           "tam.value",                      "int16");
    restoreStateValue(&tam.min,                        sizeof(tam.min),                                             "tam.min",                        "int16");
    restoreStateValue(&tam.max,                        sizeof(tam.max),                                             "tam.max",                        "int16");
    restoreStateValue(&rbrRegister,                    sizeof(rbrRegister),                                         "rbrRegister",                    "int16");
    restoreStateValue(&numberOfNamedVariables,         sizeof(numberOfNamedVariables),                              "numberOfNamedVariables",         "int16");
    restoreStateValue(&xCursor,                        sizeof(xCursor),                                             "xCursor",                        "uint32");
    restoreStateValue(&yCursor,                        sizeof(yCursor),                                             "yCursor",                        "uint32");
    restoreStateValue(&firstGregorianDay,              sizeof(firstGregorianDay),                                   "firstGregorianDay",              "uint32");
    restoreStateValue(&denMax,                         sizeof(denMax),                                              "denMax",                         "uint32");
    restoreStateValue(&lastDenominator,                sizeof(lastDenominator),                                     "lastDenominator",                "uint32");
    restoreStateValue(&currentRegisterBrowserScreen,   sizeof(currentRegisterBrowserScreen),                        "currentRegisterBrowserScreen",   "int16");
    restoreStateValue(&currentFntScr,                  sizeof(currentFntScr),                                       "currentFntScr",                  "uint8");
    restoreStateValue(&currentFlgScr,                  sizeof(currentFlgScr),                                       "currentFlgScr",                  "uint8");
    restoreStateValue(&displayFormat,                  sizeof(displayFormat),                                       "displayFormat",                  "uint8");
    restoreStateValue(&displayFormatDigits,            sizeof(displayFormatDigits),                                 "displayFormatDigits",            "uint8");
    restoreStateValue(&timeDisplayFormatDigits,        sizeof(timeDisplayFormatDigits),                             "timeDisplayFormatDigits",        "uint8");
    restoreStateValue(&shortIntegerWordSize,           sizeof(shortIntegerWordSize),                                "shortIntegerWordSize",           "uint8");
    restoreStateValue(&significantDigits,              sizeof(significantDigits),                                   "significantDigits",              "uint8");
    fractionDigits = 34;
    restoreStateValue(&fractionDigits,                 sizeof(fractionDigits),                                      "fractionDigits",                 "uint8");
    restoreStateValue(&shortIntegerMode,               sizeof(shortIntegerMode),                                    "shortIntegerMode",               "uint8");
    restoreStateValue(&currentAngularMode,             sizeof(currentAngularMode),                                  "currentAngularMode",             "uint32");

    restoreStateValue(&scrLock,                        sizeof(scrLock),                                             "scrLock",                        "uint8");
    scrLock &= 0x03;

    restoreStateValue(&roundingMode,                   sizeof(roundingMode),                                        "roundingMode",                   "uint8");
    restoreStateValue(&calcMode,                       sizeof(calcMode),                                            "calcMode",                       "uint8");
    restoreStateValue(&nextChar,                       sizeof(nextChar),                                            "nextChar",                       "uint8");
    restoreStateValue(&alphaCase,                      sizeof(alphaCase),                                           "alphaCase",                      "uint8");
    restoreStateValue(&hourGlassIconEnabled,           sizeof(hourGlassIconEnabled),                                "hourGlassIconEnabled",           "bool");
    restoreStateValue(&watchIconEnabled,               sizeof(watchIconEnabled),                                    "watchIconEnabled",               "bool");
    restoreStateValue(&serialIOIconEnabled,            sizeof(serialIOIconEnabled),                                 "serialIOIconEnabled",            "bool");
    restoreStateValue(&printerIconEnabled,             sizeof(printerIconEnabled),                                  "printerIconEnabled",             "bool");
    restoreStateValue(&programRunStop,                 sizeof(programRunStop),                                      "programRunStop",                 "uint8");
    restoreStateValue(&entryStatus,                    sizeof(entryStatus),                                         "entryStatus",                    "uint8");
    restoreStateValue(&cursorEnabled,                  sizeof(cursorEnabled),                                       "cursorEnabled",                  "uint8");

    int8_t cf = 0;
    restoreStateValue(&cf,                             sizeof(cf),                                                  "cursorFont",                     "int8");
         if(cf == 1) cursorFont = &tinyFont;
    else if(cf == 2) cursorFont = &standardFont;
    else if(cf == 3) cursorFont = &numericFont;
    else             cursorFont = NULL;

    restoreStateValue(&rbr1stDigit,                    sizeof(rbr1stDigit),                                         "rbr1stDigit",                    "bool");
    restoreStateValue(&shiftF,                         sizeof(shiftF),                                              "shiftF",                         "bool");
    restoreStateValue(&shiftG,                         sizeof(shiftG),                                              "shiftG",                         "bool");
    restoreStateValue(&rbrMode,                        sizeof(rbrMode),                                             "rbrMode",                        "uint8");
    restoreStateValue(&showContent,                    sizeof(showContent),                                         "showContent",                    "bool");
    restoreStateValue(&numScreensNumericFont,          sizeof(numScreensNumericFont),                               "numScreensNumericFont",          "uint8");
    restoreStateValue(&numLinesNumericFont,            sizeof(numLinesNumericFont),                                 "numLinesNumericFont",            "uint8");
    restoreStateValue(&numScreensStandardFont,         sizeof(numScreensStandardFont),                              "numScreensStandardFont",         "uint8");
    restoreStateValue(&numLinesStandardFont,           sizeof(numLinesStandardFont),                                "numLinesStandardFont",           "uint8");
    restoreStateValue(&numScreensTinyFont,             sizeof(numScreensTinyFont),                                  "numScreensTinyFont",             "uint8");
    restoreStateValue(&numLinesTinyFont,               sizeof(numLinesTinyFont),                                    "numLinesTinyFont",               "uint8");
    restoreStateValue(&previousCalcMode,               sizeof(previousCalcMode),                                    "previousCalcMode",               "uint8");
    restoreStateValue(&lastErrorCode,                  sizeof(lastErrorCode),                                       "lastErrorCode",                  "uint8");
    restoreStateValue(&nimNumberPart,                  sizeof(nimNumberPart),                                       "nimNumberPart",                  "uint8");
    restoreStateValue(&displayStack,                   sizeof(displayStack),                                        "displayStack",                   "uint8");
    restoreStateValue(&hexDigits,                      sizeof(hexDigits),                                           "hexDigits",                      "uint8");
    restoreStateValue(&errorMessageRegisterLine,       sizeof(errorMessageRegisterLine),                            "errorMessageRegisterLine",       "int16");
    restoreStateValue(&shortIntegerMask,               sizeof(shortIntegerMask),                                    "shortIntegerMask",               "uint64");
    restoreStateValue(&shortIntegerSignBit,            sizeof(shortIntegerSignBit),                                 "shortIntegerSignBit",            "uint64");
    restoreStateValue(&temporaryInformation,           sizeof(temporaryInformation),                                "temporaryInformation",           "uint8");

    restoreStateValue(&glyphNotFound,                  sizeof(glyphNotFound),                                       "glyphNotFound",                  "hexDump");
    glyphNotFound.data   = malloc(38);
    xcopy(glyphNotFound.data, "\xff\xf8\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\xff\xf8", 38);

    restoreStateValue(&funcOK,                         sizeof(funcOK),                                              "funcOK",                         "bool");
    restoreStateValue(&screenChange,                   sizeof(screenChange),                                        "screenChange",                   "bool");
    restoreStateValue(&exponentSignLocation,           sizeof(exponentSignLocation),                                "exponentSignLocation",           "int16");
    restoreStateValue(&denominatorLocation,            sizeof(denominatorLocation),                                 "denominatorLocation",            "int16");
    restoreStateValue(&imaginaryExponentSignLocation,  sizeof(imaginaryExponentSignLocation),                       "imaginaryExponentSignLocation",  "int16");
    restoreStateValue(&imaginaryMantissaSignLocation,  sizeof(imaginaryMantissaSignLocation),                       "imaginaryMantissaSignLocation",  "int16");
    restoreStateValue(&lineTWidth,                     sizeof(lineTWidth),                                          "lineTWidth",                     "int16");
    restoreStateValue(&lastIntegerBase,                sizeof(lastIntegerBase),                                     "lastIntegerBase",                "uint32");
    restoreStateValue(&c47MemInBlocks,                 sizeof(c47MemInBlocks),                                      "c47MemInBlocks",                 "uint64");
    restoreStateValue(&gmpMemInBytes,                  sizeof(gmpMemInBytes),                                       "gmpMemInBytes",                  "uint64");
    restoreStateValue(&catalog,                        sizeof(catalog),                                             "catalog",                        "int16");
    restoreStateValue(&lastCatalogPosition,            sizeof(lastCatalogPosition),                                 "lastCatalogPosition",            "int16");
    restoreStateValue(&lgCatalogSelection,             sizeof(lgCatalogSelection),                                  "lgCatalogSelection",             "int32");
    restoreStateValue(displayValueX,                   sizeof(displayValueX),                                       "displayValueX",                  "hexDump");
    restoreStateValue(&pcg32_global,                   sizeof(pcg32_global),                                        "pcg32_global",                   "hexDump");
    restoreStateValue(&exponentLimit,                  sizeof(exponentLimit),                                       "exponentLimit",                  "int16");
    restoreStateValue(&exponentHideLimit,              sizeof(exponentHideLimit),                                   "exponentHideLimit",              "int16");
    restoreStateValue(&keyActionProcessed,             sizeof(keyActionProcessed),                                  "keyActionProcessed",             "bool");
    restoreStateValue(&systemFlags0,                   sizeof(systemFlags0),                                        "systemFlags",                    "uint64");
    systemFlags1 = 0;
    restoreStateValue(&systemFlags1,                   sizeof(systemFlags1),                                        "systemFlags1",                   "uint64");
    restoreStateValue(&savedSystemFlags0,              sizeof(savedSystemFlags0),                                   "savedSystemFlags",               "uint64");
    savedSystemFlags1 = 0;
    restoreStateValue(&savedSystemFlags1,              sizeof(savedSystemFlags1),                                   "savedSystemFlags1",              "uint64");
    restoreStateValue(&thereIsSomethingToUndo,         sizeof(thereIsSomethingToUndo),                              "thereIsSomethingToUndo",         "bool");
    restoreStateValue(&freeProgramBytes,               sizeof(freeProgramBytes),                                    "freeProgramBytes",               "uint16");
    restoreStateValue(&firstDisplayedLocalStepNumber,  sizeof(firstDisplayedLocalStepNumber),                       "firstDisplayedLocalStepNumber",  "uint16");
    restoreStateValue(&numberOfLabels,                 sizeof(numberOfLabels),                                      "numberOfLabels",                 "uint16");
    restoreStateValue(&numberOfPrograms,               sizeof(numberOfPrograms),                                    "numberOfPrograms",               "uint16");
    restoreStateValue(&currentLocalStepNumber,         sizeof(currentLocalStepNumber),                              "currentLocalStepNumber",         "uint16");
    restoreStateValue(&currentProgramNumber,           sizeof(currentProgramNumber),                                "currentProgramNumber",           "uint16");
    restoreStateValue(&lastProgramListEnd,             sizeof(lastProgramListEnd),                                  "lastProgramListEnd",             "bool");
    restoreStateValue(&programListEnd,                 sizeof(programListEnd),                                      "programListEnd",                 "bool");
    restoreStateValue(&allSubroutineLevels,            sizeof(allSubroutineLevels),                                 "allSubroutineLevels",            "uint32");
    restoreStateValue(&pemCursorIsZerothStep,          sizeof(pemCursorIsZerothStep),                               "pemCursorIsZerothStep",          "bool");
    restoreStateValue(&halfSecTick,                    sizeof(halfSecTick),                                         "halfSecTick",                    "bool");
    restoreStateValue(&skippedStackLines,              sizeof(skippedStackLines),                                   "skippedStackLines",              "bool");
    restoreStateValue(&numberOfTamMenusToPop,          sizeof(numberOfTamMenusToPop),                               "numberOfTamMenusToPop",          "int16");
    restoreStateValue(&lrSelection,                    sizeof(lrSelection),                                         "lrSelection",                    "uint16");
    restoreStateValue(&lrSelectionUndo,                sizeof(lrSelectionUndo),                                     "lrSelectionUndo",                "uint16");
    restoreStateValue(&lrChosen,                       sizeof(lrChosen),                                            "lrChosen",                       "uint16");
    restoreStateValue(&lrChosenUndo,                   sizeof(lrChosenUndo),                                        "lrChosenUndo",                   "uint16");
    restoreStateValue(&lastPlotMode,                   sizeof(lastPlotMode),                                        "lastPlotMode",                   "uint16");
    restoreStateValue(&plotSelection,                  sizeof(plotSelection),                                       "plotSelection",                  "uint16");
    restoreStateValue(&graph_dx,                       sizeof(graph_dx),                                            "graph_dx",                       "float");
    restoreStateValue(&graph_dy,                       sizeof(graph_dy),                                            "graph_dy",                       "float");
    restoreStateValue(&roundedTicks,                   sizeof(roundedTicks),                                        "roundedTicks",                   "bool");
    restoreStateValue(&extentx,                        sizeof(extentx),                                             "extentx",                        "bool");
    restoreStateValue(&extenty,                        sizeof(extenty),                                             "extenty",                        "bool");
    restoreStateValue(&PLOT_VECT,                      sizeof(PLOT_VECT),                                           "PLOT_VECT",                      "bool");
    restoreStateValue(&PLOT_NVECT,                     sizeof(PLOT_NVECT),                                          "PLOT_NVECT",                     "bool");
    restoreStateValue(&PLOT_SCALE,                     sizeof(PLOT_SCALE),                                          "PLOT_SCALE",                     "bool");
    restoreStateValue(&Aspect_Square,                  sizeof(Aspect_Square),                                       "Aspect_Square",                  "bool");
    restoreStateValue(&PLOT_LINE,                      sizeof(PLOT_LINE),                                           "PLOT_LINE",                      "bool");
    restoreStateValue(&PLOT_CROSS,                     sizeof(PLOT_CROSS),                                          "PLOT_CROSS",                     "bool");
    restoreStateValue(&PLOT_BOX,                       sizeof(PLOT_BOX),                                            "PLOT_BOX",                       "bool");
    restoreStateValue(&PLOT_INTG,                      sizeof(PLOT_INTG),                                           "PLOT_INTG",                      "bool");
    restoreStateValue(&PLOT_DIFF,                      sizeof(PLOT_DIFF),                                           "PLOT_DIFF",                      "bool");
    restoreStateValue(&PLOT_RMS,                       sizeof(PLOT_RMS),                                            "PLOT_RMS",                       "bool");
    restoreStateValue(&PLOT_SHADE,                     sizeof(PLOT_SHADE),                                          "PLOT_SHADE",                     "bool");
    PLOT_CPXPLOT = false;
    restoreStateValue(&PLOT_CPXPLOT,                   sizeof(PLOT_CPXPLOT),                                        "PLOT_CPXPLOT",                   "bool");
    restoreStateValue(&PLOT_AXIS,                      sizeof(PLOT_AXIS),                                           "PLOT_AXIS",                      "bool");
    restoreStateValue(&PLOT_ZMX,                       sizeof(PLOT_ZMX),                                            "PLOT_ZMX",                       "int8");
    restoreStateValue(&PLOT_ZMY,                       sizeof(PLOT_ZMY),                                            "PLOT_ZMY",                       "int8");
    restoreStateValue(&PLOT_ZOOM,                      sizeof(PLOT_ZOOM),                                           "PLOT_ZOOM",                      "uint8");
    restoreStateValue(&plotmode,                       sizeof(plotmode),                                            "plotmode",                       "int8");
    restoreStateValue(&tick_int_x,                     sizeof(tick_int_x),                                          "tick_int_x",                     "float");
    restoreStateValue(&tick_int_y,                     sizeof(tick_int_y),                                          "tick_int_y",                     "float");
    restoreStateValue(&x_min,                          sizeof(x_min),                                               "x_min",                          "float");
    restoreStateValue(&x_max,                          sizeof(x_max),                                               "x_max",                          "float");
    restoreStateValue(&y_min,                          sizeof(y_min),                                               "y_min",                          "float");
    restoreStateValue(&y_max,                          sizeof(y_max),                                               "y_max",                          "float");
    restoreStateValue(&xzero,                          sizeof(xzero),                                               "xzero",                          "uint32");
    restoreStateValue(&yzero,                          sizeof(yzero),                                               "yzero",                          "uint32");
    restoreStateValue(&regStatsXY,                     sizeof(regStatsXY),                                          "regStatsXY",                     "int16");
    restoreStateValue(&matrixIndex,                    sizeof(matrixIndex),                                         "matrixIndex",                    "uint16");
    restoreStateValue(&currentViewRegister,            sizeof(currentViewRegister),                                 "currentViewRegister",            "uint16");
    restoreStateValue(&currentSolverStatus,            sizeof(currentSolverStatus),                                 "currentSolverStatus",            "uint16");
    restoreStateValue(&currentSolverProgram,           sizeof(currentSolverProgram),                                "currentSolverProgram",           "uint16");
    restoreStateValue(&currentSolverVariable,          sizeof(currentSolverVariable),                               "currentSolverVariable",          "uint16");
    restoreStateValue(&numberOfFormulae,               sizeof(numberOfFormulae),                                    "numberOfFormulae",               "uint16");
    restoreStateValue(&currentFormula,                 sizeof(currentFormula),                                      "currentFormula",                 "uint16");
    restoreStateValue(&numberOfUserMenus,              sizeof(numberOfUserMenus),                                   "numberOfUserMenus",              "uint16");
    restoreStateValue(&currentUserMenu,                sizeof(currentUserMenu),                                     "currentUserMenu",                "uint16");
    restoreStateValue(&userKeyLabelSize,               sizeof(userKeyLabelSize),                                    "userKeyLabelSize",               "uint16");
    restoreStateValue(&timerCraAndDeciseconds,         sizeof(timerCraAndDeciseconds),                              "timerCraAndDeciseconds",         "uint8");
    restoreStateValue(&timerValue,                     sizeof(timerValue),                                          "timerValue",                     "uint32");
    restoreStateValue(&timerTotalTime,                 sizeof(timerTotalTime),                                      "timerTotalTime",                 "uint32");
    restoreStateValue(&currentInputVariable,           sizeof(currentInputVariable),                                "currentInputVariable",           "uint16");
    if(backupVersion < 1002 && currentInputVariable == INVALID_VARIABLE_OLD) {currentInputVariable = INVALID_VARIABLE;}
    restoreStateValue(&SAVED_SIGMA_LASTX,              sizeof(SAVED_SIGMA_LASTX),                                   "SAVED_SIGMA_LASTX",              "real");
    restoreStateValue(&SAVED_SIGMA_LASTY,              sizeof(SAVED_SIGMA_LASTY),                                   "SAVED_SIGMA_LASTY",              "real");
    SAVED_SIGMA_LAc1 = 0;
    restoreStateValue(&SAVED_SIGMA_LAc1,               sizeof(SAVED_SIGMA_LAc1),                                    "SAVED_SIGMA_LAc1",               "int8");     //manual correction as the type allocation was wrong here
    restoreStateValue(&currentMvarLabel,               sizeof(currentMvarLabel),                                    "currentMvarLabel",               "uint16");
    if(backupVersion < 1002 && currentMvarLabel == INVALID_VARIABLE_OLD) {currentMvarLabel = INVALID_VARIABLE;}
    restoreStateValue(&graphVariabl1,                  sizeof(graphVariabl1),                                       "graphVariabl1",                  "int16");
    if(backupVersion < 1002 && graphVariabl1 == INVALID_VARIABLE_OLD) {graphVariabl1 = INVALID_VARIABLE;}
    restoreStateValue(&plotStatMx,                     sizeof(plotStatMx),                                          "plotStatMx",                     "hexDump");
    restoreStateValue(&drawHistogram,                  sizeof(drawHistogram),                                       "drawHistogram",                  "uint8");
    restoreStateValue(&statMx,                         sizeof(statMx),                                              "statMx",                         "hexDump");
    restoreStateValue(&lrSelectionHistobackup,         sizeof(lrSelectionHistobackup),                              "lrSelectionHistobackup",         "uint16");
    restoreStateValue(&lrChosenHistobackup,            sizeof(lrChosenHistobackup),                                 "lrChosenHistobackup",            "uint16");
    restoreStateValue(&loBinR,                         sizeof(loBinR),                                              "loBinR",                         "real34");
    restoreStateValue(&nBins,                          sizeof(nBins),                                               "nBins",                          "real34");
    restoreStateValue(&hiBinR,                         sizeof(hiBinR),                                              "hiBinR",                         "real34");
    restoreStateValue(&histElementXorY,                sizeof(histElementXorY),                                     "histElementXorY",                "int16");
    restoreStateValue(&screenUpdatingMode,             sizeof(screenUpdatingMode),                                  "screenUpdatingMode",             "uint8");
    //save and restore screenData is not mandatory
    //restoreStateValue(loadedScreen,                    0,                                                           "screenData",                     "screenData");
    restoreStateValue(&HOME3,                          sizeof(HOME3),                                               "HOME3",                          "bool");
    restoreStateValue(&ShiftTimoutMode,                sizeof(ShiftTimoutMode),                                     "ShiftTimoutMode",                "bool");
    restoreStateValue(&fgLN,                           sizeof(fgLN),                                                "fgLN",                           "uint8");
    restoreStateValue(&BASE_HOME,                      sizeof(BASE_HOME),                                           "BASE_HOME",                      "bool");
    restoreStateValue(&Norm_Key_00_VAR,                sizeof(Norm_Key_00_VAR),                                     "Norm_Key_00_VAR",                "int16");
    restoreStateValue(&Input_Default,                  sizeof(Input_Default),                                       "Input_Default",                  "uint8");
    restoreStateValue(&BASE_MYM,                       sizeof(BASE_MYM),                                            "BASE_MYM",                       "bool");
    restoreStateValue(&jm_G_DOUBLETAP,                 sizeof(jm_G_DOUBLETAP),                                      "jm_G_DOUBLETAP",                 "bool");
    restoreStateValue(&graph_xmin,                     sizeof(graph_xmin),                                          "graph_xmin",                     "float");
    restoreStateValue(&graph_xmax,                     sizeof(graph_xmax),                                          "graph_xmax",                     "float");
    restoreStateValue(&graph_ymin,                     sizeof(graph_ymin),                                          "graph_ymin",                     "float");
    restoreStateValue(&graph_ymax,                     sizeof(graph_ymax),                                          "graph_ymax",                     "float");
    IrFractionsCurrentStatus = CF_NORMAL;
    restoreStateValue(&running_program_jm,             sizeof(running_program_jm),                                  "running_program_jm",             "bool");
    restoreStateValue(&fnXEQMENUpos,                   sizeof(fnXEQMENUpos),                                        "fnXEQMENUpos",                   "int16");
    restoreStateValue(&indexOfItemsXEQM,               sizeof(indexOfItemsXEQM),                                    "indexOfItemsXEQM",               "hexDump");
    restoreStateValue(&T_cursorPos,                    sizeof(T_cursorPos),                                         "T_cursorPos",                    "int16");   //JM ^^
    restoreStateValue(&showRegis,                      sizeof(showRegis),                                           "showRegis",                      "int16");   //JM ^^
    restoreStateValue(&displayStackSHOIDISP,           sizeof(displayStackSHOIDISP),                                "displayStackSHOIDISP",           "uint8");   //JM ^^
    restoreStateValue(&ListXYposition,                 sizeof(ListXYposition),                                      "ListXYposition",                 "int16");   //JM ^^
    restoreStateValue(&numLock,                        sizeof(numLock),                                             "numLock",                        "bool");    //JM ^^
    restoreStateValue(&DRG_Cycling,                    sizeof(DRG_Cycling),                                         "DRG_Cycling",                    "uint8");   //JM
    restoreStateValue(&lastFlgScr,                     sizeof(lastFlgScr),                                          "lastFlgScr",                     "uint8");   //C43 JM
    restoreStateValue(&displayAIMbufferoffset,         sizeof(displayAIMbufferoffset),                              "displayAIMbufferoffset",         "int16");   //C43 JM
    restoreStateValue(&bcdDisplay,                     sizeof(bcdDisplay),                                          "bcdDisplay",                     "bool");    //C43 JM
    restoreStateValue(&topHex,                         sizeof(topHex),                                              "topHex",                         "bool");    //C43 JM
    restoreStateValue(&bcdDisplaySign,                 sizeof(bcdDisplaySign),                                      "bcdDisplaySign",                 "uint8");   //C43 JM
    restoreStateValue(&DM_Cycling,                     sizeof(DM_Cycling),                                          "DM_Cycling",                     "uint8");   //JM
    restoreStateValue(&SI_All,                         sizeof(SI_All),                                              "SI_All",                         "bool");    //JM
    restoreStateValue(&LongPressM,                     sizeof(LongPressM),                                          "LongPressM",                     "uint8");   //JM
    restoreStateValue(&LongPressF,                     sizeof(LongPressF),                                          "LongPressF",                     "uint8");   //JM
    restoreStateValue(&currentAsnScr,                  sizeof(currentAsnScr),                                       "currentAsnScr",                  "uint8");   //JM
    restoreStateValue(&gapItemLeft,                    sizeof(gapItemLeft),                                         "gapItemLeft",                    "uint16");  //JM
    restoreStateValue(&gapItemRight,                   sizeof(gapItemRight),                                        "gapItemRight",                   "uint16");  //JM
    restoreStateValue(&gapItemRadix,                   sizeof(gapItemRadix),                                        "gapItemRadix",                   "uint16");  //JM
    restoreStateValue(&grpGroupingLeft,                sizeof(grpGroupingLeft),                                     "grpGroupingLeft",                "uint8");   //JM
    restoreStateValue(&grpGroupingGr1LeftOverflow,     sizeof(grpGroupingGr1LeftOverflow),                          "grpGroupingGr1LeftOverflow",     "uint8");   //JM
    restoreStateValue(&grpGroupingGr1Left,             sizeof(grpGroupingGr1Left),                                  "grpGroupingGr1Left",             "uint8");   //JM
    restoreStateValue(&grpGroupingRight,               sizeof(grpGroupingRight),                                    "grpGroupingRight",               "uint8");   //JM
    restoreStateValue(&MYM3,                           sizeof(MYM3),                                                "MYM3",                           "bool");

    // If you create a new parameter, proceed as following:
    //newParam = 42 // default value for newParam if not found in backup.cgf. This is for compatibility with older versions of backup.cfg.
    //restoreStateValue(&newParam,                       sizeof(newParam),                                            "newParam",                       "parameterType");

    bool_t tmp1 = false;
    restoreStateValue(&tmp1,                           sizeof(tmp1),                                                "constantFractions",              "bool");
    if(backupVersion < 1003) {
      printf("Version number of configfile < 1003, transferring IRFRAC.");
      if(tmp1) {
        setSystemFlag(FLAG_IRFRAC);
      }
      else {
        clearSystemFlag(FLAG_IRFRAC);
      }
    }
    restoreStateValue(&tmp1,                           sizeof(tmp1),                                                "constantFractionsOn",            "bool");
    if(backupVersion < 1003) {
      printf("Version number of configfile < 1003, transferring IRF_ON.");
      if(tmp1) {
        setSystemFlag(FLAG_IRF_ON);
      }
      else {
        clearSystemFlag(FLAG_IRF_ON);
      }
    }
    restoreStateValue(&tmp1,                           sizeof(tmp1),                                                "eRPN",                           "bool");    //JM vv
    if(backupVersion < 1003) {
      printf("Version number of configfile < 1003, transferring eRPN.");
      if(tmp1) {
        setSystemFlag(FLAG_ERPN);
      }
      else {
        clearSystemFlag(FLAG_ERPN);
      }
    }
    restoreStateValue(&tmp1,                           sizeof(tmp1),                                                "jm_LARGELI",                     "bool");
    if(backupVersion < 1003) {
      printf("Version number of configfile < 1003, transferring jm_LARGELI.");
      if(tmp1) {
        setSystemFlag(FLAG_LARGELI);
      }
      else {
        clearSystemFlag(FLAG_LARGELI);
      }
    }
    restoreStateValue(&tmp1,                           sizeof(tmp1),                                                "CPXMULT",                        "bool");    //JM
    if(backupVersion < 1003) {
      printf("Version number of configfile < 1003, transferring CPXMULT.");
      if(tmp1) {
        setSystemFlag(FLAG_CPXMULT);
      }
      else {
        clearSystemFlag(FLAG_CPXMULT);
      }
    }



    // Freeing the space occupied by all the configuration parameters
    paramCurrent = paramHead;
    while(paramHead) {
      paramHead = paramHead->next;
      free(paramCurrent->param);
      free(paramCurrent);
      paramCurrent = paramHead;
    }

    printf("End of calc's restoration\n");

    setFGLSettings(fgLN);

    if(temporaryInformation == TI_SHOW_REGISTER_BIG || temporaryInformation == TI_SHOW_REGISTER_SMALL || temporaryInformation == TI_SHOW_REGISTER_TINY || temporaryInformation==TI_SHOW_REGISTER) {
      temporaryInformation = TI_NO_INFO;
    }

    scanLabelsAndPrograms();
    defineCurrentProgramFromGlobalStepNumber(currentLocalStepNumber + abs(programList[currentProgramNumber - 1].step) - 1);
    defineCurrentStep();
    defineFirstDisplayedStep();
    defineCurrentProgramFromCurrentStep();

    //defineCurrentLocalRegisters();

    #if (DEBUG_REGISTER_L == 1)
      refreshRegisterLine(REGISTER_X); // to show L register
    #endif // (DEBUG_REGISTER_L == 1)

    //save and restore screenData is not mandatory
    //for(int y = 0; y < SCREEN_HEIGHT; ++y) {
    //  for(int x = 0; x < SCREEN_WIDTH; x += 8) {
    //    uint8_t bmpdata = *(loadedScreen + (y * SCREEN_WIDTH + x) / 8);
    //    for(int bit = 7; bit >= 0; --bit) {
    //      *(screenData + y * screenStride + x + (7 - bit)) = (bmpdata & (1 << bit)) ? ON_PIXEL : OFF_PIXEL;
    //    }
    //  }
    //}
    //free(loadedScreen);

    if(tam.mode && !tam.alpha) {
      calcModeTamGui();
    }
    else if(tam.mode && tam.alpha) {
      calcModeAimGui();
    }
    else if(   calcMode == CM_NORMAL
            || calcMode == CM_REGISTER_BROWSER
            || calcMode == CM_FLAG_BROWSER
            || calcMode == CM_ASN_BROWSER
            || calcMode == CM_FONT_BROWSER
            || calcMode == CM_PEM
            || calcMode == CM_PLOT_STAT
            || calcMode == CM_GRAPH
            || calcMode == CM_LISTXY) {
      calcModeNormalGui();
    }
    else if(calcMode == CM_MIM) {
      calcModeNormalGui();
      mimRestore();
    }
    else if(calcMode == CM_AIM) {
      calcModeNormalGui();
      calcModeAimGui();
      cursorEnabled = true;
    }
    else if(calcMode == CM_NIM) {
      calcModeNormalGui();
      cursorEnabled = true;
    }
    else if(calcMode == CM_EIM) {
    }
    else if(calcMode == CM_ASSIGN) {
    }
    else if(calcMode == CM_TIMER) {
    }
    else {
      sprintf(errorMessage, commonBugScreenMessages[bugMsgValueFor], "restoreCalc", calcMode, "calcMode");
      displayBugScreen(errorMessage);
    }
    if(catalog) {
      clearSystemFlag(FLAG_ALPHA);
    }

    updateMatrixHeightCache();
    screenUpdatingMode = SCRUPD_AUTO;
    refreshScreen(93);
  }
#endif // PC_BUILD


char aimBuffer1[400];             //The concurrent use of the global aimBuffer
                                  //does not work. See tmpString.
                                  //Temporary solution is to use a local variable of sufficient length for the target.

#if !defined(TESTSUITE_BUILD)
  static void UI64toString(uint64_t value, char * tmpRegisterString);
  static void registerToSaveString(calcRegister_t regist) {
    longInteger_t lgInt;
    int16_t sign;
    uint64_t value;
    uint32_t base;
    char *str;
    uint8_t *cfg;

    tmpRegisterString = tmpString + START_REGISTER_VALUE;

    switch(getRegisterDataType(regist)) {
      case dtLongInteger: {
        convertLongIntegerRegisterToLongInteger(regist, lgInt);
        longIntegerToAllocatedString(lgInt, tmpRegisterString, TMP_STR_LENGTH - START_REGISTER_VALUE - 1);
        longIntegerFree(lgInt);
        strcpy(aimBuffer1, "LonI");
        break;
      }

      case dtString: {
        stringToUtf8(REGISTER_STRING_DATA(regist), (uint8_t *)(tmpRegisterString));
        strcpy(aimBuffer1, "Stri");
        break;
      }

      case dtShortInteger: {
        convertShortIntegerRegisterToUInt64(regist, &sign, &value);
        base = getRegisterShortIntegerBase(regist);

        char yy[25];
        UI64toString(value, yy);
        sprintf(tmpRegisterString, "%c%s %" PRIu32, sign ? '-' : '+', yy, base);
        strcpy(aimBuffer1, "ShoI");
        break;
      }

      case dtReal34: {
        real34ToString(REGISTER_REAL34_DATA(regist), tmpRegisterString);
        switch(getRegisterAngularMode(regist)) {
          case amDegree: {
            strcpy(aimBuffer1, "Real:DEG");
            break;
          }

          case amDMS: {
            strcpy(aimBuffer1, "Real:DMS");
            break;
          }

          case amRadian: {
            strcpy(aimBuffer1, "Real:RAD");
            break;
          }

          case amMultPi: {
            strcpy(aimBuffer1, "Real:MULTPI");
            break;
          }

          case amGrad: {
            strcpy(aimBuffer1, "Real:GRAD");
            break;
          }

          case amNone: {
            strcpy(aimBuffer1, "Real");
            break;
          }

          default: {
            strcpy(aimBuffer1, "Real:???");
            break;
          }
        }
        break;
      }

      case dtComplex34: {
        real34ToString(REGISTER_REAL34_DATA(regist), tmpRegisterString);
        strcat(tmpRegisterString, " ");
        real34ToString(REGISTER_IMAG34_DATA(regist), tmpRegisterString + strlen(tmpRegisterString));
        strcpy(aimBuffer1, "Cplx");
        break;
      }

      case dtTime: {
        real34ToString(REGISTER_REAL34_DATA(regist), tmpRegisterString);
        strcpy(aimBuffer1, "Time");
        break;
      }

      case dtDate: {
        real34ToString(REGISTER_REAL34_DATA(regist), tmpRegisterString);
        strcpy(aimBuffer1, "Date");
        break;
      }

      case dtReal34Matrix: {
        sprintf(tmpRegisterString, "%" PRIu16 " %" PRIu16, REGISTER_REAL34_MATRIX_DBLOCK(regist)->matrixRows, REGISTER_REAL34_MATRIX_DBLOCK(regist)->matrixColumns);
        strcpy(aimBuffer1, "Rema");
        break;
      }

      case dtComplex34Matrix: {
        sprintf(tmpRegisterString, "%" PRIu16 " %" PRIu16, REGISTER_COMPLEX34_MATRIX_DBLOCK(regist)->matrixRows, REGISTER_COMPLEX34_MATRIX_DBLOCK(regist)->matrixColumns);
        strcpy(aimBuffer1, "Cxma");
        break;
      }

      case dtConfig: {
        for(str=tmpRegisterString, cfg=(uint8_t *)REGISTER_CONFIG_DATA(regist), value=0; value<sizeof(dtConfigDescriptor_t); value++, cfg++, str+=2) {
          sprintf(str, "%02X", *cfg);
        }
        strcpy(aimBuffer1, "Conf");
        break;
      }

      default: {
        strcpy(tmpRegisterString, "???");
        strcpy(aimBuffer1, "????");
      }
    }
  }


  static void saveMatrixElements(calcRegister_t regist) {
    if(getRegisterDataType(regist) == dtReal34Matrix) {
      for(uint32_t element = 0; element < REGISTER_REAL34_MATRIX_DBLOCK(regist)->matrixRows * REGISTER_REAL34_MATRIX_DBLOCK(regist)->matrixColumns; ++element) {
        real34ToString(REGISTER_REAL34_MATRIX_M_ELEMENTS(regist) + element, tmpString);
        strcat(tmpString, "\n");
        save(tmpString, strlen(tmpString));
      }
    }
    else if(getRegisterDataType(regist) == dtComplex34Matrix) {
      for(uint32_t element = 0; element < REGISTER_COMPLEX34_MATRIX_DBLOCK(regist)->matrixRows * REGISTER_COMPLEX34_MATRIX_DBLOCK(regist)->matrixColumns; ++element) {
        real34ToString(VARIABLE_REAL34_DATA(REGISTER_COMPLEX34_MATRIX_M_ELEMENTS(regist) + element), tmpString);
        strcat(tmpString, " ");
        real34ToString(VARIABLE_IMAG34_DATA(REGISTER_COMPLEX34_MATRIX_M_ELEMENTS(regist) + element), tmpString + strlen(tmpString));
        strcat(tmpString, "\n");
        save(tmpString, strlen(tmpString));
      }
    }
  }
#endif // !TESTSUITE_BUILD


static void doSave(uint16_t saveType);

  void fnSaveAuto(uint16_t unusedButMandatoryParameter) {
  #ifdef DMCP_BUILD
    doSave(autoSave);
  #endif //DMCP_BUILD
  }


void fnSave(uint16_t saveMode) {
  if(saveMode == SM_MANUAL_SAVE) {
    doSave(manualSave);
  }
  else if(saveMode == SM_STATE_SAVE) {
    doSave(stateSave);
  }
}

void doSave(uint16_t saveType) {
#if !defined(TESTSUITE_BUILD)
  printStatus(0, errorMessages[SAVING_STATE_FILE],force);
  ioFilePath_t path;
  char tmpString[3000];           //The concurrent use of the global tmpString
                                  //as target does not work while the source is at
                                  //tmpRegisterString = tmpString + START_REGISTER_VALUE;
                                  //Temporary solution is to use a local variable of sufficient length for the target.

  int ret;
  calcRegister_t regist;
  uint32_t i;
  char yy1[35], yy2[35];

#if defined(DMCP_BUILD)
  // Don't pass through if the power is insufficient
  if( power_check_screen() ) return;
#endif // DMCP_BUILD

  if(saveType == autoSave) {
    path = ioPathAutoSave;
  }
  else if(saveType == manualSave) {
    path = ioPathManualSave;
  }
  else {
    path = ioPathSaveStateFile;
  }

  ret = ioFileOpen(path, ioModeWrite);

  if(ret != FILE_OK ) {
    if(ret == FILE_CANCEL ) {
      return;
    }
    else {
      #if !defined(DMCP_BUILD)
        printf("Cannot SAVE in file C47.sav!\n");
      #endif // !DMCP_BUILD
      displayCalcErrorMessage(ERROR_CANNOT_WRITE_FILE, ERR_REGISTER_LINE, REGISTER_X);
      return;
    }
  }

  // SAV file version number
  //printHalfSecUpdate_Integer(force+1, "Version",configFileVersion);
  hourGlassIconEnabled = true;
  showHideHourGlass();

  sprintf(tmpString, "SAVE_FILE_REVISION\n%" PRIu8 "\n", (uint8_t)0);
  save(tmpString, strlen(tmpString));
  sprintf(tmpString, "C43_save_file_00\n%" PRIu32 "\n", (uint32_t)configFileVersion);
  save(tmpString, strlen(tmpString));


  // Global registers
  sprintf(tmpString, "GLOBAL_REGISTERS\n%" PRIu16 "\n", (uint16_t)(LAST_GLOBAL_REGISTER+1));
  save(tmpString, strlen(tmpString));
  for(regist=FIRST_GLOBAL_REGISTER; regist<=LAST_GLOBAL_REGISTER; regist++) {
    registerToSaveString(regist);
    sprintf(tmpString, "R%03" PRId16 "\n%s\n%s\n", regist, aimBuffer1, tmpRegisterString);
    save(tmpString, strlen(tmpString));
    saveMatrixElements(regist);
  }

  // Global flags
  strcpy(tmpString, "GLOBAL_FLAGS\n");
  save(tmpString, strlen(tmpString));
  sprintf(tmpString, "%" PRIu16 " %" PRIu16 " %" PRIu16 " %" PRIu16 " %" PRIu16 " %" PRIu16 " %" PRIu16 " %" PRIu16 "\n",
                       globalFlags[0],
                                   globalFlags[1],
                                               globalFlags[2],
                                                           globalFlags[3],
                                                                       globalFlags[4],
                                                                                   globalFlags[5],
                                                                                               globalFlags[6],
                                                                                                           globalFlags[7]);
  save(tmpString, strlen(tmpString));

  // Local registers
  sprintf(tmpString, "LOCAL_REGISTERS\n%" PRIu8 "\n", currentNumberOfLocalRegisters);
  save(tmpString, strlen(tmpString));
  for(i=0; i<currentNumberOfLocalRegisters; i++) {
    registerToSaveString(FIRST_LOCAL_REGISTER + i);
    sprintf(tmpString, "R.%02" PRIu32 "\n%s\n%s\n", i, aimBuffer1, tmpRegisterString);
    save(tmpString, strlen(tmpString));
    saveMatrixElements(FIRST_LOCAL_REGISTER + i);
  }

  // Local flags
  if(currentLocalRegisters) {
    sprintf(tmpString, "LOCAL_FLAGS\n%" PRIu32 "\n", currentLocalFlags->localFlags);
    save(tmpString, strlen(tmpString));
  }

  // Named variables
  sprintf(tmpString, "NAMED_VARIABLES\n%" PRIu16 "\n", numberOfNamedVariables);
  save(tmpString, strlen(tmpString));
  for(i=0; i<numberOfNamedVariables; i++) {
    registerToSaveString(FIRST_NAMED_VARIABLE + i);
    stringToUtf8((char *)allNamedVariables[i].variableName + 1, (uint8_t *)tmpString);
    sprintf(tmpString + strlen(tmpString), "\n%s\n%s\n", aimBuffer1, tmpRegisterString);
    save(tmpString, strlen(tmpString));
    saveMatrixElements(FIRST_NAMED_VARIABLE + i);
  }

  // Statistical sums
  sprintf(tmpString, "STATISTICAL_SUMS\n%" PRIu16 "\n", (uint16_t)(statisticalSumsPointer ? NUMBER_OF_STATISTICAL_SUMS : 0));
  save(tmpString, strlen(tmpString));
  for(i=0; i<(statisticalSumsPointer ? NUMBER_OF_STATISTICAL_SUMS : 0); i++) {
    realToString(statisticalSumsPointer + REAL_SIZE_IN_BLOCKS * i , tmpRegisterString);
    sprintf(tmpString, "%s\n", tmpRegisterString);
    save(tmpString, strlen(tmpString));
  }

  // System flags
  UI64toString(systemFlags0, yy1);
  sprintf(tmpString, "SYSTEM_FLAGS\n%s\n", yy1);
  save(tmpString, strlen(tmpString));
  UI64toString(systemFlags1, yy1);
  sprintf(tmpString, "SYSTEM_FLAGS1\n%s\n", yy1);
  save(tmpString, strlen(tmpString));

  // Keyboard assignments
  sprintf(tmpString, "KEYBOARD_ASSIGNMENTS\n37\n");
  save(tmpString, strlen(tmpString));
  for(i=0; i<37; i++) {
    sprintf(tmpString, "%" PRId16 " %" PRId16 " %" PRId16 " %" PRId16 " %" PRId16 " %" PRId16 " %" PRId16 " %" PRId16 " %" PRId16 "\n",
                         kbd_usr[i].keyId,
                                     kbd_usr[i].primary,
                                                 kbd_usr[i].fShifted,
                                                             kbd_usr[i].gShifted,
                                                                         kbd_usr[i].keyLblAim,
                                                                                     kbd_usr[i].primaryAim,
                                                                                                 kbd_usr[i].fShiftedAim,
                                                                                                             kbd_usr[i].gShiftedAim,
                                                                                                                         kbd_usr[i].primaryTam);
    save(tmpString, strlen(tmpString));
  }

  // Keyboard arguments
  sprintf(tmpString, "KEYBOARD_ARGUMENTS\n");
  save(tmpString, strlen(tmpString));

  uint32_t num = 0;
  for(i = 0; i < 37 * 6; ++i) {
    if(*(getNthString((uint8_t *)userKeyLabel, i)) != 0) {
      ++num;
    }
  }
  sprintf(tmpString, "%" PRIu32 "\n", num);
  save(tmpString, strlen(tmpString));

  for(i = 0; i < 37 * 6; ++i) {
    if(*(getNthString((uint8_t *)userKeyLabel, i)) != 0) {
      sprintf(tmpString, "%" PRIu32 " ", i);
      stringToUtf8((char *)getNthString((uint8_t *)userKeyLabel, i), (uint8_t *)tmpString + strlen(tmpString));
      strcat(tmpString, "\n");
      save(tmpString, strlen(tmpString));
    }
  }

  // MyMenu
  sprintf(tmpString, "MYMENU\n18\n");
  save(tmpString, strlen(tmpString));
  for(i=0; i<18; i++) {
    sprintf(tmpString, "%" PRId16, userMenuItems[i].item);
    if(userMenuItems[i].argumentName[0] != 0) {
      strcat(tmpString, " ");
      stringToUtf8(userMenuItems[i].argumentName, (uint8_t *)tmpString + strlen(tmpString));
    }
    strcat(tmpString, "\n");
    save(tmpString, strlen(tmpString));
  }

  // MyAlpha
  sprintf(tmpString, "MYALPHA\n18\n");
  save(tmpString, strlen(tmpString));
  for(i=0; i<18; i++) {
    sprintf(tmpString, "%" PRId16, userAlphaItems[i].item);
    if(userAlphaItems[i].argumentName[0] != 0) {
      strcat(tmpString, " ");
      stringToUtf8(userAlphaItems[i].argumentName, (uint8_t *)tmpString + strlen(tmpString));
    }
    strcat(tmpString, "\n");
    save(tmpString, strlen(tmpString));
  }

  // User menus
  sprintf(tmpString, "USER_MENUS\n");
  save(tmpString, strlen(tmpString));
  sprintf(tmpString, "%" PRIu16 "\n", numberOfUserMenus);
  save(tmpString, strlen(tmpString));
  for(uint32_t j = 0; j < numberOfUserMenus; ++j) {
    stringToUtf8(userMenus[j].menuName, (uint8_t *)tmpString);
    strcat(tmpString, "\n18\n");
    save(tmpString, strlen(tmpString));
    for(i=0; i<18; i++) {
      sprintf(tmpString, "%" PRId16, userMenus[j].menuItem[i].item);
      if(userMenus[j].menuItem[i].argumentName[0] != 0) {
        strcat(tmpString, " ");
        stringToUtf8(userMenus[j].menuItem[i].argumentName, (uint8_t *)tmpString + strlen(tmpString));
      }
      strcat(tmpString, "\n");
      save(tmpString, strlen(tmpString));
    }
  }

  // Programs
  uint16_t currentSizeInBlocks = RAM_SIZE_IN_BLOCKS - TO_C47MEMPTR(beginOfProgramMemory);
  sprintf(tmpString, "PROGRAMS\n%" PRIu16 "\n", currentSizeInBlocks);
  save(tmpString, strlen(tmpString));

  sprintf(tmpString, "%" PRIu32 "\n%" PRIu32 "\n", (uint32_t)TO_C47MEMPTR(currentStep), (uint32_t)((void *)currentStep - TO_PCMEMPTR(TO_C47MEMPTR(currentStep)))); // currentStep block pointer + offset within block
  save(tmpString, strlen(tmpString));

  sprintf(tmpString, "%" PRIu32 "\n%" PRIu32 "\n", (uint32_t)TO_C47MEMPTR(firstFreeProgramByte), (uint32_t)((void *)firstFreeProgramByte - TO_PCMEMPTR(TO_C47MEMPTR(firstFreeProgramByte)))); // firstFreeProgramByte block pointer + offset within block
  save(tmpString, strlen(tmpString));

  sprintf(tmpString, "%" PRIu16 "\n", freeProgramBytes);
  save(tmpString, strlen(tmpString));

  for(i=0; i<currentSizeInBlocks; i++) {
    sprintf(tmpString, "%" PRIu32 "\n", *(((uint32_t *)(beginOfProgramMemory)) + i));
    save(tmpString, strlen(tmpString));
  }

  // Equations
  sprintf(tmpString, "EQUATIONS\n%" PRIu16 "\n", numberOfFormulae);
  save(tmpString, strlen(tmpString));

  for(i=0; i<numberOfFormulae; i++) {
    stringToUtf8(TO_PCMEMPTR(allFormulae[i].pointerToFormulaData), (uint8_t *)tmpString);
    strcat(tmpString, "\n");
    save(tmpString, strlen(tmpString));
  }

  // Other configuration stuff
        sprintf(tmpString, "OTHER_CONFIGURATION_STUFF\n00\n");
        save(tmpString, strlen(tmpString));
        save(tmpString, strlen(tmpString));

        sprintf(tmpString, "firstGregorianDay\n%"          PRIu32 "\n",     firstGregorianDay);            save(tmpString, strlen(tmpString));
        sprintf(tmpString, "denMax\n%"                     PRIu32 "\n",     denMax);                       save(tmpString, strlen(tmpString));
        sprintf(tmpString, "lastDenominator\n%"            PRIu32 "\n",     lastDenominator);              save(tmpString, strlen(tmpString));
        sprintf(tmpString, "displayFormat\n%"              PRIu8  "\n",     displayFormat);                save(tmpString, strlen(tmpString));
        sprintf(tmpString, "displayFormatDigits\n%"        PRIu8  "\n",     displayFormatDigits);          save(tmpString, strlen(tmpString));
        sprintf(tmpString, "timeDisplayFormatDigits\n%"    PRIu8  "\n",     timeDisplayFormatDigits);      save(tmpString, strlen(tmpString));
        sprintf(tmpString, "shortIntegerWordSize\n%"       PRIu8  "\n",     shortIntegerWordSize);         save(tmpString, strlen(tmpString));
        sprintf(tmpString, "shortIntegerMode\n%"           PRIu8  "\n",     shortIntegerMode);             save(tmpString, strlen(tmpString));
        sprintf(tmpString, "significantDigits\n%"          PRIu8  "\n",     significantDigits);            save(tmpString, strlen(tmpString));
        sprintf(tmpString, "fractionDigits\n%"             PRIu8  "\n",     fractionDigits);               save(tmpString, strlen(tmpString));
        sprintf(tmpString, "currentAngularMode\n%"         PRIu8  "\n",     (uint8_t)currentAngularMode);  save(tmpString, strlen(tmpString));
        sprintf(tmpString, "gapItemLeft\n%"                PRIu16 "\n",     gapItemLeft);                  save(tmpString, strlen(tmpString));
        sprintf(tmpString, "gapItemRight\n%"               PRIu16 "\n",     gapItemRight);                 save(tmpString, strlen(tmpString));
        sprintf(tmpString, "gapItemRadix\n%"               PRIu16 "\n",     gapItemRadix);                 save(tmpString, strlen(tmpString));
        sprintf(tmpString, "grpGroupingLeft\n%"            PRIu8  "\n",     grpGroupingLeft);              save(tmpString, strlen(tmpString));
        sprintf(tmpString, "grpGroupingGr1LeftOverflow\n%" PRIu8  "\n",     grpGroupingGr1LeftOverflow);   save(tmpString, strlen(tmpString));
        sprintf(tmpString, "grpGroupingGr1Left\n%"         PRIu8  "\n",     grpGroupingGr1Left);           save(tmpString, strlen(tmpString));
        sprintf(tmpString, "grpGroupingRight\n%"           PRIu8  "\n",     grpGroupingRight);             save(tmpString, strlen(tmpString));
        sprintf(tmpString, "roundingMode\n%"               PRIu8  "\n",     roundingMode);                 save(tmpString, strlen(tmpString));
        sprintf(tmpString, "displayStack\n%"               PRIu8  "\n",     displayStack);                 save(tmpString, strlen(tmpString));
        UI64toString(pcg32_global.state, yy1);
        UI64toString(pcg32_global.inc, yy2);
        sprintf(tmpString, "rngState\n%s %s\n", yy1, yy2);                                                 save(tmpString, strlen(tmpString));
        sprintf(tmpString, "exponentLimit\n%"              PRId16  "\n",    exponentLimit);                save(tmpString, strlen(tmpString));
        sprintf(tmpString, "exponentHideLimit\n%"          PRId16  "\n",    exponentHideLimit);            save(tmpString, strlen(tmpString));
        sprintf(tmpString, "bestF\n%"                      PRIu16  "\n",    lrSelection);                  save(tmpString, strlen(tmpString));
        sprintf(tmpString, "fgLN\n%"                       PRIu8  "\n",     (uint8_t)fgLN);                save(tmpString, strlen(tmpString));
        sprintf(tmpString, "HOME3\n%"                      PRIu8  "\n",     (uint8_t)HOME3);               save(tmpString, strlen(tmpString));
        sprintf(tmpString, "MYM3\n%"                       PRIu8  "\n",     (uint8_t)MYM3);                save(tmpString, strlen(tmpString));
        sprintf(tmpString, "ShiftTimoutMode\n%"            PRIu8  "\n",     (uint8_t)ShiftTimoutMode);     save(tmpString, strlen(tmpString));
        sprintf(tmpString, "BASE_HOME\n%"                  PRIu8  "\n",     (uint8_t)BASE_HOME);           save(tmpString, strlen(tmpString));
        sprintf(tmpString, "Norm_Key_00_VAR\n%"            PRId16 "\n",     Norm_Key_00_VAR);              save(tmpString, strlen(tmpString));
        sprintf(tmpString, "Input_Default\n%"              PRIu8  "\n",     Input_Default);                save(tmpString, strlen(tmpString));
        sprintf(tmpString, "BASE_MYM\n%"                   PRIu8  "\n",     (uint8_t)BASE_MYM);            save(tmpString, strlen(tmpString));
        sprintf(tmpString, "jm_G_DOUBLETAP\n%"             PRIu8  "\n",     (uint8_t)jm_G_DOUBLETAP);      save(tmpString, strlen(tmpString));
        sprintf(tmpString, "displayStackSHOIDISP\n%"       PRIu8  "\n",     displayStackSHOIDISP);         save(tmpString, strlen(tmpString));
        sprintf(tmpString, "bcdDisplay\n%"                 PRIu8  "\n",     (uint8_t)bcdDisplay);          save(tmpString, strlen(tmpString));
        sprintf(tmpString, "topHex\n%"                     PRIu8  "\n",     (uint8_t)topHex);              save(tmpString, strlen(tmpString));
        sprintf(tmpString, "bcdDisplaySign\n%"             PRIu8  "\n",     bcdDisplaySign);               save(tmpString, strlen(tmpString));
        sprintf(tmpString, "DRG_Cycling\n%"                PRIu8  "\n",     DRG_Cycling);                  save(tmpString, strlen(tmpString));
        sprintf(tmpString, "DM_Cycling\n%"                 PRIu8  "\n",     DM_Cycling);                   save(tmpString, strlen(tmpString));
        sprintf(tmpString, "SI_All\n%"                     PRIu8  "\n",     (uint8_t)SI_All);              save(tmpString, strlen(tmpString));
        sprintf(tmpString, "LongPressM\n%"                 PRIu8  "\n",     (uint8_t)LongPressM);          save(tmpString, strlen(tmpString));
        sprintf(tmpString, "LongPressF\n%"                 PRIu8  "\n",     (uint8_t)LongPressF);          save(tmpString, strlen(tmpString));
        sprintf(tmpString, "lastIntegerBase\n%"            PRIu8  "\n",     (uint8_t)lastIntegerBase);     save(tmpString, strlen(tmpString));
        sprintf(tmpString, "lrChosen\n%"                   PRIu16 "\n",     lrChosen);                     save(tmpString, strlen(tmpString));
        sprintf(tmpString, "graph_xmin\n"                  "%f"   "\n",     graph_xmin);                   save(tmpString, strlen(tmpString));
        sprintf(tmpString, "graph_xmax\n"                  "%f"   "\n",     graph_xmax);                   save(tmpString, strlen(tmpString));
        sprintf(tmpString, "graph_ymin\n"                  "%f"   "\n",     graph_ymin);                   save(tmpString, strlen(tmpString));
        sprintf(tmpString, "graph_ymax\n"                  "%f"   "\n",     graph_ymax);                   save(tmpString, strlen(tmpString));
        sprintf(tmpString, "graph_dx\n"                    "%f"   "\n",     graph_dx);                     save(tmpString, strlen(tmpString));
        sprintf(tmpString, "graph_dy\n"                    "%f"   "\n",     graph_dy);                     save(tmpString, strlen(tmpString));
        sprintf(tmpString, "roundedTicks\n%"               PRIu8  "\n",     (uint8_t)roundedTicks);        save(tmpString, strlen(tmpString));
        sprintf(tmpString, "extentx\n%"                    PRIu8  "\n",     (uint8_t)extentx);             save(tmpString, strlen(tmpString));
        sprintf(tmpString, "extenty\n%"                    PRIu8  "\n",     (uint8_t)extenty);             save(tmpString, strlen(tmpString));
        sprintf(tmpString, "PLOT_VECT\n%"                  PRIu8  "\n",     (uint8_t)PLOT_VECT);           save(tmpString, strlen(tmpString));
        sprintf(tmpString, "PLOT_NVECT\n%"                 PRIu8  "\n",     (uint8_t)PLOT_NVECT);          save(tmpString, strlen(tmpString));
        sprintf(tmpString, "PLOT_SCALE\n%"                 PRIu8  "\n",     (uint8_t)PLOT_SCALE);          save(tmpString, strlen(tmpString));
        sprintf(tmpString, "PLOT_LINE\n%"                  PRIu8  "\n",     (uint8_t)PLOT_LINE);           save(tmpString, strlen(tmpString));
        sprintf(tmpString, "PLOT_CROSS\n%"                 PRIu8  "\n",     (uint8_t)PLOT_CROSS);          save(tmpString, strlen(tmpString));
        sprintf(tmpString, "PLOT_BOX\n%"                   PRIu8  "\n",     (uint8_t)PLOT_BOX);            save(tmpString, strlen(tmpString));
        sprintf(tmpString, "PLOT_INTG\n%"                  PRIu8  "\n",     (uint8_t)PLOT_INTG);           save(tmpString, strlen(tmpString));
        sprintf(tmpString, "PLOT_DIFF\n%"                  PRIu8  "\n",     (uint8_t)PLOT_DIFF);           save(tmpString, strlen(tmpString));
        sprintf(tmpString, "PLOT_RMS\n%"                   PRIu8  "\n",     (uint8_t)PLOT_RMS);            save(tmpString, strlen(tmpString));
        sprintf(tmpString, "PLOT_SHADE\n%"                 PRIu8  "\n",     (uint8_t)PLOT_SHADE);          save(tmpString, strlen(tmpString));
        sprintf(tmpString, "PLOT_AXIS\n%"                  PRIu8  "\n",     (uint8_t)PLOT_AXIS);           save(tmpString, strlen(tmpString));
        sprintf(tmpString, "PLOT_ZMX\n%"                   PRIu8  "\n",     PLOT_ZMX);                     save(tmpString, strlen(tmpString));
        sprintf(tmpString, "PLOT_ZMY\n%"                   PRIu8  "\n",     PLOT_ZMY);                     save(tmpString, strlen(tmpString));
        sprintf(tmpString, "PLOT_CPXPLOT\n%"               PRIu8  "\n",     (uint8_t)PLOT_CPXPLOT);        save(tmpString, strlen(tmpString));
        sprintf(tmpString, "END_OTHER_PARAM\n");                                                           save(tmpString, strlen(tmpString));

  ioFileClose();

  hourGlassIconEnabled = false;
  temporaryInformation = TI_SAVED;
#endif // !TESTSUITE_BUILD
}



#if !defined(TESTSUITE_BUILD)
void readLine(char *line) {
  if(!ioEof()) {
    restore(line, 1);
    while((*line == '\n' || *line == '\r') && !ioEof()) {
      restore(line, 1);
    }

    while(*line != '\n' && *line != '\r' && !ioEof()) {
      restore(++line, 1);
    }
  }

  *line = 0;
}

void read2Lines(char *line1, char *line2) {  // Needed to capture empty lines due to empty strings saved from registers
  char eol1,eol2;

  if(!ioEof()) {
    restore(line1, 1);
    while((*line1 == '\n' || *line1 == '\r') && !ioEof()) {
      restore(line1, 1);
    }

    while(*line1 != '\n' && *line1 != '\r' && !ioEof()) {
      restore(++line1, 1);
    }
  }
  eol1 = *line1;
  *line1 = 0;

  if(!ioEof()) {
    restore(line2, 1);
    eol2 = *line2;
    if((((eol1 == '\n') && (eol2 ==  '\n')) || ((eol1 == '\r') && (eol2 ==  '\r'))) && !ioEof()) {   // empty string between two CR or two LF
      *line2 = 0;
      return;
    }
    if((((eol1 == '\r') && (eol2 ==  '\n')) || ((eol1 == '\n') && (eol2 ==  '\r'))) && !ioEof()) {   // end line is CRLF or LFCR
      restore(line2, 1);
      if(((*line2 == '\n') || (*line2 == '\r')) && !ioEof()) {     // empty string after CRLF or LFCR
        *line2 = 0;
        return;
      }
    }

    while(*line2 != '\n' && *line2 != '\r' && !ioEof()) {
      restore(++line2, 1);
    }
  }

  *line2 = 0;
}



static void UI64toString(uint64_t value, char * tmpRegisterString) {
  uint32_t v0,v1;

  v0 = value & 0xffffffff;
  v1 = value >> 32;
  if(v1 != 0) {
    sprintf(tmpRegisterString, "0x%" PRIx32 "%08" PRIx32, v1, v0);
  }
  else {
    sprintf(tmpRegisterString, "0x%" PRIx32, v0);
  }
}
#endif // !TESTSUITE_BUILD

static unsigned int getBase(const char **str) {
  unsigned int base = 10;
  //fprintf(stderr,"\nget base\n");fflush(stderr);
  if(**str == '0' && (((*str)[1] >= '0' && (*str)[1] <= '7') || (*str)[1] == 'x')) {
    base = 8;
    ++*str;
    if(**str == 'x') {
      base = 16;
      ++*str;
    }
  }
  return base;
}

static unsigned int getDigit(const char *str) {
  if('0' <= *str && *str <= '9') {
    return *str - '0';
  }
  else if('a' <= *str && *str <= 'f') {
    return *str - 'a' + 10;
  }
  else if('A' <= *str && *str <= 'F') {
    return *str - 'A' + 10;
  }
  return 1000000;
}

#define stringToUintFunc(name, type)              \
  type name(const char *str) {                    \
    type value = 0;                               \
    unsigned int digit, base = getBase(&str);     \
                                                  \
    for(;;) {                                     \
      digit = getDigit(str++);                    \
      if(digit > base)                            \
        break;                                    \
      value = value*base + digit;                 \
    }                                             \
    return value;                                 \
  }

stringToUintFunc(stringToUint8,  uint8_t)
stringToUintFunc(stringToUint16, uint16_t)
stringToUintFunc(stringToUint32, uint32_t)
stringToUintFunc(stringToUint64, uint64_t)

#define stringToIntFunc(name, type)               \
  type name(const char *str) {                    \
    type value = 0;                               \
    bool_t sign = false;                          \
    unsigned int digit, base = getBase(&str);     \
                                                  \
    if(*str == '-') {                             \
      str++;                                      \
      sign = true;                                \
    }                                             \
    else if(*str == '+') {                        \
      str++;                                      \
    }                                             \
                                                  \
    for(;;) {                                     \
      digit = getDigit(str++);                    \
      if(digit > base)                            \
        break;                                    \
      value = value*base + digit;                 \
    }                                             \
                                                  \
    if(sign) {                                    \
      value = -value;                             \
    }                                             \
    return value;                                 \
  }

stringToIntFunc(stringToInt8,  int8_t)
stringToIntFunc(stringToInt16, int16_t)
stringToIntFunc(stringToInt32, int32_t)
stringToIntFunc(stringToInt64, int64_t)


float stringToFloat(const char *str) {
  return strtof(str, NULL);
}

double stringToDouble(const char *str) {
  return strtod(str, NULL);
}


#if !defined(TESTSUITE_BUILD)
  static void restoreRegister(calcRegister_t regist, char *type, char *value) {
    uint32_t tag = amNone;

    if(type[4] == ':') {
      if(type[5] == 'R') {
        tag = amRadian;
      }
      else if(type[5] == 'M') {
        tag = amMultPi;
      }
      else if(type[5] == 'G') {
        tag = amGrad;
      }
      else if(type[5] == 'D' && type[6] == 'E') {
        tag = amDegree;
      }
      else if(type[5] == 'D' && type[6] == 'M') {
        tag = amDMS;
      }
      else {
        tag = amNone;
      }

      reallocateRegister(regist, dtReal34, REAL34_SIZE_IN_BLOCKS, tag);
      stringToReal34(value, REGISTER_REAL34_DATA(regist));
    }

    else if(strcmp(type, "Real") == 0) {
      reallocateRegister(regist, dtReal34, REAL34_SIZE_IN_BLOCKS, tag);
      stringToReal34(value, REGISTER_REAL34_DATA(regist));
    }

    else if(strcmp(type, "Time") == 0) {
      reallocateRegister(regist, dtTime, REAL34_SIZE_IN_BLOCKS, amNone);
      stringToReal34(value, REGISTER_REAL34_DATA(regist));
    }

    else if(strcmp(type, "Date") == 0) {
      reallocateRegister(regist, dtDate, REAL34_SIZE_IN_BLOCKS, amNone);
      stringToReal34(value, REGISTER_REAL34_DATA(regist));
    }

    else if(strcmp(type, "LonI") == 0) {
      longInteger_t lgInt;

      longIntegerInit(lgInt);
      stringToLongInteger(value, 10, lgInt);
      convertLongIntegerToLongIntegerRegister(lgInt, regist);
      longIntegerFree(lgInt);
    }

    else if(strcmp(type, "Stri") == 0) {
      int32_t len;

      utf8ToString((uint8_t *)value, errorMessage);
      len = stringByteLength(errorMessage) + 1;
      reallocateRegister(regist, dtString, TO_BLOCKS(len), amNone);
      xcopy(REGISTER_STRING_DATA(regist), errorMessage, len);
    }

    else if(strcmp(type, "ShoI") == 0) {
      uint16_t sign = (value[0] == '-' ? 1 : 0);
      uint64_t val  = stringToUint64(value + 1);

      while(*value != ' ') {
        value++;
      }
      while(*value == ' ') {
        value++;
      }
      uint32_t base = stringToUint32(value);

      convertUInt64ToShortIntegerRegister(sign, val, base, regist);
    }

    else if(strcmp(type, "Cplx") == 0) {
      char *imaginaryPart;

      reallocateRegister(regist, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
      imaginaryPart = value;
      while(*imaginaryPart != ' ') {
        imaginaryPart++;
      }
      *(imaginaryPart++) = 0;
      stringToReal34(value, REGISTER_REAL34_DATA(regist));
      stringToReal34(imaginaryPart, REGISTER_IMAG34_DATA(regist));
    }

  #if !defined(TESTSUITE_BUILD)
    else if(strcmp(type, "Rema") == 0) {
      char *numOfCols;
      uint16_t rows, cols;

      numOfCols = value;
      while(*numOfCols != ' ') {
        numOfCols++;
      }
      *(numOfCols++) = 0;
      rows = stringToUint16(value);
      cols = stringToUint16(numOfCols);
      reallocateRegister(regist, dtReal34Matrix, REAL34_SIZE_IN_BLOCKS * rows * cols, amNone);
      REGISTER_REAL34_MATRIX_DBLOCK(regist)->matrixRows = rows;
      REGISTER_REAL34_MATRIX_DBLOCK(regist)->matrixColumns = cols;
    }

    else if(strcmp(type, "Cxma") == 0) {
      char *numOfCols;
      uint16_t rows, cols;

      numOfCols = value;
      while(*numOfCols != ' ') {
        numOfCols++;
      }
      *(numOfCols++) = 0;
      rows = stringToUint16(value);
      cols = stringToUint16(numOfCols);
      reallocateRegister(regist, dtComplex34Matrix, COMPLEX34_SIZE_IN_BLOCKS * rows * cols, amNone);
      REGISTER_COMPLEX34_MATRIX_DBLOCK(regist)->matrixRows = rows;
      REGISTER_COMPLEX34_MATRIX_DBLOCK(regist)->matrixColumns = cols;
    }
  #endif // TESTSUITE_BUILD

    else if(strcmp(type, "Conf") == 0) {
      char *cfg;

      reallocateRegister(regist, dtConfig, CONFIG_SIZE_IN_BLOCKS, amNone);
      for(cfg=(char *)REGISTER_CONFIG_DATA(regist), tag=0;  tag < (loadedVersion < 10000008 ? 896 : sizeof(dtConfigDescriptor_t)); tag++, value+=2, cfg++) {
        *cfg = ((*value >= 'A' ? *value - 'A' + 10 : *value - '0') << 4) | (*(value + 1) >= 'A' ? *(value + 1) - 'A' + 10 : *(value + 1) - '0');
      }
      if(loadedVersion < 10000008) {
        // For earlier version config files of 896 desxcriptor length, the above Write into the register must only be up to the old descriptor content.
        // We add the defaults for the new portion of the new descriptor in the following string.
        char tmpvalue[65];
        strcpy(tmpvalue, "0000000000000000F777DC2C2B842A1C33203033460C2A330118000000000000");
        for(tag=0; tag<strlen(tmpvalue); tag+=2, cfg++) {
          *cfg = ((tmpvalue[tag] >= 'A' ? tmpvalue[tag] - 'A' + 10 : tmpvalue[tag] - '0') << 4) | (tmpvalue[tag + 1] >= 'A' ? tmpvalue[tag + 1] - 'A' + 10 : tmpvalue[tag + 1] - '0');
        }
      }

    }

    else {
      sprintf(errorMessage, "In function restoreRegister: Data: Reg %d, type %s, value %s to be coded!", (int16_t)regist, type, value);
      displayBugScreen(errorMessage);
    }
  }


  static void restoreMatrixData(calcRegister_t regist) {
    #if !defined(TESTSUITE_BUILD)
    uint16_t rows, cols;
    uint32_t i;

    if(getRegisterDataType(regist) == dtReal34Matrix) {
      rows = REGISTER_REAL34_MATRIX_DBLOCK(regist)->matrixRows;
      cols = REGISTER_REAL34_MATRIX_DBLOCK(regist)->matrixColumns;

      for(i = 0; i < rows * cols; ++i) {
        readLine(tmpString);
        stringToReal34(tmpString, REGISTER_REAL34_MATRIX_M_ELEMENTS(regist) + i);
      }
    }

    if(getRegisterDataType(regist) == dtComplex34Matrix) {
      rows = REGISTER_COMPLEX34_MATRIX_DBLOCK(regist)->matrixRows;
      cols = REGISTER_COMPLEX34_MATRIX_DBLOCK(regist)->matrixColumns;

      for(i = 0; i < rows * cols; ++i) {
        char *imaginaryPart;

        readLine(tmpString);
        imaginaryPart = tmpString;
          while(*imaginaryPart != ' ') {
            imaginaryPart++;
          }
        *(imaginaryPart++) = 0;
        stringToReal34(tmpString,     VARIABLE_REAL34_DATA(REGISTER_COMPLEX34_MATRIX_M_ELEMENTS(regist) + i));
        stringToReal34(imaginaryPart, VARIABLE_IMAG34_DATA(REGISTER_COMPLEX34_MATRIX_M_ELEMENTS(regist) + i));
      }
    }
    #endif // !TESTSUITE_BUILD
  }


  static void skipMatrixData(char *type, char *value) {
    #if !defined(TESTSUITE_BUILD)
    uint16_t rows, cols;
    uint32_t i;
    char *numOfCols;

    if(strcmp(type, "Rema") == 0 || strcmp(type, "Cxma") == 0) {
      numOfCols = value;
        while(*numOfCols != ' ') {
          numOfCols++;
        }
      *(numOfCols++) = 0;
      rows = stringToUint16(value);
      cols = stringToUint16(numOfCols);

      for(i = 0; i < rows * cols; ++i) {
        readLine(tmpString);
      }
    }
    #endif // !TESTSUITE_BUILD
  }


#define LOADDEBUG
#undef LOADDEBUG
#if defined(LOADDEBUG)
  static void debugPrintf(int s1, const char * s2, const char * s3) {
    #if defined(PC_BUILD)
      printf("%i %s %s\n", s1, s2, s3);
    #else
      char yy[1000];
      sprintf(yy,"%i %s %s\n", s1, s2, s3);
//      printHalfSecUpdate_Integer(force+1, yy, 0);
//      print_linestr(yy,false);

    #endif //!PC_BUILD
  }
#endif //LOADDEBUG


  uint16_t strcmp2(char* inStr, char* in2Str) {       //special comparison, only to accommodate incorrect separator saves in versions 10000005-6.
    if(strcmp(inStr, in2Str) == 0) {
      return 0;
    }
    if(stringByteLength(inStr) != stringByteLength(in2Str)+1 || stringByteLength(inStr) > 50) {     //if length mismatch;
      return 1;
    }
    char tmps[60];
    tmps[0]=32;
    tmps[1]=0;
    strcat(tmps, in2Str);
    if(strcmp(inStr, tmps) == 0) {
      return 0;
    }
    return 1;
  }


  static bool_t restoreOneSection(uint16_t loadMode, uint16_t s, uint16_t n, uint16_t d) {
    int16_t i, numberOfRegs;
    calcRegister_t regist;
    char *str;
    #if defined(LOADDEBUG)
      char line[1000];
    #endif //LOADDEBUG

    cancelFilename = true;
    hourGlassIconEnabled = true;
    showHideHourGlass();
    readLine(tmpString);
    #if defined(LOADDEBUG)
      sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
      debugPrintf(0, "-", tmpString);
    #endif //LOADDEBUG

    if(strcmp(tmpString, "GLOBAL_REGISTERS") == 0) {
      readLine(tmpString); // Number of global registers
      numberOfRegs = stringToInt16(tmpString);
      for(i=0; i<numberOfRegs; i++) {
        readLine(tmpString); // Register number
        regist = stringToInt16(tmpString + 1);
        read2Lines(aimBuffer,tmpString); // Register data type & Register value

        if(loadMode == LM_ALL || (loadMode == LM_REGISTERS && regist < REGISTER_X) || (loadMode == LM_REGISTERS_PARTIAL && regist >= s && regist < (s + n))) {
          #if defined(LOADDEBUG)
            sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
            debugPrintf(1, "-", tmpString);
          #endif //LOADDEBUG
          restoreRegister(loadMode == LM_REGISTERS_PARTIAL ? (regist - s + d) : regist, aimBuffer, tmpString);
          restoreMatrixData(loadMode == LM_REGISTERS_PARTIAL ? (regist - s + d) : regist);
        }
        else {
          skipMatrixData(aimBuffer, tmpString);
        }
      }
    }

    else if(strcmp(tmpString, "GLOBAL_FLAGS") == 0) {
      readLine(tmpString); // Global flags
      if(loadMode == LM_ALL || loadMode == LM_SYSTEM_STATE) {
        #if defined(LOADDEBUG)
          sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
          debugPrintf(2, "-", tmpString);
        #endif //LOADDEBUG
        str = tmpString;
        globalFlags[0] = stringToInt16(str);

        while(*str != ' ') {
          str++;
        }
        while(*str == ' ') {
          str++;
        }
        globalFlags[1] = stringToInt16(str);

        while(*str != ' ') {
          str++;
        }
        while(*str == ' ') {
          str++;
        }
        globalFlags[2] = stringToInt16(str);

        while(*str != ' ') {
          str++;
        }
        while(*str == ' ') {
          str++;
        }
        globalFlags[3] = stringToInt16(str);

        while(*str != ' ') {
          str++;
        }
        while(*str == ' ') {
          str++;
        }
        globalFlags[4] = stringToInt16(str);

        while(*str != ' ') {
          str++;
        }
        while(*str == ' ') {
          str++;
        }
        globalFlags[5] = stringToInt16(str);

        while(*str != ' ') {
          str++;
        }
        while(*str == ' ') {
          str++;
        }
        globalFlags[6] = stringToInt16(str);

        while(*str != ' ') {
          str++;
        }
        while(*str == ' ') {
          str++;
        }
        globalFlags[7] = stringToInt16(str);
      }
    }

    else if(strcmp(tmpString, "LOCAL_REGISTERS") == 0) {
      readLine(tmpString); // Number of local registers
      numberOfRegs = stringToInt16(tmpString);
      if(loadMode == LM_ALL || loadMode == LM_REGISTERS) {
        #if defined(LOADDEBUG)
          sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
          debugPrintf(3, "A", tmpString);
        #endif //LOADDEBUG
        allocateLocalRegisters(numberOfRegs);
      }

      if((loadMode != LM_ALL && loadMode != LM_REGISTERS) || lastErrorCode == ERROR_NONE) {
        #if defined(LOADDEBUG)
          sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
          debugPrintf(3, "B", tmpString);
        #endif //LOADDEBUG
        for(i=0; i<numberOfRegs; i++) {
          readLine(tmpString); // Register number
          regist = stringToInt16(tmpString + 2) + FIRST_LOCAL_REGISTER;
          read2Lines(aimBuffer,tmpString); // Register data type & Register value

          if(loadMode == LM_ALL || loadMode == LM_REGISTERS) {
            #if defined(LOADDEBUG)
              sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
              debugPrintf(3, "C", tmpString);
            #endif //LOADDEBUG
            restoreRegister(regist, aimBuffer, tmpString);
            restoreMatrixData(regist);
          }
          else {
            skipMatrixData(aimBuffer, tmpString);
          }
        }
      }
    }

    else if(strcmp(tmpString, "LOCAL_FLAGS") == 0) {
      #if defined(LOADDEBUG)
        sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
        debugPrintf(4, "A", tmpString);
      #endif //LOADDEBUG
      readLine(tmpString); // LOCAL_FLAGS
      if(loadMode == LM_ALL || loadMode == LM_REGISTERS) {
        #if defined(LOADDEBUG)
          sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
          debugPrintf(4, "B", tmpString);
        #endif //LOADDEBUG
        currentLocalFlags->localFlags = stringToUint32(tmpString);
      }
    }

    else if(strcmp(tmpString, "NAMED_VARIABLES") == 0) {
      #if defined(LOADDEBUG)
        sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
        debugPrintf(20, "A", tmpString);
      #endif //LOADDEBUG
      readLine(tmpString); // Number of named variables
      numberOfRegs = stringToInt16(tmpString);
      for(i=0; i<numberOfRegs; i++) {
        readLine(errorMessage); // Variable name
        read2Lines(aimBuffer,tmpString); // Variable data type & Variable value

        if(loadMode == LM_ALL || loadMode == LM_NAMED_VARIABLES ||
          (loadMode == LM_SUMS && ((strcmp(errorMessage, "STATS") == 0) || (strcmp(errorMessage, "HISTO") == 0)))) {

          #if defined(LOADDEBUG)
            sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
            debugPrintf(20, "B", tmpString);
          #endif //LOADDEBUG
          char *varName = errorMessage + strlen(errorMessage) + 1;
          utf8ToString((uint8_t *)errorMessage, varName);
          regist = findOrAllocateNamedVariable(varName);
          if(regist != INVALID_VARIABLE) {
            restoreRegister(regist, aimBuffer, tmpString);
            restoreMatrixData(regist);
          }
          else {
            skipMatrixData(aimBuffer, tmpString);
          }
        }
        else {
          skipMatrixData(aimBuffer, tmpString);
        }
      }
    }

    else if(strcmp(tmpString, "STATISTICAL_SUMS") == 0) {
      readLine(tmpString); // Number of statistical sums
      numberOfRegs = stringToInt16(tmpString);
      if(numberOfRegs > 0 && (loadMode == LM_ALL || loadMode == LM_SUMS)) {
        #if defined(LOADDEBUG)
          sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
          debugPrintf(6, "A", tmpString);
        #endif //LOADDEBUG

        initStatisticalSums();

        for(i=0; i<numberOfRegs; i++) {
          readLine(tmpString); // statistical sum
          if(statisticalSumsPointer) { // likely
            if(loadMode == LM_ALL || loadMode == LM_SUMS) {
              #if defined(LOADDEBUG)
                sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
                debugPrintf(6, "B", tmpString);
              #endif //LOADDEBUG
              stringToReal(tmpString, (real_t *)(statisticalSumsPointer + REAL_SIZE_IN_BLOCKS * i), &ctxtReal75);
            }
          }
        }
      }
    }

    else if(strcmp(tmpString, "SYSTEM_FLAGS") == 0) {
      readLine(tmpString); // Global flags
      if(loadMode == LM_ALL || loadMode == LM_SYSTEM_STATE) {
        #if defined(LOADDEBUG)
          sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
          debugPrintf(7, "-", tmpString);
        #endif //LOADDEBUG
        systemFlags0 = stringToUint64(tmpString);
        systemFlags1 = 0;
        if(loadedVersion < 10000006) {
          defaultStatusBar(); //clear systemflags for early version config files
        }
        if(loadedVersion < 10000009) {
          setSystemFlag(FLAG_MONIT); //Monitoring is on per default
        }
      }
    }

    else if(strcmp(tmpString, "SYSTEM_FLAGS1") == 0) {
      readLine(tmpString); // Global flags
      if(loadMode == LM_ALL || loadMode == LM_SYSTEM_STATE) {
        #if defined(LOADDEBUG)
          sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
          debugPrintf(7, "-", tmpString);
        #endif //LOADDEBUG
        systemFlags1 = stringToUint64(tmpString);
        if(loadedVersion < 10000006) {
          defaultStatusBar(); //clear systemflags for early version config files
        }
        if(loadedVersion < 10000009) {
          setSystemFlag(FLAG_MONIT); //Monitoring is on per default
        }
        if(loadedVersion < 10000012) {
          clearSystemFlag(FLAG_IRFRAC); //restore previously used manually stored flags in OTHER STUFF below
          clearSystemFlag(FLAG_IRF_ON); //restore previously used manually stored flags in OTHER STUFF below
        }
      }
    }

    else if(strcmp(tmpString, "KEYBOARD_ASSIGNMENTS") == 0) {
      readLine(tmpString); // Number of keys
      numberOfRegs = stringToInt16(tmpString);
      for(i=0; i<numberOfRegs; i++) {
        readLine(tmpString); // key
        if(loadMode == LM_ALL || loadMode == LM_SYSTEM_STATE) {
          #if defined(LOADDEBUG)
            sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
            debugPrintf(8, "-", tmpString);
          #endif //LOADDEBUG
          str = tmpString;
          kbd_usr[i].keyId = stringToInt16(str);

          while(*str != ' ') {
            str++;
          }
          while(*str == ' ') {
            str++;
          }
          kbd_usr[i].primary = stringToInt16(str);

          while(*str != ' ') {
            str++;
          }
          while(*str == ' ') {
            str++;
          }
          kbd_usr[i].fShifted = stringToInt16(str);

          while(*str != ' ') {
            str++;
          }
          while(*str == ' ') {
            str++;
          }
          kbd_usr[i].gShifted = stringToInt16(str);

          while(*str != ' ') {
            str++;
          }
          while(*str == ' ') {
            str++;
          }
          kbd_usr[i].keyLblAim = stringToInt16(str);

          while(*str != ' ') {
            str++;
          }
          while(*str == ' ') {
            str++;
          }
          kbd_usr[i].primaryAim = stringToInt16(str);

          while(*str != ' ') {
            str++;
          }
          while(*str == ' ') {
            str++;
          }
          kbd_usr[i].fShiftedAim = stringToInt16(str);

          while(*str != ' ') {
            str++;
          }
          while(*str == ' ') {
            str++;
          }
          kbd_usr[i].gShiftedAim = stringToInt16(str);

          while(*str != ' ') {
            str++;
          }
          while(*str == ' ') {
            str++;
          }
          kbd_usr[i].primaryTam = stringToInt16(str);
        }
      }
    }

    else if(strcmp(tmpString, "KEYBOARD_ARGUMENTS") == 0) {
      readLine(tmpString); // Number of keys
      numberOfRegs = stringToInt16(tmpString);
      if(loadMode == LM_ALL || loadMode == LM_SYSTEM_STATE) {
        #if defined(LOADDEBUG)
          sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
          debugPrintf(9, "A", tmpString);
        #endif //LOADDEBUG
        freeC47Blocks(userKeyLabel, TO_BLOCKS(userKeyLabelSize));
        userKeyLabelSize = 37/*keys*/ * 6/*states*/ * 1/*byte terminator*/ + 1/*byte sentinel*/;
        userKeyLabel = allocC47Blocks(TO_BLOCKS(userKeyLabelSize));
        memset(userKeyLabel,   0, TO_BYTES(TO_BLOCKS(userKeyLabelSize)));
      }
      for(i=0; i<numberOfRegs; i++) {
        readLine(tmpString); // key
        if(loadMode == LM_ALL || loadMode == LM_SYSTEM_STATE) {
          #if defined(LOADDEBUG)
            sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
            debugPrintf(9, "B", tmpString);
          #endif //LOADDEBUG
          str = tmpString;
          uint16_t key = stringToUint16(str);
          userMenuItems[i].argumentName[0] = 0;

          while((*str != ' ') && (*str != '\n') && (*str != 0)) {
            str++;
          }
          if(*str == ' ') {
            while(*str == ' ') {
              str++;
            }
            if((*str != '\n') && (*str != 0)) {
              utf8ToString((uint8_t *)str, tmpString + TMP_STR_LENGTH / 2);
              setUserKeyArgument(key, tmpString + TMP_STR_LENGTH / 2);
            }
          }
        }
      }
    }

    else if(strcmp(tmpString, "MYMENU") == 0) {
      readLine(tmpString); // Number of keys
      numberOfRegs = stringToInt16(tmpString);
      for(i=0; i<numberOfRegs; i++) {
        readLine(tmpString); // key
        if(loadMode == LM_ALL || loadMode == LM_SYSTEM_STATE) {
          #if defined(LOADDEBUG)
            sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
            debugPrintf(10, "-", tmpString);
          #endif //LOADDEBUG
          str = tmpString;
          userMenuItems[i].item            = stringToInt16(str);
          userMenuItems[i].argumentName[0] = 0;

          while((*str != ' ') && (*str != '\n') && (*str != 0)) {
            str++;
          }
          if(*str == ' ') {
            while(*str == ' ') {
              str++;
            }
            if((*str != '\n') && (*str != 0)) {
              utf8ToString((uint8_t *)str, userMenuItems[i].argumentName);
            }
          }
        }
      }
    }

    else if(strcmp(tmpString, "MYALPHA") == 0) {
      readLine(tmpString); // Number of keys
      numberOfRegs = stringToInt16(tmpString);
      for(i=0; i<numberOfRegs; i++) {
        readLine(tmpString); // key
        if(loadMode == LM_ALL || loadMode == LM_SYSTEM_STATE) {
          #if defined(LOADDEBUG)
            sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
            debugPrintf(11, "-", tmpString);
          #endif //LOADDEBUG
          str = tmpString;
          userAlphaItems[i].item            = stringToInt16(str);
          userAlphaItems[i].argumentName[0] = 0;

          while((*str != ' ') && (*str != '\n') && (*str != 0)) {
            str++;
          }
          if(*str == ' ') {
            while(*str == ' ') {
              str++;
            }
            if((*str != '\n') && (*str != 0)) {
              utf8ToString((uint8_t *)str, userAlphaItems[i].argumentName);
            }
          }
        }
      }
    }

    else if(strcmp(tmpString, "USER_MENUS") == 0) {
      readLine(tmpString); // Number of keys
      int16_t numberOfMenus = stringToInt16(tmpString);
      for(int32_t j=0; j<numberOfMenus; j++) {
        readLine(tmpString);
        int16_t target = -1;
        if(loadMode == LM_ALL || loadMode == LM_SYSTEM_STATE) {
          #if defined(LOADDEBUG)
            sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
            debugPrintf(12, "-", tmpString);
          #endif //LOADDEBUG
          utf8ToString((uint8_t *)tmpString, tmpString + TMP_STR_LENGTH / 2);
          for(i = 0; i < numberOfUserMenus; ++i) {
            if(compareString(tmpString + TMP_STR_LENGTH / 2, userMenus[i].menuName, CMP_NAME) == 0) {
              target = i;
            }
          }
          if(target == -1) {
            createMenu(tmpString + TMP_STR_LENGTH / 2);
            target = numberOfUserMenus - 1;
          }
        }

        readLine(tmpString);
        numberOfRegs = stringToInt16(tmpString);
        for(i=0; i<numberOfRegs; i++) {
          readLine(tmpString); // key
          if(loadMode == LM_ALL || loadMode == LM_SYSTEM_STATE) {
            #if defined(LOADDEBUG)
              sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
              debugPrintf(13, "-", tmpString);
            #endif //LOADDEBUG
            str = tmpString;
            userMenus[target].menuItem[i].item            = stringToInt16(str);
            userMenus[target].menuItem[i].argumentName[0] = 0;

            while((*str != ' ') && (*str != '\n') && (*str != 0)) {
              str++;
            }
            if(*str == ' ') {
              while(*str == ' ') {
                str++;
              }
              if((*str != '\n') && (*str != 0)) {
                utf8ToString((uint8_t *)str, userMenus[target].menuItem[i].argumentName);
              }
            }
          }
        }
      }
    }

    else if(strcmp(tmpString, "PROGRAMS") == 0) {
      #if defined(LOADDEBUG)
        if(loadMode == LM_ALL || loadMode == LM_PROGRAMS) {
          sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
          debugPrintf(14, "-", tmpString);
        }
      #endif //LOADDEBUG
      uint16_t numberOfBlocks;
      uint16_t oldSizeInBlocks = RAM_SIZE_IN_BLOCKS - TO_C47MEMPTR(beginOfProgramMemory);
      uint8_t *oldFirstFreeProgramByte = firstFreeProgramByte;
      uint16_t oldFreeProgramBytes = freeProgramBytes;

      readLine(tmpString); // Number of blocks
      numberOfBlocks = stringToUint16(tmpString);
      if(loadMode == LM_ALL) {
        resizeProgramMemory(numberOfBlocks);
      }
      else if(loadMode == LM_PROGRAMS) {
        resizeProgramMemory(oldSizeInBlocks + numberOfBlocks);
        oldFirstFreeProgramByte = beginOfProgramMemory + TO_BYTES(oldSizeInBlocks) - oldFreeProgramBytes - 2;
      }

      readLine(tmpString); // currentStep (pointer to block)
      if(loadMode == LM_ALL) {
        currentStep = TO_PCMEMPTR(stringToUint32(tmpString));
      }
      readLine(tmpString); // currentStep (offset in bytes within block)
      if(loadMode == LM_ALL) {
        currentStep += stringToUint32(tmpString);
      }
      else if(loadMode == LM_PROGRAMS) {
        if(programList[currentProgramNumber - 1].step > 0) {
          currentStep           -= TO_BYTES(numberOfBlocks);
          firstDisplayedStep    -= TO_BYTES(numberOfBlocks);
          beginOfCurrentProgram -= TO_BYTES(numberOfBlocks);
          endOfCurrentProgram   -= TO_BYTES(numberOfBlocks);
        }
      }

      readLine(tmpString); // firstFreeProgramByte (pointer to block)
      if(loadMode == LM_ALL || loadMode == LM_PROGRAMS) {
        firstFreeProgramByte = TO_PCMEMPTR(stringToUint32(tmpString));
      }
      readLine(tmpString); // firstFreeProgramByte (offset in bytes within block)
      if(loadMode == LM_ALL || loadMode == LM_PROGRAMS) {
        firstFreeProgramByte += stringToUint32(tmpString);
      }

      readLine(tmpString); // freeProgramBytes
      if(loadMode == LM_ALL || loadMode == LM_PROGRAMS) {
        freeProgramBytes = stringToUint16(tmpString);
      }

      if(loadMode == LM_PROGRAMS) { // .END. to END
        freeProgramBytes += oldFreeProgramBytes;
        if((oldFirstFreeProgramByte >= (beginOfProgramMemory + 2)) && isAtEndOfProgram(oldFirstFreeProgramByte - 2)) {
        }
        else {
          if(oldFreeProgramBytes + freeProgramBytes < 2) {
            uint16_t tmpFreeProgramBytes = freeProgramBytes;
            resizeProgramMemory(oldSizeInBlocks + numberOfBlocks + 1);
            oldFirstFreeProgramByte -= 4;
            freeProgramBytes = tmpFreeProgramBytes + 4;
            if(programList[currentProgramNumber - 1].step > 0) {
            currentStep           -= 4;
            firstDisplayedStep    -= 4;
            beginOfCurrentProgram -= 4;
            endOfCurrentProgram   -= 4;
            }
          }
          *(oldFirstFreeProgramByte    ) = (ITM_END >> 8) | 0x80;
          *(oldFirstFreeProgramByte + 1) =  ITM_END       & 0xff;
          freeProgramBytes -= 2;
          oldFirstFreeProgramByte += 2;
        }
      }

      for(i=0; i<numberOfBlocks; i++) {
        readLine(tmpString); // One block
        if(loadMode == LM_ALL) {
          *(((uint32_t *)(beginOfProgramMemory)) + i) = stringToUint32(tmpString);
        }
        else if(loadMode == LM_PROGRAMS) {
          uint32_t tmpBlock = stringToUint32(tmpString);
          xcopy(oldFirstFreeProgramByte + TO_BYTES(i), (uint8_t *)(&tmpBlock), 4);
        }
      }

      scanLabelsAndPrograms();
    }

    else if(strcmp(tmpString, "EQUATIONS") == 0) {
      uint16_t formulae;

      if(loadMode == LM_ALL || loadMode == LM_PROGRAMS) {
        #if defined(LOADDEBUG)
          sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
          debugPrintf(15, "A", tmpString);
        #endif //LOADDEBUG
        for(i = numberOfFormulae; i > 0; --i) {
          deleteEquation(i - 1);
        }
      }

      readLine(tmpString); // Number of formulae
      formulae = stringToUint16(tmpString);
      if(loadMode == LM_ALL || loadMode == LM_PROGRAMS) {
        #if defined(LOADDEBUG)
          sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
          debugPrintf(15, "B", tmpString);
        #endif //LOADDEBUG
        allFormulae = allocC47Blocks(TO_BLOCKS(sizeof(formulaHeader_t)) * formulae);
        numberOfFormulae = formulae;
        currentFormula = 0;
        for(i = 0; i < formulae; i++) {
          allFormulae[i].pointerToFormulaData = C47_NULL;
          allFormulae[i].sizeInBlocks = 0;
        }
      }

      for(i = 0; i < formulae; i++) {
        readLine(tmpString); // One formula
        if(loadMode == LM_ALL || loadMode == LM_PROGRAMS) {
          #if defined(LOADDEBUG)
            sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
            debugPrintf(15, "C", tmpString);
          #endif //LOADDEBUG
          utf8ToString((uint8_t *)tmpString, tmpString + TMP_STR_LENGTH / 2);
          setEquation(i, tmpString + TMP_STR_LENGTH / 2);
        }
      }
    }

    else if(strcmp(tmpString, "OTHER_CONFIGURATION_STUFF") == 0) {
      if(loadMode == LM_ALL || loadMode == LM_SYSTEM_STATE) {
        #if defined(LOADDEBUG)
          sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
          debugPrintf(16, "A", tmpString);
        #endif //LOADDEBUG
        resetOtherConfigurationStuff(); //Ensure all the configuration stuff below is reset prior to loading.
                                        //That ensures if missing settings, that the proper defaults are set.
      }
      readLine(tmpString); // Number params not used anymore, reading until end of file or "END_OTHER_PARAM"; leaving it to read the old parameter in old files
      numberOfRegs = stringToInt16(tmpString);
      i = 0;
      while(i < 255) {                                                           //adjust for absolute maximum number of OTHER CONFIGUARTION SETTINGS
        readLine(aimBuffer); // param
        if(strcmp(aimBuffer,"END_OTHER_PARAM") == 0 || aimBuffer[0] == 0) break; //break the reading loop for end of file (zero length read, or in all later files END_OTHER_PARAM)
        readLine(tmpString); // value
        if(loadMode == LM_ALL || loadMode == LM_SYSTEM_STATE) {
          #if defined(LOADDEBUG)
            sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
            char aa[333];
            sprintf(aa,"B|%u|%s",i,aimBuffer);
            debugPrintf(16, aa, tmpString);
          #endif //LOADDEBUG

          if(strcmp(aimBuffer, "firstGregorianDay") == 0) {
            firstGregorianDay = stringToUint32(tmpString);
          }
          else if(strcmp(aimBuffer, "denMax") == 0) {
            denMax = stringToUint32(tmpString);
            if(denMax == 1 || denMax > MAX_DENMAX) {
              denMax = MAX_DENMAX;
            }
          }
          else if(strcmp(aimBuffer, "lastDenominator") == 0) {
            lastDenominator = stringToUint32(tmpString);
            if(lastDenominator < 1 || lastDenominator > MAX_DENMAX) {
              lastDenominator = 4;
            }
          }
          else if(strcmp(aimBuffer, "displayFormat"               ) == 0) { displayFormat       = stringToUint8(tmpString);   }
          else if(strcmp(aimBuffer, "displayFormatDigits"         ) == 0) { displayFormatDigits = stringToUint8(tmpString);   }
          else if(strcmp(aimBuffer, "timeDisplayFormatDigits"     ) == 0) { timeDisplayFormatDigits = stringToUint8(tmpString); }
          else if(strcmp(aimBuffer, "shortIntegerWordSize"        ) == 0) { shortIntegerWordSize = stringToUint8(tmpString);  }
          else if(strcmp(aimBuffer, "shortIntegerMode"            ) == 0) { shortIntegerMode     = stringToUint8(tmpString);  }
          else if(strcmp(aimBuffer, "significantDigits"           ) == 0) { significantDigits    = stringToUint8(tmpString);  }
          else if(strcmp(aimBuffer, "fractionDigits"              ) == 0) { fractionDigits       = stringToUint8(tmpString);  }
          else if(strcmp(aimBuffer, "currentAngularMode"          ) == 0) { currentAngularMode   = stringToUint8(tmpString);  }
          else if(strcmp(aimBuffer, "groupingGap"                 ) == 0) { //backwards compatible loading old config files
            configCommon(CFG_DFLT);
            grpGroupingLeft = stringToUint8(tmpString);                     //Changed from groupingGap to remain compatible
            grpGroupingRight = grpGroupingLeft;
          }
          else if(strcmp2(aimBuffer, "gapItemLeft"                ) == 0) { gapItemLeft          = stringToUint16(tmpString); }            //This is to correct a bug in version 00000005-6, to be compatible to the old files
          else if(strcmp2(aimBuffer, "gapItemRight"               ) == 0) { gapItemRight         = stringToUint16(tmpString); }            //This is to correct a bug in version 00000005-6, to be compatible to the old files
          else if(strcmp2(aimBuffer, "gapItemRadix"               ) == 0) { gapItemRadix         = stringToUint16(tmpString); }            //This is to correct a bug in version 00000005-6, to be compatible to the old files
          else if(strcmp2(aimBuffer, "grpGroupingLeft"            ) == 0) { grpGroupingLeft      = stringToUint8(tmpString);  }            //This is to correct a bug in version 00000005-6, to be compatible to the old files
          else if(strcmp2(aimBuffer, "grpGroupingGr1LeftOverflow" ) == 0) { grpGroupingGr1LeftOverflow = stringToUint8(tmpString);  }      //This is to correct a bug in version 00000005-6, to be compatible to the old files
          else if(strcmp2(aimBuffer, "grpGroupingGr1Left"         ) == 0) { grpGroupingGr1Left   = stringToUint8(tmpString);  }            //This is to correct a bug in version 00000005-6, to be compatible to the old files
          else if(strcmp2(aimBuffer, "grpGroupingRight"           ) == 0) { grpGroupingRight     = stringToUint8(tmpString);  }            //This is to correct a bug in version 00000005-6, to be compatible to the old files
          else if(strcmp(aimBuffer, "roundingMode"                ) == 0) { roundingMode         = stringToUint8(tmpString);  }
          else if(strcmp(aimBuffer, "displayStack"                ) == 0) { displayStack         = stringToUint8(tmpString);  }
          else if(strcmp(aimBuffer, "rngState"                    ) == 0) {
            pcg32_global.state = stringToUint64(tmpString);
            str = tmpString;
            while(*str != ' ') {
              str++;
            }
            while(*str == ' ') {
              str++;
            }
            pcg32_global.inc = stringToUint64(str);
          }
          else if(strcmp(aimBuffer, "exponentLimit"               ) == 0) { exponentLimit         = stringToInt16(tmpString); }
          else if(strcmp(aimBuffer, "exponentHideLimit"           ) == 0) { exponentHideLimit     = stringToInt16(tmpString); }
          else if(strcmp(aimBuffer, "notBestF"                    ) == 0) { lrSelection           = stringToUint16(tmpString);}
          else if(strcmp(aimBuffer, "bestF"                       ) == 0) { lrSelection           = stringToUint16(tmpString);}
          else if(strcmp(aimBuffer, "fgLN"                        ) == 0) { fgLN                  = stringToUint8(tmpString); }
          else if(strcmp(aimBuffer, "jm_FG_LINE"                  ) == 0) { fgLN                  = stringToUint8(tmpString); }             //Keep compatible with old setting
          else if(strcmp(aimBuffer, "HOME3"                       ) == 0) { HOME3                 = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "MYM3"                        ) == 0) { MYM3                  = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "ShiftTimoutMode"             ) == 0) { ShiftTimoutMode       = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "SH_BASE_HOME"                ) == 0) { BASE_HOME             = (bool_t)stringToUint8(tmpString) != 0; }  //Keep compatible with old name by repeating it
          else if(strcmp(aimBuffer, "BASE_HOME"                   ) == 0) { BASE_HOME             = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "Norm_Key_00_VAR"             ) == 0) { Norm_Key_00_VAR       = stringToUint16(tmpString); }
          else if(strcmp(aimBuffer, "Input_Default"               ) == 0) { Input_Default         = stringToUint8(tmpString); }
          else if(strcmp(aimBuffer, "jm_BASE_SCREEN"              ) == 0) { BASE_MYM              = (bool_t)stringToUint8(tmpString) != 0; }        //Keep compatible by repeating
          else if(strcmp(aimBuffer, "BASE_MYM"                    ) == 0) { BASE_MYM              = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "jm_G_DOUBLETAP"              ) == 0) { jm_G_DOUBLETAP        = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "displayStackSHOIDISP"        ) == 0) { displayStackSHOIDISP  = stringToUint8(tmpString); }
          else if(strcmp(aimBuffer, "bcdDisplay"                  ) == 0) { bcdDisplay            = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "topHex"                      ) == 0) { topHex                = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "bcdDisplaySign"              ) == 0) { bcdDisplaySign        = stringToUint8(tmpString); }
          else if(strcmp(aimBuffer, "DRG_Cycling"                 ) == 0) { DRG_Cycling           = stringToUint8(tmpString); }
          else if(strcmp(aimBuffer, "DM_Cycling"                  ) == 0) { DM_Cycling            = stringToUint8(tmpString); }
          else if(strcmp(aimBuffer, "SI_All"                      ) == 0) { SI_All                = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "LongPressM"                  ) == 0) { LongPressM            = stringToUint8(tmpString); }                  //10000003
          else if(strcmp(aimBuffer, "LongPressF"                  ) == 0) { LongPressF            = stringToUint8(tmpString); }                  //10000003
          else if(strcmp(aimBuffer, "lastIntegerBase"             ) == 0) { lastIntegerBase       = stringToUint8(tmpString); }                  //10000004
          else if(strcmp(aimBuffer, "lrChosen"                    ) == 0) { lrChosen              = stringToUint16(tmpString);}
          else if(strcmp(aimBuffer, "graph_xmin"                  ) == 0) { graph_xmin            = stringToFloat(tmpString); }
          else if(strcmp(aimBuffer, "graph_xmax"                  ) == 0) { graph_xmax            = stringToFloat(tmpString); }
          else if(strcmp(aimBuffer, "graph_ymin"                  ) == 0) { graph_ymin            = stringToFloat(tmpString); }
          else if(strcmp(aimBuffer, "graph_ymax"                  ) == 0) { graph_ymax            = stringToFloat(tmpString); }
          else if(strcmp(aimBuffer, "graph_dx"                    ) == 0) { graph_dx              = stringToFloat(tmpString); }
          else if(strcmp(aimBuffer, "graph_dy"                    ) == 0) { graph_dy              = stringToFloat(tmpString); }
          else if(strcmp(aimBuffer, "roundedTicks"                ) == 0) { roundedTicks          = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "extentx"                     ) == 0) { extentx               = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "extenty"                     ) == 0) { extenty               = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "PLOT_VECT"                   ) == 0) { PLOT_VECT             = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "PLOT_NVECT"                  ) == 0) { PLOT_NVECT            = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "PLOT_SCALE"                  ) == 0) { PLOT_SCALE            = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "PLOT_LINE"                   ) == 0) { PLOT_LINE             = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "PLOT_CROSS"                  ) == 0) { PLOT_CROSS            = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "PLOT_BOX"                    ) == 0) { PLOT_BOX              = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "PLOT_INTG"                   ) == 0) { PLOT_INTG             = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "PLOT_DIFF"                   ) == 0) { PLOT_DIFF             = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "PLOT_RMS"                    ) == 0) { PLOT_RMS              = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "PLOT_SHADE"                  ) == 0) { PLOT_SHADE            = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "PLOT_AXIS"                   ) == 0) { PLOT_AXIS             = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "PLOT_ZMX"                    ) == 0) { PLOT_ZMX              = stringToUint8(tmpString); }
          else if(strcmp(aimBuffer, "PLOT_ZMY"                    ) == 0) { PLOT_ZMY              = stringToUint8(tmpString); }
          else if(strcmp(aimBuffer, "PLOT_CPXPLOT"                ) == 0) { PLOT_CPXPLOT          = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "jm_LARGELI"                  ) == 0) {
            if(loadedVersion < 10000012) {
              if((bool_t)stringToUint8(tmpString) != 0) {
                setSystemFlag(FLAG_LARGELI);
                }
              else {
                clearSystemFlag(FLAG_LARGELI);
              }
            } //Keep compatible by repeating, even though setting is now in systemflags
          }
          else if(strcmp(aimBuffer, "constantFractions"           ) == 0) { 
            if(loadedVersion < 10000012) {
              if((bool_t)stringToUint8(tmpString) != 0) {
                setSystemFlag(FLAG_IRFRAC);
                }
              else {
                clearSystemFlag(FLAG_IRFRAC);
              }
            } //Keep compatible by repeating, even though setting is now in systemflags
          }
          else if(strcmp(aimBuffer, "constantFractionsOn"         ) == 0) {
            if(loadedVersion < 10000012) {
              if((bool_t)stringToUint8(tmpString) != 0) {
                setSystemFlag(FLAG_IRF_ON);
              }
              else {
                clearSystemFlag(FLAG_IRF_ON);
              }
            } //Keep compatible by repeating, even though setting is now in systemflags
          }
          else if(strcmp(aimBuffer, "eRPN"                        ) == 0) {
            if(loadedVersion < 10000012) {
              if((bool_t)stringToUint8(tmpString) != 0) {
                setSystemFlag(FLAG_ERPN);
                }
              else {
                clearSystemFlag(FLAG_ERPN);
              }
            } //Keep compatible by repeating, even though setting is now in systemflags
          }
          else if(strcmp(aimBuffer, "CPXMult"                     ) == 0) {
            if(loadedVersion < 10000012) {
              if((bool_t)stringToUint8(tmpString) != 0) {
                setSystemFlag(FLAG_CPXMULT);
                }
              else {
                clearSystemFlag(FLAG_CPXMULT);
              }
            } //Keep compatible by repeating, even though setting is now in systemflags
          }

          hourGlassIconEnabled = false;

        }
      i++;
      }
      hourGlassIconEnabled = false;
      return false; //Signal that this was the last section loaded and no more sections to follow
      #if defined(LOADDEBUG)
        debugPrintf(17, "END1", "");
      #endif // LOADDEBUG
    }
    hourGlassIconEnabled = false;
    return true; //Signal to continue loading the next section
    #if defined(LOADDEBUG)
      debugPrintf(18, "END2", "");
    #endif // LOADDEBUG
  }
#endif // !TESTSUITE_BUILD




void doLoad(uint16_t loadMode, uint16_t s, uint16_t n, uint16_t d, uint16_t loadType) {
  #if !defined(TESTSUITE_BUILD)
  ioFilePath_t path;
  int ret;
    #if defined(LOADDEBUG)
      char yy[10];
      sprintf(yy, "%d",loadMode);
      debugPrintf(-1, "LoadMode", yy);
    #endif // LOADDEBUG

  if(loadType == autoLoad) {
    path = ioPathAutoSave;
  }
  else if(loadType == manualLoad) {
    path = ioPathManualSave;
  }
  else {
    path = ioPathLoadStateFile;
  }

  ret = ioFileOpen(path, ioModeRead);

  if(ret != FILE_OK ) {
    if(ret == FILE_CANCEL ) {
      return;
    }
    else {
      displayCalcErrorMessage(ERROR_CANNOT_READ_FILE, ERR_REGISTER_LINE, REGISTER_X);
      return;
    }
  }

  if(loadMode == LM_ALL) {
    while(currentSubroutineLevel > 0) {
      fnReturn(0);
    }
  }


  // SAVE_FILE_REVISION
  // 0
  // C43_save_file_00
  // 10000003

  // Allow older versions for autoloaded sav file
  //  while doing no check on manual loading. This may allow manual loading of older files at risk
  loadedVersion = 0;
  {
    readLine(tmpString);
    if(strcmp(tmpString, "SAVE_FILE_REVISION") == 0) {
      readLine(aimBuffer); // internal rev number (ignore now)
      readLine(aimBuffer); // param
      readLine(tmpString); // value
      if(strcmp(aimBuffer, "C43_save_file_00") == 0) {
        loadedVersion = stringToUint32(tmpString);
        if(loadedVersion < 10000000 || loadedVersion > 20000000) {
          loadedVersion = 0;
        }
      }
    }
  }

  if((((loadType == manualLoad) || (loadType == stateLoad)) && loadMode == LM_ALL) ||
    ((loadType == autoLoad) && (loadedVersion >= VersionAllowed) && (loadedVersion <= configFileVersion) && (loadMode == LM_ALL) )) {
    while(restoreOneSection(loadMode, s, n, d)) {
    }
  }


  lastErrorCode = ERROR_NONE;

  ioFileClose();

    //-------------------------------------------------------------------------------------------------
  // This is where user is informed about versions incompatibilities and changes to loaded data occur
  // The code  below is an example of a version mismatch handling
  // The string passed to show_warning() can be the same if it fits on the HW display (7 lines of ~32
  // characters and standard ASCII characters), or two differents strings can used as shown below
  //-------------------------------------------------------------------------------------------------
  //
  //Code example:
  //
  //if(loadMode == LM_ALL) {
  //  if(loadedVersion <= 88) { // Program incompatibility
  //  #if defined(PC_BUILD)
  //    sprintf(tmpString,"****Program binary incompatibility****\n"
  //                      "x→α now followed by a destination register\n"
  //                      "Loaded x→α in RAM will be replaced by NOP\n"
  //                      "CAVEAT: x→α in Flash will not be replaced so it may cause crash\n");
  //  #endif // PC_BUILD
  //  #if defined(DMCP_BUILD)
  //    sprintf(tmpString,"**Program binary incompatibility**\n"
  //                      "x->a now uses a destination register\n"
  //                      "x->a in RAM will be replaced by NOP\n"
  //                      "CAVEAT: x->a in Flash will not be\n"
  //                      "replaced so it may cause crash\n");
  //  #endif // DMCP_BUILD
  //  #if !defined(TESTSUITE_BUILD)
  //    show_warning(tmpString);
  //  #endif // TESTSUITE_BUILD
  //
  //    int globalStep = 1;
  //    uint8_t *step = beginOfProgramMemory;
  //
  //    while(!isAtEndOfPrograms(step)) { // .END.
  //      if(checkOpCodeOfStep(step, ITM_XtoALPHA)) { // x->alpha
  //        step[0] = (ITM_NOP >> 8) | 0x80;
  //        step[1] =  ITM_NOP       & 0xff;
  //        printf("x→α found at global step %d\n", globalStep);
  //      }
  //      ++globalStep;
  //      step = findNextStep(step);
  //    }
  //  }
  //}

  #if defined(DMCP_BUILD)
    sys_timer_disable(TIMER_IDX_REFRESH_SLEEP);
    sys_timer_start(TIMER_IDX_REFRESH_SLEEP,1000);
    fnTimerStart(TO_KB_ACTV, TO_KB_ACTV, JM_TO_KB_ACTV); //PROGRAM_KB_ACTV
  #endif // DMCP_BUILD


  #if !defined(TESTSUITE_BUILD)
    if(loadType == manualLoad && loadMode == LM_ALL) {
      temporaryInformation = TI_BACKUP_RESTORED;
      getDateString(lastStateFileOpened);
      strcat(lastStateFileOpened,": ");
      stringAppend(lastStateFileOpened + stringByteLength(lastStateFileOpened), fileNameSelected);
    }
    else if((loadType == autoLoad) && (loadedVersion >= VersionAllowed) && (loadedVersion <= configFileVersion) && (loadMode == LM_ALL)) {
      temporaryInformation = TI_BACKUP_RESTORED;
      getDateString(lastStateFileOpened);
      strcat(lastStateFileOpened,": ");
      stringAppend(lastStateFileOpened + stringByteLength(lastStateFileOpened), fileNameSelected);
    }
    else if(loadType == stateLoad) {
      temporaryInformation = TI_STATEFILE_RESTORED;
      getDateString(lastStateFileOpened);
      strcat(lastStateFileOpened,": ");
      stringAppend(lastStateFileOpened + stringByteLength(lastStateFileOpened), fileNameSelected);
    }
    else if(loadMode == LM_PROGRAMS) {
      temporaryInformation = TI_PROGRAMS_RESTORED;
    }
    else if(loadMode == LM_REGISTERS) {
      temporaryInformation = TI_REGISTERS_RESTORED;
    }
    else if(loadMode == LM_REGISTERS) {
      temporaryInformation = TI_REGISTERS_RESTORED;
    }
    else if(loadMode == LM_SYSTEM_STATE) {
      temporaryInformation = TI_SETTINGS_RESTORED;
    }
    else if(loadMode == LM_SUMS) {
      temporaryInformation = TI_SUMS_RESTORED;
    }
    else if(loadMode == LM_NAMED_VARIABLES) {
      temporaryInformation = TI_VARIABLES_RESTORED;
    }
    cachedDynamicMenu = 0;
  #endif // !TESTSUITE_BUILD
#endif // !TESTSUITE_BUILD
}



void fnLoad(uint16_t loadMode) {
  printStatus(0, errorMessages[LOADING_STATE_FILE],force);
  if(loadMode == LM_STATE_LOAD) {
    doLoad(LM_ALL, 0, 0, 0, stateLoad);
  }
  else {
    doLoad(loadMode, 0, 0, 0, manualLoad);
  }
  fnClearFlag(FLAG_USER);
  doRefreshSoftMenu = true;
  refreshScreen(94);
}

void fnLoadAuto(void) {
  doLoad(LM_ALL, 0, 0, 0, autoLoad);
  fnClearFlag(FLAG_USER);
  doRefreshSoftMenu = true;
  refreshScreen(95);
}


void fnLoadedFile (uint16_t unusedButMandatoryParameter) {
  liftStack();

  int16_t len = stringByteLength(lastStateFileOpened) + 1;
  reallocateRegister(REGISTER_X, dtString, TO_BLOCKS(len), amNone);
  xcopy(REGISTER_STRING_DATA(REGISTER_X), lastStateFileOpened , len);
  temporaryInformation = TI_LASTSTATEFILE;
}



#undef BACKUP

void fnDeleteBackup(uint16_t confirmation) {
  if(confirmation == NOT_CONFIRMED) {
    setConfirmationMode(fnDeleteBackup);
  }
  else {
    #if defined(DMCP_BUILD)
      FRESULT result;
      sys_disk_write_enable(1);
      result = f_unlink("SAVFILES\\C47.sav");
      if(result != FR_OK && result != FR_NO_FILE && result != FR_NO_PATH) {
        displayCalcErrorMessage(ERROR_IO, ERR_REGISTER_LINE, REGISTER_X);
      }
      result = f_unlink("SAVFILES\\C47auto.sav");
      if(result != FR_OK && result != FR_NO_FILE && result != FR_NO_PATH) {
        displayCalcErrorMessage(ERROR_IO, ERR_REGISTER_LINE, REGISTER_X);
      }
      sys_disk_write_enable(0);
    #else // !DMCP_BUILD
      int result = remove("SAVFILES/C47.sav");
      if(result == -1) {
        #if !defined(TESTSUITE_BUILD)
          int e = errno;
          if(e != ENOENT) {
            displayCalcErrorMessage(ERROR_IO, ERR_REGISTER_LINE, REGISTER_X);
            #if (EXTRA_INFO_ON_CALC_ERROR == 1)
              sprintf(errorMessage, "removing the backup failed with error code %d", e);
              moreInfoOnError("In function fnDeleteBackup:", errorMessage, NULL, NULL);
            #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
          }
        #endif // !TESTSUITE_BUILD
      }
    #endif // DMCP_BUILD
  }
}

