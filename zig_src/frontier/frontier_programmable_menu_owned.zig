// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/programming/programmableMenu.c: fnKeyGtoXeq /
// fnKeyGto / fnKeyXeq (the KEY?GTO/KEY?XEQ program-step handlers),
// fnProgrammableMenu, fnClearMenu and keyGto / keyXeq (which build the
// programmable softmenu captions from register X). This is a faithful,
// line-by-line port of the C. The file-static helpers (_getStringLabelOrVariableName,
// _indirectRegister, _indirectVariable, _get2ndParamOfKey, _setCaption) are
// reproduced as private Zig fns; regKStoC is a static-inline reimplementation;
// the EXTRA_INFO sprintf/moreInfoOnError diagnostics are gated on extra_info.
//
// programmableMenu.c is not reachable from the testSuite; verification is by
// build/link across every target plus the boundary gates.

const frontier_build_options = @import("frontier_build_options");
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const calcRegister_t = i16;
const font_t = opaque {};
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const real34_t = abi.Real34;
const complex34_t = abi.Complex34;
const irfracOption_t = c_int;

const programmableMenu_t = extern struct {
    itemName: [18][16]u8,
    itemParam: [21]u16,
    unused: u16,
};

const softmenu_t = abi.Softmenu;
const softmenuStack_t = abi.SoftmenuStack;
const tamState_t = abi.TamState;
// Constants / enum values (verified against defines.h / items.h / display.h)
// ---------------------------------------------------------------------------
const LAST_LOCAL_REGISTER_IN_KS_CODE: u8 = 210;
const FIRST_LOCAL_REGISTER_IN_KS_CODE: i32 = 112;
const FIRST_STAT_REGISTER_IN_KS_CODE: u8 = 211;
const LAST_SPARE_REGISTERS_IN_KS_CODE: u8 = 224;
const FIRST_LOCAL_REGISTER: i32 = 7000;
const LAST_LOCAL_REGISTER: i32 = 7098;
const NUMBER_OF_LOCAL_REGISTERS: i32 = 99;

const INDPM_REGISTER: u16 = 1;
const INVALID_VARIABLE: u16 = 2199;
const FAILED_INDIRECTION: i16 = 9999;
const STRING_LABEL_VARIABLE: u8 = 253;
const INDIRECT_REGISTER: u8 = 254;
const INDIRECT_VARIABLE: u8 = 255;

const ERROR_NONE: u8 = 0;
const ERROR_LABEL_NOT_FOUND: u8 = 6;
const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;
const ERROR_UNDEF_SOURCE_VAR: u8 = 36;

const REGISTER_X: calcRegister_t = 100;
const REGISTER_Z: calcRegister_t = 102;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;

const FLAG_IGN1ER: c_uint = 0x8024;

const ITM_KEY: i16 = 1497;
const ITM_XEQ: i16 = 3;
const ITM_RCL: i16 = 51;
const ITM_MENU: i16 = 1520;
const NOPARAM: u16 = 9876;

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

const SCREEN_WIDTH: i16 = 400;
const NUMBER_OF_DISPLAY_DIGITS: i16 = 20;
const TMP_STR_LENGTH: i32 = 2560;
const LIMITEXP: bool = true;
const FRONTSPACE: bool = true;
const NOIRFRAC: irfracOption_t = 0;
const noBaseOverride: u8 = 0;

const amAngleMask: u32 = 15;
const amPolar: u32 = 16;

const STD_RIGHT_ARROW = "\xa1\x92";

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------
extern var tmpStringLabelOrVariableName: [*c]u8;
extern var firstFreeProgramByte: [*c]u8;
extern var tmpString: [*c]u8;
extern var currentStep: [*c]u8;
extern var lastErrorCode: u8;
extern var dynamicMenuItem: i16;
extern var errorMessage: [*c]u8;
extern var programmableMenu: programmableMenu_t;
extern var tam: tamState_t;
// C `softmenu[]` / `softmenuStack[N]` are ARRAYS: bind the address (gotcha #1).
// The `[*]` pointer form loaded array bytes as the pointer -> wild deref.
const softmenu = @extern([*c]const softmenu_t, .{ .name = "softmenu" });
const softmenuStack = @extern([*c]softmenuStack_t, .{ .name = "softmenuStack" });

