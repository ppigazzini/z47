pub extern fn z47_calc_state_runtime_check_power() bool;
pub extern fn z47_calc_state_runtime_open_save(save_type: u16) c_int;
pub extern fn z47_calc_state_runtime_open_load(load_type: u16) c_int;
pub extern fn z47_calc_state_runtime_close_file() void;
pub extern fn z47_calc_state_runtime_display_write_error() void;
pub extern fn z47_calc_state_runtime_display_read_error() void;
pub extern fn z47_calc_state_runtime_unwind_all_subroutines() void;
pub extern fn z47_calc_state_runtime_read_line(buffer: [*c]u8) void;

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
    while (true) : (idx += 1) {
        const c = line[idx];
        if (c < '0' or c > '9') break;
        value = (value * 10) + @as(u32, c - '0');
    }
    return value;
}

pub inline fn checkPower() bool {
    return z47_calc_state_runtime_check_power();
}

pub inline fn openSave(save_type: u16) c_int {
    return z47_calc_state_runtime_open_save(save_type);
}

pub inline fn openLoad(load_type: u16) c_int {
    return z47_calc_state_runtime_open_load(load_type);
}

pub inline fn closeFile() void {
    z47_calc_state_runtime_close_file();
}

pub inline fn displayWriteError() void {
    z47_calc_state_runtime_display_write_error();
}

pub inline fn displayReadError() void {
    z47_calc_state_runtime_display_read_error();
}

pub inline fn unwindAllSubroutines() void {
    z47_calc_state_runtime_unwind_all_subroutines();
}

pub inline fn readLine(buffer: []u8) void {
    z47_calc_state_runtime_read_line(buffer.ptr);
}

pub inline fn lineEquals(line: [*c]const u8, expected: [*c]const u8) bool {
    return lineEqualsZ(line, expected);
}

pub inline fn parseU32Line(line: [*c]const u8) u32 {
    return parseU32LineZ(line);
}
