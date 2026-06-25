const build_options = @import("register_metadata_build_options");
const descriptor_storage = @import("register_descriptor_storage_owned.zig");

const use_fake_register_metadata_harness_surface =
    @hasDecl(build_options, "use_fake_register_metadata_harness_surface") and
    build_options.use_fake_register_metadata_harness_surface;

pub const calcRegister_t = i16;
pub const register_descriptor_t = u32;

const FIRST_RESERVED_VARIABLE: calcRegister_t = 2000;
// LAST_RESERVED_VARIABLE 2047 - FIRST_RESERVED_VARIABLE 2000 + 1. The defines.h
// inline comment claiming 41 is stale; the array holds 48 entries.
const NUMBER_OF_RESERVED_VARIABLES: usize = 48;
const NUMBER_OF_LETTERED_VARIABLES: calcRegister_t = 26;
const REGISTER_X: calcRegister_t = 100;
const INVALID_VARIABLE: calcRegister_t = 2199;
const C47_NULL: u32 = 65535;
const CMP_NAME: i32 = 3;
const LAST_ITEM: u32 = 2850;
const CAT_STATUS: u16 = 0x00f0;
const CAT_MENU: u16 = 2 << 4;
const NAMED_VARIABLE_NAME_LENGTH: usize = 16;

const register_header_t = extern union {
    descriptor: register_descriptor_t,
};

const named_variable_header_t = extern struct {
    header: register_header_t,
    variableName: [NAMED_VARIABLE_NAME_LENGTH]u8,
};

const reserved_variable_header_t = extern struct {
    header: register_header_t,
    reservedVariableName: [8]u8,
};

// item_t mirrors the upstream layout: a target-sized function pointer, then the
// catalog and softmenu names with the status word trailing. sizeof is 48 on the
// 64-bit host and itemCatalogName sits at offset 10, status at 44.
const item_t = extern struct {
    func: ?*const anyopaque,
    param: u16,
    itemCatalogName: [16]u8,
    itemSoftmenuName: [16]u8,
    tamMinMax: u16,
    status: u16,
};

extern var allNamedVariables: ?[*]named_variable_header_t;
extern var numberOfNamedVariables: u16;
extern const allReservedVariables: [NUMBER_OF_RESERVED_VARIABLES]reserved_variable_header_t;
extern const indexOfItems: [LAST_ITEM + 1]item_t;
extern var ram: [*c]u32;

extern fn allocC47Blocks(size_in_blocks: usize) ?*anyopaque;
extern fn reallocC47Blocks(pc_mem_ptr: ?*anyopaque, old_size_in_blocks: usize, new_size_in_blocks: usize) ?*anyopaque;
extern fn reduceC47Blocks(pc_mem_ptr: ?*anyopaque, old_size_in_blocks: usize, new_size_in_blocks: usize) void;
extern fn compareString(stra: [*c]const u8, strb: [*c]const u8, comparison_type: i32) i32;

extern fn z47_register_metadata_get_reserved_descriptor(reg: calcRegister_t) register_descriptor_t;
extern fn z47_register_metadata_get_reserved_data_type_descriptor(reg: calcRegister_t) register_descriptor_t;
extern fn z47_register_metadata_reserved_allows_data_type_write(reg: calcRegister_t) bool;
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

fn toBlocks(bytes: usize) usize {
    return (bytes + 3) >> 2;
}

fn namedVariableHeaderBlocks(count: usize) usize {
    return toBlocks(@sizeOf(named_variable_header_t) * count);
}

pub fn reservedDescriptor(reg: calcRegister_t) register_descriptor_t {
    if (use_fake_register_metadata_harness_surface) {
        return z47_register_metadata_get_reserved_descriptor(reg);
    }
    return allReservedVariables[@intCast(reg - FIRST_RESERVED_VARIABLE)].header.descriptor;
}

pub fn reservedDataTypeDescriptor(reg: calcRegister_t) register_descriptor_t {
    if (use_fake_register_metadata_harness_surface) {
        return z47_register_metadata_get_reserved_data_type_descriptor(reg);
    }
    const index = reg - FIRST_RESERVED_VARIABLE;
    if (index < NUMBER_OF_LETTERED_VARIABLES) {
        return descriptor_storage.globalDescriptor(index + REGISTER_X);
    }
    return allReservedVariables[@intCast(index)].header.descriptor;
}

pub fn reservedAllowsDataTypeWrite(reg: calcRegister_t) bool {
    if (use_fake_register_metadata_harness_surface) {
        return z47_register_metadata_reserved_allows_data_type_write(reg);
    }
    const descriptor = allReservedVariables[@intCast(reg - FIRST_RESERVED_VARIABLE)].header.descriptor;
    return (descriptor & 0xffff) != C47_NULL and ((descriptor >> 25) & 0x01) == 0;
}

pub fn toPcMemPtr(mem_ptr: u16) ?*anyopaque {
    if (use_fake_register_metadata_harness_surface) {
        return z47_register_metadata_to_pc_mem_ptr(mem_ptr);
    }
    if (mem_ptr == C47_NULL) {
        return null;
    }
    return @ptrCast(&ram[mem_ptr]);
}

