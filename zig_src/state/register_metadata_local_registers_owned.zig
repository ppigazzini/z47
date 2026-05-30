const build_options = @import("register_metadata_build_options");
const clear_owned = @import("stack_clear_owned.zig");
const memory_owned = @import("register_memory_owned.zig");
const runtime = @import("register_metadata_runtime.zig");
const stack_runtime = @import("stack_runtime.zig");

const use_fake_register_metadata_harness_surface =
    @hasDecl(build_options, "use_fake_register_metadata_harness_surface") and
    build_options.use_fake_register_metadata_harness_surface;

const localFlags_t = u32;
const NUMBER_OF_LOCAL_FLAGS: u8 = 32;

const register_header_t = extern union {
    descriptor: runtime.register_descriptor_t,
};

const subroutine_levels_t = extern struct {
    numberOfSubroutineLevels: u16,
    ptrToSubroutineLevel0Header: u16,
};

const subroutine_level_header_t = extern struct {
    returnProgramNumber: i16,
    returnLocalStep: u16,
    numberOfLocalFlags: u8,
    numberOfLocalRegisters: u8,
    subroutineLevel: u16,
    ptrToNextLevel: u16,
    ptrToPreviousLevel: u16,
};

extern var allSubroutineLevels: subroutine_levels_t;
extern var currentSubroutineLevelData: ?*subroutine_level_header_t;
extern var currentLocalFlags: ?*localFlags_t;
extern var currentLocalRegisters: ?[*]register_header_t;

extern fn reallocC47Blocks(pc_mem_ptr: ?*anyopaque, old_size_in_blocks: usize, new_size_in_blocks: usize) ?*anyopaque;
extern fn reduceC47Blocks(pc_mem_ptr: ?*anyopaque, old_size_in_blocks: usize, new_size_in_blocks: usize) void;

fn toBlocks(bytes: usize) u16 {
    return @intCast((bytes + 3) / 4);
}

fn localFlagsAfterHeader(level_data: *subroutine_level_header_t) *localFlags_t {
    const bytes: [*]align(1) u8 = @ptrCast(level_data);
    return @ptrCast(bytes + @sizeOf(subroutine_level_header_t));
}

fn localRegistersAfterFlags(flags: *localFlags_t) [*]register_header_t {
    const bytes: [*]align(1) u8 = @ptrCast(flags);
    return @ptrCast(bytes + @sizeOf(localFlags_t));
}

fn levelBlocks(register_count: u16) usize {
    return toBlocks(@sizeOf(subroutine_level_header_t) + @sizeOf(localFlags_t) + @as(usize, register_count) * @sizeOf(register_header_t));
}

fn headerOnlyBlocks() usize {
    return toBlocks(@sizeOf(subroutine_level_header_t));
}

