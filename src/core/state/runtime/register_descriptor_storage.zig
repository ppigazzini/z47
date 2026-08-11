const build_options = @import("state_descriptor_storage_build_options");

/// Index of `reg` inside a band that starts at `first` and holds `count` entries,
/// or null when the register is not one of them.
///
/// registers.c subtracts the band base and then tests only the upper bound
/// (`regist -= FIRST_NAMED_VARIABLE; if(regist < numberOfNamedVariables)`).
/// calcRegister_t is int16_t and both operands promote to int, so a register in
/// the 137..255 gap or the 2048..6999 label band yields a NEGATIVE index that
/// passes that test and reads or writes in front of the array. The `reg < first`
/// test here is the only difference: for every register that is genuinely in the
/// band the two agree exactly, and for the two gap bands z47 reports the register
/// as absent instead of touching memory it does not own.
fn resolveIndex(reg: i16, first: i16, count: u16) ?u16 {
    if (reg < first or count == 0) return null;
    const index: u16 = @intCast(reg - first);
    if (index >= count) return null;
    return index;
}

pub const calcRegister_t = i16;
pub const register_descriptor_t = u32;

pub const LAST_GLOBAL_REGISTER: calcRegister_t = 136;
pub const FIRST_NAMED_VARIABLE: calcRegister_t = 256;
pub const FIRST_LOCAL_REGISTER: calcRegister_t = 7000;

const number_of_global_registers: usize = @intCast(LAST_GLOBAL_REGISTER + 1);
const use_array_backed_global_registers =
    build_options.use_array_backed_global_registers;
const use_fake_state_harness_surface =
    build_options.use_fake_state_harness_surface;

const register_header_t = abi.RegisterHeader;

const named_variable_header_t = abi.NamedVariableHeader;

const abi = @import("abi"); // shared ABI bindings
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
    const index = resolveIndex(reg, FIRST_NAMED_VARIABLE, numberOfNamedVariables) orelse return false;
    const headers = allNamedVariables orelse return false;
    descriptor.* = headers[index].header.descriptor;
    return true;
}

pub fn trySetNamedDescriptor(reg: calcRegister_t, descriptor: register_descriptor_t) bool {
    const index = resolveIndex(reg, FIRST_NAMED_VARIABLE, numberOfNamedVariables) orelse return false;
    const headers = allNamedVariables orelse return false;
    headers[index].header.descriptor = descriptor;
    return true;
}

/// True when no local-register frame exists at all, which is the one failure
/// the C reports on the console; an index past the frame's end is a bug screen.
pub fn noLocalRegisterFrame() bool {
    return currentLocalRegisters == null;
}

pub fn tryGetLocalDescriptor(reg: calcRegister_t, descriptor: *register_descriptor_t) bool {
    const index = resolveIndex(reg, FIRST_LOCAL_REGISTER, localRegisterCount()) orelse return false;
    const headers = currentLocalRegisters orelse return false;
    descriptor.* = headers[index].descriptor;
    return true;
}

pub fn trySetLocalDescriptor(reg: calcRegister_t, descriptor: register_descriptor_t) bool {
    const index = resolveIndex(reg, FIRST_LOCAL_REGISTER, localRegisterCount()) orelse return false;
    const headers = currentLocalRegisters orelse return false;
    headers[index].descriptor = descriptor;
    return true;
}

pub fn currentLocalRegisterCount() u8 {
    return localRegisterCount();
}
