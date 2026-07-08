// SPDX-License-Identifier: GPL-3.0-only
// Zig owner for src/c47/mathematics/compare.c and incDec.c (M3.2).
//
// Canonical exports kept at the C boundary:
//   - registerCmp / registerMax / registerMin    (compare.c)
//   - incDecLonI / incDecReal / incDecShoI       (incDec.c, used by iteration.c)
// The legacy command entry points fnX*/fnDec/fnInc stay link-dead under their
// upstream names (the live ones are Zig-owned in math_command_wrappers.zig),
// but the wrappers still fall back to the retained copies for non-stack
// registers, so the full compareRegisters/almostEqual/incDec machinery is
// ported here and exported under the z47_math_wrappers_legacy_* names that
// used to be provided by the C dispatch shim.
//
// This file must only be analyzed in product builds (gated in
// math_command_wrappers.zig on !use_fake_wp34s_harness_surface): the parity
// fake runtime defines registerMin/registerMax/realCompare* itself and the
// parity link stubs define the z47_math_wrappers_legacy_* symbols.

const std = @import("std");
const abi = @import("abi");
const comparison_reals = @import("math_comparison_reals.zig");
const math_real_predicates = @import("math_real_predicates.zig");
const runtime = @import("math_command_wrappers_runtime.zig");
const math_integer_division_cells = @import("math_integer_division_cells.zig"); // M-callconv: Zig-to-Zig

const calcRegister_t = runtime.calcRegister_t;

// ---- Register numbering (src/c47/defines.h, enum REG_NUMBERS) ----
const FIRST_GLOBAL_REGISTER: u16 = 0;
const LAST_SPARE_REGISTER: u16 = 125; // REGISTER_W
const TEMP_REGISTER_1: u16 = 135;
const FIRST_NAMED_VARIABLE: u16 = 256;
const FIRST_RESERVED_VARIABLE: u16 = 2000;
const LAST_RESERVED_VARIABLE: u16 = 2047; // RESERVED_VARIABLE_LY
const FIRST_LOCAL_REGISTER: u16 = 7000;

const CMP_EXTENSIVE: i32 = 2;
const TI_TRUE: u8 = runtime.TI_FALSE + 1;

const INC_FLAG: u8 = 0;
const DEC_FLAG: u8 = 1;

const COMPARE_MODE_LESS_THAN: u8 = 0x1;
const COMPARE_MODE_EQUAL: u8 = 0x2;
const COMPARE_MODE_LESS_EQUAL: u8 = 0x3;
const COMPARE_MODE_GREATER_THAN: u8 = 0x4;
const COMPARE_MODE_NOT_EQUAL: u8 = 0x5;
const COMPARE_MODE_GREATER_EQUAL: u8 = 0x6;

// ---- Product externs not covered by the shared runtime ----
extern var numberOfNamedVariables: u16;
extern var errorMessage: [*c]u8;
extern fn badTypeError(reg: calcRegister_t) void;
extern fn compareString(stra: [*c]const u8, strb: [*c]const u8, comparison_type: i32) i32;
extern fn getRegisterAsAnyRealQuiet(reg: calcRegister_t, val: *runtime.real_t) bool;
extern fn getRegisterAsComplexOrAnyReal(reg: calcRegister_t, r: *runtime.real_t, i: *runtime.real_t, cmplx: *bool) bool;
extern fn getRegisterAsRawShortInt(reg: calcRegister_t, val: *u64, base: *u32) bool;
extern fn convertShortIntegerRegisterToReal34Register(source: calcRegister_t, destination: calcRegister_t) void;
extern fn convertComplex34MatrixRegisterToComplex34Matrix(regist: calcRegister_t, matrix: *runtime.complex34Matrix_t) void;
extern fn fnSwapX(regist: u16) void;
extern fn decQuadZero(result: *runtime.real34_t) *runtime.real34_t;
// Upstream macro currentNumberOfLocalRegisters expands to
// currentSubroutineLevelData->numberOfLocalRegisters (defines.h:2281); the
// struct layout matches zig_src/state/register_metadata_local_registers.zig.
const subroutine_level_header_t = abi.SubroutineLevelHeader;
extern var currentSubroutineLevelData: ?*subroutine_level_header_t;

fn localRegisterCount() u16 {
    const level = currentSubroutineLevelData orelse return 0;
    return level.numberOfLocalRegisters;
}

// Upstream macro TO_BYTES(CONFIG_SIZE_IN_BLOCKS) over
// sizeof(dtConfigDescriptor_t) == 840 bytes (the layout is replicated with a
// comptime size check in zig_src/frontier/frontier_store.zig).
const config_size_bytes: u32 = 840;

fn asRegister(regist: u16) calcRegister_t {
    return @bitCast(regist);
}

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) [:0]const u8 {
    const slice = std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args) catch buffer[0..0];
    buffer[slice.len] = 0;
    return buffer[0..slice.len :0];
}

const registerStringData = abi.registerString;

fn registerConfigData(reg: calcRegister_t) [*]const u8 {
    return abi.registerBytes(reg);
}

inline fn realCompare(
    operand1: *const runtime.real_t,
    operand2: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    _ = runtime.decNumberCompare(res, operand1, operand2, real_context);
}

const realIsPositive = math_real_predicates.realIsPositive;

// ============================================================================
// compare.c
// ============================================================================

fn compareTypeError(regist: calcRegister_t) void {
    runtime.temporaryInformation = runtime.TI_FALSE;
    badTypeError(regist);
}

