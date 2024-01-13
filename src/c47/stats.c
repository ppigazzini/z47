// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors


#include "stats.h"

#include "constantPointers.h"
#include "c43Extensions/graphText.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "fonts.h"
#include "items.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/matrix.h"
#include "mathematics/wp34s.h"
#include "memory.h"
#include "plotstat.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "screen.h"
#include "stack.h"
#include <string.h>

#include "c47.h"


#if !defined(TESTSUITE_BUILD) //TESTSUITE_BUILD
  static void calcMax(uint16_t maxOffset);
  static void calcMin(uint16_t maxOffset);
#endif // !TESTSUITE_BUILD

bool_t isStatsMatrixN(uint16_t *rows, calcRegister_t regStats) {
  #if !defined(TESTSUITE_BUILD)
    *rows = 0;
    if(regStats == INVALID_VARIABLE) {
      return false;
    }
    else {
      if(getRegisterDataType(regStats) != dtReal34Matrix) {
        return false;
      }
      else {
        real34Matrix_t stats;
        linkToRealMatrixRegister(regStats, &stats);
        *rows = stats.header.matrixRows;
        if(stats.header.matrixColumns != 2) {
          return false;
        }
      }
    }
  #endif // !TESTSUITE_BUILD
  return true;
}



bool_t isStatsMatrix(uint16_t *rows, char *mx) {
  #if !defined(TESTSUITE_BUILD)
    *rows = 0;
    calcRegister_t regStats = findNamedVariable(mx);
    if(regStats == INVALID_VARIABLE) {
      return false;
    }
    else {
      if(getRegisterDataType(regStats) != dtReal34Matrix) {
        return false;
      }
      else {
        real34Matrix_t stats;
        linkToRealMatrixRegister(regStats, &stats);
        *rows = stats.header.matrixRows;
        if(stats.header.matrixColumns != 2) {
          return false;
        }
      }
    }
  #endif // !TESTSUITE_BUILD
  return true;
}



