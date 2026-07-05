// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/store.c: register range validation (isRegInRange /
// regInRange), STO and the store-arithmetic commands (STO+/-/x// and STO
// min/max), STOCFG, STOS, the indexed-matrix element stores (STOEL/STOEL+/
// STOIJ) and the vector store helpers. This is a faithful, line-by-line port
// of the C. The dtConfigDescriptor_t layout is replicated byte-exactly from
// typeDefinitions.h (840 bytes); fnStoreConfig writes the same named globals
// in the same order as the C and fills the compatibility_* spare slots with
// the same defaults (false / 0 / 0.1f / 0.2f).
//
// store.c is not reachable from the testSuite; verification is by build/link
// across every target plus the boundary gates.

const std = @import("std");
const frontier_build_options = @import("frontier_build_options");
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const DECNUMUNITS = 25;
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const frontier = @import("frontier.zig"); // M-callconv: Zig-to-Zig
const frontier_char_string = @import("frontier_char_string.zig"); // M-callconv: Zig-to-Zig
const frontier_debug = @import("frontier_debug.zig"); // M-callconv: Zig-to-Zig
const frontier_error = @import("frontier_error.zig"); // M-callconv: Zig-to-Zig
const frontier_recall = @import("frontier_recall.zig"); // M-callconv: Zig-to-Zig
const frontier_register_value_conversions = @import("frontier_register_value_conversions.zig"); // M-callconv: Zig-to-Zig
const frontier_stats = @import("frontier_stats.zig"); // M-callconv: Zig-to-Zig
const real_t = abi.Real;
const real34_t = abi.Real34;
const realContext_t = abi.RealContext;
const complex34_t = abi.Complex34;
const matrixHeader_t = abi.MatrixHeader;
const real34Matrix_t = abi.Real34Matrix;
const complex34Matrix_t = abi.Complex34Matrix;
const calcRegister_t = i16;
const angularMode_t = c_int;

const mp_limb_t = usize;
const mpz_struct = abi.Mpz;
const longInteger_t = [1]mpz_struct;

const registerHeader_t = abi.RegisterHeader;
const reservedVariableHeader_t = abi.ReservedVariableHeader;

// dtConfigDescriptor_t — byte-exact mirror of typeDefinitions.h (840 bytes).
const calcKey_t = abi.CalcKey;
const normKey_t = abi.NormKey;
const pcg32_random_t = abi.Pcg32Random;
const dtConfigDescriptor_t = abi.DtConfigDescriptor;

comptime {
    if (@sizeOf(dtConfigDescriptor_t) != 840) @compileError("dtConfigDescriptor_t must be 840 bytes");
}

const subroutineLevelHeader_t = abi.SubroutineLevelHeader;

// ---------------------------------------------------------------------------
// Constants / enum values (verified against defines.h / typeDefinitions.h)
// ---------------------------------------------------------------------------
const dtLongInteger: u32 = 0;
const dtReal34: u32 = 1;
const dtComplex34: u32 = 2;
const dtReal34Matrix: u32 = 6;
const dtShortInteger: u32 = 8;
const dtConfig: u32 = 9;
const dtString: u32 = 5;

const amNone: u32 = 5;

const ERROR_NONE: u8 = 0;
const ERROR_OUT_OF_RANGE: u8 = 8;
const ERROR_STACK_CLASH: u8 = 12;
const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;
const ERROR_UNDEF_SOURCE_VAR: u8 = 36;
const ERROR_WRITE_PROTECTED_VAR: u8 = 37;
const ERROR_NO_MATRIX_INDEXED: u8 = 38;
const ERROR_NO_STRING_IN_ALPHA_REGISTER: u8 = 64;

const REGISTER_X: calcRegister_t = 100;
const REGISTER_Y: calcRegister_t = 101;
const REGISTER_Z: calcRegister_t = 102;
const REGISTER_T: calcRegister_t = 103;
const REGISTER_D: calcRegister_t = 107;
const REGISTER_I: calcRegister_t = 109;
const REGISTER_J: calcRegister_t = 110;
const REGISTER_W: calcRegister_t = 125;
const SAVED_REGISTER_X: calcRegister_t = 126;
const SAVED_REGISTER_Y: calcRegister_t = 127;
const TEMP_REGISTER_1: calcRegister_t = 135;
const FIRST_LETTERED_REGISTER: u16 = 100;
const LAST_LETTERED_REGISTER: u16 = 111;
const FIRST_STAT_REGISTER: u16 = 112;
const LAST_STAT_REGISTER: u16 = 117;
const FIRST_SPARE_REGISTER: u16 = 118;
const LAST_SPARE_REGISTER: u16 = 125;
const FIRST_TEMP_REGISTER: u16 = 135;
const LAST_TEMP_REGISTER: u16 = 136;
const FIRST_NAMED_VARIABLE: u16 = 256;
const FIRST_RESERVED_VARIABLE: u16 = 2000;
const RESERVED_VARIABLE_GRAMOD: u16 = 2040;
const RESERVED_VARIABLE_UY: u16 = 2046;
const RESERVED_VARIABLE_LY: u16 = 2047;
const LAST_RESERVED_VARIABLE: u16 = 2047;
const FIRST_LOCAL_REGISTER: u16 = 7000;
const INVALID_VARIABLE: u16 = 2199;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;
const NIM_REGISTER_LINE: calcRegister_t = REGISTER_X;

const FLAG_ASLIFT: c_uint = 0xc023;
const FLAG_SSIZE8: c_int = 0x8018;

const PGM_RUNNING: u8 = 1;
const NOPARAM: u16 = 9876;
const INC_FLAG: u16 = 0;
const C47_NULL: u16 = 65535;
const zoomOverride: i8 = 18; // graphs.h
const NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS = 10;

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------
extern var errorMessage: [*c]u8;
extern var alphaRegister: u16;
extern var lastErrorCode: u8;
extern var programRunStop: u8;
extern var shortIntegerMask: u64;
extern var matrixIndex: u16;
extern var numberOfNamedVariables: u16;
extern var currentSubroutineLevelData: ?*subroutineLevelHeader_t;
extern const allReservedVariables: [48]reservedVariableHeader_t;
extern var PLOT_ZMY: i8;

