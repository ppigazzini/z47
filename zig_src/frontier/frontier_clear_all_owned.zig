const CONFIRMED: u16 = 9877;
const NOT_CONFIRMED: u16 = 9878;
const NOPARAM: u16 = 9876;

const USER_KRESET: u16 = 50;

const ITM_RIBBON_C47: u16 = 2509;
const ITM_RIBBON_R47: u16 = 2511;

const FIRST_GLOBAL_REGISTER: u16 = 0;
const LAST_GLOBAL_REGISTER: u16 = 125;

const TI_RESET: u8 = 8;

const PGM_STOPPED: u8 = 0;
const PGM_WAITING: u8 = 2;

const ConfirmedFunction = *const fn (u16) callconv(.c) void;

fn requestConfirmation() void {
    setConfirmationMode(&fnClAll);
}

fn clearPrograms() void {
    fnClPAll(CONFIRMED);
}

fn clearSigma() void {
    fnClSigma(CONFIRMED);
    z47_frontier_release_saved_statistical_sums();
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
    fnExitAllMenus(NOPARAM);
    fnDeleteUserMenus(CONFIRMED);
}

fn resetRibbons() void {
    const ribbon = if (z47_frontier_is_r47_fam()) ITM_RIBBON_R47 else ITM_RIBBON_C47;
    fnRESET_MyM(ribbon);
    fnRESET_Mya();
}

fn rebuildCoreMenus() void {
    createHOME();
    createPFN();
}

fn resetKeysAndVariables() void {
    fnKeysManagement(USER_KRESET);
    initUserKeyArgument();
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

extern fn fnClAll(confirmation: u16) void;
extern fn setConfirmationMode(func: ConfirmedFunction) void;
extern fn fnClPAll(confirmation: u16) void;
extern fn fnClSigma(unused_but_mandatory_parameter: u16) void;
extern fn allocateLocalRegisters(number_of_registers_to_allocate: u16) void;
extern fn clearRegister(regist: i16) void;
extern fn fnExitAllMenus(unused_but_mandatory_parameter: u16) void;
extern fn fnDeleteUserMenus(confirmation: u16) void;
extern fn fnRESET_MyM(param: u16) void;
extern fn fnRESET_Mya() void;
extern fn createHOME() void;
extern fn createPFN() void;
extern fn fnKeysManagement(choice: u16) void;
extern fn initUserKeyArgument() void;
extern fn fnDeleteAllVariables(confirmation: u16) void;
extern fn fnClFAll(confirmation: u16) void;
extern fn z47_frontier_release_saved_statistical_sums() void;
extern fn z47_frontier_is_r47_fam() bool;