const abi = @import("abi");
const frontier_calc_mode = @import("frontier_calc_mode.zig"); // M-callconv: Zig-to-Zig
const frontier_char_string = @import("frontier_char_string.zig"); // M-callconv: Zig-to-Zig
const frontier_screen = @import("frontier_screen.zig"); // M-callconv: Zig-to-Zig
const frontier_softmenus = @import("frontier_softmenus.zig"); // M-callconv: Zig-to-Zig
// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/c47Extensions/xeqm.c: fnXSWAP, the X<>alpha-buffer
// swap/edit command. This is a faithful, line-by-line port of the C. The
// number->string conversion goes through the C `addition` [10][10] function
// pointer dispatch table (declared here as a Zig array of C function
// pointers); the AIM/EIM cursor bookkeeping writes the same globals in the
// same order as the C.
//
// xeqm.c is not reachable from the testSuite; verification is by build/link
// across every target plus the boundary gates.

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const calcRegister_t = i16;

// ---------------------------------------------------------------------------
// Constants / enum values (verified against defines.h / typeDefinitions.h)
// ---------------------------------------------------------------------------
const CM_NORMAL: u8 = 0;
const CM_AIM: u8 = 1;
const CM_EIM: u8 = 13;

const dtLongInteger: u32 = 0;
const dtReal34: u32 = 1;
const dtComplex34: u32 = 2;
const dtTime: u32 = 3;
const dtDate: u32 = 4;
const dtString: u32 = 5;
const dtShortInteger: u32 = 8;

const amNone: u32 = 5;

const REGISTER_X: calcRegister_t = 100;
const REGISTER_Y: calcRegister_t = 101;
const REGISTER_Z: calcRegister_t = 102;
const TEMP_REGISTER_1: calcRegister_t = 135;

const NOPARAM: u16 = 9876;

const AIM_BUFFER_LENGTH: i32 = 1024;
const TMP_STR_LENGTH: usize = 2560;

const FLAG_ERPN: c_uint = 0x8045;
const FLAG_ASLIFT: c_uint = 0xc023;

const MNU_ALPHA: i16 = 1922;

const NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS = 10;

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------
extern var calcMode: u8;
extern var aimBuffer: [*c]u8;
extern var T_cursorPos: i16;
extern var xCursor: u32;
extern var last_CM: u8;

const Fn0 = ?*const fn () callconv(.c) void;
extern const addition: [NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS]Fn0;

// ---------------------------------------------------------------------------
// Function externs
// ---------------------------------------------------------------------------
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) *anyopaque;
extern fn fnSwapXY(unusedButMandatoryParameter: u16) void;
extern fn fnDrop(unusedButMandatoryParameter: u16) void;
extern fn copySourceRegisterToDestRegister(rSource: calcRegister_t, rDest: calcRegister_t) void;
extern fn reallocateRegister(regist: calcRegister_t, dataType: u32, dataSizeWithoutDataLenBlocks: u16, tag: u32) void;

extern fn adjustResult(result: calcRegister_t, dropY: bool, setCpxRes: bool, op1: calcRegister_t, op2: calcRegister_t, op3: calcRegister_t) void;
extern fn clearRegister(regist: calcRegister_t) void;
extern fn getSystemFlag(flag: c_int) bool;
extern fn setSystemFlag(flag: c_uint) void;
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strlen(s: [*c]const u8) usize;

extern fn resetShiftState() void;

extern fn liftStack() void;

// ---------------------------------------------------------------------------
// Inline wrappers (the C macros)
// ---------------------------------------------------------------------------
// REGISTER_STRING_DATA: data pointer + sizeof(strLgIntHeader_t) == 4.
const regString = abi.registerString;
inline fn stringByteLength(str: [*c]const u8) i32 {
    return @intCast(strlen(str));
}
// TO_BLOCKS(n) == ((uint32_t)n + 3) >> 2.
inline fn toBlocks(n: i32) u16 {
    return @intCast((@as(u32, @bitCast(n)) +% 3) >> 2);
}

