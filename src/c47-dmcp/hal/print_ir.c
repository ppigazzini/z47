// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

#include "c47.h"


//
//  Get print line delay
//
uint32_t getLineDelay(void) {
  return printer_get_delay() / 100; // DMCP delay is in ms, so convert to ticks.
}


//
//  Set print line delay
//
void setLineDelay(uint16_t delay) {
  printer_set_delay(delay * 100); // delay is in ticks, so convert to ms.
}


//
// Send Byte to over IR
//
void sendByteIR(uint8_t byte) {
  if(getSystemFlag(FLAG_PRTACT)) {
    print_byte(byte);
  }
}
