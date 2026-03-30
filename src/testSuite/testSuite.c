// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file testSuite.c
 ***********************************************/

#include "c47.h"

#define NUMBER_OF_CORRECT_SIGNIFICANT_DIGITS_EXPECTED 34


extern const int16_t menu_FCNS[];
extern const int16_t menu_CONST[];
extern const int16_t menu_MENUS[];
extern const int16_t menu_SYSFL[];
extern const int16_t menu_alpha_INTL[];
extern const int16_t menu_alpha_intl[];
extern const int16_t menu_REGIST[];
extern const softmenu_t softmenu[];
char line[100000], lastInParameters[10000], fileName[1000], *filePath, filePathName[2000], registerExpectedAndValue[2400], realString[2400];
char testCaseName[1000], testCasePrefix[1000], testCaseSuffix[1000];
int32_t lineNumber, numTestsFile, numTestsTotal, failedTests;
int32_t functionIndex, funcType, correctSignificantDigits;

uint16_t label, functionParameter;

void (*funcToTest)(uint16_t);
void (*funcCvt)(uint16_t);
void runPgm(uint16_t unusedButMandatoryParameter);

static const char regNames[] = "XYZTABCDLIJKMNPQRSEFGHOUVW";

const funcTest_t funcTestNoParam[] = {
  {"fn10Pow",                fn10Pow               },
  {"fn2Pow",                 fn2Pow                },
  {"fnAdd",                  fnAdd                 },
  {"fnAim",                  fnAim                 },
  {"fnAgm",                  fnAgm                 },
  {"fnArccos",               fnArccos              },
  {"fnArccosh",              fnArccosh             },
  {"fnArcsin",               fnArcsin              },
  {"fnArcsinh",              fnArcsinh             },
  {"fnArctan",               fnArctan              },
  {"fnArctanh",              fnArctanh             },
  {"fnArg",                  fnArg                 },
  {"fnAsr",                  fnAsr                 },
  {"fnAtan2",                fnAtan2               },
  {"fnBatteryVoltage",       fnBatteryVoltage      },
  {"fnBesselJ",              fnBesselJ             },
  {"fnBesselY",              fnBesselY             },
  {"fnBinomialI",            fnBinomialI           },
  {"fnBinomialL",            fnBinomialL           },
  {"fnBinomialP",            fnBinomialP           },
  {"fnBinomialR",            fnBinomialR           },
  {"fnBn",                   fnBn                  },
  {"fnBnStar",               fnBnStar              },
  {"fnCauchyI",              fnCauchyI             },
  {"fnCauchyL",              fnCauchyL             },
  {"fnCauchyP",              fnCauchyP             },
  {"fnCauchyR",              fnCauchyR             },
  {"fnCb",                   fnCb                  },
  {"fnCeil",                 fnCeil                },
  {"fnChangeSign",           fnChangeSign          },
  {"fnChebyshevT",           fnChebyshevT          },
  {"fnChebyshevU",           fnChebyshevU          },
  {"fnChi2I",                fnChi2I               },
  {"fnChi2L",                fnChi2L               },
  {"fnChi2P",                fnChi2P               },
  {"fnChi2R",                fnChi2R               },
  {"fnClearRegisters",       fnClearRegisters      },
  {"fnClearStack",           fnClearStack          },
  {"fnClFAll",               fnClFAll              },
  {"fnClSigma",              fnClSigma             },
  {"fnClX",                  fnClX                 },
  {"fnConjugate",            fnConjugate           },
  {"fnCos",                  fnCos                 },
  {"fnCosh",                 fnCosh                },
  {"fnCountBits",            fnCountBits           },
  {"fnCross",                fnCross               },
  {"fnCube",                 fnCube                },
  {"fnCubeRoot",             fnCubeRoot            },
  {"fnCxToRe",               fnCxToRe              },
  {"fnCvtTemp",              fnCvtTemp             },
  {"fnCyx",                  fnCyx                 },
  {"fnDateTo",               fnDateTo              },
  {"fnDateToJulian",         fnDateToJulian        },
  {"fnDateTimeToJulian",     fnDateTimeToJulian    },
  {"fnDay",                  fnDay                 },
  {"fnDblDivide",            fnDblDivide           },
  {"fnDblDivideRemainder",   fnDblDivideRemainder  },
  {"fnDblMultiply",          fnDblMultiply         },
  {"fnDec",                  fnDec                 },
  {"fnDecomp",               fnDecomp              },
  {"fnDeltaPercent",         fnDeltaPercent        },
  {"fnDenMax",               fnDenMax              },
  {"fnDeterminant",          fnDeterminant         },
  {"fnDivide",               fnDivide              },
  {"fnDot",                  fnDot                 },
  {"fnDrop",                 fnDrop                },
  {"fnDropY",                fnDropY               },
  {"fnEigenvalues",          fnEigenvalues         },
  {"fnEigenvectors",         fnEigenvectors        },
  {"fnEllipticE",            fnEllipticE           },
  {"fnEllipticEphi",         fnEllipticEphi        },
  {"fnEllipticFphi",         fnEllipticFphi        },
  {"fnEllipticK",            fnEllipticK           },
  {"fnEllipticPi",           fnEllipticPi          },
  {"fnErf",                  fnErf                 },
  {"fnErfc",                 fnErfc                },
  {"fnPNorm",                fnPNorm               },
  {"fnEulersFormula",        fnEulersFormula       },
  {"fnExp",                  fnExp                 },
  {"fnExpM1",                fnExpM1               },
  {"fnExpMod",               fnExpMod              },
  {"fnExponentialI",         fnExponentialI        },
  {"fnExponentialL",         fnExponentialL        },
  {"fnExponentialP",         fnExponentialP        },
  {"fnExponentialR",         fnExponentialR        },
  {"fnExpt",                 fnExpt                },
  {"fnFactorial",            fnFactorial           },
  {"fnFib",                  fnFib                 },
  {"fnFillStack",            fnFillStack           },
  {"fnFloor",                fnFloor               },
  {"fnFp",                   fnFp                  },
  {"fnFreeFlashMemory",      fnFreeFlashMemory     },
  {"fnFreeMemory",           fnFreeMemory          },
  {"fnF_I",                  fnF_I                 },
  {"fnF_L",                  fnF_L                 },
  {"fnF_P",                  fnF_P                 },
  {"fnF_R",                  fnF_R                 },
  {"fnGamma",                fnGamma               },
  {"fnGammaX",               fnGammaX              },
  {"fnGcd",                  fnGcd                 },
  {"fnGd",                   fnGd                  },
  {"fnGeometricI",           fnGeometricI          },
  {"fnGeometricL",           fnGeometricL          },
  {"fnGeometricP",           fnGeometricP          },
  {"fnGeometricR",           fnGeometricR          },
  {"fnGetIntegerSignMode",   fnGetIntegerSignMode  },
  {"fnGetLocR",              fnGetLocR             },
  {"fnGetRoundingMode",      fnGetRoundingMode     },
  {"fnGetSignificantDigits", fnGetSignificantDigits},
  {"fnGetStackSize",         fnGetStackSize        },
  {"fnGetWordSize",          fnGetWordSize         },
  {"fnHermite",              fnHermite             },
  {"fnHermiteP",             fnHermiteP            },
  {"fnHypergeometricI",      fnHypergeometricI     },
  {"fnHypergeometricL",      fnHypergeometricL     },
  {"fnHypergeometricP",      fnHypergeometricP     },
  {"fnHypergeometricR",      fnHypergeometricR     },
  {"fnIDiv",                 fnIDiv                },
  {"fnIDivR",                fnIDivR               },
  {"fnImaginaryPart",        fnImaginaryPart       },
  {"fnInvert",               fnInvert              },
  {"fnInvertMatrix",         fnInvertMatrix        },
  {"fnInvGd",                fnInvGd               },
  {"fnIp",                   fnIp                  },
  {"fnLint",                 fnLint                },
  {"fnSint",                 fnSint                },
  {"fnIsPrime",              fnIsPrime             },
  {"fnNextPrime",            fnNextPrime           },
  {"fnPrimeFactors",         fnPrimeFactors        },
  {"fnEvPFacts",             fnEvPFacts            },
  {"fnIxyz",                 fnIxyz                },
  {"fnJacobiAmplitude",      fnJacobiAmplitude     },
  {"fnJacobiCn",             fnJacobiCn            },
  {"fnJacobiDn",             fnJacobiDn            },
  {"fnJacobiSn",             fnJacobiSn            },
  {"fnJacobiZeta",           fnJacobiZeta          },
  {"fnJulianToDateTime",     fnJulianToDateTime    },
  {"fnLaguerre",             fnLaguerre            },
  {"fnLaguerreAlpha",        fnLaguerreAlpha       },
  {"fnLcm",                  fnLcm                 },
  {"fnLegendre",             fnLegendre            },
  {"fnLINPOL",               fnLINPOL              },
  {"fnLn",                   fnLn                  },
  {"fnLnP1",                 fnLnP1                },
  {"fnLnGamma",              fnLnGamma             },
  {"fnLog10",                fnLog10               },
  {"fnLog2",                 fnLog2                },
  {"fnLogisticI",            fnLogisticI           },
  {"fnLogisticL",            fnLogisticL           },
  {"fnLogisticP",            fnLogisticP           },
  {"fnLogisticR",            fnLogisticR           },
  {"fnLogNormalI",           fnLogNormalI          },
  {"fnLogNormalL",           fnLogNormalL          },
  {"fnLogNormalP",           fnLogNormalP          },
  {"fnLogNormalR",           fnLogNormalR          },
  {"fnStdNormalI",           fnStdNormalI          },
  {"fnStdNormalL",           fnStdNormalL          },
  {"fnStdNormalP",           fnStdNormalP          },
  {"fnStdNormalR",           fnStdNormalR          },
  {"fnLogXY",                fnLogXY               },
  {"fnLnBeta",               fnLnBeta              },
  {"fnBeta",                 fnBeta                },
  {"fnLj",                   fnLj                  },
  {"fnLogicalAnd",           fnLogicalAnd          },
  {"fnLogicalNand",          fnLogicalNand         },
  {"fnLogicalNor",           fnLogicalNor          },
  {"fnLogicalNot",           fnLogicalNot          },
  {"fnLogicalOr",            fnLogicalOr           },
  {"fnLogicalXnor",          fnLogicalXnor         },
  {"fnLogicalXor",           fnLogicalXor          },
  {"fnLuDecomposition",      fnLuDecomposition     },
  {"fnM1Pow",                fnM1Pow               },
  {"fnMagnitude",            fnMagnitude           },
  {"fnMaskl",                fnMaskl               },
  {"fnMaskr",                fnMaskr               },
  {"fnMin",                  fnMin                 },
  {"fnMax",                  fnMax                 },
  {"fnMant",                 fnMant                },
  {"fnMirror",               fnMirror              },
  {"fnMod",                  fnMod                 },
  {"fnMonth",                fnMonth               },
  {"fnMulMod",               fnMulMod              },
  {"fnMultiply",             fnMultiply            },
  {"fnNegBinomialI",         fnNegBinomialI        },
  {"fnNegBinomialL",         fnNegBinomialL        },
  {"fnNegBinomialP",         fnNegBinomialP        },
  {"fnNegBinomialR",         fnNegBinomialR        },
  {"fnNeighb",               fnNeighb              },
  {"fnNop",                  fnNop                 },
  {"fnNormalI",              fnNormalI             },
  {"fnNormalL",              fnNormalL             },
  {"fnNormalP",              fnNormalP             },
  {"fnNormalR",              fnNormalR             },
  {"fnParallel",             fnParallel            },
  {"fnPi",                   fnPi                  },
  {"fnPercent",              fnPercent             },
  {"fnPercentMRR",           fnPercentMRR          },
  {"fnPercentT",             fnPercentT            },
  {"fnPercentPlusMG",        fnPercentPlusMG       },
  {"fnPercentSigma",         fnPercentSigma        },
  {"fnPoissonI",             fnPoissonI            },
  {"fnPoissonL",             fnPoissonL            },
  {"fnPoissonP",             fnPoissonP            },
  {"fnPoissonR",             fnPoissonR            },
  {"fnPower",                fnPower               },
  {"fnPyx",                  fnPyx                 },
  {"fnQrDecomposition",      fnQrDecomposition     },
  {"fnRealPart",             fnRealPart            },
  {"fnRecallIJ",             fnRecallIJ            },
  {"fnReToCx",               fnReToCx              },
  {"fnRj",                   fnRj                  },
  {"fnRL",                   fnRl                  },
  {"fnRLC",                  fnRlc                 },
  {"fnRmd",                  fnRmd                 },
  {"fnRollDown",             fnRollDown            },
  {"fnRollUp",               fnRollUp              },
  {"fnRound",                fnRound               },
  {"fnRoundi",               fnRoundi              },
  {"fnRowColSum",            fnRowColSum           },
  {"fnRR",                   fnRr                  },
  {"fnRRC",                  fnRrc                 },

  {"fnSign",                 fnSign                },
  {"fnSin",                  fnSin                 },
  {"fnSinc",                 fnSinc                },
  {"fnSincpi",               fnSincpi              },
  {"fnSinh",                 fnSinh                },
  {"fnSl",                   fnSl                  },
  {"fnSlvc",                 fnSlvc                },
  {"fnSlvq",                 fnSlvq                },
  {"fnSquare",               fnSquare              },
  {"fnSr",                   fnSr                  },
  {"fnStoreIJ",              fnStoreIJ             },
  {"fnSqrt1Px2",             fnSqrt1Px2            },
  {"fnSquareRoot",           fnSquareRoot          },
  {"fnSubtract",             fnSubtract            },
  {"fnSumXY",                fnSumXY               },
  {"fnSwapRealImaginary",    fnSwapRealImaginary   },
  {"fnSwapXY",               fnSwapXY              },
  {"fnTan",                  fnTan                 },
  {"fnTanh",                 fnTanh                },
  {"fnToDate",               fnToDate              },
  {"fnHRtoTM",               fnHRtoTM              },
  {"fnHMStoTM",              fnHMStoTM             },
  {"fnToReal",               fnToReal              },
  {"fnToPolar2",             fnToPolar2            },
  {"fnToRect2",              fnToRect2             },
  {"fnTranspose",            fnTranspose           },
  {"fnXXfn",                 fnXXfn                },
  {"fnXXfn_RSD",             fnXXfn_RSD            },
  {"fnXXfn_RDP",             fnXXfn_RDP            },
  {"fnEffToI",               fnEffToI              },
  {"fnEff",                  fnEff                 },
  {"fnTvmVar",               fnTvmVar              },
  {"fnT_I",                  fnT_I                 },
  {"fnT_L",                  fnT_L                 },
  {"fnT_P",                  fnT_P                 },
  {"fnT_R",                  fnT_R                 },
  {"fnUlp",                  fnUlp                 },
  {"fnUnitVector",           fnUnitVector          },
  {"fnUnzip",                fnUnzip               },
  {"fnVectorAngle",          fnVectorAngle         },
  {"fnWday",                 fnWday                },
  {"fnWeibullI",             fnWeibullI            },
  {"fnWeibullL",             fnWeibullL            },
  {"fnWeibullP",             fnWeibullP            },
  {"fnWeibullR",             fnWeibullR            },
  {"fnWinverse",             fnWinverse            },
  {"fnWnegative",            fnWnegative           },
  {"fnWpositive",            fnWpositive           },
  {"fnXthRoot",              fnXthRoot             },
  {"fnXToDate",              fnXToDate             },
  {"fnYear",                 fnYear                },
  {"fnZeta",                 fnZeta                },
  {"fnZip",                  fnZip                 },

  {"fnExecute",              runPgm                },
  {"",                       NULL                  }
};



