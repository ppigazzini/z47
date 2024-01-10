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
 * \file manage.h
 ***********************************************/
#if !defined(MANAGE_H)
  #define MANAGE_H

  #include "items.h"
  #include "typeDefinitions.h"
  #include <stdint.h>

  uint32_t _getProgramSize                     (void);
  void scanLabelsAndPrograms                   (void);
  void defineCurrentProgramFromGlobalStepNumber(int16_t globalStepNumber);
  void defineCurrentProgramFromCurrentStep     (void);
  void deleteStepsFromTo                       (uint8_t *from, uint8_t *to);
  void fnClPAll                                (uint16_t confirmation);
  void fnClP                                   (uint16_t label);
  void fnPem                                   (uint16_t unusedButMandatoryParameter);
  void scrollPemBackwards                      (void);
  void scrollPemForwards                       (void);
  void pemAlpha                                (int16_t item);
  void pemCloseAlphaInput                      (void);
  void pemAddNumber                            (int16_t item);
  void pemCloseNumberInput                     (void);
  void insertStepInProgram                     (int16_t func);
  void addStepInProgram                        (int16_t func);

  calcRegister_t findNamedLabel                (const char *labelName);
  calcRegister_t findNamedLabelWithDuplicate   (const char *labelName, int16_t dupNum);
  uint16_t       getNumberOfSteps              (void);

  bool_t         isAtEndOfPrograms             (const uint8_t *step); // check for .END.
  bool_t         checkOpCodeOfStep             (const uint8_t *step, uint16_t op);

  static inline bool_t isAtEndOfProgram        (const uint8_t *step) { // check for END
    return checkOpCodeOfStep(step, ITM_END);
  }
#endif // !MANAGE_H
