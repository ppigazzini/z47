const std = @import("std");
const frontier_error = @import("../error.zig");
const frontier_graph_text = @import("../plot/graph_text.zig");
const frontier_print = @import("print.zig");
const frontier_textfiles = @import("../extensions/textfiles.zig");
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

fn runAlpha(register_no: u16) void {
    if (printerActive()) {
        frontier_print.z47_frontier_print_alpha_register(register_no);
        return;
    }

    if (calcMode != CM_AIM) {
        return;
    }

    frontier_print.z47_frontier_print_backup_aim_message_area();
    frontier_graph_text.create_filename(".REGS.TSV");
    frontier_textfiles.tmpString_csv_out(5);
    frontier_print.z47_frontier_print_restore_aim_message_area();
}

fn runRegister(register_no: u16) void {
    if (printerActive()) {
        var label: [32]u8 = std.mem.zeroes([32]u8);
        frontier_print.z47_frontier_format_register_label(register_no, &label, label.len);
        frontier_print.printReg(register_no, @ptrCast(&label), true, LINE_FULL, false);
        return;
    }

    if (calcMode != CM_NORMAL) {
        return;
    }

    frontier_graph_text.create_filename(".REGS.TSV");
    frontier_textfiles.stackregister_csv_out(@as(i16, @intCast(register_no)), @as(i16, @intCast(register_no)), false);
}

fn reportPrintingDisabled() void {
    frontier_error.displayCalcErrorMessage(ERROR_PRINTING_DISABLED, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}

fn reportMissingSigmaData() void {
    frontier_error.displayCalcErrorMessage(ERROR_NO_SUMMATION_DATA, ERR_REGISTER_LINE, REGISTER_X);
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
