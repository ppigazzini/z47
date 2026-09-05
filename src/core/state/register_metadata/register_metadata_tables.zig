// The read-only tables the register-metadata owners consult: the reserved
// variable block, the RAM block-number <-> pointer mapping, and the built-in
// item catalog rows a menu name can resolve to.
//
// Named-variable storage is deliberately NOT here. The header block's allocate /
// append / rename / clear / shrink helpers and the reserved-name lookup live with
// their only caller, in register_metadata_variables.zig, so there is exactly one
// copy of each. A second set used to sit in this file behind unreferenced
// forwarders, and the two had drifted apart: that lookup scanned from the first
// reserved variable, so a one-glyph name such as "X" resolved to the lettered
// reserved register that aliases the stack, and its slot clear zeroed the whole
// sixteen-byte name where registers.c zeroes two bytes.

const descriptor_storage = @import("../runtime/register_descriptor_storage.zig");

pub const calcRegister_t = i16;
pub const register_descriptor_t = u32;

const FIRST_RESERVED_VARIABLE: calcRegister_t = 2000;
// LAST_RESERVED_VARIABLE 2047 - FIRST_RESERVED_VARIABLE 2000 + 1. The defines.h
// inline comment claiming 41 is stale; the array holds 48 entries.
const NUMBER_OF_RESERVED_VARIABLES: usize = 48;
// defines.h computes this as (FIRST_NAMED_RESERVED_VARIABLE -
// FIRST_RESERVED_VARIABLE), which is 31: the 26 lettered variables PLUS the
// five RESERVED_VARIABLE_SPARE placeholders that follow them. z47 had 26 until
// c43's own trailing comment still says 26, and is stale.
const NUMBER_OF_LETTERED_VARIABLES: calcRegister_t = 31;
const REGISTER_X: calcRegister_t = 100;
const C47_NULL: u32 = 65535;
const LAST_ITEM: u32 = 3349;
const CAT_STATUS: u16 = 0x00f0;
const CAT_MENU: u16 = 2 << 4;

const reserved_variable_header_t = abi.ReservedVariableHeader;

// item_t mirrors the upstream layout: a target-sized function pointer, then the
// catalog and softmenu names with the status word trailing. sizeof is 48 on the
// 64-bit host and itemCatalogName sits at offset 10, status at 44.
const abi = @import("abi"); // shared ABI bindings
const item_t = abi.Item;

extern const allReservedVariables: [NUMBER_OF_RESERVED_VARIABLES]reserved_variable_header_t;
extern const indexOfItems: [LAST_ITEM + 1]item_t;
extern var ram: [*c]u32;

pub fn reservedDescriptor(reg: calcRegister_t) register_descriptor_t {
    return allReservedVariables[@intCast(reg - FIRST_RESERVED_VARIABLE)].header.descriptor;
}

/// The reserved variable's display name: the header stores it length-prefixed,
/// and registers.c's diagnostics skip that byte.
pub fn reservedVariableName(reg: calcRegister_t) [*c]const u8 {
    return &allReservedVariables[@intCast(reg - FIRST_RESERVED_VARIABLE)].reservedVariableName[1];
}

pub fn reservedDataTypeDescriptor(reg: calcRegister_t) register_descriptor_t {
    const index = reg - FIRST_RESERVED_VARIABLE;
    if (index < NUMBER_OF_LETTERED_VARIABLES) {
        return descriptor_storage.globalDescriptor(index + REGISTER_X);
    }
    return allReservedVariables[@intCast(index)].header.descriptor;
}

pub fn toPcMemPtr(mem_ptr: u16) ?*anyopaque {
    if (mem_ptr == C47_NULL) {
        return null;
    }
    return @ptrCast(&ram[mem_ptr]);
}

pub fn toC47MemPtr(mem_ptr: ?*const anyopaque) u16 {
    const ptr = mem_ptr orelse return @intCast(C47_NULL);
    return @intCast((@intFromPtr(ptr) - @intFromPtr(ram)) / @sizeOf(u32));
}

pub fn builtinMenuItemCount() u32 {
    return LAST_ITEM;
}

pub fn builtinMenuItemIsMenu(index: u32) bool {
    return index < LAST_ITEM and (indexOfItems[index].status & CAT_STATUS) == CAT_MENU;
}

pub fn builtinMenuItemName(index: u32) [*c]const u8 {
    if (index >= LAST_ITEM) {
        return "";
    }
    return &indexOfItems[index].itemCatalogName[0];
}
