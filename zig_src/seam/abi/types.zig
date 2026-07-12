// SPDX-License-Identifier: GPL-3.0-only
//
// Shared ABI types. Single source of truth for the
// C numeric layouts the owners previously each hand-mirrored (36 owners defined
// their own `const real_t = extern struct {...}`; this centralizes that one copy
// and pins the layout at comptime so a toolchain/pin change is caught here rather
// than silently corrupting decNumber during a live computation).
//
// These mirror src/c47 (decNumber.h `decNumber`, decQuad `real34_t`,
// decContext `realContext_t`). The layout is proven by the parity oracles that
// already pass against the pinned upstream C; the asserts below pin the Zig side
// of that contract. This file is hand-maintained and comptime-asserted against
// the pinned upstream headers.

const std = @import("std");

/// decNumber real_t: DECNUMDIGITS-backed decimal. DECNUMUNITS = 25 (7*DECDPUN..).
pub const DECNUMUNITS = 25;
pub const Real = extern struct {
    digits: i32,
    exponent: i32,
    bits: u8,
    lsu: [DECNUMUNITS]u16,
};

/// decQuad-backed 34-digit real (16 raw bytes).
pub const Real34 = extern struct { bytes: [16]u8 };

/// Byte-compatible opaque view of `Real` for owners that only pass it to C as a
/// handle (zero-init + &x) and never read fields. Same size/align as `Real`, so
/// it is a drop-in for the `{ bytes: [60]u8 align(4) }` owners the migration
/// task converts.
pub const RealBlob = extern struct { bytes: [60]u8 align(4) };

/// 159-digit decNumber storage (upstream `REAL_T_PTR(name, 159)`): the same
/// decNumber header as `Real` but a 53-unit lsu, so `REAL_SIZE_IN_BYTES(159) ==
/// 116`. The math owners (cubic / eigen 159-digit internal paths) stack-allocate
/// one and view it as a `real_t`; `ptr`/`constPtr` provide that view. Centralized
/// here to replace the three identical per-owner re-mirrors.
pub const Real159 = extern struct {
    digits: i32,
    exponent: i32,
    bits: u8,
    lsu: [53]u16,

    pub inline fn ptr(self: *Real159) *Real {
        return @ptrCast(self);
    }
    pub inline fn constPtr(self: *const Real159) *const Real {
        return @ptrCast(self);
    }
};

/// decContext.
pub const RealContext = extern struct {
    digits: i32,
    emax: i32,
    emin: i32,
    round: c_int,
    traps: u32,
    status: u32,
    clamp: u8,
};

/// A complex value as a pair of `Real` (the C `CPLX(x)` passes &x.Real, &x.Imag).
pub const Complex = extern struct { Real: Real, Imag: Real };

/// decQuad complex (two Real34).
pub const Complex34 = extern struct { real: Real34, imag: Real34 };

/// A complex pair with lower-case r/i fields (cmplxPair), distinct from Complex's
/// {Real, Imag} spelling used by the solver/addons owners.
pub const CmplxPair = extern struct { r: Real, i: Real };

/// Subroutine-level header (run-time stack frame).
pub const SubroutineLevelHeader = extern struct {
    returnProgramNumber: i16,
    returnLocalStep: u16,
    numberOfLocalFlags: u8,
    numberOfLocalRegisters: u8,
    subroutineLevel: u16,
    ptrToNextLevel: u16,
    ptrToPreviousLevel: u16,
};

/// Keyboard key descriptor (keyboard.h calcKey_t), all i16 slots.
pub const CalcKey = extern struct {
    keyId: i16,
    primary: i16,
    fShifted: i16,
    gShifted: i16,
    keyLblAim: i16,
    primaryAim: i16,
    fShiftedAim: i16,
    gShiftedAim: i16,
    primaryTam: i16,
};

/// Soft-menu descriptor (softmenu_t): item indices + pointer to the key list.
pub const Softmenu = extern struct {
    menuItem: i16,
    numItems: i16,
    softkeyItem: [*c]const i16,
};

/// Catalog item descriptor (item.h item_t).
pub const Item = extern struct {
    func: ?*const fn (u16) callconv(.c) void,
    param: u16,
    itemCatalogName: [16]u8,
    itemSoftmenuName: [16]u8,
    tamMinMax: u16,
    status: u16,
};