pub export fn registerCmp(regist1: calcRegister_t, regist2: calcRegister_t, res: *i8) callconv(.c) bool {
    const type1 = runtime.getRegisterDataType(regist1);
    const type2 = runtime.getRegisterDataType(regist2);

    if (type1 == runtime.dtString and type2 == runtime.dtString) {
        res.* = @truncate(compareString(registerStringData(regist1), registerStringData(regist2), CMP_EXTENSIVE));
    } else if ((type1 == runtime.dtShortInteger or type1 == runtime.dtLongInteger) and
        (type2 == runtime.dtShortInteger or type2 == runtime.dtLongInteger))
    {
        var int1: runtime.mpz_struct = undefined;
        var int2: runtime.mpz_struct = undefined;

        // These should never fail
        if (runtime.getRegisterAsLongIntQuiet(regist1, &int1, null) != @as(c_int, runtime.ERROR_NONE)) {
            runtime.__gmpz_clear(&int1);
            return false;
        }

        if (runtime.getRegisterAsLongIntQuiet(regist2, &int2, null) != 0) {
            runtime.__gmpz_clear(&int2);
            runtime.__gmpz_clear(&int1);
            return false;
        }

        res.* = @truncate(@as(i32, runtime.__gmpz_cmp(&int1, &int2)));
        runtime.__gmpz_clear(&int1);
        runtime.__gmpz_clear(&int2);
    } else {
        var rcmp: runtime.real_t = undefined;
        var real1: runtime.real_t = undefined;
        var real2: runtime.real_t = undefined;

        if (!getRegisterAsAnyRealQuiet(regist1, &real1) or !getRegisterAsAnyRealQuiet(regist2, &real2)) {
            return false;
        }
        // Time stored in seconds; normalize to hours to compare against a plain
        // number similar to =? / <? / >? (see compareRegisters also).
        if (runtime.getRegisterDataType(regist1) == runtime.dtTime) {
            runtime.realDivide(&real1, runtime.z47_math_wrappers_const_3600(), &real1, &runtime.ctxtReal39);
        }
        if (runtime.getRegisterDataType(regist2) == runtime.dtTime) {
            runtime.realDivide(&real2, runtime.z47_math_wrappers_const_3600(), &real2, &runtime.ctxtReal39);
        }
        realCompare(&real1, &real2, &rcmp, &runtime.ctxtReal39);
        res.* = if (runtime.realIsZero(&rcmp)) 0 else if (realIsPositive(&rcmp)) 1 else -1;
    }
    return true;
}

fn registerMinMax(regist1: calcRegister_t, regist2: calcRegister_t, dest: calcRegister_t, maximum: c_int) void {
    var cmp: i8 = undefined;
    var r_min = regist1;
    var r_max = regist2;

    if (registerCmp(r_min, r_max, &cmp)) {
        if (cmp == 0 and (dest == regist1 or dest == regist2)) {
            return;
        }
        if (cmp > 0) {
            r_min = regist2;
            r_max = regist1;
        }
        const where = if (maximum != 0) r_max else r_min;
        if (where != dest) {
            runtime.copySourceRegisterToDestRegister(where, dest);
        }
    } else {
        badTypeError(regist1);
    }
}

pub export fn registerMax(regist1: calcRegister_t, regist2: calcRegister_t, dest: calcRegister_t) callconv(.c) void {
    registerMinMax(regist1, regist2, dest, 1);
}

pub export fn registerMin(regist1: calcRegister_t, regist2: calcRegister_t, dest: calcRegister_t) callconv(.c) void {
    registerMinMax(regist1, regist2, dest, 0);
}

// Encodes two 8-bit type IDs into one 16-bit key (low byte = REGISTER_X type).
fn typePair(lo: u32, hi: u32) u16 {
    return @as(u16, @as(u8, @truncate(lo))) | (@as(u16, @as(u8, @truncate(hi))) << 8);
}

fn cmpSign(v: i32) i32 {
    return @as(i32, @intFromBool(v > 0)) - @as(i32, @intFromBool(v < 0));
}

fn modeIsEquality(mode: u8) bool {
    return mode == COMPARE_MODE_EQUAL or mode == COMPARE_MODE_NOT_EQUAL;
}

fn isLocalRegister(r: u16) bool {
    const first = FIRST_LOCAL_REGISTER;
    const end_exclusive = FIRST_LOCAL_REGISTER +% localRegisterCount();
    return r >= first and r < end_exclusive;
}

fn isNamedVariable(r: u16) bool {
    if (numberOfNamedVariables == 0) {
        return false;
    }
    const lo = FIRST_NAMED_VARIABLE;
    const hi = FIRST_NAMED_VARIABLE +% numberOfNamedVariables -% 1;
    return r >= lo and r <= hi;
}

fn isReservedVariable(r: u16) bool {
    return r >= FIRST_RESERVED_VARIABLE and r <= LAST_RESERVED_VARIABLE;
}

fn isGlobalRegister(r: u16) bool {
    return r >= FIRST_GLOBAL_REGISTER and r <= LAST_SPARE_REGISTER;
}

fn isComparableRegister(r: u16) bool {
    return isLocalRegister(r) or
        isGlobalRegister(r) or
        isNamedVariable(r) or
        isReservedVariable(r) or
        (r == TEMP_REGISTER_1);
}

fn cmpToResult(result: i32, mode: u8) void {
    if (result < 0) {
        runtime.setTemporaryInformation((mode & COMPARE_MODE_LESS_THAN) != 0);
    } else if (result > 0) {
        runtime.setTemporaryInformation((mode & COMPARE_MODE_GREATER_THAN) != 0);
    } else {
        runtime.setTemporaryInformation((mode & COMPARE_MODE_EQUAL) != 0);
    }
}

