const std = @import("std");

/// registers.c getRegParamRange: validates a public register range keyed in
/// keystroke codes and expands a zero count to the rest of its band. The bands
/// are the numbered registers, the lettered registers, the allocated local
/// registers and the stat-and-spare registers; a range must stay inside one.
pub fn getRegParamRange(
    first: u16,
    number: *u16,
    register_x_in_ks_code: u16,
    last_lettered_register_in_ks_code: u16,
    first_local_register_in_ks_code: u16,
    current_local_register_count: u16,
    first_stat_register_in_ks_code: u16,
    last_spare_registers_in_ks_code: u16,
) bool {
    var end: u16 = undefined;

    if (first < register_x_in_ks_code) {
        end = register_x_in_ks_code;
    } else if (first <= last_lettered_register_in_ks_code) {
        end = last_lettered_register_in_ks_code + 1;
    } else if (first >= first_local_register_in_ks_code and first < first_local_register_in_ks_code + current_local_register_count) {
        end = first_local_register_in_ks_code + current_local_register_count;
    } else if (first >= first_stat_register_in_ks_code and first <= last_spare_registers_in_ks_code) {
        end = last_spare_registers_in_ks_code + 1;
    } else {
        return false;
    }

    if (number.* == 0) {
        number.* = end - first;
    }
    return @as(u32, first) + @as(u32, number.*) <= @as(u32, end);
}

// Native unit tests over the keystroke bands: numbered 0-99, lettered 100-111,
// local 112.., stat and spare 211-224.
const testing = std.testing;

fn range(first: u16, number: u16, locals: u16) ?u16 {
    var n = number;
    return if (getRegParamRange(first, &n, 100, 111, 112, locals, 211, 224)) n else null;
}

test "getRegParamRange keeps a range inside one band" {
    try testing.expectEqual(@as(?u16, 5), range(0, 5, 8));
    try testing.expectEqual(@as(?u16, 100), range(0, 0, 8)); // a zero count takes the band
    try testing.expectEqual(@as(?u16, 2), range(98, 2, 8)); // ends exactly at the band
    try testing.expectEqual(@as(?u16, null), range(98, 3, 8)); // crosses into the lettered band
    try testing.expectEqual(@as(?u16, 12), range(100, 0, 8));
    try testing.expectEqual(@as(?u16, 8), range(112, 0, 8)); // the allocated locals
    try testing.expectEqual(@as(?u16, null), range(112, 9, 8));
    try testing.expectEqual(@as(?u16, null), range(112, 1, 0)); // no locals allocated
    try testing.expectEqual(@as(?u16, 14), range(211, 0, 8));
    try testing.expectEqual(@as(?u16, null), range(224, 2, 8));
    try testing.expectEqual(@as(?u16, null), range(230, 1, 8)); // outside every band
}
