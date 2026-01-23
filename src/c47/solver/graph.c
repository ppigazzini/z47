// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors


/********************************************//** //JM
 * \file graph.c Graphing module
 ***********************************************/

#include "c47.h"

#if defined(PC_BUILD)
  //Verbose directives can be simulataneously selected
  // #define VERBOSE_SOLVER00   // minimal text
  // #define VERBOSE_SOLVER0  // a lot less text
  // #define VERBOSE_SOLVER1  // a lot less text
  // #define VERBOSE_SOLVER2  // verbose a lot
#else // !PC_BUILD
  #undef VERBOSE_SOLVER00
  #undef VERBOSE_SOLVER0
  #undef VERBOSE_SOLVER1
  #undef VERBOSE_SOLVER2
  #undef STATDEBUG
  #undef GRAPHDEBUG
#endif // PC_BUILD


//Todo: involve https://en.wikipedia.org/wiki/Brent%27s_method#Brent's_method

#define COMPLEXKICKER true       //flag to allow conversion to complex plane if no convergenge found
#define CHANGE_TO_MOD_SECANT 0   //at iteration nn go to the modified secant method. 0 means immediately
#define CONVERGE_FACTOR 1.0f     //
#define NUMBERITERATIONS 9999    // 35 // Must be smaller than LIM (see STATS)

typedef struct {
      real_t Real;
      real_t Imag;
} cplx_t;

#define ctxtSolver2 &ctxtReal39
#define CPLX(x) &(x).Real, &(x).Imag 


#if !defined(TESTSUITE_BUILD)
  static void fnPlot(uint16_t unusedButMandatoryParameter) {
      lastPlotMode = PLOT_NOTHING;
      strcpy(plotStatMx, "DrwMX");
      PLOT_SHADE = true;
      fnPlotSQ(0);
      //  C47 advanced plot ^^
  }


  #if !defined(SAVE_SPACE_DM42_13GRF)
    static void initialize_function(void){
      if(graphVariabl1 > 0) {
        #if defined(PC_BUILD)
          //printf(">>> graphVariable = %i\n", graphVariable);
          if(lastErrorCode != 0) {
            #if defined(VERBOSE_SOLVER00)
            printf("ERROR CODE in initialize_functionA: %u\n",lastErrorCode);
            #endif // VERBOSE_SOLVER00
            lastErrorCode = 0;
          }
        #endif //PC_BUILD
      }
      else {
        #if defined(PC_BUILD)
          //printf(">>> graphVariable = %i\n", graphVariable);
          #if defined(VERBOSE_SOLVER00)
            printf("ERROR CODE in initialize_functionB: %u\n",lastErrorCode);
          #endif // VERBOSE_SOLVER00
        #endif //PC_BUILD
      }
    }
  #endif // !SAVE_SPACE_DM42_13GRF


  static void execute_rpn_function(void){
    if(graphVariabl1 <= 0 || graphVariabl1 > LAST_LABEL) {
      #if defined(PC_BUILD) //PC_BUILD
        printf("Error: No graph variable %u\n",graphVariabl1);
      #endif //PC_BUILD
      return;
    }

    calcRegister_t regStats = graphVariabl1;
    if(regStats != INVALID_VARIABLE) {
      fnStore(regStats);                  //place X register into x
                                    #if defined(PC_BUILD) //PC_BUILD
                                      printf("Graph variable x=%u: ",graphVariabl1);
                                      printRegisterToConsole(graphVariabl1, " = ","\n");
                                    #endif //PC_BUILD

      parseEquation(currentFormula, EQUATION_PARSER_XEQ, tmpString, tmpString + AIM_BUFFER_LENGTH);
      adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);

                                    #if defined(PC_BUILD) //PC_BUILD
                                      printf("Graph variable y ");
                                      printRegisterToConsole(REGISTER_X, " = ","\n");
                                    #endif //PC_BUILD

                                    #if defined(PC_BUILD)
                                      if(lastErrorCode != 0) {
                                        #if defined(VERBOSE_SOLVER00)
                                        printf("ERROR CODE in execute_rpn_function: %u\n",lastErrorCode);
                                        #endif // VERBOSE_SOLVER00
                                        lastErrorCode = 0;
                                      }
                                    #endif // PC_BUILD
      fnRCL(regStats);

                                    #if defined(VERBOSE_SOLVER0) && defined(PC_BUILD)
                                      printRegisterToConsole(REGISTER_X,">>> Calc x=","");
                                      printRegisterToConsole(REGISTER_Y," y=","");
                                    #endif // VERBOSE_SOLVER0 && PC_BUILD

                                    if (ENABLE_COMPLEXSOLVER_FILE_OUTPUT == 2) {
                                      copySourceRegisterToDestRegister(REGISTER_X,REGISTER_J);
                                      copySourceRegisterToDestRegister(REGISTER_Y,REGISTER_K);
                                      fnP_All_Regs(PRN_XYr);
                                      copySourceRegisterToDestRegister(REGISTER_J,REGISTER_X);
                                      copySourceRegisterToDestRegister(REGISTER_K,REGISTER_Y);
                                    }

    }
    else {
      #if defined(PC_BUILD)
        #if defined(VERBOSE_SOLVER00)
        printf("ERROR in execute_rpn_function; invalid variable: %u\n",lastErrorCode);
        #endif // VERBOSE_SOLVER00
        lastErrorCode = 0;
      #endif
    }
  }

  #if !defined(SAVE_SPACE_DM42_13GRF)
  static bool_t complexIsLowerThanTol(const real_t *re, const real_t *im, const real_t *tol) {
        return ((realIsZero(re) && realIsZero(im)) || (realCompareAbsLessThan(re, tol) && realCompareAbsLessThan(im, tol)));
  }


  #define ADD_RAN true
  static void divFunctionComplex(const real_t *a_re, const real_t *a_im, const real_t *b_re, const real_t *b_im, real_t *res_re, real_t *res_im, bool_t addRandom, real_t *tol) {
      if(  (realIsZero(a_re) && realIsZero(a_im)) || realIsNaN(a_re) || realIsNaN(a_im) || realIsNaN(b_re) || realIsNaN(b_im)) {
        realCopy(const_0, res_re);
        realCopy(const_0, res_im);
        return;
      }
      if(!addRandom && (realIsZero(b_re) && realIsZero(b_im))) {
        stringToReal("1E30", res_re, ctxtSolver2);
        realCopy(const_0, res_im);
        return;
      }
      if(addRandom && complexIsLowerThanTol(b_re, b_im, tol)) {
          #if defined(PC_BUILD)
          printf(">>> ADD random number to denominator to prevent infinite result\n");
          #endif // PC_BUILD
        real_t temp0, temp1;
        stringToReal("1E-6", &temp0, ctxtSolver2);
        realRandomU01(&temp1);
        realAdd(&temp0, &temp1, &temp0, ctxtSolver2);
        realAdd(&temp0, b_re, &temp0, ctxtSolver2);
        divComplexComplex(a_re, a_im, &temp0, const_0, res_re, res_im, ctxtSolver2);
        return;
      }
      divComplexComplex(a_re, a_im, b_re, b_im, res_re, res_im, ctxtSolver2);
    }
  #endif // !SAVE_SPACE_DM42_13GRF


  int16_t osc = 0;
  uint8_t DXR = 0, DYR = 0, DXI = 0, DYI = 0;

  void check_osc(uint8_t ii){
    switch(ii & 0b00111111) {
      case 0b001111:
      case 0b011110:
      case 0b111100:
      case 0b010101:
      case 0b101010:
      case 0b011011:
      case 0b110110:
      case 0b101101:
        osc++;
        break;
      default: ;
    }
    switch(ii) {
      case 0b01001001:
      case 0b10010010:
      case 0b00100100:
        osc++;
        break;
      default: ;
    }
  }


//###################################################################################
//PLOTTER
  int32_t drawMxN(void){
    uint16_t rows = 0;
    if(plotStatMx[0]!='D') {
      return 0;
    }
    calcRegister_t regStats = findNamedVariable(plotStatMx);
    if(regStats == INVALID_VARIABLE) {
      return 0;
    }
    if(isStatsMatrix(&rows,plotStatMx)) {
      real34Matrix_t stats;
      linkToRealMatrixRegister(regStats, &stats);
      return stats.header.matrixRows;
    }
    else {
      return 0;
    }
  }
#endif // !TESTSUITE_BUILD


  void fnClDrawMx(uint8_t origin) {
                                  #ifdef STATDEBUG
                                    printf("Clearing Draw Matrix, from %d\n",origin);
                                  #endif //STATDEBUG
    PLOT_ZOOM = 0;
    calcRegister_t regStats = findNamedVariable("DrwMX");
    if(regStats != INVALID_VARIABLE) {
      fnDeleteVariable(regStats);
    };
  }


