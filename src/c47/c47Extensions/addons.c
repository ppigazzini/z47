// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

#include "c47.h"

/*
Math changes:

1. addon.c: Added fnArg_all which uses fnArg, but gives a result of 0 for a real
   and longint input. The testSuite is not ifluenced. Not needed to modify |x|,
   as it already works for a real and longint.
   (testSuite not in use for fnArg, therefore also not added)

2. bufferize.c: closenim: changed the default for (0 CC EXIT to 0) instead of i.
   (testSuite not ifluenced).

Todo


All the below: because both Last x and savestack does not work due to multiple steps.

  5. Added Star > Delta. Change and put in separate c file, and sort out savestack.
  6. vice versa
  7. SYM>ABC
  8. ABC>SYM
  9. e^theta. redo in math file,
  10. three phase Ohms Law: 17,18,19


 Check for savestack in jm.c
*/

#if !defined(TESTSUITE_BUILD)
  static void getStringLabelOrVariableName(uint8_t *stringAddress) {
    uint8_t stringLength = *(uint8_t *)(stringAddress++);
    xcopy(tmpStringLabelOrVariableName, stringAddress, stringLength);
    tmpStringLabelOrVariableName[stringLength] = 0;
  }
#endif // !TESTSUITE_BUILD


void fractionToString(calcRegister_t regist, char *displayString, int16_t *lessEqualGreater) {
  int16_t  sign;
  uint64_t intPart, numer, denom;

  fraction(regist, &sign, &intPart, &numer, &denom, lessEqualGreater);

  if(getSystemFlag(FLAG_PROPFR)) { // a b/c
    sprintf(displayString, "%s%" PRIu32 " %" PRIu32 "/%" PRIu32, (sign == -1 ? "-" : "+"), (uint32_t)intPart, (uint32_t)numer, (uint32_t)denom);
  }

  else { // FT_IMPROPER d/
    sprintf(displayString, "%s0 %" PRIu32 "/%" PRIu32, (sign == -1 ? "-" : "+"), (uint32_t)numer, (uint32_t)denom);

  }
}

void shortIntegerToString(calcRegister_t regist, char *displayString) {
  int16_t i, j, k, unit, base;
  uint64_t number, sign;

  base    = getRegisterTag(regist);
  number  = *(REGISTER_SHORT_INTEGER_DATA(regist));

  if(base <= 1 || base >= 17) {
    sprintf(errorMessage, commonBugScreenMessages[bugMsgValueFor], "shortIntegerToString", base, "base");
    displayBugScreen(errorMessage);
    base = 10;
  }

  //number &= shortIntegerMask;

  if(shortIntegerMode == SIM_UNSIGN || base == 2 || base == 4 || base == 8 || base == 16) {
    sign = 0;
  }
  else {
    sign = number & shortIntegerSignBit;
  }

  if(sign) {
    if(shortIntegerMode == SIM_2COMPL) {
      number |= ~shortIntegerMask;
      number = ~number + 1;
    }
    else if(shortIntegerMode == SIM_1COMPL) {
      number = ~number;
    }
    else if(shortIntegerMode == SIM_SIGNMT) {
      number &= ~shortIntegerSignBit;
    }
    else {
      sprintf(errorMessage, commonBugScreenMessages[bugMsgValueFor], "shortIntegerToString", shortIntegerMode, "shortIntegerMode");
      displayBugScreen(errorMessage);
    }

    number &= shortIntegerMask;
  }

  i = ERROR_MESSAGE_LENGTH / 2;

  if(number == 0) {
    displayString[i++] = '0';
  }

  while(number) {
    unit = number % base;
    number /= base;
    displayString[i++] = hexadecimalDigits[unit];
  }

  if(sign) {
    displayString[i++] = '-';
  }
  else {
    displayString[i++] = '+';
  }

  for(k=i-1, j=0; k>=ERROR_MESSAGE_LENGTH / 2; k--, j++) {
    if(displayString[k] == ' ') {
      displayString[j++] = STD_SPACE_PUNCTUATION[0];
      displayString[j]   = STD_SPACE_PUNCTUATION[1];
    }
    else {
      displayString[j] = displayString[k];
    }
  }
  displayString[j] = 0;

  return;
}


#if !defined(TESTSUITE_BUILD)
static void _hmsTimeToReal() {
  int16_t i = 0;
  int16_t j = 0;
  bool decimalflag = false;

  timeToDisplayString(REGISTER_X, tmpString, true);

  while(tmpString[i] != 0) {
    switch((uint8_t)tmpString[i]) {
      case '0' :
      case '1' :
      case '2' :
      case '3' :
      case '4' :
      case '5' :
      case '6' :
      case '7' :
      case '8' :
      case '9' :
      case '+' :
      case '-' :
        tmpString[j++] = (uint8_t)tmpString[i];
        break;
      case ':' :
        if(!decimalflag) {
          decimalflag = true;
          tmpString[j++] = '.';
        }
        break;
      default:
        break;
    }
    i++;
  }
  tmpString[j] = 0;

  if(tmpString[0] != 0) {
    reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BYTES, amNone);
    stringToReal34(tmpString, REGISTER_REAL34_DATA(REGISTER_X));
  }
}


static void _real34ToNim(const real34_t *real34, char *nimInput, char *nimDisplay) {
// nimInput   : used to fill aimBuffer
// nimDisplay : used to fill nimBufferDisplay
  uint16_t i;
  uint8_t grpGroupingLeftOld  = grpGroupingLeft;
  uint8_t grpGroupingRightOld = grpGroupingRight;

  grpGroupingLeft  = 0;
  grpGroupingRight = 0;
  real34ToDisplayString(real34, amNone, tmpString, &standardFont, SCREEN_WIDTH, NUMBER_OF_DISPLAY_DIGITS, true, STD_SPACE_PUNCTUATION, true);
  grpGroupingRight = grpGroupingRightOld;
  grpGroupingLeft  = grpGroupingLeftOld;
  //printf("**[DL]** _real34ToNim tmpString %s\n",tmpString);fflush(stdout);

  bool noDisplayExponent = true;
  for(i = 0; i < strlen(tmpString); i++) {
    if((tmpString[i] == STD_SUB_10[0]) && (tmpString[i+1] == STD_SUB_10[1])) {
      noDisplayExponent = false;
    }
  }
  grpGroupingLeft  = 0;
  grpGroupingRight = 0;
  real34ToString(real34, nimDisplay);
  grpGroupingRight = grpGroupingRightOld;
  grpGroupingLeft  = grpGroupingLeftOld;
  //printf("**[DL]** _real34ToNim nimBufferDisplay %s\n",nimBufferDisplay);fflush(stdout);
  bool dotFound = false;
  if(noDisplayExponent) {                                // if no exponent in display string but exponent in real34ToString, use the display string
    for(i = 0; i < strlen(nimDisplay); i++) {
      if((nimDisplay[i] == 'e') || (nimDisplay[i] == 'E')) {
        strcpy(nimDisplay, tmpString + (tmpString[0] == '-'? 0 : 1));
        break;
      }
      if(nimDisplay[i] == '.') {
        dotFound = true;
      }
    }
    if(dotFound) {
      for(i = strlen(nimDisplay)-1; i > 0; i--) {
        if(nimDisplay[i] == '0') {
          nimDisplay[i] = 0;              // remove trailing zeros
        }
        else {
          break;
        }
      }
    }
  }
  if(real34IsPositive(real34)) {
    nimInput[0] = '+';
    strcpy(nimInput + 1, nimDisplay);
  }
  else {
    strcpy(nimInput, nimDisplay);
  }
  //printf("**[DL]** _real34ToNim nimInput %s\n",nimInput);fflush(stdout);
  bool exponentFound = false;
  dotFound = false;
  for(i = 0; i < strlen(nimInput); i++) {
    if(nimInput[i] == 'E') {
      nimInput[i] = 'e';
      dotFound = true;
      exponentFound = true;
      exponentSignLocation = i + 1;
      nimNumberPart = NP_REAL_EXPONENT;
    }
    if(nimInput[i] == '.') {
      dotFound = true;
      nimNumberPart = NP_REAL_FLOAT_PART;
    }
  }
  if(!dotFound) {
    nimInput[i] = '.';
    nimNumberPart = NP_REAL_FLOAT_PART;
  }
  strcpy(nimDisplay, STD_SPACE_HAIR);
  nimBufferToDisplayBuffer(nimInput, nimDisplay + 2);
  //printf("**[DL]** _real34ToNim nimDisplay %s\n",nimDisplay+2);fflush(stdout);
  for(i=stringByteLength(nimDisplay) - 1; i>0; i--) {
    if(nimDisplay[i] == (char)0xab) {    //token
      nimDisplay[i] = SEPARATOR_LEFT[0];
      if(nimDisplay[i+1] == 1) {
        nimDisplay[i+1] = SEPARATOR_LEFT[1];
      }
    }
    if(nimDisplay[i] == (char)0xbb) {    //token
      nimDisplay[i] = SEPARATOR_RIGHT[0];
      if(nimDisplay[i+1] == 1) {
        nimDisplay[i+1] = SEPARATOR_RIGHT[1];
      }
    }
  }
  if(exponentFound) {
    exponentToDisplayString(stringToInt32(nimInput + exponentSignLocation), nimDisplay + stringByteLength(nimDisplay), NULL, true);
    if(nimInput[exponentSignLocation + 1] == 0 && nimInput[exponentSignLocation] == '-') {
      strcat(nimDisplay, STD_SUP_MINUS);
    }
    else if(nimInput[exponentSignLocation + 1] == '0' && nimInput[exponentSignLocation] == '+') {
      strcat(nimDisplay, STD_SUP_0);
    }
  }
}
#endif // !TESTSUITE_BUILD






void C47Cvt2RadSinCosTan2(real1071_t *an, angularMode_t angularMode, real1071_t *sinOut, real1071_t *cosOut, real1071_t *tanOut, realContext_t *realContext, int acc) {
  C47_WP34S_Cvt2RadSinCosTan((real_t*)an, angularMode, (real_t*)sinOut, (real_t*)cosOut, (real_t*)tanOut, realContext);
}

// Replacement Taylor sin/cos/tan function for high accuracy
// Capable of 1071 digit input and a final accuracy parameter, being the number of required digits.
//
// Only the mod reduction needs double the digits. The Taylor function has 1071 only, and the internal angle manipulation (and reduction) is on 1071.
// That means the major bignumber  reduction must be done outside Taylor

#undef DEBUG_XFN


#if !defined(PC_BUILD)
  #undef DEBUG_XFN
#endif

#define debugLongNumberLimit 100
#define modulus(a)            (a == amRadian ? const2139_2pi : a == amDegree ? const_360 : a == amGrad ? const_400 : a == amMultPi ? const_2 : const_1)


// Tightly based on the original wp34 module in the C47 code : 2025-08-17 JM
// Especially convergence modified
void WP34S_Atan1071(real1071_t *x, real1071_t *angle, realContext_t *realContext, int accNumberDigits) {
  real1071_t a, b, a2, t, j, z, last, epsilon; //-- added epsilon for convergence
  int doubles = 0;
  int invert;
  int n;
  int neg = realIsNegative((real_t*)x);
  char tmpEpsilon[16]; //-- for epsilon string conversion

  if(realIsNaN((real_t*)x)) {
    realCopy(const_NaN, (real_t*)angle);
    return;
  }

  realCopy((real_t*)x, (real_t*)&a);

  // arrange for a >= 0
  if(neg) {
    realChangeSign((real_t*)&a);
  }

  // reduce range to 0 <= a < 1, using atan(x) = pi/2 - atan(1/x)
  invert = realCompareGreaterThan((real_t*)&a, const_1);
  if(invert) {
    realDivide(const_1, (real_t*)&a, (real_t*)&a, realContext);
  }

  // Range reduce to small enough limit to use taylor series using:
  //  tan(x/2) = tan(x)/(1+sqrt(1+tan(x)²))
  //-- create const_1on10 equivalent for 1071 precision
  uInt32ToReal(10, (real_t*)&z);
  realDivide(const_1, (real_t*)&z, (real_t*)&z, realContext);
  for(n=0; n<1000; n++) {
    if(realCompareLessEqual((real_t*)&a, (real_t*)&z)) {
      break;
    }
    doubles++;
    // a = a/(1+sqrt(1+a²)) -- at most 3 iterations.
    realMultiply((real_t*)&a, (real_t*)&a, (real_t*)&b, realContext);
    realAdd((real_t*)&b, const_1, (real_t*)&b, realContext);
    realSquareRoot((real_t*)&b, (real_t*)&b, realContext);
    realAdd((real_t*)&b, const_1, (real_t*)&b, realContext);
    realDivide((real_t*)&a, (real_t*)&b, (real_t*)&a, realContext);
  }

  // Now Taylor series
  // atan(x) = x(1-x²/3+x⁴/5-x⁶/7...)
  // We calculate pairs of terms and stop when the estimate doesn't change
  //-- use epsilon convergence instead of exact equality
  sprintf(tmpEpsilon, "1E-%d", accNumberDigits);
  stringToReal(tmpEpsilon, (real_t*)&epsilon, realContext);

  uInt32ToReal(3, (real_t*)angle);
  uInt32ToReal(5, (real_t*)&j);
  realMultiply((real_t*)&a, (real_t*)&a, (real_t*)&a2, realContext); // a²
  realCopy((real_t*)&a2, (real_t*)&t);
  realDivide((real_t*)&t, (real_t*)angle, (real_t*)angle, realContext); // s = 1-t/3 -- first two terms
  realSubtract(const_1, (real_t*)angle, (real_t*)angle, realContext);

  do { // Loop until there is no digits changed
    realCopy((real_t*)angle, (real_t*)&last);

    realMultiply((real_t*)&t, (real_t*)&a2, (real_t*)&t, realContext);
    realDivide((real_t*)&t, (real_t*)&j, (real_t*)&z, realContext);
    realAdd((real_t*)angle, (real_t*)&z, (real_t*)angle, realContext);

    realAdd((real_t*)&j, const_2, (real_t*)&j, realContext);

    realMultiply((real_t*)&t, (real_t*)&a2, (real_t*)&t, realContext);
    realDivide((real_t*)&t, (real_t*)&j, (real_t*)&z, realContext);
    realSubtract((real_t*)angle, (real_t*)&z, (real_t*)angle, realContext);

    realAdd((real_t*)&j, const_2, (real_t*)&j, realContext);

    //-- use epsilon convergence test instead of exact equality
    realSubtract((real_t*)angle, (real_t*)&last, (real_t*)&b, realContext);
    realCopyAbs((real_t*)&b, (real_t*)&b);
  } while(!realCompareLessThan((real_t*)&b, (real_t*)&epsilon));

  realMultiply((real_t*)angle, (real_t*)&a, (real_t*)angle, realContext);

  while(doubles) {
    realAdd((real_t*)angle, (real_t*)angle, (real_t*)angle, realContext);
    doubles--;
  }

  if(invert) {
    realSubtract(const1071_piOn2, (real_t*)angle, (real_t*)angle, realContext);
  }

  if(neg) {
    realChangeSign((real_t*)angle);
  }
}

// Tightly based on the original wp34 module in the C47 code : 2025-08-17 JM
void WP34S_Asin1071(real1071_t *x, real1071_t *angle, realContext_t *realContext, int accNumberDigits) {
  real1071_t abx, z;

  if(realIsNaN((real_t*)x)) {
    realCopy(const_NaN, (real_t*)angle);
    return;
  }

  realCopyAbs((real_t*)x, (real_t*)&abx);
  if(realCompareGreaterThan((real_t*)&abx, const_1)) {
    realCopy(const_NaN, (real_t*)angle);
    return;
  }

  // angle = 2*atan(x/(1+sqrt(1-x*x)))
  realMultiply((real_t*)x, (real_t*)x, (real_t*)&z, realContext);
  realSubtract(const_1, (real_t*)&z, (real_t*)&z, realContext);
  realSquareRoot((real_t*)&z, (real_t*)&z, realContext);
  realAdd((real_t*)&z, const_1, (real_t*)&z, realContext);
  realDivide((real_t*)x, (real_t*)&z, (real_t*)&z, realContext);
  WP34S_Atan1071(&z, &abx, realContext, accNumberDigits);
  realAdd((real_t*)&abx, (real_t*)&abx, (real_t*)angle, realContext);
}

// Tightly based on the original wp34 module in the C47 code : 2025-08-17 JM
void WP34S_Acos1071(real1071_t *x, real1071_t *angle, realContext_t *realContext, int accNumberDigits) {
  real1071_t abx, z;

  if(realIsNaN((real_t*)x)) {
    realCopy(const_NaN, (real_t*)angle);
    return;
  }

  realCopyAbs((real_t*)x, (real_t*)&abx);
  if(realCompareGreaterThan((real_t*)&abx, const_1)) {
    realCopy(const_NaN, (real_t*)angle);
    return;
  }

  // angle = 2*atan((1-x)/sqrt(1-x*x))
  if(realCompareEqual((real_t*)x, const_1)) {
    realZero((real_t*)angle);
  }
  else {
    realMultiply((real_t*)x, (real_t*)x, (real_t*)&z, realContext);
    realSubtract(const_1, (real_t*)&z, (real_t*)&z, realContext);
    realSquareRoot((real_t*)&z, (real_t*)&z, realContext);
    realSubtract(const_1, (real_t*)x, (real_t*)&abx, realContext);
    realDivide((real_t*)&abx, (real_t*)&z, (real_t*)&z, realContext);
    WP34S_Atan1071(&z, &abx, realContext, accNumberDigits);
    realAdd((real_t*)&abx, (real_t*)&abx, (real_t*)angle, realContext);
  }
}

// Tightly based on the original wp34 module in the C47 code : 2025-08-17 JM
void WP34S_Atan2_1071(real1071_t *y, real1071_t *x, real1071_t *atan, realContext_t *realContext, int accNumberDigits) {
  real1071_t r, t;
  const bool_t xNeg = realIsNegative((real_t*)x);
  const bool_t yNeg = realIsNegative((real_t*)y);

  if(realIsNaN((real_t*)x) || realIsNaN((real_t*)y)) {
    realCopy(const_NaN, (real_t*)atan);
    return;
  }

  if(realCompareEqual((real_t*)y, const_0)) {
    if(yNeg) {
      if(realCompareEqual((real_t*)x, const_0)) {
        if(xNeg) {
          realMinus(const1071_pi, (real_t*)atan, realContext);
        }
        else {
          realCopy((real_t*)y, (real_t*)atan);
        }
      }
      else if(xNeg) {
        realMinus(const1071_pi, (real_t*)atan, realContext);
      }
      else {
        realCopy((real_t*)y, (real_t*)atan);
      }
    }
    else {
      if(realCompareEqual((real_t*)x, const_0)) {
        if(xNeg) {
          realCopy(const1071_pi, (real_t*)atan);
        }
        else {
          realZero((real_t*)atan);
        }
      }
      else if(xNeg) {
        realCopy(const1071_pi, (real_t*)atan);
      }
      else {
        realZero((real_t*)atan);
      }
    }
    return;
  }

  if(realCompareEqual((real_t*)x, const_0)) {
    realCopy(const1071_piOn2, (real_t*)atan);
    if(yNeg) {
      realSetNegativeSign((real_t*)atan);
    }
    return;
  }

  if(realIsInfinite((real_t*)x)) {
    if(xNeg) {
      if(realIsInfinite((real_t*)y)) {
        realCopy(const1071_3piOn4, (real_t*)atan);
        if(yNeg) {
          realSetNegativeSign((real_t*)atan);
        }
      }
      else {
        realCopy(const1071_pi, (real_t*)atan);
        if(yNeg) {
          realSetNegativeSign((real_t*)atan);
        }
      }
    }
    else {
      if(realIsInfinite((real_t*)y)) {
        realCopy(const1071_piOn4, (real_t*)atan);
        if(yNeg) {
          realSetNegativeSign((real_t*)atan);
        }
      }
      else {
        realZero((real_t*)atan);
        if(yNeg) {
          realSetNegativeSign((real_t*)atan);
        }
      }
    }
    return;
  }

  if(realIsInfinite((real_t*)y)) {
    realCopy(const1071_piOn2, (real_t*)atan);
    if(yNeg) {
      realSetNegativeSign((real_t*)atan);
    }
    return;
  }

  realDivide((real_t*)y, (real_t*)x, (real_t*)&t, realContext);
  WP34S_Atan1071(&t, &r, realContext, accNumberDigits);
  if(xNeg) {
    realCopy(const1071_pi, (real_t*)&t);
    if(yNeg) {
     realSetNegativeSign((real_t*)&t);
    }
  }
  else {
    realZero((real_t*)&t);
  }

  realAdd((real_t*)&r, (real_t*)&t, (real_t*)atan, realContext);
  if(realCompareEqual((real_t*)atan, const_0) && yNeg) {
    realSetNegativeSign((real_t*)atan);
  }
}


// Does not seem needed and solved with the larger pi
// Manual replacement for big due to to realDivideRemainder not working on very very large input
// set up for 1071 input, with internal mod reduction for double the digits for the following example which illustrates you need to process double the digits for 2pi
// const_2139_2pi is available but commented out in generateCatalogs.
//
// Start with example, filling 6 digits, 2pi being 6 digits
//   1000000 MOD 2pi
//   1000000 / 2pi    =  159155
//   floor()          =  159155
//   floorval x 2pi   =  999999    it is at this point where it is visible that you have only 1 digit of 'info', and to have a reduced angle of 6 digits again, it is clear that you needed 12 digits of pi to start with
//   subtract from org=  1
//
// redo example, with 12 digits, 2pi being 12 digits
//   1000000 MOD 2pi
//   1000000 / 2pi    =  159154.943092
//   floor()          =  159154
//   floorval x 2pi   =  999994.074379    it is at this point where it is visible that you have only 1 digit of 'info', and to have a reduced angle of 6 digits again, it is clear that you needed 12 digits of pi to start with
//   subtract from org=  5.925621
//
// Hence the 1071 input below, with 'internal 2139' calculation



// Python code to check XFN
// import mpmath
//
// # Set VERY high precision for intermediate calculations
// mpmath.mp.dps = 5000  # Much higher than needed for intermediate work
// print("Computing with ultra-high precision...")
//
// # Your large number - use exact string representation
// big_num_str = '828750482128618081847748861163357'
// big_num = mpmath.mpf(big_num_str)
// power_of_ten = mpmath.mpf(10) ** 958
// full_number = big_num * power_of_ten
// offset = mpmath.mpf('0.01')
// total = full_number + offset
//
// # Calculate 2π with very high precision
// two_pi = 2 * mpmath.pi
// print("Step 2: 2π computed with high precision")
//
// # Critical: Use fmod for better numerical stability with large numbers
// mod_result = mpmath.fmod(total, two_pi)
// print("Step 3: Modulo operation completed")
//
// # Calculate sine
// result = mpmath.sin(mod_result)
// print("Step 4: Sine computed")
//
// # Display intermediate results for verification
// print(f"\nIntermediate mod result (first 1070 digits):")
// print(mpmath.nstr(mod_result, 1071))
//
// print(f"\nFinal sine result (1071 decimal places):")
// # Set final output precision to exactly 1071
// final_result = mpmath.nstr(result, 1071)
// print(final_result)
//
// # Verification: compute sin of just the mod result again
// verification = mpmath.sin(mod_result)
// print(f"\nVerification (should match above):")
// print(mpmath.nstr(verification, 1071))



