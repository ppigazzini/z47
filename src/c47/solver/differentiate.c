// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file differentiate.c
 ***********************************************/

#include "c47.h"

#define MAX_ORDER   5
#define MAX_F_EVAL  (2 * MAX_ORDER + 1)

// Strucutre to hold a variable number of finite difference coefficients
// Refer to https://web.media.mit.edu/~crtaylor/calculator.html for their computation
typedef struct {
    const char *const desc;
    uint8_t n;      // Number of steps from the x, each step is by h in either direction
    uint8_t order;  // Order of the derivative (1 or 2 only at present)
    uint16_t denom; // Denominator of the finite different equation
    int16_t coeff[MAX_F_EVAL]; // Coefficients for each function evaluation point
} FINITE_DIFF_COEFF;

#define FDINFO(n, order, denom, desc)   desc, n, order, denom

#define FDPT5(a, b, c, d, e, z, f, g, h, i, j)  { a, b, c, d, e, z, f, g, h, i, j }
#define FDPT4(a, b, c, d, z, f, g, h, i)        { 0, a, b, c, d, z, f, g, h, i, 0 }
#define FDPT3(a, b, c, z, f, g, h)              { 0, 0, a, b, c, z, f, g, h, 0, 0 }
#define FDPT2(a, b, z, f, g)                    { 0, 0, 0, a, b, z, f, g, 0, 0, 0 }
#define FDPT1(a, z, f)                          { 0, 0, 0, 0, a, z, f, 0, 0, 0, 0 }

#define FDLO5(a, b, c, d, e, z)                 { a, b, c, d, e, z, 0, 0, 0, 0, 0 }
#define FDLO4(a, b, c, d, z)                    { 0, a, b, c, d, z, 0, 0, 0, 0, 0 }
#define FDLO3(a, b, c, z)                       { 0, 0, a, b, c, z, 0, 0, 0, 0, 0 }
#define FDLO2(a, b, z)                          { 0, 0, 0, a, b, z, 0, 0, 0, 0, 0 }
#define FDLO1(a, z)                             { 0, 0, 0, 0, a, z, 0, 0, 0, 0, 0 }

#define FDUP5(z, f, g, h, i, j)                 { 0, 0, 0, 0, 0, z, f, g, h, i, j }
#define FDUP4(z, f, g, h, i)                    { 0, 0, 0, 0, 0, z, f, g, h, i, 0 }
#define FDUP3(z, f, g, h)                       { 0, 0, 0, 0, 0, z, f, g, h, 0, 0 }
#define FDUP2(z, f, g)                          { 0, 0, 0, 0, 0, z, f, g, 0, 0, 0 }
#define FDUP1(z, f)                             { 0, 0, 0, 0, 0, z, f, 0, 0, 0, 0 }


// First derivative central finite difference coefficients
TO_QSPI static const FINITE_DIFF_COEFF der_1_central_2 = {
    FDINFO(1, 1, 2, "1st derivative -1 to 1"),      FDPT1(-1, 0, 1)
};
TO_QSPI static const FINITE_DIFF_COEFF der_1_central_4 = {
    FDINFO(2, 1, 12, "1st derivative -2 to 2"),     FDPT2(1, -8, 0, 8, -1)
};
TO_QSPI static const FINITE_DIFF_COEFF der_1_central_6 = {
    FDINFO(3, 1, 60, "1st derivative -3 to 3"),     FDPT3(-1, 9, -45, 0, 45, -9, 1)
};
TO_QSPI static const FINITE_DIFF_COEFF der_1_central_8 = {
    FDINFO(4, 1, 840, "1st derivative -4 to 4"),    FDPT4(3, -32, 168, -672, 0, 672, -168, 32, -3)
};
TO_QSPI static const FINITE_DIFF_COEFF der_1_central_10 = {
    FDINFO(5, 1, 2520, "1st derivative -5 to 5"),   FDPT5(-2, 25, -150, 600, -2100, 0, 2100, -600, 150, -25, 2)
};

