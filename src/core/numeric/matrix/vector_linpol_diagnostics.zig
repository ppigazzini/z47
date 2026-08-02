const std = @import("std");
const runtime = @import("../command_wrappers/runtime.zig");

pub fn invalidXError() void {
    var message_buffer: [128]u8 = undefined;
    const type_name = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_X, true, false));
    const message = runtime.bufPrintZ(&message_buffer, "cannot LINPOL with {s} in X", .{type_name}) catch "cannot LINPOL with current X type";

    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    runtime.moreInfoOnError("In function fnLINPOL:", message, null, null);
}

pub fn differingTypeError() void {
    var message_buffer: [192]u8 = undefined;
    const type_name_y = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_Y, true, false));
    const type_name_z = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_Z, true, false));
    const message = runtime.bufPrintZ(
        &message_buffer,
        "cannot LINPOL with differing data types in Y ({s}) and Z ({s})",
        .{ type_name_y, type_name_z },
    ) catch "cannot LINPOL with differing data types in Y and Z";

    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_Y);
    runtime.moreInfoOnError("In function fnLINPOL:", message, null, null);
}

pub fn coeffTypeError(regist: runtime.calcRegister_t) void {
    var message_buffer: [128]u8 = undefined;
    const type_name = std.mem.span(runtime.getRegisterDataTypeName(regist, true, false));
    const register_name = if (regist == runtime.REGISTER_Y) "Y" else "Z";
    const message = runtime.bufPrintZ(&message_buffer, "cannot LINPOL with {s} in {s}", .{ type_name, register_name }) catch "cannot LINPOL with current coefficient type";

    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, regist);
    runtime.moreInfoOnError("In function fnLINPOL:", message, null, null);
}
