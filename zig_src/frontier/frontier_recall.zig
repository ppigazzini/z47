// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/recall.c: RCL and the recall-arithmetic commands
// (RCL+/-/x// and RCL min/max), LASTx, RCLCFG, RCLS, the indexed-matrix
// element recalls (RCLEL/RCLEL+/RCLIJ) and the vector recall helpers.
// This is a faithful, line-by-line port of the C. The dtConfigDescriptor_t
// layout is replicated byte-exactly from typeDefinitions.h (840 bytes) and
// fnRecallConfig assigns the same named globals in the same order as the C;
// the compatibility_* spare slots are read-and-discarded just as the C reads
// them into unused locals.
//
// recall.c is not reachable from the testSuite; verification is by build/link
// across every target plus the boundary gates.

const std = @import("std");
const frontier_build_options = @import("frontier_build_options");
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const real34_t = abi.Real34;
const complex34_t = abi.Complex34;
const matrixHeader_t = abi.MatrixHeader;
const real34Matrix_t = abi.Real34Matrix;
const complex34Matrix_t = abi.Complex34Matrix;
const calcRegister_t = i16;
const angularMode_t = c_int;

const mp_limb_t = usize;
const mpz_struct = abi.Mpz;
const longInteger_t = [1]mpz_struct;

// registerHeader_t (typeDefinitions.h) as a packed u32.
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

// subroutineLevelHeader_t for the currentNumberOfLocalRegisters macro.
const subroutineLevelHeader_t = abi.SubroutineLevelHeader;

// ---------------------------------------------------------------------------
// Constants / enum values (verified against defines.h / typeDefinitions.h)
// ---------------------------------------------------------------------------
const dtReal34: u32 = 1;
const dtComplex34: u32 = 2;
const dtLongInteger: u32 = 0;
const dtReal34Matrix: u32 = 6;
const dtComplex34Matrix: u32 = 7;
const dtShortInteger: u32 = 8;
const dtString: u32 = 5;
const dtConfig: u32 = 9;

const amNone: u32 = 5;

const ERROR_NONE: u8 = 0;
const ERROR_OUT_OF_RANGE: u8 = 8;
const ERROR_STACK_CLASH: u8 = 12;
const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;
const ERROR_NO_MATRIX_INDEXED: u8 = 38;

const REGISTER_X: calcRegister_t = 100;
const REGISTER_Y: calcRegister_t = 101;
const REGISTER_Z: calcRegister_t = 102;
const REGISTER_T: calcRegister_t = 103;
const REGISTER_D: calcRegister_t = 107;
const REGISTER_L: calcRegister_t = 108;
const REGISTER_I: calcRegister_t = 109;
const REGISTER_J: calcRegister_t = 110;
const REGISTER_W: calcRegister_t = 125;
const SAVED_REGISTER_X: calcRegister_t = 126;
const SAVED_REGISTER_Y: calcRegister_t = 127;
const ERROR_NO_STRING_IN_ALPHA_REGISTER: u8 = 64;
const SAVED_REGISTER_L: calcRegister_t = 134;
const TEMP_REGISTER_1: calcRegister_t = 135;
const FIRST_RESERVED_VARIABLE: u16 = 2000;
const LAST_RESERVED_VARIABLE: u16 = 2047;
const FIRST_LOCAL_REGISTER: u16 = 7000;
const INVALID_VARIABLE: u16 = 2199;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;

const FLAG_ASLIFT: c_uint = 0xc023;
const FLAG_SSIZE8: c_int = 0x8018;

const PGM_RUNNING: u8 = 1;
const NOPARAM: u16 = 9876;
const INC_FLAG: u16 = 0;
const C47_NULL: u16 = 65535;
const DEC_ROUND_DOWN: c_int = 5;
const REAL34_SIZE_IN_BYTES: u32 = 16;
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
extern var currentSubroutineLevelData: ?*subroutineLevelHeader_t;
extern const allReservedVariables: [48]reservedVariableHeader_t;

// Dispatch tables: C arrays of function pointers — declared as Zig arrays.
const Fn0 = ?*const fn () callconv(.c) void;
extern const addition: [NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS]Fn0;
extern const subtraction: [NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS]Fn0;
extern const multiplication: [NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS]Fn0;
extern const division: [NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS]Fn0;