pub fn toC47MemPtr(mem_ptr: ?*const anyopaque) u16 {
    if (use_fake_register_metadata_harness_surface) {
        return z47_register_metadata_to_c47_mem_ptr(mem_ptr);
    }
    const ptr = mem_ptr orelse return @intCast(C47_NULL);
    return @intCast((@intFromPtr(ptr) - @intFromPtr(ram)) / @sizeOf(u32));
}

pub fn builtinMenuItemCount() u32 {
    if (use_fake_register_metadata_harness_surface) {
        return z47_register_metadata_builtin_menu_item_count();
    }
    return LAST_ITEM;
}

pub fn builtinMenuItemIsMenu(index: u32) bool {
    if (use_fake_register_metadata_harness_surface) {
        return z47_register_metadata_builtin_menu_item_is_menu(index);
    }
    return index < LAST_ITEM and (indexOfItems[index].status & CAT_STATUS) == CAT_MENU;
}

pub fn builtinMenuItemName(index: u32) [*c]const u8 {
    if (use_fake_register_metadata_harness_surface) {
        return z47_register_metadata_builtin_menu_item_name(index);
    }
    if (index >= LAST_ITEM) {
        return "";
    }
    return &indexOfItems[index].itemCatalogName[0];
}

pub fn allocateFirstNamedVariableHeader() bool {
    if (use_fake_register_metadata_harness_surface) {
        return z47_register_metadata_allocate_first_named_variable_header();
    }
    const ptr = allocC47Blocks(namedVariableHeaderBlocks(1));
    allNamedVariables = @ptrCast(@alignCast(ptr));
    if (ptr == null) {
        return false;
    }
    numberOfNamedVariables = 1;
    return true;
}

pub fn appendNamedVariableHeader(index: *u16) bool {
    if (use_fake_register_metadata_harness_surface) {
        return z47_register_metadata_append_named_variable_header(index);
    }
    const orig = allNamedVariables;
    index.* = numberOfNamedVariables;
    const ptr = reallocC47Blocks(
        @ptrCast(allNamedVariables),
        namedVariableHeaderBlocks(numberOfNamedVariables),
        namedVariableHeaderBlocks(@as(usize, numberOfNamedVariables) + 1),
    );
    if (ptr != null) {
        allNamedVariables = @ptrCast(@alignCast(ptr));
        numberOfNamedVariables += 1;
        return true;
    }
    allNamedVariables = orig;
    return false;
}

pub fn storeNamedVariableName(index: u16, variable_name: [*c]const u8) void {
    if (use_fake_register_metadata_harness_surface) {
        z47_register_metadata_store_named_variable_name(index, variable_name);
        return;
    }
    const headers = allNamedVariables orelse return;
    const name_field = &headers[index].variableName;

    var len: usize = 0;
    while (variable_name[len] != 0) : (len += 1) {}
    if (len > NAMED_VARIABLE_NAME_LENGTH - 1) {
        len = NAMED_VARIABLE_NAME_LENGTH - 1;
    }

    name_field[0] = @intCast(len);
    @memset(name_field[1..], 0);
    var i: usize = 0;
    while (i < len) : (i += 1) {
        name_field[1 + i] = variable_name[i];
    }
}

pub fn clearNamedVariableSlot(index: u16) void {
    if (use_fake_register_metadata_harness_surface) {
        z47_register_metadata_clear_named_variable_slot(index);
        return;
    }
    if (index >= numberOfNamedVariables) {
        return;
    }
    const headers = allNamedVariables orelse return;
    headers[index].header.descriptor = 0;
    @memset(&headers[index].variableName, 0);
}

pub fn shrinkNamedVariableHeaderStorage() void {
    if (use_fake_register_metadata_harness_surface) {
        z47_register_metadata_shrink_named_variable_header_storage();
        return;
    }
    if (numberOfNamedVariables == 0) {
        return;
    }
    reduceC47Blocks(
        @ptrCast(allNamedVariables),
        namedVariableHeaderBlocks(numberOfNamedVariables),
        namedVariableHeaderBlocks(@as(usize, numberOfNamedVariables) - 1),
    );
}

pub fn compareMenuNames(left: [*c]const u8, right: [*c]const u8) i32 {
    if (use_fake_register_metadata_harness_surface) {
        return z47_register_metadata_compare_menu_names(left, right);
    }
    return compareString(left, right, CMP_NAME);
}

pub fn findReservedVariableName(variable_name: [*c]const u8, glyph_length: u8) calcRegister_t {
    if (use_fake_register_metadata_harness_surface) {
        return z47_register_metadata_find_reserved_variable_name(variable_name, glyph_length);
    }
    var reg: usize = 0;
    while (reg < NUMBER_OF_RESERVED_VARIABLES) : (reg += 1) {
        if (allReservedVariables[reg].reservedVariableName[0] != glyph_length) {
            continue;
        }
        if (compareString(variable_name, &allReservedVariables[reg].reservedVariableName[1], CMP_NAME) == 0) {
            return FIRST_RESERVED_VARIABLE + @as(calcRegister_t, @intCast(reg));
        }
    }
    return INVALID_VARIABLE;
}
