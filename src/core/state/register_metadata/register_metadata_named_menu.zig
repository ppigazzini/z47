const ITM_RCL: u16 = 51;

const abi = @import("abi"); // shared ABI bindings
const userMenu_t = abi.UserMenu;

const register_descriptor_t = u32;

const named_variable_header_t = abi.NamedVariableHeader;

extern var numberOfNamedVariables: u16;
extern var userMenus: [*c]userMenu_t;
extern var numberOfUserMenus: u16;
extern var allNamedVariables: ?[*]named_variable_header_t;
extern fn removeUserItemAssignments(item: i16, user_item_name: [*c]u8) void;

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
    if (index >= numberOfNamedVariables) {
        return "";
    }

    const headers = allNamedVariables orelse return "";
    return @ptrCast(&headers[index].variableName[1]);
}

pub fn removeNamedVariableRecallAssignment(index: u16) void {
    if (index >= numberOfNamedVariables) {
        return;
    }

    const headers = allNamedVariables orelse return;
    removeUserItemAssignments(@intCast(ITM_RCL), @ptrCast(&headers[index].variableName[1]));
}
