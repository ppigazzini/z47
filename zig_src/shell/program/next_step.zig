// SPDX-License-Identifier: GPL-3.0-only
const consts = abi.constants;
const const34_65535 = consts.const34_65535;
const const34_1 = consts.const34_1;
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

const std = @import("std");
const frontier_build_options = @import("frontier_build_options");
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const calcRegister_t = i16;
const bool_t = u32;
const angularMode_t = c_int;

const real34_t = abi.Real34;
const abi = @import("abi"); // shared ABI bindings
const frontier_char_string = @import("../display/text/char_string.zig");
const frontier_debug = @import("../debug.zig");
const frontier_decode = @import("decode.zig");
const frontier_error = @import("../error.zig");
const frontier_items = @import("../display/items/items.zig");
const frontier_manage = @import("manage.zig");
const frontier_register_value_conversions = @import("../register_value_conversions.zig");
const frontier_screen = @import("../display/screen.zig");
const frontier_store = @import("../store.zig");
const realContext_t = abi.RealContext;
const font_t = abi.Font;

const labelList_t = abi.LabelList;
const programList_t = abi.ProgramList;
const item_t = abi.Item;
const program_step_width = @import("program_step_width.zig"); // std+abi step widths

// ---------------------------------------------------------------------------
// Constants / enum values (verified against defines.h / items.h)
// ---------------------------------------------------------------------------

const PARAM_NUMBER_8: u16 = 5;

const PTP_STATUS: u16 = 0x1e00;
const PTP_NONE: u16 = 0 << 9;
const PTP_KEYG_KEYX: u16 = 8 << 9;
const PTP_LITERAL: u16 = 13 << 9;
const PTP_REM: u16 = 14 << 9;
const PTP_DISABLED: u16 = 15 << 9;

const ITM_LBL: u16 = 1;
const ITM_END: u16 = 1458;
const ITM_KEY: u16 = 1497;
const ITM_42KEY: u16 = 2794; // HP-42S KEY step (upstream added KEY/42KEY dual handling)

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

const LAST_ITEM: u32 = 2870;

// ---------------------------------------------------------------------------
// Constant blob
// ---------------------------------------------------------------------------

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

extern fn getSystemFlag(sf: c_int) bool;
extern fn fnDropY(unusedButMandatoryParameter: u16) void;

extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterTag(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) *anyopaque;

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
    return frontier_manage.checkOpCodeOfStep(step, ITM_END);
}
const reg34 = abi.registerReal34;
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
    return abi.block_math.toBytes(u32, n);
}

// ===========================================================================
// countOpBytes / countLiteralBytes -> program_step_width.zig (std+abi, tested).
// Thin C-ABI wrappers; the pure byte-width arithmetic lives in the module.
// ===========================================================================
fn isOldParam16(func: u16) bool {
    return frontier_items.isFunctionOldParam16(func) != 0;
}

pub export fn countOpBytes(step: [*c]u8, paramMode: u16) callconv(.c) [*c]u8 {
    return program_step_width.countOpBytes(step, paramMode, isOldParam16);
}

pub export fn countLiteralBytes(step: [*c]u8) callconv(.c) [*c]u8 {
    return program_step_width.countLiteralBytes(step);
}

// ===========================================================================
// findNextStep
// ===========================================================================
pub export fn findNextStep(step: [*c]u8) callconv(.c) [*c]u8 {
    if (step == null) {
        // !DMCP_BUILD printf diagnostic dropped.
        return null;
    }
    if (frontier_manage.checkOpCodeOfStep(step, ITM_KEY) or frontier_manage.checkOpCodeOfStep(step, ITM_42KEY)) {
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
    const lblOrEnd: bool = frontier_manage.checkOpCodeOfStep(tmpStep, ITM_LBL) or isAtEndOfProgram(tmpStep) or frontier_manage.isAtEndOfPrograms(tmpStep);
    const xPos: i16 = if (lblOrEnd) 42 else 62;
    var maxWidth: i16 = SCREEN_WIDTH - xPos;

    abi.fmtBufZ(tmpString[0..2560], "{d:0>4}:" ++ "\xa0\x05", .{@as(u32, currentLocalStepNumber)});
    _ = frontier_screen.showString(tmpString, &standardFont, 1, Y_POSITION_OF_REGISTER_T_LINE + 6, vmNormal, @intFromBool(true), @intFromBool(true));

    frontier_decode.decodeOneStep(tmpStep);
    if (frontier_char_string.stringWidth(tmpString, &standardFont, true, true) >= maxWidth) {
        var xstr: [*c]u8 = tmpString;
        var xstrOrig: [*c]u8 = tmpString;
        const glyph: [*c]u8 = tmpString + TMP_STR_LENGTH - 4;
        maxWidth -= frontier_char_string.stringWidth(STD_ELLIPSIS, &standardFont, true, true);
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
            maxWidth -= frontier_char_string.stringWidth(glyph, &standardFont, true, true);
        }
        xstrOrig[0] = STD_ELLIPSIS[0];
        xstrOrig[1] = STD_ELLIPSIS[1];
        xstrOrig[2] = 0;
    }
    _ = frontier_screen.showString(tmpString, &standardFont, @intCast(xPos), Y_POSITION_OF_REGISTER_T_LINE + 6, vmNormal, @intFromBool(true), @intFromBool(true));
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
        const numberOfSteps: u16 = frontier_manage.getNumberOfSteps();
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
                frontier_manage.pemCloseAlphaInput();
            } else if (nimNumberPart == NP_INT_BASE) {
                return;
            } else {
                frontier_manage.pemCloseNumberInput();
            }
            aimBuffer[0] = 0;
            currentLocalStepNumber -= 1;
            currentStep = findPreviousStep(currentStep);
            if (!programListEnd) {
                frontier_manage.scrollPemBackwards();
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
    const numberOfSteps: u16 = frontier_manage.getNumberOfSteps();

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
    frontier_screen.refreshRegisterLine(REGISTER_T); // Clear previous VIEW or AVIEW data, if any
    frontier_screen.refreshRegisterLine(REGISTER_Z); // Clear previous test result, if any
    _showStep();
}

pub export fn fnSst(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    screenUpdatingMode = SCRUPD_AUTO;
    if (calcMode == CM_PEM) {
        if (aimBuffer[0] != 0) {
            if (getSystemFlag(FLAG_ALPHA)) {
                frontier_manage.pemCloseAlphaInput();
            } else if (nimNumberPart == NP_INT_BASE) {
                return;
            } else {
                frontier_manage.pemCloseNumberInput();
            }
            aimBuffer[0] = 0;
            currentLocalStepNumber -= 1;
            currentStep = findPreviousStep(currentStep);
            if (!programListEnd) {
                frontier_manage.scrollPemBackwards();
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
            frontier_store.fnStore(currentInputVariable & 0x3fff);
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
        if (!isAtEndOfProgram(tmpStep) and !frontier_manage.isAtEndOfPrograms(tmpStep)) {
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
            frontier_register_value_conversions.convertLongIntegerRegisterToReal34(@bitCast(regist), &arg);
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
        frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "cannot use {s} for the parameter of CASE", .{std.mem.span(frontier_debug.getRegisterDataTypeName(REGISTER_X, true, false))});
            c_moreInfoOnError("In function fnCase:", errorMessage, null, null);
        }
        return;
    }

    if (real34CompareLessThan(&arg, const34_1())) {
        fnSkip(0);
    } else if (real34CompareGreaterEqual(&arg, const34_65535())) {
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
