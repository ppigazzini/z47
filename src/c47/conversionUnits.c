// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file conversionUnits.c
 ***********************************************/

#include "conversionUnits.h"

#include "browsers/fontBrowser.h"
#include "constantPointers.h"
#include "dateTime.h"
#include "registers.h"
#include "c47Extensions/addons.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "mathematics/10pow.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"


#define inverting true
#define noninverting false



static void unitConversion(const real_t * const coefficient, uint16_t multiplyDivide, bool_t invert) {
  real_t reX;

  if(!getRegisterAsReal(REGISTER_X, &reX))
    return;

  if(!saveLastX()) {
    return;
  }

  if(invert && realIsZero(&reX)) {
    if(getSystemFlag(FLAG_SPCRES)) {
      convertRealToResultRegister(realIsNegative(&reX) ? const_minusInfinity : const_plusInfinity, REGISTER_X, amNone);
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function unitConversion:", "cannot calculate divide by zero", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }

  if(invert) {
    realDivide(const_1, &reX, &reX, &ctxtReal39);
  }

  if(multiplyDivide == multiply) {
    realMultiply(&reX, coefficient, &reX, &ctxtReal39);
  }
  else {
    realDivide(&reX, coefficient, &reX, &ctxtReal39);
  }

  convertRealToResultRegister(&reX, REGISTER_X, amNone);
  adjustResult(REGISTER_X, false, false, -1, -1, -1);
}



/********************************************//**
 * \brief Converts °Celcius to °Fahrenheit: (°Celcius * 1,8) + 32.
 * Refreshes the stack. This is the exact formula.
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnCvtCToF(uint16_t unusedButMandatoryParameter) {
  real_t reX;

  if(!getRegisterAsReal(REGISTER_X, &reX))
    return;

  if(!saveLastX()) {
    return;
  }

  realFMA(&reX, const_9on5, const_32, &reX, &ctxtReal39);

  convertRealToResultRegister(&reX, REGISTER_X, amNone);

  adjustResult(REGISTER_X, false, false, -1, -1, -1);
}



/********************************************//**
 * \brief Converts °Fahrenheit to °Celcius: (°Fahrenheit - 32) / 1,8.
 * Refreshes the stack. This is the exact formula.
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnCvtFToC(uint16_t unusedButMandatoryParameter) {
  real_t reX;

  if(!getRegisterAsReal(REGISTER_X, &reX))
    return;

  if(!saveLastX()) {
    return;
  }

  realSubtract(&reX, const_32, &reX, &ctxtReal39);
  realDivide(&reX, const_9on5, &reX, &ctxtReal39);

  convertRealToResultRegister(&reX, REGISTER_X, amNone);

  adjustResult(REGISTER_X, false, false, -1, -1, -1);
}


void fnCvtYearS(uint16_t multiplyDivide) {
  unitConversion(const_YearToS, multiplyDivide, noninverting);
}


void fnCvtCalJ(uint16_t multiplyDivide) {
  unitConversion(const_CalToJ, multiplyDivide, noninverting);
}


void fnCvtBtuJ(uint16_t multiplyDivide) {
  unitConversion(const_BtuToJ, multiplyDivide, noninverting);
}


void fnCvtWhJ(uint16_t multiplyDivide) {
  unitConversion(const_WhToJ, multiplyDivide, noninverting);
}


void fnCvtHpeW(uint16_t multiplyDivide) {
  unitConversion(const_HpeToW, multiplyDivide, noninverting);
}


void fnCvtHpmW(uint16_t multiplyDivide) {
  unitConversion(const_HpmToW, multiplyDivide, noninverting);
}


void fnCvtHpukW(uint16_t multiplyDivide) {
  unitConversion(const_HpukToW, multiplyDivide, noninverting);
}


void fnCvtLbfN(uint16_t multiplyDivide) {
  unitConversion(const_LbfToN, multiplyDivide, noninverting);
}


void fnCvtBarPa(uint16_t multiplyDivide) {
  unitConversion(const_BarToPa, multiplyDivide, noninverting);
}


void fnCvtPsiPa(uint16_t multiplyDivide) {
  unitConversion(const_PsiToPa, multiplyDivide, noninverting);
}


void fnCvtInhgPa(uint16_t multiplyDivide) {
  unitConversion(const_InhgToPa, multiplyDivide, noninverting);
}


void fnCvtMmhgPa(uint16_t multiplyDivide) {
  unitConversion(const_MmhgToPa, multiplyDivide, noninverting);
}


void fnCvtTorrPa(uint16_t multiplyDivide) {
  unitConversion(const_TorrToPa, multiplyDivide, noninverting);
}


void fnCvtAtmPa(uint16_t multiplyDivide) {
  unitConversion(const_AtmToPa, multiplyDivide, noninverting);
}


void fnCvtLbKg(uint16_t multiplyDivide) {
  unitConversion(const_LbToKg, multiplyDivide, noninverting);
}


void fnCvtCwtKg(uint16_t multiplyDivide) {
  unitConversion(const_CwtToKg, multiplyDivide, noninverting);
}


void fnCvtOzG(uint16_t multiplyDivide) {
  unitConversion(const_OzToG, multiplyDivide, noninverting);
}


void fnCvtStoneKg(uint16_t multiplyDivide) {
  unitConversion(const_StoneToKg, multiplyDivide, noninverting);
}


void fnCvtShortcwtKg(uint16_t multiplyDivide) {
  unitConversion(const_ShortcwtToKg, multiplyDivide, noninverting);
}


void fnCvtTrozG(uint16_t multiplyDivide) {
  unitConversion(const_TrozToG, multiplyDivide, noninverting);
}


void fnCvtTonKg(uint16_t multiplyDivide) {
  unitConversion(const_TonToKg, multiplyDivide, noninverting);
}


void fnCvtShorttonKg(uint16_t multiplyDivide) {
  unitConversion(const_ShorttonToKg, multiplyDivide, noninverting);
}


void fnCvtCaratG(uint16_t multiplyDivide) {
  unitConversion(const_CaratToG, multiplyDivide, noninverting);
}


void fnCvtLiangKg(uint16_t multiplyDivide) {
  unitConversion(const_20, multiplyDivide, noninverting);
}


void fnCvtJinKg(uint16_t multiplyDivide) {
  unitConversion(const_2, multiplyDivide, noninverting);
}


void fnCvtAuM(uint16_t multiplyDivide) {
  unitConversion(const_AuToM, multiplyDivide, noninverting);
}


void fnCvtMiKm(uint16_t multiplyDivide) {
  unitConversion(const_MiToKm, multiplyDivide, noninverting);
}


void fnCvtLyM(uint16_t multiplyDivide) {
  unitConversion(const_LyToM, multiplyDivide, noninverting);
}


void fnCvtNmiKm(uint16_t multiplyDivide) {
  unitConversion(const_NmiToKm, multiplyDivide, noninverting);
}

void fnCvtNmiMi(uint16_t multiplyDivide) {
  unitConversion(const_NmiToMi, multiplyDivide, noninverting);
}

void fnCvtFtM(uint16_t multiplyDivide) {
  unitConversion(const_FtToM, multiplyDivide, noninverting);
}


void fnCvtPcM(uint16_t multiplyDivide) {
  unitConversion(const_PcToM, multiplyDivide, noninverting);
}


void fnCvtInchMm(uint16_t multiplyDivide) {
  unitConversion(const_InchToMm, multiplyDivide, noninverting);
}


void fnCvtSfeetM(uint16_t multiplyDivide) {
  unitConversion(const_SfeetToM, multiplyDivide, noninverting);
}


void fnCvtYardM(uint16_t multiplyDivide) {
  unitConversion(const_YardToM, multiplyDivide, noninverting);
}


void fnCvtPointMm(uint16_t multiplyDivide) {
  unitConversion(const_PointToMm, multiplyDivide, noninverting);
}


void fnCvtFathomM(uint16_t multiplyDivide) {
  unitConversion(const_FathomToM, multiplyDivide, noninverting);
}


void fnCvtLiM(uint16_t multiplyDivide) {
  unitConversion(const_LiToM, multiplyDivide, noninverting);
}


void fnCvtChiM(uint16_t multiplyDivide) {
  unitConversion(const_3, multiplyDivide, noninverting);
}


void fnCvtYinM(uint16_t multiplyDivide) {
  unitConversion(const_YinToM, multiplyDivide, noninverting);
}


void fnCvtCunM(uint16_t multiplyDivide) {
  unitConversion(const_CunToM, multiplyDivide, noninverting);
}


void fnCvtZhangM(uint16_t multiplyDivide) {
  unitConversion(const_ZhangToM, multiplyDivide, noninverting);
}


void fnCvtFenM(uint16_t multiplyDivide) {
  unitConversion(const_FenToM, multiplyDivide, noninverting);
}


void fnCvtMileM(uint16_t multiplyDivide) {
  unitConversion(const_MiToM, multiplyDivide, noninverting);
}


void fnCvtNMiM(uint16_t multiplyDivide) {
  unitConversion(const_NmiToM, multiplyDivide, noninverting);
}


void fnCvtGalukL(uint16_t multiplyDivide) {
  unitConversion(const_GalukToL, multiplyDivide, noninverting);
}


void fnCvtGalusL(uint16_t multiplyDivide) {
  unitConversion(const_GalusToL, multiplyDivide, noninverting);
}


void fnCvtFlozukMl(uint16_t multiplyDivide) {
  unitConversion(const_FlozukToMl, multiplyDivide, noninverting);
}


void fnCvtFlozusMl(uint16_t multiplyDivide) {
  unitConversion(const_FlozusToMl, multiplyDivide, noninverting);
}


void fnCvtBarrelM3(uint16_t multiplyDivide) {
  unitConversion(const_BarrelToM3, multiplyDivide, noninverting);
}


void fnCvtQuartL(uint16_t multiplyDivide) {
  unitConversion(const_QuartToL, multiplyDivide, noninverting);
}


void fnCvtAcreHa(uint16_t multiplyDivide) {
  unitConversion(const_AccreToHa, multiplyDivide, noninverting);
}


void fnCvtAcreusHa(uint16_t multiplyDivide) {
  unitConversion(const_AccreusToHa, multiplyDivide, noninverting);
}


void fnCvtHectareM2(uint16_t multiplyDivide) {
  unitConversion(const_10000, multiplyDivide, noninverting);
}


void fnCvtFt2Hectare(uint16_t multiplyDivide) {
  unitConversion(const_Ft2ToHa, multiplyDivide, noninverting);
}


void fnCvtFt2M2(uint16_t multiplyDivide) {
  unitConversion(const_Ft2ToM2, multiplyDivide, noninverting);
}


void fnCvtHectareKm2(uint16_t multiplyDivide) {
  real_t mm;
  int32ToReal(100,&mm);
  unitConversion(&mm, multiplyDivide == multiply ? divide : multiply, noninverting);
}


void fnCvtMuM2(uint16_t multiplyDivide) {
  unitConversion(const_MuToM2, multiplyDivide, noninverting);
}


void fnCvtLbfftNm(uint16_t multiplyDivide) {
  unitConversion(const_LbfftToNm, multiplyDivide, noninverting);
}

void fnCvtMi2Km2 (uint16_t multiplyDivide) {
  unitConversion(const_MiSqToKmSq, multiplyDivide, noninverting);
}

void fnCvtNmi2Km2(uint16_t multiplyDivide) {
  unitConversion(const_NmiSqToKmSq, multiplyDivide, noninverting);
}

void fnCvtKmphmps(uint16_t multiplyDivide) {
  unitConversion(const_Kmphmps, multiplyDivide, noninverting);
}

void fnCvtRpmDegps(uint16_t multiplyDivide) {
  unitConversion(const_RpmDegps, multiplyDivide, noninverting);
}

void fnCvtMphmps(uint16_t multiplyDivide) {
  unitConversion(const_Mphmps, multiplyDivide, noninverting);
}

void fnCvtRpmRadps(uint16_t multiplyDivide) {
  unitConversion(const_RpmRadps, multiplyDivide, noninverting);
}

void fnCvtDegRad(uint16_t multiplyDivide) {
  if(getRegisterDataType(REGISTER_X) == dtReal34 && (
    ((getRegisterAngularMode(REGISTER_X) == amDegree) && multiplyDivide == multiply) || ((getRegisterAngularMode(REGISTER_X) == amRadian) && multiplyDivide == divide) )) {
    setRegisterAngularMode(REGISTER_X, amNone);
  }
  unitConversion(const_DegRad, multiplyDivide, noninverting);
}

void fnCvtDegGrad(uint16_t multiplyDivide) {
  if(getRegisterDataType(REGISTER_X) == dtReal34 && (
    ((getRegisterAngularMode(REGISTER_X) == amDegree) && multiplyDivide == multiply) || ((getRegisterAngularMode(REGISTER_X) == amGrad) && multiplyDivide == divide) )) {
    setRegisterAngularMode(REGISTER_X, amNone);
  }
  unitConversion(const_DegGrad, multiplyDivide, noninverting);
}

void fnCvtGradRad(uint16_t multiplyDivide) {
  if(getRegisterDataType(REGISTER_X) == dtReal34 && (
    ((getRegisterAngularMode(REGISTER_X) == amGrad) && multiplyDivide == multiply) || ((getRegisterAngularMode(REGISTER_X) == amRadian) && multiplyDivide == divide) )) {
    setRegisterAngularMode(REGISTER_X, amNone);
  }
  unitConversion(const_GradRad, multiplyDivide, noninverting);
}


void fnCvtFurtom    (uint16_t multiplyDivide) {
  unitConversion(const_furToM,   multiplyDivide, noninverting);
}

void fnCvtFtntos    (uint16_t multiplyDivide) {
  unitConversion(const_ftnToS,   multiplyDivide, noninverting);
}

void fnCvtFpftomps  (uint16_t multiplyDivide) {
  unitConversion(const_fpfToMps, multiplyDivide, noninverting);
}

void fnCvtBrdstom   (uint16_t multiplyDivide) {
  unitConversion(const_brdsTom,  multiplyDivide, noninverting);
}

void fnCvtFirtokg   (uint16_t multiplyDivide) {
  unitConversion(const_firToKg,  multiplyDivide, noninverting);
}

void fnCvtFpftokph  (uint16_t multiplyDivide) {
  unitConversion(const_fpfToKph, multiplyDivide, noninverting);
}

void fnCvtBrdstoin  (uint16_t multiplyDivide) {
  unitConversion(const_brdsToIn, multiplyDivide, noninverting);
}

void fnCvtFirtolb   (uint16_t multiplyDivide) {
  unitConversion(const_firToLb,  multiplyDivide, noninverting);
}

void fnCvtFpftomph  (uint16_t multiplyDivide) {
  unitConversion(const_fpfToMph, multiplyDivide, noninverting);
}

void fnCvtFpstokph  (uint16_t multiplyDivide) {
  unitConversion(const_fpsToKph, multiplyDivide, noninverting);
}

void fnCvtFpstomps  (uint16_t multiplyDivide) {
  unitConversion(const_fpsToMps, multiplyDivide, noninverting);
}

void fnL100Tokml   (uint16_t multiplyDivide) {
  //note multiplyDivide is not used, as the formula is biderectional!
  //100 / value, both ways
  // 5 l/100km = 1/5 * 100 = 20 km/l and conversely 20 l/100km = 1/20 * 100 = 5 km/l
  unitConversion(const_100, multiply, inverting);
}

void fnKmletok100K   (uint16_t multiplyDivide) {
  //note multiplyDivide is not used, as the formula is biderectional!
  //100*liter_equivalent  / (value), both ways
  real_t factor;
  realMultiply(const_GaluseqE, const_100, &factor, &ctxtReal39);
  realDivide(&factor, const_GalusToL, &factor, &ctxtReal39);
  unitConversion(&factor, multiply, inverting);
}

void fnK100Ktokmk   (uint16_t multiplyDivide) {
  //note multiplyDivide is not used, as the formula is biderectional!
  //100 / value, both ways
  unitConversion(const_100, multiply, inverting);
}

void fnL100Tomgus   (uint16_t multiplyDivide) {
  //note multiplyDivide is not used, as the formula is biderectional!
  //100 *gallon_US/mile   /  (value), both ways
  real_t factor;
  realMultiply(const_100, const_GalusToL, &factor, &ctxtReal39);
  realDivide(&factor, const_MiToKm, &factor, &ctxtReal39);
  unitConversion(&factor, multiply, inverting);
}

void fnMgeustok100M   (uint16_t multiplyDivide) {
  //note multiplyDivide is not used, as the formula is biderectional!
  //100*gallon_US_equivalent / (value), both ways
  real_t factor;
  realMultiply(const_GaluseqE, const_100, &factor, &ctxtReal39);
  unitConversion(&factor, multiply, inverting);
}

void fnK100Ktok100M   (uint16_t multiplyDivide) {
  unitConversion(const_MiToKm, multiplyDivide, noninverting);
}

void fnL100Tomguk   (uint16_t multiplyDivide) {
  //note multiplyDivide is not used, as the formula is biderectional!
  //100*gallon_UK/mile  / (value), both ways
  real_t factor;
  realMultiply(const_100, const_GalukToL, &factor, &ctxtReal39);
  realDivide(&factor, const_MiToKm, &factor, &ctxtReal39);
  unitConversion(&factor, multiply, inverting);
}

void fnMgeuktok100M   (uint16_t multiplyDivide) {
  //note multiplyDivide is not used, as the formula is biderectional!
  //100*gallon_UK_equivalent  / (value), both ways
  //const_GalukToL / const_GalusToL * 33.7 * 100
  real_t factor;
  realMultiply(const_GaluseqE, const_100, &factor, &ctxtReal39);
  realMultiply(&factor, const_GalukToL, &factor, &ctxtReal39);
  realDivide(&factor, const_GalusToL, &factor, &ctxtReal39);
  unitConversion(&factor, multiply, inverting);
}

void fnK100Mtomik   (uint16_t multiplyDivide) {
  //note multiplyDivide is not used, as the formula is biderectional!
  //100 / value, both ways
  unitConversion(const_100, multiply, inverting);
}


void fnCvtHMSHR   (uint16_t multiplyDivide) {
  if(multiplyDivide == divide) {
    fnHMStoTM(0);
    fnToReal(0);
  }
  else {
    fnHRtoTM(0);
    fnFrom_ms(0);
  }
}





/********************************************//**
 * \brief Converts power or field ratio to dB
 * dB = (10 or 20) * log10((power or field) ratio) this is the exact formula
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnCvtRatioDb(uint16_t tenOrTwenty) { // ten: power ratio   twenty: field ratio
  real_t reX;

  if(!getRegisterAsReal(REGISTER_X, &reX))
    return;

  if(!saveLastX()) {
    return;
  }

  WP34S_Log10(&reX, &reX, &ctxtReal39);
  realMultiply(&reX, (tenOrTwenty == 10 ? const_10 : const_20), &reX, &ctxtReal39);

  convertRealToResultRegister(&reX, REGISTER_X, amNone);

  adjustResult(REGISTER_X, false, false, -1, -1, -1);
}



/********************************************//**
 * \brief Converts dB to power or field ratio
 * (power or field) ratio = 10^(dB / 10 or 20) this is the exact formula
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnCvtDbRatio(uint16_t tenOrTwenty) { // ten: power ratio   twenty: field ratio
  real_t reX;

  if(!getRegisterAsReal(REGISTER_X, &reX))
    return;

  if(!saveLastX()) {
    return;
  }

  realDivide(&reX, (tenOrTwenty == 10 ? const_10 : const_20), &reX, &ctxtReal39);
  realPower10(&reX, &reX, &ctxtReal39);

  convertRealToResultRegister(&reX, REGISTER_X, amNone);

  adjustResult(REGISTER_X, false, false, -1, -1, -1);
}