extern const standardFont: font_t;
extern const numericFont: font_t;

// ---------------------------------------------------------------------------
// Function externs
// ---------------------------------------------------------------------------
extern fn xcopy(dst: *anyopaque, src: *const anyopaque, n: u32) *anyopaque;
extern fn strlen(s: [*c]const u8) usize;
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;
extern fn indirectAddressing(regist: calcRegister_t, parameterType: u16, minValue: i16, maxValue: i16, tryAllocate: bool) i16;
extern fn findNamedVariable(variableName: [*c]const u8) calcRegister_t;
extern fn findNamedLabel(labelName: [*c]const u8) calcRegister_t;
extern fn findKey2ndParam(step: [*c]u8) [*c]u8;
extern fn displayCalcErrorMessage(errorCode: u8, errMessageRegisterLine: calcRegister_t, errRegisterLine: calcRegister_t) void;
const c_moreInfoOnError = @extern(*const fn (m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) callconv(.c) void, .{ .name = "moreInfoOnError" });
extern fn getSystemFlag(flag: c_int) bool;
extern fn clearSystemFlag(flag: c_uint) void;
extern fn showSoftmenu(id: i16) void;
extern fn popSoftmenu() void;
extern fn runProgram(singleStep: bool, menuLabel: u16) void;
extern fn fnDrop(unusedButMandatoryParameter: u16) void;
extern fn lastFuncNo() i16;
extern var lastFunc: i16;
extern var alphaRegister: u16;
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterTag(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) *anyopaque;

extern fn longIntegerRegisterToDisplayString(regist: calcRegister_t, displayString: [*c]u8, strLg: i32, maxWidth: i16, maxExp: i16, allowLARGELI: bool) void;
extern fn timeToDisplayString(regist: calcRegister_t, displayString: [*c]u8, ignoreTDisp: bool) void;
extern fn dateToDisplayString(regist: calcRegister_t, displayString: [*c]u8) void;
extern fn real34MatrixToDisplayString(regist: calcRegister_t, displayString: [*c]u8) void;
extern fn complex34MatrixToDisplayString(regist: calcRegister_t, displayString: [*c]u8) void;
extern fn shortIntegerToDisplayString(regist: calcRegister_t, displayString: [*c]u8, determineFont: bool, baseOverride: u8) void;
extern fn real34ToDisplayString(real34: *align(1) const real34_t, tag: u32, displayString: [*c]u8, font: *const font_t, maxWidth: i16, displayHasNDigits: i16, limitExponent: bool, frontSpace: bool, limitIrfrac: irfracOption_t) void;
extern fn complex34ToDisplayString(complex34: *align(1) const complex34_t, displayString: [*c]u8, font: *const font_t, maxWidth: i16, displayHasNDigits: i16, limitExponent: bool, frontSpace: bool, limitIrfrac: irfracOption_t, tagAngle: u16, tagPolar: bool) void;