// Config globals mirrored by RCLCFG.
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
extern fn getRegisterDataTypeName(regist: calcRegister_t, article: bool, pad: bool) [*c]const u8;
extern fn displayCalcErrorMessage(error_code: u8, err_message_line: calcRegister_t, err_register_line: calcRegister_t) void;
const c_moreInfoOnError = @extern(*const fn (m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) callconv(.c) void, .{ .name = "moreInfoOnError" });
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;
extern fn regInRange(regist: u16) bool;
extern fn copySourceRegisterToDestRegister(rSource: calcRegister_t, rDest: calcRegister_t) void;
extern fn truncateAlphaRegisterTo44Char() void;
extern fn liftStack() void;
extern fn saveLastX() bool;
extern fn fnRollUp(unusedButMandatoryParameter: u16) void;
extern fn fnSkip(numberOfSteps: u16) void;
extern fn fnDrop(unusedButMandatoryParameter: u16) void;
extern fn fnStore(r: u16) void;
extern fn getSystemFlag(flag: c_int) bool;
extern fn setSystemFlag(flag: c_uint) void;
extern fn adjustResult(result: calcRegister_t, dropY: bool, setCpxRes: bool, op1: calcRegister_t, op2: calcRegister_t, op3: calcRegister_t) void;
extern fn registerMin(regist1: calcRegister_t, regist2: calcRegister_t, dest: calcRegister_t) void;
extern fn registerMax(regist1: calcRegister_t, regist2: calcRegister_t, dest: calcRegister_t) void;
extern fn xcopy(dst: *anyopaque, src: *const anyopaque, n: u32) *anyopaque;
extern fn forceSBupdate() void;
extern fn reallocateRegister(regist: calcRegister_t, data_type: u32, size_blocks: u16, tag: u32) void;
extern fn getIRegisterAsInt(asArrayPointer: bool) i16;
extern fn getJRegisterAsInt(asArrayPointer: bool) i16;
extern fn setIRegisterAsInt(asArrayPointer: bool, toStore: i16) void;
extern fn setJRegisterAsInt(asArrayPointer: bool, toStore: i16) void;
extern fn getMatrixDims(regist: calcRegister_t, funcName: [*:0]const u8, rows: *u16, cols: *u16) bool;
extern fn fnIncDecJ(mode: u16) void;
extern fn callByIndexedMatrix(real_f: ?*const fn (*real34Matrix_t) callconv(.c) bool, complex_f: ?*const fn (*complex34Matrix_t) callconv(.c) bool) void;
extern fn convertLongIntegerToLongIntegerRegister(lgInt: *const mpz_struct, regist: calcRegister_t) void;
extern fn convertReal34ToLongIntegerRegister(real34: *align(1) const real34_t, dest: calcRegister_t, roundingMode: c_int) void;
extern fn @"__gmpz_init"(p: *mpz_struct) void;
extern fn @"__gmpz_clear"(p: *mpz_struct) void;

// ---------------------------------------------------------------------------
// Inline wrappers (the C macros)
// ---------------------------------------------------------------------------
inline fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8) void {
    if (comptime extra_info) c_moreInfoOnError(m1, m2, m3, null);
}
inline fn dataPtr(reg: calcRegister_t) [*]u8 {
    return @ptrCast(getRegisterDataPointer(reg));
}
const reg34 = abi.registerReal34;
const regComplex34 = abi.registerComplex34;
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
inline fn complex34Copy(src: *align(1) const complex34_t, dst: *align(1) complex34_t) void {
    dst.* = src.*;
}

// ===========================================================================
// Indexed-matrix element recall callbacks (static in the C)
// ===========================================================================
fn recallElementReal(matrix: *real34Matrix_t) callconv(.c) bool {
    const i: i16 = getIRegisterAsInt(true);
    const j: i16 = getJRegisterAsInt(true);

    liftStack();
    reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
    const idx: usize = @intCast(@as(i32, i) * @as(i32, @as(u16, matrix.header.matrixColumns)) + @as(i32, j));
    real34Copy(@ptrCast(&matrix.matrixElements.?[idx]), reg34(REGISTER_X));
    return false;
}

