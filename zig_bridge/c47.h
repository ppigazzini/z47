#if !defined(Z47_C47_OVERLAY_H)
#define Z47_C47_OVERLAY_H

#include_next "c47.h"

// Keep upstream sources untouched while trimming the only DMCP variant that now
// exceeds the old-hardware QSPI flash budget under the CI toolchain.
#if defined(DMCP_BUILD) && defined(OLD_HW) && defined(TWO_FILE_PGM) && defined(DMCP_PACKAGE) && DMCP_PACKAGE == 2
#undef OPTION_TVM_FORMULAS
#endif

// Package 3 only needs a small additional trim after the retained-state split,
// so prefer the least user-visible savings before dropping major features.
#if defined(DMCP_BUILD) && defined(OLD_HW) && defined(TWO_FILE_PGM) && defined(DMCP_PACKAGE) && DMCP_PACKAGE == 3
#define SAVE_SPACE_DM42_8F
#define SAVE_SPACE_DM42_14
#define SAVE_SPACE_DM42_24_PROFILES
#endif

#endif