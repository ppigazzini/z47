// SPDX-License-Identifier: GPL-3.0-only
//
// displayCalcErrorMessage: the calculator's error-report entry point, called
// pervasively across the engine (~133 owners) to raise a calculation error. Its
// name is a misnomer inherited from the C source -- the normal path does no
// display at all, it just records the error status the shell later renders:
// lastErrorCode, errorMessageRegisterLine and screenUpdatingMode, all base kernel
// state. Only the defensive branch, taken for a malformed error code or register
// line (a programming error, never a real calculation error), needs the
// interactive bug screen, and that is handed to the shell through the host
// boundary (abi.host.reportBugError) rather than linked directly.
//
// Moving the entry point here severs the engine's dependency on the shell error
// owner: the engine's calls become intra-core, and the shell's own calls become
// a downstream shell->core dependency. The bug-screen rendering and the message
// tables stay in shell/error.zig.

const abi = @import("abi");

const calcRegister_t = i16;
const NUMBER_OF_ERROR_CODES: u8 = 129; // defines.h
const SCRUPD_AUTO: u8 = 0x00;
const REGISTER_X: calcRegister_t = 100;
const REGISTER_T: calcRegister_t = 103;

extern var lastErrorCode: u8;
extern var errorMessageRegisterLine: calcRegister_t;
extern var screenUpdatingMode: u8;

pub export fn displayCalcErrorMessage(errorCode: u8, errMessageRegisterLine: calcRegister_t, disUsedCanBeRemoved: calcRegister_t) callconv(.c) void {
    // disUsedCanBeRemoved (was errRegisterLine): dead since cb79577; the param is
    // kept because ~924 call sites still pass it.
    _ = disUsedCanBeRemoved;
    if (errorCode >= NUMBER_OF_ERROR_CODES or errorCode == 0 or
        errMessageRegisterLine > REGISTER_T or errMessageRegisterLine < REGISTER_X)
    {
        // Malformed report: let the shell format the diagnostic and paint the
        // bug screen. A no-op when the core runs headless.
        abi.host.reportBugError(errorCode, errMessageRegisterLine);
    } else {
        lastErrorCode = errorCode;
        errorMessageRegisterLine = errMessageRegisterLine;
        screenUpdatingMode = SCRUPD_AUTO;
    }
}
