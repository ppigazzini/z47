// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/**
 * \file wp43.h
 */

#if !defined(WP43_H)
  #define WP43_H

  #pragma GCC diagnostic ignored "-Wunused-parameter"


  #if defined(LINUX)
    #include <math.h>
  #endif // LINUX

  #if defined(OSX)
    // needed by chdir
    #include <unistd.h>
  #endif // OSX

  #if defined(PC_BUILD)
    #include <glib.h>
    #include <gtk/gtk.h>
    #include <gdk/gdk.h>
  #endif // PC_BUILD

  #if defined(WIN32)
    #include <locale.h>
  #endif // WIN32

  #if defined(DMCP_BUILD)
    #define DBG_PRINT

    #if defined(DBG_PRINT)
      #include <stdio.h>
    #else
      #define printf(...)
    #endif

    #include <dmcp.h>
  #endif // DMCP_BUILD

  #include "mathematics/pcg_basic.h"
  #include "realType.h"
  #include "typeDefinitions.h"

  // Variables for the simulator
  #if defined(PC_BUILD) || defined(TESTSUITE_BUILD)
    extern bool_t               debugMemAllocation;
  #endif // PC_BUILD || TESTSUITE_BUILD

  #if defined(PC_BUILD)
    extern bool_t               calcLandscape;
    extern bool_t               calcAutoLandscapePortrait;
    extern GtkWidget           *screen;
    extern GtkWidget           *frmCalc;
    extern int16_t              screenStride;
    extern int16_t              debugWindow;
    extern uint32_t            *screenData;
    extern bool_t               screenChange;
    extern char                 debugString[10000];
    #if(DEBUG_REGISTER_L == 1)
      extern GtkWidget         *lblRegisterL1;
      extern GtkWidget         *lblRegisterL2;
    #endif // (DEBUG_REGISTER_L == 1)
    #if(SHOW_MEMORY_STATUS == 1)
      extern GtkWidget         *lblMemoryStatus;
    #endif // (SHOW_MEMORY_STATUS == 1)
    extern calcKeyboard_t       calcKeyboard[43];
    extern int                  currentBezel; // 0=normal, 1=AIM, 2=TAM
  #endif //PC_BUILD

  // Variables stored in FLASH
  extern const item_t                    indexOfItems[];
  extern const reservedVariableHeader_t  allReservedVariables[];
  extern const char                      commonBugScreenMessages[NUMBER_OF_BUG_SCREEN_MESSAGES][SIZE_OF_EACH_BUG_SCREEN_MESSAGE];
  extern const char                      errorMessages[NUMBER_OF_ERROR_CODES][SIZE_OF_EACH_ERROR_MESSAGE];
  extern const calcKey_t                 kbd_std[37];
  extern const calcKey_t                 kbd_std_WP43[37];
  extern const calcKey_t                 kbd_std_DM42[37];
  #if defined(PC_BUILD)
    extern const calcKey_t                 kbd_std_D47[37];
    extern const calcKey_t                 kbd_std_V47[37];
    extern const calcKey_t                 kbd_std_E47[37];
    extern const calcKey_t                 kbd_std_N47[37];
  #endif // PC_BUILD
  extern const font_t                    standardFont, numericFont;
  extern const font_t                   *fontForShortInteger;
  extern const font_t                   *cursorFont;
  extern const char                      digits[17];
  extern any34Matrix_t                   openMatrixMIMPointer;
  extern uint16_t                        matrixIndex;
  extern void                            (* const addition[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void);
  extern void                            (* const subtraction[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void);
  extern void                            (* const multiplication[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void);
  extern void                            (* const division[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void);
  extern void                            (*confirmedFunction)(uint16_t);
  extern const softmenu_t                softmenu[];
  extern real51_t                 const *gammaLanczosCoefficients;

  // Variables stored in RAM
  extern bool_t                 fnAsnDisplayUSER;
  extern bool_t                 funcOK;
  extern bool_t                 keyActionProcessed;
  extern bool_t                 fnKeyInCatalog;
  extern bool_t                 hourGlassIconEnabled;
  extern bool_t                 watchIconEnabled;
  extern bool_t                 printerIconEnabled;
  extern bool_t                 shiftF;
  extern bool_t                 shiftG;
  extern bool_t                 showContent;
  extern bool_t                 rbr1stDigit;
  extern bool_t                 updateDisplayValueX;
  extern bool_t                 thereIsSomethingToUndo;
  extern bool_t                 lastProgramListEnd;
  extern bool_t                 programListEnd;
  extern bool_t                 serialIOIconEnabled;
  extern bool_t                 pemCursorIsZerothStep;

  extern realContext_t          ctxtReal4;    //   Limited digits: used for high speed internal calcs
  extern realContext_t          ctxtReal34;   //   34 digits
  extern realContext_t          ctxtReal39;   //   39 digits: used for 34 digits intermediate calculations
  extern realContext_t          ctxtReal51;   //   51 digits: used for 34 digits intermediate calculations
  extern realContext_t          ctxtReal75;   //   75 digits: used in SLVQ
  extern realContext_t          ctxtReal1071; // 1071 digits: used in radian angle reduction
  extern realContext_t          ctxtReal2139; // 2139 digits: used for really big modulo

  extern registerHeader_t       globalRegister[NUMBER_OF_GLOBAL_REGISTERS];
  extern registerHeader_t       savedStackRegister[NUMBER_OF_SAVED_STACK_REGISTERS + NUMBER_OF_TEMP_REGISTERS];
  extern registerHeader_t      *currentLocalRegisters;
  extern dynamicSoftmenu_t      dynamicSoftmenu[NUMBER_OF_DYNAMIC_SOFTMENUS];

  extern dataBlock_t            allSubroutineLevels;
  extern dataBlock_t           *statisticalSumsPointer;
  extern dataBlock_t           *savedStatisticalSumsPointer;
  extern dataBlock_t           *ram;
  extern dataBlock_t           *currentLocalFlags;
  extern dataBlock_t           *currentSubroutineLevelData;

  extern namedVariableHeader_t *allNamedVariables;
  extern softmenuStack_t        softmenuStack[SOFTMENU_STACK_SIZE];
  extern userMenuItem_t         userMenuItems[18];
  extern userMenuItem_t         userAlphaItems[18];
  extern userMenu_t            *userMenus;
  extern programmableMenu_t     programmableMenu;
  extern calcKey_t              kbd_usr[37];
  extern calcRegister_t         errorMessageRegisterLine;
  extern glyph_t                glyphNotFound;
  extern freeMemoryRegion_t     freeMemoryRegions[MAX_FREE_REGION];
  extern pcg32_random_t         pcg32_global;
  extern labelList_t           *labelList;
  extern labelList_t           *flashLabelList;
  extern programList_t         *programList;
  extern programList_t         *flashProgramList;
  extern angularMode_t          currentAngularMode;
  extern formulaHeader_t       *allFormulae;

  extern uint8_t               *beginOfCurrentProgram;
  extern uint8_t               *endOfCurrentProgram;
  extern uint8_t               *firstDisplayedStep;
  extern uint8_t               *currentStep;

  extern char                  *tmpString;
  extern char                  *tmpStringLabelOrVariableName;
  extern char                  *errorMessage;
  extern char                  *aimBuffer; // aimBuffer is also used for NIM
  extern char                  *nimBufferDisplay;

  /**
   * Buffer for output of TAM current state. After calling ::tamProcessInput this
   * buffer is updated to the latest TAM state and should be redrawn to the relevant
   * part of the screen.
   */
  extern char                  *tamBuffer;
  extern char                  *userKeyLabel;
  extern char                   asmBuffer[5];
  extern char                   oldTime[8];
  extern char                   dateTimeString[12];
  extern char                   displayValueX[DISPLAY_VALUE_LEN];
  extern uint16_t               gapItemLeft;
  extern uint16_t               gapItemRight;
  extern uint16_t               gapItemRadix;
  extern uint8_t                numScreensStandardFont;
  extern uint8_t                currentAsnScr;
  extern uint8_t                currentFntScr;
  extern uint8_t                currentFlgScr;
  extern uint8_t                lastFlgScr;
  extern uint8_t                displayFormat;
  extern uint8_t                displayFormatDigits;
  extern uint8_t                timeDisplayFormatDigits;
  extern uint8_t                shortIntegerWordSize;
  extern uint8_t                significantDigits;
  extern uint8_t                shortIntegerMode;
  extern uint8_t                previousCalcMode;
  extern uint8_t                grpGroupingLeft;
  extern uint8_t                grpGroupingGr1LeftOverflow;
  extern uint8_t                grpGroupingGr1Left;
  extern uint8_t                grpGroupingRight;
  extern uint8_t                roundingMode;
  extern uint8_t                calcMode;
  extern uint8_t                nextChar;
  extern uint8_t                displayStack;
  extern uint8_t                cachedDisplayStack;
  extern uint8_t                displayStackSHOIDISP;         //JM SHOIDISP
  extern uint8_t                scrLock;
  extern bool_t                 numLock;                      //JM
  extern uint8_t                alphaCase;
  extern uint8_t                numLinesNumericFont;
  extern uint8_t                numLinesStandardFont;
  extern uint8_t                cursorEnabled;
  extern uint8_t                nimNumberPart;
  extern uint8_t                hexDigits;
  extern uint8_t                lastErrorCode;
  extern uint8_t                temporaryInformation;
  extern uint8_t                rbrMode;
  extern uint8_t                numScreensNumericFont;
  extern uint8_t                timerCraAndDeciseconds;
  extern uint8_t                programRunStop;
  extern uint8_t                lastKeyCode;
  extern uint8_t                entryStatus; // 0x01 for the entry flag, backed up to 0x02 for undo
  extern uint8_t                screenUpdatingMode;
  extern uint8_t               *beginOfProgramMemory;
  extern uint8_t               *firstFreeProgramByte;
  extern bool_t                 statisticalSumsUpdate;

  /**
   * Instance of the internal state for TAM.
   */
  extern tamState_t             tam;
  extern int16_t                currentRegisterBrowserScreen;
  extern int16_t                lineTWidth;
  extern int16_t                rbrRegister;
  extern int16_t                catalog;
  extern int16_t                lastCatalogPosition[NUMBER_OF_CATALOGS];
  extern int16_t                showFunctionNameItem;
  extern int16_t                exponentSignLocation;
  extern int16_t                denominatorLocation;
  extern int16_t                imaginaryExponentSignLocation;
  extern int16_t                imaginaryMantissaSignLocation;
  extern int16_t                exponentLimit;
  extern int16_t                exponentHideLimit;
  extern int16_t                showFunctionNameCounter;
  extern int16_t                dynamicMenuItem;
  extern int16_t               *menu_RAM;
  extern int16_t                numberOfTamMenusToPop;
  extern int16_t                itemToBeAssigned;
  extern int16_t                cachedDynamicMenu;

  extern uint16_t               globalFlags[7];
  extern int16_t                longpressDelayedkey2;         //JM
  extern int16_t                longpressDelayedkey3;         //JM
  extern int16_t                T_cursorPos;                  //JMCURSOR
  extern int16_t                displayAIMbufferoffset;       //JMCURSOR
  extern uint16_t               showRegis;                    //JMSHOW
  extern int16_t                ListXYposition;               //JM
  extern int16_t                mm_MNU_HOME;                  //JM
  extern int16_t                mm_MNU_ALPHA;                 //JM
  extern int16_t                MY_ALPHA_MENU;                //JM Replaced define
  extern uint8_t                DRG_Cycling;                  //JM
  extern uint8_t                DM_Cycling;                   //JM
  extern int16_t                JM_auto_doublepress_autodrop_enabled;  //JM TIMER CLRDROP //drop
  extern int16_t                JM_auto_longpress_enabled;    //JM TIMER CLRDROP //clstk
  extern uint8_t                JM_SHIFT_HOME_TIMER1;         //Local to keyboard.c, but defined here
  extern bool_t                 ULFL, ULGL;                   //JM Underline
  extern int16_t                FN_key_pressed, FN_key_pressed_last; //JM LONGPRESS FN
  extern bool_t                 FN_timeouts_in_progress;      //JM LONGPRESS FN
  extern bool_t                 Shft_timeouts;                //JM SHIFT NEW FN
  extern bool_t                 FN_timed_out_to_NOP;          //JM LONGPRESS FN
  extern bool_t                 FN_timed_out_to_RELEASE_EXEC; //JM LONGPRESS FN
  extern bool_t                 FN_handle_timed_out_to_EXEC;
  extern bool_t                 bcdDisplay;
  extern bool_t                 topHex;
  extern bool_t                 SI_All;
  extern bool_t                 CPXMULT;
  extern uint8_t                bcdDisplaySign;
  extern uint8_t                LongPressM;
  extern uint8_t                LongPressF;
  extern uint8_t                fgLN;
  extern char                   indexOfItemsXEQM[18*8];       //JMXEQ
  extern int16_t                fnXEQMENUpos;                 //JMXEQ
  extern uint8_t                last_CM;                      //Do extern !!
  extern uint8_t                FN_state; // = ST_0_INIT;

  // Variables from jm.h
  extern bool_t                 eRPN;                         //JM eRPN Create a flag to enable or disable eRPN. See bufferize.c
  extern bool_t                 HOME3;                        //JM HOME Create a flag to enable or disable triple shift HOME3; enable or disable TRIPLE SHIFT TIMER.
  extern bool_t                 MYM3;                         //JM HOME Create a flag to enable or disable triple shift MYM3; enable or disable TRIPLE SHIFT TIMER.
  extern bool_t                 ShiftTimoutMode;              //JM HOME Create a flag to enable or disable SHIFT TIMER CANCEL.
  extern bool_t                 BASE_HOME;                    //JM BASEHOME Create a flag to enable or disable triple shift
  extern int16_t                Norm_Key_00_VAR;              //JM USER NORMAL
  extern uint8_t                Input_Default;                //JM Input Default
  extern bool_t                 BASE_MYM;                     //JM Screen / keyboard operation setup
  extern bool_t                 jm_G_DOUBLETAP;               //JM Screen / keyboard operation setup
  extern float                  graph_xmin;                   //JM Graph
  extern float                  graph_xmax;                   //JM Graph
  extern float                  graph_ymin;                   //JM Graph
  extern float                  graph_ymax;                   //JM Graph
  extern bool_t                 jm_LARGELI;                   //JM flag to keep large font numbers on screen
  extern bool_t                 constantFractions;            //JM
  extern uint8_t                constantFractionsMode;        //JM
  extern bool_t                 constantFractionsOn;          //JM
  // Variables from jm.h & xeqm.c
  extern uint32_t               indic_x;                      //JM program progress indicators
  extern uint32_t               indic_y;                      //JM program progress indicators


  extern uint16_t               glyphRow[NUMBER_OF_GLYPH_ROWS];
  extern uint16_t               freeProgramBytes;
  extern uint16_t               firstDisplayedLocalStepNumber;
  extern uint16_t               numberOfLabels;
  extern uint16_t               numberOfPrograms;
  extern uint16_t               numberOfNamedVariables;
  extern uint16_t               currentLocalStepNumber;
  extern uint16_t               currentProgramNumber;
  extern uint16_t               lrSelection;
  extern uint16_t               lrSelectionUndo;
  extern uint16_t               lrChosen;
  extern uint16_t               lrChosenUndo;
  extern uint16_t               lastPlotMode;
  extern uint16_t               plotSelection;
  extern uint16_t               currentViewRegister;
  extern uint16_t               currentSolverStatus;
  extern uint16_t               currentSolverProgram;
  extern uint16_t               currentSolverVariable;
  extern uint16_t               currentSolverNestingDepth;
  extern uint16_t               numberOfFormulae;
  extern uint16_t               currentFormula;
  extern uint16_t               numberOfUserMenus;
  extern uint16_t               currentUserMenu;
  extern uint16_t               userKeyLabelSize;
  extern uint16_t               currentInputVariable;
  extern uint16_t               currentMvarLabel;
  #if(REAL34_WIDTH_TEST == 1)
    extern uint16_t               largeur;
  #endif // (REAL34_WIDTH_TEST == 1)

  extern int32_t                numberOfFreeMemoryRegions;
  extern int32_t                lgCatalogSelection;
  extern int32_t                graphVariable;

  extern uint32_t               firstGregorianDay;
  extern uint32_t               denMax;
  extern uint32_t               lastDenominator;
  extern uint32_t               lastIntegerBase;
  extern uint32_t               xCursor;
  extern uint32_t               yCursor;
  extern uint32_t               tamOverPemYPos;
  extern uint32_t               timerValue;
  extern uint32_t               timerStartTime;
  extern uint32_t               timerTotalTime;
  extern uint32_t               pointerOfFlashPgmLibrary;
  extern uint32_t               sizeOfFlashPgmLibrary;

  extern uint64_t               shortIntegerMask;
  extern uint64_t               shortIntegerSignBit;
  extern uint64_t               systemFlags;
  extern uint64_t               savedSystemFlags;

  extern size_t                 gmpMemInBytes;
  extern size_t                 wp43MemInBlocks;

  extern real_t                 SAVED_SIGMA_LASTX;
  extern real_t                 SAVED_SIGMA_LASTY;
  extern int32_t                SAVED_SIGMA_LAct;

  extern uint16_t               lrSelectionHistobackup;
  extern uint16_t               lrChosenHistobackup;
  extern int16_t                histElementXorY;
  extern real34_t               loBinR;
  extern real34_t               nBins ;
  extern real34_t               hiBinR;
  extern char                   statMx[8];
  extern char                   plotStatMx[8];
  extern calcRegister_t         regStatsXY;


  extern bool_t                 temporaryFlagRect;
  extern bool_t                 temporaryFlagPolar;
  extern int                    vbatIntegrated;


  #if defined(DMCP_BUILD)
    extern bool_t              backToDMCP;
  #if defined(BUFFER_CLICK_DETECTION)
    extern uint32_t            timeStampKey;                                      //dr - internal keyBuffer POC
  #endif // BUFFER_CLICK_DETECTION
//  extern int                  keyAutoRepeat; // Key repetition
//  extern int16_t              previousItem;
    extern uint32_t             nextTimerRefresh;

    int                         convertKeyCode(int key);
  #endif // DMCP_BUILD
#endif // !WP43_H
