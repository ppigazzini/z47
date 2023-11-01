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

/**
 * \file typeDefinitions.h
 */
#if !defined(TYPEDEFINITIONS_H)
#define TYPEDEFINITIONS_H

#include "realType.h"
#include "mathematics/pcg_basic.h"
#include <stdint.h>
  #if defined(PC_BUILD)
  #include <gtk/gtk.h>
  #include <gdk/gdk.h>
  #endif // PC_BUILD

/**
 * \union multiplyDivide_t
   * Used for unit conversions.
   */
typedef enum {
  multiply,
  divide
} multiplyDivide_t;


/**
 * \struct calcKey_t
   * Structure keeping the informations for one key.
   */
typedef struct {
  int16_t keyId;       ///< ID of the key
  int16_t primary;     ///< ID of the primary function of the key
  int16_t fShifted;    ///< ID of the f shifted function of the key
  int16_t gShifted;    ///< ID of the g shifted function of the key
  int16_t keyLblAim;   ///< ID of the main label of the key
  int16_t primaryAim;  ///< ID of the primary AIM function: latin letters
  int16_t fShiftedAim; ///< ID of the f shifted AIM function:
  int16_t gShiftedAim; ///< ID of the g shifted AIM function: greek letters
  int16_t primaryTam;  ///< ID of the primary TAM function of the key
} calcKey_t;


/**
 * \struct glyph_t
 * Structure keeping the informations for one glyph.
 */
typedef struct {
  uint16_t charCode;         ///< Unicode code point
  uint8_t  colsBeforeGlyph;  ///< Number of empty columns before the glyph
  uint8_t  colsGlyph;        ///< Number of columns of the glyph
  uint8_t  colsAfterGlyph;   ///< Number of empty columns afer the glyph
  uint8_t  rowsAboveGlyph;   ///< Number of empty rows above the glyph
  uint8_t  rowsGlyph;        ///< Number of rows of the glyph
  uint8_t  rowsBelowGlyph;   ///< Number of empty rows below the glypg
  int16_t  rank1;            ///< Rank of the replacement glyph
  int16_t  rank2;            ///< Rank of the glyph
  char     *data;            ///< Hexadecimal data representing the glyph.
                             ///< There are rowsGlyph x (colsGlyph rounded up to 8 bit boundary) bytes
} glyph_t;


/**
 * \struct font_t
 * Font description.
 */
typedef struct {
  int8_t  id;              ///< 0=numeric 1=standard
  uint16_t numberOfGlyphs; ///< Number of glyphs in the font
  glyph_t glyphs[];        ///< Pointer to the glyph description structure
} font_t;


/**
 * \struct freeMemoryRegion_t
 * Keeps track of free memory regions.
 */
typedef struct {
  uint16_t address;      ///< Address of the free memory region
  uint16_t sizeInBlocks; ///< Size in blocks of the free memory region
} freeMemoryRegion_t;


/**
 * \enum dataType_t
 * Different data types.
 */
typedef enum {
  dtLongInteger     =  0,  ///< Z arbitrary precision integer
  dtReal34          =  1,  ///< R double precision real (128 bits)
  dtComplex34       =  2,  ///< C double precision complex (2x 128 bits)
  dtTime            =  3,  ///< Time
  dtDate            =  4,  ///< Date in various formats
  dtString          =  5,  ///< Alphanumeric string
  dtReal34Matrix    =  6,  ///< Double precision vector or matrix
  dtComplex34Matrix =  7,  ///< Double precision complex vector or matrix
  dtShortInteger    =  8,  ///< Short integer (64 bit)
  dtConfig          =  9,  ///< Configuration
  //dtLabel           = 10,  ///< Label
  //dtSystemInteger   = 11,  ///< System integer (64 bits)
  //dtFlags           = 12,  ///< Flags
  //dtPgmStep         = 13,  ///< Program step
  //dtDirectory       = 14,  ///< Program
} dataType_t; // 4 bits (NOT 5 BITS)


/**
 * \enum bool_t
 * Boolean type.
 */
typedef enum {
  false = 0,     ///< Value for false
  true  = !false ///< Value for true
} bool_t; // 1 bit


/**
 * \enum angularMode_t
 * Angular units.
 */
typedef enum {
  amRadian    =  0, // radian
  amGrad      =  1, // grad
  amDegree    =  2, // degree
  amDMS       =  3,
  amMultPi    =  4,
  amNone      =  5,
  amSecond    =  6, // not an angular but a time unit: for the routine unified with the real type
  TM_HMS      =  7, // JM not an angular but a time unit: for the C43 usage
  amAngleMask = 15,
  amPolar     = 16   // JM bit 4 of the 5 bits is used for Polar
} angularMode_t;


