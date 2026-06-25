// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/programming/nextStep.c: program-step navigation.
// countOpBytes/countLiteralBytes size one instruction's parameter bytes;
// findNextStep/findKey2ndParam/findPreviousStep walk the program memory;
// fnBst/fnSst implement the BST/SST keys (with the PEM cursor logic);
// fnBack/fnSkip/fnCase move the program counter; defineCurrentStep/
// defineFirstDisplayedStep recompute the step pointers. findNextStep is
// externed by the lblGtoXeq owner and the clcvar owner; the exported names
// stay link-compatible.
//
// Faithful, line-by-line port of the C. The !DMCP_BUILD printf diagnostics
// carry no control flow and are dropped, like the sibling owners. Warm code
// (program editor / executor) — stays in main .text.

const frontier_build_options = @import("frontier_build_options");
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const calcRegister_t = i16;
const bool_t = u32;
const angularMode_t = c_int;

const real34_t = extern struct { bytes: [16]u8 };
const realContext_t = extern struct {
    digits: i32,
    emax: i32,
    emin: i32,
    round: c_int,
    traps: u32,
    status: u32,
    clamp: u8,
};
const font_t = opaque {};

const labelList_t = extern struct {
    program: i16,
    step: i32,
    labelPointer: [*c]u8,
    instructionPointer: [*c]u8,
};
const programList_t = extern struct {
    step: i32,
    instructionPointer: [*c]u8,
};
const item_t = extern struct {
    func: ?*const anyopaque,
    param: u16,
    itemCatalogName: [16]u8,
    itemSoftmenuName: [16]u8,
    tamMinMax: u16,
    status: u16,
};

// ---------------------------------------------------------------------------
// Constants / enum values (verified against defines.h / items.h)
// ---------------------------------------------------------------------------
const LAST_LOCAL_LABEL: u8 = 123;
const LAST_SPARE_REGISTERS_IN_KS_CODE: u8 = 224;
const LAST_LOCAL_FLAG: u8 = 143;
const FLAG_M: u8 = 211;
const FLAG_W: u8 = 224;
const CNST_BEYOND_250: u8 = 250;
const SYSTEM_FLAG_NUMBER: u8 = 250;
const VALUE_0: u8 = 251;
const VALUE_1: u8 = 252;
const STRING_LABEL_VARIABLE: u8 = 253;
const INDIRECT_REGISTER: u8 = 254;
const INDIRECT_VARIABLE: u8 = 255;

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
const PTP_KEYG_KEYX: u16 = 8 << 9;
const PTP_LITERAL: u16 = 13 << 9;
const PTP_REM: u16 = 14 << 9;
const PTP_DISABLED: u16 = 15 << 9;

const BINARY_SHORT_INTEGER: u8 = 1;
const BINARY_REAL34: u8 = 3;
const BINARY_COMPLEX34: u8 = 4;
const STRING_SHORT_INTEGER: u8 = 7;
const STRING_LONG_INTEGER: u8 = 8;
const STRING_REAL34: u8 = 9;
const STRING_COMPLEX34: u8 = 10;
const STRING_TIME: u8 = 11;
const STRING_DATE: u8 = 12;
const STRING_ANGLE_RADIAN: u8 = 18;
const STRING_ANGLE_GRAD: u8 = 19;
const STRING_ANGLE_DEGREE: u8 = 20;
const STRING_ANGLE_DMS: u8 = 21;
const STRING_ANGLE_MULTPI: u8 = 22;

const REAL34_SIZE_IN_BYTES: u32 = 16;
const REAL34_SIZE_IN_BLOCKS: u16 = 4;

const ITM_LBL: u16 = 1;
const ITM_END: u16 = 1458;
const ITM_KEY: u16 = 1497;

const CM_PEM: u8 = 3;
const NP_INT_BASE: u8 = 3;
const SCRUPD_AUTO: u8 = 0x00;
const PGM_SINGLE_STEP: u8 = 6;
const INVALID_VARIABLE: u16 = 2199;
const NOPARAM: u16 = 9876;