// First derivative upper finite difference coefficients
TO_QSPI static const FINITE_DIFF_COEFF der_1_upper_1 = {
    FDINFO(1, 1, 1, "1st derivative 0 to 1"),       FDUP1(-1, 1)
};
TO_QSPI static const FINITE_DIFF_COEFF der_1_upper_2 = {
    FDINFO(2, 1, 2, "1st derivative 0 to 2"),       FDUP2(-3, 4, -1)
};
TO_QSPI static const FINITE_DIFF_COEFF der_1_upper_3 = {
    FDINFO(3, 1, 6, "1st derivative 0 to 3"),       FDUP3(-11, 18, -9, 2)
};
TO_QSPI static const FINITE_DIFF_COEFF der_1_upper_4 = {
    FDINFO(4, 1, 12, "1st derivative 0 to 4"),      FDUP4(-25, 48, -36, 16, -3)
};
TO_QSPI static const FINITE_DIFF_COEFF der_1_upper_5 = {
    FDINFO(5, 1, 60, "1st derivative 0 to 5"),      FDUP5(-137, 300, -300, 200, -75, 12)
};

// First derivative strictly upper finite difference coefficients
TO_QSPI static const FINITE_DIFF_COEFF der_1_strict_upper_2 = {
    FDINFO(2, 1, 1, "1st derivative 1 to 2"),       FDUP2(0, -1, 1)
};
TO_QSPI static const FINITE_DIFF_COEFF der_1_strict_upper_3 = {
    FDINFO(3, 1, 2, "1st derivative 1 to 3"),       FDUP3(0, -5, 8, -3)
};
TO_QSPI static const FINITE_DIFF_COEFF der_1_strict_upper_4 = {
    FDINFO(4, 1, 6, "1st derivative 1 to 4"),       FDUP4(0, -26, 57, -42, 11)
};
TO_QSPI static const FINITE_DIFF_COEFF der_1_strict_upper_5 = {
    FDINFO(5, 1, 12, "1st derivative 1 to 5"),      FDUP5(0, -77, 214, -234, 122, -25)
};

// First derivative lower finite difference coefficients
TO_QSPI static const FINITE_DIFF_COEFF der_1_lower_1 = {
    FDINFO(1, 1, 1, "1st derivative -1 to 0"),      FDLO1(-1, 1)
};
TO_QSPI static const FINITE_DIFF_COEFF der_1_lower_2 = {
    FDINFO(2, 1, 2, "1st derivative -2 to 0"),      FDLO2(1, -4, 3)
};
TO_QSPI static const FINITE_DIFF_COEFF der_1_lower_3 = {
    FDINFO(3, 1, 6, "1st derivative -3 to 0"),      FDLO3(-2, 9, -18, 11)
};
TO_QSPI static const FINITE_DIFF_COEFF der_1_lower_4 = {
    FDINFO(4, 1, 12, "1st derivative -4 to 0"),     FDLO4(3, -16, 36, -48, 25)
};
TO_QSPI static const FINITE_DIFF_COEFF der_1_lower_5 = {
    FDINFO(5, 1, 60, "1st derivative -5 to 0"),     FDLO5(-12, 75, -200, 300, -300, 137)
};

// First derivative strictly lower finite difference coefficients
TO_QSPI static const FINITE_DIFF_COEFF der_1_strict_lower_2 = {
    FDINFO(2, 1, 1, "1st derivative -2 to -1"),     FDLO2(-1, 1, 0)
};
TO_QSPI static const FINITE_DIFF_COEFF der_1_strict_lower_3 = {
    FDINFO(3, 1, 2, "1st derivative -3 to -1"),     FDLO3(3, -8, 5, 0)
};
TO_QSPI static const FINITE_DIFF_COEFF der_1_strict_lower_4 = {
    FDINFO(4, 1, 6, "1st derivative -4 to -1"),     FDLO4(-11, 42, -57, 26, 0)
};
TO_QSPI static const FINITE_DIFF_COEFF der_1_strict_lower_5 = {
    FDINFO(5, 1, 12, "1st derivative -5 to -1"),    FDLO5(25, -122, 234, -214, 77, 0)
};

