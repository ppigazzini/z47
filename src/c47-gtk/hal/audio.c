// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

#include "error.h"
#include "flags.h"
#include "c47Extensions/radioButtonCatalog.h"
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