const FLAG_ALPHA: c_int = 0x800e;

const REGISTER_X: calcRegister_t = 100;
const REGISTER_Z: calcRegister_t = 102;
const REGISTER_T: calcRegister_t = 103;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;

const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;

const TI_NO_INFO: u8 = 0;

const dtLongInteger: u32 = 0;
const dtReal34: u32 = 1;

const amNone: angularMode_t = 5;
const amAngleMask: u32 = 15;

const DEC_ROUND_DOWN: c_int = 5;

const SCREEN_WIDTH: i16 = 400;
const Y_POSITION_OF_REGISTER_T_LINE: u32 = 24;
const TMP_STR_LENGTH: usize = 2560;
const vmNormal: c_int = 0;

const STD_ELLIPSIS = "\xa0\x26";

const LAST_ITEM: u32 = 2850;

// ---------------------------------------------------------------------------
// Constant blob
// ---------------------------------------------------------------------------
const constants = @extern([*]const u8, .{ .name = "constants" });
const OFF_const34_1 = 16312;
const OFF_const34_65535 = 16792;
inline fn cst34(offset: u32) *align(1) const real34_t {
    return @ptrCast(constants + offset);
}

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------
extern var tmpString: [*c]u8;
extern var errorMessage: [*c]u8;
extern var beginOfProgramMemory: [*c]u8;
extern var numberOfLabels: u16;
extern var labelList: [*c]labelList_t;
extern var programList: [*c]programList_t;
extern const indexOfItems: [LAST_ITEM + 1]item_t;

extern var currentStep: [*c]u8;
extern var currentLocalStepNumber: u16;
extern var currentProgramNumber: u16;
extern var firstDisplayedStep: [*c]u8;
extern var firstDisplayedLocalStepNumber: u16;
extern var pemCursorIsZerothStep: bool;
extern var programListEnd: bool;
extern var currentInputVariable: u16;
extern var calcMode: u8;
extern var aimBuffer: [*c]u8;
extern var nimNumberPart: u8;
extern var screenUpdatingMode: u8;
extern var temporaryInformation: u8;
extern var dynamicMenuItem: i16;
extern var programRunStop: u8;
extern var ctxtReal34: realContext_t;
extern const standardFont: font_t;

// ---------------------------------------------------------------------------
// Function externs
// ---------------------------------------------------------------------------
extern fn isFunctionOldParam16(func: u16) bool;
extern fn checkOpCodeOfStep(step: [*c]const u8, op: u16) bool;
extern fn isAtEndOfPrograms(step: [*c]const u8) bool;
extern fn getNumberOfSteps() u16;
extern fn pemCloseAlphaInput() void;
extern fn pemCloseNumberInput() void;
extern fn scrollPemBackwards() void;
extern fn getSystemFlag(sf: c_int) bool;
extern fn fnDropY(unusedButMandatoryParameter: u16) void;
extern fn fnStore(r: u16) void;
extern fn decodeOneStep(step: [*c]u8) void;
extern fn showString(str: [*c]const u8, font: *const font_t, x: u32, y: u32, video_mode: c_int, show_leading_cols: bool, show_ending_cols: bool) u32;
extern fn stringWidth(str: [*c]const u8, font: *const font_t, with_leading: bool, with_ending: bool) i16;
extern fn refreshRegisterLine(regist: calcRegister_t) void;
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterTag(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) *anyopaque;
extern fn getRegisterDataTypeName(regist: calcRegister_t, article: bool, pad: bool) [*c]const u8;
extern fn convertLongIntegerRegisterToReal34(source: calcRegister_t, destination: *real34_t) void;
extern fn displayCalcErrorMessage(errorCode: u8, errMessageRegisterLine: calcRegister_t, errRegisterLine: calcRegister_t) void;
const c_moreInfoOnError = @extern(*const fn (m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) callconv(.c) void, .{ .name = "moreInfoOnError" });
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;

