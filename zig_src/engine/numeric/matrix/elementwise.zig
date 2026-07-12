// Zig port of the element-wise matrix dispatch family of
// src/c47/mathematics/matrix.c. These apply a scalar command (passed as a C
// function pointer that reads/writes REGISTER_X / REGISTER_Y) to every element
// of a matrix, promoting real -> complex on demand. They are the dispatch
// substrate used by the monadic/dyadic command cells across the math owners, so
// each is exported under its canonical name and the C copy is bridge-renamed to
// the legacy prefix.
//
// callByVectorElement / callByIndexedMatrix are the indexed-matrix element
// dispatchers used by the MIM-routed commands (fnGetMatrix/fnPutMatrix/...).
const abi = @import("abi");
const std = @import("std");
const runtime = @import("../command_wrappers_runtime.zig");

const real_t = runtime.real_t;
const real34_t = runtime.real34_t;
const complex34_t = runtime.complex34_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;
const calcRegister_t = runtime.calcRegister_t;
const VoidCallback = runtime.VoidCallback;
const VoidU16Callback = ?*const fn (u16) callconv(.c) void;
const RealMatrixCallback = ?*const fn (*real34Matrix_t) callconv(.c) bool;
const ComplexMatrixCallback = ?*const fn (*complex34Matrix_t) callconv(.c) bool;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const dtReal34 = runtime.dtReal34;
const dtComplex34 = runtime.dtComplex34;
const dtReal34Matrix = runtime.dtReal34Matrix;
const dtComplex34Matrix = runtime.dtComplex34Matrix;

extern fn getRegisterAsComplexOrReal(reg: calcRegister_t, r: *real_t, i: *real_t, cmplx: *bool) bool;
extern fn __gmpz_clear(op: *runtime.mpz_struct) void;
// I/J index registers + register-range check (frontier display surface).
extern fn getIRegisterAsInt(asArrayPointer: bool) i16;
extern fn getJRegisterAsInt(asArrayPointer: bool) i16;
extern fn regInRange(r: u16) bool;

inline fn registerComplex34Data(reg: calcRegister_t) *complex34_t {
    return abi.registerComplex34Aligned(reg);
}
inline fn rmEl(m: *const real34Matrix_t, i: usize) *real34_t {
    const e: [*]real34_t = @ptrCast(m.matrixElements);
    return &e[i];
}
inline fn cmEl(m: *const complex34Matrix_t, i: usize) *complex34_t {
    const e: [*]complex34_t = @ptrCast(m.matrixElements);
    return &e[i];
}
inline fn realloc(reg: calcRegister_t, dt: u32) void {
    runtime.reallocateRegister(reg, dt, 0, runtime.amNone);
}
inline fn numElems(rows: u16, cols: u16) usize {
    return @as(usize, rows) * cols;
}

// --- real-matrix (Rema) result extraction + dispatchers -------------------

fn elementwiseRemaGetResult(complex: *bool, x: *real34Matrix_t, xc: *complex34Matrix_t, i: usize) void {
    var a: real_t = undefined;
    var b: real_t = undefined;
    var isComplex: bool = false;
    _ = getRegisterAsComplexOrReal(REGISTER_X, &a, &b, &isComplex);
    if (isComplex or complex.*) {
        if (!complex.*) {
            runtime.convertReal34MatrixToComplex34Matrix(x, xc);
            if (runtime.lastErrorCode != runtime.ERROR_RAM_FULL) {
                runtime.realMatrixFree(x);
                complex.* = true;
            }
        }
        if (complex.*) { // promotion may have failed with RAM_FULL; only write xc when it actually exists
            runtime.realToReal34(&a, &cmEl(xc, i).real);
            runtime.realToReal34(&b, &cmEl(xc, i).imag);
        }
    } else {
        runtime.realToReal34(&a, rmEl(x, i));
    }
}