void fnKeyGtoXeq             (uint16_t unusedButMandatoryParameter) {}
void fnKeyGto                (uint16_t unusedButMandatoryParameter) {}
void fnKeyXeq                (uint16_t unusedButMandatoryParameter) {}
void fnProgrammableMenu      (uint16_t unusedButMandatoryParameter) {}
void fnClearMenu             (uint16_t unusedButMandatoryParameter) {}
void updateMatrixHeightCache (void) {}
void tamEnterMode            (int16_t func) {}



void printRegisterToString(calcRegister_t regist, char *registerContent) {
  char str[1000];

  if(getRegisterDataType(regist) == dtReal34) {
    real34ToString(REGISTER_REAL34_DATA(regist), str);
    sprintf(registerContent, "real34 %s %s", str, getAngularModeName(getRegisterAngularMode(regist)));
  }

  else if(getRegisterDataType(regist) == dtComplex34) {    //This needs to change to use the standard complex to string function
    real34ToString(REGISTER_REAL34_DATA(regist), str);
    sprintf(registerContent, "complex34 %s ", str);

    real34ToString(REGISTER_IMAG34_DATA(regist), str);
    if(real34IsNegative(REGISTER_IMAG34_DATA(regist))) {
      strcat(registerContent, "- ix");
      strcat(registerContent, str + 1);
    }
    else {
      strcat(registerContent, "+ ix");
      strcat(registerContent, str);
    }
  }

  else if(getRegisterDataType(regist) == dtString) {
    stringToUtf8(REGISTER_STRING_DATA(regist), (uint8_t *)str);
    sprintf(registerContent, "string (%" PRIu32 " bytes) |%s|", TO_BYTES(getRegisterMaxDataLengthInBlocks(regist)), str);
  }

  else if(getRegisterDataType(regist) == dtShortInteger) {
    uint64_t value = *(REGISTER_SHORT_INTEGER_DATA(regist));
    sprintf(registerContent, "short integer %08x-%08x (base %u)", (unsigned int)(value>>32), (unsigned int)(value&0xffffffff), getRegisterTag(regist));
  }

  else if(getRegisterDataType(regist) == dtConfig) {
    strcpy(registerContent, "Configuration data");
  }

  else if(getRegisterDataType(regist) == dtLongInteger) {
    longInteger_t lgInt;
    char lgIntStr[3000];

    convertLongIntegerRegisterToLongInteger(regist, lgInt);
    longIntegerToAllocatedString(lgInt, lgIntStr, sizeof(lgIntStr));
    longIntegerFree(lgInt);
    sprintf(registerContent, "long integer (%" PRIu32 " bytes) %s", TO_BYTES(getRegisterMaxDataLengthInBlocks(regist)), lgIntStr);
  }

  else if(getRegisterDataType(regist) == dtTime) {
    real34ToString(REGISTER_REAL34_DATA(regist), str);
    sprintf(registerContent, "time %s", str);
  }

  else if(getRegisterDataType(regist) == dtDate) {
    real34ToString(REGISTER_REAL34_DATA(regist), str);
    sprintf(registerContent, "date %s", str);
  }

  else {
    sprintf(registerContent, "In printRegisterToString: data type %s not supported", getRegisterDataTypeName(regist ,false, false));
  }
}



void runPgm(uint16_t unusedButMandatoryParameter) {
  if(label != INVALID_VARIABLE) {
    reallyRunFunction(ITM_XEQ, label);
  }
}



char *endOfString(char *string) { // string must point on the 1st "
  string++;
  while(*string != '"' && *string != 0) {
    if(*string == '\\' && *(string + 1) == 'x') {
      string += 3;
    }
    else if(*string == '\\') {
      string++;
    }

    string++;
  }

  if(*string == '"') {
    string++;
  }
  else {
    printf("Unterminated string\n");
    abortTest();
  }

  return string; // pointer to the 1st char after the ending "
}



void strToShortInteger(char *nimBuffer, calcRegister_t regist) {
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // Any change in this function must be reported in the function closeNim from file bufferize.c after the line: else if(nimNumberPart == NP_INT_BASE) {
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  longInteger_t minVal, value, maxVal;
  int16_t posHash, i, lg;
  int32_t base;

  lg = strlen(nimBuffer);
  posHash = 0;
  for(i=1; i<lg; i++) {
    if(nimBuffer[i] == '#') {
      posHash = i;
      break;
    }
  }

  for(i=posHash+1; i<lg; i++) {
    if(nimBuffer[i]<'0' || nimBuffer[i]>'9') {
      printf("\nError while initializing a short integer: there is a non numeric character in the base of the integer!\n");
      abortTest();
    }
  }

  base = atoi(nimBuffer + posHash + 1);
  if(base < 2 || base > 16) {
    printf("\nError while initializing a short integer: the base of the integer must be from 2 to 16!\n");
    abortTest();
  }

  for(i=nimBuffer[0] == '-' ? 1 : 0; i<posHash; i++) {
    if((nimBuffer[i] > '9' ? nimBuffer[i] - 'A' + 10 : nimBuffer[i] - '0') >= base) {
      printf("\nError while initializing a short integer: digit %c is not allowed in base %d!\n", nimBuffer[i], base);
      abortTest();
    }
  }

  longIntegerInit(value);
  nimBuffer[posHash] = 0;
  stringToLongInteger(nimBuffer + (nimBuffer[0] == '+' ? 1 : 0), base, value);

  // maxVal = 2^shortIntegerWordSize
  longIntegerInit(maxVal);
  if(shortIntegerWordSize >= 1 && shortIntegerWordSize <= 64) {
    longInteger2Pow(shortIntegerWordSize, maxVal);
  }
  else {
    printf("\nError while initializing a short integer: shortIntegerWordSize must be fom 1 to 64\n");
    abortTest();
  }

  // minVal = -maxVal/2
  longIntegerInit(minVal);
  longIntegerDivideUInt(maxVal, 2, minVal); // minVal = maxVal / 2
  longIntegerSetNegativeSign(minVal); // minVal = -minVal

  if((base != 2) && (base != 4) && (base != 8) && (base != 16) && (shortIntegerMode != SIM_UNSIGN)) {
    longIntegerDivideUInt(maxVal, 2, maxVal); // maxVal /= 2
  }

  longIntegerSubtractUInt(maxVal, 1, maxVal); // maxVal--

  if(shortIntegerMode == SIM_UNSIGN) {
    longIntegerSetZero(minVal); // minVal = 0
  }

  if(shortIntegerMode == SIM_1COMPL || shortIntegerMode == SIM_SIGNMT) {
    longIntegerAddUInt(minVal, 1, minVal); // minVal++
  }

  if(longIntegerCompare(value, minVal) < 0 || longIntegerCompare(value, maxVal) > 0) {
    char strMin[22], strMax[22];
    longIntegerToAllocatedString(minVal, strMin, sizeof(strMin));
    longIntegerToAllocatedString(maxVal, strMax, sizeof(strMax));
    printf("\nError while initializing a short integer: for a word size of %d bit%s and integer mode %s, the entered number must be from %s to %s!\n", shortIntegerWordSize, shortIntegerWordSize>1 ? "s" : "", getShortIntegerModeName(shortIntegerMode), strMin, strMax);
    abortTest();
  }

  reallocateRegister(regist, dtShortInteger, 0, base);

  char strValue[22];
  longIntegerToAllocatedString(value, strValue, sizeof(strValue));

  uint64_t val = strtoull(strValue + (longIntegerIsNegative(value) ? 1 : 0), NULL, 10); // when value is negative: discard the minus sign

  if(shortIntegerMode == SIM_UNSIGN) {
  }
  else if(shortIntegerMode == SIM_2COMPL) {
    if(longIntegerIsNegative(value)) {
      val = (~val + 1) & shortIntegerMask;
    }
  }
  else if(shortIntegerMode == SIM_1COMPL) {
    if(longIntegerIsNegative(value)) {
      val = ~val & shortIntegerMask;
    }
  }
  else if(shortIntegerMode == SIM_SIGNMT) {
    if(longIntegerIsNegative(value)) {
      val = (val & shortIntegerMask) | shortIntegerSignBit;
    }
  }
  else {
    printf("\nBad integer mode while initializing a short integer\n");
    abortTest();
  }

  *(REGISTER_SHORT_INTEGER_DATA(regist)) = val;

  longIntegerFree(minVal);
  longIntegerFree(value);
  longIntegerFree(maxVal);
}



char hexToChar(const char *string) {
    // the itialisation to zero prevents a 'variable used is not initialized' warning on Mac:
    char ch=0;

  if(   (('0' <= string[0] && string[0] <= '9') || ('A' <= string[0] && string[0] <= 'F') || ('a' <= string[0] && string[0] <= 'f'))
     && (('0' <= string[1] && string[1] <= '9') || ('A' <= string[1] && string[1] <= 'F') || ('a' <= string[1] && string[1] <= 'f'))) {
    if('0' <= string[0] && string[0] <= '9') {
      ch = string[0] - '0';
    }
    else if('a' <= string[0] && string[0] <= 'f') {
      ch = string[0] - 'a' + 10;
    }
    else {
      ch = string[0] - 'A' + 10;
    }

    if('0' <= string[1] && string[1] <= '9') {
      ch = ch*16 + string[1] - '0';
    }
    else if('a' <= string[1] && string[1] <= 'f') {
      ch = ch*16 + string[1] - 'a' + 10;
    }
    else {
      ch = ch*16 + string[1] - 'A' + 10;
    }
  }
  else {
    printf("\nMalformed parameter setting. The hexadecimal char \\x%c%c is erroneous.\n", string[0], string[1]);
    abortTest();
  }

  return ch;
}



void getString(char *str) {
  int32_t i, j, lg;

  lg = stringByteLength(str);

  str[lg - 1] = 0; // The ending "
  lg--;

  for(i=0; i<lg; i++) {
    if(str[i] == '\\' && (str[i + 1] == '\\' || str[i + 1] == '"')) {
      for(j=i+1; j<=lg; j++) {
        str[j - 1] = str[j];
      }
      lg--;
    }

    else if(str[i] == '\\' && str[i + 1] == 'x') {
      str[i] = hexToChar(str + i + 2);
      for(j=i+4; j<=lg; j++) {
        str[j - 3] = str[j];
      }
      lg -= 3;
    }
  }
}



