// Register value codec shared by the save/restore owners: the per-register
// value <-> text conversion that was registerToSaveString / restoreRegister /
// textTag (file-static in saveRestoreCalcState.c). The scalar type paths
// (longInteger, string, shortInteger, real34, complex34, time, date) are Zig and
// exercised by the enriched parity harness; the matrix vector-tag predicates
// (isRegisterMatrixVector / getVectorRegister{Angular,Polar}Mode — macros over
// the matrix subsystem) stay C via small z47_css_* trampolines. The C statics
// remain for the DMCP retained path.

const std = @import("std");
const text = @import("calc_state_text_owned.zig");

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

const matrixHeader_t = packed struct(u32) {
    matrixRows: u12,
    matrixColumns: u12,
    mtag: u6,
    notUsed: u2,
};
const MpzStruct = extern struct {
    mp_alloc: c_int,
    mp_size: c_int,
    mp_d: ?*anyopaque,
};
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

extern fn getRegisterDataType(regist: i16) u32;
extern fn getRegisterDataPointer(regist: i16) [*c]u8;
extern fn getRegisterTag(regist: i16) u32;
extern fn convertLongIntegerRegisterToLongInteger(regist: i16, li: *MpzStruct) void;
extern fn longIntegerToAllocatedString(li: *const MpzStruct, str: [*c]u8, str_len: i32) void;
extern fn __gmpz_clear(li: *MpzStruct) void;
extern fn convertShortIntegerRegisterToUInt64(regist: i16, sign: *i16, value: *u64) void;
extern fn decQuadToString(src: [*c]const u8, dst: [*c]u8) [*c]u8;

// matrix vector-tag predicates (unexercised by the host harness)
extern fn z47_css_isRegisterMatrixVector(regist: i16) bool;
extern fn z47_css_getVectorRegisterAngularMode(regist: i16) u8;
extern fn z47_css_getVectorRegisterPolarMode(regist: i16) u8;

// restore-side core helpers
extern fn reallocateRegister(regist: i16, data_type: u32, data_size: u16, tag: u32) void;
extern fn decQuadFromString(dst: [*c]u8, src: [*c]const u8, ctx: *OpaqueCtx) [*c]u8;
extern fn convertLongIntegerToLongIntegerRegister(li: *const MpzStruct, regist: i16) void;
extern fn convertUInt64ToShortIntegerRegister(sign: i16, value: u64, base: u32, regist: i16) void;
extern fn utf8ToString(utf8: [*c]const u8, str: [*c]u8) void;
extern fn xcopy(dst: ?*anyopaque, src: ?*const anyopaque, nbytes: u32) ?*anyopaque;
extern fn memcpy(dst: ?*anyopaque, src: ?*const anyopaque, n: usize) ?*anyopaque;
extern fn stringToUint64(s: [*c]const u8) u64;
extern fn readLine(line: [*c]u8) void;
extern fn displayBugScreen(msg: [*c]const u8) void;
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