// Second derivative central finite difference coefficients
TO_QSPI static const FINITE_DIFF_COEFF der_2_central_2 = {
    FDINFO(1, 2, 2, "2nd derivative -1 to 1"),      FDPT1(1,  -2, 1)
};
TO_QSPI static const FINITE_DIFF_COEFF der_2_central_4 = {
    FDINFO(2, 2, 12, "2nd derivative -2 to 2"),     FDPT2(-1,  16, -30, 16, -1)
};
TO_QSPI static const FINITE_DIFF_COEFF der_2_central_6 = {
    FDINFO(3, 2, 180, "2nd derivative -3 to 3"),    FDPT3(2,  -27, 270, -490, 270, -27, 2)
};
TO_QSPI static const FINITE_DIFF_COEFF der_2_central_8 = {
    FDINFO(4, 2, 5040, "2nd derivative -4 to 4"),   FDPT4(-9, 128, -1008, 8064, -14350, 8064, -1008, 128, -9)
};
// This has -73766 which is out of range for int16_t
//TO_QSPI static const FINITE_DIFF_COEFF der_2_central_10 = {
//    FDINFO(5, 2, 25200, "2nd derivative -5 to 5"),  FDPT5(8, -125, 1000, -6000, 42000, -73766, 4200, -6000, 1000, -125, 8)
//};

// Second derivative upper finite difference coefficients
TO_QSPI static const FINITE_DIFF_COEFF der_2_upper_2 = {
    FDINFO(2, 2, 1, "2nd derivative 0 to 2"),       FDUP2(1, -2, 1)
};
TO_QSPI static const FINITE_DIFF_COEFF der_2_upper_3 = {
    FDINFO(3, 2, 1, "2nd derivative 0 to 3"),       FDUP3(2, -5, 4, -1)
};
TO_QSPI static const FINITE_DIFF_COEFF der_2_upper_4 = {
    FDINFO(4, 2, 12, "2nd derivative 0 to 4"),      FDUP4(35, -104, 114, -56, 11)
};
TO_QSPI static const FINITE_DIFF_COEFF der_2_upper_5 = {
    FDINFO(5, 2, 12, "2nd derivative 0 to 5"),      FDUP5(45, -154, 214, -156, 61, -10)
};

// Second derivative strictly upper finite difference coefficients
TO_QSPI static const FINITE_DIFF_COEFF der_2_strict_upper_3 = {
    FDINFO(3, 2, 1, "2nd derivative 1 to 3"),       FDUP3(0, 1, -2, 1)
};
TO_QSPI static const FINITE_DIFF_COEFF der_2_strict_upper_4 = {
    FDINFO(4, 2, 1, "2nd derivative 1 to 4"),       FDUP4(0, 3, -8, 7, -2)
};
TO_QSPI static const FINITE_DIFF_COEFF der_2_strict_upper_5 = {
    FDINFO(5, 2, 12, "2nd derivative 1 to 5"),      FDUP5(0, 71, -236, 294, -164, 35)
};

// Second derivative lower finite difference coefficients
TO_QSPI static const FINITE_DIFF_COEFF der_2_lower_2 = {
    FDINFO(2, 2, 1, "2nd derivative -2 to 0"),      FDLO2(1, -2, 1)
};
TO_QSPI static const FINITE_DIFF_COEFF der_2_lower_3 = {
    FDINFO(3, 2, 1, "2nd derivative -3 to 0"),      FDLO3(-1, 4, -5, 2)
};
TO_QSPI static const FINITE_DIFF_COEFF der_2_lower_4 = {
    FDINFO(4, 2, 12, "2nd derivative -4 to 0"),     FDLO4(11, -56, 114, -104, 35)
};
TO_QSPI static const FINITE_DIFF_COEFF der_2_lower_5 = {
    FDINFO(5, 2, 12, "2nd derivative -5 to 0"),     FDLO5(-10, 61, -156, 214, -154, 45)
};

// Second derivative strictly lower finite difference coefficients
TO_QSPI static const FINITE_DIFF_COEFF der_2_strict_lower_3 = {
    FDINFO(3, 2, 1, "2nd derivative -3 to -1"),     FDLO3(1, -2, 1, 0)
};
TO_QSPI static const FINITE_DIFF_COEFF der_2_strict_lower_4 = {
    FDINFO(43, 2, 1, "2nd derivative -4 to -1"),    FDLO4(-2, 7, -8, 3, 0)
};
TO_QSPI static const FINITE_DIFF_COEFF der_2_strict_lower_5 = {
    FDINFO(5, 2, 12, "2nd derivative -5 to -1"),    FDLO5(35, -164, 294, -236, 71, 0)
};