/// Register-header bitfield (registerHeader_t named struct, typeDefinitions.h):
/// the 32-bit descriptor decoded into its C fields.
pub const RegisterHeaderBits = packed struct(u32) {
    pointerToRegisterData: u16,
    dataType: u4,
    tag: u5,
    readOnly: u1,
    notUsed: u6,
};

/// Register header (registerHeader_t, typeDefinitions.h): a C union of the raw
/// 32-bit `descriptor` and the decoded `bits`. Opaque owners read `.descriptor`;
/// owners that need the fields read `.bits.pointerToRegisterData` etc.
pub const RegisterHeader = extern union {
    descriptor: u32,
    bits: RegisterHeaderBits,
};

/// Matrix header (matrixHeader_t, typeDefinitions.h): a 32-bit C bitfield
/// {matrixRows:12, matrixColumns:12, mtag:6, notUsed:2}. The little-endian
/// packed-struct layout matches the C bitfield (proven by the owners already
/// using this exact shape). Fields are read directly (`h.matrixRows`); owners
/// that had `{bits:u32}` + rows()/cols() accessors are converted to field access.
pub const MatrixHeader = packed struct(u32) {
    matrixRows: u12,
    matrixColumns: u12,
    mtag: u6,
    notUsed: u2,
};

/// Named-variable header (namedVariableHeader_t).
pub const NamedVariableHeader = extern struct {
    header: RegisterHeader,
    variableName: [16]u8,
};

/// Reserved-variable header (reservedVariableHeader_t).
pub const ReservedVariableHeader = extern struct {
    header: RegisterHeader,
    reservedVariableName: [8]u8,
};

/// Soft-menu stack entry (softmenuStack_t, typeDefinitions.h): 8 bytes, align 2.
/// The C ground truth is {softmenuId, firstItem, userMenuId, calcMode}; an
/// earlier stale fork ({softmenuJumpToItem, softmenuUserSize, softmenuScrollDelta})
/// only ever zero-inited the storage, so this reconciles to the pinned-C names.
pub const SoftmenuStack = extern struct {
    softmenuId: i16,
    firstItem: i16,
    userMenuId: i16,
    calcMode: u8,
};

/// User-menu item (userMenuItem_t).
pub const UserMenuItem = extern struct {
    item: i16,
    unused: i16,
    argumentName: [16]u8,
};

/// User menu (userMenu_t): name + 18 items.
pub const UserMenu = extern struct {
    menuName: [16]u8,
    menuItem: [18]UserMenuItem,
};

/// TAM-mode state (tamState_t, typeDefinitions.h): 26 bytes, align 2. The C
/// bool_t members are `bool` (1 byte); the owners that had forked these to `u8`
/// (int-style `!= 0` / `= 1`) are converted to bool idiom at their access sites.
pub const TamState = extern struct {
    mode: u16,
    function: i16,
    alpha: bool,
    currentOperation: i16,
    dot: bool,
    colon: bool,
    indirect: bool,
    digitsSoFar: i16,
    value0: i16,
    value: i16,
    min: i16,
    max: i16,
    key: i16,
    keyAlpha: bool,
    keyDot: bool,
    keyIndirect: bool,
    keyInputFinished: bool,
};

/// Real34 matrix (real34Matrix_t, typeDefinitions.h): {matrixHeader_t header;
/// real34_t *matrixElements}. The element pointer is a nullable multi-item
/// pointer (owners index it and null-check it); this is the idiomatic spelling of
/// the C `real34_t *` and lets the [*c] forks drop their C-pointer.
pub const Real34Matrix = extern struct {
    header: MatrixHeader,
    matrixElements: ?[*]Real34,
};

/// Complex34 matrix (complex34Matrix_t): {matrixHeader_t header;
/// complex34_t *matrixElements}.
pub const Complex34Matrix = extern struct {
    header: MatrixHeader,
    matrixElements: ?[*]Complex34,
};

