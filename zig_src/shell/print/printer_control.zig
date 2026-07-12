const abi = @import("abi");
const frontier = @import("../shell.zig"); // M-callconv: Zig-to-Zig
const frontier_print = @import("print.zig"); // M-callconv: Zig-to-Zig

const FLAG_TRACE: c_uint = 0x8013;
const FLAG_PRTACT: c_uint = 0xc020;
const FLAG_PRTEN: u16 = 0x8067;
const FLAG_NORM: u16 = 0x8068;

const PROFF: u16 = 0;
const PRON: u16 = 1;
const MAN: u16 = 0;
const NORM: u16 = 1;
const TRACE: u16 = 2;
const STRACE: u16 = 3;

const PRINT_BYTE: c_int = 0;
const PRINT_CHAR: c_int = 1;
const PRINT_TAB: c_int = 2;

const PrinterState = abi.PrinterState;

pub const Command = enum {
    on_off,
    mode,
    set_model,
    set_delay,
    advance,
    list,
    byte,
    char,
    tab,
    lcd,
};

fn needsSbi(command: Command) bool {
    return switch (command) {
        .advance, .byte, .char, .tab => true,
        else => false,
    };
}

fn applyOn() void {
    printerState.print_on = true;
    setSystemFlag(FLAG_PRTACT);
    fnSetFlag(FLAG_PRTEN);
}

fn applyOff() void {
    printerState.print_on = false;
    clearSystemFlag(FLAG_PRTACT);
    fnClearFlag(FLAG_PRTEN);
}

fn applyOnOff(op: u16) void {
    if (op == PRON) {
        applyOn();
    } else if (op == PROFF) {
        applyOff();
    }
}

fn modeManual() void {
    fnClearFlag(FLAG_NORM);
    fnClearFlag(@as(u16, @intCast(FLAG_TRACE)));
}

fn modeNormal() void {
    fnSetFlag(FLAG_NORM);
    fnClearFlag(@as(u16, @intCast(FLAG_TRACE)));
}

fn modeTrace() void {
    fnClearFlag(FLAG_NORM);
    fnSetFlag(@as(u16, @intCast(FLAG_TRACE)));
}

fn modeStepTrace() void {
    fnSetFlag(FLAG_NORM);
    fnSetFlag(@as(u16, @intCast(FLAG_TRACE)));
}

fn applyMode(mode: u16) void {
    if (mode == MAN) {
        modeManual();
    } else if (mode == NORM) {
        modeNormal();
    } else if (mode == TRACE) {
        modeTrace();
    } else if (mode == STRACE) {
        modeStepTrace();
    }
}

fn applyModel(model: u16) void {
    printerState.printer_model = @as(c_int, @intCast(model));
}

fn applyDelay(delay: u16) void {
    printerState.delay = delay;
    setLineDelay(delay);
}

fn applyAdvance() void {
    frontier_print.print_lf();
}

fn applyList(lines: u16) void {
    frontier_print.printProgram(true, lines);
}

fn applyByte(byte: u16) void {
    frontier_print.cmdPrint(byte, PRINT_BYTE);
}

fn applyChar(register_no: u16) void {
    const character = frontier_print.z47_frontier_print_get_unicode_value(@as(i16, @intCast(register_no)));
    frontier_print.cmdPrint(character, PRINT_CHAR);
}

fn applyTab(column: u16) void {
    frontier_print.cmdPrint(column, PRINT_TAB);
}

fn applyLcd(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    if (getSystemFlag(@as(c_int, @intCast(FLAG_PRTACT)))) {
        return;
    }
    frontier.fnSNAP(9876);
}

pub fn run(command: Command, value: u16) void {
    const use_sbi = needsSbi(command);
    if (use_sbi) {
        frontier_print.z47_frontier_print_set_printer_sbi(true);
    }
    defer if (use_sbi) {
        frontier_print.z47_frontier_print_set_printer_sbi(false);
    };

    switch (command) {
        .on_off => applyOnOff(value),
        .mode => applyMode(value),
        .set_model => applyModel(value),
        .set_delay => applyDelay(value),
        .advance => applyAdvance(),
        .list => applyList(value),
        .byte => applyByte(value),
        .char => applyChar(value),
        .tab => applyTab(value),
        .lcd => applyLcd(value),
    }
}

extern var printerState: PrinterState;

extern fn clearSystemFlag(sf: c_uint) void;
extern fn setSystemFlag(sf: c_uint) void;
extern fn getSystemFlag(sf: c_int) bool;
extern fn fnSetFlag(flag: u16) void;
extern fn fnClearFlag(flag: u16) void;
extern fn setLineDelay(delay: u16) void;
