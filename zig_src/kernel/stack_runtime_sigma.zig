pub fn restoreSavedSigmaLastXYAndAdd(
    comptime RealT: type,
    saved_x: *const RealT,
    saved_y: *const RealT,
    register_x: i16,
    register_y: i16,
    am_none: u32,
    sigma_plus: u16,
    convert_real_to_result: *const fn (value: *const RealT, dest: i16, angle: u32) callconv(.c) void,
    sigma_add_rem: *const fn (selection: u16) callconv(.c) void,
) void {
    convert_real_to_result(saved_x, register_x, am_none);
    convert_real_to_result(saved_y, register_y, am_none);
    sigma_add_rem(sigma_plus);
}