// ---------------------------------------------------------------------------
// Inline wrappers (the C macros / static inlines)
// ---------------------------------------------------------------------------
inline fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8) void {
    if (comptime extra_info) c_moreInfoOnError(m1, m2, null, null);
}
inline fn stringByteLength(str: [*c]const u8) i32 {
    return @intCast(strlen(str));
}
inline fn regReal34(reg: calcRegister_t) *align(1) const real34_t {
    return @ptrCast(getRegisterDataPointer(reg));
}
inline fn regComplex34(reg: calcRegister_t) *align(1) const complex34_t {
    return @ptrCast(getRegisterDataPointer(reg));
}
inline fn getRegisterAngularMode(reg: calcRegister_t) u32 {
    return getRegisterTag(reg) & amAngleMask;
}
inline fn getComplexRegisterAngularMode(reg: calcRegister_t) u32 {
    return getRegisterTag(reg) & amAngleMask;
}
inline fn getComplexRegisterPolarMode(reg: calcRegister_t) u32 {
    return getRegisterTag(reg) & amPolar;
}
// regKStoC (static inline, defines.h).
inline fn regKStoC(regKS: u8) i16 {
    return @as(i16, @intCast(@as(i32, regKS) -
        @as(i32, @intFromBool(FIRST_STAT_REGISTER_IN_KS_CODE <= regKS and regKS <= LAST_SPARE_REGISTERS_IN_KS_CODE)) * NUMBER_OF_LOCAL_REGISTERS +
        @as(i32, @intFromBool(FIRST_LOCAL_REGISTER_IN_KS_CODE <= @as(i32, regKS) and @as(i32, regKS) <= @as(i32, LAST_LOCAL_REGISTER_IN_KS_CODE))) * (FIRST_LOCAL_REGISTER - FIRST_LOCAL_REGISTER_IN_KS_CODE)));
}
// COPY_REGISTER_STRING_TO(dest, regist) (registers.h).
inline fn copyRegisterStringTo(dest: [*c]u8, regist: calcRegister_t) void {
    const regData: ?*anyopaque = getRegisterDataPointer(regist);
    if (regData != null) {
        const regStr: [*c]u8 = @as([*c]u8, @ptrCast(regData.?)) + 4; // sizeof(strLgIntHeader_t)
        _ = xcopy(dest, regStr, @intCast(stringByteLength(regStr) + 1));
    }
}

// ===========================================================================
// _getStringLabelOrVariableName (static in the C)
// ===========================================================================
// Upstream shares the bounded decoder in decode.c (getStringLabelOrVariableName);
// this local copy carries the same clamp so a corrupt step's length byte cannot
// read past the program region.
fn _getStringLabelOrVariableName(stringAddress_arg: [*c]u8) void {
    const stringAddress = stringAddress_arg + 1;
    var stringLength: u8 = stringAddress_arg[0];
    if (@intFromPtr(stringAddress) >= @intFromPtr(firstFreeProgramByte)) {
        stringLength = 0;
    } else if (stringLength > @intFromPtr(firstFreeProgramByte) - @intFromPtr(stringAddress)) {
        stringLength = @intCast(@intFromPtr(firstFreeProgramByte) - @intFromPtr(stringAddress));
    }
    _ = xcopy(tmpStringLabelOrVariableName, stringAddress, stringLength);
    tmpStringLabelOrVariableName[stringLength] = 0;
}

// ===========================================================================
// _indirectRegister (static in the C)
// ===========================================================================
fn _indirectRegister(paramAddress: [*c]u8) u16 {
    const opParam: u8 = paramAddress[0];
    if (opParam <= LAST_LOCAL_REGISTER_IN_KS_CODE) { // Local register from .00 to .98
        const realParam: i16 = indirectAddressing(regKStoC(opParam), INDPM_REGISTER, 0, 99, false);
        if (realParam < 9999) {
            return @bitCast(realParam);
        }
    } else {
        _ = sprintf(tmpString, "\nIn function _indirectRegister: " ++ STD_RIGHT_ARROW ++ " %u is not a valid parameter!", @as(c_uint, opParam));
    }
    return INVALID_VARIABLE;
}

