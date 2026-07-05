pub const Kind = enum {
    insert_row_before,
    insert_row_after,
    insert_col_before,
    insert_col_after,
    delete_row,
    delete_col,
};

pub fn run(kind: Kind) void {
    mimEnter(false);
    defer mimEnter(true);

    apply(kind);
}

fn apply(kind: Kind) void {
    switch (kind) {
        .insert_row_before => z47_frontier_matrix_insert_row(false),
        .insert_row_after => z47_frontier_matrix_insert_row(true),
        .insert_col_before => z47_frontier_matrix_insert_col(false),
        .insert_col_after => z47_frontier_matrix_insert_col(true),
        .delete_row => z47_frontier_matrix_delete_row(),
        .delete_col => z47_frontier_matrix_delete_col(),
    }
}

extern fn mimEnter(commit: bool) void;
extern fn z47_frontier_matrix_insert_row(add: bool) void;
extern fn z47_frontier_matrix_insert_col(add: bool) void;
extern fn z47_frontier_matrix_delete_row() void;
extern fn z47_frontier_matrix_delete_col() void;