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
 * \file solve.h
 ***********************************************/
#if !defined(SOLVE_H)
  #define SOLVE_H

  #include "realType.h"
  #include "typeDefinitions.h"
  #include <stdint.h>

  void fnPgmSlv          (uint16_t label);
  void fnSolve           (uint16_t labelOrVariable);
  void fnSolveVar        (uint16_t unusedButMandatoryParameter);

  /**
   * Solves an equation f(x) = 0 stored as a program.
   *
   * \param[in]  variable   Register number where the unknown is stored
   * \param[in]  y          1st guess of the unknown
   * \param[in]  x          2nd guess of the unknown
   * \param[out] resZ       The last value f(x)
   * \param[out] resY       The 2nd last root tested
   * \param[out] resX       The resulting root x
   * \return                0 if a root found,
   *                        1 if large delta and opposite signs (may be a pole),
   *                        2 if the solver reached a local extremum,
   *                        3 if at least one of the initial guesses is out of the domain,
   *                        4 if the function values look constant
   */
  int solver             (calcRegister_t variable, const real34_t *y, const real34_t *x, real34_t *resZ, real34_t *resY, real34_t *resX);
#endif // !SOLVE_H
