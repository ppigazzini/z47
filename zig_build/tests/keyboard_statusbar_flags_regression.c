// SPDX-License-Identifier: GPL-3.0-only

#include <stdint.h>
#include <stdio.h>

#include "keyboard_statusbar_mask.h"

int main(void) {
  const uint8_t input = (uint8_t)(SCRUPD_MANUAL_STATUSBAR | SCRUPD_SKIP_STATUSBAR_ONE_TIME | SCRUPD_MANUAL_STACK | 0x80u);
  const uint8_t expected = (uint8_t)(SCRUPD_MANUAL_STACK | 0x80u);
  const uint8_t actual = clearStatusbarUpdateFlags(input);

  if(actual != expected) {
    fprintf(stderr, "expected %#x, got %#x\n", expected, actual);
    return 1;
  }

  if((actual & (SCRUPD_MANUAL_STATUSBAR | SCRUPD_SKIP_STATUSBAR_ONE_TIME)) != 0) {
    fprintf(stderr, "statusbar flags still set in %#x\n", actual);
    return 2;
  }

  return 0;
}