// Zig port of src/c47-gtk/c47-gtk.c -- the GTK desktop simulator entry point
// (PC_BUILD). Owns the program globals that c47-gtk.c defined and the main()
// that parses CLI args, seeds the calc model, runs the UI startup (the Zig
// z47_startup_* helpers), restores the saved state, configures the foreground
// timers, and enters the GTK main loop. Retires zig_build/host/gtk_c47_gtk_legacy.c.
const std = @import("std");
const builtin = @import("builtin");
const opts = @import("host_gtk_options");

// --- GTK key-image descriptor (typeDefinitions.h, PC_BUILD) ----------------
const calcKeyboard_t = extern struct {
    x: c_int,
    y: c_int,
    width: [4]c_int,
    height: [4]c_int,
    keyImage: [4]?*anyopaque,
};

// --- program globals (defined here; other units extern-declare them) -------
pub export var modelString: [50]u8 = [_]u8{0} ** 50;
pub export var mockup: bool = false;
pub export var dumpMenus: u16 = 0;
pub export var writeExportAll: bool = false;
pub export var config: u8 = 0;
pub export var enableFunctionKeysDisplay: bool = false;
pub export var calcLandscape: bool = false;
pub export var calcAutoLandscapePortrait: bool = true;
pub export var screen: ?*anyopaque = null;
pub export var frmCalc: ?*anyopaque = null;
pub export var screenStride: i16 = 0;
pub export var screenData: ?[*]u32 = null;
pub export var screenChange: bool = false;
pub export var calcKeyboard: [43]calcKeyboard_t = std.mem.zeroes([43]calcKeyboard_t);
pub export var currentBezel: c_int = 0;
pub export var resetKeys: bool = false;
pub export var calcModelNew: u8 = 255;

// --- calc-model constants (defines.h) --------------------------------------
const USER_C47: u8 = 46;
const USER_R47: u8 = 66;
const USER_R47f_g: u8 = 61;
const USER_R47bk_fg: u8 = 62;
const USER_R47fg_bk: u8 = 63;
const USER_R47fg_g: u8 = 64;
const USER_E47: u8 = 43;
const USER_N47: u8 = 51;
const USER_V47: u8 = 40;
const USER_D47: u8 = 47;
const USER_DM42: u8 = 45;

const CALCMODEL: u8 = opts.calcmodel;
const FLAG_USER: u16 = 0x8014;
const FLAG_AUTXEQ: u16 = 0x801f;
const NOPARAM: u16 = 9876;
const CONFIRMED: u16 = 9877;
const ITM_RS: i16 = 1725;
const ITM_RIBBON_R47: u16 = 2511;
const ITM_RIBBON_C47: u16 = 2509;
const SCREEN_REFRESH_PERIOD: c_uint = 160;
const TO_FG_LONG: u8 = 0;
const TO_CL_LONG: u8 = 1;
const TO_FG_TIMR: u8 = 2;
const TO_FN_LONG: u8 = 3;
const TO_FN_EXEC: u8 = 4;
const TO_3S_CTFF: u8 = 5;
const TO_CL_DROP: u8 = 6;
const TO_TIMER_APP: u8 = 8;
const TO_ASM_ACTIVE: u8 = 9;
const PGM_RUNNING: u8 = 1;
const SCRUPD_AUTO: u8 = 0;

// --- external state (defined elsewhere) ------------------------------------
extern var calcModel: u8;
extern var c47MemInBlocks: usize;
extern var gmpMemInBytes: usize;
extern var programRunStop: u8;
extern var screenUpdatingMode: u8;

// --- external functions ----------------------------------------------------
const TimerFn = ?*const fn (u16) callconv(.c) void;
const GSourceFunc = ?*const fn (?*anyopaque) callconv(.c) c_int;

