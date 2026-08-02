const runtime = @import("program_serialization_runtime.zig");

pub const LoadHeader = struct {
    loaded_version: u32,
    program_size_in_bytes: u32,
    valid: bool,
};

pub fn parseLoadHeader() LoadHeader {
    @setRuntimeSafety(true); // untrusted file input -- see calc_state.zig's panic decl
    var key_buffer: [256]u8 = undefined;
    var value_buffer: [256]u8 = undefined;
    var loaded_version: u32 = 0;

    runtime.readLine(key_buffer[0..]);
    if (runtime.lineEquals(key_buffer[0..], "PROGRAM_FILE_FORMAT")) {
        runtime.readLine(value_buffer[0..]);
    } else {
        runtime.showWarning(" \nThis is not a C47 program\n\nIt will not be loaded.");
        return .{ .loaded_version = 0, .program_size_in_bytes = 0, .valid = false };
    }

    runtime.readLine(key_buffer[0..]);
    runtime.readLine(value_buffer[0..]);
    if (runtime.lineEquals(key_buffer[0..], "C47_program_file_version")) {
        loaded_version = runtime.parseU32Line(value_buffer[0..]);
        if (loaded_version < runtime.OLDEST_COMPATIBLE_PROGRAM_VERSION) {
            runtime.showWarning(" \n   !!! Program version is too old !!!\nNot compatible with current version\n \nIt will not be loaded.");
            return .{ .loaded_version = loaded_version, .program_size_in_bytes = 0, .valid = false };
        }
    } else if (runtime.lineEquals(key_buffer[0..], "WP43_program_file_version")) {
        loaded_version = runtime.parseU32Line(value_buffer[0..]);
        runtime.showWarning(" \nThis is a WP43 program\nWP43 program support is experimental\nSome instructions may not be \ncompatible with the C47 and may\ncrash the calculator.");
    } else {
        runtime.showWarning(" \nThis is not a C47 program\n \nIt will not be loaded.");
        return .{ .loaded_version = 0, .program_size_in_bytes = 0, .valid = false };
    }

    runtime.readLine(key_buffer[0..]);
    runtime.readLine(value_buffer[0..]);
    if (!runtime.lineEquals(key_buffer[0..], "PROGRAM")) {
        return .{ .loaded_version = loaded_version, .program_size_in_bytes = 0, .valid = false };
    }

    return .{
        .loaded_version = loaded_version,
        .program_size_in_bytes = runtime.parseU32Line(value_buffer[0..]),
        .valid = true,
    };
}
