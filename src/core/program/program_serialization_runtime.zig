// SPDX-License-Identifier: GPL-3.0-only
const io_owned = @import("program_serialization_io.zig");
const build_options = @import("program_serialization_build_options");
const abi = @import("abi");
const line_parse = abi.line_parse; // shared std-only line match / integer parse

pub const FILE_OK: c_int = 1;
pub const FILE_CANCEL: c_int = 2;
pub const BACKUP_FORMAT: u8 = 0;
pub const PROGRAM_VERSION: u32 = 1;
pub const OLDEST_COMPATIBLE_PROGRAM_VERSION: u32 = 1;
pub const ITM_END: u16 = 1458;
pub const ITM_LBL: u16 = 1;

// OPTION_STRUCTURED_PGM, and with it OPTION_STRUCT_INDENT, which structured.h
// defines inside the same guard: the listing indents a structure's body, and a
// program carrying an unnumbered structure is refused rather than written.
pub const option_structured_pgm: bool = build_options.option_structured_pgm;
pub const ir_printing: bool = build_options.ir_printing;
pub const option_struct_indent: bool = option_structured_pgm;
pub const XPORTP_STRUCT_INDENT: i8 = 2; // spaces a structure indents its body by in an exported listing
pub const XPORTP_MAX_STRUCT_LEVELS: i8 = 99; // a file has no width limit, so this is effectively no limit

// structured.c's predicates. They answer for every build; without the option they
// report that there is nothing to indent and nothing to refuse.
pub extern fn structDisplayOutdent(step: [*c]u8) u8;
pub extern fn structStepOpensIndent(step: [*c]u8) u8;
pub extern fn structStepClosesIndent(step: [*c]u8) u8;
pub extern fn structProgramHasUnnumbered() u8;
pub extern fn fnValid(unusedButMandatoryParameter: u16) void;
pub const TI_NO_INFO: u8 = 0;
pub const TI_SAVED: u8 = 32;
pub const TI_PROGRAM_LOADED: u8 = 86;
pub const BPB: u6 = 2;
pub const BYTES_PER_BLOCK: usize = 1 << BPB;

pub extern var beginOfCurrentProgram: [*c]u8;
pub extern var endOfCurrentProgram: [*c]u8;
pub extern var firstDisplayedStep: [*c]u8;
pub extern var currentStep: [*c]u8;
pub extern var beginOfProgramMemory: [*c]u8;
pub extern var firstFreeProgramByte: [*c]u8;
pub extern var freeProgramBytes: u16;
pub extern var currentLocalStepNumber: u16;
pub extern var currentProgramNumber: u16;
pub extern var numberOfPrograms: u16;
pub extern var numberOfLabels: u16;
pub extern var temporaryInformation: u8;
pub extern var calcMode: u8;
pub extern var lastErrorCode: u8;
pub const CM_PEM: u8 = 3;

pub extern fn resizeProgramMemory(newSizeInBlocks: u16) void;
pub extern fn defineCurrentProgramFromCurrentStep() void;
pub const GLOBAL_LABELS: u8 = 253; // namedLabels_t: STRING_LABEL_VARIABLE
pub extern fn findNamedLabel(labelName: [*c]const u8, labelType: u8) i16;

// selectProgram() goes through fnGoto(), which moves the step, the step number, the program number, the displayed step
// and its number, and the program bounds. WRITEP and XPORTP put all six back, not just the two step numbers.
pub const EditorPosition = struct {
    step: [*c]u8,
    first_displayed: [*c]u8,
    local_step_number: u16,
    first_displayed_local_step_number: u16,
    program_number: u16,

    pub fn save() EditorPosition {
        return .{
            .step = currentStep,
            .first_displayed = firstDisplayedStep,
            .local_step_number = currentLocalStepNumber,
            .first_displayed_local_step_number = firstDisplayedLocalStepNumber,
            .program_number = currentProgramNumber,
        };
    }

    pub fn restore(self: EditorPosition) void {
        currentStep = self.step;
        defineCurrentProgramFromCurrentStep(); // the program bounds follow the step
        currentLocalStepNumber = self.local_step_number;
        currentProgramNumber = self.program_number;
        firstDisplayedStep = self.first_displayed;
        firstDisplayedLocalStepNumber = self.first_displayed_local_step_number;
    }
};

pub const ioPathSaveProgram: c_int = 8;
pub const ioPathSaveAllPrograms: c_int = 12;

const ITM_END_HIGH: u8 = (ITM_END >> 8) | 0x80;
const ITM_END_LOW: u8 = ITM_END & 0xff;

// isAtEndOfProgram(step) is checkOpCodeOfStep(step, ITM_END). Bit 7 of the first byte is the two-byte-opcode marker and
// is part of the match, not masked off: without it the one-byte step ISE .66 (bytes 05 B2) reads as END. A null step
// never matches.
fn isAtEndOfProgramZ(step: [*c]const u8) bool {
    if (step == null) {
        return false;
    }
    return step[0] == ITM_END_HIGH and step[1] == ITM_END_LOW;
}

pub fn displayOperationUndefined() void {
    io_owned.displayOperationUndefined();
}

pub fn displayStructureNotNumbered() void {
    io_owned.displayStructureNotNumbered();
}

pub fn checkPower() bool {
    return io_owned.checkPower();
}

pub fn selectProgram(label: u16) void {
    io_owned.selectProgram(label);
}

pub fn openSaveProgram(path: c_int) c_int {
    return io_owned.openSaveProgram(path);
}

pub fn globalLabelNameAt(i: u16, buf: *[256]u8) bool {
    return io_owned.globalLabelNameAt(i, buf);
}

