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
int32_t lineNumber, numTestsFile, numTestsTotal, successfulTests, failedTests;
int32_t functionIndex, funcType, correctSignificantDigits;
bool_t noFailForNow;

uint16_t label, functionParameter;

GtkWidget      *screen;
calcKeyboard_t  calcKeyboard[43];
int             currentBezel; // 0=normal, 1=AIM, 2=TAM
int16_t         screenStride;
uint32_t       *screenData;
bool_t          screenChange;

void (*funcToTest)(uint16_t);
void runPgm(uint16_t unusedButMandatoryParameter);
void covBackupRoundtrip(uint16_t unusedButMandatoryParameter);
void covConvToSI(uint16_t itemNr);
void covConvFromSI(uint16_t itemNr);
void covStateRoundtrip(uint16_t unusedButMandatoryParameter);
void covShortIntWordSizeRestore(uint16_t unusedButMandatoryParameter);
void covEqCalc(uint16_t unusedButMandatoryParameter);
void covDerivEq(uint16_t order);
void covSolveRoot(uint16_t which);
void covDerivErr(uint16_t which);
void covSolveErr(uint16_t which);
void covLoadPgm(uint16_t unusedButMandatoryParameter);
void covDerivPgm(uint16_t order);
void covSolvePgm(uint16_t unusedButMandatoryParameter);
void covIntegrate(uint16_t which);
void covIntegrateErr(uint16_t which);
void covIntegratePgm(uint16_t unusedButMandatoryParameter);
void covSumProd(uint16_t which);
void covISumProd(uint16_t which);
void covProgramFlow(uint16_t which);
void covTvm(uint16_t which);
void covTvmPmt(uint16_t which);
void covEff(uint16_t unusedButMandatoryParameter);
void covEffToI(uint16_t unusedButMandatoryParameter);
void covAmort(uint16_t which);
void covAmortNext(uint16_t which);
void covEqSet(uint16_t which);
void covLoadGraphPgms(uint16_t unusedButMandatoryParameter);
void covBmpName(uint16_t which);
void covHashBmp(uint16_t which);

static const char regNames[] = "XYZTABCDLIJKMNPQRSEFGHOUVW";

