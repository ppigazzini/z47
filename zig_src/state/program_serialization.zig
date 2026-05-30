const io_owned = @import("program_serialization_io_owned.zig");
const runtime = @import("program_serialization_runtime.zig");

pub export fn fnSaveProgram(label: u16) void {
    io_owned.saveProgram(label);
}

pub export fn fnLoadProgram(unusedButMandatoryParameter: u16) void {
    _ = unusedButMandatoryParameter;
    io_owned.loadProgram();
}
