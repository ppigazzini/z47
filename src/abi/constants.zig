// SPDX-License-Identifier: GPL-3.0-only
//
// Typed accessors into the generated `constants` blob. Owners previously
// reached the blob with a raw
// `@extern([*]const u8,"constants") + <magic offset>` then an unchecked
// `@ptrCast` (773 offset refs across the tree, the offset-crash class). Here the
// offset lives once, behind a named, typed accessor returning `*const Real`.
//
// The offsets are the post-pin-advance generateConstants layout (host + DMCP
// package 3, which share one blob layout; pinned by src/testSuite/tests/elec.txt
// and the pkg-3 build). These named accessors are hand-maintained here from
// constantPointers.h, seeded with the elec pilot's constants and grown per
// owner as the refactor rolls out.

const types = @import("primitives.zig");
const Real = types.Real;

const constants = @extern([*]const u8, .{ .name = "constants" });

inline fn at(comptime offset: u32) *const Real {
    return @ptrCast(@alignCast(constants + offset));
}

/// decQuad (Real34) constant at a blob byte offset (align 1, comptime-safe).
const Real34 = types.Real34;
inline fn at34(comptime offset: u32) *align(1) const Real34 {
    return @ptrCast(constants + offset);
}

/// Dynamic (runtime-offset) blob accessors; align 1 since the offset is not comptime.
pub inline fn cstR(offset: u32) *align(1) const Real {
    return @ptrCast(constants + offset);
}
pub inline fn cst34(offset: u32) *align(1) const Real34 {
    return @ptrCast(constants + offset);
}

/// Dynamic align-4 Real accessor (offset must be 4-aligned; asserted).
pub inline fn cstRAligned(offset: u32) *const Real {
    return @ptrCast(@alignCast(constants + offset));
}

// --- Seeded for the elec pilot (mathematics/elec.c) ---
pub inline fn const1on2() *const Real {
    return at(5168);
}
pub inline fn const3() *const Real {
    return at(12272);
}
pub inline fn root3on2() *const Real {
    return at(5552);
}
pub inline fn const1e_37() *const Real {
    return at(4776);
}

