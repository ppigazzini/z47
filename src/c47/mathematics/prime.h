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
 * \file prime.h
 ***********************************************/
#if !defined(PRIME_H)
  #define PRIME_H

  #include <stdint.h>

  void fnIsPrime      (uint16_t unusedButMandatoryParameter);
  void fnNextPrime    (uint16_t unusedButMandatoryParameter);
  void fnPrimeFactors (uint16_t unusedButMandatoryParameter);


  #define M_EULER_SIGMA_0  0  // k = 0
  #define M_EULER_SIGMA_1  1  // k = 1
  #define M_EULER_SIGMA_2  2  // k > 1
//#define M_EULER_SIGMA_p  3  //proper
//#define M_EULER_SIGMA_pk 4  //proper genereralized
  #define M_FACTORS        5
  void fnEvPFacts     (uint16_t unusedButMandatoryParameter);

  void fnEulPhi       (uint16_t unusedButMandatoryParameter);
#endif // !PRIME_H