fn compareRealsToTemporaryInformation(a: *runtime.real_t, b: *runtime.real_t, mode: u8) void {
    // Real ordering/equality is invalid if any operand is NaN
    if (runtime.realIsNaN(a) or runtime.realIsNaN(b)) {
        runtime.temporaryInformation = runtime.TI_FALSE;
        return;
    }

    var diff: runtime.real_t = undefined;
    realCompare(a, b, &diff, &runtime.ctxtReal39);

    const cmp: i32 = if (runtime.realIsZero(&diff)) 0 else if (runtime.realIsNegative(&diff)) -1 else 1;
    cmpToResult(cmp, mode);
}

fn compareComplexToTemporaryInformation(
    a_real: *runtime.real_t,
    a_imag: *runtime.real_t,
    b_real: *runtime.real_t,
    b_imag: *runtime.real_t,
    mode: u8,
    regist_for_error: u16,
) void {
    // Complex numbers do not have a total ordering; only == and != are supported
    if (!modeIsEquality(mode)) {
        compareTypeError(asRegister(regist_for_error));
        return;
    }
    compareRealsToTemporaryInformation(a_real, b_real, mode);
    if (runtime.temporaryInformation != runtime.TI_FALSE) {
        compareRealsToTemporaryInformation(a_imag, b_imag, mode);
    }
}

fn compareMatrix01(regist: u16, mode: u8, type_x: u32) void {
    var m_cplx: runtime.complex34Matrix_t = undefined;
    var m_real: runtime.real34Matrix_t = undefined;
    var actual_mode: u8 = COMPARE_MODE_NOT_EQUAL;
    var zero34: runtime.real34_t = undefined;
    const r: *const runtime.real34_t = @ptrCast(runtime.registerReal34Ptr(asRegister(regist)));

    _ = decQuadZero(&zero34);

    // Check for zero and identity matrices
    different: {
        if (type_x == runtime.dtReal34Matrix) {
            runtime.linkToRealMatrixRegister(runtime.REGISTER_X, &m_real);
            const elements: [*]runtime.real34_t = m_real.matrixElements;
            const rows: i32 = m_real.header.matrixRows;
            const columns: i32 = m_real.header.matrixColumns;
            var k: usize = 0;
            var i: i32 = 0;
            while (i < rows) : (i += 1) {
                var j: i32 = 0;
                while (j < columns) : ({
                    j += 1;
                    k += 1;
                }) {
                    if (!comparison_reals.real34CompareEqual(&elements[k], if (i == j) r else &zero34)) {
                        break :different;
                    }
                }
            }
        } else {
            runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &m_cplx);
            const elements: [*]runtime.complex34_t = m_cplx.matrixElements;
            const rows: i32 = m_cplx.header.matrixRows;
            const columns: i32 = m_cplx.header.matrixColumns;
            var k: usize = 0;
            var i: i32 = 0;
            while (i < rows) : (i += 1) {
                var j: i32 = 0;
                while (j < columns) : ({
                    j += 1;
                    k += 1;
                }) {
                    if (!comparison_reals.real34CompareEqual(&elements[k].real, if (i == j) r else &zero34) or
                        !runtime.real34IsZero(&elements[k].imag))
                    {
                        break :different;
                    }
                }
            }
        }
        actual_mode = COMPARE_MODE_EQUAL;
    }

    runtime.setTemporaryInformation(mode == actual_mode);
}

// In matrices, we consider NaNs to be equal which is counter to normal
fn matrixCompareRealEqual(a: *const runtime.real34_t, b: *const runtime.real34_t) bool {
    return comparison_reals.real34CompareEqual(a, b) or (runtime.real34IsNaN(a) and runtime.real34IsNaN(b));
}

fn compareMatrices(regist: u16, mode: u8, type_x: u32, type_r: u32) void {
    var x: runtime.complex34Matrix_t = undefined;
    var r: runtime.complex34Matrix_t = undefined;

    if (type_x == runtime.dtComplex34Matrix) {
        runtime.linkToComplexMatrixRegister(runtime.REGISTER_X, &x);
    } else {
        runtime.convertReal34MatrixRegisterToComplex34Matrix(runtime.REGISTER_X, &x);
    }
    if (type_r == runtime.dtComplex34Matrix) {
        runtime.linkToComplexMatrixRegister(asRegister(regist), &r);
    } else {
        runtime.convertReal34MatrixRegisterToComplex34Matrix(asRegister(regist), &r);
    }
    if (runtime.lastErrorCode != 0) { // a convert ran out of RAM; free what was allocated and return
        if (type_x == runtime.dtReal34Matrix) {
            runtime.complexMatrixFree(&x);
        }
        if (type_r == runtime.dtReal34Matrix) {
            runtime.complexMatrixFree(&r);
        }
        return;
    }
    if (x.header.matrixRows == r.header.matrixRows and x.header.matrixColumns == r.header.matrixColumns) {
        runtime.temporaryInformation = TI_TRUE;
        const x_elements: [*]runtime.complex34_t = x.matrixElements;
        const r_elements: [*]runtime.complex34_t = r.matrixElements;
        const element_count: i32 = @as(i32, x.header.matrixRows) * @as(i32, x.header.matrixColumns);
        var i: i32 = 0;
        while (i < element_count) : (i += 1) {
            const index: usize = @intCast(i);
            if (!matrixCompareRealEqual(&x_elements[index].real, &r_elements[index].real) or
                !matrixCompareRealEqual(&x_elements[index].imag, &r_elements[index].imag))
            {
                runtime.temporaryInformation = runtime.TI_FALSE;
                break;
            }
        }
    } else {
        runtime.temporaryInformation = runtime.TI_FALSE;
    }
    if (mode == COMPARE_MODE_NOT_EQUAL) {
        if (runtime.temporaryInformation == TI_TRUE) {
            runtime.temporaryInformation = runtime.TI_FALSE;
        } else {
            runtime.temporaryInformation = TI_TRUE;
        }
    }
    if (type_x == runtime.dtReal34Matrix) {
        runtime.complexMatrixFree(&x);
    }
    if (type_r == runtime.dtReal34Matrix) {
        runtime.complexMatrixFree(&r);
    }
}

