const frontier = @import("frontier.zig"); // M-callconv: Zig-to-Zig
const frontier_addons = @import("frontier_addons.zig"); // M-callconv: Zig-to-Zig
const frontier_assign = @import("frontier_assign.zig"); // M-callconv: Zig-to-Zig
const frontier_config = @import("frontier_config.zig"); // M-callconv: Zig-to-Zig
const frontier_softmenus = @import("frontier_softmenus.zig"); // M-callconv: Zig-to-Zig
const frontier_stats = @import("frontier_stats.zig"); // M-callconv: Zig-to-Zig
const CONFIRMED: u16 = 9877;
const NOT_CONFIRMED: u16 = 9878;
const NOPARAM: u16 = 9876;

const USER_KRESET: u16 = 50;

const ITM_RIBBON_C47: u16 = 2509;
const ITM_RIBBON_R47: u16 = 2511;

const FIRST_GLOBAL_REGISTER: u16 = 0;
const LAST_GLOBAL_REGISTER: u16 = 136; // = TEMP_REGISTER_2_SAVED_STATS (was 125 = LAST_SPARE_REGISTER)

const TI_RESET: u8 = 8;

const PGM_STOPPED: u8 = 0;
const PGM_WAITING: u8 = 2;

const ConfirmedFunction = *const fn (u16) callconv(.c) void;

fn requestConfirmation() void {
    frontier_config.setConfirmationMode(&frontier.fnClAll);
}

fn clearPrograms() void {
    frontier.fnClPAll(CONFIRMED);
}

fn clearSigma() void {
    frontier_stats.fnClSigma(CONFIRMED);
    frontier_config.z47_frontier_release_saved_statistical_sums();
}

fn clearRegisters() void {
    allocateLocalRegisters(0);

    var regist: u16 = FIRST_GLOBAL_REGISTER;
    while (regist <= LAST_GLOBAL_REGISTER) : (regist += 1) {
        clearRegister(@as(i16, @intCast(regist)));
    }
}

fn clearUndoState() void {
    thereIsSomethingToUndo = false;
}

fn resetMenus() void {
    frontier_softmenus.fnExitAllMenus(NOPARAM);
    frontier_assign.fnDeleteUserMenus(CONFIRMED);
}

fn resetRibbons() void {
    const ribbon = if (frontier_config.z47_frontier_is_r47_fam()) ITM_RIBBON_R47 else ITM_RIBBON_C47;
    frontier_addons.fnRESET_MyM(ribbon);
    frontier_addons.fnRESET_Mya();
}

fn rebuildCoreMenus() void {
    _ = frontier_softmenus.createHOME();
    _ = frontier_softmenus.createPFN();
}

fn resetKeysAndVariables() void {
    frontier.fnKeysManagement(USER_KRESET);
    frontier_assign.initUserKeyArgument();
    fnDeleteAllVariables(CONFIRMED);
    fnClFAll(CONFIRMED);
}

fn finalizeInfo() void {
    temporaryInformation = TI_RESET;
    if (programRunStop == PGM_WAITING) {
        programRunStop = PGM_STOPPED;
    }
}

pub fn run(confirmation: u16) void {
    if (confirmation == NOT_CONFIRMED) {
        requestConfirmation();
        return;
    }

    clearPrograms();
    clearSigma();
    clearRegisters();
    clearUndoState();
    resetMenus();
    resetRibbons();
    rebuildCoreMenus();
    resetKeysAndVariables();
    finalizeInfo();
}

extern var temporaryInformation: u8;
extern var programRunStop: u8;
extern var thereIsSomethingToUndo: bool;





extern fn allocateLocalRegisters(number_of_registers_to_allocate: u16) void;
extern fn clearRegister(regist: i16) void;








extern fn fnDeleteAllVariables(confirmation: u16) void;
extern fn fnClFAll(confirmation: u16) void;

