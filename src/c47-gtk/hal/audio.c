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

#include "error.h"
#include "flags.h"
#include "c43Extensions/radioButtonCatalog.h"
#include "screen.h"
#include "hal/audio.h"

#include <stdio.h>
#if defined(__MINGW64__)
  #define NOMINMAX
  #include <windows.h>
#elif defined(WITH_PULSEAUDIO)
  #include <pulse/simple.h>
#endif

#include "c47.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"

void audioTone(uint32_t frequency) {
  #if defined(__MINGW64__)
    char filename[32];
    sprintf(filename, "res\\tone\\tone%" PRIu32 ".wav", frequency);
    PlaySoundA(filename, NULL, SND_FILENAME | SND_SYNC | SND_NODEFAULT);
  #elif defined(WITH_PULSEAUDIO)
    pa_simple *s;
    pa_sample_spec ss;

    ss.format   = PA_SAMPLE_S16NE;
    ss.channels = 1;
    ss.rate     = 44100;

    s = pa_simple_new(NULL, "C47", PA_STREAM_PLAYBACK, NULL, "BEEP/TONE", &ss, NULL, NULL, NULL);

    if(s) {
      size_t bufSize = ss.rate / 4;
      int16_t *samples = (int16_t *)malloc(bufSize * sizeof(int16_t));
      int errCode;
      uint64_t p = 0;

      for(unsigned int i = 0; i < bufSize; ++i) {
        samples[i] = p < ((uint64_t)ss.rate * 500) ? 10362 : -10362;
        p += (uint64_t)frequency;
        p %= (uint64_t)ss.rate * 1000;
      }

      pa_simple_write(s, samples, bufSize * sizeof(int16_t), &errCode);
      pa_simple_drain(s, &errCode);
      free(samples);
      pa_simple_free(s);
    }
  #endif
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

void fnPlay (uint16_t unusedButMandatoryParameter) {
}
