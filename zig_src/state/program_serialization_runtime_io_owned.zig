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
