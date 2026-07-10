// SPDX-License-Identifier: GPL-3.0-only
//
// Pure unit-conversion pair table + lookup predicates, lifted from
// frontier_conversion_units.zig (src/c47/conversionUnits.c). The table pairs each
// convertible item with its partner, unity step, decimal exponent, and unit type;
// findPair binary-searches it (the table is sorted by item) and the predicates
// answer partner / is-conversion / same-configurable-type / standard-pair /
// one-of-a-pair questions. All of it is scalar-in / value-or-out-pointer-out with
// no register, dec, GTK, or global coupling, so it lives here as a std-only module
// exercised natively under `zig build test:unit`, reachable as
// frontier/conversion_pairs.zig. The owner keeps its pub-export C-ABI wrappers and
// its runConversion* side effects (which call findPair here) and delegates.
//
// testSuite-covered transitively via src/testSuite/tests/unitConversion.txt (the
// CONV menu paths exercise conversionPartner/isStandardPair); the native tests
// below are the first DIRECT coverage of the predicates. Transcription is verbatim
// (raw integer literals -- no ITM_*/UT_* symbol coupling in the rows).

const std = @import("std");

pub const NUM_CONVERT_PAIRS = 318;

pub const ConvPair = struct {
    item: i16,
    partner: i16,
    unity: i16,
    exponent: i8,
    type: u8,
};

const UT_NOT_CONFIGURABLE: u8 = 0;