void setParameter(char *p) {
  calcRegister_t regist = 0;
  char l[200], r[1400], real[200], imag[200], angMod[200]; //, letter;
  int32_t i;
  angularMode_t am = amDegree;

  //printf("  setting %s\n", p);

  i = 0;
  while(p[i] != '=' && p[i] != 0) {
    i++;
  }
  if(p[i] == 0) {
    printf("\nMalformed parameter setting. Missing equal sign, remember that no space is allowed around the equal sign.\n");
    abortTest();
  }

  p[i] = 0;
  strcpy(l, p);
  strcpy(r, p + i + 1);

  if(r[0] == 0) {
    printf("\nMalformed parameter setting. Missing value after equal sign, remember that no space is allowed around the equal sign.\n");
    abortTest();
  }

  //Setting a flag
  if(!strncmp(l, "FL_", 3)) {
    if(r[0] != '0' && r[0] != '1' && r[1] != 0) {
      printf("\nMalformed flag setting. The rvalue must be 0 or 1\n");
      abortTest();
    }

    //Lettered flag
    if(l[3] >= 'A' && l[4] == 0) {
      if(strstr(regNames, l + 3) != NULL) {
        uint16_t flg;

        flg = l[3] == 'T' ? 103 :
              l[3] == 'L' ? 108 :
              l[3] <= 'D' ? l[3] + 39 :
              l[3] <= 'K' ? l[3] + 36 :
                            l[3] + 12;

        if(r[0] == '1') {
          fnSetFlag(flg);
          //printf("  Flag %c set\n", l[1]);
        }
        else {
          fnClearFlag(flg);
          //printf("  Flag %c cleared\n", l[1]);
        }
      }
      else {
        printf("\nMalformed flag setting. After FL_ there shall be a number from 0 to 111, a lettered, or a system flag.\n");
        abortTest();
      }
    }

    //Numbered flag
    else if(   (l[3] >= '0' && l[3] <= '9' && l[4] == 0)
            || (l[3] >= '0' && l[3] <= '9' && l[4] >= '0' && l[4] <= '9' && l[5] == 0)
            || (l[3] >= '0' && l[3] <= '9' && l[4] >= '0' && l[4] <= '9' && l[5] >= '0' && l[5] <= '9' && l[6] == 0)) {
      uint16_t flg = atoi(l + 3);
      if(flg <= 111) {
        if(r[0] == '1') {
          fnSetFlag(flg);
          //printf("  Flag %d set\n", flg);
        }
        else {
          fnClearFlag(flg);
          //printf("  Flag %d cleared\n", flg);
        }
      }
      else {
        printf("\nMalformed flag setting. After FL_ there shall be a number from 0 to 111, a lettered, or a system flag.\n");
        abortTest();
      }
    }

    //System flag
    else {
      if(!strcmp(l+3, "SPCRES")) {
        if(r[0] == '0') {
          clearSystemFlag(FLAG_SPCRES);
        }
        else {
          setSystemFlag(FLAG_SPCRES);
        }
      }
      else if(!strcmp(l+3, "CPXRES")) {
        if(r[0] == '0') {
          clearSystemFlag(FLAG_CPXRES);
        }
        else {
          setSystemFlag(FLAG_CPXRES);
        }
      }
      else if(!strcmp(l+3, "CARRY")) {
        if(r[0] == '0') {
          clearSystemFlag(FLAG_CARRY);
        }
        else {
          setSystemFlag(FLAG_CARRY);
        }
      }
      else if(!strcmp(l+3, "OVERFL")) {
        if(r[0] == '0') {
          clearSystemFlag(FLAG_OVERFLOW);
        }
        else {
          setSystemFlag(FLAG_OVERFLOW);
        }
      }
      else if(!strcmp(l+3, "ASLIFT")) {
        if(r[0] == '0') {
          clearSystemFlag(FLAG_ASLIFT);
        }
        else {
          setSystemFlag(FLAG_ASLIFT);
        }
      }
      else if(!strcmp(l+3, "YMD")) {
        if(r[0] == '0') {
          clearSystemFlag(FLAG_YMD);
        }
        else {
          setSystemFlag(FLAG_YMD);
        }
      }
      else if(!strcmp(l+3, "MDY")) {
        if(r[0] == '0') {
          clearSystemFlag(FLAG_MDY);}
        else {
          setSystemFlag(FLAG_MDY);
        }
      }
      else if(!strcmp(l+3, "DMY")) {
        if(r[0] == '0') {
          clearSystemFlag(FLAG_DMY);
        }
        else {
          setSystemFlag(FLAG_DMY);
        }
      }
      else if(!strcmp(l+3, "TDM24")) {
        if(r[0] == '0') {
          clearSystemFlag(FLAG_TDM24);
        }
        else {
          setSystemFlag(FLAG_TDM24);
        }
      }
      else if(!strcmp(l+3, "ENDPMT")) {
        if(r[0] == '0') {
          clearSystemFlag(FLAG_ENDPMT);
        }
        else {
          setSystemFlag(FLAG_ENDPMT);
        }
      }
      else {
        printf("\nMalformed numbered flag setting. After FL_ there shall be a number from 0 to 111, a lettered, or a system flag.\n");
        abortTest();
      }
    }
  }

  else if (strcmp(l, "FARG") == 0) {
    functionParameter = atoi(r);
  }

  //Setting integer mode
  else if(strcmp(l, "IM") == 0) {
    if(strcmp(r, "1COMPL") == 0) {
      shortIntegerMode = SIM_1COMPL;
      //printf("  Set integer mode to 1COMPL\n");
    }
    else if(strcmp(r, "2COMPL") == 0) {
      shortIntegerMode = SIM_2COMPL;
      //printf("  Set integer mode to 2COMPL\n");
    }
    else if(strcmp(r, "UNSIGN") == 0) {
      shortIntegerMode = SIM_UNSIGN;
      //printf("  Set integer mode to UNSIGN\n");
    }
    else if(strcmp(r, "SIGNMT") == 0) {
      shortIntegerMode = SIM_SIGNMT;
      //printf("  Set integer mode to SIGNMT\n");
    }
    else {
      printf("\nMalformed integer mode setting. The rvalue must be 1COMPL, 2COMPL, UNSIGN or SIGNMT.\n");
      abortTest();
    }
  }

  //Setting Complex mode
  else if(strcmp(l, "CM") == 0) {
    if(strcmp(r, "RECT") == 0) {
      clearSystemFlag(FLAG_POLAR);
      //printf("  Set complex mode to RECT\n");
    }
    else if(strcmp(r, "POLAR") == 0) {
      setSystemFlag(FLAG_POLAR);
      //printf("  Set complex mode to POLAR\n");
    }
    else {
      printf("\nMalformed complex mode setting. The rvalue must be RECT or POLAR.\n");
      abortTest();
    }
  }

  //Setting angular mode
  else if(strcmp(l, "AM") == 0) {
    if(strcmp(r, "DEG") == 0) {
      currentAngularMode = amDegree;
      //printf("  Set angular mode to DEG\n");
    }
    else if(strcmp(r, "DMS") == 0) {
      currentAngularMode = amDMS;
      //printf("  Set angular mode to DMS\n");
    }
    else if(strcmp(r, "RAD") == 0) {
      currentAngularMode = amRadian;
      //printf("  Set angular mode to RAD\n");
    }
    else if(strcmp(r, "MULTPI") == 0) {
      currentAngularMode = amMultPi;
      //printf("  Set angular mode to MULTPI\n");
    }
    else if(strcmp(r, "GRAD") == 0) {
      currentAngularMode = amGrad;
      //printf("  Set angular mode to GRAD\n");
    }
    else {
      printf("\nMalformed angular mode setting. The rvalue must be DEG, DMS, GRAD, RAD or MULTPI.\n");
      abortTest();
    }
  }

  //Setting stack size
  else if(strcmp(l, "SS") == 0) {
    if(strcmp(r, "4") == 0) {
      clearSystemFlag(FLAG_SSIZE8);
      //printf("  Set stack size to 4\n");
    }
    else if(strcmp(r, "8") == 0) {
      setSystemFlag(FLAG_SSIZE8);
      //printf("  Set stack size to 8\n");
    }
    else {
      printf("\nMalformed stack size setting. The rvalue must be 4 or 8.\n");
      abortTest();
    }
  }

  //Setting word size
  else if(strcmp(l, "WS") == 0) {
    if(   (r[0] >= '0' && r[0] <= '9' && r[1] == 0)
       || (r[0] >= '0' && r[0] <= '9' && r[1] >= '0' && r[1] <= '9' && r[2] == 0)) {
      uint16_t ws = atoi(r);

      if(ws == 0) {
        ws = 64;
      }
      if(ws <= 64) {
        fnSetWordSize(ws);
        //printf("  Set word size to %d bit\n", ws);
      }
      else {
        printf("\nMalformed word size setting. The rvalue must be from 0 to 64 (0 is the same as 64).\n");
        abortTest();
      }
    }
    else {
      printf("\nMalformed word size setting. The rvalue must be a number from 0 to 64 (0 is the same as 64).\n");
      abortTest();
    }
  }

  //Setting gap
  else if(strcmp(l, "GAP") == 0) {
    if(   (r[0] >= '0' && r[0] <= '9' && r[1] == 0)
       || (r[0] >= '0' && r[0] <= '9' && r[1] >= '0' && r[1] <= '9' && r[2] == 0)) {
      uint16_t gap = atoi(r);

      if(gap <= 15) {

        grpGroupingLeft = gap;
        grpGroupingRight = gap;
        //printf("  Set grouping gap to %d\n", gap);
      }
      else {
        printf("\nMalformed grouping gap setting. The rvalue must be from 0 to 15.\n");
        abortTest();
      }
    }
    else {
      printf("\nMalformed grouping gap setting. The rvalue must be a number from 0 to 15.\n");
      abortTest();
    }
  }

  //Setting J/G
  else if(strcmp(l, "JG") == 0) {
    if(                 (r[0] >= '0' && r[0] <= '9' &&
        ((r[1] == 0) || (r[1] >= '0' && r[1] <= '9' &&
        ((r[2] == 0) || (r[2] >= '0' && r[2] <= '9' &&
        ((r[3] == 0) || (r[3] >= '0' && r[3] <= '9' &&
        ((r[4] == 0) || (r[4] >= '0' && r[4] <= '9' &&
        ((r[5] == 0) || (r[5] >= '0' && r[5] <= '9' &&
        ((r[6] == 0) || (r[6] >= '0' && r[6] <= '9' &&
        ((r[7] == 0) || (r[7] >= '0' && r[7] <= '9' &&
        ((r[8] == 0) || (r[8] >= '0' && r[8] <= '9' &&
        ((r[9] == 0) ))))))))))))))))))) {
      firstGregorianDay = atoi(r);
    }
    else {
      printf("\nMalformed J/G setting. The rvalue must be a number.\n");
      abortTest();
    }
  }

  //Setting significant digits
  else if(strcmp(l, "SD") == 0) {
    if(   (r[0] >= '0' && r[0] <= '9' && r[1] == 0)
       || (r[0] >= '0' && r[0] <= '9' && r[1] >= '0' && r[1] <= '9' && r[2] == 0)) {
      uint16_t sd = atoi(r);

      if(sd <= 34) {
        significantDigits = sd;
        //printf("  Set significant digits to %d\n", sd);
      }
      else {
        printf("\nMalformed significant digits setting. The rvalue must be from 0 to 34 (0 is the same as 34).\n");
        abortTest();
      }
    }
    else {
      printf("\nMalformed significant digits setting. The rvalue must be a number from 0 to 34 (0 is the same as 34).\n");
      abortTest();
    }
  }

  //Setting rounding mode
  else if(strcmp(l, "RMODE") == 0) {
    if(isdigit(r[0]) && r[1] == 0) {
      uint16_t rm = atoi(r);

      if(rm <= 6) {
        fnRoundingMode(rm);
        //printf("  Set rounding mode to %d (%s)\n", rm, getRoundingModeName(rm));
        //printf("  Set rounding mode to %d\n", rm);
      }
      else {
        printf("\nMalformed rounding mode setting. The rvalue must be a number from 0 to 6.\n");
        abortTest();
      }
    }
    else {
      printf("\nMalformed rounding mode setting. The rvalue must be a number from 0 to 6.\n");
      abortTest();
    }
  }


  //Setting a variable
  else if(l[0] == 'V') {

    //Variable V256-V3000
    if(   (l[1] >= '0' && l[1] <= '9' && l[2] >= '0' && l[2] <= '9' && l[3] >= '0' && l[3] <= '9' && l[4] == 0)
       || (l[1] >= '0' && l[1] <= '9' && l[2] >= '0' && l[2] <= '9' && l[3] >= '0' && l[3] <= '9' && l[4] >= '0' && l[4] <= '9' && l[5] == 0)) {
      regist = atoi(l + 1);
      if(regist < 256 || regist > 3000) {
        printf("\nMalformed variable setting. The number after V shall be from 256 to 3000.\n");
        abortTest();
      }
    }

    else {
      printf("\nMalformed variable setting. After V there should be a number from 256 to 3000.\n");
      abortTest();
    }
    goto var1;
  }


  //Setting a register
  else if(l[0] == 'R') {

    //Lettered register
    if(l[1] >= 'A' && l[2] == 0) {
      const char *p = strchr(regNames, l[1]);
      if(p != NULL) {
        regist = REGISTER_X + (p - regNames);
      }
      else {
        printf("\nMalformed lettered register setting. The letter after R is not a lettered register (%s).\n", regNames);
        abortTest();
      }
    }

    //Numbered register
    else if(   (l[1] >= '0' && l[1] <= '9' && l[2] == 0)
            || (l[1] >= '0' && l[1] <= '9' && l[2] >= '0' && l[2] <= '9' && l[3] == 0)
            || (l[1] >= '0' && l[1] <= '9' && l[2] >= '0' && l[2] <= '9' && l[3] >= '0' && l[3] <= '9' && l[4] == 0)) {
      regist = atoi(l + 1);
      if(regist > LAST_SPARE_REGISTER || regist < 0) {
        printf("\nMalformed numbered register setting. Th number after R shall be a number from 0 to %d.\n", LAST_GLOBAL_REGISTER);
        abortTest();
      }
      //letter = 0;
    }

    else {
      printf("\nMalformed register setting. After R there should be a number from 0 to %d or a lettered register.\n", LAST_GLOBAL_REGISTER);
      abortTest();
    }
var1:
    // find the : separating the data type and the value
    i = 0;
    while(r[i] != ':' && r[i] != 0) {
      i++;
    }
    if(r[i] == 0) {
      printf("\nMalformed register value. Missing colon between data type and value.\n");
      abortTest();
    }

    // separating the data type and the value
    r[i] = 0;
    strcpy(l, r);
    xcopy(r, r + i + 1, strlen(r + i + 1) + 1);

    if(strcmp(l, "LONI") == 0) {
      longInteger_t lgInt;

      // remove beginning and ending " and removing leading spaces
      xcopy(r, r + 1, strlen(r));
      while(r[0] == ' ') {
        xcopy(r, r + 1, strlen(r));
      }
      r[strlen(r) - 1] = 0;

      longIntegerInit(lgInt);
      stringToLongInteger(r, 10, lgInt);
      convertLongIntegerToLongIntegerRegister(lgInt, regist);
      longIntegerFree(lgInt);
    }
    else if(strcmp(l, "REAL") == 0) {
      // find the : separating the real value from the angular mode
      i = 0;
      while(r[i] != ':' && r[i] != 0) {
        i++;
      }
      if(r[i] == 0) {
        strcat(r, ":NONE");
      }

      // separate real value and angular mode
      r[i] = 0;
      strcpy(angMod, r + i + 1);

      if(strcmp(angMod, "DEG"   ) == 0) {
        am = amDegree;
      }
      else if(strcmp(angMod, "DMS"   ) == 0) {
        am = amDMS;
      }
      else if(strcmp(angMod, "RAD"   ) == 0) {
        am = amRadian;
      }
      else if(strcmp(angMod, "MULTPI") == 0) {
        am = amMultPi;
      }
      else if(strcmp(angMod, "GRAD"  ) == 0) {
        am = amGrad;
      }
      else if(strcmp(angMod, "NONE"  ) == 0) {
        am = amNone;
      }
      else {
        printf("\nMalformed register real%d angular mode. Unknown angular mode after real value.\n", strcmp(l, "RE16") == 0 ? 16 : 34);
        abortTest();
      }

      // remove beginning and ending " and removing leading spaces
      xcopy(r, r + 1, strlen(r));
      while(r[0] == ' ') {
        xcopy(r, r + 1, strlen(r));
      }
      r[strlen(r) - 1] = 0;

      // replace , with .
      for(i=0; i<(int)strlen(r); i++) {
        if(r[i] == ',') {
          r[i] = '.';
        }
      }

      reallocateRegister(regist, dtReal34, 0, am);
      stringToReal34(r, REGISTER_REAL34_DATA(regist));
    }
    else if(strcmp(l, "STRI") == 0) {
      getString(r + 1);
      reallocateRegister(regist, dtString, TO_BLOCKS(stringByteLength(r + 1) + 1), amNone);
      strcpy(REGISTER_STRING_DATA(regist), r + 1);
    }
    else if(strcmp(l, "SHOI") == 0) {
      // find the # separating the value from the base
      i = 0;
      while(r[i] != '#' && r[i] != 0) {
        i++;
      }
      if(r[i] == 0) {
        printf("\nMalformed register short integer value. Missing # between value and base.\n");
        abortTest();
      }

      // remove beginning and ending " and removing leading spaces
      xcopy(r, r + 1, strlen(r));
      while(r[0] == ' ') {
        xcopy(r, r + 1, strlen(r));
      }
      r[strlen(r) - 1] = 0;

      // Convert string to upper case
      for(i=0; r[i]!=0; i++) {
        if('a' <= r[i] && r[i] <= 'z') {
          r[i] -= 32;
        }
      }

      strToShortInteger(r, regist);
    }
    else if(strcmp(l, "CPLX") == 0) {
      // remove beginning and ending " and removing leading spaces
      xcopy(r, r + 1, strlen(r));
      while(r[0] == ' ') {
        xcopy(r, r + 1, strlen(r));
      }
      r[strlen(r) - 1] = 0;

      // find the i separating the real and imagynary part
      i = 0;
      while(r[i] != 'i' && r[i] != 0) {
        i++;
      }
      if(r[i] == 0) {
        printf("\nMalformed register complex34 value. Missing i between real and imaginary part.\n");
        abortTest();
      }

      // separate real and imaginary part
      r[i] = 0;
      strcpy(real, r);
      strcpy(imag, r + i + 1);

      // remove leading spaces
      while(imag[0] == ' ') {
        xcopy(imag, imag + 1, strlen(imag));
      }

      // removing trailing spaces from real part
      while(real[strlen(real) - 1] == ' ') {
        real[strlen(real) - 1] = 0;
      }

      // removing trailing spaces from imaginary part
      while(imag[strlen(imag) - 1] == ' ') {
        imag[strlen(imag) - 1] = 0;
      }

      // replace , with . in the real part
      for(i=0; i<(int)strlen(real); i++) {
        if(real[i] == ',') {
          real[i] = '.';
        }
      }

      // replace , with . in the imaginary part
      for(i=0; i<(int)strlen(imag); i++) {
        if(imag[i] == ',') {
          imag[i] = '.';
        }
      }

      reallocateRegister(regist, dtComplex34, 0, amNone);
      stringToReal34(real, REGISTER_REAL34_DATA(regist));
      stringToReal34(imag, REGISTER_IMAG34_DATA(regist));
    }
    else if(strcmp(l, "TIME") == 0) {
      int32_t k = 0;
      bool_t isHms = false;

      // find the : separating hours and minutes
      i = 0;
      while(r[i] != ':' && r[i] != 0) {
        i++;
      }
      if(r[i] == ':') { // Input by HMS
        isHms = true;
        k = i;
        r[i] = '.';
        do {
          ++k;
          if((r[k] != ':') && (r[k] != '.') && (r[k] != ',')) {
            r[++i] = r[k];
          }
        } while(r[k] != 0);
      }
      am = amNone;

      // remove beginning and ending " and removing leading spaces
      xcopy(r, r + 1, strlen(r));
      while(r[0] == ' ') {
        xcopy(r, r + 1, strlen(r));
      }
      r[strlen(r) - 1] = 0;

      // replace , with .
      for(i=0; i<(int)strlen(r); i++) {
        if(r[i] == ',') {
          r[i] = '.';
        }
      }

      reallocateRegister(regist, dtTime, 0, amNone);
      stringToReal34(r, REGISTER_REAL34_DATA(regist));
      if(isHms) {
        hmmssInRegisterToSeconds(regist);
      }
    }
    else if(strcmp(l, "DATE") == 0) {
      // remove beginning and ending " and removing leading spaces
      xcopy(r, r + 1, strlen(r));
      while(r[0] == ' ') {
        xcopy(r, r + 1, strlen(r));
      }
      r[strlen(r) - 1] = 0;

      // replace , with .
      for(i=0; i<(int)strlen(r); i++) {
        if(r[i] == ',') {
          r[i] = '.';
        }
      }

      reallocateRegister(regist, dtReal34, 0, amNone);
      stringToReal34(r, REGISTER_REAL34_DATA(regist));
      convertReal34RegisterToDateRegister(regist, regist, !YYSystem);
    }
    else if(strcmp(l, "REMA") == 0) {
      // remove beginning and ending " and removing leading spaces
      xcopy(r, r + 1, strlen(r));
      while(r[0] == ' ') {
        xcopy(r, r + 1, strlen(r));
      }
      r[strlen(r) - 1] = 0;

      // 'M'
      if(r[0] == 'M') {
        int rows, cols;
        xcopy(r, r + 1, strlen(r));
        while(r[0] == ' ') {
          xcopy(r, r + 1, strlen(r));
        }
        // rows
        i = 0;
        while(r[i] != ',' && r[i] != 0) {
          i++;
        }
        if(r[i] == ',') {
          r[i] = 0;
          rows = atoi(r);
          xcopy(r, r + i + 1, strlen(r + i + 1) + 1);
          while(r[0] == ' ') {
            xcopy(r, r + 1, strlen(r));
          }
          // cols
          i = 0;
          while(r[i] != '[' && r[i] != 0) {
            i++;
          }
          if(r[i] == '[') {
            r[i] = 0;
            cols = atoi(r);
            xcopy(r, r + i + 1, strlen(r + i + 1) + 1);
            while(r[0] == ' ') {
              xcopy(r, r + 1, strlen(r));
            }
            lastErrorCode = 0;
            initMatrixRegister(regist, rows, cols, false);
            // elements
            for(int element = 0; element < rows * cols; ++element) {
              i = 0;
              while(r[i] != ',' && r[i] != ']' && r[i] != 0) {
                i++;
              }
              bool_t lastElement = (r[i] != ',');
              r[i] = 0;
              stringToReal34(r, REGISTER_REAL34_MATRIX_ELEMENTS(regist) + element);
              if(lastElement) {
                if(element < (rows * cols - 1)) {
                  printf("\nmalformed register value. Not enough elements\n");
                  abortTest();
                }
                break;
              }
              if(element >= (rows * cols - 1)) {
                printf("\nmalformed register value. Too many elements\n");
                abortTest();
                break;
              }
              xcopy(r, r + i + 1, strlen(r + i + 1) + 1);
              while(r[0] == ' ') {
                xcopy(r, r + 1, strlen(r));
              }
            }
          }
          else {
            printf("\nmalformed register value. Missing left bracket after number of columns\n");
            abortTest();
          }
        }
        else {
          printf("\nmalformed register value. Missing comma between number of rows and of columns\n");
          abortTest();
        }
      }
      else {
        printf("\nmalformed register value. Value does not begin with 'M'\n");
        abortTest();
      }
    }
    else if(strcmp(l, "CXMA") == 0) {
      // remove beginning and ending " and removing leading spaces
      xcopy(r, r + 1, strlen(r));
      while(r[0] == ' ') {
        xcopy(r, r + 1, strlen(r));
      }
      r[strlen(r) - 1] = 0;

      // 'M'
      if(r[0] == 'M') {
        int rows, cols;
        xcopy(r, r + 1, strlen(r));
        while(r[0] == ' ') {
          xcopy(r, r + 1, strlen(r));
        }
        // rows
        i = 0;
        while(r[i] != ',' && r[i] != 0) {
          i++;
        }
        if(r[i] == ',') {
          r[i] = 0;
          rows = atoi(r);
          xcopy(r, r + i + 1, strlen(r + i + 1) + 1);
          while(r[0] == ' ') {
            xcopy(r, r + 1, strlen(r));
          }
          // cols
          i = 0;
          while(r[i] != '[' && r[i] != 0) {
            i++;
          }
          if(r[i] == '[') {
            r[i] = 0;
            cols = atoi(r);
            xcopy(r, r + i + 1, strlen(r + i + 1) + 1);
            while(r[0] == ' ') {
              xcopy(r, r + 1, strlen(r));
            }
            lastErrorCode = 0;
            initMatrixRegister(regist, rows, cols, true);
            // elements
            for(int element = 0; element < rows * cols; ++element) {
              bool_t lastElement = false;
              // real part
              i = 0;
              while(r[i] != 'i' && r[i] != ',' && r[i] != ']' && r[i] != 0) {
                i++;
              }
              bool_t imagFollows = (r[i] == 'i');
              lastElement = (r[i] != 'i' && r[i] != ',');
              r[i] = 0;
              stringToReal34(r, VARIABLE_REAL34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(regist) + element));
              // imaginary part
              if(imagFollows) {
                xcopy(r, r + i + 1, strlen(r + i + 1) + 1);
                while(r[0] == ' ') {
                  xcopy(r, r + 1, strlen(r));
                }
                i = 0;
                while(r[i] != ',' && r[i] != ']' && r[i] != 0) {
                  i++;
                }
                lastElement = (r[i] != ',');
                r[i] = 0;
                stringToReal34(r, VARIABLE_IMAG34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(regist) + element));
              }
              if(lastElement) {
                if(element < (rows * cols - 1)) {
                  printf("\nmalformed register value. Not enough elements\n");
                  abortTest();
                }
                break;
              }
              if(element >= (rows * cols - 1)) {
                printf("\nmalformed register value. Too many elements\n");
                abortTest();
                break;
              }
              xcopy(r, r + i + 1, strlen(r + i + 1) + 1);
              while(r[0] == ' ') {
                xcopy(r, r + 1, strlen(r));
              }
            }
          }
          else {
            printf("\nmalformed register value. Missing left bracket after number of columns\n");
            abortTest();
          }
        }
        else {
          printf("\nmalformed register value. Missing comma between number of rows and of columns\n");
          abortTest();
        }
      }
      else {
        printf("\nmalformed register value. Value does not begin with 'M'\n");
        abortTest();
      }
    }
    else {
      printf("\nmalformed register value. Unknown data type %s for register %s\n", l, p+1);
      abortTest();
    }

    //if(letter == 0) {
    //  printf("  R%d = ", regist);
    //}
    //else {
    //  printf("  R%c = ", letter);
    //}

    //printRegisterToConsole(regist, 0);
    //printf("\n");
  }

  //Setting a program to run
  else if(strcmp(l, "PGM") == 0) {
    r[strlen(r) - 1] = 0;
    label = findNamedLabel(r + 1);
    if(label == INVALID_VARIABLE) {
      printf("\nUnknown global label: %s\n", r+1);
      abortTest();
    }
  }

  else {
    printf("\nUnknown setting %s.\n", l);
    abortTest();
  }
}



