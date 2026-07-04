const std = @import("std");
const abi = @import("abi");
const build_options = @import("register_metadata_build_options");

const descriptor_owned = @import("register_metadata_descriptor_owned.zig");
const memory_owned = @import("register_memory_owned.zig");
const reallocate_owned = @import("register_metadata_reallocate_owned.zig");
const runtime = @import("register_metadata_runtime.zig");
const stack_runtime = @import("stack_runtime.zig");

const validate_name_max_glyphs: usize = 7;
const glyph_A: u16 = 0x41;
const glyph_Z: u16 = 0x5a;
const glyph_a: u16 = 0x61;
const glyph_z: u16 = 0x7a;
const glyph_A_grave: u16 = 0x00c0;
const glyph_cross: u16 = 0x00d7;
const glyph_divide: u16 = 0x00f7;
const glyph_z_caron: u16 = 0x017e;
const glyph_iota_dialytika_tonos: u16 = 0x0390;
const glyph_sampi: u16 = 0x03e1;
const glyph_sub_alpha: u16 = 0x2296;
const glyph_sub_mu: u16 = 0x2298;
const glyph_sup_a: u16 = 0x2482;
const glyph_sub_Z: u16 = 0x24e9;
const compare_name_mode: i32 = 3;
const reserved_variable_count = runtime.LAST_RESERVED_VARIABLE - runtime.FIRST_RESERVED_VARIABLE + 1;
const max_fake_named_variables: u16 = 64;
const use_fake_register_metadata_harness_surface = @hasDecl(build_options, "use_fake_register_metadata_harness_surface") and build_options.use_fake_register_metadata_harness_surface;

const register_header_t = abi.RegisterHeader;

const named_variable_header_t = abi.NamedVariableHeader;

const reserved_variable_header_t = abi.ReservedVariableHeader;

extern var allNamedVariables: ?[*]named_variable_header_t;
extern var allReservedVariables: [reserved_variable_count]reserved_variable_header_t;
extern fn compareString(left: [*c]const u8, right: [*c]const u8, comparison_type: i32) i32;
extern fn isMemoryBlockAvailable(size_in_blocks: usize, num_blocks: u16, extra_fraction: f32) bool;
extern fn reallocC47Blocks(pc_mem_ptr: ?*anyopaque, old_size_in_blocks: usize, new_size_in_blocks: usize) ?*anyopaque;
extern fn reduceC47Blocks(pc_mem_ptr: ?*anyopaque, old_size_in_blocks: usize, new_size_in_blocks: usize) void;

fn validateNameGlyphLength(name: [*:0]const u8) usize {
    var glyph_length: usize = 0;
    var offset: usize = 0;

    while (name[offset] != 0) {
        offset += if ((name[offset] & 0x80) != 0) @as(usize, 2) else @as(usize, 1);
        glyph_length += 1;
    }

    return glyph_length;
}

fn validateNameNextGlyphOffset(name: [*:0]const u8, offset: usize) usize {
    return offset + if ((name[offset] & 0x80) != 0) @as(usize, 2) else @as(usize, 1);
}

fn validateNameGlyphCode(name: [*:0]const u8, offset: usize) u16 {
    const first = name[offset];

    if ((first & 0x80) != 0) {
        return (@as(u16, first & 0x7f) << 8) | @as(u16, name[offset + 1]);
    }

    return @as(u16, first);
}

fn initializeSimEqMatrix(variable_name: [*:0]const u8) void {
    allocateNamedVariable(variable_name, runtime.dtReal34Matrix, runtime.real34SizeInBlocks() + runtime.matrixHeaderSizeInBlocks());
    if (stack_runtime.lastErrorCode != stack_runtime.ERROR_NONE) {
        return;
    }

    const register = runtime.FIRST_NAMED_VARIABLE + @as(runtime.calcRegister_t, @intCast(runtime.numberOfNamedVariables - 1));
    const data_ptr = descriptor_owned.getRegisterDataPointer(register);

    runtime.initializeMatrixHeader1x1(data_ptr);
    memory_owned.zeroReal34(firstMatrixElementPointer(data_ptr));
}

