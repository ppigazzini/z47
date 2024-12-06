// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file modulo.h
 ***********************************************/
#if !defined(MODULO_H)
  #define MODULO_H

  void fnMod(uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void modError(void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define modError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  //      RegYRegX
  void modLonILonI(void);
  void modLonIShoI(void);
  void modLonIReal(void);

  //      RegYRegX
  void modShoILonI(void);
  void modShoIShoI(void);
  void modShoIReal(void);

  //      RegYRegX
  void modRealLonI(void);
  void modRealShoI(void);
  void modRealReal(void);
#endif // !MODULO_H
