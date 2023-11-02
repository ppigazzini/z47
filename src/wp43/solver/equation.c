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

/********************************************//**
 * \file equation.c
 ***********************************************/

#include "solver/equation.h"

#include "constantPointers.h"
#include "charString.h"
#include "defines.h"
#include "error.h"
#include "flags.h"
#include "fonts.h"
#include "hal/gui.h"
#include "items.h"
#include "memory.h"
#include "realType.h"
#include "registers.h"
#include "screen.h"
#include "stack.h"
#include "sort.h"
#include "wp43.h"



#if !defined(TESTSUITE_BUILD)

TO_QSPI static const char bugScreenUnknownOperator[] = "In function _parseWord: Unknown operator appeared!";
TO_QSPI static const char bugScreenUnknownFormulaParserMode[] = "In function _parseWord: Unknown mode of formula parser!";

  typedef struct {
    char     name[16];
    uint16_t opCode;
    uint16_t unused;
  } functionAlias_t;

  TO_QSPI static const functionAlias_t functionAlias[] = {
    //name                                   opCode           padding


//    { "SIN",                                 ITM_sin,         0}, // Sine
    { "sin",                                 ITM_sin,         0}, // C47 Sine
    { "asin",                                ITM_arcsin,      0}, // C47 Inverse sin
    { "arsin",                               ITM_arcsin,      0}, // C47 Inverse sin
    { "arcsin",                              ITM_arcsin,      0}, // C47 Inverse sin

//    { "COS",                                 ITM_cos,         0}, // Cosine
    { "cos",                                 ITM_cos,         0}, // C47 Cosine
    { "acos",                                ITM_arccos,      0}, // C47 Inverse cos
    { "arcos",                               ITM_arccos,      0}, // C47 Inverse cos
    { "arccos",                              ITM_arccos,      0}, // C47 Inverse cos

//    { "TAN",                                 ITM_tan,         0}, // Tangent
    { "tan",                                 ITM_tan,         0}, // C47 Tangent
    { "atan",                                ITM_arctan,      0}, // C47 Inverse tan
    { "artan",                               ITM_arctan,      0}, // C47 Inverse tan
    { "arctan",                              ITM_arctan,      0}, // C47 Inverse tan

    { "SINH",                                ITM_sinh,        0}, // Hyperbolic sine
//    { "sinh",                                ITM_sinh,        0}, // C47 Hyperbolic sine
    { "ASINH",                               ITM_arsinh,      0}, // Inverse hyperbolic sine
    { "asinh",                               ITM_arsinh,      0}, // C47 Inverse hyperbolic sine
    { "arcsinh",                             ITM_arsinh,      0}, // C47 Inverse hyperbolic sine
//    { "arsinh",                              ITM_arsinh,      0}, // C47 Inverse hyperbolic sine

    { "COSH",                                ITM_cosh,        0}, // Hyperbolic cosine
//    { "cosh",                                ITM_cosh,        0}, // C47 Hyperbolic cosine
    { "ACOSH",                               ITM_arcosh,      0}, // Inverse hyperbolic cosine
    { "acosh",                               ITM_arcosh,      0}, // C47 Inverse hyperbolic cosine
    { "arccosh",                             ITM_arcosh,      0}, // C47 Inverse hyperbolic cosine
//    { "arcosh",                              ITM_arcosh,      0}, // C47 Inverse hyperbolic cosine

    { "TANH",                                ITM_tanh,        0}, // Hyperbolic tangent
//    { "tanh",                                ITM_tanh,        0}, // C47 Hyperbolic tangent
    { "ATANH",                               ITM_artanh,      0}, // Inverse hyperbolic tangent
    { "atanh",                               ITM_artanh,      0}, // C47 Inverse hyperbolic tangent
    { "arctanh",                             ITM_artanh,      0}, // C47 Inverse hyperbolic tangent
//    { "artanh",                              ITM_artanh,      0}, // C47 Inverse hyperbolic tangent

//    { "ATAN2",                               ITM_atan2,       0}, // Binary arctangent
    { "atan2",                               ITM_atan2,       0}, // C47 Binary arctangent

    { "CEIL",                                ITM_CEIL,        0}, // Ceiling function
//    { "ceil",                                ITM_CEIL,        0}, // C47 Ceiling function
//    { "EXP",                                 ITM_EXP,         0}, // Natural exponential
    { "exp",                                 ITM_EXP,         0}, // C47 Natural exponential
    { "FLOOR",                               ITM_FLOOR,       0}, // Floor function
//    { "floor",                               ITM_FLOOR,       0}, // C47 Floor function
    { "g" STD_SUB_d STD_SUP_MINUS STD_SUP_1, ITM_GDM1,        0}, // Inverse Gudermannian function
    { "g" STD_SUB_d STD_SUP_MINUS_1,         ITM_GDM1,        0}, // Inverse Gudermannian function
    { "gd" STD_SUP_MINUS STD_SUP_1,          ITM_GDM1,        0}, // Inverse Gudermannian function
    { "gd" STD_SUP_MINUS_1,                  ITM_GDM1,        0}, // Inverse Gudermannian function
    { "gd",                                  ITM_GD,          0}, // Gudermannian function
    { "g" STD_SUB_d,                         ITM_GD,          0}, // C47 Gudermannian function
//    { "LB",                                  ITM_LOG2,        0}, // Binary logarithm
    { "lB",                                  ITM_LOG2,        0}, // C47 Binary logarithm
    { "lb",                                  ITM_LOG2,        0}, // C47 Binary logarithm
//    { "LG",                                  ITM_LOG10,       0}, // Common logarithm
    { "LG2",                                 ITM_LOG2,        0}, // C47 Binary logarithm
    { "lg",                                  ITM_LOG10,       0}, // C47 Common logarithm
//    { "LN",                                  ITM_LN,          0}, // Natural logarithm
    { "ln",                                  ITM_LN,          0}, // C47 Natural logarithm
    { "LOG" STD_SUB_1 STD_SUB_0,             ITM_LOG10,       0}, // C47 Common logarithm
    { "LOG" STD_SUB_2,                       ITM_LOG2,        0}, // C47 Binary logarithm
//    { "LOG",                                 ITM_LOG10,       0}, // C47 Common logarithm
    { "LOG10",                               ITM_LOG10,       0}, // Common logarithm
    { "LOG2",                                ITM_LOG2,        0}, // Binary logarithm
    { "log" STD_SUB_1 STD_SUB_0,             ITM_LOG10,       0}, // Common logarithm
    { "log" STD_SUB_2,                       ITM_LOG2,        0}, // Binary logarithm
    { "log10",                               ITM_LOG10,       0}, // Common logarithm
    { "log",                                 ITM_LOG10,       0}, // C47 Common logarithm
    { "log2",                                ITM_LOG2,        0}, // Binary logarithm
    { "MAX",                                 ITM_Max,         0}, // Maximum
//    { "max",                                 ITM_Max,         0}, // C47 Maximum
    { "MIN",                                 ITM_Min,         0}, // Minimum
//    { "min",                                 ITM_Min,         0}, // C47 Minimum
    { "W" STD_SUP_MINUS STD_SUP_1,           ITM_WM1,         0}, // Inverse function of Lambert's W
    { "W" STD_SUP_MINUS_1,                   ITM_WM1,         0}, // C47 Inverse function of Lambert's W
    { STD_GAMMA,                             ITM_GAMMAX,      0}, // Gamma function
    { STD_SQUARE_ROOT,                       ITM_SQUAREROOTX, 0}, // Square root (available through f SQRT in EIM)
    { STD_zeta,                              ITM_zetaX,       0}, // Riemann zeta function

    { "",                                    0,               0}  // Sentinel
  };
#endif // !TESTSUITE_BUILD

//Note: i, j and 𝝿 are special characters
//Note ARCSIN, ASIN, etc. will work from the items table


