// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

void zigToneRefreshDisplay(void) {
#if defined(DMCP_BUILD)
  lcd_refresh();
#else
  refreshLcd(NULL);
#endif
}