const std = @import("std");
const abi = @import("abi");
const builtin = @import("builtin");
// No harness fork here. The parity lane used to build this owner with
// `use_fake_program_serialization_harness_surface`, which replaced twenty of the
// helpers below with counting stubs -- so the lane compared c43 against a build
// of the owner that never ran selectProgram, the label walk, or the pre-load
// screening pass at all. Now that the oracle IS c43's saveRestorePrograms.c
//, the harness supplies ioFileOpen / readLine /
// scanLabelsAndPrograms / show_warning and the rest under their real c43 names,
// and both sides run their production path through the same environment.

const is_dmcp_build = builtin.target.os.tag == .freestanding;
const build_options = @import("program_serialization_build_options");
const state_old_hw = @hasDecl(build_options, "state_old_hw") and build_options.state_old_hw;

const REGISTER_X: i16 = 100;
const REGISTER_Z: i16 = 102;
const ERR_REGISTER_LINE: i16 = REGISTER_Z;

const FIRST_LABEL: u16 = 2200;
const LAST_LABEL: u16 = 6999;
// defines.h: 16384 blocks on DM42 (DMCP without NEW_HW), 65534 everywhere else.
// 65535 is excluded throughout because it is the C47_NULL pointer value.
const RAM_SIZE_IN_BLOCKS: u16 = if (is_dmcp_build and state_old_hw) 16384 else 65534;

const ioPathLoadProgram: c_int = 11;
const ioModeWrite: c_int = 1;
const ioModeRead: c_int = 0;

const ERROR_OUT_OF_RANGE: u8 = 8;
const ERROR_RAM_FULL: u8 = 11;
const ERROR_INVALID_CORRUPTED_DATA: u8 = 18;
const ERROR_CANNOT_READ_FILE: u8 = 35;
const ERROR_CANNOT_WRITE_FILE: u8 = 55;

const C47_NULL: u32 = 65535;

const labelList_t = abi.LabelList;

const programList_t = abi.ProgramList;

// Only the fields consumed here are modelled; alpha sits at offset 4 and
// digitsSoFar at offset 12, matching upstream tamState_t.
const tamState_t = abi.TamState;

comptime {
    // Lock the upstream field layout these helpers index into. Offsets are
    // target-independent (small integers and one leading pointer-aligned field).
    std.debug.assert(@offsetOf(labelList_t, "program") == 0);
    std.debug.assert(@offsetOf(labelList_t, "step") == 4);
    std.debug.assert(@offsetOf(labelList_t, "labelPointer") == 8);
    std.debug.assert(@offsetOf(programList_t, "step") == 0);
    std.debug.assert(@offsetOf(tamState_t, "alpha") == 4);
    std.debug.assert(@offsetOf(tamState_t, "digitsSoFar") == 12);
}

extern var labelList: ?[*]labelList_t;
extern var programList: ?[*]programList_t;
extern var tam: tamState_t;
pub extern var dynamicMenuItem: i16;
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

// The RTF export half. `tmpString` is the shared scratch buffer
// decodeOneStep_XPORT and stringToRTF both write through, so the export path has
// to use it rather than a private buffer.
pub const TMP_STR_LENGTH: usize = 2560;
extern var tmpString: [*c]u8;
extern var lastFunc: i16;

extern fn decodeOneStep_XPORT(step: [*c]u8) void;
extern fn stringToRTF(str: [*c]const u8, rtf: [*c]u8) void;
extern fn findNextStep(step: [*c]u8) [*c]u8;
extern fn defineFirstDisplayedStep() void;
extern fn getNumberOfSteps() u16;
extern fn _getProgramSize() u32;
extern fn printProgram(list: bool, lines: u16) void;
extern fn getSystemFlag(sf: i32) bool;

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
extern fn ioFileSeek(position: u32) void;
extern fn getFreeRamMemory() u32;

// power_check_screen is a DMCP function-table macro, not a link symbol; the Zig
// ROM-HAL trampoline (no-op on host) supplies it.
const rom = @import("dmcp_rom");

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
    return rom.power_check_screen();
}

