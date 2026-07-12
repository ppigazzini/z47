const frontier_radio_button_catalog = @import("../extensions/radio_button_catalog.zig");
const DSP_MAX: u16 = 19;
const FLAG_FRACT: c_uint = 0x8007;

const DF_ALL: u8 = 0;
const DF_FIX: u8 = 1;
const DF_SCI: u8 = 2;
const DF_ENG: u8 = 3;
const DF_SF: u8 = 4;
const DF_UN: u8 = 5;

pub const Command = enum {
    fix,
    sci,
    eng,
    all,
    sig_fig,
    unit,
    dsp,
    time,
};

fn clampDigits(display_format_n: u16) u8 {
    const clamped: u16 = if (display_format_n > DSP_MAX) DSP_MAX else display_format_n;
    return @as(u8, @intCast(clamped));
}

fn shouldResetFraction(command: Command) bool {
    return command != .time;
}

fn shouldResetCycle(command: Command) bool {
    return switch (command) {
        .fix, .sci, .eng, .all, .sig_fig, .unit => true,
        else => false,
    };
}

fn shouldRefresh(command: Command) bool {
    return command != .time;
}

fn applyCommand(command: Command, clamped_digits: u8) void {
    switch (command) {
        .fix => {
            displayFormatDigits = clamped_digits;
            displayFormat = DF_FIX;
        },
        .sci => {
            displayFormatDigits = clamped_digits;
            displayFormat = DF_SCI;
        },
        .eng => {
            displayFormatDigits = clamped_digits;
            displayFormat = DF_ENG;
        },
        .all => {
            displayFormatDigits = clamped_digits;
            displayFormat = DF_ALL;
        },
        .sig_fig => {
            displayFormatDigits = clamped_digits;
            displayFormat = DF_SF;
        },
        .unit => {
            displayFormatDigits = clamped_digits;
            displayFormat = DF_UN;
        },
        .dsp => {
            displayFormatDigits = clamped_digits;
        },
        .time => {
            timeDisplayFormatDigits = clamped_digits;
        },
    }
}

pub fn run(command: Command, display_format_n: u16) void {
    const clamped_digits = clampDigits(display_format_n);

    if (shouldResetFraction(command)) {
        clearSystemFlag(FLAG_FRACT);
    }

    if (shouldResetCycle(command)) {
        DM_Cycling = 0;
    }

    applyCommand(command, clamped_digits);

    if (shouldRefresh(command)) {
        frontier_radio_button_catalog.fnRefreshState();
    }
}

extern var displayFormat: u8;
extern var displayFormatDigits: u8;
extern var timeDisplayFormatDigits: u8;
extern var DM_Cycling: u8;

extern fn clearSystemFlag(sf: c_uint) void;