fn compareRegisters(regist: u16, mode: u8) void {
    // Precondition: only proceed for valid/comparable registers regardless types
    if (!isComparableRegister(regist)) {
        return;
    }
    const x_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    const r_type = runtime.getRegisterDataType(asRegister(regist));
    const type_pair = typePair(x_type, r_type);

    var x_real: runtime.real_t = undefined;
    var x_imag: runtime.real_t = undefined;
    var r_real: runtime.real_t = undefined;
    var r_imag: runtime.real_t = undefined;

    switch (type_pair) {
        // String vs String
        typePair(runtime.dtString, runtime.dtString) => {
            const c = compareString(registerStringData(runtime.REGISTER_X), registerStringData(asRegister(regist)), CMP_EXTENSIVE);
            cmpToResult(c, mode);
        },

        // Config vs Config (equality only)
        typePair(runtime.dtConfig, runtime.dtConfig) => {
            if (!modeIsEquality(mode)) {
                compareTypeError(asRegister(regist));
                return;
            }
            const length = config_size_bytes;
            const order = std.mem.order(u8, registerConfigData(runtime.REGISTER_X)[0..length], registerConfigData(asRegister(regist))[0..length]);
            const c: i32 = switch (order) {
                .lt => -1,
                .eq => 0,
                .gt => 1,
            };
            cmpToResult(cmpSign(c), mode);
        },

        // Matrix vs Matrix (equality only)
        typePair(runtime.dtReal34Matrix, runtime.dtReal34Matrix),
        typePair(runtime.dtComplex34Matrix, runtime.dtComplex34Matrix),
        typePair(runtime.dtReal34Matrix, runtime.dtComplex34Matrix),
        typePair(runtime.dtComplex34Matrix, runtime.dtReal34Matrix),
        => {
            if (!modeIsEquality(mode)) {
                compareTypeError(asRegister(regist));
                return;
            }

            if (regist == TEMP_REGISTER_1 and x_type == r_type) {
                compareMatrix01(regist, mode, x_type);
            } else {
                compareMatrices(regist, mode, x_type, r_type);
            }
        },

        // Integer pairs (short/long mix)
        typePair(runtime.dtShortInteger, runtime.dtShortInteger),
        typePair(runtime.dtLongInteger, runtime.dtLongInteger),
        typePair(runtime.dtShortInteger, runtime.dtLongInteger),
        typePair(runtime.dtLongInteger, runtime.dtShortInteger),
        => {
            var x_int: runtime.mpz_struct = undefined;
            var r_int: runtime.mpz_struct = undefined;

            if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x_int, null)) {
                runtime.__gmpz_clear(&x_int);
                compareTypeError(runtime.REGISTER_X);
                return;
            }

            if (!runtime.getRegisterAsLongInt(asRegister(regist), &r_int, null)) {
                compareTypeError(asRegister(regist));
                runtime.__gmpz_clear(&r_int);
                runtime.__gmpz_clear(&x_int);
                compareTypeError(runtime.REGISTER_X);
                return;
            }

            cmpToResult(@as(i32, runtime.__gmpz_cmp(&x_int, &r_int)), mode);
            runtime.__gmpz_clear(&r_int);
            runtime.__gmpz_clear(&x_int);
        },

        // (complex, real, shortI, longI) x (complex, real, shortI, longI)
        // with at least one complex/real operand
        typePair(runtime.dtComplex34, runtime.dtComplex34),
        typePair(runtime.dtComplex34, runtime.dtReal34),
        typePair(runtime.dtComplex34, runtime.dtShortInteger),
        typePair(runtime.dtComplex34, runtime.dtLongInteger),
        typePair(runtime.dtReal34, runtime.dtComplex34),
        typePair(runtime.dtReal34, runtime.dtReal34),
        typePair(runtime.dtReal34, runtime.dtShortInteger),
        typePair(runtime.dtReal34, runtime.dtLongInteger),
        typePair(runtime.dtShortInteger, runtime.dtComplex34),
        typePair(runtime.dtShortInteger, runtime.dtReal34),
        typePair(runtime.dtLongInteger, runtime.dtComplex34),
        typePair(runtime.dtLongInteger, runtime.dtReal34),
        => {
            var is_complex = false;

            if (!getRegisterAsComplexOrAnyReal(runtime.REGISTER_X, &x_real, &x_imag, &is_complex)) {
                compareTypeError(runtime.REGISTER_X);
                return;
            }
            if (!getRegisterAsComplexOrAnyReal(asRegister(regist), &r_real, &r_imag, &is_complex)) {
                compareTypeError(asRegister(regist));
                return;
            }

            if (is_complex) {
                compareComplexToTemporaryInformation(&x_real, &x_imag, &r_real, &r_imag, mode, regist);
            } else {
                compareRealsToTemporaryInformation(&x_real, &r_real, mode);
            }
        },

        // (time, real, shoI, longI) x (time, real, shoI, longI)
        // short & long integers will be casted as real, see above
        typePair(runtime.dtReal34, runtime.dtTime),
        typePair(runtime.dtTime, runtime.dtReal34),
        typePair(runtime.dtLongInteger, runtime.dtTime),
        typePair(runtime.dtShortInteger, runtime.dtTime),
        typePair(runtime.dtTime, runtime.dtLongInteger),
        typePair(runtime.dtTime, runtime.dtShortInteger),
        typePair(runtime.dtTime, runtime.dtTime),
        => {
            var cannot_be_complex = false;
            if (!getRegisterAsComplexOrAnyReal(runtime.REGISTER_X, &x_real, &x_imag, &cannot_be_complex)) {
                compareTypeError(runtime.REGISTER_X);
                return;
            }
            if (!getRegisterAsComplexOrAnyReal(asRegister(regist), &r_real, &r_imag, &cannot_be_complex)) {
                compareTypeError(asRegister(regist));
                return;
            }

            if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtTime) {
                runtime.realDivide(&x_real, runtime.z47_math_wrappers_const_3600(), &x_real, &runtime.ctxtReal39);
            }
            if (runtime.getRegisterDataType(asRegister(regist)) == runtime.dtTime) {
                runtime.realDivide(&r_real, runtime.z47_math_wrappers_const_3600(), &r_real, &runtime.ctxtReal39);
            }

            compareRealsToTemporaryInformation(&x_real, &r_real, mode);
        },

        // Unsupported combinations
        else => {
            compareTypeError(asRegister(regist));
            var message_buffer: [64]u8 = undefined;
            const message = bufPrintZ(&message_buffer, "local register .{d:0>2}", .{@as(i32, regist) - FIRST_LOCAL_REGISTER});
            runtime.moreInfoOnError("In function compareRegisters:", message, "is not defined!", null);
        },
    }
}

