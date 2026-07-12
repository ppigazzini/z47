// Zig port of the simultaneous-linear-equation cluster of
// src/c47/mathematics/matrix.c: the SIMQ command + the Mat_A/Mat_B/Mat_X editor
// commands, and the real/complex linear-equation solvers (Ax=b via the shared
// cpxLinearEqn inverse-multiply, owned by the eigen owner). The solvers are
// public (declared in matrix.h) so they are bridge-renamed alongside the four
// commands.
const std = @import("std");
const runtime = @import("../command_wrappers_runtime.zig");
const math_matrix_eigen = @import("eigen.zig"); // M-callconv: Zig-to-Zig
const math_matrix_named = @import("named.zig"); // M-callconv: Zig-to-Zig

const real_t = runtime.real_t;
const real34_t = runtime.real34_t;
const complex34_t = runtime.complex34_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;
const calcRegister_t = runtime.calcRegister_t;
const realContext_t = runtime.realContext_t;

const REGISTER_X = runtime.REGISTER_X;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const dtReal34Matrix = runtime.dtReal34Matrix;
const dtComplex34Matrix = runtime.dtComplex34Matrix;

const MNU_SIMQ: i16 = 1347;
const MNU_TAM: i16 = 1385;
const ERROR_UNDEF_SOURCE_VAR: u8 = 36;

extern fn allocC47Blocks(size_in_blocks: usize) ?[*]align(4) real_t;
extern fn freeC47Blocks(ptr: ?[*]align(4) real_t, size_in_blocks: usize) void;
// Softmenu / matrix-editor surface (frontier owners).
extern fn showSoftmenu(id: i16) void;
extern fn popSoftmenu() void;
extern fn fnEditMatrix(unusedButMandatoryParameter: u16) void;
extern var numberOfTamMenusToPop: i16;

const REAL_SIZE_IN_BLOCKS_75: usize = 15;

inline fn rmEl(m: *const real34Matrix_t, i: usize) *real34_t {
    const e: [*]real34_t = @ptrCast(m.matrixElements);
    return &e[i];
}
inline fn cmEl(m: *const complex34Matrix_t, i: usize) *complex34_t {
    const e: [*]complex34_t = @ptrCast(m.matrixElements);
    return &e[i];
}

// --- solvers --------------------------------------------------------------

pub export fn real_matrix_linear_eqn(a: *const real34Matrix_t, b: *const real34Matrix_t, r: *real34Matrix_t) callconv(.c) void {
    const size: u16 = a.header.matrixColumns;
    const sz: usize = size;
    if (size != a.header.matrixRows) {
        mismatch(a, r, "In function real_matrix_linear_eqn:", "not a square matrix");
        return;
    }
    if (b.header.matrixRows != size or b.header.matrixColumns != 1) {
        mismatch(a, r, "In function real_matrix_linear_eqn:", "not a column vector or size mismatch");
        return;
    }
    const aBlocks = sz * sz * REAL_SIZE_IN_BLOCKS_75 * 2;
    const vBlocks = sz * REAL_SIZE_IN_BLOCKS_75 * 2;
    if (allocC47Blocks(aBlocks)) |aa| {
        if (allocC47Blocks(vBlocks)) |bb| {
            if (allocC47Blocks(vBlocks)) |rr| {
                var i: usize = 0;
                while (i < sz * sz) : (i += 1) {
                    runtime.real34ToReal(rmEl(a, i), &aa[i * 2]);
                    runtime.realSetZero(&aa[i * 2 + 1]);
                }
                i = 0;
                while (i < sz) : (i += 1) {
                    runtime.real34ToReal(rmEl(b, i), &bb[i * 2]);
                    runtime.realSetZero(&bb[i * 2 + 1]);
                }
                math_matrix_eigen.cpxLinearEqn(aa, bb, rr, size, &runtime.ctxtReal51);
                if (runtime.lastErrorCode == runtime.ERROR_NONE) {
                    if (runtime.realMatrixInit(r, size, 1)) {
                        i = 0;
                        while (i < sz) : (i += 1) runtime.realToReal34(&rr[i * 2], rmEl(r, i));
                    } else {
                        nullOutReal(a, b, r);
                        ramFull("In function real_matrix_linear_eqn:", "Ram full, 1ag");
                    }
                } else {
                    nullOutReal(a, b, r);
                }
                freeC47Blocks(rr, vBlocks);
            } else {
                nullOutReal(a, b, r);
                ramFull("In function real_matrix_linear_eqn:", "Ram full, 2ah");
            }
            freeC47Blocks(bb, vBlocks);
        } else {
            nullOutReal(a, b, r);
            ramFull("In function real_matrix_linear_eqn:", "Ram full, 3ai");
        }
        freeC47Blocks(aa, aBlocks);
    } else {
        nullOutReal(a, b, r);
        ramFull("In function real_matrix_linear_eqn:", "Ram full, 4aj");
    }
}

