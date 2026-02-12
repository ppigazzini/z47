// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file tvm.c
 ***********************************************/

#include "c47.h"

#if defined(OPTION_TVM_FORMULAS)

#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  const char * const tvmErrorMessages[] = {
    "TVM: Division by zero",                    // 0
    "TVM: Invalid interest rate",               // 1
    "TVM: Invalid number of periods",           // 2
    "TVM: No solution exists",                  // 3
    "TVM: Logarithm of non-positive number",    // 4
    "TVM: Payment frequency cannot be zero",    // 5
    "TVM: Compound frequency cannot be zero",   // 6
    "TVM: Present value cannot be zero",        // 7
    "TCM: Invalid variable requested"           // 8
  };
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

static int tvmRangeError(int errorCode) {
  displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    moreInfoOnError("In function tvmRangeError:", tvmErrorMessages[errorCode], " Out of range error", NULL);
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  return errorCode;
}

// Calculate effective interest rate per payment period
// ip = (1 + ic)^(CPER/a / PPER/a) - 1 where ic = (I%/a / 100) / CPER/a
static void calculateEffectiveRate(const real_t *iPercentPerYear,
                                    const real_t *compoundPerYear,
                                    const real_t *paymentPerYear,
                                    real_t *ip,
                                    int *error) {
  real_t ic, temp, exponent;
  
  // Check for zero frequencies
  if(decNumberIsZero((decNumber *)compoundPerYear)) {
    *error = tvmRangeError(6);
    return;
  }
  if(decNumberIsZero((decNumber *)paymentPerYear)) {
    *error = tvmRangeError(5);
    return;
  }
  
  // ic = (I%/a / 100) / CPER/a
  realDivide(iPercentPerYear, const_100, &ic, &ctxtReal51);
  realDivide(&ic, compoundPerYear, &ic, &ctxtReal51);
  
  // When CPER/a = PPER/a, ip = ic (shortcut)
  realSubtract(compoundPerYear, paymentPerYear, &temp, &ctxtReal51);
  if(decNumberIsZero((decNumber *)&temp)) {
    realCopy(&ic, ip);
    *error = 0;
    return;
  }
  
  // exponent = CPER/a / PPER/a
  realDivide(compoundPerYear, paymentPerYear, &exponent, &ctxtReal51);
  
  // ip = (1 + ic)^exponent - 1
  realAdd(&ic, const_1, &temp, &ctxtReal51);
  realPower(&temp, &exponent, ip, &ctxtReal51);
  realSubtract(ip, const_1, ip, &ctxtReal51);

  *error = 0;
}

// Calculate Present Value (PV)
// PV = -(1 + ip*p) * (PMT/ip) * [1 - (1+ip)^(-NPPER)] - FV*(1+ip)^(-NPPER)
// with special case when ip = 0: PV = -PMT*NPPER - FV
int calculatePV(const real_t *fv,
                const real_t *iPercentPerYear,
                const real_t *npper,
                const real_t *paymentPerYear,
                const real_t *pmt,
                const real_t *compoundPerYear,
                const real_t *p,
                real_t *pv) {
  real_t ip, temp1, temp2, temp3, negNpper, powerTerm, annuityFactor;
  int error = 0;
  
  calculateEffectiveRate(iPercentPerYear, compoundPerYear, paymentPerYear, &ip, &error);
  if(error != 0) return error;
  
  // Check if ip ≈ 0
  if(realCompareAbsLessThan(&ip, const_1e_37)) {
    // PV = -PMT*NPPER - FV
    realMultiply(pmt, npper, &temp1, &ctxtReal51);
    realAdd(&temp1, fv, pv, &ctxtReal51);
    realSetNegativeSign(pv);
    return 0;
  }
  
  // General case: ip ≠ 0
  // Calculate (1 + ip)^(-NPPER)
  realCopy(npper, &negNpper);
  realSetNegativeSign(&negNpper);
  realAdd(&ip, const_1, &temp1, &ctxtReal51);
  realPower(&temp1, &negNpper, &powerTerm, &ctxtReal51);
  
  // Annuity factor = [1 - (1+ip)^(-NPPER)] / ip
  realSubtract(const_1, &powerTerm, &temp1, &ctxtReal51);
  realDivide(&temp1, &ip, &annuityFactor, &ctxtReal51);
  
  // Payment timing factor = (1 + ip*p)
  realMultiply(&ip, p, &temp1, &ctxtReal51);
  realAdd(&temp1, const_1, &temp2, &ctxtReal51);
  
  // PV from payments = (1 + ip*p) * PMT * annuityFactor
  realMultiply(&temp2, pmt, &temp1, &ctxtReal51);
  realMultiply(&temp1, &annuityFactor, &temp3, &ctxtReal51);
  
  // PV from FV = FV * (1+ip)^(-NPPER)
  realMultiply(fv, &powerTerm, &temp1, &ctxtReal51);
  
  // PV = -(payment part + FV part)
  realAdd(&temp3, &temp1, pv, &ctxtReal51);
  realChangeSign(pv);

  return 0;
}

