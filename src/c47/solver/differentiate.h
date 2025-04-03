// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file differentiate.h
 ***********************************************/
#if !defined(DIFFERENTIATE_H)
  #define DIFFERENTIATE_H

  enum {
    DERIVATIVE_FIRST_CENTRAL,   DERIVATIVE_SECOND_CENTRAL,
    DERIVATIVE_FIRST_UPPER,     DERIVATIVE_SECOND_UPPER,
    DERIVATIVE_FIRST_LOWER,     DERIVATIVE_SECOND_LOWER
  };
  void fn1stDeriv      (uint16_t label);
  void fn2ndDeriv      (uint16_t label);
  void fn1stDerivEq    (uint16_t unusedButMandatoryParameter);
  void fn2ndDerivEq    (uint16_t unusedButMandatoryParameter);
#endif // !DIFFERENTIATE_H