#if !defined(TESTSUITE_BUILD)
  static void AddtoDrawMx() {
    real_t x, y;
    uint16_t rows = 0, cols;
                                  #ifdef STATDEBUG
                                    char prefix[100];
                                    memcpy(prefix, allNamedVariables[regStatsXY - FIRST_NAMED_VARIABLE].variableName + 1, allNamedVariables[regStatsXY - FIRST_NAMED_VARIABLE].variableName[0]);
                                    strcpy(prefix + allNamedVariables[regStatsXY - FIRST_NAMED_VARIABLE].variableName[0], " :");
                                    printf("Adding to Draw Matrix %s\n",prefix);
                                  #endif //STATDEBUG
    calcRegister_t regStats = regStatsXY;
    if(!isStatsMatrixN(&rows,regStats)) {
      regStats = allocateNamedMatrix(plotStatMx, 1, 2);
      regStatsXY = regStats;
      real34Matrix_t stats;
      linkToRealMatrixRegister(regStats, &stats);
      realMatrixInit(&stats,1,2);
    }
    else {
      if(appendRowAtMatrixRegister(regStats)) {
      }
      else {
        regStats = INVALID_VARIABLE;
      }
    }
    if(regStats != INVALID_VARIABLE) {

    real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
    real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);

      real34Matrix_t stats;
      linkToRealMatrixRegister(regStats, &stats);
      rows = stats.header.matrixRows;
      cols = stats.header.matrixColumns;
      realToReal34(&x, &stats.matrixElements[(rows-1) * cols    ]);
      realToReal34(&y, &stats.matrixElements[(rows-1) * cols + 1]);

                                  #ifdef STATDEBUG
                                    printf("[r,c] [%u,%u]=",rows,cols);
                                    printRealToConsole(&x,"x:="," ");
                                    printRealToConsole(&y,"y:=","\n");
                                  #endif //STATDEBUG
    }
    else {
      displayCalcErrorMessage(ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "additional matrix line not added; rows = %i",rows);
        moreInfoOnError("In function AddtoDrawMx:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }
#endif // !TESTSUITE_BUILD





//******************************************************************************************************************************


typedef struct {
  double x, y;
  double grad;
  bool_t stored;
} PlotPoint;

#define SS1 1.8                       // 1.4 grad2/grad2 threshold for 50% dx
#define SS2 2.4                       // 2   grad2/grad2 threshold for jumping back
#define FINE 9                        // (was 20) number of steps to jump
#define JMP 0.8                       // Jump back: 9 x 0.2 (was 20 x 0.1) : -0.8 -0.6 -0.4 -0.2 0 0.2 0.4 0.6 0.8, i.e. 9 steps back for discontinuity (0.9)
#define dJMP 0.2                      // Fine movement in p.u. ddx
#define STEP_OFFSET 0.99999           // Stay off exact integers
#define MIN_IMPROVEMENT_RATIO 1.25    // Minimum improvement needed to justify high-res
#define HIGH_RES_SAMPLE_COUNT 3       // Number of high-res points to evaluate
#define REVERT_THRESHOLD 0.8          // When to revert to previous dx


bool_t validateDiscontinuityResolution(PlotPoint *buffer, int count, double yBefore, double yAfter, double discontinuityThreshold) {
  #ifdef GRAPHDEBUG
    printf("\nVALIDATING DISCONTINUITY RESOLUTION:");
    printf("\n  Points: %d, yBefore=%.6f, yAfter=%.6f, threshold=%.6f\n", count, yBefore, yAfter, discontinuityThreshold);
  #endif

  if(count < 3) {
    #ifdef GRAPHDEBUG
      printf("  INVALID: Not enough points\n");
    #endif
    return false;
  }

  // Check if the fine-stepped points show smooth transition
  double maxJump = 0;
  double totalVariation = 0;

  // Check continuity between consecutive fine points
  for(int i = 1; i < count; i++) {
    double jump = fabs(buffer[i].y - buffer[i-1].y);
    totalVariation += jump;
    if(jump > maxJump) maxJump = jump;
  }

  // Also check connection to endpoints
  double startJump = fabs(buffer[0].y - yBefore);
  double endJump = fabs(yAfter - buffer[count-1].y);

  if(startJump > maxJump) maxJump = startJump;
  if(endJump > maxJump) maxJump = endJump;

  // If the maximum jump in fine steps is still above threshold, discontinuity persists
  bool_t discontinuityResolved = (maxJump < discontinuityThreshold);

  // Additional check: fine points should show reasonable continuity
  double avgVariation = totalVariation / (count - 1);
  bool_t smoothTransition = (maxJump < 3.0 * avgVariation) || (maxJump < discontinuityThreshold * 0.5);

  #ifdef GRAPHDEBUG
    printf("  maxJump=%.6f, avgVariation=%.6f\n", maxJump, avgVariation);
    printf("  startJump=%.6f, endJump=%.6f\n", startJump, endJump);
    printf("  discontinuityResolved=%d, smoothTransition=%d\n", discontinuityResolved, smoothTransition);
  #endif
  return discontinuityResolved && smoothTransition;
}



double calculateNewStepSize(int discontinuityDetected, double grad1, double grad2, bool_t grad2IncreaseDetected, double dx0) {
  #ifdef GRAPHDEBUG
    printf("calculateNewStepSize: discontinuity=%d, grad1=%.6f, grad2=%.6f, increase=%d, dx0=%.6f\n", discontinuityDetected, grad1, grad2, grad2IncreaseDetected, dx0);
  #endif

  if(discontinuityDetected > 0 && discontinuityDetected <= FINE) {
    double newDx = dJMP * dx0;
    #ifdef GRAPHDEBUG
      printf("  -> Discontinuity mode: newDx=%.6f\n", newDx);
    #endif
    return newDx;
  } else

  if(grad2 == 0 || grad1 == 0) {
    #ifdef GRAPHDEBUG
      printf("  -> Zero gradient: keeping dx0=%.6f\n", dx0);
    #endif
    return dx0;
  } else

  if(grad2IncreaseDetected) {
    double ratio1 = grad2/grad1;
    double ratio2 = grad1/grad2;
    double newDx = dx0 * ((ratio1 > SS1 || ratio2 > SS1) ? 0.5 : 1.0);
    #ifdef GRAPHDEBUG
      printf("  -> Gradient increase: ratio1=%.3f, ratio2=%.3f, newDx=%.6f\n", ratio1, ratio2, newDx);
    #endif
    return newDx;
  } else {

    #ifdef GRAPHDEBUG
      printf("  -> No change: keeping dx0=%.6f\n", dx0);
    #endif
    return dx0;
  }
}



void enterHighResMode(bool_t *inHighResMode, int *highResCount, double *highResStartX, double *baselineCurvatureChange, double *cumulativeCurvatureChange, double x, double curvatureChange) {
  #ifdef GRAPHDEBUG
    printf("*** ENTERING HIGH-RES MODE at x=%.6f, curvatureChange=%.6f ***\n", x, curvatureChange);
  #endif
  *inHighResMode = true;
  *highResCount = 0;
  *highResStartX = x;
  *baselineCurvatureChange = curvatureChange;
  *cumulativeCurvatureChange = 0;
}



void commitHighResPointsInOrder(PlotPoint *buffer, int count) {
  #ifdef GRAPHDEBUG
    printf("*** COMMITTING %d HIGH-RES POINTS ***\n", count);
    for(int i = 0; i < count; i++) {
      printf("  Point %d: x=%.6f, y=%.6f, grad=%.6f, stored=%d\n",
             i, buffer[i].x, buffer[i].y, buffer[i].grad, buffer[i].stored);
    }
  #endif
  for(int i = 0; i < count; i++) {
    if(!buffer[i].stored) {
      #if !defined(TESTSUITE_BUILD)
        convertDoubleToReal34RegisterPush(buffer[i].x, REGISTER_X);
        execute_rpn_function();
        AddtoDrawMx();
        buffer[i].stored = true;
      #endif //TESTSUITE_BUILD
    }
  }
}



void abandonHighResMode(int *highResCount, bool_t *inHighResMode) {
  #ifdef GRAPHDEBUG
    printf("*** ABANDONING HIGH-RES MODE (discarding %d points) ***\n", *highResCount);
  #endif
  *highResCount = 0;
  *inHighResMode = false;
  // High-res points are simply discarded, not added to plot
}



void resetHighResTracking(int *highResCount, bool_t *inHighResMode, double *cumulativeCurvatureChange) {
  #ifdef GRAPHDEBUG
    printf("*** RESETTING HIGH-RES TRACKING ***\n");
  #endif
  *highResCount = 0;
  *inHighResMode = false;
  *cumulativeCurvatureChange = 0;
}



bool_t detectTrueDiscontinuity(double y0, double y1, double y2, double grad0, double grad1, double grad2, double yAvg, int count) {  // Distinguish between genuine discontinuities and normal peaks
  if(real34IsSpecial(REGISTER_REAL34_DATA(REGISTER_X)) ||
     ((getRegisterDataType(REGISTER_X) == dtComplex34) &&
      (real34IsSpecial(REGISTER_IMAG34_DATA(REGISTER_X))))) {
    return true;
  }
  if(count < 4) return false;

  bool_t extremeMagnitudeJump = (fabs(y2) > 100 * yAvg) && (fabs(y1) < 10 * yAvg);
  bool_t gradientDiscontinuity = false;
  if(grad0 != 0 && grad1 != 0 && grad2 != 0) {

    // Calculate expected gradient based on trend
    double expectedGrad = grad1 + (grad1 - grad0); // Linear extrapolation
    double gradientRatio = fabs(grad2) / (fabs(expectedGrad) + 1e-10);

    // Only flag if gradient changes by more than 50x AND the function values suggest discontinuity
    gradientDiscontinuity = (gradientRatio > 50) && (fabs(y2 - y1) > 20 * fabs(y1 - y0)) && (fabs(y2 - y1) > 5 * yAvg);
  }

  // Check for sign oscillation that indicates numerical instability not smooth peaks
  bool_t signOscillationInstability = false;
  if(count >= 6) {
    // Look for rapid alternating signs with increasing magnitude - indicates instability
    bool_t y0Pos = (y0 > 0), y1Pos = (y1 > 0), y2Pos = (y2 > 0);
    if(y0Pos != y1Pos && y1Pos != y2Pos) {
      // Alternating signs - check if magnitudes are increasing dramatically
      double mag0 = fabs(y0), mag1 = fabs(y1), mag2 = fabs(y2);
      signOscillationInstability = (mag2 > 5 * mag1) && (mag1 > 5 * mag0) && (mag2 > 10 * yAvg);
    }
  }

  #ifdef GRAPHDEBUG
    printf("discontinuity check: extreme=%d, gradient=%d, oscillation=%d\n", extremeMagnitudeJump, gradientDiscontinuity, signOscillationInstability);
    if(gradientDiscontinuity) {
      double expectedGrad = grad1 + (grad1 - grad0);
      double gradientRatio = fabs(grad2) / (fabs(expectedGrad) + 1e-10);
      printf("  gradient details: expected=%.6f, actual=%.6f, ratio=%.3f\n", expectedGrad, grad2, gradientRatio);
    }
  #endif
  return extremeMagnitudeJump || gradientDiscontinuity || signOscillationInstability;
}




// =============================================================================
// ASYMPTOTE DETECTION AND RENDERING HELPER FUNCTIONS
// =============================================================================

typedef struct {
  double x;           // x-coordinate of asymptote
  double gapWidth;    // width of the discontinuity gap
  bool_t hasPositive;   // approaches +infinity
  bool_t hasNegative;   // approaches -infinity
  double maxHeight;   // standard maximum height for rendering
} AsymptoteInfo;

#define MAX_ASYMPTOTES 10
#define ASYMPTOTE_HEIGHT_RATIO 0.8  // 80% of y-axis range
#define MIN_GAP_WIDTH_RATIO 0.001   // Minimum gap width as ratio of x-range
#define ASYMPTOTE_SAMPLE_POINTS 5   // Points to sample on each side

bool_t detectAndCharacterizeAsymptote(double xLeft, double yLeft, double xRight, double yRight, double xGap, double gapWidth, AsymptoteInfo *asymptote) {
  #if !defined(TESTSUITE_BUILD)

    #ifdef GRAPHDEBUG
      printf("Checking asymptote at x=%.6f, gap=%.6f\n", xGap, gapWidth);
      printf("  Left: x=%.6f, y=%.6f\n", xLeft, yLeft);
      printf("  Right: x=%.6f, y=%.6f\n", xRight, yRight);
    #endif

    // Check if gap is significant enough
    double xRange = x_max - x_min;
    if(gapWidth < MIN_GAP_WIDTH_RATIO * xRange) {
      #ifdef GRAPHDEBUG
        printf("  Gap too small: %.6f < %.6f\n", gapWidth, MIN_GAP_WIDTH_RATIO * xRange);
      #endif
      return false;
    }

    // Sample only 2 points on each side to minimize memory usage
    double leftMaxY = yLeft, rightMaxY = yRight;
    double leftMinY = yLeft, rightMinY = yRight;

    // Sample just 2 points on each side (minimal sampling)
    for(int i = 1; i <= 2; i++) {
      // Left side samples (approaching asymptote from left)
      double sampleX = xLeft + (xGap - xLeft) * (0.7 + 0.2 * i / 2);
      convertDoubleToReal34RegisterPush(sampleX, REGISTER_X);
      execute_rpn_function();

      // Skip if we get invalid results
      if(real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_Y)) ||
         real34IsNaN(REGISTER_REAL34_DATA(REGISTER_Y))) {
        continue;
      }

      double sampleY = convertRegisterToDouble(REGISTER_Y);
      if(sampleY > leftMaxY) leftMaxY = sampleY;
      if(sampleY < leftMinY) leftMinY = sampleY;

      // Right side samples (approaching asymptote from right)
      sampleX = xGap + (xRight - xGap) * (0.2 * i / 2);
      convertDoubleToReal34RegisterPush(sampleX, REGISTER_X);
      execute_rpn_function();

      if(real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_Y)) ||
         real34IsNaN(REGISTER_REAL34_DATA(REGISTER_Y))) {
        continue;
      }

      sampleY = convertRegisterToDouble(REGISTER_Y);
      if(sampleY > rightMaxY) rightMaxY = sampleY;
      if(sampleY < rightMinY) rightMinY = sampleY;
    }

    // Determine if we have a vertical asymptote based on extreme values
    double yRange = y_max - y_min;
    double extremeThreshold = yRange * 2.0; // Values beyond 2x the plot range

    bool_t leftGoesPositive = (leftMaxY > y_max + extremeThreshold);
    bool_t leftGoesNegative = (leftMinY < y_min - extremeThreshold);
    bool_t rightGoesPositive = (rightMaxY > y_max + extremeThreshold);
    bool_t rightGoesNegative = (rightMinY < y_min - extremeThreshold);

    // Must have extreme behavior on at least one side
    if(!(leftGoesPositive || leftGoesNegative || rightGoesPositive || rightGoesNegative)) {
      #ifdef GRAPHDEBUG
        printf("  No extreme behavior detected\n");
        printf("    Left: max=%.3f, min=%.3f (need >%.3f or <%.3f)\n",
               leftMaxY, leftMinY, y_max + extremeThreshold, y_min - extremeThreshold);
        printf("    Right: max=%.3f, min=%.3f\n", rightMaxY, rightMinY);
      #endif
      return false;
    }

    // Fill asymptote info
    asymptote->x = xGap;
    asymptote->gapWidth = gapWidth;
    asymptote->hasPositive = leftGoesPositive || rightGoesPositive;
    asymptote->hasNegative = leftGoesNegative || rightGoesNegative;
    asymptote->maxHeight = yRange * ASYMPTOTE_HEIGHT_RATIO;

    #ifdef GRAPHDEBUG
      printf("  ASYMPTOTE DETECTED at x=%.6f (memory efficient)\n", asymptote->x);
      printf("    Gap width: %.6f\n", asymptote->gapWidth);
      printf("    Goes positive: %d, negative: %d\n", asymptote->hasPositive, asymptote->hasNegative);
      printf("    Standard height: %.3f\n", asymptote->maxHeight);
    #endif

  #endif //TESTSUITE_BUILD
  return true;
}



