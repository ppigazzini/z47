// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file ln.h
 ***********************************************/
#if !defined(LN_H)
  #define LN_H

  void fnLn   (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void lnError(void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define lnError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void lnLonI (void);
  void lnRema (void);
  void lnCxma (void);
  void lnShoI (void);
  void lnReal (void);
  void lnCplx (void);
  void lnComplex(const real_t *real, const real_t *imag, real_t *lnReal, real_t *lnImag, realContext_t *realContext);
#endif // !LN_H
