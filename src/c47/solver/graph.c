// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors


/********************************************//** //JM
 * \file graph.c Graphing module
 ***********************************************/

#include "c47.h"

#if defined(PC_BUILD)
  //Verbose directives can be simulataneously selected
  //#define VERBOSE_SOLVER00   // minimal text
  //#define VERBOSE_SOLVER0  // a lot less text
  //#define VERBOSE_SOLVER1  // a lot less text
  //#define VERBOSE_SOLVER2  // verbose a lot
#else // !PC_BUILD
  #undef VERBOSE_SOLVER00
  #undef VERBOSE_SOLVER0
  #undef VERBOSE_SOLVER1
  #undef VERBOSE_SOLVER2
#endif // PC_BUILD


//Todo: involve https://en.wikipedia.org/wiki/Brent%27s_method#Brent's_method

#define COMPLEXKICKER true       //flag to allow conversion to complex plane if no convergenge found
#define CHANGE_TO_MOD_SECANT 0   //at iteration nn go to the modified secant method. 0 means immediately
#define CONVERGE_FACTOR 1.0f     //
#define NUMBERITERATIONS 9999    // 35 // Must be smaller than LIM (see STATS)


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
  static bool_t regIsLowerThanTol(calcRegister_t REG, calcRegister_t TOL) {
    return (    (real34IsZero(REGISTER_REAL34_DATA(REG)) && (getRegisterDataType(REG) == dtComplex34 ? real34IsZero(REGISTER_IMAG34_DATA(REG)) : 1 ))
             || (    (real34CompareAbsLessThan(REGISTER_REAL34_DATA(REG), REGISTER_REAL34_DATA(TOL)))
                  && (getRegisterDataType(REG) == dtComplex34 ? real34CompareAbsLessThan(REGISTER_IMAG34_DATA(REG), REGISTER_REAL34_DATA(TOL)) : 1)
                )
           );
  }