extern fn decQuadToIntegralValue(r: *real34_t, a: *align(1) const real34_t, ctx: *realContext_t, round: c_int) *real34_t;
extern fn decQuadToUInt32(r: *align(1) const real34_t, ctx: *realContext_t, round: c_int) u32;
extern fn real34CompareLessThan(a: *align(1) const real34_t, b: *align(1) const real34_t) bool;
extern fn real34CompareGreaterEqual(a: *align(1) const real34_t, b: *align(1) const real34_t) bool;

// ---------------------------------------------------------------------------
// Inline wrappers (the C macros)
// ---------------------------------------------------------------------------
inline fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8) void {
    if (comptime extra_info) c_moreInfoOnError(m1, m2, null, null);
}
inline fn isAtEndOfProgram(step: [*c]const u8) bool {
    return checkOpCodeOfStep(step, ITM_END);
}
inline fn reg34(reg: calcRegister_t) *align(1) real34_t {
    return @ptrCast(getRegisterDataPointer(reg));
}
inline fn getRegisterAngularMode(reg: calcRegister_t) angularMode_t {
    return @intCast(getRegisterTag(reg) & amAngleMask);
}
inline fn real34ToIntegralValue(src: *align(1) const real34_t, dst: *real34_t, mode: c_int) void {
    _ = decQuadToIntegralValue(dst, src, &ctxtReal34, mode);
}
inline fn real34ToUInt32(src: *align(1) const real34_t) u32 {
    return decQuadToUInt32(src, &ctxtReal34, DEC_ROUND_DOWN);
}
inline fn toBytes(n: u16) u32 {
    return @as(u32, n) << 2;
}

// ===========================================================================
// countOpBytes
// ===========================================================================
pub export fn countOpBytes(step_arg: [*c]u8, paramMode: u16) callconv(.c) [*c]u8 {
    var step = step_arg;
    const opParam: u8 = step[0];
    step += 1;

    switch (paramMode) {
        PARAM_DECLARE_LABEL => {
            if (opParam <= LAST_LOCAL_LABEL) { // Local labels from 00 to 99 and from A to l
                return step;
            } else if (opParam == STRING_LABEL_VARIABLE) {
                return step + step[0] + 1;
            } else {
                // !DMCP_BUILD printf diagnostic dropped.
                return null;
            }
        },

        PARAM_LABEL => {
            if (opParam <= LAST_LOCAL_LABEL) { // Local labels from 00 to 99 and from A to l
                return step;
            } else if (opParam == STRING_LABEL_VARIABLE or opParam == INDIRECT_VARIABLE) {
                return step + step[0] + 1;
            } else if (opParam == INDIRECT_REGISTER) {
                return step + 1;
            } else {
                return null;
            }
        },

        PARAM_REGISTER => {
            if (opParam <= LAST_SPARE_REGISTERS_IN_KS_CODE) { // Global 00..99, lettered X..W, and local .00..98
                return step;
            } else if (opParam == STRING_LABEL_VARIABLE or opParam == INDIRECT_VARIABLE) {
                return step + step[0] + 1;
            } else if (opParam == INDIRECT_REGISTER) {
                return step + 1;
            } else {
                return null;
            }
        },

        PARAM_FLAG => {
            if (opParam <= LAST_LOCAL_FLAG) { // Global flags 00..99, lettered X..K, and local .00..31
                return step;
            } else if (FLAG_M <= opParam and opParam <= FLAG_W) { // Global flags from M to W
                return step;
            } else if (opParam == INDIRECT_REGISTER or opParam == SYSTEM_FLAG_NUMBER) {
                return step + 1;
            } else if (opParam == INDIRECT_VARIABLE) {
                return step + step[0] + 1;
            } else {
                return null;
            }
        },

        PARAM_NUMBER_8 => {
            if (opParam <= 249) { // Value from 0 to 99
                return step;
            } else if (opParam == INDIRECT_REGISTER) {
                return step + 1;
            } else if (opParam == INDIRECT_VARIABLE) {
                return step + step[0] + 1;
            } else {
                return null;
            }
        },

        PARAM_NUMBER_8_16 => {
            if (opParam <= 249) { // Value from 0 to 249
                return step;
            } else if (opParam == CNST_BEYOND_250) { // Value from 250 to 499
                return step + 1;
            } else if (opParam == INDIRECT_REGISTER) {
                return step + 1;
            } else if (opParam == INDIRECT_VARIABLE) {
                return step + step[0] + 1;
            } else {
                return null;
            }
        },

        PARAM_NUMBER_16 => {
            var func: u16 = (@as(u16, (step - 3)[0]) << 8) +% @as(u16, (step - 2)[0]);
            func &= 0x7fff;
            if (isFunctionOldParam16(func)) { // original Param16 without indirection support (little endian)
                return step + 1;
            } else { // new Param16 with indirection support (big endian)
                if (opParam == INDIRECT_REGISTER) {
                    return step + 1;
                } else if (opParam == INDIRECT_VARIABLE) {
                    return step + step[0] + 1;
                } else {
                    return step + 1;
                }
            }
        },

        PARAM_COMPARE => {
            if (opParam <= LAST_SPARE_REGISTERS_IN_KS_CODE or opParam == VALUE_0 or opParam == VALUE_1) {
                return step;
            } else if (opParam == STRING_LABEL_VARIABLE or opParam == INDIRECT_VARIABLE) {
                return step + step[0] + 1;
            } else if (opParam == INDIRECT_REGISTER) {
                return step + 1;
            } else {
                return null;
            }
        },

        PARAM_SKIP_BACK, PARAM_SHUFFLE => {
            return step;
        },

        PARAM_MENU => {
            if (opParam == STRING_LABEL_VARIABLE or opParam == INDIRECT_VARIABLE) {
                return step + step[0] + 1;
            } else if (opParam == INDIRECT_REGISTER) {
                return step + 1;
            } else {
                return null;
            }
        },

        else => {
            return null;
        },
    }
}