// Calculate Future Value (FV)
// FV = -PV*(1+ip)^NPPER - (1+ip*p) * (PMT/ip) * [(1+ip)^NPPER - 1]
// Special case when ip = 0: FV = -PV - PMT*NPPER
int calculateFV(const real_t *pv,
                const real_t *iPercentPerYear,
                const real_t *npper,
                const real_t *paymentPerYear,
                const real_t *pmt,
                const real_t *compoundPerYear,
                const real_t *p,
                real_t *fv) {
  real_t ip, temp1, temp2, temp3, powerTerm, annuityFactor;
  int error = 0;
  
  calculateEffectiveRate(iPercentPerYear, compoundPerYear, paymentPerYear, &ip, &error);
  if(error != 0) return error;
  
  // Check if ip ≈ 0 (use special formula)
  if(realCompareAbsLessThan(&ip, const_1e_37)) {
    // FV = -PV - PMT*NPPER
    realMultiply(pmt, npper, &temp1, &ctxtReal51);
    realAdd(pv, &temp1, fv, &ctxtReal51);
    realSetNegativeSign(fv);
    return 0;
  }
  
  // General case: ip ≠ 0
  // Calculate (1 + ip)^NPPER
  realAdd(&ip, const_1, &temp1, &ctxtReal51);
  realPower(&temp1, npper, &powerTerm, &ctxtReal51);
  
  // FV from PV = -PV * (1+ip)^NPPER
  realMultiply(pv, &powerTerm, &temp1, &ctxtReal51);
  realSetNegativeSign(&temp1);
  
  // Annuity factor = [(1+ip)^NPPER - 1] / ip
  realSubtract(&powerTerm, const_1, &temp2, &ctxtReal51);
  realDivide(&temp2, &ip, &annuityFactor, &ctxtReal51);
  
  // Payment timing factor = (1 + ip*p)
  realMultiply(&ip, p, &temp2, &ctxtReal51);
  realAdd(&temp2, const_1, &temp3, &ctxtReal51);
  
  // FV from payments = (1 + ip*p) * PMT * annuityFactor
  realMultiply(&temp3, pmt, &temp2, &ctxtReal51);
  realMultiply(&temp2, &annuityFactor, &temp3, &ctxtReal51);
  
  // FV = PV part - payment part
  realSubtract(&temp1, &temp3, fv, &ctxtReal51);
  
  return 0;
}

// Calculate Payment (PMT)
// PMT = -[PV + FV*(1+ip)^(-NPPER)] * ip / [(1+ip*p) * (1-(1+ip)^(-NPPER))]
// Special case when ip = 0: PMT = -(PV + FV) / NPPER
int calculatePMT(const real_t *pv,
                 const real_t *fv,
                 const real_t *iPercentPerYear,
                 const real_t *npper,
                 const real_t *paymentPerYear,
                 const real_t *compoundPerYear,
                 const real_t *p,
                 real_t *pmt) {
  real_t ip, temp1, temp2, temp3, negNpper, powerTerm, numerator, denominator;
  int error = 0;
  
  // Check for zero periods
  if(decNumberIsZero((decNumber *)npper)) {
    return tvmRangeError(2);
  }
  
  calculateEffectiveRate(iPercentPerYear, compoundPerYear, paymentPerYear, &ip, &error);
  if(error != 0) return error;
  
  // Check if ip ≈ 0 (use special formula)
  if(realCompareAbsLessThan(&ip, const_1e_37)) {
    // PMT = -(PV + FV) / NPPER
    realAdd(pv, fv, &temp1, &ctxtReal51);
    realDivide(&temp1, npper, pmt, &ctxtReal51);
    realSetNegativeSign(pmt);
    return 0;
  }
  
  // General case: ip ≠ 0
  // Calculate (1 + ip)^(-NPPER)
  realCopy(npper, &negNpper);
  realSetNegativeSign(&negNpper);
  realAdd(&ip, const_1, &temp1, &ctxtReal51);
  realPower(&temp1, &negNpper, &powerTerm, &ctxtReal51);
  
  // Numerator = -[PV + FV*(1+ip)^(-NPPER)] * ip
  realMultiply(fv, &powerTerm, &temp1, &ctxtReal51);
  realAdd(pv, &temp1, &temp2, &ctxtReal51);
  realMultiply(&temp2, &ip, &numerator, &ctxtReal51);
  realSetNegativeSign(&numerator);
  
  // Denominator = (1+ip*p) * [1-(1+ip)^(-NPPER)]
  realMultiply(&ip, p, &temp1, &ctxtReal51);
  realAdd(&temp1, const_1, &temp2, &ctxtReal51);
  realSubtract(const_1, &powerTerm, &temp3, &ctxtReal51);
  realMultiply(&temp2, &temp3, &denominator, &ctxtReal51);
  
  // Check for zero denominator
  if(decNumberIsZero((decNumber *)&denominator)) {
    return tvmRangeError(0);
  }
  
  // PMT = numerator / denominator
  realDivide(&numerator, &denominator, pmt, &ctxtReal51);
  
  return 0;
}