#define ADD_RAN true
static void divFunction(bool_t addRandom, calcRegister_t TOL) {
  if(  (real34IsZero(REGISTER_REAL34_DATA(REGISTER_Y)) && (getRegisterDataType(REGISTER_Y) == dtComplex34 ? real34IsZero(REGISTER_IMAG34_DATA(REGISTER_Y)) : 1 ) )
     || real34IsNaN(REGISTER_REAL34_DATA(REGISTER_Y))
     || (getRegisterDataType(REGISTER_Y) == dtComplex34 ? real34IsNaN(REGISTER_IMAG34_DATA(REGISTER_Y)) : 0 ) ) {
    fnDrop(NOPARAM);
    fnDrop(NOPARAM);
    convertDoubleToReal34RegisterPush(0.0, REGISTER_X);
    return;
  }
  if(real34IsNaN(REGISTER_REAL34_DATA(REGISTER_X)) || (getRegisterDataType(REGISTER_X) == dtComplex34 ? real34IsNaN(REGISTER_IMAG34_DATA(REGISTER_X)) : 0 ) ) {
    fnDrop(NOPARAM);
    fnDrop(NOPARAM);
    convertDoubleToReal34RegisterPush(0.0, REGISTER_X);
    return;
  }
  if(!addRandom && (real34IsZero(REGISTER_REAL34_DATA(REGISTER_X)) && (getRegisterDataType(REGISTER_X) == dtComplex34 ? real34IsZero(REGISTER_IMAG34_DATA(REGISTER_X)) : 1 ) )) {
    fnDrop(NOPARAM);
    fnDrop(NOPARAM);
    convertDoubleToReal34RegisterPush(1e30, REGISTER_X);
    return;
  }
  if(addRandom && regIsLowerThanTol(REGISTER_X, TOL)) {
      #if defined(PC_BUILD)
      printf(">>> ADD random number to denominator to prevent infinite result\n");
      #endif // PC_BUILD
    convertDoubleToReal34RegisterPush(1e-6, REGISTER_X);
    runFunction(ITM_ADD);
    runFunction(ITM_RAN);
    runFunction(ITM_ADD);
  }
  runFunction(ITM_DIV);
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





#define GRAPHDEBUG
//******************************************************************************************************************************


typedef struct {
  double x, y;
  double grad;
  bool stored;
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

#define ASYMPTOTECHECKING false

bool validateDiscontinuityResolution(PlotPoint *buffer, int count, double yBefore, double yAfter, double discontinuityThreshold) {
#ifdef GRAPHDEBUG
  printf("\nVALIDATING DISCONTINUITY RESOLUTION:");
  printf("\n  Points: %d, yBefore=%.6f, yAfter=%.6f, threshold=%.6f\n", 
         count, yBefore, yAfter, discontinuityThreshold);
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
  bool discontinuityResolved = (maxJump < discontinuityThreshold);
  
  // Additional check: fine points should show reasonable continuity
  double avgVariation = totalVariation / (count - 1);
  bool smoothTransition = (maxJump < 3.0 * avgVariation) || (maxJump < discontinuityThreshold * 0.5);
  
#ifdef GRAPHDEBUG
  printf("  maxJump=%.6f, avgVariation=%.6f\n", maxJump, avgVariation);
  printf("  startJump=%.6f, endJump=%.6f\n", startJump, endJump);
  printf("  discontinuityResolved=%d, smoothTransition=%d\n", discontinuityResolved, smoothTransition);
#endif
  
  return discontinuityResolved && smoothTransition;
}

double calculateNewStepSize(int discontinuityDetected, double grad1, double grad2, bool grad2IncreaseDetected, double dx0) {
#ifdef GRAPHDEBUG
  printf("calculateNewStepSize: discontinuity=%d, grad1=%.6f, grad2=%.6f, increase=%d, dx0=%.6f\n", discontinuityDetected, grad1, grad2, grad2IncreaseDetected, dx0);
#endif
  
  if(discontinuityDetected > 0 && discontinuityDetected <= FINE) {
    double newDx = dJMP * dx0;
#ifdef GRAPHDEBUG
    printf("  -> Discontinuity mode: newDx=%.6f\n", newDx);
#endif
    return newDx;
  } else if(grad2 == 0 || grad1 == 0) {
#ifdef GRAPHDEBUG
    printf("  -> Zero gradient: keeping dx0=%.6f\n", dx0);
#endif
    return dx0;
  } else if(grad2IncreaseDetected) {
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

void enterHighResMode(bool *inHighResMode, int *highResCount, double *highResStartX, double *baselineCurvatureChange, double *cumulativeCurvatureChange, double x, double curvatureChange) {
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

void abandonHighResMode(int *highResCount, bool *inHighResMode) {
#ifdef GRAPHDEBUG
  printf("*** ABANDONING HIGH-RES MODE (discarding %d points) ***\n", *highResCount);
#endif
  *highResCount = 0;
  *inHighResMode = false;
  // High-res points are simply discarded, not added to plot
}

void resetHighResTracking(int *highResCount, bool *inHighResMode, double *cumulativeCurvatureChange) {
#ifdef GRAPHDEBUG
  printf("*** RESETTING HIGH-RES TRACKING ***\n");
#endif
  *highResCount = 0;
  *inHighResMode = false;
  *cumulativeCurvatureChange = 0;
}

// Improved discontinuity detection that distinguishes between genuine discontinuities and normal peaks
bool detectTrueDiscontinuity(double y0, double y1, double y2, double grad0, double grad1, double grad2, double yAvg, int count) {
  // Basic checks for infinite/NaN values
  if(real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X)) || 
     ((getRegisterDataType(REGISTER_X) == dtComplex34) && 
      (real34IsInfinite(REGISTER_IMAG34_DATA(REGISTER_X))))) {
    return true;
  }
  
  if(real34IsNaN(REGISTER_REAL34_DATA(REGISTER_X)) || 
     ((getRegisterDataType(REGISTER_X) == dtComplex34) && 
      (real34IsNaN(REGISTER_IMAG34_DATA(REGISTER_X))))) {
    return true;
  }
  
  // Don't trigger on early samples
  if(count < 4) return false;
  
  // Check for extreme magnitude changes (likely discontinuity)
  bool extremeMagnitudeJump = (fabs(y2) > 100 * yAvg) && (fabs(y1) < 10 * yAvg);
  
  // Check for gradient discontinuity (not just sign change)
  // A true discontinuity shows abrupt gradient change without smooth transition
  bool gradientDiscontinuity = false;
  if(grad0 != 0 && grad1 != 0 && grad2 != 0) {
    // Calculate expected gradient based on trend
    double expectedGrad = grad1 + (grad1 - grad0); // Linear extrapolation
    double gradientRatio = fabs(grad2) / (fabs(expectedGrad) + 1e-10);
    
    // Only flag if gradient changes by more than 50x AND the function values suggest discontinuity
    gradientDiscontinuity = (gradientRatio > 50) && 
                           (fabs(y2 - y1) > 20 * fabs(y1 - y0)) &&
                           (fabs(y2 - y1) > 5 * yAvg);
  }
  
  // Check for sign oscillation that indicates numerical instability rather than smooth peaks
  bool signOscillationInstability = false;
  if(count >= 6) {
    // Look for rapid alternating signs with increasing magnitude - indicates instability
    bool y0Pos = (y0 > 0), y1Pos = (y1 > 0), y2Pos = (y2 > 0);
    if(y0Pos != y1Pos && y1Pos != y2Pos) {
      // Alternating signs - check if magnitudes are increasing dramatically
      double mag0 = fabs(y0), mag1 = fabs(y1), mag2 = fabs(y2);
      signOscillationInstability = (mag2 > 5 * mag1) && (mag1 > 5 * mag0) && (mag2 > 10 * yAvg);
    }
  }
  
#ifdef GRAPHDEBUG
  printf("discontinuity check: extreme=%d, gradient=%d, oscillation=%d\n", 
         extremeMagnitudeJump, gradientDiscontinuity, signOscillationInstability);
  if(gradientDiscontinuity) {
    double expectedGrad = grad1 + (grad1 - grad0);
    double gradientRatio = fabs(grad2) / (fabs(expectedGrad) + 1e-10);
    printf("  gradient details: expected=%.6f, actual=%.6f, ratio=%.3f\n", 
           expectedGrad, grad2, gradientRatio);
  }
#endif
  
  return extremeMagnitudeJump || gradientDiscontinuity || signOscillationInstability;
}




// =============================================================================
// ASYMPTOTE DETECTION AND RENDERING HELPER FUNCTIONS
// Add this code block before your existing graph_eqn() function
// =============================================================================

typedef struct {
  double x;           // x-coordinate of asymptote
  double gapWidth;    // width of the discontinuity gap
  bool hasPositive;   // approaches +infinity
  bool hasNegative;   // approaches -infinity
  double maxHeight;   // standard maximum height for rendering
} AsymptoteInfo;

#define MAX_ASYMPTOTES 10
#define ASYMPTOTE_HEIGHT_RATIO 0.8  // 80% of y-axis range
#define MIN_GAP_WIDTH_RATIO 0.001   // Minimum gap width as ratio of x-range
#define ASYMPTOTE_SAMPLE_POINTS 5   // Points to sample on each side

// Helper function to detect and characterize asymptotes
bool detectAndCharacterizeAsymptote(double xLeft, double yLeft, double xRight, double yRight, 
                                   double xGap, double gapWidth, AsymptoteInfo *asymptote) {
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
  
  bool leftGoesPositive = (leftMaxY > y_max + extremeThreshold);
  bool leftGoesNegative = (leftMinY < y_min - extremeThreshold);
  bool rightGoesPositive = (rightMaxY > y_max + extremeThreshold);
  bool rightGoesNegative = (rightMinY < y_min - extremeThreshold);
  
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
  
  return true;
}

// CAREFUL: Add 3 points in sequence to create clean vertical line
void renderAsymptote(AsymptoteInfo *asymptote) {
  double x_center = asymptote->x;
  double offset = 1e-3;  // Small x offset
  double asymptoteHeight = 10000.0;
  
#ifdef GRAPHDEBUG
  printf("Rendering asymptote at x=%.6f with clean 3-point vertical sequence\n", x_center);
#endif
  
  if(asymptote->hasPositive && asymptote->hasNegative) {
    // Two-way asymptote: straight vertical line
    
    // Point 1: (x-offset, -10000) - bottom left
    convertDoubleToReal34Register(x_center - offset, REGISTER_X);
    convertDoubleToReal34Register(-asymptoteHeight, REGISTER_Y);
#if !defined(TESTSUITE_BUILD)
    AddtoDrawMx();
#endif
    
    // Point 2: (x-offset, +10000) - top left (straight up)
    convertDoubleToReal34Register(x_center - offset, REGISTER_X);
    convertDoubleToReal34Register(asymptoteHeight, REGISTER_Y);
#if !defined(TESTSUITE_BUILD)
    AddtoDrawMx();
#endif
    
    // Point 3: (x+offset, +10000) - top right (continue horizontally)
    convertDoubleToReal34Register(x_center + offset, REGISTER_X);
    convertDoubleToReal34Register(asymptoteHeight, REGISTER_Y);
#if !defined(TESTSUITE_BUILD)
    AddtoDrawMx();
#endif
    
  } else if(asymptote->hasPositive) {
    // Positive only: bottom to top
    
    convertDoubleToReal34Register(x_center - offset, REGISTER_X);
    convertDoubleToReal34Register(0.0, REGISTER_Y);
#if !defined(TESTSUITE_BUILD)
    AddtoDrawMx();
#endif
    
    convertDoubleToReal34Register(x_center - offset, REGISTER_X);
    convertDoubleToReal34Register(asymptoteHeight, REGISTER_Y);
#if !defined(TESTSUITE_BUILD)
    AddtoDrawMx();
#endif
    
    convertDoubleToReal34Register(x_center + offset, REGISTER_X);
    convertDoubleToReal34Register(asymptoteHeight, REGISTER_Y);
#if !defined(TESTSUITE_BUILD)
    AddtoDrawMx();
#endif
    
  } else if(asymptote->hasNegative) {
    // Negative only: top to bottom
    
    convertDoubleToReal34Register(x_center - offset, REGISTER_X);
    convertDoubleToReal34Register(0.0, REGISTER_Y);
#if !defined(TESTSUITE_BUILD)
    AddtoDrawMx();
#endif
    
    convertDoubleToReal34Register(x_center - offset, REGISTER_X);
    convertDoubleToReal34Register(-asymptoteHeight, REGISTER_Y);
#if !defined(TESTSUITE_BUILD)
    AddtoDrawMx();
#endif
    
    convertDoubleToReal34Register(x_center + offset, REGISTER_X);
    convertDoubleToReal34Register(-asymptoteHeight, REGISTER_Y);
#if !defined(TESTSUITE_BUILD)
    AddtoDrawMx();
#endif
  }
  
#ifdef GRAPHDEBUG
  printf("Added 3 asymptote points in clean vertical sequence\n");
#endif
}

// asymptote detection that checks for sign changes with large gradients
bool detectVerticalAsymptote(double y0, double y1, double y2, double grad0, double grad1, double grad2, 
                            double x0, double x1, double x2, int count) {
  if(count < 3) return false;
  
  // Check for sign change with large gradient magnitudes (typical of vertical asymptotes)
  bool signChange = ((y1 > 0 && y2 < 0) || (y1 < 0 && y2 > 0));
  bool largeGradients = (fabs(grad1) > 50 || fabs(grad2) > 50);
  bool gradientJump = (fabs(grad2 - grad1) > fabs(grad1) * 2);
  
#ifdef GRAPHDEBUG
  printf("Vertical asymptote check: signChange=%d, largeGrads=%d, gradJump=%d\n", 
         signChange, largeGradients, gradientJump);
  printf("  y1=%.3f, y2=%.3f, grad1=%.3f, grad2=%.3f\n", y1, y2, grad1, grad2);
#endif
  
  // Asymptote likely if we have sign change AND (large gradients OR gradient jump)
  return signChange && (largeGradients || gradientJump);
}

// discontinuity detection that also checks for asymptotes
bool detectTrueDiscontinuityWithAsymptote(double y0, double y1, double y2, double grad0, double grad1, double grad2, 
                                          double yAvg, int count, double x0, double x1, double x2, 
                                          AsymptoteInfo *asymptotes, int *asymptoteCount) {
  // First check for vertical asymptote pattern (sign change + large gradient)
  bool isVerticalAsymptote = ASYMPTOTECHECKING && detectVerticalAsymptote(y0, y1, y2, grad0, grad1, grad2, x0, x1, x2, count);
  
  if(isVerticalAsymptote && *asymptoteCount < MAX_ASYMPTOTES) {
#ifdef GRAPHDEBUG
    printf("VERTICAL ASYMPTOTE PATTERN DETECTED\n");
#endif
    
    // Calculate asymptote position (midpoint between the sign change)
    double xAsymptote = (x1 + x2) / 2.0;
    double gapWidth = fabs(x2 - x1) * 2.0; // Assume gap extends beyond our sample points
    
    AsymptoteInfo candidateAsymptote;
    
    // For tan-like functions, we know it goes both ways
    candidateAsymptote.x = xAsymptote;
    candidateAsymptote.gapWidth = gapWidth;
    candidateAsymptote.hasPositive = true;  // Assume both directions for now
    candidateAsymptote.hasNegative = true;
    candidateAsymptote.maxHeight = (y_max - y_min) * ASYMPTOTE_HEIGHT_RATIO;
    
    // Store and render the asymptote
    asymptotes[*asymptoteCount] = candidateAsymptote;
    (*asymptoteCount)++;
    
    renderAsymptote(&candidateAsymptote);
    
#ifdef GRAPHDEBUG
    printf("Vertical asymptote rendered at x=%.6f\n", xAsymptote);
#endif
    
    // Return false to prevent normal discontinuity handling since we handled it as asymptote
    return false;
  }
  
  // If not a vertical asymptote, do original discontinuity detection
  bool hasDiscontinuity = detectTrueDiscontinuity(y0, y1, y2, grad0, grad1, grad2, yAvg, count);
  
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
  bool inHighResMode = false;
  double highResStartX = 0;
  double cumulativeCurvatureChange = 0;
  double baselineCurvatureChange = 0;
  double savedXBeforeHighres = 0;
  double savedDxBeforeHighres = dx0;
  int cnt = 0;
  
#ifdef GRAPHDEBUG
  int cycleCount = 0;
  double lastSignChange = x_min;
  int signChangeCount = 0;
#endif

  for(x = x_min; x <= x_max; x += STEP_OFFSET * dx) {
#ifdef GRAPHDEBUG
    printf("\n###################################\n");
    printf("--- Iteration %d: x=%.6f, dx=%.6f ---\n", cnt, x, dx);
#endif
    
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
        bool currentPositive = (y02 > 0);
        bool lastPositive = (y01 > 0);
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
        bool yRatioCheck1 = (fabs(y02/y01) > 1.01 && fabs(grad2/grad1) > SS2);
        bool yRatioCheck2 = (fabs(y01/y02) > 1.01 && fabs(grad1/grad2) > SS2);
        
        // More conservative oscillation detection - only flag if it's truly problematic
        bool signOscillation1 = (ss0 == 1  && ss1 == -1 && ss2 == 1) && 
                               (fabs(y02) > 2 * fabs(y01)) && (fabs(y00) > 2 * fabs(y01));
        bool signOscillation2 = (ss0 == -1 && ss1 == 1  && ss2 == -1) && 
                               (fabs(y02) > 2 * fabs(y01)) && (fabs(y00) > 2 * fabs(y01));
        
        // Zero crossing detection - only if accompanied by large gradient changes
        bool zeroCrossing1 = (ss1 == 1  && ss2 == -1  && y01 > 0 && y02 < 0) && 
                            (fabs(grad2 - grad1) > 10 * fabs(grad1 - grad0));
        bool zeroCrossing2 = (ss1 == -1 && ss2 == 1   && y01 < 0 && y02 > 0) && 
                            (fabs(grad2 - grad1) > 10 * fabs(grad1 - grad0));
        
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
        bool trueDiscontinuity = detectTrueDiscontinuityWithAsymptote(y00, y01, y02, grad0, grad1, grad2, yAvg, count, x00, x01, x, asymptotes, &asymptoteCount);
        if(trueDiscontinuity) {
          discontinuityDetected = FINE;
#ifdef GRAPHDEBUG
          printf("TRUE DISCONTINUITY DETECTED\n");
#endif
        }
      }
      
      // Handle jump-back logic for discontinuities and gradient increases
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
        bool wasDiscontinuity = (discontinuityDetected == FINE);
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
        
        bool shouldCommitPoints = false;
        
        if(wasDiscontinuity) {
          // For discontinuity cases, validate that fine points actually resolve the discontinuity
          bool discontinuityResolved = validateDiscontinuityResolution(
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
            // IMPORTANT: Don't skip the original grid point - restore to original position and let the normal flow handle plotting the original grid point
          }
        } else {
          // For gradient increase cases, evaluate if points add significant detail
          if(jumpBackCount >= 3) {
            // Calculate curvature variation in the jump-back region
            double maxCurvatureChange = 0;
            for(int i = 1; i < jumpBackCount - 1; i++) {
              double g1 = (jumpBackBuffer[i].y - jumpBackBuffer[i-1].y) / 
                         (jumpBackBuffer[i].x - jumpBackBuffer[i-1].x);
              double g2 = (jumpBackBuffer[i+1].y - jumpBackBuffer[i].y) / 
                         (jumpBackBuffer[i+1].x - jumpBackBuffer[i].x);
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
            bool jumpBackPointsUseful = (interpolationError > 0.1 * fabs(jumpBackStartY - y01)) ||
                                       (maxCurvatureChange > fabs(linearSlope) * 0.5);
            
#ifdef GRAPHDEBUG
            printf("  Gradient increase evaluation: maxCurv=%.6f, interpError=%.6f, useful=%d\n", 
                   maxCurvatureChange, interpolationError, jumpBackPointsUseful);
#endif
            
            shouldCommitPoints = jumpBackPointsUseful;
          }
        }
        
        if(shouldCommitPoints) {
          // Commit the fine points
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
        } else {
#ifdef GRAPHDEBUG
          printf("  DISCARDING %d jump-back points, but preserving original grid flow\n", jumpBackCount);
#endif
          // Restore to the original grid point and continue normal processing
          // This ensures the original grid point gets plotted in the normal flow
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
        printf("curvatureChange=%.6f = |(%f-%f)-(%f-%f)|\n", 
               curvatureChange, grad2, grad1, grad1, grad0);
#endif
      }
      
      // Determine new step size and resolution mode
      double newDx = calculateNewStepSize(discontinuityDetected, grad1, grad2, grad2IncreaseDetected, dx0);
      
      // Check if we're entering high-resolution mode (only if not jumped back)
      // Only trigger high-res for genuine curvature issues, not discontinuity-related step reductions
      if(!jumpedBack && !inHighResMode && newDx < prevDx * REVERT_THRESHOLD && 
         discontinuityDetected == 0 && curvatureChange > 0) {
        savedXBeforeHighres = x01;  // Save the last good x position
        savedDxBeforeHighres = prevDx;
#ifdef GRAPHDEBUG
        printf("HIGH-RES TRIGGER: newDx(%.6f) < prevDx(%.6f) * threshold(%.2f) = %.6f\n", 
               newDx, prevDx, REVERT_THRESHOLD, prevDx * REVERT_THRESHOLD);
        printf("Curvature-based trigger: discontinuity=%d, curvatureChange=%.6f\n", 
               discontinuityDetected, curvatureChange);
        printf("Saving state: x=%.6f, dx=%.6f, cycle=%d\n", savedXBeforeHighres, savedDxBeforeHighres, cycleCount);
#endif
        enterHighResMode(&inHighResMode, &highResCount, &highResStartX, &baselineCurvatureChange, &cumulativeCurvatureChange, x, curvatureChange);
      }
#ifdef GRAPHDEBUG
      else if(!jumpedBack && !inHighResMode && newDx < prevDx * REVERT_THRESHOLD) {
        printf("HIGH-RES BLOCKED: newDx(%.6f) < threshold but discontinuity=%d or curvatureChange=%.6f\n", 
               newDx, discontinuityDetected, curvatureChange);
      }
#endif
      
      // If in high-res mode, buffer the point and assess improvement
      if(inHighResMode && !jumpedBack) {
        cumulativeCurvatureChange += curvatureChange;
        
#ifdef GRAPHDEBUG
        printf("HIGH-RES MODE: count=%d/%d, cumCurv=%.6f, baseline=%.6f\n", 
               highResCount, HIGH_RES_SAMPLE_COUNT, cumulativeCurvatureChange, baselineCurvatureChange);
#endif
        
        if(highResCount < HIGH_RES_SAMPLE_COUNT) {
          // Buffer high-res points in order
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
          double improvementRatio = (baselineCurvatureChange > 0) ? 
            cumulativeCurvatureChange / (baselineCurvatureChange * HIGH_RES_SAMPLE_COUNT) : 1.0;
          
#ifdef GRAPHDEBUG
          printf("EVALUATING HIGH-RES: improvementRatio=%.3f (need %.2f)\n", 
                 improvementRatio, MIN_IMPROVEMENT_RATIO);
          printf("  cumCurv=%.6f, baseline*count=%.6f\n", 
                 cumulativeCurvatureChange, baselineCurvatureChange * HIGH_RES_SAMPLE_COUNT);
#endif
          
          if(improvementRatio >= MIN_IMPROVEMENT_RATIO) {
            // High-res was beneficial, commit buffered points in sequence
            commitHighResPointsInOrder(highResBuffer, highResCount);
            resetHighResTracking(&highResCount, &inHighResMode, &cumulativeCurvatureChange);
            // Continue with current step size
          } else {
            // High-res didn't help, abandon and continue from last good point with larger dx
#ifdef GRAPHDEBUG
            printf("HIGH-RES FAILED: reverting to x=%.6f, dx=%.6f\n", 
                   savedXBeforeHighres, savedDxBeforeHighres);
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
    
    cnt++;
  }

#ifdef GRAPHDEBUG
  printf("\n=== GRAPH EQUATION DEBUG END ===\n");
  printf("Total iterations: %d\n", cnt);
  printf("Total sign changes: %d\n", signChangeCount);
  printf("Total half cycles: %d\n", cycleCount);
  printf("================================\n");
#endif
  
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


//###################################################################################
//SOLVER HELPERS

#if !defined(TESTSUITE_BUILD)
static bool_t checkRegisterXYRealZeroTol(calcRegister_t tol) {
  return (real34IsZero(REGISTER_REAL34_DATA(REGISTER_X)) && real34IsZero(REGISTER_REAL34_DATA(REGISTER_Y)))
     || ((real34CompareAbsLessThan(REGISTER_REAL34_DATA(REGISTER_X), REGISTER_REAL34_DATA(tol)))
      && (real34CompareAbsLessThan(REGISTER_REAL34_DATA(REGISTER_Y), REGISTER_REAL34_DATA(tol))));
  }

static bool_t checkRegisterXYImagZeroTol(calcRegister_t tol) {
  return (real34IsZero(REGISTER_IMAG34_DATA(REGISTER_X)) && real34IsZero(REGISTER_IMAG34_DATA(REGISTER_Y)))
     || ((real34CompareAbsLessThan(REGISTER_IMAG34_DATA(REGISTER_X), REGISTER_IMAG34_DATA(tol)))
      && (real34CompareAbsLessThan(REGISTER_IMAG34_DATA(REGISTER_Y), REGISTER_IMAG34_DATA(tol))));
  }

static bool_t checkRegisterXYComplexAbsZeroTol(calcRegister_t tol) {
  if(getRegisterDataType(REGISTER_X) == dtComplex34 && getRegisterDataType(REGISTER_Y) == dtComplex34) {
    runFunction(ITM_ABS);
    runFunction(ITM_XexY);
    runFunction(ITM_ABS);
    runFunction(ITM_XexY);
  }
  return checkRegisterXYRealZeroTol(tol);
  }
#endif // !TESTSUITE_BUILD


//SOLVER

//Solver Registers used and destroyed. This is documented.
//(One day this needs to be rewritten to use reals, at 39 digits)
#define __STARTX0 81
#define __STARTX1 82
#define __TICKS  83
#define __TMP    84
#define __Xold   85
#define __Yold   86
#define __Y0     87
#define __X0     88
#define __X1     89
#define __X2     90
#define __Y1     91
#define __Y2     92
#define __X2N    93
#define __DX     94
#define __DY     95
#define __F      96
#define __TOL    97
#define __L1     98


#if !defined(SAVE_SPACE_DM42_13GRF)
#if !defined(TESTSUITE_BUILD)
  static void complexSolver() {         //Input parameters in registers SREG_STARTX0, SREG_STARTX1
    currentKeyCode = 255;
    if(graphVariabl1 <= 0 || graphVariabl1 > LAST_LABEL) {
      #if defined(PC_BUILD) //PC_BUILD
        printf("Error: No complex solver variable %u\n",graphVariabl1);
      #endif //PC_BUILD
      return;
    }

    calcMode = CM_NO_UNDO;
    calcRegister_t SREG_TMP  = __TMP ;
    calcRegister_t SREG_Xold = __Xold; //: x old difference
    calcRegister_t SREG_Yold = __Yold; //: y old difference
    calcRegister_t SREG_Y0   = __Y0  ; //: y0
    calcRegister_t SREG_X0   = __X0  ; //: x0    //x0 stored but noever recalled
    calcRegister_t SREG_X1   = __X1  ; //: x1
    calcRegister_t SREG_X2   = __X2  ; //: x2
    calcRegister_t SREG_Y1   = __Y1  ; //: y1
    calcRegister_t SREG_Y2   = __Y2  ; //: y2
    calcRegister_t SREG_X2N  = __X2N ; //: temporary new x2
    calcRegister_t SREG_DX   = __DX  ; //: x difference
    calcRegister_t SREG_DY   = __DY  ; //: y diffe rence
    calcRegister_t SREG_F    = __F   ; //: faxctor
    calcRegister_t SREG_TOL  = __TOL ; //: tolerance
    calcRegister_t SREG_L1   = __L1  ; //: temporary stoar
    calcRegister_t SREG_STARTX0 = __STARTX0;
    calcRegister_t SREG_STARTX1 = __STARTX1;
    calcRegister_t SREG_TICKS = __TICKS;

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


    // Initialize all temporary registers
    // Registers are being used in the DEMO data programs

    convertDoubleToReal34RegisterPush(1.0, REGISTER_X);
    fnRCL(SREG_STARTX1);
    runFunction(ITM_MULT);     //Convert input to REAL
    fnStore(SREG_X1);
    convertDoubleToReal34RegisterPush(1.0, REGISTER_X);
    fnRCL(SREG_STARTX0);
    runFunction(ITM_MULT);     //Convert input to REAL

    //if input parameters X0 and X1 are the same, add a random number to X0
    if(real34CompareEqual(REGISTER_REAL34_DATA(SREG_X1), REGISTER_REAL34_DATA(REGISTER_X))) {
      convertDoubleToReal34RegisterPush(1e-3, REGISTER_X);
      #if defined(PC_BUILD)
        printf(">>> ADD random number to second input parameter to prevent infinite result\n");
      #endif
      runFunction(ITM_ADD);
      runFunction(ITM_RAN);
      runFunction(ITM_ADD);
      fnStore(SREG_X0);
    }
    else {
      fnStore(SREG_X0);
    }

    runFunction(ITM_TICKS);
    fnStore(SREG_TICKS);
    convertDoubleToReal34RegisterPush(0.0, REGISTER_X);
    fnStore(SREG_TMP);
    fnStore(SREG_Xold);
    fnStore(SREG_Yold);
    fnStore(SREG_X2N);
    convertDoubleToReal34RegisterPush(CONVERGE_FACTOR, REGISTER_X);
    fnStore(SREG_F);                                     // factor
    convertDoubleToReal34RegisterPush(1E-1, REGISTER_X);
    fnStore(SREG_DX);                                    // initial value for difference comparison must be larger than tolerance
    fnStore(SREG_DY);                                    // initial value for difference comparison must be larger than tolerance

    real_t tol;
    convergenceTolerence(&tol);
    realToReal34(&tol,REGISTER_REAL34_DATA(SREG_TOL));   // tolerance

    fnRCL(SREG_X0);          //determined third starting point using the slope or secant
    execute_rpn_function();
    copySourceRegisterToDestRegister(REGISTER_Y,SREG_Y0);
    fnRCL(SREG_X1);
    execute_rpn_function();
    copySourceRegisterToDestRegister(REGISTER_Y,SREG_Y1);


    checkzero = checkzero ||   regIsLowerThanTol(SREG_Y0,SREG_TOL);
    if(checkzero) {
      copySourceRegisterToDestRegister(SREG_Y0,SREG_Y2);
      copySourceRegisterToDestRegister(SREG_X0,SREG_X2);
    }
    else {
      checkzero = checkzero ||   regIsLowerThanTol(SREG_Y1,SREG_TOL);
      if(checkzero) {
        copySourceRegisterToDestRegister(SREG_Y1,SREG_Y2);
        copySourceRegisterToDestRegister(SREG_X1,SREG_X2);
      }
    }

    if(!checkzero) {
      fnRCL(SREG_X1);
      fnRCL(SREG_X0);
      runFunction(ITM_SUB);                         //dx=x1-x0
      fnRCL(SREG_Y1);
      fnRCL(SREG_Y0);
      runFunction(ITM_SUB);                         //dy=y1-y0
      divFunction(ADD_RAN, SREG_TOL);               //dx/dy
      fnRCL(SREG_Y1);
      runFunction(ITM_MULT);                        //deltaX = x1 - x2 = Y1 / (dy/dx) = Y1 x 1/(dy/dx) = Y1 x dx/dy

      fnRCL(SREG_X1);
      runFunction(ITM_XexY);
      runFunction(ITM_SUB);
      fnStore(SREG_X2);
      execute_rpn_function();
      copySourceRegisterToDestRegister(REGISTER_Y,SREG_Y2);
    }


    #if (defined(VERBOSE_SOLVER00) || defined(VERBOSE_SOLVER0) || defined(VERBOSE_SOLVER1) || defined(VERBOSE_SOLVER2)) && defined(PC_BUILD)
      printf("INIT:   iterationCounter=%d \n",iterationCounter);
      printRegisterToConsole(SREG_X0,"Init X0= ","\n");
      printRegisterToConsole(SREG_X1,"Init X1= ","\n");
      printRegisterToConsole(SREG_X2,"Init X2= ","\n");
      printRegisterToConsole(SREG_Y0,"Init Y0= ","\n");
      printRegisterToConsole(SREG_Y1,"Init Y1= ","\n");
      printRegisterToConsole(SREG_Y2,"Init Y2= ","\n");
    #endif // (VERBOSE_SOLVER00 || VERBOSE_SOLVER0 || VERBOSE_SOLVER1 || VERBOSE_SOLVER2) && PC_BUILD


    //###############################################################################################################
    //#################################################### Iteration start ##########################################
    while(iterationCounter<NUMBERITERATIONS && !checkNaN && !checkzero) {
                                  #if defined(PC_BUILD)
                                    printf("Iteration start\v");
                                  #endif
        if(lastErrorCode != 0) {
                                  #if defined(PC_BUILD)
                                    printf(">>> ERROR CODE INITIALLY NON-ZERO = %d <<<<<\n",lastErrorCode);
                                  #endif //PC_BUILD
        break;
        }

      //Identify oscillations in real or imag: increment osc flag
      //osc = 0;

      if( (real34IsNegative(REGISTER_REAL34_DATA(SREG_DX)) && real34IsPositive(REGISTER_REAL34_DATA(SREG_Xold))) ||
          (real34IsPositive(REGISTER_REAL34_DATA(SREG_DX)) && real34IsNegative(REGISTER_REAL34_DATA(SREG_Xold))) ) {
        DXR = (DXR << 1) + 1;
      }
      else {
        DXR = DXR << 1;
      }

      if( (real34IsNegative(REGISTER_REAL34_DATA(SREG_DY)) && real34IsPositive(REGISTER_REAL34_DATA(SREG_Yold))) ||
          (real34IsPositive(REGISTER_REAL34_DATA(SREG_DY)) && real34IsNegative(REGISTER_REAL34_DATA(SREG_Yold))) ) {
        DYR = (DYR << 1) + 1;
      }
      else {
        DYR = DYR << 1;
      }

      if((getRegisterDataType(SREG_DX) == dtComplex34 && getRegisterDataType(SREG_Xold) == dtComplex34) &&
           ((real34IsNegative(REGISTER_IMAG34_DATA(SREG_DX)) && real34IsPositive(REGISTER_IMAG34_DATA(SREG_Xold))) ||
            (real34IsPositive(REGISTER_IMAG34_DATA(SREG_DX)) && real34IsNegative(REGISTER_IMAG34_DATA(SREG_Xold))) )) {
        DXI = (DXI << 1) + 1;
      }
      else {
        DXI = DXI << 1;
      }

      if((getRegisterDataType(SREG_DY) == dtComplex34 && getRegisterDataType(SREG_Yold) == dtComplex34) &&
           ((real34IsNegative(REGISTER_IMAG34_DATA(SREG_DY)) && real34IsPositive(REGISTER_IMAG34_DATA(SREG_Yold))) ||
            (real34IsPositive(REGISTER_IMAG34_DATA(SREG_DY)) && real34IsNegative(REGISTER_IMAG34_DATA(SREG_Yold))) )) {
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
      if((!real34CompareAbsGreaterThan(REGISTER_REAL34_DATA(SREG_DX), REGISTER_REAL34_DATA(SREG_Xold)) &&
         (getRegisterDataType(SREG_DX) == dtComplex34 && getRegisterDataType(SREG_Xold) == dtComplex34 ?
           !real34CompareAbsGreaterThan(REGISTER_IMAG34_DATA(SREG_DX), REGISTER_IMAG34_DATA(SREG_Xold)) : true))
         &&
         (!real34CompareAbsGreaterThan(REGISTER_REAL34_DATA(SREG_DY), REGISTER_REAL34_DATA(SREG_Yold)) &&
         (getRegisterDataType(SREG_DY) == dtComplex34 && getRegisterDataType(SREG_Yold) == dtComplex34 ?
           !real34CompareAbsGreaterThan(REGISTER_IMAG34_DATA(SREG_DY), REGISTER_IMAG34_DATA(SREG_Yold)) : true))
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
        if(COMPLEXKICKER && (kicker ==0) && (convergent <= 1)) {
          kicker = kicker +2;
        }
        oscillationIterationCounter = 0;
        oscillations = 0;
        convergent = 0;
                                  #if defined(VERBOSE_SOLVER2) && defined(PC_BUILD)
                                    printRegisterToConsole(SREG_X2,"\n>>>>>>>>>> from ","");
                                  #endif // VERBOSE_SOLVER2 && PC_BUILD
        fnRCL(SREG_X2);

        //when kicker = 0, then factor is small negative real, after that, it becomes complex, in the first quardrant, multplied by a alrger number every time
        convertDoubleToReal34RegisterPush(  - (kicker +0.001) / 100.0, REGISTER_X);
        if(kicker > 0) {
          runFunction(ITM_SQUAREROOTX);
          convertDoubleToReal34RegisterPush(    (kicker+0.001) / 100.0, REGISTER_X);
          runFunction(ITM_SQUAREROOTX);
          runFunction(ITM_ADD);
          convertDoubleToReal34RegisterPush(pow(-2.0,kicker), REGISTER_X);
          runFunction(ITM_MULT);
        }
                                  #if (defined(VERBOSE_SOLVER00) || defined(VERBOSE_SOLVER0)) && defined(PC_BUILD)
                                    printf("------- Kicked oscillation, #%d, ", kicker);
                                    printRegisterToConsole(REGISTER_X," multiplied: ","\n");
                                  #endif  // (VERBOSE_SOLVER00 || VERBOSE_SOLVER0) && PC_BUILD
        kicker++;

        runFunction(ITM_MULT);              //add just to force it complex  //
        fnStore(SREG_X2); //replace X2 value                                //

                                  #if defined(VERBOSE_SOLVER2) && defined(PC_BUILD)
                                    printRegisterToConsole(SREG_X2," to ","\n");
                                  #endif // VERBOSE_SOLVER2 && PC_BUILD
      }

      //@@@@@@@@@@@@@@@@@ CALCULATE NEW Y2, AND PLAUSIBILITY @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
      fnRCL(SREG_X2);                                       // get (X2,Y2)
      execute_rpn_function();                               // leaving y2 in Y and x2 in X
      copySourceRegisterToDestRegister(REGISTER_Y,SREG_Y2); // y2

                                  #if defined(VERBOSE_SOLVER1) && defined(PC_BUILD)
                                    printf("    :   iterationCounter=%d",iterationCounter);
                                    printRegisterToConsole(SREG_X2," X2="," ");
                                    printRegisterToConsole(SREG_Y2," Y2=","\n");
                                  #endif // VERBOSE_SOLVER1 && PC_BUILD

      // y2 in Y and x2 in X
      checkzero = checkzero ||   regIsLowerThanTol(SREG_Y2,SREG_TOL);
      checkNaN  = checkNaN  ||   real34IsNaN(REGISTER_REAL34_DATA(SREG_X2)) || (getRegisterDataType(SREG_X2) == dtComplex34 ? real34IsNaN(REGISTER_IMAG34_DATA(SREG_X2)) : 0 ) ||
                                 real34IsNaN(REGISTER_REAL34_DATA(SREG_Y2)) || (getRegisterDataType(SREG_Y2) == dtComplex34 ? real34IsNaN(REGISTER_IMAG34_DATA(SREG_Y2)) : 0 ) ;

                                  #if (defined(VERBOSE_SOLVER00) || defined(VERBOSE_SOLVER0)) && defined(PC_BUILD)
                                    if(checkNaN || iterationCounter==NUMBERITERATIONS-1 || checkzero) {
                                      printf("-->A Endflags zero: Y2r=0:%u Y2i=0:%u X2r=NaN:%u X2i=NaN:%u Y2r=NaN:%u Y2i=NaN%u \n",
                                        (uint16_t)real34IsZero(REGISTER_REAL34_DATA(SREG_Y2)),(uint16_t)real34IsZero(REGISTER_IMAG34_DATA(SREG_Y2)),
                                        (uint16_t)real34IsNaN (REGISTER_REAL34_DATA(SREG_X2)),(uint16_t)real34IsNaN (REGISTER_IMAG34_DATA(SREG_X2)),
                                        (uint16_t)real34IsNaN (REGISTER_REAL34_DATA(SREG_Y2)),(uint16_t)real34IsNaN (REGISTER_IMAG34_DATA(SREG_Y2))
                                        );
                                    }
                                  #endif // (VERBOSE_SOLVER00 || VERBOSE_SOLVER0) && PC_BUILD

                                  #if defined(VERBOSE_SOLVER2) && defined(PC_BUILD)
                                    printf("   iterationCounter=%d checkend=%d X2=",iterationCounter, checkNaN || iterationCounter==NUMBERITERATIONS-1 || checkzero);
                                    printRegisterToConsole(SREG_X2,"","");
                                    printRegisterToConsole(SREG_Y2,"Y2=","\n");
                                  #endif // VERBOSE_SOLVER2 && PC_BUILD

      //*************** DETERMINE DX and DY, to calculate the slope (or the inverse of the slope in this case) *******************
      copySourceRegisterToDestRegister(SREG_DX,SREG_Xold);  // store old DELTA values, for oscillation check
      copySourceRegisterToDestRegister(SREG_DY,SREG_Yold);  // store old DELTA values, for oscillation check

      if(iterationCounter < CHANGE_TO_MOD_SECANT) {              //Secant and Newton approximation methods
        if(iterationCounter < 3)  {
          //###########################
          //  normal Secant, 2-sample slope
          //  DX = X2 - X1 in YREGISTER
          //  DY = Y2 - Y1 in XREGISTER
          //###########################
                                  #if defined(VERBOSE_SOLVER00) || defined(VERBOSE_SOLVER0) || defined(VERBOSE_SOLVER1) || defined(VERBOSE_SOLVER2)
                                    printf("%3i ---------- Using normal Secant dydx 2-samples - osc=%d conv=%d",iterationCounter, oscillations, convergent);
                                  #endif // VERBOSE_SOLVER00 || VERBOSE_SOLVER0 || VERBOSE_SOLVER1 || VERBOSE_SOLVER2
          fnRCL  (SREG_X2); fnRCL(SREG_X1); runFunction(ITM_SUB);      // dx
          fnStore(SREG_DX);                                     // store difference for later
          fnRCL  (SREG_Y2); fnRCL(SREG_Y1); runFunction(ITM_SUB);      // dy
          fnStore(SREG_DY);                                     // store difference for later
          //Leave DX in YREG, and DY in XREG, so DX/DY can be computed
        }

        else {
          //###########################
          // normal secant with 3 sample slope
          //  DX = X2 - X1 in YREGISTER
          //  DY = Y2 - Y1 in XREGISTER
          //###########################
          //  The second order accurate one-sided finite difference formula for the first derivative, formule 32, of
          //  ChE 205 — Formulas for Numerical Differentiation
          //  Handout 5 05/08/02: from Pauli
                                  #if defined(VERBOSE_SOLVER00) || defined(VERBOSE_SOLVER0) || defined(VERBOSE_SOLVER1) || defined(VERBOSE_SOLVER2)
                                    printf("%3i ---------- Using Secant with 3 samples dy/dx -- osc=%d conv=%d",iterationCounter, oscillations, convergent);
                                  #endif // VERBOSE_SOLVER00 || VERBOSE_SOLVER0 || VERBOSE_SOLVER1 || VERBOSE_SOLVER2
          fnRCL      (SREG_X2); fnRCL(SREG_X1); runFunction(ITM_SUB); //Determine x2-x1
          fnStore    (SREG_DX);  //store difference DX for later
          fnRCL      (SREG_X1);
          runFunction(ITM_XexY);
          runFunction(ITM_SUB);
          fnStore    (SREG_X0);          //determine the new x0 by subtracting DX
          execute_rpn_function(); //determine the new f(x0)
          copySourceRegisterToDestRegister(REGISTER_Y,SREG_Y0); //set y0 to the result f(x0)
          //do DX = 2 (x2-x1)
          fnRCL      (SREG_DX);
          convertDoubleToReal34RegisterPush(2.0, REGISTER_X);//calculate 2(x2-x1)
          runFunction(ITM_MULT);             // DX = 2 delta x
          //do DY = (fi−2 − 4fi−1 + 3fi)
          fnRCL      (SREG_Y0);              //y0
          fnRCL      (SREG_Y1);
          convertDoubleToReal34RegisterPush(4.0, REGISTER_X);
          runFunction(ITM_MULT);
          runFunction(ITM_SUB);               //-4.y1
          fnRCL      (SREG_Y2);
          convertDoubleToReal34RegisterPush(3.0, REGISTER_X);
          runFunction(ITM_MULT);
          runFunction(ITM_ADD);                    //+3.y2
          fnStore    (SREG_DY);
          //-3-sample slope-  //Leave DX in YREG, and DY in XREG, so DX/DY can be computed
        }
        //###########################
        //  Start with DX and DY FROM EITHER 2- or 3- SAMPLE SECANT
        //
        //
        //###########################
        divFunction(!ADD_RAN, SREG_TOL);
                                  #if defined(VERBOSE_SOLVER2) && defined(PC_BUILD)
                                    fnInvert(0);
                                    printRegisterToConsole(REGISTER_X," SLOPE=","\n");
                                    fnInvert(0);
                                  #endif // VERBOSE_SOLVER2 && PC_BUILD

        fnRCL(SREG_Y2);      // determine increment in x
        runFunction(ITM_MULT);       // increment to x is: y1 . DX/DY
        fnRCL(SREG_F);       // factor to stabilize Newton method. factor=1 is straight. factor=0.1 converges 10x slower.
        runFunction(ITM_MULT);       // increment to x

                                  #if defined(VERBOSE_SOLVER1) && defined(PC_BUILD)
                                    printRegisterToConsole(SREG_F,"    Factor=        ","\n");
                                    printRegisterToConsole(SREG_X1,"    New X =        "," - ");
                                    printRegisterToConsole(REGISTER_X," - (",")\n");
                                  #endif // VERBOSE_SOLVER1 && PC_BUILD

        fnRCL(SREG_X2);
        runFunction(ITM_XexY);
        runFunction(ITM_SUB);       // subtract as per Newton, x1 - f/f'
        fnStore(SREG_X2N);          // store temporarily to new x2n
                                  #if defined(VERBOSE_SOLVER00) || defined(VERBOSE_SOLVER0) || defined(VERBOSE_SOLVER1) || defined(VERBOSE_SOLVER2)
                                    printf("  ");
                                    printRegisterToConsole(SREG_X2N,"New X=","\n");
                                    //printRegisterToConsole(REGISTER_Y,"Secant DeltaX=","\n");
                                  #endif // VERBOSE_SOLVER00 || VERBOSE_SOLVER0 || VERBOSE_SOLVER1 || VERBOSE_SOLVER2
      }
      else {
        // ---------- Modified 3 point Secant ------------
        if((iterationCounter == 0) || (!checkzero && !checkNaN)) {
                                  #if defined(VERBOSE_SOLVER00) || defined(VERBOSE_SOLVER0) || defined(VERBOSE_SOLVER1) || defined(VERBOSE_SOLVER2)
                                    printf("%3i ---------- Modified 3 point Secant ------------ osc=%d conv=%d",iterationCounter, oscillations, convergent);
                                  #endif // VERBOSE_SOLVER00 || VERBOSE_SOLVER0 || VERBOSE_SOLVER1 || VERBOSE_SOLVER2

          fnRCL(SREG_Y2);fnRCL(SREG_Y0);runFunction(ITM_SUB);fnStore(SREG_DY);
          fnRCL(SREG_X2);fnRCL(SREG_X0);runFunction(ITM_SUB);fnStore(SREG_DX);
          divFunction(!ADD_RAN, SREG_TOL);

          fnStore(SREG_TMP);

                                  #if defined(VERBOSE_SOLVER1) && defined(PC_BUILD)
                                    printRegisterToConsole(SREG_TMP," m1=","\n");
                                  #endif // VERBOSE_SOLVER1 && PC_BUILD

          fnRCL(SREG_Y2);fnRCL(SREG_Y1);runFunction(ITM_SUB);runFunction(ITM_MULT);

                                  #if defined(VERBOSE_SOLVER1) && defined(PC_BUILD)
                                    printRegisterToConsole(REGISTER_X," term1 lower=","\n");
                                  #endif // VERBOSE_SOLVER1 && PC_BUILD
          fnStore(SREG_L1);

          fnRCL(SREG_TMP);
          fnRCL(SREG_Y1);fnRCL(SREG_Y0);runFunction(ITM_SUB);
          fnRCL(SREG_X1);fnRCL(SREG_X0);runFunction(ITM_SUB);
          divFunction(!ADD_RAN, SREG_TOL);

                                  #if defined(VERBOSE_SOLVER1) && defined(PC_BUILD)
                                    printRegisterToConsole(REGISTER_X," m2=","\n");
                                  #endif // VERBOSE_SOLVER1 && PC_BUILD
          runFunction(ITM_SUB);
                                  #if defined(VERBOSE_SOLVER1) && defined(PC_BUILD)
                                    printRegisterToConsole(REGISTER_X," m1-m2 diff=","\n");
                                  #endif // VERBOSE_SOLVER1 && PC_BUILD
          fnRCL(SREG_Y2);
                                  #if defined(VERBOSE_SOLVER1) && defined(PC_BUILD)
                                    printRegisterToConsole(REGISTER_X," Y2=","\n");
                                  #endif // VERBOSE_SOLVER1 && PC_BUILD
          runFunction(ITM_MULT);
                                  #if defined(VERBOSE_SOLVER1) && defined(PC_BUILD)
                                    printRegisterToConsole(REGISTER_X," term2 lower=","\n");
                                  #endif // VERBOSE_SOLVER1 && PC_BUILD
          fnRecall(SREG_L1);
          runFunction(ITM_XexY);
          runFunction(ITM_SUB);
                                  #if defined(VERBOSE_SOLVER1) && defined(PC_BUILD)
                                  printRegisterToConsole(REGISTER_X," lower diff=","\n");
                                  #endif // VERBOSE_SOLVER1 && PC_BUILD
          fnRCL(SREG_Y2);fnRCL(SREG_Y1);runFunction(ITM_SUB);  //Y2-Y1
          runFunction(ITM_XexY);
          //get the 1/slope
          divFunction(!ADD_RAN, SREG_TOL);
          fnStore(SREG_TMP);
                                  #if defined(VERBOSE_SOLVER1) && defined(PC_BUILD)
                                    printRegisterToConsole(REGISTER_X," 1/slope=","\n");
                                  #endif // VERBOSE_SOLVER1 && PC_BUILD
          fnRCL(SREG_Y0);              // determine increment in x
          runFunction(ITM_MULT);       // increment to x is: y1 . DX/DY
          fnRCL(SREG_F);               // factor to stabilize Newton method. factor=1 is straight. factor=0.1 converges 10x slower.
          runFunction(ITM_MULT);       // increment to x
                                  #if defined(VERBOSE_SOLVER1) && defined(PC_BUILD)
                                    printRegisterToConsole(SREG_F,"    Factor=        ","\n");
                                    printRegisterToConsole(SREG_X0,"    New X =        "," - (");
                                    printRegisterToConsole(REGISTER_X,"",")\n");
                                  #endif // VERBOSE_SOLVER1 && PC_BUILD

                                  #if defined(VERBOSE_SOLVER00) || defined(VERBOSE_SOLVER0) || defined(VERBOSE_SOLVER1) || defined(VERBOSE_SOLVER2)
                                    printf("  ");
                                    printRegisterToConsole(REGISTER_X,"DeltaX=","\n");
                                  #endif // VERBOSE_SOLVER00 || VERBOSE_SOLVER0 || VERBOSE_SOLVER1 || VERBOSE_SOLVER2
          fnRCL(SREG_X0);
          runFunction(ITM_XexY);
          runFunction(ITM_SUB);        // subtract as per Newton, x1 - f/f'

          //try round numbers
          if(convergent > 3 && iterationCounter > 6 && oscillations == 0 && real34CompareLessEqual(REGISTER_REAL34_DATA(REGISTER_X),const34_1e_4)) {
            convergent = 0;
            double higherXStartValue = convertRegisterToDouble(REGISTER_X);
            convertDoubleToReal34RegisterPush(roundf(1000.0 * higherXStartValue)/1000.0, REGISTER_X);
          }

          fnStore(SREG_X2N);           // store temporarily to new x2n
        }
      }



      /* Not in use
      //Experimental bisection method to kick out  in case of real arguments
      bool_t bisect = false;
      if(    !checkzero && !checkNaN
          && (    (getRegisterDataType(SREG_Y0) == dtReal34)
               && (getRegisterDataType(SREG_Y2) == dtReal34)
               && (real34CompareAbsGreaterThan(REGISTER_REAL34_DATA(SREG_Y0),const34_1e_6))
               && (real34CompareAbsGreaterThan(REGISTER_REAL34_DATA(SREG_Y2),const34_1e_6))
               && ((    (real34IsNegative(REGISTER_REAL34_DATA(SREG_Y0))) && (real34IsPositive(REGISTER_REAL34_DATA(SREG_Y2))))
                     || ((real34IsNegative(REGISTER_REAL34_DATA(SREG_Y2))) && (real34IsPositive(REGISTER_REAL34_DATA(SREG_Y0))))
                  )
               && !(    (    real34CompareGreaterEqual(REGISTER_REAL34_DATA(SREG_X2N),REGISTER_REAL34_DATA(SREG_X0))
                          && real34CompareGreaterEqual(REGISTER_REAL34_DATA(SREG_X2),REGISTER_REAL34_DATA(SREG_X2N)))
                     ||
                            (real34CompareLessEqual(REGISTER_REAL34_DATA(SREG_X2N),REGISTER_REAL34_DATA(SREG_X0))
                          && real34CompareLessEqual(REGISTER_REAL34_DATA(SREG_X2),REGISTER_REAL34_DATA(SREG_X2N)))
                   )
             )
        ) {
        bisect = true;
        #if defined(VERBOSE_SOLVER00) || defined(VERBOSE_SOLVER0) || defined(VERBOSE_SOLVER1) || defined(VERBOSE_SOLVER2)
          printf(" Using Bisection method: Y bracketed\n");
        #endif // VERBOSE_SOLVER00 || VERBOSE_SOLVER0 || VERBOSE_SOLVER1 || VERBOSE_SOLVER2
      }
      if(bisect) {
        fnRCL(SREG_X0);
        fnRCL(SREG_X2);
        runFunction(ITM_ADD);
        convertDoubleToReal34RegisterPush(2.0, REGISTERX);       //Leaving (x1+x2)/2
        divFunction(!ADD_RAN, SREG_TOL);
        fnStore(SREG_X2N);   // store temporarily to new x2n
      }
      */
      //#############################################


                                  #if defined(VERBOSE_SOLVER1) && defined(PC_BUILD)
                                    printf("               ");printRegisterToConsole(SREG_DX,"DX=","");printRegisterToConsole(SREG_DY,"DY=","\n");
                                    printf("               ");printRegisterToConsole(SREG_X0,"X0=","");printRegisterToConsole(SREG_Y0,"Y0=","\n");
                                    printf("   -------> newX2: ");printRegisterToConsole(SREG_X2N,"","\n");
                                    printf("               ");printRegisterToConsole(SREG_X1,"X1=","");printRegisterToConsole(SREG_Y1,"Y1=","\n");
                                    printf("               ");printRegisterToConsole(SREG_X2,"X2=","");printRegisterToConsole(SREG_Y2,"Y2=","\n");
                                  #endif // VERBOSE_SOLVER1 && PC_BUILD

      copySourceRegisterToDestRegister(SREG_Y1,SREG_Y0); //old y1 copied to y0
      copySourceRegisterToDestRegister(SREG_X1,SREG_X0); //old x1 copied to x0

      copySourceRegisterToDestRegister(SREG_Y2,SREG_Y1); //old y2 copied to y1
      copySourceRegisterToDestRegister(SREG_X2,SREG_X1); //old x2 copied to x1

      fnRCL(SREG_DY);   runFunction(ITM_ABS); //difference |dy| is in Y
      fnRCL(SREG_DX);   runFunction(ITM_ABS); //difference |dx| is in X


      checkzero |= checkRegisterXYRealZeroTol(SREG_TOL);
      checkNaN |=  real34IsNaN(REGISTER_REAL34_DATA(REGISTER_X))
                 || (getRegisterDataType(REGISTER_X) == dtComplex34 ? real34IsNaN(REGISTER_IMAG34_DATA(REGISTER_X)) : 0)
                 || real34IsNaN(REGISTER_REAL34_DATA(REGISTER_Y))
                 || (getRegisterDataType(REGISTER_Y) == dtComplex34 ? real34IsNaN(REGISTER_IMAG34_DATA(REGISTER_Y)) : 0);

                                  #if defined(VERBOSE_SOLVER00) || defined(VERBOSE_SOLVER0) || defined(VERBOSE_SOLVER1)
                                    if(checkzero) {
                                      printf("--B1 Checkzero\n");
                                    }
                                    if(checkNaN) {
                                      printf("--B2 CheckNaN\n");
                                    }
                                    if(checkNaN || iterationCounter==NUMBERITERATIONS-1 || checkzero) {
                                      printf("--B3 Endflags: |DXr|=0:%u |DXr|<TOL:%u  |DXi|=0:%u |DYr|<TOL:%u |DYr|=0:%u |DYi|=0:%u |DXr|=NaN:%u |DXi|=NaN:%u |DYr|=NaN:%u |DYi|=NaN:%u \n",
                                              (uint16_t)real34IsZero(REGISTER_REAL34_DATA(REGISTER_X)),
                                              (uint16_t)(real34CompareAbsLessThan(REGISTER_REAL34_DATA(REGISTER_X), REGISTER_REAL34_DATA(SREG_TOL))),
                                              (uint16_t)real34IsZero(REGISTER_IMAG34_DATA(REGISTER_X)),
                                              (uint16_t)real34IsZero(REGISTER_REAL34_DATA(REGISTER_Y)),
                                              (uint16_t)(real34CompareAbsLessThan(REGISTER_REAL34_DATA(REGISTER_Y), REGISTER_REAL34_DATA(SREG_TOL))),
                                              (uint16_t)real34IsZero(REGISTER_IMAG34_DATA(REGISTER_Y)),
                                              (uint16_t)real34IsNaN (REGISTER_REAL34_DATA(REGISTER_X)),
                                              (uint16_t)real34IsNaN (REGISTER_IMAG34_DATA(REGISTER_X)),
                                              (uint16_t)real34IsNaN (REGISTER_REAL34_DATA(REGISTER_Y)),
                                              (uint16_t)real34IsNaN (REGISTER_IMAG34_DATA(REGISTER_Y))
                                            );
                                    }
                                  #endif // VERBOSE_SOLVER00 || VERBOSE_SOLVER0 || VERBOSE_SOLVER1
      iterationCounter++;
      oscillationIterationCounter++;

                                  #if defined(VERBOSE_SOLVER2) && defined(PC_BUILD)
                                    if(!checkNaN && !(iterationCounter==NUMBERITERATIONS) && !checkzero) {
                                      printf("END     iterationCounter=%d |DX|<TOL:%d ",iterationCounter,real34CompareAbsLessThan(REGISTER_REAL34_DATA(SREG_DX), REGISTER_REAL34_DATA(SREG_TOL)));
                                      printRegisterToConsole(SREG_DX,"","\n");
                                      printf("END     iterationCounter=%d |DY|<TOL:%d ",iterationCounter,real34CompareAbsLessThan(REGISTER_REAL34_DATA(SREG_DY), REGISTER_REAL34_DATA(SREG_TOL)));
                                      printRegisterToConsole(SREG_DY,"","\n");
                                      printRegisterToConsole(REGISTER_Y,"END     DY=","\n");
                                    }
                                  #endif // VERBOSE_SOLVER2 && PC_BUILD

                                  #if defined(VERBOSE_SOLVER1) && defined(PC_BUILD)
                                    printRegisterToConsole(SREG_DX,">>> DX=","");
                                    printRegisterToConsole(SREG_DY," DY=","");
                                    printRegisterToConsole(SREG_TMP," 1/SLOPE=","\n");
                                  #endif // VERBOSE_SOLVER1 && PC_BUILD

      copySourceRegisterToDestRegister(SREG_X2N,SREG_X2);  //new x2

      if(checkHalfSec()) {
        if(progressHalfSecUpdate_Integer(timed, "Iter: ",iterationCounter, halfSec_clearZ, halfSec_clearT, halfSec_disp)) { //timed
          real_t a, ai;
          getRegisterAsComplex(SREG_X1, &a, &ai);
          showProgressReal(&a, &ai, getRegisterDataType(SREG_X1) == dtComplex34);
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
                                    printRegisterToConsole(SREG_X1,"X = "," ");
                                    printRegisterToConsole(REGISTER_Y,"Y = ","\n");
                                  #endif // PC_BUILD

                                  if (ENABLE_COMPLEXSOLVER_FILE_OUTPUT == 1) {
                                    copySourceRegisterToDestRegister(REGISTER_X,REGISTER_K);
                                    copySourceRegisterToDestRegister(SREG_X1,REGISTER_X);
                                    fnP_All_Regs(PRN_XYr);
                                    copySourceRegisterToDestRegister(REGISTER_K,REGISTER_X);
                                  }



    }  //Iteration end

    refreshScreen(200);

    checkNaN =    checkNaN
               || real34IsNaN(REGISTER_REAL34_DATA(SREG_X1))
               || (getRegisterDataType(SREG_X1) == dtComplex34 ? real34IsNaN(REGISTER_IMAG34_DATA(SREG_X1)) : 0)
               || real34IsNaN(REGISTER_REAL34_DATA(SREG_X2))
               || (getRegisterDataType(SREG_X2) == dtComplex34 ? real34IsNaN(REGISTER_IMAG34_DATA(SREG_X2)) : 0);


    bool_t   FLAG_FRACTN = getSystemFlag(FLAG_FRACT);
    clearSystemFlag(FLAG_FRACT);


    bool_t conjugates = false;
    if(getRegisterDataType(SREG_X2) == dtComplex34) {  // do not consider conjugates for Real X
      fnRCL(SREG_X2);
      fnRCL(SREG_X2);                                  // a bit wasteful but the existing tolerance check works for two registers
      runFunction(ITM_CONJ);
      if(!checkRegisterXYImagZeroTol(SREG_TOL)) {      // prevent testing for conjugate recognition for X & Y complex Imag components close to zero, using the tolerance detector  
        execute_rpn_function();
        fnDrop(NOPARAM);
        fnRCL(SREG_Y2);
        conjugates = checkRegisterXYComplexAbsZeroTol(SREG_TOL);
        //printf("conjugates:%d\n",conjugates);
      }
    }


    fnUndo(0);

    if(((iterationCounter > NUMBERITERATIONS) && !checkzero) || checkNaN) {
      temporaryInformation = TI_SOLVER_FAILED;
      displayCalcErrorMessage(ERROR_NO_ROOT_FOUND, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
      convertDoubleToReal34RegisterPush(SOLVER_RESULT_OTHER_FAILURE, REGISTER_X);
    }
    else {
      temporaryInformation = TI_SOLVER_VARIABLE_RESULT;
      lastErrorCode = ERROR_NONE;
      convertDoubleToReal34RegisterPush(conjugates ? (double)SOLVER_RESULT_CONJUGATES : (double)SOLVER_RESULT_NORMAL, REGISTER_X);
    }


    fnRCL(SREG_Y2);
    fnRCL(SREG_X1);
    fnRCL(SREG_X2);
    copySourceRegisterToDestRegister(REGISTER_X, graphVariabl1);

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



#endif //SAVE_SPACE_DM42_13GRF
#endif // !TESTSUITE_BUILD


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