void inParameters(char *token) {
  char parameter[2000];
  int32_t lg;

  strReplace(token, "inf", "9e9999");

  while(*token == ' ') {
    token++;
  }
  while(*token != 0) {
    int32_t index = 0;
    while(*token != ' ' && *token != 0) {
      if(*token == '"') { // Inside a string
        lg = endOfString(token) - token;
        strncpy(parameter + index, token, lg--);
        index += lg;
        token += lg;
      }
      parameter[index++] = *(token++);
    }
    parameter[index] = 0;

    setParameter(parameter);

    while(*token == ' ') {
      token++;
    }
  }
}



void checkRegisterType(calcRegister_t regist, char letter, uint32_t expectedDataType, uint32_t expectedTag) {
  if(getRegisterDataType(regist) != expectedDataType) {
    if(letter == 0) {
      printf("\nRegister %d should be %s but it is %s!\n", regist, getDataTypeName(expectedDataType, true, false), getDataTypeName(getRegisterDataType(regist), true, false));
      printf("R%d = ", regist);
    }
    else {
      printf("\nRegister %c should be %s but it is %s!\n", letter, getDataTypeName(expectedDataType, true, false), getDataTypeName(getRegisterDataType(regist), true, false));
      printf("R%c = ", letter);
    }
    printRegisterToConsole(regist, "", "\n");
    abortTest();
  }

  if(getRegisterTag(regist) != expectedTag) {
    if(getRegisterDataType(regist) == dtShortInteger) {
      if(letter == 0) {
        printf("\nRegister %d is a short integer base %u but it should be base %u!\n", regist, expectedTag, getRegisterShortIntegerBase(regist));
        printf("R%d = ", regist);
      }
      else {
        printf("\nRegister %c is a short integer base %u but it should be base %u!\n", letter, expectedTag, getRegisterShortIntegerBase(regist));
        printf("R%c = ", letter);
      }
      printRegisterToConsole(regist, "", "\n");
      abortTest();
    }
    else if(getRegisterDataType(regist) == dtReal34) {
      if(letter == 0) {
        printf("\nRegister %d should be a real tagged %s but it is tagged %s!\n", regist, getAngularModeName(expectedTag), getAngularModeName(getRegisterAngularMode(regist)));
        printf("R%d = ", regist);
      }
      else {
        printf("\nRegister %c should be a real tagged %s but it is tagged %s!\n", letter, getAngularModeName(expectedTag), getAngularModeName(getRegisterAngularMode(regist)));
        printf("R%c = ", letter);
      }
      printRegisterToConsole(regist, "", "\n");
      abortTest();
    }
    else if(getRegisterDataType(regist) == dtLongInteger) {
      if(letter == 0) {
        printf("\nRegister %d should be a long integer tagged %u but it is tagged %u!\n", regist, expectedTag, getRegisterLongIntegerSign(regist));
        printf("R%d = ", regist);
      }
      else {
        printf("\nRegister %c should be a long integer tagged %u but it is tagged %u!\n", letter, expectedTag, getRegisterLongIntegerSign(regist));
        printf("R%c = ", letter);
      }
      printRegisterToConsole(regist, "", "\n");
      abortTest();
    }
  }
}



int relativeErrorReal34(real34_t *expectedValue34, real34_t *value34, char *numberPart, calcRegister_t regist, char letter) {
  real_t expectedValue, value, relativeError;

  real34ToReal(expectedValue34, &expectedValue);
  real34ToReal(value34, &value);

  realSubtract(&expectedValue, &value, &relativeError, &ctxtReal39);

  if(!realIsZero(&expectedValue)) {
    realDivide(&relativeError, &expectedValue, &relativeError, &ctxtReal39);
  }
  else {
    realCopy(&value, &relativeError);
  }
  realSetPositiveSign(&relativeError);

  correctSignificantDigits = -relativeError.exponent - relativeError.digits;
  ctxtReal39.digits = 2;
  realPlus(&relativeError, &relativeError, &ctxtReal39);
  ctxtReal39.digits = 39;
  if(correctSignificantDigits < 30) {
    //printf("\nThere are only %d correct significant digits in the %s part of the value: %d are expected!\n", correctSignificantDigits, numberPart, NUMBER_OF_CORRECT_SIGNIFICANT_DIGITS_EXPECTED);
    realToString(&relativeError, realString);
    if(letter == 0) {
      printf("\nThere are only %d correct significant digits in the %s part of register %d! Relative error is %s\n", correctSignificantDigits, numberPart, regist, realString);
      printf("R%d = ", regist);
      printReal34ToConsole(value34, "", "\n");
    }
    else {
      printf("\nThere are only %d correct significant digits in the %s part of register %c! Relative error is %s\n", correctSignificantDigits, numberPart, letter, realString);
      printf("%c = ", letter);
      printReal34ToConsole(value34, "", "\n");
    }
    printf("%s\n", lastInParameters);
    printf("%s\n", line);
    printf("in file %s line %d\n", fileName, lineNumber);
    if(correctSignificantDigits < 30 && correctSignificantDigits < NUMBER_OF_CORRECT_SIGNIFICANT_DIGITS_EXPECTED) {
      puts(registerExpectedAndValue);
      //exit(-1);
    }
  }

  return (correctSignificantDigits < 30 && correctSignificantDigits < NUMBER_OF_CORRECT_SIGNIFICANT_DIGITS_EXPECTED) ? RE_INACCURATE : RE_ACCURATE;
}



void wrongElementValue(calcRegister_t regist, char letter, int row, int col, char *expectedValue) {
  if(letter == 0) {
    printf("\nRegister %d value should be ", regist);
  }
  else {
    printf("\nRegister %c value should be ", letter);
  }
  if(row > 0 && col > 0) {
    printf("%s for element (%d, %d)\nbut it is ", expectedValue, row, col);
  }
  else {
    printf("%s\nbut it is ", expectedValue);
  }
  switch(getRegisterDataType(regist)) {
    case dtReal34Matrix:
      if(row > 0 && col > 0) {
        char str[300];
        int cols = REGISTER_MATRIX_HEADER(regist)->matrixColumns;
        real34ToString(REGISTER_REAL34_MATRIX_ELEMENTS(regist) + (row - 1) * cols + (col - 1), str);
        printf("%s\n", str);
      }
      else {
        printf("a real matrix\n");
      }
      break;

    case dtComplex34Matrix:
      if(row > 0 && col > 0) {
        char str[300];
        int cols = REGISTER_MATRIX_HEADER(regist)->matrixColumns;
        real34ToString(VARIABLE_REAL34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(regist) + (row - 1) * cols + (col - 1)), str);
        printf("%s", str);
        real34ToString(VARIABLE_IMAG34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(regist) + (row - 1) * cols + (col - 1)), str);
        printf(" %c ix %s\n", str[0] == '-' ? '-' : '+', str + (str[0] == '-' ? 1 : 0));
      }
      else {
        printf("a complex matrix\n");
      }
      break;

    default:
      printRegisterToConsole(regist, "", "\n");
  }
  abortTest();
}



void wrongRegisterValue(calcRegister_t regist, char letter, char *expectedValue) {
  wrongElementValue(regist, letter, 0, 0, expectedValue);
}



