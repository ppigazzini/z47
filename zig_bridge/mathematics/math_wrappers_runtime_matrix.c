// SPDX-License-Identifier: GPL-3.0-only

// The matrix lifecycle primitives are owned by
// zig_src/mathematics/math_matrix_lifecycle_owned.zig. Rename the upstream
// copies so they stay compiled (still called internally by the not-yet-ported
// matrix engine) but the canonical symbols resolve to the Zig owner for every
// external consumer. The defines precede c47.h so the matrix.h prototypes are
// renamed in step with the definitions and the cross-calls inside matrix.c.
// The remaining matrix engine stays in this bridge until the later B clusters
// land.
#define realMatrixInit z47_math_wrappers_legacy_realMatrixInit
#define realMatrixFree z47_math_wrappers_legacy_realMatrixFree
#define realMatrixIdentity z47_math_wrappers_legacy_realMatrixIdentity
#define realMatrixRedim z47_math_wrappers_legacy_realMatrixRedim
#define complexMatrixInit z47_math_wrappers_legacy_complexMatrixInit
#define complexMatrixFree z47_math_wrappers_legacy_complexMatrixFree
#define complexMatrixIdentity z47_math_wrappers_legacy_complexMatrixIdentity
#define complexMatrixRedim z47_math_wrappers_legacy_complexMatrixRedim
#define copyRealMatrix z47_math_wrappers_legacy_copyRealMatrix
#define copyComplexMatrix z47_math_wrappers_legacy_copyComplexMatrix
#define transposeRealMatrix z47_math_wrappers_legacy_transposeRealMatrix
#define transposeComplexMatrix z47_math_wrappers_legacy_transposeComplexMatrix
// Elementwise arithmetic owned by math_matrix_arithmetic_owned.zig (B2): add
// and subtract of two matrices, and multiply of a matrix by a scalar.
#define addRealMatrices z47_math_wrappers_legacy_addRealMatrices
#define subtractRealMatrices z47_math_wrappers_legacy_subtractRealMatrices
#define addComplexMatrices z47_math_wrappers_legacy_addComplexMatrices
#define subtractComplexMatrices z47_math_wrappers_legacy_subtractComplexMatrices
#define multiplyRealMatrix z47_math_wrappers_legacy_multiplyRealMatrix
#define _multiplyRealMatrix z47_math_wrappers_legacy__multiplyRealMatrix
#define multiplyComplexMatrix z47_math_wrappers_legacy_multiplyComplexMatrix
#define _multiplyComplexMatrix z47_math_wrappers_legacy__multiplyComplexMatrix
// Matrix-by-matrix products owned by math_matrix_product_owned.zig (B2b).
#define multiplyRealMatrices z47_math_wrappers_legacy_multiplyRealMatrices
#define multiplyComplexMatrices z47_math_wrappers_legacy_multiplyComplexMatrices
// Matrix-by-scalar divide owned by math_matrix_divide_scalar_owned.zig.
#define divideRealMatrix z47_math_wrappers_legacy_divideRealMatrix
#define _divideRealMatrix z47_math_wrappers_legacy__divideRealMatrix
#define divideComplexMatrix z47_math_wrappers_legacy_divideComplexMatrix
#define _divideComplexMatrix z47_math_wrappers_legacy__divideComplexMatrix
// Row/column swap owned by math_matrix_swap_owned.zig. Only the four public
// entry points are renamed; their shared static workers (_realMatrixSwap /
// _complexMatrixSwap) keep internal linkage and back the legacy copies.
#define realMatrixSwapRows z47_math_wrappers_legacy_realMatrixSwapRows
#define realMatrixSwapColumns z47_math_wrappers_legacy_realMatrixSwapColumns
#define complexMatrixSwapRows z47_math_wrappers_legacy_complexMatrixSwapRows
#define complexMatrixSwapColumns z47_math_wrappers_legacy_complexMatrixSwapColumns
// Row/column insert owned by math_matrix_insert_owned.zig.
#define insRowRealMatrix z47_math_wrappers_legacy_insRowRealMatrix
#define insColRealMatrix z47_math_wrappers_legacy_insColRealMatrix
#define insRowComplexMatrix z47_math_wrappers_legacy_insRowComplexMatrix
#define insColComplexMatrix z47_math_wrappers_legacy_insColComplexMatrix

#include "c47.h"

#include "../../src/c47/mathematics/matrix.c"