const frontier_matrix_editor = @import("matrix_editor.zig");
const frontier_build_options = @import("frontier_build_options");
// OPTION_DRG_CFG: DRG chooses the angular unit of a complex element being entered.
const option_drg_cfg: bool = frontier_build_options.option_drg_cfg;
const CM_MIM: u8 = 12;

const ITM_CHS: i16 = 97;
const ITM_CONSTpi: i16 = 109;
const ITM_0: i16 = 540;
const ITM_1: i16 = 541;
const ITM_2: i16 = 542;
const ITM_3: i16 = 543;
const ITM_4: i16 = 544;
const ITM_5: i16 = 545;
const ITM_6: i16 = 546;
const ITM_7: i16 = 547;
const ITM_8: i16 = 548;
const ITM_9: i16 = 549;
const ITM_PERIOD: i16 = 820;
const ITM_EXPONENT: i16 = 990;
const ITM_CC: i16 = 1730;
const ITM_BACKSPACE: i16 = 1738;
const ITM_op_j_pol: i16 = 1795;
const ITM_op_j: i16 = 1830;
const ITM_DRG: i16 = 1873;

const ItemClass = enum {
    exponent,
    period,
    digit,
    backspace,
    sign,
    imaginary_unit,
    drg,
    pi,
    unsupported,
};

pub fn run(item: i16) void {
    const class = classify(item);
    if (frontier_matrix_editor.z47_frontier_matrix_aim_is_empty()) {
        handleAimEmpty(class, item);
        return;
    }
    handleAimNonEmpty(class, item);
}

fn classify(item: i16) ItemClass {
    return switch (item) {
        ITM_EXPONENT => .exponent,
        ITM_PERIOD => .period,
        ITM_0, ITM_1, ITM_2, ITM_3, ITM_4, ITM_5, ITM_6, ITM_7, ITM_8, ITM_9 => .digit,
        ITM_BACKSPACE => .backspace,
        ITM_CHS => .sign,
        ITM_op_j_pol, ITM_op_j, ITM_CC => .imaginary_unit,
        ITM_DRG => if (option_drg_cfg) .drg else .unsupported,
        ITM_CONSTpi => .pi,
        else => .unsupported,
    };
}

fn enqueue(item: i16) void {
    frontier_matrix_editor.z47_frontier_matrix_add_item_to_nim_buffer(item);
    calcMode = CM_MIM;
}

// DRG goes to the entry only where it chooses the unit of a complex element.
fn enqueueDrg(item: i16) void {
    if (frontier_matrix_editor.z47_frontier_matrix_drg_chooses_unit()) {
        enqueue(item);
    }
}

fn handleAimEmpty(class: ItemClass, item: i16) void {
    switch (class) {
        .exponent, .period, .digit => {
            frontier_matrix_editor.z47_frontier_matrix_start_number(item);
            enqueue(item);
        },
        .drg => enqueueDrg(item),
        .backspace => frontier_matrix_editor.z47_frontier_matrix_zero_current_element(),
        .sign => frontier_matrix_editor.z47_frontier_matrix_change_sign_current_element(),
        .imaginary_unit => frontier_matrix_editor.z47_frontier_matrix_make_j_element(item),
        .pi => frontier_matrix_editor.z47_frontier_matrix_set_current_to_pi(),
        .unsupported => {},
    }
}

fn handleAimNonEmpty(class: ItemClass, item: i16) void {
    switch (class) {
        .exponent, .period, .digit, .sign, .imaginary_unit => enqueue(item),
        .backspace => {
            if (frontier_matrix_editor.z47_frontier_matrix_aim_is_single_plus_digit()) {
                frontier_matrix_editor.z47_frontier_matrix_aim_clear_single_plus_digit();
            }
            enqueue(item);
        },
        .drg => enqueueDrg(item),
        .pi => frontier_matrix_editor.z47_frontier_matrix_pi_after_i_enter(),
        .unsupported => {},
    }
}

extern var calcMode: u8;
