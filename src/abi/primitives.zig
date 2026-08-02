// SPDX-License-Identifier: GPL-3.0-only
//
// The primitive ABI types: the `extern`/`packed struct` layout mirrors of the pinned
// C that the rest of `abi/` is declared in terms of. A LEAF -- it imports nothing.
//
// WHY IT EXISTS. `types.zig` is the module root: it re-exports `constants`,
// `registers` and `runtime` as namespaces, so those three imported IT to reach the
// handful of types they are built out of. That made `abi/` a four-file import cycle
// -- in the one layer 41% of the tree imports, and the layer that must be the
// acyclic bottom of the graph. The siblings import this leaf instead, and the cycle
// has no edge left to close through.
//
// The contents are not a matter of taste. This is the transitive closure the
// compiler needs to resolve the types the siblings name, computed by adding what it
// asked for until it stopped asking -- no more, no less. Every declaration mirrors a
// C layout byte-for-byte, so `zig build abi-layout-parity` is the arbiter for any
// change to this file.

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

/// String / long-integer data header (strLgIntHeader_t).
pub const StrLgIntHeader = extern struct {
    dataMaxLengthInBlocks: u16,
    unused: u16,
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
