// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 Authors

#include "saveRestoreCalcState.h"
#include "saveRestorePrograms.h"

#include "assign.h"
#include "calcMode.h"
#include "charString.h"
#include "config.h"
#include "display.h"
#include "error.h"
#include "flags.h"
#include "hal/gui.h"
#include "hal/io.h"
#include "items.h"
#include "mathematics/matrix.h"
#include "memory.h"
#include "plotstat.h"
#include "programming/lblGtoXeq.h"
#include "programming/manage.h"
#include "programming/nextStep.h"
#include "programming/decode.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "solver/equation.h"
#include "solver/graph.h"
#include "sort.h"
#include "stats.h"
#include "ui/tam.h"
#if defined(DMCP_BUILD)
  #include <dmcp.h>
//  #include <wp43-dmcp.h>
#endif // DMCP_BUILD
#include <stdbool.h>
#include <string.h>

#include "wp43.h"

#define PROGRAM_VERSION                     01  // Original version
#define OLDEST_COMPATIBLE_PROGRAM_VERSION   01  // Original version
#define BACKUP_FORMAT                       00  // Same program format as in backup file
#define TEXT_FORMAT                         01  // Text program format - for future use

// Structure of the program file.
// Format: ASCII
// Each line after line 6 contains the decimal value of a program byte
//
//  +-----+---------------------------+
//  | Line|         Content           |
//  +-----+---------------------------+
//  |  1  |   "PROGRAM_FILE_FORMAT"   |
//  |  2  |       <file format>       |
//  |  3  |"WP43_program_file_version"|
//  |  4  |   <program file version>  |
//  |  5  |         "PROGRAM"         |
//  |  6  |       <program size>      |
//  |  7  |    <first program byte>   |
//  | ... |            ...            |
//  |  n  |    <last program byte>    |
//  +-----+---------------------------+
//



#if !defined(TESTSUITE_BUILD)
  static void _addSpaceAfterPrograms(uint16_t size) {
    if(freeProgramBytes < size) {
      uint8_t *oldBeginOfProgramMemory = beginOfProgramMemory;
      uint32_t programSizeInBlocks = RAM_SIZE_IN_BLOCKS - freeMemoryRegions[numberOfFreeMemoryRegions - 1].blockAddress - freeMemoryRegions[numberOfFreeMemoryRegions - 1].sizeInBlocks;
      uint32_t newProgramSizeInBlocks = TO_BLOCKS(TO_BYTES(programSizeInBlocks) - freeProgramBytes + size);
      freeProgramBytes      += TO_BYTES(newProgramSizeInBlocks - programSizeInBlocks);
      resizeProgramMemory(newProgramSizeInBlocks);
      currentStep           = currentStep           - oldBeginOfProgramMemory + beginOfProgramMemory;
      firstDisplayedStep    = firstDisplayedStep    - oldBeginOfProgramMemory + beginOfProgramMemory;
      beginOfCurrentProgram = beginOfCurrentProgram - oldBeginOfProgramMemory + beginOfProgramMemory;
      endOfCurrentProgram   = endOfCurrentProgram   - oldBeginOfProgramMemory + beginOfProgramMemory;
    }

    firstFreeProgramByte   += size;
    freeProgramBytes       -= size;
  }


  static bool_t _addEndNeeded(void) {
    if(firstFreeProgramByte <= beginOfProgramMemory) {
      return false;
    }
    if(firstFreeProgramByte == beginOfProgramMemory + 1) {
      return true;
    }
    if(isAtEndOfProgram(firstFreeProgramByte - 2)) {
      return false;
    }
    return true;
  }
#endif // !TESTSUITE_BUILD



