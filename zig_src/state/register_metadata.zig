const builtin = @import("builtin");
const descriptor_owned = @import("register_metadata_descriptor_owned.zig");
const payload_owned = @import("register_metadata_payload_owned.zig");
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

pub export fn setRegisterMaxDataLengthInBlocks(reg: runtime.calcRegister_t, max_data_len: u16) void {
    payload_owned.setRegisterMaxDataLengthInBlocks(reg, max_data_len);
}

pub export fn getRegisterMaxDataLengthInBlocks(reg: runtime.calcRegister_t) u16 {
    return payload_owned.getRegisterMaxDataLengthInBlocks(reg);
}

pub export fn getRegisterFullSizeInBlocks(reg: runtime.calcRegister_t) u16 {
    return payload_owned.getRegisterFullSizeInBlocks(reg);
}

pub export fn copySourceRegisterToDestRegister(source_register: runtime.calcRegister_t, dest_register: runtime.calcRegister_t) void {
    reallocate_owned.copySourceRegisterToDestRegister(source_register, dest_register);
}

pub export fn reallocateRegister(reg: runtime.calcRegister_t, data_type: u32, data_size_without_data_len_blocks: u16, tag: u32) void {
    reallocate_owned.reallocateRegister(reg, data_type, data_size_without_data_len_blocks, tag);
}

pub export fn allocateLocalRegisters(number_of_registers_to_allocate: u16) void {
    runtime.allocateLocalRegistersRetained(number_of_registers_to_allocate);
}

