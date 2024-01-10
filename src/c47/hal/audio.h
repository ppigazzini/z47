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

/**
 * \file hal/audio.h
 */
#if !defined(AUDIO_H)
  #define AUDIO_H

  #include <stdint.h>

  /**
   * Plays a tone.
   * Each hardware platform that supports playing audio should implement
   * this method to play a short tone of a given frequency. This is the
   * only supported audio playback. Configuration for a "silent mode" is
   * not covered by this function and should be checked by the caller.
   *
   * \param[in] frequency the frequency of the note to play in mHz
   */
  void audioTone(uint32_t frequency);
  
  /**
   * Set Buzzer volume on the calculator.
   * Only relevant for the DMCP version, not used for the simulator
   * Input : volume level from 0 to 11
   */
  void fnSetVolume(uint16_t volume);
  
  /**
   * Get Buzzer volume on the calculator.
   * Only relevant for the DMCP version, not used for the simulator
   * Output : volume level from 0 to 11
   */
  void fnGetVolume(uint16_t volume);

  /**
   * Increase Buzzer volume on the calculator.
   * Only relevant for the DMCP version, not used for the simulator
   */
  void fnVolumeUp(uint16_t unusedButMandatoryParameter);

  /**
   * Decrease Buzzer volume on the calculator.
   * Only relevant for the DMCP version, not used for the simulator
   */
  void fnVolumeDown(uint16_t unusedButMandatoryParameter);
  
  /**
   * DM42 squeak sound
   * Only relevant for the DMCP version, not used for the simulator
   */
  void squeak();

  /**
   * Play a sound on the buzzer whose frequency is in Y and duration in X.
   * Only relevant for the DMCP version, not used for the simulator
   */
  void fnBuzz(uint16_t unusedButMandatoryParameter);

  /**
   * Play a melody on the buzzer whose notes frequency and durations are in a Nx2 matrix.
   * Only relevant for the DMCP version, not used for the simulator
   */
  void fnPlay(uint16_t regist);
  
  uint16_t getBeepVolume();
  
#endif // !AUDIO_H
