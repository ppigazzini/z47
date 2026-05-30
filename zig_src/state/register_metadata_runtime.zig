const std = @import("std");
const build_options = @import("register_metadata_build_options");
const clear_sigma_owned = @import("register_metadata_clear_sigma_owned.zig");
const descriptor_access_owned = @import("register_metadata_descriptor_access_owned.zig");
const bridge_owned = @import("register_metadata_bridge_owned.zig");
const named_menu_owned = @import("register_metadata_named_menu_owned.zig");
const size_owned = @import("register_metadata_size_owned.zig");
const stack_runtime = @import("stack_runtime.zig");
const confirmation_owned = @import("register_metadata_confirmation_owned.zig");
const descriptor_storage = @import("register_descriptor_storage_owned.zig");
const error_owned = @import("register_metadata_error_owned.zig");
const payload_bytes_owned = @import("register_metadata_payload_bytes_owned.zig");
const variable_storage_owned = @import("register_metadata_variable_storage_owned.zig");

const use_fake_register_metadata_harness_surface =
    @hasDecl(build_options, "use_fake_register_metadata_harness_surface") and
    build_options.use_fake_register_metadata_harness_surface;

pub const calcRegister_t = stack_runtime.calcRegister_t;
pub const register_descriptor_t = stack_runtime.register_descriptor_t;
pub const dtLongInteger = stack_runtime.dtLongInteger;
pub const dtReal34 = stack_runtime.dtReal34;
pub const amNone = stack_runtime.amNone;
pub const amPolar: u32 = 16;
pub const FLAG_POLAR: i32 = 0x8006;
pub const dtComplex34: u32 = 2;
pub const dtTime: u32 = 3;
pub const dtDate: u32 = 4;
pub const dtString: u32 = 5;
pub const dtReal34Matrix: u32 = 6;
pub const dtComplex34Matrix: u32 = 7;
pub const dtShortInteger: u32 = 8;
pub const dtConfig: u32 = 9;
pub const TI_NO_INFO: u8 = 0;
pub const TI_CLEAR_ALL_VARIABLES: u8 = 98;
pub const TI_DEL_ALL_VARIABLES: u8 = 101;
pub const CONFIRMED: u16 = 9877;

pub const ERROR_CANNOT_DELETE_PREDEF_ITEM: u8 = 27;
pub const ERROR_UNDEF_SOURCE_VAR: u8 = 36;
pub const ERROR_INVALID_NAME: u8 = 48;
pub const ERROR_TOO_MANY_VARIABLES: u8 = 49;

const strLgIntHeader_t = payload_bytes_owned.strLgIntHeader_t;
const matrixHeader_t = payload_bytes_owned.matrixHeader_t;

const item_t = extern struct {
    status: u32,
    itemCatalogName: [16]u8,
};

const userMenu_t = extern struct {
    menuName: [16]u8,
};

const named_variable_header_t = extern struct {
    header: extern struct {
        descriptor: register_descriptor_t,
    },
    variableName: [16]u8,
};

const max_fake_named_variables: u16 = 64;

pub const REGISTER_X = stack_runtime.REGISTER_X;
pub const REGISTER_Y = stack_runtime.REGISTER_Y;
pub const LAST_GLOBAL_REGISTER = stack_runtime.LAST_GLOBAL_REGISTER;
pub const FIRST_NAMED_VARIABLE: calcRegister_t = 256;
pub const LAST_NAMED_VARIABLE: calcRegister_t = 1999;
pub const FIRST_RESERVED_VARIABLE: calcRegister_t = 2000;
pub const FIRST_NAMED_RESERVED_VARIABLE: calcRegister_t = 2026;
pub const LAST_RESERVED_VARIABLE: calcRegister_t = 2047;
pub const FIRST_LOCAL_REGISTER = stack_runtime.FIRST_LOCAL_REGISTER;
pub const LAST_LOCAL_REGISTER = stack_runtime.LAST_LOCAL_REGISTER;
pub const RESERVED_VARIABLE_ADM: calcRegister_t = FIRST_NAMED_RESERVED_VARIABLE;
pub const RESERVED_VARIABLE_DENMAX: calcRegister_t = FIRST_NAMED_RESERVED_VARIABLE + 1;
pub const RESERVED_VARIABLE_ISM: calcRegister_t = FIRST_NAMED_RESERVED_VARIABLE + 2;
pub const RESERVED_VARIABLE_REALDF: calcRegister_t = FIRST_NAMED_RESERVED_VARIABLE + 3;
pub const RESERVED_VARIABLE_NDEC: calcRegister_t = FIRST_NAMED_RESERVED_VARIABLE + 4;
pub const INVALID_VARIABLE: calcRegister_t = @intCast(stack_runtime.INVALID_VARIABLE);

