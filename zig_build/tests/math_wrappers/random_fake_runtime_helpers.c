// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

extern uint32_t z47_math_wrappers_bounded_rand(uint32_t s);

void z47_math_wrappers_seed_defaults(uint64_t *seed, uint64_t *seq) {
#if defined(TESTSUITE_BUILD)
  *seed = 0xDeadBeef;
  *seq = 0xBadCafeFace;
#else
  *seed = (((uint64_t)getUptimeMs()) << 32) + (uint64_t)getFreeRamMemory();
  *seq = (((uint64_t)getUptimeMs()) << 32) + (uint64_t)getFreeFlash();
#endif
}

void z47_math_wrappers_do_int_random_i(void) {
  longInteger_t regX, regY, mini, maxi;
  uint32_t maxRand;
  int32_t cmp;
  bool_t frac, init_minmax = false;

  saveForUndo();
  thereIsSomethingToUndo = true;

  if(!getRegisterAsLongInt(REGISTER_X, regX, &frac) || frac) {
    goto err1;
  }
  if(!getRegisterAsLongInt(REGISTER_Y, regY, &frac) || frac) {
    goto err2;
  }

  cmp = longIntegerCompare(regX, regY);
  if(cmp == 0) {
    goto end;
  }

  init_minmax = true;
  longIntegerInit(mini);
  longIntegerInit(maxi);
  if(cmp < 0) {
    longIntegerCopy(regX, mini);
    longIntegerCopy(regY, maxi);
  }
  else {
    longIntegerCopy(regX, maxi);
    longIntegerCopy(regY, mini);
  }

  longIntegerSubtract(maxi, mini, regX);
  if(longIntegerCompareUInt(regX, 0xFFFFFFFE) >= 0) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
    moreInfoOnError("In function doIntRandomI:", "cannot RANI# with |X - Y| >= 2^32", NULL, NULL);
#endif
    fnUndo(0);
    goto err3;
  }

  longIntegerToUInt32(regX, maxRand);
  maxRand = z47_math_wrappers_bounded_rand(maxRand + 1);
  longIntegerAddUInt(mini, maxRand, regX);

end:
  convertLongIntegerToLongIntegerRegister(regX, REGISTER_X);
  adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);

err3:
  if(init_minmax) {
    longIntegerFree(maxi);
    longIntegerFree(mini);
  }
err2:
  longIntegerFree(regY);
err1:
  longIntegerFree(regX);
}