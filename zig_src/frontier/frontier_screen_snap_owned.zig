// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for zig_bridge/frontier/screen_snap_helpers.c (the last residual C
// helper of the frontier screen subsystem). Ports, verbatim:
//
//  1. versionStr / versionStr2 — the two version strings shown by the
//     TI_VERSION / TI_BACKUP_RESTORED render branches in frontier_screen_owned.
//     Upstream assembles them from the generated VERSION_STRING (VCS id), the C
//     preprocessor __DATE__ and VERSION1. We reproduce them faithfully from
//     build options that frontier.zig computes the SAME way generated.zig builds
//     version.h (git describe + date), so no C preprocessor stamp is needed.
//
//  2. fnSNAP backup helpers (z47_frontier_snap_*) — the message-buffer xcopy
//     dance around fnScreenDump() on host / standardScreenDump() on firmware,
//     plus the TAM-buffer save/restore.
//
//  3. copyRegisterToClipboardString (+ the file-local angularUnitToString) —
//     the ~200-line register-to-text formatter called by print.c and
//     textfiles.c. Compiled for both host (PC_BUILD) and firmware (DMCP_BUILD),
//     so it is unconditional here.
//
//  4. letteredRegisterName — the trivial registerFlagLetters[] lookup, externed
//     by the print / textfiles / solver owners and upstream C.
//
//  5. The host-only (PC_BUILD) GTK clipboard / cairo helpers: drawScreen,
//     copy{Screen,Menu,RegisterX,StackRegisters,AllRegisters}ToClipboard and the
//     copyStackRegistersToClipboardString builder. These bind the GTK clipboard,
//     cairo surface and gdk-pixbuf APIs and are dead on firmware (gated by
//     comptime !dmcp_build; GTK/cairo are not linked into the DMCP build).

const frontier_build_options = @import("frontier_build_options");
const dmcp_build: bool = frontier_build_options.dmcp_build;

// ---------------------------------------------------------------------------
// Types (typeDefinitions.h ABI)
// ---------------------------------------------------------------------------
const bool_t = u8;
const calcRegister_t = i16;
const angularMode_t = c_int;
const real34_t = abi.Real34;
const complex34_t = extern struct { bytes: [32]u8 };
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const real_t = abi.Real;
const realContext_t = abi.RealContext;
const mp_limb_t = usize;
const mpz_struct = extern struct {
    _mp_alloc: c_int,
    _mp_size: c_int,
    _mp_d: [*c]mp_limb_t,
};
const longInteger_t = [1]mpz_struct;
// matrixHeader_t: rows:12, cols:12, mtag:6, notUsed:2 (only rows/cols read).
const matrixHeader_t = packed struct(u32) {
    matrixRows: u12,
    matrixColumns: u12,
    mtag: u6,
    notUsed: u2,
};

// ---------------------------------------------------------------------------
// Constants (defines.h / registers.h / fonts.h)
// ---------------------------------------------------------------------------
const REAL34_SIZE_IN_BYTES: usize = 16;
const MATRIX_HEADER_SIZE: usize = 4;
const STR_LGINT_HEADER_SIZE: usize = 4;

const ERROR_MESSAGE_LENGTH: i32 = 512;
const AIM_BUFFER_LENGTH: u32 = 1024;
const NIM_BUFFER_LENGTH: u32 = 200;
const TAM_BUFFER_LENGTH: u32 = 32;

const SCREEN_WIDTH: c_int = 400;
const SCREEN_HEIGHT: c_int = 240;

const FIRST_LETTERED_REGISTER: calcRegister_t = 100;
const FIRST_LOCAL_REGISTER: calcRegister_t = 7000;
const REGISTER_X: calcRegister_t = 100;
const REGISTER_K: calcRegister_t = 111;
const LAST_SPARE_REGISTER: calcRegister_t = 125;
const NUMBER_OF_STATISTICAL_SUMS: i32 = 28;

const dtLongInteger: u32 = 0;
const dtReal34: u32 = 1;
const dtComplex34: u32 = 2;
const dtTime: u32 = 3;
const dtDate: u32 = 4;
const dtString: u32 = 5;
const dtReal34Matrix: u32 = 6;
const dtComplex34Matrix: u32 = 7;
const dtShortInteger: u32 = 8;
const dtConfig: u32 = 9;