pub const ITM_INPUT: u16 = 43;
pub const ITM_RCL: u16 = 51;
pub const ITM_STO: u16 = 44;
pub const ITM_STOADD: u16 = 45;
pub const ITM_STOSUB: u16 = 46;
pub const ITM_STOMULT: u16 = 47;
pub const ITM_STODIV: u16 = 48;
pub const ITM_KEYQ: u16 = 77;
pub const ITM_MVAR: u16 = 1524;
pub const ITM_M_DIM: u16 = 1526;
pub const ITM_STOMAX: u16 = 1430;
pub const ITM_STOMIN: u16 = 1545;
pub const ITM_SOLVE: u16 = 1608;
pub const ITM_STOCFG: u16 = 1611;
pub const ITM_Tex: u16 = 1625;
pub const ITM_XtoALPHA: u16 = 1645;
pub const ITM_Xex: u16 = 127;
pub const ITM_Yex: u16 = 1650;
pub const ITM_Zex: u16 = 1651;
pub const ITM_INTEGRAL: u16 = 1700;

pub extern var currentAngularMode: u32;
pub extern var numberOfNamedVariables: u16;
pub extern var temporaryInformation: u8;
pub extern var userMenus: [*c]userMenu_t;
pub extern var numberOfUserMenus: u16;

extern var allNamedVariables: ?[*]named_variable_header_t;

extern fn z47_register_metadata_get_reserved_descriptor(reg: calcRegister_t) register_descriptor_t;
extern fn z47_register_metadata_get_reserved_data_type_descriptor(reg: calcRegister_t) register_descriptor_t;
extern fn z47_register_metadata_reserved_allows_data_type_write(reg: calcRegister_t) bool;
extern fn z47_register_metadata_config_size_in_blocks() u16;
extern fn z47_register_metadata_to_pc_mem_ptr(mem_ptr: u16) ?*anyopaque;
extern fn z47_register_metadata_to_c47_mem_ptr(mem_ptr: ?*const anyopaque) u16;
extern fn z47_register_metadata_builtin_menu_item_count() u32;
extern fn z47_register_metadata_builtin_menu_item_is_menu(index: u32) bool;
extern fn z47_register_metadata_builtin_menu_item_name(index: u32) [*c]const u8;
extern fn z47_register_metadata_allocate_first_named_variable_header() bool;
extern fn z47_register_metadata_append_named_variable_header(index: *u16) bool;
extern fn z47_register_metadata_store_named_variable_name(index: u16, variable_name: [*c]const u8) void;
extern fn z47_register_metadata_clear_named_variable_slot(index: u16) void;
extern fn z47_register_metadata_shrink_named_variable_header_storage() void;
extern fn z47_register_metadata_compare_menu_names(left: [*c]const u8, right: [*c]const u8) i32;
extern fn z47_register_metadata_find_reserved_variable_name(variable_name: [*c]const u8, glyph_length: u8) calcRegister_t;
extern fn z47_register_metadata_request_delete_all_variables_confirmation() void;
extern fn z47_register_metadata_request_clear_all_variables_confirmation() void;
extern fn isMemoryBlockAvailable(size_in_blocks: usize, num_blocks: u16, extra_fraction: f32) bool;
extern fn removeUserItemAssignments(item: i16, user_item_name: [*c]u8) void;
extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: calcRegister_t, err_register_line: calcRegister_t) void;
extern fn fnDeleteAllVariables(confirmation: u16) callconv(.c) void;
extern fn fnClearAllVariables(confirmation: u16) callconv(.c) void;
extern fn fnClSigma(confirmation: u16) callconv(.c) void;
extern fn fnDeleteVariable(regist: u16) callconv(.c) void;
extern fn findNamedVariable(variable_name: [*c]const u8) calcRegister_t;
extern fn setConfirmationMode(handler: *const fn (confirmation: u16) callconv(.c) void) void;
extern fn z47_registers_retained_allocateLocalRegisters(number_of_registers_to_allocate: u16) void;
extern fn z47_registers_retained_reallocateRegister(reg: calcRegister_t, data_type: u32, data_size_without_data_len_blocks: u16, tag: u32) void;