extern fn z47_startup_init_ui(argc: *c_int, argv: [*]?[*:0]u8) void;
extern fn z47_startup_enter_mainloop() void;
extern fn restoreCalc() void;
extern fn fnRESET_MyM(param: u16) void;
extern fn fnKeysManagement(choice: u16) void;
extern fn fnRefreshState() void;
extern fn calcModeNormal() void;
extern fn clearSystemFlag(flag: u16) void;
extern fn getSystemFlag(flag: u16) bool;
extern fn fnClrMod(param: u16) void;
extern fn fnSetJM(param: u16) void;
extern fn fnSetRJ(param: u16) void;
extern fn fnSetHP35(param: u16) void;
extern fn fnReset(confirmation: u16) void;
extern fn fnSaveAllPrograms(param: u16) void;
extern fn mockupSB() void;
extern fn fnScreenDump(param: u16) void;
extern fn fnDumpMenus(param: u16) void;
extern fn refreshScreen(source: u16) void;
extern fn refreshFn(timerType: u16) void;
extern fn fnTimerReset() void;
extern fn fnTimerConfig(nr: u8, func: TimerFn, param: u16) void;
extern fn runFunction(func: i16) void;
extern fn refreshLcd(data: ?*anyopaque) callconv(.c) c_int;
extern fn refreshTimer(data: ?*anyopaque) callconv(.c) c_int;
extern fn execFnTimeout(key: u16) void;
extern fn shiftCutoff(param: u16) void;
extern fn fnTimerDummy1(param: u16) void;
extern fn execTimerApp(timerType: u16) void;
extern fn gdk_threads_add_timeout(interval: c_uint, function: GSourceFunc, data: ?*anyopaque) c_uint;
extern fn __gmp_set_memory_functions(
    alloc_fn: *const fn (usize) callconv(.c) ?*anyopaque,
    realloc_fn: *const fn (?*anyopaque, usize, usize) callconv(.c) ?*anyopaque,
    free_fn: *const fn (?*anyopaque, usize) callconv(.c) void,
) void;

// clearScreen is a screen.h macro -> lcd_fill_rect + forceSBupdate.
const LcdFillRectFn = *const fn (x: u32, y: u32, dx: u32, dy: u32, val: c_int) callconv(.c) void;
const c_lcd_fill_rect = @extern(LcdFillRectFn, .{ .name = "lcd_fill_rect" });
extern fn forceSBupdate() void;
const SCREEN_WIDTH: u32 = 400;
const LCD_SET_VALUE: c_int = 0;
fn clearScreen(cnt: u16) void {
    _ = cnt;
    c_lcd_fill_rect(0, 0, SCREEN_WIDTH, 240, LCD_SET_VALUE);
    forceSBupdate();
}
extern fn allocGmp(size: usize) callconv(.c) ?*anyopaque;
extern fn reallocGmp(ptr: ?*anyopaque, old_size: usize, new_size: usize) callconv(.c) ?*anyopaque;
extern fn freeGmp(ptr: ?*anyopaque, size: usize) callconv(.c) void;
extern fn printf(format: [*:0]const u8, ...) c_int;
extern fn chdir(path: [*:0]const u8) c_int;

// isR47FAM (defines.h macro): the R47 family of layouts.
inline fn isR47FAM() bool {
    return calcModel == USER_R47f_g or calcModel == USER_R47bk_fg or
        calcModel == USER_R47fg_bk or calcModel == USER_R47fg_g;
}

inline fn argEql(arg: [*:0]u8, lit: [:0]const u8) bool {
    return std.mem.eql(u8, std.mem.span(arg), lit);
}

