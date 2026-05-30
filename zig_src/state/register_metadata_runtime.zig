const std = @import("std");
const build_options = @import("register_metadata_build_options");
const stack_runtime = @import("stack_runtime.zig");
const descriptor_storage = @import("register_descriptor_storage_owned.zig");

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

const Z47_LOCAL_MATRIX_ROWS_MASK: u32 = 0x00000fff;
const Z47_LOCAL_MATRIX_COLUMNS_MASK: u32 = 0x00fff000;
const Z47_LOCAL_MATRIX_ROWS_SHIFT: u5 = 0;
const Z47_LOCAL_MATRIX_COLUMNS_SHIFT: u5 = 12;

const strLgIntHeader_t = extern struct {
    dataMaxLengthInBlocks: u16,
    unused: u16,
};

const matrixHeader_t = extern struct {
    descriptor: u32,
};

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
    return 4;
}

fn toBlocks(bytes: usize) u16 {
    return @intCast((bytes + (bytesPerBlock() - 1)) / bytesPerBlock());
}

fn copyBytesToValue(comptime T: type, data_ptr: ?*const anyopaque) T {
    var value = std.mem.zeroes(T);
    const ptr = data_ptr orelse return value;
    const src: [*]const u8 = @ptrCast(ptr);
    const dst: [*]u8 = @ptrCast(&value);
    @memcpy(dst[0..@sizeOf(T)], src[0..@sizeOf(T)]);
    return value;
}

fn copyValueToBytes(comptime T: type, data_ptr: ?*anyopaque, value: *const T) void {
    const ptr = data_ptr orelse return;
    const src: [*]const u8 = @ptrCast(value);
    const dst: [*]u8 = @ptrCast(ptr);
    @memcpy(dst[0..@sizeOf(T)], src[0..@sizeOf(T)]);
}

fn readMatrixHeaderDescriptor(data_ptr: ?*const anyopaque) u32 {
    return copyBytesToValue(u32, data_ptr);
}

fn matrixRows(data_ptr: ?*const anyopaque) u16 {
    return @intCast((readMatrixHeaderDescriptor(data_ptr) & Z47_LOCAL_MATRIX_ROWS_MASK) >> Z47_LOCAL_MATRIX_ROWS_SHIFT);
}

fn matrixColumns(data_ptr: ?*const anyopaque) u16 {
    return @intCast((readMatrixHeaderDescriptor(data_ptr) & Z47_LOCAL_MATRIX_COLUMNS_MASK) >> Z47_LOCAL_MATRIX_COLUMNS_SHIFT);
}

fn setMatrixRowsColumns(data_ptr: ?*anyopaque, rows: u16, columns: u16) void {
    var descriptor = readMatrixHeaderDescriptor(data_ptr);
    descriptor &= ~(Z47_LOCAL_MATRIX_ROWS_MASK | Z47_LOCAL_MATRIX_COLUMNS_MASK);
    descriptor |= (@as(u32, rows) & 0x0fff) << Z47_LOCAL_MATRIX_ROWS_SHIFT;
    descriptor |= (@as(u32, columns) & 0x0fff) << Z47_LOCAL_MATRIX_COLUMNS_SHIFT;
    copyValueToBytes(u32, data_ptr, &descriptor);
}

pub fn globalDescriptor(reg: calcRegister_t) register_descriptor_t {
    return descriptor_storage.globalDescriptor(reg);
}

pub fn setGlobalDescriptor(reg: calcRegister_t, descriptor: register_descriptor_t) void {
    descriptor_storage.setGlobalDescriptor(reg, descriptor);
}

pub fn tryGetNamedDescriptor(reg: calcRegister_t, descriptor: *register_descriptor_t) bool {
    return descriptor_storage.tryGetNamedDescriptor(reg, descriptor);
}

pub fn trySetNamedDescriptor(reg: calcRegister_t, descriptor: register_descriptor_t) bool {
    return descriptor_storage.trySetNamedDescriptor(reg, descriptor);
}

pub fn namedDescriptorUnchecked(index: u16) register_descriptor_t {
    return descriptor_storage.namedDescriptorUnchecked(index);
}

pub fn setNamedDescriptorUnchecked(index: u16, descriptor: register_descriptor_t) void {
    descriptor_storage.setNamedDescriptorUnchecked(index, descriptor);
}

