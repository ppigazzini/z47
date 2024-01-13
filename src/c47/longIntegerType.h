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
 * \file longIntegerType.h
 */
#if !defined(LONGINTEGERTYPE_H)
  #define LONGINTEGERTYPE_H

  #include "defines.h"
  #include "typeDefinitions.h"

  #include <gmp.h>
  #include <stdlib.h>

  typedef mpz_t longInteger_t;

  #define REGISTER_LONG_INTEGER_DATA(a)       ((void *)(getRegisterDataPointer(a) + 1)) // Memory pointer to the long integer of a register
  #define longIntegerToUInt(op, uint)         do { uint = mpz_get_ui(op); } while(0)
  #define longIntegerToInt(op, int)           do { int  = mpz_get_si(op); } while(0)
  #define longIntegerIsZeroRegister(regist)   (getRegisterLongIntegerSign(regist) == LI_ZERO)
  //#define longIntegerIsZeroRegister(regist)   (*REGISTER_DATA_MAX_LEN(regist) == 0)

  enum { LIMB_SIZE = sizeof(mp_limb_t) };

  static inline size_t longIntegerSizeInBytes(mpz_srcptr li)                                                                               {return (abs((li)->_mp_size) * LIMB_SIZE);}
  static inline void longIntegerInit(mpz_ptr op)                                                                                           {mpz_init(op);}
  static inline void longIntegerInitSizeInBits(mpz_ptr op, mp_bitcnt_t bits)                                                               {mpz_init2(op, bits);}
  static inline void uIntToLongInteger(unsigned long int source, mpz_ptr destination)                                                      {mpz_set_ui(destination, source);}
  static inline void intToLongInteger(signed long int source, mpz_ptr destination)                                                         {mpz_set_si(destination, source);}
  static inline void longIntegerCopy(mpz_srcptr source, mpz_ptr destination)                                                               {mpz_set(destination, source);}                       // Previous implementation: mpz_add_ui(destination, source, 0);
  static inline int stringToLongInteger(const char *source, int radix, mpz_ptr destination)                                                {return mpz_set_str(destination, source, radix);}
  static inline void longIntegerChangeSign(mpz_ptr op)                                                                                     {(op)->_mp_size = -((op)->_mp_size);}
  static inline void longIntegerSetPositiveSign(mpz_ptr op)                                                                                {(op)->_mp_size = abs((op)->_mp_size);}
  static inline void longIntegerSetNegativeSign(mpz_ptr op)                                                                                {(op)->_mp_size = -abs((op)->_mp_size);}
  static inline void longIntegerSetZero(mpz_ptr op)                                                                                        {mpz_clear(op);mpz_init(op);}                         // Previous implementation: (op)->_mp_size = 0;
  static inline bool_t longIntegerIsZero(mpz_srcptr op)                                                                                    {return ((op)->_mp_size == 0);}
  static inline bool_t longIntegerIsPositive(mpz_srcptr op)                                                                                {return ((op)->_mp_size >  0);}
  static inline bool_t longIntegerIsPositiveOrZero(mpz_srcptr op)                                                                          {return ((op)->_mp_size >= 0);}
  static inline bool_t longIntegerIsNegative(mpz_srcptr op)                                                                                {return ((op)->_mp_size <  0);}
  static inline bool_t longIntegerIsNegativeOrZero(mpz_srcptr op)                                                                          {return ((op)->_mp_size <= 0);}
  static inline bool_t longIntegerIsEven(mpz_srcptr op)                                                                                    {return mpz_even_p(op);}
  static inline bool_t longIntegerIsOdd(mpz_srcptr op)                                                                                     {return mpz_odd_p(op);}
  static inline int longIntegerSign(mpz_srcptr op)                                                                                         {return mpz_sgn(op);}
  static inline longIntegerSign_t longIntegerSignTag(mpz_srcptr op)                                                                        {return ((op)->_mp_size == 0 ? LI_ZERO : ((op)->_mp_size > 0 ? LI_POSITIVE : LI_NEGATIVE));}
  static inline size_t longIntegerBits(mpz_srcptr op)                                                                                      {return mpz_sizeinbase(op, 2);}
  static inline size_t longIntegerBase10Digits(mpz_srcptr op)                                                                              {return mpz_sizeinbase(op, 10);}

  /**
   * Determines whether the long integer is probably prime.
   *
   * \returns A number indicating the prime status:
   *   - 0 = composite
   *   - 1 = probably prime
   *   - 2 = prime
   * A composite number will be identified as a prime with a probability of
   * less than 4^(-15).
   */
  static inline int longIntegerProbabPrime(mpz_srcptr op)                                                                                  {return mpz_probab_prime_p(op, 15);}
  static inline void longIntegerFree(mpz_ptr op)                                                                                           {mpz_clear(op);}
  static inline int longIntegerCompare(mpz_srcptr op1, mpz_srcptr op2)                                                                     {return mpz_cmp(op1, op2);}
  static inline void longIntegerDivide(mpz_srcptr op1, mpz_srcptr op2, mpz_ptr result)                                                     {mpz_tdiv_q(result, op1, op2);}                       // op1/op2 => result*op2 + remainder == op1
  static inline void longIntegerDivideQuotientRemainder(mpz_srcptr op1, mpz_srcptr op2, mpz_ptr quotient, mpz_ptr remainder)               {mpz_tdiv_qr(quotient, remainder, op1, op2);}         // op1/op2 => quotient*op2 + remainder == op1
  static inline void longIntegerDivideRemainder(mpz_srcptr op1, mpz_srcptr op2, mpz_ptr remainder)                                         {mpz_tdiv_r(remainder, op1, op2);}
  static inline void longIntegerModulo(mpz_srcptr op1, mpz_srcptr op2, mpz_ptr result)                                                     {mpz_mod(result, op1, op2);}
  static inline void longInteger2Pow(mp_bitcnt_t exp, mpz_ptr result)                                                                      {mpz_setbit(result, exp);}                            // result = 2^exp (result MUST be 0 before)
  static inline void longIntegerDivide2(mpz_srcptr op, mpz_ptr result)                                                                     {mpz_div_2exp(result, op, 1);}                        // result = op / 2
  static inline void longIntegerDivide2Exact(mpz_srcptr op, mpz_ptr result)                                                                {mpz_divexact_ui(result, op, 2);}                     // result = op / 2
  static inline void longIntegerSquareRoot(mpz_srcptr op, mpz_ptr result)                                                                  {mpz_sqrt(result, op);}
  static inline int longIntegerRoot(mpz_srcptr op, unsigned long int n, mpz_ptr result)                                                    {return mpz_root(result, op, n);}
  static inline int longIntegerPerfectSquare(mpz_srcptr op)                                                                                {return mpz_perfect_square_p(op);}
  static inline void longIntegerMultiply2(mpz_srcptr op, mpz_ptr result)                                                                   {mpz_mul_2exp(result, op, 1);}                        // result = op * 2
  static inline void longIntegerLeftShift(mpz_srcptr op, mp_bitcnt_t number, mpz_ptr result)                                               {mpz_mul_2exp(result, op, number);}                   // result = op * 2^number
  static inline int longIntegerCompareUInt(mpz_srcptr op, unsigned long int uint)                                                          {return mpz_cmp_ui(op, uint);}
  static inline int longIntegerCompareInt(mpz_srcptr op, signed long int sint)                                                             {return mpz_cmp_si(op, sint);}
  static inline void longIntegerAddUInt(mpz_srcptr op, unsigned long int uint, mpz_ptr result)                                             {mpz_add_ui(result, op, uint);}
  static inline void longIntegerSubtractUInt(mpz_srcptr op, unsigned long int uint, mpz_ptr result)                                        {mpz_sub_ui(result, op, uint);}
  static inline void longIntegerMultiplyUInt(mpz_srcptr op, unsigned long int uint, mpz_ptr result)                                        {mpz_mul_ui(result, op, uint);}
  static inline unsigned long int longIntegerDivideRemainderUInt(mpz_srcptr op, unsigned long int uint, mpz_ptr result, mpz_ptr remainder) {return mpz_tdiv_qr_ui(remainder, result, op, uint);} // op/uint => result*uint + remainder == op
  static inline void longIntegerDivideUInt(mpz_srcptr op, unsigned long int uint, mpz_ptr result)                                          {mpz_tdiv_q_ui(result, op, uint);}                    // op/uint => result*uint + remainder == op
  static inline void longIntegerPowerUIntUInt(unsigned long int base, unsigned long int exponent, mpz_ptr result)                          {mpz_ui_pow_ui(result, base, exponent);}              // result = base ^ exponent
  static inline void longIntegerPowerModulo(mpz_srcptr base, mpz_srcptr exponent, mpz_srcptr modulo, mpz_ptr result)                       {mpz_powm(result, base, exponent, modulo);}           // result = base ^ exponent
  static inline void longIntegerPowerUIntModulo(mpz_srcptr base, unsigned long int exponent, mpz_srcptr modulo, mpz_ptr result)            {mpz_powm_ui(result, base, exponent, modulo);}        // result = base ^ exponent
  static inline unsigned long int longIntegerModuloUInt(mpz_srcptr op, unsigned long int uint)                                             {return mpz_fdiv_ui(op, uint);}                       // result = op mod uint, 0 <= result < uint
  static inline void longIntegerGcd(mpz_srcptr op1, mpz_srcptr op2, mpz_ptr result)                                                        {mpz_gcd(result, op1, op2);}
  static inline void longIntegerLcm(mpz_srcptr op1, mpz_srcptr op2, mpz_ptr result)                                                        {mpz_lcm(result, op1, op2);}
  static inline void longIntegerFactorial(unsigned long int op, mpz_ptr result)                                                            {mpz_fac_ui(result, op);}
  static inline int longIntegerIsPrime(mpz_srcptr currentNumber)                                                                           {return mpz_probab_prime_p(currentNumber, 25);}
  static inline void longIntegerNextPrime(mpz_srcptr currentNumber, mpz_ptr nextPrime)                                                     {mpz_nextprime(nextPrime, currentNumber);}
  static inline void longIntegerFibonacci(unsigned long int op, mpz_ptr result)                                                            {mpz_fib_ui(result, op);}
#endif // !LONGINTEGERTYPE_H