fn bytesPerBlock() comptime_int {
    return payload_bytes_owned.bytesPerBlock();
}

fn toBlocks(bytes: usize) u16 {
    return payload_bytes_owned.toBlocks(bytes);
}

fn copyBytesToValue(comptime T: type, data_ptr: ?*const anyopaque) T {
    return payload_bytes_owned.copyBytesToValue(T, data_ptr);
}

fn copyValueToBytes(comptime T: type, data_ptr: ?*anyopaque, value: *const T) void {
    payload_bytes_owned.copyValueToBytes(T, data_ptr, value);
}

fn matrixRows(data_ptr: ?*const anyopaque) u16 {
    return payload_bytes_owned.matrixRows(data_ptr);
}

fn matrixColumns(data_ptr: ?*const anyopaque) u16 {
    return payload_bytes_owned.matrixColumns(data_ptr);
}

fn setMatrixRowsColumns(data_ptr: ?*anyopaque, rows: u16, columns: u16) void {
    payload_bytes_owned.setMatrixRowsColumns(data_ptr, rows, columns);
}

pub fn globalDescriptor(reg: calcRegister_t) register_descriptor_t {
    return descriptor_access_owned.globalDescriptor(reg);
}

pub fn setGlobalDescriptor(reg: calcRegister_t, descriptor: register_descriptor_t) void {
    descriptor_access_owned.setGlobalDescriptor(reg, descriptor);
}

pub fn tryGetNamedDescriptor(reg: calcRegister_t, descriptor: *register_descriptor_t) bool {
    return descriptor_access_owned.tryGetNamedDescriptor(reg, descriptor);
}

pub fn trySetNamedDescriptor(reg: calcRegister_t, descriptor: register_descriptor_t) bool {
    return descriptor_access_owned.trySetNamedDescriptor(reg, descriptor);
}

pub fn namedDescriptorUnchecked(index: u16) register_descriptor_t {
    return descriptor_access_owned.namedDescriptorUnchecked(index);
}

pub fn setNamedDescriptorUnchecked(index: u16, descriptor: register_descriptor_t) void {
    descriptor_access_owned.setNamedDescriptorUnchecked(index, descriptor);
}

pub fn tryGetLocalDescriptor(reg: calcRegister_t, descriptor: *register_descriptor_t) bool {
    return descriptor_access_owned.tryGetLocalDescriptor(reg, descriptor);
}

pub fn trySetLocalDescriptor(reg: calcRegister_t, descriptor: register_descriptor_t) bool {
    return descriptor_access_owned.trySetLocalDescriptor(reg, descriptor);
}

pub fn reservedDescriptor(reg: calcRegister_t) register_descriptor_t {
    return descriptor_access_owned.reservedDescriptor(reg);
}

pub fn reservedDataTypeDescriptor(reg: calcRegister_t) register_descriptor_t {
    return descriptor_access_owned.reservedDataTypeDescriptor(reg);
}

pub fn reservedAllowsDataTypeWrite(reg: calcRegister_t) bool {
    return descriptor_access_owned.reservedAllowsDataTypeWrite(reg);
}

pub fn dataMaxLengthInBlocks(data_ptr: ?*const anyopaque) u16 {
    return copyBytesToValue(strLgIntHeader_t, data_ptr).dataMaxLengthInBlocks;
}

pub fn setDataMaxLengthInBlocks(data_ptr: ?*anyopaque, max_data_len: u16) void {
    var header = copyBytesToValue(strLgIntHeader_t, data_ptr);
    header.dataMaxLengthInBlocks = max_data_len;
    copyValueToBytes(strLgIntHeader_t, data_ptr, &header);
}

pub fn matrixPayloadSizeInBlocks(data_ptr: ?*const anyopaque, element_size_in_blocks: u16) u16 {
    return @intCast(@as(u32, matrixRows(data_ptr)) * @as(u32, matrixColumns(data_ptr)) * @as(u32, element_size_in_blocks));
}

pub fn strLgIntHeaderSizeInBlocks() u16 {
    return size_owned.strLgIntHeaderSizeInBlocks();
}

pub fn matrixHeaderSizeInBlocks() u16 {
    return size_owned.matrixHeaderSizeInBlocks();
}

pub fn real34SizeInBlocks() u16 {
    return size_owned.real34SizeInBlocks();
}

pub fn complex34SizeInBlocks() u16 {
    return size_owned.complex34SizeInBlocks();
}