// Calculate Number of Payment Periods (NPPER)
// Case 1: PMT = 0: NPPER = ln(-FV/PV) / ln(1+ip)
// Case 2: PMT ≠ 0, ip ≠ 0: NPPER = ln(A/B) / ln(1+ip)
//         where A = -FV*ip + PMT*(1+ip*p)
//               B = PV*ip + PMT*(1+ip*p)
// Case 3: ip = 0: NPPER = -(PV + FV) / PMT
int calculateNPPER(const real_t *pv,
                   const real_t *fv,
                   const real_t *iPercentPerYear,
                   const real_t *paymentPerYear,
                   const real_t *pmt,
                   const real_t *compoundPerYear,
                   const real_t *p,
                   real_t *npper) {
  real_t ip, temp1, temp2, a, b, ratio, lnRatio, lnBase;
  int error = 0;
  
  calculateEffectiveRate(iPercentPerYear, compoundPerYear, paymentPerYear, &ip, &error);
  if(error != 0) return error;
  
  // Check if ip ≈ 0 (use special formula)
  if(realCompareAbsLessThan(&ip, const_1e_37)) {
    // Case 3: NPPER = -(PV + FV) / PMT
    if(decNumberIsZero((decNumber *)pmt)) {
      return tvmRangeError(0);
    }
    realAdd(pv, fv, &temp1, &ctxtReal51);
    realDivide(&temp1, pmt, npper, &ctxtReal51);
    realSetNegativeSign(npper);
    return 0;
  }
  
  // Check if PMT = 0 (simple compound interest)
  if(decNumberIsZero((decNumber *)pmt)) {
    // Case 1: NPPER = ln(-FV/PV) / ln(1+ip)
    // Check for PV = 0 before division
    if(decNumberIsZero((decNumber *)pv)) {
      return tvmRangeError(7);
    }
    
    realDivide(fv, pv, &ratio, &ctxtReal51);
    realSetNegativeSign(&ratio);
    
    // Check for non-positive argument to ln
    if(!realIsPositive(&ratio)) {
      return tvmRangeError(4);
    }
    
    WP34S_Ln(&ratio, &lnRatio, &ctxtReal51);
    realAdd(&ip, const_1, &temp1, &ctxtReal51);
    WP34S_Ln(&temp1, &lnBase, &ctxtReal51);
    
    // Check for zero denominator (should not happen for valid ip, but check anyway)
    if(decNumberIsZero((decNumber *)&lnBase)) {
      return tvmRangeError(0);
    }
    
    realDivide(&lnRatio, &lnBase, npper, &ctxtReal51);
    return 0;
  }
  
  // Case 2: PMT ≠ 0, ip ≠ 0
  // Calculate A = -FV*ip + PMT*(1+ip*p)
  realMultiply(fv, &ip, &temp1, &ctxtReal51);
  realSetNegativeSign(&temp1);
  realMultiply(&ip, p, &temp2, &ctxtReal51);
  realAdd(&temp2, const_1, &temp2, &ctxtReal51);
  realMultiply(pmt, &temp2, &temp2, &ctxtReal51);
  realAdd(&temp1, &temp2, &a, &ctxtReal51);
  
  // Calculate B = PV*ip + PMT*(1+ip*p)
  realMultiply(pv, &ip, &temp1, &ctxtReal51);
  realMultiply(&ip, p, &temp2, &ctxtReal51);
  realAdd(&temp2, const_1, &temp2, &ctxtReal51);
  realMultiply(pmt, &temp2, &temp2, &ctxtReal51);
  realAdd(&temp1, &temp2, &b, &ctxtReal51);
  
  // Check for zero denominator
  if(decNumberIsZero((decNumber *)&b)) {
    return tvmRangeError(0);
  }
  
  // Calculate ratio = A / B
  realDivide(&a, &b, &ratio, &ctxtReal51);
  
  // Check for non-positive argument to ln
  if(!realIsPositive(&ratio)) {
    return tvmRangeError(3);  // No solution
  }
  
  // NPPER = ln(A/B) / ln(1+ip)
  WP34S_Ln(&ratio, &lnRatio, &ctxtReal51);
  realAdd(&ip, const_1, &temp1, &ctxtReal51);
  WP34S_Ln(&temp1, &lnBase, &ctxtReal51);
  
  // Check for zero denominator
  if(decNumberIsZero((decNumber *)&lnBase)) {
    return tvmRangeError(0);
  }
  
  realDivide(&lnRatio, &lnBase, npper, &ctxtReal51);
  
  return 0;
}

