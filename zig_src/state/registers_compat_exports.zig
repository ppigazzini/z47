const register_runtime = @import("register_metadata_runtime.zig");
const reg_param_product = @import("stack_runtime_reg_param_product_owned.zig");
const product_real = @import("stack_runtime_product_real_owned.zig");
const stack_runtime = @import("stack_runtime.zig");
const register_metadata_build_options = @import("register_metadata_build_options");

// The parity harness links register_metadata_oracle.c, which defines its own
// allReservedVariables fixture table. In that build the Zig owner must not also
// export the symbol or the link fails with a duplicate definition. In the
// product build the Zig table is the sole definition consumed by the runtime
// helper C and the Zig variable accessors.
const use_fake_register_metadata_harness_surface =
    @hasDecl(register_metadata_build_options, "use_fake_register_metadata_harness_surface") and
    register_metadata_build_options.use_fake_register_metadata_harness_surface;

const register_descriptor_t = u32;
const register_header_t = extern struct {
    descriptor: register_descriptor_t,
};

const reserved_variable_desc_t = extern struct {
    Desc: [28]u8,
};

const reserved_variable_header_t = extern struct {
    header: register_header_t,
    reservedVariableName: [8]u8,
};

const reserved_variable_count: usize = @intCast(register_runtime.LAST_RESERVED_VARIABLE - register_runtime.FIRST_RESERVED_VARIABLE + 1);

const INDPM_REGISTER: u16 = 1;
const INDPM_FLAG: u16 = 2;
const INDPM_LABEL: u16 = 3;
const INDPM_MENU: u16 = 4;

const LAST_LOCAL_LABEL: i16 = 123;
const FIRST_LOCAL_FLAG: i16 = 112;
const LAST_LOCAL_FLAG: i16 = 143;
const FLAG_M: i16 = 211;
const LAST_SPARE_REGISTERS_IN_KS_CODE: i16 = 224;
const FIRST_LOCAL_REGISTER_IN_KS_CODE: i16 = 112;
const FIRST_STAT_REGISTER_IN_KS_CODE: i16 = 211;
const NUMBER_OF_LOCAL_REGISTERS: i16 = 99;

const FAILED_INDIRECTION: i16 = 9999;

const dtLongInteger = stack_runtime.dtLongInteger;
const dtReal34 = stack_runtime.dtReal34;
const dtString = stack_runtime.dtString;
const dtShortInteger = stack_runtime.dtShortInteger;
const LI_POSITIVE: u8 = 2;

const ERROR_NONE = stack_runtime.ERROR_NONE;
const ERROR_OUT_OF_RANGE = stack_runtime.ERROR_OUT_OF_RANGE;
const ERROR_INVALID_DATA_TYPE_FOR_OP = stack_runtime.ERROR_INVALID_DATA_TYPE_FOR_OP;

extern fn findOrAllocateNamedVariable(variable_name: [*:0]const u8) stack_runtime.calcRegister_t;
extern fn findNamedVariable(variable_name: [*:0]const u8) stack_runtime.calcRegister_t;
extern fn findNamedLabel(label_name: [*:0]const u8) stack_runtime.calcRegister_t;
extern fn findMenu(menu_name: [*:0]const u8) i16;
extern fn convertShortIntegerRegisterToUInt64(reg: stack_runtime.calcRegister_t, sign: *i16, value: *u64) void;
extern fn realCompareAbsLessThan(number1: *const product_real.ProductReal, number2: *const product_real.ProductReal) bool;
extern fn realToIntegralValue(source: *const product_real.ProductReal, destination: *product_real.ProductReal, mode: product_real.product_rounding_t, real_context: *product_real.ProductRealContext) void;
extern fn realToInt32C47(source: *const product_real.ProductReal, err: ?*bool) i32;

fn makeDescriptor(pointer_to_data: u16, data_type: u8, tag: u8, read_only: u8, not_used: u8) u32 {
    return @as(u32, pointer_to_data) |
        (@as(u32, data_type) << 16) |
        (@as(u32, tag) << 20) |
        (@as(u32, read_only) << 25) |
        (@as(u32, not_used) << 26);
}

