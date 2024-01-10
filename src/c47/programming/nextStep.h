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
 * \file nextStep.h
 ***********************************************/
#if !defined(NEXTSTEP_H)
  #define NEXTSTEP_H

  #include "typeDefinitions.h"
  #include <stdint.h>

  uint8_t *findNextStep            (uint8_t *step);
  uint8_t *findKey2ndParam         (uint8_t *step);
  uint8_t *findPreviousStep        (uint8_t *step);
  void     defineCurrentStep       (void);
  void     defineFirstDisplayedStep(void);
  void     fnBst                   (uint16_t unusedButMandatoryParameter);
  void     fnSst                   (uint16_t unusedButMandatoryParameter);
  void     fnBack                  (uint16_t numberOfSteps);
  void     fnSkip                  (uint16_t numberOfSteps);
  void     fnCase                  (uint16_t regist);
#endif // !NEXTSTEP_H