// sine(828750482128618081847748861163357*1E958 + 0.01)
//
// PYTHON
// Intermediate mod result (first 1070 digits):
// 0.00999999999999999999999999999999991814885893445064422653625528425365316545581953952090469113185628665043733893027080294246576255799624916492090580928341203716963235919507905294264589743146454719532618107341558043169524829017019655050718265859153945024514576959509785098429870467904362402857871970677952284363621425264416384163752566897684332098917619947601931690757044690385178939900639461872624431478968452883037867524595065030330527898870393637804585537512849811147957563083468262913096446074534997011144137575125252181183986245469624315826513790029251505353196858731095651770471821186268165128873540403080943374132678037356016006569941578455819530923337651576168203877996886921302863909892834074235217412636488459607831326808030515844522014285588168489372383240038783267970114902284801153209292440939018522158301093396953707532538635258467568427681542439856158318232971025114920529175544937676510041211042672855284774409177480736721294429908611370473686953902734260514642574760872988949248409864440172671518055632351184646717593537629145137124203303517899831871579423177
// Final sine result (1071 decimal places):
// 0.00999983333416666468254243826909964719191584275956241665060790038109737751943136062939182678813774992554629473229750332370715621490346771274042364260733481207579930091833666676865890516708312946658232415495074187566808782438690170848819366309250557240217689230883539964588501343345942503424345401918092640381708871245561262047626890390014927053715590184931856775150614365468723544769684479980591372101638466376032901017889632492616369602918954241317181784298429785029919065092556265136383832781265412371057494279679338767411538542308606925978688772822504718716194090443738323711329780142274102858347138370409683460820768287949200219622288621626395908529914668913564803675082144201652535388459730308277315146734661602328132581896297324525376510542274221570889669260386819583302831170951465269835060685433596401023466236694429027943523078704870353804056216760518070198456557633718920657033656393388926507047300101643252827101266993919619632371422883695358328510790801517693915153363916841513959977838611691213280308131376074641588281164896256764878574949537949167383853119218
//
// Taylor 2139, WP34S_BigMod & WP34S_Mod the same: Full accuracy 1071 digits !!!
// C47 REDUCED ANGLE
// 0.00999999999999999999999999999999991814885893445064422653625528425365316545581953952090469113185628665043733893027080294246576255799624916492090580928341203716963235919507905294264589743146454719532618107341558043169524829017019655050718265859153945024514576959509785098429870467904362402857871970677952284363621425264416384163752566897684332098917619947601931690757044690385178939900639461872624431478968452883037867524595065030330527898870393637804585537512849811147957563083468262913096446074534997011144137575125252181183986245469624315826513790029251505353196858731095651770471821186268165128873540403080943374132678037356016006569941578455819530923337651576168203877996886921302863909892834074235217412636488459607831326808030515844522014285588168489372383240038783267970114902284801153209292440939018522158301093396953707532538635258467568427681542439856158318232971025114920529175544937676510041211042672855284774409177480736721294429908611370473686953902734260514642574760872988949248409864440172671518055632351184646717593537629145137124203303517899831871579423177
// C47 Sine
// 0.00999983333416666468254243826909964719191584275956241665060790038109737751943136062939182678813774992554629473229750332370715621490346771274042364260733481207579930091833666676865890516708312946658232415495074187566808782438690170848819366309250557240217689230883539964588501343345942503424345401918092640381708871245561262047626890390014927053715590184931856775150614365468723544769684479980591372101638466376032901017889632492616369602918954241317181784298429785029919065092556265136383832781265412371057494279679338767411538542308606925978688772822504718716194090443738323711329780142274102858347138370409683460820768287949200219622288621626395908529914668913564803675082144201652535388459730308277315146734661602328132581896297324525376510542274221570889669260386819583302831170951465269835060685433596401023466236694429027943523078704870353804056216760518070198456557633718920657033656393388926507047300101643252827101266993919619632371422883695358328510790801517693915153363916841513959977838611691213280308131376074641588281164896256764878574949537949167383853119215
//
// Taylor 1071, WP34S_BigMod & WP34S_Mod the same: accuracy 80 digits !!!


// ******************************************************
// ** XFN: Full 1071 digit Math, 2139 internal mod reduction
// ** XFN reg with the command to be executed in X in a string COS, SIN, PI, etc.
// ** input register reg, reg+1, and X
// ** Reg   : Real / Longinteger containing the real multiplier, typically the exponent 1E-234, but could be any real multiplier
// ** Reg+1 : Longinteger containing the 1000 digit mantissa
// ** Reg+2 : Real addtion after multiplication
// ** output register X & Y & Z (the command in X is dropped)
// ** if the input register reg = Y, YZT will be dropped.
// ** Typ: SIN( Y*Z+T ) or SIN (r00*r01+r02) or SIN (M*N+O)
// **
// ******************************************************


  const bool_t user1071Flag = true;


  #if defined(TESTSUITE_BUILD)
    const bool_t use1071 = true;
  #else  
    #if (defined(DMCP_BUILD) && (HARDWARE_MODEL) && (HARDWARE_MODEL == HWM_DM42n)) || defined(PC_BUILD)
      #define HIMEMORY true  
    #else
      #define HIMEMORY false
    #endif //(HARDWARE_MODEL) && (HARDWARE_MODEL == HWM_DM42n)) || defined(DMCP_BUILD)
    const bool_t use1071 = HIMEMORY && user1071Flag;
  #endif //TESTSUITE_BUILD

  #define accuracy          (use1071 ? 1044 : 72) // 1050 // 1000 mantissa longint, 34 remainder in Real, 37 guard digits, passed to Taylor to set accuracy expectation in the iteration. Can be set down to say 1000 or more to create guard digits
  #define maxAllowedDigits  (use1071 ? 1000 : 68) // 1000
  #define maxContextDigits  (use1071 ? 1071 : 75) // 1071



int32_t realGetDigits(const real1071_t* x) {
    return ((decNumber*)x)->digits;
}

void decomposeReal(const real1071_t* x, longInteger_t integerPart, real1071_t* fractionalPart, realContext_t* c) {
    // integer part has at most maxAllowedDigits (1000) digits
    #if defined(DEBUG_XFN)
      realToString((real_t *)x, tmpString); tmpString[debugLongNumberLimit]=0; printf("decomposeReal: input: %s\n", tmpString);
    #endif //DEBUG_XFN
//--------//--------//--------//--------//-------- pre-check on original x
    int32_t digits = realGetDigits(x);
    digits = (digits < c->digits) ? digits : c->digits;   // smaller of reported digits or context precision
    if (digits <= 34) {                                   // if the data fits a real, assign the integer to 1
      goto returnUnity;
    }

//--------//--------//--------//--------//-------- normalize using realPlus() and re-check if it fits
    real1071_t mantissa;
    realPlus((real_t*)x, (real_t*)&mantissa, c);          // Normalize to remove trailing zeros with full precision
    int32_t actualDigits = realGetDigits(&mantissa);      // Get actual significant digits after normalization
    if (actualDigits <= 34) {                             // Fits in real34: integer = 1, fractional = original
      goto returnUnity;
    }

//--------//--------//--------//--------//-------- adjust mantissa to form integer 'mantissa'
    int32_t actualExponent = realGetExponent(&mantissa);  // For numbers with >34 digits: extract all significant digits as integer, up to 1000
    if (actualDigits > maxAllowedDigits) actualDigits = maxAllowedDigits;
    int32_t scaleAmount = actualDigits - 1 - actualExponent;  // Scale to make all digits into integer
    mantissa.exponent += scaleAmount;
    realContext_t cc = *c;                                // convert scaled mantissa to integral part, and condition the string
    cc.round = DEC_ROUND_HALF_UP;
    decNumberToIntegralExact((real_t*)&mantissa, (real_t*)&mantissa, &cc);
    realSetPositiveSign((real_t*)&mantissa);
    realToString((real_t*)&mantissa, tmpString);          // Convert real to string and load string into integerPart

    int32_t len = strlen(tmpString);                      // Trim all zeroes from the right side, regarless if there is a decimal point or not. No zeroas are needed in the longinteger as they will sit in the compensated Real exponent.
    for (int32_t i = len - 1; i >= 0 && tmpString[i] == '0'; i--) {
        if(i == actualExponent && i <= 34) break;
        tmpString[i] = '\0';
    }
    if (strlen(tmpString) == 0) {                         // If all zeros were removed, keep at least one zero. Will be caught in the longinteger zero check
        strcpy(tmpString, "0");
    }

    #if defined(DEBUG_XFN)
      printf("decomposeReal: longintegerstring: %s\n", tmpString);
    #endif //DEBUG_XFN

    stringToLongInteger(tmpString, 10, integerPart);
    if(longIntegerIsZero(integerPart)) {                  // failed string manipulation
      goto returnUnity;
    }
    real1071_t integerAsReal;
    convertLongIntegerToReal(integerPart, (real_t*)&integerAsReal, c);             // use the actual integer (from the text) that will be output
    realDivide((real_t*)x, (real_t*)&integerAsReal, (real_t*)fractionalPart, c);   // to calculate the real multiplier, normally the exponent
    return;

returnUnity:
    uInt32ToLongInteger(1, integerPart);
    realCopy((real_t*)x, (real_t*)fractionalPart);
    return;

}


  #define XFN_NOTFOUND 99
  #define FT_NILADIC  100
  #define FT_MONADIC  101
  #define FT_DYADIC   102

