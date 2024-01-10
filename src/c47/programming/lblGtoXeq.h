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
 * \file lblGtoXeq.h
 ***********************************************/
#if !defined(LBLGTOXEQ_H)
  #define LBLGTOXEQ_H

  #include "typeDefinitions.h"
  #include <stdint.h>

  void    fnGoto            (uint16_t label);
  void    fnGotoDot         (uint16_t globalStepNumber);
  void    fnExecute         (uint16_t label);
  void    fnExecutePlusSkip (uint16_t label);
  void    fnReturn          (uint16_t skip);
  void    fnRunProgram      (uint16_t unusedButMandatoryParameter);
  void    fnStopProgram     (uint16_t unusedButMandatoryParameter);
  void    fnCheckLabel      (uint16_t label);
  void    fnIsTopRoutine    (uint16_t unusedButMandatoryParameter);

  /**
   * Executes one step
   *
   * \param[in]  step   Instruction pointer
   * \return            -1 if already the pointer is set,
   *                    0 if the end of the routine reached,
   *                    1 if the routine continues,
   *                    > 1 if the next step shall be skipped
   */
  int16_t executeOneStep    (uint8_t *step);
  void    runProgram        (bool_t singleStep, uint16_t menuLabel);
  void    execProgram       (uint16_t label);

  void    goToGlobalStep    (int32_t step);
  void    goToPgmStep       (uint16_t program, uint16_t step);
#endif // !LBLGTOXEQ_H
