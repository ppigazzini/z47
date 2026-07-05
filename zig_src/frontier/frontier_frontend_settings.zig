const frontier_config = @import("frontier_config.zig"); // M-callconv: Zig-to-Zig
const frontier_radio_button_catalog = @import("frontier_radio_button_catalog.zig"); // M-callconv: Zig-to-Zig
const frontier_softmenus = @import("frontier_softmenus.zig"); // M-callconv: Zig-to-Zig
const FLAG_FRACT: c_uint = 0x8007;
const FLAG_PROPFR: c_uint = 0x8008;
const FLAG_FRCYC: c_uint = 0x8041;
const FLAG_IRFRAC: c_uint = 0x8047;
const FLAG_IRFRQ: c_uint = 0xc048;

const SETTING_AMODE: c_int = 0x0080;
const SETTING_SINT_MODE: c_int = 0x0083;

const TI_VERSION: u8 = 10;
const TI_WHO: u8 = 11;

const CM_CONFIRMATION: u8 = 11;

const CONFIRMED: u16 = 9877;

const MNU_GAP_L: i16 = 2151;
const MNU_GAP_RX: i16 = 2152;
const MNU_GAP_R: i16 = 2153;

const DF_DMX_MIN: i16 = 99;
const DF_HIDE_MIN: i16 = 12;

const ConfirmedFunction = *const fn (u16) callconv(.c) void;

pub const Command = enum {
    set_gap_char,
    set_group_left,
    set_group_1lo,
    set_group_1l,
    set_group_right,
    menu_gap_l,
    menu_gap_rx,
    menu_gap_r,
    integer_mode,
    who,
    version,
    set_rounding_mode,
    set_significant_digits,
    set_base_nr,
    set_fraction_digits,
    angular_mode,
    fraction_type,
    set_range,
    set_hide,
    confirmation_yes,
    confirmation_no,
    get_range,
    get_hide,
    get_last_error,
};

fn applySetGapChar(value: u16) void {
    const group = value & 49152;
    const payload = value & 16383;
    if (group == 0) {
        gapItemLeft = payload;
    } else if (group == 32768) {
        gapItemRight = payload;
    } else if (group == 49152) {
        gapItemRadix = payload;
    }
}

fn applyGroupLeft(value: u16) void {
    grpGroupingLeft = @as(u8, @intCast(value));
}

fn applyGroup1Lo(value: u16) void {
    grpGroupingGr1LeftOverflow = @as(u8, @intCast(value));
}

fn applyGroup1L(value: u16) void {
    grpGroupingGr1Left = @as(u8, @intCast(value));
}

fn applyGroupRight(value: u16) void {
    grpGroupingRight = @as(u8, @intCast(value));
}

fn applyMenuGapL() void {
    frontier_softmenus.showSoftmenu(-MNU_GAP_L);
}

fn applyMenuGapRx() void {
    frontier_softmenus.showSoftmenu(-MNU_GAP_RX);
}

fn applyMenuGapR() void {
    frontier_softmenus.showSoftmenu(-MNU_GAP_R);
}

fn applyIntegerMode(value: u16) void {
    if (shortIntegerMode != @as(u8, @intCast(value))) {
        setSystemFlagChanged(SETTING_SINT_MODE);
    }
    shortIntegerMode = @as(u8, @intCast(value));
    frontier_radio_button_catalog.fnRefreshState();
}

fn applyWho() void {
    temporaryInformation = TI_WHO;
}

fn applyVersion() void {
    temporaryInformation = TI_VERSION;
}

fn applyRounding(value: u16) void {
    roundingMode = @as(u8, @intCast(value));
}

fn applySignificantDigits(value: u16) void {
    significantDigits = @as(u8, @intCast(value));
    if (significantDigits == 0) {
        significantDigits = 34;
    }
}

fn applyBaseNr(value: u16) void {
    dispBase = @as(u8, @intCast(value));
    if (dispBase == 1) {
        dispBase = 0;
    }
}

fn applyFractionDigits(value: u16) void {
    fractionDigits = @as(u8, @intCast(value));
    if (fractionDigits == 0) {
        fractionDigits = 34;
    }
}

fn applyAngularMode(value: u16) void {
    if (currentAngularMode != @as(c_int, @intCast(value))) {
        setSystemFlagChanged(SETTING_AMODE);
    }
    currentAngularMode = @as(c_int, @intCast(value));
    frontier_radio_button_catalog.fnRefreshState();
}

fn applyFractionType() void {
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

fn applyRange(value: u16) void {
    exponentLimit = @as(i16, @intCast(value));
    if (exponentLimit < DF_DMX_MIN) {
        exponentLimit = DF_DMX_MIN;
    }
}

fn applyHide(value: u16) void {
    exponentHideLimit = @as(i16, @intCast(value));
    if (exponentHideLimit > 0 and exponentHideLimit < DF_HIDE_MIN) {
        exponentHideLimit = DF_HIDE_MIN;
    }
}

fn applyConfirmationYes() void {
    if (calcMode == CM_CONFIRMATION) {
        calcMode = previousCalcMode;
        frontier_softmenus.popSoftmenu();
        if (confirmedFunction) |func| {
            func(CONFIRMED);
        }
    }
}

fn applyConfirmationNo() void {
    if (calcMode == CM_CONFIRMATION) {
        calcMode = previousCalcMode;
        frontier_softmenus.popSoftmenu();
    }
}

fn applyGetRange() void {
    frontier_config.z47_frontier_push_u32_to_x(@as(u32, @intCast(exponentLimit)));
}

fn applyGetHide() void {
    frontier_config.z47_frontier_push_u32_to_x(@as(u32, @intCast(exponentHideLimit)));
}

fn applyGetLastError() void {
    frontier_config.z47_frontier_push_u32_to_x(@as(u32, previousErrorCode));
}

pub fn run(command: Command, value: u16) void {
    switch (command) {
        .set_gap_char => applySetGapChar(value),
        .set_group_left => applyGroupLeft(value),
        .set_group_1lo => applyGroup1Lo(value),
        .set_group_1l => applyGroup1L(value),
        .set_group_right => applyGroupRight(value),
        .menu_gap_l => applyMenuGapL(),
        .menu_gap_rx => applyMenuGapRx(),
        .menu_gap_r => applyMenuGapR(),
        .integer_mode => applyIntegerMode(value),
        .who => applyWho(),
        .version => applyVersion(),
        .set_rounding_mode => applyRounding(value),
        .set_significant_digits => applySignificantDigits(value),
        .set_base_nr => applyBaseNr(value),
        .set_fraction_digits => applyFractionDigits(value),
        .angular_mode => applyAngularMode(value),
        .fraction_type => applyFractionType(),
        .set_range => applyRange(value),
        .set_hide => applyHide(value),
        .confirmation_yes => applyConfirmationYes(),
        .confirmation_no => applyConfirmationNo(),
        .get_range => applyGetRange(),
        .get_hide => applyGetHide(),
        .get_last_error => applyGetLastError(),
    }
}

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
extern var calcMode: u8;
extern var previousCalcMode: u8;
extern var previousErrorCode: u8;
extern var confirmedFunction: ?ConfirmedFunction;

extern fn clearSystemFlag(sf: c_uint) void;
extern fn setSystemFlag(sf: c_uint) void;
extern fn getSystemFlag(sf: c_int) bool;
extern fn flipSystemFlag(sf: c_uint) void;
extern fn setSystemFlagChanged(sf: c_int) void;