// ===========================================================================
// fnXSWAP
// ===========================================================================
pub export fn fnXSWAP(mode: u16) callconv(.c) void {
    const isEdit: bool = mode > 0;
    const isSwap: bool = !isEdit;

    if (calcMode == CM_EIM or calcMode == CM_AIM) {
        if (calcMode == CM_AIM) {
            fnSwapXY(0);
        }
        // convert X to string if needed
        const type_x: u32 = getRegisterDataType(REGISTER_X);
        if (type_x == dtString and stringByteLength(regString(REGISTER_X)) >= AIM_BUFFER_LENGTH) {
            if (calcMode == CM_AIM) {
                fnSwapXY(0); // swap back before returning with nothing done
            }
            return;
        }
        if (type_x == dtReal34 or type_x == dtComplex34 or type_x == dtLongInteger or type_x == dtShortInteger or type_x == dtTime or type_x == dtDate) {
            // Backup Y; Use Y as temp to add to X; Convert number in X to string; Restore Y; Leave X as string
            copySourceRegisterToDestRegister(REGISTER_Y, TEMP_REGISTER_1); // Save Y to temp register
            var tmp: [2]u8 = undefined;
            tmp[0] = 0;
            const len: i16 = @intCast(stringByteLength(&tmp) + 1);
            reallocateRegister(REGISTER_Y, dtString, toBlocks(len), amNone); // Make blank string in Y
            _ = frontier_char_string.xcopy(regString(REGISTER_Y), &tmp, @intCast(len));
            addition[type_x][getRegisterDataType(REGISTER_Y)].?(); // Convert X (number) to string in X
            adjustResult(REGISTER_X, false, false, -1, -1, -1);

            copySourceRegisterToDestRegister(TEMP_REGISTER_1, REGISTER_Y); // restore Y
            clearRegister(TEMP_REGISTER_1); // Clear in case it was a really long longinteger
            // resulting in a converted string in X, with Y unchanged
        }
        if (getRegisterDataType(REGISTER_X) != dtString) { // somehow failed to convert then return with whatever was done in X
            if (calcMode == CM_AIM) {
                fnSwapXY(0); //  This could be optimized to still restore the original X register if it had failed to convert
            }
            return;
        }

        if (isSwap) {
            // Save aimbuffer to TEMP1 as a string register
            const len: i16 = @intCast(stringByteLength(aimBuffer) + 1);
            reallocateRegister(TEMP_REGISTER_1, dtString, toBlocks(len), amNone);
            _ = frontier_char_string.xcopy(regString(TEMP_REGISTER_1), aimBuffer, @intCast(len));
        }
        // In essence, after conversions,
        // If X is string shorter than buffer max, copy X to aimbuffer
        // If X is no string, ignore, then aimbuffer remains unchanged.
        if (getRegisterDataType(REGISTER_X) == dtString) {
            if (stringByteLength(regString(REGISTER_X)) < AIM_BUFFER_LENGTH) {
                _ = strcpy(aimBuffer, regString(REGISTER_X));

                if (isSwap) {
                    // copy aimbuffer to X
                    copySourceRegisterToDestRegister(TEMP_REGISTER_1, REGISTER_X);
                }
                // Set cursors
                if (calcMode == CM_AIM) {
                    fnSwapXY(0);
                    T_cursorPos = @intCast(stringByteLength(aimBuffer));
                    if (isEdit) {
                        fnDrop(NOPARAM);
                    }
                } else { // EIM
                    xCursor = @intCast(frontier_char_string.stringGlyphLength(aimBuffer));
                }
                frontier_screen.refreshRegisterLine(REGISTER_X); // make sure that the multi line editor check is done
                last_CM = 253;
                frontier_screen.refreshScreen(64);
            }
        }
        clearRegister(TEMP_REGISTER_1);
    } else if (calcMode == CM_NORMAL and getRegisterDataType(REGISTER_X) == dtString) {
        if (stringByteLength(regString(REGISTER_X)) < AIM_BUFFER_LENGTH) {
            if (getSystemFlag(@bitCast(FLAG_ERPN))) { // JM NEWERPN
                setSystemFlag(FLAG_ASLIFT); // JM NEWERPN OVERRIDE SLS, AS ERPN ENTER ALWAYS HAS SLS SET
            } // JM NEWERPN
            _ = strcpy(aimBuffer, regString(REGISTER_X));
            T_cursorPos = @intCast(stringByteLength(aimBuffer));
            fnDrop(NOPARAM);
            resetShiftState();
            frontier_calc_mode.calcModeAim(NOPARAM); // Alpha Input Mode
            frontier_softmenus.showSoftmenu(-MNU_ALPHA);
        }
    } else if (calcMode == CM_NORMAL and getRegisterDataType(REGISTER_X) != dtString) {
        var line1: [TMP_STR_LENGTH]u8 = undefined;
        line1[0] = 0;
        _ = strcpy(&line1, " ");
        const len: i16 = @intCast(stringByteLength(&line1));
        if (getSystemFlag(@bitCast(FLAG_ERPN))) { // JM NEWERPN
            setSystemFlag(FLAG_ASLIFT); // JM NEWERPN OVERRIDE SLS, AS ERPN ENTER ALWAYS HAS SLS SET
        } // JM NEWERPN
        liftStack();
        reallocateRegister(REGISTER_X, dtString, toBlocks(len), amNone);
        _ = strcpy(regString(REGISTER_X), &line1);
        fnXSWAP(0);
    }

    last_CM = 252;
    frontier_screen.refreshScreen(63);
    last_CM = 251;
    frontier_screen.refreshScreen(0);
}
