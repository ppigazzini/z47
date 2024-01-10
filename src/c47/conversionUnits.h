/* This file is part of 43S.
 *
 * 43S is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * 43S is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with 43S.  If not, see <http://www.gnu.org/licenses/>.
 */

/********************************************//**
 * \file conversionUnits.h
 ***********************************************/
#if !defined(CONVERSIONUNITS_H)
  #define CONVERSIONUNITS_H

  #include <stdint.h>

  // Temperature
  void fnCvtCToF      (uint16_t unusedButMandatoryParameter);
  void fnCvtFToC      (uint16_t unusedButMandatoryParameter);

  // Duration
  void fnCvtYearS     (uint16_t multiplyDivide);

  // Energy
  void fnCvtCalJ      (uint16_t multiplyDivide);
  void fnCvtBtuJ      (uint16_t multiplyDivide);
  void fnCvtWhJ       (uint16_t multiplyDivide);

  // Power
  void fnCvtHpeW      (uint16_t multiplyDivide);
  void fnCvtHpukW     (uint16_t multiplyDivide);
  void fnCvtHpmW      (uint16_t multiplyDivide);

  // Force
  void fnCvtLbfN      (uint16_t multiplyDivide);

  // Pressure
  void fnCvtBarPa     (uint16_t multiplyDivide);
  void fnCvtPsiPa     (uint16_t multiplyDivide);
  void fnCvtInhgPa    (uint16_t multiplyDivide);
  void fnCvtMmhgPa    (uint16_t multiplyDivide);
  void fnCvtTorrPa    (uint16_t multiplyDivide);
  void fnCvtAtmPa     (uint16_t multiplyDivide);

  // Mass
  void fnCvtLbKg      (uint16_t multiplyDivide);
  void fnCvtCwtKg     (uint16_t multiplyDivide);
  void fnCvtOzG       (uint16_t multiplyDivide);
  void fnCvtStoneKg   (uint16_t multiplyDivide);
  void fnCvtShortcwtKg(uint16_t multiplyDivide);
  void fnCvtTrozG     (uint16_t multiplyDivide);
  void fnCvtTonKg     (uint16_t multiplyDivide);
  void fnCvtShorttonKg(uint16_t multiplyDivide);
  void fnCvtCaratG    (uint16_t multiplyDivide);
  void fnCvtLiangKg   (uint16_t multiplyDivide);
  void fnCvtJinKg     (uint16_t multiplyDivide);

  // Length
  void fnCvtAuM       (uint16_t multiplyDivide);
  void fnCvtMiKm       (uint16_t multiplyDivide);
  void fnCvtLyM       (uint16_t multiplyDivide);
  void fnCvtNmiKm     (uint16_t multiplyDivide);
  void fnCvtNmiMi     (uint16_t multiplyDivide);
  void fnCvtFtM       (uint16_t multiplyDivide);
  void fnCvtPcM       (uint16_t multiplyDivide);
  void fnCvtInchMm    (uint16_t multiplyDivide);
  void fnCvtSfeetM    (uint16_t multiplyDivide);
  void fnCvtYardM     (uint16_t multiplyDivide);
  void fnCvtPointMm   (uint16_t multiplyDivide);
  void fnCvtFathomM   (uint16_t multiplyDivide);
  void fnCvtLiM       (uint16_t multiplyDivide);
  void fnCvtChiM      (uint16_t multiplyDivide);
  void fnCvtYinM      (uint16_t multiplyDivide);
  void fnCvtCunM      (uint16_t multiplyDivide);
  void fnCvtZhangM    (uint16_t multiplyDivide);
  void fnCvtFenM      (uint16_t multiplyDivide);
  void fnCvtMileM     (uint16_t multiplyDivide);
  void fnCvtNMiM      (uint16_t multiplyDivide);

  // Volume
  void fnCvtGalukL    (uint16_t multiplyDivide);
  void fnCvtGalusL    (uint16_t multiplyDivide);
  void fnCvtFlozukMl  (uint16_t multiplyDivide);
  void fnCvtFlozusMl  (uint16_t multiplyDivide);
  void fnCvtQuartL    (uint16_t multiplyDivide);
  void fnCvtBarrelM3  (uint16_t multiplyDivide);

  // Area
  void fnCvtAcreHa    (uint16_t multiplyDivide);
  void fnCvtAcreusHa  (uint16_t multiplyDivide);
  void fnCvtHectareM2 (uint16_t multiplyDivide);
  void fnCvtMuM2      (uint16_t multiplyDivide);
  void fnCvtMi2Km2    (uint16_t multiplyDivide);
  void fnCvtNmi2Km2   (uint16_t multiplyDivide);

  // ...
  void fnCvtRatioDb   (uint16_t tenOrTwenty);
  void fnCvtDbRatio   (uint16_t tenOrTwenty);
  void fnCvtLbfftNm   (uint16_t multiplyDivide);

  // Speed
  void fnCvtKmphmps   (uint16_t multiplyDivide);
  void fnCvtRpmDegps  (uint16_t multiplyDivide);
  void fnCvtMphmps    (uint16_t multiplyDivide);
  void fnCvtRpmRadps  (uint16_t multiplyDivide);
  void fnCvtFpstokph  (uint16_t multiplyDivide);
  void fnCvtFpstomps  (uint16_t multiplyDivide);

  // Angle
  void fnCvtDegRad    (uint16_t multiplyDivide);
  void fnCvtDegGrad   (uint16_t multiplyDivide);
  void fnCvtGradRad   (uint16_t multiplyDivide);

  // FFF
  void fnCvtFurtom    (uint16_t multiplyDivide);
  void fnCvtFtntos    (uint16_t multiplyDivide);
  void fnCvtFpftomps  (uint16_t multiplyDivide);
  void fnCvtBrdstom   (uint16_t multiplyDivide);
  void fnCvtFirtokg   (uint16_t multiplyDivide);
  void fnCvtFpftokph  (uint16_t multiplyDivide);
  void fnCvtBrdstoin  (uint16_t multiplyDivide);
  void fnCvtFirtolb   (uint16_t multiplyDivide);
  void fnCvtFpftomph  (uint16_t multiplyDivide);

  //YMMV
  void fnL100Tokml    (uint16_t multiplyDivide);
  void fnKmletok100K  (uint16_t multiplyDivide);
  void fnK100Ktokmk   (uint16_t multiplyDivide);
  void fnL100Tomgus   (uint16_t multiplyDivide);
  void fnMgeustok100M (uint16_t multiplyDivide);
  void fnK100Ktok100M (uint16_t multiplyDivide);
  void fnL100Tomguk   (uint16_t multiplyDivide);
  void fnMgeuktok100M (uint16_t multiplyDivide);
  void fnK100Mtomik   (uint16_t multiplyDivide);


#endif // !CONVERSIONUNITS_H