// Calculate Payment Periods per Annum (PPER/a)
// From: ip = (1 + ic)^(CPER/a / PPER/a) - 1
// Where: ic = (I%/a / 100) / CPER/a
// Solve: PPER/a = CPER/a * ln(1 + ic) / ln(1 + ip)
// NOTE: This requires knowing the effective rate ip, which comes from
//       solving the main TVM equation. For simple cases (PMT=0), we can
//       calculate it directly. For complex cases, use I%/a solver first.
int calculatePPER(const real_t *pv,
                  const real_t *fv,
                  const real_t *iPercentPerYear,
                  const real_t *npper,
                  const real_t *pmt,
                  const real_t *compoundPerYear,
                  const real_t *p,
                  real_t *paymentPerYear) {
  real_t ic, temp1, temp2, lnBase, lnTarget, ratio;
  real_t ip_effective;
  
  // Check for zero compounding frequency
  if(decNumberIsZero((decNumber *)compoundPerYear)) {
    return tvmRangeError(6);
  }
  
  // Calculate ic = (I%/a / 100) / CPER/a
  realDivide(iPercentPerYear, const_100, &ic, &ctxtReal51);
  realDivide(&ic, compoundPerYear, &ic, &ctxtReal51);
  
  // Calculate effective interest rate ip from the TVM parameters
  // For PMT = 0 (simple compound interest): ip = (-FV/PV)^(1/NPPER) - 1
  
  if(decNumberIsZero((decNumber *)pmt)) {
    // Simple case: compound interest only
    if(decNumberIsZero((decNumber *)pv)) {
      return tvmRangeError(7);
    }
    if(decNumberIsZero((decNumber *)npper)) {
      return tvmRangeError(2);
    }
    
    // ip = (-FV/PV)^(1/NPPER) - 1
    realDivide(fv, pv, &temp1, &ctxtReal51);
    realSetNegativeSign(&temp1);
    
    if(!realIsPositive(&temp1)) {
      return tvmRangeError(3);
    }
    
    realDivide(const_1, npper, &temp2, &ctxtReal51);
    realPower(&temp1, &temp2, &ip_effective, &ctxtReal51);
    realSubtract(&ip_effective, const_1, &ip_effective, &ctxtReal51);
    
  } else {
    // Complex case: with payments
    // This requires solving the full TVM equation for ip, which is iterative
    // User should use their I%/a solver first, then calculate PPER from result
    // For now, we'll return an error indicating this limitation
    return tvmRangeError(3);  // Use I%/a solver first for payment cases
  }
  
  // Check if ic ≈ 0
  if(realCompareAbsLessThan(&ic, const_1e_37)) {
    // When ic ≈ 0, any PPER/a works (indeterminate)
    return tvmRangeError(3);
  }
  
  // Check if ip ≈ ic (special case: PPER/a = CPER/a)
  realSubtract(&ip_effective, &ic, &temp1, &ctxtReal51);
  if(realCompareAbsLessThan(&temp1, const_1e_37)) {
    realCopy(compoundPerYear, paymentPerYear);
    return 0;
  }
  
  // General case: PPER/a = CPER/a * ln(1 + ic) / ln(1 + ip)
  realAdd(&ic, const_1, &temp1, &ctxtReal51);
  if(!realIsPositive(&temp1)) {
    return tvmRangeError(4);
  }
  WP34S_Ln(&temp1, &lnBase, &ctxtReal51);
  
  realAdd(&ip_effective, const_1, &temp1, &ctxtReal51);
  if(!realIsPositive(&temp1)) {
    return tvmRangeError(4);
  }
  WP34S_Ln(&temp1, &lnTarget, &ctxtReal51);
  
  if(decNumberIsZero((decNumber *)&lnTarget)) {
    return tvmRangeError(0);
  }
  
  // PPER/a = CPER/a * ln(1+ic) / ln(1+ip)
  realDivide(&lnBase, &lnTarget, &ratio, &ctxtReal51);
  realMultiply(compoundPerYear, &ratio, paymentPerYear, &ctxtReal51);
  
  if(!realIsPositive(paymentPerYear)) {
    return tvmRangeError(3);
  }
  
  return 0;
}

// Calculate Compounding Periods per Annum (CPER/a)
// From: ip = (1 + ic)^(CPER/a / PPER/a) - 1
// Where: ic = (I%/a / 100) / CPER/a
// This is transcendental in CPER/a, requires iterative solution.
// NOTE: For simple cases (PMT=0), we calculate ip directly.
//       For complex cases, use I%/a solver first.
int calculateCPER(const real_t *pv,
                  const real_t *fv,
                  const real_t *iPercentPerYear,
                  const real_t *npper,
                  const real_t *paymentPerYear,
                  const real_t *pmt,
                  const real_t *p,
                  real_t *compoundPerYear) {
  real_t ip, ic, temp1, temp2;
  real_t exponent, test_ip, error_val, tolerance;
  real_t delta, damping;
  int iterations = 0;
  const int maxIterations = 100;
  
  // Check for zero payment frequency
  if(decNumberIsZero((decNumber *)paymentPerYear)) {
    return tvmRangeError(5);
  }
  
  // Calculate effective interest rate per payment period (ip)
  if(decNumberIsZero((decNumber *)pmt)) {
    // Simple case: compound interest only
    if(decNumberIsZero((decNumber *)pv)) {
      return tvmRangeError(7);
    }
    if(decNumberIsZero((decNumber *)npper)) {
      return tvmRangeError(2);
    }
    
    // ip = (-FV/PV)^(1/NPPER) - 1
    realDivide(fv, pv, &temp1, &ctxtReal51);
    realSetNegativeSign(&temp1);
    
    if(!realIsPositive(&temp1)) {
      return tvmRangeError(3);
    }
    
    realDivide(const_1, npper, &temp2, &ctxtReal51);
    realPower(&temp1, &temp2, &ip, &ctxtReal51);
    realSubtract(&ip, const_1, &ip, &ctxtReal51);
    
  } else {
    // Complex case - use I%/a solver first
    return tvmRangeError(3);
  }
  
  // Iterative solution for CPER/a
  // Equation: (1 + (I%/a/100)/CPER)^(CPER/PPER) - 1 = ip
  
  stringToReal("1e-34", &tolerance, &ctxtReal51);
  
  // Initial guess: CPER/a = PPER/a
  realCopy(paymentPerYear, compoundPerYear);
  
  for(iterations = 0; iterations < maxIterations; iterations++) {
    // ic = (I%/a / 100) / CPER/a
    realDivide(iPercentPerYear, const_100, &ic, &ctxtReal51);
    realDivide(&ic, compoundPerYear, &ic, &ctxtReal51);
    
    // exponent = CPER/a / PPER/a
    realDivide(compoundPerYear, paymentPerYear, &exponent, &ctxtReal51);
    
    // test_ip = (1 + ic)^exponent - 1
    realAdd(&ic, const_1, &temp1, &ctxtReal51);
    realPower(&temp1, &exponent, &test_ip, &ctxtReal51);
    realSubtract(&test_ip, const_1, &test_ip, &ctxtReal51);
    
    // error = test_ip - ip
    realSubtract(&test_ip, &ip, &error_val, &ctxtReal51);
    
    // Check convergence
    if(realCompareAbsLessThan(&error_val, &tolerance)) {
      return 0;
    }
    
    // Newton-Raphson update
    // f(CPER) = (1 + I%/100/CPER)^(CPER/PPER) - 1 - ip
    // f'(CPER) uses quotient and chain rules - complex
    // Use simplified damped iteration instead
    
    realDivide(&error_val, &ip, &temp1, &ctxtReal51);
    realMultiply(&temp1, const_1on2, &delta, &ctxtReal51);  // damping = 0.5
    realSubtract(const_1, &delta, &damping, &ctxtReal51);
    realMultiply(compoundPerYear, &damping, compoundPerYear, &ctxtReal51);
    
    // Keep CPER/a positive
    if(!realIsPositive(compoundPerYear)) {
      realCopy(paymentPerYear, compoundPerYear);
    }
  }
  
  // Failed to converge
  return tvmRangeError(3);
}



  TO_QSPI static const char bugScreenNotForTvmVar[] = "In function solveTvmVariable: this variable is not intended for TVM application!";