// Omitted trailing coverageDriver fields are zero by the C standard; silence the per-row -Wextra noise the same way reservedRegisterLookup.h does.
#if (defined __GNUC__ && __GNUC__ + (__GNUC_MINOR__ >= 6) > 4) || (defined __clang__ && __clang_major__ >= 3)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"
#endif
const funcTest_t funcTestNoParam[] = {
  // Save / restore calc state (serializers; file I/O).
  {"fnSaveRegister",         fnSaveRegister        },
  {"fnSaveStackRegisters",   fnSaveStackRegisters  },
  {"fnSave",                 fnSave                },
  {"fnSaveAllPrograms",      fnSaveAllPrograms     },
  {"fnSaveProgram",          fnSaveProgram         },
  {"fnExportProgram",        fnExportProgram       },
  // Error raising / message display.
  {"fnRaiseError",           fnRaiseError          },
  {"fnErrorMessage",         fnErrorMessage        },
  // Curve fitting / linear regression (operate on accumulated sigma data).
  {"fnCurveFitting",         fnCurveFitting        },
  {"fnCurveFittingReset",    fnCurveFittingReset   },
  {"fnCurveFittingLR",       fnCurveFittingLR      },
  {"fnProcessLR",            fnProcessLR           },
  {"fnYIsFnx",               fnYIsFnx              },
  {"fnXIsFny",               fnXIsFny              },
  // Distributions: GEV, Pareto, Uniform (params in M/S/Q or M/N, input in X).
  {"fnGEVP",                 fnGEVP                },
  {"fnGEVL",                 fnGEVL                },
  {"fnGEVR",                 fnGEVR                },
  {"fnGEVI",                 fnGEVI                },
  {"fnParetoP",              fnParetoP             },
  {"fnParetoL",              fnParetoL             },
  {"fnParetoU",              fnParetoU             },
  {"fnParetoI",              fnParetoI             },
  {"fnPareto2P",             fnPareto2P            },
  {"fnPareto2L",             fnPareto2L            },
  {"fnPareto2U",             fnPareto2U            },
  {"fnPareto2I",             fnPareto2I            },
  {"fnUniformP",             fnUniformP            },
  {"fnUniformL",             fnUniformL            },
  {"fnUniformU",             fnUniformU            },
  {"fnUniformI",             fnUniformI            },
  // Comparisons (X vs Y) and angle conversions (operate on X).
  {"fnXLessThan",            fnXLessThan           },
  {"fnXLessEqual",           fnXLessEqual          },
  {"fnXGreaterThan",         fnXGreaterThan        },
  {"fnXGreaterEqual",        fnXGreaterEqual       },
  {"fnXEqualsTo",            fnXEqualsTo           },
  {"fnXNotEqual",            fnXNotEqual           },
  {"fnXAlmostEqual",         fnXAlmostEqual        },
  // Store / recall (FARG = register number; operate on X, and Y/Z for 2/3 variants).
  {"fnStore",                fnStore               },
  {"fnRecall",               fnRecall              },
  {"fnStoreAdd",             fnStoreAdd            },
  {"fnStoreSub",             fnStoreSub            },
  {"fnStoreMult",            fnStoreMult           },
  {"fnStoreDiv",             fnStoreDiv            },
  {"fnStoreMax",             fnStoreMax            },
  {"fnStoreMin",             fnStoreMin            },
  {"fnRecallAdd",            fnRecallAdd           },
  {"fnRecallSub",            fnRecallSub           },
  {"fnRecallMult",           fnRecallMult          },
  {"fnRecallDiv",            fnRecallDiv           },
  {"fnRecallMax",            fnRecallMax           },
  {"fnRecallMin",            fnRecallMin           },
  {"fn2Sto",                 fn2Sto                },
  {"fn3Sto",                 fn3Sto                },
  {"fn2Rcl",                 fn2Rcl                },
  {"fn3Rcl",                 fn3Rcl                },
  {"fnLastX",                fnLastX               },
  {"fnStoreStack",           fnStoreStack          },
  {"fnRecallStack",          fnRecallStack         },
  // Value/type predicates and small math ops.
  {"fnCheckType",            fnCheckType           },
  {"fnIse",                  fnIse                 },
  {"fnIsg",                  fnIsg                 },
  {"fnIsz",                  fnIsz                 },
  {"fnDse",                  fnDse                 },
  {"fnDsl",                  fnDsl                 },
  {"fnDsz",                  fnDsz                 },
  {"fnCheckNumber",          fnCheckNumber         },
  {"fnCheckAngle",           fnCheckAngle          },
  {"fnCheckMatrix",          fnCheckMatrix         },
  {"fnCheckMatrixSquare",    fnCheckMatrixSquare   },
  {"fnCheckForZero",         fnCheckForZero        },
  {"fnCheckNaN",             fnCheckNaN            },
  {"fnCheckInfinite",        fnCheckInfinite       },
  {"fnCheckSpecial",         fnCheckSpecial        },
  {"fnCheckPlusZero",        fnCheckPlusZero       },
  {"fnCheckMinusZero",       fnCheckMinusZero      },
  {"fnGetType",              fnGetType             },
  {"fnCheckInteger",         fnCheckInteger        },
  {"fnRdp",                  fnRdp                 },
  {"fnRsd",                  fnRsd                 },
  {"fnInc",                  fnInc                 },
  {"fnSdl",                  fnSdl                 },
  {"fnSdr",                  fnSdr                 },
  {"fnRandom",               fnRandom              },
  {"fnRandomI",              fnRandomI             },
  {"fnSeed",                 fnSeed                },
  // Alpha register / string ops (build ALPHA with fnClearAlpha + fnXToAlpha).
  {"fnClearAlpha",           fnClearAlpha          },
  {"fnXToAlpha",             fnXToAlpha            },
  {"fnXToAlphaOld",          fnXToAlphaOld         },
  {"fnAlphaToX",             fnAlphaToX            },
  {"fnAlphaLeng",            fnAlphaLeng           },
  {"fnAlphaPos",             fnAlphaPos            },
  {"fnAlphaIP",             fnAlphaIP             },
  {"fnAlphaRL",              fnAlphaRL             },
  {"fnAlphaRR",              fnAlphaRR             },
  {"fnAlphaSL",              fnAlphaSL             },
  {"fnAlphaSR",              fnAlphaSR             },
  {"fnAlphaLeft",            fnAlphaLeft           },
  {"fnAlphaRight",           fnAlphaRight          },
  {"fnAlphaMid",             fnAlphaMid            },
  {"fnAlphaUpper",           fnAlphaUpper          },
  {"fnAlphaLower",           fnAlphaLower          },
  {"fnAlphaRev",             fnAlphaRev            },
  {"fnAlphaTrim",            fnAlphaTrim           },
  // HP-42S ALPHA ops on the alpha register (REGISTER_K): thin wrappers over the fnAlpha* family.
  {"fn42Cla",                fn42Cla               },
  {"fn42Xtoa",               fn42Xtoa              },
  {"fn42Atox",               fn42Atox              },
  {"fn42Aleng",              fn42Aleng             },
  {"fn42Posa",               fn42Posa              },
  {"fn42Aip",                fn42Aip               },
  {"fn42AlphaRotate",        fn42AlphaRotate       },
  {"fn42AlphaShift",         fn42AlphaShift        },
  {"fn42Alpha",              fn42Alpha             },
  // Program engine: navigate to a global step (selects the current program) and clear the local variables of the current program (walks the loaded program steps;
  // needs res/testPgms/testPgms.bin staged in the CWD).
  {"fnGotoDot",              fnGotoDot             },
  {"fnClCVar",               fnClCVar              },
  // Backup serializer round-trip: save the whole calculator state to backup.cfg and restore it. Exercises both directions of saveRestoreBackup.c.
  // Resets the calculator, so its corpus test must run last.
  {"fnBackupRoundtrip",      covBackupRoundtrip, 1 },
  {"covConvToSI",            covConvToSI, 1 },
  {"covConvFromSI",          covConvFromSI, 1 },
  {"fnEqSetCov",             covEqSet, 1 },
  {"fnLoadGraphPgmsCov",     covLoadGraphPgms, 1 },
  {"fnBmpNameCov",           covBmpName, 1 },
  {"fnHashBmpCov",           covHashBmp, 1 },
  {"fnStateRoundtrip",       covStateRoundtrip, 1 },
  {"fnShortIntWSRestoreCov", covShortIntWordSizeRestore, 1 },
  {"fnEqCalcCov",            covEqCalc, 1 },
  {"fnDerivEqCov",           covDerivEq, 1 },
  {"fnSolveRootCov",         covSolveRoot, 1 },
  {"fnDerivErrCov",          covDerivErr, 1 },
  {"fnSolveErrCov",          covSolveErr, 1 },
  {"fnLoadPgmCov",           covLoadPgm, 1 },
  {"fnDerivPgmCov",          covDerivPgm, 1 },
  {"fnSolvePgmCov",          covSolvePgm, 1 },
  {"fnIntegrateCov",         covIntegrate, 1 },
  {"fnIntegrateErrCov",      covIntegrateErr, 1 },
  {"fnIntegratePgmCov",      covIntegratePgm, 1 },
  {"fnSumProdCov",           covSumProd, 1 },
  {"fnISumProdCov",          covISumProd, 1 },
  {"fnProgramFlowCov",       covProgramFlow, 1 },
  {"fnTvmCov",               covTvm, 1 },
  {"fnTvmPmtCov",            covTvmPmt, 1 },
  {"fnEffCov",               covEff, 1 },
  {"fnEffToICov",            covEffToI, 1 },
  {"fnAmortCov",             covAmort, 1 },
  {"fnAmortNextCov",         covAmortNext, 1 },
  // Statistics (use FARG=1 with fnSigmaAddRem to accumulate a (Y,X) data point).
  {"fnSigmaAddRem",          fnSigmaAddRem         },
  {"fnMeanX",                fnMeanX               },
  {"fnMeanXY",               fnMeanXY              },
  {"fnGeometricMeanXY",      fnGeometricMeanXY     },
  {"fnHarmonicMeanXY",       fnHarmonicMeanXY      },
  {"fnRMSMeanXY",            fnRMSMeanXY           },
  {"fnWeightedMeanX",        fnWeightedMeanX       },
  {"fnMedianXY",             fnMedianXY            },
  {"fnSampleStdDev",         fnSampleStdDev        },
  {"fnPopulationStdDev",     fnPopulationStdDev    },
  {"fnStandardError",        fnStandardError       },
  {"fnSampleCovariance",     fnSampleCovariance    },
  {"fnPopulationCovariance", fnPopulationCovariance},
  {"fnLowerQuartileXY",      fnLowerQuartileXY     },
  {"fnUpperQuartileXY",      fnUpperQuartileXY     },
  {"fnIQRXY",                fnIQRXY               },
  {"fnDeltaPercentXmean",    fnDeltaPercentXmean   },
  {"fnPcSigmaDeltaPcXmean",  fnPcSigmaDeltaPcXmean },
  {"fnGeometricSampleStdDev", fnGeometricSampleStdDev},
  {"fnGeometricStandardError", fnGeometricStandardError},
  {"fnWeightedSampleStdDev", fnWeightedSampleStdDev},
  {"fnWeightedStandardError", fnWeightedStandardError},
  {"fnPercentileXY",         fnPercentileXY        },
  {"fnCoeffDetermination",   fnCoefficientDetermination},
  {"fnAmortP",               fnAmortP              },
  {"fnAmortInt",             fnAmortInt            },
  {"fnAmortPrn",             fnAmortPrn            },
  {"fnAmortBal",             fnAmortBal            },
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
  {"fnConstant",             fnConstant            },
  {"fnCos",                  fnCos                 },
  {"fnCosh",                 fnCosh                },
  {"fnCountBits",            fnCountBits           },
  {"fnCross",                fnCross               },
  {"fnCube",                 fnCube                },
  {"fnCubeRoot",             fnCubeRoot            },
  {"fnCvtDbRatio",           fnCvtDbRatio          },
  {"fnCvtDegGrad",           fnCvtDegGrad          },
  {"fnCvtDegRad",            fnCvtDegRad           },
  {"fnCvtGradRad",           fnCvtGradRad          },
  {"fnCvtHMSHR",             fnCvtHMSHR            },
  {"fnCvtRatioDb",           fnCvtRatioDb          },
  {"fnCvtTemp",              fnCvtTemp             },
  {"fnCxToRe",               fnCxToRe              },
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
  {"fnVectorDist",           fnVectorDist          },
  {"fnSwapRows",             fnSwapRows            },
  {"fnSwapColumns",          fnSwapColumns         },
  {"fnColumnMin",            fnColumnMin           },
  {"fnColumnMax",            fnColumnMax           },
  {"fnSetMatrixDimensions",  fnSetMatrixDimensions },
  {"fnIndexMatrix",          fnIndexMatrix         },
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
  {"fnKmletok100K",          fnKmletok100K         },
  {"fnL100Tomgus",           fnL100Tomgus          },
  {"fnL100Tomguk",           fnL100Tomguk          },
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
  {"fnMant",                 fnMant                },
  {"fnMaskl",                fnMaskl               },
  {"fnMaskr",                fnMaskr               },
  {"fnMatrixIdentity",       fnMatrixIdentity      },
  {"fnMatrixSquareRoot",     fnMatrixSquareRoot    },
  {"fnMax",                  fnMax                 },
  {"fnMgeuktok100M",         fnMgeuktok100M        },
  {"fnMgeustok100M",         fnMgeustok100M        },
  {"fnMin",                  fnMin                 },
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
  {"fnUnitConvert",          fnUnitConvert         },
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
  {"fnXAlmostEqual",         fnXAlmostEqual        },
  {"fnYear",                 fnYear                },
  {"fnZeta",                 fnZeta                },
  {"fnZip",                  fnZip                 },
  {"fnDeltaToStar",          fnDeltaToStar         },
  {"fnStarToDelta",          fnStarToDelta         },
  {"fnSymToAbc",             fnSymToAbc            },
  {"fnAbcToSym",             fnAbcToSym            },
  {"fnCopyXtoAbc",           fnCopyXtoAbc          },
  {"fnTripleZfromVI",        fnTripleZfromVI       },
  {"fnTripleVfromIZ",        fnTripleVfromIZ       },
  {"fnTripleIfromVZ",        fnTripleIfromVZ       },
  {"fnTripleFlipPolar",      fnTripleFlipPolar     },
  // Bit set/flip on X and the bit-set/clear tests (FARG = bit number).
  {"fnSb",                   fnSb                  },
  {"fnBs",                   fnBs                  },
  {"fnBc",                   fnBc                  },
  {"fnFb",                   fnFb                  },
  // Flag test and test-and-modify (FARG = flag number).
  {"fnIsFlagSet",            fnIsFlagSet           },
  {"fnIsFlagSetSet",         fnIsFlagSetSet        },
  {"fnIsFlagSetClear",       fnIsFlagSetClear      },
  {"fnIsFlagSetFlip",        fnIsFlagSetFlip       },
  {"fnIsFlagClearSet",       fnIsFlagClearSet      },
  {"fnIsFlagClearClear",     fnIsFlagClearClear    },
  {"fnIsFlagClearFlip",      fnIsFlagClearFlip     },
  {"fnFlipFlag",             fnFlipFlag            },
  {"fnGetSystemFlag",        fnGetSystemFlag       },
  // Clear / delete all named variables (FARG = confirmation).
  {"fnClearAllVariables",    fnClearAllVariables   },
  {"fnDeleteAllVariables",   fnDeleteAllVariables  },
  // Register range management (range packed in X as s.NNDDD).
  {"fnRegSort",              fnRegSort             },
  {"fnRegSwap",              fnRegSwap             },
  {"fnRegCopy",              fnRegCopy             },
  {"fnRegClr",               fnRegClr              },
  // Statistics readouts (need accumulated sigma data; FARG selects the sum).
  {"fnXmin",                 fnXmin                },
  {"fnXmax",                 fnXmax                },
  {"fnRangeXY",              fnRangeXY             },
  {"fnStatSum",              fnStatSum             },
  // Histogram setup (fnConvertStatsToHisto arms it; FARG = ITM_X / ITM_Y).
  {"fnSetNBins",             fnSetNBins            },
  {"fnSetLoBin",             fnSetLoBin            },
  {"fnSetHiBin",             fnSetHiBin            },
  {"fnConvertStatsToHisto",  fnConvertStatsToHisto },
  // Configuration: modes, display settings, getters (config.c).
  {"fnAngularMode",          fnAngularMode         },
  {"fnIntegerMode",          fnIntegerMode         },
  {"fnFractionType",         fnFractionType        },
  {"fnRange",                fnRange               },
  {"fnHide",                 fnHide                },
  {"fnResetTVM",             fnResetTVM            },
  {"fnSetADM",               fnSetADM              },
  {"fnSetDMX",               fnSetDMX              },
  {"fnSetISM",               fnSetISM              },
  {"fnSetNDEC",              fnSetNDEC             },
  {"fnSetBaseNr",            fnSetBaseNr           },
  {"fnSetC47",               fnSetC47              },
  {"fnSetRJ",                fnSetRJ               },
  {"fnSetJM",                fnSetJM               },
  {"fnSetHP35",              fnSetHP35             },
  {"fnSetREALDF",            fnSetREALDF           },
  {"fnSetFractionDigits",    fnSetFractionDigits   },
  {"fnSetSignificantDigits", fnSetSignificantDigits},
  {"fnSetRoundingMode",      fnSetRoundingMode     },
  {"fnGetADM",               fnGetADM              },
  {"fnGetDMX",               fnGetDMX              },
  {"fnGetRange",             fnGetRange            },
  {"fnGetHide",              fnGetHide             },
  {"fnGetNDEC",              fnGetNDEC             },
  {"fnGetREALDF",            fnGetREALDF           },
  {"fnGetFractionDigits",    fnGetFractionDigits   },
  {"fnGetLastErr",           fnGetLastErr          },
  {"fnMenuGapL",             fnMenuGapL            },
  {"fnMenuGapR",             fnMenuGapR            },
  {"fnMenuGapRX",            fnMenuGapRX           },
  {"fnSettingsDispFormatGrpL", fnSettingsDispFormatGrpL},
  {"fnSettingsDispFormatGrpR", fnSettingsDispFormatGrpR},
  {"fnClAll",                fnClAll               },
  {"fnWho",                  fnWho                 },

  {"fnExecute",              runPgm                },
  {"",                       NULL                  }
};
#if (defined __GNUC__ && __GNUC__ + (__GNUC_MINOR__ >= 6) > 4) || (defined __clang__ && __clang_major__ >= 3)
#pragma GCC diagnostic pop
#endif



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
    sprintf(registerContent, "In printRegisterToString: data type %s not supported", getRegisterDataTypeName(regist, false, false));
  }
}



