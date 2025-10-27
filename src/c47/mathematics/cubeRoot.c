// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The C47 Authors

#include "c47.h"

static void curtShoI(void) {
  real_t x;
  int32_t cubeRoot;

  convertShortIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);

  if(realIsPositive(&x)) {
    PowerReal(&x, const_1on3, &x, &ctxtReal39);
  }
  else {
    realSetPositiveSign(&x);
    PowerReal(&x, const_1on3, &x, &ctxtReal39);
    realSetNegativeSign(&x);
  }

  cubeRoot = realToInt32C47(&x);

  if(cubeRoot >= 0) {
    *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = WP34S_build_value((int64_t)cubeRoot, 0);
  }
  else {
    *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = WP34S_build_value(-(int64_t)cubeRoot, 1);
  }
}



void curtReal(void) {
  real_t x;

  if(!getRegisterAsReal(REGISTER_X, &x))
    return;

  if(realIsInfinite(&x) && !getSystemFlag(FLAG_SPCRES)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function curtReal:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of curt when flag D is not set", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  if(realIsPositive(&x)) {
    PowerReal(&x, const_1on3, &x, &ctxtReal39);
  }
  else {
    realSetPositiveSign(&x);
    PowerReal(&x, const_1on3, &x, &ctxtReal39);
    realSetNegativeSign(&x);
  }
  convertRealToResultRegister(&x, REGISTER_X, amNone);
}



static  void curtLonI(void) {
  rootLonI(3);
}



void curtCplx(void) {
  real_t a, b;

  if(getRegisterAsComplex(REGISTER_X, &a, &b)) {
    curtComplex(&a, &b, &a, &b, &ctxtReal39);
    convertComplexToResultRegister(&a, &b, REGISTER_X);
  }
}



void curtComplex(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext) {
  real_t a, b;

  realCopy(real, &a);
  realCopy(imag, &b);

  if(realIsZero(&b)) {
    if(realIsPositive(&a)) {
      PowerReal(&a, const_1on3, resReal, realContext);
    }
    else {
      realSetPositiveSign(&a);
      PowerReal(&a, const_1on3, resReal, realContext);
      realSetNegativeSign(resReal);
    }
    realZero(resImag);
  }
  else {
    realRectangularToPolar(&a, &b, &a, &b, realContext);
    PowerReal(&a, const_1on3, &a, realContext);
    realMultiply(&b, const_1on3, &b, realContext);
    realPolarToRectangular(&a, &b, resReal, resImag, realContext);
  }
}