// typeDefinitions.h:223-227 — Grad=1, Degree=2, DMS=3, MultPi=4 (was mis-valued:
// amMultPi=1/amGrad=2/amDegree=3/amDMS=4, which scrambled the angle annunciator strings).
const amRadian: angularMode_t = 0;
const amGrad: angularMode_t = 1;
const amDegree: angularMode_t = 2;
const amDMS: angularMode_t = 3;
const amMultPi: angularMode_t = 4;
const amNone: angularMode_t = 5;
const amAngleMask: u32 = 15;

const FLAG_CPXj: c_int = 0x8005;

// STD_* glyph byte sequences (fonts.h).
const STD_pi = "\x83\xc0";
const STD_DEGREE = "\x80\xb0";
const STD_op_i = "\xa1\x48";
const STD_op_j = "\xa1\x49";
const STD_SIGMA = "\x83\xa3";
const STD_SUP_2 = "\xa1\x62";
const STD_SUP_3 = "\xa1\x63";
const STD_SUP_4 = "\xa1\x64";
const STD_CROSS = "\x80\xd7";

// LINEBREAK: defines.h selects "\n" for PC_BUILD+LINUX, "\n\r" for firmware.
const LINEBREAK = if (dmcp_build) "\n\r" else "\n";

// CLIPSTR: 30000 on host (PC_BUILD), TMP_STR_LENGTH (2560) on firmware.
const CLIPSTR: usize = if (dmcp_build) 2560 else 30000;

// cairo / gdk constants.
const CAIRO_FORMAT_RGB24: c_int = 1;
// GDK_SELECTION_CLIPBOARD = _GDK_MAKE_ATOM(69) = GUINT_TO_POINTER(69).
const GDK_SELECTION_CLIPBOARD: ?*anyopaque = @ptrFromInt(69);

// ---------------------------------------------------------------------------
// Version strings (build-stamp, assembled in frontier.zig)
// ---------------------------------------------------------------------------
fn nullTerm(comptime s: []const u8) [s.len + 1:0]u8 {
    var arr: [s.len + 1:0]u8 = undefined;
    @memcpy(arr[0..s.len], s);
    arr[s.len] = 0;
    return arr;
}
const version_str_bytes = frontier_build_options.version_str;
const version_str2_bytes = frontier_build_options.version_str2;
pub export const versionStr: [version_str_bytes.len + 1:0]u8 = nullTerm(version_str_bytes);
pub export const versionStr2: [version_str2_bytes.len + 1:0]u8 = nullTerm(version_str2_bytes);

// ---------------------------------------------------------------------------
// Globals / runtime / libc externs
// ---------------------------------------------------------------------------
extern var tmpString: [*c]u8;
extern var errorMessage: [*c]u8;
extern var tamBuffer: [*c]u8;
extern var statisticalSumsPointer: [*c]real_t;
extern var shortIntegerWordSize: u8;
extern var ctxtReal34: realContext_t;

const baseDigits = @extern([*c]const u8, .{ .name = "baseDigits" });
const registerFlagLetters = @extern([*c]const u8, .{ .name = "registerFlagLetters" });

extern fn xcopy(dest: ?*anyopaque, source: ?*const anyopaque, n: u32) ?*anyopaque;
extern fn strlen(s: [*c]const u8) usize;
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcat(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strchr(s: [*c]const u8, c: c_int) [*c]u8;
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;

extern fn getSystemFlag(sf: c_int) bool_t;
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) [*c]u8;
extern fn getRegisterTag(regist: calcRegister_t) u32;
extern fn convertLongIntegerRegisterToLongInteger(regist: calcRegister_t, lgInt: [*c]mpz_struct) void;
extern fn longIntegerToAllocatedString(lgInt: [*c]const mpz_struct, str: [*c]u8, strLen: i32) void;
extern fn @"__gmpz_clear"(p: *mpz_struct) void;
extern fn timeToDisplayString(regist: calcRegister_t, displayString: [*c]u8, ignoreTDisp: bool_t) void;
extern fn dateToDisplayString(regist: calcRegister_t, displayString: [*c]u8) void;
extern fn convertShortIntegerRegisterToUInt64(regist: calcRegister_t, sign: *i16, value: *u64) void;
extern fn stringToUtf8(str: [*c]const u8, utf8: [*c]u8) void;
extern fn standardScreenDump() void;
extern fn fnScreenDump(unusedButMandatoryParameter: u16) void;