fn initSimEqMatABX() void {
    initializeSimEqMatrix("Mat_A");
    if (stack_runtime.lastErrorCode != stack_runtime.ERROR_NONE) {
        return;
    }

    initializeSimEqMatrix("Mat_B");
    if (stack_runtime.lastErrorCode != stack_runtime.ERROR_NONE) {
        return;
    }

    initializeSimEqMatrix("Mat_X");
}

fn refreshSimEqMatrix(variable_name: [*:0]const u8) void {
    const register = findOrAllocateNamedVariable(variable_name);
    if (register == runtime.INVALID_VARIABLE) {
        return;
    }

    reallocate_owned.reallocateRegister(register, runtime.dtReal34Matrix, runtime.real34SizeInBlocks(), runtime.amNone);
    if (stack_runtime.lastErrorCode == stack_runtime.ERROR_RAM_FULL) {
        return;
    }

    const data_ptr = descriptor_owned.getRegisterDataPointer(register);
    runtime.initializeMatrixHeader1x1(data_ptr);
    memory_owned.zeroReal34(firstMatrixElementPointer(data_ptr));
}

fn firstMatrixElementPointer(data_ptr: ?*anyopaque) ?*anyopaque {
    const ptr = data_ptr orelse return null;
    const bytes: [*]align(1) u8 = @ptrCast(ptr);
    const payload_offset: usize = @intCast(memory_owned.bytesFromBlocks(runtime.matrixHeaderSizeInBlocks()));
    return @ptrCast(bytes + payload_offset);
}

fn refreshSimEqMatABX() void {
    refreshSimEqMatrix("Mat_A");
    if (stack_runtime.lastErrorCode == stack_runtime.ERROR_RAM_FULL) {
        return;
    }

    refreshSimEqMatrix("Mat_B");
    if (stack_runtime.lastErrorCode == stack_runtime.ERROR_RAM_FULL) {
        return;
    }

    refreshSimEqMatrix("Mat_X");
}

fn compareMenuNames(left: [*c]const u8, right: [*c]const u8) i32 {
    return compareString(left, right, compare_name_mode);
}

fn namedVariableHeaderBlocks(count: u16) usize {
    const bytes = @as(usize, count) * @sizeOf(named_variable_header_t);
    return (bytes + 3) / 4;
}

fn allocateFirstNamedVariableHeader() bool {
    if (use_fake_register_metadata_harness_surface) {
        if (!isMemoryBlockAvailable(namedVariableHeaderBlocks(1), 1, 0.0)) {
            return false;
        }

        runtime.numberOfNamedVariables = 1;
        return true;
    }

    const data_ptr = stack_runtime.allocC47Blocks(namedVariableHeaderBlocks(1)) orelse return false;
    allNamedVariables = @ptrCast(@alignCast(data_ptr));
    runtime.numberOfNamedVariables = 1;
    return true;
}

fn appendNamedVariableHeader(index: *u16) bool {
    if (use_fake_register_metadata_harness_surface) {
        if (!isMemoryBlockAvailable(namedVariableHeaderBlocks(runtime.numberOfNamedVariables + 1), 1, 0.0)) {
            return false;
        }
        if (runtime.numberOfNamedVariables >= max_fake_named_variables) {
            return false;
        }

        index.* = runtime.numberOfNamedVariables;
        runtime.numberOfNamedVariables += 1;
        return true;
    }

    const original_headers = allNamedVariables;
    index.* = runtime.numberOfNamedVariables;

    const grown_ptr = reallocC47Blocks(
        if (original_headers) |headers| @ptrCast(headers) else null,
        namedVariableHeaderBlocks(runtime.numberOfNamedVariables),
        namedVariableHeaderBlocks(runtime.numberOfNamedVariables + 1),
    ) orelse return false;

    allNamedVariables = @ptrCast(@alignCast(grown_ptr));
    runtime.numberOfNamedVariables += 1;
    return true;
}

fn storeNamedVariableName(index: u16, variable_name: [*c]const u8) void {
    if (use_fake_register_metadata_harness_surface and index >= max_fake_named_variables) {
        return;
    }

    const headers = allNamedVariables orelse return;
    const text: [*:0]const u8 = @ptrCast(variable_name);
    const slot = &headers[index];
    const len = @min(std.mem.len(text), slot.variableName.len - 1);

    slot.variableName[0] = @intCast(len);
    @memset(slot.variableName[1..], 0);
    if (len != 0) {
        _ = stack_runtime.xcopy(&slot.variableName[1], variable_name, @intCast(len));
    }
}