/// Config descriptor (dtConfigDescriptor_t): the full config-serialization
/// record; body extracted verbatim from the owners (sub-types mapped to abi).
pub const DtConfigDescriptor = extern struct {
    shortIntegerMode: u8,
    shortIntegerWordSize: u8,
    displayFormat: u8,
    displayFormatDigits: u8,
    gapItemLeft: u16,
    gapItemRight: u16,
    gapItemRadix: u16,
    grpGroupingLeft: u8,
    grpGroupingGr1LeftOverflow: u8,
    grpGroupingGr1Left: u8,
    grpGroupingRight: u8,
    currentAngularMode: c_int,
    lrSelection: u16,
    lrChosen: u16,
    denMax: u32,
    displayStack: u8,
    firstGregorianDay: u32,
    roundingMode: u8,
    systemFlags0: u64,
    systemFlags1: u64,
    kbd_usr: [37]CalcKey,
    compatibility_byte1: u8,
    compatibility_byte19: bool,
    compatibility_byte27: bool,
    compatibility_byte29: bool,
    compatibility_byte21: bool,
    compatibility_byte30: bool,
    compatibility_byte00: bool,
    compatibility_int1: i16,
    Input_Default: u8,
    dispBase: bool,
    compatibility_byte31: bool,
    compatibility_byte26: bool,
    compatibility_float1: f32,
    compatibility_float2: f32,
    Norm_Key_00: NormKey,
    compatibility_byte2: bool,
    compatibility_byte3: bool,
    compatibility_byte4: bool,
    compatibility_byte5: bool,
    compatibility_byte6: bool,
    compatibility_byte7: bool,
    compatibility_byte8: bool,
    compatibility_byte9: bool,
    compatibility_byte10: bool,
    compatibility_byte11: bool,
    compatibility_byte12: bool,
    compatibility_byte13: bool,
    compatibility_byte14: bool,
    compatibility_byte15: bool,
    fractionDigits: i8,
    compatibility_byte23: i8,
    compatibility_byte16: bool,
    compatibility_byte20: bool,
    compatibility_byte17: bool,
    IrFractionsCurrentStatus: u8,
    compatibility_byte18: bool,
    displayStackSHOIDISP: u8,
    compatibility_byte25: bool,
    compatibility_byte24: bool,
    bcdDisplaySign: u8,
    DRG_Cycling: u8,
    DM_Cycling: u8,
    compatibility_byte22: bool,
    LongPressM: u8,
    LongPressF: u8,
    lastDenominator: u32,
    significantDigits: u8,
    pcg32_global: Pcg32Random,
    exponentLimit: i16,
    exponentHideLimit: i16,
    lastIntegerBase: u32,
    compatibility_byte28: bool,
    timeDisplayFormatDigits: u8,
    reservedForPossibleFutureUse: [6]u8,
};

/// Any-matrix union (any34Matrix_t, typeDefinitions.h): overlays the shared
/// header with the real and complex matrix views.
pub const Any34Matrix = extern union {
    header: MatrixHeader,
    realMatrix: Real34Matrix,
    complexMatrix: Complex34Matrix,
};

/// Printer state (printerState_t, typeDefinitions.h): 16 bytes, align 4. The C
/// print_modes_t/printerModel_t are int-backed enums (c_int); the owners had
/// forked the enum fields between c_int/u32/enum-alias and the bool fields
/// between bool/u8 -- all byte-identical, reconciled to the C-faithful shape.
pub const PrinterState = extern struct {
    print_on: bool,
    trace_done: bool,
    print_blank_line: u8,
    print_mode: c_int,
    printer_model: c_int,
    delay: u16,
};

/// Dynamic soft-menu descriptor (dynamicSoftmenu_t): item counts + content ptr.
pub const DynamicSoftmenu = extern struct {
    menuItem: i16,
    numItems: i16,
    menuContent: [*c]u8,
};

/// Formula header (formulaHeader_t): data pointer + block size.
pub const FormulaHeader = extern struct {
    pointerToFormulaData: u16,
    sizeInBlocks: u8,
    unused: u8,
};

/// Font glyph (glyph_t, typeDefinitions.h): 24 bytes, align 8. The `_pad:[8]u8`
/// owner is an opaque view over the rank1/rank2 (+trailing pad) bytes.
pub const Glyph = extern struct {
    charCode: u16,
    colsBeforeGlyph: u8,
    colsGlyph: u8,
    colsAfterGlyph: u8,
    rowsAboveGlyph: u8,
    rowsGlyph: u8,
    rowsBelowGlyph: u8,
    rank1: i16,
    rank2: i16,
    data: [*c]u8,
};

/// Font description (font_t, typeDefinitions.h): id + count + flexible glyph
/// array (the `id:u16` owner is a misspelling of the C `int8_t id`).
pub const Font = extern struct {
    id: i8,
    numberOfGlyphs: u16,
    glyphs: [0]Glyph,
    /// glyphs[] begins at offset 8 (the [0]Glyph align-8 field). Single-source
    /// accessor so every owner's font_t == abi.Font.
    pub inline fn glyphsPtr(self: *const Font) [*]const Glyph {
        return @ptrCast(&self.glyphs);
    }
};