const Fn0 = ?*const fn () callconv(.c) void;
extern const addition: [NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS]Fn0;
extern const subtraction: [NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS]Fn0;
extern const multiplication: [NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS]Fn0;
extern const division: [NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS]Fn0;

// Config globals mirrored by STOCFG.
extern var shortIntegerMode: u8;
extern var shortIntegerWordSize: u8;
extern var displayFormat: u8;
extern var displayFormatDigits: u8;
extern var gapItemLeft: u16;
extern var gapItemRight: u16;
extern var gapItemRadix: u16;
extern var grpGroupingLeft: u8;
extern var grpGroupingGr1LeftOverflow: u8;
extern var grpGroupingGr1Left: u8;
extern var grpGroupingRight: u8;
extern var currentAngularMode: angularMode_t;
extern var lrSelection: u16;
extern var lrChosen: u16;
extern var denMax: u32;
extern var displayStack: u8;
extern var firstGregorianDay: u32;
extern var roundingMode: u8;
extern var systemFlags0: u64;
extern var systemFlags1: u64;
extern var kbd_usr: [37]calcKey_t;
extern var Input_Default: u8;
extern var dispBase: u8;
extern var Norm_Key_00: normKey_t;
extern var fractionDigits: u8;
extern var IrFractionsCurrentStatus: u8;
extern var displayStackSHOIDISP: u8;
extern var bcdDisplaySign: u8;
extern var DRG_Cycling: u8;
extern var DM_Cycling: u8;
extern var LongPressM: u8;
extern var LongPressF: u8;
extern var lastDenominator: u32;
extern var significantDigits: u8;
extern var pcg32_global: pcg32_random_t;
extern var exponentLimit: i16;
extern var exponentHideLimit: i16;
extern var lastIntegerBase: u32;
extern var timeDisplayFormatDigits: u8;

// ---------------------------------------------------------------------------
// Function externs
// ---------------------------------------------------------------------------
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) *anyopaque;


const c_moreInfoOnError = @extern(*const fn (m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) callconv(.c) void, .{ .name = "moreInfoOnError" });
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;
extern fn copySourceRegisterToDestRegister(rSource: calcRegister_t, rDest: calcRegister_t) void;
extern fn getSystemFlag(flag: c_int) bool;
extern fn setSystemFlag(flag: c_uint) void;
extern fn adjustResult(result: calcRegister_t, dropY: bool, setCpxRes: bool, op1: calcRegister_t, op2: calcRegister_t, op3: calcRegister_t) void;
extern fn registerMin(regist1: calcRegister_t, regist2: calcRegister_t, dest: calcRegister_t) void;
extern fn registerMax(regist1: calcRegister_t, regist2: calcRegister_t, dest: calcRegister_t) void;

extern fn reallocateRegister(regist: calcRegister_t, data_type: u32, size_blocks: u16, tag: u32) void;




extern fn getMatrixDims(regist: calcRegister_t, funcName: [*:0]const u8, rows: *u16, cols: *u16) bool;
extern fn getDimensionArg(rows: *u32, cols: *u32) bool;

extern fn callByIndexedMatrix(real_f: ?*const fn (*real34Matrix_t) callconv(.c) bool, complex_f: ?*const fn (*complex34Matrix_t) callconv(.c) bool) void;
extern fn fnLint(unusedButMandatoryParameter: u16) void;
extern fn fnToReal(unusedButMandatoryParameter: u16) void;
extern fn fnDrop(unusedButMandatoryParameter: u16) void;

extern fn liftStack() void;
extern fn findNamedVariable(variableName: [*c]const u8) calcRegister_t;





extern fn strcmp(a: [*c]const u8, b: [*c]const u8) c_int;
extern fn @"__gmpz_clear"(p: *mpz_struct) void;
extern fn @"__gmpz_cmp_si"(op: *const mpz_struct, c: c_long) c_int;
extern fn decQuadZero(r: *real34_t) *real34_t;

// stats.c owner exports.



// ---------------------------------------------------------------------------
// Inline wrappers (the C macros)
// ---------------------------------------------------------------------------
inline fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8) void {
    if (comptime extra_info) c_moreInfoOnError(m1, m2, m3, null);
}
const reg34 = abi.registerReal34;
const regImag34 = abi.registerImag34;
const regShortInt = abi.registerShortInteger;
inline fn regConfig(reg: calcRegister_t) *align(4) dtConfigDescriptor_t {
    return @ptrCast(@alignCast(getRegisterDataPointer(reg)));
}
inline fn getStackTop() calcRegister_t {
    return if (getSystemFlag(FLAG_SSIZE8)) REGISTER_D else REGISTER_T;
}
inline fn currentNumberOfLocalRegisters() u16 {
    return currentSubroutineLevelData.?.numberOfLocalRegisters;
}
inline fn real34Copy(src: *align(1) const real34_t, dst: *align(1) real34_t) void {
    dst.* = src.*;
}
inline fn real34SetZero(dst: *align(1) real34_t) void {
    var tmp: real34_t = undefined;
    _ = decQuadZero(&tmp);
    dst.* = tmp;
}
inline fn longIntegerCompareInt(op: *const mpz_struct, sint: i32) i32 {
    return @"__gmpz_cmp_si"(op, sint);
}
// VARIABLE_REAL34_DATA / VARIABLE_IMAG34_DATA on a complex34_t element.
inline fn variableReal34(elem: *align(1) complex34_t) *align(1) real34_t {
    return @ptrCast(elem);
}
inline fn variableImag34(elem: *align(1) complex34_t) *align(1) real34_t {
    return @ptrCast(@as([*]u8, @ptrCast(elem)) + 16);
}