/**
 * \enum commonBugScreenMessageCode_t
 * Common bug screen messages.
 */
typedef enum {
  bugMsgValueFor                 = 0,
  bugMsgCalcModeWhileProcKey     = 1,
  bugMsgNumByte                  = 2,
  bugMsgNoNamedVariables         = 3,
  bugMsgValueReturnedByFindGlyph = 4,
  bugMsgUnexpectedSValue         = 5,
  bugMsgDataTypeUnknown          = 6,
  bugMsgRegistMustBeLessThan     = 7,
  bugMsgNotDefinedMustBe         = 8,
  bugMsgRbrMode                  = 9,
} commonBugScreenMessageCode_t;


/**
 * \struct dtConfigDescriptor_t
 * Configuration for STOCFG and RCLCFG.
 */
typedef struct {
  uint8_t       shortIntegerMode;
  uint8_t       shortIntegerWordSize;
  uint8_t       displayFormat;
  uint8_t       displayFormatDigits;
  uint16_t        gapItemLeft;
  uint16_t        gapItemRight;
  uint16_t        gapItemRadix;
  uint8_t         grpGroupingLeft;
  uint8_t         grpGroupingGr1LeftOverflow;
  uint8_t         grpGroupingGr1Left;
  uint8_t         grpGroupingRight;
  uint8_t       displayStack;
  uint8_t       roundingMode;
  uint8_t       timeDisplayFormatDigits;
  uint8_t       reservedForPossibleFutureUse[3];
  angularMode_t currentAngularMode;
  uint16_t      lrSelection;
  uint16_t      lrChosen;
  uint32_t      denMax;
  uint32_t      firstGregorianDay;
  uint64_t      systemFlags;
  calcKey_t     kbd_usr[37];
  uint8_t fgLN;
  bool_t eRPN;
  bool_t HOME3;
  bool_t ShiftTimoutMode;
  bool_t CPXMULT;
  bool_t BASE_HOME;
  bool_t compatibility_bool0;               //Spare Byte !problem
  int16_t Norm_Key_00_VAR;
  uint8_t Input_Default;
  bool_t compatibility_bool00;               //Spare Byte !problem
  bool_t BASE_MYM;
  bool_t jm_G_DOUBLETAP;
  float  compatibility_float1;              //Spare float
  float  compatibility_float2;              //Spare float
  float  compatibility_float3;              //Spare float
  float  compatibility_float4;              //Spare float
  float  compatibility_float5;              //Spare float
  float  compatibility_float6;              //Spare float
  bool_t compatibility_bool1;               //Spare Byte
  bool_t compatibility_bool2;               //Spare Byte
  bool_t compatibility_bool3;               //Spare Byte
  bool_t PLOT_VECT;
  bool_t PLOT_NVECT;
  bool_t PLOT_SCALE;
  bool_t compatibility_bool4;               //Spare Byte
  bool_t PLOT_LINE;
  bool_t PLOT_CROSS;
  bool_t PLOT_BOX;
  bool_t PLOT_INTG;
  bool_t PLOT_DIFF;
  bool_t PLOT_RMS;
  bool_t PLOT_SHADE;
  bool_t PLOT_AXIS;
  int8_t PLOT_ZMX;
  int8_t PLOT_ZMY;
  bool_t compatibility_bool5;               //Spare Byte
  bool_t jm_LARGELI;
  bool_t constantFractions;
  uint8_t constantFractionsMode;
  bool_t constantFractionsOn;
  uint8_t displayStackSHOIDISP;
  bool_t bcdDisplay;
  bool_t topHex;
  uint8_t bcdDisplaySign;
  uint8_t DRG_Cycling;
  uint8_t DM_Cycling;
  bool_t SI_All;
  bool_t LongPressM;
  bool_t LongPressF;

  //Added 2023-09-12
  //Note: Do not change entries going forward to maintain compatibility
  //Should any be added, ensure that the defaults are appropriately added when reading the state file
  uint32_t       lastDenominator;
  uint8_t        significantDigits;
  pcg32_random_t pcg32_global;
  int16_t        exponentLimit;
  int16_t        exponentHideLimit;
  uint32_t       lastIntegerBase;
  bool_t MYM3;

} dtConfigDescriptor_t;


/**
 * \union registerHeader_t
 * 32 bits describing the register.
 */