const convert_pairs = [NUM_CONVERT_PAIRS]ConvPair{
    .{ .item = 220, .partner = 221, .unity = 2673, .exponent = 0, .type = 6 },
    .{ .item = 221, .partner = 220, .unity = 2665, .exponent = 0, .type = 6 },
    .{ .item = 222, .partner = 228, .unity = 0, .exponent = 0, .type = 0 },
    .{ .item = 223, .partner = 224, .unity = 0, .exponent = 4, .type = 2 },
    .{ .item = 224, .partner = 223, .unity = 226, .exponent = 0, .type = 2 },
    .{ .item = 225, .partner = 231, .unity = 0, .exponent = 0, .type = 0 },
    .{ .item = 226, .partner = 227, .unity = 0, .exponent = 0, .type = 2 },
    .{ .item = 227, .partner = 226, .unity = 226, .exponent = 0, .type = 2 },
    .{ .item = 228, .partner = 222, .unity = 0, .exponent = 0, .type = 0 },
    .{ .item = 229, .partner = 230, .unity = 0, .exponent = 6, .type = 2 },
    .{ .item = 230, .partner = 229, .unity = 0, .exponent = 4, .type = 2 },
    .{ .item = 231, .partner = 225, .unity = 0, .exponent = 0, .type = 0 },
    .{ .item = 232, .partner = 233, .unity = 266, .exponent = -3, .type = 3 },
    .{ .item = 233, .partner = 232, .unity = 274, .exponent = 0, .type = 3 },
    .{ .item = 234, .partner = 236, .unity = 0, .exponent = 4, .type = 2 },
    .{ .item = 235, .partner = 237, .unity = 237, .exponent = -3, .type = 3 },
    .{ .item = 236, .partner = 234, .unity = 234, .exponent = 4, .type = 2 },
    .{ .item = 237, .partner = 235, .unity = 0, .exponent = -3, .type = 3 },
    .{ .item = 238, .partner = 240, .unity = 0, .exponent = 4, .type = 2 },
    .{ .item = 239, .partner = 241, .unity = 274, .exponent = 0, .type = 3 },
    .{ .item = 240, .partner = 238, .unity = 238, .exponent = 4, .type = 2 },
    .{ .item = 241, .partner = 239, .unity = 255, .exponent = 0, .type = 3 },
    .{ .item = 242, .partner = 243, .unity = 243, .exponent = 0, .type = 7 },
    .{ .item = 243, .partner = 242, .unity = 0, .exponent = 0, .type = 7 },
    .{ .item = 244, .partner = 245, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 245, .partner = 244, .unity = 244, .exponent = 0, .type = 1 },
    .{ .item = 246, .partner = 247, .unity = 0, .exponent = 0, .type = 7 },
    .{ .item = 247, .partner = 246, .unity = 246, .exponent = 0, .type = 7 },
    .{ .item = 248, .partner = 249, .unity = 0, .exponent = 0, .type = 8 },
    .{ .item = 249, .partner = 248, .unity = 248, .exponent = 0, .type = 8 },
    .{ .item = 250, .partner = 251, .unity = 0, .exponent = 0, .type = 8 },
    .{ .item = 251, .partner = 250, .unity = 250, .exponent = 0, .type = 8 },
    .{ .item = 252, .partner = 254, .unity = 0, .exponent = 0, .type = 11 },
    .{ .item = 253, .partner = 255, .unity = 255, .exponent = 0, .type = 3 },
    .{ .item = 254, .partner = 252, .unity = 252, .exponent = 0, .type = 11 },
    .{ .item = 255, .partner = 253, .unity = 0, .exponent = 0, .type = 3 },
    .{ .item = 256, .partner = 257, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 257, .partner = 256, .unity = 256, .exponent = 0, .type = 4 },
    .{ .item = 258, .partner = 259, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 259, .partner = 258, .unity = 258, .exponent = 0, .type = 1 },
    .{ .item = 260, .partner = 263, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 261, .partner = 262, .unity = 262, .exponent = 0, .type = 3 },
    .{ .item = 262, .partner = 261, .unity = 0, .exponent = 0, .type = 3 },
    .{ .item = 263, .partner = 260, .unity = 260, .exponent = 0, .type = 1 },
    .{ .item = 264, .partner = 265, .unity = 266, .exponent = -3, .type = 3 },
    .{ .item = 265, .partner = 264, .unity = 237, .exponent = -3, .type = 3 },
    .{ .item = 266, .partner = 268, .unity = 0, .exponent = -3, .type = 3 },
    .{ .item = 267, .partner = 269, .unity = 270, .exponent = -3, .type = 3 },
    .{ .item = 268, .partner = 266, .unity = 266, .exponent = -3, .type = 3 },
    .{ .item = 269, .partner = 267, .unity = 237, .exponent = -3, .type = 3 },
    .{ .item = 270, .partner = 272, .unity = 0, .exponent = -3, .type = 3 },
    .{ .item = 271, .partner = 273, .unity = 276, .exponent = 0, .type = 3 },
    .{ .item = 272, .partner = 270, .unity = 270, .exponent = -3, .type = 3 },
    .{ .item = 273, .partner = 271, .unity = 255, .exponent = 0, .type = 3 },
    .{ .item = 274, .partner = 275, .unity = 0, .exponent = 0, .type = 3 },
    .{ .item = 275, .partner = 274, .unity = 274, .exponent = 0, .type = 3 },
    .{ .item = 276, .partner = 277, .unity = 0, .exponent = 0, .type = 3 },
    .{ .item = 277, .partner = 276, .unity = 276, .exponent = 0, .type = 3 },
    .{ .item = 278, .partner = 279, .unity = 0, .exponent = 0, .type = 9 },
    .{ .item = 279, .partner = 278, .unity = 278, .exponent = 0, .type = 9 },
    .{ .item = 280, .partner = 281, .unity = 0, .exponent = 0, .type = 9 },
    .{ .item = 281, .partner = 280, .unity = 280, .exponent = 0, .type = 9 },
    .{ .item = 282, .partner = 283, .unity = 0, .exponent = 0, .type = 9 },
    .{ .item = 283, .partner = 282, .unity = 282, .exponent = 0, .type = 9 },
    .{ .item = 284, .partner = 286, .unity = 0, .exponent = 0, .type = 7 },
    .{ .item = 285, .partner = 306, .unity = 270, .exponent = -3, .type = 3 },
    .{ .item = 286, .partner = 284, .unity = 284, .exponent = 0, .type = 7 },
    .{ .item = 287, .partner = 312, .unity = 0, .exponent = -3, .type = 3 },
    .{ .item = 288, .partner = 289, .unity = 0, .exponent = -3, .type = 1 },
    .{ .item = 289, .partner = 288, .unity = 2163, .exponent = -2, .type = 1 },
    .{ .item = 290, .partner = 291, .unity = 0, .exponent = 0, .type = 8 },
    .{ .item = 291, .partner = 290, .unity = 290, .exponent = 0, .type = 8 },
    .{ .item = 292, .partner = 293, .unity = 293, .exponent = 0, .type = 4 },
    .{ .item = 293, .partner = 292, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 294, .partner = 295, .unity = 295, .exponent = -3, .type = 4 },
    .{ .item = 295, .partner = 294, .unity = 0, .exponent = -3, .type = 4 },
    .{ .item = 296, .partner = 298, .unity = 298, .exponent = 0, .type = 4 },
    .{ .item = 297, .partner = 301, .unity = 266, .exponent = -3, .type = 3 },
    .{ .item = 298, .partner = 296, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 299, .partner = 315, .unity = 0, .exponent = -3, .type = 3 },
    .{ .item = 300, .partner = 302, .unity = 302, .exponent = 0, .type = 4 },
    .{ .item = 301, .partner = 297, .unity = 299, .exponent = -3, .type = 3 },
    .{ .item = 302, .partner = 300, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 303, .partner = 383, .unity = 385, .exponent = -3, .type = 3 },
    .{ .item = 304, .partner = 307, .unity = 307, .exponent = 0, .type = 4 },
    .{ .item = 305, .partner = 394, .unity = 395, .exponent = -3, .type = 3 },
    .{ .item = 306, .partner = 285, .unity = 287, .exponent = -3, .type = 3 },
    .{ .item = 307, .partner = 304, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 308, .partner = 365, .unity = 369, .exponent = -3, .type = 3 },
    .{ .item = 309, .partner = 392, .unity = 393, .exponent = -3, .type = 3 },
    .{ .item = 310, .partner = 313, .unity = 313, .exponent = 0, .type = 4 },
    .{ .item = 311, .partner = 314, .unity = 314, .exponent = 0, .type = 4 },
    .{ .item = 312, .partner = 287, .unity = 287, .exponent = -3, .type = 3 },
    .{ .item = 313, .partner = 310, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 314, .partner = 311, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 315, .partner = 299, .unity = 299, .exponent = -3, .type = 3 },
    .{ .item = 316, .partner = 318, .unity = 318, .exponent = -3, .type = 4 },
    .{ .item = 317, .partner = 351, .unity = 351, .exponent = -3, .type = 3 },
    .{ .item = 318, .partner = 316, .unity = 0, .exponent = -3, .type = 4 },
    .{ .item = 319, .partner = 354, .unity = 354, .exponent = -3, .type = 3 },
    .{ .item = 320, .partner = 321, .unity = 0, .exponent = 0, .type = 10 },
    .{ .item = 321, .partner = 320, .unity = 320, .exponent = 0, .type = 10 },
    .{ .item = 322, .partner = 323, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 323, .partner = 322, .unity = 322, .exponent = 0, .type = 1 },
    .{ .item = 324, .partner = 326, .unity = 0, .exponent = 0, .type = 7 },
    .{ .item = 325, .partner = 359, .unity = 356, .exponent = 0, .type = 3 },
    .{ .item = 326, .partner = 324, .unity = 324, .exponent = 0, .type = 7 },
    .{ .item = 327, .partner = 362, .unity = 262, .exponent = 0, .type = 3 },
    .{ .item = 328, .partner = 329, .unity = 0, .exponent = 3, .type = 1 },
    .{ .item = 329, .partner = 328, .unity = 336, .exponent = 0, .type = 1 },
    .{ .item = 330, .partner = 331, .unity = 360, .exponent = 0, .type = 1 },
    .{ .item = 331, .partner = 330, .unity = 0, .exponent = 3, .type = 1 },
    .{ .item = 332, .partner = 333, .unity = 333, .exponent = 0, .type = 1 },
    .{ .item = 333, .partner = 332, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 334, .partner = 337, .unity = 337, .exponent = -3, .type = 1 },
    .{ .item = 335, .partner = 369, .unity = 369, .exponent = -3, .type = 3 },
    .{ .item = 336, .partner = 339, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 337, .partner = 334, .unity = 0, .exponent = -3, .type = 1 },
    .{ .item = 338, .partner = 385, .unity = 385, .exponent = -3, .type = 3 },
    .{ .item = 339, .partner = 336, .unity = 336, .exponent = 0, .type = 1 },
    .{ .item = 340, .partner = 341, .unity = 341, .exponent = 0, .type = 1 },
    .{ .item = 341, .partner = 340, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 342, .partner = 343, .unity = 0, .exponent = 0, .type = 7 },
    .{ .item = 343, .partner = 342, .unity = 342, .exponent = 0, .type = 7 },
    .{ .item = 344, .partner = 346, .unity = 346, .exponent = 0, .type = 7 },
    .{ .item = 345, .partner = 393, .unity = 393, .exponent = -3, .type = 3 },
    .{ .item = 346, .partner = 344, .unity = 0, .exponent = 0, .type = 7 },
    .{ .item = 347, .partner = 395, .unity = 395, .exponent = -3, .type = 3 },
    .{ .item = 348, .partner = 349, .unity = 349, .exponent = 0, .type = 5 },
    .{ .item = 349, .partner = 348, .unity = 0, .exponent = 0, .type = 5 },
    .{ .item = 350, .partner = 353, .unity = 0, .exponent = -3, .type = 4 },
    .{ .item = 351, .partner = 317, .unity = 0, .exponent = -3, .type = 3 },
    .{ .item = 352, .partner = 355, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 353, .partner = 350, .unity = 350, .exponent = -3, .type = 4 },
    .{ .item = 354, .partner = 319, .unity = 0, .exponent = -3, .type = 3 },
    .{ .item = 355, .partner = 352, .unity = 352, .exponent = 0, .type = 4 },
    .{ .item = 356, .partner = 357, .unity = 0, .exponent = 0, .type = 3 },
    .{ .item = 357, .partner = 356, .unity = 356, .exponent = 0, .type = 3 },
    .{ .item = 358, .partner = 361, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 359, .partner = 325, .unity = 0, .exponent = -3, .type = 3 },
    .{ .item = 360, .partner = 363, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 361, .partner = 358, .unity = 358, .exponent = 0, .type = 1 },
    .{ .item = 362, .partner = 327, .unity = 0, .exponent = -3, .type = 3 },
    .{ .item = 363, .partner = 360, .unity = 360, .exponent = 0, .type = 1 },
    .{ .item = 364, .partner = 366, .unity = 0, .exponent = 3, .type = 3 },
    .{ .item = 365, .partner = 308, .unity = 270, .exponent = -3, .type = 3 },
    .{ .item = 366, .partner = 364, .unity = 364, .exponent = 3, .type = 3 },
    .{ .item = 367, .partner = 368, .unity = 0, .exponent = 0, .type = 0 },
    .{ .item = 368, .partner = 367, .unity = 0, .exponent = 0, .type = 0 },
    .{ .item = 369, .partner = 335, .unity = 0, .exponent = -3, .type = 3 },
    .{ .item = 370, .partner = 371, .unity = 0, .exponent = 0, .type = 2 },
    .{ .item = 371, .partner = 370, .unity = 0, .exponent = 4, .type = 2 },
    .{ .item = 372, .partner = 373, .unity = 0, .exponent = 0, .type = 2 },
    .{ .item = 373, .partner = 372, .unity = 372, .exponent = 0, .type = 2 },
    .{ .item = 374, .partner = 375, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 375, .partner = 374, .unity = 374, .exponent = 0, .type = 1 },
    .{ .item = 376, .partner = 377, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 377, .partner = 376, .unity = 376, .exponent = 0, .type = 1 },
    .{ .item = 378, .partner = 379, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 379, .partner = 378, .unity = 378, .exponent = 0, .type = 1 },
    .{ .item = 380, .partner = 381, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 381, .partner = 380, .unity = 380, .exponent = 0, .type = 1 },
    .{ .item = 382, .partner = 384, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 383, .partner = 303, .unity = 266, .exponent = -3, .type = 3 },
    .{ .item = 384, .partner = 382, .unity = 382, .exponent = 0, .type = 1 },
    .{ .item = 385, .partner = 338, .unity = 0, .exponent = -3, .type = 3 },
    .{ .item = 386, .partner = 387, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 387, .partner = 386, .unity = 386, .exponent = 0, .type = 1 },
    .{ .item = 388, .partner = 389, .unity = 0, .exponent = 6, .type = 2 },
    .{ .item = 389, .partner = 388, .unity = 388, .exponent = 6, .type = 2 },
    .{ .item = 390, .partner = 391, .unity = 0, .exponent = 6, .type = 2 },
    .{ .item = 391, .partner = 390, .unity = 390, .exponent = 6, .type = 2 },
    .{ .item = 392, .partner = 309, .unity = 270, .exponent = -3, .type = 3 },
    .{ .item = 393, .partner = 345, .unity = 0, .exponent = -3, .type = 3 },
    .{ .item = 394, .partner = 305, .unity = 266, .exponent = -3, .type = 3 },
    .{ .item = 395, .partner = 347, .unity = 0, .exponent = -3, .type = 3 },
    .{ .item = 1902, .partner = 1903, .unity = 270, .exponent = -3, .type = 3 },
    .{ .item = 1903, .partner = 1902, .unity = 276, .exponent = 0, .type = 3 },
    .{ .item = 2084, .partner = 2085, .unity = 2086, .exponent = 0, .type = 12 },
    .{ .item = 2085, .partner = 2084, .unity = 2743, .exponent = 0, .type = 12 },
    .{ .item = 2086, .partner = 2087, .unity = 0, .exponent = 0, .type = 12 },
    .{ .item = 2087, .partner = 2086, .unity = 2086, .exponent = 0, .type = 12 },
    .{ .item = 2088, .partner = 2089, .unity = 2745, .exponent = 0, .type = 14 },
    .{ .item = 2089, .partner = 2088, .unity = 2094, .exponent = 0, .type = 14 },
    .{ .item = 2090, .partner = 2091, .unity = 2086, .exponent = 0, .type = 12 },
    .{ .item = 2091, .partner = 2090, .unity = 2092, .exponent = 0, .type = 12 },
    .{ .item = 2092, .partner = 2093, .unity = 0, .exponent = 0, .type = 12 },
    .{ .item = 2093, .partner = 2092, .unity = 2092, .exponent = 0, .type = 12 },
    .{ .item = 2094, .partner = 2095, .unity = 0, .exponent = 0, .type = 14 },
    .{ .item = 2095, .partner = 2094, .unity = 2094, .exponent = 0, .type = 14 },
    .{ .item = 2096, .partner = 2097, .unity = 0, .exponent = 0, .type = 13 },
    .{ .item = 2097, .partner = 2096, .unity = 2096, .exponent = 0, .type = 13 },
    .{ .item = 2098, .partner = 2099, .unity = 2100, .exponent = 0, .type = 13 },
    .{ .item = 2099, .partner = 2098, .unity = 2096, .exponent = 0, .type = 13 },
    .{ .item = 2100, .partner = 2101, .unity = 0, .exponent = 0, .type = 13 },
    .{ .item = 2101, .partner = 2100, .unity = 2100, .exponent = 0, .type = 13 },
    .{ .item = 2163, .partner = 2164, .unity = 0, .exponent = -2, .type = 1 },
    .{ .item = 2164, .partner = 2163, .unity = 2163, .exponent = -2, .type = 1 },
    .{ .item = 2167, .partner = 2168, .unity = 336, .exponent = 0, .type = 1 },
    .{ .item = 2168, .partner = 2167, .unity = 360, .exponent = 0, .type = 1 },
    .{ .item = 2169, .partner = 2170, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 2170, .partner = 2169, .unity = 2169, .exponent = 0, .type = 1 },
    .{ .item = 2171, .partner = 2172, .unity = 0, .exponent = 0, .type = 5 },
    .{ .item = 2172, .partner = 2171, .unity = 2171, .exponent = 0, .type = 5 },
    .{ .item = 2173, .partner = 2174, .unity = 0, .exponent = 0, .type = 12 },
    .{ .item = 2174, .partner = 2173, .unity = 2173, .exponent = 0, .type = 12 },
    .{ .item = 2175, .partner = 2176, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 2176, .partner = 2175, .unity = 2175, .exponent = 0, .type = 1 },
    .{ .item = 2177, .partner = 2178, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 2178, .partner = 2177, .unity = 2177, .exponent = 0, .type = 4 },
    .{ .item = 2179, .partner = 2180, .unity = 2086, .exponent = 0, .type = 12 },
    .{ .item = 2180, .partner = 2179, .unity = 2173, .exponent = 0, .type = 12 },
    .{ .item = 2181, .partner = 2182, .unity = 2163, .exponent = -2, .type = 1 },
    .{ .item = 2182, .partner = 2181, .unity = 2175, .exponent = 0, .type = 1 },
    .{ .item = 2183, .partner = 2184, .unity = 293, .exponent = 0, .type = 4 },
    .{ .item = 2184, .partner = 2183, .unity = 2177, .exponent = 0, .type = 4 },
    .{ .item = 2185, .partner = 2186, .unity = 2092, .exponent = 0, .type = 12 },
    .{ .item = 2186, .partner = 2185, .unity = 2173, .exponent = 0, .type = 12 },
    .{ .item = 2187, .partner = 2188, .unity = 2086, .exponent = 0, .type = 12 },
    .{ .item = 2188, .partner = 2187, .unity = 2189, .exponent = 0, .type = 12 },
    .{ .item = 2189, .partner = 2190, .unity = 0, .exponent = 0, .type = 12 },
    .{ .item = 2190, .partner = 2189, .unity = 2189, .exponent = 0, .type = 12 },
    .{ .item = 2204, .partner = 2205, .unity = 0, .exponent = 0, .type = 15 },
    .{ .item = 2205, .partner = 2204, .unity = 0, .exponent = 0, .type = 15 },
    .{ .item = 2206, .partner = 2207, .unity = 0, .exponent = 0, .type = 16 },
    .{ .item = 2207, .partner = 2206, .unity = 0, .exponent = 0, .type = 16 },
    .{ .item = 2208, .partner = 2209, .unity = 0, .exponent = 0, .type = 16 },
    .{ .item = 2209, .partner = 2208, .unity = 0, .exponent = 0, .type = 16 },
    .{ .item = 2210, .partner = 2211, .unity = 0, .exponent = 0, .type = 15 },
    .{ .item = 2211, .partner = 2210, .unity = 0, .exponent = 0, .type = 15 },
    .{ .item = 2212, .partner = 2213, .unity = 0, .exponent = 0, .type = 16 },
    .{ .item = 2213, .partner = 2212, .unity = 0, .exponent = 0, .type = 16 },
    .{ .item = 2214, .partner = 2215, .unity = 0, .exponent = 0, .type = 16 },
    .{ .item = 2215, .partner = 2214, .unity = 0, .exponent = 0, .type = 16 },
    .{ .item = 2216, .partner = 2217, .unity = 0, .exponent = 0, .type = 15 },
    .{ .item = 2217, .partner = 2216, .unity = 0, .exponent = 0, .type = 15 },
    .{ .item = 2218, .partner = 2219, .unity = 0, .exponent = 0, .type = 16 },
    .{ .item = 2219, .partner = 2218, .unity = 0, .exponent = 0, .type = 16 },
    .{ .item = 2220, .partner = 2221, .unity = 0, .exponent = 0, .type = 16 },
    .{ .item = 2221, .partner = 2220, .unity = 0, .exponent = 0, .type = 16 },
    .{ .item = 2464, .partner = 2465, .unity = 0, .exponent = 0, .type = 8 },
    .{ .item = 2465, .partner = 2464, .unity = 2464, .exponent = 0, .type = 8 },
    .{ .item = 2466, .partner = 2467, .unity = 2163, .exponent = -2, .type = 1 },
    .{ .item = 2467, .partner = 2466, .unity = 2468, .exponent = -3, .type = 1 },
    .{ .item = 2468, .partner = 2469, .unity = 0, .exponent = -3, .type = 1 },
    .{ .item = 2469, .partner = 2468, .unity = 2468, .exponent = -3, .type = 1 },
    .{ .item = 2658, .partner = 2659, .unity = 0, .exponent = 0, .type = 8 },
    .{ .item = 2659, .partner = 2658, .unity = 2658, .exponent = 0, .type = 8 },
    .{ .item = 2660, .partner = 2661, .unity = 0, .exponent = 0, .type = 8 },
    .{ .item = 2661, .partner = 2660, .unity = 2660, .exponent = 0, .type = 8 },
    .{ .item = 2665, .partner = 2666, .unity = 0, .exponent = 0, .type = 6 },
    .{ .item = 2666, .partner = 2665, .unity = 2665, .exponent = 0, .type = 6 },
    .{ .item = 2667, .partner = 2668, .unity = 0, .exponent = 0, .type = 6 },
    .{ .item = 2668, .partner = 2667, .unity = 2667, .exponent = 0, .type = 6 },
    .{ .item = 2669, .partner = 2670, .unity = 2673, .exponent = 0, .type = 6 },
    .{ .item = 2670, .partner = 2669, .unity = 2667, .exponent = 0, .type = 6 },
    .{ .item = 2671, .partner = 2672, .unity = 0, .exponent = 0, .type = 6 },
    .{ .item = 2672, .partner = 2671, .unity = 2671, .exponent = 0, .type = 6 },
    .{ .item = 2673, .partner = 2674, .unity = 0, .exponent = 0, .type = 6 },
    .{ .item = 2674, .partner = 2673, .unity = 2673, .exponent = 0, .type = 6 },
    .{ .item = 2743, .partner = 2744, .unity = 0, .exponent = 0, .type = 12 },
    .{ .item = 2744, .partner = 2743, .unity = 2743, .exponent = 0, .type = 12 },
    .{ .item = 2745, .partner = 2746, .unity = 0, .exponent = 0, .type = 14 },
    .{ .item = 2746, .partner = 2745, .unity = 2745, .exponent = 0, .type = 14 },
    .{ .item = 2747, .partner = 2748, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 2748, .partner = 2747, .unity = 2747, .exponent = 0, .type = 4 },
    .{ .item = 2749, .partner = 2750, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 2750, .partner = 2749, .unity = 2749, .exponent = 0, .type = 4 },
    .{ .item = 2751, .partner = 2752, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 2752, .partner = 2751, .unity = 2751, .exponent = 0, .type = 4 },
    .{ .item = 2753, .partner = 2754, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 2754, .partner = 2753, .unity = 2753, .exponent = 0, .type = 4 },
    .{ .item = 2800, .partner = 2801, .unity = 0, .exponent = 0, .type = 7 },
    .{ .item = 2801, .partner = 2800, .unity = 2800, .exponent = 0, .type = 7 },
    .{ .item = 2802, .partner = 2803, .unity = 0, .exponent = 0, .type = 11 },
    .{ .item = 2803, .partner = 2802, .unity = 2802, .exponent = 0, .type = 11 },
    .{ .item = 2804, .partner = 2805, .unity = 0, .exponent = 0, .type = 19 },
    .{ .item = 2805, .partner = 2804, .unity = 2804, .exponent = 0, .type = 19 },
    .{ .item = 2806, .partner = 2807, .unity = 0, .exponent = 0, .type = 10 },
    .{ .item = 2807, .partner = 2806, .unity = 2806, .exponent = 0, .type = 10 },
    .{ .item = 2808, .partner = 2809, .unity = 2809, .exponent = 0, .type = 17 },
    .{ .item = 2809, .partner = 2808, .unity = 0, .exponent = 0, .type = 17 },
    .{ .item = 2810, .partner = 2811, .unity = 2811, .exponent = 0, .type = 17 },
    .{ .item = 2811, .partner = 2810, .unity = 0, .exponent = 0, .type = 17 },
    .{ .item = 2812, .partner = 2813, .unity = 0, .exponent = 6, .type = 7 },
    .{ .item = 2813, .partner = 2812, .unity = 2812, .exponent = 6, .type = 7 },
    .{ .item = 2814, .partner = 2815, .unity = 2821, .exponent = 0, .type = 18 },
    .{ .item = 2815, .partner = 2814, .unity = 2818, .exponent = 0, .type = 18 },
    .{ .item = 2816, .partner = 2817, .unity = 2823, .exponent = 0, .type = 18 },
    .{ .item = 2817, .partner = 2816, .unity = 2818, .exponent = 0, .type = 18 },
    .{ .item = 2818, .partner = 2819, .unity = 0, .exponent = 0, .type = 18 },
    .{ .item = 2819, .partner = 2818, .unity = 2818, .exponent = 0, .type = 18 },
    .{ .item = 2820, .partner = 2821, .unity = 2821, .exponent = 0, .type = 18 },
    .{ .item = 2821, .partner = 2820, .unity = 0, .exponent = 0, .type = 18 },
    .{ .item = 2822, .partner = 2823, .unity = 2823, .exponent = 0, .type = 18 },
    .{ .item = 2823, .partner = 2822, .unity = 0, .exponent = 0, .type = 18 },
    .{ .item = 2824, .partner = 2825, .unity = 0, .exponent = 0, .type = 0 },
    .{ .item = 2825, .partner = 2824, .unity = 0, .exponent = 0, .type = 0 },
    .{ .item = 2826, .partner = 2827, .unity = 0, .exponent = -6, .type = 3 },
    .{ .item = 2827, .partner = 2826, .unity = 2826, .exponent = -6, .type = 3 },
    .{ .item = 2828, .partner = 2829, .unity = 0, .exponent = -6, .type = 2 },
    .{ .item = 2829, .partner = 2828, .unity = 2828, .exponent = -6, .type = 2 },
    .{ .item = 2830, .partner = 2831, .unity = 0, .exponent = 0, .type = 0 },
    .{ .item = 2831, .partner = 2830, .unity = 0, .exponent = 0, .type = 0 },
    .{ .item = 2832, .partner = 2833, .unity = 0, .exponent = 0, .type = 0 },
    .{ .item = 2833, .partner = 2832, .unity = 0, .exponent = 0, .type = 0 },
    .{ .item = 2834, .partner = 2835, .unity = 0, .exponent = 0, .type = 19 },
    .{ .item = 2835, .partner = 2834, .unity = 2834, .exponent = 0, .type = 19 },
    .{ .item = 2836, .partner = 2837, .unity = 320, .exponent = 0, .type = 10 },
    .{ .item = 2837, .partner = 2836, .unity = 2806, .exponent = 0, .type = 10 },
    .{ .item = 2838, .partner = 2839, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 2839, .partner = 2838, .unity = 2838, .exponent = 0, .type = 4 },
    .{ .item = 2840, .partner = 2841, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 2841, .partner = 2840, .unity = 2840, .exponent = 0, .type = 4 },
    .{ .item = 2860, .partner = 2861, .unity = 2743, .exponent = 0, .type = 12 }, // MPHtoKNOT: unity KNOTtoMPS, UT_SPEED
    .{ .item = 2861, .partner = 2860, .unity = 2092, .exponent = 0, .type = 12 }, // KNOTtoMPH: unity MPHtoMPS,  UT_SPEED
    .{ .item = 2862, .partner = 2863, .unity = 2189, .exponent = 0, .type = 12 }, // MPHtoFPS:  unity FPStoMPS,  UT_SPEED
    .{ .item = 2863, .partner = 2862, .unity = 2092, .exponent = 0, .type = 12 }, // FPStoMPH:  unity MPHtoMPS,  UT_SPEED
};

