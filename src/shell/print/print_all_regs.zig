const std = @import("std");
const abi = @import("abi");
const frontier_build_options = @import("frontier_build_options");
const frontier_debug = @import("../debug.zig");
const frontier_error = @import("../error.zig");
const register_data_type = @import("../register_data_type.zig");
const frontier_graph_text = @import("../plot/graph_text.zig");
const frontier_print = @import("print.zig");
const frontier_textfiles = @import("../extensions/textfiles.zig");

const extra_info: bool = frontier_build_options.extra_info_on_calc_error;
const ERROR_MESSAGE_LENGTH: usize = 512;

const CM_NORMAL: u8 = 0;
const CM_NO_UNDO: u8 = 16;

const ERROR_NONE: u8 = 0;
const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;

const FLAG_PRTACT: c_uint = 0xc020;
const FLAG_SSIZE8: c_int = 0x8018;

const FIRST_NAMED_VARIABLE: u16 = 256;
const FIRST_LOCAL_REGISTER: u16 = 7000;

const REGISTER_X: i16 = 100;
const REGISTER_Y: i16 = 101;
const REGISTER_Z: i16 = 102;
const REGISTER_T: u16 = 103;
const REGISTER_D: u16 = 107;
const REGISTER_W: u16 = 125;

const ERR_REGISTER_LINE: i16 = REGISTER_Z;
const NIM_REGISTER_LINE: i16 = REGISTER_X;

const PRN_ALL: u16 = 0;
const PRN_STK: u16 = 1;
const PRN_REGS: u16 = 2;
const PRN_GLOBALr: u16 = 3;
const PRN_LOCALr: u16 = 4;
const PRN_NAMEDr: u16 = 5;
const PRN_Xr: u16 = 6;
const PRN_XYr: u16 = 7;
const PRN_TMP: u16 = 8;

const TEMP_REGISTER_1: u16 = 135;

const LINE_FULL: c_int = 0;
const LINE_LEFT: c_int = 1;
const LINE_RIGHT: c_int = 2;

const dtLongInteger: u32 = 0;
const dtReal34: u32 = 1;
const dtComplex34: u32 = 2;
const dtTime: u32 = 3;
const dtDate: u32 = 4;
const dtString: u32 = 5;
const dtReal34Matrix: u32 = 6;
const dtComplex34Matrix: u32 = 7;
const dtShortInteger: u32 = 8;

const PrintAllRegsBackend = enum {
    printer,
    csv,
    unsupported,
};

const PrintAllRegsPhase = enum {
    preflight,
    execution,
};

const print_all_regs_phase_order = [_]PrintAllRegsPhase{
    .preflight,
    .execution,
};

const PrintAllRegsTelemetry = struct {
    started: std.EnumSet(PrintAllRegsPhase) = std.EnumSet(PrintAllRegsPhase).empty,
    completed: std.EnumSet(PrintAllRegsPhase) = std.EnumSet(PrintAllRegsPhase).empty,
    aborted: bool = false,

    fn start(self: *PrintAllRegsTelemetry, phase: PrintAllRegsPhase) void {
        self.started.insert(phase);
    }

    fn complete(self: *PrintAllRegsTelemetry, phase: PrintAllRegsPhase) void {
        self.completed.insert(phase);
    }

    fn abort(self: *PrintAllRegsTelemetry) void {
        self.aborted = true;
    }

    fn canRun(self: PrintAllRegsTelemetry, phase: PrintAllRegsPhase) bool {
        return switch (phase) {
            .preflight => true,
            .execution => self.completed.contains(.preflight) and !self.aborted,
        };
    }
};

// fnP_All_Regs chirps 440/4400/440 on DMCP before bailing out of the
// print-to-file path in the wrong calc mode -- the only feedback the user gets
// that the key did nothing. Host builds have no buzzer, so this is
// firmware-only, matching the `#if defined(DMCP_BUILD)` around the C.
fn beepWrongCalcMode() void {
    if (comptime !frontier_print.is_dmcp_build) {
        return;
    }
    frontier_print.beep(440, 50);
    frontier_print.beep(4400, 50);
    frontier_print.beep(440, 50);
}

