// Register value codec shared by the save/restore owners: the per-register
// value <-> text conversion that was registerToSaveString / restoreRegister /
// textTag (file-static in saveRestoreCalcState.c). The scalar type paths
// (longInteger, string, shortInteger, real34, complex34, time, date) are Zig and
// exercised by the enriched parity harness; the matrix vector-tag predicates
// (isRegisterMatrixVector / getVectorRegister{Angular,Polar}Mode — macros over
// the matrix subsystem) are reached as direct externs to the canonical core C symbols. The C statics
// remain for the DMCP retained path.

const std = @import("std");
const abi = @import("abi");
const vector_shape = @import("vector_shape.zig"); // std-only matrix vector-shape
const data_file_bytes = @import("data_file_bytes.zig"); // std-only data-file byte transforms
const text = @import("calc_state_text.zig");
const calc_state = @import("calc_state.zig"); // intra-object Zig-to-Zig

// data types (typeDefinitions.h)
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

// angular modes
const amRadian: u8 = 0;
const amGrad: u8 = 1;
const amDegree: u8 = 2;
const amDMS: u8 = 3;
const amMultPi: u8 = 4;
const amNone: u8 = 5;
const amAngleMask: u32 = 15;
const amPolar: u32 = 16;

const START_REGISTER_VALUE: usize = 860;
const TMP_STR_LENGTH: i32 = 2560;
const STR_LG_INT_HEADER_SIZE: usize = 4; // sizeof(strLgIntHeader_t)
const REAL34_SIZE_IN_BYTES: usize = 16;
const COMPLEX34_SIZE_IN_BYTES: usize = 32;
const MATRIX_HEADER_SIZE: usize = 4; // sizeof(matrixHeader_t)
const CONFIG_DESCRIPTOR_SIZE: usize = 840; // sizeof(dtConfigDescriptor_t)

// 32-bit bitfield: rows:12, columns:12, mtag:6, notUsed:2.
const REAL34_SIZE_IN_BLOCKS: u32 = 4;
const COMPLEX34_SIZE_IN_BLOCKS: u32 = 8;
const OpaqueCtx = opaque {};

const matrixHeader_t = abi.MatrixHeader;
const MpzStruct = abi.Mpz;
comptime {
    std.debug.assert(@sizeOf(matrixHeader_t) == 4);
    // mpz_t = { int, int, mp_limb_t* }: 16 bytes on a 64-bit host, 12 on the
    // 32-bit ARM firmware target. Keep the assert target-adaptive.
    std.debug.assert(@sizeOf(MpzStruct) == 2 * @sizeOf(c_int) + @sizeOf(?*anyopaque));
}

extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcat(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strlen(s: [*c]const u8) usize;
extern fn sprintf(str: [*c]u8, format: [*c]const u8, ...) c_int;
extern fn stringToUtf8(str: [*c]const u8, utf8: [*c]u8) void;
extern fn ioFileWrite(buffer: ?*const anyopaque, size: u32) void;
// Single-byte read primitives used by the dataFileMode token readers below.
// These are the exact analogs of saveRestoreCalcState.c's static restore()
// (a one-byte ioFileRead wrapper) and ioEof(); both are provided by the
// runtime/HAL the same C uses, so they are genuinely linkable here.
extern fn ioFileRead(buffer: ?*anyopaque, size: u32) u32;
extern fn ioEof() c_int;

// Read the next whitespace-delimited token, skipping leading whitespace.
// Faithful port of saveRestoreCalcState.c readToken: any run of spaces/tabs/
// newlines/CRs separates elements, so a data-file matrix row may hold several
// elements. `tok` must point at a buffer large enough for the token.
fn readToken(tok: [*c]u8, maxLen: usize) void {
    @setRuntimeSafety(true); // untrusted file input -- see calc_state.zig's panic decl
    var p = tok;
    const end = if (maxLen == 0) tok else tok + maxLen - 1; // last writable slot; reserve one byte for the terminator
    if (maxLen != 0 and ioEof() == 0) {
        _ = ioFileRead(p, 1);
        while ((p[0] == ' ' or p[0] == '\t' or p[0] == '\n' or p[0] == '\r') and ioEof() == 0) {
            _ = ioFileRead(p, 1);
        }
        while (@intFromPtr(p) < @intFromPtr(end) and p[0] != ' ' and p[0] != '\t' and p[0] != '\n' and p[0] != '\r' and ioEof() == 0) {
            p += 1;
            _ = ioFileRead(p, 1);
        }
        // Token longer than the buffer: drain to the separator so the next read
        // resyncs, as readLine() does. A read that returns nothing cannot make
        // progress, and ioEof() stays false on an I/O error.
        while (p[0] != ' ' and p[0] != '\t' and p[0] != '\n' and p[0] != '\r') {
            if (ioFileRead(p, 1) == 0) {
                break;
            }
        }
    }
    p[0] = 0;
}

// Read the next complex matrix element token, skipping leading whitespace. A
// complex element is either a parenthesised group "( ... )" (read up to and
// including the closing ')', may span newlines) or a bare whitespace-free 'i'
// form token. Faithful port of saveRestoreCalcState.c readComplexToken.
fn readComplexToken(tok: [*c]u8, maxLen: usize) void {
    @setRuntimeSafety(true); // untrusted file input -- see calc_state.zig's panic decl
    var p = tok;
    const end = if (maxLen == 0) tok else tok + maxLen - 1; // last writable slot; reserve one byte for the terminator
    if (maxLen != 0 and ioEof() == 0) {
        _ = ioFileRead(p, 1);
        while ((p[0] == ' ' or p[0] == '\t' or p[0] == '\n' or p[0] == '\r') and ioEof() == 0) {
            _ = ioFileRead(p, 1);
        }
        if (p[0] == '(') {
            while (@intFromPtr(p) < @intFromPtr(end) and p[0] != ')' and ioEof() == 0) {
                p += 1;
                _ = ioFileRead(p, 1);
            }
            // Group longer than the buffer: drain to the closing parenthesis so the
            // next read resyncs. See readToken().
            while (p[0] != ')') {
                if (ioFileRead(p, 1) == 0) {
                    break;
                }
            }
            if (p[0] == ')' and @intFromPtr(p) < @intFromPtr(end)) {
                p += 1;
            }
        } else {
            while (@intFromPtr(p) < @intFromPtr(end) and p[0] != ' ' and p[0] != '\t' and p[0] != '\n' and p[0] != '\r' and ioEof() == 0) {
                p += 1;
                _ = ioFileRead(p, 1);
            }
            // Token longer than the buffer: drain to the separator. See readToken().
            while (p[0] != ' ' and p[0] != '\t' and p[0] != '\n' and p[0] != '\r') {
                if (ioFileRead(p, 1) == 0) {
                    break;
                }
            }
        }
    }
    p[0] = 0;
}

extern fn getRegisterDataType(regist: i16) u32;
extern fn getRegisterDataPointer(regist: i16) [*c]u8;
extern fn getRegisterTag(regist: i16) u32;
extern fn convertLongIntegerRegisterToLongInteger(regist: i16, li: *MpzStruct) void;
extern fn longIntegerToAllocatedString(li: *const MpzStruct, str: [*c]u8, str_len: i32) void;
extern fn __gmpz_clear(li: *MpzStruct) void;
extern fn convertShortIntegerRegisterToUInt64(regist: i16, sign: *i16, value: *u64) void;
extern fn decQuadToString(src: [*c]const u8, dst: [*c]u8) [*c]u8;

// matrix vector-tag predicates (registers.h / typeDefinitions.h macros, ported
// pure: a register is a 2D/3D "vector" matrix by its 1xN / Nx1 dims).
const amPolarSPH: u8 = 128;
const amPolarCYL: u8 = 64;

fn matrixRows(regist: i16) u16 {
    const hdr: *const matrixHeader_t = abi.registerMatrixHeaderAligned(regist);
    return hdr.matrixRows;
}
fn matrixCols(regist: i16) u16 {
    const hdr: *const matrixHeader_t = abi.registerMatrixHeaderAligned(regist);
    return hdr.matrixColumns;
}
fn isMatrix2dVector(rows: u16, cols: u16) bool {
    return vector_shape.is2dVector(rows, cols);
}
fn isMatrix3dVector(rows: u16, cols: u16) bool {
    return vector_shape.is3dVector(rows, cols);
}
fn isRegisterMatrixVector(regist: i16) bool {
    if (getRegisterDataType(regist) != dtReal34Matrix) return false;
    const r = matrixRows(regist);
    const c = matrixCols(regist);
    return isMatrix3dVector(r, c) or isMatrix2dVector(r, c);
}
fn getVectorRegisterAngularMode(regist: i16) u8 {
    if (getRegisterDataType(regist) != dtReal34Matrix) return amNone;
    return @intCast(getRegisterTag(regist) & amAngleMask);
}
fn getVectorRegisterPolarMode(regist: i16) u8 {
    if (getRegisterDataType(regist) != dtReal34Matrix) return 0;
    const tag = getRegisterTag(regist);
    if ((tag & amAngleMask) == @as(u32, amNone)) return 0;
    const r = matrixRows(regist);
    const c = matrixCols(regist);
    if (isMatrix3dVector(r, c)) {
        return if ((tag & amPolar) == amPolar) amPolarSPH else amPolarCYL;
    } else if (isMatrix2dVector(r, c)) {
        return @intCast(tag & amPolar);
    }
    return 0;
}

// restore-side core helpers
extern fn reallocateRegister(regist: i16, data_type: u32, data_size: u16, tag: u32) void;
extern fn decQuadFromString(dst: [*c]u8, src: [*c]const u8, ctx: *OpaqueCtx) [*c]u8;
extern fn convertLongIntegerToLongIntegerRegister(li: *const MpzStruct, regist: i16) void;
extern fn convertUInt64ToShortIntegerRegister(sign: i16, value: u64, base: u32, regist: i16) void;
extern fn utf8ToString(utf8: [*c]const u8, str: [*c]u8) void;
extern fn xcopy(dst: ?*anyopaque, src: ?*const anyopaque, nbytes: u32) ?*anyopaque;
const displayBugScreen = abi.host.showBugScreen; // routed through the host-callback boundary
extern fn __gmpz_init(li: *MpzStruct) void;
extern fn __gmpz_set_str(li: *MpzStruct, str: [*c]const u8, base: c_int) c_int;
extern fn decNumberToString(src: [*c]const u8, dst: [*c]u8) [*c]u8;
extern fn decNumberFromString(dst: [*c]u8, src: [*c]const u8, ctx: *OpaqueCtx) [*c]u8;
extern var ctxtReal34: OpaqueCtx;
extern var ctxtReal75: OpaqueCtx;
extern var statisticalSumsPointer: ?*anyopaque; // real_t*
extern var errorMessage: [*c]u8;

const REAL_SIZE_IN_BYTES: usize = 60; // sizeof(real_t)

extern var tmpString: [*c]u8;
extern var aimBuffer1: [400]u8;

// The register value is serialized into the global tmpString at a fixed offset
// (the C `tmpRegisterString = tmpString + START_REGISTER_VALUE`).
pub fn regValueBuf() [*c]u8 {
    return tmpString + START_REGISTER_VALUE;
}

fn aim() [*c]u8 {
    return &aimBuffer1[0];
}

fn regReal34Data(regist: i16) [*c]u8 {
    return getRegisterDataPointer(regist);
}
fn regImag34Data(regist: i16) [*c]u8 {
    return getRegisterDataPointer(regist) + REAL34_SIZE_IN_BYTES;
}
fn regStringData(regist: i16) [*c]u8 {
    return getRegisterDataPointer(regist) + STR_LG_INT_HEADER_SIZE;
}

// Append angle / polar markers to the type tag (textTag).
pub fn textTag(str: [*c]u8, angle: u8, polmode: u8) void {
    if (angle != amNone) {
        switch (angle & @as(u8, @intCast(amAngleMask))) {
            amDegree => _ = strcat(str, ":DEG"),
            amDMS => _ = strcat(str, ":DMS"),
            amRadian => _ = strcat(str, ":RAD"),
            amMultPi => _ = strcat(str, ":MULTPI"),
            amGrad => _ = strcat(str, ":GRAD"),
            amNone => {},
            else => _ = strcpy(str, ":???"),
        }
    }
    if ((polmode & @as(u8, @intCast(amPolar))) == @as(u8, @intCast(amPolar))) {
        _ = strcat(str, "p");
    }
}

// When true, registerToSaveString / saveMatrixElements emit the compact,
// human-readable data-file forms (set by doSaveDataFile / doLoadDataFile).
// When false the legacy full-state ("re im") forms are produced, byte-identical
// to the pre-data-file behavior — that path stays covered by the state tests.
pub var dataFileMode: bool = false;

const TEMP_REGISTER_1: i16 = 135;
const FLAG_YMD: c_int = 0xc001;
const FLAG_MDY: c_int = 0xc003;

extern fn copySourceRegisterToDestRegister(rSource: i16, rDest: i16) void;
extern fn fnFrom_msRegister(regist: i16) void;
extern fn convertDateRegisterToReal34Register(source: i16, destination: i16) void;
extern fn getSystemFlag(sf: c_int) bool;
extern fn registerFMAOutputPlainString(regist: i16, prefix: [*c]const u8, displayString: [*c]u8) bool;
extern fn getAngleModeForRegister3r(registerNo: i16, angleMode: *c_int) bool;

pub fn registerToSaveString(regist: i16, isXFNRegister: bool) void {
    const trs = regValueBuf();

    // XFN 1000-digit registers: emit the full-precision plain value via the
    // FMA output helper (OPTION_XFN_1000 path); other types fall through below.
    if (isXFNRegister) {
        if (registerFMAOutputPlainString(regist, "", trs)) {
            _ = strcpy(aim(), "RXFN");
            var am: c_int = 0;
            if (getAngleModeForRegister3r(regist, &am)) {
                textTag(aim(), @intCast(am), 0);
            }
        } else {
            aim()[0] = 0;
            trs[0] = 0;
        }
        return;
    }

    switch (getRegisterDataType(regist)) {
        dtLongInteger => {
            var lg: MpzStruct = undefined;
            convertLongIntegerRegisterToLongInteger(regist, &lg);
            longIntegerToAllocatedString(&lg, trs, TMP_STR_LENGTH - @as(i32, START_REGISTER_VALUE) - 1);
            __gmpz_clear(&lg);
            _ = strcpy(aim(), "LonI");
        },
        dtString => {
            stringToUtf8(regStringData(regist), trs);
            _ = strcpy(aim(), "Stri");
        },
        dtShortInteger => {
            var sign: i16 = 0;
            var value: u64 = 0;
            convertShortIntegerRegisterToUInt64(regist, &sign, &value);
            const base = getRegisterTag(regist);
            var yy: [25]u8 = undefined;
            text.ui64ToString(value, &yy[0]);
            const sep: u8 = if (dataFileMode) '#' else ' '; // data-file packs base after '#'
            abi.fmtCStr(trs, "{c}{s}{c}{d}", .{ @as(u8, @intCast(@as(c_int, if (sign != 0) '-' else '+'))), std.mem.sliceTo(yy[0..], 0), @as(u8, @intCast(@as(c_int, sep))), @as(c_uint, base) });
            _ = strcpy(aim(), "ShoI");
        },
        dtReal34 => {
            _ = decQuadToString(regReal34Data(regist), trs);
            _ = strcpy(aim(), "Real");
            textTag(aim(), @intCast(getRegisterTag(regist) & amAngleMask), 0);
        },
        dtComplex34 => {
            if (dataFileMode) {
                // compact form: real 3, imag -4 -> "(3-i4)"
                var reStr: [100]u8 = undefined;
                var imStr: [100]u8 = undefined;
                _ = decQuadToString(regReal34Data(regist), &reStr[0]);
                _ = decQuadToString(regImag34Data(regist), &imStr[0]);
                var imValue: [*c]u8 = &imStr[0];
                var imSign: u8 = '+';
                if (imStr[0] == '-') { // sign sits between real part and 'i', strip it from the value
                    imSign = '-';
                    imValue += 1;
                } else if (imStr[0] == '+') {
                    imValue += 1;
                }
                abi.fmtCStr(trs, "({s}{c}i{s})", .{ std.mem.sliceTo(reStr[0..], 0), @as(u8, @intCast(@as(c_int, imSign))), @as([*:0]const u8, imValue) });
            } else {
                _ = decQuadToString(regReal34Data(regist), trs);
                _ = strcat(trs, " ");
                _ = decQuadToString(regImag34Data(regist), trs + strlen(trs));
            }
            _ = strcpy(aim(), "Cplx");
            const tag = getRegisterTag(regist);
            textTag(aim(), @intCast(tag & amAngleMask), @intCast(tag & amPolar));
        },
        dtTime => {
            if (dataFileMode) {
                // dtTime -> HHMMSS-coded real in a temp register, so the live one is untouched
                copySourceRegisterToDestRegister(regist, TEMP_REGISTER_1);
                fnFrom_msRegister(TEMP_REGISTER_1);
                _ = decQuadToString(regReal34Data(TEMP_REGISTER_1), trs);
                _ = strcpy(aim(), "THMS");
            } else {
                _ = decQuadToString(regReal34Data(regist), trs);
                _ = strcpy(aim(), "Time");
            }
        },
        dtDate => {
            if (dataFileMode) {
                // dtDate -> real in the current date-format field order; record that order
                copySourceRegisterToDestRegister(regist, TEMP_REGISTER_1);
                convertDateRegisterToReal34Register(TEMP_REGISTER_1, TEMP_REGISTER_1);
                _ = decQuadToString(regReal34Data(TEMP_REGISTER_1), trs);
                if (getSystemFlag(FLAG_YMD)) {
                    _ = strcpy(aim(), "DYMD");
                } else if (getSystemFlag(FLAG_MDY)) {
                    _ = strcpy(aim(), "DMDY");
                } else {
                    _ = strcpy(aim(), "DDMY");
                }
            } else {
                _ = decQuadToString(regReal34Data(regist), trs);
                _ = strcpy(aim(), "Date");
            }
        },
        dtReal34Matrix => matrixToSaveString(regist, false),
        dtComplex34Matrix => matrixToSaveString(regist, true),
        dtConfig => configToSaveString(regist),
        else => {
            _ = strcpy(trs, "???");
            _ = strcpy(aim(), "????");
        },
    }
}

fn matrixToSaveString(regist: i16, is_complex: bool) void {
    const trs = regValueBuf();
    const hdr: *const matrixHeader_t = abi.registerMatrixHeaderAligned(regist);
    abi.fmtCStr(trs, "{d} {d}", .{ @as(c_uint, hdr.matrixRows), @as(c_uint, hdr.matrixColumns) });
    if (!is_complex) {
        _ = strcpy(aim(), "Rema");
        const is_vec = isRegisterMatrixVector(regist);
        const angle: u8 = if (is_vec) getVectorRegisterAngularMode(regist) else amNone;
        const pol: u8 = if (is_vec) getVectorRegisterPolarMode(regist) else 0;
        textTag(aim(), angle, pol);
    } else {
        _ = strcpy(aim(), "Cxma");
        const tag = getRegisterTag(regist);
        const angle: u8 = if ((tag & amPolar) == 0) amNone else @intCast(tag & amAngleMask);
        textTag(aim(), angle, @intCast(tag & amPolar));
    }
}

// Append each matrix element (one real34 per line for a real matrix; "re im"
// per line for a complex matrix) directly to the open save file.
pub fn saveMatrixElements(regist: i16) void {
    const dt = getRegisterDataType(regist);
    if (dt != dtReal34Matrix and dt != dtComplex34Matrix) return;
    const hdr: *const matrixHeader_t = abi.registerMatrixHeaderAligned(regist);
    const cols: u32 = hdr.matrixColumns;
    const count: u32 = @as(u32, hdr.matrixRows) * cols;
    const base = getRegisterDataPointer(regist) + MATRIX_HEADER_SIZE;
    var mbuf: [3000]u8 = undefined;
    const mb: [*c]u8 = &mbuf[0];
    var element: u32 = 0;
    while (element < count) : (element += 1) {
        if (dt == dtReal34Matrix) {
            _ = decQuadToString(base + element * REAL34_SIZE_IN_BYTES, mb);
            if (dataFileMode) {
                // one matrix row per line; tab-separate elements within a row
                _ = strcat(mb, if ((element % cols) == (cols - 1)) "\n" else "\t");
            } else {
                _ = strcat(mb, "\n");
            }
        } else {
            const elem = base + element * COMPLEX34_SIZE_IN_BYTES;
            if (dataFileMode) {
                var reStr: [100]u8 = undefined;
                var imStr: [100]u8 = undefined;
                _ = decQuadToString(elem, &reStr[0]);
                _ = decQuadToString(elem + REAL34_SIZE_IN_BYTES, &imStr[0]);
                // the imaginary sign is emitted between the real part and the
                // 'i', so strip it from the imaginary value
                var imSign: u8 = '+';
                var imValue: [*c]const u8 = &imStr[0];
                if (imStr[0] == '-') {
                    imSign = '-';
                    imValue += 1;
                } else if (imStr[0] == '+') {
                    imValue += 1;
                }
                // parenthesised so element boundaries are unambiguous under
                // free-form whitespace
                abi.fmtCStr(mb, "({s}{c}i{s})", .{ std.mem.sliceTo(reStr[0..], 0), @as(u8, @intCast(@as(c_int, imSign))), @as([*:0]const u8, imValue) });
                _ = strcat(mb, if ((element % cols) == (cols - 1)) "\n" else "\t");
            } else {
                _ = decQuadToString(elem, mb);
                _ = strcat(mb, " ");
                _ = decQuadToString(elem + REAL34_SIZE_IN_BYTES, mb + strlen(mb));
                _ = strcat(mb, "\n");
            }
        }
        ioFileWrite(mb, @intCast(strlen(mb)));
    }
}

fn configToSaveString(regist: i16) void {
    const trs = regValueBuf();
    const cfg: [*c]u8 = getRegisterDataPointer(regist);
    var i: usize = 0;
    while (i < CONFIG_DESCRIPTOR_SIZE) : (i += 1) {
        abi.fmtCStr(trs + i * 2, "{X:0>2}", .{@as(c_uint, cfg[i])});
    }
    _ = strcpy(aim(), "Conf");
}

// ===================== RESTORE side =====================

extern fn strcmp(a: [*c]const u8, b: [*c]const u8) c_int;
fn strcmpEq(a: [*c]const u8, b: [*c]const u8) bool {
    return strcmp(a, b) == 0;
}

fn hexVal(c: u8) u32 {
    return data_file_bytes.hexVal(c);
}

// TO_BLOCKS(sizeof(matrixHeader_t)): the one block every matrix register carries
// before its elements. One conversion, so no call site has to repeat it.
const MATRIX_HEADER_BLOCKS: u32 = abi.block_math.toBlocks(u32, MATRIX_HEADER_SIZE);

/// Refuse matrix dimensions a register cannot hold, as upstream
/// `saveRestoreCalcState.c` does. `rows`/`cols` arrive from the state or data
/// file, `reallocateRegister` takes a u16 block count, and an unrefused pair
/// truncates that count, under-allocates, and lets `restoreMatrixData` write
/// past the register. Every site that turns file dimensions into a register --
/// the two `restoreRegister` branches and `skipMatrixData` -- must go through
/// this, or the restore and skip sides disagree on the element count and the
/// file position desynchronises.
fn clampMatrixDims(rows: u16, cols: u16, element_blocks: u32) vector_shape.Dims {
    return vector_shape.clampToRegisterCapacity(
        .{ .rows = rows, .cols = cols },
        element_blocks,
        MATRIX_HEADER_BLOCKS,
    );
}

/// The element block count `reallocateRegister` is called with. Upstream passes
/// the elements only -- the header block appears in the capacity test, not in the
/// request. `@intCast` is in range by construction and not merely by inspection:
/// `dims` has been through `clampMatrixDims`, which rejects anything whose block
/// count including the header exceeds a u16, so the elements alone are at most
/// 65534.
fn matrixDataBlocks(dims: vector_shape.Dims, element_blocks: u32) u16 {
    return @intCast(vector_shape.registerBlocks(dims, element_blocks, 0));
}

// `@truncate`, not `@intCast`: upstream's fields are `unsigned matrixRows : 12`
// bitfields (typeDefinitions.h) and it assigns a uint16_t straight into them, so
// C narrows by truncation and that is defined. The capacity clamp bounds the
// PRODUCT at 16383 elements, not either dimension on its own -- 16383x1 passes it
// and still exceeds 12 bits -- so a value wider than the field is reachable, and
// `@intCast` would make it illegal behaviour here where upstream is defined: a
// panic on the host, silent UB in the ReleaseSmall firmware.
//
// The residual is upstream's and is deliberately NOT diverged from: for such a
// shape the header ends up describing fewer elements than the allocation and the
// file supplies, so the element restore and the file position disagree. Report it
// upstream rather than fixing it here, where a local clamp would change behaviour
// on a file upstream accepts.
fn setMatrixDims(regist: i16, dims: vector_shape.Dims) void {
    const hdr: *matrixHeader_t = abi.registerMatrixHeaderAligned(regist);
    hdr.matrixRows = @truncate(dims.rows);
    hdr.matrixColumns = @truncate(dims.cols);
}

// Data-file restore helpers (inverse of the dataFileMode save forms).
extern fn strchr(s: [*c]const u8, c: c_int) [*c]u8;
extern fn hmmssInRegisterToSeconds(regist: i16) void;
extern fn convertReal34RegisterToDateRegister(source: i16, destination: i16, handleYY: bool) void;
extern fn setSystemFlag(sf: c_uint) void;
extern fn clearSystemFlag(sf: c_uint) void;
const FLAG_DMY: c_int = 0xc002;

// Data files may localize the decimal separator; normalize ',' -> '.' in place.
fn dataFileCommaToPeriod(str: [*c]u8) void {
    data_file_bytes.commaToPeriod(str);
}

// Normalize any accepted complex form -- "(3-i4)", "+3+i4", "i4", stock "3 -4" --
// into the stock "re im" form the parser below expects. The pure text transform
// lives in the shared std-only abi.complex_text module (dest is a 200-byte scratch).
fn standardiseComplex(src_in: [*c]const u8, dest: [*c]u8) void {
    abi.complex_text.standardiseComplex(src_in, dest[0..abi.complex_text.STANDARDISED_COMPLEX_LENGTH]);
}

// Parse one register value (the inverse of registerToSaveString). `type_str`
// (the 4-char type tag, possibly with a ":TAG[p]" suffix) and `value` are
// mutated in place exactly as the C does.
pub fn restoreRegister(regist: i16, type_str: [*c]u8, value_in: [*c]u8, loaded_version: u32) void {
    @setRuntimeSafety(true); // untrusted file input -- see calc_state.zig's panic decl
    var tag: u32 = amNone;
    var value = value_in;

    if (type_str[4] == ':') {
        const c5 = type_str[5];
        if (c5 == 'R') {
            tag = amRadian;
        } else if (c5 == 'M') {
            tag = amMultPi;
        } else if (c5 == 'G') {
            tag = amGrad;
        } else if (c5 == 'D' and type_str[6] == 'E') {
            tag = amDegree;
        } else if (c5 == 'D' and type_str[6] == 'M') {
            tag = amDMS;
        } else {
            tag = amNone;
        }
        if (type_str[strlen(type_str) - 1] == 'p') tag |= amPolar;
        type_str[4] = 0;
    }

    if (strcmpEq(type_str, "Real")) {
        reallocateRegister(regist, dtReal34, 0, tag);
        if (dataFileMode) dataFileCommaToPeriod(value);
        _ = decQuadFromString(regReal34Data(regist), value, &ctxtReal34);
    } else if (strcmpEq(type_str, "Time")) {
        reallocateRegister(regist, dtTime, 0, amNone);
        _ = decQuadFromString(regReal34Data(regist), value, &ctxtReal34);
    } else if (strcmpEq(type_str, "Date")) {
        reallocateRegister(regist, dtDate, 0, amNone);
        _ = decQuadFromString(regReal34Data(regist), value, &ctxtReal34);
    } else if (strcmpEq(type_str, "THMS")) {
        // data-file time: HHMMSS-coded real -> seconds, in a temp register
        reallocateRegister(TEMP_REGISTER_1, dtReal34, 0, amNone);
        if (dataFileMode) dataFileCommaToPeriod(value);
        _ = decQuadFromString(regReal34Data(TEMP_REGISTER_1), value, &ctxtReal34);
        hmmssInRegisterToSeconds(TEMP_REGISTER_1);
        copySourceRegisterToDestRegister(TEMP_REGISTER_1, regist);
    } else if (strcmpEq(type_str, "DYMD") or strcmpEq(type_str, "DDMY") or strcmpEq(type_str, "DMDY")) {
        // data-file date: the type code gives the field order; force the matching
        // flag for the conversion, then restore the user's date flags.
        const savedYMD = getSystemFlag(FLAG_YMD);
        const savedMDY = getSystemFlag(FLAG_MDY);
        const savedDMY = getSystemFlag(FLAG_DMY);
        clearSystemFlag(@intCast(FLAG_YMD));
        clearSystemFlag(@intCast(FLAG_MDY));
        clearSystemFlag(@intCast(FLAG_DMY));
        if (strcmpEq(type_str, "DYMD")) {
            setSystemFlag(@intCast(FLAG_YMD));
        } else if (strcmpEq(type_str, "DMDY")) {
            setSystemFlag(@intCast(FLAG_MDY));
        } else {
            setSystemFlag(@intCast(FLAG_DMY));
        }
        reallocateRegister(TEMP_REGISTER_1, dtReal34, 0, amNone);
        if (dataFileMode) dataFileCommaToPeriod(value);
        _ = decQuadFromString(regReal34Data(TEMP_REGISTER_1), value, &ctxtReal34);
        convertReal34RegisterToDateRegister(TEMP_REGISTER_1, TEMP_REGISTER_1, false);
        copySourceRegisterToDestRegister(TEMP_REGISTER_1, regist);
        clearSystemFlag(@intCast(FLAG_YMD));
        clearSystemFlag(@intCast(FLAG_MDY));
        clearSystemFlag(@intCast(FLAG_DMY));
        if (savedYMD) setSystemFlag(@intCast(FLAG_YMD));
        if (savedMDY) setSystemFlag(@intCast(FLAG_MDY));
        if (savedDMY) setSystemFlag(@intCast(FLAG_DMY));
    } else if (strcmpEq(type_str, "LonI")) {
        var li: MpzStruct = undefined;
        __gmpz_init(&li);
        _ = __gmpz_set_str(&li, value, 10);
        convertLongIntegerToLongIntegerRegister(&li, regist);
        __gmpz_clear(&li);
    } else if (strcmpEq(type_str, "Stri")) {
        utf8ToString(value, errorMessage);
        const len: i32 = @as(i32, @intCast(strlen(errorMessage))) + 1;
        reallocateRegister(regist, dtString, @intCast((@as(u32, @intCast(len)) + 3) >> 2), amNone);
        _ = xcopy(regStringData(regist), errorMessage, @intCast(len));
    } else if (strcmpEq(type_str, "ShoI")) {
        const sign: i16 = if (value[0] == '-') 1 else 0;
        const val = calc_state.stringToUint64(value + 1);
        const hash = strchr(value, '#'); // accept "+255#16" or the old "+255 16"
        value = if (hash != null) hash + 1 else text.nextWord(value);
        const base = text.toUint32(value);
        convertUInt64ToShortIntegerRegister(sign, val, base, regist);
    } else if (strcmpEq(type_str, "Cplx")) {
        reallocateRegister(regist, dtComplex34, 0, tag);
        var stdTmp: [abi.complex_text.STANDARDISED_COMPLEX_LENGTH]u8 = undefined;
        if (dataFileMode) {
            // accept (3-i4) / 3-i4 / +3+i4 / stock "re im"; emit the stock form
            standardiseComplex(value, &stdTmp[0]);
            dataFileCommaToPeriod(&stdTmp[0]);
            value = &stdTmp[0];
        }
        var imaginaryPart = text.skipWord(value);
        if (imaginaryPart[0] != 0) { // separator present: split into real | imaginary
            imaginaryPart[0] = 0;
            imaginaryPart += 1;
            _ = decQuadFromString(regImag34Data(regist), imaginaryPart, &ctxtReal34);
        } else { // no imaginary token: imaginary part is zero, never step past '\0'
            _ = decQuadFromString(regImag34Data(regist), "0", &ctxtReal34);
        }
        _ = decQuadFromString(regReal34Data(regist), value, &ctxtReal34);
    } else if (strcmpEq(type_str, "Rema")) {
        var numOfCols = text.skipWord(value);
        numOfCols[0] = 0;
        numOfCols += 1;
        const rows = text.toUint16(value);
        const cols = text.toUint16(numOfCols);
        const dims = clampMatrixDims(rows, cols, REAL34_SIZE_IN_BLOCKS);
        reallocateRegister(regist, dtReal34Matrix, matrixDataBlocks(dims, REAL34_SIZE_IN_BLOCKS), tag);
        setMatrixDims(regist, dims);
    } else if (strcmpEq(type_str, "Cxma")) {
        var numOfCols = text.skipWord(value);
        numOfCols[0] = 0;
        numOfCols += 1;
        const rows = text.toUint16(value);
        const cols = text.toUint16(numOfCols);
        const dims = clampMatrixDims(rows, cols, COMPLEX34_SIZE_IN_BLOCKS);
        reallocateRegister(regist, dtComplex34Matrix, matrixDataBlocks(dims, COMPLEX34_SIZE_IN_BLOCKS), tag);
        setMatrixDims(regist, dims);
    } else if (strcmpEq(type_str, "Conf")) {
        // The config register is a raw byte image of dtConfigDescriptor_t, whose
        // field layout is only guaranteed from version 10000020. Upstream gates
        // this whole branch on that and bounds the decode to
        // sizeof(dtConfigDescriptor_t), with the reason written beside it: older
        // files hold earlier layouts (896, 928, 832, 856 or reordered 840 bytes)
        // whose bytes would recall into the wrong settings, and C43-era files parse
        // as version 0, so skipping the entry beats decoding a descriptor RCLCFG
        // cannot apply.
        //
        // The port had NEITHER the gate nor the bound. For a file claiming a
        // version below 10000008 it decoded 896 bytes and then copied 32 more,
        // into a register `reallocateRegister` sizes at exactly
        // CONFIG_DESCRIPTOR_SIZE -- 840 bytes. That is an 88-byte WRITE past the
        // end of the register, into the following pool block, driven entirely by a
        // version number the file supplies. Upstream's guard was already in the
        // pinned C when this owner was written; the resync never picked it up.
        //
        // Found by report-clamp-correspondence.py, which M-SAFE-8 built for exactly
        // this class: an upstream guard living inside a function the Zig already
        // has, where symbol-level correspondence sees nothing missing.
        if (loaded_version >= 10000020) {
            reallocateRegister(regist, dtConfig, 0, amNone);
            var cfg: [*c]u8 = getRegisterDataPointer(regist);
            var t: usize = 0;
            while (t < CONFIG_DESCRIPTOR_SIZE) : (t += 1) {
                cfg[0] = @intCast((hexVal(value[0]) << 4) | hexVal(value[1]));
                value += 2;
                cfg += 1;
            }
        }
    } else {
        abi.fmtBufZ(errorMessage[0..512], "In function restoreRegister: Data: Reg {d}, type {s}, value {s} to be coded!", .{ @as(c_int, regist), @as([*:0]const u8, type_str), @as([*:0]const u8, value) });
        displayBugScreen(errorMessage);
    }
}

pub fn restoreMatrixData(regist: i16) void {
    @setRuntimeSafety(true); // untrusted file input -- see calc_state.zig's panic decl
    const dt = getRegisterDataType(regist);
    if (dt == dtReal34Matrix) {
        const hdr: *const matrixHeader_t = abi.registerMatrixHeaderAligned(regist);
        const count = @as(u32, hdr.matrixRows) * @as(u32, hdr.matrixColumns);
        const base = getRegisterDataPointer(regist) + MATRIX_HEADER_SIZE;
        var i: u32 = 0;
        while (i < count) : (i += 1) {
            if (dataFileMode) {
                readToken(tmpString, @intCast(TMP_STR_LENGTH)); // any whitespace (spaces/newlines) separates elements
                dataFileCommaToPeriod(tmpString);
            } else {
                calc_state.readLine(tmpString, @intCast(TMP_STR_LENGTH));
            }
            _ = decQuadFromString(base + i * REAL34_SIZE_IN_BYTES, tmpString, &ctxtReal34);
        }
    } else if (dt == dtComplex34Matrix) {
        const hdr: *const matrixHeader_t = abi.registerMatrixHeaderAligned(regist);
        const count = @as(u32, hdr.matrixRows) * @as(u32, hdr.matrixColumns);
        const base = getRegisterDataPointer(regist) + MATRIX_HEADER_SIZE;
        var i: u32 = 0;
        while (i < count) : (i += 1) {
            if (dataFileMode) {
                var stdTmp: [abi.complex_text.STANDARDISED_COMPLEX_LENGTH]u8 = undefined;
                // one parenthesised "(re-iIM)" group (or bare i form) per
                // element, free-form whitespace between elements
                readComplexToken(tmpString, @intCast(TMP_STR_LENGTH));
                standardiseComplex(tmpString, &stdTmp[0]);
                dataFileCommaToPeriod(&stdTmp[0]);
                _ = strcpy(tmpString, &stdTmp[0]);
            } else {
                calc_state.readLine(tmpString, @intCast(TMP_STR_LENGTH));
            }
            const elem = base + i * COMPLEX34_SIZE_IN_BYTES;
            var imaginaryPart = text.skipWord(tmpString);
            if (imaginaryPart[0] != 0) { // separator present: split into real | imaginary
                imaginaryPart[0] = 0;
                imaginaryPart += 1;
                _ = decQuadFromString(elem + REAL34_SIZE_IN_BYTES, imaginaryPart, &ctxtReal34);
            } else { // no imaginary token: imaginary part is zero, never step past '\0'
                _ = decQuadFromString(elem + REAL34_SIZE_IN_BYTES, "0", &ctxtReal34);
            }
            _ = decQuadFromString(elem, tmpString, &ctxtReal34);
        }
    }
}

pub fn skipMatrixData(type_str: [*c]u8, value_in: [*c]u8) void {
    @setRuntimeSafety(true); // untrusted file input -- see calc_state.zig's panic decl
    if (strcmpEq(type_str, "Rema") or strcmpEq(type_str, "Cxma")) {
        const is_complex = strcmpEq(type_str, "Cxma");
        var numOfCols = text.skipWord(value_in);
        numOfCols[0] = 0;
        numOfCols += 1;
        // Apply the SAME clamp restoreRegister applies. A shape it refuses stores
        // no elements, so this must skip none either or the file position moves
        // by a different amount than the restore side consumed and every later
        // section is parsed from the wrong offset.
        const rows = text.toUint16(value_in);
        const cols = text.toUint16(numOfCols);
        const dims = clampMatrixDims(
            rows,
            cols,
            if (is_complex) COMPLEX34_SIZE_IN_BLOCKS else REAL34_SIZE_IN_BLOCKS,
        );
        const count = @as(u32, dims.rows) * @as(u32, dims.cols);
        var i: u32 = 0;
        while (i < count) : (i += 1) {
            if (dataFileMode) {
                // skip exactly as restoreMatrixData reads, or the file position desyncs
                if (is_complex) {
                    readComplexToken(tmpString, @intCast(TMP_STR_LENGTH));
                } else {
                    readToken(tmpString, @intCast(TMP_STR_LENGTH));
                }
            } else {
                calc_state.readLine(tmpString, @intCast(TMP_STR_LENGTH));
            }
        }
    }
}

// ===================== statistical sums =====================
// Each statistical sum is a real_t (75-digit). statisticalSumsPointer is the
// real_t array base. (Unexercised by the host harness: no stats accumulated.)

pub fn statSumToString(i: u16) void {
    const base: [*c]u8 = @ptrCast(statisticalSumsPointer);
    _ = decNumberToString(base + @as(usize, i) * REAL_SIZE_IN_BYTES, regValueBuf());
}

pub fn loadStatSum(str: [*c]const u8, i: u16) void {
    @setRuntimeSafety(true); // untrusted file input -- see calc_state.zig's panic decl
    const base: [*c]u8 = @ptrCast(statisticalSumsPointer);
    _ = decNumberFromString(base + @as(usize, i) * REAL_SIZE_IN_BYTES, str, &ctxtReal75);
}
