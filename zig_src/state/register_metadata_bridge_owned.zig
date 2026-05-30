pub const calcRegister_t = i16;

extern fn z47_register_metadata_to_pc_mem_ptr(mem_ptr: u16) ?*anyopaque;
extern fn z47_register_metadata_to_c47_mem_ptr(mem_ptr: ?*const anyopaque) u16;
extern fn z47_register_metadata_builtin_menu_item_count() u32;
extern fn z47_register_metadata_builtin_menu_item_is_menu(index: u32) bool;
extern fn z47_register_metadata_builtin_menu_item_name(index: u32) [*c]const u8;
extern fn z47_registers_retained_allocateLocalRegisters(number_of_registers_to_allocate: u16) void;
extern fn z47_registers_retained_reallocateRegister(reg: calcRegister_t, data_type: u32, data_size_without_data_len_blocks: u16, tag: u32) void;

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

pub fn allocateLocalRegistersRetained(number_of_registers_to_allocate: u16) void {
    z47_registers_retained_allocateLocalRegisters(number_of_registers_to_allocate);
}

pub fn reallocateRegisterRetained(reg: calcRegister_t, data_type: u32, data_size_without_data_len_blocks: u16, tag: u32) void {
    z47_registers_retained_reallocateRegister(reg, data_type, data_size_without_data_len_blocks, tag);
}