fn printHelp() void {
    const cc: [*:0]const u8 = if (CALCMODEL == USER_R47) "r" else "c";
    const modeltext: [*:0]const u8 = if (CALCMODEL == USER_R47) "R47" else "C47";
    _ = printf("\n-------------------------------------------------------------\n");
    _ = printf("%s Sim " ++ opts.version1 ++ ", SHA " ++ opts.vcs_commit_id ++ ".\n", modeltext);
    _ = printf("C47/R47 info to be found on 47calc.com\n");
    _ = printf("C47/R47 license GPL3, details on 47calc.com\n\n");
    _ = printf("%s47 --background     : specify background picture\n", cc);
    _ = printf("%s47 --functionkeys   : display function key labels\n\n", cc);
    _ = printf("%s47 --landscape      : landscape orientation\n", cc);
    _ = printf("%s47 --portrait       : portrait orientation\n", cc);
    _ = printf("%s47 --auto           : automatic orientation\n\n", cc);
    _ = printf("%s47 --c47            : C47\n", cc);
    _ = printf("%s47 --r47            : R47v0 layout (f g)\n", cc);
    _ = printf("%s47 --r47v0          : R47v0 layout (f g)\n", cc);
    _ = printf("%s47 --r47v1          : R47v1 layout (fg bk)\n", cc);
    _ = printf("%s47 --r47v2          : R47v2 layout (fg g)\n", cc);
    _ = printf("%s47 --r47v3          : R47v3 layout (bk fg) \n", cc);
    _ = printf("%s47 --dm42           : DM42 layout\n", cc);
    _ = printf("%s47 --e47            : E47 layout (SIM only) (sunsetting)\n", cc);
    _ = printf("%s47 --n47            : N47 layout (SIM only) (sunsetting)\n", cc);
    _ = printf("%s47 --v47            : V47 layout (SIM only) (sunsetting)\n", cc);
    _ = printf("%s47 --d47            : D47 layout (SIM only) (sunsetting)\n\n", cc);
    _ = printf("%s47 --jm             : Setting profile: Jaco preferences\n", cc);
    _ = printf("%s47 --rj             : Setting profile: RJvM preferences\n", cc);
    _ = printf("%s47 --hp35           : Setting profile: HP-35 tribute\n\n", cc);
    _ = printf("%s47 --deadkeys       : typewriter style dead keys\n", cc);
    _ = printf("%s47 --swapctrlcode   : ctrl fix for Swiss keyboards\n", cc);
    _ = printf("%s47 --mockup         : output demo status bar layout\n", cc);
    _ = printf("%s47 --dumpMenus1     : output all static menus to drive; old file name format in the form 'Menu_140_p1_RIBBONS.bmp'\n", cc);
    _ = printf("%s47 --dumpMenus2     : output all static menus to drive; new file name format in the form 'RIBBONS.1.bmp'\n", cc);
    _ = printf("%s47 --writeexportall : output all PROGs (internal use)\n", cc);
    _ = printf("%s47 --help           : list all SIM switches\n", cc);
    _ = printf("%s47 --h              : see --help\n", cc);
}