void wrongRegisterMatrixSize(calcRegister_t regist, char letter, int expectedRows, int expectedCols) {
  if(letter == 0) {
    printf("\nRegister %d value should be of ", regist);
  }
  else {
    printf("\nRegister %c value should be of ", letter);
  }
  printf("%dx%d size\nbut it is of ", expectedRows, expectedCols);
  printf("%dx%d", REGISTER_MATRIX_HEADER(regist)->matrixRows, REGISTER_MATRIX_HEADER(regist)->matrixColumns);
  printf("\nwrong size of matrix\n");
  abortTest();
}



void expectedAndShouldBeValueForElement(calcRegister_t regist, char letter, int row, int col, char *expectedValue, char *expectedAndValue) {
  char str[300];

  if(letter == 0) {
    sprintf(expectedAndValue, "\nRegister %d value should be ", regist);
  }
  else {
    sprintf(expectedAndValue, "\nRegister %c value should be ", letter);
  }
  strcat(expectedAndValue, expectedValue);
  if(row > 0 && col > 0) {
    sprintf(expectedAndValue + strlen(expectedAndValue), " for element (%d, %d)", row, col);
  }
  strcat(expectedAndValue, "\nbut it is ");
  switch(getRegisterDataType(regist)) {
    case dtReal34Matrix:
      if(row > 0 && col > 0) {
        int cols = REGISTER_MATRIX_HEADER(regist)->matrixColumns;
        real34ToString(REGISTER_REAL34_MATRIX_ELEMENTS(regist) + (row - 1) * cols + (col - 1), str);
      }
      else {
        strcpy(str, "a real matrix");
      }
      break;

    case dtComplex34Matrix:
      if(row > 0 && col > 0) {
        int cols = REGISTER_MATRIX_HEADER(regist)->matrixColumns;
        const real34_t *re34 = VARIABLE_REAL34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(regist) + (row - 1) * cols + (col - 1));
        const real34_t *im34 = VARIABLE_IMAG34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(regist) + (row - 1) * cols + (col - 1));
        real34ToString(re34, str);
        strcat(expectedAndValue, str);
        if(real34IsNegative(im34)) {
          strcat(expectedAndValue, " -ix");
          real34ToString(im34, str);
          str[0] = ' ';
        }
        else {
          strcat(expectedAndValue, " +ix ");
          real34ToString(im34, str);
        }
      }
      else {
        strcpy(str, "a complex matrix");
      }
      break;
    default:
      printRegisterToString(regist, str);
  }
  strcat(expectedAndValue, str);
  strcat(expectedAndValue, "\n");
}



void expectedAndShouldBeValue(calcRegister_t regist, char letter, char *expectedValue, char *expectedAndValue) {
  expectedAndShouldBeValueForElement(regist, letter, 0, 0, expectedValue, expectedAndValue);
}



bool_t real34AreEqual(real34_t *a, real34_t *b) {
  if( real34IsNaN(a) &&  real34IsNaN(b)) {
    return true;
  }
  if( real34IsNaN(a) && !real34IsNaN(b)) {
    return false;
  }
  if(!real34IsNaN(a) &&  real34IsNaN(b)) {
    return false;
  }

  if( real34IsInfinite(a) && !real34IsInfinite(b)) {
    return false;
  }
  if(!real34IsInfinite(a) &&  real34IsInfinite(b)) {
    return false;
  }
  if( real34IsInfinite(a) &&  real34IsInfinite(b)) {
    if(real34IsPositive(a) && real34IsPositive(b)) {
      return true;
    }
    if(real34IsNegative(a) && real34IsNegative(b)) {
      return true;
    }
    return false;
  }
  if (real34IsZero(a) && real34IsZero(b))
    return real34IsNegative(a) == real34IsNegative(b);

  return real34CompareEqual(a, b);
}



