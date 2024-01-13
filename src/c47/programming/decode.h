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
 * \file decode.h
 ***********************************************/
#if !defined(DECODE_H)
  #define DECODE_H

  #include "typeDefinitions.h"
  #include <stdint.h>

  void decodeOneStep          (uint8_t *step);
  void decodeOneStepXEQM      (uint8_t *step);
  #if !defined(DMCP_BUILD)
    void listPrograms         (void);
    void listLabelsAndPrograms(void);
  #endif // !DMCP_BUILD
#endif // !DECODE_H
