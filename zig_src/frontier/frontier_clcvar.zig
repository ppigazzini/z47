// SPDX-License-Identifier: GPL-3.0-only
const consts = abi.constants;
const const34_1 = consts.const34_1;
const const34_0 = consts.const34_0;
//
// Zig owner for src/c47/programming/clcvar.c: the clear-variables machinery.
// fnClCVar walks the current program step by step and zeroes every register /
// named variable referenced by an instruction parameter (_clearVar dispatches
// on the register data type; _processOp decodes the parameter modes,
// including indirect register / indirect variable references).
//
// Faithful, line-by-line port of the C. The sprintf(tmpString, ...) bug-path
// diagnostics have no control-flow effect and are dropped, matching the
// sibling owners. Not reachable from the testSuite; verified by build/link
// on every target plus the boundary gates.

const frontier_build_options = @import("frontier_build_options");
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const calcRegister_t = i16;
const bool_t = u32;
const angularMode_t = c_int;

const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const frontier_char_string = @import("frontier_char_string.zig"); // M-callconv: Zig-to-Zig
const frontier_date_time = @import("frontier_date_time.zig"); // M-callconv: Zig-to-Zig
const frontier_error = @import("frontier_error.zig"); // M-callconv: Zig-to-Zig
const frontier_items = @import("frontier_items.zig"); // M-callconv: Zig-to-Zig
const frontier_next_step = @import("frontier_next_step.zig"); // M-callconv: Zig-to-Zig
const frontier_register_value_conversions = @import("frontier_register_value_conversions.zig"); // M-callconv: Zig-to-Zig
const real34_t = abi.Real34;
const complex34_t = abi.Complex34;
const matrixHeader_t = abi.MatrixHeader;
const real34Matrix_t = abi.Real34Matrix;
const complex34Matrix_t = abi.Complex34Matrix;

// GMP mpz_struct (limb width == pointer width on every z47 target).
const mp_limb_t = usize;
const mpz_struct = abi.Mpz;
extern fn __gmpz_init(p: *mpz_struct) void;
extern fn __gmpz_clear(p: *mpz_struct) void;
const mpz_init = __gmpz_init;
const mpz_clear = __gmpz_clear;

const item_t = abi.Item;

// ---------------------------------------------------------------------------
// Constants / enum values (verified against defines.h / items.h /
// typeDefinitions.h)
// ---------------------------------------------------------------------------
const dtLongInteger: u32 = 0;
const dtReal34: u32 = 1;
const dtComplex34: u32 = 2;
const dtTime: u32 = 3;
const dtDate: u32 = 4;
const dtString: u32 = 5;
const dtReal34Matrix: u32 = 6;
const dtComplex34Matrix: u32 = 7;
const dtShortInteger: u32 = 8;
const dtConfig: u32 = 9;

const amNone: angularMode_t = 5;
const amNoneU: u32 = @bitCast(@as(c_int, amNone));

const REGISTER_X: calcRegister_t = 100;
const REGISTER_Z: calcRegister_t = 102;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;

const ERROR_NON_PROGRAMMABLE_COMMAND: u8 = 50;

const LAST_LOCAL_LABEL: u8 = 123;
const LAST_LOCAL_REGISTER_IN_KS_CODE: u8 = 210;
const LAST_LOCAL_FLAG: u8 = 143;
const FIRST_LOCAL_FLAG: u16 = 112;
const NUMBER_OF_LOCAL_FLAGS: u16 = 32;
const NUMBER_OF_SYSTEM_FLAGS: u16 = 64 + 43; // defines.h:926 (107); was 64+41
const CNST_BEYOND_250: u8 = 250;
const SYSTEM_FLAG_NUMBER: u8 = 250;
const VALUE_0: u8 = 251;
const VALUE_1: u8 = 252;
const STRING_LABEL_VARIABLE: u8 = 253;
const INDIRECT_REGISTER: u8 = 254;
const INDIRECT_VARIABLE: u8 = 255;

const TAM_MAX_MASK: u16 = 0x3fff;

const PARAM_DECLARE_LABEL: u16 = 1;
const PARAM_LABEL: u16 = 2;
const PARAM_REGISTER: u16 = 3;
const PARAM_FLAG: u16 = 4;
const PARAM_NUMBER_8: u16 = 5;
const PARAM_NUMBER_16: u16 = 6;
const PARAM_COMPARE: u16 = 7;
const PARAM_SKIP_BACK: u16 = 9;
const PARAM_NUMBER_8_16: u16 = 10;
const PARAM_SHUFFLE: u16 = 11;
const PARAM_MENU: u16 = 12;

