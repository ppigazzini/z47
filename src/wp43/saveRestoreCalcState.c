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
#include "c43Extensions/xeqm.h"
#include "c43Extensions/jm.h"
#include "c43Extensions/radioButtonCatalog.h"
#include "curveFitting.h"
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

#include "wp43.h"
#define BACKUP_VERSION                     787  // Change bestf
#define OLDEST_COMPATIBLE_BACKUP_VERSION   779  // save running app
#define configFileVersion                  10000008 // New STOCFG and new STATE file; arbitrary starting point version 10 000 001. Allowable values are 10000000 to 20000000
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

#if !defined(TESTSUITE_BUILD)
  #define START_REGISTER_VALUE 1000  // was 1522, why?
  static uint32_t loadedVersion = 0;
#endif //TESTSUITE_BUILD
  uint16_t flushBufferCnt = 0;


#if !defined(TESTSUITE_BUILD)
  static char *tmpRegisterString = NULL;

  static void save(const void *buffer, uint32_t size) {
    ioFileWrite(buffer, size);
  }
#endif //TESTSUITE_BUILD


static uint32_t restore(void *buffer, uint32_t size) {
  return ioFileRead(buffer, size);
}



#if defined(PC_BUILD)
  void saveCalc(void) {
//    uint8_t  compatibility_u8 = 0;           //defaults to use when settings are removed
    bool_t   compatibility_bool = false;     //defaults to use when settings are removed
    uint32_t backupVersion = BACKUP_VERSION;
    uint32_t ramSize       = RAM_SIZE;
    uint32_t ramPtr;
    int ret;

    ret = ioFileOpen(ioPathBackup, ioModeWrite);

    if(ret != FILE_OK ) {
      if(ret == FILE_CANCEL ) {
        return;
      }
      else {
        printf("Cannot save calc's memory in file backup.bin!\n");
        exit(0);
      }
    }

    if(calcMode == CM_CONFIRMATION) {
      calcMode = previousCalcMode;
      refreshScreen();
    }

    printf("Begin of calc's backup\n");

    save(&backupVersion,                      sizeof(backupVersion));
    save(&ramSize,                            sizeof(ramSize));
    save(ram,                                 TO_BYTES(RAM_SIZE));
    save(freeMemoryRegions,                   sizeof(freeMemoryRegions));
    save(&numberOfFreeMemoryRegions,          sizeof(numberOfFreeMemoryRegions));
    save(globalFlags,                         sizeof(globalFlags));
    save(errorMessage,                        ERROR_MESSAGE_LENGTH);
    save(aimBuffer,                           AIM_BUFFER_LENGTH);
    save(nimBufferDisplay,                    NIM_BUFFER_LENGTH);
    save(tamBuffer,                           TAM_BUFFER_LENGTH);
    save(asmBuffer,                           sizeof(asmBuffer));
    save(oldTime,                             sizeof(oldTime));
    save(dateTimeString,                      sizeof(dateTimeString));
    save(softmenuStack,                       sizeof(softmenuStack));
    save(globalRegister,                      sizeof(globalRegister));
    save(savedStackRegister,                  sizeof(savedStackRegister));
    save(kbd_usr,                             sizeof(kbd_usr));
    save(userMenuItems,                       sizeof(userMenuItems));
    save(userAlphaItems,                      sizeof(userAlphaItems));
    save(&tam.mode,                           sizeof(tam.mode));
    save(&tam.function,                       sizeof(tam.function));
    save(&tam.alpha,                          sizeof(tam.alpha));
    save(&tam.currentOperation,               sizeof(tam.currentOperation));
    save(&tam.dot,                            sizeof(tam.dot));
    save(&tam.indirect,                       sizeof(tam.indirect));
    save(&tam.digitsSoFar,                    sizeof(tam.digitsSoFar));
    save(&tam.value,                          sizeof(tam.value));
    save(&tam.min,                            sizeof(tam.min));
    save(&tam.max,                            sizeof(tam.max));
    save(&rbrRegister,                        sizeof(rbrRegister));
    save(&numberOfNamedVariables,             sizeof(numberOfNamedVariables));
    ramPtr = TO_WP43MEMPTR(allNamedVariables);
    save(&ramPtr,                             sizeof(ramPtr));
    ramPtr = TO_WP43MEMPTR(allFormulae);
    save(&ramPtr,                             sizeof(ramPtr));
    ramPtr = TO_WP43MEMPTR(userMenus);
    save(&ramPtr,                             sizeof(ramPtr));
    ramPtr = TO_WP43MEMPTR(userKeyLabel);
    save(&ramPtr,                             sizeof(ramPtr));
    ramPtr = TO_WP43MEMPTR(statisticalSumsPointer);
    save(&ramPtr,                             sizeof(ramPtr));
    ramPtr = TO_WP43MEMPTR(savedStatisticalSumsPointer);
    save(&ramPtr,                             sizeof(ramPtr));
    ramPtr = TO_WP43MEMPTR(labelList);
    save(&ramPtr,                             sizeof(ramPtr));
    ramPtr = TO_WP43MEMPTR(programList);
    save(&ramPtr,                             sizeof(ramPtr));
    ramPtr = TO_WP43MEMPTR(currentSubroutineLevelData);
    save(&ramPtr,                             sizeof(ramPtr));
    save(&xCursor,                            sizeof(xCursor));
    save(&yCursor,                            sizeof(yCursor));
    save(&firstGregorianDay,                  sizeof(firstGregorianDay));
    save(&denMax,                             sizeof(denMax));
    save(&lastDenominator,                    sizeof(lastDenominator));
    save(&currentRegisterBrowserScreen,       sizeof(currentRegisterBrowserScreen));
    save(&currentFntScr,                      sizeof(currentFntScr));
    save(&currentFlgScr,                      sizeof(currentFlgScr));
    save(&displayFormat,                      sizeof(displayFormat));
    save(&displayFormatDigits,                sizeof(displayFormatDigits));
    save(&timeDisplayFormatDigits,            sizeof(timeDisplayFormatDigits));
    save(&shortIntegerWordSize,               sizeof(shortIntegerWordSize));
    save(&significantDigits,                  sizeof(significantDigits));
    save(&shortIntegerMode,                   sizeof(shortIntegerMode));
    save(&currentAngularMode,                 sizeof(currentAngularMode));
    save(&scrLock,                            sizeof(scrLock));
    save(&roundingMode,                       sizeof(roundingMode));
    save(&calcMode,                           sizeof(calcMode));
    save(&nextChar,                           sizeof(nextChar));
    save(&alphaCase,                          sizeof(alphaCase));
    save(&hourGlassIconEnabled,               sizeof(hourGlassIconEnabled));
    save(&watchIconEnabled,                   sizeof(watchIconEnabled));
    save(&serialIOIconEnabled,                sizeof(serialIOIconEnabled));
    save(&printerIconEnabled,                 sizeof(printerIconEnabled));
    save(&programRunStop,                     sizeof(programRunStop));
    save(&entryStatus,                        sizeof(entryStatus));
    save(&cursorEnabled,                      sizeof(cursorEnabled));
    save(&cursorFont,                         sizeof(cursorFont));
    save(&rbr1stDigit,                        sizeof(rbr1stDigit));
    save(&shiftF,                             sizeof(shiftF));
    save(&shiftG,                             sizeof(shiftG));
    save(&rbrMode,                            sizeof(rbrMode));
    save(&showContent,                        sizeof(showContent));
    save(&numScreensNumericFont,              sizeof(numScreensNumericFont));
    save(&numLinesNumericFont,                sizeof(numLinesNumericFont));
    save(&numLinesStandardFont,               sizeof(numLinesStandardFont));
    save(&numScreensStandardFont,             sizeof(numScreensStandardFont));
    save(&previousCalcMode,                   sizeof(previousCalcMode));
    save(&lastErrorCode,                      sizeof(lastErrorCode));
    save(&nimNumberPart,                      sizeof(nimNumberPart));
    save(&displayStack,                       sizeof(displayStack));
    save(&hexDigits,                          sizeof(hexDigits));
    save(&errorMessageRegisterLine,           sizeof(errorMessageRegisterLine));
    save(&shortIntegerMask,                   sizeof(shortIntegerMask));
    save(&shortIntegerSignBit,                sizeof(shortIntegerSignBit));
    save(&temporaryInformation,               sizeof(temporaryInformation));
    save(&glyphNotFound,                      sizeof(glyphNotFound));
    save(&funcOK,                             sizeof(funcOK));
    save(&screenChange,                       sizeof(screenChange));
    save(&exponentSignLocation,               sizeof(exponentSignLocation));
    save(&denominatorLocation,                sizeof(denominatorLocation));
    save(&imaginaryExponentSignLocation,      sizeof(imaginaryExponentSignLocation));
    save(&imaginaryMantissaSignLocation,      sizeof(imaginaryMantissaSignLocation));
    save(&lineTWidth,                         sizeof(lineTWidth));
    save(&lastIntegerBase,                    sizeof(lastIntegerBase));
    save(&wp43MemInBlocks,                    sizeof(wp43MemInBlocks));
    save(&gmpMemInBytes,                      sizeof(gmpMemInBytes));
    save(&catalog,                            sizeof(catalog));
    save(&lastCatalogPosition,                sizeof(lastCatalogPosition));
    save(&lgCatalogSelection,                 sizeof(lgCatalogSelection));
    save(displayValueX,                       sizeof(displayValueX));
    save(&pcg32_global,                       sizeof(pcg32_global));
    save(&exponentLimit,                      sizeof(exponentLimit));
    save(&exponentHideLimit,                  sizeof(exponentHideLimit));
    save(&keyActionProcessed,                 sizeof(keyActionProcessed));
    save(&systemFlags,                        sizeof(systemFlags));
    save(&savedSystemFlags,                   sizeof(savedSystemFlags));
    save(&thereIsSomethingToUndo,             sizeof(thereIsSomethingToUndo));
    ramPtr = TO_WP43MEMPTR(beginOfProgramMemory);
    save(&ramPtr,                             sizeof(ramPtr)); // beginOfProgramMemory pointer to block
    ramPtr = (uint32_t)((void *)beginOfProgramMemory -        TO_PCMEMPTR(TO_WP43MEMPTR(beginOfProgramMemory)));
    save(&ramPtr,                             sizeof(ramPtr)); // beginOfProgramMemory offset within block
    ramPtr = TO_WP43MEMPTR(firstFreeProgramByte);
    save(&ramPtr,                             sizeof(ramPtr)); // firstFreeProgramByte pointer to block
    ramPtr = (uint32_t)((void *)firstFreeProgramByte - TO_PCMEMPTR(TO_WP43MEMPTR(firstFreeProgramByte)));
    save(&ramPtr,                             sizeof(ramPtr)); // firstFreeProgramByte offset within block
    ramPtr = TO_WP43MEMPTR(firstDisplayedStep);
    save(&ramPtr,                             sizeof(ramPtr)); // firstDisplayedStep pointer to block
    ramPtr = (uint32_t)((void *)firstDisplayedStep - TO_PCMEMPTR(TO_WP43MEMPTR(firstDisplayedStep)));
    save(&ramPtr,                             sizeof(ramPtr)); // firstDisplayedStep offset within block
    ramPtr = TO_WP43MEMPTR(currentStep);
    save(&ramPtr,                             sizeof(ramPtr)); // currentStep pointer to block
    ramPtr = (uint32_t)((void *)currentStep - TO_PCMEMPTR(TO_WP43MEMPTR(currentStep)));
    save(&ramPtr,                             sizeof(ramPtr)); // currentStep offset within block
    save(&freeProgramBytes,                   sizeof(freeProgramBytes));
    save(&firstDisplayedLocalStepNumber,      sizeof(firstDisplayedLocalStepNumber));
    save(&numberOfLabels,                     sizeof(numberOfLabels));
    save(&numberOfPrograms,                   sizeof(numberOfPrograms));
    save(&currentLocalStepNumber,             sizeof(currentLocalStepNumber));
    save(&currentProgramNumber,               sizeof(currentProgramNumber));
    save(&lastProgramListEnd,                 sizeof(lastProgramListEnd));
    save(&programListEnd,                     sizeof(programListEnd));
    save(&allSubroutineLevels,                sizeof(allSubroutineLevels));
    save(&pemCursorIsZerothStep,              sizeof(pemCursorIsZerothStep));
    save(&numberOfTamMenusToPop,              sizeof(numberOfTamMenusToPop));
    save(&lrSelection,                        sizeof(lrSelection));
    save(&lrSelectionUndo,                    sizeof(lrSelectionUndo));
    save(&lrChosen,                           sizeof(lrChosen));
    save(&lrChosenUndo,                       sizeof(lrChosenUndo));
    save(&lastPlotMode,                       sizeof(lastPlotMode));
    save(&plotSelection,                      sizeof(plotSelection));

    save(&graph_dx,                           sizeof(graph_dx));
    save(&graph_dy,                           sizeof(graph_dy));
    save(&roundedTicks,                       sizeof(roundedTicks));
    save(&extentx,                            sizeof(extentx));
    save(&extenty,                            sizeof(extenty));
    save(&PLOT_VECT,                          sizeof(PLOT_VECT));
    save(&PLOT_NVECT,                         sizeof(PLOT_NVECT));
    save(&PLOT_SCALE,                         sizeof(PLOT_SCALE));
    save(&Aspect_Square,                      sizeof(Aspect_Square));
    save(&PLOT_LINE,                          sizeof(PLOT_LINE));
    save(&PLOT_CROSS,                         sizeof(PLOT_CROSS));
    save(&PLOT_BOX,                           sizeof(PLOT_BOX));
    save(&PLOT_INTG,                          sizeof(PLOT_INTG));
    save(&PLOT_DIFF,                          sizeof(PLOT_DIFF));
    save(&PLOT_RMS,                           sizeof(PLOT_RMS));
    save(&PLOT_SHADE,                         sizeof(PLOT_SHADE));
    save(&PLOT_AXIS,                          sizeof(PLOT_AXIS));
    save(&PLOT_ZMX,                           sizeof(PLOT_ZMX));
    save(&PLOT_ZMY,                           sizeof(PLOT_ZMY));
    save(&PLOT_ZOOM,                          sizeof(PLOT_ZOOM));
    save(&plotmode,                           sizeof(plotmode));
    save(&tick_int_x,                         sizeof(tick_int_x));
    save(&tick_int_y,                         sizeof(tick_int_y));
    save(&x_min,                              sizeof(x_min));
    save(&x_max,                              sizeof(x_max));
    save(&y_min,                              sizeof(y_min));
    save(&y_max,                              sizeof(y_max));
    save(&xzero,                              sizeof(xzero));
    save(&yzero,                              sizeof(yzero));
    save(&matrixIndex,                        sizeof(matrixIndex));
    save(&currentViewRegister,                sizeof(currentViewRegister));
    save(&currentSolverStatus,                sizeof(currentSolverStatus));
    save(&currentSolverProgram,               sizeof(currentSolverProgram));
    save(&currentSolverVariable,              sizeof(currentSolverVariable));
    save(&numberOfFormulae,                   sizeof(numberOfFormulae));
    save(&currentFormula,                     sizeof(currentFormula));
    save(&numberOfUserMenus,                  sizeof(numberOfUserMenus));
    save(&currentUserMenu,                    sizeof(currentUserMenu));
    save(&userKeyLabelSize,                   sizeof(userKeyLabelSize));
    save(&timerCraAndDeciseconds,             sizeof(timerCraAndDeciseconds));
    save(&timerValue,                         sizeof(timerValue));
    save(&timerTotalTime,                     sizeof(timerTotalTime));
    save(&currentInputVariable,               sizeof(currentInputVariable));
    save(&SAVED_SIGMA_LASTX,                  sizeof(SAVED_SIGMA_LASTX));
    save(&SAVED_SIGMA_LASTY,                  sizeof(SAVED_SIGMA_LASTY));
    save(&SAVED_SIGMA_LAct,                   sizeof(SAVED_SIGMA_LAct));
    save(&currentMvarLabel,                   sizeof(currentMvarLabel));
    save(&graphVariable,                      sizeof(graphVariable));
    save(&plotStatMx,                         sizeof(plotStatMx));
    save(&drawHistogram,                      sizeof(drawHistogram));
    save(&statMx,                             sizeof(statMx));
    save(&lrSelectionHistobackup,             sizeof(lrSelectionHistobackup));
    save(&lrChosenHistobackup,                sizeof(lrChosenHistobackup));
    save(&loBinR,                             sizeof(loBinR));
    save(&nBins ,                             sizeof(nBins ));
    save(&hiBinR,                             sizeof(hiBinR));
    save(&histElementXorY,                    sizeof(histElementXorY));

    save(&screenUpdatingMode,                 sizeof(screenUpdatingMode));
    for(int y = 0; y < SCREEN_HEIGHT; ++y) {
      uint8_t bmpdata = 0;
      for(int x = 0; x < SCREEN_WIDTH; ++x) {
        bmpdata <<= 1;
        if(*(screenData + y*screenStride + x) == ON_PIXEL) {
          bmpdata |= 1;
        }
        if((x % 8) == 7) {
          save(&bmpdata,                      sizeof(bmpdata));
          bmpdata = 0;
        }
      }
    }

    save(&eRPN,                               sizeof(eRPN));                      //JM vv
    save(&HOME3,                              sizeof(HOME3));
    save(&ShiftTimoutMode,                    sizeof(ShiftTimoutMode));
    save(&CPXMULT,                            sizeof(CPXMULT));                   //JM
    save(&fgLN,                               sizeof(fgLN));
    save(&BASE_HOME,                          sizeof(BASE_HOME));
    save(&Norm_Key_00_VAR,                    sizeof(Norm_Key_00_VAR));
    save(&Input_Default,                      sizeof(Input_Default));
    save(&compatibility_bool,                 sizeof(compatibility_bool));        //EXTRA
    save(&BASE_MYM,                           sizeof(BASE_MYM));
    save(&jm_G_DOUBLETAP,                     sizeof(jm_G_DOUBLETAP));
    save(&compatibility_bool,                 sizeof(compatibility_bool));              //EXTRA
    save(&graph_xmin,                         sizeof(graph_xmin));
    save(&graph_xmax,                         sizeof(graph_xmax));
    save(&graph_ymin,                         sizeof(graph_ymin));
    save(&graph_ymax,                         sizeof(graph_ymax));
    save(&jm_LARGELI,                         sizeof(jm_LARGELI));
    save(&constantFractions,                  sizeof(constantFractions));
    save(&constantFractionsMode,              sizeof(constantFractionsMode));
    save(&constantFractionsOn,                sizeof(constantFractionsOn));
    save(&running_program_jm,                 sizeof(running_program_jm));
    save(&indic_x,                            sizeof(indic_x));
    save(&indic_y,                            sizeof(indic_y));
    save(&fnXEQMENUpos,                       sizeof(fnXEQMENUpos));
    save(&indexOfItemsXEQM,                   sizeof(indexOfItemsXEQM));
    save(&T_cursorPos,                        sizeof(T_cursorPos));               //JM ^^
    save(&SHOWregis,                          sizeof(SHOWregis));                 //JM ^^
    save(&mm_MNU_HOME,                        sizeof(mm_MNU_HOME));               //JM ^^
    save(&mm_MNU_ALPHA,                       sizeof(mm_MNU_ALPHA));              //JM ^^
    save(&displayStackSHOIDISP,               sizeof(displayStackSHOIDISP));      //JM ^^
    save(&ListXYposition,                     sizeof(ListXYposition));            //JM ^^
    save(&numLock,                            sizeof(numLock));                   //JM ^^
    save(&DRG_Cycling,                        sizeof(DRG_Cycling));               //JM
    save(&lastFlgScr,                         sizeof(lastFlgScr));                //C43 JM
    save(&displayAIMbufferoffset,             sizeof(displayAIMbufferoffset));    //C43 JM
    save(&bcdDisplay,                         sizeof(bcdDisplay));                //C43 JM
    save(&topHex,                             sizeof(topHex));                    //C43 JM
    save(&bcdDisplaySign,                     sizeof(bcdDisplaySign));            //C43 JM
    save(&DM_Cycling,                         sizeof(DM_Cycling));                //JM
    save(&SI_All,                             sizeof(SI_All));                    //JM
    save(&LongPressM,                         sizeof(LongPressM));                //JM
    save(&LongPressF,                         sizeof(LongPressF));                //JM
    save(&currentAsnScr,                      sizeof(currentAsnScr));             //JM

    save(&gapItemLeft,                        sizeof(gapItemLeft));               //JM
    save(&gapItemRight,                       sizeof(gapItemRight));              //JM
    save(&gapItemRadix,                       sizeof(gapItemRadix));              //JM
    save(&grpGroupingLeft,                    sizeof(grpGroupingLeft));           //JM
    save(&grpGroupingGr1LeftOverflow,         sizeof(grpGroupingGr1LeftOverflow));//JM
    save(&grpGroupingGr1Left,                 sizeof(grpGroupingGr1Left));        //JM
    save(&grpGroupingRight,                   sizeof(grpGroupingRight));          //JM
    save(&MYM3,                               sizeof(MYM3));

    ioFileClose();
    printf("End of calc's backup\n");
  }



  void restoreCalc(void) {
    printf("RestoreCalc\n");
//    uint8_t  compatibility_u8;        //defaults to use when settings are removed
      bool_t   compatibility_bool;      //defaults to use when settings are removed
    uint32_t backupVersion, ramSize, ramPtr;
    int ret;
    uint8_t *loadedScreen = malloc(SCREEN_WIDTH * SCREEN_HEIGHT / 8);

    doFnReset(CONFIRMED, loadAutoSav);
    ret = ioFileOpen(ioPathBackup, ioModeRead);

    if(ret != FILE_OK ) {
      if(ret == FILE_CANCEL ) {
        return;
      }
      else {
        printf("Cannot restore calc's memory from file backup.bin! Performing RESET\n");
        refreshScreen();
        return;
      }
    }

    restore(&backupVersion,                      sizeof(backupVersion));
    cachedDynamicMenu = 0;
    if(backupVersion < 781) {
      configCommon(CFG_DFLT);
    }
    restore(&ramSize,                            sizeof(ramSize));
    if(backupVersion > BACKUP_VERSION || backupVersion < OLDEST_COMPATIBLE_BACKUP_VERSION || ramSize != RAM_SIZE) {
      ioFileClose();
      refreshScreen();

      printf("Cannot restore calc's memory from file backup.bin! File backup.bin is from incompatible backup version.\n");
      printf("               Backup file      Program\n");
      printf("backupVersion  %6u           %6d\n", backupVersion, BACKUP_VERSION);
      printf("ramSize blocks %6u           %6d\n", ramSize, RAM_SIZE);
      printf("ramSize bytes  %6u           %6d\n", TO_BYTES(ramSize), TO_BYTES(RAM_SIZE));
      return;
    }
    else {
      printf("Begin of calc's restoration\n");

      restore(ram,                                 TO_BYTES(RAM_SIZE));
      restore(freeMemoryRegions,                   sizeof(freeMemoryRegions));
      restore(&numberOfFreeMemoryRegions,          sizeof(numberOfFreeMemoryRegions));
      restore(globalFlags,                         sizeof(globalFlags));
      restore(errorMessage,                        ERROR_MESSAGE_LENGTH);
      restore(aimBuffer,                           AIM_BUFFER_LENGTH);
      restore(nimBufferDisplay,                    NIM_BUFFER_LENGTH);
      restore(tamBuffer,                           TAM_BUFFER_LENGTH);
      restore(asmBuffer,                           sizeof(asmBuffer));
      restore(oldTime,                             sizeof(oldTime));
      restore(dateTimeString,                      sizeof(dateTimeString));
      restore(softmenuStack,                       sizeof(softmenuStack));
      restore(globalRegister,                      sizeof(globalRegister));
      restore(savedStackRegister,                  sizeof(savedStackRegister));
      restore(kbd_usr,                             sizeof(kbd_usr));
      restore(userMenuItems,                       sizeof(userMenuItems));
      restore(userAlphaItems,                      sizeof(userAlphaItems));
      restore(&tam.mode,                           sizeof(tam.mode));
      restore(&tam.function,                       sizeof(tam.function));
      restore(&tam.alpha,                          sizeof(tam.alpha));
      restore(&tam.currentOperation,               sizeof(tam.currentOperation));
      restore(&tam.dot,                            sizeof(tam.dot));
      restore(&tam.indirect,                       sizeof(tam.indirect));
      restore(&tam.digitsSoFar,                    sizeof(tam.digitsSoFar));
      restore(&tam.value,                          sizeof(tam.value));
      restore(&tam.min,                            sizeof(tam.min));
      restore(&tam.max,                            sizeof(tam.max));
      restore(&rbrRegister,                        sizeof(rbrRegister));
      restore(&numberOfNamedVariables,             sizeof(numberOfNamedVariables));
      restore(&ramPtr,                             sizeof(ramPtr));
      allNamedVariables = TO_PCMEMPTR(ramPtr);
      restore(&ramPtr,                             sizeof(ramPtr));
      allFormulae = TO_PCMEMPTR(ramPtr);
      restore(&ramPtr,                             sizeof(ramPtr));
      userMenus = TO_PCMEMPTR(ramPtr);
      restore(&ramPtr,                             sizeof(ramPtr));
      userKeyLabel = TO_PCMEMPTR(ramPtr);
      restore(&ramPtr,                             sizeof(ramPtr));
      statisticalSumsPointer = TO_PCMEMPTR(ramPtr);
      restore(&ramPtr,                             sizeof(ramPtr));
      savedStatisticalSumsPointer = TO_PCMEMPTR(ramPtr);
      restore(&ramPtr,                             sizeof(ramPtr));
      labelList = TO_PCMEMPTR(ramPtr);
      if(backupVersion < 782) { // flashLabelList
        restore(&ramPtr,                           sizeof(ramPtr));
      }
      restore(&ramPtr,                             sizeof(ramPtr));
      programList = TO_PCMEMPTR(ramPtr);
      if(backupVersion < 782) { // flashProgramList
        restore(&ramPtr,                           sizeof(ramPtr));
      }
      restore(&ramPtr,                             sizeof(ramPtr));
      currentSubroutineLevelData = TO_PCMEMPTR(ramPtr);
      restore(&xCursor,                            sizeof(xCursor));
      restore(&yCursor,                            sizeof(yCursor));
      restore(&firstGregorianDay,                  sizeof(firstGregorianDay));
      restore(&denMax,                             sizeof(denMax));
      if(backupVersion >= 780) {
        restore(&lastDenominator,                  sizeof(lastDenominator));
      }
      restore(&currentRegisterBrowserScreen,       sizeof(currentRegisterBrowserScreen));
      restore(&currentFntScr,                      sizeof(currentFntScr));
      restore(&currentFlgScr,                      sizeof(currentFlgScr));
      restore(&displayFormat,                      sizeof(displayFormat));
      restore(&displayFormatDigits,                sizeof(displayFormatDigits));
      restore(&timeDisplayFormatDigits,            sizeof(timeDisplayFormatDigits));
      restore(&shortIntegerWordSize,               sizeof(shortIntegerWordSize));
      restore(&significantDigits,                  sizeof(significantDigits));
      restore(&shortIntegerMode,                   sizeof(shortIntegerMode));
      restore(&currentAngularMode,                 sizeof(currentAngularMode));
      restore(&scrLock,                            sizeof(scrLock));
      if(backupVersion < 784) {                                                     //re-using existing old uint8 slot
        scrLock = 0;
      } else {
        scrLock &= 0x03;
      }
      restore(&roundingMode,                       sizeof(roundingMode));
      restore(&calcMode,                           sizeof(calcMode));
      restore(&nextChar,                           sizeof(nextChar));
      restore(&alphaCase,                          sizeof(alphaCase));
      restore(&hourGlassIconEnabled,               sizeof(hourGlassIconEnabled));
      restore(&watchIconEnabled,                   sizeof(watchIconEnabled));
      restore(&serialIOIconEnabled,                sizeof(serialIOIconEnabled));
      restore(&printerIconEnabled,                 sizeof(printerIconEnabled));
      restore(&programRunStop,                     sizeof(programRunStop));
      restore(&entryStatus,                        sizeof(entryStatus));
      restore(&cursorEnabled,                      sizeof(cursorEnabled));
      restore(&cursorFont,                         sizeof(cursorFont));
      restore(&rbr1stDigit,                        sizeof(rbr1stDigit));
      restore(&shiftF,                             sizeof(shiftF));
      restore(&shiftG,                             sizeof(shiftG));
      restore(&rbrMode,                            sizeof(rbrMode));
      restore(&showContent,                        sizeof(showContent));
      restore(&numScreensNumericFont,              sizeof(numScreensNumericFont));
      restore(&numLinesNumericFont,                sizeof(numLinesNumericFont));
      restore(&numLinesStandardFont,               sizeof(numLinesStandardFont));
      restore(&numScreensStandardFont,             sizeof(numScreensStandardFont));
      restore(&previousCalcMode,                   sizeof(previousCalcMode));
      restore(&lastErrorCode,                      sizeof(lastErrorCode));
      restore(&nimNumberPart,                      sizeof(nimNumberPart));
      restore(&displayStack,                       sizeof(displayStack));
      restore(&hexDigits,                          sizeof(hexDigits));
      restore(&errorMessageRegisterLine,           sizeof(errorMessageRegisterLine));
      restore(&shortIntegerMask,                   sizeof(shortIntegerMask));
      restore(&shortIntegerSignBit,                sizeof(shortIntegerSignBit));
      restore(&temporaryInformation,               sizeof(temporaryInformation));

      restore(&glyphNotFound,                      sizeof(glyphNotFound));
      glyphNotFound.data   = malloc(38);
      xcopy(glyphNotFound.data, "\xff\xf8\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\xff\xf8", 38);

      restore(&funcOK,                             sizeof(funcOK));
      restore(&screenChange,                       sizeof(screenChange));
      restore(&exponentSignLocation,               sizeof(exponentSignLocation));
      restore(&denominatorLocation,                sizeof(denominatorLocation));
      restore(&imaginaryExponentSignLocation,      sizeof(imaginaryExponentSignLocation));
      restore(&imaginaryMantissaSignLocation,      sizeof(imaginaryMantissaSignLocation));
      restore(&lineTWidth,                         sizeof(lineTWidth));
      restore(&lastIntegerBase,                    sizeof(lastIntegerBase));
      restore(&wp43MemInBlocks,                    sizeof(wp43MemInBlocks));
      restore(&gmpMemInBytes,                      sizeof(gmpMemInBytes));
      restore(&catalog,                            sizeof(catalog));
      restore(&lastCatalogPosition,                sizeof(lastCatalogPosition));
      restore(&lgCatalogSelection,                 sizeof(lgCatalogSelection));
      restore(displayValueX,                       sizeof(displayValueX));
      restore(&pcg32_global,                       sizeof(pcg32_global));
      restore(&exponentLimit,                      sizeof(exponentLimit));
      restore(&exponentHideLimit,                  sizeof(exponentHideLimit));
      restore(&keyActionProcessed,                 sizeof(keyActionProcessed));
      restore(&systemFlags,                        sizeof(systemFlags));
      restore(&savedSystemFlags,                   sizeof(savedSystemFlags));
      if(backupVersion < 785) {
        defaultStatusBar();
      }
      restore(&thereIsSomethingToUndo,             sizeof(thereIsSomethingToUndo));
      restore(&ramPtr,                             sizeof(ramPtr)); // beginOfProgramMemory pointer to block
      beginOfProgramMemory = TO_PCMEMPTR(ramPtr);
      restore(&ramPtr,                             sizeof(ramPtr)); // beginOfProgramMemory offset within block
      beginOfProgramMemory += ramPtr;
      restore(&ramPtr,                             sizeof(ramPtr)); // firstFreeProgramByte pointer to block
      firstFreeProgramByte = TO_PCMEMPTR(ramPtr);
      restore(&ramPtr,                             sizeof(ramPtr)); // firstFreeProgramByte offset within block
      firstFreeProgramByte += ramPtr;
      restore(&ramPtr,                             sizeof(ramPtr)); // firstDisplayedStep pointer to block
      firstDisplayedStep = TO_PCMEMPTR(ramPtr);
      restore(&ramPtr,                             sizeof(ramPtr)); // firstDisplayedStep offset within block
      firstDisplayedStep += ramPtr;
      restore(&ramPtr,                             sizeof(ramPtr)); // currentStep pointer to block
      currentStep = TO_PCMEMPTR(ramPtr);
      restore(&ramPtr,                             sizeof(ramPtr)); // currentStep offset within block
      currentStep += ramPtr;
      restore(&freeProgramBytes,                   sizeof(freeProgramBytes));
      restore(&firstDisplayedLocalStepNumber,      sizeof(firstDisplayedLocalStepNumber));
      restore(&numberOfLabels,                     sizeof(numberOfLabels));
      if(backupVersion < 782) { // numberOfLabelsInFlash
        restore(&numberOfPrograms,                 sizeof(numberOfPrograms));
      }
      restore(&numberOfPrograms,                   sizeof(numberOfPrograms));
      if(backupVersion < 782) { // numberOfProgramsInFlash
        restore(&currentLocalStepNumber,           sizeof(currentLocalStepNumber));
      }
      restore(&currentLocalStepNumber,             sizeof(currentLocalStepNumber));
      restore(&currentProgramNumber,               sizeof(currentProgramNumber));
      restore(&lastProgramListEnd,                 sizeof(lastProgramListEnd));
      restore(&programListEnd,                     sizeof(programListEnd));
      restore(&allSubroutineLevels,                sizeof(allSubroutineLevels));
      restore(&pemCursorIsZerothStep,              sizeof(pemCursorIsZerothStep));
      restore(&numberOfTamMenusToPop,              sizeof(numberOfTamMenusToPop));
      restore(&lrSelection,                        sizeof(lrSelection));
      restore(&lrSelectionUndo,                    sizeof(lrSelectionUndo));
      restore(&lrChosen,                           sizeof(lrChosen));
      restore(&lrChosenUndo,                       sizeof(lrChosenUndo));
      restore(&lastPlotMode,                       sizeof(lastPlotMode));
      restore(&plotSelection,                      sizeof(plotSelection));

      restore(&graph_dx,                           sizeof(graph_dx));
      restore(&graph_dy,                           sizeof(graph_dy));
      restore(&roundedTicks,                       sizeof(roundedTicks));
      restore(&extentx,                            sizeof(extentx));
      restore(&extenty,                            sizeof(extenty));
      restore(&PLOT_VECT,                          sizeof(PLOT_VECT));
      restore(&PLOT_NVECT,                         sizeof(PLOT_NVECT));
      restore(&PLOT_SCALE,                         sizeof(PLOT_SCALE));
      restore(&Aspect_Square,                      sizeof(Aspect_Square));
      restore(&PLOT_LINE,                          sizeof(PLOT_LINE));
      restore(&PLOT_CROSS,                         sizeof(PLOT_CROSS));
      restore(&PLOT_BOX,                           sizeof(PLOT_BOX));
      restore(&PLOT_INTG,                          sizeof(PLOT_INTG));
      restore(&PLOT_DIFF,                          sizeof(PLOT_DIFF));
      restore(&PLOT_RMS,                           sizeof(PLOT_RMS));
      restore(&PLOT_SHADE,                         sizeof(PLOT_SHADE));
      restore(&PLOT_AXIS,                          sizeof(PLOT_AXIS));
      restore(&PLOT_ZMX,                           sizeof(PLOT_ZMX));
      restore(&PLOT_ZMY,                           sizeof(PLOT_ZMY));
      restore(&PLOT_ZOOM,                          sizeof(PLOT_ZOOM));
      restore(&plotmode,                           sizeof(plotmode));
      restore(&tick_int_x,                         sizeof(tick_int_x));
      restore(&tick_int_y,                         sizeof(tick_int_y));
      restore(&x_min,                              sizeof(x_min));
      restore(&x_max,                              sizeof(x_max));
      restore(&y_min,                              sizeof(y_min));
      restore(&y_max,                              sizeof(y_max));
      restore(&xzero,                              sizeof(xzero));
      restore(&yzero,                              sizeof(yzero));
      restore(&matrixIndex,                        sizeof(matrixIndex));
      restore(&currentViewRegister,                sizeof(currentViewRegister));
      restore(&currentSolverStatus,                sizeof(currentSolverStatus));
      restore(&currentSolverProgram,               sizeof(currentSolverProgram));
      restore(&currentSolverVariable,              sizeof(currentSolverVariable));
      restore(&numberOfFormulae,                   sizeof(numberOfFormulae));
      restore(&currentFormula,                     sizeof(currentFormula));
      restore(&numberOfUserMenus,                  sizeof(numberOfUserMenus));
      restore(&currentUserMenu,                    sizeof(currentUserMenu));
      restore(&userKeyLabelSize,                   sizeof(userKeyLabelSize));
      restore(&timerCraAndDeciseconds,             sizeof(timerCraAndDeciseconds));
      restore(&timerValue,                         sizeof(timerValue));
      restore(&timerTotalTime,                     sizeof(timerTotalTime));
      restore(&currentInputVariable,               sizeof(currentInputVariable));
      restore(&SAVED_SIGMA_LASTX,                  sizeof(SAVED_SIGMA_LASTX));
      restore(&SAVED_SIGMA_LASTY,                  sizeof(SAVED_SIGMA_LASTY));
      restore(&SAVED_SIGMA_LAct,                   sizeof(SAVED_SIGMA_LAct));
      restore(&currentMvarLabel,                   sizeof(currentMvarLabel));
      restore(&graphVariable,                      sizeof(graphVariable));
      restore(&plotStatMx,                         sizeof(plotStatMx));
      restore(&drawHistogram,                      sizeof(drawHistogram));
      restore(&statMx,                             sizeof(statMx));
      restore(&lrSelectionHistobackup,             sizeof(lrSelectionHistobackup));
      restore(&lrChosenHistobackup,                sizeof(lrChosenHistobackup));
      restore(&loBinR,                             sizeof(loBinR));
      restore(&nBins ,                             sizeof(nBins ));
      restore(&hiBinR,                             sizeof(hiBinR));
      restore(&histElementXorY,                    sizeof(histElementXorY));

      restore(&screenUpdatingMode,                 sizeof(screenUpdatingMode));
      restore(loadedScreen,                        SCREEN_WIDTH * SCREEN_HEIGHT / 8);

      restore(&eRPN,                               sizeof(eRPN));                     //JM vv
      restore(&HOME3,                              sizeof(HOME3));
      restore(&ShiftTimoutMode,                    sizeof(ShiftTimoutMode));
      restore(&CPXMULT,                            sizeof(CPXMULT));                  //JM
      restore(&fgLN,                               sizeof(fgLN));
      restore(&BASE_HOME,                          sizeof(BASE_HOME));
      restore(&Norm_Key_00_VAR,                    sizeof(Norm_Key_00_VAR));
      restore(&Input_Default,                      sizeof(Input_Default));
      restore(&compatibility_bool,                 sizeof(compatibility_bool));
      restore(&BASE_MYM,                           sizeof(BASE_MYM));
      restore(&jm_G_DOUBLETAP,                     sizeof(jm_G_DOUBLETAP));
      restore(&compatibility_bool,                 sizeof(compatibility_bool));
      restore(&graph_xmin,                         sizeof(graph_xmin));
      restore(&graph_xmax,                         sizeof(graph_xmax));
      restore(&graph_ymin,                         sizeof(graph_ymin));
      restore(&graph_ymax,                         sizeof(graph_ymax));
      restore(&jm_LARGELI,                         sizeof(jm_LARGELI));
      restore(&constantFractions,                  sizeof(constantFractions));
      restore(&constantFractionsMode,              sizeof(constantFractionsMode));
      restore(&constantFractionsOn,                sizeof(constantFractionsOn));
      restore(&running_program_jm,                 sizeof(running_program_jm));
      restore(&indic_x,                            sizeof(indic_x));
      restore(&indic_y,                            sizeof(indic_y));
      restore(&fnXEQMENUpos,                       sizeof(fnXEQMENUpos));
      restore(&indexOfItemsXEQM,                   sizeof(indexOfItemsXEQM));
      restore(&T_cursorPos,                        sizeof(T_cursorPos));              //JM ^^
      restore(&SHOWregis,                          sizeof(SHOWregis));                //JM ^^
      restore(&mm_MNU_HOME,                        sizeof(mm_MNU_HOME));              //JM ^^
      restore(&mm_MNU_ALPHA,                       sizeof(mm_MNU_ALPHA));             //JM ^^
      restore(&displayStackSHOIDISP,               sizeof(displayStackSHOIDISP));     //JM ^^
      restore(&ListXYposition,                     sizeof(ListXYposition));           //JM ^^
      restore(&numLock,                            sizeof(numLock));                  //JM ^^
      restore(&DRG_Cycling,                        sizeof(DRG_Cycling));              //JM
      restore(&lastFlgScr,                         sizeof(lastFlgScr));
      restore(&displayAIMbufferoffset,             sizeof(displayAIMbufferoffset));   //C43 JM
      restore(&bcdDisplay,                         sizeof(bcdDisplay));               //C43 JM
      restore(&topHex,                             sizeof(topHex));                   //C43 JM
      restore(&bcdDisplaySign,                     sizeof(bcdDisplaySign));           //C43 JM
      restore(&DM_Cycling,                         sizeof(DM_Cycling));               //JM
      restore(&SI_All,                             sizeof(SI_All));                   //JM
      restore(&LongPressM,                         sizeof(LongPressM));               //JM
      restore(&LongPressF,                         sizeof(LongPressF));               //JM
      restore(&currentAsnScr,                      sizeof(currentAsnScr));            //JM

      if(backupVersion >= 781) {
        restore(&gapItemLeft,                        sizeof(gapItemLeft));               //JM
        restore(&gapItemRight,                       sizeof(gapItemRight));              //JM
        restore(&gapItemRadix,                       sizeof(gapItemRadix));              //JM
        restore(&grpGroupingLeft,                    sizeof(grpGroupingLeft));           //JM
        restore(&grpGroupingGr1LeftOverflow,         sizeof(grpGroupingGr1LeftOverflow));//JM
        restore(&grpGroupingGr1Left,                 sizeof(grpGroupingGr1Left));        //JM
        restore(&grpGroupingRight,                   sizeof(grpGroupingRight));          //JM
      }

      if(backupVersion >= 786) {
        restore(&MYM3,                                 sizeof(MYM3));
      } else MYM3 = false;

      ioFileClose();
      printf("End of calc's restoration\n");

      MY_ALPHA_MENU = mm_MNU_ALPHA;
      setFGLSettings(fgLN);

      if(temporaryInformation == TI_SHOW_REGISTER_BIG || temporaryInformation == TI_SHOW_REGISTER_SMALL)
        temporaryInformation = TI_NO_INFO;

      scanLabelsAndPrograms();
      defineCurrentProgramFromGlobalStepNumber(currentLocalStepNumber + abs(programList[currentProgramNumber - 1].step) - 1);
      defineCurrentStep();
      defineFirstDisplayedStep();
      defineCurrentProgramFromCurrentStep();

      //defineCurrentLocalRegisters();

      if(temporaryInformation==TI_SHOW_REGISTER) {
        temporaryInformation = TI_NO_INFO;
      }

      #if(DEBUG_REGISTER_L == 1)
        refreshRegisterLine(REGISTER_X); // to show L register
      #endif // (DEBUG_REGISTER_L == 1)

      for(int y = 0; y < SCREEN_HEIGHT; ++y) {
        for(int x = 0; x < SCREEN_WIDTH; x += 8) {
          uint8_t bmpdata = *(loadedScreen + (y * SCREEN_WIDTH + x) / 8);
          for(int bit = 7; bit >= 0; --bit) {
            *(screenData + y * screenStride + x + (7 - bit)) = (bmpdata & (1 << bit)) ? ON_PIXEL : OFF_PIXEL;
          }
        }
      }
      free(loadedScreen);

        if(tam.mode && !tam.alpha) {
          calcModeTamGui();
        }
        else if(tam.mode && tam.alpha) {
          calcModeAimGui();
        }
        else if(calcMode == CM_NORMAL) {
          calcModeNormalGui();
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
        else if(calcMode == CM_REGISTER_BROWSER) {
          calcModeNormalGui();
        }
        else if(calcMode == CM_FLAG_BROWSER) {
          calcModeNormalGui();
        }
        else if(calcMode == CM_ASN_BROWSER) {
          calcModeNormalGui();
        }
        else if(calcMode == CM_FONT_BROWSER) {
          calcModeNormalGui();
        }
        else if(calcMode == CM_PEM) {
          calcModeNormalGui();
        }
        else if(calcMode == CM_PLOT_STAT) {
          calcModeNormalGui();
        }
        else if(calcMode == CM_GRAPH) {
          calcModeNormalGui();
        }
        else if(calcMode == CM_LISTXY) {
          calcModeNormalGui();
        }
        else if(calcMode == CM_MIM) {
          calcModeNormalGui();
          mimRestore();
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
      refreshScreen();
    }
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

void fnSaveAuto(void) {
  doSave(autoSave);
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
flushBufferCnt = 0;
#if !defined(TESTSUITE_BUILD)
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
  sprintf(tmpString, "GLOBAL_REGISTERS\n%" PRIu16 "\n", (uint16_t)(FIRST_LOCAL_REGISTER));
  save(tmpString, strlen(tmpString));
  for(regist=0; regist<FIRST_LOCAL_REGISTER; regist++) {
    registerToSaveString(regist);
    sprintf(tmpString, "R%03" PRId16 "\n%s\n%s\n", regist, aimBuffer1, tmpRegisterString);
    save(tmpString, strlen(tmpString));
    saveMatrixElements(regist);
  }

  // Global flags
  strcpy(tmpString, "GLOBAL_FLAGS\n");
  save(tmpString, strlen(tmpString));
  sprintf(tmpString, "%" PRIu16 " %" PRIu16 " %" PRIu16 " %" PRIu16 " %" PRIu16 " %" PRIu16 " %" PRIu16 "\n",
                       globalFlags[0],
                                   globalFlags[1],
                                               globalFlags[2],
                                                           globalFlags[3],
                                                                       globalFlags[4],
                                                                                   globalFlags[5],
                                                                                               globalFlags[6]);
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
    realToString(statisticalSumsPointer + REAL_SIZE * i , tmpRegisterString);
    sprintf(tmpString, "%s\n", tmpRegisterString);
    save(tmpString, strlen(tmpString));
  }

  // System flags
  UI64toString(systemFlags, yy1);
  sprintf(tmpString, "SYSTEM_FLAGS\n%s\n", yy1);
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
  uint16_t currentSizeInBlocks = RAM_SIZE - freeMemoryRegions[numberOfFreeMemoryRegions - 1].address - freeMemoryRegions[numberOfFreeMemoryRegions - 1].sizeInBlocks;
  sprintf(tmpString, "PROGRAMS\n%" PRIu16 "\n", currentSizeInBlocks);
  save(tmpString, strlen(tmpString));

  sprintf(tmpString, "%" PRIu32 "\n%" PRIu32 "\n", (uint32_t)TO_WP43MEMPTR(currentStep), (uint32_t)((void *)currentStep - TO_PCMEMPTR(TO_WP43MEMPTR(currentStep)))); // currentStep block pointer + offset within block
  save(tmpString, strlen(tmpString));

  sprintf(tmpString, "%" PRIu32 "\n%" PRIu32 "\n", (uint32_t)TO_WP43MEMPTR(firstFreeProgramByte), (uint32_t)((void *)firstFreeProgramByte - TO_PCMEMPTR(TO_WP43MEMPTR(firstFreeProgramByte)))); // firstFreeProgramByte block pointer + offset within block
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
        sprintf(tmpString, "OTHER_CONFIGURATION_STUFF\n72\n");   
        save(tmpString, strlen(tmpString));    //JM 23+11+15+23
/*01*/  save(tmpString, strlen(tmpString)); 

//23 sprintf(tmpString, "firstGregorianDay\n%" PRIu32 "\n", firstGregorianDay);
/*02*/  sprintf(tmpString, "denMax\n%"                     PRIu32 "\n",     denMax);                       save(tmpString, strlen(tmpString));
/*03*/  sprintf(tmpString, "lastDenominator\n%"            PRIu32 "\n",     lastDenominator);              save(tmpString, strlen(tmpString));
/*04*/  sprintf(tmpString, "displayFormat\n%"              PRIu8  "\n",     displayFormat);                save(tmpString, strlen(tmpString));
/*05*/  sprintf(tmpString, "displayFormatDigits\n%"        PRIu8  "\n",     displayFormatDigits);          save(tmpString, strlen(tmpString));
/*06*/  sprintf(tmpString, "timeDisplayFormatDigits\n%"    PRIu8  "\n",     timeDisplayFormatDigits);      save(tmpString, strlen(tmpString));
/*07*/  sprintf(tmpString, "shortIntegerWordSize\n%"       PRIu8  "\n",     shortIntegerWordSize);         save(tmpString, strlen(tmpString));
/*08*/  sprintf(tmpString, "shortIntegerMode\n%"           PRIu8  "\n",     shortIntegerMode);             save(tmpString, strlen(tmpString));
/*09*/  sprintf(tmpString, "significantDigits\n%"          PRIu8  "\n",     significantDigits);            save(tmpString, strlen(tmpString));
/*10*/  sprintf(tmpString, "currentAngularMode\n%"         PRIu8  "\n",     (uint8_t)currentAngularMode);  save(tmpString, strlen(tmpString));
/*11*/  sprintf(tmpString, "gapItemLeft\n%"                PRIu16 "\n",     gapItemLeft);                  save(tmpString, strlen(tmpString));
/*12*/  sprintf(tmpString, "gapItemRight\n%"               PRIu16 "\n",     gapItemRight);                 save(tmpString, strlen(tmpString));
/*13*/  sprintf(tmpString, "gapItemRadix\n%"               PRIu16 "\n",     gapItemRadix);                 save(tmpString, strlen(tmpString));
/*14*/  sprintf(tmpString, "grpGroupingLeft\n%"            PRIu8  "\n",     grpGroupingLeft);              save(tmpString, strlen(tmpString));
/*15*/  sprintf(tmpString, "grpGroupingGr1LeftOverflow\n%" PRIu8  "\n",     grpGroupingGr1LeftOverflow);   save(tmpString, strlen(tmpString));
/*16*/  sprintf(tmpString, "grpGroupingGr1Left\n%"         PRIu8  "\n",     grpGroupingGr1Left);           save(tmpString, strlen(tmpString));
/*17*/  sprintf(tmpString, "grpGroupingRight\n%"           PRIu8  "\n",     grpGroupingRight);             save(tmpString, strlen(tmpString));
/*18*/  sprintf(tmpString, "roundingMode\n%"               PRIu8  "\n",     roundingMode);                 save(tmpString, strlen(tmpString));
/*19*/  sprintf(tmpString, "displayStack\n%"               PRIu8  "\n",     displayStack);                 save(tmpString, strlen(tmpString));
/*  */  UI64toString(pcg32_global.state, yy1);
/*  */  UI64toString(pcg32_global.inc, yy2);
/*20*/  sprintf(tmpString, "rngState\n%s %s\n", yy1, yy2);                                                 save(tmpString, strlen(tmpString));
/*21*/  sprintf(tmpString, "exponentLimit\n%"              PRId16  "\n",    exponentLimit);                save(tmpString, strlen(tmpString));
/*22*/  sprintf(tmpString, "exponentHideLimit\n%"          PRId16  "\n",    exponentHideLimit);            save(tmpString, strlen(tmpString));
/*23*/  sprintf(tmpString, "bestF\n%"                      PRIu16  "\n",    lrSelection);                  save(tmpString, strlen(tmpString));

//10     
/*01*/  sprintf(tmpString, "fgLN\n%"                       PRIu8  "\n",     (uint8_t)fgLN);                save(tmpString, strlen(tmpString));      //keep save file format by keeping the old setting
/*02*/  sprintf(tmpString, "eRPN\n%"                       PRIu8  "\n",     (uint8_t)eRPN);                save(tmpString, strlen(tmpString));
/*03*/  sprintf(tmpString, "HOME3\n%"                      PRIu8  "\n",     (uint8_t)HOME3);               save(tmpString, strlen(tmpString));
/*04*/  sprintf(tmpString, "MYM3\n%"                       PRIu8  "\n",     (uint8_t)MYM3);                save(tmpString, strlen(tmpString));
/*05*/  sprintf(tmpString, "ShiftTimoutMode\n%"            PRIu8  "\n",     (uint8_t)ShiftTimoutMode);     save(tmpString, strlen(tmpString));
/*06*/  sprintf(tmpString, "CPXMult\n%"                    PRIu8  "\n",     (uint8_t)CPXMULT);             save(tmpString, strlen(tmpString));
/*07*/  sprintf(tmpString, "BASE_HOME\n%"                  PRIu8  "\n",     (uint8_t)BASE_HOME);           save(tmpString, strlen(tmpString));
/*08*/  sprintf(tmpString, "Norm_Key_00_VAR\n%"            PRId16 "\n",     Norm_Key_00_VAR);              save(tmpString, strlen(tmpString));
/*09*/  sprintf(tmpString, "Input_Default\n%"              PRIu8  "\n",     Input_Default);                save(tmpString, strlen(tmpString));
/*10*/  sprintf(tmpString, "BASE_MYM\n%"                   PRIu8  "\n",     (uint8_t)BASE_MYM);            save(tmpString, strlen(tmpString));
/*11*/  sprintf(tmpString, "jm_G_DOUBLETAP\n%"             PRIu8  "\n",     (uint8_t)jm_G_DOUBLETAP);      save(tmpString, strlen(tmpString));

/*  *///15     
/*01*/  sprintf(tmpString, "compatibility_bool\n%"         PRIu8  "\n",     (uint8_t)0);                   save(tmpString, strlen(tmpString));            //compatibility - use when needed
/*02*/  sprintf(tmpString, "jm_LARGELI\n%"                 PRIu8  "\n",     (uint8_t)jm_LARGELI);          save(tmpString, strlen(tmpString));
/*03*/  sprintf(tmpString, "constantFractions\n%"          PRIu8  "\n",     (uint8_t)constantFractions);   save(tmpString, strlen(tmpString));
/*04*/  sprintf(tmpString, "constantFractionsMode\n%"      PRIu8  "\n",     constantFractionsMode);        save(tmpString, strlen(tmpString));
/*05*/  sprintf(tmpString, "constantFractionsOn\n%"        PRIu8  "\n",     (uint8_t)constantFractionsOn); save(tmpString, strlen(tmpString));
/*06*/  sprintf(tmpString, "displayStackSHOIDISP\n%"       PRIu8  "\n",     displayStackSHOIDISP);         save(tmpString, strlen(tmpString));
/*07*/  sprintf(tmpString, "bcdDisplay\n%"                 PRIu8  "\n",     (uint8_t)bcdDisplay);          save(tmpString, strlen(tmpString));
/*08*/  sprintf(tmpString, "topHex\n%"                     PRIu8  "\n",     (uint8_t)topHex);              save(tmpString, strlen(tmpString));
/*09*/  sprintf(tmpString, "bcdDisplaySign\n%"             PRIu8  "\n",     bcdDisplaySign);               save(tmpString, strlen(tmpString));
/*10*/  sprintf(tmpString, "DRG_Cycling\n%"                PRIu8  "\n",     DRG_Cycling);                  save(tmpString, strlen(tmpString));
/*11*/  sprintf(tmpString, "DM_Cycling\n%"                 PRIu8  "\n",     DM_Cycling);                   save(tmpString, strlen(tmpString));
/*12*/  sprintf(tmpString, "SI_All\n%"                     PRIu8  "\n",     (uint8_t)SI_All);              save(tmpString, strlen(tmpString));
/*13*/  sprintf(tmpString, "LongPressM\n%"                 PRIu8  "\n",     (uint8_t)LongPressM);          save(tmpString, strlen(tmpString));
/*14*/  sprintf(tmpString, "LongPressF\n%"                 PRIu8  "\n",     (uint8_t)LongPressF);          save(tmpString, strlen(tmpString));
/*15*/  sprintf(tmpString, "lastIntegerBase\n%"            PRIu8  "\n",     (uint8_t)lastIntegerBase);     save(tmpString, strlen(tmpString));

/*  *///23        
/*01*/  sprintf(tmpString, "lrChosen\n%"                   PRIu16 "\n",     lrChosen);                     save(tmpString, strlen(tmpString));
/*02*/  sprintf(tmpString, "graph_xmin\n"                  "%f"   "\n",     graph_xmin);                   save(tmpString, strlen(tmpString));
/*03*/  sprintf(tmpString, "graph_xmax\n"                  "%f"   "\n",     graph_xmax);                   save(tmpString, strlen(tmpString));
/*04*/  sprintf(tmpString, "graph_ymin\n"                  "%f"   "\n",     graph_ymin);                   save(tmpString, strlen(tmpString));
/*05*/  sprintf(tmpString, "graph_ymax\n"                  "%f"   "\n",     graph_ymax);                   save(tmpString, strlen(tmpString));
/*06*/  sprintf(tmpString, "graph_dx\n"                    "%f"   "\n",     graph_dx);                     save(tmpString, strlen(tmpString));
/*07*/  sprintf(tmpString, "graph_dy\n"                    "%f"   "\n",     graph_dy);                     save(tmpString, strlen(tmpString));
/*08*/  sprintf(tmpString, "roundedTicks\n%"               PRIu8  "\n",     (uint8_t)roundedTicks);        save(tmpString, strlen(tmpString));
/*09*/  sprintf(tmpString, "extentx\n%"                    PRIu8  "\n",     (uint8_t)extentx);             save(tmpString, strlen(tmpString));
/*10*/  sprintf(tmpString, "extenty\n%"                    PRIu8  "\n",     (uint8_t)extenty);             save(tmpString, strlen(tmpString));
/*11*/  sprintf(tmpString, "PLOT_VECT\n%"                  PRIu8  "\n",     (uint8_t)PLOT_VECT);           save(tmpString, strlen(tmpString));
/*12*/  sprintf(tmpString, "PLOT_NVECT\n%"                 PRIu8  "\n",     (uint8_t)PLOT_NVECT);          save(tmpString, strlen(tmpString));
/*13*/  sprintf(tmpString, "PLOT_SCALE\n%"                 PRIu8  "\n",     (uint8_t)PLOT_SCALE);          save(tmpString, strlen(tmpString));
/*14*/  sprintf(tmpString, "PLOT_LINE\n%"                  PRIu8  "\n",     (uint8_t)PLOT_LINE);           save(tmpString, strlen(tmpString));
/*15*/  sprintf(tmpString, "PLOT_CROSS\n%"                 PRIu8  "\n",     (uint8_t)PLOT_CROSS);          save(tmpString, strlen(tmpString));
/*16*/  sprintf(tmpString, "PLOT_BOX\n%"                   PRIu8  "\n",     (uint8_t)PLOT_BOX);            save(tmpString, strlen(tmpString));
/*17*/  sprintf(tmpString, "PLOT_INTG\n%"                  PRIu8  "\n",     (uint8_t)PLOT_INTG);           save(tmpString, strlen(tmpString));
/*18*/  sprintf(tmpString, "PLOT_DIFF\n%"                  PRIu8  "\n",     (uint8_t)PLOT_DIFF);           save(tmpString, strlen(tmpString));
/*19*/  sprintf(tmpString, "PLOT_RMS\n%"                   PRIu8  "\n",     (uint8_t)PLOT_RMS);            save(tmpString, strlen(tmpString));
/*20*/  sprintf(tmpString, "PLOT_SHADE\n%"                 PRIu8  "\n",     (uint8_t)PLOT_SHADE);          save(tmpString, strlen(tmpString));
/*21*/  sprintf(tmpString, "PLOT_AXIS\n%"                  PRIu8  "\n",     (uint8_t)PLOT_AXIS);           save(tmpString, strlen(tmpString));
/*22*/  sprintf(tmpString, "PLOT_ZMX\n%"                   PRIu8  "\n",     PLOT_ZMX);                     save(tmpString, strlen(tmpString));
/*23*/  sprintf(tmpString, "PLOT_ZMY\n%"                   PRIu8  "\n",     PLOT_ZMY);                     save(tmpString, strlen(tmpString));

  ioFileClose();

  hourGlassIconEnabled = false;
  temporaryInformation = TI_SAVED;
#endif // !TESTSUITE_BUILD
}



void readLine(char *line) {
  restore(line, 1);
  while(*line == '\n' || *line == '\r') {
    restore(line, 1);
  }

  while(*line != '\n' && *line != '\r') {
    restore(++line, 1);
  }

  *line = 0;
}



#if !defined(TESTSUITE_BUILD)
static void UI64toString(uint64_t value, char * tmpRegisterString) {
  uint32_t v0,v1;

  v0 = value & 0xffffffff;
  v1 = value >> 32;
  if(v1 != 0) {
    sprintf(tmpRegisterString, "0x%" PRIx32 "%0" PRIx32, v1, v0);
  }
  else {
    sprintf(tmpRegisterString, "0x%" PRIx32, v0);
  }
}
#endif // !TESTSUITE_BUILD

static unsigned int getBase(const char **str) {
  unsigned int base = 10;
  //fprintf(stderr,"\nget base\n");fflush(stderr);
  if(**str == '0' && (*str)[1] != '\0') {
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
      value = value * base + digit;               \
    }                                             \
    return value;                                 \
  }

stringToUintFunc(stringToUint8,  uint8_t)
stringToUintFunc(stringToUint16, uint16_t)
stringToUintFunc(stringToUint32, uint32_t)
stringToUintFunc(stringToUint64, uint64_t)


float strintToFloat(const char *str) {
  return strtof(str, NULL);
}


int16_t stringToInt16(const char *str) {
  int16_t value = 0;
  bool_t sign = false;

  if(*str == '-') {
    str++;
    sign = true;
  }
  else if(*str == '+') {
    str++;
  }

  while('0' <= *str && *str <= '9') {
    value = value*10 + (*(str++) - '0');
  }

  if(sign) {
    value = -value;
  }
  return value;
}



int32_t stringToInt32(const char *str) {
  int32_t value = 0;
  bool_t sign = false;

  if(*str == '-') {
    str++;
    sign = true;
  }
  else if(*str == '+') {
    str++;
  }

  while('0' <= *str && *str <= '9') {
    value = value*10 + (*(str++) - '0');
  }

  if(sign) {
    value = -value;
  }
  return value;
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

      reallocateRegister(regist, dtReal34, REAL34_SIZE, tag);
      stringToReal34(value, REGISTER_REAL34_DATA(regist));
    }

    else if(strcmp(type, "Real") == 0) {
      reallocateRegister(regist, dtReal34, REAL34_SIZE, tag);
      stringToReal34(value, REGISTER_REAL34_DATA(regist));
    }

    else if(strcmp(type, "Time") == 0) {
      reallocateRegister(regist, dtTime, REAL34_SIZE, amNone);
      stringToReal34(value, REGISTER_REAL34_DATA(regist));
    }

    else if(strcmp(type, "Date") == 0) {
      reallocateRegister(regist, dtDate, REAL34_SIZE, amNone);
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

      reallocateRegister(regist, dtComplex34, COMPLEX34_SIZE, amNone);
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
      reallocateRegister(regist, dtReal34Matrix, REAL34_SIZE * rows * cols, amNone);
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
      reallocateRegister(regist, dtComplex34Matrix, COMPLEX34_SIZE * rows * cols, amNone);
      REGISTER_COMPLEX34_MATRIX_DBLOCK(regist)->matrixRows = rows;
      REGISTER_COMPLEX34_MATRIX_DBLOCK(regist)->matrixColumns = cols;
    }
  #endif // TESTSUITE_BUILD

    else if(strcmp(type, "Conf") == 0) {
      char *cfg;

      reallocateRegister(regist, dtConfig, CONFIG_SIZE, amNone);
      for(cfg=(char *)REGISTER_CONFIG_DATA(regist), tag=0;  tag < (loadedVersion < 10000008 ? 896 : sizeof(dtConfigDescriptor_t)); tag++, value+=2, cfg++) {
        *cfg = ((*value >= 'A' ? *value - 'A' + 10 : *value - '0') << 4) | (*(value + 1) >= 'A' ? *(value + 1) - 'A' + 10 : *(value + 1) - '0');
      }
      if (loadedVersion < 10000008) {
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
      char line[100];
    #endif //LOADDEBUG

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
        readLine(aimBuffer); // Register data type
        readLine(tmpString); // Register value

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
          readLine(aimBuffer); // Register data type
          readLine(tmpString); // Register value

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
        readLine(aimBuffer); // Variable data type
        readLine(tmpString); // Variable value

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
              stringToReal(tmpString, (real_t *)(statisticalSumsPointer + REAL_SIZE * i), &ctxtReal75);
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
        systemFlags = stringToUint64(tmpString);
        if (loadedVersion < 10000006) {
          defaultStatusBar(); //clear systemflags for early version config files
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
        freeWp43(userKeyLabel, TO_BLOCKS(userKeyLabelSize));
        userKeyLabelSize = 37/*keys*/ * 6/*states*/ * 1/*byte terminator*/ + 1/*byte sentinel*/;
        userKeyLabel = allocWp43(TO_BLOCKS(userKeyLabelSize));
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
      uint16_t oldSizeInBlocks = RAM_SIZE - freeMemoryRegions[numberOfFreeMemoryRegions - 1].address - freeMemoryRegions[numberOfFreeMemoryRegions - 1].sizeInBlocks;
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
        allFormulae = allocWp43(TO_BLOCKS(sizeof(formulaHeader_t)) * formulae);
        numberOfFormulae = formulae;
        currentFormula = 0;
        for(i = 0; i < formulae; i++) {
          allFormulae[i].pointerToFormulaData = WP43_NULL;
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
      readLine(tmpString); // Number params
      numberOfRegs = stringToInt16(tmpString);
      for(i=0; i<numberOfRegs; i++) {
        readLine(aimBuffer); // param
        readLine(tmpString); // value
        if(loadMode == LM_ALL || loadMode == LM_SYSTEM_STATE) {
          #if defined(LOADDEBUG)
            sprintf(line,", loadMode:%d, %s\n",loadMode,tmpString);
            debugPrintf(16, "B", tmpString);
          #endif //LOADDEBUG

          if(strcmp(aimBuffer, "firstGregorianDay") == 0) {
            firstGregorianDay = stringToUint32(tmpString);
          }
          else if(strcmp(aimBuffer, "denMax") == 0) {
            denMax = stringToUint32(tmpString);
            if(denMax < 1 || denMax > MAX_DENMAX) {
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
          else if(strcmp(aimBuffer, "eRPN"                        ) == 0) { eRPN                  = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "HOME3"                       ) == 0) { HOME3                 = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "MYM3"                        ) == 0) { MYM3                  = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "ShiftTimoutMode"             ) == 0) { ShiftTimoutMode       = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "CPXMult"                     ) == 0) { CPXMULT               = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "SH_BASE_HOME"                ) == 0) { BASE_HOME             = (bool_t)stringToUint8(tmpString) != 0; }  //Keep compatible with old name by repeating it
          else if(strcmp(aimBuffer, "BASE_HOME"                   ) == 0) { BASE_HOME             = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "Norm_Key_00_VAR"             ) == 0) { Norm_Key_00_VAR       = stringToUint16(tmpString); }
          else if(strcmp(aimBuffer, "Input_Default"               ) == 0) { Input_Default         = stringToUint8(tmpString); }
          else if(strcmp(aimBuffer, "jm_BASE_SCREEN"              ) == 0) { BASE_MYM        = (bool_t)stringToUint8(tmpString) != 0; }        //Keep compatible by repeating
          else if(strcmp(aimBuffer, "BASE_MYM"                    ) == 0) { BASE_MYM        = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "jm_G_DOUBLETAP"              ) == 0) { jm_G_DOUBLETAP        = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "jm_LARGELI"                  ) == 0) { jm_LARGELI            = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "constantFractions"           ) == 0) { constantFractions     = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "constantFractionsMode"       ) == 0) { constantFractionsMode = stringToUint8(tmpString); }
          else if(strcmp(aimBuffer, "constantFractionsOn"         ) == 0) { constantFractionsOn   = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "displayStackSHOIDISP"        ) == 0) { displayStackSHOIDISP = stringToUint8(tmpString); }
          else if(strcmp(aimBuffer, "bcdDisplay"                  ) == 0) { bcdDisplay           = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "topHex"                      ) == 0) { topHex               = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "bcdDisplaySign"              ) == 0) { bcdDisplaySign       = stringToUint8(tmpString); }
          else if(strcmp(aimBuffer, "DRG_Cycling"                 ) == 0) { DRG_Cycling          = stringToUint8(tmpString); }
          else if(strcmp(aimBuffer, "DM_Cycling"                  ) == 0) { DM_Cycling           = stringToUint8(tmpString); }
          else if(strcmp(aimBuffer, "SI_All"                      ) == 0) { SI_All               = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "LongPressM"                  ) == 0) { LongPressM           = stringToUint8(tmpString); }                  //10000003
          else if(strcmp(aimBuffer, "LongPressF"                  ) == 0) { LongPressF           = stringToUint8(tmpString); }                  //10000003
          else if(strcmp(aimBuffer, "lastIntegerBase"             ) == 0) { lastIntegerBase      = stringToUint8(tmpString); }                  //10000004
          else if(strcmp(aimBuffer, "lrChosen"                    ) == 0) { lrChosen             = stringToUint16(tmpString);}
          else if(strcmp(aimBuffer, "graph_xmin"                  ) == 0) { graph_xmin           = strintToFloat(tmpString); }
          else if(strcmp(aimBuffer, "graph_xmax"                  ) == 0) { graph_xmax           = strintToFloat(tmpString); }
          else if(strcmp(aimBuffer, "graph_ymin"                  ) == 0) { graph_ymin           = strintToFloat(tmpString); }
          else if(strcmp(aimBuffer, "graph_ymax"                  ) == 0) { graph_ymax           = strintToFloat(tmpString); }
          else if(strcmp(aimBuffer, "graph_dx"                    ) == 0) { graph_dx             = strintToFloat(tmpString); }
          else if(strcmp(aimBuffer, "graph_dy"                    ) == 0) { graph_dy             = strintToFloat(tmpString); }
          else if(strcmp(aimBuffer, "roundedTicks"                ) == 0) { roundedTicks         = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "extentx"                     ) == 0) { extentx              = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "extenty"                     ) == 0) { extenty              = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "PLOT_VECT"                   ) == 0) { PLOT_VECT            = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "PLOT_NVECT"                  ) == 0) { PLOT_NVECT           = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "PLOT_SCALE"                  ) == 0) { PLOT_SCALE           = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "PLOT_LINE"                   ) == 0) { PLOT_LINE            = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "PLOT_CROSS"                  ) == 0) { PLOT_CROSS           = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "PLOT_BOX"                    ) == 0) { PLOT_BOX             = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "PLOT_INTG"                   ) == 0) { PLOT_INTG            = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "PLOT_DIFF"                   ) == 0) { PLOT_DIFF            = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "PLOT_RMS"                    ) == 0) { PLOT_RMS             = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "PLOT_SHADE"                  ) == 0) { PLOT_SHADE           = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "PLOT_AXIS"                   ) == 0) { PLOT_AXIS            = (bool_t)stringToUint8(tmpString) != 0; }
          else if(strcmp(aimBuffer, "PLOT_ZMX"                    ) == 0) { PLOT_ZMX             = stringToUint8(tmpString); }
          else if(strcmp(aimBuffer, "PLOT_ZMY"                    ) == 0) { PLOT_ZMY             = stringToUint8(tmpString); }


          hourGlassIconEnabled = false;

        }
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
  flushBufferCnt = 0;
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
    }
    else if((loadType == autoLoad) && (loadedVersion >= VersionAllowed) && (loadedVersion <= configFileVersion) && (loadMode == LM_ALL)) {
      temporaryInformation = TI_BACKUP_RESTORED;
    }
    else if(loadType == stateLoad) {
      temporaryInformation = TI_STATEFILE_RESTORED;
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
  if(loadMode == LM_STATE_LOAD) {
    doLoad(LM_ALL, 0, 0, 0, stateLoad);
  }
  else {
    doLoad(loadMode, 0, 0, 0, manualLoad);
  }
  fnClearFlag(FLAG_USER);
  doRefreshSoftMenu = true;
  refreshScreen();
}

void fnLoadAuto(void) {
  doLoad(LM_ALL, 0, 0, 0, autoLoad);
  fnClearFlag(FLAG_USER);
  doRefreshSoftMenu = true;
  refreshScreen();
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
            #if(EXTRA_INFO_ON_CALC_ERROR == 1)
              sprintf(errorMessage, "removing the backup failed with error code %d", e);
              moreInfoOnError("In function fnDeleteBackup:", errorMessage, NULL, NULL);
            #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
          }
        #endif // !TESTSUITE_BUILD
      }
    #endif // DMCP_BUILD
  }
}