// Tables of finite difference coefficients in order of decreasing desirability
TO_QSPI static const FINITE_DIFF_COEFF *const first_central_derivatives[] = {
    &der_1_central_10,      &der_1_central_8,       &der_1_central_6,
    &der_1_central_4,       &der_1_central_2,
    NULL
};

TO_QSPI static const FINITE_DIFF_COEFF *const first_upper_derivatives[] = {
    &der_1_upper_5,         &der_1_upper_4,         &der_1_strict_upper_5,
    &der_1_upper_3,         &der_1_strict_upper_4,  &der_1_upper_2,
    &der_1_strict_upper_3,  &der_1_upper_1,         &der_1_strict_upper_2,
    NULL
};

TO_QSPI static const FINITE_DIFF_COEFF *const first_lower_derivatives[] = {
    &der_1_lower_5,         &der_1_lower_4,         &der_1_strict_lower_5,
    &der_1_lower_3,         &der_1_strict_lower_4,  &der_1_lower_2,
    &der_1_strict_lower_3,  &der_1_lower_1,         &der_1_strict_lower_2,
    NULL
};

TO_QSPI static const FINITE_DIFF_COEFF *const second_central_derivatives[] = {
    // &der_2_central_10
    &der_2_central_8,       &der_2_central_6,       &der_2_central_4,
    &der_2_central_2,
    NULL
};

TO_QSPI static const FINITE_DIFF_COEFF *const second_upper_derivatives[] = {
    &der_2_upper_5,         &der_2_upper_4,         &der_2_strict_upper_5,
    &der_2_upper_3,         &der_2_strict_upper_4,  &der_2_upper_2,
    &der_2_strict_upper_3,
    NULL
};

TO_QSPI static const FINITE_DIFF_COEFF *const second_lower_derivatives[] = {
    &der_2_lower_5,         &der_2_lower_4,         &der_2_strict_lower_5,
    &der_2_lower_3,         &der_2_strict_lower_4,  &der_2_lower_2,
    &der_2_strict_lower_3,
    NULL
};

#if 0
// All of the above finite differences combined into a single array */
TO_QSPI static const FINITE_DIFF_COEFF *const all_first_derivatives[] = {
    &der_1_central_10,      &der_1_central_8,       &der_1_central_6,
    &der_1_central_4,       &der_1_central_2,
    &der_1_upper_5,         &der_1_upper_4,         &der_1_strict_upper_5,
    &der_1_upper_3,         &der_1_strict_upper_4,  &der_1_upper_2,
    &der_1_strict_upper_3,  &der_1_upper_1,         &der_1_strict_upper_2,
    &der_1_lower_5,         &der_1_lower_4,         &der_1_strict_lower_5,
    &der_1_lower_3,         &der_1_strict_lower_4,  &der_1_lower_2,
    &der_1_strict_lower_3,  &der_1_lower_1,         &der_1_strict_lower_2,
    NULL
};
TO_QSPI static const FINITE_DIFF_COEFF *const all_second_derivatives[] = {
    // &der_2_central_10
    &der_2_central_8,       &der_2_central_6,       &der_2_central_4,
    &der_2_central_2,
    &der_2_upper_5,         &der_2_upper_4,         &der_2_strict_upper_5,
    &der_2_upper_3,         &der_2_strict_upper_4,  &der_2_upper_2,
    &der_2_strict_upper_3,
    &der_2_lower_5,         &der_2_lower_4,         &der_2_strict_lower_5,
    &der_2_lower_3,         &der_2_strict_lower_4,  &der_2_lower_2,
    &der_2_strict_lower_3,
    NULL
};
#endif

static void calcDeriv(calcRegister_t label, const FINITE_DIFF_COEFF *const *finDiff);

static void calcDerivOfOrder(uint16_t label, int order) {
  TO_QSPI static const FINITE_DIFF_COEFF *const *const finite_difference_table[] = {
    [DERIVATIVE_FIRST_CENTRAL] = first_central_derivatives,
    [DERIVATIVE_SECOND_CENTRAL] = second_central_derivatives,
    [DERIVATIVE_FIRST_UPPER] = first_upper_derivatives,
    [DERIVATIVE_SECOND_UPPER] = second_upper_derivatives,
    [DERIVATIVE_FIRST_LOWER] = first_lower_derivatives,
    [DERIVATIVE_SECOND_LOWER] = second_lower_derivatives
  };

  calcDeriv(label, finite_difference_table[order]);
}