const PTP_STATUS: u16 = 0x1e00;
const PTP_NONE: u16 = 0 << 9;
const PTP_DECLARE_LABEL: u16 = 1 << 9;
const PTP_KEYG_KEYX: u16 = 8 << 9;
const PTP_LITERAL: u16 = 13 << 9;
const PTP_REM: u16 = 14 << 9;
const PTP_DISABLED: u16 = 15 << 9;

const ITM_END: u16 = 1458;

// regKStoC constants (defines.h).
const FIRST_STAT_REGISTER_IN_KS_CODE: i16 = 211;
const LAST_SPARE_REGISTERS_IN_KS_CODE: u8 = 224;
const NUMBER_OF_LOCAL_REGISTERS: i16 = 99;
const FIRST_LOCAL_REGISTER_IN_KS_CODE: i16 = 112;
const LAST_LOCAL_REGISTER_IN_KS_CODE_I: i16 = 210;
const FIRST_LOCAL_REGISTER: i16 = 7000;

const LAST_ITEM: u32 = 2870;

// ---------------------------------------------------------------------------
// Constant blob
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------
extern var tmpString: [*c]u8;
extern var tmpStringLabelOrVariableName: [*c]u8;
extern var firstFreeProgramByte: [*c]u8;
extern var beginOfCurrentProgram: [*c]u8;
extern const indexOfItems: [LAST_ITEM + 1]item_t;

// ---------------------------------------------------------------------------
// Function externs
// ---------------------------------------------------------------------------
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterTag(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) *anyopaque;
extern fn reallocateRegister(regist: calcRegister_t, dataType: u32, dataSizeWithoutDataLenBlocks: u16, tag: u32) void;

extern fn linkToRealMatrixRegister(regist: calcRegister_t, linkedMatrix: *real34Matrix_t) void;
extern fn linkToComplexMatrixRegister(regist: calcRegister_t, linkedMatrix: *complex34Matrix_t) void;
extern fn findOrAllocateNamedVariable(variableName: [*c]const u8) calcRegister_t;

const c_moreInfoOnError = @extern(*const fn (m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) callconv(.c) void, .{ .name = "moreInfoOnError" });

extern fn decQuadZero(r: *align(1) real34_t) *align(1) real34_t;

// ---------------------------------------------------------------------------
// Inline wrappers (the C macros / static inlines)
// ---------------------------------------------------------------------------
inline fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) void {
    if (comptime extra_info) c_moreInfoOnError(m1, m2, m3, m4);
}
inline fn real34SetZero(dst: *align(1) real34_t) void {
    _ = decQuadZero(dst);
}
const reg34 = abi.registerReal34;
const regImag34 = abi.registerImag34;
inline fn regKStoC(regKS: u8) i16 {
    const k: i16 = @intCast(regKS);
    const stat: i16 = if (FIRST_STAT_REGISTER_IN_KS_CODE <= k and regKS <= LAST_SPARE_REGISTERS_IN_KS_CODE) NUMBER_OF_LOCAL_REGISTERS else 0;
    const local: i16 = if (FIRST_LOCAL_REGISTER_IN_KS_CODE <= k and k <= LAST_LOCAL_REGISTER_IN_KS_CODE_I) (FIRST_LOCAL_REGISTER - FIRST_LOCAL_REGISTER_IN_KS_CODE) else 0;
    return k - stat + local;
}

// ===========================================================================
// _clearVar
// ===========================================================================
fn _clearVar(regist: calcRegister_t) void {
    switch (getRegisterDataType(regist)) {
        dtLongInteger => {
            var l: mpz_struct = undefined;
            mpz_init(&l);
            frontier_register_value_conversions.convertLongIntegerToLongIntegerRegister(&l, regist);
            mpz_clear(&l);
        },

        dtReal34, dtTime => {
            real34SetZero(reg34(regist));
        },

        dtComplex34 => {
            real34SetZero(reg34(regist));
            real34SetZero(regImag34(regist));
        },

        dtDate => {
            frontier_date_time.composeJulianDay(const34_0(), const34_1(), const34_1(), reg34(regist));
            frontier_date_time.julianDayToInternalDate(reg34(regist), reg34(regist));
        },

        dtString => {
            reallocateRegister(regist, dtString, 1, amNoneU);
        },

        dtReal34Matrix => {
            var m: real34Matrix_t = undefined;
            linkToRealMatrixRegister(regist, &m);
            var i: u32 = 0;
            const n: u32 = @as(u32, m.header.matrixRows) * m.header.matrixColumns;
            while (i < n) : (i += 1) {
                real34SetZero(&m.matrixElements.?[i]);
            }
        },

        dtComplex34Matrix => {
            var m: complex34Matrix_t = undefined;
            linkToComplexMatrixRegister(regist, &m);
            var i: u32 = 0;
            const n: u32 = @as(u32, m.header.matrixRows) * m.header.matrixColumns;
            while (i < n) : (i += 1) {
                real34SetZero(&m.matrixElements.?[i].real);
                real34SetZero(&m.matrixElements.?[i].imag);
            }
        },

        dtShortInteger => {
            frontier_register_value_conversions.convertUInt64ToShortIntegerRegister(0, 0, getRegisterTag(regist), regist);
        },

        dtConfig => {},

        else => {
            // printf("In function _clearVar, the data type ... is unknown!"):
            // host-only diagnostic, no control-flow effect.
        },
    }
}