fn recallElementComplex(matrix: *complex34Matrix_t) callconv(.c) bool {
    const i: i16 = getIRegisterAsInt(true);
    const j: i16 = getJRegisterAsInt(true);

    liftStack();
    reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
    const idx: usize = @intCast(@as(i32, i) * @as(i32, @as(u16, matrix.header.matrixColumns)) + @as(i32, j));
    complex34Copy(@ptrCast(&matrix.matrixElements.?[idx]), regComplex34(REGISTER_X));
    return false;
}

// ===========================================================================
// fnRecall
// ===========================================================================
pub export fn fnRecall(regist: u16) callconv(.c) void {
    if (regInRange(regist)) {
        if (@as(u16, @intCast(REGISTER_X)) <= regist and regist <= @as(u16, @intCast(getStackTop()))) {
            copySourceRegisterToDestRegister(@intCast(regist), TEMP_REGISTER_1);
            liftStack();
            copySourceRegisterToDestRegister(TEMP_REGISTER_1, REGISTER_X);
        } else {
            if (getSystemFlag(@bitCast(FLAG_ASLIFT))) {
                fnRollUp(NOPARAM);
            }
            copySourceRegisterToDestRegister(@intCast(regist), REGISTER_X);
            if (getRegisterDataType(REGISTER_X) == dtShortInteger) {
                regShortInt(REGISTER_X).* &= shortIntegerMask;
            }
        }
    }
}

pub export fn fn2Rcl(regist: u16) callconv(.c) void {
    if ((regist <= (@as(u16, @intCast(REGISTER_X)) - 1) - 1) or
        (regist >= @as(u16, @intCast(REGISTER_X)) and regist <= @as(u16, @intCast(REGISTER_W)) - 1) or
        (FIRST_LOCAL_REGISTER <= regist and @as(i32, regist) < @as(i32, FIRST_LOCAL_REGISTER) + @as(i32, currentNumberOfLocalRegisters()) - 1))
    {
        setSystemFlag(FLAG_ASLIFT);
        fnRecall(regist + 1);
        setSystemFlag(FLAG_ASLIFT);
        fnRecall(regist + 0);
    } else {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "{d:0>4}", .{@as(u32, @intCast(regist))});
            moreInfoOnError("In function fn2Rcl:", errorMessage, " is not defined!");
        }
    }
}

pub export fn fn3Rcl(regist: u16) callconv(.c) void {
    if ((regist <= (@as(u16, @intCast(REGISTER_X)) - 1) - 2) or
        (regist >= @as(u16, @intCast(REGISTER_X)) and regist <= @as(u16, @intCast(REGISTER_W)) - 2) or
        (FIRST_LOCAL_REGISTER <= regist and @as(i32, regist) < @as(i32, FIRST_LOCAL_REGISTER) + @as(i32, currentNumberOfLocalRegisters()) - 2))
    {
        setSystemFlag(FLAG_ASLIFT);
        fnRecall(regist + 2);
        setSystemFlag(FLAG_ASLIFT);
        fnRecall(regist + 1);
        setSystemFlag(FLAG_ASLIFT);
        fnRecall(regist + 0);
    } else {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "{d:0>4}", .{@as(u32, @intCast(regist))});
            moreInfoOnError("In function fn3Rcl:", errorMessage, " is not defined!");
        }
    }
}

pub export fn fnLastX(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnRecall(@intCast(REGISTER_L));
}

pub export fn fnRecallPlusSkip(regist: u16) callconv(.c) void {
    fnRecall(regist);
    fnSkip(0);
}

// ===========================================================================
// Recall arithmetic
// ===========================================================================
pub export fn fnRecallAdd(regist: u16) callconv(.c) void {
    if (regInRange(regist)) {
        if (programRunStop == PGM_RUNNING and regist == @as(u16, @intCast(REGISTER_L))) {
            copySourceRegisterToDestRegister(REGISTER_L, SAVED_REGISTER_L);
            if (lastErrorCode != ERROR_NONE) {
                return;
            }
        }
        if (!saveLastX()) {
            return;
        }
        if (programRunStop == PGM_RUNNING) {
            copySourceRegisterToDestRegister(REGISTER_Y, SAVED_REGISTER_Y);
        }
        copySourceRegisterToDestRegister(REGISTER_X, REGISTER_Y);
        copySourceRegisterToDestRegister(if (regist == @as(u16, @intCast(REGISTER_Y))) SAVED_REGISTER_Y else if (regist == @as(u16, @intCast(REGISTER_L))) SAVED_REGISTER_L else @as(calcRegister_t, @intCast(regist)), REGISTER_X);
        if (getRegisterDataType(REGISTER_X) == dtShortInteger) {
            regShortInt(REGISTER_X).* &= shortIntegerMask;
        }

        addition[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)].?();

        copySourceRegisterToDestRegister(SAVED_REGISTER_Y, REGISTER_Y);

        adjustResult(REGISTER_X, false, true, REGISTER_X, @intCast(regist), -1);
    }
}

