const std = @import("std");
const abi = @import("abi");
const builtin = @import("builtin");
const build_options = @import("program_serialization_build_options");

pub const use_fake_program_serialization_harness_surface =
    @hasDecl(build_options, "use_fake_program_serialization_harness_surface") and
    build_options.use_fake_program_serialization_harness_surface;

const is_dmcp_build = builtin.target.os.tag == .freestanding;

const REGISTER_X: i16 = 100;
const REGISTER_Z: i16 = 102;
const ERR_REGISTER_LINE: i16 = REGISTER_Z;

const FIRST_LABEL: u16 = 2200;
const LAST_LABEL: u16 = 6999;
const RAM_SIZE_IN_BLOCKS: u16 = 65534;

const ioPathLoadProgram: c_int = 11;
const ioModeWrite: c_int = 1;
const ioModeRead: c_int = 0;

const ERROR_OUT_OF_RANGE: u8 = 8;
const ERROR_CANNOT_READ_FILE: u8 = 35;
const ERROR_CANNOT_WRITE_FILE: u8 = 55;

const C47_NULL: u32 = 65535;

const labelList_t = abi.LabelList;

const programList_t = abi.ProgramList;

// Only the fields consumed here are modelled; alpha sits at offset 4 and
// digitsSoFar at offset 10, matching upstream tamState_t.
const tamState_t = abi.TamState;

comptime {
    // Lock the upstream field layout these helpers index into. Offsets are
    // target-independent (small integers and one leading pointer-aligned field).
    std.debug.assert(@offsetOf(labelList_t, "program") == 0);
    std.debug.assert(@offsetOf(labelList_t, "step") == 4);
    std.debug.assert(@offsetOf(labelList_t, "labelPointer") == 8);
    std.debug.assert(@offsetOf(programList_t, "step") == 0);
    std.debug.assert(@offsetOf(tamState_t, "alpha") == 4);
    std.debug.assert(@offsetOf(tamState_t, "digitsSoFar") == 10);
}

extern var labelList: ?[*]labelList_t;
extern var programList: ?[*]programList_t;
extern var tam: tamState_t;
extern var dynamicMenuItem: i16;
extern var numberOfLabels: u16;
extern var numberOfPrograms: u16;
extern var currentProgramNumber: u16;
extern var tmpStringLabelOrVariableName: [*c]u8;
extern var ram: [*c]u32;
extern var firstFreeProgramByte: [*c]u8;

// Mirror of manage.c's boundProgramNameLength: clamp a program-step name length
// to the bytes that remain before firstFreeProgramByte so a corrupt or imported
// program cannot make a name read run past the program region.
fn boundProgramNameLength(name_start: [*c]const u8, claimed: u8) u8 {
    if (@intFromPtr(name_start) >= @intFromPtr(firstFreeProgramByte)) {
        return 0;
    }
    if (claimed > @intFromPtr(firstFreeProgramByte) - @intFromPtr(name_start)) {
        return @intCast(@intFromPtr(firstFreeProgramByte) - @intFromPtr(name_start));
    }
    return claimed;
}

extern fn ioFileOpen(path: c_int, mode: c_int) c_int;
extern fn ioFileWrite(buffer: ?*const anyopaque, size: u32) void;
extern fn ioFileClose() void;
extern fn show_warning(string: [*c]u8) void;
const scanLabelsAndProgramsC = @extern(*const fn () callconv(.c) void, .{ .name = "scanLabelsAndPrograms" });
extern fn goToGlobalStep(step: i32) void;
extern fn fnGoto(label: u16) void;
extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: i16, err_register_line: i16) void;
extern fn xcopy(dest: ?*anyopaque, source: ?*const anyopaque, n: u32) ?*anyopaque;
extern fn readLine(line: [*c]u8, maxLen: usize) void;