// ===========================================================================
// countLiteralBytes
// ===========================================================================
pub export fn countLiteralBytes(step_arg: [*c]u8) callconv(.c) [*c]u8 {
    var step = step_arg;
    const kind: u8 = step[0];
    step += 1;
    switch (kind) {
        BINARY_SHORT_INTEGER => {
            return step + 9;
        },

        BINARY_REAL34 => {
            return step + REAL34_SIZE_IN_BYTES;
        },

        BINARY_COMPLEX34 => {
            return step + toBytes(REAL34_SIZE_IN_BLOCKS * 2);
        },

        STRING_SHORT_INTEGER => {
            return step + (step + 1)[0] + 2;
        },

        STRING_LONG_INTEGER,
        STRING_REAL34,
        STRING_LABEL_VARIABLE,
        STRING_COMPLEX34,
        STRING_DATE,
        STRING_TIME,
        STRING_ANGLE_DMS,
        STRING_ANGLE_RADIAN,
        STRING_ANGLE_GRAD,
        STRING_ANGLE_DEGREE,
        STRING_ANGLE_MULTPI,
        => {
            return step + step[0] + 1;
        },

        else => {
            // !DMCP_BUILD printf diagnostics dropped.
            return null;
        },
    }
}

// ===========================================================================
// findNextStep
// ===========================================================================
pub export fn findNextStep(step: [*c]u8) callconv(.c) [*c]u8 {
    if (step == null) {
        // !DMCP_BUILD printf diagnostic dropped.
        return null;
    }
    if (checkOpCodeOfStep(step, ITM_KEY)) {
        const afterFirst: [*c]u8 = findKey2ndParam(step);
        if (afterFirst == null) {
            return null;
        }
        return findKey2ndParam(afterFirst);
    } else {
        return findKey2ndParam(step);
    }
}

