// SPDX-License-Identifier: GPL-3.0-only
//
// Typed accessors into the generated `constants` blob. Each offset lives once,
// behind a named, typed accessor returning `*const Real`, so no owner reaches the
// blob with a raw `@extern` plus a magic offset and an unchecked pointer
// reinterpretation (the offset-crash class).
//
// The offsets are the generateConstants layout (host + DMCP package 3, which
// share one blob layout; pinned by src/testSuite/tests/elec.txt and the pkg-3
// build). These named accessors are hand-maintained here from
// constantPointers.h.

const std = @import("std");
const types = @import("primitives.zig");
const Real = types.Real;
const Real34 = types.Real34;

/// The generated `constants` blob, read in the 4-byte words its C definition is
/// aligned to (`__attribute__((aligned(4)))` in constantPointers.c).
const constants = @extern([*]const u32, .{ .name = "constants" });

/// The `T` stored at a blob byte offset. Every offset generateConstants emits is
/// a multiple of 4, so the view is word-aligned whether the offset is known at
/// compile time or not.
inline fn blobValue(comptime T: type, offset: u32) *const T {
    comptime std.debug.assert(@sizeOf(T) % 4 == 0);
    std.debug.assert(offset % 4 == 0);
    const words = constants[offset / 4 ..][0 .. @sizeOf(T) / 4];
    return std.mem.bytesAsValue(T, std.mem.sliceAsBytes(words)[0..@sizeOf(T)]);
}

inline fn at(comptime offset: u32) *const Real {
    return blobValue(Real, offset);
}

/// decQuad (Real34) constant at a blob byte offset.
inline fn at34(comptime offset: u32) *const Real34 {
    return blobValue(Real34, offset);
}

/// Runtime-offset blob accessors, for the tables that index the blob.
pub fn cstR(offset: u32) *const Real {
    return blobValue(Real, offset);
}
pub fn cst34(offset: u32) *const Real34 {
    return blobValue(Real34, offset);
}
pub const cstRAligned = cstR;

// --- Seeded for the elec pilot (mathematics/elec.c) ---
pub fn const1on2() *const Real {
    return at(5168);
}
pub fn const3() *const Real {
    return at(12272);
}
pub fn root3on2() *const Real {
    return at(5552);
}
pub fn const1e_37() *const Real {
    return at(4776);
}