pub export fn validateName(name: [*c]const u8) bool {
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

pub export fn isUniqueMenuName(name: [*c]const u8) bool {
    if (name == null) {
        return false;
    }

    var index: u32 = 0;
    while (index < runtime.builtinMenuItemCount()) : (index += 1) {
        if (!runtime.builtinMenuItemIsMenu(index)) {
            continue;
        }

        if (runtime.compareMenuNames(name, runtime.builtinMenuItemName(index)) == 0) {
            return false;
        }
    }

    index = 0;
    while (index < runtime.userMenuCount()) : (index += 1) {
        if (runtime.compareMenuNames(name, runtime.userMenuName(index)) == 0) {
            return false;
        }
    }

    return true;
}

pub export fn allocateNamedVariable(variable_name: [*c]const u8, data_type: u32, full_data_size_in_blocks: u16) void {
    if (variable_name == null) {
        return;
    }

    const text: [*:0]const u8 = @ptrCast(variable_name);
    const glyph_length = validateNameGlyphLength(text);

    if (glyph_length < 1 or glyph_length > validate_name_max_glyphs) {
        return;
    }

    if (runtime.findReservedVariableName(variable_name, @intCast(glyph_length)) != runtime.INVALID_VARIABLE) {
        runtime.reportInvalidName();
        return;
    }

    if (!validateName(variable_name)) {
        runtime.reportInvalidName();
        return;
    }

    if (runtime.numberOfNamedVariables == 0) {
        if (!runtime.allocateFirstNamedVariableHeader()) {
            runtime.reportRamFull();
            return;
        }

        runtime.storeNamedVariableName(0, variable_name);
        setRegisterDataType(runtime.FIRST_NAMED_VARIABLE, @intCast(data_type), runtime.amNone);
        setRegisterDataPointer(runtime.FIRST_NAMED_VARIABLE, stack_runtime.allocC47Blocks(full_data_size_in_blocks));
        return;
    }

    if (runtime.numberOfNamedVariables == (runtime.LAST_NAMED_VARIABLE - runtime.FIRST_NAMED_VARIABLE + 1)) {
        runtime.reportTooManyVariables();
        return;
    }

    var new_index: u16 = 0;
    if (!runtime.appendNamedVariableHeader(&new_index)) {
        runtime.reportRamFull();
        return;
    }

    runtime.storeNamedVariableName(new_index, variable_name);

    const register = runtime.FIRST_NAMED_VARIABLE + @as(runtime.calcRegister_t, @intCast(new_index));
    setRegisterDataType(register, @intCast(data_type), runtime.amNone);
    setRegisterDataPointer(register, stack_runtime.allocC47Blocks(full_data_size_in_blocks));
}

pub export fn fnDeleteVariable(regist: u16) void {
    const register: runtime.calcRegister_t = @intCast(regist);
    const named_variable_limit = runtime.FIRST_NAMED_VARIABLE + @as(runtime.calcRegister_t, @intCast(runtime.numberOfNamedVariables));

    if (register >= runtime.FIRST_NAMED_VARIABLE and register < named_variable_limit) {
        const index: u16 = @intCast(register - runtime.FIRST_NAMED_VARIABLE);
        runtime.removeNamedVariableRecallAssignment(index);
        stack_runtime.freeRegisterData(register);

        var shift_index = index;
        while (shift_index + 1 < runtime.numberOfNamedVariables) : (shift_index += 1) {
            runtime.setNamedDescriptorUnchecked(shift_index, runtime.namedDescriptorUnchecked(shift_index + 1));
            runtime.storeNamedVariableName(shift_index, runtime.namedVariableName(shift_index + 1));
        }

        runtime.clearNamedVariableSlot(runtime.numberOfNamedVariables - 1);
        runtime.shrinkNamedVariableHeaderStorage();
        runtime.numberOfNamedVariables -= 1;
        return;
    }

    if (register >= runtime.FIRST_NAMED_VARIABLE and register < runtime.LAST_NAMED_VARIABLE) {
        runtime.reportUndefSourceVar();
        return;
    }

    runtime.reportCannotDeletePredefItem();
}

fn initializeSimEqMatrix(variable_name: [*:0]const u8) void {
    allocateNamedVariable(variable_name, runtime.dtReal34Matrix, runtime.real34SizeInBlocks() + runtime.matrixHeaderSizeInBlocks());
    if (stack_runtime.lastErrorCode != stack_runtime.ERROR_NONE) {
        return;
    }

    const register = runtime.FIRST_NAMED_VARIABLE + @as(runtime.calcRegister_t, @intCast(runtime.numberOfNamedVariables - 1));
    const data_ptr = getRegisterDataPointer(register);

    runtime.initializeMatrixHeader1x1(data_ptr);
    stack_runtime.real34SetZero(firstMatrixElementPointer(data_ptr));
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

    reallocateRegister(register, runtime.dtReal34Matrix, runtime.real34SizeInBlocks(), runtime.amNone);
    if (stack_runtime.lastErrorCode == stack_runtime.ERROR_RAM_FULL) {
        return;
    }

    const data_ptr = getRegisterDataPointer(register);
    runtime.initializeMatrixHeader1x1(data_ptr);
    stack_runtime.real34SetZero(firstMatrixElementPointer(data_ptr));
}

fn firstMatrixElementPointer(data_ptr: ?*anyopaque) ?*anyopaque {
    const ptr = data_ptr orelse return null;
    const bytes: [*]align(1) u8 = @ptrCast(ptr);
    const payload_offset: usize = @intCast(stack_runtime.bytesFromBlocks(runtime.matrixHeaderSizeInBlocks()));
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

fn namedVariableNameEquals(index: u16, variable_name: [*:0]const u8) bool {
    return runtime.compareMenuNames(runtime.namedVariableName(index), variable_name) == 0;
}

fn preserveNamedVariableDuringClear(index: u16) bool {
    return namedVariableNameEquals(index, "STATS") or
        namedVariableNameEquals(index, "HISTO") or
        namedVariableNameEquals(index, "Mat_A") or
        namedVariableNameEquals(index, "Mat_B") or
        namedVariableNameEquals(index, "Mat_X");
}

pub export fn fnDeleteAllVariables(confirmation: u16) void {
    if (confirmation == stack_runtime.NOT_CONFIRMED and stack_runtime.programRunStop != stack_runtime.PGM_RUNNING) {
        runtime.requestDeleteAllVariablesConfirmation();
        return;
    }

    var variable_index = runtime.numberOfNamedVariables;
    while (variable_index > 0) : (variable_index -= 1) {
        fnDeleteVariable(@intCast(runtime.FIRST_NAMED_VARIABLE + @as(runtime.calcRegister_t, @intCast(variable_index - 1))));
    }

    initSimEqMatABX();
    runtime.temporaryInformation = if (stack_runtime.programRunStop != stack_runtime.PGM_RUNNING)
        runtime.TI_DEL_ALL_VARIABLES
    else
        runtime.TI_NO_INFO;
}

pub export fn fnClearAllVariables(confirmation: u16) void {
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

pub export fn findNamedVariable(variable_name: [*c]const u8) runtime.calcRegister_t {
    const text: [*:0]const u8 = @ptrCast(variable_name);
    const glyph_length = validateNameGlyphLength(text);

    if (glyph_length < 1 or glyph_length > 7) {
        return runtime.INVALID_VARIABLE;
    }

    const reserved = runtime.findReservedVariableName(variable_name, @intCast(glyph_length));
    if (reserved != runtime.INVALID_VARIABLE) {
        return reserved;
    }

    var index: u16 = 0;
    while (index < runtime.numberOfNamedVariables) : (index += 1) {
        if (runtime.compareMenuNames(runtime.namedVariableName(index), variable_name) == 0) {
            return runtime.FIRST_NAMED_VARIABLE + @as(runtime.calcRegister_t, @intCast(index));
        }
    }

    return runtime.INVALID_VARIABLE;
}

pub export fn findOrAllocateNamedVariable(variable_name: [*c]const u8) runtime.calcRegister_t {
    const text: [*:0]const u8 = @ptrCast(variable_name);
    const glyph_length = validateNameGlyphLength(text);

    if (glyph_length < 1 or glyph_length > 7) {
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
    stack_runtime.real34SetZero(getRegisterDataPointer(new_register));
    return new_register;
}

pub export fn isFunctionAllowingNewVariable(op: u16) bool {
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

pub export fn getRegisterDataType(reg: runtime.calcRegister_t) u32 {
    return descriptor_owned.getRegisterDataType(reg);
}

pub export fn getRegisterDataPointer(reg: runtime.calcRegister_t) ?*anyopaque {
    return descriptor_owned.getRegisterDataPointer(reg);
}

pub export fn getRegisterTag(reg: runtime.calcRegister_t) u32 {
    return descriptor_owned.getRegisterTag(reg);
}

pub export fn setRegisterDataType(reg: runtime.calcRegister_t, data_type: u16, tag: u32) void {
    descriptor_owned.setRegisterDataType(reg, data_type, tag);
}

pub export fn setRegisterDataPointer(reg: runtime.calcRegister_t, mem_ptr: ?*const anyopaque) void {
    descriptor_owned.setRegisterDataPointer(reg, mem_ptr);
}

pub export fn setRegisterTag(reg: runtime.calcRegister_t, tag: u32) void {
    descriptor_owned.setRegisterTag(reg, tag);
}