// Solve for the specified TVM variable, returns: 0 on success, error code on failure
int solveTvmVariable(uint16_t variable) {
  real_t fv, iA, nPer, pperA, cperA, pmt, pv, p;
  real_t result;
  int error = 0;
  
  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_FV),      &fv);     // Future value
  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_IPONA),   &iA);     // Interest percentage per annum
  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_NPPER),   &nPer);   // Number of periods
  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_PPERONA), &pperA);  // Payment periods per annum
  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_CPERONA), &cperA);  // Compounding periods per annum
  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_PMT),     &pmt);    // Payment
  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_PV),      &pv);     // Present value

  if(getSystemFlag(FLAG_ENDPMT)) {
    int32ToReal(0, &p);  // END mode: p=0
  } else {
    int32ToReal(1, &p);  // BEGIN mode: p=1
  }
  
  switch(variable) {
    case RESERVED_VARIABLE_PV:
      error = calculatePV(&fv, &iA, &nPer, &pperA, &pmt, &cperA, &p, &result);
      if(!error) realToReal34(&result, REGISTER_REAL34_DATA(RESERVED_VARIABLE_PV)      );     // Present value
      break;
      
    case RESERVED_VARIABLE_FV:
      error = calculateFV(&pv, &iA, &nPer, &pperA, &pmt, &cperA, &p, &result);
      if(!error) realToReal34(&result, REGISTER_REAL34_DATA(RESERVED_VARIABLE_FV)      );     // Future value
      break;
      
    case RESERVED_VARIABLE_PMT:
      error = calculatePMT(&pv, &fv, &iA, &nPer, &pperA, &cperA, &p, &result);
      if(!error) realToReal34(&result, REGISTER_REAL34_DATA(RESERVED_VARIABLE_PMT)     );    // Payment
      break;
      
    case RESERVED_VARIABLE_NPPER:
      error = calculateNPPER(&pv, &fv, &iA, &pperA, &pmt, &cperA, &p, &result);
      if(!error) realToReal34(&result, REGISTER_REAL34_DATA(RESERVED_VARIABLE_NPPER)   );   // Number of periods
      break;
      
    case RESERVED_VARIABLE_PPERONA:
      error = calculatePPER(&pv, &fv, &iA, &nPer, &pmt, &cperA, &p, &result);
      if(!error) realToReal34(&result, REGISTER_REAL34_DATA(RESERVED_VARIABLE_PPERONA) );  // Payment periods per annum
      break;
      
    case RESERVED_VARIABLE_CPERONA:
      error = calculateCPER(&pv, &fv, &iA, &nPer, &pperA, &pmt, &p, &result);
      if(!error) realToReal34(&result, REGISTER_REAL34_DATA(RESERVED_VARIABLE_CPERONA) );  // Compounding periods per annum
      break;
            
    default:
      displayBugScreen(bugScreenNotForTvmVar);
      return 8;
  }
  
  if(error != 0) {
    //Not stopping for an error, but letting it through to the old solver for erroring and/or solving
    //displayCalcErrorMessage(ERROR_NO_ROOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function solveTvmVariable:", tvmErrorMessages[error], " Cannot compute TVM equation with current parameters", NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return error;
  }

  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  convertRealToReal34ResultRegister(&result, REGISTER_X);
  setSystemFlag(FLAG_ASLIFT);
  return 0;
}


