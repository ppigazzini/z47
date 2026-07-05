const frontier_matrix_editor = @import("frontier_matrix_editor.zig"); // M-callconv: Zig-to-Zig
const INVALID_VARIABLE: u16 = 2199;

pub fn enter(commit: bool) void {
    if (!frontier_matrix_editor.z47_frontier_matrix_aim_is_empty()) {
        frontier_matrix_editor.z47_frontier_matrix_mim_enter_apply_aim_buffer();
    }
    if (commit) {
        frontier_matrix_editor.z47_frontier_matrix_mim_enter_commit_open_matrix();
    }
    frontier_matrix_editor.z47_frontier_matrix_update_height_cache();
}

pub fn finalize() void {
    frontier_matrix_editor.z47_frontier_matrix_finalize_open_matrix_memory();
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






extern fn getMatrixFromRegister(regist: u16) void;