// ===========================================================================
// isRegInRange / regInRange
// ===========================================================================
pub export fn isRegInRange(regist: u16) callconv(.c) bool {
    return (regist <= LAST_LETTERED_REGISTER) or // r00 -> r99 and includes X -> K
        (FIRST_STAT_REGISTER <= regist and regist <= LAST_STAT_REGISTER) or // M -> S
        (FIRST_SPARE_REGISTER <= regist and regist <= LAST_SPARE_REGISTER) or // E -> W
        (FIRST_LOCAL_REGISTER <= regist and @as(i32, regist) < @as(i32, FIRST_LOCAL_REGISTER) + @as(i32, currentNumberOfLocalRegisters())) or // 7000 -> 7098
        (FIRST_NAMED_VARIABLE <= regist and @as(i32, regist) < @as(i32, FIRST_NAMED_VARIABLE) + @as(i32, numberOfNamedVariables)) or // 256  -> 1999 *
        (FIRST_RESERVED_VARIABLE <= regist and regist <= LAST_RESERVED_VARIABLE) or // 2000 -> 2047 *
        (FIRST_TEMP_REGISTER <= regist and regist <= LAST_TEMP_REGISTER); // 135, 136
}

pub export fn regInRange(regist: u16) callconv(.c) bool {
    if (isRegInRange(regist)) {
        return true;
    }
    if (comptime extra_info) {
        var regType: [*:0]const u8 = undefined;
        var offset: u16 = undefined;
        var errorType: u8 = ERROR_OUT_OF_RANGE;

        if (regist <= LAST_LETTERED_REGISTER) {
            regType = "Lettered register";
            offset = regist -% FIRST_LETTERED_REGISTER;
        } else if (FIRST_STAT_REGISTER <= regist and regist <= LAST_STAT_REGISTER) {
            regType = "Stat register";
            offset = regist - FIRST_STAT_REGISTER;
        } else if (FIRST_SPARE_REGISTER <= regist and regist <= LAST_SPARE_REGISTER) {
            regType = "Spare register";
            offset = regist - FIRST_SPARE_REGISTER;
        } else if (FIRST_LOCAL_REGISTER <= regist and @as(i32, regist) < @as(i32, FIRST_LOCAL_REGISTER) + @as(i32, currentNumberOfLocalRegisters())) {
            regType = "local register .";
            offset = regist - FIRST_LOCAL_REGISTER;
        } else if (FIRST_NAMED_VARIABLE <= regist and @as(i32, regist) < @as(i32, FIRST_NAMED_VARIABLE) + @as(i32, numberOfNamedVariables)) {
            regType = "named register .";
            offset = regist - FIRST_NAMED_VARIABLE;
            errorType = ERROR_UNDEF_SOURCE_VAR;
        } else if (FIRST_RESERVED_VARIABLE <= regist and regist <= LAST_RESERVED_VARIABLE) {
            regType = "reserved variable";
            offset = regist - FIRST_RESERVED_VARIABLE;
        } else if (FIRST_TEMP_REGISTER <= regist and regist <= LAST_TEMP_REGISTER) {
            regType = "temporary register";
            offset = regist -% LAST_TEMP_REGISTER;
        } else {
            regType = "generic";
            offset = 0;
        }
        frontier_error.displayCalcErrorMessage(errorType, ERR_REGISTER_LINE, REGISTER_X);
        if (strcmp(regType, "generic") == 0) {
            abi.fmtBufZ(errorMessage[0..512], "generic", .{});
        } else {
            abi.fmtBufZ(errorMessage[0..512], "{s} {d:0>4}", .{ regType, offset });
        }
        c_moreInfoOnError("In function regInRange:", errorMessage, " is not defined!", null);
    } else {
        frontier_error.displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    }
    return false;
}

// ===========================================================================
// _checkReadOnlyVariable (static in the C)
// ===========================================================================
fn _checkReadOnlyVariable(regist: u16) bool {
    if (FIRST_RESERVED_VARIABLE <= regist and regist <= LAST_RESERVED_VARIABLE and allReservedVariables[regist - FIRST_RESERVED_VARIABLE].header.bits.readOnly == 1) {
        frontier_error.displayCalcErrorMessage(ERROR_WRITE_PROTECTED_VAR, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "reserved variable {s}", .{std.mem.span(@as([*c]const u8, @ptrCast(&allReservedVariables[regist - FIRST_RESERVED_VARIABLE].reservedVariableName)) + 1)});
            moreInfoOnError("In function _checkReadOnlyVariable:", errorMessage, " is write-protected!");
        }
        return false;
    } else {
        return true;
    }
}

// ===========================================================================
// Indexed-matrix element store callbacks (static in the C)
// ===========================================================================
fn storeElementReal(matrix: *real34Matrix_t) callconv(.c) bool {
    const i: i16 = frontier.getIRegisterAsInt(true);
    const j: i16 = frontier.getJRegisterAsInt(true);
    const idx: usize = @intCast(@as(i32, i) * @as(i32, @as(u16, matrix.header.matrixColumns)) + @as(i32, j));

    if (getRegisterDataType(REGISTER_X) == dtLongInteger) {
        frontier_register_value_conversions.convertLongIntegerRegisterToReal34(REGISTER_X, @ptrCast(&matrix.matrixElements.?[idx]));
    } else if (getRegisterDataType(REGISTER_X) == dtReal34) {
        real34Copy(reg34(REGISTER_X), @ptrCast(&matrix.matrixElements.?[idx]));
    } else {
        frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "Cannot store {s} in a matrix", .{std.mem.span(frontier_debug.getRegisterDataTypeName(REGISTER_X, true, false))});
            moreInfoOnError("In function storeElementReal:", errorMessage, null);
        }
        return false;
    }
    return true;
}