void runPgm(uint16_t unusedButMandatoryParameter) {
  if(label != INVALID_VARIABLE) {
    dynamicSoftmenu[0].numItems = 0;
    free(dynamicSoftmenu[0].menuContent); // release the dynamic menu buffer before dropping the pointer
    dynamicSoftmenu[0].menuContent = NULL;
    reallyRunFunction(ITM_XEQ, label);
  }
}



void covBackupRoundtrip(uint16_t unusedButMandatoryParameter) {
  // Save the whole calculator state to backup.cfg and restore it, exercising both the serialize and deserialize halves of saveRestoreBackup.c.
  // restoreCalc() bails when the sample programs are loaded, so clear that flag first; it resets the calculator, so this must be the last test in the list.
  loadTestPrograms = false;
  saveCalc();
  restoreCalc();
}

static void covStoTvm(int32_t value, uint16_t reg) {
  // Store an integer into a register through the calculator's own STO, which types the destination correctly. Seeds the reserved TVM registers and clobbers global
  // registers with a sentinel.
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  int32ToReal34(value, REGISTER_REAL34_DATA(REGISTER_X));
  reallyRunFunction(ITM_STO, reg);
}

static void covClobberRegs(void) {
  // Overwrite the seeded global registers R00..R05 with a sentinel so a following load must restore them from file for the round-trip assertion to mean anything (a
  // no-op load would leave the sentinel and fail the test). The sentinel is a real, so it also destroys the datatype of the mixed-type registers (R03 complex,
  // R04 string, R05 short integer) - the load must restore both the value and the type.
  for(uint16_t r = 0; r < 6; ++r) {
    covStoTvm(-99999, r);
  }
}

void covStateRoundtrip(uint16_t unusedButMandatoryParameter) {
  // Save the whole calculator state and load it straight back, driving both the serialize half (doSave) and the deserialize half (doLoad,
  // restoreOneSection) of saveRestoreCalcState.c. In the host build the DMCP power_check_screen() guard is compiled out, so doSave runs.
  // Loading rewrites the state from file, so this must run late in the list; the round-trip is lossless, so seeded registers survive it.
  //
  // Two save flavours and several load modes are exercised: the full state file (stateSave/stateLoad, c47state.bin) plus a manual save (manualSave,
  // c47.sav) read back one section at a time, covering the loadMode dispatch in restoreOneSection (registers, named variables, statistical sums, system state).
  //
  // The seeded registers R00..R05 are clobbered with a sentinel after each save and before the matching load, so the corpus assertion that they come back is proof that
  // the load actually reads and restores the file - a no-op load would leave the sentinel and fail the test, rather than passing on state that was simply never
  // changed.
  fnSave(SM_STATE_SAVE);
  covClobberRegs();
  fnLoad(LM_STATE_LOAD);
  fnSave(SM_MANUAL_SAVE);
  covClobberRegs();
  fnLoad(LM_REGISTERS);
  fnLoad(LM_NAMED_VARIABLES);
  fnLoad(LM_SUMS);
  fnLoad(LM_SYSTEM_STATE);
}

void covShortIntWordSizeRestore(uint16_t unusedButMandatoryParameter) {
  // Regression for the short-integer masks after a state restore. The state file
  // records shortIntegerWordSize but neither shortIntegerMask nor the sign bit,
  // and doLoad restores the word size by plain assignment. If the mask is not
  // rederived from the loaded word size, it keeps its pre-load value (-1 when a
  // file saved at a narrow word size is loaded into the 64-bit default), and
  // every later short-integer operation masks against the wrong width.
  //
  // Save an 8-bit state, move the live word size to 64 so shortIntegerMask
  // becomes -1, reload the 8-bit state, then store 300 as a short integer. The
  // store masks with shortIntegerMask: with a correct 8-bit mask that is
  // 300 & 0xff = 44; with the stale -1 mask it stays 300. The corpus asserts 44,
  // so the case fails unless the loader rederives the mask.
  fnSetWordSize(8);
  convertUInt64ToShortIntegerRegister(0, 200u, 10u, REGISTER_X); // a valid 8-bit seed to serialize
  fnSave(SM_STATE_SAVE);
  fnSetWordSize(64);                                             // shortIntegerMask := -1
  fnLoad(LM_STATE_LOAD);                                         // restores word size 8; the fix rederives the mask
  convertUInt64ToShortIntegerRegister(0, 300u, 10u, REGISTER_X); // masks with shortIntegerMask -> 44 or 300
}

void covEqCalc(uint16_t formulaIndex) {
  // Evaluate one of a table of formulas through the equation engine, selected by FARG. fnEqCalc() runs parseEquation() in EQUATION_PARSER_XEQ mode over the current
  // formula, driving the tokeniser, the operator-precedence parser, and the function dispatch in equation.c; the result lands in X.
  // A single formula slot is created and reused, so no formula accumulates in the pool.
  static const char * const covFormulae[] = {
    "2+3",                    // 0  addition
    "1+2" STD_CROSS "3",      // 1  precedence: x binds tighter than +
    "(1+2)" STD_CROSS "3",    // 2  parentheses override precedence
    "2^10",                   // 3  power
    "10-2-3",                 // 4  left-associative subtraction
    "2" STD_CROSS "(3+4)^2",  // 5  nested parentheses and power
    "100-2" STD_CROSS "3^2",  // 6  precedence across x and ^
    "COS(0)",                 // 7  function call -> 1
    "SIN(0)",                 // 8  function call -> 0
    "-5+3",                   // 9  unary minus
    "COS(SIN(0))",            // 10 nested function calls
    "TAN(0)",                 // 11 another function
    "LN(1)",                  // 12 natural log
    "((2+3)^2-1)",            // 13 deeper nesting
    "2^3^2",                  // 14 power associativity
    "A+2",                    // 15 named variable A (= X in)
    "A^2",                    // 16 named variable in a power
    "A" STD_CROSS "A+1",      // 17 variable used twice
    "2+3=5",                  // 18 equation that holds (residual 0)
    "3+4=10",                 // 19 equation residual (RHS-LHS = 10-7 = 3)
  };
  const uint16_t n = sizeof(covFormulae) / sizeof(covFormulae[0]);
  if(formulaIndex >= n) {
    return;
  }
  if(numberOfFormulae == 0) {
    fnEqNew(NOPARAM);
  }
  // Store the corpus input (X) into the named variable A so a formula can reference it; this exercises the variable-resolution path in the parser.
  reallyRunFunction(ITM_STO, findOrAllocateNamedVariable("A"));
  setEquation(currentFormula, covFormulae[formulaIndex]);
  fnEqCalc(NOPARAM);
}

void covDerivEq(uint16_t order) {
  // Differentiate the current formula f(X) at the point in X, through the equation derivative path (fn1stDerivEq / fn2ndDerivEq in differentiate.c,
  // which evaluate the formula via parseEquation each iteration). A formula in the named variable X is set once and reused; the eval point comes from X.
  // order 2 -> second derivative, else first. Result lands in X.
  if(numberOfFormulae == 0) {
    fnEqNew(NOPARAM);
  }
  setEquation(currentFormula, "X^3");
  currentSolverVariable = findOrAllocateNamedVariable("X");
  reallyRunFunction(ITM_STO, currentSolverVariable);
  if(order == 2) {
    fn2ndDerivEq(NOPARAM);
  }
  else {
    fn1stDerivEq(NOPARAM);
  }
}