void checkExpectedOutParameter(char *p) {
  calcRegister_t regist = 0;
  char l[2000], r[2000], real[200], imag[200], angMod[200], letter = 0;
  int32_t i;
  angularMode_t am = amDegree;
  real34_t expectedReal34, expectedImag34;

  //printf("  Checking %s\n", p);

  i = 0;
  while(p[i] != '=' && p[i] != 0) {
    i++;
  }
  if(p[i] == 0) {
    printf("\nMalformed out parameter. Missing equal sign, remember that no space is allowed around the equal sign.\n");
    abortTest();
  }

  p[i] = 0;
  strcpy(l, p);
  strcpy(r, p + i + 1);

  if(r[0] == 0) {
    printf("\nMalformed out parameter. Missing value after equal sign, remember that no space is allowed around the equal sign.\n");
    abortTest();
  }

  //Checking a flag
  if(!strncmp(l, "FL_", 3)) {
    if(r[0] != '0' && r[0] != '1' && r[1] != 0) {
      printf("\nMalformed flag checking. The rvalue must be 0 or 1.\n");
      abortTest();
    }

    //Lettered flag
    if(l[3] >= 'A' && l[4] == 0) {
      if(strstr(regNames, l + 3) != NULL) {
        uint16_t flg;

        flg = l[3] == 'T' ? 103 :
              l[3] == 'L' ? 108 :
              l[3] <= 'D' ? l[3] + 39 :
              l[3] <= 'K' ? l[3] + 36 :
                            l[3] + 12;

        if(r[0] == '1') {
          if(!getFlag(flg)) {
            printf("\nFlag %c should be set but it is clear!\n", l[1]);
            abortTest();
          }
        }
        else {
          if(getFlag(flg)) {
            printf("\nFlag %c should be clear but it is set!\n", l[1]);
            abortTest();
          }
        }
      }
      else {
        printf("\nMalformed flag checking. After FL_ there shall be a number from 0 to 111, a lettered, or a system flag.\n");
        abortTest();
      }
    }

    //Numbered flag
    else if(   (l[3] >= '0' && l[3] <= '9' && l[4] == 0)
            || (l[3] >= '0' && l[3] <= '9' && l[4] >= '0' && l[4] <= '9' && l[5] == 0)
            || (l[3] >= '0' && l[3] <= '9' && l[4] >= '0' && l[4] <= '9' && l[5] >= '0' && l[5] <= '9' && l[6] == 0)) {
      uint16_t flg = atoi(l + 3);
      if(flg <= 111) {
        if(r[0] == '1' && !getFlag(flg)) {
          printf("\nFlag %d should be set but it is clear!\n", flg);
          abortTest();
        }
        else if(r[0] == '0' && getFlag(flg)) {
          printf("\nFlag %d should be clear but it is set!\n", flg);
          abortTest();
        }
      }
      else {
        printf("\nMalformed flag checking in line. After FL_ there shall be a number from 0 to 111, a lettered, or a system flag.\n");
        abortTest();
      }
    }

    //System flag
    else {
      if(!strcmp(l+3, "SPCRES")) {
        if(r[0] == '1' && !getSystemFlag(FLAG_SPCRES)) {
          printf("\nSystem flag SPCRES should be set but it is clear!\n");
          abortTest();
        }
        else if(r[0] == '0' && getSystemFlag(FLAG_SPCRES)) {
          printf("\nSystem flag SPCRES should be clear but it is set!\n");
          abortTest();
        }
      }
      else if(!strcmp(l+3, "CPXRES")) {
        if(r[0] == '1' && !getSystemFlag(FLAG_CPXRES)) {
          printf("\nSystem flag CPXRES should be set but it is clear!\n");
          abortTest();
        }
        else if(r[0] == '0' && getSystemFlag(FLAG_CPXRES)) {
          printf("\nSystem flag CPXRES should be clear but it is set!\n");
          abortTest();
        }
      }
      else if(!strcmp(l+3, "CARRY")) {
        if(r[0] == '1' && !getSystemFlag(FLAG_CARRY)) {
          printf("\nSystem flag CARRY should be set but it is clear!\n");
          abortTest();
        }
        else if(r[0] == '0' && getSystemFlag(FLAG_CARRY)) {
          printf("\nSystem flag CARRY should be clear but it is set!\n");
          abortTest();
        }
      }
      else if(!strcmp(l+3, "OVERFL")) {
        if(r[0] == '1' && !getSystemFlag(FLAG_OVERFLOW)) {
          printf("\nSystem flag OVERFL should be set but it is clear!\n");
          abortTest();
        }
        else if(r[0] == '0' && getSystemFlag(FLAG_OVERFLOW)) {
          printf("\nSystem flag OVERFL should be clear but it is set!\n");
          abortTest();
        }
      }
      else if(!strcmp(l+3, "ASLIFT")) {
        if(r[0] == '1' && !getSystemFlag(FLAG_ASLIFT)) {
          printf("\nSystem flag ASLIFT should be set but it is clear!\n");
          abortTest();
        }
        else if(r[0] == '0' && getSystemFlag(FLAG_ASLIFT)) {
          printf("\nSystem flag ASLIFT should be clear but it is set!\n");
          abortTest();
        }
      }
      else if(!strcmp(l+3, "YMD")) {
        if(r[0] == '1' && !getSystemFlag(FLAG_YMD)) {
          printf("\nSystem flag YMD should be set but it is clear!\n");
          abortTest();
        }
        else if(r[0] == '0' && getSystemFlag(FLAG_YMD)) {
          printf("\nSystem flag YMD should be clear but it is set!\n");
          abortTest();
        }
      }
      else if(!strcmp(l+3, "MDY")) {
        if(r[0] == '1' && !getSystemFlag(FLAG_MDY)) {
          printf("\nSystem flag MDY should be set but it is clear!\n");
          abortTest();
        }
        else if(r[0] == '0' && getSystemFlag(FLAG_MDY)) {
          printf("\nSystem flag MDY should be clear but it is set!\n");
          abortTest();
        }
      }
      else if(!strcmp(l+3, "DMY")) {
        if(r[0] == '1' && !getSystemFlag(FLAG_DMY)) {
          printf("\nSystem flag DMY should be set but it is clear!\n");
          abortTest();
        }
        else if(r[0] == '0' && getSystemFlag(FLAG_DMY)) {
          printf("\nSystem flag DMY should be clear but it is set!\n");
          abortTest();
        }
      }
      else {
        printf("\nMalformed numbered flag checking. After FL_ there shall be a number from 0 to 111, a lettered, or a system flag.\n");
        abortTest();
      }
    }
  }

  //Checking integer mode
  else if(strcmp(l, "IM") == 0) {
    if(strcmp(r, "1COMPL") == 0) {
      if(shortIntegerMode != SIM_1COMPL) {
        printf("\nInteger mode should be 1COMPL but it is not!\n");
        abortTest();
      }
    }
    else if(strcmp(r, "2COMPL") == 0) {
      if(shortIntegerMode != SIM_2COMPL) {
        printf("\nInteger mode should be 2COMPL but it is not!\n");
        abortTest();
      }
    }
    else if(strcmp(r, "UNSIGN") == 0) {
      if(shortIntegerMode != SIM_UNSIGN) {
        printf("\nInteger mode should be UNSIGN but it is not!\n");
        abortTest();
      }
    }
    else if(strcmp(r, "SIGNMT") == 0) {
      if(shortIntegerMode != SIM_SIGNMT) {
        printf("\nInteger mode should be SIGNMT but it is not!\n");
        abortTest();
      }
    }
    else {
      printf("\nMalformed integer mode checking. The rvalue must be 1COMPL, 2COMPL, UNSIGN or SIGNMT.\n");
      abortTest();
    }
  }

  //Checking complex mode
  else if(strcmp(l, "CM") == 0) {
    if(strcmp(r, "RECT") == 0) {
      if(getSystemFlag(FLAG_POLAR)) {
        printf("\ncomplex mode should be RECT but it is not!\n");
        abortTest();
      }
    }
    else if(strcmp(r, "POLAR") == 0) {
      if(!getSystemFlag(FLAG_POLAR)) {
        printf("\ncomplex mode should be POLAR but it is not!\n");
        abortTest();
      }
    }
    else {
      printf("\nMalformed complex mode checking. The rvalue must be RECT or POLAR.\n");
      abortTest();
    }
  }

  //Checking angular mode
  else if(strcmp(l, "AM") == 0) {
    if(strcmp(r, "DEG") == 0) {
      if(currentAngularMode != amDegree) {
        printf("\nAngular mode should be DEGREE but it is not!\n");
        abortTest();
      }
    }
    else if(strcmp(r, "DMS") == 0) {
      if(currentAngularMode != amDMS) {
        printf("\nAngular mode should be DMS but it is not!\n");
        abortTest();
      }
    }
    else if(strcmp(r, "RAD") == 0) {
      if(currentAngularMode != amRadian) {
        printf("\nAngular mode should be RAD but it is not!\n");
        abortTest();
      }
    }
    else if(strcmp(r, "MULTPI") == 0) {
      if(currentAngularMode != amMultPi) {
        printf("\nAngular mode should be MULTPI but it is not!\n");
        abortTest();
      }
    }
    else if(strcmp(r, "GRAD") == 0) {
      if(currentAngularMode != amGrad) {
        printf("\nAngular mode should be GRAD but it is not!\n");
        abortTest();
      }
    }
    else {
      printf("\nMalformed angular mode checking. The rvalue must be DEG, DMS, GRAD, RAD or MULTPI.\n");
      abortTest();
    }
  }

  //Checking stack size
  else if(strcmp(l, "SS") == 0) {
    if(strcmp(r, "4") == 0) {
      if(getSystemFlag(FLAG_SSIZE8)) {
        printf("\nStack size should be 4 but it is not!\n");
        abortTest();
      }
    }
    else if(strcmp(r, "8") == 0) {
      if(!getSystemFlag(FLAG_SSIZE8)) {
        printf("\nStack size should be 8 but it is not!\n");
        abortTest();
      }
    }
    else {
      printf("\nMalformed stack size checking. The rvalue must be 4 or 8.\n");
      abortTest();
    }
  }

  //Checking word size
  else if(strcmp(l, "WS") == 0) {
    if(   (r[0] >= '0' && r[0] <= '9' && r[1] == 0)
       || (r[0] >= '0' && r[0] <= '9' && r[1] >= '0' && r[1] <= '9' && r[2] == 0)) {
      uint16_t ws = atoi(r);

      if(ws == 0) {
        ws = 64;
      }
      if(ws <= 64) {
        if(shortIntegerWordSize != ws) {
          printf("\nShort integer word size should be %u but it is %u!\n", ws, shortIntegerWordSize);
          abortTest();
        }
      }
      else {
        printf("\nMalformed word size checking. The rvalue must be from 0 to 64 (0 is the same as 64).\n");
        abortTest();
      }
    }
    else {
      printf("\nMalformed word size checking. The rvalue must be a number from 0 to 64 (0 is the same as 64).\n");
      abortTest();
    }
  }

  //Checking J/G
  else if(strcmp(l, "JG") == 0) {
    if(                 (r[0] >= '0' && r[0] <= '9' &&
        ((r[1] == 0) || (r[1] >= '0' && r[1] <= '9' &&
        ((r[2] == 0) || (r[2] >= '0' && r[2] <= '9' &&
        ((r[3] == 0) || (r[3] >= '0' && r[3] <= '9' &&
        ((r[4] == 0) || (r[4] >= '0' && r[4] <= '9' &&
        ((r[5] == 0) || (r[5] >= '0' && r[5] <= '9' &&
        ((r[6] == 0) || (r[6] >= '0' && r[6] <= '9' &&
        ((r[7] == 0) || (r[7] >= '0' && r[7] <= '9' &&
        ((r[8] == 0) || (r[8] >= '0' && r[8] <= '9' &&
        ((r[9] == 0) ))))))))))))))))))) {
      uint32_t jg = atoi(r);
      if(firstGregorianDay != jg) {
        printf("\nJ/G should be %u but it is %u!\n", jg, firstGregorianDay);
        abortTest();
      }
      firstGregorianDay = atoi(r);
    }
    else {
      printf("\nMalformed J/G setting. The rvalue must be a number.\n");
      abortTest();
    }
  }

  //Checking significant digits
  else if(strcmp(l, "SD") == 0) {
    if(   (r[0] >= '0' && r[0] <= '9' && r[1] == 0)
       || (r[0] >= '0' && r[0] <= '9' && r[1] >= '0' && r[1] <= '9' && r[2] == 0)) {
      uint16_t sd = atoi(r);

      if(sd <= 34) {
        if(significantDigits != sd) {
          printf("\nNumber of significant digits should be %u but it is %u!\n", sd, significantDigits);
          abortTest();
        }
      }
      else {
        printf("\nMalformed significant digits checking. The rvalue must be from 0 to 34 (0 is the same as 34).\n");
        abortTest();
      }
    }
    else {
      printf("\nMalformed significant digits checking. The rvalue must be a number from 0 to 34 (0 is the same as 34).\n");
      abortTest();
    }
  }

  //Checking rounding mode
  else if(strcmp(l, "RMODE") == 0) {
    if(r[0] >= '0' && r[0] <= '9' && r[1] == 0) {
      uint16_t rm = atoi(r);

      if(rm <= 6) {
        if(roundingMode != rm) {
          printf("\nRounding mode should be %u but it is %u!\n", rm, roundingMode);
          abortTest();
        }
      }
      else {
        printf("\nMalformed rounding mode checking. The rvalue must be a number from 0 to 6.\n");
        abortTest();
      }
    }
    else {
      printf("\nMalformed rounding mode checking. The rvalue must be a number from 0 to 6.\n");
      abortTest();
    }
  }

  //Checking error code
  else if(strcmp(l, "EC") == 0) {
    if(   (r[0] >= '0' && r[0] <= '9' && r[1] == 0)
       || (r[0] >= '0' && r[0] <= '9' && r[1] >= '0' && r[1] <= '9' && r[2] == 0)) {
      uint16_t ec = atoi(r);

      if(ec <= NUMBER_OF_ERROR_CODES) {
        if(lastErrorCode != ec) {
          printf("\nLast error code should be %u (%s) but it is %u (%s)!\n", ec, errorMessages[ec], lastErrorCode, errorMessages[lastErrorCode]);
          abortTest();
        }
      }
      else {
        printf("\nMalformed error code checking. The rvalue must be a number from 0 to 28.\n");
        abortTest();
      }
    }
    else {
      printf("\nMalformed error code checking. The rvalue must be a number from 0 to 28.\n");
      abortTest();
    }
  }


  //Setting a variable
  else if(l[0] == 'V') {

    //Variable V256-V3000
    if(   (l[1] >= '0' && l[1] <= '9' && l[2] >= '0' && l[2] <= '9' && l[3] >= '0' && l[3] <= '9' && l[4] == 0)
       || (l[1] >= '0' && l[1] <= '9' && l[2] >= '0' && l[2] <= '9' && l[3] >= '0' && l[3] <= '9' && l[4] >= '0' && l[4] <= '9' && l[5] == 0)) {
      regist = atoi(l + 1);
      if(regist < 256 || regist > 3000) {
        printf("\nMalformed variable setting. The number after V shall be from 256 to 3000.\n");
        abortTest();
      }
    }

    else {
      printf("\nMalformed variable setting. After V there should be a number from 256 to 3000.\n");
      abortTest();
    }
    goto var2;
  }


  //Checking a register
  else if(l[0] == 'R') {

    //Lettered register
    if(l[1] >= 'A' && l[2] == 0) {
      const char *p = strchr(regNames, l[1]);
      if(p != NULL) {
        letter = l[1];
        regist = REGISTER_X + (p - regNames);
      }
      else {
        printf("\nMalformed lettered register setting. The letter after R is not a lettered register (%s).\n", regNames);
        abortTest();
      }
    }

    //Numbered register
    else if(   (l[1] >= '0' && l[1] <= '9' && l[2] == 0)
            || (l[1] >= '0' && l[1] <= '9' && l[2] >= '0' && l[2] <= '9' && l[3] == 0)
            || (l[1] >= '0' && l[1] <= '9' && l[2] >= '0' && l[2] <= '9' && l[3] >= '0' && l[3] <= '9' && l[4] == 0)) {
      regist = atoi(l + 1);
      if(regist > LAST_SPARE_REGISTER || regist < 0) {
        printf("\nMalformed numbered register checking. The number after R shall be a number from 0 to 111.\n");
        abortTest();
      }
      letter = 0;
    }

    else {
      printf("\nMalformed register checking. After R there shall be a number from 0 to %d or a lettered register.\n", LAST_GLOBAL_REGISTER);
      abortTest();
    }
var2:
    // find the : separating the data type and the value
    i = 0;
    while(r[i] != ':' && r[i] != 0) {
      i++;
    }
    if(r[i] == 0) {
      printf("\nMalformed register value. Missing colon between data type and value.\n");
      abortTest();
    }

    // separating the data type and the value
    r[i] = 0;
    strcpy(l, r);
    xcopy(r, r + i + 1, strlen(r + i + 1) + 1);

    if(strcmp(l, "LONI") == 0) {
      longInteger_t expectedLongInteger, registerLongInteger;

      // remove beginning and ending " and removing leading spaces
      xcopy(r, r + 1, strlen(r));
      while(r[0] == ' ') {
        xcopy(r, r + 1, strlen(r));
      }
      r[strlen(r) - 1] = 0;

      longIntegerInit(expectedLongInteger);
      stringToLongInteger(r, 10, expectedLongInteger);
      checkRegisterType(regist, letter, dtLongInteger, longIntegerSignTag(expectedLongInteger));
      convertLongIntegerRegisterToLongInteger(regist, registerLongInteger);
      if(longIntegerCompare(expectedLongInteger, registerLongInteger) != 0) {
        wrongRegisterValue(regist, letter, r);
      }

      longIntegerFree(expectedLongInteger);
      longIntegerFree(registerLongInteger);
    }
    else if(strcmp(l, "REAL") == 0) {
      // find the : separating the real value from the angular mode
      i = 0;
      while(r[i] != ':' && r[i] != 0) {
        i++;
      }
      if(r[i] == 0) {
        strcat(r, ":NONE");
      }

      // separate real value and angular mode
      r[i] = 0;
      strcpy(angMod, r + i + 1);

           if(strcmp(angMod, "DEG"   ) == 0) am = amDegree;
      else if(strcmp(angMod, "DMS"   ) == 0) am = amDMS;
      else if(strcmp(angMod, "RAD"   ) == 0) am = amRadian;
      else if(strcmp(angMod, "MULTPI") == 0) am = amMultPi;
      else if(strcmp(angMod, "GRAD"  ) == 0) am = amGrad;
      else if(strcmp(angMod, "NONE"  ) == 0) am = amNone;
      else {
        printf("\nMalformed register real%d angular mode. Unknown angular mode after real value.\n", strcmp(l, "RE16") == 0 ? 16 : 34);
        abortTest();
      }


      // remove beginning and ending " and removing leading spaces
      xcopy(r, r + 1, strlen(r));
      while(r[0] == ' ') {
        xcopy(r, r + 1, strlen(r));
      }
      r[strlen(r) - 1] = 0;

      // replace , with .
      for(i=0; i<(int)strlen(r); i++) {
        if(r[i] == ',') {
          r[i] = '.';
        }
      }

      checkRegisterType(regist, letter, dtReal34, am);
      stringToReal34(r, &expectedReal34);
      if(!real34AreEqual(REGISTER_REAL34_DATA(regist), &expectedReal34)) {
        expectedAndShouldBeValue(regist, letter, r, registerExpectedAndValue);
        if(relativeErrorReal34(&expectedReal34, REGISTER_REAL34_DATA(regist), "real", regist, letter) == RE_INACCURATE) {
          wrongRegisterValue(regist, letter, r);
        }
      }
    }
    else if(strcmp(l, "STRI") == 0) {
      checkRegisterType(regist, letter, dtString, amNone);
      getString(r + 1);

      char *expected, *is;
      if(stringByteLength(r + 1) != stringByteLength(REGISTER_STRING_DATA(regist))) {
        char stringUtf8[1200];
        stringToUtf8(REGISTER_STRING_DATA(regist), (uint8_t *)stringUtf8);
        printf("\nThe 2 strings are not of the same size.\nRegister string: %s\n", stringUtf8);
        for(i=0, is=REGISTER_STRING_DATA(regist); i<=stringByteLength(REGISTER_STRING_DATA(regist)); i++, is++) {
          printf("%02x ", (unsigned char)*is);
        }
        stringToUtf8(r+1, (uint8_t *)stringUtf8);
        printf("\nExpected string: %s\n", stringUtf8);
        for(i=1; i<=stringByteLength(r); i++) {
          printf("%02x ", (unsigned char)r[i]);
        }
        printf("\n");
        abortTest();
      }

      for(i=stringByteLength(r + 1), expected=r + 1, is=REGISTER_STRING_DATA(regist); i>0; i--, expected++, is++) {
        //printf("%c %02x   %c %02x\n", *expected, (unsigned char)*expected, *is, (unsigned char)*is);
        if(*expected != *is) {
          printf("\nThe 2 strings are different.\nRegister string: ");
          for(i=0, is=REGISTER_STRING_DATA(regist); i<=stringByteLength(REGISTER_STRING_DATA(regist)); i++, is++) {
            printf("%02x ", (unsigned char)*is);
          }
          printf("\nExpected string: ");
          for(i=1; i<=stringByteLength(r); i++) {
            printf("%02x ", (unsigned char)r[i]);
          }
          printf("\n");
          abortTest();
          break;
        }
      }
    }
    else if(strcmp(l, "SHOI") == 0) {
      // find the # separating the value from the base
      i = 0;
      while(r[i] != '#' && r[i] != 0) {
        i++;
      }
      if(r[i] == 0) {
        printf("\nMalformed register short integer value. Missing # between value and base.\n");
        abortTest();
      }

      // remove beginning and ending " and removing leading spaces
      xcopy(r, r + 1, strlen(r));
      while(r[0] == ' ') {
        xcopy(r, r + 1, strlen(r));
      }
      r[strlen(r) - 1] = 0;

      // Convert string to upper case
      for(i=0; r[i]!=0; i++) {
        if('a' <= r[i] && r[i] <= 'z') {
          r[i] -= 32;
        }
      }

      strToShortInteger(r, TEMP_REGISTER_1);
      checkRegisterType(regist, letter, dtShortInteger, getRegisterTag(TEMP_REGISTER_1));
      if(*REGISTER_SHORT_INTEGER_DATA(TEMP_REGISTER_1) != *REGISTER_SHORT_INTEGER_DATA(regist)) {
        wrongRegisterValue(regist, letter, r);
      }
    }
    else if(strcmp(l, "CPLX") == 0) {
      checkRegisterType(regist, letter, dtComplex34, amNone);

      // remove beginning and ending " and removing leading spaces
      xcopy(r, r + 1, strlen(r));
      while(r[0] == ' ') {
        xcopy(r, r + 1, strlen(r));
      }
      r[strlen(r) - 1] = 0;

      // find the i separating the real and imagynary part
      i = 0;
      while(r[i] != 'i' && r[i] != 0) {
        i++;
      }
      if(r[i] == 0) {
        printf("\nMalformed register complex34 value. Missing i between real and imaginary part.\n");
        abortTest();
      }

      // separate real and imaginary part
      r[i] = 0;
      strcpy(real, r);
      strcpy(imag, r + i + 1);

      // remove leading spaces
      while(imag[0] == ' ') {
        xcopy(imag, imag + 1, strlen(imag));
      }

      // removing trailing spaces from real part
      while(real[strlen(real) - 1] == ' ') {
        real[strlen(real) - 1] = 0;
      }

      // removing trailing spaces from imaginary part
      while(imag[strlen(imag) - 1] == ' ') {
        imag[strlen(imag) - 1] = 0;
      }

      // replace , with . in the real part
      for(i=0; i<(int)strlen(real); i++) {
        if(real[i] == ',') {
          real[i] = '.';
        }
      }

      // replace , with . in the imaginary part
      for(i=0; i<(int)strlen(imag); i++) {
        if(imag[i] == ',') {
          imag[i] = '.';
        }
      }

      stringToReal34(real, &expectedReal34);
      stringToReal34(imag, &expectedImag34);
      if(!real34AreEqual(REGISTER_REAL34_DATA(regist), &expectedReal34)) {
        if(imag[0] == '-') {
          strcat(r, " -ix ");
          strcat(r, imag + 1);
        }
        else {
          strcat(r, " +ix ");
          strcat(r, imag);
        }
        expectedAndShouldBeValue(regist, letter, r, registerExpectedAndValue);
        if(relativeErrorReal34(&expectedReal34, REGISTER_REAL34_DATA(regist), "real", regist, letter) == RE_INACCURATE) {
          wrongRegisterValue(regist, letter, r);
        }
      }
      else if(!real34AreEqual(REGISTER_IMAG34_DATA(regist), &expectedImag34)) {
        if(imag[0] == '-') {
          strcat(r, " -ix ");
          strcat(r, imag + 1);
        }
        else {
          strcat(r, " +ix ");
          strcat(r, imag);
        }
        expectedAndShouldBeValue(regist, letter, r, registerExpectedAndValue);
        if(relativeErrorReal34(&expectedImag34, REGISTER_IMAG34_DATA(regist), "imaginary", regist, letter) == RE_INACCURATE) {
          wrongRegisterValue(regist, letter, r);
        }
      }
    }
    else if(strcmp(l, "TIME") == 0) {
      int32_t k = 0;
      bool_t isHms = false;

      // find the : separating hours and minutes
      i = 0;
      while(r[i] != ':' && r[i] != 0) {
        i++;
      }
      if(r[i] == ':') { // Input by HMS
        isHms = true;
        k = i;
        r[i] = '.';
        do {
          ++k;
          if((r[k] != ':') && (r[k] != '.') && (r[k] != ',')) {
            r[++i] = r[k];
          }
        } while(r[k] != 0);
      }
      am = amNone;

      // remove beginning and ending " and removing leading spaces
      xcopy(r, r + 1, strlen(r));
      while(r[0] == ' ') {
        xcopy(r, r + 1, strlen(r));
      }
      r[strlen(r) - 1] = 0;

      // replace , with .
      for(i=0; i<(int)strlen(r); i++) {
        if(r[i] == ',') {
          r[i] = '.';
        }
      }

      checkRegisterType(regist, letter, dtTime, amNone);
      stringToReal34(r, &expectedReal34);
      if(isHms) {
        hmmssToSeconds(&expectedReal34, &expectedReal34);
      }
      if(!real34AreEqual(REGISTER_REAL34_DATA(regist), &expectedReal34)) {
        expectedAndShouldBeValue(regist, letter, r, registerExpectedAndValue);
        if(relativeErrorReal34(&expectedReal34, REGISTER_REAL34_DATA(regist), "time", regist, letter) == RE_INACCURATE) {
          wrongRegisterValue(regist, letter, r);
        }
      }
    }
    else if(strcmp(l, "DATE") == 0) {
      // remove beginning and ending " and removing leading spaces
      xcopy(r, r + 1, strlen(r));
      while(r[0] == ' ') {
        xcopy(r, r + 1, strlen(r));
      }
      r[strlen(r) - 1] = 0;

      // replace , with .
      for(i=0; i<(int)strlen(r); i++) {
        if(r[i] == ',') {
          r[i] = '.';
        }
      }

      checkRegisterType(regist, letter, dtDate, amNone);
      reallocateRegister(TEMP_REGISTER_1, dtReal34, 0, amNone);
      stringToReal34(r, REGISTER_REAL34_DATA(TEMP_REGISTER_1));
      convertReal34RegisterToDateRegister(TEMP_REGISTER_1, TEMP_REGISTER_1, !YYSystem);
      real34Copy(REGISTER_REAL34_DATA(TEMP_REGISTER_1), &expectedReal34);
      if(!real34AreEqual(REGISTER_REAL34_DATA(regist), &expectedReal34)) {
        expectedAndShouldBeValue(regist, letter, r, registerExpectedAndValue);
        if(relativeErrorReal34(&expectedReal34, REGISTER_REAL34_DATA(regist), "date", regist, letter) == RE_INACCURATE) {
          wrongRegisterValue(regist, letter, r);
        }
      }
    }
    else if(strcmp(l, "REMA") == 0) {
      // remove beginning and ending " and removing leading spaces
      xcopy(r, r + 1, strlen(r));
      while(r[0] == ' ') {
        xcopy(r, r + 1, strlen(r));
      }
      r[strlen(r) - 1] = 0;

      // 'M'
      if(r[0] == 'M') {
        int rows, cols;
        xcopy(r, r + 1, strlen(r));
        while(r[0] == ' ') {
          xcopy(r, r + 1, strlen(r));
        }
        // rows
        i = 0;
        while(r[i] != ',' && r[i] != 0) {
          i++;
        }
        if(r[i] == ',') {
          r[i] = 0;
          rows = atoi(r);
          xcopy(r, r + i + 1, strlen(r + i + 1) + 1);
          while(r[0] == ' ') {
            xcopy(r, r + 1, strlen(r));
          }
          // cols
          i = 0;
          while(r[i] != '[' && r[i] != 0) {
            i++;
          }
          if(r[i] == '[') {
            real34_t *x1 = NULL;
            bool_t isCheckingEigenvectors;
            r[i] = 0;
            cols = atoi(r);
            isCheckingEigenvectors = (funcType == FUNC_NOPARAM) && (funcToTest == fnEigenvectors) && (regist == REGISTER_X) && (rows == cols);
            xcopy(r, r + i + 1, strlen(r + i + 1) + 1);
            if(isCheckingEigenvectors) {
              x1 = malloc(REAL34_SIZE_IN_BYTES * cols);
              for(int col = 0; col < cols; ++col) {
                real34Zero(x1 + col);
              }
            }
            while(r[0] == ' ') {
              xcopy(r, r + 1, strlen(r));
            }
            checkRegisterType(regist, letter, dtReal34Matrix, amNone);
            if(getRegisterDataType(regist) != dtReal34Matrix) {
              // nothing to do
            }
            else if((REGISTER_MATRIX_HEADER(regist)->matrixRows != rows) || (REGISTER_MATRIX_HEADER(regist)->matrixColumns != cols)) {
              wrongRegisterMatrixSize(regist, letter, rows, cols);
            }
            else {
              // elements
              for(int element = 0; element < rows * cols; ++element) {
                char valTxt[300];
                i = 0;
                while(r[i] != ',' && r[i] != ']' && r[i] != 0) {
                  i++;
                }
                bool_t lastElement = (r[i] != ',');
                r[i] = 0;
                if(isCheckingEigenvectors && real34IsZero(x1 + element % cols)) {
                  stringToReal34(r, &expectedReal34);
                  if(!real34IsZero(&expectedReal34)) {
                    real34Divide(&expectedReal34, REGISTER_REAL34_MATRIX_ELEMENTS(regist) + element, x1 + element % cols);
                  }
                }
                else if(strcmp(r, "any") != 0 && strcmp(r, "?") != 0) {
                  stringToReal34(r, &expectedReal34);
                  if(isCheckingEigenvectors) {
                    real34Multiply(&expectedReal34, x1 + element % cols, &expectedReal34);
                    real34ToString(&expectedReal34, valTxt);
                  }
                  if(!real34AreEqual(REGISTER_REAL34_MATRIX_ELEMENTS(regist) + element, &expectedReal34)) {
                    expectedAndShouldBeValueForElement(regist, letter, element / cols + 1, element % cols + 1, isCheckingEigenvectors ? valTxt : r, registerExpectedAndValue);
                    if(relativeErrorReal34(&expectedReal34, REGISTER_REAL34_MATRIX_ELEMENTS(regist) + element, "real", regist, letter) == RE_INACCURATE) {
                      wrongElementValue(regist, letter, element / cols + 1, element % cols + 1, isCheckingEigenvectors ? valTxt : r);
                    }
                  }
                }
                if(lastElement) {
                  if(element < (rows * cols - 1)) {
                    printf("\nmalformed register value. Not enough elements\n");
                    abortTest();
                  }
                  break;
                }
                if(element >= (rows * cols - 1)) {
                  printf("\nmalformed register value. Too many elements\n");
                  abortTest();
                  break;
                }
                xcopy(r, r + i + 1, strlen(r + i + 1) + 1);
                while(r[0] == ' ') {
                  xcopy(r, r + 1, strlen(r));
                }
              }
            }
            if(isCheckingEigenvectors) {
              free(x1);
            }
          }
          else {
            printf("\nmalformed register value. Missing left bracket after number of columns\n");
            abortTest();
          }
        }
        else {
          printf("\nmalformed register value. Missing comma between number of rows and of columns\n");
          abortTest();
        }
      }
      else {
        printf("\nmalformed register value. Value does not begin with 'M'\n");
        abortTest();
      }
    }
    else if(strcmp(l, "CXMA") == 0) {
      // remove beginning and ending " and removing leading spaces
      xcopy(r, r + 1, strlen(r));
      while(r[0] == ' ') {
        xcopy(r, r + 1, strlen(r));
      }
      r[strlen(r) - 1] = 0;

      // 'M'
      if(r[0] == 'M') {
        int rows, cols;
        xcopy(r, r + 1, strlen(r));
        while(r[0] == ' ') {
          xcopy(r, r + 1, strlen(r));
        }
        // rows
        i = 0;
        while(r[i] != ',' && r[i] != 0) {
          i++;
        }
        if(r[i] == ',') {
          r[i] = 0;
          rows = atoi(r);
          xcopy(r, r + i + 1, strlen(r + i + 1) + 1);
          while(r[0] == ' ') {
            xcopy(r, r + 1, strlen(r));
          }
          // cols
          i = 0;
          while(r[i] != '[' && r[i] != 0) {
            i++;
          }
          if(r[i] == '[') {
            real_t *xr1 = NULL, *xi1 = NULL;
            bool_t isCheckingEigenvectors;
            bool_t *xf1 = NULL;
            r[i] = 0;
            cols = atoi(r);
            isCheckingEigenvectors = (funcType == FUNC_NOPARAM) && (funcToTest == fnEigenvectors) && (regist == REGISTER_X) && (rows == cols);
            xcopy(r, r + i + 1, strlen(r + i + 1) + 1);
            if(isCheckingEigenvectors) {
              xr1 = malloc(REAL_SIZE_IN_BYTES * cols);
              xi1 = malloc(REAL_SIZE_IN_BYTES * cols);
              xf1 = malloc(sizeof(bool_t) * cols);
              for(int col = 0; col < cols; ++col) {
                realZero(xr1 + col);
                realZero(xi1 + col);
                xf1[col] = false;
              }
            }
            while(r[0] == ' ') {
              xcopy(r, r + 1, strlen(r));
            }
            checkRegisterType(regist, letter, dtComplex34Matrix, amNone);
            if(getRegisterDataType(regist) != dtComplex34Matrix) {
              // nothing to do
            }
            else if((REGISTER_MATRIX_HEADER(regist)->matrixRows != rows) || (REGISTER_MATRIX_HEADER(regist)->matrixColumns != cols)) {
              wrongRegisterMatrixSize(regist, letter, rows, cols);
            }
            else {
              // elements
              for(int element = 0; element < rows * cols; ++element) {
                bool_t lastElement = false;
                if(isCheckingEigenvectors && element < cols) {
                  real_t xr, xi;
                  for(int row = 0; row < rows; ++row) {
                    real34ToReal(VARIABLE_REAL34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(regist) + element + row * cols), &xr);
                    real34ToReal(VARIABLE_IMAG34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(regist) + element + row * cols), &xi);
                    mulComplexComplex(&xr, &xi, &xr, &xi, &xr, &xi, &ctxtReal39);
                    realAdd(&xr, xr1 + element % cols, xr1 + element % cols, &ctxtReal39);
                    realAdd(&xi, xi1 + element % cols, xi1 + element % cols, &ctxtReal39);
                  }
                  sqrtComplex(xr1 + element % cols, xi1 + element % cols, xr1 + element % cols, xi1 + element % cols, &ctxtReal39);
                }
                // real part
                i = 0;
                while(r[i] != 'i' && r[i] != ',' && r[i] != ']' && r[i] != 0) {
                  i++;
                }
                bool_t imagFollows = (r[i] == 'i');
                lastElement = (r[i] != 'i' && r[i] != ',');
                r[i] = 0;
                strcpy(real, r);

                // removing trailing spaces from real part
                while(real[strlen(real) - 1] == ' ') {
                  real[strlen(real) - 1] = 0;
                }

                if((strcmp(real, "any") != 0 && strcmp(real, "?") != 0) || imagFollows) {
                  real_t expectedReal, expectedImag;
                  stringToReal34(real, &expectedReal34);
                  stringToReal(real, &expectedReal, &ctxtReal39);
                  // imaginary part
                  if(imagFollows) {
                    xcopy(r, r + i + 1, strlen(r + i + 1) + 1);
                    while(r[0] == ' ') {
                      xcopy(r, r + 1, strlen(r));
                    }
                    i = 0;
                    while(r[i] != ',' && r[i] != ']' && r[i] != 0) {
                      i++;
                    }
                    lastElement = (r[i] != ',');
                    r[i] = 0;
                    strcpy(imag, r);

                    // removing trailing spaces from imaginary part
                    while(imag[strlen(imag) - 1] == ' ') {
                      imag[strlen(imag) - 1] = 0;
                    }

                    stringToReal34(imag, &expectedImag34);
                    stringToReal(imag, &expectedImag, &ctxtReal39);
                  }
                  else {
                    strcpy(imag, "0");
                    real34Zero(&expectedImag34);
                    realZero(&expectedImag);
                  }

                  if(isCheckingEigenvectors && (!realIsZero(xr1 + element % cols) || !realIsZero(xi1 + element % cols))) {
                    real_t er, ei, tmpe, tol;
                    real34ToReal(const34_1e_32, &tol);

                    real34ToReal(VARIABLE_REAL34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(regist) + element), &er);
                    real34ToReal(VARIABLE_IMAG34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(regist) + element), &ei);

                    // check for possible real or pure imaginary
                    WP34S_Atan2(&ei, &er, &tmpe, &ctxtReal39); // arctangent: check for possible pure imaginary
                    realSetPositiveSign(&tmpe);
                    if(WP34S_RelativeError(&tmpe, const_piOn2, &tol, &ctxtReal39)) {
                      realZero(&er); // possible pure imaginary
                    }
                    WP34S_Atan2(&er, &ei, &tmpe, &ctxtReal39); // arccotangent: check for possible real
                    realSetPositiveSign(&tmpe);
                    if(WP34S_RelativeError(&tmpe, const_piOn2, &tol, &ctxtReal39)) {
                      realZero(&ei); // possible real
                    }

                    realToReal34(&er, VARIABLE_REAL34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(regist) + element));
                    realToReal34(&ei, VARIABLE_IMAG34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(regist) + element));

                    realCopy(&expectedReal, &er);
                    realCopy(&expectedImag, &ei);
                    mulComplexComplex(&er, &ei, xr1 + element % cols, xi1 + element % cols, &er, &ei, &ctxtReal39);

                    // check for possible real or pure imaginary
                    WP34S_Atan2(&ei, &er, &tmpe, &ctxtReal39); // arctangent: check for possible pure imaginary
                    realSetPositiveSign(&tmpe);
                    if(WP34S_RelativeError(&tmpe, const_piOn2, &tol, &ctxtReal39)) {
                      realZero(&er); // possible pure imaginary
                    }
                    WP34S_Atan2(&er, &ei, &tmpe, &ctxtReal39); // arccotangent: check for possible real
                    realSetPositiveSign(&tmpe);
                    if(WP34S_RelativeError(&tmpe, const_piOn2, &tol, &ctxtReal39)) {
                      realZero(&ei); // possible real
                    }

                    if(!(xf1[element % cols])) {
                      const real34_t *rr = VARIABLE_REAL34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(regist) + element);
                      const real34_t *ii = VARIABLE_IMAG34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(regist) + element);
                      if(!real34IsZero(rr)) {
                        if((real34IsPositive(rr) && realIsNegative(&er)) || (real34IsNegative(rr) && realIsPositive(&er))) {
                          realChangeSign(xr1 + element % cols);
                          realChangeSign(xi1 + element % cols);
                          realChangeSign(&er);
                          realChangeSign(&ei);
                        }
                        xf1[element % cols] = true;
                      }
                      else if(!real34IsZero(ii)) {
                        if((real34IsPositive(ii) && realIsNegative(&ei)) || (real34IsNegative(ii) && realIsPositive(&ei))) {
                          realChangeSign(xi1 + element % cols);
                          realChangeSign(&ei);
                        }
                        xf1[element % cols] = true;
                      }
                    }

                    realToReal34(&er, &expectedReal34);
                    realToReal34(&ei, &expectedImag34);
                    realToString(&er, real);
                    realToString(&ei, imag);
                  }

                  if(!real34AreEqual(VARIABLE_REAL34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(regist) + element), &expectedReal34)) {
                    char str[404];
                    sprintf(str, "%s %cix %s", real, imag[0] == '-' ? '-' : '+', imag + (imag[0] == '-' ? 1 : 0));
                    expectedAndShouldBeValueForElement(regist, letter, element / cols + 1, element % cols + 1, str, registerExpectedAndValue);
                    if(relativeErrorReal34(&expectedReal34, VARIABLE_REAL34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(regist) + element), "real", regist, letter) == RE_INACCURATE) {
                      wrongElementValue(regist, letter, element / cols + 1, element % cols + 1, str);
                    }
                  }
                  else if(!real34AreEqual(VARIABLE_IMAG34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(regist) + element), &expectedImag34)) {
                    char str[404];
                    sprintf(str, "%s %cix %s", real, imag[0] == '-' ? '-' : '+', imag + (imag[0] == '-' ? 1 : 0));
                    expectedAndShouldBeValueForElement(regist, letter, element / cols + 1, element % cols + 1, str, registerExpectedAndValue);
                    if(relativeErrorReal34(&expectedImag34, VARIABLE_IMAG34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(regist) + element), "imaginary", regist, letter) == RE_INACCURATE) {
                      wrongElementValue(regist, letter, element / cols + 1, element % cols + 1, str);
                    }
                  }
                }

                if(lastElement) {
                  if(element < (rows * cols - 1)) {
                    printf("\nmalformed register value. Not enough elements\n");
                    abortTest();
                  }
                  break;
                }
                if(element >= (rows * cols - 1)) {
                  printf("\nmalformed register value. Too many elements\n");
                  abortTest();
                  break;
                }
                xcopy(r, r + i + 1, strlen(r + i + 1) + 1);
                while(r[0] == ' ') {
                  xcopy(r, r + 1, strlen(r));
                }
              }
            }
            if(isCheckingEigenvectors) {
              free(xr1);
              free(xi1);
              free(xf1);
            }
          }
          else {
            printf("\nmalformed register value. Missing left bracket after number of columns\n");
            abortTest();
          }
        }
        else {
          printf("\nmalformed register value. Missing comma between number of rows and of columns\n");
          abortTest();
        }
      }
      else {
        printf("\nmalformed register value. Value does not begin with 'M'\n");
        abortTest();
      }
    }
    else {
      printf("\nmalformed register value. Unknown data type %s for register %s\n", l, p+1);
      abortTest();
    }
  }

  else {
    printf("\nUnknown checking %s\n", l);
    abortTest();
  }
}