fn clearNamedVariableSlot(index: u16) void {
    if (index >= runtime.numberOfNamedVariables or (use_fake_register_metadata_harness_surface and index >= max_fake_named_variables)) {
        return;
    }

    const headers = allNamedVariables orelse return;
    headers[index].header.descriptor = 0;
    @memset(headers[index].variableName[0..], 0);
}

fn shrinkNamedVariableHeaderStorage() void {
    if (use_fake_register_metadata_harness_surface or runtime.numberOfNamedVariables == 0) {
        return;
    }

    const headers = allNamedVariables orelse return;
    reduceC47Blocks(
        @ptrCast(headers),
        namedVariableHeaderBlocks(runtime.numberOfNamedVariables),
        namedVariableHeaderBlocks(runtime.numberOfNamedVariables - 1),
    );
}

fn findReservedVariableName(variable_name: [*c]const u8, glyph_length: u8) runtime.calcRegister_t {
    _ = glyph_length; // C _findReservedVariable keys on BYTE length (stringByteLength), not glyph count
    const reserved_count: runtime.calcRegister_t = runtime.LAST_RESERVED_VARIABLE - runtime.FIRST_RESERVED_VARIABLE + 1;
    var byte_len: u8 = 0;
    while (variable_name[byte_len] != 0) : (byte_len += 1) {}

    var reg: runtime.calcRegister_t = 0;
    while (reg < reserved_count) : (reg += 1) {
        // reservedVariableName[0] holds the byte length (a multibyte glyph counts >1),
        // so a name like sigma-Lim (4 glyphs / 5 bytes) must match on 5, not 4.
        if (allReservedVariables[@intCast(reg)].reservedVariableName[0] != byte_len) {
            continue;
        }

        const reserved_name: [*:0]const u8 = @ptrCast(&allReservedVariables[@intCast(reg)].reservedVariableName[1]);
        if (compareMenuNames(variable_name, @ptrCast(reserved_name)) == 0) {
            return runtime.FIRST_RESERVED_VARIABLE + reg;
        }
    }

    return runtime.INVALID_VARIABLE;
}

fn namedVariableNameEquals(index: u16, variable_name: [*:0]const u8) bool {
    return compareMenuNames(runtime.namedVariableName(index), @ptrCast(variable_name)) == 0;
}

fn preserveNamedVariableDuringClear(index: u16) bool {
    return namedVariableNameEquals(index, "STATS") or
        namedVariableNameEquals(index, "HISTO") or
        namedVariableNameEquals(index, "Mat_A") or
        namedVariableNameEquals(index, "Mat_B") or
        namedVariableNameEquals(index, "Mat_X");
}

pub fn validateName(name: [*c]const u8) bool {
    if (name == null) {
        return false;
    }

    const text: [*:0]const u8 = @ptrCast(name);
    const glyph_length = validateNameGlyphLength(text);

    if (glyph_length > validate_name_max_glyphs or glyph_length == 0) {
        return false;
    }

    const first = validateNameGlyphCode(text, 0);

    if (first < glyph_A) {
        return false;
    }
    if (first > glyph_Z and first < glyph_a) {
        return false;
    }
    if (first > glyph_z and first < glyph_A_grave) {
        return false;
    }
    if (first == glyph_cross or first == glyph_divide) {
        return false;
    }
    if (first > glyph_z_caron and first < glyph_iota_dialytika_tonos) {
        return false;
    }
    if (first > glyph_sampi and first < glyph_sub_alpha) {
        return false;
    }
    if (first > glyph_sub_mu and first < glyph_sup_a) {
        return false;
    }
    if (first > glyph_sub_Z) {
        return false;
    }

    var offset = validateNameNextGlyphOffset(text, 0);
    while (text[offset] != 0) : (offset = validateNameNextGlyphOffset(text, offset)) {
        switch (text[offset]) {
            '+', '-', ':', '/', '^', '(', ')', '=', ';', '|', '!', ' ' => return false,
            else => {},
        }

        if (validateNameGlyphCode(text, offset) == glyph_cross) {
            return false;
        }
    }

    return true;
}