static void derivativeCommon(uint16_t label, uint16_t order, uint8_t ti) {
  currentSolverStatus &= ~SOLVER_STATUS_USES_FORMULA;
  bool_t solving = getSystemFlag(FLAG_SOLVING);
  setSystemFlag(FLAG_SOLVING);
  if(label >= FIRST_LABEL && label <= LAST_LABEL) {
    calcDerivOfOrder(label, order);
    temporaryInformation = ti;
  }
  else if(REGISTER_X <= label && label <= REGISTER_T) {
    // Interactive mode
    char buf[2];
    buf[0] = letteredRegisterName((calcRegister_t)label);
    buf[1] = 0;
    label = findNamedLabel(buf);
    if(label == INVALID_VARIABLE) {
      displayCalcErrorMessage(ERROR_LABEL_NOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "string '%s' is not a named label", buf);
        moreInfoOnError("In function fn1stDeriv:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
    else {
      calcDerivOfOrder(label, order);
      temporaryInformation = ti;
    }
  }
  else {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "unexpected parameter %u", label);
      moreInfoOnError("In function fn1stDeriv:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  if(!solving) {
    clearSystemFlag(FLAG_SOLVING);
  }
}

void fn1stDeriv(uint16_t label) {
  derivativeCommon(label, DERIVATIVE_FIRST_CENTRAL, TI_1ST_DERIVATIVE);
}

void fn2ndDeriv(uint16_t label) {
  derivativeCommon(label, DERIVATIVE_SECOND_CENTRAL, TI_2ND_DERIVATIVE);
}

static void derivativeEquation(uint16_t order, uint8_t ti) {
    #if !defined(TESTSUITE_BUILD)
    //new method to maintain solver variable
      reallyRunFunction(ITM_RCL, currentSolverVariable);
      copySourceRegisterToDestRegister(REGISTER_X, TEMP_REGISTER_1);
    #endif // TESTSUITE_BUILD
  currentSolverStatus |= SOLVER_STATUS_USES_FORMULA;
  calcDerivOfOrder(INVALID_VARIABLE, order);
    #if !defined(TESTSUITE_BUILD)
      reallyRunFunction(ITM_RCL, TEMP_REGISTER_1);
      reallyRunFunction(ITM_STO, currentSolverVariable);
      fnDrop(NOPARAM);
    #endif // TESTSUITE_BUILD
  temporaryInformation = ti;
}

void fn1stDerivEq(uint16_t unusedButMandatoryParameter) {
  derivativeEquation(DERIVATIVE_FIRST_CENTRAL, TI_1ST_DERIVATIVE);
}

void fn2ndDerivEq(uint16_t unusedButMandatoryParameter) {
  derivativeEquation(DERIVATIVE_SECOND_CENTRAL, TI_2ND_DERIVATIVE);
}

/* The following routines are ported from WP34s. */

static void deriv_found_lbl(calcRegister_t deltaX, real_t *h) {
  execProgram(deltaX);
  fnToReal(NOPARAM);
  if(getRegisterDataType(REGISTER_X) == dtReal34) {
    real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), h);
  }
  else {
    lastErrorCode = ERROR_NONE;
    realCopy(const_1on10, h);
  }
}

static void deriv_default_h(real_t *h) {
  calcRegister_t deltaX;

  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  realToReal34(h, REGISTER_REAL34_DATA(REGISTER_X));
  fnFillStack(NOPARAM);

  dynamicMenuItem = -1;
  if((deltaX = findNamedLabel(STD_delta "x")) != INVALID_VARIABLE) {
    deriv_found_lbl(deltaX, h);
  }
  else if((deltaX = findNamedLabel(STD_delta "X")) != INVALID_VARIABLE) {
    deriv_found_lbl(deltaX, h);
  }
  else if((deltaX = findNamedLabel(STD_DELTA "x")) != INVALID_VARIABLE) {
    deriv_found_lbl(deltaX, h);
  }
  else if((deltaX = findNamedLabel(STD_DELTA "X")) != INVALID_VARIABLE) {
    deriv_found_lbl(deltaX, h);
  }
  else {
    realCopy(const_1on10, h); /* default h = 0.1 */
  }
}


