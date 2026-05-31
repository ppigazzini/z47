pub extern fn z47_program_serialization_runtime_scan_labels_and_programs() void;
pub extern fn z47_program_serialization_runtime_go_to_last_program() void;
pub extern fn z47_program_serialization_runtime_is_at_end_of_program(step: [*c]const u8) bool;
pub extern fn z47_program_serialization_runtime_get_ram_size_in_blocks() u16;
pub extern fn z47_program_serialization_runtime_to_c47_mem_ptr(mem_ptr: [*c]const u8) u16;
pub extern fn z47_program_serialization_runtime_parse_u32_line(line: [*c]const u8) u32;
pub extern fn z47_program_serialization_runtime_parse_u8_line(line: [*c]const u8) u8;

fn lineEqualsZ(line: [*c]const u8, expected: [*c]const u8) bool {
    var idx: usize = 0;
    while (true) : (idx += 1) {
        const a = line[idx];
        const b = expected[idx];
        if (a != b) return false;
        if (a == 0) return true;
    }
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
    return lineEqualsZ(line, expected);
}