/// Binary search the item-sorted table; null if `input` is not a conversion item.
pub fn findPair(input: i16) ?*const ConvPair {
    var lo: u16 = 0;
    var hi: u16 = NUM_CONVERT_PAIRS;
    while (lo < hi) {
        const mid: u16 = (lo + hi) >> 1;
        if (convert_pairs[mid].item < input) {
            lo = mid + 1;
        } else {
            hi = mid;
        }
    }
    return if (lo < NUM_CONVERT_PAIRS and convert_pairs[lo].item == input) &convert_pairs[lo] else null;
}

pub fn conversionPartner(input: i16, unity: ?*i16, exponent: ?*i8, type_out: ?*u8) i16 {
    const entry = findPair(input) orelse return 0; // not found
    if (unity) |p| p.* = entry.unity;
    if (exponent) |p| p.* = entry.exponent;
    if (type_out) |p| p.* = entry.type;
    return entry.partner;
}

pub fn isItemConversion(itemNr: i16) bool {
    return findPair(itemNr) != null;
}

pub fn areBothConvertConfigurable(item1Nr: i16, item2Nr: i16) bool {
    const entry1 = findPair(item1Nr) orelse return false;
    const entry2 = findPair(item2Nr) orelse return false;
    return entry1.type == entry2.type and entry1.type != UT_NOT_CONFIGURABLE; // same configurable type
}