void fnPExport(uint16_t unusedButMandatoryParameter) {
#if !defined(SAVE_SPACE_DM42_10)
  #if !defined(TESTSUITE_BUILD)
    ///////////////////////////////////////////////////////////////////////////////////////
    // For details, see fnPem(). This is a modified copy.
    //
    uint16_t line, firstLine;
    uint8_t *step, *nextStep;
    uint16_t numberOfSteps = getNumberOfSteps();
    char asciiString[448];           //cannot use errorMessage buffer in disk write operations
                                     //solution is to use a local variable of sufficient length to contain a step string.

    firstDisplayedLocalStepNumber = 0;
    defineFirstDisplayedStep();

    step                     = firstDisplayedStep;
    programListEnd           = false;
    lastProgramListEnd       = false;

    if(firstDisplayedLocalStepNumber == 0) {
      sprintf(tmpString, "0000: { Prgm #%d: %" PRIu32 " bytes / %" PRIu16 " step%s }", currentProgramNumber, _getProgramSize(),                                                                               numberOfSteps, numberOfSteps == 1 ? "" : "s");
      //printf("%s\n",tmpString);

      stringAppend(tmpString + stringByteLength(tmpString), "\n");
      ioFileWrite(tmpString, strlen(tmpString));

      firstLine = 1;
    }
    else {
      firstLine = 0;
    }

    int lineOffset = 0, lineOffsetTam = 0;

    for(line=firstLine; line<9999; line++) {
      nextStep = findNextStep(step);
      sprintf(tmpString, "%04d:  " , firstDisplayedLocalStepNumber + line - lineOffset + lineOffsetTam);
      //printf("%s",tmpString);
      ioFileWrite(tmpString, strlen(tmpString));

      decodeOneStepXEQM(step);
      stringAppend(tmpString + stringByteLength(tmpString), "\n");
      stringToASCII(tmpString, asciiString);
      //printf("%s\n",errorMessage);
      ioFileWrite(asciiString, strlen(asciiString));

      if(isAtEndOfProgram(step)) {
        programListEnd = true;
        if(*nextStep == 255 && *(nextStep + 1) == 255) {
          lastProgramListEnd = true;
        }
        break;
      }
      if((*step == 255) && (*(step + 1) == 255)) {
        programListEnd = true;
        lastProgramListEnd = true;
        break;
      }
      step = nextStep;
    }
  #endif // !TESTSUITE_BUILD
#endif // !SAVE_SPACE_DM42_10
}






