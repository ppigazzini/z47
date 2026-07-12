// SPDX-License-Identifier: GPL-3.0-only
// Zig port of the register-memory core of src/c47/mathematics/matrix.c:
//   - initMatrixRegister  reallocates a register as a rows x cols real/complex
//     matrix and zeroes every element.
//   - redimMatrixRegister reshapes an existing matrix register, copying the old
//     elements into the new shape (KEEPRECT preserves the rectangle, otherwise
//     elements reflow) and zeroing whatever the new shape adds.
//   - copyAndZeroMatrixElements is the static reshape worker; ported here as a
//     generic over the element type (the C version dispatched through copy/zero
//     function pointers + an elementSize, which a typed Zig generic replaces
//     1:1: struct assignment is the byte-for-byte copy, real34SetZero the zero).
//
// initMatrixRegister/redimMatrixRegister are still externed by many already
// ported owners (allocateNamedMatrix, the fnNewMatrix/fnMatrixIdentity/stats/
// set-dimensions commands, math_prime) and by the not-yet-ported matrix engine
// inside the bridge; the bridge renames the upstream copies to
// z47_math_wrappers_legacy_* so those internal C cross-calls keep working while
// every canonical consumer resolves to this owner.

const abi = @import("abi");
const runtime = @import("../math_command_wrappers_runtime.zig");

const calcRegister_t = runtime.calcRegister_t;
const real34_t = runtime.real34_t;
const complex34_t = runtime.complex34_t;

// items.h: the redimension item codes. ITM_M_DIM keeps the rectangle vs reflow
// per dimMode == ITM_M_DIM_GR (see the KEEPRECT examples in matrix.c).
const ITM_M_DIM_GR: u16 = 1739;

// Matrix elements live immediately after the matrixHeader_t (matrix.c:
// REGISTER_*_MATRIX_ELEMENTS = getRegisterDataPointer + sizeof(matrixHeader_t)).
fn elementBase(regist: calcRegister_t) [*]u8 {
    const p: [*]u8 = abi.registerBytes(regist);
    return p + @sizeOf(runtime.matrixHeader_t);
}

fn registerRealElements(regist: calcRegister_t) [*]real34_t {
    return @ptrCast(@alignCast(elementBase(regist)));
}

fn registerComplexElements(regist: calcRegister_t) [*]complex34_t {
    return @ptrCast(@alignCast(elementBase(regist)));
}

fn zeroElement(comptime T: type, dst: *T) void {
    if (T == real34_t) {
        runtime.real34SetZero(dst);
    } else {
        // complex34ZeroWrapper: zero both the real and imaginary real34 parts.
        runtime.real34SetZero(&dst.real);
        runtime.real34SetZero(&dst.imag);
    }
}

// matrix.c copyAndZeroMatrixElements, typed per element. keepRect == (dimMode
// was ITM_M_DIM_GR). Indices are widened to usize so the row*cols products
// cannot overflow (C promotes them to int).
fn copyAndZeroMatrixElements(
    comptime T: type,
    src: [*]const T,
    dst: [*]T,
    srcRows: u16,
    srcCols: u16,
    dstRows: u16,
    dstCols: u16,
    keepRect: bool,
) void {
    if (keepRect) {
        // Copy preserving rectangular structure.
        const copyRows = @min(srcRows, dstRows);
        const copyCols = @min(srcCols, dstCols);
        var row: u16 = 0;
        while (row < copyRows) : (row += 1) {
            var col: u16 = 0;
            while (col < copyCols) : (col += 1) {
                dst[@as(usize, row) * dstCols + col] = src[@as(usize, row) * srcCols + col];
            }
        }
        // Zero new columns in existing rows.
        row = 0;
        while (row < @min(srcRows, dstRows)) : (row += 1) {
            var col: u16 = srcCols;
            while (col < dstCols) : (col += 1) {
                zeroElement(T, &dst[@as(usize, row) * dstCols + col]);
            }
        }
        // Zero entire new rows.
        row = srcRows;
        while (row < dstRows) : (row += 1) {
            var col: u16 = 0;
            while (col < dstCols) : (col += 1) {
                zeroElement(T, &dst[@as(usize, row) * dstCols + col]);
            }
        }
    } else {
        // Linear copy.
        const srcCount = @as(usize, srcRows) * srcCols;
        const dstCount = @as(usize, dstRows) * dstCols;
        var i: usize = 0;
        while (i < @min(srcCount, dstCount)) : (i += 1) {
            dst[i] = src[i];
        }
        // Zero new elements.
        if (srcCount < dstCount) {
            i = srcCount;
            while (i < dstCount) : (i += 1) {
                zeroElement(T, &dst[i]);
            }
        }
    }
}

