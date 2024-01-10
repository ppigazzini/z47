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
 * \file xnor.h
 ***********************************************/
#if !defined(XNOR_H)
  #define XNOR_H

  #include "defines.h"
  #include <stdint.h>

  void fnLogicalXnor(uint16_t unusedButMandatoryParameter);

  #if(EXTRA_INFO_ON_CALC_ERROR == 1)
    void xnorError24  (void);
  #else // (EXTRA_INFO_ON_CALC_ERROR == 1)
    #define xnorError24 typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void xnorError31  (void);
  void xnorLonILonI (void);
  void xnorLonIReal (void);
  void xnorRealLonI (void);
  void xnorRealReal (void);
  void xnorShoIShoI (void);
#endif // !XNOR_H