// --- math_gd ---
pub fn const39piOn2() *const Real {
    return at(12140);
}
pub fn const39piOn4() *const Real {
    return at(5516);
}
pub fn const__1() *const Real {
    return at(4704);
}
pub fn const_1() *const Real {
    return at(12116);
}
pub fn const_2() *const Real {
    return at(12188);
}
pub fn const_1on2() *const Real {
    return at(5168);
}
pub fn const_10() *const Real {
    return at(12392);
}
pub fn const_360() *const Real {
    return at(12704);
}
pub fn const_400() *const Real {
    return at(12716);
}
pub fn const1071_pi() *const Real {
    return at(17908);
}
pub fn const2139_2pi() *const Real {
    return at(18632);
}
pub fn const__4() *const Real {
    return at(4692);
}
pub fn const_1on4() *const Real {
    return at(5064);
}
pub fn const39_1on3() *const Real {
    return at(5088);
}
pub fn const39_pi() *const Real {
    return at(1848);
}
pub fn const39_piOn2() *const Real {
    return at(12140);
}
pub fn const39_piOn4() *const Real {
    return at(5516);
}
pub fn const39_root2on2() *const Real {
    return at(5480);
}
pub fn const75_2pi() *const Real {
    return at(15496);
}
pub fn const_1e_32() *const Real {
    return at(13084);
}
pub fn const_1e_37() *const Real {
    return at(4776);
}
pub fn const_1e_49() *const Real {
    return at(4764);
}
pub fn const__1Off() *const Real {
    return at(4704);
}
pub fn const_3Off() *const Real {
    return at(12272);
}
pub fn const_0() *const Real {
    return at(1708);
}
pub fn const_1on10() *const Real {
    return at(4968);
}
pub fn const_30() *const Real {
    return at(12464);
}
pub fn const_60() *const Real {
    return at(12644);
}
pub fn const_360000() *const Real {
    return at(12896);
}
pub fn const_100() *const Real {
    return at(15388);
}
pub fn const_3() *const Real {
    return at(12272);
}
pub fn const_4() *const Real {
    return at(12284);
}
pub fn const_5() *const Real {
    return at(12332);
}
pub fn const_6() *const Real {
    return at(12344);
}
pub fn const39_eE() *const Real {
    return at(176);
}
pub fn const_8() *const Real {
    return at(12368);
}
pub fn const_24() *const Real {
    return at(12428);
}
pub fn const_90() *const Real {
    return at(15400);
}
// Angular-mode quadrant bounds (wp34s.c reduceAngleToRange) and the tanh
// saturation threshold (WP34S_Tanh, where |x| > 47 already equals 1 to 39
// digits).
pub fn const_200() *const Real {
    return at(15304);
}
pub fn const_50() *const Real {
    return at(15472);
}
pub fn const_45() *const Real {
    return at(15484);
}
pub fn const_47() *const Real {
    return at(12584);
}
pub fn const75_piOn2() *const Real {
    return at(15328);
}
pub fn const39_gammaEM() *const Real {
    return at(1256);
}
pub fn const39_egamma() *const Real {
    return at(5180);
}
pub fn const_NaN() *const Real {
    return at(812);
}
pub fn const39_2pi() *const Real {
    return at(1812);
}
pub fn const39_ln2piOn2() *const Real {
    return at(5600);
}
pub fn const_12() *const Real {
    return at(12404);
}
pub fn const_1260() *const Real {
    return at(12756);
}
pub fn const_1680() *const Real {
    return at(12768);
}
pub fn const39_root3on2() *const Real {
    return at(5552);
}
pub fn const_9() *const Real {
    return at(12380);
}
pub fn const_54() *const Real {
    return at(12596);
}
pub fn const_2916() *const Real {
    return at(12780);
}
pub fn const_1e_6() *const Real {
    return at(4848);
}
pub fn const_1e_30() *const Real {
    return at(4800);
}
pub fn const_1e_34() *const Real {
    return at(4788);
}
pub fn const_1e_16() *const Real {
    return at(4824);
}
pub fn const39_ln10() *const Real {
    return at(12200);
}
pub fn const_7() *const Real {
    return at(12356);
}
pub fn const_1e_6143() *const Real {
    return at(13216);
}
pub fn const_86400() *const Real {
    return at(12884);
}
pub fn const34_43200() *const Real34 {
    return at34(29372);
}
pub fn const34_86400() *const Real34 {
    return at34(29404);
}
pub fn const34_2() *const Real34 {
    return at34(28924);
}
pub fn const34_28() *const Real34 {
    return at34(29084);
}
pub fn const34_400() *const Real34 {
    return at34(29212);
}
pub fn const34__4712() *const Real34 {
    return at34(28812);
}
pub fn const34_1() *const Real34 {
    return at34(28908);
}
pub fn const34_31() *const Real34 {
    return at34(29100);
}
pub fn const34_12() *const Real34 {
    return at34(29036);
}
pub fn const34_14() *const Real34 {
    return at34(29052);
}
pub fn const34_4800() *const Real34 {
    return at34(29308);
}
pub fn const34_1461() *const Real34 {
    return at34(29260);
}
pub fn const34_4() *const Real34 {
    return at34(28956);
}
pub fn const34_367() *const Real34 {
    return at34(29196);
}
pub fn const34_4900() *const Real34 {
    return at34(29324);
}
pub fn const34_100() *const Real34 {
    return at34(29148);
}
pub fn const34_3() *const Real34 {
    return at34(28940);
}
pub fn const34_9() *const Real34 {
    return at34(29004);
}
pub fn const34_7() *const Real34 {
    return at34(28988);
}
pub fn const34_5001() *const Real34 {
    return at34(29340);
}
pub fn const34_275() *const Real34 {
    return at34(29180);
}
pub fn const34_1729777() *const Real34 {
    return at34(29468);
}
pub fn const34_1401() *const Real34 {
    return at34(29244);
}
pub fn const34_274277() *const Real34 {
    return at34(29436);
}
pub fn const34_146097() *const Real34 {
    return at34(29420);
}
pub fn const34_38() *const Real34 {
    return at34(29116);
}
pub fn const34_153() *const Real34 {
    return at34(29164);
}
pub fn const34_5() *const Real34 {
    return at34(28972);
}
pub fn const34_4716() *const Real34 {
    return at34(29292);
}
pub fn const34_1on2() *const Real34 {
    return at34(28892);
}
pub fn const34_24() *const Real34 {
    return at34(29068);
}
pub fn const34_3600() *const Real34 {
    return at34(29276);
}
pub fn const34_60() *const Real34 {
    return at34(29132);
}
pub fn const34_maxDate() *const Real34 {
    return at34(29500);
}
pub fn const34_maxTime() *const Real34 {
    return at34(29516);
}
pub fn const34_1e6() *const Real34 {
    return at34(29452);
}
pub fn const34_1on10() *const Real34 {
    return at34(28876);
}
pub fn const34_32075() *const Real34 {
    return at34(29356);
}
pub fn const34_65535() *const Real34 {
    return at34(29388);
}
pub fn const_2p32() *const Real {
    return at(12924);
}
pub fn const34_2p32() *const Real34 {
    return at34(29484);
}
pub fn const12321_2pi() *const Real {
    return at(20068);
}
pub fn const_2p64() *const Real {
    return at(13036);
}
pub fn const34_1e_4() *const Real34 {
    return at34(28860);
}
pub fn const_2p63() *const Real {
    return at(13012);
}
pub fn const34_0() *const Real34 {
    return at34(28796);
}
pub fn const_3on2() *const Real {
    return at(12128);
}
pub fn const_9999() *const Real {
    return at(12844);
}
pub fn const39_ln2() *const Real {
    return at(5216);
}
pub fn q16200() *const Real34 {
    return at34(28796);
}
pub fn q16312() *const Real34 {
    return at34(28908);
}
pub fn c1848() *const Real {
    return at(1848);
}
pub fn c1684() *const Real {
    return at(1684);
}
pub fn c1696() *const Real {
    return at(1696);
}
pub fn q16264() *const Real34 {
    return at34(28860);
}
pub fn q16280() *const Real34 {
    return at34(28876);
}
pub fn q16296() *const Real34 {
    return at34(28892);
}
pub fn q16328() *const Real34 {
    return at34(28924);
}
pub fn q16344() *const Real34 {
    return at34(28940);
}
pub fn q16392() *const Real34 {
    return at34(28988);
}
pub fn q16408() *const Real34 {
    return at34(29004);
}
pub fn q16472() *const Real34 {
    return at34(29068);
}
pub fn c1708() *const Real {
    return at(1708);
}
pub fn c4376() *const Real {
    return at(4704);
}
pub fn c4436() *const Real {
    return at(4776);
}
pub fn c4520() *const Real {
    return at(4968);
}
pub fn c4580() *const Real {
    return at(5168);
}
pub fn c4856() *const Real {
    return at(12116);
}
pub fn c7532() *const Real {
    return at(15388);
}
pub fn c812() *const Real {
    return at(812);
}
pub fn q16568() *const Real34 {
    return at34(29164);
}
pub fn c4928() *const Real {
    return at(12188);
}
pub fn c4484() *const Real {
    return at(4824);
}
pub fn c5708() *const Real {
    return at(13084);
}
pub fn c5568() *const Real {
    return at(12944);
}
pub fn c4508() *const Real {
    return at(4848);
}
pub fn c4544() *const Real {
    return at(5088);
}
pub fn c5012() *const Real {
    return at(12272);
}
pub fn c4532() *const Real {
    return at(5064);
}
pub fn c5180() *const Real {
    return at(12452);
}
pub fn c7628() *const Real {
    return at(15484);
}
pub fn c5236() *const Real {
    return at(12584);
}
pub fn c7616() *const Real {
    return at(15472);
}
pub fn c7544() *const Real {
    return at(15400);
}
pub fn c7460() *const Real {
    return at(15316);
}
pub fn c7448() *const Real {
    return at(15304);
}
pub fn c5344() *const Real {
    return at(12692);
}
pub fn c5356() *const Real {
    return at(12704);
}
pub fn c5368() *const Real {
    return at(12716);
}
pub fn c5460() *const Real {
    return at(12808);
}
pub fn c5696() *const Real {
    return at(13072);
}
pub fn c5684() *const Real {
    return at(13060);
}
pub fn c4472() *const Real {
    return at(4812);
}
pub fn c4424() *const Real {
    return at(4764);
}
pub fn c5192() *const Real {
    return at(12540);
}
pub fn c1812() *const Real {
    return at(1812);
}
pub fn c4880() *const Real {
    return at(12140);
}
pub fn c4736() *const Real {
    return at(5516);
}
pub fn c4976() *const Real {
    return at(12236);
}
pub fn c4628() *const Real {
    return at(5216);
}
pub fn c4940() *const Real {
    return at(12200);
}
pub fn c4700() *const Real {
    return at(5480);
}
pub fn c4592() *const Real {
    return at(5180);
}
pub fn c176() *const Real {
    return at(176);
}
pub fn c7388() *const Real {
    return at(15244);
}
pub fn c7472() *const Real {
    return at(15328);
}
pub fn c7556() *const Real {
    return at(15412);
}
pub fn c7700() *const Real {
    return at(15616);
}
pub fn c9932() *const Real {
    return at(17908);
}
pub fn c9208() *const Real {
    return at(17184);
}
pub fn c8484() *const Real {
    return at(16460);
}
pub fn c7760() *const Real {
    return at(15736);
}
/// The incomplete gamma coefficient tables const39_igammaC0_00 .. const39_igammaC7_12:
/// eight tables of 31, 29, 27, 25, 23, 17, 15 and 13 entries, back to back in the
/// blob at REAL_SIZE_IN_BYTES(39) = 36 bytes each, table 0 first. igammaC39(table, k)
/// is entry k of table `table`.
pub fn const39_igammaC0_00() *const Real {
    return at(5636);
}
const igamma_table_start = [8]u32{ 0, 31, 60, 87, 112, 135, 152, 167 };
pub fn igammaC39(table: u32, k: u32) *const Real {
    return cstR(5636 + (igamma_table_start[table] + k) * 36);
}
pub fn const75_pi() *const Real {
    return at(15244);
}
pub fn const51_1on3() *const Real {
    return at(5124);
}
pub fn const51_7zeta2SqOn5() *const Real {
    return at(5340);
}
pub fn const51_twoLn2() *const Real {
    return at(5252);
}
pub fn const51_zeta2() *const Real {
    return at(5296);
}
pub fn const75_ln10() *const Real {
    return at(15556);
}
pub fn const75_ln2() *const Real {
    return at(5384);
}
pub fn const75_piOn4() *const Real {
    return at(15412);
}
pub fn const_1000() *const Real {
    return at(12728);
}
pub fn const_10000() *const Real {
    return at(12860);
}
pub fn const_180() *const Real {
    return at(15316);
}
pub fn const_1e_10000() *const Real {
    return at(13060);
}
pub fn const_1e_12() *const Real {
    return at(4836);
}
pub fn const_1e_71() *const Real {
    return at(4752);
}
pub fn const_205() *const Real {
    return at(12692);
}
pub fn const_28() *const Real {
    return at(12440);
}
pub fn const_29() *const Real {
    return at(12452);
}
pub fn const_3on4() *const Real {
    return at(5076);
}
pub fn const__gammaRm1() *const Real {
    return at(12476);
}
pub fn const_gammaR() *const Real {
    return at(12540);
}
pub fn const_gammaRm1() *const Real {
    return at(12508);
}
pub fn const_plusInfinity() *const Real {
    return at(1696);
}
pub fn const75_egamma() *const Real {
    return at(15676);
}
pub fn const39_root2() *const Real {
    return at(5444);
}
pub fn const_1on40000() *const Real {
    return at(12872);
}
pub fn const_459p67() *const Real {
    return at(4188);
}
pub fn const_9on5() *const Real {
    return at(12176);
}
pub fn const39_3piOn4() *const Real {
    return at(12236);
}
pub fn const_10p9__1() *const Real {
    return at(12976);
}
pub fn const75_3piOn4() *const Real {
    return at(15616);
}
pub fn const_1e32() *const Real {
    return at(12944);
}
pub fn const75_gammaC00() *const Real {
    return at(13444);
}
/// The first of the 29 Lanczos coefficients const75_gammaC01..29, laid out back
/// to back at REAL_SIZE_IN_BYTES(75) = 60 bytes each; index with gammaC75(k).
pub fn const75_gammaC01() *const Real {
    return at(13504);
}
pub fn gammaC75(k: u32) *const Real {
    return cstR(13504 + k * 60);
}
pub fn c5308() *const Real {
    return at(12656);
}
pub fn c5260() *const Real {
    return at(12608);
}
pub fn c4808() *const Real {
    return at(5588);
}
pub fn c5296() *const Real {
    return at(12644);
}
pub fn c5448() *const Real {
    return at(12796);
}
pub fn c5828() *const Real {
    return at(13204);
}
pub fn c2628() *const Real {
    return at(2636);
}
pub fn c2048() *const Real {
    return at(2048);
}
pub fn c2648() *const Real {
    return at(2656);
}
pub fn q16552() *const Real34 {
    return at34(29148);
}
pub fn q16632() *const Real34 {
    return at34(29228);
}