// Complex cube root using Halley's method: x_{n+1} = x_n * (x_n³ + 2z) / (2x_n³ + z)
void curtComplex159(const real_t *zReal, const real_t *zImag, real_t *resReal, real_t *resImag, realContext_t *realContext) {
  // create 159 constants
  real159_t const159_1on3, const159_root3on2;
  realZero((real_t *)&const159_1on3);
  realZero((real_t *)&const159_root3on2);
  // 1/3 = 1 ÷ 3
  realDivide(const_1, const_3, (real_t *)&const159_1on3, realContext);
  // sqrt(3)/2 = sqrt(3) ÷ 2
  realSquareRoot(const_3, (real_t *)&const159_root3on2, realContext);
  realDivide((real_t *)&const159_root3on2, const_2, (real_t *)&const159_root3on2, realContext);

  real159_t xr, xi, zr, zi;
  real159_t x3r, x3i, temp1r, temp1i, temp2r, temp2i, numr, numi, denomr, denomi, quotr, quoti;
  real159_t temp, denom_mag;
  
  realZero((real_t *)&xr); realZero((real_t *)&xi);
  realZero((real_t *)&zr); realZero((real_t *)&zi);
  realZero((real_t *)&x3r); realZero((real_t *)&x3i);
  realZero((real_t *)&temp1r); realZero((real_t *)&temp1i);
  realZero((real_t *)&temp2r); realZero((real_t *)&temp2i);
  realZero((real_t *)&numr); realZero((real_t *)&numi);
  realZero((real_t *)&denomr); realZero((real_t *)&denomi);
  realZero((real_t *)&quotr); realZero((real_t *)&quoti);
  realZero((real_t *)&temp); realZero((real_t *)&denom_mag);
  
  realCopy(zReal, (real_t *)&zr);
  realCopy(zImag, (real_t *)&zi);
  
  if(realIsZero((real_t *)&zr) && realIsZero((real_t *)&zi)) {
    realZero(resReal);
    realZero(resImag);
    return;
  }


  // Handle pure imaginary case
  if(realIsZero((real_t *)&zr)) {
    // cbrt(0 + bi) where b != 0
    // Use polar: bi = |b| * e^(i*π/2*sign(b))
    // cbrt = |b|^(1/3) * e^(i*π/6*sign(b))
    // = |b|^(1/3) * (cos(π/6*sign(b)) + i*sin(π/6*sign(b)))
    // cos(π/6) = sqrt(3)/2, sin(π/6) = 1/2 for positive
    // cos(-π/6) = sqrt(3)/2, sin(-π/6) = -1/2 for negative
    
    realSetPositiveSign((real_t *)&zi);
    realPower((real_t *)&zi, (real_t *)&const159_1on3, (real_t *)&temp, realContext);
    
    // xr = |zi|^(1/3) * sqrt(3)/2
    realMultiply((real_t *)&temp, (real_t *)&const159_root3on2, (real_t *)&xr, realContext);
    
    // xi = |zi|^(1/3) * 1/2 * sign(zi_original)
    realMultiply((real_t *)&temp, const_1on2, (real_t *)&xi, realContext);
    if(realIsNegative(zImag)) {
      realChangeSign((real_t *)&xi);
    }
    
    realCopy((real_t *)&xr, resReal);
    realCopy((real_t *)&xi, resImag);
    return;
  }

  
  // Handle real-only case (common for real symmetric matrices)
  if(realIsZero((real_t *)&zi)) {
    if(realIsPositive((real_t *)&zr)) {
      realPower((real_t *)&zr, (real_t *)&const159_1on3, (real_t *)&xr, realContext);
      realZero((real_t *)&xi);
    } else {
      realSetPositiveSign((real_t *)&zr);
      realPower((real_t *)&zr, (real_t *)&const159_1on3, (real_t *)&xr, realContext);
      realSetNegativeSign((real_t *)&xr);
      realZero((real_t *)&xi);
      realSetPositiveSign((real_t *)&zr); // Restore sign
      realSetNegativeSign((real_t *)&zr);
    }
    realCopy((real_t *)&xr, resReal);
    realCopy((real_t *)&xi, resImag);
    return;
  }
  
  // Initial guess: x_0 = z^(1/3) ≈ |z|^(1/3) * (cos(θ/3) + i*sin(θ/3))
  // Simplified: use |z|^(1/3) in direction of z
  realMultiply((real_t *)&zr, (real_t *)&zr, (real_t *)&temp, realContext);
  realMultiply((real_t *)&zi, (real_t *)&zi, (real_t *)&denom_mag, realContext);
  realAdd((real_t *)&temp, (real_t *)&denom_mag, (real_t *)&temp, realContext);
  realPower((real_t *)&temp, (real_t *)&const159_1on3, (real_t *)&denom_mag, realContext); // |z|^(1/3)
  
  // Normalize z and scale by |z|^(1/3)
  realSquareRoot((real_t *)&temp, (real_t *)&temp, realContext); // |z|
  realDivide((real_t *)&zr, (real_t *)&temp, (real_t *)&xr, realContext);
  realDivide((real_t *)&zi, (real_t *)&temp, (real_t *)&xi, realContext);
  realMultiply((real_t *)&xr, (real_t *)&denom_mag, (real_t *)&xr, realContext);
  realMultiply((real_t *)&xi, (real_t *)&denom_mag, (real_t *)&xi, realContext);
  
  // Halley's method iterations: x_{n+1} = x_n * (x_n³ + 2z) / (2x_n³ + z)
  for(int iter = 0; iter < 8; iter++) {
    // Compute x³ = x * x²
    // First x² = (xr+xi*i)²
    realMultiply((real_t *)&xr, (real_t *)&xr, (real_t *)&temp1r, realContext);
    realMultiply((real_t *)&xi, (real_t *)&xi, (real_t *)&temp1i, realContext);
    realSubtract((real_t *)&temp1r, (real_t *)&temp1i, (real_t *)&temp1r, realContext); // x²_r
    realMultiply((real_t *)&xr, (real_t *)&xi, (real_t *)&temp1i, realContext);
    realAdd((real_t *)&temp1i, (real_t *)&temp1i, (real_t *)&temp1i, realContext); // x²_i
    
    // Now x³ = x² * x
    realMultiply((real_t *)&temp1r, (real_t *)&xr, (real_t *)&temp, realContext);
    realMultiply((real_t *)&temp1i, (real_t *)&xi, (real_t *)&temp2r, realContext);
    realSubtract((real_t *)&temp, (real_t *)&temp2r, (real_t *)&x3r, realContext);
    
    realMultiply((real_t *)&temp1r, (real_t *)&xi, (real_t *)&temp, realContext);
    realMultiply((real_t *)&temp1i, (real_t *)&xr, (real_t *)&temp2r, realContext);
    realAdd((real_t *)&temp, (real_t *)&temp2r, (real_t *)&x3i, realContext);
    
    // Numerator: x³ + 2z
    realMultiply((real_t *)&zr, const_2, (real_t *)&temp, realContext);
    realAdd((real_t *)&x3r, (real_t *)&temp, (real_t *)&numr, realContext);
    realMultiply((real_t *)&zi, const_2, (real_t *)&temp, realContext);
    realAdd((real_t *)&x3i, (real_t *)&temp, (real_t *)&numi, realContext);
    
    // Denominator: 2x³ + z
    realMultiply((real_t *)&x3r, const_2, (real_t *)&temp, realContext);
    realAdd((real_t *)&temp, (real_t *)&zr, (real_t *)&denomr, realContext);
    realMultiply((real_t *)&x3i, const_2, (real_t *)&temp, realContext);
    realAdd((real_t *)&temp, (real_t *)&zi, (real_t *)&denomi, realContext);
    
    // Quotient: num / denom = (numr+numi*i) / (denomr+denomi*i)
    // = ((numr*denomr + numi*denomi) + (numi*denomr - numr*denomi)*i) / (denomr² + denomi²)
    realMultiply((real_t *)&denomr, (real_t *)&denomr, (real_t *)&temp, realContext);
    realMultiply((real_t *)&denomi, (real_t *)&denomi, (real_t *)&temp2r, realContext);
    realAdd((real_t *)&temp, (real_t *)&temp2r, (real_t *)&denom_mag, realContext);
    
    realMultiply((real_t *)&numr, (real_t *)&denomr, (real_t *)&temp, realContext);
    realMultiply((real_t *)&numi, (real_t *)&denomi, (real_t *)&temp2r, realContext);
    realAdd((real_t *)&temp, (real_t *)&temp2r, (real_t *)&temp, realContext);
    realDivide((real_t *)&temp, (real_t *)&denom_mag, (real_t *)&quotr, realContext);
    
    realMultiply((real_t *)&numi, (real_t *)&denomr, (real_t *)&temp, realContext);
    realMultiply((real_t *)&numr, (real_t *)&denomi, (real_t *)&temp2r, realContext);
    realSubtract((real_t *)&temp, (real_t *)&temp2r, (real_t *)&temp, realContext);
    realDivide((real_t *)&temp, (real_t *)&denom_mag, (real_t *)&quoti, realContext);
    
    // x_{n+1} = x_n * quot = (xr+xi*i) * (quotr+quoti*i)
    realMultiply((real_t *)&xr, (real_t *)&quotr, (real_t *)&temp, realContext);
    realMultiply((real_t *)&xi, (real_t *)&quoti, (real_t *)&temp2r, realContext);
    realSubtract((real_t *)&temp, (real_t *)&temp2r, (real_t *)&temp1r, realContext);
    
    realMultiply((real_t *)&xr, (real_t *)&quoti, (real_t *)&temp, realContext);
    realMultiply((real_t *)&xi, (real_t *)&quotr, (real_t *)&temp2r, realContext);
    realAdd((real_t *)&temp, (real_t *)&temp2r, (real_t *)&temp1i, realContext);
    
    realCopy((real_t *)&temp1r, (real_t *)&xr);
    realCopy((real_t *)&temp1i, (real_t *)&xi);
  }
  
  realCopy((real_t *)&xr, resReal);
  realCopy((real_t *)&xi, resImag);
}




/********************************************//**
 * \brief regX ==> regL and curt(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnCubeRoot(uint16_t unusedButMandatoryParameter) {
  processIntRealComplexMonadicFunction(&curtReal, &curtCplx, &curtShoI, &curtLonI);
}
