// SPDX-License-Identifier: GPL-3.0-only
//
// C-side ground-truth companion to the abi parity oracle, in two parts.
//
// (1) Struct layouts translate-c cannot see: the bitfield and union types
// (matrixHeader_t, registerHeader_t, and the matrix/variable-header aggregates
// that embed them) are demoted to `opaque {}` by translate-c -- it cannot
// represent a C bitfield -- so the Zig oracle (abi_layout_oracle.zig) cannot
// @sizeOf/@offsetOf them. This file pins their C ground-truth layout with
// _Static_assert. The matching Zig side is pinned by the comptime asserts in
// zig_src/abi/types.zig; together they cross-check what translate-c leaves opaque.
//
// (2) Drift-fragile value mirrors: owners hardcode copies of defines.h #define
// values and C sizeof()s with no other continuous guard (constants_parity.zig is
// a behavioral fnConstant/fnPi oracle, not a value gate). Several of these have a
// documented bug history of going stale (TM_CMP was 10021, NUMBER_OF_ERROR_CODES
// was 127, ...). Pin the proven-fragile ones so an upstream defines.h change
// fails this lane instead of silently mis-behaving in testSuite-blind owners.
//
// Sizes: matrixHeader_t/registerHeader_t are 32-bit words (4). The matrix/header
// aggregates carry a 4-byte header + an 8-byte (host) pointer or fixed byte
// tail, 8-aligned.
#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>
#include "defines.h"
#include "decContext.h"
#include "decNumber.h"
#include "decQuad.h"
#include "realType.h"
#include "mathematics/pcg_basic.h"
typedef struct _GtkWidget GtkWidget;
#include "typeDefinitions.h"
#include "items.h"

_Static_assert(sizeof(matrixHeader_t) == 4, "matrixHeader_t is a 32-bit bitfield");
_Static_assert(sizeof(registerHeader_t) == 4, "registerHeader_t is a 32-bit word");
_Static_assert(sizeof(real34Matrix_t) == 16, "real34Matrix_t = header(4) + pad + real34_t*(8)");
_Static_assert(sizeof(complex34Matrix_t) == 16, "complex34Matrix_t = header(4) + pad + complex34_t*(8)");
_Static_assert(sizeof(any34Matrix_t) == 16, "any34Matrix_t overlays the two matrix views");
_Static_assert(sizeof(namedVariableHeader_t) == 20, "namedVariableHeader_t = header(4) + name[16]");
_Static_assert(sizeof(reservedVariableHeader_t) == 12, "reservedVariableHeader_t = header(4) + name[8]");
_Static_assert(offsetof(namedVariableHeader_t, variableName) == 4, "name follows the 4-byte header");
_Static_assert(offsetof(reservedVariableHeader_t, reservedVariableName) == 4, "name follows the 4-byte header");

// frontier_register_browser hardcodes CONFIG_SIZE_IN_BYTES = 840 (a testSuite-
// blind display constant). Pin it to the C computation so an upstream growth of
// dtConfigDescriptor_t is caught here instead of silently showing a wrong size.
_Static_assert(TO_BYTES(TO_BLOCKS(sizeof(dtConfigDescriptor_t))) == 840,
               "frontier_register_browser CONFIG_SIZE_IN_BYTES must stay 840");

// More C-derived sizeof constants hardcoded across owners without a guard. These
// drive register (de)serialization strides in calc_state_register_codec and the
// string/long-integer header math in frontier_display / keyboard_state_runtime /
// solve_owned -- an upstream type growth would silently corrupt copies, and none
// is caught by the testSuite. dtConfigDescriptor_t is pinned to its EXACT size
// here (calc_state_register_codec's CONFIG_DESCRIPTOR_SIZE copies sizeof bytes,
// a stricter contract than the rounded CONFIG_SIZE_IN_BYTES above).
_Static_assert(sizeof(strLgIntHeader_t) == 4, "STR_LG_INT_HEADER_SIZE / SIZEOF_STR_LG_INT_HEADER");
_Static_assert(sizeof(real_t) == 60, "REAL_SIZE_IN_BYTES codec stride");
_Static_assert(sizeof(dtConfigDescriptor_t) == 840, "CONFIG_DESCRIPTOR_SIZE (exact, not just TO_BYTES-rounded)");

