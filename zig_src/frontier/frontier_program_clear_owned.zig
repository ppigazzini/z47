const NOT_CONFIRMED: u16 = 9878;

const ITM_END: u16 = 1458;

const TI_NO_INFO: u8 = 0;
const TI_DEL_ALL_PRGMS: u8 = 99;

const SCRUPD_AUTO: u8 = 0x00;

const PGM_STOPPED: u8 = 0;
const PGM_RUNNING: u8 = 1;

const ConfirmedFunction = *const fn (u16) callconv(.c) void;

fn requestConfirmation() void {
    setConfirmationMode(&fnClPAll);
}

fn seedProgramEndMarker() void {
    beginOfProgramMemory[0] = @as(u8, @intCast((ITM_END >> 8) | 0x80));
    beginOfProgramMemory[1] = @as(u8, @intCast(ITM_END & 0xff));
    beginOfProgramMemory[2] = 255;
    beginOfProgramMemory[3] = 255;
}

fn initializeProgramPointers() void {
    firstFreeProgramByte = beginOfProgramMemory + 2;
    freeProgramBytes = 0;
}

fn resetProgramState() void {
    temporaryInformation = TI_NO_INFO;
    programRunStop = PGM_STOPPED;
}

fn restoreActiveProgramPointers() void {
    currentStep = beginOfProgramMemory;
    firstDisplayedStep = beginOfProgramMemory;
    firstDisplayedLocalStepNumber = 0;
    currentLocalStepNumber = 1;
    beginOfCurrentProgram = beginOfProgramMemory;
    endOfCurrentProgram = firstFreeProgramByte;
}

fn setTemporaryInformation() void {
    temporaryInformation = if (programRunStop != PGM_RUNNING) TI_DEL_ALL_PRGMS else TI_NO_INFO;
}

fn setScreenUpdatingAuto() void {
    screenUpdatingMode = SCRUPD_AUTO;
}

pub fn run(confirmation: u16) void {
    if (confirmation == NOT_CONFIRMED) {
        requestConfirmation();
        return;
    }

    removeUserItemAssignments(3, "");

    const was_in_ram = z47_frontier_program_current_program_in_ram();
    resizeProgramMemory(1);
    seedProgramEndMarker();
    initializeProgramPointers();
    resetProgramState();

    if (was_in_ram) {
        restoreActiveProgramPointers();
    }

    scanLabelsAndPrograms();
    setTemporaryInformation();
    setScreenUpdatingAuto();
}

extern var temporaryInformation: u8;
extern var programRunStop: u8;
extern var screenUpdatingMode: u8;
extern var beginOfProgramMemory: [*]u8;
extern var firstFreeProgramByte: [*]u8;
extern var freeProgramBytes: u16;
extern var currentStep: [*]u8;
extern var firstDisplayedStep: [*]u8;
extern var firstDisplayedLocalStepNumber: u16;
extern var currentLocalStepNumber: u16;
extern var beginOfCurrentProgram: [*]u8;
extern var endOfCurrentProgram: [*]u8;

extern fn fnClPAll(confirmation: u16) void;
extern fn setConfirmationMode(func: ConfirmedFunction) void;
extern fn resizeProgramMemory(new_size_in_blocks: u16) void;
extern fn scanLabelsAndPrograms() void;
extern fn removeUserItemAssignments(user_item: i16, user_item_name: [*:0]const u8) void;
extern fn z47_frontier_program_current_program_in_ram() bool;