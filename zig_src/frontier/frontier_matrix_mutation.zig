const frontier = @import("frontier.zig"); // M-callconv: Zig-to-Zig
const frontier_matrix_editor = @import("frontier_matrix_editor.zig"); // M-callconv: Zig-to-Zig
pub const Kind = enum {
    insert_row_before,
    insert_row_after,
    insert_col_before,
    insert_col_after,
    delete_row,
    delete_col,
};

pub fn run(kind: Kind) void {
    frontier.mimEnter(false);
    defer frontier.mimEnter(true);

    apply(kind);
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