void covSolveRoot(uint16_t which) {
  // Find a root of a formula with the numeric root solver (fnSolve -> solver() in solve.c). The two guesses come from Y and X on the stack;
  // the solver evaluates the formula (equation.c) each iteration, leaving the result in X. Using a formula avoids a program fixture,
  // so SOLVER_STATUS_USES_FORMULA is set explicitly. which < 2 uses f(X)=X^2-4 (roots +/-2); which >= 2 uses f(X)=X^2+1, which has no real root,
  // driving the solver's no-root-found path.
  if(numberOfFormulae == 0) {
    fnEqNew(NOPARAM);
  }
  setEquation(currentFormula, (which >= 2) ? "X^2+1" : "X^2-4");
  const uint16_t var = findOrAllocateNamedVariable("X");
  currentSolverVariable = var;
  // Reset the solver status to exactly USES_FORMULA: a prior solver-driving test (e.g. the equation derivative) can leave other status bits set that change the
  // solver's convergence, so assign rather than OR.
  currentSolverStatus = SOLVER_STATUS_USES_FORMULA;
  fnSolve(var);
}

void covDerivErr(uint16_t which) {
  // Drive the error/dispatch branches of the program-based derivative entry (derivativeCommon in differentiate.c), which the formula path covDerivEq does not reach.
  // which=0: a stack register whose letter names no program label -> ERROR_LABEL_NOT_FOUND; otherwise an out-of-range parameter -> ERROR_OUT_OF_RANGE.
  if(which == 0) {
    fn1stDeriv(REGISTER_T);            // letter 'T' names no program label
  }
  else {
    fn1stDeriv(FIRST_NAMED_VARIABLE);  // outside [FIRST_LABEL,LAST_LABEL] and [X,T]
  }
}

void covSolveErr(uint16_t which) {
  // Drive the error/dispatch branches of fnPgmSlv (solve.c), distinct from the formula solver covSolveRoot drives. which=0:
  // a stack register whose letter names no program label -> ERROR_LABEL_NOT_FOUND; otherwise an out-of-range parameter -> ERROR_OUT_OF_RANGE.
  if(which == 0) {
    fnPgmSlv(REGISTER_T);
  }
  else {
    fnPgmSlv(FIRST_NAMED_VARIABLE);
  }
}

static void covWriteAndLoadPgm(const uint8_t *pgm, size_t n) {
  // Write a program in the program-file format (PROGRAM_VERSION 1, one byte per line) and import it through the official loader fnLoadProgram,
  // which appends it safely and registers the global label. The file is the Test-suffixed name the test HAL maps ioPathLoadProgram to (c47programTest.bin),
  // never the real c47program.bin, so the suite cannot clobber a user's saved program.
  FILE *f = fopen("c47programTest.bin", "wb");
  if(f == NULL) {
    printf("\nCannot open c47programTest.bin for writing\n");
    abortTest();
    return;
  }
  fprintf(f, "PROGRAM_FILE_FORMAT\n0\nC47_program_file_version\n1\nPROGRAM\n%u\n", (unsigned)n);
  for(size_t i = 0; i < n; ++i) {
    fprintf(f, "%u\n", pgm[i]);
  }
  fclose(f);
  fnLoadProgram(NOPARAM);
}

void covLoadPgm(uint16_t unusedButMandatoryParameter) {
  // Build and import two labelled RPN programs: S = X^2 - 4 (root at X=2, derivative 2X) for the solver / differentiator / integrator / real summation,
  // and T = X^2 (which returns a long integer for a long-integer counter) for the indexed summation. Both reach the execProgram branches the formula corpus cannot.
  // Bytes: LBL name / X^2 / [literal 4 / SUB] / END.
  static const uint8_t pgmS[] = {
    ITM_LBL, STRING_LABEL_VARIABLE, 1, 'S',            // LBL "S"
    ITM_SQUARE,                                        // X^2
    ITM_LITERAL, STRING_REAL34, 1, '4',                // 4
    ITM_SUB,                                           // X^2 - 4
    (uint8_t)((ITM_END >> 8) | 0x80), (uint8_t)(ITM_END & 0xff), // END
  };
  static const uint8_t pgmT[] = {
    ITM_LBL, STRING_LABEL_VARIABLE, 1, 'T',            // LBL "T"
    ITM_SQUARE,                                        // X^2
    (uint8_t)((ITM_END >> 8) | 0x80), (uint8_t)(ITM_END & 0xff), // END
  };
  covWriteAndLoadPgm(pgmS, sizeof(pgmS));
  covWriteAndLoadPgm(pgmT, sizeof(pgmT));
}

void covProgramFlow(uint16_t which) {
  // Drive the program flow-control engine (lblGtoXeq.c) and program clearing
  // (manage.c): a cross-program subroutine call and return, a forward GTO over a
  // dead step, an unresolved XEQ, clearing one program and all programs, a
  // step-number goto, the top-routine check, and a literal of each string-encoded
  // type. Named global labels are encoded like covLoadPgm; each program ends with
  // END.
  static const uint8_t pgmQ[] = {                          // Q: X -> X + 10, return
    ITM_LBL, STRING_LABEL_VARIABLE, 1, 'Q',
    ITM_LITERAL, STRING_REAL34, 2, '1', '0',
    ITM_ADD,
    ITM_RTN,
    (uint8_t)((ITM_END >> 8) | 0x80), (uint8_t)(ITM_END & 0xff),
  };
  static const uint8_t pgmP[] = {                          // P: 5, XEQ Q -> 15
    ITM_LBL, STRING_LABEL_VARIABLE, 1, 'P',
    ITM_LITERAL, STRING_REAL34, 1, '5',
    ITM_XEQ, STRING_LABEL_VARIABLE, 1, 'Q',
    (uint8_t)((ITM_END >> 8) | 0x80), (uint8_t)(ITM_END & 0xff),
  };
  static const uint8_t pgmG[] = {                          // G: 7, GTO H, (dead 999), H: 3, + -> 10
    ITM_LBL, STRING_LABEL_VARIABLE, 1, 'G',
    ITM_LITERAL, STRING_REAL34, 1, '7',
    ITM_GTO, STRING_LABEL_VARIABLE, 1, 'H',
    ITM_LITERAL, STRING_REAL34, 3, '9', '9', '9',
    ITM_LBL, STRING_LABEL_VARIABLE, 1, 'H',
    ITM_LITERAL, STRING_REAL34, 1, '3',
    ITM_ADD,
    (uint8_t)((ITM_END >> 8) | 0x80), (uint8_t)(ITM_END & 0xff),
  };
  static const uint8_t pgmE[] = {                          // E: XEQ Z (undefined) -> label not found
    ITM_LBL, STRING_LABEL_VARIABLE, 1, 'E',
    ITM_XEQ, STRING_LABEL_VARIABLE, 1, 'Z',
    (uint8_t)((ITM_END >> 8) | 0x80), (uint8_t)(ITM_END & 0xff),
  };
  static const uint8_t pgmC[] = {                          // C: trivial program to clear
    ITM_LBL, STRING_LABEL_VARIABLE, 1, 'C',
    (uint8_t)((ITM_END >> 8) | 0x80), (uint8_t)(ITM_END & 0xff),
  };

  // Start from an empty program memory (this also drives fnClPAll in manage.c) so
  // the freshly loaded labels are unambiguous and the missing-label lookup in
  // case 2 cannot resolve to a sample program.
  fnClPAll(CONFIRMED);
  dynamicMenuItem = -1; // fnGoto and goToGlobalStep divert to a dynamic-menu label when this is >= 0

  switch(which) {
    case 0: { // cross-program subroutine call (XEQ) and return (RTN): 5 + 10 = 15
      covWriteAndLoadPgm(pgmQ, sizeof(pgmQ));
      covWriteAndLoadPgm(pgmP, sizeof(pgmP));
      fnExecute(findNamedLabel("P", GLOBAL_LABELS));
      break;
    }
    case 1: { // forward GTO past the dead 999 step into H: 7 + 3 = 10
      covWriteAndLoadPgm(pgmG, sizeof(pgmG));
      fnExecute(findNamedLabel("G", GLOBAL_LABELS));
      break;
    }
    case 2: { // XEQ of an undefined label leaves ERROR_LABEL_NOT_FOUND
      covWriteAndLoadPgm(pgmE, sizeof(pgmE));
      fnExecute(findNamedLabel("E", GLOBAL_LABELS));
      break;
    }
    case 3: { // clear a single loaded program by its global label (manage.c fnClP)
      covWriteAndLoadPgm(pgmC, sizeof(pgmC));
      fnClP(findNamedLabel("C", GLOBAL_LABELS));
      break;
    }
    case 4: { // go to a program step by number, driving goToGlobalStep (fnGotoDot)
      covWriteAndLoadPgm(pgmG, sizeof(pgmG));
      fnGotoDot(2);
      break;
    }
    case 5: { // fnIsTopRoutine reports TI_TRUE at the top level; leave 1/0 in X
      fnIsTopRoutine(NOPARAM);
      reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
      int32ToReal34(temporaryInformation == TI_TRUE ? 1 : 0, REGISTER_REAL34_DATA(REGISTER_X));
      break;
    }
    case 6: { // push a literal of each string-encoded type, driving _putLiteral;
              // the last literal (long integer 42) is left in X
      static const uint8_t pgmL[] = {
        ITM_LBL, STRING_LABEL_VARIABLE, 1, 'L',
        ITM_LITERAL, STRING_LONG_INTEGER, 3, '1', '2', '3',
        ITM_LITERAL, STRING_REAL34, 3, '3', '.', '5',
        ITM_LITERAL, STRING_COMPLEX34, 4, '3', '+', 'i', '4',
        ITM_LITERAL, STRING_ANGLE_DEGREE, 2, '4', '5',
        ITM_LITERAL, STRING_ANGLE_RADIAN, 1, '1',
        ITM_LITERAL, STRING_ANGLE_GRAD, 2, '5', '0',
        ITM_LITERAL, STRING_ANGLE_MULTPI, 3, '0', '.', '5',
        ITM_LITERAL, STRING_ANGLE_DMS, 3, '1', '.', '3',
        ITM_LITERAL, STRING_DATE, 7, '2', '4', '5', '1', '5', '4', '5',
        ITM_LITERAL, STRING_TIME, 3, '1', '.', '3',
        ITM_LITERAL, STRING_LABEL_VARIABLE, 2, 'h', 'i',
        ITM_LITERAL, STRING_SHORT_INTEGER, 16, 2, 'F', 'F',
        ITM_LITERAL, STRING_LONG_INTEGER, 2, '4', '2',
        (uint8_t)((ITM_END >> 8) | 0x80), (uint8_t)(ITM_END & 0xff),
      };
      covWriteAndLoadPgm(pgmL, sizeof(pgmL));
      fnExecute(findNamedLabel("L", GLOBAL_LABELS));
      break;
    }
    default: break;
  }
  programRunStop = PGM_STOPPED; // leave the run state idle for the next test
  calcMode = CM_NORMAL;
}

