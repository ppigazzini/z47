extern fn drawScreen(widget: ?*anyopaque, cr: ?*anyopaque, data: ?*anyopaque) c_int;

pub fn drawScreenWrapper(widget: ?*anyopaque, cr: ?*anyopaque, data: ?*anyopaque) c_int {
    return drawScreen(widget, cr, data);
}