// --- math_gd ---
pub inline fn const39piOn2() *const Real {
    return at(12140);
}
pub inline fn const39piOn4() *const Real {
    return at(5516);
}
pub inline fn const__1() *const Real {
    return at(4704);
}
pub inline fn const_1() *const Real {
    return at(12116);
}
pub inline fn const_2() *const Real {
    return at(12188);
}
pub inline fn const_1on2() *const Real {
    return at(5168);
}
pub inline fn const_10() *const Real {
    return at(12392);
}
pub inline fn const_360() *const Real {
    return at(12704);
}
pub inline fn const_400() *const Real {
    return at(12716);
}
pub inline fn const1071_pi() *const Real {
    return at(17908);
}
pub inline fn const2139_2pi() *const Real {
    return at(18632);
}
pub inline fn const__4() *const Real {
    return at(4692);
}
pub inline fn const_1on4() *const Real {
    return at(5064);
}
pub inline fn const39_1on3() *const Real {
    return at(5088);
}
pub inline fn const39_pi() *const Real {
    return at(1848);
}
pub inline fn const39_piOn2() *const Real {
    return at(12140);
}
pub inline fn const39_piOn4() *const Real {
    return at(5516);
}
pub inline fn const39_root2on2() *const Real {
    return at(5480);
}
pub inline fn const75_2pi() *const Real {
    return at(15496);
}
pub inline fn const_1e_32() *const Real {
    return at(13084);
}
pub inline fn const_1e_37() *const Real {
    return at(4776);
}
pub inline fn const_1e_49() *const Real {
    return at(4764);
}
pub inline fn const__1Off() *const Real {
    return at(4704);
}
pub inline fn const_3Off() *const Real {
    return at(12272);
}
pub inline fn const_0() *const Real {
    return at(1708);
}
pub inline fn const_1on10() *const Real {
    return at(4968);
}
pub inline fn const_30() *const Real {
    return at(12464);
}
pub inline fn const_60() *const Real {
    return at(12644);
}
pub inline fn const_360000() *const Real {
    return at(12896);
}
pub inline fn const_100() *const Real {
    return at(15388);
}
pub inline fn const_3() *const Real {
    return at(12272);
}
pub inline fn const_4() *const Real {
    return at(12284);
}
pub inline fn const_5() *const Real {
    return at(12332);
}
pub inline fn const_6() *const Real {
    return at(12344);
}
pub inline fn const39_eE() *const Real {
    return at(176);
}
pub inline fn const_8() *const Real {
    return at(12368);
}
pub inline fn const_24() *const Real {
    return at(12428);
}
pub inline fn const_90() *const Real {
    return at(15400);
}
// Angular-mode quadrant bounds (wp34s.c reduceAngleToRange) and the tanh
// saturation threshold (WP34S_Tanh, where |x| > 47 already equals 1 to 39
// digits).
pub inline fn const_200() *const Real {
    return at(15304);
}
pub inline fn const_50() *const Real {
    return at(15472);
}
pub inline fn const_45() *const Real {
    return at(15484);
}
pub inline fn const_47() *const Real {
    return at(12584);
}
pub inline fn const75_piOn2() *const Real {
    return at(15328);
}
pub inline fn const39_gammaEM() *const Real {
    return at(1256);
}
pub inline fn const39_egamma() *const Real {
    return at(5180);
}
pub inline fn const_NaN() *const Real {
    return at(812);
}
pub inline fn const39_2pi() *const Real {
    return at(1812);
}
pub inline fn const39_ln2piOn2() *const Real {
    return at(5600);
}
pub inline fn const_12() *const Real {
    return at(12404);
}
pub inline fn const_1260() *const Real {
    return at(12756);
}
pub inline fn const_1680() *const Real {
    return at(12768);
}
pub inline fn const39_root3on2() *const Real {
    return at(5552);
}
pub inline fn const_9() *const Real {
    return at(12380);
}
pub inline fn const_54() *const Real {
    return at(12596);
}
pub inline fn const_2916() *const Real {
    return at(12780);
}
pub inline fn const_1e_6() *const Real {
    return at(4848);
}
pub inline fn const_1e_30() *const Real {
    return at(4800);
}
pub inline fn const_1e_34() *const Real {
    return at(4788);
}
pub inline fn const_1e_16() *const Real {
    return at(4824);
}
pub inline fn const39_ln10() *const Real {
    return at(12200);
}
pub inline fn const_7() *const Real {
    return at(12356);
}
pub inline fn const_1e_6143() *const Real {
    return at(13216);
}
pub inline fn const_86400() *const Real {
    return at(12884);
}
pub inline fn const34_43200() *align(1) const Real34 {
    return at34(29372);
}
pub inline fn const34_86400() *align(1) const Real34 {
    return at34(29404);
}
pub inline fn const34_2() *align(1) const Real34 {
    return at34(28924);
}
pub inline fn const34_28() *align(1) const Real34 {
    return at34(29084);
}
pub inline fn const34_400() *align(1) const Real34 {
    return at34(29212);
}
pub inline fn const34__4712() *align(1) const Real34 {
    return at34(28812);
}
pub inline fn const34_1() *align(1) const Real34 {
    return at34(28908);
}
pub inline fn const34_31() *align(1) const Real34 {
    return at34(29100);
}
pub inline fn const34_12() *align(1) const Real34 {
    return at34(29036);
}
pub inline fn const34_14() *align(1) const Real34 {
    return at34(29052);
}
pub inline fn const34_4800() *align(1) const Real34 {
    return at34(29308);
}
pub inline fn const34_1461() *align(1) const Real34 {
    return at34(29260);
}
pub inline fn const34_4() *align(1) const Real34 {
    return at34(28956);
}
pub inline fn const34_367() *align(1) const Real34 {
    return at34(29196);
}
pub inline fn const34_4900() *align(1) const Real34 {
    return at34(29324);
}
pub inline fn const34_100() *align(1) const Real34 {
    return at34(29148);
}
pub inline fn const34_3() *align(1) const Real34 {
    return at34(28940);
}
pub inline fn const34_9() *align(1) const Real34 {
    return at34(29004);
}
pub inline fn const34_7() *align(1) const Real34 {
    return at34(28988);
}
pub inline fn const34_5001() *align(1) const Real34 {
    return at34(29340);
}
pub inline fn const34_275() *align(1) const Real34 {
    return at34(29180);
}
pub inline fn const34_1729777() *align(1) const Real34 {
    return at34(29468);
}
pub inline fn const34_1401() *align(1) const Real34 {
    return at34(29244);
}
pub inline fn const34_274277() *align(1) const Real34 {
    return at34(29436);
}
pub inline fn const34_146097() *align(1) const Real34 {
    return at34(29420);
}
pub inline fn const34_38() *align(1) const Real34 {
    return at34(29116);
}
pub inline fn const34_153() *align(1) const Real34 {
    return at34(29164);
}
pub inline fn const34_5() *align(1) const Real34 {
    return at34(28972);
}
pub inline fn const34_4716() *align(1) const Real34 {
    return at34(29292);
}
pub inline fn const34_1on2() *align(1) const Real34 {
    return at34(28892);
}
pub inline fn const34_24() *align(1) const Real34 {
    return at34(29068);
}
pub inline fn const34_3600() *align(1) const Real34 {
    return at34(29276);
}
pub inline fn const34_60() *align(1) const Real34 {
    return at34(29132);
}
pub inline fn const34_maxDate() *align(1) const Real34 {
    return at34(29500);
}
pub inline fn const34_maxTime() *align(1) const Real34 {
    return at34(29516);
}
pub inline fn const34_1e6() *align(1) const Real34 {
    return at34(29452);
}
pub inline fn const34_1on10() *align(1) const Real34 {
    return at34(28876);
}
pub inline fn const34_32075() *align(1) const Real34 {
    return at34(29356);
}
pub inline fn const34_65535() *align(1) const Real34 {
    return at34(29388);
}
pub inline fn const_2p32() *const Real {
    return at(12924);
}
pub inline fn const34_2p32() *align(1) const Real34 {
    return at34(29484);
}
pub inline fn const12321_2pi() *const Real {
    return at(20068);
}
pub inline fn const_2p64() *const Real {
    return at(13036);
}
pub inline fn const34_1e_4() *align(1) const Real34 {
    return at34(28860);
}
pub inline fn const_2p63() *const Real {
    return at(13012);
}
pub inline fn const34_0() *align(1) const Real34 {
    return at34(28796);
}
pub inline fn const_3on2() *const Real {
    return at(12128);
}
pub inline fn const_9999() *const Real {
    return at(12844);
}
pub inline fn const39_ln2() *const Real {
    return at(5216);
}
pub inline fn q16200() *align(1) const Real34 {
    return at34(28796);
}
pub inline fn q16312() *align(1) const Real34 {
    return at34(28908);
}
pub inline fn c1848() *const Real {
    return at(1848);
}
pub inline fn c1684() *const Real {
    return at(1684);
}
pub inline fn c1696() *const Real {
    return at(1696);
}
pub inline fn q16264() *align(1) const Real34 {
    return at34(28860);
}
pub inline fn q16280() *align(1) const Real34 {
    return at34(28876);
}
pub inline fn q16296() *align(1) const Real34 {
    return at34(28892);
}
pub inline fn q16328() *align(1) const Real34 {
    return at34(28924);
}
pub inline fn q16344() *align(1) const Real34 {
    return at34(28940);
}
pub inline fn q16392() *align(1) const Real34 {
    return at34(28988);
}
pub inline fn q16408() *align(1) const Real34 {
    return at34(29004);
}
pub inline fn q16472() *align(1) const Real34 {
    return at34(29068);
}
pub inline fn c1708() *const Real {
    return at(1708);
}
pub inline fn c4376() *const Real {
    return at(4704);
}
pub inline fn c4436() *const Real {
    return at(4776);
}
pub inline fn c4520() *const Real {
    return at(4968);
}
pub inline fn c4580() *const Real {
    return at(5168);
}
pub inline fn c4856() *const Real {
    return at(12116);
}
pub inline fn c7532() *const Real {
    return at(15388);
}
pub inline fn c812() *const Real {
    return at(812);
}
pub inline fn q16568() *align(1) const Real34 {
    return at34(29164);
}
pub inline fn c4928() *const Real {
    return at(12188);
}
pub inline fn c4484() *const Real {
    return at(4824);
}
pub inline fn c5708() *const Real {
    return at(13084);
}
pub inline fn c5568() *const Real {
    return at(12944);
}
pub inline fn c4508() *const Real {
    return at(4848);
}
pub inline fn c4544() *const Real {
    return at(5088);
}
pub inline fn c5012() *const Real {
    return at(12272);
}
pub inline fn c4532() *const Real {
    return at(5064);
}
pub inline fn c5180() *const Real {
    return at(12452);
}
pub inline fn c7628() *const Real {
    return at(15484);
}
pub inline fn c5236() *const Real {
    return at(12584);
}
pub inline fn c7616() *const Real {
    return at(15472);
}
pub inline fn c7544() *const Real {
    return at(15400);
}
pub inline fn c7460() *const Real {
    return at(15316);
}
pub inline fn c7448() *const Real {
    return at(15304);
}
pub inline fn c5344() *const Real {
    return at(12692);
}
pub inline fn c5356() *const Real {
    return at(12704);
}
pub inline fn c5368() *const Real {
    return at(12716);
}
pub inline fn c5460() *const Real {
    return at(12808);
}
pub inline fn c5696() *const Real {
    return at(13072);
}
pub inline fn c5684() *const Real {
    return at(13060);
}
pub inline fn c4472() *const Real {
    return at(4812);
}
pub inline fn c4424() *const Real {
    return at(4764);
}
pub inline fn c5192() *const Real {
    return at(12540);
}
pub inline fn c1812() *const Real {
    return at(1812);
}
pub inline fn c4880() *const Real {
    return at(12140);
}
pub inline fn c4736() *const Real {
    return at(5516);
}
pub inline fn c4976() *const Real {
    return at(12236);
}
pub inline fn c4628() *const Real {
    return at(5216);
}
pub inline fn c4940() *const Real {
    return at(12200);
}
pub inline fn c4700() *const Real {
    return at(5480);
}
pub inline fn c4592() *const Real {
    return at(5180);
}
pub inline fn c176() *const Real {
    return at(176);
}
pub inline fn c7388() *const Real {
    return at(15244);
}
pub inline fn c7472() *const Real {
    return at(15328);
}
pub inline fn c7556() *const Real {
    return at(15412);
}
pub inline fn c7700() *const Real {
    return at(15616);
}
pub inline fn c9932() *const Real {
    return at(17908);
}
pub inline fn c9208() *const Real {
    return at(17184);
}
pub inline fn c8484() *const Real {
    return at(16460);
}
pub inline fn c7760() *const Real {
    return at(15736);
}
/// The incomplete gamma coefficient tables const39_igammaC0_00 .. const39_igammaC7_12:
/// eight tables of 31, 29, 27, 25, 23, 17, 15 and 13 entries, back to back in the
/// blob at REAL_SIZE_IN_BYTES(39) = 36 bytes each, table 0 first. igammaC39(table, k)
/// is entry k of table `table`.
pub inline fn const39_igammaC0_00() *const Real {
    return at(5636);
}
const igamma_table_start = [8]u32{ 0, 31, 60, 87, 112, 135, 152, 167 };
pub inline fn igammaC39(table: u32, k: u32) *align(1) const Real {
    return cstR(5636 + (igamma_table_start[table] + k) * 36);
}
pub inline fn const75_3piOn4() *const Real {
    return at(15616);
}
pub inline fn const_1e32() *const Real {
    return at(12944);
}
pub inline fn const75_gammaC00() *const Real {
    return at(13444);
}
/// The first of the 29 Lanczos coefficients const75_gammaC01..29, laid out back
/// to back at REAL_SIZE_IN_BYTES(75) = 60 bytes each; index with gammaC75(k).
pub inline fn const75_gammaC01() *const Real {
    return at(13504);
}
pub inline fn gammaC75(k: u32) *align(1) const Real {
    return cstR(13504 + k * 60);
}
pub inline fn c5308() *const Real {
    return at(12656);
}
pub inline fn c5260() *const Real {
    return at(12608);
}
pub inline fn c4808() *const Real {
    return at(5588);
}
pub inline fn c5296() *const Real {
    return at(12644);
}
pub inline fn c5448() *const Real {
    return at(12796);
}
pub inline fn c5828() *const Real {
    return at(13204);
}
pub inline fn c2628() *const Real {
    return at(2636);
}
pub inline fn c2048() *const Real {
    return at(2048);
}
pub inline fn c2648() *const Real {
    return at(2656);
}
pub inline fn q16552() *align(1) const Real34 {
    return at34(29148);
}
pub inline fn q16632() *align(1) const Real34 {
    return at34(29228);
}