const PrintAllRegsContext = struct {
    option: u16,
    backend: PrintAllRegsBackend = .unsupported,
    local_count: u16 = 0,
    s: u16 = 0,
    n: u16 = 0,

    fn resolveBackend(self: *PrintAllRegsContext) bool {
        if (getSystemFlag(@as(c_int, @intCast(FLAG_PRTACT)))) {
            self.backend = .printer;
            return true;
        }

        if (calcMode == CM_NORMAL or calcMode == CM_NO_UNDO) {
            self.backend = .csv;
            return true;
        }

        self.backend = .unsupported;
        beepWrongCalcMode();
        return false;
    }

    fn cacheLocalCount(self: *PrintAllRegsContext) void {
        self.local_count = frontier_print.z47_frontier_current_number_of_local_registers();
    }

    fn prepareCsvFilename(self: *PrintAllRegsContext) void {
        if (self.backend != .csv) {
            return;
        }

        frontier_graph_text.create_filename(".REGS.TSV");
        self.cacheLocalCount();
    }

    fn resolveRegParam(self: *PrintAllRegsContext) bool {
        lastErrorCode = getRegParam(null, &self.s, &self.n, null);
        if (lastErrorCode == ERROR_NONE) {
            return true;
        }

        frontier_error.displayCalcErrorMessage(lastErrorCode, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        return false;
    }

    fn execute(self: *PrintAllRegsContext) void {
        switch (self.backend) {
            .printer => self.executePrinterOption(),
            .csv => self.executeCsvOption(),
            .unsupported => {},
        }
    }

    // fnP_All_Regs wraps only its print-to-printer arm in
    // `#if defined(OPTION_IR_PRINTING)`, so on the DM42 packages that drop the
    // option that whole option switch is gone: no register is printed and none
    // of its ERROR_INVALID_DATA_TYPE_FOR_OP / ERROR_MATRIX_MISMATCH refusals is
    // raised. The print-to-file arm is outside the guard and stays live.
    fn executePrinterOption(self: *PrintAllRegsContext) void {
        if (comptime !frontier_print.ir_printing) {
            return;
        }
        switch (self.option) {
            PRN_ALL => self.printerOptionAll(),
            PRN_REGS => self.printerOptionRegs(),
            PRN_Xr => self.printerOptionXr(),
            PRN_STK => self.printerOptionStack(),
            PRN_XYr => self.printerOptionXYr(),
            else => {},
        }
    }

    fn printerOptionAll(self: *PrintAllRegsContext) void {
        self.cacheLocalCount();
        if (printAllRegsPrintRangeOrReturn(@as(u16, @intCast(REGISTER_X)), REGISTER_W)) return;
        if (printAllRegsPrintRangeOrReturn(0, 99)) return;

        if (self.local_count > 0 and printAllRegsPrintRangeOrReturn(FIRST_LOCAL_REGISTER, FIRST_LOCAL_REGISTER + self.local_count - 1)) {
            return;
        }

        if (numberOfNamedVariables > 0) {
            _ = printAllRegsPrintRangeOrReturn(FIRST_NAMED_VARIABLE, FIRST_NAMED_VARIABLE + numberOfNamedVariables - 1);
        }
    }

    fn printerOptionRegs(self: *PrintAllRegsContext) void {
        if (!self.resolveRegParam()) {
            return;
        }

        _ = printAllRegsPrintRangeOrReturn(self.s, (self.s + self.n) - 1);
    }

    fn printerOptionXr(self: *PrintAllRegsContext) void {
        _ = self;
        frontier_print.printReg(@as(u16, @intCast(REGISTER_X)), null, false, LINE_FULL, false);
    }

    fn printerOptionStack(self: *PrintAllRegsContext) void {
        _ = self;
        const stack_top: u16 = if (getSystemFlag(FLAG_SSIZE8)) REGISTER_D else REGISTER_T;
        _ = printAllRegsPrintRangeOrReturn(stack_top, @as(u16, @intCast(REGISTER_X)));
    }

    fn printerOptionXYr(self: *PrintAllRegsContext) void {
        _ = self;
        if (printAllRegsPrinterXYrScalar()) {
            return;
        }

        if (printAllRegsPrinterXYrMatrix()) {
            return;
        }

        frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        reportInvalidXYrDataType(REGISTER_X, "X");
    }

    fn executeCsvOption(self: *PrintAllRegsContext) void {
        switch (self.option) {
            PRN_ALL => self.csvOptionAll(),
            PRN_REGS => self.csvOptionRegs(),
            PRN_STK => self.csvOptionStack(),
            PRN_GLOBALr => printAllRegsCsvOut(0, 99, false),
            PRN_LOCALr => self.csvOptionLocal(),
            PRN_NAMEDr => self.csvOptionNamed(),
            PRN_Xr => printAllRegsCsvOut(@as(i16, @intCast(REGISTER_X)), @as(i16, @intCast(REGISTER_X)), false),
            PRN_TMP => printAllRegsCsvOut(@as(i16, @intCast(TEMP_REGISTER_1)), @as(i16, @intCast(TEMP_REGISTER_1)), false),
            PRN_XYr => printAllRegsCsvOut(@as(i16, @intCast(REGISTER_X)), @as(i16, @intCast(REGISTER_Y)), true),
            else => {},
        }
    }

    fn csvOptionAll(self: *PrintAllRegsContext) void {
        self.cacheLocalCount();
        printAllRegsCsvOut(@as(i16, @intCast(REGISTER_X)), @as(i16, @intCast(REGISTER_W)), false);
        printAllRegsCsvOut(0, 99, false);

        if (self.local_count > 0) {
            printAllRegsCsvOut(@as(i16, @intCast(FIRST_LOCAL_REGISTER)), @as(i16, @intCast(FIRST_LOCAL_REGISTER + self.local_count - 1)), false);
        }

        if (numberOfNamedVariables > 0) {
            printAllRegsCsvOut(@as(i16, @intCast(FIRST_NAMED_VARIABLE)), @as(i16, @intCast(FIRST_NAMED_VARIABLE + numberOfNamedVariables - 1)), false);
        }
    }

    fn csvOptionRegs(self: *PrintAllRegsContext) void {
        if (!self.resolveRegParam()) {
            return;
        }

        printAllRegsCsvOut(@as(i16, @intCast(self.s)), @as(i16, @intCast((self.s + self.n) - 1)), false);
    }

    fn csvOptionStack(self: *PrintAllRegsContext) void {
        _ = self;
        if (getSystemFlag(FLAG_SSIZE8)) {
            printAllRegsCsvOut(@as(i16, @intCast(REGISTER_X)), @as(i16, @intCast(REGISTER_D)), false);
            return;
        }

        printAllRegsCsvOut(@as(i16, @intCast(REGISTER_X)), @as(i16, @intCast(REGISTER_T)), false);
    }

    fn csvOptionLocal(self: *PrintAllRegsContext) void {
        self.cacheLocalCount();
        if (self.local_count == 0) {
            return;
        }

        printAllRegsCsvOut(@as(i16, @intCast(FIRST_LOCAL_REGISTER)), @as(i16, @intCast(FIRST_LOCAL_REGISTER + self.local_count - 1)), false);
    }

    fn csvOptionNamed(self: *PrintAllRegsContext) void {
        _ = self;
        if (numberOfNamedVariables == 0) {
            return;
        }

        printAllRegsCsvOut(@as(i16, @intCast(FIRST_NAMED_VARIABLE)), @as(i16, @intCast(FIRST_NAMED_VARIABLE + numberOfNamedVariables - 1)), false);
    }
};

const PrintAllRegsRunner = struct {
    ctx: PrintAllRegsContext,
    telemetry: PrintAllRegsTelemetry = .{},

    fn run(self: *PrintAllRegsRunner) void {
        if (printAllRegsUseTelemetryPipeline()) {
            self.runWithTelemetry();
            return;
        }

        self.runBare();
    }

    fn runBare(self: *PrintAllRegsRunner) void {
        for (print_all_regs_phase_order) |phase| {
            if (!self.executePhase(phase)) {
                return;
            }
        }
    }

    fn runWithTelemetry(self: *PrintAllRegsRunner) void {
        for (print_all_regs_phase_order) |phase| {
            if (!self.telemetry.canRun(phase)) {
                return;
            }

            self.telemetry.start(phase);
            if (!self.executePhase(phase)) {
                self.telemetry.abort();
                return;
            }
            self.telemetry.complete(phase);
        }
    }

    fn executePhase(self: *PrintAllRegsRunner, phase: PrintAllRegsPhase) bool {
        return switch (phase) {
            .preflight => self.ctx.resolveBackend(),
            .execution => blk: {
                self.ctx.prepareCsvFilename();
                self.ctx.execute();
                break :blk true;
            },
        };
    }
};

fn isPrintableScalarType(dt: u32) bool {
    return register_data_type.isPrintableScalarType(dt);
}

// The two PRN_XYr scalar refusals name the register and the data type that was
// refused; both are EXTRA_INFO console hints, compiled out on firmware and on
// the testSuite.
fn reportInvalidXYrDataType(regist: i16, register_letter: []const u8) void {
    if (comptime !extra_info) {
        return;
    }
    abi.fmtBufZ(errorMessage[0..ERROR_MESSAGE_LENGTH], "invalid data type {s} for register {s}", .{
        std.mem.span(frontier_debug.getRegisterDataTypeName(regist, true, false)),
        register_letter,
    });
    frontier_error.moreInfoOnErrorImpl("In function fnP_All_Regs(PRN_XYr):", errorMessage, null, null);
}

fn printAllRegsPrintRangeOrReturn(first: u16, last: u16) bool {
    return frontier_print.z47_frontier_print_reg_range(first, last);
}

fn printAllRegsPrinterXYrScalar() bool {
    const x_type = getRegisterDataType(REGISTER_X);
    if (!isPrintableScalarType(x_type)) {
        return false;
    }

    const y_type = getRegisterDataType(REGISTER_Y);
    if (!isPrintableScalarType(y_type)) {
        frontier_error.displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_Y);
        reportInvalidXYrDataType(REGISTER_Y, "Y");
        return true;
    }

    frontier_print.printReg(@as(u16, @intCast(REGISTER_X)), null, false, LINE_LEFT, false);
    frontier_print.printReg(@as(u16, @intCast(REGISTER_Y)), null, false, LINE_RIGHT, false);
    return true;
}

