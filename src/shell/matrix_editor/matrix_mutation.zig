const matrix_lifecycle = @import("matrix_lifecycle.zig");
const frontier_matrix_editor = @import("matrix_editor.zig");
pub const Kind = enum {
    insert_row_before,
    insert_row_after,
    insert_col_before,
    insert_col_after,
    delete_row,
    delete_col,
};

pub fn run(kind: Kind) void {
    if (!frontier_matrix_editor.matrixEnsureEditorMode(refusingFunction(kind))) {
        return;
    }

    matrix_lifecycle.mimEnter(false);
    defer matrix_lifecycle.mimEnter(true);

    apply(kind);
}

/// The four row/column mutations are four separate C functions, and each names
/// itself in the console hint it prints when it refuses outside CM_MIM.
fn refusingFunction(kind: Kind) [*:0]const u8 {
    return switch (kind) {
        .insert_row_before, .insert_row_after => "In function _fnInsRow:",
        .insert_col_before, .insert_col_after => "In function _fnInsCol:",
        .delete_row => "In function fnDelRow:",
        .delete_col => "In function fnDelCol:",
    };
}

fn apply(kind: Kind) void {
    switch (kind) {
        .insert_row_before => frontier_matrix_editor.z47_frontier_matrix_insert_row(false),
        .insert_row_after => frontier_matrix_editor.z47_frontier_matrix_insert_row(true),
        .insert_col_before => frontier_matrix_editor.z47_frontier_matrix_insert_col(false),
        .insert_col_after => frontier_matrix_editor.z47_frontier_matrix_insert_col(true),
        .delete_row => frontier_matrix_editor.z47_frontier_matrix_delete_row(),
        .delete_col => frontier_matrix_editor.z47_frontier_matrix_delete_col(),
    }
}
