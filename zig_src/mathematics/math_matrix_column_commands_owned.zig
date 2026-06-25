// Zig port of the column-reduction / search commands of
// src/c47/mathematics/matrix.c: fnColumnMin / fnColumnMax (min/max of the
// indexed column, with the row index returned in Y) and fnMatrixFind (locate a
// scalar in the indexed matrix, returning its I,J). All dispatch through the
// now-Zig callByIndexedMatrix; the static reducer/search callbacks stay
// file-local here.
const std = @import("std");
const runtime = @import("math_command_wrappers_runtime.zig");

const real_t = runtime.real_t;
const real34_t = runtime.real34_t;
const complex34_t = runtime.complex34_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;
const calcRegister_t = runtime.calcRegister_t;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const TI_TRUE: u8 = 13;
const TI_FALSE = runtime.TI_FALSE;
const FLAG_ASLIFT: i32 = 0xc023;
const REAL34_SIZE_IN_BYTES: u16 = 16;

const constants = @extern([*]const u8, .{ .name = "constants" });
inline fn cstR(comptime off: u32) *const real_t {
    return @ptrCast(@alignCast(constants + off));
}
inline fn const_minusInfinity() *const real_t {
    return cstR(1684);
}
inline fn const_plusInfinity() *const real_t {
    return cstR(1696);
}

extern fn callByIndexedMatrix(real_f: ?*const fn (*real34Matrix_t) callconv(.c) bool, complex_f: ?*const fn (*complex34Matrix_t) callconv(.c) bool) void;
extern fn getIRegisterAsInt(asArrayPointer: bool) i16;
extern fn getJRegisterAsInt(asArrayPointer: bool) i16;
extern fn real34CompareLessThan(a: *const real34_t, b: *const real34_t) bool;
extern fn real34CompareGreaterThan(a: *const real34_t, b: *const real34_t) bool;
extern fn real34CompareEqual(a: *const real34_t, b: *const real34_t) bool;
extern fn __gmpz_init(op: *runtime.mpz_struct) void;
extern fn __gmpz_set_ui(op: *runtime.mpz_struct, value: c_ulong) void;
extern fn __gmpz_clear(op: *runtime.mpz_struct) void;
extern fn convertLongIntegerRegisterToReal34(regist: calcRegister_t, r: *real34_t) void;

inline fn rmEl(m: *const real34Matrix_t, i: usize) *real34_t {
    const e: [*]real34_t = @ptrCast(m.matrixElements);
    return &e[i];
}
inline fn cmEl(m: *const complex34Matrix_t, i: usize) *complex34_t {
    const e: [*]complex34_t = @ptrCast(m.matrixElements);
    return &e[i];
}

fn columnMinMaxReal(matrix: *real34Matrix_t, calcMax: bool) bool {
    const i = getIRegisterAsInt(true);
    const j = getJRegisterAsInt(true);
    var res_r: u16 = 0;
    var res_val: real34_t = undefined;
    const cols: usize = matrix.header.matrixColumns;
    runtime.realToReal34(if (calcMax) const_minusInfinity() else const_plusInfinity(), &res_val);
    if (i >= 0 and j >= 0 and i < matrix.header.matrixRows and j < matrix.header.matrixColumns) {
        var r: usize = 0;
        while (r < matrix.header.matrixRows) : (r += 1) {
            const cell = rmEl(matrix, r * cols + @as(usize, @intCast(j)));
            if (!calcMax and real34CompareLessThan(cell, &res_val)) {
                res_val = cell.*;
                res_r = @intCast(r);
            } else if (calcMax and real34CompareGreaterThan(cell, &res_val)) {
                res_val = cell.*;
                res_r = @intCast(r);
            }
        }
        runtime.liftStack();
        runtime.setSystemFlag(FLAG_ASLIFT);
        runtime.liftStack();

        var longIntVar: runtime.longInteger_t = undefined;
        __gmpz_init(&longIntVar[0]);
        __gmpz_set_ui(&longIntVar[0], res_r + 1);
        runtime.convertLongIntegerToLongIntegerRegister(&longIntVar[0], REGISTER_Y);
        __gmpz_clear(&longIntVar[0]);

        runtime.reallocateRegister(REGISTER_X, runtime.dtReal34, REAL34_SIZE_IN_BYTES, runtime.amNone);
        runtime.registerReal34Data(REGISTER_X).* = res_val;
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        if (runtime.extra_info_on_calc_error) {
            var buf: [64]u8 = undefined;
            const m = runtime.bufPrintZ(&buf, "rows {d} and/or {d} out of range.", .{ i, j }) catch "out of range";
            runtime.moreInfoOnError("In function columnMinMaxReal:", m, null, null);
        }
        return false;
    }
    return true;
}

fn columnMinMatrix(matrix: *real34Matrix_t) callconv(.c) bool {
    return columnMinMaxReal(matrix, false);
}
fn columnMaxMatrix(matrix: *real34Matrix_t) callconv(.c) bool {
    return columnMinMaxReal(matrix, true);
}
fn columnMinMaxComplex(matrix: *complex34Matrix_t) callconv(.c) bool {
    _ = matrix;
    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    if (runtime.extra_info_on_calc_error) {
        var buf: [80]u8 = undefined;
        const tn = runtime.getRegisterDataTypeName(REGISTER_X, true, false);
        const m = runtime.bufPrintZ(&buf, "Cannot apply this function to {s}", .{tn}) catch "wrong type";
        runtime.moreInfoOnError("In function columnMinMaxComplex:", m, null, null);
    }
    return false;
}

