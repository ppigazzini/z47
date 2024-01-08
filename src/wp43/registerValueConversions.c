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

#include "registerValueConversions.h"

#include "charString.h"
#include "constantPointers.h"
#include "dateTime.h"
#include "debug.h"
#include "display.h"
#include "error.h"
#include "integers.h"
#include "mathematics/matrix.h"
#include "mathematics/rsd.h"
#include "memory.h"
#include "registers.h"
#include <string.h>

#include "wp43.h"



void convertLongIntegerToLongIntegerRegister(const longInteger_t lgInt, calcRegister_t regist) {
  uint16_t sizeInBytes = longIntegerSizeInBytes(lgInt);

  reallocateRegister(regist, dtLongInteger, TO_BLOCKS(sizeInBytes), longIntegerSignTag(lgInt));
  xcopy(REGISTER_LONG_INTEGER_DATA(regist), lgInt->_mp_d, sizeInBytes);
}



void convertLongIntegerRegisterToLongInteger(calcRegister_t regist, longInteger_t lgInt) {
  uint32_t sizeInBytes = TO_BYTES(getRegisterMaxDataLengthInBlocks(regist));

  longIntegerInitSizeInBits(lgInt, 8 * max(sizeInBytes, LIMB_SIZE));

  xcopy(lgInt->_mp_d, REGISTER_LONG_INTEGER_DATA(regist), sizeInBytes);

  if(getRegisterLongIntegerSign(regist) == LI_NEGATIVE) {
    lgInt->_mp_size = -(sizeInBytes / LIMB_SIZE);
  }
  else {
    lgInt->_mp_size = sizeInBytes / LIMB_SIZE;
  }
}



