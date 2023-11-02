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
 * \file hal/gui.h
 */
#if !defined(GUI_H)
  #define GUI_H

  #include "defines.h"

  #if defined(DMCP_BUILD) || (SCREEN_800X480 == 1)
    #define calcModeNormalGui()
    #define calcModeAimGui()
    #define calcModeTamGui()
  #else
    void calcModeNormalGui (void);
    void calcModeAimGui    (void);
    void calcModeTamGui    (void);
  #endif
#endif // !GUI_H
