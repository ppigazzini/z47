const std = @import("std");
const build_options = @import("constants_build_options");
const use_fake_harness_surface = @hasDecl(build_options, "use_fake_harness_surface") and build_options.use_fake_harness_surface;

fn bufPrintZ(buffer: []u8, comptime format: []const u8, args: anytype) ![:0]u8 {
    const slice = try std.fmt.bufPrint(buffer[0 .. buffer.len - 1], format, args);
    buffer[slice.len] = 0;
    return buffer[0..slice.len :0];
}

pub const calcRegister_t = i16;
pub const angularMode_t = c_int;

pub const REGISTER_X: calcRegister_t = 100;
pub const SOLVER_STATUS_READY_TO_EXECUTE: u16 = 0x0001;
pub const dtReal34: u32 = 1;
pub const amNone: angularMode_t = 5;
pub const NOUC: usize = 84;

pub const real_t = opaque {};
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
pub const real34_t = abi.Real34;

pub extern var currentSolverStatus: u16;
pub extern var errorMessage: [512]u8;
pub extern var realtConstants: [NOUC]*const real_t;

pub extern fn liftStack() void;
pub extern fn adjustResult(
    res: calcRegister_t,
    drop_y: bool,
    set_cpx_res: bool,
    op1: calcRegister_t,
    op2: calcRegister_t,
    op3: calcRegister_t,
) void;
pub extern fn setLastintegerBasetoZero() void;
pub extern fn getRegisterDataPointer(reg: calcRegister_t) ?*anyopaque;
pub extern fn reallocateRegister(reg: calcRegister_t, data_type: u32, data_size_without_data_len_blocks: u16, tag: u32) void;
pub extern fn realToReal34(source: *const real_t, destination: *real34_t) void;
pub extern fn convertRealToResultRegister(source: *const real_t, dest: calcRegister_t, angle: angularMode_t) void;
pub extern fn moreInfoOnError(msg1: [*:0]const u8, msg2: ?[*:0]const u8, msg3: ?[*:0]const u8, msg4: ?[*:0]const u8) void;
pub extern fn z47_constants_test_register_real34_data(reg: calcRegister_t) *real34_t;

pub fn registerReal34Ptr(reg: calcRegister_t) *align(1) real34_t {
    if (use_fake_harness_surface) {
        return z47_constants_test_register_real34_data(reg);
    }

    const ptr = getRegisterDataPointer(reg) orelse unreachable;
    return @ptrCast(ptr);
}

pub inline fn validateConstant(constant: u16) bool {
    if (constant >= NOUC) {
        if (build_options.extra_info_on_calc_error) {
            const message = bufPrintZ(
                errorMessage[0 .. errorMessage.len - 1],
                "parameter constant ({d}) is out of bounds, constant must be less or equal to {d}",
                .{ constant, NOUC - 1 },
            ) catch unreachable;
            moreInfoOnError("In function fnConstant:", message.ptr, null, null);
        }
        return false;
    }

    return true;
}

pub inline fn storeConstantInX(constant: u16) void {
    reallocateRegister(REGISTER_X, dtReal34, 0, @as(u32, @intCast(amNone)));
    realToReal34(realtConstants[constant], registerReal34Ptr(REGISTER_X));
}

pub inline fn storePiInX() void {
    convertRealToResultRegister(realtConstants[NOUC - 1], REGISTER_X, amNone);
}

pub inline fn setLastIntegerBaseToZero() void {
    setLastintegerBasetoZero();
}
