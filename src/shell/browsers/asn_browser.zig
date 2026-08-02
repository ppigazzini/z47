// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/browsers/asnBrowser.c: fnAsnViewer (the assign-browser
// application entry) and its static renderer fnAsnDisplay. This is a faithful,
// line-by-line port of the C. The SAVE_SPACE_DM42_8ASN guard compiled the
// renderer (and the KEY_X_5 table) out of old-HW single-file DM42 builds; that
// guard is never enabled for the packages z47 ships, so the code is always
// present here. The kbd_std model-selection macro is reproduced inline (the
// PC-only E47/D47/V47/N47 variants are gated on !dmcp_build to match the C
// header, which only declares those symbols under PC_BUILD). lcd_fill_rect and
// bitblt24 are DMCP-ROM fixed-address calls on firmware and linkable symbols on
// host, trampolined like the sibling owners.
//
// asnBrowser.c is not reachable from the testSuite; verification is by
// build/link across every target plus the boundary gates.

const frontier_build_options = @import("frontier_build_options");
const dmcp_build: bool = frontier_build_options.dmcp_build;
const old_hw: bool = frontier_build_options.old_hw;

const LIBRARY_FN_BASE: usize = if (old_hw) 0x08000201 else 0x08000301;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const bool_t = bool;
const videoMode_t = c_int;

const abi = @import("abi"); // shared ABI bindings
const frontier_char_string = @import("../display/text/char_string.zig");
const frontier_screen = @import("../display/screen.zig");
const frontier_softmenus = @import("../display/softmenus/softmenus.zig");
const frontier_status_bar = @import("../display/statusbar/status_bar.zig");
const calcKey_t = abi.CalcKey;
const normKey_t = abi.NormKey;
const item_t = abi.Item;

// tamState_t — only .alpha is read by this file. Full layout for ABI size.
const tamState_t = abi.TamState;
// Constants / enum values (verified against defines.h / typeDefinitions.h)
// ---------------------------------------------------------------------------
const CM_AIM: u8 = 1;
const CM_EIM: u8 = 13;
const CM_ASN_BROWSER: u8 = 17;

const FLAG_USER: c_int = 0x8014;
const FLAG_ALPHA: c_uint = 0x800e;

const SOFTMENU_HEIGHT: i16 = 23;
const TI_NO_INFO: u8 = 0;
const SCREEN_WIDTH: i16 = 400;

const vmNormal: videoMode_t = 0;
const vmReverse: videoMode_t = 1;

const NOVAL: i8 = -126; // radioButtonCatalog.h

const MNU_DYNAMIC: i16 = 1394;
const ITM_XEQ: i16 = 3;
const ITM_RCL: i16 = 51;

const YOFF: i16 = 32; // local #define in the C

// calcModel values (defines.h).
const USER_V47: u8 = 40;
const USER_E47: u8 = 43;
const USER_DM42: u8 = 45;
const USER_C47: u8 = 46;
const USER_D47: u8 = 47;
const USER_N47: u8 = 51;
const USER_R47f_g: u8 = 61;
const USER_R47bk_fg: u8 = 62;
const USER_R47fg_bk: u8 = 63;
const USER_R47fg_g: u8 = 64;

// LCD raster ops (dmcp.h).
const BLT_OR: c_int = 0;
const BLT_ANDN: c_int = 1;
const BLT_NONE: c_int = 0;
const LCD_SET_VALUE: c_int = 0;

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------
extern var previousCalcMode: u8;
extern var calcMode: u8;
extern var calcModel: u8;
extern var currentAsnScr: u8;
extern var fnAsnDisplayUSER: bool_t;
extern var temporaryInformation: u8;
extern var hourGlassIconEnabled: bool_t;
extern var userKeyLabel: [*c]u8;
// assign.c's NULL-tolerant reader for userKeyLabel (added at the 6559a9c59 pin).
extern fn getUserKeyLabelString(n: i16) [*c]u8;
extern var tam: tamState_t;
extern var Norm_Key_00: normKey_t;

const font_t = abi.Font;
extern const standardFont: font_t;

extern const KEY_X: [7]c_int;

extern var kbd_usr: [37]calcKey_t;
extern const kbd_std_C47: [37]calcKey_t;
extern const kbd_std_DM42: [37]calcKey_t;
extern const kbd_std_R47f_g: [37]calcKey_t;
extern const kbd_std_R47bk_fg: [37]calcKey_t;
extern const kbd_std_R47fg_bk: [37]calcKey_t;
extern const kbd_std_R47fg_g: [37]calcKey_t;
// PC-only model variants (declared in c47.h only under PC_BUILD).
extern const kbd_std_E47: [37]calcKey_t;
extern const kbd_std_D47: [37]calcKey_t;
extern const kbd_std_V47: [37]calcKey_t;
extern const kbd_std_N47: [37]calcKey_t;