typedef union {
  uint32_t descriptor;
  struct {
    uint32_t pointerToRegisterData : 16; ///< Memory block number
    uint32_t dataType              :  4; ///< dtLongInteger, dtReal34, ...
    uint32_t tag                   :  5; ///< Short integer base, real34 angular mode, or long integer sign; complex34 angle mode + Polar
    uint32_t readOnly              :  1; ///< The register or variable is readOnly if this field is 1 (used for system named variables)
    uint32_t notUsed               :  6; ///< 6 bits free
  };
} registerHeader_t;


/**
 * \union dataBlock_t
 * Header for datatypes: string, long integer, and matrix.
 */
typedef union {
  uint32_t data;
  uint32_t localFlags;

  struct {
    uint16_t dataMaxLength;             ///< String max length (includind terminating \0) in blocks or Long integer max length in blocks
    uint16_t dummy;                     ///< Dummy
  };

  struct {
    uint16_t variableNameLen;           ///< Size of the name in blocs: 1 to 4, up to 15 bytes = 7 double byte glyphs + trailing 0
    uint16_t ptrToVariableName;         ///< Pointer to the name of the variable
  };

  struct {
    uint16_t matrixRows;                ///< Number of rows in the matrix
    uint16_t matrixColumns;             ///< Number of columns in the matrix
  };

  struct {
    uint16_t numberOfSubroutineLevels;  ///< Number of subroutine levels
    uint16_t ptrToSubroutineLevel0Data; ///< Pointer to subroutine level 0 data
  };

  struct {
    uint16_t numberOfNamedVariables;    ///< Number of named variables
    uint16_t ptrToNamedVariablesList;   ///< Pointer to the named variable list
  };

  struct {
    int16_t  returnProgramNumber;       ///< return program number >0 if in RAM and <0 if in FLASH
    uint16_t returnLocalStep;           ///< Return local step number in program number
  };

  struct {
    uint8_t  numberOfLocalFlags;        ///< Number of allocated local flags
    uint8_t  numberOfLocalRegisters;    ///< Number of allocated local registers
    uint16_t subroutineLevel;           ///< Subroutine level
  };

  struct {
    uint16_t ptrToNextLevel;            ///< Pointer to next level of subroutine data
    uint16_t ptrToPreviousLevel;        ///< Pointer to previous level of subroutine data
  };
} dataBlock_t;


/**
 * \struct namedVariableHeader_t
 * Header for named variables.
 */
typedef struct {
  registerHeader_t header;  ///< Header
  uint8_t variableName[16]; ///< Variable name
} namedVariableHeader_t;


/**
 * \struct reservedVariableHeader_t
 * Header for system named variables.
 */
typedef struct {
  registerHeader_t header;         ///< Header
  uint8_t reservedVariableName[8]; ///< Variable name
} reservedVariableHeader_t;


/**
 * \struct formulaHeader_t
 * Header for EQN formulae.
 */
typedef struct {
  uint16_t pointerToFormulaData; ///< Memory block number
  uint8_t  sizeInBlocks;         ///< Size of allocated memory block
  uint8_t  unused;               ///< Padding
} formulaHeader_t;


/**
 * \enum videoMode_t
 * Video mode: normal video or reverse video.
 */
typedef enum {
  vmNormal,  ///< Normal mode: black on white background
  vmReverse  ///< Reverse mode: white on black background
} videoMode_t; // 1 bit


/**
 * \struct softmenu_t
   * Structure keeping the informations for one softmenu.
   */
typedef struct {
  int16_t menuItem;           ///< ID of the menu. The item is always negative and -item must be in the indexOfItems area
  int16_t numItems;           ///< Number of items in the softmenu (must be a multiple of 6 for now)
  const int16_t *softkeyItem; ///< Pointer to the first item of the menu
} softmenu_t;


/**
 * \struct dynamicSoftmenu_t
   * Structure keeping the informations for one variable softmenu.
   */
typedef struct {
  int16_t menuItem;           ///< ID of the menu. The item is always negative and -item must be in the indexOfItems area
  int16_t numItems;           ///< Number of items in the dynamic softmenu (must be a multiple of 6 for now)
  uint8_t *menuContent;       ///< Pointer to the menu content
} dynamicSoftmenu_t;


/**
 * \struct softmenuStack_t
   * Stack of softmenus.
   */
typedef struct {
  int16_t softmenuId; ///< Softmenu ID = rank in dynamicSoftmenu or softmenu
  int16_t firstItem;  ///< Current first item on the screen (unshifted F1 = bottom left)
} softmenuStack_t;


/**
 * \typedef calcRegister_t
 * \brief A type for calculator registers
*/
typedef int16_t calcRegister_t;

/**
 * \struct real34Matrix_t
 * A type for real34Matrix.
 */