// ===========================================================================
// _indirectVariable (static in the C)
// ===========================================================================
fn _indirectVariable(stringAddress: [*c]u8) u16 {
    _getStringLabelOrVariableName(stringAddress);
    const regist: calcRegister_t = findNamedVariable(tmpStringLabelOrVariableName);
    if (regist != @as(calcRegister_t, @bitCast(INVALID_VARIABLE))) {
        const realParam: i16 = indirectAddressing(regist, INDPM_REGISTER, 0, 99, false);
        if (realParam < 9999) {
            return @bitCast(realParam);
        }
    } else {
        displayCalcErrorMessage(ERROR_UNDEF_SOURCE_VAR, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "string '%s' is not a named variable", tmpStringLabelOrVariableName);
            moreInfoOnError("In function _indirectVariable:", errorMessage);
        }
    }
    return INVALID_VARIABLE;
}

// ===========================================================================
// _get2ndParamOfKey (static in the C)
// ===========================================================================
fn _get2ndParamOfKey(paramAddress_arg: [*c]u8) u16 {
    var paramAddress = paramAddress_arg;
    const opParam: u8 = paramAddress[0];
    paramAddress += 1;

    if (opParam <= 109) { // Local label from 00 to 99 or from A to J
        return opParam;
    } else if (opParam == STRING_LABEL_VARIABLE) {
        _getStringLabelOrVariableName(paramAddress);
        const label: calcRegister_t = findNamedLabel(tmpStringLabelOrVariableName);
        if (label != @as(calcRegister_t, @bitCast(INVALID_VARIABLE))) {
            return @bitCast(label);
        } else {
            displayCalcErrorMessage(ERROR_LABEL_NOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                _ = sprintf(errorMessage, "string '%s' is not a named label", tmpStringLabelOrVariableName);
                moreInfoOnError("In function _get2ndParamOfKey:", errorMessage);
            }
        }
    } else if (opParam == INDIRECT_REGISTER) {
        return _indirectRegister(paramAddress);
    } else if (opParam == INDIRECT_VARIABLE) {
        return _indirectVariable(paramAddress);
    } else {
        if (comptime extra_info) {
            _ = sprintf(tmpString, "\nIn function _get2ndParamOfKey: %u is not a valid parameter!", @as(c_uint, opParam));
        }
    }
    return INVALID_VARIABLE;
}

// ===========================================================================
// fnKeyGtoXeq
// ===========================================================================
pub export fn fnKeyGtoXeq(keyNum: u16) callconv(.c) void {
    const secondParam: [*c]u8 = findKey2ndParam(currentStep);
    var label: u16 = undefined;

    if (secondParam == null) { // findKey2ndParam returns NULL on a malformed/.END. step
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        return;
    }

    const opParam: [*c]u8 = secondParam + 1;
    label = _get2ndParamOfKey(opParam);

    if (lastErrorCode != ERROR_NONE and getSystemFlag(@bitCast(FLAG_IGN1ER))) {
        lastErrorCode = ERROR_NONE;
        clearSystemFlag(FLAG_IGN1ER);
    } else if (secondParam[0] == ITM_XEQ) {
        keyXeq(keyNum, label);
    } else {
        keyGto(keyNum, label);
    }
}

// ===========================================================================
// fnKeyGto / fnKeyXeq
// ===========================================================================
pub export fn fnKeyGto(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    keyGto(@bitCast(tam.key), @bitCast(tam.value));
}

pub export fn fnKeyXeq(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    keyXeq(@bitCast(tam.key), @bitCast(tam.value));
}

// ===========================================================================
// fnProgrammableMenu
// ===========================================================================
pub export fn fnProgrammableMenu(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    // Show the programmable menu
    if (dynamicMenuItem == -1 or softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem != -ITM_MENU) {
        showSoftmenu(-ITM_MENU);
    }
    // Select the programmable menu
    else if (programmableMenu.itemParam[@intCast(dynamicMenuItem)] != INVALID_VARIABLE) {
        const prm: i16 = dynamicMenuItem;
        dynamicMenuItem = -1;
        // No popSoftmenu() here — upstream removed it (commit 5d2af9e43); popping
        // the softmenu before runProgram corrupted the stack the program runs under.
        runProgram(false, programmableMenu.itemParam[@intCast(prm)]);
    }
    // EXIT key
    else if (dynamicMenuItem == 20) {
        dynamicMenuItem = -1;
        popSoftmenu();
    }
}