// ===========================================================================
// findKey2ndParam
// ===========================================================================
pub export fn findKey2ndParam(step_arg: [*c]u8) callconv(.c) [*c]u8 {
    var step = step_arg;
    if (step == null) {
        // !DMCP_BUILD printf diagnostic dropped.
        return null;
    }
    var op: u16 = step[0];
    step += 1;
    if (op & 0x80 != 0) {
        op &= 0x7f;
        op <<= 8;
        op |= step[0];
        step += 1;
    }

    if (op == 0x7fff) { // .END.
        return null;
    } else {
        switch (indexOfItems[op].status & PTP_STATUS) {
            PTP_NONE, PTP_DISABLED => {
                return step;
            },

            PTP_LITERAL, PTP_REM => {
                return countLiteralBytes(step);
            },

            PTP_KEYG_KEYX => {
                return countOpBytes(step, PARAM_NUMBER_8);
            },

            else => {
                return countOpBytes(step, (indexOfItems[op].status & PTP_STATUS) >> 9);
            },
        }
    }
}

// ===========================================================================
// findPreviousStep
// ===========================================================================
pub export fn findPreviousStep(step: [*c]u8) callconv(.c) [*c]u8 {
    var searchFromStep: [*c]u8 = null;

    if (step == beginOfProgramMemory) {
        return step;
    }

    if (numberOfLabels == 0 or @intFromPtr(step) <= @intFromPtr(labelList[0].instructionPointer)) {
        searchFromStep = beginOfProgramMemory;
    } else {
        var label: i16 = @as(i16, @bitCast(numberOfLabels)) - 1;
        while (label >= 0) : (label -= 1) {
            if (@intFromPtr(labelList[@intCast(label)].instructionPointer) < @intFromPtr(step)) {
                searchFromStep = labelList[@intCast(label)].instructionPointer;
                break;
            }
        }
    }

    var nextStep: [*c]u8 = findNextStep(searchFromStep);
    while (nextStep != null and nextStep != step) {
        searchFromStep = nextStep;
        nextStep = findNextStep(searchFromStep);
    }
    // !DMCP_BUILD "passed target without finding it" printf dropped.

    return searchFromStep;
}

// ===========================================================================
// _showStep (static)
// ===========================================================================
fn _showStep() void {
    const tmpStep: [*c]u8 = currentStep;
    const lblOrEnd: bool = checkOpCodeOfStep(tmpStep, ITM_LBL) or isAtEndOfProgram(tmpStep) or isAtEndOfPrograms(tmpStep);
    const xPos: i16 = if (lblOrEnd) 42 else 62;
    var maxWidth: i16 = SCREEN_WIDTH - xPos;

    _ = sprintf(tmpString, "%04u:" ++ "\xa0\x05", @as(c_uint, currentLocalStepNumber));
    _ = showString(tmpString, &standardFont, 1, Y_POSITION_OF_REGISTER_T_LINE + 6, vmNormal, true, true);

    decodeOneStep(tmpStep);
    if (stringWidth(tmpString, &standardFont, true, true) >= maxWidth) {
        var xstr: [*c]u8 = tmpString;
        var xstrOrig: [*c]u8 = tmpString;
        const glyph: [*c]u8 = tmpString + TMP_STR_LENGTH - 4;
        maxWidth -= stringWidth(STD_ELLIPSIS, &standardFont, true, true);
        while (maxWidth > 0) {
            xstrOrig = xstr;
            glyph[0] = xstr[0];
            xstr += 1;
            if (glyph[0] & 0x80 != 0) {
                glyph[1] = xstr[0];
                xstr += 1;
                glyph[2] = 0;
            } else {
                glyph[1] = 0;
            }
            maxWidth -= stringWidth(glyph, &standardFont, true, true);
        }
        xstrOrig[0] = STD_ELLIPSIS[0];
        xstrOrig[1] = STD_ELLIPSIS[1];
        xstrOrig[2] = 0;
    }
    _ = showString(tmpString, &standardFont, @intCast(xPos), Y_POSITION_OF_REGISTER_T_LINE + 6, vmNormal, true, true);
}