// --- atan table path (mathematics/wp34s.c WP34S_Atan_table_compute) ---
pub inline fn const39_1on7() *const Real {
    return at(5016);
}
pub inline fn const39_1on9() *const Real {
    return at(4980);
}
pub inline fn const39_1on11() *const Real {
    return at(4932);
}
pub inline fn const39_1on13() *const Real {
    return at(4896);
}
pub inline fn const39_1on15() *const Real {
    return at(4860);
}
pub inline fn const_1on5() *const Real {
    return at(5052);
}
pub inline fn const39_atan1on10() *const Real {
    return at(28292);
}
pub inline fn const39_atan2on10() *const Real {
    return at(28328);
}
pub inline fn const39_atan3on10() *const Real {
    return at(28364);
}
pub inline fn const39_atan4on10() *const Real {
    return at(28400);
}
pub inline fn const39_atan5on10() *const Real {
    return at(28436);
}
pub inline fn const39_atan6on10() *const Real {
    return at(28472);
}
pub inline fn const39_atan7on10() *const Real {
    return at(28508);
}
pub inline fn const39_atan8on10() *const Real {
    return at(28544);
}
pub inline fn const39_atan9on10() *const Real {
    return at(28580);
}
pub inline fn const39_atanP08() *const Real {
    return at(28616);
}
pub inline fn const39_atanP09() *const Real {
    return at(28652);
}
pub inline fn const39_atanP10() *const Real {
    return at(28688);
}
pub inline fn const39_atanP11() *const Real {
    return at(28724);
}
pub inline fn const39_atanP12() *const Real {
    return at(28760);
}
