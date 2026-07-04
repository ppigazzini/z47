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
const use_fake_state_harness_surface =
    @hasDecl(build_options, "use_fake_state_harness_surface") and
    build_options.use_fake_state_harness_surface;

const register_header_t = abi.RegisterHeader;

const named_variable_header_t = abi.NamedVariableHeader;

const abi = @import("abi"); // L1 shared bindings
const subroutineLevelHeader_t = abi.SubroutineLevelHeader;

const GlobalRegisterBacking = if (use_array_backed_global_registers)
    [number_of_global_registers]register_header_t
else
    [*]register_header_t;

extern var globalRegister: GlobalRegisterBacking;
extern var allNamedVariables: ?[*]named_variable_header_t;
extern var currentLocalRegisters: ?[*]register_header_t;
extern var numberOfNamedVariables: u16;
extern var currentSubroutineLevelData: ?*subroutineLevelHeader_t;

comptime {
    if (use_fake_state_harness_surface) {
        _ = struct {
            extern var currentNumberOfLocalRegisters: u8;
        };
    }
}

fn localRegisterCount() u8 {
    if (use_fake_state_harness_surface) {
        const fake = struct {
            extern var currentNumberOfLocalRegisters: u8;
        };
        return fake.currentNumberOfLocalRegisters;
    }

    const current_level = currentSubroutineLevelData orelse return 0;
    return current_level.numberOfLocalRegisters;
}

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

pub fn namedDescriptorUnchecked(index: u16) register_descriptor_t {
    const headers = allNamedVariables orelse return 0;
    return headers[index].header.descriptor;
}

pub fn setNamedDescriptorUnchecked(index: u16, descriptor: register_descriptor_t) void {
    const headers = allNamedVariables orelse return;
    headers[index].header.descriptor = descriptor;
}

pub fn tryGetLocalDescriptor(reg: calcRegister_t, descriptor: *register_descriptor_t) bool {
    if (reg < FIRST_LOCAL_REGISTER) {
        return false;
    }

    const index: u16 = @intCast(reg - FIRST_LOCAL_REGISTER);
    if (index >= localRegisterCount()) {
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
    if (index >= localRegisterCount()) {
        return false;
    }

    const headers = currentLocalRegisters orelse return false;
    headers[index].descriptor = descriptor;
    return true;
}

pub fn currentLocalRegisterCount() u8 {
    return localRegisterCount();
}