// readSearchValue -- decode REGISTER_X into a real34 search value, returning
// false (with temporaryInformation set) when the value cannot be a plain real.
fn readSearchValue(searchVal: *real34_t) ?bool {
    switch (runtime.getRegisterDataType(REGISTER_X)) {
        runtime.dtShortInteger => {
            var x: real_t = undefined;
            runtime.convertShortIntegerRegisterToReal(REGISTER_X, &x, &runtime.ctxtReal39);
            runtime.realToReal34(&x, searchVal);
        },
        runtime.dtLongInteger => {
            convertLongIntegerRegisterToReal34(REGISTER_X, searchVal);
        },
        runtime.dtReal34 => {
            if (runtime.getRegisterAngularMode(REGISTER_X) == runtime.amNone) {
                searchVal.* = runtime.registerReal34Data(REGISTER_X).*;
            } else {
                runtime.temporaryInformation = TI_FALSE;
                return true;
            }
        },
        runtime.dtComplex34 => {
            if (runtime.real34IsZero(runtime.registerImag34Data(REGISTER_X))) {
                searchVal.* = runtime.registerReal34Data(REGISTER_X).*;
            } else {
                runtime.temporaryInformation = TI_FALSE;
                return true;
            }
        },
        else => {
            runtime.temporaryInformation = TI_FALSE;
            return true;
        },
    }
    return null;
}

fn matrixFindReal(matrix: *real34Matrix_t) callconv(.c) bool {
    var searchVal: real34_t = undefined;
    if (readSearchValue(&searchVal)) |_| return true;
    const cols: usize = matrix.header.matrixColumns;
    var r: usize = 0;
    while (r < matrix.header.matrixRows) : (r += 1) {
        var c: usize = 0;
        while (c < cols) : (c += 1) {
            if (real34CompareEqual(rmEl(matrix, r * cols + c), &searchVal)) {
                runtime.setIRegisterAsInt(true, @intCast(r));
                runtime.setJRegisterAsInt(true, @intCast(c));
                runtime.temporaryInformation = TI_TRUE;
                return true;
            }
        }
    }
    runtime.temporaryInformation = TI_FALSE;
    return true;
}

fn matrixFindComplex(matrix: *complex34Matrix_t) callconv(.c) bool {
    var searchValR: real34_t = undefined;
    var searchValI: real34_t = undefined;
    switch (runtime.getRegisterDataType(REGISTER_X)) {
        runtime.dtShortInteger => {
            var x: real_t = undefined;
            runtime.convertShortIntegerRegisterToReal(REGISTER_X, &x, &runtime.ctxtReal39);
            runtime.realToReal34(&x, &searchValR);
            runtime.real34SetZero(&searchValI);
        },
        runtime.dtLongInteger => {
            convertLongIntegerRegisterToReal34(REGISTER_X, &searchValR);
            runtime.real34SetZero(&searchValI);
        },
        runtime.dtReal34 => {
            if (runtime.getRegisterAngularMode(REGISTER_X) == runtime.amNone) {
                searchValR = runtime.registerReal34Data(REGISTER_X).*;
                runtime.real34SetZero(&searchValI);
            } else {
                runtime.temporaryInformation = TI_FALSE;
                return true;
            }
        },
        runtime.dtComplex34 => {
            searchValR = runtime.registerReal34Data(REGISTER_X).*;
            searchValI = runtime.registerImag34Data(REGISTER_X).*;
        },
        else => {
            runtime.temporaryInformation = TI_FALSE;
            return true;
        },
    }
    const cols: usize = matrix.header.matrixColumns;
    var r: usize = 0;
    while (r < matrix.header.matrixRows) : (r += 1) {
        var c: usize = 0;
        while (c < cols) : (c += 1) {
            const cell = cmEl(matrix, r * cols + c);
            if (real34CompareEqual(&cell.real, &searchValR) and real34CompareEqual(&cell.imag, &searchValI)) {
                runtime.setIRegisterAsInt(true, @intCast(r));
                runtime.setJRegisterAsInt(true, @intCast(c));
                runtime.temporaryInformation = TI_TRUE;
                return true;
            }
        }
    }
    runtime.temporaryInformation = TI_FALSE;
    return true;
}

pub export fn fnColumnMin(unusedParamButMandatory: u16) callconv(.c) void {
    _ = unusedParamButMandatory;
    callByIndexedMatrix(&columnMinMatrix, &columnMinMaxComplex);
}
pub export fn fnColumnMax(unusedParamButMandatory: u16) callconv(.c) void {
    _ = unusedParamButMandatory;
    callByIndexedMatrix(&columnMaxMatrix, &columnMinMaxComplex);
}
pub export fn fnMatrixFind(unusedParamButMandatory: u16) callconv(.c) void {
    _ = unusedParamButMandatory;
    callByIndexedMatrix(&matrixFindReal, &matrixFindComplex);
}