fn storeElementComplex(matrix: *complex34Matrix_t) callconv(.c) bool {
    const i: i16 = frontier.getIRegisterAsInt(true);
    const j: i16 = frontier.getJRegisterAsInt(true);
    const idx: usize = @intCast(@as(i32, i) * @as(i32, @as(u16, matrix.header.matrixColumns)) + @as(i32, j));
    const elem: *align(1) complex34_t = @ptrCast(&matrix.matrixElements.?[idx]);

    if (getRegisterDataType(REGISTER_X) == dtLongInteger) {
        frontier_register_value_conversions.convertLongIntegerRegisterToReal34(REGISTER_X, variableReal34(elem));
        real34SetZero(variableImag34(elem));
    } else if (getRegisterDataType(REGISTER_X) == dtReal34) {
        real34Copy(reg34(REGISTER_X), variableReal34(elem));
        real34SetZero(variableImag34(elem));
    } else if (getRegisterDataType(REGISTER_X) == dtComplex34) {
        real34Copy(reg34(REGISTER_X), variableReal34(elem));
        real34Copy(regImag34(REGISTER_X), variableImag34(elem));
    } else {
        frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "Cannot store {s} in a matrix", .{std.mem.span(frontier_debug.getRegisterDataTypeName(REGISTER_X, true, false))});
            moreInfoOnError("In function storeElementReal:", errorMessage, null);
        }
        return false;
    }
    return true;
}

fn storeIjReal(matrix: *real34Matrix_t) callconv(.c) bool {
    var rows: u32 = undefined;
    var cols: u32 = undefined;
    if (getDimensionArg(&rows, &cols)) {
        if (rows > 0 and rows <= @as(u32, @as(u16, matrix.header.matrixRows)) and cols > 0 and cols <= @as(u32, @as(u16, matrix.header.matrixColumns))) {
            copySourceRegisterToDestRegister(REGISTER_Y, REGISTER_I);
            copySourceRegisterToDestRegister(REGISTER_X, REGISTER_J);
            return true;
        } else {
            frontier_error.displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                abi.fmtBufZ(errorMessage[0..512], "({d}, {d}) out of range", .{ rows, cols });
                moreInfoOnError("In function storeIjReal:", errorMessage, null);
            }
        }
    } else if (lastErrorCode == ERROR_NONE) {
        frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "Cannot store {s} as matrix index", .{std.mem.span(frontier_debug.getRegisterDataTypeName(REGISTER_X, true, false))});
            moreInfoOnError("In function storeIjReal:", errorMessage, null);
        }
    }
    return false;
}

fn storeIjComplex(matrix: *complex34Matrix_t) callconv(.c) bool {
    return storeIjReal(@ptrCast(matrix));
}

// ===========================================================================
// _storeValue (static in the C)
// ===========================================================================
fn _storeValue(regist: u16) void {
    if (regist == RESERVED_VARIABLE_UY or regist == RESERVED_VARIABLE_LY) {
        PLOT_ZMY = zoomOverride; // PLOT EQN
    }
    if (regist == RESERVED_VARIABLE_GRAMOD) {
        copySourceRegisterToDestRegister(REGISTER_X, TEMP_REGISTER_1);
        fnLint(NOPARAM);
        if (lastErrorCode == ERROR_NONE) {
            var x: longInteger_t = undefined;
            frontier_register_value_conversions.convertLongIntegerRegisterToLongInteger(REGISTER_X, &x[0]);
            if (longIntegerCompareInt(&x[0], 0) >= 0 and longIntegerCompareInt(&x[0], 3) <= 0) {
                copySourceRegisterToDestRegister(REGISTER_X, @intCast(regist));
                copySourceRegisterToDestRegister(TEMP_REGISTER_1, REGISTER_X);
            } else {
                frontier_error.displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
                if (comptime extra_info) {
                    moreInfoOnError("In function _storeValue:", "Invalid value for GRAMOD", null);
                }
            }
            @"__gmpz_clear"(&x[0]); // longIntegerFree
        }
    } else if (FIRST_RESERVED_VARIABLE <= regist and regist <= LAST_RESERVED_VARIABLE and allReservedVariables[regist - FIRST_RESERVED_VARIABLE].header.bits.dataType == dtReal34) {
        copySourceRegisterToDestRegister(REGISTER_X, TEMP_REGISTER_1);
        fnToReal(NOPARAM);
        if (lastErrorCode == ERROR_NONE) {
            copySourceRegisterToDestRegister(REGISTER_X, @intCast(regist));
            copySourceRegisterToDestRegister(TEMP_REGISTER_1, REGISTER_X);
        }
    } else {
        copySourceRegisterToDestRegister(REGISTER_X, @intCast(regist));
    }
}

// ===========================================================================
// fnStore / fn2Sto / fn3Sto
// ===========================================================================
pub export fn fnStore(regist: u16) callconv(.c) void {
    if (_checkReadOnlyVariable(regist) and regInRange(regist)) {
        _storeValue(regist);
        var rows: u16 = 1;
        if (regist >= FIRST_NAMED_VARIABLE and @as(calcRegister_t, @intCast(regist)) == findNamedVariable("STATS")) {
            if (frontier_stats.isStatsMatrixN(&rows, @intCast(regist))) {
                frontier_stats.calcSigma(0);
            } else {
                frontier_stats.clearStatisticalSums();
            }
        }
    }
}

pub export fn fn2Sto(regist: u16) callconv(.c) void {
    if ((regist <= (@as(u16, @intCast(REGISTER_X)) - 1) - 1) or
        (regist >= @as(u16, @intCast(REGISTER_X)) and regist <= @as(u16, @intCast(REGISTER_W)) - 1) or
        (FIRST_LOCAL_REGISTER <= regist and @as(i32, regist) < @as(i32, FIRST_LOCAL_REGISTER) + @as(i32, currentNumberOfLocalRegisters()) - 1))
    {
        setSystemFlag(FLAG_ASLIFT);
        copySourceRegisterToDestRegister(REGISTER_X, @intCast(regist + 0));
        copySourceRegisterToDestRegister(REGISTER_Y, @intCast(regist + 1));
    } else {
        frontier_error.displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "{d:0>4}", .{@as(u32, @intCast(regist))});
            moreInfoOnError("In function fn2Sto:", errorMessage, " is not defined!");
        }
    }
}

