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
 * \file mean.h
 ***********************************************/
#if !defined(VARIANCE_H)
  #define VARIANCE_H

  #include "realType.h"
  #include "typeDefinitions.h"
  #include <stdint.h>

  void fnWeightedSampleStdDev     (uint16_t unusedButMandatoryParameter);
  void fnWeightedPopulationStdDev (uint16_t unusedButMandatoryParameter);
  void fnWeightedStandardError    (uint16_t unusedButMandatoryParameter);
  void fnSampleStdDev             (uint16_t unusedButMandatoryParameter);
  void fnPopulationStdDev         (uint16_t unusedButMandatoryParameter);
  void fnStandardError            (uint16_t unusedButMandatoryParameter);
  void fnGeometricSampleStdDev    (uint16_t unusedButMandatoryParameter);
  void fnGeometricPopulationStdDev(uint16_t unusedButMandatoryParameter);
  void fnGeometricStandardError   (uint16_t unusedButMandatoryParameter);
  void fnPopulationCovariance     (uint16_t unusedButMandatoryParameter);
  void fnSampleCovariance         (uint16_t unusedButMandatoryParameter);
  void fnCoefficientDetermination (uint16_t unusedButMandatoryParameter);
  void fnMinExpStdDev             (uint16_t unusedButMandatoryParameter);
  void fnStatSMI                  (real_t *SMI);
  void fnStatR                    (real_t *RR, real_t *SXY, real_t *SX, real_t *SY);
  void fnStatSXY                  (real_t *SXY);
  void fnStatSX_SY                (real_t *SX, real_t *SY);
  bool_t processCurvefitSA        (real_t *SA0, real_t *SA1);
  void fnStatSa                   (uint16_t unusedButMandatoryParameter);
#endif // !VARIANCE_H
