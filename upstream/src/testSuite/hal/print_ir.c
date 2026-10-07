// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

#include "c47.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"

//
//  Get print line delay
//
uint32_t getLineDelay() {
  return (0);
}


//
//  Set print line delay
//
void setLineDelay(uint16_t delay) {
}


// The bytes the printer route sent since the corpus last cleared them, for the PRX= check
char    printedBytes[4096];
int32_t printedLength = 0;

//
// Send Byte to over IR
//
void sendByteIR( uint8_t byte ) {
  if(printedLength < (int32_t)sizeof(printedBytes) - 1) {
    printedBytes[printedLength++] = byte;
    printedBytes[printedLength] = 0;
  }
}