pub export fn z47_math_wrappers_legacy_fnXLessThan(regist: u16) callconv(.c) void {
    compareRegisters(regist, COMPARE_MODE_LESS_THAN);
}

pub export fn z47_math_wrappers_legacy_fnXLessEqual(regist: u16) callconv(.c) void {
    compareRegisters(regist, COMPARE_MODE_LESS_EQUAL);
}

pub export fn z47_math_wrappers_legacy_fnXGreaterThan(regist: u16) callconv(.c) void {
    compareRegisters(regist, COMPARE_MODE_GREATER_THAN);
}

pub export fn z47_math_wrappers_legacy_fnXGreaterEqual(regist: u16) callconv(.c) void {
    compareRegisters(regist, COMPARE_MODE_GREATER_EQUAL);
}

pub export fn z47_math_wrappers_legacy_fnXEqualsTo(regist: u16) callconv(.c) void {
    compareRegisters(regist, COMPARE_MODE_EQUAL);
}

pub export fn z47_math_wrappers_legacy_fnXNotEqual(regist: u16) callconv(.c) void {
    compareRegisters(regist, COMPARE_MODE_NOT_EQUAL);
}

fn almostEqualMatrix(regist: u16) void {
    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34Matrix and
        runtime.getRegisterDataType(asRegister(regist)) == runtime.dtReal34Matrix)
    {
        var x: runtime.real34Matrix_t = undefined;
        var r: runtime.real34Matrix_t = undefined;
        runtime.convertReal34MatrixRegisterToReal34Matrix(runtime.REGISTER_X, &x);
        runtime.convertReal34MatrixRegisterToReal34Matrix(asRegister(regist), &r);
        if (runtime.lastErrorCode != 0) { // a convert ran out of RAM; free locals and return before rounding
            runtime.realMatrixFree(&x);
            runtime.realMatrixFree(&r);
            return;
        }
        math_integer_division_cells.roundRema();
        fnSwapX(regist);
        math_integer_division_cells.roundRema();
        fnSwapX(regist);
        compareRegisters(regist, COMPARE_MODE_EQUAL);
        runtime.convertReal34MatrixToReal34MatrixRegister(&r, asRegister(regist));
        runtime.convertReal34MatrixToReal34MatrixRegister(&x, runtime.REGISTER_X);
        runtime.realMatrixFree(&r);
        runtime.realMatrixFree(&x);
    } else {
        const x_is_cxma = runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtComplex34Matrix;
        const r_is_cxma = runtime.getRegisterDataType(asRegister(regist)) == runtime.dtComplex34Matrix;
        var x: runtime.complex34Matrix_t = undefined;
        var r: runtime.complex34Matrix_t = undefined;
        var m: runtime.real34Matrix_t = undefined;

        if (x_is_cxma) {
            convertComplex34MatrixRegisterToComplex34Matrix(runtime.REGISTER_X, &x);
        } else {
            runtime.convertReal34MatrixRegisterToComplex34Matrix(runtime.REGISTER_X, &x);
            runtime.convertReal34MatrixRegisterToReal34Matrix(runtime.REGISTER_X, &m);
        }
        if (r_is_cxma) {
            convertComplex34MatrixRegisterToComplex34Matrix(asRegister(regist), &r);
        } else {
            runtime.convertReal34MatrixRegisterToComplex34Matrix(asRegister(regist), &r);
            runtime.convertReal34MatrixRegisterToReal34Matrix(asRegister(regist), &m);
        }
        if (runtime.lastErrorCode != 0) { // a convert ran out of RAM; free locals and return before rounding
            runtime.complexMatrixFree(&x);
            runtime.complexMatrixFree(&r);
            if (!x_is_cxma or !r_is_cxma) {
                runtime.realMatrixFree(&m);
            }
            return;
        }

        if (x_is_cxma) {
            math_integer_division_cells.roundCxma();
        } else {
            math_integer_division_cells.roundRema();
        }
        fnSwapX(regist);
        if (r_is_cxma) {
            math_integer_division_cells.roundCxma();
        } else {
            math_integer_division_cells.roundRema();
        }
        fnSwapX(regist);

        compareRegisters(regist, COMPARE_MODE_EQUAL);

        if (r_is_cxma) {
            runtime.convertComplex34MatrixToComplex34MatrixRegister(&r, asRegister(regist));
        } else {
            runtime.convertReal34MatrixToReal34MatrixRegister(&m, asRegister(regist));
        }
        if (x_is_cxma) {
            runtime.convertComplex34MatrixToComplex34MatrixRegister(&x, runtime.REGISTER_X);
        } else {
            runtime.convertReal34MatrixToReal34MatrixRegister(&m, runtime.REGISTER_X);
        }

        runtime.complexMatrixFree(&r);
        runtime.complexMatrixFree(&x);
        if (!x_is_cxma or !r_is_cxma) {
            runtime.realMatrixFree(&m);
        }
    }
}