pub export fn fnRecallSub(regist: u16) callconv(.c) void {
    if (regInRange(regist)) {
        if (programRunStop == PGM_RUNNING and regist == @as(u16, @intCast(REGISTER_L))) {
            copySourceRegisterToDestRegister(REGISTER_L, SAVED_REGISTER_L);
            if (lastErrorCode != ERROR_NONE) {
                return;
            }
        }
        if (!saveLastX()) {
            return;
        }
        if (programRunStop == PGM_RUNNING) {
            copySourceRegisterToDestRegister(REGISTER_Y, SAVED_REGISTER_Y);
        }
        copySourceRegisterToDestRegister(REGISTER_X, REGISTER_Y);
        copySourceRegisterToDestRegister(if (regist == @as(u16, @intCast(REGISTER_Y))) SAVED_REGISTER_Y else if (regist == @as(u16, @intCast(REGISTER_L))) SAVED_REGISTER_L else @as(calcRegister_t, @intCast(regist)), REGISTER_X);
        if (getRegisterDataType(REGISTER_X) == dtShortInteger) {
            regShortInt(REGISTER_X).* &= shortIntegerMask;
        }

        subtraction[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)].?();

        copySourceRegisterToDestRegister(SAVED_REGISTER_Y, REGISTER_Y);

        adjustResult(REGISTER_X, false, true, REGISTER_X, @intCast(regist), -1);
    }
}

pub export fn fnRecallMult(regist: u16) callconv(.c) void {
    if (regInRange(regist)) {
        if (programRunStop == PGM_RUNNING and regist == @as(u16, @intCast(REGISTER_L))) {
            copySourceRegisterToDestRegister(REGISTER_L, SAVED_REGISTER_L);
            if (lastErrorCode != ERROR_NONE) {
                return;
            }
        }
        if (!saveLastX()) {
            return;
        }
        if (programRunStop == PGM_RUNNING) {
            copySourceRegisterToDestRegister(REGISTER_Y, SAVED_REGISTER_Y);
        }
        copySourceRegisterToDestRegister(REGISTER_X, REGISTER_Y);
        copySourceRegisterToDestRegister(if (regist == @as(u16, @intCast(REGISTER_Y))) SAVED_REGISTER_Y else if (regist == @as(u16, @intCast(REGISTER_L))) SAVED_REGISTER_L else @as(calcRegister_t, @intCast(regist)), REGISTER_X);
        if (getRegisterDataType(REGISTER_X) == dtShortInteger) {
            regShortInt(REGISTER_X).* &= shortIntegerMask;
        }

        multiplication[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)].?();

        copySourceRegisterToDestRegister(SAVED_REGISTER_Y, REGISTER_Y);

        adjustResult(REGISTER_X, false, true, REGISTER_X, @intCast(regist), -1);
    }
}

pub export fn fnRecallDiv(regist: u16) callconv(.c) void {
    if (regInRange(regist)) {
        if (programRunStop == PGM_RUNNING and regist == @as(u16, @intCast(REGISTER_L))) {
            copySourceRegisterToDestRegister(REGISTER_L, SAVED_REGISTER_L);
            if (lastErrorCode != ERROR_NONE) {
                return;
            }
        }
        if (!saveLastX()) {
            return;
        }
        if (programRunStop == PGM_RUNNING) {
            copySourceRegisterToDestRegister(REGISTER_Y, SAVED_REGISTER_Y);
        }
        copySourceRegisterToDestRegister(REGISTER_X, REGISTER_Y);
        copySourceRegisterToDestRegister(if (regist == @as(u16, @intCast(REGISTER_Y))) SAVED_REGISTER_Y else if (regist == @as(u16, @intCast(REGISTER_L))) SAVED_REGISTER_L else @as(calcRegister_t, @intCast(regist)), REGISTER_X);
        if (getRegisterDataType(REGISTER_X) == dtShortInteger) {
            regShortInt(REGISTER_X).* &= shortIntegerMask;
        }

        division[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)].?();

        copySourceRegisterToDestRegister(SAVED_REGISTER_Y, REGISTER_Y);

        adjustResult(REGISTER_X, false, true, REGISTER_X, @intCast(regist), -1);
    }
}