void covDerivPgm(uint16_t order) {
  // Program-based derivative: differentiate the loaded program S (f(X)=X^2-4) at the point in X through derivativeCommon -> calcDeriv -> execProgram (differentiate.c)
  // - the program branch covDerivEq (formula) does not reach. f'(X)=2X, so the first derivative at X=3 is 6.
  const calcRegister_t label = findNamedLabel("S", GLOBAL_LABELS);
  if(label == INVALID_VARIABLE) {
    printf("\nUnknown global label: S\n");
    abortTest();
    return;
  }
  currentSolverStatus &= ~SOLVER_STATUS_USES_FORMULA;
  if(order == 2) {
    fn2ndDeriv(label);
  }
  else {
    fn1stDeriv(label);
  }
}

void covSolvePgm(uint16_t unusedButMandatoryParameter) {
  // Program-based root solve: find a root of the loaded program S (f(X)=X^2-4) with fnSolve -> solver() over the program (execProgram each iteration in solve.c) - the
  // program branch covSolveRoot (formula) does not reach. The two guesses come from Y and X on the stack; the positive root is 2. fnPgmSlv selects the program,
  // then fnSolve over a named variable runs the iteration (the program reads the trial value the solver leaves in X).
  const calcRegister_t label = findNamedLabel("S", GLOBAL_LABELS);
  if(label == INVALID_VARIABLE) {
    printf("\nUnknown global label: S\n");
    abortTest();
    return;
  }
  // Clear the whole solver status first: a prior TVM or interactive solve can leave bits set (e.g. SOLVER_STATUS_TVM_APPLICATION) that send _executeSolver down the
  // wrong evaluation path, so assign rather than clear a single bit.
  currentSolverStatus = 0;
  fnPgmSlv(label);
  fnSolve(findOrAllocateNamedVariable("X"));
}

void covIntegrate(uint16_t which) {
  // Integrate the current formula f(X) over [Y, X] with fnIntegrateYX (integrate.c -> the double-exponential integrator,
  // evaluating the formula via parseEquation each iteration). which selects the integrand; the lower limit comes from Y and the upper from X on the stack;
  // the result lands in X. A formula avoids a program fixture, so SOLVER_STATUS_USES_FORMULA is set explicitly.
  static const char * const covIntegrand[] = {
    "X",                              // 0  integral of X     over [0,2] = 2
    "X" STD_CROSS "X",                // 1  integral of X*X   over [0,3] = 9
    "X+1",                            // 2  integral of X+1   over [0,2] = 4
    "X" STD_CROSS "X" STD_CROSS "X",  // 3  integral of X^3   over [0,2] = 4
    "2" STD_CROSS "X",                // 4  integral of 2*X   over [0,3] = 9
  };
  const uint16_t n = sizeof(covIntegrand) / sizeof(covIntegrand[0]);
  if(which >= n) {
    return;
  }
  if(numberOfFormulae == 0) {
    fnEqNew(NOPARAM);
  }
  setEquation(currentFormula, covIntegrand[which]);
  const uint16_t var = findOrAllocateNamedVariable("X");
  currentSolverVariable = var;
  currentSolverStatus = SOLVER_STATUS_USES_FORMULA;
  // Accuracy: zero the ACC reserved variable, which the integrator reads as the default 1e-32 tolerance. This does not touch X/Y,
  // which carry the limits that fnIntegrateYX reads (upper from X, lower from Y).
  reallocateRegister(RESERVED_VARIABLE_ACC, dtReal34, 0, amNone);
  int32ToReal34(0, REGISTER_REAL34_DATA(RESERVED_VARIABLE_ACC));
  fnIntegrateYX(var);
}

void covIntegrateErr(uint16_t which) {
  // Drive the dispatch error branches of the integrator (_fnIntegrate / fnPgmInt in integrate.c). which=0: a stack register whose letter names no program label ->
  // ERROR_LABEL_NOT_FOUND; otherwise a named variable with no program specified -> ERROR_NO_PROGRAM_SPECIFIED.
  if(which == 0) {
    fnIntegrate(REGISTER_T);
  }
  else {
    currentSolverStatus = 0;
    currentSolverProgram = 9999;   // >= numberOfLabels: no program specified
    fnIntegrate(FIRST_NAMED_VARIABLE);
  }
}

void covIntegratePgm(uint16_t unusedButMandatoryParameter) {
  // Program-based integral: integrate the loaded program S (f(X)=X^2-4) over [Y,X] through fnPgmInt -> the integrator's execProgram branch (integrate.c),
  // distinct from the formula path covIntegrate drives. Integral of X^2-4 over [0,3] is [X^3/3 - 4X] = 9 - 12 = -3. Requires the sample programs staged,
  // so its corpus runs after programs.txt.
  const calcRegister_t label = findNamedLabel("S", GLOBAL_LABELS);
  if(label == INVALID_VARIABLE) {
    printf("\nUnknown global label: S\n");
    abortTest();
    return;
  }
  currentSolverStatus = 0;
  fnPgmInt(label);
  reallocateRegister(RESERVED_VARIABLE_ACC, dtReal34, 0, amNone);
  int32ToReal34(0, REGISTER_REAL34_DATA(RESERVED_VARIABLE_ACC));
  fnIntegrateYX(findOrAllocateNamedVariable("X"));
}

void covSumProd(uint16_t which) {
  // Program-based summation / product (sumprod.c). fnProgrammableSum / fnProgrammableProduct run the loaded program S (f(n)=n^2-4) for the counter n = Z, Z+X, ...
  // up to Y (from=Z, to=Y, step=X on the stack), accumulating the sum or product of f(n). For n=3,4,5: sum = 5+12+21 = 38, product = 5*12*21 = 1260.
  // Requires the sample programs staged, so its corpus runs after programs.
  const calcRegister_t label = findNamedLabel("S", GLOBAL_LABELS);
  if(label == INVALID_VARIABLE) {
    printf("\nUnknown global label: S\n");
    abortTest();
    return;
  }
  currentSolverStatus = 0;
  if(which == 1) {
    fnProgrammableProduct(label);
  }
  else {
    fnProgrammableSum(label);
  }
}

void covISumProd(uint16_t which) {
  // Program-based indexed (long-integer) summation / product (isumprod.c). fnProgrammableiSum / fnProgrammableiProduct run the loaded program T (f(n)=n^2,
  // which returns a long integer for a long-integer counter) for n = Z, Z+X, ... up to Y (from=Z, to=Y, step=X, all long integers on the stack),
  // accumulating a long-integer sum or product. For n=1,3,5 (from=1, to=5, step=2): sum = 1+9+25 = 35, product = 1*9*25 = 225. Requires the sample programs staged,
  // so its corpus runs after programs.
  const calcRegister_t label = findNamedLabel("T", GLOBAL_LABELS);
  if(label == INVALID_VARIABLE) {
    printf("\nUnknown global label: T\n");
    abortTest();
    return;
  }
  currentSolverStatus = 0;
  if(which == 1) {
    fnProgrammableiProduct(label);
  }
  else {
    fnProgrammableiSum(label);
  }
}


static void covSolveTvmTarget(uint16_t target) {
  // Clobber the target with a deliberately-wrong value (50) so a no-op fnTvmVar would leave 50 and fail rather than pass on the pre-seeded answer, solve for it,
  // and copy the result into X for the corpus to assert.
  covStoTvm(50, target);
  fnTvmVar(target);
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  real34Copy(REGISTER_REAL34_DATA(target), REGISTER_REAL34_DATA(REGISTER_X));
}

