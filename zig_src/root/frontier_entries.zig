const runtime = @import("frontier_runtime.zig");

const DSP_MAX: u16 = 19;
const FLAG_FRACT: c_uint = 0x8007;

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

extern fn clearSystemFlag(sf: c_uint) void;
extern fn fnRefreshState() void;

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
    runtime.z47_frontier_retained_fnP_PrinterOnOff(op);
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