// decimal helpers (decQuad/decNumber macros in C).
extern fn decQuadReduce(r: *real34_t, op: *const real34_t, ctx: *realContext_t) *real34_t;
extern fn decQuadToString(dq: *const real34_t, str: [*c]u8) [*c]u8;
extern fn decNumberToString(r: *const real_t, str: [*c]u8) [*c]u8;

inline fn real34Reduce(operand: *const real34_t, res: *real34_t) void {
    _ = decQuadReduce(res, operand, &ctxtReal34);
}
inline fn real34ToString(source: *const real34_t, destination: [*c]u8) void {
    _ = decQuadToString(source, destination);
}
// real34IsNegative / real34SetPositiveSign are byte-level macros on bytes[15].
inline fn real34IsNegative(source: *const real34_t) bool {
    return (source.bytes[15] & 0x80) == 0x80;
}
inline fn real34SetPositiveSign(operand: *real34_t) void {
    operand.bytes[15] &= 0x7F;
}
inline fn realToString(source: *const real_t, destination: [*c]u8) void {
    _ = decNumberToString(source, destination);
}
inline fn getRegisterAngularMode(reg: calcRegister_t) u32 {
    return getRegisterTag(reg) & amAngleMask;
}
inline fn getRegisterShortIntegerBase(reg: calcRegister_t) u32 {
    return getRegisterTag(reg);
}
inline fn longIntegerFree(op: *mpz_struct) void {
    @"__gmpz_clear"(op);
}
inline fn stringByteLength(s: [*c]const u8) i32 {
    return @intCast(strlen(s));
}
// COMPLEX_UNIT: STD_op_j when FLAG_CPXj is set, else STD_op_i.
inline fn complexUnit() [*:0]const u8 {
    return if (getSystemFlag(FLAG_CPXj) != 0) STD_op_j else STD_op_i;
}

// REGISTER_* data accessors.
inline fn regReal34(reg: calcRegister_t) *real34_t {
    return @ptrCast(@alignCast(getRegisterDataPointer(reg)));
}
inline fn regImag34(reg: calcRegister_t) *real34_t {
    return @ptrCast(@alignCast(getRegisterDataPointer(reg) + REAL34_SIZE_IN_BYTES));
}
inline fn regMatrixHeader(reg: calcRegister_t) *matrixHeader_t {
    return @ptrCast(@alignCast(getRegisterDataPointer(reg)));
}
inline fn regReal34MatrixElems(reg: calcRegister_t) [*]real34_t {
    return @ptrCast(@alignCast(getRegisterDataPointer(reg) + MATRIX_HEADER_SIZE));
}
inline fn regComplex34MatrixElems(reg: calcRegister_t) [*]complex34_t {
    return @ptrCast(@alignCast(getRegisterDataPointer(reg) + MATRIX_HEADER_SIZE));
}
inline fn regStringData(reg: calcRegister_t) [*c]u8 {
    return getRegisterDataPointer(reg) + STR_LGINT_HEADER_SIZE;
}

// ---------------------------------------------------------------------------
// fnSNAP backup helpers
// ---------------------------------------------------------------------------
pub export fn z47_frontier_snap_screenshot_with_message_backup() callconv(.c) void {
    if (comptime dmcp_build) {
        standardScreenDump();
    } else {
        const len = AIM_BUFFER_LENGTH + NIM_BUFFER_LENGTH + TAM_BUFFER_LENGTH + @as(u32, @intCast(ERROR_MESSAGE_LENGTH));
        _ = xcopy(tmpString, errorMessage, len);
        fnScreenDump(0);
        _ = xcopy(errorMessage, tmpString, len);
    }
}

pub export fn z47_frontier_snap_backup_tam(dst: [*c]u8) callconv(.c) void {
    _ = xcopy(dst, tamBuffer, TAM_BUFFER_LENGTH);
}

pub export fn z47_frontier_snap_restore_tam(src: [*c]const u8) callconv(.c) void {
    _ = xcopy(tamBuffer, src, TAM_BUFFER_LENGTH);
}

// ---------------------------------------------------------------------------
// letteredRegisterName
// ---------------------------------------------------------------------------
pub export fn letteredRegisterName(regist: calcRegister_t) callconv(.c) u8 {
    return registerFlagLetters[@intCast(regist - FIRST_LETTERED_REGISTER)];
}

