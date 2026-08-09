const io_owned = @import("program_serialization_io.zig");
const line_parse = @import("abi").line_parse; // shared std-only line match / integer parse

pub const FILE_OK: c_int = 1;
pub const FILE_CANCEL: c_int = 2;
pub const BACKUP_FORMAT: u8 = 0;
pub const PROGRAM_VERSION: u32 = 1;
pub const OLDEST_COMPATIBLE_PROGRAM_VERSION: u32 = 1;
pub const ITM_END: u16 = 1458;
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

pub extern fn resizeProgramMemory(newSizeInBlocks: u16) void;
pub const GLOBAL_LABELS: u8 = 253; // namedLabels_t: STRING_LABEL_VARIABLE
pub extern fn findNamedLabel(labelName: [*c]const u8, labelType: u8) u16;

pub const ioPathSaveProgram: c_int = 8;
pub const ioPathSaveAllPrograms: c_int = 12;

const END_OPCODE_HIGH: u8 = 0x85;
const END_OPCODE_LOW: u8 = 0xB2;

fn isAtEndOfProgramZ(step: [*c]const u8) bool {
    return step[0] == END_OPCODE_HIGH and step[1] == END_OPCODE_LOW;
}

pub inline fn checkPower() bool {
    return io_owned.checkPower();
}

pub inline fn selectProgram(label: u16) void {
    io_owned.selectProgram(label);
}

pub inline fn openSaveProgram(path: c_int) c_int {
    return io_owned.openSaveProgram(path);
}

pub inline fn globalLabelNameAt(i: u16, buf: *[256]u8) bool {
    return io_owned.globalLabelNameAt(i, buf);
}

pub inline fn openLoadProgram() c_int {
    return io_owned.openLoadProgram();
}

pub inline fn writeLiteral(text: [*c]const u8) void {
    io_owned.writeLiteral(text);
}

pub inline fn writeU32Line(value: u32) void {
    io_owned.writeU32Line(value);
}

pub inline fn writeU8Line(value: u8) void {
    io_owned.writeU8Line(value);
}

pub const TI_PRINT_COMPLETE: u8 = 136;
pub const EXPORT_VERSION: u32 = 3;
pub const FLAG_PRTACT: i32 = 0xc020;
pub const ITM_PRINTERPROG: i16 = 1713;
/// print.h's `list` argument: PROG lists a program, ALPHA lists the alpha register.
pub const PROG: bool = false;
pub const ioPathExportRTFProgram: c_int = 10;
pub const ioPathExportRTFAllPrograms: c_int = 13;

pub extern var firstDisplayedLocalStepNumber: u16;
pub extern var programListEnd: bool;
pub extern var lastProgramListEnd: bool;

pub inline fn tmpStringContent() []const u8 {
    return io_owned.tmpStringContent();
}

pub inline fn tmpStringSet(text: []const u8) void {
    io_owned.tmpStringSet(text);
}

pub inline fn tmpStringAppend(text: []const u8) void {
    io_owned.tmpStringAppend(text);
}

pub inline fn tmpStringIndent(indent: usize, scratch: []u8) void {
    io_owned.tmpStringIndent(indent, scratch);
}

pub inline fn writeTmpString() void {
    io_owned.writeTmpString();
}

pub inline fn tmpStringToRTFInPlace(source: [*c]const u8) void {
    io_owned.tmpStringToRTFInPlace(source);
}

pub inline fn decodeStepForExport(step: [*c]u8) void {
    io_owned.decodeStepForExport(step);
}

pub inline fn nextStep(step: [*c]u8) [*c]u8 {
    return io_owned.nextStep(step);
}

pub inline fn defineFirstStep() void {
    io_owned.defineFirstStep();
}

pub inline fn numberOfSteps() u16 {
    return io_owned.numberOfSteps();
}

pub inline fn programSize() u32 {
    return io_owned.programSize();
}

pub inline fn systemFlag(sf: i32) bool {
    return io_owned.systemFlag(sf);
}

pub inline fn lastFunction() i16 {
    return io_owned.lastFunction();
}

pub inline fn printProgramListing(list: bool, lines: u16) void {
    io_owned.printProgramListing(list, lines);
}

pub inline fn displayExportWriteError() void {
    io_owned.displayExportWriteError();
}

pub const is_host_build = io_owned.is_host_build;

pub inline fn reportProgramExported(label: u16, program_number: u16, name: [*c]const u8) void {
    io_owned.reportProgramExported(label, program_number, name);
}

pub inline fn reportProgramNotExported(program_number: u16, name: [*c]const u8) void {
    io_owned.reportProgramNotExported(program_number, name);
}

pub inline fn readLine(buffer: []u8) void {
    io_owned.readLineInto(buffer.ptr, buffer.len);
}

pub inline fn closeFile() void {
    io_owned.closeFile();
}

pub inline fn displayWriteError() void {
    io_owned.displayWriteError();
}

pub inline fn displayReadError() void {
    io_owned.displayReadError();
}

pub inline fn displayRamFullError() void {
    io_owned.displayRamFullError();
}

pub inline fn displayCorruptedDataError() void {
    io_owned.displayCorruptedDataError();
}

pub inline fn getFreeRamMemoryBytes() u32 {
    return io_owned.getFreeRamMemoryBytes();
}

pub inline fn seekLoadFileStart() void {
    io_owned.seekLoadFileStart();
}

pub inline fn showWarning(message: [*c]const u8) void {
    io_owned.showWarning(message);
}

pub inline fn scanLabelsAndPrograms() void {
    io_owned.scanLabelsAndPrograms();
}

/// goToGlobalStep reads a dynamic-menu label whenever this is >= 0; a load
/// clears it so the step it lands on is the program's own.
pub inline fn setDynamicMenuItemNone() void {
    io_owned.dynamicMenuItem = -1;
}

pub inline fn goToLastProgram() void {
    io_owned.goToLastProgram();
}

pub inline fn isAtEndOfProgram(step: [*c]const u8) bool {
    return isAtEndOfProgramZ(step);
}

pub inline fn getRamSizeInBlocks() u16 {
    return io_owned.getRamSizeInBlocks();
}

pub inline fn toC47MemPtr(mem_ptr: [*c]const u8) u16 {
    return io_owned.toC47MemPtr(mem_ptr);
}

pub inline fn parseU32Line(line: []const u8) u32 {
    return line_parse.parseU32(line);
}

pub inline fn parseU8Line(line: []const u8) u8 {
    return line_parse.parseU8(line);
}

pub inline fn lineEquals(line: []const u8, expected: []const u8) bool {
    return line_parse.equals(line, expected);
}
