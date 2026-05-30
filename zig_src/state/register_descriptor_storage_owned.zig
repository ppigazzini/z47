const build_options = @import("state_descriptor_storage_build_options");

pub const calcRegister_t = i16;
pub const register_descriptor_t = u32;

pub const LAST_GLOBAL_REGISTER: calcRegister_t = 136;
pub const FIRST_NAMED_VARIABLE: calcRegister_t = 256;
pub const FIRST_LOCAL_REGISTER: calcRegister_t = 7000;

const number_of_global_registers: usize = @intCast(LAST_GLOBAL_REGISTER + 1);
const use_array_backed_global_registers =
    @hasDecl(build_options, "use_array_backed_global_registers") and
    build_options.use_array_backed_global_registers;

const register_header_t = extern union {
    descriptor: register_descriptor_t,
};

const named_variable_header_t = extern struct {
    header: register_header_t,
    variableName: [16]u8,
};

const GlobalRegisterBacking = if (use_array_backed_global_registers)
    [number_of_global_registers]register_header_t
else
    [*]register_header_t;

extern var globalRegister: GlobalRegisterBacking;
extern var allNamedVariables: ?[*]named_variable_header_t;
extern var currentLocalRegisters: ?[*]register_header_t;
extern var numberOfNamedVariables: u16;
extern var currentNumberOfLocalRegisters: u8;

fn globalRegisterHeader(reg: calcRegister_t) *register_header_t {
    const index: usize = @intCast(reg);
    return &globalRegister[index];
}

pub fn globalDescriptor(reg: calcRegister_t) register_descriptor_t {
    return globalRegisterHeader(reg).descriptor;
}

pub fn setGlobalDescriptor(reg: calcRegister_t, descriptor: register_descriptor_t) void {
    globalRegisterHeader(reg).descriptor = descriptor;
}

pub fn tryGetNamedDescriptor(reg: calcRegister_t, descriptor: *register_descriptor_t) bool {
    if (reg < FIRST_NAMED_VARIABLE or numberOfNamedVariables == 0) {
        return false;
    }

    const index: u16 = @intCast(reg - FIRST_NAMED_VARIABLE);
    if (index >= numberOfNamedVariables) {
        return false;
    }

    const headers = allNamedVariables orelse return false;
    descriptor.* = headers[index].header.descriptor;
    return true;
}

pub fn trySetNamedDescriptor(reg: calcRegister_t, descriptor: register_descriptor_t) bool {
    if (reg < FIRST_NAMED_VARIABLE or numberOfNamedVariables == 0) {
        return false;
    }

    const index: u16 = @intCast(reg - FIRST_NAMED_VARIABLE);
    if (index >= numberOfNamedVariables) {
        return false;
    }

    const headers = allNamedVariables orelse return false;
    headers[index].header.descriptor = descriptor;
    return true;
}

pub fn tryGetLocalDescriptor(reg: calcRegister_t, descriptor: *register_descriptor_t) bool {
    if (reg < FIRST_LOCAL_REGISTER) {
        return false;
    }

    const index: u16 = @intCast(reg - FIRST_LOCAL_REGISTER);
    if (index >= currentNumberOfLocalRegisters) {
        return false;
    }

    const headers = currentLocalRegisters orelse return false;
    descriptor.* = headers[index].descriptor;
    return true;
}

pub fn trySetLocalDescriptor(reg: calcRegister_t, descriptor: register_descriptor_t) bool {
    if (reg < FIRST_LOCAL_REGISTER) {
        return false;
    }

    const index: u16 = @intCast(reg - FIRST_LOCAL_REGISTER);
    if (index >= currentNumberOfLocalRegisters) {
        return false;
    }

    const headers = currentLocalRegisters orelse return false;
    headers[index].descriptor = descriptor;
    return true;
}