pub export fn elementwiseRema(f: VoidCallback) callconv(.c) void {
    var x: real34Matrix_t = undefined;
    var xc: complex34Matrix_t = undefined;
    var complex: bool = false;
    runtime.convertReal34MatrixRegisterToReal34Matrix(REGISTER_X, &x);
    const n = numElems(x.header.matrixRows, x.header.matrixColumns);
    var i: usize = 0;
    while (i < n) : (i += 1) {
        realloc(REGISTER_X, dtReal34);
        if (complex) {
            runtime.registerReal34Data(REGISTER_X).* = cmEl(&xc, i).real;
        } else {
            runtime.registerReal34Data(REGISTER_X).* = rmEl(&x, i).*;
        }
        f.?();
        elementwiseRemaGetResult(&complex, &x, &xc, i);
    }
    if (complex) {
        runtime.convertComplex34MatrixToComplex34MatrixRegister(&xc, REGISTER_X);
        runtime.complexMatrixFree(&xc);
    } else {
        runtime.convertReal34MatrixToReal34MatrixRegister(&x, REGISTER_X);
        runtime.realMatrixFree(&x);
    }
}

pub export fn elementwiseRema_UInt16(f: VoidU16Callback, param: u16) callconv(.c) void {
    var x: real34Matrix_t = undefined;
    var xc: complex34Matrix_t = undefined;
    var complex: bool = false;
    runtime.convertReal34MatrixRegisterToReal34Matrix(REGISTER_X, &x);
    const n = numElems(x.header.matrixRows, x.header.matrixColumns);
    var i: usize = 0;
    while (i < n) : (i += 1) {
        realloc(REGISTER_X, dtReal34);
        if (complex) {
            runtime.registerReal34Data(REGISTER_X).* = cmEl(&xc, i).real;
        } else {
            runtime.registerReal34Data(REGISTER_X).* = rmEl(&x, i).*;
        }
        f.?(param);
        elementwiseRemaGetResult(&complex, &x, &xc, i);
    }
    if (complex) {
        runtime.convertComplex34MatrixToComplex34MatrixRegister(&xc, REGISTER_X);
        runtime.complexMatrixFree(&xc);
    } else {
        runtime.convertReal34MatrixToReal34MatrixRegister(&x, REGISTER_X);
        runtime.realMatrixFree(&x);
    }
}

pub export fn elementwiseRemaLonI(f: VoidCallback) callconv(.c) void {
    var y: real34Matrix_t = undefined;
    var yc: complex34Matrix_t = undefined;
    var x: runtime.longInteger_t = undefined;
    var complex: bool = false;
    runtime.convertReal34MatrixRegisterToReal34Matrix(REGISTER_Y, &y);
    runtime.convertLongIntegerRegisterToLongInteger(REGISTER_X, &x[0]);
    const n = numElems(y.header.matrixRows, y.header.matrixColumns);
    var i: usize = 0;
    while (i < n) : (i += 1) {
        realloc(REGISTER_Y, dtReal34);
        if (complex) {
            runtime.registerReal34Data(REGISTER_Y).* = cmEl(&yc, i).real;
        } else {
            runtime.registerReal34Data(REGISTER_Y).* = rmEl(&y, i).*;
        }
        runtime.convertLongIntegerToLongIntegerRegister(&x[0], REGISTER_X);
        f.?();
        elementwiseRemaGetResult(&complex, &y, &yc, i);
    }
    if (complex) {
        runtime.convertComplex34MatrixToComplex34MatrixRegister(&yc, REGISTER_X);
        runtime.complexMatrixFree(&yc);
    } else {
        runtime.convertReal34MatrixToReal34MatrixRegister(&y, REGISTER_X);
        runtime.realMatrixFree(&y);
    }
    __gmpz_clear(&x[0]);
}

