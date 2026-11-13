// SPDX-License-Identifier: GPL-3.0-only
//
// C reference side of the focused wp34s differentials.
//
// The atan, atan2, circular-trig and real-trig-primitive lanes compare the Zig
// owners against upstream's own mathematics/wp34s.c. Linked as it is, that file
// would collide with the Zig owners' exports of the same names, so it is
// included here with every global it defines renamed to oracle_<name>. Its
// calls between those globals rename with them, so the reference is c43's code
// throughout. The list is the object's own symbol table (nm --defined-only -g
// of wp34s.c compiled alone), not a header: a global the list misses is a
// duplicate symbol at link time, never a silent stand-in.

#define C47_WP34S_Acos                    oracle_C47_WP34S_Acos
#define C47_WP34S_Asin                    oracle_C47_WP34S_Asin
#define C47_WP34S_Atan                    oracle_C47_WP34S_Atan
#define C47_WP34S_Atan2                   oracle_C47_WP34S_Atan2
#define C47_WP34S_Cvt2RadSinCosTan        oracle_C47_WP34S_Cvt2RadSinCosTan
#define C47_WP34S_SinCosTanTaylor         oracle_C47_WP34S_SinCosTanTaylor
#define WP34S_AbsoluteError               oracle_WP34S_AbsoluteError
#define WP34S_AdjustPositiveUnderflow     oracle_WP34S_AdjustPositiveUnderflow
#define WP34S_ArcSinh                     oracle_WP34S_ArcSinh
#define WP34S_ArcTanh                     oracle_WP34S_ArcTanh
#define WP34S_AtLeastContext              oracle_WP34S_AtLeastContext
#define WP34S_Bernoulli                   oracle_WP34S_Bernoulli
#define WP34S_BetaCalculationContext      oracle_WP34S_BetaCalculationContext
#define WP34S_BetaFraction                oracle_WP34S_BetaFraction
#define WP34S_BigMod                      oracle_WP34S_BigMod
#define WP34S_CheckDistributionParameters oracle_WP34S_CheckDistributionParameters
#define WP34S_ComplexAbsError             oracle_WP34S_ComplexAbsError
#define WP34S_ComplexGamma                oracle_WP34S_ComplexGamma
#define WP34S_ComplexLambertW             oracle_WP34S_ComplexLambertW
#define WP34S_ComplexLnGamma              oracle_WP34S_ComplexLnGamma
#define WP34S_ComplexRelativeError        oracle_WP34S_ComplexRelativeError
#define WP34S_DistributionProbabilityData oracle_WP34S_DistributionProbabilityData
#define WP34S_Erf                         oracle_WP34S_Erf
#define WP34S_Erfc                        oracle_WP34S_Erfc
#define WP34S_ExpM1                       oracle_WP34S_ExpM1
#define WP34S_Factorial                   oracle_WP34S_Factorial
#define WP34S_Gamma                       oracle_WP34S_Gamma
#define WP34S_GammaP                      oracle_WP34S_GammaP
#define WP34S_HasCancellation             oracle_WP34S_HasCancellation
#define WP34S_InverseComplexW             oracle_WP34S_InverseComplexW
#define WP34S_InverseW                    oracle_WP34S_InverseW
#define WP34S_IsPositiveFinite            oracle_WP34S_IsPositiveFinite
#define WP34S_LambertW                    oracle_WP34S_LambertW
#define WP34S_LanczosSum                  oracle_WP34S_LanczosSum
#define WP34S_Ln                          oracle_WP34S_Ln
#define WP34S_Ln1P                        oracle_WP34S_Ln1P
#define WP34S_LnExtended                  oracle_WP34S_LnExtended
#define WP34S_LnGamma                     oracle_WP34S_LnGamma
#define WP34S_Log                         oracle_WP34S_Log
#define WP34S_Log10                       oracle_WP34S_Log10
#define WP34S_Log1pMinus                  oracle_WP34S_Log1pMinus
#define WP34S_Logxy                       oracle_WP34S_Logxy
#define WP34S_MarkPositive                oracle_WP34S_MarkPositive
#define WP34S_MarkProbability             oracle_WP34S_MarkProbability
#define WP34S_Mod                         oracle_WP34S_Mod
#define WP34S_OrthoPoly                   oracle_WP34S_OrthoPoly
#define WP34S_Real34Remainder             oracle_WP34S_Real34Remainder
#define WP34S_RelativeError               oracle_WP34S_RelativeError
#define WP34S_SetPowerOfTen               oracle_WP34S_SetPowerOfTen
#define WP34S_SinhCosh                    oracle_WP34S_SinhCosh
#define WP34S_Tanh                        oracle_WP34S_Tanh
#define WP34S_TinyOddSeries               oracle_WP34S_TinyOddSeries
#define WP34S_Zeta                        oracle_WP34S_Zeta
#define WP34S_betai                       oracle_WP34S_betai
#define distributions                     oracle_distributions
#define fnDistribution                    oracle_fnDistribution
#define mod2Pi                            oracle_mod2Pi
#define reduceAngleToRange                oracle_reduceAngleToRange

#include "../../../upstream/src/c47/mathematics/wp34s.c"