const Snapshot = struct {
    t: u8,
    r: runtime.real34_t,
    i: runtime.real34_t,
    li: runtime.mpz_struct,
    si_val: u64,
    si_base: u32,
};

// SNAPVAL: the long/short integer cases read REGISTER_X regardless of reg,
// faithfully mirroring the upstream macro.
fn snapValue(reg: calcRegister_t, s: *Snapshot) void {
    s.t = @truncate(runtime.getRegisterDataType(reg));
    switch (@as(u32, s.t)) {
        runtime.dtComplex34 => {
            s.r = @as(*const runtime.real34_t, @ptrCast(runtime.registerReal34Ptr(reg))).*;
            s.i = @as(*const runtime.real34_t, @ptrCast(runtime.registerImag34Ptr(reg))).*;
        },
        runtime.dtReal34 => {
            s.r = @as(*const runtime.real34_t, @ptrCast(runtime.registerReal34Ptr(reg))).*;
            _ = decQuadZero(&s.i);
        },
        runtime.dtLongInteger => {
            _ = runtime.getRegisterAsLongInt(runtime.REGISTER_X, &s.li, null);
        },
        runtime.dtShortInteger => {
            _ = getRegisterAsRawShortInt(runtime.REGISTER_X, &s.si_val, &s.si_base);
        },
        else => {},
    }
}

fn restoreValue(reg: calcRegister_t, s: *Snapshot) void {
    switch (@as(u32, s.t)) {
        runtime.dtComplex34 => {
            @as(*runtime.real34_t, @ptrCast(runtime.registerImag34Ptr(reg))).* = s.i;
            // fall through (upstream: dtComplex34 falls into dtReal34)
            @as(*runtime.real34_t, @ptrCast(runtime.registerReal34Ptr(reg))).* = s.r;
        },
        runtime.dtReal34 => {
            @as(*runtime.real34_t, @ptrCast(runtime.registerReal34Ptr(reg))).* = s.r;
        },
        runtime.dtLongInteger => {
            runtime.convertLongIntegerToLongIntegerRegister(&s.li, reg);
            runtime.__gmpz_clear(&s.li);
        },
        runtime.dtShortInteger => {
            runtime.registerShortIntegerPtr(reg).* = s.si_val;
            runtime.setRegisterTag(reg, s.si_base);
        },
        else => {},
    }
}

