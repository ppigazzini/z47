const runtime = @import("frontier_runtime.zig");

const DSP_MAX: u16 = 19;
const FLAG_FRACT: c_uint = 0x8007;
const FLAG_PROPFR: c_uint = 0x8008;
const FLAG_TRACE: c_uint = 0x8013;
const FLAG_PRTACT: c_uint = 0xc020;
const FLAG_INTING: c_uint = 0xc025;
const FLAG_SOLVING: c_uint = 0xc026;
const FLAG_FRCYC: c_uint = 0x8041;
const FLAG_IRFRAC: c_uint = 0x8047;
const FLAG_IRFRQ: c_uint = 0xc048;
const FLAG_PRTEN: u16 = 0x8067;
const FLAG_NORM: u16 = 0x8068;

const SETTING_AMODE: c_int = 0x0080;
const SETTING_SINT_MODE: c_int = 0x0083;

const TI_VERSION: u8 = 10;
const TI_WHO: u8 = 11;

const MNU_GAP_L: i16 = 2151;
const MNU_GAP_RX: i16 = 2152;
const MNU_GAP_R: i16 = 2153;

const PROFF: u16 = 0;
const PRON: u16 = 1;
const MAN: u16 = 0;
const NORM: u16 = 1;
const TRACE: u16 = 2;
const STRACE: u16 = 3;

const PRINT_BYTE: c_int = 0;
const PRINT_CHAR: c_int = 1;
const PRINT_TAB: c_int = 2;

const DF_DMX_MIN: i16 = 99;
const DF_HIDE_MIN: i16 = 12;

const DF_ALL: u8 = 0;
const DF_FIX: u8 = 1;
const DF_SCI: u8 = 2;
const DF_ENG: u8 = 3;
const DF_SF: u8 = 4;
const DF_UN: u8 = 5;

extern var displayFormat: u8;
extern var displayFormatDigits: u8;
extern var timeDisplayFormatDigits: u8;
extern var DM_Cycling: u8;
extern var gapItemLeft: u16;
extern var gapItemRight: u16;
extern var gapItemRadix: u16;
extern var grpGroupingLeft: u8;
extern var grpGroupingGr1LeftOverflow: u8;
extern var grpGroupingGr1Left: u8;
extern var grpGroupingRight: u8;
extern var shortIntegerMode: u8;
extern var temporaryInformation: u8;
extern var roundingMode: u8;
extern var significantDigits: u8;
extern var dispBase: u8;
extern var fractionDigits: u8;
extern var currentAngularMode: c_int;
extern var exponentLimit: i16;
extern var exponentHideLimit: i16;

const PrinterState = extern struct {
    print_on: bool,
    trace_done: bool,
    print_blank_line: u8,
    print_mode: c_int,
    printer_model: c_int,
    delay: u16,
};

extern var printerState: PrinterState;

extern fn clearSystemFlag(sf: c_uint) void;
extern fn setSystemFlag(sf: c_uint) void;
extern fn getSystemFlag(sf: c_int) bool;
extern fn flipSystemFlag(sf: c_uint) void;
extern fn setSystemFlagChanged(sf: c_int) void;
extern fn fnSetFlag(flag: u16) void;
extern fn fnClearFlag(flag: u16) void;
extern fn fnRefreshState() void;
extern fn showSoftmenu(menu: i16) void;
extern fn setLineDelay(delay: u16) void;
extern fn print_lf() void;
extern fn printProgram(list: bool, lines: u16) void;
extern fn cmdPrint(arg: u16, op: c_int) void;
extern fn z47_frontier_print_set_printer_sbi(status: bool) void;
extern fn z47_frontier_print_get_unicode_value(regist: i16) u16;

fn clampDisplayDigits(display_format_n: u16) u8 {
    const clamped: u16 = if (display_format_n > DSP_MAX) DSP_MAX else display_format_n;
    return @as(u8, @intCast(clamped));
}

fn displayFormatReset(display_format_n: u16) void {
    displayFormatDigits = clampDisplayDigits(display_format_n);
    clearSystemFlag(FLAG_FRACT);
    DM_Cycling = 0;
}

pub export fn fnSNAP(unused_but_mandatory_parameter: u16) callconv(.c) void {
    runtime.z47_frontier_retained_fnSNAP(unused_but_mandatory_parameter);
}

pub export fn fnDisplayFormatFix(display_format_n: u16) callconv(.c) void {
    displayFormatReset(display_format_n);
    displayFormat = DF_FIX;
    fnRefreshState();
}

pub export fn fnDisplayFormatSci(display_format_n: u16) callconv(.c) void {
    displayFormatReset(display_format_n);
    displayFormat = DF_SCI;
    fnRefreshState();
}

pub export fn fnDisplayFormatEng(display_format_n: u16) callconv(.c) void {
    displayFormatReset(display_format_n);
    displayFormat = DF_ENG;
    fnRefreshState();
}

