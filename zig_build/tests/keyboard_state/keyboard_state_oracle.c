// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

void z47_keyboard_state_retained_processKeyAction(int16_t item);
void z47_keyboard_state_retained_fnKeyEnter(uint16_t unusedButMandatoryParameter);
void z47_keyboard_state_retained_fnKeyExit(uint16_t unusedButMandatoryParameter);
void z47_keyboard_state_retained_fnKeyCC(uint16_t unusedButMandatoryParameter);
void z47_keyboard_state_retained_fnKeyBackspace(uint16_t unusedButMandatoryParameter);
void z47_keyboard_state_retained_fnKeyUp(uint16_t unusedButMandatoryParameter);
void z47_keyboard_state_retained_fnKeyDown(uint16_t unusedButMandatoryParameter);
void z47_keyboard_state_retained_fnKeyDotD(uint16_t unusedButMandatoryParameter);

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

void oracle_processKeyAction(int16_t item) {
  if((item == ITM_UP1_ITEM || item == ITM_DOWN1_ITEM) &&
     calcMode == CM_FLAG_BROWSER &&
     tam.mode == 0 &&
     lastErrorCode == 0 &&
     temporaryInformation == TI_NO_INFO &&
     programRunStop != PGM_WAITING &&
     calcMode != CM_PLOT_STAT &&
     calcMode != CM_GRAPH) {
    keyActionProcessed = false;
    keyActionProcessed = true;

    if(item == ITM_UP1_ITEM) {
      oracle_fnKeyUp(0);
      screenUpdatingMode &= (uint8_t)~(SCRUPD_MANUAL_MENU | SCRUPD_MANUAL_STACK);
      refreshScreen(118);
    }
    else {
      oracle_fnKeyDown(0);
      screenUpdatingMode &= (uint8_t)~(SCRUPD_MANUAL_MENU | SCRUPD_MANUAL_STACK);
      refreshScreen(119);
    }

    keyActionProcessed = true;
    return;
  }

  z47_keyboard_state_retained_processKeyAction(item);
}

void oracle_fnKeyEnter(uint16_t unusedButMandatoryParameter) {
  z47_keyboard_state_retained_fnKeyEnter(unusedButMandatoryParameter);
}

void oracle_fnKeyExit(uint16_t unusedButMandatoryParameter) {
  z47_keyboard_state_retained_fnKeyExit(unusedButMandatoryParameter);
}

void oracle_fnKeyCC(uint16_t complexType) {
  if(calcMode == CM_NIM && complexType != KEY_COMPLEX) {
    addItemToNimBuffer(ITM_CC);
    return;
  }

  switch(calcMode) {
    case CM_REGISTER_BROWSER:
    case CM_FLAG_BROWSER:
    case CM_ASN_BROWSER:
    case CM_FONT_BROWSER:
    case CM_PLOT_STAT:
    case CM_TIMER:
    case CM_LISTXY:
    case CM_GRAPH:
      return;
    default:
      z47_keyboard_state_retained_fnKeyCC(complexType);
      return;
  }
}

void oracle_fnKeyBackspace(uint16_t unusedButMandatoryParameter) {
  if(tam.mode == 0 && calcMode == CM_NIM) {
    addItemToNimBuffer(ITM_BACKSPACE_ITEM);
    screenUpdatingMode &= (uint8_t)~(SCRUPD_MANUAL_STACK | SCRUPD_SKIP_STACK_ONE_TIME);
    return;
  }

  z47_keyboard_state_retained_fnKeyBackspace(unusedButMandatoryParameter);
}

void oracle_fnKeyUp(uint16_t unusedButMandatoryParameter) {
  switch(calcMode) {
    case CM_FLAG_BROWSER:
      currentFlgScr = (uint8_t)(currentFlgScr + 1);
      return;
    case CM_LISTXY:
      ListXYposition += 10;
      keyActionProcessed = true;
      return;
    default:
      z47_keyboard_state_retained_fnKeyUp(unusedButMandatoryParameter);
      return;
  }
}

void oracle_fnKeyDown(uint16_t unusedButMandatoryParameter) {
  switch(calcMode) {
    case CM_FLAG_BROWSER:
      currentFlgScr = (uint8_t)(currentFlgScr - 1);
      return;
    case CM_LISTXY:
      ListXYposition -= 10;
      keyActionProcessed = true;
      return;
    default:
      z47_keyboard_state_retained_fnKeyDown(unusedButMandatoryParameter);
      return;
  }
}

void oracle_fnKeyDotD(uint16_t unusedButMandatoryParameter) {
  (void)unusedButMandatoryParameter;

  switch(calcMode) {
    case CM_NORMAL: {
      int32_t flag = getSystemFlag(FLAG_IRFRQ) ? FLAG_IRFRAC : FLAG_FRACT;
      if(getSystemFlag(flag)) {
        clearSystemFlag((uint32_t)flag);
      }
      else {
        runFunction(ITM_toREAL);
      }
      return;
    }
    case CM_NIM:
      addItemToNimBuffer(ITM_dotD);
      return;
    case CM_REGISTER_BROWSER:
    case CM_FLAG_BROWSER:
    case CM_ASN_BROWSER:
    case CM_FONT_BROWSER:
    case CM_PLOT_STAT:
    case CM_GRAPH:
    case CM_MIM:
    case CM_EIM:
    case CM_TIMER:
    case CM_LISTXY:
      return;
    default:
      z47_keyboard_state_retained_fnKeyDotD(0);
      return;
  }
}