fn almostEqualScalar(regist: u16, type_pair: u16) void {
    var snap1: Snapshot = undefined;
    var snap2: Snapshot = undefined;

    // Snapshot real values before rounding
    snapValue(runtime.REGISTER_X, &snap1);
    snapValue(asRegister(regist), &snap2);

    switch (type_pair) {
        typePair(runtime.dtComplex34, runtime.dtComplex34),
        typePair(runtime.dtComplex34, runtime.dtReal34),
        typePair(runtime.dtComplex34, runtime.dtShortInteger),
        typePair(runtime.dtComplex34, runtime.dtLongInteger),
        => math_integer_division_cells.roundCplx(),

        typePair(runtime.dtReal34, runtime.dtComplex34),
        typePair(runtime.dtReal34, runtime.dtReal34),
        typePair(runtime.dtReal34, runtime.dtShortInteger),
        typePair(runtime.dtReal34, runtime.dtLongInteger),
        => math_integer_division_cells.roundReal(),

        // when SI vs Real or Complex, cast to real
        typePair(runtime.dtShortInteger, runtime.dtComplex34),
        typePair(runtime.dtShortInteger, runtime.dtReal34),
        => {
            convertShortIntegerRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
            math_integer_division_cells.roundReal();
        },

        // when LI vs Real or Complex, cast to real
        typePair(runtime.dtLongInteger, runtime.dtComplex34),
        typePair(runtime.dtLongInteger, runtime.dtReal34),
        => {
            runtime.convertLongIntegerRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
            math_integer_division_cells.roundReal();
        },

        // when time vs Real or longinteger
        typePair(runtime.dtTime, runtime.dtReal34) => {
            math_integer_division_cells.roundTime();
            runtime.convertTimeRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
        },

        typePair(runtime.dtShortInteger, runtime.dtTime) => {
            convertShortIntegerRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
            runtime.convertReal34RegisterToTimeRegister(runtime.REGISTER_X, runtime.REGISTER_X);
            math_integer_division_cells.roundTime();
            runtime.convertTimeRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
        },

        typePair(runtime.dtLongInteger, runtime.dtTime),
        typePair(runtime.dtReal34, runtime.dtTime),
        => {
            // (LongInteger, Time) falls through to (Real34, Time) in C
            if (type_pair == typePair(runtime.dtLongInteger, runtime.dtTime)) {
                runtime.convertLongIntegerRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
            }
            runtime.convertReal34RegisterToTimeRegister(runtime.REGISTER_X, runtime.REGISTER_X);
            math_integer_division_cells.roundTime();
            runtime.convertTimeRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
        },

        typePair(runtime.dtTime, runtime.dtShortInteger),
        typePair(runtime.dtTime, runtime.dtLongInteger),
        => {
            math_integer_division_cells.roundTime();
            runtime.convertTimeRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
        },

        typePair(runtime.dtTime, runtime.dtTime) => math_integer_division_cells.roundTime(),

        else => {
            fnSwapX(regist);
            compareTypeError(asRegister(regist));
            return;
        },
    }
    if (regist != TEMP_REGISTER_1) {
        fnSwapX(regist);
        switch (type_pair) {
            typePair(runtime.dtComplex34, runtime.dtComplex34),
            typePair(runtime.dtReal34, runtime.dtComplex34),
            typePair(runtime.dtShortInteger, runtime.dtComplex34),
            typePair(runtime.dtLongInteger, runtime.dtComplex34),
            => math_integer_division_cells.roundCplx(),

            typePair(runtime.dtComplex34, runtime.dtReal34),
            typePair(runtime.dtReal34, runtime.dtReal34),
            typePair(runtime.dtShortInteger, runtime.dtReal34),
            typePair(runtime.dtLongInteger, runtime.dtReal34),
            => math_integer_division_cells.roundReal(),

            // when SI vs Real or Complex, cast to real
            typePair(runtime.dtComplex34, runtime.dtShortInteger),
            typePair(runtime.dtReal34, runtime.dtShortInteger),
            => {
                convertShortIntegerRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
                math_integer_division_cells.roundReal();
            },

            // when LI vs Real or Complex, cast to real
            typePair(runtime.dtComplex34, runtime.dtLongInteger),
            typePair(runtime.dtReal34, runtime.dtLongInteger),
            => {
                runtime.convertLongIntegerRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
                math_integer_division_cells.roundReal();
            },

            typePair(runtime.dtReal34, runtime.dtTime) => {
                math_integer_division_cells.roundTime();
                runtime.convertTimeRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
            },

            typePair(runtime.dtTime, runtime.dtShortInteger) => {
                convertShortIntegerRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
                runtime.convertReal34RegisterToTimeRegister(runtime.REGISTER_X, runtime.REGISTER_X);
                math_integer_division_cells.roundTime();
                runtime.convertTimeRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
            },

            typePair(runtime.dtTime, runtime.dtLongInteger),
            typePair(runtime.dtTime, runtime.dtReal34),
            => {
                // (Time, LongInteger) falls through to (Time, Real34) in C
                if (type_pair == typePair(runtime.dtTime, runtime.dtLongInteger)) {
                    runtime.convertLongIntegerRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
                }
                runtime.convertReal34RegisterToTimeRegister(runtime.REGISTER_X, runtime.REGISTER_X);
                math_integer_division_cells.roundTime();
                runtime.convertTimeRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
            },

            typePair(runtime.dtShortInteger, runtime.dtTime),
            typePair(runtime.dtLongInteger, runtime.dtTime),
            => {
                math_integer_division_cells.roundTime();
                runtime.convertTimeRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
            },

            typePair(runtime.dtTime, runtime.dtTime) => math_integer_division_cells.roundTime(),

            else => {
                fnSwapX(regist);
                compareTypeError(asRegister(regist));
                return;
            },
        }
        fnSwapX(regist);
    }

    compareRegisters(regist, COMPARE_MODE_EQUAL);

    restoreValue(runtime.REGISTER_X, &snap1);
    restoreValue(asRegister(regist), &snap2);
}

pub export fn z47_math_wrappers_legacy_fnXAlmostEqual(regist: u16) callconv(.c) void {
    const x_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    const r_type = runtime.getRegisterDataType(asRegister(regist));
    const type_pair = typePair(x_type, r_type);
    switch (type_pair) {
        typePair(runtime.dtReal34Matrix, runtime.dtReal34Matrix),
        typePair(runtime.dtReal34Matrix, runtime.dtComplex34Matrix),
        typePair(runtime.dtComplex34Matrix, runtime.dtReal34Matrix),
        typePair(runtime.dtComplex34Matrix, runtime.dtComplex34Matrix),
        => almostEqualMatrix(regist),

        typePair(runtime.dtComplex34, runtime.dtComplex34),
        typePair(runtime.dtComplex34, runtime.dtReal34),
        typePair(runtime.dtComplex34, runtime.dtShortInteger),
        typePair(runtime.dtComplex34, runtime.dtLongInteger),
        typePair(runtime.dtReal34, runtime.dtComplex34),
        typePair(runtime.dtReal34, runtime.dtReal34),
        typePair(runtime.dtReal34, runtime.dtShortInteger),
        typePair(runtime.dtReal34, runtime.dtLongInteger),
        typePair(runtime.dtShortInteger, runtime.dtComplex34),
        typePair(runtime.dtShortInteger, runtime.dtReal34),
        typePair(runtime.dtLongInteger, runtime.dtComplex34),
        typePair(runtime.dtLongInteger, runtime.dtReal34),
        typePair(runtime.dtReal34, runtime.dtTime),
        typePair(runtime.dtTime, runtime.dtReal34),
        typePair(runtime.dtLongInteger, runtime.dtTime),
        typePair(runtime.dtTime, runtime.dtLongInteger),
        typePair(runtime.dtShortInteger, runtime.dtTime),
        typePair(runtime.dtTime, runtime.dtShortInteger),
        typePair(runtime.dtTime, runtime.dtTime),
        => almostEqualScalar(regist, type_pair),

        typePair(runtime.dtShortInteger, runtime.dtShortInteger),
        typePair(runtime.dtShortInteger, runtime.dtLongInteger),
        typePair(runtime.dtLongInteger, runtime.dtShortInteger),
        typePair(runtime.dtLongInteger, runtime.dtLongInteger),
        => compareRegisters(regist, COMPARE_MODE_EQUAL), // No need to round

        else => compareTypeError(asRegister(regist)),
    }
}

