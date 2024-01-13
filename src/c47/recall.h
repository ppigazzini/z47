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

/**
 * \file recall.h
 */
#if !defined(RECALL_H)
  #define RECALL_H

  #include <stdint.h>

  /**
   * Recalls a register in X.
   *
   * \param[in] regist
   */
  void         fnRecall       (uint16_t r);

  /**
   * Recalls register L in X.
   *
   * \param[in] unusedButMandatoryParameter
   */
  void         fnLastX        (uint16_t unusedButMandatoryParameter);

  /**
   * Adds a register to X.
   *
   * \param[in] regist
   */
  void         fnRecallAdd    (uint16_t r);

  /**
   * Subtracts a register from X.
   *
   * \param[in] regist
   */
  void         fnRecallSub    (uint16_t r);

  /**
   * Multiplies X by a register.
   *
   * \param[in] regist
   */
  void         fnRecallMult   (uint16_t r);

  /**
   * Divides X by a register.
   *
   * \param[in] regist
   */
  void         fnRecallDiv    (uint16_t r);

  /**
   * Keeps in X min(X, register).
   *
   * \param[in] regist
   */
  void         fnRecallMin    (uint16_t r);

  /**
   * Keeps in X max(X, register).
   *
   * \param[in] regist
   */
  void         fnRecallMax    (uint16_t r);

  /**
   * Recalls a configuration.
   *
   * \param[in] regist
   */
  void         fnRecallConfig (uint16_t r);

  /**
   * Recalls a stack.
   *
   * \param[in] regist
   */
  void         fnRecallStack  (uint16_t r);

  /**
   * Recalls the matrix element I,J in X.
   *
   * \param[in] regist
   */
  void         fnRecallElement(uint16_t unusedButMandatoryParameter);

  /**
   * Recalls the indexes I and J in X and Y.
   *
   * \param[in] regist
   */
  void         fnRecallIJ     (uint16_t unusedButMandatoryParameter);
#endif // !RECALL_H