void fnExportProgram(uint16_t label) {
  #if !defined(TESTSUITE_BUILD)
    uint32_t programVersion = PROGRAM_VERSION;
    ioFilePath_t path;
    int ret;

    // Find program boundaries
    const uint16_t savedCurrentLocalStepNumber = currentLocalStepNumber;
    uint16_t savedCurrentProgramNumber = currentProgramNumber;

    // no argument – need to save current program
    if(label == 0 && !tam.alpha && tam.digitsSoFar == 0) {
        // find the first global label in the current program
        uint16_t currentLabel = 0;
        strcpy(tmpStringLabelOrVariableName, "untitled");
        while (currentLabel < numberOfLabels) {
          if (labelList[currentLabel].program == currentProgramNumber) {
            break;
          }
          currentLabel++;
        }
        // get the first global label name
        while (currentLabel < numberOfLabels) {
          if (labelList[currentLabel].step > 0) {  // global label
            // get current label name (to be used as default file name)
            xcopy(tmpStringLabelOrVariableName, labelList[currentLabel].labelPointer + 1, *(labelList[currentLabel].labelPointer));
            tmpStringLabelOrVariableName[*(labelList[currentLabel].labelPointer)] = 0;
            break;
          }
          currentLabel++;
        }
    }
    // Existing global label
    else if(label >= FIRST_LABEL && label <= LAST_LABEL) {
      fnGoto(label);
      // get current label name (to be used as default file name)
      xcopy(tmpStringLabelOrVariableName, labelList[label - FIRST_LABEL].labelPointer + 1, *(labelList[label - FIRST_LABEL].labelPointer));
      tmpStringLabelOrVariableName[*(labelList[label - FIRST_LABEL].labelPointer)] = 0;
    }
    // Invalid label
    else {
      displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "label %" PRIu16 " is not a global label", label);
        moreInfoOnError("In function fnSaveProgram:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }

    path = ioPathExportProgram;
    ret = ioFileOpen(path, ioModeWrite);

    if(ret != FILE_OK ) {
      if(ret == FILE_CANCEL ) {
        return;
      }
      else {
        #if !defined(DMCP_BUILD)
          printf("Cannot export program!\n");
        #endif
        displayCalcErrorMessage(ERROR_CANNOT_WRITE_FILE, ERR_REGISTER_LINE, REGISTER_X);
        return;
      }
    }

    // PROGRAM file version
    sprintf(tmpString, "C47 Program file export, version %" PRIu32 "\n", (uint32_t)programVersion);
    ioFileWrite(tmpString, strlen(tmpString));

    fnPExport(0);

    ioFileClose();

    currentLocalStepNumber = savedCurrentLocalStepNumber;
    currentProgramNumber = savedCurrentProgramNumber;

    temporaryInformation = TI_SAVED;
  #endif // !TESTSUITE_BUILD
}



void fnSaveProgram(uint16_t label) {
  #if !defined(TESTSUITE_BUILD)
    uint32_t programVersion = PROGRAM_VERSION;
    ioFilePath_t path;
    //char tmpString[3000];           //The concurrent use of the global tmpString
    //                                //as target does not work while the source is at
    //                                //tmpRegisterString = tmpString + START_REGISTER_VALUE;
    //                                //Temporary solution is to use a local variable of sufficient length for the target.
    uint32_t i;
    int ret;

    #if defined(DMCP_BUILD)
      // Don't pass through if the power is insufficient
      if(power_check_screen()) {
        return;
      }
    #endif // DMCP_BUILD

    // Find program boundaries
    const uint16_t savedCurrentLocalStepNumber = currentLocalStepNumber;
    uint16_t savedCurrentProgramNumber = currentProgramNumber;

    // no argument – need to save current program
    if(label == 0 && !tam.alpha && tam.digitsSoFar == 0) {
        // find the first global label in the current program
        uint16_t currentLabel = 0;
        strcpy(tmpStringLabelOrVariableName, "untitled");
        while (currentLabel < numberOfLabels) {
          if (labelList[currentLabel].program == currentProgramNumber) {
            break;
          }
          currentLabel++;
        }
        // get the first global label name
        while (currentLabel < numberOfLabels) {
          if (labelList[currentLabel].step > 0) {  // global label
            // get current label name (to be used as default file name)
            xcopy(tmpStringLabelOrVariableName, labelList[currentLabel].labelPointer + 1, *(labelList[currentLabel].labelPointer));
            tmpStringLabelOrVariableName[*(labelList[currentLabel].labelPointer)] = 0;
            break;
          }
          currentLabel++;
        }
    }
    // Existing global label
    else if(label >= FIRST_LABEL && label <= LAST_LABEL) {
      fnGoto(label);
      // get current label name (to be used as default file name)
      xcopy(tmpStringLabelOrVariableName, labelList[label - FIRST_LABEL].labelPointer + 1, *(labelList[label - FIRST_LABEL].labelPointer));
      tmpStringLabelOrVariableName[*(labelList[label - FIRST_LABEL].labelPointer)] = 0;
    }
    // Invalid label
    else {
      displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "label %" PRIu16 " is not a global label", label);
        moreInfoOnError("In function fnSaveProgram:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }

    path = ioPathSaveProgram;
    ret = ioFileOpen(path, ioModeWrite);

    if(ret != FILE_OK ) {
      if(ret == FILE_CANCEL ) {
        return;
      }
      else {
        #if !defined(DMCP_BUILD)
          printf("Cannot save program!\n");
        #endif
        displayCalcErrorMessage(ERROR_CANNOT_WRITE_FILE, ERR_REGISTER_LINE, REGISTER_X);
        return;
      }
    }

    // PROGRAM file version
    sprintf(tmpString, "PROGRAM_FILE_FORMAT\n%" PRIu8 "\n", (uint8_t)BACKUP_FORMAT);
    ioFileWrite(tmpString, strlen(tmpString));
    sprintf(tmpString, "C47_program_file_version\n%" PRIu32 "\n", (uint32_t)programVersion);
    ioFileWrite(tmpString, strlen(tmpString));

    // Program
    size_t currentSizeInBytes = endOfCurrentProgram - ((currentProgramNumber == numberOfPrograms) ? 2 : 0) - beginOfCurrentProgram;
    sprintf(tmpString, "PROGRAM\n%" PRIu32 "\n", (uint32_t)currentSizeInBytes);
    ioFileWrite(tmpString, strlen(tmpString));

    // Save program bytes
    for(i=0; i<currentSizeInBytes; i++) {
      sprintf(tmpString, "%" PRIu8 "\n", beginOfCurrentProgram[i]);
      ioFileWrite(tmpString, strlen(tmpString));
    }
    // If last program in memory then add .END. statement
    if(currentProgramNumber == numberOfPrograms) {
      sprintf(tmpString, "255\n255\n");
      ioFileWrite(tmpString, strlen(tmpString));
    }

    ioFileClose();

    currentLocalStepNumber = savedCurrentLocalStepNumber;
    currentProgramNumber = savedCurrentProgramNumber;

    temporaryInformation = TI_SAVED;
  #endif // !TESTSUITE_BUILD
}


void fnLoadProgram(uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
    ioFilePath_t path;
    uint32_t pgmSizeInByte;
    uint32_t i;
    uint8_t *startOfProgram;
    int ret;

    path = ioPathLoadProgram;
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

    //Check save file version
    uint32_t loadedVersion = 0;
    readLine(tmpString);
    if(strcmp(tmpString, "PROGRAM_FILE_FORMAT") == 0) {
      readLine(aimBuffer); // Format of program instructions (ignore now, there is only one format)
    }
    else {
      #if !defined(TESTSUITE_BUILD)
        sprintf(tmpString," \nThis is not a C47 program\n\nIt will not be loaded.");
        show_warning(tmpString);
      #endif // TESTSUITE_BUILD
      ioFileClose();
      return;
    }
    readLine(aimBuffer); // param
    readLine(tmpString); // value
    if(strcmp(aimBuffer, "C47_program_file_version") == 0) {
      loadedVersion = stringToUint32(tmpString);
      if(loadedVersion < OLDEST_COMPATIBLE_PROGRAM_VERSION) { // Program incompatibility
        #if !defined(TESTSUITE_BUILD)
          sprintf(tmpString, " \n   !!! Program version is too old !!!\nNot compatible with current version\n \nIt will not be loaded.");
          show_warning(tmpString);
        #endif // TESTSUITE_BUILD
        ioFileClose();
        return;
      }
    }
    else {
      if(strcmp(aimBuffer, "WP43_program_file_version") == 0) {
        loadedVersion = stringToUint32(tmpString);
        #if !defined(TESTSUITE_BUILD)
          sprintf(tmpString," \nThis is a WP43 program\nWP43 program support is experimental\nSome instructions may not be \ncompatible with the C47 and may\ncrash the calculator.");
          show_warning(tmpString);
        #endif // TESTSUITE_BUILD
      }
      else {
        #if !defined(TESTSUITE_BUILD)
          sprintf(tmpString, " \nThis is not a C47 program\n \nIt will not be loaded.");
          show_warning(tmpString);
        #endif // TESTSUITE_BUILD
        ioFileClose();
        return;
      }
    }
    readLine(aimBuffer); // param
    readLine(tmpString); // value
    if(strcmp(aimBuffer, "PROGRAM") == 0) {
      pgmSizeInByte = stringToUint32(tmpString);
    }
    else {
      ioFileClose();
      return;
    }

    if(_addEndNeeded()) {
      _addSpaceAfterPrograms(2);
      *(firstFreeProgramByte - 2) = (ITM_END >> 8) | 0x80;
      *(firstFreeProgramByte - 1) =  ITM_END       & 0xff;
      *(firstFreeProgramByte    ) = 0xffu;
      *(firstFreeProgramByte + 1) = 0xffu;
      scanLabelsAndPrograms();
    }

    _addSpaceAfterPrograms(pgmSizeInByte);
    startOfProgram = firstFreeProgramByte - pgmSizeInByte;
    for(i=0; i<pgmSizeInByte; i++) {
      readLine(tmpString); // One byte
      startOfProgram[i] = stringToUint8(tmpString);
    }

    *(firstFreeProgramByte    ) = 0xffu;
    *(firstFreeProgramByte + 1) = 0xffu;
    scanLabelsAndPrograms();

    ioFileClose();

    if(loadedVersion < OLDEST_COMPATIBLE_PROGRAM_VERSION) { // Program incompatibility
      sprintf(tmpString," \n"
                        "   !!! Program version is too old !!!\n"
                        "Not compatible with current version\n"
                        " \n"
                        "It will not be loaded.");
      #if !defined(TESTSUITE_BUILD)
        show_warning(tmpString);
      #endif // TESTSUITE_BUILD
      return;
    }

    temporaryInformation = TI_PROGRAM_LOADED;
  #endif // !TESTSUITE_BUILD
}
