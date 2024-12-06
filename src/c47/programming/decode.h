// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file decode.h
 ***********************************************/
#if !defined(DECODE_H)
  #define DECODE_H

  void decodeOneStep                (uint8_t *step);
  void decodeOneStep_XPORT          (uint8_t *step);
  void decodeOneStepXEQM_XPORT      (uint8_t *step);
  #if !defined(DMCP_BUILD)
    void listPrograms         (void);
    void listLabelsAndPrograms(void);
  #endif // !DMCP_BUILD
#endif // !DECODE_H
