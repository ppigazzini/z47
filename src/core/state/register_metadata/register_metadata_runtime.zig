const descriptor_storage = @import("../runtime/register_descriptor_storage.zig");
const named_menu_owned = @import("register_metadata_named_menu.zig");
const size_owned = @import("register_metadata_size.zig");
const stack_runtime = @import("../runtime/stack_runtime.zig");
const tables_owned = @import("register_metadata_tables.zig");
const error_owned = @import("register_metadata_error.zig");
const payload_bytes_owned = @import("register_metadata_payload_bytes.zig");

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

const abi = @import("abi"); // shared ABI bindings
const register_metadata = @import("../register_metadata.zig");
const register_metadata_local_registers = @import("register_metadata_local_registers.zig");
const userMenu_t = abi.UserMenu;

const named_variable_header_t = abi.NamedVariableHeader;

pub const REGISTER_X = stack_runtime.REGISTER_X;
pub const REGISTER_Y = stack_runtime.REGISTER_Y;
pub const LAST_GLOBAL_REGISTER = stack_runtime.LAST_GLOBAL_REGISTER;
pub const FIRST_NAMED_VARIABLE: calcRegister_t = 256;
pub const LAST_NAMED_VARIABLE: calcRegister_t = 1999;
pub const FIRST_RESERVED_VARIABLE: calcRegister_t = 2000;
// defines.h: the 26 lettered variables occupy 2000-2025, five
// RESERVED_VARIABLE_SPARE placeholders 2026-2030, and the NAMED block starts at
// RESERVED_VARIABLE_ACC = 2031.
//
// This was 2026, with ADM/DENMAX/ISM/REALDF/NDEC named at
// 2026-2030 -- five names c43 removed when it inserted the spares, and which live
// in the CONFIG block now (config.h fnGetADM / fnGetREALDF / fnGetNDEC). Two
// models coexisted in one tree: frontier_config and softmenus already used
// ACC=2031/FV=2034/PMT=2038/PV=2039/UX=2041, while the range-check owners used
// 2026. reserved-variable IDs are serialized into state files, so this was a
// parity gap independently of the oracle work it was blocking.
pub const FIRST_NAMED_RESERVED_VARIABLE: calcRegister_t = 2031;
pub const LAST_RESERVED_VARIABLE: calcRegister_t = 2047;
pub const FIRST_LOCAL_REGISTER = stack_runtime.FIRST_LOCAL_REGISTER;
pub const LAST_LOCAL_REGISTER = stack_runtime.LAST_LOCAL_REGISTER;
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
pub const ITM_XtoALPHA: u16 = 2785; // items.h: 2785 (fnXToAlpha). 1645 was fnXToAlphaOld, making isFunctionAllowingNewVariable match the deprecated x->alpha instead of the current one.
pub const ITM_Xex: u16 = 127;
pub const ITM_Yex: u16 = 1650;
pub const ITM_Zex: u16 = 1651;
pub const ITM_INTEGRAL: u16 = 1700;
pub const ITM_INTEGRAL_YX: u16 = 1690;
pub const ITM_PLTf: u16 = 2734;
pub const ITM_F1DRV: u16 = 2883;
pub const ITM_F2DRV: u16 = 2884;

pub extern var currentAngularMode: u32;
pub extern var numberOfNamedVariables: u16;
pub extern var temporaryInformation: u8;
pub extern var userMenus: [*c]userMenu_t;
pub extern var numberOfUserMenus: u16;
pub extern var currentSolverVariable: u16;
pub extern var graphVariabl1: calcRegister_t;
// debug.c's data-type name, for the two bug screens that quote it.
pub extern fn getDataTypeName(data_type: u16, with_article: bool, pad_with_blanks: bool) [*c]const u8;
// The second line of an error screen, which every accessor here uses to say which
// register frame was missing. m2..m4 are nullable: upstream passes NULL where it
// has nothing to add and "" where it wants the blank line.
pub extern fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) void;

