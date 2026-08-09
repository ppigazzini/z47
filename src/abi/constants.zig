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
    return at(4836);
}
pub inline fn const3() *const Real {
    return at(5268);
}
pub inline fn root3on2() *const Real {
    return at(5028);
}
pub inline fn const1e_37() *const Real {
    return at(4692);
}

// --- math_gd ---
pub inline fn const39piOn2() *const Real {
    return at(5136);
}
pub inline fn const39piOn4() *const Real {
    return at(4992);
}
pub inline fn const__1() *const Real {
    return at(4632);
}
pub inline fn const_1() *const Real {
    return at(5112);
}
pub inline fn const_2() *const Real {
    return at(5184);
}
pub inline fn const_1on2() *const Real {
    return at(4836);
}
pub inline fn const_10() *const Real {
    return at(5388);
}
pub inline fn const_360() *const Real {
    return at(5612);
}
pub inline fn const_400() *const Real {
    return at(5624);
}
pub inline fn const1071_pi() *const Real {
    return at(10188);
}
pub inline fn const2139_2pi() *const Real {
    return at(10912);
}
pub inline fn const__4() *const Real {
    return at(4620);
}
pub inline fn const_1on4() *const Real {
    return at(4788);
}
pub inline fn const39_1on3() *const Real {
    return at(4800);
}
pub inline fn const39_pi() *const Real {
    return at(1848);
}
pub inline fn const39_piOn2() *const Real {
    return at(5136);
}
pub inline fn const39_piOn4() *const Real {
    return at(4992);
}
pub inline fn const39_root2on2() *const Real {
    return at(4956);
}
pub inline fn const75_2pi() *const Real {
    return at(7896);
}
pub inline fn const_1e_32() *const Real {
    return at(5964);
}
pub inline fn const_1e_37() *const Real {
    return at(4692);
}
pub inline fn const_1e_49() *const Real {
    return at(4680);
}
pub inline fn const__1Off() *const Real {
    return at(4632);
}
pub inline fn const_3Off() *const Real {
    return at(5268);
}
pub inline fn const_0() *const Real {
    return at(1708);
}
pub inline fn const_1on10() *const Real {
    return at(4776);
}
pub inline fn const_60() *const Real {
    return at(5552);
}
pub inline fn const_100() *const Real {
    return at(7788);
}
pub inline fn const_3() *const Real {
    return at(5268);
}
pub inline fn const_4() *const Real {
    return at(5280);
}
pub inline fn const_5() *const Real {
    return at(5328);
}
pub inline fn const_6() *const Real {
    return at(5340);
}
pub inline fn const39_eE() *const Real {
    return at(176);
}
pub inline fn const_8() *const Real {
    return at(5364);
}
pub inline fn const_24() *const Real {
    return at(5424);
}
pub inline fn const_90() *const Real {
    return at(7800);
}
pub inline fn const75_piOn2() *const Real {
    return at(7728);
}
pub inline fn const39_gammaEM() *const Real {
    return at(1256);
}
pub inline fn const39_egamma() *const Real {
    return at(4848);
}
pub inline fn const_NaN() *const Real {
    return at(812);
}
pub inline fn const39_2pi() *const Real {
    return at(1812);
}
pub inline fn const39_ln2piOn2() *const Real {
    return at(5076);
}
pub inline fn const_12() *const Real {
    return at(5400);
}
pub inline fn const_1260() *const Real {
    return at(5664);
}
pub inline fn const_1680() *const Real {
    return at(5676);
}
pub inline fn const39_root3on2() *const Real {
    return at(5028);
}
pub inline fn const_9() *const Real {
    return at(5376);
}
pub inline fn const_54() *const Real {
    return at(5504);
}
pub inline fn const_2916() *const Real {
    return at(5688);
}
pub inline fn const_1e_6() *const Real {
    return at(4764);
}
pub inline fn const_1e_30() *const Real {
    return at(4716);
}
pub inline fn const_1e_34() *const Real {
    return at(4704);
}
pub inline fn const_1e_16() *const Real {
    return at(4740);
}
pub inline fn const39_ln10() *const Real {
    return at(5196);
}
pub inline fn const_7() *const Real {
    return at(5352);
}
pub inline fn const_1e_6143() *const Real {
    return at(6096);
}
pub inline fn const_86400() *const Real {
    return at(5780);
}
pub inline fn const34_43200() *align(1) const Real34 {
    return at34(17032);
}
pub inline fn const34_86400() *align(1) const Real34 {
    return at34(17064);
}
pub inline fn const34_2() *align(1) const Real34 {
    return at34(16584);
}
pub inline fn const34_28() *align(1) const Real34 {
    return at34(16744);
}
pub inline fn const34_400() *align(1) const Real34 {
    return at34(16872);
}
pub inline fn const34__4712() *align(1) const Real34 {
    return at34(16472);
}
pub inline fn const34_1() *align(1) const Real34 {
    return at34(16568);
}
pub inline fn const34_31() *align(1) const Real34 {
    return at34(16760);
}
pub inline fn const34_12() *align(1) const Real34 {
    return at34(16696);
}
pub inline fn const34_14() *align(1) const Real34 {
    return at34(16712);
}
pub inline fn const34_4800() *align(1) const Real34 {
    return at34(16968);
}
pub inline fn const34_1461() *align(1) const Real34 {
    return at34(16920);
}
pub inline fn const34_4() *align(1) const Real34 {
    return at34(16616);
}
pub inline fn const34_367() *align(1) const Real34 {
    return at34(16856);
}
pub inline fn const34_4900() *align(1) const Real34 {
    return at34(16984);
}
pub inline fn const34_100() *align(1) const Real34 {
    return at34(16808);
}
pub inline fn const34_3() *align(1) const Real34 {
    return at34(16600);
}
pub inline fn const34_9() *align(1) const Real34 {
    return at34(16664);
}
pub inline fn const34_7() *align(1) const Real34 {
    return at34(16648);
}
pub inline fn const34_5001() *align(1) const Real34 {
    return at34(17000);
}
pub inline fn const34_275() *align(1) const Real34 {
    return at34(16840);
}
pub inline fn const34_1729777() *align(1) const Real34 {
    return at34(17128);
}
pub inline fn const34_1401() *align(1) const Real34 {
    return at34(16904);
}
pub inline fn const34_274277() *align(1) const Real34 {
    return at34(17096);
}
pub inline fn const34_146097() *align(1) const Real34 {
    return at34(17080);
}
pub inline fn const34_38() *align(1) const Real34 {
    return at34(16776);
}
pub inline fn const34_153() *align(1) const Real34 {
    return at34(16824);
}
pub inline fn const34_5() *align(1) const Real34 {
    return at34(16632);
}
pub inline fn const34_4716() *align(1) const Real34 {
    return at34(16952);
}
pub inline fn const34_1on2() *align(1) const Real34 {
    return at34(16552);
}
pub inline fn const34_24() *align(1) const Real34 {
    return at34(16728);
}
pub inline fn const34_3600() *align(1) const Real34 {
    return at34(16936);
}
pub inline fn const34_60() *align(1) const Real34 {
    return at34(16792);
}
pub inline fn const34_maxDate() *align(1) const Real34 {
    return at34(17160);
}
pub inline fn const34_maxTime() *align(1) const Real34 {
    return at34(17176);
}
pub inline fn const34_1e6() *align(1) const Real34 {
    return at34(17112);
}
pub inline fn const34_1on10() *align(1) const Real34 {
    return at34(16536);
}
pub inline fn const34_32075() *align(1) const Real34 {
    return at34(17016);
}
pub inline fn const34_65535() *align(1) const Real34 {
    return at34(17048);
}
pub inline fn const_2p32() *const Real {
    return at(5804);
}
pub inline fn const34_2p32() *align(1) const Real34 {
    return at34(17144);
}
pub inline fn const6147_2pi() *const Real {
    return at(12348);
}
pub inline fn const_2p64() *const Real {
    return at(5916);
}
pub inline fn const34_1e_4() *align(1) const Real34 {
    return at34(16520);
}
pub inline fn const_2p63() *const Real {
    return at(5892);
}
pub inline fn const34_0() *align(1) const Real34 {
    return at34(16456);
}
pub inline fn const_3on2() *const Real {
    return at(5124);
}
pub inline fn const_9999() *const Real {
    return at(5752);
}
pub inline fn const39_ln2() *const Real {
    return at(4884);
}
pub inline fn q16200() *align(1) const Real34 {
    return at34(16456);
}
pub inline fn q16312() *align(1) const Real34 {
    return at34(16568);
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
    return at34(16520);
}
pub inline fn q16280() *align(1) const Real34 {
    return at34(16536);
}
pub inline fn q16296() *align(1) const Real34 {
    return at34(16552);
}
pub inline fn q16328() *align(1) const Real34 {
    return at34(16584);
}
pub inline fn q16344() *align(1) const Real34 {
    return at34(16600);
}
pub inline fn q16392() *align(1) const Real34 {
    return at34(16648);
}
pub inline fn q16408() *align(1) const Real34 {
    return at34(16664);
}
pub inline fn q16472() *align(1) const Real34 {
    return at34(16728);
}
pub inline fn c1708() *const Real {
    return at(1708);
}
pub inline fn c4376() *const Real {
    return at(4632);
}
pub inline fn c4436() *const Real {
    return at(4692);
}
pub inline fn c4520() *const Real {
    return at(4776);
}
pub inline fn c4580() *const Real {
    return at(4836);
}
pub inline fn c4856() *const Real {
    return at(5112);
}
pub inline fn c7532() *const Real {
    return at(7788);
}
pub inline fn c812() *const Real {
    return at(812);
}
pub inline fn q16568() *align(1) const Real34 {
    return at34(16824);
}
pub inline fn c4928() *const Real {
    return at(5184);
}
pub inline fn c4484() *const Real {
    return at(4740);
}
pub inline fn c5708() *const Real {
    return at(5964);
}
pub inline fn c5568() *const Real {
    return at(5824);
}
pub inline fn c4508() *const Real {
    return at(4764);
}
pub inline fn c4544() *const Real {
    return at(4800);
}
pub inline fn c5012() *const Real {
    return at(5268);
}
pub inline fn c4532() *const Real {
    return at(4788);
}
pub inline fn c5180() *const Real {
    return at(5436);
}
pub inline fn c7628() *const Real {
    return at(7884);
}
pub inline fn c5236() *const Real {
    return at(5492);
}
pub inline fn c7616() *const Real {
    return at(7872);
}
pub inline fn c7544() *const Real {
    return at(7800);
}
pub inline fn c7460() *const Real {
    return at(7716);
}
pub inline fn c7448() *const Real {
    return at(7704);
}
pub inline fn c5344() *const Real {
    return at(5600);
}
pub inline fn c5356() *const Real {
    return at(5612);
}
pub inline fn c5368() *const Real {
    return at(5624);
}
pub inline fn c5460() *const Real {
    return at(5716);
}
pub inline fn c5696() *const Real {
    return at(5952);
}
pub inline fn c5684() *const Real {
    return at(5940);
}
pub inline fn c4472() *const Real {
    return at(4728);
}
pub inline fn c4424() *const Real {
    return at(4680);
}
pub inline fn c5192() *const Real {
    return at(5448);
}
pub inline fn c1812() *const Real {
    return at(1812);
}
pub inline fn c4880() *const Real {
    return at(5136);
}
pub inline fn c4736() *const Real {
    return at(4992);
}
pub inline fn c4976() *const Real {
    return at(5232);
}
pub inline fn c4628() *const Real {
    return at(4884);
}
pub inline fn c4940() *const Real {
    return at(5196);
}
pub inline fn c4700() *const Real {
    return at(4956);
}
pub inline fn c4592() *const Real {
    return at(4848);
}
pub inline fn c176() *const Real {
    return at(176);
}
pub inline fn c7388() *const Real {
    return at(7644);
}
pub inline fn c7472() *const Real {
    return at(7728);
}
pub inline fn c7556() *const Real {
    return at(7812);
}
pub inline fn c7700() *const Real {
    return at(7956);
}
pub inline fn c9932() *const Real {
    return at(10188);
}
pub inline fn c9208() *const Real {
    return at(9464);
}
pub inline fn c8484() *const Real {
    return at(8740);
}
pub inline fn c7760() *const Real {
    return at(8016);
}
pub inline fn c6068() *const Real {
    return at(6324);
}
pub inline fn c12092() *const Real {
    return at(12348);
}
pub inline fn c5308() *const Real {
    return at(5564);
}
pub inline fn c5260() *const Real {
    return at(5516);
}
pub inline fn c4808() *const Real {
    return at(5064);
}
pub inline fn c5296() *const Real {
    return at(5552);
}
pub inline fn c5448() *const Real {
    return at(5704);
}
pub inline fn c5828() *const Real {
    return at(6084);
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
    return at34(16808);
}
pub inline fn q16632() *align(1) const Real34 {
    return at34(16888);
}