pub export fn fn3Sto(regist: u16) callconv(.c) void {
    if ((regist <= (@as(u16, @intCast(REGISTER_X)) - 1) - 2) or
        (regist >= @as(u16, @intCast(REGISTER_X)) and regist <= @as(u16, @intCast(REGISTER_W)) - 2) or
        (FIRST_LOCAL_REGISTER <= regist and @as(i32, regist) < @as(i32, FIRST_LOCAL_REGISTER) + @as(i32, currentNumberOfLocalRegisters()) - 2))
    {
        setSystemFlag(FLAG_ASLIFT);
        copySourceRegisterToDestRegister(REGISTER_X, @intCast(regist + 0));
        copySourceRegisterToDestRegister(REGISTER_Y, @intCast(regist + 1));
        copySourceRegisterToDestRegister(REGISTER_Z, @intCast(regist + 2));
    } else {
        frontier_error.displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "{d:0>4}", .{@as(u32, @intCast(regist))});
            moreInfoOnError("In function fn3Sto:", errorMessage, " is not defined!");
        }
    }
}

// ===========================================================================
// Store arithmetic
// ===========================================================================
pub export fn fnStoreAdd(regist: u16) callconv(.c) void {
    if (_checkReadOnlyVariable(regist) and regInRange(regist)) {
        if (programRunStop == PGM_RUNNING) {
            copySourceRegisterToDestRegister(REGISTER_Y, SAVED_REGISTER_Y);
            copySourceRegisterToDestRegister(REGISTER_X, SAVED_REGISTER_X);
        }

        copySourceRegisterToDestRegister(@intCast(regist), REGISTER_Y);
        if (getRegisterDataType(REGISTER_Y) == dtShortInteger) {
            regShortInt(REGISTER_Y).* &= shortIntegerMask;
        }

        addition[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)].?();

        copySourceRegisterToDestRegister(SAVED_REGISTER_Y, REGISTER_Y);
        _storeValue(regist);
        if (regist != @as(u16, @intCast(REGISTER_X))) {
            copySourceRegisterToDestRegister(SAVED_REGISTER_X, REGISTER_X);
        }

        adjustResult(REGISTER_X, false, true, REGISTER_X, @intCast(regist), -1);
        var rows: u16 = 1;
        if (regist >= FIRST_NAMED_VARIABLE and frontier_stats.isStatsMatrixN(&rows, @intCast(regist)) and @as(calcRegister_t, @intCast(regist)) == findNamedVariable("STATS")) {
            frontier_stats.calcSigma(0);
        }
    }
}

pub export fn fnStoreSub(regist: u16) callconv(.c) void {
    if (_checkReadOnlyVariable(regist) and regInRange(regist)) {
        if (programRunStop == PGM_RUNNING) {
            copySourceRegisterToDestRegister(REGISTER_Y, SAVED_REGISTER_Y);
            copySourceRegisterToDestRegister(REGISTER_X, SAVED_REGISTER_X);
        }

        copySourceRegisterToDestRegister(@intCast(regist), REGISTER_Y);
        if (getRegisterDataType(REGISTER_Y) == dtShortInteger) {
            regShortInt(REGISTER_Y).* &= shortIntegerMask;
        }

        subtraction[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)].?();

        copySourceRegisterToDestRegister(SAVED_REGISTER_Y, REGISTER_Y);
        _storeValue(regist);
        if (regist != @as(u16, @intCast(REGISTER_X))) {
            copySourceRegisterToDestRegister(SAVED_REGISTER_X, REGISTER_X);
        }

        adjustResult(REGISTER_X, false, true, REGISTER_X, @intCast(regist), -1);
        var rows: u16 = 1;
        if (regist >= FIRST_NAMED_VARIABLE and frontier_stats.isStatsMatrixN(&rows, @intCast(regist)) and @as(calcRegister_t, @intCast(regist)) == findNamedVariable("STATS")) {
            frontier_stats.calcSigma(0);
        }
    }
}

pub export fn fnStoreMult(regist: u16) callconv(.c) void {
    if (_checkReadOnlyVariable(regist) and regInRange(regist)) {
        if (programRunStop == PGM_RUNNING) {
            copySourceRegisterToDestRegister(REGISTER_Y, SAVED_REGISTER_Y);
            copySourceRegisterToDestRegister(REGISTER_X, SAVED_REGISTER_X);
        }

        copySourceRegisterToDestRegister(@intCast(regist), REGISTER_Y);
        if (getRegisterDataType(REGISTER_Y) == dtShortInteger) {
            regShortInt(REGISTER_Y).* &= shortIntegerMask;
        }

        multiplication[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)].?();

        copySourceRegisterToDestRegister(SAVED_REGISTER_Y, REGISTER_Y);
        _storeValue(regist);
        if (regist != @as(u16, @intCast(REGISTER_X))) {
            copySourceRegisterToDestRegister(SAVED_REGISTER_X, REGISTER_X);
        }

        adjustResult(REGISTER_X, false, true, REGISTER_X, @intCast(regist), -1);
        var rows: u16 = 1;
        if (regist >= FIRST_NAMED_VARIABLE and frontier_stats.isStatsMatrixN(&rows, @intCast(regist)) and @as(calcRegister_t, @intCast(regist)) == findNamedVariable("STATS")) {
            frontier_stats.calcSigma(0);
        }
    }
}

pub export fn fnStoreDiv(regist: u16) callconv(.c) void {
    if (_checkReadOnlyVariable(regist) and regInRange(regist)) {
        if (programRunStop == PGM_RUNNING) {
            copySourceRegisterToDestRegister(REGISTER_Y, SAVED_REGISTER_Y);
            copySourceRegisterToDestRegister(REGISTER_X, SAVED_REGISTER_X);
        }

        copySourceRegisterToDestRegister(@intCast(regist), REGISTER_Y);
        if (getRegisterDataType(REGISTER_Y) == dtShortInteger) {
            regShortInt(REGISTER_Y).* &= shortIntegerMask;
        }

        division[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)].?();

        copySourceRegisterToDestRegister(SAVED_REGISTER_Y, REGISTER_Y);
        _storeValue(regist);
        if (regist != @as(u16, @intCast(REGISTER_X))) {
            copySourceRegisterToDestRegister(SAVED_REGISTER_X, REGISTER_X);
        }

        adjustResult(REGISTER_X, false, true, REGISTER_X, @intCast(regist), -1);
        var rows: u16 = 1;
        if (regist >= FIRST_NAMED_VARIABLE and frontier_stats.isStatsMatrixN(&rows, @intCast(regist)) and @as(calcRegister_t, @intCast(regist)) == findNamedVariable("STATS")) {
            frontier_stats.calcSigma(0);
        }
    }
}

