const percent_base_owned = @import("math_percent_base_owned.zig");
const percent_extended_owned = @import("math_percent_extended_owned.zig");

pub fn percent(unused_but_mandatory_parameter: u16) void {
    percent_base_owned.percent(unused_but_mandatory_parameter);
}

pub fn percentMRR(unused_but_mandatory_parameter: u16) void {
    percent_extended_owned.percentMRR(unused_but_mandatory_parameter);
}

pub fn percentPlusMG(unused_but_mandatory_parameter: u16) void {
    percent_extended_owned.percentPlusMG(unused_but_mandatory_parameter);
}

pub fn percentT(unused_but_mandatory_parameter: u16) void {
    percent_extended_owned.percentT(unused_but_mandatory_parameter);
}

pub fn deltaPercent(unused_but_mandatory_parameter: u16) void {
    percent_extended_owned.deltaPercent(unused_but_mandatory_parameter);
}