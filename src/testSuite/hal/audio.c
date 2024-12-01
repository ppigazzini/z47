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

#include "c43Extensions/radioButtonCatalog.h"
#include "hal/audio.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"

void audioTone(uint32_t frequency) {
}

void fnSetVolume(uint16_t volume) {
}

uint16_t getBeepVolume(void) {
  return NOVAL;
}

void fnGetVolume(uint16_t unusedButMandatoryParameter) {
}

void fnVolumeUp(uint16_t unusedButMandatoryParameter) {
}

void fnVolumeDown(uint16_t unusedButMandatoryParameter) {
}

void fnBuzz(uint16_t unusedButMandatoryParameter) {
}

void fnPlay(uint16_t unusedButMandatoryParameter) {
}