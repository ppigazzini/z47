// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file differentiate.h
 ***********************************************/
#if !defined(DIFFERENTIATE_H)
  #define DIFFERENTIATE_H

  void fn1stDeriv      (uint16_t label);
  void fn2ndDeriv      (uint16_t label);
  void fn1stDerivEq    (uint16_t unusedButMandatoryParameter);
  void fn2ndDerivEq    (uint16_t unusedButMandatoryParameter);

  void firstDerivative (calcRegister_t label);
  void secondDerivative(calcRegister_t label);
#endif // !DIFFERENTIATE_H
