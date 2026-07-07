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
