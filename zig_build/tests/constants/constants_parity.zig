const std = @import("std");

const constants_snapshot_t = extern struct {
    lift_stack_calls: u32,
    current_solver_status: u16,

    reallocate_register_calls: u32,
    reallocate_register_reg: i16,
    reallocate_register_data_type: u32,
    reallocate_register_data_size_without_data_len_blocks: u16,
    reallocate_register_tag: u32,

    real_to_real34_calls: u32,
    real_to_real34_source_id: u16,
    real_to_real34_destination_reg: i16,

    convert_real_to_result_register_calls: u32,
    convert_real_to_result_source_id: u16,
    convert_real_to_result_dest: i16,
    convert_real_to_result_angle: i32,

    adjust_result_calls: u32,
    adjust_result_res: i16,
    adjust_result_drop_y: bool,
    adjust_result_set_cpx_res: bool,
    adjust_result_op1: i16,
    adjust_result_op2: i16,
    adjust_result_op3: i16,

    set_lastinteger_base_to_zero_calls: u32,
    register_x_real34_id: u16,

    more_info_calls: u32,
    more_info_line1: [64]u8,
    more_info_line2: [256]u8,
};

extern fn constantsRuntimeReset() void;
extern fn constantsRuntimeCapture(snapshot: *constants_snapshot_t) void;
extern fn fnConstant(constant: u16) callconv(.c) void;
extern fn fnPi(unused_but_mandatory_parameter: u16) callconv(.c) void;
extern fn oracle_fnConstant(constant: u16) callconv(.c) void;
extern fn oracle_fnPi(unused_but_mandatory_parameter: u16) callconv(.c) void;

const ConstantsFn = *const fn (u16) callconv(.c) void;

fn runCase(name: []const u8, oracle_fn: ConstantsFn, zig_fn: ConstantsFn, arg: u16) bool {
    var expected: constants_snapshot_t = undefined;
    var actual: constants_snapshot_t = undefined;

    constantsRuntimeReset();
    oracle_fn(arg);
    constantsRuntimeCapture(&expected);

    constantsRuntimeReset();
    zig_fn(arg);
    constantsRuntimeCapture(&actual);

    const equal = std.mem.eql(u8, std.mem.asBytes(&expected), std.mem.asBytes(&actual));
    if (!equal) {
        std.debug.print("{s}({d}) parity mismatch\n", .{ name, arg });
    }
    return equal;
}

pub fn main() !void {
    var failures: u32 = 0;

    if (!runCase("fnConstant", &oracle_fnConstant, &fnConstant, 0)) failures += 1;
    if (!runCase("fnConstant", &oracle_fnConstant, &fnConstant, 7)) failures += 1;
    if (!runCase("fnConstant", &oracle_fnConstant, &fnConstant, 83)) failures += 1;
    if (!runCase("fnConstant", &oracle_fnConstant, &fnConstant, 84)) failures += 1;
    if (!runCase("fnPi", &oracle_fnPi, &fnPi, 0)) failures += 1;
    if (!runCase("fnPi", &oracle_fnPi, &fnPi, 99)) failures += 1;

    if (failures != 0) {
        std.debug.print("{d} constants parity checks failed\n", .{failures});
        std.process.exit(1);
    }
}