void outParameters(char *token) {
  char parameter[2000];
  int32_t lg;

  strReplace(token, "inf", "9e9999");

  while(*token == ' ') {
    token++;
  }
  while(*token != 0) {
    int32_t index = 0;
    while(*token != ' ' && *token != 0) {
      if(*token == '"') { // Inside a string
        lg = endOfString(token) - token;
        strncpy(parameter + index, token, lg--);
        index += lg;
        token += lg;
      }
      parameter[index++] = *(token++);
    }
    parameter[index] = 0;

    //printf("  Check %s\n", parameter);
    checkExpectedOutParameter(parameter);

    while(*token == ' ') {
      token++;
    }
  }
}



void callFunction(void) {
  lastErrorCode = 0;

  switch(funcType) {
    case FUNC_NOPARAM:
      if((indexOfItems[functionIndex].status & US_STATUS) == US_ENABLED) {
        saveForUndo();
      }
      else if((indexOfItems[functionIndex].status & US_STATUS) == US_CANCEL) {
        thereIsSomethingToUndo = false;
      }

      funcToTest(functionParameter);
      break;

    case FUNC_CVT:
      funcCvt(NOPARAM);
      break;

    default: ;
  }

  if(lastErrorCode == 0) {
    if(functionIndex < LAST_ITEM) {
      if((indexOfItems[functionIndex].status & SLS_STATUS) == SLS_DISABLED) {
        clearSystemFlag(FLAG_ASLIFT);
      }
      else if((indexOfItems[functionIndex].status & SLS_STATUS) == SLS_ENABLED) {
        setSystemFlag(FLAG_ASLIFT);
      }
    }
  }
}