// ---------------------------------------------------------------------------
// angularUnitToString (file-local)
// ---------------------------------------------------------------------------
fn angularUnitToString(angularMode: angularMode_t, string: [*c]u8) void {
    switch (angularMode) {
        amRadian => _ = strcpy(string, "r"),
        amMultPi => _ = strcpy(string, STD_pi),
        amGrad => _ = strcpy(string, "g"),
        amDegree => _ = strcpy(string, STD_DEGREE),
        amDMS => _ = strcpy(string, "d.ms"),
        amNone => {},
        else => _ = strcpy(string, "?"),
    }
}

// ---------------------------------------------------------------------------
// copyRegisterToClipboardString (PC_BUILD || DMCP_BUILD => always)
// ---------------------------------------------------------------------------
pub export fn copyRegisterToClipboardString(regist: calcRegister_t, clipboardString: [*c]u8, forPrinter: bool_t) callconv(.c) void {
    var string: [CLIPSTR]u8 = undefined;
    const buf: [*c]u8 = &string;

    switch (getRegisterDataType(regist)) {
        dtLongInteger => {
            var lgInt: longInteger_t = undefined;
            convertLongIntegerRegisterToLongInteger(regist, &lgInt[0]);
            longIntegerToAllocatedString(&lgInt[0], buf, @intCast(CLIPSTR));
            longIntegerFree(&lgInt[0]);
        },

        dtTime => {
            timeToDisplayString(regist, buf, 0);
        },

        dtDate => {
            dateToDisplayString(regist, buf);
        },

        dtString => {
            const regData = getRegisterDataPointer(regist);
            if (regData != null) {
                const regStr = regStringData(regist);
                _ = xcopy(buf, regStr, @intCast(stringByteLength(regStr) + 1));
            }
        },

        dtReal34Matrix => {
            const matrixHeader = regMatrixHeader(regist);
            var real34 = regReal34MatrixElems(regist);
            var reduced: real34_t = undefined;
            const rows: u32 = matrixHeader.matrixRows;
            const columns: u32 = matrixHeader.matrixColumns;
            _ = sprintf(buf, "%ux%u", rows, columns);

            var i: u32 = 0;
            while (i < rows * columns) : (i += 1) {
                _ = strcat(buf, LINEBREAK);
                const len = strlen(buf);

                real34Reduce(&real34[0], &reduced);
                real34 += 1;
                real34ToString(&reduced, buf + len);

                if (strchr(buf + len, '.') == null and strchr(buf + len, 'E') == null) {
                    _ = strcat(buf + len, ".");
                }
            }
        },

        dtComplex34Matrix => {
            const matrixHeader = regMatrixHeader(regist);
            var complex34 = regComplex34MatrixElems(regist);
            var reduced: real34_t = undefined;
            const rows: u32 = matrixHeader.matrixRows;
            const columns: u32 = matrixHeader.matrixColumns;
            _ = sprintf(buf, "%ux%u", rows, columns);

            var i: u32 = 0;
            while (i < rows * columns) : (i += 1) {
                _ = strcat(buf, LINEBREAK);
                var len = strlen(buf);

                // Real part
                real34Reduce(@ptrCast(&complex34[0]), &reduced);
                real34ToString(&reduced, buf + len);
                if (strchr(buf + len, '.') == null and strchr(buf + len, 'E') == null) {
                    _ = strcat(buf + len, ".");
                }
                len = strlen(buf);

                // Imaginary part
                const imagPart: *const real34_t = @ptrCast(@as([*]u8, @ptrCast(&complex34[0])) + REAL34_SIZE_IN_BYTES);
                real34Reduce(imagPart, &reduced);
                if (real34IsNegative(&reduced)) {
                    _ = sprintf(buf + len, " - %sx", complexUnit());
                    len += 5;
                    real34SetPositiveSign(&reduced);
                    real34ToString(&reduced, buf + len);
                } else {
                    _ = sprintf(buf + len + strlen(buf + len), " + %sx", complexUnit());
                    len += 5;
                    real34ToString(&reduced, buf + len);
                }
                if (strchr(buf + len, '.') == null and strchr(buf + len, 'E') == null) {
                    _ = strcat(buf + len, ".");
                }
                complex34 += 1;
            }
        },

        dtShortInteger => {
            var sign: i16 = undefined;
            var shortInt: u64 = undefined;
            convertShortIntegerRegisterToUInt64(regist, &sign, &shortInt);
            const base: u64 = getRegisterShortIntegerBase(regist);

            var n: i32 = ERROR_MESSAGE_LENGTH - 100;
            if (forPrinter != 0) {
                _ = sprintf(errorMessage + @as(usize, @intCast(n)), "#%d", @as(c_int, @intCast(base)));
            } else {
                _ = sprintf(errorMessage + @as(usize, @intCast(n)), "#%d (word size = %u)", @as(c_int, @intCast(base)), @as(c_uint, shortIntegerWordSize));
            }
            n -= 1;

            if (shortInt == 0) {
                errorMessage[@intCast(n)] = '0';
                n -= 1;
            } else {
                while (shortInt != 0) {
                    errorMessage[@intCast(n)] = baseDigits[@intCast(shortInt % base)];
                    n -= 1;
                    shortInt /= base;
                }
                if (sign != 0) {
                    errorMessage[@intCast(n)] = '-';
                    n -= 1;
                }
            }
            n += 1;

            _ = strcpy(buf, errorMessage + @as(usize, @intCast(n)));
        },

        dtReal34 => {
            var reduced: real34_t = undefined;
            real34Reduce(regReal34(regist), &reduced);
            real34ToString(&reduced, buf);
            if (strchr(buf, '.') == null and strchr(buf, 'E') == null) {
                _ = strcat(buf, ".");
            }
            angularUnitToString(@intCast(getRegisterAngularMode(regist)), buf + strlen(buf));
        },

        dtComplex34 => {
            var reduced: real34_t = undefined;
            var tmpStr: [100]u8 = undefined;
            const tmp: [*c]u8 = &tmpStr;

            // Real part
            real34Reduce(regReal34(regist), &reduced);
            real34ToString(&reduced, tmp);
            if (strchr(tmp, '.') == null and strchr(tmp, 'E') == null) {
                _ = strcat(tmp, ".");
            }
            var len = strlen(tmp);

            // Imaginary part
            real34Reduce(regImag34(regist), &reduced);
            if (real34IsNegative(&reduced)) {
                _ = sprintf(buf, "%s - %sx", tmp, complexUnit());
                len += 5;
                real34SetPositiveSign(&reduced);
                real34ToString(&reduced, buf + len);
            } else {
                _ = sprintf(buf, "%s + %sx", tmp, complexUnit());
                len += 5;
                real34ToString(&reduced, buf + len);
            }
            if (strchr(buf + len, '.') == null and strchr(buf + len, 'E') == null) {
                _ = strcat(buf + len, ".");
            }
        },

        dtConfig => {
            if (forPrinter != 0) {
                _ = xcopy(buf, "Config. data", 13);
            } else {
                _ = xcopy(buf, "Configuration data", 19);
            }
        },

        else => {
            _ = sprintf(buf, "In function copyRegisterXToClipboard, the data type %u is unknown! Please try to reproduce and submit a bug.", getRegisterDataType(regist));
        },
    }

    if (forPrinter != 0) {
        _ = strcpy(clipboardString, buf);
    } else {
        stringToUtf8(buf, clipboardString);
    }
}