pub export fn complex_matrix_linear_eqn(a: *const complex34Matrix_t, b: *const complex34Matrix_t, r: *complex34Matrix_t) callconv(.c) void {
    const size: u16 = a.header.matrixColumns;
    const sz: usize = size;
    if (size != a.header.matrixRows) {
        mismatchC(a, r, "In function complex_matrix_linear_eqn:", "not a square matrix");
        return;
    }
    if (b.header.matrixRows != size or b.header.matrixColumns != 1) {
        mismatchC(a, r, "In function complex_matrix_linear_eqn:", "not a column vector or size mismatch");
        return;
    }
    const aBlocks = sz * sz * REAL_SIZE_IN_BLOCKS_75 * 2;
    const vBlocks = sz * REAL_SIZE_IN_BLOCKS_75 * 2;
    if (allocC47Blocks(aBlocks)) |aa| {
        if (allocC47Blocks(vBlocks)) |bb| {
            if (allocC47Blocks(vBlocks)) |rr| {
                var i: usize = 0;
                while (i < sz * sz) : (i += 1) {
                    runtime.real34ToReal(&cmEl(a, i).real, &aa[i * 2]);
                    runtime.real34ToReal(&cmEl(a, i).imag, &aa[i * 2 + 1]);
                }
                i = 0;
                while (i < sz) : (i += 1) {
                    runtime.real34ToReal(&cmEl(b, i).real, &bb[i * 2]);
                    runtime.real34ToReal(&cmEl(b, i).imag, &bb[i * 2 + 1]);
                }
                math_matrix_eigen.cpxLinearEqn(aa, bb, rr, size, &runtime.ctxtReal51);
                if (runtime.lastErrorCode == runtime.ERROR_NONE) {
                    if (runtime.complexMatrixInit(r, size, 1)) {
                        i = 0;
                        while (i < sz) : (i += 1) {
                            runtime.realToReal34(&rr[i * 2], &cmEl(r, i).real);
                            runtime.realToReal34(&rr[i * 2 + 1], &cmEl(r, i).imag);
                        }
                    } else {
                        nullOutComplex(a, b, r);
                        ramFull("In function complex_matrix_linear_eqn:", "Ram full, 1ak");
                    }
                } else {
                    nullOutComplex(a, b, r);
                }
                freeC47Blocks(rr, vBlocks);
            } else {
                nullOutComplex(a, b, r);
                ramFull("In function complex_matrix_linear_eqn:", "Ram full, 2al");
            }
            freeC47Blocks(bb, vBlocks);
        } else {
            nullOutComplex(a, b, r);
            ramFull("In function complex_matrix_linear_eqn:", "Ram full, 3am");
        }
        freeC47Blocks(aa, aBlocks);
    } else {
        nullOutComplex(a, b, r);
        ramFull("In function complex_matrix_linear_eqn:", "Ram full, 4an");
    }
}