pub fn selectProgram(label: u16) void {
    dynamicMenuItem = -1;

    if (label == 0 and !tam.alpha and tam.digitsSoFar == 0) {
        const untitled = "untitled";
        @memcpy(tmpStringLabelOrVariableName[0..untitled.len], untitled);
        tmpStringLabelOrVariableName[untitled.len] = 0;

        const labels = labelList orelse return;
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
        return;
    }

    if (label >= FIRST_LABEL and label <= LAST_LABEL) {
        fnGoto(label);
        const labels = labelList orelse return;
        copyLabelName(labels[label - FIRST_LABEL].labelPointer);
        return;
    }

    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
}

pub fn openSaveProgram(path: c_int) c_int {
    return ioFileOpen(path, ioModeWrite);
}

// Copies the i-th label's name into buf when it is a global label (step > 0),
// returning false otherwise. Mirrors the per-label setup in fnSaveAllPrograms.
pub fn globalLabelNameAt(i: u16, buf: *[256]u8) bool {
    // Product-only: the parity/fake harness does not provide labelList/xcopy, so
    // keep their references behind the comptime gate (as the other helpers do).
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
    return ioFileOpen(ioPathLoadProgram, ioModeRead);
}

pub fn writeLiteral(text: [*c]const u8) void {
    ioFileWrite(text, @intCast(cStringLength(text)));
}

pub fn writeU32Line(value: u32) void {
    var buffer: [64]u8 = undefined;
    const line = std.fmt.bufPrint(&buffer, "{d}\n", .{value}) catch return;
    ioFileWrite(line.ptr, @intCast(line.len));
}

pub fn writeU8Line(value: u8) void {
    var buffer: [32]u8 = undefined;
    const line = std.fmt.bufPrint(&buffer, "{d}\n", .{value}) catch return;
    ioFileWrite(line.ptr, @intCast(line.len));
}

// tmpString accessors. Every one of them clamps at TMP_STR_LENGTH - 1 and keeps
// the terminator: upstream's stringCopy has no bound, and a decoded step longer
// than the buffer would run past it.
pub fn tmpStringContent() []const u8 {
    return tmpString[0..cStringLength(tmpString)];
}

pub fn tmpStringSet(text: []const u8) void {
    const n = @min(text.len, TMP_STR_LENGTH - 1);
    @memcpy(tmpString[0..n], text[0..n]);
    tmpString[n] = 0;
}

pub fn tmpStringAppend(text: []const u8) void {
    const at = cStringLength(tmpString);
    if (at + 1 >= TMP_STR_LENGTH) return;
    const n = @min(text.len, TMP_STR_LENGTH - 1 - at);
    @memcpy(tmpString[at..][0..n], text[0..n]);
    tmpString[at + n] = 0;
}

/// Shift tmpString right by `indent` bytes and fill the gap with spaces, using
/// `scratch` as the intermediate copy exactly as fnPExport uses asciiString.
pub fn tmpStringIndent(indent: usize, scratch: []u8) void {
    const len = @min(cStringLength(tmpString), scratch.len - 1);
    @memcpy(scratch[0..len], tmpString[0..len]);
    scratch[len] = 0;
    const n = @min(len, TMP_STR_LENGTH - 1 - indent);
    @memcpy(tmpString[indent..][0..n], scratch[0..n]);
    tmpString[indent + n] = 0;
    var ii: usize = 0;
    while (ii < indent) : (ii += 1) {
        tmpString[ii] = ' ';
    }
}

pub fn writeTmpString() void {
    ioFileWrite(tmpString, @intCast(cStringLength(tmpString)));
}

pub fn tmpStringToRTFInPlace(source: [*c]const u8) void {
    stringToRTF(source, tmpString);
}

pub fn decodeStepForExport(step: [*c]u8) void {
    decodeOneStep_XPORT(step);
}

pub fn nextStep(step: [*c]u8) [*c]u8 {
    return findNextStep(step);
}

