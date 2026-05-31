pub fn getRegClrRange(
    comptime use_fake_stack_state_harness_surface: bool,
    s: *u16,
    n: *u16,
    product_decoder: *const fn (?*bool, *u16, *u16, ?*u16) u8,
) u8 {
    if (use_fake_stack_state_harness_surface) {
        return z47_registers_legacy_get_reg_clr_range(s, n);
    }

    return product_decoder(null, s, n, null);
}

pub fn getRegSwapRange(
    comptime use_fake_stack_state_harness_surface: bool,
    s: *u16,
    n: *u16,
    d: *u16,
    product_decoder: *const fn (?*bool, *u16, *u16, ?*u16) u8,
) u8 {
    if (use_fake_stack_state_harness_surface) {
        return z47_registers_legacy_get_reg_swap_range(s, n, d);
    }

    return product_decoder(null, s, n, d);
}

pub fn getRegCopyParams(
    comptime use_fake_stack_state_harness_surface: bool,
    f: *bool,
    s: *u16,
    n: *u16,
    d: *u16,
    product_decoder: *const fn (?*bool, *u16, *u16, ?*u16) u8,
) u8 {
    if (use_fake_stack_state_harness_surface) {
        return z47_registers_legacy_get_reg_copy_params(f, s, n, d);
    }

    return product_decoder(f, s, n, d);
}

extern fn z47_registers_legacy_get_reg_clr_range(s: *u16, n: *u16) u8;
extern fn z47_registers_legacy_get_reg_swap_range(s: *u16, n: *u16, d: *u16) u8;
extern fn z47_registers_legacy_get_reg_copy_params(f: *bool, s: *u16, n: *u16, d: *u16) u8;