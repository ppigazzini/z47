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
 * \file ui/matrixEditor.c
 ***********************************************/

#if !defined(MATRIXEDITOR_H)
  #define MATRIXEDITOR_H

  #include "typeDefinitions.h"

  #if !defined(TESTSUITE_BUILD)
    #define MATRIX_LINE_WIDTH            380
    //#define MATRIX_LINE_WIDTH_LARGE      120
    //#define MATRIX_LINE_WIDTH_SMALL      93
    //#define MATRIX_CHAR_LEN              30
    #define MATRIX_MAX_ROWS              5
    #define MATRIX_MAX_COLUMNS           11
  #endif // TESTSUITE_BUILD

  /**
   * Opens the Matrix Editor.
   *
   * \param[in] regist
   */
  void       fnEditMatrix                   (uint16_t regist);

  /**
   * Recalls old element in the Matrix Editor.
   *
   * \param[in] unusedParamButMandatory
   */
  void       fnOldMatrix                    (uint16_t unusedParamButMandatory);

  /**
   * Go to an element in the Matrix Editor.
   *
   * \param[in] unusedParamButMandatory
   */
  void       fnGoToElement                  (uint16_t unusedParamButMandatory);

  void       fnGoToRow                      (uint16_t row);
  void       fnGoToColumn                   (uint16_t col);

  /**
   * Set grow mode.
   *
   * \param[in] growFlag
   */
  void       fnSetGrowMode                  (uint16_t growFlag);

  /**
   * Increment or decrement of register I as row pointer.
   *
   * \param[in] mode
   */
  void       fnIncDecI                      (uint16_t mode);

  /**
   * Increment or decrement of register J as column pointer.
   *
   * \param[in] mode
   */
  void       fnIncDecJ                      (uint16_t mode);

  /**
   * Insert a row.
   *
   * \param[in] unusedParamButMandatory
   */
  void       fnInsRow                       (uint16_t unusedParamButMandatory);

  /**
   * Delete a row.
   *
   * \param[in] unusedParamButMandatory
   */
  void       fnDelRow                       (uint16_t unusedParamButMandatory);

  #if !defined(TESTSUITE_BUILD)
    int16_t  getIRegisterAsInt              (bool_t asArrayPointer);
    int16_t  getJRegisterAsInt              (bool_t asArrayPointer);
    void     setIRegisterAsInt              (bool_t asArrayPointer, int16_t toStore);
    void     setJRegisterAsInt              (bool_t asArrayPointer, int16_t toStore);

    bool_t   wrapIJ                         (uint16_t rows, uint16_t cols);
  #endif // TESTSUITE_BUILD

#endif // !MATRIXEDITOR_H
