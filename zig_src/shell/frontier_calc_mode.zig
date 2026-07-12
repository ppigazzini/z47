// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/calcMode.c: fnOff, calcModeNormal, calcModeAim,
// enterAsmModeIfMenuIsACatalog, leaveAsmMode and calcModeNim. This is a faithful,
// line-by-line port of the C.
//
// fnOff has fully distinct PC_BUILD and DMCP_BUILD bodies: on host it frees an
// open matrix-editor matrix, saves the calc and quits GTK; on firmware it sets
// the STAT_PGM_END bit of the fixed-address DMCP state word (sdb.calc_state). Both
// are reproduced, gated on dmcp_build. The PC-only jm_show_comment telltale calls
// (calcModeNormal / calcModeAim / enterAsmMode / calcModeNim) are reproduced as
// calls to the host-provided jm_show_comment symbol; on firmware that symbol does
// not exist, so the calls are compiled out under !dmcp_build (matching the
// upstream #if PC_BUILD guards).
//
// calcMode.c is not reachable from the testSuite; verification is by build/link
// across every target plus the boundary gates.

const frontier_build_options = @import("frontier_build_options");
const dmcp_build: bool = frontier_build_options.dmcp_build;
const old_hw: bool = frontier_build_options.old_hw;

// DMCP sys_sdb_t base address (dmcp.h: #define sdb (*((sys_sdb_t*)BASE))).
// calc_state is the first field (volatile uint32_t at offset 0).
const SDB_BASE: usize = if (old_hw) 0x10002000 else 0x20000000;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const bool_t = bool;
const calcRegister_t = i16;
const angularMode_t = c_int;
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const frontier_bufferize = @import("display/bufferize.zig"); // M-callconv: Zig-to-Zig
const frontier_error = @import("frontier_error.zig"); // M-callconv: Zig-to-Zig
const frontier_screen = @import("display/screen.zig"); // M-callconv: Zig-to-Zig
const frontier_softmenus = @import("display/softmenus/softmenus.zig"); // M-callconv: Zig-to-Zig
const frontier_timer = @import("frontier_timer.zig"); // M-callconv: Zig-to-Zig
const real34_t = abi.Real34;

const tamState_t = abi.TamState;

const softmenu_t = abi.Softmenu;
const softmenuStack_t = abi.SoftmenuStack;

const matrixHeader_t = abi.MatrixHeader;
// any34Matrix_t union { header; realMatrix{header; real34_t *elements}; ... }.
// The matrixElements pointer sits after the 4-byte header in both arms.
const real34Matrix_t = abi.Real34Matrix;
const complex34Matrix_t = abi.Complex34Matrix;

const font_t = abi.Font;

// ---------------------------------------------------------------------------
// Constants / enum values (verified against defines.h / typeDefinitions.h)
// ---------------------------------------------------------------------------
const CM_NORMAL: u8 = 0;
const CM_AIM: u8 = 1;
const CM_NIM: u8 = 2;
const CM_PEM: u8 = 3;
const CM_ASSIGN: u8 = 4;
const CM_MIM: u8 = 12;
const CM_ASN_BROWSER: u8 = 17;
const CM_EIM: u8 = 13;

const FLAG_ALPHA: c_uint = 0x800e;
const FLAG_NUMLOCK: c_uint = 0x8043;

const AC_UPPER: u8 = 0;
const CAPS_AIM_DEFAULT: u8 = AC_UPPER;
const CAPS_ASMcat_DEFAULT: u8 = AC_UPPER;
const NC_NORMAL: u8 = 0;

const AIM_REGISTER_LINE: calcRegister_t = 100; // REGISTER_X
const NIM_REGISTER_LINE: calcRegister_t = 100; // REGISTER_X
const ERR_REGISTER_LINE: calcRegister_t = 102; // REGISTER_Z
const REGISTER_X: calcRegister_t = 100;
const Y_POSITION_OF_AIM_LINE: u32 = 132;

const ERROR_RAM_FULL: u8 = 11;
const INVALID_VARIABLE: u16 = 2199;
const amNone: angularMode_t = 5;

const dtReal34Matrix: u32 = 6;
const dtComplex34Matrix: u32 = 7;