fn desc(comptime text: []const u8) reserved_variable_desc_t {
    comptime {
        if (text.len >= 28) @compileError("reserved variable description too long");
    }

    var out: [28]u8 = [_]u8{0} ** 28;
    inline for (text, 0..) |ch, i| {
        out[i] = ch;
    }
    return .{ .Desc = out };
}

fn regName(a: u8, b: u8, c: u8, d: u8, e: u8, f: u8, g: u8, h: u8) [8]u8 {
    return .{ a, b, c, d, e, f, g, h };
}

fn makeReserved(pointer_to_data: u16, data_type: u8, tag: u8, read_only: u8, not_used: u8, name: [8]u8) reserved_variable_header_t {
    return .{
        .header = .{ .descriptor = makeDescriptor(pointer_to_data, data_type, tag, read_only, not_used) },
        .reservedVariableName = name,
    };
}

fn regKStoC(reg_ks: i16) i16 {
    const stat_or_spare: i16 = if (FIRST_STAT_REGISTER_IN_KS_CODE <= reg_ks and reg_ks <= LAST_SPARE_REGISTERS_IN_KS_CODE) 1 else 0;
    const local: i16 = if (FIRST_LOCAL_REGISTER_IN_KS_CODE <= reg_ks and reg_ks <= FIRST_LOCAL_REGISTER_IN_KS_CODE + NUMBER_OF_LOCAL_REGISTERS - 1) 1 else 0;

    return reg_ks -
        stat_or_spare * NUMBER_OF_LOCAL_REGISTERS +
        local * (@as(i16, stack_runtime.FIRST_LOCAL_REGISTER) - FIRST_LOCAL_REGISTER_IN_KS_CODE);
}

fn registerReal34Ptr(reg: stack_runtime.calcRegister_t) *align(1) product_real.ProductReal34 {
    const ptr = stack_runtime.getRegisterDataPointer(reg) orelse unreachable;
    return @ptrCast(ptr);
}

fn registerStringData(reg: stack_runtime.calcRegister_t) [*:0]const u8 {
    const data_ptr = stack_runtime.getRegisterDataPointer(reg) orelse return "";
    const bytes: [*]const u8 = @ptrCast(data_ptr);
    return @ptrCast(bytes + 4);
}

fn parseRealRegisterToNonNegativeInt(reg: stack_runtime.calcRegister_t, max_value: i16, value_out: *i16) bool {
    var x: product_real.ProductReal = undefined;
    var integer_part: product_real.ProductReal = undefined;
    var max_plus_one: product_real.ProductReal = undefined;

    product_real.productReal34ToReal(registerReal34Ptr(reg), &x);
    product_real.productUInt32ToReal(@intCast(@as(i32, max_value) + 1), &max_plus_one);

    if (!realCompareAbsLessThan(&x, &max_plus_one)) {
        return false;
    }
    if (product_real.productRealIsNegative(&x)) {
        return false;
    }

    realToIntegralValue(&x, &integer_part, product_real.PRODUCT_DEC_ROUND_DOWN, product_real.realContext39());
    value_out.* = @intCast(realToInt32C47(&integer_part, null));
    return true;
}

pub export const varDescr: [reserved_variable_count]reserved_variable_desc_t = .{
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
    desc(" Future Value ="),
    desc(" I%YR = APR ="),
    desc(" n pay periods ="),
    desc(" Pay periods YR ="),
    desc(" Payment ="),
    desc(" Present Value ="),
    desc(""),
    desc(""),
    desc(""),
    desc(" Compounding periods YR ="),
    desc(""),
    desc(""),
    desc(""),
    desc(""),
};

