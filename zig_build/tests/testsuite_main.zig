// SPDX-License-Identifier: GPL-3.0-only
//
// Entry point of the testSuite executables. The upstream runner ships its own
// main() in src/testSuite/testSuite.c, which the build renames to
// z47_testsuite_main so this wrapper can run first.
//
// The wrapper exists to wire the core->shell redraw hook (abi.host). Upstream
// links a plain refreshScreen, so its testSuite gets the calculator's real
// redraw behaviour; z47 severed that call behind an installable hook whose
// default is a neutral no-op, and the hook is installed by program_main, which
// the test runner never calls. Left unwired the oracle silently diverges from
// the product it certifies: fnSolve's mid-solve refreshScreen is what re-pushes
// the EQ_EDIT softmenu and takes the calculator out of CM_EIM, and without it a
// later program's ENTER lands in the equation-editor branch and never lifts the
// stack.
//
// Only the redraw hook is installed. The rest of the table (the abort poll and
// the half-second progress line) is interactive pacing with no calculation
// effect, and the headless defaults are what the suite has always run with.
//
// This object is linked ONLY into the main testSuite executables. The oracle
// mini-suites rename main for their own entry points and keep the defaults.

const abi = @import("abi");

extern fn refreshScreen(source: u16) callconv(.c) void;
extern fn z47_testsuite_main(argc: c_int, argv: [*c][*c]u8) callconv(.c) c_int;

pub export fn main(argc: c_int, argv: [*c][*c]u8) callconv(.c) c_int {
    abi.host.installRequestRefresh(&refreshScreen);
    return z47_testsuite_main(argc, argv);
}
