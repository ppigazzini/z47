// SPDX-License-Identifier: GPL-3.0-only
//
// Entry point of the testSuite executables. The upstream runner ships its own
// main() in src/testSuite/testSuite.c, which the build renames to
// z47_testsuite_main so this wrapper can run first.
//
// The wrapper exists to wire the core->shell hooks (abi.host). Upstream links
// the shell functions directly, so its testSuite gets the calculator's real
// behaviour; z47 severed those calls behind installable hooks whose defaults are
// neutral, and the hooks are installed by program_main, which the test runner
// never calls. Left unwired the oracle silently diverges from the product it
// certifies: fnSolve's mid-solve refreshScreen is what re-pushes the EQ_EDIT
// softmenu and takes the calculator out of CM_EIM, and without it a later
// program's ENTER lands in the equation-editor branch and never lifts the stack.
//
// Every hook whose C counterpart the upstream testSuite links is installed here:
//
//   refreshScreen              the redraw above.
//   displayBugScreen           compiled unconditionally upstream, and it moves
//                              state, not just pixels: previousCalcMode,
//                              calcMode = CM_BUG_ON_SCREEN, FLAG_ALPHA and
//                              cursorEnabled all change before it paints, and
//                              every later test in the run sees that.
//   reportBugError             its companion, which formats the diagnostic.
//   checkHalfSec               gated on FLAG_MONIT upstream, not on the build:
//   progressHalfSecUpdate_...  with MONIT set the C testSuite really does tick
//                              the half-second clock and draw the progress line.
//
// The abort poll is left on its default: upstream's is PC_BUILD-gated and reads
// currentKeyCode, which no test drives.
//
// This object is linked ONLY into the main testSuite executables. The oracle
// mini-suites rename main for their own entry points and keep the defaults.

const abi = @import("abi");

const bool_t = u8; // the C-ABI bool the shell owners export (realType.h)

extern fn refreshScreen(source: u16) callconv(.c) void;
extern fn displayBugScreen(msg: [*:0]const u8) callconv(.c) void;
extern fn reportBugError(errorCode: u8, errMessageRegisterLine: i16) callconv(.c) void;
extern fn checkHalfSec() callconv(.c) bool_t;
extern fn progressHalfSecUpdate_Integer(
    mode: u8,
    txt: [*c]u8,
    loop: i32,
    clearZ: bool_t,
    clearT: bool_t,
    disp: bool_t,
) callconv(.c) bool_t;
extern fn z47_testsuite_main(argc: c_int, argv: [*c][*c]u8) callconv(.c) c_int;

pub export fn main(argc: c_int, argv: [*c][*c]u8) callconv(.c) c_int {
    abi.host.installRequestRefresh(&refreshScreen);
    abi.host.installShowBugScreen(&displayBugScreen);
    abi.host.installReportBugError(&reportBugError);
    abi.host.installCheckHalfSec(&checkHalfSec);
    abi.host.installProgressHalfSec(&progressHalfSecUpdate_Integer);
    return z47_testsuite_main(argc, argv);
}