pub export fn elementwiseRemaReal(f: VoidCallback) callconv(.c) void {
    var y: real34Matrix_t = undefined;
    var yc: complex34Matrix_t = undefined;
    var xin: real_t = undefined;
    var x: real34_t = undefined;
    var complex: bool = false;
    if (!runtime.getRegisterAsReal(REGISTER_X, &xin)) return;
    runtime.realToReal34(&xin, &x);
    runtime.convertReal34MatrixRegisterToReal34Matrix(REGISTER_Y, &y);
    const n = numElems(y.header.matrixRows, y.header.matrixColumns);
    var i: usize = 0;
    while (i < n) : (i += 1) {
        realloc(REGISTER_Y, dtReal34);
        realloc(REGISTER_X, dtReal34);
        if (complex) {
            runtime.registerReal34Data(REGISTER_Y).* = cmEl(&yc, i).real;
        } else {
            runtime.registerReal34Data(REGISTER_Y).* = rmEl(&y, i).*;
        }
        runtime.registerReal34Data(REGISTER_X).* = x;
        f.?();
        elementwiseRemaGetResult(&complex, &y, &yc, i);
    }
    if (complex) {
        runtime.convertComplex34MatrixToComplex34MatrixRegister(&yc, REGISTER_X);
        runtime.complexMatrixFree(&yc);
    } else {
        runtime.convertReal34MatrixToReal34MatrixRegister(&y, REGISTER_X);
        runtime.realMatrixFree(&y);
    }
}

pub export fn elementwiseRemaShoI(f: VoidCallback) callconv(.c) void {
    var y: real34Matrix_t = undefined;
    var yc: complex34Matrix_t = undefined;
    var x: u64 = undefined;
    var sign: i16 = undefined;
    var complex: bool = false;
    runtime.convertReal34MatrixRegisterToReal34Matrix(REGISTER_Y, &y);
    runtime.convertShortIntegerRegisterToUInt64(REGISTER_X, &sign, &x);
    const base = runtime.getRegisterShortIntegerBase(REGISTER_X);
    const n = numElems(y.header.matrixRows, y.header.matrixColumns);
    var i: usize = 0;
    while (i < n) : (i += 1) {
        realloc(REGISTER_Y, dtReal34);
        if (complex) {
            runtime.registerReal34Data(REGISTER_Y).* = cmEl(&yc, i).real;
        } else {
            runtime.registerReal34Data(REGISTER_Y).* = rmEl(&y, i).*;
        }
        runtime.convertUInt64ToShortIntegerRegister(sign, x, base, REGISTER_X);
        f.?();
        elementwiseRemaGetResult(&complex, &y, &yc, i);
    }
    if (complex) {
        runtime.convertComplex34MatrixToComplex34MatrixRegister(&yc, REGISTER_X);
        runtime.complexMatrixFree(&yc);
    } else {
        runtime.convertReal34MatrixToReal34MatrixRegister(&y, REGISTER_X);
        runtime.realMatrixFree(&y);
    }
}

pub export fn elementwiseRealRema(f: VoidCallback) callconv(.c) void {
    var x: real34Matrix_t = undefined;
    var xc: complex34Matrix_t = undefined;
    var yin: real_t = undefined;
    var y: real34_t = undefined;
    var complex: bool = false;
    if (!runtime.getRegisterAsReal(REGISTER_Y, &yin)) return;
    runtime.realToReal34(&yin, &y);
    runtime.convertReal34MatrixRegisterToReal34Matrix(REGISTER_X, &x);
    const n = numElems(x.header.matrixRows, x.header.matrixColumns);
    var i: usize = 0;
    while (i < n) : (i += 1) {
        realloc(REGISTER_Y, dtReal34);
        realloc(REGISTER_X, dtReal34);
        runtime.registerReal34Data(REGISTER_Y).* = y;
        if (complex) {
            runtime.registerReal34Data(REGISTER_X).* = cmEl(&xc, i).real;
        } else {
            runtime.registerReal34Data(REGISTER_X).* = rmEl(&x, i).*;
        }
        f.?();
        elementwiseRemaGetResult(&complex, &x, &xc, i);
    }
    if (complex) {
        runtime.convertComplex34MatrixToComplex34MatrixRegister(&xc, REGISTER_X);
        runtime.complexMatrixFree(&xc);
    } else {
        runtime.convertReal34MatrixToReal34MatrixRegister(&x, REGISTER_X);
        runtime.realMatrixFree(&x);
    }
}