typedef struct {
   dataBlock_t header;
   real34_t    *matrixElements;
} real34Matrix_t;

/**
 * \struct complex34Matrix_t
 * A type for complex34Matrix.
 */
typedef struct {
   dataBlock_t header;
   complex34_t *matrixElements;
} complex34Matrix_t;

/**
 * \union any34Matrix_t
 * Stores either real34Matrix_t or complex34Matrix_t.
 */
typedef union {
   dataBlock_t       header;
   real34Matrix_t    realMatrix;
   complex34Matrix_t complexMatrix;
} any34Matrix_t;

/**
 * \struct item_t
 * Structure keeping the information for one item.
 */
typedef struct {
  void     (*func)(uint16_t); ///< Function called to execute the item
  uint16_t param;             ///< 1st parameter to the above function
  char     itemCatalogName [16]; ///< Name of the item in the catalogs and in programs
  char     itemSoftmenuName[16]; ///< Representation of the item in the menus and on the keyboard
  uint16_t tamMinMax;         ///< Minimal value (2 bits) and maximal value (14 bits) for TAM argument
  //uint16_t tamMin;            ///< Minimal value for TAM argument
  //uint16_t tamMax;            ///< Maximal value for TAM argument
  uint16_t status;            ///< Catalog, stack lift status and undo status
  //char     catalog;           ///< Catalog in which the item is located: see #define CAT_* in defines.h
  //uint8_t  stackLiftStatus;   ///< Stack lift status after item execution.
  //uint8_t  undoStatus;        ///< Undo status after item execution.
} item_t;


/**
 * \struct userMenuItem_t
 * Structure keeping the information for one item of MyMenu and MyAlpha.
 */
typedef struct {
  int16_t  item;               ///< Item ID
  int16_t  unused;             ///< Padding
  char     argumentName[16];   ///< Name of variable or label
} userMenuItem_t;

/**
 * \struct userMenu_t
 * Structure keeping the information for a user-defined menu.
 */
typedef struct {
  char           menuName[16];  ///< Name of menu
  userMenuItem_t menuItem[18];  ///< Items
} userMenu_t;


/**
 * \struct programmableMenu_t
 * Structure keeping the information for programmable menu.
 */
typedef struct {
  char           itemName[18][16]; ///< Name of items
  uint16_t       itemParam[21];    ///< Parameter, XEQ if MSB set, GTO if MSB clear
  uint16_t       unused;           ///< Padding
} programmableMenu_t;


/**
 * \struct labelList_t
 * Structure keeping the information for a program label.
 */
typedef struct {
  int16_t  program;             ///< Program id
  int32_t  step;                ///< Step number of the label: <0 for a local label and >0 for a global label
  uint8_t *labelPointer;        ///< Pointer to the byte after the 0x01 op code (LBL)
  uint8_t *instructionPointer;  ///< Pointer to the instruction following the label
} labelList_t;


/**
 * \struct programList_t
 * Structure keeping the information for a program.
 */
typedef struct {
  int32_t  step;                ///< (Step number + 1) of the program begin
  uint8_t *instructionPointer;  ///< Pointer to the program begin
} programList_t;


/**
 * \struct tamState_t
 * State for TAM mode. Most of this state is internal and so not documented.
 */
typedef struct {
  /**
   * The mode used by TAM processing. If non-zero then TAM mode is active.
   * This should be used to determine whether the calculator is in TAM mode:
   *
   *     if(tam.mode) {
   *       // the calculator is in TAM mode
   *     }
   */
  uint16_t   mode;
  int16_t    function;
  /**
   * Whether input is a string rather than a number. For example, a named variable.
   * If the calculator is in alpha mode then additional details apply. See
   * ::tamProcessInput for further details.
   */
  bool_t     alpha;
  int16_t    currentOperation;
  bool_t     dot;
  bool_t     indirect;
  int16_t    digitsSoFar;
  int16_t    value;
  int16_t    min;
  int16_t    max;
  /**
   * Only used for KEYG and KEYX
   */
  int16_t    key;
  bool_t     keyAlpha;
  bool_t     keyDot;
  bool_t     keyIndirect;
  bool_t     keyInputFinished;
} tamState_t;

  #if defined(PC_BUILD)
  /**
   * \struct calcKeyboard_t
   * Structure keeping key images, image sizes, and image locations.
   */
  typedef struct {
    int x, y;
    int width[4], height[4];
    GtkWidget *keyImage[4];
  } calcKeyboard_t;
  #endif // PC_BUILD
#endif // .TYPEDEFINITIONS_H