pub export fn fnDisplayFormatAll(display_format_n: u16) callconv(.c) void {
    displayFormatReset(display_format_n);
    displayFormat = DF_ALL;
    fnRefreshState();
}

pub export fn fnDisplayFormatSigFig(display_format_n: u16) callconv(.c) void {
    displayFormatReset(display_format_n);
    displayFormat = DF_SF;
    fnRefreshState();
}

pub export fn fnDisplayFormatUnit(display_format_n: u16) callconv(.c) void {
    displayFormatReset(display_format_n);
    displayFormat = DF_UN;
    fnRefreshState();
}

pub export fn fnDisplayFormatDsp(display_format_n: u16) callconv(.c) void {
    displayFormatDigits = clampDisplayDigits(display_format_n);
    clearSystemFlag(FLAG_FRACT);
    fnRefreshState();
}

pub export fn fnDisplayFormatTime(display_format_n: u16) callconv(.c) void {
    timeDisplayFormatDigits = clampDisplayDigits(display_format_n);
}

pub export fn fnDynamicMenu(unused_but_mandatory_parameter: u16) callconv(.c) void {
    runtime.z47_frontier_retained_fnDynamicMenu(unused_but_mandatory_parameter);
}

pub export fn fnNop(unused_but_mandatory_parameter: u16) callconv(.c) void {
    runtime.z47_frontier_retained_fnNop(unused_but_mandatory_parameter);
}

pub export fn fnCFGsettings(unused_but_mandatory_parameter: u16) callconv(.c) void {
    runtime.z47_frontier_retained_fnCFGsettings(unused_but_mandatory_parameter);
}

pub export fn fnP_PrinterOnOff(op: u16) callconv(.c) void {
    if (op == PRON) {
        printerState.print_on = true;
        setSystemFlag(FLAG_PRTACT);
        fnSetFlag(FLAG_PRTEN);
    } else if (op == PROFF) {
        printerState.print_on = false;
        clearSystemFlag(FLAG_PRTACT);
        fnClearFlag(FLAG_PRTEN);
    }
}

pub export fn fnP_PrinterMode(mode: u16) callconv(.c) void {
    if (mode == MAN) {
        fnClearFlag(FLAG_NORM);
        fnClearFlag(@as(u16, @intCast(FLAG_TRACE)));
    } else if (mode == NORM) {
        fnSetFlag(FLAG_NORM);
        fnClearFlag(@as(u16, @intCast(FLAG_TRACE)));
    } else if (mode == TRACE) {
        fnClearFlag(FLAG_NORM);
        fnSetFlag(@as(u16, @intCast(FLAG_TRACE)));
    } else if (mode == STRACE) {
        fnSetFlag(FLAG_NORM);
        fnSetFlag(@as(u16, @intCast(FLAG_TRACE)));
    }
}

pub export fn fnSetPrinter(model: u16) callconv(.c) void {
    printerState.printer_model = @as(c_int, @intCast(model));
}

pub export fn fnP_SetDelay(delay: u16) callconv(.c) void {
    printerState.delay = delay;
    setLineDelay(delay);
}

pub export fn fnP_Advance(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    z47_frontier_print_set_printer_sbi(true);
    print_lf();
    z47_frontier_print_set_printer_sbi(false);
}

pub export fn fnP_PrinterList(lines: u16) callconv(.c) void {
    printProgram(true, lines);
}

pub export fn fnP_Byte(byte: u16) callconv(.c) void {
    z47_frontier_print_set_printer_sbi(true);
    cmdPrint(byte, PRINT_BYTE);
    z47_frontier_print_set_printer_sbi(false);
}

pub export fn fnP_Char(register_no: u16) callconv(.c) void {
    z47_frontier_print_set_printer_sbi(true);
    const character = z47_frontier_print_get_unicode_value(@as(i16, @intCast(register_no)));
    cmdPrint(character, PRINT_CHAR);
    z47_frontier_print_set_printer_sbi(false);
}

pub export fn fnP_Tab(column: u16) callconv(.c) void {
    z47_frontier_print_set_printer_sbi(true);
    cmdPrint(column, PRINT_TAB);
    z47_frontier_print_set_printer_sbi(false);
}

pub export fn fnP_LCD(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    if (getSystemFlag(@as(c_int, @intCast(FLAG_PRTACT)))) {
        return;
    }
    fnSNAP(9876);
}

pub export fn fnSetGapChar(char_param: u16) callconv(.c) void {
    const group = char_param & 49152;
    const value = char_param & 16383;
    if (group == 0) {
        gapItemLeft = value;
    } else if (group == 32768) {
        gapItemRight = value;
    } else if (group == 49152) {
        gapItemRadix = value;
    }
}

pub export fn fnSettingsDispFormatGrpL(param: u16) callconv(.c) void {
    grpGroupingLeft = @as(u8, @intCast(param));
}

pub export fn fnSettingsDispFormatGrp1Lo(param: u16) callconv(.c) void {
    grpGroupingGr1LeftOverflow = @as(u8, @intCast(param));
}