extern fn z47_program_serialization_runtime_check_power() bool;
extern fn z47_program_serialization_runtime_select_program(label: u16) bool;
extern fn z47_program_serialization_runtime_open_save_program() c_int;
extern fn z47_program_serialization_runtime_open_load_program() c_int;
extern fn z47_program_serialization_runtime_write_literal(text: [*c]const u8) void;
extern fn z47_program_serialization_runtime_write_u32_line(value: u32) void;
extern fn z47_program_serialization_runtime_write_u8_line(value: u8) void;
extern fn z47_program_serialization_runtime_read_line(buffer: [*c]u8) void;
extern fn z47_program_serialization_runtime_close_file() void;
extern fn z47_program_serialization_runtime_display_write_error() void;
extern fn z47_program_serialization_runtime_display_read_error() void;
extern fn z47_program_serialization_runtime_show_warning(message: [*c]const u8) void;
extern fn z47_program_serialization_runtime_scan_labels_and_programs() void;
extern fn z47_program_serialization_runtime_go_to_last_program() void;
extern fn z47_program_serialization_runtime_get_ram_size_in_blocks() u16;
extern fn z47_program_serialization_runtime_to_c47_mem_ptr(mem_ptr: [*c]const u8) u16;

// power_check_screen is a DMCP function-table macro, not a link symbol; the Zig
// ROM-HAL trampoline (no-op on host) replaces the retired C bridge shim.
const rom = @import("state_dmcp_rom.zig");

fn cStringLength(text: [*c]const u8) usize {
    var len: usize = 0;
    while (text[len] != 0) : (len += 1) {}
    return len;
}

fn copyLabelName(label_ptr: ?[*]u8) void {
    const ptr = label_ptr orelse return;
    const len = boundProgramNameLength(ptr + 1, ptr[0]);
    _ = xcopy(tmpStringLabelOrVariableName, ptr + 1, len);
    tmpStringLabelOrVariableName[len] = 0;
}

pub fn checkPower() bool {
    if (use_fake_program_serialization_harness_surface) {
        return z47_program_serialization_runtime_check_power();
    }
    return rom.power_check_screen();
}

pub fn selectProgram(label: u16) bool {
    if (use_fake_program_serialization_harness_surface) {
        return z47_program_serialization_runtime_select_program(label);
    }

    dynamicMenuItem = -1;

    if (label == 0 and !tam.alpha and tam.digitsSoFar == 0) {
        const untitled = "untitled";
        @memcpy(tmpStringLabelOrVariableName[0..untitled.len], untitled);
        tmpStringLabelOrVariableName[untitled.len] = 0;

        const labels = labelList orelse return true;
        var current_label: u16 = 0;
        while (current_label < numberOfLabels) : (current_label += 1) {
            if (labels[current_label].program == currentProgramNumber) {
                break;
            }
        }
        while (current_label < numberOfLabels) : (current_label += 1) {
            if (labels[current_label].step > 0) {
                copyLabelName(labels[current_label].labelPointer);
                break;
            }
        }
        return true;
    }

    if (label >= FIRST_LABEL and label <= LAST_LABEL) {
        fnGoto(label);
        const labels = labelList orelse return true;
        copyLabelName(labels[label - FIRST_LABEL].labelPointer);
        return true;
    }

    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    return false;
}

pub fn openSaveProgram(path: c_int) c_int {
    if (use_fake_program_serialization_harness_surface) {
        return z47_program_serialization_runtime_open_save_program();
    }
    return ioFileOpen(path, ioModeWrite);
}

// Copies the i-th label's name into buf when it is a global label (step > 0),
// returning false otherwise. Mirrors the per-label setup in fnSaveAllPrograms.
pub fn globalLabelNameAt(i: u16, buf: *[256]u8) bool {
    // Product-only: the parity/fake harness does not provide labelList/xcopy, so
    // keep their references behind the comptime gate (as the other helpers do).
    if (use_fake_program_serialization_harness_surface) {
        return false;
    }
    const labels = labelList orelse return false;
    if (labels[i].step <= 0) return false;
    const lp = labels[i].labelPointer;
    if (lp == null) return false;
    const len = boundProgramNameLength(lp + 1, lp[0]);
    _ = xcopy(buf, lp + 1, len);
    buf[len] = 0;
    return true;
}

