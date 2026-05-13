// SPDX-License-Identifier: GPL-3.0-only

#include <stdint.h>
#include <string.h>

#include "flags_test_runtime.h"

typedef enum { FLAG_CLEAR = 0, FLAG_SET = 1, FLAG_FLIP = 2 } flagAction_t;

typedef struct {
  uint16_t clear_config;
  uint16_t set_config;
  uint16_t flag;
} clear_set_pair_t;

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

static const clear_set_pair_t clearSetPairs[] = {
  { TF_H12, TF_H24, FLAG_TDM24 },
  { CU_I, CU_J, FLAG_CPXj },
  { PS_DOT, PS_CROSS, FLAG_MULTx },
  { SS_4, SS_8, FLAG_SSIZE8 },
  { CM_RECTANGULAR, CM_POLAR, FLAG_POLAR },
  { DO_SCI, DO_ENG, FLAG_ENGOVR },
};

static const uint16_t setSettingFlipFlags[] = {
  FLAG_HPRP,
  FLAG_MNUp1,
  FLAG_HPBASE,
  FLAG_2TO10,
  FLAG_AMORT_HP12C,
  FLAG_PROPFR,
  FLAG_PRTACT,
  FLAG_LEAD0,
  FLAG_CPXRES,
  FLAG_SPCRES,
  FLAG_ERPN,
  FLAG_CARRY,
  FLAG_OVERFLOW,
  FLAG_FRCYC,
  FLAG_CPXMULT,
  FLAG_CPXPLOT,
  FLAG_SHOWX,
  FLAG_SHOWY,
  FLAG_PBOX,
  FLAG_PCURVE,
  FLAG_PCROS,
  FLAG_PPLUS,
  FLAG_PLINE,
  FLAG_SCALE,
  FLAG_VECT,
  FLAG_NVECT,
  FLAG_TOPHEX,
  FLAG_BCD,
  FLAG_LARGELI,
  FLAG_FRACT,
  FLAG_IRFRAC,
  FLAG_G_DOUBLETAP,
  FLAG_SHFT_4s,
  FLAG_FGGR,
  FLAG_TRACE,
  FLAG_NORM,
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

bool_t oracle_getFlag(uint16_t flag) {
  if(flag & 0x8000) {
    return oracle_getSystemFlag(flag);
  }

  if(flag <= FLAG_K) {
    return (globalFlags[flag / 16] & (uint16_t)(1u << (flag % 16))) != 0;
  }

  if(flag <= LAST_LOCAL_FLAG) {
    if(currentLocalFlags != NULL) {
      uint16_t local_flag = flag - NUMBER_OF_GLOBAL_FLAGS;
      if(local_flag < NUMBER_OF_LOCAL_FLAGS) {
        return (*currentLocalFlags & ((uint32_t)1u << local_flag)) != 0;
      }
    }

    return false;
  }

  if(flag >= FLAG_M && flag <= FLAG_W) {
    flag -= 99;
    return (globalFlags[flag / 16] & (uint16_t)(1u << (flag % 16))) != 0;
  }

  return false;
}

static bool_t oracle_isSystemFlagWriteProtected(uint16_t flag) {
  return (flag & 0x4000) != 0;
}

static void oracle_setUserFlag(uint16_t flag) {
  if(flag <= FLAG_K) {
    globalFlags[flag / 16] |= (uint16_t)(1u << (flag % 16));
    return;
  }

  if(flag <= LAST_LOCAL_FLAG) {
    if(currentLocalFlags != NULL) {
      uint16_t local_flag = flag - NUMBER_OF_GLOBAL_FLAGS;
      if(local_flag < NUMBER_OF_LOCAL_FLAGS) {
        *currentLocalFlags |= (uint32_t)1u << local_flag;
      }
    }
    return;
  }

  if(flag >= FLAG_M && flag <= FLAG_W) {
    flag -= 99;
    globalFlags[flag / 16] |= (uint16_t)(1u << (flag % 16));
  }
}

static void oracle_clearUserFlag(uint16_t flag) {
  if(flag <= FLAG_K) {
    globalFlags[flag / 16] &= (uint16_t)~(1u << (flag % 16));
    return;
  }

  if(flag <= LAST_LOCAL_FLAG) {
    if(currentLocalFlags != NULL) {
      uint16_t local_flag = flag - NUMBER_OF_GLOBAL_FLAGS;
      if(local_flag < NUMBER_OF_LOCAL_FLAGS) {
        *currentLocalFlags &= (uint32_t)~((uint32_t)1u << local_flag);
      }
    }
    return;
  }

  if(flag >= FLAG_M && flag <= FLAG_W) {
    flag -= 99;
    globalFlags[flag / 16] &= (uint16_t)~(1u << (flag % 16));
  }
}

static void oracle_flipUserFlag(uint16_t flag) {
  if(flag <= FLAG_K) {
    globalFlags[flag / 16] ^= (uint16_t)(1u << (flag % 16));
    return;
  }

  if(flag <= LAST_LOCAL_FLAG) {
    if(currentLocalFlags != NULL) {
      uint16_t local_flag = flag - NUMBER_OF_GLOBAL_FLAGS;
      if(local_flag < NUMBER_OF_LOCAL_FLAGS) {
        *currentLocalFlags ^= (uint32_t)1u << local_flag;
      }
    }
    return;
  }

  if(flag >= FLAG_M && flag <= FLAG_W) {
    flag -= 99;
    globalFlags[flag / 16] ^= (uint16_t)(1u << (flag % 16));
  }
}

static void oracle_handleWriteProtectedFlag(void) {
  writeProtectedErrorCalls++;
  temporaryInformation = TI_NO_INFO;
  if(programRunStop == PGM_WAITING) {
    programRunStop = PGM_STOPPED;
  }
}

static void oracle_enterAlphaMode(void) {
  enterAlphaCalls++;
  oracle_setSystemFlag(FLAG_ALPHA);
}

static void oracle_leaveAlphaMode(void) {
  leaveAlphaCalls++;
  oracle_clearSystemFlag(FLAG_ALPHA);
}

static void oracle_leaveTamModeIfEnabled(void) {
  leaveTamCalls++;
}

static void oracle_requestClFAllConfirmation(void) {
  clFAllConfirmationCalls++;
}

bool_t oracle_getSystemFlag(int32_t sf) {
  int32_t flag = sf & 0x3fff;

  if(flag < 64) {
    return (systemFlags0 & ((uint64_t)1 << flag)) != 0;
  }

  return (systemFlags1 & ((uint64_t)1 << (flag - 64))) != 0;
}

void oracle_fnGetSystemFlag(uint16_t systemFlag) {
  temporaryInformation = oracle_getSystemFlag(systemFlag) ? TI_TRUE : TI_FALSE;
}

void oracle_fnSetFlag(uint16_t flag) {
  if(flag & 0x8000) {
    if(oracle_isSystemFlagWriteProtected(flag)) {
      oracle_handleWriteProtectedFlag();
    }
    else if(flag == FLAG_ALPHA) {
      oracle_leaveTamModeIfEnabled();
      oracle_enterAlphaMode();
    }
    else {
      oracle_setSystemFlag(flag);
    }
    return;
  }

  oracle_setUserFlag(flag);
}

void oracle_fnClearFlag(uint16_t flag) {
  if(flag & 0x8000) {
    if(oracle_isSystemFlagWriteProtected(flag)) {
      oracle_handleWriteProtectedFlag();
    }
    else if(flag == FLAG_ALPHA) {
      oracle_leaveTamModeIfEnabled();
      oracle_leaveAlphaMode();
    }
    else {
      oracle_clearSystemFlag(flag);
    }
    return;
  }

  oracle_clearUserFlag(flag);
}

void oracle_fnFlipFlag(uint16_t flag) {
  if(flag & 0x8000) {
    if(oracle_isSystemFlagWriteProtected(flag)) {
      oracle_handleWriteProtectedFlag();
    }
    else if(flag == FLAG_ALPHA) {
      oracle_leaveTamModeIfEnabled();
      if(oracle_getSystemFlag(FLAG_ALPHA)) {
        oracle_leaveAlphaMode();
      }
      else {
        oracle_enterAlphaMode();
      }
    }
    else {
      oracle_flipSystemFlag(flag);
    }
    return;
  }

  oracle_flipUserFlag(flag);
}

void oracle_fnClFAll(uint16_t confirmation) {
  if(confirmation == NOT_CONFIRMED && programRunStop != PGM_RUNNING) {
    oracle_requestClFAllConfirmation();
    return;
  }

  memset(globalFlags, 0, sizeof(globalFlags));
  if(currentLocalFlags != NULL) {
    *currentLocalFlags = 0;
  }

  temporaryInformation = programRunStop != PGM_RUNNING ? TI_CLEAR_ALL_FLAGS : TI_NO_INFO;
  screenUpdatingMode = SCRUPD_AUTO;
}

void oracle_SetSetting(uint16_t jmConfig) {
  uint_fast16_t i;

  for(i = 0; i < nbrOfElements(clearSetPairs); i++) {
    if(jmConfig == clearSetPairs[i].clear_config) {
      oracle_fnClearFlag(clearSetPairs[i].flag);
      fnRefreshState();
      return;
    }

    if(jmConfig == clearSetPairs[i].set_config) {
      oracle_fnSetFlag(clearSetPairs[i].flag);
      fnRefreshState();
      return;
    }
  }

  for(i = 0; i < nbrOfElements(setSettingFlipFlags); i++) {
    if(jmConfig == setSettingFlipFlags[i]) {
      oracle_fnFlipFlag(jmConfig);
      fnRefreshState();
      return;
    }
  }

  switch(jmConfig) {
    case JC_NL:
      oracle_fnFlipFlag(FLAG_NUMLOCK);
      showAlphaModeonGui();
      break;

    case FLAG_DENANY:
      oracle_fnFlipFlag(jmConfig);
      oracle_clearSystemFlag(FLAG_DENFIX);
      break;

    case FLAG_DENFIX:
      oracle_fnFlipFlag(jmConfig);
      oracle_clearSystemFlag(FLAG_DENANY);
      break;

    case FLAG_HOME_TRIPLE:
      oracle_fnFlipFlag(jmConfig);
      if(oracle_getSystemFlag(FLAG_HOME_TRIPLE)) {
        oracle_clearSystemFlag(FLAG_MYM_TRIPLE);
      }
      break;

    case FLAG_MYM_TRIPLE:
      oracle_fnFlipFlag(jmConfig);
      if(oracle_getSystemFlag(FLAG_MYM_TRIPLE)) {
        oracle_clearSystemFlag(FLAG_HOME_TRIPLE);
      }
      break;

    case FLAG_BASE_MYM:
      oracle_fnFlipFlag(jmConfig);
      if(oracle_getSystemFlag(FLAG_BASE_MYM)) {
        oracle_clearSystemFlag(FLAG_BASE_HOME);
      }
      break;

    case FLAG_BASE_HOME:
      oracle_fnFlipFlag(jmConfig);
      if(oracle_getSystemFlag(FLAG_BASE_HOME)) {
        oracle_clearSystemFlag(FLAG_BASE_MYM);
      }
      break;

    case FLAG_FGLNFUL:
      oracle_fnFlipFlag(jmConfig);
      if(oracle_getSystemFlag(FLAG_FGLNFUL)) {
        oracle_clearSystemFlag(FLAG_FGLNLIM);
      }
      break;

    case FLAG_FGLNLIM:
      oracle_fnFlipFlag(jmConfig);
      if(oracle_getSystemFlag(FLAG_FGLNLIM)) {
        oracle_clearSystemFlag(FLAG_FGLNFUL);
      }
      break;

    case ITM_DREAL:
      oracle_fnFlipFlag(FLAG_DREAL);
      break;

    case JC_UC:
      alphaCase = alphaCase == AC_LOWER ? AC_UPPER : AC_LOWER;
      break;

    case JC_SS:
      if(scrLock == NC_NORMAL) {
        scrLock = NC_SUBSCRIPT;
      }
      else if(scrLock == NC_SUBSCRIPT) {
        scrLock = NC_SUPERSCRIPT;
      }
      else if(scrLock == NC_SUPERSCRIPT) {
        scrLock = NC_NORMAL;
      }
      else {
        scrLock = NC_NORMAL;
      }
      nextChar = scrLock;
      showAlphaModeonGui();
      break;

    default:
      break;
  }

  fnRefreshState();
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