static void _differentiatorIteration(calcRegister_t label, real_t *r0) {
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  realToReal34(r0, REGISTER_REAL34_DATA(REGISTER_X));
  fnFillStack(NOPARAM);

  if(currentSolverStatus & SOLVER_STATUS_USES_FORMULA) {
    #if !defined(TESTSUITE_BUILD)
      //printf("parseEquation\n");
      reallyRunFunction(ITM_STO, currentSolverVariable);
      parseEquation(currentFormula, EQUATION_PARSER_XEQ, tmpString, tmpString + AIM_BUFFER_LENGTH);
    #endif // TESTSUITE_BUILD
  }
  else {
    dynamicMenuItem = -1;
    //printf("Running RPN execProgram\n");
    execProgram(label);
    fnToReal(NOPARAM);
  }

  if(getRegisterDataType(REGISTER_X) == dtReal34) {
    real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), r0);
  }
  else {
    lastErrorCode = ERROR_NONE;
    realCopy(const_NaN, r0);
  }
}

// Try to computer a single derivative estimate from a quadrature
static bool_t calcOneDeriv(const FINITE_DIFF_COEFF *quad, const real_t fx[MAX_F_EVAL],
                           const real_t *h, real_t *r, realContext_t *realContext) {
  uint16_t i;
  real_t t, s;

  // Check if all f(x) are defined or not
  for (i=0; i<MAX_F_EVAL; i++)
    if (quad->coeff[i] != 0 && realIsSpecial(fx + i))
      return false;

  // All values are defined where required so calculate the weighted sum
  realZero(&s);
  for (i=0; i<MAX_F_EVAL; i++)
    if (quad->coeff[i] != 0) {
      int32ToReal(quad->coeff[i], &t);
      realFMA(fx + i, &t, &s, &s, realContext);
    }
  // Inefficiently factor in the derivative order
  // It's not a problem since the order can only be 1 or 2 currently
  // For larger orders we need to divide the result by h^order
  uInt32ToReal(quad->denom, &t);
  for (i=0; i<quad->order; i++)
    realMultiply(&t, h, &t, realContext);
  realDivide(&s, &t, r, realContext);
  return true;
}

// Compute the function values f(x + k h), k = -MAX_ORDER .. MAX_ORDER
static void calcFuncValues(calcRegister_t label, const real_t *x, real_t fx[MAX_F_EVAL],
                           real_t *h, realContext_t *realContext) {
    int i;
    real_t t;

    for (i=0; i < MAX_F_EVAL; i++) {
        int32ToReal(i - MAX_ORDER, &t);
        realFMA(&t, h, x, fx + i, realContext);
        _differentiatorIteration(label, fx + i);
    }
}


// Evaluate the function at quadrature points and computer "best" estimate
static void calcDeriv(calcRegister_t label, const FINITE_DIFF_COEFF *const *finDiff) {
  real_t x, h, fx[MAX_F_EVAL];
  int i;

  if(!getRegisterAsReal(REGISTER_X, &x))
    return;

  if (!realIsSpecial(&x)) {
    deriv_default_h(&h);

    // Compute the function at the finite difference points
    saveForUndo();
    calcFuncValues(label, &x, fx, &h, &ctxtReal39);
    undo();

#if 0
    // This block of code prints out all the function evaluations and
    // all the various derivative estimates.
    {
        char buf[1000];

        for (i=0; i<MAX_F_EVAL; i++)
          printf("f[x+%dh] = %s\n", i - MAX_ORDER, decNumberToString(fx+i, buf));
        for (i=0; finDiff[i] != NULL; i++)
          if (calcOneDeriv(finDiff[i], fx, &h, &x, &ctxtReal39))
            printf("df/dx = %s\t(%s)\n", decNumberToString(&x, buf), finDiff[i]->desc);
    }
#endif
    // Try finite differences until we get a result
    for (i=0; finDiff[i] != NULL; i++)
      if (calcOneDeriv(finDiff[i], fx, &h, &x, &ctxtReal39))
        goto finish;
  }
  // No estimate possible
  realCopy(const_NaN, &x);
finish:
  convertRealToResultRegister(&x, REGISTER_X, amNone);
}

