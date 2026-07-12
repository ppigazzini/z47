const std = @import("std");
const frontier_error = @import("../error.zig"); // M-callconv: Zig-to-Zig
const frontier_print = @import("print.zig"); // M-callconv: Zig-to-Zig

const FLAG_PRTACT: c_uint = 0xc020;
const FLAG_PRTEN: u16 = 0x8067;

const ERROR_PRINTING_DISABLED: u8 = 63;

const REGISTER_X: i16 = 100;
const REGISTER_Z: i16 = 102;

const ERR_REGISTER_LINE: i16 = REGISTER_Z;
const NIM_REGISTER_LINE: i16 = REGISTER_X;
const LINE_FULL: c_int = 0;

const PGM_RUNNING: u8 = 1;
const PGM_SINGLE_STEP: u8 = 6;

const PrintUserStage = enum {
    initialize,
    validate_printer_active,
    print_user_variables,
    print_program_listing,
    print_trailer,
};

const PrintUserPhase = enum {
    preflight,
    scan_variables,
    scan_programs,
    finalize,
};

const print_user_phase_order = [_]PrintUserPhase{
    .preflight,
    .scan_variables,
    .scan_programs,
    .finalize,
};

const PrintUserTelemetry = struct {
    started: std.EnumSet(PrintUserPhase) = std.EnumSet(PrintUserPhase).initEmpty(),
    completed: std.EnumSet(PrintUserPhase) = std.EnumSet(PrintUserPhase).initEmpty(),
    aborted: bool = false,

    fn start(self: *PrintUserTelemetry, phase: PrintUserPhase) void {
        self.started.insert(phase);
    }

    fn complete(self: *PrintUserTelemetry, phase: PrintUserPhase) void {
        self.completed.insert(phase);
    }

    fn abort(self: *PrintUserTelemetry) void {
        self.aborted = true;
    }

    fn canRun(self: PrintUserTelemetry, phase: PrintUserPhase) bool {
        return switch (phase) {
            .preflight => true,
            .scan_variables => self.completed.contains(.preflight) and !self.aborted,
            .scan_programs => self.completed.contains(.scan_variables) and !self.aborted,
            .finalize => self.completed.contains(.scan_programs) and !self.aborted,
        };
    }
};