pub export fn elementwiseRemaRema(f: VoidCallback) callconv(.c) void {
    var x: real34Matrix_t = undefined;
    var y: real34Matrix_t = undefined;
    var xc: complex34Matrix_t = undefined;
    var complex: bool = false;
    runtime.convertReal34MatrixRegisterToReal34Matrix(REGISTER_X, &x);
    runtime.convertReal34MatrixRegisterToReal34Matrix(REGISTER_Y, &y);
    if (x.header.matrixRows != y.header.matrixRows or x.header.matrixColumns != y.header.matrixColumns) {
        runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, REGISTER_X);
        return;
    }
    const n = numElems(x.header.matrixRows, x.header.matrixColumns);
    var i: usize = 0;
    while (i < n) : (i += 1) {
        realloc(REGISTER_Y, dtReal34);
        realloc(REGISTER_X, dtReal34);
        runtime.registerReal34Data(REGISTER_Y).* = rmEl(&y, i).*;
        if (complex) {
            runtime.registerReal34Data(REGISTER_X).* = cmEl(&xc, i).real;
        } else {
            runtime.registerReal34Data(REGISTER_X).* = rmEl(&x, i).*;
        }
        f.?();
        elementwiseRemaGetResult(&complex, &x, &xc, i);
    }
    runtime.realMatrixFree(&y);
    if (complex) {
        runtime.convertComplex34MatrixToComplex34MatrixRegister(&xc, REGISTER_X);
        runtime.complexMatrixFree(&xc);
    } else {
        runtime.convertReal34MatrixToReal34MatrixRegister(&x, REGISTER_X);
        runtime.realMatrixFree(&x);
    }
}

// --- complex-matrix (Cxma) result extraction + dispatchers ----------------

fn elementwiseCxmaGetResult(x: *complex34Matrix_t, i: usize) void {
    var a: real_t = undefined;
    var b: real_t = undefined;
    _ = runtime.getRegisterAsComplex(REGISTER_X, &a, &b);
    runtime.realToReal34(&a, &cmEl(x, i).real);
    runtime.realToReal34(&b, &cmEl(x, i).imag);
}

pub export fn elementwiseCxma(f: VoidCallback) callconv(.c) void {
    var x: complex34Matrix_t = undefined;
    runtime.convertComplex34MatrixRegisterToComplex34Matrix(REGISTER_X, &x);
    const n = numElems(x.header.matrixRows, x.header.matrixColumns);
    var i: usize = 0;
    while (i < n) : (i += 1) {
        realloc(REGISTER_X, dtComplex34);
        registerComplex34Data(REGISTER_X).* = cmEl(&x, i).*;
        f.?();
        elementwiseCxmaGetResult(&x, i);
    }
    runtime.convertComplex34MatrixToComplex34MatrixRegister(&x, REGISTER_X);
    runtime.complexMatrixFree(&x);
}

pub export fn elementwiseCxma_UInt16(f: VoidU16Callback, param: u16) callconv(.c) void {
    var x: complex34Matrix_t = undefined;
    runtime.convertComplex34MatrixRegisterToComplex34Matrix(REGISTER_X, &x);
    const n = numElems(x.header.matrixRows, x.header.matrixColumns);
    var i: usize = 0;
    while (i < n) : (i += 1) {
        realloc(REGISTER_X, dtComplex34);
        registerComplex34Data(REGISTER_X).* = cmEl(&x, i).*;
        f.?(param);
        elementwiseCxmaGetResult(&x, i);
    }
    runtime.convertComplex34MatrixToComplex34MatrixRegister(&x, REGISTER_X);
    runtime.complexMatrixFree(&x);
}

