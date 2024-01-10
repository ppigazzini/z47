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
 * \file statusBar.h
 * Status bar management.
 */
#if !defined(STATUSBAR_H)

#include "c47.h"


#define STATUSBAR_H

  #if !defined(TESTSUITE_BUILD)
  /**
   * Refreshes the status bar.
   */
  void refreshStatusBar       (void);

  /**
   * Displays date and time in the status bar.
   */
  void showDateTime           (void);

  /**
   * Displays the complex result mode C or R in the status bar.
   */
  void showRealComplexResult  (void);

  /**
   * Displays the complex mode rectangular or polar in the status bar.
   */
  void showComplexMode        (void);

  /**
   * Displays the angular mode in the status bar.
   */
  void showAngularMode        (void);

  /**
   * Displays the faction mode in the status bar.
   */
  void showFracMode           (void);

  /**
   * Displays the integer mode icon in the status bar.
   */
  void showIntegerMode        (void);

  /**
   * Displays the matrix mode icon in the status bar.
   */
  void showMatrixMode         (void);

  /**
   * Displays the TVM mode icon in the status bar.
   */
  void showTvmMode            (void);

  /**
   * Displays the overflow flag and the carry flag.
   */
  void showOverflowCarry      (void);

  /**
   * Shows or hides the alpha mode.
   */
  void showHideAlphaMode      (void);

  /**
   * Shows or hides the hourglass icon in the status bar.
   */
  void showHideHourGlass      (void);

  /**
   * Shows ASB icon in the status bar.
   */
  void light_ASB_icon         (void);

  /**
   * Hides ASB icon in the status bar.
   */
  void kill_ASB_icon          (void);

  /**
   * Shows or hides the watch icon in the status bar.
   */
  void showHideWatch          (void);

  /**
   * Shows or hides the serial I/O icon in the status bar.
   */
  void showHideSerialIO       (void);

  /**
   * Shows or hides the printer icon in the status bar.
   */
  void showHidePrinter        (void);

  /**
   * Shows or hides the user mode icon in the status bar.
   */
  void showHideUserMode       (void);

  #if defined(DMCP_BUILD)
    /**
     * Shows or hides the USB or low battery icon in the status bar.
     */
    int updateVbatIntegrated(void);
    void showHideUsbLowBattery(void);
  #else // !DMCP_BUILD
    /**
     * Shows or hides the USB icon in the status bar.
     */
    void showHideStackLift    (void);
  #endif // DMCP_BUILD

  void showHideASB            (void);       //JM

#endif // !TESTSUITE_BUILD
#endif // !STATUSBAR_H
