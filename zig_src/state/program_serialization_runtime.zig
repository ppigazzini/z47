const io_owned = @import("program_serialization_runtime_io_owned.zig");
const state_owned = @import("program_serialization_runtime_state_owned.zig");

pub const FILE_OK: c_int = 1;
pub const FILE_CANCEL: c_int = 2;
pub const BACKUP_FORMAT: u8 = 0;
pub const PROGRAM_VERSION: u32 = 1;
pub const OLDEST_COMPATIBLE_PROGRAM_VERSION: u32 = 1;
pub const ITM_END: u16 = 1458;
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
pub extern var temporaryInformation: u8;

pub extern fn resizeProgramMemory(newSizeInBlocks: u16) void;
pub inline fn checkPower() bool {
    return io_owned.checkPower();
}

pub inline fn selectProgram(label: u16) bool {
    return io_owned.selectProgram(label);
}

pub inline fn openSaveProgram() c_int {
    return io_owned.openSaveProgram();
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

pub inline fn readLine(buffer: []u8) void {
    io_owned.readLine(buffer);
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

pub inline fn showWarning(message: [*c]const u8) void {
    io_owned.showWarning(message);
}

pub inline fn scanLabelsAndPrograms() void {
    state_owned.scanLabelsAndPrograms();
}

pub inline fn goToLastProgram() void {
    state_owned.goToLastProgram();
}

pub inline fn isAtEndOfProgram(step: [*c]const u8) bool {
    return state_owned.isAtEndOfProgram(step);
}

pub inline fn getRamSizeInBlocks() u16 {
    return state_owned.getRamSizeInBlocks();
}

pub inline fn toC47MemPtr(mem_ptr: [*c]const u8) u16 {
    return state_owned.toC47MemPtr(mem_ptr);
}

pub inline fn parseU32Line(line: [*c]const u8) u32 {
    return state_owned.parseU32Line(line);
}

pub inline fn parseU8Line(line: [*c]const u8) u8 {
    return state_owned.parseU8Line(line);
}

pub inline fn lineEquals(line: [*c]const u8, expected: [*c]const u8) bool {
    return state_owned.lineEquals(line, expected);
}
