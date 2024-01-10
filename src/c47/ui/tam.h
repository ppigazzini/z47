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
 * \file ui/tam.h
 */
#if !defined(TAM_H)
  #define TAM_H

  #include "defines.h"
  #include <stdint.h>

  #if !defined(TESTSUITE_BUILD)
    /**
     * Enters TAM mode.
     * This initialises TAM entry for the given command and sets the `tamBuffer`
     * to the appropriate text. In GUI mode the keyboard is set-up. Once this
     * function has been called TAM mode can be left by input processed by
     * ::tamProcessInput or by calling ::tamLeaveMode. If TAM is left the command
     * that triggered TAM is implicitly cancelled (no further action is needed).
     * For the command to be executed the input must be processed by
     * ::tamProcessInput.
     *
     * This function should be called instead of the command that requires TAM
     * input. The command that requires TAM should be passed as a parameter.
     *
     * \param[in] func the `indexOfItems` index for the command that
     *                 requires TAM mode
     */
    void tamEnterMode    (int16_t func);

    /**
     * Leaves TAM mode. TAM mode is closed and the pending operation is cancelled.
     */
    void tamLeaveMode    (void);

    /**
     * Processes input for the TAM buffer.
     * Almost all input is handled by this function. The exceptions are:
     * - alpha input when in 'alpha' mode (tamState_t::alpha), where input of alpha
     *   characters must be put into the AIM buffer before calling this function with
     *   the input item
     * - `EXIT` and other external functions where TAM should be closed externally
     *   using ::tamLeaveMode
     *
     * After calling this function the ::tamBuffer will be updated and it should be
     * redrawn to the relevant part of the display.
     *
     * \param[in] item the ITM value to process
     */
    void tamProcessInput (uint16_t item);


    /**
     * Returns actual function for current TAM.
     *
     * \return operation code
     */
    int16_t tamOperation (void);
  #endif // !TESTSUITE_BUILD
#endif // !TAM_H