// menu IDs (items.h).
const MNU_ALPHA: i16 = 1922;
const MNU_FCNS: i16 = 1330;
const MNU_FCNS_EIM: i16 = 2228;
const MNU_CONST: i16 = 1322;
const MNU_MENU: i16 = 2407;
const MNU_MENUS: i16 = 1345;
const MNU_SYSFL: i16 = 1379;
const MNU_ALPHAINTL: i16 = 1374;
const MNU_ALPHAintl: i16 = 1384;
const MNU_PROG: i16 = 1392;
const MNU_PROGS: i16 = 1355;
const MNU_VAR: i16 = 1389;
const MNU_MATRS: i16 = 1343;
const MNU_STRINGS: i16 = 1364;
const MNU_DATES: i16 = 1325;
const MNU_TIMES: i16 = 1366;
const MNU_ANGLES: i16 = 1314;
const MNU_SINTS: i16 = 1332;
const MNU_LINTS: i16 = 1338;
const MNU_REALS: i16 = 1360;
const MNU_CPXS: i16 = 1324;
const MNU_CONFIGS: i16 = 2231;
const MNU_ALLVARS: i16 = 2232;
const MNU_NUMBRS: i16 = 2230;
const MNU_Solver: i16 = 1361;
const MNU_Grapher: i16 = 1388;
const MNU_Sf: i16 = 1380;
const MNU_1STDERIV: i16 = 1335;
const MNU_2NDDERIV: i16 = 1336;
const MNU_MVAR: i16 = 1398;

// catalog IDs (defines.h).
const CATALOG_NONE: i16 = 0;
const CATALOG_CNST: i16 = 1;
const CATALOG_FCNS: i16 = 2;
const CATALOG_MENU: i16 = 3;
const CATALOG_SYFL: i16 = 4;
const CATALOG_AINT: i16 = 5;
const CATALOG_aint: i16 = 6;
const CATALOG_PROG: i16 = 7;
const CATALOG_VAR: i16 = 8;
const CATALOG_MATRS: i16 = 9;
const CATALOG_STRINGS: i16 = 10;
const CATALOG_DATES: i16 = 11;
const CATALOG_TIMES: i16 = 12;
const CATALOG_ANGLES: i16 = 13;
const CATALOG_SINTS: i16 = 14;
const CATALOG_LINTS: i16 = 15;
const CATALOG_REALS: i16 = 16;
const CATALOG_CPXS: i16 = 17;
const CATALOG_MVAR: i16 = 18;
const CATALOG_CONFIGS: i16 = 19;
const CATALOG_ALLVARS: i16 = 20;
const CATALOG_NUMBRS: i16 = 21;
const CATALOG_FCNS_EIM: i16 = 22;

const STAT_PGM_END: u32 = 1 << 9;

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------
extern var calcMode: u8;
extern var previousCalcMode: u8;
extern var alphaCase: u8;
extern var nextChar: u8;
extern var scrLock: u8;
extern var cursorEnabled: u8;
extern var hexDigits: u8;
extern var lastErrorCode: u8;
extern var catalog: i16;
extern var xCursor: u32;
extern var yCursor: u32;
extern var matrixIndex: u16;
extern var tam: tamState_t;
extern var aimBuffer: [*c]u8;
extern var cursorFont: *const font_t;
const SOFTMENU_STACK_SIZE = 8;
extern var softmenuStack: [SOFTMENU_STACK_SIZE]softmenuStack_t;
extern var openMatrixMIMPointer: extern union {
    header: matrixHeader_t,
    realMatrix: real34Matrix_t,
    complexMatrix: complex34Matrix_t,
};

// softmenu[] is a C array; its symbol address is the table base.
const softmenu = @extern([*]const softmenu_t, .{ .name = "softmenu" });
extern const numericFont: font_t;
extern const standardFont: font_t;

// ---------------------------------------------------------------------------
// Function externs
// ---------------------------------------------------------------------------

extern fn clearSystemFlag(flag: c_uint) void;
extern fn setSystemFlag(flag: c_uint) void;
extern fn getSystemFlag(flag: c_int) bool_t;
extern fn liftStack() void;
extern fn saveForUndo() void;
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) [*]u8;
extern fn setRegisterTag(regist: calcRegister_t, tag: u32) void;

extern fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) void;

// decQuad real34SetZero(destination) -> decQuadZero(destination).
extern fn decQuadZero(r: *real34_t) *real34_t;

// GUI hooks. On DMCP_BUILD (and the no-keyboard simulator) these are empty
// macros in hal/gui.h, not linkable symbols; on the host sim/testSuite (with an
// on-screen keyboard) they are real functions. Call them only on the host;
// no-op on firmware to match the C macro expansion.
const VoidFn = *const fn () callconv(.c) void;
inline fn calcModeNormalGui() void {
    if (comptime !dmcp_build) @extern(VoidFn, .{ .name = "calcModeNormalGui" })();
}
inline fn calcModeAimGui() void {
    if (comptime !dmcp_build) @extern(VoidFn, .{ .name = "calcModeAimGui" })();
}
inline fn calcModeTamGui() void {
    if (comptime !dmcp_build) @extern(VoidFn, .{ .name = "calcModeTamGui" })();
}

// jm_show_comment is PC_BUILD-only (host). Referenced only under !dmcp_build.
extern fn jm_show_comment(comment: [*c]u8) void;

