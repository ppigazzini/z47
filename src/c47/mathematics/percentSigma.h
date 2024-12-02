// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file percentSigma.h
 ***********************************************/
#if !defined(PERCENTSIGMA_H)
  #define PERCENTSIGMA_H

  #include <stdint.h>
  #include "typeDefinitions.h"

  void fnPercentSigma(uint16_t unusedButMandatoryParameter);

  bool_t percentSigma(real_t *xReal, real_t *rReal, realContext_t *realContext);
#endif // !PERCENTSIGMA_H