void fnEqNew(uint16_t unusedButMandatoryParameter) {
  if(numberOfFormulae == 0) {
    allFormulae = allocWp43(TO_BLOCKS(sizeof(formulaHeader_t)));
    if(allFormulae) {
      numberOfFormulae = 1;
      currentFormula = 0;
      allFormulae[0].pointerToFormulaData = WP43_NULL;
      allFormulae[0].sizeInBlocks = 0;
      graphVariable = 0;
    }
    else {
      displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function fnEqNew:", "there is not enough memory for a new equation!", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }
  }
  else {
    formulaHeader_t *newPtr = allocWp43(TO_BLOCKS(sizeof(formulaHeader_t)) * (numberOfFormulae + 1));
    if(newPtr) {
      for(uint32_t i = 0; i < numberOfFormulae; ++i) {
        newPtr[i + (i > currentFormula ? 1 : 0)] = allFormulae[i];
      }
      ++currentFormula;
      newPtr[currentFormula].pointerToFormulaData = WP43_NULL;
      newPtr[currentFormula].sizeInBlocks = 0;
      freeWp43(allFormulae, TO_BLOCKS(sizeof(formulaHeader_t)) * (numberOfFormulae));
      allFormulae = newPtr;
      ++numberOfFormulae;
      graphVariable = 0;
    }
    else {
      displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function fnEqNew:", "there is not enough memory for a new equation!", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }
  }
  fnEqEdit(NOPARAM);
}

void fnEqEdit(uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
    if(currentFormula < numberOfFormulae) {
      const char *equationString = TO_PCMEMPTR(allFormulae[currentFormula].pointerToFormulaData);
        if(equationString) {
          xcopy(aimBuffer, equationString, stringByteLength(equationString) + 1);
        }
        else {
          aimBuffer[0] = 0;
        }
      calcMode = CM_EIM;
      alphaCase = AC_LOWER;
      nextChar = NC_NORMAL;//JM C43
      numLock = false;     //JM C43
      scrLock = NC_NORMAL;
      setSystemFlag(FLAG_ALPHA);
      yCursor = 0;
      xCursor = equationString ? stringGlyphLength(equationString) : 0;
      calcModeAimGui();
    }
  #endif // !TESTSUITE_BUILD
}

void fnEqDelete(uint16_t unusedButMandatoryParameter) {
  deleteEquation(currentFormula);
}

void fnEqCursorLeft(uint16_t unusedButMandatoryParameter) {
  if(xCursor > 0) {
    --xCursor;
  }
}

void fnEqCursorRight(uint16_t unusedButMandatoryParameter) {
  if(xCursor < (uint32_t)stringGlyphLength(aimBuffer)) {
    ++xCursor;
  }
}

void fnEqCalc(uint16_t unusedButMandatoryParameter) {
  #if defined(DEBUGUNDO)
    printf(">>> saveForUndo from fnEqCalc, calcMode = %i, something to undo (pre) = %i \n",calcMode, thereIsSomethingToUndo);
  #endif // DEBUGUNDO
  if(!thereIsSomethingToUndo && !CM_NO_UNDO) {
    saveForUndo();
  }
  setSystemFlag(FLAG_SOLVING);
  parseEquation(currentFormula, EQUATION_PARSER_XEQ, tmpString, tmpString + AIM_BUFFER_LENGTH);
  adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
  clearSystemFlag(FLAG_SOLVING);
}



void setEquation(uint16_t equationId, const char *equationString) {
  uint32_t newSizeInBlocks = TO_BLOCKS(stringByteLength(equationString) + 1);
  uint8_t *newPtr;
  if(allFormulae[equationId].sizeInBlocks == 0) {
    newPtr = allocWp43(newSizeInBlocks);
  }
  else {
    newPtr = reallocWp43(TO_PCMEMPTR(allFormulae[equationId].pointerToFormulaData), allFormulae[equationId].sizeInBlocks, newSizeInBlocks);
  }
  if(newPtr) {
    allFormulae[equationId].pointerToFormulaData = TO_WP43MEMPTR(newPtr);
  }
  else {
    displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function setEquation:", "there is not enough memory for a new equation!", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }
  allFormulae[equationId].sizeInBlocks = newSizeInBlocks;
  xcopy(TO_PCMEMPTR(allFormulae[equationId].pointerToFormulaData), equationString, stringByteLength(equationString) + 1);
}

void deleteEquation(uint16_t equationId) {
  if(equationId < numberOfFormulae) {
    if(allFormulae[equationId].sizeInBlocks > 0) {
      freeWp43(TO_PCMEMPTR(allFormulae[equationId].pointerToFormulaData), allFormulae[equationId].sizeInBlocks);
    }
    for(uint16_t i = equationId + 1; i < numberOfFormulae; ++i) {
      allFormulae[i - 1] = allFormulae[i];
    }
    freeWp43(allFormulae + (--numberOfFormulae), TO_BLOCKS(sizeof(formulaHeader_t)));
    if(numberOfFormulae == 0) {
      allFormulae = NULL;
    }
    if(numberOfFormulae > 0 && currentFormula >= numberOfFormulae) {
      currentFormula = numberOfFormulae - 1;
    }
    graphVariable = 0;
  }
}



#if !defined(TESTSUITE_BUILD)
  static void _showExponent(char **bufPtr, const char **strPtr, int16_t *strWidth) {
    switch(*(++(*strPtr))) {
      //case '1': {
      //  **bufPtr         = STD_SUP_1[0];
      //  *((*bufPtr) + 1) = STD_SUP_1[1];
      //  break;
      //}
      //case '2': {
      //  **bufPtr         = STD_SUP_2[0];
      //  *((*bufPtr) + 1) = STD_SUP_2[1];
      //  break;
      //}
      //case '3': {
      //  **bufPtr         = STD_SUP_3[0];
      //  *((*bufPtr) + 1) = STD_SUP_3[1];
      //  break;
      //}
      case '+': {
      **bufPtr         = STD_SUP_PLUS[0];
      *((*bufPtr) + 1) = STD_SUP_PLUS[1];
      break;
      }
      case '-': {
      **bufPtr         = STD_SUP_MINUS[0];
      *((*bufPtr) + 1) = STD_SUP_MINUS[1];
      break;
      }
      default: {
      **bufPtr         = STD_SUP_0[0];
      *((*bufPtr) + 1) = STD_SUP_0[1] + ((**strPtr) - '0');
  }
    }
  *((*bufPtr) + 2) = 0;
  (*strWidth) += stringWidth(*bufPtr, &standardFont, true, true);
  (*bufPtr) += 2;
}

static uint32_t _checkExponent(const char *strPtr) {
  uint32_t digits = 0;
  while(1) {
    switch(*strPtr) {
      case '0':
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
      case '8':
        case '9': {
        ++digits;
        ++strPtr;
        break;
        }
      case '^':
        case '.': {
        return 0;
        }
      case '+':
        case '-': {
        if(digits == 0) {
          ++digits;
          ++strPtr;
          break;
        }
        else {
          return digits;
        }
        }
        default: {
        return digits;
    }
  }
}
  }

static void _addSpace(char **bufPtr, int16_t *strWidth, uint32_t *doubleBytednessHistory) { // space between an operand and an operator
  bool_t spaceShallBeAdded = true;
    if(((*bufPtr) >= (tmpString + 2)) && (compareChar((*bufPtr) - 2, STD_SPACE_PUNCTUATION) == 0)) {
      spaceShallBeAdded = false;
    }
    if(((*bufPtr) >= (tmpString + 1)) && (((*doubleBytednessHistory) & 1) == 0 && *((*bufPtr) - 1) == ' ')) {
      spaceShallBeAdded = false;
    }
  if(spaceShallBeAdded) {
    **bufPtr         = STD_SPACE_PUNCTUATION[0];
    *((*bufPtr) + 1) = STD_SPACE_PUNCTUATION[1];
    *((*bufPtr) + 2) = 0;
    *strWidth += stringWidth(*bufPtr, &standardFont, true, true);
    *bufPtr += 2;
    *doubleBytednessHistory |= 1;
    *doubleBytednessHistory <<= 1;
  }
}
#endif // !TESTSUITE_BUILD

void showEquation(uint16_t equationId, uint16_t startAt, uint16_t cursorAt, bool_t dryRun, bool_t *cursorShown, bool_t *rightEllipsis) {
  #if !defined(TESTSUITE_BUILD)
  if(equationId < numberOfFormulae || equationId == EQUATION_AIM_BUFFER) {
    char *bufPtr = tmpString;
    const char *strPtr = equationId == EQUATION_AIM_BUFFER ? aimBuffer : (char *)TO_PCMEMPTR(allFormulae[equationId].pointerToFormulaData);
    uint16_t strLength = 0;
    int16_t strWidth = 0;
    int16_t glyphWidth = 0;
    uint32_t doubleBytednessHistory = 0;
    uint32_t tmpVal = 0;
    bool_t inLabel = false;
    bool_t unaryMinus = true;
    bool_t inNumeric = true;
    bool_t beginningOfNumber = true;
    bool_t inExponent = false;
    const char *tmpPtr = strPtr;

    bool_t _cursorShown, _rightEllipsis;
      if(cursorShown == NULL) {
        cursorShown = &_cursorShown;
      }
      if(rightEllipsis == NULL) {
        rightEllipsis = &_rightEllipsis;
      }
    *cursorShown = false;
    *rightEllipsis = false;

    for(uint32_t i = 0; i < 7; ++i) {
      tmpPtr += ((*tmpPtr) & 0x80) ? 2 : 1;
      if(*tmpPtr == ':') {
        inLabel = (startAt <= (i + 1));
        tmpVal = i;
        break;
      }
      else if(*tmpPtr == '(') {
        inLabel = false;
        tmpVal = i;
        break;
      }
    }
    bufPtr = tmpString;

    if(startAt > 0) {
      *bufPtr       = STD_ELLIPSIS[0];
      *(bufPtr + 1) = STD_ELLIPSIS[1];
      *(bufPtr + 2) = 0;
      strWidth += stringWidth(bufPtr, &standardFont, true, true);
      bufPtr += 2;
    }
    if(startAt == cursorAt) {
      *bufPtr       = STD_CURSOR[0];
      *(bufPtr + 1) = STD_CURSOR[1];
      *(bufPtr + 2) = 0;
      strWidth += stringWidth(bufPtr, &standardFont, true, true);
      bufPtr += 2;
      *cursorShown = true;
    }

    while((*strPtr) != 0) {
      if((++strLength) > startAt) {
        doubleBytednessHistory <<= 1;
        *bufPtr = *strPtr;

        /* Argument separator */
        if((!inLabel) && (*strPtr) == ':') {
          _addSpace(&bufPtr, &strWidth, &doubleBytednessHistory);
          *bufPtr       = *strPtr;
          *(bufPtr + 1) = 0;
          strWidth += stringWidth(bufPtr, &standardFont, true, true);
          *(bufPtr + 1) = STD_SPACE_PUNCTUATION[0];
          *(bufPtr + 2) = STD_SPACE_PUNCTUATION[1];
          *(bufPtr + 3) = 0;
          doubleBytednessHistory <<= 1;
          doubleBytednessHistory |= 1;
          bufPtr += 1;
          unaryMinus = true;
          inNumeric = true;
          beginningOfNumber = true;
          inExponent = false;
        }

        /* End of label */
        else if((*strPtr) == ':') {
          *(bufPtr + 1) = 0;
          strWidth += stringWidth(bufPtr, &standardFont, true, true);
          *(bufPtr + 1) = ' ';
          *(bufPtr + 2) = 0;
          doubleBytednessHistory <<= 1;
          bufPtr += 1;
          inLabel = false;
        }

        /* Unary minus */
        else if((!inLabel) && unaryMinus && (*strPtr) == '-') {
            if(strLength > 1) {
              _addSpace(&bufPtr, &strWidth, &doubleBytednessHistory);
            }
          *bufPtr       = *strPtr;
          *(bufPtr + 1) = 0;
          unaryMinus = false;
          inExponent = false;
        }

        /* Opening parenthesis */
        else if((!inLabel) && (*strPtr) == '(') {
          *(bufPtr + 1) = 0;
          strWidth += stringWidth(bufPtr, &standardFont, true, true);
          *(bufPtr + 1) = STD_SPACE_PUNCTUATION[0];
          *(bufPtr + 2) = STD_SPACE_PUNCTUATION[1];
          *(bufPtr + 3) = 0;
          doubleBytednessHistory <<= 1;
          doubleBytednessHistory |= 1;
          bufPtr += 1;
          unaryMinus = true;
          inNumeric = true;
          beginningOfNumber = true;
          inExponent = false;
        }

        /* Power (if not editing) */
        else if((!inLabel) && (cursorAt == EQUATION_NO_CURSOR && (*strPtr) == '^' && (tmpVal = _checkExponent(strPtr + 1)))) {
            for(uint32_t i = 0; i < tmpVal; ++i) {
            _showExponent(&bufPtr, &strPtr, &strWidth);
            }
          *bufPtr = 0;
          bufPtr -= 2;
          strWidth -= stringWidth(bufPtr, &standardFont, true, true);
          doubleBytednessHistory |= 1;
          for(uint32_t i = 1; i < tmpVal; ++i) {
            doubleBytednessHistory <<= 1;
            doubleBytednessHistory |= 1;
          }
          unaryMinus = false;
          inExponent = false;
        }

        /* Closing parenthesis or power (when editing) */
        else if((!inLabel) && ((*strPtr) == ')' || (*strPtr) == '^')) {
          _addSpace(&bufPtr, &strWidth, &doubleBytednessHistory);
          *bufPtr       = *strPtr;
          *(bufPtr + 1) = 0;
          unaryMinus = false;
          inExponent = false;
        }

        /* Sign of exponent */
        else if((!inLabel) && inNumeric && inExponent && ((*strPtr) == '+' || (*strPtr) == '-')) {
          *(bufPtr + 1) = 0;
          unaryMinus = false;
          inNumeric = false;
          beginningOfNumber = false;
          inExponent = false;
        }

        /* Operators */
        else if((!inLabel) && ((*strPtr) == '=' || (*strPtr) == '+' || (*strPtr) == '-' || (*strPtr) == '/' || (*strPtr) == '!' || (*strPtr) == '|')) {
            if((*strPtr) != '|' || (strLength > (startAt + 1))) {
            _addSpace(&bufPtr, &strWidth, &doubleBytednessHistory);
            }
          *bufPtr       = *strPtr;
          *(bufPtr + 1) = 0;
          strWidth += stringWidth(bufPtr, &standardFont, true, true);
          *(bufPtr + 1) = STD_SPACE_PUNCTUATION[0];
          *(bufPtr + 2) = STD_SPACE_PUNCTUATION[1];
          *(bufPtr + 3) = 0;
          doubleBytednessHistory <<= 1;
          doubleBytednessHistory |= 1;
          bufPtr += 1;
          unaryMinus = false;
          inNumeric = true;
          beginningOfNumber = true;
          inExponent = false;
        }

        /* Multiply */
        else if((!inLabel) && (compareChar(strPtr, STD_CROSS) == 0 || compareChar(strPtr, STD_DOT) == 0)) {
          _addSpace(&bufPtr, &strWidth, &doubleBytednessHistory);
          *bufPtr       = PRODUCT_SIGN[0];
          *(bufPtr + 1) = PRODUCT_SIGN[1];
          *(bufPtr + 2) = 0;
          strWidth += stringWidth(bufPtr, &standardFont, true, true);
          *(bufPtr + 2) = STD_SPACE_PUNCTUATION[0];
          *(bufPtr + 3) = STD_SPACE_PUNCTUATION[1];
          *(bufPtr + 4) = 0;
          doubleBytednessHistory <<= 1;
          doubleBytednessHistory |= 3;
          bufPtr += 2;
          unaryMinus = false;
          inNumeric = true;
          beginningOfNumber = true;
          inExponent = false;
        }

        /* Numbers */
        else if((!inLabel) && (((*strPtr) >= '0' && (*strPtr) <= '9') || (*strPtr) == '.')) {
          *(bufPtr + 1) = 0;
          unaryMinus = false;
          inExponent = false;
          beginningOfNumber = false;
        }

        /* Exponent */
        else if((!inLabel) && inNumeric && (!beginningOfNumber) && (!inExponent) && (*strPtr) == 'E') {
          if(cursorAt == EQUATION_NO_CURSOR) {
            *bufPtr       = STD_DOT[0];
            *(bufPtr + 1) = STD_DOT[1];
            *(bufPtr + 2) = STD_SUB_10[0];
            *(bufPtr + 3) = STD_SUB_10[1];
            *(bufPtr + 4) = 0;
            doubleBytednessHistory <<= 1;
            doubleBytednessHistory |= 3;
            strWidth += stringWidth(bufPtr, &standardFont, true, true);
            bufPtr += 4;
            tmpVal = _checkExponent(strPtr + 1);
              for(uint32_t i = 0; i < tmpVal; ++i) {
              _showExponent(&bufPtr, &strPtr, &strWidth);
              }
            *bufPtr = 0;
            bufPtr -= 2;
            strWidth -= stringWidth(bufPtr, &standardFont, true, true);
            for(uint32_t i = 0; i < tmpVal; ++i) {
              doubleBytednessHistory <<= 1;
              doubleBytednessHistory |= 1;
            }
            unaryMinus = false;
            inExponent = false;
            beginningOfNumber = false;
          }
          else {
            *(bufPtr + 1) = 0;
            unaryMinus = false;
            inExponent = true;
            beginningOfNumber = false;
          }
        }

        /* Other double-byte characters */
        else if((*strPtr) & 0x80) {
          *(bufPtr + 1) = *(strPtr + 1);
          *(bufPtr + 2) = 0;
          doubleBytednessHistory |= 1;
          unaryMinus = false;
          inNumeric = false;
          inExponent = false;
          beginningOfNumber = false;
        }

        /* Other single-byte characters */
        else {
          *(bufPtr + 1) = 0;
          unaryMinus = false;
          inNumeric = false;
          inExponent = false;
          beginningOfNumber = false;
        }

        /* Add the character */
        glyphWidth = stringWidth(bufPtr, &standardFont, true, true);
        strWidth += glyphWidth;

        /* Cursor */
        if(strLength == cursorAt) {
          bufPtr += (doubleBytednessHistory & 0x00000001) ? 2 : 1;
          *bufPtr       = STD_CURSOR[0];
          *(bufPtr + 1) = STD_CURSOR[1];
          *(bufPtr + 2) = 0;
          glyphWidth = stringWidth(bufPtr, &standardFont, true, true);
          strWidth += glyphWidth;
          doubleBytednessHistory <<= 1;
          doubleBytednessHistory |= 1;
          *cursorShown = true;
        }

        /* Trailing ellipsis */
        if(strWidth > (SCREEN_WIDTH - 2)) {
          glyphWidth = stringWidth(STD_ELLIPSIS, &standardFont, true, true);
          while(1) {
              if(*bufPtr == STD_CURSOR[0] && *(bufPtr + 1) == STD_CURSOR[1]) {
                *cursorShown = false;
              }
            strWidth -= stringWidth(bufPtr, &standardFont, true, true);
            *bufPtr = 0;
              if((strWidth + glyphWidth) <= (SCREEN_WIDTH - 2)) {
                break;
              }
            doubleBytednessHistory >>= 1;
            bufPtr -= (doubleBytednessHistory & 0x00000001) ? 2 : 1;
          }
          *bufPtr       = STD_ELLIPSIS[0];
          *(bufPtr + 1) = STD_ELLIPSIS[1];
          *(bufPtr + 2) = 0;
          *rightEllipsis = true;
          break;
        }

        /* Increment bufPtr */
        bufPtr += (doubleBytednessHistory & 0x00000001) ? 2 : 1;
      }
      strPtr += ((*strPtr) & 0x80) ? 2 : 1;
    }

      if((!dryRun) && (*cursorShown || cursorAt == EQUATION_NO_CURSOR)) {
      showString(tmpString, &standardFont, 1, SCREEN_HEIGHT - SOFTMENU_HEIGHT * 3 + 2 , vmNormal, true, true);
  }
    }
  #endif // !TESTSUITE_BUILD
}



#if !defined(TESTSUITE_BUILD)
static void _menuItem(int16_t item, char *bufPtr) {
  xcopy(bufPtr,indexOfItems[item].itemSoftmenuName,stringByteLength(indexOfItems[item].itemSoftmenuName) + 1);
  bufPtr[stringByteLength(indexOfItems[item].itemSoftmenuName)+1]=0;
  //  xcopy(bufPtr, "Calc", 5);
  //  bufPtr[5] = 0;
}

#define PARSER_HINT_NUMERIC  0
#define PARSER_HINT_OPERATOR 1
#define PARSER_HINT_FUNCTION 2
#define PARSER_HINT_VARIABLE 3
#define PARSER_HINT_REGULAR  (stringGlyphLength(buffer) == numericCount ? PARSER_HINT_NUMERIC : PARSER_HINT_VARIABLE)

//#define PARSER_OPERATOR_STACK_SIZE   (getSystemFlag(FLAG_SSIZE8) ? 8 : 4)
#define PARSER_OPERATOR_STACK_SIZE   10 /* (200 - 16) / 18 */
#define PARSER_OPERATOR_STACK        ((uint16_t *)mvarBuffer)
#define PARSER_NUMERIC_STACK_SIZE    PARSER_OPERATOR_STACK_SIZE
#define PARSER_NUMERIC_STACK         ((real34_t *)(mvarBuffer + PARSER_OPERATOR_STACK_SIZE * 2 + sizeof(real34_t) * 2))
#define PARSER_LEFT_VALUE_REAL       ((real34_t *)(mvarBuffer + PARSER_OPERATOR_STACK_SIZE * 2))
#define PARSER_LEFT_VALUE_IMAG       ((real34_t *)(mvarBuffer + PARSER_OPERATOR_STACK_SIZE * 2 + sizeof(real34_t)))
#define PARSER_NUMERIC_STACK_POINTER ((uint8_t *)(mvarBuffer + PARSER_OPERATOR_STACK_SIZE * 2 + sizeof(real34_t) * (2 + 2 * PARSER_NUMERIC_STACK_SIZE)))

#define PARSER_OPERATOR_ITM_PARENTHESIS_LEFT   5000
#define PARSER_OPERATOR_ITM_PARENTHESIS_RIGHT  5001
#define PARSER_OPERATOR_ITM_VERTICAL_BAR_LEFT  5002
#define PARSER_OPERATOR_ITM_VERTICAL_BAR_RIGHT 5003
#define PARSER_OPERATOR_ITM_EQUAL              5004
#define PARSER_OPERATOR_ITM_YX                 5005
#define PARSER_OPERATOR_ITM_XFACT              5006
#define PARSER_OPERATOR_ITM_END_OF_FORMULA     5007

static uint32_t _operatorPriority(uint16_t func) {
  // priority of operator: smaller number represents higher priority
  // associative property: even number represents left-associativity, odd number represents right-associativity.
  switch(func) {
    case ITM_MULT:
      case ITM_DIV: {
      return 8;
      }
    case ITM_ADD:
      case ITM_SUB: {
      return 10;
      }
      case PARSER_OPERATOR_ITM_YX: {
      return 7;
      }
      case PARSER_OPERATOR_ITM_XFACT: {
      return 5;
      }
    case PARSER_OPERATOR_ITM_PARENTHESIS_LEFT:
    case PARSER_OPERATOR_ITM_PARENTHESIS_RIGHT:
    case PARSER_OPERATOR_ITM_VERTICAL_BAR_LEFT:
    case PARSER_OPERATOR_ITM_VERTICAL_BAR_RIGHT:
      case PARSER_OPERATOR_ITM_EQUAL: {
      return 1;
      }
      default: {
      return 3;
  }
}
  }

static void _pushNumericStack(char *mvarBuffer, const real34_t *re, const real34_t *im) {
  if((*PARSER_NUMERIC_STACK_POINTER) < PARSER_NUMERIC_STACK_SIZE) {
    real34Copy(re, &PARSER_NUMERIC_STACK[*PARSER_NUMERIC_STACK_POINTER * 2    ]);
    real34Copy(im, &PARSER_NUMERIC_STACK[*PARSER_NUMERIC_STACK_POINTER * 2 + 1]);
    ++(*PARSER_NUMERIC_STACK_POINTER);
  }
  else {
    displayCalcErrorMessage(ERROR_EQUATION_TOO_COMPLEX, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function parseEquation:", "numeric stack overflow!", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}

static void _popNumericStack(char *mvarBuffer, real34_t *re, real34_t *im) {
  if((*PARSER_NUMERIC_STACK_POINTER) > 0) {
    --(*PARSER_NUMERIC_STACK_POINTER);
    real34Copy(&PARSER_NUMERIC_STACK[*PARSER_NUMERIC_STACK_POINTER * 2], re);
      if(im) {
        real34Copy(&PARSER_NUMERIC_STACK[*PARSER_NUMERIC_STACK_POINTER * 2 + 1], im);
      }
  }
  else {
    displayCalcErrorMessage(ERROR_SYNTAX_ERROR_IN_EQUATION, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function parseEquation:", "numeric stack is empty!", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    realToReal34(const_NaN, re);
      if(im) {
        realToReal34(const_NaN, im);
      }
    }
  }

static void _runDyadicFunction(char *mvarBuffer, uint16_t item) {
  real34_t re, im;
  liftStack();
  clearRegister(REGISTER_X);
  liftStack();

  _popNumericStack(mvarBuffer, &re, &im);
  if(real34IsZero(&im) || real34IsNaN(&im)) {
    real34Copy(&re, REGISTER_REAL34_DATA(REGISTER_X));
  }
  else {
    reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE, amNone);
    real34Copy(&re, REGISTER_REAL34_DATA(REGISTER_X));
    real34Copy(&im, REGISTER_IMAG34_DATA(REGISTER_X));
  }

  _popNumericStack(mvarBuffer, &re, &im);
  if(real34IsZero(&im) || real34IsNaN(&im)) {
    real34Copy(&re, REGISTER_REAL34_DATA(REGISTER_Y));
  }
  else {
    reallocateRegister(REGISTER_Y, dtComplex34, COMPLEX34_SIZE, amNone);
    real34Copy(&re, REGISTER_REAL34_DATA(REGISTER_Y));
    real34Copy(&im, REGISTER_IMAG34_DATA(REGISTER_Y));
  }

  runFunction(item);

  if(getRegisterDataType(REGISTER_X) == dtComplex34) {
    _pushNumericStack(mvarBuffer, REGISTER_REAL34_DATA(REGISTER_X), REGISTER_IMAG34_DATA(REGISTER_X));
  }
  else {
    fnToReal(NOPARAM);
    _pushNumericStack(mvarBuffer, REGISTER_REAL34_DATA(REGISTER_X), const34_0);
  }
  fnDrop(NOPARAM);
}

static void _runMonadicFunction(char *mvarBuffer, uint16_t item) {
  real34_t re, im;
  liftStack();
  clearRegister(REGISTER_X);

  _popNumericStack(mvarBuffer, &re, &im);
  if(real34IsZero(&im) || real34IsNaN(&im)) {
    real34Copy(&re, REGISTER_REAL34_DATA(REGISTER_X));
  }
  else {
    reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE, amNone);
    real34Copy(&re, REGISTER_REAL34_DATA(REGISTER_X));
    real34Copy(&im, REGISTER_IMAG34_DATA(REGISTER_X));
  }

  runFunction(item);
  temporaryInformation = TI_NO_INFO;

  if(getRegisterDataType(REGISTER_X) == dtComplex34) {
    _pushNumericStack(mvarBuffer, REGISTER_REAL34_DATA(REGISTER_X), REGISTER_IMAG34_DATA(REGISTER_X));
  }
  else {
    fnToReal(NOPARAM);
    _pushNumericStack(mvarBuffer, REGISTER_REAL34_DATA(REGISTER_X), const34_0);
  }
  fnDrop(NOPARAM);
}

static void _runEqFunction(char *mvarBuffer, uint16_t item) {
  switch(item) {
    case PARSER_OPERATOR_ITM_YX: // dyadic functions
    case ITM_COMB:
    case ITM_PERM:
    case ITM_YX:
    case ITM_LOGXY:
    case ITM_ADD:
    case ITM_SUB:
    case ITM_MULT:
    case ITM_DIV:
    case ITM_IDIV:
    case ITM_MOD:
    case ITM_MAX:
    case ITM_MIN:
    case ITM_RMD:
    case ITM_HN:
    case ITM_HNP:
    case ITM_Lm:
    case ITM_Pn:
    case ITM_Tn:
    case ITM_Un:
      case ITM_atan2: {
      _runDyadicFunction(mvarBuffer, item);
      break;
      }
      default: { // monadic functions
      _runMonadicFunction(mvarBuffer, item);
  }
}
  }

static void _processOperator(uint16_t func, char *mvarBuffer) {
  uint32_t opStackTop = 0xffffffffu;
  for(uint32_t i = 0; i < PARSER_OPERATOR_STACK_SIZE; ++i) {
    if((i == PARSER_OPERATOR_STACK_SIZE) || (PARSER_OPERATOR_STACK[i] == 0)) {
      opStackTop = i;
      break;
    }
  }
  if(opStackTop != 0xffffffffu) {
    /* flush operator stack */
    /* closing parenthesis, equal, or end of formula */
    if(func == PARSER_OPERATOR_ITM_PARENTHESIS_RIGHT || func == PARSER_OPERATOR_ITM_VERTICAL_BAR_RIGHT || func == PARSER_OPERATOR_ITM_EQUAL || func == PARSER_OPERATOR_ITM_END_OF_FORMULA) {
      for(int32_t i = (int32_t)opStackTop - 1; i >= 0; --i) {
        switch(PARSER_OPERATOR_STACK[i]) {
            case PARSER_OPERATOR_ITM_PARENTHESIS_LEFT: {
            if(func == PARSER_OPERATOR_ITM_VERTICAL_BAR_RIGHT) {
              displayCalcErrorMessage(ERROR_SYNTAX_ERROR_IN_EQUATION, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
              #if(EXTRA_INFO_ON_CALC_ERROR == 1)
                moreInfoOnError("In function parseEquation:", "parentheses mismatch!", "parenthesis not closed", NULL);
              #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
            }
            break;
            }
            case PARSER_OPERATOR_ITM_VERTICAL_BAR_LEFT: {
            _runEqFunction(mvarBuffer, ITM_ABS);
            if(func == PARSER_OPERATOR_ITM_PARENTHESIS_RIGHT) {
              displayCalcErrorMessage(ERROR_SYNTAX_ERROR_IN_EQUATION, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
              #if(EXTRA_INFO_ON_CALC_ERROR == 1)
                moreInfoOnError("In function parseEquation:", "parentheses mismatch!", "unpaired vertical bar within parentheses", NULL);
              #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
            }
            break;
            }
            case PARSER_OPERATOR_ITM_YX: {
            _runEqFunction(mvarBuffer, ITM_YX);
            break;
            }
            case PARSER_OPERATOR_ITM_XFACT: {
            _runEqFunction(mvarBuffer, ITM_XFACT);
            break;
            }
            default: {
            _runEqFunction(mvarBuffer, PARSER_OPERATOR_STACK[i]);
        }
          }
        switch(PARSER_OPERATOR_STACK[i]) {
          case ITM_ADD:
          case ITM_SUB:
          case ITM_MULT:
          case ITM_DIV:
          case PARSER_OPERATOR_ITM_YX:
            case PARSER_OPERATOR_ITM_XFACT: {
            PARSER_OPERATOR_STACK[i] = 0;
            break;
            }
            default: {
            PARSER_OPERATOR_STACK[i] = 0;
              if(func == PARSER_OPERATOR_ITM_PARENTHESIS_RIGHT || func == PARSER_OPERATOR_ITM_VERTICAL_BAR_RIGHT) {
                return;
              }
            displayCalcErrorMessage(ERROR_SYNTAX_ERROR_IN_EQUATION, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
            #if(EXTRA_INFO_ON_CALC_ERROR == 1)
              moreInfoOnError("In function parseEquation:", "parentheses mismatch!", "parenthesis not closed", NULL);
            #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
            break;
        }
      }
        }
      switch(func) {
          case PARSER_OPERATOR_ITM_PARENTHESIS_RIGHT: {
          displayCalcErrorMessage(ERROR_SYNTAX_ERROR_IN_EQUATION, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
          #if(EXTRA_INFO_ON_CALC_ERROR == 1)
            moreInfoOnError("In function parseEquation:", "parentheses mismatch!", "no corresponding opening parenthesis", NULL);
          #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
          break;
          }
          case PARSER_OPERATOR_ITM_VERTICAL_BAR_RIGHT: {
          displayCalcErrorMessage(ERROR_SYNTAX_ERROR_IN_EQUATION, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
          #if(EXTRA_INFO_ON_CALC_ERROR == 1)
            moreInfoOnError("In function parseEquation:", "parentheses mismatch!", "no corresponding opening vertical bar", NULL);
          #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
          break;
          }
          case PARSER_OPERATOR_ITM_EQUAL: {
          fnToReal(NOPARAM);
          _popNumericStack(mvarBuffer, PARSER_LEFT_VALUE_REAL, PARSER_LEFT_VALUE_IMAG);
          break;
          }
          default: {
          setSystemFlag(FLAG_ASLIFT);
          liftStack();
          if((real34IsZero(PARSER_LEFT_VALUE_IMAG) || real34IsNaN(PARSER_LEFT_VALUE_IMAG)) && (real34IsZero(&PARSER_NUMERIC_STACK[(*PARSER_NUMERIC_STACK_POINTER) * 2 - 1]) || real34IsNaN(&PARSER_NUMERIC_STACK[(*PARSER_NUMERIC_STACK_POINTER) * 2 - 1]))) {
            reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE, amNone);
            real34Subtract(&PARSER_NUMERIC_STACK[(*PARSER_NUMERIC_STACK_POINTER) * 2 - 2], PARSER_LEFT_VALUE_REAL, REGISTER_REAL34_DATA(REGISTER_X));
          }
          else {
            reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE, amNone);
            real34Subtract(&PARSER_NUMERIC_STACK[(*PARSER_NUMERIC_STACK_POINTER) * 2 - 2], PARSER_LEFT_VALUE_REAL, REGISTER_REAL34_DATA(REGISTER_X));
            real34Subtract(&PARSER_NUMERIC_STACK[(*PARSER_NUMERIC_STACK_POINTER) * 2 - 1], PARSER_LEFT_VALUE_IMAG, REGISTER_IMAG34_DATA(REGISTER_X));
          }
          --(*PARSER_NUMERIC_STACK_POINTER);
      }
        }
      return;
    }

    /* stack is empty */
    if(opStackTop == 0) {
      PARSER_OPERATOR_STACK[0] = func;
      return;
    }

    /* other cases */
    for(uint32_t i = opStackTop; i > 0; --i) {

      /* factorial */
      if(func == PARSER_OPERATOR_ITM_XFACT) {
        _runEqFunction(mvarBuffer, ITM_XFACT);
        return;
      }

      /* push an operator */
        else if(( _operatorPriority(PARSER_OPERATOR_STACK[i - 1]) < 4) || /* parenthesis */
        (_operatorPriority(PARSER_OPERATOR_STACK[i - 1]) & (~1u)) > (_operatorPriority(func) & (~1u)) || /* higher priority */
        ((_operatorPriority(PARSER_OPERATOR_STACK[i - 1]) & (~1u)) == (_operatorPriority(func) & (~1u)) && (_operatorPriority(func) & 1) /* same priority and right-associative */ )
      ) {
        if(i < PARSER_OPERATOR_STACK_SIZE) {
          PARSER_OPERATOR_STACK[i] = func;
        }
        else {
          displayCalcErrorMessage(ERROR_EQUATION_TOO_COMPLEX, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
          #if(EXTRA_INFO_ON_CALC_ERROR == 1)
            moreInfoOnError("In function parseEquation:", "operator stack overflow!", NULL, NULL);
          #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        }
        return;
      }

      /* pop an operator */
      else {
        _runEqFunction(mvarBuffer, PARSER_OPERATOR_STACK[i - 1] == PARSER_OPERATOR_ITM_YX ? ITM_YX :
                                   PARSER_OPERATOR_STACK[i - 1] == PARSER_OPERATOR_ITM_VERTICAL_BAR_LEFT ? ITM_ABS :
                                   PARSER_OPERATOR_STACK[i - 1]);
        if(i == 1) {
          PARSER_OPERATOR_STACK[i - 1] = func;
          return;
        }
        else {
          PARSER_OPERATOR_STACK[i - 1] = 0;
        }
      }

    }
  }
  else {
    displayCalcErrorMessage(ERROR_EQUATION_TOO_COMPLEX, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function parseEquation:", "operator stack overflow!", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}

static void _parseWord(char *strPtr, uint16_t parseMode, uint16_t parserHint, char *mvarBuffer) {
  uint32_t tmpVal = 0;
  if(parserHint != PARSER_HINT_NUMERIC && stringGlyphLength(strPtr) > 7) {
    displayCalcErrorMessage(ERROR_SYNTAX_ERROR_IN_EQUATION, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function parseEquation:", strPtr, "token too long!", NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }
  if(strPtr[0] == 0) {
    return;
  }

  switch(parseMode) {
      case EQUATION_PARSER_MVAR: {
      if(parserHint == PARSER_HINT_VARIABLE) {
        char *bufPtr = mvarBuffer;
        if(compareString(STD_pi, strPtr, CMP_NAME) == 0) { // check for pi
          return;
        }
        if(compareString(STD_i, strPtr, CMP_NAME) == 0 || compareString(STD_j, strPtr, CMP_NAME) == 0 || compareString(STD_op_i, strPtr, CMP_NAME) == 0 || compareString(STD_op_j, strPtr, CMP_NAME) == 0) { // check for i
          return;
        }
        while(*bufPtr != 0) { // check for duplicates
          if(compareString(bufPtr, strPtr, CMP_NAME) == 0) {
            return;
          }
          bufPtr += stringByteLength(bufPtr) + 1;
          ++tmpVal;
        }
        for(uint32_t i = CST_01; i <= CST_79; ++i) { // check for constants
          if(compareString(indexOfItems[i].itemCatalogName, strPtr, CMP_NAME) == 0) {
            return;
          }
        }
        if(validateName(strPtr)) {
          calcRegister_t var = findOrAllocateNamedVariable(strPtr);
          xcopy(bufPtr, strPtr, stringByteLength(strPtr) + 1);
          bufPtr += stringByteLength(strPtr) + 1;
          bufPtr[0] = 0;
          if((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_SOLVER && var >= FIRST_RESERVED_VARIABLE) {
            displayCalcErrorMessage(ERROR_INVALID_NAME, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
            #if(EXTRA_INFO_ON_CALC_ERROR == 1)
              moreInfoOnError("In function parseEquation:", strPtr, "names a register or a reserved variable!", NULL);
            #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
          }
          else {
            if(tmpVal == 2 && ((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_SOLVER)) {   // If the 4th variable has just been added, add Draw and Calc.
              _menuItem(ITM_CPXSLV, bufPtr);
              bufPtr += stringByteLength(bufPtr) + 1;
              _menuItem(ITM_DRAW, bufPtr);
              bufPtr += stringByteLength(bufPtr) + 1;
              _menuItem(ITM_CALC, bufPtr);
            }
              else if(tmpVal == 3 && ((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_1ST_DERIVATIVE)) {
                _menuItem(ITM_DRAW, bufPtr);
                bufPtr += stringByteLength(bufPtr) + 1;
              _menuItem(ITM_FPHERE, bufPtr);
            }
              else if(tmpVal == 3 && ((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_2ND_DERIVATIVE)) {
                _menuItem(ITM_DRAW, bufPtr);
                bufPtr += stringByteLength(bufPtr) + 1;
              _menuItem(ITM_FPPHERE, bufPtr);
            }
          }
        }
        else {
          displayCalcErrorMessage(ERROR_SYNTAX_ERROR_IN_EQUATION, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
          #if(EXTRA_INFO_ON_CALC_ERROR == 1)
            moreInfoOnError("In function parseEquation 1:", strPtr, "is not a valid name!", NULL);
          #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        }
      }
      break;
      }

      case EQUATION_PARSER_XEQ: {
      if(parserHint == PARSER_HINT_VARIABLE) {
        if(compareString(STD_pi, strPtr, CMP_NAME) == 0) { // check for pi
          runFunction(ITM_CONSTpi);
          _pushNumericStack(mvarBuffer, REGISTER_REAL34_DATA(REGISTER_X), const34_0);
          fnDrop(NOPARAM);
          return;
        }
        if(compareString(STD_i, strPtr, CMP_NAME) == 0 || compareString(STD_j, strPtr, CMP_NAME) == 0 || compareString(STD_op_i, strPtr, CMP_NAME) == 0 || compareString(STD_op_j, strPtr, CMP_NAME) == 0) { // check for i
          runFunction(ITM_op_j);
          _pushNumericStack(mvarBuffer, const34_0, const34_1);
          fnDrop(NOPARAM);
          return;
        }
        for(uint32_t i = CST_01; i <= CST_79; ++i) { // check for constants
          if(compareString(indexOfItems[i].itemCatalogName, strPtr, CMP_NAME) == 0) {
            runFunction(i);
            _pushNumericStack(mvarBuffer, REGISTER_REAL34_DATA(REGISTER_X), const34_0);
            fnDrop(NOPARAM);
            return;
          }
        }
        if(validateName(strPtr)) {
          reallyRunFunction(ITM_RCL, findNamedVariable(strPtr));
          if(getRegisterDataType(REGISTER_X) == dtComplex34) {
            _pushNumericStack(mvarBuffer, REGISTER_REAL34_DATA(REGISTER_X), REGISTER_IMAG34_DATA(REGISTER_X));
          }
          else {
            fnToReal(NOPARAM);
            _pushNumericStack(mvarBuffer, REGISTER_REAL34_DATA(REGISTER_X), const34_0);
          }
          fnDrop(NOPARAM);
        }
        else {
          displayCalcErrorMessage(ERROR_SYNTAX_ERROR_IN_EQUATION, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
          #if(EXTRA_INFO_ON_CALC_ERROR == 1)
            moreInfoOnError("In function parseEquation 2:", strPtr, "is not a valid name!", NULL);
          #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        }
      }
      else if(parserHint == PARSER_HINT_NUMERIC) {
        real34_t val;
        stringToReal34(strPtr, &val);
        _pushNumericStack(mvarBuffer, &val, const34_0);
      }
      else if(parserHint == PARSER_HINT_OPERATOR) {
        if(compareString("+", strPtr, CMP_BINARY) == 0) {
          _processOperator(ITM_ADD, mvarBuffer);
        }
        else if(compareString("-", strPtr, CMP_BINARY) == 0) {
          _processOperator(ITM_SUB, mvarBuffer);
        }
        else if(compareString(STD_CROSS, strPtr, CMP_BINARY) == 0 || compareString(STD_DOT, strPtr, CMP_BINARY) == 0) {
          _processOperator(ITM_MULT, mvarBuffer);
        }
        else if(compareString("/", strPtr, CMP_BINARY) == 0) {
          _processOperator(ITM_DIV, mvarBuffer);
        }
        else if(compareString("^", strPtr, CMP_BINARY) == 0) {
          _processOperator(PARSER_OPERATOR_ITM_YX, mvarBuffer);
        }
        else if(compareString("!", strPtr, CMP_BINARY) == 0) {
          _processOperator(PARSER_OPERATOR_ITM_XFACT, mvarBuffer);
        }
        else if(compareString("(", strPtr, CMP_BINARY) == 0) {
          _processOperator(PARSER_OPERATOR_ITM_PARENTHESIS_LEFT, mvarBuffer);
        }
        else if(compareString(")", strPtr, CMP_BINARY) == 0) {
          _processOperator(PARSER_OPERATOR_ITM_PARENTHESIS_RIGHT, mvarBuffer);
        }
        else if(compareString("|", strPtr, CMP_BINARY) == 0) {
          _processOperator(PARSER_OPERATOR_ITM_VERTICAL_BAR_LEFT, mvarBuffer);
        }
        else if(compareString("|)", strPtr, CMP_BINARY) == 0) {
          _processOperator(PARSER_OPERATOR_ITM_VERTICAL_BAR_RIGHT, mvarBuffer);
        }
        else if(compareString("=", strPtr, CMP_BINARY) == 0) {
          _processOperator(PARSER_OPERATOR_ITM_EQUAL, mvarBuffer);
        }
        else if(compareString(":", strPtr, CMP_BINARY) == 0) {
          // label or parameter separator will be skipped
        }
        else {
          displayBugScreen(bugScreenUnknownOperator);
        }
      }
      else if(parserHint == PARSER_HINT_FUNCTION) {
        for(uint32_t i = 0; functionAlias[i].name[0] != 0; ++i) {
          if(compareString(functionAlias[i].name, strPtr, CMP_NAME) == 0) {
            _processOperator(functionAlias[i].opCode, mvarBuffer);
            return;
          }
        }
        for(uint32_t i = 1; i < LAST_ITEM; ++i) {
          if(((indexOfItems[i].status & EIM_STATUS) == EIM_ENABLED) && (indexOfItems[i].param <= NOPARAM) && (compareString(indexOfItems[i].itemCatalogName, strPtr, CMP_NAME) == 0)) {
            _processOperator(i, mvarBuffer);
            return;
          }
        }
        for(uint32_t i = 1; i < LAST_ITEM; ++i) {
          if(((indexOfItems[i].status & EIM_STATUS) == EIM_ENABLED) && (indexOfItems[i].param <= NOPARAM) && (compareString(indexOfItems[i].itemSoftmenuName, strPtr, CMP_NAME) == 0)) {
            _processOperator(i, mvarBuffer);
            return;
          }
        }
        displayCalcErrorMessage(ERROR_FUNCTION_NOT_FOUND, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        #if(EXTRA_INFO_ON_CALC_ERROR == 1)
          moreInfoOnError("In function parseEquation:", strPtr, "is not recognized as a function", "or not for equations");
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      }
      break;
      }

      default: {
      displayBugScreen(bugScreenUnknownFormulaParserMode);
  }
}
  }
#endif // !TESTSUITE_BUILD

void parseEquation(uint16_t equationId, uint16_t parseMode, char *buffer, char *mvarBuffer) {
  #if !defined(TESTSUITE_BUILD)
  const char *strPtr = (char *)TO_PCMEMPTR(allFormulae[equationId].pointerToFormulaData);
  char *bufPtr = buffer;
  int16_t numericCount = 0;
  bool_t equalAppeared = false, labeled = false, afterClosingParenthesis = false, unaryMinusCanOccur = true, afterSpace = false;
  bool_t inExponent = false, exponentSignCanOccur = false;

  for(uint32_t i = 0; i < PARSER_OPERATOR_STACK_SIZE; ++i) {
    PARSER_OPERATOR_STACK[i] = 0;
  }
  real34Zero(PARSER_LEFT_VALUE_REAL);
  real34Zero(PARSER_LEFT_VALUE_IMAG);
  for(uint32_t i = 0; i < PARSER_NUMERIC_STACK_SIZE; ++i) {
    realToReal34(const_NaN, &PARSER_NUMERIC_STACK[i * 2    ]);
    realToReal34(const_NaN, &PARSER_NUMERIC_STACK[i * 2 + 1]);
  }
  *PARSER_NUMERIC_STACK_POINTER = 0;
  if(parseMode == EQUATION_PARSER_XEQ) {
    fnClearStack(NOPARAM);
  }

  for(uint32_t i = 0; i < 7; ++i) {
    strPtr += ((*strPtr) & 0x80) ? 2 : 1;
    if(*strPtr == ':') {
      labeled = true;
      ++strPtr;
      break;
    }
    else if(*strPtr == '(') {
      labeled = false;
      break;
    }
  }
  if(!labeled) {
    strPtr = (char *)TO_PCMEMPTR(allFormulae[equationId].pointerToFormulaData);
  }

  while(*strPtr != 0) {
    while(*strPtr == ' ') {
      afterSpace = true;
      ++strPtr;
    }

      #pragma GCC diagnostic push
      #pragma GCC diagnostic ignored "-Wimplicit-fallthrough"
    switch(*strPtr) {
      case ';':
        case ',': {
        displayCalcErrorMessage(ERROR_SYNTAX_ERROR_IN_EQUATION, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        #if(EXTRA_INFO_ON_CALC_ERROR == 1)
          sprintf(errorMessage, "%c", *strPtr);
          moreInfoOnError("In function parseEquation:", errorMessage, "cannot be appeared in equations", NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        return;
        }

        case '(':
        if(bufPtr != buffer) {
          *(bufPtr++) = 0;
          ++strPtr;
          if(stringGlyphLength(buffer) == numericCount) {
            displayCalcErrorMessage(ERROR_SYNTAX_ERROR_IN_EQUATION, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
            #if(EXTRA_INFO_ON_CALC_ERROR == 1)
              moreInfoOnError("In function parseEquation:", "attempt to call a number as a function!", NULL, NULL);
            #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
            return;
          }
          else {
            _parseWord(buffer, parseMode, PARSER_HINT_FUNCTION, mvarBuffer);
            bufPtr = buffer;
            buffer[0] = 0;
            numericCount = 0;
            afterClosingParenthesis = false;
            unaryMinusCanOccur = true;
            afterSpace = false;
            inExponent = false;
            exponentSignCanOccur = false;
            break;
          }
        }
        /* fallthrough */


      case '=':
      case '+':
      case '-':
      case '/':
      case ')':
      case '^':
      case '!':
      case ':':
        case '|':
        if(equalAppeared && (*strPtr == '=')) {
          displayCalcErrorMessage(ERROR_SYNTAX_ERROR_IN_EQUATION, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
          #if(EXTRA_INFO_ON_CALC_ERROR == 1)
            moreInfoOnError("In function parseEquation:", "= appears more than once", NULL, NULL);
          #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
          return;
        }
        else if((bufPtr != buffer) && (*strPtr == '|')) {
          *(bufPtr++) = 0;
          _parseWord(buffer, parseMode, PARSER_HINT_REGULAR, mvarBuffer);
          bufPtr = buffer;
          numericCount = 0;
          *(bufPtr++) = '|';
          *(bufPtr++) = ')';
          *(bufPtr++) = 0;
          afterClosingParenthesis = true;
          unaryMinusCanOccur = false;
          afterSpace = false;
          inExponent = false;
          exponentSignCanOccur = false;
        }
        else if(exponentSignCanOccur && (*strPtr == '+' || *strPtr == '-')) {
          /* exponent sign */
          *(bufPtr++) = *(strPtr++);
          ++numericCount;
          afterClosingParenthesis = false;
          unaryMinusCanOccur = false;
          afterSpace = false;
          inExponent = true;
          exponentSignCanOccur = false;
          break;
        }
        else if(bufPtr != buffer) {
          *(bufPtr++) = 0;
          _parseWord(buffer, parseMode, PARSER_HINT_REGULAR, mvarBuffer);
          afterClosingParenthesis = (*strPtr == ')');
          unaryMinusCanOccur = false;
          afterSpace = false;
          inExponent = false;
          exponentSignCanOccur = false;
        }
        else if(unaryMinusCanOccur && *strPtr == '-') {
          /* unary minus */
          buffer[0] = '-';
          buffer[1] = '1';
          buffer[2] = 0;
          _parseWord(buffer, parseMode, PARSER_HINT_NUMERIC, mvarBuffer);
          buffer[0] = STD_DOT[0];
          buffer[1] = STD_DOT[1];
          buffer[2] = 0;
          _parseWord(buffer, parseMode, PARSER_HINT_OPERATOR, mvarBuffer);
          bufPtr = buffer;
          buffer[0] = 0;
          numericCount = 0;
          afterClosingParenthesis = false;
          unaryMinusCanOccur = false;
          ++strPtr;
          afterSpace = false;
          inExponent = false;
          exponentSignCanOccur = false;
          break;
        }
        else if((*strPtr == '(') || (*strPtr == '|' && !afterClosingParenthesis)) {
          afterClosingParenthesis = false;
          unaryMinusCanOccur = true;
          afterSpace = false;
          inExponent = false;
          exponentSignCanOccur = false;
        }
        else if(*strPtr == ')' || *strPtr == '|') {
          if(*strPtr == '|') {
            bufPtr = buffer;
            numericCount = 0;
            *(bufPtr++) = '|';
            *(bufPtr++) = ')';
            *(bufPtr++) = 0;
          }
          afterClosingParenthesis = true;
          unaryMinusCanOccur = false;
          afterSpace = false;
          inExponent = false;
          exponentSignCanOccur = false;
        }
        else if(afterClosingParenthesis && *strPtr != ':') {
          afterClosingParenthesis = false;
          unaryMinusCanOccur = false;
          afterSpace = false;
          inExponent = false;
          exponentSignCanOccur = false;
        }
        else {
          displayCalcErrorMessage(ERROR_SYNTAX_ERROR_IN_EQUATION, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
          #if(EXTRA_INFO_ON_CALC_ERROR == 1)
            moreInfoOnError("In function parseEquation:", buffer, "unexpected operator", NULL);
          #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
          return;
        }
        if(*strPtr == '=') {
          equalAppeared = true;
          unaryMinusCanOccur = true;
          afterSpace = false;
          inExponent = false;
          exponentSignCanOccur = false;
        }

        if(compareString("|)", buffer, CMP_BINARY) != 0) {
          buffer[0] = *(strPtr++);
          buffer[1] = 0;
        }
        else {
          ++strPtr;
        }
        _parseWord(buffer, parseMode, PARSER_HINT_OPERATOR, mvarBuffer);
        bufPtr = buffer;
        buffer[0] = 0;
        numericCount = 0;
        inExponent = false;
        exponentSignCanOccur = false;
        break;


        default: {
        if(afterSpace) {
          *(bufPtr++) = 0;
          _parseWord(buffer, parseMode, PARSER_HINT_REGULAR, mvarBuffer);
          bufPtr = buffer;
          numericCount = 0;
          afterSpace = false;
        }
        if((*strPtr >= '0' && *strPtr <= '9') || *strPtr == '.') {
          ++numericCount;
          exponentSignCanOccur = false;
        }
        else if((!inExponent) && *strPtr == 'E' && ((*bufPtr = 0), numericCount == stringGlyphLength(buffer))) {
          ++numericCount;
          inExponent = true;
          exponentSignCanOccur = true;
        }
        else {
          inExponent = false;
          exponentSignCanOccur = false;
        }
        if(compareChar(strPtr, STD_CROSS) == 0 || compareChar(strPtr, STD_DOT) == 0) {
          *(bufPtr++) = 0;
          _parseWord(buffer, parseMode, PARSER_HINT_REGULAR, mvarBuffer);
          buffer[0] = *(strPtr++);
          buffer[1] = *(strPtr++);
          buffer[2] = 0;
          _parseWord(buffer, parseMode, PARSER_HINT_OPERATOR, mvarBuffer);
          bufPtr = buffer;
          buffer[0] = 0;
          numericCount = 0;
        }
        else {
          *(bufPtr++) = *strPtr;
          if((*(strPtr++)) & 0x80) {
            *(bufPtr++) = *(strPtr++);
          }
        }
        afterClosingParenthesis = false;
        unaryMinusCanOccur = false;
        afterSpace = false;
    }
      }
      #pragma GCC diagnostic pop
      if(lastErrorCode != ERROR_NONE) {
        return;
      }
  }
  if(bufPtr != buffer) {
    *(bufPtr++) = 0;
    _parseWord(buffer, parseMode, PARSER_HINT_REGULAR, mvarBuffer);
  }

  if(parseMode == EQUATION_PARSER_MVAR) {
    uint32_t tmpVal = 0;
    bufPtr = mvarBuffer;
    while(*bufPtr != 0) {
      bufPtr += stringByteLength(bufPtr) + 1;
      ++tmpVal;
    }
    if((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_SOLVER) {
      for(; tmpVal < 3; ++tmpVal) {  //If there are less than 4 variables, skip to the 5th item and add Draw & Calc.
        *(bufPtr++) = 0;
      }
      if(tmpVal == 3) {
        _menuItem(ITM_CPXSLV, bufPtr);
        bufPtr += stringByteLength(bufPtr) + 1;
        _menuItem(ITM_DRAW, bufPtr);
        bufPtr += stringByteLength(bufPtr) + 1;
        _menuItem(ITM_CALC, bufPtr);
      }
    }
    if((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_1ST_DERIVATIVE || (currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_2ND_DERIVATIVE) {
        for(; tmpVal < 4; ++tmpVal) {  //If there are less than 4 variables, skip to the 5th item and add Draw & Calc.
        *(bufPtr++) = 0;
      }
        if(tmpVal == 4) {
        if((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_1ST_DERIVATIVE) {
            _menuItem(ITM_DRAW, bufPtr);
            bufPtr += stringByteLength(bufPtr) + 1;
          _menuItem(ITM_FPHERE, bufPtr);
        }
        else {
            _menuItem(ITM_DRAW, bufPtr);
            bufPtr += stringByteLength(bufPtr) + 1;
          _menuItem(ITM_FPPHERE, bufPtr);
        }
      }
    }
  }
  if(parseMode == EQUATION_PARSER_XEQ) {
    _processOperator(PARSER_OPERATOR_ITM_END_OF_FORMULA, mvarBuffer);
  }
  #endif // !TESTSUITE_BUILD
}