#if !defined(TESTSUITE_BUILD)
  static void addMax(real_t *x, real_t *y) {
    // xmax
    if(realCompareGreaterThan(x, SIGMA_XMAX)) {
      realCopy(x, SIGMA_XMAX);
    }

    // ymax
    if(realCompareGreaterThan(y, SIGMA_YMAX)) {
      realCopy(y, SIGMA_YMAX);
    }
  }


  static void addMin(real_t *x, real_t *y) {
    // xmin
    if(realCompareLessThan(x, SIGMA_XMIN)) {
      realCopy(x, SIGMA_XMIN);
    }

    // ymin
    if(realCompareLessThan(y, SIGMA_YMIN)) {
      realCopy(y, SIGMA_YMIN);
    }
  }


  static void addSigma(real_t *x, real_t *y) {
    real_t tmpReal1, tmpReal2, tmpReal3;
    realContext_t *realContext = &ctxtReal75; // Summation data with 75 digits

    addMax(x, y);
    addMin(x, y);

    // n
    realAdd(SIGMA_N, const_1, SIGMA_N, realContext);

    // sigma x
    realAdd(SIGMA_X, x, SIGMA_X, realContext);

    // sigma y
    realAdd(SIGMA_Y, y, SIGMA_Y, realContext);

    // sigma x²
    realMultiply(x, x, &tmpReal1, realContext);
    realAdd(SIGMA_X2, &tmpReal1, SIGMA_X2, realContext);

    // sigma x³
    realMultiply(&tmpReal1, x, &tmpReal2, realContext);
    realAdd(SIGMA_X3, &tmpReal2, SIGMA_X3, realContext);

    // sigma x⁴
    realMultiply(&tmpReal2, x, &tmpReal2, realContext);
    realAdd(SIGMA_X4, &tmpReal2, SIGMA_X4, realContext);

    // sigma x²y
    realMultiply(&tmpReal1, y, &tmpReal2, realContext);
    realAdd(SIGMA_X2Y, &tmpReal2, SIGMA_X2Y, realContext);

    // sigma x²/y
    realDivide(&tmpReal1, y, &tmpReal2, realContext);
    realAdd(SIGMA_X2onY, &tmpReal2, SIGMA_X2onY, realContext);

    // sigma 1/x²
    realDivide(const_1, &tmpReal1, &tmpReal2, realContext);
    realAdd(SIGMA_1onX2, &tmpReal2, SIGMA_1onX2, realContext);

    // sigma y²
    realMultiply(y, y, &tmpReal1, realContext);
    realAdd(SIGMA_Y2, &tmpReal1, SIGMA_Y2, realContext);

    // sigma 1/y²
    realDivide(const_1, &tmpReal1, &tmpReal2, realContext);
    realAdd(SIGMA_1onY2, &tmpReal2, SIGMA_1onY2, realContext);

    // sigma xy
    realMultiply(x, y, &tmpReal1, realContext);
    realAdd(SIGMA_XY, &tmpReal1, SIGMA_XY, realContext);

    // sigma ln(x)
    WP34S_Ln(x, &tmpReal1, realContext);
    realCopy(&tmpReal1 ,&tmpReal3);
    realAdd(SIGMA_lnX, &tmpReal1, SIGMA_lnX, realContext);

    // sigma ln²(x)
    realMultiply(&tmpReal1, &tmpReal1, &tmpReal2, realContext);
    realAdd(SIGMA_ln2X, &tmpReal2, SIGMA_ln2X, realContext);

    // sigma yln(x)
    realMultiply(&tmpReal1, y, &tmpReal1, realContext);
    realAdd(SIGMA_YlnX, &tmpReal1, SIGMA_YlnX, realContext);

    // sigma ln(y)
    WP34S_Ln(y, &tmpReal1, realContext);
    realAdd(SIGMA_lnY, &tmpReal1, SIGMA_lnY, realContext);

    // sigma ln(x)×ln(y)
    realMultiply(&tmpReal3, &tmpReal1, &tmpReal3, realContext);
    realAdd(SIGMA_lnXlnY, &tmpReal3, SIGMA_lnXlnY, realContext);

    // sigma ln(y)/x
    realDivide(&tmpReal1, x, &tmpReal2, realContext);
    realAdd(SIGMA_lnYonX, &tmpReal2, SIGMA_lnYonX, realContext);

    // sigma ln²(y)
    realMultiply(&tmpReal1, &tmpReal1, &tmpReal2, realContext);
    realAdd(SIGMA_ln2Y, &tmpReal2, SIGMA_ln2Y, realContext);

    // sigma xln(y)
    realMultiply(&tmpReal1, x, &tmpReal1, realContext);
    realAdd(SIGMA_XlnY, &tmpReal1, SIGMA_XlnY, realContext);

    // sigma x²ln(y)
    realMultiply(&tmpReal1, x, &tmpReal1, realContext);
    realAdd(SIGMA_X2lnY, &tmpReal1, SIGMA_X2lnY, realContext);

    // sigma 1/x
    realDivide(const_1, x, &tmpReal1, realContext);
    realAdd(SIGMA_1onX, &tmpReal1, SIGMA_1onX, realContext);

    // sigma x/y
    realDivide(x, y, &tmpReal1, realContext);
    realAdd(SIGMA_XonY, &tmpReal1, SIGMA_XonY, realContext);

    // sigma 1/y
    realDivide(const_1, y, &tmpReal1, realContext);
    realAdd(SIGMA_1onY, &tmpReal1, SIGMA_1onY, realContext);
  }


  static bool_t ignoreMaxIfValid(real_t *r1, real_t *r2){
    if(realIsNaN (r1) || realIsNaN (r2) || realIsInfinite (r1) || realIsInfinite (r2) || realCompareEqual(r1, r2)) {
      calcMax(1);
      return false;
    }
    return true;
  }

  static bool_t ignoreMinIfValid(real_t *r1, real_t *r2){
    if(realIsNaN (r1) || realIsNaN (r2) || realIsInfinite (r1) || realIsInfinite (r2) || realCompareEqual(r1, r2)) {
      calcMin(1);
      return false;
    }
    return true;
  }


  static bool_t realSubtractIfValid(real_t *r1, real_t *r2, real_t *r3, realContext_t *ct){
    if(realIsNaN (r1) || realIsNaN (r2) || realIsInfinite (r1) || realIsInfinite (r2)) {
      calcSigma(1);
      return false;
    }
    realSubtract(r1, r2, r3, ct);
    return true;
  }


  static void subSigma(real_t *x, real_t *y) {
    real_t tmpReal1, tmpReal2, tmpReal3;
    realContext_t *realContext = &ctxtReal75; // Summation data with 75 digits
   // SIGMA-

    // xmax
    if(!ignoreMaxIfValid(x, SIGMA_XMAX)) {
      goto endMax;
    }

    // ymax
    if(!ignoreMaxIfValid(y, SIGMA_YMAX)) {
      goto endMax;
    }

    endMax:

    // xmin
    if(!ignoreMinIfValid(x, SIGMA_XMIN)) {
      goto endMin;
    }

    // ymin
    if(!ignoreMinIfValid(y, SIGMA_YMIN)) {
      goto endMin;
    }

    endMin:

    // n
    realCopy(const_1,&tmpReal1);
    if(!realSubtractIfValid(SIGMA_N, &tmpReal1, SIGMA_N, realContext)) {
      goto toReturn;
    }

    // sigma x
    if(!realSubtractIfValid(SIGMA_X, x, SIGMA_X, realContext)) {
      goto toReturn;
    }

    // sigma y
    if(!realSubtractIfValid(SIGMA_Y, y, SIGMA_Y, realContext)) {
      goto toReturn;
    }

    // sigma x²
    realMultiply(x, x, &tmpReal1, realContext);
    if(!realSubtractIfValid(SIGMA_X2, &tmpReal1, SIGMA_X2, realContext)) {
      goto toReturn;
    }

    // sigma x³
    realMultiply(&tmpReal1, x, &tmpReal2, realContext);
    if(!realSubtractIfValid(SIGMA_X3, &tmpReal2, SIGMA_X3, realContext)) {
      goto toReturn;
    }

    // sigma x⁴
    realMultiply(&tmpReal2, x, &tmpReal2, realContext);
    if(!realSubtractIfValid(SIGMA_X4, &tmpReal2, SIGMA_X4, realContext)) {
      goto toReturn;
    }

    // sigma x²y
    realMultiply(&tmpReal1, y, &tmpReal2, realContext);
    if(!realSubtractIfValid(SIGMA_X2Y, &tmpReal2, SIGMA_X2Y, realContext)) {
      goto toReturn;
    }

    // sigma x²/y
    realDivide(&tmpReal1, y, &tmpReal2, realContext);
    if(!realSubtractIfValid(SIGMA_X2onY, &tmpReal2, SIGMA_X2onY, realContext)) {
      goto toReturn;
    }

    // sigma 1/x²
    realDivide(const_1, &tmpReal1, &tmpReal2, realContext);
    if(!realSubtractIfValid(SIGMA_1onX2, &tmpReal2, SIGMA_1onX2, realContext)) {
      goto toReturn;
    }

    // sigma y²
    realMultiply(y, y, &tmpReal1, realContext);
    if(!realSubtractIfValid(SIGMA_Y2, &tmpReal1, SIGMA_Y2, realContext)) {
      goto toReturn;
    }

    // sigma 1/y²
    realDivide(const_1, &tmpReal1, &tmpReal2, realContext);
    if(!realSubtractIfValid(SIGMA_1onY2, &tmpReal2, SIGMA_1onY2, realContext)) {
      goto toReturn;
    }

    // sigma xy
    realMultiply(x, y, &tmpReal1, realContext);
    if(!realSubtractIfValid(SIGMA_XY, &tmpReal1, SIGMA_XY, realContext)) {
      goto toReturn;
    }

    // sigma ln(x)
    WP34S_Ln(x, &tmpReal1, realContext);
    realCopy(&tmpReal1 ,&tmpReal3);
    if(!realSubtractIfValid(SIGMA_lnX, &tmpReal1, SIGMA_lnX, realContext)) {
      goto toReturn;
    }

    // sigma ln²(x)
    realMultiply(&tmpReal1, &tmpReal1, &tmpReal2, realContext);
    if(!realSubtractIfValid(SIGMA_ln2X, &tmpReal2, SIGMA_ln2X, realContext)) {
      goto toReturn;
    }

    // sigma yln(x)
    realMultiply(&tmpReal1, y, &tmpReal1, realContext);
    if(!realSubtractIfValid(SIGMA_YlnX, &tmpReal1, SIGMA_YlnX, realContext)) {
      goto toReturn;
    }

    // sigma ln(y)
    WP34S_Ln(y, &tmpReal1, realContext);
    if(!realSubtractIfValid(SIGMA_lnY, &tmpReal1, SIGMA_lnY, realContext)) {
      goto toReturn;
    }

    // sigma ln(x)×ln(y)
    realMultiply(&tmpReal3, &tmpReal1, &tmpReal3, realContext);
    if(!realSubtractIfValid(SIGMA_lnXlnY, &tmpReal3, SIGMA_lnXlnY, realContext)) {
      goto toReturn;
    }

    // sigma ln(y)/x
    realDivide(&tmpReal1, x, &tmpReal2, realContext);
    if(!realSubtractIfValid(SIGMA_lnYonX, &tmpReal2, SIGMA_lnYonX, realContext)) {
      goto toReturn;
    }

    // sigma ln²(y)
    realMultiply(&tmpReal1, &tmpReal1, &tmpReal2, realContext);
    if(!realSubtractIfValid(SIGMA_ln2Y, &tmpReal2, SIGMA_ln2Y, realContext)) {
      goto toReturn;
    }

    // sigma xln(y)
    realMultiply(&tmpReal1, x, &tmpReal1, realContext);
    if(!realSubtractIfValid(SIGMA_XlnY, &tmpReal1, SIGMA_XlnY, realContext)) {
      goto toReturn;
    }

    // sigma x²ln(y)
    realMultiply(&tmpReal1, x, &tmpReal1, realContext);
    if(!realSubtractIfValid(SIGMA_X2lnY, &tmpReal1, SIGMA_X2lnY, realContext)) {
      goto toReturn;
    }

    // sigma 1/x
    realDivide(const_1, x, &tmpReal1, realContext);
    if(!realSubtractIfValid(SIGMA_1onX, &tmpReal1, SIGMA_1onX, realContext)) {
      goto toReturn;
    }

    // sigma x/y
    realDivide(x, y, &tmpReal1, realContext);
    if(!realSubtractIfValid(SIGMA_XonY, &tmpReal1, SIGMA_XonY, realContext)) {
      goto toReturn;
    }

    // sigma 1/y
    realDivide(const_1, y, &tmpReal1, realContext);
    if(!realSubtractIfValid(SIGMA_1onY, &tmpReal1, SIGMA_1onY, realContext)) {
      goto toReturn;
    }

    toReturn:

    return;
  }