/// Programmable-menu descriptor (programmableMenu_t): 332 bytes, align 2.
pub const ProgrammableMenu = extern struct {
    itemName: [18][16]u8,
    itemParam: [21]u16,
    unused: u16,
};

/// Subroutine-levels header (subroutineLevels_t, typeDefinitions.h): 4 bytes.
pub const SubroutineLevels = extern struct {
    numberOfSubroutineLevels: u16,
    ptrToSubroutineLevel0Header: u16,
};

/// Free-memory region (freeMemoryRegion_t): block address + size, 4 bytes.
pub const FreeMemoryRegion = extern struct {
    blockAddress: u16,
    sizeInBlocks: u16,
};

/// Broken-down calendar time (libc-style tm / Tm): 9 c_int fields.
pub const Tm = extern struct {
    sec: c_int,
    min: c_int,
    hour: c_int,
    mday: c_int,
    mon: c_int,
    year: c_int,
    wday: c_int,
    yday: c_int,
    isdst: c_int,
};

/// Confirmation temporary-info entry (confirmationTI_t).
pub const ConfirmationTI = extern struct {
    item: i16,
    string: [30]u8,
};

/// Function-in-MIM descriptor (fInMim_t).
pub const FInMim = extern struct {
    itemNr: u16,
};

/// Martel-printer glyph (glyphMartelPrinter_t): char + 48-byte bitmap.
pub const GlyphMartelPrinter = extern struct {
    charCode: u16,
    data: [48]u8,
};

/// Printer glyph (glyphPrinter_t): char + 5-byte bitmap.
pub const GlyphPrinter = extern struct {
    charCode: u16,
    data: [5]u8,
};

/// String / long-integer data header (strLgIntHeader_t).
pub const StrLgIntHeader = extern struct {
    dataMaxLengthInBlocks: u16,
    unused: u16,
};

/// Short date (dt_t): year/month/day.
pub const DateShort = extern struct {
    year: u16,
    month: u8,
    day: u8,
};

/// Short time (tm_t): hour/min/sec/csec + day-of-week.
pub const TimeShort = extern struct {
    hour: u8,
    min: u8,
    sec: u8,
    csec: u8,
    dow: u8,
};

/// Program-label entry (labelList_t, typeDefinitions.h): id/step + two C byte
/// pointers into program memory (indexed and pointer-arithmetic'd, so [*c]).
pub const LabelList = extern struct {
    program: i16,
    step: i32,
    labelPointer: [*c]u8,
    instructionPointer: [*c]u8,
};

/// Program entry (programList_t, typeDefinitions.h): begin step + instruction ptr.
pub const ProgramList = extern struct {
    step: i32,
    instructionPointer: [*c]u8,
};

/// Norm-key descriptor (normKey_t, typeDefinitions.h): 20 bytes, align 2.
pub const NormKey = extern struct {
    func: i16,
    funcParam: [16]u8,
    used: bool,
};

/// PCG32 RNG state (pcg32_random_t, pcg_basic.h): 16 bytes, align 8.
pub const Pcg32Random = extern struct {
    state: u64,
    inc: u64,
};

/// GMP limb: pointer-width on every z47 target (usize, NOT c_ulong which is
/// 32-bit on Win64 -- see math_command_wrappers_runtime).
pub const MpLimb = usize;

/// GMP mpz_t element (mpz_struct, gmp.h __mpz_struct): {_mp_alloc, _mp_size,
/// _mp_d}. Field names carry the GMP underscore prefix and _mp_d is the limb
/// pointer owners index directly; [*c] is the faithful GMP ABI spelling.
pub const Mpz = extern struct {
    _mp_alloc: c_int,
    _mp_size: c_int,
    _mp_d: [*c]MpLimb,
};

/// Item-name alias (nameAlias_t): item id + display name.
pub const NameAlias = extern struct {
    item: u16,
    name: [16]u8,
};

/// Summation-register name (summationRegisterName_t): 16-byte name.
pub const SummationRegisterName = extern struct {
    name: [16]u8,
};

/// Reserved-variable descriptor string (reservedVariableDescStr_t): 28 bytes.
pub const ReservedVariableDescStr = extern struct {
    Desc: [28]u8,
};