pub var allReservedVariables: [reserved_variable_count]reserved_variable_header_t = .{
    makeReserved(0, 0, 0, 0, 0, regName(1, 'X', 0, 0, 0, 0, 0, 0)),
    makeReserved(0, 0, 0, 0, 0, regName(1, 'Y', 0, 0, 0, 0, 0, 0)),
    makeReserved(0, 0, 0, 0, 0, regName(1, 'Z', 0, 0, 0, 0, 0, 0)),
    makeReserved(0, 0, 0, 0, 0, regName(1, 'T', 0, 0, 0, 0, 0, 0)),
    makeReserved(0, 0, 0, 0, 0, regName(1, 'A', 0, 0, 0, 0, 0, 0)),
    makeReserved(0, 0, 0, 0, 0, regName(1, 'B', 0, 0, 0, 0, 0, 0)),
    makeReserved(0, 0, 0, 0, 0, regName(1, 'C', 0, 0, 0, 0, 0, 0)),
    makeReserved(0, 0, 0, 0, 0, regName(1, 'D', 0, 0, 0, 0, 0, 0)),
    makeReserved(0, 0, 0, 0, 0, regName(1, 'L', 0, 0, 0, 0, 0, 0)),
    makeReserved(0, 0, 0, 0, 0, regName(1, 'I', 0, 0, 0, 0, 0, 0)),
    makeReserved(0, 0, 0, 0, 0, regName(1, 'J', 0, 0, 0, 0, 0, 0)),
    makeReserved(0, 0, 0, 0, 0, regName(1, 'K', 0, 0, 0, 0, 0, 0)),
    makeReserved(0, 0, 0, 0, 0, regName(1, 'M', 0, 0, 0, 0, 0, 0)),
    makeReserved(0, 0, 0, 0, 0, regName(1, 'N', 0, 0, 0, 0, 0, 0)),
    makeReserved(0, 0, 0, 0, 0, regName(1, 'P', 0, 0, 0, 0, 0, 0)),
    makeReserved(0, 0, 0, 0, 0, regName(1, 'Q', 0, 0, 0, 0, 0, 0)),
    makeReserved(0, 0, 0, 0, 0, regName(1, 'R', 0, 0, 0, 0, 0, 0)),
    makeReserved(0, 0, 0, 0, 0, regName(1, 'S', 0, 0, 0, 0, 0, 0)),
    makeReserved(0, 0, 0, 0, 0, regName(1, 'E', 0, 0, 0, 0, 0, 0)),
    makeReserved(0, 0, 0, 0, 0, regName(1, 'F', 0, 0, 0, 0, 0, 0)),
    makeReserved(0, 0, 0, 0, 0, regName(1, 'G', 0, 0, 0, 0, 0, 0)),
    makeReserved(0, 0, 0, 0, 0, regName(1, 'H', 0, 0, 0, 0, 0, 0)),
    makeReserved(0, 0, 0, 0, 0, regName(1, 'O', 0, 0, 0, 0, 0, 0)),
    makeReserved(0, 0, 0, 0, 0, regName(1, 'U', 0, 0, 0, 0, 0, 0)),
    makeReserved(0, 0, 0, 0, 0, regName(1, 'V', 0, 0, 0, 0, 0, 0)),
    makeReserved(0, 0, 0, 0, 0, regName(1, 'W', 0, 0, 0, 0, 0, 0)),
    makeReserved(0, @intCast(dtLongInteger), LI_POSITIVE, 1, 0, regName(3, 'A', 'D', 'M', 0, 0, 0, 0)),
    makeReserved(0, @intCast(dtReal34), @intCast(stack_runtime.amNone), 0, 0, regName(5, 'D', '.', 'M', 'A', 'X', 0, 0)),
    makeReserved(0, @intCast(dtReal34), @intCast(stack_runtime.amNone), 0, 0, regName(3, 'I', 'S', 'M', 0, 0, 0, 0)),
    makeReserved(0, @intCast(dtReal34), @intCast(stack_runtime.amNone), 0, 0, regName(6, 'R', 'E', 'A', 'L', 'D', 'F', 0)),
    makeReserved(0, @intCast(dtLongInteger), LI_POSITIVE, 0, 0, regName(4, '#', 'D', 'E', 'C', 0, 0, 0)),
    makeReserved(0, @intCast(dtReal34), @intCast(stack_runtime.amNone), 0, 0, regName(3, 'A', 'C', 'C', 0, 0, 0, 0)),
    makeReserved(4, @intCast(dtReal34), @intCast(stack_runtime.amNone), 0, 0, regName(5, 161, 145, 'L', 'i', 'm', 0, 0)),
    makeReserved(8, @intCast(dtReal34), @intCast(stack_runtime.amNone), 0, 0, regName(5, 161, 147, 'L', 'i', 'm', 0, 0)),
    makeReserved(12, @intCast(dtReal34), @intCast(stack_runtime.amNone), 0, 0, regName(2, 'F', 'V', 0, 0, 0, 0, 0)),
    makeReserved(16, @intCast(dtReal34), @intCast(stack_runtime.amNone), 0, 0, regName(4, 'I', '%', '/', 'a', 0, 0, 0)),
    makeReserved(20, @intCast(dtReal34), @intCast(stack_runtime.amNone), 0, 0, regName(5, 'N', 'P', 'P', 'E', 'R', 0, 0)),
    makeReserved(24, @intCast(dtReal34), @intCast(stack_runtime.amNone), 0, 0, regName(6, 'P', 'P', 'E', 'R', '/', 'a', 0)),
    makeReserved(28, @intCast(dtReal34), @intCast(stack_runtime.amNone), 0, 0, regName(3, 'P', 'M', 'T', 0, 0, 0, 0)),
    makeReserved(32, @intCast(dtReal34), @intCast(stack_runtime.amNone), 0, 0, regName(2, 'P', 'V', 0, 0, 0, 0, 0)),
    makeReserved(36, @intCast(dtLongInteger), LI_POSITIVE, 0, 0, regName(6, 'G', 'R', 'A', 'M', 'O', 'D', 0)),
    makeReserved(40, @intCast(dtReal34), @intCast(stack_runtime.amNone), 0, 0, regName(3, 161, 145, 'X', 0, 0, 0, 0)),
    makeReserved(44, @intCast(dtReal34), @intCast(stack_runtime.amNone), 0, 0, regName(3, 161, 147, 'X', 0, 0, 0, 0)),
    makeReserved(48, @intCast(dtReal34), @intCast(stack_runtime.amNone), 0, 0, regName(6, 'C', 'P', 'E', 'R', '/', 'a', 0)),
    makeReserved(52, @intCast(dtReal34), @intCast(stack_runtime.amNone), 0, 0, regName(5, 161, 145, 'E', 'S', 'T', 0, 0)),
    makeReserved(56, @intCast(dtReal34), @intCast(stack_runtime.amNone), 0, 0, regName(5, 161, 147, 'E', 'S', 'T', 0, 0)),
    makeReserved(60, @intCast(dtReal34), @intCast(stack_runtime.amNone), 0, 0, regName(3, 161, 145, 'Y', 0, 0, 0, 0)),
    makeReserved(64, @intCast(dtReal34), @intCast(stack_runtime.amNone), 0, 0, regName(3, 161, 147, 'Y', 0, 0, 0, 0)),
};