// ===========================================================================
// Host-only GTK clipboard / cairo helpers (PC_BUILD). Dead on firmware.
// ===========================================================================
// screenData is a `u32 *` global (the malloc'd LCD framebuffer). @extern returns
// a pointer TO the symbol, so to read the stored buffer pointer we need
// @extern(*[*c]u32) and a `.*` — mirroring screenStride just below. Declaring it
// as @extern([*c]u32) (missing one level) yielded &screenData instead, so
// drawScreen handed cairo the data-segment address and pixman ran off it into an
// unmapped page (SIGSEGV) while also rendering garbage. See drawScreen.
const screenDataPtr = if (!dmcp_build) @extern(*[*c]u32, .{ .name = "screenData" }) else {};
const screenStride = if (!dmcp_build) @extern(*i16, .{ .name = "screenStride" }) else {};
inline fn screenData() [*c]u32 {
    return screenDataPtr.*;
}

extern fn cairo_image_surface_create_for_data(data: [*c]u8, format: c_int, width: c_int, height: c_int, stride: c_int) ?*anyopaque;
extern fn cairo_set_source_surface(cr: ?*anyopaque, surface: ?*anyopaque, x: f64, y: f64) void;
extern fn cairo_surface_mark_dirty(surface: ?*anyopaque) void;
extern fn cairo_paint(cr: ?*anyopaque) void;
extern fn cairo_surface_destroy(surface: ?*anyopaque) void;
extern fn gtk_clipboard_get(selection: ?*anyopaque) ?*anyopaque;
extern fn gtk_clipboard_clear(clipboard: ?*anyopaque) void;
extern fn gtk_clipboard_set_text(clipboard: ?*anyopaque, text: [*c]const u8, len: c_int) void;
extern fn gtk_clipboard_set_image(clipboard: ?*anyopaque, pixbuf: ?*anyopaque) void;
extern fn gdk_pixbuf_get_from_surface(surface: ?*anyopaque, src_x: c_int, src_y: c_int, width: c_int, height: c_int) ?*anyopaque;