typedef struct {
      const char* name;
      int function_id;
      int function_type;
  } FunctionLookup;


  TO_QSPI static const FunctionLookup FUNCTION_TABLE[] = {
      {"",    ITM_pi_XFN      ,FT_NILADIC },
      {"",    ITM_DEG2_XFN    ,FT_MONADIC },
      {"",    ITM_RAD2_XFN    ,FT_MONADIC },
      {"",    ITM_sin_XFN     ,FT_MONADIC },
      {"",    ITM_cos_XFN     ,FT_MONADIC },
      {"",    ITM_tan_XFN     ,FT_MONADIC },
      {"",    ITM_arcsin_XFN  ,FT_MONADIC },
      {"",    ITM_arccos_XFN  ,FT_MONADIC },
      {"",    ITM_arctan_XFN  ,FT_MONADIC },
      {"",    ITM_LN_XFN      ,FT_MONADIC },
      {"",    ITM_LOG_XFN     ,FT_MONADIC },
      {"",    ITM_EXP_XFN     ,FT_MONADIC },
      {"",    ITM_10X_XFN     ,FT_MONADIC },
      {"",    ITM_SQRT_XFN    ,FT_MONADIC },
      {"",    ITM_MODANG_XFN  ,FT_MONADIC },
      {"",    ITM_1ONX_XFN    ,FT_MONADIC },
      {"",    ITM_atan2_XFN   ,FT_DYADIC  },
      {"",    ITM_ADD_XFN     ,FT_DYADIC  },
      {"",    ITM_SUB_XFN     ,FT_DYADIC  },
      {"",    ITM_POWER_XFN   ,FT_DYADIC  },
      {"",    ITM_MULT_XFN    ,FT_DYADIC  },
      {"",    ITM_DIV_XFN     ,FT_DYADIC  },
      {"",    ITM_MOD_XFN     ,FT_DYADIC  },
      {NULL,  0               ,0   }
  };


  static int lookupFunctionId(int function_id) {
      for (const FunctionLookup* entry = FUNCTION_TABLE; entry->name; entry++) {
          if (entry->function_id == function_id) {
              return entry->function_type;
          }
      }
      return XFN_NOTFOUND;
  }

  static bool_t getLongintegerRegisterAsReal1071(int registerNo, real1071_t* result, realContext_t* c) {
    if(getRegisterDataType(registerNo) == dtLongInteger) {
        longInteger_t lint;
        bool_t frac = false;
        if(getRegisterAsLongInt(registerNo, lint, &frac)) {
          if(!frac) {   //cannot be false due to longint type check
            longIntegerToString(lint, 10, tmpString);
            longIntegerFree(lint);
            decNumberFromString((real_t *)result, tmpString, c);
          }
          return true;
        }
    } else
    if(getRegisterDataType(registerNo) == dtReal34) {
//must still deal with the angle if applicable in Y
        if(getRegisterAsReal(registerNo, (real_t *)result)) {
          return true;
        }
    }
    displayCalcErrorMessage(ERROR_INPUT_DATA_TYPE_NOT_MATCHING, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "Invalid input register");
        moreInfoOnError("In function fnXfn:getLongintegerRegisterAsReal1071:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return false;
  }


  #define inputAngleMode(r)           (registerIsNoAngle(r+1) && registerIsNoAngle(r+2) ? (!registerIsNoAngle(r) ? getRegisterAngularMode(r) : amNone) : amNone)

  #define deemedInputAngleMode(r)     (inputAngleError(r) ? amNone : inputAngleMode(r) == amNone ? currentAngularMode : inputAngleMode(r))

  #define registerIsNoAngle(r)        ((getRegisterDataType(r) == dtReal34 && getRegisterAngularMode(r) == amNone) || getRegisterDataType(r) == dtLongInteger)

  #define inputIsNoAngle(r)           (registerIsNoAngle(r) || (!registerIsNoAngle(r+1) || !registerIsNoAngle(r+2)))

  #define inputAngleError(r)          (!registerIsNoAngle(r+1) || !registerIsNoAngle(r+2))


  static bool_t getAngleModeForRegister(int registerNo, angularMode_t *angleMode ) {
    if(!inputAngleError(registerNo)) {
      *angleMode = deemedInputAngleMode(registerNo);
      return true;
    }
    return false;
   }



  static bool_t validateExponent(const real1071_t* x) {
    if(realGetExponent(x) > maxAllowedDigits) {
        return false;
    }
    return true;
  }


  static bool_t readThreeRegisters(int registerNo, real1071_t* result, real1071_t* temporary, realContext_t* c) {
    if(!getLongintegerRegisterAsReal1071(registerNo+0, temporary, c)) {                        //ignore anglemode, it is handled elsewhere
        return false;
    }
    if(!getLongintegerRegisterAsReal1071(registerNo+1, result, c)) {    // check for long integer first, to first have that error message if invalid number
        return false;
    }
    realMultiply((real_t *)result, (real_t *)temporary, (real_t *)result, c);

    if(!getLongintegerRegisterAsReal1071(registerNo+2, temporary, c)) {                        //ignore anglemode, it is handled elsewhere
//Must still deal with getRegisterAsReal should TI or error if dataloss will occur
        return false;
    }
    realAdd((real_t *)result, (real_t*)temporary, (real_t *)result, c);
    realCopy(const_0, (real_t*)temporary);
    return true;
  }


  static bool getCombinedParameter (int param, int registerNo, real1071_t* combined, real1071_t* temporary, angularMode_t* angleMode, realContext_t* c) {

    if(!getAngleModeForRegister(registerNo, angleMode)) {
      displayCalcErrorMessage(ERROR_INPUT_DATA_TYPE_NOT_MATCHING, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
          sprintf(errorMessage, "Invalid input registers: getAngleModeForRegister ");
          moreInfoOnError("In function fnXfn:getCombinedParameter:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return false;
    }
    if(!readThreeRegisters(registerNo, combined, temporary, c)) {
      displayCalcErrorMessage(ERROR_INPUT_DATA_TYPE_NOT_MATCHING, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
          sprintf(errorMessage, "Invalid input registers: readThreeRegisters");
          moreInfoOnError("In function fnXfn:getCombinedParameter:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return false;
    }
    #if defined(DEBUG_XFN)
        realToString((real_t *)combined, tmpString); printf("VAR%d: x * y + z: %s\n", param, tmpString);
    #endif //DEBUG_XFN
    if(!validateExponent(combined)) {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        #if (EXTRA_INFO_ON_CALC_ERROR == 1)
            sprintf(errorMessage, "Total VAR%d = r%d*r%d+r%d exceeds the maximum exponent %d > %d", param, registerNo, registerNo+1, registerNo+2, realGetExponent(combined), maxAllowedDigits);
            moreInfoOnError("In function fnXfn:", errorMessage, NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        return false;
    }
    return true;
  }


//--------//--------//-- MAIN function dispatcher --//--------//--------//--------
  static void doXfn(uint16_t registerNo, int function, int functionType, int ErrorLocation);

  void fnXXfn(uint16_t function) {                               //--------//--------//-- Known function, X --//--------//--------//--------
    int ErrorLocation = 0;
    int functionType = lookupFunctionId(function);
    if(functionType == XFN_NOTFOUND) {
      ErrorLocation = 11;
    }
    doXfn(REGISTER_X, function, functionType, ErrorLocation);
  }

  void fnXfnIndirect(uint16_t registerNo, uint16_t function) {   //--------//--------//-- Known function, register no  --//--------//--------//--------
    int ErrorLocation = 0;
    int functionType = lookupFunctionId(function);
    if(functionType == XFN_NOTFOUND) {
      ErrorLocation = 14;
    }
    if((functionType == FT_NILADIC) ||
       (functionType == FT_MONADIC && (registerNo <= FIRST_LETTERED_REGISTER - 3 || (registerNo >= FIRST_LETTERED_REGISTER && registerNo <= (LAST_SPARE_REGISTER+1) - 3) ))  ||
       (functionType == FT_DYADIC  && (registerNo <= FIRST_LETTERED_REGISTER - 6 || (registerNo >= FIRST_LETTERED_REGISTER && registerNo <= (LAST_SPARE_REGISTER+1) - 6) )))   {
      doXfn(registerNo, function, functionType, ErrorLocation);
      return;
    }
    displayCalcErrorMessage(ERROR_UNDEF_SOURCE_VAR, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "Specified register numbers out of range: %d",registerNo);
      moreInfoOnError("In function fnXfnIndirect:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }




  void fnXXfn_ToDEG               (uint16_t registerNo) {
    fnXfnIndirect(registerNo, ITM_DEG2_XFN);
  }
  void fnXXfn_ToRAD               (uint16_t registerNo) {
    fnXfnIndirect(registerNo, ITM_RAD2_XFN);
  }
  void fnXXfn_sin                 (uint16_t registerNo) {
    fnXfnIndirect(registerNo, ITM_sin_XFN);
  }
  void fnXXfn_cos                 (uint16_t registerNo) {
    fnXfnIndirect(registerNo, ITM_cos_XFN);
  }
  void fnXXfn_tan                 (uint16_t registerNo) {
    fnXfnIndirect(registerNo, ITM_tan_XFN);
  }
  void fnXXfn_pi                  (uint16_t registerNo) {
    fnXfnIndirect(registerNo, ITM_pi_XFN);
  }
  void fnXXfn_atan2               (uint16_t registerNo) {
    fnXfnIndirect(registerNo, ITM_atan2_XFN);
  }
  void fnXXfn_arcsin              (uint16_t registerNo) {
    fnXfnIndirect(registerNo, ITM_arcsin_XFN);
  }
  void fnXXfn_arccos              (uint16_t registerNo) {
    fnXfnIndirect(registerNo, ITM_arccos_XFN);
  }
  void fnXXfn_arctan              (uint16_t registerNo) {
    fnXfnIndirect(registerNo, ITM_arctan_XFN);
  }
  void fnXXfn_LN                  (uint16_t registerNo) {
    fnXfnIndirect(registerNo, ITM_LN_XFN);
  }
  void fnXXfn_LOG                 (uint16_t registerNo) {
    fnXfnIndirect(registerNo, ITM_LOG_XFN);
  }
  void fnXXfn_EXP                 (uint16_t registerNo) {
    fnXfnIndirect(registerNo, ITM_EXP_XFN);
  }
  void fnXXfn_10X                 (uint16_t registerNo) {
    fnXfnIndirect(registerNo, ITM_10X_XFN);
  }
  void fnXXfn_POWER               (uint16_t registerNo) {
    fnXfnIndirect(registerNo, ITM_POWER_XFN);
  }
  void fnXXfn_SQRT                (uint16_t registerNo) {
    fnXfnIndirect(registerNo, ITM_SQRT_XFN);
  }
  void fnXXfn_1ONX                (uint16_t registerNo) {
    fnXfnIndirect(registerNo, ITM_1ONX_XFN);
  }
  void fnXXfn_ADD                 (uint16_t registerNo) {
    fnXfnIndirect(registerNo, ITM_ADD_XFN);
  }
  void fnXXfn_SUB                 (uint16_t registerNo) {
    fnXfnIndirect(registerNo, ITM_SUB_XFN);
  }
  void fnXXfn_MULT                (uint16_t registerNo) {
    fnXfnIndirect(registerNo, ITM_MULT_XFN);
  }
  void fnXXfn_DIV                 (uint16_t registerNo) {
    fnXfnIndirect(registerNo, ITM_DIV_XFN);
  }
  void fnXXfn_MOD                 (uint16_t registerNo) {
    fnXfnIndirect(registerNo, ITM_MOD_XFN);
  }
  void fnXXfn_MODANG              (uint16_t registerNo) {
    fnXfnIndirect(registerNo, ITM_MODANG_XFN);
  }




  static void doXfn(uint16_t registerNo, int function, int functionType, int ErrorLocation) {
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      int location = 0;
    #endif //EXTRA_INFO_ON_CALC_ERROR

    if(ErrorLocation != 0 || function == XFN_NOTFOUND || functionType == XFN_NOTFOUND) {
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        location = ErrorLocation;
      #endif //EXTRA_INFO_ON_CALC_ERROR
      goto noFunction;
      }

    if(!saveLastX()) {
      return;
    }

    real1071_t paramX, paramY, paramTemp;
    realCopy(const_0,(real_t*)&paramX);
    real_t tmpR;

    realContext_t c = ctxtReal75;
    c.digits = maxContextDigits;           // Automatic change over to 75 digits for DM42 hardware, and 1071 digits for DM42n and simulator

    angularMode_t angleMode = currentAngularMode;
    angularMode_t tmpAngle;

    if(functionType == FT_NILADIC) {
      ; //no input needed, continue
    } else
    if(functionType == FT_MONADIC || functionType == FT_DYADIC) {
      if(!getCombinedParameter(1, registerNo, &paramX, &paramTemp, &angleMode, &c)) {   //use the angle of the 1st param only, if set
        return;
      }
      if(functionType == FT_DYADIC) {
        if(!getCombinedParameter(2, registerNo + 3, &paramY, &paramTemp, &tmpAngle, &c)) { // ignore angle
          return;
        }
      }
    } else {
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        location = 3;
      #endif //EXTRA_INFO_ON_CALC_ERROR
      goto noFunction;
    }

    #if defined(DEBUG_XFN)
      printf("Angle mode = %d;  function number = %d\n", angleMode, function);
    #endif //DEBUG_XFN


    if(realIsSpecial((real_t *)&paramX)) {
      #if defined(DEBUG_XFN)
        printf("Real is Special, forcing NaN output, bypassing calculations\n");
        realToString((real_t*)&paramX, tmpString);   tmpString[debugLongNumberLimit]=0; printf("ParamX is Special = %s\n", tmpString);
      #endif //DEBUG_XFN
      realCopy(const_NaN, (real_t *)&paramX);
    }
    else {
      switch(function) {
  //--------//--------//-- Executing function --//--------//--------//--------

  //--------//NILADIC FUNCTIONS
        case ITM_pi_XFN: {
          realCopy(const1071_pi, (real_t *)&paramX);
//          realDivide(const2139_2pi, const_2, (real_t*)&paramX, &c);
          break;
        }

  //--------//MONADIC FUNCTIONS
        case ITM_RAD2_XFN: {
          if(inputIsNoAngle(registerNo)) {
            angleMode = amRadian;
            break;
          } else
          if(!inputAngleError(registerNo) && angleMode != amRadian) {                                                                       // if either or both is/are set to am
            realDivide((real_t*)&paramX, modulus(angleMode), (real_t*)&paramX, &c);
            realMultiply((real_t*)&paramX, modulus(amRadian), (real_t*)&paramX, &c);        
          }
          angleMode = amRadian;
          break;
        }

        case ITM_DEG2_XFN: {
          if(inputIsNoAngle(registerNo)) {
            angleMode = amDegree;
            break;
          } else
          if(!inputAngleError(registerNo) && angleMode != amDegree) {                                                                       // if either or both is/are set to am
            realDivide((real_t*)&paramX, modulus(angleMode), (real_t*)&paramX, &c);
            realMultiply((real_t*)&paramX, modulus(amDegree), (real_t*)&paramX, &c);        
          }
          angleMode = amDegree;
          break;
        }


        case ITM_sin_XFN:
        case ITM_cos_XFN:
        case ITM_tan_XFN: {
            #if defined(DEBUG_XFN)
              realToString((real_t*)&paramX, tmpString);   tmpString[debugLongNumberLimit]=0; printf("ParamX = %s\n", tmpString);
              realToString(modulus(angleMode), tmpString); tmpString[debugLongNumberLimit]=0; printf("Modulus= %s\n", tmpString);
              printf("angleMode %d\n", angleMode);
            #endif //DEBUG_XFN

            //WP34S_BigMod((real_t *)&paramX, modulus(angleMode), (real_t *)&paramX, &c);

            #if defined(DEBUG_XFN)
              realToString((real_t *)&paramX, tmpString); /*tmpString[debugLongNumberLimit]=0; */printf(" ParamX reduced angle: %s\n",tmpString);
            #endif //DEBUG_XFN

            real1071_t aa,bb;
            realCopy(const_0,(real_t*)&aa);
            realCopy(const_0,(real_t*)&bb);
            if(function == ITM_sin_XFN) { C47Cvt2RadSinCosTan2(&paramX, angleMode, &paramX, NULL,    NULL,    &c, accuracy); } else
            if(function == ITM_cos_XFN) { C47Cvt2RadSinCosTan2(&paramX, angleMode, NULL,    &paramX, NULL,    &c, accuracy); } else
            if(function == ITM_tan_XFN) { C47Cvt2RadSinCosTan2(&paramX, angleMode, &aa,     &bb,     &paramX, &c, accuracy); }
            }
            break;

        case ITM_arcsin_XFN: {
          WP34S_Asin1071(&paramX, &paramX, &c, accuracy);
          convertAngleFromTo((real_t *)&paramX, amRadian, currentAngularMode, &c);
          break;
        }
        case ITM_arccos_XFN: {
          WP34S_Acos1071(&paramX, &paramX, &c, accuracy);
          convertAngleFromTo((real_t *)&paramX, amRadian, currentAngularMode, &c);
          break;
        }
        case ITM_arctan_XFN: {
          WP34S_Atan1071(&paramX, &paramX, &c, accuracy);
          convertAngleFromTo((real_t *)&paramX, amRadian, currentAngularMode, &c);
          break;
        }

        case ITM_LN_XFN: {
          decNumberLn((real_t *)&paramX, (real_t *)&paramX, &c);
          break;
        }
        case ITM_LOG_XFN: {
          decNumberLn((real_t *)&paramX, (real_t *)&paramX, &c);
          decNumberLn((real_t *)&paramTemp, const_10, &c);
          realDivide((real_t *)&paramX, (real_t *)&paramTemp, (real_t *)&paramX, &c);
          break;
        }
        case ITM_EXP_XFN: {
          decNumberExp((real_t *)&paramX, (real_t *)&paramX, &c);
          break;
        }
        case ITM_10X_XFN: {
          realPower(const_10, (real_t *)&paramX, (real_t *)&paramX, &c);
          break;
        }
        case ITM_SQRT_XFN: {
          realPower((real_t *)&paramX, const_1on2, (real_t *)&paramX, &c);
          break;
        }
        case ITM_1ONX_XFN: {
          realDivide(const_1, (real_t *)&paramX, (real_t *)&paramX, &c);
          break;
        }
        case ITM_MODANG_XFN: {
          if(angleMode == amRadian) {
            WP34S_BigMod((real_t *)&paramX, modulus(angleMode), (real_t *)&paramX, &c);
            // prep for: mod2Pi((real_t *)&paramX, (real_t *)&paramX, &c);
          } else {
            WP34S_Mod((real_t *)&paramX, modulus(angleMode), (real_t *)&paramX, &c);
          }
          break;
        }
  //--------//DYADIC FUNCTIONS
        case ITM_ADD_XFN: {
          realAdd       ((real_t*)&paramY, (real_t*)&paramX, (real_t*)&paramX, &c);
          break;
        }
        case ITM_SUB_XFN: {
          realSubtract  ((real_t*)&paramY, (real_t*)&paramX, (real_t*)&paramX, &c);
          break;
        }
        case ITM_POWER_XFN: {
          realPower     ((real_t*)&paramY, (real_t*)&paramX, (real_t*)&paramX, &c);
          break;
        }
        case ITM_MULT_XFN: {
          realMultiply  ((real_t*)&paramY, (real_t*)&paramX, (real_t*)&paramX, &c);
          break;
        }
        case ITM_DIV_XFN: {
          realDivide    ((real_t*)&paramY, (real_t*)&paramX, (real_t*)&paramX, &c);
          break;
        }
        case ITM_MOD_XFN: {
          WP34S_BigMod  ((real_t*)&paramY, (real_t*)&paramX, (real_t*)&paramX, &c);
          break;
        }
        case ITM_atan2_XFN: {
          WP34S_Atan2_1071(&paramY, &paramX, &paramX, &c, accuracy);
          convertAngleFromTo((real_t *)&paramX, amRadian, currentAngularMode, &c);
          break;
        }

  //--------//No function
        default: {
          #if (EXTRA_INFO_ON_CALC_ERROR == 1)
            location = 5;
          #endif //EXTRA_INFO_ON_CALC_ERROR
          goto noFunction;
        }
      }
    }

    #if defined(DEBUG_XFN)
      printRegisterToConsole(REGISTER_X,"\nX:","\n");
      realToString((real_t *)&paramX, tmpString); tmpString[debugLongNumberLimit]=0; printf("Output: %s\n",tmpString);
    #endif //DEBUG_XFN

//--------//--------//-- Processing stack output with paramX as the output --//--------//--------//--------


    //Step 0: Prep the stack
    if(functionType == FT_MONADIC || functionType == FT_DYADIC) {
      //If the input registers are XYZ then drop the stack input
      if((registerNo == REGISTER_Y || registerNo == REGISTER_X) && lastErrorCode == 0) {
        if(registerNo == REGISTER_Y) {
          fnDropY(NOPARAM); //y
        }
        fnDropY(NOPARAM); //z
        fnDropY(NOPARAM); //t
      }
    } else

    if(functionType == FT_NILADIC && registerNo == REGISTER_X) {
      setSystemFlag(FLAG_ASLIFT);
      liftStack();
    }


    switch(function) {
      case ITM_arcsin_XFN:
      case ITM_arccos_XFN:
      case ITM_arctan_XFN:
      case ITM_atan2_XFN:
      case ITM_RAD2_XFN:
      case ITM_DEG2_XFN: {
        //leave angleMode
        break;
      }
      default: {
        angleMode = amNone;
        break;
      }
    }


    //Step 1: Send a 0 addition term to the stack output (Form only, will be rewritten later)
    reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
    realCopy(const_0, &tmpR);
    convertRealToReal34ResultRegister(&tmpR, REGISTER_X);
    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);


    //Step 2: Send integer part to stack output
    setSystemFlag(FLAG_ASLIFT);
    liftStack();
    longInteger_t integerOutput;
    longIntegerInit(integerOutput);
    decomposeReal(&paramX, integerOutput, &paramY, &c);
    convertLongIntegerToLongIntegerRegister(integerOutput,REGISTER_X);
    longIntegerFree(integerOutput);


    //Step 3: Send real multiplier to the stack output
    setSystemFlag(FLAG_ASLIFT);
    liftStack();
    realPlus((real_t *)&paramY, &tmpR, &ctxtReal75);
    convertRealToResultRegister(&tmpR, REGISTER_X, angleMode);
    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);


    //Step 4: update difference term;         re-using paramY
    if(functionType == FT_NILADIC || functionType == FT_MONADIC || functionType == FT_DYADIC) {
      if(!getCombinedParameter(1, REGISTER_X, &paramY, &paramTemp, &tmpAngle, &c)) {   //ignore angle
        ; //should be errored already in getCombinedParameter
        return;
      }
      realSubtract((real_t *)&paramX, (real_t *)&paramY, (real_t *)&paramY, &c);
      realPlus((real_t *)&paramY, &tmpR, &ctxtReal75);
      convertRealToResultRegister(&tmpR, REGISTER_Z, amNone);
    }


    //Step 5: debug stack output
    #if defined(DEBUG_XFN)
      printRegisterToConsole(REGISTER_Z,"\nZ:","\n");
      printRegisterToConsole(REGISTER_Y,"\nY:","\n");
      printRegisterToConsole(REGISTER_X,"\nX:","\n");
    #endif //DEBUG_XFN

    return;


noFunction:
    displayCalcErrorMessage(ERROR_UNDEFINED_OPCODE, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "Incorrect function code %d (location %d)", function, location);
      moreInfoOnError("In function fnXfn:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
}





void fnEdit (uint16_t unusedParamButMandatory) {
  //fnEdit: this is simply the stub with the currently working edit routines, linked via ITM_EDIT, which is also located on long press Backspace.
  //All might have to be changed have a propoer generic EDIT function.
  #if !defined(TESTSUITE_BUILD)
    int16_t index;
    uint8_t grpGroupingLeftOld;
    uint8_t grpGroupingRightOld;
    char    varOrLblName[8];

    if(tam.mode != 0) goto err;
    switch(calcMode) {
      case CM_NORMAL :
        if(currentMenu() == -MNU_EQN || currentMenu() == -MNU_Sfdx || currentMenu() == -MNU_Solver_TOOL || currentMenu() == -MNU_Sf_TOOL || currentMenu() == -MNU_GRAPHS ||
           (currentMenu() == -MNU_MVAR && (currentSolverStatus & SOLVER_STATUS_USES_FORMULA) && (currentSolverStatus & SOLVER_STATUS_INTERACTIVE))         ) {
          showSoftmenu(-MNU_EQN);
          runFunction(ITM_EQ_EDI);
        }
        else {
          switch(getRegisterDataType(REGISTER_X)) {
            case dtLongInteger: {
              #define NIM_BUFFER_EXTENDED_LENGTH    1400      // provision for very long integers (up to 1000 digits + separators)
              memset(nimBufferDisplay, 0, NIM_BUFFER_EXTENDED_LENGTH);
              longInteger_t lgInt;
              convertLongIntegerRegisterToLongInteger(REGISTER_X, lgInt);
              longIntegerToAllocatedString(lgInt, nimBufferDisplay, NIM_BUFFER_EXTENDED_LENGTH);
              if(longIntegerIsPositiveOrZero(lgInt)) {
                aimBuffer[0] = '+';
                strcpy(aimBuffer + 1, nimBufferDisplay);
              }
              else {
                strcpy(aimBuffer, nimBufferDisplay);
              }
              longIntegerFree(lgInt);
              if(grpGroupingLeft > 0) {
                int16_t len = strlen(nimBufferDisplay);
                for(int16_t i=len - grpGroupingLeft; i>0; i-=grpGroupingLeft) {
                  if(i != 1 || nimBufferDisplay[0] != '-') {
                    if(gapItemLeft != ITM_NULL) {  // insert gapCharLeft
                      uint8_t lenGapItem = strlen(indexOfItems[gapItemLeft].itemSoftmenuName);
                      xcopy(nimBufferDisplay + i + lenGapItem, nimBufferDisplay + i, len - i + 1);
                      xcopy(nimBufferDisplay + i , indexOfItems[gapItemLeft].itemSoftmenuName, lenGapItem);
                      len += lenGapItem;
                    }
                  }
                }
              }

              // Test if long inter number display string will fit on two lines in standard font, if not do nothing (cannot edit)
              if(stringWidth(nimBufferDisplay, &standardFont, true, true) < (SCREEN_WIDTH * 2)  - 8) { // 8 is the standard font cursor width
                //printf("**[DL]** aimBuffer %s \n nimBufferDisplay %s\n",aimBuffer,nimBufferDisplay);fflush(stdout);
                calcMode = CM_NIM;
                clearSystemFlag(FLAG_ALPHA);
                freeRegisterData(REGISTER_X);
                setRegisterDataPointer(REGISTER_X, allocC47Blocks(REAL34_SIZE_IN_BLOCKS));
                setRegisterDataType(REGISTER_X, dtReal34, amNone);
                real34Zero(REGISTER_REAL34_DATA(REGISTER_X));
                hexDigits = 0;
                nimNumberPart = NP_INT_10;
                //clearRegisterLine(NIM_REGISTER_LINE, true, true);
                if(!checkHP) clearRegisterLine(NIM_REGISTER_LINE, true, true);
                xCursor = 1;
                cursorEnabled = true;
                cursorFont = &numericFont;
              }
              else {
                memset(nimBufferDisplay, 0, NIM_BUFFER_EXTENDED_LENGTH);
                aimBuffer[0] = 0;
                nimBufferDisplay[0] = 0;
              }
              break;
            }

            case dtReal34: {
              edit_dtReal34:
              grpGroupingLeftOld  = grpGroupingLeft;
              grpGroupingRightOld = grpGroupingRight;
              angularMode_t xangularMode = getRegisterAngularMode(REGISTER_X);

              //printf("**[DL]** xangularMode %d\n",xangularMode);fflush(stdout);
              memset(aimBuffer, 0, AIM_BUFFER_LENGTH);
              memset(nimBufferDisplay, 0, NIM_BUFFER_LENGTH);

              if(xangularMode == amDMS) {
                real34FromDegToDms(REGISTER_REAL34_DATA(REGISTER_X), REGISTER_REAL34_DATA(REGISTER_X));
              }

              uint16_t lessEqualGreater = 0;
              if (getSystemFlag(FLAG_FRACT)) {
                grpGroupingLeft  = 0;
                grpGroupingRight = 0;
                fractionToString(REGISTER_X, aimBuffer, (int16_t *)&lessEqualGreater);
                grpGroupingRight = grpGroupingRightOld;
                grpGroupingLeft  = grpGroupingLeftOld;

                if(lessEqualGreater == 0) {         // display fraction
                  nimNumberPart = NP_FRACTION_DENOMINATOR;
                  strcpy(nimBufferDisplay, STD_SPACE_HAIR);
                  nimBufferToDisplayBuffer(aimBuffer, nimBufferDisplay + 2);
                  strcat(nimBufferDisplay, STD_SPACE_4_PER_EM);
                  for(index=2; aimBuffer[index]!=' '; index++) {
                  }
                  supNumberToDisplayString(stringToInt32(aimBuffer + index + 1), nimBufferDisplay + stringByteLength(nimBufferDisplay), NULL, true);

                  strcat(nimBufferDisplay, "/");

                  for(; aimBuffer[index]!='/'; index++) {
                  }
                  if(aimBuffer[++index] != 0) {
                    subNumberToDisplayString(stringToInt32(aimBuffer + index), nimBufferDisplay + stringByteLength(nimBufferDisplay), NULL);
                  }
                }
                else {    // display real34
                  _real34ToNim(REGISTER_REAL34_DATA(REGISTER_X), aimBuffer, nimBufferDisplay);
                }
              }
              else {  // display real34
                _real34ToNim(REGISTER_REAL34_DATA(REGISTER_X), aimBuffer, nimBufferDisplay);
              }
              //printf("**[DL]** dtReal34 aimBuffer %s nimBufferDisplay %s\n",aimBuffer,nimBufferDisplay);fflush(stdout);

              calcMode = CM_NIM;
              clearSystemFlag(FLAG_ALPHA);
              uint16_t dataType = getRegisterDataType(REGISTER_X);
              freeRegisterData(REGISTER_X);
              setRegisterDataPointer(REGISTER_X, allocC47Blocks(REAL34_SIZE_IN_BLOCKS));
              if((dataType == dtTime) || (dataType == dtDate)) {
                setRegisterDataType(REGISTER_X, dataType, xangularMode);   // Keep time and date datatypes
              }
              else {
                setRegisterDataType(REGISTER_X, dtReal34, xangularMode);
              }
              real34Zero(REGISTER_REAL34_DATA(REGISTER_X));
              //printf("**[DL]** AngularMode %d\n",getRegisterAngularMode(REGISTER_X));fflush(stdout);
              hexDigits = 0;
              if(!checkHP) clearRegisterLine(NIM_REGISTER_LINE, true, true);
              xCursor = 1;
              cursorEnabled = true;
              cursorFont = &numericFont;
              break;
            }

            case dtTime: {
              _hmsTimeToReal();
              setRegisterDataType(REGISTER_X, dtTime, amNone);  // Force time data type to preserve it when closing NIM
              goto edit_dtReal34;
              break;
            }

            case dtDate: {
              convertDateRegisterToReal34Register(REGISTER_X, REGISTER_X);
              setRegisterDataType(REGISTER_X, dtDate, amNone);  // Force date data type to preserve it when closing NIM
              goto edit_dtReal34;
              break;
            }

            case dtString: {
              setSystemFlag(FLAG_ASLIFT);
              if(stringByteLength(REGISTER_STRING_DATA(REGISTER_X)) < AIM_BUFFER_LENGTH) {
                strcpy(aimBuffer, REGISTER_STRING_DATA(REGISTER_X));
                T_cursorPos = stringByteLength(aimBuffer);
                fnDrop(NOPARAM);
                shiftF = false;
                shiftG = false;
                #if !defined(TESTSUITE_BUILD)
                  calcModeAim(NOPARAM); // Alpha Input Mode
                  showSoftmenu(-MNU_ALPHA);
                #endif // !TESTSUITE_BUILD
              }
              break;
            }

            case dtReal34Matrix:
            case dtComplex34Matrix: {
              fnEditMatrix(NOPARAM);
              break;
            }

            case dtShortInteger: {
              uint16_t i;
              grpGroupingLeftOld  = grpGroupingLeft;
              grpGroupingRightOld = grpGroupingRight;

              memset(aimBuffer, 0, AIM_BUFFER_LENGTH);
              memset(nimBufferDisplay, 0, NIM_BUFFER_LENGTH);

              lastIntegerBase  = getRegisterTag(REGISTER_X);
              nimNumberPart = (lastIntegerBase <= 10 ? NP_INT_10 : NP_INT_16);

              grpGroupingLeft  = 0;
              grpGroupingRight = 0;
              shortIntegerToString(REGISTER_X, aimBuffer);
              grpGroupingRight = grpGroupingRightOld;
              grpGroupingLeft  = grpGroupingLeftOld;

              hexDigits   = 0;
              for(i = 0; i < strlen(aimBuffer); i++) {
                if((aimBuffer[i] >= 'A') && (aimBuffer[i] <= 'F')) {
                  hexDigits++;
                }
              }

              strcpy(nimBufferDisplay, STD_SPACE_HAIR);
              nimBufferToDisplayBuffer(aimBuffer, nimBufferDisplay + 2);
              for(i=stringByteLength(nimBufferDisplay) - 1; i>0; i--) {
                if(nimBufferDisplay[i] == (char)0xab) {    //token
                  nimBufferDisplay[i] = SEPARATOR_LEFT[0];
                  if(nimBufferDisplay[i+1] == 1) {
                    nimBufferDisplay[i+1] = SEPARATOR_LEFT[1];
                  }
                }
              }

              printf("**[DL]** dtShortInteger aimBuffer %s nimBufferDisplay %s\n",aimBuffer,nimBufferDisplay);fflush(stdout);

              calcMode = CM_NIM;
              clearSystemFlag(FLAG_ALPHA);
              freeRegisterData(REGISTER_X);
              setRegisterDataPointer(REGISTER_X, allocC47Blocks(REAL34_SIZE_IN_BLOCKS));
              setRegisterDataType(REGISTER_X, dtReal34, amNone);
              if(!checkHP) clearRegisterLine(NIM_REGISTER_LINE, true, true);
              xCursor = 1;
              cursorEnabled = true;
              cursorFont = &numericFont;
              break;
            }

            // case dtConfig: Not relevant for EDIT
            default: {
              goto err;
            }
          }
        }
        break;

      case CM_AIM :
        runFunction(ITM_XEDIT);
        break;

      case CM_PEM : {
        if(pemCursorIsZerothStep) return;
        //printf("**[DL]** currentLocalStepNumber %d\n",currentLocalStepNumber);fflush(stdout);
        int16_t i = 0;
        int16_t func = currentStep[i++];
        if(func & 0x80) {
          func &= 0x7f;
          func <<= 8;
          func |= currentStep[i++];
        }
        uint8_t opParam  = currentStep[i++];
        uint8_t opParam2 = currentStep[i++];
        uint8_t opParam3 = currentStep[i];

        if((opParam == STRING_LABEL_VARIABLE) || (opParam == INDIRECT_VARIABLE)) {
          for(index = 0;  index < opParam2; index++) {
            varOrLblName[index] = currentStep[i++];
          }
          varOrLblName[index] = 0;
        }
        //printf("**[DL]** fnEdit cmPem func %d opParam %d opParam2 %d decodedLiteralType %d\n",func,opParam,opParam2,decodedLiteralType);fflush(stdout);

        if((func == ITM_LITERAL || func == ITM_REM)) {
          memset(aimBuffer, 0, AIM_BUFFER_LENGTH);

          if(opParam == STRING_LABEL_VARIABLE) {
            pemAlphaEdit(NOPARAM);
          }
          else if((opParam == BINARY_SHORT_INTEGER) || (opParam == STRING_SHORT_INTEGER) || (opParam == STRING_LONG_INTEGER) ||
                  (opParam == BINARY_REAL34)        || (opParam == STRING_REAL34)        ||
                  (opParam == BINARY_COMPLEX34)     || (opParam == STRING_COMPLEX34)     ||
                  (opParam == STRING_DATE)          || (opParam == STRING_TIME)          || (opParam == STRING_ANGLE_DMS)    ||
                  (opParam == STRING_ANGLE_RADIAN)  || (opParam == STRING_ANGLE_GRAD)    ||
                  (opParam == STRING_ANGLE_DEGREE)  || (opParam == STRING_ANGLE_MULTPI)) {
            char *tempBuffer = errorMessage + 3000;
            bool chsNeeded = false;
            bool isDate = (opParam == STRING_DATE ? true : false);

            if((opParam == STRING_REAL34)|| (opParam == STRING_COMPLEX34))  {
              getStringLabelOrVariableName(&currentStep[2]);
              strcpy(tempBuffer, tmpStringLabelOrVariableName);
            }
            else {
              grpGroupingLeftOld  = grpGroupingLeft;
              grpGroupingRightOld = grpGroupingRight;
              grpGroupingRight = 0;
              grpGroupingLeft  = 0;
              decodeOneStep(currentStep);
              grpGroupingRight = grpGroupingRightOld;
              grpGroupingLeft  = grpGroupingLeftOld;
              strcpy(tempBuffer, tmpString);
            }
            lastIntegerBase = (opParam == BINARY_SHORT_INTEGER ? opParam2: opParam == STRING_SHORT_INTEGER ? opParam2: 0);
            //printf("**[DL]** fnEdit lastIntegerBase %d tempBuffer %s\n",lastIntegerBase,tempBuffer);fflush(stdout);
            deleteStepsFromTo(currentStep, findNextStep(currentStep));

            uint16_t i;
            uint16_t iMax = strlen(tempBuffer);
            bool decimalflag = false;
            for(i = 0; i < iMax; i++) {
              //printf("**[DL]** fnEdit tempBuffer[%2d] %02x aimBuffer %s\n",i,tempBuffer[i]&0xff,aimBuffer);fflush(stdout);
              switch ((uint8_t) tempBuffer[i]) {
                case '0':
                case '1':
                case '2':
                case '3':
                case '4':
                case '5':
                case '6':
                case '7':
                case '8':
                case '9':
                  pemAddNumber(ITM_0 + tempBuffer[i] - '0', false);
                  break;
                case 'A':
                case 'B':
                case 'C':
                case 'D':
                case 'E':
                case 'F':
                  pemAddNumber(ITM_A + tempBuffer[i] - 'A', false);
                  break;
                case '.':
                  if(!decimalflag) {
                    decimalflag = true;
                    pemAddNumber(ITM_PERIOD, false);
                  }
                  break;
                case ':' :
                  if(!decimalflag) {
                    decimalflag = true;
                    pemAddNumber(ITM_PERIOD, false);
                  }
                  break;
                case '+':
                  if(chsNeeded)  pemAddNumber(ITM_CHS, false);  // '-' was already encountered, let's first negate the real part
                  chsNeeded = false;
                  if(opParam == BINARY_COMPLEX34) {
                    //printf("**[DL]** fnEdit pemAddNumber ITM_CC aimBuffer %s\n",aimBuffer);fflush(stdout);
                    pemAddNumber(ITM_CC, false);
                    decimalflag = false;
                  }
                  break;
                case '-':
                  if(isDate) {
                    if(!decimalflag) {
                      decimalflag = true;
                      pemAddNumber(ITM_PERIOD, false);
                    }
                  }
                  else {
                    if(chsNeeded) pemAddNumber(ITM_CHS, false);  // second time '-' is encountered, let's first negate the real part
                    chsNeeded = true;
                    if(opParam == BINARY_COMPLEX34) {
                      //printf("**[DL]** fnEdit pemAddNumber ITM_CC aimBuffer %s\n",aimBuffer);fflush(stdout);
                      pemAddNumber(ITM_CC, false);
                      decimalflag = false;
                    }
                  }
                  break;
                case '/':
                  if(isDate) {
                    if(!decimalflag) {
                      decimalflag = true;
                      pemAddNumber(ITM_PERIOD, false);
                    }
                  }
                  break;
                case 'e':
                  if(chsNeeded) pemAddNumber(ITM_CHS, false);           // change mantissa sign before entering exponent
                  chsNeeded = false;
                  pemAddNumber(ITM_EXPONENT, false);
                  break;
                case 'i':
                  pemAddNumber(ITM_CC, false);
                  decimalflag = false;
                  break;
                case 0x80:
                  i++;
                  //printf("**[DL]**        tempBuffer[%2d] %02x\n",i,tempBuffer[i]&0xff);fflush(stdout);
                  if((tempBuffer[i] == STD_CROSS[1]) && (nimNumberPart != NP_COMPLEX_INT_PART)) {
                    i += 2; // Skip next character (STD_BASE_10)
                    if(chsNeeded) pemAddNumber(ITM_CHS, false);         // change mantissa sign before entering exponent
                    chsNeeded = false;
                    pemAddNumber(ITM_EXPONENT, false);
                  }
                  else if((tempBuffer[i] == STD_DEGREE[1]) && (opParam == STRING_ANGLE_DMS)) {
                    pemAddNumber(ITM_PERIOD, false);
                  }
                  break;
                case 0xa1:
                  i++;
                  //printf("**[DL]**        tempBuffer[%2d] %02x\n",i,tempBuffer[i]&0xff);fflush(stdout);
                  if((tempBuffer[i] >= STD_SUP_0[1]) && (tempBuffer[i] <= STD_SUP_9[1])) {
                    pemAddNumber(ITM_0 + tempBuffer[i] - STD_SUP_0[1], false);
                  }
                  else if(tempBuffer[i] == STD_SUP_MINUS[1]) {
                    chsNeeded = true;
                  }
                  else if(((tempBuffer[i] == STD_op_i[1]) || (tempBuffer[i] == STD_op_j[1])) &&
                          (nimNumberPart != NP_COMPLEX_INT_PART)) {
                    //printf("**[DL]** fnEdit pemAddNumber ITM_op_j aimBuffer %s\n",aimBuffer);fflush(stdout);
                    pemAddNumber(ITM_CC, false);
                    decimalflag = false;
                  }
                  //printf("**[DL]** fnEdit pemAddNumber %02x aimBuffer %s\n",tempBuffer[i],aimBuffer);fflush(stdout);
                  break;
                case 0x81:
                case 0x82:
                case 0x83:
                case 0x9d:
                case 0x9e:
                case 0xa0:
                case 0xa2:
                case 0xa3:
                case 0xa4:
                case 0xa5:
                case 0xa6:
                case 0xa7:
                case 0xa9:
                case 0xab:
                case 0xac:
                  i++;   // Ignore non supported unicode characters, including base subscripts
                  //printf("**[DL]**        tempBuffer[%2d] %02x\n",i,tempBuffer[i]&0xff);fflush(stdout);
                  break;
                default:
                  //printf("**[DL]** dflt   tempBuffer[%2d] %02x\n",i,tempBuffer[i]&0xff);fflush(stdout);
                  break;
              }
              lastIntegerBase = (opParam == BINARY_SHORT_INTEGER ? opParam2: opParam == STRING_SHORT_INTEGER ? opParam2: 0);
            }
            if(chsNeeded) pemAddNumber(ITM_CHS, false);
            switch (opParam) {
              case STRING_DATE:
              case STRING_TIME:
              case STRING_ANGLE_RADIAN:
              case STRING_ANGLE_GRAD:
              case STRING_ANGLE_DEGREE:
              case STRING_ANGLE_DMS:
              case STRING_ANGLE_MULTPI: {
                editingLiteralType = opParam;
                break;
              }
              default:
                editingLiteralType = 0;
            }
            pemAddNumber(ITM_NOP, true);    // to insert the resulting number in program
            //printf("**[DL]** fnEdit editingLiteralType %d aimBuffer %s\n",editingLiteralType,aimBuffer);fflush(stdout);
          }
          else {
            ;
          }
        }
        else {
          uint16_t regNumber;
          uint16_t paramMode = (indexOfItems[func].status & PTP_STATUS) >> 9;
          switch (paramMode) {
            case PARAM_DECLARE_LABEL:
            case PARAM_LABEL:
            case PARAM_REGISTER:
            case PARAM_FLAG:
            case PARAM_NUMBER_8:
            case PARAM_NUMBER_16:            // Used only for "BestF", "RNG", "DMX", "YY"
            case PARAM_COMPARE:
            case PARAM_SKIP_BACK:
            case PARAM_NUMBER_8_16:          // Used only for "CNST
            case PARAM_SHUFFLE:              // Used only for "<>"
            case PARAM_MENU: {               // Used only for "OPENM"
              deleteStepsFromTo(currentStep, findNextStep(currentStep));
              if(!pemCursorIsZerothStep) fnBst(NOPARAM);
              tamEnterMode(func);

              uint8_t maxDigits = tam.max < 10 ? 1 : (tam.max < 100 ? 2 : (tam.max < 1000 ? 3 : (tam.max < 10000 ? 4 : 5)));

              if((opParam == INDIRECT_REGISTER) && (!isFunctionOldParam16(func)))  {
                tam.indirect = true;
                tam.max = 99;
                maxDigits = 2;
                opParam = opParam2;
                opParam2 = opParam3;
                popSoftmenu();
                showSoftmenu(-MNU_TAM);
                --numberOfTamMenusToPop;
              }
              else if((opParam == INDIRECT_VARIABLE) && (!isFunctionOldParam16(func)))   {
                tam.indirect = true;
                opParam = STRING_LABEL_VARIABLE;
                popSoftmenu();
                showSoftmenu(-MNU_TAM);
                --numberOfTamMenusToPop;
              }

              regNumber = opParam;
              if((paramMode == PARAM_REGISTER) || (paramMode == PARAM_COMPARE) || tam.indirect) {
                if(opParam <= LAST_SPARE_REGISTERS_IN_KS_CODE) { // Global register from 00 to 99, Lettered register from X to K, or Local register from .00 to .98
                  regNumber = regKStoC(opParam);
                }
              }

              if ((paramMode == PARAM_FLAG) && opParam == SYSTEM_FLAG_NUMBER) {                 // System flag
                tam.digitsSoFar = 0;
                tam.value = 0;
              }
              else if(opParam == STRING_LABEL_VARIABLE) {      // Variable name
                tam.digitsSoFar = 0;
                tam.value = 0;
              }
              else if ((paramMode == PARAM_COMPARE) && ((opParam == VALUE_0) ||(opParam == VALUE_1)))  {  // Comparison to 0 or 1
                tam.digitsSoFar = 0;
                tam.value = 0;
              }
              else if((paramMode == PARAM_FLAG) && opParam > LAST_GLOBAL_FLAG) {                // Local flag
                tam.dot = true;
                tam.digitsSoFar = maxDigits - 1;
                tam.value = (opParam - FIRST_LOCAL_FLAG) / 10;
              }
              else if(((paramMode == PARAM_REGISTER) || (paramMode == PARAM_COMPARE) || tam.indirect) && (regNumber > LAST_GLOBAL_REGISTER)) {    // Local register
                tam.dot = true;
                tam.digitsSoFar = maxDigits - 1;
                tam.value = (regNumber - FIRST_LOCAL_REGISTER) / 10;
              }
              else if(((paramMode == PARAM_REGISTER) || (paramMode == PARAM_FLAG) || (paramMode == PARAM_COMPARE)|| tam.indirect) && opParam >= REGISTER_X) {    // Lettered flag or register from X to K
                tam.digitsSoFar = 0;
                tam.value = 0;
              }
              else if(((paramMode == PARAM_DECLARE_LABEL) || (paramMode == PARAM_LABEL)) && opParam >= 100) {    // Local label from A to E or Label name
                tam.digitsSoFar = 0;
                tam.value = 0;
              }
              else if((paramMode == PARAM_NUMBER_16) && !tam.indirect) {     // BestF, RNG, DMX, YY parameter
                tam.digitsSoFar =  maxDigits - 1;
                if(isFunctionOldParam16(func)) {  // original Param16 functions without indirection support (little endian parameter)
                  tam.value = ((opParam2 << 8) + opParam) / 10;
                }
                else {                        // new Param16 functions with indirection support (big endian parameter)
                  tam.value = ((opParam << 8) + opParam2) / 10;
                }
                //tam.value = (opParam & 0X3F) + 0X1500;     // remove last shuffled register
              }
              else if(paramMode == PARAM_SHUFFLE) {       // Stack registers shuffle
                tam.digitsSoFar = 3;
                tam.value = (opParam & 0X3F) + 0X1500;    // remove last shuffled register
              }
              else if ((paramMode == PARAM_NUMBER_8_16) && opParam == CNST_BEYOND_250) {         // Constant from 250 to 499
                tam.digitsSoFar = maxDigits - 1;
                tam.value = (opParam2 / 10) + 25;
              }
              else {                                    // Number, numbered register 0-99, local label 0-99
                tam.digitsSoFar =  maxDigits - 1;
                tam.value = opParam / 10;
              }
              //printf("**[DL]** tamProcessInput func %d aimBuffer %s\n",func,aimBuffer);fflush(stdout);
              tamProcessInput(func);
              //scrollPemBackwards();
              if(opParam == STRING_LABEL_VARIABLE) {      // Variable name : Label or  edit name string
                tamProcessInput(ITM_alpha);
                varOrLblName[6] = 0;  // Ensure name is 6 characters maximum
                strcpy(aimBuffer, varOrLblName);
                T_cursorPos = strlen(varOrLblName);
                tamProcessInput(ITM_NOP);                 // to insert the resulting string in program
              }

              break;
            }


            case PARAM_KEYG_KEYX: {                            // Key Goto or Key eXecute
              func = (opParam2 == ITM_GTO ? ITM_KEYG : ITM_KEYX);
              deleteStepsFromTo(currentStep, findNextStep(currentStep));
              runFunction(func);
              tamProcessInput(ITM_0 + opParam/10);
              tamProcessInput(ITM_0 + (opParam % 10));
              if((opParam3 == INDIRECT_REGISTER) || (opParam3 == INDIRECT_VARIABLE)) {
                tamProcessInput(ITM_INDIRECTION);
              }
              scrollPemBackwards();
              break;
            }

            default: {
              ;
            }
          }
        }
        break;
      }

      default:
err:
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        #if (EXTRA_INFO_ON_CALC_ERROR == 1)
          sprintf(errorMessage, "Calculator mode or type not supported for EDIT command");
          moreInfoOnError("In function fnEdit:", errorMessage, NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        break;
    }
  #endif
}


#ifdef DMCP_BUILD
  void standardScreenDump(void) {
  resetShiftState();                  //JM To avoid f or g top left of the screen, clear to make sure
  int32_t vol = 0;
  vol = getBeepVolume();
  fnSetVolume(11);
  _Buzz(100,5);
  xcopy(tmpString, errorMessage, ERROR_MESSAGE_LENGTH + AIM_BUFFER_LENGTH + NIM_BUFFER_LENGTH + TAM_BUFFER_LENGTH);       //backup portion of the "message buffer" area in DMCP used by ERROR..AIM..NIM buffers, to the tmpstring area in DMCP. DMCP uses this area during create_screenshot.
  create_screenshot(0);      //Screen dump
  xcopy(errorMessage, tmpString, ERROR_MESSAGE_LENGTH + AIM_BUFFER_LENGTH + NIM_BUFFER_LENGTH + TAM_BUFFER_LENGTH);        //   This total area must be less than the tmpString storage area, which it is.
  _Buzz(100,5);
  fnSetVolume((uint16_t)vol);
}
#endif //DMCP_BUILD


bool_t anyKeyWaiting(void) {
  #if defined(DMCP_BUILD)
    return key_empty() == 0 || key_tail() != -1;
  #elif defined(PC_BUILD) // !DMCP_BUILD
    //printf("KeyWaiting keyCode=%u",currentKeyCode);
    return currentKeyCode == 32; //EXIT1 / EXIT key //Do not us gtk_events_pending() as it triggers for timers too
  #endif // PC_BUILD
  return false;
}



bool_t exitKeyWaiting(void) {
  #if defined(DMCP_BUILD)
    bool_t checkKey = C47PopKeyNoBuffer(DISPLAY_WAIT_FOR_RELEASE) == 32;
    if(!checkKey) {
      key_pop_all();
      clearKeyBuffer();
    }
    return checkKey;
  #elif defined(PC_BUILD) // !DMCP_BUILD
    //printf("KeyWaiting keyCode=%u",currentKeyCode);
    return currentKeyCode == 32; //EXIT1 / EXIT key //Do not us gtk_events_pending() as it triggers for timers too
  #endif // PC_BUILD
  return false;
}


int C47PopKeyNoBuffer(bool_t displayWaitForRelease) {
  int tmpf = -1;
  #if defined(DMCP_BUILD)
    if(!anyKeyWaiting()) return -1;
    if(displayWaitForRelease) {
      #if !defined(TESTSUITE_BUILD)
        showString("Waiting for key ...", &standardFont, 20, 40, vmNormal, false, false);
      #endif //!TESTSUITE_BUILD
      force_refresh(force);
////Monitor key codes on screen
//char sss[22];
//sprintf(sss,"%i   AA ",sys_last_key());
//print_linestr(sss,true);
    }
    wait_for_key_release(0);
    bool_t signalToDoScreenDump = false;
    bool_t signalToDoEXIT       = false;
    bool_t signalToDoRS         = false;
    int tmpz = -1;
    while(anyKeyWaiting()) {
      tmpz = key_pop();
      if(tmpz > 0) tmpf = tmpz;                     //use the last key in the buffer
      if(tmpz == 44) signalToDoScreenDump = true;   //if any key in the buffer is 44
      if(tmpz == 33) signalToDoEXIT = true;
      if(tmpz == 36) signalToDoRS = true;
    }

    if(signalToDoScreenDump) {
      standardScreenDump();
      tmpf = 0;
    }
    if(signalToDoRS) {
      tmpf = 36;
    }
    if(signalToDoEXIT) {
      tmpf = 33;
    }
    return tmpf - 1;        //EXIT = 33-1
  #else // !DMCP_BUILD
    tmpf = currentKeyCode;
    currentKeyCode = 255;
    return tmpf;           //EXIT = 32
  #endif // DMCP_BUILD
}


void fnShoiXRepeats(uint16_t numberOfRepeats) {           //JM SHOIDISP
  displayStackSHOIDISP = numberOfRepeats;                 //   0-3
  fnRefreshState();

  //if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
  //  fnChangeBaseJM(getRegisterTag(REGISTER_X));
  //}
  //else {
  //  if(lastIntegerBase > 1 && lastIntegerBase <= 16) {
  //    fnChangeBaseJM(lastIntegerBase);
  //  }
  //}
}


void fnCFGsettings(uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
    runFunction(ITM_FF);
    showSoftmenu(-MNU_SYSFL);
  #endif // !TESTSUITE_BUILD
}


//=-=-=-=-=-=-==-=-
//input is date
//output is ymd coded decimal yyyy.mmdd in the form of a normal decimal
void fnFrom_ymd(uint16_t unusedButMandatoryParameter){
  #if !defined(TESTSUITE_BUILD)
    if(getRegisterDataType(REGISTER_X) == dtDate) {
      fnToReal(NOPARAM);
    }
  #endif // !TESTSUITE_BUILD
}



//=-=-=-=-=-=-==-=-
//input is time or DMS
//output is sexagesima coded decimal ddd.mmsssssss in the form of a normal decimal
void fnFrom_ms(uint16_t unusedButMandatoryParameter){
  #if !defined(TESTSUITE_BUILD)
    char tmpString100[100];
    char tmpString100_OUT[100];
    tmpString100[0] = 0;
    tmpString100_OUT[0] = 0;

    if(getRegisterDataType(REGISTER_X) == dtTime) {
      temporaryInformation = TI_FROM_MS_TIME;
    }
    else if(getRegisterDataType(REGISTER_X) == dtReal34 && getRegisterAngularMode(REGISTER_X) != amNone) {
      if(getRegisterAngularMode(REGISTER_X) != amDMS) {
        fnAngularModeJM(amDMS);
      }
      temporaryInformation = TI_FROM_MS_DEG;
    }
    else {
      temporaryInformation = TI_NO_INFO;
    }

    if(temporaryInformation != TI_NO_INFO) {
      if(temporaryInformation == TI_FROM_MS_TIME) {
        copyRegisterToClipboardString2(REGISTER_X, tmpString100);
      }
      if(temporaryInformation == TI_FROM_MS_DEG) {
        real34ToDisplayString(REGISTER_REAL34_DATA(REGISTER_X), getRegisterAngularMode(REGISTER_X), tmpString100, &standardFont, SCREEN_WIDTH, NUMBER_OF_DISPLAY_DIGITS, !LIMITEXP, FRONTSPACE, NOIRFRAC);
        int16_t tmp_i = 0;
        while(tmpString100[tmp_i] != 0 && tmpString100[tmp_i+1] != 0) { //pre-condition the dd.mmssss to replaxce spaces with zeroes
          //printf("%c %d", tmpString100[tmp_i], tmpString100[tmp_i]);
          if((uint8_t)tmpString100[tmp_i] == 128 && (uint8_t)tmpString100[tmp_i+1] == 176) {
            tmpString100[tmp_i]   = ' ';
            tmpString100[tmp_i+1] = 'o';
          }
          if((uint8_t)tmpString100[tmp_i] == 'o' && (uint8_t)tmpString100[tmp_i+1] == ' ') {
            tmpString100[tmp_i+1] = '0';
          }
          if((uint8_t)tmpString100[tmp_i] == ':' && (uint8_t)tmpString100[tmp_i+1] == ' ') {
            tmpString100[tmp_i+1] = '0';
          }
          if((uint8_t)tmpString100[tmp_i] == '\'' && (uint8_t)tmpString100[tmp_i+1] == ' ') {
            tmpString100[tmp_i+1] = '0';
          }
          tmp_i++;
        }
      }

      //printf(" ------- 002 >>>%s<<<\n", tmpString100);

      int16_t tmp_j, tmp_i;
      tmp_i = tmp_j = 0;
      bool_t decimalflag = false;
      while(tmpString100[tmp_i] != 0) {
        //printf("%c %d",(uint8_t)tmpString100[tmp_i], (uint8_t)tmpString100[tmp_i]);
        switch((uint8_t)tmpString100[tmp_i]) {
          case '0' :
          case '1' :
          case '2' :
          case '3' :
          case '4' :
          case '5' :
          case '6' :
          case '7' :
          case '8' :
          case '9' :
          case '+' :
          case '-' :
            //printf("-\n");
            tmpString100_OUT[tmp_j] = (uint8_t)tmpString100[tmp_i];
            tmpString100_OUT[++tmp_j] = 0;
            break;
          case 'o' :
          case ':' :
          case '.' :
          case ',' :
            if(!decimalflag) {
              //printf("decimal\n");
              decimalflag = true;
              tmpString100_OUT[tmp_j] = '.';
              tmpString100_OUT[++tmp_j] = 0;
            }
            break;
          default:
            //printf("ignore.\n");
            break;
        }
        tmp_i++;
      }

      if(tmpString100_OUT[0] != 0) {
        reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
        stringToReal34(tmpString100_OUT, REGISTER_REAL34_DATA(REGISTER_X));
        #if (EXTRA_INFO_ON_CALC_ERROR == 1)
          printf("\n ------- 003 >>>%s<<<\n",tmpString100_OUT);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      }
    }

    //stringToReal(tmpString100, &value, &ctxtReal39);
  #endif // !TESTSUITE_BUILD
}


/*
* If in direct entry, accept h.ms, example 1.23 [.ms] would be 1:23:00. Do not change the ADM.
* If closed in X: and X is REAL/integer, then convert this to h.ms. Do not change the ADM.
* If closed in X: and X is already a Time in visible hms like 1:23:45, then change the time to REAL, then tag the REAL with d.ms (‘’) in the form 1°23’45.00’’. Do not change the ADM.
* if closed in X: and X is already d.ms, then convert X to time in h:ms.Do not change the ADM.
*/
//


// 2023-09-07
// Current operation:
//   A.    From NIM press .ms: always real/integer (no angle), converting the digits to “h” ”m” ”s”:
//   a.    Example 1.2345 .ms -> 1:23:45, No change.
//
//   B.    With H:M:S (1:23:45) in X, press .ms (again): rewrite the hexadecimal digits and tag as angle
//   a.    Example 1:23:45 in X, .ms -> 1°23’45’’ tagged angle, No change
//
//   C.    With Real/Integer (hours) in X press .ms: -> convert X hours to HMS:
//   a.    Example 1.2345 ENTER, .ms -> 1:14:04.2, No change.
//
//   D.    Tagged angle in X: RAD GRAD MULpi in X, .ms: no action. Proposed change.
//
//   E.    Tagged angle in X: DMS, press .ms: rewrite D:M:S to H:M:S. No change.
//   a.    Press .ms again, see (B)
//
//   F.    Tagged angle in X: DEG, .ms: do >>DMS
//   a.    Press again, see (E), the cyclic continue as now, no change
//
// I propose these CHANGES for Tagged angles only:
//   D.    Tagged angle in X: RAD GRAD MULpi in X, .ms: Change to do: >>DMS
//   a.    Press again, see (E), the cyclic continue as now, no change




void fnTo_ms(uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
    switch(calcMode) { //JM
      case CM_NIM:
        addItemToNimBuffer(ITM_ms);
        break;

      case CM_NORMAL:
        copySourceRegisterToDestRegister(REGISTER_L, TEMP_REGISTER_1); // STO TMP

        switch(getRegisterDataType(REGISTER_X)) { //if integer, make a real
          case dtShortInteger:
            convertShortIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
            break;
          case dtLongInteger:
            convertLongIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
            break;
          default:
            break;
        }

        if(getRegisterDataType(REGISTER_X) == dtReal34) {
          if(getRegisterAngularMode(REGISTER_X) == amDMS) {
            if(calcMode == CM_NORMAL) {
              fnToReal(0);
            }
            else if(calcMode == CM_NIM) {
              addItemToNimBuffer(ITM_dotD);
            }
            fnHRtoTM(0);
          }
          else if(getRegisterAngularMode(REGISTER_X) == amDegree // ||
//             getRegisterAngularMode(REGISTER_X) == amRadian ||
//             getRegisterAngularMode(REGISTER_X) == amGrad   ||
//             getRegisterAngularMode(REGISTER_X) == amMultPi
            ) {
            fnAngularModeJM(amDMS);
          }
          else if(getRegisterAngularMode(REGISTER_X) == amNone) {
            fnHRtoTM(0);
          }
          else {
            displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            #if (EXTRA_INFO_ON_CALC_ERROR == 1)
              sprintf(errorMessage, "cannot calculate specific type/tag");
              moreInfoOnError("In function fnTo_ms:", errorMessage, NULL, NULL);
            #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
          }
        }
        else if(getRegisterDataType(REGISTER_X) == dtTime) {
          fnToHr(0);
          setRegisterAngularMode(REGISTER_X, amDegree);
          fnCvtFromCurrentAngularMode(amDMS);
        }

        copySourceRegisterToDestRegister(TEMP_REGISTER_1, REGISTER_L); // STO TMP
        break;

      case CM_REGISTER_BROWSER:
      case CM_ASN_BROWSER:
      case CM_FLAG_BROWSER:
      case CM_FONT_BROWSER:
      case CM_PLOT_STAT:
      case CM_LISTXY: //JM
      case CM_GRAPH:  //JM
        break;

      default:
        sprintf(errorMessage, commonBugScreenMessages[bugMsgCalcModeWhileProcKey], "fnTo_ms", calcMode, ".ms");
        displayBugScreen(errorMessage);
    }
  #endif // !TESTSUITE_BUILD
}


void addzeroes(char *st, uint8_t ix) {
  uint_fast8_t iy;
  strcpy(st, "1");
  for(iy = 0; iy < ix; iy++) {
    strcat(st, "0");
  }
}


void fnMultiplySI(uint16_t multiplier) {
  copySourceRegisterToDestRegister(REGISTER_L, TEMP_REGISTER_1); // STO TMP
  char mult[64];
  char divi[64];
  mult[0] = 0;
  divi[0] = 0;

  uint16_t base = 10;

  if(multiplier > 100 && multiplier <= 100 + 18) {
    addzeroes(mult, multiplier - 100);
    base = 10;
  }
  else if(multiplier < 100 && multiplier >= 100 - 18) {
    addzeroes(divi, 100 - multiplier);
    base = 10;
  }
  else if(multiplier == 100) {
    strcpy(mult, "1");
    base = 10;
  }
  else if(multiplier > 200 && multiplier <= 200 + 50) {
    addzeroes(mult, multiplier - 200);
    base = 2;
  }
  else if(multiplier == 200) {
    strcpy(mult, "1");
    base = 2;
  }


  setSystemFlag(FLAG_ASLIFT);
  liftStack();
  longInteger_t lgInt;
  longIntegerInit(lgInt);

  if(mult[0] != 0) {
    stringToLongInteger(mult + (mult[0] == '+' ? 1 : 0), base, lgInt);
    convertLongIntegerToLongIntegerRegister(lgInt, REGISTER_X);
    longIntegerFree(lgInt);
    fnMultiply(0);
  }
  else if(divi[0] != 0) {
    stringToLongInteger(divi + (divi[0] == '+' ? 1 : 0), base, lgInt);
    convertLongIntegerToLongIntegerRegister(lgInt, REGISTER_X);
    longIntegerFree(lgInt);
    fnDivide(0);
  }

  adjustResult(REGISTER_X, false, false, REGISTER_X, REGISTER_Y, -1);
  copySourceRegisterToDestRegister(TEMP_REGISTER_1, REGISTER_L); // STO TMP
}


#define forcedLiftTheStack true

static void cpxToStk(const real_t *real1, const real_t *real2, const bool_t sl) {
  if(sl == forcedLiftTheStack) setSystemFlag(FLAG_ASLIFT);
  liftStack();
//  reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
//  realToReal34(real1, REGISTER_REAL34_DATA(REGISTER_X));
//  realToReal34(real2, REGISTER_IMAG34_DATA(REGISTER_X));
//  adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
  convertComplexToResultRegister(real1, real2, REGISTER_X);
}


void fn_cnst_op_j(uint16_t unusedButMandatoryParameter) {
  if(calcMode == CM_NIM || calcMode == CM_MIM) {
    fnKeyCC(ITM_op_j);
  }
  else {
    cpxToStk(const_0, const_1, !forcedLiftTheStack);
  }
}


void fn_cnst_op_j_pol(uint16_t unusedButMandatoryParameter) {
  if(calcMode == CM_NIM || calcMode == CM_MIM) {
    fnKeyCC(ITM_op_j_pol);
  }
  else {
    cpxToStk(const_0, const_1, !forcedLiftTheStack);
    fnToPolar2(0);
  }
}


void fn_cnst_op_aa(uint16_t unusedButMandatoryParameter) {
  cpxToStk(const_1on2, const_root3on2, !forcedLiftTheStack);
  chsCplx();
}


void fn_cnst_op_a(uint16_t unusedButMandatoryParameter) {
  fn_cnst_op_aa(0);
  conjCplx();
}


void fn_cnst_0_cpx(uint16_t unusedButMandatoryParameter) {
  cpxToStk(const_0, const_0, !forcedLiftTheStack);
}


void fn_cnst_1_cpx(uint16_t unusedButMandatoryParameter) {
  cpxToStk(const_1, const_0, !forcedLiftTheStack);
}

struct cmplxPair {
  real_t r, i;
};

void fn_cnst_op_A(uint16_t unusedButMandatoryParameter) {
  complex34Matrix_t matrixC;

  if(!saveLastX()) {
    return;
  }

  setSystemFlag(FLAG_ASLIFT);
  liftStack();
  convertRealToResultRegister(const_0, REGISTER_X,amNone);

  //Initialize Memory for Matrix
  if(initMatrixRegister(REGISTER_X, 3, 3, true)) {
  }
  else {
    displayCalcErrorMessage(ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "Not enough memory for a %" PRIu32 STD_CROSS "%" PRIu32 " matrix", 1, 1);
      moreInfoOnError("In function fn_cnst_op_A:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }
  adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);

  linkToComplexMatrixRegister(REGISTER_X,  &matrixC);

  real_t const__rt3on2, const_rt3on2, const__1on2;
  realDivide(const_rt3,const_2,&const_rt3on2,&ctxtReal39);
  realDivide(const_rt3,const_2,&const__rt3on2,&ctxtReal39);
  realSetNegativeSign(&const__rt3on2);
  realCopy(const_1on2,&const__1on2);
  realSetNegativeSign(&const__1on2);

  realToReal34(&const__1on2, VARIABLE_REAL34_DATA(&matrixC.matrixElements[4]));
  realToReal34(&const__rt3on2, VARIABLE_IMAG34_DATA(&matrixC.matrixElements[4]));
  realToReal34(&const__1on2, VARIABLE_REAL34_DATA(&matrixC.matrixElements[5]));
  realToReal34(&const_rt3on2, VARIABLE_IMAG34_DATA(&matrixC.matrixElements[5]));
  realToReal34(&const__1on2, VARIABLE_REAL34_DATA(&matrixC.matrixElements[7]));
  realToReal34(&const_rt3on2, VARIABLE_IMAG34_DATA(&matrixC.matrixElements[7]));
  realToReal34(&const__1on2, VARIABLE_REAL34_DATA(&matrixC.matrixElements[8]));
  realToReal34(&const__rt3on2, VARIABLE_IMAG34_DATA(&matrixC.matrixElements[8]));

  for (int i = 0; i < 3; i++) {
    realToReal34(const_1, VARIABLE_REAL34_DATA(&matrixC.matrixElements[i]));
    real34Zero(VARIABLE_IMAG34_DATA(&matrixC.matrixElements[i]));
    if(i != 0) {
      realToReal34(const_1, VARIABLE_REAL34_DATA(&matrixC.matrixElements[i*3]));
      real34Zero(VARIABLE_IMAG34_DATA(&matrixC.matrixElements[i*3]));
    }
  }
  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}



TO_QSPI static const struct {
    unsigned rows  : 2;
    unsigned cols  : 2;
    unsigned x     : 2;
    unsigned y     : 2;
    unsigned z     : 2;
    unsigned xdef  : 2;
    unsigned ydef  : 2;
    unsigned zdef  : 2;
} vecCreate[] = {
//  type     r  c   x    y    z   xdef ydef zdef
    [ 1] = { 3, 1,  2 ,  1,   0,   2,   2,   2 },     // 3x1 vector created from xyz FOR ELEC menu
    [ 2] = { 1, 3,  0 ,  1,   2,   2,   2,   2 },     // 1x3 vector created from zyx FOR MATX menu
    [ 3] = { 1, 3,  0 ,  1,   2,   0,   0,   1 },     // 1x3 unity vectors 100
    [ 4] = { 1, 3,  0 ,  1,   2,   0,   1,   0 },     // 1x3 unity vectors 010
    [ 5] = { 1, 3,  0 ,  1,   2,   1,   0,   0 },     // 1x3 unity vectors 001

    [ 6] = { 1, 2,  0 ,  1,   3,   2,   2,   3 },     // 1x2 vector created from yx
    [ 7] = { 1, 2,  0 ,  1,   3,   0,   1,   3 },     // 1x2 unity vectors 10
    [ 8] = { 1, 2,  0 ,  1,   3,   1,   0,   3 }      // 1x2 unity vectors 01

    // r c is the size of the matrix to be created, eg. 1x3 or 2x1 etc.
    // x y z are the matrix element number mapping to the register name, eg. x=2 means x register goes to internal matrix element 2; 3 means not copied
    // xdef/ydef/zdef
    //   = 1/0 : the value to be pre-loaded into the matrix element
    //   = 2   : the value is copied from register X, Y or Z to the specified matrix element
    //   = 3   : not copied
  };


static bool_t processDefaultVector(calcRegister_t regist, uint8_t p, uint8_t d, struct cmplxPair *x, bool_t *complexCoefs) {
  if(d == 2) {
    if(!getRegisterAsComplexOrReal(regist, &x[p].r, &x[p].i, complexCoefs)) {
      return false;
    }
  }
  else if(d < 2) {
    realCopy(d == 1 ? const_1 : const_0, &x[p].r);
  }
  return true;
}


void fnConvertStkToMx(uint16_t constVector) {
  bool_t complexCoefs = false;
  struct cmplxPair x[3];
  real34Matrix_t matrix;
  complex34Matrix_t matrixC;
  uint16_t elements;

  elements = vecCreate[constVector].rows * vecCreate[constVector].cols;

  if(!processDefaultVector(REGISTER_X, vecCreate[constVector].x, vecCreate[constVector].xdef, x, &complexCoefs)) return;
  if(!processDefaultVector(REGISTER_Y, vecCreate[constVector].y, vecCreate[constVector].ydef, x, &complexCoefs)) return;
  if(max(vecCreate[constVector].z, vecCreate[constVector].zdef) != 3 &&
     !processDefaultVector(REGISTER_Z, vecCreate[constVector].z, vecCreate[constVector].zdef, x, &complexCoefs)) return;

  if(!saveLastX()) {
    return;
  }

  if(vecCreate[constVector].xdef < 2 || vecCreate[constVector].ydef < 2 || vecCreate[constVector].zdef < 2) {
    setSystemFlag(FLAG_ASLIFT);
    liftStack();
  } else {
    fnDrop(NOPARAM);
    if(elements > 2) {
      fnDrop(NOPARAM);
    }
  }


  if(getRegisterDataType(REGISTER_X) != dtReal34Matrix && getRegisterDataType(REGISTER_X) != dtComplex34Matrix) {
    //Initialize Memory for Matrix
    if(initMatrixRegister(REGISTER_X, vecCreate[constVector].rows, vecCreate[constVector].cols, complexCoefs)) {
    }
    else {
      displayCalcErrorMessage(ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "Not enough memory for a %" PRIu32 STD_CROSS "%" PRIu32 " matrix", 1, 1);
        moreInfoOnError("In function fnConvertStkToMx:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }
    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
  }


  if(complexCoefs) {
    linkToComplexMatrixRegister(REGISTER_X,  &matrixC);
  } else {
    linkToRealMatrixRegister(REGISTER_X,  &matrix);
  }


  for (int i = 0; i < elements; i++) {
    if(complexCoefs) {
      realToReal34(&x[elements-1-i].r, VARIABLE_REAL34_DATA(&matrixC.matrixElements[i]));
      realToReal34(&x[elements-1-i].i, VARIABLE_IMAG34_DATA(&matrixC.matrixElements[i]));
    }
    else {
      realToReal34(&x[elements-1-i].r, &matrix.matrixElements[i]);
    }
  }

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);

}

void fnConvertMxToStk(uint16_t param) {
  real34Matrix_t matrix;
  complex34Matrix_t matrixC;

  if(!(getRegisterDataType(REGISTER_X) == dtReal34Matrix || getRegisterDataType(REGISTER_X) == dtComplex34Matrix)) {
    return;
  }

  if(!saveLastX()) {
    return;
  }

  copySourceRegisterToDestRegister(REGISTER_X,TEMP_REGISTER_1);
  setSystemFlag(FLAG_ASLIFT);
  liftStack();
  setSystemFlag(FLAG_ASLIFT);
  liftStack();
  convertRealToResultRegister(const_0, REGISTER_X,amNone);
  convertRealToResultRegister(const_0, REGISTER_Y,amNone);
  convertRealToResultRegister(const_0, REGISTER_Z,amNone);

  if(getRegisterDataType(TEMP_REGISTER_1) == dtComplex34Matrix) {
    linkToComplexMatrixRegister(TEMP_REGISTER_1,  &matrixC);
  } else {
    linkToRealMatrixRegister(TEMP_REGISTER_1,  &matrix);
  }


  for (int i = 0; i < 3; i++) {
    uint16_t rg = vecCreate[param].x == 2-i ? REGISTER_X : vecCreate[param].y == 2-i ? REGISTER_Y : vecCreate[param].z == 2-i ? REGISTER_Z : 0;
    if(getRegisterDataType(TEMP_REGISTER_1) == dtComplex34Matrix) {
      real34Copy(VARIABLE_REAL34_DATA(&matrixC.matrixElements[i]),REGISTER_REAL34_DATA(rg));
      real34Copy(VARIABLE_REAL34_DATA(&matrixC.matrixElements[i]),REGISTER_IMAG34_DATA(rg));
    }
    else {
      real34Copy(&matrix.matrixElements[i],REGISTER_REAL34_DATA(rg));
    }
    adjustResult(rg, false, false, rg, -1, -1);
  }
}


//Rounding
void fnJM_2SI(uint16_t unusedButMandatoryParameter) { //Convert Real to Longint; Longint to shortint; shortint to longint
  if(calcMode == CM_NIM) {
    if((   (nimNumberPart == NP_INT_BASE && aimBuffer[strlen(aimBuffer) - 1] == '#')
        || (nimNumberPart == NP_INT_10 && lastIntegerBase > 0)   )) {
      #if defined (PC_BUILD)
        printf("Do not react when in NIM SI\n");
      #endif //PC_BUILD
      return;
    }
  }
  longInteger_t tmp1, tmp3;
  switch(getRegisterDataType(REGISTER_X)) {
    case dtLongInteger:
      convertLongIntegerRegisterToLongInteger(REGISTER_X, tmp3);
      if(shortIntegerMode == SIM_UNSIGN && longIntegerIsNegative(tmp3)) {
        temporaryInformation = TI_DATA_NEG_OVRFL;
      }
      convertLongIntegerRegisterToShortIntegerRegister(REGISTER_X, REGISTER_X); //default to 10
      if(lastIntegerBase >= 2 && lastIntegerBase <= 16 && lastIntegerBase != 10) {
        fnChangeBase(lastIntegerBase);
      }
      convertShortIntegerRegisterToLongInteger(REGISTER_X, tmp1);

      if(longIntegerCompare(tmp1,tmp3) != 0) {
        if(temporaryInformation != TI_DATA_NEG_OVRFL) {
          temporaryInformation = TI_DATA_LOSS;             // I cannot think of which condition will reach here, without other overflows overriding, but leaving it in
        }
        setSystemFlag(FLAG_OVERFLOW);
      }
      longIntegerFree(tmp1);
      longIntegerFree(tmp3);

      break;
    case dtReal34:
      fnRoundi(0);
      break;
    case dtShortInteger:
      convertShortIntegerRegisterToLongIntegerRegister(REGISTER_X, REGISTER_X); //This shortint to longint!
      lastIntegerBase = 0;                                                      //JMNIM clear lastintegerbase, to switch off hex mode
      fnRefreshState();                                                         //JMNIM
      break;
    default:
      break;
  }
}


/* JM UNIT********************************************//**                                                JM UNIT
 * \brief Adds the power of 10 using numeric font to displayString                                        JM UNIT
 *        Converts to units like m, M, k, etc.                                                            JM UNIT
 * \param[out] displayString char*     Result string                                                      JM UNIT
 * \param[in]  exponent int32_t Power of 10 to format                                                     JM UNIT
 * \return void                                                                                           JM UNIT
 ***********************************************                                                          JM UNIT */
void exponentToUnitDisplayString(int32_t exponent, bool_t flag2To10, char *displayString, char *displayValueString, bool_t nimMode) {               //JM UNIT

TO_QSPI static const char SIprefixes[64]  = "q  r  y  z  a  f  p  n  u  m     k  M  G  T  P  E  Z  Y  R  Q  ";
TO_QSPI static const char ITSIprefixes[16] = "K  M  G  T  P  ";

  displayString[0] = ' ';
  displayString[1] = 0;
  displayString[2] = 0;
  displayString[3] = 0;

  if(!flag2To10 && !getSystemFlag(FLAG_2TO10)) {
      if((-15 <= exponent && exponent <= 15) ||
        (-30 <= exponent && exponent <= 30 && getSystemFlag(FLAG_PFX_ALL))) {
        displayString[1] = SIprefixes[exponent + 30];
        if(displayString[1] == 'u') {
          displayString[1] = STD_mu[0]; displayString[2] = STD_mu[1];
        }
      }
  }
  else if(flag2To10) {                            //exponent of 2^(10/3)

      if((3 <= exponent && exponent <= 15)) {
        displayString[1] = ITSIprefixes[exponent - 3];
        displayString[2] = 'i';
      }
    }

  if(displayString[1] == 0) {
    strcpy(displayString, PRODUCT_SIGN);                                                                //JM UNIT Below, copy of
    displayString += 2;                                                                                 //JM UNIT exponentToDisplayString in display.c
    strcpy(displayString, STD_SUB_10);                                                                  //JM UNIT
    displayString += 2;                                                                                 //JM UNIT
    displayString[0] = 0;                                                                               //JM UNIT
    if(nimMode) {                                                                                       //JM UNIT
      if(exponent != 0) {                                                                               //JM UNIT
        supNumberToDisplayString(exponent, displayString, displayValueString, false);                   //JM UNIT
      }                                                                                                 //JM UNIT
    }                                                                                                   //JM UNIT
    else {                                                                                              //JM UNIT
      supNumberToDisplayString(exponent, displayString, displayValueString, false);                     //JM UNIT
    }                                                                                                   //JM UNIT
  }                                                                                                     //JM UNIT
}                                                                                                       //JM UNIT


void fnDisplayFormatCycle (uint16_t unusedButMandatoryParameter) {
  if(DM_Cycling == 0 && softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_PREFIX) {
    fnDisplayFormatUnit(displayFormatDigits);
  }
  else if(displayFormat == DF_UN) {
    fnDisplayFormatSigFig(displayFormatDigits);
  }
  else if(displayFormat == DF_SF ) {
    fnDisplayFormatAll(displayFormatDigits);
  }
  else if(displayFormat == DF_ALL) {
    fnDisplayFormatFix(displayFormatDigits);
  }
  else if(displayFormat == DF_FIX) {
    fnDisplayFormatSci(displayFormatDigits);
  }
  else if(displayFormat == DF_SCI) {
    fnDisplayFormatEng(displayFormatDigits);
  }
  else if(displayFormat == DF_ENG) {
    fnDisplayFormatUnit(displayFormatDigits);
  }
  DM_Cycling = 1;
}


//change the current state from the old state?
void fnAngularModeJM(uint16_t AMODE) { //Setting to HMS does not change AM
  #if !defined(TESTSUITE_BUILD)

  copySourceRegisterToDestRegister(REGISTER_X, TEMP_REGISTER_1);
  if(AMODE == TM_HMS) {
    if(getRegisterDataType(REGISTER_X) == dtTime) {
      goto to_return;
    }
    if(getRegisterDataType(REGISTER_X) == dtReal34 && getRegisterAngularMode(REGISTER_X) != amNone) {
      fnCvtFromCurrentAngularMode(amDegree);
    }

    if(calcMode == CM_NORMAL) {
      fnToReal(0);
    }
    else if(calcMode == CM_NIM) {
      addItemToNimBuffer(ITM_dotD);
    }

    fnHRtoTM(0); //covers longint & real
  }
  else {
    if(getRegisterDataType(REGISTER_X) == dtTime) {
      fnToHr(0); //covers time
      setRegisterAngularMode(REGISTER_X, amDegree);
      fnCvtFromCurrentAngularMode(AMODE);
      //fnAngularMode(AMODE);                             Remove updating of ADM to the same mode
    }

    if(getRegisterDataType(REGISTER_X) == dtComplex34 || getRegisterDataType(REGISTER_X) == dtComplex34Matrix) {
      //printf("###AA fnAngularModeJM (%i)<= %i\n",REGISTER_X, AMODE);
      //printf("###BB fnAngularModeJM (%i)=> %i\n",REGISTER_X, getRegisterTag(REGISTER_X));

      setComplexRegisterAngularMode(REGISTER_X, AMODE);
      setComplexRegisterPolarMode(REGISTER_X, amPolar);
      //printf("###CC fnAngularModeJM (%i)=> %i\n",REGISTER_X, getRegisterTag(REGISTER_X));
    }
    else {
      if((getRegisterDataType(REGISTER_X) != dtReal34) || ((getRegisterDataType(REGISTER_X) == dtReal34) && getRegisterAngularMode(REGISTER_X) == amNone)) {

        if(calcMode == CM_NORMAL) {         //convert longint, and strip all angles to real.
          fnToReal(0);
        }
        else if(calcMode == CM_NIM) {
          addItemToNimBuffer(ITM_dotD);
        }

        uint16_t currentAngularModeOld = currentAngularMode;
        fnAngularMode(AMODE);
        fnCvtFromCurrentAngularMode(currentAngularMode);
        currentAngularMode = currentAngularModeOld;       //Remove updating of ADM to the same mode (set in fnCvtFromCurrentAngularMode())
      }
      else { //convert existing tagged angle
        fnCvtFromCurrentAngularMode(AMODE);
      }
    }
  }

  to_return:
  copySourceRegisterToDestRegister(TEMP_REGISTER_1, REGISTER_L);
  #endif //TESTSUITE_BUILD
}



void DRG_cyc(uint16_t * dest) {
    DRG_Cycling = 1;
    switch(*dest) {
      case amNone:   *dest = currentAngularMode; break; //converts from to the same, i.e. get to current angle mode
      case amRadian: *dest = amGrad;             break;
      case amGrad:   *dest = amDegree;           break;
      case amDegree: *dest = amRadian;           break;
      case amDMS:    *dest = amDegree;           break;
      case amMultPi: *dest = amRadian;           break; //do not support Mulpi but at least get out of it
      default: ;
    }
  }


void fnDRG(uint16_t unusedButMandatoryParameter) {
  switch(getRegisterDataType(REGISTER_X)) {
    case dtTime:
    case dtDate:
    case dtString:
    case dtReal34Matrix:
    case dtConfig:
      goto to_return_noLastX;
      break;
    default: ;
  }

  copySourceRegisterToDestRegister(REGISTER_X, TEMP_REGISTER_1);
  uint16_t dest = 9999;

  if(getRegisterDataType(REGISTER_X) == dtComplex34 || getRegisterDataType(REGISTER_X) == dtComplex34Matrix) {
    setComplexRegisterPolarMode(REGISTER_X, amPolar);      //re-set it to Polar iven if it was there already
    dest = getComplexRegisterAngularMode(REGISTER_X);
    DRG_cyc(&dest);
    setComplexRegisterAngularMode(REGISTER_X,dest);

  }
  else if(getRegisterDataType(REGISTER_X) == dtShortInteger) {           // If shortinteger in X, convert to real
    convertShortIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
    setRegisterAngularMode(REGISTER_X, amNone);                          //is probably none already
  }
  else if(getRegisterDataType(REGISTER_X) == dtLongInteger) {            // If longinteger in X, convert to real
    convertLongIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
    setRegisterAngularMode(REGISTER_X, amNone);                          //is probably none already
  }

  if(getRegisterDataType(REGISTER_X) == dtReal34) {                      // if real
    dest = getRegisterAngularMode(REGISTER_X);

    if(dest != amNone && dest != currentAngularMode && DRG_Cycling != 1) {   //first step: convert tagged angle to ADM
      fnCvtToCurrentAngularMode(dest);
      goto to_return;
    }

    DRG_cyc(&dest);
    fnCvtFromCurrentAngularMode(dest);
    //currentAngularMode = dest;          //remove setting of ADM!
  }

  to_return:
  copySourceRegisterToDestRegister(TEMP_REGISTER_1, REGISTER_L);
  to_return_noLastX:
  return;
}


void shrinkNimBuffer(void) {                      //JMNIM vv
  int16_t lastChar; //if digits in NIMBUFFER, ensure switch to NIM,
  int16_t hexD = 0;
  bool_t reached_end = false;
  lastChar = strlen(aimBuffer) - 1;
  if(lastChar >= 1) {
    uint_fast16_t ix = 0;
    while(aimBuffer[ix] != 0) { //if # found in nimbuffer, return and do nothing
      if(aimBuffer[ix] >= 'A') {
        hexD++;
      }
      if(aimBuffer[ix] == '#' || aimBuffer[ix] == '.' || reached_end) { //chr(35) = "#"
        aimBuffer[ix] = 0;
        reached_end = true;
        //printf(">>> ***A # found. hexD=%d\n",hexD);
      }
      else {
        //printf(">>> ***B # not found in %s:%d=%d hexD=%d\n",nimBuffer,ix,nimBuffer[ix],hexD);
      }
      ix++;
    }
    if(hexD > 0) {
      nimNumberPart = NP_INT_16;
    }
    else {
      nimNumberPart = NP_INT_10;
    }
    //calcMode = CM_NIM;
  }
}                                                 //JMNIM ^^


void fnChangeBaseJM(uint16_t BASE) {
  #if !defined(TESTSUITE_BUILD)
    //printf(">>> §§§ fnChangeBaseJMa Calmode:%d, nimbuffer:%s, lastbase:%d, nimnumberpart:%d\n", calcMode, nimBuffer, lastIntegerBase, nimNumberPart);
    shrinkNimBuffer();
    fnChangeBase(BASE);

    if(getSystemFlag(FLAG_HPBASE)) {
      for(uint16_t regist = REGISTER_X + 1; regist < REGISTER_X + (getSystemFlag(FLAG_SSIZE8) ? 8 : 4); regist ++ ) {
        if(getRegisterDataType(regist) == dtShortInteger) {
          if(2 <= BASE && BASE <= 16) {
            setRegisterTag(regist, BASE);
          }
          fnRefreshState();
        }
      }
    }

    nimBufferToDisplayBuffer(aimBuffer, nimBufferDisplay + 2);
  #endif // !TESTSUITE_BUILD
}


void fnChangeBaseMNU(uint16_t BASE) {
  #if !defined(TESTSUITE_BUILD)

    if(calcMode == CM_AIM) {
      addItemToBuffer(ITM_toINT);
      return;
    }

    //printf(">>> §§§ fnChangeBaseMNUa Calmode:%d, nimbuffer:%s, lastbase:%d, nimnumberpart:%d\n", calcMode, nimBuffer, lastIntegerBase, nimNumberPart);
    shrinkNimBuffer();
    //printf(">>> §§§ fnChangeBaseMNUb Calmode:%d, nimbuffer:%s, lastbase:%d, nimnumberpart:%d\n", calcMode, nimBuffer, lastIntegerBase, nimNumberPart);

    if(lastIntegerBase == 0 && calcMode == CM_NORMAL && BASE > 1 && BASE <= 16) {
      //printf(">>> §§§fnChangeBaseMNc CM_NORMAL: convert non-shortint-mode to %d & return\n", BASE);
      fnChangeBaseJM(BASE);
      return;
    }

    if(calcMode == CM_NORMAL && BASE == NOPARAM) {
      //printf(">>> §§§fnChangeBaseMNd CM_NORMAL: convert non-shortint-mode to TAM\n");
      runFunction(ITM_toINT);
      return;
    }

    if(BASE > 1 && BASE <= 16) { //BASIC CONVERSION IN X REGISTER, OR DIGITS IN NIMBUFFER IF IN CM_NORMAL
      //printf(">>> §§§1 convert base to %d & return\n", BASE);
      fnChangeBaseJM(BASE);
      nimBufferToDisplayBuffer(aimBuffer, nimBufferDisplay + 2);
      return;
    }

    if(aimBuffer[0] == 0 && calcMode == CM_NORMAL && BASE == NOPARAM) { //IF # FROM MENU & TAM.
      //printf(">>> §§§2 # FROM MENU: nimBuffer[0]=0; use runfunction\n");
      runFunction(ITM_toINT);
      nimBufferToDisplayBuffer(aimBuffer, nimBufferDisplay + 2);
      return;
    }

    if(aimBuffer[0] != 0 && calcMode == CM_NIM) { //IF # FROM MENU, while in NIM, just add to NimBuffer
      //printf(">>> §§§3 # nimBuffer in use, addItemToNimBuffer\n");
      addItemToNimBuffer(ITM_toINT);
      nimBufferToDisplayBuffer(aimBuffer, nimBufferDisplay + 2);
      return;
    }

  #endif // !TESTSUITE_BUILD
}

/********************************************//**
 * \brief Set Input_Default
 *
 * \param[in] inputDefault uint16_t
 * \return void
 ***********************************************/
void fnInDefault(uint16_t inputDefault) {
  Input_Default = inputDefault;
  lastIntegerBase = 0;
  fnRefreshState();
}


void fnByteShortcutsS(uint16_t size) { //JM POC BASE2 vv
  fnSetWordSize(size);
  fnIntegerMode(SIM_2COMPL);
}


void fnByteShortcutsU(uint16_t size) {
  fnSetWordSize(size);
  fnIntegerMode(SIM_UNSIGN);
}


void fnP_Alpha(void) {
  #if !defined(TESTSUITE_BUILD)
    if(calcMode != CM_AIM) {
      #if defined(DMCP_BUILD)
        beep(440, 50);
        beep(4400, 50);
        beep(440, 50);
      #endif // DMCP_BUILD
      return;
    }
    xcopy(tmpString, aimBuffer, ERROR_MESSAGE_LENGTH + AIM_BUFFER_LENGTH + NIM_BUFFER_LENGTH);       //backup portion of the "message buffer" area in DMCP used by ERROR..AIM..NIM buffers, to the tmpstring area in DMCP. DMCP uses this area during create_screenshot.
    create_filename(".REGS.TSV");

    #if (VERBOSE_LEVEL >= 1)
      clearScreen(2);
      print_linestr("Output Aim Buffer to drive:", true);
      print_linestr(filename_csv, false);
    #endif // VERBOSE_LEVEL >= 1

    tmpString_csv_out(5);          //aimBuffer now already copied to tmpString
    xcopy(aimBuffer,tmpString, ERROR_MESSAGE_LENGTH + AIM_BUFFER_LENGTH + NIM_BUFFER_LENGTH);        //   This total area must be less than the tmpString storage area, which it is.
    //print_linestr(aimBuffer,false);
  #endif
}



void fnP_Regs (uint16_t registerNo) {
  #if !defined(TESTSUITE_BUILD)
    if(calcMode != CM_NORMAL) {
      #if defined(DMCP_BUILD)
        beep(440, 50);
        beep(4400, 50);
        beep(440, 50);
      #endif // DMCP_BUILD
      return;
    }

    create_filename(".REGS.TSV");

    #if (VERBOSE_LEVEL >= 1)
      clearScreen(3);
      print_linestr("Output regs to drive:", true);
      print_linestr(filename_csv, false);
    #endif // VERBOSE_LEVEL >= 1

    stackregister_csv_out((int16_t)registerNo, (int16_t)registerNo, !ONELINE);

  #endif // !TESTSUITE_BUILD
}



void fnP_All_Regs(uint16_t option) {
  #if !defined(TESTSUITE_BUILD)
    if(calcMode != CM_NORMAL && calcMode != CM_NO_UNDO) {
      #if defined(DMCP_BUILD)
        beep(440, 50);
        beep(4400, 50);
        beep(440, 50);
      #endif // DMCP_BUILD
      return;
    }

    create_filename(".REGS.TSV");

    #if (VERBOSE_LEVEL >= 1)
      clearScreen(4);
      print_linestr("Output regs to drive:", true);
      print_linestr(filename_csv, false);
    #endif // VERBOSE_LEVEL >= 1

    switch(option) {
      case PRN_ALL:
        stackregister_csv_out(REGISTER_X, REGISTER_W, !ONELINE);
        stackregister_csv_out(0, 99, !ONELINE);
        if(currentNumberOfLocalRegisters > 0) stackregister_csv_out(FIRST_LOCAL_REGISTER, FIRST_LOCAL_REGISTER + currentNumberOfLocalRegisters - 1, !ONELINE);
        if(numberOfNamedVariables > 0) stackregister_csv_out(FIRST_NAMED_VARIABLE, FIRST_NAMED_VARIABLE + numberOfNamedVariables - 1, !ONELINE);


        //stackregister_csv_out(FIRST_LOCAL_REGISTER, FIRST_LOCAL_REGISTER+100, !ONELINE);
        break;

      case PRN_STK:
        if(getSystemFlag(FLAG_SSIZE8)) {
          stackregister_csv_out(REGISTER_X, REGISTER_D, !ONELINE);
        }
        else {
          stackregister_csv_out(REGISTER_X, REGISTER_T, !ONELINE);
        }
        break;

      case PRN_GLOBALr:
        stackregister_csv_out(0, 99, !ONELINE);
        break;

      case PRN_LOCALr:
        if(currentNumberOfLocalRegisters > 0) stackregister_csv_out(FIRST_LOCAL_REGISTER, FIRST_LOCAL_REGISTER + currentNumberOfLocalRegisters - 1, !ONELINE);
        break;

      case PRN_NAMEDr:
        if(numberOfNamedVariables > 0) stackregister_csv_out(FIRST_NAMED_VARIABLE, FIRST_NAMED_VARIABLE + numberOfNamedVariables - 1, !ONELINE);
        break;

      case PRN_Xr:
        stackregister_csv_out(REGISTER_X, REGISTER_X, !ONELINE);
        break;

      case PRN_TMP:
        stackregister_csv_out(TEMP_REGISTER_1, TEMP_REGISTER_1, !ONELINE);
        break;

      case PRN_XYr:
        stackregister_csv_out(REGISTER_X, REGISTER_Y, ONELINE);
        break;

      default: ;
    }
  #endif // !TESTSUITE_BUILD
}


void doubleToXRegisterReal34(double x) { //Convert from double to X register REAL34
  setSystemFlag(FLAG_ASLIFT);
  liftStack();
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  snprintf(tmpString, TMP_STR_LENGTH, "%.16e", x);
  stringToReal34(tmpString, REGISTER_REAL34_DATA(REGISTER_X));
  //adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
  setSystemFlag(FLAG_ASLIFT);
}


void fnStrtoReg(const char buffer[], calcRegister_t regist) {                             //DONE
  int16_t mem = stringByteLength(buffer) + 1;
  reallocateRegister(regist, dtString, TO_BLOCKS(mem), amNone);
  xcopy(REGISTER_STRING_DATA(regist), buffer, mem);
}

void fnStrtoX(const char buffer[]) {                             //DONE
  setSystemFlag(FLAG_ASLIFT); // 5
  liftStack();
  fnStrtoReg(buffer, REGISTER_X);
  setSystemFlag(FLAG_ASLIFT);
}


void fnStrInputReal34(char inp1[]) { // CONVERT STRING to REAL IN X      //DONE
  tmpString[0] = 0;
  strcat(tmpString, inp1);
  setSystemFlag(FLAG_ASLIFT); // 5
  liftStack();
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  stringToReal34(tmpString, REGISTER_REAL34_DATA(REGISTER_X));
  setSystemFlag(FLAG_ASLIFT);
}


void fnStrInputLongint(char inp1[]) { // CONVERT STRING to Longint X      //DONE
  tmpString[0] = 0;
  strcat(tmpString, inp1);
  setSystemFlag(FLAG_ASLIFT); // 5
  liftStack();

  longInteger_t lgInt;
  longIntegerInit(lgInt);
  stringToLongInteger(tmpString + (tmpString[0] == '+' ? 1 : 0), 10, lgInt);
  convertLongIntegerToLongIntegerRegister(lgInt, REGISTER_X);
  longIntegerFree(lgInt);
  setSystemFlag(FLAG_ASLIFT);
}


void fnRCL(int16_t inp) { //DONE
  setSystemFlag(FLAG_ASLIFT);
  if(inp == TEMP_REGISTER_1) {
    liftStack();
    copySourceRegisterToDestRegister(inp, REGISTER_X);
  }
  else {
    fnRecall(inp);
  }
}


double convert_to_double(calcRegister_t regist) { //Convert from X register to double
  double y;
  real_t tmpy;
  switch(getRegisterDataType(regist)) {
    case dtLongInteger:
      convertLongIntegerRegisterToReal(regist, &tmpy, &ctxtReal39);
      break;
    case dtReal34:
      real34ToReal(REGISTER_REAL34_DATA(regist), &tmpy);
      break;
    default:
      return 0;
  }
  realToString(&tmpy, tmpString);
  y = strtof(tmpString, NULL);
  return y;
}


void timeToReal34(uint16_t hms) { //always 24 hour time;
  calcRegister_t regist = REGISTER_X;
  real34_t real34, value34, tmp34, h34, m34, s34;
  int32_t sign;
  uint32_t digits, tDigits = 0u, bDigits;
  bool_t isValid12hTime = false; //, isAfternoon = false;

  real34Copy(REGISTER_REAL34_DATA(regist), &real34);
  sign = real34IsNegative(&real34);

  // Pre-rounding
  int32ToReal34(10, &value34);
  int32ToReal34(10, &tmp34);
  for(bDigits = 0; bDigits < (isValid12hTime ? 14 : 16); ++bDigits) {
    if(real34CompareAbsLessThan(&h34, &value34)) {
      break;
    }
    real34Multiply(&value34, &tmp34, &value34);
  }
  tDigits = (isValid12hTime ? 14 : 16);
  isValid12hTime = false;

  for(digits = bDigits; digits < tDigits; ++digits) {
    real34Multiply(&real34, &value34, &real34);
  }
  real34ToIntegralValue(&real34, &real34, DEC_ROUND_HALF_UP);
  for(digits = bDigits; digits < tDigits; ++digits) {
    real34Divide(&real34, &value34, &real34);
  }
  tDigits = 0u;
  real34SetPositiveSign(&real34);

  if(hms == 3) {
    //total seconds
    reallocateRegister(regist, dtReal34, 0, amNone);
    real34Copy(&real34, REGISTER_REAL34_DATA(regist));
    return;
  }

  // Seconds
  //real34ToIntegralValue(&real34, &s34, DEC_ROUND_DOWN);
  real34Copy(&real34, &s34);
  real34Subtract(&real34, &s34, &real34); // Fractional part
  int32ToReal34(60, &value34);
  // Minutes
  real34Divide(&s34, &value34, &m34);
  real34ToIntegralValue(&m34, &m34, DEC_ROUND_DOWN);
  real34DivideRemainder(&s34, &value34, &s34);
  // Hours
  real34Divide(&m34, &value34, &h34);
  real34ToIntegralValue(&h34, &h34, DEC_ROUND_DOWN);
  real34DivideRemainder(&m34, &value34, &m34);

  switch(hms) {
    case 0: //h
      int32ToReal34(sign ? -1 : +1, &value34);
      real34Multiply(&h34, &value34, &h34);
      reallocateRegister(regist, dtReal34, 0, amNone);
      real34Copy(&h34, REGISTER_REAL34_DATA(regist));
      break;

    case 1: //m
      int32ToReal34(sign ? -1 : +1, &value34);
      real34Multiply(&m34, &value34, &m34);
      reallocateRegister(regist, dtReal34, 0, amNone);
      real34Copy(&m34, REGISTER_REAL34_DATA(regist));
      break;

    case 2: //s
      int32ToReal34(sign ? -1 : +1, &value34);
      real34Multiply(&s34, &value34, &s34);
      reallocateRegister(regist, dtReal34, 0, amNone);
      real34Copy(&s34, REGISTER_REAL34_DATA(regist));
      break;

    default: ;
  }
}


void dms34ToReal34(uint16_t dms) {
  real34_t angle34;
  calcRegister_t regist = REGISTER_X;
  real34_t value34, d34, m34, s34, fs34;
  real34Copy(REGISTER_REAL34_DATA(regist), &angle34);

  //    char degStr[27];
  uint32_t m, s, fs;
  int16_t sign;

  real_t temp, degrees, minutes, seconds;

  real34ToReal(&angle34, &temp);

  sign = realIsNegative(&temp) ? -1 : 1;
  realSetPositiveSign(&temp);

  // Get the degrees
  realToIntegralValue(&temp, &degrees, DEC_ROUND_DOWN, &ctxtReal39);

  // Get the minutes
  realSubtract(&temp, &degrees, &temp, &ctxtReal39);
  temp.exponent += 2; // temp = temp * 100
  realToIntegralValue(&temp, &minutes, DEC_ROUND_DOWN, &ctxtReal39);

  // Get the seconds
  realSubtract(&temp, &minutes, &temp, &ctxtReal39);
  temp.exponent += 2; // temp = temp * 100
  realToIntegralValue(&temp, &seconds, DEC_ROUND_DOWN, &ctxtReal39);

  // Get the fractional seconds
  realSubtract(&temp, &seconds, &temp, &ctxtReal39);
  temp.exponent += 2; // temp = temp * 100

  fs = realToUint32C47(&temp);
  s  = realToUint32C47(&seconds);
  m  = realToUint32C47(&minutes);

  if(fs >= 100) {
    fs -= 100;
    s++;
  }

  if(s >= 60) {
    s -= 60;
    m++;
  }

  if(m >= 60)  {
    m -= 60;
    realAdd(&degrees, const_1, &degrees, &ctxtReal39);
  }

  switch(dms)  {
    case 0: //d
      int32ToReal34(sign, &value34);
      realToReal34(&degrees, &d34);
      real34Multiply(&d34, &value34, &d34);
      reallocateRegister(regist, dtReal34, 0, amNone);
      real34Copy(&d34, REGISTER_REAL34_DATA(regist));
      break;

    case 1: //m
      int32ToReal34(m, &m34);
      int32ToReal34(sign, &value34);
      real34Multiply(&m34, &value34, &m34);
      reallocateRegister(regist, dtReal34, 0, amNone);
      real34Copy(&m34, REGISTER_REAL34_DATA(regist));
      break;

    case 2: //s
      int32ToReal34(fs, &fs34);
      int32ToReal34(100, &value34);
      real34Divide(&fs34, &value34, &fs34);

      int32ToReal34(s, &s34);
      real34Add(&s34, &fs34, &s34);

      int32ToReal34(sign, &value34);
      real34Multiply(&s34, &value34, &s34);
      reallocateRegister(regist, dtReal34, 0, amNone);
      real34Copy(&s34, REGISTER_REAL34_DATA(regist));
      break;

    default: ;
  }
}


void notSexa(void) {
  copySourceRegisterToDestRegister(REGISTER_L, REGISTER_X);
  displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    sprintf(errorMessage, "data type %s cannot be converted!", getRegisterDataTypeName(REGISTER_X, false, false));
    moreInfoOnError("In function notSexagecimal:", errorMessage, NULL, NULL);
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
}


void fnHrDeg(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }
  if(getRegisterAngularMode(REGISTER_X) == amDMS && getRegisterDataType(REGISTER_X) == dtReal34) {
    dms34ToReal34(0);
  }
  else if(getRegisterDataType(REGISTER_X) == dtTime) {
    timeToReal34(0);
  }
  else {
    notSexa();
  }
}


void fnMinute(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }
  if(getRegisterAngularMode(REGISTER_X) == amDMS && getRegisterDataType(REGISTER_X) == dtReal34) {
    dms34ToReal34(1);
  }
  else if(getRegisterDataType(REGISTER_X) == dtTime) {
    timeToReal34(1);
  }
  else {
    notSexa();
  }
}


void fnSecond(uint16_t unusedButMandatoryParameter){
  if(!saveLastX()) {
    return;
  }
  if(getRegisterAngularMode(REGISTER_X) == amDMS && getRegisterDataType(REGISTER_X) == dtReal34) {
    dms34ToReal34(2);
  }
  else if(getRegisterDataType(REGISTER_X) == dtTime) {
    timeToReal34(2);
  }
  else {
    notSexa();
  }
}


void fnTimeTo(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  if(getRegisterAngularMode(REGISTER_X) == amDMS && getRegisterDataType(REGISTER_X) == dtReal34) {
    dms34ToReal34(0);
    liftStack();
    copySourceRegisterToDestRegister(REGISTER_L, REGISTER_X);
    dms34ToReal34(1);
    liftStack();
    copySourceRegisterToDestRegister(REGISTER_L, REGISTER_X);
    dms34ToReal34(2);
  }
  else if(getRegisterDataType(REGISTER_X) == dtTime) {
    timeToReal34(0);
    liftStack();
    copySourceRegisterToDestRegister(REGISTER_L, REGISTER_X);
    timeToReal34(1);
    liftStack();
    copySourceRegisterToDestRegister(REGISTER_L, REGISTER_X);
    timeToReal34(2);
  }
  else {
    notSexa();
    return;
  }
}


/********************************************//**
 * \brief Check if time is valid (e.g. 10:61:61 is invalid)
 *
 * \param[in] hour real34_t*
 * \param[in] minute real34_t*
 * \param[in] second real34_t*
 * \return bool_t true if valid
 ***********************************************/
bool_t isValidTime(const real34_t *hour, const real34_t *minute, const real34_t *second) {
  real34_t val;

  // second
  real34ToIntegralValue(second, &val, DEC_ROUND_FLOOR), real34Subtract(second, &val, &val);
  if(!real34IsZero(&val)) {
    return false;
  }

  int32ToReal34(0, &val), real34Compare(second, &val, &val);
  if(real34ToInt32(&val) < 0) {
    return false;
  }

  int32ToReal34(59, &val), real34Compare(second, &val, &val);
  if(real34ToInt32(&val) > 0) {
    return false;
  }

  // minute
  real34ToIntegralValue(minute, &val, DEC_ROUND_FLOOR), real34Subtract(minute, &val, &val);
  if(!real34IsZero(&val)) {
    return false;
  }

  int32ToReal34(0, &val), real34Compare(minute, &val, &val);
  if(real34ToInt32(&val) < 0) {
    return false;
  }

  int32ToReal34(59, &val), real34Compare(minute, &val, &val);
  if(real34ToInt32(&val) > 0) {
    return false;
  }

  // hour
  real34ToIntegralValue(hour, &val, DEC_ROUND_FLOOR), real34Subtract(hour, &val, &val);
  if(!real34IsZero(&val)) {
    return false;
  }

  int32ToReal34(0, &val), real34Compare(hour, &val, &val);
  if(real34ToInt32(&val) < 0) {
    return false;
  }

  int32ToReal34(23, &val), real34Compare(hour, &val, &val);
  if(real34ToInt32(&val) > 0) {
    return false;
  }

  // Valid time
  return true;
}


TO_QSPI const calcRegister_t toTimeParamReg[3] = {REGISTER_Z, REGISTER_Y, REGISTER_X};
void fnToTime(uint16_t unusedButMandatoryParameter) {
  real34_t hr, m, s;
  real34_t *part[3];
  uint_fast8_t i;

  if(!saveLastX()) {
    return;
  }

  part[0] = &hr;
  part[1] = &m;
  part[2] = &s; //hrMs

  for(i=0; i<3; ++i) {
    switch(getRegisterDataType(toTimeParamReg[i])) {
      case dtLongInteger:
        convertLongIntegerRegisterToReal34(toTimeParamReg[i], part[i]);
        break;

      case dtReal34:
        if(getRegisterAngularMode(toTimeParamReg[i])) {
          real34ToIntegralValue(REGISTER_REAL34_DATA(toTimeParamReg[i]), part[i], DEC_ROUND_DOWN);
          break;
        }
        /* fallthrough */

      default:
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        #if (EXTRA_INFO_ON_CALC_ERROR == 1)
          sprintf(errorMessage, "data type %s cannot be converted to a time!", getRegisterDataTypeName(toTimeParamReg[i], false, false));
          moreInfoOnError("In function fnToTime:", errorMessage, NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        return;
    }
  }

  // valid date
  fnDropY(NOPARAM);
  fnDropY(NOPARAM);

  real34Multiply(const34_3600, &hr, &hr); //hr is now seconds
  real34Multiply(const34_60, &m, &m); //m is now seconds
  real34Add(&hr, &m, &hr);
  real34Add(&hr, &s, &hr);

  reallocateRegister(REGISTER_X, dtTime, 0, amNone);
  real34Copy(&hr, REGISTER_REAL34_DATA(REGISTER_X));
}



// ** ITFRAC *****************************************************************************
// ** IRFRAC parameters: input minimum: 1E-16
// **                  : input maximum: 999 999 999 excluding the IR factor
// **                  : DMX maximum setting 32500
// **                  : Output numerator, excluding IR factor: 999 999 999
// **                  : internal max 1E9-1 after IR constant divided
// **                  : Accuracy 24 digits;
// **                  : Internally uses 12 digits in denom seeker for integer conversions
// **                  : Internally uses 26 digits for denom seeker real
// **                  : Internally uses 26 digits for fraction comparison,
// ** ************************************************************************************
// **
// ** 24 digits guaranteed. 24+2 used, as this has proven to need only 24+1
// ** decNumber number of digits needed for IRFRAC
// ** optimised and verified for the input range offered
#define K_ctxtReal_denominator_finder                           26  //Continuous fraction representation
#define K_ctxtReal_integer_conversion_find_lowest_err_fraction  12  //Determine correct fraction to use from continuous fraction expansion matrix
#define K_ctxtReal_irrational_detection                         26  //This is used for multiple of input constant too large, as well as for irrational tolerance, relative.
#define K_ctxtReal_find_multiple_of_irr                         26  //This is used to determine the whole multiple.

int32_t getSmallestDenom(const real_t *val) { // ignore numerator determined, as this needs to be re-calculated in the main algo
  /*
  ** Adapted from:
  ** https://www.ics.uci.edu/~eppstein/numth/frap.c
  **
  ** find rational approximation to given real number
  ** David Eppstein / UC Irvine / 8 Aug 1993
  ** With corrections from Arno Formella, May 2008
  **
  ** based on the theory of continued fractions
  ** if x = a1 + 1/(a2 + 1/(a3 + 1/(a4 + ...)))
  ** then best approximation is found by truncating this series
  ** (with some adjustments in the last term).
  **
  ** Note the fraction can be recovered as the first column of the matrix
  **  ( a1 1 ) ( a2 1 ) ( a3 1 ) ...
  **  ( 1  0 ) ( 1  0 ) ( 1  0 )
  ** Instead of keeping the sequence of continued fraction terms,
  ** we just keep the last partial product of these matrices.
  */

  realContext_t ctxtReal_denom_finder = ctxtReal39;
  ctxtReal_denom_finder.digits = K_ctxtReal_denominator_finder;
  real_t xx, temp;
  realCopy(val, &xx);

  int32_t m[2][2];
  m[0][0] = 1;

  int32_t maxden, ai, dd;
  if(denMax == 0 || denMax > MAX_DENMAX) {
    maxden = MAX_INTERNAL_DENMAX;
  } else {
    maxden = denMax;
  }
  int32ToReal(maxden,&temp);
  realDivide(const_1on4,&temp,&temp,&ctxtReal_denom_finder);
  if(realCompareLessThan(&xx,&temp)) {
    //printf("Lower than 0.25/DMX, quitting before fraction loop.\n");  // Any value lower than 0.5/DMX will be deemed 0. Make the threshold 1/2 of 0.5/DMX
    dd = 1;
    goto nothingTodo;
  }


  /* initialize matrix */
  m[0][0] = m[1][1] = 1;
  m[0][1] = m[1][0] = 0;

  /* loop finding terms until denom gets too big */
  while(m[1][0] *  ( ai = realToInt32C47(&xx) ) + m[1][1] <= maxden) {
    //printf("  ai = %12i  condition:%8i<%6i ",ai, m[1][0] * ai + m[1][1], maxden ); printf("  m00=%8i m11=%8i m01=%8i m10=%8i   ", m[0][0], m[1][1], m[0][1], m[1][0]); printRealToConsole(&xx,"  xx="," + m[1][1] \n");
    int32_t t;
    t = m[0][0] * ai + m[0][1];
    m[0][1] = m[0][0];
    m[0][0] = t;
    t = m[1][0] * ai + m[1][1];
    m[1][1] = m[1][0];
    m[1][0] = t;

    int32ToReal(ai,&temp);
    realSubtract(&xx,&temp,&xx,&ctxtReal_denom_finder);
    //printf("                                               "); printf("  m00=%8i m11=%8i m01=%8i m10=%8i   ", m[0][0], m[1][1], m[0][1], m[1][0]); printRealToConsole(&xx,"  xx="," + m[1][1] \n");
    if(realIsZero(&xx) || realCompareAbsLessThan(&xx, const_1e_24)) {
      break;  // AF: division by zero
    }
    realDivide(const_1,&xx,&xx,&ctxtReal_denom_finder);
    if(realCompareGreaterThan(&xx,const_10p9__1)) {         // let 1/xx ceiling to const_10p9__1
      realCopy(const_10p9__1,&xx);
    }
    if(realIsSpecial(&xx)) {
      #if defined(PC_BUILD)
        errorf("Representation failure. Quitting fraction loop.");
        printRealToConsole(&xx,"xx:","\n");
        fflush(stderr);
      #endif //PC_BUILD
      dd = 1;
      goto nothingTodo;
    }
  }

  //Pick the correct num/denom from the matrix
  realContext_t ctxtReal_integer_conversion_find_lowest_err_fraction = ctxtReal39;
  ctxtReal_integer_conversion_find_lowest_err_fraction.digits = K_ctxtReal_integer_conversion_find_lowest_err_fraction;
  real_t num1, den1, num2, den2;
  real_t frac1, frac2;
  real_t err1, err2;
  // Convert int32_t integers to reals
  int32ToReal(m[0][0], &num1);
  int32ToReal(m[1][0], &den1);
  int32ToReal(m[0][1], &num2);
  int32ToReal(m[1][1], &den2);
  //decNumberFromInt32(&num1, m[0][0]);
  //decNumberFromInt32(&den1, m[1][0]);
  //decNumberFromInt32(&num2, m[0][1]);
  //decNumberFromInt32(&den2, m[1][1]);

  // Compute fractions num/den: frac = num / den
  realDivide(&num1, &den1, &frac1, &ctxtReal_integer_conversion_find_lowest_err_fraction);
  realDivide(&num2, &den2, &frac2, &ctxtReal_integer_conversion_find_lowest_err_fraction);
  // Compute errors: err = |value - fraction|
  realSubtract(val, &frac1, &err1, &ctxtReal_integer_conversion_find_lowest_err_fraction);
  realCopyAbs(&err1, &err1);
  realSubtract(val, &frac2, &err2, &ctxtReal_integer_conversion_find_lowest_err_fraction);
  realCopyAbs(&err2, &err2);
  real_t cmpResult;           // to store comparison result
  // Compare errors: if err2 < err1, update m accordingly
  realCompare(&err2, &err1, &cmpResult, &ctxtReal_integer_conversion_find_lowest_err_fraction);
  // cmpResult will hold -1 if err2 < err1, 0 if equal, 1 if err2 > err1
  // Check if err2 < err1 and swap output if needed
  // printRealToConsole(&err1,"\nerr1: "," "); printf("%d/%d      ",m[0][0],m[1][0]);
  // printRealToConsole(&err2,  "err2: "," "); printf("%d/%d\n",    m[0][1],m[1][1]);
  if (realIsNegative(&cmpResult)) {
      m[0][0] = m[0][1];
      m[1][0] = m[1][1];
  }
  //ignore numerator for the IRFRAC application - that is re-done later, report the denominator
  dd = m[1][0];
  // printf("----> Selected %d\n",dd);
  if(dd == 0) {
    dd = 1;
  }
nothingTodo:
  //printf(">>> %i / %i \n",  m[0][0], dd);
  return dd;
}

//** Helper to help create and format output string
void changeToSup(uint64_t numer, char *str) {  //numerator
  int16_t  endingZero = 0;
  str[0]=0;
  _numerator(numer, str, &endingZero);

}

//** Helper to help create and format output string
void changeToSub(uint64_t denom, char *str) {  //denominator
  int16_t  endingZero = 1;
  str[0]='/';
  str[1]=0;
  _denominator(denom, str, &endingZero);
}

//** Helper to help create and format output string
void changeToWholeString(int32_t intt, char *str, char *str1) {
  str[0]=0;
  longInteger_t lgInt;
  longIntegerInit(lgInt);
  int32ToLongInteger(intt, lgInt);
  longIntegerToDisplayString(lgInt, str, 30, SCREEN_WIDTH, 20, true);
  strcat(str,str1);
  longIntegerFree(lgInt);
}


//** Main IRFRAC search and conversion function
bool_t checkForAndChange(char *displayString, const real_t *valueReal, const real_t *valueRealAbs, const real_t *constant, const real_t *findingIrrationalTolerance, const char *constantStr,  bool_t frontSpace, bool_t complexMixedNumbers) {
    #define DISALLOW_MIXED_NUMBER_CONSTANTS true // Dont allow 1 e + e/3, rather write 1 1/3 e
    #define DISALLOW_MIXED_NUMBER_COMPLEX   false  // Dont allow 1 2/3 and 1e+2e/3, rather use 5/3 and 5e/3
    realContext_t ctxtReal_irrational_detection = ctxtReal39;
    ctxtReal_irrational_detection.digits = K_ctxtReal_irrational_detection;
    realContext_t ctxtReal_find_multiple_of_irr = ctxtReal39;
    ctxtReal_find_multiple_of_irr.digits = K_ctxtReal_find_multiple_of_irr;

    char cStr[16];
    bool_t useMixedNumbers = getSystemFlag(FLAG_PROPFR) && (DISALLOW_MIXED_NUMBER_COMPLEX ? !complexMixedNumbers : true);
    //printf(">>>## useMixedNumbers %u\n",useMixedNumbers);
    real_t smallestDenomR, newConstant, multipleOfNewConstant, multipleOfNewConstant_ip, multipleOfNewConstant_fp, multConstant;

    char denomStr[20], wholePart[30], resultingIntStr[100], tmpstr[50];
    tmpstr[0]=0;
    denomStr[0] = 0;
    wholePart[0] = 0;
    resultingIntStr[0] = 0;
    int32_t multipleOfNewConstantInteger = 0;
    char sign[2];

    if(realIsPositive(valueReal)) {
      strcpy(sign, "+");
    }
    else {
      strcpy(sign, "-");
    }

    //Returning: Real is too small
    if(realCompareLessThan(valueRealAbs, const_1e_16)) {
      return false;
    }
    //Returning: Multiple of constant is too large
    realDivide(valueRealAbs,constant,&multConstant,&ctxtReal_irrational_detection);                                               //TRYOUT 12 instead of 27
    if(realCompareGreaterThan(&multConstant, const_10p9__1)) {   //reduce whole multiple range to 34-24 = 10 digits. Use 10p9__1 = 999 999 999. (was const_2p31__1 = 2 147 483 647)
      return false;
    }


    //See if the multiplier to the constant has a whole denominator

#define IRFRAC_ENGINE
#ifndef IRFRAC_ENGINE
    //* This section uses the standard fraction() to calculate the denominator
    int16_t sign1, lessEqualGreater;
    uint64_t intPart, numer, denom;
    reallocateRegister(TEMP_REGISTER_1, dtReal34, 0, amNone);
    realToReal34(&multConstant,REGISTER_REAL34_DATA(TEMP_REGISTER_1));
    fraction(TEMP_REGISTER_1, &sign1, &intPart, &numer, &denom, &lessEqualGreater);   //does not yet work in all the frac modes.
    //printf("aaaaaaa: %i%llu + %llu / %llu \n",sign1,intPart,numer,denom);
    int32_t smallestDenom = denom;
#endif //FRACT_ENGINE
#ifdef IRFRAC_ENGINE
    //* This section uses the new special demoninator search engine
    int32_t smallestDenom = getSmallestDenom(&multConstant);                                                    //denominator
#endif //IRFRAC_ENGINE


    //Create a new constant comprising the constant divided by the whole denominator
    int32ToReal(smallestDenom, &smallestDenomR);
    realDivide(constant, &smallestDenomR, &newConstant, &ctxtReal39);

    //See if there is a whole multiple of the new constant
    realDivide(valueRealAbs, &newConstant, &multipleOfNewConstant, &ctxtReal_find_multiple_of_irr);
    realToIntegralValue(&multipleOfNewConstant, &multipleOfNewConstant_ip, DEC_ROUND_HALF_UP, &ctxtReal_find_multiple_of_irr);
    realSubtract(&multipleOfNewConstant, &multipleOfNewConstant_ip, &multipleOfNewConstant_fp, &ctxtReal_find_multiple_of_irr);
    multipleOfNewConstantInteger = abs(realToInt32C47(&multipleOfNewConstant_ip));                              //numerator

    //See if the ip is out of range (use the Real check not the integer check to protect agains > 32 bit integer max)
    if(realCompareAbsGreaterThan(&multipleOfNewConstant_ip, const_10p9__1)) {   //reduce whole multiple range to 34-24 = 10 digits. Use 10p9__1 = 999 999 999. (was const_2p31__1 = 2 147 483 647)
      return false;
    }

  real_t findingIrrationalTolerance1;
  realMultiply(findingIrrationalTolerance, &smallestDenomR, &findingIrrationalTolerance1, &ctxtReal_irrational_detection);         // do relative convergence // MUST TRY 12. SEEMS TO WORK ON 12



// DEBUG CODE
//                                printRealToConsole(constant,"\n\nconstant=","\n");
//                                printRealToConsole(valueReal,"valueReal=","\n");
//                                printRealToConsole(&multConstant,"multConstant=","\n");
//                                printf("smallestDenom:%i\n",smallestDenom);
//                                printRealToConsole(&newConstant,"newConstant=","\n");
//                                printRealToConsole(&multipleOfNewConstant,"multipleOfNewConstant=","\n");
//                                printRealToConsole(&multipleOfNewConstant_ip,"multipleOfNewConstant_ip=","\n");
//                                printRealToConsole(&multipleOfNewConstant_fp,"multipleOfNewConstant_fp=","\n");

//                                printf(">>>multipleOfNewConstantInteger:%i>1? SmallestDenom:%i\n", multipleOfNewConstantInteger, smallestDenom);
//                                printf(" Numer=%i Denom:%i\n---\n", multipleOfNewConstantInteger, smallestDenom);
//                                printRealToConsole(&multipleOfNewConstant_fp,"fp:","--\n");
//                                printRealToConsole(findingIrrationalTolerance,"tol:","--\n");
//                                printf("realCompareAbsLessThan(&multipleOfNewConstant_fp,findingIrrationalTolerance):%i\n",realCompareAbsLessThan(&multipleOfNewConstant_fp,findingIrrationalTolerance));
//                                printf(">>> %i ", multipleOfNewConstantInteger);
//                                printf("QQ:%s§\n",displayString);
//                                char teststr[1000];
//                                char teststr1[1000];
//                                sprintf(teststr,">>>@@@1 |%s|%s|%s| %i %i\n", resultingIntStr, constantStr, denomStr, (int16_t)stringByteLength(resultingIntStr)-1, resultingIntStr[stringByteLength(resultingIntStr)-1]);
//                                stringToASCII(teststr,teststr1);
//                                printf("%s\n",teststr1);
//                                printf(">>>multipleOfNewConstantInteger:%i>=1? realCompareAbsLessThan(&multipleOfNewConstant_fp,findingIrrationalTolerance):%i\n", multipleOfNewConstantInteger, realCompareAbsLessThan(&multipleOfNewConstant_fp,findingIrrationalTolerance));


    if((DISALLOW_MIXED_NUMBER_CONSTANTS && constantStr[0]!=0 && multipleOfNewConstantInteger > smallestDenom) && useMixedNumbers && smallestDenom != 1) {   //remove this last "&& useMixedNumbers" to change to "3/4 e" instead of "3e/4"
      cStr[0] = 0;
    }
    else {
      strcpy(cStr,constantStr);
    }


// DEBUG CODE
//                                printRealToConsole(valueReal,"\n\nInputvalue: valueReal=","\n");
//                                printRealToConsole(constant,"    constant=","\n");
//                                printf("    §%s§   §%s§   §%s§\n", resultingIntStr, constantStr, denomStr);
//                                printRealToConsole(&findingIrrationalTolerance1,"findingIrrationalTolerance1=","\n");
//                                char displayString2[200];
//                                stringToASCII(constantStr,displayString2);
//                                printf("constantStr:%s\n",displayString2);
//                                printf("Numerator: multipleOfNewConstantInteger   %i\n",multipleOfNewConstantInteger);
//                                printf("Denominator: smallestDenom                         /            %i\n",smallestDenom);
//                                printRealToConsole(&multipleOfNewConstant_fp,"&multipleOfNewConstant_fp=","\n");
//                                char displayString1[200];
//                                stringToASCII(resultingIntStr,displayString1); printf("BBB1 ---> %s %u %u %u %u %u %u %u %u\n",displayString1,(uint8_t)(displayString[0]),(uint8_t)(displayString[1]),(uint8_t)(displayString[2]),(uint8_t)(displayString[3]),(uint8_t)(displayString[4]),(uint8_t)(displayString[5]),(uint8_t)(displayString[6]),(uint8_t)(displayString[7]));

    if(multipleOfNewConstantInteger >= 1 && realCompareAbsLessThan(&multipleOfNewConstant_fp,&findingIrrationalTolerance1)) {

// DEBUG CODE
//                                printf("A whole multiple %i of the 'new' constant exists\n", multipleOfNewConstantInteger);
//                                printf("  useMixedNumbers = %u\n", useMixedNumbers);

      if(multipleOfNewConstantInteger > smallestDenom  &&  smallestDenom > 1  && multipleOfNewConstantInteger != 0 && useMixedNumbers && smallestDenom != 1) {   // Numer > Denom;
        int32_t wholeInteger = multipleOfNewConstantInteger / smallestDenom;
        multipleOfNewConstantInteger = multipleOfNewConstantInteger - (wholeInteger * smallestDenom);

// DEBUG CODE
//                                printf("B  wholeInteger %i, multipleOfNewConstantInteger %i of the 'new' constant exists\n", wholeInteger, multipleOfNewConstantInteger);
        char useMixedNumbersSep[3];
        if(cStr[0]==0) {                                                                                          // no constant
          useMixedNumbersSep[0] = STD_SPACE_4_PER_EM[0];
          useMixedNumbersSep[1] = STD_SPACE_4_PER_EM[1];
          useMixedNumbersSep[2] = 0;
          changeToWholeString(wholeInteger,wholePart,useMixedNumbersSep);
          strcat(wholePart,useMixedNumbersSep);                                                                   // "1 "
        }
        else {                                                                                                    // constant with numbers
          useMixedNumbersSep[0] = sign[0];
          useMixedNumbersSep[1] = sign[1];
          useMixedNumbersSep[2] = 0;
          if(wholeInteger == 1) {
            sprintf(wholePart, "%s%s", cStr, useMixedNumbersSep);                                                 // "e+"
          }
          else {
            changeToWholeString(wholeInteger,wholePart,PRODUCT_SIGN);
            strcat(wholePart,cStr);
            strcat(wholePart,useMixedNumbersSep);                                                                 // "2xe+"
          }
        }
      }

      if(cStr[0] == 0) {                                                                                          // no constant
        if(smallestDenom > 1) {
          changeToSup(multipleOfNewConstantInteger, tmpstr);                                                      // numerator
        }
        else {
          return false;
          //return false, to abort and use standard decimal instead of "1."
          //sprintf(tmpstr,"%i",(int)multipleOfNewConstantInteger);                                                 //==1
          //strcat(tmpstr,RADIX34_MARK_STRING);
        }
        sprintf(resultingIntStr, "%s%s", wholePart, tmpstr);                                                        // "1 1"
      }
      else {                                                                                                      // constant
        if(multipleOfNewConstantInteger == 1) {
          sprintf(resultingIntStr,"%s", wholePart);                                                                 // "e+" or "2xe+"
        }
        else {
          sprintf(tmpstr,"%i%s",(int)multipleOfNewConstantInteger,PRODUCT_SIGN);
          sprintf(resultingIntStr, "%s%s", wholePart, tmpstr);                                                      // "e+1" or "2xe+1"
        }
      }
    } else {                                                                                  // A whole multiple %i of the 'new' constant does not exist
        if(smallestDenom == 1) {
          return false;   //unlikely
          //return false, to abort and use standard decimal instead of "1."
          //sprintf(resultingIntStr,"%i", (int)multipleOfNewConstantInteger);                                       // if denom = 1, then use large font
        }
        else {
          changeToSup(multipleOfNewConstantInteger, resultingIntStr);                                             // if denom <> 0, then use superscript, knowing there is a denom
        }

    }

// DEBUG CODE
//                                printf("QQ1 %s\n",wholePart);       printf("BBB1 ---> %u %u %u %u %u %u %u %u\n",(uint8_t)(wholePart[0]),(uint8_t)(wholePart[1]),(uint8_t)(wholePart[2]),(uint8_t)(wholePart[3]),(uint8_t)(wholePart[4]),(uint8_t)(wholePart[5]),(uint8_t)(wholePart[6]),(uint8_t)(wholePart[7]));
//                                printf("  2 %s\n",tmpstr);          printf("BBB2 ---> %u %u %u %u %u %u %u %u\n",(uint8_t)(tmpstr[0]),(uint8_t)(tmpstr[1]),(uint8_t)(tmpstr[2]),(uint8_t)(tmpstr[3]),(uint8_t)(tmpstr[4]),(uint8_t)(tmpstr[5]),(uint8_t)(tmpstr[6]),(uint8_t)(tmpstr[7]));
//                                printf("  3 %s\n",resultingIntStr); printf("BBB3 ---> %u %u %u %u %u %u %u %u\n",(uint8_t)(resultingIntStr[0]),(uint8_t)(resultingIntStr[1]),(uint8_t)(resultingIntStr[2]),(uint8_t)(resultingIntStr[3]),(uint8_t)(resultingIntStr[4]),(uint8_t)(resultingIntStr[5]),(uint8_t)(resultingIntStr[6]),(uint8_t)(resultingIntStr[7]));
//                                char teststr[1000];
//                                sprintf(teststr,">>>@@@2 |%s|%s|%s| %i %i\n", resultingIntStr, constantStr, denomStr, (int16_t)stringByteLength(resultingIntStr)-1, resultingIntStr[stringByteLength(resultingIntStr)-1]);
//                                char teststr2[1000];
//                                stringToASCII(teststr,teststr2);
//                                printf("%s\n",teststr2);

    if(smallestDenom > 1) {
      changeToSub(smallestDenom, denomStr);                                                                     // "/12"
    }

    if((resultingIntStr[stringByteLength(resultingIntStr)-1]==' ' || resultingIntStr[max(0,stringByteLength(resultingIntStr)-1)]==0) &&  denomStr[0]=='/' && cStr[0]==0) {
      sprintf(tmpstr, STD_SUP_1 "%s", denomStr);
      strcpy(denomStr, tmpstr);
    }

  real_t roundingTolerance1;
  irfractionTolerence(smallestDenom * 6 + 1, &roundingTolerance1);                                              // relative convergence, add (6x+1) i.e about 0.43 digits + 1 for safety margin)

// DEBUG CODE
//                               printRealToConsole(&multipleOfNewConstant_fp,"&multipleOfNewConstant_fp=","\n");
//                               printRealToConsole(&roundingTolerance1,"roundingTolerance1=","\n");
//                               printRealToConsole(&findingIrrationalTolerance1,"findingIrrationalTolerance1=","\n");

    displayString[0] = 0;
    if(!realCompareAbsGreaterThan(&multipleOfNewConstant_fp,&findingIrrationalTolerance1)) {                                     // irrational tolerance found, show irrational and fraction
      if(!realCompareAbsLessThan(&multipleOfNewConstant_fp,&roundingTolerance1) ){                                               // prepend the tags; FDIGS=34 is normal, i.e. no lying, meaning opening up the tolerance band for zero
        strcat(displayString, STD_ALMOST_EQUAL);
      }

      if(sign[0]=='+') {
        if(frontSpace) {
          strcat(displayString, STD_SPACE_4_PER_EM);  //changed, not allowing for a space equal length to "-"
          if(resultingIntStr[0] !=0 ) {
            strcat(displayString, resultingIntStr);
          }
          strcat(displayString,cStr);
          strcat(displayString,denomStr);                              // " 2xe+" "e" "/3"
        }
        else {
          if(resultingIntStr[0] != 0) {
            strcat(displayString, resultingIntStr);
          }
          strcat(displayString,cStr);
          strcat(displayString,denomStr);                              // "2xe+" "e" "/3"
        }
      }
      else { // "-"
        strcat(displayString, STD_SPACE_4_PER_EM "-");
        if(resultingIntStr[0] !=0 ) {
          strcat(displayString, resultingIntStr);
        }
        strcat(displayString,cStr);
        strcat(displayString,denomStr);                                // "-2xe+" "e" "/3"
      }

      if(cStr[0] == 0 && constantStr[0] !=0) {                         // "-2/3" "e"
        strcat(displayString,STD_SPACE_4_PER_EM);
        strcat(displayString,PRODUCT_SIGN);
        strcat(displayString,STD_SPACE_4_PER_EM);
        strcat(displayString,constantStr);
      }

      return true;             //successful IRFRAC conversion, displaying as fraction
    }
    else {
      return false;            //unsuccessful IRFRAC conversion, displaying as decimal
    }
  }


void fnSafeReset (uint16_t unusedButMandatoryParameter) {
  if(!jm_G_DOUBLETAP && !ShiftTimoutMode && !HOME3 && !MYM3) {
    fgLN            = RBX_FGLNFUL;  //not in conditional clear
    jm_G_DOUBLETAP  = true;
    ShiftTimoutMode = true;
    HOME3           = true;
    MYM3            = false;
    BASE_HOME       = false;
    BASE_MYM        = true;
  }
  else {
    fgLN            = RBX_FGLNOFF;  //not in conditional clear
    jm_G_DOUBLETAP  = false;
    ShiftTimoutMode = false;
    HOME3           = false;
    MYM3            = false;
    BASE_HOME       = false;
    BASE_MYM        = true;
  }
}


#if !defined(TESTSUITE_BUILD)
  static void assignToMyMenu_(uint16_t position) {
    if(position < 18) {
      _assignItem(&userMenuItems[position]);
    }
    cachedDynamicMenu = 0;
  }


  static void assignToMyAlpha_(uint16_t position) {
    if(position < 18) {
      _assignItem(&userAlphaItems[position]);
    }
    cachedDynamicMenu = 0;
  }
#endif // !TESTSUITE_BUILD


void fnRESET_MyM(uint16_t param) {
  //Pre-assign the MyMenu                   //JM
  #if !defined(TESTSUITE_BUILD)
    BASE_MYM = false;                                                   //JM prevent slow updating of 6 menu items
    for(int8_t fn = 1; fn <= 6; fn++) {
      if(param == ITM_RIBBON_SAV) {
        switch(fn) {
          case 1: itemToBeAssigned = ITM_SYSTEM2; break;
          case 2: itemToBeAssigned = ITM_ACTUSB;  break;
          case 3: itemToBeAssigned = ITM_SAVE;    break;
          case 4: itemToBeAssigned = ITM_LOAD;    break;
          case 5: itemToBeAssigned = ITM_SAVEST;  break;
          case 6: itemToBeAssigned = ITM_LOADST;  break;
          default:break;
        }
      }
      else if(param == ITM_RIBBON_FIN) {
        switch(fn) {
          case 1: itemToBeAssigned = ITM_PC;      break;
          case 2: itemToBeAssigned = ITM_DELTAPC; break;
          case 3: itemToBeAssigned = ITM_YX;      break;
          case 4: itemToBeAssigned = ITM_SQUARE;  break;
          case 5: itemToBeAssigned = ITM_10x;     break;
          case 6: itemToBeAssigned = -MNU_FIN;    break;
          default:break;
        }
      }
      else if(param == ITM_RIBBON_CPX) {
        switch(fn) {
          case 1: itemToBeAssigned = ITM_DRG;      break;
          case 2: itemToBeAssigned = ITM_CC;       break;
          case 3: itemToBeAssigned = ITM_EE_EXP_TH;break;
          case 4: itemToBeAssigned = ITM_EXP;      break;
          case 5: itemToBeAssigned = ITM_op_j_pol; break;
          case 6: itemToBeAssigned = ITM_op_j;     break;
          default:break;
        }
      }

      //C47 et al
          else if(!isR47FAM && param == ITM_RIBBON_ENG) {
            switch(fn) {
              case 1: itemToBeAssigned = -MNU_CPX;     break;
              case 2: itemToBeAssigned = -MNU_MATX;    break;
              case 3: itemToBeAssigned = ITM_CONSTpi;  break;
              case 4: itemToBeAssigned = ITM_op_j;     break;
              case 5: itemToBeAssigned = ITM_EXP;      break;
              case 6: itemToBeAssigned = -MNU_TRG_C47; break;
              default:break;
            }
          }
      //R47
          else if(isR47FAM && param == ITM_RIBBON_ENG) {
            switch(fn) {
              case 1: itemToBeAssigned = ITM_op_j;     break;
              case 2: itemToBeAssigned = -MNU_CPX;     break;
              case 3: itemToBeAssigned = ITM_CONSTpi;  break;
              case 4: itemToBeAssigned = -MNU_MATX;    break;
              case 5: itemToBeAssigned = -MNU_TRG_R47; break;
              case 6: itemToBeAssigned = ITM_EXP;      break;
              default:break;
            }
          }
      //END CONDITIONAL

      else if(param == ITM_RIBBON_C47) {
        switch(fn) {
          case 1: itemToBeAssigned = ITM_DRG;      break;
          case 2: itemToBeAssigned = ITM_YX;       break;
          case 3: itemToBeAssigned = ITM_SQUARE;   break;
          case 4: itemToBeAssigned = ITM_10x;      break;
          case 5: itemToBeAssigned = ITM_EXP;      break;
          case 6: itemToBeAssigned = ITM_op_j;     break;
          default:break;
        }
      }
      else if(param == ITM_RIBBON_C47PL) {
        switch(fn) {
          case 1: itemToBeAssigned = ITM_DRG;      break;
          case 2: itemToBeAssigned = ITM_DSP;      break;
          case 3: itemToBeAssigned = ITM_DREAL;    break;
          case 4: itemToBeAssigned = ITM_FF;       break;
          case 5: itemToBeAssigned = ITM_Rup;      break;
          case 6: itemToBeAssigned = ITM_XFACT;    break;
          default:break;
        }
      }
      else if(param == ITM_RIBBON_R47) {
        switch(fn) {
          case 1: itemToBeAssigned = ITM_op_j;     break;
          case 2: itemToBeAssigned = ITM_op_j_pol; break;
          case 3: itemToBeAssigned = ITM_XFACT;    break;
          case 4: itemToBeAssigned = ITM_XTHROOT;  break;
          case 5: itemToBeAssigned = ITM_10x;      break;
          case 6: itemToBeAssigned = ITM_EXP;      break;
          default:break;
        }
      }
      else if(param == ITM_RIBBON_R47PL) {
        switch(fn) {
          case 1: itemToBeAssigned = ITM_TIMER;    break;
          case 2: itemToBeAssigned = ITM_DSP;      break;
          case 3: itemToBeAssigned = ITM_DREAL;    break;
          case 4: itemToBeAssigned = ITM_FF;       break;
          case 5: itemToBeAssigned = -MNU_LOOP;    break;
          case 6: itemToBeAssigned = -MNU_TEST;    break;
          default:break;
        }
      }
      else {
        itemToBeAssigned = ASSIGN_CLEAR;
      }

      if(itemToBeAssigned == -MNU_PFN) {
        strcpy(aimBuffer,"P.FN");
        assignGetName1();
      }
      else if(itemToBeAssigned == -MNU_HOME) {
        strcpy(aimBuffer,"HOME");
        assignGetName1();
      }

      assignToMyMenu_(fn - 1);
      if(param == 0) {
        itemToBeAssigned = ASSIGN_CLEAR;
        assignToMyMenu_(6 + fn - 1);
        itemToBeAssigned = ASSIGN_CLEAR;
        assignToMyMenu_(12 + fn - 1);
      }
    }
    BASE_MYM = true;                                           //JM Menu system default (removed from reset_jm_defaults)
    refreshScreen(42);
  #endif // !TESTSUITE_BUILD
}


void fnRESET_Mya(void){
  //Pre-assign the MyAlpha Menu                   //JM
  #if !defined(TESTSUITE_BUILD)
    for(int8_t fn = 1; fn <= 6; fn++) {
      itemToBeAssigned = ASSIGN_CLEAR;
      assignToMyAlpha_(fn - 1);
      itemToBeAssigned = ASSIGN_CLEAR;
      assignToMyAlpha_(6 + fn - 1);
      itemToBeAssigned = ASSIGN_CLEAR;
      assignToMyAlpha_(12 + fn - 1);
    }
//    itemToBeAssigned = -MNU_ALPHA;
//    assignToMyAlpha_(5);
    refreshScreen(43);
  #endif // !TESTSUITE_BUILD
}


//Softmenus:
//--------------------------------------------------------------------------------------------
//JM To determine the menu number for a given menuId          //JMvv
int16_t mm(int16_t id) {
  int16_t m;
  m = 0;
  if(id != 0) { // Search by ID
    while(softmenu[m].menuItem != 0) {
      //printf(">>> mm %d %d %d %s \n",id, m, softmenu[m].menuItem, indexOfItems[-softmenu[m].menuItem].itemSoftmenuName);
      if(softmenu[m].menuItem == id) {
        //printf("####>> mm() broken out id=%i m=%i\n",id,m);
        break;
      }
      m++;
    }
  }
  return m;
}                                                             //JM^^

#if !defined(TESTSUITE_BUILD)
  //vv EXTRA DRAWINGS FOR RADIO_BUTTON AND CHECK_BOX
  #define JM_LINE2_DRAW
  #undef JM_LINE2_DRAW
  #if defined(JM_LINE2_DRAW)
    void JM_LINE2(uint32_t xx, uint32_t yy) {                          // To draw the lines for radiobutton on screen
      uint32_t x, y;
      y = yy-3-1;
      for(x=xx-66+1; x<min(xx-1,SCREEN_WIDTH); x++) {
        if(mod(x, 2) == 0) {
          setBlackPixel(x, y);
          setBlackPixel(x, y+2);
        }
        else {
          setBlackPixel(x, y+1);
        }
      }
    }
  #endif // JM_LINE2_DRAW


  #define RB_EXTRA_BORDER
  //#undef RB_EXTRA_BORDER
  #define RB_CLEAR_CENTER
  #undef RB_CLEAR_CENTER
  #if defined(RB_EXTRA_BORDER)
    void rbColumnCcccccc(uint32_t xx, uint32_t yy) {
      lcd_fill_rect(xx,yy+2,1,7,  0);
    }
  #endif // RB_EXTRA_BORDER


  void rbColumnCcSssssCc(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      lcd_fill_rect(xx, yy+8, 1, 2,  0);
    #endif // RB_EXTRA_BORDER

    lcd_fill_rect(xx, yy+3, 1, 5,  0xFF);

    #if defined(RB_EXTRA_BORDER)
      lcd_fill_rect(xx, yy+1, 1, 1,  0);
    #endif // RB_EXTRA_BORDER
  }


  void rbColumnCcSssssssCc(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      lcd_fill_rect(xx, yy+9, 1, 2,  0);
    #endif // RB_EXTRA_BORDER

    lcd_fill_rect(xx, yy+2, 1, 7,  0xFF);

    #if defined(RB_EXTRA_BORDER)
      lcd_fill_rect(xx, yy, 1, 2,  0);
    #endif // RB_EXTRA_BORDER
  }


  void rbColumnCSssCccSssC(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      setWhitePixel (xx, yy+10);
    #endif // RB_EXTRA_BORDER

    lcd_fill_rect(xx, yy+7, 1, 3,  0xFF);
    lcd_fill_rect(xx, yy+4, 1, 3,  0);
    lcd_fill_rect(xx, yy+1, 1, 3,  0xFF);

    #if defined(RB_EXTRA_BORDER)
      setWhitePixel (xx, yy+0);
    #endif // RB_EXTRA_BORDER
  }


  void rbColumnCSsCSssCSsC(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      setWhitePixel(xx, yy+10);
    #endif // RB_EXTRA_BORDER

    lcd_fill_rect(xx, yy+8, 1, 2,  0xFF);
    setWhitePixel(xx, yy+7);
    lcd_fill_rect(xx, yy+4, 1, 3,  0xFF);
    setWhitePixel(xx, yy+3);
    lcd_fill_rect(xx, yy+1, 1, 2,  0xFF);

    #if defined(RB_EXTRA_BORDER)
      setWhitePixel(xx, yy+0);
    #endif // RB_EXTRA_BORDER
  }


  void rbColumnCcSsNnnSsCc(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      lcd_fill_rect(xx, yy+9, 1, 2,  0);
    #endif // RB_EXTRA_BORDER

    lcd_fill_rect(xx, yy+7, 1, 2,  0xFF);

    #if defined(RB_CLEAR_CENTER)
      lcd_fill_rect(xx, yy+4, 1, 3,  0);
    #endif // RB_CLEAR_CENTER

    lcd_fill_rect(xx, yy+2, 1, 2,  0xFF);

    #if defined(RB_EXTRA_BORDER)
      lcd_fill_rect(xx, yy+0, 1, 2,  0);
    #endif // RB_EXTRA_BORDER
  }


  void rbColumnCSsNnnnnSsC(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      setWhitePixel (xx, yy+10);
    #endif //RB_EXTRA_BORDER

    lcd_fill_rect(xx, yy+8,1,2,  0xFF);

    #if defined(RB_CLEAR_CENTER)
      lcd_fill_rect(xx, yy+3,1,5,  0);
    #endif //RB_CLEAR_CENTER

    lcd_fill_rect(xx, yy+1,1,2,  0xFF);

    #if defined(RB_EXTRA_BORDER)
      setWhitePixel(xx, yy+0);
    #endif //RB_EXTRA_BORDERf
  }


  void rbColumnCSNnnnnnnSC(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      setWhitePixel(xx, yy+10);
    #endif //RB_EXTRA_BORDER

    setBlackPixel(xx, yy+9);

    #if defined(RB_CLEAR_CENTER)
      lcd_fill_rect(xx, yy+2, 1, 7,  0);
    #endif //RB_CLEAR_CENTER

    setBlackPixel (xx, yy+1);

    #if defined(RB_EXTRA_BORDER)
      setWhitePixel(xx, yy+0);
    #endif //RB_EXTRA_BORDER
  }


  #if defined(RB_EXTRA_BORDER)
    void cbColumnCcccccccccc(uint32_t xx, uint32_t yy) {
      lcd_fill_rect(xx, yy+0, 1, 11,  0);
    }
  #endif // RB_EXTRA_BORDER


  void cbColumnCSssssssssC(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      setWhitePixel(xx, yy+10);
    #endif //RB_EXTRA_BORDER

    lcd_fill_rect(xx, yy+1, 1, 9,  0xFF);

    #if defined(RB_EXTRA_BORDER)
      setWhitePixel(xx,yy+0);
    #endif //RB_EXTRA_BORDER
  }


  void cbColumnCSsCccccSsC(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      setWhitePixel(xx, yy+10);
    #endif // RB_EXTRA_BORDER

    lcd_fill_rect(xx, yy+8, 1, 2,  0xFF);
    lcd_fill_rect(xx, yy+3, 1, 5,  0);
    lcd_fill_rect(xx, yy+1, 1, 2,  0xFF);

    #if defined(RB_EXTRA_BORDER)
      setWhitePixel(xx, yy+0);
    #endif // RB_EXTRA_BORDER
  }


  void cbColumnCSNnnnnnnSC(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      setWhitePixel(xx,yy+10);
    #endif // RB_EXTRA_BORDER

    setBlackPixel(xx, yy+9);

    #if defined(RB_CLEAR_CENTER)
      lcd_fill_rect(xx, yy+2, 1, 7,  0);
    #endif // RB_CLEAR_CENTER

    setBlackPixel(xx, yy+1);

    #if defined(RB_EXTRA_BORDER)
      setWhitePixel(xx, yy+0);
    #endif // RB_EXTRA_BORDER
  }


  void RB_CHECKED(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      rbColumnCcccccc(xx+0, yy);
    #endif // RB_EXTRA_BORDER
    rbColumnCcSssssCc(xx+1, yy);
    rbColumnCcSssssssCc(xx+2, yy);
    rbColumnCSssCccSssC(xx+3, yy);
    rbColumnCSsCSssCSsC(xx+4, yy);
    rbColumnCSsCSssCSsC(xx+5, yy);
    rbColumnCSsCSssCSsC(xx+6, yy);
    rbColumnCSssCccSssC(xx+7, yy);
    rbColumnCcSssssssCc(xx+8, yy);
    rbColumnCcSssssCc(xx+9, yy);
    //#if defined(RB_EXTRA_BORDER)
    //  rbColumnCcccccc(xx+10, yy);
    //#endif // RB_EXTRA_BORDER
  }


  void RB_UNCHECKED(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      rbColumnCcccccc(xx+0, yy);
    #endif // RB_EXTRA_BORDER
    rbColumnCcSssssCc(xx+1, yy);
    rbColumnCcSsNnnSsCc(xx+2, yy);
    rbColumnCSsNnnnnSsC(xx+3, yy);
    rbColumnCSNnnnnnnSC(xx+4, yy);
    rbColumnCSNnnnnnnSC(xx+5, yy);
    rbColumnCSNnnnnnnSC(xx+6, yy);
    rbColumnCSsNnnnnSsC(xx+7, yy);
    rbColumnCcSsNnnSsCc(xx+8, yy);
    rbColumnCcSssssCc(xx+9, yy);
    //#if defined(RB_EXTRA_BORDER)
    //  rbColumnCcccccc(xx+10, yy);
    //#endif // RB_EXTRA_BORDER
  }


  void CB_CHECKED(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      lcd_fill_rect(xx, yy-1, 10, 11, 0);
      cbColumnCcccccccccc(xx+0, yy);
    #endif // RB_EXTRA_BORDER
    cbColumnCSssssssssC(xx+1, yy);
    cbColumnCSssssssssC(xx+2, yy);
    cbColumnCSsCccccSsC(xx+3, yy);
    rbColumnCSsCSssCSsC(xx+4, yy);
    rbColumnCSsCSssCSsC(xx+5, yy);
    rbColumnCSsCSssCSsC(xx+6, yy);
    cbColumnCSsCccccSsC(xx+7, yy);
    cbColumnCSssssssssC(xx+8, yy);
    cbColumnCSssssssssC(xx+9, yy);
    //#if defined(RB_EXTRA_BORDER)
    //  cbColumnCcccccccccc(xx+10, yy);
    //#endif // RB_EXTRA_BORDER
  }


  void CB_UNCHECKED(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      lcd_fill_rect(xx, yy-1, 10, 11, 0);
      cbColumnCcccccccccc(xx+0, yy);
    #endif // RB_EXTRA_BORDER
    cbColumnCSssssssssC(xx+1, yy);
    cbColumnCSNnnnnnnSC(xx+2, yy);
    cbColumnCSNnnnnnnSC(xx+3, yy);
    cbColumnCSNnnnnnnSC(xx+4, yy);
    cbColumnCSNnnnnnnSC(xx+5, yy);
    cbColumnCSNnnnnnnSC(xx+6, yy);
    cbColumnCSNnnnnnnSC(xx+7, yy);
    cbColumnCSNnnnnnnSC(xx+8, yy);
    cbColumnCSssssssssC(xx+9, yy);
    //#if defined(RB_EXTRA_BORDER)
    //  cbColumnCcccccccccc(xx+10, yy);
    //#endif // RB_EXTRA_BORDER
  }
  //^^
#endif // !TESTSUITE_BUILD


void fnSetBCD (uint16_t bcd) {
  switch(bcd) {
    case BCD9c:
    case BCD10c:
    case BCDu:
      bcdDisplaySign = bcd;
      break;
    default: ;
  }
}


void setFGLSettings(uint16_t option) {
  switch(option) {
    case RBX_FGLNOFF:
    case RBX_FGLNLIM:
    case RBX_FGLNFUL:
      fgLN = (uint8_t)option;
      break;
    default:
      fgLN = RBX_FGLNFUL;
  }
}


void fnLongPressSwitches (uint16_t option) {
  switch(option) {
    case RBX_F14:
    case RBX_F124:
    case RBX_F1234:
      LongPressF = option;
      break;
    case RBX_M14   :
    case RBX_M124  :
    case RBX_M1234 :
      LongPressM = option;
      break;
    default:
      LongPressM = RBX_M1234;
      LongPressF = RBX_F124;
  }
}


