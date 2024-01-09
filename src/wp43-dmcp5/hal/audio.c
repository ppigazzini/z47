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


#include "typeDefinitions.h"
#include "defines.h"
#include "error.h"
#include "flags.h"
#include "hal/audio.h"
#include "keyboard.h"
#include "mathematics/matrix.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "stack.h"

#include <stdio.h>
#include <dmcp.h>

#include "wp43.h"

static uint32_t _getValueFromRegister(calcRegister_t regist);
static void _Buzz(uint32_t frequency, uint32_t ms_delay);

void audioTone(uint32_t frequency) {
  start_buzzer_freq(frequency);
  sys_delay(250);
  stop_buzzer();
}

void dm42_squeak() {
  if(!getSystemFlag(FLAG_QUIET)) {
    start_buzzer_freq(1835000);
    sys_delay(125);
    stop_buzzer();
  }
}

void fnSetVolume(uint16_t volume) {
  uint16_t i;
  uint16_t current_volume;
  current_volume = get_beep_volume();
  //volume++;
  if (volume > current_volume) {
    for(i = current_volume; i < volume; i++) {
      beep_volume_up();
    }
  } else if (volume < current_volume) {
    for(i = current_volume; i > volume; i--) {
      beep_volume_down();
    }
  }  
}

uint16_t getBeepVolume() {
    return get_beep_volume();
}

void fnGetVolume(uint16_t unusedButMandatoryParameter) {
  longInteger_t volume;

  liftStack();

  longIntegerInit(volume);
  uIntToLongInteger(get_beep_volume(), volume);
  convertLongIntegerToLongIntegerRegister(volume, REGISTER_X);
  longIntegerFree(volume);
}

void fnVolumeUp(uint16_t unusedButMandatoryParameter) {
    beep_volume_up();
    audioTone(440000);    // tone 8
}

void fnVolumeDown(uint16_t unusedButMandatoryParameter) {
    beep_volume_down();
    audioTone(440000);    // tone 8
}

static uint32_t _getValueFromRegister(calcRegister_t regist) {
    uint32_t value;

    if(getRegisterDataType(regist) == dtReal34) {
      value = real34ToUInt32(REGISTER_REAL34_DATA(regist));
    }

    else if(getRegisterDataType(regist) == dtLongInteger) {
      longInteger_t lgInt;
      convertLongIntegerRegisterToLongInteger(regist, lgInt);
      longIntegerToUInt(lgInt, value);
      longIntegerFree(lgInt);
    }

    else {
      displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
      //errorMoreInfo("register %" PRId16 " is %s:\nnot suited for addressing!", regist, getRegisterDataTypeName(regist, true, false));
      return -1;
    }

  return value;
}

static void _Buzz(uint32_t frequency, uint32_t ms_delay) {
  if (ms_delay > 0) { 
    if (ms_delay > 2000) ms_delay = 2000;  // max duration value : 2s
    if (frequency != 0) { 
      if (frequency > 20000) frequency = 20000;  // max  audible frequency:  20 kHz
      start_buzzer_freq(frequency*1000);
      sys_delay(ms_delay);
      stop_buzzer();
    } else {
      sys_delay(ms_delay);
    }
  }
}

void fnBuzz(uint16_t unusedButMandatoryParameter) {
  uint32_t frequency;
  uint32_t ms_delay;
  if(!getSystemFlag(FLAG_QUIET)) {
    frequency = _getValueFromRegister(REGISTER_Y);
    ms_delay  = _getValueFromRegister(REGISTER_X);
    _Buzz(frequency, ms_delay);
  }
}

void fnPlay(uint16_t regist) {
  uint32_t frequency;
  uint32_t ms_delay;
  uint16_t volume;
  uint16_t cols;
  if(getRegisterDataType(regist) == dtReal34Matrix) {
    real34Matrix_t m;
    if(!getSystemFlag(FLAG_QUIET)) {
      linkToRealMatrixRegister(regist, &m);
      cols = m.header.matrixColumns;
      if ((cols != 2) && (cols != 3)) {
        displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X);
        //errorMoreInfo("DataType %" PRIu32 " is not a Nx2 matrix", getRegisterDataType(regist));
        return;
      }
      for(uint16_t i = 0; i < m.header.matrixRows; ++i) {
        frequency = real34ToUInt32(&m.matrixElements[i * cols]);
        ms_delay  = real34ToUInt32(&m.matrixElements[i * cols + 1]);
        volume    = real34ToUInt32(&m.matrixElements[i * cols + 2]);
        if (cols == 3) fnSetVolume(volume);
        _Buzz(frequency, ms_delay);
        if (ms_delay > 0) sys_delay(ms_delay/8);  // delay between two notes: note duration/8
        while(!key_empty()) {
          if (key_pop() == KEY_EXIT) {          // exit if user press EXIT
            key_pop_all ();
            return;
          }
        }
      }
    }
  }
  else {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
    //errorMoreInfo("DataType %" PRIu32 " is not a real matrix", getRegisterDataType(regist));
  }
}