pub export fn fnRecallMin(regist_arg: u16) callconv(.c) void {
    var regist = regist_arg;
    if (regInRange(regist)) {
        if (programRunStop == PGM_RUNNING and regist == @as(u16, @intCast(REGISTER_L))) {
            copySourceRegisterToDestRegister(REGISTER_L, SAVED_REGISTER_L);
            if (lastErrorCode != ERROR_NONE) {
                return;
            }
        }
        if (!saveLastX()) {
            return;
        }
        if (FIRST_RESERVED_VARIABLE <= regist and regist < LAST_RESERVED_VARIABLE and allReservedVariables[regist - FIRST_RESERVED_VARIABLE].header.bits.pointerToRegisterData == C47_NULL) {
            copySourceRegisterToDestRegister(if (regist == @as(u16, @intCast(REGISTER_L))) SAVED_REGISTER_L else @as(calcRegister_t, @intCast(regist)), TEMP_REGISTER_1);
            regist = @intCast(TEMP_REGISTER_1);
        }
        registerMin(REGISTER_X, @intCast(regist), REGISTER_X);
    }
}

pub export fn fnRecallMax(regist_arg: u16) callconv(.c) void {
    var regist = regist_arg;
    if (regInRange(regist)) {
        if (programRunStop == PGM_RUNNING and regist == @as(u16, @intCast(REGISTER_L))) {
            copySourceRegisterToDestRegister(REGISTER_L, SAVED_REGISTER_L);
            if (lastErrorCode != ERROR_NONE) {
                return;
            }
        }
        if (!saveLastX()) {
            return;
        }
        if (FIRST_RESERVED_VARIABLE <= regist and regist < LAST_RESERVED_VARIABLE and allReservedVariables[regist - FIRST_RESERVED_VARIABLE].header.bits.pointerToRegisterData == C47_NULL) {
            copySourceRegisterToDestRegister(if (regist == @as(u16, @intCast(REGISTER_L))) SAVED_REGISTER_L else @as(calcRegister_t, @intCast(regist)), TEMP_REGISTER_1);
            regist = @intCast(TEMP_REGISTER_1);
        }
        registerMax(REGISTER_X, @intCast(regist), REGISTER_X);
    }
}