pub export fn main(argc: c_int, argv: [*][*:0]u8) callconv(.c) c_int {
    if (builtin.os.tag == .macos) {
        // The macOS app bundle sets the working directory to the executable dir.
        if (argc >= 1) {
            const a0 = std.mem.span(argv[0]);
            if (std.mem.lastIndexOfScalar(u8, a0, '/')) |idx| {
                var buf: [1024]u8 = undefined;
                if (idx < buf.len) {
                    @memcpy(buf[0..idx], a0[0..idx]);
                    buf[idx] = 0;
                    _ = chdir(@ptrCast(&buf));
                }
            }
        }
    }

    c47MemInBlocks = 0;
    gmpMemInBytes = 0;
    __gmp_set_memory_functions(&allocGmp, &reallocGmp, &freeGmp);

    modelString[0] = 0;
    calcLandscape = false;
    calcAutoLandscapePortrait = true;

    var arg: usize = 1;
    while (arg < @as(usize, @intCast(argc))) : (arg += 1) {
        if (argEql(argv[arg], "--background")) {
            _ = printf("Activated: %s\n", argv[arg]);
            if (arg + 1 < @as(usize, @intCast(argc)) and argv[arg + 1][0] != 0) {
                arg += 1;
                _ = std.fmt.bufPrintZ(&modelString, "{s}", .{std.mem.span(argv[arg])}) catch {};
                if (arg + 1 < @as(usize, @intCast(argc)) and argv[arg + 1][0] != 0) {
                    arg += 1;
                } else break;
            }
        }
        if (argEql(argv[arg], "--functionkeys")) {
            enableFunctionKeysDisplay = true;
            _ = printf("Activated: %s\n", argv[arg]);
        } else {
            enableFunctionKeysDisplay = false;
        }
        if (argEql(argv[arg], "--landscape")) {
            calcLandscape = true;
            calcAutoLandscapePortrait = false;
            _ = printf("Activated: %s\n", argv[arg]);
        }
        if (argEql(argv[arg], "--portrait")) {
            calcLandscape = false;
            calcAutoLandscapePortrait = false;
            _ = printf("Activated: %s\n", argv[arg]);
        }
        if (argEql(argv[arg], "--auto")) {
            calcLandscape = false;
            calcAutoLandscapePortrait = true;
            _ = printf("Activated: %s\n", argv[arg]);
        }
        if (argEql(argv[arg], "--c47")) {
            calcModelNew = USER_C47;
            _ = printf("Activated: %s\n", argv[arg]);
        }
        if (argEql(argv[arg], "--r47")) {
            calcModelNew = USER_R47f_g;
            _ = printf("Activated: %s\n", argv[arg]);
        }
        if (argEql(argv[arg], "--r47v0")) {
            calcModelNew = USER_R47f_g;
            _ = printf("Activated: %s\n", argv[arg]);
        }
        if (argEql(argv[arg], "--r47v1")) {
            calcModelNew = USER_R47fg_bk;
            _ = printf("Activated: %s\n", argv[arg]);
        }
        if (argEql(argv[arg], "--r47v2")) {
            calcModelNew = USER_R47fg_g;
            _ = printf("Activated: %s\n", argv[arg]);
        }
        if (argEql(argv[arg], "--r47v3")) {
            calcModelNew = USER_R47bk_fg;
            _ = printf("Activated: %s\n", argv[arg]);
        }
        if (argEql(argv[arg], "--e47")) {
            calcModelNew = USER_E47;
            _ = printf("Activated: %s\n", argv[arg]);
        }
        if (argEql(argv[arg], "--n47")) {
            calcModelNew = USER_N47;
            _ = printf("Activated: %s\n", argv[arg]);
        }
        if (argEql(argv[arg], "--v47")) {
            calcModelNew = USER_V47;
            _ = printf("Activated: %s\n", argv[arg]);
        }
        if (argEql(argv[arg], "--d47")) {
            calcModelNew = USER_D47;
            _ = printf("Activated: %s\n", argv[arg]);
        }
        if (argEql(argv[arg], "--dm42")) {
            calcModelNew = USER_DM42;
            _ = printf("Activated: %s\n", argv[arg]);
        }
        if (argEql(argv[arg], "--jm")) {
            config = 1;
            _ = printf("Activated: %s\n", argv[arg]);
        }
        if (argEql(argv[arg], "--rj")) {
            config = 2;
            _ = printf("Activated: %s\n", argv[arg]);
        }
        if (argEql(argv[arg], "--hp35")) {
            config = 3;
            _ = printf("Activated: %s\n", argv[arg]);
        }
        if (argEql(argv[arg], "--deadkeys")) {
            testDeadKeys = true;
            _ = printf("Activated: %s\n", argv[arg]);
        }
        if (argEql(argv[arg], "--swapctrlcode")) {
            swapCtrlCode = true;
            _ = printf("Activated: %s\n", argv[arg]);
        }
        if (argEql(argv[arg], "--writeexportall")) {
            _ = printf("Activated: %s\n", argv[arg]);
            writeExportAll = true;
        }
        if (argEql(argv[arg], "--mockup")) {
            _ = printf("Activated: %s\n", argv[arg]);
            mockup = true;
        }
        if (argEql(argv[arg], "--dumpMenus1")) {
            _ = printf("Activated: %s\n", argv[arg]);
            dumpMenus = 1;
        }
        if (argEql(argv[arg], "--dumpMenus2")) {
            _ = printf("Activated: %s\n", argv[arg]);
            dumpMenus = 2;
        }
        if (argEql(argv[arg], "--help") or argEql(argv[arg], "--h") or argEql(argv[arg], "-h")) {
            printHelp();
            _ = printf("Activated: %s\n\n", argv[arg]);
            return 0;
        }
    }

    // Set the R47/C47 mode for initial startup; honour a command-line override.
    if (calcModel == USER_R47) {
        calcModel = USER_R47f_g;
    }
    if (calcModelNew != 255) {
        calcModel = calcModelNew;
        _ = printf("calcModel A re-set to %d\n", @as(c_int, calcModelNew));
    }

    z47_startup_init_ui(@constCast(&argc), @ptrCast(@constCast(&argv)));

    restoreCalc();

    if (calcModelNew != 255) {
        calcModel = calcModelNew;
        _ = printf("calcModel B re-set to %d\n", @as(c_int, calcModelNew));
        resetKeys = true;
    }
    if (CALCMODEL == USER_R47) {
        if (!isR47FAM()) {
            fnRESET_MyM(ITM_RIBBON_R47);
            _ = printf("Restoring ribbon to R47 due to calculator model change.\n");
            resetKeys = true;
        }
    }
    if (CALCMODEL == USER_C47) {
        if (calcModel != USER_C47) {
            fnRESET_MyM(ITM_RIBBON_C47);
            _ = printf("Restoring ribbon to C47 due to calculator model change.\n");
            resetKeys = true;
        }
    }
    if (calcModelNew != 255) {
        _ = printf("ClrMod due to calculator model change.\n");
        clearSystemFlag(FLAG_USER);
        fnClrMod(NOPARAM);
        calcModeNormal();
    }
    if (resetKeys) {
        _ = printf("Resetting keys due to incompatible layout.\n");
        fnKeysManagement(calcModel);
        fnRefreshState();
        calcModeNormal();
    }

    switch (config) {
        1 => fnSetJM(0),
        2 => fnSetRJ(0),
        3 => fnSetHP35(0),
        else => {},
    }

    if (writeExportAll) {
        fnReset(CONFIRMED);
        fnSaveAllPrograms(NOPARAM);
        return 0;
    }

    if (mockup) {
        fnReset(CONFIRMED);
        clearScreen(120);
        mockupSB();
        fnScreenDump(NOPARAM);
        _ = printf("\n\nOutput file saved.\n\n");
        return 0;
    }

    if (dumpMenus > 0) {
        fnReset(CONFIRMED);
        clearScreen(121);
        fnDumpMenus(dumpMenus);
        _ = printf("\n\nOutput menus saved.\n");
        return 0;
    }

    refreshScreen(190);

    _ = gdk_threads_add_timeout(SCREEN_REFRESH_PERIOD, &refreshLcd, null);
    fnTimerReset();
    fnTimerConfig(TO_FG_LONG, &refreshFn, TO_FG_LONG);
    fnTimerConfig(TO_CL_LONG, &refreshFn, TO_CL_LONG);
    fnTimerConfig(TO_FG_TIMR, &refreshFn, TO_FG_TIMR);
    fnTimerConfig(TO_FN_LONG, &refreshFn, TO_FN_LONG);
    fnTimerConfig(TO_FN_EXEC, &execFnTimeout, 0);
    fnTimerConfig(TO_3S_CTFF, &shiftCutoff, TO_3S_CTFF);
    fnTimerConfig(TO_CL_DROP, &fnTimerDummy1, TO_CL_DROP);
    fnTimerConfig(TO_TIMER_APP, &execTimerApp, 0);
    fnTimerConfig(TO_ASM_ACTIVE, &refreshFn, TO_ASM_ACTIVE);
    _ = gdk_threads_add_timeout(5, &refreshTimer, null);

    if (getSystemFlag(FLAG_AUTXEQ)) {
        clearSystemFlag(FLAG_AUTXEQ);
        if (programRunStop != PGM_RUNNING) {
            screenUpdatingMode = SCRUPD_AUTO;
            runFunction(ITM_RS);
        }
        refreshScreen(191);
    }

    z47_startup_enter_mainloop();
    return 0;
}

extern var testDeadKeys: bool;
extern var swapCtrlCode: bool;