// C `item_t indexOfItems[]` is an ARRAY: bind the address. The `[*]`
// pointer form loaded the array's first bytes as the pointer -> wild deref.
const indexOfItems = @extern([*c]const item_t, .{ .name = "indexOfItems" });

// ---------------------------------------------------------------------------
// Function externs
// ---------------------------------------------------------------------------

extern fn getSystemFlag(flag: c_int) bool_t;
extern fn clearSystemFlag(flag: c_uint) void;
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcmp(a: [*c]const u8, b: [*c]const u8) c_int;

extern fn strlen(s: [*c]const u8) usize;
// stringCopy (charString.c): stpcpy semantics — copy incl. NUL, return ptr to NUL.
fn stringCopy(dest: [*c]u8, source: [*c]const u8) [*c]u8 {
    const l: u32 = @intCast(strlen(source));
    return @as([*c]u8, @ptrCast(frontier_char_string.xcopy(dest, source, l + 1))) + l;
}

// lcd_fill_rect / bitblt24 are DMCP SDK fixed-address library calls on firmware
// (LIBRARY_FN_BASE + offset); on host they are real symbols.
const LcdFillRectFn = *const fn (x: u32, y: u32, dx: u32, dy: u32, val: c_int) callconv(.c) void;
const c_lcd_fill_rect = @extern(LcdFillRectFn, .{ .name = "lcd_fill_rect" });
inline fn lcdFillRect(x: u32, y: u32, dx: u32, dy: u32, val: c_int) void {
    if (comptime dmcp_build) {
        const f: LcdFillRectFn = @ptrFromInt(LIBRARY_FN_BASE + 60);
        f(x, y, dx, dy, val);
    } else {
        c_lcd_fill_rect(x, y, dx, dy, val);
    }
}
const Bitblt24Fn = *const fn (x: u32, dx: u32, y: u32, val: u32, blt_op: c_int, fill: c_int) callconv(.c) void;
const c_bitblt24 = @extern(Bitblt24Fn, .{ .name = "bitblt24" });
inline fn bitblt24(x: u32, dx: u32, y: u32, val: u32, blt_op: c_int, fill: c_int) void {
    if (comptime dmcp_build) {
        const f: Bitblt24Fn = @ptrFromInt(LIBRARY_FN_BASE + 36);
        f(x, dx, y, val, blt_op, fill);
    } else {
        c_bitblt24(x, dx, y, val, blt_op, fill);
    }
}
// static inline setBlackPixel / setWhitePixel (hal/lcd.h).
fn setBlackPixel(x: u32, y: u32) callconv(.c) void {
    bitblt24(x, 1, y, 1, BLT_OR, BLT_NONE);
}
fn setWhitePixel(x: u32, y: u32) callconv(.c) void {
    bitblt24(x, 1, y, 1, BLT_ANDN, BLT_NONE);
}

// ---------------------------------------------------------------------------
// Inline wrappers (the C macros)
// ---------------------------------------------------------------------------
inline fn stringByteLength(str: [*c]const u8) i32 {
    return @intCast(strlen(str));
}
inline fn maxI(a: i32, b: i32) i32 {
    return if (a > b) a else b;
}
inline fn showStr(str: [*:0]const u8, x: u32, y: u32, videoMode: videoMode_t, showLeadingCols: bool_t, showEndingCols: bool_t) void {
    _ = frontier_screen.showString(str, &standardFont, x, y, videoMode, @intFromBool(showLeadingCols), @intFromBool(showEndingCols));
}

// kbd_std model-selection macro (c47.h). The E47/D47/V47/N47 variants are only
// declared under PC_BUILD, so reference them only on the host build.
inline fn kbdStd() [*]const calcKey_t {
    if (calcModel == USER_C47) return &kbd_std_C47;
    if (calcModel == USER_DM42) return &kbd_std_DM42;
    if (calcModel == USER_R47f_g) return &kbd_std_R47f_g;
    if (calcModel == USER_R47bk_fg) return &kbd_std_R47bk_fg;
    if (calcModel == USER_R47fg_bk) return &kbd_std_R47fg_bk;
    if (calcModel == USER_R47fg_g) return &kbd_std_R47fg_g;
    if (comptime !dmcp_build) {
        if (calcModel == USER_E47) return &kbd_std_E47;
        if (calcModel == USER_D47) return &kbd_std_D47;
        if (calcModel == USER_V47) return &kbd_std_V47;
        if (calcModel == USER_N47) return &kbd_std_N47;
        if (calcModel == USER_DM42) return &kbd_std_DM42;
    }
    return &kbd_std_C47;
}