pub export fn elementwiseCxmaLonI(f: VoidCallback) callconv(.c) void {
    var y: complex34Matrix_t = undefined;
    var x: runtime.longInteger_t = undefined;
    runtime.convertComplex34MatrixRegisterToComplex34Matrix(REGISTER_Y, &y);
    runtime.convertLongIntegerRegisterToLongInteger(REGISTER_X, &x[0]);
    const n = numElems(y.header.matrixRows, y.header.matrixColumns);
    var i: usize = 0;
    while (i < n) : (i += 1) {
        realloc(REGISTER_Y, dtComplex34);
        registerComplex34Data(REGISTER_Y).* = cmEl(&y, i).*;
        runtime.convertLongIntegerToLongIntegerRegister(&x[0], REGISTER_X);
        f.?();
        elementwiseCxmaGetResult(&y, i);
    }
    runtime.convertComplex34MatrixToComplex34MatrixRegister(&y, REGISTER_X);
    __gmpz_clear(&x[0]);
    runtime.complexMatrixFree(&y);
}

pub export fn elementwiseCxmaReal(f: VoidCallback) callconv(.c) void {
    var y: complex34Matrix_t = undefined;
    var x: real34_t = undefined;
    var xin: real_t = undefined;
    if (!runtime.getRegisterAsReal(REGISTER_X, &xin)) return;
    runtime.realToReal34(&xin, &x);
    runtime.convertComplex34MatrixRegisterToComplex34Matrix(REGISTER_Y, &y);
    const n = numElems(y.header.matrixRows, y.header.matrixColumns);
    var i: usize = 0;
    while (i < n) : (i += 1) {
        realloc(REGISTER_Y, dtComplex34);
        realloc(REGISTER_X, dtReal34);
        registerComplex34Data(REGISTER_Y).* = cmEl(&y, i).*;
        runtime.registerReal34Data(REGISTER_X).* = x;
        f.?();
        elementwiseCxmaGetResult(&y, i);
    }
    runtime.convertComplex34MatrixToComplex34MatrixRegister(&y, REGISTER_X);
    runtime.complexMatrixFree(&y);
}

pub export fn elementwiseCxmaShoI(f: VoidCallback) callconv(.c) void {
    var y: complex34Matrix_t = undefined;
    var x: u64 = undefined;
    var sign: i16 = undefined;
    runtime.convertComplex34MatrixRegisterToComplex34Matrix(REGISTER_Y, &y);
    runtime.convertShortIntegerRegisterToUInt64(REGISTER_X, &sign, &x);
    const base = runtime.getRegisterShortIntegerBase(REGISTER_X);
    const n = numElems(y.header.matrixRows, y.header.matrixColumns);
    var i: usize = 0;
    while (i < n) : (i += 1) {
        realloc(REGISTER_Y, dtComplex34);
        registerComplex34Data(REGISTER_Y).* = cmEl(&y, i).*;
        runtime.convertUInt64ToShortIntegerRegister(sign, x, base, REGISTER_X);
        f.?();
        elementwiseCxmaGetResult(&y, i);
    }
    runtime.convertComplex34MatrixToComplex34MatrixRegister(&y, REGISTER_X);
    runtime.complexMatrixFree(&y);
}

pub export fn elementwiseCxmaCplx(f: VoidCallback) callconv(.c) void {
    var y: complex34Matrix_t = undefined;
    var x: complex34_t = undefined;
    var xReal: real_t = undefined;
    var xImag: real_t = undefined;
    if (!runtime.getRegisterAsComplex(REGISTER_X, &xReal, &xImag)) return;
    runtime.realToReal34(&xReal, &x.real);
    runtime.realToReal34(&xImag, &x.imag);
    runtime.convertComplex34MatrixRegisterToComplex34Matrix(REGISTER_Y, &y);
    const n = numElems(y.header.matrixRows, y.header.matrixColumns);
    var i: usize = 0;
    while (i < n) : (i += 1) {
        realloc(REGISTER_Y, dtComplex34);
        realloc(REGISTER_X, dtComplex34);
        registerComplex34Data(REGISTER_Y).* = cmEl(&y, i).*;
        registerComplex34Data(REGISTER_X).* = x;
        f.?();
        elementwiseCxmaGetResult(&y, i);
    }
    runtime.convertComplex34MatrixToComplex34MatrixRegister(&y, REGISTER_X);
    runtime.complexMatrixFree(&y);
}