/// Lettered-flag display entry (letteredFlagDisplay_t): 4-char text + position.
pub const LetteredFlagDisplay = extern struct {
    txt: [4]u8,
    position: u32,
};

/// Upper/lower case pair (upperLower_t): two 3-byte UTF-8 glyphs.
pub const UpperLower = extern struct {
    upper: [3]u8,
    lower: [3]u8,
};

/// GTK keyboard geometry (calcKeyboard_t): key rectangles + widget handles. The
/// C `keyImage` members are `GtkWidget *`; modelled as opaque pointers so this
/// shared ABI layer stays GTK-free while keeping the exact pointer layout.
pub const CalcKeyboard = extern struct {
    x: c_int,
    y: c_int,
    width: [4]c_int,
    height: [4]c_int,
    keyImage: [4]?*anyopaque,
};

/// Local-flags word (localFlags_t): the C typedef is a bare `uint32_t`.
pub const LocalFlags = u32;

/// Typed constant-blob accessors (L1), reached as `abi.constants.const1on2()`.
pub const constants = @import("constants.zig");

/// Typed C-runtime wrappers (L1), reached as `abi.runtime.add(&a, &b, &r)`.
pub const runtime = @import("runtime.zig");

// decNumber bit flags (realType.h), shared by the owners that inspect `Real.bits`.
pub const DECNEG: u8 = 0x80;
pub const DECINF: u8 = 0x40;
pub const DECNAN: u8 = 0x20;
pub const DECSNAN: u8 = 0x10;
pub const DECSPECIAL: u8 = DECINF | DECNAN | DECSNAN;

comptime {
    // Pin the Zig layout of the C-shared types. A mismatch here is a build error,
    // not a silent runtime reinterpretation.
    std.debug.assert(@offsetOf(Real, "digits") == 0);
    std.debug.assert(@offsetOf(Real, "exponent") == 4);
    std.debug.assert(@offsetOf(Real, "bits") == 8);
    std.debug.assert(@offsetOf(Real, "lsu") == 10);
    std.debug.assert(@sizeOf(Real) == 60);
    std.debug.assert(@sizeOf(Real159) == 116);
    std.debug.assert(@sizeOf(Real34) == 16);
    std.debug.assert(@sizeOf(Complex) == 2 * @sizeOf(Real));
    std.debug.assert(@sizeOf(Complex34) == 32);
    std.debug.assert(@sizeOf(SubroutineLevelHeader) == 12);
    std.debug.assert(@sizeOf(CalcKey) == 18);
    std.debug.assert(@offsetOf(Softmenu, "numItems") == 2);
    std.debug.assert(@sizeOf(SoftmenuStack) == 8);
    std.debug.assert(@alignOf(SoftmenuStack) == 2);
    std.debug.assert(@offsetOf(SoftmenuStack, "firstItem") == 2);
    std.debug.assert(@offsetOf(SoftmenuStack, "userMenuId") == 4);
    std.debug.assert(@offsetOf(SoftmenuStack, "calcMode") == 6);
    std.debug.assert(@sizeOf(TamState) == 28);
    std.debug.assert(@alignOf(TamState) == 2);
    std.debug.assert(@offsetOf(TamState, "alpha") == 4);
    std.debug.assert(@offsetOf(TamState, "digitsSoFar") == 12);
    std.debug.assert(@offsetOf(TamState, "keyInputFinished") == 27);
    std.debug.assert(@sizeOf(Pcg32Random) == 16);
    std.debug.assert(@offsetOf(Pcg32Random, "inc") == 8);
    std.debug.assert(@sizeOf(RegisterHeader) == 4);
    std.debug.assert(@alignOf(RegisterHeader) == 4);
    std.debug.assert(@bitOffsetOf(RegisterHeaderBits, "dataType") == 16);
    std.debug.assert(@bitOffsetOf(RegisterHeaderBits, "readOnly") == 25);
    std.debug.assert(@sizeOf(PrinterState) == 16);
    std.debug.assert(@alignOf(PrinterState) == 4);
    std.debug.assert(@offsetOf(PrinterState, "print_mode") == 4);
    std.debug.assert(@offsetOf(PrinterState, "printer_model") == 8);
    std.debug.assert(@offsetOf(PrinterState, "delay") == 12);
    std.debug.assert(@sizeOf(MatrixHeader) == 4);
    std.debug.assert(@bitOffsetOf(MatrixHeader, "matrixColumns") == 12);
    std.debug.assert(@bitOffsetOf(MatrixHeader, "mtag") == 24);
}

