/* This file is part of 43S.
 *
 * 43S is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * 43S is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with 43S.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "ui/tone.h"

#include <stdio.h>
#include "flags.h"
#include "hal/audio.h"
#include "screen.h"

#include "c47.h"

TO_QSPI uint32_t frequency[10] = {164814, 220000, 246942, 277183, 293665, 329628, 369995, 415305, 440000, 554365};

static void _tonePlay(uint16_t toneNum) {
  if(getSystemFlag(FLAG_QUIET)) {
    return;
  }
  if(toneNum < 10) {
    audioTone(frequency[toneNum]);
  }
}

void fnTone(uint16_t toneNum) {
  #if defined(DMCP_BUILD)
    lcd_refresh();
  #else // !DMCP_BUILD
    refreshLcd(NULL);
  #endif // DMCP_BUILD

  _tonePlay(toneNum);
}

void fnBeep(uint16_t unusedButMandatoryParameter) {
  #if defined(DMCP_BUILD)
    lcd_refresh();
  #else // !DMCP_BUILD
    refreshLcd(NULL);
  #endif // DMCP_BUILD

  _tonePlay(8);
  _tonePlay(5);
  _tonePlay(9);
  _tonePlay(8);
}