// ===========================================================================
// fnRecallConfig
// ===========================================================================
pub export fn fnRecallConfig(regist: u16) callconv(.c) void {
    if (getRegisterDataType(@intCast(regist)) == dtConfig) {
        const configToRecall = regConfig(@intCast(regist));

        shortIntegerMode = configToRecall.shortIntegerMode;
        shortIntegerWordSize = configToRecall.shortIntegerWordSize;
        displayFormat = configToRecall.displayFormat;
        displayFormatDigits = configToRecall.displayFormatDigits;
        gapItemLeft = configToRecall.gapItemLeft;
        gapItemRight = configToRecall.gapItemRight;
        gapItemRadix = configToRecall.gapItemRadix;
        grpGroupingLeft = configToRecall.grpGroupingLeft;
        grpGroupingGr1LeftOverflow = configToRecall.grpGroupingGr1LeftOverflow;
        grpGroupingGr1Left = configToRecall.grpGroupingGr1Left;
        grpGroupingRight = configToRecall.grpGroupingRight;
        currentAngularMode = configToRecall.currentAngularMode;
        lrSelection = configToRecall.lrSelection;
        lrChosen = configToRecall.lrChosen;
        denMax = configToRecall.denMax;
        displayStack = configToRecall.displayStack;
        firstGregorianDay = configToRecall.firstGregorianDay;
        roundingMode = configToRecall.roundingMode;
        systemFlags0 = configToRecall.systemFlags0;
        systemFlags1 = configToRecall.systemFlags1;
        _ = xcopy(@ptrCast(&kbd_usr), @ptrCast(&configToRecall.kbd_usr), @sizeOf(@TypeOf(kbd_usr)));
        // Spare/compatibility slots: the C reads these into unused locals.
        _ = configToRecall.compatibility_byte1;
        _ = configToRecall.compatibility_byte19;
        _ = configToRecall.compatibility_byte28;
        _ = configToRecall.compatibility_byte29;
        _ = configToRecall.compatibility_byte21;
        _ = configToRecall.compatibility_byte30; // fixed!
        _ = configToRecall.compatibility_byte00; // spare
        _ = configToRecall.compatibility_int1; // spare
        Input_Default = configToRecall.Input_Default;
        dispBase = @intFromBool(configToRecall.dispBase);
        _ = configToRecall.compatibility_byte31;
        _ = configToRecall.compatibility_byte26;
        _ = configToRecall.compatibility_float1; // spare
        _ = configToRecall.compatibility_float2; // spare
        Norm_Key_00.func = configToRecall.Norm_Key_00.func;
        _ = xcopy(@ptrCast(&Norm_Key_00.funcParam), @ptrCast(&configToRecall.Norm_Key_00.funcParam), @sizeOf(@TypeOf(Norm_Key_00.funcParam)));
        Norm_Key_00.used = configToRecall.Norm_Key_00.used;
        _ = configToRecall.compatibility_byte2;
        _ = configToRecall.compatibility_byte3;
        _ = configToRecall.compatibility_byte4;
        _ = configToRecall.compatibility_byte5;
        _ = configToRecall.compatibility_byte6;
        _ = configToRecall.compatibility_byte7;
        _ = configToRecall.compatibility_byte8;
        _ = configToRecall.compatibility_byte9;
        _ = configToRecall.compatibility_byte10;
        _ = configToRecall.compatibility_byte11;
        _ = configToRecall.compatibility_byte12;
        _ = configToRecall.compatibility_byte13;
        _ = configToRecall.compatibility_byte14;
        _ = configToRecall.compatibility_byte15;
        fractionDigits = @bitCast(configToRecall.fractionDigits);
        _ = configToRecall.compatibility_byte23;
        _ = configToRecall.compatibility_byte16; // spare
        _ = configToRecall.compatibility_byte20;
        _ = configToRecall.compatibility_byte17;
        IrFractionsCurrentStatus = configToRecall.IrFractionsCurrentStatus;
        _ = configToRecall.compatibility_byte18;
        displayStackSHOIDISP = configToRecall.displayStackSHOIDISP;
        _ = configToRecall.compatibility_byte25;
        _ = configToRecall.compatibility_byte24;
        bcdDisplaySign = configToRecall.bcdDisplaySign;
        DRG_Cycling = configToRecall.DRG_Cycling;
        DM_Cycling = configToRecall.DM_Cycling;
        _ = configToRecall.compatibility_byte22;
        LongPressM = configToRecall.LongPressM;
        LongPressF = configToRecall.LongPressF;
        lastDenominator = configToRecall.lastDenominator;
        significantDigits = configToRecall.significantDigits;
        pcg32_global = configToRecall.pcg32_global;
        exponentLimit = configToRecall.exponentLimit;
        exponentHideLimit = configToRecall.exponentHideLimit;
        lastIntegerBase = configToRecall.lastIntegerBase;
        _ = configToRecall.compatibility_byte27;
        timeDisplayFormatDigits = configToRecall.timeDisplayFormatDigits;
    } else {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "data type {s} cannot be used to recall a configuration!", .{std.mem.span(getRegisterDataTypeName(@intCast(regist), false, false))});
            moreInfoOnError("In function fnRecallConfig:", errorMessage, null);
        }
    }
    forceSBupdate();
}