// ===========================================================================
// _bstInPem (static) / fnBst
// ===========================================================================
fn _bstInPem() void {
    if (currentLocalStepNumber > 1) {
        if (firstDisplayedLocalStepNumber > 0 and currentLocalStepNumber <= firstDisplayedLocalStepNumber + 3) {
            firstDisplayedLocalStepNumber -= 1;
        }
        currentLocalStepNumber -= 1;
    } else if (currentLocalStepNumber == 1 and !pemCursorIsZerothStep) {
        currentLocalStepNumber = 1;
        firstDisplayedLocalStepNumber = 0;
        pemCursorIsZerothStep = true;
    } else {
        const numberOfSteps: u16 = getNumberOfSteps();
        currentLocalStepNumber = numberOfSteps;
        pemCursorIsZerothStep = false;
        if (numberOfSteps <= 6) {
            firstDisplayedLocalStepNumber = 0;
        } else {
            firstDisplayedLocalStepNumber = numberOfSteps - 6;
        }
    }
    defineFirstDisplayedStep();
}

pub export fn fnBst(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    screenUpdatingMode = SCRUPD_AUTO;
    if (calcMode == CM_PEM) {
        if (aimBuffer[0] != 0) {
            if (getSystemFlag(FLAG_ALPHA)) {
                pemCloseAlphaInput();
            } else if (nimNumberPart == NP_INT_BASE) {
                return;
            } else {
                pemCloseNumberInput();
            }
            aimBuffer[0] = 0;
            currentLocalStepNumber -= 1;
            currentStep = findPreviousStep(currentStep);
            if (!programListEnd) {
                scrollPemBackwards();
            }
        }
    }
    currentInputVariable = INVALID_VARIABLE;
    _bstInPem();
    if (calcMode != CM_PEM) {
        defineCurrentStep();
        _showStep();
    }
}

// ===========================================================================
// _sstInPem (static) / showStep / fnSst
// ===========================================================================
fn _sstInPem() void {
    const numberOfSteps: u16 = getNumberOfSteps();

    if (currentLocalStepNumber == 1 and pemCursorIsZerothStep) {
        currentLocalStepNumber = 1;
        firstDisplayedLocalStepNumber = 0;
        pemCursorIsZerothStep = false;
    } else if (currentLocalStepNumber < numberOfSteps) {
        const before = currentLocalStepNumber;
        currentLocalStepNumber += 1;
        if (before >= 3) {
            if (!programListEnd) {
                firstDisplayedLocalStepNumber += 1;
            }
        }

        if (firstDisplayedLocalStepNumber + 7 > numberOfSteps) {
            if (numberOfSteps <= 6) {
                firstDisplayedLocalStepNumber = 0;
            } else {
                firstDisplayedLocalStepNumber = numberOfSteps - 6;
            }
        }
    } else {
        currentLocalStepNumber = 1;
        firstDisplayedLocalStepNumber = 0;
        pemCursorIsZerothStep = true;
    }

    defineFirstDisplayedStep();
}

pub export fn showStep() callconv(.c) void {
    temporaryInformation = TI_NO_INFO;
    refreshRegisterLine(REGISTER_T); // Clear previous VIEW or AVIEW data, if any
    refreshRegisterLine(REGISTER_Z); // Clear previous test result, if any
    _showStep();
}

pub export fn fnSst(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    screenUpdatingMode = SCRUPD_AUTO;
    if (calcMode == CM_PEM) {
        if (aimBuffer[0] != 0) {
            if (getSystemFlag(FLAG_ALPHA)) {
                pemCloseAlphaInput();
            } else if (nimNumberPart == NP_INT_BASE) {
                return;
            } else {
                pemCloseNumberInput();
            }
            aimBuffer[0] = 0;
            currentLocalStepNumber -= 1;
            currentStep = findPreviousStep(currentStep);
            if (!programListEnd) {
                scrollPemBackwards();
            }
        }
        currentInputVariable = INVALID_VARIABLE;
        _sstInPem();
    } else {
        showStep();
        if (currentInputVariable != INVALID_VARIABLE) {
            if (currentInputVariable & 0x8000 != 0) {
                fnDropY(NOPARAM);
            }
            fnStore(currentInputVariable & 0x3fff);
            currentInputVariable = INVALID_VARIABLE;
        }
        dynamicMenuItem = -1;
        programRunStop = PGM_SINGLE_STEP;
        //runProgram(true, INVALID_VARIABLE); // [DL] Not executed here, delayed until SST key released
    }
}