inline fn stride4() c_int {
    return @as(c_int, screenStride.*) * 4;
}
inline fn clipboardForClear() ?*anyopaque {
    const clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
    gtk_clipboard_clear(clipboard);
    gtk_clipboard_set_text(clipboard, "", 0);
    return clipboard;
}

pub export fn drawScreen(widget: ?*anyopaque, cr: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    _ = widget;
    _ = data;
    // On firmware this UI helper is dead; reference cr (no discard, which the
    // lint would conflict with its host use below) and return FALSE.
    if (comptime dmcp_build) return @intFromBool(cr != cr);
    const imageSurface = cairo_image_surface_create_for_data(@ptrCast(screenData()), CAIRO_FORMAT_RGB24, SCREEN_WIDTH, SCREEN_HEIGHT, stride4());
    cairo_set_source_surface(cr, imageSurface, 0, 0);
    cairo_surface_mark_dirty(imageSurface);
    cairo_paint(cr);
    cairo_surface_destroy(imageSurface);
    return 0; // FALSE
}

pub export fn copyScreenToClipboard() callconv(.c) void {
    if (comptime dmcp_build) return;
    const clipboard = clipboardForClear();
    const imageSurface = cairo_image_surface_create_for_data(@ptrCast(screenData()), CAIRO_FORMAT_RGB24, SCREEN_WIDTH, SCREEN_HEIGHT, stride4());
    gtk_clipboard_set_image(clipboard, gdk_pixbuf_get_from_surface(imageSurface, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT));
}

pub export fn copyMenuToClipboard() callconv(.c) void {
    if (comptime dmcp_build) return;
    const clipboard = clipboardForClear();
    const imageSurface = cairo_image_surface_create_for_data(@ptrCast(screenData()), CAIRO_FORMAT_RGB24, SCREEN_WIDTH, SCREEN_HEIGHT - 170, stride4());
    gtk_clipboard_set_image(clipboard, gdk_pixbuf_get_from_surface(imageSurface, 0, 170, SCREEN_WIDTH, SCREEN_HEIGHT - 170));
}

pub export fn copyRegisterXToClipboard() callconv(.c) void {
    if (comptime dmcp_build) return;
    const clipboard = clipboardForClear();
    var clipboardString: [CLIPSTR]u8 = undefined;
    copyRegisterToClipboardString(REGISTER_X, &clipboardString, 0);
    gtk_clipboard_set_text(clipboard, &clipboardString, -1);
}

fn copyStackRegistersToClipboardString(clipboardString: [*c]u8, lastRegist: calcRegister_t) void {
    var ptr: [*c]u8 = clipboardString;
    var sep: [*:0]const u8 = "";
    var r: calcRegister_t = lastRegist;
    while (r >= REGISTER_X) : (r -= 1) {
        ptr += @intCast(sprintf(ptr, "%s%c = ", sep, @as(c_int, letteredRegisterName(r))));
        copyRegisterToClipboardString(r, ptr, 0);
        ptr = strchr(ptr, 0);
        sep = LINEBREAK;
    }
}

pub export fn copyStackRegistersToClipboard() callconv(.c) void {
    if (comptime dmcp_build) return;
    const clipboard = clipboardForClear();
    var clipboardString: [10000]u8 = undefined;
    copyStackRegistersToClipboardString(&clipboardString, REGISTER_K);
    gtk_clipboard_set_text(clipboard, &clipboardString, -1);
}