pub fn shortIntegerSizeInBlocks() u16 {
    return size_owned.shortIntegerSizeInBlocks();
}

pub fn configSizeInBlocks() u16 {
    return size_owned.configSizeInBlocks();
}

pub fn memoryBlockAvailable(size_in_blocks: u16) bool {
    return size_owned.memoryBlockAvailable(size_in_blocks);
}

pub fn alignLongIntegerBlocks(size_in_blocks: u16) u16 {
    return size_owned.alignLongIntegerBlocks(size_in_blocks);
}

pub fn initializeMatrixHeader1x1(data_ptr: ?*anyopaque) void {
    size_owned.initializeMatrixHeader1x1(data_ptr);
}

pub fn reportRamFull() void {
    error_owned.reportRamFull();
}

pub fn toPcMemPtr(mem_ptr: u16) ?*anyopaque {
    return bridge_owned.toPcMemPtr(mem_ptr);
}

pub fn toC47MemPtr(mem_ptr: ?*const anyopaque) u16 {
    return bridge_owned.toC47MemPtr(mem_ptr);
}

pub fn builtinMenuItemCount() u32 {
    return bridge_owned.builtinMenuItemCount();
}

pub fn builtinMenuItemIsMenu(index: u32) bool {
    return bridge_owned.builtinMenuItemIsMenu(index);
}

pub fn builtinMenuItemName(index: u32) [*c]const u8 {
    return bridge_owned.builtinMenuItemName(index);
}

pub fn userMenuCount() u32 {
    return named_menu_owned.userMenuCount();
}

pub fn userMenuName(index: u32) [*c]const u8 {
    return named_menu_owned.userMenuName(index);
}

pub fn namedVariableName(index: u16) [*c]const u8 {
    return named_menu_owned.namedVariableName(index);
}

pub fn allocateFirstNamedVariableHeader() bool {
    return variable_storage_owned.allocateFirstNamedVariableHeader();
}

pub fn appendNamedVariableHeader(index: *u16) bool {
    return variable_storage_owned.appendNamedVariableHeader(index);
}

pub fn storeNamedVariableName(index: u16, variable_name: [*c]const u8) void {
    variable_storage_owned.storeNamedVariableName(index, variable_name);
}

pub fn removeNamedVariableRecallAssignment(index: u16) void {
    named_menu_owned.removeNamedVariableRecallAssignment(index);
}

pub fn clearNamedVariableSlot(index: u16) void {
    variable_storage_owned.clearNamedVariableSlot(index);
}

pub fn shrinkNamedVariableHeaderStorage() void {
    variable_storage_owned.shrinkNamedVariableHeaderStorage();
}

pub fn compareMenuNames(left: [*c]const u8, right: [*c]const u8) i32 {
    return variable_storage_owned.compareMenuNames(left, right);
}

pub fn findReservedVariableName(variable_name: [*c]const u8, glyph_length: u8) calcRegister_t {
    return variable_storage_owned.findReservedVariableName(variable_name, glyph_length);
}

pub fn reportInvalidName() void {
    error_owned.reportInvalidName(ERROR_INVALID_NAME);
}

pub fn reportUndefSourceVar() void {
    error_owned.reportUndefSourceVar(ERROR_UNDEF_SOURCE_VAR);
}

pub fn reportCannotDeletePredefItem() void {
    error_owned.reportCannotDeletePredefItem(ERROR_CANNOT_DELETE_PREDEF_ITEM);
}

pub fn reportTooManyVariables() void {
    error_owned.reportTooManyVariables(ERROR_TOO_MANY_VARIABLES);
}

pub fn clearSigma() void {
    clear_sigma_owned.clearSigma();
}

pub fn requestDeleteAllVariablesConfirmation() void {
    confirmation_owned.requestDeleteAllVariablesConfirmation();
}

pub fn requestClearAllVariablesConfirmation() void {
    confirmation_owned.requestClearAllVariablesConfirmation();
}

pub fn allocateLocalRegistersRetained(number_of_registers_to_allocate: u16) void {
    bridge_owned.allocateLocalRegistersRetained(number_of_registers_to_allocate);
}

pub fn reallocateRegisterRetained(reg: calcRegister_t, data_type: u32, data_size_without_data_len_blocks: u16, tag: u32) void {
    bridge_owned.reallocateRegisterRetained(reg, data_type, data_size_without_data_len_blocks, tag);
}