// PC-only matrix-free, saveCalc and gtk_main_quit — linkable on host, referenced
// only under !dmcp_build.
extern fn realMatrixFree(matrix: *real34Matrix_t) void;
extern fn complexMatrixFree(matrix: *complex34Matrix_t) void;
extern fn saveCalc() void;
extern fn gtk_main_quit() void;
extern var headlessMode: bool; // c47.c global; in --dumpMenus there is no GTK loop to quit

extern var shiftF: bool_t;
extern var shiftG: bool_t;

// ---------------------------------------------------------------------------
// Inline wrappers (the C macros)
// ---------------------------------------------------------------------------
const reg34 = abi.registerReal34Aligned;
inline fn real34SetZero(destination: *real34_t) void {
    _ = decQuadZero(destination);
}
inline fn setRegisterAngularMode(reg: calcRegister_t, am: angularMode_t) void {
    setRegisterTag(reg, @bitCast(am));
}

// SET_ST(STAT_PGM_END): set a bit in the fixed-address sdb.calc_state word.
inline fn setStatPgmEnd() void {
    const calc_state: *volatile u32 = @ptrFromInt(SDB_BASE);
    calc_state.* |= STAT_PGM_END;
}

// ===========================================================================
// fnOff
// ===========================================================================
pub export fn fnOff(unusedParamButMandatory: u16) callconv(.c) void {
    _ = unusedParamButMandatory;
    shiftF = false;
    shiftG = false;

    frontier_timer.fnStopTimerApp();

    if (comptime !dmcp_build) { // PC_BUILD
        if (matrixIndex != INVALID_VARIABLE) {
            if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
                if (openMatrixMIMPointer.realMatrix.matrixElements != null) {
                    realMatrixFree(&openMatrixMIMPointer.realMatrix);
                }
            } else if (getRegisterDataType(@bitCast(matrixIndex)) == dtComplex34Matrix) {
                if (openMatrixMIMPointer.complexMatrix.matrixElements != null) {
                    complexMatrixFree(&openMatrixMIMPointer.complexMatrix);
                }
            }
        }
        saveCalc();
        if (!headlessMode) {
            gtk_main_quit();
        }
    } else { // DMCP_BUILD
        setStatPgmEnd();
    }
}

// ===========================================================================
// calcModeNormal
// ===========================================================================
pub export fn calcModeNormal() callconv(.c) void {
    if (comptime !dmcp_build) {
        var tmp: [200]u8 = undefined;
        abi.fmtBufZ(&tmp, "^^^^### calcModeNormal", .{});
        jm_show_comment(&tmp);
    }
    calcMode = CM_NORMAL;
    if (softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem == -MNU_ALPHA) {
        frontier_softmenus.popSoftmenu();
    }

    if (softmenuStack[0].softmenuId == 1) { // MyAlpha
        softmenuStack[0].softmenuId = 0; // MyMenu
    }

    clearSystemFlag(FLAG_ALPHA);
    frontier_screen.hideCursor();
    cursorEnabled = 0;

    calcModeNormalGui();
}

// ===========================================================================
// calcModeAim
// ===========================================================================
pub export fn calcModeAim(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (comptime !dmcp_build) {
        var tmp: [200]u8 = undefined;
        abi.fmtBufZ(&tmp, "^^^^### calcModeAim", .{});
        jm_show_comment(&tmp);
    }

    alphaCase = CAPS_AIM_DEFAULT;
    nextChar = NC_NORMAL;
    clearSystemFlag(FLAG_NUMLOCK);
    scrLock = NC_NORMAL;

    if (tam.mode == 0 and calcMode != CM_ASSIGN and calcMode != CM_PEM and calcMode != CM_ASN_BROWSER) {
        calcMode = CM_AIM;
        liftStack();

        frontier_screen.clearRegisterLine(AIM_REGISTER_LINE, true, true);
        xCursor = 1;
        yCursor = Y_POSITION_OF_AIM_LINE + 6;
        cursorFont = &standardFont;
        cursorEnabled = 1;
    }

    if (tam.mode == 0) {
        frontier_softmenus.showSoftmenu(-MNU_ALPHA);
    }

    if (softmenuStack[0].softmenuId == 0) { // MyMenu
        softmenuStack[0].softmenuId = 1; // MyAlpha
    }

    setSystemFlag(FLAG_ALPHA);

    calcModeAimGui();
}

