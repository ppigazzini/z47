const diagnostics_owned = @import("vector_linpol_diagnostics.zig");
const compute_owned = @import("vector_linpol_compute.zig");
const io_owned = @import("vector_linpol_io.zig");
const result_owned = @import("vector_linpol_result.zig");
const runtime = @import("../math_command_wrappers_runtime.zig");

pub fn linpol() callconv(.c) void {
    var a_real: runtime.real_t = undefined;
    var b_real: runtime.real_t = undefined;
    var a_imag: runtime.real_t = undefined;
    var b_imag: runtime.real_t = undefined;
    var p: runtime.real_t = undefined;
    var result_real: runtime.real_t = undefined;
    var result_imag: runtime.real_t = undefined;
    var real_coefs = true;
    var data_tag_y: runtime.angularMode_t = runtime.amNone;
    var data_tag_z: runtime.angularMode_t = runtime.amNone;
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    const type_z = runtime.getRegisterDataType(runtime.REGISTER_Z);
    const is_y_angle = type_y == runtime.dtReal34 and runtime.getRegisterAngularMode(runtime.REGISTER_Y) != runtime.amNone;
    const is_z_angle = type_z == runtime.dtReal34 and runtime.getRegisterAngularMode(runtime.REGISTER_Z) != runtime.amNone;

    runtime.realSetZero(&a_imag);
    runtime.realSetZero(&b_imag);

    if (!io_owned.readP(&p)) {
        diagnostics_owned.invalidXError();
        return;
    }

    if ((type_y != type_z and (type_y == runtime.dtTime or type_z == runtime.dtTime)) or
        (is_y_angle and !is_z_angle) or
        (is_z_angle and !is_y_angle))
    {
        diagnostics_owned.differingTypeError();
        return;
    }

    if (!io_owned.readCoeff(runtime.REGISTER_Y, type_y, &b_real, &b_imag, &real_coefs, &data_tag_y)) {
        diagnostics_owned.coeffTypeError(runtime.REGISTER_Y);
        return;
    }

    if (!io_owned.readCoeff(runtime.REGISTER_Z, type_z, &a_real, &a_imag, &real_coefs, &data_tag_z)) {
        diagnostics_owned.coeffTypeError(runtime.REGISTER_Z);
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, runtime.REGISTER_Y, runtime.REGISTER_Z);
    runtime.fnDrop(0);
    runtime.fnDrop(0);

    compute_owned.linpolScalar(&a_real, &b_real, &p, &result_real);
    if (!real_coefs) {
        compute_owned.linpolScalar(&a_imag, &b_imag, &p, &result_imag);
    }

    result_owned.writeResult(
        type_y,
        is_y_angle,
        is_z_angle,
        data_tag_y,
        data_tag_z,
        real_coefs,
        &result_real,
        &result_imag,
    );
}
