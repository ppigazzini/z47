// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file lnPOne.h
 ***********************************************/
#if !defined(LNPONE_H)
  #define LNPONE_H
  // Coded by JM, based on ln.h

  void fnLnP1   (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void lnP1Error(void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define lnP1Error typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void lnP1LonI (void);
  void lnP1Rema (void);
  void lnP1Cxma (void);
  void lnP1ShoI (void);
  void lnP1Real (void);
  void lnP1Cplx (void);
  void lnP1Complex(const real_t *real, const real_t *imag, real_t *lnReal, real_t *lnImag, realContext_t *realContext);
#endif // !LNPONE_H