pub export fn fnSettingsDispFormatGrp1L(param: u16) callconv(.c) void {
    grpGroupingGr1Left = @as(u8, @intCast(param));
}

pub export fn fnSettingsDispFormatGrpR(param: u16) callconv(.c) void {
    grpGroupingRight = @as(u8, @intCast(param));
}

pub export fn fnMenuGapL(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    showSoftmenu(-MNU_GAP_L);
}

pub export fn fnMenuGapRX(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    showSoftmenu(-MNU_GAP_RX);
}

pub export fn fnMenuGapR(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    showSoftmenu(-MNU_GAP_R);
}

pub export fn fnIntegerMode(mode: u16) callconv(.c) void {
    if (shortIntegerMode != @as(u8, @intCast(mode))) {
        setSystemFlagChanged(SETTING_SINT_MODE);
    }
    shortIntegerMode = @as(u8, @intCast(mode));
    fnRefreshState();
}

pub export fn fnWho(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    temporaryInformation = TI_WHO;
}

pub export fn fnVersion(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    temporaryInformation = TI_VERSION;
}

pub export fn fnSetRoundingMode(rm: u16) callconv(.c) void {
    roundingMode = @as(u8, @intCast(rm));
}

pub export fn fnSetSignificantDigits(s: u16) callconv(.c) void {
    significantDigits = @as(u8, @intCast(s));
    if (significantDigits == 0) {
        significantDigits = 34;
    }
}

pub export fn fnSetBaseNr(s: u16) callconv(.c) void {
    dispBase = @as(u8, @intCast(s));
    if (dispBase == 1) {
        dispBase = 0;
    }
}

pub export fn fnSetFractionDigits(s: u16) callconv(.c) void {
    fractionDigits = @as(u8, @intCast(s));
    if (fractionDigits == 0) {
        fractionDigits = 34;
    }
}

pub export fn fnAngularMode(am: u16) callconv(.c) void {
    if (currentAngularMode != @as(c_int, @intCast(am))) {
        setSystemFlagChanged(SETTING_AMODE);
    }
    currentAngularMode = @as(c_int, @intCast(am));
    fnRefreshState();
}

pub export fn fnFractionType(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    var state: u8 = 0;
    if (getSystemFlag(@as(c_int, @intCast(FLAG_IRFRAC)))) state += 8;
    if (getSystemFlag(@as(c_int, @intCast(FLAG_IRFRQ)))) state += 4;
    if (getSystemFlag(@as(c_int, @intCast(FLAG_PROPFR)))) state += 2;
    if (getSystemFlag(@as(c_int, @intCast(FLAG_FRACT)))) state += 1;

    if (getSystemFlag(@as(c_int, @intCast(FLAG_FRCYC)))) {
        state = switch (state) {
            0b0000 => 0b0001,
            0b0010 => 0b0011,
            0b0100 => 0b1100,
            0b0110 => 0b1110,
            0b0001 => 0b1110,
            0b0011 => 0b0001,
            0b1100 => 0b0011,
            0b1110 => 0b1100,
            else => 0b0011,
        };

        if ((state & 8) != 0) setSystemFlag(FLAG_IRFRAC) else clearSystemFlag(FLAG_IRFRAC);
        if ((state & 4) != 0) setSystemFlag(FLAG_IRFRQ) else clearSystemFlag(FLAG_IRFRQ);
        if ((state & 2) != 0) setSystemFlag(FLAG_PROPFR) else clearSystemFlag(FLAG_PROPFR);
        if ((state & 1) != 0) setSystemFlag(FLAG_FRACT) else clearSystemFlag(FLAG_FRACT);
    } else {
        if (getSystemFlag(@as(c_int, @intCast(FLAG_IRFRQ)))) {
            flipSystemFlag(FLAG_IRFRAC);
        } else {
            flipSystemFlag(FLAG_FRACT);
        }
    }
}

pub export fn fnRange(r: u16) callconv(.c) void {
    exponentLimit = @as(i16, @intCast(r));
    if (exponentLimit < DF_DMX_MIN) {
        exponentLimit = DF_DMX_MIN;
    }
}

pub export fn fnHide(h: u16) callconv(.c) void {
    exponentHideLimit = @as(i16, @intCast(h));
    if (exponentHideLimit > 0 and exponentHideLimit < DF_HIDE_MIN) {
        exponentHideLimit = DF_HIDE_MIN;
    }
}

pub export fn fnKeysManagement(choice: u16) callconv(.c) void {
    runtime.z47_frontier_retained_fnKeysManagement(choice);
}

pub export fn fnPlotStat(plot_mode: u16) callconv(.c) void {
    runtime.z47_frontier_retained_fnPlotStat(plot_mode);
}

pub export fn fnEditMatrix(regist: u16) callconv(.c) void {
    runtime.z47_frontier_retained_fnEditMatrix(regist);
}

pub export fn fnClPAll(confirmation: u16) callconv(.c) void {
    runtime.z47_frontier_retained_fnClPAll(confirmation);
}