// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

// comparisonReals.c, compare.c and incDec.c are owned by
// zig_src/mathematics/math_comparison_reals_owned.zig and
// math_register_compare_owned.zig. checkValue.c and int.c have Zig owners in
// math_command_wrappers.zig and no remaining live symbols. addition.c and
// subtraction.c are owned by math_addition_cells_owned.zig and
// math_subtraction_cells_owned.zig.

#define fnMultiply z47_math_wrappers_legacy_fnMultiply
#include "../../src/c47/mathematics/multiplication.c"
#undef fnMultiply

#define fnDivide z47_math_wrappers_legacy_fnDivide
#include "../../src/c47/mathematics/division.c"
#undef fnDivide

#define fnIDiv z47_math_wrappers_legacy_fnIDiv
#include "../../src/c47/mathematics/idiv.c"
#undef fnIDiv

#define fnIDivR z47_math_wrappers_legacy_fnIDivR
#include "../../src/c47/mathematics/idivr.c"
#undef fnIDivR

#define fnDblMultiply z47_math_wrappers_legacy_fnDblMultiply
#include "../../src/c47/mathematics/dblMultiplication.c"
#undef fnDblMultiply

#define fnDblDivide z47_math_wrappers_legacy_fnDblDivide
#define fnDblDivideRemainder z47_math_wrappers_legacy_fnDblDivideRemainder
#include "../../src/c47/mathematics/dblDivision.c"
#undef fnDblDivideRemainder
#undef fnDblDivide

#define fnRound z47_math_wrappers_legacy_fnRound
#include "../../src/c47/mathematics/round.c"
#undef fnRound

#define fnDecomp z47_math_wrappers_legacy_fnDecomp
#include "../../src/c47/mathematics/decomp.c"
#undef fnDecomp

