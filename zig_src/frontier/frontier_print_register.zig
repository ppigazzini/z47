const std = @import("std");

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
        z47_frontier_print_alpha_register(register_no);
        return;
    }

    if (calcMode != CM_AIM) {
        return;
    }

    z47_frontier_print_backup_aim_message_area();
    create_filename(".REGS.TSV");
    tmpString_csv_out(5);
    z47_frontier_print_restore_aim_message_area();
}

fn runRegister(register_no: u16) void {
    if (printerActive()) {
        var label: [32]u8 = std.mem.zeroes([32]u8);
        z47_frontier_format_register_label(register_no, &label, label.len);
        printReg(register_no, @ptrCast(&label), true, LINE_FULL, false);
        return;
    }

    if (calcMode != CM_NORMAL) {
        return;
    }

    create_filename(".REGS.TSV");
    stackregister_csv_out(@as(i16, @intCast(register_no)), @as(i16, @intCast(register_no)), false);
}

fn reportPrintingDisabled() void {
    displayCalcErrorMessage(ERROR_PRINTING_DISABLED, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}

fn reportMissingSigmaData() void {
    displayCalcErrorMessage(ERROR_NO_SUMMATION_DATA, ERR_REGISTER_LINE, REGISTER_X);
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
        z47_frontier_print_sigma_line(register_index);
        if (z47_frontier_print_exit_pressed()) {
            return;
        }
    }
}

extern var calcMode: u8;
extern var programRunStop: u8;
extern var currentKeyCode: u8;
extern var statisticalSumsPointer: ?*anyopaque;

extern fn getSystemFlag(sf: c_int) bool;
extern fn printReg(regist: u16, label: ?[*:0]const u8, eq: bool, where: c_int, pr_sigma: bool) void;
extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: i16, err_register_line: i16) void;
extern fn z47_frontier_print_exit_pressed() bool;
extern fn z47_frontier_print_sigma_line(index: u16) void;
extern fn z47_frontier_print_alpha_register(register_no: u16) void;
extern fn create_filename(file_suffix: [*:0]const u8) void;
extern fn stackregister_csv_out(reg_b: i16, reg_e: i16, one_line: bool) void;
extern fn z47_frontier_format_register_label(register_no: u16, label: [*]u8, label_size: u16) void;
extern fn z47_frontier_print_backup_aim_message_area() void;
extern fn z47_frontier_print_restore_aim_message_area() void;
extern fn tmpString_csv_out(nn: u8) void;