// SPDX-License-Identifier: GPL-3.0-only
//
// The live value panel the solver, the integrator and the sum/product engines
// paint over the stack while they run (ENABLE_SOLVER_PROGRESS in defines.h).
// Four engines draw four different panels into the same three register lines,
// so the register-line geometry and the display-format save/restore live here
// once rather than in each of them.

const abi = @import("abi");
const runtime = @import("solve_runtime.zig");
const consts = abi.constants;

const real_t = abi.Real;
const real34_t = abi.Real34;

inline fn const34_0() *align(1) const real34_t {
    return consts.q16200();
}
const calcRegister_t = runtime.calcRegister_t;

const REGISTER_X: calcRegister_t = 100;
const REGISTER_Y: calcRegister_t = 101;
const REGISTER_Z: calcRegister_t = 102;
const TEMP_REGISTER_1: calcRegister_t = 135;

const Y_POSITION_OF_REGISTER_Y_LINE: u32 = 96;
const Y_POSITION_OF_REGISTER_X_LINE: u32 = 132;
const SCREEN_WIDTH: u32 = 400;
const TMP_STR_LENGTH: i32 = 2560;

const vmNormal: c_int = 0;
const amNone: u32 = 5;
const DF_ALL: u8 = 0;
const FLAG_CPXj: c_int = 0x8005;
const STD_op_i = "\xa1\x48";
const STD_op_j = "\xa1\x49";
/// force_refresh's "force" mode (screen.h).
const force: u8 = 1;

/// decNumber sign bit, in the high byte of the decimal128 encoding.
const REAL34_SIGN_BIT: u8 = 0x80;

inline fn real34IsSpecial(v: *align(1) const real34_t) bool {
    return runtime.decQuadIsNaN(v) != 0 or runtime.decQuadIsSignaling(v) != 0 or runtime.decQuadIsInfinite(v) != 0;
}
inline fn real34IsZero(v: *align(1) const real34_t) bool {
    return runtime.decQuadIsZero(v) != 0;
}
inline fn real34IsNegative(v: *align(1) const real34_t) bool {
    return (v.bytes[15] & REAL34_SIGN_BIT) != 0;
}

/// The digit count the panel renders with: everything the format allows, but no
/// more than the 33 a stack line can hold.
fn beginPanel() u8 {
    const saved = runtime.displayFormatDigits;
    runtime.clearRegisterLine(REGISTER_Z, true, true);
    runtime.clearRegisterLine(REGISTER_Y, true, true);
    runtime.clearRegisterLine(REGISTER_X, true, true);
    runtime.displayFormatDigits = if (runtime.displayFormat == DF_ALL) 0 else 33;
    return saved;
}

fn endPanel(saved: u8) void {
    runtime.displayFormatDigits = saved;
    runtime.force_refresh(force);
}

fn showValueAt(value: *align(1) const real34_t, y: u32) void {
    runtime.real34ToDisplayString(value, amNone, runtime.tmpString, &runtime.standardFont, 9999, 34, false, true, 0);
    _ = runtime.showString(runtime.tmpString, &runtime.standardFont, 1, y, vmNormal, true, true);
}

fn signMark(v: *align(1) const real34_t) [*c]const u8 {
    if (real34IsSpecial(v)) return "?";
    if (real34IsZero(v)) return "";
    return if (real34IsNegative(v)) "-" else "+";
}

/// The solver's bracket panel: the two endpoints, each with the sign of the
/// function there. The endpoints are shown in increasing order.
pub fn showSolverBracket(a_in: *align(1) const real34_t, b_in: *align(1) const real34_t, fa_in: *align(1) const real34_t, fb_in: *align(1) const real34_t) void {
    var a = a_in;
    var b = b_in;
    var fa = fa_in;
    var fb = fb_in;
    if (runtime.real34CompareGreaterThan(a, b)) {
        const t = a;
        a = b;
        b = t;
        const tf = fa;
        fa = fb;
        fb = tf;
    }

    const saved = beginPanel();
    showValueAt(a, Y_POSITION_OF_REGISTER_Y_LINE + 6);
    _ = runtime.showString(signMark(fa), &runtime.standardFont, SCREEN_WIDTH - 10, Y_POSITION_OF_REGISTER_Y_LINE + 6, vmNormal, true, true);
    showValueAt(b, Y_POSITION_OF_REGISTER_X_LINE + 6);
    _ = runtime.showString(signMark(fb), &runtime.standardFont, SCREEN_WIDTH - 10, Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, true, true);
    runtime.displayFormatDigits = saved;
    lcdRefreshOnFirmware();
}

/// The solver and integrator panels refresh the whole LCD rather than going
/// through force_refresh, and only on the firmware. lcd_refresh is a DMCP ROM
/// jump-table call there, not a link symbol.
const solve_build_options = @import("solve_build_options");
const is_dmcp_build = @import("builtin").target.os.tag == .freestanding;
const dm42_pkg_xip = solve_build_options.dm42_pkg_xip;
const library_fn_base: usize = if (dm42_pkg_xip) 0x08000201 else 0x08000301;
fn lcdRefreshOnFirmware() void {
    if (comptime is_dmcp_build) {
        const f: *const fn () callconv(.c) void = @ptrFromInt(library_fn_base + 48);
        f();
    }
}

/// The integrator's panel: the partial integral on X and the remaining interval
/// width on Y.
pub fn showIntegralPartial(partial: *align(1) const real34_t, span: *align(1) const real34_t) void {
    const saved = beginPanel();
    showValueAt(partial, Y_POSITION_OF_REGISTER_X_LINE + 6);
    showValueAt(span, Y_POSITION_OF_REGISTER_Y_LINE + 6);
    runtime.displayFormatDigits = saved;
    lcdRefreshOnFirmware();
}

/// The integer sum/product panel: the running value, through TEMP_REGISTER_1
/// because only a register can be rendered as a long integer.
pub fn showLongIntegerPartial(a: *const abi.Mpz) void {
    const saved = beginPanel();
    runtime.convertLongIntegerToLongIntegerRegister(a, TEMP_REGISTER_1);
    runtime.longIntegerRegisterToDisplayString(TEMP_REGISTER_1, runtime.tmpString, TMP_STR_LENGTH, 400, 400, false); // allow LARGELI
    _ = runtime.showString(runtime.tmpString, &runtime.standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, true, true);
    endPanel(saved);
}

/// The real sum/product panel: one line for a real running value, two for a
/// complex one with the imaginary part signed and unit-tagged.
pub fn showRealPartial(a: *align(1) const real34_t, ai: *align(1) const real34_t, cpx: bool) void {
    const saved = beginPanel();
    if (!cpx) {
        showValueAt(a, Y_POSITION_OF_REGISTER_X_LINE + 6);
    } else {
        showValueAt(a, Y_POSITION_OF_REGISTER_Y_LINE + 6);
        // A numeric comparison, not a sign-bit read: -0 takes the "+" branch and
        // a NaN takes the blank one.
        const sign_text: [*c]const u8 = if (runtime.real34CompareGreaterEqual(ai, const34_0())) "+" else " ";
        const x = runtime.showString(sign_text, &runtime.standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, true, true);
        runtime.real34ToDisplayString(ai, amNone, runtime.tmpString, &runtime.standardFont, 9999, 34, false, true, 0);
        _ = runtime.strcat(runtime.tmpString, if (runtime.getSystemFlag(FLAG_CPXj)) STD_op_j else STD_op_i);
        _ = runtime.showString(runtime.tmpString, &runtime.standardFont, x, Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, true, true);
    }
    endPanel(saved);
}
