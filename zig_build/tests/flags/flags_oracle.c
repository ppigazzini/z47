// SPDX-License-Identifier: GPL-3.0-only

#include <stdint.h>

#include "flags_test_runtime.h"

typedef enum { FLAG_CLEAR = 0, FLAG_SET = 1, FLAG_FLIP = 2 } flagAction_t;

uint64_t oracle_systemFlags0Changed = UINT64_MAX;
uint64_t oracle_systemFlags1Changed = UINT64_MAX;
uint64_t oracle_systemFlags2Changed = UINT64_MAX;

static const uint16_t refreshStateFlags[] = {
  0x8000, 0xc001, 0xc002, 0xc003, 0x8004, 0x8017, 0x8005, 0x8006, 0x800d,
  0x8009, 0x800a, 0x8018, 0x801b, 0x801c, 0xc029, 0x802b, 0x8056, 0x803c,
  0x8043, 0x8044, 0x8045, 0x800b, 0x800c, 0x8041, 0x8046, 0xc00f, 0x803d,
  0x8011, 0x804b, 0x804c, 0x804d, 0x804e, 0x805a, 0x804f, 0x8050, 0x8051,
  0x8052, 0x8053, 0x8054, 0x8058, 0x8064,
};

static const uint16_t clearStatusBarFlags[] = {
  0x802c, 0x802e, 0x802f, 0x8030, 0x8032, 0x8033, 0x8034, 0x8035, 0x8036,
  0x8037, 0x8038, 0x8039, 0x803a, 0x803b, FLAG_SBfrac, FLAG_SBwoy,
  FLAG_SBtime, FLAG_FRACT, FLAG_IRFRAC, FLAG_IRFRQ,
};

static void oracle_setSystemFlagBit(unsigned int sf) {
  int32_t flag = (int32_t)(sf & 0x3fff);

  if(flag < 64) {
    oracle_systemFlags0Changed |= (~systemFlags0 & ((uint64_t)1 << flag));
    systemFlags0 |= ((uint64_t)1 << flag);
  }
  else {
    oracle_systemFlags1Changed |= (~systemFlags1 & ((uint64_t)1 << (flag - 64)));
    systemFlags1 |= ((uint64_t)1 << (flag - 64));
  }
}

static void oracle_clearSystemFlagBit(unsigned int sf) {
  int32_t flag = (int32_t)(sf & 0x3fff);

  if(flag < 64) {
    oracle_systemFlags0Changed |= (systemFlags0 & ((uint64_t)1 << flag));
    systemFlags0 &= ~((uint64_t)1 << flag);
  }
  else {
    oracle_systemFlags1Changed |= (systemFlags1 & ((uint64_t)1 << (flag - 64)));
    systemFlags1 &= ~((uint64_t)1 << (flag - 64));
  }
}

static void oracle_flipSystemFlagBit(unsigned int sf) {
  int32_t flag = (int32_t)(sf & 0x3fff);

  if(flag < 64) {
    oracle_systemFlags0Changed |= ((uint64_t)1 << flag);
    systemFlags0 ^= ((uint64_t)1 << flag);
  }
  else {
    oracle_systemFlags1Changed |= ((uint64_t)1 << (flag - 64));
    systemFlags1 ^= ((uint64_t)1 << (flag - 64));
  }
}

bool_t oracle_getSystemFlag(int32_t sf) {
  int32_t flag = sf & 0x3fff;

  if(flag < 64) {
    return (systemFlags0 & ((uint64_t)1 << flag)) != 0;
  }

  return (systemFlags1 & ((uint64_t)1 << (flag - 64))) != 0;
}