fn nullOutReal(a: *const real34Matrix_t, b: *const real34Matrix_t, r: *real34Matrix_t) void {
    if (@intFromPtr(a) != @intFromPtr(r) and @intFromPtr(b) != @intFromPtr(r)) {
        r.matrixElements = null;
        r.header.matrixRows = 0;
        r.header.matrixColumns = 0;
    }
}
fn nullOutComplex(a: *const complex34Matrix_t, b: *const complex34Matrix_t, r: *complex34Matrix_t) void {
    if (@intFromPtr(a) != @intFromPtr(r) and @intFromPtr(b) != @intFromPtr(r)) {
        r.matrixElements = null;
        r.header.matrixRows = 0;
        r.header.matrixColumns = 0;
    }
}
fn ramFull(fnName: [*:0]const u8, tag: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, ERR_REGISTER_LINE, REGISTER_X);
    if (runtime.extra_info_on_calc_error) runtime.moreInfoOnError(fnName, tag, null, null);
}
fn mismatch(a: *const real34Matrix_t, r: *const real34Matrix_t, fnName: [*:0]const u8, what: []const u8) void {
    _ = r;
    runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X);
    if (runtime.extra_info_on_calc_error) {
        var buf: [80]u8 = undefined;
        const m = runtime.bufPrintZ(&buf, "{s} ({d}\xc3\x97{d})", .{ what, a.header.matrixRows, a.header.matrixColumns }) catch "mismatch";
        runtime.moreInfoOnError(fnName, m, null, null);
    }
}
fn mismatchC(a: *const complex34Matrix_t, r: *const complex34Matrix_t, fnName: [*:0]const u8, what: []const u8) void {
    _ = r;
    runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X);
    if (runtime.extra_info_on_calc_error) {
        var buf: [80]u8 = undefined;
        const m = runtime.bufPrintZ(&buf, "{s} ({d}\xc3\x97{d})", .{ what, a.header.matrixRows, a.header.matrixColumns }) catch "mismatch";
        runtime.moreInfoOnError(fnName, m, null, null);
    }
}

// --- commands -------------------------------------------------------------

pub export fn fnSimultaneousLinearEquation(numberOfUnknowns: u16) callconv(.c) void {
    if (math_matrix_named.allocateNamedMatrix("Mat_A", numberOfUnknowns, numberOfUnknowns) != runtime.INVALID_VARIABLE) {
        if (math_matrix_named.allocateNamedMatrix("Mat_B", numberOfUnknowns, 1) != runtime.INVALID_VARIABLE) {
            if (math_matrix_named.allocateNamedMatrix("Mat_X", numberOfUnknowns, 1) != runtime.INVALID_VARIABLE) {
                popSoftmenu();
                showSoftmenu(-MNU_SIMQ);
                showSoftmenu(-MNU_TAM);
                numberOfTamMenusToPop = 1;
            }
        }
    }
}

pub export fn fnEditLinearEquationMatrixA(unusedParamButMandatory: u16) callconv(.c) void {
    _ = unusedParamButMandatory;
    fnEditMatrix(@bitCast(runtime.findNamedVariable("Mat_A")));
}
pub export fn fnEditLinearEquationMatrixB(unusedParamButMandatory: u16) callconv(.c) void {
    _ = unusedParamButMandatory;
    fnEditMatrix(@bitCast(runtime.findNamedVariable("Mat_B")));
}