pub fn registerToSaveString(regist: i16) void {
    const trs = regValueBuf();
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
            _ = sprintf(trs, "%c%s %u", @as(c_int, if (sign != 0) '-' else '+'), &yy[0], @as(c_uint, base));
            _ = strcpy(aim(), "ShoI");
        },
        dtReal34 => {
            _ = decQuadToString(regReal34Data(regist), trs);
            _ = strcpy(aim(), "Real");
            textTag(aim(), @intCast(getRegisterTag(regist) & amAngleMask), 0);
        },
        dtComplex34 => {
            _ = decQuadToString(regReal34Data(regist), trs);
            _ = strcat(trs, " ");
            _ = decQuadToString(regImag34Data(regist), trs + strlen(trs));
            _ = strcpy(aim(), "Cplx");
            const tag = getRegisterTag(regist);
            textTag(aim(), @intCast(tag & amAngleMask), @intCast(tag & amPolar));
        },
        dtTime => {
            _ = decQuadToString(regReal34Data(regist), trs);
            _ = strcpy(aim(), "Time");
        },
        dtDate => {
            _ = decQuadToString(regReal34Data(regist), trs);
            _ = strcpy(aim(), "Date");
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
    const hdr: *const matrixHeader_t = @ptrCast(@alignCast(getRegisterDataPointer(regist)));
    _ = sprintf(trs, "%u %u", @as(c_uint, hdr.matrixRows), @as(c_uint, hdr.matrixColumns));
    if (!is_complex) {
        _ = strcpy(aim(), "Rema");
        const is_vec = z47_css_isRegisterMatrixVector(regist);
        const angle: u8 = if (is_vec) z47_css_getVectorRegisterAngularMode(regist) else amNone;
        const pol: u8 = if (is_vec) z47_css_getVectorRegisterPolarMode(regist) else 0;
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
    const hdr: *const matrixHeader_t = @ptrCast(@alignCast(getRegisterDataPointer(regist)));
    const count: u32 = @as(u32, hdr.matrixRows) * @as(u32, hdr.matrixColumns);
    const base = getRegisterDataPointer(regist) + MATRIX_HEADER_SIZE;
    var mbuf: [3000]u8 = undefined;
    const mb: [*c]u8 = &mbuf[0];
    var element: u32 = 0;
    while (element < count) : (element += 1) {
        if (dt == dtReal34Matrix) {
            _ = decQuadToString(base + element * REAL34_SIZE_IN_BYTES, mb);
        } else {
            const elem = base + element * COMPLEX34_SIZE_IN_BYTES;
            _ = decQuadToString(elem, mb);
            _ = strcat(mb, " ");
            _ = decQuadToString(elem + REAL34_SIZE_IN_BYTES, mb + strlen(mb));
        }
        _ = strcat(mb, "\n");
        ioFileWrite(mb, @intCast(strlen(mb)));
    }
}

fn configToSaveString(regist: i16) void {
    const trs = regValueBuf();
    const cfg: [*c]u8 = getRegisterDataPointer(regist);
    var i: usize = 0;
    while (i < CONFIG_DESCRIPTOR_SIZE) : (i += 1) {
        _ = sprintf(trs + i * 2, "%02X", @as(c_uint, cfg[i]));
    }
    _ = strcpy(aim(), "Conf");
}

// ===================== RESTORE side =====================

extern fn strcmp(a: [*c]const u8, b: [*c]const u8) c_int;
fn strcmpEq(a: [*c]const u8, b: [*c]const u8) bool {
    return strcmp(a, b) == 0;
}

fn hexVal(c: u8) u32 {
    return if (c >= 'A') @as(u32, c - 'A' + 10) else @as(u32, c - '0');
}

fn setMatrixDims(regist: i16, rows: u16, cols: u16) void {
    const hdr: *matrixHeader_t = @ptrCast(@alignCast(getRegisterDataPointer(regist)));
    hdr.matrixRows = @intCast(rows);
    hdr.matrixColumns = @intCast(cols);
}

// Defaults appended when loading a pre-10000008 (896-byte) config descriptor.
const config_pre_10000008_defaults = [_]u8{
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0xF7, 0x77, 0xDC, 0x2C, 0x2B, 0x84, 0x2A, 0x1C,
    0x33, 0x20, 0x30, 0x33, 0x46, 0x0C, 0x2A, 0x33,
    0x01, 0x18, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
};

// Parse one register value (the inverse of registerToSaveString). `type_str`
// (the 4-char type tag, possibly with a ":TAG[p]" suffix) and `value` are
// mutated in place exactly as the C does.
pub fn restoreRegister(regist: i16, type_str: [*c]u8, value_in: [*c]u8, loaded_version: u32) void {
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
        _ = decQuadFromString(regReal34Data(regist), value, &ctxtReal34);
    } else if (strcmpEq(type_str, "Time")) {
        reallocateRegister(regist, dtTime, 0, amNone);
        _ = decQuadFromString(regReal34Data(regist), value, &ctxtReal34);
    } else if (strcmpEq(type_str, "Date")) {
        reallocateRegister(regist, dtDate, 0, amNone);
        _ = decQuadFromString(regReal34Data(regist), value, &ctxtReal34);
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
        const val = stringToUint64(value + 1);
        value = text.nextWord(value);
        const base = text.toUint32(value);
        convertUInt64ToShortIntegerRegister(sign, val, base, regist);
    } else if (strcmpEq(type_str, "Cplx")) {
        reallocateRegister(regist, dtComplex34, 0, tag);
        var imaginaryPart = text.skipWord(value);
        imaginaryPart[0] = 0;
        imaginaryPart += 1;
        _ = decQuadFromString(regReal34Data(regist), value, &ctxtReal34);
        _ = decQuadFromString(regImag34Data(regist), imaginaryPart, &ctxtReal34);
    } else if (strcmpEq(type_str, "Rema")) {
        var numOfCols = text.skipWord(value);
        numOfCols[0] = 0;
        numOfCols += 1;
        const rows = text.toUint16(value);
        const cols = text.toUint16(numOfCols);
        reallocateRegister(regist, dtReal34Matrix, @intCast(REAL34_SIZE_IN_BLOCKS * @as(u32, rows) * @as(u32, cols)), tag);
        setMatrixDims(regist, rows, cols);
    } else if (strcmpEq(type_str, "Cxma")) {
        var numOfCols = text.skipWord(value);
        numOfCols[0] = 0;
        numOfCols += 1;
        const rows = text.toUint16(value);
        const cols = text.toUint16(numOfCols);
        reallocateRegister(regist, dtComplex34Matrix, @intCast(COMPLEX34_SIZE_IN_BLOCKS * @as(u32, rows) * @as(u32, cols)), tag);
        setMatrixDims(regist, rows, cols);
    } else if (strcmpEq(type_str, "Conf")) {
        reallocateRegister(regist, dtConfig, 0, amNone);
        var cfg: [*c]u8 = getRegisterDataPointer(regist);
        const limit: usize = if (loaded_version < 10000008) 896 else CONFIG_DESCRIPTOR_SIZE;
        var t: usize = 0;
        while (t < limit) : (t += 1) {
            cfg[0] = @intCast((hexVal(value[0]) << 4) | hexVal(value[1]));
            value += 2;
            cfg += 1;
        }
        if (loaded_version < 10000008) {
            _ = memcpy(cfg, &config_pre_10000008_defaults[0], config_pre_10000008_defaults.len);
        }
    } else {
        _ = sprintf(errorMessage, "In function restoreRegister: Data: Reg %d, type %s, value %s to be coded!", @as(c_int, regist), type_str, value);
        displayBugScreen(errorMessage);
    }
}