static void oracle_systemFlagAction(uint16_t systemFlag, flagAction_t action) {
  uint_fast16_t i;

  for(i = 0; i < nbrOfElements(refreshStateFlags); i++) {
    if(systemFlag == refreshStateFlags[i]) {
      fnRefreshState();
      goto doInteractionFlags;
    }
  }

  for(i = 0; i < nbrOfElements(clearStatusBarFlags); i++) {
    if(systemFlag == clearStatusBarFlags[i]) {
      #if defined(DMCP_BUILD)
        reallyClearStatusBar(201);
      #endif
      fnRefreshState();
      screenUpdatingMode &= ~SCRUPD_MANUAL_STATUSBAR;
      goto doInteractionFlags;
    }
  }

  if(systemFlag == FLAG_BCD) {
    if(oracle_getSystemFlag(systemFlag) && action != FLAG_CLEAR && lastIntegerBase == 0) {
      fnChangeBaseJM(10);
    }
  }

doInteractionFlags:
  switch(systemFlag) {
    case FLAG_SBfrac:
      lastIntegerBase = 0;
      break;

    case FLAG_SBwoy:
    case FLAG_SBtime:
      if(systemFlag == FLAG_SBtime && oracle_getSystemFlag(FLAG_SBtime)) {
        oracle_clearSystemFlagBit(FLAG_SBwoy);
      }
      else if(systemFlag == FLAG_SBwoy && oracle_getSystemFlag(FLAG_SBwoy)) {
        oracle_clearSystemFlagBit(FLAG_SBtime);
      }
      break;

    case FLAG_FRACT:
      if(oracle_getSystemFlag(FLAG_FRACT)) {
        oracle_clearSystemFlagBit(FLAG_IRFRAC);
        oracle_clearSystemFlagBit(FLAG_IRFRQ);
      }
      break;

    case FLAG_IRFRAC:
      if(oracle_getSystemFlag(FLAG_IRFRAC)) {
        oracle_clearSystemFlagBit(FLAG_FRACT);
        oracle_setSystemFlagBit(FLAG_IRFRQ);
      }
      break;

    case FLAG_IRFRQ:
      if(oracle_getSystemFlag(FLAG_FRACT)) {
        oracle_clearSystemFlagBit(FLAG_FRACT);
        oracle_setSystemFlagBit(FLAG_IRFRAC);
      }
      break;

    default:
      break;
  }
}

void oracle_setSystemFlag(unsigned int sf) {
  oracle_setSystemFlagBit(sf);
  oracle_systemFlagAction((uint16_t)sf, FLAG_SET);
}

void oracle_clearSystemFlag(unsigned int sf) {
  oracle_clearSystemFlagBit(sf);
  oracle_systemFlagAction((uint16_t)sf, FLAG_CLEAR);
}

void oracle_flipSystemFlag(unsigned int sf) {
  oracle_flipSystemFlagBit(sf);
  oracle_systemFlagAction((uint16_t)sf, FLAG_FLIP);
}

bool_t oracle_didSystemFlagChange(int32_t sf) {
  int32_t flag = sf & 0x3fff;
  bool_t returnvalue;

  if(flag < 64) {
    returnvalue = (oracle_systemFlags0Changed & ((uint64_t)1 << flag)) != 0;
    oracle_systemFlags0Changed &= ~((uint64_t)1 << flag);
  }
  else if(flag < 128) {
    returnvalue = (oracle_systemFlags1Changed & ((uint64_t)1 << (flag - 64))) != 0;
    oracle_systemFlags1Changed &= ~((uint64_t)1 << (flag - 64));
  }
  else {
    returnvalue = (oracle_systemFlags2Changed & ((uint64_t)1 << (flag - 128))) != 0;
    oracle_systemFlags2Changed &= ~((uint64_t)1 << (flag - 128));
  }

  return returnvalue;
}

void oracle_setSystemFlagChanged(int32_t sf) {
  int32_t flag = sf & 0x3fff;

  if(flag < 64) {
    oracle_systemFlags0Changed |= ((uint64_t)1 << flag);
  }
  else if(flag < 128) {
    oracle_systemFlags1Changed |= ((uint64_t)1 << (flag - 64));
  }
  else {
    oracle_systemFlags2Changed |= ((uint64_t)1 << (flag - 128));
  }
}

void oracle_setAllSystemFlagChanged(void) {
  oracle_systemFlags0Changed = UINT64_MAX;
  oracle_systemFlags1Changed = UINT64_MAX;
  oracle_systemFlags2Changed = UINT64_MAX;
}

void oracle_forceSystemFlag(unsigned int sf, int set) {
  if(set) {
    oracle_setSystemFlag(sf);
  }
  else {
    oracle_clearSystemFlag(sf);
  }
}