// The TVM engine keeps I%/a and i% in step, so a store into either half -- or into
// the payment or compounding frequency the conversion between them uses -- has to
// recompute the partner. tvm.zig owns the arithmetic.
pub const RESERVED_VARIABLE_IPONA: calcRegister_t = 2035;
pub const RESERVED_VARIABLE_PPERONA: calcRegister_t = 2037;
pub const RESERVED_VARIABLE_IP: calcRegister_t = 2040;
pub const RESERVED_VARIABLE_CPERONA: calcRegister_t = 2043;
pub extern fn tvmSyncIp(written: calcRegister_t) void;

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

pub fn noLocalRegisterFrame() bool {
    return descriptor_storage.noLocalRegisterFrame();
}

pub fn tryGetLocalDescriptor(reg: calcRegister_t, descriptor: *register_descriptor_t) bool {
    return descriptor_storage.tryGetLocalDescriptor(reg, descriptor);
}

pub fn trySetLocalDescriptor(reg: calcRegister_t, descriptor: register_descriptor_t) bool {
    return descriptor_storage.trySetLocalDescriptor(reg, descriptor);
}

pub fn reservedDescriptor(reg: calcRegister_t) register_descriptor_t {
    return tables_owned.reservedDescriptor(reg);
}

pub fn reservedDataTypeDescriptor(reg: calcRegister_t) register_descriptor_t {
    return tables_owned.reservedDataTypeDescriptor(reg);
}

pub fn dataMaxLengthInBlocks(data_ptr: ?*const anyopaque) u16 {
    return payload_bytes_owned.copyBytesToValue(strLgIntHeader_t, data_ptr).dataMaxLengthInBlocks;
}

pub fn setDataMaxLengthInBlocks(data_ptr: ?*anyopaque, max_data_len: u16) void {
    var header = payload_bytes_owned.copyBytesToValue(strLgIntHeader_t, data_ptr);
    header.dataMaxLengthInBlocks = max_data_len;
    payload_bytes_owned.copyValueToBytes(strLgIntHeader_t, data_ptr, &header);
}

