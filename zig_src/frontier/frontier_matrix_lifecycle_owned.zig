const INVALID_VARIABLE: u16 = 2199;

pub fn enter(commit: bool) void {
    if (!z47_frontier_matrix_aim_is_empty()) {
        z47_frontier_matrix_mim_enter_apply_aim_buffer();
    }
    if (commit) {
        z47_frontier_matrix_mim_enter_commit_open_matrix();
    }
    z47_frontier_matrix_update_height_cache();
}

pub fn finalize() void {
    z47_frontier_matrix_finalize_open_matrix_memory();
    matrixIndex = INVALID_VARIABLE;
}

pub fn restore() void {
    const idx = matrixIndex;

    finalize();

    if (idx != INVALID_VARIABLE) {
        getMatrixFromRegister(idx);
        matrixIndex = idx;
    }
}

extern var matrixIndex: u16;

extern fn z47_frontier_matrix_aim_is_empty() bool;
extern fn z47_frontier_matrix_mim_enter_apply_aim_buffer() void;
extern fn z47_frontier_matrix_mim_enter_commit_open_matrix() void;
extern fn z47_frontier_matrix_update_height_cache() void;
extern fn z47_frontier_matrix_finalize_open_matrix_memory() void;
extern fn getMatrixFromRegister(regist: u16) void;