pub fn defineFirstStep() void {
    defineFirstDisplayedStep();
}

pub fn numberOfSteps() u16 {
    return getNumberOfSteps();
}

pub fn programSize() u32 {
    return _getProgramSize();
}

pub fn systemFlag(sf: i32) bool {
    return getSystemFlag(sf);
}

pub fn lastFunction() i16 {
    return lastFunc;
}

pub fn printProgramListing(list: bool, lines: u16) void {
    printProgram(list, lines);
}

pub fn readLineInto(buffer: [*c]u8, maxLen: usize) void {
    readLine(buffer, maxLen);
}

pub fn closeFile() void {
    ioFileClose();
}

pub fn displayWriteError() void {
    displayCalcErrorMessage(ERROR_CANNOT_WRITE_FILE, ERR_REGISTER_LINE, REGISTER_X);
}

extern fn printf(fmt: [*:0]const u8, ...) c_int;
extern fn fflush(stream: ?*anyopaque) c_int;
extern fn stringToASCII(str: [*c]const u8, ascii: [*c]u8) void;

pub const is_host_build = !is_dmcp_build;

/// The two stdout lines the simulator's export-all walk prints per label. Host
/// only: `fnSaveAllPrograms` does not exist on the firmware at all.
pub fn reportProgramExported(label: u16, program_number: u16, name: [*c]const u8) void {
    var ascii_name: [500]u8 = undefined;
    stringToASCII(name, &ascii_name);
    _ = printf("Export & saving labelnumber %5i in program number %5u: Files %s.p47 %s.rtf\n", @as(c_int, label), @as(c_uint, program_number), &ascii_name, &ascii_name);
    _ = fflush(null);
}

pub fn reportProgramNotExported(program_number: u16, name: [*c]const u8) void {
    var ascii_name: [500]u8 = undefined;
    stringToASCII(name, &ascii_name);
    _ = printf("   Not saved: %s is not the first label in program %5u.\n", &ascii_name, @as(c_uint, program_number));
    _ = fflush(null);
}

/// The export path's open failure: the simulator says so on stdout before the
/// calculator error, the firmware only raises the error.
pub fn displayExportWriteError() void {
    if (comptime !is_dmcp_build) {
        _ = printf("Cannot export program!\n");
    }
    displayCalcErrorMessage(ERROR_CANNOT_WRITE_FILE, ERR_REGISTER_LINE, REGISTER_X);
}

pub fn displayReadError() void {
    displayCalcErrorMessage(ERROR_CANNOT_READ_FILE, ERR_REGISTER_LINE, REGISTER_X);
}

pub fn displayRamFullError() void {
    displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, REGISTER_X);
}

pub fn displayCorruptedDataError() void {
    displayCalcErrorMessage(ERROR_INVALID_CORRUPTED_DATA, ERR_REGISTER_LINE, REGISTER_X);
}

pub fn getFreeRamMemoryBytes() u32 {
    return getFreeRamMemory();
}

pub fn seekLoadFileStart() void {
    ioFileSeek(0);
}

pub fn showWarning(message: [*c]const u8) void {
    var warning: [256]u8 = undefined;
    var idx: usize = 0;
    while (idx < warning.len - 1 and message[idx] != 0) : (idx += 1) {
        warning[idx] = message[idx];
    }
    warning[idx] = 0;
    show_warning(&warning);
}

pub fn scanLabelsAndPrograms() void {
    scanLabelsAndProgramsC();
}

pub fn goToLastProgram() void {
    if (numberOfPrograms > 0) {
        const programs = programList orelse return;
        goToGlobalStep(programs[numberOfPrograms - 1].step);
    }
}

pub fn getRamSizeInBlocks() u16 {
    return RAM_SIZE_IN_BLOCKS;
}

pub fn toC47MemPtr(mem_ptr: [*c]const u8) u16 {
    if (mem_ptr == null) {
        return @intCast(C47_NULL);
    }
    return @intCast((@intFromPtr(mem_ptr) - @intFromPtr(ram)) / @sizeOf(u32));
}