// ===========================================================================
// fnRecallStack
// ===========================================================================
pub export fn fnRecallStack(regist: u16) callconv(.c) void {
    const size: u16 = if (getSystemFlag(FLAG_SSIZE8)) 8 else 4;

    if (@as(i32, REGISTER_X) - @as(i32, size) <= @as(i32, regist) and @as(i32, regist) < REGISTER_X) {
        displayCalcErrorMessage(ERROR_STACK_CLASH, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "Cannot execute RCLS, destination register would overlap the stack: {d}", .{@as(i32, regist)});
            moreInfoOnError("In function fnRecallStack:", errorMessage, null);
        }
    } else if ((@as(u16, @intCast(REGISTER_X)) <= regist and regist < FIRST_LOCAL_REGISTER) or @as(i32, regist) + @as(i32, size) > @as(i32, FIRST_LOCAL_REGISTER) + @as(i32, currentNumberOfLocalRegisters())) {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "Cannot execute RCLS, destination register is out of range: {d}", .{@as(i32, regist)});
            moreInfoOnError("In function fnRecallStack:", errorMessage, null);
        }
    } else {
        if (!saveLastX()) {
            return;
        }

        var i: i32 = 0;
        while (i < size) : (i += 1) {
            copySourceRegisterToDestRegister(@intCast(@as(i32, regist) + i), @intCast(@as(i32, REGISTER_X) + i));
        }

        i = 0;
        while (i < 4) : (i += 1) {
            adjustResult(@intCast(@as(i32, REGISTER_X) + i), false, true, @intCast(@as(i32, REGISTER_X) + i), -1, -1);
        }
    }
}

// ===========================================================================
// Matrix element recall
// ===========================================================================
pub export fn fnRecallVElement(ix: u16) callconv(.c) void {
    const matrixIndexBak: u16 = matrixIndex;
    const iBak: i16 = getIRegisterAsInt(true);
    const jBak: i16 = getJRegisterAsInt(true);
    var rows: u16 = undefined;
    var cols: u16 = undefined;
    if (getMatrixDims(REGISTER_X, "In function fnRecallVElement:", &rows, &cols)) {
        // C int promotion: (ix-1)/cols is signed int arithmetic.
        setIRegisterAsInt(false, @intCast(@divTrunc(@as(i32, ix) - 1, @as(i32, cols)) + 1));
        setJRegisterAsInt(false, @intCast(@rem(@as(i32, ix) - 1, @as(i32, cols)) + 1));
        matrixIndex = @intCast(REGISTER_X);
        _fnRecallElement(false);
        setIRegisterAsInt(false, iBak);
        setJRegisterAsInt(false, jBak);
        matrixIndex = matrixIndexBak;
    }
}

pub export fn fnRecallVector(regist_arg: u16) callconv(.c) void {
    var regist = regist_arg;
    const matrixIndexBak: u16 = matrixIndex;
    const iBak: i16 = getIRegisterAsInt(true);
    const jBak: i16 = getJRegisterAsInt(true);
    var rows: u16 = undefined;
    var cols: u16 = undefined;
    if (!getMatrixDims(REGISTER_X, "In function fnRecallVector:", &rows, &cols)) {
        return;
    }
    matrixIndex = @intCast(REGISTER_X);
    var ix: u16 = 1;
    while (@as(u32, ix) <= @as(u32, rows) * @as(u32, cols) and lastErrorCode == 0) : (ix +%= 1) { // for 5x5, from 1 to 25
        setIRegisterAsInt(false, @intCast((ix - 1) / cols + 1));
        setJRegisterAsInt(false, @intCast((ix - 1) % cols + 1));
        _fnRecallElement(false);
        if (lastErrorCode != 0) {
            return;
        }
        if (regist > @as(u16, @intCast(REGISTER_X)) and regist < @as(u16, @intCast(getStackTop()))) {
            fnStore(1 +% regist);
            regist +%= 1;
        } else {
            fnStore(regist);
            regist +%= 1;
        }
        if (lastErrorCode != 0) {
            return;
        }
        fnDrop(NOPARAM);
    }
    setIRegisterAsInt(false, iBak);
    setJRegisterAsInt(false, jBak);
    matrixIndex = matrixIndexBak;
}

pub export fn fnRecallElementPlus(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    _fnRecallElement(true);
}

pub export fn fnRecallElement(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    _fnRecallElement(false);
}

