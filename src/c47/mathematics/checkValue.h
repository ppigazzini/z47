// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file checkValue.h
 ***********************************************/
#if !defined(CHECKVALUE_H)
  #define CHECKVALUE_H

  void fnCheckValue   (uint16_t mode);
  void checkValueError(uint16_t unusedButMandatoryParameter);
  void checkValueDT   (uint16_t mode);
  void checkValueLonI (uint16_t mode);
  void checkValueRema (uint16_t mode);
  void checkValueCxma (uint16_t mode);
  void checkValueShoI (uint16_t mode);
  void checkValueReal (uint16_t mode);
  void checkValueCplx (uint16_t mode);
  void fnCheckType    (uint16_t unusedButMandatoryParameter);
#endif // !CHECKVALUE_H