pub fn isUniqueMenuName(name: [*c]const u8) bool {
    if (name == null) {
        return false;
    }

    var index: u32 = 0;
    while (index < runtime.builtinMenuItemCount()) : (index += 1) {
        if (!runtime.builtinMenuItemIsMenu(index)) {
            continue;
        }

        if (compareMenuNames(name, runtime.builtinMenuItemName(index)) == 0) {
            return false;
        }
    }

    index = 0;
    while (index < runtime.userMenuCount()) : (index += 1) {
        if (compareMenuNames(name, runtime.userMenuName(index)) == 0) {
            return false;
        }
    }

    return true;
}

pub fn allocateNamedVariable(variable_name: [*c]const u8, data_type: u32, full_data_size_in_blocks: u16) void {
    if (variable_name == null) {
        return;
    }

    const text: [*:0]const u8 = @ptrCast(variable_name);
    const glyph_length = validateNameGlyphLength(text);

    if (glyph_length < 1 or glyph_length > validate_name_max_glyphs) {
        return;
    }

    if (findReservedVariableName(variable_name, @intCast(glyph_length)) != runtime.INVALID_VARIABLE) {
        runtime.reportInvalidName();
        return;
    }

    if (!validateName(variable_name)) {
        runtime.reportInvalidName();
        return;
    }

    if (runtime.numberOfNamedVariables == 0) {
        if (!allocateFirstNamedVariableHeader()) {
            runtime.reportRamFull();
            return;
        }

        storeNamedVariableName(0, variable_name);
        descriptor_owned.setRegisterDataType(runtime.FIRST_NAMED_VARIABLE, @intCast(data_type), runtime.amNone);
        descriptor_owned.setRegisterDataPointer(runtime.FIRST_NAMED_VARIABLE, stack_runtime.allocC47Blocks(full_data_size_in_blocks));
        return;
    }

    if (runtime.numberOfNamedVariables == (runtime.LAST_NAMED_VARIABLE - runtime.FIRST_NAMED_VARIABLE + 1)) {
        runtime.reportTooManyVariables();
        return;
    }

    var new_index: u16 = 0;
    if (!appendNamedVariableHeader(&new_index)) {
        runtime.reportRamFull();
        return;
    }

    storeNamedVariableName(new_index, variable_name);

    const register = runtime.FIRST_NAMED_VARIABLE + @as(runtime.calcRegister_t, @intCast(new_index));
    descriptor_owned.setRegisterDataType(register, @intCast(data_type), runtime.amNone);
    descriptor_owned.setRegisterDataPointer(register, stack_runtime.allocC47Blocks(full_data_size_in_blocks));
}

pub fn deleteVariable(regist: u16) void {
    const register: runtime.calcRegister_t = @intCast(regist);
    const named_variable_limit = runtime.FIRST_NAMED_VARIABLE + @as(runtime.calcRegister_t, @intCast(runtime.numberOfNamedVariables));

    if (register >= runtime.FIRST_NAMED_VARIABLE and register < named_variable_limit) {
        const index: u16 = @intCast(register - runtime.FIRST_NAMED_VARIABLE);
        runtime.removeNamedVariableRecallAssignment(index);
        memory_owned.freeRegisterData(register);

        var shift_index = index;
        while (shift_index + 1 < runtime.numberOfNamedVariables) : (shift_index += 1) {
            runtime.setNamedDescriptorUnchecked(shift_index, runtime.namedDescriptorUnchecked(shift_index + 1));
            storeNamedVariableName(shift_index, runtime.namedVariableName(shift_index + 1));
        }

        clearNamedVariableSlot(runtime.numberOfNamedVariables - 1);
    shrinkNamedVariableHeaderStorage();
        runtime.numberOfNamedVariables -= 1;
        return;
    }

    if (register >= runtime.FIRST_NAMED_VARIABLE and register < runtime.LAST_NAMED_VARIABLE) {
        runtime.reportUndefSourceVar();
        return;
    }

    runtime.reportCannotDeletePredefItem();
}

pub fn deleteAllVariables(confirmation: u16) void {
    if (confirmation == stack_runtime.NOT_CONFIRMED and stack_runtime.programRunStop != stack_runtime.PGM_RUNNING) {
        runtime.requestDeleteAllVariablesConfirmation();
        return;
    }

    var variable_index = runtime.numberOfNamedVariables;
    while (variable_index > 0) : (variable_index -= 1) {
        deleteVariable(@intCast(runtime.FIRST_NAMED_VARIABLE + @as(runtime.calcRegister_t, @intCast(variable_index - 1))));
    }

    initSimEqMatABX();
    runtime.temporaryInformation = if (stack_runtime.programRunStop != stack_runtime.PGM_RUNNING)
        runtime.TI_DEL_ALL_VARIABLES
    else
        runtime.TI_NO_INFO;
}