#endif //OPTION_TVM_FORMULAS


#if defined(TESTSUITE_BUILD)
  #define testing true
#else
  #define testing false
#endif //TESTSUITE_BUILD


  TO_QSPI static const char bugScreenNotForTvm[] = "In function fnTvmVar: this variable is not intended for TVM application!";

void fnTvmVar(uint16_t variable) {
    switch(variable) {
      case RESERVED_VARIABLE_FV:
      case RESERVED_VARIABLE_IPONA:
      case RESERVED_VARIABLE_NPPER:
      case RESERVED_VARIABLE_PPERONA:
      case RESERVED_VARIABLE_CPERONA:
      case RESERVED_VARIABLE_PMT:
      case RESERVED_VARIABLE_PV: {
        currentSolverStatus |= SOLVER_STATUS_TVM_APPLICATION;
        currentSolverVariable = variable;
        tvmIKnown = false;

        /* Calculate */
        if(currentSolverStatus & SOLVER_STATUS_READY_TO_EXECUTE || programRunStop == PGM_RUNNING || programRunStop == PGM_PAUSED || testing) {
          real34_t y, x, resZ, resY, resX;
          saveForUndo();
          thereIsSomethingToUndo = true;
          liftStack();
          tvmIKnown = false;

          #if defined(OPTION_TVM_FORMULAS)
            if(variable != RESERVED_VARIABLE_IPONA) {
              if(solveTvmVariable(variable) == 0) {
                #if defined(PC_BUILD)
                  printf("Success analytical TVM\n");
                #endif //PC_BUILD
                temporaryInformation = TI_SOLVER_VARIABLE;
                return;   // Try analytic solution, if unsuccessful, do the standard solve anyway
              }
            }
          #endif //OPTION_TVM_FORMULAS

          switch(variable) {
            case RESERVED_VARIABLE_IPONA:
            case RESERVED_VARIABLE_PPERONA:
            case RESERVED_VARIABLE_CPERONA: {
              tvmIChanges = true;
              break;
            }
            default: {
              tvmIChanges = false;
            }
          }

          real34Multiply(REGISTER_REAL34_DATA(variable), const34_2, &y);
          real34Multiply(REGISTER_REAL34_DATA(variable), const34_1on2, &x);

          switch(variable) {
            case RESERVED_VARIABLE_PV: {
              if(real34CompareAbsLessThan(REGISTER_REAL34_DATA(RESERVED_VARIABLE_PV),const34_1e_4)) {
                real34Multiply(REGISTER_REAL34_DATA(RESERVED_VARIABLE_FV), const34_2, &y);
                real34Multiply(REGISTER_REAL34_DATA(RESERVED_VARIABLE_FV), const34_1on2, &x);
              }
              break;
            }
            case RESERVED_VARIABLE_FV: {
              if(real34CompareAbsLessThan(REGISTER_REAL34_DATA(RESERVED_VARIABLE_FV),const34_1e_4)) {
                real34Multiply(REGISTER_REAL34_DATA(RESERVED_VARIABLE_PV), const34_2, &y);
                real34Multiply(REGISTER_REAL34_DATA(RESERVED_VARIABLE_PV), const34_1on2, &x);
              }
              break;
            }
            case RESERVED_VARIABLE_IPONA: {
              if(real34CompareAbsLessThan(REGISTER_REAL34_DATA(variable), const34_1on10)) {       //if interest rate p.a. < 0.1% then default to a reasonable 3% to 7% strarting condition
                real34Copy(const34_3, &y); //3
                real34Copy(const34_7, &x); //7
              }
              break;
            }

            case RESERVED_VARIABLE_NPPER: {
              if(real34CompareLessThan(REGISTER_REAL34_DATA(variable), const34_1)) {
                real34Copy(const34_2, &y);
                real34Copy(const34_1, &x);
              }
              break;
            }

            case RESERVED_VARIABLE_CPERONA:
            case RESERVED_VARIABLE_PPERONA: {
              if(real34CompareLessThan(REGISTER_REAL34_DATA(variable), const34_3)) {
                real34Copy(const34_24, &y);
                real34Copy(const34_9, &x);
              }
              break;
            }

            case RESERVED_VARIABLE_PMT: {
              //no special x y cases
              break;
            }
            default:break;
          }

          if((variable == RESERVED_VARIABLE_PV || variable == RESERVED_VARIABLE_FV) &&
            !real34IsZero(REGISTER_REAL34_DATA(RESERVED_VARIABLE_PV)) &&
            !real34IsZero(REGISTER_REAL34_DATA(RESERVED_VARIABLE_FV)) &&
            real34IsNegative(REGISTER_REAL34_DATA(RESERVED_VARIABLE_PV)) == real34IsNegative(REGISTER_REAL34_DATA(RESERVED_VARIABLE_FV))) {
              real34ChangeSign(&y);
              real34ChangeSign(&x);
          }

          if(real34CompareAbsLessThan(&x,const34_1e_4) && real34CompareAbsLessThan(&y,const34_1e_4)) { //still after all the tries, if x & y are still both below 0.0001, then change x to 1 (keeping y = 0)
            real34Copy(const34_1, &x);
          }

          uint16_t iter = 0;
          real34_t xx, yy;

          #define nIter 6
          while(iter++ < nIter || !real34CompareEqual(&resX, &resY)) {
            real34Copy(&x, &xx);
            real34Copy(&y, &yy);
            #if defined(PC_BUILD)
              printReal34ToConsole(&x,"iter x:","\n");
              printReal34ToConsole(&y,"iter y:","\n");
            #endif //PC_BUILD
            uint16_t solveResult = solver(variable, &y, &x, &resZ, &resY, &resX);
            #if defined(PC_BUILD)
              printf("Solve iteration: iter=%u solveResult=%u\n",iter,solveResult);
            #endif //PC_BUILD
            if(solveResult == SOLVER_RESULT_NORMAL) {
              #if defined(PC_BUILD)
                printReal34ToConsole(&resZ,"solver results: resZ:","\n");
                printReal34ToConsole(&resY,"solver results: resY:","\n");
                printReal34ToConsole(&resX,"solver results: resX:","\n");
              #endif //PC_BUILD
              reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
              real34Copy(&resX, REGISTER_REAL34_DATA(REGISTER_X));
              temporaryInformation = TI_SOLVER_VARIABLE;
              thereIsSomethingToUndo = false;
              break;
            }
            else if(solveResult == SOLVER_RESULT_CONSTANT) { // in cases with prevented infinite loop
              iter = nIter;
              break;
            }
            else if(solveResult == SOLVER_RESULT_ABORTED) { // solver aborted
              iter = nIter;
              if(exitKeyWaiting()) {
                break;
              }
            }
            else {
              if(real34IsNegative(&xx)) {
                real34Subtract(&xx, const34_2, &x);
              } else {
                real34Add(&xx, const34_1, &x);
              }
              if(real34IsNegative(&yy)) {
                real34Subtract(&yy, const34_1on2, &y);
              }
              else {
                real34Add(&yy, const34_2, &y);
              }
              real34Multiply(&x, const34_3, &x);
              if((iter+1)%3 == 0) {
                real34ChangeSign(&x);
              }
              real34Multiply(&y, const34_2, &y);
            }
          }

          if(iter == nIter) {
            if(lastErrorCode != ERROR_SOLVER_ABORT) {
              displayCalcErrorMessage(ERROR_NO_ROOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
            }
            #if (EXTRA_INFO_ON_CALC_ERROR == 1)
              moreInfoOnError("In function fnTvmVar:", "cannot compute TVM equation", "with current parameters", NULL);
            #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
          }

          adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
          setSystemFlag(FLAG_ASLIFT);
        }

        /* Store parameters */
        else {
          fnToReal(NOPARAM);
          if(lastErrorCode == ERROR_NONE) {
            reallyRunFunction(ITM_STO, variable);
            if(variable == RESERVED_VARIABLE_PPERONA) {
              reallyRunFunction(ITM_STO, RESERVED_VARIABLE_CPERONA);
            }
            currentSolverStatus |= SOLVER_STATUS_READY_TO_EXECUTE;
            temporaryInformation = TI_SOLVER_VARIABLE;
          }
          adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
          setSystemFlag(FLAG_ASLIFT);
        }
        break;
      }

      default: {
        displayBugScreen(bugScreenNotForTvm);
      }
    }
}



void fnTvmBeginMode(uint16_t unusedButMandatoryParameter) {
  clearSystemFlag(FLAG_ENDPMT);
}

void fnTvmEndMode(uint16_t unusedButMandatoryParameter) {
  setSystemFlag(FLAG_ENDPMT);
}


void fnEff(uint16_t unusedButMandatoryParameter) {
  real_t iA, cperA, tmp;
  //no need to use tvmIKnown or tvmIChanges, as this is a simplistic output only, which takes the current cperA & iA and produces the effective rate. There is no situation where there is no values in these
    //   EFF = 100({[iA / 100cperA] + 1} ^ cperA - 1)

  if(getRegisterAsRealQuiet(RESERVED_VARIABLE_IPONA, &iA) &&
     getRegisterAsRealQuiet(RESERVED_VARIABLE_CPERONA, &cperA) &&
     !realIsZero(&cperA)) {

    saveForUndo();
    thereIsSomethingToUndo = true;
    liftStack();

    iA.exponent -= 2; // iA = iA / 100
    realDivide(&iA, &cperA, &tmp, &ctxtReal39);
    realAdd(&tmp, const_1, &tmp, &ctxtReal39);
    realPower(&tmp, &cperA, &tmp, &ctxtReal39);
    realSubtract(&tmp, const_1, &tmp, &ctxtReal39);
    tmp.exponent += 2; // tmp = tmp * 100

    reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
    convertRealToReal34ResultRegister(&tmp, REGISTER_X);
    temporaryInformation = TI_TVM_EFF;
  } else {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function fnEff:", "cannot compute EFF%/a ", "with parameter cp/a = 0", NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}


void fnEffToI(uint16_t unusedButMandatoryParameter) {
  real_t iEFF, tmp, cperA, cperAInv;
  //no need to use tvmIKnown or tvmIChanges, as this is a simplistic output only, which takes the current cperA & iA and produces the effective rate. There is no situation where there is no values in these
    // iA = {[(EFF / 100 + 1) ^ (1/cperA) ] - 1 } 100 * cperA

  if(getRegisterAsRealQuiet(REGISTER_X, &iEFF) &&
     getRegisterAsRealQuiet(RESERVED_VARIABLE_CPERONA, &cperA) &&
     !realIsZero(&cperA) &&
     realIsPositive(&iEFF)) {

    saveForUndo();
    thereIsSomethingToUndo = true;

    iEFF.exponent -= 2; // iEFF = iEFF / 100
    realAdd(&iEFF, const_1, &tmp, &ctxtReal39);

    realDivide(const_1, &cperA, &cperAInv, &ctxtReal39);
    PowerReal(&tmp, &cperAInv, &tmp, &ctxtReal39);
    realSubtract(&tmp, const_1, &tmp, &ctxtReal39);
    tmp.exponent += 2; // tmp = tmp * 100
    realMultiply(&tmp, &cperA, &tmp, &ctxtReal39);

    realToReal34(&tmp, REGISTER_REAL34_DATA(RESERVED_VARIABLE_IPONA));
    reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
    convertRealToReal34ResultRegister(&tmp, REGISTER_X);

    temporaryInformation = TI_TVM_IA;
  } else {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function fnEffToI:", "cannot compute I%/a ", "with parameters n = 0 & EFF/a < 0 ", NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}





void tvmEquation(void) {
  real_t fv, iA, nPer, pperA, cperA, pmt, pv;
  real_t i1nPer, val, tmp, r;
  static real_t i;

  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_FV),      &fv);     //future value
  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_IPONA),   &iA);     //interest percentage per annum
  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_NPPER),   &nPer);   //number of periods
  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_PPERONA), &pperA);  //payment periods per annum
  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_CPERONA), &cperA);  //compounding periods per annum
  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_PMT),     &pmt);    //payment
  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_PV),      &pv);     //present value
  /*
    The plan is to find an interest rate iM which,
    when compounded pperA times in a year, gives iAER.
    (AER stands for annual effective rate.)
    iAER can be found like this:
    1 + iAER = (1 + (iA/100)/cperA)^cperA
    Also,
    1 + iAER = (1 + iM) ^ pperA.
    So
    iM = (1 + (iA/100)/cperA)^(cperA/pperA) - 1.
    If cperA = pperA this is just iM = (iA/100)/pperA.

    Define r = cperA / pperA. r = 1 corresponds to the "normal" case.
    In terms of r,
    iM = (1 + iA/100/pperA/r)^r - 1.
    This reduces to iM = (iA/100)/pperA when r=1.
    When pperA is set cperA is also set to the same value. So if no value
    is entered for cperA, r will be 1. We can test for this and short-circuit
    the calculation.
    If no value is entered for pperA - perhaps it's being solved for so it's zero
    Can I avoid repeating this calculation each time the TVM equation is called?
    The calculation of i depends on: iA; pperA; cperA. iA could change if i is being solved for;
    similarly, the other two could change as well if being solved for.
    This function doesn't know what is being solved for.
    It takes a lot of iterations to converge but without the calculation of i each time
    these iterations pass much more quickly. So I do need to do something here.
   */

  if((!tvmIKnown) || (tvmIChanges)) { // if i hasn't been found yet or i changes each time
    realDivide(&iA, const_100, &i, &ctxtReal39);
    realDivide(&i, &pperA, &i, &ctxtReal39);
    // i is now (iA / 100) / pperA.
    // This is the "normal" value of i when cperA = pperA.

    realDivide(&cperA, &pperA, &r, &ctxtReal39); // r = cperA / pperA

    if(!(realIsZero(&r) || realCompareEqual(const_1, &r)) ) { // not normal case
      realDivide(&i, &r, &i, &ctxtReal39);
      realAdd(&i, const_1, &i, &ctxtReal39);
      realPower(&i, &r, &i, &ctxtReal39);
      realSubtract(&i, const_1, &i, &ctxtReal39); // i = (1 + (i/pperA)/r)^r - 1
    }
    tvmIKnown = true;
  }

  realChangeSign(&pv);

  realAdd(&i, const_1, &i1nPer, &ctxtReal39);
  realPower(&i1nPer, &nPer, &i1nPer, &ctxtReal39);

  if(getSystemFlag(FLAG_ENDPMT)) {
    realCopy(const_1, &val); // END mode
  }
  else {
    realAdd(const_1, &i, &val, &ctxtReal39); // BEGIN mode
  }

  realMultiply(&val, &pmt, &val, &ctxtReal39);
  if(realCompareAbsLessThan(&i,const_1e_37)) {    //prevent infinity when i = 0, to continue work
    realCopy(const_1e_37,&i);
  }
  realDivide(&val, &i, &val, &ctxtReal39);

  realSubtract(const_1, &i1nPer, &tmp, &ctxtReal39);
  realMultiply(&val, &tmp, &val, &ctxtReal39);

  realFMA(&pv, &i1nPer, &val, &val, &ctxtReal39);
  realSubtract(&val, &fv, &val, &ctxtReal39);

  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  convertRealToReal34ResultRegister(&val, REGISTER_X);
}