pub fn tryGetLocalDescriptor(reg: calcRegister_t, descriptor: *register_descriptor_t) bool {
    return descriptor_storage.tryGetLocalDescriptor(reg, descriptor);
}

pub fn trySetLocalDescriptor(reg: calcRegister_t, descriptor: register_descriptor_t) bool {
    return descriptor_storage.trySetLocalDescriptor(reg, descriptor);
}

pub fn reservedDescriptor(reg: calcRegister_t) register_descriptor_t {
    return z47_register_metadata_get_reserved_descriptor(reg);
}

pub fn reservedDataTypeDescriptor(reg: calcRegister_t) register_descriptor_t {
    return z47_register_metadata_get_reserved_data_type_descriptor(reg);
}

pub fn reservedAllowsDataTypeWrite(reg: calcRegister_t) bool {
    return z47_register_metadata_reserved_allows_data_type_write(reg);
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
    return toBlocks(@sizeOf(strLgIntHeader_t));
}

pub fn matrixHeaderSizeInBlocks() u16 {
    return toBlocks(@sizeOf(matrixHeader_t));
}

pub fn real34SizeInBlocks() u16 {
    return stack_runtime.real34SizeInBlocks();
}

pub fn complex34SizeInBlocks() u16 {
    return real34SizeInBlocks() * 2;
}

pub fn shortIntegerSizeInBlocks() u16 {
    return 2;
}

pub fn configSizeInBlocks() u16 {
    return z47_register_metadata_config_size_in_blocks();
}

pub fn memoryBlockAvailable(size_in_blocks: u16) bool {
    return isMemoryBlockAvailable(size_in_blocks, 2, 0.1);
}

pub fn alignLongIntegerBlocks(size_in_blocks: u16) u16 {
    const limb_size_in_bytes = @sizeOf(usize);
    const limb_size_in_blocks = toBlocks(limb_size_in_bytes);

    if ((@as(usize, size_in_blocks) * bytesPerBlock()) % limb_size_in_bytes != 0) {
        return @intCast(((@as(usize, size_in_blocks) / limb_size_in_blocks) + 1) * limb_size_in_blocks);
    }

    return size_in_blocks;
}

pub fn initializeMatrixHeader1x1(data_ptr: ?*anyopaque) void {
    setMatrixRowsColumns(data_ptr, 1, 1);
}

pub fn reportRamFull() void {
    displayCalcErrorMessage(stack_runtime.ERROR_RAM_FULL, if (use_fake_register_metadata_harness_surface) REGISTER_X else stack_runtime.REGISTER_Z, if (use_fake_register_metadata_harness_surface) REGISTER_Y else REGISTER_X);
}

pub fn toPcMemPtr(mem_ptr: u16) ?*anyopaque {
    return z47_register_metadata_to_pc_mem_ptr(mem_ptr);
}

pub fn toC47MemPtr(mem_ptr: ?*const anyopaque) u16 {
    return z47_register_metadata_to_c47_mem_ptr(mem_ptr);
}

pub fn builtinMenuItemCount() u32 {
    return z47_register_metadata_builtin_menu_item_count();
}

pub fn builtinMenuItemIsMenu(index: u32) bool {
    return z47_register_metadata_builtin_menu_item_is_menu(index);
}

pub fn builtinMenuItemName(index: u32) [*c]const u8 {
    return z47_register_metadata_builtin_menu_item_name(index);
}

pub fn userMenuCount() u32 {
    return numberOfUserMenus;
}

pub fn userMenuName(index: u32) [*c]const u8 {
    if (index >= numberOfUserMenus) {
        return "";
    }

    return @ptrCast(&userMenus[index].menuName[0]);
}

pub fn namedVariableName(index: u16) [*c]const u8 {
    if (index >= numberOfNamedVariables or (use_fake_register_metadata_harness_surface and index >= max_fake_named_variables)) {
        return "";
    }

    const headers = allNamedVariables orelse return "";
    return @ptrCast(&headers[index].variableName[1]);
}

pub fn allocateFirstNamedVariableHeader() bool {
    return z47_register_metadata_allocate_first_named_variable_header();
}