fn _fnRecallElement(stepForward: bool) void {
    if (matrixIndex == INVALID_VARIABLE) {
        displayCalcErrorMessage(ERROR_NO_MATRIX_INDEXED, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "Cannot execute RCLEL without a matrix indexed", .{});
            moreInfoOnError("In function fnRecallElement:", errorMessage, null);
        }
    } else {
        callByIndexedMatrix(recallElementReal, recallElementComplex);
        if (stepForward) {
            fnIncDecJ(INC_FLAG);
        }
    }
}

// ===========================================================================
// fnRecallIJ
// ===========================================================================
pub export fn fnRecallIJ(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (matrixIndex == INVALID_VARIABLE) {
        displayCalcErrorMessage(ERROR_NO_MATRIX_INDEXED, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "Cannot execute RCLIJ without a matrix indexed", .{});
            moreInfoOnError("In function fnRecallIJ:", errorMessage, null);
        }
    } else {
        var zero: longInteger_t = undefined;
        @"__gmpz_init"(&zero[0]); // longIntegerInit
        defer @"__gmpz_clear"(&zero[0]); // longIntegerFree — leak fix (master fd83b4a4)

        if (!saveLastX()) {
            return;
        }

        liftStack();
        setSystemFlag(FLAG_ASLIFT);
        liftStack();

        if (matrixIndex == INVALID_VARIABLE or !regInRange(matrixIndex) or !((getRegisterDataType(@intCast(matrixIndex)) == dtReal34Matrix) or (getRegisterDataType(@intCast(matrixIndex)) == dtComplex34Matrix))) {
            convertLongIntegerToLongIntegerRegister(&zero[0], REGISTER_Y);
            convertLongIntegerToLongIntegerRegister(&zero[0], REGISTER_X);
        } else {
            if (getRegisterDataType(REGISTER_I) == dtLongInteger) {
                copySourceRegisterToDestRegister(REGISTER_I, REGISTER_Y);
            } else if (getRegisterDataType(REGISTER_I) == dtReal34) {
                convertReal34ToLongIntegerRegister(reg34(REGISTER_I), REGISTER_Y, DEC_ROUND_DOWN);
            } else {
                convertLongIntegerToLongIntegerRegister(&zero[0], REGISTER_Y);
            }
            if (getRegisterDataType(REGISTER_J) == dtLongInteger) {
                copySourceRegisterToDestRegister(REGISTER_J, REGISTER_X);
            } else if (getRegisterDataType(REGISTER_J) == dtReal34) {
                convertReal34ToLongIntegerRegister(reg34(REGISTER_J), REGISTER_X, DEC_ROUND_DOWN);
            } else {
                convertLongIntegerToLongIntegerRegister(&zero[0], REGISTER_X);
            }
        }

        adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
        adjustResult(REGISTER_Y, false, true, REGISTER_Y, -1, -1);
    }
}

// ===========================================================================
// fn42AlphaRecall (42S ARCL) — NEW upstream op (master fd83b4a4). Additive/
// unreached: no items.c dispatch wiring yet. Appends `regist` to the alpha
// register via the type-dispatched addition[][] table, then restores X/Y.
// ===========================================================================
pub export fn fn42AlphaRecall(regist: u16) callconv(.c) void {
    if (regInRange(regist)) {
        if (getRegisterDataType(@intCast(alphaRegister)) == dtString) {
            if (programRunStop == PGM_RUNNING) {
                copySourceRegisterToDestRegister(REGISTER_Y, SAVED_REGISTER_Y);
                copySourceRegisterToDestRegister(REGISTER_X, SAVED_REGISTER_X);
            }

            copySourceRegisterToDestRegister(@intCast(regist), REGISTER_X);
            copySourceRegisterToDestRegister(@intCast(alphaRegister), REGISTER_Y);

            if (getRegisterDataType(REGISTER_X) == dtShortInteger) {
                regShortInt(REGISTER_X).* &= shortIntegerMask;
            }

            addition[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)].?();

            copySourceRegisterToDestRegister(REGISTER_X, @intCast(alphaRegister));
            truncateAlphaRegisterTo44Char();

            copySourceRegisterToDestRegister(SAVED_REGISTER_Y, REGISTER_Y);
            copySourceRegisterToDestRegister(SAVED_REGISTER_X, REGISTER_X);
        } else {
            displayCalcErrorMessage(ERROR_NO_STRING_IN_ALPHA_REGISTER, ERR_REGISTER_LINE, REGISTER_T);
        }
    }
}