// ===========================================================================
// Static helpers
// ===========================================================================
// Upstream shares the bounded decoder in decode.c (getStringLabelOrVariableName);
// this local copy carries the same clamp so a corrupt step's length byte cannot
// read past the program region.
fn _getStringLabelOrVariableName(stringAddress: [*c]u8) void {
    var stringLength: u8 = stringAddress[0];
    const nameStart: [*c]u8 = stringAddress + 1;
    if (@intFromPtr(nameStart) >= @intFromPtr(firstFreeProgramByte)) {
        stringLength = 0;
    } else if (stringLength > @intFromPtr(firstFreeProgramByte) - @intFromPtr(nameStart)) {
        stringLength = @intCast(@intFromPtr(firstFreeProgramByte) - @intFromPtr(nameStart));
    }
    _ = frontier_char_string.xcopy(@ptrCast(tmpStringLabelOrVariableName), @ptrCast(nameStart), stringLength);
    tmpStringLabelOrVariableName[stringLength] = 0;
}

fn _indirectRegister(paramAddress: [*c]u8) void {
    const opParam: u8 = paramAddress[0];
    if (opParam <= LAST_LOCAL_REGISTER_IN_KS_CODE) { // Local register from .00 to .98
        _clearVar(regKStoC(opParam));
    } else {
        // sprintf(tmpString, "...not a valid parameter!"): bug-path, dropped.
    }
}

fn _indirectVariable(stringAddress: [*c]u8) void {
    _getStringLabelOrVariableName(stringAddress);
    const regist: calcRegister_t = findOrAllocateNamedVariable(tmpStringLabelOrVariableName);
    _clearVar(regist);
}

