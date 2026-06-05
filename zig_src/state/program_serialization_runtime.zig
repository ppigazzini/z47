const io_owned = @import("program_serialization_io_owned.zig");

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

const END_OPCODE_HIGH: u8 = 0x85;
const END_OPCODE_LOW: u8 = 0xB2;

fn lineEqualsZ(line: [*c]const u8, expected: [*c]const u8) bool {
    var idx: usize = 0;
    while (true) : (idx += 1) {
        const a = line[idx];
        const b = expected[idx];
        if (a != b) return false;
        if (a == 0) return true;
    }
}

fn parseU32LineZ(line: [*c]const u8) u32 {
    var value: u32 = 0;
    var idx: usize = 0;

    while (line[idx] >= '0' and line[idx] <= '9') : (idx += 1) {
        value = value * 10 + (line[idx] - '0');
    }

    return value;
}

fn parseU8LineZ(line: [*c]const u8) u8 {
    return @intCast(parseU32LineZ(line));
}

fn isAtEndOfProgramZ(step: [*c]const u8) bool {
    return step[0] == END_OPCODE_HIGH and step[1] == END_OPCODE_LOW;
}

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
    io_owned.readLineInto(buffer.ptr);
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
    io_owned.scanLabelsAndPrograms();
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

pub inline fn parseU32Line(line: [*c]const u8) u32 {
    return parseU32LineZ(line);
}

pub inline fn parseU8Line(line: [*c]const u8) u8 {
    return parseU8LineZ(line);
}

pub inline fn lineEquals(line: [*c]const u8, expected: [*c]const u8) bool {
    return lineEqualsZ(line, expected);
}
