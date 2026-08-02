#if !defined(Z47_C47_OVERLAY_H)
#define Z47_C47_OVERLAY_H

#include_next "c47.h"

// Keep upstream sources untouched while trimming the only DMCP variant that now
// exceeds the old-hardware QSPI flash budget under the CI toolchain.
#if defined(DMCP_BUILD) && defined(OLD_HW) && defined(TWO_FILE_PGM) && defined(DMCP_PACKAGE) && DMCP_PACKAGE == 2
#undef OPTION_TVM_FORMULAS
#undef OPTION_TVM_NEWTON
#define SAVE_SPACE_DM42_8F
#define SAVE_SPACE_DM42_12ELLIP
#define SAVE_SPACE_DM42_12BESSEL
#define SAVE_SPACE_DM42_12ORTHO
#define SAVE_SPACE_DM42_14
#define SAVE_SPACE_DM42_16
#define SAVE_SPACE_DM42_24_PROFILES
#endif

// Package 1 now needs the next upstream DIST trims as well to stay within the
// old-hardware QSPI budget with the rewritten ownership slices.
#if defined(DMCP_BUILD) && defined(OLD_HW) && defined(TWO_FILE_PGM) && defined(DMCP_PACKAGE) && DMCP_PACKAGE == 1
#undef OPTION_TVM_NEWTON
#define SAVE_SPACE_DM42_14
#define SAVE_SPACE_DM42_16
#define SAVE_SPACE_DM42_17
#define SAVE_SPACE_DM42_17B
#define SAVE_SPACE_DM42_17C
#define SAVE_SPACE_DM42_24_PROFILES
#endif

// Package 3 only needs a small additional trim after the legacy-state split,
// so prefer the least user-visible savings before dropping major features.
#if defined(DMCP_BUILD) && defined(OLD_HW) && defined(TWO_FILE_PGM) && defined(DMCP_PACKAGE) && DMCP_PACKAGE == 3
#define SAVE_SPACE_DM42_8F
#define SAVE_SPACE_DM42_14
#define SAVE_SPACE_DM42_16
#define SAVE_SPACE_DM42_17B
#define SAVE_SPACE_DM42_24_PROFILES
#undef OPTION_ELEC
#undef OPTION_VECTOR
#endif

#endif