// ===========================================================================
// fnBack
// ===========================================================================
pub export fn fnBack(numberOfSteps: u16) callconv(.c) void {
    if (@as(i32, numberOfSteps) >= @as(i32, currentLocalStepNumber) - 1) {
        currentLocalStepNumber = 1;
        currentStep = programList[currentProgramNumber - 1].instructionPointer;
    } else {
        currentLocalStepNumber -= numberOfSteps;
        defineCurrentStep();
    }
}

// ===========================================================================
// fnSkip
// ===========================================================================
pub export fn fnSkip(numberOfSteps: u16) callconv(.c) void {
    var i: u16 = 0;
    while (i <= numberOfSteps) : (i +%= 1) { // '<=' is intended here because the pointer must be moved at least by 1 step
        const tmpStep: [*c]u8 = currentStep;
        if (!isAtEndOfProgram(tmpStep) and !isAtEndOfPrograms(tmpStep)) {
            const next: [*c]u8 = findNextStep(currentStep);
            if (next == null) {
                // !DMCP_BUILD printf diagnostic dropped.
                break;
            }
            currentLocalStepNumber += 1;
            currentStep = next;
        } else {
            break;
        }
    }
}

// ===========================================================================
// fnCase
// ===========================================================================
pub export fn fnCase(regist: u16) callconv(.c) void {
    var arg: real34_t = undefined;
    var handled = false;

    switch (getRegisterDataType(@bitCast(regist))) {
        dtLongInteger => {
            convertLongIntegerRegisterToReal34(@bitCast(regist), &arg);
            handled = true;
        },
        dtReal34 => {
            if (getRegisterAngularMode(@bitCast(regist)) == amNone) {
                real34ToIntegralValue(reg34(@bitCast(regist)), &arg, DEC_ROUND_DOWN);
                handled = true;
            }
            // else: fallthrough to the default error path.
        },
        else => {},
    }

    if (!handled) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "cannot use %s for the parameter of CASE", getRegisterDataTypeName(REGISTER_X, true, false));
            c_moreInfoOnError("In function fnCase:", errorMessage, null, null);
        }
        return;
    }

    if (real34CompareLessThan(&arg, cst34(OFF_const34_1))) {
        fnSkip(0);
    } else if (real34CompareGreaterEqual(&arg, cst34(OFF_const34_65535))) {
        fnSkip(65534);
    } else {
        fnSkip(@intCast(real34ToUInt32(&arg) - 1));
    }
}

// ===========================================================================
// defineCurrentStep / defineFirstDisplayedStep
// ===========================================================================
pub export fn defineCurrentStep() callconv(.c) void {
    currentStep = programList[currentProgramNumber - 1].instructionPointer;
    var i: u16 = 1;
    while (i < currentLocalStepNumber) : (i += 1) {
        const next: [*c]u8 = findNextStep(currentStep);
        if (next == null) {
            // !DMCP_BUILD printf diagnostic dropped.
            break;
        }
        currentStep = next;
    }
}

pub export fn defineFirstDisplayedStep() callconv(.c) void {
    firstDisplayedStep = programList[currentProgramNumber - 1].instructionPointer;
    var i: u16 = 1;
    while (i < firstDisplayedLocalStepNumber) : (i += 1) {
        const next: [*c]u8 = findNextStep(firstDisplayedStep);
        if (next == null) {
            // !DMCP_BUILD printf diagnostic dropped.
            break;
        }
        firstDisplayedStep = next;
    }
}
