// SPDX-License-Identifier: GPL-3.0-only
//
// The calculator, as far as c43's saveRestorePrograms.c is concerned.
//
// Same shape as the flags lane (REPORT-31 M31-2), for the same reasons: this
// claims upstream's `C47_H` guard because saveRestorePrograms.c sits next to the
// real c47.h and its quoted `#include "c47.h"` would find that one first; and it
// includes c43's own pure headers rather than copying constants, so a c43 value
// change reaches the lane instead of being frozen here.
//
// The frozen oracle this replaced had drifted badly -- it modelled neither the
// pre-load screening pass, nor the RAM-full bound, nor the `TI_NO_INFO` reset at
// load entry, and it restored the saved program number on an error path where
// c43 does not.

#ifndef C47_H
#define C47_H

#include <inttypes.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef bool bool_t;
typedef int16_t calcRegister_t;

// Placeholders for numeric/GUI types named in structs this lane never touches.
typedef struct {
  uint8_t opaque[64];
} real_t;
typedef struct {
  uint8_t opaque[16];
} real34_t;
typedef struct {
  real34_t real;
  real34_t imag;
} complex34_t;
typedef struct {
  uint64_t state;
  uint64_t inc;
} pcg32_random_t;
typedef struct Z47ProgramSerializationGtkWidget GtkWidget;

#include "../../../upstream/src/c47/defines.h"
#include "../../../upstream/src/c47/items.h"
#include "../../../upstream/src/c47/typeDefinitions.h"
#include "../../../upstream/src/c47/hal/io.h"
#include "../../../upstream/src/c47/programming/nextStep.h"
#include "../../../upstream/src/c47/fonts.h"

// ---------------------------------------------------------------------------
// Program memory and the tables around it. Defined by
// program_serialization_fake_runtime.c and shared by both implementations.
// ---------------------------------------------------------------------------
extern uint32_t *ram;
extern uint8_t *beginOfProgramMemory;
extern uint8_t *firstFreeProgramByte;
extern uint8_t *beginOfCurrentProgram;
extern uint8_t *endOfCurrentProgram;
extern uint8_t *firstDisplayedStep;
extern uint8_t *currentStep;
extern uint16_t freeProgramBytes;
extern uint16_t firstDisplayedLocalStepNumber;
extern uint16_t currentLocalStepNumber;
extern uint16_t currentProgramNumber;
extern uint16_t numberOfPrograms;
extern uint16_t numberOfLabels;
extern bool_t programListEnd;
extern bool_t lastProgramListEnd;
extern labelList_t *labelList;
extern programList_t *programList;
extern tamState_t tam;
extern int16_t dynamicMenuItem;
extern uint8_t temporaryInformation;
extern int16_t lastFunc;

// The step grammar the pre-load screening pass reads. NOT a reference: it is
// shared INPUT, read identically by c43's `_screenFileStep` and by the Zig
// owner's `screenFileStep`, so a case can construct a specific opcode class and
// still be comparing the two implementations rather than a table.
extern item_t indexOfItems[LAST_ITEM + 1];
int16_t paramTailBytes(uint16_t paramMode, uint16_t op, uint8_t opParam);
int16_t literalTailBytes(uint8_t literalType);

extern char *tmpString;
extern char *tmpStringLabelOrVariableName;
extern char *aimBuffer;
extern char *errorMessage;

// ---------------------------------------------------------------------------
// Everything saveRestorePrograms.c calls out to.
// ---------------------------------------------------------------------------
int ioFileOpen(ioFilePath_t path, ioFileMode_t mode);
void ioFileWrite(const void *buffer, uint32_t size);
void ioFileClose(void);
void ioFileSeek(uint32_t position);
void readLine(char *line, size_t maxLen);
uint8_t stringToUint8(const char *str);
uint32_t stringToUint32(const char *str);
void show_warning(char *string);
void scanLabelsAndPrograms(void);
void goToGlobalStep(int32_t step);
void fnGoto(uint16_t label);
uint16_t findNamedLabel(const char *labelName, uint8_t labelType);
uint8_t boundProgramNameLength(const uint8_t *nameStart, uint8_t claimed);
void resizeProgramMemory(uint16_t newSizeInBlocks);
bool_t isAtEndOfProgram(const uint8_t *step);
uint32_t getFreeRamMemory(void);
void displayCalcErrorMessage(uint8_t errorCode, calcRegister_t errMessageRegisterLine, calcRegister_t disUsedCanBeRemoved);
void moreInfoOnError(const char *m1, const char *m2, const char *m3, const char *m4);
void *xcopy(void *dest, const void *source, uint32_t n);

// The RTF/text export half of saveRestorePrograms.c. Compiled, never called by
// this lane -- but compiled means an upstream change there is a build failure
// here rather than silence.
uint16_t getNumberOfSteps(void);
void defineFirstDisplayedStep(void);
void decodeOneStep_XPORT(const uint8_t *step);
uint32_t _getProgramSize(void);
bool_t getSystemFlag(int32_t sf);
void printProgram(uint16_t mode, uint16_t unused);
void stringToASCII(const char *str, char *ascii);
void stringToRTF(const char *str, char *rtf);
void stringCopy(char *dest, const char *source);
int32_t stringByteLength(const char *str);

// The Zig owner's exports, under their c43 names -- the side under test.
#include "../../../upstream/src/c47/saveRestorePrograms.h"

#endif
