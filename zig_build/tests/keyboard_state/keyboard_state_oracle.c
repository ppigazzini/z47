// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

bool_t oracle_caseReplacements(uint8_t id, bool_t lowerCaseSelected, int16_t item, int16_t *itemOut) {
  (void)id;

  *itemOut = item;
  if(lowerCaseSelected && ITM_A <= item && item <= ITM_Z) {
    *itemOut = item + (ITM_a - ITM_A);
    return true;
  }
  else if(!lowerCaseSelected && ITM_A <= item && item <= ITM_Z) {
    return true;
  }
  else if(!lowerCaseSelected && ITM_a <= item && item <= ITM_z) {
    *itemOut = item - (ITM_a - ITM_A);
    return true;
  }
  else if(lowerCaseSelected && ITM_a <= item && item <= ITM_z) {
    return true;
  }

  return false;
}

bool_t oracle_keyReplacements(int16_t item, int16_t *item1, bool_t NL, bool_t FSHIFT, bool_t GSHIFT) {
  if(calcMode == CM_AIM || calcMode == CM_EIM || calcMode == CM_PEM || (tam.mode && tam.alpha) || (calcMode == CM_ASSIGN && itemToBeAssigned == 0)) {
    if(GSHIFT) {
      switch(item) {
        case ITM_sigma: *item1 = ITM_SIGMA; break;
        case ITM_delta: *item1 = ITM_DELTA; break;
        case ITM_NULL: *item1 = ITM_SPACE; break;
        default: break;
      }
    }
    else if(NL) {
      uint16_t ix = 15;

      item -= (ITM_A + 26 <= item && item <= ITM_Z + 26) ? -26 : 0;
      while(ix < 37) {
        if(kbd_std[ix].primaryAim != ITM_EXIT1 && kbd_std[ix].primaryAim != ITM_UP1 && kbd_std[ix].primaryAim != ITM_DOWN1 && kbd_std[ix].primaryAim != ITM_BACKSPACE) {
          if(!FSHIFT && item == kbd_std[ix].primaryAim) {
            *item1 = getSystemFlag(FLAG_USER) ? kbd_usr[ix].gShiftedAim : kbd_std[ix].gShiftedAim;
            break;
          }
          if(FSHIFT && ix >= 31 && item == kbd_std[ix].gShiftedAim) {
            *item1 = getSystemFlag(FLAG_USER) ? kbd_usr[ix].primaryAim : kbd_std[ix].primaryAim;
            break;
          }
        }
        ix++;
      }
    }
  }

  return *item1 != 0;
}

uint16_t oracle_numlockReplacements(uint16_t id, int16_t item, bool_t NL, bool_t FSHIFT, bool_t GSHIFT) {
  int16_t item1 = 0;

  (void)id;
  if(oracle_keyReplacements(item, &item1, NL, FSHIFT, GSHIFT)) {
    return (uint16_t)(item1 < 0 ? -item1 : item1);
  }

  return (uint16_t)(item < 0 ? -item : item);
}

void oracle_setLastKeyCode(int key) {
  if(1 <= key && key <= 43) {
    if(key <= 6) {
      lastKeyCode = key + 20;
    }
    else if(key <= 12) {
      lastKeyCode = key - 6 + 30;
    }
    else if(key <= 17) {
      lastKeyCode = key - 12 + 40;
    }
    else if(key <= 22) {
      lastKeyCode = key - 17 + 50;
    }
    else if(key <= 27) {
      lastKeyCode = key - 22 + 60;
    }
    else if(key <= 32) {
      lastKeyCode = key - 27 + 70;
    }
    else if(key <= 43) {
      lastKeyCode = key - 37 + 10;
    }
  }
}