pub export fn fnStoreMin(regist_arg: u16) callconv(.c) void {
    var regist = regist_arg;
    if (_checkReadOnlyVariable(regist) and regInRange(regist)) {
        copySourceRegisterToDestRegister(REGISTER_X, SAVED_REGISTER_X);
        if (FIRST_RESERVED_VARIABLE <= regist and regist < LAST_RESERVED_VARIABLE and allReservedVariables[regist - FIRST_RESERVED_VARIABLE].header.bits.pointerToRegisterData == C47_NULL) {
            copySourceRegisterToDestRegister(@intCast(regist), TEMP_REGISTER_1);
            regist = @intCast(TEMP_REGISTER_1);
        } else if (FIRST_RESERVED_VARIABLE <= regist and regist < LAST_RESERVED_VARIABLE and allReservedVariables[regist - FIRST_RESERVED_VARIABLE].header.bits.pointerToRegisterData == C47_NULL) {
            fnToReal(NOPARAM);
            if (lastErrorCode == ERROR_NONE) {
                copySourceRegisterToDestRegister(@intCast(regist), TEMP_REGISTER_1);
                regist = @intCast(TEMP_REGISTER_1);
            }
        }
        registerMin(REGISTER_X, @intCast(regist), @intCast(regist));
        copySourceRegisterToDestRegister(SAVED_REGISTER_X, REGISTER_X);
    }
}

pub export fn fnStoreMax(regist_arg: u16) callconv(.c) void {
    var regist = regist_arg;
    if (_checkReadOnlyVariable(regist) and regInRange(regist)) {
        copySourceRegisterToDestRegister(REGISTER_X, SAVED_REGISTER_X);
        if (FIRST_RESERVED_VARIABLE <= regist and regist < LAST_RESERVED_VARIABLE and allReservedVariables[regist - FIRST_RESERVED_VARIABLE].header.bits.pointerToRegisterData == C47_NULL) {
            copySourceRegisterToDestRegister(@intCast(regist), TEMP_REGISTER_1);
            regist = @intCast(TEMP_REGISTER_1);
        } else if (FIRST_RESERVED_VARIABLE <= regist and regist < LAST_RESERVED_VARIABLE and allReservedVariables[regist - FIRST_RESERVED_VARIABLE].header.bits.pointerToRegisterData == C47_NULL) {
            fnToReal(NOPARAM);
            if (lastErrorCode == ERROR_NONE) {
                copySourceRegisterToDestRegister(@intCast(regist), TEMP_REGISTER_1);
                regist = @intCast(TEMP_REGISTER_1);
            }
        }
        registerMax(REGISTER_X, @intCast(regist), @intCast(regist));
        copySourceRegisterToDestRegister(SAVED_REGISTER_X, REGISTER_X);
    }
}