pub export fn initMatrixRegister(regist: calcRegister_t, rows: u16, cols: u16, complex: bool) callconv(.c) bool {
    // (The upstream PC_BUILD pre-existing-error console diagnostic is omitted:
    // it only printfs to the developer console and has no calc-state effect.)
    const blocks: u16 = if (complex) runtime.COMPLEX34_SIZE_IN_BLOCKS else runtime.REAL34_SIZE_IN_BLOCKS;
    const neededSize: u16 = @truncate(@as(u32, rows) * cols * blocks);
    runtime.reallocateRegister(
        regist,
        if (complex) runtime.dtComplex34Matrix else runtime.dtReal34Matrix,
        neededSize,
        runtime.amNone,
    );
    if (regist == runtime.INVALID_VARIABLE) {
        return false;
    } else if (runtime.lastErrorCode == runtime.ERROR_NONE) {
        const header = runtime.registerMatrixHeader(regist);
        header.matrixRows = @truncate(rows);
        header.matrixColumns = @truncate(cols);
        const count: usize = @as(usize, rows) * cols;
        if (complex) {
            const elems = registerComplexElements(regist);
            var i: usize = 0;
            while (i < count) : (i += 1) {
                runtime.real34SetZero(&elems[i].real);
                runtime.real34SetZero(&elems[i].imag);
            }
        } else {
            const elems = registerRealElements(regist);
            var i: usize = 0;
            while (i < count) : (i += 1) {
                runtime.real34SetZero(&elems[i]);
            }
        }
        return true;
    } else {
        return false;
    }
}

pub export fn redimMatrixRegister(regist: calcRegister_t, rows: u16, cols: u16, dimMode: u16) callconv(.c) bool {
    if (regist == runtime.INVALID_VARIABLE) {
        return false;
    } else if (runtime.getRegisterDataType(regist) == runtime.dtReal34Matrix) {
        const header0 = runtime.registerMatrixHeader(regist);
        const origRows: u16 = header0.matrixRows;
        const origCols: u16 = header0.matrixColumns;
        const newSize: u16 = @truncate(@as(u32, rows) * cols * runtime.REAL34_SIZE_IN_BLOCKS);
        var newMatrix: runtime.real34Matrix_t = undefined;
        runtime.convertReal34MatrixRegisterToReal34Matrix(regist, &newMatrix);
        if (runtime.lastErrorCode == runtime.ERROR_NONE) {
            runtime.reallocateRegister(regist, runtime.dtReal34Matrix, newSize, runtime.amNone);
            if (runtime.lastErrorCode == runtime.ERROR_NONE) {
                const header = runtime.registerMatrixHeader(regist);
                header.matrixRows = @truncate(rows);
                header.matrixColumns = @truncate(cols);
                copyAndZeroMatrixElements(
                    real34_t,
                    @ptrCast(newMatrix.matrixElements),
                    registerRealElements(regist),
                    origRows,
                    origCols,
                    rows,
                    cols,
                    dimMode == ITM_M_DIM_GR,
                );
                runtime.realMatrixFree(&newMatrix);
                return true;
            } else {
                runtime.realMatrixFree(&newMatrix);
                return false;
            }
        } else {
            return false;
        }
    } else if (runtime.getRegisterDataType(regist) == runtime.dtComplex34Matrix) {
        const header0 = runtime.registerMatrixHeader(regist);
        const origRows: u16 = header0.matrixRows;
        const origCols: u16 = header0.matrixColumns;
        const newSize: u16 = @truncate(@as(u32, rows) * cols * runtime.COMPLEX34_SIZE_IN_BLOCKS);
        var newMatrix: runtime.complex34Matrix_t = undefined;
        runtime.convertComplex34MatrixRegisterToComplex34Matrix(regist, &newMatrix);
        if (runtime.lastErrorCode == runtime.ERROR_NONE) {
            runtime.reallocateRegister(regist, runtime.dtComplex34Matrix, newSize, runtime.amNone);
            if (runtime.lastErrorCode == runtime.ERROR_NONE) {
                const header = runtime.registerMatrixHeader(regist);
                header.matrixRows = @truncate(rows);
                header.matrixColumns = @truncate(cols);
                copyAndZeroMatrixElements(
                    complex34_t,
                    @ptrCast(newMatrix.matrixElements),
                    registerComplexElements(regist),
                    origRows,
                    origCols,
                    rows,
                    cols,
                    dimMode == ITM_M_DIM_GR,
                );
                runtime.complexMatrixFree(&newMatrix);
                return true;
            } else {
                runtime.complexMatrixFree(&newMatrix);
                return false;
            }
        } else {
            return false;
        }
    } else {
        return initMatrixRegister(regist, rows, cols, false);
    }
}
