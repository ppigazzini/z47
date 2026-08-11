const abi = @import("abi");
const build_options = @import("register_metadata_build_options");
const stack_runtime = @import("../runtime/stack_runtime.zig");

pub const REGISTER_X = stack_runtime.REGISTER_X;
pub const REGISTER_Y = stack_runtime.REGISTER_Y;

extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: stack_runtime.calcRegister_t, err_register_line: stack_runtime.calcRegister_t) void;

// The firmware-bug reports the register accessors raise: a register id no branch
// of the accessor can serve is a coding error, not a calculator error, so the
// screen switches to CM_BUG_ON_SCREEN in every build and lastErrorCode is left
// alone. The formats are the shared commonBugScreenMessages rows so the text has
// one owner; the row indices are commonBugScreenMessageCode_t.
const bugMsgNoNamedVariables: usize = 2;
const bugMsgDataTypeUnknown: usize = 5;
const bugMsgRegistMustBeLessThan: usize = 6;
const bugMsgNotDefinedMustBe: usize = 7;
const SIZE_OF_EACH_BUG_SCREEN_MESSAGE: usize = 100;
const commonBugScreenMessages = @extern([*c]const [SIZE_OF_EACH_BUG_SCREEN_MESSAGE]u8, .{ .name = "commonBugScreenMessages" });
const displayBugScreen = abi.host.showBugScreen; // routed through the host-callback boundary
extern var errorMessage: [*c]u8;
extern fn sprintf(buffer: [*c]u8, format: [*c]const u8, ...) c_int;

fn bugFormat(row: usize) [*c]const u8 {
    return @ptrCast(&commonBugScreenMessages[row]);
}

pub fn reportNoNamedVariablesBug(function_name: [*:0]const u8) void {
    _ = sprintf(errorMessage, bugFormat(bugMsgNoNamedVariables), function_name);
    displayBugScreen(errorMessage);
}

pub fn reportRegisterAboveLastBug(function_name: [*:0]const u8, reg: stack_runtime.calcRegister_t, limit: stack_runtime.calcRegister_t) void {
    _ = sprintf(errorMessage, bugFormat(bugMsgRegistMustBeLessThan), function_name, @as(c_int, reg), @as(c_int, limit));
    displayBugScreen(errorMessage);
}

pub fn reportVariableNotDefinedBug(function_name: [*:0]const u8, variable_kind: [*:0]const u8, index: u16, last_index: u16) void {
    _ = sprintf(errorMessage, bugFormat(bugMsgNotDefinedMustBe), function_name, variable_kind, @as(c_int, index), @as(c_int, last_index));
    displayBugScreen(errorMessage);
}

pub fn reportDataTypeUnknownBug(function_name: [*:0]const u8, data_type_name: [*c]const u8) void {
    _ = sprintf(errorMessage, bugFormat(bugMsgDataTypeUnknown), function_name, data_type_name);
    displayBugScreen(errorMessage);
}

// The register accessors' "<kind> <n> is not defined!" hint. Unlike the bug
// screens above it is an EXTRA_INFO_ON_CALC_ERROR diagnostic, absent from the
// firmware and from the testSuite, which upstream compiles with the macro forced
// to 0: the `extra_info` test keeps the two errorMessage writes off both the way
// upstream's #if does. The moreInfoOnError symbol carries its own gate, so the
// call itself needs none. The build option is what distinguishes the testSuite
// from the sim; they share a target.
//
// The message arrives in two pieces because that is how the popup lays it out:
// the subject in the first half of errorMessage, the range in the second, and the
// two halves are handed over as separate arguments alongside the literal middle.
const extra_info: bool = build_options.extra_info_on_calc_error;
const ERROR_MESSAGE_LENGTH: usize = 512;

extern fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) void;

fn reportNotDefined(function_name: [*:0]const u8, subject_format: [*:0]const u8, index: c_int, last_index: c_int) void {
    const range = errorMessage + ERROR_MESSAGE_LENGTH / 2;
    _ = sprintf(errorMessage, subject_format, index);
    _ = sprintf(range, "Must be from 0 to %u", last_index);
    moreInfoOnError(function_name, @ptrCast(errorMessage), "is not defined!", @ptrCast(range));
}

pub fn reportNamedVariableNotDefined(function_name: [*:0]const u8, index: u16, last_index: u16) void {
    if (comptime extra_info) {
        reportNotDefined(function_name, "named variable %d", @as(c_int, @as(i16, @bitCast(index))), @as(c_int, last_index));
    }
}

pub fn reportLocalRegisterNotDefined(function_name: [*:0]const u8, index: u16, last_index: u8) void {
    if (comptime extra_info) {
        reportNotDefined(function_name, "local register %d", @as(c_int, @as(i16, @bitCast(index))), @as(c_int, last_index));
    }
}

fn reportError(error_code: u8) void {
    displayCalcErrorMessage(
        error_code,
        stack_runtime.REGISTER_Z,
        REGISTER_X,
    );
}

pub fn reportRamFull() void {
    reportError(stack_runtime.ERROR_RAM_FULL);
}

/// A reserved variable owns a fixed block named by a const header, so there is
/// nothing to free, allocate or retype; reallocateRegister refuses instead.
pub fn reportReservedVariableRetype() void {
    reportError(stack_runtime.ERROR_INVALID_DATA_TYPE_FOR_OP);
}

pub fn reportInvalidName(error_invalid_name: u8) void {
    reportError(error_invalid_name);
}

pub fn reportUndefSourceVar(error_undef_source_var: u8) void {
    reportError(error_undef_source_var);
}

pub fn reportCannotDeletePredefItem(error_cannot_delete_predef_item: u8) void {
    reportError(error_cannot_delete_predef_item);
}

pub fn reportTooManyVariables(error_too_many_variables: u8) void {
    reportError(error_too_many_variables);
}