typedef struct {
    double dx;
    double dy;
} PointOffset;

// Three possible templates for asymptotes
TO_QSPI const PointOffset asymptote_offsets_both[] = {
    { -1.0, -1.0 }, // (x - offset, -height)
    { -1.0,  1.0 }, // (x - offset, +height)
    {  1.0,  1.0 }  // (x + offset, +height)
};

TO_QSPI const PointOffset asymptote_offsets_positive[] = {
    { -1.0,  0.0 }, // (x - offset, 0)
    { -1.0,  1.0 }, // (x - offset, +height)
    {  1.0,  1.0 }  // (x + offset, +height)
};

TO_QSPI const PointOffset asymptote_offsets_negative[] = {
    { -1.0,  0.0 }, // (x - offset, 0)
    { -1.0, -1.0 }, // (x - offset, -height)
    {  1.0, -1.0 }  // (x + offset, -height)
};



void renderAsymptote(AsymptoteInfo *asymptote) {
  #if !defined(TESTSUITE_BUILD)
    double x_center = asymptote->x;
    double offset = 1e-3;  // Small x offset
    double asymptoteHeight = 10000.0;

    #ifdef GRAPHDEBUG
      printf("Rendering asymptote at x=%.6f with clean 3-point vertical sequence\n", x_center);
    #endif

    const PointOffset* offsets = NULL;

    if (asymptote->hasPositive && asymptote->hasNegative) {
        offsets = asymptote_offsets_both;
    } else if (asymptote->hasPositive) {
        offsets = asymptote_offsets_positive;
    } else if (asymptote->hasNegative) {
        offsets = asymptote_offsets_negative;
    }

    if (offsets) {
        for (int i = 0; i < 3; i++) {
            double x = x_center + offsets[i].dx * offset;
            double y = offsets[i].dy * ((offsets[i].dy == 0.0) ? 0.0 : asymptoteHeight);
            convertDoubleToReal34Register(x, REGISTER_X);
            convertDoubleToReal34Register(y, REGISTER_Y);
            AddtoDrawMx();
        }
    }
  #ifdef GRAPHDEBUG
    printf("Added 3 asymptote points in clean vertical sequence\n");
  #endif
  #endif //TESTSUITE_BUILD
}



bool_t detectTrueDiscontinuityWithAsymptote(double y0, double y1, double y2, double grad0, double grad1, double grad2, double yAvg, int count, double x0, double x1, double x2, AsymptoteInfo *asymptotes, int *asymptoteCount) {

  // If not a vertical asymptote, do discontinuity detection
  bool_t hasDiscontinuity = detectTrueDiscontinuity(y0, y1, y2, grad0, grad1, grad2, yAvg, count);

  if(hasDiscontinuity && count >= 4 && *asymptoteCount < MAX_ASYMPTOTES) {
    // Check if this discontinuity might be an asymptote using the detailed method
    double gapWidth = fabs(x2 - x0);
    double xGap = (x0 + x2) / 2.0;

    #ifdef GRAPHDEBUG
      printf("Checking complex discontinuity for asymptote: x0=%.6f, x1=%.6f, x2=%.6f\n", x0, x1, x2);
      printf("  Gap center: %.6f, width: %.6f\n", xGap, gapWidth);
    #endif

    AsymptoteInfo candidateAsymptote;

    if(detectAndCharacterizeAsymptote(x0, y0, x2, y2, xGap, gapWidth, &candidateAsymptote)) {
      // Store the asymptote
      asymptotes[*asymptoteCount] = candidateAsymptote;
      (*asymptoteCount)++;

      // Render the asymptote immediately
      renderAsymptote(&candidateAsymptote);

      #ifdef GRAPHDEBUG
        printf("Complex asymptote detected and rendered\n");
      #endif

      // Return false to prevent normal discontinuity handling
      return false;
    }
  }

  #ifdef GRAPHDEBUG
    if(hasDiscontinuity) {
      printf("Regular discontinuity detected, not an asymptote\n");
    }
  #endif

  return hasDiscontinuity;
}

// =============================================================================
// END OF ASYMPTOTE HELPER FUNCTIONS
// =============================================================================


