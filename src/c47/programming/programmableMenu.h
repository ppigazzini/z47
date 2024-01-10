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
 * \file programmableMenu.h
 ***********************************************/
#if !defined(PROGRAMMABLEMENU_H)
  #define PROGRAMMABLEMENU_H

  #include <stdint.h>

  void fnKeyGtoXeq       (uint16_t keyNum);
  void fnKeyGto          (uint16_t unusedButMandatoryParameter);
  void fnKeyXeq          (uint16_t unusedButMandatoryParameter);
  void fnProgrammableMenu(uint16_t unusedButMandatoryParameter);
  void fnClearMenu       (uint16_t unusedButMandatoryParameter);

  #if !defined(TESTSUITE_BUILD)
    void keyGto            (uint16_t keyNum, uint16_t label);
    void keyXeq            (uint16_t keyNum, uint16_t label);
  #endif // !TESTSUITE_BUILD
#endif // !PROGRAMMABLEMENU_H
