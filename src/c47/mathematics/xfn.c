// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

#include "c47.h"


// Replacement Taylor sin/cos/tan function for high accuracy
// Capable of 1071 digit input and a final accuracy parameter, being the number of required digits.
// Only the mod reduction needs double the digits. The Taylor function uses 1071 only, and the internal angle manipulation (and reduction) is on 1071.
// The major bignumber reduction must be done outside Taylor

#undef DEBUG_XFN

#if !defined(PC_BUILD)
  #undef DEBUG_XFN
#endif


#if defined(SAVE_SPACE_DM42_18_XFN)
  void fnXfnIndirect(uint16_t registerNo, uint16_t function) {
  }
  void fnXXfn(uint16_t function) {
  }
  bool_t registerFMAOutputString(calcRegister_t regist, char* prefix, char *displayString) {
  return 0;
  }
  void fnXXfn_ToDEG               (uint16_t registerNo) {
  }
  void fnXXfn_ToRAD               (uint16_t registerNo) {
  }
  void fnXXfn_sin                 (uint16_t registerNo) {
  }
  void fnXXfn_cos                 (uint16_t registerNo) {
  }
  void fnXXfn_tan                 (uint16_t registerNo) {
  }
  void fnXXfn_pi                  (uint16_t registerNo) {
  }
  void fnXXfn_swap                (uint16_t registerNo) {
  }
  void fnXXfn_drop                (uint16_t registerNo) {
  }
  void fnXXfn_atan2               (uint16_t registerNo) {
  }
  void fnXXfn_arcsin              (uint16_t registerNo) {
  }
  void fnXXfn_arccos              (uint16_t registerNo) {
  }
  void fnXXfn_arctan              (uint16_t registerNo) {
  }
  void fnXXfn_LN                  (uint16_t registerNo) {
  }
  void fnXXfn_LOG                 (uint16_t registerNo) {
  }
  void fnXXfn_EXP                 (uint16_t registerNo) {
  }
  void fnXXfn_10X                 (uint16_t registerNo) {
  }
  void fnXXfn_POWER               (uint16_t registerNo) {
  }
  void fnXXfn_SQRT                (uint16_t registerNo) {
  }
  void fnXXfn_1ONX                (uint16_t registerNo) {
  }
  void fnXXfn_ADD                 (uint16_t registerNo) {
  }
  void fnXXfn_SUB                 (uint16_t registerNo) {
  }
  void fnXXfn_MULT                (uint16_t registerNo) {
  }
  void fnXXfn_DIV                 (uint16_t registerNo) {
  }
  void fnXXfn_MOD                 (uint16_t registerNo) {
  }
  void fnXXfn_MODANG              (uint16_t registerNo) {
  }
  void fnXXfn_TO                  (uint16_t registerNo) {
  }
#endif //SAVE_SPACE_DM42_18_XFN



#if !defined(SAVE_SPACE_DM42_18_XFN)
  #define debugLongNumberLimit       100
  #define modulus(a)                 (a == amRadian ? const2139_2pi : a == amDegree ? const_360 : a == amGrad ? const_400 : a == amMultPi ? const_2 : const_1)

  static void C47Cvt2RadSinCosTan1071(real1071_t *an, angularMode_t angularMode, real1071_t *sinOut, real1071_t *cosOut, real1071_t *tanOut, realContext_t *realContext) {
    explicitTaylorIterVisibilitySelection = true;
    C47_WP34S_Cvt2RadSinCosTan((real_t*)an, angularMode, (real_t*)sinOut, (real_t*)cosOut, (real_t*)tanOut, realContext);
  }
  static void C47_WP34S_Asin1071(real1071_t *x, real1071_t *angle, realContext_t *realContext) {
    explicitTaylorIterVisibilitySelection = true;
    C47_WP34S_Asin((real_t*)x, (real_t*)angle, realContext);
  }
  static void C47_WP34S_Acos1071(real1071_t *x, real1071_t *angle, realContext_t *realContext) {
    explicitTaylorIterVisibilitySelection = true;
    C47_WP34S_Acos((real_t*)x, (real_t*)angle, realContext);
  }
  static void C47_WP34S_Atan1071(real1071_t *x, real1071_t *angle, realContext_t *realContext) {
    explicitTaylorIterVisibilitySelection = true;
    C47_WP34S_Atan((real_t*)x, (real_t*)angle, realContext);
  }
  static void C47_WP34S_Atan2_1071(real1071_t *y, real1071_t *x, real1071_t *atan, realContext_t *realContext) {
    explicitTaylorIterVisibilitySelection = true;
    C47_WP34S_Atan2((real_t*)y, (real_t*)x, (real_t*)atan, realContext);
  }



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

  #define maxAllowedDigits  (use1071 ? 1000 : 68)
  #define maxContextDigits  (use1071 ? 1071 : 75)



int32_t realGetDigits(const real1071_t* x) {
    return ((decNumber*)x)->digits;
}