pub fn matrixPayloadSizeInBlocks(data_ptr: ?*const anyopaque, element_size_in_blocks: u16) u16 {
    return @intCast(
        @as(u32, payload_bytes_owned.matrixRows(data_ptr)) *
            @as(u32, payload_bytes_owned.matrixColumns(data_ptr)) *
            @as(u32, element_size_in_blocks),
    );
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

pub fn initializeMatrixRegisterHeader1x1(data_ptr: ?*anyopaque) void {
    size_owned.initializeMatrixRegisterHeader1x1(data_ptr);
}

pub fn reportRamFull() void {
    error_owned.reportRamFull();
}

pub fn traceReallocateRamFull(payload_size_in_blocks: u16, reg: calcRegister_t) void {
    error_owned.traceReallocateRamFull(payload_size_in_blocks, reg);
}

pub fn reportNoNamedVariablesBug(function_name: [*:0]const u8) void {
    error_owned.reportNoNamedVariablesBug(function_name);
}

pub fn reportRegisterAboveLastBug(function_name: [*:0]const u8, reg: calcRegister_t) void {
    error_owned.reportRegisterAboveLastBug(function_name, reg, LAST_RESERVED_VARIABLE + 1);
}

pub fn reportVariableNotDefinedBug(function_name: [*:0]const u8, variable_kind: [*:0]const u8, index: u16, last_index: u16) void {
    error_owned.reportVariableNotDefinedBug(function_name, variable_kind, index, last_index);
}

pub fn reportDataTypeUnknownBug(function_name: [*:0]const u8, data_type_name: [*c]const u8) void {
    error_owned.reportDataTypeUnknownBug(function_name, data_type_name);
}

// The accessors report the index inside the block, not the register id, and the
// upper bound is one less than the number of entries the block currently holds.
pub fn reportNamedVariableNotDefined(function_name: [*:0]const u8, reg: calcRegister_t) void {
    error_owned.reportNamedVariableNotDefined(function_name, @bitCast(reg -% FIRST_NAMED_VARIABLE), numberOfNamedVariables -% 1);
}

pub fn reportLocalRegisterNotDefined(function_name: [*:0]const u8, reg: calcRegister_t) void {
    error_owned.reportLocalRegisterNotDefined(function_name, @bitCast(reg -% FIRST_LOCAL_REGISTER), stack_runtime.currentLocalRegisterCount() -% 1);
}

pub fn reportLocalRegisterNotDefinedTwoPart(function_name: [*:0]const u8, reg: calcRegister_t) void {
    error_owned.reportLocalRegisterNotDefinedTwoPart(function_name, @bitCast(reg -% FIRST_LOCAL_REGISTER), stack_runtime.currentLocalRegisterCount() -% 1);
}

pub fn reportReservedVariableRetype(reg: calcRegister_t) void {
    error_owned.reportReservedVariableRetype();
    error_owned.reportReservedVariableRetypeDetail(tables_owned.reservedVariableName(reg));
}

pub fn reportTooManyLocalRegisters(requested: u16) void {
    error_owned.reportTooManyLocalRegisters(requested);
}

pub fn reportBadVariableName(variable_name: [*c]const u8, why: [*:0]const u8, why_continued: ?[*:0]const u8) void {
    error_owned.reportBadVariableName(variable_name, why, why_continued);
}

pub fn reportNamedVariableTableFull(capacity: u16) void {
    error_owned.reportNamedVariableTableFull(capacity);
}

pub fn toPcMemPtr(mem_ptr: u16) ?*anyopaque {
    return tables_owned.toPcMemPtr(mem_ptr);
}

pub fn toC47MemPtr(mem_ptr: ?*const anyopaque) u16 {
    return tables_owned.toC47MemPtr(mem_ptr);
}

pub fn builtinMenuItemCount() u32 {
    return tables_owned.builtinMenuItemCount();
}

pub fn builtinMenuItemIsMenu(index: u32) bool {
    return tables_owned.builtinMenuItemIsMenu(index);
}

pub fn builtinMenuItemName(index: u32) [*c]const u8 {
    return tables_owned.builtinMenuItemName(index);
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

pub fn removeNamedVariableRecallAssignment(index: u16) void {
    named_menu_owned.removeNamedVariableRecallAssignment(index);
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

// Folded in from register_metadata_clear_sigma.zig and
// register_metadata_confirmation.zig. Both were one-line
// forwarders wrapped around a build-option fork that swapped the real call for a
// harness stub; with the unit lane and its fake surface gone, each was left as a
// twelve-line file holding a single call to an extern this module already owns
// the declarations for. That is the barnacle check-file-cohesion.sh names.
extern fn fnClSigma(confirmation: u16) callconv(.c) void;
extern fn setConfirmationMode(handler: *const fn (confirmation: u16) callconv(.c) void) void;

// The confirmation handlers are reached as EXTERNS, not through
// `@import("../register_metadata.zig")`, and that is not incidental: taking the
// Zig-level address of those two exports adds an @import edge that closes an
// eight-file cycle in core/state (check-module-graph.py refuses it, correctly --
// a cycle means those files cannot be read one at a time). setConfirmationMode
// wants a C-ABI function pointer, which is exactly what the export is, so the
// link-time reference is also the more honest spelling of what happens.
extern fn fnDeleteAllVariables(confirmation: u16) callconv(.c) void;
extern fn fnClearAllVariables(confirmation: u16) callconv(.c) void;

pub fn clearSigma() void {
    fnClSigma(CONFIRMED);
}

pub fn requestDeleteAllVariablesConfirmation() void {
    setConfirmationMode(&fnDeleteAllVariables);
}

pub fn requestClearAllVariablesConfirmation() void {
    setConfirmationMode(&fnClearAllVariables);
}

pub fn allocateLocalRegistersRetained(number_of_registers_to_allocate: u16) void {
    register_metadata_local_registers.allocateLocalRegisters(number_of_registers_to_allocate);
}

pub fn reallocateRegisterRetained(reg: calcRegister_t, data_type: u32, data_size_without_data_len_blocks: u16, tag: u32) void {
    register_metadata.reallocateRegister(reg, data_type, data_size_without_data_len_blocks, tag);
}
