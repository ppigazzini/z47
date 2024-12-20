// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file integerPart.c
 ***********************************************/

#include "c47.h"

static void doIP(real_t *x) {
  realToIntegralValue(x, x, DEC_ROUND_DOWN, &ctxtReal39);
}

static void ipReal(void) {
  real_t x;

  if (getRegisterAsReal(REGISTER_X, &x)) {
    doIP(&x);
    convertRealToResultRegister(&x, REGISTER_X, amNone);
  }
}

static void ipCplx(void) {
  real_t a, b;

  if (getRegisterAsComplex(REGISTER_X, &a, &b)) {
    doIP(&a);
    doIP(&b);
    convertComplexToResultRegister(&a, &b, REGISTER_X);
  }
}


/********************************************//**
 * \brief regX ==> regL and IP(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnIp(uint16_t unusedButMandatoryParameter) {
  processIntRealComplexMonadicFunction(&ipReal, &ipCplx, &doNothing, &doNothing);
}
