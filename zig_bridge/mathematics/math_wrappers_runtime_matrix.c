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
// Real LU decomposition owned by math_matrix_real_lu_owned.zig.
#define WP34S_LU_decomposition z47_math_wrappers_legacy_WP34S_LU_decomposition
// Complex LU decomposition owned by math_matrix_complex_lu_owned.zig (it reuses
// the Zig-owned luCpxMat from math_matrix_complex_core_owned.zig).
#define complex_LU_decomposition z47_math_wrappers_legacy_complex_LU_decomposition
// Matrix inverse owned by math_matrix_invert_owned.zig (via the Zig dense core
// invCpxMat).
#define invertRealMatrix z47_math_wrappers_legacy_invertRealMatrix
#define invertComplexMatrix z47_math_wrappers_legacy_invertComplexMatrix
// Matrix-by-matrix divide owned by math_matrix_divide_matrices_owned.zig (y *
// inverse(x)); the dense core invCpxMat/mulCpxMat is the Zig
// math_matrix_complex_core_owned.zig copy.
#define divideRealMatrices z47_math_wrappers_legacy_divideRealMatrices
#define divideComplexMatrices z47_math_wrappers_legacy_divideComplexMatrices
// Matrix-by-scalar divide owned by math_matrix_divide_scalar_owned.zig.
#define divideRealMatrix z47_math_wrappers_legacy_divideRealMatrix
#define _divideRealMatrix z47_math_wrappers_legacy__divideRealMatrix
#define divideComplexMatrix z47_math_wrappers_legacy_divideComplexMatrix
#define _divideComplexMatrix z47_math_wrappers_legacy__divideComplexMatrix
// Reciprocal scalar-by-matrix divide (scalar / each element) also owned by
// math_matrix_divide_scalar_owned.zig.
#define divideByRealMatrix z47_math_wrappers_legacy_divideByRealMatrix
#define _divideByRealMatrix z47_math_wrappers_legacy__divideByRealMatrix
#define divideByComplexMatrix z47_math_wrappers_legacy_divideByComplexMatrix
#define _divideByComplexMatrix z47_math_wrappers_legacy__divideByComplexMatrix
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
// Row/column delete owned by math_matrix_delete_owned.zig.
#define delRowRealMatrix z47_math_wrappers_legacy_delRowRealMatrix
#define delColRealMatrix z47_math_wrappers_legacy_delColRealMatrix
#define delRowComplexMatrix z47_math_wrappers_legacy_delRowComplexMatrix
#define delColComplexMatrix z47_math_wrappers_legacy_delColComplexMatrix
// Vector size and euclidean p-norm owned by
// math_matrix_euclidean_norm_owned.zig. The static worker
// _euclideanNormRealMatrix is renamed too; the not-yet-ported vectorAngle keeps
// calling its own legacy copy until that cluster lands.
#define realVectorSize z47_math_wrappers_legacy_realVectorSize
#define complexVectorSize z47_math_wrappers_legacy_complexVectorSize
#define _euclideanNormRealMatrix z47_math_wrappers_legacy__euclideanNormRealMatrix
#define euclideanNormRealMatrix z47_math_wrappers_legacy_euclideanNormRealMatrix
#define euclideanNormComplexMatrix z47_math_wrappers_legacy_euclideanNormComplexMatrix
// Vector dot products owned by math_matrix_dot_owned.zig. The static worker
// _dotRealVectors is renamed too; the not-yet-ported vectorAngle keeps calling
// its own legacy copy until that cluster lands.
#define _dotRealVectors z47_math_wrappers_legacy__dotRealVectors
#define dotRealVectors z47_math_wrappers_legacy_dotRealVectors
#define dotComplexVectors z47_math_wrappers_legacy_dotComplexVectors
// Vector cross products owned by math_matrix_cross_owned.zig.
#define crossRealVectors z47_math_wrappers_legacy_crossRealVectors
#define crossComplexVectors z47_math_wrappers_legacy_crossComplexVectors
// Vector angle owned by math_matrix_vector_angle_owned.zig. It reuses the now
// Zig-owned _dotRealVectors / _euclideanNormRealMatrix workers.
#define vectorAngle z47_math_wrappers_legacy_vectorAngle
// Determinant owned by math_matrix_determinant_owned.zig. Only the two public
// entry points are renamed; the static LU workers (luCpxMat / detCpxMat) keep
// internal linkage and back the not-yet-ported engine (the Zig owner carries
// its own private copies).
#define detRealMatrix z47_math_wrappers_legacy_detRealMatrix
#define detComplexMatrix z47_math_wrappers_legacy_detComplexMatrix
// Matrix register-linking owned by math_matrix_register_link_owned.zig: point a
// stack-local descriptor at a register's in-place matrix data without copying.
#define linkToRealMatrixRegister z47_math_wrappers_legacy_linkToRealMatrixRegister
#define linkToComplexMatrixRegister z47_math_wrappers_legacy_linkToComplexMatrixRegister
// Named-matrix helpers owned by math_matrix_named_owned.zig.
#define allocateNamedMatrix z47_math_wrappers_legacy_allocateNamedMatrix
#define appendRowAtMatrixRegister z47_math_wrappers_legacy_appendRowAtMatrixRegister
// Matrix-register allocate/reshape core owned by
// math_matrix_register_memory_owned.zig (initMatrixRegister + redimMatrixRegister;
// the static reshape worker copyAndZeroMatrixElements keeps internal linkage and
// backs the legacy redimMatrixRegister copy, with its own private Zig copy).
#define initMatrixRegister z47_math_wrappers_legacy_initMatrixRegister
#define redimMatrixRegister z47_math_wrappers_legacy_redimMatrixRegister
// STATS-matrix undo helpers owned by math_matrix_stats_owned.zig.
#define saveStatsMatrix z47_math_wrappers_legacy_saveStatsMatrix
#define recallStatsMatrix z47_math_wrappers_legacy_recallStatsMatrix
// Matrix dimension helpers owned by math_matrix_dimension_arg_owned.zig
// (getDimensionArg keeps its static worker getSingleDimension as a private Zig
// copy; only the two public helpers are renamed).
#define getMatrixDims z47_math_wrappers_legacy_getMatrixDims
#define getDimensionArg z47_math_wrappers_legacy_getDimensionArg
// fn* matrix command wrappers owned by the math_matrix_*_command_owned.zig
// owners; the numeric primitives they drive stay in this bridge (or are already
// Zig-owned and called by their canonical names).
#define fnTranspose z47_math_wrappers_legacy_fnTranspose
#define fnDeterminant z47_math_wrappers_legacy_fnDeterminant
#define fnVectorAngle z47_math_wrappers_legacy_fnVectorAngle
// fnEuclideanNorm / fnVectorDist own their static worker _fnEuclideanNorm as a
// private Zig copy; only the two public commands are renamed.
#define fnEuclideanNorm z47_math_wrappers_legacy_fnEuclideanNorm
#define fnVectorDist z47_math_wrappers_legacy_fnVectorDist
#define fnInvertMatrix z47_math_wrappers_legacy_fnInvertMatrix
#define fnMatrixIdentity z47_math_wrappers_legacy_fnMatrixIdentity
// fnGetMatrixDimensions / fnGetMatrixDimensions42 own their static worker
// getMatrixDimensionsToStack as a private Zig copy.
#define fnGetMatrixDimensions z47_math_wrappers_legacy_fnGetMatrixDimensions
#define fnGetMatrixDimensions42 z47_math_wrappers_legacy_fnGetMatrixDimensions42
// Matrix-index helpers owned by math_matrix_index_command_owned.zig.
#define isMatrixIndexed z47_math_wrappers_legacy_isMatrixIndexed
#define fnIndexMatrix z47_math_wrappers_legacy_fnIndexMatrix
#define fnLuDecomposition z47_math_wrappers_legacy_fnLuDecomposition
#define fnQrDecomposition z47_math_wrappers_legacy_fnQrDecomposition
#define fnNewMatrix z47_math_wrappers_legacy_fnNewMatrix
// fnSetMatrixDimensions / fnSetMatrixDimensionsGr own their static worker
// _SetMatrixDimensions as a private Zig copy; only the two public commands are
// renamed.
#define fnSetMatrixDimensions z47_math_wrappers_legacy_fnSetMatrixDimensions
#define fnSetMatrixDimensionsGr z47_math_wrappers_legacy_fnSetMatrixDimensionsGr

#include "c47.h"

#include "../../src/c47/mathematics/matrix.c"