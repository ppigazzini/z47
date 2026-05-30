pub const calcRegister_t = i16;

extern fn z47_register_metadata_allocate_first_named_variable_header() bool;
extern fn z47_register_metadata_append_named_variable_header(index: *u16) bool;
extern fn z47_register_metadata_store_named_variable_name(index: u16, variable_name: [*c]const u8) void;
extern fn z47_register_metadata_clear_named_variable_slot(index: u16) void;
extern fn z47_register_metadata_shrink_named_variable_header_storage() void;
extern fn z47_register_metadata_compare_menu_names(left: [*c]const u8, right: [*c]const u8) i32;
extern fn z47_register_metadata_find_reserved_variable_name(variable_name: [*c]const u8, glyph_length: u8) calcRegister_t;

pub fn allocateFirstNamedVariableHeader() bool {
    return z47_register_metadata_allocate_first_named_variable_header();
}

pub fn appendNamedVariableHeader(index: *u16) bool {
    return z47_register_metadata_append_named_variable_header(index);
}

pub fn storeNamedVariableName(index: u16, variable_name: [*c]const u8) void {
    z47_register_metadata_store_named_variable_name(index, variable_name);
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