pub fn openLoadProgram() c_int {
    return io_owned.openLoadProgram();
}

pub fn writeLiteral(text: [*c]const u8) void {
    io_owned.writeLiteral(text);
}

pub fn writeU32Line(value: u32) void {
    io_owned.writeU32Line(value);
}

pub fn writeU8Line(value: u8) void {
    io_owned.writeU8Line(value);
}

pub const TI_PRINT_COMPLETE: u8 = 136;
pub const EXPORT_VERSION: u32 = 3;
pub const FLAG_PRTACT: i32 = 0xc020;
pub const FLAG_AUTOVALID: i32 = 0x8070; // VALID runs by itself on leaving the program editor
pub const NOPARAM: u16 = 9876;
pub const ERROR_NONE: u8 = 0;
pub const ITM_PRINTERPROG: i16 = 1713;
/// print.h's `list` argument: PROG lists a program, ALPHA lists the alpha register.
pub const PROG: bool = false;
pub const ioPathExportRTFProgram: c_int = 10;
pub const ioPathExportRTFAllPrograms: c_int = 13;

pub extern var firstDisplayedLocalStepNumber: u16;
pub extern var programListEnd: bool;
pub extern var programList: [*c]align(4) abi.ProgramList;
pub extern fn findNextStep(step: [*c]u8) [*c]u8;
pub extern fn isAtEndOfPrograms(step: [*c]const u8) bool;
pub extern var lastProgramListEnd: bool;

pub fn tmpStringContent() []const u8 {
    return io_owned.tmpStringContent();
}

pub fn tmpStringSet(text: []const u8) void {
    io_owned.tmpStringSet(text);
}

pub fn tmpStringAppend(text: []const u8) void {
    io_owned.tmpStringAppend(text);
}

pub fn tmpStringIndent(indent: usize, scratch: []u8) void {
    io_owned.tmpStringIndent(indent, scratch);
}

pub fn writeTmpString() void {
    io_owned.writeTmpString();
}

pub fn tmpStringToRTFInPlace(source: [*c]const u8) void {
    io_owned.tmpStringToRTFInPlace(source);
}

pub fn decodeStepForExport(step: [*c]u8) void {
    io_owned.decodeStepForExport(step);
}

pub fn nextStep(step: [*c]u8) [*c]u8 {
    return io_owned.nextStep(step);
}

pub fn defineFirstStep() void {
    io_owned.defineFirstStep();
}

pub fn numberOfSteps() u16 {
    return io_owned.numberOfSteps();
}

pub fn programSize() u32 {
    return io_owned.programSize();
}

pub fn systemFlag(sf: i32) bool {
    return io_owned.systemFlag(sf);
}

pub fn lastFunction() i16 {
    return io_owned.lastFunction();
}

pub fn printProgramListing(list: bool, lines: u16) void {
    io_owned.printProgramListing(list, lines);
}

pub fn displayExportWriteError() void {
    io_owned.displayExportWriteError();
}

pub const is_host_build = io_owned.is_host_build;

pub fn reportProgramExported(label: u16, program_number: u16, name: [*c]const u8) void {
    io_owned.reportProgramExported(label, program_number, name);
}

pub fn reportProgramNotExported(program_number: u16, name: [*c]const u8) void {
    io_owned.reportProgramNotExported(program_number, name);
}

pub fn readLine(buffer: []u8) void {
    io_owned.readLineInto(buffer.ptr, buffer.len);
}

pub fn closeFile() void {
    io_owned.closeFile();
}

pub fn displayWriteError() void {
    io_owned.displayWriteError();
}

pub fn displayReadError() void {
    io_owned.displayReadError();
}

pub fn displayRamFullError() void {
    io_owned.displayRamFullError();
}

pub fn displayCorruptedDataError() void {
    io_owned.displayCorruptedDataError();
}

pub fn getFreeRamMemoryBytes() u32 {
    return io_owned.getFreeRamMemoryBytes();
}

pub fn seekLoadFileStart() void {
    io_owned.seekLoadFileStart();
}

pub fn showWarning(message: [*c]const u8) void {
    io_owned.showWarning(message);
}

pub fn scanLabelsAndPrograms() void {
    io_owned.scanLabelsAndPrograms();
}

/// goToGlobalStep reads a dynamic-menu label whenever this is >= 0; a load
/// clears it so the step it lands on is the program's own.
pub fn setDynamicMenuItemNone() void {
    io_owned.dynamicMenuItem = -1;
}

pub fn goToLastProgram() void {
    io_owned.goToLastProgram();
}

/// checkOpCodeOfStep for a two-byte op: the 0x80 marker is part of the match.
pub fn checkOpCodeOfStep(step: [*c]const u8, op: u16) bool {
    if (step == null) {
        return false;
    }
    if (op < 128) {
        return step[0] == op;
    }
    return step[0] == ((op >> 8) | 0x80) and step[1] == (op & 0xff);
}

pub fn isAtEndOfProgram(step: [*c]const u8) bool {
    return isAtEndOfProgramZ(step);
}

pub fn getRamSizeInBlocks() u16 {
    return io_owned.getRamSizeInBlocks();
}

pub fn toC47MemPtr(mem_ptr: [*c]const u8) u16 {
    return io_owned.toC47MemPtr(mem_ptr);
}

pub fn parseU32Line(line: []const u8) u32 {
    return line_parse.parseU32(line);
}

pub fn parseU8Line(line: []const u8) u8 {
    return line_parse.parseU8(line);
}

pub fn lineEquals(line: []const u8, expected: []const u8) bool {
    return line_parse.equals(line, expected);
}