void covTvm(uint16_t which) {
  // Solve one time-value-of-money variable from the others with fnTvmVar (tvm.c). In the testSuite build the internal `testing` flag is true,
  // so fnTvmVar executes the solve directly instead of waiting on the MVAR menu. A consistent END-mode problem with round numbers - N=3,
  // I%/yr=100 (periodic rate 100%), PV=-1000, PMT=0, FV=8000, one payment and compounding period per year - so every solved variable is exact: FV=-PV(1+i)^N=8000,
  // PV=-1000, N=3, I%=100, PMT=0. FARG selects the target (0=FV, 1=PV, 2=PMT, 3=N, 4=I%); the result is copied from its reserved register into X for the corpus to
  // assert.
  setSystemFlag(FLAG_ENDPMT);
  covStoTvm(3,     RESERVED_VARIABLE_NPPER);
  covStoTvm(100,   RESERVED_VARIABLE_IPONA);
  covStoTvm(-1000, RESERVED_VARIABLE_PV);
  covStoTvm(0,     RESERVED_VARIABLE_PMT);
  covStoTvm(8000,  RESERVED_VARIABLE_FV);
  covStoTvm(1,     RESERVED_VARIABLE_PPERONA);
  covStoTvm(1,     RESERVED_VARIABLE_CPERONA);
  currentSolverStatus = 0;
  uint16_t target;
  switch(which) {
    case 1:  target = RESERVED_VARIABLE_PV;    break;
    case 2:  target = RESERVED_VARIABLE_PMT;   break;
    case 3:  target = RESERVED_VARIABLE_NPPER; break;
    case 4:  target = RESERVED_VARIABLE_IPONA; break;
    default: target = RESERVED_VARIABLE_FV;    break;
  }
  // The closed-form variables (FV/PV/PMT/N) ignore the wrong seed and simply overwrite it; the iterative I% solve takes the seeded 50 as its starting guess,
  // a wrong start inside the convergence basin, so that case proves the solver moves from a wrong start to 100.
  covSolveTvmTarget(target);
}

void covTvmPmt(uint16_t which) {
  // TVM with a non-zero payment (annuity), driving the annuity-factor and payment-timing branches of calculateFV / calculatePV / calculatePMT. Consistent problem: N=3,
  // I%/yr=100 (periodic rate 100%), PV=0, PMT=-100. In END mode this is an ordinary annuity, FV = -PMT*((1+i)^N-1)/i = 700;
  // with FARG >= 10 the driver clears FLAG_ENDPMT (BEGIN mode, annuity due), where the payment-timing factor (1+i) lifts the future value to FV = 700*(1+i) = 1400 and
  // covers the p=1 branch. FARG selects the target (0/10=FV, 1/11=PV, 2/12=PMT); the result is asserted in X.
  const bool_t begin = which >= 10;
  const uint16_t sel = begin ? (uint16_t)(which - 10) : which;
  if(begin) {
    clearSystemFlag(FLAG_ENDPMT);
  }
  else {
    setSystemFlag(FLAG_ENDPMT);
  }
  covStoTvm(3,    RESERVED_VARIABLE_NPPER);
  covStoTvm(100,  RESERVED_VARIABLE_IPONA);
  covStoTvm(0,    RESERVED_VARIABLE_PV);
  covStoTvm(-100, RESERVED_VARIABLE_PMT);
  covStoTvm(begin ? 1400 : 700, RESERVED_VARIABLE_FV);
  covStoTvm(1,    RESERVED_VARIABLE_PPERONA);
  covStoTvm(1,    RESERVED_VARIABLE_CPERONA);
  currentSolverStatus = 0;
  uint16_t target;
  switch(sel) {
    case 1:  target = RESERVED_VARIABLE_PV;  break;
    case 2:  target = RESERVED_VARIABLE_PMT; break;
    default: target = RESERVED_VARIABLE_FV;  break;
  }
  // All three targets here are closed-form, so the wrong seed is overwritten.
  covSolveTvmTarget(target);
  setSystemFlag(FLAG_ENDPMT);  // restore the default payment-timing mode (test isolation)
}

void covEff(uint16_t unusedButMandatoryParameter) {
  // Effective annual interest rate: fnEff computes 100*((iA/(100*cperA)+1)^cperA - 1) from the nominal rate and the compounding frequency, leaving it in X.
  // Nominal 100%/yr compounded 2/yr -> effective 100*((1+0.5)^2-1) = 125%.
  covStoTvm(100, RESERVED_VARIABLE_IPONA);
  covStoTvm(2,   RESERVED_VARIABLE_CPERONA);
  fnEff(NOPARAM);
}

void covEffToI(uint16_t unusedButMandatoryParameter) {
  // Inverse of fnEff: the nominal annual rate from the effective rate (read from X) and the compounding frequency (CPER/a).
  // fnEffToI computes iA = 100*cperA*((EFF/100+1)^(1/cperA)-1); EFF=125% compounded 2/yr gives ((1.25+1)^(1/2)-1)*100*2 = (1.5-1)*200 = 100% nominal - the exact
  // inverse of the covEff case (100% nominal, 2/yr -> 125% effective).
  covStoTvm(2, RESERVED_VARIABLE_CPERONA);
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  int32ToReal34(125, REGISTER_REAL34_DATA(REGISTER_X));
  fnEffToI(NOPARAM);
}

// Common loan state for the amortisation drivers: PV=1000, I%/yr=100 (periodic rate 100%), PMT=-1200, END mode, one payment and compounding period per year. Period 1:
// interest 1000, principal 200, balance 800; period 2 (start 800): interest 800, principal 400, balance 400.
static void covSeedAmortLoan(void) {
  setSystemFlag(FLAG_ENDPMT);
  covStoTvm(3,     RESERVED_VARIABLE_NPPER);
  covStoTvm(100,   RESERVED_VARIABLE_IPONA);
  covStoTvm(1000,  RESERVED_VARIABLE_PV);
  covStoTvm(-1200, RESERVED_VARIABLE_PMT);
  covStoTvm(1,     RESERVED_VARIABLE_PPERONA);
  covStoTvm(1,     RESERVED_VARIABLE_CPERONA);
}

static void covRunAmort(uint16_t sel) {
  if(sel == 1) {
    fnAmortPrn(NOPARAM);
  }
  else if(sel == 2) {
    fnAmortInt(NOPARAM);
  }
  else {
    fnAmortBal(NOPARAM);
  }
}

void covAmort(uint16_t which) {
  // Amortisation schedule for the shared loan. FARG encodes two axes: band = FARG/10 selects the mode (0 = single-period analytical,
  // 1 = HP12C period-by- period balance path amortBalAt_HP12C, 2 = multi-period analytical range [1,2]); sel = FARG%10 selects the figure (0 = BAL, 1 = PRN, 2 = INT).
  // The result is left in X. The periodic rate 1.00 is exact, so the HP12C rounded schedule matches the analytical one.
  // For the range [1,2] the interest and principal accumulate over both periods (INT=1000+800=1800, PRN=200+400=600) and BAL is the balance after period 2 (=400),
  // driving the multi-period accumulation loop the single-period cases skip.
  const uint16_t band = which / 10;
  const uint16_t sel  = which % 10;
  covSeedAmortLoan();
  if(band == 1) {
    setSystemFlag(FLAG_AMORT_HP12C);
  }
  else {
    clearSystemFlag(FLAG_AMORT_HP12C);
  }
  amortP1 = 1;
  amortP2 = (band == 2) ? 2 : 1;
  covRunAmort(sel);
  clearSystemFlag(FLAG_AMORT_HP12C);  // restore the default amortisation mode (test isolation)
  amortP1 = 1;
  amortP2 = 1;                        // restore the default amortisation range (test isolation)
}

void covAmortNext(uint16_t which) {
  // Advance the amortisation range with fnAmortNext, then read period 2. From the [1,1] range fnAmortNext moves it to [2,2] (amortP1=amortP2=2);
  // period 2 has interest 800, principal 400 and balance 400. FARG selects the figure (0=BAL, 1=PRN, 2=INT).
  covSeedAmortLoan();
  clearSystemFlag(FLAG_AMORT_HP12C);
  amortP1 = 1;
  amortP2 = 1;
  fnAmortNext(NOPARAM);
  covRunAmort(which);
  amortP1 = 1;
  amortP2 = 1;                        // restore the default amortisation range (test isolation)
}



// Wrappers exposing the SI round-trip halves (custom conversion pairs) to generated tests in conversionsSI.txt; the param is the convertPairs[] item number
void covConvToSI(uint16_t itemNr) {
  runConversionToSI((int16_t)itemNr);
}

void covConvFromSI(uint16_t itemNr) {
  runConversionFromSI((int16_t)itemNr);
}

// SHA-256 (FIPS 180-4), self-contained, to hash the SNAP bitmap.
typedef struct { uint32_t s[8]; uint64_t len; uint8_t buf[64]; uint32_t n; } sha256Ctx;

static uint32_t sha256Ror(uint32_t x, int r) { return (x >> r) | (x << (32 - r)); }