#if !defined(TESTSUITE_BUILD)
  static void graph_eqn(uint16_t mode) {
    currentKeyCode = 255;
    calcMode = CM_GRAPH;
    saveForUndo();
    regStatsXY = findNamedVariable(plotStatMx);
    double x;
    double x01 = x_min;
    double y01 = 0;
    double y02 = 0;
    double y00 = 0; // Add y00 for improved discontinuity detection
    double dy;
    double dx0 = (x_max-x_min)/SCREEN_WIDTH_GRAPH*10;
    double dx = dx0;
    double grad2 = 1;
    double grad1 = 1;
    double grad0 = 1;
    double prevDx = dx0; // Track previous step size
    int16_t count = 0;
    int16_t ss0 = 0;
    int16_t ss1 = 0;
    int16_t ss2 = 0;
    uint8_t discontinuityDetected = 0;
    bool_t  grad2IncreaseDetected = false;
    double yAvg = 0.1;
    int loop = 0;
    bool_t jumpedBack = false;
    AsymptoteInfo asymptotes[MAX_ASYMPTOTES];
    int asymptoteCount = 0;

  #ifdef GRAPHDEBUG
    printf("\n=== GRAPH EQUATION DEBUG START ===\n");
    printf("Initial parameters: xMin=%.6f, xMax=%.6f, dx0=%.6f\n", x_min, x_max, dx0);
    printf("Screen width: %d, SS1=%.1f, SS2=%.1f\n", SCREEN_WIDTH_GRAPH, SS1, SS2);
  #endif

    if(graphVariabl1 < FIRST_NAMED_VARIABLE || graphVariabl1 > LAST_NAMED_VARIABLE) {
      regStatsXY = INVALID_VARIABLE;
      return;
    }

  #if defined (LOW_GRAPH_ACC)
    //Change to SDIGS digit operation for graphs;
    if(significantDigitsForEqnGraphs <= 6) {
      ctxtReal34.digits = significantDigitsForEqnGraphs;
      ctxtReal39.digits = significantDigitsForEqnGraphs+3;
      ctxtReal51.digits = significantDigitsForEqnGraphs+6;
      ctxtReal75.digits = significantDigitsForEqnGraphs+9;
    }
  #endif

    fillStackWithReal0();

    convertDoubleToReal34RegisterPush(x_max, REGISTER_X);
    execute_rpn_function();
    yAvg += 2 * fabs(convertRegisterToDouble(REGISTER_Y));

    if(mode == initDrwMx) {
      fnClDrawMx(3);
      strcpy(plotStatMx,"DrwMX");
      asymptoteCount = 0; // Reset asymptote tracking for new plot
    }
  #if defined(GRAPHDEBUG)
    printf("dx0=%f discontinuityDetected:%u grad2IncreaseDetected:%u\n",dx0, discontinuityDetected, grad2IncreaseDetected);
  #endif // GRAPHDEBUG

    //Main loop, default is 40 x 6 point gaps, across the 240 wide screen
    //  If the gradient is increasing, then the dx is reduced.
    //  That helps going forward, but not looking a the last sample which already jumped too far, so the next part steps back.
    PlotPoint highResBuffer[HIGH_RES_SAMPLE_COUNT];
    int highResCount = 0;
    bool_t inHighResMode = false;
    double highResStartX = 0;
    double cumulativeCurvatureChange = 0;
    double baselineCurvatureChange = 0;
    double savedXBeforeHighres = 0;
    double savedDxBeforeHighres = dx0;

    #ifdef GRAPHDEBUG
      int cnt = 0;
      int cycleCount = 0;
      double lastSignChange = x_min;
      int signChangeCount = 0;
    #endif //GRAPHDEBUG

    for(x = x_min; x <= x_max; x += STEP_OFFSET * dx) {
      #ifdef GRAPHDEBUG
        printf("\n###################################\n");
        printf("--- Iteration %d: x=%.6f, dx=%.6f ---\n", cnt, x, dx);
      #endif //GRAPHDEBUG

      jumpedBack = false;
      x = fmax(x_min, fmin(x_max, x));

      convertDoubleToReal34RegisterPush(x, REGISTER_X);
      execute_rpn_function();

      // Handle complex plotting
      if(getSystemFlag(FLAG_CPXPLOT)) {
        fnRCL(REGISTER_Y);
        fnStore(TEMP_REGISTER_1);
        fnImaginaryPart(0);
        fnRCL(TEMP_REGISTER_1);
        fnRealPart(0);
        AddtoDrawMx();
        continue;
      }

      y02 = convertRegisterToDouble(REGISTER_Y);

      #ifdef GRAPHDEBUG
        printf("y02=%.6f\n", y02);
      #endif

      // Calculate gradient and detect anomalies
      if(count > 0) {
        dy = y02 - y01;
        grad2 = (x != x01) ? dy / (x - x01) : 0.0;

        #ifdef GRAPHDEBUG
          printf("dy=%.6f, grad2=%.6f\n", dy, grad2);

          // Track sign changes for cycle detection
          if(count > 1) {
            bool_t currentPositive = (y02 > 0);
            bool_t lastPositive = (y01 > 0);
            if(currentPositive != lastPositive) {
              signChangeCount++;
              printf("[SIGN CHANGE #%d at x=%.6f, distance from last=%.6f]\n",
                     signChangeCount, x, x - lastSignChange);
              lastSignChange = x;
              if(signChangeCount % 2 == 0) {
                cycleCount++;
                printf("[HALF CYCLE #%d COMPLETE]\n", cycleCount);
              }
            }
          }
        #endif

        // Update sign states
        ss0 = ss1;
        ss1 = ss2;
        ss2 = grad2 == 0 ? 0 : grad2 > 0 ? 1 : -1;
        grad0 = grad1;
        grad1 = grad2;

        #ifdef GRAPHDEBUG
          printf("Signs: ss0=%d, ss1=%d, ss2=%d\n", ss0, ss1, ss2);
          printf("Grads: grad0=%.6f, grad1=%.6f, grad2=%.6f\n", grad0, grad1, grad2);
        #endif

        // Detect gradient anomalies using improved logic
        if(grad1 != 0 && grad2 != 0) {
          bool_t yRatioCheck1 = (fabs(y02/y01) > 1.01 && fabs(grad2/grad1) > SS2);
          bool_t yRatioCheck2 = (fabs(y01/y02) > 1.01 && fabs(grad1/grad2) > SS2);

          // Conservative oscillation detection - only flag if it's truly problematic
          bool_t signOscillation1 = (ss0 == 1  && ss1 == -1 && ss2 == 1) && (fabs(y02) > 2 * fabs(y01)) && (fabs(y00) > 2 * fabs(y01));
          bool_t signOscillation2 = (ss0 == -1 && ss1 == 1  && ss2 == -1) && (fabs(y02) > 2 * fabs(y01)) && (fabs(y00) > 2 * fabs(y01));

          // Zero crossing detection - only if accompanied by large gradient changes
          bool_t zeroCrossing1 = (ss1 == 1  && ss2 == -1  && y01 > 0 && y02 < 0) && (fabs(grad2 - grad1) > 10 * fabs(grad1 - grad0));
          bool_t zeroCrossing2 = (ss1 == -1 && ss2 == 1   && y01 < 0 && y02 > 0) && (fabs(grad2 - grad1) > 10 * fabs(grad1 - grad0));

          grad2IncreaseDetected = yRatioCheck1 || yRatioCheck2 || signOscillation1 || signOscillation2 || zeroCrossing1 || zeroCrossing2;

          #ifdef GRAPHDEBUG
            printf("Gradient increase checks:\n");
            printf("  yRatio1(%.3f>1.01 && %.3f>%.1f): %d\n", fabs(y02/y01), fabs(grad2/grad1), SS2, yRatioCheck1);
            printf("  yRatio2(%.3f>1.01 && %.3f>%.1f): %d\n", fabs(y01/y02), fabs(grad1/grad2), SS2, yRatioCheck2);
            printf("  signOsc1(%d,%d,%d): %d\n", ss0, ss1, ss2, signOscillation1);
            printf("  signOsc2(%d,%d,%d): %d\n", ss0, ss1, ss2, signOscillation2);
            printf("  zeroCross1(ss=%d->%d, y=%.3f->%.3f): %d\n", ss1, ss2, y01, y02, zeroCrossing1);
            printf("  zeroCross2(ss=%d->%d, y=%.3f->%.3f): %d\n", ss1, ss2, y01, y02, zeroCrossing2);
            printf("  => grad2IncreaseDetected: %d\n", grad2IncreaseDetected);
          #endif

        } else {
          grad2IncreaseDetected = false;
          #ifdef GRAPHDEBUG
            printf("Zero gradient detected, no increase flagged\n");
          #endif
        }

        // Update running average
        if(count == 0) {
          yAvg += 2 * fabs(y02);
        } else if(fabs(y02) > yAvg) {
          yAvg += fabs(y02) / count;
        }

        #ifdef GRAPHDEBUG
          printf("yAvg=%.6f\n", yAvg);
        #endif

        // Use improved discontinuity detection
        if(discontinuityDetected == 0) {
          double x00 = (count > 1) ? x01 - dx : x_min;
          bool_t trueDiscontinuity = detectTrueDiscontinuityWithAsymptote(y00, y01, y02, grad0, grad1, grad2, yAvg, count, x00, x01, x, asymptotes, &asymptoteCount);
          if(trueDiscontinuity) {
            discontinuityDetected = FINE;
            #ifdef GRAPHDEBUG
              printf("TRUE DISCONTINUITY DETECTED\n");
            #endif
          }
        }

        // Jump-back logic for discontinuities and gradient increases
        if((discontinuityDetected == FINE) || (discontinuityDetected == 0 && grad2IncreaseDetected)) {
          #ifdef GRAPHDEBUG
            printf("JUMPING BACK: discontinuity=%d, gradIncrease=%d\n", discontinuityDetected, grad2IncreaseDetected);
            printf("  Before jump: x=%.6f, y=%.6f\n", x, y02);
          #endif

          // If in high-res mode, abandon it since we're jumping back anyway
          if(inHighResMode) {
            abandonHighResMode(&highResCount, &inHighResMode);
          }

          // Store the current position and original discontinuity trigger
          double jumpBackStartX = x;
          double jumpBackStartY = y02;
          bool_t wasDiscontinuity = (discontinuityDetected == FINE);
          double discontinuityThreshold = wasDiscontinuity ? fabs(y02 - y01) * 0.1 : 0; // 10% of original jump

          x -= dx * JMP;
          jumpedBack = true;
          convertDoubleToReal34RegisterPush(x, REGISTER_X);
          execute_rpn_function();
          y02 = convertRegisterToDouble(REGISTER_Y);
          grad2 = (y02 - y01) / (x - x01);
          ss0 = ss1;
          ss1 = ss2;
          ss2 = grad2 == 0 ? 0 : grad2 > 0 ? 1 : -1;

          #ifdef GRAPHDEBUG
            printf("  After jump: x=%.6f, y=%.6f, newGrad=%.6f\n", x, y02, grad2);
            printf("  Will evaluate %d fine-step points\n", FINE);
            if(wasDiscontinuity) {
              printf("  Discontinuity threshold: %.6f\n", discontinuityThreshold);
            }
          #endif

          // Sample the fine-stepped points
          PlotPoint jumpBackBuffer[FINE];
          int jumpBackCount = 0;
          double jumpBackX = x;
          double jumpBackDx = dJMP * dx0;

          for(int jbStep = 0; jbStep < FINE && jumpBackX < jumpBackStartX; jbStep++) {
            convertDoubleToReal34RegisterPush(jumpBackX, REGISTER_X);
            execute_rpn_function();
            double jbY = convertRegisterToDouble(REGISTER_Y);

            jumpBackBuffer[jumpBackCount].x = jumpBackX;
            jumpBackBuffer[jumpBackCount].y = jbY;
            jumpBackBuffer[jumpBackCount].stored = false;
            jumpBackCount++;
            jumpBackX += jumpBackDx;
          }

          bool_t shouldCommitPoints = false;

          if(wasDiscontinuity) {
            // For discontinuity cases, validate that fine points actually resolve the discontinuity
            bool_t discontinuityResolved = validateDiscontinuityResolution(
              jumpBackBuffer, jumpBackCount, y01, jumpBackStartY, discontinuityThreshold);

            if(discontinuityResolved) {
              #ifdef GRAPHDEBUG
                printf("  DISCONTINUITY RESOLVED: committing fine points\n");
              #endif
              shouldCommitPoints = true;
              discontinuityDetected = 0; // Clear discontinuity flag
            } else {
              #ifdef GRAPHDEBUG
                printf("  DISCONTINUITY PERSISTS: abandoning fine points, but keeping original grid point\n");
              #endif
              discontinuityDetected = 0; // Clear flag
              shouldCommitPoints = false;
              // Don't skip the original grid point - restore to original position and let the normal flow handle plotting the original grid point
            }
          } else {
            // For gradient increase cases, evaluate if points add significant detail
            if(jumpBackCount >= 3) {
              // Calculate curvature variation in the jump-back region
              double maxCurvatureChange = 0;
              for(int i = 1; i < jumpBackCount - 1; i++) {
                double g1 = (jumpBackBuffer[i].y - jumpBackBuffer[i-1].y) / (jumpBackBuffer[i].x - jumpBackBuffer[i-1].x);
                double g2 = (jumpBackBuffer[i+1].y - jumpBackBuffer[i].y) / (jumpBackBuffer[i+1].x - jumpBackBuffer[i].x);
                double curvChange = fabs(g2 - g1);
                if(curvChange > maxCurvatureChange) {
                  maxCurvatureChange = curvChange;
                }
              }
              // Compare with linear interpolation
              double linearSlope = (jumpBackStartY - y01) / (jumpBackStartX - x01);
              double interpolationError = 0;
              for(int i = 0; i < jumpBackCount; i++) {
                double expectedY = y01 + linearSlope * (jumpBackBuffer[i].x - x01);
                double error = fabs(jumpBackBuffer[i].y - expectedY);
                if(error > interpolationError) {
                  interpolationError = error;
                }
              }
              // Points are useful if they show significant non-linear behavior
              bool_t jumpBackPointsUseful = (interpolationError > 0.1 * fabs(jumpBackStartY - y01)) || (maxCurvatureChange > fabs(linearSlope) * 0.5);

              #ifdef GRAPHDEBUG
                printf("  Gradient increase evaluation: maxCurv=%.6f, interpError=%.6f, useful=%d\n", maxCurvatureChange, interpolationError, jumpBackPointsUseful);
              #endif
              shouldCommitPoints = jumpBackPointsUseful;
            }
          }

          if(shouldCommitPoints) { // fine points
            #ifdef GRAPHDEBUG
              printf("  COMMITTING %d jump-back points\n", jumpBackCount);
            #endif
            for(int i = 0; i < jumpBackCount; i++) {
              convertDoubleToReal34RegisterPush(jumpBackBuffer[i].x, REGISTER_X);
              execute_rpn_function();
              AddtoDrawMx();
            }

            // Also plot the original grid point (jumpBackStartX, jumpBackStartY)
            convertDoubleToReal34RegisterPush(jumpBackStartX, REGISTER_X);
            execute_rpn_function();
            AddtoDrawMx();

            // Set position to continue from the original grid point
            x = jumpBackStartX;
            y02 = jumpBackStartY;
            dx = dx0; // Reset to original step size
            jumpedBack = false; // Clear flag since we've handled the plotting

            #ifdef GRAPHDEBUG
              printf("  Continuing from original grid point: x=%.6f, y=%.6f\n", x, y02);
            #endif

          } else {  // not fine points

            #ifdef GRAPHDEBUG
              printf("  DISCARDING %d jump-back points, but preserving original grid flow\n", jumpBackCount);
            #endif
            // Restore to the original grid point and continue normal processing, ensures original grid point gets plotted in the normal flow
            x = jumpBackStartX;
            y02 = jumpBackStartY;
            dx = dx0; // Revert to original step size
            jumpedBack = false; // Clear flag so the original point gets plotted normally

            // Recalculate gradient for the original point
            grad2 = (y02 - y01) / (x - x01);
            ss0 = ss1;
            ss1 = ss2;
            ss2 = grad2 == 0 ? 0 : grad2 > 0 ? 1 : -1;

            #ifdef GRAPHDEBUG
              printf("  Restored to original grid: x=%.6f, y=%.6f, grad=%.6f\n", x, y02, grad2);
              printf("  Original grid point will be plotted normally\n");
            #endif
          }
        }

        // Calculate curvature change for resolution assessment
        double curvatureChange = 0;
        if(count > 1 && grad0 != 0 && grad1 != 0) {
          curvatureChange = fabs((grad2 - grad1) - (grad1 - grad0));
          #ifdef GRAPHDEBUG
            printf("curvatureChange=%.6f = |(%f-%f)-(%f-%f)|\n", curvatureChange, grad2, grad1, grad1, grad0);
          #endif
        }

        // Determine new step size and resolution mode
        double newDx = calculateNewStepSize(discontinuityDetected, grad1, grad2, grad2IncreaseDetected, dx0);

        // Check if we're entering high-resolution mode (only if not jumped back) and only trigger high-res for genuine curvature issues, not discontinuity-related step reductions
        if(!jumpedBack && !inHighResMode && newDx < prevDx * REVERT_THRESHOLD &&
           discontinuityDetected == 0 && curvatureChange > 0) {
          savedXBeforeHighres = x01;  // Save the last good x position
          savedDxBeforeHighres = prevDx;

          #ifdef GRAPHDEBUG
            printf("HIGH-RES TRIGGER: newDx(%.6f) < prevDx(%.6f) * threshold(%.2f) = %.6f\n", newDx, prevDx, REVERT_THRESHOLD, prevDx * REVERT_THRESHOLD);
            printf("Curvature-based trigger: discontinuity=%d, curvatureChange=%.6f\n", discontinuityDetected, curvatureChange);
            printf("Saving state: x=%.6f, dx=%.6f, cycle=%d\n", savedXBeforeHighres, savedDxBeforeHighres, cycleCount);
          #endif

          enterHighResMode(&inHighResMode, &highResCount, &highResStartX, &baselineCurvatureChange, &cumulativeCurvatureChange, x, curvatureChange);
        }

          #ifdef GRAPHDEBUG
            else if(!jumpedBack && !inHighResMode && newDx < prevDx * REVERT_THRESHOLD) {
                 printf("HIGH-RES BLOCKED: newDx(%.6f) < threshold but discontinuity=%d or curvatureChange=%.6f\n", newDx, discontinuityDetected, curvatureChange);
            }
          #endif

        // If in high-res mode, buffer the point and assess improvement
        if(inHighResMode && !jumpedBack) {
          cumulativeCurvatureChange += curvatureChange;

          #ifdef GRAPHDEBUG
            printf("HIGH-RES MODE: count=%d/%d, cumCurv=%.6f, baseline=%.6f\n", highResCount, HIGH_RES_SAMPLE_COUNT, cumulativeCurvatureChange, baselineCurvatureChange);
          #endif

          if(highResCount < HIGH_RES_SAMPLE_COUNT) { // Buffer high-res points in order
            highResBuffer[highResCount].x = x;
            highResBuffer[highResCount].y = y02;
            highResBuffer[highResCount].grad = grad2;
            highResBuffer[highResCount].stored = false;
            highResCount++;
            #ifdef GRAPHDEBUG
              printf("  Buffered point %d: x=%.6f, y=%.6f\n", highResCount-1, x, y02);
            #endif
          } else {
            // Evaluate if high-res provided sufficient improvement
            double improvementRatio = (baselineCurvatureChange > 0) ? cumulativeCurvatureChange / (baselineCurvatureChange * HIGH_RES_SAMPLE_COUNT) : 1.0;

            #ifdef GRAPHDEBUG
              printf("EVALUATING HIGH-RES: improvementRatio=%.3f (need %.2f)\n", improvementRatio, MIN_IMPROVEMENT_RATIO);
              printf("  cumCurv=%.6f, baseline*count=%.6f\n", cumulativeCurvatureChange, baselineCurvatureChange * HIGH_RES_SAMPLE_COUNT);
            #endif

            if(improvementRatio >= MIN_IMPROVEMENT_RATIO) {            // High-res was beneficial, commit buffered points in sequence
              commitHighResPointsInOrder(highResBuffer, highResCount);
              resetHighResTracking(&highResCount, &inHighResMode, &cumulativeCurvatureChange);
              // Continue with current step size
            } else {                                                   // High-res didn't help, abandon and continue from last good point with larger dx
              #ifdef GRAPHDEBUG
                printf("HIGH-RES FAILED: reverting to x=%.6f, dx=%.6f\n", savedXBeforeHighres, savedDxBeforeHighres);
              #endif
              abandonHighResMode(&highResCount, &inHighResMode);
              x = savedXBeforeHighres + savedDxBeforeHighres;
              dx = savedDxBeforeHighres;
              // Don't set jumpedBack since we want to continue forward, just with larger steps
              continue; // Skip to next iteration with the adjusted x
            }
          }
        }

        prevDx = dx;
        dx = newDx;

        #ifdef GRAPHDEBUG
          printf("Step size: prevDx=%.6f -> dx=%.6f\n", prevDx, dx);
        #endif
      }

      // Add point to plot (skip if in high-res buffering mode or jumped back)
      if(!jumpedBack && dx >= 0 && !inHighResMode) {

        #ifdef GRAPHDEBUG
          printf("ADDING POINT TO PLOT: x=%.6f, y=%.6f\n", x, y02);
        #endif
        AddtoDrawMx();

      } else {
        #ifdef GRAPHDEBUG
          printf("SKIPPING PLOT: jumpedBack=%d, dx=%.6f, inHighRes=%d\n", jumpedBack, dx, inHighResMode);
        #endif
      }

      // Update state for next iteration
      if(count > 0) {
        grad1 = grad2;
      }
      y00 = y01; // Update y00 for improved discontinuity detection
      y01 = y02;
      x01 = x;

      if(discontinuityDetected != 0) discontinuityDetected--;

      count++;
      if(count > 60) break;

      loop++;
      if(checkHalfSec()) {
        progressHalfSecUpdate_Integer(timed, "Iter: ",loop, halfSec_clearZ, halfSec_clearT, halfSec_disp); //timed
      }

      #if defined(DMCP_BUILD)
        if(exitKeyWaiting()) {
          progressHalfSecUpdate_Integer(force+1, "Interrupted Iter:",loop, halfSec_clearZ, halfSec_clearT, halfSec_disp);
          fnClearStack(0);
          calcMode = CM_NORMAL;
          screenUpdatingMode = SCRUPD_AUTO;
          screenUpdatingMode |= SCRUPD_SKIP_STATUSBAR_ONE_TIME;
          break;
        }
      #endif //DMCP_BUILD

      #ifdef GRAPHDEBUG
        cnt++;
      #endif //GRAPHDEBUG
    }

    #ifdef GRAPHDEBUG
      printf("\n=== GRAPH EQUATION DEBUG END ===\n");
      printf("Total iterations: %d\n", cnt);
      printf("Total sign changes: %d\n", signChangeCount);
      printf("Total half cycles: %d\n", cycleCount);
      printf("================================\n");
    #endif //GRAPHDEBUG

    if(inHighResMode && highResCount > 0) {
      abandonHighResMode(&highResCount, &inHighResMode);
    }

    #if defined (LOW_GRAPH_ACC)
      //Change to SDIGS digit operation for fresh stack;
      ctxtReal34.digits = 34; //Change back to normal operation for stack;
      ctxtReal39.digits = 39; //Change back to 39 digit operation for stack;
    #endif //LOW_GRAPH_ACC

    fillStackWithReal0();

    #if defined (LOW_GRAPH_ACC)
      //Change to SDIGS digit operation for screen graphs;
      if(significantDigitsForEqnGraphs <= 6) {
        ctxtReal34.digits = significantDigitsForScreen;
        ctxtReal39.digits = significantDigitsForScreen+3;
      }
    #endif //LOW_GRAPH_ACC

    if(!GRAPHMODE) { //Change over hourglass to the left side
      clearScreenOld(clrStatusBar, !clrRegisterLines, !clrSoftkeys);
    }
    calcMode = CM_GRAPH;
    hourGlassIconEnabled = true;       //clear the current portion of statusbar
    showHideHourGlass();
    refreshStatusBar();
    fnPlot(0);
    #if defined (LOW_GRAPH_ACC)
      //Change to normal operation for graphs;
      ctxtReal34.digits = 34;
      ctxtReal39.digits = 39;
      ctxtReal51.digits = 51;
      ctxtReal75.digits = 75;
    #endif //LOW_GRAPH_ACC

  }