// Colocated hermetic tests -- run by `zig build idiom-test`.
// These assert the ABI contract the C parity oracle cannot express directly.
const testing = std.testing;

test "Real matches the C decNumber ABI (size/offsets)" {
    try testing.expectEqual(@as(usize, 60), @sizeOf(Real));
    try testing.expectEqual(@as(usize, 4), @alignOf(Real));
    try testing.expectEqual(@as(usize, 0), @offsetOf(Real, "digits"));
    try testing.expectEqual(@as(usize, 10), @offsetOf(Real, "lsu"));
}

test "Complex is two back-to-back Reals" {
    try testing.expectEqual(@sizeOf(Real), @offsetOf(Complex, "Imag"));
    try testing.expectEqual(2 * @sizeOf(Real), @sizeOf(Complex));
}

test "RealBlob is a drop-in for Real (same size and align)" {
    try testing.expectEqual(@sizeOf(Real), @sizeOf(RealBlob));
    try testing.expectEqual(@alignOf(Real), @alignOf(RealBlob));
}

test "decNumber special-flag mask is INF|NAN|SNAN" {
    try testing.expectEqual(@as(u8, DECINF | DECNAN | DECSNAN), DECSPECIAL);
}

// ===========================================================================
// Typed register-data accessors: the extern binding of
// getRegisterDataPointer lives in the approved boundary file abi/registers.zig
// so this pure-layout file stays extern-free (check-zig-c-boundaries); the
// accessors are re-exported here so owners reach them as abi.registerReal34(...).
pub const registers = @import("registers.zig");
pub const registerReal34 = registers.registerReal34;
pub const registerImag34 = registers.registerImag34;
pub const registerComplex34 = registers.registerComplex34;
pub const registerShortInteger = registers.registerShortInteger;
pub const registerString = registers.registerString;
pub const registerBytes = registers.registerBytes;
pub const registerConfig = registers.registerConfig;
pub const registerMatrixHeader = registers.registerMatrixHeader;
pub const registerReal34Aligned = registers.registerReal34Aligned;
pub const registerImag34Aligned = registers.registerImag34Aligned;
pub const registerComplex34Aligned = registers.registerComplex34Aligned;
pub const registerMatrixHeaderAligned = registers.registerMatrixHeaderAligned;
pub const registerShortIntegerAligned = registers.registerShortIntegerAligned;
pub const registerReal34MatrixElements = registers.registerReal34MatrixElements;
pub const registerComplex34MatrixElements = registers.registerComplex34MatrixElements;
pub const matrixRealElems = registers.matrixRealElems;
pub const matrixConstRealElems = registers.matrixConstRealElems;
pub const matrixComplexElems = registers.matrixComplexElems;
pub const matrixConstComplexElems = registers.matrixConstComplexElems;

/// Format `args` into `buf` with a trailing NUL, like C `sprintf`/`snprintf`.
/// Built on the stable `std.fmt.bufPrint` -- NOT `bufPrintZ`, which Zig
/// 0.17-dev removed -- so the migrated call sites survive a toolchain bump and a
/// future std.fmt change is absorbed in this single place. `buf` must fit the
/// output (proven per call site by the format-equivalence oracle over a bounded
/// scratch buffer), matching the C sprintf "caller guarantees the size" contract.
pub fn fmtBufZ(buf: []u8, comptime fmt: []const u8, args: anytype) void {
    const written = std.fmt.bufPrint(buf[0 .. buf.len - 1], fmt, args) catch unreachable;
    buf[written.len] = 0;
}

/// Like fmtBufZ but for a raw C `[*c]u8` destination whose backing size is not
/// known at the call site (a caller-provided display/scratch buffer, or a moving
/// write pointer like the save-file writer). Formats into a local staging buffer
/// and copies exactly content+NUL to `dst` -- byte-identical to what
/// `sprintf(dst, fmt, args)` would write, so it honours the same "caller
/// guarantees the buffer is big enough" contract as the C it replaces. The 512B
/// stage covers every display/label/save-line these sites produce (asserted).
pub fn fmtCStr(dst: [*c]u8, comptime fmt: []const u8, args: anytype) void {
    var stage: [512]u8 = undefined;
    const s = std.fmt.bufPrint(&stage, fmt, args) catch unreachable;
    @memcpy(dst[0..s.len], s);
    dst[s.len] = 0;
}

