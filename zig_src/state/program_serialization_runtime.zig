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
pub extern fn z47_program_serialization_runtime_check_power() bool;
pub extern fn z47_program_serialization_runtime_select_program(label: u16) bool;
pub extern fn z47_program_serialization_runtime_open_save_program() c_int;
pub extern fn z47_program_serialization_runtime_open_load_program() c_int;
pub extern fn z47_program_serialization_runtime_write_literal(text: [*c]const u8) void;
pub extern fn z47_program_serialization_runtime_write_u32_line(value: u32) void;
pub extern fn z47_program_serialization_runtime_write_u8_line(value: u8) void;
pub extern fn z47_program_serialization_runtime_read_line(buffer: [*c]u8) void;
pub extern fn z47_program_serialization_runtime_close_file() void;
pub extern fn z47_program_serialization_runtime_display_write_error() void;
pub extern fn z47_program_serialization_runtime_display_read_error() void;
pub extern fn z47_program_serialization_runtime_show_warning(message: [*c]const u8) void;
pub extern fn z47_program_serialization_runtime_scan_labels_and_programs() void;
pub extern fn z47_program_serialization_runtime_go_to_last_program() void;
pub extern fn z47_program_serialization_runtime_is_at_end_of_program(step: [*c]const u8) bool;
pub extern fn z47_program_serialization_runtime_get_ram_size_in_blocks() u16;
pub extern fn z47_program_serialization_runtime_to_c47_mem_ptr(mem_ptr: [*c]const u8) u16;
pub extern fn z47_program_serialization_runtime_parse_u32_line(line: [*c]const u8) u32;
pub extern fn z47_program_serialization_runtime_parse_u8_line(line: [*c]const u8) u8;
pub extern fn z47_program_serialization_runtime_line_equals(line: [*c]const u8, expected: [*c]const u8) bool;

pub inline fn checkPower() bool {
    return z47_program_serialization_runtime_check_power();
}

pub inline fn selectProgram(label: u16) bool {
    return z47_program_serialization_runtime_select_program(label);
}

pub inline fn openSaveProgram() c_int {
    return z47_program_serialization_runtime_open_save_program();
}

pub inline fn openLoadProgram() c_int {
    return z47_program_serialization_runtime_open_load_program();
}

pub inline fn writeLiteral(text: [*c]const u8) void {
    z47_program_serialization_runtime_write_literal(text);
}

pub inline fn writeU32Line(value: u32) void {
    z47_program_serialization_runtime_write_u32_line(value);
}

pub inline fn writeU8Line(value: u8) void {
    z47_program_serialization_runtime_write_u8_line(value);
}

pub inline fn readLine(buffer: []u8) void {
    z47_program_serialization_runtime_read_line(buffer.ptr);
}

pub inline fn closeFile() void {
    z47_program_serialization_runtime_close_file();
}

pub inline fn displayWriteError() void {
    z47_program_serialization_runtime_display_write_error();
}

pub inline fn displayReadError() void {
    z47_program_serialization_runtime_display_read_error();
}

pub inline fn showWarning(message: [*c]const u8) void {
    z47_program_serialization_runtime_show_warning(message);
}

pub inline fn scanLabelsAndPrograms() void {
    z47_program_serialization_runtime_scan_labels_and_programs();
}

pub inline fn goToLastProgram() void {
    z47_program_serialization_runtime_go_to_last_program();
}

pub inline fn isAtEndOfProgram(step: [*c]const u8) bool {
    return z47_program_serialization_runtime_is_at_end_of_program(step);
}

pub inline fn getRamSizeInBlocks() u16 {
    return z47_program_serialization_runtime_get_ram_size_in_blocks();
}

pub inline fn toC47MemPtr(mem_ptr: [*c]const u8) u16 {
    return z47_program_serialization_runtime_to_c47_mem_ptr(mem_ptr);
}

pub inline fn parseU32Line(line: [*c]const u8) u32 {
    return z47_program_serialization_runtime_parse_u32_line(line);
}

pub inline fn parseU8Line(line: [*c]const u8) u8 {
    return z47_program_serialization_runtime_parse_u8_line(line);
}

pub inline fn lineEquals(line: [*c]const u8, expected: [*c]const u8) bool {
    return z47_program_serialization_runtime_line_equals(line, expected);
}