#endif // !TESTSUITE_|BUILD



bool_t checkMinimumDataPoints(const real_t *n) {
  if(statisticalSumsPointer == NULL) {
    displayCalcErrorMessage(ERROR_NO_SUMMATION_DATA, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function checkMinimumDataPoints:", "There is no statistical data available!", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return false;
  }

  if(realCompareLessThan(SIGMA_N, n)) {
    displayCalcErrorMessage(ERROR_TOO_FEW_DATA, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function checkMinimumDataPoints:", "There is insufficient statistical data available!", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return false;
  }
  return true;
}


static void clearStatisticalSums(void) {
  if(statisticalSumsPointer) {
    for(int32_t sum=0; sum<NUMBER_OF_STATISTICAL_SUMS - 4; sum++) {
      realZero((real_t *)(statisticalSumsPointer + REAL_SIZE_IN_BLOCKS * sum));
    }
    realCopy(const_plusInfinity,  SIGMA_XMIN);
    realCopy(const_plusInfinity,  SIGMA_YMIN);
    realCopy(const_minusInfinity, SIGMA_XMAX);
    realCopy(const_minusInfinity, SIGMA_YMAX);
  }
}


void initStatisticalSums(void) {
  if(statisticalSumsUpdate) {
    if(statisticalSumsPointer == NULL) {
      statisticalSumsPointer = allocC47Blocks(NUMBER_OF_STATISTICAL_SUMS * REAL_SIZE_IN_BLOCKS);
      clearStatisticalSums();
    }
  else {
      displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
    }
    uint16_t rows;
    strcpy(statMx,"STATS");                     //any stats operation restores the stats matrix. The purpose of the changed names are just to be able to exchange the matrixes for reading and graphing
    calcRegister_t regStats = findNamedVariable(statMx);
    if(isStatsMatrixN(&rows, regStats) && rows > 0) {
      calcSigma(0);
    }
  }
}



#if !defined(TESTSUITE_BUILD)
  static void calcMax(uint16_t maxOffset) {
    realCopy(const_minusInfinity, SIGMA_XMAX);
    realCopy(const_minusInfinity, SIGMA_YMAX);

    calcRegister_t regStats = findNamedVariable(statMx);
    if(regStats != INVALID_VARIABLE) {
      real34Matrix_t stats;
      linkToRealMatrixRegister(regStats, &stats);
      const uint16_t rows = stats.header.matrixRows, cols = stats.header.matrixColumns;

      real_t x, y;
      for(uint16_t i = 0; i < rows - maxOffset; i++) {
        real34ToReal(&stats.matrixElements[i * cols    ], &x);
        real34ToReal(&stats.matrixElements[i * cols + 1], &y);
        addMax(&x, &y);
      }
    }
  }


  static void calcMin(uint16_t maxOffset) {
    realCopy(const_plusInfinity,  SIGMA_XMIN);
    realCopy(const_plusInfinity,  SIGMA_YMIN);

    calcRegister_t regStats = findNamedVariable(statMx);
    if(regStats != INVALID_VARIABLE) {
      real34Matrix_t stats;
      linkToRealMatrixRegister(regStats, &stats);
      const uint16_t rows = stats.header.matrixRows, cols = stats.header.matrixColumns;
      real_t x, y;
      for(uint16_t i = 0; i < rows - maxOffset; i++) {
        real34ToReal(&stats.matrixElements[i * cols    ], &x);
        real34ToReal(&stats.matrixElements[i * cols + 1], &y);
        addMin(&x, &y);
      }
    }
  }
#endif // !TESTSUITE_BUILD



void calcSigma(uint16_t maxOffset) {
  #if !defined(TESTSUITE_BUILD)
    clearStatisticalSums();
    if(!statisticalSumsPointer) {
      initStatisticalSums();
    }
    calcRegister_t regStats = findNamedVariable(statMx);
    uint16_t rr = 1;
    if(regStats >= FIRST_NAMED_VARIABLE && isStatsMatrixN(&rr, regStats) && regStats != INVALID_VARIABLE) {
      real34Matrix_t stats;
      linkToRealMatrixRegister(regStats, &stats);
      const uint16_t rows = stats.header.matrixRows, cols = stats.header.matrixColumns;
      real_t x, y;
      char aa[100];
      for(uint16_t i = 0; i < rows - maxOffset; i++) {
        sprintf(aa,"%s%s (%u of %u)",errorMessages[RECALC_SUMS], statMx,i,rows - maxOffset);
        printStatus(0, aa,force);
        real34ToReal(&stats.matrixElements[i * cols    ], &x);
        real34ToReal(&stats.matrixElements[i * cols + 1], &y);
        addSigma(&x, &y);
      }
    }
    printStatus(0, " ",force);
  #endif //TESTSUITE_BUILD
}


#if !defined(TESTSUITE_BUILD)
static void getLastRowStatsMatrix(real_t *x, real_t *y) {
  uint16_t rows = 0, cols;
  calcRegister_t regStats = findNamedVariable(statMx);

  if(regStats != INVALID_VARIABLE) {
    real34Matrix_t stats;
    linkToRealMatrixRegister(regStats, &stats);
    rows = stats.header.matrixRows;
    cols = stats.header.matrixColumns;
    real34ToReal(&stats.matrixElements[(rows-1) * cols    ], x);
    real34ToReal(&stats.matrixElements[(rows-1) * cols + 1], y);
  }
  else {
    displayCalcErrorMessage(ERROR_NO_SUMMATION_DATA, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "STATS matrix not found");
      moreInfoOnError("In function getLastRowStatsMatrix:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}



  static void AddtoStatsMatrix(real_t *x, real_t *y) {
    uint16_t rows = 0, cols;
    strcpy(statMx,"STATS");                     //any stats operation restores the stats matrix. The purpose of the changed names are just to be able to exchange the matrixes for reading and graphing
    calcRegister_t regStats = findNamedVariable(statMx);
    if(!isStatsMatrix(&rows,statMx)) {
      regStats = allocateNamedMatrix(statMx, 1, 2);
      real34Matrix_t stats;
      linkToRealMatrixRegister(regStats, &stats);
      //realMatrixInit(&stats,1,2);
    }
    else {
      if(appendRowAtMatrixRegister(regStats)) {
      }
      else {
        regStats = INVALID_VARIABLE;
      }
    }
    if(regStats != INVALID_VARIABLE) {
      real34Matrix_t stats;
      linkToRealMatrixRegister(regStats, &stats);
      rows = stats.header.matrixRows;
      cols = stats.header.matrixColumns;
      realToReal34(x, &stats.matrixElements[(rows-1) * cols    ]);
      realToReal34(y, &stats.matrixElements[(rows-1) * cols + 1]);
    }
    else {
      displayCalcErrorMessage(ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "additional matrix line not added; rows = %i",rows);
        moreInfoOnError("In function AddtoStatsMatrix:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }



  static void removeLastRowFromStatsMatrix(void) {
    uint16_t rows = 0;
    strcpy(statMx,"STATS");                     //any stats operation restores the stats matrix. The purpose of the changed names are just to be able to exchange the matrixes for reading and graphing
    if(!isStatsMatrix(&rows,statMx)) {
      displayCalcErrorMessage(ERROR_NO_SUMMATION_DATA, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "no STATS matrix");
        moreInfoOnError("In function removeLastRowFromStatsMatrix:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }

    calcRegister_t regStats = findNamedVariable(statMx);
    if(rows <= 1) {
      fnClSigma(0);
      return;
    }
    else {
      if(!redimMatrixRegister(regStats, rows - 1, 2)) {
        regStats = INVALID_VARIABLE;
      }
    }
    if(regStats == INVALID_VARIABLE) {
      displayCalcErrorMessage(ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "matrix/line not removed");
        moreInfoOnError("In function removeFromStatsMatrix:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }
#endif // !TESTSUITE_BUILD


static calcRegister_t fnClHisto(bool_t deleteVariable) {
  #if !defined(TESTSUITE_BUILD)
    calcRegister_t regHisto = findNamedVariable("HISTO");
    if(regHisto == INVALID_VARIABLE) {
      allocateNamedVariable("HISTO", dtReal34, REAL34_SIZE_IN_BLOCKS);
      regHisto = findNamedVariable("HISTO");
    }
    if(regHisto == INVALID_VARIABLE) {
      displayCalcErrorMessage(ERROR_NO_MATRIX_INDEXED, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "HISTO matrix not created");
        moreInfoOnError("In function fnClHisto:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return INVALID_VARIABLE;
    }
    if(deleteVariable) {
      fnDeleteVariable(regHisto);
      return INVALID_VARIABLE;
    }
    else {
      clearRegister(regHisto);
      return regHisto;
    }
  #else
    return INVALID_VARIABLE;
  #endif //TESTSUITE_BUILD
}


void setStatisticalSumsUpdate(bool_t para) {
  //if going off auto, or confirming it is still on auto off, clear sums
  if(!para) {
    if(statisticalSumsPointer != NULL) {
      freeC47Blocks(statisticalSumsPointer, NUMBER_OF_STATISTICAL_SUMS * REAL_SIZE_IN_BLOCKS);
      statisticalSumsPointer = NULL;
      if(lastErrorCode != ERROR_NONE) {
        return;
      }
    }
  }
  if (statisticalSumsUpdate && !para) {
    //It is on auto and it is being switched off auto. Stats sums already cleared, just set the flag.
    statisticalSumsUpdate = false;
  } else
  if (!statisticalSumsUpdate && para) {
    //it is off auto and it is swithing on to auto update. Clear and sums and calc up any existing matrix.
    statisticalSumsUpdate = true;
    initStatisticalSums(); //calcSigma is implied
    if(lastErrorCode != ERROR_NONE) {
      return;
    }
  }
  //it it is off auto and switched off, it must remain so. Not further actions
  //if it is on  auto and switched on, it must remain so. Not further actions
}


void fnClSigma(uint16_t unusedButMandatoryParameter) {
  fnClHisto(true);
  strcpy(statMx,"STATS");                     //any stats operation restores the stats matrix. The purpose of the changed names are just to be able to exchange the matrixes for reading and graphing
  calcRegister_t regStats = findNamedVariable(statMx);
  if(regStats == INVALID_VARIABLE) {
    allocateNamedVariable(statMx, dtReal34, REAL34_SIZE_IN_BLOCKS);
    regStats = findNamedVariable(statMx);
  }
  if(regStats == INVALID_VARIABLE) {
    displayCalcErrorMessage(ERROR_NO_MATRIX_INDEXED, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "STATS matrix not created");
      moreInfoOnError("In function fnClSigma:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  fnDeleteVariable(regStats);
  lrChosen = 0;                             // linear regression selection
  lastPlotMode = PLOT_NOTHING;              // last selected  plotmode
  plotSelection = 0;                        // Currently selected linear regression mode
  PLOT_ZOOM = 0;                            // Currently selected plot zoom level
  drawHistogram = 0;
  histElementXorY = 0;


  if(statisticalSumsPointer != NULL) {
    freeC47Blocks(statisticalSumsPointer, NUMBER_OF_STATISTICAL_SUMS * REAL_SIZE_IN_BLOCKS);
    statisticalSumsPointer = NULL;
  }
}



void fnSigma(uint16_t plusMinus) {
  #if !defined(TESTSUITE_BUILD)
    real_t x, y;
    realContext_t *realContext = &ctxtReal75; // Summation data with 75 digits

  lrChosen = 0;

  if(plusMinus == 1) { // SIGMA+
    if(   (getRegisterDataType(REGISTER_X) == dtLongInteger || getRegisterDataType(REGISTER_X) == dtReal34)
       && (getRegisterDataType(REGISTER_Y) == dtLongInteger || getRegisterDataType(REGISTER_Y) == dtReal34)) {

        if(statisticalSumsUpdate && statisticalSumsPointer == NULL) {
          initStatisticalSums();
          if(lastErrorCode != ERROR_NONE) {
            return;
          }
        } else {
          setStatisticalSumsUpdate(statisticalSumsUpdate);    //ensure it deletes the sums anyway if clear
          if(lastErrorCode != ERROR_NONE) {
            return;
          }
        }

      if(getRegisterDataType(REGISTER_X) == dtLongInteger) {
        convertLongIntegerRegisterToReal(REGISTER_X, &x, realContext);
        convertLongIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
      }
      else {
        real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
    }

      if(getRegisterDataType(REGISTER_Y) == dtLongInteger) {
        convertLongIntegerRegisterToReal(REGISTER_Y, &y, realContext);
        convertLongIntegerRegisterToReal34Register(REGISTER_Y, REGISTER_Y);
      }
      else {
        real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
      }

        if(statisticalSumsUpdate) {
          addSigma(&x, &y);
        }
        AddtoStatsMatrix(&x, &y);
        realCopy(&x,      &SAVED_SIGMA_LASTX);
        realCopy(&y,      &SAVED_SIGMA_LASTY);
        SAVED_SIGMA_LAct = +1;

        #if defined(DEBUGUNDO)
          calcRegister_t regStats = findNamedVariable(statMx);
          printRegisterToConsole(regStats,"From: AddtoStatsMatrix STATS:\n","\n");
        #endif //DEBUGUNDO

        if(statisticalSumsPointer != NULL) {
          temporaryInformation = TI_STATISTIC_SUMS;
        }
      }
      else if(getRegisterDataType(REGISTER_X) == dtReal34Matrix && plusMinus == 1) {
        real34Matrix_t matrix;
        linkToRealMatrixRegister(REGISTER_X, &matrix);

        if(matrix.header.matrixColumns == 2) {
          if(statisticalSumsUpdate && statisticalSumsPointer == NULL) {
            initStatisticalSums();
            if(lastErrorCode != ERROR_NONE) {
              return;
            }
          } else {
            setStatisticalSumsUpdate(statisticalSumsUpdate);    //ensure it deletes the sums anyway if clear
            if(lastErrorCode != ERROR_NONE) {
              return;
            }
          }

          if(!saveLastX()) {
            return;
          }
          for(uint16_t i = 0; i < matrix.header.matrixRows; ++i) {
            real34ToReal(&matrix.matrixElements[i * 2    ], &x);
            real34ToReal(&matrix.matrixElements[i * 2 + 1], &y);
            if(statisticalSumsUpdate) {
              addSigma(&x, &y);
            }
            AddtoStatsMatrix(&x, &y);
          }

          liftStack();
          reallocateRegister(REGISTER_Y, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
          convertRealToReal34ResultRegister(&y, REGISTER_Y);
          reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
          convertRealToReal34ResultRegister(&x, REGISTER_X);
          if(statisticalSumsPointer != NULL) {
            temporaryInformation = TI_STATISTIC_SUMS;
          }
        }
        else {
          displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
          #if(EXTRA_INFO_ON_CALC_ERROR == 1)
            sprintf(errorMessage, "cannot use %" PRIu16 STD_CROSS "%" PRId16 "-matrix as statistical data!", matrix.header.matrixRows, matrix.header.matrixColumns);
            moreInfoOnError("In function fnSigma:", errorMessage, NULL, NULL);
          #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        }
      }
      else {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
        #if(EXTRA_INFO_ON_CALC_ERROR == 1)
          sprintf(errorMessage, "cannot use (%s, %s) as statistical data!", getDataTypeName(getRegisterDataType(REGISTER_X), false, false), getDataTypeName(getRegisterDataType(REGISTER_Y), false, false));
          moreInfoOnError("In function fnSigma:", errorMessage, NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      }
    }
    else { // SIGMA-
      if(checkMinimumDataPoints(const_1)) {
        getLastRowStatsMatrix(&x, &y);
        if(statisticalSumsUpdate) {
          subSigma(&x, &y);
        }
        removeLastRowFromStatsMatrix();

        if(statisticalSumsPointer != NULL) {
          temporaryInformation = TI_STATISTIC_SUMS;
        }
        liftStack();
        setSystemFlag(FLAG_ASLIFT);
        liftStack();
        convertRealToReal34ResultRegister(&x, REGISTER_X);
        convertRealToReal34ResultRegister(&y, REGISTER_Y);

        realCopy(&x,       &SAVED_SIGMA_LASTX);
        realCopy(&y,       &SAVED_SIGMA_LASTY);
        SAVED_SIGMA_LAct = -1;

        #if defined(DEBUGUNDO)
          if(statisticalSumsPointer != NULL) {
            calcRegister_t regStats = findNamedVariable(statMx);
            //printRealToConsole(SIGMA_N,"   >>> After\n   >>>   SIGMA_N:","\n");
            //printRealToConsole(SIGMA_XMAX,"   >>>   SIGMA_MaxX:","\n");
            //printRegisterToConsole(regStats,"From Sigma-: STATS\n","\n");
          }
        #endif //DEBUGUNDO
      }
    }
  #endif // TESTSUITE_BUILD
}



void fnStatSum(uint16_t sum) {
  if(checkMinimumDataPoints(const_1)) {
    liftStack();
    realToReal34((real_t *)(statisticalSumsPointer + REAL_SIZE_IN_BLOCKS * sum), REGISTER_REAL34_DATA(REGISTER_X));
  }
}



void fnSumXY(uint16_t unusedButMandatoryParameter) {
  if(checkMinimumDataPoints(const_1)) {
    liftStack();
    setSystemFlag(FLAG_ASLIFT);
    liftStack();

    convertRealToReal34ResultRegister(SIGMA_X, REGISTER_X);
    convertRealToReal34ResultRegister(SIGMA_Y, REGISTER_Y);

    temporaryInformation = TI_SUMX_SUMY;
  }
}



void fnXmin(uint16_t unusedButMandatoryParameter) {
  if(checkMinimumDataPoints(const_1)) {
    liftStack();
    setSystemFlag(FLAG_ASLIFT);
    liftStack();

    convertRealToReal34ResultRegister(SIGMA_XMIN, REGISTER_X);
    convertRealToReal34ResultRegister(SIGMA_YMIN, REGISTER_Y);

    temporaryInformation = TI_XMIN_YMIN;
  }
}


void fnXmax(uint16_t unusedButMandatoryParameter) {
  if(checkMinimumDataPoints(const_1)) {
    liftStack();
    setSystemFlag(FLAG_ASLIFT);
    liftStack();

    convertRealToReal34ResultRegister(SIGMA_XMAX, REGISTER_X);
    convertRealToReal34ResultRegister(SIGMA_YMAX, REGISTER_Y);

    temporaryInformation = TI_XMAX_YMAX;
  }
}


void fnRangeXY(uint16_t unusedButMandatoryParameter) {
  real_t t;

  if(checkMinimumDataPoints(const_1)) {
    liftStack();
    setSystemFlag(FLAG_ASLIFT);
    liftStack();

    realSubtract(SIGMA_XMAX, SIGMA_XMIN, &t, &ctxtReal39);
    convertRealToReal34ResultRegister(&t, REGISTER_X);

    realSubtract(SIGMA_YMAX, SIGMA_YMIN, &t, &ctxtReal39);
    convertRealToReal34ResultRegister(&t, REGISTER_Y);

    temporaryInformation = TI_RANGEX_RANGEY;
  }
}


//----------- Histogram Section -----------------


#if !defined(TESTSUITE_BUILD)
  static bool_t isHistoMatrix(uint16_t *rows, char *mx) {
    *rows = 0;
    calcRegister_t regHisto = findNamedVariable(mx);
    if(regHisto == INVALID_VARIABLE) {
      return false;
    }
    else {
      if(getRegisterDataType(regHisto) != dtReal34Matrix) {
        return false;}
      else
      {
        real34Matrix_t histo;
        linkToRealMatrixRegister(regHisto, &histo);
        *rows = histo.header.matrixRows;
        if(histo.header.matrixColumns != 2) {
          return false;
        }
      }
    }
    return true;
  }


  static void initHistoMatrix(real_t *s) {
    uint16_t rows = 0, cols;
    calcRegister_t regHisto = findNamedVariable("HISTO");
    if(!isHistoMatrix(&rows,"HISTO")) {
      regHisto = allocateNamedMatrix("HISTO", 1, 2);
      real34Matrix_t histo;
      linkToRealMatrixRegister(regHisto, &histo);
      //realMatrixInit(&histo, 1, 2);
      //printf("Initialising HISTO\n");
    }
    else {
      if(appendRowAtMatrixRegister(regHisto)) {
      }
      else {
        regHisto = INVALID_VARIABLE;
      }
    }
    if(regHisto != INVALID_VARIABLE) {
      real34Matrix_t histo;
      linkToRealMatrixRegister(regHisto, &histo);
      rows = histo.header.matrixRows;
      cols = histo.header.matrixColumns;
      realToReal34(s,       &histo.matrixElements[(rows-1) * cols    ]);
      realToReal34(const_0, &histo.matrixElements[(rows-1) * cols + 1]);
      //printf(">>>>>HISTO rows=%d  cols=%d  ",rows, cols);
      //printReal34ToConsole(&histo.matrixElements[(rows-1) * cols    ],"X:","  ");
      //printReal34ToConsole(&histo.matrixElements[(rows-1) * cols +1 ],"Y:","  \n");
    }
    else {
      displayCalcErrorMessage(ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "additional matrix line not added; rows = %i",rows);
        moreInfoOnError("In function initHistoMatrix:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }
#endif //!defined(TESTSUITE_BUILD)


static void convertStatsMatrixToHistoMatrix(uint16_t statsVariableToHistogram);

void fnSetLoBin(uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
    if(histElementXorY == -1) {
      return;
    }
    if(getRegisterDataType(REGISTER_X) == dtLongInteger) {
      convertLongIntegerRegisterToReal34(REGISTER_X, &loBinR);
      convertStatsMatrixToHistoMatrix(histElementXorY == 1 ? ITM_Y : histElementXorY == 0 ? ITM_X : -1);
    }
    else {
      if(getRegisterDataType(REGISTER_X) == dtReal34) {
        real34Copy(REGISTER_REAL34_DATA(REGISTER_X), &loBinR);
        convertStatsMatrixToHistoMatrix(histElementXorY == 1 ? ITM_Y : histElementXorY == 0 ? ITM_X : -1);
      }
      else {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        #if defined(PC_BUILD)
        sprintf(errorMessage, "DataType %" PRIu32, getRegisterDataType(REGISTER_X));
        moreInfoOnError("In function fnSetLoBin:", errorMessage, "is not a long integer or real.", "");
        #endif // PC_BUILD
      }
    }
  #endif //!defined(TESTSUITE_BUILD)
}

static void convertStatsMatrixToHistoMatrix(uint16_t statsVariableToHistogram);

void fnSetHiBin(uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
    if(histElementXorY == -1) {
      return;
    }
    if(getRegisterDataType(REGISTER_X) == dtLongInteger) {
      convertLongIntegerRegisterToReal34(REGISTER_X, &hiBinR);
      convertStatsMatrixToHistoMatrix(histElementXorY == 1 ? ITM_Y : histElementXorY == 0 ? ITM_X : -1);
    }
    else {
      if(getRegisterDataType(REGISTER_X) == dtReal34) {
        real34Copy(REGISTER_REAL34_DATA(REGISTER_X), &hiBinR);
        convertStatsMatrixToHistoMatrix(histElementXorY == 1 ? ITM_Y : histElementXorY == 0 ? ITM_X : -1);
      }
      else {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        #if defined(PC_BUILD)
        sprintf(errorMessage, "DataType %" PRIu32, getRegisterDataType(REGISTER_X));
        moreInfoOnError("In function fnSetHiBin:", errorMessage, "is not a long integer or real.", "");
        #endif // PC_BUILD
      }
    }
  #endif //!defined(TESTSUITE_BUILD)
}


void fnSetNBins(uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
    if(histElementXorY == -1) {
      return;
    }
    if(getRegisterDataType(REGISTER_X) == dtLongInteger) {
      convertLongIntegerRegisterToReal34(REGISTER_X, &nBins);
      convertStatsMatrixToHistoMatrix(histElementXorY == 1 ? ITM_Y : histElementXorY == 0 ? ITM_X : -1);
    }
    else {
      if(getRegisterDataType(REGISTER_X) == dtReal34) {
        real34Copy(REGISTER_REAL34_DATA(REGISTER_X), &nBins);
        convertStatsMatrixToHistoMatrix(histElementXorY == 1 ? ITM_Y : histElementXorY == 0 ? ITM_X : -1);
      }
      else {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        #if defined(PC_BUILD)
        sprintf(errorMessage, "DataType %" PRIu32, getRegisterDataType(REGISTER_X));
        moreInfoOnError("In function fnSetNBins:", errorMessage, "is not a long integer or real.", "");
        #endif // PC_BUILD
      }
    }
  #endif //!defined(TESTSUITE_BUILD)
}



void fnConvertStatsToHisto(uint16_t statsVariableToHistogram) {
    uint16_t rows;
    real_t lb, hb, nb, nn;

    if(statMx[0]=='S' && isStatsMatrix(&rows,statMx)) {
      if(checkMinimumDataPoints(const_3)) {
        if(statsVariableToHistogram == ITM_Y) {
          realToReal34(SIGMA_YMIN, &loBinR);                                     //set up the user variables from auto estimates from the data
          realToReal34(SIGMA_YMAX, &hiBinR);                                     //set up the user variables from auto estimates from the data
          histElementXorY = 1;
        } else if(statsVariableToHistogram == ITM_X) {
          realToReal34(SIGMA_XMIN, &loBinR);                                     //set up the user variables from auto estimates from the data
          realToReal34(SIGMA_XMAX, &hiBinR);                                     //set up the user variables from auto estimates from the data
          histElementXorY = 0;
        }
        else {
          return;
        }

      real34ToReal(&loBinR, &lb);
      real34ToReal(&hiBinR, &hb);
      realCopy(SIGMA_N, &nn);
      realSquareRoot(&nn,&nb,&ctxtReal39);
      realToIntegralValue(&nb, &nb, DEC_ROUND_CEILING, &ctxtReal39);  //number of bins are defaulted to square root of data points  nb = CEIL (sqrt(SIGMA_N))
      realToReal34(&nb, &nBins);                                      //set up the user variables from auto estimates from the data

        convertStatsMatrixToHistoMatrix(statsVariableToHistogram);
      }
    }
    else {
      displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "Wrong statistical matrix is selected: %s!", statMx);
        moreInfoOnError("In function convertStatsMatrixToHistoMatrix:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }

}

//#define HISTDEBUG

//Histogram bin limits are:
// data points larger than loBinR (inclusive) and smaller than hiBinR (exclusive), except the right most bin right hand limit is inclusive)
static void convertStatsMatrixToHistoMatrix(uint16_t statsVariableToHistogram) {
  #if !defined(TESTSUITE_BUILD)
    real_t ii, lb, hb, nb, bw, bwon2;
    uint16_t i = 0;
    uint16_t j = 0;

    if(!checkMinimumDataPoints(const_3)) {
      return;
    }
    if(statMx[0]!='S') {
      displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "Wrong statistical matrix is selected: %s!", statMx);
        moreInfoOnError("In function convertStatsMatrixToHistoMatrix:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }

    calcRegister_t regStats = findNamedVariable(statMx);              //connect to STATS matrix
    calcRegister_t regHisto = fnClHisto(false);                       //clear and connect to HISTO matrix

    if(isStatsMatrix(&i, statMx) && regStats != INVALID_VARIABLE && regHisto != INVALID_VARIABLE) {

      real34ToReal(&loBinR, &lb);
      real34ToReal(&hiBinR, &hb);
      real34ToReal(&nBins , &nb);
      int32_t NN = real34ToInt32(&nBins);
      realSubtract(&hb, &lb, &bw, &ctxtReal39);
      realDivide(&bw, &nb, &bw, &ctxtReal39);
      realMultiply(&bw, const_1on2, &bwon2, &ctxtReal39);                  //calculate bin width bw and half bin width bw_on_2

      real34Matrix_t stats;
      real34Matrix_t histo;
      linkToRealMatrixRegister(regStats, &stats);
      const uint16_t rows = stats.header.matrixRows, cols = stats.header.matrixColumns;
      if(cols == 2) {

        for(i = 0; i < NN; i++) {
          int32ToReal(i, &ii);
          realAdd(&ii, const_1on2, &ii, &ctxtReal39);
          realMultiply(&ii, &bw, &ii, &ctxtReal39);
          realAdd(&ii, &lb, &ii, &ctxtReal39);                      //bin midpoint
          //printRealToConsole(&ii,"midpoint "," \n");
          initHistoMatrix(&ii);                                     // Set up all x-mid-points of the bins in HISTO, with 0 in y
          linkToRealMatrixRegister(regHisto, &histo);
          //#if defined(PC_BUILD)
          //  printf("Histo Matrix init: %d ",i);
          //  printReal34ToConsole(&histo.matrixElements[(i) * histo.header.matrixColumns    ],"X:","  ");
          //  printReal34ToConsole(&histo.matrixElements[(i) * histo.header.matrixColumns +1 ],"Y:","  \n");
          //#endif // PC_BUILD
        }

        if(isStatsMatrix(&i, statMx) && isHistoMatrix(&i, "HISTO")) {
          for(i = 0; i < rows; i++) {
            //printf("n=%d ^^^^ i=%d ",n,i);
            for(j = 0; j < NN; j++) {
              real_t t, tl, th;
              real34ToReal(&stats.matrixElements[i * cols + histElementXorY], &t);  //from X or Y, depending
              real34ToReal(&histo.matrixElements[j * histo.header.matrixColumns    ], &tl); //get the bin mid x
              //#if defined(PC_BUILD)
              //  printf("Histo Matrix recalled: %d\n",i);
              //  printReal34ToConsole(&histo.matrixElements[j * histo.header.matrixColumns      ],"HISTO(col1):"," ");
              //  printReal34ToConsole(&histo.matrixElements[j * histo.header.matrixColumns + 1  ],"HISTO(col2):","  \n");
              //#endif // PC_BUILD
              realSubtract(&tl, &bwon2, &tl, &ctxtReal39);   //get the bin x low
              realAdd     (&tl, &bw   , &th, &ctxtReal39);   //get the bin x hi
              //#if defined(PC_BUILD)
              //  printRealToConsole(&tl,"low:","  ");
              //  printRealToConsole(&t,"t (midpoint):","  ");
              //  printRealToConsole(&th,"hi:","\n");
              //#endif // PC_BUILD
              if( (j <  NN - 1 && realCompareLessThan(&t, &th) && realCompareGreaterEqual(&t, &tl)) ||
                  (j == NN - 1 && realCompareLessEqual(&t, &th) && realCompareGreaterEqual(&t, &tl)) )  {
                real34Add(&histo.matrixElements[j * histo.header.matrixColumns + 1], const34_1, &histo.matrixElements[j * histo.header.matrixColumns + 1]);
                #if defined(PC_BUILD) && defined(HISTDEBUG)
                  printf("Stats element %d in bin no %d, lying between: ",i,j);
                  printRealToConsole(&tl,"low (inclusive):"," and ");
                  if(j == NN - 1) {
                    printRealToConsole(&th,"hi (inclusive):","\n");
                  }
                  else {
                    printRealToConsole(&th,"hi (exclusive):","\n");
                  }
                #endif // PC_BUILD && HISTDEBUG
                break;
              }
            }
          }
          //#if defined(PC_BUILD)
          //  for(i = 0; i < NN; i++) {
          //    printf("Histo Matrix populated: %d ",i);
          //    printReal34ToConsole(&histo.matrixElements[(i) * histo.header.matrixColumns    ],"X:","  ");
          //    printReal34ToConsole(&histo.matrixElements[(i) * histo.header.matrixColumns +1 ],"Y:","  \n");
          //  }
          //#endif // PC_BUILD
        }

        liftStack();
        liftStack();
        liftStack();
        reallocateRegister(REGISTER_Z, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
        convertRealToReal34ResultRegister(&nb, REGISTER_Z);
        reallocateRegister(REGISTER_Y, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
        convertRealToReal34ResultRegister(&lb, REGISTER_Y);
        reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
        convertRealToReal34ResultRegister(&hb, REGISTER_X);
        temporaryInformation = TI_STATISTIC_HISTO;
      }
      else {
        displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
        #if(EXTRA_INFO_ON_CALC_ERROR == 1)
          sprintf(errorMessage, " Matrix columns not right: %s!", statMx);
          moreInfoOnError("In function convertStatsMatrixToHistoMatrix:", errorMessage, NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        return;
      }
    }
    else {
        displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
        #if(EXTRA_INFO_ON_CALC_ERROR == 1)
          sprintf(errorMessage, " invalid STATS or HISTO variable!");
          moreInfoOnError("In function convertStatsMatrixToHistoMatrix:", errorMessage, NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        return;
    }
  #endif // !TESTSUITE_BUILD
}