comptime {
    if (!use_fake_register_metadata_harness_surface) {
        @export(&allReservedVariables, .{ .name = "allReservedVariables" });
    }
}

pub export fn getRegParam(f: ?*bool, s: *u16, n: *u16, d: ?*u16) u8 {
    return reg_param_product.getRegParamProduct(f, s, n, d, stack_runtime.currentLocalRegisterCount());
}

pub export fn indirectAddressing(regist: stack_runtime.calcRegister_t, parameter_type: u16, min_value: i16, max_value_in: i16, try_allocate: bool) i16 {
    _ = regist;
    _ = parameter_type;
    _ = min_value;
    _ = max_value_in;
    _ = try_allocate;
    stack_runtime.displayCalcErrorMessage(ERROR_OUT_OF_RANGE, stack_runtime.ERR_REGISTER_LINE, stack_runtime.REGISTER_X);
    return FAILED_INDIRECTION;
}

pub export fn printStringToConsole(str: [*:0]const u8, before: [*:0]const u8, after: [*:0]const u8) void {
    _ = str;
    _ = before;
    _ = after;
}

pub export fn printReal34ToConsole(value: *const product_real.ProductReal34, before: [*:0]const u8, after: [*:0]const u8) void {
    _ = value;
    _ = before;
    _ = after;
}

pub export fn printRealToConsole(value: *const stack_runtime.real_t, before: [*:0]const u8, after: [*:0]const u8) void {
    _ = value;
    _ = before;
    _ = after;
}

pub export fn printRegisterToConsole(regist: stack_runtime.calcRegister_t, before: [*:0]const u8, after: [*:0]const u8) void {
    _ = regist;
    _ = before;
    _ = after;
}