void functionToCall(char *functionName) {
  int32_t function;

  functionParameter = NOPARAM;
  char *openParenthesis = strchr(functionName, '(');
  char *closeParenthesis = strchr(functionName, ')');
  if((openParenthesis && !closeParenthesis) || (!openParenthesis && closeParenthesis)) {
    printf("\nParameter parenthesis do not match!\n");
    abortTest();
  }
  else if(openParenthesis && closeParenthesis) {
    *closeParenthesis = 0;
    *(openParenthesis++) = 0;
    functionParameter = atoi(openParenthesis);
  }

  function = 0;
  while(funcTestNoParam[function].name[0] != 0 && strcmp(funcTestNoParam[function].name, functionName) != 0) {
    function++;
  }

  if(funcTestNoParam[function].name[0] != 0) {
    funcToTest = funcTestNoParam[function].func;
    funcType = FUNC_NOPARAM;

    if(funcToTest == runPgm) {
      functionIndex = ITM_XEQ;
    }
    else {
      for(functionIndex=1; functionIndex<=LAST_ITEM; functionIndex++) {
        if(indexOfItems[functionIndex].func == funcToTest) {
          break;
        }
      }
    }

    if(functionIndex >= LAST_ITEM) {
      printf("\nThe function %s must be somewhere in the indexOfItems array!\n", functionName);
      abortTest();
    }

    //printf("%s=%d\n", functionName, functionIndex);
    return;
  }

  printf("\nCannot find the function to test: check spelling of the function name and remember the name is case sensitive\n");
  abortTest();
}



void abortTest(void) {
  numTestsTotal--;
  failedTests++;
  printf("\n%s\n", lastInParameters);
  printf("%s\n", line);
  printf("in file %s line %d\n-------------------------------------------------------------------------------------------------------------------------------------\n", fileName, lineNumber);
  //exit(-1);
}



void standardizeLine(void) {
  char *location;

  // trim comments
  location = strstr(line, ";");
  if(location != NULL) {
    *location = 0;
  }

  // trim ending LF
  location = strstr(line, "\n");
  if(location != NULL) {
    *location = 0;
  }

  // trim ending CR
  location = strstr(line, "\r");
  if(location != NULL) {
    *location = 0;
  }

  // trim ending LF
  location = strstr(line, "\n");
  if(location != NULL) {
    *location = 0;
  }

  // Change tabs in spaces
  for(int i=strlen(line)-1; i>0; i--) {
    if(line[i] == '\t') {
      line[i] = ' ';
    }
  }

  // Trim ending spaces
  for(int i=strlen(line)-1; i>0; i--) {
    if(line[i] == ' ') {
      line[i] = 0;
    }
    else {
      break;
    }
  }

  // Trim beginning spaces
  while(line[0] == ' ') {
    xcopy(line, line + 1, strlen(line));
  }

  // 2 spaces ==> 1 space
  for(uint32_t i=0; i<strlen(line); i++) {
    if(line[i] == '"') {
      i = endOfString(line + i) - line;
    }
    if(line[i] == ' ' && line[i + 1] == ' ') {
      xcopy(line + i, line + i + 1, strlen(line + i) - 1);
      line[strlen(line) - 1] = 0;
      i--;
    }
  }
}


static bool_t timerOperation = false;
static bool_t timedFunction = false;
static time_t startTime = 0;  // module-level static variable
void startTimer(void) {
    startTime = time(NULL);
}

void stopTimerAndPrint(void) {
    if (startTime == 0) {
        printf("Timer was not started.\n");
        return;
    }
    time_t endTime = time(NULL);
    double elapsed = difftime(endTime, startTime);
    if(elapsed > 1)
      printf("\n -- Processing time > 1 second: %d s\n", (int)elapsed);
}



void processLine(void) {
  // convert to upper case
  int32_t lg = strlen(line);
  for(int i=0; i<lg; i++) {
    if(line[i] == '"') {
      i = endOfString(line + i) - line;
    }

    if('a' <= line[i] && line[i] <= 'z') {
      line[i] -= 32;
    }
    if(i >= 5 && (strncmp(line, "FUNC: ", 6) == 0 || strncmp(line, "DESC: ", 6) == 0)) {
      break;
    }
    if(i >= 12 && (strncmp(line, "DESC_PREFIX: ", 13) == 0 || strncmp(line, "DESC_SUFFIX: ", 13) == 0)) {
      break;
    }
  }


  if(strncmp(line, "TIMER: ", 7) == 0) {
    printf("\n%s", line);
    timedFunction = true;
  }

  else if(strncmp(line, "TIMERON:", 8) == 0) {
    timerOperation = true;
  }

  else if(strncmp(line, "TIMEROFF:", 9) == 0) {
    timerOperation = false;
  }

  else if(strncmp(line, "IN: ", 4) == 0) {
    //printf("%s\n", line);
    strcpy(lastInParameters, line);
    inParameters(line + 4);
  }

  else if(strncmp(line, "DESC: ", 6) == 0) {
    //printf("%s\n", line);
    strcpy(testCaseName, line + 6);
  }

  else if(strncmp(line, "DESC_PREFIX: ", 13) == 0) {
    //printf("%s\n", line);
    strcpy(testCasePrefix, line + 13);
  }

  else if(strncmp(line, "DESC_SUFFIX: ", 13) == 0) {
    //printf("%s\n", line);
    strcpy(testCaseSuffix, line + 13);
  }

  else if(strncmp(line, "FUNC: ", 6) == 0) {
    //printf("%s\n", line);
    functionToCall(line + 6);
  }

  else if(strncmp(line, "OUT: ", 5) == 0) {
    //printf("%s\n", line);
    if(timedFunction && timerOperation) startTimer();
    callFunction();
    if(timedFunction && timerOperation) {
      timedFunction = true;
      stopTimerAndPrint();
    }

    if((numTestsFile++ % 10) == 0 && !timedFunction &&!timerOperation) {
      printf(".");
    }

    numTestsTotal++;
    outParameters(line + 5);
  }

  else if(line[0] != 0) {
    printf("\nLine cannot be processed\n%s\n", line);
    abortTest();
  }
}



void processOneFile(void) {
  FILE *testSuite;

  numTestsFile = 0;

  strcpy(fileName, line);
  strcat(fileName, ".txt");
  sprintf(filePathName, "%s/%s", filePath, fileName);

  printf("Performing tests from file %s ", filePathName);
  fflush(stdout);

  testSuite = fopen(filePathName, "rb");
  if(testSuite == NULL) {
    printf("Cannot open file %s!\n", fileName);
    exit(-1);
  }

  // Default function to call
  functionIndex = ITM_NOP;
  funcToTest = fnNop;
  funcType = FUNC_NOPARAM;

  ignoreReturnedValue(fgets(line, 9999, testSuite));
  lineNumber = 1;
  while(!feof(testSuite)) {
    standardizeLine();
    while(strlen(line) >= 4 && strncmp(line + strlen(line) - 4, " ...", 4) == 0) {
      line[strlen(line) - 3] = 0;
      if(!feof(testSuite)) {
        ignoreReturnedValue(fgets(line + strlen(line), 9999, testSuite));
        lineNumber++;
        standardizeLine();
      }
    }
    processLine();
    ignoreReturnedValue(fgets(line, 9999, testSuite));
    lineNumber++;
  }

  fclose(testSuite);

  timedFunction = false;
  timerOperation = false;
  //printf(" %d passed successfully\n", numTestsFile);
  printf("\n");
}



void checkOneCatalogSorting(const int16_t *catalog, int16_t catalogId, const char *catalogName) {
  int32_t i, nbElements;

  for(nbElements=0, i=0; softmenu[i].menuItem; i++) {
    if(softmenu[i].menuItem == -catalogId) {
      nbElements = softmenu[i].numItems;
      break;
    }
  }
  if(nbElements == 0) {
    printf("MNU_%s (-%d) not found in structure softmenu!\n", catalogName, catalogId);
    //exit(1);
  }

  printf("Checking sort order of catalog %s (%d elements)\n", catalogName, nbElements);

  for(i=1; i<nbElements; i++) {
    int32_t cmp;
    if((cmp = compareString(indexOfItems[abs(catalog[i - 1])].itemCatalogName, indexOfItems[abs(catalog[i])].itemCatalogName, CMP_EXTENSIVE)) >= 0) {
      printf("In catalog %s, element %d (item %d) should be after element %d (item %d). cmp = %d\n",
                         catalogName, i - 1,  catalog[i - 1],             i,       catalog[i],cmp);
      //exit(1);
    }
  }
}



void checkCatalogsSorting(void) {
  //compareString(indexOfItems[1048].itemCatalogName, indexOfItems[1049].itemCatalogName, CMP_EXTENSIVE);
  checkOneCatalogSorting(menu_FCNS,       MNU_FCNS,      "FCNS");
  checkOneCatalogSorting(menu_CONST,      MNU_CONST,     "CONST");
  checkOneCatalogSorting(menu_SYSFL,      MNU_SYSFL,     "SYS.FL");
  checkOneCatalogSorting(menu_alpha_INTL, MNU_ALPHAINTL, "alphaINTL");
  checkOneCatalogSorting(menu_alpha_intl, MNU_ALPHAintl, "alphaIntl");
}



int processTests(const char *listPath) {
  FILE *fileList;
  char *listPathDup = strdup(listPath);
  filePath = dirname(listPathDup);

  checkCatalogsSorting();

  numTestsTotal = 0;
  failedTests = 0;

  fileList = fopen(listPath, "rb");
  if(fileList == NULL) {
    printf("Cannot open file testSuiteList.txt!\n");
    exit(-1);
  }

  setSystemFlag(FLAG_DENANY);                              //JM Default
  setSystemFlag(FLAG_DENFIX);                              //JM default
  denMax = 9999;                                           //JM default

  fgets(line, 9999, fileList);
  while(!feof(fileList)) {
    standardizeLine();
    if(line[0] != 0) {
      processOneFile();
    }
    ignoreReturnedValue(fgets(line, 9999, fileList));
  }

  fclose(fileList);

  printf("\n************************************\n");
  printf("* %6d TESTS PASSED SUCCESSFULLY *\n", numTestsTotal);
  printf("* %6d TEST%c FAILED              *\n", failedTests, failedTests == 1 ? ' ' : 'S');
  printf("************************************\n");

  free(listPathDup);

  return failedTests > 0 || gmpMemInBytes != 0;
}

int main(int argc, char* argv[]) {
  int exitCode;

  if(argc < 2) {
    printf("Usage: testSuite <list file>\n");
    return 1;
  }

  c47MemInBlocks = 0;
  gmpMemInBytes = 0;
  mp_set_memory_functions(allocGmp, reallocGmp, freeGmp);

  fnReset(CONFIRMED);

  /*
  longInteger_t li;
  longIntegerInit(li);
  uInt32ToLongInteger(1u, li);
  convertLongIntegerToLongIntegerRegister(li, REGISTER_Z);
  uInt32ToLongInteger(2u, li);
  convertLongIntegerToLongIntegerRegister(li, REGISTER_Y);
  uInt32ToLongInteger(2203u, li);
  convertLongIntegerToLongIntegerRegister(li, REGISTER_X);
  fnPower(NOPARAM);
  fnSwapXY(NOPARAM);
  fnSubtract(NOPARAM);
  printf("a\n");
  fnIsPrime(NOPARAM);
  printf("b\n");
  longIntegerFree(li);
  return 0;
  */


  exitCode = processTests(argv[1]);
  printf("The memory owned by GMP should be 0 bytes. Else report a bug please!\n");
  debugMemory("End of testsuite");

  return exitCode;
}