void decomposeReal(const real1071_t* x, longInteger_t integerPart, real1071_t* fractionalPart, realContext_t* c) {
    // integer part has at most maxAllowedDigits (1000) digits
    #if defined(DEBUG_XFN)
      realToString((real_t *)x, tmpString); tmpString[debugLongNumberLimit]=0; printf("decomposeReal 000: input: %s\n", tmpString);
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
      printf("decomposeReal: longintegerstring 002: %s\n", tmpString);
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
    #if defined(DEBUG_XFN)
      realToString((real_t *)fractionalPart, tmpString); tmpString[debugLongNumberLimit]=0; printf("decomposeReal 003: fractionalPart: %s\n", tmpString);
    #endif //DEBUG_XFN
    return;

}


  #define XFN_NOTFOUND 99
  #define FT_NILADIC  100
  #define FT_MONADIC  101
  #define FT_DYADIC   102
  #define FT_SINGLEX  103

typedef struct {
      int function_id;
      int function_type;
  } FunctionLookup;


  TO_QSPI static const FunctionLookup FUNCTION_TABLE[] = {
      { ITM_pi_XFN      ,FT_NILADIC },
      { ITM_DROP_XFN    ,FT_NILADIC },
      { ITM_SWAP_XFN    ,FT_NILADIC },
      { ITM_TO_XFN      ,FT_SINGLEX },  //special case where hte function drops one register
      { ITM_DEG2_XFN    ,FT_MONADIC },
      { ITM_RAD2_XFN    ,FT_MONADIC },
      { ITM_sin_XFN     ,FT_MONADIC },
      { ITM_cos_XFN     ,FT_MONADIC },
      { ITM_tan_XFN     ,FT_MONADIC },
      { ITM_arcsin_XFN  ,FT_MONADIC },
      { ITM_arccos_XFN  ,FT_MONADIC },
      { ITM_arctan_XFN  ,FT_MONADIC },
      { ITM_LN_XFN      ,FT_MONADIC },
      { ITM_LOG_XFN     ,FT_MONADIC },
      { ITM_EXP_XFN     ,FT_MONADIC },
      { ITM_10X_XFN     ,FT_MONADIC },
      { ITM_SQRT_XFN    ,FT_MONADIC },
      { ITM_MODANG_XFN  ,FT_MONADIC },
      { ITM_1ONX_XFN    ,FT_MONADIC },
      { ITM_atan2_XFN   ,FT_DYADIC  },
      { ITM_ADD_XFN     ,FT_DYADIC  },
      { ITM_SUB_XFN     ,FT_DYADIC  },
      { ITM_POWER_XFN   ,FT_DYADIC  },
      { ITM_MULT_XFN    ,FT_DYADIC  },
      { ITM_DIV_XFN     ,FT_DYADIC  },
      { ITM_MOD_XFN     ,FT_DYADIC  },
      { 0               ,0   }
  };


  static int lookupFunctionId(int function_id) {
      for (const FunctionLookup* entry = FUNCTION_TABLE; entry->function_id; entry++) {
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


  static bool_t getAngleModeForRegister(int registerNo, angularMode_t *angleMode ) {
    if(!inputAngleError3r(registerNo)) {
      *angleMode = deemedInputAngleMode3r(registerNo);
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
        realToString((real_t *)combined, tmpString); printf("VAR%d: x * y + z: %s; anglemode = %d\n", param, tmpString, *angleMode);
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

  static bool getSingleParameter (int registerNo, real1071_t* combined, angularMode_t* angleMode, realContext_t* c) {
printf("Dddd %d\n",registerNo);
    *angleMode = registerIsNoAngle(registerNo) ? amNone : getRegisterAngularMode(registerNo);

    if(!getLongintegerRegisterAsReal1071(registerNo, combined, c)) {                        //ignore anglemode, it is handled elsewhere
      displayCalcErrorMessage(ERROR_INPUT_DATA_TYPE_NOT_MATCHING, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
          sprintf(errorMessage, "Invalid input registers: getLongintegerRegisterAsReal1071");
          moreInfoOnError("In function fnXfn:getSingleParameter:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return false;
    }
    #if defined(DEBUG_XFN)
        realToString((real_t *)combined, tmpString); printf("VAR: x * y + z: %s\n", tmpString);
    #endif //DEBUG_XFN
    if(!validateExponent(combined)) {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        #if (EXTRA_INFO_ON_CALC_ERROR == 1)
            sprintf(errorMessage, "Total VAR = r%d exceeds the maximum exponent %d > %d", registerNo, realGetExponent(combined), maxAllowedDigits);
            moreInfoOnError("In function fnXfn:", errorMessage, NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        return false;
    }
    return true;
  }


  bool_t registerFMAOutputString(calcRegister_t regist, char* prefix, char *displayString) {
    angularMode_t angle;
    real1071_t tmp1, tmp2;
    realContext_t c = ctxtReal75;
    c.digits = 1000;
    c.round = DEC_ROUND_HALF_UP;
    if(getCombinedParameter(1, regist, &tmp1, &tmp2, &angle, &c)) {   //use the angle of the 1st param only, if set
      // realPlus((real_t *)&tmp1, (real_t *)&tmp1, &c);
      strcpy(displayString, prefix);
      realToSci((real_t *)&tmp1, displayString + stringByteLength(displayString));
      return true;
    }
    return false;
  }



  void fnDrop3(void) {
    fnDrop(NOPARAM);
    fnDrop(NOPARAM);
    fnDrop(NOPARAM);
    reallocateRegister(REGISTER_T, dtReal34, REAL34_SIZE_IN_BYTES, amNone);
    real34Copy(const34_0, REGISTER_REAL34_DATA(REGISTER_T));
    reallocateRegister(REGISTER_A, dtReal34, REAL34_SIZE_IN_BYTES, amNone);
    real34Copy(const34_0, REGISTER_REAL34_DATA(REGISTER_A));
    reallocateRegister(REGISTER_B, dtReal34, REAL34_SIZE_IN_BYTES, amNone);
    real34Copy(const34_0, REGISTER_REAL34_DATA(REGISTER_B));
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
    if((functionType == FT_NILADIC) || (functionType == FT_SINGLEX) ||
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
  void fnXXfn_swap                (uint16_t registerNo) {
    fnXfnIndirect(registerNo, ITM_SWAP_XFN);
  }
  void fnXXfn_drop                (uint16_t registerNo) {
    fnXfnIndirect(registerNo, ITM_DROP_XFN);
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
  void fnXXfn_TO                  (uint16_t registerNo) {
    fnXfnIndirect(registerNo, ITM_TO_XFN);
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
    if(functionType == FT_SINGLEX) {
      if(!getSingleParameter(registerNo, &paramX, &angleMode, &c)) {
        return;
      }      
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
        case ITM_SWAP_XFN: {
          fnSwapX(REGISTER_T);
          fnSwapY(REGISTER_A);
          fnSwapZ(REGISTER_B);
          return;
        }
        case ITM_DROP_XFN: {
          fnDrop3();
          return;
        }

  //--------//MONADIC FUNCTIONS
        case ITM_RAD2_XFN: {
          if(inputIsNoAngle3r(registerNo)) {
            angleMode = amRadian;
            break;
          } else
          if(!inputAngleError3r(registerNo) && angleMode != amRadian) {                                                                       // if either or both is/are set to am
            realDivide((real_t*)&paramX, modulus(angleMode), (real_t*)&paramX, &c);
            realMultiply((real_t*)&paramX, modulus(amRadian), (real_t*)&paramX, &c);        
          }
          angleMode = amRadian;
          break;
        }

        case ITM_DEG2_XFN: {
          if(inputIsNoAngle3r(registerNo)) {
            angleMode = amDegree;
            break;
          } else
          if(!inputAngleError3r(registerNo) && angleMode != amDegree) {                                                                       // if either or both is/are set to am
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
            if(function == ITM_sin_XFN) { C47Cvt2RadSinCosTan1071(&paramX, angleMode, &paramX, NULL,    NULL,    &c); } else
            if(function == ITM_cos_XFN) { C47Cvt2RadSinCosTan1071(&paramX, angleMode, NULL,    &paramX, NULL,    &c); } else
            if(function == ITM_tan_XFN) { C47Cvt2RadSinCosTan1071(&paramX, angleMode, &aa,     &bb,     &paramX, &c); }
            }
            break;

        case ITM_arcsin_XFN: {
          C47_WP34S_Asin1071(&paramX, &paramX, &c);
          convertAngleFromTo((real_t *)&paramX, amRadian, currentAngularMode, &c);
          break;
        }
        case ITM_arccos_XFN: {
          C47_WP34S_Acos1071(&paramX, &paramX, &c);
          convertAngleFromTo((real_t *)&paramX, amRadian, currentAngularMode, &c);
          break;
        }
        case ITM_arctan_XFN: {
          C47_WP34S_Atan1071(&paramX, &paramX, &c);
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
  //--------//SINGLE REG FUNCTIONS
        case ITM_TO_XFN: {
            //paramX input ->> output
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
          C47_WP34S_Atan2_1071(&paramY, &paramX, &paramX, &c);
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
    if((functionType == FT_MONADIC || functionType == FT_DYADIC)  && registerNo == REGISTER_X && lastErrorCode == 0) {       // If the base input register is X for XYZ bzw. TAB, then drop the stack input
        fnDrop3();
    } else if(functionType == FT_SINGLEX) {
        fnDrop(NOPARAM);
    }


    switch(function) {
      case ITM_arcsin_XFN:
      case ITM_arccos_XFN:
      case ITM_arctan_XFN:
      case ITM_atan2_XFN:
      case ITM_RAD2_XFN:
      case ITM_DEG2_XFN:
      case ITM_TO_XFN:
      case ITM_ADD_XFN:
      case ITM_SUB_XFN:
      case ITM_MULT_XFN: {
        //leave angleMode
        break;
      }
      default: {
        angleMode = amNone;
        break;
      }
    }


    //Step 1: Send a 0 addition term to the stack output (Form only, will be rewritten later)
    setSystemFlag(FLAG_ASLIFT);
    liftStack();
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

#endif //SAVE_SPACE_DM42_18_XFN