// StatSumNames[NUMBER_OF_STATISTICAL_SUMS]: fixed-width 14-glyph-column labels.
const StatSumNames = [_][]const u8{
    "n             ",
    STD_SIGMA ++ "(x)          ",
    STD_SIGMA ++ "(y)          ",
    STD_SIGMA ++ "(x" ++ STD_SUP_2 ++ ")         ",
    STD_SIGMA ++ "(x" ++ STD_SUP_2 ++ "y)        ",
    STD_SIGMA ++ "(y" ++ STD_SUP_2 ++ ")         ",
    STD_SIGMA ++ "(xy)         ",
    STD_SIGMA ++ "(ln(x)" ++ STD_CROSS ++ "ln(y))",
    STD_SIGMA ++ "(ln(x))      ",
    STD_SIGMA ++ "(ln" ++ STD_SUP_2 ++ "(x))     ",
    STD_SIGMA ++ "(y ln(x))    ",
    STD_SIGMA ++ "(ln(y))      ",
    STD_SIGMA ++ "(ln" ++ STD_SUP_2 ++ "(y))     ",
    STD_SIGMA ++ "(x ln(y))    ",
    STD_SIGMA ++ "(ln(y)/x)    ",
    STD_SIGMA ++ "(x" ++ STD_SUP_2 ++ "/y)       ",
    STD_SIGMA ++ "(1/x)        ",
    STD_SIGMA ++ "(1/x" ++ STD_SUP_2 ++ ")       ",
    STD_SIGMA ++ "(x/y)        ",
    STD_SIGMA ++ "(1/y)        ",
    STD_SIGMA ++ "(1/y" ++ STD_SUP_2 ++ ")       ",
    STD_SIGMA ++ "(x" ++ STD_SUP_3 ++ ")         ",
    STD_SIGMA ++ "(x" ++ STD_SUP_4 ++ ")         ",
    "x min         ",
    "x max         ",
    "y min         ",
    "y max         ",
};

pub export fn copyAllRegistersToClipboard() callconv(.c) void {
    if (comptime dmcp_build) return;
    const clipboard = clipboardForClear();
    var clipboardString: [15000]u8 = undefined;
    var ptr: [*c]u8 = &clipboardString;

    copyStackRegistersToClipboardString(ptr, LAST_SPARE_REGISTER);

    var regist: i32 = 99;
    while (regist >= 0) : (regist -= 1) {
        ptr += strlen(ptr);
        _ = sprintf(ptr, LINEBREAK ++ "R%02d = ", regist);
        ptr += strlen(ptr);
        copyRegisterToClipboardString(@intCast(regist), ptr, 0);
    }

    const numLocal: i32 = currentNumberOfLocalRegisters();
    regist = numLocal - 1;
    while (regist >= 0) : (regist -= 1) {
        ptr += strlen(ptr);
        _ = sprintf(ptr, LINEBREAK ++ "R.%02d = ", regist);
        ptr += strlen(ptr);
        copyRegisterToClipboardString(@intCast(FIRST_LOCAL_REGISTER + regist), ptr, 0);
    }

    if (statisticalSumsPointer != null) {
        const ssp: [*]real_t = @ptrCast(statisticalSumsPointer);
        var sumName: [40]u8 = undefined;
        var sum: i32 = 0;
        while (sum < NUMBER_OF_STATISTICAL_SUMS) : (sum += 1) {
            ptr += strlen(ptr);
            _ = strcpy(&sumName, StatSumNames[@intCast(sum)].ptr);

            _ = sprintf(ptr, LINEBREAK ++ "SR%02d = ", sum);
            ptr += strlen(ptr);
            stringToUtf8(&sumName, ptr);
            ptr += strlen(ptr);
            _ = strcpy(ptr, " = ");
            ptr += strlen(ptr);
            realToString(&ssp[@intCast(sum)], tmpString);
            if (strchr(tmpString, '.') == null and strchr(tmpString, 'E') == null) {
                _ = strcat(tmpString, ".");
            }
            _ = strcpy(ptr, tmpString);
        }
    }

    gtk_clipboard_set_text(clipboard, &clipboardString, -1);
}

// currentNumberOfLocalRegisters: currentSubroutineLevelData->numberOfLocalRegisters.
const subroutineLevelHeader_t = abi.SubroutineLevelHeader;
extern var currentSubroutineLevelData: [*c]subroutineLevelHeader_t;
inline fn currentNumberOfLocalRegisters() u8 {
    return currentSubroutineLevelData[0].numberOfLocalRegisters;
}
