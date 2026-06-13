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

#include "c47.h"

#include "../../src/c47/mathematics/matrix.c"