// ===========================================================================
// fnStoreConfig
// ===========================================================================
pub export fn fnStoreConfig(regist: u16) callconv(.c) void {
    // Defaults to use when settings are removed (matches the C local values).
    const compatibility_int1: i16 = 0;
    const compatibility_byte00: bool = false;
    const compatibility_byte1: u8 = 0;
    const compatibility_byte2: bool = false;
    const compatibility_byte3: bool = false;
    const compatibility_byte4: bool = false;
    const compatibility_byte5: bool = false;
    const compatibility_byte6: bool = false;
    const compatibility_byte7: bool = false;
    const compatibility_byte8: bool = false;
    const compatibility_byte9: bool = false;
    const compatibility_byte10: bool = false;
    const compatibility_byte11: bool = false;
    const compatibility_byte12: bool = false;
    const compatibility_byte13: bool = false;
    const compatibility_byte14: bool = false;
    const compatibility_byte15: bool = false;
    const compatibility_byte16: bool = false;
    const compatibility_byte17: bool = false;
    const compatibility_byte18: bool = false;
    const compatibility_byte19: bool = false;
    const compatibility_byte20: bool = false;
    const compatibility_byte21: bool = false;
    const compatibility_byte22: bool = false;
    const compatibility_byte23: bool = false;
    const compatibility_byte24: bool = false;
    const compatibility_byte25: bool = false;
    const compatibility_byte26: bool = false;
    const compatibility_byte27: bool = false;
    const compatibility_byte28: bool = false;
    const compatibility_byte29: bool = false;
    const compatibility_byte30: bool = false;
    const compatibility_byte31: bool = false;
    const compatibility_float1: f32 = 0.1;
    const compatibility_float2: f32 = 0.2;
    reallocateRegister(@intCast(regist), dtConfig, 0, amNone);
    const configToStore = regConfig(@intCast(regist));

    configToStore.shortIntegerMode = shortIntegerMode;
    configToStore.shortIntegerWordSize = shortIntegerWordSize;
    configToStore.displayFormat = displayFormat;
    configToStore.displayFormatDigits = displayFormatDigits;
    configToStore.gapItemLeft = gapItemLeft;
    configToStore.gapItemRight = gapItemRight;
    configToStore.gapItemRadix = gapItemRadix;
    configToStore.grpGroupingLeft = grpGroupingLeft;
    configToStore.grpGroupingGr1LeftOverflow = grpGroupingGr1LeftOverflow;
    configToStore.grpGroupingGr1Left = grpGroupingGr1Left;
    configToStore.grpGroupingRight = grpGroupingRight;
    configToStore.currentAngularMode = currentAngularMode;
    configToStore.lrSelection = lrSelection;
    configToStore.lrChosen = lrChosen;
    configToStore.denMax = denMax;
    configToStore.displayStack = displayStack;
    configToStore.firstGregorianDay = firstGregorianDay;
    configToStore.roundingMode = roundingMode;
    configToStore.systemFlags0 = systemFlags0;
    configToStore.systemFlags1 = systemFlags1;
    _ = frontier_char_string.xcopy(@ptrCast(&configToStore.kbd_usr), @ptrCast(&kbd_usr), @sizeOf(@TypeOf(kbd_usr)));
    configToStore.compatibility_byte1 = compatibility_byte1;
    configToStore.compatibility_byte19 = compatibility_byte19;
    configToStore.compatibility_byte28 = compatibility_byte28;
    configToStore.compatibility_byte29 = compatibility_byte29;
    configToStore.compatibility_byte21 = compatibility_byte21;
    configToStore.compatibility_byte30 = compatibility_byte30;
    configToStore.compatibility_byte00 = compatibility_byte00; // added
    configToStore.compatibility_int1 = compatibility_int1; // added
    configToStore.Input_Default = Input_Default;
    configToStore.dispBase = dispBase != 0;
    configToStore.compatibility_byte31 = compatibility_byte31;
    configToStore.compatibility_byte26 = compatibility_byte26;
    configToStore.compatibility_float1 = compatibility_float1;
    configToStore.compatibility_float2 = compatibility_float2;
    configToStore.Norm_Key_00.func = Norm_Key_00.func;
    _ = frontier_char_string.xcopy(@ptrCast(&configToStore.Norm_Key_00.funcParam), @ptrCast(&Norm_Key_00.funcParam), @sizeOf(@TypeOf(Norm_Key_00.funcParam)));
    configToStore.Norm_Key_00.used = Norm_Key_00.used;
    configToStore.compatibility_byte2 = compatibility_byte2;
    configToStore.compatibility_byte3 = compatibility_byte3;
    configToStore.compatibility_byte4 = compatibility_byte4;
    configToStore.compatibility_byte5 = compatibility_byte5;
    configToStore.compatibility_byte6 = compatibility_byte6;
    configToStore.compatibility_byte7 = compatibility_byte7;
    configToStore.compatibility_byte8 = compatibility_byte8;
    configToStore.compatibility_byte9 = compatibility_byte9;
    configToStore.compatibility_byte10 = compatibility_byte10;
    configToStore.compatibility_byte11 = compatibility_byte11;
    configToStore.compatibility_byte12 = compatibility_byte12;
    configToStore.compatibility_byte13 = compatibility_byte13;
    configToStore.compatibility_byte14 = compatibility_byte14;
    configToStore.compatibility_byte15 = compatibility_byte15;
    configToStore.fractionDigits = @bitCast(fractionDigits);
    configToStore.compatibility_byte23 = @intFromBool(compatibility_byte23);
    configToStore.compatibility_byte16 = compatibility_byte16;
    configToStore.compatibility_byte20 = compatibility_byte20;
    configToStore.compatibility_byte17 = compatibility_byte17;
    configToStore.IrFractionsCurrentStatus = IrFractionsCurrentStatus;
    configToStore.compatibility_byte18 = compatibility_byte18;
    configToStore.displayStackSHOIDISP = displayStackSHOIDISP;
    configToStore.compatibility_byte25 = compatibility_byte25;
    configToStore.compatibility_byte24 = compatibility_byte24;
    configToStore.bcdDisplaySign = bcdDisplaySign;
    configToStore.DRG_Cycling = DRG_Cycling;
    configToStore.DM_Cycling = DM_Cycling;
    configToStore.compatibility_byte22 = compatibility_byte22;
    configToStore.LongPressM = LongPressM;
    configToStore.LongPressF = LongPressF;
    configToStore.lastDenominator = lastDenominator;
    configToStore.significantDigits = significantDigits;
    configToStore.pcg32_global = pcg32_global;
    configToStore.exponentLimit = exponentLimit;
    configToStore.exponentHideLimit = exponentHideLimit;
    configToStore.lastIntegerBase = lastIntegerBase;
    configToStore.compatibility_byte27 = compatibility_byte27;
    configToStore.timeDisplayFormatDigits = timeDisplayFormatDigits;
}

// ===========================================================================
// fnStoreStack
// ===========================================================================
pub export fn fnStoreStack(regist: u16) callconv(.c) void {
    const size: u16 = if (getSystemFlag(FLAG_SSIZE8)) 8 else 4;

    if (@as(i32, regist) + @as(i32, size) >= REGISTER_X and @as(i32, regist) < REGISTER_X) {
        frontier_error.displayCalcErrorMessage(ERROR_STACK_CLASH, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "Cannot execute STOS, destination register would overlap the stack: {d}", .{@as(i32, regist)});
            moreInfoOnError("In function fnStoreStack:", errorMessage, null);
        }
    } else if ((regist >= @as(u16, @intCast(REGISTER_X)) and regist < FIRST_LOCAL_REGISTER) or @as(i32, regist) + @as(i32, size) > @as(i32, FIRST_LOCAL_REGISTER) + @as(i32, currentNumberOfLocalRegisters())) {
        frontier_error.displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "Cannot execute STOS, destination register is out of range: {d}", .{@as(i32, regist)});
            moreInfoOnError("In function fnStoreStack:", errorMessage, null);
        }
    } else {
        var i: i32 = 0;
        while (i < size) : (i += 1) {
            copySourceRegisterToDestRegister(@intCast(@as(i32, REGISTER_X) + i), @intCast(@as(i32, regist) + i));
        }
    }
}

