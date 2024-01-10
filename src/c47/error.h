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
 * \file error.h
 ***********************************************/
#if !defined(ERROR_H)
  #define ERROR_H

  #include "defines.h"
  #include "typeDefinitions.h"
  #include <stdint.h>

  void fnRaiseError             (uint16_t errorCode);
  void fnErrorMessage           (uint16_t unusedButMandatoryParameter);

  #if !defined(TESTSUITE_BUILD)
    void displayBugScreen     (const char *msg);
  #endif // TESTSUITE_BUILD

  void displayCalcErrorMessage  (uint8_t errorCode, calcRegister_t errMessageRegisterLine, calcRegister_t errRegisterLine);
  void displayDomainErrorMessage(uint8_t errorCode, calcRegister_t errMessageRegisterLine, calcRegister_t errRegisterLine);
  void moreInfoOnError          (const char *m1, const char *m2, const char *m3, const char *m4);
  #if(EXTRA_INFO_ON_CALC_ERROR != 1)
    void typeError              (void);
  #endif // (EXTRA_INFO_ON_CALC_ERROR != 1)
#endif // !ERROR_H