// ===========================================================================
// fnClearMenu
// ===========================================================================
pub export fn fnClearMenu(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var i: usize = 0;
    while (i < 18) : (i += 1) {
        programmableMenu.itemName[i][0] = 0;
        programmableMenu.itemParam[i] = INVALID_VARIABLE;
    }
    i = 18;
    while (i < 21) : (i += 1) {
        programmableMenu.itemParam[i] = INVALID_VARIABLE;
    }
}

// ===========================================================================
// _setCaption (static in the C)
// ===========================================================================
fn _setCaption(keyNum: u16) void {
    if (1 <= keyNum and keyNum <= 18) {
        var ts: [*c]u8 = tmpString;
        const stringRegister: calcRegister_t = if (lastFuncNo() == ITM_KEY) REGISTER_X else @intCast(alphaRegister);
        switch (getRegisterDataType(stringRegister)) {
            dtString => {
                copyRegisterStringTo(tmpString, stringRegister);
            },
            dtLongInteger => {
                longIntegerRegisterToDisplayString(stringRegister, tmpString, TMP_STR_LENGTH, SCREEN_WIDTH, 50, false); // JM added last parameter: Allow LARGELI
            },
            dtTime => {
                timeToDisplayString(stringRegister, tmpString, false);
            },
            dtDate => {
                dateToDisplayString(stringRegister, tmpString);
            },
            dtReal34Matrix => {
                real34MatrixToDisplayString(stringRegister, tmpString);
            },
            dtComplex34Matrix => {
                complex34MatrixToDisplayString(stringRegister, tmpString);
            },
            dtShortInteger => {
                shortIntegerToDisplayString(stringRegister, tmpString, false, noBaseOverride);
            },
            dtReal34 => {
                real34ToDisplayString(regReal34(stringRegister), getRegisterAngularMode(stringRegister), tmpString, &standardFont, SCREEN_WIDTH, NUMBER_OF_DISPLAY_DIGITS, !LIMITEXP, FRONTSPACE, NOIRFRAC);
            },
            dtComplex34 => {
                complex34ToDisplayString(regComplex34(stringRegister), tmpString, &numericFont, SCREEN_WIDTH, NUMBER_OF_DISPLAY_DIGITS, !LIMITEXP, FRONTSPACE, NOIRFRAC, @intCast(getComplexRegisterAngularMode(stringRegister)), getComplexRegisterPolarMode(stringRegister) != 0);
            },
            dtConfig => {
                _ = xcopy(tmpString, "Configu", 8);
            },
            else => {
                tmpString[0] = 0;
            },
        }

        if (lastFunc == ITM_KEY) { // Drop for ITM_KEY, not for ITM_42KEY
            fnDrop(NOPARAM);
        }

        var i: usize = 0;
        while (i < 7 and ts[0] != 0) : (i += 1) {
            ts += if ((ts[0] & 0x80) != 0) @as(usize, 2) else @as(usize, 1);
        }
        ts[0] = 0;

        _ = xcopy(&programmableMenu.itemName[keyNum - 1], tmpString, @intCast(stringByteLength(tmpString) + 1));
    }
}

// ===========================================================================
// keyGto / keyXeq
// ===========================================================================
pub export fn keyGto(keyNum: u16, label: u16) callconv(.c) void {
    _setCaption(keyNum);
    programmableMenu.itemParam[keyNum - 1] = label & 0x7fff;
}

pub export fn keyXeq(keyNum: u16, label: u16) callconv(.c) void {
    _setCaption(keyNum);
    programmableMenu.itemParam[keyNum - 1] = label | 0x8000;
}