void convertLongIntegerRegisterToReal34Register(calcRegister_t source, calcRegister_t destination) {
  longInteger_t lgInt;

  convertLongIntegerRegisterToLongInteger(source, lgInt);
  longIntegerToAllocatedString(lgInt, tmpString, TMP_STR_LENGTH);
  longIntegerFree(lgInt);
  reallocateRegister(destination, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
  stringToReal34(tmpString, REGISTER_REAL34_DATA(destination));
}


void convertLongIntegerRegisterToReal34(calcRegister_t source, real34_t *destination) {
  longInteger_t lgInt;

  convertLongIntegerRegisterToLongInteger(source, lgInt);
  longIntegerToAllocatedString(lgInt, tmpString, TMP_STR_LENGTH);
  longIntegerFree(lgInt);
  stringToReal34(tmpString, destination);
}


void convertLongIntegerRegisterToReal(calcRegister_t source, real_t *destination, realContext_t *ctxt) {
  longInteger_t lgInt;

  convertLongIntegerRegisterToLongInteger(source, lgInt);
  convertLongIntegerToReal(lgInt, destination, ctxt);
  longIntegerFree(lgInt);
}



void convertLongIntegerToReal(longInteger_t source, real_t *destination, realContext_t *ctxt) {
  longIntegerToAllocatedString(source, tmpString, TMP_STR_LENGTH);
  stringToReal(tmpString, destination, ctxt);
}



void convertLongIntegerToShortIntegerRegister(longInteger_t lgInt, uint32_t base, calcRegister_t destination) {
  reallocateRegister(destination, dtShortInteger, SHORT_INTEGER_SIZE, base);
  if(longIntegerIsZero(lgInt)) {
    *(REGISTER_SHORT_INTEGER_DATA(destination)) = 0;
  }
  else {
    #if defined(OS32BIT) // 32 bit
      uint64_t u64 = *(uint32_t *)(lgInt->_mp_d);
      if(abs(lgInt->_mp_size) > 1) {
        u64 |= (int64_t)(*(((uint32_t *)(lgInt->_mp_d)) + 1)) << 32;
      }
      *(REGISTER_SHORT_INTEGER_DATA(destination)) = u64 & shortIntegerMask;
    #else // 64 bit
      *(REGISTER_SHORT_INTEGER_DATA(destination)) = *(uint64_t *)(lgInt->_mp_d) & shortIntegerMask;
    #endif // OS32BIT
    if(longIntegerIsNegative(lgInt)) {
      *(REGISTER_SHORT_INTEGER_DATA(destination)) = WP34S_intChs(*(REGISTER_SHORT_INTEGER_DATA(destination)));
    }
  }
}



void convertLongIntegerRegisterToShortIntegerRegister(calcRegister_t source, calcRegister_t destination) {
  longInteger_t lgInt;

  convertLongIntegerRegisterToLongInteger(source, lgInt);
  convertLongIntegerToShortIntegerRegister(lgInt, 10, destination);
  longIntegerFree(lgInt);
}



void convertShortIntegerRegisterToReal34Register(calcRegister_t source, calcRegister_t destination) {
  uint64_t value;
  int16_t sign;
  real34_t lowWord;

  convertShortIntegerRegisterToUInt64(source, &sign, &value);
  reallocateRegister(destination, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);

  uInt32ToReal34(value >> 32, REGISTER_REAL34_DATA(destination));
  uInt32ToReal34(value & 0x00000000ffffffff, &lowWord);
  real34FMA(REGISTER_REAL34_DATA(destination), const34_2p32, &lowWord, REGISTER_REAL34_DATA(destination));

  if(sign) {
    real34SetNegativeSign(REGISTER_REAL34_DATA(destination));
  }
}



void convertShortIntegerRegisterToReal(calcRegister_t source, real_t *destination, realContext_t *ctxt) {
  uint64_t value;
  int16_t sign;
  real_t lowWord;

  convertShortIntegerRegisterToUInt64(source, &sign, &value);

  uInt32ToReal(value >> 32, destination);
  uInt32ToReal(value & 0x00000000ffffffff, &lowWord);
  realFMA(destination, const_2p32, &lowWord, destination, ctxt);

  if(sign) {
    realSetNegativeSign(destination);
  }
}



void convertShortIntegerRegisterToUInt64(calcRegister_t regist, int16_t *sign, uint64_t *value) {
  *value = *(REGISTER_SHORT_INTEGER_DATA(regist)) & shortIntegerMask;

  if(shortIntegerMode == SIM_UNSIGN) {
    *sign = 0;
  }
  else {
    if(*value & shortIntegerSignBit) { // Negative value
      *sign = 1;

      if(shortIntegerMode == SIM_2COMPL) {
        *value = ((~*value) + 1) & shortIntegerMask;
      }
      else if(shortIntegerMode == SIM_1COMPL) {
        *value = (~*value) & shortIntegerMask;
      }
      else if(shortIntegerMode == SIM_SIGNMT) {
       *value -= shortIntegerSignBit;
      }
      else {
        sprintf(errorMessage, commonBugScreenMessages[bugMsgValueFor], "convertShortIntegerRegisterToUInt64", shortIntegerMode, "shortIntegerMode");
        displayBugScreen(errorMessage);
        *sign = 0;
        *value = 0;
      }
    }
    else { // Positive value
      *sign = 0;
    }
  }
}



void convertShortIntegerRegisterToLongInteger(calcRegister_t source, longInteger_t lgInt) {
  uint64_t value;
  int16_t sign;

  convertShortIntegerRegisterToUInt64(source, &sign, &value);

  longIntegerInit(lgInt);
  uIntToLongInteger(value >> 32, lgInt);
  longIntegerLeftShift(lgInt, 32, lgInt);
  longIntegerAddUInt(lgInt, value & 0x00000000ffffffff, lgInt);

  if(sign) {
    longIntegerChangeSign(lgInt);
  }
}



void convertShortIntegerRegisterToLongIntegerRegister(calcRegister_t source, calcRegister_t destination) {
  longInteger_t lgInt;

  convertShortIntegerRegisterToLongInteger(source, lgInt);

  convertLongIntegerToLongIntegerRegister(lgInt, destination);
  longIntegerFree(lgInt);
}



void convertUInt64ToShortIntegerRegister(int16_t sign, uint64_t value, uint32_t base, calcRegister_t regist) {
  if(sign) { // Negative value
    if(shortIntegerMode == SIM_2COMPL) {
      value = (~value) + 1;
    }
    else if(shortIntegerMode == SIM_1COMPL) {
      value = ~value;
    }
    else if(shortIntegerMode == SIM_SIGNMT) {
      value += shortIntegerSignBit;
    }
    else {
      sprintf(errorMessage, commonBugScreenMessages[bugMsgValueFor], "convertUInt64ToShortIntegerRegister", shortIntegerMode, "shortIntegerMode");
      displayBugScreen(errorMessage);
      value = 0;
    }
  }

  reallocateRegister(regist, dtShortInteger, SHORT_INTEGER_SIZE, base);
  *(REGISTER_SHORT_INTEGER_DATA(regist)) = value & shortIntegerMask;
}



void convertReal34ToLongInteger(const real34_t *re34, longInteger_t lgInt, enum rounding roundingMode) {
  uint8_t bcd[DECQUAD_Pmax];
  int32_t sign, exponent;
  real34_t real34;

  real34ToIntegralValue(re34, &real34, roundingMode);
  sign = real34GetCoefficient(&real34, bcd);
  exponent = real34GetExponent(&real34);

  longIntegerInit(lgInt);
  uIntToLongInteger(bcd[0], lgInt);

  for(int i=1; i<DECQUAD_Pmax; i++) {
    longIntegerMultiplyUInt(lgInt, 10, lgInt);
    longIntegerAddUInt(lgInt, bcd[i], lgInt);
  }

  while(exponent > 0) {
    longIntegerMultiplyUInt(lgInt, 10, lgInt);
    exponent--;
  }

  if(sign) {
    longIntegerChangeSign(lgInt);
  }
}



void convertReal34ToLongIntegerRegister(const real34_t *real34, calcRegister_t dest, enum rounding roundingMode) {
  longInteger_t lgInt;

  convertReal34ToLongInteger(real34, lgInt, roundingMode);
  convertLongIntegerToLongIntegerRegister(lgInt, dest);

  longIntegerFree(lgInt);
}



void convertRealToLongInteger(const real_t *re, longInteger_t lgInt, enum rounding roundingMode) {
  uint8_t bcd[75];
  int32_t sign, exponent;
  real_t real;

  realToIntegralValue(re, &real, roundingMode, &ctxtReal39);
  realGetCoefficient(&real, bcd);
  sign = (realIsNegative(&real) ? 1 : 0);
  exponent = real.exponent;

  uIntToLongInteger(bcd[0], lgInt);

  for(int i=1; i<real.digits; i++) {
    longIntegerMultiplyUInt(lgInt, 10, lgInt);
    longIntegerAddUInt(lgInt, bcd[i], lgInt);
  }

  while(exponent > 0) {
    longIntegerMultiplyUInt(lgInt, 10, lgInt);
    exponent--;
  }

  if(sign) {
    longIntegerChangeSign(lgInt);
  }
}



void convertRealToLongIntegerRegister(const real_t *real, calcRegister_t dest, enum rounding roundingMode) {
  longInteger_t lgInt;

  longIntegerInit(lgInt);

  convertRealToLongInteger(real, lgInt, roundingMode);
  convertLongIntegerToLongIntegerRegister(lgInt, dest);
  longIntegerFree(lgInt);
}



void realToIntegralValue(const real_t *source, real_t *destination, enum rounding mode, realContext_t *realContext) {
  enum rounding savedRoundingMode;

  savedRoundingMode = realContext->round;
  realContext->round = mode;
  realContext->status = 0;
  decNumberToIntegralValue(destination, source, realContext);
  realContext->round = savedRoundingMode;
}



void convertRealToReal34ResultRegister(const real_t *real, calcRegister_t dest) {
  real_t rounded;
  roundToSignificantDigits(real, &rounded, significantDigits == 0 ? 34 : significantDigits, &ctxtReal75);
  realToReal34(&rounded, REGISTER_REAL34_DATA(dest));
}

void convertRealToImag34ResultRegister(const real_t *real, calcRegister_t dest) {
  real_t rounded;
  roundToSignificantDigits(real, &rounded, significantDigits == 0 ? 34 : significantDigits, &ctxtReal75);
  realToReal34(&rounded, REGISTER_IMAG34_DATA(dest));
}

void convertComplexToResultRegister(const real_t *real, const real_t *imag, calcRegister_t dest) {
  convertRealToReal34ResultRegister(real, dest);
  convertRealToImag34ResultRegister(imag, dest);
}


void convertTimeRegisterToReal34Register(calcRegister_t source, calcRegister_t destination) {
  real34_t real34, value34;
  real34Copy(REGISTER_REAL34_DATA(source), &real34);
  int32ToReal34(3600, &value34);
  reallocateRegister(destination, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
  real34Divide(&real34, &value34, REGISTER_REAL34_DATA(destination));
}



void convertReal34RegisterToTimeRegister(calcRegister_t source, calcRegister_t destination) {
  real34_t real34, value34;
  real34Copy(REGISTER_REAL34_DATA(source), &real34);
  int32ToReal34(3600, &value34);
  reallocateRegister(destination, dtTime, REAL34_SIZE_IN_BLOCKS, amNone);
  real34Multiply(&real34, &value34, REGISTER_REAL34_DATA(destination));
}



void convertLongIntegerRegisterToTimeRegister(calcRegister_t source, calcRegister_t destination) {
  convertLongIntegerRegisterToReal34Register(source, destination);
  convertReal34RegisterToTimeRegister(destination, destination);
}



void convertDateRegisterToReal34Register(calcRegister_t source, calcRegister_t destination) {
  real34_t y, m, d, j, val;
  bool_t isNegative;

  internalDateToJulianDay(REGISTER_REAL34_DATA(source), &j);
  decomposeJulianDay(&j, &y, &m, &d);
  isNegative = real34IsNegative(&y);
  real34SetPositiveSign(&y);

  if(getSystemFlag(FLAG_YMD)) {
    int32ToReal34(100, &val), real34Divide(&m, &val, &m);
    int32ToReal34(10000, &val), real34Divide(&d, &val, &d);
  }
  else if(getSystemFlag(FLAG_MDY)) {
    int32ToReal34(100, &val), real34Divide(&d, &val, &d);
    int32ToReal34(1000000, &val), real34Divide(&y, &val, &y);
  }
  else if(getSystemFlag(FLAG_DMY)) {
    int32ToReal34(100, &val), real34Divide(&m, &val, &m);
    int32ToReal34(1000000, &val), real34Divide(&y, &val, &y);
  }

  reallocateRegister(destination, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
  real34Add(&y, &m, REGISTER_REAL34_DATA(destination));
  real34Add(REGISTER_REAL34_DATA(destination), &d, REGISTER_REAL34_DATA(destination));
  if(isNegative) {
    real34SetNegativeSign(REGISTER_REAL34_DATA(destination));
  }
}



void convertReal34RegisterToDateRegister(calcRegister_t source, calcRegister_t destination) {
  real34_t part1, part2, part3, val;
  bool_t isNegative;

  isNegative = real34IsNegative(REGISTER_REAL34_DATA(source));
  real34CopyAbs(REGISTER_REAL34_DATA(source), &part2);
  real34ToIntegralValue(&part2, &part1, DEC_ROUND_DOWN);
  real34Subtract(&part2, &part1, &part2);
  int32ToReal34(100, &val), real34Multiply(&part2, &val, &part2);

  real34Copy(&part2, &part3);
  real34ToIntegralValue(&part2, &part2, DEC_ROUND_DOWN);
  real34Subtract(&part3, &part2, &part3);
  int32ToReal34(getSystemFlag(FLAG_YMD) ? 100 : 10000, &val), real34Multiply(&part3, &val, &part3);
  real34ToIntegralValue(&part3, &part3, DEC_ROUND_DOWN);

  if(isNegative) {
    if(getSystemFlag(FLAG_YMD)) {
      real34SetNegativeSign(&part1);
    }
    else {
      real34SetNegativeSign(&part3);
    }
  }

  if((getSystemFlag(FLAG_YMD) && !isValidDay(&part1, &part2, &part3)) ||
    ( getSystemFlag(FLAG_MDY) && !isValidDay(&part3, &part1, &part2)) ||
    ( getSystemFlag(FLAG_DMY) && !isValidDay(&part3, &part2, &part1))) {
      displayCalcErrorMessage(ERROR_BAD_TIME_OR_DATE_INPUT, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function convertReal34RegisterToDateRegister:", "Invalid date input like 30 Feb.", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
  }

  reallocateRegister(destination, dtDate, REAL34_SIZE_IN_BLOCKS, amNone);
  if(getSystemFlag(FLAG_YMD)) {
    composeJulianDay(&part1, &part2, &part3, REGISTER_REAL34_DATA(destination));
  }
  else if(getSystemFlag(FLAG_MDY)) {
    composeJulianDay(&part3, &part1, &part2, REGISTER_REAL34_DATA(destination));
  }
  else if(getSystemFlag(FLAG_DMY)) {
    composeJulianDay(&part3, &part2, &part1, REGISTER_REAL34_DATA(destination));
  }

  int32ToReal34(86400, &val), real34Multiply(REGISTER_REAL34_DATA(destination), &val, REGISTER_REAL34_DATA(destination));
  int32ToReal34(43200, &val), real34Add(REGISTER_REAL34_DATA(destination), &val, REGISTER_REAL34_DATA(destination));
}



void convertReal34MatrixRegisterToReal34Matrix(calcRegister_t regist, real34Matrix_t *matrix) {
  dataBlock_t *dblock           = REGISTER_REAL34_MATRIX_DBLOCK(regist);
  real34_t    *matrixElem     = REGISTER_REAL34_MATRIX_M_ELEMENTS(regist);

  if(realMatrixInit(matrix, dblock->matrixRows, dblock->matrixColumns)) {
    if(matrix->matrixElements) {
      xcopy(matrix->matrixElements, REGISTER_REAL34_MATRIX_M_ELEMENTS(regist), (matrix->header.matrixColumns * matrix->header.matrixRows) * sizeof(real34_t));

      for(int i = 0; i < matrix->header.matrixColumns * matrix->header.matrixRows; i++) {
        real34Copy(&matrixElem[i], &matrix->matrixElements[i]);
      }
    }
  }
  else {
    displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
  }
}

void convertReal34MatrixToReal34MatrixRegister(const real34Matrix_t *matrix, calcRegister_t regist) {
  const size_t neededSize = (matrix->header.matrixColumns * matrix->header.matrixRows) * sizeof(real34_t);
  reallocateRegister(regist, dtReal34Matrix, TO_BLOCKS(neededSize), amNone);
  if(lastErrorCode != ERROR_RAM_FULL) {
    xcopy(REGISTER_REAL34_MATRIX(regist), matrix, sizeof(dataBlock_t));
    xcopy(REGISTER_REAL34_MATRIX_M_ELEMENTS(regist), matrix->matrixElements, neededSize);
  }
}

void convertComplex34MatrixRegisterToComplex34Matrix(calcRegister_t regist, complex34Matrix_t *matrix) {
  dataBlock_t *dblock           = REGISTER_COMPLEX34_MATRIX_DBLOCK(regist);
  complex34_t *matrixElem       = REGISTER_COMPLEX34_MATRIX_M_ELEMENTS(regist);

  if(complexMatrixInit(matrix, dblock->matrixRows, dblock->matrixColumns)) {
    if(matrix->matrixElements) {
      xcopy(matrix->matrixElements, REGISTER_COMPLEX34_MATRIX_M_ELEMENTS(regist), (matrix->header.matrixColumns * matrix->header.matrixRows) * sizeof(complex34_t));

        for(int i = 0; i < matrix->header.matrixColumns * matrix->header.matrixRows; i++) {
          complex34Copy(&matrixElem[i], &matrix->matrixElements[i]);
        }
      }
    }
    else {
      displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
    }
  }

void convertComplex34MatrixToComplex34MatrixRegister(const complex34Matrix_t *matrix, calcRegister_t regist) {
  reallocateRegister(regist, dtComplex34Matrix, TO_BLOCKS((matrix->header.matrixColumns * matrix->header.matrixRows) * sizeof(complex34_t)), amNone);
  if(lastErrorCode != ERROR_RAM_FULL) {
    xcopy(REGISTER_COMPLEX34_MATRIX(regist), matrix, sizeof(dataBlock_t));
    xcopy(REGISTER_COMPLEX34_MATRIX_M_ELEMENTS(regist), matrix->matrixElements, (matrix->header.matrixColumns * matrix->header.matrixRows) * sizeof(complex34_t));
  }
}

void convertReal34MatrixToComplex34Matrix(const real34Matrix_t *source, complex34Matrix_t *destination) {
  if(complexMatrixInit(destination, source->header.matrixRows, source->header.matrixColumns)) {
    if(destination->matrixElements) {
      for(uint16_t i = 0; i < source->header.matrixRows * source->header.matrixColumns; ++i) {
        real34Copy(&source->matrixElements[i], VARIABLE_REAL34_DATA(&destination->matrixElements[i]));
        real34Zero(VARIABLE_IMAG34_DATA(&destination->matrixElements[i]));
      }
    }
  }
  else {
    displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
  }
}

void convertReal34MatrixRegisterToComplex34Matrix(calcRegister_t source, complex34Matrix_t *destination) {
  real34Matrix_t matrix;
  linkToRealMatrixRegister(source, &matrix);
  convertReal34MatrixToComplex34Matrix(&matrix, destination);
}

void convertReal34MatrixRegisterToComplex34MatrixRegister(calcRegister_t source, calcRegister_t destination) {
  complex34Matrix_t matrix;
  convertReal34MatrixRegisterToComplex34Matrix(source, &matrix);
  convertComplex34MatrixToComplex34MatrixRegister(&matrix, destination);
  setComplexRegisterAngularMode(destination, currentAngularMode);
  setComplexRegisterPolarMode(destination, getSystemFlag(FLAG_POLAR) ? amPolar : 0);
  complexMatrixFree(&matrix);
}

#if !defined(TESTSUITE_BUILD)
  void convertDoubleToString(double x, int16_t n, char *buff) { //Reformatting real strings that are formatted according to different locale settings
    uint16_t i = 2;
    uint16_t j = 2;
    bool_t error = false;

    snprintf(buff, n, "%.16e", x);

    if(buff[0] != '-') {
      i = 0;
      while(buff[i] != 0) {
        i++;
      }
      buff[i+1] = 0;
      while(i != 0) {
        buff[i] = buff[i-1];
        i--;
      }
      buff[0] = '+';
    }

    if(buff[0]!=0 && (buff[1]=='+' || buff[1]!='-') && (buff[2]=='.' || buff[2]==',')) {
      buff[2] = '.';
      i = 3;
      j = 3;
      while(buff[i] != 0) {
        if(buff[i]==',' || buff[i]=='.' || buff[i]==' ') {
          buff[j] = 0;
        }
        else {
          buff[j] = buff[i];
          j++;
        }
        i++;
      }
      buff[j] = 0;
    }
    else {
      error = true;
    }

    //debug code to check for locale error by forcing a real conversion
    //  stringToReal34(buff, REGISTER_REAL34_DATA(REGISTER_X));
    //  if(real34IsNaN(REGISTER_REAL34_DATA(REGISTER_X))) error = true;

      if(error) {
        #if defined(PC_BUILD)
          printf("ERROR in locale: doubleToString: attempt to correct:  §%s§\n", buff);
          snprintf(buff, 100, "%.16e", x);
          printf("                                 Original conversion: §%s§\n", buff);
        #endif //PC_BUILD
        strcpy(buff,"NaN");
      }
    }


  void convertDoubleToReal(double x, real_t *destination, realContext_t *ctxt) {
    char buff[100];

    buff[0]=0;
    convertDoubleToString(x, 100, buff);
    stringToReal(buff, destination, ctxt);
  }

  void convertDoubleToReal34Register(double x, calcRegister_t destination) {
    char buff[100];

    reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
    convertDoubleToString(x, 100, buff);
    stringToReal34(buff, REGISTER_REAL34_DATA(REGISTER_X));

    #if defined(PC_BUILD)
      if(real34IsNaN(REGISTER_REAL34_DATA(REGISTER_X))) {
        snprintf(buff, 100, "%.16e", x);
        printf("ERROR in convertDoubleToReal34Register: %s\n",buff);
      }
    #endif // PC_BUILD
  }
#endif // !TESTSUITE_BUILD


double convertRegisterToDouble(calcRegister_t regist) {
  double y;
  real_t tmpy;

  switch(getRegisterDataType(regist)) {
    case dtLongInteger: {
      convertLongIntegerRegisterToReal(regist, &tmpy, &ctxtReal39);
      break;
    }
    case dtReal34:
    case dtComplex34: {
      real34ToReal(REGISTER_REAL34_DATA(regist), &tmpy);
      break;
    }
    default: {
      #if defined(PC_BUILD)
        printf("ERROR IN convertRegisterToDouble\n");
      #endif
      return DOUBLE_NOT_INIT;
      break;
    }
  }
  realToDouble(&tmpy, &y);
  return y;
}


//Pauli volunteered this fuction, rev 1 2021-10-10
#if DECDPUN != 3
  #error DECDPUN must be 3
#endif

static float fnRealToFloat(const real_t *r){
  int s = 0;
  int j, n, e;

  static const float exps[] = {
    1.e-45, 1.e-44, 1.e-43, 1.e-42, 1.e-41, 1.e-40, 1.e-39, 1.e-38,
    1.e-37, 1.e-36, 1.e-35, 1.e-34, 1.e-33, 1.e-32, 1.e-31, 1.e-30,
    1.e-29, 1.e-28, 1.e-27, 1.e-26, 1.e-25, 1.e-24, 1.e-23, 1.e-22,
    1.e-21, 1.e-20, 1.e-19, 1.e-18, 1.e-17, 1.e-16, 1.e-15, 1.e-14,
    1.e-13, 1.e-12, 1.e-11, 1.e-10, 1.e-9,  1.e-8,  1.e-7,  1.e-6,
    1.e-5,  1.e-4,  1.e-3,  1.e-2,  1.e-1,  1.e0,   1.e1,   1.e2,
    1.e3,   1.e4,   1.e5,   1.e6,   1.e7,   1.e8,   1.e9,
    1.e10,  1.e11,  1.e12,  1.e13,  1.e14,  1.e15,  1.e16,  1.e17,
    1.e18,  1.e19,  1.e20,  1.e21,  1.e22,  1.e23,  1.e24,  1.e25,
    1.e26,  1.e27,  1.e28,  1.e29,  1.e30,  1.e31,  1.e32,  1.e33,
    1.e34,  1.e35,  1.e36,  1.e37,  1.e38
  };

  if(realIsSpecial(r)) {
    if(realIsNaN(r)) {
      return 0. / 0.;
    }
    goto infinite;
  }
  if(realIsZero(r)) {
    goto zero;
  }

  j = (r->digits + DECDPUN-1) / DECDPUN;
  while(j > 0) {
    if((s = r->lsu[--j]) != 0) {
      break;
    }
  }
  for(n = 0; --j >= 0 && n < 2; n++) {
    s = (s * 1000) + r->lsu[j];
  }
  if(realIsNegative(r)) {
    s = -s;
  }
  e = r->exponent + (j + 1) * DECDPUN;
  if(e < -45) {
zero:
    return realIsPositive(r) ? 0. : -0.;
  }
  if(e > 38) {
infinite:
    if(realIsPositive(r)) {
      return 1. / 0.;
    }
    return -1. / 0.;
  }
  return (float)s * exps[e + 45];
}

//#define realToReal39(source, destination) decQuadFromNumber ((real39_t *)(destination), source, &ctxtReal39)

void realToFloat(const real_t *vv, float *v) {
  *v = fnRealToFloat(vv);
}

void realToDouble(const real_t *vv, double *v) {      //Not using double internally, i.e. using float type. Change fnRealToFloat if double is needed in future
  *v = fnRealToFloat(vv);
}

bool_t getRegisterAsComplex(calcRegister_t reg, real_t *r, real_t *i) {
  switch(getRegisterDataType(reg)) {
    case dtLongInteger:
      convertLongIntegerRegisterToReal(reg, r, &ctxtReal75);
      break;

    case dtShortInteger:
      convertShortIntegerRegisterToReal(reg, r, &ctxtReal34);
      break;

    case dtReal34:
      real34ToReal(REGISTER_REAL34_DATA(reg), r);
      break;

    case dtComplex34:
      real34ToReal(REGISTER_REAL34_DATA(reg), r);
      real34ToReal(REGISTER_IMAG34_DATA(reg), i);
      return true;

    default: {
      displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, reg);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "cannot convert %d from %s to complex", reg, getRegisterDataTypeName(reg, true, false));
        moreInfoOnError("In function getRegisterAsComplex:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return false;
    }
  }
  realZero(i);
  return true;
}

bool_t getRegisterAsComplexOrReal(calcRegister_t reg, real_t *r, real_t *i, bool_t *cmplx) {
  switch(getRegisterDataType(reg)) {
    case dtLongInteger:
      convertLongIntegerRegisterToReal(reg, r, &ctxtReal75);
      break;

    case dtShortInteger:
      convertShortIntegerRegisterToReal(reg, r, &ctxtReal34);
      break;

    case dtReal34:
      real34ToReal(REGISTER_REAL34_DATA(reg), r);
      break;

    case dtComplex34:
      real34ToReal(REGISTER_REAL34_DATA(reg), r);
      real34ToReal(REGISTER_IMAG34_DATA(reg), i);
      *cmplx = true;
      return true;

    default:
      displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, reg);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "cannot convert %d from %s to complex", reg, getRegisterDataTypeName(reg, true, false));
        moreInfoOnError("In function getRegisterAsComplexOrReal:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return false;
  }
  realZero(i);
  return true;
}

bool_t getRegisterAsReal(calcRegister_t reg, real_t *val) {
  switch(getRegisterDataType(reg)) {
    case dtLongInteger:
      convertLongIntegerRegisterToReal(reg, val, &ctxtReal75);
      break;

    case dtShortInteger:
      convertShortIntegerRegisterToReal(reg, val, &ctxtReal34);
      break;

    case dtReal34:
      real34ToReal(REGISTER_REAL34_DATA(reg), val);
      break;

    case dtComplex34:
      if (real34IsZero(REGISTER_IMAG34_DATA(reg))) {
        real34ToReal(REGISTER_REAL34_DATA(reg), val);
        break;
      }
    /* fall through */

    default:
      displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, reg);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "cannot convert %d from %s to real", reg, getRegisterDataTypeName(reg, true, false));
        moreInfoOnError("In function getRegisterAsReal:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return false;
  }
  return true;
}

void processRealComplexMonadicFunction(void (*realf)(void), void (*complexf)(void)) {
  real_t aReal, aImag;
  bool_t cmplxRes = false;
  const uint32_t type = getRegisterDataType(REGISTER_X);

  if(!saveLastX())
    return;

  if (type == dtReal34Matrix)
    elementwiseRema(realf);
  else if (type == dtComplex34Matrix)
    elementwiseCxma(complexf);
  else if (getRegisterAsComplexOrReal(REGISTER_X, &aReal, &aImag, &cmplxRes)) {
    if (cmplxRes)
      complexf();
    else
      realf();
  }

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}
