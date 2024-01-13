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
 * \file elliptic.h
 ***********************************************/
#if !defined(ELLIPTIC_H)
  #define ELLIPTIC_H

  #include "realType.h"
  #include <stdint.h>

  void fnJacobiSn       (uint16_t unusedButMandatoryParameter);
  void fnJacobiCn       (uint16_t unusedButMandatoryParameter);
  void fnJacobiDn       (uint16_t unusedButMandatoryParameter);
  void fnJacobiAmplitude(uint16_t unusedButMandatoryParameter);

  void fnEllipticK      (uint16_t unusedButMandatoryParameter);
  void fnEllipticE      (uint16_t unusedButMandatoryParameter);
  void fnEllipticPi     (uint16_t unusedButMandatoryParameter);
  void fnEllipticFphi   (uint16_t unusedButMandatoryParameter);
  void fnEllipticEphi   (uint16_t unusedButMandatoryParameter);
  void fnJacobiZeta     (uint16_t unusedButMandatoryParameter);

  /**
   * Computes Jacobi elliptic functions am, sn, cn and dn.
   * \c am, \c sn, \c cn or \c dn can be \c NULL if the corresponding results are not needed.
   *
   * \param[in] u argument 𝑢
   * \param[in] m parameter 𝑚 = 𝑘² = sin²𝛼
   * \param[out] am amplitude am(𝑢|𝑚)
   * \param[out] sn <em>sinus amplitudinis</em> sn(𝑢|𝑚)
   * \param[out] cn <em>cosinus amplitudinis</em> cn(𝑢|𝑚)
   * \param[out] dn <em>delta amplitudinis</em> dn(𝑢|𝑚)
   */
  void jacobiElliptic   (const real_t *u, const real_t *m, real_t *am, real_t *sn, real_t *cn, real_t *dn, realContext_t *realContext);

  /**
   * Computes elliptic amplitude for complex argument.
   *
   * \param[in] ur real part of argument ℜ(𝑢)
   * \param[in] ui imaginary part of argument ℑ(𝑢)
   * \param[in] m parameter 𝑚 = 𝑘² = sin²𝛼
   * \param[out] rr real part of result
   * \param[out] ri imaginary part of result
   */
  void jacobiComplexAm  (const real_t *ur, const real_t *ui, const real_t *m, real_t *rr, real_t *ri, realContext_t *realContext);

  /**
   * Computes <em>sinus amplitudinis</em> for complex argument.
   *
   * \param[in] ur real part of argument ℜ(𝑢)
   * \param[in] ui imaginary part of argument ℑ(𝑢)
   * \param[in] m parameter 𝑚 = 𝑘² = sin²𝛼
   * \param[out] rr real part of result
   * \param[out] ri imaginary part of result
   */
  void jacobiComplexSn  (const real_t *ur, const real_t *ui, const real_t *m, real_t *rr, real_t *ri, realContext_t *realContext);

  /**
   * Computes <em>cosinus amplitudinis</em> for complex argument.
   *
   * \param[in] ur real part of argument ℜ(𝑢)
   * \param[in] ui imaginary part of argument ℑ(𝑢)
   * \param[in] m parameter 𝑚 = 𝑘² = sin²𝛼
   * \param[out] rr real part of result
   * \param[out] ri imaginary part of result
   */
  void jacobiComplexCn  (const real_t *ur, const real_t *ui, const real_t *m, real_t *rr, real_t *ri, realContext_t *realContext);

  /**
   * Computes <em>delta amplitudinis</em> for complex argument.
   *
   * \param[in] ur real part of argument ℜ(𝑢)
   * \param[in] ui imaginary part of argument ℑ(𝑢)
   * \param[in] m parameter 𝑚 = 𝑘² = sin²𝛼
   * \param[out] rr real part of result
   * \param[out] ri imaginary part of result
   */
  void jacobiComplexDn  (const real_t *ur, const real_t *ui, const real_t *m, real_t *rr, real_t *ri, realContext_t *realContext);

  /**
   * Computes complete elliptic integral of the 1st and 2nd kinds.
   * \c k, \c ki, \c e or \c ei can be \c NULL if the corresponding results are not needed.
   * If \c ki or \c ei is \c NULL, returns NaN to \c k or \c e for \c m > 1.
   *
   * \param[in] m parameter 𝑚 = 𝑘² = sin²𝛼
   * \param[out] k elliptic integral of the 1st kind ℜ(K(𝑚))
   * \param[out] ki elliptic integral of the 1st kind ℑ(K(𝑚))
   * \param[out] e elliptic integral of the 2nd kind ℜ(E(𝑚))
   * \param[out] ei elliptic integral of the 2nd kind ℑ(E(𝑚))
   */
  void ellipticKE       (const real_t *m, real_t *k, real_t *ki, real_t *e, real_t *ei, realContext_t *realContext);

  /**
   * Computes incomplete elliptic integral of the 3rd kind Π(𝑛 | 𝑚).
   *
   * \param[in] n characteristic 𝑛
   * \param[in] m parameter 𝑚 = 𝑘² = sin²𝛼
   * \param[out] res real part of the result
   * \param[out] resi imaginary part of the result
   */
  void ellipticPi       (const real_t *n, const real_t *m, real_t *res, real_t *resi, realContext_t *realContext);

  /**
   * Computes incomplete elliptic integral of the 1st kind F(𝜑 + i 𝜓 | 𝑚).
   *
   * \param[in] phi amplitude 𝜑
   * \param[in] psi amplitude i𝜓
   * \param[in] m parameter 𝑚 = 𝑘² = sin²𝛼
   * \param[out] res real part of the result
   * \param[out] resi imaginary part of the result
   */
  void ellipticF        (const real_t *phi, const real_t *psi, const real_t *m, real_t *res, real_t *resi, realContext_t *realContext);

  /**
   * Computes incomplete elliptic integral of the 2nd kind E(𝜑 + i 𝜓 | 𝑚).
   *
   * \param[in] phi amplitude 𝜑
   * \param[in] psi amplitude i𝜓
   * \param[in] m parameter 𝑚 = 𝑘² = sin²𝛼
   * \param[out] res real part of the result
   * \param[out] resi imaginary part of the result
   */
  void ellipticE        (const real_t *phi, const real_t *psi, const real_t *m, real_t *res, real_t *resi, realContext_t *realContext);

  /**
   * Computes Jacobi zeta function Ζ(𝜑 + i 𝜓 | 𝑚).
   *
   * \param[in] phi amplitude 𝜑
   * \param[in] psi amplitude i𝜓
   * \param[in] m parameter 𝑚 = 𝑘² = sin²𝛼
   * \param[out] res real part of the result
   * \param[out] resi imaginary part of the result
   */
  void jacobiZeta       (const real_t *phi, const real_t *psi, const real_t *m, real_t *res, real_t *resi, realContext_t *realContext);
#endif // !ELLIPTIC_H