// ===========================================================================
// Matrix element store
// ===========================================================================
pub export fn fnStoreVElement(ix: u16) callconv(.c) void {
    const matrixIndexBak: u16 = matrixIndex;
    const iBak: i16 = frontier.getIRegisterAsInt(true);
    const jBak: i16 = frontier.getJRegisterAsInt(true);
    var rx: real_t = undefined;
    var rows: u16 = undefined;
    var cols: u16 = undefined;
    if (!getMatrixDims(REGISTER_Y, "In function fnStoreVElement:", &rows, &cols)) {
        return;
    }
    if (!frontier_register_value_conversions.getRegisterAsComplex(REGISTER_X, &rx, &rx) and !frontier_register_value_conversions.getRegisterAsReal(REGISTER_X, &rx)) {
        frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "DataType {d}", .{@as(u32, getRegisterDataType(REGISTER_X))});
            c_moreInfoOnError("In function fnStoreVElement:", errorMessage, "is not a Real/Integer/Complex.", "");
        }
        return;
    }
    // C int promotion: (ix-1)/cols is signed int arithmetic.
    frontier.setIRegisterAsInt(false, @intCast(@divTrunc(@as(i32, ix) - 1, @as(i32, cols)) + 1));
    frontier.setJRegisterAsInt(false, @intCast(@rem(@as(i32, ix) - 1, @as(i32, cols)) + 1));
    matrixIndex = @intCast(REGISTER_Y);
    _fnStoreElement(false);
    frontier.setIRegisterAsInt(false, iBak);
    frontier.setJRegisterAsInt(false, jBak);
    matrixIndex = matrixIndexBak;
}

pub export fn fnStoreVector(regist_arg: u16) callconv(.c) void {
    var regist = regist_arg;
    const matrixIndexBak: u16 = matrixIndex;
    const iBak: i16 = frontier.getIRegisterAsInt(true);
    const jBak: i16 = frontier.getJRegisterAsInt(true);
    var rows: u16 = undefined;
    var cols: u16 = undefined;
    if (!getMatrixDims(REGISTER_X, "In function fnStoreVector:", &rows, &cols)) {
        return;
    }
    copySourceRegisterToDestRegister(getStackTop(), TEMP_REGISTER_1);
    setSystemFlag(FLAG_ASLIFT);
    liftStack();
    matrixIndex = @intCast(REGISTER_Y);
    var ix: u16 = 1;
    while (@as(u32, ix) <= @as(u32, rows) * @as(u32, cols) and lastErrorCode == 0) : (ix +%= 1) { // for 5x5, from 1 to 25
        frontier.setIRegisterAsInt(false, @intCast((ix - 1) / cols + 1));
        frontier.setJRegisterAsInt(false, @intCast((ix - 1) % cols + 1));
        fnDrop(NOPARAM);
        frontier_recall.fnRecall(regist);
        regist +%= 1;
        if (getRegisterDataType(REGISTER_X) != dtComplex34) {
            fnToReal(NOPARAM);
        }
        if (lastErrorCode != 0) {
            return;
        }
        _fnStoreElement(false);
        if (lastErrorCode != 0) {
            return;
        }
    }
    frontier.setIRegisterAsInt(false, iBak);
    frontier.setJRegisterAsInt(false, jBak);
    matrixIndex = matrixIndexBak;
    fnDrop(NOPARAM);
    copySourceRegisterToDestRegister(TEMP_REGISTER_1, getStackTop());
}

pub export fn fnStoreElementPlus(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    _fnStoreElement(true);
}

pub export fn fnStoreElement(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    _fnStoreElement(false);
}

fn _fnStoreElement(stepForward: bool) void {
    if (matrixIndex == INVALID_VARIABLE) {
        frontier_error.displayCalcErrorMessage(ERROR_NO_MATRIX_INDEXED, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "Cannot execute STOEL without a matrix indexed", .{});
            moreInfoOnError("In function _fnStoreElement:", errorMessage, null);
        }
    } else {
        if (regInRange(matrixIndex) and getRegisterDataType(@intCast(matrixIndex)) == dtReal34Matrix and getRegisterDataType(REGISTER_X) == dtComplex34) {
            // Real matrices turns to complex matrices by setting a complex element
            frontier_register_value_conversions.convertReal34MatrixRegisterToComplex34MatrixRegister(@intCast(matrixIndex), @intCast(matrixIndex));
        }
        callByIndexedMatrix(storeElementReal, storeElementComplex);
        if (stepForward) {
            frontier.fnIncDecJ(INC_FLAG);
        }
        var rows: u16 = 1;
        if (matrixIndex >= FIRST_NAMED_VARIABLE and frontier_stats.isStatsMatrixN(&rows, @intCast(matrixIndex)) and @as(calcRegister_t, @intCast(matrixIndex)) == findNamedVariable("STATS")) {
            frontier_stats.calcSigma(0);
        }
    }
}

// ===========================================================================
// fnStoreIJ
// ===========================================================================
pub export fn fnStoreIJ(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (matrixIndex == INVALID_VARIABLE) {
        frontier_error.displayCalcErrorMessage(ERROR_NO_MATRIX_INDEXED, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "Cannot execute STOIJ without a matrix indexed", .{});
            moreInfoOnError("In function fnStoreIJ:", errorMessage, null);
        }
    } else {
        callByIndexedMatrix(storeIjReal, storeIjComplex);
        var rows: u16 = 1;
        if (matrixIndex >= FIRST_NAMED_VARIABLE and frontier_stats.isStatsMatrixN(&rows, @intCast(matrixIndex)) and @as(calcRegister_t, @intCast(matrixIndex)) == findNamedVariable("STATS")) {
            frontier_stats.calcSigma(0);
        }
    }
}

// ===========================================================================
// fn42AlphaStore (42S ASTO) — NEW upstream op (master fd83b4a4). Additive/
// unreached: no items.c dispatch wiring yet. Stores up to 6 bytes of the alpha
// register as a string into `regist`.
// ===========================================================================
const regStringData = abi.registerString;

pub export fn fn42AlphaStore(regist: u16) callconv(.c) void {
    if (regInRange(regist)) {
        if (getRegisterDataType(@intCast(alphaRegister)) == dtString) {
            var source: [*c]u8 = regStringData(@intCast(alphaRegister));
            reallocateRegister(@intCast(regist), dtString, 7, amNone);
            var dest: [*c]u8 = regStringData(@intCast(regist));
            var i: u16 = 0;
            while (i < 6) : (i += 1) {
                if (source[0] != 0) {
                    dest[0] = source[0];
                    dest += 1;
                    source += 1;
                }
            }
            dest[0] = 0;
        } else {
            frontier_error.displayCalcErrorMessage(ERROR_NO_STRING_IN_ALPHA_REGISTER, ERR_REGISTER_LINE, REGISTER_T);
        }
    }
}