pub fn appendNamedVariableHeader(index: *u16) bool {
    return z47_register_metadata_append_named_variable_header(index);
}

pub fn storeNamedVariableName(index: u16, variable_name: [*c]const u8) void {
    z47_register_metadata_store_named_variable_name(index, variable_name);
}

pub fn removeNamedVariableRecallAssignment(index: u16) void {
    if (use_fake_register_metadata_harness_surface or index >= numberOfNamedVariables) {
        return;
    }

    const headers = allNamedVariables orelse return;
    removeUserItemAssignments(@intCast(ITM_RCL), @ptrCast(&headers[index].variableName[1]));
}

pub fn clearNamedVariableSlot(index: u16) void {
    z47_register_metadata_clear_named_variable_slot(index);
}

pub fn shrinkNamedVariableHeaderStorage() void {
    z47_register_metadata_shrink_named_variable_header_storage();
}

pub fn compareMenuNames(left: [*c]const u8, right: [*c]const u8) i32 {
    return z47_register_metadata_compare_menu_names(left, right);
}

pub fn findReservedVariableName(variable_name: [*c]const u8, glyph_length: u8) calcRegister_t {
    return z47_register_metadata_find_reserved_variable_name(variable_name, glyph_length);
}

pub fn reportInvalidName() void {
    displayCalcErrorMessage(ERROR_INVALID_NAME, if (use_fake_register_metadata_harness_surface) REGISTER_X else stack_runtime.REGISTER_Z, if (use_fake_register_metadata_harness_surface) REGISTER_Y else REGISTER_X);
}

pub fn reportUndefSourceVar() void {
    displayCalcErrorMessage(ERROR_UNDEF_SOURCE_VAR, if (use_fake_register_metadata_harness_surface) REGISTER_X else stack_runtime.REGISTER_Z, if (use_fake_register_metadata_harness_surface) REGISTER_Y else REGISTER_X);
}

pub fn reportCannotDeletePredefItem() void {
    displayCalcErrorMessage(ERROR_CANNOT_DELETE_PREDEF_ITEM, if (use_fake_register_metadata_harness_surface) REGISTER_X else stack_runtime.REGISTER_Z, if (use_fake_register_metadata_harness_surface) REGISTER_Y else REGISTER_X);
}

pub fn reportTooManyVariables() void {
    displayCalcErrorMessage(ERROR_TOO_MANY_VARIABLES, if (use_fake_register_metadata_harness_surface) REGISTER_X else stack_runtime.REGISTER_Z, if (use_fake_register_metadata_harness_surface) REGISTER_Y else REGISTER_X);
}

pub fn clearSigma() void {
    if (!use_fake_register_metadata_harness_surface) {
        fnClSigma(CONFIRMED);
        return;
    }

    var register = findNamedVariable("HISTO");
    if (register != INVALID_VARIABLE) {
        fnDeleteVariable(@intCast(register));
    }

    register = findNamedVariable("STATS");
    if (register != INVALID_VARIABLE) {
        fnDeleteVariable(@intCast(register));
    }

    stack_runtime.lrChosen = 0;
    stack_runtime.freeC47Blocks(stack_runtime.statisticalSumsPointer, stack_runtime.statisticalSumsBlocks());
    stack_runtime.statisticalSumsPointer = null;
}

pub fn requestDeleteAllVariablesConfirmation() void {
    if (use_fake_register_metadata_harness_surface) {
        z47_register_metadata_request_delete_all_variables_confirmation();
        return;
    }

    setConfirmationMode(&fnDeleteAllVariables);
}

pub fn requestClearAllVariablesConfirmation() void {
    if (use_fake_register_metadata_harness_surface) {
        z47_register_metadata_request_clear_all_variables_confirmation();
        return;
    }

    setConfirmationMode(&fnClearAllVariables);
}

pub fn allocateLocalRegistersRetained(number_of_registers_to_allocate: u16) void {
    z47_registers_retained_allocateLocalRegisters(number_of_registers_to_allocate);
}

pub fn reallocateRegisterRetained(reg: calcRegister_t, data_type: u32, data_size_without_data_len_blocks: u16, tag: u32) void {
    z47_registers_retained_reallocateRegister(reg, data_type, data_size_without_data_len_blocks, tag);
}