// Norm_Key_00_key (defines.h:554).
inline fn normKey00Key() i16 {
    return if (calcModel == USER_C47) 0 else if (calcModel == USER_DM42) 0 else if (calcModel == USER_R47f_g) -1 else if (calcModel == USER_R47bk_fg) 10 else if (calcModel == USER_R47fg_bk) 11 else -1;
}

inline fn asnDispShortForm() bool {
    return previousCalcMode == CM_AIM or previousCalcMode == CM_EIM or tam.alpha;
}
inline fn asnDisplayUSER() bool {
    // (fnAsnDisplayUSER ^ (AsnDispShortForm & !getSystemFlag(FLAG_USER)))
    const lhs: u1 = @intFromBool(fnAsnDisplayUSER);
    const rhs: u1 = @intFromBool(asnDispShortForm()) & @intFromBool(!getSystemFlag(FLAG_USER));
    return (lhs ^ rhs) != 0;
}

// ===========================================================================
// fnAsnDisplay (static in the C)
// ===========================================================================
const KEY_X_5 = [6]c_int{ -1, 80, 160, 240, 320, 400 };

fn fnAsnDisplay(page: u8) void {
    var x1: i16 = undefined;
    var x2: i16 = undefined;
    var yy: i16 = undefined;
    var kk: c_int = 0;
    var key: i16 = undefined;
    var Name: [16]u8 = undefined;
    yy = 1;
    if (previousCalcMode == CM_AIM or previousCalcMode == CM_EIM or tam.alpha) {
        if (currentAsnScr < 4) {
            currentAsnScr = 6;
        }
    }

    // clearScreen(12): lcd_fill_rect(0,0,SCREEN_WIDTH,240,LCD_SET_VALUE) + frontier_status_bar.forceSBupdate().
    lcdFillRect(0, 0, @intCast(SCREEN_WIDTH), 240, LCD_SET_VALUE);
    frontier_status_bar.forceSBupdate();

    frontier_softmenus.showSoftmenuCurrentPart();
    showStr(if (asnDisplayUSER()) "(USER KEYS)" else "(STD KEYS)", 280, YOFF, vmNormal, false, false);
    switch (page) {
        1 => showStr("unshifted keyboard mapping", 30, YOFF, vmNormal, false, false),
        2 => showStr("f-shift keyboard mapping", 30, YOFF, vmNormal, false, false),
        3 => showStr("g-shift keyboard mapping", 30, YOFF, vmNormal, false, false),
        4 => showStr("alpha keyboard mapping", 30, YOFF, vmNormal, false, false),
        5 => showStr("alpha f-shift mapping", 30, YOFF, vmNormal, false, false),
        6 => showStr("alpha g-shift mapping", 30, YOFF, vmNormal, false, false),
        else => {},
    }
    showStr("[\xa1\x91][\xa1\x93] Browse - [.] Toggle STD/USER View", 20, 220, vmNormal, false, false);

    const kbd_std = kbdStd();

    key = 0;
    while (key < 37) : (key += 1) {
        if (key < 17) {
            x1 = @intCast(KEY_X[@intCast(@rem(key, 6) + @intFromBool(key > 12))]);
            x2 = @intCast(KEY_X[@intCast(@rem(key + @intFromBool(key > 11), 6) + 1)]);
            yy = @divTrunc(key, 6) + 1;
        } else {
            x1 = @intCast(KEY_X_5[@intCast(@rem(key - 17, 5))]);
            x2 = @intCast(KEY_X_5[@intCast(@rem(key - 17, 5) + 1)]);
            yy = @divTrunc(key - 17, 5) + 4;
        }

        var Norm_Key_00_used: bool_t = false;
        if (asnDisplayUSER()) {
            switch (page) { // in user mode, user keys override if set, and if not set, the allows +NRM to override
                1 => kk = kbd_usr[@intCast(key)].primary, // not even the +NRM key location, therefore normal user operation
                2 => kk = kbd_usr[@intCast(key)].fShifted,
                3 => kk = kbd_usr[@intCast(key)].gShifted,
                4 => kk = kbd_usr[@intCast(key)].primaryAim,
                5 => kk = kbd_usr[@intCast(key)].fShiftedAim,
                6 => kk = kbd_usr[@intCast(key)].gShiftedAim,
                else => {},
            }
        } else {
            switch (page) { // in non-user mode, +NRM overrides kbd_std
                1 => {
                    if (key == normKey00Key()) {
                        kk = Norm_Key_00.func;
                        Norm_Key_00_used = Norm_Key_00.func != kbd_std[@intCast(key)].primary; // only display in reverse and [] if different from kbd_std
                    } else {
                        kk = kbd_std[@intCast(key)].primary;
                    }
                },
                2 => kk = kbd_std[@intCast(key)].fShifted,
                3 => kk = kbd_std[@intCast(key)].gShifted,
                4 => kk = kbd_std[@intCast(key)].primaryAim,
                5 => kk = kbd_std[@intCast(key)].fShiftedAim,
                6 => kk = kbd_std[@intCast(key)].gShiftedAim,
                else => {},
            }
        }

        _ = strcpy(&Name, @ptrCast(&indexOfItems[@intCast(maxI(kk, -kk))].itemSoftmenuName));
        if (strcmp(&Name, "0000") == 0) {
            Name[0] = 0;
        }
        if (Norm_Key_00_used) {
            if ((Norm_Key_00.funcParam[0] != 0) and ((Norm_Key_00.func == -MNU_DYNAMIC) or (Norm_Key_00.func == ITM_XEQ) or (Norm_Key_00.func == ITM_RCL))) {
                _ = strcpy(&Name, &Norm_Key_00.funcParam); // name of a user menu, program or variable assigned to the Norm key
            }
        } else {
            const funcParam: [*c]u8 = getUserKeyLabelString(key * 6 + (@as(i16, page) - 1));
            if ((funcParam[0] != 0) and ((strcmp(&Name, "DYNMNU") == 0) or (strcmp(&Name, "XEQ") == 0) or (strcmp(&Name, "RCL") == 0))) {
                _ = strcpy(&Name, getUserKeyLabelString(key * 6 + (@as(i16, page) - 1))); // name of a user menu, program or variable assigned to a key
            }
        }

        var tmp3: [20]u8 = undefined;
        tmp3[0] = 0;
        if (Norm_Key_00_used) {
            _ = stringCopy(&tmp3, "[");
            _ = stringCopy(@as([*c]u8, &tmp3) + 1, &Name);
            _ = stringCopy(@as([*c]u8, &tmp3) + @as(usize, @intCast(stringByteLength(&tmp3))), "]");
            Name[0] = 0;
            _ = stringCopy(&Name, &tmp3);
        }
        const videoMode: videoMode_t = if (!Norm_Key_00_used) (if (((kk > 0 or Name[0] == 0) and tmp3[0] == 0)) vmNormal else vmReverse) else vmReverse;
        frontier_softmenus.showKey(@ptrCast(&Name), x1, x2, YOFF + yy * SOFTMENU_HEIGHT, YOFF + (yy + 1) * SOFTMENU_HEIGHT, videoMode, @intFromBool(true), @intFromBool(true), NOVAL, NOVAL, "");

        if (asnDisplayUSER() and
            (((page == 1) and (kbd_std[@intCast(key)].primary == kbd_usr[@intCast(key)].primary)) or
                ((page == 2) and (kbd_std[@intCast(key)].fShifted == kbd_usr[@intCast(key)].fShifted)) or
                ((page == 3) and (kbd_std[@intCast(key)].gShifted == kbd_usr[@intCast(key)].gShifted)) or
                ((page == 4) and (kbd_std[@intCast(key)].primaryAim == kbd_usr[@intCast(key)].primaryAim)) or
                ((page == 5) and (kbd_std[@intCast(key)].fShiftedAim == kbd_usr[@intCast(key)].fShiftedAim)) or
                ((page == 6) and (kbd_std[@intCast(key)].gShiftedAim == kbd_usr[@intCast(key)].gShiftedAim))))
        {
            const setPixel: *const fn (u32, u32) callconv(.c) void = if (videoMode != 0) &setWhitePixel else &setBlackPixel;
            var yStroke: i16 = YOFF + yy * SOFTMENU_HEIGHT + 3;
            while (yStroke < YOFF + (yy + 1) * SOFTMENU_HEIGHT - 2) : (yStroke += 1) {
                var xStroke: i16 = x1 + 3 + @as(i16, @intCast(@rem(2 * @as(i32, yStroke) + @as(i32, x1), 5)));
                while (xStroke < x2 - 2) : (xStroke += 5) {
                    setPixel(@intCast(xStroke), @intCast(yStroke));
                }
            }
        }
    }

    temporaryInformation = TI_NO_INFO;
}

// ===========================================================================
// fnAsnViewer
// ===========================================================================
pub export fn fnAsnViewer(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    hourGlassIconEnabled = false;
    if (calcMode != CM_ASN_BROWSER) {
        previousCalcMode = calcMode;
        calcMode = CM_ASN_BROWSER;
        clearSystemFlag(FLAG_ALPHA);
        currentAsnScr = if (asnDispShortForm()) 6 else 1;
        return;
    }
    fnAsnDisplay(currentAsnScr);
}