fn reportLocalRegisterRangeError(number_of_registers_to_allocate: u16) void {
    _ = number_of_registers_to_allocate;
    stack_runtime.displayCalcErrorMessage(stack_runtime.ERROR_OUT_OF_RANGE, stack_runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
}

fn refreshLocalStorage(level_data: *subroutine_level_header_t, register_count: u16) void {
    currentSubroutineLevelData = level_data;
    currentLocalFlags = localFlagsAfterHeader(level_data);
    level_data.numberOfLocalFlags = NUMBER_OF_LOCAL_FLAGS;
    level_data.numberOfLocalRegisters = @intCast(register_count);
    currentLocalRegisters = if (register_count == 0)
        null
    else
        localRegistersAfterFlags(currentLocalFlags.?);
}

fn clearLocalStorage() void {
    currentLocalFlags = null;
    currentLocalRegisters = null;
}

fn initializeLocalRegister(reg: runtime.calcRegister_t) bool {
    stack_runtime.lastErrorCode = stack_runtime.ERROR_NONE;
    clear_owned.clearRegister(reg);
    return stack_runtime.lastErrorCode == stack_runtime.ERROR_RAM_FULL;
}

fn freeLocalRegisterRange(start_index: u16, end_index: u16) void {
    var index = start_index;
    while (index < end_index) : (index += 1) {
        memory_owned.freeRegisterData(runtime.FIRST_LOCAL_REGISTER + @as(runtime.calcRegister_t, @intCast(index)));
    }
}

fn updateSubroutineLinks() void {
    const current_level = currentSubroutineLevelData orelse return;

    if (current_level.subroutineLevel == 0) {
        allSubroutineLevels.ptrToSubroutineLevel0Header = runtime.toC47MemPtr(current_level);
        return;
    }

    const previous_ptr = runtime.toPcMemPtr(current_level.ptrToPreviousLevel) orelse return;
    const previous_level: *subroutine_level_header_t = @ptrCast(@alignCast(previous_ptr));
    previous_level.ptrToNextLevel = runtime.toC47MemPtr(current_level);
}

fn allocateFirstLocalRegisters(number_of_registers_to_allocate: u16) void {
    const old_level = currentSubroutineLevelData;
    const grown_ptr = reallocC47Blocks(
        if (old_level) |level| @ptrCast(level) else null,
        headerOnlyBlocks(),
        levelBlocks(number_of_registers_to_allocate),
    ) orelse {
        currentSubroutineLevelData = old_level;
        runtime.reportRamFull();
        return;
    };

    const level: *subroutine_level_header_t = @ptrCast(@alignCast(grown_ptr));
    refreshLocalStorage(level, number_of_registers_to_allocate);
    currentLocalFlags.?[0] = 0;

    var index: u16 = 0;
    while (index < number_of_registers_to_allocate) : (index += 1) {
        if (initializeLocalRegister(runtime.FIRST_LOCAL_REGISTER + @as(runtime.calcRegister_t, @intCast(index)))) {
            freeLocalRegisterRange(0, index);
            reduceC47Blocks(grown_ptr, levelBlocks(number_of_registers_to_allocate), headerOnlyBlocks());
            currentSubroutineLevelData = level;
            clearLocalStorage();
            level.numberOfLocalFlags = 0;
            level.numberOfLocalRegisters = 0;
            runtime.reportRamFull();
            return;
        }
    }

    updateSubroutineLinks();
}

fn growLocalRegisters(number_of_registers_to_allocate: u16, old_number_of_local_registers: u16) void {
    const old_level = currentSubroutineLevelData;
    const grown_ptr = reallocC47Blocks(
        if (old_level) |level| @ptrCast(level) else null,
        levelBlocks(@intCast(old_number_of_local_registers)),
        levelBlocks(number_of_registers_to_allocate),
    ) orelse {
        currentSubroutineLevelData = old_level;
        runtime.reportRamFull();
        return;
    };

    const level: *subroutine_level_header_t = @ptrCast(@alignCast(grown_ptr));
    refreshLocalStorage(level, number_of_registers_to_allocate);

    var index = old_number_of_local_registers;
    while (index < number_of_registers_to_allocate) : (index += 1) {
        if (initializeLocalRegister(runtime.FIRST_LOCAL_REGISTER + @as(runtime.calcRegister_t, @intCast(index)))) {
            freeLocalRegisterRange(old_number_of_local_registers, index);
            reduceC47Blocks(grown_ptr, levelBlocks(number_of_registers_to_allocate), levelBlocks(@intCast(old_number_of_local_registers)));
            currentSubroutineLevelData = level;
            refreshLocalStorage(level, @intCast(old_number_of_local_registers));
            runtime.reportRamFull();
            return;
        }
    }

    updateSubroutineLinks();
}

fn shrinkLocalRegisters(number_of_registers_to_allocate: u16, old_number_of_local_registers: u16) void {
    const level = currentSubroutineLevelData orelse return;

    freeLocalRegisterRange(number_of_registers_to_allocate, old_number_of_local_registers);
    reduceC47Blocks(
        @ptrCast(level),
        levelBlocks(@intCast(old_number_of_local_registers)),
        levelBlocks(number_of_registers_to_allocate),
    );
    refreshLocalStorage(level, number_of_registers_to_allocate);
    updateSubroutineLinks();
}

pub fn allocateLocalRegisters(number_of_registers_to_allocate: u16) void {
    if (use_fake_register_metadata_harness_surface) {
        runtime.allocateLocalRegistersRetained(number_of_registers_to_allocate);
        return;
    }

    if (number_of_registers_to_allocate > 99) {
        reportLocalRegisterRangeError(number_of_registers_to_allocate);
        return;
    }

    if (currentLocalFlags == null) {
        allocateFirstLocalRegisters(number_of_registers_to_allocate);
        return;
    }

    const current_level = currentSubroutineLevelData orelse return;
    const old_number_of_local_registers: u16 = current_level.numberOfLocalRegisters;
    if (number_of_registers_to_allocate == old_number_of_local_registers) {
        return;
    }

    if (number_of_registers_to_allocate > old_number_of_local_registers) {
        growLocalRegisters(number_of_registers_to_allocate, old_number_of_local_registers);
        return;
    }

    shrinkLocalRegisters(number_of_registers_to_allocate, old_number_of_local_registers);
}