static void sha256Block(sha256Ctx *c, const uint8_t *p) {
  static const uint32_t K[64] = {
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2};
  uint32_t w[64], a, b, cc, d, e, f, g, h, t1, t2;
  for(int i = 0; i < 16; i++) {
    w[i] = ((uint32_t)p[i*4] << 24) | ((uint32_t)p[i*4+1] << 16) | ((uint32_t)p[i*4+2] << 8) | p[i*4+3];
  }
  for(int i = 16; i < 64; i++) {
    uint32_t s0 = sha256Ror(w[i-15], 7) ^ sha256Ror(w[i-15], 18) ^ (w[i-15] >> 3);
    uint32_t s1 = sha256Ror(w[i-2], 17) ^ sha256Ror(w[i-2], 19) ^ (w[i-2] >> 10);
    w[i] = w[i-16] + s0 + w[i-7] + s1;
  }
  a=c->s[0]; b=c->s[1]; cc=c->s[2]; d=c->s[3]; e=c->s[4]; f=c->s[5]; g=c->s[6]; h=c->s[7];
  for(int i = 0; i < 64; i++) {
    uint32_t S1 = sha256Ror(e, 6) ^ sha256Ror(e, 11) ^ sha256Ror(e, 25);
    uint32_t ch = (e & f) ^ (~e & g);
    t1 = h + S1 + ch + K[i] + w[i];
    uint32_t S0 = sha256Ror(a, 2) ^ sha256Ror(a, 13) ^ sha256Ror(a, 22);
    uint32_t maj = (a & b) ^ (a & cc) ^ (b & cc);
    t2 = S0 + maj;
    h=g; g=f; f=e; e=d+t1; d=cc; cc=b; b=a; a=t1+t2;
  }
  c->s[0]+=a; c->s[1]+=b; c->s[2]+=cc; c->s[3]+=d; c->s[4]+=e; c->s[5]+=f; c->s[6]+=g; c->s[7]+=h;
}

static void sha256Init(sha256Ctx *c) {
  c->s[0]=0x6a09e667; c->s[1]=0xbb67ae85; c->s[2]=0x3c6ef372; c->s[3]=0xa54ff53a;
  c->s[4]=0x510e527f; c->s[5]=0x9b05688c; c->s[6]=0x1f83d9ab; c->s[7]=0x5be0cd19;
  c->len = 0; c->n = 0;
}

static void sha256Update(sha256Ctx *c, const uint8_t *p, size_t len) {
  c->len += len;
  while(len) {
    uint32_t k = 64 - c->n;
    if(k > len) { k = (uint32_t)len; }
    memcpy(c->buf + c->n, p, k);
    c->n += k; p += k; len -= k;
    if(c->n == 64) { sha256Block(c, c->buf); c->n = 0; }
  }
}

static void sha256Final(sha256Ctx *c, char outHex[65]) {
  uint64_t bits = c->len * 8; // message length captured before padding
  uint8_t pad = 0x80, zero = 0;
  sha256Update(c, &pad, 1);
  while(c->n != 56) { sha256Update(c, &zero, 1); }
  uint8_t lenb[8];
  for(int i = 0; i < 8; i++) { lenb[i] = (uint8_t)(bits >> (56 - i*8)); }
  sha256Update(c, lenb, 8);
  for(int i = 0; i < 8; i++) { sprintf(outHex + i*8, "%08X", c->s[i]); }
  outHex[64] = 0;
}

// Plot-regression drivers (graphs_cov.txt). Each graph is rendered by XEQ of a small RPN program ending in SNAP (G1..G4, staged by covLoadGraphPgms), i.e.
// in the real programmed UI context, and pinned by a SHA-256 of the SNAP screen capture:
//   EQN Draw_y^x: G1 - X.SWAP the formula in from the X string, then Draw it;
//   ADV PLTf    : G2 - program plot (PGMPLT ->00 via R00, then PLTf 'x');
//   PLOT PLSTAT : G3 - statistics plot from the seeded sums;
//   REGR SCATR  : G4 - scatter plot from the same seeded sums;
//   REGR HISTO  : (not yet programmable, interactive only).
//   REGR ASSESS : (not yet programmable, interactive only).
// covBmpName numbers the bitmap (c47plotTest<N>.bmp) so every graph stays on disk; covHashBmp pins its SHA-256.
void covEqSet(uint16_t which) {
  // Stage the fallback formula G1 swaps out; also allocates the formula slot and the solver variable. The plot range comes from the stack on the XEQ line.
  if(numberOfFormulae == 0) {
    fnEqNew(NOPARAM);
  }
  setEquation(currentFormula, which == 1 ? "SIN(X)" : "X^2");
  currentSolverVariable = findOrAllocateNamedVariable("X");
}

// Two-byte program opcode: the high bit on the first byte marks that a second opcode byte follows (the decoder's (op & 0x80) convention).
#define OP2(itm) (uint8_t)(((itm) >> 8) | 0x80), (uint8_t)((itm) & 0xff)

void covLoadGraphPgms(uint16_t unusedButMandatoryParameter) {
  // Build and import the graph programs through the official loader like program S (covLoadPgm). G2..G4 match the numbered bitmaps they snap.
  static const uint8_t pgmG1[] = {
    ITM_LBL, STRING_LABEL_VARIABLE, 2, 'G', '1',    // LBL "G1"
    OP2(ITM_XSWAP),                                 // X.SWAP (formula <-> X string)
    ITM_DROP,                                       // DROP the old formula text
    OP2(ITM_DRAW),                                  // Draw y^x
    OP2(ITM_PLTFCNS),                               // PLTFCNS (plot menu up, as interactive Draw shows it)
    OP2(ITM_SNAP),                                  // SNAP
    OP2(ITM_END),                                   // END
  };
  static const uint8_t pgmG2[] = {
    ITM_LBL, STRING_LABEL_VARIABLE, 2, 'G', '2',    // LBL "G2"
    OP2(ITM_PGMPLT), INDIRECT_REGISTER, 0,          // PGMPLT ->00
    OP2(ITM_PLTf), STRING_LABEL_VARIABLE, 1, 'x',   // PLTf 'x'
    OP2(ITM_SNAP),                                  // SNAP
    OP2(ITM_END),                                   // END
  };
  static const uint8_t pgmG3[] = {
    ITM_LBL, STRING_LABEL_VARIABLE, 2, 'G', '3',    // LBL "G3"
    OP2(ITM_PLOT_STAT),                             // PLSTAT
    OP2(ITM_SNAP),                                  // SNAP
    OP2(ITM_END),                                   // END
  };
  static const uint8_t pgmG4[] = {
    ITM_LBL, STRING_LABEL_VARIABLE, 2, 'G', '4',    // LBL "G4"
    OP2(ITM_PLOT_SCATR),                            // SCATR
    OP2(ITM_SNAP),                                  // SNAP
    OP2(ITM_END),                                   // END
  };
  covWriteAndLoadPgm(pgmG1, sizeof(pgmG1));
  covWriteAndLoadPgm(pgmG2, sizeof(pgmG2));
  covWriteAndLoadPgm(pgmG3, sizeof(pgmG3));
  covWriteAndLoadPgm(pgmG4, sizeof(pgmG4));
}

// The on-disk name of graph <which>'s bitmap. covBmpName points the SNAP capture at it and covHashBmp reads it back; one builder keeps the two from drifting.
static void covPlotBmpName(char *out, uint16_t which) {
  sprintf(out, "c47plotTest%u.bmp", which);
}

void covBmpName(uint16_t which) {
  // Point the next SNAP capture at c47plotTest<FARG>.bmp; the override is consumed by one capture, so this runs before each XEQ of a graph program.
  covPlotBmpName(_ioFileNameOverride, which);
}