fn _processOp(paramAddress_arg: [*c]u8, op: u16, paramMode: u16) void {
    var paramAddress = paramAddress_arg;
    const opParam: u8 = paramAddress[0];
    paramAddress += 1;

    switch (paramMode) {
        PARAM_DECLARE_LABEL => {
            // nothing to do
        },

        PARAM_LABEL => {
            if (opParam <= LAST_LOCAL_LABEL) { // Local label from 00 to 99 or from A to l
                // nothing to do
            } else if (opParam == STRING_LABEL_VARIABLE) {
                // nothing to do
            } else if (opParam == INDIRECT_REGISTER) {
                _indirectRegister(paramAddress);
            } else if (opParam == INDIRECT_VARIABLE) {
                _indirectVariable(paramAddress);
            } else {
                // sprintf bug-path, dropped.
            }
        },

        PARAM_FLAG => {
            if (opParam <= LAST_LOCAL_FLAG) { // Global flag 00..99, Lettered X..K, or Local .00..31
                // nothing to do
            } else if (FIRST_LOCAL_FLAG + NUMBER_OF_LOCAL_FLAGS <= opParam and opParam < FIRST_LOCAL_FLAG + NUMBER_OF_LOCAL_FLAGS + NUMBER_OF_SYSTEM_FLAGS) { // Local register from .00 to .31
                // nothing to do
            } else if (opParam == SYSTEM_FLAG_NUMBER) {
                // nothing to do
            } else if (opParam == INDIRECT_REGISTER) {
                _indirectRegister(paramAddress);
            } else if (opParam == INDIRECT_VARIABLE) {
                _indirectVariable(paramAddress);
            } else {
                // sprintf bug-path, dropped.
            }
        },

        PARAM_NUMBER_8 => {
            if (opParam <= (indexOfItems[op].tamMinMax & TAM_MAX_MASK)) { // Value from 0 to 99
                // nothing to do
            } else if (opParam == INDIRECT_REGISTER) {
                _indirectRegister(paramAddress);
            } else if (opParam == INDIRECT_VARIABLE) {
                _indirectVariable(paramAddress);
            } else {
                // sprintf bug-path, dropped.
            }
        },

        PARAM_NUMBER_8_16 => {
            if (opParam <= 249) { // Value from 0 to 249
                // nothing to do
            } else if (opParam == CNST_BEYOND_250) { // Value from 250 to 499
                // nothing to do
            } else if (opParam == INDIRECT_REGISTER) {
                _indirectRegister(paramAddress);
            } else if (opParam == INDIRECT_VARIABLE) {
                _indirectVariable(paramAddress);
            } else {
                // sprintf bug-path, dropped.
            }
        },

        PARAM_NUMBER_16 => {
            var func: u16 = (@as(u16, (paramAddress - 3)[0]) << 8) +% @as(u16, (paramAddress - 2)[0]);
            func &= 0x7fff;
            if (frontier_items.isFunctionOldParam16(func) != 0) { // original Param16 functions without indirection support (little endian parameter)
                // nothing to do
            } else { // new Param16 functions with indirection support (big endian parameter)
                const opParam16: u16 = (@as(u16, opParam) << 8) +% @as(u16, paramAddress[0]);
                if (opParam == INDIRECT_REGISTER) {
                    _indirectRegister(paramAddress);
                } else if (opParam == INDIRECT_VARIABLE) {
                    _indirectVariable(paramAddress);
                } else if (opParam16 <= 511) { // Value from 0 to 511
                    // nothing to do
                } else {
                    // sprintf bug-path, dropped.
                }
            }
        },

        PARAM_SKIP_BACK, PARAM_SHUFFLE => {
            // nothing to do
        },

        PARAM_REGISTER, PARAM_COMPARE => {
            if (opParam <= LAST_LOCAL_REGISTER_IN_KS_CODE) { // Global 00..99, Lettered X..K, or Local .00..98
                _clearVar(regKStoC(opParam));
            } else if (opParam == STRING_LABEL_VARIABLE) {
                _getStringLabelOrVariableName(paramAddress);
                _clearVar(findOrAllocateNamedVariable(tmpStringLabelOrVariableName));
            } else if (paramMode == PARAM_COMPARE and (opParam == VALUE_0 or opParam == VALUE_1)) {
                // nothing to do
            } else if (opParam == INDIRECT_REGISTER) {
                _indirectRegister(paramAddress);
            } else if (opParam == INDIRECT_VARIABLE) {
                _indirectVariable(paramAddress);
            } else {
                // sprintf bug-path, dropped.
            }
        },

        PARAM_MENU => {
            if (opParam == STRING_LABEL_VARIABLE) {
                // nothing to do
            } else if (opParam == INDIRECT_REGISTER) {
                _indirectRegister(paramAddress);
            } else if (opParam == INDIRECT_VARIABLE) {
                _indirectVariable(paramAddress);
            } else {
                // sprintf bug-path, dropped.
            }
        },

        else => {
            // sprintf(tmpString, "paramMode %u is not valid!"): bug-path, dropped.
        },
    }
}

fn _processOneStep(step_arg: [*c]u8) bool {
    var step = step_arg;
    var op: u16 = step[0];
    step += 1;
    if (op & 0x80 != 0) {
        op &= 0x7f;
        op <<= 8;
        op |= step[0];
        step += 1;
    }

    if (op == ITM_END or op == 0x7fff) {
        return false;
    } else {
        switch (indexOfItems[op].status & PTP_STATUS) {
            PTP_NONE, PTP_DECLARE_LABEL, PTP_LITERAL, PTP_REM => {
                return true;
            },

            PTP_DISABLED => {
                frontier_error.displayCalcErrorMessage(ERROR_NON_PROGRAMMABLE_COMMAND, ERR_REGISTER_LINE, REGISTER_X);
                moreInfoOnError("In function _processOneStep:", "non-programmable function", @ptrCast(&indexOfItems[op].itemCatalogName), "appeared in the program!");
                return false;
            },

            PTP_KEYG_KEYX => {
                const secondParam: [*c]u8 = frontier_next_step.findKey2ndParam(step - 2);
                _processOp(step, op, PARAM_NUMBER_8);
                if (secondParam != null) { // findKey2ndParam returns NULL on a malformed/.END. step
                    _processOp(secondParam, secondParam[0], PARAM_LABEL);
                }
                return true;
            },

            else => {
                _processOp(step, op, (indexOfItems[op].status & PTP_STATUS) >> 9);
                return true;
            },
        }
    }
}

// ===========================================================================
// fnClCVar
// ===========================================================================
pub export fn fnClCVar(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var ptr: [*c]u8 = beginOfCurrentProgram;

    while (_processOneStep(ptr)) {
        ptr = frontier_next_step.findNextStep(ptr);
    }
}