pub fn clearAllVariables(confirmation: u16) void {
    if (confirmation == stack_runtime.NOT_CONFIRMED and stack_runtime.programRunStop != stack_runtime.PGM_RUNNING) {
        runtime.requestClearAllVariablesConfirmation();
        return;
    }

    var variable_index = runtime.numberOfNamedVariables;
    while (variable_index > 0) {
        const index = variable_index - 1;
        variable_index -= 1;

        if (preserveNamedVariableDuringClear(index)) {
            continue;
        }

        stack_runtime.clearRegister(runtime.FIRST_NAMED_VARIABLE + @as(runtime.calcRegister_t, @intCast(index)));
    }

    runtime.clearSigma();
    refreshSimEqMatABX();
    runtime.temporaryInformation = if (stack_runtime.programRunStop != stack_runtime.PGM_RUNNING)
        runtime.TI_CLEAR_ALL_VARIABLES
    else
        runtime.TI_NO_INFO;
}

pub fn findNamedVariable(variable_name: [*c]const u8) runtime.calcRegister_t {
    const text: [*:0]const u8 = @ptrCast(variable_name);
    const glyph_length = validateNameGlyphLength(text);

    if (glyph_length < 1 or glyph_length > validate_name_max_glyphs) {
        return runtime.INVALID_VARIABLE;
    }

    const reserved = findReservedVariableName(variable_name, @intCast(glyph_length));
    if (reserved != runtime.INVALID_VARIABLE) {
        return reserved;
    }

    var index: u16 = 0;
    while (index < runtime.numberOfNamedVariables) : (index += 1) {
        if (compareMenuNames(runtime.namedVariableName(index), variable_name) == 0) {
            return runtime.FIRST_NAMED_VARIABLE + @as(runtime.calcRegister_t, @intCast(index));
        }
    }

    return runtime.INVALID_VARIABLE;
}

pub fn findOrAllocateNamedVariable(variable_name: [*c]const u8) runtime.calcRegister_t {
    const text: [*:0]const u8 = @ptrCast(variable_name);
    const glyph_length = validateNameGlyphLength(text);

    if (glyph_length < 1 or glyph_length > validate_name_max_glyphs) {
        return runtime.INVALID_VARIABLE;
    }

    const register = findNamedVariable(variable_name);
    if (register != runtime.INVALID_VARIABLE) {
        return register;
    }

    if (runtime.numberOfNamedVariables > (runtime.LAST_NAMED_VARIABLE - runtime.FIRST_NAMED_VARIABLE)) {
        return runtime.INVALID_VARIABLE;
    }

    allocateNamedVariable(variable_name, runtime.dtReal34, runtime.real34SizeInBlocks());
    if (stack_runtime.lastErrorCode != stack_runtime.ERROR_NONE) {
        return runtime.INVALID_VARIABLE;
    }

    const new_register = runtime.FIRST_NAMED_VARIABLE + @as(runtime.calcRegister_t, @intCast(runtime.numberOfNamedVariables - 1));
    memory_owned.zeroReal34(descriptor_owned.getRegisterDataPointer(new_register));
    return new_register;
}

pub fn isFunctionAllowingNewVariable(op: u16) bool {
    return switch (op) {
        runtime.ITM_INPUT,
        runtime.ITM_STO,
        runtime.ITM_STOADD,
        runtime.ITM_STOSUB,
        runtime.ITM_STOMULT,
        runtime.ITM_STODIV,
        runtime.ITM_KEYQ,
        runtime.ITM_M_DIM,
        runtime.ITM_MVAR,
        runtime.ITM_SOLVE,
        runtime.ITM_STOCFG,
        runtime.ITM_STOMAX,
        runtime.ITM_STOMIN,
        runtime.ITM_XtoALPHA,
        runtime.ITM_Xex,
        runtime.ITM_Yex,
        runtime.ITM_Zex,
        runtime.ITM_Tex,
        runtime.ITM_INTEGRAL,
        => true,
        else => false,
    };
}