void covHashBmp(uint16_t which) {
  // SHA-256 the numbered Test bitmap the graph program's SNAP just wrote; the 64-digit hex lands in X for the corpus to compare against the reference.
  char bmpName[24];
  covPlotBmpName(bmpName, which);
  FILE *bmp = fopen(bmpName, "rb");
  if(bmp == NULL) {
    printf("\nCannot open %s\n", bmpName);
    abortTest();
    return;
  }
  sha256Ctx ctx;
  sha256Init(&ctx);
  uint8_t buf[4096];
  size_t got;
  while((got = fread(buf, 1, sizeof(buf), bmp)) > 0) {
    sha256Update(&ctx, buf, got);
  }
  fclose(bmp);
  char hex[65];
  sha256Final(&ctx, hex);
  reallocateRegister(REGISTER_X, dtString, TO_BLOCKS(stringByteLength(hex) + 1), amNone);
  strcpy(REGISTER_STRING_DATA(REGISTER_X), hex);
  calcMode = CM_NORMAL; // leave the graph view so a reordered corpus is unaffected
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
      else if(!strcmp(l+3, "PLINE")) {
        if(r[0] == '0') {
          clearSystemFlag(FLAG_PLINE);
        }
        else {
          setSystemFlag(FLAG_PLINE);
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

  else if(strcmp(l, "FARG") == 0) {
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
      convertReal34RegisterToDateRegister(regist, regist, false);  //no !YYsystem needed here
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
    label = findNamedLabel(r + 1, GLOBAL_LABELS);
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
  if(real34IsZero(a) && real34IsZero(b)) {
    return real34IsNegative(a) == real34IsNegative(b);
  }

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
      convertReal34RegisterToDateRegister(TEMP_REGISTER_1, TEMP_REGISTER_1, false);  //no !YYsystem needed here
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
            isCheckingEigenvectors = (funcType == FUNC_TO_TEST) && (funcToTest == fnEigenvectors) && (regist == REGISTER_X) && (rows == cols);
            xcopy(r, r + i + 1, strlen(r + i + 1) + 1);
            if(isCheckingEigenvectors) {
              x1 = malloc(REAL34_SIZE_IN_BYTES * cols);
              for(int col = 0; col < cols; ++col) {
                real34SetZero(x1 + col);
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
            isCheckingEigenvectors = (funcType == FUNC_TO_TEST) && (funcToTest == fnEigenvectors) && (regist == REGISTER_X) && (rows == cols);
            xcopy(r, r + i + 1, strlen(r + i + 1) + 1);
            if(isCheckingEigenvectors) {
              xr1 = malloc(REAL_SIZE_IN_BYTES(75) * cols);
              xi1 = malloc(REAL_SIZE_IN_BYTES(75) * cols);
              xf1 = malloc(sizeof(bool_t) * cols);
              for(int col = 0; col < cols; ++col) {
                realSetZero(xr1 + col);
                realSetZero(xi1 + col);
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
                    real34SetZero(&expectedImag34);
                    realSetZero(&expectedImag);
                  }

                  if(isCheckingEigenvectors && (!realIsZero(xr1 + element % cols) || !realIsZero(xi1 + element % cols))) {
                    real_t er, ei, tmpe, tol;
                    real34ToReal(const34_1e_32, &tol);

                    real34ToReal(VARIABLE_REAL34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(regist) + element), &er);
                    real34ToReal(VARIABLE_IMAG34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(regist) + element), &ei);

                    // check for possible real or pure imaginary
                    C47_WP34S_Atan2(&ei, &er, &tmpe, &ctxtReal39); // arctangent: check for possible pure imaginary
                    realSetPositiveSign(&tmpe);
                    if(WP34S_RelativeError(&tmpe, const39_piOn2, &tol, &ctxtReal39)) {
                      realSetZero(&er); // possible pure imaginary
                    }
                    C47_WP34S_Atan2(&er, &ei, &tmpe, &ctxtReal39); // arccotangent: check for possible real
                    realSetPositiveSign(&tmpe);
                    if(WP34S_RelativeError(&tmpe, const39_piOn2, &tol, &ctxtReal39)) {
                      realSetZero(&ei); // possible real
                    }

                    realToReal34(&er, VARIABLE_REAL34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(regist) + element));
                    realToReal34(&ei, VARIABLE_IMAG34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(regist) + element));

                    realCopy(&expectedReal, &er);
                    realCopy(&expectedImag, &ei);
                    mulComplexComplex(&er, &ei, xr1 + element % cols, xi1 + element % cols, &er, &ei, &ctxtReal39);

                    // check for possible real or pure imaginary
                    C47_WP34S_Atan2(&ei, &er, &tmpe, &ctxtReal39); // arctangent: check for possible pure imaginary
                    realSetPositiveSign(&tmpe);
                    if(WP34S_RelativeError(&tmpe, const39_piOn2, &tol, &ctxtReal39)) {
                      realSetZero(&er); // possible pure imaginary
                    }
                    C47_WP34S_Atan2(&er, &ei, &tmpe, &ctxtReal39); // arccotangent: check for possible real
                    realSetPositiveSign(&tmpe);
                    if(WP34S_RelativeError(&tmpe, const39_piOn2, &tol, &ctxtReal39)) {
                      realSetZero(&ei); // possible real
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



static void checkGmpMemFreed(void) {
  if(gmpMemInBytes != 0) {
    char tmpMsg[1000];
    sprintf(tmpMsg, "\ngmpMemInBytes should be 0 but it is %" PRIu64 "! Check to ensure allocated long integers have been freed.", (uint64_t)gmpMemInBytes);
    errorf(tmpMsg);
    fflush(stderr);
    exit(-1);
  }
}



void callFunction(void) {
  lastErrorCode = 0;

  switch(funcType) {
    case FUNC_TO_TEST:
      if((indexOfItems[functionIndex].status & US_STATUS) == US_ENABLED) {
        saveForUndo();
      }
      else if((indexOfItems[functionIndex].status & US_STATUS) == US_CANCEL) {
        thereIsSomethingToUndo = false;
      }

      funcToTest(functionParameter);
      checkGmpMemFreed();
      break;

    case FUNC_ITEM:
      // Real dispatch chain: reallyRunFunction does undo and stack lift itself, so the mimicry below is skipped
      reallyRunFunction(functionIndex, indexOfItems[functionIndex].param);
      checkGmpMemFreed();
      break;

    default: ;
  }

  if(funcType != FUNC_ITEM && lastErrorCode == 0) {
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
    funcType = FUNC_TO_TEST;

    if(funcToTest == runPgm) {
      functionIndex = ITM_XEQ;
    }
    else if(funcTestNoParam[function].coverageDriver) {
      functionIndex = ITM_NOP; // testSuite-local coverage drivers, not catalog items
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



// ITM_ name table for the Item: directive, lazily parsed from items.h in the source tree so it cannot go stale
typedef struct {
  char    name[64];
  int32_t number;
} itemName_t;

static itemName_t *itemNameTable = NULL;
static int32_t     itemNameCount = 0;

static void loadItemNameTable(void) {
  char  itemsHPath[2100], buffer[1000];
  FILE *itemsH;

  snprintf(itemsHPath, sizeof(itemsHPath), "%s/../../c47/items.h", filePath);
  itemsH = fopen(itemsHPath, "rb");
  if(itemsH == NULL) {
    printf("Cannot open file %s to resolve ITM_ names!\n", itemsHPath);
    exit(-1);
  }

  while(fgets(buffer, sizeof(buffer), itemsH) != NULL) {
    itemName_t entry;
    memcpy(entry.name, "ITM_", 4);
    if(sscanf(buffer, " #define ITM_%59s %d", entry.name + 4, &entry.number) == 2) {
      if((itemNameCount % 500) == 0) {
        itemNameTable = realloc(itemNameTable, (itemNameCount + 500) * sizeof(itemName_t));
        if(itemNameTable == NULL) {
          printf("Out of memory building the ITM_ name table!\n");
          exit(-1);
        }
      }
      itemNameTable[itemNameCount++] = entry;
    }
  }

  fclose(itemsH);
}



static int32_t lookupItemName(const char *name) {
  if(itemNameTable == NULL) {
    loadItemNameTable();
  }

  for(int32_t i=0; i<itemNameCount; i++) {
    if(strcmp(itemNameTable[i].name, name) == 0) {
      return itemNameTable[i].number;
    }
  }

  return -1;
}



void itemToCall(char *itemSpec) {
  int32_t itemNr;

  // Default to a NOP so a following Out: after a failed Item: does not rerun the previous function
  functionIndex = ITM_NOP;
  funcToTest    = fnNop;
  funcType      = FUNC_TO_TEST;

  if(strncmp(itemSpec, "ITM_", 4) == 0) {
    itemNr = lookupItemName(itemSpec);
    if(itemNr < 0) {
      printf("\nCannot find %s in items.h: check spelling of the item name and remember the name is case sensitive\n", itemSpec);
      abortTest();
      return;
    }
  }
  else if('0' <= itemSpec[0] && itemSpec[0] <= '9') {
    char *end;
    itemNr = (int32_t)strtol(itemSpec, &end, 10);
    if(*end != 0) {
      printf("\nItem number has trailing characters: %s\n", itemSpec);
      abortTest();
      return;
    }
  }
  else {
    printf("\nItem must be an ITM_ name or an item number: %s\n", itemSpec);
    abortTest();
    return;
  }

  if(itemNr <= 0 || itemNr >= LAST_ITEM) {
    printf("\nItem number %d is out of range (1..%d)\n", itemNr, LAST_ITEM - 1);
    abortTest();
    return;
  }

  if(indexOfItems[itemNr].func == itemToBeCoded) {
    printf("\nItem %d (%s) is not an implemented function\n", itemNr, itemSpec);
    abortTest();
    return;
  }

  functionIndex = itemNr;
  funcType      = FUNC_ITEM;
}



void abortTest(void) {
  if(noFailForNow) {
    noFailForNow = false;
    failedTests++;
    successfulTests--;
  }
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
  if(startTime == 0) {
    printf("Timer was not started.\n");
    return;
  }
  time_t endTime = time(NULL);
  double elapsed = difftime(endTime, startTime);
  if(elapsed > 1) {
    printf("\n -- Processing time > 1 second: %d s\n", (int)elapsed);
  }
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
    if(i >= 5 && (strncmp(line, "FUNC: ", 6) == 0 || strncmp(line, "DESC: ", 6) == 0 || strncmp(line, "ITEM: ", 6) == 0)) {
      break;
    }
    if(i >= 12 && (strncmp(line, "DESC_PREFIX: ", 13) == 0 || strncmp(line, "DESC_SUFFIX: ", 13) == 0)) {
      break;
    }
  }


  if(strncmp(line, "TIMER: ", 7) == 0) {
    printf("%s", line);
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

  else if(strncmp(line, "ITEM: ", 6) == 0) {
    //printf("%s\n", line);
    itemToCall(line + 6);
  }

  else if(strncmp(line, "OUT: ", 5) == 0) {
    //printf("%s\n", line);
    if(timedFunction && timerOperation) {
      startTimer();
    }
    callFunction();
    if(timedFunction && timerOperation) {
      timedFunction = true;
      stopTimerAndPrint();
    }

    if((numTestsFile++ % 10) == 0 && !timedFunction &&!timerOperation) {
      printf(".");
    }

    numTestsTotal++;
    successfulTests++;
    noFailForNow = true;
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
  funcType = FUNC_TO_TEST;

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
                         catalogName, i - 1,  catalog[i - 1],             i,       catalog[i], cmp);
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

  numTestsTotal   = 0;
  successfulTests = 0;
  failedTests     = 0;

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
  printf("* NUMBER OF TESTS %6d           *\n", numTestsTotal);
  printf("* %6d TEST%c PASSED SUCCESSFULLY *\n", successfulTests, successfulTests == 1 ? ' ' : 'S');
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
  gmpMemInBytes  = 0;
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
