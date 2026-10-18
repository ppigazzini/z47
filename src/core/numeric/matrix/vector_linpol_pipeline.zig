const diagnostics_owned = @import("vector_linpol_diagnostics.zig");
const compute_owned = @import("vector_linpol_compute.zig");
const io_owned = @import("vector_linpol_io.zig");
const result_owned = @import("vector_linpol_result.zig");
const runtime = @import("../command_wrappers/runtime.zig");

pub fn linpol() callconv(.c) void {
    var a: runtime.cplx_t = undefined;
    var b: runtime.cplx_t = undefined;
    var p: runtime.real_t = undefined;
    var r: runtime.cplx_t = undefined;
    var exact_result: runtime.real_t = undefined;
    var real_coefs = true;
    var data_tag_y: runtime.angularMode_t = runtime.amNone;
    var data_tag_z: runtime.angularMode_t = runtime.amNone;
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    const type_z = runtime.getRegisterDataType(runtime.REGISTER_Z);
    const is_y_angle = type_y == runtime.dtReal34 and runtime.getRegisterAngularMode(runtime.REGISTER_Y) != runtime.amNone;
    const is_z_angle = type_z == runtime.dtReal34 and runtime.getRegisterAngularMode(runtime.REGISTER_Z) != runtime.amNone;

    runtime.realSetZero(&a.Imag);
    runtime.realSetZero(&b.Imag);

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

    if (!io_owned.readCoeff(runtime.REGISTER_Y, type_y, &b.Real, &b.Imag, &real_coefs, &data_tag_y)) {
        diagnostics_owned.coeffTypeError(runtime.REGISTER_Y);
        return;
    }

    if (!io_owned.readCoeff(runtime.REGISTER_Z, type_z, &a.Real, &a.Imag, &real_coefs, &data_tag_z)) {
        diagnostics_owned.coeffTypeError(runtime.REGISTER_Z);
        return;
    }

    // With a long integer among the operands and plain integer or untagged real
    // endpoints, the interpolation is formed exactly on scaled long integers.
    const exact_interpolation = real_coefs and
        (type_x == runtime.dtLongInteger or type_y == runtime.dtLongInteger or type_z == runtime.dtLongInteger) and
        (type_y == runtime.dtLongInteger or type_y == runtime.dtShortInteger or (type_y == runtime.dtReal34 and !is_y_angle)) and
        (type_z == runtime.dtLongInteger or type_z == runtime.dtShortInteger or (type_z == runtime.dtReal34 and !is_z_angle)) and
        io_owned.linpolExactRegisters(&p, &exact_result);

    if (!runtime.saveLastX()) {
        return;
    }

    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, runtime.REGISTER_Y, runtime.REGISTER_Z);
    runtime.fnDrop(runtime.NOPARAM);
    runtime.fnDrop(runtime.NOPARAM);

    if (!exact_interpolation) {
        compute_owned.linpolScalar(&a.Real, &b.Real, &p, &r.Real);
    }
    if (!real_coefs) {
        compute_owned.linpolScalar(&a.Imag, &b.Imag, &p, &r.Imag);
    }

    result_owned.writeResult(
        type_y,
        is_y_angle,
        is_z_angle,
        data_tag_y,
        data_tag_z,
        real_coefs,
        &r,
        if (exact_interpolation) &exact_result else null,
    );
}