// Part (2): drift-fragile defines.h value mirrors. Each has a hardcoded twin in a
// Zig owner; several carry a bug-history comment there (was-wrong-before). An
// upstream value change must fail here rather than silently mis-behave.
_Static_assert(TM_CMP == 10022, "keyboard/print/items/manage TM_CMP (was 10021 -> broke comparisons)");
_Static_assert(TM_STRING == 10021, "keyboard_state_runtime TM_STRING");
_Static_assert(NUMBER_OF_ERROR_CODES == 129, "frontier_error bound (was 127 -> rejected codes 127/128)");
_Static_assert(ERROR_TI_UNDO_FAILED == 128, "frontier_screen / math_command_wrappers error 128");
_Static_assert(SETTING_PRINTERICON == 134, "frontier_print status-bar icon (was 130)");
_Static_assert(ERROR_UNDEF_SOURCE_VAR == 36, "math_xfn (was 6 = ERROR_LABEL_NOT_FOUND)");
_Static_assert(PGM_SINGLE_STEP == 6, "frontier_items programRunStop single-step (was 2)");
_Static_assert(MAX_FACTORIAL == 450, "math_runtime_helpers factorial domain bound");
// Second batch: more owner-hardcoded defines.h mirrors, several bug-flagged.
_Static_assert(C47_NULL == 65535, "free-list null-block sentinel 0xFFFF (was 0; block 0 is valid)");
_Static_assert(FLAG_ASLIFT == 0xc023, "auto-stack-lift flag (was 0x8019 = FLAG_QUIET)");
_Static_assert(SIZE_OF_EACH_ERROR_MESSAGE == 48, "solve_owned errorMessages row stride (64 gave a wrong stride); pairs with NUMBER_OF_ERROR_CODES above");
_Static_assert(FIRST_RESERVED_VARIABLE == 2000, "solver/equation reserved-variable base = LAST_NAMED_VARIABLE+1");
_Static_assert(ERROR_MESSAGE_LENGTH == 512, "math_runtime_helpers errorMessage buffer length");
_Static_assert(SCREEN_WIDTH == 400, "screen width used in browser/display right-justification");
_Static_assert(TMP_STR_LENGTH == 2560, "tmpString buffer length used across owners");
_Static_assert(TI_PERC == 68, "temporaryInformation TI_PERC: set must match the display check");
_Static_assert(TI_PERCD == 69, "temporaryInformation TI_PERCD");
_Static_assert(ERROR_INPUT_DATA_TYPE_NOT_MATCHING == 31, "math_xfn error code");
_Static_assert(ERROR_UNDEFINED_OPCODE == 3, "math_xfn error code");
// Third batch: register-range and flag bounds, plus the dispatch-critical
// register data-type enum (frontier_register_browser et al. hardcode these; a
// wrong value mis-routes every register operation -- dtReal34 was once 0).
_Static_assert(LAST_GLOBAL_REGISTER == 136, "register-range top = TEMP_REGISTER_2_SAVED_STATS (was 125)");
_Static_assert(FLAG_USER == 32788, "user-flag base (was a stale 43 in the original scaffold)");
_Static_assert(dtLongInteger == 0, "register data-type enum");
_Static_assert(dtReal34 == 1, "register data-type enum (was 0 = dtLongInteger)");
_Static_assert(dtComplex34 == 2, "register data-type enum");
_Static_assert(dtTime == 3, "register data-type enum");
_Static_assert(dtDate == 4, "register data-type enum");
_Static_assert(dtString == 5, "register data-type enum");
_Static_assert(dtReal34Matrix == 6, "register data-type enum");
_Static_assert(dtComplex34Matrix == 7, "register data-type enum");
_Static_assert(dtShortInteger == 8, "register data-type enum");
_Static_assert(dtConfig == 9, "register data-type enum");
// items.h item code (needs items.h above): frontier_items.isFunctionAllowingNew-
// Variable keys on this; 1645 (ITM_XtoALPHA_OLD) matched the deprecated x->alpha.
_Static_assert(ITM_XtoALPHA == 2785, "current fnXToAlpha item code (was 1645 = deprecated _OLD)");