pub export fn elementwiseRealCxma(f: VoidCallback) callconv(.c) void {
    var x: complex34Matrix_t = undefined;
    var y: real34_t = undefined;
    var yin: real_t = undefined;
    if (!runtime.getRegisterAsReal(REGISTER_Y, &yin)) return;
    runtime.realToReal34(&yin, &y);
    runtime.convertComplex34MatrixRegisterToComplex34Matrix(REGISTER_X, &x);
    const n = numElems(x.header.matrixRows, x.header.matrixColumns);
    var i: usize = 0;
    while (i < n) : (i += 1) {
        realloc(REGISTER_Y, dtReal34);
        realloc(REGISTER_X, dtComplex34);
        runtime.registerReal34Data(REGISTER_Y).* = y;
        registerComplex34Data(REGISTER_X).* = cmEl(&x, i).*;
        f.?();
        elementwiseCxmaGetResult(&x, i);
    }
    runtime.convertComplex34MatrixToComplex34MatrixRegister(&x, REGISTER_X);
    runtime.complexMatrixFree(&x);
}

pub export fn elementwiseCplxCxma(f: VoidCallback) callconv(.c) void {
    var x: complex34Matrix_t = undefined;
    var y: complex34_t = undefined;
    var yReal: real_t = undefined;
    var yImag: real_t = undefined;
    if (!runtime.getRegisterAsComplex(REGISTER_Y, &yReal, &yImag)) return;
    runtime.realToReal34(&yReal, &y.real);
    runtime.realToReal34(&yImag, &y.imag);
    runtime.convertComplex34MatrixRegisterToComplex34Matrix(REGISTER_X, &x);
    const n = numElems(x.header.matrixRows, x.header.matrixColumns);
    var i: usize = 0;
    while (i < n) : (i += 1) {
        realloc(REGISTER_Y, dtComplex34);
        realloc(REGISTER_X, dtComplex34);
        registerComplex34Data(REGISTER_Y).* = y;
        registerComplex34Data(REGISTER_X).* = cmEl(&x, i).*;
        f.?();
        elementwiseCxmaGetResult(&x, i);
    }
    runtime.convertComplex34MatrixToComplex34MatrixRegister(&x, REGISTER_X);
    runtime.complexMatrixFree(&x);
}

pub export fn elementwiseCplxRema(f: VoidCallback) callconv(.c) void {
    var x: complex34Matrix_t = undefined;
    var y: complex34_t = undefined;
    var yReal: real_t = undefined;
    var yImag: real_t = undefined;
    if (!runtime.getRegisterAsComplex(REGISTER_Y, &yReal, &yImag)) return;
    runtime.realToReal34(&yReal, &y.real);
    runtime.realToReal34(&yImag, &y.imag);
    runtime.convertReal34MatrixRegisterToComplex34Matrix(REGISTER_X, &x);
    const n = numElems(x.header.matrixRows, x.header.matrixColumns);
    var i: usize = 0;
    while (i < n) : (i += 1) {
        realloc(REGISTER_Y, dtComplex34);
        realloc(REGISTER_X, dtComplex34);
        registerComplex34Data(REGISTER_Y).* = y;
        registerComplex34Data(REGISTER_X).* = cmEl(&x, i).*;
        f.?();
        elementwiseCxmaGetResult(&x, i);
    }
    runtime.convertComplex34MatrixToComplex34MatrixRegister(&x, REGISTER_X);
    runtime.complexMatrixFree(&x);
}