pub fn restoreMatrixData(regist: i16) void {
    const dt = getRegisterDataType(regist);
    if (dt == dtReal34Matrix) {
        const hdr: *const matrixHeader_t = @ptrCast(@alignCast(getRegisterDataPointer(regist)));
        const count = @as(u32, hdr.matrixRows) * @as(u32, hdr.matrixColumns);
        const base = getRegisterDataPointer(regist) + MATRIX_HEADER_SIZE;
        var i: u32 = 0;
        while (i < count) : (i += 1) {
            readLine(tmpString);
            _ = decQuadFromString(base + i * REAL34_SIZE_IN_BYTES, tmpString, &ctxtReal34);
        }
    } else if (dt == dtComplex34Matrix) {
        const hdr: *const matrixHeader_t = @ptrCast(@alignCast(getRegisterDataPointer(regist)));
        const count = @as(u32, hdr.matrixRows) * @as(u32, hdr.matrixColumns);
        const base = getRegisterDataPointer(regist) + MATRIX_HEADER_SIZE;
        var i: u32 = 0;
        while (i < count) : (i += 1) {
            readLine(tmpString);
            var imaginaryPart = text.skipWord(tmpString);
            imaginaryPart[0] = 0;
            imaginaryPart += 1;
            const elem = base + i * COMPLEX34_SIZE_IN_BYTES;
            _ = decQuadFromString(elem, tmpString, &ctxtReal34);
            _ = decQuadFromString(elem + REAL34_SIZE_IN_BYTES, imaginaryPart, &ctxtReal34);
        }
    }
}

pub fn skipMatrixData(type_str: [*c]u8, value_in: [*c]u8) void {
    if (strcmpEq(type_str, "Rema") or strcmpEq(type_str, "Cxma")) {
        var numOfCols = text.skipWord(value_in);
        numOfCols[0] = 0;
        numOfCols += 1;
        const rows = text.toUint16(value_in);
        const cols = text.toUint16(numOfCols);
        const count = @as(u32, rows) * @as(u32, cols);
        var i: u32 = 0;
        while (i < count) : (i += 1) readLine(tmpString);
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
    const base: [*c]u8 = @ptrCast(statisticalSumsPointer);
    _ = decNumberFromString(base + @as(usize, i) * REAL_SIZE_IN_BYTES, str, &ctxtReal75);
}
