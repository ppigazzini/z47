const std = @import("std");
const abi = @import("abi");
const frontier_build_options = @import("frontier_build_options");
const frontier_error = @import("../error.zig");
const frontier_graph_text = @import("../plot/graph_text.zig");
const frontier_print = @import("print.zig");
const frontier_textfiles = @import("../extensions/textfiles.zig");

const extra_info: bool = frontier_build_options.extra_info_on_calc_error;
const ERROR_MESSAGE_LENGTH: usize = 512;

const FLAG_PRTACT: c_uint = 0xc020;
const FLAG_PRTEN: u16 = 0x8067;

const CM_NORMAL: u8 = 0;
const CM_AIM: u8 = 1;

const ERROR_NO_SUMMATION_DATA: u8 = 28;
const ERROR_PRINTING_DISABLED: u8 = 63;

const ERR_REGISTER_LINE: i16 = 102;
const NIM_REGISTER_LINE: i16 = 100;
const REGISTER_X: i16 = 100;

const PGM_RUNNING: u8 = 1;
const PGM_SINGLE_STEP: u8 = 6;

const LINE_FULL: c_int = 0;
const SIGMA_REGISTER_COUNT: u16 = 28;
const SIGMA_KEYCODE: u8 = 255;

pub const Command = enum {
    alpha,
    regs,
    sigma,
};

pub fn run(command: Command, register_no: u16) void {
    switch (command) {
        .alpha => runAlpha(register_no),
        .regs => runRegister(register_no),
        .sigma => runSigma(),
    }
}

fn printerActive() bool {
    return getSystemFlag(@as(c_int, @intCast(FLAG_PRTACT)));
}

fn printEnabledWhileProgramRuns() bool {
    return getSystemFlag(@as(c_int, @intCast(FLAG_PRTEN))) or (programRunStop != PGM_RUNNING and programRunStop != PGM_SINGLE_STEP);
}

// Upstream's fnP_Alpha/fnP_Regs chirp 440/4400/440 on DMCP before bailing out of
// the print-to-file path in the wrong calc mode -- the only feedback the user
// gets that the key did nothing. Host builds have no buzzer, so this is
// firmware-only, matching the `#if defined(DMCP_BUILD)` around the C.
fn beepWrongCalcMode() void {
    if (comptime !frontier_print.is_dmcp_build) {
        return;
    }
    frontier_print.beep(440, 50);
    frontier_print.beep(4400, 50);
    frontier_print.beep(440, 50);
}

fn runAlpha(register_no: u16) void {
    if (printerActive()) {
        frontier_print.z47_frontier_print_alpha_register(register_no);
        return;
    }

    if (calcMode != CM_AIM) {
        beepWrongCalcMode();
        return;
    }

    frontier_print.z47_frontier_print_backup_aim_message_area();
    frontier_graph_text.create_filename(".REGS.TSV");
    frontier_textfiles.tmpString_csv_out(5);
    frontier_print.z47_frontier_print_restore_aim_message_area();
}

fn runRegister(register_no: u16) void {
    if (printerActive()) {
        // fnP_Regs wraps only its print-to-printer arm in
        // `#if defined(OPTION_IR_PRINTING)`, so on the DM42 packages that drop
        // the option the label is never built and nothing is printed; the
        // print-to-file arm below stays live everywhere.
        if (comptime !frontier_print.ir_printing) {
            return;
        }
        // fnP_Regs declares char label[16]: the longest thing written into it is
        // a named variable's name, at most 15 bytes plus the terminator.
        var label: [16]u8 = std.mem.zeroes([16]u8);
        frontier_print.z47_frontier_format_register_label(register_no, &label, label.len);
        frontier_print.printReg(register_no, @ptrCast(&label), true, LINE_FULL, false);
        return;
    }

    if (calcMode != CM_NORMAL) {
        beepWrongCalcMode();
        return;
    }

    frontier_graph_text.create_filename(".REGS.TSV");
    frontier_textfiles.stackregister_csv_out(@as(i16, @intCast(register_no)), @as(i16, @intCast(register_no)), false);
}

// fnP_Sigma's printing-disabled hint is a `#if defined(PC_BUILD)` console line
// built through the shared errorMessage buffer, host-only like the printf
// traces in the print owner.
fn reportPrintingDisabled() void {
    frontier_error.displayCalcErrorMessage(ERROR_PRINTING_DISABLED, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
    if (comptime !frontier_print.is_dmcp_build) {
        abi.fmtBufZ(errorMessage[0..ERROR_MESSAGE_LENGTH], "Printing is disabled", .{});
        frontier_error.moreInfoOnErrorImpl("In function fnP_Sigma:", errorMessage, null, null);
    }
}

// The no-summation-data hint is the EXTRA_INFO one, and it passes its text
// straight to moreInfoOnError rather than through errorMessage.
fn reportMissingSigmaData() void {
    frontier_error.displayCalcErrorMessage(ERROR_NO_SUMMATION_DATA, ERR_REGISTER_LINE, REGISTER_X);
    if (comptime extra_info) {
        frontier_error.moreInfoOnErrorImpl("In function fnP_Sigma:", "There is no statistical data available!", null, null);
    }
}

fn runSigma() void {
    currentKeyCode = SIGMA_KEYCODE;

    if (statisticalSumsPointer == null) {
        reportMissingSigmaData();
        return;
    }

    if (!printerActive()) {
        return;
    }

    // fnP_Sigma's print-to-printer arm -- the printing-disabled refusal included
    // -- sits inside `#if defined(OPTION_IR_PRINTING)`, so the DM42 packages that
    // drop the option reach the same empty body as the print-to-file arm. The
    // no-summation-data error above is outside the guard and stays live.
    if (comptime !frontier_print.ir_printing) {
        return;
    }

    if (!printEnabledWhileProgramRuns()) {
        reportPrintingDisabled();
        return;
    }

    var register_index: u16 = 0;
    while (register_index < SIGMA_REGISTER_COUNT) : (register_index += 1) {
        frontier_print.z47_frontier_print_sigma_line(register_index);
        if (frontier_print.z47_frontier_print_exit_pressed()) {
            return;
        }
    }
}

extern var calcMode: u8;
extern var errorMessage: [*c]u8;
extern var programRunStop: u8;
extern var currentKeyCode: u8;
extern var statisticalSumsPointer: ?*anyopaque;

extern fn getSystemFlag(sf: c_int) bool;

pub export fn fnP_Alpha(register_no: u16) callconv(.c) void {
    run(.alpha, register_no);
}

pub export fn fnP_Regs(register_no: u16) callconv(.c) void {
    run(.regs, register_no);
}