pub export fn fnEditLinearEquationMatrixX(unusedParamButMandatory: u16) callconv(.c) void {
    _ = unusedParamButMandatory;
    if (runtime.findNamedVariable("Mat_A") == runtime.INVALID_VARIABLE or
        runtime.findNamedVariable("Mat_B") == runtime.INVALID_VARIABLE or
        runtime.findNamedVariable("Mat_X") == runtime.INVALID_VARIABLE)
    {
        runtime.displayCalcErrorMessage(ERROR_UNDEF_SOURCE_VAR, ERR_REGISTER_LINE, REGISTER_X);
        if (runtime.extra_info_on_calc_error) runtime.moreInfoOnError("In function fnEditLinearEquationMatrixX:", "At least one of Mat_A, Mat_B or Mat_X is missing", null, null);
    } else if (runtime.getRegisterDataType(runtime.findNamedVariable("Mat_A")) == dtReal34Matrix and runtime.getRegisterDataType(runtime.findNamedVariable("Mat_B")) == dtReal34Matrix) {
        var a: real34Matrix_t = undefined;
        var b: real34Matrix_t = undefined;
        var x: real34Matrix_t = undefined;
        runtime.linkToRealMatrixRegister(runtime.findNamedVariable("Mat_A"), &a);
        runtime.linkToRealMatrixRegister(runtime.findNamedVariable("Mat_B"), &b);
        real_matrix_linear_eqn(&a, &b, &x);
        if (x.matrixElements != null) {
            runtime.convertReal34MatrixToReal34MatrixRegister(&x, runtime.findNamedVariable("Mat_X"));
            runtime.realMatrixFree(&x);
        }
    } else if (runtime.getRegisterDataType(runtime.findNamedVariable("Mat_A")) == dtReal34Matrix and runtime.getRegisterDataType(runtime.findNamedVariable("Mat_B")) == dtComplex34Matrix) {
        var a: complex34Matrix_t = undefined;
        var b: complex34Matrix_t = undefined;
        var x: complex34Matrix_t = undefined;
        runtime.convertReal34MatrixRegisterToComplex34Matrix(runtime.findNamedVariable("Mat_A"), &a);
        runtime.linkToComplexMatrixRegister(runtime.findNamedVariable("Mat_B"), &b);
        complex_matrix_linear_eqn(&a, &b, &x);
        if (x.matrixElements != null) {
            runtime.convertComplex34MatrixToComplex34MatrixRegister(&x, runtime.findNamedVariable("Mat_X"));
            runtime.complexMatrixFree(&x);
        }
        runtime.complexMatrixFree(&a);
    } else if (runtime.getRegisterDataType(runtime.findNamedVariable("Mat_A")) == dtComplex34Matrix and runtime.getRegisterDataType(runtime.findNamedVariable("Mat_B")) == dtReal34Matrix) {
        var a: complex34Matrix_t = undefined;
        var b: complex34Matrix_t = undefined;
        var x: complex34Matrix_t = undefined;
        runtime.linkToComplexMatrixRegister(runtime.findNamedVariable("Mat_A"), &a);
        runtime.convertReal34MatrixRegisterToComplex34Matrix(runtime.findNamedVariable("Mat_B"), &b);
        complex_matrix_linear_eqn(&a, &b, &x);
        if (x.matrixElements != null) {
            runtime.convertComplex34MatrixToComplex34MatrixRegister(&x, runtime.findNamedVariable("Mat_X"));
            runtime.complexMatrixFree(&x);
        }
        runtime.complexMatrixFree(&b);
    } else if (runtime.getRegisterDataType(runtime.findNamedVariable("Mat_A")) == dtComplex34Matrix and runtime.getRegisterDataType(runtime.findNamedVariable("Mat_B")) == dtComplex34Matrix) {
        var a: complex34Matrix_t = undefined;
        var b: complex34Matrix_t = undefined;
        var x: complex34Matrix_t = undefined;
        runtime.linkToComplexMatrixRegister(runtime.findNamedVariable("Mat_A"), &a);
        runtime.linkToComplexMatrixRegister(runtime.findNamedVariable("Mat_B"), &b);
        complex_matrix_linear_eqn(&a, &b, &x);
        if (x.matrixElements != null) {
            runtime.convertComplex34MatrixToComplex34MatrixRegister(&x, runtime.findNamedVariable("Mat_X"));
            runtime.complexMatrixFree(&x);
        }
    }
    if (runtime.lastErrorCode == runtime.ERROR_NONE) {
        runtime.liftStack();
        runtime.copySourceRegisterToDestRegister(runtime.findNamedVariable("Mat_X"), REGISTER_X);
        popSoftmenu();
    }
}
