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
 * \file store.h
 */
#if !defined(STORE_H)
  #define STORE_H

  #include "typeDefinitions.h"
  #include <stdint.h>

  bool_t       regInRange    (uint16_t r);
  /**
   * Stores X in an other register.
   *
   * \param[in] registerNumber
   */
  void         fnStore       (uint16_t r);

  /**
   * Adds X to a register.
   *
   * \param[in] registerNumber
   */
  void         fnStoreAdd    (uint16_t r);

  /**
   * Subtracts X from a register.
   *
   * \param[in] registerNumber
   */
  void         fnStoreSub    (uint16_t r);

  /**
   * Multiplies a register by X.
   *
   * \param[in] registerNumber
   */
  void         fnStoreMult   (uint16_t r);

  /**
   * Divides a register by X.
   *
   * \param[in] registerNumber
   */
  void         fnStoreDiv    (uint16_t r);

  /**
   * Keeps in a register min(X, register).
   *
   * \param[in] registerNumber
   */
  void         fnStoreMin    (uint16_t r);

  /**
   * Keeps in a register max(X, register).
   *
   * \param[in] registerNumber
   */
  void         fnStoreMax    (uint16_t r);

  /**
   * Stores the configuration.
   *
   * \param[in] regist
   */
  void         fnStoreConfig (uint16_t r);

  /**
   * Stores the stack.
   *
   * \param[in] regist
   */
  void         fnStoreStack  (uint16_t r);

  /**
   * Stores X in the element I,J of a matrix.
   *
   * \param[in] regist
   */
  void         fnStoreElement(uint16_t unusedButMandatoryParameter);

  /**
   * Stores X and Y in the indexes I and J.
   *
   * \param[in] regist
   */
  void         fnStoreIJ     (uint16_t unusedButMandatoryParameter);
#endif // !STORE_H
