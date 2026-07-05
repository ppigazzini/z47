const matrix_nav = @import("frontier_matrix_nav.zig");
const frontier = @import("frontier.zig"); // M-callconv: Zig-to-Zig
const frontier_matrix_editor = @import("frontier_matrix_editor.zig"); // M-callconv: Zig-to-Zig

const Geometry = struct {
    rows: i16,
    cols: i16,
    col_vector: bool,
};

const Selection = struct {
    row: i16,
    col: i16,
};

pub fn run() void {
    ensureSoftmenu();

    const geometry = loadGeometry();
    applyWrapGrowthIfNeeded(geometry);

    const selection = readSelection(geometry);
    updateScrollRow(geometry, selection);
    render(geometry, selection);
}

fn loadGeometry() Geometry {
    var rows: i16 = @as(i16, @intCast(frontier_matrix_editor.z47_frontier_matrix_open_rows()));
    var cols: i16 = @as(i16, @intCast(frontier_matrix_editor.z47_frontier_matrix_open_cols()));
    var col_vector = false;

    if (cols == 1 and rows > 1) {
        col_vector = true;
        cols = rows;
        rows = 1;
    }

    return .{ .rows = rows, .cols = cols, .col_vector = col_vector };
}

fn ensureSoftmenu() void {
    if (!frontier_matrix_editor.z47_frontier_matrix_softmenu_has_m_edit()) {
        frontier_matrix_editor.z47_frontier_matrix_show_m_edit_softmenu();
    }
    if (frontier_matrix_editor.z47_frontier_matrix_softmenu_top_is_m_edit()) {
        frontier_matrix_editor.z47_frontier_matrix_calc_mode_normal_gui();
    }
}

fn wrapCoordinates(geometry: Geometry) bool {
    const wrap_rows: u16 = if (geometry.col_vector) @as(u16, @intCast(geometry.cols)) else @as(u16, @intCast(geometry.rows));
    const wrap_cols: u16 = if (geometry.col_vector) 1 else @as(u16, @intCast(geometry.cols));
    return matrix_nav.wrap(wrap_rows, wrap_cols);
}

fn applyWrapGrowthIfNeeded(geometry: Geometry) void {
    if (wrapCoordinates(geometry)) {
        frontier_matrix_editor.z47_frontier_matrix_insert_row(false);
        frontier_matrix_editor.z47_frontier_matrix_commit_open_to_register();
    }
}

fn readSelection(geometry: Geometry) Selection {
    return .{
        .row = if (geometry.col_vector) frontier.getJRegisterAsInt(true) else frontier.getIRegisterAsInt(true),
        .col = if (geometry.col_vector) frontier.getIRegisterAsInt(true) else frontier.getJRegisterAsInt(true),
    };
}

fn computeScrollRow(rows: i16, selected_row: i16, current_scroll_row: i16) i16 {
    if (selected_row == 0 or rows <= 5) {
        return 0;
    }
    if (selected_row == rows - 1) {
        return selected_row - 4;
    }
    if (selected_row < current_scroll_row + 1) {
        return selected_row - 1;
    }
    if (selected_row > current_scroll_row + 3) {
        return selected_row - 3;
    }
    return current_scroll_row;
}

fn updateScrollRow(geometry: Geometry, selection: Selection) void {
    const existing: i16 = @as(i16, @intCast(frontier_matrix_editor.z47_frontier_matrix_scroll_row_get()));
    const next = computeScrollRow(geometry.rows, selection.row, existing);
    frontier_matrix_editor.z47_frontier_matrix_scroll_row_set(@as(u16, @intCast(next)));
}

fn render(geometry: Geometry, selection: Selection) void {
    frontier_matrix_editor.z47_frontier_matrix_render_editor_body(geometry.col_vector, geometry.rows, geometry.cols, selection.row, selection.col);
}













