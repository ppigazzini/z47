// SPDX-License-Identifier: GPL-3.0-only
//
// C-side companion to the abi struct-layout parity oracle. The bitfield and
// union types (matrixHeader_t, registerHeader_t, and the matrix/variable-header
// aggregates that embed them) are demoted to `opaque {}` by translate-c -- it
// cannot represent a C bitfield -- so the Zig oracle (abi_layout_oracle.zig)
// cannot @sizeOf/@offsetOf them. This file pins their C ground-truth layout with
// _Static_assert, compiled against the pinned upstream headers. The matching Zig
// side is pinned by the comptime asserts in zig_src/abi/types.zig; together they
// cross-check the layouts translate-c leaves opaque.
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