pub fn isStandardPair(item1Nr: i16, item2Nr: i16) bool {
    return item2Nr != 0 and conversionPartner(item1Nr, null, null, null) == item2Nr;
}

pub fn isOneOfAConvertPair(x: u16, itemNr: i16, oddNrPartner: *i16) bool {
    const entry = findPair(itemNr) orelse return false; // not a conversion-pair member
    if ((x & 1) == 0) {
        oddNrPartner.* = entry.partner; // even x = left softkey: report partner
    }
    return true;
}

test "findPair binary-searches the item-sorted table" {
    try std.testing.expect(findPair(220) != null);
    try std.testing.expectEqual(@as(?*const ConvPair, null), findPair(1)); // below range
    try std.testing.expectEqual(@as(i16, 221), findPair(220).?.partner);
}

test "conversionPartner returns the partner and writes the out-params" {
    var unity: i16 = -1;
    var exponent: i8 = -1;
    var t: u8 = 255;
    try std.testing.expectEqual(@as(i16, 221), conversionPartner(220, &unity, &exponent, &t));
    try std.testing.expectEqual(@as(i16, 2673), unity);
    try std.testing.expectEqual(@as(i8, 0), exponent);
    try std.testing.expectEqual(@as(u8, 6), t);
    try std.testing.expectEqual(@as(i16, 0), conversionPartner(1, null, null, null)); // not found
}

test "membership / configurable / standard-pair / one-of-a-pair predicates" {
    try std.testing.expect(isItemConversion(220));
    try std.testing.expect(!isItemConversion(1));
    try std.testing.expect(areBothConvertConfigurable(223, 224)); // both type 2
    try std.testing.expect(!areBothConvertConfigurable(222, 228)); // both type 0 (not configurable)
    try std.testing.expect(isStandardPair(220, 221));
    try std.testing.expect(!isStandardPair(220, 999));
    var partner: i16 = 0;
    try std.testing.expect(isOneOfAConvertPair(0, 220, &partner)); // even x -> partner reported
    try std.testing.expectEqual(@as(i16, 221), partner);
    partner = 0;
    try std.testing.expect(isOneOfAConvertPair(1, 220, &partner)); // odd x -> not written
    try std.testing.expectEqual(@as(i16, 0), partner);
    try std.testing.expect(!isOneOfAConvertPair(0, 1, &partner)); // not a pair member
}
