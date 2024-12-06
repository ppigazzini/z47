// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file parallel.h
 ***********************************************/
#if !defined(PARALLEL_H)
  #define PARALLEL_H

  void fnParallel      (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void parallelError   (void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define parallelError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  //      RegYRegX
  void parallelLonILonI(void);
  void parallelLonIReal(void);
  void parallelLonICplx(void);

  //      RegYRegX
  void parallelRealLonI(void);
  void parallelRealReal(void);
  void parallelRealCplx(void);

  //      RegYRegX
  void parallelCplxLonI(void);
  void parallelCplxReal(void);
  void parallelCplxCplx(void);
#endif // !PARALLEL_H
