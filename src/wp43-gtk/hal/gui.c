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

#include "hal/gui.h"

#include "gtkGui.h"
#include "items.h"
#include "wp43.h"
/*
#if(SIMULATOR_ON_SCREEN_KEYBOARD == 1)
  void calcModeNormalGui(void) {
    int key;

    gtk_fixed_move(GTK_FIXED(grid), bezelImage[1], -999,      -999);
    gtk_fixed_move(GTK_FIXED(grid), bezelImage[2], -999,      -999);
    gtk_fixed_move(GTK_FIXED(grid), bezelImage[0], bezelX[0], bezelY[0]);
    currentBezel = 0;

    for(key=0; key<43; key++) {
      gtk_fixed_move(GTK_FIXED(grid), calcKeyboard[key].keyImage[1], -999,                -999);
      gtk_fixed_move(GTK_FIXED(grid), calcKeyboard[key].keyImage[2], -999,                -999);
      gtk_fixed_move(GTK_FIXED(grid), calcKeyboard[key].keyImage[0], calcKeyboard[key].x, calcKeyboard[key].y);
    }
    gtk_fixed_move(GTK_FIXED(grid), calcKeyboard[ 10].keyImage[3], -999,                -999);
  }

  void calcModeAimGui(void) {
    int key;

    gtk_fixed_move(GTK_FIXED(grid), bezelImage[0], -999,      -999);
    gtk_fixed_move(GTK_FIXED(grid), bezelImage[2], -999,      -999);
    gtk_fixed_move(GTK_FIXED(grid), bezelImage[1], bezelX[1], bezelY[1]);
    currentBezel = 1;

    for(key=0; key<43; key++) {
      gtk_fixed_move(GTK_FIXED(grid), calcKeyboard[key].keyImage[0], -999,                -999);
      gtk_fixed_move(GTK_FIXED(grid), calcKeyboard[key].keyImage[2], -999,                -999);
      gtk_fixed_move(GTK_FIXED(grid), calcKeyboard[key].keyImage[1], calcKeyboard[key].x, calcKeyboard[key].y);
    }
    gtk_fixed_move(GTK_FIXED(grid), calcKeyboard[ 10].keyImage[3], -999,                -999);
  }

  void calcModeTamGui(void) {
    int key;

    gtk_fixed_move(GTK_FIXED(grid), bezelImage[0], -999,      -999);
    gtk_fixed_move(GTK_FIXED(grid), bezelImage[1], -999,      -999);
    gtk_fixed_move(GTK_FIXED(grid), bezelImage[2], bezelX[2], bezelY[2]);
    currentBezel = 2;

    for(key=0; key<43; key++) {
      gtk_fixed_move(GTK_FIXED(grid), calcKeyboard[key].keyImage[0], -999,                -999);
      gtk_fixed_move(GTK_FIXED(grid), calcKeyboard[key].keyImage[1], -999,                -999);
      if(key == 10) {
        if(tam.mode == TM_LABEL || (tam.mode == TM_SOLVE && (tam.function != ITM_SOLVE || calcMode != CM_PEM)) || (tam.mode == TM_KEY && tam.keyInputFinished)) {
          gtk_fixed_move(GTK_FIXED(grid), calcKeyboard[key].keyImage[2], -999,                -999);
          gtk_fixed_move(GTK_FIXED(grid), calcKeyboard[key].keyImage[3], calcKeyboard[key].x, calcKeyboard[key].y);
        }
        else {
          gtk_fixed_move(GTK_FIXED(grid), calcKeyboard[key].keyImage[2], calcKeyboard[key].x, calcKeyboard[key].y);
          gtk_fixed_move(GTK_FIXED(grid), calcKeyboard[key].keyImage[3], -999,                -999);
        }
      }
      else {
        gtk_fixed_move(GTK_FIXED(grid), calcKeyboard[key].keyImage[2], calcKeyboard[key].x, calcKeyboard[key].y);
      }
    }
  }
#else // SIMULATOR_ON_SCREEN_KEYBOARD != 1
  void calcModeNormalGui (void) {}
  void calcModeAimGui    (void) {}
  void calcModeTamGui    (void) {}
#endif // SIMULATOR_ON_SCREEN_KEYBOARD == 1
*/