pub fn openLoadProgram() c_int {
    if (use_fake_program_serialization_harness_surface) {
        return z47_program_serialization_runtime_open_load_program();
    }
    return ioFileOpen(ioPathLoadProgram, ioModeRead);
}

pub fn writeLiteral(text: [*c]const u8) void {
    if (use_fake_program_serialization_harness_surface) {
        z47_program_serialization_runtime_write_literal(text);
        return;
    }
    ioFileWrite(text, @intCast(cStringLength(text)));
}

pub fn writeU32Line(value: u32) void {
    if (use_fake_program_serialization_harness_surface) {
        z47_program_serialization_runtime_write_u32_line(value);
        return;
    }
    var buffer: [64]u8 = undefined;
    const line = std.fmt.bufPrint(&buffer, "{d}\n", .{value}) catch return;
    ioFileWrite(line.ptr, @intCast(line.len));
}

pub fn writeU8Line(value: u8) void {
    if (use_fake_program_serialization_harness_surface) {
        z47_program_serialization_runtime_write_u8_line(value);
        return;
    }
    var buffer: [32]u8 = undefined;
    const line = std.fmt.bufPrint(&buffer, "{d}\n", .{value}) catch return;
    ioFileWrite(line.ptr, @intCast(line.len));
}

pub fn readLineInto(buffer: [*c]u8, maxLen: usize) void {
    if (use_fake_program_serialization_harness_surface) {
        z47_program_serialization_runtime_read_line(buffer);
        return;
    }
    readLine(buffer, maxLen);
}

pub fn closeFile() void {
    if (use_fake_program_serialization_harness_surface) {
        z47_program_serialization_runtime_close_file();
        return;
    }
    ioFileClose();
}

pub fn displayWriteError() void {
    if (use_fake_program_serialization_harness_surface) {
        z47_program_serialization_runtime_display_write_error();
        return;
    }
    displayCalcErrorMessage(ERROR_CANNOT_WRITE_FILE, ERR_REGISTER_LINE, REGISTER_X);
}

pub fn displayReadError() void {
    if (use_fake_program_serialization_harness_surface) {
        z47_program_serialization_runtime_display_read_error();
        return;
    }
    displayCalcErrorMessage(ERROR_CANNOT_READ_FILE, ERR_REGISTER_LINE, REGISTER_X);
}

pub fn showWarning(message: [*c]const u8) void {
    if (use_fake_program_serialization_harness_surface) {
        z47_program_serialization_runtime_show_warning(message);
        return;
    }
    var warning: [256]u8 = undefined;
    var idx: usize = 0;
    while (idx < warning.len - 1 and message[idx] != 0) : (idx += 1) {
        warning[idx] = message[idx];
    }
    warning[idx] = 0;
    show_warning(&warning);
}

pub fn scanLabelsAndPrograms() void {
    if (use_fake_program_serialization_harness_surface) {
        z47_program_serialization_runtime_scan_labels_and_programs();
        return;
    }
    scanLabelsAndProgramsC();
}

pub fn goToLastProgram() void {
    if (use_fake_program_serialization_harness_surface) {
        z47_program_serialization_runtime_go_to_last_program();
        return;
    }
    if (numberOfPrograms > 0) {
        const programs = programList orelse return;
        goToGlobalStep(programs[numberOfPrograms - 1].step);
    }
}

pub fn getRamSizeInBlocks() u16 {
    if (use_fake_program_serialization_harness_surface) {
        return z47_program_serialization_runtime_get_ram_size_in_blocks();
    }
    return RAM_SIZE_IN_BLOCKS;
}

pub fn toC47MemPtr(mem_ptr: [*c]const u8) u16 {
    if (use_fake_program_serialization_harness_surface) {
        return z47_program_serialization_runtime_to_c47_mem_ptr(mem_ptr);
    }
    if (mem_ptr == null) {
        return @intCast(C47_NULL);
    }
    return @intCast((@intFromPtr(mem_ptr) - @intFromPtr(ram)) / @sizeOf(u32));
}