const PrintUserContext = struct {
    label: [32]u8 = std.mem.zeroes([32]u8),
    user_variable_found: bool = false,
    step: [*]u8 = undefined,
    program_number: u16 = 1,
    first_program_label: bool = true,

    fn initialize(self: *PrintUserContext) void {
        currentKeyCode = 255;
        self.step = frontier_print.z47_frontier_program_begin();
        self.program_number = 1;
        self.first_program_label = true;
        self.user_variable_found = false;
    }

    fn validatePrinterActive(self: *PrintUserContext) bool {
        _ = self;
        if (!printUserPrinterEnabled()) {
            if (getSystemFlag(@as(c_int, @intCast(FLAG_PRTEN))) or printUserRunStateAllowsPrint()) {
                frontier_error.displayCalcErrorMessage(ERROR_PRINTING_DISABLED, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
            }
            return false;
        }
        return true;
    }

    fn loadLabel(self: *PrintUserContext, idx: u16) bool {
        return frontier_print.z47_frontier_named_variable_label(idx, &self.label, self.label.len);
    }

    fn shouldSkipLabel(self: *PrintUserContext) bool {
        return frontier_print.z47_frontier_user_variable_should_skip(@ptrCast(&self.label));
    }

    fn printVariableLine(self: *PrintUserContext) void {
        const variable = frontier_print.z47_frontier_find_named_variable_register(@ptrCast(&self.label));
        frontier_print.printReg(@intCast(variable), @ptrCast(&self.label), true, LINE_FULL, false);
        self.user_variable_found = true;
    }

    fn scanVariables(self: *PrintUserContext) bool {
        var idx: u16 = 0;
        while (idx < numberOfNamedVariables) : (idx += 1) {
            if (!self.loadLabel(idx)) {
                continue;
            }

            if (self.shouldSkipLabel()) {
                continue;
            }

            self.printVariableLine();
            if (frontier_print.z47_frontier_print_exit_pressed()) {
                return false;
            }
        }

        if (self.user_variable_found) {
            frontier_print.print_lf();
        }

        return true;
    }

    fn programHasNext(self: PrintUserContext) bool {
        return !frontier_print.z47_frontier_programs_end(self.step);
    }

    fn advanceProgramStep(self: *PrintUserContext) [*]u8 {
        return frontier_print.z47_frontier_program_next_step(self.step);
    }

    fn printProgramLabel(self: *PrintUserContext) void {
        frontier_print.printLine(frontier_print.z47_frontier_program_label_prefix(), 0);
        frontier_print.printLine(@ptrCast(&self.label), 0);
        frontier_print.printLine(frontier_print.z47_frontier_program_label_suffix(), if (self.first_program_label) 0 else 1);

        if (self.first_program_label) {
            frontier_print.z47_frontier_print_program_counter(self.program_number, numberOfPrograms);
            self.first_program_label = false;
        }
    }

    fn handleProgramGlobalLabel(self: *PrintUserContext) void {
        if (frontier_print.z47_frontier_program_global_label(self.step, &self.label, self.label.len)) {
            self.printProgramLabel();
        }
    }

    fn handleProgramEnd(self: *PrintUserContext) void {
        if (!frontier_print.z47_frontier_program_step_is_end(self.step)) {
            return;
        }

        frontier_print.printLine("END", if (self.first_program_label) 0 else 1);
        if (self.first_program_label) {
            frontier_print.z47_frontier_print_program_counter(self.program_number, numberOfPrograms);
        }
        self.program_number += 1;
        self.first_program_label = true;
    }

    fn scanPrograms(self: *PrintUserContext) bool {
        while (self.programHasNext()) {
            const next_step = self.advanceProgramStep();

            self.handleProgramGlobalLabel();
            self.handleProgramEnd();

            self.step = next_step;
            if (frontier_print.z47_frontier_print_exit_pressed()) {
                return false;
            }
        }

        return true;
    }
};

const PrintUserRunner = struct {
    ctx: PrintUserContext = .{},
    telemetry: PrintUserTelemetry = .{},

    fn run(self: *PrintUserRunner) void {
        if (printUserUseTelemetryPipeline()) {
            self.runWithTelemetry();
            return;
        }
        self.runBare();
    }

    fn runBare(self: *PrintUserRunner) void {
        for (print_user_phase_order) |phase| {
            if (!self.executePhase(phase)) {
                return;
            }
        }
    }

    fn runWithTelemetry(self: *PrintUserRunner) void {
        for (print_user_phase_order) |phase| {
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

    fn executePhase(self: *PrintUserRunner, phase: PrintUserPhase) bool {
        for (printUserStagesForPhase(phase)) |stage| {
            if (!self.executeStage(stage)) {
                return false;
            }
        }
        return true;
    }

    fn executeStage(self: *PrintUserRunner, stage: PrintUserStage) bool {
        return switch (stage) {
            .initialize => blk: {
                self.ctx.initialize();
                break :blk true;
            },
            .validate_printer_active => self.ctx.validatePrinterActive(),
            .print_user_variables => self.ctx.scanVariables(),
            .print_program_listing => self.ctx.scanPrograms(),
            .print_trailer => blk: {
                frontier_print.printLine(".END.", 1);
                break :blk true;
            },
        };
    }
};

fn printUserStagesForPhase(phase: PrintUserPhase) []const PrintUserStage {
    return switch (phase) {
        .preflight => &.{ .initialize, .validate_printer_active },
        .scan_variables => &.{.print_user_variables},
        .scan_programs => &.{.print_program_listing},
        .finalize => &.{.print_trailer},
    };
}

fn printUserPrinterEnabled() bool {
    return getSystemFlag(@as(c_int, @intCast(FLAG_PRTACT)));
}

fn printUserRunStateAllowsPrint() bool {
    return !((programRunStop != PGM_RUNNING) and (programRunStop != PGM_SINGLE_STEP));
}

fn printUserUseTelemetryPipeline() bool {
    return true;
}

pub fn run() void {
    var runner = PrintUserRunner{};
    runner.run();
}

extern var programRunStop: u8;
extern var currentKeyCode: u8;
extern var numberOfNamedVariables: u16;
extern var numberOfPrograms: u16;

extern fn getSystemFlag(sf: c_int) bool;