#endif // !TESTSUITE_BUILD
//******************************************************************************************************************************



void graph_stat(uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
    saveForUndo();
    strcpy(plotStatMx,"STATS");

    if(statMxN()) {
      lastPlotMode = PLOT_NOTHING;
      calcMode = CM_GRAPH;
      reDraw = true;
      PLOT_SHADE = true;

      if(!getSystemFlag(FLAG_PLINE) && !getSystemFlag(FLAG_PCROS) && !getSystemFlag(FLAG_PBOX) && !getSystemFlag(FLAG_PPLUS)) {
        fnPline(NOPARAM);
      }

      fillStackWithReal0();
      fnPlotSQ(0);
    }
    else {
      calcMode = CM_NORMAL;
      displayCalcErrorMessage(ERROR_NO_SUMMATION_DATA, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "There is no statistical/plot data available!");
        moreInfoOnError("In function fnPlotStat:", errorMessage, NULL, NULL);
      #endif
    }
  #endif // !TESTSUITE_BUILD
}


// COMPLEX SOLVER

#if !defined(SAVE_SPACE_DM42_13GRF)
  #if !defined(TESTSUITE_BUILD)

  // =============================================================================
  // SOLVER HELPERS
  // =============================================================================

  #if !defined(TESTSUITE_BUILD)
  static bool_t check2RealZeroTol(const real_t *a, const real_t *b, const real_t *tol) {
    return (realIsZero(a) && realIsZero(b))
       || ((realCompareAbsLessThan(a, tol))
        && (realCompareAbsLessThan(b, tol)));
    }

  // static bool_t checkRegisterXYRealZeroTol(calcRegister_t tol) {
  //   return (real34IsZero(REGISTER_REAL34_DATA(REGISTER_X)) && real34IsZero(REGISTER_REAL34_DATA(REGISTER_Y)))
  //      || ((real34CompareAbsLessThan(REGISTER_REAL34_DATA(REGISTER_X), REGISTER_REAL34_DATA(tol)))
  //       && (real34CompareAbsLessThan(REGISTER_REAL34_DATA(REGISTER_Y), REGISTER_REAL34_DATA(tol))));
  //   }
  //
  // static bool_t checkRegisterXYImagZeroTol(calcRegister_t tol) {
  //   return (real34IsZero(REGISTER_IMAG34_DATA(REGISTER_X)) && real34IsZero(REGISTER_IMAG34_DATA(REGISTER_Y)))
  //      || ((real34CompareAbsLessThan(REGISTER_IMAG34_DATA(REGISTER_X), REGISTER_IMAG34_DATA(tol)))
  //       && (real34CompareAbsLessThan(REGISTER_IMAG34_DATA(REGISTER_Y), REGISTER_IMAG34_DATA(tol))));
  //   }
  //
  // static bool_t checkRegisterXYComplexAbsZeroTol(calcRegister_t tol) {
  //   if(getRegisterDataType(REGISTER_X) == dtComplex34 && getRegisterDataType(REGISTER_Y) == dtComplex34) {
  //     runFunction(ITM_MAGNITUDE);
  //     runFunction(ITM_XexY);
  //     runFunction(ITM_MAGNITUDE);
  //     runFunction(ITM_XexY);
  //   }
  //   return checkRegisterXYRealZeroTol(tol);
  //   }
  #endif // !TESTSUITE_BUILD

  // =============================================================================
  // END SOLVER HELPER FUNCTIONS
  // =============================================================================

  #if defined(PC_BUILD)
    static void printSolverResult(uint16_t iterationCounter, bool_t conjugates) {
      char str[200];
      real34ToString(REGISTER_REAL34_DATA(REGISTER_X), str);
      printf("\n\n\033[1m%2u: %-36s ", significantDigits, str);
      real34ToString(REGISTER_IMAG34_DATA(REGISTER_X), str);
      if(real34IsNegative(REGISTER_IMAG34_DATA(REGISTER_X))) {
        printf("- ix%-36s", str + 1);
      }
      else {
        printf("+ ix%-36s", str);
      }
      printf(" (iter:%2i conj:%u)\033[0m\n\n", iterationCounter, conjugates);
    }
  #else
    static inline void printSolverResult(uint16_t iterationCounter, bool_t conjugates) {}
  #endif // PC_BUILD


  // Solver Registers used and destroyed. This is documented.
  #define __STARTX0 81
  #define __STARTX1 82


#if defined(PC_BUILD)
  static void printComplexToConsole(const real_t *re, const real_t *im, const char *before, const char *after) {
    char str[100];
    realToString(re, str);
    printf("%s%s + ", before, str);
    realToString(im, str);
    printf("%si %s", str, after);
  }