// Both matrix arms convert register X once and read the dimensions and every
// element off that one copy; the dimension tests, the two loops and the size
// mismatch refusal live with the conversion in the print owner.
fn printAllRegsPrinterXYrMatrix() bool {
    const x_type = getRegisterDataType(REGISTER_X);
    if (x_type == dtReal34Matrix) {
        frontier_print.z47_frontier_print_xy_real_matrix();
        return true;
    }

    if (x_type == dtComplex34Matrix) {
        frontier_print.z47_frontier_print_xy_complex_matrix();
        return true;
    }

    return false;
}

fn printAllRegsCsvOut(first: i16, last: i16, one_line: bool) void {
    frontier_textfiles.stackregister_csv_out(first, last, one_line);
}

fn printAllRegsUseTelemetryPipeline() bool {
    return true;
}

pub fn run(option: u16) void {
    var runner = PrintAllRegsRunner{
        .ctx = .{ .option = option },
    };
    runner.run();
}

extern var calcMode: u8;
extern var errorMessage: [*c]u8;
extern var lastErrorCode: u8;
extern var numberOfNamedVariables: u16;

extern fn getSystemFlag(sf: c_int) bool;

extern fn getRegParam(f: ?*bool, s: *u16, n: *u16, d: ?*u16) u8;

extern fn getRegisterDataType(regist: i16) u32;

pub export fn fnP_All_Regs(option: u16) callconv(.c) void {
    run(option);
}