pub export fn elementwiseRemaCplx(f: VoidCallback) callconv(.c) void {
    var y: complex34Matrix_t = undefined;
    var x: complex34_t = undefined;
    var xReal: real_t = undefined;
    var xImag: real_t = undefined;
    if (!runtime.getRegisterAsComplex(REGISTER_X, &xReal, &xImag)) return;
    runtime.realToReal34(&xReal, &x.real);
    runtime.realToReal34(&xImag, &x.imag);
    runtime.convertReal34MatrixRegisterToComplex34Matrix(REGISTER_Y, &y);
    const n = numElems(y.header.matrixRows, y.header.matrixColumns);
    var i: usize = 0;
    while (i < n) : (i += 1) {
        realloc(REGISTER_Y, dtComplex34);
        realloc(REGISTER_X, dtComplex34);
        registerComplex34Data(REGISTER_X).* = x;
        registerComplex34Data(REGISTER_Y).* = cmEl(&y, i).*;
        f.?();
        elementwiseCxmaGetResult(&y, i);
    }
    runtime.convertComplex34MatrixToComplex34MatrixRegister(&y, REGISTER_X);
    runtime.complexMatrixFree(&y);
}

pub export fn elementwiseCxmaRema(f: VoidCallback) callconv(.c) void {
    var x: real34Matrix_t = undefined;
    var y: complex34Matrix_t = undefined;
    runtime.convertReal34MatrixRegisterToReal34Matrix(REGISTER_X, &x);
    runtime.convertComplex34MatrixRegisterToComplex34Matrix(REGISTER_Y, &y);
    if (x.header.matrixRows != y.header.matrixRows or x.header.matrixColumns != y.header.matrixColumns) {
        runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, REGISTER_X);
        return;
    }
    const n = numElems(x.header.matrixRows, x.header.matrixColumns);
    var i: usize = 0;
    while (i < n) : (i += 1) {
        realloc(REGISTER_Y, dtComplex34);
        realloc(REGISTER_X, dtReal34);
        registerComplex34Data(REGISTER_Y).* = cmEl(&y, i).*;
        runtime.registerReal34Data(REGISTER_X).* = rmEl(&x, i).*;
        f.?();
        elementwiseCxmaGetResult(&y, i);
    }
    runtime.realMatrixFree(&x);
    runtime.convertComplex34MatrixToComplex34MatrixRegister(&y, REGISTER_X);
    runtime.complexMatrixFree(&y);
}

pub export fn elementwiseRemaCxma(f: VoidCallback) callconv(.c) void {
    var y: real34Matrix_t = undefined;
    var x: complex34Matrix_t = undefined;
    runtime.convertReal34MatrixRegisterToReal34Matrix(REGISTER_Y, &y);
    runtime.convertComplex34MatrixRegisterToComplex34Matrix(REGISTER_X, &x);
    if (x.header.matrixRows != y.header.matrixRows or x.header.matrixColumns != y.header.matrixColumns) {
        runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, REGISTER_X);
        return;
    }
    const n = numElems(x.header.matrixRows, x.header.matrixColumns);
    var i: usize = 0;
    while (i < n) : (i += 1) {
        realloc(REGISTER_Y, dtReal34);
        realloc(REGISTER_X, dtComplex34);
        runtime.registerReal34Data(REGISTER_Y).* = rmEl(&y, i).*;
        registerComplex34Data(REGISTER_X).* = cmEl(&x, i).*;
        f.?();
        elementwiseCxmaGetResult(&x, i);
    }
    runtime.realMatrixFree(&y);
    runtime.convertComplex34MatrixToComplex34MatrixRegister(&x, REGISTER_X);
    runtime.complexMatrixFree(&x);
}

pub export fn elementwiseCxmaCxma(f: VoidCallback) callconv(.c) void {
    var x: complex34Matrix_t = undefined;
    var y: complex34Matrix_t = undefined;
    runtime.convertComplex34MatrixRegisterToComplex34Matrix(REGISTER_Y, &y);
    runtime.convertComplex34MatrixRegisterToComplex34Matrix(REGISTER_X, &x);
    if (x.header.matrixRows != y.header.matrixRows or x.header.matrixColumns != y.header.matrixColumns) {
        runtime.displayCalcErrorMessage(runtime.ERROR_MATRIX_MISMATCH, runtime.ERR_REGISTER_LINE, REGISTER_X);
        return;
    }
    const n = numElems(x.header.matrixRows, x.header.matrixColumns);
    var i: usize = 0;
    while (i < n) : (i += 1) {
        realloc(REGISTER_Y, dtComplex34);
        realloc(REGISTER_X, dtComplex34);
        registerComplex34Data(REGISTER_Y).* = cmEl(&y, i).*;
        registerComplex34Data(REGISTER_X).* = cmEl(&x, i).*;
        f.?();
        elementwiseCxmaGetResult(&x, i);
    }
    runtime.complexMatrixFree(&y);
    runtime.convertComplex34MatrixToComplex34MatrixRegister(&x, REGISTER_X);
    runtime.complexMatrixFree(&x);
}

