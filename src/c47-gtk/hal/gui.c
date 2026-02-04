// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

#include "c47.h"

/*
#if (SIMULATOR_ON_SCREEN_KEYBOARD == 1)
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
        if(tam.mode == TM_LABEL || tam.mode == TM_LBLONLY || (tam.mode == TM_SOLVE && (tam.function != ITM_SOLVE || calcMode != CM_PEM)) || (tam.mode == TM_KEY && tam.keyInputFinished)) {
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