/// Like fmtCStr but returns the number of bytes written (excluding the NUL),
/// matching C `sprintf`'s return value -- for a moving write pointer that the
/// caller advances by the length (e.g. the clipboard/CSV stream writers).
pub fn fmtCStrN(dst: [*c]u8, comptime fmt: []const u8, args: anytype) usize {
    var stage: [512]u8 = undefined;
    const s = std.fmt.bufPrint(&stage, fmt, args) catch unreachable;
    @memcpy(dst[0..s.len], s);
    dst[s.len] = 0;
    return s.len;
}

// ---------------------------------------------------------------------------
// Byte-exact C `%.<precision>e` float formatter. Lives in a
// std-only, extern-free sibling so the format oracle can import and prove the
// EXACT shipping code byte-identical to libc `%.Pe`. See abi/float_format.zig.
const float_format = @import("float_format.zig");
pub const fmtExpBuf = float_format.fmtExpBuf;
pub const fmtFixedBuf = float_format.fmtFixedBuf;
pub const fmtGBuf = float_format.fmtGBuf;

// Shared std-only pure integer primitives (gcd, isqrt, mod-exp, ...). Reachable
// as `abi.int_math.*` from any owner; unit-tested under `zig build test:unit`.
pub const int_math = @import("int_math.zig");

// Shared std-only byte<->allocation-block arithmetic (round bytes up to whole
// 4-byte blocks / multiply back). Reachable as `abi.block_math.*`; state memory
// owners and frontier PC-memory owners delegate here.
pub const block_math = @import("block_math.zig");

// Shared std-only WP34S short-integer *mode* arithmetic (value/overflow decisions
// under unsigned / 1's- / 2's-complement / sign-magnitude). Reachable as
// `abi.shortint_arith.*`; frontier_integers delegates its WP34S_int* cores here.
pub const shortint_arith = @import("shortint_arith.zig");

// Shared std-only WP34S/C47 double->string display formatting (the calculator's
// fixed-15-digit sci form + sign/separator normalization). Reachable as
// `abi.sci_format.*`; the register-value converters delegate their buffer work here.
pub const sci_format = @import("sci_format.zig");

// Shared std-only glyph char-code helpers (1-or-2-byte decode, super/subscript/
// struck folding for CMP_NAME ordering, compareChar lead difference). Reachable as
// `abi.glyph_code.*`; frontier_sort delegates its compareChar/compareString cores.
pub const glyph_code = @import("glyph_code.zig");

// Shared std-only complex-number text normalization ("(3-i4)"/"+3+i4"/"i4"/stock
// "re im" -> stock "re im"). Reachable as `abi.complex_text.*`; the state restore
// codec delegates standardiseComplex here.
pub const complex_text = @import("complex_text.zig");

// Shared std-only PCG32 generator kernels (state advance, output permutation,
// bounded rejection sampling). Reachable as `abi.pcg32.*`; the math random owner
// threads its global rng state through these and keeps the real_t producer.
pub const pcg32 = @import("pcg32.zig");

// Shared std-only C47 glyph-string navigation + UTF-8 codec (glyph count/next/prev/
// last, numeric-template validation, code-point<->UTF-8). Reachable as
// `abi.c47_string.*`; frontier_char_string delegates its stringFuncs primitives here.
pub const c47_string = @import("c47_string.zig");

/// Byte-exact C `%.<precision>e` written to a raw C pointer + trailing NUL, like
/// `sprintf(dst, "%.Pe", value)`. The [*c] dest wrappers live here (beside
/// fmtCStr) so float_format.zig stays extern- and [*c]-free for the oracle.
pub fn fmtExpC(dst: [*c]u8, precision: usize, value: f64) void {
    var stage: [512]u8 = undefined;
    const s = float_format.fmtExpBuf(&stage, precision, value);
    @memcpy(dst[0..s.len], s);
    dst[s.len] = 0;
}

/// Byte-exact C `%<width>.<P>g/G` written to a raw C pointer + trailing NUL.
pub fn fmtGC(dst: [*c]u8, width: usize, precision: usize, upper: bool, value: f64) void {
    var stage: [512]u8 = undefined;
    const s = float_format.fmtGBuf(&stage, width, precision, upper, value);
    @memcpy(dst[0..s.len], s);
    dst[s.len] = 0;
}