// --- atan table path (mathematics/wp34s.c WP34S_Atan_table_compute) ---
pub fn const39_1on7() *const Real {
    return at(5016);
}
pub fn const39_1on9() *const Real {
    return at(4980);
}
pub fn const39_1on11() *const Real {
    return at(4932);
}
pub fn const39_1on13() *const Real {
    return at(4896);
}
pub fn const39_1on15() *const Real {
    return at(4860);
}
pub fn const_1on5() *const Real {
    return at(5052);
}
pub fn const39_atan1on10() *const Real {
    return at(28292);
}
pub fn const39_atan2on10() *const Real {
    return at(28328);
}
pub fn const39_atan3on10() *const Real {
    return at(28364);
}
pub fn const39_atan4on10() *const Real {
    return at(28400);
}
pub fn const39_atan5on10() *const Real {
    return at(28436);
}
pub fn const39_atan6on10() *const Real {
    return at(28472);
}
pub fn const39_atan7on10() *const Real {
    return at(28508);
}
pub fn const39_atan8on10() *const Real {
    return at(28544);
}
pub fn const39_atan9on10() *const Real {
    return at(28580);
}
pub fn const39_atanP08() *const Real {
    return at(28616);
}
pub fn const39_atanP09() *const Real {
    return at(28652);
}
pub fn const39_atanP10() *const Real {
    return at(28688);
}
pub fn const39_atanP11() *const Real {
    return at(28724);
}
pub fn const39_atanP12() *const Real {
    return at(28760);
}