#endif //PC_BUILD
  
  
static inline void copyComplex(const cplx_t *from, cplx_t *to) {
  realCopy(&from->Real, &to->Real);
  realCopy(&from->Imag, &to->Imag);  
}
  
  
  static void complexSolver() {         //Input parameters in registers SREG_STARTX0, SREG_STARTX1
    currentKeyCode = 255;
    if(graphVariabl1 <= 0 || graphVariabl1 > LAST_LABEL) {
#if defined(PC_BUILD) //PC_BUILD
      printf("Error: No complex solver variable %u\n",graphVariabl1);
#endif //PC_BUILD
      return;
    }

    calcMode = CM_NO_UNDO;
    
    calcRegister_t SREG_STARTX0 = __STARTX0;
    calcRegister_t SREG_STARTX1 = __STARTX1;

    runFunction(ITM_CLSTK);
    runFunction(ITM_RAD);
    clearSystemFlag(FLAG_SSIZE8);
    setSystemFlag(FLAG_CPXRES);
    int16_t oscillationIterationCounter;
    int16_t oscillations = 0;
    int16_t convergent = 0;
    int iterationCounter;
    bool_t checkNaN = false;
    bool_t checkzero = false;
    osc = 0;
    DXR = 0, DYR = 0, DXI = 0, DYI = 0;
    iterationCounter = 0; oscillationIterationCounter = 0;
    int16_t kicker = 0;
    

    real_t f;
    real_t term;
    real_t tol;
    
    cplx_t X0;
    cplx_t X1;
    cplx_t X2;
    cplx_t X2N;
    cplx_t dX;
    cplx_t Xold;

    cplx_t Y0;
    cplx_t Y1;
    cplx_t Y2;
    cplx_t dY;
    cplx_t Yold;

    cplx_t L1;
    cplx_t temp0; // temp
    cplx_t temp1; // temp REGISTER_X
    cplx_t temp2; // temp REGISTER_Y


    // Initialize
    getRegisterAsComplex(SREG_STARTX1, CPLX(X1));
    getRegisterAsComplex(SREG_STARTX0, CPLX(X0));

    //if input parameters X0 and X1 are the same, add a random number to X0
    if(realCompareEqual(&X0.Real, &X1.Real) && realCompareEqual(&X0.Imag, &X1.Imag)) {
#if defined(PC_BUILD)
      printf(">>> ADD random number to second input parameter to prevent infinite result\n");
#endif
      stringToReal("1E-3", &term, ctxtSolver2);
      realAdd(&X0.Real, &term, &X0.Real, ctxtSolver2);
      realRandomU01(&term);
      realAdd(&X0.Real, &term, &X0.Real, ctxtSolver2);
    }
    // uint32_t ticks = getUptimeMs() / 100;

    realCopy(const_0, &Xold.Real); realCopy(const_0, &Xold.Imag);
    copyComplex(&Xold, &Yold);
    copyComplex(&Xold, &X2N);
    copyComplex(&Xold, &dX);
    // initial value for difference comparison must be larger than tolerance
    stringToReal("1E-1", &dX.Real, ctxtSolver2);
    copyComplex(&dX, &dY);                       

    convertDoubleToReal(CONVERGE_FACTOR, &f, ctxtSolver2); // factor ()

    convergenceTolerence(&tol);

    convertComplexToResultRegister(CPLX(X0), REGISTER_X); //determined third starting point using the slope or secant
    execute_rpn_function();
    getRegisterAsComplex(REGISTER_Y, CPLX(Y0));
    convertComplexToResultRegister(CPLX(X1), REGISTER_X);
    execute_rpn_function();
    getRegisterAsComplex(REGISTER_Y, CPLX(Y1));


    checkzero = checkzero ||   complexIsLowerThanTol(CPLX(Y0), &tol);
    if(checkzero) {
      copyComplex(&Y0, &Y2);
      copyComplex(&X0, &X2);
    }
    else {
      checkzero = checkzero ||   complexIsLowerThanTol(CPLX(Y1), &tol);
      if(checkzero) {
        copyComplex(&Y1, &Y2);
        copyComplex(&X2, &X2);
      }
    }

    if(!checkzero) {
      subComplex(CPLX(X1), CPLX(X0), CPLX(temp0), ctxtSolver2);  //dx=x1-x0
      subComplex(CPLX(Y1), CPLX(Y0), CPLX(temp1), ctxtSolver2);  //dy=y1-y0
      divFunctionComplex( CPLX(temp0), CPLX(temp1), CPLX(temp0),  ADD_RAN, &tol);  //dx/dy
      mulComplexComplex( CPLX(temp0), CPLX(Y1), CPLX(temp0), ctxtSolver2);  //deltaX = x1 - x2 = Y1 / (dy/dx) = Y1 x 1/(dy/dx) = Y1 x dx/dy
      subComplex(CPLX(X1), CPLX(temp0), CPLX(X2), ctxtSolver2);  //x2=x1-deltaX
      convertComplexToResultRegister(CPLX(X2), REGISTER_X);
      execute_rpn_function();
      getRegisterAsComplex(REGISTER_Y, CPLX(Y2));
    }


#if (defined(VERBOSE_SOLVER00) || defined(VERBOSE_SOLVER0) || defined(VERBOSE_SOLVER1) || defined(VERBOSE_SOLVER2)) && defined(PC_BUILD)
    printf("INIT:   iterationCounter=%d \n",iterationCounter);
    printComplexToConsole(CPLX(X0), "Init X0=", "\n");
    printComplexToConsole(CPLX(X1), "Init X1=", "\n");
    printComplexToConsole(CPLX(X2), "Init X2=", "\n");
    printComplexToConsole(CPLX(Y0), "Init Y0=", "\n");
    printComplexToConsole(CPLX(Y1), "Init Y1=", "\n");
    printComplexToConsole(CPLX(Y2), "Init Y2=", "\n");
#endif // (VERBOSE_SOLVER00 || VERBOSE_SOLVER0 || VERBOSE_SOLVER1 || VERBOSE_SOLVER2) && PC_BUILD


    //###############################################################################################################
    //#################################################### Iteration start ##########################################
    while(iterationCounter<NUMBERITERATIONS && !checkNaN && !checkzero) {
#if defined(PC_BUILD)
      printf("\nIteration start\v");
#endif
      if(lastErrorCode != 0) {
#if defined(PC_BUILD)
        printf(">>> ERROR CODE INITIALLY NON-ZERO = %d <<<<<\n",lastErrorCode);
#endif //PC_BUILD
        break;
      }

      //Identify oscillations in real or imag: increment osc flag
      //osc = 0;

      if( (realIsNegative(&dX.Real) && realIsPositive(&Xold.Real)) ||
      (realIsPositive(&dX.Real) && realIsNegative(&Xold.Real)) ) {
        DXR = (DXR << 1) + 1;
      }
      else {
        DXR = DXR << 1;
      }

      if( (realIsNegative(&dY.Real) && realIsPositive(&Yold.Real)) ||
      (realIsPositive(&dY.Real) && realIsNegative(&Yold.Real)) ) {
        DYR = (DYR << 1) + 1;
      }
      else {
        DYR = DYR << 1;
      }

      if( (realIsNegative(&dX.Imag) && realIsPositive(&Xold.Imag)) ||
      (realIsPositive(&dX.Imag) && realIsNegative(&Xold.Imag)) ) {
        DXI = (DXI << 1) + 1;
      }
      else {
        DXI = DXI << 1;
      }

      if( (realIsNegative(&dY.Imag) && realIsPositive(&Yold.Imag)) ||
      (realIsPositive(&dY.Imag) && realIsNegative(&Yold.Imag)) ) {
        DYI = (DYI << 1) + 1;
      }
      else {
        DYI = DYI << 1;
      }

      check_osc(DXR);
      check_osc(DYR);
      check_osc(DXI);
      check_osc(DYI);

      //If osc flag is active, that is any delta polarity change, then increment oscillation count
      if(osc > 0) {
        oscillations++;
      }
      else {
        oscillations = max(0,oscillations-1);
      }

      //If converging, increment convergence counter
      if((!realCompareAbsGreaterThan(&dX.Real, &Xold.Real) && (!realCompareAbsGreaterThan(&dX.Imag, &Xold.Imag)))
        &&
          (!realCompareAbsGreaterThan(&dY.Real, &Yold.Real) && (!realCompareAbsGreaterThan(&dY.Imag, &Yold.Imag)))
      ) {
        convergent++;
      }
      else {
        convergent = max(0,convergent-1);
      }
#if defined(VERBOSE_SOLVER0)
      printf("##### iterationCounter= %d osc= %d  conv= %d n",iterationCounter, oscillations, convergent);
#endif // VERBOSE_SOLVER0
#if defined(VERBOSE_SOLVER1)
      printf("################################### iterationCounter= %d osc= %d  conv= %d ###########################################\n",iterationCounter, oscillations, convergent);
#endif //VERBOSE_SOLVER1

      if(convergent > 6 && oscillations > 3) {

#if defined(PC_BUILD)
        printf("    --   reset detection from =convergent%i and oscillations=%i to ", convergent, oscillations);
#endif // PC_BUILD
        convergent = 2;
        oscillations = 2;
#if defined(PC_BUILD)
        printf("%i and %i\n", convergent, oscillations);
#endif // PC_BUILD
      }

      // If increment is oscillating it is assumed that it is unstable and needs to have a complex starting value

      if((((oscillations >= 3) && (oscillationIterationCounter > 9) && (convergent <= 2)) )) { //|| (oscillations == 0 && convergent > 6 && real34CompareAbsLessThan(REGISTER_REAL34_DATA(SREG_DX), const34_1e_4) && (getRegisterDataType(SREG_DX) == dtComplex34 ? real34CompareAbsLessThan(REGISTER_IMAG34_DATA(SREG_DX), const34_1e_4) : 1 )  )
        if(COMPLEXKICKER && (kicker == 0) && (convergent <= 1)) {
          kicker = kicker + 2;
        }
        oscillationIterationCounter = 0;
        oscillations = 0;
        convergent = 0;
#if defined(VERBOSE_SOLVER2) && defined(PC_BUILD)
        printComplexToConsole(CPLX(X2), "\n>>>>>>>>>> from ", "");
#endif // VERBOSE_SOLVER2 && PC_BUILD


        //when kicker = 0, then factor is small negative real, after that, it becomes complex, in the first quadrant, multplied by a alrger number every time
        
        
        
        convertDoubleToReal( - (kicker + 0.001) / 100.0, &temp1.Real, ctxtSolver2);
        realCopy(const_0, &temp1.Imag);
        if(kicker > 0) {
          sqrtComplex(CPLX(temp1), CPLX(temp1), ctxtSolver2);
          convertDoubleToReal((kicker + 0.001) / 100.0, &temp2.Real, ctxtSolver2);
          realCopy(const_0, &temp2.Imag);
          sqrtComplex(CPLX(temp2), CPLX(temp2), ctxtSolver2);
          addComplex(CPLX(temp1), CPLX(temp2), CPLX(temp1), ctxtSolver2);
          convertDoubleToReal( pow(-2.0, kicker), &temp2.Real, ctxtSolver2);
          realCopy(const_0, &temp2.Imag);
          mulComplexComplex(CPLX(temp1), CPLX(temp2), CPLX(temp1), ctxtSolver2);
        }
#if (defined(VERBOSE_SOLVER00) || defined(VERBOSE_SOLVER0)) && defined(PC_BUILD)
        printf("------- Kicked oscillation, #%d, multiplied: ", kicker);
        printComplexToConsole(CPLX(temp1), "multiplied: ", "\n");
#endif  // (VERBOSE_SOLVER00 || VERBOSE_SOLVER0) && PC_BUILD
        kicker++;
        mulComplexComplex(CPLX(temp1), CPLX(X2), CPLX(X2), ctxtSolver2);
#if defined(VERBOSE_SOLVER2) && defined(PC_BUILD)
        printComplexToConsole(CPLX(X2), " to ", "\n");
#endif // VERBOSE_SOLVER2 && PC_BUILD
      }

      //@@@@@@@@@@@@@@@@@ CALCULATE NEW Y2, AND PLAUSIBILITY @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
      convertComplexToResultRegister(CPLX(X2), REGISTER_X); // get (X2)
      execute_rpn_function();                                         // leaving y2 in Y and x2 in X
      getRegisterAsComplex(REGISTER_Y, CPLX(Y2));           // y2

#if defined(VERBOSE_SOLVER1) && defined(PC_BUILD)
      printf("    :   iterationCounter=%d",iterationCounter);
      printComplexToConsole(CPLX(X2)," X2="," ");
      printComplexToConsole(CPLX(Y2)," Y2=","\n");
#endif // VERBOSE_SOLVER1 && PC_BUILD

      // y2 in Y2 and x2 in X2
      checkzero = checkzero ||   complexIsLowerThanTol(CPLX(Y2), &tol);
      checkNaN  = checkNaN  ||   realIsNaN(&X2.Real) || realIsNaN(&X2.Imag) ||
        realIsNaN(&Y2.Real) || realIsNaN(&Y2.Imag) ;

#if (defined(VERBOSE_SOLVER00) || defined(VERBOSE_SOLVER0)) && defined(PC_BUILD)
      if(checkNaN || iterationCounter==NUMBERITERATIONS-1 || checkzero) {
        printf("-->A Endflags zero: Y2r=0:%u Y2i=0:%u X2r=NaN:%u X2i=NaN:%u Y2r=NaN:%u Y2i=NaN%u \n",
        (uint16_t)realIsZero(&Y2.Real),(uint16_t)realIsZero(&Y2.Imag),
        (uint16_t)realIsNaN(&X2.Real),(uint16_t)realIsNaN(&X2.Imag),
        (uint16_t)realIsNaN(&Y2.Real),(uint16_t)realIsNaN(&Y2.Imag)
          );
      }
#endif // (VERBOSE_SOLVER00 || VERBOSE_SOLVER0) && PC_BUILD

#if defined(VERBOSE_SOLVER2) && defined(PC_BUILD)
      printf("   iterationCounter=%d checkend=%d X2=",iterationCounter, checkNaN || iterationCounter==NUMBERITERATIONS-1 || checkzero);
      printComplexToConsole(CPLX(X2),"","");
      printComplexToConsole(CPLX(Y2),"Y2=","\n");
#endif // VERBOSE_SOLVER2 && PC_BUILD

      //*************** DETERMINE DX and DY, to calculate the slope (or the inverse of the slope in this case) *******************
      copyComplex(&dX, &Xold);  // store old DELTA values, for oscillation check
      copyComplex(&dY, &Yold);  // store old DELTA values, for oscillation check

      // ---------- Modified 3 point Secant ------------
      if((iterationCounter == 0) || (!checkzero && !checkNaN)) {
#if defined(VERBOSE_SOLVER00) || defined(VERBOSE_SOLVER0) || defined(VERBOSE_SOLVER1) || defined(VERBOSE_SOLVER2)
        printf("%3i ---------- Modified 3 point Secant ------------ osc=%d conv=%d\n",iterationCounter, oscillations, convergent);
        printComplexToConsole(CPLX(X0), "           X0=","\n");
        printComplexToConsole(CPLX(Y0), "           Y0=","\n");
        printComplexToConsole(CPLX(X1), "           X1=","\n");
        printComplexToConsole(CPLX(Y1), "           Y1=","\n");
        printComplexToConsole(CPLX(X2), "           X2=","\n");
        printComplexToConsole(CPLX(Y2), "           Y2=","\n");
        
#endif // VERBOSE_SOLVER00 || VERBOSE_SOLVER0 || VERBOSE_SOLVER1 || VERBOSE_SOLVER2

        subComplex(CPLX(Y2), CPLX(Y0), CPLX(dY), ctxtSolver2); // Y2-Y0 = dY
        subComplex(CPLX(X2), CPLX(X0), CPLX(dX), ctxtSolver2); // X2-X0 = dX
        divFunctionComplex(CPLX(dY), CPLX(dX),  CPLX(temp0), !ADD_RAN, &tol); // dY/dX = temp0

#if defined(VERBOSE_SOLVER1) && defined(PC_BUILD)
        printComplexToConsole(CPLX(temp0), " m1=","\n");
#endif // VERBOSE_SOLVER1 && PC_BUILD

        subComplex(CPLX(Y2), CPLX(Y1), CPLX(L1), ctxtSolver2);
#if defined(VERBOSE_SOLVER1) && defined(PC_BUILD)
        printComplexToConsole(CPLX(L1), " Y2-Y1=","\n");
#endif // VERBOSE_SOLVER1 && PC_BUILD

        mulComplexComplex(CPLX(temp0),CPLX(L1), CPLX(L1), ctxtSolver2);
#if defined(VERBOSE_SOLVER1) && defined(PC_BUILD)
        printComplexToConsole(CPLX(L1), " term1 lower m1*(Y2-Y1)=","\n");
#endif // VERBOSE_SOLVER1 && PC_BUILD

        subComplex(CPLX(Y1), CPLX(Y0), CPLX(temp1), ctxtSolver2);
#if defined(VERBOSE_SOLVER1) && defined(PC_BUILD)
        printComplexToConsole(CPLX(temp1), " dY2=","\n");//30
#endif // VERBOSE_SOLVER1 && PC_BUILD
        subComplex(CPLX(X1), CPLX(X0), CPLX(temp2), ctxtSolver2);
        divFunctionComplex(CPLX(temp1), CPLX(temp2), CPLX(temp1), !ADD_RAN, &tol);

#if defined(VERBOSE_SOLVER1) && defined(PC_BUILD)
        printComplexToConsole(CPLX(temp1), " m2=","\n");//30
#endif // VERBOSE_SOLVER1 && PC_BUILD
        subComplex(CPLX(temp0), CPLX(temp1), CPLX(temp1), ctxtSolver2);
#if defined(VERBOSE_SOLVER1) && defined(PC_BUILD)
        printComplexToConsole(CPLX(temp1)," m1-m2 diff=","\n");
        printComplexToConsole(CPLX(Y2), " Y2=","\n");
#endif // VERBOSE_SOLVER1 && PC_BUILD
        mulComplexComplex(CPLX(temp1), CPLX(Y2), CPLX(temp1), ctxtSolver2);
#if defined(VERBOSE_SOLVER1) && defined(PC_BUILD)
        printComplexToConsole(CPLX(temp1), " term2 lower=","\n");
#endif // VERBOSE_SOLVER1 && PC_BUILD
        subComplex(CPLX(L1), CPLX(temp1), CPLX(temp1), ctxtSolver2);
        
#if defined(VERBOSE_SOLVER1) && defined(PC_BUILD)
        printComplexToConsole(CPLX(temp1), " lower diff=","\n");
#endif // VERBOSE_SOLVER1 && PC_BUILD
        subComplex(CPLX(Y2), CPLX(Y1), CPLX(temp2), ctxtSolver2);
        //get the 1/slope
        divFunctionComplex(CPLX(temp2), CPLX(temp1), CPLX(temp0), !ADD_RAN, &tol);
#if defined(VERBOSE_SOLVER1) && defined(PC_BUILD)
        printComplexToConsole(CPLX(temp0), " 1/slope=","\n");
#endif // VERBOSE_SOLVER1 && PC_BUILD
        mulComplexComplex(CPLX(temp0), CPLX(Y0), CPLX(temp1), ctxtSolver2); // increment to x is: y1 . DX/DY
        // factor to stabilize Newton method. factor=1 is straight. factor=0.1 converges 10x slower.
        mulComplexComplex(CPLX(temp1), &f, const_0, CPLX(temp1), ctxtSolver2); // increment to x is: y1 . DX/DY

#if defined(VERBOSE_SOLVER1) && defined(PC_BUILD)
        printRealToConsole(&f, "    Factor=        ","\n");
        printComplexToConsole(CPLX(X0),"    New X =        "," - (");
        printComplexToConsole(CPLX(temp1),"",")\n");
#endif // VERBOSE_SOLVER1 && PC_BUILD
        subComplex(CPLX(X0), CPLX(temp1), CPLX(temp1), ctxtSolver2); // subtract as per Newton, x1 - f/f'

        //try round numbers
        if(convergent > 3 && iterationCounter > 6 && oscillations == 0 && realCompareLessEqual(&temp1.Real, const_1e_4)) {
          convergent = 0;
          double higherXStartValue;
          realToDouble(&temp1.Real, &higherXStartValue);
          convertDoubleToReal(roundf(1000.0 * higherXStartValue)/1000.0, &temp1.Real, ctxtSolver2);
          realCopy(const_0, &temp1.Imag);
        }

        copyComplex(&temp1, &X2N);// store temporarily to new x2n
      }

      //#############################################


#if defined(VERBOSE_SOLVER1) && defined(PC_BUILD)
      printComplexToConsole(&dX.Real,   &dX.Imag, "               DX=","");printComplexToConsole(CPLX(dY),"DY=","\n");
      printComplexToConsole(&X0.Real,   &X0.Imag, "               X0=","");printComplexToConsole(CPLX(Y0),"Y0=","\n");
      printComplexToConsole(CPLX(X2N),"   -------> newX2: ","\n");
      printComplexToConsole(&X1.Real,   &X1.Imag, "               X1=","");printComplexToConsole(CPLX(Y1),"Y1=","\n");
      printComplexToConsole(&X2.Real,   &X2.Imag, "               X2=","");printComplexToConsole(CPLX(Y2),"Y2=","\n");
#endif // VERBOSE_SOLVER1 && PC_BUILD

      copyComplex(&Y1, &Y0); //old y1 copied to y0
      copyComplex(&X1, &X0); //old x1 copied to x0
      copyComplex(&Y2, &Y1); //old y2 copied to y1
      copyComplex(&X2, &X1); //old x2 copied to x1

      complexMagnitude(CPLX(dX), &temp2.Real,  ctxtSolver2);
      complexMagnitude(CPLX(dY), &temp1.Real,  ctxtSolver2);

      checkzero |= check2RealZeroTol(&temp1.Real, &temp2.Real, &tol);
      checkNaN |=  realIsNaN(&temp1.Real) || realIsNaN(&temp2.Real);

#if defined(VERBOSE_SOLVER00) || defined(VERBOSE_SOLVER0) || defined(VERBOSE_SOLVER1)
      if(checkzero) {
        printf("--B1 Checkzero\n");
      }
      if(checkNaN) {
        printf("--B2 CheckNaN\n");
      }
      if(checkNaN || iterationCounter==NUMBERITERATIONS-1 || checkzero) {
        printf("--B3 Endflags: |DXr|=0:%u |DXr|<TOL:%u |DYr|<TOL:%u |DYr|=0:%u |DXr|=NaN:%u |DYr|=NaN:%u \n",
        (uint16_t) realIsZero(&temp1.Real),
        (uint16_t)(realCompareAbsLessThan(&temp1.Real, &tol)),
        (uint16_t) realIsZero(&temp2.Real),
        (uint16_t)(realCompareAbsLessThan(&temp2.Real, &tol)),
        (uint16_t) realIsNaN (&temp1.Real),
        (uint16_t) realIsNaN (&temp2.Real)
          );
      }
#endif // VERBOSE_SOLVER00 || VERBOSE_SOLVER0 || VERBOSE_SOLVER1
      iterationCounter++;
      oscillationIterationCounter++;

#if defined(VERBOSE_SOLVER2) && defined(PC_BUILD)
      if(!checkNaN && !(iterationCounter==NUMBERITERATIONS) && !checkzero) {
        printf("END     iterationCounter=%d |DX|<TOL:%d ",iterationCounter, realCompareAbsLessThan(&dX.Real, &tol));
        printComplexToConsole(CPLX(dX),"","\n");
        printf("END     iterationCounter=%d |DY|<TOL:%d ",iterationCounter, realCompareAbsLessThan(&dY.Real, &tol));
        printComplexToConsole(CPLX(dY),"","\n");
        printComplexToConsole(CPLX(temp1),"END     DY=","\n");
      }
#endif // VERBOSE_SOLVER2 && PC_BUILD

#if defined(VERBOSE_SOLVER1) && defined(PC_BUILD)
      printComplexToConsole(CPLX(dX),">>> DX=","");
      printComplexToConsole(CPLX(dY)," DY=","");
      printComplexToConsole(CPLX(temp0)," 1/SLOPE=","\n");
#endif // VERBOSE_SOLVER1 && PC_BUILD

      realCopy(&X2N.Real, &X2.Real); realCopy(&X2N.Imag, &X2.Imag); //new x2

      if(checkHalfSec()) {
        if(progressHalfSecUpdate_Integer(timed, "Iter: ",iterationCounter, halfSec_clearZ, halfSec_clearT, halfSec_disp)) { //timed
          showProgressReal(CPLX(X1), realIsZero(&X1.Imag));
        }
      }

      if(exitKeyWaiting()) {
        showString("key Waiting ...", &standardFont, 20, 40, vmNormal, false, false);
        progressHalfSecUpdate_Integer(force+1, "Interrupted Iter:",iterationCounter, halfSec_clearZ, halfSec_clearT, halfSec_disp);
        calcMode = CM_NORMAL;
        screenUpdatingMode = SCRUPD_AUTO;
        screenUpdatingMode |= SCRUPD_SKIP_STATUSBAR_ONE_TIME;
        break;
      }
#if defined(PC_BUILD)
      printf("iterationCounter = %i ", iterationCounter);
      printComplexToConsole(CPLX(X1),"X = "," ");
      printComplexToConsole(CPLX(Y1),"Y = ","\n");
#endif // PC_BUILD

      if (ENABLE_COMPLEXSOLVER_FILE_OUTPUT == 1) {
        convertComplexToResultRegister(CPLX(X1), REGISTER_X);
        convertComplexToResultRegister(CPLX(Y1), REGISTER_Y);
        fnP_All_Regs(PRN_XYr);
      }



    }  //Iteration end

    refreshScreen(200);

    checkNaN =    checkNaN
      || realIsNaN(&X1.Real) || realIsNaN(&X1.Imag)
        || realIsNaN(&X2.Real) || realIsNaN(&X2.Imag);


    bool_t   FLAG_FRACTN = getSystemFlag(FLAG_FRACT);
    clearSystemFlag(FLAG_FRACT);


    bool_t conjugates = false;
    if(!check2RealZeroTol(&X2.Imag, &X2.Imag, &tol)) {  // do not consider conjugates if X is close to Real
      realCopy(&X2.Real, &temp1.Real); realCopy(&X2.Imag, &temp1.Imag);
      realChangeSign(&temp1.Imag);
      convertComplexToResultRegister(CPLX(temp1), REGISTER_X); // get (X2)
      execute_rpn_function();                                         // leaving y2 in Y and x2 in X
      getRegisterAsComplex(REGISTER_Y, CPLX(temp2));           // y2
      conjugates = check2RealZeroTol(CPLX(temp2), &tol);
    }


    fnUndo(0);

    if(((iterationCounter > NUMBERITERATIONS) && !checkzero) || checkNaN) {
      temporaryInformation = TI_SOLVER_FAILED;
      displayCalcErrorMessage(ERROR_NO_ROOT_FOUND, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
      convertDoubleToReal34RegisterPush(SOLVER_RESULT_OTHER_FAILURE, REGISTER_T);
    }
    else {
      temporaryInformation = TI_SOLVER_VARIABLE_RESULT;
      lastErrorCode = ERROR_NONE;
      convertDoubleToReal34RegisterPush(conjugates ? (double)SOLVER_RESULT_CONJUGATES : (double)SOLVER_RESULT_NORMAL, REGISTER_T);
    }

    convertComplexToResultRegister(CPLX(Y2), REGISTER_Z);
    convertComplexToResultRegister(CPLX(X1), REGISTER_Y);
    convertComplexToResultRegister(CPLX(X2), REGISTER_X);
    copySourceRegisterToDestRegister(REGISTER_X, graphVariabl1);

    printSolverResult(iterationCounter, conjugates);

    if(FLAG_FRACTN) {
      setSystemFlag(FLAG_FRACT);
    }

    calcMode = CM_NORMAL;
    SAVED_SIGMA_lastAddRem = SIGMA_NONE;   //prevent undo of last stats add action. REMOVE when STATS are not used anymore
    return;
  }


  void fnComplexSolver(void) {
    printStatus(1,errorMessages[COMPLEX_SOLVER],force);
    fnClDrawMx(4);
    strcpy(plotStatMx,"DrwMX"); //why is this graph stuff here?
    statGraphReset();

    double higherXStartValue = convertRegisterToDouble(REGISTER_X);
    double lowerXStartValue = convertRegisterToDouble(REGISTER_Y);
    #if (defined(VERBOSE_SOLVER00) || defined(VERBOSE_SOLVER0)) && defined(PC_BUILD)
      printRegisterToConsole(REGISTER_Y,">>> lowerXStartValue=","");
      printRegisterToConsole(REGISTER_X," higherXStartValue=","\n");
    #endif // (VERBOSE_SOLVER00 || VERBOSE_SOLVER0) && PC_BUILD
    calcRegister_t SREG_STARTX0 = __STARTX0;
    calcRegister_t SREG_STARTX1 = __STARTX1;
    copySourceRegisterToDestRegister(REGISTER_Y,SREG_STARTX0);
    copySourceRegisterToDestRegister(REGISTER_X,SREG_STARTX1);
    fnDrop(NOPARAM);
    fnDrop(NOPARAM);
    saveForUndo(); //repeat after dropping the input parameters

    if(higherXStartValue>lowerXStartValue + 0.01 && higherXStartValue!=DOUBLE_NOT_INIT && lowerXStartValue!=DOUBLE_NOT_INIT) { //pre-condition the plotter
      x_min = lowerXStartValue;
      x_max = higherXStartValue;
    }
    #if (defined(VERBOSE_SOLVER00) || defined(VERBOSE_SOLVER0)) && defined(PC_BUILD)
      printf("xmin:%f, xmax:%f\n",x_min,x_max);
    #endif // (VERBOSE_SOLVER00 || VERBOSE_SOLVER0) && PC_BUILD
    initialize_function();
    complexSolver();
  }

  #endif // !TESTSUITE_BUILD
#endif //SAVE_SPACE_DM42_13GRF


//-----------------------------------------------------//-----------------------------------------------------
void fnEqSolvGraph (uint16_t func) {
  #if !defined(SAVE_SPACE_DM42_13GRF)
    #if !defined(TESTSUITE_BUILD)
      hourGlassIconEnabled = true;
      showHideHourGlass();
      #if defined(DMCP_BUILD)
        lcd_refresh();
      #else // !DMCP_BUILD
        refreshLcd(NULL);
      #endif // DMCP_BUILD

      real_t x, y;


      switch(func) {
        case EQ_CPXSOLVE_LU:
        case EQ_REALSOLVE_LU: {
          if(getRegisterAsReal(RESERVED_VARIABLE_LEST, &y) && getRegisterAsReal(RESERVED_VARIABLE_UEST, &x)) {
            liftStack();
            reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
            liftStack();
            reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
            realToReal34(&x, REGISTER_REAL34_DATA(REGISTER_X));
            realToReal34(&y, REGISTER_REAL34_DATA(REGISTER_Y));
            solverEstimatesUsed = true;
          }
          break;
        }
        case EQ_CPXSOLVE:
        case EQ_REALSOLVE: {
          if(getRegisterAsReal(REGISTER_X, &x) && getRegisterAsReal(REGISTER_Y, &y)) {
            reallocateRegister(RESERVED_VARIABLE_UEST, dtReal34, 0, amNone);
            reallocateRegister(RESERVED_VARIABLE_LEST, dtReal34, 0, amNone);
            realToReal34(&x, REGISTER_REAL34_DATA(RESERVED_VARIABLE_UEST));
            realToReal34(&y, REGISTER_REAL34_DATA(RESERVED_VARIABLE_LEST));
            solverEstimatesUsed = false;
          }
          break;
        }
        case EQ_PLOT_LU: {           //uses limits
          if(getRegisterAsReal(RESERVED_VARIABLE_LX, &y) && getRegisterAsReal(RESERVED_VARIABLE_UX, &x)) {
            liftStack();
            reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
            liftStack();
            reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
            realToReal34(&x, REGISTER_REAL34_DATA(REGISTER_X));
            realToReal34(&y, REGISTER_REAL34_DATA(REGISTER_Y));
          }
          break;
        }
        case EQ_PLOT: {              //uses X, Y
          if(getRegisterAsReal(REGISTER_X, &x) && getRegisterAsReal(REGISTER_Y, &y)) {
            reallocateRegister(RESERVED_VARIABLE_UX, dtReal34, 0, amNone);
            reallocateRegister(RESERVED_VARIABLE_LX, dtReal34, 0, amNone);
            realToReal34(&x, REGISTER_REAL34_DATA(RESERVED_VARIABLE_UX));
            realToReal34(&y, REGISTER_REAL34_DATA(RESERVED_VARIABLE_LX));
            }
          break;
        }
        default:
          return;
          break;
      }

      graphVariabl1 = currentSolverVariable;
      if(graphVariabl1<0) {
        graphVariabl1 = -graphVariabl1;
      }

      if(graphVariabl1 >= FIRST_NAMED_VARIABLE && graphVariabl1 <= LAST_NAMED_VARIABLE) {
        #if (defined(VERBOSE_SOLVER00) || defined(VERBOSE_SOLVER0)) && defined(PC_BUILD)
          printf("graphVariabl1 accepted: %i\n", graphVariabl1);
        #endif // (VERBOSE_SOLVER00 || VERBOSE_SOLVER0) && PC_BUILD
      }
      else {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        #if (EXTRA_INFO_ON_CALC_ERROR == 1)
          sprintf(errorMessage, "unexpected parameter %u", graphVariabl1);
          moreInfoOnError("In function fnEqSolvGraph:", errorMessage, NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        return;
      }


      //initialize x
      currentSolverStatus &= ~SOLVER_STATUS_READY_TO_EXECUTE;

      switch(func) {
        case EQ_REALSOLVE_LU:
        case EQ_REALSOLVE: {
          if((currentSolverVariable >= FIRST_NAMED_VARIABLE) ) {//&& currentSolverStatus & SOLVER_STATUS_READY_TO_EXECUTE) {
            fnSolve(currentSolverVariable);
          }
          break;
        }

        case EQ_CPXSOLVE_LU:
        case EQ_CPXSOLVE: {
          fnComplexSolver();
          break;
        }

        case EQ_PLOT_LU:
        case EQ_PLOT: {

    //      PLOT_ZMY = 0; removed default zeroing of the zoom factor in eqn as it is irritating with the new y range control
          double higherXStartValue = convertRegisterToDouble(REGISTER_X);
          double lowerXStartValue = convertRegisterToDouble(REGISTER_Y);
          #if (defined(VERBOSE_SOLVER00) || defined(VERBOSE_SOLVER0)) && defined(PC_BUILD)
            printf(">>> lowerXStartValue=%f  higherXStartValue=%f\n",lowerXStartValue, higherXStartValue);
          #endif // (VERBOSE_SOLVER00 || VERBOSE_SOLVER0) && PC_BUILD

          fnClDrawMx(5);
          strcpy(plotStatMx,"DrwMX");

          if(higherXStartValue>lowerXStartValue + 0.0001 && higherXStartValue!=DOUBLE_NOT_INIT && lowerXStartValue!=DOUBLE_NOT_INIT) { //pre-condition the plotter
            x_min = lowerXStartValue;
            x_max = higherXStartValue;
          }
          if(x_min > x_max) { //swap if entered in incorrect sequence
            float kk = x_max;
            x_max = x_min;
            x_min = kk;
          }
          float x_d = fabs(x_max-x_min);
          if(x_d < 0.0001) { //too close together for float type
            x_d = 0.0001 * 10;
            if(fabs(x_min)<0.0001 || fabs(x_max)<0.0001) { //abort old values typically 0 - 0 and change to -1 to 1
              x_d = 10;
            }
            x_min = x_min - 0.1 * x_d;
            x_max = x_max + 0.1 * x_d;
          }
          #if (defined(VERBOSE_SOLVER00) || defined(VERBOSE_SOLVER0)) && defined(PC_BUILD)
            printf("xmin:%f, xmax:%f\n",x_min,x_max);
          #endif // (VERBOSE_SOLVER00 || VERBOSE_SOLVER0) && PC_BUILD

          initialize_function();
          graph_eqn(noInitDrwMx);

          if(!getSystemFlag(FLAG_PCROS) && !getSystemFlag(FLAG_PBOX) && !getSystemFlag(FLAG_PPLUS)) {
            setSystemFlag(FLAG_PLINE);
          }

          reDraw = true;
          screenUpdatingMode = SCRUPD_AUTO;
          screenUpdatingMode |= SCRUPD_SKIP_STATUSBAR_ONE_TIME;
          refreshScreen(239);
          break;
        }
        default: ;
      }
    #endif // !TESTSUITE_BUILD
  #endif // SAVE_SPACE_DM42_13GRF
}