// --- indexed-matrix element dispatchers (MIM) -----------------------------

fn dispatchIndexedElement(real_f: RealMatrixCallback, complex_f: ComplexMatrixCallback, fnName: [*:0]const u8) void {
    const i = getIRegisterAsInt(true);
    const j = getJRegisterAsInt(true);
    const mi: calcRegister_t = @intCast(runtime.matrixIndex);

    if (mi == runtime.INVALID_VARIABLE or !regInRange(runtime.matrixIndex)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_OUT_OF_RANGE, runtime.ERR_REGISTER_LINE, REGISTER_X);
        if (runtime.extra_info_on_calc_error) {
            var buf: [80]u8 = undefined;
            const m = runtime.bufPrintZ(&buf, "Cannot execute: destination register is out of range: {d}", .{runtime.matrixIndex}) catch "out of range";
            runtime.moreInfoOnError(fnName, m, null, null);
        }
    } else if (runtime.getRegisterDataType(mi) == dtReal34Matrix) {
        var mat: real34Matrix_t = undefined;
        runtime.convertReal34MatrixRegisterToReal34Matrix(mi, &mat);
        if (i < 0 or i >= mat.header.matrixRows or j < 0 or j >= mat.header.matrixColumns) {
            outOfRangeElement(i, j, fnName);
        } else {
            if (real_f.?(&mat)) {
                runtime.convertReal34MatrixToReal34MatrixRegister(&mat, mi);
            }
        }
        runtime.realMatrixFree(&mat);
    } else if (runtime.getRegisterDataType(mi) == dtComplex34Matrix) {
        var mat: complex34Matrix_t = undefined;
        runtime.convertComplex34MatrixRegisterToComplex34Matrix(mi, &mat);
        if (i < 0 or i >= mat.header.matrixRows or j < 0 or j >= mat.header.matrixColumns) {
            outOfRangeElement(i, j, fnName);
        } else {
            if (complex_f.?(&mat)) {
                runtime.convertComplex34MatrixToComplex34MatrixRegister(&mat, mi);
            }
        }
        runtime.complexMatrixFree(&mat);
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, REGISTER_X);
        if (runtime.extra_info_on_calc_error) {
            var buf: [96]u8 = undefined;
            const tn = runtime.getRegisterDataTypeName(REGISTER_X, true, false);
            const m = runtime.bufPrintZ(&buf, "Cannot execute: something other than a matrix is indexed {s}", .{tn}) catch "not a matrix";
            runtime.moreInfoOnError(fnName, m, null, null);
        }
    }
}

fn outOfRangeElement(i: i16, j: i16, fnName: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_OUT_OF_RANGE, runtime.ERR_REGISTER_LINE, REGISTER_X);
    if (runtime.extra_info_on_calc_error) {
        var buf: [80]u8 = undefined;
        const m = runtime.bufPrintZ(&buf, "Cannot execute: element ({d}, {d}) out of range", .{ i + 1, j + 1 }) catch "out of range";
        runtime.moreInfoOnError(fnName, m, null, null);
    }
}

pub export fn callByVectorElement(real_f: RealMatrixCallback, complex_f: ComplexMatrixCallback) callconv(.c) void {
    dispatchIndexedElement(real_f, complex_f, "In function callByVectorElement:");
}

pub export fn callByIndexedMatrix(real_f: RealMatrixCallback, complex_f: ComplexMatrixCallback) callconv(.c) void {
    dispatchIndexedElement(real_f, complex_f, "In function callByIndexedMatrix:");
}