// ============================================================================
// incDec.c
// ============================================================================

fn incDecError(regist: u16, flag: u8) void {
    _ = flag;
    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, asRegister(regist));

    runtime.moreInfoOnError("In function incDecError:", "Cannot increment/decrement, incompatible type.", null, null);
}

pub export fn incDecLonI(regist: u16, flag: u8) callconv(.c) void {
    var r: runtime.mpz_struct = undefined;

    runtime.convertLongIntegerRegisterToLongInteger(asRegister(regist), &r);

    if (flag == INC_FLAG) {
        runtime.__gmpz_add_ui(&r, &r, 1);
    } else {
        runtime.__gmpz_sub_ui(&r, &r, 1);
    }

    runtime.convertLongIntegerToLongIntegerRegister(&r, asRegister(regist));

    runtime.__gmpz_clear(&r);
}

pub export fn incDecReal(regist: u16, flag: u8) callconv(.c) void {
    var r: runtime.real_t = undefined;

    runtime.real34ToReal(@ptrCast(runtime.registerReal34Ptr(asRegister(regist))), &r);
    if (flag == INC_FLAG) {
        runtime.realAdd(&r, runtime.z47_math_wrappers_const_1(), &r, &runtime.ctxtReal39);
    } else {
        runtime.realSubtract(&r, runtime.z47_math_wrappers_const_1(), &r, &runtime.ctxtReal39);
    }

    runtime.realToReal34(&r, @ptrCast(runtime.registerReal34Ptr(asRegister(regist))));
}

fn incDecCplx(regist: u16, flag: u8) void {
    var r_real: runtime.real_t = undefined;

    runtime.real34ToReal(@ptrCast(runtime.registerReal34Ptr(asRegister(regist))), &r_real);

    if (flag == INC_FLAG) {
        runtime.realAdd(&r_real, runtime.z47_math_wrappers_const_1(), &r_real, &runtime.ctxtReal39);
    } else {
        runtime.realSubtract(&r_real, runtime.z47_math_wrappers_const_1(), &r_real, &runtime.ctxtReal39);
    }

    runtime.realToReal34(&r_real, @ptrCast(runtime.registerReal34Ptr(asRegister(regist))));
}

pub export fn incDecTime(regist: u16, flag: u8) callconv(.c) void {
    var r: runtime.real_t = undefined;

    // "count hours", value in seconds; step by 1 h = 3600 s to match DSZ/ISZ.
    runtime.real34ToReal(@ptrCast(runtime.registerReal34Ptr(asRegister(regist))), &r);

    if (flag == INC_FLAG) {
        runtime.realAdd(&r, runtime.z47_math_wrappers_const_3600(), &r, &runtime.ctxtReal39);
    } else {
        runtime.realSubtract(&r, runtime.z47_math_wrappers_const_3600(), &r, &runtime.ctxtReal39);
    }

    runtime.realToReal34(&r, @ptrCast(runtime.registerReal34Ptr(asRegister(regist))));
}

pub export fn incDecShoI(regist: u16, flag: u8) callconv(.c) void {
    var r_sign: i16 = undefined;
    var r_value: u64 = undefined;

    runtime.convertShortIntegerRegisterToUInt64(asRegister(regist), &r_sign, &r_value);

    if (r_sign != 0) { // register regist negative
        if (flag != INC_FLAG) {
            r_value +%= 1;
        } else {
            r_value -%= 1;
        }
    } else { // register regist positive
        if (flag == INC_FLAG) {
            r_value +%= 1;
        } else {
            r_value -%= 1;
        }
    }

    runtime.convertUInt64ToShortIntegerRegister(r_sign, r_value, runtime.getRegisterTag(asRegister(regist)), asRegister(regist));
}

// Mirrors the incDec dispatch table from upstream incDec.c.
fn incDecDispatch(regist: u16, flag: u8) void {
    switch (runtime.getRegisterDataType(asRegister(regist))) {
        runtime.dtLongInteger => incDecLonI(regist, flag),
        runtime.dtReal34 => incDecReal(regist, flag),
        runtime.dtComplex34 => incDecCplx(regist, flag),
        runtime.dtTime => incDecTime(regist, flag),
        runtime.dtShortInteger => incDecShoI(regist, flag),
        else => incDecError(regist, flag),
    }
}

fn retainedIncDec(regist: u16, flag: u8, comptime function_name: [:0]const u8) void {
    if (@as(u32, regist) < @as(u32, FIRST_LOCAL_REGISTER) + localRegisterCount()) {
        incDecDispatch(regist, flag);
    } else {
        var message_buffer: [64]u8 = undefined;
        const message = bufPrintZ(&message_buffer, "local register .{d:0>2}", .{@as(i32, regist) - FIRST_LOCAL_REGISTER});
        runtime.moreInfoOnError("In function " ++ function_name ++ ":", message, "is not defined!", null);
    }
}

pub export fn z47_math_wrappers_legacy_fnDec(regist: u16) callconv(.c) void {
    retainedIncDec(regist, DEC_FLAG, "fnDec");
}

pub export fn z47_math_wrappers_legacy_fnInc(regist: u16) callconv(.c) void {
    retainedIncDec(regist, INC_FLAG, "fnInc");
}
