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
const CONFIG_DESCRIPTOR_SIZE: usize = 840; // sizeof(dtConfigDescriptor_t)

// 32-bit bitfield: rows:12, columns:12, mtag:6, notUsed:2.
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
    std.debug.assert(@sizeOf(MpzStruct) == 16);
}

extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcat(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strlen(s: [*c]const u8) usize;
extern fn sprintf(str: [*c]u8, format: [*c]const u8, ...) c_int;
extern fn stringToUtf8(str: [*c]const u8, utf8: [*c]u8) void;

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

fn configToSaveString(regist: i16) void {
    const trs = regValueBuf();
    const cfg: [*c]u8 = getRegisterDataPointer(regist);
    var i: usize = 0;
    while (i < CONFIG_DESCRIPTOR_SIZE) : (i += 1) {
        _ = sprintf(trs + i * 2, "%02X", @as(c_uint, cfg[i]));
    }
    _ = strcpy(aim(), "Conf");
}