// ===========================================================================
// enterAsmModeIfMenuIsACatalog
// ===========================================================================
pub export fn enterAsmModeIfMenuIsACatalog(id: i16) callconv(.c) void {
    switch (-id) {
        MNU_FCNS => catalog = CATALOG_FCNS,
        MNU_FCNS_EIM => catalog = CATALOG_FCNS_EIM,
        MNU_CONST => catalog = CATALOG_CNST,
        MNU_MENU, MNU_MENUS => catalog = CATALOG_MENU,
        MNU_SYSFL => catalog = CATALOG_SYFL,
        MNU_ALPHAINTL => catalog = CATALOG_AINT,
        MNU_ALPHAintl => catalog = CATALOG_aint,
        MNU_PROG, MNU_PROGS => catalog = CATALOG_PROG,
        MNU_VAR => catalog = CATALOG_VAR,
        MNU_MATRS => catalog = CATALOG_MATRS,
        MNU_STRINGS => catalog = CATALOG_STRINGS,
        MNU_DATES => catalog = CATALOG_DATES,
        MNU_TIMES => catalog = CATALOG_TIMES,
        MNU_ANGLES => catalog = CATALOG_ANGLES,
        MNU_SINTS => catalog = CATALOG_SINTS,
        MNU_LINTS => catalog = CATALOG_LINTS,
        MNU_REALS => catalog = CATALOG_REALS,
        MNU_CPXS => catalog = CATALOG_CPXS,
        MNU_CONFIGS => catalog = CATALOG_CONFIGS,
        MNU_ALLVARS => catalog = CATALOG_ALLVARS,
        MNU_NUMBRS => catalog = CATALOG_NUMBRS,
        MNU_Solver, MNU_Grapher, MNU_Sf, MNU_1STDERIV, MNU_2NDDERIV, MNU_MVAR => catalog = CATALOG_MVAR,
        else => catalog = CATALOG_NONE,
    }
    if (comptime !dmcp_build) {
        var tmp: [200]u8 = undefined;
        abi.fmtBufZ(&tmp, "^^^^### enterAsmMode catalog={d}", .{@as(i32, catalog)});
        jm_show_comment(&tmp);
    }

    if (catalog != 0) {
        if (calcMode == CM_NIM) {
            frontier_bufferize.closeNim();
        }
        if (calcMode != CM_PEM or !getSystemFlag(FLAG_ALPHA)) {
            if (calcMode != CM_AIM and calcMode != CM_EIM) {
                alphaCase = CAPS_ASMcat_DEFAULT;
                nextChar = NC_NORMAL;
                clearSystemFlag(FLAG_NUMLOCK);
                scrLock = NC_NORMAL;
            }

            clearSystemFlag(FLAG_ALPHA);
            frontier_bufferize.resetAlphaSelectionBuffer();

            if (catalog != CATALOG_MVAR) {
                calcModeAimGui();
            }
        }
    }
}

// ===========================================================================
// leaveAsmMode
// ===========================================================================
pub export fn leaveAsmMode() callconv(.c) void {
    catalog = CATALOG_NONE;

    if (tam.mode != 0 and !tam.alpha) {
        calcModeTamGui();
    } else if (calcMode == CM_AIM or (tam.mode != 0 and tam.alpha)) {
        calcModeAimGui();
    } else if (calcMode == CM_NORMAL or calcMode == CM_PEM or calcMode == CM_MIM or calcMode == CM_ASSIGN) {
        calcModeNormalGui();
    }
}

// ===========================================================================
// calcModeNim
// ===========================================================================
pub export fn calcModeNim(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (comptime !dmcp_build) {
        var tmp: [200]u8 = undefined;
        abi.fmtBufZ(&tmp, "^^^^### calcModeNim", .{});
        jm_show_comment(&tmp);
    }
    saveForUndo();
    if (lastErrorCode == ERROR_RAM_FULL) {
        frontier_error.displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        if (comptime !dmcp_build) {
            moreInfoOnError("In function calcModeNim:", "there is not enough memory to save for undo!", null, null);
        }
        return;
    }

    calcMode = CM_NIM;
    clearSystemFlag(FLAG_ALPHA);

    liftStack();
    real34SetZero(reg34(REGISTER_X));
    setRegisterAngularMode(REGISTER_X, amNone);

    aimBuffer[0] = 0;
    hexDigits = 0;

    if (!checkHP()) {
        frontier_screen.clearRegisterLine(NIM_REGISTER_LINE, true, true);
    }
    xCursor = 1;
    cursorEnabled = 1;
    cursorFont = &numericFont;
}

// ---------------------------------------------------------------------------
// checkHP macro (defines.h:2225):
// (significantDigits <= 16 && displayStack == 1 && exponentLimit == 99 &&
//  Input_Default == ID_DP && (calcMode == CM_NORMAL || calcMode == CM_NIM))
// ---------------------------------------------------------------------------
extern var significantDigits: u8;
extern var displayStack: u8;
extern var exponentLimit: i16;
extern var Input_Default: u8;
const ID_DP: u8 = 2;
inline fn checkHP() bool {
    return significantDigits <= 16 and displayStack == 1 and exponentLimit == 99 and Input_Default == ID_DP and (calcMode == CM_NORMAL or calcMode == CM_NIM);
}

extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;
